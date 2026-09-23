## v1.0.11

- add green-flag approach markers for instances with separate approach coordinates
- unify approach tooltip rendering with the main tooltip system
- add approach marker support for Maraudon and Razorfen Downs
- refresh marker verification and keep unresolved cases on the main verified entrance only

# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### 🐛 Bug Fixes
- Make the requested release/tag version authoritative and rewrite the TOC before CI validation and packaging.
- Support two-part versions such as `v1.0` in addition to three-part versions such as `v1.0.10`.
- Generate the current-tag changelog in CI when the requested release section is not already present.

## [1.0.10] - 2026-09-21

- allow `CURSEFORGE_PROJECT_ID` to be read from a repository secret with repository-variable fallback
- make BigWigs Packager use the resolved project ID environment value
- extend release validation for the GitHub/CurseForge workflow contract

### 🛠️ Refactor
- Replace the monolithic `Localization.lua` with separate `Localizations/enUS.lua` and `Localizations/ukUA.lua` translation databases.
- Make English the default/fallback addon language; keep Ukrainian available through the language selector.
- Move instance descriptions, notes, and Forever-change text out of `Database.lua` and reference them only through localization keys.
- Remove scattered `descriptionUk` / `foreverChangeUk` fields and English-to-Ukrainian lookup tables.
- Keep dungeon, raid, and wing names canonical and untranslated in every language.
- Add release validation for locale-key parity, missing localization references, and accidental instance-name localization.

## [1.0.9] - 2026-09-21

### 🚀 New Features
- Expand the Forever data model to explicitly track Classic-origin content that is available in Forever without duplicating map pins.
- Add unified English and Ukrainian descriptions for all 28 dungeons and all 9 raids.
- Add source-backed boss counts where currently published.
- Add Barrow Deeps and Hyjal Summit boss rosters from the current Forever Legacy raid objectives.
- Add provenance/status labels: `Forever • New`, `Classic • Forever`, and `Classic • Forever • Updated`.
- Add a tooltip option for instance descriptions and display of boss counts.

### 🛠️ Refactor
- Mark returning Classic dungeons as updated in Forever because dungeon boss loot is reworked across old and new dungeons.
- Mark Molten Core and Onyxia's Lair with their confirmed Forever progression/tier changes.
- Keep unnamed future roadmap raids out of the map database until a confirmed name and location exist.
- Bump database schema to version 2.

## [1.0.8] - 2026-09-21

### 🚀 New Features
- Add runtime language switching with **Auto / Українська / English** modes.
- Default language now follows the WoW client locale; `ukUA` automatically uses Ukrainian and unsupported locales fall back to English.
- Add full Ukrainian translation for addon settings, tooltip labels, player counts, coordinate labels, filter names, and database notes.
- Use the client-localized zone name from `C_Map` in tooltips when available.

### 🛠️ Refactor
- Move localization strings and translated database text into a dedicated `Localization.lua` module.
- Keep canonical instance names from the database unchanged to avoid mismatches with source data while localizing addon-generated UI around them.

## [1.0.7] - 2026-09-21

### ⚙️ Miscellaneous Tasks
- Port the Max Camera Distance release preparation flow: centralized version bump, git-cliff changelog generation, conventional release commit and annotated tag.
- Add `cliff.toml` and `tools/set_version.py`.
- Make `release.sh` generate release notes before triggering the existing CurseForge publish pipeline.

# 1.0.6

- Ported the CurseForge release pipeline from Max Camera Distance.
- Added BigWigs Packager configuration through `.pkgmeta`.
- Added tag-triggered GitHub Actions publishing for `v*` releases.
- Added strict pre-release validation for Lua syntax, Forever-only TOC layout, required release files, package metadata, and tag/version consistency.
- Added local `release.sh` wrapper for packaging and CurseForge upload.
- CurseForge project ID is supplied through the `CURSEFORGE_PROJECT_ID` repository variable instead of being hard-coded into the addon.
- CurseForge API authentication uses the `CF_API_KEY` repository secret, with both current packager token environment names populated for compatibility.
- Added `RELEASING.md` with release and repository-setup instructions.

# 1.0.5

- Fixed incorrect instance-marker placement on the Azeroth/global map.
- Global-map positions are now calculated explicitly with `C_Map.GetMapRectOnMap()` instead of relying on generic zone-to-world translation.
- Added recursive parent-map projection fallback for maps that do not expose a direct rectangle to Azeroth.
- Global-map tooltip/click handling now resolves projected pins back to their original zone records.
- TomTom waypoints created from the Azeroth map now use the original zone coordinates instead of projected display coordinates.
- Restored license/third-party notice files that were accidentally omitted from the 1.0.4 package.

# 1.0.4

- Fixed global Azeroth-map behavior by separating it from continent-map visibility.
- Added a dedicated `Show on Azeroth / global map` toggle.
- Global-map markers remain available by default and can be disabled independently if the map becomes too busy.
- `Show on continent maps` continues to control continent behavior only.

# 1.0.2

- Added a dedicated transparent addon icon based on the supplied runestone artwork.
- Added `icon.tga` for WoW addon metadata / TOC usage.
- Added `icon.png` and `curseforge-icon.png` for documentation and project-page usage.
- Added `## IconTexture` metadata to the `_Camelot.toc` file.
- Expanded README and added CurseForge-ready documentation text.
- Added minor runtime optimization by caching ancestor-name lookups during map resolution.

# 1.0.1

- Restored the supplied base addon's standard blue dungeon portal.
- Restored the supplied base addon's standard green raid portal.
- Added a dedicated blue-orange portal for WoW Forever-new dungeons only.
- Forever-new raids continue to use the normal green raid portal.
- Icon selection now respects active filters when several records share a coordinate.
- Removed the global gold icon tint.

# 1.0.0

- Rebuilt the supplied classic HandyNotes plugin as a WoW Forever-only addon.
- Replaced the hard-coded old instance table with the supplied consolidated
  dungeon/raid database.
- Added strict new-database-first coordinate merge logic.
- Added old-addon coordinate fallback only for matching records with missing
  new coordinates.
- Added dynamic Forever map discovery through `C_Map.GetMapChildrenInfo`.
- Added safe map-ID validation so legacy numeric IDs cannot silently point to a
  reused map.
- Added Forever-new and Classic-era filters.
- Removed dead lockout settings/code from the old addon.
- Kept optional TomTom right-click waypoints.

