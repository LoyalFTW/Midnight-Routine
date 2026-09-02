local addonName, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local CoreData = assert(ns.CoreData, "MidnightRoutine CoreData must load before Core/Scanner.lua")
local DeepCopy = CoreData.DeepCopy
local SetProgressValue = CoreData.SetProgressValue
local PruneProgressStore = CoreData.PruneProgressStore

-- Scan failures are announced once per source per session; a module that throws
-- every scan would otherwise flood the chat frame.
local reportedScanFailures = {}

local function ReportScanFailure(source, err)
    if reportedScanFailures[source] then
        return
    end
    reportedScanFailures[source] = true
    print(string.format(
        L["Scan_Failed"] or "|cff2ae7c6MidnightRoutine:|r Scan step '%s' failed and was skipped: %s",
        tostring(source), tostring(err)))
end

-- Runs a module's own scan without letting a throw escape into the caller. One
-- broken module must not stop the modules after it, nor abandon the scan latch.
local function SafeModuleScan(mod)
    local ok, changed = pcall(mod.onScan, mod)
    if not ok then
        ReportScanFailure(mod.key or "?", changed)
        return nil
    end
    return changed
end

local function WriteProgress(progress, modKey, rowKey, val, overrides)
    if overrides and overrides[modKey] then
        local mo = overrides[modKey][rowKey]
        if mo and mo > val then val = mo end
    end
    return SetProgressValue(progress, modKey, rowKey, val)
end

local function ValuesEqual(a, b)
    if a == b then
        return true
    end

    if type(a) ~= type(b) then
        return false
    end

    if type(a) ~= "table" then
        return false
    end

    for key, value in pairs(a) do
        if not ValuesEqual(value, b[key]) then
            return false
        end
    end

    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end

    return true
end

local function RowScanSignature(row)
    if not row then
        return ""
    end

    local color = row.countColor
    local colorSig
    if type(color) == "table" then
        colorSig = tostring(color[1]) .. "," .. tostring(color[2]) .. "," .. tostring(color[3]) .. "," .. tostring(color[4])
    else
        colorSig = tostring(color)
    end

    local visible = row.isVisible and row.isVisible() or nil
    return colorSig
        .. "\031" .. tostring(row.countText)
        .. "\031" .. tostring(visible)
        .. "\031" .. tostring(row.max)
        .. "\031" .. tostring(row.note)
        .. "\031" .. tostring(row.vaultColor)
        .. "\031" .. tostring(row.vaultLabel)
end

local function UpdateCurrencyProgressForRow(self, progress, mod, row)
    local info = C_CurrencyInfo.GetCurrencyInfo(row.currencyId)
    if not info then
        return false
    end

    local dirty = false
    local wallet  = info.quantity or 0
    local weekly  = info.quantityEarnedThisWeek or 0
    local weeklyCap = (info.maxWeeklyQuantity and info.maxWeeklyQuantity > 0)
                      and info.maxWeeklyQuantity or nil
    local dynamicCap = nil
    local raw = wallet

    if not row.noMax and info.maxQuantity and info.maxQuantity > 0 then
        dynamicCap = info.maxQuantity
        if info.useTotalEarnedForMaxQty and info.totalEarned ~= nil then
            raw = info.totalEarned
        else
            raw = wallet
        end
    elseif weeklyCap and not row.noMax then
        dynamicCap = weeklyCap
        raw = weekly
    end

    if dynamicCap and row.max ~= dynamicCap then
        row.max = dynamicCap
        dirty = true
    end

    local walletKey = row.key .. "_wallet"
    local previousWallet = progress[mod.key] and progress[mod.key][walletKey]

    if SetProgressValue(progress, mod.key, walletKey, wallet) then
        dirty = true
    end

    if row.trackWeeklyEarned then
        local collectedKey = row.key .. "_collected"
        local trackingCap = row.weeklyCap or weeklyCap or row.max
        local collected = progress[mod.key] and tonumber(progress[mod.key][collectedKey]) or 0

        if previousWallet ~= nil and wallet > previousWallet then
            collected = collected + (wallet - previousWallet)
        end

        -- Only the API's own earned-this-week figure may raise the tally. The wallet
        -- balance is currency held, not currency earned, so using it as a floor reports
        -- a full week's progress for anything carried across the reset.
        collected = math.max(collected, weekly)
        if trackingCap and trackingCap > 0 then
            collected = math.min(collected, trackingCap)
        end

        if SetProgressValue(progress, mod.key, collectedKey, collected) then
            dirty = true
        end
    end

    local val = row.noMax and raw or math.min(raw, row.max or raw)
    if WriteProgress(progress, mod.key, row.key, val, self.db.char.manualOverrides) then
        dirty = true
    end

    return dirty
