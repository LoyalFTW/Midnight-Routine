local _, ns = ...
local MR = ns.MR

local SCAN_THROTTLE      = 2
local GILDED_STASH_WIDGET_ID = 7591
local GILDED_STASH_REQUIRED = 4
local GILDED_STASH_OBJECT_IDS = {
    [584507] = true,
    [506498] = true,
}
local DELVERS_BOUNTY_ITEMS = {
    274374,
    252415,
    265714,
}

local QUEST_DELVERS_BOUNTY_LOOTED = 86371
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local EXPANSIONS = {
    {
        label  = L["Midnight"],
        mapIds = { [2393]=true, [2395]=true, [2405]=true, [2413]=true, [2424]=true, [2437]=true, [2512]=true, [2633]=true, [2635]=true },
        zones  = {
            { uiMapId = 2393, delves = { {8426,8425,91186}, {8440,8439,92444} } },
            { uiMapId = 2424, delves = { {8428,8427,91182} } },
            { uiMapId = 2395, delves = { {8438,8437,91189} } },
            { uiMapId = 2405, delves = { {8432,8431,91184}, {8430,8429,91183} } },
            { uiMapId = 2413, delves = { {8434,8433,91185}, {8436,8435,91187} } },
            { uiMapId = 2437, delves = { {8444,8443,91188}, {8442,8441,91190} } },
            { uiMapId = 2512, delves = { {8763,8764,95715}, {8760,8761,95716} } },
        },
    },
    {
        label  = L["Delves_WarWithin"],
        mapIds = { [2248]=true, [2214]=true, [2215]=true, [2255]=true, [2346]=true, [2371]=true },
        zones  = {
            { uiMapId = 2248, delves = { {7779,7864,82939}, {7781,7865,82941}, {7787,7863,82944} } },
            { uiMapId = 2214, delves = { {7782,7866,82945}, {7788,7867,82938}, {8181,8143,85187} } },
            { uiMapId = 2215, delves = { {7780,7869,82940}, {7783,7870,82937}, {7785,7868,82777}, {7789,7871,78508} } },
            { uiMapId = 2255, delves = { {7784,7873,82776}, {7786,7872,82943}, {7790,7874,82942} } },
            { uiMapId = 2346, delves = { {8246,8140,85668} } },
            { uiMapId = 2371, delves = { {8273,8274,0} } },
        },
    },
}

local function GetPlayerExpansion()
    local mapId = C_Map.GetBestMapForUnit("player")
    if mapId then
        for _ = 1, 6 do
            for _, exp in ipairs(EXPANSIONS) do
                if exp.mapIds[mapId] then return exp end
            end
            local info = C_Map.GetMapInfo(mapId)
            if not info or not info.parentMapID or info.parentMapID == 0 then break end
            mapId = info.parentMapID
        end
    end
    return EXPANSIONS[1]
end

for _, exp in ipairs(EXPANSIONS) do
    local total = 0
    for _, zone in ipairs(exp.zones) do total = total + #zone.delves end
    exp.total = total
end

