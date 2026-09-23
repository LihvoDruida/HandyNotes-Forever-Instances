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
        "LegacyFallback.lua"
        "Localizations/enUS.lua"
        "Localizations/ukUA.lua"
        "dungeon.tga"
        "raid.tga"
        "forever_dungeon.tga"
        "icon.tga"
        "CHANGELOG.md"
        "LICENSE.md"
        "THIRD_PARTY_NOTICES.md"
        ".pkgmeta"
        ".github/workflows/release.yml"
        "release.sh"
        "check_all.sh"
        "RELEASING.md"
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
assert(counts.Alliance == 4, "expected 4 Alliance-territory dungeons, got " .. tostring(counts.Alliance))
assert(counts.Horde == 7, "expected 7 Horde-territory dungeons, got " .. tostring(counts.Horde))
assert(counts.Contested == 17, "expected 17 contested dungeons, got " .. tostring(counts.Contested))
print(string.format("Dungeon territories: Alliance=%d Horde=%d Contested=%d", counts.Alliance, counts.Horde, counts.Contested))
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
    "BOSSES_LABEL", "LOCATION_LABEL", "ENTRANCE_LABEL", "OVERVIEW",
    "FOREVER_CHANGES", "NOTES", "RIGHT_CLICK_TOMTOM",
}
for _, locale in ipairs({ "enUS", "ukUA" }) do
    local bucket = assert(ns.Locales and ns.Locales[locale], "missing locale " .. locale)
    for _, key in ipairs(required) do
        assert(type(bucket[key]) == "string" and bucket[key] ~= "", locale .. " missing tooltip key " .. key)
    end
end
LUA
}

stage "Lua syntax"             lua_syntax
stage "Dungeon territory data" dungeon_territory_data
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
