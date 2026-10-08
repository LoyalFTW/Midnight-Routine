local _, addonNS = ...
local tracking = addonNS.Tracking

function tracking.API:CreateProfessionKnowledgeTracker(MR, context)
local ns = context.namespace
local waypointLocationIndex = context.waypointLocationIndex
local watchedItemIDs, watchedQuestIDs, watchedCurrencyIDs, itemCacheFrame

local function IsEntryVisible(entry)
    if entry.kind == "darkmoon" then
        return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() or false
    end
    return true
end

local RECURRING_SECTION_KEYS = { weekly = true, darkmoon = true, lures = true }

local function IsRecurringSection(section)
    return section and RECURRING_SECTION_KEYS[section.key] == true
end

local function HasProfessionLearned(skillLine, source)
    if MR.isForever then return ns.Forever.HasProfession(skillLine) end
    if source and MR.HasProfessionForModule then
        return MR:HasProfessionForModule(skillLine, source)
    end

    if MR.playerProfessions and MR.playerProfessions[skillLine] then
        return true
    end

    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
        local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLine)
        if info and (info.skillLevel or 0) > 0 then
            return true
        end
    end

    return false
end

ns.HasProfessionLearned = HasProfessionLearned
function ns.IsProfessionLearnedForSource(profession, source)
    return profession and HasProfessionLearned(profession.skillLine, source) or false
end

local function QuestIDs(entry)
    if entry.questIDs then return entry.questIDs end
    if entry.questIds then return entry.questIds end
    if entry.questID then return { entry.questID } end
    return {}
end

local function Required(entry)
    if entry.mode == "count" then return entry.required or #QuestIDs(entry) end
    return 1
end

local function IsSpellOnCooldown(spellID)
    if not spellID then
        return false
    end

    local startTime, duration = 0, 0
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then
            startTime = info.startTime or 0
            duration = info.duration or 0
        end
    end

    if duration <= 1.5 and GetSpellCooldown then
        local legacyStart, legacyDuration = GetSpellCooldown(spellID)
        startTime = legacyStart or startTime
        duration = legacyDuration or duration
    end

    if duration <= 1.5 then
        return false
    end

    return ((startTime or 0) + duration) > GetTime()
end

ns.IsSpellOnCooldown = IsSpellOnCooldown

local function Completed(entry)
    if entry.spellID then
        return IsSpellOnCooldown(entry.spellID) and 1 or 0
    end

    local total = 0
    for _, questID in ipairs(QuestIDs(entry)) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then total = total + 1 end
    end
    return total
end

local function Progress(entry)
    local completed = Completed(entry)
    local required = Required(entry)
    if entry.mode == "count" then
        return math.min(completed, required), required
    end
    if completed > 0 then return 1, 1 end
    return 0, 1
end

function MR:GetProfessionKnowledgeEntryProgress(entry)
    entry = (entry and entry.professionKnowledgeEntry) or entry
    if not entry then
        return 0, 1
    end
    return Progress(entry)
end

local function IsDone(entry)
    local current, required = Progress(entry)
    return current >= required
end

local function KPDone(entry)
    local current = Progress(entry)
    if entry.mode == "count" then return (entry.kp or 0) * current end
    return current > 0 and (entry.kp or 0) or 0
end

local function KPTotal(entry)
    return (entry.mode == "count" and Required(entry) or 1) * (entry.kp or 0)
end

local function SectionStats(section)
    local done, total, kpDone, kpTotal = 0, 0, 0, 0
    for _, entry in ipairs(section.entries) do
        if IsEntryVisible(entry) then
            total = total + 1
            if IsDone(entry) then done = done + 1 end
            kpDone = kpDone + KPDone(entry)
            kpTotal = kpTotal + KPTotal(entry)
        end
    end
    return done, total, kpDone, kpTotal
end

local function ProfessionStats(profession)
    local done, total, kpDone, kpTotal = 0, 0, 0, 0
    for _, section in ipairs(profession.sections) do
        if not IsRecurringSection(section) then
            local sd, st, skd, skt = SectionStats(section)
            done = done + sd
            total = total + st
            kpDone = kpDone + skd
            kpTotal = kpTotal + skt
        end
    end
    return done, total, kpDone, kpTotal
end

local function ProfessionWeeklyStats(profession)
    local kpDone, kpTotal = 0, 0
    for _, section in ipairs(profession.sections) do
        if IsRecurringSection(section) then
            for _, entry in ipairs(section.entries) do
                if IsEntryVisible(entry) then
                    kpDone = kpDone + KPDone(entry)
                    kpTotal = kpTotal + KPTotal(entry)
                end
            end
        end
    end
    return kpDone, kpTotal
end

