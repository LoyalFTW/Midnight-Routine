local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local HOLIDAY_TIMEWALKING = {
    { id = 559, key = "burning" },
    { id = 562, key = "wrath" },
    { id = 587, key = "cataclysm" },
    { id = 643, key = "mists" },
    { id = 1056, key = "draenor" },
    { id = 1263, key = "legion" },
    { id = 1271, key = "legion" },
    { id = 1326 },
    { id = 1400 },
    { id = 1404 },
    { id = 1500 },
    { id = 1508, key = "classic" },
    { id = 1669, key = "bfa" },
    { id = 1703, key = "shadowlands" },
    { id = 1722, key = "dragonflight" },
}

local function CombineQuestIds(...)
    local merged = {}
    for i = 1, select("#", ...) do
        local source = select(i, ...)
        if type(source) == "table" then
            for _, questId in ipairs(source) do
                merged[#merged + 1] = questId
            end
        end
    end
    return merged
end

local TIMEWALKING_DUNGEON_QUESTS = {
    classic = {
        current = { 83274, 85947 },
        compat = {},
        fallbackName = "An Original Path Through Time",
    },
    burning = {
        current = { 93608, 83363 },
        compat = { 39020 },
        fallbackName = "A Burning Path Through Time",
    },
    wrath = {
        current = { 83365, 85949 },
        compat = { 39021 },
        fallbackName = "A Frozen Path Through Time",
    },
    cataclysm = {
        current = { 93611, 83359 },
        compat = { 40792 },
        fallbackName = "A Shattered Path Through Time",
    },
    mists = {
        current = { 93612, 83362 },
        compat = { 72725, 62635, 53035, 45799, 40785 },
        fallbackName = "A Shrouded Path Through Time",
    },
    draenor = {
        current = { 93613, 83364 },
        compat = { 45566, 54995 },
        fallbackName = "A Savage Path Through Time",
    },
    legion = {
        current = { 83360 },
        compat = { 62786 },
        fallbackName = "A Fel Path Through Time",
    },
    bfa = {
        current = { 88805 },
        compat = {},
        fallbackName = "A Scarred Path Through Time",
    },
    shadowlands = {
        current = { 93628 },
        compat = {},
        fallbackName = "A Shadowed Path Through Time",
    },
    dragonflight = {
        current = { 93497, 93495 },
        compat = {},
        fallbackName = "A Soaring Path Through Time",
    },
}

local TIMEWALKING_DUNGEON_WEEKLIES = CombineQuestIds(
    TIMEWALKING_DUNGEON_QUESTS.classic.current,
    TIMEWALKING_DUNGEON_QUESTS.classic.compat,
    TIMEWALKING_DUNGEON_QUESTS.burning.current,
    TIMEWALKING_DUNGEON_QUESTS.burning.compat,
    TIMEWALKING_DUNGEON_QUESTS.wrath.current,
    TIMEWALKING_DUNGEON_QUESTS.wrath.compat,
    TIMEWALKING_DUNGEON_QUESTS.cataclysm.current,
    TIMEWALKING_DUNGEON_QUESTS.cataclysm.compat,
    TIMEWALKING_DUNGEON_QUESTS.mists.current,
    TIMEWALKING_DUNGEON_QUESTS.mists.compat,
    TIMEWALKING_DUNGEON_QUESTS.draenor.current,
    TIMEWALKING_DUNGEON_QUESTS.draenor.compat,
    TIMEWALKING_DUNGEON_QUESTS.legion.current,
    TIMEWALKING_DUNGEON_QUESTS.legion.compat,
    TIMEWALKING_DUNGEON_QUESTS.bfa.current,
    TIMEWALKING_DUNGEON_QUESTS.shadowlands.current,
    TIMEWALKING_DUNGEON_QUESTS.shadowlands.compat,
    TIMEWALKING_DUNGEON_QUESTS.dragonflight.current,
    TIMEWALKING_DUNGEON_QUESTS.dragonflight.compat
)

local TIMEWALKING_RAID_WEEKLIES = {
    82817,
    47523,
    50316,
    57637,
}

local TIMEWALKING_DUNGEON_PICKUP_LOCATION = {
    zone = 2393,
    x = 48.4,
    y = 64.5,
}

local TIMEWALKING_RAID_PICKUP_LOCATIONS = {
    [82817] = {
        alliance = { zone = 84, x = 56.0, y = 19.0 },
        horde = { zone = 85, x = 52.8, y = 83.0 },
    },
    [47523] = { zone = 111, x = 54.6, y = 39.6 },
    [50316] = { zone = 125, x = 51.0, y = 47.6 },
    [57637] = {
        alliance = { zone = 84, x = 76.6, y = 16.6 },
        horde = { zone = 85, x = 52.0, y = 41.6 },
    },
}

local TIMEWALKING_EVENT_HINTS = {
    {
        key = "classic",
        holidayMatches = { "classic", "original", "past" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.classic.current, TIMEWALKING_DUNGEON_QUESTS.classic.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.classic.fallbackName,
        raidQuestIds = { 82817 },
        raidFallbackName = "Disturbance Detected: Blackrock Depths",
        hasRaid = true,
    },
    {
        key = "burning",
        holidayMatches = { "burning", "outland", "twistingnether" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.burning.current, TIMEWALKING_DUNGEON_QUESTS.burning.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.burning.fallbackName,
        raidQuestIds = { 47523 },
        raidFallbackName = "Disturbance Detected: Black Temple",
        hasRaid = true,
    },
    {
        key = "wrath",
        holidayMatches = { "frozen", "northrend", "scourge", "lichking" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.wrath.current, TIMEWALKING_DUNGEON_QUESTS.wrath.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.wrath.fallbackName,
        raidQuestIds = { 50316 },
        raidFallbackName = "Disturbance Detected: Ulduar",
        hasRaid = true,
    },
    {
        key = "cataclysm",
        holidayMatches = { "shattered", "cataclysm", "destroyer" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.cataclysm.current, TIMEWALKING_DUNGEON_QUESTS.cataclysm.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.cataclysm.fallbackName,
        raidQuestIds = { 57637 },
        raidFallbackName = "Disturbance Detected: Firelands",
        hasRaid = true,
    },
    {
        key = "mists",
        holidayMatches = { "mist", "pandaria", "shrouded" },
        auraSpellId = 335151,
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.mists.current, TIMEWALKING_DUNGEON_QUESTS.mists.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.mists.fallbackName,
        hasRaid = false,
    },
    {
        key = "draenor",
        holidayMatches = { "savage", "draenor", "iron" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.draenor.current, TIMEWALKING_DUNGEON_QUESTS.draenor.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.draenor.fallbackName,
        hasRaid = false,
    },
    {
        key = "legion",
        holidayMatches = { "fel", "legion" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.legion.current, TIMEWALKING_DUNGEON_QUESTS.legion.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.legion.fallbackName,
        hasRaid = false,
    },
    {
        key = "bfa",
        holidayMatches = { "scarred", "azeroth" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.bfa.current, TIMEWALKING_DUNGEON_QUESTS.bfa.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.bfa.fallbackName,
        hasRaid = false,
    },
    {
        key = "shadowlands",
        holidayMatches = { "shadowed", "shadowlands" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.shadowlands.current, TIMEWALKING_DUNGEON_QUESTS.shadowlands.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.shadowlands.fallbackName,
        hasRaid = false,
    },
    {
        key = "dragonflight",
        holidayMatches = { "soaring", "dragonflight", "dragonflights", "dragonisles" },
        dungeonQuestIds = CombineQuestIds(TIMEWALKING_DUNGEON_QUESTS.dragonflight.current, TIMEWALKING_DUNGEON_QUESTS.dragonflight.compat),
        dungeonFallbackName = TIMEWALKING_DUNGEON_QUESTS.dragonflight.fallbackName,
        hasRaid = false,
    },
}

local TURBULENT_TIMEWAYS_EVENT_WINDOWS = {
    { startDate = 20260630, endDate = 20260707, key = "dragonflight" },
    { startDate = 20260707, endDate = 20260714, key = "bfa" },
    { startDate = 20260714, endDate = 20260721, key = "shadowlands" },
    { startDate = 20260721, endDate = 20260728, key = "classic" },
    { startDate = 20260728, endDate = 20260804, key = "burning" },
    { startDate = 20260804, endDate = 20260811, key = "dragonflight" },
}

local IsQuestCurrentlyActive
local PlayerHasAuraSpell
local GetActiveTimewalkingEventHint
local GetActiveTimewalkingHolidayInfo

local function ColorsEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end

    return a[1] == b[1] and a[2] == b[2] and a[3] == b[3]
end

local function NormalizeText(text)
    if type(text) ~= "string" then
        return ""
    end

    return text:lower():gsub("[^%a%d]", "")
end

local function CalendarTimeToEpoch(value)
    if type(value) == "number" then
        return value
    end
    if type(value) ~= "table" or not time then
        return nil
    end
    return time({
        year = value.year,
        month = value.month,
        day = value.monthDay or value.day,
        hour = value.hour or 0,
        min = value.minute or 0,
        sec = 0,
    })
end

local function GetHolidayEntryId(entry)
    if type(entry) == "table" then
        return entry.id
    end
    return entry
end

local function GetHolidayEntryKey(entry)
    if type(entry) == "table" then
        return entry.key
    end
    return nil
end

local function GetHolidayInfoIfActive(entry)
    local holidayId = GetHolidayEntryId(entry)
    if not holidayId or not C_DateAndTime or not C_DateAndTime.GetHolidayInfo then
        return nil
    end

    local info = C_DateAndTime.GetHolidayInfo(holidayId)
    if not info then
        return nil
    end

    local startTime = CalendarTimeToEpoch(info.startTime)
    local endTime = CalendarTimeToEpoch(info.endTime)
    local now = GetServerTime and GetServerTime() or (time and time()) or nil
    if startTime ~= nil and endTime ~= nil and now and now >= startTime and now <= endTime then
        return info
    end

    return nil
end

local function IsHolidayActive(entry)
    return GetHolidayInfoIfActive(entry) ~= nil
end

local function GetCurrentCalendarDate()
    if C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
        return C_DateAndTime.GetCurrentCalendarTime()
    end

    if C_Calendar and C_Calendar.GetDate then
        local dateOrWeekday, month, monthDay, year = C_Calendar.GetDate()
        if type(dateOrWeekday) == "table" then
            return dateOrWeekday
        end

        return {
            weekday = dateOrWeekday,
            month = month,
            monthDay = monthDay,
            year = year,
        }
    end

    return nil
end

local function GetTodayTimewalkingHolidayInfo()
    if not (C_Calendar and C_Calendar.GetHolidayInfo) then
        return nil
    end

    local today = GetCurrentCalendarDate()
    if not today or not today.monthDay then
        return nil
    end

    for index = 1, 20 do
        local info = C_Calendar.GetHolidayInfo(0, today.monthDay, index)
        if not info then
            break
        end

        local name = NormalizeText(info.name)
        local description = NormalizeText(info.description)
        local text = name .. description
        if text:find("timewalking", 1, true) or text:find("turbulenttimeways", 1, true) then
            local startTime = CalendarTimeToEpoch(info.startTime)
            local endTime = CalendarTimeToEpoch(info.endTime)
            local now = GetServerTime and GetServerTime() or (time and time()) or nil
            if not startTime or not endTime or (now and now >= startTime and now <= endTime) then
                return info
            end
        end
    end

    return nil
end

local function GetDateStamp(dateInfo)
    if type(dateInfo) ~= "table" or not dateInfo.year or not dateInfo.month or not dateInfo.monthDay then
        return nil
    end

    return (dateInfo.year * 10000) + (dateInfo.month * 100) + dateInfo.monthDay
end

local function GetScheduledTurbulentTimewaysKey()
    local todayStamp = GetDateStamp(GetCurrentCalendarDate())
    if not todayStamp then
        return nil
    end

    for _, window in ipairs(TURBULENT_TIMEWAYS_EVENT_WINDOWS) do
        if todayStamp >= window.startDate and todayStamp < window.endDate then
            return window.key
        end
    end

    return nil
end

local function GetTurbulentTimewaysFallbackKey(holidayInfo)
    local text = NormalizeText(holidayInfo and holidayInfo.name) .. NormalizeText(holidayInfo and holidayInfo.description)
    if text:find("turbulenttimeways", 1, true) then
        return GetScheduledTurbulentTimewaysKey()
    end

    return nil
end

local function IsTimewalkingActive()
    if GetActiveTimewalkingEventHint and GetActiveTimewalkingEventHint() then
        return true
    end

    local _, holidayInfo = GetActiveTimewalkingHolidayInfo()
    if holidayInfo then
        return true
    end

    if GetScheduledTurbulentTimewaysKey() then
        return true
    end

    for _, id in ipairs(HOLIDAY_TIMEWALKING) do
        if IsHolidayActive(id) then
            return true
        end
    end

    for _, hint in ipairs(TIMEWALKING_EVENT_HINTS) do
        if PlayerHasAuraSpell and PlayerHasAuraSpell(hint.auraSpellId) then
            return true
        end
    end

    for _, questId in ipairs(TIMEWALKING_DUNGEON_WEEKLIES) do
        if IsQuestCurrentlyActive(questId) then
            return true
        end
    end

    for _, questId in ipairs(TIMEWALKING_RAID_WEEKLIES) do
        if IsQuestCurrentlyActive(questId) then
            return true
        end
    end

    return false
end

GetActiveTimewalkingHolidayInfo = function()
    if not (C_DateAndTime and C_DateAndTime.GetHolidayInfo) then
        return nil, nil, nil
    end

    for _, entry in ipairs(HOLIDAY_TIMEWALKING) do
        local info = GetHolidayInfoIfActive(entry)
        if info then
            return GetHolidayEntryId(entry), info, GetHolidayEntryKey(entry)
        end
    end

    local todayHolidayInfo = GetTodayTimewalkingHolidayInfo()
    if todayHolidayInfo then
        return nil, todayHolidayInfo, nil
    end

    return nil, nil, nil
end

IsQuestCurrentlyActive = function(questId)
    if not questId then
        return false
    end

    if C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(questId) then
        return true
    end

    if C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questId) then
        if C_TaskQuest and C_TaskQuest.GetQuestTimeLeftSeconds then
            local timeLeft = C_TaskQuest.GetQuestTimeLeftSeconds(questId)
            if timeLeft and timeLeft > 0 then
                return true
            end
        end
    end

    if MR.IsQuestOfferVisible and MR:IsQuestOfferVisible(questId) then
        return true
    end

    if GetQuestID and GetQuestID() == questId then
        return true
    end

    return false
end

PlayerHasAuraSpell = function(spellId)
    if not spellId then
        return false
    end

    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        return C_UnitAuras.GetPlayerAuraBySpellID(spellId) ~= nil
    end

    if AuraUtil and AuraUtil.FindAuraByName and GetSpellInfo then
        local spellName = GetSpellInfo(spellId)
        if spellName and spellName ~= "" then
            return AuraUtil.FindAuraByName(spellName, "player", "HELPFUL") ~= nil
        end
    end

    return false
end

GetActiveTimewalkingEventHint = function()
    local _, holidayInfo, holidayKey = GetActiveTimewalkingHolidayInfo()
    if holidayKey then
        for _, hint in ipairs(TIMEWALKING_EVENT_HINTS) do
            if hint.key == holidayKey then
                return hint
            end
        end
    end

    local holidayName = NormalizeText(holidayInfo and holidayInfo.name)
    local holidayDescription = NormalizeText(holidayInfo and holidayInfo.description)
    local holidayText = holidayName .. holidayDescription

    if holidayText ~= "" then
        for _, hint in ipairs(TIMEWALKING_EVENT_HINTS) do
            for _, match in ipairs(hint.holidayMatches or {}) do
                if holidayText:find(NormalizeText(match), 1, true) then
                    return hint
                end
            end
        end
    end

    local turbulentFallbackKey = GetTurbulentTimewaysFallbackKey(holidayInfo)
        or GetScheduledTurbulentTimewaysKey()
    if turbulentFallbackKey then
        for _, hint in ipairs(TIMEWALKING_EVENT_HINTS) do
            if hint.key == turbulentFallbackKey then
                return hint
            end
        end
    end

    for _, hint in ipairs(TIMEWALKING_EVENT_HINTS) do
        if PlayerHasAuraSpell(hint.auraSpellId) then
            return hint
        end
    end

    return nil
end

local function ClearWaypoint(row)
    if type(row) ~= "table" then
        return
    end

    row.zone = nil
    row.x = nil
    row.y = nil
    row.waypointTitle = nil
end

local function ApplyWaypoint(row, location)
    if type(row) ~= "table" then
        return
    end

    if type(location) ~= "table" or not location.zone or not location.x or not location.y then
        ClearWaypoint(row)
        return
    end

    row.zone = location.zone
    row.x = location.x
    row.y = location.y
    row.waypointTitle = location.title or row.label
end

local function GetRaidPickupLocation(questId)
    local location = TIMEWALKING_RAID_PICKUP_LOCATIONS[questId]
    if type(location) ~= "table" then
        return nil
    end

    if location.zone then
        return location
    end

    local faction = UnitFactionGroup and UnitFactionGroup("player")
    if faction == "Alliance" then
        return location.alliance
    end

    return location.horde
end

local function GetLocalizedDungeonPickupNote()
    local npcName = L["TW_NPC_Aethas"] or "Archmage Aethas Sunreaver"
    local pattern = L["TW_DungeonPickup_Aethas"] or "Pick up the weekly from %s in Silvermoon City, or use the Adventure Journal."
    return string.format(pattern, npcName)
end

local function GetLocalizedRaidPickupNote(questId)
    local npcName = L["TW_NPC_Vormu"] or "Vormu"
    if questId == 82817 then
        local classicNpcName = L["TW_NPC_Grannadormu"] or "Grannadormu"
        local pattern = L["TW_RaidPickup_BlackrockDepths"] or "Pick up the raid quest from %s at the Timewalking hub in Stormwind or Orgrimmar."
        return string.format(pattern, classicNpcName)
    end
    if questId == 47523 then
        local pattern = L["TW_RaidPickup_BlackTemple"] or "Pick up the raid quest from %s in Shattrath City."
        return string.format(pattern, npcName)
    end
    if questId == 50316 then
        local pattern = L["TW_RaidPickup_Ulduar"] or "Pick up the raid quest from %s in Dalaran."
        return string.format(pattern, npcName)
    end
    if questId == 57637 then
        local pattern = L["TW_RaidPickup_Firelands"] or "Pick up the raid quest from %s in Orgrimmar or Stormwind."
        return string.format(pattern, npcName)
    end
    return L["TW_Raid_Note"] or "Complete the Timewalking raid quest available this week."
end

local function UpdateTimewalkingQuestRow(progressBucket, row, questIds, storagePrefix, defaultNote, emptyText, eventHint)
    if type(progressBucket) ~= "table" or type(row) ~= "table" or type(questIds) ~= "table" then
        return false
    end

    local activeQuestId, activeQuestName
    local completedQuestId, completedQuestName
    local rowNote = defaultNote
    local storedQuestId = progressBucket[storagePrefix .. "_active_quest"]
    local storedQuestName = progressBucket[storagePrefix .. "_active_name"]
    local prevValue = tonumber(progressBucket[row.key]) or 0
    local prevCompletedQuestId = progressBucket[storagePrefix .. "_completed_quest"]
    local prevCompletedQuestName = progressBucket[storagePrefix .. "_completed_name"]
    local prevVisible = tonumber(progressBucket[storagePrefix .. "_visible"]) or 0
    local prevCountText = row.countText
    local prevCountColor = row.countColor and { row.countColor[1], row.countColor[2], row.countColor[3] } or nil
    local prevNote = row.note
    local prevZone = row.zone
    local prevX = row.x
    local prevY = row.y
    local prevWaypointTitle = row.waypointTitle

    for _, questId in ipairs(questIds) do
        if not activeQuestId and IsQuestCurrentlyActive(questId) then
            activeQuestId = questId
            if storedQuestId == questId and storedQuestName then
                activeQuestName = storedQuestName
            else
                activeQuestName = MR:GetQuestName(questId)
            end
        end
        if not completedQuestId and C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questId) then
            completedQuestId = questId
            if prevCompletedQuestId == questId and prevCompletedQuestName then
                completedQuestName = prevCompletedQuestName
            else
                completedQuestName = MR:GetQuestName(questId)
            end
        end
    end

    if not activeQuestId and eventHint and storagePrefix == "tw_dungeon" and eventHint.dungeonQuestIds then
        for _, questId in ipairs(eventHint.dungeonQuestIds) do
            if C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questId) then
                completedQuestId = completedQuestId or questId
                completedQuestName = completedQuestName or MR:GetQuestName(questId, eventHint.dungeonFallbackName)
                break
            end
        end

        activeQuestId = eventHint.dungeonQuestIds[1]
        activeQuestName = MR:GetQuestName(activeQuestId, eventHint.dungeonFallbackName)
    elseif not activeQuestId and eventHint and storagePrefix == "tw_raid" and eventHint.hasRaid and eventHint.raidQuestIds then
        for _, questId in ipairs(eventHint.raidQuestIds) do
            if C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questId) then
                completedQuestId = completedQuestId or questId
                completedQuestName = completedQuestName or MR:GetQuestName(questId, eventHint.raidFallbackName)
                break
            end
        end

        activeQuestId = eventHint.raidQuestIds[1]
        activeQuestName = MR:GetQuestName(activeQuestId, eventHint.raidFallbackName)
    elseif not activeQuestId and eventHint and storagePrefix == "tw_raid" and eventHint.hasRaid == false then
        progressBucket[storagePrefix .. "_visible"] = 0
    end

    if storagePrefix == "tw_dungeon" and eventHint then
        rowNote = GetLocalizedDungeonPickupNote()
    elseif storagePrefix == "tw_raid" and eventHint then
        if eventHint.hasRaid == false then
            rowNote = L["TW_Raid_NotAvailable_Event"] or "There is no Timewalking raid quest during this Timewalking event."
        else
            rowNote = GetLocalizedRaidPickupNote(activeQuestId or completedQuestId or storedQuestId)
        end
    end

    if activeQuestId then
        progressBucket[storagePrefix .. "_active_quest"] = activeQuestId
        progressBucket[storagePrefix .. "_active_name"] = activeQuestName
        storedQuestId = activeQuestId
        storedQuestName = activeQuestName
    end

    local isDone = completedQuestId ~= nil
    if not isDone and storedQuestId and C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(storedQuestId) then
        completedQuestId = storedQuestId
        completedQuestName = MR:GetQuestName(storedQuestId, storedQuestName)
        isDone = true
    end

    progressBucket[row.key] = isDone and 1 or 0
    progressBucket[storagePrefix .. "_completed_quest"] = completedQuestId
    progressBucket[storagePrefix .. "_completed_name"] = completedQuestName
    progressBucket[storagePrefix .. "_visible"] = (activeQuestId or completedQuestId or storedQuestId) and 1 or 0

    if isDone then
        row.countText = completedQuestName or (L["Done"] or "Done")
        row.countColor = { 0.4, 0.85, 0.4 }
        ClearWaypoint(row)
    elseif activeQuestId then
        row.countText = activeQuestName or (L["Weekly_SA_Count_ActiveSingle"] or "Active")
        row.countColor = { 1, 0.9, 0.3 }
        if storagePrefix == "tw_dungeon" then
            ApplyWaypoint(row, {
                zone = TIMEWALKING_DUNGEON_PICKUP_LOCATION.zone,
                x = TIMEWALKING_DUNGEON_PICKUP_LOCATION.x,
                y = TIMEWALKING_DUNGEON_PICKUP_LOCATION.y,
                title = L["TW_NPC_Aethas"] or "Archmage Aethas Sunreaver",
            })
        elseif storagePrefix == "tw_raid" then
            local raidLocation = GetRaidPickupLocation(activeQuestId)
            if raidLocation then
                raidLocation = {
                    zone = raidLocation.zone,
                    x = raidLocation.x,
                    y = raidLocation.y,
                    title = activeQuestId == 82817 and (L["TW_NPC_Grannadormu"] or "Grannadormu") or (L["TW_NPC_Vormu"] or "Vormu"),
                }
            end
            ApplyWaypoint(row, raidLocation)
        else
            ClearWaypoint(row)
        end
    elseif emptyText then
        row.countText = emptyText
        row.countColor = { 0.75, 0.78, 0.86 }
        ClearWaypoint(row)
    else
        row.countText = nil
        row.countColor = nil
        ClearWaypoint(row)
    end

    row.note = rowNote
    local changed = prevValue ~= (progressBucket[row.key] or 0)
        or prevCompletedQuestId ~= progressBucket[storagePrefix .. "_completed_quest"]
        or prevCompletedQuestName ~= progressBucket[storagePrefix .. "_completed_name"]
        or prevVisible ~= (progressBucket[storagePrefix .. "_visible"] or 0)
        or prevCountText ~= row.countText
        or not ColorsEqual(prevCountColor, row.countColor)
        or prevNote ~= row.note
        or prevZone ~= row.zone
        or prevX ~= row.x
        or prevY ~= row.y
        or prevWaypointTitle ~= row.waypointTitle

    return isDone or activeQuestId ~= nil, changed
end

MR:RegisterModule({
    key         = "timewalking",
    label       = L["Timewalking"] or "Timewalking",
    labelColor  = "#66ccff",
    icon        = "Interface\\Icons\\Achievement_Quests_Completed_08",
    resetType   = "weekly",
    defaultOpen = true,
    isVisible   = IsTimewalkingActive,
    scanReturnsChanged = true,

    onScan = function(mod)
        local db = MR.db.char.progress
        if not db[mod.key] then
            db[mod.key] = {}
        end

        local eventHint = GetActiveTimewalkingEventHint()
        local changed = false

        for _, row in ipairs(mod.rows) do
            if row.key == "tw_dungeon" then
                local _, rowChanged = UpdateTimewalkingQuestRow(
                    db[mod.key],
                    row,
                    TIMEWALKING_DUNGEON_WEEKLIES,
                    "tw_dungeon",
                    L["TW_Weekly_Note"] or "Complete the Timewalking dungeon weekly for the cache.",
                    nil,
                    eventHint
                )
                changed = changed or rowChanged
            elseif row.key == "tw_raid" then
                local _, rowChanged = UpdateTimewalkingQuestRow(
                    db[mod.key],
                    row,
                    TIMEWALKING_RAID_WEEKLIES,
                    "tw_raid",
                    L["TW_Raid_Note"] or "Complete the Timewalking raid quest available this week.",
                    L["TW_Raid_NotActive"] or "Not up this week",
                    eventHint
                )
                changed = changed or rowChanged
            end
        end

        return changed
    end,

    rows = {
        {
            key         = "tw_dungeon",
            label       = L["TW_DungeonTitle"] or "Dungeon",
            max         = 1,
            note        = L["TW_Weekly_Note"],
            autoTracked = true,
            hideCoordText = true,
        },
        {
            key         = "tw_raid",
            label       = L["Raid"] or "Raid",
            max         = 1,
            note        = L["TW_Raid_Note"] or "Complete the Timewalking raid quest available this week.",
            autoTracked = true,
            hideCoordText = true,
        },
    },
})
