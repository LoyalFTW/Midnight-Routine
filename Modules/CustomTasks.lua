local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local CUSTOM_MODULE_KEY = "custom_tasks"
local DAILY_HEADER_KEY = "__custom_task_daily_header"
local WEEKLY_HEADER_KEY = "__custom_task_weekly_header"
local NO_RESET_HEADER_KEY = "__custom_task_no_reset_header"
local DAILY_ADD_ROW_KEY = "__custom_task_add_daily"
local WEEKLY_ADD_ROW_KEY = "__custom_task_add_weekly"
local NO_RESET_ADD_ROW_KEY = "__custom_task_add_no_reset"
local TASK_SCOPE_CHARACTER = "character"
local TASK_SCOPE_SHARED = "shared"
local RESET_TYPE_COLORS = {
    daily = "#58c9d4",
    weekly = "#c9853f",
    none = "#a987d9",
}

local function TrimText(value)
    value = tostring(value or "")
    value = value:gsub("^%s+", ""):gsub("%s+$", "")
    return value
end

local function Text(key, fallback)
    local value = L[key]
    return (value and value ~= key) and value or fallback
end

local function NormalizeTaskScope(scope)
    return scope == TASK_SCOPE_SHARED and TASK_SCOPE_SHARED or TASK_SCOPE_CHARACTER
end

local function GetTaskStorage(scope)
    if not (MR and MR.db and MR.db.char) then
        return nil
    end

    scope = NormalizeTaskScope(scope)
    if scope == TASK_SCOPE_SHARED then
        MR.db.global.customTasks = MR.db.global.customTasks or {}
        MR.db.global.customTaskNextId = tonumber(MR.db.global.customTaskNextId) or 1
        return MR.db.global.customTasks
    end

    MR.db.char.customTasks = MR.db.char.customTasks or {}
    MR.db.char.customTaskNextId = tonumber(MR.db.char.customTaskNextId) or 1
    return MR.db.char.customTasks
end

local function GetTaskRowKey(taskId, scope)
    local prefix = NormalizeTaskScope(scope) == TASK_SCOPE_SHARED and "shared_task" or "task"
    return ("%s_%s"):format(prefix, tostring(taskId))
end

local function GetTaskProgressKey(taskId, scope)
    return GetTaskRowKey(taskId, scope)
end

local function NormalizeResetType(resetType)
    if resetType == "daily" then return "daily" end
    if resetType == "none" then return "none" end
    return "weekly"
end

local function NormalizeTaskMax(maxValue)
    local value = tonumber(maxValue) or 1
    value = math.floor(value)
    if value < 1 then
        value = 1
    elseif value > 999 then
        value = 999
    end
    return value
end

