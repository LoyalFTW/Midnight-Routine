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
local IsMainTextOnlyMode

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
end

local function SetFontForText(fontString, text, size, flags)
    if not fontString then return end
    local fontPath = FONT_ROWS
    if ns.ResolveFontForText then
        fontPath = ns.ResolveFontForText(text, FONT_ROWS)
    elseif ns.ScriptFontForText then
        fontPath = ns.ScriptFontForText(text) or FONT_ROWS
    end
    fontString:SetFont(fontPath, size, flags)
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
    local list = {}
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

function MR:ApplyPeekOnHover(enable)
    self.db.profile.peekOnHover = enable

    if not enable then
        peekUpdater:SetScript("OnUpdate", nil)
        peekUpdater:Hide()
        for _, f in ipairs(PeekFrameList()) do
            if f:IsShown() then f:SetAlpha(1.0) end
        end
        return
    end

    peekUpdater:Show()
    peekUpdater:SetScript("OnUpdate", function(_, dt)
        local target = AnyFrameHovered() and PEEK_ALPHA_HOVER or PEEK_ALPHA_IDLE
        local rate   = (target > PEEK_ALPHA_IDLE) and PEEK_FADE_IN or PEEK_FADE_OUT
        for _, f in ipairs(PeekFrameList()) do
            if f:IsShown() then
                local cur = f:GetAlpha()
                if math.abs(cur - target) < 0.005 then
                    f:SetAlpha(target)
                else
                    local step = rate * dt
                    if cur < target then
                        f:SetAlpha(math.min(cur + step, target))
                    else
                        f:SetAlpha(math.max(cur - step, target))
                    end
                end
            end
        end
    end)
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
    if GameTooltip and GameTooltip:IsOwned(frame) then
        GameTooltip:Hide()
    end
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
        if not selfFrame._mrDetachedHost and MR.FastToggleMainSection and MR:FastToggleMainSection(mod.key) then
        elseif not selfFrame._mrDetachedHost and MR.RefreshMainPanelSectionsOnly then
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

    GameTooltip:SetOwner(selfFrame, "ANCHOR_RIGHT")
    GameTooltip:SetText(mod.label, 1, 1, 1)
    GameTooltip:AddLine(L["Tooltip_ExpandCollapse"], 0.5, 0.5, 0.5)
    GameTooltip:AddLine(selfFrame._mrDetachedHost and "Right-click to dock back" or "Right-click to detach", 0.5, 0.8, 1)
    if mod.key == "custom_tasks" then
        GameTooltip:AddLine("Shift-right-click to rename this header.", 0.85, 0.82, 0.45, true)
    end
    GameTooltip:Show()
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
    selfBtn:SetBackdropColor(0.07, 0.18, 0.24, 1)
    selfBtn:SetBackdropBorderColor(0.30, 0.80, 0.78, 1)
    if selfBtn._label then
        selfBtn._label:SetTextColor(0.65, 1.00, 0.92, 1)
    end
    GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
    GameTooltip:SetText("Show all Blizzard currencies", 1, 1, 1)
    GameTooltip:AddLine("Opens a side window populated from the currency API.", 0.55, 0.82, 1, true)
    GameTooltip:Show()
end

local function CurrencyBrowserButtonOnLeave(selfBtn)
    local alpha = selfBtn._mrTransparent and 0 or (0.90 * (selfBtn._mrFrameAlpha or 1))
    local borderAlpha = selfBtn._mrTransparent and 0 or (0.70 * (selfBtn._mrFrameAlpha or 1))
    selfBtn:SetBackdropColor(0.04, 0.09, 0.14, alpha)
    selfBtn:SetBackdropBorderColor(0.14, 0.34, 0.42, borderAlpha)
    if selfBtn._label then
        selfBtn._label:SetTextColor(0.42, 0.82, 0.82, selfBtn._mrTransparent and 0.75 or 1)
    end
    HideTooltipIfOwned(selfBtn)
end

local function StyleSectionCollapseIndicator(indicator, isOpen)
    if not indicator then return end
    indicator:ClearAllPoints()
    indicator:SetSize(14, 14)
    indicator:SetPoint("RIGHT", indicator:GetParent(), "RIGHT", -6, 0)

    if not indicator._lineA then
        indicator._lineA = indicator:CreateTexture(nil, "OVERLAY")
        indicator._lineA:SetTexture("Interface\\Buttons\\WHITE8X8")
        indicator._lineB = indicator:CreateTexture(nil, "OVERLAY")
        indicator._lineB:SetTexture("Interface\\Buttons\\WHITE8X8")
    end

    local r, g, b, a = 0.50, 0.95, 0.80, 1
    indicator._lineA:SetColorTexture(r, g, b, a)
    indicator._lineB:SetColorTexture(r, g, b, a)
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
end

