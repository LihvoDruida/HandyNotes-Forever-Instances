#!/usr/bin/env bash
# Prepare and optionally publish a release in the same style as Max_Camera_Distance.
#
#   ./release.sh 1.0.7
#   ./release.sh v1.0.7 --push
#
# The script:
#   1. validates the repository state;
#   2. changes the TOC version;
#   3. generates the release changelog from git commits with git-cliff;
#   4. runs the full pre-release gate;
#   5. creates the conventional release commit and annotated tag;
#   6. with --push, pushes commit + tag and lets GitHub Actions publish CurseForge.
set -euo pipefail

cd "$(dirname "$0")"

usage() {
    echo "Usage: $0 <X.Y.Z|vX.Y.Z> [--push]" >&2
    exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage
RAW_VERSION="$1"
PUSH=false
if [[ ${2:-} == "--push" ]]; then
    PUSH=true
elif [[ $# -eq 2 ]]; then
    usage
fi

if [[ "$RAW_VERSION" =~ ^v?([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    VERSION="${BASH_REMATCH[1]}"
    TAG="v${VERSION}"
else
    echo "Invalid version: $RAW_VERSION (expected X.Y.Z or vX.Y.Z)" >&2
    exit 2
fi

for command in git python3 git-cliff; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "$command is required." >&2
        exit 127
    fi
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "release.sh must be run inside the git repository." >&2
    exit 2
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Working tree is not clean. Commit or stash changes before preparing a release." >&2
    git status --short >&2
    exit 1
fi

if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Tag already exists: $TAG" >&2
    exit 1
fi

CURRENT_VERSION=$(sed -n 's/^## Version:[[:space:]]*v\{0,1\}//p' HandyNotes_ForeverInstances_Camelot.toc | head -n1 | tr -d '\r')
echo "Preparing release: ${CURRENT_VERSION:-unknown} -> $TAG"

python3 tools/set_version.py "$TAG"

# Generate only commits since the latest release tag and prepend the new block.
# The release preparation commit itself is excluded by cliff.toml on future runs.
echo "Generating CHANGELOG.md from git history..."
git-cliff --unreleased --tag "$TAG" --prepend CHANGELOG.md

# Make tag/version matching testable before the actual tag exists.
GITHUB_REF_NAME="$TAG" bash ./check_all.sh

# Only release-controlled files should have changed at this point.
UNEXPECTED=$(git status --porcelain | awk '{print $2}' | grep -Ev '^(HandyNotes_ForeverInstances_Camelot\.toc|CHANGELOG\.md)$' || true)
if [[ -n "$UNEXPECTED" ]]; then
    echo "Unexpected files changed during release preparation:" >&2
    echo "$UNEXPECTED" | sed 's/^/  /' >&2
    exit 1
fi

git add HandyNotes_ForeverInstances_Camelot.toc CHANGELOG.md
git commit -m "chore(release): prepare for $TAG"
git tag -a "$TAG" -m "HandyNotes: Forever Instances $TAG"

echo ""
echo "Prepared $TAG"
echo "  version:   TOC -> $TAG"
echo "  changelog: generated from commits"
echo "  commit:    chore(release): prepare for $TAG"
echo "  tag:       $TAG"

if $PUSH; then
    echo "Pushing release commit and tag..."
    git push origin HEAD
    git push origin "$TAG"
    echo "GitHub Actions will package the addon and publish the CurseForge release."
else
    echo ""
    echo "Not pushed yet. Review the result, then run:"
    echo "  git push origin HEAD"
    echo "  git push origin $TAG"
    echo "or rerun the next release with --push."
fi