local function NormalizeEncounterIds(value)
    if value == nil or value == "" then
        return nil
    end

    local ids = {}
    local seen = {}

    local function addEncounterId(raw)
        local encounterId = tonumber(raw)
        if not encounterId then
            return
        end

        encounterId = math.floor(encounterId)
        if encounterId <= 0 or seen[encounterId] then
            return
        end

        seen[encounterId] = true
        ids[#ids + 1] = encounterId
    end

    if type(value) == "table" then
        for _, entry in ipairs(value) do
            addEncounterId(entry)
        end
    elseif type(value) == "number" then
        addEncounterId(value)
    elseif type(value) == "string" then
        for token in value:gmatch("%d+") do
            addEncounterId(token)
        end
    end

    if #ids == 0 then
        return nil
    end

    table.sort(ids)
    return ids
end

local function BuildEncounterIdsText(encounterIds)
    if type(encounterIds) ~= "table" or #encounterIds == 0 then
        return nil
    end

    local values = {}
    for _, encounterId in ipairs(encounterIds) do
        values[#values + 1] = tostring(encounterId)
    end
    return table.concat(values, ", ")
end

local VALID_ENCOUNTER_DIFFICULTIES = { [14]=true, [15]=true, [16]=true, [17]=true }



MR.CANONICAL_DIFFICULTY = {

    [14] = 14,
    [15] = 15,
    [16] = 16,
    [17] = 17,

    [3]  = 14,
    [4]  = 14,
    [5]  = 15,
    [6]  = 15,
    [7]  = 17,

    [24] = 14,
    [33] = 14,
}
local CANONICAL_DIFFICULTY = MR.CANONICAL_DIFFICULTY
local GetDiffProgressStorage

local function CountTrackedDifficulties(task)
    if not (task and task.encounterIds) then return 0 end

    if not task.encounterDifficulties then return 4 end
    local n = 0
    for _ in pairs(task.encounterDifficulties) do n = n + 1 end
    return n
end

local function GetDiffProgress(self, taskId, scope)
    if not self.db then return {} end
    local task = self:GetCustomTaskById(taskId, scope)
    if not task then return nil end
    local storage = GetDiffProgressStorage(task)
    if not storage then return {} end
    local key = GetTaskProgressKey(taskId, scope)
    storage[key] = storage[key] or {}
    return storage[key]
end



local function NormalizeEncounterDifficulties(value)
    if value == nil then return nil end
    if type(value) ~= "table" then return nil end
    local result, count = {}, 0
    for k, v in pairs(value) do
        local id = tonumber(k) or (v ~= true and tonumber(v) or nil)
        if id and VALID_ENCOUNTER_DIFFICULTIES[id] then
            result[id] = true
            count = count + 1
        end
    end
    return count > 0 and result or nil
end

local function NormalizeQuestIds(value)
    if value == nil or value == "" then
        return nil
    end

    local ids = {}
    local seen = {}

    local function addQuestId(raw)
        local questId = tonumber(raw)
        if not questId then
            return
        end

        questId = math.floor(questId)
        if questId <= 0 or seen[questId] then
            return
        end

        seen[questId] = true
        ids[#ids + 1] = questId
    end

    if type(value) == "table" then
        for _, entry in ipairs(value) do
            addQuestId(entry)
        end
    elseif type(value) == "number" then
        addQuestId(value)
    elseif type(value) == "string" then
        for token in value:gmatch("%d+") do
            addQuestId(token)
        end
    end

    if #ids == 0 then
        return nil
    end

    table.sort(ids)
    return ids
end

local function GetQuestFrequencyResetType(questId)
    if not questId or not C_QuestLog then
        return nil
    end

    local logIndex = C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questId)
    if logIndex and logIndex > 0 and C_QuestLog.GetInfo then
        local info = C_QuestLog.GetInfo(logIndex)
        local frequency = info and info.frequency
        local dailyValue = (Enum and Enum.QuestFrequency and Enum.QuestFrequency.Daily) or 1
        local weeklyValue = (Enum and Enum.QuestFrequency and Enum.QuestFrequency.Weekly) or 2

        if frequency == dailyValue then
            return "daily"
        elseif frequency == weeklyValue then
            return "weekly"
        end
    end

    if GetQuestID and GetQuestID() == questId then
        if QuestIsDaily and QuestIsDaily() then
            return "daily"
        end
        if QuestIsWeekly and QuestIsWeekly() then
            return "weekly"
        end
    end

    return nil
end

local function ResolveQuestResetType(questIds, fallbackResetType)
    fallbackResetType = NormalizeResetType(fallbackResetType)
    if fallbackResetType == "none" then
        return "none"
    end
    if type(questIds) ~= "table" then
        return fallbackResetType
    end

    for _, questId in ipairs(questIds) do
        local resetType = GetQuestFrequencyResetType(questId)
        if resetType then
            return resetType
        end
    end

    return fallbackResetType
end

local function BuildQuestIdsText(questIds)
    if type(questIds) ~= "table" or #questIds == 0 then
        return nil
    end

    local values = {}
    for _, questId in ipairs(questIds) do
        values[#values + 1] = tostring(questId)
    end
    return table.concat(values, ", ")
end

local function FormatQuestMoneyReward(copper)
    copper = tonumber(copper) or 0
    if GetMoneyString then
        return GetMoneyString(copper, true)
    end

    return string.format("%dg", math.floor(copper / 10000))
end

local QUEST_REWARD_CACHE = {}

local function HasLoadedQuestRewardData(questId)
    if HaveQuestRewardData then
        local ok, loaded = pcall(HaveQuestRewardData, questId)
        if ok then
            return loaded == true
        end
    end

    if C_QuestLog and C_QuestLog.HasQuestRewardData then
        local ok, loaded = pcall(C_QuestLog.HasQuestRewardData, questId)
        if ok then
            return loaded == true
        end
    end

    return true
end

local function GetQuestMoneyReward(questId)
    if GetQuestLogRewardMoney then
        local ok, money = pcall(GetQuestLogRewardMoney, questId)
        if ok and type(money) == "number" and money > 0 then
            return money
        end
    end

    if C_QuestLog and C_QuestLog.GetQuestRewardMoney then
        local ok, money = pcall(C_QuestLog.GetQuestRewardMoney, questId)
        if ok and type(money) == "number" and money > 0 then
            return money
        end
    end

    return 0
end

local function GetCachedQuestMoneyReward(questId)
    questId = tonumber(questId)
    if not questId then
        return 0, false
    end

    local cached = QUEST_REWARD_CACHE[questId]
    if cached and cached.loaded then
        return cached.money or 0, false
    end

    if HasLoadedQuestRewardData(questId) then
        local money = GetQuestMoneyReward(questId)
        QUEST_REWARD_CACHE[questId] = {
            loaded = true,
            money = money,
        }
        return money, false
    end

    return 0, false
end

local function GetQuestRewardSummary(questIds)
    if type(questIds) ~= "table" or #questIds == 0 then
        return 0, false
    end

    local totalMoney = 0
    local pending = false

    for _, questId in ipairs(questIds) do
        local money, requested = GetCachedQuestMoneyReward(questId)
        totalMoney = totalMoney + money
        if requested then
            pending = true
        end
    end

    return totalMoney, pending
end

local function NormalizeBoolean(value)
    return value == true
end

local function GetAccountWideProgressStorage()
    if not (MR and MR.db) then
        return nil
    end

    MR.db.global.customTaskProgress = MR.db.global.customTaskProgress or {}
    return MR.db.global.customTaskProgress
end

local function GetAccountWideManualOverrideStorage()
    if not (MR and MR.db) then
        return nil
    end

    MR.db.global.customTaskManualOverrides = MR.db.global.customTaskManualOverrides or {}
    return MR.db.global.customTaskManualOverrides
end

local function ReadCustomTaskValue(source, rowKey)
    local sourceModule = source and source[CUSTOM_MODULE_KEY]
    return sourceModule and sourceModule[rowKey] or nil
end

local function WriteCustomTaskValue(target, rowKey, value)
    if not (target and rowKey and value ~= nil) then
        return
    end

    target[CUSTOM_MODULE_KEY] = target[CUSTOM_MODULE_KEY] or {}
    target[CUSTOM_MODULE_KEY][rowKey] = value
end

GetDiffProgressStorage = function(task)
    if task and task.accountWideComplete then
        MR.db.global.customTaskDiffProgress = MR.db.global.customTaskDiffProgress or {}
        return MR.db.global.customTaskDiffProgress
    end

    if not (MR and MR.db and MR.db.char) then
        return nil
    end

    MR.db.char.customTaskDiffProgress = MR.db.char.customTaskDiffProgress or {}
    return MR.db.char.customTaskDiffProgress
end

local RefreshCustomTaskViews

function MR:IsCustomTaskGroupHideComplete(resetType)
    resetType = NormalizeResetType(resetType)
    local storage = self:GetActiveModuleStorage()
    local settings = storage and storage[CUSTOM_MODULE_KEY]
    local groups = settings and settings.hideCompleteGroups
    return groups and groups[resetType] == true or false
end

function MR:SetCustomTaskGroupHideComplete(resetType, value)
    resetType = NormalizeResetType(resetType)
    local storage = self:GetActiveModuleStorage()
    storage[CUSTOM_MODULE_KEY] = storage[CUSTOM_MODULE_KEY] or {}
    storage[CUSTOM_MODULE_KEY].hideCompleteGroups = storage[CUSTOM_MODULE_KEY].hideCompleteGroups or {}
    storage[CUSTOM_MODULE_KEY].hideCompleteGroups[resetType] = value and true or false
    self:RefreshCustomTasksModule()
    self:RefreshUI()
end

local function SortTasks(tasks)
    table.sort(tasks, function(a, b)
        local aOrder = tonumber(a and a.order) or 0
        local bOrder = tonumber(b and b.order) or 0
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end

        local aId = tonumber(a and a.id) or 0
        local bId = tonumber(b and b.id) or 0
        return aId < bId
    end)
end

function MR:GetCustomTaskRowKey(taskId, scope)
    return GetTaskRowKey(taskId, scope)
end

function MR:IsCustomTaskAccountWideCompletion(rowKey)
    if type(rowKey) ~= "string" then
        return false
    end

    local scope = rowKey:match("^shared_task_") and TASK_SCOPE_SHARED or TASK_SCOPE_CHARACTER
    local taskId = tonumber(rowKey:match("^shared_task_(%d+)") or rowKey:match("^task_(%d+)"))
    local task = taskId and self:GetCustomTaskById(taskId, scope) or nil
    return task and task.accountWideComplete == true or false
end

function MR:GetCustomTasks()
    local tasks = {}

    local function appendTasks(storage, scope)
        for _, task in ipairs(storage or {}) do
            tasks[#tasks + 1] = task
            task.scope = scope
        end
    end

    appendTasks(GetTaskStorage(TASK_SCOPE_CHARACTER), TASK_SCOPE_CHARACTER)
    appendTasks(GetTaskStorage(TASK_SCOPE_SHARED), TASK_SCOPE_SHARED)

    for index, task in ipairs(tasks) do
        task.id = tonumber(task.id) or index
        task.label = TrimText(task.label ~= "" and task.label or (L["CustomTasks_Untitled"] or "Untitled Task"))
        task.max = NormalizeTaskMax(task.max)
        task.order = tonumber(task.order) or index
        task.questIds = NormalizeQuestIds(task.questIds or task.questId)
        task.encounterIds = NormalizeEncounterIds(task.encounterIds)
        task.resetType = ResolveQuestResetType(task.questIds, task.resetType)
        task.scope = NormalizeTaskScope(task.scope)
        task.allowManualQuestClicks = NormalizeBoolean(task.allowManualQuestClicks)
        task.autoUpdateInstances = NormalizeBoolean(task.autoUpdateInstances)
        task.accountWideComplete = NormalizeBoolean(task.accountWideComplete)
        task.encounterDifficulties = NormalizeEncounterDifficulties(task.encounterDifficulties)
        task.questId = nil
    end
    SortTasks(tasks)
    return tasks
end

function MR:GetCustomTasksTitle()
    if not (self and self.db and self.db.char) then
        return L["CustomTasks_Title"] or "Custom Tasks"
    end

    local savedTitle = TrimText(self.db.char.customTasksTitle)
    if savedTitle == "" then
        return L["CustomTasks_Title"] or "Custom Tasks"
    end

    return savedTitle
end

function MR:SetCustomTasksTitle(title)
    if not (self and self.db and self.db.char) then
        return false
    end

    local cleanTitle = TrimText(title)
    if cleanTitle == "" then
        cleanTitle = L["CustomTasks_Title"] or "Custom Tasks"
    end

    self.db.char.customTasksTitle = cleanTitle
    RefreshCustomTaskViews(self)
    return true
end

function MR:GetCustomTaskById(taskId, scope)
    taskId = tonumber(taskId)
    if not taskId then
        return nil
    end

    for _, task in ipairs(self:GetCustomTasks()) do
        if tonumber(task.id) == taskId and (scope == nil or NormalizeTaskScope(task.scope) == NormalizeTaskScope(scope)) then
            return task
        end
    end

    return nil
end

RefreshCustomTaskViews = function(self, moduleAlreadyRefreshed)
    if not moduleAlreadyRefreshed and self.RefreshCustomTasksModule then
        self:RefreshCustomTasksModule()
    end
    if self.RequestConfigRepopulate then
        self:RequestConfigRepopulate(nil, 0.04)
    elseif self.RepopulateConfigFrame then
        self:RepopulateConfigFrame()
    end
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.01)
    elseif self.RefreshUI then
        self:RefreshUI()
    end
end

local function BuildSectionRows(rows, tasks, resetType, headerKey, addKey, headerLabel, headerNote, addLabel)
    local doneCount = 0
    local addRowVisible = MR:IsRowEnabled(CUSTOM_MODULE_KEY, addKey)
    for _, task in ipairs(tasks) do
        if NormalizeResetType(task.resetType) == resetType then
            if tonumber(MR:GetProgress(CUSTOM_MODULE_KEY, GetTaskRowKey(task.id, task.scope))) >= NormalizeTaskMax(task.max) then
                doneCount = doneCount + 1
            end
        end
    end

    rows[#rows + 1] = {
        key = headerKey,
        label = headerLabel,
        note = headerNote,
        control = true,
        sectionHeader = true,
        hideStatus = true,
        noDefaultTooltipHint = true,
        configGroup = resetType,
        labelColor = RESET_TYPE_COLORS[resetType],
        headerBackgroundKey = "custom_tasks_section_" .. resetType,
        countText = string.format("%d / %d", doneCount, #tasks),
        countColor = { 0.74, 0.80, 0.88 },
        headerActionStyle = "visibility",
        headerActionVisible = addRowVisible,
        headerActionTooltip = addRowVisible
            and (L["CustomTasks_HideAddRow"] or "Click to hide the add-task row for this section.")
            or (L["CustomTasks_ShowAddRow"] or "Click to show the add-task row for this section."),
        onHeaderActionClick = function()
            MR:SetRowEnabled(CUSTOM_MODULE_KEY, addKey, not addRowVisible)
            RefreshCustomTaskViews(MR)
        end,
    }

    for _, task in ipairs(tasks) do
        if NormalizeResetType(task.resetType) == resetType then
            local taskId = tonumber(task.id)
            if taskId then
                local taskScope = NormalizeTaskScope(task.scope)
                local rowKey = GetTaskRowKey(taskId, taskScope)
                local resetLabel = resetType == "daily"
                    and (L["CustomTasks_ResetDaily"] or "Daily reset")
                    or resetType == "none"
                        and (L["CustomTasks_ResetNone"] or "No reset")
                        or (L["CustomTasks_ResetWeekly"] or "Weekly reset")
                local scopeLabel = (taskScope == TASK_SCOPE_SHARED)
                    and Text("CustomTasks_SharedScope", "Shows on all alts")
                    or Text("CustomTasks_CharacterScope", "Shows on this character")
                local completionScopeLabel = task.accountWideComplete
                    and Text("CustomTasks_AccountCompleteScope", "Completion shared by all alts")
                    or Text("CustomTasks_CharacterCompleteScope", "Completion tracked per character")
                local questIds = NormalizeQuestIds(task.questIds)
                local questIdText = BuildQuestIdsText(questIds)
                local rewardCopper = GetQuestRewardSummary(questIds)
                local rewardText = rewardCopper and rewardCopper > 0 and FormatQuestMoneyReward(rewardCopper) or nil
                local encounterIds = NormalizeEncounterIds(task.encounterIds)
                local encounterIdText = BuildEncounterIdsText(encounterIds)
                local noteText
                if encounterIds then
                    noteText = string.format(
                        "%s\n%s",
                        resetLabel,
                        string.format(
                            L["CustomTasks_EncounterNote"] or "Auto-completes on boss kill for encounter ID%s %s. Shift-left-click to edit. Shift-right-click to delete.",
                            (#encounterIds == 1) and "" or "s",
                            encounterIdText or ""
                        )
                    )
                elseif questIds then
                    local questNote = string.format(
                        L["CustomTasks_QuestNote"] or "Auto-tracks quest completion for quest ID%s %s. Shift-left-click to edit. Shift-right-click to delete.",
                        (#questIds == 1) and "" or "s",
                        questIdText or ""
                    )
                    if rewardText then
                        questNote = string.format("%s\nGold reward: %s", questNote, rewardText)
                    end
                    noteText = string.format(
                        "%s\n%s",
                        resetLabel,
                        questNote
                    )
                else
                    noteText = string.format(
                        "%s\n%s",
                        resetLabel,
                        (task.max > 1)
                            and (L["CustomTasks_CounterNote"] or "Left-click to add progress. Right-click to remove progress. Shift-left-click to edit. Shift-right-click to delete.")
                            or (L["CustomTasks_TaskNote"] or "Left-click the checkbox to toggle. Shift-left-click to rename. Shift-right-click to delete.")
                    )
                end
                noteText = string.format("%s\n%s\n%s", scopeLabel, completionScopeLabel, noteText)
                local effectiveMax = task.max
                local diffCount = CountTrackedDifficulties(task)
                if diffCount >= 2 then effectiveMax = diffCount end
                rows[#rows + 1] = {
                    key = rowKey,
                    label = rewardText and ("|cffffd36a" .. task.label .. "|r") or task.label,
                    max = effectiveMax,
                    note = noteText,
                    countText = rewardText,
                    countColor = rewardText and { 1.00, 0.82, 0.30 } or nil,
                    toggleStatus = (task.max <= 1) and ((not questIds) or task.allowManualQuestClicks) and (not encounterIds),
                    questIds = questIds,
                    encounterIds = encounterIds,
                    allowManualQuestClicks = task.allowManualQuestClicks,
                    autoUpdateInstances = task.autoUpdateInstances,
                    encounterDifficulties = task.encounterDifficulties,
                    taskId = task.id,
                    taskScope = taskScope,
                    accountWideComplete = task.accountWideComplete,
                    preserveCompletion = resetType == "none",
                    configGroup = resetType,
                    hideComplete = MR:IsCustomTaskGroupHideComplete(resetType),
                    noDefaultTooltipHint = true,
                    tooltipFunc = function(tip)
                        tip:AddLine(" ")
                        tip:AddLine(scopeLabel, 0.72, 0.80, 1.00, true)
                        tip:AddLine(completionScopeLabel, 0.72, 0.80, 1.00, true)
                        tip:AddLine(resetLabel, 0.80, 0.90, 1.00, true)
                        if encounterIds then
                            tip:AddLine(
                                string.format(
                                    L["CustomTasks_EncounterHint"] or "Auto-completes on boss kill for encounter ID%s %s.",
                                    (#encounterIds == 1) and "" or "s",
                                    encounterIdText or ""
                                ),
                                0.70, 0.90, 0.70, true
                            )
                        elseif questIds then
                            tip:AddLine(
                                string.format(
                                    L["CustomTasks_QuestHint"] or "Tracks quest completion automatically for quest ID%s %s.",
                                    (#questIds == 1) and "" or "s",
                                    questIdText or ""
                                ),
                                0.70, 0.90, 0.70, true
                            )
                            if rewardText then
                                tip:AddLine("Gold reward: " .. rewardText, 1.00, 0.82, 0.30, true)
                            end
                            if task.allowManualQuestClicks then
                                tip:AddLine(L["CustomTasks_QuestManualHint"] or "Manual clicking is enabled for this quest task.", 0.95, 0.82, 0.50, true)
                            end
                        elseif task.max > 1 then
                            tip:AddLine(L["CustomTasks_CounterIncreaseHint"] or "Left-click to add progress", 0.70, 0.90, 0.70, true)
                            tip:AddLine(L["CustomTasks_CounterDecreaseHint"] or "Right-click to remove progress", 1, 0.80, 0.45, true)
                        else
                            tip:AddLine(L["CustomTasks_CheckboxHint"] or "Left-click the checkbox to toggle complete", 0.70, 0.90, 0.70, true)
                        end
                        tip:AddLine(L["CustomTasks_EditHint"] or "Shift-left-click to rename", 0.45, 0.85, 1, true)
                        tip:AddLine(L["CustomTasks_DeleteHint"] or "Shift-right-click to delete", 1, 0.55, 0.55, true)
                    end,
                    onLeftClick = function(row)
                        if IsShiftKeyDown() and MR.ShowCustomTaskDialog then
                            MR:ShowCustomTaskDialog(taskId, nil, taskScope)
                            return true
                        end
                        return false
                    end,
                    onRightClick = function(row)
                        if IsShiftKeyDown() then
                            MR:DeleteCustomTask(taskId, taskScope)
                            return true
                        end
                        return false
                    end,
                }
            end
        end
    end

    rows[#rows + 1] = {
        key = addKey,
        label = addLabel,
        note = L["CustomTasks_AddNote"] or "Click to create a new custom task for this character.",
        control = true,
        hideStatus = true,
        noDefaultTooltipHint = true,
        configGroup = resetType,
        countText = L["CustomTasks_AddButton"] or "[ + ]",
        countColor = { 0.92, 0.78, 0.24 },
        onLeftClick = function()
            if MR.ShowCustomTaskDialog then
                MR:ShowCustomTaskDialog(nil, resetType)
            end
            return true
        end,
        onRightClick = function()
            if MR.ShowCustomTaskDialog then
                MR:ShowCustomTaskDialog(nil, resetType)
            end
            return true
        end,
    }
end

function MR:AddCustomTask(label, resetType, maxValue, questIds, allowManualQuestClicks, encounterIds, autoUpdateInstances, encounterDifficulties, scope, accountWideComplete)
    scope = NormalizeTaskScope(scope)
    local tasks = GetTaskStorage(scope)
    local cleanLabel = TrimText(label)
    if not tasks or cleanLabel == "" then
        return nil
    end

    questIds = NormalizeQuestIds(questIds)
    encounterIds = NormalizeEncounterIds(encounterIds)
    resetType = ResolveQuestResetType(questIds, resetType)
    allowManualQuestClicks = NormalizeBoolean(allowManualQuestClicks)
    autoUpdateInstances = NormalizeBoolean(autoUpdateInstances)
    encounterDifficulties = NormalizeEncounterDifficulties(encounterDifficulties)
    accountWideComplete = NormalizeBoolean(accountWideComplete)

    local taskId
    if scope == TASK_SCOPE_SHARED then
        taskId = tonumber(self.db.global.customTaskNextId) or 1
        self.db.global.customTaskNextId = taskId + 1
    else
        taskId = tonumber(self.db.char.customTaskNextId) or 1
        self.db.char.customTaskNextId = taskId + 1
    end

    tasks[#tasks + 1] = {
        id = taskId,
        scope = scope,
        label = cleanLabel,
        max = NormalizeTaskMax(maxValue),
        order = #tasks + 1,
        resetType = resetType,
        questIds = questIds,
        encounterIds = encounterIds,
        allowManualQuestClicks = allowManualQuestClicks,
        autoUpdateInstances = autoUpdateInstances,
        accountWideComplete = accountWideComplete,
        encounterDifficulties = encounterDifficulties,
    }

    if self.RefreshCustomTasksModule then
        self:RefreshCustomTasksModule()
    end
    if questIds and self.RefreshQuestProgress then
        self:RefreshQuestProgress(nil, false)
    end
    RefreshCustomTaskViews(self, true)
    return taskId
end

function MR:UpdateCustomTask(taskId, label, resetType, maxValue, questIds, allowManualQuestClicks, encounterIds, autoUpdateInstances, encounterDifficulties, scope, originalScope, accountWideComplete)
    scope = NormalizeTaskScope(scope)
    originalScope = NormalizeTaskScope(originalScope or scope)
    local task = self:GetCustomTaskById(taskId, originalScope)
    local cleanLabel = TrimText(label)
    if not task or cleanLabel == "" then
        return false
    end

    local oldScope = NormalizeTaskScope(task.scope)
    local oldTaskId = task.id
    local oldRowKey = GetTaskRowKey(oldTaskId, oldScope)
    local oldAccountWideComplete = task.accountWideComplete == true
    local existingProgressSource = oldAccountWideComplete and GetAccountWideProgressStorage() or (self.db.char and self.db.char.progress)
    local existingOverrideSource = oldAccountWideComplete and GetAccountWideManualOverrideStorage() or (self.db.char and self.db.char.manualOverrides)
    local existingProgressValue = ReadCustomTaskValue(existingProgressSource, oldRowKey)
    local existingOverrideValue = ReadCustomTaskValue(existingOverrideSource, oldRowKey)
    if oldScope ~= scope then
        local oldTasks = GetTaskStorage(oldScope)
        local newTasks = GetTaskStorage(scope)
        if not oldTasks or not newTasks then
            return false
        end

        for index = #oldTasks, 1, -1 do
            if oldTasks[index] == task then
                table.remove(oldTasks, index)
                break
            end
        end

        if scope == TASK_SCOPE_SHARED then
            task.id = tonumber(self.db.global.customTaskNextId) or 1
            self.db.global.customTaskNextId = task.id + 1
        else
            task.id = tonumber(self.db.char.customTaskNextId) or 1
            self.db.char.customTaskNextId = task.id + 1
        end

        task.order = #newTasks + 1
        newTasks[#newTasks + 1] = task

        if self.db.char.progress and self.db.char.progress[CUSTOM_MODULE_KEY] then
            self.db.char.progress[CUSTOM_MODULE_KEY][oldRowKey] = nil
        end
        if self.db.char.manualOverrides and self.db.char.manualOverrides[CUSTOM_MODULE_KEY] then
            self.db.char.manualOverrides[CUSTOM_MODULE_KEY][oldRowKey] = nil
        end
        if self.db.char.customTaskDiffProgress then
            self.db.char.customTaskDiffProgress[oldRowKey] = nil
            self.db.char.customTaskDiffProgress[tostring(oldTaskId)] = nil
        end
        if self.db.global then
            if self.db.global.customTaskProgress and self.db.global.customTaskProgress[CUSTOM_MODULE_KEY] then
                self.db.global.customTaskProgress[CUSTOM_MODULE_KEY][oldRowKey] = nil
            end
            if self.db.global.customTaskManualOverrides and self.db.global.customTaskManualOverrides[CUSTOM_MODULE_KEY] then
                self.db.global.customTaskManualOverrides[CUSTOM_MODULE_KEY][oldRowKey] = nil
            end
            if self.db.global.customTaskDiffProgress then
                self.db.global.customTaskDiffProgress[oldRowKey] = nil
                self.db.global.customTaskDiffProgress[tostring(oldTaskId)] = nil
            end
        end
    end

    questIds = NormalizeQuestIds(questIds)
    encounterIds = NormalizeEncounterIds(encounterIds)
    resetType = ResolveQuestResetType(questIds, resetType)
    allowManualQuestClicks = NormalizeBoolean(allowManualQuestClicks)
    autoUpdateInstances = NormalizeBoolean(autoUpdateInstances)
    accountWideComplete = NormalizeBoolean(accountWideComplete)
    local newRowKey = GetTaskRowKey(task.id, scope)

    if oldAccountWideComplete ~= accountWideComplete then
        local oldProgress = oldAccountWideComplete and GetAccountWideProgressStorage() or (self.db.char and self.db.char.progress)
        local oldOverrides = oldAccountWideComplete and GetAccountWideManualOverrideStorage() or (self.db.char and self.db.char.manualOverrides)
        local oldDiff = oldAccountWideComplete and (self.db.global and self.db.global.customTaskDiffProgress) or (self.db.char and self.db.char.customTaskDiffProgress)
        if oldProgress and oldProgress[CUSTOM_MODULE_KEY] then oldProgress[CUSTOM_MODULE_KEY][oldRowKey] = nil end
        if oldOverrides and oldOverrides[CUSTOM_MODULE_KEY] then oldOverrides[CUSTOM_MODULE_KEY][oldRowKey] = nil end
        if oldDiff then
            oldDiff[tostring(oldTaskId)] = nil
            oldDiff[oldRowKey] = nil
        end
    end

    task.label = cleanLabel
    task.scope = scope
    task.resetType = resetType
    task.max = NormalizeTaskMax(maxValue)
    task.questIds = questIds
    task.encounterIds = encounterIds
    task.allowManualQuestClicks = allowManualQuestClicks
    task.autoUpdateInstances = autoUpdateInstances
    task.accountWideComplete = accountWideComplete
    task.encounterDifficulties = NormalizeEncounterDifficulties(encounterDifficulties)
    if accountWideComplete then
        WriteCustomTaskValue(GetAccountWideProgressStorage(), newRowKey, existingProgressValue)
        WriteCustomTaskValue(GetAccountWideManualOverrideStorage(), newRowKey, existingOverrideValue)
    end
    if self.RefreshCustomTasksModule then
        self:RefreshCustomTasksModule()
    end
    if questIds and self.RefreshQuestProgress then
        self:RefreshQuestProgress(nil, false)
    end
    RefreshCustomTaskViews(self, true)
    return true
end

function MR:ToggleCustomTask(taskId, scope)
    local task = self:GetCustomTaskById(taskId, scope)
    if not task then
        return false
    end

    local rowKey = GetTaskRowKey(task.id, task.scope)
    local cur = tonumber(self:GetProgress(CUSTOM_MODULE_KEY, rowKey)) or 0
    local newVal = cur >= 1 and 0 or 1
    self:SetProgress(CUSTOM_MODULE_KEY, rowKey, newVal, 1, task.autoUpdateInstances == true)
    if task.accountWideComplete then
        WriteCustomTaskValue(GetAccountWideProgressStorage(), rowKey, newVal)
    end

    if task.questIds then
        if newVal >= 1 then
            self:SetManualOverride(CUSTOM_MODULE_KEY, rowKey, 1, 1)
            if task.accountWideComplete then
                WriteCustomTaskValue(GetAccountWideManualOverrideStorage(), rowKey, 1)
            end
        else
            self:SetManualOverride(CUSTOM_MODULE_KEY, rowKey, 0, 1)
            if task.accountWideComplete then
                WriteCustomTaskValue(GetAccountWideManualOverrideStorage(), rowKey, 0)
            end
        end
    end

    return true
end

function MR:ResetCustomTasksByType(resetType)
    resetType = NormalizeResetType(resetType)
    if resetType == "none" then
        return
    end
    local tasks = self:GetCustomTasks()
    local progress = self.db and self.db.char and self.db.char.progress and self.db.char.progress[CUSTOM_MODULE_KEY]
    local overrides = self.db and self.db.char and self.db.char.manualOverrides and self.db.char.manualOverrides[CUSTOM_MODULE_KEY]
    local diffProg = self.db and self.db.char and self.db.char.customTaskDiffProgress
    if not tasks then
        return
    end

    local resetAt = (resetType == "daily")
        and (self.GetLastDailyTimestamp and self:GetLastDailyTimestamp())
        or (self.GetLastResetTimestamp and self:GetLastResetTimestamp())
    local region = (GetCurrentRegion and GetCurrentRegion()) or 1
    local globalStampKey = ((resetType == "daily") and "lastCustomTaskDailyResetAt" or "lastCustomTaskWeeklyResetAt")
        .. "_" .. tostring(region)
    local sharedAlreadyReset = false
    if self.db and self.db.global and resetAt then
        local prevGlobalResetAt = tonumber(self.db.global[globalStampKey]) or 0
        if prevGlobalResetAt >= resetAt then
            sharedAlreadyReset = true
        else
            self.db.global[globalStampKey] = resetAt
        end
    end

    local globalProgress = (not sharedAlreadyReset) and self.db and self.db.global and self.db.global.customTaskProgress and self.db.global.customTaskProgress[CUSTOM_MODULE_KEY] or nil
    local globalOverrides = (not sharedAlreadyReset) and self.db and self.db.global and self.db.global.customTaskManualOverrides and self.db.global.customTaskManualOverrides[CUSTOM_MODULE_KEY] or nil
    local globalDiffProg = (not sharedAlreadyReset) and self.db and self.db.global and self.db.global.customTaskDiffProgress or nil

    if not progress and not overrides and not diffProg and not globalProgress and not globalOverrides and not globalDiffProg then
        return
    end

    for _, task in ipairs(tasks) do
        if NormalizeResetType(task.resetType) == resetType then
            local rowKey = GetTaskRowKey(task.id, task.scope)
            if progress then progress[rowKey] = nil end
            if overrides then overrides[rowKey] = nil end
            if globalProgress then globalProgress[rowKey] = nil end
            if globalOverrides then globalOverrides[rowKey] = nil end
            if diffProg then
                diffProg[tostring(task.id)] = nil
                diffProg[GetTaskProgressKey(task.id, task.scope)] = nil
            end
            if globalDiffProg then
                globalDiffProg[tostring(task.id)] = nil
                globalDiffProg[GetTaskProgressKey(task.id, task.scope)] = nil
            end
        end
    end
end

function MR:DeleteCustomTask(taskId, scope)
    scope = NormalizeTaskScope(scope)
    local tasks = GetTaskStorage(scope)
    taskId = tonumber(taskId)
    if not tasks or not taskId then
        return false
    end

    local removed = false
    for index = #tasks, 1, -1 do
        if tonumber(tasks[index].id) == taskId then
            table.remove(tasks, index)
            removed = true
            break
        end
    end

    if not removed then
        return false
    end

    if self.db and self.db.char and self.db.char.customTaskDiffProgress then
        self.db.char.customTaskDiffProgress[tostring(taskId)] = nil
        self.db.char.customTaskDiffProgress[GetTaskProgressKey(taskId, scope)] = nil
    end
    if self.db and self.db.global and self.db.global.customTaskDiffProgress then
        self.db.global.customTaskDiffProgress[tostring(taskId)] = nil
        self.db.global.customTaskDiffProgress[GetTaskProgressKey(taskId, scope)] = nil
    end

    SortTasks(tasks)
    for index, task in ipairs(tasks) do
        task.order = index
    end

    local rowKey = GetTaskRowKey(taskId, scope)
    if self.db.char.progress and self.db.char.progress[CUSTOM_MODULE_KEY] then
        self.db.char.progress[CUSTOM_MODULE_KEY][rowKey] = nil
    end
    if self.db.char.manualOverrides and self.db.char.manualOverrides[CUSTOM_MODULE_KEY] then
        self.db.char.manualOverrides[CUSTOM_MODULE_KEY][rowKey] = nil
    end
    if self.db.global and self.db.global.customTaskProgress and self.db.global.customTaskProgress[CUSTOM_MODULE_KEY] then
        self.db.global.customTaskProgress[CUSTOM_MODULE_KEY][rowKey] = nil
    end
    if self.db.global and self.db.global.customTaskManualOverrides and self.db.global.customTaskManualOverrides[CUSTOM_MODULE_KEY] then
        self.db.global.customTaskManualOverrides[CUSTOM_MODULE_KEY][rowKey] = nil
    end
    if self.db.profile.rowColors and self.db.profile.rowColors[CUSTOM_MODULE_KEY] then
        self.db.profile.rowColors[CUSTOM_MODULE_KEY][rowKey] = nil
    end

    local storage = self:GetActiveModuleStorage()
    if storage and storage[CUSTOM_MODULE_KEY] and storage[CUSTOM_MODULE_KEY].hiddenRows then
        storage[CUSTOM_MODULE_KEY].hiddenRows[rowKey] = nil
    end
    if storage and storage[CUSTOM_MODULE_KEY] and type(storage[CUSTOM_MODULE_KEY].rowOrder) == "table" then
        for index = #storage[CUSTOM_MODULE_KEY].rowOrder, 1, -1 do
            if storage[CUSTOM_MODULE_KEY].rowOrder[index] == rowKey then
                table.remove(storage[CUSTOM_MODULE_KEY].rowOrder, index)
            end
        end
    end

    RefreshCustomTaskViews(self)
    return true
end

function MR:RefreshCustomTasksModule()
    local mod = self.moduleByKey and self.moduleByKey[CUSTOM_MODULE_KEY]
    if not mod then
        return
    end

    local rows = {}
    local tasks = self:GetCustomTasks()
    local dailyTasks = {}
    local weeklyTasks = {}
    local noResetTasks = {}
    for _, task in ipairs(tasks) do
        local resetType = NormalizeResetType(task.resetType)
        if resetType == "daily" then
            dailyTasks[#dailyTasks + 1] = task
        elseif resetType == "none" then
            noResetTasks[#noResetTasks + 1] = task
        else
            weeklyTasks[#weeklyTasks + 1] = task
        end
    end

    BuildSectionRows(
        rows,
        dailyTasks,
        "daily",
        DAILY_HEADER_KEY,
        DAILY_ADD_ROW_KEY,
        L["CustomTasks_DailyHeader"] or "Daily",
        L["CustomTasks_DailyNote"] or "Resets automatically at the daily reset.",
        L["CustomTasks_AddDailyLabel"] or "Add daily task"
    )
    BuildSectionRows(
        rows,
        weeklyTasks,
        "weekly",
        WEEKLY_HEADER_KEY,
        WEEKLY_ADD_ROW_KEY,
        L["CustomTasks_WeeklyHeader"] or "Weekly",
        L["CustomTasks_WeeklyNote"] or "Resets automatically at the weekly reset.",
        L["CustomTasks_AddWeeklyLabel"] or "Add weekly task"
    )
    BuildSectionRows(
        rows,
        noResetTasks,
        "none",
        NO_RESET_HEADER_KEY,
        NO_RESET_ADD_ROW_KEY,
        L["CustomTasks_NoResetHeader"] or "No Reset",
        L["CustomTasks_NoResetNote"] or "Does not reset automatically.",
        L["CustomTasks_AddNoResetLabel"] or "Add no-reset task"
    )

    mod.rows = rows
    mod.label = self:GetCustomTasksTitle()
    self._moduleStatsCache = nil
    self._orderedModulesCache = nil
end

function MR:RefreshEncounterProgress(encounterId, refreshUI, difficultyId)
    if not (self and self.db and self.db.char and self.db.char.progress) then
        return false
    end

    if difficultyId then
        difficultyId = CANONICAL_DIFFICULTY[difficultyId] or difficultyId
    end

    local progress = self.db.char.progress
    local dirty = false

    for _, mod in ipairs(self.modules) do
        if self:IsModuleEnabled(mod.key) then
            for _, row in ipairs(mod.rows) do
                if row.encounterIds then
                    local shouldMark = encounterId == nil
                    if not shouldMark then
                        for _, eid in ipairs(row.encounterIds) do
                            if eid == encounterId then
                                shouldMark = true
                                break
                            end
                        end
                    end

                    if shouldMark and difficultyId and row.encounterDifficulties then
                        shouldMark = row.encounterDifficulties[difficultyId] == true
                    end

                    if shouldMark then
                        local progressBucket = (self.GetProgressBucket and self:GetProgressBucket(mod.key, row.key)) or progress
                        if not progressBucket[mod.key] then
                            progressBucket[mod.key] = {}
                        end
                        local cur = progressBucket[mod.key][row.key] or 0
                        local maxVal = row.max or 1
                        if difficultyId and row.taskId then
                            local diffState = GetDiffProgress(self, row.taskId, row.taskScope)
                            if diffState and not diffState[difficultyId] then
                                diffState[difficultyId] = true
                                if cur < maxVal then
                                    progressBucket[mod.key][row.key] = cur + 1
                                    dirty = true
                                end
                            end
                        elseif not row.taskId and cur < maxVal then
                            progressBucket[mod.key][row.key] = maxVal
                            dirty = true
                        end
                    end
                end
            end
        end
    end

    if dirty then
        self._moduleStatsCache = nil
        if refreshUI ~= false then
            if self.RequestDataRefresh then
                self:RequestDataRefresh()
            else
                self:RefreshUI()
            end
        end
    end

    return dirty
end

MR:RegisterModule({
    key = CUSTOM_MODULE_KEY,
    label = L["CustomTasks_Title"] or "Custom Tasks",
    labelColor = "#b07cff",
    defaultOpen = true,
    rows = {},
})
