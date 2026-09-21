local addonName, ns = ...

local PLUGIN_NAME = "ForeverInstances"
local ADDON_TITLE = "HandyNotes: Forever Instances"

local WORLD_MAP_ID = 947
if C_Map and type(C_Map.GetFallbackWorldMapID) == "function" then
    local ok, mapID = pcall(C_Map.GetFallbackWorldMapID)
    if ok and type(mapID) == "number" then
        WORLD_MAP_ID = mapID
    end
end

-- Keep the visual language of the supplied base addon:
--   * raids: standard green portal
--   * existing/Classic-era dungeons: standard blue portal
--   * Forever-new dungeons: dedicated blue/orange portal
-- Forever raids intentionally remain green so icon color continues to identify
-- instance type first, while only brand-new Forever dungeons get the new style.
local ICON_DUNGEON = "Interface\\AddOns\\HandyNotes_ForeverInstances\\dungeon.tga"
local ICON_RAID = "Interface\\AddOns\\HandyNotes_ForeverInstances\\raid.tga"
local ICON_FOREVER_DUNGEON = "Interface\\AddOns\\HandyNotes_ForeverInstances\\forever_dungeon.tga"

local HandyNotes = LibStub and LibStub("AceAddon-3.0", true) and LibStub("AceAddon-3.0"):GetAddon("HandyNotes", true)
local AceDB = LibStub and LibStub("AceDB-3.0", true)

if not HandyNotes or not AceDB or not ns.DB then
    return
end

local defaults = {
    profile = {
        zoneScale = 2.0,
        zoneAlpha = 1.0,
        continentScale = 1.6,
        continentAlpha = 0.95,
        showOnContinent = true,
        showOnAzeroth = true,
        language = "enUS",
        tomtom = true,
        show = {
            Dungeon = true,
            Raid = true,
            Classic = true,
            Forever = true,
        },
        showCoordinates = true,
        showDescriptions = true,
        showNotes = true,
    },
}

local db
local nodes = {}
local worldNodes = {}
local worldNodesDirty = true
local ancestorZones = {}
local unresolved = {}
local mapNameIndex = nil
local ancestorNameCache = {}
local initialized = false
local waypointHandles = {}

local function activeLanguage()
    if db and db.language == "ukUA" then
        return "ukUA"
    end
    return "enUS"
end

local function localizedRaw(key)
    local locales = ns.Locales or {}
    local english = locales.enUS or {}
    local bucket = locales[activeLanguage()] or english
    return bucket[key] or english[key]
end

local function L(key, ...)
    local value = localizedRaw(key)
    local text = type(value) == "string" and value or key

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, text, ...)
        if ok then return formatted end
        return text
    end
    return text
end

local function optionalL(key, ...)
    local text = localizedRaw(key)
    if type(text) ~= "string" or text == "" then return nil end

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, text, ...)
        if ok then return formatted end
        return text
    end
    return text
end

local function localizedDescription(instance)
    if not instance or type(instance.descriptionKey) ~= "string" then return nil end
    return optionalL(instance.descriptionKey)
end

local function localizedForeverChange(instance)
    if not instance or type(instance.foreverChangeKey) ~= "string" then return nil end
    return optionalL(instance.foreverChangeKey)
end

local function provenanceLabel(instance)
    if not instance then return L("CLASSIC") end

    if instance.isForeverNew == true or instance.origin == "Forever" or instance._group == "Forever" then
        return L("FOREVER") .. " • " .. L("NEW")
    end

    if instance.availableInForever then
        if instance.foreverStatus == "updated" then
            return L("CLASSIC") .. " • " .. L("FOREVER") .. " • " .. L("UPDATED")
        end
        return L("CLASSIC") .. " • " .. L("FOREVER")
    end

    return L("CLASSIC")
end

local function trim(value)
    if type(value) ~= "string" then return value end
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function normalizeName(value)
    if type(value) ~= "string" then return "" end
    value = value:lower()
    value = value:gsub("[’`´]", "'")
    value = value:gsub("^the%s+", "")
    value = value:gsub("[%p%s]+", "")
    return value
end

local function safeGetMapInfo(mapID)
    if not C_Map or type(C_Map.GetMapInfo) ~= "function" or type(mapID) ~= "number" then
        return nil
    end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if ok then return info end
    return nil
end

