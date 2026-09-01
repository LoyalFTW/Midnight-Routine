local _, ns = ...
local MR = ns.MR
local Warband = assert(ns.WarbandBoardInternal, "UI/Warband/Shared.lua must load first")
local WBState = Warband.state
local L = Warband.L
local FONT_ROWS = ns.FONT_ROWS
local FONT_HEADERS = ns.FONT_HEADERS
local MakeBackdrop = ns.MakeBackdrop
local StyledFrame = ns.StyledFrame
local TitleBar = ns.TitleBar
local CloseButton = ns.CloseButton
local OptionsGap = ns.OptionsGap
local OptionsDivider = ns.OptionsDivider
local OptionsSectionLabel = ns.OptionsSectionLabel
local OptionsCheckbox = ns.OptionsCheckbox
local OptionsSlider = ns.OptionsSlider
local DAY_SECONDS = Warband.DAY_SECONDS
local GetFontSize = Warband.GetFontSize
local GetFontFlags = Warband.GetFontFlags
local RefreshFonts = Warband.RefreshFonts
local GetWindowLayoutValue = Warband.GetWindowLayoutValue
local SetWindowLayoutValue = Warband.SetWindowLayoutValue
local WBClean = Warband.WBClean
local WBHexColor = Warband.WBHexColor
local WBApplySurface = Warband.WBApplySurface
local WBStylePillButton = Warband.WBStylePillButton
local WBFormatTimestamp = Warband.WBFormatTimestamp
local WBStatusText = Warband.WBStatusText
local WBStatusColor = Warband.WBStatusColor
local WBCharacterMatchesSearch = Warband.WBCharacterMatchesSearch
local WBClassColor = Warband.WBClassColor
local WBEnsureDragGhost = Warband.WBEnsureDragGhost
local WBStartDragVisual = Warband.WBStartDragVisual
local WBStopDragVisual = Warband.WBStopDragVisual
local WBMarkDragTarget = Warband.WBMarkDragTarget
local WBUpdateDragTargetFromCursor = Warband.WBUpdateDragTargetFromCursor
local GetExpansionDisplayInfo = Warband.GetExpansionDisplayInfo
local GetExpansionDisplayLabel = Warband.GetExpansionDisplayLabel
local CycleExpansion = Warband.CycleExpansion
local BuildExpansionDropdown = Warband.BuildExpansionDropdown
local WBConcentrationText = Warband.WBConcentrationText
local WBConcentrationCurrent = Warband.WBConcentrationCurrent
local WBConcentrationDailyGain = Warband.WBConcentrationDailyGain
local WBConcentrationProjectedQuantity = Warband.WBConcentrationProjectedQuantity
local WBConcentrationTimeToFull = Warband.WBConcentrationTimeToFull
local WBFormatDurationShort = Warband.WBFormatDurationShort
local WBFormatConcentrationFullAt = Warband.WBFormatConcentrationFullAt
local WBConcentrationLabel = Warband.WBConcentrationLabel
local WBGetConcentrationTrackerAlpha = Warband.WBGetConcentrationTrackerAlpha
local WBSetConcentrationTrackerAlpha = Warband.WBSetConcentrationTrackerAlpha
local WBIsConcentrationTrackerCompact = Warband.WBIsConcentrationTrackerCompact
local WBSetConcentrationTrackerCompact = Warband.WBSetConcentrationTrackerCompact
local WBGetConcentrationTrackerHiddenCharacters = Warband.WBGetConcentrationTrackerHiddenCharacters
local WBIsConcentrationTrackerCharacterHidden = Warband.WBIsConcentrationTrackerCharacterHidden
local WBSetConcentrationTrackerCharacterHidden = Warband.WBSetConcentrationTrackerCharacterHidden
local WBApplyConcentrationTrackerTheme = Warband.WBApplyConcentrationTrackerTheme
local WBAltLoginPrompt = Warband.WBAltLoginPrompt
local WBGetAltBoardView = Warband.WBGetAltBoardView
local WBSetAltBoardView = Warband.WBSetAltBoardView
local WBShouldHideCompletedCharacters = Warband.WBShouldHideCompletedCharacters
local WBCreateScrollArea = Warband.WBCreateScrollArea
local WBRefreshAltBoardTabs = Warband.WBRefreshAltBoardTabs
local WBPopulateConcentrationOverview = Warband.WBPopulateConcentrationOverview
local WBRefreshMainAltPicker = Warband.WBRefreshMainAltPicker
local WBBuildMainAltPicker = Warband.WBBuildMainAltPicker
local WBPopulateConcentrationTracker = Warband.WBPopulateConcentrationTracker

