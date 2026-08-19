local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")
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
local hex = ns.Hex
local COL = ns.COLORS
local GetWidgetCache = ns.GetWidgetCache
local HideUnusedWidgets = ns.HideUnusedWidgets
local ResetSelectableWidget = ns.ResetSelectableWidget
local DAY_SECONDS = 24 * 60 * 60
local WBState = ns.WarbandBoardState or {}
ns.WarbandBoardState = WBState

local function GetFontSize()
    return (ns.GetFontSize and ns.GetFontSize()) or 11
end

local function GetFontFlags()
    return (ns.GetFontFlags and ns.GetFontFlags(MR.GetActiveMediaSettings and MR:GetActiveMediaSettings() or (MR.db and MR.db.profile))) or "OUTLINE"
end

local function RefreshFonts()
    if ns.EnsureFonts then
        FONT_HEADERS, FONT_ROWS = ns.EnsureFonts()
    end
end

function MR:RefreshWarbandBoardFonts()
    RefreshFonts()
end

local function GetWindowLayoutValue(key)
    return MR.GetWindowLayoutValue and MR:GetWindowLayoutValue(key) or nil
end

local function SetWindowLayoutValue(key, value)
    if MR.SetWindowLayoutValue then
        MR:SetWindowLayoutValue(key, value)
    end
end