local function addMapCandidate(index, info)
    if type(info) ~= "table" or type(info.mapID) ~= "number" or type(info.name) ~= "string" then
        return
    end

    local key = normalizeName(info.name)
    if key == "" then return end

    index[key] = index[key] or {}
    for _, existing in ipairs(index[key]) do
        if existing.mapID == info.mapID then
            return
        end
    end
    table.insert(index[key], info)
end

local function buildMapIndex()
    local index = {}

    -- Forever exposes the modern C_Map API. Azeroth (947) is the main root;
    -- Cosmic (946) is also scanned as a safe fallback for client-side changes.
    if C_Map and type(C_Map.GetMapChildrenInfo) == "function" then
        for _, rootID in ipairs({ WORLD_MAP_ID, 946 }) do
            local rootInfo = safeGetMapInfo(rootID)
            if rootInfo then addMapCandidate(index, rootInfo) end

            local ok, children = pcall(C_Map.GetMapChildrenInfo, rootID, nil, true)
            if ok and type(children) == "table" then
                for _, info in ipairs(children) do
                    addMapCandidate(index, info)
                end
            end
        end
    end

    -- Also index every legacy map ID from the supplied base addon if that map
    -- still exists in the current Forever client.
    for _, bucket in pairs(ns.LegacyFallback or {}) do
        for _, legacy in pairs(bucket) do
            local info = safeGetMapInfo(legacy.mapID)
            if info then addMapCandidate(index, info) end
        end
    end

    -- Finally include the player's current map and its ancestry. This helps on
    -- beta builds where a brand-new Forever map is not yet attached to 947.
    if C_Map and type(C_Map.GetBestMapForUnit) == "function" then
        local ok, current = pcall(C_Map.GetBestMapForUnit, "player")
        if ok and current then
            local seen = {}
            while current and current ~= 0 and not seen[current] do
                seen[current] = true
                local info = safeGetMapInfo(current)
                if not info then break end
                addMapCandidate(index, info)
                current = info.parentMapID
            end
        end
    end

    mapNameIndex = index
end

local function getAncestorNameSet(mapID)
    if ancestorNameCache[mapID] then
        return ancestorNameCache[mapID]
    end

    local result = {}
    local seen = {}
    local current = mapID

    while current and current ~= 0 and not seen[current] do
        seen[current] = true
        local info = safeGetMapInfo(current)
        if not info then break end
        result[normalizeName(info.name)] = true
        current = info.parentMapID
    end

    ancestorNameCache[mapID] = result
    return result
end

local function candidateScore(info, parentZone)
    local score = 0

    if Enum and Enum.UIMapType then
        if info.mapType == Enum.UIMapType.Zone then
            score = score + 100
        elseif info.mapType == Enum.UIMapType.Orphan then
            score = score + 60
        elseif info.mapType == Enum.UIMapType.Continent then
            score = score + 10
        elseif info.mapType == Enum.UIMapType.Dungeon then
            score = score - 100
        end
    end

    if parentZone then
        local ancestors = getAncestorNameSet(info.mapID)
        if ancestors[normalizeName(parentZone)] then
            score = score + 50
        end
    end

    return score
end

local function namesForInstance(instance)
    local names = { instance.zone }
    if type(instance.aliasesZones) == "table" then
        for _, alias in ipairs(instance.aliasesZones) do
            table.insert(names, alias)
        end
    end
    return names
end

local function resolveMapID(instance, legacy)
    if not mapNameIndex then buildMapIndex() end

    local bestInfo, bestScore
    for _, zoneName in ipairs(namesForInstance(instance)) do
        local candidates = mapNameIndex[normalizeName(zoneName)]
        if candidates then
            for _, info in ipairs(candidates) do
                local score = candidateScore(info, instance.parentZone)
                if not bestInfo or score > bestScore then
                    bestInfo, bestScore = info, score
                end
            end
        end
    end

    if bestInfo then
        return bestInfo.mapID
    end

    -- Last chance: use the old addon's map ID only when the current client's
    -- map at that ID still has the expected zone name. This prevents accidental
    -- placement on a reused numeric map ID.
    if legacy and legacy.mapID then
        local info = safeGetMapInfo(legacy.mapID)
        if info then
            local actual = normalizeName(info.name)
            for _, expected in ipairs(namesForInstance(instance)) do
                if actual == normalizeName(expected) then
                    return legacy.mapID
                end
            end
        end
    end

    return nil
end

