local addonName, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Core = assert(ns.CoreInternals, "Core/Foundation.lua must load first")
local DeepCopy = Core.DeepCopy
local MergeMissing = Core.MergeMissing
local RestoreDefaults = Core.RestoreDefaults
local IsTableEmpty = Core.IsTableEmpty
local MODULES_WITH_OPTIONAL_CURRENCY_COMPLETION = Core.optionalCurrencyModules
local IsInRestrictedCombat = Core.IsInRestrictedCombat
local DEFAULTS = Core.defaults

function MR:ApplyScaleToAll(v)
    self.db.profile.scale          = v
    self.db.profile.raresScale     = v
    self.db.profile.renownScale    = v
    self.db.profile.gatheringScale = v
    if self.frame then self.frame:SetScale(v) end
    local rf = self.raresFrame
    if rf and rf:IsShown() then rf:SetScale(v) end
    local rnf = self.renownFrame
    if rnf and rnf:IsShown() then rnf:SetScale(v) end
    local gf = self.gatheringLocationsFrame
    if gf and gf:IsShown() then gf:SetScale(v) end
    if self.detachedFrames then
        for _, frame in pairs(self.detachedFrames) do
            frame:SetScale(v)
        end
    end
    if self.RepopulateRaresConfig     then self:RepopulateRaresConfig() end
    if self.RepopulateGatheringConfig then self:RepopulateGatheringConfig() end
    if self.RepopulateRenownConfig    then self:RepopulateRenownConfig() end
    if self.RequestConfigRepopulate then
        self:RequestConfigRepopulate(nil, 0.06)
    elseif self.RepopulateConfigFrame then
        self:RepopulateConfigFrame()
    end
end

function MR:ApplyFontSizeToAll(v)
    self.db.profile.fontSize          = v
    self.db.profile.raresFontSize     = v
    self.db.profile.gatheringFontSize = v
    self.db.profile.renownFontSize    = v
    if self.ApplySharedMediaSettings then
        self:ApplySharedMediaSettings()
    elseif self.RequestVisualRefresh then
        self:RequestVisualRefresh({ config = false })
    end
    if self.raresFrame and self.raresFrame.IsShown and self.raresFrame:IsShown() and self.RebuildRaresFrame then
        self:RebuildRaresFrame()
    end
    if self.RebuildRenownFrame            then self:RebuildRenownFrame() end
    if self.RepopulateRaresConfig     then self:RepopulateRaresConfig() end
    if self.RepopulateGatheringConfig then self:RepopulateGatheringConfig() end
    if self.RepopulateRenownConfig    then self:RepopulateRenownConfig() end
    if self.RequestConfigRepopulate then
        self:RequestConfigRepopulate(nil, 0.06)
    elseif self.RepopulateConfigFrame then
        self:RepopulateConfigFrame()
    end
end


function MR:HasVisibleMainTrackingSurface()
    if self.frame and self.frame.IsShown and self.frame:IsShown() then
        return true
    end
    if self.altBoardFrame and self.altBoardFrame.IsShown and self.altBoardFrame:IsShown() then
        return true
    end
    if self.detachedFrames then
        for _, frame in pairs(self.detachedFrames) do
            if frame and frame.IsShown and frame:IsShown() then
                return true
            end
        end
    end
    return false
end

function MR:MarkBackgroundDataDirty()
    self._backgroundDataDirty = true
    self._refreshUIDirty = true
    self._mainPanelNeedsRefresh = true
end

local HIDDEN_SURFACE_TIMER_FIELDS = {
    "_refreshRequestTimer",
    "_dataRefreshTimer",
    "_requestedScanTimer",
    "_scanThrottleTimer",
    "_refreshUITimer",
    "_delvesLiveProgressTimer",
}

function MR:SuspendHiddenSurfaceWork()
    if self:HasVisibleMainTrackingSurface() then
        return false
    end

    for _, field in ipairs(HIDDEN_SURFACE_TIMER_FIELDS) do
        local timer = self[field]
        if timer and self.CancelTimer then self:CancelTimer(timer) end
        self[field] = nil
    end
    self._refreshRequestAt = nil
    self._requestedScanAt = nil
    self._refreshRequestPending = nil
    self._dataRefreshPending = nil
    self._refreshUIPending = nil
    self._scanPending = nil
    self:MarkBackgroundDataDirty()
    return true
