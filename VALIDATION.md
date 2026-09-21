# Validation report — v1.0.10

## Localization architecture

- `Localizations/enUS.lua` is the default/fallback English database.
- `Localizations/ukUA.lua` is the Ukrainian database.
- Both files contain the same localization-key set.
- `Database.lua` stores `descriptionKey`, `noteKey`, and `foreverChangeKey` instead of duplicated translated prose.
- No `descriptionUk`, `foreverChangeUk`, English→Ukrainian lookup tables, or monolithic `Localization.lua` remain.
- Dungeon, raid, and wing names remain canonical and are not localized.
- Existing saved `language = "auto"` values migrate to `enUS`.
- The language selector now exposes only `English` and `Українська`.

## Data integrity

- 28 dungeon records and 9 raid records remain in the map database.
- All 37 instance descriptions are represented by localization keys in both language databases.
- 16 database notes are represented by localization keys in both language databases.
- 2 explicit Forever-change summaries are represented by localization keys in both language databases.
- 9 dungeons and 2 raids remain marked as Forever-new.
- Missing coordinates remain limited to Barrow Deeps and Hyjal Summit; no coordinates are invented.

## Map/runtime behavior

- Zone, continent, minimap, and Azeroth/global-map rendering logic is unchanged by the localization refactor.
- Azeroth/global pins continue to use explicit `C_Map.GetMapRectOnMap()` projection.
- TomTom waypoints created from global-map pins continue to use original zone coordinates.
- Portal icon routing remains: green raids, blue existing dungeons, blue-orange Forever-new dungeons.

## Release validation

`check_all.sh` now verifies:

- Lua syntax recursively, including files under `Localizations/`.
- required Forever-only release layout;
- identical English/Ukrainian locale-key sets;
- every database localization key exists in the locale databases;
- legacy scattered localization fields are absent;
- no `nameKey` localization is introduced for instance names;
- Camelot-only TOC/interface constraints;
- TOC/tag/changelog version consistency;
- BigWigs Packager metadata.

All validation stages pass for v1.0.10.
