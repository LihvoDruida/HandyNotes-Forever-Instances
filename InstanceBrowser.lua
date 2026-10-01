-- Forever Instances - Blizzard-quest-style, taint-safe instance browser for WoW Forever
local addonName, ns = ...

local Database = ns.DB
if not Database then return end

local Browser = {}
ns.InstanceBrowser = Browser

local TAB_W, TAB_H = 42, 55
local TAB_ICON_SIZE = 20
local TAB_GAP = -3
local TAB_ICON_GOLD = { 1.00, 0.82, 0.00 }
local TAB_ICON_DIM = { 0.55, 0.45, 0.10 }
local ROW_HEIGHT = 44
local HEADER_HEIGHT = 28
local QUEST_HEADER_HEIGHT = 29
local DEFAULT_PANEL_WIDTH = 308

local panel
local tabFrame
local backTab
local initialized = false
local selectedIsOurs = false
local restoringBlizzardDisplayMode = false
local prevBlizzardDisplayMode
local activePinTarget
local activeTomTomWaypoint
local searchText = ""
local rowPool, headerPool = {}, {}
local rowCursor, headerCursor = 1, 1
local externalTabHooks = setmetatable({}, { __mode = "k" })
local systemModeHooks = setmetatable({}, { __mode = "k" })
local worldMapTabsHookedLibrary = nil

local function L(key, ...)
    if type(ns.L) == "function" then return ns.L(key, ...) end
    local locales = ns.Locales or {}
    local bucket = locales.enUS or {}
    local value = bucket[key] or key
    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, tostring(value), ...)
        if ok then return formatted end
    end
    return tostring(value)
end

local function GetProfile()
    if type(ns.GetProfile) == "function" then
        local profile = ns.GetProfile()
        if type(profile) == "table" then
            profile.browser = type(profile.browser) == "table" and profile.browser or {}
            profile.browser.collapsed = type(profile.browser.collapsed) == "table" and profile.browser.collapsed or {}
            return profile.browser
        end
    end
end

local sessionState = { collapsed = {} }
local function GetState()
    local state = GetProfile() or sessionState
    state.collapsed = type(state.collapsed) == "table" and state.collapsed or {}
    for _, continent in ipairs(Database.InstanceContinents or { "Eastern Kingdoms", "Kalimdor" }) do
        if state.collapsed[continent] == nil then state.collapsed[continent] = false end
    end
    return state
end

local function SafeAtlas(texture, atlas, useAtlasSize)
    if not texture or type(texture.SetAtlas) ~= "function" or not atlas then return false end
    return pcall(texture.SetAtlas, texture, atlas, useAtlasSize == true)
end

local function SetVertexColor(texture, color)
    if texture and color then texture:SetVertexColor(color[1], color[2], color[3], 1) end
end

local function SafeMapInfo(mapID)
    mapID = tonumber(mapID)
    if not mapID or not C_Map or type(C_Map.GetMapInfo) ~= "function" then return nil end
    local ok, info = pcall(C_Map.GetMapInfo, mapID)
    if ok and type(info) == "table" then return info end
end

local function GetCanonicalLocation(instance)
    if type(Database.GetCanonicalLocation) ~= "function" then return nil end
    return Database.GetCanonicalLocation(instance)
end

local function GetCoordinates(instance)
    local _, percentX, percentY = GetCanonicalLocation(instance)
    if type(percentX) == "number" and type(percentY) == "number" then
        return percentX / 100, percentY / 100
    end
end

local function GetContinent(instance)
    if type(Database.GetInstanceContinent) == "function" then
        local continent = Database.GetInstanceContinent(instance)
        if continent then return continent end
    end
    return L("OTHER") ~= "OTHER" and L("OTHER") or "Other"
end

local function GetEntries()
    if type(Database.GetBrowserEntries) == "function" then return Database.GetBrowserEntries() end
    return {}
end

local function EntryMatches(entry, query)
    if not query or query == "" then return true end
    local instance = entry.instance or {}
    local level = ""
    if instance.levelMin then
        level = tostring(instance.levelMin)
        if instance.levelMax and instance.levelMax ~= instance.levelMin then level = level .. "-" .. tostring(instance.levelMax) end
    end
    local haystack = table.concat({
        instance.name or "", instance.zone or "", instance.contentType or "", instance.era or "", level,
        table.concat(instance.aliases or {}, " "),
    }, " "):lower()
    return haystack:find(query, 1, true) ~= nil
end

local function SortEntries(a, b)
    local ai, bi = a.instance or {}, b.instance or {}
    local ak, bk = ai.contentType or "", bi.contentType or ""
    if ak ~= bk then return ak == "Dungeon" end
    local al, bl = tonumber(ai.levelMin) or 999, tonumber(bi.levelMin) or 999
    if al ~= bl then return al < bl end
    return tostring(ai.name or "") < tostring(bi.name or "")
end

local function GetContinentLabel(continent)
    if continent == "Eastern Kingdoms" then return L("BROWSER_CONTINENT_EASTERN_KINGDOMS") end
    if continent == "Kalimdor" then return L("BROWSER_CONTINENT_KALIMDOR") end
    return tostring(continent or "")
end

