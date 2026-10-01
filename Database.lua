-- Forever Instances - WoW Forever only
-- Data sources: user-provided WoWForeverInstances.lua + Lootified Instances.lua (2026-09-26)
local addonName, ns = ...

-- WoWForeverInstances.lua
-- Consolidated WoW Forever dungeon / raid database.
--
-- Primary sources:
--   MapUtils 1.2.0 (Camelot) pins.lua supplied with this update — authoritative dungeon world-map pins/UIMapIDs.
--   https://www.warcrafttavern.com/forever/guides/dungeons/
--   https://wowhandbook.com/zones/dungeons/
--   https://www.warcrafttavern.com/forever/guides/raids/
--   https://wowhandbook.com/zones/raids/
--   https://www.wowhead.com/forever/guide/dungeons-overview-locations-details
--   https://mobalytics.gg/wow-forever/guides/wow-forever-dungeons-raids
--   https://wowtbc.gg/warcraftforever/loot-tables/dungeons/
--   https://wowtbc.gg/warcraftforever/news/what-we-know/#new-raids
--
-- Coordinates are zone-map percentages (0..100), NOT normalized 0..1.
-- Use DB.GetNormalizedCoordinates() for C_Map / normalized consumers.
--
-- Data policy:
--   * Content classification is consensus-driven across the current Forever catalogs above.
--     Every top-level record carries an explicit contentType (Dungeon/Raid) and era (Classic/Forever).
--   * Level ranges: current WoW Forever table from Warcraft Tavern; new Forever ranges are cross-checked
--     against current Wowhead, Mobalytics, WoW Handbook, and wowtbc.gg coverage.
--   * One canonical coordinate exists per browser/map entry. The same mapID/x/y is used by
--     the list, HandyNotes world/minimap pin, map navigation, and TomTom.
--   * Lootified Instances.lua contributes current dungeon level ranges, instance IDs,
--     canonical entrance coordinates, and wing splits only; boss/loot data is intentionally not imported.
--   * When the supplied dataset has no verified entrance coordinate, the existing verified
--     MapUtils/Forever coordinate remains the single canonical point.
--   * Multi-wing dungeons keep coordinates only on their wing rows; aggregate parent records
--     are metadata containers and are never rendered as extra map pins.
--   * Unified descriptions: concise paraphrases synthesized from the checked Forever dungeon/raid resources;
--     the UI does not split descriptions by source.
--   * Returning Classic instances are marked as available in Forever without duplicating map nodes.
--   * Unnamed roadmap raids are intentionally not added as map records until a name/location is published.
--   * Dungeon territory is normalized as Alliance / Horde / Contested for tooltip faction context.
--     Territory labels do not create additional coordinate records or map markers.