local function applyLegacyFallback()
    local used = 0

    local function applyBucket(kind, sourceBucket, fallbackBucket)
        if type(sourceBucket) ~= "table" then return end
        fallbackBucket = fallbackBucket or {}

        for groupName, group in pairs(sourceBucket) do
            if type(group) == "table" then
                for id, instance in pairs(group) do
                    if type(instance) == "table" then
                        local legacy = fallbackBucket[id]
                        if legacy then
                            instance.legacyMapID = legacy.mapID
                            if (type(instance.x) ~= "number" or type(instance.y) ~= "number")
                                and type(legacy.x) == "number" and type(legacy.y) == "number" then
                                instance.x = legacy.x
                                instance.y = legacy.y
                                instance.coordStatus = "legacy_fallback"
                                instance.coordSource = "supplied_base_addon"
                                instance.coordFallbackFromLegacy = true
                                used = used + 1
                            end
                        end
                        instance._kind = kind
                        instance._group = groupName
                        instance._id = id
                    end
                end
            end
        end
    end

    applyBucket("Dungeon", ns.DB.Dungeons, ns.LegacyFallback and ns.LegacyFallback.Dungeons)
    applyBucket("Raid", ns.DB.Raids, ns.LegacyFallback and ns.LegacyFallback.Raids)

    ns.LegacyFallbackApplied = used
end

local function packCoord(percentX, percentY)
    local x = math.floor(percentX * 100 + 0.5)
    local y = math.floor(percentY * 100 + 0.5)
    return x * 10000 + y
end

local function addAncestorRelation(zoneMapID)
    local seen = {}
    local current = zoneMapID

    while current and current ~= 0 and not seen[current] do
        seen[current] = true
        local info = safeGetMapInfo(current)
        if not info then break end
        local parent = info.parentMapID
        if parent and parent ~= 0 then
            ancestorZones[parent] = ancestorZones[parent] or {}
            ancestorZones[parent][zoneMapID] = true
        end
        current = parent
    end
end

local function addNode(mapID, coord, instance)
    nodes[mapID] = nodes[mapID] or {}
    local node = nodes[mapID][coord]
    if not node then
        node = { instances = {} }
        nodes[mapID][coord] = node
    end
    table.insert(node.instances, instance)
end

local function rebuildNodes()
    wipe(nodes)
    wipe(worldNodes)
    worldNodesDirty = true
    wipe(ancestorZones)
    wipe(unresolved)
    wipe(ancestorNameCache)
    buildMapIndex()

    local function processBucket(sourceBucket, fallbackBucket)
        for _, group in pairs(sourceBucket or {}) do
            for id, instance in pairs(group or {}) do
                if type(instance) == "table" then
                    local legacy = fallbackBucket and fallbackBucket[id] or nil
                    if type(instance.x) == "number" and type(instance.y) == "number" then
                        local mapID = resolveMapID(instance, legacy)
                        if mapID then
                            instance._mapID = mapID
                            addNode(mapID, packCoord(instance.x, instance.y), instance)
                            addAncestorRelation(mapID)
                        else
                            unresolved[id] = {
                                reason = "map_unresolved",
                                zone = instance.zone,
                                name = instance.name,
                            }
                        end
                    else
                        unresolved[id] = {
                            reason = "coordinate_missing",
                            zone = instance.zone,
                            name = instance.name,
                        }
                    end
                end
            end
        end
    end

    processBucket(ns.DB.Dungeons, ns.LegacyFallback and ns.LegacyFallback.Dungeons)
    processBucket(ns.DB.Raids, ns.LegacyFallback and ns.LegacyFallback.Raids)
    ns.Unresolved = unresolved
end

local function nodeVisible(instance)
    if not db then return true end
    if not db.show[instance._kind] then return false end
    if instance._group == "Forever" then
        return db.show.Forever
    end
    return db.show.Classic
end

