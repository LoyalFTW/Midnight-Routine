local _, ns = ...
local MR = ns.MR

local cfgFrame
local keybindCaptureFrame
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")
local TOGGLE_WINDOWS_BINDING = "MIDNIGHTROUTINE_TOGGLE_WINDOWS"
local MODIFIER_KEYS = {
    LALT = true,
    RALT = true,
    ALT = true,
    LCTRL = true,
    RCTRL = true,
    CTRL = true,
    LSHIFT = true,
    RSHIFT = true,
    SHIFT = true,
    LMETA = true,
    RMETA = true,
    META = true,
}
local MOUSE_BUTTON_KEYS = {
    LeftButton = "BUTTON1",
    RightButton = "BUTTON2",
    MiddleButton = "BUTTON3",
}

local PANEL_MIN_WIDTH  = 200
local PANEL_MAX_WIDTH  = 500
local PANEL_MIN_HEIGHT = 100
local PANEL_MAX_HEIGHT = 800
local FONT_SIZE_MIN = 7
local FONT_SIZE_MAX = 20
local DAY_SECONDS = 24 * 60 * 60

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
local OptionsBtn = ns.OptionsBtn
local OptionsSlider = ns.OptionsSlider
local OptionsColorSwatch = ns.OptionsColorSwatch
local ApplyBackgroundTexture    = ns.ApplyBackgroundTexture
local GetMainHeaderPosition     = ns.GetMainHeaderPosition
local IsAnimatedMinimizeEnabled = ns.IsAnimatedMinimizeEnabled
local ApplyMainFrameLayout      = ns.ApplyMainFrameLayout
local RestoreFramePos           = ns.RestoreManagedFramePos or ns.RestoreFramePos

local function GetFontSize()
    if type(ns.GetFontSize) == "function" then
        return ns.GetFontSize()
    end

    if MR and MR.db and MR.db.profile and MR.db.profile.fontSize then
        return MR.db.profile.fontSize
    end

    return 11
end

local function GetFontFlags()
    if type(ns.GetFontFlags) == "function" then
        local flags = ns.GetFontFlags(MR.GetActiveMediaSettings and MR:GetActiveMediaSettings() or (MR.db and MR.db.profile))
        if flags ~= nil then
            return flags
        end
    end

    return "OUTLINE"
end

local function GetLocaleFont()
    if type(STANDARD_TEXT_FONT) == "string" and STANDARD_TEXT_FONT ~= "" then
        return STANDARD_TEXT_FONT
    end
    if GameFontNormal and GameFontNormal.GetFont then
        local f = GameFontNormal:GetFont()
        if type(f) == "string" and f ~= "" then return f end
    end
    if ns.GetDefaultFontTexture then
        local f = ns.GetDefaultFontTexture()
        if type(f) == "string" and f ~= "" then return f end
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function RefreshFonts()
    if ns.EnsureFonts then
        FONT_HEADERS, FONT_ROWS = ns.EnsureFonts()
    end
    local loc = GetLocaleFont()
    if not FONT_ROWS    or FONT_ROWS    == "" then FONT_ROWS    = loc end
    if not FONT_HEADERS or FONT_HEADERS == "" then FONT_HEADERS = loc end
end

local function SetWindowLayoutValue(key, value)
    if MR and MR.SetWindowLayoutValue then
        MR:SetWindowLayoutValue(key, value)
    end
end

local function RefreshVisualSettings()
    if MR and MR.RefreshMainPanelSectionsOnly and MR:RefreshMainPanelSectionsOnly() then
        if MR.RefreshVisibleDetachedFrames then
            MR:RefreshVisibleDetachedFrames()
        end
    elseif MR and MR.RefreshUI then
        MR:RefreshUI()
    end
    if collectgarbage then collectgarbage("step", 80) end
end

local function ScheduleSettingsGarbageCollect()
    if not (MR and MR.ScheduleTimer and collectgarbage) then
        return
    end

    MR._settingsGCToken = (MR._settingsGCToken or 0) + 1
    local token = MR._settingsGCToken
    MR:ScheduleTimer(function()
        if MR._settingsGCToken == token then
            collectgarbage("collect")
        end
    end, 0.75)
