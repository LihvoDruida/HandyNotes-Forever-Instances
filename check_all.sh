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

lua_syntax() {
    local compiler=""
    if command -v luac5.1 >/dev/null 2>&1; then
        compiler="luac5.1"
    elif command -v luac >/dev/null 2>&1; then
        compiler="luac"
    else
        echo "luac5.1/luac is required for the Lua syntax gate" >&2
        return 127
    fi

    local rc=0
    while IFS= read -r -d '' f; do
        "$compiler" -p "$f" || rc=1
    done < <(find . -type f -name '*.lua' -not -path './.git/*' -print0)
    return $rc
}

release_layout() {
    local required=(
        "Forever_Instances_Camelot.toc"
        "Core.lua"
        "Database.lua"
        "AtlasData.lua"
        "LegacyFallback.lua"
        "Localizations/enUS.lua"
        "Localizations/ukUA.lua"
        "dungeon.tga"
        "raid.tga"
        "forever_dungeon.tga"
        "entrance_flag.tga"
        "icon.tga"
        "CHANGELOG.md"
        "LICENSE.md"
        "THIRD_PARTY_NOTICES.md"
        ".pkgmeta"
        ".github/workflows/release.yml"
        "release.sh"
        "check_all.sh"
        "RELEASING.md"
        "CONTENT_CLASSIFICATION_AUDIT.md"
        "cliff.toml"
        "tools/set_version.py"
    )

    local rc=0
    for f in "${required[@]}"; do
        if [[ ! -s "$f" ]]; then
            echo "missing or empty release file: $f" >&2
            rc=1
        fi
    done
    return $rc
}

toc_forever_only() {
    local toc="Forever_Instances_Camelot.toc"
    grep -Eq '^## Interface:[[:space:]]*16001([[:space:]]*)$' "$toc" || {
        echo "Forever TOC must use Interface 16001" >&2
        return 1
    }

    local count
    count=$(find . -maxdepth 1 -name '*.toc' -printf '.' | wc -c)
    if [[ "$count" -ne 1 ]]; then
        echo "Forever-only package must contain exactly one TOC; found $count" >&2
        return 1
    fi

    [[ "$(basename "$(find . -maxdepth 1 -name '*.toc' -print -quit)")" == "Forever_Instances_Camelot.toc" ]]
}

release_version_applied() {
    # Local validation without a requested release version is allowed.
    # In CI the workflow rewrites the TOC from GITHUB_REF_NAME before this gate.
    local tag="${GITHUB_REF_NAME:-}"
    [[ -z "$tag" ]] && return 0

    local version
    version=$(sed -n 's/^## Version:[[:space:]]*//p' "Forever_Instances_Camelot.toc" | head -n1 | tr -d '\r')
    if [[ -z "$version" ]]; then
        echo "TOC version is missing" >&2
        return 1
    fi

    local normalized_toc="${version#v}"
    local normalized_tag="${tag#v}"
    if [[ "$normalized_toc" != "$normalized_tag" ]]; then
        echo "tag/version mismatch: tag=$tag toc=$version" >&2
        return 1
    fi

    python3 tools/set_version.py --check "$tag"
}


changelog_matches_version() {
    local version
    version=$(sed -n 's/^## Version:[[:space:]]*v\{0,1\}//p' "Forever_Instances_Camelot.toc" | head -n1 | tr -d '\r')
    if [[ -z "$version" ]]; then
        echo "TOC version is missing" >&2
        return 1
    fi

    if ! grep -Fq "## [$version]" CHANGELOG.md; then
        echo "CHANGELOG.md has no release section for TOC version $version" >&2
        return 1
    fi
}

pkgmeta_valid() {
    grep -Eq '^package-as:[[:space:]]*Forever_Instances$' .pkgmeta || return 1
    grep -Eq '^manual-changelog:' .pkgmeta || return 1
    grep -Eq '^[[:space:]]+-[[:space:]]+\.github$' .pkgmeta || return 1
}

