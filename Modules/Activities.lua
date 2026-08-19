local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local CURSE_SURGE_INTERVAL = 2700
local CURSE_SURGE_EPOCH_BASE = 1786843866
local CURSE_SURGE_LIVE_DURATION = 300
local CURSE_SURGE_SITES = {
    { name = L["CurseSurgeSite_MalformedLeviathan"],       zone = 2512, x = 46.7, y = 62.8 },
    { name = L["CurseSurgeSite_BroodmothersNest"],         zone = 2512, x = 45.7, y = 29.6 },
    { name = L["CurseSurgeSite_LoomingMutagenior"],        zone = 2512, x = 26.4, y = 64.9 },
    { name = L["CurseSurgeSite_MlurkkrMassacre"],          zone = 2512, x = 70.5, y = 32.7 },
    { name = L["CurseSurgeSite_SiegeWhisperingMarsch"],    zone = 2512, x = 67.1, y = 77.5 },
}

local CURSE_SURGE_REGION_OFFSETS = {
    CN = 1800,
    EU = 900,
}

local CURSE_SURGE_POI_TO_SITE = {
    [8940] = 1, 
    [8938] = 2, 
    [8936] = 3, 
    [8939] = 4, 
    [8937] = 5, 
}

local function GetCurseSurgeRegionKey()
    local region = GetCurrentRegionName and GetCurrentRegionName()
    if type(region) == "string" and region ~= "" then
        return region
    end
    return "UNKNOWN"
end

local function GetCurseSurgeOffsetSeconds()
    return CURSE_SURGE_REGION_OFFSETS[GetCurseSurgeRegionKey()] or 0
end

local function ReadCurseSurgeEpochFromScheduler()
    if not (C_EventScheduler and C_EventScheduler.GetScheduledEvents) then
        return nil
    end

    local ok, list = pcall(C_EventScheduler.GetScheduledEvents)
    if not ok or type(list) ~= "table" then
        return nil
    end

    for _, ev in ipairs(list) do
        if type(ev) == "table" and ev.areaPoiID then
            local siteIndex = CURSE_SURGE_POI_TO_SITE[ev.areaPoiID]
            local startTime = tonumber(ev.startTime)
            if siteIndex and startTime then
                local duration = tonumber(ev.duration)
                if not duration and ev.endTime then
                    duration = tonumber(ev.endTime) - startTime
                end
                if not duration or duration == CURSE_SURGE_INTERVAL then
                    return startTime - (siteIndex - 1) * CURSE_SURGE_INTERVAL
                end
            end
        end
    end

    return nil
end

local schedulerEpochCache, schedulerEpochCachedAt

local function GetCurseSurgeEpoch()
    if not schedulerEpochCache or GetTime() - (schedulerEpochCachedAt or 0) > 60 then
        schedulerEpochCache = ReadCurseSurgeEpochFromScheduler()
        schedulerEpochCachedAt = GetTime()
    end

    return schedulerEpochCache or (CURSE_SURGE_EPOCH_BASE + GetCurseSurgeOffsetSeconds())
end

local function GetCurseSurgeState()
    local epoch = GetCurseSurgeEpoch()
    local elapsed = GetServerTime() - epoch
    local offset = elapsed % CURSE_SURGE_INTERVAL
    local cycleIndex = math.floor(elapsed / CURSE_SURGE_INTERVAL)
    local isLive = offset < CURSE_SURGE_LIVE_DURATION
    local siteIndex = isLive and cycleIndex or (cycleIndex + 1)
    local site = CURSE_SURGE_SITES[(siteIndex % #CURSE_SURGE_SITES) + 1]

    return epoch, site
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

local function AnnounceCurseSurge()
    local epoch, site = GetCurseSurgeState()
    if not site then
        print(L["Chat_CurseSurgeNoSite"] or "|cff2ae7c6MidnightRoutine:|r Nothing to announce right now.")
        return
    end

    local elapsed = (GetServerTime() - epoch) % CURSE_SURGE_INTERVAL
    local msg
    if elapsed < CURSE_SURGE_LIVE_DURATION then
        msg = string.format(L["Chat_CurseSurgeAnnounceLive"] or "Routine: %s is LIVE on the Coiled Isle! (%.1f, %.1f)",
            site.name, site.x, site.y)
    else
        msg = string.format(L["Chat_CurseSurgeAnnounceNext"] or "Routine: %s next in %s on the Coiled Isle (%.1f, %.1f)",
            site.name, FormatCurseSurgeCountdown(CURSE_SURGE_INTERVAL - elapsed), site.x, site.y)
    end
    msg = msg .. " " .. CurseSurgePinLink(site.zone, site.x, site.y)

    local idx = GetCurseSurgeZoneChannelIndex()
    if idx then
        SendChatMessage(msg, "CHANNEL", nil, idx)
    else
        SendChatMessage(msg, "SAY")
    end
end

local curseSurgeBoundaryTimer

local function ScheduleCurseSurgeBoundaryRefresh()
    if curseSurgeBoundaryTimer then
        curseSurgeBoundaryTimer:Cancel()
        curseSurgeBoundaryTimer = nil
    end

    local epoch = GetCurseSurgeEpoch()
    local offset = (GetServerTime() - epoch) % CURSE_SURGE_INTERVAL
    local wait = (offset < CURSE_SURGE_LIVE_DURATION)
        and (CURSE_SURGE_LIVE_DURATION - offset)
        or (CURSE_SURGE_INTERVAL - offset)
    wait = wait + 1

    curseSurgeBoundaryTimer = C_Timer.NewTimer(wait, function()
        curseSurgeBoundaryTimer = nil
        if MR.RequestScan then MR:RequestScan() end
        ScheduleCurseSurgeBoundaryRefresh()
    end)
end

if MR.IsPatchAvailable and MR:IsPatchAvailable("12.1.0") then
    ScheduleCurseSurgeBoundaryRefresh()

    local curseSurgeSchedulerWatcher = CreateFrame("Frame")
    curseSurgeSchedulerWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    curseSurgeSchedulerWatcher:RegisterEvent("EVENT_SCHEDULER_UPDATE")
    curseSurgeSchedulerWatcher:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            if C_EventScheduler and C_EventScheduler.RequestEvents then
                pcall(C_EventScheduler.RequestEvents)
            end
            return
        end

        schedulerEpochCache = nil
        if MR.RequestScan then MR:RequestScan() end
        ScheduleCurseSurgeBoundaryRefresh()
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
        local epoch, site = GetCurseSurgeState()
        local changed = false
        for _, row in ipairs(mod.rows) do
            if row.key == "curse_surge" then
                row.timerEpoch = epoch
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
            key           = "curse_surge",
            label         = L["Act_CurseSurge_Label"],
            max           = 1,
            note          = L["Act_CurseSurge_Note"],
            patchKey      = "12.1.0",
            timerEpoch    = GetCurseSurgeEpoch(),
            timerInterval = CURSE_SURGE_INTERVAL,
            timerDuration = CURSE_SURGE_LIVE_DURATION,
            autoTracked   = true,
            noDefaultTooltipHint = true,
            tooltipFunc = function(tip)
                tip:AddLine(" ")
                tip:AddLine(L["Act_CurseSurge_AnnounceHint"] or "Shift-right-click to announce this to zone chat.", 0.55, 0.55, 0.60, true)
            end,
            onRightClick = function()
                if IsShiftKeyDown() then
                    AnnounceCurseSurge()
                    return true
                end
                return false
            end,
        },
    },
})
