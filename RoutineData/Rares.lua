local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end
local L = LibStub("AceLocale-3.0"):GetLocale("RoutineData")
local tracking = RoutineData.Tracking
local isForever = RoutineData.isForever

local SCAN_DEBOUNCE = 3
local SHORT_LIST_COUNT = 4

local rareByNpcID

local function IsRoutineLoaded()
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return isLoaded and isLoaded("MidnightRoutine") and true or false
end

local function BuildIndex()
    rareByNpcID = {}
    if isForever then
        for npcID, data in pairs(tracking.Forever.rareCatalog or {}) do
            rareByNpcID[npcID] = { data.name }
        end
        return
    end
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    for _, catalog in ipairs(tracking.rareCatalogs or {}) do
        for _, rare in ipairs(catalog.rares) do
            local npcID = rare[6]
            if npcID and (not rare.faction or not faction or rare.faction == faction) then
                rareByNpcID[npcID] = rare
            end
        end
    end
end

local function GetRare(npcID)
    if not rareByNpcID then BuildIndex() end
    return rareByNpcID[npcID]
end

local function NpcIDFromGUID(guid)
    if not guid or (issecretvalue and issecretvalue(guid)) then return nil end
    if C_CreatureInfo and C_CreatureInfo.GetCreatureID then
        local ok, npcID = pcall(C_CreatureInfo.GetCreatureID, guid)
        if ok and npcID then return tonumber(npcID) end
    end
    if type(guid) ~= "string" then return nil end
    local unitType, npcID = guid:match("(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end
    return tonumber(npcID)
end

local function IsKilledNow(rare)
    local questID = rare[2]
    return questID ~= nil and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questID) == true
end

function RoutineData:ScanRares()
    local charKey = self:GetCurrentCharacterKey()
    if not charKey then return end
    if not rareByNpcID then BuildIndex() end

    local record = self:GetCharacterRecord(charKey, true)
    local kills = record.rares
    if type(kills) ~= "table" then
        kills = {}
        record.rares = kills
    end

    local now = (GetServerTime and GetServerTime()) or time()
    if isForever then
        record.updatedAt.rares = now
        return
    end
    local lastReset = self:GetLastWeeklyReset()
    for npcID, rare in pairs(rareByNpcID) do
        if IsKilledNow(rare) then
            if not kills[npcID] or kills[npcID] < lastReset then
                kills[npcID] = now
            end
        else
            kills[npcID] = nil
        end
    end
    record.updatedAt.rares = now
end

local scanQueued
local function QueueScan()
    if scanQueued then return end
    scanQueued = true
    C_Timer.After(SCAN_DEBOUNCE, function()
        scanQueued = nil
        RoutineData:ScanRares()
    end)
end

local function CharacterStatus(charKey, record, npcID, rare, currentKey, lastReset)
    if charKey == currentKey and not isForever then
        return IsKilledNow(rare) and "killed" or "open"
    end
    local seen = record.rares and record.rares[npcID]
    if seen and seen >= lastReset then return "killed" end
    local synced = record.updatedAt and record.updatedAt.rares
    if not synced or synced < lastReset then return "stale" end
    return "open"
end

local STATUS_TEXT = {
    killed = { L["Rares_Tooltip_Killed"], 0.85, 0.65, 0.10 },
    stale = { L["Rares_Tooltip_NeedsLogin"], 0.70, 0.70, 0.70 },
    open = { L["Rares_Tooltip_NotKilled"], 0.50, 0.50, 0.50 },
}

local function AddRareLines(tooltip, npcID, rare)
    local settings = RoutineData.db and RoutineData.db.settings
    if not (settings and settings.tooltipRares) then return end

    local currentKey = RoutineData:GetCurrentCharacterKey()
    local lastReset = RoutineData:GetLastWeeklyReset()
    local rows, killed = {}, 0
    for charKey, record in pairs(RoutineData.db.characters) do
        local status = CharacterStatus(charKey, record, npcID, rare, currentKey, lastReset)
        if status == "killed" then killed = killed + 1 end
        rows[#rows + 1] = { key = charKey, classFile = record.classFile, status = status, current = charKey == currentKey }
    end
    if #rows == 0 then return end

    table.sort(rows, function(a, b)
        if a.current ~= b.current then return a.current end
        if (a.status == "killed") ~= (b.status == "killed") then return a.status == "killed" end
        return a.key < b.key
    end)

    tooltip:AddLine(" ")
    local current = rows[1].current and rows[1] or nil
    if current then
        local text = STATUS_TEXT[current.status]
        tooltip:AddLine(text[1], text[2], text[3], text[4])
    end
    tooltip:AddLine(string.format(L["Rares_Tooltip_WarbandHeader"], killed, #rows), 0.65, 0.90, 1)

    local expanded = IsShiftKeyDown()
    local shown = expanded and #rows or math.min(#rows, SHORT_LIST_COUNT)
    for index = 1, shown do
        local row = rows[index]
        local text = STATUS_TEXT[row.status]
        tooltip:AddDoubleLine(RoutineData.CharacterLabel(row.key, row.classFile), text[1], 1, 1, 1, text[2], text[3], text[4])
    end
    if #rows > shown then
        tooltip:AddLine(L["Rares_Tooltip_HoldShiftFullList"], 0.55, 0.55, 0.60)
    end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
        if tooltip ~= GameTooltip or IsRoutineLoaded() then return end
        pcall(function()
            local npcID = data and NpcIDFromGUID(data.guid)
            local rare = npcID and GetRare(npcID)
            if rare and (rare[2] or isForever) then AddRareLines(tooltip, npcID, rare) end
        end)
    end)
end

local shiftWatcher = CreateFrame("Frame")
shiftWatcher:RegisterEvent("MODIFIER_STATE_CHANGED")
shiftWatcher:SetScript("OnEvent", function()
    if not IsRoutineLoaded() and GameTooltip:IsShown() and GameTooltip.RefreshData and select(2, GameTooltip:GetUnit()) then
        GameTooltip:RefreshData()
    end
end)

local function RecordRareDeath(guid)
    local npcID = NpcIDFromGUID(guid)
    local charKey = RoutineData:GetCurrentCharacterKey()
    if not (npcID and charKey and GetRare(npcID)) then return end

    local record = RoutineData:GetCharacterRecord(charKey, true)
    record.rares = record.rares or {}
    local now = (GetServerTime and GetServerTime()) or time()
    record.rares[npcID] = now
    record.updatedAt.rares = now
end

RoutineData:OnLogin(function()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    if isForever then
        if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("UNIT_DIED") then
            frame:RegisterEvent("UNIT_DIED")
        end
        frame:SetScript("OnEvent", function(_, event, guid)
            if event == "UNIT_DIED" then
                RecordRareDeath(guid)
            else
                QueueScan()
            end
        end)
    else
        frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
        frame:SetScript("OnEvent", QueueScan)
    end
end)
