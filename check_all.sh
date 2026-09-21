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
    done < <(find . -maxdepth 1 -name '*.lua' -print0)
    return $rc
}

release_layout() {
    local required=(
        "HandyNotes_ForeverInstances_Camelot.toc"
        "Core.lua"
        "Database.lua"
        "LegacyFallback.lua"
        "dungeon.tga"
        "raid.tga"
        "forever_dungeon.tga"
        "icon.tga"
        "CHANGELOG.md"
        "LICENSE.md"
        "THIRD_PARTY_NOTICES.md"
        ".pkgmeta"
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
    local toc="HandyNotes_ForeverInstances_Camelot.toc"
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

    [[ "$(basename "$(find . -maxdepth 1 -name '*.toc' -print -quit)")" == "HandyNotes_ForeverInstances_Camelot.toc" ]]
}

tag_matches_version() {
    # Local validation without a release tag is allowed. release.sh and CI set GITHUB_REF_NAME.
    local tag="${GITHUB_REF_NAME:-}"
    [[ -z "$tag" ]] && return 0

    local version
    version=$(sed -n 's/^## Version:[[:space:]]*//p' HandyNotes_ForeverInstances_Camelot.toc | head -n1 | tr -d '\r')
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
    version=$(sed -n 's/^## Version:[[:space:]]*v\{0,1\}//p' HandyNotes_ForeverInstances_Camelot.toc | head -n1 | tr -d '\r')
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
    grep -Eq '^package-as:[[:space:]]*HandyNotes_ForeverInstances$' .pkgmeta || return 1
    grep -Eq '^manual-changelog:' .pkgmeta || return 1
    grep -Eq '^[[:space:]]+-[[:space:]]+\.github$' .pkgmeta || return 1
}

stage "Lua syntax"             lua_syntax
stage "Release file layout"   release_layout
stage "Forever-only TOC"      toc_forever_only
stage "Tag matches TOC"       tag_matches_version
stage "Changelog matches TOC" changelog_matches_version
stage "Package metadata"      pkgmeta_valid

echo ""
if [[ $failures -eq 0 ]]; then
    echo "ALL CHECKS PASSED"
else
    echo "${failures} STAGE(S) FAILED"
fi
exit $failures
