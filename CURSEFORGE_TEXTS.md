# CurseForge texts

## Project title

HandyNotes: Forever Instances

## Short summary

A WoW Forever-only HandyNotes plugin that marks dungeon and raid entrances on the map and minimap using a merged Forever instance database with safe legacy-coordinate fallback.

## Short description

HandyNotes: Forever Instances adds dungeon and raid entrance markers to your map in **World of Warcraft: Forever**.

It is built specifically for the **Forever client**, uses a consolidated database for both classic-era and Forever-new instances, supports optional **TomTom** waypoints, and keeps clear icon colors for raids, normal dungeons, and Forever-only dungeons.

## Full project description

### Overview

**HandyNotes: Forever Instances** is a **WoW Forever-only** map plugin for **HandyNotes**.
It shows dungeon and raid entrances on zone maps, continent maps, and the minimap, with separate control for the Azeroth/global map.

This version was rebuilt from the supplied classic HandyNotes dungeon addon and upgraded to use a new consolidated Forever instance database.

### Features

- **Ukrainian / English localization** with Auto mode based on the WoW client locale
- Dungeon and raid entrance markers
- World map, continent map, and minimap support
- Optional **TomTom** right-click waypoints
- Filters for:
  - Dungeons
  - Raids
  - Classic-era instances
  - Forever-new instances
- Separate visibility controls for continent maps and the Azeroth/global map
- Tooltip details for:
  - level range
  - player count
  - zone / location
  - coordinates
  - wing breakdowns
  - database notes

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

The addon includes **Auto / Українська / English** language modes. Auto is the default and follows the WoW client locale. A `ukUA` client automatically uses Ukrainian; unsupported locales fall back to English.

Settings, tooltip labels, filters, coordinates, player counts, TomTom instructions, wing labels, and database notes are localized. Zone names use the current client map localization when available.

### Client support

This addon is packaged **only for WoW Forever** and ships only with:

`HandyNotes_ForeverInstances_Camelot.toc`

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
