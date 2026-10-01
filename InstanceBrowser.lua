-- Forever Instances - native Blizzard-styled, taint-safe instance browser for WoW Forever
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
local initialized = false
local selectedIsOurs = false
local lastSelectedWasOurs = false
local restoringBlizzardDisplayMode = false
local prevBlizzardDisplayMode
local activePinTarget
local activeTomTomWaypoint
local searchText = ""
local rowPool, headerPool = {}, {}
local rowCursor, headerCursor = 1, 1
local foreignTabHooks = setmetatable({}, { __mode = "k" })
local systemModeHooks = setmetatable({}, { __mode = "k" })

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
    local root = "Interface\\AddOns\\" .. addonName .. "\\"
    local isRaid = instance.contentType == "Raid"
    if isRaid then row.typeIcon:SetTexture(root .. "raid.tga")
    elseif instance.era == "Forever" then row.typeIcon:SetTexture(root .. "forever_dungeon.tga")
    else row.typeIcon:SetTexture(root .. "dungeon.tga") end
    row.typeIcon:SetTexCoord(0, 1, 0, 1)
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
    child:SetWidth(math.max(1, width - 4))
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

local function SetTabSelected(tab, selected)
    if not tab then return end
    if tab.SelectedTexture and tab.SelectedTexture.SetShown then
        tab.SelectedTexture:SetShown(selected == true)
    end
    if tab.TabGlow and tab.TabGlow.SetAlpha then
        tab.TabGlow:SetAlpha(selected and 0.55 or 0)
    end
    if tab._fiIcon then
        SetVertexColor(tab._fiIcon, selected and TAB_ICON_GOLD or TAB_ICON_DIM)
    end
end

local function RefreshSelectGlows()
    SetTabSelected(tabFrame, selectedIsOurs)
end

local function CreateSideTab(qmf)
    if tabFrame or not qmf then return end
    local ref = qmf.MapLegendTab or qmf.EventsTab or qmf.QuestsTab
    if not ref then return end

    local ok, tab = pcall(CreateFrame, "Frame", "ForeverInstancesMapBrowserTab", qmf, "LargeSideTabButtonTemplate")
    if not ok or not tab then
        tab = CreateFrame("Frame", "ForeverInstancesMapBrowserTab", qmf)
        tab:SetSize(TAB_W, TAB_H)
        tab:EnableMouse(true)
        tab._fiNativeTemplate = false

        local bg = tab:CreateTexture(nil, "BACKGROUND")
        SafeAtlas(bg, "common-sidetab", true)
        bg:SetPoint("CENTER")

        local selected = tab:CreateTexture(nil, "OVERLAY")
        SafeAtlas(selected, "common-sidetab-selected", true)
        selected:SetPoint("CENTER")
        selected:Hide()
        tab.SelectedTexture = selected

        local hover = tab:CreateTexture(nil, "HIGHLIGHT")
        SafeAtlas(hover, "common-sidetab-hover", true)
        hover:SetPoint("CENTER")
    else
        tab._fiNativeTemplate = true
    end

    local w, h = ref:GetSize()
    if w and w > 0 and h and h > 0 then tab:SetSize(w, h) end
    tab:SetFrameLevel(ref:GetFrameLevel())
    tab.tooltipText = L("BROWSER_TITLE")

    local icon = tab.Icon
    if not icon then
        icon = tab:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("CENTER")
    end
    icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\dungeon.tga")
    icon:SetTexCoord(0, 1, 0, 1)
    icon:SetSize(TAB_ICON_SIZE + 3, TAB_ICON_SIZE + 3)
    SetVertexColor(icon, TAB_ICON_DIM)
    tab._fiIcon = icon

    local function Activate(_, button, upInside)
        if button == "LeftButton" and upInside ~= false then Browser:Show() end
    end
    if tab._fiNativeTemplate then
        tab.customMouseUpHandler = Activate
    else
        tab:SetScript("OnMouseUp", Activate)
        tab:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText(L("BROWSER_TITLE"))
            GameTooltip:AddLine(L("BROWSER_TAB_DESC"), 1, 1, 1, true)
            GameTooltip:Show()
        end)
        tab:SetScript("OnLeave", GameTooltip_Hide)
    end

    tabFrame = tab
    SetTabSelected(tabFrame, false)
end