local function GetEntriesForContinent(continent)
    local result = {}
    local query = tostring(searchText or ""):lower()
    for _, entry in ipairs(GetEntries()) do
        local instance = entry.instance
        if GetContinent(instance) == continent and EntryMatches(entry, query) then
            result[#result + 1] = entry
        end
    end
    table.sort(result, SortEntries)
    return result
end

local function OpenZoneMap(mapID)
    if not SafeMapInfo(mapID) then return false end
    if C_Map and type(C_Map.OpenWorldMap) == "function" then
        local ok = pcall(C_Map.OpenWorldMap, mapID)
        if ok then return true end
    end
    return false
end

function Browser:ShowInstanceOnMap(instance)
    if type(instance) ~= "table" then return false end
    local mapID = GetCanonicalLocation(instance)
    local x, y = GetCoordinates(instance)
    if not mapID or not x or not y then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cffffd36bForever Instances:|r " .. L("BROWSER_LOCATION_UNAVAILABLE", instance.name or L("INSTANCE")))
        end
        return false
    end
    if not OpenZoneMap(mapID) then return false end

    local state = GetState()
    state.lastInstance = instance.name
    activePinTarget = { name = instance.name, mapID = mapID, x = x, y = y }
    self:RefreshList()
    return true
end

local function HasTomTom()
    return type(_G.TomTom) == "table" and type(_G.TomTom.AddWaypoint) == "function"
end

function Browser:NavigateTo(instance)
    if type(instance) ~= "table" then return false end
    local mapID = GetCanonicalLocation(instance)
    local x, y = GetCoordinates(instance)
    if not mapID or not x or not y then return self:ShowInstanceOnMap(instance) end
    if not HasTomTom() then return self:ShowInstanceOnMap(instance) end

    self:ShowInstanceOnMap(instance)
    if activeTomTomWaypoint and type(_G.TomTom.RemoveWaypoint) == "function" then
        pcall(_G.TomTom.RemoveWaypoint, _G.TomTom, activeTomTomWaypoint)
        activeTomTomWaypoint = nil
    end
    local ok, uid = pcall(_G.TomTom.AddWaypoint, _G.TomTom, mapID, x, y, {
        title = instance.name, source = addonName, persistent = false,
        minimap = true, world = true, crazy = true, silent = true,
    })
    if ok and uid then
        activeTomTomWaypoint = uid
        if type(_G.TomTom.SetCrazyArrow) == "function" then
            pcall(_G.TomTom.SetCrazyArrow, _G.TomTom, uid, 10, instance.name)
        end
    end
    return ok and uid ~= nil
end

local function SetTypeIconAppearance(row, instance)
    local atlas = instance.contentType == "Raid" and "Raid" or "Dungeon"
    if not SafeAtlas(row.typeIcon, atlas, false) then
        local root = "Interface\\AddOns\\" .. addonName .. "\\"
        row.typeIcon:SetTexture(root .. (instance.contentType == "Raid" and "raid.tga" or "dungeon.tga"))
        row.typeIcon:SetTexCoord(0, 1, 0, 1)
    end
end

local function ApplyRowSelectionVisual(row, selected)
    if not row then return end
    if selected then
        row.nameText:SetTextColor(1, 0.82, 0.12)
        row.metaText:SetTextColor(0.95, 0.84, 0.36)
        if row.LockHighlight then row:LockHighlight() end
    else
        row.nameText:SetTextColor(0.92, 0.90, 0.84)
        row.metaText:SetTextColor(0.62, 0.62, 0.58)
        if row.UnlockHighlight then row:UnlockHighlight() end
    end
end

local function ClearSearchFocus()
    if panel and panel.searchBox and panel.searchBox.HasFocus and panel.searchBox:HasFocus() then panel.searchBox:ClearFocus() end
end

local function AcquireHeader(parent)
    local header = headerPool[headerCursor]
    if not header then
        header = CreateFrame("Button", nil, parent)
        header:SetHeight(HEADER_HEIGHT)
        header:RegisterForClicks("LeftButtonDown")
        header:HookScript("OnMouseDown", ClearSearchFocus)

        header.bg = header:CreateTexture(nil, "BACKGROUND")
        header.bg:SetAllPoints()
        SafeAtlas(header.bg, "QuestLog-tab", false)

        header.hover = header:CreateTexture(nil, "ARTWORK", nil, -1)
        header.hover:SetAllPoints()
        SafeAtlas(header.hover, "QuestLog-tab", false)
        header.hover:SetBlendMode("ADD")
        header.hover:SetAlpha(0.40)
        header.hover:Hide()

        header.label = header:CreateFontString(nil, "OVERLAY", "Game15Font_Shadow")
        header.label:SetPoint("LEFT", 10, 0)
        header.label:SetPoint("RIGHT", -56, 0)
        header.label:SetJustifyH("LEFT")
        header.label:SetMaxLines(1)
        header.label:SetTextColor(0.60, 0.58, 0.55, 1)

        header.count = header:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        header.count:SetPoint("RIGHT", -34, 0)

        header.toggleBtn = CreateFrame("Button", nil, header)
        header.toggleBtn:SetSize(26, 25)
        header.toggleBtn:SetPoint("RIGHT", -8, 0)
        header.toggleBtn:SetFrameLevel(header:GetFrameLevel() + 2)
        header.toggleBtn:RegisterForClicks("LeftButtonDown")
        header.toggleBtn:HookScript("OnMouseDown", ClearSearchFocus)
        header.toggleBtn:SetHitRectInsets(-10, -10, -6, -6)

        header.toggleBtn.bg = header.toggleBtn:CreateTexture(nil, "ARTWORK")
        header.toggleBtn.bg:SetAllPoints()
        header.toggleBtn.bg:SetTexture(796424)
        header.toggleBtn.bg:Hide()
        header.toggleBtn.icon = header.toggleBtn:CreateTexture(nil, "OVERLAY")
        header.toggleBtn.icon:SetSize(18, 17)
        header.toggleBtn.icon:SetPoint("CENTER")
        SafeAtlas(header.toggleBtn.icon, "QuestLog-icon-shrink", false)
        header.toggleBtn:SetHighlightTexture(130757)

        header.toggleBtn:SetScript("OnEnter", function(self)
            self.bg:Show(); header.hover:Show()
        end)
        header.toggleBtn:SetScript("OnLeave", function(self)
            self.bg:Hide(); if not header:IsMouseOver() then header.hover:Hide() end
        end)
        header.toggleBtn:SetScript("OnClick", function()
            if not header.continent then return end
            local state = GetState()
            state.collapsed[header.continent] = not state.collapsed[header.continent]
            Browser:RefreshList()
        end)
        header:SetScript("OnClick", function(self)
            if self.toggleBtn and self.toggleBtn:IsMouseOver() then return end
            if not self.continent then return end
            local state = GetState()
            state.collapsed[self.continent] = not state.collapsed[self.continent]
            Browser:RefreshList()
        end)
        header:SetScript("OnEnter", function(self)
            self.hover:Show(); self.label:SetTextColor(0.90, 0.88, 0.85, 1)
        end)
        header:SetScript("OnLeave", function(self)
            if not self.toggleBtn:IsMouseOver() then self.hover:Hide() end
            self.label:SetTextColor(0.60, 0.58, 0.55, 1)
        end)
        headerPool[#headerPool + 1] = header
    else
        header:SetParent(parent)
    end
    headerCursor = headerCursor + 1
    header:Show()
    return header
end

local function SetNavButtonAppearance(button, instance)
    local mapID = GetCanonicalLocation(instance)
    local x, y = GetCoordinates(instance)
    local navigable = mapID ~= nil and x ~= nil and y ~= nil
    button.navigable = navigable
    button.tomtom = navigable and HasTomTom()
    button:SetAlpha(navigable and 1 or 0.42)
    button.icon:SetDesaturated(not navigable)
    if button.tomtom then
        if not SafeAtlas(button.icon, "poi-traveldirections-arrow", false) then button.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01") end
        button.icon:SetSize(14, 18)
    elseif navigable then
        if not SafeAtlas(button.icon, "Waypoint-MapPin-Untracked", false) then button.icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01") end
        button.icon:SetSize(19, 22)
    else
        if not SafeAtlas(button.icon, "QuestSharing-QuestLog-Padlock", false) then button.icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up") end
        button.icon:SetSize(17, 17)
    end
end

local function AcquireRow(parent)
    local row = rowPool[rowCursor]
    if not row then
        row = CreateFrame("Button", nil, parent)
        row:SetHeight(ROW_HEIGHT)
        row:RegisterForClicks("LeftButtonDown")
        row:EnableMouse(true)
        row:HookScript("OnMouseDown", ClearSearchFocus)
        if row.SetHighlightAtlas then
            row:SetHighlightAtlas("QuestLog-quest-glow-yellow")
            local hl = row:GetHighlightTexture()
            if hl then hl:SetBlendMode("ADD"); hl:SetAllPoints(row) end
        end

        row.typeIcon = row:CreateTexture(nil, "ARTWORK")
        row.typeIcon:SetSize(24, 24)
        row.typeIcon:SetPoint("LEFT", row, "LEFT", 7, 0)

        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.nameText:SetPoint("TOPLEFT", row, "TOPLEFT", 40, -6)
        row.nameText:SetJustifyH("LEFT")
        row.nameText:SetMaxLines(1)

        row.metaText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.metaText:SetPoint("TOPLEFT", row.nameText, "BOTTOMLEFT", 0, -3)
        row.metaText:SetJustifyH("LEFT")
        row.metaText:SetMaxLines(1)

        row.nav = CreateFrame("Button", nil, row)
        row.nav:SetSize(22, 22)
        row.nav:SetPoint("RIGHT", -3, 0)
        row.nav:RegisterForClicks("LeftButtonDown")
        row.nav:HookScript("OnMouseDown", ClearSearchFocus)
        row.nameText:SetPoint("RIGHT", row.nav, "LEFT", -5, 0)
        row.metaText:SetPoint("RIGHT", row.nav, "LEFT", -5, 0)
        row.nav.highlight = row.nav:CreateTexture(nil, "HIGHLIGHT")
        row.nav.highlight:SetAllPoints()
        if not SafeAtlas(row.nav.highlight, "UI-QuestPoi-OuterGlow", false) then row.nav.highlight:SetColorTexture(1, 0.78, 0.15, 0.20) end
        row.nav.icon = row.nav:CreateTexture(nil, "ARTWORK")
        row.nav.icon:SetPoint("CENTER")
        row.nav.icon:SetVertexColor(1, 0.82, 0.20)
        row.nav:SetScript("OnClick", function(self)
            local parentRow = self:GetParent()
            if not parentRow or not parentRow.instance or not self.navigable then return end
            if self.tomtom then Browser:NavigateTo(parentRow.instance) else Browser:ShowInstanceOnMap(parentRow.instance) end
        end)
        row.nav:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            if not self.navigable then GameTooltip:SetText(L("BROWSER_LOCATION_TBA"))
            elseif self.tomtom then GameTooltip:SetText(L("BROWSER_NAVIGATE_TOMTOM"))
            else GameTooltip:SetText(L("BROWSER_SHOW_ON_MAP")) end
            GameTooltip:Show()
        end)
        row.nav:SetScript("OnLeave", GameTooltip_Hide)

        row.separator = row:CreateTexture(nil, "ARTWORK")
        row.separator:SetHeight(1)
        row.separator:SetPoint("BOTTOMLEFT", 40, 0)
        row.separator:SetPoint("BOTTOMRIGHT", -4, 0)
        row.separator:SetColorTexture(0.48, 0.40, 0.24, 0.22)

        row:SetScript("OnClick", function(self)
            if self.nav and self.nav.IsMouseOver and self.nav:IsMouseOver() then return end
            if self.instance then Browser:ShowInstanceOnMap(self.instance) end
        end)
        row:SetScript("OnEnter", function(self)
            local state = GetState()
            if self.instance and state.lastInstance ~= self.instance.name then
                self.nameText:SetTextColor(1, 0.84, 0.22); self.metaText:SetTextColor(0.86, 0.78, 0.36)
            end
            if self.instance then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.instance.name or L("INSTANCE"))
                GameTooltip:AddLine(L("BROWSER_ROW_CLICK"), 1, 0.82, 0.20, true)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            local state = GetState()
            ApplyRowSelectionVisual(self, self.instance and state.lastInstance == self.instance.name)
            GameTooltip:Hide()
        end)
        rowPool[#rowPool + 1] = row
    else
        row:SetParent(parent)
    end
    rowCursor = rowCursor + 1
    row:Show()
    return row
end

local function ResetPools()
    rowCursor, headerCursor = 1, 1
    for _, row in ipairs(rowPool) do row:Hide() end
    for _, header in ipairs(headerPool) do header:Hide() end
end

local function ReadSearchBoxText()
    if panel and panel.searchBox and type(panel.searchBox.GetText) == "function" then
        local ok, value = pcall(panel.searchBox.GetText, panel.searchBox)
        if ok then return tostring(value or "") end
    end
    return tostring(searchText or "")
end

function Browser:SetSearchText(value, syncEditBox)
    value = tostring(value or "")
    searchText = value
    if syncEditBox ~= false and panel and panel.searchBox and panel.searchBox:GetText() ~= value then panel.searchBox:SetText(value) end
    self:RefreshList()
end

function Browser:RefreshList()
    if not panel or not panel.scrollChild then return end
    searchText = ReadSearchBoxText()
    ResetPools()

    local child = panel.scrollChild
    local width = math.max(250, panel.scrollFrame:GetWidth() or DEFAULT_PANEL_WIDTH)
    child:SetWidth(width)
    local y, visibleCount = -2, 0
    local state = GetState()
    local searching = searchText ~= ""

    for _, continent in ipairs(Database.InstanceContinents or { "Eastern Kingdoms", "Kalimdor" }) do
        local entries = GetEntriesForContinent(continent)
        if not searching or #entries > 0 then
            local header = AcquireHeader(child)
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", child, "TOPLEFT", 0, y)
            header:SetPoint("RIGHT", child, "RIGHT", 0, 0)
            header.continent = continent
            header.label:SetText(GetContinentLabel(continent))
            header.count:SetText(tostring(#entries))
            local collapsed = (not searching) and state.collapsed[continent]
            SafeAtlas(header.toggleBtn.icon, collapsed and "QuestLog-icon-expand" or "QuestLog-icon-shrink", false)
            header.toggleBtn:SetAlpha(searching and 0.35 or 1)
            y = y - HEADER_HEIGHT

            if not collapsed then
                for _, entry in ipairs(entries) do
                    local instance = entry.instance
                    local row = AcquireRow(child)
                    row:ClearAllPoints()
                    row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, y)
                    row:SetPoint("RIGHT", child, "RIGHT", 0, 0)
                    row.instance = instance
                    SetTypeIconAppearance(row, instance)
                    row.nameText:SetText(instance.name or entry.id)
                    ApplyRowSelectionVisual(row, state.lastInstance == instance.name)

                    local typeText = instance.contentType == "Raid" and L("RAID") or L("DUNGEON")
                    local parts = { typeText }
                    if instance.levelMin then
                        if instance.levelMax and instance.levelMax ~= instance.levelMin then
                            parts[#parts + 1] = string.format("%s %d-%d", L("LEVEL_SHORT"), instance.levelMin, instance.levelMax)
                        else
                            parts[#parts + 1] = string.format("%s %d", L("LEVEL_SHORT"), instance.levelMin)
                        end
                    end
                    if instance.zone and instance.zone ~= "" then parts[#parts + 1] = instance.zone end
                    row.metaText:SetText(table.concat(parts, "  •  "))
                    SetNavButtonAppearance(row.nav, instance)
                    y = y - ROW_HEIGHT
                    visibleCount = visibleCount + 1
                end
            end
        end
    end

    child:SetHeight(math.max(1, -y + 2))
    if panel.noResults then panel.noResults:SetShown(searching and visibleCount == 0) end
    local maxScroll = math.max(0, child:GetHeight() - (panel.scrollFrame:GetHeight() or 0))
    if (panel.scrollFrame:GetVerticalScroll() or 0) > maxScroll then panel.scrollFrame:SetVerticalScroll(maxScroll) end
    if panel.SyncScrollBar then panel.SyncScrollBar() end
end

local function FindAtlasTexture(frame, atlas)
    if not frame or not frame.GetRegions then return nil end
    for i = 1, frame:GetNumRegions() do
        local region = select(i, frame:GetRegions())
        if region and region.GetAtlas and region.GetObjectType and region:GetObjectType() == "Texture"
           and region:GetAtlas() == atlas then
            return region
        end
    end
    return nil
end

local function IsQuestStyleSideTab(child, qmf)
    if not child or child == tabFrame or child == backTab then return false end
    if child.GetParent and child:GetParent() ~= qmf then return false end
    if not child.IsShown or not child:IsShown() then return false end
    if not FindAtlasTexture(child, "QuestLog-tab-side") then return false end
    return true
end

local function GetVisibleQuestStyleSideTabs(qmf)
    local tabs = {}
    if not qmf or not qmf.GetChildren then return tabs end
    for _, child in ipairs({ qmf:GetChildren() }) do
        if IsQuestStyleSideTab(child, qmf) then tabs[#tabs + 1] = child end
    end
    return tabs
end

local function IsNativeQuestMapTab(tab, qmf)
    return qmf and (tab == qmf.QuestsTab or tab == qmf.EventsTab or tab == qmf.MapLegendTab)
end

local function IsNativeDisplayMode(qmf, displayMode)
    if not qmf or displayMode == nil then return false end
    local tabs = { qmf.QuestsTab, qmf.EventsTab, qmf.MapLegendTab }
    for _, tab in ipairs(tabs) do
        if tab and tab.displayMode ~= nil and tab.displayMode == displayMode then return true end
    end
    return false
end

local function FindSideTabIcon(tab)
    if not tab then return nil end
    if tab.Icon and tab.Icon.GetObjectType and tab.Icon:GetObjectType() == "Texture" then return tab.Icon end
    if not tab.GetRegions then return nil end
    for i = 1, tab:GetNumRegions() do
        local region = select(i, tab:GetRegions())
        if region and region.GetObjectType and region:GetObjectType() == "Texture" then
            local atlas = region.GetAtlas and region:GetAtlas()
            local low = atlas and atlas:lower() or ""
            if not low:find("questlog%-tab", 1, false) and not low:find("glow", 1, true) then
                return region
            end
        end
    end
    return nil
end

local function GetSideTabIconIdentity(tab)
    local icon = FindSideTabIcon(tab)
    if not icon then return nil end
    local atlas = icon.GetAtlas and icon:GetAtlas()
    if atlas then return "atlas:" .. tostring(atlas) end
    local texture = icon.GetTexture and icon:GetTexture()
    if texture then return "texture:" .. tostring(texture) end
    return nil
end

local function AddIconIdentity(set, kind, value)
    if value == nil or value == "" then return end
    set[tostring(kind) .. ":" .. tostring(value)] = true
end

-- Forever may keep Blizzard's real Quests tab hidden while another addon draws
-- a visual return-to-quests tab.  The copied glyph can be either the active or
-- inactive Blizzard atlas depending on load order, so comparing only the
-- QuestsTab's *current* icon is not stable.  Build the identity set from the
-- current icon plus Blizzard's active/inactive atlas metadata.
local function GetQuestTabIconIdentities(qmf)
    local set = {}
    local questsTab = qmf and qmf.QuestsTab
    if not questsTab then return set end

    AddIconIdentity(set, "atlas", questsTab.activeAtlas)
    AddIconIdentity(set, "atlas", questsTab.inactiveAtlas)

    local icon = FindSideTabIcon(questsTab)
    if icon then
        AddIconIdentity(set, "atlas", icon.GetAtlas and icon:GetAtlas())
        AddIconIdentity(set, "texture", icon.GetTexture and icon:GetTexture())
    end
    return set
end

local function IsFallbackQuestTab(tab, qmf)
    if not tab or not qmf or tab.displayMode ~= nil or IsNativeQuestMapTab(tab, qmf) then return false end
    local tabIdentity = GetSideTabIconIdentity(tab)
    if not tabIdentity then return false end
    return GetQuestTabIconIdentities(qmf)[tabIdentity] == true
end

local function CountExternalSelectedGlows(qmf)
    if not qmf then return 0 end
    local count = 0
    for _, other in ipairs(GetVisibleQuestStyleSideTabs(qmf)) do
        if not IsNativeQuestMapTab(other, qmf) then
            local glow = FindAtlasTexture(other, "QuestLog-Tab-side-Glow-Select")
            if glow and glow:IsShown() then count = count + 1 end
        end
    end
    return count
end

local function RefreshSelectGlows()
    local qmf = _G.QuestMapFrame
    if not qmf then return end
    local function setGlow(tab, shown)
        if not tab then return end
        local glow = tab._fiSelectGlow or FindAtlasTexture(tab, "QuestLog-Tab-side-Glow-Select")
        if glow then
            tab._fiSelectGlow = glow
            glow:SetShown(shown)
        end
    end

    -- Native Blizzard tabs are updated by QuestMapFrame:SetDisplayMode. While our
    -- detached surface is selected, hide their checked glow so only one tab looks
    -- active. The native state is restored through SetDisplayMode when we leave.
    if selectedIsOurs then
        setGlow(qmf.QuestsTab, false)
        setGlow(qmf.MapLegendTab, false)
        setGlow(qmf.EventsTab, false)
        setGlow(tabFrame, true)
    else
        setGlow(tabFrame, false)
    end

    -- A detached fallback Quests tab is semantically the native Quests state,
    -- even when it was created by another addon.  While Forever Instances owns
    -- the sidebar it must not remain selected, otherwise two side tabs are gold
    -- at once.  We only arbitrate tabs positively identified as a Quests
    -- fallback; arbitrary third-party custom tabs keep full ownership of their
    -- own visuals.  Once our panel is released, the fallback is selected only
    -- when Blizzard itself is actually in the Quests display mode.
    local questsMode = qmf.QuestsTab and qmf.QuestsTab.displayMode or nil
    local nativeQuestsActive = not selectedIsOurs and questsMode ~= nil and qmf.displayMode == questsMode
    for _, other in ipairs(GetVisibleQuestStyleSideTabs(qmf)) do
        if IsFallbackQuestTab(other, qmf) then
            setGlow(other, nativeQuestsActive)
            SetVertexColor(FindSideTabIcon(other), nativeQuestsActive and TAB_ICON_GOLD or TAB_ICON_DIM)
        end
    end

    if backTab then
        setGlow(backTab, nativeQuestsActive)
        SetVertexColor(backTab._fiIcon, nativeQuestsActive and TAB_ICON_GOLD or TAB_ICON_DIM)
    end
    SetVertexColor(tabFrame and tabFrame._fiIcon, selectedIsOurs and TAB_ICON_GOLD or TAB_ICON_DIM)
end

-- Deliberately mirrors the visible construction used by the working map-search
-- tab: a plain sibling frame using Blizzard's quest-log side-tab atlases.  We
-- intentionally do NOT assign displayMode to our tab.  Third-party tab managers
-- using the same display-mode convention therefore never try to re-anchor themselves below us,
-- which prevents mutual anchor loops; we always place ourselves after their
-- settled visible tab chain instead.
local function CreateSideTab(qmf)
    if tabFrame or not qmf then return end
    local ref = qmf.MapLegendTab or qmf.EventsTab or qmf.QuestsTab
    if not ref then return end
    local w, h = ref:GetSize()
    if not w or w == 0 then w, h = TAB_W, TAB_H end

    local tab = CreateFrame("Frame", "ForeverInstancesMapBrowserTab", qmf)
    tab:SetSize(w, h)
    tab:SetFrameStrata("HIGH")
    tab:SetFrameLevel(ref:GetFrameLevel())
    tab:EnableMouse(true)
    tab._fiQuestStyleTab = true

    local bg = tab:CreateTexture(nil, "BACKGROUND")
    SafeAtlas(bg, "QuestLog-tab-side", true)
    bg:SetPoint("CENTER", tab, "CENTER", 0, 0)
    tab._fiBackground = bg

    local icon = tab:CreateTexture(nil, "ARTWORK")
    if not SafeAtlas(icon, "Dungeon", false) then
        icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\dungeon.tga")
        icon:SetTexCoord(0, 1, 0, 1)
    end
    icon:SetSize(TAB_ICON_SIZE, TAB_ICON_SIZE)
    icon:SetPoint("CENTER", tab, "CENTER", 0, 0)
    SetVertexColor(icon, TAB_ICON_DIM)
    tab._fiIcon = icon
    tab._fiUsesBlizzardDungeonAtlas = icon.GetAtlas and icon:GetAtlas() == "Dungeon" or false

    local selectGlow = tab:CreateTexture(nil, "OVERLAY")
    SafeAtlas(selectGlow, "QuestLog-Tab-side-Glow-Select", true)
    selectGlow:SetPoint("CENTER", bg, "CENTER", 0, 0)
    selectGlow:Hide()
    tab._fiSelectGlow = selectGlow

    local hoverGlow = tab:CreateTexture(nil, "HIGHLIGHT")
    SafeAtlas(hoverGlow, "QuestLog-Tab-side-Glow-hover", true)
    hoverGlow:SetPoint("CENTER", bg, "CENTER", 0, 0)

    tab:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" and self._fiIcon then self._fiIcon:SetPoint("CENTER", -1, -1) end
    end)
    tab:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            if self._fiIcon then self._fiIcon:SetPoint("CENTER", 0, 0) end
            if SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB and PlaySound then
                pcall(PlaySound, SOUNDKIT.IG_CHARACTER_INFO_TAB)
            end
            Browser:Show()
        end
    end)
    tab:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L("BROWSER_TITLE"))
        GameTooltip:AddLine(L("BROWSER_TAB_DESC"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    tab:SetScript("OnLeave", GameTooltip_Hide)

    tabFrame = tab
end

local function CreateBackTab(qmf)
    local tab = CreateFrame("Frame", "ForeverInstancesMapQuestsTab", qmf)
    local refW, refH = qmf.QuestsTab:GetSize()
    if not refW or refW == 0 then refW, refH = TAB_W, TAB_H end
    tab:SetSize(refW, refH)
    tab:SetFrameStrata("HIGH")
    tab:SetFrameLevel(qmf.QuestsTab:GetFrameLevel())
    tab:EnableMouse(true)
    tab._fiQuestStyleTab = true

    local bg = tab:CreateTexture(nil, "BACKGROUND")
    SafeAtlas(bg, "QuestLog-tab-side", true)
    bg:SetPoint("CENTER", tab, "CENTER", 0, 0)

    local icon = tab:CreateTexture(nil, "ARTWORK")
    local copied = false
    local src = qmf.QuestsTab.Icon
    if not src then
        for i = 1, qmf.QuestsTab:GetNumRegions() do
            local region = select(i, qmf.QuestsTab:GetRegions())
            if region and region.GetObjectType and region:GetObjectType() == "Texture" then
                local atlas = region.GetAtlas and region:GetAtlas()
                local low = atlas and atlas:lower() or ""
                if atlas and not low:find("tab", 1, true) and not low:find("glow", 1, true) then
                    src = region
                    break
                end
            end
        end
    end
    if src then
        local atlas = src.GetAtlas and src:GetAtlas()
        if atlas then SafeAtlas(icon, atlas, false); copied = true
        elseif src.GetTexture and src:GetTexture() then
            icon:SetTexture(src:GetTexture())
            if src.GetTexCoord then icon:SetTexCoord(src:GetTexCoord()) end
            copied = true
        end
    end
    if not copied then icon:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon") end
    icon:SetSize(TAB_ICON_SIZE + 4, TAB_ICON_SIZE + 4)
    icon:SetPoint("CENTER", tab, "CENTER", 0, 0)
    SetVertexColor(icon, TAB_ICON_GOLD)
    tab._fiIcon = icon

    local selectGlow = tab:CreateTexture(nil, "OVERLAY")
    SafeAtlas(selectGlow, "QuestLog-Tab-side-Glow-Select", true)
    selectGlow:SetPoint("CENTER", bg, "CENTER", 0, 0)
    selectGlow:Show()
    tab._fiSelectGlow = selectGlow

    local hoverGlow = tab:CreateTexture(nil, "HIGHLIGHT")
    SafeAtlas(hoverGlow, "QuestLog-Tab-side-Glow-hover", true)
    hoverGlow:SetPoint("CENTER", bg, "CENTER", 0, 0)

    tab:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            if SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB and PlaySound then
                pcall(PlaySound, SOUNDKIT.IG_CHARACTER_INFO_TAB)
            end
            Browser:Hide(true)
            RefreshSelectGlows()
        end
    end)
    tab:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(_G.QUESTLOG_BUTTON or _G.QUESTS_LABEL or "Quests")
        GameTooltip:Show()
    end)
    tab:SetScript("OnLeave", GameTooltip_Hide)
    return tab
end

-- The content surface follows the proven quest-log map-search geometry exactly:
-- sibling outer frame on ContentsAnchor, 29px search header, -22 right inset,
-- Blizzard paper/border, plain ScrollFrame plus MinimalScrollBar.
local function CreatePanel(qmf)
    if panel or not qmf then return end
    local anchor = qmf.ContentsAnchor or qmf.QuestsFrame or qmf

    local outer = CreateFrame("Frame", "ForeverInstancesMapBrowserOuter", qmf)
    outer:SetAllPoints(anchor)
    outer:EnableMouse(false)

    local p = CreateFrame("Frame", "ForeverInstancesMapBrowserPanel", outer)
    p:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, -QUEST_HEADER_HEIGHT)
    p:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -22, 0)
    p:EnableMouse(true)
    p.outer = outer
    outer:Hide()

    local paper = p:CreateTexture(nil, "BACKGROUND", nil, -1)
    if not SafeAtlas(paper, "QuestLog-main-background", true) then paper:SetTexture("Interface\\QuestFrame\\QuestBG") end
    paper:SetAllPoints(p)
    p.paper = paper

    local okBorder, border = pcall(CreateFrame, "Frame", nil, p, "QuestLogBorderFrameTemplate")
    if okBorder and border then
        border:SetFrameLevel(p:GetFrameLevel() + 2)
        border:EnableMouse(false)
        p.border = border
    end

    local searchBox = CreateFrame("EditBox", "ForeverInstancesMapBrowserSearchBox", outer, "SearchBoxTemplate")
    searchBox:ClearAllPoints()
    searchBox:SetHeight(20)
    searchBox:SetPoint("TOPLEFT", outer, "TOPLEFT", 6, -2)
    searchBox:SetPoint("RIGHT", outer, "RIGHT", -7, 0)
    p.searchBox = searchBox

    p.AlignToBlizzardSearch = function()
        local qsb = _G.QuestScrollFrame and QuestScrollFrame.SearchBox
        if not qsb then return end
        local n = qsb:GetNumPoints() or 0
        if n == 0 then return end
        searchBox:ClearAllPoints()
        for i = 1, n do
            local point, relTo, relPoint, x, y = qsb:GetPoint(i)
            if point then searchBox:SetPoint(point, relTo, relPoint, x, y) end
        end
        local w, h = qsb:GetSize()
        if w and w > 0 and h and h > 0 then searchBox:SetSize(w, h) end
    end
    p.MeasureBlizzardSearch = p.AlignToBlizzardSearch

    searchBox:SetScript("OnTextChanged", function(self)
        if SearchBoxTemplate_OnTextChanged then pcall(SearchBoxTemplate_OnTextChanged, self) end
        searchText = tostring(self:GetText() or "")
        Browser:RefreshList()
    end)

    local scrollFrame = CreateFrame("ScrollFrame", "ForeverInstancesMapBrowserScrollFrame", p)
    scrollFrame:SetPoint("TOPLEFT", p, "TOPLEFT", 4, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -4, 4)
    scrollFrame:EnableMouseWheel(true)
    p.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)
    scrollFrame:HookScript("OnSizeChanged", function(_, w) scrollChild:SetWidth(w) end)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(0, (scrollChild:GetHeight() or 0) - (self:GetHeight() or 0))
        local target = (self:GetVerticalScroll() or 0) - delta * 24
        if target < 0 then target = 0 end
        if target > maxScroll then target = maxScroll end
        self:SetVerticalScroll(target)
    end)
    p.scrollChild = scrollChild

    local okBar, scrollBar = pcall(CreateFrame, "EventFrame", nil, p, "MinimalScrollBar")
    if okBar and scrollBar then
        scrollBar:SetFrameStrata("HIGH")
        scrollBar:SetPoint("TOPLEFT", p, "TOPRIGHT", 8, 2)
        scrollBar:SetPoint("BOTTOMLEFT", p, "BOTTOMRIGHT", 8, -4)
        p.scrollBar = scrollBar

        local function SyncScrollBar()
            local contentH, viewH = scrollChild:GetHeight() or 0, scrollFrame:GetHeight() or 0
            if scrollBar.SetVisibleExtentPercentage then
                scrollBar:SetVisibleExtentPercentage(contentH > 0 and math.min(1, viewH / contentH) or 1)
            end
            if scrollBar.SetScrollPercentage then
                local maxScroll = math.max(1, contentH - viewH)
                scrollBar:SetScrollPercentage((scrollFrame:GetVerticalScroll() or 0) / maxScroll)
            end
        end
        if scrollBar.RegisterCallback and scrollBar.Event and scrollBar.Event.OnScroll then
            scrollBar:RegisterCallback(scrollBar.Event.OnScroll, function(_, pct)
                local maxScroll = math.max(0, (scrollChild:GetHeight() or 0) - (scrollFrame:GetHeight() or 0))
                scrollFrame:SetVerticalScroll(pct * maxScroll)
            end, p)
        end
        scrollFrame:HookScript("OnSizeChanged", SyncScrollBar)
        scrollFrame:HookScript("OnVerticalScroll", SyncScrollBar)
        if hooksecurefunc then hooksecurefunc(scrollChild, "SetHeight", SyncScrollBar) end
        p.SyncScrollBar = SyncScrollBar
    end

    local emptyMsg = p:CreateFontString(nil, "OVERLAY", "SystemFont_Med3")
    emptyMsg:SetPoint("TOP", scrollFrame, "TOP", 0, -30)
    emptyMsg:SetWidth(250)
    emptyMsg:SetJustifyH("CENTER")
    emptyMsg:SetText(_G.QUEST_LOG_NO_RESULTS or L("BROWSER_NO_RESULTS"))
    emptyMsg:Hide()
    p.noResults = emptyMsg

    outer:HookScript("OnSizeChanged", function() Browser:SyncPanelGeometry() end)
    panel = p
