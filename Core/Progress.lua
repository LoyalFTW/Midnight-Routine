local _, ns = ...
local MR = ns.MR
local Core = assert(ns.CoreInternals, "Core/Foundation.lua must load first")
local DeepCopy = Core.DeepCopy
local MergeMissing = Core.MergeMissing
local RestoreDefaults = Core.RestoreDefaults
local IsTableEmpty = Core.IsTableEmpty

local function CanImportLegacyCustomTaskProgress(self, rowKey)
    local taskId = type(rowKey) == "string" and tonumber(rowKey:match("^shared_task_(%d+)")) or nil
    local task = taskId and self.GetCustomTaskById and self:GetCustomTaskById(taskId, "shared") or nil
    if not task then
        return false
    end
    if task.resetType == "none" then
        return true
    end

    local region = (GetCurrentRegion and GetCurrentRegion()) or 1
    local stampPrefix = task.resetType == "daily" and "lastCustomTaskDailyResetAt_" or "lastCustomTaskWeeklyResetAt_"
    return not (self.db and self.db.global and tonumber(self.db.global[stampPrefix .. tostring(region)]))
end

function MR:GetProgress(moduleKey, rowKey)
    if moduleKey == "custom_tasks" and self.IsCustomTaskAccountWideCompletion and self:IsCustomTaskAccountWideCompletion(rowKey) then
        local progress = self.db and self.db.global and self.db.global.customTaskProgress
        local m = progress and progress[moduleKey]
        if m and m[rowKey] ~= nil then
            return m[rowKey]
        end

        local taskId = type(rowKey) == "string" and rowKey:match("^shared_task_(%d+)")
        local legacyKey = taskId and CanImportLegacyCustomTaskProgress(self, rowKey) and ("task_" .. taskId) or nil
        local legacyValue = legacyKey and m and m[legacyKey] or nil
        if legacyValue ~= nil then
            return legacyValue
        end

        if not CanImportLegacyCustomTaskProgress(self, rowKey) then
            return 0
        end

        local source = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or nil
        local function readLocalProgress(localProgress)
            local localModule = localProgress and localProgress[moduleKey]
            return localModule and (localModule[rowKey] or (legacyKey and localModule[legacyKey])) or nil
        end
        local selectedValue = readLocalProgress(source and source.progress)
        local currentValue = readLocalProgress(self.db and self.db.char and self.db.char.progress)
        local localValue = selectedValue
        if currentValue ~= nil and (localValue == nil or (tonumber(currentValue) or 0) > (tonumber(localValue) or 0)) then
            localValue = currentValue
        end
        if localValue ~= nil then
            local globalProgress = self.db and self.db.global and self.db.global.customTaskProgress
            if globalProgress then
                globalProgress[moduleKey] = globalProgress[moduleKey] or {}
                globalProgress[moduleKey][rowKey] = localValue
            end
            return localValue
        end

        return 0
    end

    local source = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or self.db.char
    local progress = source and source.progress or self.db.char.progress
    local m = progress and progress[moduleKey]
    return m and m[rowKey] or 0
end

function MR:IsRowVisibleForCharacter(mod, row, charData)
    if not row or not row.isVisible then
        return true
    end

    if mod and (mod.key == "darkmoon_faire" or (type(row.key) == "string" and row.key:match("_dmf$"))) then
        return row.isVisible() == true
    end

    charData = charData or (self.GetMainFrameProgressSource and self:GetMainFrameProgressSource()) or (self.db and self.db.char)
    if type(charData) == "table" and self.db and charData ~= self.db.char then
        local visibility = charData.rowVisibility
        local moduleVisibility = type(visibility) == "table" and mod and visibility[mod.key] or nil
        local savedVisible = type(moduleVisibility) == "table" and moduleVisibility[row.key] or nil
        if savedVisible ~= nil then
            return savedVisible == true
        end

        local progress = type(charData.progress) == "table" and mod and charData.progress[mod.key] or nil
        if type(progress) == "table" and (tonumber(progress[row.key]) or 0) > 0 then
            return true
        end
    end

    return row.isVisible() == true
end

function MR:GetProgressBucket(moduleKey, rowKey)
    if moduleKey == "custom_tasks" and self.IsCustomTaskAccountWideCompletion and self:IsCustomTaskAccountWideCompletion(rowKey) then
        self.db.global.customTaskProgress = self.db.global.customTaskProgress or {}
        return self.db.global.customTaskProgress
    end

    return self.db.char.progress
end