local function ScanExpansion(exp, mdb)
    if not (C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIInfo) then return end

    local active  = 0
    local total   = 0
    local entries = {}

    for _, zone in ipairs(exp.zones) do
        local zoneName = (C_Map.GetMapInfo(zone.uiMapId) or {}).name or "Unknown"
        for _, pair in ipairs(zone.delves) do
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(zone.uiMapId, pair[1])
            if poiInfo then
                total = total + 1
                active = active + 1
                entries[#entries + 1] = zoneName .. ": " .. (poiInfo.name or "?")
            end
        end
    end

    mdb["bountiful_live"]    = active
    mdb["bountiful_total"]   = total
    mdb["bountiful_entries"] = table.concat(entries, "\n")
    mdb["bountiful_exp"]     = total > 0 and exp.label or nil
end

local function IsQuestCompleted(questId)
    if not (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted and questId) then
        return false
    end

    return C_QuestLog.IsQuestFlaggedCompleted(questId) == true
end

local function HasDelversBounty()
    if not (C_Item and C_Item.GetItemCount) then
        return false
    end

    for _, itemId in ipairs(DELVERS_BOUNTY_ITEMS) do
        if (C_Item.GetItemCount(itemId, true, false, true, true) or 0) > 0 then
            return true
        end
    end

    return false
end

local function GetGildedStashTooltip()
    local getter = C_UIWidgetManager and C_UIWidgetManager.GetSpellDisplayVisualizationInfo
    if not getter then
        return nil
    end

    local ok, widget = pcall(getter, GILDED_STASH_WIDGET_ID)
    local spellInfo = ok and type(widget) == "table" and widget.spellInfo or nil
    if type(spellInfo) == "table"
        and type(spellInfo.tooltip) == "string"
        and spellInfo.tooltip ~= "" then
        return spellInfo.tooltip
    end

    return nil
end

local function GetWorldActivityProgress()
    local progress = {}
    if not (C_WeeklyRewards and C_WeeklyRewards.GetSortedProgressForActivity) then
        return progress
    end

    local activityType = Enum
        and Enum.WeeklyRewardChestThresholdType
        and Enum.WeeklyRewardChestThresholdType.World
        or 6
    return C_WeeklyRewards.GetSortedProgressForActivity(activityType, true) or progress
end

local bountifulRow
local bountyRow
local gildedStashRow
local lastScan = 0
local pendingScanTimer
local DELVES_SCAN_KEYS = { "delves" }
local seenGildedStashSources = {}

local function IsBountyRowComplete(done)
    return (tonumber(done) or 0) >= 1
end

local function ExtractTooltipProgress(text)
    if type(text) ~= "string" or text == "" then
        return nil, nil
    end

    local fallbackCurrent, fallbackTotal
    for current, total in text:gmatch("(%d+)%s*/%s*(%d+)") do
        current = tonumber(current)
        total = tonumber(total)
        if current and total and total > 0 then
            if total == GILDED_STASH_REQUIRED then
                return current, total
            end

            if not fallbackCurrent then
                fallbackCurrent = current
                fallbackTotal = total
            end
        end
    end

    return fallbackCurrent, fallbackTotal
end

local function GetGildedStashFloor(mdb)
    local saved = tonumber(mdb and mdb.gilded_stash) or 0
    local manual = MR.GetManualOverride and tonumber(MR:GetManualOverride("delves", "gilded_stash")) or 0
    return math.max(saved, manual)
end

local function UpdateGildedStashProgress(mdb, row)
    if type(mdb) ~= "table" or not row then
        return false
    end

    local storedValue = tonumber(mdb["gilded_stash"]) or 0
    local oldValue = GetGildedStashFloor(mdb)
    local oldTotal = tonumber(mdb["gilded_stash_total"]) or 0
    local oldMax = tonumber(row.max) or 0
    local oldCountText = row.countText
    local oldNote = row.note

    local tooltip = GetGildedStashTooltip()
    local fulfilled, required = ExtractTooltipProgress(tooltip)
    local hasLiveData = fulfilled ~= nil

    if hasLiveData then
        required = required or GILDED_STASH_REQUIRED
        fulfilled = math.max(oldValue, math.max(0, math.min(fulfilled, required)))
        mdb["gilded_stash"] = fulfilled
        mdb["gilded_stash_total"] = required
        row.max = required
        row.countText = nil
        row.countColor = nil
        row.note = L["Delves_GildedStash_Note"] or "Requires Delver's Journey Rank 4; loot up to 4 Gilded Stashes from Tier 11 Delves each week."
        return storedValue ~= fulfilled
            or oldTotal ~= required
            or oldMax ~= required
            or oldCountText ~= row.countText
            or oldNote ~= row.note
    end

    row.max = (tonumber(mdb["gilded_stash_total"]) or 0) > 0 and mdb["gilded_stash_total"] or GILDED_STASH_REQUIRED
    row.note = L["Delves_GildedStash_Note"] or "Requires Delver's Journey Rank 4; loot up to 4 Gilded Stashes from Tier 11 Delves each week."

    if (tonumber(mdb["gilded_stash"]) or 0) >= row.max then
        row.countText = L["Done"] or "Done"
        row.countColor = { 0.40, 0.85, 0.40 }
    else
        row.countText = nil
        row.countColor = nil
    end

    return storedValue ~= (tonumber(mdb["gilded_stash"]) or 0)
        or oldTotal ~= (tonumber(mdb["gilded_stash_total"]) or 0)
        or oldMax ~= (tonumber(row.max) or 0)
        or oldCountText ~= row.countText
        or oldNote ~= row.note
end

MR:RegisterModule({
    key         = "delves",
    label       = L["Delves"],
    labelColor  = "#c8956c",
    resetType   = "weekly",
    defaultOpen = false,
    scanReturnsChanged = true,

    onScan = function(mod)
        local now = GetTime()
        if (now - lastScan) < SCAN_THROTTLE then
            if not pendingScanTimer and MR.ScheduleTimer then
                pendingScanTimer = MR:ScheduleTimer(function()
                    pendingScanTimer = nil
                    MR:RefreshModuleScans(DELVES_SCAN_KEYS, true)
                end, SCAN_THROTTLE - (now - lastScan))
            end
            return false
        end
        if pendingScanTimer and MR.CancelTimer then
            MR:CancelTimer(pendingScanTimer)
            pendingScanTimer = nil
        end
        lastScan = now
        local db  = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end
        local mdb = db[mod.key]
        local beforeProgress = {}
        for key, value in pairs(mdb) do
            beforeProgress[key] = value
        end
        local beforeRows = {
            bountiful_count = bountifulRow and {
                countText = bountifulRow.countText,
                countColor = bountifulRow.countColor and { unpack(bountifulRow.countColor) } or nil,
                max = bountifulRow.max,
                note = bountifulRow.note,
            } or nil,
            delve_bounty = bountyRow and {
                countText = bountyRow.countText,
                countColor = bountyRow.countColor and { unpack(bountyRow.countColor) } or nil,
                max = bountyRow.max,
                note = bountyRow.note,
            } or nil,
            gilded_stash = gildedStashRow and {
                countText = gildedStashRow.countText,
                countColor = gildedStashRow.countColor and { unpack(gildedStashRow.countColor) } or nil,
                max = gildedStashRow.max,
                note = gildedStashRow.note,
            } or nil,
        }
        local function HasChanges()
            for key, value in pairs(mdb) do
                if beforeProgress[key] ~= value then
                    return true
                end
            end
            for key in pairs(beforeProgress) do
                if mdb[key] ~= beforeProgress[key] then
                    return true
                end
            end
            for rowKey, beforeRow in pairs(beforeRows) do
                local row = rowKey == "bountiful_count" and bountifulRow
                    or rowKey == "delve_bounty" and bountyRow
                    or gildedStashRow
                if beforeRow and row then
                    local beforeColor = beforeRow.countColor
                    local afterColor = row.countColor
                    local sameColor = (beforeColor == afterColor)
                        or (type(beforeColor) == "table" and type(afterColor) == "table"
                            and (beforeColor[1] or 0) == (afterColor[1] or 0)
                            and (beforeColor[2] or 0) == (afterColor[2] or 0)
                            and (beforeColor[3] or 0) == (afterColor[3] or 0)
                            and (beforeColor[4] or 0) == (afterColor[4] or 0))
                    if beforeRow.countText ~= row.countText
                        or beforeRow.max ~= row.max
                        or beforeRow.note ~= row.note
                        or not sameColor then
                        return true
                    end
                end
            end
            return false
        end

        local exp = GetPlayerExpansion()
        if exp then
            ScanExpansion(exp, mdb)
            bountifulRow.max = mdb["bountiful_total"] > 0 and mdb["bountiful_total"] or exp.total
            if mdb["bountiful_total"] and mdb["bountiful_total"] > 0 then
                bountifulRow.countText = string.format(L["Count_Active"] or "%d active", mdb["bountiful_total"])
                bountifulRow.countColor = { 1.0, 0.82, 0.30 }
            else
                bountifulRow.countText = nil
                bountifulRow.countColor = nil
            end
        else
            mdb["bountiful_live"]    = 0
            mdb["bountiful_total"]   = 0
            mdb["bountiful_entries"] = ""
            mdb["bountiful_exp"]     = nil
            bountifulRow.countText = nil
            bountifulRow.countColor = nil
        end

        local buckets = MR.GetWeeklyRewardActivityBuckets and MR:GetWeeklyRewardActivityBuckets() or nil
        local savedRuns = tonumber(mdb["delve_runs"]) or 0
        local manualRuns = MR.GetManualOverride and tonumber(MR:GetManualOverride("delves", "delve_runs")) or 0
        if buckets and buckets.world and buckets.world[1] then
            local bestRuns = 0
            for _, act in ipairs(buckets.world) do
                if (act.progress or 0) > bestRuns then
                    bestRuns = act.progress or 0
                end
            end

            bestRuns = math.max(bestRuns, savedRuns, manualRuns)

            if mdb["delve_runs"] ~= bestRuns then mdb["delve_runs"] = bestRuns end
        else
            local bestRuns = math.max(savedRuns, manualRuns)
            if mdb["delve_runs"] ~= bestRuns then mdb["delve_runs"] = bestRuns end
        end

        local bountyLooted = IsQuestCompleted(QUEST_DELVERS_BOUNTY_LOOTED) and 1 or 0
        local bountyProgress = bountyLooted > 0 and not HasDelversBounty() and 1 or 0

        if mdb["delve_bounty"] ~= bountyProgress then
            mdb["delve_bounty"] = bountyProgress
        end

        if bountyRow then
            if bountyProgress == 1 then
                bountyRow.countText = L["Used"] or "Used"
                bountyRow.countColor = { 0.40, 0.85, 0.40 }
            elseif bountyLooted > 0 then
                bountyRow.countText = L["Collected"] or "Collected"
                bountyRow.countColor = { 1.00, 0.82, 0.30 }
            else
                bountyRow.countText = nil
                bountyRow.countColor = nil
            end
        end

        UpdateGildedStashProgress(mdb, gildedStashRow)
        return HasChanges()
    end,

    rows = {
        {
            key     = "delve_runs",
            label   = L["Delves_Runs_Label"],
            max     = 8,
            note    = L["Delves_Runs_Note"],
            liveKey = "delve_runs",
            tooltipFunc = function(tip)
                local mdb = MR.db.char.progress["delves"]
                local completed = math.min(tonumber(mdb and mdb["delve_runs"]) or 0, 8)
                local desiredRuns = 8

                tip:AddLine(" ")
                tip:AddLine(string.format(L["Delves_Runs_Progress"] or "%d / 8 completed this week", completed), 0.40, 0.85, 0.40)
                tip:AddLine(string.format(L["Delves_Runs_Top"] or "Top %d Activities This Week", desiredRuns), 1, 1, 1)

                for _, tierProgress in ipairs(GetWorldActivityProgress()) do
                    local numRuns = math.min(tonumber(tierProgress.numPoints) or 0, desiredRuns)
                    if numRuns > 0 then
                        local difficulty = tonumber(tierProgress.difficulty) or 1
                        desiredRuns = desiredRuns - numRuns
                        if difficulty > 1 then
                            tip:AddLine(string.format(L["Delves_Runs_Tier"] or "- Tier %d (%d)", difficulty, numRuns), 0.9, 0.85, 0.6)
                        else
                            tip:AddLine(string.format(L["Delves_Runs_TierWorld"] or "- Tier %d / World Activities (%d)", difficulty, numRuns), 0.9, 0.85, 0.6)
                        end
                    end
                    if desiredRuns <= 0 then
                        break
                    end
                end

                if completed == 0 then
                    tip:AddLine(L["Delves_Runs_None"] or "No qualifying activities recorded this week.", 0.6, 0.6, 0.6)
                end
            end,
        },
        {
            key   = "gilded_stash",
            label = L["Delves_GildedStash_Label"] or "|cffc8956cGilded Stash:|r",
            max   = GILDED_STASH_REQUIRED,
            note  = L["Delves_GildedStash_Note"] or "Requires Delver's Journey Rank 4; loot up to 4 Gilded Stashes from Tier 11 Delves each week.",
            tooltipFunc = function(tip)
                local mdb = MR.db.char.progress["delves"]
                local tooltip = GetGildedStashTooltip()

                tip:AddLine(" ")
                if tooltip and tooltip ~= "" then
                    for line in tooltip:gmatch("[^\n]+") do
                        tip:AddLine(line, 0.9, 0.85, 0.6, true)
                    end
                elseif mdb and (tonumber(mdb["gilded_stash"]) or 0) > 0 then
                    tip:AddLine(
                        string.format(
                            "%d / %d",
                            tonumber(mdb["gilded_stash"]) or 0,
                            tonumber(mdb["gilded_stash_total"]) or GILDED_STASH_REQUIRED
                        ),
                        0.9, 0.85, 0.6
                    )
                    tip:AddLine(L["Delves_GildedStash_Refresh"] or "Open the Gilded Stash at the end of a completed Tier 11 Delve to update this weekly count.", 0.6, 0.6, 0.6, true)
                else
                    tip:AddLine(L["Delves_GildedStash_Refresh"] or "Open the Gilded Stash at the end of a completed Tier 11 Delve to update this weekly count.", 0.6, 0.6, 0.6, true)
                end
            end,
        },
        {
            key     = "delve_bounty",
            label   = L["Delves_Bounty_Label"],
            max     = 1,
            note    = L["Delves_Bounty_Note"],
            countWidth = 84,
            itemId  = DELVERS_BOUNTY_ITEMS[1],
            noItemProgress = true,
            liveKey = "delve_bounty",
            completeFunc = IsBountyRowComplete,
        },
        {
            key     = "bountiful_count",
            label   = L["Delves_Bountiful_Label"],
            max     = 4,
            noMax   = true,
            note    = L["Delves_Bountiful_Note"],
            countWidth = 84,
            liveKey = "bountiful_live",
            isVisible = function()
                local mdb = MR.db.char.progress["delves"]
                return mdb and (mdb["bountiful_total"] or 0) > 0
            end,
            tooltipFunc = function(tip)
                local mdb     = MR.db.char.progress["delves"]
                local expName = mdb and mdb["bountiful_exp"]
                local entries = mdb and mdb["bountiful_entries"]
                tip:AddLine(" ")
                if expName then
                    tip:AddLine(string.format(L["Delves_Bountiful_Today"], expName), 1, 1, 1)
                end
                if entries and entries ~= "" then
                    for line in entries:gmatch("[^\n]+") do
                        tip:AddLine("  " .. line, 0.9, 0.85, 0.6)
                    end
                else
                    tip:AddLine(L["Delves_No_Bountiful"], 0.6, 0.6, 0.6)
                end
            end,
        },
    },
})

do
    local mod = MR.moduleByKey["delves"]
    for _, r in ipairs(mod.rows) do
        if r.key == "bountiful_count" then bountifulRow = r; break end
    end
    for _, r in ipairs(mod.rows) do
        if r.key == "delve_bounty" then bountyRow = r; break end
    end
    for _, r in ipairs(mod.rows) do
        if r.key == "gilded_stash" then gildedStashRow = r; break end
    end
end

function MR:RefreshDelvesLiveProgress(refreshUI)
    local mod = self and self.moduleByKey and self.moduleByKey["delves"]
    if not (mod and self.db and self.db.char and self.db.char.progress) then
        return false
    end

    local progress = self.db.char.progress
    if not progress[mod.key] then
        progress[mod.key] = {}
    end

    local changed = UpdateGildedStashProgress(progress[mod.key], gildedStashRow)
    if changed then
        self._moduleStatsCache = nil
        if refreshUI then
            self:RefreshUI()
        end
    end

    return changed
end

function MR:RecordGildedStashLoot(refreshUI)
    if not (GetNumLootItems and GetLootSourceInfo and strsplit) then
        return false
    end

    local sourceGuid
    for slot = 1, GetNumLootItems() do
        local sources = { GetLootSourceInfo(slot) }
        for index = 1, #sources, 2 do
            local guid = sources[index]
            local objectId = type(guid) == "string" and tonumber((select(6, strsplit("-", guid)))) or nil
            if objectId and GILDED_STASH_OBJECT_IDS[objectId] then
                sourceGuid = guid
                break
            end
        end
        if sourceGuid then
            break
        end
    end

    if not sourceGuid then
        return false, false
    end
    if seenGildedStashSources[sourceGuid] then
        return false, true
    end
    seenGildedStashSources[sourceGuid] = true

    local progress = self.db and self.db.char and self.db.char.progress
    if not progress then
        return false, true
    end
    if not progress.delves then
        progress.delves = {}
    end

    local mdb = progress.delves
    local storedValue = tonumber(mdb.gilded_stash) or 0
    local oldValue = GetGildedStashFloor(mdb)
    local liveValue, liveTotal = ExtractTooltipProgress(GetGildedStashTooltip())
    local newValue = math.max(oldValue, tonumber(liveValue) or 0)
    if newValue <= oldValue then
        newValue = oldValue + 1
    end
    local required = tonumber(liveTotal) or tonumber(mdb.gilded_stash_total) or GILDED_STASH_REQUIRED
    newValue = math.min(newValue, required)

    mdb.gilded_stash = newValue
    mdb.gilded_stash_total = required
    gildedStashRow.max = required
    gildedStashRow.note = L["Delves_GildedStash_Note"] or "Requires Delver's Journey Rank 4; loot up to 4 Gilded Stashes from Tier 11 Delves each week."
    if newValue >= required then
        gildedStashRow.countText = L["Done"] or "Done"
        gildedStashRow.countColor = { 0.40, 0.85, 0.40 }
    else
        gildedStashRow.countText = nil
        gildedStashRow.countColor = nil
    end

    self._moduleStatsCache = nil
    if refreshUI then
        self:RefreshUI()
    else
        self:MarkBackgroundDataDirty()
    end
    return newValue ~= storedValue, true
end
