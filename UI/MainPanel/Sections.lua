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
local SetFontIfChanged = UI.SetFontIfChanged
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
local HideTooltipIfOwned = UI.HideTooltipIfOwned
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

local function SetOneAnchor(region, point, relativeTo, relativePoint, x, y)
    if region._mrPoint1 == point
        and region._mrRelative1 == relativeTo
        and region._mrRelativePoint1 == relativePoint
        and region._mrX1 == x
        and region._mrY1 == y
        and region._mrPoint2 == nil then
        return
    end
    region:ClearAllPoints()
    region:SetPoint(point, relativeTo, relativePoint, x, y)
    region._mrPoint1, region._mrRelative1, region._mrRelativePoint1 = point, relativeTo, relativePoint
    region._mrX1, region._mrY1, region._mrPoint2, region._mrRelative2 = x, y, nil, nil
end

local function SetTwoAnchors(region, point1, relative1, relativePoint1, x1, y1, point2, relative2, relativePoint2, x2, y2)
    if region._mrPoint1 == point1
        and region._mrRelative1 == relative1
        and region._mrRelativePoint1 == relativePoint1
        and region._mrX1 == x1
        and region._mrY1 == y1
        and region._mrPoint2 == point2
        and region._mrRelative2 == relative2
        and region._mrRelativePoint2 == relativePoint2
        and region._mrX2 == x2
        and region._mrY2 == y2 then
        return
    end
    region:ClearAllPoints()
    region:SetPoint(point1, relative1, relativePoint1, x1, y1)
    region:SetPoint(point2, relative2, relativePoint2, x2, y2)
    region._mrPoint1, region._mrRelative1, region._mrRelativePoint1 = point1, relative1, relativePoint1
    region._mrX1, region._mrY1 = x1, y1
    region._mrPoint2, region._mrRelative2, region._mrRelativePoint2 = point2, relative2, relativePoint2
    region._mrX2, region._mrY2 = x2, y2
end

local function GetMainRenderRange(self)
    local scrollTop = self.scroll and self.scroll:GetVerticalScroll() or 0
    local viewHeight = self.scroll and self.scroll:GetHeight() or 0
    local buffer = math.max(ROW_HEIGHT * 3, viewHeight * 0.35)
    return scrollTop - buffer, scrollTop + viewHeight + buffer, viewHeight
end

local function IsMainRangeVisible(self, top, bottom)
    local renderTop, renderBottom, viewHeight = GetMainRenderRange(self)
    return viewHeight <= 0 or (bottom >= renderTop and top <= renderBottom)
end