function MR:GetManualOverrideBucket(moduleKey, rowKey)
    if moduleKey == "custom_tasks" and self.IsCustomTaskAccountWideCompletion and self:IsCustomTaskAccountWideCompletion(rowKey) then
        self.db.global.customTaskManualOverrides = self.db.global.customTaskManualOverrides or {}
        return self.db.global.customTaskManualOverrides
    end

    return self.db.char.manualOverrides
end

local function IsDefaultProgressValue(value)
    return type(value) == "number" and value == 0
end

local function RemoveEmptyProgressBucket(progress, modKey)
    if progress[modKey] and next(progress[modKey]) == nil then
        progress[modKey] = nil
    end
end

local function SetProgressValue(progress, modKey, rowKey, val)
    if IsDefaultProgressValue(val) then
        local bucket = progress[modKey]
        if not bucket or bucket[rowKey] == nil then
            RemoveEmptyProgressBucket(progress, modKey)
            return false
        end
        bucket[rowKey] = nil
        RemoveEmptyProgressBucket(progress, modKey)
        return true
    end

    if not progress[modKey] then progress[modKey] = {} end
    if progress[modKey][rowKey] == val then return false end
    progress[modKey][rowKey] = val
    return true
end

local function PruneProgressStore(progress)
    if type(progress) ~= "table" then
        return false
    end

    local dirty = false
    for modKey, bucket in pairs(progress) do
        if type(bucket) == "table" then
            for rowKey, value in pairs(bucket) do
                if IsDefaultProgressValue(value) then
                    bucket[rowKey] = nil
                    dirty = true
                end
            end
            if next(bucket) == nil then
                progress[modKey] = nil
                dirty = true
            end
        end
    end

    return dirty
end

ns.CoreData = {
    DeepCopy = DeepCopy,
    SetProgressValue = SetProgressValue,
    PruneProgressStore = PruneProgressStore,
}

function MR:SetProgress(moduleKey, rowKey, value, maxVal, bypassInstanceSuspend)
    local progressBucket = self.GetProgressBucket and self:GetProgressBucket(moduleKey, rowKey) or self.db.char.progress
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() and not bypassInstanceSuspend then
        if not progressBucket[moduleKey] then
            progressBucket[moduleKey] = {}
        end
        if moduleKey == "custom_tasks" and type(rowKey) == "string" and rowKey:match("^shared_task_") then
            local taskId = rowKey:match("^shared_task_(%d+)")
            if taskId then
                progressBucket[moduleKey]["task_" .. taskId] = nil
            end
        end
        SetProgressValue(progressBucket, moduleKey, rowKey, math.max(0, math.min(value, maxVal)))
        return
    end

    if self:ShouldDeferForCombat("refreshUI") then
        self:QueueDeferredProgressUpdate(moduleKey, rowKey, value, maxVal)
        return
    end

    if not progressBucket[moduleKey] then
        progressBucket[moduleKey] = {}
    end
    if moduleKey == "custom_tasks" and type(rowKey) == "string" and rowKey:match("^shared_task_") then
        local taskId = rowKey:match("^shared_task_(%d+)")
        if taskId then
            progressBucket[moduleKey]["task_" .. taskId] = nil
        end
    end
    SetProgressValue(progressBucket, moduleKey, rowKey, math.max(0, math.min(value, maxVal)))
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.01)
    else
        self:RefreshUI()
    end
    local mod = self.moduleByKey and self.moduleByKey[moduleKey]
    if mod and mod.profSkillLine and self.RefreshProfessionKnowledgeSurfaces then
        self:RequestProfessionKnowledgeSurfaceRefresh()
    end
end


function MR:BumpProgress(moduleKey, rowKey, delta, maxVal, bypassInstanceSuspend)
    local current = self:GetProgress(moduleKey, rowKey)
    self:SetProgress(moduleKey, rowKey, current + delta, maxVal, bypassInstanceSuspend)
end

