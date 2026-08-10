local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local MIDNIGHT_MAP_IDS = {
    [2393] = true,
    [2395] = true,
    [2405] = true,
    [2413] = true,
    [2437] = true,
    [2576] = true,
}

local WORLD_BOSS_ROTATION = {
    { key = "luashal",    label = L["WB_Luashal_Label"],    note = L["WB_Luashal_Note"],    zone = 2395, match = "luashal", questId = 92560 },
    { key = "cragpine",   label = L["WB_Cragpine_Label"],   note = L["WB_Cragpine_Note"],   zone = 2437, match = "cragpine", questId = 92123 },
    { key = "thormbelan", label = L["WB_Thormbelan_Label"], note = L["WB_Thormbelan_Note"], zone = 2413, match = "thormbelan", questId = 92034 },
    { key = "predaxas",   label = L["WB_Predaxas_Label"],   note = L["WB_Predaxas_Note"],   zone = 2405, match = "predaxas", questId = 92636 },
}

local WEEK_SECONDS = 7 * 24 * 60 * 60
local MIDNIGHT_SEASON_START_RESET = 1773727200
local DONE_COLOR = { 0.30, 0.90, 0.55 }
local ACTIVE_COLOR = { 1.00, 0.82, 0.30 }
local NEXT_COLOR = { 0.75, 0.78, 0.86 }
local function NormalizeText(text)
    if type(text) ~= "string" then
        return ""
    end

    return text:lower():gsub("[^%a%d]", "")
end

local function GetWorldBossQuestCache()
    local profile = MR.db and MR.db.profile
    if not profile then
        return {}
    end

    if not profile.worldBossQuestIDs then
        profile.worldBossQuestIDs = {}
    end

    return profile.worldBossQuestIDs
end

local function SyncWorldBossKillRecord(bossKey)
    local char = MR.db and MR.db.char
    if not char or not bossKey then return end

    if not char.worldBossKills then
        char.worldBossKills = {}
    end

    local weekKey = MR:GetCurrentWeekKey()
    if not weekKey or weekKey == 0 then return end

    local existing = char.worldBossKills[bossKey]
    if existing and existing.w == weekKey then
        return false
    end

    char.worldBossKills[bossKey] = {
        w = weekKey,
        t = GetServerTime(),
    }
    return true
end

local function GetWorldBossKillStatus(bossKey)
    local char = MR.db and MR.db.char
    if not char or not char.worldBossKills then return nil end

    local weekKey = MR:GetCurrentWeekKey()
    if not weekKey or weekKey == 0 then return nil end

    local rec = char.worldBossKills[bossKey]
    if not rec or rec.w ~= weekKey then
        return nil
    end

    return "week"
end

local function IsInMidnightMap()
    local current = C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not current then return false end

    local checked = 0
    while current and checked < 10 do
        if MIDNIGHT_MAP_IDS[current] then
            return true
        end
        local info = C_Map.GetMapInfo(current)
        current = info and info.parentMapID
        checked = checked + 1
    end

    return false
end

local function FindWorldBossQuestID(mapID, matchText, bossKey)
    local cache = GetWorldBossQuestCache()

    if not (C_TaskQuest and C_TaskQuest.GetQuestsForPlayerByMapID) then
        return bossKey and cache[bossKey] or nil
    end

    local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapID)
    if not quests then
        return bossKey and cache[bossKey] or nil
    end

    local needle = NormalizeText(matchText)
    for _, info in ipairs(quests) do
        local questID = info.questId or info.questID
        if questID then
            local title = MR:GetQuestName(questID)
            if title and NormalizeText(title):find(needle, 1, true) then
                if bossKey then
                    cache[bossKey] = questID
                end
                return questID
            end
        end
    end

    return bossKey and cache[bossKey] or nil
end

local function FormatRemaining(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)

    if days > 0 then
        return string.format(L["WB_Timer_DaysHours"] or "%dd %dh", days, hours)
    end

    local minutes = math.floor((seconds % 3600) / 60)
    return string.format(L["WB_Timer_HoursMins"] or "%dh %dm", hours, minutes)
end

