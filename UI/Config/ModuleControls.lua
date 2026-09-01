local _, ns = ...
local MR = ns.MR

local Config = assert(ns.ConfigInternal, "UI/Config/Frame.lua must load first")
local L = Config.L
local FONT_ROWS = ns.FONT_ROWS
local FONT_HEADERS = ns.FONT_HEADERS
local MakeBackdrop = ns.MakeBackdrop
local OptionsColorSwatch = ns.OptionsColorSwatch
local hex = ns.Hex
local GetFontFlags = Config.GetFontFlags

local function RequestConfigRefresh(frame, repopulate)
    if repopulate and MR.RequestConfigRepopulate then
        MR:RequestConfigRepopulate(frame, 0.04)
    elseif MR.RequestConfigRefresh then
        MR:RequestConfigRefresh()
    else
        MR:RefreshUI()
    end
end

local function ApplyVisibilityState(button, label, active)
    button:SetBackdropColor(0.05, 0.10, 0.18, 1)
    button:SetBackdropBorderColor(
        active and 0.15 or 0.35,
        active and 0.32 or 0.12,
        active and 0.38 or 0.12,
        1
    )
    label:SetText(active and "o" or "-")
    label:SetTextColor(
        active and 0.25 or 0.55,
        active and 0.85 or 0.25,
        active and 0.70 or 0.25
    )
end

local function CreateGrip(parent, height, enabled, onStart, onCommit)
    local grip = CreateFrame("Button", nil, parent, "BackdropTemplate")
    grip:SetSize(16, math.max(height - 4, 14))
    grip:SetPoint("LEFT", parent, "LEFT", 1, 0)
    grip:RegisterForClicks("LeftButtonUp")
    grip:SetBackdrop(MakeBackdrop())
    grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
    grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
    grip:SetEnabled(enabled)
    grip:SetAlpha(enabled and 1 or 0.35)

    local label = grip:CreateFontString(nil, "OVERLAY")
    label:SetFont(ns.FONT_HEADERS, 13, GetFontFlags())
    label:SetPoint("CENTER")
    label:SetText("=")
    label:SetTextColor(0.50, 0.75, 0.68)

    grip:SetScript("OnEnter", function()
        if enabled then
            label:SetTextColor(0.3, 1, 0.8)
            grip:SetBackdropColor(0.15, 0.35, 0.30, 0.9)
            grip:SetBackdropBorderColor(0.3, 1, 0.75, 1)
        end
    end)
    grip:SetScript("OnLeave", function()
        label:SetTextColor(0.50, 0.75, 0.68)
        grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
        grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
    end)
    grip:SetScript("OnMouseDown", function(selfGrip)
        if enabled and onStart then
            onStart(selfGrip)
        end
    end)
    grip:SetScript("OnClick", function()
        if enabled and onCommit then
            onCommit()
        end
    end)
    return grip
end

Config.CreateGrip = CreateGrip

local function CreateExpandButton(parent, expanded, onToggle)
    local isExpanded = expanded == true
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(16, 16)
    button:SetPoint("RIGHT", parent, "RIGHT", -1, 0)
    button:SetBackdrop(MakeBackdrop())

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
    label:SetPoint("CENTER", button, "CENTER", 0, 1)
    label:SetText(isExpanded and "v" or ">")

    local function ApplyState(hovered)
        button:SetBackdropColor(hovered and 0.08 or 0.05, hovered and 0.22 or 0.10, hovered and 0.32 or 0.18, 1)
        button:SetBackdropBorderColor(hovered and 0.25 or 0.15, hovered and 0.85 or 0.32, hovered and 0.72 or 0.38, 1)
        label:SetTextColor(hovered and 1 or 0.45, hovered and 1 or 0.75, hovered and 1 or 0.70)
    end

    ApplyState(false)
    button:SetScript("OnClick", function(...)
        isExpanded = not isExpanded
        label:SetText(isExpanded and "v" or ">")
        if onToggle then onToggle(...) end
    end)
    button:SetScript("OnEnter", function()
        ApplyState(true)
        ns.ShowTooltip(button, { text = L["Config_ExpandCollapseRows"] })
    end)
    button:SetScript("OnLeave", function()
        ApplyState(false)
        ns.HideOwnedTooltip(button)
    end)
    return button
