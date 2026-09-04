local _, ns = ...
local MR = ns.MR
local UI = assert(ns.UIInternal, "UI/Foundation.lua must load first")
local L = UI.L
local PANEL_MIN_WIDTH = UI.PANEL_MIN_WIDTH
local PANEL_MAX_WIDTH = UI.PANEL_MAX_WIDTH
local PANEL_MIN_HEIGHT = UI.PANEL_MIN_HEIGHT
local PANEL_MAX_HEIGHT = UI.PANEL_MAX_HEIGHT
local FONT_ROWS = UI.FONT_ROWS
local FONT_HEADERS = UI.FONT_HEADERS
local MakeBackdrop = UI.MakeBackdrop
local StyledFrame = UI.StyledFrame
local LeftAccent = UI.LeftAccent
local TitleBar = UI.TitleBar
local CloseButton = UI.CloseButton
local RestoreFramePos = UI.RestoreFramePos
local RestoreManagedFramePos = UI.RestoreManagedFramePos
local CaptureManagedFrameAnchor = UI.CaptureManagedFrameAnchor
local ApplyManagedFrameAnchor = UI.ApplyManagedFrameAnchor
local AnimateManagedFrameHeight = UI.AnimateManagedFrameHeight
local WrapColor = UI.WrapColor
local SetDotColor = UI.SetDotColor
local OptionsGap = UI.OptionsGap
local OptionsDivider = UI.OptionsDivider
local OptionsSectionLabel = UI.OptionsSectionLabel
local OptionsCheckbox = UI.OptionsCheckbox
local OptionsBtn = UI.OptionsBtn
local OptionsSlider = UI.OptionsSlider
local OptionsColorSwatch = UI.OptionsColorSwatch
local ApplyBackgroundTexture = UI.ApplyBackgroundTexture
local FONT_SIZE_MIN = UI.FONT_SIZE_MIN
local FONT_SIZE_MAX = UI.FONT_SIZE_MAX
local DAY_SECONDS = UI.DAY_SECONDS
local ROW_HEIGHT = UI.ROW_HEIGHT
local HEADER_HEIGHT = UI.HEADER_HEIGHT
local PADDING = UI.PADDING
local SECTION_GAP = UI.SECTION_GAP
local BuildModuleStatsCache = UI.BuildModuleStatsCache
local GetModuleStats = UI.GetModuleStats
local IsMainTextOnlyMode = UI.IsMainTextOnlyMode
local DIFF_BADGE_DEFS = UI.DIFF_BADGE_DEFS
local DIFF_BADGE_ORDER = UI.DIFF_BADGE_ORDER
local DIFF_BADGE_COLORS = UI.DIFF_BADGE_COLORS
local GetWindowLayoutValue = UI.GetWindowLayoutValue
local SetWindowLayoutValue = UI.SetWindowLayoutValue
local countColor = UI.countColor
local WC = UI.WC
local GetFontSize = UI.GetFontSize
local GetFontFlags = UI.GetFontFlags
local GetLocaleFont = UI.GetLocaleFont
local RefreshFonts = UI.RefreshFonts
local SetFontForText = UI.SetFontForText
local GetMainHeaderHeight = UI.GetMainHeaderHeight
local GetMainCharacterBarHeight = UI.GetMainCharacterBarHeight
local GetMainHeaderMetrics = UI.GetMainHeaderMetrics
local PEEK_ALPHA_IDLE = UI.PEEK_ALPHA_IDLE
local PEEK_ALPHA_HOVER = UI.PEEK_ALPHA_HOVER
local PEEK_FADE_IN = UI.PEEK_FADE_IN
local PEEK_FADE_OUT = UI.PEEK_FADE_OUT
local PeekFrameList = UI.PeekFrameList
local AnyFrameHovered = UI.AnyFrameHovered
local GetMovableHostFrame = UI.GetMovableHostFrame
local peekUpdater = UI.peekUpdater
local StopPeekAnimation = UI.StopPeekAnimation
local StartPeekAnimation = UI.StartPeekAnimation
local RecalcLayout = UI.RecalcLayout
local hex = UI.hex
local COL = UI.COL
local ApplyTheme = UI.ApplyTheme
local CleanLabelText = UI.CleanLabelText
local ExtractInlineLabelColor = UI.ExtractInlineLabelColor
local MainSectionHeaderOnMouseDown = UI.MainSectionHeaderOnMouseDown
local MainSectionHeaderOnDragStart = UI.MainSectionHeaderOnDragStart
local MainSectionHeaderOnDragStop = UI.MainSectionHeaderOnDragStop
local MainSectionHeaderOnMouseUp = UI.MainSectionHeaderOnMouseUp
local MainSectionHeaderOnEnter = UI.MainSectionHeaderOnEnter
local MainSectionHeaderOnLeave = UI.MainSectionHeaderOnLeave
local CurrencyBrowserButtonOnClick = UI.CurrencyBrowserButtonOnClick
local CurrencyBrowserButtonOnEnter = UI.CurrencyBrowserButtonOnEnter
local CurrencyBrowserButtonOnLeave = UI.CurrencyBrowserButtonOnLeave
local StyleSectionCollapseIndicator = UI.StyleSectionCollapseIndicator
local StyleCurrencyBrowserButton = UI.StyleCurrencyBrowserButton
local MainHeaderActionOnClick = UI.MainHeaderActionOnClick
local MainHeaderActionOnEnter = UI.MainHeaderActionOnEnter
local MainHeaderActionOnLeave = UI.MainHeaderActionOnLeave
local MainRowOnEnter = UI.MainRowOnEnter
local MainRowOnLeave = UI.MainRowOnLeave
local MainRowOnMouseDown = UI.MainRowOnMouseDown
local MainStatusButtonOnClick = UI.MainStatusButtonOnClick
local MainStatusButtonOnEnter = UI.MainStatusButtonOnEnter
local MainStatusButtonOnLeave = UI.MainStatusButtonOnLeave
local HideMainRowWidget = UI.HideMainRowWidget
local PoolMainRowWidget = UI.PoolMainRowWidget
local HideMainSectionWidget = UI.HideMainSectionWidget
local HideMainExpansionHeaderWidget = UI.HideMainExpansionHeaderWidget
local GetTextOnlyHeaderAlpha = UI.GetTextOnlyHeaderAlpha
local ShouldShowIcons = UI.ShouldShowIcons
local ShouldShowSectionHeaders = UI.ShouldShowSectionHeaders
local UIIcons = UI.UIIcons
local GetRowIconInfo = UI.GetRowIconInfo
local GetModuleIconInfo = UI.GetModuleIconInfo
local ShouldShowModuleHeaderIcon = UI.ShouldShowModuleHeaderIcon
local ApplyIconToTexture = UI.ApplyIconToTexture
local EnsureMainRowWidget = UI.EnsureMainRowWidget
local UpdateMainRowWidget = UI.UpdateMainRowWidget
local GetMainRowGroupKey = UI.GetMainRowGroupKey
local IsMainRowVisible = UI.IsMainRowVisible
local IsMainRowInGroup = UI.IsMainRowInGroup
local HasVisibleRowsInMainGroup = UI.HasVisibleRowsInMainGroup
local IsMainRowGroupEnabled = UI.IsMainRowGroupEnabled
local SetMainRowGroupEnabled = UI.SetMainRowGroupEnabled
local BuildMainRowGroupHeader = UI.BuildMainRowGroupHeader
local ShouldRenderMainRowGroupHeader = UI.ShouldRenderMainRowGroupHeader
local RenderMainGroupedRows = UI.RenderMainGroupedRows
local CountMainGroupedRows = UI.CountMainGroupedRows
local EnsureMainSeparator = UI.EnsureMainSeparator
local EnsureMainExpansionHeaderWidget = UI.EnsureMainExpansionHeaderWidget
local UpdateMainExpansionHeaderWidget = UI.UpdateMainExpansionHeaderWidget
local CreateSectionWidget = UI.CreateSectionWidget
local EnsureMainSectionWidget = UI.EnsureMainSectionWidget
local EnsureDetachedSectionWidget = UI.EnsureDetachedSectionWidget
local AddSectionRegistryEntry = UI.AddSectionRegistryEntry
local UpdateDetachedSectionWidget = UI.UpdateDetachedSectionWidget
local EnsureMainDifficultyBadges = UI.EnsureMainDifficultyBadges
local GetMainFrameProgressModule = UI.GetMainFrameProgressModule
local GetMainFrameRowCount = UI.GetMainFrameRowCount
local RegisterTimerRow = UI.RegisterTimerRow
local UpdateMainSectionWidget = UI.UpdateMainSectionWidget
local ClearArrayContents = UI.ClearArrayContents