function MR:RefreshConcentrationTracker(data)
    if self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown() then
        WBPopulateConcentrationTracker(self.concentrationTrackerFrame, data)
    end
end

local function WBCreateHeaderButton(parent, icon, normalColor, hoverBg, hoverBorder, tooltipText, onClick)
    local size = icon.size or 18
    return ns.HeaderButton(parent, {
        size = size,
        texture = icon.tex,
        text = icon.text,
        iconSize = icon.tex and (size - 4) or nil,
        fontSize = math.max(8, size - 7),
        color = normalColor,
        hoverColor = { 1, 1, 1 },
        hoverBackground = { hoverBg[1], hoverBg[2], hoverBg[3], 1 },
        hoverBorder = { hoverBorder[1], hoverBorder[2], hoverBorder[3], 1 },
        tooltip = tooltipText,
        onClick = onClick,
    })
end

local WBHideConcentrationTrackerOptions

local function WBApplyConcentrationTrackerLayout(frame)
    if not frame then
        return
    end

    local minimized = GetWindowLayoutValue("concentrationTrackerMinimized") == true
    local headerHeight = math.max(24, GetFontSize() + 11)
    WBApplyConcentrationTrackerTheme(frame)
    if frame.titleBar then
        frame.titleBar:SetHeight(headerHeight)
    end
    if frame.body then frame.body:SetShown(not minimized) end
    if frame.summary then frame.summary:SetShown(not minimized and not WBIsConcentrationTrackerCompact()) end
    if frame.scroll then frame.scroll:SetShown(not minimized) end
    if frame.scrollTrack then frame.scrollTrack:SetShown(not minimized) end
    if frame.dragger then frame.dragger:SetShown(not minimized) end
    if minimized then
        WBHideConcentrationTrackerOptions(frame)
    end
    if frame.minBtn and frame.minBtn._iconObj then
        frame.minBtn._iconObj:SetText(minimized and "+" or "-")
    end

    if minimized then
        frame:SetHeight(headerHeight)
    else
        local size = GetWindowLayoutValue("concentrationTrackerSize")
        frame:SetSize((size and size.width) or 440, (size and size.height) or 520)
    end

    if frame.content then
        local fw = frame:GetWidth()
        if not fw or fw <= 0 then fw = 440 end
        frame.content:SetWidth(math.max(fw - 40, 300))
    end
    if frame.scrollUpdate then
        frame.scrollUpdate()
    end
end

WBHideConcentrationTrackerOptions = function(frame)
    if WBState.concentrationTrackerConfigFrame then
        WBState.concentrationTrackerConfigFrame:Hide()
    end
end

