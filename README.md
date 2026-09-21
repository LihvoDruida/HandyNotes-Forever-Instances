# HandyNotes: Forever Instances

**HandyNotes: Forever Instances** is a **World of Warcraft: Forever only** plugin
for **HandyNotes** that marks dungeon and raid entrances on the map and minimap.

This build was rebuilt from the supplied classic HandyNotes base addon and merged
with the supplied `WoWForeverInstances.lua` database.

## Supported client

- **WoW Forever only**
- Loads only through `HandyNotes_ForeverInstances_Camelot.toc`
- Does **not** ship Retail / Classic / Wrath / Cata / MoP TOC files

## Features

- Shows **dungeons and raids** on the zone map, continent map, and minimap.
- Global Azeroth/world-map visibility is now controlled separately to avoid map clutter.
- Uses the **new consolidated Forever database** as the main source of truth.
- Applies **legacy coordinate fallback** only when the new database has a matching
  record with missing numeric coordinates.
- Supports **TomTom right-click waypoints**.
- Includes filters for:
  - Dungeons
  - Raids
  - Classic-era instances
  - Forever-new instances
  - Separate continent-map and Azeroth/global-map visibility toggles
- Unified English / Ukrainian instance descriptions.
- Shows extra tooltip data:
  - recommended level range
  - player count
  - zone / location
  - coordinates
  - wing breakdowns
  - boss counts
  - Classic / Forever provenance and update status
  - database notes


## Localization

The addon includes a runtime language selector with three modes:

- **Auto** — default; follows the WoW client locale.
- **Українська** — forces Ukrainian.
- **English** — forces English.

When Auto is selected, a client reporting `ukUA` uses Ukrainian automatically.
Other currently unsupported client locales fall back to English. The language can be
overridden at any time from the HandyNotes plugin settings.

Localized content includes settings, filters, tooltip labels, player counts,
coordinate labels, TomTom instructions, wing labels, and database notes. Zone names
are read from the current client through `C_Map` where possible, so they follow the
client's own localization. Canonical dungeon and raid names remain the names stored
in the database.

## Data merge rules

1. `Database.lua` is authoritative.
2. Old addon coordinates **never overwrite** coordinates already present in the new database.
3. Old coordinates are copied only when:
   - the record exists in both databases, and
   - the new record is missing valid numeric `x/y` values.
4. Instances that exist only in the new Forever database stay untouched.
5. Records with no reliable coordinates remain unresolved instead of being placed at fake positions.

## Icon system

The addon now uses three clear icon groups:

- **Raids** -> standard **green** portal (`raid.tga`)
- **Existing / Classic-era dungeons** -> standard **blue** portal (`dungeon.tga`)
- **WoW Forever-new dungeons only** -> dedicated **blue-orange** portal (`forever_dungeon.tga`)

Additionally, the package now ships a dedicated addon icon:

- `icon.tga` -> transparent-background addon icon for WoW / addon metadata
- `icon.png` -> transparent PNG variant
- `curseforge-icon.png` -> larger transparent PNG for project/media usage

## Forever content classification

The database now separates **content origin** from **availability in Forever** instead of treating every returning instance as "Classic only".

Tooltip labels use three states:

- **Forever • New** — content created for WoW Forever.
- **Classic • Forever** — Classic-origin content present in Forever with no specific instance-level change currently confirmed.
- **Classic • Forever • Updated** — Classic-origin content with a confirmed Forever change.

All returning Classic dungeons are marked **Updated** because Forever reworks dungeon boss loot across both old and new dungeons. Molten Core and Onyxia's Lair also carry explicit Forever progression/tier-change notes.

## Unified instance descriptions

Every dungeon and raid now has one concise in-game description in English and Ukrainian. The text is synthesized into a single description per instance; it is intentionally **not split into separate Warcraft Tavern / WoW Handbook descriptions**.

Current catalog coverage:

- 28 dungeons
- 9 raids
- 9 Forever-new dungeons
- 2 Forever-new raids

Published boss counts are stored when available. Barrow Deeps and Hyjal Summit also include the boss rosters currently exposed by Forever's Legacy raid objectives. Unnamed future roadmap raids are not added as map entries until their names and locations are confirmed.

## Notes on missing coordinates

At build time, the only unresolved records remain:

- **Barrow Deeps**
- **Hyjal Summit**

They stay unresolved because no verified coordinates were available and the legacy base addon did not contain matching records.

## Files included

- `HandyNotes_ForeverInstances_Camelot.toc`
- `Localization.lua`
- `Database.lua`
- `LegacyFallback.lua`
- `Core.lua`
- `dungeon.tga`
- `raid.tga`
- `forever_dungeon.tga`
- `icon.tga`
- `icon.png`
- `curseforge-icon.png`
- documentation files

## Credits

- Base structure adapted from the supplied HandyNotes classic dungeon addon.
- Forever database built from the supplied `WoWForeverInstances.lua`.
- Optional waypoint integration via **TomTom**.

## Global-map coordinate handling

The Azeroth/global map uses dedicated coordinate projection. Each zone entrance is
converted into the zone rectangle returned by `C_Map.GetMapRectOnMap()` so the pin
is placed on the correct part of Kalimdor or the Eastern Kingdoms. The projected
coordinate is display-only; tooltips and TomTom waypoints still use the original
zone/map record.

## Automated releases

The repository includes a tag-based CurseForge release pipeline using the
BigWigs WoW AddOn Packager. Push a matching `v<version>` tag to package the addon,
create a GitHub release, and upload it to CurseForge after the pre-release gate
passes. See `RELEASING.md` for required GitHub variables/secrets and release steps.
