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

function ns.CloseButton(parent, onClose, opts)
    opts = opts or {}
    local size = opts.size or 20
    local button = ns.HeaderButton(parent, {
        size = size,
        text = "x",
        font = opts.font or ns.FONT_HEADERS,
        fontSize = opts.fontSize or math.max(8, size - 9),
        color = { 0.88, 0.56, 0.56, 1 },
        themed = true,
        hoverColor = { 1, 1, 1, 1 },
        hoverBackground = { 0.28, 0.10, 0.10, 1 },
        hoverBorder = { 0.90, 0.25, 0.25, 1 },
        tooltip = opts.tooltip,
        tooltipSub = opts.tooltipSub,
        onClick = onClose,
    })
    if opts.anchor ~= false then
        button:SetPoint("RIGHT", parent, "RIGHT", -(opts.margin or 8), 0)
    end
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

    if opts.themed then
        if button._isTexture then
            ns.RegisterThemedVertexTexture(iconObject, normalColor[1], normalColor[2], normalColor[3], normalColor[4])
        else
            ns.RegisterThemedFontString(iconObject, normalColor[1], normalColor[2], normalColor[3], normalColor[4])
        end
    end

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
        if opts.themed then
            local r, g, b = ns.ResolveThemeColor(normalColor[1], normalColor[2], normalColor[3])
            SetIconColor({ r, g, b, normalColor[4] })
        else
            SetIconColor(normalColor)
        end
        ns.HideOwnedTooltip(self)
    end)
    ns.RegisterThemedState(button, function(self)
        if self:IsMouseOver() then
            ApplyBackdrop(hoverBg, hoverBorder)
            SetIconColor(hoverColor)
        else
            ApplyBackdrop(normalBg, normalBorder)
            if opts.themed then
                local r, g, b = ns.ResolveThemeColor(normalColor[1], normalColor[2], normalColor[3])
                SetIconColor({ r, g, b, normalColor[4] })
            else
                SetIconColor(normalColor)
            end
        end
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
    ns.RegisterThemedVertexTexture(texture, (tintColor and tintColor[1]) or 1, (tintColor and tintColor[2]) or 1, (tintColor and tintColor[3]) or 1)

    button:SetScript("OnEnter", function(self)
        ApplyButtonHover(self, true)
        texture:SetVertexColor((hoverTintColor and hoverTintColor[1]) or 1, (hoverTintColor and hoverTintColor[2]) or 1, (hoverTintColor and hoverTintColor[3]) or 1)
        ShowHeaderTooltip(self, tooltipText)
    end)
    button:SetScript("OnLeave", function(self)
        ApplyButtonHover(self, false)
        local r, g, b = ns.ResolveThemeColor((tintColor and tintColor[1]) or 1, (tintColor and tintColor[2]) or 1, (tintColor and tintColor[3]) or 1)
        texture:SetVertexColor(r, g, b)
        ns.HideOwnedTooltip(self)
    end)
    ns.RegisterThemedState(button, function(self)
        local hovered = self:IsMouseOver()
        ApplyButtonHover(self, hovered)
        if hovered then
            texture:SetVertexColor((hoverTintColor and hoverTintColor[1]) or 1, (hoverTintColor and hoverTintColor[2]) or 1, (hoverTintColor and hoverTintColor[3]) or 1)
        else
            local r, g, b = ns.ResolveThemeColor((tintColor and tintColor[1]) or 1, (tintColor and tintColor[2]) or 1, (tintColor and tintColor[3]) or 1)
            texture:SetVertexColor(r, g, b)
        end
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
    ns.RegisterThemedFontString(label, 0.25, 0.80, 0.68)

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
        local r, g, b = ns.ResolveThemeColor(0.25, 0.80, 0.68)
        label:SetTextColor(r, g, b)
        ns.HideOwnedTooltip(self)
    end)
    ns.RegisterThemedState(button, function(self)
        local hovered = self:IsMouseOver()
        ApplyButtonHover(self, hovered)
        if hovered then
            label:SetTextColor(1, 1, 1)
        else
            local r, g, b = ns.ResolveThemeColor(0.25, 0.80, 0.68)
            label:SetTextColor(r, g, b)
        end
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
