MR_FONT_HEADERS = STANDARD_TEXT_FONT
MR_FONT_ROWS    = STANDARD_TEXT_FONT
MR_BACKDROP_FILE = "Interface\\Buttons\\WHITE8X8"

MR_COL = {
    complete   = { 0,    1,    0.59 },
    half       = { 1,    0.47, 0    },
    incomplete = { 0.6,  0.6,  0.6  },
    bg         = { 0.02, 0.03, 0.07, 0.96 },
    accent     = { 0.85, 0.65, 0.10 },
    border     = { 0.15, 0.15, 0.20 },
    titlebar   = { 0.05, 0.12, 0.22 },
}

function MR_HEX(h)
    h = h:gsub("#", "")
    return tonumber(h:sub(1,2), 16) / 255,
           tonumber(h:sub(3,4), 16) / 255,
           tonumber(h:sub(5,6), 16) / 255
end

function MR_WC(rrggbb, text)
    return string.format("|cff%s%s|r", rrggbb, text)
end

function MR_CountColor(done, max)
    if     done >= max then return MR_COL.complete[1],   MR_COL.complete[2],   MR_COL.complete[3]
    elseif done  > 0   then return MR_COL.half[1],       MR_COL.half[2],       MR_COL.half[3]
    else                    return MR_COL.incomplete[1], MR_COL.incomplete[2], MR_COL.incomplete[3]
    end
end

function MR_SetDotColor(tex, done, max)
    if     done >= max then tex:SetColorTexture(MR_COL.complete[1], MR_COL.complete[2], MR_COL.complete[3], 1)
    elseif done  > 0   then tex:SetColorTexture(MR_COL.half[1],     MR_COL.half[2],     MR_COL.half[3],     1)
    else                    tex:SetColorTexture(0.3, 0.3, 0.3, 1)
    end
end

function MR_GetFontSize()
    if MR and MR.db and MR.db.profile and MR.db.profile.fontSize then
        return MR.db.profile.fontSize
    end
    return 11
end

function MR_MakeBackdrop(edge)
    if edge == false then
        return { bgFile = MR_BACKDROP_FILE }
    end
    return {
        bgFile   = MR_BACKDROP_FILE,
        edgeFile = MR_BACKDROP_FILE,
        edgeSize = 1,
    }
end

function MR_StyledFrame(parent, name, strata, level)
    local f = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    f:SetFrameStrata(strata or "MEDIUM")
    f:SetFrameLevel(level or 10)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop(MR_MakeBackdrop())
    f:SetBackdropColor(MR_COL.bg[1], MR_COL.bg[2], MR_COL.bg[3], MR_COL.bg[4])
    f:SetBackdropBorderColor(MR_COL.border[1], MR_COL.border[2], MR_COL.border[3], 1)
    return f
end

function MR_TopAccent(parent, r, g, b)
    r, g, b = r or MR_COL.accent[1], g or MR_COL.accent[2], b or MR_COL.accent[3]
    local tex = parent:CreateTexture(nil, "BORDER")
    tex:SetPoint("TOPLEFT",  parent, "TOPLEFT",  0, 0)
    tex:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    tex:SetHeight(2)
    tex:SetColorTexture(r, g, b, 1)
    return tex
end

function MR_LeftAccent(parent, r, g, b)
    r, g, b = r or MR_COL.accent[1], g or MR_COL.accent[2], b or MR_COL.accent[3]
    local tex = parent:CreateTexture(nil, "BORDER")
    tex:SetPoint("TOPLEFT",    parent, "TOPLEFT",    0, 0)
    tex:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    tex:SetWidth(3)
    tex:SetColorTexture(r, g, b, 1)
    return tex
end

function MR_TitleBar(parent, h)
    h = h or 36
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetPoint("TOPLEFT")
    bar:SetPoint("TOPRIGHT")
    bar:SetHeight(h)
    bar:SetBackdrop(MR_MakeBackdrop(false))
    bar:SetBackdropColor(MR_COL.titlebar[1], MR_COL.titlebar[2], MR_COL.titlebar[3], 1)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    return bar
