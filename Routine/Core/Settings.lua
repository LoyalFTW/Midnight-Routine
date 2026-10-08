local _, ns = ...
local MR = ns.MR
local Core = assert(ns.CoreInternals, "Core/Foundation.lua must load first")
local MoveArrayItem = Core.MoveArrayItem
local MODULES_WITH_OPTIONAL_CURRENCY_COMPLETION = Core.optionalCurrencyModules
local VALID_FRAME_STRATA = {
    BACKGROUND = true,
    LOW = true,
    MEDIUM = true,
    HIGH = true,
    DIALOG = true,
}

function MR:GetFrameStrata()
    local strata = self.db and self.db.profile and self.db.profile.frameStrata or "HIGH"
    return VALID_FRAME_STRATA[strata] and strata or "HIGH"
end

function MR:RegisterPriorityFrame(frame)
    if not frame or not frame.SetFrameStrata then return frame end
    self._priorityFrames = self._priorityFrames or setmetatable({}, { __mode = "k" })
    self._priorityFrames[frame] = true
    frame:SetFrameStrata(self:GetFrameStrata())
    return frame
end

function MR:SetFrameStrata(strata)
    if not VALID_FRAME_STRATA[strata] then return end
    self.db.profile.frameStrata = strata
    if self._priorityFrames then
        for frame in pairs(self._priorityFrames) do
            if frame and frame.SetFrameStrata then
                frame:SetFrameStrata(strata)
            end
        end
    end
end

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
    "_refreshUITimer",
}

function MR:SuspendHiddenSurfaceWork()
    if self:HasVisibleMainTrackingSurface() then
        return false
    end

    local uiCanceled = self._refreshRequestPending == true
        or self._dataRefreshPending == true
        or self._refreshUIPending == true

    for _, field in ipairs(HIDDEN_SURFACE_TIMER_FIELDS) do
        local timer = self[field]
        if timer then
            uiCanceled = true
            if self.CancelTimer then self:CancelTimer(timer) end
        end
        self[field] = nil
    end
    self._refreshRequestAt = nil
    self._refreshRequestPending = nil
    self._dataRefreshPending = nil
    self._refreshUIPending = nil
    if uiCanceled then
        self._refreshUIDirty = true
        self._mainPanelNeedsRefresh = true
    end
    return uiCanceled
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
    if self.RequestCompletionSoundCheck then
        self:RequestCompletionSoundCheck()
    end
    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return
    end

    if self:ShouldDeferForCombat("refreshUI") then
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
    if self.RequestCompletionSoundCheck then
        self:RequestCompletionSoundCheck()
    end
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
end

function MR:RequestProfessionKnowledgeSurfaceRefresh(delay)
    local gatheringVisible = self.gatheringLocationsFrame
        and self.gatheringLocationsFrame.IsShown
        and self.gatheringLocationsFrame:IsShown()
    if not gatheringVisible then
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
            if not liveGatheringVisible then
                return
            end
            self._professionKnowledgeSurfaceRefreshPending = nil
            self:RefreshProfessionKnowledgeSurfaces()
        end
    end, delay)
end

local function GetRowSettingModuleKey(self, modKey, rowKey, field)
    local mod = self.moduleByKey and self.moduleByKey[modKey]
    if mod then
        for _, row in ipairs(mod.rows or {}) do
            if row.key == rowKey then
                return row[field] or modKey
            end
        end
    end
    return modKey
end

function MR:IsRowEnabled(modKey, rowKey)
    local mod = self.moduleByKey and self.moduleByKey[modKey]
    if mod then
        for _, row in ipairs(mod.rows or {}) do
            if row.key == rowKey and not self:IsPatchEnabled(self:GetRowPatchKey(mod, row), modKey) then
                return false
            end
        end
    end

    local storage = self:GetActiveModuleStorage()
    local storageKey = GetRowSettingModuleKey(self, modKey, rowKey, "visibilityModuleKey")
    local s = storage and storage[storageKey]
    if not s or not s.hiddenRows then return true end
    return s.hiddenRows[rowKey] ~= false
end

function MR:SetRowEnabled(modKey, rowKey, enabled, skipRefresh)
    local storage = self:GetActiveModuleStorage()
    local storageKey = GetRowSettingModuleKey(self, modKey, rowKey, "visibilityModuleKey")
    if not storage[storageKey] then storage[storageKey] = {} end
    if not storage[storageKey].hiddenRows then
        storage[storageKey].hiddenRows = {}
    end
    storage[storageKey].hiddenRows[rowKey] = enabled and true or false
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

    local sourceRow
    local targetRow
    for _, row in ipairs(mod.rows or {}) do
        if row.key == rowKey then
            sourceRow = row
        elseif row.key == targetRowKey then
            targetRow = row
        end
    end
    if sourceRow and targetRow and sourceRow.configGroup ~= targetRow.configGroup then
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

    if not MoveArrayItem(order, rowKey, targetRowKey, afterTarget) then
        return false
    end
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
    if self._instanceFramesHidden then
        local stateKey = ({
            renownOpen = "renown",
            raresOpen = "rares",
            gatheringLocOpen = "gathering",
            concentrationTrackerOpen = "concentration",
        })[key]
        if stateKey then
            self._instanceRestoreState = self._instanceRestoreState or {}
            self._instanceRestoreState[stateKey] = newValue
        end
    end

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
    local themeColor = self:GetThemeColor()
    if themeColor then
        return themeColor
    end
    local mod = self.moduleByKey[modKey]
    return mod and mod.labelColor or "#ffffff"
