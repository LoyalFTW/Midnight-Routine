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
local countColor = ns.CountColor
local GetWidgetCache = ns.GetWidgetCache
local HideUnusedWidgets = ns.HideUnusedWidgets
local ResetCachedWidget = ns.ResetCachedWidget
local ResetSelectableWidget = ns.ResetSelectableWidget
local DAY_SECONDS = Warband.DAY_SECONDS
local WBConcentrationColor = Warband.WBConcentrationColor
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

local function GetSharedHeaderHeight()
    local getHeight = ns.UIInternal and ns.UIInternal.GetMainHeaderHeight
    return getHeight and getHeight() or 30
end

local CHARACTER_ROW_HEIGHT = 58
local CHARACTER_ROW_GAP = 4

local function GetCharacterDetailsText(entry)
    local details = entry.realm ~= "" and entry.realm or ""
    local professions = entry.professionLabels
    if type(professions) ~= "table" or #professions == 0 then
        return details
    end

    local professionText = table.concat(professions, ", ", 1, math.min(#professions, 2))
    if #professions > 2 then
        professionText = professionText .. " +" .. (#professions - 2)
    end
    if details == "" then
        return professionText
    end
    return details .. " | " .. professionText
end

local function MoveAltBoardCharacter(sourceKey, targetKey, afterTarget)
    if MR.SetAltBoardCharacterPosition then
        return MR:SetAltBoardCharacterPosition(sourceKey, targetKey, afterTarget)
    end
    return false
end

local function MoveConcentrationProfession(sourceID, targetID, afterTarget)
    if MR.SetAltBoardConcentrationProfessionPosition then
        return MR:SetAltBoardConcentrationProfessionPosition(sourceID, targetID, afterTarget)
    end
    return false
end

local function UpdateAltBoardCharacterDrag(rail)
    if not WBState.WBDraggingAltBoardCharacterKey or not IsMouseButtonDown("LeftButton") then
        WBState.WBDraggingAltBoardCharacterKey = nil
        rail:SetScript("OnUpdate", nil)
        WBStopDragVisual()
        return
    end
    WBUpdateDragTargetFromCursor(WBState.WBDraggingAltBoardCharacterKey, rail._characterDragRows, MoveAltBoardCharacter)
end

local function UpdateConcentrationProfessionDrag(pane)
    if not WBState.WBDraggingConcentrationSkillLineID or not IsMouseButtonDown("LeftButton") then
        WBState.WBDraggingConcentrationSkillLineID = nil
        pane:SetScript("OnUpdate", nil)
        WBStopDragVisual()
        return
    end
    WBUpdateDragTargetFromCursor(WBState.WBDraggingConcentrationSkillLineID, pane._orderChips, MoveConcentrationProfession, "horizontal")
end

local function EnsureWarbandCharacterButton(frame, index)
    local buttons = GetWidgetCache(frame, "charButtons")
    local btn = buttons[index]
    if btn then
        return btn
    end

    btn = CreateFrame("Button", nil, frame.charRail, "BackdropTemplate")
    btn:SetSize(216, CHARACTER_ROW_HEIGHT)
    btn:SetPoint("TOPLEFT", frame.charRail, "TOPLEFT", 0, -((index - 1) * (CHARACTER_ROW_HEIGHT + CHARACTER_ROW_GAP)))
    btn:SetBackdrop(MakeBackdrop())
    btn._dragBorderColor = {}

    btn._accent = btn:CreateTexture(nil, "ARTWORK")
    btn._accent:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 1, 0)
    btn._accent:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 0)
    btn._accent:SetHeight(1)

    btn._name = btn:CreateFontString(nil, "OVERLAY")
    btn._name:SetPoint("TOPLEFT", btn, "TOPLEFT", 10, -7)
    btn._name:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -30, -7)
    btn._name:SetJustifyH("LEFT")
    btn._name:SetWordWrap(false)

    btn._meta = btn:CreateFontString(nil, "OVERLAY")
    btn._meta:SetPoint("TOPLEFT", btn, "TOPLEFT", 10, -22)
    btn._meta:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -10, -22)
    btn._meta:SetJustifyH("LEFT")
    btn._meta:SetTextColor(0.62, 0.70, 0.80)
    btn._meta:SetWordWrap(false)

    btn._note = btn:CreateFontString(nil, "OVERLAY")
    btn._note:SetPoint("TOPLEFT", btn, "TOPLEFT", 10, -39)
    btn._note:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -10, -39)
    btn._note:SetJustifyH("LEFT")
    btn._note:SetWordWrap(false)

    local hideBtn = CreateFrame("Button", nil, btn, "BackdropTemplate")
    hideBtn:SetSize(16, 16)
    hideBtn:SetPoint("RIGHT", btn, "RIGHT", -7, 0)
    hideBtn:SetBackdrop(MakeBackdrop())
    hideBtn._owner = btn
    btn._hideBtn = hideBtn
    hideBtn._label = hideBtn:CreateFontString(nil, "OVERLAY")
    hideBtn._label:SetPoint("CENTER", hideBtn, "CENTER", 0, 1)

    hideBtn:SetScript("OnClick", function(selfBtn)
        local owner = selfBtn._owner
        local entry = owner and owner._entry
        if not entry or entry.isCurrent then return end
        local makeHidden = not entry.hidden
        MR:SetAltBoardCharacterHidden(entry.key, makeHidden)
        if makeHidden and frame.selectedCharKey == entry.key then
            frame.selectedCharKey = nil
        end
        MR:RefreshWarbandBoard()
    end)
    hideBtn:SetScript("OnEnter", function(selfBtn)
        local entry = selfBtn._owner and selfBtn._owner._entry
        if not entry then return end
        if entry.hidden then
            selfBtn:SetBackdropColor(0.08, 0.18, 0.10, 0.95)
            selfBtn:SetBackdropBorderColor(0.30, 0.90, 0.42, 1)
        else
            selfBtn:SetBackdropColor(0.18, 0.08, 0.08, 0.95)
            selfBtn:SetBackdropBorderColor(0.90, 0.30, 0.30, 1)
        end
        selfBtn._label:SetTextColor(1, 1, 1)
        ns.ShowTooltip(selfBtn, {
            text = entry.hidden and (L["AltBoard_ShowCharacter"] or "Show on Alt Weekly Board") or (L["AltBoard_HideCharacter"] or "Hide from Alt Weekly Board"),
        })
    end)
    hideBtn:SetScript("OnLeave", function(selfBtn)
        selfBtn:SetBackdropColor(0.035, 0.060, 0.090, 0.88)
        selfBtn:SetBackdropBorderColor(0.12, 0.20, 0.26, 0.72)
        selfBtn._label:SetTextColor(0.78, 0.88, 0.92)
        ns.HideTooltip(selfBtn)
    end)

    btn:SetScript("OnClick", function(selfBtn)
        if selfBtn._dragStarted then
            selfBtn._dragStarted = nil
            return
        end
        if selfBtn._entry and frame.selectedCharKey ~= selfBtn._entry.key then
            frame.selectedCharKey = selfBtn._entry.key
            MR:RefreshWarbandBoardSelection()
        end
    end)
    btn:SetScript("OnMouseDown", function(selfBtn, button)
        local entry = selfBtn._entry
        if button ~= "LeftButton" or not entry or entry.isCurrent or not IsShiftKeyDown() then return end
        selfBtn._dragStarted = true
        WBState.WBDraggingAltBoardCharacterKey = entry.key
        frame.charRail:SetScript("OnUpdate", UpdateAltBoardCharacterDrag)
        WBStartDragVisual(entry.name, selfBtn._classR, selfBtn._classG, selfBtn._classB)
        selfBtn:SetBackdropBorderColor(selfBtn._classR, selfBtn._classG, selfBtn._classB, 1)
        ns.HideTooltip()
    end)
    btn:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            WBState.WBDraggingAltBoardCharacterKey = nil
            frame.charRail:SetScript("OnUpdate", nil)
            WBStopDragVisual()
        end
    end)
    btn:SetScript("OnEnter", function(selfBtn)
        if not selfBtn._selected then
            selfBtn:SetBackdropColor(0.026, 0.046, 0.072, 0.96)
            selfBtn:SetBackdropBorderColor(selfBtn._classR * 0.42, selfBtn._classG * 0.42, selfBtn._classB * 0.42, 0.86)
        end
        ns.ShowTooltip(selfBtn, { text = L["AltBoard_DragCharacterOrder"] or "Click to view. Hold Shift and drag to reorder." })
    end)
    btn:SetScript("OnLeave", function(selfBtn)
        if not selfBtn._selected then
            selfBtn:SetBackdropColor(0.018, 0.032, 0.052, 0.90)
            selfBtn:SetBackdropBorderColor(0.07, 0.12, 0.18, 0.56)
        end
        ns.HideTooltip(selfBtn)
    end)

    buttons[index] = btn
    MR._warbandCharacterRowCreatedCount = (MR._warbandCharacterRowCreatedCount or 0) + 1
    return btn