local function projectPointToMap(sourceMapID, targetMapID, x, y)
    if sourceMapID == targetMapID then
        return x, y
    end

    if not C_Map or type(C_Map.GetMapRectOnMap) ~= "function" then
        return nil, nil
    end

    -- Blizzard exposes the exact rectangle occupied by a child map on a
    -- parent/top-level map. Using it here avoids the generic HBD zone -> world
    -- translation path, which can be wrong for the Forever Azeroth layout.
    local ok, minX, maxX, minY, maxY = pcall(C_Map.GetMapRectOnMap, sourceMapID, targetMapID)
    if ok
        and type(minX) == "number" and type(maxX) == "number"
        and type(minY) == "number" and type(maxY) == "number" then
        local tx = minX + (maxX - minX) * x
        local ty = minY + (maxY - minY) * y
        if tx >= 0 and tx <= 1 and ty >= 0 and ty <= 1 then
            return tx, ty
        end
    end

    -- Some maps only expose a rectangle to their direct parent. Walk the
    -- hierarchy one level at a time as a safe fallback.
    local currentMapID = sourceMapID
    local tx, ty = x, y
    local seen = {}

    while currentMapID and currentMapID ~= 0 and not seen[currentMapID] do
        seen[currentMapID] = true
        local info = safeGetMapInfo(currentMapID)
        if not info or not info.parentMapID or info.parentMapID == 0 then
            break
        end

        local parentMapID = info.parentMapID
        local rectOK, pMinX, pMaxX, pMinY, pMaxY = pcall(C_Map.GetMapRectOnMap, currentMapID, parentMapID)
        if not rectOK
            or type(pMinX) ~= "number" or type(pMaxX) ~= "number"
            or type(pMinY) ~= "number" or type(pMaxY) ~= "number" then
            break
        end

        tx = pMinX + (pMaxX - pMinX) * tx
        ty = pMinY + (pMaxY - pMinY) * ty
        currentMapID = parentMapID

        if currentMapID == targetMapID then
            if tx >= 0 and tx <= 1 and ty >= 0 and ty <= 1 then
                return tx, ty
            end
            return nil, nil
        end
    end

    return nil, nil
end

local function nodeHasVisibleInstance(node)
    for _, instance in ipairs(node.instances or {}) do
        if nodeVisible(instance) then
            return true
        end
    end
    return false
end

local function nodeIcon(node)
    local hasRaid = false
    local hasForeverDungeon = false

    for _, instance in ipairs(node.instances or {}) do
        if nodeVisible(instance) then
            if instance._kind == "Raid" then
                hasRaid = true
            elseif instance._kind == "Dungeon"
                and (instance.isForeverNew == true or instance._group == "Forever") then
                hasForeverDungeon = true
            end
        end
    end

    if hasRaid then
        return ICON_RAID
    elseif hasForeverDungeon then
        return ICON_FOREVER_DUNGEON
    end
    return ICON_DUNGEON
end

local function rebuildWorldNodes()
    wipe(worldNodes)
    worldNodesDirty = false

    if not db or not db.showOnAzeroth then
        return
    end

    local sourceMaps = ancestorZones[WORLD_MAP_ID]
    if not sourceMaps then
        return
    end

    for sourceMapID in pairs(sourceMaps) do
        local sourceNodes = nodes[sourceMapID]
        if sourceNodes then
            for sourceCoord, sourceNode in pairs(sourceNodes) do
                local x, y = HandyNotes:getXY(sourceCoord)
                local worldX, worldY = projectPointToMap(sourceMapID, WORLD_MAP_ID, x, y)

                if worldX and worldY then
                    local worldCoord = HandyNotes:getCoord(worldX, worldY)
                    local worldNode = worldNodes[worldCoord]
                    if not worldNode then
                        worldNode = { instances = {}, sources = {} }
                        worldNodes[worldCoord] = worldNode
                    end

                    for _, instance in ipairs(sourceNode.instances) do
                        table.insert(worldNode.instances, instance)
                    end
                    table.insert(worldNode.sources, {
                        mapID = sourceMapID,
                        coord = sourceCoord,
                        node = sourceNode,
                    })
                end
            end
        end
    end
end

local function getWorldNodes()
    if worldNodesDirty then
        rebuildWorldNodes()
    end
    return worldNodes
end

local function getDisplayNode(uiMapID, coord)
    if uiMapID == WORLD_MAP_ID then
        return getWorldNodes()[coord]
    end
    return nodes[uiMapID] and nodes[uiMapID][coord]
end