local function WBClean(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end

    return text:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
end

local function WBHexColor(hexColor, fallbackR, fallbackG, fallbackB)
    if type(hexColor) == "string" and hexColor ~= "" then
        return hex(hexColor)
    end

    return fallbackR or 1, fallbackG or 1, fallbackB or 1
end

local function WBApplySurface(frame, variant, alpha)
    if not frame then
        return
    end

    if ns.HookBackdropFrame then
        ns.HookBackdropFrame(frame)
    end

    if variant == "panel" then
        frame:SetBackdropColor(0.018, 0.030, 0.050, alpha or 0.96)
        frame:SetBackdropBorderColor(0.10, 0.16, 0.24, 0.72)
    elseif variant == "raised" then
        frame:SetBackdropColor(0.030, 0.055, 0.085, alpha or 0.96)
        frame:SetBackdropBorderColor(0.16, 0.26, 0.34, 0.78)
    elseif variant == "soft" then
        frame:SetBackdropColor(0.022, 0.038, 0.060, alpha or 0.92)
        frame:SetBackdropBorderColor(0.07, 0.12, 0.18, 0.62)
    else
        frame:SetBackdropColor(0.014, 0.024, 0.042, alpha or 0.98)
        frame:SetBackdropBorderColor(0.08, 0.13, 0.20, 0.76)
    end
end

local function WBStylePillButton(btn, active)
    if not btn then
        return
    end

    btn:SetBackdropColor(active and 0.045 or 0.024, active and 0.095 or 0.050, active and 0.130 or 0.080, active and 0.96 or 0.88)
    btn:SetBackdropBorderColor(active and 0.20 or 0.10, active and 0.62 or 0.24, active and 0.56 or 0.30, active and 0.95 or 0.70)
    if btn._label then
        btn._label:SetTextColor(active and 0.88 or 0.62, active and 0.96 or 0.76, active and 0.92 or 0.78)
    end
end

function MR:RequestWarbandBoardRefresh(immediate)
    if not (self and self.altBoardFrame and self.altBoardFrame:IsShown() and self.RefreshWarbandBoard) then
        return
    end

    if immediate then
        self._warbandBoardRefreshQueued = nil
        self:RefreshWarbandBoard()
        return
    end

    local now = GetTime and GetTime() or 0
    local lastRefreshAt = self._warbandBoardLastRefreshAt or 0
    local minInterval = 0.75

    if (now - lastRefreshAt) >= minInterval then
        self:RefreshWarbandBoard()
        return
    end

    if self._warbandBoardRefreshQueued then
        return
    end

    self._warbandBoardRefreshQueued = true
    C_Timer.After(minInterval, function()
        if not MR then
            return
        end
        MR._warbandBoardRefreshQueued = nil
        if MR.altBoardFrame and MR.altBoardFrame:IsShown() and MR.RefreshWarbandBoard then
            MR:RefreshWarbandBoard()
        end
    end)
end

function MR:RefreshWarbandDataSurfaces()
    local boardVisible = self.altBoardFrame and self.altBoardFrame:IsShown()
    if boardVisible and self.RefreshWarbandBoard then
        self:RefreshWarbandBoard()
    elseif self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown() and self.RefreshConcentrationTracker then
        self:RefreshConcentrationTracker()
    end
end

function MR:RefreshWarbandCharacterSurfaces()
    self:RefreshWarbandDataSurfaces()
    if self.RefreshMainAltPicker then
        self:RefreshMainAltPicker()
    end
end

local function WBFormatTimestamp(ts)
    if not ts or ts <= 0 then
        return L["AltBoard_NoScanRecorded"] or "No scan recorded"
    end

    return date("%b %d, %H:%M", ts)
end

local function WBStatusText(entry)
    if not entry then
        return L["AltBoard_NoCharacters"] or "No characters found"
    end
    if entry.stale then
        return L["AltBoard_NeedsLogin"] or "Needs login after reset"
    end
    if (entry.doneRows or 0) >= (entry.totalRows or 0) and (entry.totalRows or 0) > 0 then
        return L["AltBoard_EverythingDone"] or "Everything done"
    end
    if (entry.doneRows or 0) == 0 and (entry.activeRows or 0) == 0 then
        return L["AltBoard_FreshWeek"] or "Fresh week"
    end

    if (entry.activeRows or 0) > 0 then
        return string.format(L["AltBoard_StatusCompleteProgress"] or "%d complete, %d in progress", entry.doneRows or 0, entry.activeRows or 0)
    end

    return string.format(L["AltBoard_StatusCompleteOnly"] or "%d complete", entry.doneRows or 0)
end

local function WBStatusColor(entry)
    if not entry then
        return 0.6, 0.6, 0.6
    end
    if entry.stale then
        return 0.95, 0.50, 0.25
    end
    if (entry.doneRows or 0) >= (entry.totalRows or 0) and (entry.totalRows or 0) > 0 then
        return 0.20, 0.95, 0.60
    end
    if (entry.activeRows or 0) > 0 then
        return 1.00, 0.76, 0.28
    end

    return 0.55, 0.72, 0.95
end

local function WBCharacterMatchesSearch(entry, query)
    if not entry or query == nil or query == "" then
        return true
    end

    query = tostring(query):lower()
    local haystack = table.concat({
        entry.name or "",
        entry.realm or "",
        entry.note or "",
        entry.key or "",
    }, " "):lower()

    return haystack:find(query, 1, true) ~= nil
end

local function WBClassColor(entry)
    local classFile = entry and entry.classFile
    local classColor = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if classColor then
        return classColor.r, classColor.g, classColor.b
    end

    return WBStatusColor(entry)
end

local WBConcentrationColor

local WBRestoreDragTarget

local function WBEnsureDragGhost()
    if WBState.WBDragGhost then
        return WBState.WBDragGhost
    end

    local ghost = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    ghost:SetFrameStrata("TOOLTIP")
    ghost:SetSize(170, 24)
    ghost:SetBackdrop(MakeBackdrop())
    ghost:SetBackdropColor(0.018, 0.032, 0.048, 0.94)
    ghost:SetBackdropBorderColor(0.20, 0.78, 0.70, 0.95)
    ghost:EnableMouse(false)
    ghost:Hide()

    local label = ghost:CreateFontString(nil, "OVERLAY")
    label:SetFont(ns.FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
    label:SetPoint("LEFT", ghost, "LEFT", 8, 0)
    label:SetPoint("RIGHT", ghost, "RIGHT", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetTextColor(0.92, 0.98, 1.00)
    ghost.label = label

    ghost:SetScript("OnUpdate", function(selfGhost)
        if not IsMouseButtonDown("LeftButton") then
            selfGhost:Hide()
            WBState.WBDraggingConcentrationSkillLineID = nil
            WBState.WBDraggingAltBoardCharacterKey = nil
            WBRestoreDragTarget()
            return
        end

        local x, y = GetCursorPosition()
        if x and y then
            local scale = UIParent:GetEffectiveScale()
            selfGhost:ClearAllPoints()
            selfGhost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", (x / scale) + 18, (y / scale) - 14)
        end
    end)

    WBState.WBDragGhost = ghost
    return ghost
end

local function WBStartDragVisual(label, r, g, b)
    local ghost = WBEnsureDragGhost()
    ghost.label:SetText(label or "")
    ghost:SetBackdropBorderColor(r or 0.20, g or 0.78, b or 0.70, 0.95)
    ghost:Show()
end

WBRestoreDragTarget = function()
    if WBState.WBDragTarget and WBState.WBDragTarget.SetBackdropBorderColor then
        local c = WBState.WBDragTarget._dragBorderColor
        if c then
            WBState.WBDragTarget:SetBackdropBorderColor(c[1], c[2], c[3], c[4])
        end
    end
    WBState.WBDragTarget = nil
end

local function WBStopDragVisual()
    if WBState.WBDragGhost then
        WBState.WBDragGhost:Hide()
    end
    WBRestoreDragTarget()
end

local function WBMarkDragTarget(target)
    if WBState.WBDragTarget == target then
        return
    end
    WBRestoreDragTarget()
    WBState.WBDragTarget = target
    if target and target.SetBackdropBorderColor then
        target:SetBackdropBorderColor(1.00, 0.95, 0.35, 1)
    end
end

local function WBUpdateDragTargetFromCursor(sourceID, chips, setter, orientation)
    if not sourceID or type(chips) ~= "table" then
        return
    end

    local cursorX, cursorY = GetCursorPosition()
    if not cursorX or not cursorY then
        return
    end

    for _, chip in ipairs(chips) do
        local targetID = chip and chip.dragID
        if chip and chip:IsShown() and targetID and targetID ~= sourceID then
            local scale = chip.GetEffectiveScale and chip:GetEffectiveScale() or UIParent:GetEffectiveScale()
            local x = cursorX / scale
            local y = cursorY / scale
            local left, right, top, bottom = chip:GetLeft(), chip:GetRight(), chip:GetTop(), chip:GetBottom()
            if left and right and top and bottom and x >= left and x <= right and y <= top and y >= bottom then
                local afterTarget
                if orientation == "horizontal" then
                    afterTarget = x > (left + ((right - left) * 0.5))
                else
                    afterTarget = y < (bottom + ((top - bottom) * 0.5))
                end
                WBMarkDragTarget(chip)
                return setter(sourceID, targetID, afterTarget)
            end
        end
    end
    WBRestoreDragTarget()
    return false
end

WBConcentrationColor = function(entry)
    if not entry then
        return 0.55, 0.72, 0.95
    end

    local current = tonumber(entry.estimatedQuantity) or tonumber(entry.quantity) or 0
    local maxQuantity = tonumber(entry.maxQuantity) or 0
    if maxQuantity > 0 and current >= maxQuantity then
        return 0.20, 0.95, 0.60
    end
    if current <= 0 then
        return 0.95, 0.35, 0.35
    end

    return 1.00, 0.76, 0.28
end

local function GetExpansionDisplayInfo(forAltBoard)
    local key = MR:GetSelectedExpansionKey(forAltBoard)
    return MR:GetExpansionInfo(key)
end

ns.GetExpansionDisplayInfo = GetExpansionDisplayInfo

local function GetExpansionDisplayLabel(forAltBoard)
    local info = GetExpansionDisplayInfo(forAltBoard)
    return info and (info.shortLabel or info.label or info.key) or "Midnight"
end

local function CycleExpansion(forAltBoard, direction)
    local expansions = MR:GetSelectableExpansions()
    if #expansions <= 1 then
        return
    end

    local currentKey = MR:GetSelectedExpansionKey(forAltBoard)
    local currentIndex = 1
    for idx, info in ipairs(expansions) do
        if info.key == currentKey then
            currentIndex = idx
            break
        end
    end

    local nextIndex = currentIndex + (direction or 1)
    if nextIndex < 1 then
        nextIndex = #expansions
    elseif nextIndex > #expansions then
        nextIndex = 1
    end

    MR:SetSelectedExpansionKey(expansions[nextIndex].key, forAltBoard)
end

local function BuildExpansionDropdown(parent, forAltBoard, opts)
    opts = opts or {}
    return ns.CreateDropdown(parent, {
        width = opts.width or 150,
        height = opts.height or 18,
        fontSize = opts.fontSize or function()
            return math.max(8, GetFontSize() - 1)
        end,
        getOptions = function()
            return MR:GetSelectableExpansions()
        end,
        getSelected = function()
            return MR:GetSelectedExpansionKey(forAltBoard)
        end,
        onSelect = function(key)
            MR:SetSelectedExpansionKey(key, forAltBoard)
        end,
        hideWhenSingle = true,
        style = "teal",
    })
end

ns.BuildExpansionDropdown = BuildExpansionDropdown

local function WBConcentrationText(entry)
    if not entry then
        return "-"
    end

    local current = math.floor((tonumber(entry.estimatedQuantity) or tonumber(entry.quantity) or 0) + 0.0001)
    local maxQuantity = tonumber(entry.maxQuantity) or 0
    if maxQuantity > 0 then
        return string.format("%d / %d", current, maxQuantity)
    end

    return tostring(current)
end

local function WBConcentrationCurrent(entry)
    return math.max(0, math.floor((tonumber(entry and entry.estimatedQuantity) or tonumber(entry and entry.quantity) or 0) + 0.0001))
end

local function WBConcentrationDailyGain(entry)
    local cycleMS = tonumber(entry and entry.rechargingCycleDurationMS) or 0
    local amountPerCycle = tonumber(entry and entry.rechargingAmountPerCycle) or 1
    if amountPerCycle <= 0 then
        amountPerCycle = 1
    end
    if cycleMS <= 0 or amountPerCycle <= 0 then
        return 0
    end

    return math.max(0, math.floor(((DAY_SECONDS * 1000) / cycleMS) * amountPerCycle + 0.0001))
end

local function WBConcentrationProjectedQuantity(entry, aheadSeconds)
    local current = WBConcentrationCurrent(entry)
    local maxQuantity = tonumber(entry and entry.maxQuantity) or 0
    local cycleMS = tonumber(entry and entry.rechargingCycleDurationMS) or 0
    local amountPerCycle = tonumber(entry and entry.rechargingAmountPerCycle) or 1
    if amountPerCycle <= 0 then
        amountPerCycle = 1
    end
    local secondsAhead = tonumber(aheadSeconds) or 0

    if maxQuantity > 0 and current >= maxQuantity then
        return maxQuantity
    end
    if secondsAhead <= 0 or cycleMS <= 0 or amountPerCycle <= 0 then
        return maxQuantity > 0 and math.min(current, maxQuantity) or current
    end

    local cycles = math.floor((secondsAhead * 1000) / cycleMS)
    local projected = current + (cycles * amountPerCycle)
    if maxQuantity > 0 then
        projected = math.min(projected, maxQuantity)
    end

    return math.max(0, math.floor(projected + 0.0001))
end

local function WBConcentrationTimeToFull(entry)
    local current = WBConcentrationCurrent(entry)
    local maxQuantity = tonumber(entry and entry.maxQuantity) or 0
    local cycleMS = tonumber(entry and entry.rechargingCycleDurationMS) or 0
    local amountPerCycle = tonumber(entry and entry.rechargingAmountPerCycle) or 1
    if amountPerCycle <= 0 then
        amountPerCycle = 1
    end

    if maxQuantity <= 0 or current >= maxQuantity then
        return 0, GetServerTime()
    end
    if cycleMS <= 0 or amountPerCycle <= 0 then
        return nil, nil
    end

    local remaining = math.max(0, maxQuantity - current)
    local cyclesNeeded = math.ceil(remaining / amountPerCycle)
    local seconds = math.max(0, math.floor((cyclesNeeded * cycleMS) / 1000 + 0.5))
    return seconds, (GetServerTime() or time()) + seconds
end

local function WBFormatDurationShort(seconds)
    if not seconds or seconds <= 0 then
        return "0h"
    end

    local days = math.floor(seconds / DAY_SECONDS)
    local hours = math.floor((seconds % DAY_SECONDS) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    if days > 0 then
        return string.format("%dd %dh", days, hours)
    end
    if hours > 0 then
        return string.format("%dh %dm", hours, minutes)
    end
    return string.format("%dm", math.max(1, minutes))
end

local function WBFormatConcentrationFullAt(ts)
    if not ts or ts <= 0 then
        return "-"
    end

    return date("%d.%m %H:%M", ts)
end

local function WBConcentrationLabel()
    return rawget(L, "Concentration") or "Concentration"
end

local function WBGetConcentrationTrackerAlpha()
    local value = tonumber(GetWindowLayoutValue("concentrationTrackerAlpha")) or 1
    return math.max(0, math.min(1, value))
end

local function WBSetConcentrationTrackerAlpha(value)
    SetWindowLayoutValue("concentrationTrackerAlpha", math.max(0, math.min(1, tonumber(value) or 1)))
end

local function WBIsConcentrationTrackerCompact()
    return GetWindowLayoutValue("concentrationTrackerCompact") == true
end

local function WBSetConcentrationTrackerCompact(value)
    SetWindowLayoutValue("concentrationTrackerCompact", value and true or false)
end

local function WBGetConcentrationTrackerHiddenCharacters()
    local hidden = GetWindowLayoutValue("concentrationTrackerHiddenCharacters")
    if type(hidden) ~= "table" then
        hidden = {}
        SetWindowLayoutValue("concentrationTrackerHiddenCharacters", hidden)
    end
    return hidden
end

local function WBIsConcentrationTrackerCharacterHidden(charKey)
    return charKey and WBGetConcentrationTrackerHiddenCharacters()[charKey] == true
end

local function WBSetConcentrationTrackerCharacterHidden(charKey, hidden)
    if not charKey then
        return
    end

    local hiddenCharacters = WBGetConcentrationTrackerHiddenCharacters()
    hiddenCharacters[charKey] = hidden and true or nil
end

local function WBApplyConcentrationTrackerTheme(frame)
    if not frame then
        return
    end

    local value = WBGetConcentrationTrackerAlpha()
    frame:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4] * value)
    frame:SetBackdropBorderColor(0.15, 0.15, 0.20, value)
    if frame.titleBar then
        frame.titleBar:SetBackdropColor(0.03, 0.06, 0.12, 0.98 * value)
        frame.titleBar:SetBackdropBorderColor(0.17, 0.24, 0.32, value)
    end
end

local function WBAltLoginPrompt()
    return L["AltBoard_LoginAltPrompt"] or "Log into an alt for it to show here."
end

local function WBGetAltBoardView()
    local view = MR and MR.db and MR.db.profile and MR.db.profile.altBoardView
    return view == "concentration" and "concentration" or "character"
end

local function WBSetAltBoardView(view)
    if MR and MR.db and MR.db.profile then
        MR.db.profile.altBoardView = (view == "concentration") and "concentration" or "character"
    end
end

local function WBShouldHideCompletedCharacters()
    return MR
        and MR.db
        and MR.db.profile
        and MR.db.profile.altBoardHideCompleted == true
end

local function WBCreateScrollArea(parent, topLeftAnchor, bottomRightAnchor)
    return ns.CreateScrollArea(parent, topLeftAnchor, bottomRightAnchor, {
        hideTrack = true,
        minThumbHeight = 18,
        thumbColor = { 0.24, 0.72, 0.72, 0.80 },
    })
end

local function WBRefreshAltBoardTabs(frame)
    if not frame or not frame.altTabs then
        return
    end

    local activeView = WBGetAltBoardView()
    for viewKey, tab in pairs(frame.altTabs) do
        local active = viewKey == activeView
        WBStylePillButton(tab, active)
    end
end

local function ConfigureConcentrationDragSurface(content)
    content._orderChips = content._orderChips or {}
    wipe(content._orderChips)
end

local function MoveConcentrationProfession(dragID, targetID, afterTarget)
    if MR.SetAltBoardConcentrationProfessionPosition then
        return MR:SetAltBoardConcentrationProfessionPosition(dragID, targetID, afterTarget)
    end
    return false
end

local function UpdateConcentrationDrag(content)
    local sourceID = WBState.WBDraggingConcentrationSkillLineID
    if not sourceID or not IsMouseButtonDown("LeftButton") then
        WBState.WBDraggingConcentrationSkillLineID = nil
        content:SetScript("OnUpdate", nil)
        WBStopDragVisual()
        return
    end
    WBUpdateDragTargetFromCursor(sourceID, content._orderChips, MoveConcentrationProfession)
end

local function ResetConcentrationRow(row)
    row._entry = nil
    row._dragSurface = nil
end

local function EnsureConcentrationRow(card, index)
    local rows = GetWidgetCache(card, "_rows")
    local row = rows[index]
    if row then return row end

    row = CreateFrame("Frame", nil, card, "BackdropTemplate")
    row:SetBackdrop(MakeBackdrop(false))
    row:EnableMouse(true)
    row._dragBorderColor = {}
    row._label = row:CreateFontString(nil, "OVERLAY")
    row._label:SetJustifyH("LEFT")
    row._value = row:CreateFontString(nil, "OVERLAY")
    row._value:SetJustifyH("RIGHT")
    row._bar = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row._bar:SetBackdrop(MakeBackdrop(false))
    row._bar:SetBackdropColor(0.08, 0.12, 0.18, 1)
    row._projectedFill = row._bar:CreateTexture(nil, "ARTWORK")
    row._projectedFill:SetPoint("TOPLEFT")
    row._projectedFill:SetPoint("BOTTOMLEFT")
    row._currentFill = row._bar:CreateTexture(nil, "OVERLAY")
    row._currentFill:SetPoint("TOPLEFT")
    row._currentFill:SetPoint("BOTTOMLEFT")
    row._gain = row:CreateFontString(nil, "OVERLAY")
    row._gain:SetJustifyH("LEFT")
    row._full = row:CreateFontString(nil, "OVERLAY")
    row._full:SetJustifyH("RIGHT")
    row._fullAt = row:CreateFontString(nil, "OVERLAY")
    row._fullAt:SetJustifyH("RIGHT")

    row:SetScript("OnMouseDown", function(selfRow, button)
        if button ~= "LeftButton" or not selfRow._entry then return end
        WBState.WBDraggingConcentrationSkillLineID = selfRow.dragID
        if selfRow._dragSurface then
            selfRow._dragSurface:SetScript("OnUpdate", UpdateConcentrationDrag)
        end
        WBStartDragVisual(selfRow._labelText, selfRow._r, selfRow._g, selfRow._b)
        selfRow._dragging = true
        selfRow:SetBackdropColor(0.055 + selfRow._r * 0.040, 0.070 + selfRow._g * 0.040, 0.090 + selfRow._b * 0.040, 0.40)
        selfRow:SetBackdropBorderColor(selfRow._r, selfRow._g, selfRow._b, 1)
        ns.HideTooltip()
    end)
    row:SetScript("OnMouseUp", function(selfRow, button)
        if button ~= "LeftButton" then return end
        WBState.WBDraggingConcentrationSkillLineID = nil
        if selfRow._dragSurface then
            selfRow._dragSurface:SetScript("OnUpdate", nil)
        end
        WBStopDragVisual()
        selfRow._dragging = nil
        selfRow:SetBackdropColor(0, 0, 0, 0)
        selfRow:SetBackdropBorderColor(selfRow._r * 0.36, selfRow._g * 0.36, selfRow._b * 0.36, 0)
    end)
    row:SetScript("OnEnter", function(selfRow)
        ns.ShowTooltip(selfRow, { text = L["AltBoard_DragProfessionOrder"] or "Click and drag to reorder professions." })
    end)
    row:SetScript("OnLeave", function(selfRow) ns.HideTooltip(selfRow) end)

    rows[index] = row
    MR._warbandConcentrationRowCreatedCount = (MR._warbandConcentrationRowCreatedCount or 0) + 1
    return row
end

local function EnsureConcentrationCard(frame, poolKey, index, content)
    local cards = GetWidgetCache(frame, poolKey)
    local card = cards[index]
    if card then return card end

    card = CreateFrame("Frame", nil, content, "BackdropTemplate")
    card:SetBackdrop(MakeBackdrop())
    card._topAccent = card:CreateTexture(nil, "ARTWORK")
    card._topAccent:SetPoint("TOPLEFT")
    card._topAccent:SetPoint("TOPRIGHT")
    card._topAccent:SetHeight(3)
    card._leftAccent = card:CreateTexture(nil, "ARTWORK")
    card._leftAccent:SetPoint("TOPLEFT")
    card._leftAccent:SetPoint("BOTTOMLEFT")
    card._leftAccent:SetWidth(3)
    card._name = card:CreateFontString(nil, "OVERLAY")
    card._name:SetJustifyH("LEFT")
    card._meta = card:CreateFontString(nil, "OVERLAY")
    card._meta:SetJustifyH("RIGHT")

    cards[index] = card
    MR._warbandConcentrationCardCreatedCount = (MR._warbandConcentrationCardCreatedCount or 0) + 1
    return card
end

local function UpdateConcentrationRow(row, entry, contentWidth, mode, compact, rowY, dragSurface)
    local rr, rg, rb = WBConcentrationColor(entry)
    local current = WBConcentrationCurrent(entry)
    local maxQuantity = tonumber(entry.maxQuantity) or 0
    local projected = WBConcentrationProjectedQuantity(entry, DAY_SECONDS)
    local dailyGain = math.max(0, projected - current)
    local fullInSeconds, fullAt = WBConcentrationTimeToFull(entry)
    local overview = mode == "overview"
    local rowHeight = overview and 54 or (compact and 24 or 42)

    row._entry = entry
    row._dragSurface = dragSurface
    row._labelText = entry.label or (L["Unknown"] or "Unknown")
    row._r, row._g, row._b = rr, rg, rb
    row.dragID = tonumber(entry.skillLineID)
    row._dragBorderColor[1], row._dragBorderColor[2] = rr * 0.36, rg * 0.36
    row._dragBorderColor[3], row._dragBorderColor[4] = rb * 0.36, 0
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", row:GetParent(), "TOPLEFT", 12, -rowY)
    row:SetPoint("TOPRIGHT", row:GetParent(), "TOPRIGHT", -12, -rowY)
    row:SetHeight(rowHeight)
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(rr * 0.36, rg * 0.36, rb * 0.36, 0)

    row._label:ClearAllPoints()
    row._label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row._label:SetPoint("TOPRIGHT", row, "TOPRIGHT", overview and -110 or -105, 0)
    row._label:SetFont(overview and ns.FONT_HEADERS or ns.FONT_ROWS, compact and math.max(8, GetFontSize() - 1) or math.max(9, GetFontSize()), GetFontFlags())
    row._label:SetText(row._labelText)
    row._label:SetTextColor(overview and 0.88 or 0.86, overview and 0.92 or 0.91, overview and 0.97 or 0.97)
    row._value:ClearAllPoints()
    row._value:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    row._value:SetFont(ns.FONT_HEADERS, compact and math.max(8, GetFontSize() - 1) or math.max(9, GetFontSize()), GetFontFlags())
    row._value:SetText(maxQuantity > 0 and string.format("%d / %d", current, maxQuantity) or tostring(current))
    row._value:SetTextColor(rr, rg, rb)

    row._bar:ClearAllPoints()
    row._bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, compact and not overview and -15 or -18)
    row._bar:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, compact and not overview and -15 or -18)
    row._bar:SetHeight(overview and 8 or (compact and 4 or 7))
    row._projectedFill:SetColorTexture(rr, rg, rb, 0.22)
    row._currentFill:SetColorTexture(rr, rg, rb, 0.88)
    local barWidth = math.max(contentWidth - 24, 1)
    local currentPct = maxQuantity > 0 and math.min(1, current / maxQuantity) or 0
    local projectedPct = maxQuantity > 0 and math.min(1, projected / maxQuantity) or currentPct
    row._currentFill:SetWidth(math.max(1, barWidth * currentPct))
    row._projectedFill:SetWidth(math.max(1, barWidth * projectedPct))

    if overview or not compact then
        row._gain:ClearAllPoints()
        row._gain:SetPoint("TOPLEFT", row._bar, "BOTTOMLEFT", 0, -4)
        row._gain:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
        row._gain:SetText(string.format(L["AltBoard_ConcentrationProjected24h"] or "24h +%d", dailyGain))
        row._gain:SetTextColor(0.68, 0.77, 0.86)
        row._gain:Show()
        row._full:ClearAllPoints()
        row._full:SetPoint("TOPRIGHT", row._bar, "BOTTOMRIGHT", 0, -4)
        row._full:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
        if fullInSeconds == nil then
            row._full:SetText(L["AltBoard_AwaitingRefresh"] or "Awaiting refresh")
        elseif fullInSeconds <= 0 then
            row._full:SetText(L["AltBoard_ConcentrationFull"] or "Fully replenished")
        else
            row._full:SetText(string.format(L["AltBoard_ConcentrationFullIn"] or "Full in %s", WBFormatDurationShort(fullInSeconds)))
        end
        row._full:SetTextColor(0.68, 0.77, 0.86)
        row._full:Show()
    else
        row._gain:Hide()
        row._full:Hide()
    end
    if overview then
        row._fullAt:ClearAllPoints()
        row._fullAt:SetPoint("TOPLEFT", row._gain, "BOTTOMLEFT", 0, -3)
        row._fullAt:SetPoint("TOPRIGHT", row._full, "BOTTOMRIGHT", 0, -3)
        row._fullAt:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
        if fullInSeconds == nil then row._fullAt:SetText("")
        elseif fullInSeconds <= 0 then row._fullAt:SetText(L["AltBoard_ConcentrationFullNow"] or "Full now")
        else row._fullAt:SetText(string.format(L["AltBoard_ConcentrationFullAt"] or "Full on %s", WBFormatConcentrationFullAt(fullAt))) end
        row._fullAt:SetTextColor(0.52, 0.62, 0.72)
        row._fullAt:Show()
    else
        row._fullAt:Hide()
    end
    row:Show()
