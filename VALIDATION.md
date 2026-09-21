# Release pipeline validation — 1.0.8

- `.pkgmeta` follows the BigWigs Packager structure used by Max Camera Distance.
- `.github/workflows/release.yml` triggers only for `v*` tags.
- GitHub workflow validates `CURSEFORGE_PROJECT_ID` and `CF_API_KEY` before publishing.
- GitHub workflow has `contents: write` for GitHub release creation.
- `check_all.sh` validates Lua syntax, the Forever-only Camelot TOC, package layout, `.pkgmeta`, and tag/version consistency.
- `release.sh` supports local BigWigs packaging and CurseForge upload without hard-coding credentials.
- Repository-only release files are excluded from the player package via `.pkgmeta`.

# Validation report

Localization runtime checks:

- `Localization.lua` parses successfully.
- Auto language resolves `ukUA` to Ukrainian and unsupported locales to English.
- Manual Ukrainian/English overrides resolve independently of the client locale.
- Ukrainian UI keys and translated database notes were exercised in a Lua runtime smoke test.

Build-time checks completed for 1.0.8:

- Lua syntax: `Localization.lua`, `Database.lua`, `LegacyFallback.lua`, and `Core.lua` parse successfully with LuaTeX.
- Database count: 28 dungeons and 9 raids.
- Forever-new count: 9 dungeons and 2 raids.
- Missing coordinates remain limited to 2 records:
  - Barrow Deeps — Mount Hyjal.
  - Hyjal Summit — Mount Hyjal.
- No fallback coordinates are invented for unresolved records.
- Standard dungeon icon: `dungeon.tga` (blue portal).
- Standard raid icon: `raid.tga` (green portal).
- Forever-new dungeon icon: `forever_dungeon.tga` (blue-orange portal).
- Addon metadata icon: `icon.tga` with transparent background.
- Packaging contains only the Forever `_Camelot.toc` flavor file.
- Continent maps still use HandyNotes child-map handling.
- Azeroth/global map uses dedicated native projection through `C_Map.GetMapRectOnMap()`.
- Direct source-map -> Azeroth projection is attempted first.
- If a map does not expose a direct rectangle, projection walks its parent chain one map at a time.
- Projected coordinates are rejected when they fall outside normalized `0..1` map bounds.
- Global-map pins retain the original source map and source coordinate.
- Tooltips continue to resolve the original instance records.
- TomTom waypoints created from global-map pins use the original zone coordinates, never the projected Azeroth display coordinate.
- `showOnAzeroth = true` by default and remains independently configurable from continent visibility.
- `LICENSE.md` and `THIRD_PARTY_NOTICES.md` are present in the package.

## Release automation validation (1.0.7)

- `cliff.toml` mirrors the conventional-commit grouping used by Max Camera Distance.
- `tools/set_version.py` is the single deterministic version writer/checker for the Camelot TOC.
- `release.sh` now performs version bump -> changelog generation -> validation -> release commit -> annotated tag.
- `check_all.sh` verifies the current TOC version has a matching `CHANGELOG.md` release section.
- The tag-triggered GitHub Action is publish-only; release metadata is prepared and committed before the tag is pushed.
