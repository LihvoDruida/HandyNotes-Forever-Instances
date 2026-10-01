# Changelog

## [1.0.29] - 2026-10-01

### 🐛 Bug Fixes
- Fix simultaneous selected state between Forever Instances and an external fallback Quests tab.
- Recognize fallback Quests tabs from Blizzard's active/inactive quest-tab atlas metadata instead of comparing only the currently displayed icon, which changes with tab state on Forever.
- While the dungeon browser is selected, suppress only positively identified fallback-Quests selected glow/icon tint; arbitrary third-party custom tabs remain untouched.
- Restore fallback-Quests visuals from the actual Blizzard `QuestMapFrame.displayMode`, preventing stale yellow tabs and preserving one-active-tab behavior.
- Fix one-click return to Quests from Forever Instances: a fallback Quests tab is now correctly classified, so the native Blizzard display mode is restored instead of leaving a blank gray sidebar.
- Fix a diagnostic Lua multi-return bug that reported valid Deadmines coordinates as `0.0,0.0`; the canonical database record itself was already correct.

### 🧪 Diagnostics
- `/fitest` now validates the corrected canonical coordinate read and fallback-Quests visual arbitration.

## [1.0.28] - 2026-10-01

### 🐛 Bug Fixes
- Fix the blank gray World Map sidebar that could appear when switching from Forever Instances to another custom map tab.
- Remove the pre-click (`OnMouseDown`) foreign-tab handoff. External custom tabs now receive the click first and Forever Instances releases its panel only from a post-`OnMouseUp` hook, matching the working reference addon's tab-switch lifecycle.
- Stop directly owning or restoring another addon's icon/glow state. Foreign tabs keep responsibility for their own selected visuals.
- Before opening Forever Instances from another detached custom tab, briefly hand control back through the last valid Blizzard QuestMapFrame display mode. Cooperative detached tabs observe that normal mode change and close themselves through their own hooks before Forever Instances selects its panel.
- Keep native Blizzard tabs entirely out of the generic foreign-tab hook path; native Quests / Events / Map Legend switches are handled only by `QuestMapFrame:SetDisplayMode`.
- Preserve taint-safe integration: no `TabButtons` / `ContentFrames` mutation and no addon MapCanvas pin.

### 🧪 Diagnostics
- Report the external handoff phase as `post-mouseup` and validate only non-native custom/fallback side-tab hooks.
- Keep custom-tab exclusivity diagnostics without mutating foreign tab visuals.

## [1.0.27] - 2026-10-01

### 🐛 Bug Fixes
- Make Forever Instances mutually exclusive with other Blizzard-style custom World Map side tabs, not only fallback Quests tabs.
- When the dungeon browser is selected, suppress the selected glow and active icon tint of every other custom `QuestLog-tab-side` sibling so two addon tabs cannot remain yellow at the same time.
- Use a two-phase generic handoff (`OnMouseDown` + `OnMouseUp`) for external custom tabs so switching away from Forever Instances remains reliable even when another addon consumes or replaces one of those mouse phases.
- Restore Blizzard mode only for passive/fallback tabs with no `displayMode`; managed custom tabs receive control directly so the native quest panel is not painted over their content.
- Keep all compatibility generic: no EasyFind/global frame names or other addon-specific runtime dependencies are introduced.

### 🧪 Diagnostics
- Add `/fitest` coverage for custom side-tab visual exclusivity and expose managed custom tab counts plus any external selected glows while Forever Instances is active.

## [1.0.26] - 2026-10-01

### 🐛 Bug Fixes
- Fix the World Map tab handoff where Forever Instances and an external fallback Quests tab could both remain visually selected at the same time.
- Hook every visible Blizzard-style direct side tab on mouse-down and restore the last native QuestMapFrame display mode before the destination tab handles its own click. This prevents a fallback Quests tab from becoming a no-op while Forever Instances is active.
- Detect fallback side tabs generically from Blizzard `QuestLog-tab-side` chrome; no addon names or foreign frame names are hard-coded.
- Temporarily suppress the selected glow of passive fallback tabs while Forever Instances is active and restore their original glow state when leaving the browser.
- Reuse an already-present fallback side tab as the stack anchor instead of creating a duplicate Quests return tab.
- Keep the detached/taint-safe architecture: no writes to Blizzard `TabButtons` / `ContentFrames` and no MapCanvas pin ownership.