function MR:ToggleConcentrationTracker()
    if self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown() then
        self:HideConcentrationTracker()
        return
    end

    if self.ClearManagedWindowsBundleHidden then
        self:ClearManagedWindowsBundleHidden()
    end
    if self._instanceFramesHidden then
        if self.SetManagedWindowOpen then
            self:SetManagedWindowOpen("concentrationTrackerOpen", true)
        end
        return
    end

    if not self.concentrationTrackerFrame then
        local frame = StyledFrame(UIParent, nil, "DIALOG", 35)
        self:RegisterPriorityFrame(frame)
        local savedSize = GetWindowLayoutValue("concentrationTrackerSize")
        frame:SetSize((savedSize and savedSize.width) or 440, (savedSize and savedSize.height) or 520)
        frame:SetScale(self.db.profile.scale or 1)
        local pos = GetWindowLayoutValue("concentrationTrackerPosition")
        if pos and pos.point then
            frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 260, 10)
        end

        local titleBar = TitleBar(frame, math.max(24, GetFontSize() + 11))
        titleBar:SetBackdropColor(0.04, 0.11, 0.20, 1)
        titleBar:SetScript("OnDragStart", function()
            if not (MR.db and MR.db.profile and MR.db.profile.locked) then
                frame:StartMoving()
            end
        end)
        titleBar:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            local pt, _, rp, x, y = frame:GetPoint()
            SetWindowLayoutValue("concentrationTrackerPosition", { point = pt, relPoint = rp, x = x, y = y })
        end)

        local title = titleBar:CreateFontString(nil, "OVERLAY")
        title:SetFont(ns.FONT_HEADERS, math.max(8, GetFontSize() - 2), GetFontFlags())
        title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
        title:SetPoint("RIGHT", titleBar, "RIGHT", -100, 0)
        title:SetJustifyH("LEFT")
        title:SetText(L["AltBoard_ConcentrationTrackerTitle"] or "Alt Concentration")
        title:SetTextColor(0.92, 0.97, 1.0)

        local closeBtn = WBCreateHeaderButton(
            titleBar,
            { text = "x", size = 18 },
            {0.88, 0.56, 0.56},
            {0.28, 0.10, 0.10},
            {0.90, 0.25, 0.25},
            L["Close"],
            function()
                MR:HideConcentrationTracker()
            end
        )
        closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -8, 0)

        local minBtn = WBCreateHeaderButton(
            titleBar,
            { text = "-", size = 18 },
            {0.80, 0.84, 0.88},
            {0.10, 0.17, 0.24},
            {0.32, 0.58, 0.72},
            L["Minimize"],
            function()
                SetWindowLayoutValue("concentrationTrackerMinimized", GetWindowLayoutValue("concentrationTrackerMinimized") ~= true)
                WBApplyConcentrationTrackerLayout(frame)
            end
        )
        minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)

        local cfgBtn = WBCreateHeaderButton(
            titleBar,
            { tex = "Interface\\Buttons\\UI-OptionsButton", size = 18 },
            {0.92, 0.76, 0.24},
            {0.18, 0.14, 0.05},
            {0.98, 0.82, 0.24},
            L["Options"],
            function() MR:ToggleConcentrationTrackerConfig() end
        )
        cfgBtn:SetPoint("RIGHT", minBtn, "LEFT", -4, 0)

        if MR.ApplyPanelHeaderAutoHide then MR:ApplyPanelHeaderAutoHide(frame, titleBar) end

        local refreshBtn = WBCreateHeaderButton(
            titleBar,
            { tex = "Interface\\Buttons\\UI-RefreshButton", size = 18 },
            {0.70, 0.88, 0.85},
            {0.06, 0.18, 0.16},
            {0.25, 0.85, 0.72},
            L["CurrencyBrowser_Refresh"] or "Refresh",
            function()
                if MR.RefreshPlayerProfessions then
                    MR:RefreshPlayerProfessions()
                end
                if MR.RefreshProfessionConcentration then
                    MR:RefreshProfessionConcentration()
                end
                WBPopulateConcentrationTracker(frame)
            end
        )
        refreshBtn:SetPoint("RIGHT", cfgBtn, "LEFT", -4, 0)

        local summary = frame:CreateFontString(nil, "OVERLAY")
        summary:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        summary:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -30)
        summary:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -30)
        summary:SetJustifyH("LEFT")
        summary:SetTextColor(0.64, 0.74, 0.84)

        local scroll, content, scrollUpdate, scrollTrack = WBCreateScrollArea(
            frame,
            { "TOPLEFT", frame, "TOPLEFT", 14, -54 },
            { "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 14 }
        )
        content:SetSize(400, 1)

        local emptyLabel = content:CreateFontString(nil, "OVERLAY")
        emptyLabel:SetFont(ns.FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
        emptyLabel:SetJustifyH("LEFT")
        emptyLabel:SetTextColor(0.68, 0.74, 0.84)
        emptyLabel:Hide()

        local dragger = CreateFrame("Frame", nil, frame)
        dragger:SetSize(12, 12)
        dragger:SetFrameLevel(frame:GetFrameLevel() + 10)
        dragger:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        dragger:EnableMouse(true)
        local dTex = dragger:CreateTexture(nil, "OVERLAY")
        dTex:SetAllPoints()
        dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

        dragger:SetScript("OnEnter", function()
            if not (MR.db and MR.db.profile and MR.db.profile.locked) then
                dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
            end
        end)
        dragger:SetScript("OnLeave", function()
            dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        end)

        local dragStartW, dragStartH, dragStartX, dragStartY
        dragger:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" and not (MR.db and MR.db.profile and MR.db.profile.locked) then
                dragStartW = frame:GetWidth()
                dragStartH = frame:GetHeight()
                dragStartX, dragStartY = GetCursorPosition()
                local scale = frame:GetEffectiveScale()
                dragStartX = dragStartX / scale
                dragStartY = dragStartY / scale
                dragger._dragging = true
            end
        end)
        dragger:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" and dragger._dragging then
                dragger._dragging = false
                local newW = math.max(320, math.min(700, math.floor(frame:GetWidth())))
                local newH = math.max(260, math.min(800, math.floor(frame:GetHeight())))
                frame:SetSize(newW, newH)
                SetWindowLayoutValue("concentrationTrackerSize", { width = newW, height = newH })
                WBPopulateConcentrationTracker(frame)
            end
        end)
        dragger:SetScript("OnUpdate", function()
            if not dragger._dragging then return end
            local cx, cy = GetCursorPosition()
            local scale = frame:GetEffectiveScale()
            cx = cx / scale
            cy = cy / scale
            local dx = cx - dragStartX
            local dy = dragStartY - cy
            local newFrameWidth = math.max(320, math.min(700, dragStartW + dx))
            frame:SetSize(
                newFrameWidth,
                math.max(260, math.min(800, dragStartH + dy))
            )
            if frame.content then
                frame.content:SetWidth(math.max(newFrameWidth - 40, 300))
            end
            if frame.scrollUpdate then
                frame.scrollUpdate()
            end
        end)

        frame.titleBar = titleBar
        frame.summary = summary
        frame.refreshBtn = refreshBtn
        frame.scroll = scroll
        frame.content = content
        frame.scrollUpdate = scrollUpdate
        frame.scrollTrack = scrollTrack
        frame.emptyLabel = emptyLabel
        frame.closeBtn = closeBtn
        frame.minBtn = minBtn
        frame.cfgBtn = cfgBtn
        frame.dragger = dragger
        frame.widgets = {}

        self.concentrationTrackerFrame = frame
    end

    self.concentrationTrackerFrame:SetScale(self.db.profile.scale or 1)
    self.concentrationTrackerFrame:Show()
    if self.SetManagedWindowOpen then
        self:SetManagedWindowOpen("concentrationTrackerOpen", true)
    end
    WBApplyConcentrationTrackerLayout(self.concentrationTrackerFrame)
    WBPopulateConcentrationTracker(self.concentrationTrackerFrame)
