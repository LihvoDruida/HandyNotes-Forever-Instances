-- Forever Instances - Atlas metadata bridge
-- Generated from the user-supplied Atlas v1.53.00 AreaIDs_ClassicForever.lua.
-- Atlas source table states it is updated for WoW Forever 1.60.1.69913.
-- This file stores factual AreaID mappings only; it does not copy Atlas implementation code.
local addonName, ns = ...

local AtlasData = {
    sourceAddon = "Atlas",
    sourceVersion = "v1.53.00",
    sourceClientBuild = "1.60.1.69913",
    instances = {
        ragefire_chasm = {
            instanceAreaIDs = { 2437 },
            zoneAreaIDs = { 1637 },
        },
        deadmines = {
            instanceAreaIDs = { 1581 },
            zoneAreaIDs = { 40, 206, 16149 },
        },
        wailing_caverns = {
            instanceAreaIDs = { 718 },
            zoneAreaIDs = { 17 },
        },
        shadowfang_keep = {
            instanceAreaIDs = { 209, 236 },
            zoneAreaIDs = { 130 },
        },
        blackfathom_deeps = {
            instanceAreaIDs = { 719, 2797 },
            zoneAreaIDs = { 331, 16169 },
        },
        the_stockade = {
            instanceAreaIDs = { 717 },
            zoneAreaIDs = { 1519, 16509 },
        },
        gnomeregan = {
            instanceAreaIDs = { 133, 721 },
            zoneAreaIDs = { 1 },
        },
        razorfen_kraul = {
            instanceAreaIDs = { 491, 1717 },
            zoneAreaIDs = { 17 },
        },
        scarlet_monastery = {
            atlasNames = { "Scarlet Monastery" },
            instanceAreaIDs = { 796 },
            zoneAreaIDs = { 85 },
        },
        uldaman = {
            instanceAreaIDs = { 1337, 1517 },
            zoneAreaIDs = { 3 },
        },
        razorfen_downs = {
            instanceAreaIDs = { 722, 1316 },
            zoneAreaIDs = { 17 },
        },
        zulfarrak = {
            instanceAreaIDs = { 978, 1176 },
            zoneAreaIDs = { 440 },
        },
        maraudon = {
            instanceAreaIDs = { 2100 },
            zoneAreaIDs = { 405, 16017 },
        },
        temple_of_atal_hakkar = {
            instanceAreaIDs = { 1477 },
            zoneAreaIDs = { 8, 16116 },
        },
        blackrock_depths = {
            instanceAreaIDs = { 1584, 17803 },
            zoneAreaIDs = { 51 },
        },
        blackrock_spire = {
            instanceAreaIDs = { 1583, 17804 },
            zoneAreaIDs = { 46, 16508 },
        },
        dire_maul = {
            instanceAreaIDs = { 2557, 2577 },
            zoneAreaIDs = { 357, 16018 },
        },
        stratholme = {
            instanceAreaIDs = { 2017, 2279 },
            zoneAreaIDs = { 139, 16028 },
        },
        scholomance = {
            instanceAreaIDs = { 2057 },
            zoneAreaIDs = { 28 },
        },
        hall_of_thanes = {
            atlasNames = { "The Hall of Thanes" },
            instanceAreaIDs = { 16919 },
            zoneAreaIDs = { 1537 },
        },
        ruins_of_lordaeron = {
            instanceAreaIDs = { 153, 16611 },
            zoneAreaIDs = { 85 },
        },
        excavation_site_wetlands = {
            instanceAreaIDs = { 16732, 17732 },
            zoneAreaIDs = { 11 },
        },
        city_of_dalaran = {
            instanceAreaIDs = { 16544, 16560 },
            zoneAreaIDs = { 36 },
        },
        drowned_city = {
            instanceAreaIDs = {  },
            zoneAreaIDs = { 33, 16117 },
        },
        kroldok_stronghold = {
            atlasNames = { "Krol'dok Stronghold" },
            instanceAreaIDs = { 17780 },
            zoneAreaIDs = { 16591 },
        },
        alcaz_prison = {
            instanceAreaIDs = {  },
            zoneAreaIDs = { 15 },
        },
        blackmaw_hold = {
            instanceAreaIDs = { 1216 },
            zoneAreaIDs = { 16, 16003 },
        },
        shapers_terrace = {
            atlasNames = { "The Shaper's Terrace" },
            instanceAreaIDs = { 16985 },
            zoneAreaIDs = { 490 },
        },
        molten_core = {
            instanceAreaIDs = { 2717 },
            zoneAreaIDs = { 46, 16508 },
        },
        onyxias_lair = {
            instanceAreaIDs = { 2159 },
            zoneAreaIDs = { 15 },
        },
        blackwing_lair = {
            instanceAreaIDs = { 2677 },
            zoneAreaIDs = { 46, 16508 },
        },
        zulgurub = {
            instanceAreaIDs = { 19, 1977, 16129 },
            zoneAreaIDs = { 33, 16117 },
        },
        ruins_of_ahnqiraj = {
            instanceAreaIDs = { 3429, 3454 },
            zoneAreaIDs = { 1377 },
        },
        temple_of_ahnqiraj = {
            instanceAreaIDs = { 16076 },
            zoneAreaIDs = { 1377 },
        },
        naxxramas = {
            instanceAreaIDs = { 3456, 16394 },
            zoneAreaIDs = { 139, 16028 },
        },
        barrow_deeps = {
            instanceAreaIDs = {  },
            zoneAreaIDs = { 616, 16004 },
        },
        hyjal_summit = {
            instanceAreaIDs = {  },
            zoneAreaIDs = { 616, 16004 },
        },
    },
}

-- Attach Atlas metadata to every known instance without changing canonical x/y coordinates.
-- Atlas core does not provide outdoor world-map XY coordinates in this dataset; AreaIDs are
-- kept separately so they can be used for validation and optional runtime Atlas integration.
local function attach(bucket)
    for _, group in pairs(bucket or {}) do
        for id, instance in pairs(group or {}) do
            local meta = AtlasData.instances[id]
            if meta then
                instance.atlas = meta
            end
        end
    end
end

if ns.DB then
    attach(ns.DB.Dungeons)
    attach(ns.DB.Raids)
end

ns.AtlasData = AtlasData