end

local function PopulateConcentrationCards(frame, data, opts)
    local content = opts.content
    local cards = GetWidgetCache(frame, opts.poolKey)
    ConfigureConcentrationDragSurface(content)
    content:SetWidth(opts.contentWidth)
    local cardIndex, totalCharacters, totalProfessions, hiddenCount, yOff = 0, 0, 0, 0, 0

    for _, charEntry in ipairs(data or {}) do
        local entries = type(charEntry.concentration) == "table" and charEntry.concentration or nil
        if entries and #entries > 0 and opts.isHidden and opts.isHidden(charEntry) then
            hiddenCount = hiddenCount + 1
        elseif entries and #entries > 0 then
            cardIndex = cardIndex + 1
            totalCharacters = totalCharacters + 1
            totalProfessions = totalProfessions + #entries
            local card = EnsureConcentrationCard(frame, opts.poolKey, cardIndex, content)
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOff)
            card:SetWidth(opts.contentWidth)
            WBApplySurface(card, "soft", opts.alpha or 0.96)
            local cr, cg, cb = WBClassColor(charEntry)
            if opts.mode == "overview" then
                card._topAccent:SetColorTexture(cr, cg, cb, 1)
                card._topAccent:Show()
                card._leftAccent:Hide()
            else
                card._leftAccent:Hide()
                card._topAccent:Hide()
                card:SetBackdropBorderColor(0.08, 0.16, 0.24, 0.80 * (opts.alpha or 1))
            end
            card._name:ClearAllPoints()
            card._name:SetPoint("TOPLEFT", card, "TOPLEFT", 12, opts.compact and -7 or -10)
            card._name:SetPoint("TOPRIGHT", card, "TOPRIGHT", -110, -10)
            card._name:SetFont(ns.FONT_HEADERS, opts.compact and math.max(9, GetFontSize()) or math.max(10, GetFontSize() + 1), GetFontFlags())
            card._name:SetText(charEntry.isCurrent and (charEntry.name .. "  |cff7ce7d8" .. (L["AltBoard_Current"] or "Current") .. "|r") or charEntry.name)
            if opts.mode == "overview" then
                card._name:SetTextColor(0.94, 0.98, 1)
            else
                card._name:SetTextColor(cr, cg, cb)
            end
            card._meta:ClearAllPoints()
            card._meta:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, opts.mode == "overview" and -10 or -11)
            card._meta:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
            card._meta:SetText(charEntry.realm ~= "" and charEntry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"))
            card._meta:SetTextColor(0.64, 0.72, 0.82)

            local rowY = opts.mode == "overview" and 32 or (opts.compact and 26 or 34)
            for rowIndex, entry in ipairs(entries) do
                local row = EnsureConcentrationRow(card, rowIndex)
                UpdateConcentrationRow(row, entry, opts.contentWidth, opts.mode, opts.compact, rowY, content)
                content._orderChips[#content._orderChips + 1] = row
                rowY = rowY + (opts.mode == "overview" and 62 or (opts.compact and 30 or 48))
            end
            HideUnusedWidgets(card._rows, #entries, ResetConcentrationRow)
            card:SetHeight(rowY + (opts.mode == "overview" and 4 or (opts.compact and 2 or 4)))
            card:Show()
            yOff = yOff + card:GetHeight() + (opts.mode == "overview" and 14 or (opts.compact and 6 or 10))
        end
    end
    HideUnusedWidgets(cards, cardIndex)
    return totalCharacters, totalProfessions, hiddenCount, yOff
end
local function WBPopulateConcentrationOverview(frame, data)
    if not frame or not frame.overviewContent then
        return 0, 0
    end

    local contentWidth = math.max((frame.overviewScroll and frame.overviewScroll:GetWidth() or frame.rightPane:GetWidth() or 520) - 8, 320)
    local totalCharacters, totalProfessions, _, yOff = PopulateConcentrationCards(frame, data, {
        content = frame.overviewContent,
        contentWidth = contentWidth,
        poolKey = "_overviewCards",
        mode = "overview",
    })

    if totalProfessions == 0 then
        local empty = frame.overviewEmptyLabel
        if empty then
            empty:SetPoint("TOPLEFT", frame.overviewContent, "TOPLEFT", 8, -6)
            empty:SetPoint("TOPRIGHT", frame.overviewContent, "TOPRIGHT", -8, -6)
            empty:SetText(L["AltBoard_ConcentrationNone"] or "No concentration data on tracked characters yet.")
            empty:Show()
        end
        frame.overviewContent:SetHeight(40)
    else
        if frame.overviewEmptyLabel then frame.overviewEmptyLabel:Hide() end
        frame.overviewContent:SetHeight(math.max(yOff, 1))
    end
    if frame.overviewScrollUpdate then frame.overviewScrollUpdate() end
    return totalCharacters, totalProfessions
end

local function WBGetMainAltPickerData(frame)
    local list = frame._pickerData or {}
    local entries = frame._pickerEntryCache or {}
    local orderIndex = frame._pickerOrderIndex or {}
    local seen = frame._pickerSeenKeys or {}
    frame._pickerData = list
    frame._pickerEntryCache = entries
    frame._pickerOrderIndex = orderIndex
    frame._pickerSeenKeys = seen
    wipe(list)
    wipe(orderIndex)
    wipe(seen)

    if MR.GetAltBoardCharacterOrder then
        for index, charKey in ipairs(MR:GetAltBoardCharacterOrder()) do orderIndex[charKey] = index end
    end
    local characters = MR.db and MR.db.sv and MR.db.sv.char
    local hiddenCharacters = MR.db and MR.db.profile and MR.db.profile.altBoardHiddenCharacters or nil
    for charKey, charData in pairs(characters or {}) do
        if type(charData) == "table" and type(charData.progress) == "table" and not (hiddenCharacters and hiddenCharacters[charKey]) then
            local entry = entries[charKey] or {}
            entries[charKey] = entry
            local name, realm = MR:ParseCharacterKey(charKey)
            entry.key = charKey
            entry.name = name or charKey
            entry.realm = realm or ""
            entry.classFile = charData.classFile
            entry.isCurrent = false
            entry._order = orderIndex[charKey] or math.huge
            list[#list + 1] = entry
            seen[charKey] = true
        end
    end
    for charKey in pairs(entries) do if not seen[charKey] then entries[charKey] = nil end end
    table.sort(list, function(a, b)
        if a._order ~= b._order then return a._order < b._order end
        if a.realm ~= b.realm then return a.realm < b.realm end
        return a.name < b.name
    end)
    return list
end

local function WBRefreshMainAltPicker(frame)
    frame = frame or WBState.mainAltPickerFrame
    if not frame then
        return
    end

    RefreshFonts()
    frame:SetScale(MR.db and MR.db.profile and MR.db.profile.scale or 1)

    local data = WBGetMainAltPickerData(frame)
    local searchText = frame.characterSearchText or ""
    local listData = frame._filteredCharacters or {}
    frame._filteredCharacters = listData
    wipe(listData)
    for _, entry in ipairs(data or {}) do
        if WBCharacterMatchesSearch(entry, searchText) then
            listData[#listData + 1] = entry
        end
    end

    local selectedKey = MR.GetMainAltViewCharacterKey and MR:GetMainAltViewCharacterKey() or nil
    local currentKey = MR.GetCurrentCharacterKey and MR:GetCurrentCharacterKey() or nil
    local characterButtons = GetWidgetCache(frame, "charButtons")

    if frame.titleText then
        frame.titleText:SetText(L["AltPicker_Title"] or "All Characters")
    end

    local currentRow = frame._currentCharacterEntry or {}
    frame._currentCharacterEntry = currentRow
    currentRow.key = currentKey
    currentRow.name = UnitName and UnitName("player") or (L["AltPicker_CurrentCharacter"] or "Current Character")
    currentRow.realm = GetRealmName and GetRealmName() or ""
    currentRow.classFile = select(2, UnitClass("player"))
    currentRow.isCurrent = true

    local rows = frame._characterRows or {}
    frame._characterRows = rows
    wipe(rows)
    rows[1] = currentRow
    for _, entry in ipairs(listData) do
        if entry.key ~= currentKey then
            rows[#rows + 1] = entry
        end
    end
    if frame.charRail and frame.leftScroll then
        frame.charRail:SetWidth(math.max((frame.leftScroll:GetWidth() or 220) - 2, 1))
    end
    if frame.countText then
        frame.countText:SetText(tostring(#rows))
    end

    for index, entry in ipairs(rows) do
        local row = characterButtons[index]
        if not row then
            row = CreateFrame("Button", nil, frame.charRail, "BackdropTemplate")
            MR._mainAltPickerRowCreatedCount = (MR._mainAltPickerRowCreatedCount or 0) + 1
            row:SetHeight(28)
            row:SetPoint("TOPLEFT", frame.charRail, "TOPLEFT", 0, -((index - 1) * 30))
            row:SetPoint("TOPRIGHT", frame.charRail, "TOPRIGHT", 0, -((index - 1) * 30))
            row:SetBackdrop(MakeBackdrop())

            local iconPlate = CreateFrame("Frame", nil, row, "BackdropTemplate")
            iconPlate:SetSize(16, 16)
            iconPlate:SetPoint("LEFT", row, "LEFT", 7, 0)
            iconPlate:SetBackdrop(MakeBackdrop())
            iconPlate:SetBackdropColor(0.004, 0.010, 0.016, 0.86)
            row._iconPlate = iconPlate

            local classIcon = iconPlate:CreateTexture(nil, "ARTWORK")
            classIcon:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
            classIcon:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
            classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            row._classIcon = classIcon

            local name = row:CreateFontString(nil, "OVERLAY")
            name:SetPoint("LEFT", row, "LEFT", 29, 0)
            name:SetPoint("RIGHT", row, "RIGHT", -76, 0)
            name:SetJustifyH("LEFT")
            name:SetWordWrap(false)
            row._name = name

            local realm = row:CreateFontString(nil, "OVERLAY")
            realm:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            realm:SetJustifyH("RIGHT")
            realm:SetTextColor(0.68, 0.70, 0.74)
            row._realm = realm

            row:SetScript("OnClick", function(selfRow)
                local selectedEntry = selfRow._entry
                if selectedEntry and MR.SetMainAltViewCharacter then
                    MR:SetMainAltViewCharacter(selectedEntry.isCurrent and nil or selectedEntry.key)
                end
                frame:Hide()
            end)
            row:SetScript("OnEnter", function(selfRow)
                if not selfRow._selected then
                    selfRow:SetBackdropColor(0.020, 0.036, 0.052, 0.82)
                    selfRow:SetBackdropBorderColor(0.10, 0.26, 0.32, 0.62)
                end
            end)
            row:SetScript("OnLeave", function(selfRow)
                if not selfRow._selected then
                    selfRow:SetBackdropColor(0.008, 0.014, 0.022, 0.36)
                    selfRow:SetBackdropBorderColor(0.04, 0.07, 0.10, 0.26)
                end
            end)

            characterButtons[index] = row
        end

        local selectedRow = (entry.isCurrent and not selectedKey) or (selectedKey and selectedKey == entry.key)
        row._entry = entry
        row._selected = selectedRow and true or false
        local cr, cg, cb = WBClassColor(entry)
        if selectedRow then
            row:SetBackdropColor(0.030, 0.058, 0.078, 0.98)
            row:SetBackdropBorderColor(0.16, 0.44, 0.48, 0.78)
        else
            row:SetBackdropColor(0.008, 0.014, 0.022, 0.36)
            row:SetBackdropBorderColor(0.04, 0.07, 0.10, 0.26)
        end

        local iconPlate = row._iconPlate
        iconPlate:SetBackdropBorderColor(cr * 0.42, cg * 0.42, cb * 0.42, selectedRow and 0.84 or 0.58)

        local classIcon = row._classIcon
        local coords = entry.classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[entry.classFile] or nil
        if coords then
            classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
            iconPlate:Show()
        else
            iconPlate:Hide()
        end

        local name = row._name
        name:SetFont(ns.FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
        name:SetText(entry.name)
        name:SetTextColor(cr, cg, cb)

        local realm = row._realm
        realm:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
        realm:SetText(entry.realm ~= "" and entry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"))
        row:Show()
    end

    HideUnusedWidgets(characterButtons, #rows, ResetSelectableWidget)

    frame.charRail:SetHeight(math.max(#rows * 30, 1))
    if frame.leftScrollUpdate then frame.leftScrollUpdate() end
end

local function WBBuildMainAltPicker()
    local frame = StyledFrame(UIParent, nil, "DIALOG", 26)
    frame:SetSize(220, 286)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    if MR._characterBar then
        frame:SetPoint("TOPLEFT", MR._characterBar, "BOTTOMLEFT", 0, -2)
    elseif MR.frame then
        frame:SetPoint("TOPLEFT", MR.frame, "BOTTOMLEFT", 0, -2)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", -120, 0)
    end
    frame:SetBackdrop(MakeBackdrop())
    frame:SetBackdropColor(0.006, 0.010, 0.016, 0.97)
    frame:SetBackdropBorderColor(0.12, 0.28, 0.34, 0.90)
    frame:Hide()

    local titleBar = TitleBar(frame, 26)
    titleBar:SetBackdropColor(0.012, 0.030, 0.044, 0.99)
    titleBar:SetBackdropBorderColor(0.12, 0.32, 0.38, 0.90)
    titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(ns.FONT_HEADERS, math.max(10, GetFontSize()), GetFontFlags())
    title:SetPoint("LEFT", titleBar, "LEFT", 8, 1)
    title:SetText(L["AltPicker_Title"] or "All Characters")
    title:SetTextColor(0.78, 0.96, 0.98)
    frame.titleText = title

    CloseButton(titleBar, function()
        frame:Hide()
    end)

    local countText = titleBar:CreateFontString(nil, "OVERLAY")
    countText:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
    countText:SetPoint("RIGHT", titleBar, "RIGHT", -30, 1)
    countText:SetTextColor(0.42, 0.68, 0.72)
    frame.countText = countText

    local leftPane = CreateFrame("Frame", nil, frame)
    leftPane:SetPoint("TOPLEFT", frame, "TOPLEFT", 7, -33)
    leftPane:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -7, 7)

    local searchBox = CreateFrame("EditBox", nil, leftPane, "BackdropTemplate")
    searchBox:SetHeight(24)
    searchBox:SetPoint("TOPLEFT", leftPane, "TOPLEFT", 0, 0)
    searchBox:SetPoint("TOPRIGHT", leftPane, "TOPRIGHT", 0, 0)
    searchBox:SetAutoFocus(false)
    searchBox:SetFont(ns.FONT_ROWS, math.max(9, GetFontSize() - 1), GetFontFlags())
    searchBox:SetTextColor(0.90, 0.95, 1.00)
    searchBox:SetJustifyH("LEFT")
    searchBox:SetBackdrop(MakeBackdrop())
    searchBox:SetBackdropColor(0.004, 0.010, 0.016, 0.98)
    searchBox:SetBackdropBorderColor(0.08, 0.22, 0.28, 0.78)
    searchBox:SetTextInsets(8, 24, 0, 0)

    local placeholder = searchBox:CreateFontString(nil, "OVERLAY")
    placeholder:SetFont(ns.FONT_ROWS, math.max(9, GetFontSize() - 1), GetFontFlags())
    placeholder:SetPoint("LEFT", searchBox, "LEFT", 8, 0)
    placeholder:SetText(L["AltBoard_SearchPlaceholder"] or "Search characters...")
    placeholder:SetTextColor(0.42, 0.44, 0.50)

    local clearBtn = CreateFrame("Button", nil, searchBox, "BackdropTemplate")
    clearBtn:SetSize(15, 15)
    clearBtn:SetPoint("RIGHT", searchBox, "RIGHT", -5, 0)
    clearBtn:SetBackdrop(MakeBackdrop())
    clearBtn:SetBackdropColor(0.030, 0.030, 0.042, 0.86)
    clearBtn:SetBackdropBorderColor(0.12, 0.12, 0.16, 0.72)
    clearBtn:Hide()

    local clearLabel = clearBtn:CreateFontString(nil, "OVERLAY")
    clearLabel:SetFont(ns.FONT_HEADERS, 8, GetFontFlags())
    clearLabel:SetPoint("CENTER", clearBtn, "CENTER", 0, 1)
    clearLabel:SetText("x")
    clearLabel:SetTextColor(0.70, 0.72, 0.78)

    local function UpdateSearch(text)
        placeholder:SetShown(text == "")
        clearBtn:SetShown(text ~= "")
    end

    searchBox:SetScript("OnTextChanged", function(selfBox)
        local text = selfBox:GetText() or ""
        if frame.characterSearchText == text then
            UpdateSearch(text)
            return
        end
        frame.characterSearchText = text
        UpdateSearch(text)
        WBRefreshMainAltPicker(frame)
    end)
    searchBox:SetScript("OnEscapePressed", function(selfBox)
        selfBox:SetText("")
        selfBox:ClearFocus()
    end)
    searchBox:SetScript("OnEditFocusGained", function()
        searchBox:SetBackdropBorderColor(0.20, 0.58, 0.62, 0.95)
    end)
    searchBox:SetScript("OnEditFocusLost", function()
        searchBox:SetBackdropBorderColor(0.08, 0.22, 0.28, 0.78)
    end)
    clearBtn:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
    end)
    frame.characterSearchBox = searchBox

    local leftScroll, charRail, leftScrollUpdate = WBCreateScrollArea(
        leftPane,
        { "TOPLEFT", leftPane, "TOPLEFT", 0, -31 },
        { "BOTTOMRIGHT", leftPane, "BOTTOMRIGHT", -2, 0 }
    )
    frame.leftScroll = leftScroll
    frame.charRail = charRail
    frame.leftScrollUpdate = leftScrollUpdate
    frame.charButtons = {}

    return frame
end

local function WBPopulateConcentrationTracker(frame, data)
    if not frame or not frame.content then return end

    data = data or MR:GetWarbandWeeklyData()
    local frameWidth = frame:GetWidth()
    if not frameWidth or frameWidth <= 0 then frameWidth = 440 end
    local contentWidth = math.max(frameWidth - 40, 300)
    local compact = WBIsConcentrationTrackerCompact()
    local alpha = WBGetConcentrationTrackerAlpha()
    local totalCharacters, totalProfessions, hiddenCount, yOff = PopulateConcentrationCards(frame, data, {
        content = frame.content,
        contentWidth = contentWidth,
        poolKey = "_concentrationTrackerCards",
        mode = "tracker",
        compact = compact,
        alpha = 0.96 * alpha,
        isHidden = function(charEntry)
            return WBIsConcentrationTrackerCharacterHidden(charEntry.key)
        end,
    })

    if frame.summary then
        if compact then
            frame.summary:Hide()
        else
            frame.summary:Show()
            if totalProfessions > 0 then
                local summaryText = string.format(L["AltBoard_ConcentrationOverviewSub"] or "%d professions across %d characters", totalProfessions, totalCharacters)
                if hiddenCount > 0 then
                    summaryText = summaryText .. string.format("  |  " .. (L["AltBoard_ConcentrationHiddenCount"] or "%d hidden"), hiddenCount)
                end
                frame.summary:SetText(summaryText)
            elseif hiddenCount > 0 then
                frame.summary:SetText(string.format(L["AltBoard_ConcentrationHiddenCount"] or "%d hidden", hiddenCount))
            else
                frame.summary:SetText(L["AltBoard_ConcentrationNone"] or "No concentration data on tracked characters yet.")
            end
        end
    end

    if frame.scroll then
        frame.scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, compact and -32 or -54)
    end

    if totalProfessions == 0 then
        if frame.emptyLabel then
            frame.emptyLabel:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 8, -6)
            frame.emptyLabel:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -8, -6)
            frame.emptyLabel:SetText(L["AltBoard_ConcentrationNone"] or "No concentration data on tracked characters yet.")
            frame.emptyLabel:Show()
        end
        frame.content:SetHeight(42)
    else
        if frame.emptyLabel then frame.emptyLabel:Hide() end
        frame.content:SetHeight(math.max(yOff, 1))
    end

    if GetWindowLayoutValue("concentrationTrackerMinimized") ~= true then
        local neededHeight = math.min(800, math.max(150, (compact and 32 or 54) + (frame.content:GetHeight() or 0) + 14))
        frame:SetHeight(neededHeight)
    end

    if frame.scrollUpdate then frame.scrollUpdate() end
end

local Warband = {
    state = WBState,
    L = L,
    DAY_SECONDS = DAY_SECONDS,
    GetFontSize = GetFontSize,
    GetFontFlags = GetFontFlags,
    RefreshFonts = RefreshFonts,
    GetWindowLayoutValue = GetWindowLayoutValue,
    SetWindowLayoutValue = SetWindowLayoutValue,
    WBClean = WBClean,
    WBHexColor = WBHexColor,
    WBApplySurface = WBApplySurface,
    WBStylePillButton = WBStylePillButton,
    WBFormatTimestamp = WBFormatTimestamp,
    WBStatusText = WBStatusText,
    WBStatusColor = WBStatusColor,
    WBCharacterMatchesSearch = WBCharacterMatchesSearch,
    WBClassColor = WBClassColor,
    WBEnsureDragGhost = WBEnsureDragGhost,
    WBStartDragVisual = WBStartDragVisual,
    WBStopDragVisual = WBStopDragVisual,
    WBMarkDragTarget = WBMarkDragTarget,
    WBUpdateDragTargetFromCursor = WBUpdateDragTargetFromCursor,
    GetExpansionDisplayInfo = GetExpansionDisplayInfo,
    GetExpansionDisplayLabel = GetExpansionDisplayLabel,
    CycleExpansion = CycleExpansion,
    BuildExpansionDropdown = BuildExpansionDropdown,
    WBConcentrationText = WBConcentrationText,
    WBConcentrationCurrent = WBConcentrationCurrent,
    WBConcentrationDailyGain = WBConcentrationDailyGain,
    WBConcentrationProjectedQuantity = WBConcentrationProjectedQuantity,
    WBConcentrationTimeToFull = WBConcentrationTimeToFull,
    WBFormatDurationShort = WBFormatDurationShort,
    WBFormatConcentrationFullAt = WBFormatConcentrationFullAt,
    WBConcentrationLabel = WBConcentrationLabel,
    WBGetConcentrationTrackerAlpha = WBGetConcentrationTrackerAlpha,
    WBSetConcentrationTrackerAlpha = WBSetConcentrationTrackerAlpha,
    WBIsConcentrationTrackerCompact = WBIsConcentrationTrackerCompact,
    WBSetConcentrationTrackerCompact = WBSetConcentrationTrackerCompact,
    WBGetConcentrationTrackerHiddenCharacters = WBGetConcentrationTrackerHiddenCharacters,
    WBIsConcentrationTrackerCharacterHidden = WBIsConcentrationTrackerCharacterHidden,
    WBSetConcentrationTrackerCharacterHidden = WBSetConcentrationTrackerCharacterHidden,
    WBApplyConcentrationTrackerTheme = WBApplyConcentrationTrackerTheme,
    WBAltLoginPrompt = WBAltLoginPrompt,
    WBGetAltBoardView = WBGetAltBoardView,
    WBSetAltBoardView = WBSetAltBoardView,
    WBShouldHideCompletedCharacters = WBShouldHideCompletedCharacters,
    WBCreateScrollArea = WBCreateScrollArea,
    WBRefreshAltBoardTabs = WBRefreshAltBoardTabs,
    WBPopulateConcentrationOverview = WBPopulateConcentrationOverview,
    WBRefreshMainAltPicker = WBRefreshMainAltPicker,
    WBBuildMainAltPicker = WBBuildMainAltPicker,
    WBPopulateConcentrationTracker = WBPopulateConcentrationTracker,
    WBConcentrationColor = WBConcentrationColor,
}
ns.WarbandBoardInternal = Warband
