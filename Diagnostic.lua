-- Forever Instances - live in-game diagnostic/regression runner
-- Runs only when explicitly requested with /fitest.
local addonName, ns = ...

local Diagnostic = {}
ns.Diagnostic = Diagnostic

local EVENT_PREFIX = "|cffffd36bForever Instances:|r "
local DISPLAY_NAME = "Forever Instances Live Test"

local reportFrame
local reportEditBox
local reportStatus
local lastReport = ""
local activeRun
local runSerial = 0

local function L(key, ...)
    if type(ns.L) == "function" then
        return ns.L(key, ...)
    end
    local locales = ns.Locales or {}
    local bucket = locales.enUS or {}
    local value = bucket[key] or key
    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, tostring(value), ...)
        if ok then return formatted end
    end
    return tostring(value)
end

local function chat(message)
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
        DEFAULT_CHAT_FRAME:AddMessage(EVENT_PREFIX .. tostring(message or ""))
    end
end

local function trim(value)
    value = tostring(value or "")
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function shallowCopy(source)
    local out = {}
    if type(source) == "table" then
        for key, value in pairs(source) do out[key] = value end
    end
    return out
end

local function getAddonMetadata(field)
    if C_AddOns and type(C_AddOns.GetAddOnMetadata) == "function" then
        local ok, value = pcall(C_AddOns.GetAddOnMetadata, addonName, field)
        if ok then return value end
    end
    if type(GetAddOnMetadata) == "function" then
        local ok, value = pcall(GetAddOnMetadata, addonName, field)
        if ok then return value end
    end
    return nil
end

local function isAddonLoaded(name)
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        local ok, loaded = pcall(C_AddOns.IsAddOnLoaded, name)
        if ok then return loaded == true end
    end
    if type(IsAddOnLoaded) == "function" then
        local ok, loaded = pcall(IsAddOnLoaded, name)
        if ok then return loaded == true end
    end
    return false
end

local function tryLoadAddon(name)
    if isAddonLoaded(name) then return true, "already loaded" end
    local loader
    if C_AddOns and type(C_AddOns.LoadAddOn) == "function" then
        loader = function() return C_AddOns.LoadAddOn(name) end
    elseif type(UIParentLoadAddOn) == "function" then
        loader = function() return UIParentLoadAddOn(name) end
    elseif type(LoadAddOn) == "function" then
        loader = function() return LoadAddOn(name) end
    end
    if not loader then return false, "no LoadAddOn API" end

    local ok, loaded, reason = pcall(loader)
    if not ok then return false, tostring(loaded) end
    if loaded == true or isAddonLoaded(name) then return true, tostring(reason or "loaded") end
    return false, tostring(reason or loaded or "load failed")
end

local function safeDebugStack()
    if type(debugstack) ~= "function" then return "" end
    local ok, stack = pcall(debugstack, 3, 18, 18)
    if ok and type(stack) == "string" then return stack end
    return ""
end

local function formatTimestamp()
    if type(date) == "function" then
        local ok, value = pcall(date, "%Y-%m-%d %H:%M:%S")
        if ok then return value end
    end
    return tostring(GetTime and GetTime() or "unknown")
end

local function safeCreateFrame(frameType, name, parent, template)
    local ok, frame = pcall(CreateFrame, frameType, name, parent, template)
    if ok then return frame end
    return nil
end

