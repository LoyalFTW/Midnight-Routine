local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local PANEL_MIN_WIDTH  = 200
local PANEL_MAX_WIDTH  = 500
local PANEL_MIN_HEIGHT = 100
local PANEL_MAX_HEIGHT = 800
local FONT_ROWS = ns.FONT_ROWS
local FONT_HEADERS = ns.FONT_HEADERS
local MakeBackdrop = ns.MakeBackdrop
local StyledFrame = ns.StyledFrame
local LeftAccent = ns.LeftAccent
local TitleBar = ns.TitleBar
local CloseButton = ns.CloseButton
local RestoreFramePos = ns.RestoreFramePos
local RestoreManagedFramePos = ns.RestoreManagedFramePos
local CaptureManagedFrameAnchor = ns.CaptureManagedFrameAnchor
local ApplyManagedFrameAnchor = ns.ApplyManagedFrameAnchor
local AnimateManagedFrameHeight = ns.AnimateManagedFrameHeight
local WrapColor = ns.WrapColor
local SetDotColor = ns.SetDotColor
local OptionsGap = ns.OptionsGap
local OptionsDivider = ns.OptionsDivider
local OptionsSectionLabel = ns.OptionsSectionLabel
local OptionsCheckbox = ns.OptionsCheckbox
local OptionsBtn = ns.OptionsBtn
local OptionsSlider = ns.OptionsSlider
local OptionsColorSwatch = ns.OptionsColorSwatch
local ApplyBackgroundTexture = ns.ApplyBackgroundTexture

local FONT_SIZE_MIN = 7
local FONT_SIZE_MAX = 20
local DAY_SECONDS = 24 * 60 * 60

local ROW_HEIGHT    = 18
local HEADER_HEIGHT = 18
local PADDING       = 6
local SECTION_GAP   = 6
local BuildModuleStatsCache
local GetModuleStats
local function IsMainTextOnlyMode(...)
    local UI = ns.UIInternal
    return UI and UI.IsMainTextOnlyMode and UI.IsMainTextOnlyMode(...)
end

local DIFF_BADGE_DEFS = {
    { id = 17, label = "L" },
    { id = 14, label = "N" },
    { id = 15, label = "H" },
    { id = 16, label = "M" },
}

local DIFF_BADGE_ORDER = { 17, 14, 15, 16 }

local DIFF_BADGE_COLORS = {
    [17] = { done = { 0.30, 0.60, 1.00 }, todo = { 0.08, 0.14, 0.24 }, border_done = { 0.22, 0.50, 0.90 }, border_todo = { 0.08, 0.12, 0.20 }, text_done = { 1, 1, 1 }, text_todo = { 0.22, 0.35, 0.50 } },
    [14] = { done = { 0.22, 0.72, 0.32 }, todo = { 0.06, 0.16, 0.09 }, border_done = { 0.16, 0.58, 0.26 }, border_todo = { 0.06, 0.14, 0.08 }, text_done = { 1, 1, 1 }, text_todo = { 0.18, 0.38, 0.22 } },
    [15] = { done = { 1.00, 0.52, 0.08 }, todo = { 0.26, 0.14, 0.04 }, border_done = { 0.88, 0.42, 0.06 }, border_todo = { 0.18, 0.10, 0.03 }, text_done = { 1, 1, 1 }, text_todo = { 0.48, 0.26, 0.10 } },
    [16] = { done = { 0.85, 0.18, 0.20 }, todo = { 0.24, 0.06, 0.07 }, border_done = { 0.70, 0.12, 0.14 }, border_todo = { 0.18, 0.05, 0.05 }, text_done = { 1, 1, 1 }, text_todo = { 0.46, 0.16, 0.16 } },
}

local GetWindowLayoutValue
local SetWindowLayoutValue
local countColor
local WC = WrapColor

countColor = ns.CountColor

local function GetFontSize()
    if type(ns.GetFontSize) == "function" then
        return ns.GetFontSize()
    end

    if MR and MR.db and MR.db.profile and MR.db.profile.fontSize then
        return MR.db.profile.fontSize
    end

    return 11