### 🧪 Diagnostics
- Expose total Blizzard-style side tabs, passive fallback tabs, and installed handoff hooks in `/fitest` debug state.

## [1.0.25] - 2026-10-01

### 🐛 Bug Fixes
- Restore Blizzard ownership of the World Map open lifecycle: closing the map while Forever Instances is selected no longer makes the addon tab reopen automatically next time.
- Remove the immediate, next-frame, and delayed browser reactivation passes that overrode the game's intended quest/event/legend mode on map open.
- When the map closes or is maximized, restore the native display mode only to clean up the temporary `SetDisplayMode(nil)` state, then clear the addon selection.
- Keep Forever Instances user-driven: the browser opens only after an explicit click on its side tab (or an explicit addon action), never because the World Map was reopened.
- Preserve native Blizzard map behavior on subsequent opens while keeping the detached/taint-safe browser architecture.

### 🧪 Diagnostics
- Replace the old sticky-browser reopen assertion with `Blizzard default map reopen lifecycle`, which verifies that the browser is closed, its tab is unselected, a native display mode is restored, and native map content is visible after reopening.

## [1.0.24] - 2026-10-01

### 🐛 Bug Fixes
- Fix the World Map close/reopen regression where the Forever Instances browser restored while Blizzard's quest list was also visible underneath it.
- Match the supplied working map-tab lifecycle more closely: restore the selected addon surface immediately on `WorldMapFrame:OnShow`, repeat once on the next frame, and perform one bounded late exclusivity pass for Forever's delayed quest-panel restoration.
- When the browser is selected, explicitly keep Blizzard `QuestsFrame`, `EventsFrame`, and `MapLegend` content hidden after display-mode changes so only one sidebar surface can be visible.
- Synchronize with `LibWorldMapTabs` through its public `SetDisplayMode(nil)` API when the library is present, without depending on any named addon or foreign frame.
- Hook the shared tab manager's display-mode changes so selecting another managed map tab cleanly closes the Forever Instances browser.
- Preserve the detached/taint-safe architecture: no writes to Blizzard `TabButtons` / `ContentFrames`, no addon-owned MapCanvas pin, and no direct `WorldMapFrame:SetMapID()`.

### 🧪 Diagnostics
- Extend `/fitest` with a real `WorldMapFrame` hide/show cycle that reproduces the reported bug and verifies that the browser restores with Blizzard quest/event/legend content fully hidden.
- Expose native sidebar visibility and shared-tab-manager presence in the diagnostic state.

## [1.0.23] - 2026-10-01

- Replaced the v1.0.22 `LargeSideTabButtonTemplate` experiment with the same proven frame construction used by the supplied map-search reference: a plain `QuestMapFrame` sibling with Blizzard `QuestLog-tab-side`, selected-glow, hover-glow, and stock 42/55-style geometry.
- Keep the Forever Instances tab out of the foreign `displayMode` chain on purpose. This prevents two independently managed addons from anchoring to each other and creating circular anchors or large vertical jumps.
- Discover only visible direct `QuestMapFrame` children that already participate in the established `displayMode` tab chain, then place Forever Instances after the lowest settled tab with the stock `-3 px` gap.
- Restore the working fallback Quests side-tab for Forever clients where Blizzard keeps its own quest side tabs hidden.
- Rebuild the browser panel using the proven quest-log layout: `ContentsAnchor`, 29 px search strip, 22 px right inset, `QuestLog-main-background`, `QuestLogBorderFrameTemplate`, a plain scroll frame, and `MinimalScrollBar`.
- Use Blizzard's `Dungeon`/`Raid` atlases for browser glyphs with local textures only as fallback.
- Remove hard-coded integration with named third-party addons; foreign tab switching is detected through the common direct-child/display-mode behavior only.
- Preserve the detached/taint-safe panel, no `TabButtons`/`ContentFrames` mutation, and the single canonical `Database.lua -> mapID/x/y` coordinate source.
- Update `/fitest` to verify the quest-style panel geometry, manual scrollbar, no own `displayMode`, stable foreign-tab chain, and zero side-tab collisions.