end

function MR:ActivateVisibleTrackingSurface()
    if not self._backgroundDataDirty then
        return false
    end

    self._backgroundDataDirty = nil
    if self.UpdateInstanceFrameVisibility then self:UpdateInstanceFrameVisibility() end
    if self.RefreshPlayerProfessions then self:RefreshPlayerProfessions() end
    if self.RefreshProfessionConcentration then self:RefreshProfessionConcentration() end
    if self.RefreshStoryCampaignRegistration then self:RefreshStoryCampaignRegistration() end
    if self.RequestScan then self:RequestScan(0.01) end
    return true
end

function MR:RequestUIRefresh(delay)
    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return
    end

    if IsInRestrictedCombat() then
        self:QueueCombatDeferredUpdate("refreshUI")
        return
    end

    if not self.ScheduleTimer then
        if self.NoteRefreshSource then
            self:NoteRefreshSource("RequestUIRefresh")
        end
        self:RefreshUI()
        return
    end

    delay = tonumber(delay) or 0.05

    local now = GetTime and GetTime() or 0
    local targetAt = now + delay
    if self._refreshRequestTimer and self._refreshRequestAt and self._refreshRequestAt <= targetAt then
        return
    end

    if self.NoteRefreshSource then
        self:NoteRefreshSource("RequestUIRefresh")
    end

    self._refreshRequestPending = true
    if self._refreshRequestTimer and self.CancelTimer then
        self:CancelTimer(self._refreshRequestTimer)
        self._refreshRequestTimer = nil
    end

    self._refreshRequestAt = targetAt
    self._refreshRequestTimer = self:ScheduleTimer(function()
        self._refreshRequestTimer = nil
        self._refreshRequestAt = nil
        if self._refreshRequestPending then
            self._refreshRequestPending = nil
            self:RefreshUI()
        end
    end, delay)
end

function MR:RequestConfigRefresh()
    self:RequestUIRefresh(0.04)
end

function MR:RequestDataRefresh(delay)
    if self.NoteRefreshSource then
        self:NoteRefreshSource("RequestDataRefresh")
    end
    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return
    end

    if self._dataRefreshPending then
        return
    end

    if not self.ScheduleTimer then
        self:RefreshUI()
        return
    end

    self._dataRefreshPending = true
    self._dataRefreshTimer = self:ScheduleTimer(function()
        self._dataRefreshTimer = nil
        self._dataRefreshPending = nil
        if self.RequestUIRefresh then
            self:RequestUIRefresh(0.01)
        else
            self:RefreshUI()
        end
    end, tonumber(delay) or 0.05)
end

function MR:RequestConfigRepopulate(reason, delay)
    if not self.ScheduleTimer then
        if self.RepopulateConfigFrame then
            self:RepopulateConfigFrame(reason)
        end
        return
    end

    delay = tonumber(delay) or 0.06
    self._configRepopulatePending = reason or true
    if self._configRepopulateTimer and self.CancelTimer then
        self:CancelTimer(self._configRepopulateTimer)
        self._configRepopulateTimer = nil
    end

    self._configRepopulateTimer = self:ScheduleTimer(function()
        local pendingReason = self._configRepopulatePending
        self._configRepopulateTimer = nil
        self._configRepopulatePending = nil
        if pendingReason and self.RepopulateConfigFrame then
            self:RepopulateConfigFrame(pendingReason == true and nil or pendingReason)
        end
    end, delay)
end

