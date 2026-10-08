local _, ns = ...

local STYLES = {
    teal = {
        buttonBorder = { 0.18, 0.40, 0.45, 1 },
        hoverBorder = { 0.26, 0.78, 0.72, 1 },
        label = { 0.76, 0.97, 0.94, 1 },
        caret = { 0.78, 0.90, 0.92, 1 },
        popupBorder = { 0.18, 0.40, 0.45, 1 },
        selectedBorder = { 0.28, 0.86, 0.78, 1 },
        optionLabel = { 0.74, 0.90, 0.92, 1 },
        selectedLabel = { 0.96, 1.00, 1.00, 1 },
        check = { 0.80, 0.94, 0.92, 1 },
    },
    gold = {
        buttonBorder = { 0.40, 0.32, 0.18, 1 },
        hoverBorder = { 0.85, 0.70, 0.35, 1 },
        label = { 0.90, 0.80, 0.55, 1 },
        caret = { 0.85, 0.75, 0.55, 1 },
        popupBorder = { 0.40, 0.32, 0.18, 1 },
        selectedBorder = { 0.55, 0.46, 0.20, 1 },
        optionLabel = { 0.85, 0.80, 0.75, 1 },
        selectedLabel = { 0.96, 0.90, 0.65, 1 },
        check = { 0.90, 0.80, 0.55, 1 },
    },
}

local BUTTON_BG = { 0.05, 0.12, 0.20, 0.95 }
local HOVER_BG = { 0.08, 0.18, 0.28, 0.98 }
local POPUP_BG = { 0.04, 0.09, 0.15, 0.98 }
local ROW_BG = { 0.05, 0.12, 0.20, 0.94 }
local ROW_BORDER = { 0.12, 0.26, 0.32, 0.95 }
local SELECTED_BG = { 0.10, 0.22, 0.30, 0.98 }

local function Resolve(opts, key, fallback)
    local value = opts[key]
    if type(value) == "function" then
        value = value()
    end
    if value == nil then
        return fallback
    end
    return value
end

local function SetBackdropColor(frame, color, alpha)
    frame:SetBackdropColor(color[1], color[2], color[3], (color[4] or 1) * alpha)
end

local function SetBackdropBorderColor(frame, color, alpha)
    frame:SetBackdropBorderColor(color[1], color[2], color[3], (color[4] or 1) * alpha)
end


local function OptionLabel(option)
    return tostring(option.shortLabel or option.label or option.key or option.value or "")
end

local function OptionKey(option)
    if option.key ~= nil then
        return option.key
    end
    return option.value
end