local GetModuleWindowTitle = UI.GetModuleWindowTitle
local ApplyWidth = UI.ApplyWidth
local ApplyHeight = UI.ApplyHeight
local ApplyFontSize = UI.ApplyFontSize
local GetMainHeaderPosition = UI.GetMainHeaderPosition
local IsAnimatedMinimizeEnabled = UI.IsAnimatedMinimizeEnabled
local IsMainHeaderAtBottom = UI.IsMainHeaderAtBottom
local GetMainFrameExpandedHeight = UI.GetMainFrameExpandedHeight
local GetMainFrameCollapsedHeight = UI.GetMainFrameCollapsedHeight
local GetStoredMainFrameCollapsedAnchor = UI.GetStoredMainFrameCollapsedAnchor
local SetStoredMainFrameCollapsedAnchor = UI.SetStoredMainFrameCollapsedAnchor
local GetStoredMainFrameActiveAnchor = UI.GetStoredMainFrameActiveAnchor
local SetStoredMainFrameActiveAnchor = UI.SetStoredMainFrameActiveAnchor
local CaptureMainFrameAnchor = UI.CaptureMainFrameAnchor
local ApplyMainFrameAnchor = UI.ApplyMainFrameAnchor
local ApplyExplicitMainFrameAnchor = UI.ApplyExplicitMainFrameAnchor
local GetBottomHeaderCollapseTarget = UI.GetBottomHeaderCollapseTarget
local ApplyMainFrameLayout = UI.ApplyMainFrameLayout
local SetMainFrameChromeVisible = UI.SetMainFrameChromeVisible
local mainFrameAnimator = UI.mainFrameAnimator
local StopMainFrameAnimation = UI.StopMainFrameAnimation
local AnimateMainFrameHeight = UI.AnimateMainFrameHeight
local HasVisibleUISurface = UI.HasVisibleUISurface