end

function Browser:SyncPanelGeometry()
    if not panel then return false end
    if panel.AlignToBlizzardSearch then panel.AlignToBlizzardSearch() end
    if panel.scrollFrame and panel.scrollChild then
        local w = panel.scrollFrame:GetWidth() or 0
        if w > 0 then panel.scrollChild:SetWidth(w) end
    end
    if panel.SyncScrollBar then panel.SyncScrollBar() end
    return true
end

local function IsVisibleManagedSideTab(child, qmf)
    if not IsQuestStyleSideTab(child, qmf) then return false end
    if child.displayMode == nil then return false end
    local hasEnter = child.OnEnter ~= nil or (child.GetScript and child:GetScript("OnEnter") ~= nil)
    return hasEnter == true
end

local function GetVisibleManagedSideTabs(qmf)
    local tabs = {}
    if not qmf or not qmf.GetChildren then return tabs end
    for _, child in ipairs({ qmf:GetChildren() }) do
        if IsVisibleManagedSideTab(child, qmf) then tabs[#tabs + 1] = child end
    end
    return tabs
end

local function HookExternalTab(tab)
    local qmf = _G.QuestMapFrame
    if not tab or tab == tabFrame or tab == backTab or IsNativeQuestMapTab(tab, qmf)
       or externalTabHooks[tab] or not tab.HookScript then
        return
    end
    externalTabHooks[tab] = true

    local function HandoffAfterDestination()
        if not selectedIsOurs then return end
        -- IMPORTANT: run only AFTER the destination tab's own mouse-up handler.
        -- The reference MapSearch addon documents the exact failure caused by
        -- restoring/hiding during the first half of a tab click: the destination
        -- can end up with qmf.displayMode=nil and a blank gray sidebar until a
        -- second click.  A post-click handoff lets the destination establish its
        -- own panel first, then releases ours without painting Blizzard content
        -- over it.  Only a passive Quests-return tab requests native restoration.
        Browser:Hide(IsFallbackQuestTab(tab, _G.QuestMapFrame))
    end

    pcall(tab.HookScript, tab, "OnMouseUp", function(_, button)
        if button == "LeftButton" then HandoffAfterDestination() end
    end)
end

local tabAnchorName = nil
local tabAnchorMode = "managed-chain"
local function PlaceTab()
    if not tabFrame then return false end
    local qmf = _G.QuestMapFrame
    if not qmf then return false end

    local lowest, lowestBottom
    for _, child in ipairs(GetVisibleQuestStyleSideTabs(qmf)) do
        HookExternalTab(child)
    end
    for _, child in ipairs(GetVisibleManagedSideTabs(qmf)) do
        local bottom = child:GetBottom()
        if bottom and (not lowestBottom or bottom < lowestBottom) then
            lowest, lowestBottom = child, bottom
        end
    end

    -- If another addon already drew a generic fallback side-tab (for example a
    -- Quests return tab on Forever), never create a duplicate one. We only use
    -- it as a visual stack anchor; its click is handled by the generic handoff
    -- hook above and Blizzard still owns the actual quest display mode.
    local passiveLowest, passiveLowestBottom
    if not lowest then
        for _, child in ipairs(GetVisibleQuestStyleSideTabs(qmf)) do
            if child.displayMode == nil then
                local bottom = child:GetBottom()
                if bottom and (not passiveLowestBottom or bottom < passiveLowestBottom) then
                    passiveLowest, passiveLowestBottom = child, bottom
                end
            end
        end
    end

    tabFrame:ClearAllPoints()
    if backTab and (lowest or passiveLowest) then backTab:Hide() end
    if lowest then
        tabFrame:SetPoint("TOPLEFT", lowest, "BOTTOMLEFT", 0, TAB_GAP)
        tabAnchorMode = "managed-chain"
        tabAnchorName = lowest.GetName and lowest:GetName() or "anonymous"
    elseif passiveLowest then
        tabFrame:SetPoint("TOPLEFT", passiveLowest, "BOTTOMLEFT", 0, TAB_GAP)
        tabAnchorMode = "passive-side-tab"
        tabAnchorName = passiveLowest.GetName and (passiveLowest:GetName() or "anonymous") or "anonymous"
    elseif qmf.QuestsTab and not qmf.QuestsTab:IsShown() then
        backTab = backTab or CreateBackTab(qmf)
        backTab:ClearAllPoints()
        backTab:SetPoint("TOPLEFT", qmf, "TOPRIGHT", -9, -28)
        backTab:Show()
        tabFrame:SetPoint("TOPLEFT", backTab, "BOTTOMLEFT", 0, TAB_GAP)
        tabAnchorMode = "fallback-quest-tab"
        tabAnchorName = backTab:GetName() or "ForeverInstancesMapQuestsTab"
    elseif qmf.MapLegendTab then
        tabFrame:SetPoint("TOPLEFT", qmf.MapLegendTab, "BOTTOMLEFT", 0, TAB_GAP)
        tabAnchorMode = "stock-maplegend"
        tabAnchorName = qmf.MapLegendTab:GetName() or "MapLegendTab"
    else
        tabFrame:SetPoint("LEFT", qmf, "RIGHT", 0, 0)
        tabAnchorMode = "frame-edge"
        tabAnchorName = qmf:GetName() or "QuestMapFrame"
    end

    tabFrame:Show()
    return true
end

function Browser:PlaceTab()
    return PlaceTab()
end

local function GetFrameRect(frame)
    if not frame then return nil end
    local left, right, top, bottom = frame:GetLeft(), frame:GetRight(), frame:GetTop(), frame:GetBottom()
    if not left or not right or not top or not bottom then return nil end
    return { left = left, right = right, top = top, bottom = bottom }
end

local function RectsOverlap(a, b, padding)
    padding = tonumber(padding) or 1
    if not a or not b then return false end
    return a.left < b.right - padding and a.right > b.left + padding
       and a.bottom < b.top - padding and a.top > b.bottom + padding
end

function Browser:GetTabCollisionCount()
    local qmf = _G.QuestMapFrame
    if not qmf or not tabFrame or not tabFrame:IsShown() then return 0 end
    local ours = GetFrameRect(tabFrame)
    if not ours then return 0 end
    local count = 0
    for _, other in ipairs(GetVisibleManagedSideTabs(qmf)) do
        if RectsOverlap(ours, GetFrameRect(other), 1) then count = count + 1 end
    end
    if backTab and backTab:IsShown() and RectsOverlap(ours, GetFrameRect(backTab), 1) then count = count + 1 end
    return count
end

function Browser:GetTabLayoutDebug()
    local qmf = _G.QuestMapFrame
    local result = { candidates = {}, collisions = 0, anchorMode = tabAnchorMode, anchorName = tabAnchorName }
    if not qmf then return result end
    local ours = tabFrame and GetFrameRect(tabFrame) or nil
    for _, other in ipairs(GetVisibleManagedSideTabs(qmf)) do
        local rect = GetFrameRect(other)
        result.candidates[#result.candidates + 1] = {
            name = other.GetName and (other:GetName() or "anonymous") or "anonymous",
            displayMode = tostring(other.displayMode),
            left = rect and rect.left or nil, right = rect and rect.right or nil,
            top = rect and rect.top or nil, bottom = rect and rect.bottom or nil,
        }
        if ours and RectsOverlap(ours, rect, 1) then result.collisions = result.collisions + 1 end
    end
    result.ours = ours
    return result
end

local lastSystemDisplayMode

local function GetWorldMapTabsLibrary()
    if type(_G.LibStub) ~= "function" then return nil end
    local ok, lib = pcall(_G.LibStub, "LibWorldMapTabs", true)
    if ok and type(lib) == "table" and type(lib.SetDisplayMode) == "function" then return lib end
    return nil
end

local function HideNativeQuestMapContent(qmf)
    if not qmf then return end
    -- WoW Forever can re-show the quest content during the map's OnShow
    -- sequence even after SetDisplayMode(nil).  Keep the detached surface
    -- exclusive whenever our tab is selected.  These are ordinary content
    -- frames, not protected MapCanvas pins or protected-action state.
    if qmf.QuestsFrame and qmf.QuestsFrame.IsShown and qmf.QuestsFrame:IsShown() then qmf.QuestsFrame:Hide() end
    if qmf.EventsFrame and qmf.EventsFrame.IsShown and qmf.EventsFrame:IsShown() then qmf.EventsFrame:Hide() end
    if qmf.MapLegend and qmf.MapLegend.IsShown and qmf.MapLegend:IsShown() then qmf.MapLegend:Hide() end
end

local function ReleaseOtherDetachedPanels(qmf)
    if not qmf or type(qmf.SetDisplayMode) ~= "function" then return false end
    if IsNativeDisplayMode(qmf, qmf.displayMode) then return false end

    -- Detached map tabs such as the reference MapSearch surface listen for a
    -- *real* Blizzard display mode to know that another tab has taken control.
    -- If one of those tabs left QuestMapFrame in nil mode, briefly hand control
    -- back to the last native mode before selecting Forever Instances.  This is
    -- a valid Blizzard mode (never a fabricated enum/string), so cooperative
    -- custom tabs close themselves through their own secure hooks and restore
    -- their own icon/glow state.  We immediately leave that native mode below.
    local nativeMode = lastSystemDisplayMode or (qmf.QuestsTab and qmf.QuestsTab.displayMode)
    if nativeMode == nil then return false end
    local ok = pcall(qmf.SetDisplayMode, qmf, nativeMode)
    return ok == true
end

local function DeactivateOtherMapContents(qmf)
    if not qmf then return end
    if type(qmf.SetDisplayMode) == "function" then
        local ok = pcall(qmf.SetDisplayMode, qmf)
        if not ok then HideNativeQuestMapContent(qmf) end
    else
        HideNativeQuestMapContent(qmf)
    end

    -- Match the proven detached map-tab lifecycle: third-party map
    -- tab frameworks do not necessarily react to QuestMapFrame:nil, so use
    -- their public shared-library API when it is present.  No foreign addon
    -- names or frames are referenced.
    local lib = GetWorldMapTabsLibrary()
    if lib then pcall(lib.SetDisplayMode, lib, nil) end

    -- While our browser is actively selected, keep the native content frames off.
    HideNativeQuestMapContent(qmf)
end

local function InstallExternalModeHook()
    local lib = GetWorldMapTabsLibrary()
    if not lib or worldMapTabsHookedLibrary == lib then return end
    worldMapTabsHookedLibrary = lib
    if type(hooksecurefunc) == "function" then
        hooksecurefunc(lib, "SetDisplayMode", function(_, displayMode)
            if displayMode ~= nil then
                if selectedIsOurs then Browser:Hide(false) end
            end
        end)
    end
end

local function InstallSystemModeHook(qmf)
    if not qmf or systemModeHooks[qmf] then return end
    systemModeHooks[qmf] = true
    local initialMode = qmf.displayMode or (qmf.QuestsTab and qmf.QuestsTab.displayMode)
    if IsNativeDisplayMode(qmf, initialMode) then lastSystemDisplayMode = initialMode end
    if type(hooksecurefunc) == "function" and type(qmf.SetDisplayMode) == "function" then
        hooksecurefunc(qmf, "SetDisplayMode", function(_, displayMode)
            if displayMode ~= nil then
                if IsNativeDisplayMode(qmf, displayMode) then lastSystemDisplayMode = displayMode end
                if selectedIsOurs then Browser:Hide(false) end
            end
        end)
    end
end

function Browser:EnsureExclusivePanel()
    if not selectedIsOurs or not panel or not panel.outer or not panel.outer:IsShown() then return false end
    local qmf = _G.QuestMapFrame
    if not qmf then return false end
    DeactivateOtherMapContents(qmf)
    panel.outer:Show()
    return true
end

function Browser:Show()
    if not panel or not panel.outer then return false end
    local qmf = _G.QuestMapFrame
    if not qmf then return false end

    if panel.MeasureBlizzardSearch then panel.MeasureBlizzardSearch() end

    -- If another detached custom tab currently owns a nil QuestMapFrame mode,
    -- give it a normal Blizzard-mode handoff first. This mirrors the reference
    -- addon's coexistence contract and prevents two independent panels from
    -- remaining selected at the same time.
    ReleaseOtherDetachedPanels(qmf)

    selectedIsOurs = true
    prevBlizzardDisplayMode = qmf.displayMode or lastSystemDisplayMode

    DeactivateOtherMapContents(qmf)

    panel.outer:Show()
    self:SyncPanelGeometry()
    self:RefreshList()
    RefreshSelectGlows()
    PlaceTab()
    return true
end

function Browser:Hide(restoreBlizzardMode)
    if panel and panel.outer then panel.outer:Hide() end
    local wasSelected = selectedIsOurs
    selectedIsOurs = false
    if panel and panel.searchBox then panel.searchBox:ClearFocus() end

    local qmf = _G.QuestMapFrame
    if wasSelected and restoreBlizzardMode and qmf and qmf.SetDisplayMode and qmf.displayMode == nil then
        local restore = prevBlizzardDisplayMode or lastSystemDisplayMode or (qmf.QuestsTab and qmf.QuestsTab.displayMode) or qmf.QuestsFrame
        if restore then
            restoringBlizzardDisplayMode = true
            pcall(qmf.SetDisplayMode, qmf, restore)
            restoringBlizzardDisplayMode = false
        end
    end
    if wasSelected then prevBlizzardDisplayMode = nil end
    RefreshSelectGlows()
end

local layoutPending = false
function Browser:ScheduleLayout(delay)
    if layoutPending then return end
    layoutPending = true
    local function run()
        layoutPending = false
        PlaceTab()
    end
    delay = tonumber(delay) or 0
    if C_Timer and C_Timer.After then C_Timer.After(delay, run) else run() end
end

function Browser:Initialize()
    local qmf = _G.QuestMapFrame
    if not qmf or not (qmf.MapLegendTab or qmf.EventsTab or qmf.QuestsTab) then return false end
    if not tabFrame then CreateSideTab(qmf) end
    if not panel then CreatePanel(qmf) end
    if not tabFrame or not panel then return false end

    InstallSystemModeHook(qmf)
    InstallExternalModeHook()
    PlaceTab()
    self:SyncPanelGeometry()
    self:RefreshList()

    if not initialized then
        initialized = true

        -- Do not make the addon tab sticky across World Map close/reopen.
        -- Blizzard owns the map-open lifecycle and decides which native mode
        -- is shown when the map opens. Our browser is user-selected only:
        -- clicking its side tab opens it; closing/maximizing the map restores
        -- the previously active Blizzard mode and clears our selection.
        if _G.WorldMapFrame then
            WorldMapFrame:HookScript("OnShow", function()
                PlaceTab()
                if panel and panel.MeasureBlizzardSearch then panel.MeasureBlizzardSearch() end
                Browser:ScheduleLayout(0)
            end)

            WorldMapFrame:HookScript("OnHide", function()
                if selectedIsOurs then
                    Browser:Hide(true)
                end
            end)

            if WorldMapFrame.IsMaximized and type(hooksecurefunc) == "function" then
                local function UpdateVisibility()
                    if not tabFrame then return end
                    if WorldMapFrame:IsMaximized() then
                        if selectedIsOurs then Browser:Hide(true) end
                        tabFrame:Hide()
                    else
                        tabFrame:Show()
                        PlaceTab()
                        Browser:ScheduleLayout(0)
                    end
                end
                hooksecurefunc(WorldMapFrame, "Maximize", UpdateVisibility)
                hooksecurefunc(WorldMapFrame, "Minimize", UpdateVisibility)
                UpdateVisibility()
            end
        end
    end
    return true
end

function Browser:IsShown()
    return panel and panel.outer and panel.outer:IsShown() or false
end

function Browser:GetDebugState()
    local qmf = _G.QuestMapFrame
    local tabArrayTouched, contentArrayTouched = false, false
    if qmf and type(qmf.TabButtons) == "table" and tabFrame then
        for _, value in ipairs(qmf.TabButtons) do if value == tabFrame then tabArrayTouched = true break end end
    end
    if qmf and type(qmf.ContentFrames) == "table" and panel and panel.outer then
        for _, value in ipairs(qmf.ContentFrames) do if value == panel.outer then contentArrayTouched = true break end end
    end
    local managedCount = qmf and #GetVisibleManagedSideTabs(qmf) or 0
    local questStyleCount, passiveCount, hookedCount, customManagedCount, customUnmanagedCount = 0, 0, 0, 0, 0
    if qmf then
        local allSideTabs = GetVisibleQuestStyleSideTabs(qmf)
        questStyleCount = #allSideTabs
        for _, sideTab in ipairs(allSideTabs) do
            if IsFallbackQuestTab(sideTab, qmf) then
                passiveCount = passiveCount + 1
            elseif not IsNativeQuestMapTab(sideTab, qmf) and sideTab.displayMode == nil then
                customUnmanagedCount = customUnmanagedCount + 1
            elseif not IsNativeQuestMapTab(sideTab, qmf) then
                customManagedCount = customManagedCount + 1
            end
            if externalTabHooks[sideTab] then hookedCount = hookedCount + 1 end
        end
    end
    return {
        initialized = initialized,
        safeDetached = not tabArrayTouched and not contentArrayTouched,
        blizzardTabArrayTouched = tabArrayTouched,
        blizzardContentArrayTouched = contentArrayTouched,
        questStyleTab = tabFrame and tabFrame._fiQuestStyleTab == true,
        panelExists = panel ~= nil,
        shown = self:IsShown(),
        tabChecked = selectedIsOurs,
        tabSelected = selectedIsOurs,
        displayMode = qmf and qmf.displayMode or nil,
        visibleRows = math.max(0, rowCursor - 1),
        visibleHeaders = math.max(0, headerCursor - 1),
        searchText = searchText,
        activePinName = activePinTarget and activePinTarget.name or nil,
        activePinMapID = activePinTarget and activePinTarget.mapID or nil,
        markerShown = false,
        sideTabsDetected = managedCount,
        questStyleSideTabsDetected = questStyleCount,
        passiveSideTabsDetected = passiveCount,
        customManagedSideTabsDetected = customManagedCount,
        customUnmanagedSideTabsDetected = customUnmanagedCount,
        externalTabHandoffHooks = hookedCount,
        externalTabHandoffPhase = "post-mouseup",
        externalSelectedGlows = qmf and CountExternalSelectedGlows(qmf) or 0,
        tabCollisions = self:GetTabCollisionCount(),
        tabDisplayMode = tabFrame and tabFrame.displayMode or nil,
        tabAnchorMode = tabAnchorMode,
        tabAnchorName = tabAnchorName,
        usesBlizzardDungeonAtlas = tabFrame and tabFrame._fiUsesBlizzardDungeonAtlas == true or false,
        manualQuestScroll = panel and panel.scrollFrame ~= nil and panel.scrollBar ~= nil,
        nativeQuestsShown = qmf and qmf.QuestsFrame and qmf.QuestsFrame:IsShown() or false,
        nativeEventsShown = qmf and qmf.EventsFrame and qmf.EventsFrame:IsShown() or false,
        nativeLegendShown = qmf and qmf.MapLegend and qmf.MapLegend:IsShown() or false,
        externalTabLibrary = GetWorldMapTabsLibrary() ~= nil,
    }
end

function Browser:CaptureDebugTransientState()
    local state = GetState()
    local pinCopy
    if type(activePinTarget) == "table" then
        pinCopy = {}; for key, value in pairs(activePinTarget) do pinCopy[key] = value end
    end
    return { activePinTarget = pinCopy, lastInstance = state.lastInstance, browserShown = self:IsShown() }
end

function Browser:RestoreDebugTransientState(snapshot)
    snapshot = type(snapshot) == "table" and snapshot or {}
    activePinTarget = snapshot.activePinTarget
    local state = GetState(); state.lastInstance = snapshot.lastInstance
    if snapshot.browserShown then self:Show() else self:Hide(true) end
    self:RefreshList()
end

function Browser:DebugCountMatches(query)
    query = tostring(query or ""):lower()
    local count = 0
    for _, entry in ipairs(GetEntries()) do if EntryMatches(entry, query) then count = count + 1 end end
    return count
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 ~= addonName and arg1 ~= "Blizzard_WorldMap" and initialized then
        -- A newly loaded addon may add another map tab.  We never inspect its
        -- name; simply re-run the same direct-child layout after it loads.
    end

    local function RefreshIntegration()
        Browser:Initialize()
        PlaceTab()
    end
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, RefreshIntegration)
        C_Timer.After(0.12, RefreshIntegration)
        C_Timer.After(0.40, RefreshIntegration)
    else
        RefreshIntegration()
    end
end)