end

function MR:GetConfigFrame()
    return cfgFrame
end
function MR:ToggleConfig()
    if cfgFrame and cfgFrame:IsShown() then cfgFrame:Hide() return end
    if not cfgFrame then cfgFrame = self:BuildConfigFrame() end
    if self.RefreshStoryCampaignRegistration then
        self:RefreshStoryCampaignRegistration()
    end
    self:PopulateConfigFrame(cfgFrame)
    cfgFrame:Show()
end

function MR:IsConfigShown()
    return cfgFrame and cfgFrame:IsShown() or false
end

function MR:EnsureConfigShown()
    if not cfgFrame then
        cfgFrame = self:BuildConfigFrame()
    end
    self:PopulateConfigFrame(cfgFrame)
    cfgFrame:Show()
end

function MR:HideConfig()
    if cfgFrame then cfgFrame:Hide() end
end

local function GetCapturedBindingText(key)
    if GetBindingText then
        local text = GetBindingText(key, "KEY_")
        if text and text ~= "" then return text end
    end
    return key
end

local function BuildCapturedBinding(key)
    local prefix = ""
    if IsAltKeyDown and IsAltKeyDown() then prefix = prefix .. "ALT-" end
    if IsControlKeyDown and IsControlKeyDown() then prefix = prefix .. "CTRL-" end
    if IsShiftKeyDown and IsShiftKeyDown() then prefix = prefix .. "SHIFT-" end
    if IsMetaKeyDown and IsMetaKeyDown() then prefix = prefix .. "META-" end
    return prefix .. key
end

local function RefreshKeyBindingPage()
    if cfgFrame and cfgFrame:IsShown() then
        MR:PopulateConfigFrame(cfgFrame)
    end
end

local function ClearToggleWindowsBinding()
    local first, second = GetBindingKey(TOGGLE_WINDOWS_BINDING)
    if first then SetBinding(first) end
    if second then SetBinding(second) end
    SaveBindings(GetCurrentBindingSet())
    RefreshKeyBindingPage()
end