end

function MR_CloseButton(parent, onClose)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(16, 16)
    btn:SetPoint("RIGHT", parent, "RIGHT", -6, 0)
    btn:SetBackdrop(MR_MakeBackdrop())
    btn:SetBackdropColor(0.12, 0.04, 0.04, 1)
    btn:SetBackdropBorderColor(0.45, 0.12, 0.12, 1)
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(MR_FONT_HEADERS, 11, "OUTLINE")
    lbl:SetPoint("CENTER", btn, "CENTER", 0, 1)
    lbl:SetText("x")
    lbl:SetTextColor(0.75, 0.28, 0.28)
    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.35, 0.06, 0.06, 1)
        btn:SetBackdropBorderColor(0.90, 0.25, 0.25, 1)
        lbl:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.12, 0.04, 0.04, 1)
        btn:SetBackdropBorderColor(0.45, 0.12, 0.12, 1)
        lbl:SetTextColor(0.75, 0.28, 0.28)
    end)
    if onClose then btn:SetScript("OnClick", onClose) end
    return btn
end

function MR_SaveFramePos(frame, key)
    if not MR or not MR.db then return end
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local pt, _, rp, x, y = frame:GetPoint()
        MR.db.profile[key] = { point = pt, relPoint = rp, x = x, y = y }
    end)
end

function MR_RestoreFramePos(frame, key, defaultX, defaultY)
    if MR and MR.db and MR.db.profile[key] then
        local p = MR.db.profile[key]
        frame:SetPoint(p.point, UIParent, p.relPoint or p.point, p.x, p.y)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", defaultX or 0, defaultY or 0)
    end
end

function MR_OptionsGap(body, yOff, h)
    return yOff - (h or 4)
end

function MR_OptionsDivider(body, yOff, pad)
    pad = pad or 8
    local fr = CreateFrame("Frame", nil, body, "BackdropTemplate")
    fr:SetPoint("TOPLEFT",  body, "TOPLEFT",   pad, yOff)
    fr:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
    fr:SetHeight(1)
    fr:SetBackdrop(MR_MakeBackdrop(false))
    fr:SetBackdropColor(1, 1, 1, 0.07)
    return yOff - 6
end

function MR_OptionsSectionLabel(body, yOff, text, pad)
    pad = pad or 8
    local fs = body:CreateFontString(nil, "OVERLAY")
    fs:SetFont(MR_FONT_ROWS, 9, "OUTLINE")
    fs:SetText("|cff888888" .. text .. "|r")
    fs:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    return yOff - 14
end

function MR_OptionsCheckbox(body, yOff, label, getVal, setVal, r, g, b, pad, onRefresh)
    pad = pad or 8
    local fr = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
    fr:SetSize(20, 20)
    fr:SetPoint("TOPLEFT", body, "TOPLEFT", pad - 2, yOff)
    fr:SetChecked(getVal())
    fr:EnableMouse(true)
    fr:SetScript("OnClick", function(s)
        setVal(s:GetChecked())
        if onRefresh then onRefresh() end
    end)
    local lbl = fr:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(MR_FONT_ROWS, 10, "OUTLINE")
    lbl:SetText(label)
    lbl:SetTextColor(r or 0.88, g or 0.88, b or 0.88)
    lbl:SetPoint("LEFT", fr, "RIGHT", 0, 0)
    return yOff - 22
end

function MR_OptionsBtn(body, yOff, label, onClick, width, pad)
    pad   = pad   or 8
    width = width or 184
    local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
    btn:SetSize(width, 20)
    btn:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    btn:SetBackdrop(MR_MakeBackdrop())
    btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
    btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFont(MR_FONT_ROWS, 10, "OUTLINE")
    fs:SetPoint("CENTER")
    fs:SetText(label)
    fs:SetTextColor(0.70, 0.88, 0.85)
    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.08, 0.22, 0.32, 1)
        btn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
        fs:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
        btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
        fs:SetTextColor(0.70, 0.88, 0.85)
    end)
    return yOff - 26