local function PoolMainSectionWidget(self, modKey)
    local sections = self._mainSectionFrames
    local card = sections and sections[modKey]
    if not card then return end

    HideMainSectionWidget(card)
    sections[modKey] = nil
    if card._mrInMainSectionPool then return end

    local pool = self._mainSectionWidgetPool or {}
    self._mainSectionWidgetPool = pool
    card._mrInMainSectionPool = true
    pool[#pool + 1] = card
    self._mainSectionWidgetPooledCount = (self._mainSectionWidgetPooledCount or 0) + 1
end

local function PoolOutOfRangeMainRows(self, card)
    if not (card and card._rows) then return end

    local recycleKeys = card._recycleRowKeys or {}
    card._recycleRowKeys = recycleKeys
    for i = #recycleKeys, 1, -1 do
        recycleKeys[i] = nil
    end

    local sectionY = card._mrLayoutY or 0
    for key, rowFrame in pairs(card._rows) do
        local rowTop = sectionY + (rowFrame._mrLayoutY or 0)
        local rowBottom = rowTop + (rowFrame._mrLayoutHeight or ROW_HEIGHT)
        if not IsMainRangeVisible(self, rowTop, rowBottom) then
            recycleKeys[#recycleKeys + 1] = key
        end
    end
    for _, key in ipairs(recycleKeys) do
        PoolMainRowWidget(card, key, card._rows[key])
    end
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

    local expansionHeaderH = expansionHeaderKey and 22 or 0
    local sectionHeight = math.max((stats and stats.height or 0) - SECTION_GAP, HEADER_HEIGHT + 1) + expansionHeaderH
    if not IsMainRangeVisible(self, yOff, yOff + sectionHeight) then
        PoolMainSectionWidget(self, mod.key)
        if recordRegistry ~= false then
            AddSectionRegistryEntry(self, nil, mod.key, col or 1, yOff, yOff + (stats and stats.height or 0) + expansionHeaderH, expansionHeaderKey)
        end
        return nil
    end

    local allDone = (secTotal > 0) and (secDone == secTotal)
    local card = EnsureMainSectionWidget(self, mod.key)
    local cardWidth = math.max(colW - 6, 1)
    if card._mrLayoutParent ~= self.content
        or card._mrLayoutX ~= xOff
        or card._mrLayoutY ~= yOff
        or card._mrLayoutWidth ~= cardWidth
        or card._mrLayoutHeight ~= sectionHeight then
        card:ClearAllPoints()
        card:SetPoint("TOPLEFT", self.content, "TOPLEFT", xOff + 3, -yOff)
        card:SetSize(cardWidth, sectionHeight)
        card._mrLayoutParent = self.content
        card._mrLayoutX = xOff
        card._mrLayoutY = yOff
        card._mrLayoutWidth = cardWidth
        card._mrLayoutHeight = sectionHeight
    end
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
            SetTwoAnchors(card._expHeader,
                "TOPLEFT", card, "TOPLEFT", 0, 0,
                "TOPRIGHT", card, "TOPRIGHT", 0, 0)
            card._expHeader:SetHeight(expansionHeaderH - 3)
            card._expHeader:SetBackdropColor(0.035, 0.055, 0.070, transparent and 0 or (0.86 * frameAlpha))
            card._expHeader:SetBackdropBorderColor(0.14, 0.30, 0.34, transparent and 0 or (0.80 * frameAlpha))
            SetTwoAnchors(card._expHeader._label,
                "LEFT", card._expHeader, "LEFT", 7, 0,
                "RIGHT", card._expHeader, "RIGHT", -7, 0)
            SetFontIfChanged(card._expHeader._label, FONT_HEADERS, math.max(8, GetFontSize() - 1), GetFontFlags())
            card._expHeader._label:SetText(label)
            card._expHeader._label:SetTextColor(0.72, 0.86, 0.88, transparent and 0.85 or 0.95)
            card._expHeader:Show()
        else
            card._expHeader:Hide()
        end
    end

    SetTwoAnchors(card._hdrFrame,
        "TOPLEFT", card, "TOPLEFT", 0, -expansionHeaderH,
        "TOPRIGHT", card, "TOPRIGHT", 0, -expansionHeaderH)
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
    if mod.profSkillLine and not explicitColor then
        headerColor = "#f5f7fa"
    end
    local lr, lg, lb = hex(headerColor)
    local accentA = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 1 or 0) * frameAlpha)
    local accentR, accentG, accentB = lr, lg, lb
    if allDone then
        accentR, accentG, accentB = COL.complete[1], COL.complete[2], COL.complete[3]
    end

    card._hdrFrame._iconPlate:SetSize(math.max(HEADER_HEIGHT - 6, 12), math.max(HEADER_HEIGHT - 6, 12))
    SetOneAnchor(card._hdrFrame._iconPlate, "LEFT", card._hdrFrame, "LEFT", 4, 0)
    local iconPlateBgAlpha = transparent and (showSoftHeaders and (0.16 * accentA) or 0) or ((showSectionHeaders and 0.16 or 0) * frameAlpha)
    local iconPlateBorderAlpha = transparent and (showSoftHeaders and (0.50 * accentA) or 0) or ((showSectionHeaders and 0.50 or 0) * frameAlpha)
    card._hdrFrame._iconPlate:SetBackdropColor(accentR, accentG, accentB, iconPlateBgAlpha)
    card._hdrFrame._iconPlate:SetBackdropBorderColor(accentR, accentG, accentB, iconPlateBorderAlpha)

    local iconInfo = showIcons and ShouldShowModuleHeaderIcon(mod.key) and GetModuleIconInfo(mod) or nil
    card._hdrFrame._icon:SetSize(math.max(HEADER_HEIGHT - 12, 9), math.max(HEADER_HEIGHT - 12, 9))
    SetOneAnchor(card._hdrFrame._icon, "CENTER", card._hdrFrame._iconPlate, "CENTER", 0, 0)
    local hasHeaderIcon = ApplyIconToTexture(card._hdrFrame._icon, iconInfo, { 0.14, 0.86, 0.14, 0.86 })
    card._hdrFrame._iconPlate:SetShown(hasHeaderIcon and (showIcons or showSectionHeaders))

    SetFontIfChanged(card._hdrFrame._label, FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
    card._hdrFrame._label:SetJustifyH("LEFT")
    if card._hdrFrame._label.SetWordWrap then
        card._hdrFrame._label:SetWordWrap(false)
    end
    card._hdrFrame._label:SetText((allDone and not explicitColor) and WC("00ff96", mod.label) or WC(headerColor:gsub("#", ""), mod.label))

    SetFontIfChanged(card._hdrFrame._count, FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    local currencyBrowserButton = card._hdrFrame._currencyBrowserButton
    local showCurrencyBrowserButton = mod.key == "currencies" and MR.ToggleCurrencyBrowserFrame
    if showCurrencyBrowserButton then
        SetOneAnchor(currencyBrowserButton, "RIGHT", card._hdrFrame, "RIGHT", -23, 0)
        StyleCurrencyBrowserButton(currencyBrowserButton, transparent, frameAlpha)
        currencyBrowserButton:Show()
        SetOneAnchor(card._hdrFrame._count, "RIGHT", currencyBrowserButton, "LEFT", -8, 0)
    else
        currencyBrowserButton:Hide()
        SetOneAnchor(card._hdrFrame._count, "RIGHT", card._hdrFrame, "RIGHT", -22, 0)
    end
    card._hdrFrame._count:SetText(showCurrencyBrowserButton
        and string.format("%d / %d", secDone, secTotal)
        or string.format("%d / %d", secDone, secTotal))
    card._hdrFrame._count:SetTextColor(countColor(secDone, secTotal))
    card._hdrFrame._count:SetJustifyH("RIGHT")
    local labelLeft = hasHeaderIcon and card._hdrFrame._iconPlate or card._hdrFrame
    SetTwoAnchors(card._hdrFrame._label,
        "LEFT", labelLeft, hasHeaderIcon and "RIGHT" or "LEFT", hasHeaderIcon and 6 or 9, 0,
        "RIGHT", card._hdrFrame._count, "LEFT", -8, 0)

    StyleSectionCollapseIndicator(card._hdrFrame._arrow, isOpen)

    local localY = expansionHeaderH + HEADER_HEIGHT
    SetTwoAnchors(card._divider,
        "TOPLEFT", card, "TOPLEFT", 0, -localY,
        "TOPRIGHT", card, "TOPRIGHT", 0, -localY)
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
            local absoluteTop = yOff + rowY
            local absoluteBottom = absoluteTop + ROW_HEIGHT
            if not IsMainRangeVisible(self, absoluteTop, absoluteBottom) then
                return nil, rowY + ROW_HEIGHT, row.key or tostring(row.label or rowY)
            end
            return UpdateMainRowWidget(self, card, mod, row, done, rowY, card:GetWidth())
        end)
    end

    local recycleKeys = card._recycleRowKeys or {}
    card._recycleRowKeys = recycleKeys
    for index = #recycleKeys, 1, -1 do recycleKeys[index] = nil end
    for key in pairs(card._rows or {}) do
        if not usedRows[key] then recycleKeys[#recycleKeys + 1] = key end
    end
    for _, key in ipairs(recycleKeys) do
        PoolMainRowWidget(card, key, card._rows[key])
    end

    if recordRegistry ~= false then
        AddSectionRegistryEntry(self, card, mod.key, col or 1, yOff, yOff + (stats and stats.height or 0) + expansionHeaderH, expansionHeaderKey)
    end
    return card
end

function MR:RefreshMainPanelViewport()
    if self._mainViewportRefreshInProgress or self._refreshUIInProgress then
        return false
    end
    if not (self.frame and self.frame:IsShown() and self.scroll and self.content) then
        return false
    end

    local assignments = self._modColAssignBuffer
    local count = self._modColAssignCount or 0
    local colW = self._mainPanelColumnWidth
    if not assignments or count == 0 or not colW then
        return false
    end

    local scrollTop = self.scroll:GetVerticalScroll() or 0
    local viewHeight = self.scroll:GetHeight() or 0
    local viewBottom = scrollTop + viewHeight
    if self._mainMaterializedTop
        and scrollTop >= (self._mainMaterializedTop + ROW_HEIGHT)
        and viewBottom <= (self._mainMaterializedBottom - ROW_HEIGHT) then
        return false
    end

    self._mainViewportRefreshInProgress = true
    local timerRows = self._timerRows
    if timerRows then
        for i = #timerRows, 1, -1 do
            timerRows[i] = nil
        end
    end

    for i = 1, count do
        local assign = assignments[i]
        if assign and assign.mod then
            local stats = GetModuleStats(self, assign.mod)
            local expansionHeaderH = assign.expansionHeaderKey and 22 or 0
            local sectionHeight = math.max((stats and stats.height or 0) - SECTION_GAP, HEADER_HEIGHT + 1) + expansionHeaderH
            if not IsMainRangeVisible(self, assign.yOff or 0, (assign.yOff or 0) + sectionHeight) then
                PoolMainSectionWidget(self, assign.mod.key)
            end
        end
    end

    if self._mainSectionFrames then
        for _, card in pairs(self._mainSectionFrames) do
            PoolOutOfRangeMainRows(self, card)
        end
    end
    for i = 1, count do
        local assign = assignments[i]
        if assign and assign.mod then
            local xOff = ((assign.col or 1) - 1) * colW
            UpdateMainSectionWidget(self, assign.mod, assign.yOff or 0, xOff, colW, assign.col, false, assign.expansionHeaderKey)
        end
    end
    self._mainMaterializedTop, self._mainMaterializedBottom = GetMainRenderRange(self)
    self._mainViewportRefreshCount = (self._mainViewportRefreshCount or 0) + 1
    self._mainViewportRefreshInProgress = nil

    if self.UpdateTimerRowTicker then
        self:UpdateTimerRowTicker()
    end
    return true
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
    self._mainMaterializedTop = nil
    self._mainMaterializedBottom = nil
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
            local section = UpdateMainSectionWidget(self, assign.mod, assign.yOff, xOff, colW, assign.col, true, assign.expansionHeaderKey)
            if section then
                activeMainSections[assign.mod.key] = true
                self.widgets[#self.widgets + 1] = section
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

    local frameW = MR.db.profile.width or 260
    local usableW = frameW - 9
    local MIN_COL = 200
    local numCols = math.max(1, math.floor(usableW / MIN_COL))
    if numCols ~= 1 then
        return false
    end

    RecalcLayout()
    self._mainMaterializedTop = nil
    self._mainMaterializedBottom = nil
    local newOpen = not MR:IsModuleOpen(modKey)
    MR:SetModuleOpen(modKey, newOpen)
    stats.isOpen = newOpen
    stats.height = stats.shownRows == 0 and 0 or (HEADER_HEIGHT + 1 + SECTION_GAP + (newOpen and (stats.shownRows * ROW_HEIGHT) or 0))

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


UI.UpdateMainSectionWidget = UpdateMainSectionWidget
UI.ClearArrayContents = ClearArrayContents
UI.IsMainTextOnlyMode = IsMainTextOnlyMode
UI.GetTextOnlyHeaderAlpha = GetTextOnlyHeaderAlpha
UI.ShouldShowIcons = ShouldShowIcons
UI.ShouldShowSectionHeaders = ShouldShowSectionHeaders

