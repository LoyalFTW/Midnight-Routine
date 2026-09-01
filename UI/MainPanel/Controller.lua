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

local function GetModuleWindowTitle(mod)
    local cleanLabel = mod.label:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
    return cleanLabel
end

local function ApplyWidth(newW)
    newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, math.floor(newW)))
    MR.db.profile.width = newW
    if MR.frame then MR.frame:SetWidth(newW) end
    if MR.RequestUIRefresh then
        MR:RequestUIRefresh(0.02)
    else
        MR:RefreshUI()
    end
end
MR.ApplyWidth = ApplyWidth

local function ApplyHeight(newH)
    newH = math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, math.floor(newH)))
    MR.db.profile.height = newH
    if MR.frame then MR.frame:SetHeight(newH) end
    if MR.RequestUIRefresh then
        MR:RequestUIRefresh(0.02)
    else
        MR:RefreshUI()
    end
end
MR.ApplyHeight = ApplyHeight

local function ApplyFontSize(newSize)
    newSize = math.max(FONT_SIZE_MIN, math.min(FONT_SIZE_MAX, math.floor(newSize)))
    if MR.db and MR.db.profile and MR.db.profile.syncWindowFontSize == true and MR.ApplyFontSizeToAll then
        MR:ApplyFontSizeToAll(newSize)
        return
    end

    MR.db.profile.fontSize = newSize
    RecalcLayout()
    if MR.ApplySharedMediaSettings then
        MR:ApplySharedMediaSettings()
    else
        if MR.RequestUIRefresh then
            MR:RequestUIRefresh(0.02)
        else
            MR:RefreshUI()
        end
    end
end
MR.ApplyFontSize = ApplyFontSize

GetWindowLayoutValue = function(key)
    if MR and MR.GetWindowLayoutValue then
        return MR:GetWindowLayoutValue(key)
    end

    if not (MR and MR.db and key) then return nil end

    if MR.db.profile and MR.db.profile.characterWindowLayout == true then
        local charLayout = MR.db.char and MR.db.char.windowLayout
        if charLayout and charLayout[key] ~= nil then
            return charLayout[key]
        end
    end

    return MR.db.profile and MR.db.profile[key]
end

SetWindowLayoutValue = function(key, value)
    if MR and MR.SetWindowLayoutValue then
        MR:SetWindowLayoutValue(key, value)
        return
    end

    if not (MR and MR.db and key) then return end

    if MR.db.profile and MR.db.profile.characterWindowLayout == true then
        if not MR.db.char.windowLayout then
            MR.db.char.windowLayout = {}
        end
        MR.db.char.windowLayout[key] = value
        return
    end

    MR.db.profile[key] = value
end

local function GetMainHeaderPosition()
    if GetWindowLayoutValue and GetWindowLayoutValue("mainHeaderPosition") == "bottom" then
        return "bottom"
    end

    return "top"
end

local function IsAnimatedMinimizeEnabled()
    if GetWindowLayoutValue then
        return GetWindowLayoutValue("animatedMinimize") == true
    end

    return false
end

function MR:GetManagedHeaderPosition()
    return GetMainHeaderPosition()
end

function MR:IsManagedAnimatedMinimizeEnabled()
    return IsAnimatedMinimizeEnabled()
end

local function IsMainHeaderAtBottom()
    return GetMainHeaderPosition() == "bottom"
end

local function GetMainFrameExpandedHeight()
    return math.max(PANEL_MIN_HEIGHT, math.min(MR.db.profile.height or 400, PANEL_MAX_HEIGHT))
end

local function GetMainFrameCollapsedHeight()
    return GetMainHeaderHeight()
end

local function GetStoredMainFrameCollapsedAnchor()
    local pos = GetWindowLayoutValue("collapsedPosition")
    if pos and pos.point then
        return pos
    end

    return GetWindowLayoutValue("position")
end

local function SetStoredMainFrameCollapsedAnchor(pos)
    if not pos or not pos.point then
        return
    end

    SetWindowLayoutValue("collapsedPosition", {
        point = pos.point,
        relPoint = pos.relPoint or pos.point,
        x = pos.x or 0,
        y = pos.y or 0,
    })
end

local function GetStoredMainFrameActiveAnchor()
    if MR and MR.db and MR.db.profile and MR.db.profile.minimized then
        return GetStoredMainFrameCollapsedAnchor()
    end

    return GetWindowLayoutValue("position")
end

local function SetStoredMainFrameActiveAnchor(pos)
    if not pos or not pos.point then
        return
    end

    if MR and MR.db and MR.db.profile and MR.db.profile.minimized then
        SetStoredMainFrameCollapsedAnchor(pos)
    else
        SetWindowLayoutValue("position", {
            point = pos.point,
            relPoint = pos.relPoint or pos.point,
            x = pos.x or 0,
            y = pos.y or 0,
        })
    end
end

local function CaptureMainFrameAnchor(frame, anchorMode)
    return CaptureManagedFrameAnchor(frame, anchorMode, GetStoredMainFrameActiveAnchor())
end

local function ApplyMainFrameAnchor(frame, anchorMode, preserveScreenPosition)
    if not frame then
        return
    end

    if MR and MR._mainFrameDragging then
        return
    end

    local pos = preserveScreenPosition and CaptureMainFrameAnchor(frame, anchorMode) or GetStoredMainFrameActiveAnchor()
    if not pos or not pos.point then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
        return
    end

    ApplyManagedFrameAnchor(frame, pos)
    SetStoredMainFrameActiveAnchor(pos)
end

local function ApplyExplicitMainFrameAnchor(frame, pos)
    if not frame or not pos or not pos.point then
        return
    end

    ApplyManagedFrameAnchor(frame, pos)
end

local function GetBottomHeaderCollapseTarget(frame)
    local movedSinceExpand = MR and MR._mainFrameMovedSinceExpand == true
    local anchor

    if movedSinceExpand then
        anchor = CaptureMainFrameAnchor(frame, "bottom")
    else
        anchor = (MR and MR._mainCollapsedAnchorBeforeExpand) or GetStoredMainFrameCollapsedAnchor()
    end

    if not (anchor and anchor.point) then
        anchor = CaptureMainFrameAnchor(frame, "bottom")
    end

    if anchor and anchor.point then
        SetStoredMainFrameCollapsedAnchor(anchor)
    end

    if MR then
        MR._mainCollapsedAnchorBeforeExpand = nil
        MR._mainFrameMovedSinceExpand = false
    end

    return anchor
end

local function IsMainCombatDisabled()
    return MR and MR.IsCombatUpdatesDisabled and MR:IsCombatUpdatesDisabled()
end