function ns.CreateDropdown(parent, opts)
    opts = opts or {}
    local style = STYLES[opts.style or "teal"] or STYLES.teal

    local function ThemeColor(color)
        if opts.themed == false then
            return color[1], color[2], color[3]
        end
        return ns.ResolveThemeColor(color[1], color[2], color[3])
    end

    local function SetThemeTextColor(fontString, color, alpha)
        local r, g, b = ThemeColor(color)
        fontString:SetTextColor(r, g, b, (color[4] or 1) * alpha)
    end

    local function SetThemeBorderColor(frame, color, alpha)
        local r, g, b = ThemeColor(color)
        frame:SetBackdropBorderColor(r, g, b, (color[4] or 1) * alpha)
    end

    local function GetAlpha()
        return math.max(0, math.min(Resolve(opts, "alpha", 1), 1))
    end

    local function GetFontSize()
        return math.max(8, Resolve(opts, "fontSize", 8))
    end

    local function GetOptions()
        return opts.getOptions and opts.getOptions() or {}
    end

    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(opts.width or 130, opts.height or 18)
    button:SetBackdrop(ns.MakeBackdrop())

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(ns.FONT_ROWS, GetFontSize(), ns.GetFontFlags())
    label:SetPoint("LEFT", button, "LEFT", opts.labelInset or 8, opts.textYOffset or 1)
    label:SetPoint("RIGHT", button, "RIGHT", opts.labelRightInset or -20, opts.textYOffset or 1)
    label:SetJustifyH("LEFT")
    button._label = label

    local caret = button:CreateFontString(nil, "OVERLAY")
    caret:SetFont(ns.FONT_HEADERS, math.max(9, GetFontSize() + 1), ns.GetFontFlags())
    caret:SetPoint("RIGHT", button, "RIGHT", opts.caretInset or -7, opts.textYOffset or 1)
    caret:SetText("v")
    button._caret = caret
    if opts.themed ~= false then
        label:SetTextColor(0.94, 0.96, 0.98, style.label[4])
        ns.RegisterThemedFontString(caret, style.caret[1], style.caret[2], style.caret[3], style.caret[4])
    end

    local popup
    local popupScroll
    local popupContent
    local scrollTrack
    local updatePopupScroll
    local dismiss

    local function EnsurePopup()
        if popup then
            return
        end

        popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        popup:SetFrameStrata("TOOLTIP")
        popup:SetFrameLevel(50)
        popup:SetClampedToScreen(true)
        popup:SetBackdrop(ns.MakeBackdrop())
        popup:Hide()
        popup.buttons = {}

        popupScroll = CreateFrame("ScrollFrame", nil, popup)
        popupContent = CreateFrame("Frame", nil, popupScroll)
        popupContent:SetSize(1, 1)
        scrollTrack = CreateFrame("Frame", nil, popup)
        scrollTrack:SetWidth(6)
        updatePopupScroll = ns.AttachScrollList(popupScroll, popupContent, scrollTrack, {
            hideTrack = true,
            minThumbHeight = 18,
            thumbColor = style.check,
            wheelStep = 24,
        })

        dismiss = CreateFrame("Frame", nil, UIParent)
        dismiss:SetAllPoints(UIParent)
        dismiss:SetFrameStrata("TOOLTIP")
        dismiss:SetFrameLevel(49)
        dismiss:EnableMouse(true)
        dismiss:Hide()
        dismiss:SetScript("OnMouseDown", function()
            popup:Hide()
            dismiss:Hide()
        end)

        button:SetScript("OnHide", function()
            popup:Hide()
            dismiss:Hide()
        end)

        button._popup = popup
        button._popupScroll = popupScroll
        button._dismiss = dismiss
        button._mrExternalFrames = button._mrExternalFrames or {}
        button._mrExternalFrames[#button._mrExternalFrames + 1] = popup
        button._mrExternalFrames[#button._mrExternalFrames + 1] = dismiss
    end

    function button:ApplyFonts()
        local fontSize = GetFontSize()
        local caretSize = math.max(9, fontSize + 1)
        local minHeight = opts.height or 18
        local maxHeight = opts.maxHeight or math.huge
        local alpha = GetAlpha()

        self:SetHeight(math.min(maxHeight, math.max(minHeight, fontSize + (opts.heightPadding or 8))))
        label:SetFont(ns.FONT_ROWS, fontSize, ns.GetFontFlags())
        caret:SetFont(ns.FONT_HEADERS, caretSize, ns.GetFontFlags())
        SetBackdropColor(self, BUTTON_BG, alpha)
        SetThemeBorderColor(self, style.buttonBorder, alpha)
        label:SetTextColor(0.94, 0.96, 0.98, alpha)
        SetThemeTextColor(caret, style.caret, alpha)

        if opts.dynamicWidth then
            local textWidth = (label:GetStringWidth() or 0) + (opts.widthPadding or 30)
            self:SetWidth(math.max(opts.width or 78, math.min(opts.maxWidth or 220, math.ceil(textWidth))))
        end

        if popup then
            for _, row in ipairs(popup.buttons) do
                row:SetHeight(math.max(18, fontSize + 10))
                row._label:SetFont(ns.FONT_ROWS, fontSize, ns.GetFontFlags())
                row._check:SetFont(ns.FONT_HEADERS, caretSize, ns.GetFontFlags())
            end
        end
    end

    button:SetScript("OnEnter", function(self)
        local alpha = GetAlpha()
        SetBackdropColor(self, HOVER_BG, alpha)
        SetThemeBorderColor(self, style.hoverBorder, alpha)
    end)
    button:SetScript("OnLeave", function(self)
        local alpha = GetAlpha()
        SetBackdropColor(self, BUTTON_BG, alpha)
        SetThemeBorderColor(self, style.buttonBorder, alpha)
    end)
    ns.RegisterThemedState(button, function(self)
        local alpha = GetAlpha()
        SetBackdropColor(self, self:IsMouseOver() and HOVER_BG or BUTTON_BG, alpha)
        SetThemeBorderColor(self, self:IsMouseOver() and style.hoverBorder or style.buttonBorder, alpha)
        label:SetTextColor(0.94, 0.96, 0.98, alpha)
        SetThemeTextColor(caret, style.caret, alpha)
    end)

    local function EnsurePopupButton(index)
        local row = popup.buttons[index]
        if row then return row end

        row = CreateFrame("Button", nil, popupContent, "BackdropTemplate")
        row:SetBackdrop(ns.MakeBackdrop())
        row._label = row:CreateFontString(nil, "OVERLAY")
        row._label:SetFont(ns.FONT_ROWS, GetFontSize(), ns.GetFontFlags())
        row._label:SetPoint("LEFT", row, "LEFT", 8, 1)
        row._label:SetPoint("RIGHT", row, "RIGHT", -22, 1)
        row._label:SetJustifyH("LEFT")
        row._check = row:CreateFontString(nil, "OVERLAY")
        row._check:SetFont(ns.FONT_HEADERS, math.max(9, GetFontSize() + 1), ns.GetFontFlags())
        row._check:SetPoint("RIGHT", row, "RIGHT", -7, 1)

        row:SetScript("OnEnter", function(self)
            local alpha = GetAlpha()
            SetBackdropColor(self, HOVER_BG, alpha)
            SetThemeBorderColor(self, style.hoverBorder, alpha)
        end)
        row:SetScript("OnLeave", function(self)
            local alpha = GetAlpha()
            SetBackdropColor(self, self._checked and SELECTED_BG or ROW_BG, alpha)
            if self._checked then
                SetThemeBorderColor(self, style.selectedBorder, alpha)
            else
                SetBackdropBorderColor(self, ROW_BORDER, alpha)
            end
        end)
        row:SetScript("OnClick", function(self)
            local option = self._option
            if not option then return end
            popup:Hide()
            dismiss:Hide()
            if opts.onSelect then opts.onSelect(OptionKey(option), option) end
            button:Update()
        end)

        popup.buttons[index] = row
        return row
    end

    function button:Update()
        local options = GetOptions()
        local selectedKey = opts.getSelected and opts.getSelected()
        label:SetText("")
        for _, option in ipairs(options) do
            if OptionKey(option) == selectedKey then
                label:SetText(OptionLabel(option))
                break
            end
        end
        self:ApplyFonts()
        if opts.hideWhenSingle and #options <= 1 then self:Hide() else self:Show() end
    end

    button:SetScript("OnClick", function(self)
        local options = GetOptions()
        if #options <= 1 then return end
        EnsurePopup()

        local selectedKey = opts.getSelected and opts.getSelected()
        local fontSize = GetFontSize()
        local rowHeight = math.max(18, fontSize + 10)
        local rowSpacing = opts.rowSpacing or 2
        local maxVisibleRows = opts.maxVisibleRows or 10
        local visibleRows = math.min(#options, maxVisibleRows)
        local needsScroll = #options > maxVisibleRows
        self:ApplyFonts()

        local rowWidth = math.max(self:GetWidth(), opts.minMenuWidth or 130)
        if opts.dynamicMenuWidth then
            for _, option in ipairs(options) do
                rowWidth = math.max(rowWidth, (#OptionLabel(option) * fontSize * 0.58) + 34)
            end
            rowWidth = math.min(opts.maxWidth or 220, math.ceil(rowWidth))
        end

        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -4)
        popup:SetSize(rowWidth + (needsScroll and 10 or 0), (visibleRows * (rowHeight + rowSpacing)) + 6)
        local alpha = GetAlpha()
        SetBackdropColor(popup, POPUP_BG, alpha)
        SetThemeBorderColor(popup, style.popupBorder, alpha)

        popupScroll:ClearAllPoints()
        popupScroll:SetPoint("TOPLEFT", popup, "TOPLEFT", 3, -3)
        popupScroll:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", needsScroll and -12 or -3, 3)
        scrollTrack:ClearAllPoints()
        scrollTrack:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -3, -3)
        scrollTrack:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -3, 3)
        if not needsScroll then scrollTrack:Hide() end
        popupContent:SetSize(rowWidth - 6, math.max((#options * (rowHeight + rowSpacing)) - rowSpacing + 6, 1))

        for index, option in ipairs(options) do
            local row = EnsurePopupButton(index)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", popupContent, "TOPLEFT", 0, -3 - ((index - 1) * (rowHeight + rowSpacing)))
            row:SetPoint("TOPRIGHT", popupContent, "TOPRIGHT", 0, -3 - ((index - 1) * (rowHeight + rowSpacing)))
            row:SetHeight(rowHeight)
            row._option = option
            row._checked = OptionKey(option) == selectedKey
            row._label:SetText(OptionLabel(option))
            row._label:SetTextColor(row._checked and 1 or 0.90, row._checked and 1 or 0.93, row._checked and 1 or 0.96, alpha)
            row._check:SetText(row._checked and "x" or "")
            SetThemeTextColor(row._check, style.check, alpha)
            SetBackdropColor(row, row._checked and SELECTED_BG or ROW_BG, alpha)
            if row._checked then
                SetThemeBorderColor(row, style.selectedBorder, alpha)
            else
                SetBackdropBorderColor(row, ROW_BORDER, alpha)
            end
            row:Show()
        end

        for index = #options + 1, #popup.buttons do
            popup.buttons[index]._option = nil
            popup.buttons[index]:Hide()
        end

        local selectedIndex = 1
        for index, option in ipairs(options) do
            if OptionKey(option) == selectedKey then
                selectedIndex = index
                break
            end
        end
        local selectedOffset = math.max(0, (selectedIndex - 1) * (rowHeight + rowSpacing))
        local maxScroll = math.max(popupContent:GetHeight() - popupScroll:GetHeight(), 0)
        popupScroll:SetVerticalScroll(math.min(selectedOffset, maxScroll))
        updatePopupScroll()

        if popup:IsShown() then
            popup:Hide()
            dismiss:Hide()
        else
            dismiss:Show()
            popup:Show()
        end
    end)

    button:Update()
    return button
end