end

local function UpdateQuestProgressForRow(self, progress, mod, row)
    local done = 0
    if row.questIds then
        if row.orderedQuestSequence then
            for _, qid in ipairs(row.questIds) do
                if not C_QuestLog.IsQuestFlaggedCompleted(qid) then
                    break
                end
                done = done + 1
            end
        else
            for _, qid in ipairs(row.questIds) do
                if C_QuestLog.IsQuestFlaggedCompleted(qid) then
                    done = done + 1
                end
            end
        end
    end

    local value = math.min(done, row.max or done)
    local progressBucket = (self.GetProgressBucket and self:GetProgressBucket(mod.key, row.key)) or progress
    local overridesBucket = (self.GetManualOverrideBucket and self:GetManualOverrideBucket(mod.key, row.key)) or self.db.char.manualOverrides

    if (row.accountWideComplete or row.preserveCompletion) and value == 0 then
        local existing = progressBucket[mod.key] and progressBucket[mod.key][row.key] or 0
        if existing > 0 then
            return false
        end
    end

    return WriteProgress(progressBucket, mod.key, row.key, value, overridesBucket)
end

local function UpdateItemProgressForRow(self, progress, mod, row)
    local count = 0
    if C_Item and C_Item.GetItemCount then
        count = C_Item.GetItemCount(row.itemId, false, false, true) or 0
    elseif GetItemCount then
        -- Same arguments as the C_Item call above: bag and reagent bank, no charges.
        count = GetItemCount(row.itemId, false, false, true) or 0
    end

    local value = row.noMax and count or math.min(count, row.max or count)
    return WriteProgress(progress, mod.key, row.key, value, self.db.char.manualOverrides)
end

function MR:PrimeModuleData(mod)
    if not (mod and self.db and self.db.char and self.db.char.progress) then
        return false
    end

    local progress = self.db.char.progress
    local dirty = false
    for _, row in ipairs(mod.rows or {}) do
        if row.questIds and not row.turnInTracked then
            dirty = UpdateQuestProgressForRow(self, progress, mod, row) or dirty
        elseif row.questIds and row.turnInTracked and row.allowQuestFlagBackfill then
            local progressBucket = (self.GetProgressBucket and self:GetProgressBucket(mod.key, row.key)) or progress
            local currentValue = progressBucket[mod.key] and progressBucket[mod.key][row.key] or 0
            if currentValue <= 0 then
                dirty = UpdateQuestProgressForRow(self, progress, mod, row) or dirty
            end
        end
        if row.currencyId then
            dirty = UpdateCurrencyProgressForRow(self, progress, mod, row) or dirty
        end
        if row.itemId and not row.noItemProgress then
            dirty = UpdateItemProgressForRow(self, progress, mod, row) or dirty
        end
    end

    if mod.onScan then
        dirty = (SafeModuleScan(mod) == true) or dirty
    end

    self._moduleStatsCache = nil
    return dirty
end

function MR:RequestScan(delay)
    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return
    end

    delay = tonumber(delay) or 0

    if self._scanSuppressedUntil then
        local remaining = self._scanSuppressedUntil - GetTime()
        if remaining > delay then
            delay = remaining + 0.1
        end
    end

    if delay > 0 then
        local targetAt = GetTime() + delay

        if self._requestedScanTimer and self._requestedScanAt and self._requestedScanAt <= targetAt then
            return
        end

        if self._requestedScanTimer then
            self:CancelTimer(self._requestedScanTimer)
        end
        self._requestedScanAt = targetAt
        self._requestedScanTimer = self:ScheduleTimer(function()
            self._requestedScanTimer = nil
            self._requestedScanAt = nil
            self:Scan()
        end, delay)
        return
    end

    self:Scan()
end





local function ListContains(list, value)
    for i = 1, #list do
        if list[i] == value then
            return true
        end
    end
    return false
end