local function ApplyMainFrameLayout(frame, preserveScreenPosition)
    if not frame then
        return
    end

    local titleBar = MR and MR._titleBar
    local scrollBg = MR and MR._scrollBg
    local scroll = MR and MR.scroll
    local track = MR and MR._scrollTrack
    local dragger = MR and MR._dragger
    local characterBar = MR and MR._characterBar
    local headerHeight = titleBar and titleBar:GetHeight() or GetMainHeaderHeight()
    local characterBarHeight = GetMainCharacterBarHeight()
    local chromeHeight = headerHeight + characterBarHeight
    local headerBottom = IsMainHeaderAtBottom()
    local minimized = MR and MR.db and MR.db.profile and MR.db.profile.minimized == true
    local combatDisabled = IsMainCombatDisabled()

    if titleBar then
        titleBar:ClearAllPoints()
        if headerBottom then
            titleBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
            titleBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        else
            titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        end
    end

    if characterBar then
        characterBar:ClearAllPoints()
        characterBar:SetHeight(math.max(1, characterBarHeight))
        characterBar:SetShown(characterBarHeight > 0 and not minimized and not combatDisabled)
        if headerBottom then
            characterBar:SetPoint("BOTTOMLEFT", titleBar, "TOPLEFT", 0, 0)
            characterBar:SetPoint("BOTTOMRIGHT", titleBar, "TOPRIGHT", 0, 0)
        else
            characterBar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
            characterBar:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, 0)
        end
    end

    if scrollBg then
        scrollBg:ClearAllPoints()
        scrollBg:SetShown(not minimized and not combatDisabled)
        if headerBottom then
            scrollBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            scrollBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, chromeHeight)
        else
            scrollBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -chromeHeight)
            scrollBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        end
    end

    if scroll then
        scroll:ClearAllPoints()
        scroll:SetShown(not minimized and not combatDisabled)
        if headerBottom then
            scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
            scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -9, chromeHeight + 6)
        else
            scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(chromeHeight + 6))
            scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -9, 4)
        end
    end

    if track and scroll then
        track:SetShown(not minimized and not combatDisabled)
        track:ClearAllPoints()
        track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 1, 0)
        track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    end

    if dragger then
        dragger:ClearAllPoints()
        dragger:SetShown(not minimized and not combatDisabled)
        if headerBottom then
            dragger:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
        else
            dragger:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        end
    end

    if minimized then
        frame:SetHeight(GetMainFrameCollapsedHeight())
    end
    if MR and MR._combatDisabledFrame then
        MR._combatDisabledFrame:SetShown(combatDisabled and not minimized)
    end
    if MR and MR.titleCount then
        MR.titleCount:SetShown(not combatDisabled)
    end
    ApplyMainFrameAnchor(frame, GetMainHeaderPosition(), preserveScreenPosition == true)
end

ns.GetMainHeaderPosition     = GetMainHeaderPosition
ns.IsAnimatedMinimizeEnabled = IsAnimatedMinimizeEnabled
ns.ApplyMainFrameLayout      = ApplyMainFrameLayout

local function SetMainFrameChromeVisible(visible)
    visible = visible and not IsMainCombatDisabled()
    if MR.scroll then MR.scroll:SetShown(visible) end
    if MR._scrollBg then MR._scrollBg:SetShown(visible) end
    if MR._scrollTrack then MR._scrollTrack:SetShown(visible) end
    if MR._characterBar then
        MR._characterBar:SetShown(visible and MR.db and MR.db.profile and MR.db.profile.showMainCharacterBar ~= false)
    end
    if MR._dragger then
        MR._dragger:SetShown(visible and not (MR.db and MR.db.profile and MR.db.profile.minimized))
    end
end

local mainFrameAnimator = CreateFrame("Frame")
mainFrameAnimator:Hide()

local function StopMainFrameAnimation()
    mainFrameAnimator:SetScript("OnUpdate", nil)
    mainFrameAnimator:Hide()
end

local function AnimateMainFrameHeight(targetHeight, onFinished)
    local frame = MR and MR.frame
    if not frame then
        if onFinished then onFinished() end
        return
    end

    local startHeight = frame:GetHeight() or targetHeight
    local delta = targetHeight - startHeight
    if math.abs(delta) < 1 then
        frame:SetHeight(targetHeight)
        if onFinished then onFinished() end
        return
    end

    StopMainFrameAnimation()
    mainFrameAnimator:Show()
    AnimateManagedFrameHeight(frame, targetHeight, function()
        StopMainFrameAnimation()
        if onFinished then onFinished() end
    end, nil, mainFrameAnimator)
end

