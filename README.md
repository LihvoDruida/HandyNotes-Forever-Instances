# Forever Instances — Dungeon & Raid Pins for HandyNotes

**Forever Instances** is a World of Warcraft: Forever (`Interface 16001`) HandyNotes plugin for dungeon and raid locations. It also adds a searchable instance browser to the World Map quest-log sidebar.

## Current data model

`Database.lua` is the only location database used at runtime.

- Canonical catalog: **28 dungeons + 9 raids**.
- Browser catalog: **44 rows** after expanding Scarlet Monastery, Dire Maul, Blackrock Spire, and Stratholme into their individual wings.
- **42** browser rows have a canonical location.
- **2** rows remain intentionally unresolved: Barrow Deeps and Hyjal Summit.
- Dungeon level ranges, instance IDs, canonical entrance locations, and wing splits are synchronized from the supplied `Instances.lua` data where present.
- Boss and loot tables from that supplied file are **not imported**.

### One coordinate, one marker

Every rendered browser/map entry has at most one stored location:

```text
mapID + x + y
```

That exact record is consumed by:

- the world-map instance browser;
- HandyNotes world/minimap pins;
- World Map navigation;
- TomTom waypoints.

There are no separate `entrance`, `alternateEntrances`, `mapPoints`, or legacy fallback coordinate databases. Multi-wing instances store coordinates only on the wing rows; their aggregate parent record is metadata-only and does not create another pin. Any continent/world projection is calculated at runtime from the same canonical zone point and is never stored as another location.

## World Map browser

The browser is implemented independently but follows the same proven quest-log map layout used by stable map-search addons on Forever:

- a plain `QuestMapFrame` sibling tab drawn with Blizzard's `QuestLog-tab-side`, selected-glow, and hover-glow atlases;
- Blizzard's `Dungeon` atlas for the tab glyph, with the local texture only as a compatibility fallback;
- `SearchBoxTemplate` aligned to Blizzard's live quest search box;
- a plain scroll frame with Blizzard `MinimalScrollBar`, 24 px wheel steps, and the stock quest-log scrollbar offsets;
- `QuestLogBorderFrameTemplate` and `QuestLog-main-background`;
- content aligned to `QuestMapFrame.ContentsAnchor`, with the panel starting below the stock 29 px search strip and using the stock 22 px right inset;
- no insertion into Blizzard `TabButtons` or `ContentFrames`;
- the Forever Instances tab deliberately has no foreign `displayMode`, so other addons cannot create a mutual/circular anchor chain with it;
- visible direct `QuestMapFrame` tabs that already participate in the established `displayMode` chain are used read-only as the placement reference;
- a small bounded set of deferred layout passes handles tabs registered just after the map opens, without a continuous geometry watcher or hard-coded addon names.

The browser does **not** insert itself into `QuestMapFrame.TabButtons` or `ContentFrames`, and does not create its own MapCanvas pin. This avoids the protected-action taint chain previously observed through `Button:SetPassThroughButtons()`.

## Instance list

Rows are grouped by continent and can be collapsed when not searching. Each row displays:

- canonical instance/wing name;
- dungeon or raid type;
- level range;
- zone;
- map/TomTom navigation using the same canonical point as the HandyNotes marker.

Search filters the same 44-row browser dataset directly.

## Localization

Supported addon UI languages:

- English (`enUS`) — default/fallback;
- Українська (`ukUA`).

Dungeon, raid, and wing names remain canonical and are not translated. Addon-generated labels and descriptions are stored in `Localizations/enUS.lua` and `Localizations/ukUA.lua`.

## In-game regression test

Run:

```text
/fitest
```

or:

```text
/foreverinstancetest
```

outside combat. The live test checks the database, all browser rows, canonical coordinate contract, HandyNotes/AceDB availability, C_Map resolution, Blizzard-native detached sidebar geometry, side-tab collision avoidance, list/search behavior, map navigation, Lua errors, and protected-action events.

Use:

```text
/fitest show
```

to reopen the most recent report from the current session.

## Runtime files

- `Forever_Instances_Camelot.toc`
- `Database.lua`
- `AtlasData.lua`
- `Core.lua`
- `InstanceBrowser.lua`
- `Diagnostic.lua`
- `Localizations/enUS.lua`
- `Localizations/ukUA.lua`
- `dungeon.tga`
- `forever_dungeon.tga`
- `raid.tga`
- `icon.tga`

Repository documentation is intentionally limited to `README.md`, `CHANGELOG.md`, `LICENSE.md`, and `THIRD_PARTY_NOTICES.md`.

## Optional integrations

- **TomTom** — waypoint/crazy-arrow navigation.
- **Atlas** — optional instance-map opening when a matching Atlas map is available.

## Validation and releases

`check_all.sh` validates Lua syntax when `luac` is available, database integrity, the single-coordinate contract, localization parity, the independent Blizzard-native UI structure, generic side-tab collision handling, live diagnostic surface, source hygiene, release layout, TOC metadata, and the GitHub/CurseForge release workflow.

The GitHub Actions release workflow installs Lua 5.1 before running the validation gate, then packages the addon as `Forever_Instances`.
