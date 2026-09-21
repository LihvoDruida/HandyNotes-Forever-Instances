-- HandyNotes_ForeverInstances localization
-- Runtime language can be switched without changing the client locale.
local addonName, ns = ...

local Locale = {
    enUS = {
        ADDON_DESC = "Dungeon and raid entrance locations for World of Warcraft: Forever.",
        DESCRIPTION = "Forever-only HandyNotes database. New database coordinates take priority; old-addon coordinates are used only when the new record has no coordinates.",
        LANGUAGE = "Language",
        LANGUAGE_DESC = "Auto follows the WoW client locale. Unsupported client locales fall back to English.",
        LANGUAGE_AUTO = "Auto (client: %s)",
        LANGUAGE_ENGLISH = "English",
        LANGUAGE_UKRAINIAN = "Українська",

        ZONE_ICON_SCALE = "Zone icon scale",
        ZONE_ICON_OPACITY = "Zone icon opacity",
        CONTINENT_ICON_SCALE = "Continent icon scale",
        CONTINENT_ICON_OPACITY = "Continent icon opacity",
        SHOW_CONTINENT = "Show on continent maps",
        SHOW_AZEROTH = "Show on Azeroth / global map",
        TOMTOM_WAYPOINTS = "TomTom right-click waypoints",
        SHOW_COORDINATES = "Show coordinates in tooltip",
        SHOW_DESCRIPTIONS = "Show instance descriptions in tooltip",
        SHOW_NOTES = "Show database notes in tooltip",
        FILTERS = "Filters",
        DUNGEONS = "Dungeons",
        RAIDS = "Raids",
        CLASSIC_INSTANCES = "Classic-era instances available in Forever",
        FOREVER_INSTANCES = "Forever-new instances",

        INSTANCE = "Instance",
        DUNGEON = "Dungeon",
        RAID = "Raid",
        CLASSIC = "Classic",
        FOREVER = "Forever",
        NEW = "New",
        UPDATED = "Updated",
        BOSSES = "Bosses: %d",
        FOREVER_CHANGE = "Forever: %s",
        DUNGEON_LOOT_UPDATE = "Dungeon boss loot is reworked across both returning and new dungeons, including guaranteed rare-quality boss rewards and many new items.",
        LEVEL_SHORT = "Lv",
        PLAYERS = "%d players",
        PLAYER_RANGE = "%d-%d players",
        UP_TO_PLAYERS = "up to %d players",
        LOCATION = "Location: %s",
        ENTRANCE = "Entrance: %.1f, %.1f%s",
        LEGACY_FALLBACK = "  (legacy fallback)",
        WINGS = "Wings:",
        WING = "Wing",
        RIGHT_CLICK_TOMTOM = "Right-click: set TomTom waypoint",
    },

    ukUA = {
        ADDON_DESC = "Розташування входів до підземель і рейдів у World of Warcraft: Forever.",
        DESCRIPTION = "База HandyNotes лише для Forever. Координати з нової бази мають пріоритет; координати зі старого адона використовуються тільки тоді, коли в новому записі координати відсутні.",
        LANGUAGE = "Мова",
        LANGUAGE_DESC = "Автоматичний режим використовує мову клієнта WoW. Для непідтримуваних мов використовується англійська.",
        LANGUAGE_AUTO = "Автоматично (клієнт: %s)",
        LANGUAGE_ENGLISH = "English",
        LANGUAGE_UKRAINIAN = "Українська",

        ZONE_ICON_SCALE = "Масштаб іконок у зоні",
        ZONE_ICON_OPACITY = "Прозорість іконок у зоні",
        CONTINENT_ICON_SCALE = "Масштаб іконок на континенті",
        CONTINENT_ICON_OPACITY = "Прозорість іконок на континенті",
        SHOW_CONTINENT = "Показувати на картах континентів",
        SHOW_AZEROTH = "Показувати на глобальній карті Азероту",
        TOMTOM_WAYPOINTS = "Точки TomTom правою кнопкою миші",
        SHOW_COORDINATES = "Показувати координати в підказці",
        SHOW_DESCRIPTIONS = "Показувати описи інстансів у підказці",
        SHOW_NOTES = "Показувати примітки бази в підказці",
        FILTERS = "Фільтри",
        DUNGEONS = "Підземелля",
        RAIDS = "Рейди",
        CLASSIC_INSTANCES = "Класичні інстанси, доступні у Forever",
        FOREVER_INSTANCES = "Нові інстанси Forever",

        INSTANCE = "Інстанс",
        DUNGEON = "Підземелля",
        RAID = "Рейд",
        CLASSIC = "Класика",
        FOREVER = "Forever",
        NEW = "Нове",
        UPDATED = "Змінено",
        BOSSES = "Боси: %d",
        FOREVER_CHANGE = "Зміни Forever: %s",
        DUNGEON_LOOT_UPDATE = "Перероблено здобич із босів як у класичних, так і в нових підземеллях: боси гарантовано дають рідкісні предмети, а до таблиць здобичі додано багато нових речей.",
        LEVEL_SHORT = "Рів.",
        PLAYERS = "%d гравців",
        PLAYER_RANGE = "%d-%d гравців",
        UP_TO_PLAYERS = "до %d гравців",
        LOCATION = "Розташування: %s",
        ENTRANCE = "Вхід: %.1f, %.1f%s",
        LEGACY_FALLBACK = "  (координати зі старої бази)",
        WINGS = "Крила:",
        WING = "Крило",
        RIGHT_CLICK_TOMTOM = "ПКМ: створити точку TomTom",
    },
}