function MR:BuildUI()
    RefreshFonts()
    if self.frame then self.frame:Show() return end

    RecalcLayout()
    local w = MR.db.profile.width or 260
    local h = MR.db.profile.minimized and GetMainFrameCollapsedHeight() or (MR.db.profile.height or 400)

    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetWidth(w)
    f:SetHeight(h)
    self:RegisterPriorityFrame(f)
    f:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(f) end
    f:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4])
    f:SetBackdropBorderColor(0.15, 0.15, 0.2, 1)
    f:SetMovable(true)
    f:SetClampedToScreen(true)

    RestoreManagedFramePos(f, nil, 0, 0, GetStoredMainFrameActiveAnchor())
    f:SetScale(MR.db.profile.scale or 1)
    self.frame = f
    f:SetScript("OnShow", function()
        if MR._tickFrame then MR._tickFrame:Show() end
        if MR.ActivateVisibleTrackingSurface and MR:ActivateVisibleTrackingSurface() then
            MR:RequestUIRefresh(0.08)
        elseif MR._refreshUIDirty or MR._mainPanelNeedsRefresh then
            MR:RefreshUI()
        end
    end)
    f:SetScript("OnHide", function()
        if MR._tickFrame and not MR:HasVisibleMainTrackingSurface() then
            MR._tickFrame:Hide()
        end
        if MR.SuspendHiddenSurfaceWork then MR:SuspendHiddenSurfaceWork() end
    end)

    local scrollBg = f:CreateTexture(nil, "BACKGROUND")
    ApplyBackgroundTexture(scrollBg, COL.bg[1], COL.bg[2], COL.bg[3], 0.96)
    MR._scrollBg = scrollBg

    local titleBar = TitleBar(f, GetMainHeaderHeight())
    MR._titleBar = titleBar
    titleBar:SetBackdropColor(0.03, 0.06, 0.12, 0.98)
    titleBar:SetBackdropBorderColor(0.17, 0.24, 0.32, 1)
    titleBar:SetScript("OnDragStart", function()
        if not MR.db.profile.locked then
            MR._mainFrameDragging = true
            f:StartMoving()
        end
    end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local pos = CaptureMainFrameAnchor(f, GetMainHeaderPosition())
        if pos then
            SetStoredMainFrameActiveAnchor(pos)
            if (not MR.db.profile.minimized) and IsMainHeaderAtBottom() then
                MR._mainFrameMovedSinceExpand = true
            end
        end
        MR._mainFrameDragging = false
    end)
    if MR.ApplyPanelHeaderAutoHide then MR:ApplyPanelHeaderAutoHide(f, titleBar) end

    local titleAccent = titleBar:CreateTexture(nil, "ARTWORK")
    MR._titleAccent = titleAccent
    titleAccent:SetPoint("TOPLEFT",    titleBar, "TOPLEFT",    0, 0)
    titleAccent:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    titleAccent:SetWidth(0)
    titleAccent:SetColorTexture(0.92, 0.72, 0.20, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(ns.FONT_HEADERS, math.max(8, GetFontSize() - 2), GetFontFlags())
    title:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
    title:SetPoint("RIGHT", titleBar, "RIGHT", -110, 0)
    title:SetJustifyH("LEFT")
    title:SetText(L["Title"])
    self.titleText = title

    local titleCount = titleBar:CreateFontString(nil, "OVERLAY")
    titleCount:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    titleCount:SetTextColor(0.84, 0.88, 0.90)
    self.titleCount = titleCount

    local BTN_SIZE   = 20
    local BTN_PAD    = 4
    local BTN_MARGIN = 8

    local function MakeHeaderBtn(icon, normalColor, hoverBg, hoverBorder, tooltipText, tooltipSub)
        return ns.HeaderButton(titleBar, {
            size = BTN_SIZE,
            texture = icon.tex,
            text = icon.text,
            iconSize = icon.tex and (BTN_SIZE - 6) or nil,
            fontSize = 11,
            color = normalColor,
            hoverColor = { 1, 1, 1 },
            hoverBackground = { hoverBg[1], hoverBg[2], hoverBg[3], 1 },
            hoverBorder = { hoverBorder[1], hoverBorder[2], hoverBorder[3], 1 },
            tooltip = tooltipText,
            tooltipSub = tooltipSub,
        })
    end

    local closeBtn = MakeHeaderBtn(
        { text = "x" },
        {0.88, 0.56, 0.56},
        {0.28, 0.10, 0.10},
        {0.90, 0.25, 0.25},
        L["Close"],
        L["UI_HideAddon"]
    )
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -BTN_MARGIN, 0)
    closeBtn:SetScript("OnClick", function()
        MR:HideMainPanel(true)
    end)
    self.closeBtn = closeBtn

    local minBtn = MakeHeaderBtn(
        { text = "-" },
        {0.80, 0.84, 0.88},
        {0.10, 0.17, 0.24},
        {0.32, 0.58, 0.72},
        L["Minimize"],
        L["UI_CollapseHint"]
    )
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -BTN_PAD, 0)
    self.minBtn = minBtn

    local function UpdateMinimizeVisual()
        minBtn._lbl:SetText(MR.db.profile.minimized and "+" or "-")
    end
    UpdateMinimizeVisual()
    self.UpdateMinimizeVisual = UpdateMinimizeVisual

    local function ApplyMinimizeState()
        local collapsed = MR.db.profile.minimized == true
        local targetHeight = collapsed and GetMainFrameCollapsedHeight() or GetMainFrameExpandedHeight()
        local useAnimation = IsAnimatedMinimizeEnabled()
        ApplyMainFrameLayout(f, true)
        if collapsed then
            if MR._dragger then MR._dragger:Hide() end
        else
            SetMainFrameChromeVisible(true)
        end

        local function finalize()
            if collapsed then
                SetMainFrameChromeVisible(false)
            else
                SetMainFrameChromeVisible(true)
            end
            UpdateMinimizeVisual()
        end

        if useAnimation then
            AnimateMainFrameHeight(targetHeight, finalize)
        else
            StopMainFrameAnimation()
            f:SetHeight(targetHeight)
            finalize()
        end
    end
    self.ApplyMinimizeState = ApplyMinimizeState

    minBtn:SetScript("OnClick", function()
        MR.db.profile.minimized = not MR.db.profile.minimized
        if MR.db.profile.minimized and MR.HideCurrencyBrowserFrame then
            MR:HideCurrencyBrowserFrame()
        end
        ApplyMinimizeState()
    end)

    local cfgBtn = MakeHeaderBtn(
        { tex = "Interface\\Buttons\\UI-OptionsButton" },
        {0.92, 0.76, 0.24},
        {0.18, 0.14, 0.05},
        {0.98, 0.82, 0.24},
        L["Options"],
        L["UI_ChatHint"]
    )
    cfgBtn:SetPoint("RIGHT", minBtn, "LEFT", -BTN_PAD, 0)
    cfgBtn:SetScript("OnClick", function()
        MR:ToggleConfig()
        MR:DismissFirstTimeGlow()
    end)

    local origCfgEnter = cfgBtn:GetScript("OnEnter")
    cfgBtn:SetScript("OnEnter", function(s)
        origCfgEnter(s)
        if MR.db and not MR.db.profile.firstSeen then
            ns.AddTooltipLines(s, function(tooltip)
                tooltip:AddLine(L["Options_Glow"], 1, 1, 1)
                tooltip:AddLine(L["UI_ModularHint"], 0.9, 0.85, 0.3)
            end)
        end
    end)

    local cfgShine = CreateFrame("Frame", nil, cfgBtn)
    cfgShine:SetSize(28, 28)
    cfgShine:SetPoint("CENTER", cfgBtn, "CENTER", 0, 0)
    cfgShine:Hide()
    local function MakeSparkle(parent, x, y)
        local t = parent:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\ItemSocketingFrame\\UI-ItemSockingFrame-Glow")
        t:SetSize(10, 10)
        t:SetPoint("CENTER", parent, "CENTER", x, y)
        t:SetBlendMode("ADD")
        return t
    end
    cfgShine._sparks = {
        MakeSparkle(cfgShine, -9,  9),
        MakeSparkle(cfgShine,  9,  9),
        MakeSparkle(cfgShine, -9, -9),
        MakeSparkle(cfgShine,  9, -9),
    }
    local elapsed = 0
    cfgShine:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        local alpha = 0.5 + 0.5 * math.sin(elapsed * 4)
        for _, s in ipairs(self._sparks) do s:SetAlpha(alpha) end
    end)
    cfgShine.Play = function(self) self:Show() end
    cfgShine.Stop = function(self) self:Hide() end
    self.cfgShine = cfgShine

    self.cfgBtn = cfgBtn

    local warbandBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    warbandBtn:SetSize(50, BTN_SIZE)
    warbandBtn:SetPoint("RIGHT", cfgBtn, "LEFT", -BTN_PAD, 0)
    warbandBtn:SetBackdrop(MakeBackdrop())
    warbandBtn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
    warbandBtn:SetBackdropBorderColor(0.24, 0.31, 0.38, 0.95)
    local warbandGlow = warbandBtn:CreateTexture(nil, "BACKGROUND")
    warbandGlow:SetPoint("TOPLEFT")
    warbandGlow:SetPoint("BOTTOMRIGHT")
    warbandGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    warbandGlow:SetColorTexture(0.15, 0.42, 0.45, 0.14)
    local warbandText = warbandBtn:CreateFontString(nil, "OVERLAY")
    warbandText:SetFont(ns.FONT_HEADERS, 9, GetFontFlags())
    warbandText:SetPoint("CENTER", warbandBtn, "CENTER", 0, 1)
    warbandText:SetText(L["AltBoard_ButtonLabel"] or "ALTS")
    warbandText:SetTextColor(0.84, 0.92, 0.96)
    self.warbandBtnText = warbandText
    warbandBtn:SetScript("OnEnter", function(selfBtn)
        selfBtn:SetBackdropColor(0.11, 0.17, 0.24, 1)
        selfBtn:SetBackdropBorderColor(0.42, 0.62, 0.76, 1)
        warbandText:SetTextColor(1, 1, 1)
        ns.ShowTooltip(selfBtn, {
            anchor = "ANCHOR_BOTTOM",
            build = function(tooltip)
                tooltip:SetText(L["AltBoard_OpenTooltip"] or "Open Alt Weekly Board", 1, 1, 1)
                tooltip:AddLine(L["AltBoard_OpenTooltipSub"] or "Browse every tracked alt and see exactly what is done, in progress, or untouched this week.", 0.6, 0.85, 0.85, true)
            end,
        })
    end)
    warbandBtn:SetScript("OnLeave", function(selfBtn)
        selfBtn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
        selfBtn:SetBackdropBorderColor(0.24, 0.31, 0.38, 0.95)
        warbandText:SetTextColor(0.84, 0.92, 0.96)
        ns.HideOwnedTooltip(selfBtn)
    end)
    warbandBtn:SetScript("OnClick", function()
        MR:ToggleWarbandBoard()
    end)
    self.warbandBtn = warbandBtn

    local characterBar = CreateFrame("Button", nil, f, "BackdropTemplate")
    characterBar:SetHeight(GetMainCharacterBarHeight())
    characterBar:SetBackdrop(MakeBackdrop())
    characterBar:SetBackdropColor(0.020, 0.040, 0.060, 0.96)
    characterBar:SetBackdropBorderColor(0.08, 0.16, 0.22, 0.45)
    characterBar:SetFrameLevel(f:GetFrameLevel() + 2)
    MR._characterBar = characterBar

    local characterAccent = characterBar:CreateTexture(nil, "ARTWORK")
    characterAccent:SetTexture("Interface\\Buttons\\WHITE8X8")
    characterAccent:SetPoint("BOTTOMLEFT", characterBar, "BOTTOMLEFT", 1, 0)
    characterAccent:SetPoint("BOTTOMRIGHT", characterBar, "BOTTOMRIGHT", -1, 0)
    characterAccent:SetHeight(1)
    characterAccent:SetColorTexture(0.18, 0.78, 0.72, 0.38)

    local characterIconPlate = CreateFrame("Frame", nil, characterBar, "BackdropTemplate")
    characterIconPlate:SetSize(16, 16)
    characterIconPlate:SetPoint("LEFT", characterBar, "LEFT", 7, 0)
    characterIconPlate:SetBackdrop(MakeBackdrop())
    characterIconPlate:SetBackdropColor(0.005, 0.012, 0.020, 0.86)
    characterIconPlate:SetBackdropBorderColor(0.12, 0.24, 0.30, 0.70)

    local characterIcon = characterIconPlate:CreateTexture(nil, "ARTWORK")
    characterIcon:SetPoint("TOPLEFT", characterIconPlate, "TOPLEFT", 2, -2)
    characterIcon:SetPoint("BOTTOMRIGHT", characterIconPlate, "BOTTOMRIGHT", -2, 2)
    characterIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")

    local characterName = characterBar:CreateFontString(nil, "OVERLAY")
    characterName:SetFont(ns.FONT_HEADERS, math.max(9, GetFontSize() - 2), GetFontFlags())
    characterName:SetPoint("LEFT", characterIconPlate, "RIGHT", 6, 0)
    characterName:SetJustifyH("LEFT")
    characterName:SetWordWrap(false)

    local characterRealm = characterBar:CreateFontString(nil, "OVERLAY")
    characterRealm:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 3), GetFontFlags())
    characterRealm:SetPoint("LEFT", characterName, "RIGHT", 5, 0)
    characterRealm:SetPoint("RIGHT", characterBar, "RIGHT", -28, 0)
    characterRealm:SetJustifyH("LEFT")
    characterRealm:SetWordWrap(false)
    characterRealm:SetTextColor(0.42, 0.60, 0.64)

    local characterCaret = characterBar:CreateFontString(nil, "OVERLAY")
    characterCaret:SetFont(ns.FONT_HEADERS, 9, GetFontFlags())
    characterCaret:SetPoint("RIGHT", characterBar, "RIGHT", -9, 1)
    characterCaret:SetText("v")
    characterCaret:SetTextColor(0.48, 0.72, 0.74)

    local function UpdateCharacterBar()
        local altInfo = MR.GetMainAltViewCharacterInfo and MR:GetMainAltViewCharacterInfo() or nil
        local name = altInfo and altInfo.name or (UnitName and UnitName("player")) or (L["Unknown"] or "Unknown")
        local realm = altInfo and altInfo.realm or (GetRealmName and GetRealmName()) or ""
        local classFile = altInfo and altInfo.data and altInfo.data.classFile or select(2, UnitClass("player"))
        local classColor = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile] or nil
        local cr, cg, cb = 0.18, 0.78, 0.72
        if classColor then
            cr, cg, cb = classColor.r, classColor.g, classColor.b
        end
        characterName:SetText(name)
        characterName:SetTextColor(cr, cg, cb)
        characterName:SetWidth(math.min(math.max(characterName:GetStringWidth() + 2, 20), math.max((characterBar:GetWidth() or 260) - 120, 50)))
        characterRealm:SetText(realm ~= "" and ("|cff789094-|r " .. realm) or "")
        characterAccent:SetColorTexture(cr, cg, cb, 0.38)
        characterIconPlate:SetBackdropBorderColor(cr * 0.45, cg * 0.45, cb * 0.45, 0.72)
        local coords = classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classFile] or nil
        if coords then
            characterIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
            characterIcon:Show()
        else
            characterIcon:Hide()
        end
    end
    self.UpdateMainCharacterBar = UpdateCharacterBar

    characterBar:SetScript("OnClick", function()
        if MR.ToggleMainAltPicker then
            MR:ToggleMainAltPicker()
        end
    end)
    characterBar:SetScript("OnEnter", function(selfBtn)
        selfBtn:SetBackdropColor(0.030, 0.060, 0.082, 1)
        selfBtn:SetBackdropBorderColor(0.14, 0.34, 0.40, 0.82)
        characterCaret:SetTextColor(1, 1, 1)
        ns.ShowTooltip(selfBtn, {
            build = function(tooltip)
                tooltip:SetText(L["AltPicker_OpenTooltip"] or "Open Alt Picker", 1, 1, 1)
                tooltip:AddLine(L["AltPicker_OpenTooltipSub"] or "Pick an alt to show its saved progress in the main frame.", 0.6, 0.85, 0.85, true)
            end,
        })
    end)
    characterBar:SetScript("OnLeave", function(selfBtn)
        selfBtn:SetBackdropColor(0.020, 0.040, 0.060, 0.96)
        selfBtn:SetBackdropBorderColor(0.08, 0.16, 0.22, 0.45)
        characterCaret:SetTextColor(0.48, 0.72, 0.74)
        ns.HideOwnedTooltip(selfBtn)
    end)
    self.characterBar = characterBar

    titleCount:SetPoint("RIGHT", warbandBtn, "LEFT", -6, 0)
    title:ClearAllPoints()
    title:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
    title:SetPoint("RIGHT", titleCount, "LEFT", -8, 0)
    title:SetJustifyH("LEFT")

    local function RefreshMainHeaderChrome()
        local metrics = GetMainHeaderMetrics()
        titleBar:SetHeight(metrics.headerHeight)
        closeBtn:SetSize(metrics.buttonSize, metrics.buttonSize)
        minBtn:SetSize(metrics.buttonSize, metrics.buttonSize)
        cfgBtn:SetSize(metrics.buttonSize, metrics.buttonSize)
        warbandBtn:SetSize(metrics.warbandWidth, metrics.buttonSize)
        characterBar:SetHeight(math.max(1, GetMainCharacterBarHeight()))
        characterIconPlate:SetSize(math.max(14, metrics.fontSize + 5), math.max(14, metrics.fontSize + 5))
        characterName:SetFont(ns.FONT_HEADERS, math.max(9, metrics.fontSize - 2), GetFontFlags())
        characterRealm:SetFont(ns.FONT_ROWS, math.max(8, metrics.fontSize - 3), GetFontFlags())
        if cfgBtn._iconTex then
            cfgBtn._iconTex:SetSize(metrics.buttonSize - 5, metrics.buttonSize - 5)
        end
        if closeBtn._lbl then
            closeBtn._lbl:SetFont(ns.FONT_HEADERS, math.max(8, metrics.fontSize - 1), GetFontFlags())
        end
        if minBtn._lbl then
            minBtn._lbl:SetFont(ns.FONT_HEADERS, math.max(8, metrics.fontSize - 1), GetFontFlags())
        end
        title:SetFont(ns.FONT_HEADERS, math.max(8, metrics.fontSize - 2), GetFontFlags())
        titleCount:SetFont(ns.FONT_ROWS, math.max(8, metrics.fontSize - 2), GetFontFlags())
        warbandText:SetFont(ns.FONT_HEADERS, math.max(8, metrics.fontSize - 2), GetFontFlags())
        UpdateCharacterBar()
        ApplyMainFrameLayout(f)
    end
    self.RefreshMainHeaderChrome = RefreshMainHeaderChrome
    RefreshMainHeaderChrome()

    local scroll = CreateFrame("ScrollFrame", nil, f)
    self.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize((MR.db.profile.width or 260) - 9, 1)
    self.content = content

    local track = CreateFrame("Frame", nil, f)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 1, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    track:SetWidth(5)
    self._scrollTrack = track
    self.UpdateScrollBar = ns.AttachScrollList(scroll, content, track, {
        thumbColor = { 0.25, 0.65, 0.65, 0.75 },
        onScroll = function()
            if MR.RefreshMainPanelViewport then
                MR:RefreshMainPanelViewport()
            end
        end,
    })

    local combatDisabledFrame = CreateFrame("Frame", nil, f)
    combatDisabledFrame:SetAllPoints(scroll)
    combatDisabledFrame:SetFrameLevel(f:GetFrameLevel() + 12)
    combatDisabledFrame:Hide()
    self._combatDisabledFrame = combatDisabledFrame

    local combatDisabledText = combatDisabledFrame:CreateFontString(nil, "OVERLAY")
    combatDisabledText:SetFont(ns.FONT_HEADERS, math.max(10, GetFontSize()), GetFontFlags())
    combatDisabledText:SetPoint("CENTER", combatDisabledFrame, "CENTER", 0, 0)
    combatDisabledText:SetText(L["Combat_Disabled"] or "Disabled during combat")
    combatDisabledText:SetTextColor(0.92, 0.48, 0.38)
    self._combatDisabledText = combatDisabledText

    self.widgets         = {}
    self.sectionRegistry = {}

    local dragger = CreateFrame("Frame", nil, f)
    dragger:SetSize(12, 12)
    dragger:SetFrameLevel(f:GetFrameLevel() + 10)
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
    local resizeLayoutElapsed = 0
    local function FinishMainFrameResize()
        if not dragger._dragging then
            return
        end
        dragger._dragging = false
        dragger:SetScript("OnUpdate", nil)
        resizeLayoutElapsed = 0
        local newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, math.floor(f:GetWidth())))
        local newH = math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, math.floor(f:GetHeight())))
        MR.db.profile.width = newW
        MR.db.profile.height = newH
        f:SetWidth(newW)
        f:SetHeight(newH)
        MR:RefreshUI()
        local configFrame = MR.GetConfigFrame and MR:GetConfigFrame()
        if configFrame and configFrame:IsShown() then
            MR:PopulateConfigFrame(configFrame)
        end
    end
    local function ResizeMainFrame(_, elapsed)
        if not dragger._dragging then
            dragger:SetScript("OnUpdate", nil)
            return
        end
        if not IsMouseButtonDown("LeftButton") then
            FinishMainFrameResize()
            return
        end
        local cx, cy = GetCursorPosition()
        local scale = f:GetEffectiveScale()
        cx = cx / scale
        cy = cy / scale
        local dx = cx - dragStartX
        local dy = dragStartY - cy
        local newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, dragStartW + dx))
        local newH = math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, dragStartH + dy))
        f:SetWidth(newW)
        f:SetHeight(newH)
        resizeLayoutElapsed = resizeLayoutElapsed + (elapsed or 0)
        if resizeLayoutElapsed >= 0.04 then
            resizeLayoutElapsed = 0
            MR.db.profile.width = math.floor(newW)
            MR.db.profile.height = math.floor(newH)
            if MR.RefreshMainPanelSectionsOnly then
                MR:RefreshMainPanelSectionsOnly()
            elseif MR.UpdateScrollBar then
                MR.UpdateScrollBar()
            end
        elseif MR.UpdateScrollBar then
            MR.UpdateScrollBar()
        end
    end
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not MR.db.profile.locked then
            dragStartW = f:GetWidth()
            dragStartH = f:GetHeight()
            dragStartX, dragStartY = GetCursorPosition()
            local scale = f:GetEffectiveScale()
            dragStartX = dragStartX / scale
            dragStartY = dragStartY / scale
            resizeLayoutElapsed = 0
            dragger._dragging = true
            dragger:SetScript("OnUpdate", ResizeMainFrame)
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            FinishMainFrameResize()
        end
    end)
    self._dragger = dragger

    self._timerRows = {}
    local tickFrame = CreateFrame("Frame")
    local function UpdateTimerRows()
        MR._timerRowTickCount = (MR._timerRowTickCount or 0) + 1
        local hasActiveTimer
        for _, f in ipairs(MR._timerRows) do
            if f:IsShown() and f._timerUpdate then
                hasActiveTimer = true
                f._timerUpdate()
            end
        end
        if not hasActiveTimer and MR._timerRowsTicker then
            MR._timerRowsTicker:Cancel()
            MR._timerRowsTicker = nil
        end
    end
    local function StartTimerRowTicker()
        if MR._timerRowsTicker or not (MR._timerRows and #MR._timerRows > 0) then return end
        MR._timerRowsTicker = C_Timer.NewTicker(1, UpdateTimerRows)
    end
    local function StopTimerRowTicker()
        if MR._timerRowsTicker then
            MR._timerRowsTicker:Cancel()
            MR._timerRowsTicker = nil
        end
    end
    local function UpdateTimerRowTicker()
        if MR:HasVisibleMainTrackingSurface() and MR._timerRows and #MR._timerRows > 0 then
            StartTimerRowTicker()
        else
            StopTimerRowTicker()
        end
    end
    self.UpdateTimerRowTicker = UpdateTimerRowTicker
    tickFrame:SetScript("OnShow", UpdateTimerRowTicker)
    tickFrame:SetScript("OnHide", StopTimerRowTicker)
    self._tickFrame = tickFrame
    tickFrame:SetShown(self:HasVisibleMainTrackingSurface())
    if tickFrame:IsShown() then UpdateTimerRowTicker() end

    ApplyMainFrameLayout(f)
    if self.ActivateVisibleTrackingSurface then
        self:ActivateVisibleTrackingSurface()
    end
    self:UpdateCombatDisplayState()
    self:RefreshUI()
    ApplyTheme()
end

function MR:UpdateCombatDisplayState()
    if not self.frame then
        return
    end

    ApplyMainFrameLayout(self.frame)
    if self._tickFrame then
        self._tickFrame:SetShown(not IsMainCombatDisabled() and self:HasVisibleMainTrackingSurface())
    end
end

local function HasVisibleUISurface(self)
    if self.frame and self.frame:IsShown() then
        return true
    end
    if self.altBoardFrame and self.altBoardFrame:IsShown() then
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

function MR:RefreshUI()
    if self.NoteRefreshSource then
        self:NoteRefreshSource("RefreshUI")
    end
    self._refreshUIAttemptCount = (self._refreshUIAttemptCount or 0) + 1

    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self._refreshUIDirty = true
        return
    end

    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("refreshUI") then
        self._refreshUIDirty = true
        return
    end

    if not self:CanRefreshUIImmediately() then
        self._refreshUIDirty = true
        return
    end

    if not HasVisibleUISurface(self) then
        self._refreshUIDirty = true
        self._mainPanelNeedsRefresh = true
        return
    end

    local now = GetTime and GetTime() or 0
    local minRefreshInterval = 0.15

    if self._refreshUIInProgress then
        self._refreshUIPending = true
        return
    end

    if self._lastRefreshUIAt and (now - self._lastRefreshUIAt) < minRefreshInterval then
        self._refreshUIPending = true
        if not self._refreshUITimer then
            local delay = math.max(minRefreshInterval - (now - self._lastRefreshUIAt), 0.01)
            self._refreshUITimer = self:ScheduleTimer(function()
                self._refreshUITimer = nil
                if self._refreshUIPending then
                    self._refreshUIPending = nil
                    self:RefreshUI()
                end
            end, delay)
        end
        return
    end

    local profiling = self._scrollProfileArmed and debugprofilestop
    local profileStarted = profiling and debugprofilestop() or nil
    local statsElapsed = 0
    local mainElapsed = 0
    local createdBefore = self._mainRowWidgetCreatedCount or 0
    local optionalBefore = self._mainRowOptionalPartCreatedCount or 0

    self._refreshUIInProgress = true
    self._refreshUIDirty = nil
    self._refreshUICount = (self._refreshUICount or 0) + 1

    RecalcLayout()
    local statsStarted = profiling and debugprofilestop() or nil
    self._moduleStatsCache = BuildModuleStatsCache(self)
    if statsStarted then statsElapsed = debugprofilestop() - statsStarted end
    local expansionInfo = ns.GetExpansionDisplayInfo(false)
    local refreshMain = self.frame and self.frame:IsShown()
    local mainStarted = profiling and refreshMain and debugprofilestop() or nil

    if not refreshMain then
        self._mainPanelNeedsRefresh = true
    end

    if refreshMain then
        self._mainPanelNeedsRefresh = nil
        self._mainMaterializedTop = nil
        self._mainMaterializedBottom = nil

        if self.titleText then
            self.titleText:SetText(L["Title"] or "Routine")
        end
        if self.UpdateMainCharacterBar then
            self:UpdateMainCharacterBar()
        end
        if self.expansionDropdown and self.expansionDropdown.Update then
            self.expansionDropdown:Update()
        end
        ApplyMainFrameLayout(self.frame)
        self.widgets = self.widgets or {}
        self.sectionRegistry = self.sectionRegistry or {}
        self._timerRows = self._timerRows or {}
        ClearArrayContents(self.widgets)
        ClearArrayContents(self.sectionRegistry)
        ClearArrayContents(self._timerRows)
        self._sectionRegistryCount = 0

        local allDone, allTotal = 0, 0

        local frameW   = MR.db.profile.width or 260
        local usableW  = frameW - 9
        local MIN_COL  = 200
        local numCols  = math.max(1, math.floor(usableW / MIN_COL))
        local colW     = math.floor(usableW / numCols)

        local visibleMods = self._visibleModsBuffer or {}
        self._visibleModsBuffer = visibleMods
        local visibleModCount = 0
        local lastVisibleExpansionKey
        for _, mod in ipairs(MR:GetOrderedModules("all")) do
            local modVisible = not mod.isVisible or mod:isVisible()
            if MR:IsModuleEnabled(mod.key) and modVisible and not MR:IsModuleDetached(mod.key) and not (MR.ShouldHideProfessionModuleInMain and MR:ShouldHideProfessionModuleInMain(mod)) then
                local stats = GetModuleStats(self, mod)
                local totalRows = stats and stats.totalRows or 0
                local doneRows = stats and stats.doneRows or 0
                local shownRows = stats and stats.shownRows or 0
                if shownRows > 0 then
                    local h = stats and stats.height or 0
                    local expansionKey = MR:GetModuleExpansionKey(mod)
                    if mod.profSkillLine and expansionKey ~= lastVisibleExpansionKey then
                        lastVisibleExpansionKey = expansionKey
                        visibleModCount = visibleModCount + 1
                        local headerEntry = visibleMods[visibleModCount] or {}
                        headerEntry.mod = nil
                        headerEntry.expansionKey = expansionKey
                        headerEntry.expansionHeaderKey = nil
                        headerEntry.h = 22
                        visibleMods[visibleModCount] = headerEntry
                    end
                    local expansionCollapsed = mod.profSkillLine and MR.db.profile.collapsedProfessionExpansions and MR.db.profile.collapsedProfessionExpansions[expansionKey] == true
                    if not expansionCollapsed then
                        visibleModCount = visibleModCount + 1
                        local slot = visibleModCount
                        local entry = visibleMods[slot] or {}
                        entry.mod = mod
                        entry.expansionKey = nil
                        entry.expansionHeaderKey = nil
                        entry.h = h
                        visibleMods[slot] = entry
                    end
                    allTotal = allTotal + shownRows
                    allDone = allDone + math.min(doneRows, shownRows)
                end
            end
        end

        local cols = self._colsBuffer or {}
        self._colsBuffer = cols
        for i = 1, numCols do
            cols[i] = 0
        end
        for i = numCols + 1, #cols do
            cols[i] = nil
        end

        local totalModH = 0
        for i = 1, visibleModCount do
            totalModH = totalModH + visibleMods[i].h
        end

        local modColAssign = self._modColAssignBuffer or {}
        self._modColAssignBuffer = modColAssign
        local modColAssignCount = 0
        local curCol = 1
        local targetColH = math.max(totalModH / numCols, 1)
        for i = 1, visibleModCount do
            local entry = visibleMods[i]
            local projectedH = entry.h or 0
            if entry.expansionKey and visibleMods[i + 1] then
                projectedH = projectedH + (visibleMods[i + 1].h or 0)
            end
            if curCol < numCols and cols[curCol] > 0 and (cols[curCol] + projectedH) > targetColH then
                curCol = curCol + 1
            end
            modColAssignCount = modColAssignCount + 1
            local slot = modColAssignCount
            local assign = modColAssign[slot] or {}
            assign.mod = entry.mod
            assign.expansionKey = entry.expansionKey
            assign.expansionHeaderKey = entry.expansionHeaderKey
            assign.col = curCol
            assign.yOff = cols[curCol]
            modColAssign[slot] = assign
            cols[curCol] = cols[curCol] + entry.h
        end
        self._modColAssignCount = modColAssignCount
        self._mainPanelColumnWidth = colW

        local activeMainSections = self._activeMainSectionsBuffer or {}
        self._activeMainSectionsBuffer = activeMainSections
        for key in pairs(activeMainSections) do
            activeMainSections[key] = nil
        end
        for i = 1, modColAssignCount do
            local mod = modColAssign[i].mod
            if mod then activeMainSections[mod.key] = true end
        end
        if self._mainSectionFrames then
            for key, section in pairs(self._mainSectionFrames) do
                if not activeMainSections[key] then
                    HideMainSectionWidget(section)
                end
            end
        end
        for i = 1, modColAssignCount do
            local assign = modColAssign[i]
            local xOff = (assign.col - 1) * colW
            if assign.mod then
                local section = UpdateMainSectionWidget(self, assign.mod, assign.yOff, xOff, colW, assign.col, nil, assign.expansionHeaderKey)
                if section then
                    activeMainSections[assign.mod.key] = true
                    table.insert(self.widgets, section)
                end
            elseif assign.expansionKey then
                local header = UpdateMainExpansionHeaderWidget(self, assign.expansionKey, assign.yOff, xOff, colW)
                table.insert(self.widgets, header)
            end
        end

        if self._mainExpansionHeaderFrames then
            for _, header in pairs(self._mainExpansionHeaderFrames) do
                local key = header._expansionKey
                local active = false
                for i = 1, modColAssignCount do
                    if modColAssign[i].expansionKey == key then
                        active = true
                        break
                    end
                end
                if not active then
                    HideMainExpansionHeaderWidget(header)
                end
            end
        end

        for c = 2, numCols do
            local sep = EnsureMainSeparator(self, c - 1)
            sep:SetWidth(1)
            sep:ClearAllPoints()
            sep:SetPoint("TOPLEFT",    self.content, "TOPLEFT",    (c - 1) * colW, 0)
            sep:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", (c - 1) * colW, 0)
            table.insert(self.widgets, sep)
        end
        if self._mainColumnSeparators then
            for index, sep in pairs(self._mainColumnSeparators) do
                if index > (numCols - 1) then
                    sep:Hide()
                end
            end
        end

        self.titleCount:SetText(string.format("%d / %d", allDone, allTotal))
        self.titleCount:SetTextColor(countColor(allDone, allTotal))

        local totalH = 0
        for c = 1, numCols do if cols[c] > totalH then totalH = cols[c] end end

        self.content:SetWidth(usableW)

        self.content:SetHeight(math.max(totalH, 1))
        local userH = MR.db.profile.height or 400
        if MR.db.profile.minimized then
            self.frame:SetHeight(GetMainFrameCollapsedHeight())
        else
            self.frame:SetHeight(math.max(PANEL_MIN_HEIGHT, math.min(userH, PANEL_MAX_HEIGHT)))
        end

        if self.scroll then
            local maxScroll = math.max(math.max(totalH, 1) - self.scroll:GetHeight(), 0)
            local cur = self.scroll:GetVerticalScroll()
            if cur > maxScroll then
                self.scroll:SetVerticalScroll(maxScroll)
            end
        end

        if self.UpdateScrollBar then self.UpdateScrollBar() end

        if MR.db.profile.minimized then
            StopMainFrameAnimation()
            SetMainFrameChromeVisible(false)
            self.frame:SetHeight(GetMainFrameCollapsedHeight())
            if self.UpdateMinimizeVisual then self.UpdateMinimizeVisual() end
        else
            SetMainFrameChromeVisible(true)
        end
    end
    if mainStarted then mainElapsed = debugprofilestop() - mainStarted end

    self:RefreshVisibleDetachedFrames()

    if self.UpdateTimerRowTicker then
        self:UpdateTimerRowTicker()
    end

    if self.altBoardFrame and self.altBoardFrame:IsShown() and self.RequestWarbandBoardRefresh then
        self:RequestWarbandBoardRefresh(false)
    end

    self._lastRefreshUIAt = GetTime and GetTime() or now
    self._refreshUIInProgress = nil

    if self._refreshUIPending and not self._refreshUITimer then
        self._refreshUIPending = nil
        self._refreshUITimer = self:ScheduleTimer(function()
            self._refreshUITimer = nil
            self:RefreshUI()
        end, minRefreshInterval)
    end

    if collectgarbage then
        collectgarbage("step", 160)
    end
    if profileStarted and self.CaptureScrollProfile then
        local elapsed = debugprofilestop() - profileStarted
        local created = (self._mainRowWidgetCreatedCount or 0) - createdBefore
        local optional = (self._mainRowOptionalPartCreatedCount or 0) - optionalBefore
        local detail = string.format("stats=%.1fms main=%.1fms rows=%d optional=%d", statsElapsed, mainElapsed, created, optional)
        self:CaptureScrollProfile("full refresh", elapsed, detail)
    end
end

function MR:ApplySharedMediaSettings()
    if ns.ApplySharedMedia then
        ns.ApplySharedMedia(self.GetActiveMediaSettings and self:GetActiveMediaSettings() or (self.db and self.db.profile))
    end

    RefreshFonts()
    if self.RefreshWarbandBoardFonts then
        self:RefreshWarbandBoardFonts()
    end
    local fontSize = GetFontSize()
    if self.titleText then
        self.titleText:SetFont(ns.FONT_HEADERS, math.max(8, fontSize - 2), GetFontFlags())
    end
    if self.titleCount then
        self.titleCount:SetFont(ns.FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
    end
    if self.warbandBtnText then
        self.warbandBtnText:SetFont(ns.FONT_HEADERS, 9, GetFontFlags())
    end
    if self.RefreshCustomTaskDialogThemes then
        self:RefreshCustomTaskDialogThemes()
    end
    if self.expansionDropdown and self.expansionDropdown.ApplyFonts then
        self.expansionDropdown:ApplyFonts()
    end
    if self.altBoardFrame then
        local frame = self.altBoardFrame
        if frame.titleText then
            frame.titleText:SetFont(ns.FONT_HEADERS, math.max(8, fontSize - 2), GetFontFlags())
        end
        if frame.summaryValue then
            frame.summaryValue:SetFont(ns.FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
        end
        if frame.summarySub then
            frame.summarySub:SetFont(ns.FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
        end
        if frame.leftLabel then
            frame.leftLabel:SetFont(ns.FONT_ROWS, math.max(9, fontSize), GetFontFlags())
        end
        if frame.showHiddenLabel then
            frame.showHiddenLabel:SetFont(ns.FONT_ROWS, 9, GetFontFlags())
        end
        if frame.hideCompletedLabel then
            frame.hideCompletedLabel:SetFont(ns.FONT_ROWS, 9, GetFontFlags())
        end
        if frame.heroName then
            frame.heroName:SetFont(ns.FONT_HEADERS, math.max(13, fontSize + 3), GetFontFlags())
        end
        if frame.heroMeta then
            frame.heroMeta:SetFont(ns.FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
        end
        if frame.heroStatus then
            frame.heroStatus:SetFont(ns.FONT_ROWS, math.max(10, fontSize), GetFontFlags())
        end
        if frame.expansionDropdown and frame.expansionDropdown.ApplyFonts then
            frame.expansionDropdown:ApplyFonts()
        end
    end
    ApplyTheme()
    if ns.RefreshAllFrameBackgrounds then
        ns.RefreshAllFrameBackgrounds()
    end
    if self.frame and ns.RefreshFrameBackground then
        ns.RefreshFrameBackground(self.frame)
    end
    if self._titleBar and ns.RefreshFrameBackground then
        ns.RefreshFrameBackground(self._titleBar)
    end
    if self.ApplyCurrencyBrowserTheme then
        self:ApplyCurrencyBrowserTheme()
    end
    if self.RefreshMainHeaderChrome then
        self:RefreshMainHeaderChrome()
    end
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.02)
    else
        self:RefreshUI()
    end

    if self.raresFrame and self.raresFrame.IsShown and self.raresFrame:IsShown() and self.RebuildRaresFrame then
        self:RebuildRaresFrame()
    end
    if self.RequestProfessionKnowledgeSurfaceRefresh then
        self:RequestProfessionKnowledgeSurfaceRefresh(0.04)
    elseif self.RebuildGatheringLocationsFrame then
        self:RebuildGatheringLocationsFrame()
    end
    if self.RebuildRenownFrame then self:RebuildRenownFrame() end
    if self.RepopulateRaresConfig then self:RepopulateRaresConfig() end
    if self.RepopulateGatheringConfig and not self.RequestProfessionKnowledgeSurfaceRefresh then
        self:RepopulateGatheringConfig()
    end
    if self.RepopulateRenownConfig then self:RepopulateRenownConfig() end
    if self.altBoardFrame and self.RefreshWarbandBoard then
        self:RefreshWarbandBoard()
    end
    if collectgarbage then
        collectgarbage("step", 200)
    end
end


UI.GetModuleWindowTitle = GetModuleWindowTitle
UI.ApplyWidth = ApplyWidth
UI.ApplyHeight = ApplyHeight
UI.ApplyFontSize = ApplyFontSize
UI.GetWindowLayoutValue = GetWindowLayoutValue
UI.SetWindowLayoutValue = SetWindowLayoutValue
UI.GetMainHeaderPosition = GetMainHeaderPosition
UI.IsAnimatedMinimizeEnabled = IsAnimatedMinimizeEnabled
UI.IsMainHeaderAtBottom = IsMainHeaderAtBottom
UI.GetMainFrameExpandedHeight = GetMainFrameExpandedHeight
UI.GetMainFrameCollapsedHeight = GetMainFrameCollapsedHeight
UI.GetStoredMainFrameCollapsedAnchor = GetStoredMainFrameCollapsedAnchor
UI.SetStoredMainFrameCollapsedAnchor = SetStoredMainFrameCollapsedAnchor
UI.GetStoredMainFrameActiveAnchor = GetStoredMainFrameActiveAnchor
UI.SetStoredMainFrameActiveAnchor = SetStoredMainFrameActiveAnchor
UI.CaptureMainFrameAnchor = CaptureMainFrameAnchor
UI.ApplyMainFrameAnchor = ApplyMainFrameAnchor
UI.ApplyExplicitMainFrameAnchor = ApplyExplicitMainFrameAnchor
UI.GetBottomHeaderCollapseTarget = GetBottomHeaderCollapseTarget
UI.ApplyMainFrameLayout = ApplyMainFrameLayout
UI.SetMainFrameChromeVisible = SetMainFrameChromeVisible
UI.mainFrameAnimator = mainFrameAnimator
UI.StopMainFrameAnimation = StopMainFrameAnimation
UI.AnimateMainFrameHeight = AnimateMainFrameHeight
UI.HasVisibleUISurface = HasVisibleUISurface