end

local function EnsureWarbandDetailRow(card, index)
    local rows = GetWidgetCache(card, "_rows")
    local row = rows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, card)
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 11, -42 - ((index - 1) * 24))
    row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -11, -42 - ((index - 1) * 24))
    row:SetHeight(23)
    row:EnableMouse(true)
    row._bg = row:CreateTexture(nil, "BACKGROUND")
    row._bg:SetAllPoints()
    row._dot = row:CreateTexture(nil, "ARTWORK")
    row._dot:SetSize(4, 13)
    row._dot:SetPoint("LEFT", row, "LEFT", 2, 0)
    row._label = row:CreateFontString(nil, "OVERLAY")
    row._label:SetPoint("LEFT", row, "LEFT", 16, 0)
    row._label:SetPoint("RIGHT", row, "RIGHT", -120, 0)
    row._label:SetJustifyH("LEFT")
    row._value = row:CreateFontString(nil, "OVERLAY")
    row._value:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    row._value:SetJustifyH("RIGHT")
    row._accent = row:CreateFontString(nil, "OVERLAY")
    row._accent:SetPoint("RIGHT", row._value, "LEFT", -8, 0)
    row._accent:SetJustifyH("RIGHT")

    row:SetScript("OnEnter", function(selfRow)
        local entry = selfRow._entry
        if not entry then return end
        ns.ShowTooltip(selfRow, {
            build = function(tooltip)
                if entry.currencyId and not entry.noBlizzardTooltip then
                    tooltip:SetCurrencyByID(entry.currencyId)
                    if entry.trackWeeklyEarned then
                        tooltip:AddLine(" ")
                        tooltip:AddLine(string.format("Collected this week: %s", entry.displayValue), 0.72, 0.86, 1, true)
                        tooltip:AddLine(string.format("Currently held: %d", entry.wallet or 0), 0.72, 0.86, 1, true)
                    else
                        tooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
                    end
                else
                    tooltip:SetText(entry.label, 1, 1, 1, 1, true)
                end
            end,
        })
    end)
    row:SetScript("OnLeave", function(selfRow) ns.HideTooltip(selfRow) end)
    rows[index] = row
    MR._warbandDetailRowCreatedCount = (MR._warbandDetailRowCreatedCount or 0) + 1
    return row
end

local function EnsureWarbandDetailCard(frame, index)
    local cards = GetWidgetCache(frame, "_detailCards")
    local card = cards[index]
    if card then return card end

    card = CreateFrame("Frame", nil, frame.detailContent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", frame.detailContent, "TOPLEFT", 0, 0)
    card:SetSize(1, 1)
    card:SetBackdrop(MakeBackdrop())
    card._topAccent = card:CreateTexture(nil, "ARTWORK")
    card._topAccent:SetPoint("TOPLEFT")
    card._topAccent:SetPoint("TOPRIGHT")
    card._topAccent:SetHeight(2)

    local headerBtn = CreateFrame("Button", nil, card)
    headerBtn:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    headerBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    headerBtn:SetHeight(36)
    headerBtn._card = card
    card._headerBtn = headerBtn
    card._headerHover = headerBtn:CreateTexture(nil, "BACKGROUND")
    card._headerHover:SetAllPoints()
    card._headerHover:SetColorTexture(1, 1, 1, 0)
    card._arrow = headerBtn:CreateFontString(nil, "OVERLAY")
    card._arrow:SetPoint("TOPLEFT", headerBtn, "TOPLEFT", 13, -10)
    card._title = headerBtn:CreateFontString(nil, "OVERLAY")
    card._title:SetPoint("TOPLEFT", card._arrow, "TOPRIGHT", 8, 0)
    card._title:SetPoint("RIGHT", headerBtn, "RIGHT", -120, 0)
    card._title:SetJustifyH("LEFT")
    card._progress = card:CreateFontString(nil, "OVERLAY")
    card._progress:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -10)
    card._progressTrack = card:CreateTexture(nil, "BACKGROUND", nil, 1)
    card._progressTrack:SetPoint("TOPLEFT", card, "TOPLEFT", 13, -30)
    card._progressTrack:SetPoint("TOPRIGHT", card, "TOPRIGHT", -13, -30)
    card._progressTrack:SetHeight(2)
    card._progressTrack:SetColorTexture(0.08, 0.10, 0.14, 0.72)
    card._progressFill = card:CreateTexture(nil, "ARTWORK")
    card._progressFill:SetPoint("LEFT", card._progressTrack, "LEFT", 0, 0)
    card._progressFill:SetHeight(2)

    headerBtn:SetScript("OnClick", function(selfBtn)
        local owner = selfBtn._card
        local entry = owner and owner._entry
        if not entry then return end
        MR.db.profile.altBoardCollapsedModules = MR.db.profile.altBoardCollapsedModules or {}
        MR.db.profile.altBoardCollapsedModules[entry.key] = not owner._collapsed or nil
        MR:RefreshWarbandBoardSelection()
    end)
    headerBtn:SetScript("OnEnter", function(selfBtn) selfBtn._card._headerHover:SetColorTexture(1, 1, 1, 0.025) end)
    headerBtn:SetScript("OnLeave", function(selfBtn) selfBtn._card._headerHover:SetColorTexture(1, 1, 1, 0) end)

    cards[index] = card
    MR._warbandDetailCardCreatedCount = (MR._warbandDetailCardCreatedCount or 0) + 1
    return card
end

local function EnsureWarbandConcentrationChip(frame, index)
    local chips = GetWidgetCache(frame, "heroConcentrationWidgets")
    local chip = chips[index]
    if chip then return chip end

    chip = CreateFrame("Frame", nil, frame.concentrationPane, "BackdropTemplate")
    chip:SetBackdrop(MakeBackdrop())
    chip:EnableMouse(true)
    chip._dragBorderColor = {}
    chip._glow = chip:CreateTexture(nil, "BACKGROUND")
    chip._glow:SetAllPoints()
    chip._glow:SetTexture("Interface\\Buttons\\WHITE8X8")
    chip._dot = chip:CreateTexture(nil, "ARTWORK")
    chip._dot:SetSize(4, 14)
    chip._dot:SetPoint("LEFT", chip, "LEFT", 8, 0)
    chip._label = chip:CreateFontString(nil, "OVERLAY")
    chip._label:SetPoint("LEFT", chip._dot, "RIGHT", 6, 0)
    chip._label:SetPoint("RIGHT", chip, "RIGHT", -68, 0)
    chip._label:SetJustifyH("LEFT")
    chip._value = chip:CreateFontString(nil, "OVERLAY")
    chip._value:SetPoint("RIGHT", chip, "RIGHT", -8, 0)
    chip._value:SetWidth(52)
    chip._value:SetJustifyH("RIGHT")

    chip:SetScript("OnMouseDown", function(selfChip, button)
        if button ~= "LeftButton" or not selfChip._entry then return end
        WBState.WBDraggingConcentrationSkillLineID = selfChip.dragID
        frame.concentrationPane:SetScript("OnUpdate", UpdateConcentrationProfessionDrag)
        WBStartDragVisual(selfChip._labelText, selfChip._r, selfChip._g, selfChip._b)
        selfChip:SetBackdropColor(0.055 + selfChip._r * 0.050, 0.075 + selfChip._g * 0.050, 0.095 + selfChip._b * 0.050, 0.98)
        selfChip:SetBackdropBorderColor(selfChip._r, selfChip._g, selfChip._b, 1)
        ns.HideTooltip()
    end)
    chip:SetScript("OnMouseUp", function(selfChip, button)
        if button ~= "LeftButton" then return end
        WBState.WBDraggingConcentrationSkillLineID = nil
        frame.concentrationPane:SetScript("OnUpdate", nil)
        WBStopDragVisual()
        selfChip:SetBackdropColor(0.018 + selfChip._r * 0.045, 0.030 + selfChip._g * 0.045, 0.046 + selfChip._b * 0.045, 0.92)
        selfChip:SetBackdropBorderColor(selfChip._r * 0.42, selfChip._g * 0.42, selfChip._b * 0.42, 0.72)
    end)
    chip:SetScript("OnEnter", function(selfChip)
        selfChip:SetBackdropBorderColor(selfChip._r * 0.64, selfChip._g * 0.64, selfChip._b * 0.64, 0.90)
        ns.ShowTooltip(selfChip, { text = L["AltBoard_DragProfessionOrder"] or "Click and drag to reorder professions." })
    end)
    chip:SetScript("OnLeave", function(selfChip)
        if tonumber(WBState.WBDraggingConcentrationSkillLineID) ~= selfChip.dragID then
            selfChip:SetBackdropColor(0.018 + selfChip._r * 0.045, 0.030 + selfChip._g * 0.045, 0.046 + selfChip._b * 0.045, 0.92)
            selfChip:SetBackdropBorderColor(selfChip._r * 0.42, selfChip._g * 0.42, selfChip._b * 0.42, 0.72)
        end
        ns.HideTooltip(selfChip)
    end)

    chips[index] = chip
    MR._warbandConcentrationChipCreatedCount = (MR._warbandConcentrationChipCreatedCount or 0) + 1
    return chip