local function StyleCurrencyBrowserButton(button, transparent, frameAlpha)
    if not button then return end
    button._mrTransparent = transparent
    button._mrFrameAlpha = frameAlpha
    button:SetSize(24, 14)
    button:SetBackdropColor(0.04, 0.09, 0.14, transparent and 0 or (0.90 * frameAlpha))
    button:SetBackdropBorderColor(0.14, 0.34, 0.42, transparent and 0 or (0.70 * frameAlpha))
    if button._label then
        button._label:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 3), GetFontFlags())
        button._label:SetText(L["CurrencyBrowser_All"] or "ALL")
        button._label:SetTextColor(0.42, 0.82, 0.82, transparent and 0.75 or 1)
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
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText(data.row.headerActionTooltip, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end
end

local function MainHeaderActionOnLeave(selfBtn)
    HideTooltipIfOwned(selfBtn)
end

local function MainRowOnEnter(selfRow)
    local data = selfRow._mrData
    if not data then
        return
    end

    if data.mode == "sectionHeader" then
        if data.row.note then
            GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
            GameTooltip:SetText(data.row.label, 1, 1, 1)
            GameTooltip:AddLine(data.row.note, 0.70, 0.70, 0.76, true)
            GameTooltip:Show()
        end
        return
    end

    if data.mode == "collapsed" then
        GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Tooltip_DonePrefix"] .. data.row.label, 0.4, 0.85, 0.4, 1, true)
        GameTooltip:AddLine(L["Tooltip_CompletedWeek"], 0.3, 0.6, 0.3)
        GameTooltip:Show()
        return
    end

    if selfRow._hover then
        selfRow._hover:SetColorTexture(1, 1, 1, data.transparent and 0 or (0.04 * data.frameAlpha))
    end

    local row = data.row
    GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
    if row.currencyId and not row.noBlizzardTooltip then
        GameTooltip:SetCurrencyByID(row.currencyId)
        GameTooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
        if row.tooltipFunc then
            row.tooltipFunc(GameTooltip)
        end
    elseif row.itemId and not row.noBlizzardTooltip then
        if GameTooltip.SetItemByID then
            GameTooltip:SetItemByID(row.itemId)
        else
            GameTooltip:SetHyperlink("item:" .. row.itemId)
        end
        GameTooltip:AddLine(L["Tooltip_AutoItem"], 0.9, 0.6, 1)
    else
        GameTooltip:SetText(row.label, 1, 1, 1, 1, true)
        if row.note then
            GameTooltip:AddLine(row.note, 0.7, 0.7, 0.7, true)
        end
        if data.hasWaypoint then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(string.format(L["Gathering_Coords"], row.x, row.y), 0.7, 1, 0.9)
            GameTooltip:AddLine(L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
        end
        if row.tooltipFunc then
            row.tooltipFunc(GameTooltip)
        end
        if row.noDefaultTooltipHint then
        elseif row.liveKey or row.autoTracked or (row.currencyId and row.noBlizzardTooltip) then
            GameTooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
        elseif row.questIds then
            GameTooltip:AddLine(L["Tooltip_AutoQuest"], 0.4, 1, 0.6)
        elseif row.spellId or row.itemId then
            GameTooltip:AddLine(L["Tooltip_AutoItem"], 0.9, 0.6, 1)
        elseif not data.hasWaypoint then
            GameTooltip:AddLine(L["Tooltip_ManualClick"], 0.5, 0.5, 0.5)
        end
    end
    GameTooltip:Show()
end

local function MainRowOnLeave(selfRow)
    if selfRow._hover then
        selfRow._hover:SetColorTexture(1, 1, 1, 0)
    end
    HideTooltipIfOwned(selfRow)
end

local function MainRowOnMouseDown(selfRow, button)
    local data = selfRow._mrData
    if not data or data.mode ~= "normal" then
        return
    end

    if MR.IsMainAltViewActive and MR:IsMainAltViewActive() then
        return
    end

    local row = data.row
    local mod = data.mod
    local done = data.done

    if button == "LeftButton" and row.onLeftClick then
        local handled = row.onLeftClick(row, mod, done, selfRow)
        if handled ~= false then
            return
        end
    elseif button == "RightButton" and row.onRightClick then
        local handled = row.onRightClick(row, mod, done, selfRow)
        if handled ~= false then
            return
        end
    end

    if button == "LeftButton" and data.hasWaypoint then
        local ok, source = MR:SetWaypoint(row)
        if ok then
            print(string.format(L["Waypoint_Set"], source, row.waypointTitle or row.label, row.x, row.y))
        else
            print(L["Waypoint_Unavailable"])
        end
    elseif not data.isAutoTracked and not row.encounterIds and button == "LeftButton" then
        MR:BumpProgress(mod.key, row.key, 1, row.max)
    elseif not data.isAutoTracked and not row.encounterIds and button == "RightButton" then
        MR:BumpProgress(mod.key, row.key, -1, row.max)
    end
end

local function MainStatusButtonOnClick(selfBtn)
    local owner = selfBtn._mrOwner
    local data = owner and owner._mrData
    if not data or data.mode ~= "normal" then
        return
    end

    if MR.IsMainAltViewActive and MR:IsMainAltViewActive() then
        return
    end

    local row = data.row
    local mod = data.mod
    if mod.key == "custom_tasks" and IsShiftKeyDown() and row.onLeftClick then
        local handled = row.onLeftClick(row, mod, data.done, owner)
        if handled ~= false then
            return
        end
    end

    if row.toggleStatus and MR.ToggleCustomTask and mod.key == "custom_tasks" then
        local rowKey = row.key or ""
        local scope = row.taskScope or (rowKey:match("^shared_task_") and "shared" or "character")
        local taskId = tonumber(rowKey:match("^shared_task_(%d+)") or rowKey:match("^task_(%d+)"))
        MR:ToggleCustomTask(taskId, scope)
        return
    end


    if row.encounterIds then return end

    local cur = MR:GetManualOverride(mod.key, row.key)
    MR:SetManualOverride(mod.key, row.key, cur >= row.max and 0 or row.max, row.max)
end

local function MainStatusButtonOnEnter(selfBtn)
    local owner = selfBtn._mrOwner
    local data = owner and owner._mrData
    if not data or data.mode ~= "normal" then
        return
    end

    if owner._hover then
        owner._hover:SetColorTexture(1, 1, 1, data.transparent and 0 or (0.04 * data.frameAlpha))
    end

    local row = data.row
    local mo = row.toggleStatus and MR:GetProgress(data.mod.key, row.key) or MR:GetManualOverride(data.mod.key, row.key)
    GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
    GameTooltip:SetText(row.label, 1, 1, 1, 1, true)
    if row.note then
        GameTooltip:AddLine(row.note, 0.7, 0.7, 0.7, true)
    end
    GameTooltip:AddLine(" ")
    if mo >= row.max then
        GameTooltip:AddLine(L["Tooltip_ManualDot_Active"], 1, 0.85, 0.1, true)
    else
        GameTooltip:AddLine(L["Tooltip_ManualDot_Hint"], 0.7, 0.7, 0.7, true)
    end
    GameTooltip:Show()
end

local function MainStatusButtonOnLeave(selfBtn)
    local owner = selfBtn._mrOwner
    if owner and owner._hover then
        owner._hover:SetColorTexture(1, 1, 1, 0)
    end
    HideTooltipIfOwned(selfBtn)
end

local function HideMainRowWidget(rowFrame)
    if not rowFrame then
        return
    end

    HideTooltipIfOwned(rowFrame)
    if rowFrame._headerActionButton then
        HideTooltipIfOwned(rowFrame._headerActionButton)
    end
    if rowFrame._statusBtn then
        HideTooltipIfOwned(rowFrame._statusBtn)
    end
    rowFrame._mrData = nil
    rowFrame._timerUpdate = nil
    rowFrame:Hide()
end

local function HideMainSectionWidget(section)
    if not section then
        return
    end

    if section._hdrFrame then
        HideTooltipIfOwned(section._hdrFrame)
    end
    if section._rows then
        for _, rowFrame in pairs(section._rows) do
            HideMainRowWidget(rowFrame)
        end
    end
    section:Hide()
end

local function HideMainExpansionHeaderWidget(frame)
    if frame then
        frame:Hide()
    end
end

local GetTextOnlyHeaderAlpha
local ShouldShowIcons
local ShouldShowSectionHeaders
local NormalizeIconInfo
local GetRowIconInfo
local GetModuleIconInfo
local ShouldShowModuleHeaderIcon
local GetModuleFallbackIconInfo
local ApplyIconToTexture
local EnsureMainRowWidget
local UpdateMainRowWidget

local function GetMainRowGroupKey(row)
    local group = row and row.group
    if group then
        return group
    end
    return nil
end

local function GetVisibleRowsByGroup(mod, rows)
    local rowsByGroup = {}
    for _, row in ipairs(rows or {}) do
        local group = GetMainRowGroupKey(row)
        if group then
            local rowVisible = MR.IsRowVisibleForCharacter and MR:IsRowVisibleForCharacter(mod, row) or (not row.isVisible or row.isVisible())
            if rowVisible then
                rowsByGroup[group] = rowsByGroup[group] or {}
                rowsByGroup[group][#rowsByGroup[group] + 1] = row
            end
        end
    end
    return rowsByGroup
end

local function BuildMainRowGroupHeader(mod, group, groupRows)
    local visible = MR:IsRowGroupEnabled(mod.key, groupRows)
    local label = (ns.GetRowGroupLabel and ns.GetRowGroupLabel(group)) or tostring(group)
    return {
        key = "__group_" .. tostring(group),
        label = label,
        control = true,
        sectionHeader = true,
        hideStatus = true,
        noDefaultTooltipHint = true,
        headerActionStyle = "visibility",
        headerActionVisible = visible,
        onHeaderActionClick = function()
            MR:SetRowGroupEnabled(mod.key, groupRows, not MR:IsRowGroupEnabled(mod.key, groupRows))
        end,
    }
end

local function ShouldRenderMainRowGroupHeader(self, mod, groupRows, hideComplete)
    if not MR:IsRowGroupEnabled(mod.key, groupRows) then
        return true
    end

    for _, row in ipairs(groupRows or {}) do
        if MR:IsRowEnabled(mod.key, row.key) then
            local done = MR:GetProgress(mod.key, row.key)
            local rowComplete = self:IsRowComplete(mod, row, done)
            if row.control or not (hideComplete and rowComplete) then
                return true
            end
        end
    end

    return false
end

local function RenderMainGroupedRows(self, card, mod, rows, hideComplete, yOff, colW, usedRows, buildRowFunc)
    local rowsByGroup = GetVisibleRowsByGroup(mod, rows)
    local lastGroup
    for _, row in ipairs(rows or {}) do
        local rowVisible = MR.IsRowVisibleForCharacter and MR:IsRowVisibleForCharacter(mod, row) or (not row.isVisible or row.isVisible())
        local group = GetMainRowGroupKey(row)
        if rowVisible and group and group ~= lastGroup and rowsByGroup[group] and ShouldRenderMainRowGroupHeader(self, mod, rowsByGroup[group], hideComplete) then
            local header = BuildMainRowGroupHeader(mod, group, rowsByGroup[group])
            local rowFrame, nextY, rowId = buildRowFunc(header, 0, yOff)
            yOff = nextY
            if usedRows then usedRows[rowId] = true end
        end
        lastGroup = group

        if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
            local done = MR:GetProgress(mod.key, row.key)
            local rowComplete = self:IsRowComplete(mod, row, done)
            if row.control or not (hideComplete and rowComplete) then
                local rowFrame, nextY, rowId = buildRowFunc(row, done, yOff)
                yOff = nextY
                if usedRows then usedRows[rowId] = true end
            end
        end
    end
    return yOff
end

local function EnsureMainSeparator(self, index)
    self._mainColumnSeparators = self._mainColumnSeparators or {}
    local sep = self._mainColumnSeparators[index]
    if sep then
        sep:SetParent(self.content)
        sep:Show()
        return sep
    end

    sep = CreateFrame("Frame", nil, self.content)
    sep._tex = sep:CreateTexture(nil, "ARTWORK")
    sep._tex:SetAllPoints()
    sep._tex:SetColorTexture(1, 1, 1, 0.08)
    self._mainColumnSeparators[index] = sep
    return sep
end

local function EnsureMainExpansionHeaderWidget(self, expansionKey)
    self._mainExpansionHeaderFrames = self._mainExpansionHeaderFrames or {}
    local key = "__expansion_" .. tostring(expansionKey or "midnight")
    local frame = self._mainExpansionHeaderFrames[key]
    if frame then
        frame:SetParent(self.content)
        frame:Show()
        return frame
    end

    frame = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
    frame._label = frame:CreateFontString(nil, "OVERLAY")
    frame._label:SetJustifyH("LEFT")
    self._mainExpansionHeaderFrames[key] = frame
    return frame
end

local function UpdateMainExpansionHeaderWidget(self, expansionKey, yOff, xOff, colW)
    local frame = EnsureMainExpansionHeaderWidget(self, expansionKey)
    local info = MR.GetExpansionInfo and MR:GetExpansionInfo(expansionKey) or nil
    local label = (info and (info.shortLabel or info.label or info.key)) or tostring(expansionKey or "")
    local frameAlpha = MR.db.profile.frameAlpha or 1.0
    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", self.content, "TOPLEFT", xOff + 3, -yOff)
    frame:SetSize(math.max(colW - 6, 1), 18)
    frame:SetFrameLevel((self.content:GetFrameLevel() or 0) + 8)
    frame:SetBackdrop(MakeBackdrop())
    frame:SetBackdropColor(0.035, 0.055, 0.070, 0.86 * frameAlpha)
    frame:SetBackdropBorderColor(0.14, 0.30, 0.34, 0.80 * frameAlpha)
    frame._label:SetFont(FONT_HEADERS, math.max(8, GetFontSize() - 1), GetFontFlags())
    frame._label:SetPoint("LEFT", frame, "LEFT", 7, 0)
    frame._label:SetPoint("RIGHT", frame, "RIGHT", -7, 0)
    frame._label:SetText(label)
    frame._label:SetTextColor(0.72, 0.86, 0.88, 0.95)
    return frame
end

local function EnsureMainSectionWidget(self, modKey)
    self._mainSectionFrames = self._mainSectionFrames or {}
    local card = self._mainSectionFrames[modKey]
    if card then
        card:SetParent(self.content)
        card:Show()
        return card
    end

    card = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
    card._glow = card:CreateTexture(nil, "BACKGROUND")
    card._glow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    card._glow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    card._glow:SetTexture("Interface\\Buttons\\WHITE8X8")

    card._expHeader = CreateFrame("Frame", nil, card, "BackdropTemplate")
    card._expHeader:SetBackdrop(MakeBackdrop())
    card._expHeader._label = card._expHeader:CreateFontString(nil, "OVERLAY")
    card._expHeader._label:SetJustifyH("LEFT")

    card._hdrFrame = CreateFrame("Frame", nil, card)
    card._hdrFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    card._hdrFrame:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    card._hdrFrame:EnableMouse(true)
    card._hdrFrame._hdrHover = card._hdrFrame:CreateTexture(nil, "BORDER")
    card._hdrFrame._hdrHover:SetAllPoints()
    card._hdrFrame._hdrBg = card._hdrFrame:CreateTexture(nil, "BACKGROUND")
    card._hdrFrame._hdrBg:SetAllPoints()
    card._hdrFrame._iconPlate = CreateFrame("Frame", nil, card._hdrFrame, "BackdropTemplate")
    card._hdrFrame._icon = card._hdrFrame:CreateTexture(nil, "ARTWORK")
    card._hdrFrame._label = card._hdrFrame:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._count = card._hdrFrame:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._currencyBrowserButton = CreateFrame("Button", nil, card._hdrFrame, "BackdropTemplate")
    card._hdrFrame._currencyBrowserButton:SetSize(18, 18)
    card._hdrFrame._currencyBrowserButton:SetBackdrop(MakeBackdrop())
    card._hdrFrame._currencyBrowserButton:SetScript("OnClick", CurrencyBrowserButtonOnClick)
    card._hdrFrame._currencyBrowserButton:SetScript("OnEnter", CurrencyBrowserButtonOnEnter)
    card._hdrFrame._currencyBrowserButton:SetScript("OnLeave", CurrencyBrowserButtonOnLeave)
    card._hdrFrame._currencyBrowserText = card._hdrFrame._currencyBrowserButton:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._currencyBrowserButton._label = card._hdrFrame._currencyBrowserText
    card._hdrFrame._currencyBrowserText:SetFont(FONT_ROWS, 12, GetFontFlags())
    card._hdrFrame._currencyBrowserText:SetPoint("CENTER", card._hdrFrame._currencyBrowserButton, "CENTER", 0, 0)
    card._hdrFrame._currencyBrowserText:SetText(L["CurrencyBrowser_All"] or "ALL")
    card._hdrFrame._arrow = CreateFrame("Frame", nil, card._hdrFrame)
    card._hdrFrame:SetScript("OnMouseDown", MainSectionHeaderOnMouseDown)
    card._hdrFrame:SetScript("OnMouseUp", MainSectionHeaderOnMouseUp)
    card._hdrFrame:SetScript("OnDragStart", MainSectionHeaderOnDragStart)
    card._hdrFrame:SetScript("OnDragStop", MainSectionHeaderOnDragStop)
    card._hdrFrame:SetScript("OnEnter", MainSectionHeaderOnEnter)
    card._hdrFrame:SetScript("OnLeave", MainSectionHeaderOnLeave)

    card._divider = CreateFrame("Frame", nil, card, "BackdropTemplate")
    card._divider:SetBackdrop(MakeBackdrop(false))

    card._rows = {}
    self._mainSectionFrames[modKey] = card
    return card
end

local function EnsureDetachedSectionWidget(frame, modKey)
    frame._sectionFrames = frame._sectionFrames or {}
    local card = frame._sectionFrames[modKey]
    if card then
        card:SetParent(frame.content)
        card:Show()
        return card
    end

    card = CreateFrame("Frame", nil, frame.content, "BackdropTemplate")
    card._glow = card:CreateTexture(nil, "BACKGROUND")
    card._glow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    card._glow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    card._glow:SetTexture("Interface\\Buttons\\WHITE8X8")

    card._hdrFrame = CreateFrame("Frame", nil, card)
    card._hdrFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    card._hdrFrame:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    card._hdrFrame:EnableMouse(true)
    card._hdrFrame:RegisterForDrag("LeftButton")
    card._hdrFrame._hdrHover = card._hdrFrame:CreateTexture(nil, "BORDER")
    card._hdrFrame._hdrHover:SetAllPoints()
    card._hdrFrame._hdrBg = card._hdrFrame:CreateTexture(nil, "BACKGROUND")
    card._hdrFrame._hdrBg:SetAllPoints()
    card._hdrFrame._iconPlate = CreateFrame("Frame", nil, card._hdrFrame, "BackdropTemplate")
    card._hdrFrame._icon = card._hdrFrame:CreateTexture(nil, "ARTWORK")
    card._hdrFrame._label = card._hdrFrame:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._count = card._hdrFrame:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._currencyBrowserButton = CreateFrame("Button", nil, card._hdrFrame, "BackdropTemplate")
    card._hdrFrame._currencyBrowserButton:SetSize(18, 18)
    card._hdrFrame._currencyBrowserButton:SetBackdrop(MakeBackdrop())
    card._hdrFrame._currencyBrowserButton:SetScript("OnClick", CurrencyBrowserButtonOnClick)
    card._hdrFrame._currencyBrowserButton:SetScript("OnEnter", CurrencyBrowserButtonOnEnter)
    card._hdrFrame._currencyBrowserButton:SetScript("OnLeave", CurrencyBrowserButtonOnLeave)
    card._hdrFrame._currencyBrowserText = card._hdrFrame._currencyBrowserButton:CreateFontString(nil, "OVERLAY")
    card._hdrFrame._currencyBrowserButton._label = card._hdrFrame._currencyBrowserText
    card._hdrFrame._currencyBrowserText:SetFont(FONT_ROWS, 12, GetFontFlags())
    card._hdrFrame._currencyBrowserText:SetPoint("CENTER", card._hdrFrame._currencyBrowserButton, "CENTER", 0, 0)
    card._hdrFrame._currencyBrowserText:SetText(L["CurrencyBrowser_All"] or "ALL")
    card._hdrFrame._arrow = CreateFrame("Frame", nil, card._hdrFrame)
    card._hdrFrame:SetScript("OnMouseDown", MainSectionHeaderOnMouseDown)
    card._hdrFrame:SetScript("OnMouseUp", MainSectionHeaderOnMouseUp)
    card._hdrFrame:SetScript("OnDragStart", MainSectionHeaderOnDragStart)
    card._hdrFrame:SetScript("OnDragStop", MainSectionHeaderOnDragStop)
    card._hdrFrame:SetScript("OnEnter", MainSectionHeaderOnEnter)
    card._hdrFrame:SetScript("OnLeave", MainSectionHeaderOnLeave)

    card._divider = CreateFrame("Frame", nil, card, "BackdropTemplate")
    card._divider:SetBackdrop(MakeBackdrop(false))

    card._rows = {}
    frame._sectionFrames[modKey] = card
    return card
end

local function AddSectionRegistryEntry(self, frame, modKey, col, yOff, bottom, expansionHeaderKey)
    self._sectionRegistryPool = self._sectionRegistryPool or {}
    local index = (self._sectionRegistryCount or 0) + 1
    self._sectionRegistryCount = index
    local entry = self._sectionRegistryPool[index] or {}
    self._sectionRegistryPool[index] = entry
    entry.frame = frame
    entry.modKey = modKey
    entry.col = col or 1
    entry.yOff = yOff or 0
    entry.bottom = bottom
    entry.expansionHeaderKey = expansionHeaderKey
    self.sectionRegistry[index] = entry
    return entry
end

local function UpdateDetachedSectionWidget(self, hostFrame, mod, contentWidth)
    local transparent = IsMainTextOnlyMode()
    local frameAlpha = MR.db.profile.frameAlpha or 1.0
    local showSectionHeaders = ShouldShowSectionHeaders()
    local textOnlyHeaderAlpha = showSectionHeaders and GetTextOnlyHeaderAlpha() or 0
    local headerAlpha = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 0.90 or 0) * frameAlpha)
    local dividerAlpha = transparent and (0.50 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.09 or 0) * frameAlpha)
    local showSoftHeaders = transparent and textOnlyHeaderAlpha > 0
    local showIcons = ShouldShowIcons()
    local stats = GetModuleStats(self, mod)
    local isOpen = stats and stats.isOpen
    local secTotal = stats and stats.totalRows or 0
    local secDone = stats and stats.doneRows or 0
    local shownRows = stats and stats.shownRows or 0
    if shownRows == 0 then
        return nil
    end

    local allDone = (secTotal > 0) and (secDone == secTotal)
    local card = EnsureDetachedSectionWidget(hostFrame, mod.key)
    local sectionHeight = math.max((stats and stats.height or 0) - SECTION_GAP, HEADER_HEIGHT + 1)
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", hostFrame.content, "TOPLEFT", 0, 0)
    card:SetSize(math.max(contentWidth, 1), sectionHeight)
    card:SetBackdrop(MakeBackdrop())
    card._hdrFrame._mrDetachedHost = nil
    if transparent then
        card:SetBackdropColor(0, 0, 0, 0)
        card:SetBackdropBorderColor(0, 0, 0, 0)
    else
        card:SetBackdropColor(0.02, 0.03, 0.05, 0.94 * frameAlpha)
        card:SetBackdropBorderColor(0.18, 0.22, 0.28, 0.95 * frameAlpha)
    end
    card._glow:SetColorTexture(0.12, 0.14, 0.18, transparent and 0 or (0.10 * frameAlpha))

    card._hdrFrame:SetHeight(HEADER_HEIGHT)
    card._hdrFrame._mrMod = mod
    card._hdrFrame._mrDetachedHost = hostFrame
    card._hdrFrame._mrHoverAlpha = transparent and (0.10 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.05 or 0) * frameAlpha)
    local customHeaderBg = MR.GetHeaderBackgroundColor and MR:GetHeaderBackgroundColor(mod.key) or nil
    local hdrR, hdrG, hdrB = 0.08, 0.09, 0.12
    if customHeaderBg then
        hdrR, hdrG, hdrB = hex(customHeaderBg)
    end
    card._hdrFrame._hdrBg:SetColorTexture(hdrR, hdrG, hdrB, headerAlpha)

    local explicitColor = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local customColor = MR:GetHeaderColor(mod.key)
    local headerColor = customColor or mod.labelColor or "#ffffff"
    local lr, lg, lb = hex(headerColor)
    local accentA = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 1 or 0) * frameAlpha)
    local accentR, accentG, accentB = lr, lg, lb
    if allDone then
        accentR, accentG, accentB = COL.complete[1], COL.complete[2], COL.complete[3]
    end

    card._hdrFrame._iconPlate:ClearAllPoints()
    card._hdrFrame._iconPlate:SetSize(math.max(HEADER_HEIGHT - 6, 12), math.max(HEADER_HEIGHT - 6, 12))
    card._hdrFrame._iconPlate:SetPoint("LEFT", card._hdrFrame, "LEFT", 4, 0)
    card._hdrFrame._iconPlate:SetBackdrop(MakeBackdrop())
    local iconPlateBgAlpha = transparent and (showSoftHeaders and (0.16 * accentA) or 0) or ((showSectionHeaders and 0.16 or 0) * frameAlpha)
    local iconPlateBorderAlpha = transparent and (showSoftHeaders and (0.50 * accentA) or 0) or ((showSectionHeaders and 0.50 or 0) * frameAlpha)
    card._hdrFrame._iconPlate:SetBackdropColor(accentR, accentG, accentB, iconPlateBgAlpha)
    card._hdrFrame._iconPlate:SetBackdropBorderColor(accentR, accentG, accentB, iconPlateBorderAlpha)

    local iconInfo = showIcons and ShouldShowModuleHeaderIcon(mod.key) and GetModuleIconInfo(mod) or nil
    card._hdrFrame._icon:ClearAllPoints()
    card._hdrFrame._icon:SetSize(math.max(HEADER_HEIGHT - 12, 9), math.max(HEADER_HEIGHT - 12, 9))
    card._hdrFrame._icon:SetPoint("CENTER", card._hdrFrame._iconPlate, "CENTER", 0, 0)
    local hasHeaderIcon = ApplyIconToTexture(card._hdrFrame._icon, iconInfo, { 0.14, 0.86, 0.14, 0.86 })
    card._hdrFrame._iconPlate:SetShown(hasHeaderIcon and (showIcons or showSectionHeaders))

    card._hdrFrame._label:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
    card._hdrFrame._label:ClearAllPoints()
    if hasHeaderIcon then
        card._hdrFrame._label:SetPoint("LEFT", card._hdrFrame._iconPlate, "RIGHT", 6, 0)
    else
        card._hdrFrame._label:SetPoint("LEFT", card._hdrFrame, "LEFT", 9, 0)
    end
    card._hdrFrame._label:SetJustifyH("LEFT")
    if card._hdrFrame._label.SetWordWrap then
        card._hdrFrame._label:SetWordWrap(false)
    end
    card._hdrFrame._label:SetText((allDone and not explicitColor) and WC("00ff96", mod.label) or WC(headerColor:gsub("#", ""), mod.label))

    card._hdrFrame._count:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    card._hdrFrame._count:ClearAllPoints()
    local currencyBrowserButton = card._hdrFrame._currencyBrowserButton
    local showCurrencyBrowserButton = mod.key == "currencies" and MR.ToggleCurrencyBrowserFrame
    if showCurrencyBrowserButton then
        currencyBrowserButton:ClearAllPoints()
        currencyBrowserButton:SetPoint("RIGHT", card._hdrFrame, "RIGHT", -23, 0)
        StyleCurrencyBrowserButton(currencyBrowserButton, transparent, frameAlpha)
        currencyBrowserButton:Show()
        card._hdrFrame._count:SetPoint("RIGHT", currencyBrowserButton, "LEFT", -8, 0)
    else
        currencyBrowserButton:Hide()
        card._hdrFrame._count:SetPoint("RIGHT", card._hdrFrame, "RIGHT", -22, 0)
    end
    card._hdrFrame._count:SetText(showCurrencyBrowserButton
        and string.format("%d / %d", secDone, secTotal)
        or string.format("%d / %d", secDone, secTotal))
    card._hdrFrame._count:SetTextColor(countColor(secDone, secTotal))
    card._hdrFrame._count:SetJustifyH("RIGHT")
    card._hdrFrame._label:SetPoint("RIGHT", card._hdrFrame._count, "LEFT", -8, 0)

    StyleSectionCollapseIndicator(card._hdrFrame._arrow, isOpen)

    local localY = HEADER_HEIGHT
    card._divider:ClearAllPoints()
    card._divider:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -localY)
    card._divider:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, -localY)
    card._divider:SetHeight(1)
    card._divider:SetBackdropColor(1, 1, 1, dividerAlpha)

    local usedRows = card._usedRows or {}
    card._usedRows = usedRows
    for key in pairs(usedRows) do
        usedRows[key] = nil
    end
    if isOpen then
        localY = localY + 1
        local hideComplete = stats and stats.hideComplete
        local rows = MR.GetOrderedRows and MR:GetOrderedRows(mod) or mod.rows
        localY = RenderMainGroupedRows(self, card, mod, rows, hideComplete, localY, card:GetWidth(), usedRows, function(row, done, rowY)
            return UpdateMainRowWidget(self, card, mod, row, done, rowY, card:GetWidth())
        end)
    end

    for key, rowFrame in pairs(card._rows or {}) do
        if not usedRows[key] then
            HideMainRowWidget(rowFrame)
        end
    end

    return card
end

EnsureMainRowWidget = function(section, rowKey)
    section._rows = section._rows or {}
    local rowFrame = section._rows[rowKey]
    if rowFrame then
        rowFrame:SetParent(section)
        rowFrame:Show()
        return rowFrame
    end

    rowFrame = CreateFrame("Frame", nil, section)
    rowFrame:EnableMouse(true)
    rowFrame:SetScript("OnEnter", MainRowOnEnter)
    rowFrame:SetScript("OnLeave", MainRowOnLeave)
    rowFrame:SetScript("OnMouseDown", MainRowOnMouseDown)

    rowFrame._headerBg = rowFrame:CreateTexture(nil, "BACKGROUND")
    rowFrame._headerBg:SetAllPoints()
    rowFrame._headerText = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._headerActionButton = CreateFrame("Button", nil, rowFrame, "BackdropTemplate")
    rowFrame._headerActionButton._mrOwner = rowFrame
    rowFrame._headerActionButton:SetScript("OnClick", MainHeaderActionOnClick)
    rowFrame._headerActionButton:SetScript("OnEnter", MainHeaderActionOnEnter)
    rowFrame._headerActionButton:SetScript("OnLeave", MainHeaderActionOnLeave)
    rowFrame._headerActionText = rowFrame._headerActionButton:CreateFontString(nil, "OVERLAY")
    rowFrame._headerActionText:SetFont(FONT_ROWS, 9, GetFontFlags())
    rowFrame._headerCount = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._headerCount:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())

    rowFrame._collapsedLine = rowFrame:CreateTexture(nil, "ARTWORK")
    rowFrame._collapsedDot = rowFrame:CreateTexture(nil, "ARTWORK")

    rowFrame._hover = rowFrame:CreateTexture(nil, "BACKGROUND")
    rowFrame._hover:SetAllPoints()
    rowFrame._rowShade = rowFrame:CreateTexture(nil, "BORDER")
    rowFrame._separator = rowFrame:CreateTexture(nil, "ARTWORK")

    rowFrame._statusBtn = CreateFrame("Button", nil, rowFrame, "BackdropTemplate")
    rowFrame._statusBtn._mrOwner = rowFrame
    rowFrame._statusBtn:SetScript("OnClick", MainStatusButtonOnClick)
    rowFrame._statusBtn:SetScript("OnEnter", MainStatusButtonOnEnter)
    rowFrame._statusBtn:SetScript("OnLeave", MainStatusButtonOnLeave)
    rowFrame._statusFill = rowFrame._statusBtn:CreateTexture(nil, "ARTWORK")
    rowFrame._statusFill:SetPoint("TOPLEFT", rowFrame._statusBtn, "TOPLEFT", 2, -2)
    rowFrame._statusFill:SetPoint("BOTTOMRIGHT", rowFrame._statusBtn, "BOTTOMRIGHT", -2, 2)
    rowFrame._statusCheck = rowFrame._statusBtn:CreateFontString(nil, "OVERLAY")
    rowFrame._statusCheck:SetFont(FONT_HEADERS, 9, GetFontFlags())
    rowFrame._statusCheck:SetPoint("CENTER", rowFrame._statusBtn, "CENTER", 0, 1)
    rowFrame._statusCheck:SetText("x")

    rowFrame._rowIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    rowFrame._countIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    rowFrame._label = rowFrame:CreateFontString(nil, "OVERLAY")
    if rowFrame._label.SetWordWrap then
        rowFrame._label:SetWordWrap(false)
    end
    if rowFrame._label.SetNonSpaceWrap then
        rowFrame._label:SetNonSpaceWrap(false)
    end
    if rowFrame._label.SetShadowOffset then
        rowFrame._label:SetShadowOffset(0, 0)
    end
    rowFrame._count = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._count:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
    rowFrame._wallet = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._wallet:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
    rowFrame._coords = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._coords:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 1), GetFontFlags())
    rowFrame._vault = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._vault:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())


    local DIFF_BADGE_DEFS = {
        { id = 17, label = "L" },
        { id = 14, label = "N" },
        { id = 15, label = "H" },
        { id = 16, label = "M" },
    }
    rowFrame._diffBadges = {}
    for i, def in ipairs(DIFF_BADGE_DEFS) do
        local btn = CreateFrame("Frame", nil, rowFrame, "BackdropTemplate")
        btn:SetSize(14, 14)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT_ROWS, math.max(6, GetFontSize() - 3), GetFontFlags())
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
        lbl:SetText(def.label)
        btn._lbl = lbl
        btn._diffId = def.id
        btn:Hide()
        rowFrame._diffBadges[i] = btn
    end
    rowFrame._diffCount = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._diffCount:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())

    section._rows[rowKey] = rowFrame
    return rowFrame
