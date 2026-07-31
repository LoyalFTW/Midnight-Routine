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
local countColor = ns.CountColor
local hex = ns.Hex
local COL = ns.COLORS
local DAY_SECONDS = 24 * 60 * 60
local concentrationTrackerConfigFrame
local mainAltPickerFrame

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

local function WBReleaseWidgets(bucket)
    if not bucket then
        return
    end

    for _, widget in ipairs(bucket or {}) do
        widget:Hide()
        widget:SetParent(nil)
    end
    wipe(bucket)
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

local function WBAddSoftSheen(frame, r, g, b, alpha)
    if not frame then
        return nil
    end

    local tex = frame:CreateTexture(nil, "BACKGROUND")
    tex:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
    tex:SetPoint("RIGHT", frame, "RIGHT", -1, 0)
    tex:SetHeight(24)
    tex:SetTexture("Interface\\Buttons\\WHITE8X8")
    tex:SetColorTexture(r or 0.10, g or 0.20, b or 0.30, alpha or 0.07)
    return tex
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

local WBDraggingConcentrationSkillLineID
local WBDraggingAltBoardCharacterKey
local WBDragGhost
local WBDragTarget
local WBRestoreDragTarget

local function WBEnsureDragGhost()
    if WBDragGhost then
        return WBDragGhost
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
    label:SetFont(FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
    label:SetPoint("LEFT", ghost, "LEFT", 8, 0)
    label:SetPoint("RIGHT", ghost, "RIGHT", -8, 0)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(false)
    label:SetTextColor(0.92, 0.98, 1.00)
    ghost.label = label

    ghost:SetScript("OnUpdate", function(selfGhost)
        if not IsMouseButtonDown("LeftButton") then
            selfGhost:Hide()
            WBDraggingConcentrationSkillLineID = nil
            WBDraggingAltBoardCharacterKey = nil
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

    WBDragGhost = ghost
    return ghost
end

local function WBStartDragVisual(label, r, g, b)
    local ghost = WBEnsureDragGhost()
    ghost.label:SetText(label or "")
    ghost:SetBackdropBorderColor(r or 0.20, g or 0.78, b or 0.70, 0.95)
    ghost:Show()
end

WBRestoreDragTarget = function()
    if WBDragTarget and WBDragTarget.SetBackdropBorderColor then
        local c = WBDragTarget._dragBorderColor
        if c then
            WBDragTarget:SetBackdropBorderColor(c[1], c[2], c[3], c[4])
        end
    end
    WBDragTarget = nil
end

local function WBStopDragVisual()
    if WBDragGhost then
        WBDragGhost:Hide()
    end
    WBRestoreDragTarget()
end

local function WBMarkDragTarget(target)
    if WBDragTarget == target then
        return
    end
    WBRestoreDragTarget()
    WBDragTarget = target
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

    local function ResolveDropdownFontSize()
        if type(opts.fontSize) == "function" then
            return opts.fontSize() or 8
        end

        if type(opts.fontSize) == "number" then
            return opts.fontSize
        end

        return math.max(8, GetFontSize() - 1)
    end

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(opts.width or 150, opts.height or 18)
    btn.forAltBoard = forAltBoard
    btn:SetBackdrop(MakeBackdrop())
    btn:SetBackdropColor(0.05, 0.12, 0.20, 0.95)
    btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_ROWS, ResolveDropdownFontSize(), GetFontFlags())
    label:SetPoint("LEFT", btn, "LEFT", 8, 1)
    label:SetPoint("RIGHT", btn, "RIGHT", -20, 1)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.76, 0.97, 0.94)
    btn._label = label

    local caret = btn:CreateFontString(nil, "OVERLAY")
    caret:SetFont(FONT_HEADERS, math.max(9, ResolveDropdownFontSize() + 1), GetFontFlags())
    caret:SetPoint("RIGHT", btn, "RIGHT", -7, 1)
    caret:SetText("v")
    caret:SetTextColor(0.78, 0.90, 0.92)
    btn._caret = caret

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(50)
    popup:SetBackdrop(MakeBackdrop())
    popup:SetBackdropColor(0.04, 0.09, 0.15, 0.98)
    popup:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
    popup:Hide()
    popup.buttons = {}
    btn._popup = popup

    local dismiss = CreateFrame("Frame", nil, UIParent)
    dismiss:SetAllPoints(UIParent)
    dismiss:SetFrameStrata("DIALOG")
    dismiss:SetFrameLevel(49)
    dismiss:EnableMouse(true)
    dismiss:Hide()
    dismiss:SetScript("OnMouseDown", function()
        popup:Hide()
        dismiss:Hide()
    end)
    btn._dismiss = dismiss

    function btn:ApplyFonts()
        local labelSize = ResolveDropdownFontSize()
        local caretSize = math.max(9, labelSize + 1)
        local rowHeight = math.max(18, labelSize + 10)

        self:SetHeight(math.max(opts.height or 18, labelSize + 8))
        if self._label then
            self._label:SetFont(FONT_ROWS, labelSize, GetFontFlags())
        end
        if self._caret then
            self._caret:SetFont(FONT_HEADERS, caretSize, GetFontFlags())
        end

        for _, row in ipairs(popup.buttons) do
            if row._label then
                row._label:SetFont(FONT_ROWS, labelSize, GetFontFlags())
            end
            if row._check then
                row._check:SetFont(FONT_HEADERS, caretSize, GetFontFlags())
            end
            row:SetHeight(rowHeight)
        end
    end

    btn:SetScript("OnEnter", function(selfBtn)
        selfBtn:SetBackdropColor(0.08, 0.18, 0.28, 0.98)
        selfBtn:SetBackdropBorderColor(0.26, 0.78, 0.72, 1)
    end)
    btn:SetScript("OnLeave", function(selfBtn)
        selfBtn:SetBackdropColor(0.05, 0.12, 0.20, 0.95)
        selfBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
    end)

    function btn:Update()
        local expansions = MR:GetSelectableExpansions()
        self:ApplyFonts()
        if #expansions <= 1 then
            self:Hide()
            return
        end

        local current = MR:GetExpansionInfo(MR:GetSelectedExpansionKey(self.forAltBoard))
        self._label:SetText(current.shortLabel or current.label or current.key)
        self:Show()
    end

    local function EnsurePopupButton(index)
        local row = popup.buttons[index]
        if row then
            return row
        end

        row = CreateFrame("Button", nil, popup, "BackdropTemplate")
        row:SetHeight(18)
        row:SetBackdrop(MakeBackdrop())
        row:SetBackdropColor(0.05, 0.12, 0.20, 0.94)
        row:SetBackdropBorderColor(0.12, 0.26, 0.32, 0.95)

        row._label = row:CreateFontString(nil, "OVERLAY")
        row._label:SetFont(FONT_ROWS, ResolveDropdownFontSize(), GetFontFlags())
        row._label:SetPoint("LEFT", row, "LEFT", 8, 1)
        row._label:SetPoint("RIGHT", row, "RIGHT", -22, 1)
        row._label:SetJustifyH("LEFT")

        row._check = row:CreateFontString(nil, "OVERLAY")
        row._check:SetFont(FONT_HEADERS, math.max(9, ResolveDropdownFontSize() + 1), GetFontFlags())
        row._check:SetPoint("RIGHT", row, "RIGHT", -7, 1)

        row:SetScript("OnEnter", function(selfRow)
            selfRow:SetBackdropColor(0.08, 0.18, 0.28, 0.98)
            selfRow:SetBackdropBorderColor(0.26, 0.78, 0.72, 1)
        end)
        row:SetScript("OnLeave", function(selfRow)
            local active = selfRow._checked == true
            selfRow:SetBackdropColor(active and 0.10 or 0.05, active and 0.22 or 0.12, active and 0.30 or 0.20, active and 0.98 or 0.94)
            selfRow:SetBackdropBorderColor(active and 0.28 or 0.12, active and 0.86 or 0.26, active and 0.78 or 0.32, active and 1 or 0.95)
        end)

        popup.buttons[index] = row
        return row
    end

    btn:SetScript("OnClick", function(selfBtn)
        local expansions = MR:GetSelectableExpansions()
        if #expansions <= 1 then
            return
        end

        local selectedKey = MR:GetSelectedExpansionKey(selfBtn.forAltBoard)
        local rowWidth = math.max(selfBtn:GetWidth(), 130)
        local labelSize = ResolveDropdownFontSize()
        local rowHeight = math.max(18, labelSize + 10)
        selfBtn:ApplyFonts()
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", selfBtn, "BOTTOMLEFT", 0, -4)
        popup:SetSize(rowWidth, (#expansions * (rowHeight + 2)) + 6)

        for index, info in ipairs(expansions) do
            local row = EnsurePopupButton(index)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", popup, "TOPLEFT", 3, -3 - ((index - 1) * (rowHeight + 2)))
            row:SetSize(rowWidth - 6, rowHeight)
            row._checked = info.key == selectedKey
            row._label:SetText(info.shortLabel or info.label or info.key)
            row._label:SetTextColor(row._checked and 0.96 or 0.74, row._checked and 1.00 or 0.90, row._checked and 1.00 or 0.92)
            row._check:SetText(row._checked and "x" or "")
            row._check:SetTextColor(0.80, 0.94, 0.92)
            row:SetBackdropColor(row._checked and 0.10 or 0.05, row._checked and 0.22 or 0.12, row._checked and 0.30 or 0.20, row._checked and 0.98 or 0.94)
            row:SetBackdropBorderColor(row._checked and 0.28 or 0.12, row._checked and 0.86 or 0.26, row._checked and 0.78 or 0.32, row._checked and 1 or 0.95)
            row:SetScript("OnClick", function()
                MR:SetSelectedExpansionKey(info.key, selfBtn.forAltBoard)
                popup:Hide()
                dismiss:Hide()
            end)
            row:Show()
        end

        for index = #expansions + 1, #popup.buttons do
            popup.buttons[index]:Hide()
        end

        if popup:IsShown() then
            popup:Hide()
            dismiss:Hide()
        else
            dismiss:Show()
            popup:Show()
        end
    end)

    return btn
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
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint(topLeftAnchor[1], topLeftAnchor[2], topLeftAnchor[3], topLeftAnchor[4], topLeftAnchor[5])
    scroll:SetPoint(bottomRightAnchor[1], bottomRightAnchor[2], bottomRightAnchor[3], bottomRightAnchor[4], bottomRightAnchor[5])
    scroll:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)

    local track = CreateFrame("Frame", nil, parent)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 3, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 3, 0)
    track:SetWidth(5)

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0.00, 0.00, 0.00, 0.30)

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(5)
    thumb:EnableMouse(true)
    thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

    local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    thumbTex:SetColorTexture(0.24, 0.72, 0.72, 0.80)

    local function UpdateScrollBar()
        local viewH = scroll:GetHeight()
        local contentH = content:GetHeight()
        local maxScroll = math.max(contentH - viewH, 0)
        local currentScroll = scroll:GetVerticalScroll()

        if currentScroll > maxScroll then
            scroll:SetVerticalScroll(maxScroll)
            currentScroll = maxScroll
        elseif currentScroll < 0 then
            scroll:SetVerticalScroll(0)
            currentScroll = 0
        end

        if contentH <= viewH or viewH <= 0 then
            if currentScroll ~= 0 then
                scroll:SetVerticalScroll(0)
            end
            track:Hide()
            thumb:Hide()
            return
        end

        track:Show()
        thumb:Show()
        local trackH = math.max(track:GetHeight(), 1)
        local thumbH = math.max(trackH * (viewH / contentH), 18)
        local pct = currentScroll / math.max(maxScroll, 1)
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
    scroll:SetScript("OnVerticalScroll", function() UpdateScrollBar() end)

    return scroll, content, UpdateScrollBar, track
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