end

local function GetFontFlags()
    if type(ns.GetFontFlags) == "function" then
        local flags = ns.GetFontFlags(MR.GetActiveMediaSettings and MR:GetActiveMediaSettings() or (MR.db and MR.db.profile))
        if flags ~= nil then
            return flags
        end
    end

    return "OUTLINE"
end

local function GetLocaleFont()
    if type(STANDARD_TEXT_FONT) == "string" and STANDARD_TEXT_FONT ~= "" then
        return STANDARD_TEXT_FONT
    end
    if GameFontNormal and GameFontNormal.GetFont then
        local f = GameFontNormal:GetFont()
        if type(f) == "string" and f ~= "" then return f end
    end
    if ns.GetDefaultFontTexture then
        local f = ns.GetDefaultFontTexture()
        if type(f) == "string" and f ~= "" then return f end
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function RefreshFonts()
    if ns.EnsureFonts then
        FONT_HEADERS, FONT_ROWS = ns.EnsureFonts()
    end
    local loc = GetLocaleFont()
    if not FONT_ROWS    or FONT_ROWS    == "" then FONT_ROWS    = loc end
    if not FONT_HEADERS or FONT_HEADERS == "" then FONT_HEADERS = loc end

    local UI = ns.UIInternal
    if UI then
        UI.FONT_ROWS = FONT_ROWS
        UI.FONT_HEADERS = FONT_HEADERS
    end
end

local function SetFontIfChanged(fontString, fontPath, size, flags)
    if not fontString then return end
    fontPath = ns.FONT_ROWS or ns.FONT_HEADERS or fontPath
    flags = flags or ""
    if fontString._mrFontPath == fontPath
        and fontString._mrFontSize == size
        and fontString._mrFontFlags == flags then
        return
    end

    local applied = fontString:SetFont(fontPath, size, flags)
    if applied == false then
        local fallback = GetLocaleFont()
        if fallback ~= fontPath then
            applied = fontString:SetFont(fallback, size, flags)
            fontPath = fallback
        end
    end
    if applied == false then
        return false
    end
    fontString._mrFontPath = fontPath
    fontString._mrFontSize = size
    fontString._mrFontFlags = flags
    return true
end

local function SetFontForText(fontString, text, size, flags)
    if not fontString then return end
    local fontPath = ns.FONT_ROWS or FONT_ROWS
    if ns.ResolveFontForText then
        fontPath = ns.ResolveFontForText(text, fontPath)
    elseif ns.ScriptFontForText then
        fontPath = ns.ScriptFontForText(text) or fontPath
    end
    SetFontIfChanged(fontString, fontPath, size, flags)
end

local function GetMainHeaderHeight()
    return math.max(24, GetFontSize() + 11)
end

local function GetMainCharacterBarHeight()
    if not (MR and MR.db and MR.db.profile and MR.db.profile.showMainCharacterBar ~= false) then
        return 0
    end
    return math.max(22, GetFontSize() + 10)
end

local function GetMainHeaderMetrics()
    local fontSize = GetFontSize()
    local headerHeight = GetMainHeaderHeight()
    return {
        fontSize = fontSize,
        headerHeight = headerHeight,
        iconSize = math.max(14, fontSize),
        buttonSize = math.max(16, fontSize + 1),
        buttonPad = 3,
        buttonMargin = 6,
        warbandWidth = math.max(34, fontSize * 3),
    }
end

local PEEK_ALPHA_IDLE   = 0.0
local PEEK_ALPHA_HOVER  = 1.0
local PEEK_FADE_IN      = 6.0
local PEEK_FADE_OUT     = 2.5