local function CreatePanel(qmf)
    if panel or not qmf then return end
    local anchor = qmf.QuestsFrame or qmf.ContentsAnchor or qmf
    local usingContentsAnchor = anchor == qmf.ContentsAnchor

    local outer = CreateFrame("Frame", "ForeverInstancesMapBrowserOuter", qmf)
    outer:SetAllPoints(anchor)
    outer:SetFrameLevel((anchor.GetFrameLevel and anchor:GetFrameLevel() or qmf:GetFrameLevel()) + 12)
    outer:EnableMouse(true)
    outer:Hide()

    local p = CreateFrame("Frame", "ForeverInstancesMapBrowserPanel", outer)
    p:SetPoint("TOPLEFT", outer, "TOPLEFT", 0, -QUEST_HEADER_HEIGHT)
    p:SetPoint("BOTTOMRIGHT", outer, "BOTTOMRIGHT", usingContentsAnchor and -22 or 0, 0)
    p:SetFrameLevel(outer:GetFrameLevel() + 1)
    p:EnableMouse(true)
    p.outer = outer

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
    searchBox:SetFrameLevel(outer:GetFrameLevel() + 2)
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

    local function SearchChanged(self)
        if SearchBoxTemplate_OnTextChanged then pcall(SearchBoxTemplate_OnTextChanged, self) end
        searchText = tostring(self:GetText() or "")
        Browser:RefreshList()
    end
    searchBox:SetScript("OnTextChanged", SearchChanged)

    local okScroll, scrollFrame = pcall(CreateFrame, "ScrollFrame", "ForeverInstancesMapBrowserScrollFrame", p, "ScrollFrameTemplate")
    if not okScroll or not scrollFrame then
        scrollFrame = CreateFrame("ScrollFrame", "ForeverInstancesMapBrowserScrollFrame", p)
        scrollFrame._fiNativeTemplate = false
    else
        scrollFrame._fiNativeTemplate = true
    end
    scrollFrame:SetPoint("TOPLEFT", p, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", 0, 0)
    scrollFrame:EnableMouseWheel(true)
    p.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)
    scrollFrame:HookScript("OnSizeChanged", function(_, w)
        scrollChild:SetWidth(math.max(1, (w or 1) - 4))
    end)
    scrollChild:SetWidth(math.max(1, (scrollFrame:GetWidth() or 1) - 4))
    p.scrollChild = scrollChild

    local scrollBar = scrollFrame.ScrollBar
    if scrollBar then
        scrollBar:ClearAllPoints()
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 8, 2)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 8, -4)
        p.scrollBar = scrollBar
    end

    if not scrollFrame:GetScript("OnMouseWheel") then
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local maxScroll = math.max(0, (scrollChild:GetHeight() or 0) - (self:GetHeight() or 0))
            local target = (self:GetVerticalScroll() or 0) - delta * 24
            if target < 0 then target = 0 elseif target > maxScroll then target = maxScroll end
            self:SetVerticalScroll(target)
            if p.scrollBar and p.scrollBar.Update then p.scrollBar:Update() end
        end)
    end

    p.SyncScrollBar = function()
        if p.scrollBar and p.scrollBar.Update then pcall(p.scrollBar.Update, p.scrollBar) end
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
        if w > 0 then panel.scrollChild:SetWidth(math.max(1, w - 4)) end
    end
    if panel.SyncScrollBar then panel.SyncScrollBar() end
    return true
end

local function IsLikelySideTab(frame, qmf)
    if not frame or frame == tabFrame or frame == panel or frame == (panel and panel.outer) then return false end
    if not frame.IsShown or not frame:IsShown() then return false end
    local w, h = frame:GetSize()
    if not w or not h or w < 34 or w > 72 or h < 44 or h > 72 then return false end
    local qRight = qmf:GetRight()
    local left, right = frame:GetLeft(), frame:GetRight()
    if not qRight or not left or not right then return false end
    if right < qRight - 8 or left > qRight + 90 then return false end
    local top, bottom = frame:GetTop(), frame:GetBottom()
    local qTop, qBottom = qmf:GetTop(), qmf:GetBottom()
    if not top or not bottom or not qTop or not qBottom then return false end
    return top <= qTop + 16 and bottom >= qBottom - 16
end