local function collectSourceMaps(uiMapID, isMinimapUpdate)
    local list, seen = {}, {}

    local function add(mapID)
        if mapID and nodes[mapID] and not seen[mapID] then
            seen[mapID] = true
            table.insert(list, mapID)
        end
    end

    add(uiMapID)

    -- If the player is on a child/micro map, allow nodes from its parent zone.
    local current = uiMapID
    local parentSeen = {}
    while current and current ~= 0 and not parentSeen[current] do
        parentSeen[current] = true
        local info = safeGetMapInfo(current)
        if not info then break end
        current = info.parentMapID
        add(current)
    end

    -- World/continent maps need descendant zone nodes. Do not do this on the
    -- minimap because HBD handles the player's current zone separately.
    -- Azeroth/Cosmic root maps are handled separately so the global map can be
    -- disabled without affecting continent maps.
    if not isMinimapUpdate and ancestorZones[uiMapID] then
        local allowChildren = false
        if uiMapID == WORLD_MAP_ID or uiMapID == 946 then
            allowChildren = false
        else
            allowChildren = db.showOnContinent
        end

        if allowChildren then
            for zoneMapID in pairs(ancestorZones[uiMapID]) do
                add(zoneMapID)
            end
        end
    end

    return list
end

local iteratorPool = setmetatable({}, { __mode = "k" })

local function acquireIteratorState()
    local state = next(iteratorPool) or {}
    iteratorPool[state] = nil
    wipe(state)
    return state
end

local function releaseIteratorState(state)
    wipe(state)
    iteratorPool[state] = true
end

local function iterNodes(state, previousCoord)
    if not state then return end

    while state.mapIndex <= #state.maps do
        local mapID = state.maps[state.mapIndex]
        local data = nodes[mapID]
        local coord, node = next(data or {}, previousCoord)

        while coord do
            local visible = false
            for _, instance in ipairs(node.instances) do
                if nodeVisible(instance) then
                    visible = true
                    break
                end
            end

            if visible then
                local icon = nodeIcon(node)

                local scale = state.zoneView and db.zoneScale or db.continentScale
                local alpha = state.zoneView and db.zoneAlpha or db.continentAlpha
                return coord, mapID == state.requestedMapID and nil or mapID, icon, scale, alpha
            end

            coord, node = next(data, coord)
        end

        state.mapIndex = state.mapIndex + 1
        previousCoord = nil
    end

    releaseIteratorState(state)
end

local function iterWorldNodes(state, previousCoord)
    if not state then return end

    local coord, node = next(state.data, previousCoord)
    while coord do
        if nodeHasVisibleInstance(node) then
            return coord, nil, nodeIcon(node), db.continentScale, db.continentAlpha
        end
        coord, node = next(state.data, coord)
    end

    releaseIteratorState(state)
end

local pluginHandler = {}

function pluginHandler:GetNodes2(uiMapID, isMinimapUpdate)
    if not isMinimapUpdate and uiMapID == WORLD_MAP_ID then
        if not db.showOnAzeroth then
            return next, {}
        end

        local state = acquireIteratorState()
        state.data = getWorldNodes()
        return iterWorldNodes, state, nil
    end

    local maps = collectSourceMaps(uiMapID, isMinimapUpdate)
    if #maps == 0 then
        return next, {}
    end

    local mapInfo = safeGetMapInfo(uiMapID)
    local zoneView = isMinimapUpdate
    if not zoneView and mapInfo and Enum and Enum.UIMapType then
        zoneView = mapInfo.mapType == Enum.UIMapType.Zone
            or mapInfo.mapType == Enum.UIMapType.Orphan
            or mapInfo.mapType == Enum.UIMapType.Micro
    end

    local state = acquireIteratorState()
    state.maps = maps
    state.mapIndex = 1
    state.requestedMapID = uiMapID
    state.zoneView = zoneView

    return iterNodes, state, nil
end

local function levelText(instance)
    local minLevel, maxLevel = instance.levelMin, instance.levelMax
    if type(minLevel) ~= "number" then return nil end
    if type(maxLevel) ~= "number" or minLevel == maxLevel then
        return tostring(minLevel)
    end
    return string.format("%d-%d", minLevel, maxLevel)
end

local function playerText(instance)
    if type(instance.players) == "number" and type(instance.maxPlayers) == "number" and instance.players ~= instance.maxPlayers then
        return L("PLAYER_RANGE", instance.players, instance.maxPlayers)
    elseif type(instance.players) == "number" then
        return L("PLAYERS", instance.players)
    elseif type(instance.maxPlayers) == "number" then
        return L("UP_TO_PLAYERS", instance.maxPlayers)
    end
    return nil
end

local function sortedWings(wings)
    local result = {}
    for _, wing in pairs(wings or {}) do
        table.insert(result, wing)
    end
    table.sort(result, function(a, b)
        local al = type(a.levelMin) == "number" and a.levelMin or 999
        local bl = type(b.levelMin) == "number" and b.levelMin or 999
        if al ~= bl then return al < bl end
        return tostring(a.name or "") < tostring(b.name or "")
    end)
    return result