end

function MR:HideConcentrationTracker(persistState)
    if self.concentrationTrackerFrame then
        self.concentrationTrackerFrame:Hide()
    end
    WBHideConcentrationTrackerOptions(self.concentrationTrackerFrame)
    if persistState ~= false and self.db and self.SetManagedWindowOpen then
        self:SetManagedWindowOpen("concentrationTrackerOpen", false)
    end
end

function MR:EnsureConcentrationTrackerShown()
    if self._instanceFramesHidden then
        if self.SetManagedWindowOpen then
            self:SetManagedWindowOpen("concentrationTrackerOpen", true)
        end
        return
    end
    if not (self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown()) then
        self:ToggleConcentrationTracker()
        return
    end

    if self.SetManagedWindowOpen then
        self:SetManagedWindowOpen("concentrationTrackerOpen", true)
    end
    WBApplyConcentrationTrackerLayout(self.concentrationTrackerFrame)
    WBPopulateConcentrationTracker(self.concentrationTrackerFrame)
end

function MR:BuildConcentrationTrackerConfigFrame()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetWidth(300)
    self:RegisterPriorityFrame(f)
    f:SetFrameLevel(40)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(f) end
    f:SetBackdropColor(0.03, 0.07, 0.12, 0.98)
    f:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
    f:Hide()

    local tbar = TitleBar(f, 22)
    tbar:SetBackdropColor(0.04, 0.11, 0.20, 1)
    tbar:SetScript("OnDragStart", function() f:StartMoving() end)
    tbar:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    local title = tbar:CreateFontString(nil, "OVERLAY")
    title:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
    title:SetPoint("LEFT", tbar, "LEFT", 8, 0)
    title:SetPoint("RIGHT", tbar, "RIGHT", -28, 0)
    title:SetJustifyH("LEFT")
    title:SetText(L["Options"] or "Options")
    title:SetTextColor(0.92, 0.97, 1.0)

    CloseButton(tbar, function() f:Hide() end)
    return f
end