function MR:RequestVisualRefresh(opts)
    opts = type(opts) == "table" and opts or {}

    if opts.applySharedMedia and ns.ApplySharedMedia then
        ns.ApplySharedMedia(self.GetActiveMediaSettings and self:GetActiveMediaSettings() or (self.db and self.db.profile))
    end

    if opts.refreshBackgrounds and ns.RefreshAllFrameBackgrounds then
        ns.RefreshAllFrameBackgrounds()
    end

    if opts.main ~= false then
        if self.RequestUIRefresh then
            self:RequestUIRefresh(opts.mainDelay or 0.02)
        elseif self.RefreshUI then
            self:RefreshUI()
        end
    end

    if opts.profession ~= false then
        if self.RequestProfessionKnowledgeSurfaceRefresh then
            self:RequestProfessionKnowledgeSurfaceRefresh(opts.professionDelay or 0.04)
        elseif self.RefreshGatheringLocationsFrame then
            self:RefreshGatheringLocationsFrame()
        end
    end

    if opts.config ~= false then
        if self.RequestConfigRepopulate then
            self:RequestConfigRepopulate(opts.configReason, opts.configDelay or 0.06)
        elseif self.RepopulateConfigFrame then
            self:RepopulateConfigFrame(opts.configReason)
        end
    end
end

function MR:IsModuleHideComplete(modKey)
    local storage = self:GetActiveModuleStorage()
    local s = storage and storage[modKey]
    if s and s.hideComplete ~= nil then return s.hideComplete end
    if MODULES_WITH_OPTIONAL_CURRENCY_COMPLETION[modKey] then
        return false
    end
    return self.db.char.hideComplete
end

function MR:SetModuleHideComplete(modKey, value, skipRefresh)
    local storage = self:GetActiveModuleStorage()
    if not storage[modKey] then storage[modKey] = {} end
    if storage[modKey].hideComplete == value then
        return
    end
    storage[modKey].hideComplete = value
    if not skipRefresh then
        self:RefreshUI()
    end
end

function MR:RefreshProfessionKnowledgeSurfaces()
    if self._suspendProfessionKnowledgeSurfaceRefresh then
        return
    end
    if self.RebuildGatheringLocationsFrame then
        self:RebuildGatheringLocationsFrame()
    end
    if self.RepopulateGatheringConfig then
        self:RepopulateGatheringConfig()
    end
end

function MR:RequestProfessionKnowledgeSurfaceRefresh(delay)
    local gatheringVisible = self.gatheringLocationsFrame
        and self.gatheringLocationsFrame.IsShown
        and self.gatheringLocationsFrame:IsShown()
    local configFrame = self.GetConfigFrame and self:GetConfigFrame() or nil
    local configVisible = configFrame and configFrame.IsShown and configFrame:IsShown()
    if not gatheringVisible and not configVisible then
        self._professionKnowledgeSurfaceRefreshPending = true
        return
    end

    if not self.ScheduleTimer then
        self:RefreshProfessionKnowledgeSurfaces()
        return
    end

    delay = tonumber(delay) or 0.04
    local now = GetTime and GetTime() or 0
    local targetAt = now + delay
    if self._professionKnowledgeSurfaceRefreshTimer
        and self._professionKnowledgeSurfaceRefreshAt
        and self._professionKnowledgeSurfaceRefreshAt <= targetAt then
        return
    end

    self._professionKnowledgeSurfaceRefreshPending = true
    if self._professionKnowledgeSurfaceRefreshTimer and self.CancelTimer then
        self:CancelTimer(self._professionKnowledgeSurfaceRefreshTimer)
        self._professionKnowledgeSurfaceRefreshTimer = nil
    end

    self._professionKnowledgeSurfaceRefreshAt = targetAt
    self._professionKnowledgeSurfaceRefreshTimer = self:ScheduleTimer(function()
        self._professionKnowledgeSurfaceRefreshTimer = nil
        self._professionKnowledgeSurfaceRefreshAt = nil
        if self._professionKnowledgeSurfaceRefreshPending then
            local liveGatheringVisible = self.gatheringLocationsFrame
                and self.gatheringLocationsFrame.IsShown
                and self.gatheringLocationsFrame:IsShown()
            local liveConfigFrame = self.GetConfigFrame and self:GetConfigFrame() or nil
            local liveConfigVisible = liveConfigFrame
                and liveConfigFrame.IsShown
                and liveConfigFrame:IsShown()
            if not liveGatheringVisible and not liveConfigVisible then
                return
            end
            self._professionKnowledgeSurfaceRefreshPending = nil
            self:RefreshProfessionKnowledgeSurfaces()
        end
    end, delay)