end

local function localizedZoneName(instance)
    if instance and instance._mapID then
        local info = safeGetMapInfo(instance._mapID)
        if info and type(info.name) == "string" and info.name ~= "" then
            return info.name
        end
    end
    return instance and instance.zone or nil
end

local TOOLTIP_COLORS = {
    title = { 1.00, 0.82, 0.28 },
    meta = { 0.76, 0.78, 0.82 },
    label = { 0.68, 0.72, 0.78 },
    value = { 0.92, 0.92, 0.92 },
    body = { 0.86, 0.86, 0.86 },
    accent = { 0.35, 0.85, 1.00 },
    note = { 0.65, 0.65, 0.65 },
    action = { 0.45, 0.95, 0.45 },
    wing = { 0.78, 0.78, 0.78 },
    alliance = { 0.28, 0.56, 1.00 },
    horde = { 1.00, 0.30, 0.22 },
    contested = { 0.95, 0.73, 0.28 },
}

local function addTooltipLine(tooltip, text, color, wrap)
    if type(text) ~= "string" or text == "" then return end
    color = color or TOOLTIP_COLORS.value
    tooltip:AddLine(text, color[1], color[2], color[3], wrap == true)
end

local function addTooltipDetail(tooltip, label, value, valueColor)
    if type(label) ~= "string" or label == "" or value == nil or value == "" then return end
    local left = TOOLTIP_COLORS.label
    local right = valueColor or TOOLTIP_COLORS.value
    tooltip:AddDoubleLine(tostring(label), tostring(value), left[1], left[2], left[3], right[1], right[2], right[3])
end

local function addTooltipSection(tooltip, heading, body, color)
    if type(body) ~= "string" or body == "" then return end
    tooltip:AddLine(" ")
    addTooltipLine(tooltip, heading, TOOLTIP_COLORS.label, false)
    addTooltipLine(tooltip, body, color or TOOLTIP_COLORS.body, true)
end

local function territoryInfo(instance)
    if not instance or instance._kind ~= "Dungeon" then return nil, nil end

    if instance.territory == "Alliance" then
        return L("TERRITORY_ALLIANCE"), TOOLTIP_COLORS.alliance
    elseif instance.territory == "Horde" then
        return L("TERRITORY_HORDE"), TOOLTIP_COLORS.horde
    elseif instance.territory == "Contested" then
        return L("TERRITORY_CONTESTED"), TOOLTIP_COLORS.contested
    end

    return nil, nil
end

local function renderInstanceTooltip(tooltip, instance)
    addTooltipLine(tooltip, instance.name or instance._id or L("INSTANCE"), TOOLTIP_COLORS.title, false)

    local meta = {
        provenanceLabel(instance),
        instance._kind == "Raid" and L("RAID") or L("DUNGEON"),
    }
    local levels = levelText(instance)
    if levels then table.insert(meta, L("LEVEL_SHORT") .. " " .. levels) end
    local players = playerText(instance)
    if players then table.insert(meta, players) end
    addTooltipLine(tooltip, table.concat(meta, "  •  "), TOOLTIP_COLORS.meta, false)

    local territory, territoryColor = territoryInfo(instance)
    if territory then
        addTooltipDetail(tooltip, L("TERRITORY"), territory, territoryColor)
    end

    if type(instance.bossCount) == "number" then
        addTooltipDetail(tooltip, L("BOSSES_LABEL"), tostring(instance.bossCount))
    end

    if instance.zone then
        local zoneName = localizedZoneName(instance) or instance.zone
        local location = instance.location and (instance.location .. " - " .. zoneName) or zoneName
        addTooltipDetail(tooltip, L("LOCATION_LABEL"), location)
    end

    if db.showCoordinates and type(instance.x) == "number" and type(instance.y) == "number" then
        local coords = string.format("%.1f, %.1f", instance.x, instance.y)
        if instance.coordFallbackFromLegacy then
            coords = coords .. L("LEGACY_FALLBACK")
        end
        addTooltipDetail(tooltip, L("ENTRANCE_LABEL"), coords)
    end

    if db.showDescriptions then
        local description = localizedDescription(instance)
        if description then
            addTooltipSection(tooltip, L("OVERVIEW"), description, TOOLTIP_COLORS.body)
        end
    end

    if db.showDescriptions and instance.foreverStatus == "updated" then
        local change = localizedForeverChange(instance)
        if not change and instance._kind == "Dungeon" then
            change = optionalL("DUNGEON_LOOT_UPDATE")
        end
        if change then
            addTooltipSection(tooltip, L("FOREVER_CHANGES"), change, TOOLTIP_COLORS.accent)
        end
    end

    if instance.wings then
        local wings = sortedWings(instance.wings)
        if #wings > 0 then
            tooltip:AddLine(" ")
            addTooltipLine(tooltip, L("WINGS"), TOOLTIP_COLORS.label, false)
            for _, wing in ipairs(wings) do
                local wingName = wing.name or wing.fullName or L("WING")
                local wingLevels = levelText(wing)
                if wingLevels then
                    addTooltipDetail(tooltip, wingName, L("LEVEL_SHORT") .. " " .. wingLevels, TOOLTIP_COLORS.wing)
                else
                    addTooltipLine(tooltip, "  " .. wingName, TOOLTIP_COLORS.wing, false)
                end
            end
        end
    end

    if db.showNotes and type(instance.noteKey) == "string" then
        local note = optionalL(instance.noteKey)
        if note then
            addTooltipSection(tooltip, L("NOTES"), trim(note), TOOLTIP_COLORS.note)
        end
    end