end

function MR:GetClassColorHex()
    local classFile = select(2, UnitClass("player"))
    local classColor = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if not classColor then
        return nil
    end
    return string.format("#%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
end

function MR:GetThemeColor()
    local profile = self.db and self.db.profile
    if not profile then return nil end
    if profile.themeColorMode == "class" then
        return self:GetClassColorHex()
    end
    return profile.themeColor
end

function MR:RefreshImmediateThemeSurfaces()
    local profile = self.db and self.db.profile
    if not profile then return end

    local function RefreshCard(card)
        local header = card and card._hdrFrame
        local mod = header and header._mrMod
        if not (mod and header._label) then return end

        local explicit = profile.headerColors and profile.headerColors[mod.key]
        local color = explicit or self:GetThemeColor() or mod.labelColor or "#ffffff"
        if mod.profSkillLine and not explicit then
            color = "#f5f7fa"
        elseif card._mrAllDone and not explicit then
            color = "#00ff96"
        end
        local r, g, b = ns.Hex(color)
        header._label:SetText(ns.StripColorCodes(mod.label))
        header._label:SetTextColor(r, g, b)

        if mod.key == "currencies" and header._currencyBrowserButton and ns.UIInternal and ns.UIInternal.StyleCurrencyBrowserButton then
            ns.UIInternal.StyleCurrencyBrowserButton(header._currencyBrowserButton, header._currencyBrowserButton._mrTransparent, header._currencyBrowserButton._mrFrameAlpha or 1)
        end
    end

    if self._mainSectionFrames then
        for _, card in pairs(self._mainSectionFrames) do
            RefreshCard(card)
        end
    end
    if self.detachedFrames then
        for _, frame in pairs(self.detachedFrames) do
            if frame._sectionFrames then
                for _, card in pairs(frame._sectionFrames) do
                    RefreshCard(card)
                end
            end
        end
    end
end

function MR:RequestThemeSurfaceRefresh()
    if self._themeSurfaceRefreshTimer and self.CancelTimer then
        self:CancelTimer(self._themeSurfaceRefreshTimer)
        self._themeSurfaceRefreshTimer = nil
    end

    local function RefreshSurfaces()
        self._themeSurfaceRefreshTimer = nil
        if self.altBoardFrame and self.altBoardFrame:IsShown() and self.RefreshWarbandBoard then
            self:RefreshWarbandBoard(true)
        end
        if self.RefreshMainAltPicker then
            self:RefreshMainAltPicker()
        end
        self:RequestVisualRefresh({ mainDelay = 0, professionDelay = 0, config = false })
    end

    if self.ScheduleTimer then
        self._themeSurfaceRefreshTimer = self:ScheduleTimer(RefreshSurfaces, 0.06)
    else
        RefreshSurfaces()
    end
end

function MR:ApplyThemeColorSelection()
    local themeColor = self:GetThemeColor()
    self._appliedThemeColor = themeColor
    if ns.ApplyThemeAccentColor then
        ns.ApplyThemeAccentColor(themeColor)
    end
    if ns.ApplyTitleBarTheme then
        ns.ApplyTitleBarTheme(themeColor)
    end
    if self.RefreshImmediateThemeSurfaces then
        self:RefreshImmediateThemeSurfaces()
    end
    self:RequestThemeSurfaceRefresh()
end

function MR:SetThemeColor(hexColor)
    self.db.profile.themeColor = hexColor or nil
    self.db.profile.themeColorMode = hexColor and "custom" or "default"
    self:ApplyThemeColorSelection()
end

function MR:ClearHeaderColorOverrides()
    local profile = self.db and self.db.profile
    if not profile then return end

    profile.headerColors = profile.headerColors or {}
    profile.headerBackgroundColors = profile.headerBackgroundColors or {}
    for _, mod in ipairs(self.modules or {}) do
        if mod.key then
            profile.headerColors[mod.key] = nil
            profile.headerBackgroundColors[mod.key] = nil
        end
    end
end

function MR:SetThemeColorToClassColor()
    if not self:GetClassColorHex() then
        return
    end
    self:ClearHeaderColorOverrides()
    self.db.profile.themeColor = nil
    self.db.profile.themeColorMode = "class"
    self:ApplyThemeColorSelection()
end

function MR:ResetThemeColor()
    self:ClearHeaderColorOverrides()
    self:SetThemeColor(nil)
end

function MR:IsThemeColorClassColor()
    return self.db and self.db.profile and self.db.profile.themeColorMode == "class"
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
    modKey = GetRowSettingModuleKey(self, modKey, rowKey, "colorModuleKey")
    local p = self.db.profile.rowColors
    if p and p[modKey] and p[modKey][rowKey] then
        return p[modKey][rowKey]
    end
end

function MR:SetRowColor(modKey, rowKey, hexColor)
    modKey = GetRowSettingModuleKey(self, modKey, rowKey, "colorModuleKey")
    if not self.db.profile.rowColors then self.db.profile.rowColors = {} end
    if not self.db.profile.rowColors[modKey] then self.db.profile.rowColors[modKey] = {} end
    self.db.profile.rowColors[modKey][rowKey] = hexColor
    self:RequestVisualRefresh()
end

function MR:ResetRowColor(modKey, rowKey)
    modKey = GetRowSettingModuleKey(self, modKey, rowKey, "colorModuleKey")
    local p = self.db.profile.rowColors
    if p and p[modKey] then
        p[modKey][rowKey] = nil
    end
    self:RequestVisualRefresh()
end