end

function MR_OptionsSlider(body, yOff, label, min, max, step, getVal, setVal, fillR, fillG, fillB, pad)
    pad   = pad   or 8
    fillR = fillR or 0.85
    fillG = fillG or 0.65
    fillB = fillB or 0.10
    local lbl = body:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(MR_FONT_ROWS, 9, "OUTLINE")
    lbl:SetText("|cff888888" .. label .. "|r")
    lbl:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    yOff = yOff - 14
    local bg = CreateFrame("Frame", nil, body, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    bg:SetSize(138, 14)
    bg:SetBackdrop(MR_MakeBackdrop())
    bg:SetBackdropColor(0, 0, 0, 0.5)
    bg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    local fill = bg:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", bg, "LEFT", 2, 0)
    fill:SetHeight(10)
    fill:SetColorTexture(fillR, fillG, fillB, 0.85)
    local valBox = CreateFrame("Frame", nil, body, "BackdropTemplate")
    valBox:SetPoint("LEFT", bg, "RIGHT", 4, 0)
    valBox:SetSize(44, 14)
    valBox:SetBackdrop(MR_MakeBackdrop())
    valBox:SetBackdropColor(0, 0, 0, 0.5)
    valBox:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    local valTxt = valBox:CreateFontString(nil, "OVERLAY")
    valTxt:SetFont(MR_FONT_ROWS, 9, "OUTLINE")
    valTxt:SetPoint("CENTER", valBox, "CENTER", 0, 0)
    local function UpdateVis(v)
        local pct = (v - min) / (max - min)
        fill:SetWidth(math.max(2, (bg:GetWidth() - 4) * pct))
        valTxt:SetText(string.format("%.2f", v):gsub("%.?0+$", ""))
    end
    local sl = CreateFrame("Slider", nil, bg)
    sl:SetAllPoints(bg)
    sl:SetMinMaxValues(min, max)
    sl:SetValueStep(step)
    sl:SetObeyStepOnDrag(true)
    sl:SetOrientation("HORIZONTAL")
    sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local th = sl:GetThumbTexture()
    if th then th:Hide() end
    sl:SetValue(getVal())
    UpdateVis(getVal())
    sl:SetScript("OnValueChanged", function(s, v) UpdateVis(v) end)
    sl:SetScript("OnMouseUp",      function(s) setVal(s:GetValue()) end)
    return yOff - 18
end

function MR_OptionsColorSwatch(parent, r, g, b, onPick, onReset, tooltip)
    local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
    swatch:SetSize(16, 16)
    swatch:SetBackdrop(MR_MakeBackdrop())
    swatch:SetBackdropColor(r, g, b, 1)
    swatch:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    swatch:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b,
                hasOpacity = false,
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    r, g, b = nr, ng, nb
                    swatch:SetBackdropColor(r, g, b, 1)
                    if onPick then onPick(r, g, b) end
                end,
                cancelFunc = function(prev)
                    r, g, b = prev.r, prev.g, prev.b
                    swatch:SetBackdropColor(r, g, b, 1)
                    if onPick then onPick(r, g, b) end
                end,
            })
        elseif button == "RightButton" then
            if onReset then
                r, g, b = onReset()
                swatch:SetBackdropColor(r, g, b, 1)
            end
        end
    end)
    swatch:SetScript("OnEnter", function()
        swatch:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
        GameTooltip:SetOwner(swatch, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltip or "Color", 1, 1, 1)
        GameTooltip:AddLine("Left-click: Pick color", 0.5, 0.5, 0.5)
        if onReset then GameTooltip:AddLine("Right-click: Reset", 0.5, 0.5, 0.5) end
        GameTooltip:Show()
    end)
    swatch:SetScript("OnLeave", function()
        swatch:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        GameTooltip:Hide()
    end)
    return swatch
end
