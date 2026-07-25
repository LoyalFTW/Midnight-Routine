local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local HOLIDAY_DARKMOON_FAIRE = 479

local DARKMOON_ISLAND_MAP = 244

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

local function IsHolidayActive(holidayId)
    if not C_DateAndTime or not C_DateAndTime.GetHolidayInfo then return false end
    local info = C_DateAndTime.GetHolidayInfo(holidayId)
    if not info then return false end
    local startTime = CalendarTimeToEpoch(info.startTime)
    local endTime = CalendarTimeToEpoch(info.endTime)
    local now = GetServerTime and GetServerTime() or time()
    return startTime ~= nil and endTime ~= nil and now >= startTime and now <= endTime
end

local function IsOnDarkmoonIsland()
    local mapId = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not mapId then return false end
    for _ = 1, 5 do
        if mapId == DARKMOON_ISLAND_MAP then return true end
        local info = C_Map.GetMapInfo(mapId)
        if not info or not info.parentMapID or info.parentMapID == 0 then break end
        mapId = info.parentMapID
    end
    return false
end

function MR.IsDarkmoonVisible()
    return IsHolidayActive(HOLIDAY_DARKMOON_FAIRE) or IsOnDarkmoonIsland()
end

MR:RegisterModule({
    key         = "darkmoon_faire",
    label       = L["DMF_Title"],
    labelColor  = "#cc99ff",
    resetType   = "weekly",
    defaultOpen = true,
    isVisible   = MR.IsDarkmoonVisible,

    rows = {
        { key = "dmf_dungeon",  label = L["DMF_Dungeon_Label"],  max = 1, note = L["DMF_Dungeon_Note"],  questIds = { 29525 } },
        { key = "dmf_tonk",     label = L["DMF_Tonk_Label"],     max = 1, note = L["DMF_Tonk_Note"],     questIds = { 29434 } },
        { key = "dmf_shooting", label = L["DMF_Hammer_Label"],   max = 1, note = L["DMF_Hammer_Note"],   questIds = { 29526 } },
        { key = "dmf_ring",     label = L["DMF_Ring_Label"],     max = 1, note = L["DMF_Ring_Note"],     questIds = { 29524 } },
        { key = "dmf_cannon",   label = L["DMF_Cannon_Label"],   max = 1, note = L["DMF_Cannon_Note"],   questIds = { 29527 } },
        { key = "dmf_sword",    label = L["DMF_Target_Label"],   max = 1, note = L["DMF_Target_Note"],   questIds = { 29529 } },

        { key = "dmf_fish",  label = L["DMF_Fish_Label"],  max = 1, note = L["DMF_Fish_Note"],  questIds = { 29513 } },
        { key = "dmf_cook",  label = L["DMF_Cook_Label"],  max = 1, note = L["DMF_Cook_Note"],  questIds = { 29509 } },
    },
})
