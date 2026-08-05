local _, ns = ...
local MR = ns.MR

local cfgFrame
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

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
local hex                       = ns.Hex
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

local function ReleaseConfigWidgetTree(frame)
    if not frame then
        return
    end

    if frame._mrExternalFrames then
        for _, external in ipairs(frame._mrExternalFrames) do
            ReleaseConfigWidgetTree(external)
        end
        frame._mrExternalFrames = nil
    end

    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        ReleaseConfigWidgetTree(child)
    end

    if frame.GetObjectType and frame:GetObjectType() == "Button" then
        frame:SetScript("OnClick", nil)
        frame:SetScript("OnEnter", nil)
        frame:SetScript("OnLeave", nil)
        frame:SetScript("OnMouseDown", nil)
        frame:SetScript("OnMouseUp", nil)
    end

    frame:SetScript("OnUpdate", nil)
    frame:EnableMouse(false)
    frame:Hide()
    frame:SetParent(nil)
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

function MR:BuildConfigFrame()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetWidth(344)
    f:SetFrameStrata("HIGH")
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
    tbar:SetBackdropColor(0.06, 0.10, 0.20, 1)
    tbar:SetScript("OnDragStart", function() f:StartMoving() end)
    tbar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(FONT_HEADERS, 11, GetFontFlags())
    ttitle:SetText(L["Config_Title"])
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)
    f.titleText = ttitle
    f.titleBar = tbar

    local closeBtn = CloseButton(tbar, function() f:Hide() end)

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
    ReleaseConfigWidgetTree = ReleaseConfigWidgetTree,
    RestoreFramePos = RestoreFramePos,
}

function MR:RequestConfigRepopulate(frame, delay)
    -- Core callers historically pass a reason string here, while config controls
    -- pass the frame directly. Treat anything that is not a frame as the
    -- default config frame so either call form remains safe.
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
