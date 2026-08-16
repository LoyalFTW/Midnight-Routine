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

if MR.db and MR.db.global and MR.db.global.curseSurgeAnchor then
    MR.db.global.curseSurgeAnchor = nil
end
if MR.db and MR.db.global and MR.db.global.curseSurgeRegionOffsets then
    MR.db.global.curseSurgeRegionOffsets = nil
end

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

local function GetCurseSurgeEpoch()
    return CURSE_SURGE_EPOCH_BASE + GetCurseSurgeOffsetSeconds()
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
        },
    },
})