## [1.0.22] - 2026-10-01

- Rebuilt the world-map side tab around Blizzard's own `LargeSideTabButtonTemplate` and `SidePanelTabButtonMixin` behavior instead of custom tab artwork or recursive geometry heuristics.
- The browser tab now uses Blizzard's built-in `Dungeon` atlas for both active and inactive states and the template's native checked/selected/hover/press handling.
- Replaced recursive map-tree scanning with a strict direct-sibling tab chain: only side-tab-sized frames directly parented to `QuestMapFrame` can participate in placement.
- Anchor the Forever Instances tab exactly like Blizzard chains `EventsTab` and `MapLegendTab`: `TOP` to the previous tab's `BOTTOM` with the stock `-3 px` gap.
- Removed the continuous 0.30 s layout watcher and collision-retry drift that could attach the tab to unrelated map controls and push it into the map border.
- Keep compatibility with other properly implemented map tabs by detecting only direct QuestMapFrame side-tab siblings and re-evaluating the chain on map show, sibling show/hide, and addon load.
- Switch browser dungeon/raid row glyphs to Blizzard's native `Dungeon` / `Raid` atlases with local textures retained only as a compatibility fallback.
- Preserve the taint-safe detached content panel and the single canonical `Database.lua -> mapID/x/y` location source.

## [1.0.21] - 2026-10-01

- Fixed side-tab stacking races that could visually merge the Forever Instances icon with another quest/map tab.
- The addon tab now stays hidden until a deferred layout pass resolves the current map-tab stack.
- Side-tab discovery now scans native tab arrays read-only plus nested map-frame children by geometry and Blizzard side-tab chrome, without addon-name dependencies.
- Added immediate child-count change detection so tabs created later by other addons trigger a safe reflow.
- Added collision retry/verification and richer `/fitest` tab-layout diagnostics.
- Kept the browser detached from Blizzard `TabButtons` / `ContentFrames` and preserved the single canonical coordinate source.

## [1.0.20] - 2026-10-01

### 🛠️ UI / UX
- Replace the reference-specific world-map integration with an independently implemented browser architecture that has no hard-coded dependency on EasyFind, ForeverDungeonMaps, or any other addon.
- Build the side tab from Blizzard's `LargeSideTabButtonTemplate`, keep the addon icon/content unique, and use the stock `SearchBoxTemplate`, `ScrollFrameTemplate`, `QuestLogBorderFrameTemplate`, and `QuestLog-main-background` for the surrounding UI.
- Detect visible side tabs generically by live frame geometry, place the Forever Instances tab below the current lowest tab, and reflow while the World Map is open or when later addons load/show/hide tabs.
- Add a collision guard so the addon tab does not occupy the same screen rectangle as another World Map side tab.
- Align the browser panel directly to Blizzard's live `QuestMapFrame.QuestsFrame` instead of copying another addon's panel geometry.
- Keep the browser detached from Blizzard `TabButtons` / `ContentFrames` so the protected-action taint fix remains intact.

### 🧱 Data / Coordinates
- Preserve the single canonical `Database.lua -> mapID/x/y` coordinate contract. HandyNotes, the browser, map opening, and TomTom continue to read the same instance/wing record with no additional coordinate store.

### 🧪 Diagnostics
- Extend `/fitest` with checks for Blizzard-native tab/scroll templates and zero side-tab rectangle collisions.
- Update the architecture gate to reject hard-coded third-party tab integration in runtime code.

## [1.0.19] - 2026-09-30

