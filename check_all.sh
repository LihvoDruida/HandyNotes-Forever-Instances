#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")"
failures=0

stage() {
    local label="$1"; shift
    echo ""
    echo "=== ${label}"
    if "$@"; then
        echo "--- PASS: ${label}"
    else
        echo "--- FAIL: ${label}"
        failures=$((failures + 1))
    fi
}

find_lua() {
    command -v lua5.1 2>/dev/null || command -v lua 2>/dev/null || command -v texlua 2>/dev/null || true
}

lua_syntax() {
    local compiler=""
    if command -v luac5.1 >/dev/null 2>&1; then compiler="luac5.1"
    elif command -v luac >/dev/null 2>&1; then compiler="luac"
    else
        local lua_bin; lua_bin="$(find_lua)"
        if [[ -z "$lua_bin" ]]; then
            echo "SKIP: no Lua parser available in this local environment"
            return 0
        fi
        local tmp; tmp=$(mktemp --suffix=.lua)
        cat >"$tmp" <<'LUA'
for i = 1, #arg do
    local fn, err = loadfile(arg[i])
    if not fn then io.stderr:write(arg[i] .. ": " .. tostring(err) .. "\n"); os.exit(1) end
end
LUA
        mapfile -d '' files < <(find . -type f -name '*.lua' -not -path './.git/*' -print0)
        "$lua_bin" "$tmp" "${files[@]}"
        local rc=$?
        rm -f "$tmp"
        return $rc
    fi
    local rc=0
    while IFS= read -r -d '' f; do "$compiler" -p "$f" || rc=1; done < <(find . -type f -name '*.lua' -not -path './.git/*' -print0)
    return $rc
}

