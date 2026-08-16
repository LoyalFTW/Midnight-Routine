local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local CURSE_SURGE_INTERVAL = 2700
local CURSE_SURGE_EPOCH = 1786843866
local CURSE_SURGE_LIVE_DURATION = 300
local CURSE_SURGE_SITES = {
    { name = "The Malformed Leviathan",           zone = 2512, x = 46.7, y = 62.8 },
    { name = "The Broodmother's Nest",             zone = 2512, x = 45.7, y = 29.6 },
    { name = "The Looming Mutagenior",             zone = 2512, x = 26.4, y = 64.9 },
    { name = "Mlurkkr Massacre",                   zone = 2512, x = 70.5, y = 32.7 },
    { name = "Siege at the Whispering Marsch",     zone = 2512, x = 67.1, y = 77.5 },
}

if MR.db and MR.db.global and MR.db.global.curseSurgeAnchor then
    MR.db.global.curseSurgeAnchor = nil
end

local function GetCurseSurgeState()
    local elapsed = GetServerTime() - CURSE_SURGE_EPOCH
    local offset = elapsed % CURSE_SURGE_INTERVAL
    local cycleIndex = math.floor(elapsed / CURSE_SURGE_INTERVAL)
    local isLive = offset < CURSE_SURGE_LIVE_DURATION
    local siteIndex = isLive and cycleIndex or (cycleIndex + 1)
    local site = CURSE_SURGE_SITES[(siteIndex % #CURSE_SURGE_SITES) + 1]

    return site, isLive
end

local curseSurgeBoundaryTimer

local function ScheduleCurseSurgeBoundaryRefresh()
    if curseSurgeBoundaryTimer then
        curseSurgeBoundaryTimer:Cancel()
        curseSurgeBoundaryTimer = nil
    end

    local offset = (GetServerTime() - CURSE_SURGE_EPOCH) % CURSE_SURGE_INTERVAL
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
        local site = GetCurseSurgeState()
        local changed = false
        for _, row in ipairs(mod.rows) do
            if row.key == "curse_surge" then
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
            timerEpoch    = CURSE_SURGE_EPOCH,
            timerInterval = CURSE_SURGE_INTERVAL,
            timerDuration = CURSE_SURGE_LIVE_DURATION,
            autoTracked   = true,
            noDefaultTooltipHint = true,
        },
    },
})