local function WBPopulateConcentrationOverview(frame, data)
    if not frame or not frame.overviewContent then
        return 0, 0
    end

    frame.overviewWidgets = frame.overviewWidgets or {}
    WBReleaseWidgets(frame.overviewWidgets)

    local contentWidth = math.max((frame.overviewScroll and frame.overviewScroll:GetWidth() or frame.rightPane:GetWidth() or 520) - 8, 320)
    frame.overviewContent:SetWidth(contentWidth)

    local totalCharacters = 0
    local totalProfessions = 0
    local yOff = 0
    frame.overviewContent._orderChips = {}
    frame.overviewContent:SetScript("OnUpdate", function(selfContent)
        if not WBDraggingConcentrationSkillLineID then
            return
        end
        if not IsMouseButtonDown("LeftButton") then
            WBUpdateDragTargetFromCursor(WBDraggingConcentrationSkillLineID, selfContent._orderChips, function(sourceID, targetID, afterTarget)
                if MR.SetAltBoardConcentrationProfessionPosition then
                    return MR:SetAltBoardConcentrationProfessionPosition(sourceID, targetID, afterTarget)
                end
                return false
            end)
            WBDraggingConcentrationSkillLineID = nil
            WBStopDragVisual()
            return
        end
        WBUpdateDragTargetFromCursor(WBDraggingConcentrationSkillLineID, selfContent._orderChips, function(sourceID, targetID, afterTarget)
            if MR.SetAltBoardConcentrationProfessionPosition then
                return MR:SetAltBoardConcentrationProfessionPosition(sourceID, targetID, afterTarget)
            end
            return false
        end)
    end)

    for _, charEntry in ipairs(data or {}) do
        local concentrationEntries = type(charEntry.concentration) == "table" and charEntry.concentration or nil
        if concentrationEntries and #concentrationEntries > 0 then
            totalCharacters = totalCharacters + 1
            totalProfessions = totalProfessions + #concentrationEntries

            local card = CreateFrame("Frame", nil, frame.overviewContent, "BackdropTemplate")
            card:SetPoint("TOPLEFT", frame.overviewContent, "TOPLEFT", 0, -yOff)
            card:SetWidth(contentWidth)
            card:SetBackdrop(MakeBackdrop())
            WBApplySurface(card, "soft", 0.96)

            local cr, cg, cb = WBClassColor(charEntry)
            WBAddSoftSheen(card, cr, cg, cb, 0.08)

            local topAccent = card:CreateTexture(nil, "ARTWORK")
            topAccent:SetPoint("TOPLEFT")
            topAccent:SetPoint("TOPRIGHT")
            topAccent:SetHeight(3)
            topAccent:SetColorTexture(cr, cg, cb, 1)

            local header = card:CreateFontString(nil, "OVERLAY")
            header:SetFont(FONT_HEADERS, math.max(11, GetFontSize() + 1), GetFontFlags())
            header:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -10)
            header:SetText(charEntry.isCurrent and (charEntry.name .. "  |cff7ce7d8" .. (L["AltBoard_Current"] or "Current") .. "|r") or charEntry.name)
            header:SetTextColor(0.94, 0.98, 1.00)

            local meta = card:CreateFontString(nil, "OVERLAY")
            meta:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
            meta:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -10)
            meta:SetJustifyH("RIGHT")
            meta:SetText(charEntry.realm ~= "" and charEntry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"))
            meta:SetTextColor(0.64, 0.72, 0.82)

            local rowY = 32
            for _, concentrationEntry in ipairs(concentrationEntries) do
                local rr, rg, rb = WBConcentrationColor(concentrationEntry)
                local current = WBConcentrationCurrent(concentrationEntry)
                local maxQuantity = tonumber(concentrationEntry.maxQuantity) or 0
                local projected = WBConcentrationProjectedQuantity(concentrationEntry, DAY_SECONDS)
                local dailyGain = math.max(0, projected - current)
                local fullInSeconds, fullAt = WBConcentrationTimeToFull(concentrationEntry)

                local row = CreateFrame("Frame", nil, card, "BackdropTemplate")
                row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -rowY)
                row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -rowY)
                row:SetHeight(54)
                row:SetBackdrop(MakeBackdrop(false))
                row:SetBackdropColor(0, 0, 0, 0)
                row:SetBackdropBorderColor(rr * 0.36, rg * 0.36, rb * 0.36, 0)
                row:EnableMouse(true)
                row.dragID = tonumber(concentrationEntry.skillLineID)
                row._dragBorderColor = { rr * 0.36, rg * 0.36, rb * 0.36, 0 }
                frame.overviewContent._orderChips[#frame.overviewContent._orderChips + 1] = row

                local label = row:CreateFontString(nil, "OVERLAY")
                label:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
                label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
                label:SetPoint("TOPRIGHT", row, "TOPRIGHT", -110, 0)
                label:SetJustifyH("LEFT")
                label:SetText(concentrationEntry.label or (L["Unknown"] or "Unknown"))
                label:SetTextColor(0.88, 0.92, 0.97)

                local value = row:CreateFontString(nil, "OVERLAY")
                value:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
                value:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
                value:SetJustifyH("RIGHT")
                value:SetText(maxQuantity > 0 and string.format("%d / %d", current, maxQuantity) or tostring(current))
                value:SetTextColor(rr, rg, rb)

                local barBg = CreateFrame("Frame", nil, row, "BackdropTemplate")
                barBg:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -18)
                barBg:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -18)
                barBg:SetHeight(8)
                barBg:SetBackdrop(MakeBackdrop(false))
                barBg:SetBackdropColor(0.08, 0.12, 0.18, 1)

                local projectedFill = barBg:CreateTexture(nil, "ARTWORK")
                projectedFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
                projectedFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
                projectedFill:SetColorTexture(rr, rg, rb, 0.22)

                local currentFill = barBg:CreateTexture(nil, "OVERLAY")
                currentFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
                currentFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
                currentFill:SetColorTexture(rr, rg, rb, 0.88)

                local barWidth = math.max(contentWidth - 24, 1)
                local currentPct = maxQuantity > 0 and math.min(1, current / maxQuantity) or 0
                local projectedPct = maxQuantity > 0 and math.min(1, projected / maxQuantity) or currentPct
                currentFill:SetWidth(barWidth * currentPct)
                projectedFill:SetWidth(barWidth * projectedPct)

                local gainText = row:CreateFontString(nil, "OVERLAY")
                gainText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                gainText:SetPoint("TOPLEFT", barBg, "BOTTOMLEFT", 0, -4)
                gainText:SetJustifyH("LEFT")
                gainText:SetText(string.format(L["AltBoard_ConcentrationProjected24h"] or "24h +%d", dailyGain))
                gainText:SetTextColor(0.68, 0.77, 0.86)

                local fullInText = row:CreateFontString(nil, "OVERLAY")
                fullInText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                fullInText:SetPoint("TOPRIGHT", barBg, "BOTTOMRIGHT", 0, -4)
                fullInText:SetJustifyH("RIGHT")
                if fullInSeconds == nil then
                    fullInText:SetText(L["AltBoard_AwaitingRefresh"] or "Awaiting refresh")
                elseif fullInSeconds <= 0 then
                    fullInText:SetText(L["AltBoard_ConcentrationFull"] or "Fully replenished")
                else
                    fullInText:SetText(string.format(L["AltBoard_ConcentrationFullIn"] or "Full in %s", WBFormatDurationShort(fullInSeconds)))
                end
                fullInText:SetTextColor(0.68, 0.77, 0.86)

                local fullAtText = row:CreateFontString(nil, "OVERLAY")
                fullAtText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                fullAtText:SetPoint("TOPLEFT", gainText, "BOTTOMLEFT", 0, -3)
                fullAtText:SetPoint("TOPRIGHT", fullInText, "BOTTOMRIGHT", 0, -3)
                fullAtText:SetJustifyH("RIGHT")
                if fullInSeconds == nil then
                    fullAtText:SetText("")
                elseif fullInSeconds <= 0 then
                    fullAtText:SetText(L["AltBoard_ConcentrationFullNow"] or "Full now")
                else
                    fullAtText:SetText(string.format(L["AltBoard_ConcentrationFullAt"] or "Full on %s", WBFormatConcentrationFullAt(fullAt)))
                end
                fullAtText:SetTextColor(0.52, 0.62, 0.72)

                row:SetScript("OnMouseDown", function(selfRow, button)
                    if button ~= "LeftButton" then
                        return
                    end
                    WBDraggingConcentrationSkillLineID = tonumber(concentrationEntry.skillLineID)
                    WBStartDragVisual(concentrationEntry.label or (L["Unknown"] or "Unknown"), rr, rg, rb)
                    selfRow._dragging = true
                    selfRow:SetBackdropColor(0.055 + rr * 0.040, 0.070 + rg * 0.040, 0.090 + rb * 0.040, 0.40)
                    selfRow:SetBackdropBorderColor(rr, rg, rb, 1)
                    GameTooltip:Hide()
                end)
                row:SetScript("OnMouseUp", function(selfRow, button)
                    if button == "LeftButton" then
                        WBDraggingConcentrationSkillLineID = nil
                        WBStopDragVisual()
                        selfRow._dragging = nil
                        selfRow:SetBackdropColor(0, 0, 0, 0)
                        selfRow:SetBackdropBorderColor(rr * 0.36, rg * 0.36, rb * 0.36, 0)
                    end
                end)
                row:SetScript("OnEnter", function(selfRow)
                    GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
                    GameTooltip:SetText(L["AltBoard_DragProfessionOrder"] or "Click and drag to reorder professions.", 1, 1, 1)
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                table.insert(frame.overviewWidgets, row)
                rowY = rowY + 62
            end

            card:SetHeight(rowY + 4)
            table.insert(frame.overviewWidgets, card)
            yOff = yOff + card:GetHeight() + 14
        end
    end

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
        if frame.overviewEmptyLabel then
            frame.overviewEmptyLabel:Hide()
        end
        frame.overviewContent:SetHeight(math.max(yOff, 1))
    end

    if frame.overviewScrollUpdate then
        frame.overviewScrollUpdate()
    end

    return totalCharacters, totalProfessions
end

local function WBRefreshMainAltPicker(frame)
    frame = frame or mainAltPickerFrame
    if not frame then
        return
    end

    RefreshFonts()
    frame:SetScale(MR.db and MR.db.profile and MR.db.profile.scale or 1)

    local data = MR:GetWarbandWeeklyData(false)
    local searchText = frame.characterSearchText or ""
    local listData = {}
    for _, entry in ipairs(data or {}) do
        if WBCharacterMatchesSearch(entry, searchText) then
            listData[#listData + 1] = entry
        end
    end

    local selectedKey = MR.GetMainAltViewCharacterKey and MR:GetMainAltViewCharacterKey() or nil
    local currentKey = MR.GetCurrentCharacterKey and MR:GetCurrentCharacterKey() or nil
    WBReleaseWidgets(frame.charButtons)
    frame.charButtons = frame.charButtons or {}

    if frame.titleText then
        frame.titleText:SetText(L["AltPicker_Title"] or "All Characters")
    end

    local currentRow = {
        key = currentKey,
        name = UnitName and UnitName("player") or (L["AltPicker_CurrentCharacter"] or "Current Character"),
        realm = GetRealmName and GetRealmName() or "",
        classFile = select(2, UnitClass("player")),
        isCurrent = true,
        stale = false,
        hidden = false,
        doneRows = 0,
        activeRows = 0,
        totalRows = 0,
    }

    local rows = { currentRow }
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
        local row = CreateFrame("Button", nil, frame.charRail, "BackdropTemplate")
        row:SetHeight(28)
        row:SetPoint("TOPLEFT", frame.charRail, "TOPLEFT", 0, -((index - 1) * 30))
        row:SetPoint("TOPRIGHT", frame.charRail, "TOPRIGHT", 0, -((index - 1) * 30))
        row:SetBackdrop(MakeBackdrop())

        local selectedRow = (entry.isCurrent and not selectedKey) or (selectedKey and selectedKey == entry.key)
        local cr, cg, cb = WBClassColor(entry)
        if selectedRow then
            row:SetBackdropColor(0.030, 0.058, 0.078, 0.98)
            row:SetBackdropBorderColor(0.16, 0.44, 0.48, 0.78)
        else
            row:SetBackdropColor(0.008, 0.014, 0.022, 0.36)
            row:SetBackdropBorderColor(0.04, 0.07, 0.10, 0.26)
        end

        local iconPlate = CreateFrame("Frame", nil, row, "BackdropTemplate")
        iconPlate:SetSize(16, 16)
        iconPlate:SetPoint("LEFT", row, "LEFT", 7, 0)
        iconPlate:SetBackdrop(MakeBackdrop())
        iconPlate:SetBackdropColor(0.004, 0.010, 0.016, 0.86)
        iconPlate:SetBackdropBorderColor(cr * 0.42, cg * 0.42, cb * 0.42, selectedRow and 0.84 or 0.58)

        local classIcon = iconPlate:CreateTexture(nil, "ARTWORK")
        classIcon:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
        classIcon:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
        classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        local coords = entry.classFile and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[entry.classFile] or nil
        if coords then
            classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        else
            iconPlate:Hide()
        end

        local name = row:CreateFontString(nil, "OVERLAY")
        name:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), GetFontFlags())
        name:SetPoint("LEFT", row, "LEFT", 29, 0)
        name:SetPoint("RIGHT", row, "RIGHT", -76, 0)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        name:SetText(entry.name)
        name:SetTextColor(cr, cg, cb)

        local realm = row:CreateFontString(nil, "OVERLAY")
        realm:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
        realm:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        realm:SetJustifyH("RIGHT")
        realm:SetText(entry.realm ~= "" and entry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"))
        realm:SetTextColor(0.68, 0.70, 0.74)

        row:SetScript("OnClick", function()
            if MR.SetMainAltViewCharacter then
                MR:SetMainAltViewCharacter(entry.isCurrent and nil or entry.key)
            end
            frame:Hide()
        end)
        row:SetScript("OnEnter", function(selfRow)
            if not selectedRow then
                selfRow:SetBackdropColor(0.020, 0.036, 0.052, 0.82)
                selfRow:SetBackdropBorderColor(0.10, 0.26, 0.32, 0.62)
            end
        end)
        row:SetScript("OnLeave", function(selfRow)
            if not selectedRow then
                selfRow:SetBackdropColor(0.008, 0.014, 0.022, 0.36)
                selfRow:SetBackdropBorderColor(0.04, 0.07, 0.10, 0.26)
            end
        end)

        table.insert(frame.charButtons, row)
    end

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
    title:SetFont(FONT_HEADERS, math.max(10, GetFontSize()), GetFontFlags())
    title:SetPoint("LEFT", titleBar, "LEFT", 8, 1)
    title:SetText(L["AltPicker_Title"] or "All Characters")
    title:SetTextColor(0.78, 0.96, 0.98)
    frame.titleText = title

    CloseButton(titleBar, function()
        frame:Hide()
    end)

    local countText = titleBar:CreateFontString(nil, "OVERLAY")
    countText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
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
    searchBox:SetFont(FONT_ROWS, math.max(9, GetFontSize() - 1), GetFontFlags())
    searchBox:SetTextColor(0.90, 0.95, 1.00)
    searchBox:SetJustifyH("LEFT")
    searchBox:SetBackdrop(MakeBackdrop())
    searchBox:SetBackdropColor(0.004, 0.010, 0.016, 0.98)
    searchBox:SetBackdropBorderColor(0.08, 0.22, 0.28, 0.78)
    searchBox:SetTextInsets(8, 24, 0, 0)

    local placeholder = searchBox:CreateFontString(nil, "OVERLAY")
    placeholder:SetFont(FONT_ROWS, math.max(9, GetFontSize() - 1), GetFontFlags())
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
    clearLabel:SetFont(FONT_HEADERS, 8, GetFontFlags())
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

local function WBPopulateConcentrationTracker(frame)
    if not frame or not frame.content then
        return
    end

    frame.widgets = frame.widgets or {}
    WBReleaseWidgets(frame.widgets)

    local data = MR:GetWarbandWeeklyData()
    local contentWidth = math.max((frame.scroll and frame.scroll:GetWidth() or frame:GetWidth() or 430) - 8, 300)
    local compact = WBIsConcentrationTrackerCompact()
    local totalCharacters = 0
    local totalProfessions = 0
    local hiddenCount = 0
    local yOff = 0

    frame.content:SetWidth(contentWidth)
    frame.content._orderChips = {}
    frame.content:SetScript("OnUpdate", function(selfContent)
        if not WBDraggingConcentrationSkillLineID then
            return
        end
        if not IsMouseButtonDown("LeftButton") then
            WBUpdateDragTargetFromCursor(WBDraggingConcentrationSkillLineID, selfContent._orderChips, function(sourceID, targetID, afterTarget)
                if MR.SetAltBoardConcentrationProfessionPosition then
                    return MR:SetAltBoardConcentrationProfessionPosition(sourceID, targetID, afterTarget)
                end
                return false
            end)
            WBDraggingConcentrationSkillLineID = nil
            WBStopDragVisual()
            return
        end
        WBUpdateDragTargetFromCursor(WBDraggingConcentrationSkillLineID, selfContent._orderChips, function(sourceID, targetID, afterTarget)
            if MR.SetAltBoardConcentrationProfessionPosition then
                return MR:SetAltBoardConcentrationProfessionPosition(sourceID, targetID, afterTarget)
            end
            return false
        end)
    end)

    for _, charEntry in ipairs(data or {}) do
        local concentrationEntries = type(charEntry.concentration) == "table" and charEntry.concentration or nil
        if concentrationEntries and #concentrationEntries > 0 and WBIsConcentrationTrackerCharacterHidden(charEntry.key) then
            hiddenCount = hiddenCount + 1
        elseif concentrationEntries and #concentrationEntries > 0 then
            totalCharacters = totalCharacters + 1
            totalProfessions = totalProfessions + #concentrationEntries

            local card = CreateFrame("Frame", nil, frame.content, "BackdropTemplate")
            card:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 0, -yOff)
            card:SetWidth(contentWidth)
            card:SetBackdrop(MakeBackdrop())
            WBApplySurface(card, "soft", 0.96 * WBGetConcentrationTrackerAlpha())
            card:SetBackdropBorderColor(0.08, 0.16, 0.24, 0.80 * WBGetConcentrationTrackerAlpha())

            local cr, cg, cb = WBClassColor(charEntry)
            local accent = card:CreateTexture(nil, "ARTWORK")
            accent:SetPoint("TOPLEFT")
            accent:SetPoint("BOTTOMLEFT")
            accent:SetWidth(3)
            accent:SetColorTexture(cr, cg, cb, 1)

            local name = card:CreateFontString(nil, "OVERLAY")
            name:SetFont(FONT_HEADERS, compact and math.max(9, GetFontSize()) or math.max(10, GetFontSize() + 1), GetFontFlags())
            name:SetPoint("TOPLEFT", card, "TOPLEFT", 12, compact and -7 or -10)
            name:SetPoint("TOPRIGHT", card, "TOPRIGHT", -110, -10)
            name:SetJustifyH("LEFT")
            name:SetText(charEntry.isCurrent and (charEntry.name .. "  |cff7ce7d8" .. (L["AltBoard_Current"] or "Current") .. "|r") or charEntry.name)
            name:SetTextColor(0.94, 0.98, 1.00)

            local realm = card:CreateFontString(nil, "OVERLAY")
            realm:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
            realm:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -11)
            realm:SetJustifyH("RIGHT")
            realm:SetText(charEntry.realm ~= "" and charEntry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"))
            realm:SetTextColor(0.62, 0.70, 0.80)

            local rowY = compact and 26 or 34
            for _, concentrationEntry in ipairs(concentrationEntries) do
                local rr, rg, rb = WBConcentrationColor(concentrationEntry)
                local current = WBConcentrationCurrent(concentrationEntry)
                local maxQuantity = tonumber(concentrationEntry.maxQuantity) or 0
                local projected = WBConcentrationProjectedQuantity(concentrationEntry, DAY_SECONDS)
                local dailyGain = math.max(0, projected - current)
                local fullInSeconds = WBConcentrationTimeToFull(concentrationEntry)

                local row = CreateFrame("Frame", nil, card, "BackdropTemplate")
                row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -rowY)
                row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -rowY)
                row:SetHeight(compact and 24 or 42)
                row:SetBackdrop(MakeBackdrop(false))
                row:SetBackdropColor(0, 0, 0, 0)
                row:SetBackdropBorderColor(rr * 0.36, rg * 0.36, rb * 0.36, 0)
                row:EnableMouse(true)
                row.dragID = tonumber(concentrationEntry.skillLineID)
                row._dragBorderColor = { rr * 0.36, rg * 0.36, rb * 0.36, 0 }
                frame.content._orderChips[#frame.content._orderChips + 1] = row

                local label = row:CreateFontString(nil, "OVERLAY")
                label:SetFont(FONT_ROWS, compact and math.max(8, GetFontSize() - 1) or math.max(9, GetFontSize()), GetFontFlags())
                label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
                label:SetPoint("TOPRIGHT", row, "TOPRIGHT", -105, 0)
                label:SetJustifyH("LEFT")
                label:SetText(concentrationEntry.label or (L["Unknown"] or "Unknown"))
                label:SetTextColor(0.86, 0.91, 0.97)

                local value = row:CreateFontString(nil, "OVERLAY")
                value:SetFont(FONT_HEADERS, compact and math.max(8, GetFontSize() - 1) or math.max(9, GetFontSize()), GetFontFlags())
                value:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
                value:SetJustifyH("RIGHT")
                value:SetText(maxQuantity > 0 and string.format("%d / %d", current, maxQuantity) or tostring(current))
                value:SetTextColor(rr, rg, rb)

                local barBg = CreateFrame("Frame", nil, row, "BackdropTemplate")
                barBg:SetPoint("TOPLEFT", row, "TOPLEFT", 0, compact and -15 or -18)
                barBg:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, compact and -15 or -18)
                barBg:SetHeight(compact and 4 or 7)
                barBg:SetBackdrop(MakeBackdrop(false))
                barBg:SetBackdropColor(0.08, 0.12, 0.18, 1)

                local projectedFill = barBg:CreateTexture(nil, "ARTWORK")
                projectedFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
                projectedFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
                projectedFill:SetColorTexture(rr, rg, rb, 0.22)

                local currentFill = barBg:CreateTexture(nil, "OVERLAY")
                currentFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
                currentFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
                currentFill:SetColorTexture(rr, rg, rb, 0.88)

                local barWidth = math.max(contentWidth - 24, 1)
                local currentPct = maxQuantity > 0 and math.min(1, current / maxQuantity) or 0
                local projectedPct = maxQuantity > 0 and math.min(1, projected / maxQuantity) or currentPct
                currentFill:SetWidth(barWidth * currentPct)
                projectedFill:SetWidth(barWidth * projectedPct)

                if not compact then
                    local gainText = row:CreateFontString(nil, "OVERLAY")
                    gainText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                    gainText:SetPoint("TOPLEFT", barBg, "BOTTOMLEFT", 0, -4)
                    gainText:SetJustifyH("LEFT")
                    gainText:SetText(string.format(L["AltBoard_ConcentrationProjected24h"] or "24h +%d", dailyGain))
                    gainText:SetTextColor(0.64, 0.74, 0.84)

                    local fullText = row:CreateFontString(nil, "OVERLAY")
                    fullText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
                    fullText:SetPoint("TOPRIGHT", barBg, "BOTTOMRIGHT", 0, -4)
                    fullText:SetJustifyH("RIGHT")
                    if fullInSeconds == nil then
                        fullText:SetText(L["AltBoard_AwaitingRefresh"] or "Awaiting refresh")
                    elseif fullInSeconds <= 0 then
                        fullText:SetText(L["AltBoard_ConcentrationFull"] or "Fully replenished")
                    else
                        fullText:SetText(string.format(L["AltBoard_ConcentrationFullIn"] or "Full in %s", WBFormatDurationShort(fullInSeconds)))
                    end
                    fullText:SetTextColor(0.64, 0.74, 0.84)
                end

                row:SetScript("OnMouseDown", function(selfRow, button)
                    if button ~= "LeftButton" then
                        return
                    end
                    WBDraggingConcentrationSkillLineID = tonumber(concentrationEntry.skillLineID)
                    WBStartDragVisual(concentrationEntry.label or (L["Unknown"] or "Unknown"), rr, rg, rb)
                    selfRow._dragging = true
                    selfRow:SetBackdropColor(0.055 + rr * 0.040, 0.070 + rg * 0.040, 0.090 + rb * 0.040, 0.40)
                    selfRow:SetBackdropBorderColor(rr, rg, rb, 1)
                    GameTooltip:Hide()
                end)
                row:SetScript("OnMouseUp", function(selfRow, button)
                    if button == "LeftButton" then
                        WBDraggingConcentrationSkillLineID = nil
                        WBStopDragVisual()
                        selfRow._dragging = nil
                        selfRow:SetBackdropColor(0, 0, 0, 0)
                        selfRow:SetBackdropBorderColor(rr * 0.36, rg * 0.36, rb * 0.36, 0)
                    end
                end)
                row:SetScript("OnEnter", function(selfRow)
                    GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
                    GameTooltip:SetText(L["AltBoard_DragProfessionOrder"] or "Click and drag to reorder professions.", 1, 1, 1)
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)

                table.insert(frame.widgets, row)
                rowY = rowY + (compact and 30 or 48)
            end

            card:SetHeight(rowY + (compact and 2 or 4))
            table.insert(frame.widgets, card)
            yOff = yOff + card:GetHeight() + (compact and 6 or 10)
        end
    end

    if frame.summary then
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

    if totalProfessions == 0 then
        if frame.emptyLabel then
            frame.emptyLabel:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 8, -6)
            frame.emptyLabel:SetPoint("TOPRIGHT", frame.content, "TOPRIGHT", -8, -6)
            frame.emptyLabel:SetText(L["AltBoard_ConcentrationNone"] or "No concentration data on tracked characters yet.")
            frame.emptyLabel:Show()
        end
        frame.content:SetHeight(42)
    else
        if frame.emptyLabel then
            frame.emptyLabel:Hide()
        end
        frame.content:SetHeight(math.max(yOff, 1))
    end

    if frame.scrollUpdate then
        frame.scrollUpdate()
    end