local function EnsureKeybindCaptureFrame()
    if keybindCaptureFrame then return keybindCaptureFrame end

    local capture = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    capture:SetAllPoints(UIParent)
    capture:SetFrameStrata("FULLSCREEN_DIALOG")
    capture:SetFrameLevel(500)
    capture:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    capture:SetBackdropColor(0, 0, 0, 0)
    capture:EnableMouse(true)
    capture:EnableMouseWheel(true)
    capture:EnableKeyboard(true)
    capture:SetPropagateKeyboardInput(false)
    capture:Hide()

    local panel = CreateFrame("Frame", nil, capture, "BackdropTemplate")
    panel:SetSize(320, 172)
    panel:SetPoint("CENTER")
    panel:SetBackdrop(MakeBackdrop())
    panel:SetBackdropColor(0.03, 0.07, 0.13, 1)
    panel:SetBackdropBorderColor(0.16, 0.78, 0.75, 1)
    panel:EnableMouse(false)

    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_HEADERS, 14, GetFontFlags())
    title:SetPoint("TOP", panel, "TOP", 0, -22)
    title:SetText(L["Config_SetKeyBinding"] or "Set Show / Hide Key")
    title:SetTextColor(0.16, 0.91, 0.78)

    local prompt = panel:CreateFontString(nil, "OVERLAY")
    prompt:SetFont(FONT_ROWS, 11, GetFontFlags())
    prompt:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -56)
    prompt:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -24, -56)
    prompt:SetJustifyH("CENTER")
    prompt:SetWordWrap(true)
    prompt:SetText(L["Config_KeyBindingPrompt"] or "Press any key, mouse button, or scroll the mouse wheel. Modifiers may be held.")
    prompt:SetTextColor(0.92, 0.95, 1)

    local status = panel:CreateFontString(nil, "OVERLAY")
    status:SetFont(FONT_ROWS, 10, GetFontFlags())
    status:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 24, 22)
    status:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -24, 22)
    status:SetJustifyH("CENTER")
    status:SetWordWrap(true)
    status:SetText(L["Config_KeyBindingCancel"] or "Escape cancels. Backspace clears the binding.")
    status:SetTextColor(0.62, 0.68, 0.76)

    capture.status = status
    capture.pendingKey = nil

    local function FinishCapture()
        capture.pendingKey = nil
        capture:Hide()
        RefreshKeyBindingPage()
    end

    local function SaveCapturedBinding(key)
        if InCombatLockdown and InCombatLockdown() then
            print((L["Binding_Header"] or "Routine") .. ": " .. (L["Config_KeyBindingsCombat"] or "Key bindings cannot be changed during combat."))
            FinishCapture()
            return
        end

        local action = GetBindingAction(key)
        if action and action ~= "" and action ~= TOGGLE_WINDOWS_BINDING then
            if capture.pendingKey ~= key then
                capture.pendingKey = key
                local actionName = GetBindingName and GetBindingName(action) or action
                capture.status:SetText((L["Config_KeyBindingConflict"] or "%s is already assigned to %s. Press it again to replace that binding."):format(GetCapturedBindingText(key), actionName))
                capture.status:SetTextColor(1, 0.62, 0.20)
                return
            end
        end

        local first, second = GetBindingKey(TOGGLE_WINDOWS_BINDING)
        if first and first ~= key then SetBinding(first) end
        if second and second ~= key then SetBinding(second) end
        if not SetBinding(key, TOGGLE_WINDOWS_BINDING) then
            capture.pendingKey = nil
            capture.status:SetText(L["Config_KeyBindingFailed"] or "That binding could not be saved. Try another key.")
            capture.status:SetTextColor(1, 0.32, 0.28)
            return
        end
        SaveBindings(GetCurrentBindingSet())
        FinishCapture()
    end

    local function CaptureKey(key)
        if key == "ESCAPE" then
            FinishCapture()
            return
        end
        if key == "BACKSPACE" then
            ClearToggleWindowsBinding()
            FinishCapture()
            return
        end
        if MODIFIER_KEYS[key] or key == "UNKNOWN" then return end
        SaveCapturedBinding(BuildCapturedBinding(key))
    end

    capture:SetScript("OnKeyDown", function(_, key)
        CaptureKey(key)
    end)
    capture:SetScript("OnMouseDown", function(_, button)
        local number = button and button:match("^Button(%d+)$")
        CaptureKey(MOUSE_BUTTON_KEYS[button] or (number and ("BUTTON" .. number)) or string.upper(button or "UNKNOWN"))
    end)
    capture:SetScript("OnMouseWheel", function(_, delta)
        CaptureKey(delta > 0 and "MOUSEWHEELUP" or "MOUSEWHEELDOWN")
    end)
    capture:SetScript("OnShow", function()
        capture.pendingKey = nil
        capture.status:SetText(L["Config_KeyBindingCancel"] or "Escape cancels. Backspace clears the binding.")
        capture.status:SetTextColor(0.62, 0.68, 0.76)
        capture:EnableKeyboard(true)
        capture:EnableMouseWheel(true)
        capture:SetPropagateKeyboardInput(false)
    end)
    capture:SetScript("OnHide", function()
        capture:EnableKeyboard(false)
        capture:EnableMouseWheel(false)
    end)

    keybindCaptureFrame = capture
    return capture
end

function MR:ShowToggleWindowsKeybindDialog()
    if InCombatLockdown and InCombatLockdown() then
        print((L["Binding_Header"] or "Routine") .. ": " .. (L["Config_KeyBindingsCombat"] or "Key bindings cannot be changed during combat."))
        return
    end
    EnsureKeybindCaptureFrame():Show()
end