end

local function GetMainFrameProgressModule(modKey)
    local source = MR.GetMainFrameProgressSource and MR:GetMainFrameProgressSource() or (MR.db and MR.db.char)
    local progress = source and source.progress
    return progress and progress[modKey] or nil
end

local function GetMainFrameRowCount(row)
    if MR.IsMainAltViewActive and MR:IsMainAltViewActive() then
        return nil, nil
    end

    return row.countText, row.countColor
end

UpdateMainRowWidget = function(self, section, mod, row, done, yOff, colW)
    local rowId = row.key or tostring(row.label or yOff)
    local rowFrame = EnsureMainRowWidget(section, rowId)
    local transparent = IsMainTextOnlyMode()
    local showIcons = ShouldShowIcons()
    local frameAlpha = MR.db.profile.frameAlpha or 1.0
    local isAutoTracked = row.autoTracked
        or ((row.questIds ~= nil) and not row.allowManualQuestClicks)
        or (row.encounterIds ~= nil)
        or (row.liveKey ~= nil)
        or (row.spellId ~= nil)
        or (row.currencyId ~= nil)
        or (row.itemId ~= nil)
    local hasWaypoint = row.zone and row.x and row.y
    local isComplete = self:IsRowComplete(mod, row, done)
    local collapsed = false
    local rowH = collapsed and 8 or ROW_HEIGHT

    rowFrame._mrData = rowFrame._mrData or {}
    rowFrame._mrData.mod = mod
    rowFrame._mrData.row = row
    rowFrame._mrData.done = done
    rowFrame._mrData.transparent = transparent
    rowFrame._mrData.frameAlpha = frameAlpha
    rowFrame._mrData.isAutoTracked = isAutoTracked
    rowFrame._mrData.hasWaypoint = hasWaypoint
    rowFrame._mrData.isComplete = isComplete
    rowFrame:ClearAllPoints()
    rowFrame:SetPoint("TOPLEFT", section, "TOPLEFT", 0, -yOff)
    rowFrame:SetSize(colW, rowH)
    rowFrame._timerUpdate = nil
    rowFrame:Show()

    rowFrame._headerBg:Hide()
    rowFrame._headerText:Hide()
    rowFrame._headerActionButton:Hide()
    rowFrame._headerCount:Hide()
    rowFrame._collapsedLine:Hide()
    rowFrame._collapsedDot:Hide()
    rowFrame._hover:Hide()
    rowFrame._rowShade:Hide()
    rowFrame._separator:Hide()
    rowFrame._statusBtn:Hide()
    rowFrame._rowIcon:Hide()
    rowFrame._countIcon:Hide()
    rowFrame._label:Hide()
    rowFrame._count:Hide()
    rowFrame._wallet:Hide()
    rowFrame._coords:Hide()
    rowFrame._vault:Hide()
    if rowFrame._diffBadges then
        for _, badge in ipairs(rowFrame._diffBadges) do badge:Hide() end
    end
    if rowFrame._diffCount then rowFrame._diffCount:Hide() end

    if row.sectionHeader then
        rowFrame._mrData.mode = "sectionHeader"
        rowFrame._headerBg:Show()
        if transparent then
            rowFrame._headerBg:SetColorTexture(1, 1, 1, 0)
        else
            rowFrame._headerBg:SetColorTexture(0.06, 0.08, 0.13, 0.92 * frameAlpha)
        end

        SetFontForText(rowFrame._headerText, row.label, math.max(8, GetFontSize() - 1), GetFontFlags())
        rowFrame._headerText:ClearAllPoints()
        rowFrame._headerText:SetPoint("LEFT", rowFrame, "LEFT", 8, 0)
        rowFrame._headerText:SetPoint("RIGHT", rowFrame, "RIGHT", -84, 0)
        rowFrame._headerText:SetJustifyH("LEFT")
        rowFrame._headerText:SetText(row.label)
        rowFrame._headerText:SetTextColor(0.82, 0.66, 0.98)
        rowFrame._headerText:Show()

        local headerActionButton = nil
        if ((row.headerActionText and row.headerActionText ~= "") or row.headerActionStyle == "visibility") and row.onHeaderActionClick then
            headerActionButton = rowFrame._headerActionButton
            headerActionButton:ClearAllPoints()
            headerActionButton:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
            headerActionButton:Show()
            rowFrame._headerActionText:ClearAllPoints()

            if row.headerActionStyle == "visibility" then
                headerActionButton:SetSize(14, 14)
                headerActionButton:SetBackdrop(MakeBackdrop())
                headerActionButton:SetBackdropColor(0.05, 0.10, 0.18, 1)
                headerActionButton:SetBackdropBorderColor(
                    row.headerActionVisible and 0.15 or 0.35,
                    row.headerActionVisible and 0.32 or 0.12,
                    row.headerActionVisible and 0.38 or 0.12,
                    1
                )
                rowFrame._headerActionText:SetFont(FONT_ROWS, 9, GetFontFlags())
                rowFrame._headerActionText:SetPoint("CENTER", headerActionButton, "CENTER", 0, 0)
                rowFrame._headerActionText:SetJustifyH("CENTER")
                rowFrame._headerActionText:SetText(row.headerActionVisible and "o" or "-")
                rowFrame._headerActionText:SetTextColor(
                    row.headerActionVisible and 0.25 or 0.55,
                    row.headerActionVisible and 0.85 or 0.25,
                    row.headerActionVisible and 0.70 or 0.25
                )
            else
                headerActionButton:SetSize(26, rowH)
                rowFrame._headerActionText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                rowFrame._headerActionText:SetPoint("CENTER", headerActionButton, "CENTER", 0, 0)
                rowFrame._headerActionText:SetJustifyH("CENTER")
                rowFrame._headerActionText:SetText(row.headerActionText)
                if row.headerActionColor then
                    rowFrame._headerActionText:SetTextColor(row.headerActionColor[1], row.headerActionColor[2], row.headerActionColor[3])
                else
                    rowFrame._headerActionText:SetTextColor(0.92, 0.78, 0.24)
                end
            end
            rowFrame._headerActionText:Show()
        end

        local headerCountText, headerCountColor = GetMainFrameRowCount(row)
        if headerCountText and headerCountText ~= "" then
            rowFrame._headerCount:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
            rowFrame._headerCount:ClearAllPoints()
            if headerActionButton then
                rowFrame._headerCount:SetPoint("RIGHT", headerActionButton, "LEFT", -8, 0)
            else
                rowFrame._headerCount:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
            end
            rowFrame._headerCount:SetJustifyH("RIGHT")
            rowFrame._headerCount:SetText(headerCountText)
            if headerCountColor then
                rowFrame._headerCount:SetTextColor(headerCountColor[1], headerCountColor[2], headerCountColor[3])
            else
                rowFrame._headerCount:SetTextColor(0.74, 0.80, 0.88)
            end
            rowFrame._headerCount:Show()
        end

        return rowFrame, yOff + rowH, rowId
    end

    rowFrame._mrData.mode = "normal"
    rowFrame._hover:SetColorTexture(1, 1, 1, 0)
    rowFrame._hover:Show()
    rowFrame._rowShade:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 0, -1)
    rowFrame._rowShade:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 0, 0)
    if isComplete and not transparent then
        rowFrame._rowShade:SetColorTexture(0.12, 0.16, 0.12, 0.18 * frameAlpha)
    else
        rowFrame._rowShade:SetColorTexture(0, 0, 0, 0)
    end
    rowFrame._rowShade:Show()

    rowFrame._separator:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", 12, 0)
    rowFrame._separator:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", -12, 0)
    rowFrame._separator:SetHeight(1)
    rowFrame._separator:SetColorTexture(1, 1, 1, transparent and 0 or (0.06 * frameAlpha))
    rowFrame._separator:Show()

    rowFrame._statusBtn:ClearAllPoints()
    rowFrame._statusBtn:SetSize(14, 14)
    rowFrame._statusBtn:SetPoint("LEFT", rowFrame, "LEFT", PADDING + 2, 0)
    rowFrame._statusBtn:SetBackdrop(MakeBackdrop())

    local mo = MR:GetManualOverride(mod.key, row.key)
    local forcedComplete = row.max and mo >= row.max
    local activeDone = forcedComplete and row.max or done
    if transparent then
        rowFrame._statusBtn:SetBackdropColor(0, 0, 0, 0)
    else
        rowFrame._statusBtn:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * frameAlpha)
    end
    if forcedComplete then
        rowFrame._statusBtn:SetBackdropBorderColor(transparent and 0 or 0.88, transparent and 0 or 0.74, transparent and 0 or 0.22, transparent and 0 or frameAlpha)
        rowFrame._statusFill:SetColorTexture(0.88, 0.74, 0.22, transparent and 0 or (0.85 * frameAlpha))
        rowFrame._statusCheck:SetFont(FONT_HEADERS, 9, GetFontFlags())
        rowFrame._statusCheck:SetTextColor(0.10, 0.08, 0.02, transparent and 0 or 1)
        if transparent then rowFrame._statusCheck:Hide() else rowFrame._statusCheck:Show() end
    elseif isComplete then
        rowFrame._statusBtn:SetBackdropBorderColor(transparent and 0 or 0.24, transparent and 0 or 0.76, transparent and 0 or 0.46, transparent and 0 or frameAlpha)
        rowFrame._statusFill:SetColorTexture(0.20, 0.72, 0.42, transparent and 0 or (0.85 * frameAlpha))
        rowFrame._statusCheck:SetFont(FONT_HEADERS, 9, GetFontFlags())
        rowFrame._statusCheck:SetTextColor(0.03, 0.08, 0.04, transparent and 0 or 1)
        if transparent then rowFrame._statusCheck:Hide() else rowFrame._statusCheck:Show() end
    elseif row.max and activeDone > 0 then
        rowFrame._statusBtn:SetBackdropBorderColor(transparent and 0 or 0.62, transparent and 0 or 0.52, transparent and 0 or 0.22, transparent and 0 or (0.95 * frameAlpha))
        rowFrame._statusFill:SetColorTexture(0.78, 0.62, 0.22, transparent and 0 or (0.70 * frameAlpha))
        rowFrame._statusCheck:Hide()
    else
        rowFrame._statusBtn:SetBackdropBorderColor(transparent and 0 or 0.24, transparent and 0 or 0.28, transparent and 0 or 0.34, transparent and 0 or (0.95 * frameAlpha))
        rowFrame._statusFill:SetColorTexture(0.09, 0.10, 0.14, transparent and 0 or (0.70 * frameAlpha))
        rowFrame._statusCheck:Hide()
    end
    if row.hideStatus then
        rowFrame._statusBtn:Hide()
    else
        rowFrame._statusBtn:Show()
    end
    rowFrame._statusBtn:EnableMouse((((isAutoTracked and not row.noMax) or row.toggleStatus) and not row.hideStatus) and true or false)

    local isCurrencyModule = mod and (mod.key == "currencies" or mod.key == "pvp_currencies")
    local countIconInfo = (showIcons and isCurrencyModule and row.currencyId) and GetRowIconInfo(mod, row) or nil
    local rowIconInfo = (mod and mod.profSkillLine) and GetRowIconInfo(mod, row) or nil
    local iconSize = math.max(ROW_HEIGHT - 8, 12)
    rowFrame._rowIcon:ClearAllPoints()
    rowFrame._rowIcon:SetSize(iconSize, iconSize)
    rowFrame._rowIcon:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
    local hasRowIcon = ApplyIconToTexture(rowFrame._rowIcon, rowIconInfo)
    if isComplete and hasRowIcon then
        rowFrame._rowIcon:SetVertexColor(0.55, 0.55, 0.55, 0.7)
    else
        rowFrame._rowIcon:SetVertexColor(1, 1, 1, 1)
    end
    rowFrame._rowIcon:SetShown(hasRowIcon)

    rowFrame._countIcon:ClearAllPoints()
    rowFrame._countIcon:SetSize(iconSize, iconSize)
    rowFrame._countIcon:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
    local hasCountIcon = ApplyIconToTexture(rowFrame._countIcon, countIconInfo)
    if isComplete and hasCountIcon then
        rowFrame._countIcon:SetVertexColor(0.55, 0.55, 0.55, 0.7)
    else
        rowFrame._countIcon:SetVertexColor(1, 1, 1, 1)
    end
    rowFrame._countIcon:SetShown(hasCountIcon)

    local hasNumericMax = type(row.max) == "number" and row.max > 0
    local isCurrencyRow = row.currencyId and hasNumericMax and not row.noMax
    local isProfessionRow = mod and mod.profSkillLine
    local hasCoordText = hasWaypoint and not row.hideCoordText and not isProfessionRow
    local hasKnowledgeText = type(row.kpTotal) == "number" and row.kpTotal > 0
    local lblRightOff = isCurrencyRow and -96 or (hasCoordText and (hasKnowledgeText and -168 or -128) or (hasKnowledgeText and -64 or -52))

    SetFontForText(rowFrame._label, CleanLabelText(row.label), GetFontSize(), GetFontFlags())
    rowFrame._label:ClearAllPoints()
    if hasRowIcon then
        rowFrame._label:SetPoint("LEFT", rowFrame._rowIcon, "RIGHT", 8, 0)
    else
        rowFrame._label:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
    end
    rowFrame._label:SetPoint("RIGHT", rowFrame, "RIGHT", lblRightOff, 0)
    rowFrame._label:SetJustifyH("LEFT")
    rowFrame._label:SetJustifyV("MIDDLE")

    local rowCustom = MR:GetRowColor(mod.key, row.key) or (row.colorKey and MR:GetRowColor(mod.key, row.colorKey))
    local headerCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local inlineColor = ExtractInlineLabelColor(row.label)
    local effectiveColor = rowCustom or headerCustom or inlineColor
    local cleanLabel = CleanLabelText(row.label)
    if isComplete then
        rowFrame._label:SetText(cleanLabel)
        if effectiveColor then
            local cr, cg, cb = hex(effectiveColor)
            rowFrame._label:SetTextColor(cr * 0.45, cg * 0.45, cb * 0.45)
        else
            rowFrame._label:SetTextColor(0.38, 0.38, 0.38)
        end
    elseif effectiveColor then
        rowFrame._label:SetText(cleanLabel)
        rowFrame._label:SetTextColor(hex(effectiveColor))
    else
        rowFrame._label:SetText(cleanLabel)
        rowFrame._label:SetTextColor(1, 1, 1)
    end
    rowFrame._label:Show()

    rowFrame._count:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
    rowFrame._count:ClearAllPoints()
    if hasCountIcon then
        rowFrame._count:SetPoint("RIGHT", rowFrame._countIcon, "LEFT", -4, 0)
    else
        rowFrame._count:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
    end
    rowFrame._count:SetJustifyH("RIGHT")
    if rowFrame._count.SetWordWrap then
        rowFrame._count:SetWordWrap(false)
    end
    rowFrame._count:SetWidth(0)

    local countText, countTextColor = GetMainFrameRowCount(row)
    if isProfessionRow then
        countText, countTextColor = nil, nil
    end
    if countText then
        rowFrame._count:SetText(countText)
        if countTextColor then
            rowFrame._count:SetTextColor(countTextColor[1], countTextColor[2], countTextColor[3])
        else
            rowFrame._count:SetTextColor(0.8, 0.8, 0.8)
        end

        if not isCurrencyRow and not hasCoordText then
            local reservedWidth
            if type(row.countWidth) == "number" and row.countWidth > 0 then
                reservedWidth = row.countWidth
            else
                reservedWidth = math.min(
                    math.max(math.floor((rowFrame._count:GetStringWidth() or 0) + 8), 64),
                    math.floor(math.max(rowFrame:GetWidth() * 0.5, 64))
                )
            end
            rowFrame._count:SetWidth(reservedWidth)
            rowFrame._label:ClearAllPoints()
            if hasRowIcon then
                rowFrame._label:SetPoint("LEFT", rowFrame._rowIcon, "RIGHT", 8, 0)
            else
                rowFrame._label:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
            end
            rowFrame._label:SetPoint("RIGHT", rowFrame._count, "LEFT", -8, 0)
        else
            rowFrame._count:SetWidth(0)
        end
    elseif isCurrencyRow then
        local mdb = GetMainFrameProgressModule(mod.key)
        local wallet = (mdb and mdb[row.key .. "_wallet"]) or done
        rowFrame._count:SetText(string.format("%d/%d", done, row.max))
        rowFrame._count:SetTextColor(countColor(done, row.max))
        rowFrame._wallet:SetShown(not row.hideWallet)
        rowFrame._label:ClearAllPoints()
        if hasRowIcon then
            rowFrame._label:SetPoint("LEFT", rowFrame._rowIcon, "RIGHT", 8, 0)
        else
            rowFrame._label:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
        end
        if row.hideWallet then
            rowFrame._label:SetPoint("RIGHT", rowFrame._count, "LEFT", -8, 0)
        else
            rowFrame._wallet:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
            rowFrame._wallet:ClearAllPoints()
            rowFrame._wallet:SetPoint("RIGHT", rowFrame._count, "LEFT", -5, 0)
            rowFrame._wallet:SetJustifyH("RIGHT")
            rowFrame._wallet:SetText(string.format("|cffaaaaaa(%d)|r", wallet))
            rowFrame._label:SetPoint("RIGHT", rowFrame._wallet, "LEFT", -8, 0)
        end
    elseif isProfessionRow then
        rowFrame._count:SetText("")
    else
        rowFrame._count:SetText((row.noMax or not hasNumericMax) and tostring(done) or string.format("%d / %d", done, row.max))
        if row.noMax or not hasNumericMax then
            rowFrame._count:SetTextColor(0.8, 0.8, 0.8)
        else
            rowFrame._count:SetTextColor(countColor(done, row.max))
        end
        if hasCountIcon and row.currencyId then
            rowFrame._label:ClearAllPoints()
            rowFrame._label:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
            rowFrame._label:SetPoint("RIGHT", rowFrame._count, "LEFT", -8, 0)
        end
    end
    rowFrame._count:Show()

    local rightAnchor = rowFrame._count
    if hasKnowledgeText then
        rowFrame._vault:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 1), GetFontFlags())
        rowFrame._vault:ClearAllPoints()
        rowFrame._vault:SetPoint("RIGHT", rowFrame._count, "LEFT", -8, 0)
        rowFrame._vault:SetJustifyH("RIGHT")
        if isComplete then
            rowFrame._vault:SetText(L["Done"] or "Done")
            rowFrame._vault:SetTextColor(0.32, 0.80, 0.50, 0.95)
        else
            rowFrame._vault:SetText("+" .. tostring(row.kpTotal))
            if effectiveColor then
                rowFrame._vault:SetTextColor(hex(effectiveColor))
            else
                rowFrame._vault:SetTextColor(0.92, 0.78, 0.24, 0.95)
            end
        end
        rowFrame._vault:Show()
        rightAnchor = rowFrame._vault
    end

    if hasCoordText then
        rowFrame._coords:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 1), GetFontFlags())
        rowFrame._coords:ClearAllPoints()
        rowFrame._coords:SetPoint("RIGHT", rightAnchor, "LEFT", -8, 0)
        rowFrame._coords:SetJustifyH("RIGHT")
        rowFrame._coords:SetText(string.format("%.2f, %.2f", row.x, row.y))
        if isComplete then
            rowFrame._coords:SetTextColor(0.4, 0.4, 0.4, 0.6)
        else
            rowFrame._coords:SetTextColor(0.65, 0.9, 1, 0.95)
        end
        rowFrame._coords:Show()
    end

    if row.vaultLabel then
        rowFrame._vault:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
        rowFrame._vault:ClearAllPoints()
        rowFrame._vault:SetPoint("RIGHT", rowFrame._count, "LEFT", -4, 0)
        rowFrame._vault:SetText(row.vaultLabel)
        rowFrame._vault:SetTextColor(hex(row.vaultColor or "#ffffff"))
        rowFrame._vault:Show()
    end



    local DIFF_BADGE_ORDER = { 17, 14, 15, 16 }
    local DIFF_BADGE_COLORS = {
        [17] = { done = { 0.30, 0.60, 1.00 }, todo = { 0.08, 0.14, 0.24 }, border_done = { 0.22, 0.50, 0.90 }, border_todo = { 0.08, 0.12, 0.20 }, text_done = { 1, 1, 1 }, text_todo = { 0.22, 0.35, 0.50 } },
        [14] = { done = { 0.22, 0.72, 0.32 }, todo = { 0.06, 0.16, 0.09 }, border_done = { 0.16, 0.58, 0.26 }, border_todo = { 0.06, 0.14, 0.08 }, text_done = { 1, 1, 1 }, text_todo = { 0.18, 0.38, 0.22 } },
        [15] = { done = { 1.00, 0.52, 0.08 }, todo = { 0.26, 0.14, 0.04 }, border_done = { 0.88, 0.42, 0.06 }, border_todo = { 0.18, 0.10, 0.03 }, text_done = { 1, 1, 1 }, text_todo = { 0.48, 0.26, 0.10 } },
        [16] = { done = { 0.85, 0.18, 0.20 }, todo = { 0.24, 0.06, 0.07 }, border_done = { 0.70, 0.12, 0.14 }, border_todo = { 0.18, 0.05, 0.05 }, text_done = { 1, 1, 1 }, text_todo = { 0.46, 0.16, 0.16 } },
    }

    local hasEncounterDiffTracking = row.encounterIds and rowFrame._diffBadges and row.taskId
    if hasEncounterDiffTracking then
        local diffState = nil
        if row.accountWideComplete and MR.db and MR.db.global and MR.db.global.customTaskDiffProgress then
            diffState = MR.db.global.customTaskDiffProgress[row.key]
        elseif MR.db and MR.db.char and MR.db.char.customTaskDiffProgress then
            diffState = MR.db.char.customTaskDiffProgress[row.key] or MR.db.char.customTaskDiffProgress[tostring(row.taskId)]
        end
        if not diffState then
            diffState = rowFrame._emptyDiffState or {}
            rowFrame._emptyDiffState = diffState
        end


        local effectiveDiffs = row.encounterDifficulties
        local allDiffs = (effectiveDiffs == nil)


        local visibleBadges = rowFrame._visibleDiffBadges or {}
        rowFrame._visibleDiffBadges = visibleBadges
        for i = #visibleBadges, 1, -1 do
            visibleBadges[i] = nil
        end
        for _, diffId in ipairs(DIFF_BADGE_ORDER) do
            if allDiffs or (effectiveDiffs and effectiveDiffs[diffId]) then
                for _, badge in ipairs(rowFrame._diffBadges) do
                    if badge._diffId == diffId then
                        visibleBadges[#visibleBadges + 1] = badge
                        break
                    end
                end
            end
        end

        for _, badge in ipairs(rowFrame._diffBadges) do badge:Hide() end

        local numTracked = #visibleBadges
        local numDone = 0
        for _, badge in ipairs(visibleBadges) do
            if diffState[badge._diffId] then numDone = numDone + 1 end
        end



        local BADGE_W, BADGE_GAP = 14, 2
        local rowH = ROW_HEIGHT
        local badgeY = math.floor((rowH - BADGE_W) / 2)
        for i, badge in ipairs(visibleBadges) do
            badge:SetSize(BADGE_W, BADGE_W)
            badge:ClearAllPoints()


            local xOff = -4 - (numTracked - i) * (BADGE_W + BADGE_GAP)
            badge:SetPoint("TOPRIGHT", rowFrame, "TOPRIGHT", xOff, -badgeY)
            badge:Show()

            local isDone = diffState[badge._diffId] == true
            local col = DIFF_BADGE_COLORS[badge._diffId] or DIFF_BADGE_COLORS[14]
            local bgC = isDone and col.done or col.todo
            local bdC = isDone and col.border_done or col.border_todo
            local txtC = isDone and col.text_done or col.text_todo
            badge:SetBackdropColor(bgC[1], bgC[2], bgC[3], transparent and 0 or (isDone and 0.88 or 0.65) * frameAlpha)
            badge:SetBackdropBorderColor(bdC[1], bdC[2], bdC[3], transparent and 0 or frameAlpha)
            badge._lbl:SetTextColor(txtC[1], txtC[2], txtC[3], transparent and (isDone and 0.70 or 0.25) or (isDone and 1 or 0.40))
        end


        local badgeZoneWidth = numTracked * (BADGE_W + BADGE_GAP)
        if rowFrame._diffCount then
            rowFrame._diffCount:ClearAllPoints()
            rowFrame._diffCount:SetPoint("RIGHT", rowFrame, "RIGHT", -4 - badgeZoneWidth - 4, 0)
            rowFrame._diffCount:SetJustifyH("RIGHT")
            rowFrame._diffCount:SetText(string.format("%d/%d", numDone, numTracked))
            if numDone >= numTracked and numTracked > 0 then
                rowFrame._diffCount:SetTextColor(0.22, 0.72, 0.32)
            elseif numDone > 0 then
                rowFrame._diffCount:SetTextColor(0.88, 0.72, 0.28)
            else
                rowFrame._diffCount:SetTextColor(0.38, 0.42, 0.48)
            end
            rowFrame._diffCount:Show()
        end


        rowFrame._count:Hide()
        local reservedRight = badgeZoneWidth + 32
        rowFrame._label:ClearAllPoints()
        if hasRowIcon then
            rowFrame._label:SetPoint("LEFT", rowFrame._rowIcon, "RIGHT", 8, 0)
        else
            rowFrame._label:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
        end
        rowFrame._label:SetPoint("RIGHT", rowFrame, "RIGHT", -(reservedRight + 8), 0)
    end

    if row.timerEpoch and not isComplete and not collapsed then
        local function FormatMMSS(s)
            return string.format("%d:%02d", math.floor(s / 60), s % 60)
        end
        local function UpdateTimer()
            local now = GetServerTime()
            local offset = (now - row.timerEpoch) % row.timerInterval
            if offset < row.timerDuration then
                local rem = row.timerDuration - offset
                rowFrame._count:SetText(L["Timer_Live"] .. FormatMMSS(rem))
                rowFrame._count:SetTextColor(0.25, 0.88, 0.50, 1)
            else
                local rem = row.timerInterval - offset
                rowFrame._count:SetText(L["Timer_Next"] .. FormatMMSS(rem))
                rowFrame._count:SetTextColor(0.55, 0.55, 0.55, 1)
            end
        end
        UpdateTimer()
        rowFrame._timerUpdate = UpdateTimer
        table.insert(MR._timerRows, rowFrame)
    end

    return rowFrame, yOff + rowH, rowId
end

local function UpdateMainSectionWidget(self, mod, yOff, xOff, colW, col, recordRegistry, expansionHeaderKey)
    local transparent = IsMainTextOnlyMode()
    local frameAlpha = MR.db.profile.frameAlpha or 1.0
    local showSectionHeaders = ShouldShowSectionHeaders()
    local textOnlyHeaderAlpha = showSectionHeaders and GetTextOnlyHeaderAlpha() or 0
    local headerAlpha = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 0.90 or 0) * frameAlpha)
    local dividerAlpha = transparent and (0.50 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.09 or 0) * frameAlpha)
    local showSoftHeaders = transparent and textOnlyHeaderAlpha > 0
    local showIcons = ShouldShowIcons()
    local stats = GetModuleStats(self, mod)
    local isOpen = stats and stats.isOpen
    local secTotal = stats and stats.totalRows or 0
    local secDone = stats and stats.doneRows or 0
    local shownRows = stats and stats.shownRows or 0
    if shownRows == 0 then
        return nil
    end

    local allDone = (secTotal > 0) and (secDone == secTotal)
    local card = EnsureMainSectionWidget(self, mod.key)
    local expansionHeaderH = expansionHeaderKey and 22 or 0
    local sectionHeight = math.max((stats and stats.height or 0) - SECTION_GAP, HEADER_HEIGHT + 1) + expansionHeaderH
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", self.content, "TOPLEFT", xOff + 3, -yOff)
    card:SetSize(math.max(colW - 6, 1), sectionHeight)
    card:SetBackdrop(MakeBackdrop())
    if transparent then
        card:SetBackdropColor(0, 0, 0, 0)
        card:SetBackdropBorderColor(0, 0, 0, 0)
    else
        card:SetBackdropColor(0.02, 0.03, 0.05, 0.94 * frameAlpha)
        card:SetBackdropBorderColor(0.18, 0.22, 0.28, 0.95 * frameAlpha)
    end
    card._glow:SetColorTexture(0.12, 0.14, 0.18, transparent and 0 or (0.10 * frameAlpha))

    if card._expHeader then
        if expansionHeaderKey then
            local info = MR.GetExpansionInfo and MR:GetExpansionInfo(expansionHeaderKey) or nil
            local label = (info and (info.shortLabel or info.label or info.key)) or tostring(expansionHeaderKey or "")
            card._expHeader:ClearAllPoints()
            card._expHeader:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
            card._expHeader:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
            card._expHeader:SetHeight(expansionHeaderH - 3)
            card._expHeader:SetBackdropColor(0.035, 0.055, 0.070, transparent and 0 or (0.86 * frameAlpha))
            card._expHeader:SetBackdropBorderColor(0.14, 0.30, 0.34, transparent and 0 or (0.80 * frameAlpha))
            card._expHeader._label:ClearAllPoints()
            card._expHeader._label:SetPoint("LEFT", card._expHeader, "LEFT", 7, 0)
            card._expHeader._label:SetPoint("RIGHT", card._expHeader, "RIGHT", -7, 0)
            card._expHeader._label:SetFont(FONT_HEADERS, math.max(8, GetFontSize() - 1), GetFontFlags())
            card._expHeader._label:SetText(label)
            card._expHeader._label:SetTextColor(0.72, 0.86, 0.88, transparent and 0.85 or 0.95)
            card._expHeader:Show()
        else
            card._expHeader:Hide()
        end
    end

    card._hdrFrame:ClearAllPoints()
    card._hdrFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -expansionHeaderH)
    card._hdrFrame:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, -expansionHeaderH)
    card._hdrFrame:SetHeight(HEADER_HEIGHT)
    card._hdrFrame._mrMod = mod
    card._hdrFrame._mrHoverAlpha = transparent and (0.10 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.05 or 0) * frameAlpha)
    local customHeaderBg = MR.GetHeaderBackgroundColor and MR:GetHeaderBackgroundColor(mod.key) or nil
    local hdrR, hdrG, hdrB = 0.08, 0.09, 0.12
    if customHeaderBg then
        hdrR, hdrG, hdrB = hex(customHeaderBg)
    end
    card._hdrFrame._hdrBg:SetColorTexture(hdrR, hdrG, hdrB, headerAlpha)

    local explicitColor = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local customColor = MR:GetHeaderColor(mod.key)
    local headerColor = customColor or mod.labelColor or "#ffffff"
    local lr, lg, lb = hex(headerColor)
    local accentA = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 1 or 0) * frameAlpha)
    local accentR, accentG, accentB = lr, lg, lb
    if allDone then
        accentR, accentG, accentB = COL.complete[1], COL.complete[2], COL.complete[3]
    end

    card._hdrFrame._iconPlate:ClearAllPoints()
    card._hdrFrame._iconPlate:SetSize(math.max(HEADER_HEIGHT - 6, 12), math.max(HEADER_HEIGHT - 6, 12))
    card._hdrFrame._iconPlate:SetPoint("LEFT", card._hdrFrame, "LEFT", 4, 0)
    card._hdrFrame._iconPlate:SetBackdrop(MakeBackdrop())
    local iconPlateBgAlpha = transparent and (showSoftHeaders and (0.16 * accentA) or 0) or ((showSectionHeaders and 0.16 or 0) * frameAlpha)
    local iconPlateBorderAlpha = transparent and (showSoftHeaders and (0.50 * accentA) or 0) or ((showSectionHeaders and 0.50 or 0) * frameAlpha)
    card._hdrFrame._iconPlate:SetBackdropColor(accentR, accentG, accentB, iconPlateBgAlpha)
    card._hdrFrame._iconPlate:SetBackdropBorderColor(accentR, accentG, accentB, iconPlateBorderAlpha)

    local iconInfo = showIcons and ShouldShowModuleHeaderIcon(mod.key) and GetModuleIconInfo(mod) or nil
    card._hdrFrame._icon:ClearAllPoints()
    card._hdrFrame._icon:SetSize(math.max(HEADER_HEIGHT - 12, 9), math.max(HEADER_HEIGHT - 12, 9))
    card._hdrFrame._icon:SetPoint("CENTER", card._hdrFrame._iconPlate, "CENTER", 0, 0)
    local hasHeaderIcon = ApplyIconToTexture(card._hdrFrame._icon, iconInfo, { 0.14, 0.86, 0.14, 0.86 })
    card._hdrFrame._iconPlate:SetShown(hasHeaderIcon and (showIcons or showSectionHeaders))

    card._hdrFrame._label:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
    card._hdrFrame._label:ClearAllPoints()
    if hasHeaderIcon then
        card._hdrFrame._label:SetPoint("LEFT", card._hdrFrame._iconPlate, "RIGHT", 6, 0)
    else
        card._hdrFrame._label:SetPoint("LEFT", card._hdrFrame, "LEFT", 9, 0)
    end
    card._hdrFrame._label:SetJustifyH("LEFT")
    if card._hdrFrame._label.SetWordWrap then
        card._hdrFrame._label:SetWordWrap(false)
    end
    card._hdrFrame._label:SetText((allDone and not explicitColor) and WC("00ff96", mod.label) or WC(headerColor:gsub("#", ""), mod.label))

    card._hdrFrame._count:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    card._hdrFrame._count:ClearAllPoints()
    local currencyBrowserButton = card._hdrFrame._currencyBrowserButton
    local showCurrencyBrowserButton = mod.key == "currencies" and MR.ToggleCurrencyBrowserFrame
    if showCurrencyBrowserButton then
        currencyBrowserButton:ClearAllPoints()
        currencyBrowserButton:SetPoint("RIGHT", card._hdrFrame, "RIGHT", -23, 0)
        StyleCurrencyBrowserButton(currencyBrowserButton, transparent, frameAlpha)
        currencyBrowserButton:Show()
        card._hdrFrame._count:SetPoint("RIGHT", currencyBrowserButton, "LEFT", -8, 0)
    else
        currencyBrowserButton:Hide()
        card._hdrFrame._count:SetPoint("RIGHT", card._hdrFrame, "RIGHT", -22, 0)
    end
    card._hdrFrame._count:SetText(showCurrencyBrowserButton
        and string.format("%d / %d", secDone, secTotal)
        or string.format("%d / %d", secDone, secTotal))
    card._hdrFrame._count:SetTextColor(countColor(secDone, secTotal))
    card._hdrFrame._count:SetJustifyH("RIGHT")
    card._hdrFrame._label:SetPoint("RIGHT", card._hdrFrame._count, "LEFT", -8, 0)

    StyleSectionCollapseIndicator(card._hdrFrame._arrow, isOpen)

    local localY = expansionHeaderH + HEADER_HEIGHT
    card._divider:ClearAllPoints()
    card._divider:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -localY)
    card._divider:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, -localY)
    card._divider:SetHeight(1)
    card._divider:SetBackdropColor(1, 1, 1, dividerAlpha)

    local usedRows = card._usedRows or {}
    card._usedRows = usedRows
    for key in pairs(usedRows) do
        usedRows[key] = nil
    end
    if isOpen then
        localY = localY + 1
        local hideComplete = stats and stats.hideComplete
        local rows = MR.GetOrderedRows and MR:GetOrderedRows(mod) or mod.rows
        localY = RenderMainGroupedRows(self, card, mod, rows, hideComplete, localY, card:GetWidth(), usedRows, function(row, done, rowY)
            return UpdateMainRowWidget(self, card, mod, row, done, rowY, card:GetWidth())
        end)
    end

    for key, rowFrame in pairs(card._rows or {}) do
        if not usedRows[key] then
            HideMainRowWidget(rowFrame)
        end
    end

    if recordRegistry ~= false then
        AddSectionRegistryEntry(self, card, mod.key, col or 1, yOff, yOff + (stats and stats.height or 0) + expansionHeaderH, expansionHeaderKey)
    end
    return card
