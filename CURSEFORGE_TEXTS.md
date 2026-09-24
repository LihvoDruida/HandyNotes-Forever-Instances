# CurseForge texts

## Project title

Forever Instances — Dungeon & Raid Pins for HandyNotes

## Short summary

A WoW Forever-only HandyNotes plugin that marks dungeon and raid entrances on the map and minimap using a merged Forever instance database with safe legacy-coordinate fallback.

## Short description

Forever Instances — Dungeon & Raid Pins for HandyNotes adds dungeon and raid entrance markers to your map in **World of Warcraft: Forever**.

It is built specifically for the **Forever client**, uses a consolidated database for both classic-era and Forever-new instances, supports optional **TomTom** waypoints, and keeps clear icon colors for raids, normal dungeons, and Forever-only dungeons.

## Full project description

### Overview

**Forever Instances — Dungeon & Raid Pins for HandyNotes** is a **WoW Forever-only** map plugin for **HandyNotes**.
It shows dungeon and raid entrances on zone maps, continent maps, and the minimap, with separate control for the Azeroth/global map.

This version was rebuilt from the supplied classic HandyNotes dungeon addon and upgraded to use a new consolidated Forever instance database.

### Features

- English / Ukrainian language switcher (English by default)

- Dungeon and raid entrance markers
- World map, continent map, and minimap support
- Optional **TomTom** right-click waypoints
- Filters for:
  - Dungeons
  - Raids
  - Classic-era instances
  - Forever-new instances
- Separate visibility controls for continent maps and the Azeroth/global map
- Unified tooltip layout for every instance
- Faction-territory tags for dungeons:
  - Alliance — blue
  - Horde — red
  - Contested — gold
- Tooltip sections for status, level/group size, bosses, location, coordinates, descriptions, Forever changes, wings, and notes

### Dungeon territory labels

The current Forever catalog is classified as **5 Alliance-territory**, **7 Horde-territory**, and **16 Contested** dungeons. The tooltip uses the corresponding faction color while keeping portal icons dedicated to instance type/content generation. Territory describes the area around the entrance and does not imply that every dungeon is faction-locked.

### Data logic

The addon follows a strict merge policy:

1. The new Forever database is the main source of truth.
2. Old addon coordinates never overwrite already verified new coordinates.
3. Old coordinates are used only when the same record exists in the new database and the new record has no numeric coordinates.
4. New Forever-only records are preserved as-is.
5. Missing coordinates stay unresolved instead of being guessed.

### Icon logic

- **Raids** use the standard **green** portal.
- **Existing / Classic-era dungeons** use the standard **blue** portal.
- **WoW Forever-new dungeons only** use a dedicated **blue-orange** portal.

This makes new Forever dungeon content easy to distinguish at a glance without changing the normal raid color language.

### Localization

The addon includes an **English / Українська** language switcher. **English is the default and fallback language.**

Settings, tooltip labels, filters, coordinates, player counts, descriptions, Forever-change summaries, TomTom instructions, and database notes use centralized localization keys. Dungeon, raid, and wing names remain canonical and are **not translated**. Zone names use the current client map localization when available.

### Classic + Forever status labels

The addon now tracks where an instance originated and how it appears in Forever without duplicating pins:

- **Forever • New** — brand-new Forever content
- **Classic • Forever** — returning Classic content
- **Classic • Forever • Updated** — returning content with a confirmed Forever change

Classic dungeons are marked Updated because Forever reworks dungeon boss loot across both returning and new dungeons. Molten Core and Onyxia's Lair include their confirmed Forever progression changes.

### Unified descriptions

All **28 dungeons** and **9 raids** include concise English and Ukrainian descriptions. Descriptions are merged into one clean in-game summary per instance rather than being separated by source. Published boss counts are included where available, and the current Barrow Deeps / Hyjal Summit boss rosters are stored from Forever's Legacy raid objectives.

Unnamed future roadmap raids are intentionally not placed on the map until a confirmed name and location are published.

### Client support

This addon is packaged **only for WoW Forever** and ships only with:

`Forever_Instances_Camelot.toc`

It is not intended for Retail or other Classic branches.

### Dependencies

**Required:**
- HandyNotes

**Optional:**
- TomTom

## Release notes for 1.0.2

- Added transparent addon/project icons based on the runestone artwork.
- Added TOC icon metadata.
- Expanded documentation and CurseForge-ready text.
- Added a small map-resolution cache optimization.

## Release notes for 1.0.5

- Fixed incorrect dungeon/raid positions on the Azeroth global map.
- Global markers now use native map-rectangle projection for accurate placement.
- TomTom waypoints from global-map pins continue to target the original zone entrance.


## Release notes for 1.0.6

- Added automated CurseForge releases through GitHub Actions and BigWigs Packager.
- Added pre-release validation for Lua syntax, Forever-only TOC structure, package files, and tag/version consistency.
- Added local release wrapper and dedicated release documentation.

## Release notes for 1.0.9

- Added unified descriptions for every dungeon and raid.
- Added Classic / Forever / Updated provenance labels.
- Added published boss counts and new Forever raid boss rosters.
- Added confirmed Forever changes for Molten Core and Onyxia's Lair.
- Added description visibility setting.


### Optional Atlas integration

If **Atlas** (or a compatible Atlas Forever map package) is installed, Forever Instances can match available Atlas instance maps and lets you **Shift + left-click** a map pin to open the corresponding instance map in Atlas. Atlas is optional and is not bundled with this addon.


### Filters

Filters combine content type and content generation independently: **Dungeons / Raids** and **Classic-era / Forever-new**. Turning off a category immediately refreshes both world-map and minimap pins.
