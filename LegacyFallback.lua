-- Legacy coordinate fallback extracted from the supplied
-- HandyNotes_DungeonLocations (Classic) base addon.
--
-- IMPORTANT:
-- These values are NEVER allowed to overwrite coordinates that already
-- exist in Database.lua. They are only a last-resort fallback for records
-- that exist in the new database but have no x/y coordinate there.
local addonName, ns = ...

ns.LegacyFallback = {
    Dungeons = {
        ragefire_chasm = { zone = "Orgrimmar", mapID = 1454, x = 51.60, y = 49.83 },
        deadmines = { zone = "Westfall", mapID = 1436, x = 42.57, y = 71.71 },
        wailing_caverns = { zone = "The Barrens", mapID = 1413, x = 45.97, y = 36.34 },
        shadowfang_keep = { zone = "Silverpine Forest", mapID = 1421, x = 44.80, y = 67.80 },
        blackfathom_deeps = { zone = "Ashenvale", mapID = 1440, x = 14.00, y = 13.10 },
        the_stockade = { zone = "Stormwind City", mapID = 1453, x = 40.28, y = 55.21 },
        gnomeregan = { zone = "Dun Morogh", mapID = 1426, x = 24.46, y = 39.81 },
        razorfen_kraul = { zone = "The Barrens", mapID = 1413, x = 41.89, y = 89.50 },
        scarlet_monastery = { zone = "Tirisfal Glades", mapID = 1420, x = 85.30, y = 32.20 },
        uldaman = { zone = "Badlands", mapID = 1418, x = 44.53, y = 12.12 },
        razorfen_downs = { zone = "The Barrens", mapID = 1413, x = 49.13, y = 93.48 },
        zulfarrak = { zone = "Tanaris", mapID = 1446, x = 38.72, y = 20.00 },
        maraudon = { zone = "Desolace", mapID = 1443, x = 29.10, y = 62.50 },
        temple_of_atal_hakkar = { zone = "Swamp of Sorrows", mapID = 1435, x = 69.50, y = 52.50 },
        blackrock_depths = { zone = "Searing Gorge", mapID = 1427, x = 34.70, y = 86.00 },
        blackrock_spire = { zone = "Burning Steppes", mapID = 1428, x = 29.94, y = 47.78 },
        dire_maul = { zone = "Feralas", mapID = 1444, x = 59.11, y = 43.28 },
        stratholme = { zone = "Eastern Plaguelands", mapID = 1423, x = 30.85, y = 17.00 },
        scholomance = { zone = "Western Plaguelands", mapID = 1422, x = 69.00, y = 72.90 },
    },
    Raids = {
        molten_core = { zone = "Burning Steppes", mapID = 1428, x = 29.94, y = 47.78 },
        onyxias_lair = { zone = "Dustwallow Marsh", mapID = 1445, x = 52.90, y = 77.70 },
        blackwing_lair = { zone = "Burning Steppes", mapID = 1428, x = 29.94, y = 47.78 },
        zulgurub = { zone = "Stranglethorn Vale", mapID = 1434, x = 53.96, y = 17.57 },
        ruins_of_ahnqiraj = { zone = "Silithus", mapID = 1451, x = 29.09, y = 93.20 },
        temple_of_ahnqiraj = { zone = "Silithus", mapID = 1451, x = 29.09, y = 93.20 },
        naxxramas = { zone = "Eastern Plaguelands", mapID = 1423, x = 39.00, y = 26.00 },
    },
}