workflow_config() {
    local workflow=".github/workflows/release.yml"
    [[ -s "$workflow" ]] || { echo "missing release workflow: $workflow" >&2; return 1; }

    grep -Fq 'secrets.CURSEFORGE_PROJECT_ID || vars.CURSEFORGE_PROJECT_ID' "$workflow" || {
        echo "release workflow must support CURSEFORGE_PROJECT_ID as secret with variable fallback" >&2
        return 1
    }
    grep -Fq 'args: -p ${{ env.CURSEFORGE_PROJECT_ID }}' "$workflow" || {
        echo "packager must consume the resolved CURSEFORGE_PROJECT_ID env value" >&2
        return 1
    }
    grep -Fq 'CF_API_KEY: ${{ secrets.CF_API_KEY }}' "$workflow" || {
        echo "release workflow must read CF_API_KEY from repository secrets" >&2
        return 1
    }
    grep -Fq 'run: bash ./check_all.sh' "$workflow" || {
        echo "release workflow must invoke check_all.sh through bash so CI does not depend on executable file mode" >&2
        return 1
    }
    grep -Fq 'python3 tools/set_version.py "$GITHUB_REF_NAME"' "$workflow" || {
        echo "release workflow must rewrite the TOC version from the requested tag before validation" >&2
        return 1
    }
    grep -Fq 'rm -f CHANGELOG.md' "$workflow" || {
        echo "release workflow must discard any pre-existing CHANGELOG.md before generation" >&2
        return 1
    }
    grep -Fq 'git-cliff --current --output CHANGELOG.md' "$workflow" || {
        echo "release workflow must generate CHANGELOG.md from the current Git tag instead of consuming a ready file" >&2
        return 1
    }
}


dungeon_territory_data() {
    local lua_bin=""
    if command -v lua5.1 >/dev/null 2>&1; then
        lua_bin="lua5.1"
    elif command -v lua >/dev/null 2>&1; then
        lua_bin="lua"
    else
        echo "lua5.1/lua is required for dungeon territory validation" >&2
        return 127
    fi

    "$lua_bin" - <<'LUA'
local ns = {}
local chunk, err = loadfile("Database.lua")
assert(chunk, err)
chunk("Forever_Instances", ns)

local counts = { Alliance = 0, Horde = 0, Contested = 0 }
local total = 0
for _, bucket in pairs(ns.DB.Dungeons or {}) do
    for id, instance in pairs(bucket or {}) do
        total = total + 1
        assert(counts[instance.territory] ~= nil, "missing/invalid dungeon territory for " .. tostring(id))
        counts[instance.territory] = counts[instance.territory] + 1
        assert(instance.players == 5, "unexpected base group size for " .. tostring(id) .. ": " .. tostring(instance.players))
        if id == "blackrock_spire" then
            assert(instance.maxPlayers == 10, "Blackrock Spire must preserve its 5-10 player range")
        end
    end
end

assert(total == 28, "expected 28 dungeons, got " .. tostring(total))
assert(counts.Alliance + counts.Horde + counts.Contested == total, "dungeon territory totals do not match dungeon count")
print(string.format("Dungeon territories: Alliance=%d Horde=%d Contested=%d", counts.Alliance, counts.Horde, counts.Contested))
LUA
}