### 🛠️ UI / UX
- Rebuild the World Map instance browser around the supplied EasyFind `MapTab` layout and switching model: detached side tab, sibling `ContentsAnchor` panel, 29 px search strip, 22 px right inset, quest-log paper/border, `MinimalScrollBar`, and matching tab selection/restore behavior.
- Keep Forever Instances' own two-line instance rows and search content while using the same surrounding panel geometry and scroll mechanics as EasyFind.
- Keep the browser out of Blizzard `TabButtons` / `ContentFrames` and continue using nil `QuestMapFrame:SetDisplayMode()` selection so the v1.0.17 taint fix remains intact.

### 🧱 Data / Coordinates
- Promote `mapID/x/y` to the single canonical location contract for every browser/map entry.
- Remove `LegacyFallback.lua`, `entrance`, `alternateEntrances`, `mapPoints`, and the obsolete `entrance_flag.tga` marker path.
- Build HandyNotes pins from the same wing-expanded `GetBrowserEntries()` records used by the sidebar, so list navigation, map pins, and TomTom resolve to the exact same stored point.
- Keep grouped parents for Scarlet Monastery, Dire Maul, Blackrock Spire, and Stratholme metadata-only; their wing rows own the actual coordinates.
- Bump the database schema to 9.

### 🧪 Diagnostics
- Extend `/fitest` with a single-coordinate-source invariant and EasyFind-style panel/scroll geometry checks.
- Update side-tab simulation for the frame-based `OnMouseUp` behavior used by EasyFind rather than `Button:Click()`.

## [1.0.18] - 2026-09-30

### 🐛 Bug Fixes
- Fix the three failures reported by the in-game `/fitest` pass on Forever build 70124: zero-sized scroll geometry in diagnostics, search rendering not following programmatic/live edit-box text, and the no-match search case.
- Anchor the detached browser to Blizzard's actual `QuestsFrame` rectangle so the overlay, search strip, border, and list viewport match the stock quest-log panel instead of approximating `ContentsAnchor` geometry.
- Preserve Blizzard `ScrollFrameTemplate` / `ScrollUtil` mouse-wheel behavior when the client provides it; use a small 30px fallback only on clients without a native wheel handler.
- Move the browser search box outside the scroll viewport, fully mask the underlying Blizzard quest content, and keep search state synchronized directly from the visible edit box.
- During active search, expand matching sections automatically, hide empty continent headers, and show the stock no-results message when nothing matches.

### 🧪 Diagnostics
- Make `/fitest` force a render refresh after changing search text and validate the browser scroll viewport against the live `QuestMapFrame.QuestsFrame` dimensions and scrollbar presence.

## [1.0.17] - 2026-09-30

### 🐛 Bug Fixes
- Remove browser writes to Blizzard `QuestMapFrame.TabButtons`, `ContentFrames`, and custom display-mode state after an in-game `ADDON_ACTION_BLOCKED` taint report involving protected `Button:SetPassThroughButtons()`.
- Remove the addon-owned World Map canvas marker; opening an instance now relies on the addon's existing HandyNotes pin and the public `C_Map.OpenWorldMap()` API, avoiding direct `WorldMapFrame:SetMapID()` execution in addon taint context.
- Rebuild the browser panel geometry around Blizzard's `QuestScrollFrame` layout: `ContentsAnchor` width, `ScrollFrameTemplate`, quest-style scrollbar offsets, mouse-wheel stepping/clamping, and correctly separated search/header/content regions.
- Prevent the browser frame and scrollbar from overlapping the world-map side tabs and top border.

### 🧱 Data
- Synchronize dungeon level ranges, instance IDs, and entrance coordinates from the supplied `Instances.lua` dataset without importing boss or loot tables.
- Preserve earlier verified access points as `alternateEntrances` instead of discarding them when the supplied entrance differs.
- Expand Scarlet Monastery, Dire Maul, Blackrock Spire, and Stratholme into explicit browser wing rows with their own levels, group sizes, and coordinates.
- Keep the canonical database at 37 top-level instances while the browser now renders 44 rows: 35 dungeon/wing rows plus 9 raids.