local function ensureReportFrame()
    if reportFrame then return reportFrame end

    local frame = safeCreateFrame("Frame", "ForeverInstancesDiagnosticFrame", UIParent, "BasicFrameTemplateWithInset")
    if not frame then
        frame = safeCreateFrame("Frame", "ForeverInstancesDiagnosticFrame", UIParent, "BackdropTemplate")
    end
    if not frame then
        frame = CreateFrame("Frame", "ForeverInstancesDiagnosticFrame", UIParent)
    end

    frame:SetSize(760, 560)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    if frame.SetBackdrop and not frame.Bg then
        pcall(frame.SetBackdrop, frame, {
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 24,
            insets = { left = 8, right = 8, top = 8, bottom = 8 },
        })
    end

    local title = frame.TitleText
    if not title then
        title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        title:SetPoint("TOP", 0, -13)
    end
    title:SetText(L("DIAG_TITLE"))

    if not frame.CloseButton then
        local closeX = safeCreateFrame("Button", nil, frame, "UIPanelCloseButton")
        if closeX then closeX:SetPoint("TOPRIGHT", -4, -4) end
    end

    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 20, -42)
    hint:SetPoint("TOPRIGHT", -20, -42)
    hint:SetJustifyH("LEFT")
    hint:SetText(L("DIAG_COPY_HINT"))

    local status = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    status:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", 0, -7)
    status:SetPoint("TOPRIGHT", hint, "BOTTOMRIGHT", 0, -7)
    status:SetJustifyH("LEFT")
    status:SetText("")
    reportStatus = status

    local scroll = safeCreateFrame("ScrollFrame", "ForeverInstancesDiagnosticScrollFrame", frame, "UIPanelScrollFrameTemplate")
    if not scroll then scroll = CreateFrame("ScrollFrame", "ForeverInstancesDiagnosticScrollFrame", frame) end
    scroll:SetPoint("TOPLEFT", 18, -82)
    scroll:SetPoint("BOTTOMRIGHT", -36, 54)

    local edit = safeCreateFrame("EditBox", "ForeverInstancesDiagnosticEditBox", scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:EnableMouse(true)
    edit:SetFontObject(ChatFontNormal or GameFontHighlightSmall)
    edit:SetTextInsets(4, 4, 4, 4)
    edit:SetWidth(690)
    edit:SetHeight(12000)
    edit:SetJustifyH("LEFT")
    edit:SetJustifyV("TOP")
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(edit)
    reportEditBox = edit

    local selectButton = safeCreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    selectButton:SetSize(120, 24)
    selectButton:SetPoint("BOTTOMLEFT", 18, 18)
    selectButton:SetText(L("DIAG_SELECT_ALL"))
    selectButton:SetScript("OnClick", function()
        if reportEditBox then
            reportEditBox:SetFocus()
            reportEditBox:HighlightText(0, -1)
        end
    end)

    local rerunButton = safeCreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    rerunButton:SetSize(130, 24)
    rerunButton:SetPoint("LEFT", selectButton, "RIGHT", 8, 0)
    rerunButton:SetText(L("DIAG_RERUN"))
    rerunButton:SetScript("OnClick", function() Diagnostic:Run() end)

    local closeButton = safeCreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(100, 24)
    closeButton:SetPoint("BOTTOMRIGHT", -18, 18)
    closeButton:SetText(L("DIAG_CLOSE"))
    closeButton:SetScript("OnClick", function() frame:Hide() end)

    frame:Hide()
    reportFrame = frame
    return frame
end

local function showReport(text, statusText)
    lastReport = tostring(text or "")
    local frame = ensureReportFrame()
    if reportEditBox then
        reportEditBox:SetText(lastReport)
        reportEditBox:SetCursorPosition(0)
        reportEditBox:ClearFocus()
    end
    if reportStatus then reportStatus:SetText(statusText or "") end
    frame:Show()
    if frame.Raise then frame:Raise() end
end

local Runner = {}
Runner.__index = Runner

function Runner:Line(text)
    self.lines[#self.lines + 1] = tostring(text or "")
end

function Runner:Result(status, name, detail)
    status = status or "INFO"
    self.counts[status] = (self.counts[status] or 0) + 1
    local suffix = detail and detail ~= "" and (" — " .. tostring(detail)) or ""
    self:Line(string.format("[%s] %s%s", status, tostring(name or ""), suffix))
end

function Runner:Info(name, detail) self:Result("INFO", name, detail) end
function Runner:Pass(name, detail) self:Result("PASS", name, detail) end
function Runner:Fail(name, detail) self:Result("FAIL", name, detail) end
function Runner:Warn(name, detail) self:Result("WARN", name, detail) end
function Runner:Skip(name, detail) self:Result("SKIP", name, detail) end

function Runner:Test(name, fn)
    local function onError(err)
        return tostring(err) .. (safeDebugStack() ~= "" and ("\n" .. safeDebugStack()) or "")
    end
    local ok, passed, detail, status = xpcall(fn, onError)
    if not ok then
        self:Fail(name, passed)
        self.capturedErrors = self.capturedErrors + 1
        return false
    end
    if passed == true then
        if status == "WARN" then self:Warn(name, detail) else self:Pass(name, detail) end
        return true
    elseif passed == "SKIP" then
        self:Skip(name, detail)
        return nil
    elseif passed == "WARN" then
        self:Warn(name, detail)
        return nil
    else
        self:Fail(name, detail or "condition returned false")
        return false
    end
end

function Runner:AddRestore(fn)
    self.restores[#self.restores + 1] = fn
end

function Runner:RestoreState()
    for index = #self.restores, 1, -1 do
        local ok, err = pcall(self.restores[index])
        if not ok then self:Warn("State restore #" .. tostring(index), tostring(err)) end
    end
    self.restores = {}
end

function Runner:Later(delay, fn)
    local serial = self.serial
    local callback = function()
        if not activeRun or activeRun.serial ~= serial or self.finished then return end
        local ok, err = xpcall(fn, function(e)
            return tostring(e) .. (safeDebugStack() ~= "" and ("\n" .. safeDebugStack()) or "")
        end)
        if not ok then
            self:Fail("Asynchronous test phase", err)
            self.capturedErrors = self.capturedErrors + 1
            self:Finish()
        end
    end
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(delay or 0, callback)
    else
        callback()
    end
end

function Runner:InstallErrorCapture()
    if type(geterrorhandler) ~= "function" or type(seterrorhandler) ~= "function" then
        self:Skip("Global Lua error capture", "geterrorhandler/seterrorhandler API unavailable")
        return
    end
    local original = geterrorhandler()
    if type(original) ~= "function" then
        self:Skip("Global Lua error capture", "current error handler is unavailable")
        return
    end
    self.originalErrorHandler = original
    local run = self
    local handler = function(message)
        if activeRun == run and not run.finished then
            run.capturedErrors = run.capturedErrors + 1
            run:Line("")
            run:Line("[LUA ERROR] Global error raised while the live test was active:")
            run:Line(tostring(message))
            local stack = safeDebugStack()
            if stack ~= "" then run:Line(stack) end
        end
        return original(message)
    end
    local ok, err = pcall(seterrorhandler, handler)
    if ok then
        self.errorHandlerInstalled = true
        self:Pass("Global Lua error capture", "temporary handler installed; original handler is still called")
    else
        self:Warn("Global Lua error capture", tostring(err))
    end
end

function Runner:RestoreErrorCapture()
    if self.errorHandlerInstalled and self.originalErrorHandler and type(seterrorhandler) == "function" then
        pcall(seterrorhandler, self.originalErrorHandler)
    end
    self.errorHandlerInstalled = false
end

function Runner:Header()
    local version = getAddonMetadata("Version") or "unknown"
    local gameVersion, build, buildDate, tocVersion
    if type(GetBuildInfo) == "function" then
        local ok, a, b, c, d = pcall(GetBuildInfo)
        if ok then gameVersion, build, buildDate, tocVersion = a, b, c, d end
    end
    local locale = type(GetLocale) == "function" and GetLocale() or "unknown"
    local bestMap
    if C_Map and type(C_Map.GetBestMapForUnit) == "function" then
        local ok, value = pcall(C_Map.GetBestMapForUnit, "player")
        if ok then bestMap = value end
    end

    self:Line("=== " .. DISPLAY_NAME .. " ===")
    self:Line("Timestamp: " .. formatTimestamp())
    self:Line("Addon: " .. tostring(addonName) .. " " .. tostring(version))
    self:Line("Client: " .. tostring(gameVersion or "unknown") .. " build=" .. tostring(build or "unknown") .. " toc=" .. tostring(tocVersion or "unknown") .. " buildDate=" .. tostring(buildDate or "unknown"))
    self:Line("Locale: " .. tostring(locale))
    self:Line("Player mapID: " .. tostring(bestMap or "unknown"))
    self:Line("Combat lockdown: " .. tostring(type(InCombatLockdown) == "function" and InCombatLockdown() or false))
    self:Line("")
    self:Line("The report records PASS/FAIL/WARN/SKIP for every check and captures Lua/UI/protected-action errors raised while this test is active.")
    self:Line("")
end

local function getDatabaseCounts()
    local db = ns.DB
    local total, dungeons, raids, tba = 0, 0, 0, 0
    local ids, names = {}, {}
    local errors = {}
    if type(db) ~= "table" then return nil end

    for _, sectionName in ipairs({ "Dungeons", "Raids" }) do
        local expectedType = sectionName == "Dungeons" and "Dungeon" or "Raid"
        for _, era in ipairs({ "Classic", "Forever" }) do
            local bucket = db[sectionName] and db[sectionName][era] or {}
            for id, instance in pairs(bucket or {}) do
                total = total + 1
                if expectedType == "Dungeon" then dungeons = dungeons + 1 else raids = raids + 1 end
                if ids[id] then errors[#errors + 1] = "duplicate id=" .. tostring(id) end
                ids[id] = true
                if type(instance.name) ~= "string" or instance.name == "" then
                    errors[#errors + 1] = "missing name=" .. tostring(id)
                elseif names[instance.name] then
                    errors[#errors + 1] = "duplicate name=" .. tostring(instance.name)
                else
                    names[instance.name] = true
                end
                if instance.contentType ~= expectedType then errors[#errors + 1] = "contentType=" .. tostring(id) end
                if instance.era ~= era then errors[#errors + 1] = "era=" .. tostring(id) end
                if instance.coordStatus == "tba" then tba = tba + 1 end
            end
        end
    end
    return total, dungeons, raids, tba, errors
end

function Runner:RunCoreTests()
    self:Line("--- Core / dependencies ---")

    self:Test("Canonical database loaded", function()
        return type(ns.DB) == "table", type(ns.DB) == "table" and ("schema=" .. tostring(ns.DB.version)) or "ns.DB is missing"
    end)

    self:Test("Database catalog totals", function()
        local total, dungeons, raids, tba, errors = getDatabaseCounts()
        if not total then return false, "database unavailable" end
        if #errors > 0 then return false, table.concat(errors, "; ") end
        return total == 37 and dungeons == 28 and raids == 9 and tba == 2,
            string.format("total=%d dungeons=%d raids=%d tba=%d", total, dungeons, raids, tba)
    end)

    self:Test("Browser entries come from shared database", function()
        if type(ns.DB.GetBrowserEntries) ~= "function" then return false, "GetBrowserEntries missing" end
        local entries = ns.DB.GetBrowserEntries()
        return type(entries) == "table" and #entries == 44, "entries=" .. tostring(type(entries) == "table" and #entries or "invalid")
    end)

    self:Test("Supplied dungeon levels / canonical coordinates / wings", function()
        local classic = ns.DB.Dungeons and ns.DB.Dungeons.Classic or {}
        local dm = classic.deadmines
        local sm = classic.scarlet_monastery
        local dire = classic.dire_maul
        local brs = classic.blackrock_spire
        local strat = classic.stratholme
        if not (dm and sm and dire and brs and strat) then return false, "required dungeon records missing" end

        local wingCount = 0
        for _, parent in ipairs({ sm, dire, brs, strat }) do
            for _ in pairs(parent.wings or {}) do wingCount = wingCount + 1 end
        end
        local mapID, x, y
        if type(ns.DB.GetCanonicalLocation) == "function" then
            mapID, x, y = ns.DB.GetCanonicalLocation(dm)
        end
        local ok = dm.levelMin == 17 and dm.levelMax == 26
            and mapID == 1436 and x == 38.2 and y == 77.5
            and wingCount == 11
            and dire.wings and dire.wings.east and dire.wings.east.levelMin == 54
            and brs.wings and brs.wings.lower and brs.wings.lower.players == 10
            and strat.wings and strat.wings.undead and strat.wings.undead.x == 43.0
        return ok, string.format("Deadmines=%s-%s canonical=%s %.1f,%.1f wings=%d",
            tostring(dm.levelMin), tostring(dm.levelMax), tostring(mapID),
            tonumber(x) or 0, tonumber(y) or 0, wingCount)
    end)

    self:Test("Single canonical coordinate source", function()
        if type(ns.DB.GetBrowserEntries) ~= "function" or type(ns.DB.GetCanonicalLocation) ~= "function" then
            return false, "canonical database helpers missing"
        end
        local invalid, mapped, tba = {}, 0, 0
        for _, entry in ipairs(ns.DB.GetBrowserEntries()) do
            local instance = entry.instance
            if instance.entrance ~= nil or instance.alternateEntrances ~= nil or instance.mapPoints ~= nil then
                invalid[#invalid + 1] = tostring(entry.id) .. " has secondary coordinate field"
            end
            local mapID, x, y = ns.DB.GetCanonicalLocation(instance)
            if instance.coordStatus == "tba" then
                tba = tba + 1
                if mapID ~= nil or x ~= nil or y ~= nil then invalid[#invalid + 1] = tostring(entry.id) .. " exposes TBA location" end
            elseif type(mapID) == "number" and type(x) == "number" and type(y) == "number" then
                mapped = mapped + 1
            else
                invalid[#invalid + 1] = tostring(entry.id) .. " missing canonical location"
            end
        end
        return #invalid == 0 and mapped == 42 and tba == 2,
            #invalid == 0 and string.format("mapped=%d tba=%d secondaryFields=0", mapped, tba) or table.concat(invalid, "; ")
    end)

    self:Test("Normalized coordinate contract", function()
        if type(ns.DB.GetNormalizedCoordinates) ~= "function" then return false, "GetNormalizedCoordinates missing" end
        local valid, tba, invalid = 0, 0, {}
        for _, entry in ipairs(ns.DB.GetBrowserEntries()) do
            local instance = entry.instance
            local x, y = ns.DB.GetNormalizedCoordinates(instance)
            if instance.coordStatus == "tba" then
                tba = tba + 1
                if x ~= nil or y ~= nil then invalid[#invalid + 1] = entry.id .. " exposes TBA coordinates" end
            elseif type(x) == "number" and type(y) == "number" and x > 0 and x <= 1 and y > 0 and y <= 1 then
                valid = valid + 1
            else
                invalid[#invalid + 1] = entry.id .. " invalid coordinates"
            end
        end
        return #invalid == 0 and valid == 42 and tba == 2,
            #invalid == 0 and string.format("valid=%d tba=%d", valid, tba) or table.concat(invalid, "; ")
    end)

    self:Test("Continent classification", function()
        if type(ns.DB.GetInstanceContinent) ~= "function" then return false, "GetInstanceContinent missing" end
        local counts = { ["Eastern Kingdoms"] = 0, ["Kalimdor"] = 0 }
        local invalid = {}
        for _, entry in ipairs(ns.DB.GetBrowserEntries()) do
            local continent = ns.DB.GetInstanceContinent(entry.instance)
            if counts[continent] == nil then invalid[#invalid + 1] = tostring(entry.id) .. "=" .. tostring(continent)
            else counts[continent] = counts[continent] + 1 end
        end
        return #invalid == 0 and counts["Eastern Kingdoms"] == 26 and counts["Kalimdor"] == 18,
            string.format("Eastern Kingdoms=%d Kalimdor=%d%s", counts["Eastern Kingdoms"], counts["Kalimdor"], #invalid > 0 and (" invalid=" .. table.concat(invalid, ",")) or "")
    end)

    self:Test("HandyNotes dependency", function()
        local ace = LibStub and LibStub("AceAddon-3.0", true)
        local hn = ace and ace:GetAddon("HandyNotes", true)
        return hn ~= nil, hn and "HandyNotes AceAddon instance found" or "HandyNotes not found"
    end)

    self:Test("AceDB dependency", function()
        local aceDB = LibStub and LibStub("AceDB-3.0", true)
        return aceDB ~= nil, aceDB and "AceDB-3.0 found" or "AceDB-3.0 not found"
    end)

    self:Test("Core diagnostic surface", function()
        return type(ns.GetProfile) == "function" and type(ns.GetFilterState) == "function" and type(ns.GetUnresolved) == "function",
            "GetProfile/GetFilterState/GetUnresolved"
    end)

    self:Test("Saved profile schema", function()
        local profile = type(ns.GetProfile) == "function" and ns.GetProfile() or nil
        if type(profile) ~= "table" then return false, "profile unavailable" end
        local show = profile.show
        if type(show) ~= "table" then return false, "profile.show missing" end
        for _, key in ipairs({ "Dungeon", "Raid", "Classic", "Forever" }) do
            if type(show[key]) ~= "boolean" then return false, "profile.show." .. key .. " is not boolean" end
        end
        return true, "language=" .. tostring(profile.language)
    end)

    self:Test("Localization parity", function()
        local locales = ns.Locales or {}
        local en, uk = locales.enUS, locales.ukUA
        if type(en) ~= "table" or type(uk) ~= "table" then return false, "enUS/ukUA table missing" end
        local missingEn, missingUk = {}, {}
        for key in pairs(en) do if uk[key] == nil then missingUk[#missingUk + 1] = key end end
        for key in pairs(uk) do if en[key] == nil then missingEn[#missingEn + 1] = key end end
        return #missingEn == 0 and #missingUk == 0,
            (#missingEn == 0 and #missingUk == 0) and "enUS=ukUA key parity" or ("missingEn=" .. table.concat(missingEn, ",") .. " missingUk=" .. table.concat(missingUk, ","))
    end)

    self:Test("C_Map API", function()
        return C_Map and type(C_Map.GetMapInfo) == "function" and type(C_Map.GetBestMapForUnit) == "function",
            C_Map and "GetMapInfo/GetBestMapForUnit present" or "C_Map unavailable"
    end)

    self:Test("Live map resolution for mapped instances", function()
        if not C_Map or type(C_Map.GetMapInfo) ~= "function" then return "SKIP", "C_Map.GetMapInfo unavailable" end
        local resolved, unresolved = 0, {}
        for _, entry in ipairs(ns.DB.GetBrowserEntries()) do
            local instance = entry.instance
            if instance.coordStatus ~= "tba" and type(instance.mapID) == "number" then
                local ok, info = pcall(C_Map.GetMapInfo, instance.mapID)
                if ok and type(info) == "table" then resolved = resolved + 1
                else unresolved[#unresolved + 1] = tostring(entry.id) .. "(" .. tostring(instance.mapID) .. ")" end
            end
        end
        if #unresolved > 0 then return "WARN", "resolved=" .. resolved .. " unresolved=" .. table.concat(unresolved, ",") end
        return true, "resolved mapIDs=" .. tostring(resolved)
    end)

    self:Test("Core live node rebuild", function()
        if type(ns.Rebuild) ~= "function" then return false, "ns.Rebuild missing" end
        ns.Rebuild()
        return true, "rebuildNodes + HandyNotes refresh completed"
    end)

    do
        local unresolved = type(ns.GetUnresolved) == "function" and ns.GetUnresolved() or {}
        local expected = { barrow_deeps = true, hyjal_summit = true }
        local count, unexpected, wrongReason = 0, {}, {}
        for id, info in pairs(type(unresolved) == "table" and unresolved or {}) do
            count = count + 1
            if not expected[id] then unexpected[#unexpected + 1] = tostring(id) end
            if expected[id] and type(info) == "table" and info.reason ~= "coordinate_missing" then
                wrongReason[#wrongReason + 1] = tostring(id) .. "=" .. tostring(info.reason)
            end
        end
        if count == 2 and #unexpected == 0 and #wrongReason == 0 then
            self:Pass("Runtime unresolved map nodes", "expected TBA only: barrow_deeps, hyjal_summit")
        else
            local detail = "count=" .. tostring(count)
            if #unexpected > 0 then detail = detail .. " unexpected=" .. table.concat(unexpected, ",") end
            if #wrongReason > 0 then detail = detail .. " reasons=" .. table.concat(wrongReason, ",") end
            self:Warn("Runtime unresolved map nodes", detail)
        end
    end

    do
        local fileIDResolver
        if C_Texture and type(C_Texture.GetFileIDFromPath) == "function" then
            fileIDResolver = function(path) return C_Texture.GetFileIDFromPath(path) end
        elseif type(GetFileIDFromPath) == "function" then
            fileIDResolver = GetFileIDFromPath
        end
        if fileIDResolver then
            local missing = {}
            for _, file in ipairs({ "dungeon.tga", "raid.tga", "forever_dungeon.tga", "icon.tga" }) do
                local path = "Interface\\AddOns\\" .. addonName .. "\\" .. file
                local ok, fileID = pcall(fileIDResolver, path)
                if not ok or not fileID or fileID == 0 then missing[#missing + 1] = file end
            end
            if #missing == 0 then self:Pass("Runtime texture asset resolution", "all addon TGA assets resolved")
            else self:Fail("Runtime texture asset resolution", "missing=" .. table.concat(missing, ",")) end
        else
            self:Skip("Runtime texture asset resolution", "GetFileIDFromPath API unavailable on this client")
        end
    end

    local filters = type(ns.GetFilterState) == "function" and ns.GetFilterState() or nil
    if type(filters) == "table" then
        self:Info("Current filters", string.format("Dungeon=%s Raid=%s Classic=%s Forever=%s", tostring(filters.Dungeon), tostring(filters.Raid), tostring(filters.Classic), tostring(filters.Forever)))
    end

    self:Info("Optional TomTom", isAddonLoaded("TomTom") and "loaded" or "not loaded; TomTom-specific navigation is skipped")
    self:Info("Optional Atlas", (_G.Atlas or isAddonLoaded("Atlas")) and "loaded" or "not loaded")
    self:Line("")
end

function Runner:PrepareBrowserTest()
    self:Line("--- Taint-safe world-map browser simulation ---")

    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        self:Skip("Interactive browser simulation", "player is in combat lockdown; run /fitest again out of combat")
        self:Finish()
        return
    end

    if not _G.QuestMapFrame then
        local loaded, reason = tryLoadAddon("Blizzard_WorldMap")
        if loaded then self:Pass("Load Blizzard_WorldMap", reason)
        else self:Warn("Load Blizzard_WorldMap", reason) end
    else
        self:Pass("Load Blizzard_WorldMap", "QuestMapFrame already available")
    end

    local browser = ns.InstanceBrowser
    self:Test("InstanceBrowser module", function()
        return type(browser) == "table" and type(browser.Initialize) == "function" and type(browser.RefreshList) == "function",
            type(browser) == "table" and "module present" or "module missing"
    end)
    if type(browser) ~= "table" then self:Finish() return end

    self:Test("Browser initialization", function()
        local ok = browser:Initialize()
        return ok == true, "Initialize()=" .. tostring(ok)
    end)

    local qmf = _G.QuestMapFrame
    local tab = _G.ForeverInstancesMapBrowserTab
    local search = _G.ForeverInstancesMapBrowserSearchBox
    if not qmf or not tab then
        self:Fail("Detached side-tab creation", "QuestMapFrame or ForeverInstancesMapBrowserTab missing")
        self:Finish()
        return
    end
    self:Pass("Detached side-tab creation", "frame=" .. tostring(tab:GetName() or "anonymous"))

    local previousSearch = search and search:GetText() or ""
    local profile = type(ns.GetProfile) == "function" and ns.GetProfile() or nil
    local collapsed = profile and profile.browser and profile.browser.collapsed
    local previousCollapsed = shallowCopy(collapsed)
    local browserTransient = type(browser.CaptureDebugTransientState) == "function" and browser:CaptureDebugTransientState() or nil

    local worldWasShown = _G.WorldMapFrame and _G.WorldMapFrame:IsShown() or false
    local previousMapID
    if _G.WorldMapFrame and type(_G.WorldMapFrame.GetMapID) == "function" then
        local ok, value = pcall(_G.WorldMapFrame.GetMapID, _G.WorldMapFrame)
        if ok then previousMapID = value end
    end

    self:AddRestore(function()
        if search and search.SetText then search:SetText(previousSearch or "") end
        if type(collapsed) == "table" then
            for key in pairs(collapsed) do collapsed[key] = nil end
            for key, value in pairs(previousCollapsed) do collapsed[key] = value end
        end
        if type(browser.RestoreDebugTransientState) == "function" then
            browser:RestoreDebugTransientState(browserTransient)
        elseif browser and type(browser.Hide) == "function" then
            browser:Hide()
        end
        if browser and type(browser.RefreshList) == "function" then browser:RefreshList() end
        if _G.WorldMapFrame then
            if previousMapID and C_Map and type(C_Map.OpenWorldMap) == "function" then
                pcall(C_Map.OpenWorldMap, previousMapID)
            end
            if worldWasShown then
                pcall(_G.WorldMapFrame.Show, _G.WorldMapFrame)
            else
                pcall(_G.WorldMapFrame.Hide, _G.WorldMapFrame)
            end
        end
    end)

    if type(collapsed) == "table" then
        collapsed["Eastern Kingdoms"] = false
        collapsed["Kalimdor"] = false
    end
    browser:RefreshList()

    self:Test("Blizzard map tables remain untouched", function()
        local state = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
        return state.safeDetached == true
            and state.blizzardTabArrayTouched == false
            and state.blizzardContentArrayTouched == false,
            string.format("safeDetached=%s TabButtonsTouched=%s ContentFramesTouched=%s",
                tostring(state.safeDetached), tostring(state.blizzardTabArrayTouched), tostring(state.blizzardContentArrayTouched))
    end)

    self:Test("No addon-owned MapCanvas marker", function()
        return _G.ForeverInstancesBrowserMapMarker == nil,
            "ForeverInstancesBrowserMapMarker=" .. tostring(_G.ForeverInstancesBrowserMapMarker)
    end)

    self:Test("Repeated initialization stays detached", function()
        browser:Initialize()
        local state = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
        return state.safeDetached == true, "safeDetached=" .. tostring(state.safeDetached)
    end)

    self:Test("Tab anchor/size", function()
        local width, height = tab:GetSize()
        local points = tab.GetNumPoints and tab:GetNumPoints() or 0
        return width and width > 0 and height and height > 0 and points > 0,
            string.format("size=%.0fx%.0f anchors=%d", width or 0, height or 0, points or 0)
    end)

    self:Test("Quest-style panel / scroll surface", function()
        local scroll = _G.ForeverInstancesMapBrowserScrollFrame
        local p = _G.ForeverInstancesMapBrowserPanel
        local outer = _G.ForeverInstancesMapBrowserOuter
        if not scroll or not p or not outer then return false, "scroll/panel/outer frame missing" end
        if browser and type(browser.SyncPanelGeometry) == "function" then browser:SyncPanelGeometry() end
        local sw, sh = scroll:GetSize()
        local pw, ph = p:GetSize()
        local reference = qmf and qmf.QuestsFrame
        local rw, rh = 0, 0
        if reference then rw, rh = reference:GetSize() end
        local bar = p.scrollBar
        local state = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
        local geometryOK = sw and sw > 0 and sh and sh > 0 and pw and pw > 0 and ph and ph > 0
        if rw and rw > 1 then geometryOK = geometryOK and math.abs(pw - rw) <= 2 end
        if rh and rh > 30 then geometryOK = geometryOK and math.abs(ph - (rh - 29)) <= 2 end
        geometryOK = geometryOK and math.abs(sw - (pw - 8)) <= 2 and math.abs(sh - (ph - 8)) <= 2
        return geometryOK and scroll:GetParent() == p and bar ~= nil and state.manualQuestScroll == true,
            string.format("panel=%.0fx%.0f scroll=%.0fx%.0f questFrame=%.0fx%.0f scrollbar=%s manual=%s",
                pw or 0, ph or 0, sw or 0, sh or 0, rw or 0, rh or 0, tostring(bar ~= nil), tostring(state.manualQuestScroll))
    end)

    self:Test("Quest-style detached side-tab chain", function()
        local state = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
        local layout = type(browser.GetTabLayoutDebug) == "function" and browser:GetTabLayoutDebug() or {}
        local names = {}
        if type(layout.candidates) == "table" then
            for _, info in ipairs(layout.candidates) do names[#names + 1] = tostring(info.name or "anonymous") end
        end
        local anchorOK = state.tabAnchorMode == "managed-chain"
            or state.tabAnchorMode == "passive-side-tab"
            or state.tabAnchorMode == "fallback-quest-tab"
            or state.tabAnchorMode == "stock-maplegend"
        return state.questStyleTab == true
            and state.usesBlizzardDungeonAtlas == true
            and state.tabDisplayMode == nil
            and anchorOK
            and (state.tabCollisions or 0) == 0,
            string.format("questStyle=%s atlas=%s ownDisplayMode=%s anchor=%s:%s managed=%s questStylePeers=%s customManaged=%s customUnmanaged=%s passive=%s handoffHooks=%s collisions=%s tabs=%s",
                tostring(state.questStyleTab), tostring(state.usesBlizzardDungeonAtlas), tostring(state.tabDisplayMode),
                tostring(state.tabAnchorMode), tostring(state.tabAnchorName), tostring(state.sideTabsDetected),
                tostring(state.questStyleSideTabsDetected), tostring(state.customManagedSideTabsDetected), tostring(state.customUnmanagedSideTabsDetected), tostring(state.passiveSideTabsDetected),
                tostring(state.externalTabHandoffHooks), tostring(state.tabCollisions),
                #names > 0 and table.concat(names, ",") or "none")
    end)

    self:Test("External side-tab handoff coverage", function()
        local state = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
        local targets = (tonumber(state.customManagedSideTabsDetected) or 0)
            + (tonumber(state.customUnmanagedSideTabsDetected) or 0)
            + (tonumber(state.passiveSideTabsDetected) or 0)
        local hooks = tonumber(state.externalTabHandoffHooks) or 0
        return hooks >= targets and state.externalTabHandoffPhase == "post-mouseup",
            string.format("targets=%d passive=%s hooks=%d phase=%s", targets, tostring(state.passiveSideTabsDetected), hooks, tostring(state.externalTabHandoffPhase))
    end)

    self:Test("Simulated addon side-tab click", function()
        local handler = tab.GetScript and tab:GetScript("OnMouseUp")
        if type(handler) ~= "function" then return false, "OnMouseUp handler unavailable" end
        handler(tab, "LeftButton")
        return true, "addon OnMouseUp invoked"
    end)

    self:Later(0.10, function() self:InspectBrowserOpen(search) end)
end

function Runner:InspectBrowserOpen(search)
    local browser = ns.InstanceBrowser
    local tab = _G.ForeverInstancesMapBrowserTab

    self:Test("Browser panel became visible", function()
        local shown = browser and type(browser.IsShown) == "function" and browser:IsShown()
        return shown == true, "shown=" .. tostring(shown)
    end)

    self:Test("Side tab selected state", function()
        local state = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
        return state.tabSelected == true, "selected=" .. tostring(state.tabSelected)
    end)

    self:Test("Custom side-tab visual exclusivity", function()
        local state = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
        local selectedPeers = tonumber(state.externalSelectedGlows) or 0
        return selectedPeers == 0,
            string.format("customManaged=%s customUnmanaged=%s passive=%s externalSelectedGlows=%d",
                tostring(state.customManagedSideTabsDetected), tostring(state.customUnmanagedSideTabsDetected), tostring(state.passiveSideTabsDetected), selectedPeers)
    end)

    self:Test("Browser full-list rendering", function()
        if type(browser.GetDebugState) ~= "function" then return false, "GetDebugState missing" end
        local state = browser:GetDebugState()
        return state.visibleRows == 44 and state.visibleHeaders == 2,
            string.format("rows=%s headers=%s", tostring(state.visibleRows), tostring(state.visibleHeaders))
    end)

    if not search then
        self:Fail("Search box simulation", "ForeverInstancesMapBrowserSearchBox missing")
        self:Finish()
        return
    end

    if type(browser.Hide) == "function" then browser:Hide() end
    self:Later(0.06, function() self:InspectBrowserHide(search) end)
end

function Runner:InspectBrowserHide(search)
    local browser = ns.InstanceBrowser
    local tab = _G.ForeverInstancesMapBrowserTab
    self:Test("Detached browser hides cleanly", function()
        local shown = browser and type(browser.IsShown) == "function" and browser:IsShown()
        local state = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
        return shown == false and state.tabSelected ~= true,
            "browserShown=" .. tostring(shown) .. " tabSelected=" .. tostring(state.tabSelected)
    end)

    if type(browser.Show) == "function" then browser:Show() end
    self:Later(0.06, function() self:InspectBrowserReopen(search) end)
end

function Runner:InspectBrowserReopen(search)
    local browser = ns.InstanceBrowser
    self:Test("Detached browser reopens cleanly", function()
        local shown = browser and type(browser.IsShown) == "function" and browser:IsShown()
        return shown == true, "shown=" .. tostring(shown)
    end)

    -- Close the whole World Map while our tab is selected, then open it again.
    -- The addon must NOT override Blizzard's normal map-open lifecycle. The
    -- browser selection is cleared on close and the previously active native
    -- display mode is restored before the map is shown again.
    if _G.WorldMapFrame and type(_G.WorldMapFrame.Show) == "function" and type(_G.WorldMapFrame.Hide) == "function" then
        pcall(_G.WorldMapFrame.Show, _G.WorldMapFrame)
        self:Later(0.05, function()
            pcall(_G.WorldMapFrame.Hide, _G.WorldMapFrame)
            self:Later(0.05, function()
                pcall(_G.WorldMapFrame.Show, _G.WorldMapFrame)
                self:Later(0.18, function() self:InspectWorldMapReopen(search) end)
            end)
        end)
    else
        self:Skip("Blizzard default map reopen lifecycle", "WorldMapFrame Show/Hide unavailable")
        search:SetText("Deadmines")
        if browser and type(browser.RefreshList) == "function" then browser:RefreshList() end
        self:Later(0.08, function() self:InspectSearchResult(search) end)
    end
end

function Runner:InspectWorldMapReopen(search)
    local browser = ns.InstanceBrowser
    self:Test("Blizzard default map reopen lifecycle", function()
        local state = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
        local nativeVisible = state.nativeQuestsShown == true
            or state.nativeEventsShown == true
            or state.nativeLegendShown == true
        local ok = state.shown ~= true and state.tabSelected ~= true
            and state.displayMode ~= nil and nativeVisible
        return ok, string.format("browser=%s selected=%s quests=%s events=%s legend=%s displayMode=%s",
            tostring(state.shown), tostring(state.tabSelected), tostring(state.nativeQuestsShown),
            tostring(state.nativeEventsShown), tostring(state.nativeLegendShown), tostring(state.displayMode))
    end)

    -- Continue the browser-specific tests only after an explicit user-style
    -- selection. Reopening the World Map itself must never select our tab.
    if browser and type(browser.Show) == "function" then browser:Show() end
    self:Later(0.06, function()
        search:SetText("Deadmines")
        if browser and type(browser.RefreshList) == "function" then browser:RefreshList() end
        self:Later(0.08, function() self:InspectSearchResult(search) end)
    end)
end

function Runner:InspectSearchResult(search)
    local browser = ns.InstanceBrowser
    self:Test("Search rendering: Deadmines", function()
        local state = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
        local pureCount = type(browser.DebugCountMatches) == "function" and browser:DebugCountMatches("Deadmines") or nil
        return state.visibleRows == 1 and pureCount == 1,
            string.format("rendered=%s databaseMatches=%s", tostring(state.visibleRows), tostring(pureCount))
    end)

    search:SetText("zzzz_diagnostic_no_match_zzzz")
    if browser and type(browser.RefreshList) == "function" then browser:RefreshList() end
    self:Later(0.08, function()
        self:Test("Search rendering: no match", function()
            local state = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
            return state.visibleRows == 0, "rendered=" .. tostring(state.visibleRows)
        end)
        self:RunRepresentativeMapAction()
    end)
end

function Runner:RunRepresentativeMapAction()
    local browser = ns.InstanceBrowser
    if not browser or type(browser.ShowInstanceOnMap) ~= "function" then
        self:Fail("Representative row/map action", "Browser:ShowInstanceOnMap unavailable")
        self:Finish()
        return
    end

    local target
    for _, entry in ipairs(ns.DB.GetBrowserEntries()) do
        if entry.id == "deadmines" then target = entry.instance break end
    end
    if not target then
        self:Fail("Representative row/map action", "deadmines record missing")
        self:Finish()
        return
    end

    local ok, result = pcall(browser.ShowInstanceOnMap, browser, target)
    if not ok then
        self:Fail("Representative row/map action", tostring(result))
        self:Finish()
        return
    end
    if result ~= true then
        self:Fail("Representative row/map action", "ShowInstanceOnMap returned " .. tostring(result))
        self:Finish()
        return
    end
    self:Pass("Representative row/map action", "The Deadmines requested through the same browser navigation path as a row click")
    self:Later(0.12, function() self:InspectRepresentativeMapAction(target) end)
end

function Runner:InspectRepresentativeMapAction(target)
    local browser = ns.InstanceBrowser
    local debugState = type(browser.GetDebugState) == "function" and browser:GetDebugState() or {}
    local currentMapID
    if _G.WorldMapFrame and type(_G.WorldMapFrame.GetMapID) == "function" then
        local ok, value = pcall(_G.WorldMapFrame.GetMapID, _G.WorldMapFrame)
        if ok then currentMapID = value end
    end

    self:Test("Representative map switched to target zone", function()
        return currentMapID == target.mapID, "currentMapID=" .. tostring(currentMapID) .. " expected=" .. tostring(target.mapID)
    end)
    self:Test("Representative navigation remains MapCanvas-detached", function()
        return debugState.activePinName == target.name
            and debugState.activePinMapID == target.mapID
            and debugState.markerShown == false
            and _G.ForeverInstancesBrowserMapMarker == nil,
            "name=" .. tostring(debugState.activePinName) .. " mapID=" .. tostring(debugState.activePinMapID)
                .. " markerFrame=" .. tostring(_G.ForeverInstancesBrowserMapMarker)
    end)
    self:Finish()
end

function Runner:CaptureEvent(event, ...)
    if self.finished then return end
    self.capturedEvents = self.capturedEvents + 1
    local args = {}
    for index = 1, select("#", ...) do
        args[#args + 1] = tostring(select(index, ...))
    end
    local detail = table.concat(args, " | ")
    local elapsed = (GetTime and GetTime() or self.startedAt) - self.startedAt
    detail = string.format("t=+%.3fs | %s", tonumber(elapsed) or 0, detail)
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        local offender = tostring(select(1, ...))
        if offender == addonName or offender == "Forever_Instances" then
            self:Fail("Captured event " .. event, detail)
        else
            self:Warn("Captured event " .. event, detail)
        end
    elseif event == "LUA_WARNING" or event == "UI_ERROR_MESSAGE" then
        self:Warn("Captured event " .. event, detail)
    else
        self:Info("Captured event " .. event, detail)
    end
end

function Runner:Finish()
    if self.finished then return end
    self.finished = true

    self:RestoreState()
    self:RestoreErrorCapture()

    if self.capturedEvents == 0 then
        self:Pass("UI/protected-action event capture", "no registered error events were raised during the test")
    else
        self:Info("UI/protected-action event capture", "captured=" .. tostring(self.capturedEvents))
    end

    local memoryAfter = collectgarbage and collectgarbage("count") or nil
    local elapsed = (GetTime and GetTime() or self.startedAt) - self.startedAt
    self:Line("")
    self:Line("--- Summary ---")
    self:Line("PASS: " .. tostring(self.counts.PASS or 0))
    self:Line("FAIL: " .. tostring(self.counts.FAIL or 0))
    self:Line("WARN: " .. tostring(self.counts.WARN or 0))
    self:Line("SKIP: " .. tostring(self.counts.SKIP or 0))
    self:Line("INFO: " .. tostring(self.counts.INFO or 0))
    self:Line("Captured Lua errors: " .. tostring(self.capturedErrors))
    self:Line("Captured UI/protected-action events: " .. tostring(self.capturedEvents))
    self:Line(string.format("Elapsed: %.3f sec", tonumber(elapsed) or 0))
    if self.memoryBefore and memoryAfter then
        self:Line(string.format("Lua memory: %.1f KB -> %.1f KB (delta %+.1f KB)", self.memoryBefore, memoryAfter, memoryAfter - self.memoryBefore))
    end
    self:Line("")
    self:Line("Result meaning: FAIL = expected behavior did not happen; WARN = suspicious/non-fatal client-specific condition; SKIP = dependency/API/state prevented that check.")
    self:Line("Copy this entire report after the test and attach it to the bug report/development chat.")

    local report = table.concat(self.lines, "\n")
    local summary = string.format(L("DIAG_SUMMARY"), self.counts.PASS or 0, self.counts.FAIL or 0, self.counts.WARN or 0, self.counts.SKIP or 0)
    showReport(report, summary)
    chat(L("DIAG_COMPLETE_CHAT"))
    activeRun = nil
end

function Runner:Start()
    self:Header()
    self:InstallErrorCapture()
    self:RunCoreTests()
    self:PrepareBrowserTest()
end

local eventFrame = CreateFrame("Frame")
for _, event in ipairs({ "UI_ERROR_MESSAGE", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "LUA_WARNING" }) do
    pcall(eventFrame.RegisterEvent, eventFrame, event)
end
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if activeRun and not activeRun.finished then activeRun:CaptureEvent(event, ...) end
end)

function Diagnostic:Run()
    if activeRun and not activeRun.finished then
        chat(L("DIAG_ALREADY_RUNNING"))
        return false
    end

    if type(InCombatLockdown) == "function" and InCombatLockdown() then
        chat(L("DIAG_COMBAT_BLOCKED"))
        return false
    end

    runSerial = runSerial + 1
    local runner = setmetatable({
        serial = runSerial,
        lines = {},
        counts = {},
        restores = {},
        capturedErrors = 0,
        capturedEvents = 0,
        startedAt = GetTime and GetTime() or 0,
        memoryBefore = collectgarbage and collectgarbage("count") or nil,
        finished = false,
    }, Runner)
    activeRun = runner

    if reportFrame then reportFrame:Hide() end
    chat(L("DIAG_STARTED"))

    local ok, err = xpcall(function() runner:Start() end, function(e)
        return tostring(e) .. (safeDebugStack() ~= "" and ("\n" .. safeDebugStack()) or "")
    end)
    if not ok then
        runner:Fail("Diagnostic runner startup", err)
        runner.capturedErrors = runner.capturedErrors + 1
        runner:Finish()
        return false
    end
    return true
end

function Diagnostic:ShowLastReport()
    if lastReport == "" then
        chat(L("DIAG_NO_REPORT"))
        return false
    end
    showReport(lastReport, L("DIAG_LAST_REPORT"))
    return true
end

function Diagnostic:GetLastReport()
    return lastReport
end

SLASH_FOREVERINSTANCESTEST1 = "/fitest"
SLASH_FOREVERINSTANCESTEST2 = "/foreverinstancetest"
SlashCmdList.FOREVERINSTANCESTEST = function(message)
    local command = trim(message):lower()
    if command == "show" or command == "log" or command == "report" then
        Diagnostic:ShowLastReport()
    elseif command == "help" or command == "?" then
        chat(L("DIAG_COMMAND_HELP"))
    else
        Diagnostic:Run()
    end
end