content_classification_data() {
    local lua_bin=""
    if command -v lua5.1 >/dev/null 2>&1; then
        lua_bin="lua5.1"
    elif command -v lua >/dev/null 2>&1; then
        lua_bin="lua"
    else
        echo "lua5.1/lua is required for content classification validation" >&2
        return 127
    fi

    "$lua_bin" - <<'LUA'
local ns = {}
local chunk, err = loadfile("Database.lua")
assert(chunk, err)
chunk("Forever_Instances", ns)

local expected = {
    Dungeons = {
        Classic = {
            ragefire_chasm=true, deadmines=true, wailing_caverns=true, shadowfang_keep=true,
            blackfathom_deeps=true, the_stockade=true, gnomeregan=true, razorfen_kraul=true,
            scarlet_monastery=true, uldaman=true, razorfen_downs=true, zulfarrak=true,
            maraudon=true, temple_of_atal_hakkar=true, blackrock_depths=true, blackrock_spire=true,
            dire_maul=true, stratholme=true, scholomance=true,
        },
        Forever = {
            hall_of_thanes=true, ruins_of_lordaeron=true, excavation_site_wetlands=true,
            city_of_dalaran=true, drowned_city=true, kroldok_stronghold=true, alcaz_prison=true,
            blackmaw_hold=true, shapers_terrace=true,
        },
    },
    Raids = {
        Classic = {
            molten_core=true, onyxias_lair=true, blackwing_lair=true, zulgurub=true,
            ruins_of_ahnqiraj=true, temple_of_ahnqiraj=true, naxxramas=true,
        },
        Forever = { barrow_deeps=true, hyjal_summit=true },
    },
}

local counts = { DungeonClassic=0, DungeonForever=0, RaidClassic=0, RaidForever=0 }
for sectionName, contentType in pairs({ Dungeons="Dungeon", Raids="Raid" }) do
    for _, era in ipairs({ "Classic", "Forever" }) do
        local bucket = assert(ns.DB[sectionName][era], sectionName .. "." .. era .. " missing")
        local expectedSet = expected[sectionName][era]
        for id, instance in pairs(bucket) do
            assert(expectedSet[id], "unexpected " .. sectionName .. "." .. era .. " record: " .. tostring(id))
            assert(instance.contentType == contentType, "wrong contentType for " .. tostring(id))
            assert(instance.era == era, "wrong era for " .. tostring(id))
            local key = contentType .. era
            counts[key] = counts[key] + 1
        end
        for id in pairs(expectedSet) do
            assert(bucket[id], "missing " .. sectionName .. "." .. era .. " record: " .. tostring(id))
        end
    end
end

assert(counts.DungeonClassic == 19, "expected 19 Classic dungeons")
assert(counts.DungeonForever == 9, "expected 9 Forever-new dungeons")
assert(counts.RaidClassic == 7, "expected 7 Classic raids")
assert(counts.RaidForever == 2, "expected 2 Forever-new raids")

-- UI status filters overlap by design.
local classicMatches, foreverMatches, overlap, union = 0, 0, 0, 0
for _, sectionName in ipairs({ "Dungeons", "Raids" }) do
    for _, bucket in pairs(ns.DB[sectionName] or {}) do
        for _, instance in pairs(bucket or {}) do
            local classic = instance.era == "Classic"
            local forever = instance.era == "Forever" or instance.foreverStatus == "updated"
            if classic then classicMatches = classicMatches + 1 end
            if forever then foreverMatches = foreverMatches + 1 end
            if classic and forever then overlap = overlap + 1 end
            if classic or forever then union = union + 1 end
        end
    end
end
assert(classicMatches == 26, "Classic-era filter must match 26 Classic-origin instances")
assert(foreverMatches == 32, "Forever new/updated filter must match 32 instances")
assert(overlap == 21, "expected 21 updated Classic instances to match both status filters")
assert(union == 37, "both status filters enabled must cover all 37 instances")

local core = assert(io.open("Core.lua", "rb")):read("*a")
assert(core:find('local function canonicalKind', 1, true), "Core.lua must use canonical contentType metadata")
assert(core:find('local function canonicalEra', 1, true), "Core.lua must use canonical era metadata")
assert(core:find('local function isClassicFilterMatch', 1, true), "Core.lua must define Classic-origin filter matching")
assert(core:find('local function isForeverFilterMatch', 1, true), "Core.lua must define Forever new/updated matching")
assert(core:find('return matchesClassic or matchesForever', 1, true), "status filters must use overlapping OR semantics")
assert(core:find('local function setFilter', 1, true), "Core.lua must centralize filter writes")
assert(core:find('HandyNotes.UpdatePluginMap', 1, true), "Core.lua must directly refresh HandyNotes after filter changes")
assert(core:find('worldNodesDirty = true', 1, true), "Core.lua must invalidate Azeroth projection cache")

print(string.format("Classification: dungeons=%d+%d raids=%d+%d; filters classic=%d forever-new-or-updated=%d overlap=%d", counts.DungeonClassic, counts.DungeonForever, counts.RaidClassic, counts.RaidForever, classicMatches, foreverMatches, overlap))
LUA
}