function MR:PopulateConcentrationTrackerConfigFrame(f)
    if not f then
        return
    end

    if f.body then
        return
    end

    RefreshFonts()
    local keepLeft, keepTop
    if f.IsShown and f:IsShown() and self.CaptureFrameScreenPosition then
        keepLeft, keepTop = self:CaptureFrameScreenPosition(f)
    end

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    body:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.body = body

    local yOff = -28
    local pad = 8
    local cfgFs = (ns.GetFontSize and ns.GetFontSize()) or (MR.db and MR.db.profile and MR.db.profile.fontSize) or 9
    local contentW = (f:GetWidth() or 300) - (pad * 2)
    body:SetSize(f:GetWidth() or 300, 1)

    local function Gap(h) yOff = OptionsGap(body, yOff, h) end
    local function Divider() yOff = OptionsDivider(body, yOff, pad) end
    local function SectionLabel(text) yOff = OptionsSectionLabel(body, yOff, text, pad, cfgFs) end
    local function Check(label, getValue, setValue, r, g, b)
        yOff = OptionsCheckbox(body, yOff, label, getValue, setValue, r or 0.78, g or 0.78, b or 0.88, pad,
            function() MR:PopulateConcentrationTrackerConfigFrame(f) end, cfgFs)
    end
    local function Slider(label, minValue, maxValue, step, getValue, setValue, r, g, b)
        yOff = OptionsSlider(body, yOff, label, minValue, maxValue, step, getValue, setValue, r, g, b, pad, false, cfgFs)
    end

    SectionLabel(L["Config_Display"] or "Display")
    Slider(L["BACKGROUND"] or "BACKGROUND", 0, 1, 0.05,
        function() return WBGetConcentrationTrackerAlpha() end,
        function(value)
            WBSetConcentrationTrackerAlpha(value)
            if MR.concentrationTrackerFrame then
                WBApplyConcentrationTrackerLayout(MR.concentrationTrackerFrame)
                WBPopulateConcentrationTracker(MR.concentrationTrackerFrame)
            end
        end,
        0.40, 0.75, 0.82)

    Gap(2)
    Check(L["AltBoard_ConcentrationCompactMode"] or "Compact Mode",
        function() return WBIsConcentrationTrackerCompact() end,
        function(value)
            WBSetConcentrationTrackerCompact(value)
            if MR.concentrationTrackerFrame then
                WBPopulateConcentrationTracker(MR.concentrationTrackerFrame)
            end
        end,
        0.38, 0.90, 0.72)

    Gap(4)
    Divider()
    SectionLabel(L["AltBoard_ConcentrationCharacterVisibility"] or "Show / Hide Characters")

    local data = MR:GetWarbandWeeklyData()
    local anyCharacters = false
    for _, charEntry in ipairs(data or {}) do
        local concentrationEntries = type(charEntry.concentration) == "table" and charEntry.concentration or nil
        if concentrationEntries and #concentrationEntries > 0 then
            anyCharacters = true
            local label = string.format(
                (L["AltBoard_ConcentrationShowCharacter"] or "Show %s - %s"),
                charEntry.name or "?",
                charEntry.realm ~= "" and charEntry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm")
            )
            Check(label,
                function() return not WBIsConcentrationTrackerCharacterHidden(charEntry.key) end,
                function(value)
                    WBSetConcentrationTrackerCharacterHidden(charEntry.key, not value)
                    if MR.concentrationTrackerFrame then
                        WBPopulateConcentrationTracker(MR.concentrationTrackerFrame)
                    end
                end,
                0.78, 0.86, 0.95)
        end
    end

    if not anyCharacters then
        local empty = body:CreateFontString(nil, "OVERLAY")
        empty:SetFont(ns.FONT_ROWS, math.max(8, cfgFs - 1), GetFontFlags())
        empty:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
        empty:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
        empty:SetJustifyH("LEFT")
        empty:SetText(L["AltBoard_ConcentrationNone"] or "No concentration data on tracked characters yet.")
        empty:SetTextColor(0.68, 0.74, 0.84)
        yOff = yOff - 28
    end

    body:SetHeight(math.max(1, -yOff))
    f:SetHeight(math.max(150, -yOff + 10))
    if keepLeft and keepTop and self.RestoreFrameScreenPosition then
        self:RestoreFrameScreenPosition(f, keepLeft, keepTop)
    end
end

function MR:ToggleConcentrationTrackerConfig()
    if WBState.concentrationTrackerConfigFrame and WBState.concentrationTrackerConfigFrame:IsShown() then
        WBState.concentrationTrackerConfigFrame:Hide()
        return
    end

    if not WBState.concentrationTrackerConfigFrame then
        WBState.concentrationTrackerConfigFrame = self:BuildConcentrationTrackerConfigFrame()
    end

    self:PopulateConcentrationTrackerConfigFrame(WBState.concentrationTrackerConfigFrame)
    WBState.concentrationTrackerConfigFrame:ClearAllPoints()
    if self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown() then
        WBState.concentrationTrackerConfigFrame:SetPoint("TOPLEFT", self.concentrationTrackerFrame, "TOPRIGHT", 4, 0)
    else
        WBState.concentrationTrackerConfigFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    WBState.concentrationTrackerConfigFrame:Show()
    if self.CaptureFrameScreenPosition and self.RestoreFrameScreenPosition then
        local left, top = self:CaptureFrameScreenPosition(WBState.concentrationTrackerConfigFrame)
        self:RestoreFrameScreenPosition(WBState.concentrationTrackerConfigFrame, left, top)
    end
end