local function PeekFrameList()
    local list = MR._peekFrameList or {}
    MR._peekFrameList = list
    for i = #list, 1, -1 do
        list[i] = nil
    end
    if MR.frame                  then list[#list+1] = MR.frame end
    if MR.raresFrame             then list[#list+1] = MR.raresFrame end
    if MR.renownFrame            then list[#list+1] = MR.renownFrame end
    if MR.gatheringLocationsFrame then list[#list+1] = MR.gatheringLocationsFrame end
    if MR.detachedFrames then
        for _, f in pairs(MR.detachedFrames) do
            list[#list+1] = f
        end
    end
    return list
end

local function AnyFrameHovered()
    for _, f in ipairs(PeekFrameList()) do
        if f:IsShown() and f:IsMouseOver() then return true end
    end
    return false
end

local function GetMovableHostFrame(frame)
    local current = frame
    while current do
        if current.IsMovable and current:IsMovable() then
            return current
        end
        current = current.GetParent and current:GetParent() or nil
    end
    return nil
end

local peekUpdater = CreateFrame("Frame")
peekUpdater:Hide()

local function StopPeekAnimation()
    peekUpdater:SetScript("OnUpdate", nil)
    peekUpdater:Hide()
end

local function StartPeekAnimation()
    if not (MR.db and MR.db.profile and MR.db.profile.peekOnHover) then return end
    peekUpdater:Show()
    peekUpdater:SetScript("OnUpdate", function(_, dt)
        local target = AnyFrameHovered() and PEEK_ALPHA_HOVER or PEEK_ALPHA_IDLE
        local rate = (target > PEEK_ALPHA_IDLE) and PEEK_FADE_IN or PEEK_FADE_OUT
        local settled = true
        for _, f in ipairs(PeekFrameList()) do
            if f:IsShown() then
                local cur = f:GetAlpha()
                if math.abs(cur - target) < 0.005 then
                    f:SetAlpha(target)
                else
                    settled = false
                    local step = rate * dt
                    if cur < target then
                        f:SetAlpha(math.min(cur + step, target))
                    else
                        f:SetAlpha(math.max(cur - step, target))
                    end
                end
            end
        end
        if settled then StopPeekAnimation() end
    end)
end

function MR:RegisterPeekFrame(frame)
    if not frame or frame._mrPeekEventsHooked then return end
    frame._mrPeekEventsHooked = true
    frame:HookScript("OnEnter", StartPeekAnimation)
    frame:HookScript("OnLeave", function()
        C_Timer.After(0, StartPeekAnimation)
    end)
    frame:HookScript("OnShow", StartPeekAnimation)
end

function MR:ApplyPeekOnHover(enable)
    self.db.profile.peekOnHover = enable

    if not enable then
        StopPeekAnimation()
        for _, f in ipairs(PeekFrameList()) do
            if f:IsShown() then f:SetAlpha(1.0) end
        end
        return
    end

    for _, frame in ipairs(PeekFrameList()) do
        self:RegisterPeekFrame(frame)
    end
    StartPeekAnimation()
end

local function RecalcLayout()
    local fs = GetFontSize()
    ROW_HEIGHT    = math.max(18, fs + 10)
    HEADER_HEIGHT = math.max(18, fs + 10)
    PADDING       = math.max(4, math.floor(fs * 0.55))
end

local hex = ns.Hex

local COL = ns.COLORS

local function ApplyTheme()
    if not MR.frame then return end
    local t = IsMainTextOnlyMode()
    local v = MR.db.profile.frameAlpha or 1.0
    local f = MR.frame
    f:SetBackdrop(MakeBackdrop())
    if MR._titleBar then
        MR._titleBar:SetBackdrop(MakeBackdrop())
    end
    if MR._characterBar then
        MR._characterBar:SetBackdrop(MakeBackdrop())
    end
    if t then
        f:SetBackdropColor(0, 0, 0, 0)
        f:SetBackdropBorderColor(0, 0, 0, 0)
        if MR._titleBar    then MR._titleBar:SetBackdropColor(0, 0, 0, 0) end
        if MR._titleBar    then MR._titleBar:SetBackdropBorderColor(0, 0, 0, 0) end
        if MR._characterBar then MR._characterBar:SetBackdropColor(0, 0, 0, 0) end
        if MR._characterBar then MR._characterBar:SetBackdropBorderColor(0, 0, 0, 0) end
        if MR._scrollBg    then ApplyBackgroundTexture(MR._scrollBg, 0, 0, 0, 0) end
        if MR._titleAccent then MR._titleAccent:SetAlpha(0) end
    else
        f:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4] * v)
        f:SetBackdropBorderColor(0.15, 0.15, 0.2, v)
        if MR._titleBar    then MR._titleBar:SetBackdropColor(0.03, 0.06, 0.12, 0.98 * v) end
        if MR._titleBar    then MR._titleBar:SetBackdropBorderColor(0.17, 0.24, 0.32, v) end
        if MR._characterBar then MR._characterBar:SetBackdropColor(0.020, 0.040, 0.060, 0.96 * v) end
        if MR._characterBar then MR._characterBar:SetBackdropBorderColor(0.08, 0.16, 0.22, 0.45 * v) end
        if MR._scrollBg    then ApplyBackgroundTexture(MR._scrollBg, COL.bg[1], COL.bg[2], COL.bg[3], 0.96 * v) end
        if MR._titleAccent then MR._titleAccent:SetAlpha(0) end
    end
end
MR.ApplyTheme = ApplyTheme

local function CleanLabelText(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end

    return text:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
end

local function ExtractInlineLabelColor(text)
    if type(text) ~= "string" then
        return nil
    end

    local hexColor = text:match("|cff(%x%x%x%x%x%x)")
    if not hexColor then
        return nil
    end

    return "#" .. hexColor
end

local function HideTooltipIfOwned(frame)
    ns.HideTooltip(frame)
end

local function MainSectionHeaderOnMouseDown(selfFrame, button)
    if selfFrame._mrDetachedHost and button == "LeftButton" then
        selfFrame._pressed = true
        selfFrame._dragged = false
        return
    end

    if button == "LeftButton" then
        selfFrame._pressed = true
    end
end

local function MainSectionHeaderOnDragStart(selfFrame)
    local host = selfFrame._mrDetachedHost
    if not host or MR.db.profile.locked then
        return
    end

    selfFrame._dragged = true
    host:StartMoving()
end

local function MainSectionHeaderOnDragStop(selfFrame)
    local host = selfFrame._mrDetachedHost
    local mod = selfFrame._mrMod
    if not host or not mod then
        return
    end

    host:StopMovingOrSizing()
    local pt, _, rp, x, y = host:GetPoint()
    MR:SetDetachedModulePosition(mod.key, pt, rp, x, y)
end

local function MainSectionHeaderOnMouseUp(selfFrame, button)
    local mod = selfFrame._mrMod
    if not mod then
        selfFrame._pressed = false
        return
    end

    if selfFrame._mrDetachedHost and button == "LeftButton" and selfFrame._dragged then
        selfFrame._pressed = false
        selfFrame._dragged = false
        return
    end

    if mod.key == "custom_tasks" and button == "RightButton" and IsShiftKeyDown() then
        if MR.ShowCustomTasksTitleDialog then
            MR:ShowCustomTasksTitleDialog()
        end
        selfFrame._pressed = false
        return
    end

    if button == "LeftButton" then
        if not selfFrame._mrDetachedHost and MR.RefreshMainPanelSectionsOnly then
            MR:SetModuleOpen(mod.key, not MR:IsModuleOpen(mod.key))
            MR:RefreshMainPanelSectionsOnly()
        elseif MR.RequestUIRefresh then
            MR:SetModuleOpen(mod.key, not MR:IsModuleOpen(mod.key))
            MR:RequestUIRefresh(0.04)
        else
            MR:SetModuleOpen(mod.key, not MR:IsModuleOpen(mod.key))
            MR:RefreshUI()
        end
    elseif button == "RightButton" then
        MR:SetModuleDetached(mod.key, not selfFrame._mrDetachedHost)
        if MR.RequestUIRefresh then
            MR:RequestUIRefresh(0.04)
        else
            MR:RefreshUI()
        end
    end

    selfFrame._pressed = false
end

local function MainSectionHeaderOnEnter(selfFrame)
    local mod = selfFrame._mrMod
    if not mod then
        return
    end

    local alpha = selfFrame._mrHoverAlpha or 0
    if selfFrame._hdrHover then
        selfFrame._hdrHover:SetColorTexture(1, 1, 1, alpha)
    end

    ns.ShowTooltip(selfFrame, {
        build = function(tooltip)
            tooltip:SetText(mod.label, 1, 1, 1)
            tooltip:AddLine(L["Tooltip_ExpandCollapse"], 0.5, 0.5, 0.5)
            tooltip:AddLine(selfFrame._mrDetachedHost and "Right-click to dock back" or "Right-click to detach", 0.5, 0.8, 1)
            if mod.key == "custom_tasks" then
                tooltip:AddLine("Shift-right-click to rename this header.", 0.85, 0.82, 0.45, true)
            end
        end,
    })
end

local function MainSectionHeaderOnLeave(selfFrame)
    if selfFrame._hdrHover then
        selfFrame._hdrHover:SetColorTexture(1, 1, 1, 0)
    end
    HideTooltipIfOwned(selfFrame)
end

local function CurrencyBrowserButtonOnClick()
    if MR.ToggleCurrencyBrowserFrame then
        MR:ToggleCurrencyBrowserFrame()
    end
end

local function CurrencyBrowserButtonOnEnter(selfBtn)
    selfBtn:SetBackdropColor(0.04, 0.24, 0.27, 1)
    selfBtn:SetBackdropBorderColor(0.20, 0.95, 0.82, 1)
    if selfBtn._label then
        selfBtn._label:SetTextColor(0.76, 1.00, 0.94, 1)
    end
    ns.ShowTooltip(selfBtn, {
        text = L["CurrencyBrowser_BrowseTooltipTitle"] or "Browse all currencies",
        build = function(tooltip)
            tooltip:SetText(L["CurrencyBrowser_BrowseTooltipTitle"] or "Browse all currencies", 1, 1, 1)
            tooltip:AddLine(L["CurrencyBrowser_BrowseTooltipText"] or "Find and add currencies that are not currently shown here.", 0.55, 0.82, 1, true)
        end,
    })
end

local function CurrencyBrowserButtonOnLeave(selfBtn)
    local alpha = selfBtn._mrTransparent and 0 or (0.94 * (selfBtn._mrFrameAlpha or 1))
    local borderAlpha = selfBtn._mrTransparent and 0 or (0.88 * (selfBtn._mrFrameAlpha or 1))
    selfBtn:SetBackdropColor(0.025, 0.12, 0.15, alpha)
    selfBtn:SetBackdropBorderColor(0.10, 0.72, 0.66, borderAlpha)
    if selfBtn._label then
        selfBtn._label:SetTextColor(0.42, 0.92, 0.84, selfBtn._mrTransparent and 0.75 or 1)
    end
    HideTooltipIfOwned(selfBtn)
end

local function StyleSectionCollapseIndicator(indicator, isOpen)
    if not indicator then return end
    isOpen = isOpen and true or false
    if not indicator._mrBaseLayoutApplied then
        indicator:ClearAllPoints()
        indicator:SetSize(14, 14)
        indicator:SetPoint("RIGHT", indicator:GetParent(), "RIGHT", -6, 0)
        indicator._mrBaseLayoutApplied = true
    end

    if not indicator._lineA then
        indicator._lineA = indicator:CreateTexture(nil, "OVERLAY")
        indicator._lineA:SetTexture("Interface\\Buttons\\WHITE8X8")
        indicator._lineB = indicator:CreateTexture(nil, "OVERLAY")
        indicator._lineB:SetTexture("Interface\\Buttons\\WHITE8X8")
    end

    local r, g, b, a = 0.50, 0.95, 0.80, 1
    indicator._lineA:SetColorTexture(r, g, b, a)
    indicator._lineB:SetColorTexture(r, g, b, a)
    if indicator._mrLayoutOpen ~= isOpen then
        indicator._lineA:ClearAllPoints()
        indicator._lineB:ClearAllPoints()

        if isOpen then
            indicator._lineA:SetSize(8, 2)
            indicator._lineB:SetSize(8, 2)
            indicator._lineA:SetPoint("CENTER", indicator, "CENTER", -2, 0)
            indicator._lineB:SetPoint("CENTER", indicator, "CENTER", 2, 0)
            if indicator._lineA.SetRotation then
                indicator._lineA:SetRotation(math.rad(35))
                indicator._lineB:SetRotation(math.rad(-35))
            end
            indicator._lineB:Show()
        else
            indicator._lineA:SetSize(10, 2)
            indicator._lineA:SetPoint("CENTER", indicator, "CENTER", 0, 0)
            if indicator._lineA.SetRotation then
                indicator._lineA:SetRotation(0)
                indicator._lineB:SetRotation(0)
            end
            indicator._lineB:Hide()
        end
        indicator._lineA:Show()
        indicator._mrLayoutOpen = isOpen
    end
end

local function StyleCurrencyBrowserButton(button, transparent, frameAlpha)
    if not button then return end
    button._mrTransparent = transparent
    button._mrFrameAlpha = frameAlpha
    if not button._mrBaseLayoutApplied then
        button:SetHeight(20)
        button._mrBaseLayoutApplied = true
    end
    button:SetBackdropColor(0.025, 0.12, 0.15, transparent and 0 or (0.94 * frameAlpha))
    button:SetBackdropBorderColor(0.10, 0.72, 0.66, transparent and 0 or (0.88 * frameAlpha))
    if button._label then
        SetFontIfChanged(button._label, FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        button._label:SetText(L["CurrencyBrowser_All"] or "Browse all currencies")
        button._label:SetTextColor(0.42, 0.92, 0.84, transparent and 0.75 or 1)
    end
    if button._icon then
        button._icon:SetVertexColor(0.34, 0.94, 0.84, transparent and 0.75 or 1)
    end
end

local function MainHeaderActionOnClick(selfBtn)
    if MR.IsMainAltViewActive and MR:IsMainAltViewActive() then
        return
    end

    local owner = selfBtn._mrOwner
    local data = owner and owner._mrData
    if data and data.row and data.row.onHeaderActionClick then
        data.row.onHeaderActionClick(data.row, data.mod, owner)
    end
end

local function MainHeaderActionOnEnter(selfBtn)
    local owner = selfBtn._mrOwner
    local data = owner and owner._mrData
    if data and data.row and data.row.headerActionTooltip and data.row.headerActionTooltip ~= "" then
        ns.ShowTooltip(selfBtn, { text = data.row.headerActionTooltip, wrap = true })
    end
end

local function MainHeaderActionOnLeave(selfBtn)
    HideTooltipIfOwned(selfBtn)
end


local UI = ns.UIInternal or {}
ns.UIInternal = UI
UI.MR = MR
UI.L = L
UI.PANEL_MIN_WIDTH = PANEL_MIN_WIDTH
UI.PANEL_MAX_WIDTH = PANEL_MAX_WIDTH
UI.PANEL_MIN_HEIGHT = PANEL_MIN_HEIGHT
UI.PANEL_MAX_HEIGHT = PANEL_MAX_HEIGHT
UI.FONT_ROWS = FONT_ROWS
UI.FONT_HEADERS = FONT_HEADERS
UI.MakeBackdrop = MakeBackdrop
UI.StyledFrame = StyledFrame
UI.LeftAccent = LeftAccent
UI.TitleBar = TitleBar
UI.CloseButton = CloseButton
UI.RestoreFramePos = RestoreFramePos
UI.RestoreManagedFramePos = RestoreManagedFramePos
UI.CaptureManagedFrameAnchor = CaptureManagedFrameAnchor
UI.ApplyManagedFrameAnchor = ApplyManagedFrameAnchor
UI.AnimateManagedFrameHeight = AnimateManagedFrameHeight
UI.WrapColor = WrapColor
UI.SetDotColor = SetDotColor
UI.OptionsGap = OptionsGap
UI.OptionsDivider = OptionsDivider
UI.OptionsSectionLabel = OptionsSectionLabel
UI.OptionsCheckbox = OptionsCheckbox
UI.OptionsBtn = OptionsBtn
UI.OptionsSlider = OptionsSlider
UI.OptionsColorSwatch = OptionsColorSwatch
UI.ApplyBackgroundTexture = ApplyBackgroundTexture
UI.FONT_SIZE_MIN = FONT_SIZE_MIN
UI.FONT_SIZE_MAX = FONT_SIZE_MAX
UI.DAY_SECONDS = DAY_SECONDS
UI.ROW_HEIGHT = ROW_HEIGHT
UI.HEADER_HEIGHT = HEADER_HEIGHT
UI.PADDING = PADDING
UI.SECTION_GAP = SECTION_GAP
UI.BuildModuleStatsCache = BuildModuleStatsCache
UI.GetModuleStats = GetModuleStats
UI.IsMainTextOnlyMode = IsMainTextOnlyMode
UI.DIFF_BADGE_DEFS = DIFF_BADGE_DEFS
UI.DIFF_BADGE_ORDER = DIFF_BADGE_ORDER
UI.DIFF_BADGE_COLORS = DIFF_BADGE_COLORS
UI.GetWindowLayoutValue = GetWindowLayoutValue
UI.SetWindowLayoutValue = SetWindowLayoutValue
UI.countColor = countColor
UI.WC = WC
UI.GetFontSize = GetFontSize
UI.GetFontFlags = GetFontFlags
UI.GetLocaleFont = GetLocaleFont
UI.RefreshFonts = RefreshFonts
UI.SetFontIfChanged = SetFontIfChanged
UI.SetFontForText = SetFontForText
UI.GetMainHeaderHeight = GetMainHeaderHeight
UI.GetMainCharacterBarHeight = GetMainCharacterBarHeight
UI.GetMainHeaderMetrics = GetMainHeaderMetrics
UI.PEEK_ALPHA_IDLE = PEEK_ALPHA_IDLE
UI.PEEK_ALPHA_HOVER = PEEK_ALPHA_HOVER
UI.PEEK_FADE_IN = PEEK_FADE_IN
UI.PEEK_FADE_OUT = PEEK_FADE_OUT
UI.PeekFrameList = PeekFrameList
UI.AnyFrameHovered = AnyFrameHovered
UI.GetMovableHostFrame = GetMovableHostFrame
UI.peekUpdater = peekUpdater
UI.StopPeekAnimation = StopPeekAnimation
UI.StartPeekAnimation = StartPeekAnimation
UI.RecalcLayout = RecalcLayout
UI.hex = hex
UI.COL = COL
UI.ApplyTheme = ApplyTheme
UI.CleanLabelText = CleanLabelText
UI.ExtractInlineLabelColor = ExtractInlineLabelColor
UI.HideTooltipIfOwned = HideTooltipIfOwned
UI.MainSectionHeaderOnMouseDown = MainSectionHeaderOnMouseDown
UI.MainSectionHeaderOnDragStart = MainSectionHeaderOnDragStart
UI.MainSectionHeaderOnDragStop = MainSectionHeaderOnDragStop
UI.MainSectionHeaderOnMouseUp = MainSectionHeaderOnMouseUp
UI.MainSectionHeaderOnEnter = MainSectionHeaderOnEnter
UI.MainSectionHeaderOnLeave = MainSectionHeaderOnLeave
UI.CurrencyBrowserButtonOnClick = CurrencyBrowserButtonOnClick
UI.CurrencyBrowserButtonOnEnter = CurrencyBrowserButtonOnEnter
UI.CurrencyBrowserButtonOnLeave = CurrencyBrowserButtonOnLeave
UI.StyleSectionCollapseIndicator = StyleSectionCollapseIndicator
UI.StyleCurrencyBrowserButton = StyleCurrencyBrowserButton
UI.MainHeaderActionOnClick = MainHeaderActionOnClick
UI.MainHeaderActionOnEnter = MainHeaderActionOnEnter
UI.MainHeaderActionOnLeave = MainHeaderActionOnLeave