### 🧪 Diagnostics
- Update `/fitest` to verify that Blizzard tab/content arrays remain untouched and that no addon-owned MapCanvas marker exists.
- Avoid simulated Blizzard-tab clicks in diagnostics so the diagnostic itself cannot be the source of protected-action taint.

## [1.0.16] - 2026-09-30

### 🧪 Diagnostics
- Add `/fitest` (`/foreverinstancetest`) for an explicit live in-game regression/smoke pass.
- Validate the canonical 37-instance database, normalized coordinates, continent split, dependencies, SavedVariables schema, localization parity, live `C_Map` resolution, native map-tab registration, tab switching, complete list rendering, and search behavior.
- Capture test-time Lua errors plus available `UI_ERROR_MESSAGE`, `ADDON_ACTION_BLOCKED`, `ADDON_ACTION_FORBIDDEN`, and `LUA_WARNING` events without suppressing the normal game error handler.
- Open a movable copyable report window after the run with PASS / FAIL / WARN / SKIP results, elapsed time, memory delta, captured errors, and captured client events.
- Add `/fitest show` to reopen the latest session report.
- Restore map-browser display mode, search text, and continent collapse state after the simulation.

## [1.0.15] - 2026-09-30

### 🚀 New Features
- Add a full world-map **Dungeons & Raids** browser based on the ForeverDungeonMaps list UI.
- Read every row, level range, zone, map ID, and navigation coordinate from the canonical `Database.lua` records instead of maintaining a second location database.
- Add search, continent groups, collapse/expand headers, active-row highlighting, map navigation, temporary map ping, and TomTom integration.

### 🛠️ UI / UX
- Register the new side tab through Blizzard's native `QuestMapFrame.TabButtons` / `ContentFrames` display-mode system when available, so clicking it and the built-in Quests / Events / Map Legend tabs switches content exactly through `QuestMapFrame:SetDisplayMode()`.
- Match the stock quest-log side-tab artwork, checked glow, hover glow, panel background, headers, list spacing, and scrollbar behavior.
- Keep compatibility fallbacks for Forever builds where the native tab arrays are unavailable.

### 🧱 Data
- Add shared continent metadata and a canonical browser-entry helper to `Database.lua`; no dungeon or raid coordinates are duplicated in the UI module.

## [1.0.14] - 2026-09-27

### 🗺️ Map Data
- Replace primary coordinates for every dungeon covered by the supplied **MapUtils 1.2.0 Camelot** database with its exact world-map pins and UIMapIDs.
- Preserve MapUtils multi-point records instead of collapsing them: Hall of the Thanes path, Ruins of Lordaeron Undercity point, both Blackrock Mountain sides, and all three Dire Maul wing points.
- Keep Stratholme and Forever-only dungeons absent from MapUtils unchanged rather than inventing source data.

### 🛠️ Refactor
- Add explicit `mapID` support and `mapPoints` rendering for source-authored multi-point dungeon locations.
- Prefer a verified explicit UIMapID when present, with the existing map-name resolver retained as fallback.

## [1.0.12] - 2026-09-23

### 🚀 New Features
- Add a mandatory `entrance = { x, y }` block to every dungeon and raid record.
- Add dedicated green-flag rendering for verified entrance/access points that differ from the primary instance marker.
- Add a newly verified Hall of Thanes portal at `43.5, 52.0`.

### 🐛 Bug Fixes
- Suppress entrance flags when coordinates are unknown (`0,0`) or duplicate the main instance point.
- Remove the unverified Razorfen Downs approach marker.
- Keep separate verified access points for Blackfathom Deeps, Gnomeregan, Uldaman, Maraudon, Temple of Atal'Hakkar, Stratholme, and Hall of Thanes.
- Keep Barrow Deeps and Hyjal Summit unresolved instead of inventing coordinates.

### 🛠️ Refactor
- Separate primary instance coordinates from optional entrance/access coordinates throughout the data and rendering layers.
- Rename the approach marker asset and runtime model to entrance markers.
- Expand release validation for the 37-record entrance contract.

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