end

local function ClearArrayContents(t)
    if not t then
        return
    end

    for i = #t, 1, -1 do
        t[i] = nil
    end
end

function MR:RefreshMainPanelSectionsOnly()
    if not (self and self.frame and self.content and self.frame:IsShown()) then
        return false
    end

    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self._refreshUIDirty = true
        return false
    end

    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("refreshUI") then
        self._refreshUIDirty = true
        return false
    end

    RecalcLayout()
    self._moduleStatsCache = BuildModuleStatsCache(self)

    self.widgets = self.widgets or {}
    self.sectionRegistry = self.sectionRegistry or {}
    self._timerRows = self._timerRows or {}
    ClearArrayContents(self.widgets)
    ClearArrayContents(self.sectionRegistry)
    ClearArrayContents(self._timerRows)
    self._sectionRegistryCount = 0

    local allDone, allTotal = 0, 0
    local frameW = MR.db.profile.width or 260
    local usableW = frameW - 9
    local MIN_COL = 200
    local numCols = math.max(1, math.floor(usableW / MIN_COL))
    local colW = math.floor(usableW / numCols)

    local visibleMods = self._visibleModsBuffer or {}
    self._visibleModsBuffer = visibleMods
    local visibleModCount = 0
    local lastVisibleExpansionKey
    local pendingExpansionHeaderKey
    for _, mod in ipairs(MR:GetOrderedModules("all")) do
        local modVisible = not mod.isVisible or mod:isVisible()
        if MR:IsModuleEnabled(mod.key) and modVisible and not MR:IsModuleDetached(mod.key) and not (MR.ShouldHideProfessionModuleInMain and MR:ShouldHideProfessionModuleInMain(mod)) then
            local stats = GetModuleStats(self, mod)
            local doneRows = stats and stats.doneRows or 0
            local shownRows = stats and stats.shownRows or 0
            if shownRows > 0 then
                local expansionKey = MR:GetModuleExpansionKey(mod)
                if mod.profSkillLine and expansionKey ~= lastVisibleExpansionKey then
                    pendingExpansionHeaderKey = expansionKey
                    lastVisibleExpansionKey = expansionKey
                end
                visibleModCount = visibleModCount + 1
                local slot = visibleModCount
                local entry = visibleMods[slot] or {}
                entry.mod = mod
                entry.expansionKey = nil
                entry.expansionHeaderKey = pendingExpansionHeaderKey
                entry.h = (stats and stats.height or 0) + (pendingExpansionHeaderKey and 22 or 0)
                visibleMods[slot] = entry
                pendingExpansionHeaderKey = nil
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

    local activeMainSections = self._activeMainSectionsBuffer or {}
    self._activeMainSectionsBuffer = activeMainSections
    for key in pairs(activeMainSections) do
        activeMainSections[key] = nil
    end

    for i = 1, modColAssignCount do
        local assign = modColAssign[i]
        local xOff = (assign.col - 1) * colW
        if assign.mod then
            local section = UpdateMainSectionWidget(self, assign.mod, assign.yOff, xOff, colW, assign.col, true, assign.expansionHeaderKey)
            if section then
                activeMainSections[assign.mod.key] = true
                self.widgets[#self.widgets + 1] = section
            end
        end
    end

    if self._mainSectionFrames then
        for key, section in pairs(self._mainSectionFrames) do
            if not activeMainSections[key] then
                HideMainSectionWidget(section)
            end
        end
    end
    if self._mainExpansionHeaderFrames then
        for _, frame in pairs(self._mainExpansionHeaderFrames) do
            HideMainExpansionHeaderWidget(frame)
        end
    end

    for c = 2, numCols do
        local sep = EnsureMainSeparator(self, c - 1)
        sep:SetWidth(1)
        sep:ClearAllPoints()
        sep:SetPoint("TOPLEFT", self.content, "TOPLEFT", (c - 1) * colW, 0)
        sep:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", (c - 1) * colW, 0)
        self.widgets[#self.widgets + 1] = sep
    end
    if self._mainColumnSeparators then
        for index, sep in pairs(self._mainColumnSeparators) do
            if index > (numCols - 1) then
                sep:Hide()
            end
        end
    end

    if self.titleCount then
        self.titleCount:SetText(string.format("%d / %d", allDone, allTotal))
        self.titleCount:SetTextColor(countColor(allDone, allTotal))
    end

    local totalH = 0
    for c = 1, numCols do
        if cols[c] > totalH then
            totalH = cols[c]
        end
    end

    self.content:SetWidth(usableW)
    self.content:SetHeight(math.max(totalH, 1))

    if self.scroll then
        local maxScroll = math.max(math.max(totalH, 1) - self.scroll:GetHeight(), 0)
        local cur = self.scroll:GetVerticalScroll()
        if cur > maxScroll then
            self.scroll:SetVerticalScroll(maxScroll)
        end
    end

    if self.UpdateScrollBar then
        self.UpdateScrollBar()
    end

    return true
end

function MR:FastToggleMainSection(modKey)
    if not (self and self.frame and self.content and self.frame:IsShown()) then
        return false
    end

    if self._refreshUIInProgress or self._refreshUIPending or self._refreshUITimer or self._refreshRequestPending or self._refreshRequestTimer then
        return false
    end

    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self._refreshUIDirty = true
        return false
    end

    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("refreshUI") then
        self._refreshUIDirty = true
        return false
    end

    if self:IsModuleDetached(modKey) then
        return false
    end

    local mod = self.moduleByKey and self.moduleByKey[modKey]
    local section = self._mainSectionFrames and self._mainSectionFrames[modKey]
    local stats = self._moduleStatsCache and self._moduleStatsCache[modKey]
    if not (mod and section and stats and stats.shownRows and stats.shownRows > 0) then
        return false
    end

    local registryEntry
    for _, info in ipairs(self.sectionRegistry or {}) do
        if info.modKey == modKey then
            registryEntry = info
            break
        end
    end
    if not registryEntry then
        return false
    end

    RecalcLayout()
    local newOpen = not MR:IsModuleOpen(modKey)
    MR:SetModuleOpen(modKey, newOpen)
    stats.isOpen = newOpen
    stats.height = stats.shownRows == 0 and 0 or (HEADER_HEIGHT + 1 + SECTION_GAP + (newOpen and (stats.shownRows * ROW_HEIGHT) or 0))

    local frameW = MR.db.profile.width or 260
    local usableW = frameW - 9
    local MIN_COL = 200
    local numCols = math.max(1, math.floor(usableW / MIN_COL))
    if numCols ~= 1 then
        return false
    end
    local colW = math.floor(usableW / numCols)
    local xOff = ((registryEntry.col or 1) - 1) * colW

    UpdateMainSectionWidget(self, mod, registryEntry.yOff or 0, xOff, colW, registryEntry.col or 1, false, registryEntry.expansionHeaderKey)

    local colOffsets = self._fastToggleColOffsets or {}
    self._fastToggleColOffsets = colOffsets
    for i = 1, numCols do
        colOffsets[i] = 0
    end
    for i = numCols + 1, #colOffsets do
        colOffsets[i] = nil
    end

    local totalH = 0
    for _, info in ipairs(self.sectionRegistry or {}) do
        local curSection = self._mainSectionFrames and self._mainSectionFrames[info.modKey]
        local curStats = self._moduleStatsCache and self._moduleStatsCache[info.modKey]
        if curSection and curSection:IsShown() and curStats and curStats.shownRows > 0 then
            local col = math.max(1, math.min(info.col or 1, numCols))
            local yOff = colOffsets[col] or 0
            local x = (col - 1) * colW
            local expansionHeaderH = info.expansionHeaderKey and 22 or 0
            curSection:ClearAllPoints()
            curSection:SetPoint("TOPLEFT", self.content, "TOPLEFT", x + 3, -yOff)
            curSection:SetSize(math.max(colW - 6, 1), math.max((curStats.height or 0) - SECTION_GAP, HEADER_HEIGHT + 1) + expansionHeaderH)
            info.col = col
            info.yOff = yOff
            info.bottom = yOff + (curStats.height or 0) + expansionHeaderH
            colOffsets[col] = yOff + (curStats.height or 0) + expansionHeaderH
            if colOffsets[col] > totalH then
                totalH = colOffsets[col]
            end
        end
    end

    for c = 2, numCols do
        local sep = EnsureMainSeparator(self, c - 1)
        sep:SetWidth(1)
        sep:ClearAllPoints()
        sep:SetPoint("TOPLEFT", self.content, "TOPLEFT", (c - 1) * colW, 0)
        sep:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", (c - 1) * colW, 0)
    end
    if self._mainColumnSeparators then
        for index, sep in pairs(self._mainColumnSeparators) do
            sep:SetShown(index <= (numCols - 1))
        end
    end

    self.content:SetWidth(usableW)
    self.content:SetHeight(math.max(totalH, 1))
    if self.scroll then
        local maxScroll = math.max(math.max(totalH, 1) - self.scroll:GetHeight(), 0)
        local cur = self.scroll:GetVerticalScroll()
        if cur > maxScroll then
            self.scroll:SetVerticalScroll(maxScroll)
        end
    end
    if self.UpdateScrollBar then
        self.UpdateScrollBar()
    end

    return true
end

IsMainTextOnlyMode = function()
    if not (MR and MR.db and MR.db.profile) then
        return false
    end

    if MR.db.profile.transparentMode then
        return true
    end

    return (MR.db.profile.frameAlpha or 1.0) <= 0.01
end

GetTextOnlyHeaderAlpha = function()
    if not (MR and MR.db and MR.db.profile) then
        return 0
    end

    if not IsMainTextOnlyMode() then
        return 0
    end

    if MR.db.profile.keepHeadersVisibleInTextMode == false then
        return 0
    end

    return 0.32
end

ShouldShowIcons = function()
    if not (MR and MR.db and MR.db.profile) then
        return false
    end

    return MR.db.profile.keepIconsVisibleInTextMode ~= false
end

ShouldShowSectionHeaders = function()
    if not (MR and MR.db and MR.db.profile) then
        return false
    end

    return MR.db.profile.keepHeadersVisibleInTextMode ~= false
end

local MODULE_ICON_FALLBACKS = {
    currencies          = { texture = "Interface\\Icons\\INV_Misc_Coin_17" },
    midnight_activities = { texture = "Interface\\Icons\\Ability_Creature_Cursed_04" },
    omnium_folio        = { texture = "Interface\\Icons\\INV_Enchant_VoidSphere" },
    pvp_currencies      = { texture = "Interface\\TargetingFrame\\UI-PVP-FFA" },
    pvp_weeklies        = { texture = "Interface\\TargetingFrame\\UI-PVP-HORDE" },
    s1_weekly           = { texture = "Interface\\Icons\\INV_Misc_Note_01" },
    world_bosses        = { texture = "Interface\\Icons\\Ability_Hunter_BeastCall" },
    timewalking         = { texture = "Interface\\Icons\\Achievement_Quests_Completed_08" },
    prof_alchemy        = { texture = "Interface\\Icons\\Trade_Alchemy" },
    prof_blacksmithing  = { texture = "Interface\\Icons\\Trade_BlackSmithing" },
    prof_enchanting     = { texture = "Interface\\Icons\\Trade_Engraving" },
    prof_engineering    = { texture = "Interface\\Icons\\Trade_Engineering" },
    prof_herbalism      = { texture = "Interface\\Icons\\Trade_Herbalism" },
    prof_inscription    = { texture = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
    prof_jewelcrafting  = { texture = "Interface\\Icons\\INV_Misc_Gem_01" },
    prof_leatherworking = { texture = "Interface\\Icons\\INV_Misc_ArmorKit_17" },
    prof_mining         = { texture = "Interface\\Icons\\Trade_Mining" },
    prof_skinning       = { texture = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
    prof_tailoring      = { texture = "Interface\\Icons\\Trade_Tailoring" },
    skin_lures          = { texture = "Interface\\Icons\\INV_Misc_Food_50" },
}

local MODULE_HEADER_ICON_KEYS = {
    currencies = true,
    delves = true,
    great_vault = true,
    midnight_activities = true,
    omnium_folio = true,
    prey = true,
    pvp_currencies = true,
    pvp_weeklies = true,
    s1_weekly = true,
    timewalking = true,
    world_bosses = true,
    prof_alchemy = true,
    prof_blacksmithing = true,
    prof_enchanting = true,
    prof_engineering = true,
    prof_herbalism = true,
    prof_inscription = true,
    prof_jewelcrafting = true,
    prof_leatherworking = true,
    prof_mining = true,
    prof_skinning = true,
    prof_tailoring = true,
    skin_lures = true,
}

ShouldShowModuleHeaderIcon = function(modKey)
    return false
end

GetModuleFallbackIconInfo = function(modKey)
    if not modKey or modKey == "" then
        return nil
    end

    local exact = MODULE_ICON_FALLBACKS[modKey]
    if exact then
        return exact
    end

    if modKey:match("^story_campaign_") then
        return { texture = "Interface\\GossipFrame\\AvailableQuestIcon" }
    end

    return nil
end

local ROW_ICON_FALLBACKS = {
    vault_raid          = { texture = "Interface\\LFGFrame\\LFGICON-RAIDFINDER" },
    vault_dungeon       = { texture = "Interface\\LFGFrame\\LFGICON-HEROICDUNGEON" },
    vault_world         = { texture = "Interface\\Icons\\INV_Misc_Map_01" },
    sparks_of_war       = { texture = "Interface\\TargetingFrame\\UI-PVP-FFA" },
    preparing_battle    = { texture = "Interface\\Icons\\Ability_Warrior_BattleShout" },
    something_different = { texture = "Interface\\Icons\\Achievement_BG_winBrawl" },
    early_training      = { texture = "Interface\\Icons\\INV_Sword_04" },
    call_to_delves      = { texture = "Interface\\Icons\\INV_Misc_Spyglass_03" },
    abundance           = { texture = "Interface\\Icons\\INV_Enchant_VoidSphere" },
    lost_legends        = { texture = "Interface\\Icons\\Achievement_Quests_Completed_08" },
    saltherils_soiree   = { texture = "Interface\\Icons\\INV_Drink_11" },
    fortify_runestones  = { texture = "Interface\\Icons\\INV_Stone_15" },
    unity_against_void  = { texture = "Interface\\Icons\\Spell_Shadow_ArcaneTorrent" },
    special_assignment  = { texture = "Interface\\Icons\\INV_Letter_15" },
    tw_dungeon          = { texture = "Interface\\LFGFrame\\LFGICON-HEROICDUNGEON" },
    tw_raid             = { texture = "Interface\\LFGFrame\\LFGICON-RAIDFINDER" },
}

NormalizeIconInfo = function(info)
    if not info then
        return nil
    end

    if type(info) == "number" then
        return { texture = info }
    end

    if type(info) == "string" then
        return { texture = info }
    end

    if type(info) == "table" then
        return {
            atlas = info.atlas,
            texture = info.texture or info.tex or info.fileID,
            texCoord = info.texCoord,
            tint = info.tint,
        }
    end

    return nil
end

GetRowIconInfo = function(mod, row)
    if not row then
        return nil
    end

    local explicit = NormalizeIconInfo(row.icon)
    if explicit then
        return explicit
    end

    if row.currencyId and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(row.currencyId)
        if info and info.iconFileID then
            return { texture = info.iconFileID }
        end
    end

    local itemId = row.itemId or row.itemID
    if itemId and C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(itemId)
        if icon then
            return { texture = icon }
        end
    end

    if row.spellId then
        local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(row.spellId) or GetSpellTexture(row.spellId)
        if icon then
            return { texture = icon }
        end
    end

    local fallback = ROW_ICON_FALLBACKS[row.key]
    if fallback then
        return fallback
    end

    return GetModuleFallbackIconInfo(mod and mod.key or "")
end

GetModuleIconInfo = function(mod)
    if not mod then
        return nil
    end

    if mod.key == "great_vault" then
        local keyIcon = GetRowIconInfo(nil, { currencyId = 3028 })
        if keyIcon then
            return keyIcon
        end
    end

    local explicit = NormalizeIconInfo(mod.icon)
    if explicit then
        return explicit
    end

    if mod.rows then
        local rows = MR.GetOrderedRows and MR:GetOrderedRows(mod) or mod.rows
        for _, row in ipairs(rows) do
            local rowIcon = GetRowIconInfo(mod, row)
            if rowIcon then
                return rowIcon
            end
        end
    end

    return GetModuleFallbackIconInfo(mod.key)
end

ApplyIconToTexture = function(texture, info, fallbackTexCoord)
    if not texture then
        return false
    end

    info = NormalizeIconInfo(info)
    if not info then
        texture:Hide()
        return false
    end

    texture:Show()
    if info.atlas and texture.SetAtlas then
        texture:SetAtlas(info.atlas, true)
        texture:SetTexCoord(0, 1, 0, 1)
    else
        texture:SetTexture(info.texture)
        if info.texCoord then
            texture:SetTexCoord(unpack(info.texCoord))
        elseif fallbackTexCoord then
            texture:SetTexCoord(unpack(fallbackTexCoord))
        else
            texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
    end

    if info.tint then
        texture:SetVertexColor(info.tint[1] or 1, info.tint[2] or 1, info.tint[3] or 1, info.tint[4] or 1)
    else
        texture:SetVertexColor(1, 1, 1, 1)
    end

    return true
end

local function CurrencyInfoHasAnyFlag(info, ...)
    if type(info) ~= "table" then
        return false
    end

    for i = 1, select("#", ...) do
        local key = select(i, ...)
        if info[key] then
            return true
        end
    end

    return false
end

local function IsCurrencyWarbandTransferable(currencyID, info)
    if CurrencyInfoHasAnyFlag(
        info,
        "isAccountTransferable",
        "isWarbandTransferable",
        "isTransferable",
        "transferable"
    ) then
        return true
    end

    if C_CurrencyInfo then
        local candidates = {
            "IsCurrencyAccountTransferable",
            "IsCurrencyTransferable",
            "IsAccountTransferableCurrency",
        }
        for _, methodName in ipairs(candidates) do
            local method = C_CurrencyInfo[methodName]
            if type(method) == "function" then
                local ok, result = pcall(method, currencyID)
                if ok and result then
                    return true
                end
            end
        end
    end

    return false
end

local function GetCurrencyWarbandKind(currencyID)
    if not (currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return nil
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info then
        return nil
    end

    if info.isAccountWide then
        return "account", info
    end

    if IsCurrencyWarbandTransferable(currencyID, info) then
        return "transfer", info
    end

    return nil, info
end

function MR:GetCurrencyWarbandMarkerInfo(currencyID)
    local kind = GetCurrencyWarbandKind(currencyID)
    if kind == "account" then
        return {
            atlas = "warbands-icon",
            text = ACCOUNT_LEVEL_CURRENCY or "Warband Currency",
        }
    elseif kind == "transfer" then
        return {
            atlas = "warbands-transferable-icon",
            text = ACCOUNT_TRANSFERRABLE_CURRENCY or "Warband Transferable",
        }
    end

    return nil
end

function MR:AddCurrencyTransferTooltipLines(tooltip, currencyID)
    if not (tooltip and currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return false
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not IsCurrencyWarbandTransferable(currencyID, info) then
        return false
    end

    local percentage = tonumber(info and (info.transferPercentage or info.accountTransferPercentage or info.currencyTransferPercentage))
    tooltip:AddLine(" ")
    if percentage and percentage > 0 then
        tooltip:AddLine(string.format("Warband Transfer: %d%%", percentage), 0.45, 0.85, 1, true)
    else
        tooltip:AddLine("Warband Transferable", 0.45, 0.85, 1, true)
    end
    return true
end

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
        characterBar:SetShown(characterBarHeight > 0 and not (MR.db and MR.db.profile and MR.db.profile.minimized))
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
        if headerBottom then
            scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
            scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -9, chromeHeight + 6)
        else
            scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -(chromeHeight + 6))
            scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -9, 4)
        end
    end

    if track and scroll then
        track:ClearAllPoints()
        track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 1, 0)
        track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    end

    if dragger then
        dragger:ClearAllPoints()
        if headerBottom then
            dragger:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
        else
            dragger:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        end
    end

    ApplyMainFrameAnchor(frame, GetMainHeaderPosition(), preserveScreenPosition == true)
end

ns.GetMainHeaderPosition     = GetMainHeaderPosition
ns.IsAnimatedMinimizeEnabled = IsAnimatedMinimizeEnabled
ns.ApplyMainFrameLayout      = ApplyMainFrameLayout

local function SetMainFrameChromeVisible(visible)
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
    local h = MR.db.profile.height or 400

    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetWidth(w)
    f:SetHeight(h)
    f:SetFrameStrata("MEDIUM")
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
        if MR._refreshUIDirty or MR._mainPanelNeedsRefresh then
            MR:RefreshUI()
        end
    end)

    local scrollBg = f:CreateTexture(nil, "BACKGROUND")
    ApplyBackgroundTexture(scrollBg, COL.bg[1], COL.bg[2], COL.bg[3], 0.96)
    MR._scrollBg = scrollBg

    local titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    MR._titleBar = titleBar
    titleBar:SetHeight(GetMainHeaderHeight())
    titleBar:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(titleBar) end
    titleBar:SetBackdropColor(0.03, 0.06, 0.12, 0.98)
    titleBar:SetBackdropBorderColor(0.17, 0.24, 0.32, 1)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
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
    title:SetFont(FONT_HEADERS, math.max(8, GetFontSize() - 2), GetFontFlags())
    title:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
    title:SetPoint("RIGHT", titleBar, "RIGHT", -110, 0)
    title:SetJustifyH("LEFT")
    title:SetText(L["Title"])
    self.titleText = title

    local titleCount = titleBar:CreateFontString(nil, "OVERLAY")
    titleCount:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    titleCount:SetTextColor(0.84, 0.88, 0.90)
    self.titleCount = titleCount

    local BTN_SIZE   = 20
    local BTN_PAD    = 4
    local BTN_MARGIN = 8

    local function MakeHeaderBtn(icon, normalColor, hoverBg, hoverBorder, tooltipText, tooltipSub)
        local btn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
        btn:SetSize(BTN_SIZE, BTN_SIZE)
        btn:SetBackdrop(MakeBackdrop())
        btn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
        btn:SetBackdropBorderColor(0.18, 0.23, 0.30, 0.95)

        local iconObj
        if icon.tex then
            local t = btn:CreateTexture(nil, "OVERLAY")
            t:SetSize(BTN_SIZE - 6, BTN_SIZE - 6)
            t:SetPoint("CENTER", btn, "CENTER", 0, 0)
            t:SetTexture(icon.tex)
            t:SetVertexColor(normalColor[1], normalColor[2], normalColor[3])
            iconObj = t
            btn._iconTex = t
        else
            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_HEADERS, 11, GetFontFlags())
            lbl:SetPoint("CENTER", btn, "CENTER", 0, 1)
            lbl:SetText(icon.text)
            lbl:SetTextColor(normalColor[1], normalColor[2], normalColor[3])
            iconObj = lbl
            btn._lbl = lbl
        end

        btn._normalColor = normalColor
        btn._iconObj     = iconObj
        btn._isTexture   = (icon.tex ~= nil)

        btn:SetScript("OnEnter", function(s)
            btn:SetBackdropColor(hoverBg[1], hoverBg[2], hoverBg[3], 1)
            btn:SetBackdropBorderColor(hoverBorder[1], hoverBorder[2], hoverBorder[3], 1)
            if btn._isTexture then
                btn._iconObj:SetVertexColor(1, 1, 1)
            else
                btn._iconObj:SetTextColor(1, 1, 1)
            end
            if tooltipText then
                GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
                GameTooltip:SetText(tooltipText, 1, 1, 1)
                if tooltipSub then GameTooltip:AddLine(tooltipSub, 0.6, 0.6, 0.6) end
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function()
            btn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
            btn:SetBackdropBorderColor(0.18, 0.23, 0.30, 0.95)
            if btn._isTexture then
                btn._iconObj:SetVertexColor(normalColor[1], normalColor[2], normalColor[3])
            else
                btn._iconObj:SetTextColor(normalColor[1], normalColor[2], normalColor[3])
            end
            GameTooltip:Hide()
        end)
        return btn
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
        if MR.HideCurrencyBrowserFrame then
            MR:HideCurrencyBrowserFrame()
        end
        f:Hide()
        MR.db.char.panelOpen = false
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
            GameTooltip:AddLine(L["Options_Glow"], 1, 1, 1)
            GameTooltip:AddLine(L["UI_ModularHint"], 0.9, 0.85, 0.3)
            GameTooltip:Show()
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
    warbandText:SetFont(FONT_HEADERS, 9, GetFontFlags())
    warbandText:SetPoint("CENTER", warbandBtn, "CENTER", 0, 1)
    warbandText:SetText(L["AltBoard_ButtonLabel"] or "ALTS")
    warbandText:SetTextColor(0.84, 0.92, 0.96)
    self.warbandBtnText = warbandText
    warbandBtn:SetScript("OnEnter", function(selfBtn)
        selfBtn:SetBackdropColor(0.11, 0.17, 0.24, 1)
        selfBtn:SetBackdropBorderColor(0.42, 0.62, 0.76, 1)
        warbandText:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(selfBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["AltBoard_OpenTooltip"] or "Open Alt Weekly Board", 1, 1, 1)
        GameTooltip:AddLine(L["AltBoard_OpenTooltipSub"] or "Browse every tracked alt and see exactly what is done, in progress, or untouched this week.", 0.6, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    warbandBtn:SetScript("OnLeave", function(selfBtn)
        selfBtn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
        selfBtn:SetBackdropBorderColor(0.24, 0.31, 0.38, 0.95)
        warbandText:SetTextColor(0.84, 0.92, 0.96)
        GameTooltip:Hide()
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
    characterName:SetFont(FONT_HEADERS, math.max(9, GetFontSize() - 2), GetFontFlags())
    characterName:SetPoint("LEFT", characterIconPlate, "RIGHT", 6, 0)
    characterName:SetJustifyH("LEFT")
    characterName:SetWordWrap(false)

    local characterRealm = characterBar:CreateFontString(nil, "OVERLAY")
    characterRealm:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 3), GetFontFlags())
    characterRealm:SetPoint("LEFT", characterName, "RIGHT", 5, 0)
    characterRealm:SetPoint("RIGHT", characterBar, "RIGHT", -28, 0)
    characterRealm:SetJustifyH("LEFT")
    characterRealm:SetWordWrap(false)
    characterRealm:SetTextColor(0.42, 0.60, 0.64)

    local characterCaret = characterBar:CreateFontString(nil, "OVERLAY")
    characterCaret:SetFont(FONT_HEADERS, 9, GetFontFlags())
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
        GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["AltPicker_OpenTooltip"] or "Open Alt Picker", 1, 1, 1)
        GameTooltip:AddLine(L["AltPicker_OpenTooltipSub"] or "Pick an alt to show its saved progress in the main frame.", 0.6, 0.85, 0.85, true)
        GameTooltip:Show()
    end)
    characterBar:SetScript("OnLeave", function(selfBtn)
        selfBtn:SetBackdropColor(0.020, 0.040, 0.060, 0.96)
        selfBtn:SetBackdropBorderColor(0.08, 0.16, 0.22, 0.45)
        characterCaret:SetTextColor(0.48, 0.72, 0.74)
        GameTooltip:Hide()
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
        characterName:SetFont(FONT_HEADERS, math.max(9, metrics.fontSize - 2), GetFontFlags())
        characterRealm:SetFont(FONT_ROWS, math.max(8, metrics.fontSize - 3), GetFontFlags())
        if cfgBtn._iconTex then
            cfgBtn._iconTex:SetSize(metrics.buttonSize - 5, metrics.buttonSize - 5)
        end
        if closeBtn._lbl then
            closeBtn._lbl:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 1), GetFontFlags())
        end
        if minBtn._lbl then
            minBtn._lbl:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 1), GetFontFlags())
        end
        title:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 2), GetFontFlags())
        titleCount:SetFont(FONT_ROWS, math.max(8, metrics.fontSize - 2), GetFontFlags())
        warbandText:SetFont(FONT_HEADERS, math.max(8, metrics.fontSize - 2), GetFontFlags())
        UpdateCharacterBar()
        ApplyMainFrameLayout(f)
    end
    self.RefreshMainHeaderChrome = RefreshMainHeaderChrome
    RefreshMainHeaderChrome()

    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:EnableMouseWheel(true)
    self.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth((MR.db.profile.width or 260) - 9)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    self.content = content

    local track = CreateFrame("Frame", nil, f)
    self._scrollTrack = track
    track:SetPoint("TOPLEFT",    scroll, "TOPRIGHT",    1, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    track:SetWidth(5)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0, 0, 0, 0.3)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(5)
    thumb:EnableMouse(true)
    thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(0.25, 0.65, 0.65, 0.75)

    local function UpdateScrollBar()
        local viewH    = scroll:GetHeight()
        local contentH = content:GetHeight()
        if contentH <= viewH or viewH <= 0 then thumb:Hide() return end
        thumb:Show()
        local trackH = math.max(track:GetHeight(), 1)
        local thumbH = math.max(trackH * (viewH / contentH), 14)
        local pct    = scroll:GetVerticalScroll() / (contentH - viewH)
        thumb:SetHeight(thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -((trackH - thumbH) * pct))
    end

    local function SetScrollFromCursor(cursorY, grabOffset)
        local viewH = scroll:GetHeight()
        local contentH = content:GetHeight()
        local maxScroll = math.max(contentH - viewH, 0)
        if maxScroll <= 0 then
            scroll:SetVerticalScroll(0)
            UpdateScrollBar()
            return
        end

        local trackTop = track:GetTop()
        local trackBottom = track:GetBottom()
        if not trackTop or not trackBottom then return end

        local trackH = math.max(trackTop - trackBottom, 1)
        local thumbH = thumb:GetHeight()
        local movable = math.max(trackH - thumbH, 1)
        local offset = grabOffset or (thumbH * 0.5)
        local y = math.max(0, math.min((trackTop - cursorY) - offset, movable))
        local pct = y / movable
        scroll:SetVerticalScroll(maxScroll * pct)
        UpdateScrollBar()
    end

    track:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or not thumb:IsShown() then return end
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / UIParent:GetEffectiveScale()
        SetScrollFromCursor(cursorY, thumb:GetHeight() * 0.5)
        thumb._dragging = true
        thumb._grabOffset = thumb:GetHeight() * 0.5
        thumb:SetScript("OnUpdate", function(self)
            if not IsMouseButtonDown("LeftButton") then
                self._dragging = nil
                self._grabOffset = nil
                self:SetScript("OnUpdate", nil)
                return
            end

            local _, dragCursorY = GetCursorPosition()
            dragCursorY = dragCursorY / UIParent:GetEffectiveScale()
            SetScrollFromCursor(dragCursorY, self._grabOffset)
        end)
    end)

    thumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or not self:IsShown() then return end
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / UIParent:GetEffectiveScale()
        local thumbTop = self:GetTop()
        self._grabOffset = thumbTop and (thumbTop - cursorY) or (self:GetHeight() * 0.5)
        self._dragging = true
        self:SetScript("OnUpdate", function(btn)
            if not IsMouseButtonDown("LeftButton") then
                btn._dragging = nil
                btn._grabOffset = nil
                btn:SetScript("OnUpdate", nil)
                return
            end

            local _, dragCursorY = GetCursorPosition()
            dragCursorY = dragCursorY / UIParent:GetEffectiveScale()
            SetScrollFromCursor(dragCursorY, btn._grabOffset)
        end)
    end)

    thumb:SetScript("OnMouseUp", function(self)
        self._dragging = nil
        self._grabOffset = nil
        self:SetScript("OnUpdate", nil)
    end)

    scroll:SetScript("OnMouseWheel", function(_, delta)
        local cur = scroll:GetVerticalScroll()
        local max = math.max(content:GetHeight() - scroll:GetHeight(), 0)
        scroll:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, max)))
        UpdateScrollBar()
    end)
    scroll:SetScript("OnScrollRangeChanged", function() UpdateScrollBar() end)
    scroll:SetScript("OnVerticalScroll",     function() UpdateScrollBar() end)
    self.UpdateScrollBar = UpdateScrollBar

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
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not MR.db.profile.locked then
            dragStartW = f:GetWidth()
            dragStartH = f:GetHeight()
            dragStartX, dragStartY = GetCursorPosition()
            local scale = f:GetEffectiveScale()
            dragStartX = dragStartX / scale
            dragStartY = dragStartY / scale
            dragger._dragging = true
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            local newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, math.floor(f:GetWidth())))
            local newH = math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, math.floor(f:GetHeight())))
            MR.db.profile.width  = newW
            MR.db.profile.height = newH
            f:SetWidth(newW)
            f:SetHeight(newH)
            MR:RefreshUI()
            local configFrame = MR.GetConfigFrame and MR:GetConfigFrame()
            if configFrame and configFrame:IsShown() then MR:PopulateConfigFrame(configFrame) end
        end
    end)
    dragger:SetScript("OnUpdate", function()
        if not dragger._dragging then return end
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
    end)
    self._dragger = dragger

    self._timerRows = {}
    local _tick = 0
    local tickFrame = CreateFrame("Frame")
    tickFrame:SetScript("OnUpdate", function(_, elapsed)
        _tick = _tick + elapsed
        if _tick < 1 then return end
        _tick = 0
        for _, f in ipairs(MR._timerRows) do
            if f:IsShown() and f._timerUpdate then
                f._timerUpdate()
            end
        end
    end)
    self._tickFrame = tickFrame

    ApplyMainFrameLayout(f)
    self:RefreshUI()
    ApplyTheme()
