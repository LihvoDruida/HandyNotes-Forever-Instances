-- HandyNotes_ForeverInstances - WoW Forever only
-- Data source: user-provided WoWForeverInstances.lua
local addonName, ns = ...

-- WoWForeverInstances.lua
-- Consolidated WoW Forever dungeon / raid database.
--
-- Primary sources:
--   https://www.warcrafttavern.com/forever/guides/dungeons/
--   https://wowhandbook.com/zones/dungeons/
--   https://www.warcrafttavern.com/forever/guides/raids/
--   https://wowhandbook.com/zones/raids/
--
-- Coordinates are zone-map percentages (0..100), NOT normalized 0..1.
-- Use DB.GetNormalizedCoordinates() for C_Map / normalized consumers.
--
-- Data policy:
--   * Level ranges: current WoW Forever table from Warcraft Tavern.
--   * Classic entrance coords: WoW Handbook where consistent.
--   * Conflicting coordinates were cross-checked instead of copied blindly.
--   * Unknown/TBA Forever entrance coordinates remain nil.

local DB = {
    version = 1,
    coordinateUnit = "percent",

    Dungeons = {
        Classic = {
            ragefire_chasm = {
                name = "Ragefire Chasm",
                levelMin = 13,
                levelMax = 18,
                minEntryLevel = 8,
                zone = "Orgrimmar",
                x = 53.0,
                y = 48.9,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            deadmines = {
                name = "The Deadmines",
                aliases = { "Deadmines" },
                levelMin = 15,
                levelMax = 22,
                minEntryLevel = 10,
                zone = "Westfall",
                x = 38.2,
                y = 77.5,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            wailing_caverns = {
                name = "Wailing Caverns",
                levelMin = 17,
                levelMax = 24,
                minEntryLevel = 10,
                zone = "The Barrens",
                x = 46.0,
                y = 36.3,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            shadowfang_keep = {
                name = "Shadowfang Keep",
                levelMin = 20,
                levelMax = 26,
                minEntryLevel = 10,
                zone = "Silverpine Forest",
                x = 44.7,
                y = 67.8,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            blackfathom_deeps = {
                name = "Blackfathom Deeps",
                aliases = { "BFD" },
                levelMin = 22,
                levelMax = 28,
                minEntryLevel = 10,
                zone = "Ashenvale",
                x = 14.5,
                y = 14.6,
                players = 5,
                maxPlayers = 10,
                coordStatus = "conflict_resolved",
                coordSource = "warcrafttavern",
                note = "WoWHandbook currently places this in Darkshore; Warcraft Tavern and Classic references place the entrance at The Zoram Strand in Ashenvale.",
            },

            the_stockade = {
                name = "The Stockade",
                aliases = { "Stockade", "The Stockades" },
                levelMin = 25,
                levelMax = 29,
                minEntryLevel = 15,
                zone = "Stormwind City",
                x = 50.4,
                y = 66.2,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            gnomeregan = {
                name = "Gnomeregan",
                levelMin = 29,
                levelMax = 38,
                minEntryLevel = 15,
                zone = "Dun Morogh",
                x = 24.0,
                y = 40.0,
                players = 5,
                maxPlayers = 10,
                coordStatus = "cross_checked",
                coordSource = "warcrafttavern",
                note = "Warcraft Tavern entrance coordinate; WoWHandbook uses a different point in the Gnomeregan exterior complex.",
            },

            razorfen_kraul = {
                name = "Razorfen Kraul",
                aliases = { "RFK" },
                levelMin = 29,
                levelMax = 38,
                minEntryLevel = 15,
                zone = "The Barrens",
                x = 42.3,
                y = 89.9,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            scarlet_monastery = {
                name = "The Scarlet Monastery",
                aliases = { "Scarlet Monastery", "SM" },
                levelMin = 30,
                levelMax = 46,
                minEntryLevel = 20,
                zone = "Tirisfal Glades",
                x = 85.1,
                y = 31.4,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "wowhandbook",
                wings = {
                    graveyard = {
                        name = "Graveyard",
                        fullName = "The Scarlet Monastery - Graveyard",
                        levelMin = 30,
                        levelMax = 38,
                        minEntryLevel = 20,
                        players = 5,
                        maxPlayers = 10,
                    },
                    library = {
                        name = "Library",
                        fullName = "The Scarlet Monastery - Library",
                        levelMin = 33,
                        levelMax = 41,
                        minEntryLevel = 20,
                        players = 5,
                        maxPlayers = 10,
                    },
                    armory = {
                        name = "Armory",
                        fullName = "The Scarlet Monastery - Armory",
                        levelMin = 36,
                        levelMax = 44,
                        minEntryLevel = 20,
                        players = 5,
                        maxPlayers = 10,
                    },
                    cathedral = {
                        name = "Cathedral",
                        fullName = "The Scarlet Monastery - Cathedral",
                        levelMin = 38,
                        levelMax = 46,
                        minEntryLevel = 20,
                        players = 5,
                        maxPlayers = 10,
                    },
                },
            },

            uldaman = {
                name = "Uldaman",
                levelMin = 36,
                levelMax = 45,
                minEntryLevel = 30,
                zone = "Badlands",
                x = 44.2,
                y = 12.2,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            razorfen_downs = {
                name = "Razorfen Downs",
                aliases = { "RFD" },
                levelMin = 37,
                levelMax = 46,
                minEntryLevel = 25,
                zone = "The Barrens",
                x = 50.9,
                y = 92.9,
                players = 5,
                maxPlayers = 10,
                coordStatus = "cross_checked",
                coordSource = "wowhandbook",
                note = "WoWHandbook's ~50.9,92.9 agrees with Classic references for the actual instance entrance; some guides use an earlier approach point around 43,95.",
            },

            zulfarrak = {
                name = "Zul'Farrak",
                aliases = { "ZF" },
                levelMin = 40,
                levelMax = 47,
                minEntryLevel = 35,
                zone = "Tanaris",
                x = 38.7,
                y = 19.9,
                players = 5,
                maxPlayers = 10,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            maraudon = {
                name = "Maraudon",
                levelMin = 45,
                levelMax = 51,
                minEntryLevel = 30,
                zone = "Desolace",
                x = 29.3,
                y = 62.5,
                players = 5,
                maxPlayers = 10,
                coordStatus = "cross_checked",
                coordSource = "wowhandbook",
                approach = {
                    x = 38.0,
                    y = 58.0,
                    label = "Valley of Spears / exterior approach",
                    source = "warcrafttavern",
                },
            },

            temple_of_atal_hakkar = {
                name = "The Temple of Atal'Hakkar",
                aliases = { "Temple of Atal'Hakkar", "Sunken Temple", "ST" },
                levelMin = 50,
                levelMax = 55,
                minEntryLevel = 35,
                zone = "Swamp of Sorrows",
                x = 69.0,
                y = 54.0,
                players = 5,
                maxPlayers = 10,
                coordStatus = "conflict_resolved",
                coordSource = "cross_check",
                note = "WoWHandbook currently lists 77.3,35.9. Classic entrance references and the actual temple location place the exterior entrance around 69,54.",
            },

            blackrock_depths = {
                name = "Blackrock Depths",
                aliases = { "BRD" },
                levelMin = 52,
                levelMax = 60,
                minEntryLevel = 40,
                location = "Blackrock Mountain",
                zone = "Searing Gorge",
                x = 27.1,
                y = 72.5,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            blackrock_spire = {
                name = "Blackrock Spire",
                aliases = { "BRS" },
                levelMin = 57,
                levelMax = 60,
                minEntryLevel = 45,
                location = "Blackrock Mountain",
                zone = "Burning Steppes",
                x = 33.0,
                y = 25.2,
                coordStatus = "verified",
                coordSource = "wowhandbook",
                wings = {
                    lower = {
                        name = "Lower Blackrock Spire",
                        aliases = { "LBRS" },
                        levelMin = 57,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 5,
                        maxPlayers = 10,
                    },
                    upper = {
                        name = "Upper Blackrock Spire",
                        aliases = { "UBRS" },
                        levelMin = 60,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 10,
                        maxPlayers = 10,
                    },
                },
            },

            dire_maul = {
                name = "Dire Maul",
                aliases = { "DM" },
                levelMin = 58,
                levelMax = 60,
                minEntryLevel = 45,
                zone = "Feralas",
                x = 62.0,
                y = 33.3,
                coordStatus = "verified",
                coordSource = "wowhandbook",
                wings = {
                    east = {
                        name = "Dire Maul East",
                        aliases = { "DME" },
                        levelMin = 58,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 5,
                        maxPlayers = 5,
                    },
                    west = {
                        name = "Dire Maul West",
                        aliases = { "DMW" },
                        levelMin = 60,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 5,
                        maxPlayers = 5,
                    },
                    north = {
                        name = "Dire Maul North",
                        aliases = { "DMN" },
                        levelMin = 60,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 5,
                        maxPlayers = 5,
                    },
                },
            },

            stratholme = {
                name = "Stratholme",
                levelMin = 58,
                levelMax = 60,
                minEntryLevel = 45,
                zone = "Eastern Plaguelands",
                x = 26.1,
                y = 10.4,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "wowhandbook",
                wings = {
                    living = {
                        name = "Stratholme - Living",
                        aliases = { "Stratholme: Live", "Strat Live" },
                        levelMin = 58,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 5,
                        maxPlayers = 5,
                    },
                    undead = {
                        name = "Stratholme - Undead",
                        aliases = { "Stratholme: Dead", "Strat UD" },
                        levelMin = 58,
                        levelMax = 60,
                        minEntryLevel = 45,
                        players = 5,
                        maxPlayers = 5,
                    },
                },
            },

            scholomance = {
                name = "Scholomance",
                aliases = { "Scholo" },
                levelMin = 58,
                levelMax = 60,
                minEntryLevel = 45,
                zone = "Western Plaguelands",
                x = 69.7,
                y = 73.4,
                players = 5,
                maxPlayers = 5,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },
        },

        Forever = {
            hall_of_thanes = {
                name = "Hall of Thanes",
                aliases = { "The Hall of Thanes" },
                isForeverNew = true,
                levelMin = 13,
                levelMax = 18,
                minEntryLevel = nil,
                zone = "Ironforge",
                parentZone = "Dun Morogh",
                x = 43.0,
                y = 51.0,
                players = nil,
                maxPlayers = nil,
                coordStatus = "verified",
                coordSource = "wowhead",
                note = "Inside Ironforge, in the High Seat / throne hall.",
            },

            ruins_of_lordaeron = {
                name = "Ruins of Lordaeron",
                isForeverNew = true,
                levelMin = 15,
                levelMax = 20,
                minEntryLevel = nil,
                zone = "Tirisfal Glades",
                x = 61.3,
                y = 58.8,
                players = nil,
                maxPlayers = nil,
                coordStatus = "verified",
                coordSource = "dving",
                note = "Inner courtyard of the Lordaeron ruins above Undercity; approach through the former Lordaeron main gate.",
            },

            excavation_site_wetlands = {
                name = "Excavation Site: Wetlands",
                aliases = { "Excavation Site" },
                isForeverNew = true,
                levelMin = 24,
                levelMax = 29,
                minEntryLevel = nil,
                zone = "Wetlands",
                x = 36.8,
                y = 48.2,
                players = nil,
                maxPlayers = nil,
                coordStatus = "verified",
                coordSource = "wowgg_dving",
                note = "Dungeon entrance at Whelgar's Excavation Site in Wetlands.",
            },

            city_of_dalaran = {
                name = "City of Dalaran",
                isForeverNew = true,
                levelMin = 28,
                levelMax = 33,
                minEntryLevel = nil,
                zone = "Alterac Mountains",
                x = 32.4,
                y = 66.7,
                players = nil,
                maxPlayers = nil,
                coordStatus = "verified",
                coordSource = "wowgg_dving",
                note = "Entrance beneath the Violet Dome of Dalaran.",
            },

            drowned_city = {
                name = "The Drowned City",
                aliases = { "Drowned City" },
                isForeverNew = true,
                levelMin = 35,
                levelMax = 40,
                minEntryLevel = nil,
                zone = "Stranglethorn Vale",
                x = 19.8,
                y = 22.4,
                players = nil,
                maxPlayers = nil,
                coordStatus = "verified",
                coordSource = "wowgg_dving",
                note = "Underwater entrance near the north-west coast; dive toward the ruined troll columns. Level range 35-40 uses the corrected Forever table.",
            },

            kroldok_stronghold = {
                name = "Krol'Dok Stronghold",
                aliases = { "Krol’dok Stronghold", "Krol'Dok" },
                isForeverNew = true,
                levelMin = 40,
                levelMax = 45,
                minEntryLevel = nil,
                zone = "The Riverglades",
                aliasesZones = { "Riverglades" },
                x = 74.2,
                y = 33.5,
                players = nil,
                maxPlayers = nil,
                coordStatus = "verified",
                coordSource = "wowgg_dving_wowhead",
                note = "Stronghold in the wooded eastern ravine. Level range 40-45 is the corrected Blizzard-published range.",
            },

            alcaz_prison = {
                name = "Alcaz Prison",
                aliases = { "Alcaz Island Prison" },
                isForeverNew = true,
                levelMin = 48,
                levelMax = 53,
                minEntryLevel = nil,
                zone = "Dustwallow Marsh",
                x = 78.4,
                y = 18.2,
                players = nil,
                maxPlayers = nil,
                coordStatus = "verified",
                coordSource = "wowgg_dving_wowhead",
                note = "Entrance on Alcaz Island, leading into the prison complex beneath the main fort.",
            },

            blackmaw_hold = {
                name = "Blackmaw Hold",
                isForeverNew = true,
                levelMin = 55,
                levelMax = 60,
                minEntryLevel = nil,
                zone = "Azshara",
                x = 23.4,
                y = 28.5,
                players = nil,
                maxPlayers = nil,
                coordStatus = "verified",
                coordSource = "wowgg_dving_wowhead",
                note = "Far north of Azshara, behind the large furbolg gate. The dungeon also connects onward toward Barrow Deeps.",
            },

            shapers_terrace = {
                name = "Shaper's Terrace",
                aliases = { "The Shaper's Terrace", "Shaper’s Terrace" },
                isForeverNew = true,
                levelMin = 58,
                levelMax = 60,
                minEntryLevel = nil,
                zone = "Un'Goro Crater",
                x = 41.6,
                y = 11.2,
                players = nil,
                maxPlayers = nil,
                coordStatus = "verified",
                coordSource = "wowgg_dving",
                note = "High on the rocky slopes along the northern wall of Un'Goro Crater.",
            },
        },
    },

    Raids = {
        Classic = {
            molten_core = {
                name = "Molten Core",
                aliases = { "MC" },
                levelMin = 60,
                levelMax = 60,
                zone = "Burning Steppes",
                location = "Blackrock Mountain",
                x = 26.3,
                y = 24.6,
                players = 40,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            onyxias_lair = {
                name = "Onyxia's Lair",
                aliases = { "Onyxia", "Ony" },
                levelMin = 60,
                levelMax = 60,
                zone = "Dustwallow Marsh",
                x = 52.3,
                y = 76.1,
                players = 40,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            blackwing_lair = {
                name = "Blackwing Lair",
                aliases = { "BWL" },
                levelMin = 60,
                levelMax = 60,
                zone = "Burning Steppes",
                location = "Blackrock Mountain",
                x = 32.5,
                y = 32.4,
                players = 40,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            zulgurub = {
                name = "Zul'Gurub",
                aliases = { "ZG" },
                levelMin = 60,
                levelMax = 60,
                zone = "Stranglethorn Vale",
                x = 54.0,
                y = 17.6,
                players = 20,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            ruins_of_ahnqiraj = {
                name = "Ruins of Ahn'Qiraj",
                aliases = { "AQ20" },
                levelMin = 60,
                levelMax = 60,
                zone = "Silithus",
                x = 29.0,
                y = 92.8,
                players = 20,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            temple_of_ahnqiraj = {
                name = "Temple of Ahn'Qiraj",
                aliases = { "AQ40" },
                levelMin = 60,
                levelMax = 60,
                zone = "Silithus",
                x = 29.0,
                y = 92.7,
                players = 40,
                coordStatus = "verified",
                coordSource = "wowhandbook",
            },

            naxxramas = {
                name = "Naxxramas",
                aliases = { "Naxx" },
                levelMin = 60,
                levelMax = 60,
                zone = "Eastern Plaguelands",
                x = 39.0,
                y = 26.0,
                players = 40,
                coordStatus = "cross_checked",
                coordSource = "wowhead_classic",
                note = "Ground entry is the Plaguewood teleport spire; the necropolis itself floats above the zone.",
            },
        },

        Forever = {
            barrow_deeps = {
                name = "Barrow Deeps",
                aliases = { "The Barrow Deeps" },
                isForeverNew = true,
                levelMin = 60,
                levelMax = 60,
                zone = "Mount Hyjal",
                x = nil,
                y = nil,
                players = 10,
                coordStatus = "tba",
                note = "Warcraft Tavern identifies a Mount Hyjal entrance and says two other entrances are still TBA.",
            },

            hyjal_summit = {
                name = "Hyjal Summit",
                isForeverNew = true,
                levelMin = 60,
                levelMax = 60,
                zone = "Mount Hyjal",
                x = nil,
                y = nil,
                players = 20,
                coordStatus = "tba",
                note = "Location is confirmed as Mount Hyjal; a reliable entrance coordinate is not yet published in the checked sources.",
            },
        },
    },
}

-- Convert percentage coordinates (e.g. 53.0, 48.9) to normalized 0..1.
function DB.GetNormalizedCoordinates(instance)
    if not instance or type(instance.x) ~= "number" or type(instance.y) ~= "number" then
        return nil, nil
    end

    return instance.x / 100, instance.y / 100
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

ns.DB = DB