function MR:HideDetachedModules()
    if not self.detachedFrames then return end
    for _, frame in pairs(self.detachedFrames) do
        frame:Hide()
    end
end

function MR:ShowDetachedModules()
    if self._instanceFramesHidden then return end
    if self:IsManagedWindowsBundleHidden() then return end
    if not self.detachedFrames then return end
    for key, frame in pairs(self.detachedFrames) do
        local mod = self.moduleByKey[key]
        local modVisible = mod and (not mod.isVisible or mod:isVisible())
        if self:IsModuleDetached(key) and self:IsModuleEnabled(key) and modVisible then
            frame:Show()
        end
    end
end

function MR:EnsureDetachedFrame(mod)
    self.detachedFrames = self.detachedFrames or {}
    local frame = self.detachedFrames[mod.key]
    if frame then return frame end

    local savedSize = self:GetDetachedModuleSize(mod.key)
    local defaultW = math.max(220, (self.db.profile.width or 260) - 20)
    local defaultH = HEADER_HEIGHT + 120
    local title = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    title:SetSize(savedSize and savedSize.width or defaultW, savedSize and savedSize.height or defaultH)
    self:RegisterPriorityFrame(title)
    title:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(title) end
    title:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4])
    title:SetBackdropBorderColor(0.15, 0.15, 0.2, 1)
    title:SetClampedToScreen(true)
    title:SetMovable(true)

    local pos = self:GetDetachedModulePosition(mod.key)
    if pos and pos.point then
        title:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    else
        title:SetPoint("CENTER", UIParent, "CENTER", 40, -40)
    end

    local dragBar = CreateFrame("Frame", nil, title, "BackdropTemplate")
    dragBar:SetPoint("TOPLEFT", title, "TOPLEFT", 0, 0)
    dragBar:SetPoint("TOPRIGHT", title, "TOPRIGHT", 0, 0)
    dragBar:SetHeight(6)
    dragBar:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(dragBar) end
    dragBar:SetBackdropColor(0.04, 0.10, 0.20, 1)
    dragBar:SetBackdropBorderColor(0.10, 0.28, 0.35, 1)
    dragBar:EnableMouse(false)

    local dragAccent = dragBar:CreateTexture(nil, "ARTWORK")
    dragAccent:SetPoint("TOPLEFT", dragBar, "TOPLEFT", 0, 0)
    dragAccent:SetPoint("BOTTOMLEFT", dragBar, "BOTTOMLEFT", 0, 0)
    dragAccent:SetWidth(3)
    dragAccent:SetColorTexture(0.16, 0.78, 0.75, 1)

    local scroll = CreateFrame("ScrollFrame", nil, title)
    scroll:SetPoint("TOPLEFT", title, "TOPLEFT", 4, -8)
    scroll:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT", -4, 4)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)
    content:SetHeight(1)
    local scrollTrack = CreateFrame("Frame", nil, title)
    scrollTrack:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 0, 0)
    scrollTrack:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 0, 0)
    scrollTrack:SetWidth(1)
    ns.AttachScrollList(scroll, content, scrollTrack, {
        showTrack = false,
        wheelStep = 24,
    })

    local dragger = CreateFrame("Frame", nil, title)
    dragger:SetSize(12, 12)
    dragger:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT", -1, 1)
    dragger:SetFrameLevel(title:GetFrameLevel() + 10)
    dragger:EnableMouse(true)

    local dTex = dragger:CreateTexture(nil, "OVERLAY")
    dTex:SetAllPoints()
    dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    dragger:SetScript("OnEnter", function()
        if not MR.db.profile.locked then
            dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        end
    end)
    dragger:SetScript("OnLeave", function()
        dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)

    local dragStartW, dragStartH, dragStartX, dragStartY
    local function ResizeDetachedFrame()
        if not dragger._dragging or not IsMouseButtonDown("LeftButton") then
            dragger._dragging = false
            dragger:SetScript("OnUpdate", nil)
            return
        end
        local cx, cy = GetCursorPosition()
        local scale = title:GetEffectiveScale()
        cx = cx / scale
        cy = cy / scale
        local dx = cx - dragStartX
        local dy = dragStartY - cy
        local newW = math.max(180, math.min(PANEL_MAX_WIDTH, dragStartW + dx))
        local newH = math.max(HEADER_HEIGHT + 48, math.min(PANEL_MAX_HEIGHT, dragStartH + dy))
        title:SetWidth(newW)
        title:SetHeight(newH)
    end
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not MR.db.profile.locked then
            dragStartW = title:GetWidth()
            dragStartH = title:GetHeight()
            dragStartX, dragStartY = GetCursorPosition()
            local scale = title:GetEffectiveScale()
            dragStartX = dragStartX / scale
            dragStartY = dragStartY / scale
            dragger._dragging = true
            dragger:SetScript("OnUpdate", ResizeDetachedFrame)
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            dragger:SetScript("OnUpdate", nil)
            local newW = math.max(180, math.min(PANEL_MAX_WIDTH, math.floor(title:GetWidth())))
            local newH = math.max(HEADER_HEIGHT + 48, math.min(PANEL_MAX_HEIGHT, math.floor(title:GetHeight())))
            title:SetWidth(newW)
            title:SetHeight(newH)
            MR:SetDetachedModuleSize(mod.key, newW, newH)
            MR:RefreshUI()
        end
    end)

    frame = title
    frame.scroll = scroll
    frame.content = content
    frame._dragBar = dragBar
    frame._dragAccent = dragAccent
    frame._dragger = dragger
    frame._widgets = {}
    frame._modKey = mod.key
    if MR.RegisterPeekFrame then MR:RegisterPeekFrame(frame) end
    frame:SetScript("OnShow", function()
        if MR._tickFrame then MR._tickFrame:Show() end
        if MR.ActivateVisibleTrackingSurface and MR:ActivateVisibleTrackingSurface() then
            MR:RequestUIRefresh(0.08)
        elseif MR._refreshUIDirty or frame._needsRefresh then
            MR:RefreshUI()
        end
    end)
    frame:SetScript("OnHide", function()
        if MR._tickFrame and not MR:HasVisibleMainTrackingSurface() then
            MR._tickFrame:Hide()
        end
        if MR.SuspendHiddenSurfaceWork then MR:SuspendHiddenSurfaceWork() end
    end)
    self.detachedFrames[mod.key] = frame
    return frame