end

function MR:IsRowEnabled(modKey, rowKey)
    local mod = self.moduleByKey and self.moduleByKey[modKey]
    if mod then
        for _, row in ipairs(mod.rows or {}) do
            if row.key == rowKey and not self:IsPatchEnabled(self:GetRowPatchKey(mod, row)) then
                return false
            end
        end
    end

    local storage = self:GetActiveModuleStorage()
    local s = storage and storage[modKey]
    if not s or not s.hiddenRows then return true end
    return s.hiddenRows[rowKey] ~= false
end

function MR:SetRowEnabled(modKey, rowKey, enabled, skipRefresh)
    local storage = self:GetActiveModuleStorage()
    if not storage[modKey] then storage[modKey] = {} end
    if not storage[modKey].hiddenRows then
        storage[modKey].hiddenRows = {}
    end
    storage[modKey].hiddenRows[rowKey] = enabled and true or false
    if not skipRefresh then
        self:RefreshUI()
    end
    self:RequestProfessionKnowledgeSurfaceRefresh()
end

function MR:IsRowGroupEnabled(modKey, rows)
    if not (modKey and type(rows) == "table") then
        return true
    end
    for _, row in ipairs(rows) do
        if not self:IsRowEnabled(modKey, row.key) then
            return false
        end
    end
    return true
end

function MR:SetRowGroupEnabled(modKey, rows, enabled)
    if not (modKey and type(rows) == "table") then
        return
    end
    self._suspendProfessionKnowledgeSurfaceRefresh = true
    for _, row in ipairs(rows) do
        self:SetRowEnabled(modKey, row.key, enabled, true)
    end
    self._suspendProfessionKnowledgeSurfaceRefresh = nil
    self:RefreshUI()
    self:RequestProfessionKnowledgeSurfaceRefresh()
end