function MR:ScanAutoUpdateInstanceRows(changedQuestId, changedEncounterId, difficultyId)
    if not (self and self.db and self.db.char and self.db.char.progress) then
        return
    end

    if difficultyId and MR.CANONICAL_DIFFICULTY then
        difficultyId = MR.CANONICAL_DIFFICULTY[difficultyId] or difficultyId
    end
    local progress = self.db.char.progress
    for _, mod in ipairs(self.modules) do
        if self:IsModuleEnabled(mod.key) then
            for _, row in ipairs(mod.rows) do

                if row.autoUpdateInstances and row.questIds
                    and (changedQuestId == nil or ListContains(row.questIds, changedQuestId)) then
                    if not row.turnInTracked then
                        UpdateQuestProgressForRow(self, progress, mod, row)
                    elseif row.allowQuestFlagBackfill then
                        local progressBucket = (self.GetProgressBucket and self:GetProgressBucket(mod.key, row.key)) or progress
                        local cur = progressBucket[mod.key] and progressBucket[mod.key][row.key] or 0
                        if cur <= 0 then
                            UpdateQuestProgressForRow(self, progress, mod, row)
                        end
                    end
                end

                if row.encounterIds
                    and (changedEncounterId == nil or ListContains(row.encounterIds, changedEncounterId)) then

                    local diffOk = (not difficultyId) or (not row.encounterDifficulties) or (row.encounterDifficulties[difficultyId] == true)
                    if diffOk then
                        local progressBucket = (self.GetProgressBucket and self:GetProgressBucket(mod.key, row.key)) or progress
                        if not progressBucket[mod.key] then progressBucket[mod.key] = {} end
                        local cur = progressBucket[mod.key][row.key] or 0
                        local maxVal = row.max or 1

                        if difficultyId and row.taskId then
                            if self.db then
                                local diffProgress
                                if row.accountWideComplete then
                                    self.db.global.customTaskDiffProgress = self.db.global.customTaskDiffProgress or {}
                                    diffProgress = self.db.global.customTaskDiffProgress
                                elseif self.db.char then
                                    self.db.char.customTaskDiffProgress = self.db.char.customTaskDiffProgress or {}
                                    diffProgress = self.db.char.customTaskDiffProgress
                                end
                                local key = row.key or tostring(row.taskId)
                                if diffProgress then
                                    diffProgress[key] = diffProgress[key] or {}
                                    local diffState = diffProgress[key]
                                    if not diffState[difficultyId] then
                                        diffState[difficultyId] = true
                                        if cur < maxVal then
                                            progressBucket[mod.key][row.key] = cur + 1
                                            self._moduleStatsCache = nil
                                        end
                                    end
                                end
                            end
                        elseif not row.taskId then
                            if cur < maxVal then
                                progressBucket[mod.key][row.key] = maxVal
                                self._moduleStatsCache = nil
                            end
                        end
                    end
                end
            end
        end
    end
end

function MR:RefreshCurrencyProgress(currencyId, refreshUI)
    if not (self and self.db and self.db.char and self.db.char.progress) then
        return false
    end

    local progress = self.db.char.progress
    local dirty = false

    for _, mod in ipairs(self.modules) do
        if self:IsModuleEnabled(mod.key) then
            for _, row in ipairs(mod.rows) do
                if row.currencyId and (currencyId == nil or row.currencyId == currencyId) then
                    if UpdateCurrencyProgressForRow(self, progress, mod, row) then
                        dirty = true
                    end
                end
            end
        end
    end

    if dirty then
        self._moduleStatsCache = nil
        if refreshUI ~= false then
            self:RefreshUI()
        end
    end

    return dirty
end

function MR:RefreshQuestProgress(questId, refreshUI)
    if not (self and self.db and self.db.char and self.db.char.progress) then
        return false
    end

    local progress = self.db.char.progress
    local dirty = false

    for _, mod in ipairs(self.modules) do
        if self:IsModuleEnabled(mod.key) then
            for _, row in ipairs(mod.rows) do
                if row.questIds then
                    local shouldUpdate = questId == nil
                    if not shouldUpdate then
                        for _, qid in ipairs(row.questIds) do
                            if qid == questId then
                                shouldUpdate = true
                                break
                            end
                        end
                    end

                    if shouldUpdate then
                        if row.turnInTracked and row.allowQuestFlagBackfill then
                            local progressBucket = (self.GetProgressBucket and self:GetProgressBucket(mod.key, row.key)) or progress
                            local currentValue = progressBucket[mod.key] and progressBucket[mod.key][row.key] or 0
                            if currentValue <= 0 and UpdateQuestProgressForRow(self, progress, mod, row) then
                                dirty = true
                            end
                        elseif not row.turnInTracked then
                            if UpdateQuestProgressForRow(self, progress, mod, row) then
                                dirty = true
                            end
                        end
                    end
                end
            end
        end
    end

    if dirty then
        self._moduleStatsCache = nil
        if refreshUI ~= false then
            self:RefreshUI()
        end
    end

    return dirty