end

function pluginHandler:OnEnter(uiMapID, coord)
    local node = getDisplayNode(uiMapID, coord)
    if not node then return end

    local tooltip = GameTooltip
    if not tooltip then return end

    if self.GetCenter and UIParent and UIParent.GetCenter then
        local selfX = select(1, self:GetCenter())
        local rootX = select(1, UIParent:GetCenter())
        if selfX and rootX and selfX > rootX then
            tooltip:SetOwner(self, "ANCHOR_LEFT")
        else
            tooltip:SetOwner(self, "ANCHOR_RIGHT")
        end
    else
        tooltip:SetOwner(self, "ANCHOR_RIGHT")
    end

    local shown = 0
    for _, instance in ipairs(node.instances) do
        if nodeVisible(instance) then
            shown = shown + 1
            if shown > 1 then
                tooltip:AddLine(" ")
            end
            renderInstanceTooltip(tooltip, instance)
        end
    end

    if shown > 0 and db.tomtom and TomTom and type(TomTom.AddWaypoint) == "function" then
        tooltip:AddLine(" ")
        addTooltipLine(tooltip, L("RIGHT_CLICK_TOMTOM"), TOOLTIP_COLORS.action, false)
    end

    tooltip:Show()
end

function pluginHandler:OnLeave()
    if GameTooltip then GameTooltip:Hide() end
end

function pluginHandler:OnClick(button, down, uiMapID, coord)
    if button ~= "RightButton" or not down or not db.tomtom or not TomTom or type(TomTom.AddWaypoint) ~= "function" then
        return
    end

    local node = getDisplayNode(uiMapID, coord)
    if not node then return end

    local waypointMapID = uiMapID
    local waypointCoord = coord

    -- Pins on the Azeroth map use pre-projected display coordinates. TomTom
    -- still needs the original zone/map coordinate.
    if uiMapID == WORLD_MAP_ID and node.sources then
        for _, source in ipairs(node.sources) do
            if nodeHasVisibleInstance(source.node) then
                waypointMapID = source.mapID
                waypointCoord = source.coord
                break
            end
        end
    end

    local x, y = HandyNotes:getXY(waypointCoord)
    local names = {}
    for _, instance in ipairs(node.instances) do
        if nodeVisible(instance) then
            table.insert(names, instance.name or instance._id or L("INSTANCE"))
        end
    end
    if #names == 0 then return end

    local key = tostring(waypointMapID) .. ":" .. tostring(waypointCoord)
    local old = waypointHandles[key]
    if old and type(TomTom.IsValidWaypoint) == "function" and TomTom:IsValidWaypoint(old) then
        return
    end

    waypointHandles[key] = TomTom:AddWaypoint(waypointMapID, x, y, {
        title = table.concat(names, " / "),
        persistent = false,
        minimap = true,
        world = true,
    })
end

local function notifyUpdate()
    HandyNotes:SendMessage("HandyNotes_NotifyUpdate", PLUGIN_NAME)
end

local function languageValues()
    return {
        enUS = L("LANGUAGE_ENGLISH"),
        ukUA = L("LANGUAGE_UKRAINIAN"),
    }