end

local function CreateHideCompleteButton(parent, moduleKey, anchor)
    local isCurrencyModule = moduleKey == "currencies" or moduleKey == "pvp_currencies"
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(16, 16)
    button:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
    button:SetBackdrop(MakeBackdrop())

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(ns.FONT_ROWS, 8, GetFontFlags())
    label:SetPoint("CENTER")

    local function ApplyState(hovered)
        local active = MR:IsModuleHideComplete(moduleKey)
        button:SetBackdropColor(hovered and 0.08 or 0.05, hovered and 0.22 or 0.10, hovered and 0.32 or 0.18, 1)
        button:SetBackdropBorderColor(
            hovered and 0.25 or (active and 0.15 or 0.35),
            hovered and 0.85 or (active and 0.32 or 0.12),
            hovered and 0.72 or (active and 0.38 or 0.12),
            1
        )
        label:SetText(active and "H" or "S")
        label:SetTextColor(hovered and 1 or (active and 0.45 or 0.55), hovered and 1 or (active and 0.75 or 0.25), hovered and 1 or (active and 0.70 or 0.25))
    end

    ApplyState(false)
    button:SetScript("OnClick", function()
        MR:SetModuleHideComplete(moduleKey, not MR:IsModuleHideComplete(moduleKey), true)
        ApplyState(false)
        RequestConfigRefresh(nil, false)
    end)
    button:SetScript("OnEnter", function()
        ApplyState(true)
        local text
        if isCurrencyModule then
            text = MR:IsModuleHideComplete(moduleKey)
                    and "Hide Currencies When Completed enabled - capped currencies will be hidden"
                    or "Hide Currencies When Completed disabled - currencies stay visible at cap"
        else
            text = MR:IsModuleHideComplete(moduleKey) and L["Config_RowsCollapsed"] or L["Config_RowsShown"]
        end
        ns.ShowTooltip(button, { text = text })
    end)
    button:SetScript("OnLeave", function()
        ApplyState(false)
        ns.HideOwnedTooltip(button)
    end)
    return button
end

local function CreateModuleColorControls(parent, spec, anchor)
    local moduleKey = spec.module.key
    local background = MR.GetHeaderBackgroundColor and MR:GetHeaderBackgroundColor(moduleKey) or nil
    local br, bg, bb = 0.08, 0.09, 0.12
    if background then
        br, bg, bb = hex(background)
    end

    local backgroundSwatch = OptionsColorSwatch(parent, br, bg, bb, function(r, g, b)
        MR:SetHeaderBackgroundColor(moduleKey, string.format("#%02x%02x%02x", r * 255, g * 255, b * 255))
    end, function()
        MR:ResetHeaderBackgroundColor(moduleKey)
        RequestConfigRefresh(spec.configFrame, true)
        return 0.08, 0.09, 0.12
    end, L["Config_HeaderBackgroundColor"] or "Header Background")
    backgroundSwatch:SetPoint("RIGHT", anchor, "LEFT", -2, 0)

    local current = MR:GetHeaderColor(moduleKey)
    local r, g, b = hex(current or spec.module.labelColor or "#ffffff")
    local colorSwatch = OptionsColorSwatch(parent, r, g, b, function(nr, ng, nb)
        MR:SetHeaderColor(moduleKey, string.format("#%02x%02x%02x", nr * 255, ng * 255, nb * 255))
    end, function()
        MR:ResetHeaderColor(moduleKey)
        RequestConfigRefresh(spec.configFrame, true)
        return hex(spec.module.labelColor or "#ffffff")
    end, L["Config_HeaderColor"])
    colorSwatch:SetPoint("RIGHT", backgroundSwatch, "LEFT", -2, 0)
    return colorSwatch
end