end

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
    title:SetFrameStrata("MEDIUM")
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
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        local cur = scroll:GetVerticalScroll()
        local max = math.max(content:GetHeight() - scroll:GetHeight(), 0)
        scroll:SetVerticalScroll(math.max(0, math.min(cur - delta * 24, max)))
    end)

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
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not MR.db.profile.locked then
            dragStartW = title:GetWidth()
            dragStartH = title:GetHeight()
            dragStartX, dragStartY = GetCursorPosition()
            local scale = title:GetEffectiveScale()
            dragStartX = dragStartX / scale
            dragStartY = dragStartY / scale
            dragger._dragging = true
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            local newW = math.max(180, math.min(PANEL_MAX_WIDTH, math.floor(title:GetWidth())))
            local newH = math.max(HEADER_HEIGHT + 48, math.min(PANEL_MAX_HEIGHT, math.floor(title:GetHeight())))
            title:SetWidth(newW)
            title:SetHeight(newH)
            MR:SetDetachedModuleSize(mod.key, newW, newH)
            MR:RefreshUI()
        end
    end)
    dragger:SetScript("OnUpdate", function()
        if not dragger._dragging then return end
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
    end)

    frame = title
    frame.scroll = scroll
    frame.content = content
    frame._dragBar = dragBar
    frame._dragAccent = dragAccent
    frame._dragger = dragger
    frame._widgets = {}
    frame._modKey = mod.key
    frame:SetScript("OnShow", function()
        if MR._refreshUIDirty or frame._needsRefresh then
            MR:RefreshUI()
        end
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

    for _, mod in ipairs(MR:GetOrderedModules("all")) do
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

function MR:RefreshUI()
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self._refreshUIDirty = true
        return
    end

    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("refreshUI") then
        self._refreshUIDirty = true
        return
    end

    if not self.frame or not self.content then
        self._refreshUIDirty = true
        return
    end

    if not self:CanRefreshUIImmediately() then
        self._refreshUIDirty = true
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

    self._refreshUIInProgress = true
    self._refreshUIDirty = nil

    RecalcLayout()
    self._moduleStatsCache = BuildModuleStatsCache(self)
    local expansionInfo = ns.GetExpansionDisplayInfo(false)
    local refreshMain = self.frame and self.frame:IsShown()

    if not refreshMain then
        self._mainPanelNeedsRefresh = true
    end

    if refreshMain then
        self._mainPanelNeedsRefresh = nil

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
        local pendingExpansionHeaderKey
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
                        pendingExpansionHeaderKey = expansionKey
                        lastVisibleExpansionKey = expansionKey
                    end
                    visibleModCount = visibleModCount + 1
                    local slot = visibleModCount
                    local entry = visibleMods[slot] or {}
                    entry.mod = mod
                    entry.expansionKey = nil
                    entry.expansionHeaderKey = pendingExpansionHeaderKey
                    entry.h = h + (pendingExpansionHeaderKey and 22 or 0)
                    visibleMods[slot] = entry
                    pendingExpansionHeaderKey = nil
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

        local activeMainSections = self._activeMainSectionsBuffer or {}
        self._activeMainSectionsBuffer = activeMainSections
        for key in pairs(activeMainSections) do
            activeMainSections[key] = nil
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
            end
        end

        if self._mainSectionFrames then
            for key, section in pairs(self._mainSectionFrames) do
                if not activeMainSections[key] then
                    HideMainSectionWidget(section)
                end
            end
        end
        if self._mainExpansionHeaderFrames then
            for _, frame in pairs(self._mainExpansionHeaderFrames) do
                HideMainExpansionHeaderWidget(frame)
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
        self.frame:SetHeight(math.max(PANEL_MIN_HEIGHT, math.min(userH, PANEL_MAX_HEIGHT)))

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

    self:RefreshVisibleDetachedFrames()

    if self.altBoardFrame and self.altBoardFrame:IsShown() and self.RequestWarbandBoardRefresh then
        self:RequestWarbandBoardRefresh(false)
    end

    self._moduleStatsCache = nil
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
        self.titleText:SetFont(FONT_HEADERS, math.max(8, fontSize - 2), GetFontFlags())
    end
    if self.titleCount then
        self.titleCount:SetFont(FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
    end
    if self.warbandBtnText then
        self.warbandBtnText:SetFont(FONT_HEADERS, 9, GetFontFlags())
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
            frame.titleText:SetFont(FONT_HEADERS, math.max(12, fontSize + 2), GetFontFlags())
        end
        if frame.summaryValue then
            frame.summaryValue:SetFont(FONT_HEADERS, math.max(11, fontSize + 1), GetFontFlags())
        end
        if frame.summarySub then
            frame.summarySub:SetFont(FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
        end
        if frame.leftLabel then
            frame.leftLabel:SetFont(FONT_ROWS, math.max(9, fontSize), GetFontFlags())
        end
        if frame.showHiddenLabel then
            frame.showHiddenLabel:SetFont(FONT_ROWS, 9, GetFontFlags())
        end
        if frame.hideCompletedLabel then
            frame.hideCompletedLabel:SetFont(FONT_ROWS, 9, GetFontFlags())
        end
        if frame.heroName then
            frame.heroName:SetFont(FONT_HEADERS, math.max(13, fontSize + 3), GetFontFlags())
        end
        if frame.heroMeta then
            frame.heroMeta:SetFont(FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
        end
        if frame.heroStatus then
            frame.heroStatus:SetFont(FONT_ROWS, math.max(10, fontSize), GetFontFlags())
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

function MR:IsRowComplete(mod, row, done)
    if mod and (mod.key == "currencies" or mod.key == "pvp_currencies") and not self:IsModuleHideComplete(mod.key) then
        return false
    end
    if row.completeFunc then
        return row.completeFunc(done, row, mod) == true
    end
    return row.max and not row.noMax and done >= row.max
end

BuildModuleStatsCache = function(self)
    local cache = self._moduleStatsCache or {}
    local seen = self._moduleStatsSeen or {}
    self._moduleStatsSeen = seen

    for _, mod in ipairs(MR:GetOrderedModules("all")) do
        local hideComplete = MR:IsModuleHideComplete(mod.key)
        local isOpen = MR:IsModuleOpen(mod.key)
        local totalRows, doneRows, shownRows = 0, 0, 0
        local height = HEADER_HEIGHT + 1 + SECTION_GAP

        local rows = MR.GetOrderedRows and MR:GetOrderedRows(mod) or mod.rows
        local rowsByGroup = GetVisibleRowsByGroup(mod, rows)
        local lastGroup
        for _, row in ipairs(rows) do
            local rowVisible = MR.IsRowVisibleForCharacter and MR:IsRowVisibleForCharacter(mod, row) or (not row.isVisible or row.isVisible())
            local group = GetMainRowGroupKey(row)
            if rowVisible and group and group ~= lastGroup and rowsByGroup[group] and ShouldRenderMainRowGroupHeader(self, mod, rowsByGroup[group], hideComplete) then
                shownRows = shownRows + 1
                if isOpen then
                    height = height + ROW_HEIGHT
                end
            end
            lastGroup = group

            if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
                local done = MR:GetProgress(mod.key, row.key)
                local countsForTotals = not row.control
                local isComplete = countsForTotals and self:IsRowComplete(mod, row, done) or false
                if countsForTotals then
                    totalRows = totalRows + 1
                    if isComplete then
                        doneRows = doneRows + 1
                    end
                end

                if row.control or not (hideComplete and isComplete) then
                    shownRows = shownRows + 1
                    if isOpen then
                        height = height + ROW_HEIGHT
                    end
                end
            end
        end

        if shownRows == 0 then
            height = 0
        end

        local entry = cache[mod.key] or {}
        entry.doneRows = doneRows
        entry.height = height
        entry.hideComplete = hideComplete
        entry.isOpen = isOpen
        entry.shownRows = shownRows
        entry.totalRows = totalRows
        cache[mod.key] = entry
        seen[mod.key] = true
    end

    for key in pairs(cache) do
        if not seen[key] then
            cache[key] = nil
        end
        seen[key] = nil
    end

    return cache
end

GetModuleStats = function(self, mod)
    local cache = self._moduleStatsCache
    if cache and cache[mod.key] then
        return cache[mod.key]
    end

    local fallback = BuildModuleStatsCache(self)
    return fallback[mod.key]
end

function MR:MeasureSection(mod)
    local stats = GetModuleStats(self, mod)
    return stats and stats.height or 0
end

function MR:GetModuleRowStats(mod)
    local stats = GetModuleStats(self, mod)
    if not stats then
        return 0, 0, 0
    end

    return stats.totalRows, stats.doneRows, stats.shownRows
end

function MR:BuildSection(mod, yOff, xOff, colW, col, parent, widgetBucket, opts)
    parent = parent or self.content
    widgetBucket = widgetBucket or self.widgets
    opts = opts or {}
    local transparent = IsMainTextOnlyMode()
    local frameAlpha = MR.db.profile.frameAlpha or 1.0
    local showSectionHeaders = ShouldShowSectionHeaders()
    local textOnlyHeaderAlpha = showSectionHeaders and GetTextOnlyHeaderAlpha() or 0
    local headerAlpha = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 0.90 or 0) * frameAlpha)
    local dividerAlpha = transparent and (0.50 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.09 or 0) * frameAlpha)
    local showSoftHeaders = transparent and textOnlyHeaderAlpha > 0
    local showIcons = ShouldShowIcons()
    local stats = GetModuleStats(self, mod)
    local isOpen = stats and stats.isOpen
    local secTotal = stats and stats.totalRows or 0
    local secDone = stats and stats.doneRows or 0
    local shownRows = stats and stats.shownRows or 0
    if shownRows == 0 then
        return yOff
    end
    local allDone = (secTotal > 0) and (secDone == secTotal)

    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff + 3, -yOff)
    card:SetSize(math.max(colW - 6, 1), math.max((stats and stats.height or 0) - SECTION_GAP, HEADER_HEIGHT + 1))
    card:SetBackdrop(MakeBackdrop())
    if transparent then
        card:SetBackdropColor(0, 0, 0, 0)
        card:SetBackdropBorderColor(0, 0, 0, 0)
    else
        card:SetBackdropColor(0.02, 0.03, 0.05, 0.94 * frameAlpha)
        card:SetBackdropBorderColor(0.18, 0.22, 0.28, 0.95 * frameAlpha)
    end
    table.insert(widgetBucket, card)

    local cardGlow = card:CreateTexture(nil, "BACKGROUND")
    cardGlow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    cardGlow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    cardGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
    cardGlow:SetColorTexture(0.12, 0.14, 0.18, transparent and 0 or (0.10 * frameAlpha))

    local hdrFrame = CreateFrame("Frame", nil, card)
    hdrFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    hdrFrame:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    hdrFrame:SetHeight(HEADER_HEIGHT)
    hdrFrame:EnableMouse(true)
    if opts.detached then
        hdrFrame:RegisterForDrag("LeftButton")
    end

    local hdrBg = hdrFrame:CreateTexture(nil, "BACKGROUND")
    hdrBg:SetAllPoints()
    local customHeaderBg = MR.GetHeaderBackgroundColor and MR:GetHeaderBackgroundColor(mod.key) or nil
    local hdrR, hdrG, hdrB = 0.08, 0.09, 0.12
    if customHeaderBg then
        hdrR, hdrG, hdrB = hex(customHeaderBg)
    end
    hdrBg:SetColorTexture(hdrR, hdrG, hdrB, headerAlpha)

    local hdrHover = hdrFrame:CreateTexture(nil, "BORDER")
    hdrHover:SetAllPoints()
    hdrHover:SetColorTexture(1, 1, 1, 0)

    local explicitColor = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local customColor = MR:GetHeaderColor(mod.key)
    local headerColor = customColor or mod.labelColor or "#ffffff"
    local lr,lg,lb = hex(headerColor)
    local accentA = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 1 or 0) * frameAlpha)
    local accentR, accentG, accentB = lr, lg, lb
    if allDone then
        accentR, accentG, accentB = COL.complete[1], COL.complete[2], COL.complete[3]
    end

    local iconPlate = CreateFrame("Frame", nil, hdrFrame, "BackdropTemplate")
    iconPlate:SetSize(math.max(HEADER_HEIGHT - 6, 12), math.max(HEADER_HEIGHT - 6, 12))
    iconPlate:SetPoint("LEFT", hdrFrame, "LEFT", 4, 0)
    iconPlate:SetBackdrop(MakeBackdrop())
    local iconPlateBgAlpha = transparent and (showSoftHeaders and (0.16 * accentA) or 0) or ((showSectionHeaders and 0.16 or 0) * frameAlpha)
    local iconPlateBorderAlpha = transparent and (showSoftHeaders and (0.50 * accentA) or 0) or ((showSectionHeaders and 0.50 or 0) * frameAlpha)
    iconPlate:SetBackdropColor(accentR, accentG, accentB, iconPlateBgAlpha)
    iconPlate:SetBackdropBorderColor(accentR, accentG, accentB, iconPlateBorderAlpha)

    local iconInfo = showIcons and ShouldShowModuleHeaderIcon(mod.key) and GetModuleIconInfo(mod) or nil
    local icon = hdrFrame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(math.max(HEADER_HEIGHT - 12, 9), math.max(HEADER_HEIGHT - 12, 9))
    icon:SetPoint("CENTER", iconPlate, "CENTER", 0, 0)
    local hasHeaderIcon = ApplyIconToTexture(icon, iconInfo, { 0.14, 0.86, 0.14, 0.86 })
    iconPlate:SetShown(hasHeaderIcon and (showIcons or showSectionHeaders))

    local lbl = hdrFrame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
    lbl:ClearAllPoints()
    if hasHeaderIcon then
        lbl:SetPoint("LEFT", iconPlate, "RIGHT", 6, 0)
    else
        lbl:SetPoint("LEFT", hdrFrame, "LEFT", 9, 0)
    end
    lbl:SetJustifyH("LEFT")
    if lbl.SetWordWrap then
        lbl:SetWordWrap(false)
    end
    lbl:SetText((allDone and not explicitColor)
        and WC("00ff96", mod.label)
        or  WC(headerColor:gsub("#",""), mod.label))

    local cnt = hdrFrame:CreateFontString(nil, "OVERLAY")
    cnt:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    cnt:SetPoint("RIGHT", hdrFrame, "RIGHT", -22, 0)
    cnt:SetText(string.format("%d / %d", secDone, secTotal))
    cnt:SetTextColor(countColor(secDone, secTotal))
    cnt:SetJustifyH("RIGHT")
    lbl:SetPoint("RIGHT", cnt, "LEFT", -8, 0)

    local arrow = CreateFrame("Frame", nil, hdrFrame)
    StyleSectionCollapseIndicator(arrow, isOpen)

    hdrFrame:EnableMouse(true)
    hdrFrame:SetScript("OnMouseDown", function(_, button)
        if opts.detached and button == "LeftButton" then
            hdrFrame._pressed = true
            hdrFrame._dragged = false
        end
    end)
    hdrFrame:SetScript("OnDragStart", function()
        if not opts.detached or MR.db.profile.locked then return end
        hdrFrame._dragged = true
        local host = GetMovableHostFrame(parent)
        if host then
            host:StartMoving()
        end
    end)
    hdrFrame:SetScript("OnDragStop", function()
        if not opts.detached then return end
        local host = GetMovableHostFrame(parent)
        if host then
            host:StopMovingOrSizing()
            local pt, _, rp, x, y = host:GetPoint()
            MR:SetDetachedModulePosition(mod.key, pt, rp, x, y)
        end
    end)
    hdrFrame:SetScript("OnMouseUp", function(_, button)
        if opts.detached and button == "LeftButton" and hdrFrame._dragged then
            hdrFrame._pressed = false
            hdrFrame._dragged = false
            return
        end
        if mod.key == "custom_tasks" and button == "RightButton" and IsShiftKeyDown() then
            if MR.ShowCustomTasksTitleDialog then
                MR:ShowCustomTasksTitleDialog()
            end
            hdrFrame._pressed = false
            hdrFrame._dragged = false
            return
        end
        if button == "LeftButton" then
            MR:SetModuleOpen(mod.key, not MR:IsModuleOpen(mod.key))
            if MR.RequestUIRefresh then
                MR:RequestUIRefresh(0.04)
            else
                MR:RefreshUI()
            end
        elseif button == "RightButton" then
            MR:SetModuleDetached(mod.key, not opts.detached)
            if MR.RequestUIRefresh then
                MR:RequestUIRefresh(0.04)
            else
                MR:RefreshUI()
            end
        end
        hdrFrame._pressed = false
    end)
    hdrFrame:SetScript("OnEnter", function()
        hdrHover:SetColorTexture(1, 1, 1, transparent and (0.10 * textOnlyHeaderAlpha) or ((showSectionHeaders and 0.05 or 0) * frameAlpha))
        GameTooltip:SetOwner(hdrFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(mod.label, 1, 1, 1)
        GameTooltip:AddLine(L["Tooltip_ExpandCollapse"], 0.5, 0.5, 0.5)
        GameTooltip:AddLine(opts.detached and "Right-click to dock back" or "Right-click to detach", 0.5, 0.8, 1)
        if mod.key == "custom_tasks" then
            GameTooltip:AddLine("Shift-right-click to rename this header.", 0.85, 0.82, 0.45, true)
        end
        GameTooltip:Show()
    end)
    hdrFrame:SetScript("OnLeave", function()
        hdrHover:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
    end)

    table.insert(widgetBucket, hdrFrame)
    if widgetBucket == self.widgets then
        AddSectionRegistryEntry(self, card, mod.key, col or 1, yOff)
    end

    local localY = HEADER_HEIGHT

    local div = CreateFrame("Frame", nil, card, "BackdropTemplate")
    div:SetPoint("TOPLEFT", card, "TOPLEFT", 0, -localY)
    div:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, -localY)
    div:SetHeight(1)
    div:SetBackdrop(MakeBackdrop(false))
    div:SetBackdropColor(1, 1, 1, dividerAlpha)
    table.insert(widgetBucket, div)

    if isOpen then
        localY = localY + 1
        local hideComplete = stats and stats.hideComplete
        local rows = MR.GetOrderedRows and MR:GetOrderedRows(mod) or mod.rows
        localY = RenderMainGroupedRows(self, card, mod, rows, hideComplete, localY, card:GetWidth(), nil, function(row, done, rowY)
            local nextY = self:BuildRow(mod, row, done, rowY, false, 0, card:GetWidth(), card, widgetBucket)
            return nil, nextY, row.key or tostring(row.label or rowY)
        end)
    end

    if widgetBucket == self.widgets then
        self.sectionRegistry[#self.sectionRegistry].bottom = yOff + (stats and stats.height or 0)
    end

    return yOff + (stats and stats.height or 0)
end

function MR:BuildRow(mod, row, done, yOff, collapsed, xOff, colW, parent, widgetBucket)
    xOff = xOff or 0
    colW = colW or ((MR.db.profile.width or 260) - 13)
    parent = parent or self.content
    widgetBucket = widgetBucket or self.widgets
    local transparent = IsMainTextOnlyMode()
    local showIcons = ShouldShowIcons()
    local frameAlpha = MR.db.profile.frameAlpha or 1.0
    local isAutoTracked = row.autoTracked
        or ((row.questIds ~= nil) and not row.allowManualQuestClicks)
        or (row.encounterIds ~= nil)
        or (row.liveKey ~= nil)
        or (row.spellId ~= nil)
        or (row.currencyId ~= nil)
        or (row.itemId ~= nil)
    local hasWaypoint   = row.zone and row.x and row.y
    local isComplete    = self:IsRowComplete(mod, row, done)
    local GHOST_H       = 8
    local rowH          = collapsed and GHOST_H or ROW_HEIGHT

    local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", xOff, -yOff)
    rowFrame:SetSize(colW, rowH)
    rowFrame:EnableMouse(true)

    if row.sectionHeader then
        local headerBg = rowFrame:CreateTexture(nil, "BACKGROUND")
        headerBg:SetAllPoints()
        if transparent then
            headerBg:SetColorTexture(1, 1, 1, 0)
        else
            headerBg:SetColorTexture(0.06, 0.08, 0.13, 0.92 * frameAlpha)
        end

        local headerText = rowFrame:CreateFontString(nil, "OVERLAY")
        SetFontForText(headerText, row.label, math.max(8, GetFontSize() - 1), GetFontFlags())
        headerText:SetPoint("LEFT", rowFrame, "LEFT", 8, 0)
        headerText:SetPoint("RIGHT", rowFrame, "RIGHT", -84, 0)
        headerText:SetJustifyH("LEFT")
        headerText:SetText(row.label)
        headerText:SetTextColor(0.82, 0.66, 0.98)

        local headerActionButton
        if ((row.headerActionText and row.headerActionText ~= "") or row.headerActionStyle == "visibility") and row.onHeaderActionClick then
            headerActionButton = CreateFrame("Button", nil, rowFrame, "BackdropTemplate")
            headerActionButton:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
            if row.headerActionStyle == "visibility" then
                headerActionButton:SetSize(14, 14)
                headerActionButton:SetBackdrop(MakeBackdrop())
                headerActionButton:SetBackdropColor(0.05, 0.10, 0.18, 1)
                headerActionButton:SetBackdropBorderColor(
                    row.headerActionVisible and 0.15 or 0.35,
                    row.headerActionVisible and 0.32 or 0.12,
                    row.headerActionVisible and 0.38 or 0.12,
                    1
                )

                local actionText = headerActionButton:CreateFontString(nil, "OVERLAY")
                actionText:SetFont(FONT_ROWS, 9, GetFontFlags())
                actionText:SetPoint("CENTER", headerActionButton, "CENTER", 0, 0)
                actionText:SetJustifyH("CENTER")
                actionText:SetText(row.headerActionVisible and "o" or "-")
                actionText:SetTextColor(
                    row.headerActionVisible and 0.25 or 0.55,
                    row.headerActionVisible and 0.85 or 0.25,
                    row.headerActionVisible and 0.70 or 0.25
                )
            else
                headerActionButton:SetSize(26, rowH)

                local actionText = headerActionButton:CreateFontString(nil, "OVERLAY")
                actionText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                actionText:SetPoint("CENTER", headerActionButton, "CENTER", 0, 0)
                actionText:SetJustifyH("CENTER")
                actionText:SetText(row.headerActionText)
                if row.headerActionColor then
                    actionText:SetTextColor(row.headerActionColor[1], row.headerActionColor[2], row.headerActionColor[3])
                else
                    actionText:SetTextColor(0.92, 0.78, 0.24)
                end
            end

            headerActionButton:SetScript("OnClick", function()
                row.onHeaderActionClick(row, mod, rowFrame)
            end)
            headerActionButton:SetScript("OnEnter", function()
                if row.headerActionTooltip and row.headerActionTooltip ~= "" then
                    GameTooltip:SetOwner(headerActionButton, "ANCHOR_RIGHT")
                    GameTooltip:SetText(row.headerActionTooltip, 1, 1, 1, 1, true)
                    GameTooltip:Show()
                end
            end)
            headerActionButton:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end

        local headerCountText, headerCountColor = GetMainFrameRowCount(row)
        if headerCountText and headerCountText ~= "" then
            local countText = rowFrame:CreateFontString(nil, "OVERLAY")
            countText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
            if headerActionButton then
                countText:SetPoint("RIGHT", headerActionButton, "LEFT", -8, 0)
            else
                countText:SetPoint("RIGHT", rowFrame, "RIGHT", -8, 0)
            end
            countText:SetJustifyH("RIGHT")
            countText:SetText(headerCountText)
            if headerCountColor then
                countText:SetTextColor(headerCountColor[1], headerCountColor[2], headerCountColor[3])
            else
                countText:SetTextColor(0.74, 0.80, 0.88)
            end
        end

        rowFrame:SetScript("OnEnter", function()
            if row.note then
                GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
                GameTooltip:SetText(row.label, 1, 1, 1)
                GameTooltip:AddLine(row.note, 0.70, 0.70, 0.76, true)
                GameTooltip:Show()
            end
        end)
        rowFrame:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        table.insert(widgetBucket, rowFrame)
        return yOff + rowH
    end

    if collapsed then
        local line = rowFrame:CreateTexture(nil, "ARTWORK")
        line:SetPoint("LEFT",  rowFrame, "LEFT",  PADDING + 10, 0)
        line:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
        line:SetHeight(1)
        line:SetColorTexture(0.25, 0.25, 0.25, 0.5)

        local dot = rowFrame:CreateTexture(nil, "ARTWORK")
        dot:SetSize(4, 4)
        dot:SetPoint("LEFT", rowFrame, "LEFT", PADDING, 0)
        dot:SetColorTexture(0.25, 0.55, 0.25, 0.6)

        rowFrame:SetScript("OnEnter", function()
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Tooltip_DonePrefix"] .. row.label, 0.4, 0.85, 0.4, 1, true)
            GameTooltip:AddLine(L["Tooltip_CompletedWeek"], 0.3, 0.6, 0.3)
            GameTooltip:Show()
        end)
        rowFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

        table.insert(widgetBucket, rowFrame)
        return yOff + rowH
    end

    local hover = rowFrame:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0)

    local rowShade = rowFrame:CreateTexture(nil, "BORDER")
    rowShade:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 0, -1)
    rowShade:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 0, 0)
    if isComplete and not transparent then
        rowShade:SetColorTexture(0.12, 0.16, 0.12, 0.18 * frameAlpha)
    else
        rowShade:SetColorTexture(0, 0, 0, 0)
    end

    local separator = rowFrame:CreateTexture(nil, "ARTWORK")
    separator:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", 12, 0)
    separator:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", -12, 0)
    separator:SetHeight(1)
    separator:SetColorTexture(1, 1, 1, transparent and 0 or (0.06 * frameAlpha))

    rowFrame:SetScript("OnEnter", function()
        hover:SetColorTexture(1, 1, 1, transparent and 0 or (0.04 * frameAlpha))
        if row.currencyId and not row.noBlizzardTooltip then
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            GameTooltip:SetCurrencyByID(row.currencyId)
            GameTooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
            if row.tooltipFunc then
                row.tooltipFunc(GameTooltip)
            end
            GameTooltip:Show()
        elseif row.itemId and not row.noBlizzardTooltip then
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            if GameTooltip.SetItemByID then
                GameTooltip:SetItemByID(row.itemId)
            else
                GameTooltip:SetHyperlink("item:" .. row.itemId)
            end
            GameTooltip:AddLine(L["Tooltip_AutoItem"], 0.9, 0.6, 1)
            GameTooltip:Show()
        else
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(row.label, 1, 1, 1, 1, true)
            if row.note then GameTooltip:AddLine(row.note, 0.7, 0.7, 0.7, true) end
            if hasWaypoint then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(string.format(L["Gathering_Coords"], row.x, row.y), 0.7, 1, 0.9)
                GameTooltip:AddLine(L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
            end
            if row.tooltipFunc then
                row.tooltipFunc(GameTooltip)
            end
            if row.noDefaultTooltipHint then
            elseif row.liveKey or row.autoTracked or (row.currencyId and row.noBlizzardTooltip) then
                GameTooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
            elseif row.questIds then
                GameTooltip:AddLine(L["Tooltip_AutoQuest"], 0.4, 1, 0.6)
            elseif row.spellId or row.itemId then
                GameTooltip:AddLine(L["Tooltip_AutoItem"], 0.9, 0.6, 1)
            elseif not hasWaypoint then
                GameTooltip:AddLine(L["Tooltip_ManualClick"], 0.5, 0.5, 0.5)
            end
            GameTooltip:Show()
        end
    end)
    rowFrame:SetScript("OnLeave", function()
        hover:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
    end)

    rowFrame:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and row.onLeftClick then
            local handled = row.onLeftClick(row, mod, done, rowFrame)
            if handled ~= false then
                return
            end
        elseif button == "RightButton" and row.onRightClick then
            local handled = row.onRightClick(row, mod, done, rowFrame)
            if handled ~= false then
                return
            end
        end

        if button == "LeftButton" and hasWaypoint then
            local ok, source = MR:SetWaypoint(row)
            if ok then
                print(string.format(L["Waypoint_Set"], source, row.waypointTitle or row.label, row.x, row.y))
            else
                print(L["Waypoint_Unavailable"])
            end
        elseif not isAutoTracked and button == "LeftButton" then
                MR:BumpProgress(mod.key, row.key, 1, row.max)
        elseif not isAutoTracked and button == "RightButton" then
            MR:BumpProgress(mod.key, row.key, -1, row.max)
        end
    end)

    local statusObjectType = ((isAutoTracked and not row.noMax) or row.toggleStatus) and "Button" or "Frame"
    local statusBtn = CreateFrame(statusObjectType, nil, rowFrame, "BackdropTemplate")
    statusBtn:SetSize(14, 14)
    statusBtn:SetPoint("LEFT", rowFrame, "LEFT", PADDING + 2, 0)
    statusBtn:SetBackdrop(MakeBackdrop())

    local statusFill = statusBtn:CreateTexture(nil, "ARTWORK")
    statusFill:SetPoint("TOPLEFT", statusBtn, "TOPLEFT", 2, -2)
    statusFill:SetPoint("BOTTOMRIGHT", statusBtn, "BOTTOMRIGHT", -2, 2)

    local statusCheck = statusBtn:CreateFontString(nil, "OVERLAY")
    statusCheck:SetFont(FONT_HEADERS, 9, GetFontFlags())
    statusCheck:SetPoint("CENTER", statusBtn, "CENTER", 0, 1)
    statusCheck:SetText("x")

    local function RefreshStatusDisplay()
        local mo = MR:GetManualOverride(mod.key, row.key)
        local forcedComplete = row.max and mo >= row.max
        local activeDone = forcedComplete and row.max or done

        if transparent then
            statusBtn:SetBackdropColor(0, 0, 0, 0)
        else
            statusBtn:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * frameAlpha)
        end
        if forcedComplete then
            statusBtn:SetBackdropBorderColor(transparent and 0 or 0.88, transparent and 0 or 0.74, transparent and 0 or 0.22, transparent and 0 or frameAlpha)
            statusFill:SetColorTexture(0.88, 0.74, 0.22, transparent and 0 or (0.85 * frameAlpha))
            statusCheck:SetTextColor(0.10, 0.08, 0.02, transparent and 0 or 1)
            if transparent then statusCheck:Hide() else statusCheck:Show() end
        elseif isComplete then
            statusBtn:SetBackdropBorderColor(transparent and 0 or 0.24, transparent and 0 or 0.76, transparent and 0 or 0.46, transparent and 0 or frameAlpha)
            statusFill:SetColorTexture(0.20, 0.72, 0.42, transparent and 0 or (0.85 * frameAlpha))
            statusCheck:SetTextColor(0.03, 0.08, 0.04, transparent and 0 or 1)
            if transparent then statusCheck:Hide() else statusCheck:Show() end
        elseif row.max and activeDone > 0 then
            statusBtn:SetBackdropBorderColor(transparent and 0 or 0.62, transparent and 0 or 0.52, transparent and 0 or 0.22, transparent and 0 or (0.95 * frameAlpha))
            statusFill:SetColorTexture(0.78, 0.62, 0.22, transparent and 0 or (0.70 * frameAlpha))
            statusCheck:Hide()
        else
            statusBtn:SetBackdropBorderColor(transparent and 0 or 0.24, transparent and 0 or 0.28, transparent and 0 or 0.34, transparent and 0 or (0.95 * frameAlpha))
            statusFill:SetColorTexture(0.09, 0.10, 0.14, transparent and 0 or (0.70 * frameAlpha))
            statusCheck:Hide()
        end
    end
    RefreshStatusDisplay()
    if row.hideStatus then
        statusBtn:Hide()
    end

    if statusBtn:GetObjectType() == "Button" then
        statusBtn:SetScript("OnClick", function()
            if mod.key == "custom_tasks" and IsShiftKeyDown() and row.onLeftClick then
                local handled = row.onLeftClick(row, mod, done, rowFrame)
                if handled ~= false then
                    return
                end
            end

            if row.toggleStatus and MR.ToggleCustomTask and mod.key == "custom_tasks" then
                local rowKey = row.key or ""
                local scope = row.taskScope or (rowKey:match("^shared_task_") and "shared" or "character")
                local taskId = tonumber(rowKey:match("^shared_task_(%d+)") or rowKey:match("^task_(%d+)"))
                MR:ToggleCustomTask(taskId, scope)
                return
            end
            local cur = MR:GetManualOverride(mod.key, row.key)
            MR:SetManualOverride(mod.key, row.key, cur >= row.max and 0 or row.max, row.max)
        end)
        statusBtn:SetScript("OnEnter", function()
            hover:SetColorTexture(1, 1, 1, transparent and 0 or (0.04 * frameAlpha))
            local mo = row.toggleStatus and MR:GetProgress(mod.key, row.key) or MR:GetManualOverride(mod.key, row.key)
            GameTooltip:SetOwner(statusBtn, "ANCHOR_RIGHT")
            GameTooltip:SetText(row.label, 1, 1, 1, 1, true)
            if row.note then GameTooltip:AddLine(row.note, 0.7, 0.7, 0.7, true) end
            GameTooltip:AddLine(" ")
            if mo >= row.max then
                GameTooltip:AddLine(L["Tooltip_ManualDot_Active"], 1, 0.85, 0.1, true)
            else
                GameTooltip:AddLine(L["Tooltip_ManualDot_Hint"], 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()
        end)
        statusBtn:SetScript("OnLeave", function()
            hover:SetColorTexture(1, 1, 1, 0)
            GameTooltip:Hide()
        end)
    end

    local isCurrencyModule = mod and (mod.key == "currencies" or mod.key == "pvp_currencies")
    local rowIconInfo = (mod and mod.profSkillLine) and GetRowIconInfo(mod, row) or nil
    local countIconInfo = (showIcons and isCurrencyModule and row.currencyId) and GetRowIconInfo(mod, row) or nil
    local iconSize = math.max(ROW_HEIGHT - 8, 12)
    local rowIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    rowIcon:SetSize(iconSize, iconSize)
    rowIcon:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
    local hasRowIcon = ApplyIconToTexture(rowIcon, rowIconInfo)
    if isComplete and hasRowIcon then
        rowIcon:SetVertexColor(0.55, 0.55, 0.55, 0.7)
    end
    local countIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    countIcon:SetSize(iconSize, iconSize)
    countIcon:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
    local hasCountIcon = ApplyIconToTexture(countIcon, countIconInfo)
    if isComplete and hasCountIcon then
        countIcon:SetVertexColor(0.55, 0.55, 0.55, 0.7)
    end
    local hasNumericMax = type(row.max) == "number" and row.max > 0
    local isCurrencyRow = row.currencyId and hasNumericMax and not row.noMax
    local isProfessionRow = mod and mod.profSkillLine
    local hasCoordText  = hasWaypoint and not row.hideCoordText and not isProfessionRow
    local hasKnowledgeText = type(row.kpTotal) == "number" and row.kpTotal > 0
    local lblRightOff   = isCurrencyRow and -96 or (hasCoordText and (hasKnowledgeText and -168 or -128) or (hasKnowledgeText and -64 or -52))

    local lbl = rowFrame:CreateFontString(nil, "OVERLAY")
    if lbl.SetWordWrap then
        lbl:SetWordWrap(false)
    end
    if lbl.SetNonSpaceWrap then
        lbl:SetNonSpaceWrap(false)
    end
    if lbl.SetShadowOffset then
        lbl:SetShadowOffset(0, 0)
    end
    SetFontForText(lbl, CleanLabelText(row.label), GetFontSize(), GetFontFlags())
    if hasRowIcon then
        lbl:SetPoint("LEFT", rowIcon, "RIGHT", 8, 0)
    else
        lbl:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
    end
    lbl:SetPoint("RIGHT", rowFrame, "RIGHT", lblRightOff, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetJustifyV("MIDDLE")

    local rowCustom    = MR:GetRowColor(mod.key, row.key) or (row.colorKey and MR:GetRowColor(mod.key, row.colorKey))
    local headerCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local inlineColor  = ExtractInlineLabelColor(row.label)
    local effectiveColor = rowCustom or headerCustom or inlineColor
    local cleanLabel = CleanLabelText(row.label)

    if isComplete then
        lbl:SetText(cleanLabel)
        if effectiveColor then
            local cr, cg, cb = hex(effectiveColor)
            lbl:SetTextColor(cr * 0.45, cg * 0.45, cb * 0.45)
        else
            lbl:SetTextColor(0.38, 0.38, 0.38)
        end
    elseif effectiveColor then
        lbl:SetText(cleanLabel)
        lbl:SetTextColor(hex(effectiveColor))
    else
        lbl:SetText(cleanLabel)
        lbl:SetTextColor(1, 1, 1)
    end

    local countFS = rowFrame:CreateFontString(nil, "OVERLAY")
    countFS:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
    if hasCountIcon then
        countFS:SetPoint("RIGHT", countIcon, "LEFT", -4, 0)
    else
        countFS:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
    end
    countFS:SetJustifyH("RIGHT")
    if countFS.SetWordWrap then
        countFS:SetWordWrap(false)
    end

    local countText, countTextColor = GetMainFrameRowCount(row)
    if isProfessionRow then
        countText, countTextColor = nil, nil
    end
    if countText then
        countFS:SetText(countText)
        if countTextColor then
            countFS:SetTextColor(countTextColor[1], countTextColor[2], countTextColor[3])
        else
            countFS:SetTextColor(0.8, 0.8, 0.8)
        end

        if not isCurrencyRow and not hasCoordText then
            local reservedWidth
            if type(row.countWidth) == "number" and row.countWidth > 0 then
                reservedWidth = row.countWidth
            else
                reservedWidth = math.min(
                    math.max(math.floor((countFS:GetStringWidth() or 0) + 8), 64),
                    math.floor(math.max(rowFrame:GetWidth() * 0.5, 64))
                )
            end
            countFS:SetWidth(reservedWidth)
            lbl:ClearAllPoints()
            if hasRowIcon then
                lbl:SetPoint("LEFT", rowIcon, "RIGHT", 8, 0)
            else
                lbl:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
            end
            lbl:SetPoint("RIGHT", countFS, "LEFT", -8, 0)
        end
    elseif isCurrencyRow then
        local mdb    = GetMainFrameProgressModule(mod.key)
        local wallet = (mdb and mdb[row.key .. "_wallet"]) or done

        countFS:SetText(string.format("%d/%d", done, row.max))
        countFS:SetTextColor(countColor(done, row.max))

        lbl:ClearAllPoints()
        lbl:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
        if row.hideWallet then
            lbl:SetPoint("RIGHT", countFS, "LEFT", -8, 0)
        else
            local walletFS = rowFrame:CreateFontString(nil, "OVERLAY")
            walletFS:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
            walletFS:SetPoint("RIGHT", countFS, "LEFT", -5, 0)
            walletFS:SetJustifyH("RIGHT")
            walletFS:SetText(string.format("|cffaaaaaa(%d)|r", wallet))
            lbl:SetPoint("RIGHT", walletFS, "LEFT", -8, 0)
        end
    elseif isProfessionRow then
        countFS:SetText("")
    else
        countFS:SetText((row.noMax or not hasNumericMax) and tostring(done) or string.format("%d / %d", done, row.max))
        if row.noMax or not hasNumericMax then
            countFS:SetTextColor(0.8, 0.8, 0.8)
        else
            countFS:SetTextColor(countColor(done, row.max))
        end
        if hasCountIcon and row.currencyId then
            lbl:ClearAllPoints()
            lbl:SetPoint("LEFT", statusBtn, "RIGHT", 8, 0)
            lbl:SetPoint("RIGHT", countFS, "LEFT", -8, 0)
        end
    end

    local rightAnchor = countFS
    if hasKnowledgeText then
        local knowledgeFS = rowFrame:CreateFontString(nil, "OVERLAY")
        knowledgeFS:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 1), GetFontFlags())
        knowledgeFS:SetPoint("RIGHT", countFS, "LEFT", -8, 0)
        knowledgeFS:SetJustifyH("RIGHT")
        if knowledgeFS.SetWordWrap then
            knowledgeFS:SetWordWrap(false)
        end
        if isComplete then
            knowledgeFS:SetText(L["Done"] or "Done")
            knowledgeFS:SetTextColor(0.32, 0.80, 0.50, 0.95)
        else
            knowledgeFS:SetText("+" .. tostring(row.kpTotal))
            if effectiveColor then
                knowledgeFS:SetTextColor(hex(effectiveColor))
            else
                knowledgeFS:SetTextColor(0.92, 0.78, 0.24, 0.95)
            end
        end
        rightAnchor = knowledgeFS
    end

    if hasCoordText then
        local coordsFS = rowFrame:CreateFontString(nil, "OVERLAY")
        coordsFS:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 1), GetFontFlags())
        coordsFS:SetPoint("RIGHT", rightAnchor, "LEFT", -8, 0)
        coordsFS:SetJustifyH("RIGHT")
        coordsFS:SetText(string.format("%.2f, %.2f", row.x, row.y))
        if isComplete then
            coordsFS:SetTextColor(0.4, 0.4, 0.4, 0.6)
        else
            coordsFS:SetTextColor(0.65, 0.9, 1, 0.95)
        end
    end

    if row.vaultLabel then
        local vl = rowFrame:CreateFontString(nil, "OVERLAY")
        vl:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
        vl:SetPoint("RIGHT", countFS, "LEFT", -4, 0)
        vl:SetText(row.vaultLabel)
        vl:SetTextColor(hex(row.vaultColor or "#ffffff"))
    end

    if row.timerEpoch and not isComplete and not collapsed then
        local function FormatMMSS(s)
            return string.format("%d:%02d", math.floor(s / 60), s % 60)
        end
        local function UpdateTimer()
            local now    = GetServerTime()
            local offset = (now - row.timerEpoch) % row.timerInterval
            if offset < row.timerDuration then
                local rem = row.timerDuration - offset
                countFS:SetText(L["Timer_Live"] .. FormatMMSS(rem))
                countFS:SetTextColor(0.25, 0.88, 0.50, 1)
            else
                local rem = row.timerInterval - offset
                countFS:SetText(L["Timer_Next"] .. FormatMMSS(rem))
                countFS:SetTextColor(0.55, 0.55, 0.55, 1)
            end
        end
        UpdateTimer()
        rowFrame._timerUpdate = UpdateTimer
        table.insert(MR._timerRows, rowFrame)
    end

    table.insert(widgetBucket, rowFrame)
    return yOff + rowH