end

local function makeOptions()
    return {
        type = "group",
        name = ADDON_TITLE,
        desc = function() return L("ADDON_DESC") end,
        get = function(info) return db[info[#info]] end,
        set = function(info, value)
            db[info[#info]] = value
            notifyUpdate()
        end,
        args = {
            description = {
                type = "description",
                name = function() return L("DESCRIPTION") end,
                order = 1,
            },
            language = {
                type = "select",
                name = function() return L("LANGUAGE") end,
                desc = function() return L("LANGUAGE_DESC") end,
                values = languageValues,
                order = 2,
                get = function() return db.language == "ukUA" and "ukUA" or "enUS" end,
                set = function(_, value)
                    db.language = value
                    notifyUpdate()
                end,
            },
            zoneScale = {
                type = "range", name = function() return L("ZONE_ICON_SCALE") end, min = 0.2, max = 5, step = 0.1, order = 10,
            },
            zoneAlpha = {
                type = "range", name = function() return L("ZONE_ICON_OPACITY") end, min = 0, max = 1, step = 0.05, order = 11,
            },
            continentScale = {
                type = "range", name = function() return L("CONTINENT_ICON_SCALE") end, min = 0.2, max = 5, step = 0.1, order = 12,
            },
            continentAlpha = {
                type = "range", name = function() return L("CONTINENT_ICON_OPACITY") end, min = 0, max = 1, step = 0.05, order = 13,
            },
            showOnContinent = {
                type = "toggle", name = function() return L("SHOW_CONTINENT") end, order = 20,
            },
            showOnAzeroth = {
                type = "toggle", name = function() return L("SHOW_AZEROTH") end, order = 21,
                get = function() return db.showOnAzeroth end,
                set = function(_, value)
                    db.showOnAzeroth = value
                    worldNodesDirty = true
                    notifyUpdate()
                end,
            },
            tomtom = {
                type = "toggle", name = function() return L("TOMTOM_WAYPOINTS") end, order = 22,
            },
            showCoordinates = {
                type = "toggle", name = function() return L("SHOW_COORDINATES") end, order = 23,
            },
            showDescriptions = {
                type = "toggle", name = function() return L("SHOW_DESCRIPTIONS") end, order = 24,
            },
            showNotes = {
                type = "toggle", name = function() return L("SHOW_NOTES") end, order = 25,
            },
            filters = {
                type = "header", name = function() return L("FILTERS") end, order = 30,
            },
            showDungeons = {
                type = "toggle", name = function() return L("DUNGEONS") end, order = 31,
                get = function() return db.show.Dungeon end,
                set = function(_, value) db.show.Dungeon = value notifyUpdate() end,
            },
            showRaids = {
                type = "toggle", name = function() return L("RAIDS") end, order = 32,
                get = function() return db.show.Raid end,
                set = function(_, value) db.show.Raid = value notifyUpdate() end,
            },
            showClassic = {
                type = "toggle", name = function() return L("CLASSIC_INSTANCES") end, order = 33,
                get = function() return db.show.Classic end,
                set = function(_, value) db.show.Classic = value notifyUpdate() end,
            },
            showForever = {
                type = "toggle", name = function() return L("FOREVER_INSTANCES") end, order = 34,
                get = function() return db.show.Forever end,
                set = function(_, value) db.show.Forever = value notifyUpdate() end,
            },
        },
    }
end

local function initialize()
    if initialized then return end
    initialized = true

    applyLegacyFallback()
    rebuildNodes()

    local aceDB = AceDB:New("HandyNotes_ForeverInstancesDB", defaults, true)
    db = aceDB.profile

    -- v1.0.10 localization migration: only explicit language databases are
    -- supported. Existing "auto" profiles migrate to English, the default.
    if db.language ~= "ukUA" and db.language ~= "enUS" then
        db.language = "enUS"
    end

    HandyNotes:RegisterPluginDB(PLUGIN_NAME, pluginHandler, makeOptions())
    notifyUpdate()

    -- Small diagnostic surface for /dump without polluting normal gameplay.
    ns.GetUnresolved = function() return unresolved end
    ns.Rebuild = function()
        rebuildNodes()
        notifyUpdate()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        initialize()
    elseif event == "PLAYER_ENTERING_WORLD" and initialized and next(unresolved) then
        -- Beta map data may become available after entering the world.
        rebuildNodes()
        notifyUpdate()
    end
end)