entrance_coordinate_data() {
    local lua_bin=""
    if command -v lua5.1 >/dev/null 2>&1; then
        lua_bin="lua5.1"
    elif command -v lua >/dev/null 2>&1; then
        lua_bin="lua"
    else
        echo "lua5.1/lua is required for entrance-coordinate validation" >&2
        return 127
    fi

    "$lua_bin" - <<'LUA'
local ns = {}
local chunk, err = loadfile("Database.lua")
assert(chunk, err)
chunk("Forever_Instances", ns)

local total = 0
local dungeons = 0
local raids = 0
local distinctEntrances = 0

local function validate(kind, id, instance)
    total = total + 1
    if kind == "Dungeon" then dungeons = dungeons + 1 else raids = raids + 1 end

    assert(type(instance.entrance) == "table", "missing entrance block for " .. tostring(id))
    local ex = instance.entrance.x
    local ey = instance.entrance.y
    assert(type(ex) == "number" and type(ey) == "number", "entrance x/y must be numeric for " .. tostring(id))
    assert(ex >= 0 and ey >= 0, "entrance x/y must not be negative for " .. tostring(id))

    local hasEntrance = ex > 0 and ey > 0
    local zeroEntrance = ex == 0 and ey == 0
    assert(hasEntrance or zeroEntrance, "entrance must be either a positive coordinate pair or 0,0 for " .. tostring(id))

    if hasEntrance then
        distinctEntrances = distinctEntrances + 1
        local entranceZone = instance.entrance.zone or instance.zone
        if type(instance.x) == "number" and type(instance.y) == "number"
            and entranceZone == instance.zone then
            assert(ex ~= instance.x or ey ~= instance.y,
                "duplicate entrance must be stored as 0,0 for " .. tostring(id))
        end
    end
end

for _, group in pairs(ns.DB.Dungeons or {}) do
    for id, instance in pairs(group or {}) do validate("Dungeon", id, instance) end
end
for _, group in pairs(ns.DB.Raids or {}) do
    for id, instance in pairs(group or {}) do validate("Raid", id, instance) end
end

assert(total == 37, "expected 37 total instances, got " .. tostring(total))
assert(dungeons == 28, "expected 28 dungeons, got " .. tostring(dungeons))
assert(raids == 9, "expected 9 raids, got " .. tostring(raids))
assert(distinctEntrances == 7, "expected 7 distinct entrance markers, got " .. tostring(distinctEntrances))

local barrow = assert(ns.DB.Raids.Forever.barrow_deeps)
local hyjal = assert(ns.DB.Raids.Forever.hyjal_summit)
assert(barrow.entrance.x == 0 and barrow.entrance.y == 0, "Barrow Deeps unknown entrance must stay 0,0")
assert(hyjal.entrance.x == 0 and hyjal.entrance.y == 0, "Hyjal Summit unknown entrance must stay 0,0")

local core = assert(io.open("Core.lua", "rb")):read("*a")
assert(core:find('local function hasUsablePoint', 1, true), "Core.lua must guard zero/unknown points")
assert(core:find('if not hasUsablePoint(entrance.x, entrance.y)', 1, true), "Core.lua must suppress 0,0 entrance markers")
assert(core:find('ICON_ENTRANCE', 1, true), "Core.lua must define the entrance flag icon")

print(string.format("Instance entrances: total=%d dungeons=%d raids=%d distinct=%d", total, dungeons, raids, distinctEntrances))
LUA
}

localization_tooltip_keys() {
    local lua_bin=""
    if command -v lua5.1 >/dev/null 2>&1; then
        lua_bin="lua5.1"
    elif command -v lua >/dev/null 2>&1; then
        lua_bin="lua"
    else
        echo "lua5.1/lua is required for localization validation" >&2
        return 127
    fi

    "$lua_bin" - <<'LUA'
local ns = {}
for _, path in ipairs({ "Localizations/enUS.lua", "Localizations/ukUA.lua" }) do
    local chunk, err = loadfile(path)
    assert(chunk, err)
    chunk("Forever_Instances", ns)
end

local required = {
    "TERRITORY", "TERRITORY_ALLIANCE", "TERRITORY_HORDE", "TERRITORY_CONTESTED",
    "BOSSES_LABEL", "LOCATION_LABEL", "ENTRANCE_LABEL", "INSTANCE_POINT_LABEL",
    "ENTRANCE_MARKER", "ACCESS_LABEL", "ENTRANCE_FOREVER_MAP",
    "ENTRANCE_INSTANCE_PORTAL", "ENTRANCE_SECONDARY",
    "ENTRANCE_MARAUDON_STONE_DOOR", "ENTRANCE_FOREVER_PORTAL",
    "ENTRANCE_SERVICE_GATE", "OVERVIEW", "FOREVER_CHANGES", "NOTES",
    "RIGHT_CLICK_TOMTOM", "SHIFT_CLICK_ATLAS",
    "CLASSIC_INSTANCES", "CLASSIC_INSTANCES_DESC",
    "FOREVER_INSTANCES", "FOREVER_INSTANCES_DESC",
}
for _, locale in ipairs({ "enUS", "ukUA" }) do
    local bucket = assert(ns.Locales and ns.Locales[locale], "missing locale " .. locale)
    for _, key in ipairs(required) do
        assert(type(bucket[key]) == "string" and bucket[key] ~= "", locale .. " missing tooltip key " .. key)
    end
end
LUA
}

