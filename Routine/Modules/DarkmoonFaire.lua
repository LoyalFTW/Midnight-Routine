local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers["DarkmoonFaire"] = function(owner, context)
    local ns = context.namespace
    if ns.MR.isForever then return end
    local MR = ns.MR

    local L = context.labels

    local HOLIDAY_DARKMOON_FAIRE = 479

    local DARKMOON_ISLAND_MAP = 407

    local DARKMOON_QUEST_IDS = {
        29434,
        29506, 29507, 29508, 29509, 29510, 29511, 29513, 29514, 29515,
        29516, 29517, 29518, 29519, 29520, 29524, 29525, 29526, 29527, 29529,
    }

    local DARKMOON_REQUIRED_ITEMS = {
        [29506] = { { itemID = 1645, count = 5, fallback = "Moonberry Juice" } },
        [29509] = { { itemID = 30817, count = 5, fallback = "Simple Flour" } },
        [29515] = { { itemID = 39354, count = 5, fallback = "Light Parchment" } },
        [29517] = {
            { itemID = 6529, count = 10, fallback = "Shiny Bauble" },
            { itemID = 2320, count = 5, fallback = "Coarse Thread" },
            { itemID = 6260, count = 5, fallback = "Blue Dye" },
        },
        [29520] = {
            { itemID = 2320, count = 1, fallback = "Coarse Thread" },
            { itemID = 2604, count = 1, fallback = "Red Dye" },
            { itemID = 6260, count = 1, fallback = "Blue Dye" },
        },
    }

    local cachedVisible
    local cacheExpiresAt = 0

    local function CanReadValue(value)
        if canaccessvalue then
            return canaccessvalue(value)
        end
        if issecretvalue then
            return not issecretvalue(value)
        end
        return true
    end

    local function CanReadTable(value)
        if not CanReadValue(value) then
            return false
        end
        if type(value) ~= "table" then
            return true
        end
        return not canaccesstable or canaccesstable(value)
    end

    local function CanReadAll(...)
        for index = 1, select("#", ...) do
            if not CanReadValue(select(index, ...)) then
                return false
            end
        end
        return true
    end

    local function CalendarTimeToEpoch(value)
        if not CanReadTable(value) then
            return nil
        end
        if type(value) == "number" then
            return value
        end
        if type(value) ~= "table" or not time then
            return nil
        end

        local year = value.year
        local month = value.month
        local monthDay = value.monthDay
        local day = value.day
        local hour = value.hour
        local minute = value.minute
        if not CanReadAll(year, month, monthDay, day, hour, minute) then
            return nil
        end

        return time({
            year = year,
            month = month,
            day = monthDay or day,
            hour = hour or 0,
            min = minute or 0,
            sec = 0,
        })
    end

    local function IsHolidayActive(holidayId)
        if not C_DateAndTime or not C_DateAndTime.GetHolidayInfo then return false end
        local info = C_DateAndTime.GetHolidayInfo(holidayId)
        if not CanReadTable(info) then return false end
        local startTime = CalendarTimeToEpoch(info.startTime)
        local endTime = CalendarTimeToEpoch(info.endTime)
        local now = GetServerTime and GetServerTime() or time()
        return startTime ~= nil and endTime ~= nil and now >= startTime and now <= endTime
    end

    local function GetCurrentCalendarDate()
        if C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime then
            return C_DateAndTime.GetCurrentCalendarTime()
        end

        if C_Calendar and C_Calendar.GetDate then
            local dateOrWeekday, month, monthDay, year = C_Calendar.GetDate()
            if not CanReadAll(dateOrWeekday, month, monthDay, year) then
                return nil
            end
            if type(dateOrWeekday) == "table" then
                if not CanReadTable(dateOrWeekday) then return nil end
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

    local function NormalizeTitle(value)
        if not CanReadValue(value) then return "" end
        if type(value) ~= "string" then return "" end
        return value:lower():gsub("[%s%p]", "")
    end

    local function IsDarkmoonTitle(value)
        local title = NormalizeTitle(value)
        if title == "" then return false end

        local localizedTitle = NormalizeTitle(L["DMF_Title"])
        local localizedSection = NormalizeTitle(L["ProfKnowledge_Section_Darkmoon"])
        return (localizedTitle ~= "" and title:find(localizedTitle, 1, true) ~= nil)
            or (localizedSection ~= "" and title:find(localizedSection, 1, true) ~= nil)
            or title:find("darkmoonfaire", 1, true) ~= nil
    end

    local function IsHolidayInfoActive(info)
        if not CanReadTable(info) or type(info) ~= "table" then return false end
        local startTime = CalendarTimeToEpoch(info.startTime)
        local endTime = CalendarTimeToEpoch(info.endTime)
        if not startTime or not endTime then
            return true
        end
        local now = GetServerTime and GetServerTime() or (time and time()) or nil
        return now ~= nil and now >= startTime and now <= endTime
    end

    function MR:IsCalendarHolidayActive(eventID)
        if not (C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent) then return false end
        local today = GetCurrentCalendarDate()
        if not CanReadTable(today) or type(today) ~= "table" then return false end
        local monthDay = today.monthDay
        if not CanReadValue(monthDay) or not monthDay then return false end
        local monthOffset = 0
        if C_Calendar.GetMonthInfo then
            local month = C_Calendar.GetMonthInfo(0)
            if CanReadTable(month) and type(month) == "table" then
                if not CanReadAll(month.year, month.month, today.year, today.month) then return false end
                monthOffset = (today.year - month.year) * 12 + today.month - month.month
            end
        end
        local numEvents = C_Calendar.GetNumDayEvents(monthOffset, monthDay)
        if not CanReadValue(numEvents) then return false end
        for index = 1, numEvents or 0 do
            local event = C_Calendar.GetDayEvent(monthOffset, monthDay, index)
            if CanReadTable(event) and type(event) == "table" then
                local currentID = event.eventID
                if CanReadValue(currentID) and currentID == eventID then
                    if C_DateAndTime and C_DateAndTime.CompareCalendarTime
                        and CanReadTable(event.startTime) and CanReadTable(event.endTime) then
                        local okStart, startRemaining = pcall(C_DateAndTime.CompareCalendarTime, event.startTime, today)
                        local okEnd, endRemaining = pcall(C_DateAndTime.CompareCalendarTime, event.endTime, today)
                        if okStart and okEnd and CanReadAll(startRemaining, endRemaining)
                            and type(startRemaining) == "number" and type(endRemaining) == "number" then
                            if startRemaining >= 0 and endRemaining < 0 then return true end
                        elseif IsHolidayInfoActive(event) then
                            return true
                        end
                    elseif IsHolidayInfoActive(event) then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function IsDarkmoonOnCalendar()
        if not C_Calendar then return false end
        local today = GetCurrentCalendarDate()
        if not CanReadTable(today) then return false end
        local monthDay = today.monthDay
        if not CanReadValue(monthDay) or not monthDay then return false end

        if C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent then
            local numEvents = C_Calendar.GetNumDayEvents(0, monthDay)
            if not CanReadValue(numEvents) then return false end
            numEvents = numEvents or 0
            for index = 1, numEvents do
                local event = C_Calendar.GetDayEvent(0, monthDay, index)
                if CanReadTable(event) then
                    local eventID = event.eventID
                    local title = event.title
                    local matchesID = CanReadValue(eventID) and eventID == HOLIDAY_DARKMOON_FAIRE
                    local matchesTitle = CanReadValue(title) and IsDarkmoonTitle(title)
                    if (matchesID or matchesTitle) and IsHolidayInfoActive(event) then
                        return true
                    end
                end
            end
        end

        if C_Calendar.GetHolidayInfo then
            for index = 1, 20 do
                local info = C_Calendar.GetHolidayInfo(0, monthDay, index)
                if not CanReadValue(info) then break end
                if not info then break end
                if CanReadTable(info) then
                    local name = info.name
                    local description = info.description
                    local matchesName = CanReadValue(name) and IsDarkmoonTitle(name)
                    local matchesDescription = CanReadValue(description) and IsDarkmoonTitle(description)
                    if (matchesName or matchesDescription) and IsHolidayInfoActive(info) then
                        return true
                    end
                end
            end
        end

        return false
    end

    local function IsDarkmoonWeekByDate()
        local today = GetCurrentCalendarDate()
        if not CanReadTable(today) then return false end
        local rawMonthDay = today.monthDay
        local rawWeekday = today.weekday
        if not CanReadAll(rawMonthDay, rawWeekday) then return false end
        local monthDay = tonumber(rawMonthDay)
        local weekday = tonumber(rawWeekday)
        if not monthDay or not weekday then return false end

        local firstWeekday = ((weekday - ((monthDay - 1) % 7) - 1) % 7) + 1
        local firstSunday = firstWeekday == 1 and 1 or (9 - firstWeekday)
        return monthDay >= firstSunday and monthDay < firstSunday + 7
    end

    local function HasActiveDarkmoonQuest()
        if not C_QuestLog or not C_QuestLog.IsOnQuest then return false end
        for _, questId in ipairs(DARKMOON_QUEST_IDS) do
            if C_QuestLog.IsOnQuest(questId) then
                return true
            end
        end
        return false
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

    local function ComputeDarkmoonVisible()
        return IsOnDarkmoonIsland()
            or MR:IsCalendarHolidayActive(HOLIDAY_DARKMOON_FAIRE)
            or IsDarkmoonOnCalendar()
            or IsHolidayActive(HOLIDAY_DARKMOON_FAIRE)
            or HasActiveDarkmoonQuest()
            or IsDarkmoonWeekByDate()
    end

    function MR.IsDarkmoonVisible()
        local now = GetTime and GetTime() or 0
        if cachedVisible ~= nil and now < cacheExpiresAt then
            return cachedVisible
        end
        cachedVisible = ComputeDarkmoonVisible()
        cacheExpiresAt = now + 5
        return cachedVisible
    end

    function MR:RefreshDarkmoonVisibility()
        local previous = cachedVisible
        cacheExpiresAt = 0
        local visible = MR.IsDarkmoonVisible()
        return previous == nil or previous ~= visible
    end


    function MR:GetDarkmoonRequiredItems(questId)
        return DARKMOON_REQUIRED_ITEMS[tonumber(questId)] or false
    end

    function MR:GetDarkmoonShoppingItems()
        local professions = {
            [29506] = 171,
            [29509] = 185,
            [29515] = 773,
            [29517] = 165,
            [29520] = 197,
        }
        local counts = {}
        local learnedProfessions = {}
        if GetProfessions and GetProfessionInfo then
            local indices = { GetProfessions() }
            if indices[5] then learnedProfessions[185] = true end
            for index = 1, 5 do
                local professionIndex = indices[index]
                if professionIndex then
                    local _, _, _, _, _, _, skillLine = GetProfessionInfo(professionIndex)
                    if skillLine then learnedProfessions[skillLine] = true end
                end
            end
        end
        if C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines
            and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
            for _, skillLine in ipairs(C_TradeSkillUI.GetAllProfessionTradeSkillLines() or {}) do
                local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLine)
                if info and (info.skillLevel or 0) > 0 then
                    learnedProfessions[info.parentProfessionID or skillLine] = true
                end
            end
        end
        local expansionProfessions = { [171] = 2906, [773] = 2913, [197] = 2918, [165] = 2915 }
        for questID, skillLine in pairs(professions) do
            local learned = learnedProfessions[skillLine]
                or (ns.HasProfessionLearned and ns.HasProfessionLearned(skillLine))
                or (self.playerProfessions and self.playerProfessions[skillLine])
                or (expansionProfessions[skillLine] and self.HasProfessionForModule
                    and self:HasProfessionForModule(expansionProfessions[skillLine]))
                or (C_QuestLog and C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(questID))
            local complete = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
                and C_QuestLog.IsQuestFlaggedCompleted(questID)
            if questID == 29509 and self.GetProgress then
                learned = true
                complete = (self:GetProgress("darkmoon_faire", "dmf_cook") or 0) >= 1
            end
            if learned and not complete then
                for _, item in ipairs(DARKMOON_REQUIRED_ITEMS[questID]) do
                    counts[item.itemID] = (counts[item.itemID] or 0) + item.count
                end
            end
        end
        local items = {}
        for itemID, count in pairs(counts) do
            items[#items + 1] = { itemID = itemID, count = count }
        end
        table.sort(items, function(a, b) return a.itemID < b.itemID end)
        return items
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

            { key = "dmf_fish",  label = L["DMF_Fish_Label"],  max = 1, note = L["DMF_Fish_Note"],  questIds = { 29513 }, tooltipFunc = function(tip) MR:AddDarkmoonMaterialsToTooltip(tip, 29513) end },
            { key = "dmf_cook",  label = L["DMF_Cook_Label"],  max = 1, note = L["DMF_Cook_Note"],  questIds = { 29509 }, tooltipFunc = function(tip) MR:AddDarkmoonMaterialsToTooltip(tip, 29509) end },
        },
    })
end
