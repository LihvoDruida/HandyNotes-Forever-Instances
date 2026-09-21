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
    fi

    local rc=0
    if [[ -n "$compiler" ]]; then
        while IFS= read -r -d '' f; do
            "$compiler" -p "$f" || rc=1
        done < <(find . -type f -name '*.lua' ! -path './tools/*' -print0)
        return $rc
    fi

    if command -v luatex >/dev/null 2>&1; then
        local checker
        checker=$(mktemp)
        cat >"$checker" <<'LUA'
for i = 1, #arg do
    local chunk, err = loadfile(arg[i])
    if not chunk then
        io.stderr:write(arg[i] .. ": " .. tostring(err) .. "\n")
        os.exit(1)
    end
end
LUA
        local files=()
        while IFS= read -r -d '' f; do files+=("$f"); done < <(find . -type f -name '*.lua' ! -path './tools/*' -print0)
        luatex --luaonly "$checker" "${files[@]}" || rc=1
        rm -f "$checker"
        return $rc
    fi

    echo "luac5.1, luac, or luatex is required for the Lua syntax gate" >&2
    return 127
}

release_layout() {
    local required=(
        "HandyNotes_ForeverInstances_Camelot.toc"
        "Core.lua"
        "Localizations/enUS.lua"
        "Localizations/ukUA.lua"
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


localization_layout() {
    python3 - <<'PY'
from pathlib import Path
import re

root = Path('.')
en = (root / 'Localizations/enUS.lua').read_text(encoding='utf-8')
uk = (root / 'Localizations/ukUA.lua').read_text(encoding='utf-8')
db = (root / 'Database.lua').read_text(encoding='utf-8')
core = (root / 'Core.lua').read_text(encoding='utf-8')

def keys(text):
    return set(re.findall(r'^\s*([A-Z0-9_]+)\s*=', text, re.M))

en_keys = keys(en)
uk_keys = keys(uk)
if en_keys != uk_keys:
    print('localization key mismatch', file=__import__('sys').stderr)
    print('missing in ukUA:', sorted(en_keys - uk_keys), file=__import__('sys').stderr)
    print('missing in enUS:', sorted(uk_keys - en_keys), file=__import__('sys').stderr)
    raise SystemExit(1)

for legacy in ('descriptionUk', 'foreverChangeUk', 'Localization.lua', 'LocalizeDisplayName', 'LocalizeDatabaseText'):
    if legacy in db or legacy in core:
        print(f'legacy localization pattern remains: {legacy}', file=__import__('sys').stderr)
        raise SystemExit(1)

# Instance names stay canonical in Database.lua and must not become locale keys.
if re.search(r'\bnameKey\s*=', db):
    print('instance names must not be localized via nameKey', file=__import__('sys').stderr)
    raise SystemExit(1)

for field in ('descriptionKey', 'noteKey', 'foreverChangeKey'):
    for key in re.findall(rf'\b{field}\s*=\s*"([A-Z0-9_]+)"', db):
        if key not in en_keys:
            print(f'{field} references missing locale key: {key}', file=__import__('sys').stderr)
            raise SystemExit(1)

print(f'Localization OK: {len(en_keys)} shared keys; English default; canonical instance names unchanged')
PY
}

stage "Lua syntax"             lua_syntax
stage "Release file layout"   release_layout
stage "Localization layout"    localization_layout
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