end

function MR:RefreshWarbandBoard(reuseData)
    local frame = self.altBoardFrame
    if not frame then return end
    self._warbandBoardLastRefreshAt = GetTime and GetTime() or 0
    frame:SetScale(self.db.profile.scale or 1)
    local expansionInfo = GetExpansionDisplayInfo(true)
    local activeView = WBGetAltBoardView()

    if frame.titleText then
        frame.titleText:SetText(L["AltBoard_Title"] or "Alt Weekly Board")
    end
    WBRefreshAltBoardTabs(frame)
    if frame.expansionDropdown and frame.expansionDropdown.Update then
        frame.expansionDropdown:Update()
    end

    if frame.summarySub then
        frame.summarySub:ClearAllPoints()
        frame.summarySub:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -(GetSharedHeaderHeight() + 10))
    end
    if frame.leftPane then
        frame.leftPane:ClearAllPoints()
        frame.leftPane:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -(GetSharedHeaderHeight() + 34))
        frame.leftPane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
        frame.leftPane:SetWidth(238)
    end

    local reusedData = reuseData and type(frame._data) == "table"
    local data = reusedData and frame._data or nil
    if type(data) ~= "table" then
        data = self:GetWarbandWeeklyData()
        frame._data = data
    end
    if reusedData then
        self._warbandBoardSelectionRefreshCount = (self._warbandBoardSelectionRefreshCount or 0) + 1
    else
        self._warbandBoardDataBuildCount = (self._warbandBoardDataBuildCount or 0) + 1
        if self.RefreshConcentrationTracker then
            self:RefreshConcentrationTracker(data)
        end
    end
    local searchText = frame.characterSearchText or ""
    local listData = frame._filteredBoardCharacters or {}
    frame._filteredBoardCharacters = listData
    wipe(listData)
    for _, entry in ipairs(data or {}) do
        if WBCharacterMatchesSearch(entry, searchText) then
            listData[#listData + 1] = entry
        end
    end

    if not frame.selectedCharKey or not data then
        frame.selectedCharKey = nil
    end

    local selected = nil
    for _, entry in ipairs(data) do
        if frame.selectedCharKey and entry.key == frame.selectedCharKey then
            selected = entry
            break
        end
    end
    if searchText ~= "" and selected and not WBCharacterMatchesSearch(selected, searchText) then
        selected = listData[1]
        frame.selectedCharKey = selected and selected.key or nil
    end
    if searchText ~= "" and #listData == 0 then
        selected = nil
        frame.selectedCharKey = nil
    end
    if not selected then
        if searchText ~= "" and #listData == 0 then
            frame.selectedCharKey = nil
        else
            selected = listData[1] or data[1]
            frame.selectedCharKey = selected and selected.key or nil
        end
    end

    frame.charRail._characterDragRows = frame.charRail._characterDragRows or {}
    wipe(frame.charRail._characterDragRows)

    local totalDone, totalRows, staleCount = 0, 0, 0
    for _, entry in ipairs(data) do
        totalDone = totalDone + entry.doneRows
        totalRows = totalRows + entry.totalRows
        if entry.stale then
            staleCount = staleCount + 1
        end
    end

    if activeView == "concentration" then
        frame.summaryValue:SetText("")
    else
        frame.summaryValue:SetText(string.format("%d / %d", totalDone, totalRows))
        frame.summaryValue:SetTextColor(countColor(totalDone, math.max(totalRows, 1)))
    end

    if #data <= 1 then
        frame.summarySub:SetText(string.format("%s  |  %s", expansionInfo.shortLabel or expansionInfo.label or expansionInfo.key, WBAltLoginPrompt()))
    else
        frame.summarySub:SetText(string.format("%s  |  " .. (L["AltBoard_CharactersTracked"] or "%d characters tracked"), expansionInfo.shortLabel or expansionInfo.label or expansionInfo.key, #data))
    end

    if frame.showHiddenBtn and frame.showHiddenBtn._label then
        frame.showHiddenBtn._label:SetText(MR.db.profile.altBoardShowHidden and (L["AltBoard_HideHidden"] or "Hide Hidden") or (L["AltBoard_ShowHidden"] or "Show Hidden"))
        WBStylePillButton(frame.showHiddenBtn, MR.db.profile.altBoardShowHidden == true)
    end
    if frame.characterSearchBox and not frame.characterSearchBox:HasFocus() and frame.characterSearchBox:GetText() ~= searchText then
        frame.characterSearchBox:SetText(searchText)
    end
    if frame.hideCompletedBtn and frame.hideCompletedBtn._label then
        frame.hideCompletedBtn._label:SetText(MR.db.profile.altBoardHideCompleted and (L["AltBoard_ShowCompleted"] or "Show Completed") or (L["AltBoard_HideCompleted"] or "Hide Completed"))
        WBStylePillButton(frame.hideCompletedBtn, MR.db.profile.altBoardHideCompleted == true)
        if activeView == "character" then
            frame.hideCompletedBtn:Show()
            if frame.detailFilterBar then frame.detailFilterBar:Show() end
        else
            frame.hideCompletedBtn:Hide()
            if frame.detailFilterBar then frame.detailFilterBar:Hide() end
        end
    end

    if not selected then
        frame.heroName:SetText(L["AltBoard_NoTrackedCharacters"] or "No tracked characters yet")
        frame.heroMeta:SetText(WBAltLoginPrompt())
        frame.heroStatus:SetText("")
        HideUnusedWidgets(frame.heroConcentrationWidgets, 0, ResetCachedWidget)
        for _, card in ipairs(frame._overviewCards or {}) do card:Hide() end
        HideUnusedWidgets(frame.charButtons, 0, ResetSelectableWidget)
        HideUnusedWidgets(frame._detailCards, 0, ResetCachedWidget)
        if frame.concentrationPane then
            frame.concentrationPane:SetHeight(42)
        end
        if frame.concentrationStatus then
            frame.concentrationStatus:SetText(WBAltLoginPrompt())
            frame.concentrationStatus:SetTextColor(0.68, 0.74, 0.84)
        end
        if frame.hero then frame.hero:Hide() end
        if frame.concentrationPane then frame.concentrationPane:Hide() end
        if frame.detailScroll then frame.detailScroll:Hide() end
        if frame.overviewScroll then frame.overviewScroll:Show() end
        if frame.overviewEmptyLabel then
            frame.overviewEmptyLabel:SetPoint("TOPLEFT", frame.overviewContent, "TOPLEFT", 8, -6)
            frame.overviewEmptyLabel:SetPoint("TOPRIGHT", frame.overviewContent, "TOPRIGHT", -8, -6)
            frame.overviewEmptyLabel:SetText(searchText ~= "" and (L["AltBoard_NoCharacters"] or "No characters found") or (L["AltBoard_ConcentrationNone"] or "No concentration data on tracked characters yet."))
            frame.overviewEmptyLabel:Show()
        end
        if frame.overviewContent then
            frame.overviewContent:SetHeight(40)
        end
        if frame.overviewScrollUpdate then
            frame.overviewScrollUpdate()
        end
        frame.detailContent:SetHeight(1)
        return
    end

    for index, entry in ipairs(listData) do
        local btn = EnsureWarbandCharacterButton(frame, index)
        local isSelected = (selected.key == entry.key)
        local sr, sg, sb = WBClassColor(entry)
        btn._entry = entry
        btn._selected = isSelected
        btn._classR, btn._classG, btn._classB = sr, sg, sb
        if isSelected then
            btn:SetBackdropColor(0.034 + sr * 0.035, 0.050 + sg * 0.035, 0.070 + sb * 0.035, 0.98)
            btn:SetBackdropBorderColor(sr * 0.52, sg * 0.52, sb * 0.52, 0.90)
        else
            btn:SetBackdropColor(0.018, 0.032, 0.052, 0.90)
            btn:SetBackdropBorderColor(0.07, 0.12, 0.18, 0.56)
        end

        btn._accent:SetHeight(isSelected and 2 or 1)
        btn._accent:SetColorTexture(sr, sg, sb, isSelected and 0.92 or 0.62)

        btn._name:SetFont(FONT_HEADERS, math.max(9, GetFontSize() - 1), GetFontFlags())
        btn._name:SetText(entry.isCurrent and (entry.name .. "  |cff7ce7d8" .. (L["AltBoard_Current"] or "Current") .. "|r") or entry.name)
        btn._meta:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
        btn._meta:SetText(GetCharacterDetailsText(entry))
        btn._note:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
        btn._note:SetText(entry.note or "")
        btn._note:SetTextColor(0.46, 0.78, 0.72)
        btn._note:SetShown(entry.note ~= nil and entry.note ~= "")

        local hideBtn = btn._hideBtn
        hideBtn:SetBackdropColor(0.035, 0.060, 0.090, 0.88)
        hideBtn:SetBackdropBorderColor(0.12, 0.20, 0.26, 0.72)
        hideBtn._label:SetFont(FONT_HEADERS, 10, GetFontFlags())
        hideBtn._label:SetText(entry.hidden and "+" or "x")
        hideBtn._label:SetTextColor(0.78, 0.88, 0.92)
        hideBtn:SetShown(not entry.isCurrent)

        btn.dragID = entry.key
        btn._dragBorderColor[1] = isSelected and sr * 0.52 or 0.07
        btn._dragBorderColor[2] = isSelected and sg * 0.52 or 0.12
        btn._dragBorderColor[3] = isSelected and sb * 0.52 or 0.18
        btn._dragBorderColor[4] = isSelected and 0.90 or 0.56
        if not entry.isCurrent then
            frame.charRail._characterDragRows[#frame.charRail._characterDragRows + 1] = btn
        end
        btn:Show()
    end
    HideUnusedWidgets(frame.charButtons, #listData, ResetSelectableWidget)

    frame.charRail:SetHeight(math.max(#listData * (CHARACTER_ROW_HEIGHT + CHARACTER_ROW_GAP), 1))
    if frame.leftScrollUpdate then
        frame.leftScrollUpdate()
    end

    if activeView == "concentration" then
        if frame.hero then frame.hero:Hide() end
        if frame.concentrationPane then frame.concentrationPane:Hide() end
        if frame.detailScroll then frame.detailScroll:Hide() end
        if frame.overviewScroll then frame.overviewScroll:Show() end

        local totalCharacters, totalProfessions = WBPopulateConcentrationOverview(frame, data)
        frame.summarySub:SetText(string.format(
            "%s  |  " .. (L["AltBoard_ConcentrationOverviewSub"] or "%d professions across %d characters"),
            expansionInfo.shortLabel or expansionInfo.label or expansionInfo.key,
            totalProfessions,
            totalCharacters
        ))
        return
    end

    for _, card in ipairs(frame._overviewCards or {}) do card:Hide() end
    if frame.overviewEmptyLabel then
        frame.overviewEmptyLabel:Hide()
    end
    if frame.overviewScroll then frame.overviewScroll:Hide() end
    if frame.hero then frame.hero:Show() end
    if frame.concentrationPane then frame.concentrationPane:Show() end
    if frame.detailScroll then frame.detailScroll:Show() end

    frame.heroName:SetText(selected.name)
    local syncAt = selected.lastSyncAt and selected.lastSyncAt > 0 and selected.lastSyncAt or selected.lastResetAt
    frame.heroMeta:SetText(string.format(L["AltBoard_LastSynced"] or "%s  |  Last synced: %s", selected.realm ~= "" and selected.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"), WBFormatTimestamp(syncAt)))
    if frame.heroNoteBox and not frame.heroNoteBox:HasFocus() then
        frame.heroNoteBox:SetText(selected.note or "")
    end
    frame.heroStatus:ClearAllPoints()
    frame.heroStatus:SetPoint("BOTTOMLEFT", frame.hero, "BOTTOMLEFT", 14, 12)
    frame.heroStatus:SetText("")

    local showHiddenCharacters = MR.db and MR.db.profile and MR.db.profile.altBoardShowHidden == true
    local concentrationEntries = (not showHiddenCharacters) and type(selected.concentration) == "table" and selected.concentration or nil
    local concentrationHeight = 42
    if concentrationEntries and #concentrationEntries > 0 and frame.concentrationPane then
        local contentWidth = math.max((frame.concentrationPane:GetWidth() or 520) - 28, 200)
        local columns = math.max(1, math.min(4, #concentrationEntries))
        if contentWidth >= 520 then
            columns = math.max(columns, math.min(3, #concentrationEntries))
        end
        local gap = 8
        while columns > 1 and ((columns * 168) + ((columns - 1) * gap)) > contentWidth do
            columns = columns - 1
        end
        local chipWidth = math.max(168, math.floor((contentWidth - ((columns - 1) * gap)) / columns))
        local rowHeight = 26
        local usedRows = math.max(1, math.ceil(#concentrationEntries / columns))
        frame.concentrationPane._orderChips = frame.concentrationPane._orderChips or {}
        wipe(frame.concentrationPane._orderChips)

        for index, concentrationEntry in ipairs(concentrationEntries) do
            local rr, rg, rb = WBConcentrationColor(concentrationEntry)
            local labelText = concentrationEntry.label or (L["Unknown"] or "Unknown")
            local valueText = WBConcentrationText(concentrationEntry)
            local col = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            local xOffset = 14 + (col * (chipWidth + gap))
            local yOffset = -34 - (row * (rowHeight + gap))

            local chip = EnsureWarbandConcentrationChip(frame, index)
            chip._entry = concentrationEntry
            chip._labelText = labelText
            chip._r, chip._g, chip._b = rr, rg, rb
            chip:ClearAllPoints()
            chip:SetSize(chipWidth, rowHeight)
            chip:SetPoint("TOPLEFT", frame.concentrationPane, "TOPLEFT", xOffset, yOffset)
            chip:SetBackdropColor(0.018 + rr * 0.045, 0.030 + rg * 0.045, 0.046 + rb * 0.045, 0.92)
            chip:SetBackdropBorderColor(rr * 0.42, rg * 0.42, rb * 0.42, 0.72)
            chip.skillLineID = tonumber(concentrationEntry.skillLineID)
            chip.dragID = tonumber(concentrationEntry.skillLineID)
            chip._dragBorderColor[1], chip._dragBorderColor[2] = rr * 0.42, rg * 0.42
            chip._dragBorderColor[3], chip._dragBorderColor[4] = rb * 0.42, 0.72
            frame.concentrationPane._orderChips[#frame.concentrationPane._orderChips + 1] = chip
            chip._glow:SetColorTexture(rr, rg, rb, 0.04)
            chip._dot:SetColorTexture(rr, rg, rb, 1)
            chip._label:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
            chip._label:SetText(labelText)
            chip._label:SetTextColor(0.84, 0.89, 0.96)
            chip._value:SetFont(FONT_HEADERS, math.max(9, GetFontSize() - 1), GetFontFlags())
            chip._value:SetText(valueText)
            chip._value:SetTextColor(0.97, 0.98, 1.00)
            chip:Show()
        end

        HideUnusedWidgets(frame.heroConcentrationWidgets, #concentrationEntries, ResetCachedWidget)

        concentrationHeight = 34 + (usedRows * rowHeight) + (math.max(0, usedRows - 1) * gap) + 10
    else
        HideUnusedWidgets(frame.heroConcentrationWidgets, 0, ResetCachedWidget)
        frame.heroStatus:SetText(selected.stale and (L["AltBoard_AwaitingRefresh"] or "Awaiting refresh") or "")
        if frame.concentrationStatus then
            frame.concentrationStatus:SetText(selected.stale and (L["AltBoard_AwaitingRefresh"] or "Awaiting refresh") or WBAltLoginPrompt())
            frame.concentrationStatus:SetTextColor(selected.stale and 0.95 or 0.68, selected.stale and 0.50 or 0.74, selected.stale and 0.25 or 0.84)
        end
    end

    if frame.concentrationStatus and concentrationEntries and #concentrationEntries > 0 then
        frame.concentrationStatus:SetText("")
    end

    if frame.concentrationPane then
        frame.concentrationPane:SetHeight(concentrationHeight)
    end
    if frame.detailEmptyLabel then
        frame.detailEmptyLabel:Hide()
    end

    local detailWidth = math.max((frame.detailScroll and frame.detailScroll:GetWidth() or 540) - 8, 320)
    frame.detailContent:SetWidth(detailWidth)

    local orderIndex = frame._detailOrderIndex or {}
    frame._detailOrderIndex = orderIndex
    wipe(orderIndex)
    for idx, mod in ipairs(MR:GetOrderedModules(MR:GetSelectedExpansionKey(true))) do
        orderIndex[mod.key] = idx
    end
    table.sort(selected.modules, function(a, b)
        local ai = orderIndex[a.key] or 9999
        local bi = orderIndex[b.key] or 9999
        if ai ~= bi then
            return ai < bi
        end
        return a.label < b.label
    end)

    local yOff = 0
    local cardIndex = 0
    local hideCompletedRows = WBShouldHideCompletedCharacters()
    local collapsedModules = (MR.db and MR.db.profile and MR.db.profile.altBoardCollapsedModules) or {}

    for _, moduleEntry in ipairs(selected.modules) do
        cardIndex = cardIndex + 1
        local card = EnsureWarbandDetailCard(frame, cardIndex)
        local visibleRows = card._visibleRows or {}
        card._visibleRows = visibleRows
        wipe(visibleRows)
        for _, rowEntry in ipairs(moduleEntry.rows) do
            if not (hideCompletedRows and rowEntry.complete) then
                visibleRows[#visibleRows + 1] = rowEntry
            end
        end

        if hideCompletedRows and #visibleRows == 0 then
            cardIndex = cardIndex - 1
            card:Hide()
        else
            local mr, mg, mb = WBHexColor(moduleEntry.color, 1, 1, 1)
            local isCollapsed = collapsedModules[moduleEntry.key] == true
            card._entry = moduleEntry
            card._collapsed = isCollapsed
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", frame.detailContent, "TOPLEFT", 0, -yOff)
            card:SetWidth(detailWidth)
            WBApplySurface(card, "soft", 0.92)
            card._topAccent:SetColorTexture(mr, mg, mb, 0.92)
            card._arrow:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
            card._arrow:SetText(isCollapsed and "+" or "-")
            card._arrow:SetTextColor(0.62, 0.72, 0.78)
            card._title:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
            card._title:SetText(moduleEntry.label)
            card._title:SetTextColor(math.min(1, mr + 0.08), math.min(1, mg + 0.08), math.min(1, mb + 0.08))
            card._progress:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
            card._progress:SetText(string.format("%d / %d", moduleEntry.doneRows, moduleEntry.totalRows))
            local pr, pg, pb = countColor(moduleEntry.doneRows, math.max(moduleEntry.totalRows, 1))
            card._progress:SetTextColor(pr, pg, pb)
            card._progressFill:SetColorTexture(pr, pg, pb, 0.92)
            card._progressFill:SetWidth(math.max(1, (detailWidth - 26) * math.min(1, moduleEntry.doneRows / math.max(moduleEntry.totalRows, 1))))

            local usedRowCount = isCollapsed and 0 or #visibleRows
            for rowIndex = 1, usedRowCount do
                local rowEntry = visibleRows[rowIndex]
                local row = EnsureWarbandDetailRow(card, rowIndex)
                row._entry = rowEntry
                row._bg:SetColorTexture(1, 1, 1, rowIndex % 2 == 0 and 0.018 or 0)
                local rr, rg, rb
                if selected.stale then
                    rr, rg, rb = 0.42, 0.42, 0.46
                elseif rowEntry.complete then
                    rr, rg, rb = 0.20, 0.95, 0.60
                elseif rowEntry.value > 0 then
                    rr, rg, rb = 1.00, 0.76, 0.28
                else
                    rr, rg, rb = 0.42, 0.48, 0.56
                end
                row._dot:SetColorTexture(rr, rg, rb, 0.92)
                row._label:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
                row._label:SetText(rowEntry.label)
                row._label:SetTextColor(0.84, 0.88, 0.93)
                row._value:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
                row._value:SetText(selected.stale and (L["AltBoard_AwaitingRefresh"] or "Awaiting refresh") or rowEntry.displayValue)
                row._value:SetTextColor(rr, rg, rb)
                if rowEntry.accentLabel then
                    row._accent:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
                    row._accent:SetText(WBClean(rowEntry.accentLabel))
                    row._accent:SetTextColor(WBHexColor(rowEntry.accentColor, 0.78, 0.82, 0.95))
                    row._accent:Show()
                else
                    row._accent:Hide()
                end
                row:Show()
            end
            for rowIndex = usedRowCount + 1, #(card._rows or {}) do
                card._rows[rowIndex]._entry = nil
                card._rows[rowIndex]:Hide()
            end

            local moduleY = 42 + (usedRowCount * 24)
            card:SetHeight(moduleY + 8)
            card:Show()
            yOff = yOff + moduleY + 18
        end
    end
    HideUnusedWidgets(frame._detailCards, cardIndex, ResetCachedWidget)

    if yOff == 0 and hideCompletedRows and frame.detailEmptyLabel then
        frame.detailEmptyLabel:SetPoint("TOPLEFT", frame.detailContent, "TOPLEFT", 8, -6)
        frame.detailEmptyLabel:SetPoint("TOPRIGHT", frame.detailContent, "TOPRIGHT", -8, -6)
        frame.detailEmptyLabel:SetText(L["AltBoard_NoIncompleteRows"] or "No incomplete rows to show.")
        frame.detailEmptyLabel:Show()
        frame.detailContent:SetHeight(40)
    else
        frame.detailContent:SetHeight(math.max(yOff, 1))
    end
    if frame.detailScrollUpdate then
        frame.detailScrollUpdate()
    end
end

function MR:RefreshWarbandBoardSelection()
    self:RefreshWarbandBoard(true)
end

function MR:ToggleWarbandBoard()
    if self.altBoardFrame and self.altBoardFrame:IsShown() then
        self.altBoardFrame:Hide()
        return
    end

    if not self.altBoardFrame then
        local frame = StyledFrame(UIParent, nil, "DIALOG", 30)
        frame:SetSize(860, 640)
        frame:SetScale(self.db.profile.scale or 1)
        local pos = GetWindowLayoutValue("warbandBoardPosition")
        if pos and pos.point then
            frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 130, 10)
        end

        local bgGlow = frame:CreateTexture(nil, "BACKGROUND")
        bgGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        bgGlow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        bgGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
        bgGlow:SetColorTexture(0.012, 0.020, 0.036, 0.98)

        local headerHeight = GetSharedHeaderHeight()
        local titleBar = TitleBar(frame, headerHeight)
        titleBar:SetBackdropColor(0.03, 0.06, 0.12, 0.98)
        titleBar:SetBackdropBorderColor(0.17, 0.24, 0.32, 1)
        titleBar:SetScript("OnDragStart", function()
            frame:StartMoving()
        end)
        titleBar:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            local pt, _, rp, x, y = frame:GetPoint()
            SetWindowLayoutValue("warbandBoardPosition", { point = pt, relPoint = rp, x = x, y = y })
        end)
        local title = titleBar:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_HEADERS, math.max(8, GetFontSize() - 2), GetFontFlags())
        title:SetPoint("LEFT", titleBar, "LEFT", 14, 1)
        title:SetPoint("RIGHT", titleBar, "RIGHT", -150, 0)
        title:SetJustifyH("LEFT")
        title:SetText(L["AltBoard_Title"] or "Alt Weekly Board")
        title:SetTextColor(0.90, 0.95, 1.0)

        local summaryValue = titleBar:CreateFontString(nil, "OVERLAY")
        summaryValue:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        summaryValue:SetPoint("RIGHT", titleBar, "RIGHT", -58, 1)
        summaryValue:SetText("0 / 0")

        local summarySub = frame:CreateFontString(nil, "OVERLAY")
        summarySub:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        summarySub:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -(headerHeight + 10))
        summarySub:SetTextColor(0.58, 0.67, 0.76)
        summarySub:SetText("")

        CloseButton(titleBar, function() frame:Hide() end)

        local expansionDropdown = BuildExpansionDropdown(frame, true, {
            width = 160,
            height = 18,
        })
        expansionDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -(headerHeight + 6))

        local leftPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        leftPane:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -(headerHeight + 34))
        leftPane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
        leftPane:SetWidth(238)
        leftPane:SetBackdrop(MakeBackdrop())
        WBApplySurface(leftPane, "panel")

        local leftLabel = leftPane:CreateFontString(nil, "OVERLAY")
        leftLabel:SetFont(FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
        leftLabel:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 12, -12)
        leftLabel:SetText(L["AltBoard_Characters"] or "Characters")
        leftLabel:SetTextColor(0.70, 0.82, 0.86)

        local showHiddenBtn = CreateFrame("Button", nil, leftPane, "BackdropTemplate")
        showHiddenBtn:SetSize(96, 20)
        showHiddenBtn:SetPoint("TOPRIGHT", leftPane, "TOPRIGHT", -10, -9)
        showHiddenBtn:SetBackdrop(MakeBackdrop())
        WBStylePillButton(showHiddenBtn, false)

        local showHiddenLabel = showHiddenBtn:CreateFontString(nil, "OVERLAY")
        showHiddenLabel:SetFont(FONT_ROWS, 9, GetFontFlags())
        showHiddenLabel:SetPoint("LEFT", showHiddenBtn, "LEFT", 6, 0)
        showHiddenLabel:SetPoint("RIGHT", showHiddenBtn, "RIGHT", -6, 0)
        showHiddenLabel:SetJustifyH("CENTER")
        showHiddenLabel:SetText(L["AltBoard_ShowHidden"] or "Show Hidden")
        showHiddenLabel:SetTextColor(0.70, 0.88, 0.85)
        showHiddenBtn._label = showHiddenLabel

        showHiddenBtn:SetScript("OnClick", function()
            MR.db.profile.altBoardShowHidden = not MR.db.profile.altBoardShowHidden
            MR:RefreshWarbandBoard()
        end)
        showHiddenBtn:SetScript("OnEnter", function(selfBtn)
            WBStylePillButton(selfBtn, true)
            showHiddenLabel:SetTextColor(1, 1, 1)
        end)
        showHiddenBtn:SetScript("OnLeave", function(selfBtn)
            WBStylePillButton(selfBtn, MR.db.profile.altBoardShowHidden == true)
        end)

        local searchBox = CreateFrame("EditBox", nil, leftPane, "BackdropTemplate")
        searchBox:SetSize(214, 24)
        searchBox:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 10, -34)
        searchBox:SetAutoFocus(false)
        searchBox:SetFont(FONT_ROWS, math.max(9, GetFontSize() - 1), GetFontFlags())
        searchBox:SetTextColor(0.90, 0.95, 1.00)
        searchBox:SetJustifyH("LEFT")
        searchBox:SetBackdrop(MakeBackdrop())
        searchBox:SetBackdropColor(0.010, 0.018, 0.030, 0.94)
        searchBox:SetBackdropBorderColor(0.08, 0.14, 0.20, 0.72)
        searchBox:SetTextInsets(22, 26, 0, 0)

        local searchIcon = searchBox:CreateFontString(nil, "OVERLAY")
        searchIcon:SetFont(FONT_ROWS, math.max(9, GetFontSize() - 1), GetFontFlags())
        searchIcon:SetPoint("LEFT", searchBox, "LEFT", 8, 0)
        searchIcon:SetText(">")
        searchIcon:SetTextColor(0.42, 0.52, 0.60)

        local searchPlaceholder = searchBox:CreateFontString(nil, "OVERLAY")
        searchPlaceholder:SetFont(FONT_ROWS, math.max(9, GetFontSize() - 1), GetFontFlags())
        searchPlaceholder:SetPoint("LEFT", searchBox, "LEFT", 22, 0)
        searchPlaceholder:SetText(L["AltBoard_SearchPlaceholder"] or "Search characters...")
        searchPlaceholder:SetTextColor(0.42, 0.50, 0.58)

        local clearSearchBtn = CreateFrame("Button", nil, searchBox, "BackdropTemplate")
        clearSearchBtn:SetSize(16, 16)
        clearSearchBtn:SetPoint("RIGHT", searchBox, "RIGHT", -5, 0)
        clearSearchBtn:SetBackdrop(MakeBackdrop())
        clearSearchBtn:SetBackdropColor(0.025, 0.045, 0.065, 0.88)
        clearSearchBtn:SetBackdropBorderColor(0.10, 0.16, 0.22, 0.72)

        local clearSearchLabel = clearSearchBtn:CreateFontString(nil, "OVERLAY")
        clearSearchLabel:SetFont(FONT_HEADERS, 9, GetFontFlags())
        clearSearchLabel:SetPoint("CENTER", clearSearchBtn, "CENTER", 0, 1)
        clearSearchLabel:SetText("x")
        clearSearchLabel:SetTextColor(0.58, 0.68, 0.76)
        clearSearchBtn:Hide()

        local function UpdateSearchVisuals(text)
            if text == "" then
                searchPlaceholder:Show()
                clearSearchBtn:Hide()
            else
                searchPlaceholder:Hide()
                clearSearchBtn:Show()
            end
        end

        searchBox:SetScript("OnTextChanged", function(selfBox)
            local text = selfBox:GetText() or ""
            if frame.characterSearchText == text then
                UpdateSearchVisuals(text)
                return
            end
            frame.characterSearchText = text
            UpdateSearchVisuals(text)
            MR:RequestWarbandBoardRefresh(true)
        end)
        searchBox:SetScript("OnEscapePressed", function(selfBox)
            selfBox:SetText("")
            selfBox:ClearFocus()
        end)
        searchBox:SetScript("OnEditFocusGained", function()
            searchBox:SetBackdropBorderColor(0.20, 0.55, 0.52, 0.92)
        end)
        searchBox:SetScript("OnEditFocusLost", function()
            searchBox:SetBackdropBorderColor(0.08, 0.14, 0.20, 0.72)
        end)
        clearSearchBtn:SetScript("OnClick", function()
            searchBox:SetText("")
            searchBox:ClearFocus()
        end)
        clearSearchBtn:SetScript("OnEnter", function(selfBtn)
            selfBtn:SetBackdropColor(0.055, 0.095, 0.120, 0.96)
            selfBtn:SetBackdropBorderColor(0.18, 0.38, 0.42, 0.90)
            clearSearchLabel:SetTextColor(1, 1, 1)
        end)
        clearSearchBtn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(0.025, 0.045, 0.065, 0.88)
            selfBtn:SetBackdropBorderColor(0.10, 0.16, 0.22, 0.72)
            clearSearchLabel:SetTextColor(0.58, 0.68, 0.76)
        end)

        local leftScroll, charRail, leftScrollUpdate = WBCreateScrollArea(
            leftPane,
            { "TOPLEFT", leftPane, "TOPLEFT", 8, -64 },
            { "BOTTOMRIGHT", leftPane, "BOTTOMRIGHT", -12, 8 }
        )

        local rightPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        rightPane:SetPoint("TOPLEFT", leftPane, "TOPRIGHT", 14, 0)
        rightPane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 14)
        rightPane:SetBackdrop(MakeBackdrop())
        WBApplySurface(rightPane, "panel")

        local tabBar = CreateFrame("Frame", nil, rightPane)
        tabBar:SetPoint("TOPLEFT", rightPane, "TOPLEFT", 14, -14)
        tabBar:SetPoint("TOPRIGHT", rightPane, "TOPRIGHT", -14, -14)
        tabBar:SetHeight(26)

        local function CreateAltBoardTab(label, viewKey)
            local btn = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
            btn:SetSize(136, 23)
            btn:SetBackdrop(MakeBackdrop())
            btn:SetScript("OnClick", function()
                WBSetAltBoardView(viewKey)
                MR:RefreshWarbandBoard()
            end)
            btn:SetScript("OnEnter", function(selfBtn)
                if WBGetAltBoardView() ~= viewKey then
                    WBStylePillButton(selfBtn, true)
                    if selfBtn._label then
                        selfBtn._label:SetTextColor(1, 1, 1)
                    end
                end
            end)
            btn:SetScript("OnLeave", function()
                WBRefreshAltBoardTabs(frame)
            end)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
            lbl:SetPoint("CENTER", btn, "CENTER", 0, 0)
            lbl:SetText(label)
            btn._label = lbl
            return btn
        end

        local characterTab = CreateAltBoardTab(L["AltBoard_TabCharacter"] or "Character", "character")
        characterTab:SetPoint("LEFT", tabBar, "LEFT", 0, 0)

        local concentrationTab = CreateAltBoardTab(L["AltBoard_TabConcentration"] or "Concentration", "concentration")
        concentrationTab:SetPoint("LEFT", characterTab, "RIGHT", 8, 0)

        local concentrationTrackerBtn = CreateFrame("Button", nil, tabBar, "BackdropTemplate")
        concentrationTrackerBtn:SetSize(144, 23)
        concentrationTrackerBtn:SetPoint("LEFT", concentrationTab, "RIGHT", 8, 0)
        concentrationTrackerBtn:SetBackdrop(MakeBackdrop())
        concentrationTrackerBtn:SetBackdropColor(0.024, 0.050, 0.080, 0.90)
        concentrationTrackerBtn:SetBackdropBorderColor(0.12, 0.25, 0.30, 0.75)

        local concentrationTrackerLabel = concentrationTrackerBtn:CreateFontString(nil, "OVERLAY")
        concentrationTrackerLabel:SetFont(FONT_ROWS, 9, GetFontFlags())
        concentrationTrackerLabel:SetPoint("LEFT", concentrationTrackerBtn, "LEFT", 6, 0)
        concentrationTrackerLabel:SetPoint("RIGHT", concentrationTrackerBtn, "RIGHT", -6, 0)
        concentrationTrackerLabel:SetJustifyH("CENTER")
        concentrationTrackerLabel:SetText(L["AltBoard_TrackAllConcentration"] or "Concentration Popout")
        concentrationTrackerLabel:SetTextColor(0.70, 0.88, 0.85)
        concentrationTrackerBtn._label = concentrationTrackerLabel

        concentrationTrackerBtn:SetScript("OnClick", function()
            MR:ToggleConcentrationTracker()
        end)
        concentrationTrackerBtn:SetScript("OnEnter", function(selfBtn)
            selfBtn:SetBackdropColor(0.045, 0.105, 0.145, 0.96)
            selfBtn:SetBackdropBorderColor(0.20, 0.62, 0.56, 0.95)
            concentrationTrackerLabel:SetTextColor(1, 1, 1)
        end)
        concentrationTrackerBtn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(0.024, 0.050, 0.080, 0.90)
            selfBtn:SetBackdropBorderColor(0.12, 0.25, 0.30, 0.75)
            concentrationTrackerLabel:SetTextColor(0.70, 0.88, 0.85)
        end)

        local hero = CreateFrame("Frame", nil, rightPane, "BackdropTemplate")
        hero:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -14)
        hero:SetPoint("TOPRIGHT", tabBar, "BOTTOMRIGHT", 0, -14)
        hero:SetHeight(92)
        hero:SetBackdrop(MakeBackdrop())
        WBApplySurface(hero, "raised")

        local heroGlow = hero:CreateTexture(nil, "BACKGROUND")
        heroGlow:SetPoint("TOPLEFT")
        heroGlow:SetPoint("BOTTOMRIGHT")
        heroGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
        heroGlow:SetColorTexture(0.08, 0.16, 0.22, 0.08)

        local heroName = hero:CreateFontString(nil, "OVERLAY")
        heroName:SetFont(FONT_HEADERS, math.max(13, GetFontSize() + 3), GetFontFlags())
        heroName:SetPoint("TOPLEFT", hero, "TOPLEFT", 18, -15)
        heroName:SetPoint("RIGHT", hero, "RIGHT", -244, 0)
        heroName:SetTextColor(0.96, 0.99, 1.00)

        local heroMeta = hero:CreateFontString(nil, "OVERLAY")
        heroMeta:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        heroMeta:SetPoint("TOPLEFT", heroName, "BOTTOMLEFT", 0, -8)
        heroMeta:SetPoint("RIGHT", heroName, "RIGHT", 0, 0)
        heroMeta:SetTextColor(0.70, 0.78, 0.86)

        local heroStatus = hero:CreateFontString(nil, "OVERLAY")
        heroStatus:SetFont(FONT_ROWS, math.max(10, GetFontSize()), GetFontFlags())
        heroStatus:SetPoint("BOTTOMLEFT", hero, "BOTTOMLEFT", 18, 14)

        local heroNoteLabel = hero:CreateFontString(nil, "OVERLAY")
        heroNoteLabel:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        heroNoteLabel:SetPoint("TOPLEFT", hero, "TOPRIGHT", -226, -15)
        heroNoteLabel:SetText(L["AltBoard_NoteLabel"] or "Note / tag")
        heroNoteLabel:SetTextColor(0.62, 0.74, 0.80)

        local heroNoteBox = CreateFrame("EditBox", nil, hero, "BackdropTemplate")
        heroNoteBox:SetSize(210, 24)
        heroNoteBox:SetPoint("TOPLEFT", heroNoteLabel, "BOTTOMLEFT", 0, -6)
        heroNoteBox:SetAutoFocus(false)
        heroNoteBox:SetFont(FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
        heroNoteBox:SetTextColor(0.92, 0.96, 1.00)
        heroNoteBox:SetJustifyH("LEFT")
        heroNoteBox:SetMaxLetters(80)
        heroNoteBox:SetBackdrop(MakeBackdrop())
        heroNoteBox:SetBackdropColor(0.014, 0.026, 0.044, 0.94)
        heroNoteBox:SetBackdropBorderColor(0.10, 0.18, 0.24, 0.76)
        heroNoteBox:SetTextInsets(8, 8, 0, 0)

        local function SaveHeroNote()
            if not frame.selectedCharKey then
                return
            end

            MR:SetAltBoardCharacterNote(frame.selectedCharKey, heroNoteBox:GetText() or "")
            MR:RequestWarbandBoardRefresh(true)
        end

        heroNoteBox:SetScript("OnEnterPressed", function(selfBox)
            SaveHeroNote()
            selfBox:ClearFocus()
        end)
        heroNoteBox:SetScript("OnEscapePressed", function(selfBox)
            selfBox:SetText(MR:GetAltBoardCharacterNote(frame.selectedCharKey) or "")
            selfBox:ClearFocus()
        end)
        heroNoteBox:SetScript("OnEditFocusLost", function()
            SaveHeroNote()
            heroNoteBox:SetBackdropBorderColor(0.10, 0.18, 0.24, 0.76)
        end)
        heroNoteBox:SetScript("OnEditFocusGained", function()
            heroNoteBox:SetBackdropBorderColor(0.24, 0.66, 0.60, 0.95)
        end)
        heroNoteBox:SetScript("OnEnter", function(selfBox)
            ns.ShowTooltip(selfBox, { text = L["AltBoard_NoteTooltip"] or "Add a short note or tag for this character." })
        end)
        heroNoteBox:SetScript("OnLeave", function(selfBox)
            ns.HideTooltip(selfBox)
        end)

        local concentrationPane = CreateFrame("Frame", nil, rightPane, "BackdropTemplate")
        concentrationPane:SetPoint("TOPLEFT", hero, "BOTTOMLEFT", 0, -10)
        concentrationPane:SetPoint("TOPRIGHT", hero, "BOTTOMRIGHT", 0, -10)
        concentrationPane:SetHeight(42)
        concentrationPane:SetBackdrop(MakeBackdrop())
        WBApplySurface(concentrationPane, "soft")

        local concentrationAccent = concentrationPane:CreateTexture(nil, "ARTWORK")
        concentrationAccent:SetPoint("TOPLEFT")
        concentrationAccent:SetPoint("TOPRIGHT")
        concentrationAccent:SetHeight(1)
        concentrationAccent:SetColorTexture(0.50, 0.42, 0.72, 0.95)

        local concentrationTitle = concentrationPane:CreateFontString(nil, "OVERLAY")
        concentrationTitle:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
        concentrationTitle:SetPoint("TOPLEFT", concentrationPane, "TOPLEFT", 14, -10)
        concentrationTitle:SetText(WBConcentrationLabel())
        concentrationTitle:SetTextColor(0.78, 0.76, 0.92)

        local concentrationStatus = concentrationPane:CreateFontString(nil, "OVERLAY")
        concentrationStatus:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        concentrationStatus:SetPoint("TOPLEFT", concentrationTitle, "BOTTOMLEFT", 0, -8)
        concentrationStatus:SetPoint("RIGHT", concentrationPane, "RIGHT", -12, 0)
        concentrationStatus:SetJustifyH("LEFT")
        concentrationStatus:SetTextColor(0.70, 0.78, 0.88)

        local detailFilterBar = CreateFrame("Frame", nil, rightPane)
        detailFilterBar:SetPoint("TOPLEFT", concentrationPane, "BOTTOMLEFT", 0, -10)
        detailFilterBar:SetPoint("TOPRIGHT", concentrationPane, "BOTTOMRIGHT", 0, -10)
        detailFilterBar:SetHeight(22)

        local hideCompletedBtn = CreateFrame("Button", nil, detailFilterBar, "BackdropTemplate")
        hideCompletedBtn:SetSize(122, 20)
        hideCompletedBtn:SetPoint("TOPRIGHT", detailFilterBar, "TOPRIGHT", -2, 0)
        hideCompletedBtn:SetBackdrop(MakeBackdrop())
        WBStylePillButton(hideCompletedBtn, false)

        local hideCompletedLabel = hideCompletedBtn:CreateFontString(nil, "OVERLAY")
        hideCompletedLabel:SetFont(FONT_ROWS, 9, GetFontFlags())
        hideCompletedLabel:SetPoint("LEFT", hideCompletedBtn, "LEFT", 6, 0)
        hideCompletedLabel:SetPoint("RIGHT", hideCompletedBtn, "RIGHT", -6, 0)
        hideCompletedLabel:SetJustifyH("CENTER")
        hideCompletedLabel:SetText(L["AltBoard_HideCompleted"] or "Hide Completed")
        hideCompletedLabel:SetTextColor(0.70, 0.88, 0.85)
        hideCompletedBtn._label = hideCompletedLabel

        hideCompletedBtn:SetScript("OnClick", function()
            MR.db.profile.altBoardHideCompleted = not MR.db.profile.altBoardHideCompleted
            MR:RefreshWarbandBoard()
        end)
        hideCompletedBtn:SetScript("OnEnter", function(selfBtn)
            WBStylePillButton(selfBtn, true)
            hideCompletedLabel:SetTextColor(1, 1, 1)
        end)
        hideCompletedBtn:SetScript("OnLeave", function(selfBtn)
            WBStylePillButton(selfBtn, MR.db.profile.altBoardHideCompleted == true)
        end)

        local detailScroll, detailContent, detailScrollUpdate = WBCreateScrollArea(
            rightPane,
            { "TOPLEFT", detailFilterBar, "BOTTOMLEFT", 0, -8 },
            { "BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", -10, 10 }
        )
        detailContent:SetSize(520, 1)
        local detailEmptyLabel = detailContent:CreateFontString(nil, "OVERLAY")
        detailEmptyLabel:SetFont(FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
        detailEmptyLabel:SetJustifyH("LEFT")
        detailEmptyLabel:SetTextColor(0.68, 0.74, 0.84)
        detailEmptyLabel:Hide()

        local overviewScroll, overviewContent, overviewScrollUpdate = WBCreateScrollArea(
            rightPane,
            { "TOPLEFT", tabBar, "BOTTOMLEFT", 0, -12 },
            { "BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", -10, 10 }
        )
        overviewContent:SetSize(520, 1)
        overviewScroll:Hide()

        local overviewEmptyLabel = overviewContent:CreateFontString(nil, "OVERLAY")
        overviewEmptyLabel:SetFont(FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
        overviewEmptyLabel:SetJustifyH("LEFT")
        overviewEmptyLabel:SetTextColor(0.68, 0.74, 0.84)
        overviewEmptyLabel:Hide()

        frame.charButtons = {}
        frame.charRail = charRail
        frame.leftScroll = leftScroll
        frame.leftScrollUpdate = leftScrollUpdate
        frame.detailScroll = detailScroll
        frame.detailScrollUpdate = detailScrollUpdate
        frame.detailContent = detailContent
        frame.detailEmptyLabel = detailEmptyLabel
        frame.detailFilterBar = detailFilterBar
        frame.overviewScroll = overviewScroll
        frame.overviewScrollUpdate = overviewScrollUpdate
        frame.overviewContent = overviewContent
        frame.overviewEmptyLabel = overviewEmptyLabel
        frame.summaryValue = summaryValue
        frame.summarySub = summarySub
        frame.expansionDropdown = expansionDropdown
        frame.hero = hero
        frame.heroConcentrationWidgets = {}
        frame.concentrationPane = concentrationPane
        frame.concentrationTitle = concentrationTitle
        frame.concentrationStatus = concentrationStatus
        frame.concentrationTrackerBtn = concentrationTrackerBtn
        frame.leftPane = leftPane
        frame.showHiddenBtn = showHiddenBtn
        frame.characterSearchBox = searchBox
        frame.hideCompletedBtn = hideCompletedBtn
        frame.heroName = heroName
        frame.heroMeta = heroMeta
        frame.heroStatus = heroStatus
        frame.heroNoteLabel = heroNoteLabel
        frame.heroNoteBox = heroNoteBox
        frame.titleText = title
        frame.leftLabel = leftLabel
        frame.showHiddenLabel = showHiddenLabel
        frame.hideCompletedLabel = hideCompletedLabel
        frame.tabBar = tabBar
        frame.altTabs = {
            character = characterTab,
            concentration = concentrationTab,
        }
        frame.rightPane = rightPane

        frame:SetScript("OnShow", function()
            if MR._tickFrame then MR._tickFrame:Show() end
            if MR.ActivateVisibleTrackingSurface and MR:ActivateVisibleTrackingSurface() then
                MR:RequestUIRefresh(0.08)
            end
        end)
        frame:SetScript("OnHide", function()
            if MR._tickFrame and not MR:HasVisibleMainTrackingSurface() then
                MR._tickFrame:Hide()
            end
            if MR.SuspendHiddenSurfaceWork then MR:SuspendHiddenSurfaceWork() end
        end)

        self.altBoardFrame = frame
    end

    self.altBoardFrame:SetScale(self.db.profile.scale or 1)
    self.altBoardFrame:Show()
    if self.ActivateVisibleTrackingSurface then
        self:ActivateVisibleTrackingSurface()
    end
    self:RefreshWarbandBoard()
end

function MR:ToggleMainAltPicker()
    local state = Warband.state
    local picker = state and state.mainAltPickerFrame
    if picker and picker:IsShown() then
        picker:Hide()
        return
    end

    if not state then
        return
    end
    if not picker then
        picker = WBBuildMainAltPicker()
        state.mainAltPickerFrame = picker
    end

    if MR._characterBar then
        picker:SetWidth(math.max(220, MR._characterBar:GetWidth() or 220))
    end
    picker:ClearAllPoints()
    if MR._characterBar then
        if ns.GetMainHeaderPosition and ns.GetMainHeaderPosition() == "bottom" then
            picker:SetPoint("BOTTOMLEFT", MR._characterBar, "TOPLEFT", 0, 2)
        else
            picker:SetPoint("TOPLEFT", MR._characterBar, "BOTTOMLEFT", 0, -2)
        end
    elseif MR.frame then
        picker:SetPoint("TOPLEFT", MR.frame, "BOTTOMLEFT", 0, -2)
    else
        picker:SetPoint("CENTER", UIParent, "CENTER", -120, 0)
    end
    picker:Show()
    WBRefreshMainAltPicker(picker)
end

function MR:HideMainAltPicker()
    local state = Warband.state
    local picker = state and state.mainAltPickerFrame
    if picker then
        picker:Hide()
    end
end

function MR:RefreshMainAltPicker()
    local state = Warband.state
    local picker = state and state.mainAltPickerFrame
    if picker and picker:IsShown() then
        WBRefreshMainAltPicker(picker)
    end
end