end

function MR:RefreshItemProgress(itemId, refreshUI)
    if not (self and self.db and self.db.char and self.db.char.progress) then
        return false
    end

    local progress = self.db.char.progress
    local dirty = false

    for _, mod in ipairs(self.modules) do
        if self:IsModuleEnabled(mod.key) then
            for _, row in ipairs(mod.rows) do
                if row.itemId and not row.noItemProgress and (itemId == nil or row.itemId == itemId) then
                    if UpdateItemProgressForRow(self, progress, mod, row) then
                        dirty = true
                    end
                end
            end
        end
    end

    if dirty then
        self._moduleStatsCache = nil
        if refreshUI ~= false then
            self:RefreshUI()
        end
    end

    return dirty
end

function MR:RefreshModuleScans(moduleKeys, refreshUI)
    if not (self and self.db and self.db.char and self.db.char.progress and moduleKeys) then
        return false
    end
    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return false
    end

    self._moduleScanPassCount = (self._moduleScanPassCount or 0) + 1
    local dirty = false
    for _, moduleKey in ipairs(moduleKeys) do
        local mod = self.moduleByKey and self.moduleByKey[moduleKey]
        if mod and mod.onScan and self:IsModuleEnabled(moduleKey) then
            self._moduleScanModuleCount = (self._moduleScanModuleCount or 0) + 1
            if not self.db.char.progress[moduleKey] then
                self.db.char.progress[moduleKey] = {}
            end
            local beforeProgress
            local beforeRows
            if not mod.scanReturnsChanged then
                beforeProgress = DeepCopy(self.db.char.progress[moduleKey])
                beforeRows = {}
                for _, row in ipairs(mod.rows or {}) do
                    beforeRows[row.key] = RowScanSignature(row)
                end
            end

            local moduleChanged = SafeModuleScan(mod) == true

            self.db.char.rowVisibility = self.db.char.rowVisibility or {}
            self.db.char.rowVisibility[moduleKey] = self.db.char.rowVisibility[moduleKey] or {}
            local visibilityBucket = self.db.char.rowVisibility[moduleKey]
            for _, row in ipairs(mod.rows or {}) do
                local currentVisible = row.isVisible and row.isVisible() == true or nil
                if visibilityBucket[row.key] ~= currentVisible then
                    moduleChanged = true
                end
                visibilityBucket[row.key] = currentVisible
            end

            if not mod.scanReturnsChanged then
                local afterProgress = self.db.char.progress[moduleKey]
                if not ValuesEqual(beforeProgress, afterProgress) then
                    moduleChanged = true
                end
                if not moduleChanged then
                    for _, row in ipairs(mod.rows or {}) do
                        if beforeRows[row.key] ~= RowScanSignature(row) then
                            moduleChanged = true
                            break
                        end
                    end
                end
            end

            if moduleChanged and self.NoteRefreshSource then
                self:NoteRefreshSource("ModuleScanChanged:" .. moduleKey)
            end
            dirty = dirty or moduleChanged
        end
    end

    PruneProgressStore(self.db.char.progress)
    if self.db.global then
        PruneProgressStore(self.db.global.customTaskProgress)
    end

    if dirty then
        self._moduleStatsCache = nil
        if refreshUI then
            self:RequestDataRefresh()
        end
    end

    return dirty
end

