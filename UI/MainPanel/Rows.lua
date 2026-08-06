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
    region._mrPoint1 = point
    region._mrRelative1 = relativeTo
    region._mrRelativePoint1 = relativePoint
    region._mrX1 = x
    region._mrY1 = y
    region._mrPoint2 = nil
    region._mrRelative2 = nil
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
    region._mrPoint1 = point1
    region._mrRelative1 = relative1
    region._mrRelativePoint1 = relativePoint1
    region._mrX1 = x1
    region._mrY1 = y1
    region._mrPoint2 = point2
    region._mrRelative2 = relative2
    region._mrRelativePoint2 = relativePoint2
    region._mrX2 = x2
    region._mrY2 = y2
end

local function SetWidthIfChanged(region, width)
    if region._mrLayoutWidth ~= width then
        region:SetWidth(width)
        region._mrLayoutWidth = width
    end
end

local function MainRowOnEnter(selfRow)
    local data = selfRow._mrData
    if not data then
        return
    end

    if data.mode == "sectionHeader" then
        if data.row.note then
            ns.ShowTooltip(selfRow, {
                build = function(tooltip)
                    tooltip:SetText(data.row.label, 1, 1, 1)
                    tooltip:AddLine(data.row.note, 0.70, 0.70, 0.76, true)
                end,
            })
        end
        return
    end

    if data.mode == "collapsed" then
        ns.ShowTooltip(selfRow, {
            build = function(tooltip)
                tooltip:SetText(L["Tooltip_DonePrefix"] .. data.row.label, 0.4, 0.85, 0.4, 1, true)
                tooltip:AddLine(L["Tooltip_CompletedWeek"], 0.3, 0.6, 0.3)
            end,
        })
        return
    end

    if selfRow._hover then
        selfRow._hover:SetColorTexture(1, 1, 1, data.transparent and 0 or (0.04 * data.frameAlpha))
    end

    local row = data.row
    if data.mod and data.mod.profSkillLine and row.profKnowledgeCatchup and MR.ShowProfessionKnowledgeCatchupTooltip then
        MR:ShowProfessionKnowledgeCatchupTooltip(selfRow, row)
        return
    end

    if data.mod and data.mod.profSkillLine and (row.professionKnowledgeEntry or row.profKnowledgeSectionKey) and MR.ShowProfessionKnowledgeSourceTooltip then
        MR:ShowProfessionKnowledgeSourceTooltip(selfRow, row, row.profKnowledgeSectionKey)
        return
    end

    ns.ShowTooltip(selfRow, {
        build = function(tooltip)
            if row.currencyId and not row.noBlizzardTooltip then
                tooltip:SetCurrencyByID(row.currencyId)
                tooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
                if row.tooltipFunc then
                    row.tooltipFunc(tooltip)
                end
            elseif row.itemId and not row.noBlizzardTooltip then
                if tooltip.SetItemByID then
                    tooltip:SetItemByID(row.itemId)
                else
                    tooltip:SetHyperlink("item:" .. row.itemId)
                end
                tooltip:AddLine(L["Tooltip_AutoItem"], 0.9, 0.6, 1)
            else
                tooltip:SetText(row.label, 1, 1, 1, 1, true)
                if row.note then
                    tooltip:AddLine(row.note, 0.7, 0.7, 0.7, true)
                end
                if data.hasWaypoint then
                    tooltip:AddLine(" ")
                    tooltip:AddLine(string.format(L["Gathering_Coords"], row.x, row.y), 0.7, 1, 0.9)
                    tooltip:AddLine(L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
                end
                if row.tooltipFunc then
                    row.tooltipFunc(tooltip)
                end
                if row.noDefaultTooltipHint then
                elseif row.liveKey or row.autoTracked or (row.currencyId and row.noBlizzardTooltip) then
                    tooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
                elseif row.questIds then
                    tooltip:AddLine(L["Tooltip_AutoQuest"], 0.4, 1, 0.6)
                elseif row.spellId or row.itemId then
                    tooltip:AddLine(L["Tooltip_AutoItem"], 0.9, 0.6, 1)
                elseif not data.hasWaypoint then
                    tooltip:AddLine(L["Tooltip_ManualClick"], 0.5, 0.5, 0.5)
                end
            end
        end,
    })
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

    if button == "LeftButton" and mod and mod.profSkillLine and (row.professionKnowledgeEntry or row.profKnowledgeSectionKey) and MR.SetProfessionKnowledgeWaypoint then
        MR:SetProfessionKnowledgeWaypoint(row, row.profKnowledgeSectionKey)
        return
    elseif button == "LeftButton" and data.hasWaypoint then
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
    if data.mod and data.mod.profSkillLine and row.profKnowledgeCatchup and MR.ShowProfessionKnowledgeCatchupTooltip then
        MR:ShowProfessionKnowledgeCatchupTooltip(selfBtn, row)
        return
    end
    if data.mod and data.mod.profSkillLine and (row.professionKnowledgeEntry or row.profKnowledgeSectionKey) and MR.ShowProfessionKnowledgeSourceTooltip then
        MR:ShowProfessionKnowledgeSourceTooltip(selfBtn, row, row.profKnowledgeSectionKey)
        return
    end

    local mo = row.toggleStatus and MR:GetProgress(data.mod.key, row.key) or MR:GetManualOverride(data.mod.key, row.key)
    ns.ShowTooltip(selfBtn, {
        build = function(tooltip)
            tooltip:SetText(row.label, 1, 1, 1, 1, true)
            if row.note then
                tooltip:AddLine(row.note, 0.7, 0.7, 0.7, true)
            end
            tooltip:AddLine(" ")
            if mo >= row.max then
                tooltip:AddLine(L["Tooltip_ManualDot_Active"], 1, 0.85, 0.1, true)
            else
                tooltip:AddLine(L["Tooltip_ManualDot_Hint"], 0.7, 0.7, 0.7, true)
            end
        end,
    })
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

local function PoolMainRowWidget(section, key, rowFrame)
    HideMainRowWidget(rowFrame)
    if section and section._rows and section._rows[key] == rowFrame then
        section._rows[key] = nil
    end
    if rowFrame._mrInMainRowPool then
        return
    end
    MR._mainRowWidgetPools = MR._mainRowWidgetPools or {}
    local poolKind = rowFrame._mrWidgetKind or "normal"
    local pool = MR._mainRowWidgetPools[poolKind]
    if not pool then
        pool = {}
        MR._mainRowWidgetPools[poolKind] = pool
    end
    rowFrame._mrInMainRowPool = true
    pool[#pool + 1] = rowFrame
    MR._mainRowWidgetPooledCount = (MR._mainRowWidgetPooledCount or 0) + 1
end

local function HideMainSectionWidget(section)
    if not section then
        return
    end

    if section._hdrFrame then
        HideTooltipIfOwned(section._hdrFrame)
    end
    if section._rows then
        local recycleKeys = section._recycleRowKeys or {}
        section._recycleRowKeys = recycleKeys
        for index = #recycleKeys, 1, -1 do recycleKeys[index] = nil end
        for key in pairs(section._rows) do recycleKeys[#recycleKeys + 1] = key end
        for _, key in ipairs(recycleKeys) do
            PoolMainRowWidget(section, key, section._rows[key])
        end
    end
    section:Hide()
end

local function HideMainExpansionHeaderWidget(frame)
    if frame then
        frame:Hide()
    end
end

local function GetTextOnlyHeaderAlpha(...)
    local fn = UI.GetTextOnlyHeaderAlpha
    return fn and fn(...) or 0
end

local function ShouldShowIcons(...)
    local fn = UI.ShouldShowIcons
    return fn and fn(...) or false
end

local function ShouldShowSectionHeaders(...)
    local fn = UI.ShouldShowSectionHeaders
    return fn and fn(...) or false
end
local UIIcons = ns.UIIcons
local GetRowIconInfo = UIIcons.GetRow
local GetModuleIconInfo = UIIcons.GetModule
local ShouldShowModuleHeaderIcon = UIIcons.ShouldShowModuleHeader
local ApplyIconToTexture = UIIcons.ApplyToTexture
local EnsureMainRowWidget
local UpdateMainRowWidget

local function GetMainRowGroupKey(row)
    local group = row and row.group
    if group then
        return group
    end
    return nil
end

local function IsMainRowVisible(mod, row)
    return MR.IsRowVisibleForCharacter and MR:IsRowVisibleForCharacter(mod, row) or (not row.isVisible or row.isVisible())
end

local function IsMainRowInGroup(mod, row, group)
    return GetMainRowGroupKey(row) == group and IsMainRowVisible(mod, row)
end

local function HasVisibleRowsInMainGroup(mod, rows, group)
    for _, row in ipairs(rows or {}) do
        if IsMainRowInGroup(mod, row, group) then
            return true
        end
    end
    return false
end

local function IsMainRowGroupEnabled(mod, group)
    if not (mod and mod.key and group) then
        return true
    end

    for _, row in ipairs(mod.rows or {}) do
        if IsMainRowInGroup(mod, row, group) and not MR:IsRowEnabled(mod.key, row.key) then
            return false
        end
    end

    return true
end

local function SetMainRowGroupEnabled(mod, group, enabled)
    if not (mod and mod.key and group) then
        return
    end

    MR._suspendProfessionKnowledgeSurfaceRefresh = true
    for _, row in ipairs(mod.rows or {}) do
        if IsMainRowInGroup(mod, row, group) then
            MR:SetRowEnabled(mod.key, row.key, enabled, true)
        end
    end
    MR._suspendProfessionKnowledgeSurfaceRefresh = nil
    MR:RefreshUI()
    MR:RequestProfessionKnowledgeSurfaceRefresh()
end

local function BuildMainRowGroupHeader(mod, group)
    MR._mainRowGroupHeaderCache = MR._mainRowGroupHeaderCache or {}
    local cacheKey = tostring(mod.key) .. "\001" .. tostring(group)
    local header = MR._mainRowGroupHeaderCache[cacheKey]
    if not header then
        header = {
            key = "__group_" .. tostring(group),
            control = true,
            sectionHeader = true,
            hideStatus = true,
            noDefaultTooltipHint = true,
            headerActionStyle = "visibility",
            onHeaderActionClick = function(row)
                local headerRow = row and row._mrGroupHeader or header
                local headerMod = headerRow._mrMod
                local headerGroup = headerRow._mrGroup
                SetMainRowGroupEnabled(headerMod, headerGroup, not IsMainRowGroupEnabled(headerMod, headerGroup))
            end,
        }
        MR._mainRowGroupHeaderCache[cacheKey] = header
    end

    local visible = IsMainRowGroupEnabled(mod, group)
    local label = (ns.GetRowGroupLabel and ns.GetRowGroupLabel(group)) or tostring(group)
    header.label = label
    header.headerActionVisible = visible
    header._mrMod = mod
    header._mrGroup = group
    header._mrGroupHeader = header
    return header
end

local function ShouldRenderMainRowGroupHeader(self, mod, rows, group, hideComplete)
    if not IsMainRowGroupEnabled(mod, group) then
        return true
    end

    for _, row in ipairs(rows or {}) do
        if IsMainRowInGroup(mod, row, group) and MR:IsRowEnabled(mod.key, row.key) then
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
    local lastGroup
    for _, row in ipairs(rows or {}) do
        local rowVisible = IsMainRowVisible(mod, row)
        local group = GetMainRowGroupKey(row)
        if rowVisible and group and group ~= lastGroup and HasVisibleRowsInMainGroup(mod, rows, group) and ShouldRenderMainRowGroupHeader(self, mod, rows, group, hideComplete) then
            local header = BuildMainRowGroupHeader(mod, group)
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

local function CountMainGroupedRows(self, mod, rows, hideComplete, isOpen)
    local shownRows = 0
    local extraHeight = 0
    local lastGroup
    for _, row in ipairs(rows or {}) do
        local rowVisible = IsMainRowVisible(mod, row)
        local group = GetMainRowGroupKey(row)
        if rowVisible and group and group ~= lastGroup and HasVisibleRowsInMainGroup(mod, rows, group) and ShouldRenderMainRowGroupHeader(self, mod, rows, group, hideComplete) then
            shownRows = shownRows + 1
            if isOpen then
                extraHeight = extraHeight + ROW_HEIGHT
            end
        end
        lastGroup = group

        if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
            local done = MR:GetProgress(mod.key, row.key)
            local rowComplete = self:IsRowComplete(mod, row, done)
            if row.control or not (hideComplete and rowComplete) then
                shownRows = shownRows + 1
                if isOpen then
                    extraHeight = extraHeight + ROW_HEIGHT
                end
            end
        end
    end

    return shownRows, extraHeight
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
    frame:SetBackdrop(MakeBackdrop())
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
    frame:SetBackdropColor(0.035, 0.055, 0.070, 0.86 * frameAlpha)
    frame:SetBackdropBorderColor(0.14, 0.30, 0.34, 0.80 * frameAlpha)
    frame._label:SetFont(ns.FONT_HEADERS, math.max(8, GetFontSize() - 1), GetFontFlags())
    frame._label:SetPoint("LEFT", frame, "LEFT", 7, 0)
    frame._label:SetPoint("RIGHT", frame, "RIGHT", -7, 0)
    frame._label:SetText(label)
    frame._label:SetTextColor(0.72, 0.86, 0.88, 0.95)
    return frame
end

local function CreateSectionWidget(parent, includeExpansionHeader, registerDrag)
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetBackdrop(MakeBackdrop())
    card._glow = card:CreateTexture(nil, "BACKGROUND")
    card._glow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    card._glow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    card._glow:SetTexture("Interface\\Buttons\\WHITE8X8")

    if includeExpansionHeader then
        card._expHeader = CreateFrame("Frame", nil, card, "BackdropTemplate")
        card._expHeader:SetBackdrop(MakeBackdrop())
        card._expHeader._label = card._expHeader:CreateFontString(nil, "OVERLAY")
        card._expHeader._label:SetJustifyH("LEFT")
    end

    card._hdrFrame = CreateFrame("Frame", nil, card)
    card._hdrFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    card._hdrFrame:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    card._hdrFrame:EnableMouse(true)
    if registerDrag then
        card._hdrFrame:RegisterForDrag("LeftButton")
    end
    card._hdrFrame._hdrHover = card._hdrFrame:CreateTexture(nil, "BORDER")
    card._hdrFrame._hdrHover:SetAllPoints()
    card._hdrFrame._hdrBg = card._hdrFrame:CreateTexture(nil, "BACKGROUND")
    card._hdrFrame._hdrBg:SetAllPoints()
    card._hdrFrame._iconPlate = CreateFrame("Frame", nil, card._hdrFrame, "BackdropTemplate")
    card._hdrFrame._iconPlate:SetBackdrop(MakeBackdrop())
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
    card._hdrFrame._currencyBrowserText:SetFont(ns.FONT_ROWS, 12, GetFontFlags())
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
    return card
end

local function EnsureMainSectionWidget(self, modKey)
    self._mainSectionFrames = self._mainSectionFrames or {}
    local card = self._mainSectionFrames[modKey]
    if card then
        if card:GetParent() ~= self.content then
            card:SetParent(self.content)
        end
        card:Show()
        return card
    end

    card = CreateSectionWidget(self.content, true, false)
    self._mainSectionFrames[modKey] = card
    return card
end

local function EnsureDetachedSectionWidget(frame, modKey)
    frame._sectionFrames = frame._sectionFrames or {}
    local card = frame._sectionFrames[modKey]
    if card then
        if card:GetParent() ~= frame.content then
            card:SetParent(frame.content)
        end
        card:Show()
        return card
    end

    card = CreateSectionWidget(frame.content, false, true)
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
    if mod.profSkillLine and not explicitColor then
        headerColor = "#f5f7fa"
    end
    local lr, lg, lb = hex(headerColor)
    local accentA = transparent and textOnlyHeaderAlpha or ((showSectionHeaders and 1 or 0) * frameAlpha)
    local accentR, accentG, accentB = lr, lg, lb
    if allDone then
        accentR, accentG, accentB = COL.complete[1], COL.complete[2], COL.complete[3]
    end

    card._hdrFrame._iconPlate:ClearAllPoints()
    card._hdrFrame._iconPlate:SetSize(math.max(HEADER_HEIGHT - 6, 12), math.max(HEADER_HEIGHT - 6, 12))
    card._hdrFrame._iconPlate:SetPoint("LEFT", card._hdrFrame, "LEFT", 4, 0)
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

    card._hdrFrame._label:SetFont(ns.FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
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

    card._hdrFrame._count:SetFont(ns.FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
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

    local recycleKeys = card._recycleRowKeys or {}
    card._recycleRowKeys = recycleKeys
    for index = #recycleKeys, 1, -1 do recycleKeys[index] = nil end
    for key, rowFrame in pairs(card._rows or {}) do
        if not usedRows[key] then
            recycleKeys[#recycleKeys + 1] = key
        end
    end
    for _, key in ipairs(recycleKeys) do
        PoolMainRowWidget(card, key, card._rows[key])
    end

    return card
end

EnsureMainRowWidget = function(section, rowKey, widgetKind)
    section._rows = section._rows or {}
    local rowFrame = section._rows[rowKey]
    if rowFrame then
        if rowFrame:GetParent() ~= section then
            rowFrame:SetParent(section)
        end
        rowFrame:Show()
        return rowFrame
    end

    local pool = MR._mainRowWidgetPools and MR._mainRowWidgetPools[widgetKind]
    if pool and #pool > 0 then
        rowFrame = table.remove(pool)
        rowFrame._mrInMainRowPool = nil
        MR._mainRowWidgetReusedCount = (MR._mainRowWidgetReusedCount or 0) + 1
        rowFrame:SetParent(section)
    else
        rowFrame = CreateFrame("Frame", nil, section)
        MR._mainRowWidgetCreatedCount = (MR._mainRowWidgetCreatedCount or 0) + 1
    end
    rowFrame._mrWidgetKind = widgetKind
    if rowFrame._mrRowWidgetInitialized then
        section._rows[rowKey] = rowFrame
        rowFrame:Show()
        return rowFrame
    end
    rowFrame._mrRowWidgetInitialized = true
    rowFrame:EnableMouse(true)
    rowFrame:SetScript("OnEnter", MainRowOnEnter)
    rowFrame:SetScript("OnLeave", MainRowOnLeave)
    rowFrame:SetScript("OnMouseDown", MainRowOnMouseDown)

    rowFrame._hover = rowFrame:CreateTexture(nil, "BACKGROUND")
    rowFrame._hover:SetAllPoints()
    rowFrame._rowShade = rowFrame:CreateTexture(nil, "BORDER")
    rowFrame._rowShade:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", 0, -1)
    rowFrame._rowShade:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", 0, 0)
    rowFrame._separator = rowFrame:CreateTexture(nil, "ARTWORK")
    rowFrame._separator:SetPoint("BOTTOMLEFT", rowFrame, "BOTTOMLEFT", 12, 0)
    rowFrame._separator:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", -12, 0)
    rowFrame._separator:SetHeight(1)

    rowFrame._statusBtn = CreateFrame("Button", nil, rowFrame, "BackdropTemplate")
    rowFrame._statusBtn:SetBackdrop(MakeBackdrop())
    rowFrame._statusBtn:SetSize(14, 14)
    rowFrame._statusBtn:SetPoint("LEFT", rowFrame, "LEFT", PADDING + 2, 0)
    rowFrame._statusBtn._mrOwner = rowFrame
    rowFrame._statusBtn:SetScript("OnClick", MainStatusButtonOnClick)
    rowFrame._statusBtn:SetScript("OnEnter", MainStatusButtonOnEnter)
    rowFrame._statusBtn:SetScript("OnLeave", MainStatusButtonOnLeave)
    rowFrame._statusFill = rowFrame._statusBtn:CreateTexture(nil, "ARTWORK")
    rowFrame._statusFill:SetPoint("TOPLEFT", rowFrame._statusBtn, "TOPLEFT", 2, -2)
    rowFrame._statusFill:SetPoint("BOTTOMRIGHT", rowFrame._statusBtn, "BOTTOMRIGHT", -2, 2)
    rowFrame._statusCheck = rowFrame._statusBtn:CreateFontString(nil, "OVERLAY")
    rowFrame._statusCheck:SetFont(ns.FONT_HEADERS, 9, GetFontFlags())
    rowFrame._statusCheck:SetPoint("CENTER", rowFrame._statusBtn, "CENTER", 0, 1)
    rowFrame._statusCheck:SetText("x")

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
    rowFrame._count:SetFont(ns.FONT_ROWS, GetFontSize(), GetFontFlags())
    section._rows[rowKey] = rowFrame
    return rowFrame
end

local function EnsureMainRowHeaderParts(rowFrame)
    if rowFrame._headerBg then return end

    rowFrame._headerBg = rowFrame:CreateTexture(nil, "BACKGROUND")
    rowFrame._headerBg:SetAllPoints()
    rowFrame._headerText = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._headerActionButton = CreateFrame("Button", nil, rowFrame, "BackdropTemplate")
    rowFrame._headerActionButton:SetBackdrop(MakeBackdrop())
    rowFrame._headerActionButton._mrOwner = rowFrame
    rowFrame._headerActionButton:SetScript("OnClick", MainHeaderActionOnClick)
    rowFrame._headerActionButton:SetScript("OnEnter", MainHeaderActionOnEnter)
    rowFrame._headerActionButton:SetScript("OnLeave", MainHeaderActionOnLeave)
    rowFrame._headerActionText = rowFrame._headerActionButton:CreateFontString(nil, "OVERLAY")
    rowFrame._headerActionText:SetFont(ns.FONT_ROWS, 9, GetFontFlags())
    rowFrame._headerCount = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._headerCount:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
    MR._mainRowOptionalPartCreatedCount = (MR._mainRowOptionalPartCreatedCount or 0) + 5
end

local function EnsureMainRowTexture(rowFrame, key)
    local texture = rowFrame[key]
    if not texture then
        texture = rowFrame:CreateTexture(nil, "ARTWORK")
        rowFrame[key] = texture
        local iconSize = math.max(ROW_HEIGHT - 8, 12)
        texture:SetSize(iconSize, iconSize)
        if key == "_rowIcon" then
            texture:SetPoint("LEFT", rowFrame._statusBtn, "RIGHT", 8, 0)
        elseif key == "_countIcon" then
            texture:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
        end
        MR._mainRowOptionalPartCreatedCount = (MR._mainRowOptionalPartCreatedCount or 0) + 1
    end
    return texture
end

local function EnsureMainRowText(rowFrame, key)
    local fontString = rowFrame[key]
    if not fontString then
        fontString = rowFrame:CreateFontString(nil, "OVERLAY")
        rowFrame[key] = fontString
        MR._mainRowOptionalPartCreatedCount = (MR._mainRowOptionalPartCreatedCount or 0) + 1
    end
    return fontString
end

local function GetMainRowWidgetKind(mod, row)
    if row.sectionHeader then
        local kind = "header"
        if ((row.headerActionText and row.headerActionText ~= "") or row.headerActionStyle == "visibility") and row.onHeaderActionClick then
            kind = kind .. ":action"
        end
        if row.countText then
            kind = kind .. ":count"
        end
        return kind
    end

    local kind = "normal"
    local isProfessionRow = mod and mod.profSkillLine
    local isCurrencyRow = mod and (mod.key == "currencies" or mod.key == "pvp_currencies") and row.currencyId
    if isProfessionRow then kind = kind .. ":profession" end
    if isCurrencyRow then kind = kind .. ":currency" end
    if row.zone and row.x and row.y and not row.hideCoordText and not isProfessionRow then kind = kind .. ":coords" end
    if (type(row.kpTotal) == "number" and row.kpTotal > 0) or row.vaultLabel then kind = kind .. ":detail" end
    if row.encounterIds and row.taskId then kind = kind .. ":difficulty" end
    return kind
end

local function EnsureMainDifficultyBadges(rowFrame)
    if rowFrame._diffBadges then
        return
    end

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
        lbl:SetFont(ns.FONT_ROWS, math.max(6, GetFontSize() - 3), GetFontFlags())
        lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
        lbl:SetText(def.label)
        btn._lbl = lbl
        btn._diffId = def.id
        btn:Hide()
        rowFrame._diffBadges[i] = btn
    end
    rowFrame._diffCount = rowFrame:CreateFontString(nil, "OVERLAY")
    rowFrame._diffCount:SetFont(ns.FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    MR._mainRowOptionalPartCreatedCount = (MR._mainRowOptionalPartCreatedCount or 0) + (#DIFF_BADGE_DEFS * 2) + 1
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

local function RegisterTimerRow(rowFrame)
    MR._timerRows = MR._timerRows or {}
    for _, existing in ipairs(MR._timerRows) do
        if existing == rowFrame then
            return
        end
    end
    MR._timerRows[#MR._timerRows + 1] = rowFrame
end

UpdateMainRowWidget = function(self, section, mod, row, done, yOff, colW)
    local rowId = row.key or tostring(row.label or yOff)
    local rowFrame = EnsureMainRowWidget(section, rowId, GetMainRowWidgetKind(mod, row))
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
    if rowFrame._mrLayoutSection ~= section
        or rowFrame._mrLayoutY ~= yOff
        or rowFrame._mrLayoutWidth ~= colW
        or rowFrame._mrLayoutHeight ~= rowH then
        rowFrame:ClearAllPoints()
        rowFrame:SetPoint("TOPLEFT", section, "TOPLEFT", 0, -yOff)
        rowFrame:SetSize(colW, rowH)
        rowFrame._mrLayoutSection = section
        rowFrame._mrLayoutY = yOff
        rowFrame._mrLayoutWidth = colW
        rowFrame._mrLayoutHeight = rowH
    end
    rowFrame._timerUpdate = nil
    rowFrame:Show()

    if rowFrame._headerBg then rowFrame._headerBg:Hide() end
    if rowFrame._headerText then rowFrame._headerText:Hide() end
    if rowFrame._headerActionButton then rowFrame._headerActionButton:Hide() end
    if rowFrame._headerCount then rowFrame._headerCount:Hide() end
    rowFrame._hover:Hide()
    rowFrame._rowShade:Hide()
    rowFrame._separator:Hide()
    rowFrame._statusBtn:Hide()
    if rowFrame._rowIcon then rowFrame._rowIcon:Hide() end
    if rowFrame._countIcon then rowFrame._countIcon:Hide() end
    rowFrame._label:Hide()
    rowFrame._count:Hide()
    if rowFrame._wallet then rowFrame._wallet:Hide() end
    if rowFrame._coords then rowFrame._coords:Hide() end
    if rowFrame._vault then rowFrame._vault:Hide() end
    if rowFrame._diffBadges then
        for _, badge in ipairs(rowFrame._diffBadges) do badge:Hide() end
    end
    if rowFrame._diffCount then rowFrame._diffCount:Hide() end

    if row.sectionHeader then
        EnsureMainRowHeaderParts(rowFrame)
        rowFrame._mrData.mode = "sectionHeader"
        rowFrame._headerBg:Show()
        if transparent then
            rowFrame._headerBg:SetColorTexture(1, 1, 1, 0)
        else
            rowFrame._headerBg:SetColorTexture(0.06, 0.08, 0.13, 0.92 * frameAlpha)
        end

        SetFontForText(rowFrame._headerText, row.label, math.max(8, GetFontSize() - 1), GetFontFlags())
        SetTwoAnchors(rowFrame._headerText,
            "LEFT", rowFrame, "LEFT", 8, 0,
            "RIGHT", rowFrame, "RIGHT", -84, 0)
        rowFrame._headerText:SetJustifyH("LEFT")
        rowFrame._headerText:SetText(row.label)
        rowFrame._headerText:SetTextColor(0.84, 0.70, 0.95, 0.95)
        rowFrame._headerText:Show()

        local headerActionButton = nil
        if ((row.headerActionText and row.headerActionText ~= "") or row.headerActionStyle == "visibility") and row.onHeaderActionClick then
            headerActionButton = rowFrame._headerActionButton
            SetOneAnchor(headerActionButton, "RIGHT", rowFrame, "RIGHT", -4, 0)
            headerActionButton:Show()

            if row.headerActionStyle == "visibility" then
                headerActionButton:SetSize(14, 14)
                headerActionButton:SetBackdropColor(0.05, 0.10, 0.18, 1)
                headerActionButton:SetBackdropBorderColor(
                    row.headerActionVisible and 0.15 or 0.35,
                    row.headerActionVisible and 0.32 or 0.12,
                    row.headerActionVisible and 0.38 or 0.12,
                    1
                )
                SetFontIfChanged(rowFrame._headerActionText, FONT_ROWS, 9, GetFontFlags())
                SetOneAnchor(rowFrame._headerActionText, "CENTER", headerActionButton, "CENTER", 0, 0)
                rowFrame._headerActionText:SetJustifyH("CENTER")
                rowFrame._headerActionText:SetText(row.headerActionVisible and "o" or "-")
                rowFrame._headerActionText:SetTextColor(
                    row.headerActionVisible and 0.25 or 0.55,
                    row.headerActionVisible and 0.85 or 0.25,
                    row.headerActionVisible and 0.70 or 0.25
                )
            else
                headerActionButton:SetSize(26, rowH)
                SetFontIfChanged(rowFrame._headerActionText, FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                SetOneAnchor(rowFrame._headerActionText, "CENTER", headerActionButton, "CENTER", 0, 0)
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
            SetFontIfChanged(rowFrame._headerCount, FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
            if headerActionButton then
                SetOneAnchor(rowFrame._headerCount, "RIGHT", headerActionButton, "LEFT", -8, 0)
            else
                SetOneAnchor(rowFrame._headerCount, "RIGHT", rowFrame, "RIGHT", -8, 0)
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
    if isComplete and not transparent then
        rowFrame._rowShade:SetColorTexture(0.12, 0.16, 0.12, 0.18 * frameAlpha)
    else
        rowFrame._rowShade:SetColorTexture(0, 0, 0, 0)
    end
    rowFrame._rowShade:Show()

    rowFrame._separator:SetColorTexture(1, 1, 1, transparent and 0 or (0.06 * frameAlpha))
    rowFrame._separator:Show()

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
        SetFontIfChanged(rowFrame._statusCheck, FONT_HEADERS, 9, GetFontFlags())
        rowFrame._statusCheck:SetTextColor(0.10, 0.08, 0.02, transparent and 0 or 1)
        if transparent then rowFrame._statusCheck:Hide() else rowFrame._statusCheck:Show() end
    elseif isComplete then
        rowFrame._statusBtn:SetBackdropBorderColor(transparent and 0 or 0.24, transparent and 0 or 0.76, transparent and 0 or 0.46, transparent and 0 or frameAlpha)
        rowFrame._statusFill:SetColorTexture(0.20, 0.72, 0.42, transparent and 0 or (0.85 * frameAlpha))
        SetFontIfChanged(rowFrame._statusCheck, FONT_HEADERS, 9, GetFontFlags())
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
    local rowIcon = rowIconInfo and EnsureMainRowTexture(rowFrame, "_rowIcon") or nil
    local hasRowIcon = rowIcon and ApplyIconToTexture(rowIcon, rowIconInfo) or false
    if isComplete and hasRowIcon then
        rowIcon:SetVertexColor(0.55, 0.55, 0.55, 0.7)
    elseif rowIcon then
        rowIcon:SetVertexColor(1, 1, 1, 1)
    end
    if rowIcon then rowIcon:SetShown(hasRowIcon) end

    local countIcon = countIconInfo and EnsureMainRowTexture(rowFrame, "_countIcon") or nil
    local hasCountIcon = countIcon and ApplyIconToTexture(countIcon, countIconInfo) or false
    if isComplete and hasCountIcon then
        countIcon:SetVertexColor(0.55, 0.55, 0.55, 0.7)
    elseif countIcon then
        countIcon:SetVertexColor(1, 1, 1, 1)
    end
    if countIcon then countIcon:SetShown(hasCountIcon) end

    local hasNumericMax = type(row.max) == "number" and row.max > 0
    local isCurrencyRow = row.currencyId and hasNumericMax and not row.noMax
    local isProfessionRow = mod and mod.profSkillLine
    local hasCoordText = hasWaypoint and not row.hideCoordText and not isProfessionRow
    local hasKnowledgeText = type(row.kpTotal) == "number" and row.kpTotal > 0
    local lblRightOff = isCurrencyRow and -96 or (hasCoordText and (hasKnowledgeText and -168 or -128) or (hasKnowledgeText and -64 or -52))

    SetFontForText(rowFrame._label, CleanLabelText(row.label), GetFontSize(), GetFontFlags())
    if hasRowIcon then
        SetTwoAnchors(rowFrame._label,
            "LEFT", rowFrame._rowIcon, "RIGHT", 8, 0,
            "RIGHT", rowFrame, "RIGHT", lblRightOff, 0)
    else
        SetTwoAnchors(rowFrame._label,
            "LEFT", rowFrame._statusBtn, "RIGHT", 8, 0,
            "RIGHT", rowFrame, "RIGHT", lblRightOff, 0)
    end
    rowFrame._label:SetJustifyH("LEFT")
    rowFrame._label:SetJustifyV("MIDDLE")

    local rowCustom = MR:GetRowColor(mod.key, row.key) or (row.colorKey and MR:GetRowColor(mod.key, row.colorKey))
    local headerCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[mod.key]
    local inlineColor = ExtractInlineLabelColor(row.label)
    local professionFallbackColor = isProfessionRow and mod.labelColor or nil
    local effectiveColor = rowCustom or headerCustom or inlineColor or professionFallbackColor
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

    SetFontIfChanged(rowFrame._count, FONT_ROWS, GetFontSize(), GetFontFlags())
    if hasCountIcon then
        SetOneAnchor(rowFrame._count, "RIGHT", rowFrame._countIcon, "LEFT", -4, 0)
    else
        SetOneAnchor(rowFrame._count, "RIGHT", rowFrame, "RIGHT", -4, 0)
    end
    rowFrame._count:SetJustifyH("RIGHT")
    if rowFrame._count.SetWordWrap then
        rowFrame._count:SetWordWrap(false)
    end
    SetWidthIfChanged(rowFrame._count, 0)

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
            SetWidthIfChanged(rowFrame._count, reservedWidth)
            if hasRowIcon then
                SetTwoAnchors(rowFrame._label,
                    "LEFT", rowFrame._rowIcon, "RIGHT", 8, 0,
                    "RIGHT", rowFrame._count, "LEFT", -8, 0)
            else
                SetTwoAnchors(rowFrame._label,
                    "LEFT", rowFrame._statusBtn, "RIGHT", 8, 0,
                    "RIGHT", rowFrame._count, "LEFT", -8, 0)
            end
        else
            SetWidthIfChanged(rowFrame._count, 0)
        end
    elseif isCurrencyRow then
        local mdb = GetMainFrameProgressModule(mod.key)
        local wallet = (mdb and mdb[row.key .. "_wallet"]) or done
        local walletText = not row.hideWallet and EnsureMainRowText(rowFrame, "_wallet") or rowFrame._wallet
        rowFrame._count:SetText(string.format("%d/%d", done, row.max))
        rowFrame._count:SetTextColor(countColor(done, row.max))
        if walletText then walletText:SetShown(not row.hideWallet) end
        if row.hideWallet then
            local leftAnchor = hasRowIcon and rowFrame._rowIcon or rowFrame._statusBtn
            SetTwoAnchors(rowFrame._label,
                "LEFT", leftAnchor, "RIGHT", 8, 0,
                "RIGHT", rowFrame._count, "LEFT", -8, 0)
        else
            SetFontIfChanged(walletText, FONT_ROWS, GetFontSize(), GetFontFlags())
            SetOneAnchor(walletText, "RIGHT", rowFrame._count, "LEFT", -5, 0)
            walletText:SetJustifyH("RIGHT")
            walletText:SetText(string.format("|cffaaaaaa(%d)|r", wallet))
            local leftAnchor = hasRowIcon and rowFrame._rowIcon or rowFrame._statusBtn
            SetTwoAnchors(rowFrame._label,
                "LEFT", leftAnchor, "RIGHT", 8, 0,
                "RIGHT", walletText, "LEFT", -8, 0)
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
            SetTwoAnchors(rowFrame._label,
                "LEFT", rowFrame._statusBtn, "RIGHT", 8, 0,
                "RIGHT", rowFrame._count, "LEFT", -8, 0)
        end
    end
    rowFrame._count:Show()

    local rightAnchor = rowFrame._count
    if hasKnowledgeText then
        local vaultText = EnsureMainRowText(rowFrame, "_vault")
        SetFontIfChanged(vaultText, FONT_ROWS, math.max(7, GetFontSize() - 1), GetFontFlags())
        SetOneAnchor(vaultText, "RIGHT", rowFrame._count, "LEFT", -8, 0)
        vaultText:SetJustifyH("RIGHT")
        if isComplete then
            vaultText:SetText(L["Done"] or "Done")
            vaultText:SetTextColor(0.32, 0.80, 0.50, 0.95)
        else
            vaultText:SetText("+" .. tostring(row.kpTotal))
            if effectiveColor then
                vaultText:SetTextColor(hex(effectiveColor))
            else
                vaultText:SetTextColor(0.92, 0.78, 0.24, 0.95)
            end
        end
        vaultText:Show()
        rightAnchor = vaultText
    end

    if hasCoordText then
        local coordsText = EnsureMainRowText(rowFrame, "_coords")
        SetFontIfChanged(coordsText, FONT_ROWS, math.max(7, GetFontSize() - 1), GetFontFlags())
        SetOneAnchor(coordsText, "RIGHT", rightAnchor, "LEFT", -8, 0)
        coordsText:SetJustifyH("RIGHT")
        coordsText:SetText(string.format("%.2f, %.2f", row.x, row.y))
        if isComplete then
            coordsText:SetTextColor(0.4, 0.4, 0.4, 0.6)
        else
            coordsText:SetTextColor(0.65, 0.9, 1, 0.95)
        end
        coordsText:Show()
    end

    if row.vaultLabel then
        local vaultText = EnsureMainRowText(rowFrame, "_vault")
        SetFontIfChanged(vaultText, FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
        SetOneAnchor(vaultText, "RIGHT", rowFrame._count, "LEFT", -4, 0)
        vaultText:SetText(row.vaultLabel)
        vaultText:SetTextColor(hex(row.vaultColor or "#ffffff"))
        vaultText:Show()
    end
    local hasEncounterDiffTracking = row.encounterIds and row.taskId
    if hasEncounterDiffTracking then
        EnsureMainDifficultyBadges(rowFrame)
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
            local xOff = -4 - (numTracked - i) * (BADGE_W + BADGE_GAP)
            SetOneAnchor(badge, "TOPRIGHT", rowFrame, "TOPRIGHT", xOff, -badgeY)
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
            SetOneAnchor(rowFrame._diffCount, "RIGHT", rowFrame, "RIGHT", -4 - badgeZoneWidth - 4, 0)
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
        if hasRowIcon then
            SetTwoAnchors(rowFrame._label,
                "LEFT", rowFrame._rowIcon, "RIGHT", 8, 0,
                "RIGHT", rowFrame, "RIGHT", -(reservedRight + 8), 0)
        else
            SetTwoAnchors(rowFrame._label,
                "LEFT", rowFrame._statusBtn, "RIGHT", 8, 0,
                "RIGHT", rowFrame, "RIGHT", -(reservedRight + 8), 0)
        end
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
        RegisterTimerRow(rowFrame)
    end

    return rowFrame, yOff + rowH, rowId
end

function MR:IsRowComplete(mod, row, done)
    if mod and (mod.key == "currencies" or mod.key == "pvp_currencies") and not self:IsModuleHideComplete(mod.key) then
        return false
    end
    if row and row.professionKnowledgeEntry and self.GetProfessionKnowledgeEntryProgress then
        local current, required = self:GetProfessionKnowledgeEntryProgress(row)
        return (current or 0) >= (required or 1)
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
        for _, row in ipairs(rows) do
            local rowVisible = IsMainRowVisible(mod, row)
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
            end
        end

        local countedShownRows, extraHeight = CountMainGroupedRows(self, mod, rows, hideComplete, isOpen)
        shownRows = countedShownRows
        height = height + extraHeight

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



UI.MainRowOnEnter = MainRowOnEnter
UI.MainRowOnLeave = MainRowOnLeave
UI.MainRowOnMouseDown = MainRowOnMouseDown
UI.MainStatusButtonOnClick = MainStatusButtonOnClick
UI.MainStatusButtonOnEnter = MainStatusButtonOnEnter
UI.MainStatusButtonOnLeave = MainStatusButtonOnLeave
UI.HideMainRowWidget = HideMainRowWidget
UI.PoolMainRowWidget = PoolMainRowWidget
UI.HideMainSectionWidget = HideMainSectionWidget
UI.HideMainExpansionHeaderWidget = HideMainExpansionHeaderWidget
UI.GetTextOnlyHeaderAlpha = GetTextOnlyHeaderAlpha
UI.ShouldShowIcons = ShouldShowIcons
UI.ShouldShowSectionHeaders = ShouldShowSectionHeaders
UI.UIIcons = UIIcons
UI.GetRowIconInfo = GetRowIconInfo
UI.GetModuleIconInfo = GetModuleIconInfo
UI.ShouldShowModuleHeaderIcon = ShouldShowModuleHeaderIcon
UI.ApplyIconToTexture = ApplyIconToTexture
UI.EnsureMainRowWidget = EnsureMainRowWidget
UI.UpdateMainRowWidget = UpdateMainRowWidget
UI.GetMainRowGroupKey = GetMainRowGroupKey
UI.IsMainRowVisible = IsMainRowVisible
UI.IsMainRowInGroup = IsMainRowInGroup
UI.HasVisibleRowsInMainGroup = HasVisibleRowsInMainGroup
UI.IsMainRowGroupEnabled = IsMainRowGroupEnabled
UI.SetMainRowGroupEnabled = SetMainRowGroupEnabled
UI.BuildMainRowGroupHeader = BuildMainRowGroupHeader
UI.ShouldRenderMainRowGroupHeader = ShouldRenderMainRowGroupHeader
UI.RenderMainGroupedRows = RenderMainGroupedRows
UI.CountMainGroupedRows = CountMainGroupedRows
UI.EnsureMainSeparator = EnsureMainSeparator
UI.EnsureMainExpansionHeaderWidget = EnsureMainExpansionHeaderWidget
UI.UpdateMainExpansionHeaderWidget = UpdateMainExpansionHeaderWidget
UI.CreateSectionWidget = CreateSectionWidget
UI.EnsureMainSectionWidget = EnsureMainSectionWidget
UI.EnsureDetachedSectionWidget = EnsureDetachedSectionWidget
UI.AddSectionRegistryEntry = AddSectionRegistryEntry
UI.UpdateDetachedSectionWidget = UpdateDetachedSectionWidget
UI.EnsureMainDifficultyBadges = EnsureMainDifficultyBadges
UI.GetMainFrameProgressModule = GetMainFrameProgressModule
UI.GetMainFrameRowCount = GetMainFrameRowCount
UI.RegisterTimerRow = RegisterTimerRow
UI.BuildModuleStatsCache = BuildModuleStatsCache
UI.GetModuleStats = GetModuleStats