local function CleanDisplayLabel(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end
    return text:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
end

function MR:SetWaypoint(target)
    local mapID = target and target.zone
    local x = target and target.x and (target.x / 100)
    local y = target and target.y and (target.y / 100)
    local tomTom = _G and rawget(_G, "TomTom")

    if not mapID or not x or not y then
        return false, "Invalid coordinates"
    end

    local title = target.waypointTitle or CleanDisplayLabel(target.label)

    if tomTom and tomTom.AddWaypoint then
        local ok = pcall(function()
            tomTom:AddWaypoint(mapID, x, y, {
                title = title,
                persistent = false,
                minimap = true,
                world = true,
            })
        end)
        if ok then return true, "TomTom" end
    end

    if UiMapPoint and UiMapPoint.CreateFromCoordinates and C_Map and C_Map.SetUserWaypoint then
        local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        if point then
            C_Map.SetUserWaypoint(point)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
            return true, "Blizzard" end
    end

    return false, "No waypoint API available"
end

function MR:GetRowWaypointTarget(row, activateNavigation)
    if type(row) ~= "table" then
        return nil
    end

    if type(row.getWaypoint) == "function" then
        local ok, target = pcall(row.getWaypoint, row)
        if ok and type(target) == "table" and target.zone and target.x and target.y then
            return target
        end
    end

    local questIds = row.navigationQuestIds or row.questIds
    if type(questIds) == "table" and C_QuestLog and C_QuestLog.GetNextWaypoint then
        for _, questId in ipairs(questIds) do
            local ok, mapID, x, y = pcall(C_QuestLog.GetNextWaypoint, questId)
            if ok and mapID and x and y then
                if activateNavigation ~= false and C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
                    pcall(C_SuperTrack.SetSuperTrackedQuestID, questId)
                end
                local waypointText
                if C_QuestLog.GetNextWaypointText then
                    local textOk, textValue = pcall(C_QuestLog.GetNextWaypointText, questId)
                    if textOk then
                        waypointText = textValue
                    end
                end
                return {
                    zone = mapID,
                    x = x * 100,
                    y = y * 100,
                    label = waypointText or self:GetQuestName(questId, row.label),
                    waypointTitle = waypointText or self:GetQuestName(questId, CleanDisplayLabel(row.label)),
                }
            end
        end
    end

    if row.zone and row.x and row.y then
        return row
    end

    return nil
end

function MR:NavigateToRow(row)
    local target = self:GetRowWaypointTarget(row)
    if not target then
        return false, "No destination available"
    end

    local ok, source = self:SetWaypoint(target)
    return ok, source, target
end

function MR:GetManualOverride(modKey, rowKey)
    if modKey == "custom_tasks" and self.IsCustomTaskAccountWideCompletion and self:IsCustomTaskAccountWideCompletion(rowKey) then
        local m = self.db and self.db.global and self.db.global.customTaskManualOverrides
        local modOverrides = m and m[modKey]
        if modOverrides and modOverrides[rowKey] ~= nil then
            return modOverrides[rowKey]
        end

        local taskId = type(rowKey) == "string" and rowKey:match("^shared_task_(%d+)")
        local legacyKey = taskId and CanImportLegacyCustomTaskProgress(self, rowKey) and ("task_" .. taskId) or nil
        local legacyValue = legacyKey and modOverrides and modOverrides[legacyKey] or nil
        if legacyValue ~= nil then
            return legacyValue
        end

        if not CanImportLegacyCustomTaskProgress(self, rowKey) then
            return 0
        end

        local source = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or nil
        local function readLocalOverride(localOverrides)
            local localModule = localOverrides and localOverrides[modKey]
            return localModule and (localModule[rowKey] or (legacyKey and localModule[legacyKey])) or nil
        end
        local selectedValue = readLocalOverride(source and source.manualOverrides)
        local currentValue = readLocalOverride(self.db and self.db.char and self.db.char.manualOverrides)
        local localValue = selectedValue
        if currentValue ~= nil and (localValue == nil or (tonumber(currentValue) or 0) > (tonumber(localValue) or 0)) then
            localValue = currentValue
        end
        if localValue ~= nil then
            local globalOverrides = self.db and self.db.global and self.db.global.customTaskManualOverrides
            if globalOverrides then
                globalOverrides[modKey] = globalOverrides[modKey] or {}
                globalOverrides[modKey][rowKey] = localValue
            end
            return localValue
        end

        return 0
    end

    local source = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or self.db.char
    local m = source and source.manualOverrides or self.db.char.manualOverrides
    return (m and m[modKey] and m[modKey][rowKey]) or 0
end

function MR:SetManualOverride(modKey, rowKey, val, maxVal)
    local overrides = self.GetManualOverrideBucket and self:GetManualOverrideBucket(modKey, rowKey) or self.db.char.manualOverrides
    if not overrides then return end
    if not overrides[modKey] then overrides[modKey] = {} end
    if modKey == "custom_tasks" and type(rowKey) == "string" and rowKey:match("^shared_task_") then
        local taskId = rowKey:match("^shared_task_(%d+)")
        if taskId then
            overrides[modKey]["task_" .. taskId] = nil
        end
    end
    if val <= 0 then
        overrides[modKey][rowKey] = nil
        self:SetProgress(modKey, rowKey, 0, maxVal or 1)
        self:Scan()
    else
        overrides[modKey][rowKey] = maxVal and math.min(val, maxVal) or val
        self:SetProgress(modKey, rowKey, overrides[modKey][rowKey], maxVal)
    end
end