function MR:BuildConfigFrame()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetWidth(344)
    self:RegisterPriorityFrame(f)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(f) end
    f:SetBackdropColor(0.03, 0.06, 0.12, 0.98)
    f:SetBackdropBorderColor(0.08, 0.18, 0.22, 0.78)
    f:Hide()
    if MR.frame then
        f:SetPoint("TOPLEFT", MR.frame, "TOPRIGHT", 4, 0)
    else
        f:SetPoint("CENTER")
    end

    local tbar = TitleBar(f, 22)
    tbar:SetBackdropColor(0.035, 0.075, 0.145, 1)
    tbar:SetScript("OnDragStart", function() f:StartMoving() end)
    tbar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(ns.FONT_HEADERS, 11, GetFontFlags())
    ttitle:SetText(L["Config_Title"])
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)
    ttitle:SetTextColor(1.00, 0.56, 0.08)
    f.titleText = ttitle
    f.titleBar = tbar

    local titleEdge = tbar:CreateTexture(nil, "ARTWORK")
    titleEdge:SetPoint("BOTTOMLEFT", tbar, "BOTTOMLEFT", 0, 0)
    titleEdge:SetPoint("BOTTOMRIGHT", tbar, "BOTTOMRIGHT", 0, 0)
    titleEdge:SetHeight(1)
    titleEdge:SetColorTexture(0.10, 0.24, 0.30, 0.85)

    CloseButton(tbar, function() f:Hide() end)

    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -22)
    scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 0)
    local scrollContent = CreateFrame("Frame", nil, scroll)
    scrollContent:SetSize(f:GetWidth() or 344, 1)

    local track = CreateFrame("Frame", nil, f)
    track:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -25)
    track:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
    track:SetWidth(4)

    if ns.AttachScrollList then
        f.UpdateScrollBar = ns.AttachScrollList(scroll, scrollContent, track)
        f.scroll = scroll
        f.scrollTrack = track
    else
        scroll:Hide()
        track:Hide()
    end

    return f
end


ns.ConfigInternal = {
    L = L,
    PANEL_MIN_WIDTH = PANEL_MIN_WIDTH,
    PANEL_MAX_WIDTH = PANEL_MAX_WIDTH,
    PANEL_MIN_HEIGHT = PANEL_MIN_HEIGHT,
    PANEL_MAX_HEIGHT = PANEL_MAX_HEIGHT,
    FONT_SIZE_MIN = FONT_SIZE_MIN,
    FONT_SIZE_MAX = FONT_SIZE_MAX,
    DAY_SECONDS = DAY_SECONDS,
    GetFontSize = GetFontSize,
    GetFontFlags = GetFontFlags,
    RefreshFonts = RefreshFonts,
    SetWindowLayoutValue = SetWindowLayoutValue,
    RefreshVisualSettings = RefreshVisualSettings,
    ScheduleSettingsGarbageCollect = ScheduleSettingsGarbageCollect,
    RestoreFramePos = RestoreFramePos,
}

function MR:RequestConfigRepopulate(frame, delay)
    if type(frame) ~= "table" or type(frame.IsShown) ~= "function" then
        frame = cfgFrame
    end
    if not frame or not frame:IsShown() then
        return
    end

    if not self.ScheduleTimer then
        self:PopulateConfigFrame(frame)
        return
    end

    delay = tonumber(delay) or 0.04
    self._configRepopulatePendingFrame = frame
    if self._configRepopulateTimer and self.CancelTimer then
        self:CancelTimer(self._configRepopulateTimer)
        self._configRepopulateTimer = nil
    end

    self._configRepopulateTimer = self:ScheduleTimer(function()
        local target = self._configRepopulatePendingFrame
        self._configRepopulateTimer = nil
        self._configRepopulatePendingFrame = nil
        if target and type(target.IsShown) == "function" and target:IsShown() then
            self:PopulateConfigFrame(target)
        end
    end, delay)
end

function MR:RepopulateConfigFrame()
    if cfgFrame and cfgFrame:IsShown() then
        self:PopulateConfigFrame(cfgFrame)
    end
end