-- The body of one scan pass. Extracted so MR:Scan can run it under pcall and
-- clear the in-progress latch whether it returns or throws.
local function RunScanPass(self)
    self.db.char.lastSyncAt = GetServerTime()
    local beforeProgress = DeepCopy(self.db.char.progress)
    local beforeRows = {}
    for _, mod in ipairs(self.modules) do
        if self:IsModuleEnabled(mod.key) then
            local rows = {}
            beforeRows[mod.key] = rows
            for _, row in ipairs(mod.rows or {}) do
                rows[row.key] = RowScanSignature(row)
            end
        end
    end
    local concentrationChanged = self:RefreshProfessionConcentration()

    local progress = self.db.char.progress

    for _, mod in ipairs(self.modules) do
        if self:IsModuleEnabled(mod.key) then
            for _, row in ipairs(mod.rows) do
            if row.questIds and not row.turnInTracked then
                UpdateQuestProgressForRow(self, progress, mod, row)
            elseif row.questIds and row.turnInTracked and row.allowQuestFlagBackfill then
                local currentValue = progress[mod.key] and progress[mod.key][row.key] or 0
                if currentValue <= 0 then
                    UpdateQuestProgressForRow(self, progress, mod, row)
                end
            end
            if row.currencyId then
                UpdateCurrencyProgressForRow(self, progress, mod, row)
            end
            if row.itemId and not row.noItemProgress then
                UpdateItemProgressForRow(self, progress, mod, row)
            end
            end

            if mod.onScan then
                SafeModuleScan(mod)
            end

            local mdb = progress[mod.key]
            if mdb then
                for _, row in ipairs(mod.rows) do
                    if row.liveKey and row.liveKey ~= row.key and mdb[row.liveKey] ~= nil then
                        local rowMax = row.max or mdb[row.liveKey]
                        local capped = row.noMax and mdb[row.liveKey] or math.min(mdb[row.liveKey], rowMax)
                        local _ov = self.db.char.manualOverrides
                        if _ov and _ov[mod.key] then
                            local mo = _ov[mod.key][row.key]
                            if mo and mo > capped then capped = mo end
                        end
                        SetProgressValue(progress, mod.key, row.key, capped)
                    end
                    if row.liveTierLabelKey then
                        row.vaultLabel = mdb[row.liveTierLabelKey]
                    end
                    if row.liveTierColorKey then
                        row.vaultColor = mdb[row.liveTierColorKey]
                    end
                end
            end
        end
    end

    PruneProgressStore(progress)
    if self.db.global then
        PruneProgressStore(self.db.global.customTaskProgress)
    end

    local dirty = concentrationChanged == true or not ValuesEqual(beforeProgress, progress)
    if not dirty then
        for _, mod in ipairs(self.modules) do
            local moduleRows = beforeRows[mod.key]
            if moduleRows then
                for _, row in ipairs(mod.rows or {}) do
                    if moduleRows[row.key] ~= RowScanSignature(row) then
                        dirty = true
                        break
                    end
                end
            end
            if dirty then break end
        end
    end

    if dirty then self:RequestDataRefresh() end
    if self.SyncAllRareKills then self:SyncAllRareKills() end
    if self.RefreshRares  then self:RefreshRares()  end
    if self.RefreshRenown then self:RefreshRenown() end
end

function MR:Scan()
    if self:ShouldDeferForCombat("scan") then
        return
    end

    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return
    end

    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self:ScanAutoUpdateInstanceRows(nil, nil)
        return
    end

    local now = GetTime and GetTime() or 0
    local minScanInterval = 0.25

    if self._requestedScanTimer then
        self:CancelTimer(self._requestedScanTimer)
        self._requestedScanTimer = nil
    end

    if self._scanInProgress then
        self._scanPending = true
        return
    end

    if self._lastScanAt and (now - self._lastScanAt) < minScanInterval then
        self._scanPending = true
        if not self._scanThrottleTimer then
            local delay = math.max(minScanInterval - (now - self._lastScanAt), 0.01)
            self._scanThrottleTimer = self:ScheduleTimer(function()
                self._scanThrottleTimer = nil
                if self._scanPending then
                    self._scanPending = nil
                    self:Scan()
                end
            end, delay)
        end
        return
    end

    if self._scanSuppressedUntil and GetTime() < self._scanSuppressedUntil then
        return
    end

    self._scanCount = (self._scanCount or 0) + 1
    self._scanInProgress = true

    local ok, err = pcall(RunScanPass, self)

    self._lastScanAt = GetTime and GetTime() or now
    self._scanInProgress = nil

    if not ok then
        ReportScanFailure("Scan", err)
    end

    if self._scanPending and not self._scanThrottleTimer then
        self._scanPending = nil
        self._scanThrottleTimer = self:ScheduleTimer(function()
            self._scanThrottleTimer = nil
            self:Scan()
        end, minScanInterval)
    end
end