local function GetProfessionSkillSummary(skillLineID)
    if not (C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID) then
        return nil
    end

    local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
    if not info then
        return nil
    end

    local skill = info.skillLevel or 0
    local maxSkill = info.maxSkillLevel or 0
    if skill <= 0 or maxSkill <= 0 then
        return nil
    end

    local bonus = info.bonusSkillLevel or info.bonusSkill or 0
    if bonus > 0 then
        return string.format("%d/%d +%d", skill, maxSkill, bonus)
    end

    return string.format("%d/%d", skill, maxSkill)
end

local function GetCurrencyRemaining(currencyID)
    if not (currencyID and currencyID > 0 and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return 0
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info then
        return 0
    end

    local maxQuantity = info.maxQuantity or 0
    local quantity = info.quantity or 0
    if maxQuantity > 0 then
        return math.max(maxQuantity - quantity, 0)
    end

    return quantity
end

local function GetItemCountRemaining(itemID)
    if not (itemID and C_Item and C_Item.GetItemCount) then
        return 0
    end
    return C_Item.GetItemCount(itemID, false, false, true) or 0
end

local function GetProfessionCatchupAmount(profession, expansion)
    if profession.catchupCurrency then
        return GetCurrencyRemaining(profession.catchupCurrency)
    end

    if expansion and expansion.sharedCatchupItemID then
        return GetItemCountRemaining(expansion.sharedCatchupItemID)
    end

    return 0
end

local function GetProfessionCatchupProgress(profession)
    if not (profession.catchupCurrency and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return nil
    end
    local info = C_CurrencyInfo.GetCurrencyInfo(profession.catchupCurrency)
    if not info then
        return nil
    end

    if info.maxQuantity and info.maxQuantity > 0 then
        local done = (info.useTotalEarnedForMaxQty and info.totalEarned) or info.quantity or 0
        return done, info.maxQuantity
    elseif info.maxWeeklyQuantity and info.maxWeeklyQuantity > 0 then
        return info.quantityEarnedThisWeek or 0, info.maxWeeklyQuantity
    end

    return nil
end

local function GetProfessionTaskCategory(row)
    local key = row and row.key or ""
    if key:find("treatise") then
        return "treatises"
    elseif key:find("dmf") then
        return "darkmoon"
    elseif key == "prof_catchup" then
        return "catchup"
    elseif key:find("drop") or key:find("rock") or key:find("plumes") or key:find("bone") or key:find("essence") or key:find("shard") or key:find("tail") or key:find("nodule") then
        return "drops"
    elseif key:find("quest") or key:find("notebook") then
        return "quests"
    end

    return "other"
end

local function GetProfessionTaskModules(profession, filterFn)
    local modules = {}
    if not (profession and profession.skillLine and MR.modules) then
        return modules
    end

    for _, mod in ipairs(MR.modules) do
        if mod.profSkillLine == profession.skillLine and MR:IsModuleEnabled(mod.key) then
            local modVisible = not mod.isVisible or mod:isVisible()
            if modVisible and (not filterFn or filterFn(mod)) then
                modules[#modules + 1] = mod
            end
        end
    end

    table.sort(modules, function(a, b)
        return (a.order or 9999) < (b.order or 9999)
    end)
    return modules
end

local function GetProfessionTaskProgress(mod, row)
    if row and (row.professionKnowledgeEntry or row.profKnowledgeSectionKey) then
        local current, required = Progress(row.professionKnowledgeEntry or row)
        local max = tonumber(row.max) or required
        if max and max > 0 and not row.noMax then
            return math.min(current or 0, max), max, (current or 0) >= max
        end
        return current or 0, nil, (current or 0) > 0
    end

    local current = MR:GetProgress(mod.key, row.key) or 0
    local max = tonumber(row.max)
    if max and max > 0 and not row.noMax then
        return math.min(current, max), max, current >= max
    end

    return current, nil, current and current > 0
end

local function GetProfessionTaskRows(profession, filterFn)
    if MR.isForever then return ns.Forever.GetProfessionTasks(profession) end
    local rows = {}
    local doneCount, totalCount = 0, 0
    local db = MR.db and MR.db.profile or {}

    for _, mod in ipairs(GetProfessionTaskModules(profession, filterFn)) do
        for _, row in ipairs(mod.rows or {}) do
            local rowVisible = not row.isVisible or row.isVisible()
            local category = GetProfessionTaskCategory(row)
            local rowEnabled = MR:IsRowEnabled(mod.key, row.key)
            if rowVisible and rowEnabled then
                local current, max, done = GetProfessionTaskProgress(mod, row)
                if not (done and db.gatheringHideCompleted) then
                    rows[#rows + 1] = {
                        mod = mod,
                        row = row,
                        category = category,
                        group = row.group or category,
                        done = done,
                        current = current,
                        max = max,
                    }
                end
                if max then
                    totalCount = totalCount + 1
                    if done then doneCount = doneCount + 1 end
                end
            end
        end
    end

    return rows, doneCount, totalCount
end

local function IsSkinningLuresModule(mod)
    return mod and mod.key == "skin_lures"
end

local function IsProfessionKnowledgeModule(mod)
    return not IsSkinningLuresModule(mod)
end

local function GetQuestSpecificLocations(entry)
    local locations = {}
    local seen = {}
    if entry and entry.questLocations then
        for _, questID in ipairs(QuestIDs(entry)) do
            local location = entry.questLocations[questID]
            if location and location.zone and location.x and location.y then
                local key = tostring(location.zone) .. ":" .. tostring(location.x) .. ":" .. tostring(location.y)
                if not seen[key] then
                    seen[key] = true
                    locations[#locations + 1] = location
                end
            end
        end
    end
    return locations
end

local function GetWaypointTarget(entry, cycleKey)
    local locations = GetQuestSpecificLocations(entry)
    if #locations > 0 then
        for _, questID in ipairs(QuestIDs(entry)) do
            if C_QuestLog and C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(questID) then
                local location = entry.questLocations[questID]
                if location and location.zone and location.x and location.y then
                    return location, #locations
                end
            end
        end
        local index = waypointLocationIndex[cycleKey] or 1
        if index < 1 or index > #locations then index = 1 end
        return locations[index], #locations
    end
    if entry and entry.zone and entry.x and entry.y then
        return entry, 1
    end
    return nil, 0
end

local function EnsureGatheringWatchFrame()
    if itemCacheFrame then return end
    watchedItemIDs = {}
    watchedQuestIDs = {}
    watchedCurrencyIDs = {}
    for _, expansion in ipairs(context.expansions or {}) do
        for _, profession in ipairs(expansion.professions or {}) do
            if profession.catchupCurrency then watchedCurrencyIDs[profession.catchupCurrency] = true end
            for _, section in ipairs(profession.sections or {}) do
                for _, entry in ipairs(section.entries or {}) do
                    if entry.itemID then watchedItemIDs[entry.itemID] = true end
                    if entry.questID then watchedQuestIDs[entry.questID] = true end
                    for _, questID in ipairs(entry.questIDs or {}) do
                        watchedQuestIDs[questID] = true
                    end
                end
            end
        end
    end

    itemCacheFrame = CreateFrame("Frame")
    itemCacheFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    itemCacheFrame:RegisterEvent("QUEST_TURNED_IN")
    itemCacheFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    itemCacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    itemCacheFrame:RegisterEvent("TRADE_SKILL_SHOW")
    itemCacheFrame:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
    itemCacheFrame:SetScript("OnEvent", function(self, event, itemID)
        if event == "GET_ITEM_INFO_RECEIVED" then
            if not watchedItemIDs[itemID] then return end
            context.requestRefresh()
            return
        end

        if event == "QUEST_TURNED_IN" and itemID and not watchedQuestIDs[itemID] then
            return
        end

        if event == "CURRENCY_DISPLAY_UPDATE" and itemID and not watchedCurrencyIDs[itemID] then
            return
        end

        if event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" then
            local changed = MR.RefreshPlayerProfessions and MR:RefreshPlayerProfessions()
            if changed then
                if MR.RequestScan then MR:RequestScan(1) end
                context.requestRefresh(true)
            end
            return
        end

        context.requestRefresh()
    end)
end

function MR:GetProfessionKnowledgeWatchCounts()
    local function Count(values)
        local total = 0
        for _ in pairs(values or {}) do
            total = total + 1
        end
        return total
    end
    return Count(watchedItemIDs), Count(watchedQuestIDs), Count(watchedCurrencyIDs), itemCacheFrame ~= nil
end


return {
    IsEntryVisible = IsEntryVisible,
    HasProfessionLearned = HasProfessionLearned,
    QuestIDs = QuestIDs,
    Required = Required,
    IsSpellOnCooldown = IsSpellOnCooldown,
    Progress = Progress,
    IsDone = IsDone,
    KPDone = KPDone,
    KPTotal = KPTotal,
    SectionStats = SectionStats,
    ProfessionStats = ProfessionStats,
    ProfessionWeeklyStats = ProfessionWeeklyStats,
    GetProfessionSkillSummary = GetProfessionSkillSummary,
    GetItemCountRemaining = GetItemCountRemaining,
    GetProfessionCatchupAmount = GetProfessionCatchupAmount,
    GetProfessionCatchupProgress = GetProfessionCatchupProgress,
    GetProfessionTaskRows = GetProfessionTaskRows,
    IsSkinningLuresModule = IsSkinningLuresModule,
    IsProfessionKnowledgeModule = IsProfessionKnowledgeModule,
    GetQuestSpecificLocations = GetQuestSpecificLocations,
    GetWaypointTarget = GetWaypointTarget,
    EnsureGatheringWatchFrame = EnsureGatheringWatchFrame,
}
end