end

function MR:HasVisibleDetachedFrames()
    if not self.detachedFrames then
        return false
    end

    for _, frame in pairs(self.detachedFrames) do
        if frame and frame:IsShown() then
            return true
        end
    end

    return false
end

function MR:CanRefreshUIImmediately()
    if self._instanceFramesHidden then
        return false
    end

    if self.frame and self.frame:IsShown() then
        return true
    end

    return self:HasVisibleDetachedFrames()
end

function MR:RefreshVisibleDetachedFrames()
    self.detachedFrames = self.detachedFrames or {}
    local seenDetached = self._seenDetachedBuffer or {}
    self._seenDetachedBuffer = seenDetached
    for key in pairs(seenDetached) do
        seenDetached[key] = nil
    end
    local allowShowing = not self._instanceFramesHidden and not self:IsManagedWindowsBundleHidden()

    for _, mod in ipairs(MR:GetOrderedMainModules()) do
        local modVisible = not mod.isVisible or mod:isVisible()
        local detached = MR:IsModuleDetached(mod.key)
        local frame = self.detachedFrames[mod.key]
        local stats = GetModuleStats(self, mod)
        local shownRows = stats and stats.shownRows or 0

        if detached and MR:IsModuleEnabled(mod.key) and modVisible and shownRows > 0 then
            frame = self:EnsureDetachedFrame(mod)
            seenDetached[mod.key] = true

            local savedSize = self:GetDetachedModuleSize(mod.key)
            local alpha = self.db.profile.frameAlpha or 1.0
            frame:SetScale(self.db.profile.scale or 1.0)
            frame:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4] * alpha)
            frame:SetBackdropBorderColor(0.15, 0.15, 0.2, alpha)
            if savedSize and savedSize.width and savedSize.height then
                frame:SetSize(savedSize.width, savedSize.height)
            end
            if frame._dragBar then
                frame._dragBar:SetBackdropColor(0.05, 0.12, 0.22, alpha)
                frame._dragBar:SetBackdropBorderColor(0.10, 0.28, 0.35, alpha)
            end
            if frame._dragAccent then
                frame._dragAccent:SetAlpha(alpha)
            end

            local shouldRefreshFrame = allowShowing or frame:IsShown()
            if shouldRefreshFrame then
                local scrollWidth = frame.scroll and frame.scroll:GetWidth() or (frame:GetWidth() - 8)
                frame.content:SetWidth(math.max(scrollWidth, 1))
                local section = UpdateDetachedSectionWidget(self, frame, mod, math.max(scrollWidth, 1))
                local sectionHeight = section and section:GetHeight() or HEADER_HEIGHT
                frame.content:SetHeight(math.max(sectionHeight, 1))
                if frame.scroll then
                    local maxScroll = math.max(frame.content:GetHeight() - frame.scroll:GetHeight(), 0)
                    if frame.scroll:GetVerticalScroll() > maxScroll then
                        frame.scroll:SetVerticalScroll(maxScroll)
                    end
                end
                if not MR:IsModuleOpen(mod.key) then
                    frame:SetHeight(HEADER_HEIGHT + 12)
                elseif not (savedSize and savedSize.height) then
                    frame:SetHeight(math.max(sectionHeight + 12, HEADER_HEIGHT + 48))
                end
                frame._needsRefresh = nil
            else
                frame._needsRefresh = true
            end

            if allowShowing then
                frame:Show()
            else
                frame:Hide()
            end
        elseif frame then
            frame._needsRefresh = true
            if frame._sectionFrames then
                for _, section in pairs(frame._sectionFrames) do
                    HideMainSectionWidget(section)
                end
            end
            frame:Hide()
        end
    end

    for key, frame in pairs(self.detachedFrames) do
        if not seenDetached[key] then
            frame._needsRefresh = true
            if frame._sectionFrames then
                for _, section in pairs(frame._sectionFrames) do
                    HideMainSectionWidget(section)
                end
            end
            frame:Hide()
        end
    end
end