local function CollectSideTabs(qmf)
    local tabs, seen = {}, {}
    local function scan(parent)
        if not parent or not parent.GetChildren then return end
        for _, child in ipairs({ parent:GetChildren() }) do
            if not seen[child] and IsLikelySideTab(child, qmf) then
                seen[child] = true
                tabs[#tabs + 1] = child
            end
        end
    end
    scan(qmf)
    scan(_G.WorldMapFrame)
    table.sort(tabs, function(a, b)
        return (a:GetTop() or 0) > (b:GetTop() or 0)
    end)
    return tabs
end

local function HookForeignTab(tab)
    if not tab or tab == tabFrame or foreignTabHooks[tab] then return end
    foreignTabHooks[tab] = true
    if tab.HookScript then
        pcall(tab.HookScript, tab, "OnMouseUp", function(_, button)
            if button == "LeftButton" and selectedIsOurs then Browser:Hide(false) end
        end)
        pcall(tab.HookScript, tab, "OnShow", function() Browser:ScheduleLayout() end)
        pcall(tab.HookScript, tab, "OnHide", function() Browser:ScheduleLayout() end)
    end
end

function Browser:GetTabCollisionCount()
    local qmf = _G.QuestMapFrame
    if not qmf or not tabFrame or not tabFrame:IsShown() then return 0 end
    local l1, r1, t1, b1 = tabFrame:GetLeft(), tabFrame:GetRight(), tabFrame:GetTop(), tabFrame:GetBottom()
    if not l1 or not r1 or not t1 or not b1 then return 0 end
    local count = 0
    for _, other in ipairs(CollectSideTabs(qmf)) do
        if other ~= tabFrame then
            local l2, r2, t2, b2 = other:GetLeft(), other:GetRight(), other:GetTop(), other:GetBottom()
            if l2 and r2 and t2 and b2 then
                local horizontal = l1 < r2 - 1 and r1 > l2 + 1
                local vertical = b1 < t2 - 1 and t1 > b2 + 1
                if horizontal and vertical then count = count + 1 end
            end
        end
    end
    return count
end

local layoutPending = false
function Browser:ScheduleLayout()
    if layoutPending then return end
    layoutPending = true
    local function run()
        layoutPending = false
        Browser:PlaceTab()
    end
    if C_Timer and C_Timer.After then C_Timer.After(0, run) else run() end
end

function Browser:PlaceTab()
    if not tabFrame then return false end
    local qmf = _G.QuestMapFrame
    if not qmf then return false end

    local candidates = CollectSideTabs(qmf)
    local lowest, lowestBottom
    for _, candidate in ipairs(candidates) do
        HookForeignTab(candidate)
        local bottom = candidate:GetBottom()
        if bottom and (not lowestBottom or bottom < lowestBottom) then
            lowest, lowestBottom = candidate, bottom
        end
    end

    tabFrame:ClearAllPoints()
    if lowest then
        tabFrame:SetPoint("TOPLEFT", lowest, "BOTTOMLEFT", 0, TAB_GAP)
    elseif qmf.QuestsTab then
        tabFrame:SetPoint("TOPLEFT", qmf.QuestsTab, "TOPLEFT", 0, 0)
    else
        tabFrame:SetPoint("TOPLEFT", qmf, "TOPRIGHT", 3, -28)
    end
    tabFrame:Show()
    return true
end

local lastSystemDisplayMode
local function InstallSystemModeHook(qmf)
    if not qmf or systemModeHooks[qmf] then return end
    systemModeHooks[qmf] = true
    lastSystemDisplayMode = qmf.displayMode or (qmf.QuestsTab and qmf.QuestsTab.displayMode)
    if type(hooksecurefunc) == "function" and type(qmf.SetDisplayMode) == "function" then
        hooksecurefunc(qmf, "SetDisplayMode", function(_, displayMode)
            if displayMode ~= nil then
                lastSystemDisplayMode = displayMode
                if not restoringBlizzardDisplayMode then lastSelectedWasOurs = false end
                if selectedIsOurs then Browser:Hide(false) end
            end
        end)
    end
end

function Browser:Show()
    if not panel or not panel.outer then return false end
    local qmf = _G.QuestMapFrame
    if not qmf then return false end

    if panel.MeasureBlizzardSearch then panel.MeasureBlizzardSearch() end

    selectedIsOurs = true
    lastSelectedWasOurs = true
    prevBlizzardDisplayMode = qmf.displayMode or lastSystemDisplayMode

    if qmf.SetDisplayMode then
        -- If another detached panel currently owns the nil display mode, briefly
        -- return to the last stock mode first. This gives any cooperating addon a
        -- normal Blizzard mode transition to close itself without naming or
        -- depending on that addon.
        if qmf.displayMode == nil and lastSystemDisplayMode ~= nil then
            pcall(qmf.SetDisplayMode, qmf, lastSystemDisplayMode)
        end
        pcall(qmf.SetDisplayMode, qmf)
    end

    panel.outer:Show()
    self:SyncPanelGeometry()
    self:RefreshList()
    RefreshSelectGlows()
    self:PlaceTab()
    return true
end

function Browser:Hide(restoreBlizzardMode)
    if panel and panel.outer then panel.outer:Hide() end
    local wasSelected = selectedIsOurs
    selectedIsOurs = false
    if panel and panel.searchBox then panel.searchBox:ClearFocus() end

    local qmf = _G.QuestMapFrame
    if wasSelected and restoreBlizzardMode and qmf and qmf.SetDisplayMode and qmf.displayMode == nil then
        local restore = prevBlizzardDisplayMode or lastSystemDisplayMode or (qmf.QuestsTab and qmf.QuestsTab.displayMode)
        if restore then
            restoringBlizzardDisplayMode = true
            pcall(qmf.SetDisplayMode, qmf, restore)
            restoringBlizzardDisplayMode = false
        end
    end
    if wasSelected then prevBlizzardDisplayMode = nil end
    RefreshSelectGlows()
end

local layoutWatcher
local function InstallLayoutWatcher()
    if layoutWatcher then return end
    layoutWatcher = CreateFrame("Frame")
    local elapsed = 0
    layoutWatcher:SetScript("OnUpdate", function(_, dt)
        if not _G.WorldMapFrame or not WorldMapFrame:IsShown() then return end
        elapsed = elapsed + dt
        if elapsed < 0.40 then return end
        elapsed = 0
        Browser:PlaceTab()
    end)
end

function Browser:Initialize()
    local qmf = _G.QuestMapFrame
    if not qmf or not (qmf.MapLegendTab or qmf.EventsTab or qmf.QuestsTab) then return false end
    if not tabFrame then CreateSideTab(qmf) end
    if not panel then CreatePanel(qmf) end
    if not tabFrame or not panel then return false end

    InstallSystemModeHook(qmf)
    InstallLayoutWatcher()
    self:PlaceTab()
    self:SyncPanelGeometry()
    self:RefreshList()

    if not initialized then
        initialized = true
        if _G.WorldMapFrame then
            WorldMapFrame:HookScript("OnShow", function()
                Browser:ScheduleLayout()
                if C_Timer and C_Timer.After then
                    C_Timer.After(0, function()
                        Browser:PlaceTab()
                        if panel and panel.MeasureBlizzardSearch then panel.MeasureBlizzardSearch() end
                        if lastSelectedWasOurs and panel and not (WorldMapFrame.IsMaximized and WorldMapFrame:IsMaximized()) then Browser:Show() end
                    end)
                end
            end)
            WorldMapFrame:HookScript("OnHide", function()
                if selectedIsOurs then lastSelectedWasOurs = true; Browser:Hide(true) end
            end)
            if WorldMapFrame.IsMaximized and type(hooksecurefunc) == "function" then
                local function UpdateVisibility()
                    if not tabFrame then return end
                    if WorldMapFrame:IsMaximized() then Browser:Hide(true); tabFrame:Hide()
                    else tabFrame:Show(); Browser:ScheduleLayout() end
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
    local foreignCount = 0
    if qmf then foreignCount = #CollectSideTabs(qmf) end
    return {
        initialized = initialized,
        safeDetached = not tabArrayTouched and not contentArrayTouched,
        blizzardTabArrayTouched = tabArrayTouched,
        blizzardContentArrayTouched = contentArrayTouched,
        nativeTabTemplate = tabFrame and tabFrame._fiNativeTemplate == true,
        nativeScrollTemplate = panel and panel.scrollFrame and panel.scrollFrame._fiNativeTemplate == true,
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
        sideTabsDetected = foreignCount,
        tabCollisions = self:GetTabCollisionCount(),
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
    if event == "ADDON_LOADED" and arg1 ~= addonName and not initialized then return end

    local function RefreshIntegration()
        Browser:Initialize()
        Browser:PlaceTab()
    end
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, RefreshIntegration)
        C_Timer.After(0.15, RefreshIntegration)
    else
        RefreshIntegration()
    end
end)