end

function MR:RefreshConcentrationTracker()
    if self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown() then
        WBPopulateConcentrationTracker(self.concentrationTrackerFrame)
    end
end

local function WBCreateHeaderButton(parent, icon, normalColor, hoverBg, hoverBorder, tooltipText, onClick)
    local size = icon.size or 18
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(size, size)
    btn:SetBackdrop(MakeBackdrop())
    btn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
    btn:SetBackdropBorderColor(0.18, 0.23, 0.30, 0.95)

    local iconObj
    if icon.tex then
        iconObj = btn:CreateTexture(nil, "OVERLAY")
        iconObj:SetSize(size - 4, size - 4)
        iconObj:SetPoint("CENTER", btn, "CENTER", 0, 0)
        iconObj:SetTexture(icon.tex)
        iconObj:SetVertexColor(normalColor[1], normalColor[2], normalColor[3])
        btn._isTexture = true
    else
        iconObj = btn:CreateFontString(nil, "OVERLAY")
        iconObj:SetFont(FONT_HEADERS, math.max(8, size - 7), GetFontFlags())
        iconObj:SetPoint("CENTER", btn, "CENTER", 0, 1)
        iconObj:SetText(icon.text)
        iconObj:SetTextColor(normalColor[1], normalColor[2], normalColor[3])
    end

    btn._iconObj = iconObj
    btn._normalColor = normalColor
    btn:SetScript("OnEnter", function(selfBtn)
        selfBtn:SetBackdropColor(hoverBg[1], hoverBg[2], hoverBg[3], 1)
        selfBtn:SetBackdropBorderColor(hoverBorder[1], hoverBorder[2], hoverBorder[3], 1)
        if selfBtn._isTexture then
            selfBtn._iconObj:SetVertexColor(1, 1, 1)
        else
            selfBtn._iconObj:SetTextColor(1, 1, 1)
        end
        if tooltipText then
            GameTooltip:SetOwner(selfBtn, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tooltipText, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function(selfBtn)
        selfBtn:SetBackdropColor(0.07, 0.09, 0.13, 0.96)
        selfBtn:SetBackdropBorderColor(0.18, 0.23, 0.30, 0.95)
        if selfBtn._isTexture then
            selfBtn._iconObj:SetVertexColor(normalColor[1], normalColor[2], normalColor[3])
        else
            selfBtn._iconObj:SetTextColor(normalColor[1], normalColor[2], normalColor[3])
        end
        GameTooltip:Hide()
    end)
    if onClick then
        btn:SetScript("OnClick", onClick)
    end

    return btn
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
    if frame.summary then frame.summary:SetShown(not minimized) end
    if frame.refreshBtn then frame.refreshBtn:SetShown(not minimized) end
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
        frame.content:SetWidth(math.max((frame.scroll and frame.scroll:GetWidth() or frame:GetWidth() or 430) - 8, 300))
    end
    if frame.scrollUpdate then
        frame.scrollUpdate()
    end
end

WBHideConcentrationTrackerOptions = function(frame)
    if concentrationTrackerConfigFrame then
        concentrationTrackerConfigFrame:Hide()
    end
end

function MR:ToggleConcentrationTracker()
    if self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown() then
        self:HideConcentrationTracker()
        return
    end

    if not self.concentrationTrackerFrame then
        local frame = StyledFrame(UIParent, nil, "DIALOG", 35)
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
        title:SetFont(FONT_HEADERS, math.max(8, GetFontSize() - 2), GetFontFlags())
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

        local summary = frame:CreateFontString(nil, "OVERLAY")
        summary:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        summary:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -36)
        summary:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -100, -36)
        summary:SetJustifyH("LEFT")
        summary:SetTextColor(0.64, 0.74, 0.84)

        local refreshBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        refreshBtn:SetSize(78, 20)
        refreshBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -32)
        refreshBtn:SetBackdrop(MakeBackdrop())
        refreshBtn:SetBackdropColor(0.05, 0.10, 0.18, 0.95)
        refreshBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
        refreshBtn._label = refreshBtn:CreateFontString(nil, "OVERLAY")
        refreshBtn._label:SetFont(FONT_ROWS, 9, GetFontFlags())
        refreshBtn._label:SetPoint("CENTER", refreshBtn, "CENTER", 0, 0)
        refreshBtn._label:SetText(L["CurrencyBrowser_Refresh"] or "Refresh")
        refreshBtn._label:SetTextColor(0.70, 0.88, 0.85)
        refreshBtn:SetScript("OnClick", function()
            if MR.RefreshPlayerProfessions then
                MR:RefreshPlayerProfessions()
            end
            if MR.RefreshProfessionConcentration then
                MR:RefreshProfessionConcentration()
            end
            WBPopulateConcentrationTracker(frame)
        end)
        refreshBtn:SetScript("OnEnter", function(selfBtn)
            selfBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
            selfBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
            selfBtn._label:SetTextColor(1, 1, 1)
        end)
        refreshBtn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(0.05, 0.10, 0.18, 0.95)
            selfBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
            selfBtn._label:SetTextColor(0.70, 0.88, 0.85)
        end)

        local scroll, content, scrollUpdate, scrollTrack = WBCreateScrollArea(
            frame,
            { "TOPLEFT", frame, "TOPLEFT", 14, -62 },
            { "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 14 }
        )
        content:SetSize(400, 1)

        local emptyLabel = content:CreateFontString(nil, "OVERLAY")
        emptyLabel:SetFont(FONT_ROWS, math.max(9, GetFontSize()), GetFontFlags())
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
            frame:SetSize(
                math.max(320, math.min(700, dragStartW + dx)),
                math.max(260, math.min(800, dragStartH + dy))
            )
            if frame.content then
                frame.content:SetWidth(math.max((frame.scroll and frame.scroll:GetWidth() or frame:GetWidth() or 430) - 8, 300))
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

local function ReleaseConcentrationTrackerConfigBody(frame)
    if frame and frame.body then
        if MR.ReleaseFrameTree then
            MR:ReleaseFrameTree(frame.body)
        else
            frame.body:EnableMouse(false)
            frame.body:Hide()
            frame.body:SetParent(nil)
        end
        frame.body = nil
    end
end

function MR:BuildConcentrationTrackerConfigFrame()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetWidth(300)
    f:SetFrameStrata("HIGH")
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
    title:SetFont(FONT_HEADERS, 10, GetFontFlags())
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

    RefreshFonts()
    local keepLeft, keepTop
    if f.IsShown and f:IsShown() and self.CaptureFrameScreenPosition then
        keepLeft, keepTop = self:CaptureFrameScreenPosition(f)
    end

    ReleaseConcentrationTrackerConfigBody(f)

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
        empty:SetFont(FONT_ROWS, math.max(8, cfgFs - 1), GetFontFlags())
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
    if concentrationTrackerConfigFrame and concentrationTrackerConfigFrame:IsShown() then
        concentrationTrackerConfigFrame:Hide()
        return
    end

    if not concentrationTrackerConfigFrame then
        concentrationTrackerConfigFrame = self:BuildConcentrationTrackerConfigFrame()
    end

    self:PopulateConcentrationTrackerConfigFrame(concentrationTrackerConfigFrame)
    concentrationTrackerConfigFrame:ClearAllPoints()
    if self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown() then
        concentrationTrackerConfigFrame:SetPoint("TOPLEFT", self.concentrationTrackerFrame, "TOPRIGHT", 4, 0)
    else
        concentrationTrackerConfigFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    concentrationTrackerConfigFrame:Show()
    if self.CaptureFrameScreenPosition and self.RestoreFrameScreenPosition then
        local left, top = self:CaptureFrameScreenPosition(concentrationTrackerConfigFrame)
        self:RestoreFrameScreenPosition(concentrationTrackerConfigFrame, left, top)
    end
end

function MR:RefreshWarbandBoard()
    local frame = self.altBoardFrame
    if not frame then return end
    self._warbandBoardLastRefreshAt = GetTime and GetTime() or 0
    frame:SetScale(self.db.profile.scale or 1)
    if self.RefreshConcentrationTracker then
        self:RefreshConcentrationTracker()
    end
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
        frame.summarySub:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -52)
    end
    if frame.leftPane then
        frame.leftPane:ClearAllPoints()
        frame.leftPane:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -76)
        frame.leftPane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
        frame.leftPane:SetWidth(238)
    end

    local data = self:GetWarbandWeeklyData()
    frame._data = data
    local searchText = frame.characterSearchText or ""
    local listData = {}
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

    WBReleaseWidgets(frame.charButtons)
    WBReleaseWidgets(frame.detailWidgets)
    frame.charRail._characterDragRows = {}
    frame.charRail:SetScript("OnUpdate", function(selfRail)
        if not WBDraggingAltBoardCharacterKey then
            return
        end
        if not IsMouseButtonDown("LeftButton") then
            WBUpdateDragTargetFromCursor(WBDraggingAltBoardCharacterKey, selfRail._characterDragRows, function(sourceKey, targetKey, afterTarget)
                if MR.SetAltBoardCharacterPosition then
                    return MR:SetAltBoardCharacterPosition(sourceKey, targetKey, afterTarget)
                end
                return false
            end)
            WBDraggingAltBoardCharacterKey = nil
            WBStopDragVisual()
            return
        end
        WBUpdateDragTargetFromCursor(WBDraggingAltBoardCharacterKey, selfRail._characterDragRows, function(sourceKey, targetKey, afterTarget)
            if MR.SetAltBoardCharacterPosition then
                return MR:SetAltBoardCharacterPosition(sourceKey, targetKey, afterTarget)
            end
            return false
        end)
    end)

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
        WBReleaseWidgets(frame.heroConcentrationWidgets)
        WBReleaseWidgets(frame.overviewWidgets)
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
        local btn = CreateFrame("Button", nil, frame.charRail, "BackdropTemplate")
        btn:SetSize(216, 66)
        btn:SetPoint("TOPLEFT", frame.charRail, "TOPLEFT", 0, -((index - 1) * 72))
        btn:SetBackdrop(MakeBackdrop())

        local isSelected = (selected.key == entry.key)
        local sr, sg, sb = WBClassColor(entry)
        if isSelected then
            btn:SetBackdropColor(0.034 + sr * 0.035, 0.050 + sg * 0.035, 0.070 + sb * 0.035, 0.98)
            btn:SetBackdropBorderColor(sr * 0.52, sg * 0.52, sb * 0.52, 0.90)
        else
            btn:SetBackdropColor(0.018, 0.032, 0.052, 0.90)
            btn:SetBackdropBorderColor(0.07, 0.12, 0.18, 0.56)
        end

        WBAddSoftSheen(btn, sr, sg, sb, isSelected and 0.10 or 0.025)

        local accent = btn:CreateTexture(nil, "ARTWORK")
        accent:SetPoint("TOPLEFT")
        accent:SetPoint("BOTTOMLEFT")
        accent:SetWidth(isSelected and 3 or 2)
        accent:SetColorTexture(sr, sg, sb, isSelected and 0.92 or 0.62)

        local progressBg = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
        progressBg:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 12, 8)
        progressBg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -34, 8)
        progressBg:SetHeight(3)
        progressBg:SetColorTexture(0.07, 0.09, 0.12, 0.82)

        local progressFill = btn:CreateTexture(nil, "ARTWORK")
        progressFill:SetPoint("LEFT", progressBg, "LEFT", 0, 0)
        progressFill:SetHeight(3)
        local pr, pg, pb = countColor(entry.doneRows, math.max(entry.totalRows, 1))
        progressFill:SetColorTexture(pr, pg, pb, 0.92)
        progressFill:SetWidth(math.max(1, (((btn:GetWidth() or 216) - 46) * math.min(1, entry.doneRows / math.max(entry.totalRows, 1)))))

        local name = btn:CreateFontString(nil, "OVERLAY")
        name:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
        name:SetPoint("TOPLEFT", btn, "TOPLEFT", 13, -8)
        name:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -34, -7)
        name:SetJustifyH("LEFT")
        name:SetText(entry.isCurrent and (entry.name .. "  |cff7ce7d8" .. (L["AltBoard_Current"] or "Current") .. "|r") or entry.name)

        local meta = btn:CreateFontString(nil, "OVERLAY")
        meta:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        meta:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
        meta:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -34, -3)
        meta:SetJustifyH("LEFT")
        local metaText = string.format("%s  |  %d/%d", entry.realm ~= "" and entry.realm or (L["AltBoard_UnknownRealm"] or "Unknown Realm"), entry.doneRows, entry.totalRows)
        meta:SetText(metaText)
        meta:SetTextColor(0.62, 0.70, 0.80)

        local note = btn:CreateFontString(nil, "OVERLAY")
        note:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
        note:SetPoint("TOPLEFT", meta, "BOTTOMLEFT", 0, -2)
        note:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -34, -3)
        note:SetJustifyH("LEFT")
        if entry.note and entry.note ~= "" then
            note:SetText(entry.note)
            note:SetTextColor(0.78, 0.86, 0.86)
        else
            note:SetText("")
        end

        local hideBtn = CreateFrame("Button", nil, btn, "BackdropTemplate")
        hideBtn:SetSize(16, 16)
        hideBtn:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -8, -8)
        hideBtn:SetBackdrop(MakeBackdrop())
        hideBtn:SetBackdropColor(0.035, 0.060, 0.090, 0.88)
        hideBtn:SetBackdropBorderColor(0.12, 0.20, 0.26, 0.72)

        local hideLabel = hideBtn:CreateFontString(nil, "OVERLAY")
        hideLabel:SetFont(FONT_HEADERS, 10, GetFontFlags())
        hideLabel:SetPoint("CENTER", hideBtn, "CENTER", 0, 1)
        hideLabel:SetText(entry.hidden and "+" or "x")
        hideLabel:SetTextColor(0.78, 0.88, 0.92)

        hideBtn:SetScript("OnClick", function()
            local makeHidden = not entry.hidden
            MR:SetAltBoardCharacterHidden(entry.key, makeHidden)
            if makeHidden and frame.selectedCharKey == entry.key then
                frame.selectedCharKey = nil
            end
            MR:RefreshWarbandBoard()
        end)
        hideBtn:SetScript("OnEnter", function(selfBtn)
            if entry.hidden then
                selfBtn:SetBackdropColor(0.08, 0.18, 0.10, 0.95)
                selfBtn:SetBackdropBorderColor(0.30, 0.90, 0.42, 1)
            else
                selfBtn:SetBackdropColor(0.18, 0.08, 0.08, 0.95)
                selfBtn:SetBackdropBorderColor(0.90, 0.30, 0.30, 1)
            end
            hideLabel:SetTextColor(1, 1, 1)
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:SetText(entry.hidden and (L["AltBoard_ShowCharacter"] or "Show on Alt Weekly Board") or (L["AltBoard_HideCharacter"] or "Hide from Alt Weekly Board"), 1, 1, 1)
            GameTooltip:Show()
        end)
        hideBtn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(0.035, 0.060, 0.090, 0.88)
            selfBtn:SetBackdropBorderColor(0.12, 0.20, 0.26, 0.72)
            hideLabel:SetTextColor(0.78, 0.88, 0.92)
            GameTooltip:Hide()
        end)

        btn.dragID = entry.key
        btn._dragBorderColor = isSelected
            and { sr * 0.52, sg * 0.52, sb * 0.52, 0.90 }
            or { 0.07, 0.12, 0.18, 0.56 }
        frame.charRail._characterDragRows[#frame.charRail._characterDragRows + 1] = btn

        btn:SetScript("OnClick", function()
            frame.selectedCharKey = entry.key
            MR:RefreshWarbandBoard()
        end)
        btn:SetScript("OnMouseDown", function(selfBtn, button)
            if button ~= "LeftButton" then
                return
            end
            WBDraggingAltBoardCharacterKey = entry.key
            WBStartDragVisual(entry.name, sr, sg, sb)
            selfBtn:SetBackdropBorderColor(sr, sg, sb, 1)
            GameTooltip:Hide()
        end)
        btn:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then
                WBDraggingAltBoardCharacterKey = nil
                WBStopDragVisual()
            end
        end)
        btn:SetScript("OnEnter", function(selfBtn)
            if not isSelected then
                selfBtn:SetBackdropColor(0.026, 0.046, 0.072, 0.96)
                selfBtn:SetBackdropBorderColor(sr * 0.42, sg * 0.42, sb * 0.42, 0.86)
            end
            GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["AltBoard_DragCharacterOrder"] or "Click and drag to reorder characters.", 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(selfBtn)
            if not isSelected then
                selfBtn:SetBackdropColor(0.018, 0.032, 0.052, 0.90)
                selfBtn:SetBackdropBorderColor(0.07, 0.12, 0.18, 0.56)
            end
            GameTooltip:Hide()
        end)

        table.insert(frame.charButtons, btn)
    end

    frame.charRail:SetHeight(math.max(#listData * 72, 1))
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

    WBReleaseWidgets(frame.overviewWidgets)
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

    WBReleaseWidgets(frame.heroConcentrationWidgets)
    frame.heroConcentrationWidgets = frame.heroConcentrationWidgets or {}

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
        frame.concentrationPane._orderChips = {}
        frame.concentrationPane:SetScript("OnUpdate", function(selfPane)
            if not WBDraggingConcentrationSkillLineID then
                return
            end
            if not IsMouseButtonDown("LeftButton") then
                WBUpdateDragTargetFromCursor(WBDraggingConcentrationSkillLineID, selfPane._orderChips, function(sourceID, targetID, afterTarget)
                    if MR.SetAltBoardConcentrationProfessionPosition then
                        return MR:SetAltBoardConcentrationProfessionPosition(sourceID, targetID, afterTarget)
                    end
                    return false
                end, "horizontal")
                WBDraggingConcentrationSkillLineID = nil
                WBStopDragVisual()
                return
            end
            WBUpdateDragTargetFromCursor(WBDraggingConcentrationSkillLineID, selfPane._orderChips, function(sourceID, targetID, afterTarget)
                if MR.SetAltBoardConcentrationProfessionPosition then
                    return MR:SetAltBoardConcentrationProfessionPosition(sourceID, targetID, afterTarget)
                end
                return false
            end, "horizontal")
        end)

        for index, concentrationEntry in ipairs(concentrationEntries) do
            local rr, rg, rb = WBConcentrationColor(concentrationEntry)
            local labelText = concentrationEntry.label or (L["Unknown"] or "Unknown")
            local valueText = WBConcentrationText(concentrationEntry)
            local col = (index - 1) % columns
            local row = math.floor((index - 1) / columns)
            local xOffset = 14 + (col * (chipWidth + gap))
            local yOffset = -34 - (row * (rowHeight + gap))

            local chip = CreateFrame("Frame", nil, frame.concentrationPane, "BackdropTemplate")
            chip:SetSize(chipWidth, rowHeight)
            chip:SetPoint("TOPLEFT", frame.concentrationPane, "TOPLEFT", xOffset, yOffset)
            chip:SetBackdrop(MakeBackdrop())
            chip:SetBackdropColor(0.018 + rr * 0.045, 0.030 + rg * 0.045, 0.046 + rb * 0.045, 0.92)
            chip:SetBackdropBorderColor(rr * 0.42, rg * 0.42, rb * 0.42, 0.72)
            chip:EnableMouse(true)
            chip.skillLineID = tonumber(concentrationEntry.skillLineID)
            chip.dragID = tonumber(concentrationEntry.skillLineID)
            chip._dragBorderColor = { rr * 0.42, rg * 0.42, rb * 0.42, 0.72 }
            frame.concentrationPane._orderChips[#frame.concentrationPane._orderChips + 1] = chip

            local chipGlow = chip:CreateTexture(nil, "BACKGROUND")
            chipGlow:SetAllPoints()
            chipGlow:SetTexture("Interface\\Buttons\\WHITE8X8")
            chipGlow:SetColorTexture(rr, rg, rb, 0.04)

            local dot = chip:CreateTexture(nil, "ARTWORK")
            dot:SetSize(4, 14)
            dot:SetPoint("LEFT", chip, "LEFT", 8, 0)
            dot:SetColorTexture(rr, rg, rb, 1)

            local label = chip:CreateFontString(nil, "OVERLAY")
            label:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
            label:SetPoint("LEFT", dot, "RIGHT", 6, 0)
            label:SetPoint("RIGHT", chip, "RIGHT", -68, 0)
            label:SetJustifyH("LEFT")
            label:SetText(labelText)
            label:SetTextColor(0.84, 0.89, 0.96)

            local value = chip:CreateFontString(nil, "OVERLAY")
            value:SetFont(FONT_HEADERS, math.max(9, GetFontSize() - 1), GetFontFlags())
            value:SetPoint("RIGHT", chip, "RIGHT", -8, 0)
            value:SetWidth(52)
            value:SetJustifyH("RIGHT")
            value:SetText(valueText)
            value:SetTextColor(0.97, 0.98, 1.00)

            chip:SetScript("OnMouseDown", function(selfChip, button)
                if button ~= "LeftButton" then
                    return
                end
                WBDraggingConcentrationSkillLineID = tonumber(concentrationEntry.skillLineID)
                WBStartDragVisual(labelText, rr, rg, rb)
                selfChip:SetBackdropColor(0.055 + rr * 0.050, 0.075 + rg * 0.050, 0.095 + rb * 0.050, 0.98)
                selfChip:SetBackdropBorderColor(rr, rg, rb, 1)
                GameTooltip:Hide()
            end)
            chip:SetScript("OnMouseUp", function(selfChip, button)
                if button == "LeftButton" then
                    WBDraggingConcentrationSkillLineID = nil
                    WBStopDragVisual()
                    selfChip:SetBackdropColor(0.018 + rr * 0.045, 0.030 + rg * 0.045, 0.046 + rb * 0.045, 0.92)
                    selfChip:SetBackdropBorderColor(rr * 0.42, rg * 0.42, rb * 0.42, 0.72)
                end
            end)
            chip:SetScript("OnEnter", function(selfChip)
                selfChip:SetBackdropBorderColor(rr * 0.64, rg * 0.64, rb * 0.64, 0.90)
                GameTooltip:SetOwner(selfChip, "ANCHOR_RIGHT")
                GameTooltip:SetText(L["AltBoard_DragProfessionOrder"] or "Click and drag to reorder professions.", 1, 1, 1)
                GameTooltip:Show()
            end)
            chip:SetScript("OnLeave", function(selfChip)
                if tonumber(WBDraggingConcentrationSkillLineID) ~= tonumber(concentrationEntry.skillLineID) then
                    selfChip:SetBackdropColor(0.018 + rr * 0.045, 0.030 + rg * 0.045, 0.046 + rb * 0.045, 0.92)
                    selfChip:SetBackdropBorderColor(rr * 0.42, rg * 0.42, rb * 0.42, 0.72)
                end
                GameTooltip:Hide()
            end)

            table.insert(frame.heroConcentrationWidgets, chip)
        end

        concentrationHeight = 34 + (usedRows * rowHeight) + (math.max(0, usedRows - 1) * gap) + 10
    else
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

    local orderIndex = {}
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

    local hideCompletedRows = WBShouldHideCompletedCharacters()

    for _, moduleEntry in ipairs(selected.modules) do
        local visibleRows = {}
        for _, rowEntry in ipairs(moduleEntry.rows) do
            if not (hideCompletedRows and rowEntry.complete) then
                table.insert(visibleRows, rowEntry)
            end
        end

        if not (hideCompletedRows and #visibleRows == 0) then
        local card = CreateFrame("Frame", nil, frame.detailContent, "BackdropTemplate")
        card:SetPoint("TOPLEFT", frame.detailContent, "TOPLEFT", 0, -yOff)
        card:SetSize(1, 1)
        card:SetWidth(detailWidth)
        card:SetBackdrop(MakeBackdrop())
        WBApplySurface(card, "soft", 0.92)

        local mr, mg, mb = WBHexColor(moduleEntry.color, 1, 1, 1)
        local collapsedModules = (MR.db and MR.db.profile and MR.db.profile.altBoardCollapsedModules) or {}
        local isCollapsed = collapsedModules[moduleEntry.key] == true
        WBAddSoftSheen(card, mr, mg, mb, 0.035)

        local topAccent = card:CreateTexture(nil, "ARTWORK")
        topAccent:SetPoint("TOPLEFT")
        topAccent:SetPoint("TOPRIGHT")
        topAccent:SetHeight(2)
        topAccent:SetColorTexture(mr, mg, mb, 0.92)

        local headerBtn = CreateFrame("Button", nil, card)
        headerBtn:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
        headerBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
        headerBtn:SetHeight(36)

        local headerHover = headerBtn:CreateTexture(nil, "BACKGROUND")
        headerHover:SetAllPoints()
        headerHover:SetColorTexture(1, 1, 1, 0)

        local arrow = headerBtn:CreateFontString(nil, "OVERLAY")
        arrow:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
        arrow:SetPoint("TOPLEFT", headerBtn, "TOPLEFT", 13, -10)
        arrow:SetText(isCollapsed and "+" or "-")
        arrow:SetTextColor(0.62, 0.72, 0.78)

        local title = headerBtn:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
        title:SetPoint("TOPLEFT", arrow, "TOPRIGHT", 8, 0)
        title:SetPoint("RIGHT", headerBtn, "RIGHT", -120, 0)
        title:SetJustifyH("LEFT")
        title:SetText(moduleEntry.label)
        title:SetTextColor(math.min(1, mr + 0.08), math.min(1, mg + 0.08), math.min(1, mb + 0.08))

        local progress = card:CreateFontString(nil, "OVERLAY")
        progress:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        progress:SetPoint("TOPRIGHT", card, "TOPRIGHT", -14, -10)
        progress:SetText(string.format("%d / %d", moduleEntry.doneRows, moduleEntry.totalRows))
        local pr, pg, pb = countColor(moduleEntry.doneRows, math.max(moduleEntry.totalRows, 1))
        progress:SetTextColor(pr, pg, pb)

        local progressTrack = card:CreateTexture(nil, "BACKGROUND", nil, 1)
        progressTrack:SetPoint("TOPLEFT", card, "TOPLEFT", 13, -30)
        progressTrack:SetPoint("TOPRIGHT", card, "TOPRIGHT", -13, -30)
        progressTrack:SetHeight(2)
        progressTrack:SetColorTexture(0.08, 0.10, 0.14, 0.72)

        local progressFill = card:CreateTexture(nil, "ARTWORK")
        progressFill:SetPoint("LEFT", progressTrack, "LEFT", 0, 0)
        progressFill:SetHeight(2)
        progressFill:SetColorTexture(pr, pg, pb, 0.92)
        progressFill:SetWidth(math.max(1, (detailWidth - 26) * math.min(1, moduleEntry.doneRows / math.max(moduleEntry.totalRows, 1))))

        headerBtn:SetScript("OnClick", function()
            if not MR.db.profile.altBoardCollapsedModules then
                MR.db.profile.altBoardCollapsedModules = {}
            end
            MR.db.profile.altBoardCollapsedModules[moduleEntry.key] = not isCollapsed or nil
            MR:RefreshWarbandBoard()
        end)
        headerBtn:SetScript("OnEnter", function()
            headerHover:SetColorTexture(1, 1, 1, 0.025)
        end)
        headerBtn:SetScript("OnLeave", function()
            headerHover:SetColorTexture(1, 1, 1, 0)
        end)

        local moduleY = 42
        if not isCollapsed then
            for rowIndex, rowEntry in ipairs(visibleRows) do
                local row = CreateFrame("Frame", nil, card)
                row:SetPoint("TOPLEFT", card, "TOPLEFT", 11, -moduleY)
                row:SetPoint("TOPRIGHT", card, "TOPRIGHT", -11, -moduleY)
                row:SetHeight(23)

                if rowIndex % 2 == 0 then
                    local rowBg = row:CreateTexture(nil, "BACKGROUND")
                    rowBg:SetAllPoints()
                    rowBg:SetColorTexture(1, 1, 1, 0.018)
                end

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

                local dot = row:CreateTexture(nil, "ARTWORK")
                dot:SetSize(4, 13)
                dot:SetPoint("LEFT", row, "LEFT", 2, 0)
                dot:SetColorTexture(rr, rg, rb, 0.92)

                local label = row:CreateFontString(nil, "OVERLAY")
                label:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
                label:SetPoint("LEFT", row, "LEFT", 16, 0)
                label:SetPoint("RIGHT", row, "RIGHT", -120, 0)
                label:SetJustifyH("LEFT")
                label:SetText(rowEntry.label)
                label:SetTextColor(0.84, 0.88, 0.93)

                local value = row:CreateFontString(nil, "OVERLAY")
                value:SetFont(FONT_ROWS, GetFontSize(), GetFontFlags())
                value:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                value:SetJustifyH("RIGHT")
                value:SetText(selected.stale and (L["AltBoard_AwaitingRefresh"] or "Awaiting refresh") or rowEntry.displayValue)
                value:SetTextColor(rr, rg, rb)

                if rowEntry.accentLabel then
                    local accent = row:CreateFontString(nil, "OVERLAY")
                    accent:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
                    accent:SetPoint("RIGHT", value, "LEFT", -8, 0)
                    accent:SetJustifyH("RIGHT")
                    accent:SetText(WBClean(rowEntry.accentLabel))
                    accent:SetTextColor(WBHexColor(rowEntry.accentColor, 0.78, 0.82, 0.95))
                end

                row:EnableMouse(true)
                row:SetScript("OnEnter", function(selfRow)
                    GameTooltip:SetOwner(selfRow, "ANCHOR_RIGHT")
                    if rowEntry.currencyId and not rowEntry.noBlizzardTooltip then
                        GameTooltip:SetCurrencyByID(rowEntry.currencyId)
                        if rowEntry.trackWeeklyEarned then
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddLine(string.format("Collected this week: %s", rowEntry.displayValue), 0.72, 0.86, 1, true)
                            GameTooltip:AddLine(string.format("Currently held: %d", rowEntry.wallet or 0), 0.72, 0.86, 1, true)
                        else
                            GameTooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
                        end
                    else
                        GameTooltip:SetText(rowEntry.label, 1, 1, 1, 1, true)
                    end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function(selfRow)
                    if GameTooltip:GetOwner() == selfRow then GameTooltip:Hide() end
                end)

                table.insert(frame.detailWidgets, row)
                moduleY = moduleY + 24
            end
        end

        card:SetHeight(moduleY + 8)
        table.insert(frame.detailWidgets, card)
        yOff = yOff + moduleY + 18
        end
    end

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

        local titleBar = TitleBar(frame, 42)
        titleBar:SetBackdropColor(0.018, 0.038, 0.066, 1)
        titleBar:SetScript("OnDragStart", function()
            frame:StartMoving()
        end)
        titleBar:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
            local pt, _, rp, x, y = frame:GetPoint()
            SetWindowLayoutValue("warbandBoardPosition", { point = pt, relPoint = rp, x = x, y = y })
        end)
        local title = titleBar:CreateFontString(nil, "OVERLAY")
        title:SetFont(FONT_HEADERS, math.max(14, GetFontSize() + 3), GetFontFlags())
        title:SetPoint("LEFT", titleBar, "LEFT", 14, 1)
        title:SetPoint("RIGHT", titleBar, "RIGHT", -150, 0)
        title:SetJustifyH("LEFT")
        title:SetText(L["AltBoard_Title"] or "Alt Weekly Board")
        title:SetTextColor(0.90, 0.95, 1.0)

        local summaryValue = titleBar:CreateFontString(nil, "OVERLAY")
        summaryValue:SetFont(FONT_HEADERS, math.max(11, GetFontSize() + 1), GetFontFlags())
        summaryValue:SetPoint("RIGHT", titleBar, "RIGHT", -58, 1)
        summaryValue:SetText("0 / 0")

        local summarySub = frame:CreateFontString(nil, "OVERLAY")
        summarySub:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        summarySub:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -52)
        summarySub:SetTextColor(0.58, 0.67, 0.76)
        summarySub:SetText("")

        CloseButton(titleBar, function() frame:Hide() end)

        local expansionDropdown = BuildExpansionDropdown(frame, true, {
            width = 160,
            height = 18,
        })
        expansionDropdown:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -42, -48)

        local leftPane = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        leftPane:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -76)
        leftPane:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 14)
        leftPane:SetWidth(238)
        leftPane:SetBackdrop(MakeBackdrop())
        WBApplySurface(leftPane, "panel")
        WBAddSoftSheen(leftPane, 0.10, 0.18, 0.24, 0.04)

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
        WBAddSoftSheen(rightPane, 0.08, 0.14, 0.20, 0.04)

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
            GameTooltip:SetOwner(selfBox, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["AltBoard_NoteTooltip"] or "Add a short note or tag for this character.", 1, 1, 1)
            GameTooltip:Show()
        end)
        heroNoteBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
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
        frame.detailWidgets = {}
        frame.overviewWidgets = {}
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
    if mainAltPickerFrame and mainAltPickerFrame:IsShown() then
        mainAltPickerFrame:Hide()
        return
    end

    if not mainAltPickerFrame then
        mainAltPickerFrame = WBBuildMainAltPicker()
    end

    if MR._characterBar then
        mainAltPickerFrame:SetWidth(math.max(220, MR._characterBar:GetWidth() or 220))
    end
    mainAltPickerFrame:ClearAllPoints()
    if MR._characterBar then
        if ns.GetMainHeaderPosition and ns.GetMainHeaderPosition() == "bottom" then
            mainAltPickerFrame:SetPoint("BOTTOMLEFT", MR._characterBar, "TOPLEFT", 0, 2)
        else
            mainAltPickerFrame:SetPoint("TOPLEFT", MR._characterBar, "BOTTOMLEFT", 0, -2)
        end
    elseif MR.frame then
        mainAltPickerFrame:SetPoint("TOPLEFT", MR.frame, "BOTTOMLEFT", 0, -2)
    else
        mainAltPickerFrame:SetPoint("CENTER", UIParent, "CENTER", -120, 0)
    end
    mainAltPickerFrame:Show()
    WBRefreshMainAltPicker(mainAltPickerFrame)
end

function MR:HideMainAltPicker()
    if mainAltPickerFrame then
        mainAltPickerFrame:Hide()
    end
end

function MR:RefreshMainAltPicker()
    if mainAltPickerFrame and mainAltPickerFrame:IsShown() then
        WBRefreshMainAltPicker(mainAltPickerFrame)
    end
end