atlas_metadata_data() {
    local lua_bin=""
    if command -v lua5.1 >/dev/null 2>&1; then
        lua_bin="lua5.1"
    elif command -v lua >/dev/null 2>&1; then
        lua_bin="lua"
    else
        echo "lua5.1/lua is required for Atlas metadata validation" >&2
        return 127
    fi

    "$lua_bin" - <<'LUA'
local ns = {}
for _, path in ipairs({ "Database.lua", "AtlasData.lua" }) do
    local chunk, err = loadfile(path)
    assert(chunk, err)
    chunk("Forever_Instances", ns)
end

assert(ns.AtlasData, "AtlasData.lua did not initialize ns.AtlasData")
assert(ns.AtlasData.sourceVersion == "v1.53.00", "unexpected Atlas source version")
assert(ns.AtlasData.sourceClientBuild == "1.60.1.69913", "unexpected Atlas Forever source build")

local total, withInstance, withZone = 0, 0, 0
local function validate(bucket)
    for _, group in pairs(bucket or {}) do
        for id, instance in pairs(group or {}) do
            total = total + 1
            local meta = assert(instance.atlas, "missing Atlas metadata for " .. tostring(id))
            assert(type(meta.instanceAreaIDs) == "table", "missing Atlas instanceAreaIDs for " .. tostring(id))
            assert(type(meta.zoneAreaIDs) == "table", "missing Atlas zoneAreaIDs for " .. tostring(id))
            if #meta.instanceAreaIDs > 0 then withInstance = withInstance + 1 end
            if #meta.zoneAreaIDs > 0 then withZone = withZone + 1 end
        end
    end
end
validate(ns.DB.Dungeons)
validate(ns.DB.Raids)

assert(total == 37, "expected Atlas metadata for 37 instances, got " .. tostring(total))
assert(withInstance == 33, "expected 33 direct Atlas instance AreaID matches, got " .. tostring(withInstance))
assert(withZone == 37, "expected zone AreaIDs for all 37 instances, got " .. tostring(withZone))
assert(ns.DB.Dungeons.Forever.hall_of_thanes.atlas.instanceAreaIDs[1] == 16919, "Hall of Thanes Atlas AreaID mismatch")
assert(ns.DB.Dungeons.Forever.kroldok_stronghold.atlas.instanceAreaIDs[1] == 17780, "Krol'dok Atlas AreaID mismatch")
assert(ns.DB.Dungeons.Forever.shapers_terrace.atlas.instanceAreaIDs[1] == 16985, "Shaper's Terrace Atlas AreaID mismatch")

local core = assert(io.open("Core.lua", "rb")):read("*a")
assert(core:find('findAtlasMapKey', 1, true), "Core.lua must provide optional Atlas map matching")
assert(core:find('openAtlasMap', 1, true), "Core.lua must provide optional Atlas map opening")
assert(core:find('SHIFT_CLICK_ATLAS', 1, true), "Core.lua must expose Atlas tooltip action")
print(string.format("Atlas metadata: total=%d direct-instance=%d zone=%d", total, withInstance, withZone))
LUA
}

stage "Lua syntax"             lua_syntax
stage "Content classification" content_classification_data
stage "Dungeon territory data" dungeon_territory_data
stage "Entrance coordinate data" entrance_coordinate_data
stage "Atlas metadata"          atlas_metadata_data
stage "Tooltip localization"   localization_tooltip_keys
stage "Release file layout"   release_layout
stage "Forever-only TOC"      toc_forever_only
stage "Release version applied" release_version_applied
stage "Changelog matches TOC" changelog_matches_version
stage "Package metadata"      pkgmeta_valid
stage "Release workflow"       workflow_config

echo ""
if [[ $failures -eq 0 ]]; then
    echo "ALL CHECKS PASSED"
else
    echo "${failures} STAGE(S) FAILED"
fi
exit $failures
