local _, ns = ...

local function ApplyButtonBase(button)
    button:SetSize(16, 16)
    button:SetBackdrop(ns.MakeBackdrop())
    button:SetBackdropColor(0.06, 0.12, 0.22, 0.85)
    button:SetBackdropBorderColor(0.15, 0.35, 0.40, 0.9)
end

local function ApplyButtonHover(button, hovered)
    if hovered then
        button:SetBackdropColor(0.08, 0.22, 0.32, 1)
        button:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
    else
        button:SetBackdropColor(0.06, 0.12, 0.22, 0.85)
        button:SetBackdropBorderColor(0.15, 0.35, 0.40, 0.9)
    end
end

local function ShowHeaderTooltip(button, text)
    if text then
        ns.ShowTooltip(button, { anchor = "ANCHOR_BOTTOM", text = text })
    end
end

function ns.TitleBar(parent, height)
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(height or 36)
    bar:SetBackdrop(ns.MakeBackdrop(false))
    ns.HookBackdropFrame(bar)
    local colors = ns.COLORS
    bar:SetBackdropColor(colors.titlebar[1], colors.titlebar[2], colors.titlebar[3], 1)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    return bar
end

function ns.CloseButton(parent, onClose)
    local button = ns.AcquireFrame(parent, "closeButton", "Button", "BackdropTemplate")
    button:SetSize(16, 16)
    button:SetPoint("RIGHT", parent, "RIGHT", -6, 0)
    button:SetBackdrop(ns.MakeBackdrop())
    button:SetBackdropColor(0.12, 0.04, 0.04, 1)
    button:SetBackdropBorderColor(0.45, 0.12, 0.12, 1)

    local label = ns.AcquireFontString(button, "label", "OVERLAY")
    label:SetFont(ns.FONT_HEADERS, 11, ns.GetFontFlags())
    label:SetPoint("CENTER", button, "CENTER", 0, 1)
    label:SetText("x")
    label:SetTextColor(0.75, 0.28, 0.28)

    button:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.35, 0.06, 0.06, 1)
        self:SetBackdropBorderColor(0.90, 0.25, 0.25, 1)
        label:SetTextColor(1, 1, 1)
    end)
    button:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.04, 0.04, 1)
        self:SetBackdropBorderColor(0.45, 0.12, 0.12, 1)
        label:SetTextColor(0.75, 0.28, 0.28)
    end)

    button:SetScript("OnClick", onClose)

    return button
end

