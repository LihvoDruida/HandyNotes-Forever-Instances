# Forever Instances — Dungeon & Raid Pins for HandyNotes

**Forever Instances — Dungeon & Raid Pins for HandyNotes** is a **World of Warcraft: Forever only** plugin
for **HandyNotes** that marks dungeon and raid entrances on the map and minimap.

This build was rebuilt from the supplied classic HandyNotes base addon and merged
with the supplied `WoWForeverInstances.lua` database.

## Addon identity

- CurseForge / display name: **Forever Instances — Dungeon & Raid Pins for HandyNotes**
- Installed addon folder: `Forever_Instances`
- Forever TOC: `Forever_Instances_Camelot.toc`

## Supported client

- **WoW Forever only**
- Loads only through `Forever_Instances_Camelot.toc`
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
- Uses one unified tooltip layout for every dungeon and raid:
  - canonical instance name and status row
  - faction territory for dungeons
  - boss count, location, and entrance details
  - description / Forever changes / wings / notes in consistent sections
  - TomTom action shown in the same place on every tooltip
- Dungeon faction-territory tags use faction-aware colors:
  - **Alliance** — blue
  - **Horde** — red
  - **Contested** — gold


## Dungeon faction territory

The current Forever dungeon catalog is normalized into three territory groups for tooltip context:

- **5 Alliance-territory dungeons**
- **7 Horde-territory dungeons**
- **16 Contested dungeons**

These labels describe the faction territory around the dungeon entrance, not a blanket access restriction. Dungeon, raid, and wing names remain canonical and untranslated.

Blackfathom Deeps keeps the legacy/Ashenvale main location as a separate map point, but its **territory is Alliance** because the current Forever entrance catalog places the access point in Darkshore. The conflicting locations remain explicit in the database instead of silently discarding either source.

## Localization

The addon uses two explicit language databases:

- **English** — default and fallback language.
- **Українська** — selectable from the HandyNotes plugin settings.

All addon-generated strings, instance descriptions, database notes, and Forever
change summaries are referenced by localization keys. The translations live only in
`Localizations/enUS.lua` and `Localizations/ukUA.lua`.

**Dungeon, raid, and wing names are not translated.** Their canonical names remain
in `Database.lua` and are displayed exactly as stored there. Zone names are read
from `C_Map` when available, so the game client can still provide its own localized
zone names.


## Main point vs entrance point

Every dungeon and raid record has two coordinate concepts:

- top-level `x` / `y` — the primary map point for the instance/location;
- `entrance = { x, y }` — an additional entrance/access point shown with the green flag.

The `entrance` block is mandatory for every record. `0.0, 0.0` means that the
separate entrance is unknown **or** would duplicate the primary point. In both
cases the addon intentionally does not render a green entrance flag.

A non-zero entrance is rendered only when it is distinct from the main point.
The entrance may also specify its own `zone` when the access point is represented
on a different map from the primary instance location.

## Data merge rules

1. `Database.lua` is authoritative.
2. Old addon coordinates **never overwrite** coordinates already present in the new database.
3. Old coordinates are copied only when:
   - the record exists in both databases, and
   - the new record is missing valid numeric `x/y` values.
4. Instances that exist only in the new Forever database stay untouched.
5. Records with no reliable coordinates remain unresolved instead of being placed at fake positions.

## Icon system

The addon uses four clear marker groups:

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


## Localization architecture

All addon-generated text is centralized through localization keys. The translation
databases are stored separately:

- `Localizations/enUS.lua` — English, loaded first and used as the fallback/default.
- `Localizations/ukUA.lua` — Ukrainian.

`Database.lua` stores only localization keys for descriptions, notes, and Forever
change text (`descriptionKey`, `noteKey`, `foreverChangeKey`). It no longer stores
parallel English/Ukrainian prose fields.

**Dungeon and raid names are not translated.** Canonical instance names and wing
names remain in `Database.lua` and are shown exactly as stored there.

## Files included

- `Forever_Instances_Camelot.toc`
- `Localizations/enUS.lua` and `Localizations/ukUA.lua`
- `Database.lua`
- `LegacyFallback.lua`
- `Core.lua`
- `dungeon.tga`
- `raid.tga`
- `forever_dungeon.tga`
- `entrance_flag.tga`
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

## Atlas integration

The addon includes an optional metadata bridge generated from the supplied **Atlas v1.53.00** `AreaIDs_ClassicForever.lua` table (Atlas marks that table as updated for WoW Forever 1.60.1.69913).

- Atlas instance AreaIDs and outdoor-zone AreaIDs are attached to every dungeon/raid record where Atlas provides them.
- Atlas metadata never overwrites the addon's verified world-map `x/y` coordinates.
- The supplied Atlas core does **not** contain outdoor world-map X/Y coordinates; its relevant location data is AreaID-based.
- If Atlas plus an Atlas map module/fork is installed and exposes a matching map in `AtlasMaps`, **Shift + left-click** on a Forever Instances pin opens the corresponding Atlas instance map.
- Atlas remains completely optional; no Atlas code is bundled or required at runtime.

See `ATLAS_AUDIT.md` in the source package for the per-instance AreaID mapping.

### Filter behavior

The four HandyNotes filters are two independent dimensions and combine with **AND** logic:

- `Dungeons` / `Raids` select the content type.
- `Classic-era instances` / `Forever-new instances` select the content generation.

Every top-level database record carries explicit `contentType` and `era` metadata, so filtering no longer depends on transient runtime fields. Existing SavedVariables with missing filter keys migrate to enabled defaults. Filter changes invalidate the Azeroth projection cache and directly refresh the HandyNotes plugin map, with the normal HandyNotes message path retained as a compatibility fallback.


## Source classification audit

See `CONTENT_CLASSIFICATION_AUDIT.md` in the source package for the complete 37-instance Classic/Forever and Dungeon/Raid classification review, source list, and documented cross-source conflicts.

## Filter semantics

The two status filters are intentionally **overlapping**:

- **Classic-era instances** — all Classic-origin dungeons and raids.
- **Forever: new or updated** — every brand-new Forever instance plus any Classic-origin instance with a documented Forever-specific update.

This means disabling **Classic-era instances** while leaving **Forever: new or updated** enabled keeps all new/updated Forever-relevant content visible.
