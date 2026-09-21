# Release workflow

The release system mirrors the workflow used by Max Camera Distance:

1. **Version is changed centrally in the Camelot TOC.**
2. **`git-cliff` builds the release changelog from commit history.**
3. The full release gate runs.
4. A `chore(release): prepare for vX.Y.Z` commit is created.
5. An annotated `vX.Y.Z` tag is created.
6. Pushing that tag triggers GitHub Actions.
7. BigWigs Packager creates the addon ZIP and publishes it to CurseForge.

## Commit format

Use conventional commits so the generated changelog is grouped correctly:

```text
feat: add new instance filter
fix(map): correct Azeroth marker projection
perf(map): cache resolved map transforms
refactor: simplify node collection
chore: update project metadata
```

`doc`, `style`, and `test` commits are intentionally omitted from public release notes by `cliff.toml`.

## Prepare a release

Install `git-cliff`, then run from a clean git checkout:

```bash
./release.sh 1.0.7
```

or:

```bash
./release.sh v1.0.7
```

The script automatically:

- updates `## Version` to `v1.0.7`;
- generates and prepends the `1.0.7` section in `CHANGELOG.md`;
- validates that the tag and TOC version match;
- runs `check_all.sh`;
- creates the release commit;
- creates the annotated tag.

Review the result and push:

```bash
git push origin HEAD
git push origin v1.0.7
```

Or let the release script push immediately:

```bash
./release.sh 1.0.7 --push
```

## CurseForge configuration

`CURSEFORGE_PROJECT_ID` may be stored either as a **repository secret** or a
**repository variable**. The workflow checks the secret first and falls back to
the variable. This means the current GitHub setup with both values under
`Repository secrets` works without moving the project ID.

Repository secrets:

```text
CURSEFORGE_PROJECT_ID=<project id>
CF_API_KEY=<CurseForge token>
```

Alternatively, keep only `CF_API_KEY` as a secret and put the non-sensitive
project ID under **Actions -> Variables**:

```text
CURSEFORGE_PROJECT_ID=<project id>
```

Resolution order used by the workflow:

```text
secrets.CURSEFORGE_PROJECT_ID
        ↓ if empty
vars.CURSEFORGE_PROJECT_ID
```

The tag-triggered GitHub workflow uses `BigWigsMods/packager@v2` and `.pkgmeta`.
`CHANGELOG.md` is supplied to the packager as the manual release changelog.

## Files responsible for releases

- `release.sh` — version bump, changelog, validation, commit and tag
- `tools/set_version.py` — deterministic TOC version writer/checker
- `cliff.toml` — changelog grouping/rules
- `check_all.sh` — release gate
- `.pkgmeta` — BigWigs/CurseForge package metadata
- `.github/workflows/release.yml` — tag-triggered publish pipeline

## Shell script permissions

GitHub Actions invokes the pre-release gate as:

```bash
bash ./check_all.sh
```

and `release.sh` invokes it the same way. This is intentional: the release pipeline does not depend on the repository preserving the Unix executable bit, which is especially useful when commits are prepared from Windows.

You may still keep the scripts executable locally with:

```bash
git update-index --chmod=+x check_all.sh release.sh
```

but it is no longer required for CI.