function Config.CreateModuleControl(spec)
    local mod = spec.module
    local moduleKey = mod.key
    local frameTemplate = spec.emphasized and "BackdropTemplate" or nil
    local frame = CreateFrame("Frame", nil, spec.parent, frameTemplate)
    frame:SetPoint("TOPLEFT", spec.parent, "TOPLEFT", spec.x or 4, spec.y)
    frame:SetSize(spec.width, spec.height)

    if spec.emphasized then
        frame:SetBackdrop(MakeBackdrop())
        local r, g, b = hex(MR:GetHeaderColor(moduleKey) or mod.labelColor or "#2ae7c6")
        frame:SetBackdropColor(0.018 + r * 0.035, 0.024 + g * 0.035, 0.030 + b * 0.035, 0.90)
        frame:SetBackdropBorderColor(r * 0.42, g * 0.42, b * 0.42, 0.82)
    end

    local grip = CreateGrip(frame, spec.height, spec.available, spec.onDragStart, spec.onDragCommit)
    local checkbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    checkbox:SetSize(20, 20)
    checkbox:SetPoint("LEFT", grip, "RIGHT", 1, 0)
    checkbox:SetChecked(MR:IsModuleEnabled(moduleKey))
    checkbox:SetEnabled(spec.available)
    checkbox:SetAlpha(spec.available and 1 or 0.45)
    checkbox:SetScript("OnClick", function(control)
        MR:SetModuleEnabled(moduleKey, control:GetChecked(), true)
        if spec.onEnabledChanged then
            spec.onEnabledChanged()
        else
            RequestConfigRefresh(spec.configFrame, false)
        end
    end)

    local expand = CreateExpandButton(frame, spec.expanded, spec.onToggleExpanded)
    local hide = CreateHideCompleteButton(frame, moduleKey, expand)
    local color = CreateModuleColorControls(frame, spec, hide)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(ns.FONT_ROWS, spec.fontSize, GetFontFlags())
    label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    label:SetPoint("RIGHT", color, "LEFT", -2, 0)
    label:SetJustifyH("LEFT")
    label:SetText(spec.label)
    local labelColor = MR:GetHeaderColor(moduleKey) or mod.labelColor
    if not spec.available then
        label:SetTextColor(0.42, 0.46, 0.48)
        frame:SetAlpha(0.70)
    elseif labelColor then
        label:SetTextColor(hex(labelColor))
    else
        label:SetTextColor(0.88, 0.88, 0.88)
    end
    return frame
end

