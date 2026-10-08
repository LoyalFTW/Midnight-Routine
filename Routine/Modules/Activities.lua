local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers["Activities"] = function(owner, context)
    local ns = context.namespace
    if ns.MR.isForever then return end
    local MR = ns.MR

    local L = context.labels

    local function IsBrewfestActive()
        if MR.IsCalendarHolidayActive and MR:IsCalendarHolidayActive(372) then
            return true
        end
        local now = GetServerTime()
        return now >= 1789923600 and now < 1791306000
    end

    local brewfestVisible

    function MR:RefreshBrewfestVisibility()
        local previous = brewfestVisible
        brewfestVisible = IsBrewfestActive()
        return previous == nil or previous ~= brewfestVisible
    end

    local CURSE_SURGE_DURATION = 600
    local CURSE_SURGE_SITES = {
        { name = L["CurseSurgeSite_MalformedLeviathan"],       zone = 2512, x = 46.7, y = 62.8 },
        { name = L["CurseSurgeSite_BroodmothersNest"],         zone = 2512, x = 45.7, y = 29.6 },
        { name = L["CurseSurgeSite_LoomingMutagenior"],        zone = 2512, x = 26.4, y = 64.9 },
        { name = L["CurseSurgeSite_MlurkkrMassacre"],          zone = 2512, x = 70.5, y = 32.7 },
        { name = L["CurseSurgeSite_SiegeWhisperingMarsch"],    zone = 2512, x = 67.1, y = 77.5 },
    }

    local CURSE_SURGE_POI_TO_SITE = {
        [8940] = 1, 
        [8938] = 2, 
        [8936] = 3, 
        [8939] = 4, 
        [8937] = 5, 
    }

    local scheduledCurseSurges = {}
    local curseSurgeScheduleInitialized
    local curseSurgeScheduleRequested
    local activeCurseSurgeSite
    local activeCurseSurgeStartTime
    local activeCurseSurgeEndTime
    local endedCurseSurgeSite
    local endedCurseSurgeAt
    local mapCurseSurgeSite
    local ongoingCurseSurgeSite
    local scenarioCurseSurgeSite
    local scenarioCurseSurgeComplete

    local function GetCurseSurgeEndTime(event)
        local endTime = event.startTime + CURSE_SURGE_DURATION
        return event.endTime and event.endTime > event.startTime and math.min(event.endTime, endTime)
            or endTime
    end

    local function ReadCurseSurgeFromMap()
        if not (C_AreaPoiInfo and C_AreaPoiInfo.GetEventsForMap) then
            return nil, false
        end

        local ok, list = pcall(C_AreaPoiInfo.GetEventsForMap, 2512)
        if not ok or type(list) ~= "table" then
            return nil, false
        end

        for _, areaPoiID in ipairs(list) do
            local siteIndex = CURSE_SURGE_POI_TO_SITE[areaPoiID]
            if siteIndex then
                return CURSE_SURGE_SITES[siteIndex], true
            end
        end

        return nil, true
    end

    local function ReadCurseSurgeFromScenario()
        if not (C_ScenarioInfo and C_ScenarioInfo.GetScenarioInfo) then
            return nil
        end

        local ok, info = pcall(C_ScenarioInfo.GetScenarioInfo)
        if not ok or type(info) ~= "table" or type(info.name) ~= "string" then
            return nil
        end

        for _, site in ipairs(CURSE_SURGE_SITES) do
            if info.name:find(site.name, 1, true) then
                return site, info.isComplete == true
            end
        end
    end

    local function RefreshCurseSurgeData(refreshSchedule, refreshMap, refreshScenario)
        if refreshSchedule and C_EventScheduler and C_EventScheduler.HasData then
            local ok, hasData = pcall(C_EventScheduler.HasData)
            if not ok or not hasData then refreshSchedule = false end
        end
        if refreshSchedule and C_EventScheduler and C_EventScheduler.GetScheduledEvents then
            local ok, list = pcall(C_EventScheduler.GetScheduledEvents)
            if ok and type(list) == "table" then
                local events = {}
                for _, ev in ipairs(list) do
                    if type(ev) == "table" then
                        local siteIndex = CURSE_SURGE_POI_TO_SITE[ev.areaPoiID]
                        local startTime = tonumber(ev.startTime)
                        if siteIndex and startTime then
                            events[#events + 1] = {
                                site = CURSE_SURGE_SITES[siteIndex],
                                startTime = startTime,
                                endTime = tonumber(ev.endTime),
                            }
                        end
                    end
                end
                local now = GetServerTime()
                for _, previous in ipairs(scheduledCurseSurges) do
                    if previous.startTime <= now and GetCurseSurgeEndTime(previous) > now then
                        local found
                        for _, event in ipairs(events) do
                            if event.site == previous.site and event.startTime == previous.startTime then
                                found = true
                                break
                            end
                        end
                        if not found then events[#events + 1] = previous end
                    end
                end
                table.sort(events, function(a, b)
                    return a.startTime < b.startTime
                end)
                scheduledCurseSurges = events
                curseSurgeScheduleInitialized = true
            end
        end

        if refreshMap then
            mapCurseSurgeSite = ReadCurseSurgeFromMap()
        end
        if refreshSchedule and C_EventScheduler and C_EventScheduler.GetOngoingEvents then
            local ok, list = pcall(C_EventScheduler.GetOngoingEvents)
            if ok and type(list) == "table" then
                ongoingCurseSurgeSite = nil
                for _, ev in ipairs(list) do
                    if type(ev) == "table" then
                        local siteIndex = CURSE_SURGE_POI_TO_SITE[ev.areaPoiID]
                        if siteIndex then
                            ongoingCurseSurgeSite = CURSE_SURGE_SITES[siteIndex]
                            break
                        end
                    end
                end
            end
        end

        if refreshScenario then
            scenarioCurseSurgeSite, scenarioCurseSurgeComplete = ReadCurseSurgeFromScenario()
        end
        local detectedSite = mapCurseSurgeSite or ongoingCurseSurgeSite
        local scenarioSite, scenarioComplete = scenarioCurseSurgeSite, scenarioCurseSurgeComplete
        if scenarioSite and not scenarioComplete then detectedSite = scenarioSite end
        local now = GetServerTime()
        if activeCurseSurgeSite and not detectedSite then
            endedCurseSurgeSite = activeCurseSurgeSite
            endedCurseSurgeAt = now
        end
        if scenarioSite and scenarioComplete then
            endedCurseSurgeSite = scenarioSite
            endedCurseSurgeAt = now
        end
        if detectedSite ~= activeCurseSurgeSite then
            activeCurseSurgeStartTime = nil
            activeCurseSurgeEndTime = detectedSite and now + CURSE_SURGE_DURATION or nil
        end
        if detectedSite then
            for _, event in ipairs(scheduledCurseSurges) do
                if event.site == detectedSite and event.startTime <= now
                    and (not activeCurseSurgeStartTime or event.startTime >= activeCurseSurgeStartTime) then
                    activeCurseSurgeStartTime = event.startTime
                    activeCurseSurgeEndTime = GetCurseSurgeEndTime(event)
                end
            end
        end
        activeCurseSurgeSite = detectedSite
    end

    local function GetCurseSurgeState()
        local now = GetServerTime()
        local liveEvent
        local nextEvent
        for _, ev in ipairs(scheduledCurseSurges) do
            if ev.startTime > now and not nextEvent then
                nextEvent = ev
            elseif ev.startTime <= now
                and GetCurseSurgeEndTime(ev) > now then
                local ended = endedCurseSurgeSite == ev.site and endedCurseSurgeAt and endedCurseSurgeAt >= ev.startTime
                if not ended then liveEvent = ev end
                if not ended and activeCurseSurgeSite == ev.site then
                    return "live", GetCurseSurgeEndTime(ev) - now, activeCurseSurgeSite
                end
            end
        end

        local activeEnded = endedCurseSurgeSite == activeCurseSurgeSite and endedCurseSurgeAt
            and (not activeCurseSurgeStartTime or endedCurseSurgeAt >= activeCurseSurgeStartTime)
        if activeCurseSurgeSite and not activeEnded and activeCurseSurgeEndTime and activeCurseSurgeEndTime > now then
            return "live", activeCurseSurgeEndTime - now, activeCurseSurgeSite
        end

        local recentlyEnded = endedCurseSurgeSite == (liveEvent and liveEvent.site)
            and endedCurseSurgeAt
            and liveEvent and endedCurseSurgeAt >= liveEvent.startTime
        if liveEvent and not recentlyEnded then
            return "live", GetCurseSurgeEndTime(liveEvent) - now, liveEvent.site
        end
        if nextEvent then
            return "next", nextEvent.startTime - now, nextEvent.site, nextEvent.startTime
        end

        return "unavailable"
    end

    local function FormatCurseSurgeCountdown(seconds)
        seconds = math.max(0, math.floor(seconds or 0))
        return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
    end

    local function GetCurseSurgeZoneChannelIndex()
        local list = { GetChannelList() }
        local generalLabel = GENERAL or "General"
        for i = 1, #list, 3 do
            local id, name = list[i], list[i + 1]
            if id and type(name) == "string" and name:find(generalLabel, 1, true) then
                return id
            end
        end
    end

-- Same clickable pin the game inserts when you shift-click a map pin into chat --
-- readers can click straight to the spot. CURSE_SURGE_SITES coords are already
-- 0-100 percent, so *100 lands on the hyperlink's 0-10000 scale.
    local function CurseSurgePinLink(mapID, x, y)
        return string.format("|cffffff00|Hworldmap:%d:%d:%d|h[%s]|h|r",
            mapID, math.floor(x * 100 + 0.5), math.floor(y * 100 + 0.5),
            MAP_PIN_HYPERLINK or "Map Pin Location")
    end

    local function GetCurseSurgeGroupChatType()
        local instanceCategory = Enum and Enum.PartyCategory and Enum.PartyCategory.Instance or LE_PARTY_CATEGORY_INSTANCE
        if IsInGroup and instanceCategory and IsInGroup(instanceCategory) then
            return "INSTANCE_CHAT"
        end
        if IsInRaid and IsInRaid() then
            return "RAID"
        end
        if IsInGroup and IsInGroup() then
            return "PARTY"
        end
    end

    local function AnnounceCurseSurge(toGroup)
        local phase, seconds, site = GetCurseSurgeState()
        if not site then
            print(L["Chat_CurseSurgeNoSite"] or "|cff2ae7c6MidnightRoutine:|r Nothing to announce right now.")
            return
        end

        local msg
        if phase == "live" then
            msg = string.format(L["Chat_CurseSurgeAnnounceLive"] or "Routine: %s is LIVE on the Coiled Isle! (%.1f, %.1f)",
                site.name, site.x, site.y)
        else
            msg = string.format(L["Chat_CurseSurgeAnnounceNext"] or "Routine: %s next in %s on the Coiled Isle (%.1f, %.1f)",
                site.name, FormatCurseSurgeCountdown(seconds), site.x, site.y)
        end
        msg = msg .. " " .. CurseSurgePinLink(site.zone, site.x, site.y)

        if toGroup then
            local chatType = GetCurseSurgeGroupChatType()
            if chatType then
                SendChatMessage(msg, chatType)
            else
                print(L["Chat_CurseSurgeNoGroup"] or "|cff2ae7c6MidnightRoutine:|r You are not in a party, raid, or instance group.")
            end
            return
        end

        local idx = GetCurseSurgeZoneChannelIndex()
        if idx then
            SendChatMessage(msg, "CHANNEL", nil, idx)
        else
            SendChatMessage(msg, "SAY")
        end
    end

    local curseSurgeBoundaryTimer
    local curseSurgeBoundaryAt
    local curseSurgeRefreshTimer
    local curseSurgeRefreshSchedule
    local curseSurgeRefreshMap
    local curseSurgeRefreshScenario
    local curseSurgePublishedPhase
    local curseSurgePublishedSite
    local curseSurgePublishedStart
    local CURSE_SURGE_SCAN_KEYS = { "midnight_activities" }
    local ScheduleCurseSurgeBoundaryRefresh

    local function IsOnCurseSurgeMap()
        local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        for _ = 1, 6 do
            if mapID == 2512 then return true end
            local info = mapID and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
            if not info or not info.parentMapID or info.parentMapID == 0 then break end
            mapID = info.parentMapID
        end
        return false
    end

    local function RequestCurseSurgeRefresh(event)
        local enteringWorld = event == "PLAYER_ENTERING_WORLD"
        if enteringWorld and not curseSurgeScheduleRequested and C_EventScheduler and C_EventScheduler.RequestEvents then
            curseSurgeScheduleRequested = true
            pcall(C_EventScheduler.RequestEvents)
        end
        local localEvent = event == "AREA_POIS_UPDATED" or event == "SCENARIO_UPDATE" or event == "SCENARIO_COMPLETED" or event == "ZONE_CHANGED_NEW_AREA"
        local onMap = (enteringWorld or localEvent) and IsOnCurseSurgeMap()
        if (enteringWorld or event == "ZONE_CHANGED_NEW_AREA") and not onMap then
            mapCurseSurgeSite = nil
            scenarioCurseSurgeSite = nil
            scenarioCurseSurgeComplete = nil
        end
        if localEvent and not onMap then return end
        curseSurgeRefreshSchedule = curseSurgeRefreshSchedule or (enteringWorld and not curseSurgeScheduleInitialized) or event == "EVENT_SCHEDULER_UPDATE"
        curseSurgeRefreshMap = curseSurgeRefreshMap or (onMap and (enteringWorld or event == "AREA_POIS_UPDATED" or event == "ZONE_CHANGED_NEW_AREA"))
        curseSurgeRefreshScenario = curseSurgeRefreshScenario or (onMap and (enteringWorld or event == "SCENARIO_UPDATE" or event == "SCENARIO_COMPLETED" or event == "ZONE_CHANGED_NEW_AREA"))
        if event and not curseSurgeRefreshSchedule and not curseSurgeRefreshMap and not curseSurgeRefreshScenario then return end
        if curseSurgeRefreshTimer then return end
        curseSurgeRefreshTimer = MR:ScheduleTimer(function()
            if curseSurgeRefreshSchedule or curseSurgeRefreshMap or curseSurgeRefreshScenario then
                RefreshCurseSurgeData(curseSurgeRefreshSchedule, curseSurgeRefreshMap, curseSurgeRefreshScenario)
            end
            curseSurgeRefreshSchedule = nil
            curseSurgeRefreshMap = nil
            curseSurgeRefreshScenario = nil
            curseSurgeRefreshTimer = nil
            local phase, _, site, startTime = GetCurseSurgeState()
            if phase ~= curseSurgePublishedPhase or site ~= curseSurgePublishedSite or startTime ~= curseSurgePublishedStart then
                curseSurgePublishedPhase = phase
                curseSurgePublishedSite = site
                curseSurgePublishedStart = startTime
                MR:RefreshModuleScans(CURSE_SURGE_SCAN_KEYS, true)
            end
            ScheduleCurseSurgeBoundaryRefresh()
        end, 0.2)
    end

    ScheduleCurseSurgeBoundaryRefresh = function()
        local now = GetServerTime()
        local nextCheck
        if activeCurseSurgeEndTime and activeCurseSurgeEndTime > now then
            nextCheck = activeCurseSurgeEndTime + 1
        end
        for _, event in ipairs(scheduledCurseSurges) do
            if event.startTime > now then
                nextCheck = math.min(nextCheck or math.huge, event.startTime + 1)
            end
            local endTime = GetCurseSurgeEndTime(event)
            if endTime > now then
                nextCheck = math.min(nextCheck or math.huge, endTime + 1)
            end
        end
        if curseSurgeBoundaryTimer and curseSurgeBoundaryAt and nextCheck and curseSurgeBoundaryAt == nextCheck then
            return
        end
        if curseSurgeBoundaryTimer then
            MR:CancelTimer(curseSurgeBoundaryTimer)
            curseSurgeBoundaryTimer = nil
        end

        curseSurgeBoundaryAt = nextCheck
        if not nextCheck then return end
        curseSurgeBoundaryTimer = MR:ScheduleTimer(function()
            curseSurgeBoundaryTimer = nil
            curseSurgeBoundaryAt = nil
            RequestCurseSurgeRefresh()
        end, math.max(nextCheck - now, 0.2))
    end

    if MR.IsPatchAvailable and MR:IsPatchAvailable("12.1.0") then
        ScheduleCurseSurgeBoundaryRefresh()

        local curseSurgeSchedulerWatcher = CreateFrame("Frame")
        curseSurgeSchedulerWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
        curseSurgeSchedulerWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        curseSurgeSchedulerWatcher:RegisterEvent("EVENT_SCHEDULER_UPDATE")
        curseSurgeSchedulerWatcher:RegisterEvent("AREA_POIS_UPDATED")
        curseSurgeSchedulerWatcher:RegisterEvent("SCENARIO_UPDATE")
        curseSurgeSchedulerWatcher:RegisterEvent("SCENARIO_COMPLETED")
        curseSurgeSchedulerWatcher:SetScript("OnEvent", function(_, event)
            RequestCurseSurgeRefresh(event)
        end)
    end

    MR:RegisterModule({
        key         = "midnight_activities",
        label       = L["Activities_Title"],
        labelColor  = "#ff9040",
        resetType   = "weekly",
        defaultOpen = true,
        scanReturnsChanged = true,

        onScan = function(mod)
            local _, _, site = GetCurseSurgeState()
            local changed = false
            for _, row in ipairs(mod.rows) do
                if row.key == "curse_surge" then
                    local weeklyComplete = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
                        and C_QuestLog.IsQuestFlaggedCompleted(96995) == true or false
                    if not weeklyComplete and C_QuestLog and C_QuestLog.GetQuestObjectives then
                        local objectives = C_QuestLog.GetQuestObjectives(96995)
                        local objective = objectives and objectives[1]
                        weeklyComplete = (tonumber(objective and objective.numFulfilled) or 0) >= 3
                    end
                    if row.relatedWeeklyComplete ~= weeklyComplete then
                        changed = true
                        row.relatedWeeklyComplete = weeklyComplete
                    end
                    local note = site
                        and string.format(L["Act_CurseSurge_NoteSite"] or "%s\nSite: %s (%.1f, %.1f)", L["Act_CurseSurge_Note"], site.name, site.x, site.y)
                        or L["Act_CurseSurge_Note"]
                    if row.note ~= note or row.zone ~= (site and site.zone) then
                        changed = true
                    end
                    row.note = note
                    if site then
                        row.zone, row.x, row.y = site.zone, site.x, site.y
                        row.waypointTitle = site.name
                    else
                        row.zone, row.x, row.y, row.waypointTitle = nil, nil, nil, nil
                    end
                end
            end
            return changed
        end,

        rows = {
            {
                key           = "stormarion_assault",
                relatedWeekly = { moduleKey = "midnight_activities", rowKey = "stormarion_assault", max = 1 },
                label         = L["Act_Stormarion_Label"],
                max           = 1,
                note          = L["Act_Stormarion_Note"],
                patchKey      = "12.0.0",
                questIds      = { 90962 },
                timerEpoch    = 1772370083,
                timerInterval = 1800,
                timerDuration = 900,
            },
            {
                key           = "brewfest_banquet",
                label         = L["Holiday_BrewfestBanquet_Label"],
                max           = 1,
                note          = L["Holiday_BrewfestBanquet_Note"],
                group         = "holidays",
                groupInConfigOnly = true,
                isVisible     = IsBrewfestActive,
                autoTracked   = true,
                timerEpoch    = 0,
                timerInterval = 3600,
                timerDuration = 600,
            },
            {
                key           = "curse_surge",
                relatedWeekly = { moduleKey = "s1_weekly", rowKey = "turn_back_surge", max = 3 },
                label         = L["Act_CurseSurge_Label"],
                max           = 1,
                note          = L["Act_CurseSurge_Note"],
                patchKey      = "12.1.0",
                timerStateFunc = GetCurseSurgeState,
                autoTracked   = true,
                noDefaultTooltipHint = true,
                tooltipFunc = function(tip)
                    tip:AddLine(" ")
                    tip:AddLine(L["Act_CurseSurge_AnnounceHint"] or "Shift-right-click: announce to zone chat.\nCtrl-right-click: announce to your group.", 0.55, 0.55, 0.60, true)
                end,
                onRightClick = function()
                    if IsControlKeyDown and IsControlKeyDown() then
                        AnnounceCurseSurge(true)
                        return true
                    end
                    if IsShiftKeyDown() then
                        AnnounceCurseSurge(false)
                        return true
                    end
                    return false
                end,
            },
        },
    })
end