local function GetActiveWorldBossState(now)
    now = now or GetServerTime()
    local currentReset = MR.GetLastResetTimestamp and MR:GetLastResetTimestamp() or now
    local weeksSinceStart = math.max(0, math.floor((currentReset - MIDNIGHT_SEASON_START_RESET) / WEEK_SECONDS))
    local activeIndex = (weeksSinceStart % #WORLD_BOSS_ROTATION) + 1

    return WORLD_BOSS_ROTATION[activeIndex], activeIndex, currentReset, currentReset + WEEK_SECONDS
end

local function IsActiveWorldBossRow(rowKey)
    local activeBoss = GetActiveWorldBossState()
    return activeBoss and activeBoss.key == rowKey or false
end

function MR:GetActiveWorldBossInfo()
    local boss, index, currentReset, nextReset = GetActiveWorldBossState()
    return boss, index, currentReset, nextReset
end

function MR:IsCurrentWorldBossCompleted()
    local activeBoss = GetActiveWorldBossState()
    if not activeBoss then
        return false
    end

    local questID = activeBoss.questId or FindWorldBossQuestID(activeBoss.zone, activeBoss.match, activeBoss.key)
    if questID and C_QuestLog.IsQuestFlaggedCompleted(questID) then
        SyncWorldBossKillRecord(activeBoss.key)
        return true
    end

    return GetWorldBossKillStatus(activeBoss.key) ~= nil
end

function MR:SyncCurrentWorldBossKillByName(name)
    if type(name) ~= "string" or name == "" then
        return false
    end

    local activeBoss = GetActiveWorldBossState()
    if not activeBoss then
        return false
    end

    local normalizedName = NormalizeText(name)
    local normalizedLabel = NormalizeText(activeBoss.label)
    if normalizedName == NormalizeText(activeBoss.match)
        or normalizedName == normalizedLabel
        or normalizedName:find(NormalizeText(activeBoss.match), 1, true)
        or normalizedName:find(normalizedLabel, 1, true) then
        SyncWorldBossKillRecord(activeBoss.key)
        return true
    end

    return false
end

local function GetWorldBossRowSignature(database, boss, row)
    local color = row.countColor
    return tostring(database[boss.key])
        .. "\031" .. tostring(row.countText)
        .. "\031" .. tostring(color and color[1])
        .. "\031" .. tostring(color and color[2])
        .. "\031" .. tostring(color and color[3])
end

MR:RegisterModule({
    key         = "world_bosses",
    label       = L["WB_Title"],
    labelColor  = "#ff4444",
    resetType   = "weekly",
    defaultOpen = true,
    isVisible = function() return not MR:IsPatchAvailable("12.1.0") end,
    scanReturnsChanged = true,

    onScan = function(mod)
        local db = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end

        local now = GetServerTime()
        local _, activeIndex, currentReset, nextReset = GetActiveWorldBossState(now)
        local before = {}
        for index, boss in ipairs(WORLD_BOSS_ROTATION) do
            before[index] = GetWorldBossRowSignature(db[mod.key], boss, mod.rows[index])
        end

        local changed = false

        for index, boss in ipairs(WORLD_BOSS_ROTATION) do
            local row = mod.rows[index]
            local isActive = index == activeIndex
            local questID = boss.questId or FindWorldBossQuestID(boss.zone, boss.match, boss.key)
            if questID and C_QuestLog.IsQuestFlaggedCompleted(questID) then
                SyncWorldBossKillRecord(boss.key)
            end

            local isDone = GetWorldBossKillStatus(boss.key) ~= nil

            db[mod.key][boss.key] = isDone and 1 or 0

            if isActive then
                local remaining = nextReset - now
                if isDone then
                    row.countText = string.format("%s - %s", L["Done"] or "Done", FormatRemaining(remaining))
                    row.countColor = DONE_COLOR
                else
                    row.countText = string.format(L["WB_Timer_Active"] or "Active - %s", FormatRemaining(remaining))
                    row.countColor = ACTIVE_COLOR
                end
            else
                local weekOffset = (index - activeIndex + #WORLD_BOSS_ROTATION) % #WORLD_BOSS_ROTATION
                local startAt = currentReset + (weekOffset * WEEK_SECONDS)
                row.countText = string.format(L["WB_Timer_Next"] or "Next - %s", FormatRemaining(startAt - now))
                row.countColor = NEXT_COLOR
            end

            local after = GetWorldBossRowSignature(db[mod.key], boss, row)
            if after ~= before[index] then
                changed = true
            end
        end
        return changed
    end,

    rows = {
        { key = "luashal",    label = L["WB_Luashal_Label"],    note = L["WB_Luashal_Note"],    max = 1, autoTracked = true, isVisible = function() return IsActiveWorldBossRow("luashal") end },
        { key = "cragpine",   label = L["WB_Cragpine_Label"],   note = L["WB_Cragpine_Note"],   max = 1, autoTracked = true, isVisible = function() return IsActiveWorldBossRow("cragpine") end },
        { key = "thormbelan", label = L["WB_Thormbelan_Label"], note = L["WB_Thormbelan_Note"], max = 1, autoTracked = true, isVisible = function() return IsActiveWorldBossRow("thormbelan") end },
        { key = "predaxas",   label = L["WB_Predaxas_Label"],   note = L["WB_Predaxas_Note"],   max = 1, autoTracked = true, isVisible = function() return IsActiveWorldBossRow("predaxas") end },
    },
})