function ns.HeaderButton(parent, opts)
    opts = opts or {}
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(opts.width or opts.size or 18, opts.height or opts.size or 18)
    button:SetBackdrop(ns.MakeBackdrop())

    local normalBg = opts.background or { 0.07, 0.09, 0.13, 0.96 }
    local normalBorder = opts.border or { 0.18, 0.23, 0.30, 0.95 }
    local hoverBg = opts.hoverBackground or { 0.08, 0.22, 0.32, 1 }
    local hoverBorder = opts.hoverBorder or { 0.25, 0.85, 0.72, 1 }
    local normalColor = opts.color or { 1, 1, 1, 1 }
    local hoverColor = opts.hoverColor or { 1, 1, 1, 1 }

    local function ApplyBackdrop(background, border)
        button:SetBackdropColor(background[1], background[2], background[3], background[4] or 1)
        button:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
    end

    local iconObject
    if opts.texture then
        iconObject = button:CreateTexture(nil, "OVERLAY")
        iconObject:SetSize(opts.iconWidth or opts.iconSize or math.max(8, button:GetWidth() - 4), opts.iconHeight or opts.iconSize or math.max(8, button:GetHeight() - 4))
        iconObject:SetPoint("CENTER", button, "CENTER", opts.iconX or 0, opts.iconY or 0)
        iconObject:SetTexture(opts.texture)
        iconObject:SetVertexColor(normalColor[1], normalColor[2], normalColor[3], normalColor[4] or 1)
        button._isTexture = true
        button._iconTex = iconObject
    else
        iconObject = button:CreateFontString(nil, "OVERLAY")
        iconObject:SetFont(opts.font or ns.FONT_HEADERS, opts.fontSize or math.max(8, (opts.height or opts.size or 18) - 7), opts.fontFlags or ns.GetFontFlags())
        iconObject:SetPoint("CENTER", button, "CENTER", opts.iconX or 0, opts.iconY or 1)
        iconObject:SetText(opts.text or "")
        iconObject:SetTextColor(normalColor[1], normalColor[2], normalColor[3], normalColor[4] or 1)
        button._lbl = iconObject
    end
    button._iconObj = iconObject
    button._normalColor = normalColor

    local function SetIconColor(color)
        if button._isTexture then
            iconObject:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
        else
            iconObject:SetTextColor(color[1], color[2], color[3], color[4] or 1)
        end
    end

    ApplyBackdrop(normalBg, normalBorder)
    button:SetScript("OnEnter", function(self)
        ApplyBackdrop(hoverBg, hoverBorder)
        SetIconColor(hoverColor)
        if opts.tooltip then
            ns.ShowTooltip(self, {
                anchor = opts.tooltipAnchor or "ANCHOR_BOTTOM",
                build = function(tooltip)
                    tooltip:SetText(opts.tooltip, 1, 1, 1)
                    if opts.tooltipSub then
                        tooltip:AddLine(opts.tooltipSub, 0.6, 0.6, 0.6, true)
                    end
                end,
            })
        end
    end)
    button:SetScript("OnLeave", function(self)
        ApplyBackdrop(normalBg, normalBorder)
        SetIconColor(normalColor)
        ns.HideOwnedTooltip(self)
    end)
    if opts.onClick then
        button:SetScript("OnClick", opts.onClick)
    end

    return button
end

function ns.HeaderIconButton(parent, texturePath, tintColor, hoverTintColor, tooltipText, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    ApplyButtonBase(button)

    local texture = button:CreateTexture(nil, "OVERLAY")
    texture:SetSize(14, 14)
    texture:SetPoint("CENTER")
    texture:SetTexture(texturePath)
    texture:SetVertexColor((tintColor and tintColor[1]) or 1, (tintColor and tintColor[2]) or 1, (tintColor and tintColor[3]) or 1)

    button:SetScript("OnEnter", function(self)
        ApplyButtonHover(self, true)
        texture:SetVertexColor((hoverTintColor and hoverTintColor[1]) or 1, (hoverTintColor and hoverTintColor[2]) or 1, (hoverTintColor and hoverTintColor[3]) or 1)
        ShowHeaderTooltip(self, tooltipText)
    end)
    button:SetScript("OnLeave", function(self)
        ApplyButtonHover(self, false)
        texture:SetVertexColor((tintColor and tintColor[1]) or 1, (tintColor and tintColor[2]) or 1, (tintColor and tintColor[3]) or 1)
        ns.HideOwnedTooltip(self)
    end)

    if onClick then
        button:SetScript("OnClick", onClick)
    end

    button._iconTex = texture
    return button
end

function ns.HeaderToggleButton(parent, getLabel, tooltipText, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    ApplyButtonBase(button)

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(ns.FONT_HEADERS, 12, ns.GetFontFlags())
    label:SetPoint("CENTER", button, "CENTER", 0, 1)
    label:SetTextColor(0.25, 0.80, 0.68)

    local function RefreshLabel()
        label:SetText(type(getLabel) == "function" and getLabel() or tostring(getLabel or "-"))
    end

    button:SetScript("OnEnter", function(self)
        ApplyButtonHover(self, true)
        label:SetTextColor(1, 1, 1)
        ShowHeaderTooltip(self, tooltipText)
    end)
    button:SetScript("OnLeave", function(self)
        ApplyButtonHover(self, false)
        label:SetTextColor(0.25, 0.80, 0.68)
        ns.HideOwnedTooltip(self)
    end)
    button:SetScript("OnClick", function(...)
        if onClick then
            onClick(...)
        end
        RefreshLabel()
    end)

    RefreshLabel()
    button._label = label
    button.RefreshLabel = RefreshLabel
    return button
end