function Config.CreateTaskControl(spec)
    local mod = spec.module
    local row = spec.row
    local moduleKey = mod.key
    local rowKey = row.key
    local enabled = MR:IsRowEnabled(moduleKey, rowKey)

    local frame = CreateFrame("Frame", nil, spec.parent)
    frame:SetPoint("TOPLEFT", spec.parent, "TOPLEFT", spec.x or 18, spec.y)
    frame:SetSize(spec.width, spec.height)
    frame:EnableMouse(true)
    frame:SetAlpha(spec.available and 1 or 0.55)
    frame:SetScript("OnMouseDown", function(selfFrame, button)
        if spec.available and button == "LeftButton" and spec.onDragStart then
            spec.onDragStart(selfFrame)
        end
    end)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and spec.onDragCommit then
            spec.onDragCommit()
        end
    end)
    frame:SetScript("OnEnter", function()
        ns.ShowTooltip(frame, { text = L["Config_DragRowTooltip"] })
    end)
    frame:SetScript("OnLeave", function()
        ns.HideOwnedTooltip(frame)
    end)

    local dot = frame:CreateTexture(nil, "ARTWORK")
    dot:SetSize(5, 5)
    dot:SetPoint("LEFT", frame, "LEFT", 0, 0)

    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(ns.FONT_ROWS, spec.fontSize, GetFontFlags())
    label:SetPoint("LEFT", frame, "LEFT", 10, 0)
    label:SetPoint("RIGHT", frame, "RIGHT", -48, 0)
    label:SetJustifyH("LEFT")
    label:SetText(spec.label)

    local visibility = CreateFrame("Button", nil, frame, "BackdropTemplate")
    visibility:SetSize(14, 14)
    visibility:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    visibility:SetBackdrop(MakeBackdrop())
    visibility:SetEnabled(spec.available)
    local visibilityLabel = visibility:CreateFontString(nil, "OVERLAY")
    visibilityLabel:SetFont(ns.FONT_ROWS, spec.fontSize, GetFontFlags())
    visibilityLabel:SetPoint("CENTER")

    local function ApplyState(hovered)
        enabled = MR:IsRowEnabled(moduleKey, rowKey)
        local effectiveColor = MR:GetRowColor(moduleKey, rowKey)
            or (MR.db.profile.headerColors and MR.db.profile.headerColors[moduleKey])
        dot:SetColorTexture(hex(MR:GetRowColor(moduleKey, rowKey) or MR:GetHeaderColor(moduleKey)))
        dot:SetAlpha(enabled and 0.8 or 0.25)
        if not enabled then
            label:SetTextColor(0.35, 0.35, 0.35)
        elseif effectiveColor then
            label:SetTextColor(hex(effectiveColor))
        else
            label:SetTextColor(0.80, 0.80, 0.80)
        end
        ApplyVisibilityState(visibility, visibilityLabel, enabled)
        if hovered then
            visibility:SetBackdropColor(0.08, 0.22, 0.32, 1)
            visibility:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
            visibilityLabel:SetTextColor(1, 1, 1)
        end
    end

    visibility:SetScript("OnClick", function()
        MR:SetRowEnabled(moduleKey, rowKey, not MR:IsRowEnabled(moduleKey, rowKey), true)
        RequestConfigRefresh(spec.configFrame, false)
        ApplyState(false)
    end)
    visibility:SetScript("OnEnter", function()
        ApplyState(true)
        ns.ShowTooltip(visibility, { text = enabled and L["Config_HideRow"] or L["Config_ShowRow"] })
    end)
    visibility:SetScript("OnLeave", function()
        ApplyState(false)
        ns.HideOwnedTooltip(visibility)
    end)

    local r, g, b = hex(MR:GetRowColor(moduleKey, rowKey) or MR:GetHeaderColor(moduleKey))
    local swatch = OptionsColorSwatch(frame, r, g, b, function(nr, ng, nb)
        MR:SetRowColor(moduleKey, rowKey, string.format("#%02x%02x%02x", nr * 255, ng * 255, nb * 255))
        ApplyState(false)
    end, function()
        MR:ResetRowColor(moduleKey, rowKey)
        ApplyState(false)
        return hex(MR:GetHeaderColor(moduleKey))
    end, L["Config_RowColor"])
    swatch:SetSize(14, 14)
    swatch:SetPoint("RIGHT", visibility, "LEFT", -2, 0)

    local canHaveCompletionSound = type(row.max) == "number" and row.max > 0 and not row.noMax and not row.currencyId
    if canHaveCompletionSound then
        local soundBtn = CreateFrame("Button", nil, frame)
        soundBtn:SetSize(14, 14)
        soundBtn:SetPoint("RIGHT", swatch, "LEFT", -4, 0)

        local icon = soundBtn:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetAtlas("common-icon-sound", true)
        soundBtn:SetScript("OnClick", function()
            if ns.OpenCompletionSoundMenu then
                ns.OpenCompletionSoundMenu(moduleKey, rowKey, soundBtn)
            end
        end)
        soundBtn:SetScript("OnEnter", function()
            local hasSound = ns.GetCompletionSoundValue and ns.GetCompletionSoundValue(moduleKey, rowKey) ~= nil
            icon:SetVertexColor(1, 1, 1)
            ns.ShowTooltip(soundBtn, { text = hasSound
                and (L["Config_RowSoundHintSet"] or "Completion sound set. Click to change.")
                or (L["Config_RowSoundHint"] or "Click to set a completion sound.") })
        end)
        soundBtn:SetScript("OnLeave", function()
            local hasSound = ns.GetCompletionSoundValue and ns.GetCompletionSoundValue(moduleKey, rowKey) ~= nil
            if hasSound then
                icon:SetVertexColor(0.90, 0.75, 0.35)
            else
                icon:SetVertexColor(0.45, 0.47, 0.52)
            end
            ns.HideOwnedTooltip(soundBtn)
        end)
        local hasSoundNow = ns.GetCompletionSoundValue and ns.GetCompletionSoundValue(moduleKey, rowKey) ~= nil
        if hasSoundNow then
            icon:SetVertexColor(0.90, 0.75, 0.35)
        else
            icon:SetVertexColor(0.45, 0.47, 0.52)
        end
    end

    ApplyState(false)
    return frame
end