local DB = {
    version = 9,
    coordinateUnit = "percent",

    Dungeons = {
        Classic = {
            ragefire_chasm = {
                name = "Ragefire Chasm",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 389 },
                levelMin = 13,
                levelMax = 18,
                minEntryLevel = 8,
                zone = "Orgrimmar",
                territory = "Horde",
                mapID = 1454,
                x = 52.8,
                y = 49.6,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",
                descriptionKey = "INSTANCE_RAGEFIRE_CHASM_DESCRIPTION",
                bossCount = 4,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            deadmines = {
                name = "The Deadmines",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 36 },
                aliases = { "Deadmines" },
                levelMin = 17,
                levelMax = 26,
                minEntryLevel = 10,
                zone = "Westfall",
                territory = "Alliance",
                mapID = 1436,
                x = 38.2,
                y = 77.5,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                descriptionKey = "INSTANCE_DEADMINES_DESCRIPTION",
                bossCount = 7,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            wailing_caverns = {
                name = "Wailing Caverns",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 43 },
                levelMin = 17,
                levelMax = 24,
                minEntryLevel = 10,
                zone = "The Barrens",
                territory = "Horde",
                mapID = 1413,
                x = 46.0,
                y = 36.3,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                descriptionKey = "INSTANCE_WAILING_CAVERNS_DESCRIPTION",
                bossCount = 8,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            shadowfang_keep = {
                name = "Shadowfang Keep",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 33 },
                levelMin = 22,
                levelMax = 30,
                minEntryLevel = 10,
                zone = "Silverpine Forest",
                territory = "Horde",
                mapID = 1421,
                x = 44.7,
                y = 67.8,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                descriptionKey = "INSTANCE_SHADOWFANG_KEEP_DESCRIPTION",
                bossCount = 8,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            blackfathom_deeps = {
                name = "Blackfathom Deeps",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 48 },
                aliases = { "BFD" },
                levelMin = 24,
                levelMax = 32,
                minEntryLevel = 10,
                zone = "Ashenvale",
                territory = "Alliance",
                mapID = 1440,
                x = 14.5,
                y = 14.6,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                noteKey = "INSTANCE_BLACKFATHOM_DEEPS_NOTE",
                descriptionKey = "INSTANCE_BLACKFATHOM_DEEPS_DESCRIPTION",
                bossCount = 7,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            the_stockade = {
                name = "The Stockade",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 34 },
                aliases = { "Stockade", "The Stockades" },
                levelMin = 24,
                levelMax = 32,
                minEntryLevel = 15,
                zone = "Stormwind City",
                territory = "Alliance",
                mapID = 1453,
                x = 42.0,
                y = 58.0,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                descriptionKey = "INSTANCE_THE_STOCKADE_DESCRIPTION",
                bossCount = 5,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            gnomeregan = {
                name = "Gnomeregan",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 90 },
                levelMin = 29,
                levelMax = 38,
                minEntryLevel = 15,
                zone = "Dun Morogh",
                territory = "Alliance",
                mapID = 1426,
                x = 17.7,
                y = 39.1,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                noteKey = "INSTANCE_GNOMEREGAN_NOTE",
                descriptionKey = "INSTANCE_GNOMEREGAN_DESCRIPTION",
                bossCount = 5,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            razorfen_kraul = {
                name = "Razorfen Kraul",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 47 },
                aliases = { "RFK" },
                levelMin = 29,
                levelMax = 38,
                minEntryLevel = 15,
                zone = "The Barrens",
                territory = "Horde",
                mapID = 1413,
                x = 42.3,
                y = 89.9,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                descriptionKey = "INSTANCE_RAZORFEN_KRAUL_DESCRIPTION",
                bossCount = 6,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            scarlet_monastery = {
                name = "The Scarlet Monastery",
                contentType = "Dungeon",
                era = "Classic",
                aliases = { "Scarlet Monastery", "SM" },
                levelMin = 30,
                levelMax = 46,
                minEntryLevel = 20,
                zone = "Tirisfal Glades",
                territory = "Horde",
                mapID = 1420,
                players = 5,
                maxPlayers = 10,
                coordStatus = "grouped",

                wings = {
                    graveyard = {
                        name = "Scarlet Monastery: Graveyard",
                        fullName = "Scarlet Monastery: Graveyard",
                        levelMin = 30,
                        levelMax = 38,
                        minEntryLevel = 20,
                        players = 5,
                        maxPlayers = 5,
                        instanceIDs = { 189 },
                        mapID = 1420,
                        zone = "Tirisfal Glades",
                        x = 85.1,
                        y = 31.4,
                        coordStatus = "verified",
                        coordSource = "lootified_instances_2026_09_26",
                    },
                    library = {
                        name = "Scarlet Monastery: Library",
                        fullName = "Scarlet Monastery: Library",
                        levelMin = 33,
                        levelMax = 41,
                        minEntryLevel = 20,
                        players = 5,
                        maxPlayers = 5,
                        instanceIDs = { 189 },
                        mapID = 1420,
                        zone = "Tirisfal Glades",
                        x = 85.1,
                        y = 31.4,
                        coordStatus = "verified",
                        coordSource = "lootified_instances_2026_09_26",
                    },
                    armory = {
                        name = "Scarlet Monastery: Armory",
                        fullName = "Scarlet Monastery: Armory",
                        levelMin = 36,
                        levelMax = 44,
                        minEntryLevel = 20,
                        players = 5,
                        maxPlayers = 5,
                        instanceIDs = { 189 },
                        mapID = 1420,
                        zone = "Tirisfal Glades",
                        x = 85.1,
                        y = 31.4,
                        coordStatus = "verified",
                        coordSource = "lootified_instances_2026_09_26",
                    },
                    cathedral = {
                        name = "Scarlet Monastery: Cathedral",
                        fullName = "Scarlet Monastery: Cathedral",
                        levelMin = 38,
                        levelMax = 46,
                        minEntryLevel = 20,
                        players = 5,
                        maxPlayers = 5,
                        instanceIDs = { 189 },
                        mapID = 1420,
                        zone = "Tirisfal Glades",
                        x = 85.1,
                        y = 31.4,
                        coordStatus = "verified",
                        coordSource = "lootified_instances_2026_09_26",
                    },
                },
                descriptionKey = "INSTANCE_SCARLET_MONASTERY_DESCRIPTION",
                bossCount = 7,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            uldaman = {
                name = "Uldaman",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 70 },
                levelMin = 41,
                levelMax = 51,
                minEntryLevel = 30,
                zone = "Badlands",
                territory = "Contested",
                mapID = 1418,
                x = 44.2,
                y = 12.2,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                descriptionKey = "INSTANCE_ULDAMAN_DESCRIPTION",
                bossCount = 8,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            razorfen_downs = {
                name = "Razorfen Downs",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 129 },
                aliases = { "RFD" },
                levelMin = 37,
                levelMax = 46,
                minEntryLevel = 25,
                zone = "The Barrens",
                territory = "Horde",
                mapID = 1413,
                x = 50.9,
                y = 92.9,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                noteKey = "INSTANCE_RAZORFEN_DOWNS_NOTE",
                descriptionKey = "INSTANCE_RAZORFEN_DOWNS_DESCRIPTION",
                bossCount = 6,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            zulfarrak = {
                name = "Zul'Farrak",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 209 },
                aliases = { "ZF" },
                levelMin = 44,
                levelMax = 54,
                minEntryLevel = 35,
                zone = "Tanaris",
                territory = "Contested",
                mapID = 1446,
                x = 38.7,
                y = 19.9,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                descriptionKey = "INSTANCE_ZULFARRAK_DESCRIPTION",
                bossCount = 8,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            maraudon = {
                name = "Maraudon",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 349 },
                levelMin = 46,
                levelMax = 55,
                minEntryLevel = 30,
                zone = "Desolace",
                territory = "Contested",
                mapID = 1443,
                x = 29.3,
                y = 62.5,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                descriptionKey = "INSTANCE_MARAUDON_DESCRIPTION",
                bossCount = 8,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            temple_of_atal_hakkar = {
                name = "The Temple of Atal'Hakkar",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 109 },
                aliases = { "Temple of Atal'Hakkar", "Sunken Temple", "ST" },
                levelMin = 50,
                levelMax = 60,
                minEntryLevel = 35,
                zone = "Swamp of Sorrows",
                territory = "Contested",
                mapID = 1435,
                x = 77.3,
                y = 35.9,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                noteKey = "INSTANCE_TEMPLE_OF_ATAL_HAKKAR_NOTE",
                descriptionKey = "INSTANCE_TEMPLE_OF_ATAL_HAKKAR_DESCRIPTION",
                bossCount = 8,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            blackrock_depths = {
                name = "Blackrock Depths",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 230 },
                aliases = { "BRD" },
                levelMin = 52,
                levelMax = 60,
                minEntryLevel = 40,
                location = "Blackrock Mountain",
                zone = "Searing Gorge",
                territory = "Contested",
                mapID = 1427,
                x = 27.1,
                y = 72.5,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                descriptionKey = "INSTANCE_BLACKROCK_DEPTHS_DESCRIPTION",
                bossCount = 21,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            blackrock_spire = {
                name = "Blackrock Spire",
                contentType = "Dungeon",
                era = "Classic",
                aliases = { "BRS" },
                levelMin = 55,
                levelMax = 60,
                minEntryLevel = 45,
                location = "Blackrock Mountain",
                zone = "Burning Steppes",
                territory = "Contested",
                players = 5,
                maxPlayers = 10,
                mapID = 1428,
                coordStatus = "grouped",

                wings = {
                    lower = {
                        name = "Lower Blackrock Spire",
                        aliases = { "LBRS" },
                        levelMin = 55,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 10,
                        maxPlayers = 10,
                        instanceIDs = { 229 },
                        mapID = 1428,
                        zone = "Burning Steppes",
                        x = 33.0,
                        y = 25.2,
                        coordStatus = "verified",
                        coordSource = "lootified_instances_2026_09_26",
                    },
                    upper = {
                        name = "Upper Blackrock Spire",
                        aliases = { "UBRS" },
                        levelMin = 59,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 10,
                        maxPlayers = 10,
                        instanceIDs = { 229 },
                        mapID = 1428,
                        zone = "Burning Steppes",
                        x = 33.0,
                        y = 25.2,
                        coordStatus = "verified",
                        coordSource = "lootified_instances_2026_09_26",
                    },
                },
                descriptionKey = "INSTANCE_BLACKROCK_SPIRE_DESCRIPTION",
                bossCount = 14,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            dire_maul = {
                name = "Dire Maul",
                contentType = "Dungeon",
                era = "Classic",
                aliases = { "DM" },
                levelMin = 54,
                levelMax = 60,
                minEntryLevel = 45,
                zone = "Feralas",
                territory = "Contested",
                players = 5,
                maxPlayers = 5,
                mapID = 1444,
                coordStatus = "grouped",

                wings = {
                    east = {
                        name = "Dire Maul: East",
                        aliases = { "DME" },
                        levelMin = 54,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 5,
                        maxPlayers = 5,
                        instanceIDs = { 429 },
                        mapID = 1444,
                        zone = "Feralas",
                        x = 64.8,
                        y = 30.2,
                        coordStatus = "verified",
                        coordSource = "lootified_instances_2026_09_26",
                    },
                    west = {
                        name = "Dire Maul: West",
                        aliases = { "DMW" },
                        levelMin = 56,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 5,
                        maxPlayers = 5,
                        instanceIDs = { 429 },
                        mapID = 1444,
                        zone = "Feralas",
                        x = 60.2,
                        y = 30.4,
                        coordStatus = "verified",
                        coordSource = "lootified_instances_2026_09_26",
                    },
                    north = {
                        name = "Dire Maul: North",
                        aliases = { "DMN" },
                        levelMin = 56,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 5,
                        maxPlayers = 5,
                        instanceIDs = { 429 },
                        mapID = 1444,
                        zone = "Feralas",
                        x = 62.4,
                        y = 24.8,
                        coordStatus = "verified",
                        coordSource = "lootified_instances_2026_09_26",
                    },
                },
                descriptionKey = "INSTANCE_DIRE_MAUL_DESCRIPTION",
                bossCount = 19,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            stratholme = {
                name = "Stratholme",
                contentType = "Dungeon",
                era = "Classic",
                levelMin = 58,
                levelMax = 60,
                minEntryLevel = 45,
                zone = "Eastern Plaguelands",
                territory = "Contested",
                players = 5,
                maxPlayers = 5,
                coordStatus = "grouped",

                wings = {
                    living = {
                        name = "Stratholme: Main Gate",
                        aliases = { "Stratholme: Live", "Strat Live" },
                        levelMin = 58,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 5,
                        maxPlayers = 5,
                        instanceIDs = { 329 },
                        mapID = 1423,
                        zone = "Eastern Plaguelands",
                        x = 26.1,
                        y = 10.4,
                        coordStatus = "verified",
                        coordSource = "lootified_instances_2026_09_26",
                    },
                    undead = {
                        name = "Stratholme: Service Gate",
                        aliases = { "Stratholme: Dead", "Strat UD" },
                        levelMin = 58,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 5,
                        maxPlayers = 5,
                        instanceIDs = { 329 },
                        mapID = 1423,
                        zone = "Eastern Plaguelands",
                        x = 43.0,
                        y = 18.0,
                        coordStatus = "verified",
                        coordSource = "lootified_instances_2026_09_26",
                    },
                },
                descriptionKey = "INSTANCE_STRATHOLME_DESCRIPTION",
                bossCount = 19,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },

            scholomance = {
                name = "Scholomance",
                contentType = "Dungeon",
                era = "Classic",
                instanceIDs = { 289 },
                aliases = { "Scholo" },
                levelMin = 58,
                levelMax = 60,
                minEntryLevel = 45,
                zone = "Western Plaguelands",
                territory = "Contested",
                mapID = 1422,
                x = 69.7,
                y = 73.4,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                descriptionKey = "INSTANCE_SCHOLOMANCE_DESCRIPTION",
                bossCount = 14,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
            },
        },

        Forever = {
            hall_of_thanes = {
                name = "Hall of Thanes",
                contentType = "Dungeon",
                era = "Forever",
                instanceIDs = {  },
                aliases = { "The Hall of Thanes" },
                isForeverNew = true,
                levelMin = 13,
                levelMax = 18,
                minEntryLevel = nil,
                zone = "Ironforge",
                territory = "Alliance",
                parentZone = "Dun Morogh",
                mapID = 1455,
                x = 43.5,
                y = 52.0,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",
                noteKey = "INSTANCE_HALL_OF_THANES_NOTE",
                descriptionKey = "INSTANCE_HALL_OF_THANES_DESCRIPTION",
                bossCount = 4,
                origin = "Forever",
                availableInForever = true,
                foreverStatus = "new",
            },

            ruins_of_lordaeron = {
                name = "Ruins of Lordaeron",
                contentType = "Dungeon",
                era = "Forever",
                instanceIDs = {  },
                isForeverNew = true,
                levelMin = 15,
                levelMax = 20,
                minEntryLevel = nil,
                zone = "Tirisfal Glades",
                territory = "Horde",
                mapID = 1458,
                x = 71.6,
                y = 11.4,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",

                noteKey = "INSTANCE_RUINS_OF_LORDAERON_NOTE",
                descriptionKey = "INSTANCE_RUINS_OF_LORDAERON_DESCRIPTION",
                bossCount = 7,
                origin = "Forever",
                availableInForever = true,
                foreverStatus = "new",
            },

            excavation_site_wetlands = {
                name = "Excavation Site: Wetlands",
                contentType = "Dungeon",
                era = "Forever",
                instanceIDs = {  },
                aliases = { "Excavation Site" },
                isForeverNew = true,
                levelMin = 24,
                levelMax = 29,
                minEntryLevel = nil,
                zone = "Wetlands",
                mapID = 1437,
                territory = "Contested",
                x = 36.8,
                y = 48.2,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "wowgg_dving",
                noteKey = "INSTANCE_EXCAVATION_SITE_WETLANDS_NOTE",
                descriptionKey = "INSTANCE_EXCAVATION_SITE_WETLANDS_DESCRIPTION",
                bossCount = 4,
                origin = "Forever",
                availableInForever = true,
                foreverStatus = "new",
            },

            city_of_dalaran = {
                name = "City of Dalaran",
                contentType = "Dungeon",
                era = "Forever",
                instanceIDs = {  },
                isForeverNew = true,
                levelMin = 28,
                levelMax = 33,
                minEntryLevel = nil,
                zone = "Alterac Mountains",
                mapID = 1416,
                territory = "Contested",
                x = 32.4,
                y = 66.7,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "wowgg_dving",
                noteKey = "INSTANCE_CITY_OF_DALARAN_NOTE",
                descriptionKey = "INSTANCE_CITY_OF_DALARAN_DESCRIPTION",
                bossCount = 9,
                origin = "Forever",
                availableInForever = true,
                foreverStatus = "new",
            },

            drowned_city = {
                name = "The Drowned City",
                contentType = "Dungeon",
                era = "Forever",
                instanceIDs = {  },
                aliases = { "Drowned City" },
                isForeverNew = true,
                levelMin = 35,
                levelMax = 40,
                minEntryLevel = nil,
                zone = "Stranglethorn Vale",
                mapID = 1434,
                territory = "Contested",
                x = 19.8,
                y = 22.4,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "wowgg_dving",
                noteKey = "INSTANCE_DROWNED_CITY_NOTE",
                descriptionKey = "INSTANCE_DROWNED_CITY_DESCRIPTION",
                origin = "Forever",
                availableInForever = true,
                foreverStatus = "new",
            },

            kroldok_stronghold = {
                name = "Krol'Dok Stronghold",
                contentType = "Dungeon",
                era = "Forever",
                instanceIDs = {  },
                aliases = { "Krol’dok Stronghold", "Krol'Dok" },
                isForeverNew = true,
                levelMin = 40,
                levelMax = 45,
                minEntryLevel = nil,
                zone = "The Riverglades",
                territory = "Contested",
                aliasesZones = { "Riverglades" },
                x = 74.2,
                y = 33.5,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "wowgg_dving_wowhead",
                noteKey = "INSTANCE_KROLDOK_STRONGHOLD_NOTE",
                descriptionKey = "INSTANCE_KROLDOK_STRONGHOLD_DESCRIPTION",
                origin = "Forever",
                availableInForever = true,
                foreverStatus = "new",
            },

            alcaz_prison = {
                name = "Alcaz Prison",
                contentType = "Dungeon",
                era = "Forever",
                instanceIDs = {  },
                aliases = { "Alcaz Island Prison" },
                isForeverNew = true,
                levelMin = 48,
                levelMax = 53,
                minEntryLevel = nil,
                zone = "Dustwallow Marsh",
                mapID = 1445,
                territory = "Contested",
                x = 78.4,
                y = 18.2,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "wowgg_dving_wowhead",
                noteKey = "INSTANCE_ALCAZ_PRISON_NOTE",
                descriptionKey = "INSTANCE_ALCAZ_PRISON_DESCRIPTION",
                origin = "Forever",
                availableInForever = true,
                foreverStatus = "new",
            },

            blackmaw_hold = {
                name = "Blackmaw Hold",
                contentType = "Dungeon",
                era = "Forever",
                instanceIDs = {  },
                isForeverNew = true,
                levelMin = 55,
                levelMax = 60,
                minEntryLevel = nil,
                zone = "Azshara",
                mapID = 1447,
                territory = "Contested",
                x = 23.4,
                y = 28.5,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "wowgg_dving_wowhead",
                noteKey = "INSTANCE_BLACKMAW_HOLD_NOTE",
                descriptionKey = "INSTANCE_BLACKMAW_HOLD_DESCRIPTION",
                origin = "Forever",
                availableInForever = true,
                foreverStatus = "new",
            },

            shapers_terrace = {
                name = "Shaper's Terrace",
                contentType = "Dungeon",
                era = "Forever",
                instanceIDs = {  },
                aliases = { "The Shaper's Terrace", "Shaper’s Terrace" },
                isForeverNew = true,
                levelMin = 58,
                levelMax = 60,
                minEntryLevel = nil,
                zone = "Un'Goro Crater",
                mapID = 1449,
                territory = "Contested",
                x = 41.6,
                y = 11.2,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "wowgg_dving",
                noteKey = "INSTANCE_SHAPERS_TERRACE_NOTE",
                descriptionKey = "INSTANCE_SHAPERS_TERRACE_DESCRIPTION",
                origin = "Forever",
                availableInForever = true,
                foreverStatus = "new",
            },
        },
    },

    Raids = {
        Classic = {
            molten_core = {
                name = "Molten Core",
                contentType = "Raid",
                era = "Classic",
                aliases = { "MC" },
                levelMin = 60,
                levelMax = 60,
                zone = "Burning Steppes",
                mapID = 1428,
                location = "Blackrock Mountain",
                x = 26.3,
                y = 24.6,
                players = 40,
                coordStatus = "verified",
                coordSource = "wowhandbook",
                descriptionKey = "INSTANCE_MOLTEN_CORE_DESCRIPTION",
                bossCount = 10,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
                foreverChangeKey = "INSTANCE_MOLTEN_CORE_FOREVER_CHANGE",
            },

            onyxias_lair = {
                name = "Onyxia's Lair",
                contentType = "Raid",
                era = "Classic",
                aliases = { "Onyxia", "Ony" },
                levelMin = 60,
                levelMax = 60,
                zone = "Dustwallow Marsh",
                mapID = 1445,
                x = 52.3,
                y = 76.1,
                players = 40,
                coordStatus = "verified",
                coordSource = "lootified_instances_2026_09_26",
                descriptionKey = "INSTANCE_ONYXIAS_LAIR_DESCRIPTION",
                bossCount = 1,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "updated",
                foreverChangeKey = "INSTANCE_ONYXIAS_LAIR_FOREVER_CHANGE",
                bosses = { "Onyxia" },
            },

            blackwing_lair = {
                name = "Blackwing Lair",
                contentType = "Raid",
                era = "Classic",
                aliases = { "BWL" },
                levelMin = 60,
                levelMax = 60,
                zone = "Burning Steppes",
                mapID = 1428,
                location = "Blackrock Mountain",
                x = 32.5,
                y = 32.4,
                players = 40,
                coordStatus = "verified",
                coordSource = "wowhandbook",
                descriptionKey = "INSTANCE_BLACKWING_LAIR_DESCRIPTION",
                bossCount = 8,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "returning",
            },

            zulgurub = {
                name = "Zul'Gurub",
                contentType = "Raid",
                era = "Classic",
                aliases = { "ZG" },
                levelMin = 60,
                levelMax = 60,
                zone = "Stranglethorn Vale",
                mapID = 1434,
                x = 54.0,
                y = 17.6,
                players = 20,
                coordStatus = "verified",
                coordSource = "wowhandbook",
                descriptionKey = "INSTANCE_ZULGURUB_DESCRIPTION",
                bossCount = 10,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "returning",
            },

            ruins_of_ahnqiraj = {
                name = "Ruins of Ahn'Qiraj",
                contentType = "Raid",
                era = "Classic",
                aliases = { "AQ20" },
                levelMin = 60,
                levelMax = 60,
                zone = "Silithus",
                mapID = 1451,
                x = 29.0,
                y = 92.8,
                players = 20,
                coordStatus = "verified",
                coordSource = "wowhandbook",
                descriptionKey = "INSTANCE_RUINS_OF_AHNQIRAJ_DESCRIPTION",
                bossCount = 6,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "returning",
            },

            temple_of_ahnqiraj = {
                name = "Temple of Ahn'Qiraj",
                contentType = "Raid",
                era = "Classic",
                aliases = { "AQ40" },
                levelMin = 60,
                levelMax = 60,
                zone = "Silithus",
                mapID = 1451,
                x = 29.0,
                y = 92.7,
                players = 40,
                coordStatus = "verified",
                coordSource = "wowhandbook",
                descriptionKey = "INSTANCE_TEMPLE_OF_AHNQIRAJ_DESCRIPTION",
                bossCount = 9,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "returning",
            },

            naxxramas = {
                name = "Naxxramas",
                contentType = "Raid",
                era = "Classic",
                aliases = { "Naxx" },
                levelMin = 60,
                levelMax = 60,
                zone = "Eastern Plaguelands",
                mapID = 1423,
                x = 39.0,
                y = 26.0,
                players = 40,
                coordStatus = "cross_checked",
                coordSource = "wowhead_classic",
                noteKey = "INSTANCE_NAXXRAMAS_NOTE",
                descriptionKey = "INSTANCE_NAXXRAMAS_DESCRIPTION",
                bossCount = 15,
                origin = "Classic",
                availableInForever = true,
                foreverStatus = "returning",
            },
        },

        Forever = {
            barrow_deeps = {
                name = "Barrow Deeps",
                contentType = "Raid",
                era = "Forever",
                aliases = { "The Barrow Deeps" },
                isForeverNew = true,
                levelMin = 60,
                levelMax = 60,
                zone = "Mount Hyjal",
                x = nil,
                y = nil,
                players = 10,
                coordStatus = "tba",
                noteKey = "INSTANCE_BARROW_DEEPS_NOTE",
                descriptionKey = "INSTANCE_BARROW_DEEPS_DESCRIPTION",
                bossCount = 8,
                origin = "Forever",
                availableInForever = true,
                foreverStatus = "new",
                bosses = { "Deepscar Matriarch", "Elder Tangleclaw", "Khalith the Dreadspinner", "Well of Sorrow", "Amethrax", "Del'lynar Songwood", "Ravus and Darlyssa", "Sonya Darkhallow" },
            },

            hyjal_summit = {
                name = "Hyjal Summit",
                contentType = "Raid",
                era = "Forever",
                isForeverNew = true,
                levelMin = 60,
                levelMax = 60,
                zone = "Mount Hyjal",
                x = nil,
                y = nil,
                players = 20,
                coordStatus = "tba",
                noteKey = "INSTANCE_HYJAL_SUMMIT_NOTE",
                descriptionKey = "INSTANCE_HYJAL_SUMMIT_DESCRIPTION",
                bossCount = 13,
                origin = "Forever",
                availableInForever = true,
                foreverStatus = "new",
                bosses = { "Bandalar", "Ancient of Decay", "Time-lost Battalion", "Sylvestris Dusksong", "Old Gloomlurker", "Gharalis the Abyssal", "Kathris the Haunted", "Anara Chillwind", "Elder Minderel", "Tracker Stillwind", "Council of Thorns", "Nythus the Dreambound", "The Wild King" },
            },
        },
    },
}

-- Map IDs are part of the same canonical location contract. Most records store
-- the verified UIMapID directly. A Forever-only zone whose UIMapID is not
-- published in the supplied data (currently The Riverglades) is resolved by
-- name from the live C_Map tree and cached onto that same canonical record.
-- No alternate x/y coordinate is introduced by this resolver.
local liveMapNameIndex

local function normalizeMapName(value)
    if type(value) ~= "string" then return "" end
    value = value:lower():gsub("[’`´]", "'")
    value = value:gsub("^the%s+", "")
    return value:gsub("[%p%s]+", "")
end

local function buildLiveMapNameIndex()
    local index = {}
    local function add(info)
        if type(info) ~= "table" or type(info.mapID) ~= "number" or type(info.name) ~= "string" then return end
        local key = normalizeMapName(info.name)
        if key == "" then return end
        local bucket = index[key]
        if not bucket then bucket = {}; index[key] = bucket end
        for _, existing in ipairs(bucket) do if existing.mapID == info.mapID then return end end
        bucket[#bucket + 1] = info
    end
    if C_Map and type(C_Map.GetMapInfo) == "function" and type(C_Map.GetMapChildrenInfo) == "function" then
        for _, rootID in ipairs({ 947, 946 }) do
            local okRoot, rootInfo = pcall(C_Map.GetMapInfo, rootID)
            if okRoot then add(rootInfo) end
            local ok, children = pcall(C_Map.GetMapChildrenInfo, rootID, nil, true)
            if ok and type(children) == "table" then for _, info in ipairs(children) do add(info) end end
        end
    end
    if C_Map and type(C_Map.GetBestMapForUnit) == "function" and type(C_Map.GetMapInfo) == "function" then
        local ok, current = pcall(C_Map.GetBestMapForUnit, "player")
        local seen = {}
        while ok and current and current ~= 0 and not seen[current] do
            seen[current] = true
            local okInfo, info = pcall(C_Map.GetMapInfo, current)
            if not okInfo or type(info) ~= "table" then break end
            add(info)
            current = info.parentMapID
        end
    end
    liveMapNameIndex = index
end

local function resolveCanonicalMapID(instance)
    if not instance then return nil end
    if type(instance.mapID) == "number" then return instance.mapID end
    if not liveMapNameIndex then buildLiveMapNameIndex() end
    local names = { instance.zone }
    for _, alias in ipairs(instance.aliasesZones or {}) do names[#names + 1] = alias end
    for _, name in ipairs(names) do
        local bucket = liveMapNameIndex and liveMapNameIndex[normalizeMapName(name)]
        if bucket and bucket[1] then
            instance.mapID = bucket[1].mapID
            instance.coordMapIDSource = "live_c_map_name_resolution"
            return instance.mapID
        end
    end
end

-- Canonical location contract. Every rendered browser entry has at most one
-- mapID/x/y point; every consumer reads this exact record.
function DB.GetCanonicalLocation(instance)
    if not instance or instance.coordStatus == "tba" or instance.coordStatus == "grouped" then
        return nil
    end
    if type(instance.x) ~= "number" or type(instance.y) ~= "number"
        or instance.x <= 0 or instance.x > 100 or instance.y <= 0 or instance.y > 100 then
        return nil
    end
    local mapID = resolveCanonicalMapID(instance)
    if type(mapID) ~= "number" then return nil end
    return mapID, instance.x, instance.y, instance.zone
end

-- Convert canonical percentage coordinates (e.g. 53.0, 48.9) to normalized 0..1.
function DB.GetNormalizedCoordinates(instance)
    local _, x, y = DB.GetCanonicalLocation(instance)
    if not x or not y then return nil, nil end
    return x / 100, y / 100
end

-- Inclusive level-range helper.
function DB.IsInLevelRange(instance, level)
    if not instance or type(level) ~= "number" then
        return false
    end

    return level >= instance.levelMin and level <= instance.levelMax
end

-- Returns Classic + Forever dungeon records without mutating the source tables.
function DB.GetAllDungeons()
    local result = {}

    for id, data in pairs(DB.Dungeons.Classic) do
        result[id] = data
    end

    for id, data in pairs(DB.Dungeons.Forever) do
        result[id] = data
    end

    return result
end

-- Returns Classic + Forever raid records without mutating the source tables.
function DB.GetAllRaids()
    local result = {}

    for id, data in pairs(DB.Raids.Classic) do
        result[id] = data
    end

    for id, data in pairs(DB.Raids.Forever) do
        result[id] = data
    end

    return result
end

-- Shared browser metadata. The browser intentionally does not maintain a
-- second coordinate database: it reads mapID/x/y directly from the canonical
-- dungeon/raid records above and only keeps continent grouping metadata here.
DB.InstanceContinents = { "Eastern Kingdoms", "Kalimdor" }
DB.ZoneContinents = {
    ["Alterac Mountains"] = "Eastern Kingdoms",
    ["Badlands"] = "Eastern Kingdoms",
    ["Burning Steppes"] = "Eastern Kingdoms",
    ["Dun Morogh"] = "Eastern Kingdoms",
    ["Eastern Plaguelands"] = "Eastern Kingdoms",
    ["Ironforge"] = "Eastern Kingdoms",
    ["Searing Gorge"] = "Eastern Kingdoms",
    ["Silverpine Forest"] = "Eastern Kingdoms",
    ["Stormwind City"] = "Eastern Kingdoms",
    ["Stranglethorn Vale"] = "Eastern Kingdoms",
    ["Swamp of Sorrows"] = "Eastern Kingdoms",
    ["The Riverglades"] = "Eastern Kingdoms",
    ["Riverglades"] = "Eastern Kingdoms",
    ["Tirisfal Glades"] = "Eastern Kingdoms",
    ["Westfall"] = "Eastern Kingdoms",
    ["Western Plaguelands"] = "Eastern Kingdoms",
    ["Wetlands"] = "Eastern Kingdoms",

    ["Ashenvale"] = "Kalimdor",
    ["Azshara"] = "Kalimdor",
    ["Desolace"] = "Kalimdor",
    ["Dustwallow Marsh"] = "Kalimdor",
    ["Feralas"] = "Kalimdor",
    ["Mount Hyjal"] = "Kalimdor",
    ["Orgrimmar"] = "Kalimdor",
    ["Silithus"] = "Kalimdor",
    ["Tanaris"] = "Kalimdor",
    ["The Barrens"] = "Kalimdor",
    ["Un'Goro Crater"] = "Kalimdor",
}

function DB.GetInstanceContinent(instance)
    if not instance then return nil end
    if instance.continent then return instance.continent end
    return DB.ZoneContinents[instance.zone] or DB.ZoneContinents[instance.parentZone]
end

-- Browser/navigation consumers get references to the canonical records so any
-- future coordinate correction automatically appears in both HandyNotes pins
-- and the side-panel list without synchronizing duplicate tables.
local function prepareWingRecord(parent, parentID, wingID, wing)
    -- A wing is itself the canonical record. Populate inherited metadata on
    -- that same table; never manufacture a second object containing copied
    -- mapID/x/y values.
    wing.name = wing.fullName or wing.name or parent.name
    wing.aliases = wing.aliases or parent.aliases
    wing.contentType = parent.contentType
    wing.era = parent.era
    wing.levelMin = wing.levelMin or parent.levelMin
    wing.levelMax = wing.levelMax or parent.levelMax
    wing.minEntryLevel = wing.minEntryLevel or parent.minEntryLevel
    wing.zone = wing.zone or parent.zone
    wing.parentZone = wing.parentZone or parent.parentZone
    wing.location = wing.location or parent.location
    wing.territory = wing.territory or parent.territory
    wing.players = wing.players or parent.players
    wing.maxPlayers = wing.maxPlayers or parent.maxPlayers
    wing.instanceIDs = wing.instanceIDs or parent.instanceIDs
    wing.coordStatus = wing.coordStatus or parent.coordStatus
    wing.coordSource = wing.coordSource or parent.coordSource
    wing.origin = parent.origin
    wing.availableInForever = parent.availableInForever
    wing.foreverStatus = parent.foreverStatus
    wing.isForeverNew = parent.isForeverNew
    wing.descriptionKey = wing.descriptionKey or parent.descriptionKey
    wing.noteKey = wing.noteKey or parent.noteKey
    wing.parentInstance = parent
    wing.parentID = parentID
    wing.wingID = wingID
    wing.isWing = true
    return wing
end

-- Browser/navigation consumers are derived directly from the canonical records.
-- Dungeon records with explicit wings are expanded into one row per wing instead
-- of showing a misleading aggregate row. No second coordinate database exists.
function DB.GetBrowserEntries()
    local result = {}

    local function append(sectionName, era)
        local bucket = DB[sectionName] and DB[sectionName][era]
        for id, instance in pairs(bucket or {}) do
            if sectionName == "Dungeons" and type(instance.wings) == "table" and next(instance.wings) then
                for wingID, wing in pairs(instance.wings) do
                    result[#result + 1] = {
                        id = id .. ":" .. tostring(wingID),
                        parentID = id,
                        wingID = wingID,
                        section = sectionName,
                        era = era,
                        instance = prepareWingRecord(instance, id, wingID, wing),
                    }
                end
            else
                result[#result + 1] = {
                    id = id,
                    section = sectionName,
                    era = era,
                    instance = instance,
                }
            end
        end
    end

    append("Dungeons", "Classic")
    append("Dungeons", "Forever")
    append("Raids", "Classic")
    append("Raids", "Forever")
    return result
end

ns.DB = DB