local UkrainianNotes = {
    ["WoWHandbook currently places this in Darkshore; Warcraft Tavern and Classic references place the entrance at The Zoram Strand in Ashenvale."] = "WoWHandbook наразі розміщує цей вхід у Темнобережжі; Warcraft Tavern і класичні джерела вказують на Узбережжя Зорам в Ясенедолі.",
    ["Warcraft Tavern entrance coordinate; WoWHandbook uses a different point in the Gnomeregan exterior complex."] = "Координата входу за Warcraft Tavern; WoWHandbook використовує іншу точку у зовнішньому комплексі Гномреґана.",
    ["WoWHandbook's ~50.9,92.9 agrees with Classic references for the actual instance entrance; some guides use an earlier approach point around 43,95."] = "Координати WoWHandbook ~50.9,92.9 збігаються з класичними джерелами для фактичного входу; деякі гайди використовують більш ранню точку підходу приблизно 43,95.",
    ["WoWHandbook currently lists 77.3,35.9. Classic entrance references and the actual temple location place the exterior entrance around 69,54."] = "WoWHandbook наразі вказує 77.3,35.9. Класичні джерела та фактичне розташування храму ставлять зовнішній вхід приблизно на 69,54.",
    ["Inside Ironforge, in the High Seat / throne hall."] = "Усередині Стальгорна, у Високому Престолі / тронній залі.",
    ["Inner courtyard of the Lordaeron ruins above Undercity; approach through the former Lordaeron main gate."] = "Внутрішній двір руїн Лордерона над Підмістом; підхід через колишню головну браму Лордерона.",
    ["Dungeon entrance at Whelgar's Excavation Site in Wetlands."] = "Вхід до підземелля на Розкопках Вельґара в Болотяних угіддях.",
    ["Entrance beneath the Violet Dome of Dalaran."] = "Вхід під Фіолетовим Куполом Даларана.",
    ["Underwater entrance near the north-west coast; dive toward the ruined troll columns. Level range 35-40 uses the corrected Forever table."] = "Підводний вхід біля північно-західного узбережжя; пірнайте в напрямку зруйнованих трольських колон. Діапазон рівнів 35-40 взято з виправленої таблиці Forever.",
    ["Stronghold in the wooded eastern ravine. Level range 40-45 is the corrected Blizzard-published range."] = "Фортеця в лісистій східній ущелині. Діапазон рівнів 40-45 відповідає виправленим даним, опублікованим Blizzard.",
    ["Entrance on Alcaz Island, leading into the prison complex beneath the main fort."] = "Вхід на острові Алькац веде до тюремного комплексу під головною фортецею.",
    ["Far north of Azshara, behind the large furbolg gate. The dungeon also connects onward toward Barrow Deeps."] = "Далеко на півночі Азшари, за великою брамою фурболґів. Підземелля також має сполучення в напрямку Barrow Deeps.",
    ["High on the rocky slopes along the northern wall of Un'Goro Crater."] = "Високо на кам'янистих схилах уздовж північної стіни кратера Ун'Ґоро.",
    ["Ground entry is the Plaguewood teleport spire; the necropolis itself floats above the zone."] = "Наземний вхід — телепортаційний шпиль у Чумному Лісі; сам некрополь ширяє над зоною.",
    ["Warcraft Tavern identifies a Mount Hyjal entrance and says two other entrances are still TBA."] = "Warcraft Tavern вказує один вхід на горі Гіджал; ще два входи поки позначені як TBA.",
    ["Location is confirmed as Mount Hyjal; a reliable entrance coordinate is not yet published in the checked sources."] = "Розташування на горі Гіджал підтверджене, але надійні координати входу в перевірених джерелах поки не опубліковані.",
}

local UkrainianNames = {
    ["Graveyard"] = "Цвинтар",
    ["Library"] = "Бібліотека",
    ["Armory"] = "Збройова",
    ["Cathedral"] = "Собор",
    ["Lower Blackrock Spire"] = "Нижня частина Шпиля Чорної гори",
    ["Upper Blackrock Spire"] = "Верхня частина Шпиля Чорної гори",
    ["Dire Maul East"] = "Забутий Міст — Схід",
    ["Dire Maul West"] = "Забутий Міст — Захід",
    ["Dire Maul North"] = "Забутий Міст — Північ",
    ["Stratholme - Living"] = "Стратгольм — Живі",
    ["Stratholme - Undead"] = "Стратгольм — Нежить",
}

local function rawClientLocale()
    if type(GetLocale) == "function" then
        local ok, value = pcall(GetLocale)
        if ok and type(value) == "string" and value ~= "" then
            return value
        end
    end
    return "enUS"
end

function ns.GetClientLocaleCode()
    return rawClientLocale()
end

function ns.ResolveLanguage(preference)
    if preference == "ukUA" or preference == "enUS" then
        return preference
    end

    local client = rawClientLocale()
    if client == "ukUA" then
        return "ukUA"
    end
    return "enUS"
end

function ns.GetLocalizedText(key, language)
    language = language or "enUS"
    local bucket = Locale[language] or Locale.enUS
    return bucket[key] or Locale.enUS[key] or key
end

function ns.LocalizeDatabaseText(value, language)
    if language == "ukUA" and type(value) == "string" then
        return UkrainianNotes[value] or value
    end
    return value
end

function ns.LocalizeDisplayName(value, language)
    if language == "ukUA" and type(value) == "string" then
        return UkrainianNames[value] or value
    end
    return value
end

ns.Locale = Locale