function MR:SetModuleRowOrder(modKey, orderedKeys)
    if not (self and self.db and modKey and type(orderedKeys) == "table") then
        return false
    end

    local mod = self.moduleByKey and self.moduleByKey[modKey]
    if not mod then
        return false
    end

    local storage = self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod))
    if not storage then
        return false
    end
    storage[modKey] = storage[modKey] or {}

    local valid = {}
    for _, row in ipairs(mod.rows or {}) do
        if row and row.key then
            valid[row.key] = true
        end
    end

    local cleaned, seen = {}, {}
    for _, rowKey in ipairs(orderedKeys) do
        if valid[rowKey] and not seen[rowKey] then
            cleaned[#cleaned + 1] = rowKey
            seen[rowKey] = true
        end
    end

    storage[modKey].rowOrder = cleaned
    self._moduleStatsCache = nil
    return true
end

function MR:SetModuleRowPosition(modKey, rowKey, targetRowKey, afterTarget)
    if not (modKey and rowKey and targetRowKey) or rowKey == targetRowKey then
        return false
    end

    local mod = self.moduleByKey and self.moduleByKey[modKey]
    if not mod then
        return false
    end

    local rows = self:GetOrderedRows(mod)
    local order, seen = {}, {}
    for _, row in ipairs(rows or {}) do
        if row and row.key and not row.control and not seen[row.key] then
            order[#order + 1] = row.key
            seen[row.key] = true
        end
    end

    if not seen[rowKey] then
        order[#order + 1] = rowKey
        seen[rowKey] = true
    end
    if not seen[targetRowKey] then
        order[#order + 1] = targetRowKey
        seen[targetRowKey] = true
    end

    local fromIndex, targetIndex
    for index, existingKey in ipairs(order) do
        if existingKey == rowKey then
            fromIndex = index
        elseif existingKey == targetRowKey then
            targetIndex = index
        end
    end
    if not fromIndex or not targetIndex or fromIndex == targetIndex then
        return false
    end

    local insertIndex = targetIndex
    if fromIndex < targetIndex then
        insertIndex = insertIndex - 1
    end
    if afterTarget then
        insertIndex = insertIndex + 1
    end
    insertIndex = math.max(1, math.min(#order, insertIndex))
    if insertIndex == fromIndex then
        return false
    end

    local moved = table.remove(order, fromIndex)
    table.insert(order, insertIndex, moved)
    if not self:SetModuleRowOrder(modKey, order) then
        return false
    end
    if self.RefreshUI then
        self:RefreshUI()
    end
    if self.RequestWarbandBoardRefresh then
        self:RequestWarbandBoardRefresh(false)
    end
    return true
end

function MR:IsCharacterWindowLayoutEnabled()
    return self.db and self.db.profile and self.db.profile.characterWindowLayout == true
end

function MR:GetWindowLayoutValue(key)
    if not (self and self.db and key) then return nil end

    if self:IsCharacterWindowLayoutEnabled() then
        local charLayout = self.db.char and self.db.char.windowLayout
        if charLayout and charLayout[key] ~= nil then
            return charLayout[key]
        end
    end

    return self.db.profile[key]
end

function MR:SetWindowLayoutValue(key, value)
    if not (self and self.db and key) then return end

    if self:IsCharacterWindowLayoutEnabled() then
        if not self.db.char.windowLayout then
            self.db.char.windowLayout = {}
        end
        self.db.char.windowLayout[key] = value
    else
        self.db.profile[key] = value
    end
end

function MR:GetManagedWindowOpen(key)
    if not key then
        return false
    end

    return self:GetWindowLayoutValue(key) == true
end

function MR:SetManagedWindowOpen(key, value)
    if not key then
        return
    end

    local newValue = value and true or false
    local oldValue = self:GetWindowLayoutValue(key) == true
    self:SetWindowLayoutValue(key, newValue)

    if oldValue ~= newValue then
        if self.RequestConfigRepopulate then
            self:RequestConfigRepopulate(nil, 0.01)
        elseif self.RepopulateConfigFrame then
            self:RepopulateConfigFrame()
        end
    end
end

function MR:GetHeaderColor(modKey)
    if self.db.profile.headerColors and self.db.profile.headerColors[modKey] then
        return self.db.profile.headerColors[modKey]
    end
    local mod = self.moduleByKey[modKey]
    return mod and mod.labelColor or "#ffffff"
end

function MR:SetHeaderColor(modKey, hexColor)
    if not self.db.profile.headerColors then
        self.db.profile.headerColors = {}
    end
    self.db.profile.headerColors[modKey] = hexColor
    self:RequestVisualRefresh()
end

function MR:ResetHeaderColor(modKey)
    if self.db.profile.headerColors then
        self.db.profile.headerColors[modKey] = nil
    end
    self:RequestVisualRefresh()
end

function MR:GetHeaderBackgroundColor(modKey)
    if self.db.profile.headerBackgroundColors and self.db.profile.headerBackgroundColors[modKey] then
        return self.db.profile.headerBackgroundColors[modKey]
    end
    return nil
end

function MR:SetHeaderBackgroundColor(modKey, hexColor)
    if not self.db.profile.headerBackgroundColors then
        self.db.profile.headerBackgroundColors = {}
    end
    self.db.profile.headerBackgroundColors[modKey] = hexColor
    self:RequestVisualRefresh()
end

function MR:ResetHeaderBackgroundColor(modKey)
    if self.db.profile.headerBackgroundColors then
        self.db.profile.headerBackgroundColors[modKey] = nil
    end
    self:RequestVisualRefresh()
end

function MR:GetActiveMediaSettings()
    if not (self and self.db) then
        return {}
    end

    if self:IsCharacterWindowLayoutEnabled() then
        self.db.char.mediaSettings = self.db.char.mediaSettings or {}
        return self.db.char.mediaSettings
    end

    return self.db.profile
end

function MR:GetMediaSetting(key)
    if not (self and self.db and key) then
        return nil
    end

    local active = self:GetActiveMediaSettings()
    if active[key] ~= nil then
        return active[key]
    end

    return self.db.profile[key]
end

function MR:SetMediaSetting(key, value, skipRefresh)
    if not (self and self.db and key) then
        return
    end

    local active = self:GetActiveMediaSettings()
    active[key] = value
    if not skipRefresh then
        self:RequestVisualRefresh({
            applySharedMedia = true,
            refreshBackgrounds = true,
        })
    end
end

function MR:IsCursorWithinBounds(target)
    if not target or not target.IsShown or not target:IsShown() then
        return false
    end

    local left = target:GetLeft()
    local right = target:GetRight()
    local top = target:GetTop()
    local bottom = target:GetBottom()
    if not left or not right or not top or not bottom then
        return false
    end

    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent and UIParent:GetEffectiveScale() or 1
    cursorX = cursorX / uiScale
    cursorY = cursorY / uiScale

    return cursorX >= left and cursorX <= right and cursorY >= bottom and cursorY <= top
end

function MR:ApplyPanelHeaderAutoHide(frame, titleBar, shouldHideFunc)
    if not frame or not titleBar then return end

    if not frame._mrPanelHeaderAutoHideHooked then
        frame._mrHeaderHoverElapsed = 0
        frame:EnableMouse(true)
        frame:HookScript("OnEnter", function(self)
            if self.UpdatePanelHeaderVisibility then
                self:UpdatePanelHeaderVisibility(true)
            end
        end)
        frame:HookScript("OnLeave", function(self)
            if self.UpdatePanelHeaderVisibility then
                self:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(self))
            end
        end)
        frame:HookScript("OnShow", function(self)
            if self.UpdatePanelHeaderVisibility then
                self:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(self))
            end
        end)
        frame._mrPanelHeaderAutoHideHooked = true
    end

    frame.UpdatePanelHeaderVisibility = function(self, isHovering)
        local hideHeaders = MR.db and MR.db.profile and MR.db.profile.autoHidePanelHeaders
        if shouldHideFunc then
            hideHeaders = hideHeaders or shouldHideFunc(self)
        end
        titleBar:SetAlpha((hideHeaders and not isHovering) and 0 or 1)
        self._mrHeaderHovering = isHovering
    end

    frame:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(frame))
end

function MR:RefreshPanelHeaderVisibility(frame)
    if frame and frame.UpdatePanelHeaderVisibility then
        frame:UpdatePanelHeaderVisibility(self:IsCursorWithinBounds(frame))
    end
end

function MR:GetRowColor(modKey, rowKey)
    local p = self.db.profile.rowColors
    if p and p[modKey] and p[modKey][rowKey] then
        return p[modKey][rowKey]
    end
end

function MR:SetRowColor(modKey, rowKey, hexColor)
    if not self.db.profile.rowColors then self.db.profile.rowColors = {} end
    if not self.db.profile.rowColors[modKey] then self.db.profile.rowColors[modKey] = {} end
    self.db.profile.rowColors[modKey][rowKey] = hexColor
    self:RequestVisualRefresh()
end

function MR:ResetRowColor(modKey, rowKey)
    local p = self.db.profile.rowColors
    if p and p[modKey] then
        p[modKey][rowKey] = nil
    end
    self:RequestVisualRefresh()
end

local STATIC_TURN_IN_COMPLETIONS = {
    [89268] = { mod = "s1_weekly",           row = "lost_legends"        },
    [89289] = { mod = "s1_weekly",           row = "saltherils_soiree"   },
    [91966] = { mod = "s1_weekly",           row = "saltherils_soiree"   },
    [90573] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [90574] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [90575] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [90576] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [93744] = { mod = "s1_weekly",           row = "unity_against_void"  },
    [96727] = { mod = "s1_weekly",           row = "unity_against_void"  },
    [90962] = { mod = "midnight_activities", row = "stormarion_assault"  },
    [94835] = { mod = "pvp_weeklies",        row = "early_training"      },
}

local TURN_IN_COMPLETIONS = {}

Core.staticTurnInCompletions = STATIC_TURN_IN_COMPLETIONS
Core.turnInCompletions = TURN_IN_COMPLETIONS

