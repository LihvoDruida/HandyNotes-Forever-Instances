# Validation report — v1.0.12

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

Validation is configured for the v1.0.12 data contract and is executed in CI where Lua 5.1/luac is available.

## GitHub / CurseForge workflow compatibility

- `CURSEFORGE_PROJECT_ID` is resolved from `secrets.CURSEFORGE_PROJECT_ID` first.
- If that secret is absent, the workflow falls back to `vars.CURSEFORGE_PROJECT_ID`.
- `CF_API_KEY` remains a repository secret.
- BigWigs Packager receives the already-resolved project ID through the workflow environment.
- `check_all.sh` now guards this workflow contract against regressions.

## Release-version authority

- The version supplied by the release tag is authoritative.
- CI rewrites `## Version` in `Forever_Instances_Camelot.toc` from `GITHUB_REF_NAME` before validation and packaging.
- Two-part versions such as `v1.0` and multi-part versions such as `v1.0.10` are accepted.
- CI discards any pre-built changelog and regenerates `CHANGELOG.md` from Git history for the requested tag.
- The pre-release gate validates the rewritten version instead of requiring the repository TOC value to match the tag before preparation.


- `CHANGELOG.md` is regenerated from Git history for every release and is never trusted as a pre-built input file.
## Tooltip / dungeon territory validation

- All 28 dungeon records now carry exactly one `territory` value: `Alliance`, `Horde`, or `Contested`.
- Expected distribution is enforced by `check_all.sh`: **4 Alliance / 7 Horde / 17 Contested**.
- All current Forever dungeon records are normalized to a 5-player base group size where the current catalog identifies them as 5-player dungeons.
- Tooltip labels for territory, bosses, location, entrance, overview, Forever changes, and notes are required in both `enUS` and `ukUA`.
- Tooltip rendering is centralized in one renderer instead of formatting each data section independently.
- Faction territory uses fixed visual semantics: Alliance blue, Horde red, Contested gold.


- Blackfathom Deeps is validated as **Contested** because the resolved entrance is in The Zoram Strand, Ashenvale; this intentionally differs from current listings that map it to Darkshore / Alliance territory.



## Coordinate / entrance audit

- Database contains 37 top-level records: 28 dungeons and 9 raids.
- Every record has an explicit `entrance = { x, y }` block.
- `entrance = { x = 0.0, y = 0.0 }` means unknown or identical to the main point.
- Zero/unknown entrance blocks never create a green flag marker.
- A defensive duplicate check also suppresses a non-zero entrance if it exactly matches the main point on the same map.
- Distinct verified entrance/access markers currently exist for Blackfathom Deeps, Gnomeregan, Uldaman back entrance, Maraudon Stone Door, Temple of Atal'Hakkar, Stratholme Service Gate, and Hall of Thanes.
- Barrow Deeps and Hyjal Summit keep unknown main coordinates and a zero entrance block until exact coordinates are published.