runtime_data_integrity() {
    local lua_bin; lua_bin="$(find_lua)"
    if [[ -z "$lua_bin" ]]; then
        echo "SKIP: no Lua runtime available in this local environment"
        return 0
    fi
    local tmp; tmp=$(mktemp --suffix=.lua)
    cat >"$tmp" <<'LUA'
local ns = {}
assert(loadfile("Database.lua"))("Forever_Instances", ns)
assert(type(ns.DB) == "table", "ns.DB missing")
local DB = ns.DB
assert(DB.version == 9, "expected database schema 9")
assert(type(DB.GetBrowserEntries) == "function", "GetBrowserEntries missing")
assert(type(DB.GetCanonicalLocation) == "function", "GetCanonicalLocation missing")
assert(type(DB.GetNormalizedCoordinates) == "function", "GetNormalizedCoordinates missing")

local total, dungeons, raids, tba = 0, 0, 0, 0
local territories = { Alliance=0, Horde=0, Contested=0 }
local grouped = 0
local deferredMapIDs = 0
local secondary = {}
local function inspectRecord(id, v, isWing)
    assert(type(v.name) == "string" and v.name ~= "", "missing name: " .. id)
    if v.entrance ~= nil or v.alternateEntrances ~= nil or v.mapPoints ~= nil then
        secondary[#secondary+1] = id
    end
    if v.coordStatus == "grouped" then
        grouped = grouped + (isWing and 0 or 1)
        assert(v.x == nil and v.y == nil, "group parent must not store coordinates: " .. id)
    elseif v.coordStatus == "tba" then
        assert(v.x == nil and v.y == nil, "TBA record must not store coordinates: " .. id)
    else
        assert(type(v.x) == "number" and v.x > 0 and v.x <= 100, "canonical x invalid: " .. id)
        assert(type(v.y) == "number" and v.y > 0 and v.y <= 100, "canonical y invalid: " .. id)
        local mapID, x, y = DB.GetCanonicalLocation(v)
        if type(mapID) == "number" then
            assert(x == v.x and y == v.y, "canonical coordinate mismatch: " .. id)
            local nx, ny = DB.GetNormalizedCoordinates(v)
            assert(math.abs(nx - x/100) < 0.000001 and math.abs(ny - y/100) < 0.000001, "normalized mismatch: " .. id)
        else
            -- The Riverglades UIMapID is client-owned and resolved centrally
            -- through C_Map at runtime; this offline Lua runner has no C_Map.
            assert(v.mapID == nil and (v.zone == "The Riverglades" or v.zone == "Riverglades"), "unexpected deferred mapID: " .. id)
            deferredMapIDs = deferredMapIDs + 1
        end
    end
end

for sectionName, expected in pairs({Dungeons="Dungeon", Raids="Raid"}) do
    for _, era in ipairs({"Classic", "Forever"}) do
        for id, v in pairs(DB[sectionName][era] or {}) do
            total = total + 1
            if expected == "Dungeon" then
                dungeons = dungeons + 1
                assert(v.contentType == "Dungeon", "dungeon contentType mismatch: " .. id)
                if territories[v.territory] ~= nil then territories[v.territory] = territories[v.territory] + 1 end
            else
                raids = raids + 1
                assert(v.contentType == "Raid", "raid contentType mismatch: " .. id)
            end
            assert(v.era == era, "era mismatch: " .. id)
            if v.coordStatus == "tba" then tba = tba + 1 end
            inspectRecord(id, v, false)
            for wingID, wing in pairs(v.wings or {}) do inspectRecord(id .. "/" .. wingID, wing, true) end
        end
    end
end

assert(total == 37 and dungeons == 28 and raids == 9, string.format("catalog totals changed: %d/%d/%d", total,dungeons,raids))
assert(tba == 2, "expected exactly two TBA records")
assert(grouped == 4, "expected four grouped parent dungeons")
assert(deferredMapIDs == 1, "expected exactly one live-resolved UIMapID")
assert(#secondary == 0, "secondary coordinate fields remain: " .. table.concat(secondary, ","))
assert(territories.Alliance == 5 and territories.Horde == 7 and territories.Contested == 16,
    string.format("territory counts changed A=%d H=%d C=%d", territories.Alliance, territories.Horde, territories.Contested))

local entries = DB.GetBrowserEntries()
assert(#entries == 44, "browser entries must be 44")
local mapped, deferredBrowserMap, browserTba, wingRows = 0, 0, 0, 0
for _, e in ipairs(entries) do
    local v = e.instance
    if e.parentID then wingRows = wingRows + 1 end
    local mapID, x, y = DB.GetCanonicalLocation(v)
    if v.coordStatus == "tba" then
        browserTba = browserTba + 1
        assert(mapID == nil and x == nil and y == nil, "TBA browser row exposes location: " .. e.id)
    else
        if type(mapID)=="number" and type(x)=="number" and type(y)=="number" then
            mapped = mapped + 1
        elseif type(v.x)=="number" and type(v.y)=="number" and v.mapID == nil
            and (v.zone == "The Riverglades" or v.zone == "Riverglades") then
            deferredBrowserMap = deferredBrowserMap + 1
        else
            error("browser row missing canonical location: " .. e.id)
        end
    end
end
assert(mapped == 41 and deferredBrowserMap == 1 and browserTba == 2 and wingRows == 11,
    string.format("browser location coverage mismatch mapped=%d deferred=%d tba=%d wings=%d", mapped,deferredBrowserMap,browserTba,wingRows))

local dm = DB.Dungeons.Classic.deadmines
local mapID,x,y = DB.GetCanonicalLocation(dm)
assert(dm.levelMin == 17 and dm.levelMax == 26 and mapID == 1436 and x == 38.2 and y == 77.5, "Deadmines canonical record mismatch")
local dire = DB.Dungeons.Classic.dire_maul
assert(dire.coordStatus == "grouped" and dire.x == nil and dire.y == nil, "Dire Maul parent must not create a map point")
assert(dire.wings.east.x == 64.8 and dire.wings.west.x == 60.2 and dire.wings.north.x == 62.4, "Dire Maul wings mismatch")
local strat = DB.Dungeons.Classic.stratholme
assert(strat.wings.living.x == 26.1 and strat.wings.undead.x == 43.0, "Stratholme wings mismatch")

print(string.format("Database: top=%d dungeons=%d raids=%d browser=%d mapped=%d deferredMapID=%d tba=%d wings=%d", total,dungeons,raids,#entries,mapped,deferredBrowserMap,browserTba,wingRows))
LUA
    "$lua_bin" "$tmp"
    local rc=$?
    rm -f "$tmp"
    return $rc
}

localization_parity() {
    local lua_bin; lua_bin="$(find_lua)"
    if [[ -z "$lua_bin" ]]; then
        python3 - <<'PY'
import re
from pathlib import Path
keys=[]
for name in ('enUS.lua','ukUA.lua'):
    s=(Path('Localizations')/name).read_text()
    keys.append(set(re.findall(r'^\s*([A-Z0-9_]+)\s*=', s, re.M)))
assert keys[0] == keys[1], f'locale mismatch en-only={sorted(keys[0]-keys[1])} uk-only={sorted(keys[1]-keys[0])}'
print(f'Locale key parity: {len(keys[0])} keys')
PY
        return
    fi
    local tmp; tmp=$(mktemp --suffix=.lua)
    cat >"$tmp" <<'LUA'
local ns = {}
assert(loadfile("Localizations/enUS.lua"))("Forever_Instances", ns)
assert(loadfile("Localizations/ukUA.lua"))("Forever_Instances", ns)
local en, uk = ns.Locales.enUS, ns.Locales.ukUA
for k in pairs(en) do assert(uk[k] ~= nil, "ukUA missing " .. k) end
for k in pairs(uk) do assert(en[k] ~= nil, "enUS missing " .. k) end
print("Locale key parity: OK")
LUA
    "$lua_bin" "$tmp"
    local rc=$?
    rm -f "$tmp"
    return $rc
}

ui_architecture() {
    python3 - <<'PY2'
from pathlib import Path
b=Path('InstanceBrowser.lua').read_text()
c=Path('Core.lua').read_text()
d=Path('Database.lua').read_text()
checks={
    'quest sibling outer': 'outer:SetAllPoints(anchor)' in b,
    'quest inner top -29': '"TOPLEFT", anchor, "TOPLEFT", 0, -QUEST_HEADER_HEIGHT' in b,
    'quest right inset -22': '"BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -22, 0' in b,
    'manual MinimalScrollBar': '"MinimalScrollBar"' in b,
    'scroll bar top': '"TOPLEFT", p, "TOPRIGHT", 8, 2' in b,
    'scroll bar bottom': '"BOTTOMLEFT", p, "BOTTOMRIGHT", 8, -4' in b,
    'Blizzard side-tab chrome': 'QuestLog-tab-side' in b,
    'Blizzard side-tab selected glow': 'QuestLog-Tab-side-Glow-Select' in b,
    'Blizzard side-tab hover glow': 'QuestLog-Tab-side-Glow-hover' in b,
    'Blizzard dungeon atlas': 'SafeAtlas(icon, "Dungeon", false)' in b,
    'foreign managed-tab discovery': 'child.displayMode == nil' in b and 'GetVisibleManagedSideTabs(qmf)' in b,
    'generic Blizzard-style peer discovery': 'GetVisibleQuestStyleSideTabs(qmf)' in b and 'QuestLog-tab-side' in b,
    'post-mouseup external tab handoff': 'HandoffAfterDestination' in b and 'externalTabHandoffPhase = "post-mouseup"' in b and 'OnMouseDown", function(_, button)\n        if button == "LeftButton" then HandoffAfterDestination() end' not in b,
    'fallback quest visual arbitration': 'GetQuestTabIconIdentities' in b and 'IsFallbackQuestTab' in b and 'nativeQuestsActive' in b and 'CountExternalSelectedGlows' in b,
    'cooperative detached-tab release': 'ReleaseOtherDetachedPanels(qmf)' in b and 'lastSystemDisplayMode' in b,
    'own tab excluded from foreign displayMode chain': 'tab.displayMode = "ForeverInstancesBrowser"' not in b,
    'Blizzard-owned map reopen lifecycle': 'Do not make the addon tab sticky across World Map close/reopen' in b,
    'no sticky browser reopen state': 'lastSelectedWasOurs' not in b and 'restoreBrowser' not in b,
    'map close restores native mode': 'WorldMapFrame:HookScript("OnHide"' in b and 'Browser:Hide(true)' in b,
    'shared tab manager sync': 'LibWorldMapTabs' in b and 'pcall(lib.SetDisplayMode, lib, nil)' in b,
    'native content exclusivity': 'HideNativeQuestMapContent(qmf)' in b,
    'no continuous layout watcher': 'SetScript("OnUpdate"' not in b,
    'nil SetDisplayMode selection': 'pcall(qmf.SetDisplayMode, qmf)' in b,
    'single canonical browser source': 'GetCanonicalLocation(instance)' in b,
    'single canonical core source': 'ns.DB.GetCanonicalLocation(instance)' in c,
    'browser-entry core iteration': 'ns.DB.GetBrowserEntries' in c,
    'no SetMapID': ':SetMapID(' not in b,
    'no MapCanvas pin': 'AcquirePin' not in b and 'CreatePin' not in b,
    'no TabButtons mutation': 'table.insert(qmf.TabButtons' not in b and 'qmf.TabButtons[' not in b,
    'no ContentFrames mutation': 'table.insert(qmf.ContentFrames' not in b and 'qmf.ContentFrames[' not in b,
    'no hard-coded foreign addon globals': '_G.EasyFind' not in b and '_G.ForeverDungeonMaps' not in b,
    'no secondary coord fields DB': all(x not in d for x in ('entrance =','alternateEntrances =','mapPoints =')),
    'no legacy fallback runtime': 'LegacyFallback' not in c and 'LegacyFallback' not in b,
}
bad=[k for k,v in checks.items() if not v]
assert not bad, 'failed architecture checks: ' + ', '.join(bad)
print('Quest-style detached UI + Blizzard-owned map lifecycle + canonical coordinate architecture: OK')
PY2
}

source_hygiene() {
    python3 - <<'PY'
from pathlib import Path
root=Path('.')
assert not (root/'LegacyFallback.lua').exists(), 'LegacyFallback.lua should be removed'
assert not (root/'entrance_flag.tga').exists(), 'entrance_flag.tga should be removed'
# Diagnostic names obsolete fields only to verify they are absent at runtime.
for p in (root/'Core.lua', root/'InstanceBrowser.lua', root/'Database.lua'):
    s=p.read_text(errors='replace')
    for token in ('alternateEntrances','mapPoints','.entrance'):
        assert token not in s, f'{p}: obsolete coordinate token {token}'
print('No legacy coordinate database/assets remain')
PY
}

release_layout() {
    local required=(
        Forever_Instances_Camelot.toc Core.lua InstanceBrowser.lua Diagnostic.lua Database.lua AtlasData.lua
        Localizations/enUS.lua Localizations/ukUA.lua dungeon.tga raid.tga forever_dungeon.tga icon.tga
        .pkgmeta .github/workflows/release.yml release.sh check_all.sh cliff.toml tools/set_version.py
    )
    local rc=0
    for f in "${required[@]}"; do [[ -s "$f" ]] || { echo "missing/empty: $f" >&2; rc=1; }; done
    [[ ! -e LegacyFallback.lua ]] || { echo "LegacyFallback.lua must not ship" >&2; rc=1; }
    [[ ! -e entrance_flag.tga ]] || { echo "entrance_flag.tga must not ship" >&2; rc=1; }
    return $rc
}

toc_forever_only() {
    grep -Eq '^## Interface:[[:space:]]*16001[[:space:]]*$' Forever_Instances_Camelot.toc || return 1
    local count; count=$(find . -maxdepth 1 -name '*.toc' | wc -l)
    [[ "$count" -eq 1 ]] || return 1
    ! grep -Fq 'LegacyFallback.lua' Forever_Instances_Camelot.toc
}

release_version_applied() {
    local tag="${GITHUB_REF_NAME:-}"
    [[ -z "$tag" ]] && return 0
    local version; version=$(sed -n 's/^## Version:[[:space:]]*//p' Forever_Instances_Camelot.toc | head -n1 | tr -d '\r')
    [[ "${version#v}" == "${tag#v}" ]] || { echo "tag/version mismatch tag=$tag toc=$version" >&2; return 1; }
    python3 tools/set_version.py --check "$tag"
}

changelog_matches_version() {
    local version; version=$(sed -n 's/^## Version:[[:space:]]*v\{0,1\}//p' Forever_Instances_Camelot.toc | head -n1 | tr -d '\r')
    grep -Fq "## [$version]" CHANGELOG.md
}

pkgmeta_valid() {
    grep -Eq '^package-as:[[:space:]]*Forever_Instances$' .pkgmeta && grep -Eq '^manual-changelog:' .pkgmeta
}

workflow_config() {
    local f=.github/workflows/release.yml
    grep -Fq 'secrets.CURSEFORGE_PROJECT_ID || vars.CURSEFORGE_PROJECT_ID' "$f" || return 1
    grep -Fq 'CF_API_KEY: ${{ secrets.CF_API_KEY }}' "$f" || return 1
    grep -Fq 'run: bash ./check_all.sh' "$f" || return 1
    grep -Fq 'python3 tools/set_version.py "$GITHUB_REF_NAME"' "$f" || return 1
    grep -Fq 'args: -p ${{ env.CURSEFORGE_PROJECT_ID }}' "$f" || return 1
}

diagnostic_surface() {
    grep -Fq 'SLASH_FOREVERINSTANCESTEST1 = "/fitest"' Diagnostic.lua || return 1
    grep -Fq 'ADDON_ACTION_BLOCKED' Diagnostic.lua || return 1
    grep -Fq 'Single canonical coordinate source' Diagnostic.lua || return 1
    grep -Fq 'Quest-style panel / scroll surface' Diagnostic.lua || return 1
    grep -Fq 'Quest-style detached side-tab chain' Diagnostic.lua || return 1
    grep -Fq 'External side-tab handoff coverage' Diagnostic.lua || return 1
    grep -Fq 'Custom side-tab visual exclusivity' Diagnostic.lua || return 1
    grep -Fq 'Blizzard default map reopen lifecycle' Diagnostic.lua || return 1
    grep -Fq 'Browser:GetDebugState' InstanceBrowser.lua || return 1
    ! grep -Fq 'lastSelectedWasOurs' InstanceBrowser.lua || return 1
    ! grep -Fq 'restoreBrowser()' InstanceBrowser.lua || return 1
    grep -Fq 'Do not make the addon tab sticky across World Map close/reopen' InstanceBrowser.lua || return 1
}

stage "Lua syntax" lua_syntax
stage "Database / canonical locations" runtime_data_integrity
stage "Localization parity" localization_parity
stage "Quest-style map UI architecture" ui_architecture
stage "Live diagnostic surface" diagnostic_surface
stage "Source hygiene" source_hygiene
stage "Release file layout" release_layout
stage "Forever-only TOC" toc_forever_only
stage "Release version applied" release_version_applied
stage "Changelog matches TOC" changelog_matches_version
stage "Package metadata" pkgmeta_valid
stage "Release workflow" workflow_config

echo ""
if [[ $failures -eq 0 ]]; then echo "ALL CHECKS PASSED"; else echo "${failures} STAGE(S) FAILED"; fi
exit $failures