end

function ns.AttachScrollList(scroll, content, track)
    scroll:EnableMouseWheel(true)
    scroll:SetScrollChild(content)

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0, 0, 0, 0.3)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetPoint("LEFT", track, "LEFT", 0, 0)
    thumb:SetPoint("RIGHT", track, "RIGHT", 0, 0)
    thumb:EnableMouse(true)
    thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(0.20, 0.66, 0.63, 0.7)

    local function GetContentHeight()
        local child = scroll:GetScrollChild()
        return child and child:GetHeight() or 0
    end

    local function UpdateScrollBar()
        local viewH, contentH = scroll:GetHeight(), GetContentHeight()
        if contentH <= viewH or viewH <= 0 then thumb:Hide(); return end
        thumb:Show()
        local trackH = math.max(track:GetHeight(), 1)
        local thumbH = math.max(trackH * (viewH / contentH), 14)
        local pct = scroll:GetVerticalScroll() / math.max(contentH - viewH, 1)
        thumb:SetHeight(thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -((trackH - thumbH) * pct))
        thumb:SetPoint("RIGHT", track, "RIGHT", 0, 0)
    end

    local function SetScrollFromCursor(cursorY, grabOffset)
        local viewH = scroll:GetHeight()
        local contentH = GetContentHeight()
        local maxScroll = math.max(contentH - viewH, 0)
        if maxScroll <= 0 then
            scroll:SetVerticalScroll(0)
            UpdateScrollBar()
            return
        end

        local trackTop = track:GetTop()
        local trackBottom = track:GetBottom()
        if not trackTop or not trackBottom then return end

        local trackH = math.max(trackTop - trackBottom, 1)
        local thumbH = thumb:GetHeight()
        local movable = math.max(trackH - thumbH, 1)
        local offset = grabOffset or (thumbH * 0.5)
        local y = math.max(0, math.min((trackTop - cursorY) - offset, movable))
        local pct = y / movable
        scroll:SetVerticalScroll(maxScroll * pct)
        UpdateScrollBar()
    end

    track:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or not thumb:IsShown() then return end
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / UIParent:GetEffectiveScale()
        SetScrollFromCursor(cursorY, thumb:GetHeight() * 0.5)
        thumb._grabOffset = thumb:GetHeight() * 0.5
        thumb:SetScript("OnUpdate", function(self)
            if not IsMouseButtonDown("LeftButton") then
                self._grabOffset = nil
                self:SetScript("OnUpdate", nil)
                return
            end

            local _, dragCursorY = GetCursorPosition()
            dragCursorY = dragCursorY / UIParent:GetEffectiveScale()
            SetScrollFromCursor(dragCursorY, self._grabOffset)
        end)
    end)

    thumb:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" or not self:IsShown() then return end
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / UIParent:GetEffectiveScale()
        local thumbTop = self:GetTop()
        self._grabOffset = thumbTop and (thumbTop - cursorY) or (self:GetHeight() * 0.5)
        self:SetScript("OnUpdate", function(btn)
            if not IsMouseButtonDown("LeftButton") then
                btn._grabOffset = nil
                btn:SetScript("OnUpdate", nil)
                return
            end

            local _, dragCursorY = GetCursorPosition()
            dragCursorY = dragCursorY / UIParent:GetEffectiveScale()
            SetScrollFromCursor(dragCursorY, btn._grabOffset)
        end)
    end)

    thumb:SetScript("OnMouseUp", function(self)
        self._grabOffset = nil
        self:SetScript("OnUpdate", nil)
    end)

    scroll:SetScript("OnMouseWheel", function(_, delta)
        scroll:SetVerticalScroll(math.max(0, math.min(scroll:GetVerticalScroll() - delta * 30, math.max(GetContentHeight() - scroll:GetHeight(), 0))))
        UpdateScrollBar()
    end)
    scroll:SetScript("OnScrollRangeChanged", UpdateScrollBar)
    scroll:SetScript("OnVerticalScroll", UpdateScrollBar)

    return UpdateScrollBar, thumb, trackBg, thumbTex
end
