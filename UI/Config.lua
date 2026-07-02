local _, ns = ...
local MR = ns.MR

local F = _G.Foundry_1_0

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
        local flags = ns.GetFontFlags()
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

local function ReleaseConfigWidgetTree(frame)
    if not frame then
        return
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

        if frame.menuCtrl then
            frame.menuCtrl:Destroy()
            frame.menuCtrl = nil
        end
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
    f:SetWidth(292)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(f) end
    f:SetBackdropColor(0.03, 0.06, 0.12, 0.98)
    f:SetBackdropBorderColor(0.4, 0.28, 0, 1)
    f:Hide()
    if MR.frame then
        f:SetPoint("TOPLEFT", MR.frame, "TOPRIGHT", 4, 0)
    else
        f:SetPoint("CENTER")
    end

    local tbar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    tbar:SetPoint("TOPLEFT")
    tbar:SetPoint("TOPRIGHT")
    tbar:SetHeight(22)
    tbar:SetBackdrop(MakeBackdrop(false))
    if ns.HookBackdropFrame then ns.HookBackdropFrame(tbar) end
    tbar:SetBackdropColor(0.06, 0.10, 0.20, 1)
    tbar:EnableMouse(true)
    tbar:RegisterForDrag("LeftButton")
    tbar:SetScript("OnDragStart", function() f:StartMoving() end)
    tbar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(FONT_HEADERS, 11, GetFontFlags())
    ttitle:SetText(L["Config_Title"])
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)
    f.titleText = ttitle
    f.titleBar = tbar

    local closeBtn = CloseButton(tbar, function() f:Hide() end)

    return f
end

function MR:PopulateConfigFrame(f)
    if f.body then
        ReleaseConfigWidgetTree(f.body)
        f.body = nil
    end

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    body:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.body = body

    local yOff = -26
    local cfgFs = GetFontSize()
    local contentW = (f:GetWidth() or 292) - 16
    local activePage = MR._cfgPage or "windows"

    if activePage ~= "windows" and activePage ~= "layout" and activePage ~= "modules" and activePage ~= "reset" then
        activePage = "windows"
        MR._cfgPage = activePage
    end

    local function Gap(h)          yOff = OptionsGap(body, yOff, h) end
    local function Divider()       yOff = OptionsDivider(body, yOff, 4) end
    local function SectionLabel(t) yOff = OptionsSectionLabel(body, yOff, t, 8, cfgFs) end
    local function Checkbox(label, getVal, setVal, color)
        local r, g, b
        if color then r, g, b = hex(color) end
        yOff = OptionsCheckbox(body, yOff, label, getVal, setVal, r, g, b, 4, nil, cfgFs)
    end
    local function Btn(label, onClick) yOff = OptionsBtn(body, yOff, label, onClick, math.max(192, contentW), 8, cfgFs) end
    local function ChoiceDropdown(label, choices, getVal, setVal, getResetValue)
        local current = getVal()
        local currentIndex = 1
        for index, choice in ipairs(choices) do
            if choice.value == current then
                currentIndex = index
                break
            end
        end

        local caption = body:CreateFontString(nil, "OVERLAY")
        caption:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
        caption:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        caption:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
        caption:SetJustifyH("LEFT")
        caption:SetWordWrap(false)
        caption:SetText("|cff888888" .. label .. "|r")

        yOff = yOff - 14

        local row = CreateFrame("Frame", nil, body)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        row:SetSize(contentW, 26)

        local valueBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        valueBtn:SetSize(math.max(170, contentW - 28), 20)
        valueBtn:SetPoint("LEFT", row, "LEFT", 0, 0)
        valueBtn:SetBackdrop(MakeBackdrop())
        valueBtn:SetBackdropColor(0.05, 0.12, 0.20, 0.95)
        valueBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

        local valueText = valueBtn:CreateFontString(nil, "OVERLAY")
        valueText:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
        valueText:SetPoint("LEFT", valueBtn, "LEFT", 8, 1)
        valueText:SetPoint("RIGHT", valueBtn, "RIGHT", -22, 1)
        valueText:SetJustifyH("LEFT")
        valueText:SetWordWrap(false)
        valueText:SetTextColor(0.76, 0.97, 0.94)

        local caret = valueBtn:CreateFontString(nil, "OVERLAY")
        caret:SetFont(FONT_HEADERS, 10, GetFontFlags())
        caret:SetPoint("RIGHT", valueBtn, "RIGHT", -7, 1)
        caret:SetText("v")
        caret:SetTextColor(0.78, 0.90, 0.92)

        local function ApplySelection(index, commit)
            currentIndex = index
            local selected = choices[currentIndex] or choices[1]
            valueText:SetText(selected.label)
            if commit ~= false then
                setVal(selected.value, selected)
            end
        end

        valueBtn:SetScript("OnEnter", function(selfBtn)
            selfBtn:SetBackdropColor(0.08, 0.18, 0.28, 0.98)
            selfBtn:SetBackdropBorderColor(0.26, 0.78, 0.72, 1)
        end)
        valueBtn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(0.05, 0.12, 0.20, 0.95)
            selfBtn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
        end)

        -- Popup mechanism (overflow scroll, outside-click dismiss, anchor
        -- clamping) is Foundry.Menu / Blizzard's native menu system. valueBtn
        -- stays a plain custom BackdropTemplate button (not a DropdownButton),
        -- so we drive the menu with :CreateContextMenu(owner) from OnClick
        -- rather than :SetupDropdown (which requires the DropdownButtonMixin
        -- SetupMenu API valueBtn does not have). Anonymous name: this widget
        -- is rebuilt every PopulateConfigFrame call, so a stable name would
        -- collide with the still-live controller from the previous populate.
        if F then
            local menuCtrl = F.Menu:New({
                builder = function(_, rootDescription)
                    rootDescription:CreateTitle(label)
                    for index, choice in ipairs(choices) do
                        rootDescription:CreateRadio(choice.label, function()
                            return index == currentIndex
                        end, function()
                            ApplySelection(index, true)
                        end)
                    end
                end,
            })
            -- Stored on valueBtn so ReleaseConfigWidgetTree can :Destroy() it on
            -- teardown -- this widget is rebuilt every PopulateConfigFrame call,
            -- and an undestroyed anonymous controller leaks its liveKeys entry.
            valueBtn.menuCtrl = menuCtrl
            valueBtn:SetScript("OnClick", function()
                if menuCtrl then
                    menuCtrl:CreateContextMenu(valueBtn)
                end
            end)
        end

        local resetBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
        resetBtn:SetSize(20, 20)
        resetBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)
        resetBtn:SetBackdrop(MakeBackdrop())
        resetBtn:SetBackdropColor(0.12, 0.04, 0.04, 1)
        resetBtn:SetBackdropBorderColor(0.45, 0.12, 0.12, 1)

        local resetText = resetBtn:CreateFontString(nil, "OVERLAY")
        resetText:SetFont(FONT_HEADERS, 10, GetFontFlags())
        resetText:SetPoint("CENTER", resetBtn, "CENTER", 0, 1)
        resetText:SetText("x")
        resetText:SetTextColor(0.75, 0.28, 0.28)

        resetBtn:SetScript("OnClick", function()
            local resetValue = getResetValue and getResetValue() or choices[1].value
            for index, choice in ipairs(choices) do
                if choice.value == resetValue then
                    ApplySelection(index, true)
                    return
                end
            end
            ApplySelection(1, true)
        end)

        ApplySelection(currentIndex, false)
        yOff = yOff - 34
    end

    local function MediaSelector(label, kind, getVal, setVal)
        local sharedMedia = ns.GetSharedMedia and ns.GetSharedMedia()
        local defaultLabel = kind == "font" and "Game Default" or "Midnight Default"
        local choices = {
            { label = defaultLabel, value = ns.MEDIA_DEFAULT_TOKEN },
        }
        local seen = { [defaultLabel] = true }
        if ns.GetSharedMediaList then
            for _, name in ipairs(ns.GetSharedMediaList(kind)) do
                if type(name) == "string" and name ~= "" and not seen[name] then
                    choices[#choices + 1] = { label = name, value = name }
                    seen[name] = true
                end
            end
        end

        ChoiceDropdown(label, choices,
            function()
                local current = getVal()
                if current == nil or current == ns.MEDIA_DEFAULT_TOKEN then
                    return ns.MEDIA_DEFAULT_TOKEN
                end
                return current
            end,
            function(value)
                local path
                if value and value ~= ns.MEDIA_DEFAULT_TOKEN and sharedMedia then
                    local mediaType = kind == "font" and sharedMedia.MediaType.FONT or sharedMedia.MediaType.BACKGROUND
                    path = sharedMedia:Fetch(mediaType, value, true)
                end
                if value == ns.MEDIA_DEFAULT_TOKEN and kind == "font" and ns.GetDefaultFontTexture then
                    path = ns.GetDefaultFontTexture()
                elseif value == ns.MEDIA_DEFAULT_TOKEN and kind == "background" and ns.GetDefaultBackgroundTexture then
                    path = ns.GetDefaultBackgroundTexture()
                end
                setVal(value, path)
            end,
            function()
                return ns.MEDIA_DEFAULT_TOKEN
            end)
    end
    local function SetLayoutMode(enabled)
        MR.db.profile.characterWindowLayout = enabled
        if MR.ApplySharedMediaSettings then
            MR:ApplySharedMediaSettings()
        end
        MR:RefreshUI()
        if MR.frame then
            ApplyMainFrameLayout(MR.frame)
        end
        if MR.raresFrame then
            MR.raresFrame:ClearAllPoints()
            RestoreFramePos(MR.raresFrame, "raresPos", 580, 0)
        end
        if MR.renownFrame then
            MR.renownFrame:ClearAllPoints()
            RestoreFramePos(MR.renownFrame, "renownPos", 300, 0)
        end
        if MR.gatheringLocationsFrame then
            MR.gatheringLocationsFrame:ClearAllPoints()
            RestoreFramePos(MR.gatheringLocationsFrame, "gatheringLocPos", 860, 0)
        end
        if MR.RebuildRaresFrame then
            MR:RebuildRaresFrame()
        end
        if MR.RebuildRenownFrame then
            MR:RebuildRenownFrame()
        end
        if MR.RebuildGatheringLocationsFrame then
            MR:RebuildGatheringLocationsFrame()
        end
        MR:PopulateConfigFrame(f)
    end

    do
        local tabs = {
            { key = "windows", label = L["Config_TabWindows"] or "Windows" },
            { key = "layout",  label = L["Config_TabLayout"]  or "Layout"  },
            { key = "modules", label = L["Config_TabModules"] or "Modules" },
            { key = "reset",   label = L["Config_TabReset"]   or "Reset"   },
        }
        local tabW = math.floor((contentW - 6) / #tabs)
        local tabY = yOff
        for i, tab in ipairs(tabs) do
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(tabW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", 8 + (i - 1) * (tabW + 2), tabY)
            btn:SetBackdrop(MakeBackdrop())
            local isActive = activePage == tab.key
            btn:SetBackdropColor(isActive and 0.11 or 0.05, isActive and 0.24 or 0.09, isActive and 0.23 or 0.15, 1)
            btn:SetBackdropBorderColor(isActive and 0.22 or 0.16, isActive and 0.82 or 0.28, isActive and 0.70 or 0.36, 1)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
            lbl:SetPoint("CENTER")
            lbl:SetText(tab.label)
            lbl:SetTextColor(isActive and 0.85 or 0.62, isActive and 1.0 or 0.75, isActive and 0.92 or 0.70)

            btn:SetScript("OnClick", function()
                MR._cfgPage = tab.key
                MR:PopulateConfigFrame(f)
            end)
            btn:SetScript("OnEnter", function()
                if activePage ~= tab.key then
                    btn:SetBackdropColor(0.08, 0.18, 0.24, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.90, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = (MR._cfgPage or "windows") == tab.key
                btn:SetBackdropColor(selected and 0.11 or 0.05, selected and 0.24 or 0.09, selected and 0.23 or 0.15, 1)
                btn:SetBackdropBorderColor(selected and 0.22 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.85 or 0.62, selected and 1.0 or 0.75, selected and 0.92 or 0.70)
            end)
        end
        yOff = yOff - 26
    end

    f:SetScript("OnUpdate", nil)

    if activePage == "windows" then
        SectionLabel(L["Title"])
        Checkbox(L["Config_ShowMainFrame"],
            function() return MR.frame and MR.frame:IsShown() or false end,
            function(v)
                if v then
                    if not MR.frame then
                        MR:BuildUI()
                    elseif not MR.frame:IsShown() then
                        MR.frame:Show()
                    end
                    MR.db.char.panelOpen = true
                    if MR.ClearManagedWindowsBundleHidden then
                        MR:ClearManagedWindowsBundleHidden()
                    end
                else
                    if MR.frame then
                        MR.frame:Hide()
                    end
                    MR.db.char.panelOpen = false
                end
            end, "#2ae7c6")

        Checkbox(L["Config_OpenRenown"],
            function() return MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("renownOpen") end,
            function(v)
                if MR.SetManagedWindowOpen then
                    MR:SetManagedWindowOpen("renownOpen", v)
                end
                if MR.ToggleRenown then MR:ToggleRenown() end
            end, "#d9b82e")

        Checkbox(L["Config_OpenRares"],
            function() return MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("raresOpen") end,
            function(v)
                if MR.SetManagedWindowOpen then
                    MR:SetManagedWindowOpen("raresOpen", v)
                end
                if MR.ToggleRares then MR:ToggleRares() end
            end, "#e05050")

        Checkbox(L["Profession_Knowledge"],
            function() return MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("gatheringLocOpen") end,
            function(v)
                if MR.SetManagedWindowOpen then
                    MR:SetManagedWindowOpen("gatheringLocOpen", v)
                end
                if MR.ToggleGatheringLocations then MR:ToggleGatheringLocations() end
            end, "#c9853f")

        Gap(4); Divider()
        SectionLabel(L["OPTIONS"])
        Checkbox(L["Config_HideWhenCompleted"],
            function() return MR.db.char.hideComplete end,
            function(v)
                local moduleStorage = MR:GetActiveModuleStorage()
                MR.db.char.hideComplete = v
                for _, mod in ipairs(MR.modules) do
                    if moduleStorage and moduleStorage[mod.key] then
                        moduleStorage[mod.key].hideComplete = nil
                    end
                end
                if MR.RequestConfigRefresh then
                    MR:RequestConfigRefresh()
                else
                    MR:RefreshUI()
                end
            end)
        Checkbox(L["Config_HideCurrenciesWhenCompleted"] or "Hide Currencies When Completed",
            function() return MR:IsModuleHideComplete("currencies") end,
            function(v)
                MR:SetModuleHideComplete("currencies", v and true or false, true)
                if MR.RequestConfigRefresh then
                    MR:RequestConfigRefresh()
                else
                    MR:RefreshUI()
                end
            end)
        Checkbox(L["Config_LockFrame"],
            function() return MR.db.profile.locked end,
            function(v)
                MR.db.profile.locked = v
                MR.frame:SetMovable(not v)
            end)
        Checkbox(L["Config_HideMinimap"],
            function() return MR.db.profile.minimap and MR.db.profile.minimap.hide or false end,
            function(v) MR:SetMinimapHidden(v) end)
        Checkbox(L["Config_HideInInstances"],
            function() return MR.db.profile.hideFramesInInstances end,
            function(v)
                MR.db.profile.hideFramesInInstances = v
                if MR.UpdateInstanceFrameVisibility then
                    MR:UpdateInstanceFrameVisibility()
                end
            end)
        Checkbox(L["Config_RememberManagedWindowsVisibility"],
            function() return MR.db.profile.rememberManagedWindowsVisibility end,
            function(v)
                MR.db.profile.rememberManagedWindowsVisibility = v and true or false
                if not MR.db.profile.rememberManagedWindowsVisibility then
                    MR.db.profile.managedWindowsBundleHidden = false
                    MR:RefreshUI()
                end
            end)
        Checkbox(L["Config_PeekOnHover"],
            function() return MR.db.profile.peekOnHover end,
            function(v) MR:ApplyPeekOnHover(v) end)
        Checkbox(L["Config_AutoHidePanelHeaders"],
            function() return MR.db.profile.autoHidePanelHeaders end,
            function(v)
                MR.db.profile.autoHidePanelHeaders = v
                if MR.frame and MR.frame.UpdatePanelHeaderVisibility then
                    MR.frame:UpdatePanelHeaderVisibility(MR.frame:IsMouseOver())
                end
                if MR.renownFrame and MR.renownFrame.UpdatePanelHeaderVisibility then
                    MR.renownFrame:UpdatePanelHeaderVisibility(MR.renownFrame:IsMouseOver())
                end
                if MR.raresFrame and MR.raresFrame.UpdatePanelHeaderVisibility then
                    MR.raresFrame:UpdatePanelHeaderVisibility(MR.raresFrame:IsMouseOver())
                end
                if MR.gatheringLocationsFrame and MR.gatheringLocationsFrame.UpdatePanelHeaderVisibility then
                    MR.gatheringLocationsFrame:UpdatePanelHeaderVisibility(MR.gatheringLocationsFrame:IsMouseOver())
                end
            end)
        Gap(4); Divider()
        SectionLabel(L["GreatVault_Title"])
        Checkbox(L["Config_CompactGreatVault"],
            function() return MR.db and MR.db.profile and MR.db.profile.greatVaultCombined == true end,
            function(v)
                MR.db.profile.greatVaultCombined = v and true or false
                MR:RefreshUI()
            end, "#ff8000")
    elseif activePage == "layout" then
        SectionLabel(L["Config_LayoutMode"] or "Layout Mode")

        local modeY = yOff - 4
        local modeBtnW = math.floor((contentW - 2) / 2)
        local function CreateModeButton(label, enabled, x)
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(modeBtnW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", x, modeY)
            btn:SetBackdrop(MakeBackdrop())
            local active = MR.db.profile.characterWindowLayout == enabled
            btn:SetBackdropColor(active and 0.12 or 0.05, active and 0.30 or 0.09, active and 0.24 or 0.16, 1)
            btn:SetBackdropBorderColor(active and 0.24 or 0.16, active and 0.82 or 0.28, active and 0.70 or 0.36, 1)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
            lbl:SetPoint("CENTER")
            lbl:SetText(label)
            lbl:SetTextColor(active and 0.92 or 0.70, active and 1.0 or 0.78, active and 0.94 or 0.74)

            btn:SetScript("OnClick", function() SetLayoutMode(enabled) end)
            btn:SetScript("OnEnter", function()
                if MR.db.profile.characterWindowLayout ~= enabled then
                    btn:SetBackdropColor(0.08, 0.20, 0.25, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.92, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = MR.db.profile.characterWindowLayout == enabled
                btn:SetBackdropColor(selected and 0.12 or 0.05, selected and 0.30 or 0.09, selected and 0.24 or 0.16, 1)
                btn:SetBackdropBorderColor(selected and 0.24 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.92 or 0.70, selected and 1.0 or 0.78, selected and 0.94 or 0.74)
            end)
        end

        CreateModeButton(L["Config_LayoutShared"] or "Shared", false, 8)
        CreateModeButton(L["Config_LayoutCharacter"] or "Per Character", true, 8 + modeBtnW + 2)
        yOff = yOff - 30

        Divider()
        SectionLabel(L["Config_Display"])

        yOff = OptionsSlider(body, yOff, L["WIDTH"], PANEL_MIN_WIDTH, PANEL_MAX_WIDTH, 10,
            function() return MR.db.profile.width or 260 end,
            function(v)
                MR.ApplyWidth(v)
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate(f, 0.08)
                else
                    MR:PopulateConfigFrame(f)
                end
            end,
            0.16, 0.78, 0.75, 8, nil, cfgFs)

        Gap(6)
        yOff = OptionsSlider(body, yOff, L["HEIGHT"], PANEL_MIN_HEIGHT, PANEL_MAX_HEIGHT, 10,
            function() return MR.db.profile.height or 400 end,
            function(v)
                MR.ApplyHeight(v)
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate(f, 0.08)
                else
                    MR:PopulateConfigFrame(f)
                end
            end,
            0.16, 0.75, 0.78, 8, nil, cfgFs)

        Gap(6)
        yOff = OptionsSlider(body, yOff, L["SCALE"], 0.5, 2.0, 0.05,
            function() return MR.db.profile.scale or 1.0 end,
            function(v)
                if MR.db.profile.syncWindowScale then
                    MR:ApplyScaleToAll(v)
                else
                    MR.db.profile.scale = v
                    if MR.frame then MR.frame:SetScale(v) end
                end
            end,
            0.55, 0.22, 0.82, 8, nil, cfgFs)

        Gap(2)
        yOff = OptionsCheckbox(body, yOff, L["Config_SyncScale"],
            function() return MR.db.profile.syncWindowScale end,
            function(v)
                MR.db.profile.syncWindowScale = v
                if v then MR:ApplyScaleToAll(MR.db.profile.scale or 1.0) end
                MR:PopulateConfigFrame(f)
            end,
            0.55, 0.22, 0.82, 8, nil, cfgFs)

        Gap(4); Divider()
        SectionLabel(L["Config_MainHeaderPosition"] or "Main Header Position")

        local headerModeY = yOff - 4
        local headerModeBtnW = math.floor((contentW - 2) / 2)
        local function CreateHeaderModeButton(label, value, x)
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(headerModeBtnW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", x, headerModeY)
            btn:SetBackdrop(MakeBackdrop())
            local active = GetMainHeaderPosition() == value
            btn:SetBackdropColor(active and 0.12 or 0.05, active and 0.30 or 0.09, active and 0.24 or 0.16, 1)
            btn:SetBackdropBorderColor(active and 0.24 or 0.16, active and 0.82 or 0.28, active and 0.70 or 0.36, 1)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
            lbl:SetPoint("CENTER")
            lbl:SetText(label)
            lbl:SetTextColor(active and 0.92 or 0.70, active and 1.0 or 0.78, active and 0.94 or 0.74)

            btn:SetScript("OnClick", function()
                if GetMainHeaderPosition() == value then
                    return
                end
                SetWindowLayoutValue("mainHeaderPosition", value)
                ApplyMainFrameLayout(MR.frame, true)
                MR:RefreshUI()
                if MR.RebuildRaresFrame then
                    MR:RebuildRaresFrame()
                end
                if MR.RebuildRenownFrame then
                    MR:RebuildRenownFrame()
                end
                if MR.RebuildGatheringLocationsFrame then
                    MR:RebuildGatheringLocationsFrame()
                end
                MR:PopulateConfigFrame(f)
            end)
            btn:SetScript("OnEnter", function()
                if GetMainHeaderPosition() ~= value then
                    btn:SetBackdropColor(0.08, 0.20, 0.25, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.92, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = GetMainHeaderPosition() == value
                btn:SetBackdropColor(selected and 0.12 or 0.05, selected and 0.30 or 0.09, selected and 0.24 or 0.16, 1)
                btn:SetBackdropBorderColor(selected and 0.24 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.92 or 0.70, selected and 1.0 or 0.78, selected and 0.94 or 0.74)
            end)
        end

        CreateHeaderModeButton(L["Config_MainHeaderTop"] or "Top / Grow Down", "top", 8)
        CreateHeaderModeButton(L["Config_MainHeaderBottom"] or "Bottom / Grow Up", "bottom", 8 + headerModeBtnW + 2)
        yOff = yOff - 30

        Gap(2)
        yOff = OptionsCheckbox(body, yOff,
            L["Config_ShowMainCharacterBar"] or "Show Character Switcher Bar",
            function() return MR.db.profile.showMainCharacterBar ~= false end,
            function(v)
                MR.db.profile.showMainCharacterBar = v and true or false
                if not v and MR.HideMainAltPicker then
                    MR:HideMainAltPicker()
                end
                if MR.RefreshMainHeaderChrome then
                    MR:RefreshMainHeaderChrome()
                elseif MR.frame then
                    ApplyMainFrameLayout(MR.frame, true)
                end
                MR:RefreshUI()
            end,
            0.16, 0.78, 0.75, 8, nil, cfgFs)

        Gap(2)
        yOff = OptionsCheckbox(body, yOff,
            L["Config_AnimatedMinimize"] or "Animated Minimize / Restore",
            function() return IsAnimatedMinimizeEnabled() end,
            function(v)
                SetWindowLayoutValue("animatedMinimize", v and true or false)
            end,
            0.55, 0.22, 0.82, 8, nil, cfgFs)

        Gap(4); Divider()

        Gap(6)
        yOff = OptionsSlider(body, yOff, L["Config_FontSize"], FONT_SIZE_MIN, FONT_SIZE_MAX, 1,
            function() return GetFontSize() end,
            function(v)
                if MR.db.profile.syncWindowFontSize then
                    MR:ApplyFontSizeToAll(math.floor(v))
                else
                    MR.ApplyFontSize(math.floor(v))
                end
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate(f, 0.08)
                else
                    MR:PopulateConfigFrame(f)
                end
            end,
            0.78, 0.55, 0.16, 8, nil, cfgFs)

        local presets = { {"S", 9}, {"M", 11}, {"L", 14}, {"XL", 17} }
        local btnW = math.floor((contentW - 6) / #presets)
        for i, p in ipairs(presets) do
            local pb = CreateFrame("Button", nil, body, "BackdropTemplate")
            pb:SetSize(btnW, 16)
            pb:SetPoint("TOPLEFT", body, "TOPLEFT", 8 + (i - 1) * (btnW + 2), yOff - 18)
            pb:SetBackdrop(MakeBackdrop())
            local isActive = (GetFontSize() == p[2])
            pb:SetBackdropColor(isActive and 0.12 or 0.05, isActive and 0.35 or 0.10, isActive and 0.32 or 0.18, 1)
            pb:SetBackdropBorderColor(isActive and 0.25 or 0.18, isActive and 0.85 or 0.40, isActive and 0.70 or 0.45, 1)
            local pfs = pb:CreateFontString(nil, "OVERLAY")
            pfs:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
            pfs:SetPoint("CENTER")
            pfs:SetText(p[1])
            pfs:SetTextColor(isActive and 0.2 or 0.6, isActive and 0.95 or 0.75, isActive and 0.75 or 0.65)
            pb:SetScript("OnClick", function()
                if MR.db.profile.syncWindowFontSize then
                    MR:ApplyFontSizeToAll(p[2])
                else
                    MR.ApplyFontSize(p[2])
                end
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate(f, 0.08)
                else
                    MR:PopulateConfigFrame(f)
                end
            end)
            pb:SetScript("OnEnter", function()
                pb:SetBackdropColor(0.10, 0.28, 0.28, 1)
                pb:SetBackdropBorderColor(0.25, 0.90, 0.75, 1)
            end)
            pb:SetScript("OnLeave", function()
                pb:SetBackdropColor(isActive and 0.12 or 0.05, isActive and 0.35 or 0.10, isActive and 0.32 or 0.18, 1)
                pb:SetBackdropBorderColor(isActive and 0.25 or 0.18, isActive and 0.85 or 0.40, isActive and 0.70 or 0.45, 1)
            end)
        end

        yOff = yOff - 40

        Gap(2)
        yOff = OptionsCheckbox(body, yOff, L["Config_SyncFontSize"],
            function() return MR.db.profile.syncWindowFontSize end,
            function(v)
                MR.db.profile.syncWindowFontSize = v
                if v then MR:ApplyFontSizeToAll(GetFontSize()) end
                MR:PopulateConfigFrame(f)
            end,
            0.78, 0.55, 0.16, 8, nil, cfgFs)

        Gap(4); Divider()
        SectionLabel(L["Config_SharedMedia"] or "Shared Media")
        MediaSelector(L["Config_Font"] or "Font", "font",
            function() return MR.GetMediaSetting and MR:GetMediaSetting("fontMedia") or MR.db.profile.fontMedia end,
            function(value, path)
                if MR.SetMediaSetting then
                    MR:SetMediaSetting("fontMedia", value)
                    MR:SetMediaSetting("fontMediaPath", path)
                else
                    MR.db.profile.fontMedia = value
                    MR.db.profile.fontMediaPath = path
                end
                MR:ApplySharedMediaSettings()
            end)
        ChoiceDropdown(L["Config_FontStyle"] or "Font Style", {
                { label = L["Config_FontStyleOutline"] or "Outline", value = "OUTLINE" },
                { label = L["Config_FontStyleNone"] or "None", value = "" },
                { label = L["Config_FontStyleThick"] or "Thick Outline", value = "THICKOUTLINE" },
                { label = L["Config_FontStyleMono"] or "Monochrome", value = "MONOCHROME" },
                { label = L["Config_FontStyleMonoOutline"] or "Monochrome Outline", value = "OUTLINE, MONOCHROME" },
                { label = L["Config_FontStyleMonoThick"] or "Monochrome Thick Outline", value = "THICKOUTLINE, MONOCHROME" },
            },
            function()
                if ns.GetFontFlags then
                    return ns.GetFontFlags(MR.GetActiveMediaSettings and MR:GetActiveMediaSettings() or MR.db.profile)
                end
                return MR.GetMediaSetting and MR:GetMediaSetting("fontFlags") or MR.db.profile.fontFlags or "OUTLINE"
            end,
            function(value)
                if MR.SetMediaSetting then
                    MR:SetMediaSetting("fontFlags", value)
                else
                    MR.db.profile.fontFlags = value
                end
                MR:ApplySharedMediaSettings()
            end,
            function()
                return "OUTLINE"
            end)
        MediaSelector(L["Config_BackgroundTexture"] or "Background texture", "background",
            function() return MR.GetMediaSetting and MR:GetMediaSetting("backgroundMedia") or MR.db.profile.backgroundMedia end,
            function(value, path)
                if MR.SetMediaSetting then
                    MR:SetMediaSetting("backgroundMedia", value)
                    MR:SetMediaSetting("backgroundMediaPath", path)
                else
                    MR.db.profile.backgroundMedia = value
                    MR.db.profile.backgroundMediaPath = path
                end
                MR:ApplySharedMediaSettings()
            end)

        Gap(4)
        yOff = OptionsSlider(body, yOff, L["BACKGROUND"], 0, 1, 0.05,
            function() return MR.db.profile.frameAlpha or 1.0 end,
            function(v)
                MR.db.profile.frameAlpha = v
                if MR.ApplyTheme then MR.ApplyTheme() end
                MR:RefreshUI()
            end,
            0.40, 0.40, 0.40, 8, nil, cfgFs)

        Gap(2)
        yOff = OptionsCheckbox(body, yOff,
            L["Config_ShowIcons"] or "Show Icons",
            function() return MR.db.profile.keepIconsVisibleInTextMode ~= false end,
            function(v)
                MR.db.profile.keepIconsVisibleInTextMode = v
                MR:RefreshUI()
            end,
            0.40, 0.40, 0.40, 8, nil, cfgFs)

        Gap(2)
        yOff = OptionsCheckbox(body, yOff,
            L["Config_ShowSectionHeaders"] or "Show Section Headers",
            function() return MR.db.profile.keepHeadersVisibleInTextMode ~= false end,
            function(v)
                MR.db.profile.keepHeadersVisibleInTextMode = v
                MR:RefreshUI()
            end,
            0.40, 0.40, 0.40, 8, nil, cfgFs)
    end

    if activePage == "modules" then
        Gap(4); Divider()
        SectionLabel(L["Config_ModuleSettings"])

    if not MR._cfgExpanded then MR._cfgExpanded = {} end

    local function ApplyToggleButtonState(btn, fs, active)
        if not (btn and fs) then
            return
        end

        btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
        btn:SetBackdropBorderColor(
            active and 0.15 or 0.35,
            active and 0.32 or 0.12,
            active and 0.38 or 0.12, 1)
        fs:SetText(active and "H" or "S")
        fs:SetTextColor(
            active and 0.45 or 0.55,
            active and 0.75 or 0.25,
            active and 0.70 or 0.25)
    end

    local function BuildHideCompleteBtn(parent, key, anchorRight)
        local hideActive = MR:IsModuleHideComplete(key)
        local isCurrencyModule = key == "currencies" or key == "pvp_currencies"
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(16, 16)
        if anchorRight == parent then
            btn:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
        else
            btn:SetPoint("RIGHT", anchorRight, "LEFT", -2, 0)
        end
        btn:SetBackdrop(MakeBackdrop())
        btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
        btn:SetBackdropBorderColor(
            hideActive and 0.15 or 0.35,
            hideActive and 0.32 or 0.12,
            hideActive and 0.38 or 0.12, 1)
        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT_ROWS, 8, GetFontFlags())
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
        ApplyToggleButtonState(btn, fs, hideActive)
        btn:SetScript("OnClick", function()
            local active = not MR:IsModuleHideComplete(key)
            MR:SetModuleHideComplete(key, active, true)
            ApplyToggleButtonState(btn, fs, active)
            if MR.RequestConfigRefresh then
                MR:RequestConfigRefresh()
            else
                MR:RefreshUI()
            end
        end)
        btn:SetScript("OnEnter", function()
            btn:SetBackdropColor(0.08, 0.22, 0.32, 1)
            btn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
            fs:SetTextColor(1, 1, 1)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            if isCurrencyModule then
                GameTooltip:SetText(
                    MR:IsModuleHideComplete(key)
                        and "Hide Currencies When Completed enabled - capped currencies will be hidden"
                        or "Hide Currencies When Completed disabled - currencies stay visible at cap",
                    1, 1, 1
                )
            else
                GameTooltip:SetText(MR:IsModuleHideComplete(key) and L["Config_RowsCollapsed"] or L["Config_RowsShown"], 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            local active = MR:IsModuleHideComplete(key)
            btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
            btn:SetBackdropBorderColor(active and 0.15 or 0.35, active and 0.32 or 0.12, active and 0.38 or 0.12, 1)
            fs:SetTextColor(active and 0.45 or 0.55, active and 0.75 or 0.25, active and 0.70 or 0.25)
            GameTooltip:Hide()
        end)
        return btn
    end

    local function BuildColorSwatch(parent, key, mod, anchorRight)
        local currentColor = MR:GetHeaderColor(key)
        local r, g, b = hex(currentColor or mod.labelColor or "#ffffff")
        local swatch = OptionsColorSwatch(parent, r, g, b,
            function(nr, ng, nb)
                local hx = string.format("#%02x%02x%02x", nr*255, ng*255, nb*255)
                MR:SetHeaderColor(key, hx)
            end,
            function()
                MR:ResetHeaderColor(key)
                local dr, dg, db = hex(mod.labelColor or "#ffffff")
                MR:PopulateConfigFrame(f)
                return dr, dg, db
            end,
            L["Config_HeaderColor"])
        swatch:SetPoint("RIGHT", anchorRight, "LEFT", -2, 0)
        return swatch
    end

    local function BuildHeaderBackgroundSwatch(parent, key, anchorRight)
        local currentColor = MR.GetHeaderBackgroundColor and MR:GetHeaderBackgroundColor(key) or nil
        local r, g, b = 0.08, 0.09, 0.12
        if currentColor then
            r, g, b = hex(currentColor)
        end
        local swatch = OptionsColorSwatch(parent, r, g, b,
            function(nr, ng, nb)
                local hx = string.format("#%02x%02x%02x", nr*255, ng*255, nb*255)
                MR:SetHeaderBackgroundColor(key, hx)
            end,
            function()
                MR:ResetHeaderBackgroundColor(key)
                MR:PopulateConfigFrame(f)
                return 0.08, 0.09, 0.12
            end,
            L["Config_HeaderBackgroundColor"] or "Header Background")
        swatch:SetPoint("RIGHT", anchorRight, "LEFT", -2, 0)
        return swatch
    end

    local drag = { active = false, srcKey = nil, targetIdx = nil }

    local dragGhost = CreateFrame("Frame", nil, body, "BackdropTemplate")
    dragGhost:SetHeight(20)
    dragGhost:SetFrameStrata("DIALOG")
    dragGhost:SetBackdrop(MakeBackdrop())
    dragGhost:SetBackdropColor(0.08, 0.28, 0.22, 0.95)
    dragGhost:SetBackdropBorderColor(0.2, 0.9, 0.65, 1)
    dragGhost:Hide()
    local dragGhostLbl = dragGhost:CreateFontString(nil, "OVERLAY")
    dragGhostLbl:SetFont(FONT_HEADERS, 10, GetFontFlags())
    dragGhostLbl:SetPoint("LEFT", dragGhost, "LEFT", 8, 0)
    dragGhostLbl:SetTextColor(0.3, 1, 0.75)

    local dragLine = CreateFrame("Frame", nil, body)
    dragLine:SetHeight(2)
    dragLine:SetFrameStrata("DIALOG")
    dragLine:Hide()
    local dragLineTex = dragLine:CreateTexture(nil, "OVERLAY")
    dragLineTex:SetAllPoints()
    dragLineTex:SetColorTexture(0.2, 0.9, 0.65, 1)

    local orderedMods = MR:GetOrderedModules()
    local orderIndex = {}
    for index, mod in ipairs(orderedMods) do
        orderIndex[mod.key] = index
    end

    local _allMods = {}
    for _, mod in ipairs(orderedMods) do
        _allMods[#_allMods + 1] = mod
    end
    table.sort(_allMods, function(a, b)
        local ao = MR.GetPatchSortOrder and MR:GetPatchSortOrder(MR:GetModulePatchKey(a)) or 999999
        local bo = MR.GetPatchSortOrder and MR:GetPatchSortOrder(MR:GetModulePatchKey(b)) or 999999
        if ao ~= bo then
            return ao < bo
        end
        return (orderIndex[a.key] or 9999) < (orderIndex[b.key] or 9999)
    end)

    local _cfgRows = {}

    local function FormatReleaseSuffix(patchKey)
        if not patchKey then
            return nil
        end
        local patchInfo = MR:GetPatchInfo(patchKey)
        return "|cff667788(" .. (patchInfo.shortLabel or patchInfo.key or patchKey) .. ")|r"
    end

    local function FormatModuleConfigLabel(mod)
        local suffix = FormatReleaseSuffix(MR:GetModulePatchKey(mod))
        if suffix then
            return string.format("%s  %s", mod.label or mod.key, suffix)
        end
        return mod.label or mod.key
    end

    local function FormatRowConfigLabel(mod, row)
        local cleanLabel = (row.label or row.key):gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
        local suffix = FormatReleaseSuffix(MR:GetRowPatchKey(mod, row))
        if suffix then
            return string.format("%s  %s", cleanLabel, suffix)
        end
        return cleanLabel
    end

    local function BuildPatchHeader(patchKey)
        local patchInfo = MR:GetPatchInfo(patchKey)
        local enabled = MR:IsPatchEnabled(patchKey)
        local ROW_H = 22
        local patchFr = CreateFrame("Frame", nil, body, "BackdropTemplate")
        patchFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
        patchFr:SetSize(contentW, ROW_H)
        patchFr:SetBackdrop(MakeBackdrop())
        patchFr:SetBackdropColor(enabled and 0.07 or 0.08, enabled and 0.17 or 0.07, enabled and 0.22 or 0.08, 0.95)
        patchFr:SetBackdropBorderColor(enabled and 0.20 or 0.35, enabled and 0.62 or 0.18, enabled and 0.70 or 0.18, 1)

        local cb = CreateFrame("CheckButton", nil, patchFr, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("LEFT", patchFr, "LEFT", 2, 0)
        cb:SetChecked(enabled)
        cb:SetScript("OnClick", function(s)
            MR:SetPatchEnabled(patchKey, s:GetChecked(), true)
            if MR.RequestConfigRefresh then
                MR:RequestConfigRefresh()
            else
                MR:RefreshUI()
            end
        end)

        local lbl = patchFr:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT_HEADERS, 10, GetFontFlags())
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        lbl:SetPoint("RIGHT", patchFr, "RIGHT", -8, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetText((patchInfo.label or patchKey) .. "  |cff667788" .. (L["Config_PatchFilter"] or "Patch filter") .. "|r")
        lbl:SetTextColor(enabled and 0.82 or 0.45, enabled and 0.98 or 0.48, enabled and 0.95 or 0.50)

        yOff = yOff - ROW_H
    end

    local function GetConfigRowsForModule(mod)
        local orderedRows = MR.GetOrderedRows and MR:GetOrderedRows(mod) or (mod.rows or {})
        local rows = {}
        for _, row in ipairs(orderedRows) do
            if not row.control then
                rows[#rows + 1] = row
            end
        end

        return rows
    end

    local function BuildRowPatchHeader(patchKey)
        local patchInfo = MR:GetPatchInfo(patchKey)
        local enabled = MR:IsPatchEnabled(patchKey)
        local ROW_H = 18
        local patchFr = CreateFrame("Frame", nil, body, "BackdropTemplate")
        patchFr:SetPoint("TOPLEFT", body, "TOPLEFT", 18, yOff)
        patchFr:SetSize(contentW - 20, ROW_H)
        patchFr:SetBackdrop(MakeBackdrop())
        patchFr:SetBackdropColor(enabled and 0.05 or 0.07, enabled and 0.13 or 0.06, enabled and 0.16 or 0.07, 0.88)
        patchFr:SetBackdropBorderColor(enabled and 0.16 or 0.30, enabled and 0.42 or 0.16, enabled and 0.48 or 0.16, 0.9)

        local cb = CreateFrame("CheckButton", nil, patchFr, "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("LEFT", patchFr, "LEFT", 0, 0)
        cb:SetChecked(enabled)
        cb:SetScript("OnClick", function(s)
            MR:SetPatchEnabled(patchKey, s:GetChecked(), true)
            if MR.RequestConfigRefresh then
                MR:RequestConfigRefresh()
            else
                MR:RefreshUI()
            end
        end)

        local lbl = patchFr:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT_HEADERS, 9, GetFontFlags())
        lbl:SetPoint("LEFT", cb, "RIGHT", 1, 0)
        lbl:SetPoint("RIGHT", patchFr, "RIGHT", -6, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetText((patchInfo.label or patchKey) .. "  |cff667788" .. (L["Config_PatchFilter"] or "Patch filter") .. "|r")
        lbl:SetTextColor(enabled and 0.72 or 0.42, enabled and 0.90 or 0.46, enabled and 0.88 or 0.48)

        yOff = yOff - ROW_H
    end

    local function DragOnUpdate()
        if not drag.active then return end
        local rows = _cfgRows
        if #rows == 0 then return end

        local cx, cy = GetCursorPosition()
        local scale  = body:GetEffectiveScale()
        local bLeft  = body:GetLeft()
        local bTop   = body:GetTop()
        if not bLeft or not bTop then return end
        local localX = cx / scale - bLeft
        local localY = bTop - cy / scale

        dragGhost:ClearAllPoints()
        dragGhost:SetPoint("TOPLEFT",  body, "TOPLEFT", 4,       -localY + 10)
        dragGhost:SetPoint("TOPRIGHT", body, "TOPRIGHT", -4,     -localY + 10)
        dragGhost:Show()

        local screenCY = cy / UIParent:GetEffectiveScale()
        local slot = #rows
        for i, row in ipairs(rows) do
            local rTop = row.frame:GetTop()
            local rBot = row.frame:GetBottom()
            if rTop and rBot then
                local mid = (rTop + rBot) / 2
                if screenCY > mid then
                    slot = i - 1
                    break
                end
            end
        end
        slot = math.max(0, math.min(slot, #rows))
        drag.targetIdx = slot

        local lineRefFrame
        local lineAtBottom = false
        if slot == 0 then
            lineRefFrame = rows[1].frame
            lineAtBottom = false
        elseif slot >= #rows then
            lineRefFrame = rows[#rows].frame
            lineAtBottom = true
        else
            lineRefFrame = rows[slot].frame
            lineAtBottom = true
        end

        if lineRefFrame then
            local lY = lineAtBottom and (lineRefFrame:GetBottom() or 0) or (lineRefFrame:GetTop() or 0)
            local lLeft  = lineRefFrame:GetLeft()  or 0
            local lRight = lineRefFrame:GetRight() or 0
            local bodyTop   = body:GetTop() or 0
            local bodyLeft  = body:GetLeft() or 0
            local lineBodyY = -(bodyTop - lY)
            local lineBodyL = lLeft - bodyLeft
            local lineBodyR = lRight - bodyLeft
            dragLine:ClearAllPoints()
            dragLine:SetPoint("TOPLEFT",  body, "TOPLEFT", lineBodyL, lineBodyY)
            dragLine:SetPoint("TOPRIGHT", body, "TOPLEFT", lineBodyR, lineBodyY)
            dragLine:Show()
        end

        for _, row in ipairs(rows) do
            row.frame:SetAlpha(row.key == drag.srcKey and 0.3 or 1.0)
        end
    end

    f:SetScript("OnUpdate", function()
        if drag.active then DragOnUpdate() end
    end)

    local function CommitDrag()
        if not drag.active then return end
        drag.active = false
        for _, row in ipairs(_cfgRows) do row.frame:SetAlpha(1) end
        dragGhost:Hide()
        dragLine:Hide()

        local slot = drag.targetIdx
        if slot == nil then MR:PopulateConfigFrame(f); return end

        local allMods = MR:GetOrderedModules()
        local visMods = {}
        for _, row in ipairs(_cfgRows) do
            for _, m in ipairs(allMods) do
                if m.key == row.key then table.insert(visMods, m); break end
            end
        end
        local srcIdx = nil
        for i, m in ipairs(visMods) do
            if m.key == drag.srcKey then srcIdx = i; break end
        end
        if not srcIdx then MR:PopulateConfigFrame(f); return end

        local insertAt = slot + 1
        if srcIdx < insertAt then insertAt = insertAt - 1 end
        insertAt = math.max(1, math.min(insertAt, #visMods))

        if srcIdx ~= insertAt then
            local moved = table.remove(visMods, srcIdx)
            table.insert(visMods, insertAt, moved)
            local inCfgRows = {}
            for _, row in ipairs(_cfgRows) do inCfgRows[row.key] = true end
            local newOrder = {}
            local vi = 1
            for _, m in ipairs(allMods) do
                if inCfgRows[m.key] then
                    table.insert(newOrder, visMods[vi].key); vi = vi + 1
                else
                    table.insert(newOrder, m.key)
                end
            end
            MR:SetModuleOrder(newOrder)
            MR:RefreshUI()
        end
        drag.srcKey = nil; drag.targetIdx = nil
        MR:PopulateConfigFrame(f)
    end

    local lastPatchKey
    for _, mod in ipairs(_allMods) do
        local key = mod.key
        local optVisible = not mod.isVisible or mod:isVisible()
        local patchKey = MR:GetModulePatchKey(mod)

        if optVisible and patchKey and patchKey ~= lastPatchKey then
            BuildPatchHeader(patchKey)
            lastPatchKey = patchKey
        end

        if mod.profSkillLine then
            if MR.playerProfessions[mod.profSkillLine] then
                local ROW_H = 22
                local headerFr = CreateFrame("Frame", nil, body)
                headerFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
                headerFr:SetSize(contentW, ROW_H)

                local grip = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
                grip:SetSize(16, ROW_H - 2)
                grip:SetPoint("LEFT", headerFr, "LEFT", 1, 0)
                grip:RegisterForClicks("LeftButtonUp")
                grip:SetBackdrop(MakeBackdrop())
                grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
                grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
                local gripLbl = grip:CreateFontString(nil, "OVERLAY")
                gripLbl:SetFont(FONT_HEADERS, 13, GetFontFlags())
                gripLbl:SetPoint("CENTER", grip, "CENTER", 0, 0)
                gripLbl:SetText("=")
                gripLbl:SetTextColor(0.50, 0.75, 0.68)
                grip:SetScript("OnEnter", function()
                    if not drag.active then
                        gripLbl:SetTextColor(0.3, 1, 0.8)
                        grip:SetBackdropColor(0.15, 0.35, 0.30, 0.9)
                        grip:SetBackdropBorderColor(0.3, 1, 0.75, 1)
                    end
                end)
                grip:SetScript("OnLeave", function()
                    if not drag.active then
                        gripLbl:SetTextColor(0.50, 0.75, 0.68)
                        grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
                        grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
                    end
                end)
                grip:SetScript("OnMouseDown", function()
                    if drag.active then return end
                    drag.active = true
                    drag.srcKey = key
                    drag.targetIdx = nil
                    dragGhostLbl:SetText(mod.label)
                end)
                grip:SetScript("OnClick", function()
                    if drag.active then CommitDrag() end
                end)
                table.insert(_cfgRows, { key = key, frame = headerFr, label = mod.label })

                local cb = CreateFrame("CheckButton", nil, headerFr, "UICheckButtonTemplate")
                cb:SetSize(20, 20)
                cb:SetPoint("LEFT", headerFr, "LEFT", 18, 0)
                cb:SetChecked(MR:IsModuleEnabled(key))
                cb:SetScript("OnClick", function(s)
                    MR:SetModuleEnabled(key, s:GetChecked(), true)
                    if MR.RequestConfigRefresh then
                        MR:RequestConfigRefresh()
                    else
                        MR:RefreshUI()
                    end
                end)

                local isExp = MR._cfgExpanded[key]
                local arrowBtn = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
                arrowBtn:SetSize(16, 16)
                arrowBtn:SetPoint("RIGHT", headerFr, "RIGHT", 0, 0)
                arrowBtn:SetBackdrop(MakeBackdrop())
                arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                arrowBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
                local arrowLbl = arrowBtn:CreateFontString(nil, "OVERLAY")
                arrowLbl:SetFont(FONT_HEADERS, 10, GetFontFlags())
                arrowLbl:SetPoint("CENTER", arrowBtn, "CENTER", 0, 1)
                arrowLbl:SetText(isExp and "v" or ">")
                arrowLbl:SetTextColor(0.45, 0.75, 0.70)
                arrowBtn:SetScript("OnClick", function()
                    MR._cfgExpanded[key] = not MR._cfgExpanded[key]
                    if MR.RequestConfigRepopulate then
                        MR:RequestConfigRepopulate(f, 0.04)
                    else
                        MR:PopulateConfigFrame(f)
                    end
                end)
                arrowBtn:SetScript("OnEnter", function()
                    arrowBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
                    arrowBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
                    arrowLbl:SetTextColor(1, 1, 1)
                    GameTooltip:SetOwner(arrowBtn, "ANCHOR_RIGHT")
                    GameTooltip:SetText(L["Config_ExpandCollapseRows"], 1, 1, 1)
                    GameTooltip:Show()
                end)
                arrowBtn:SetScript("OnLeave", function()
                    arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                    arrowBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
                    arrowLbl:SetTextColor(0.45, 0.75, 0.70)
                    GameTooltip:Hide()
                end)

                local hideBtn = BuildHideCompleteBtn(headerFr, key, arrowBtn)
                local bgSwatch = BuildHeaderBackgroundSwatch(headerFr, key, hideBtn)
                local colorSwatch = BuildColorSwatch(headerFr, key, mod, bgSwatch)

                local lbl = headerFr:CreateFontString(nil, "OVERLAY")
                lbl:SetFont(FONT_ROWS, 10, GetFontFlags())
                lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
                lbl:SetPoint("RIGHT", colorSwatch, "LEFT", -2, 0)
                lbl:SetText(FormatModuleConfigLabel(mod))
                lbl:SetJustifyH("LEFT")
                local customColor = MR:GetHeaderColor(key)
                if customColor or mod.labelColor then
                    lbl:SetTextColor(hex(customColor or mod.labelColor))
                else
                    lbl:SetTextColor(0.88, 0.88, 0.88)
                end

                yOff = yOff - ROW_H

                if MR._cfgExpanded[key] then
                    local guide = body:CreateTexture(nil, "ARTWORK")
                    guide:SetWidth(1)
                    guide:SetColorTexture(0.20, 0.55, 0.50, 0.35)

                    local guideTopY = yOff

                    local lastRowPatchKey
                    for _, row in ipairs(GetConfigRowsForModule(mod)) do
                        local rowPatchKey = MR:GetRowPatchKey(mod, row)
                        if rowPatchKey and rowPatchKey ~= lastRowPatchKey then
                            BuildRowPatchHeader(rowPatchKey)
                            lastRowPatchKey = rowPatchKey
                        end
                        local rkey    = row.key
                        local enabled = MR:IsRowEnabled(key, rkey)

                        local rowFr = CreateFrame("Frame", nil, body)
                        rowFr:SetPoint("TOPLEFT", body, "TOPLEFT", 18, yOff)
                        rowFr:SetSize(contentW - 20, 18)

                        local rdot = rowFr:CreateTexture(nil, "ARTWORK")
                        rdot:SetSize(5, 5)
                        rdot:SetPoint("LEFT", rowFr, "LEFT", 0, 0)
                        rdot:SetColorTexture(hex(MR:GetRowColor(key, rkey) or MR:GetHeaderColor(key)))
                        rdot:SetAlpha(enabled and 0.8 or 0.25)

                        local rlbl = rowFr:CreateFontString(nil, "OVERLAY")
                        rlbl:SetFont(FONT_ROWS, 9, GetFontFlags())
                        rlbl:SetPoint("LEFT", rowFr, "LEFT", 10, 0)
                        rlbl:SetPoint("RIGHT", rowFr, "RIGHT", -32, 0)
                        rlbl:SetJustifyH("LEFT")
                        rlbl:SetText(FormatRowConfigLabel(mod, row))
                        if not enabled then
                            rlbl:SetTextColor(0.35, 0.35, 0.35)
                        else
                            local rRowCustom    = MR:GetRowColor(key, rkey)
                            local rHeaderCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[key]
                            local rEffective    = rRowCustom or rHeaderCustom
                            if rEffective then
                                rlbl:SetTextColor(hex(rEffective))
                            else
                                rlbl:SetTextColor(0.80, 0.80, 0.80)
                            end
                        end

                        local eyeBtn = CreateFrame("Button", nil, rowFr, "BackdropTemplate")
                        eyeBtn:SetSize(14, 14)
                        eyeBtn:SetPoint("RIGHT", rowFr, "RIGHT", 0, 0)
                        eyeBtn:SetBackdrop(MakeBackdrop())
                        eyeBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                        eyeBtn:SetBackdropBorderColor(
                            enabled and 0.15 or 0.35,
                            enabled and 0.32 or 0.12,
                            enabled and 0.38 or 0.12, 1)
                        local eyeLbl = eyeBtn:CreateFontString(nil, "OVERLAY")
                        eyeLbl:SetFont(FONT_ROWS, 9, GetFontFlags())
                        eyeLbl:SetPoint("CENTER", eyeBtn, "CENTER", 0, 0)
                        eyeLbl:SetText(enabled and "o" or "-")
                        eyeLbl:SetTextColor(
                            enabled and 0.25 or 0.55,
                            enabled and 0.85 or 0.25,
                            enabled and 0.70 or 0.25)

                        local function ApplyRowToggleState(isEnabled)
                            rdot:SetAlpha(isEnabled and 0.8 or 0.25)
                            if not isEnabled then
                                rlbl:SetTextColor(0.35, 0.35, 0.35)
                            else
                                local rRowCustom = MR:GetRowColor(key, rkey)
                                local rHeaderCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[key]
                                local rEffective = rRowCustom or rHeaderCustom
                                if rEffective then
                                    rlbl:SetTextColor(hex(rEffective))
                                else
                                    rlbl:SetTextColor(0.80, 0.80, 0.80)
                                end
                            end
                            eyeBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                            eyeBtn:SetBackdropBorderColor(
                                isEnabled and 0.15 or 0.35,
                                isEnabled and 0.32 or 0.12,
                                isEnabled and 0.38 or 0.12, 1)
                            eyeLbl:SetText(isEnabled and "o" or "-")
                            eyeLbl:SetTextColor(
                                isEnabled and 0.25 or 0.55,
                                isEnabled and 0.85 or 0.25,
                                isEnabled and 0.70 or 0.25)
                        end

                        eyeBtn:SetScript("OnClick", function()
                            enabled = not MR:IsRowEnabled(key, rkey)
                            MR:SetRowEnabled(key, rkey, enabled, true)
                            if MR.RequestConfigRefresh then
                                MR:RequestConfigRefresh()
                            else
                                MR:RefreshUI()
                            end
                            ApplyRowToggleState(enabled)
                        end)
                        eyeBtn:SetScript("OnEnter", function()
                            eyeBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
                            eyeBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
                            eyeLbl:SetTextColor(1, 1, 1)
                            GameTooltip:SetOwner(eyeBtn, "ANCHOR_RIGHT")
                            GameTooltip:SetText(enabled and L["Config_HideRow"] or L["Config_ShowRow"], 1, 1, 1)
                            GameTooltip:Show()
                        end)
                        eyeBtn:SetScript("OnLeave", function()
                            ApplyRowToggleState(enabled)
                            GameTooltip:Hide()
                        end)

                        local rsr, rsg, rsb = hex(MR:GetRowColor(key, rkey) or MR:GetHeaderColor(key))
                        local rowSwatch = OptionsColorSwatch(rowFr, rsr, rsg, rsb,
                            function(nr, ng, nb)
                                local hx = string.format("#%02x%02x%02x", nr*255, ng*255, nb*255)
                                MR:SetRowColor(key, rkey, hx)
                            end,
                            function()
                                MR:ResetRowColor(key, rkey)
                                return hex(MR:GetHeaderColor(key))
                            end,
                            L["Config_RowColor"])
                        rowSwatch:SetSize(14, 14)
                        rowSwatch:SetPoint("RIGHT", eyeBtn, "LEFT", -2, 0)

                        yOff = yOff - 19
                    end

                    if yOff == guideTopY then
                        guide:Hide()
                    else
                        guide:SetPoint("TOPLEFT",    body, "TOPLEFT", 14, guideTopY)
                        guide:SetPoint("BOTTOMLEFT", body, "TOPLEFT", 14, yOff + 4)
                    end

                    Gap(3)
                end
            end

        elseif optVisible then
            local ROW_H = 22
            local headerFr = CreateFrame("Frame", nil, body)
            headerFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
            headerFr:SetSize(contentW, ROW_H)

            local cb = CreateFrame("CheckButton", nil, headerFr, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("LEFT", headerFr, "LEFT", 18, 0)
            cb:SetChecked(MR:IsModuleEnabled(key))
            cb:SetScript("OnClick", function(s)
                MR:SetModuleEnabled(key, s:GetChecked(), true)
                if MR.RequestConfigRefresh then
                    MR:RequestConfigRefresh()
                else
                    MR:RefreshUI()
                end
            end)

            local isExp = MR._cfgExpanded[key]
            local arrowBtn = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
            arrowBtn:SetSize(16, 16)
            arrowBtn:SetPoint("RIGHT", headerFr, "RIGHT", 0, 0)
            arrowBtn:SetBackdrop(MakeBackdrop())
            arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
            arrowBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
            local arrowLbl = arrowBtn:CreateFontString(nil, "OVERLAY")
            arrowLbl:SetFont(FONT_HEADERS, 10, GetFontFlags())
            arrowLbl:SetPoint("CENTER", arrowBtn, "CENTER", 0, 1)
            arrowLbl:SetText(isExp and "v" or ">")
            arrowLbl:SetTextColor(0.45, 0.75, 0.70)
            arrowBtn:SetScript("OnClick", function()
                MR._cfgExpanded[key] = not MR._cfgExpanded[key]
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate(f, 0.04)
                else
                    MR:PopulateConfigFrame(f)
                end
            end)
            arrowBtn:SetScript("OnEnter", function()
                arrowBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
                arrowBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
                arrowLbl:SetTextColor(1, 1, 1)
                GameTooltip:SetOwner(arrowBtn, "ANCHOR_RIGHT")
                GameTooltip:SetText(L["Config_ExpandCollapseRows"], 1, 1, 1)
                GameTooltip:Show()
            end)
            arrowBtn:SetScript("OnLeave", function()
                arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                arrowBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
                arrowLbl:SetTextColor(0.45, 0.75, 0.70)
                GameTooltip:Hide()
            end)

            local grip = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
            grip:SetSize(16, ROW_H - 2)
            grip:SetPoint("LEFT", headerFr, "LEFT", 1, 0)
            grip:RegisterForClicks("LeftButtonUp")
            grip:SetBackdrop(MakeBackdrop())
            grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
            grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
            local gripLbl = grip:CreateFontString(nil, "OVERLAY")
            gripLbl:SetFont(FONT_HEADERS, 13, GetFontFlags())
            gripLbl:SetPoint("CENTER", grip, "CENTER", 0, 0)
            gripLbl:SetText("=")
            gripLbl:SetTextColor(0.50, 0.75, 0.68)
            grip:SetScript("OnEnter", function()
                if not drag.active then
                    gripLbl:SetTextColor(0.3, 1, 0.8)
                    grip:SetBackdropColor(0.15, 0.35, 0.30, 0.9)
                    grip:SetBackdropBorderColor(0.3, 1, 0.75, 1)
                end
            end)
            grip:SetScript("OnLeave", function()
                if not drag.active then
                    gripLbl:SetTextColor(0.50, 0.75, 0.68)
                    grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
                    grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
                end
            end)
            grip:SetScript("OnMouseDown", function()
                if drag.active then return end
                drag.active = true
                drag.srcKey = key
                drag.targetIdx = nil
                dragGhostLbl:SetText(mod.label)
            end)
            grip:SetScript("OnClick", function()
                if drag.active then CommitDrag() end
            end)
            table.insert(_cfgRows, { key = key, frame = headerFr, label = mod.label })

            local hideBtn = BuildHideCompleteBtn(headerFr, key, arrowBtn)
            local bgSwatch = BuildHeaderBackgroundSwatch(headerFr, key, hideBtn)
            local colorSwatch = BuildColorSwatch(headerFr, key, mod, bgSwatch)

            local lbl = headerFr:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, 10, GetFontFlags())
            lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
            lbl:SetPoint("RIGHT", colorSwatch, "LEFT", -2, 0)
            lbl:SetText(FormatModuleConfigLabel(mod))
            lbl:SetJustifyH("LEFT")
            local customColor = MR:GetHeaderColor(key)
            if customColor or mod.labelColor then
                lbl:SetTextColor(hex(customColor or mod.labelColor))
            else
                lbl:SetTextColor(0.88, 0.88, 0.88)
            end

            yOff = yOff - ROW_H

            if MR._cfgExpanded[key] then
                local guide = body:CreateTexture(nil, "ARTWORK")
                guide:SetWidth(1)
                guide:SetColorTexture(0.20, 0.55, 0.50, 0.35)

                local guideTopY = yOff

                local lastRowPatchKey
                for _, row in ipairs(GetConfigRowsForModule(mod)) do
                    local rowPatchKey = MR:GetRowPatchKey(mod, row)
                    if rowPatchKey and rowPatchKey ~= lastRowPatchKey then
                        BuildRowPatchHeader(rowPatchKey)
                        lastRowPatchKey = rowPatchKey
                    end
                    local rkey    = row.key
                    local enabled = MR:IsRowEnabled(key, rkey)

                    local rowFr = CreateFrame("Frame", nil, body)
                    rowFr:SetPoint("TOPLEFT", body, "TOPLEFT", 18, yOff)
                    rowFr:SetSize(contentW - 20, 18)

                    local rdot = rowFr:CreateTexture(nil, "ARTWORK")
                    rdot:SetSize(5, 5)
                    rdot:SetPoint("LEFT", rowFr, "LEFT", 0, 0)
                    rdot:SetColorTexture(hex(MR:GetRowColor(key, rkey) or MR:GetHeaderColor(key)))
                    rdot:SetAlpha(enabled and 0.8 or 0.25)

                    local rlbl = rowFr:CreateFontString(nil, "OVERLAY")
                    rlbl:SetFont(FONT_ROWS, 9, GetFontFlags())
                    rlbl:SetPoint("LEFT", rowFr, "LEFT", 10, 0)
                    rlbl:SetPoint("RIGHT", rowFr, "RIGHT", -32, 0)
                    rlbl:SetJustifyH("LEFT")
                    rlbl:SetText(FormatRowConfigLabel(mod, row))
                    if not enabled then
                        rlbl:SetTextColor(0.35, 0.35, 0.35)
                    else
                        local rRowCustom    = MR:GetRowColor(key, rkey)
                        local rHeaderCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[key]
                        local rEffective    = rRowCustom or rHeaderCustom
                        if rEffective then
                            rlbl:SetTextColor(hex(rEffective))
                        else
                            rlbl:SetTextColor(0.80, 0.80, 0.80)
                        end
                    end

                    local eyeBtn = CreateFrame("Button", nil, rowFr, "BackdropTemplate")
                    eyeBtn:SetSize(14, 14)
                    eyeBtn:SetPoint("RIGHT", rowFr, "RIGHT", 0, 0)
                    eyeBtn:SetBackdrop(MakeBackdrop())
                    eyeBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                    eyeBtn:SetBackdropBorderColor(
                        enabled and 0.15 or 0.35,
                        enabled and 0.32 or 0.12,
                        enabled and 0.38 or 0.12, 1)
                    local eyeLbl = eyeBtn:CreateFontString(nil, "OVERLAY")
                    eyeLbl:SetFont(FONT_ROWS, 9, GetFontFlags())
                    eyeLbl:SetPoint("CENTER", eyeBtn, "CENTER", 0, 0)
                    eyeLbl:SetText(enabled and "o" or "-")
                    eyeLbl:SetTextColor(
                        enabled and 0.25 or 0.55,
                        enabled and 0.85 or 0.25,
                        enabled and 0.70 or 0.25)

                    local function ApplyRowToggleState(isEnabled)
                        rdot:SetAlpha(isEnabled and 0.8 or 0.25)
                        if not isEnabled then
                            rlbl:SetTextColor(0.35, 0.35, 0.35)
                        else
                            local rRowCustom = MR:GetRowColor(key, rkey)
                            local rHeaderCustom = MR.db.profile.headerColors and MR.db.profile.headerColors[key]
                            local rEffective = rRowCustom or rHeaderCustom
                            if rEffective then
                                rlbl:SetTextColor(hex(rEffective))
                            else
                                rlbl:SetTextColor(0.80, 0.80, 0.80)
                            end
                        end
                        eyeBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                        eyeBtn:SetBackdropBorderColor(
                            isEnabled and 0.15 or 0.35,
                            isEnabled and 0.32 or 0.12,
                            isEnabled and 0.38 or 0.12, 1)
                        eyeLbl:SetText(isEnabled and "o" or "-")
                        eyeLbl:SetTextColor(
                            isEnabled and 0.25 or 0.55,
                            isEnabled and 0.85 or 0.25,
                            isEnabled and 0.70 or 0.25)
                    end

                    eyeBtn:SetScript("OnClick", function()
                        enabled = not MR:IsRowEnabled(key, rkey)
                        MR:SetRowEnabled(key, rkey, enabled, true)
                        if MR.RequestConfigRefresh then
                            MR:RequestConfigRefresh()
                        else
                            MR:RefreshUI()
                        end
                        ApplyRowToggleState(enabled)
                    end)
                    eyeBtn:SetScript("OnEnter", function()
                        eyeBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
                        eyeBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
                        eyeLbl:SetTextColor(1, 1, 1)
                        GameTooltip:SetOwner(eyeBtn, "ANCHOR_RIGHT")
                        GameTooltip:SetText(enabled and L["Config_HideRow"] or L["Config_ShowRow"], 1, 1, 1)
                        GameTooltip:Show()
                    end)
                    eyeBtn:SetScript("OnLeave", function()
                        ApplyRowToggleState(enabled)
                        GameTooltip:Hide()
                    end)

                    local rsr, rsg, rsb = hex(MR:GetRowColor(key, rkey) or MR:GetHeaderColor(key))
                    local rowSwatch = OptionsColorSwatch(rowFr, rsr, rsg, rsb,
                        function(nr, ng, nb)
                            local hx = string.format("#%02x%02x%02x", nr*255, ng*255, nb*255)
                            MR:SetRowColor(key, rkey, hx)
                        end,
                        function()
                            MR:ResetRowColor(key, rkey)
                            return hex(MR:GetHeaderColor(key))
                        end,
                        L["Config_RowColor"])
                    rowSwatch:SetSize(14, 14)
                    rowSwatch:SetPoint("RIGHT", eyeBtn, "LEFT", -2, 0)

                    yOff = yOff - 19
                end

                if yOff == guideTopY then
                    guide:Hide()
                else
                    guide:SetPoint("TOPLEFT",    body, "TOPLEFT", 14, guideTopY)
                    guide:SetPoint("BOTTOMLEFT", body, "TOPLEFT", 14, yOff + 4)
                end

                Gap(3)
            end
        end
    end
    end

    if activePage == "reset" then
        SectionLabel(L["RESETS"])
        Btn(L["Config_ResetEverything"], function()
            MR:ResetAllSettings()
            MR:PopulateConfigFrame(f)
        end)
        Btn(L["Config_ResetColors"], function()
            MR.db.profile.headerColors = {}
            MR.db.profile.headerBackgroundColors = {}
            MR.db.profile.rowColors = {}
            MR:RefreshUI()
            MR:PopulateConfigFrame(f)
        end)
        Btn(L["Config_ResetOrder"], function()
            if MR:IsCharacterWindowLayoutEnabled() then
                MR.db.char.moduleOrder = {}
            else
                MR.db.profile.moduleOrder = {}
            end
            MR._orderedModulesCache = nil
            MR:RefreshUI()
            MR:PopulateConfigFrame(f)
        end)
    end

    Gap(8)
    local totalH = math.abs(yOff) + 8
    body:SetHeight(totalH)
    f:SetHeight(totalH)
end

function MR:RequestConfigRepopulate(frame, delay)
    frame = frame or cfgFrame
    if not frame or not frame:IsShown() then
        return
    end

    delay = tonumber(delay) or 0.04
    self._configRepopulatePendingFrame = frame
    if self._configRepopulateTimer then
        self._configRepopulateTimer:Cancel()
        self._configRepopulateTimer = nil
    end

    self._configRepopulateTimer = C_Timer.NewTimer(delay, function()
        local target = self._configRepopulatePendingFrame
        self._configRepopulateTimer = nil
        self._configRepopulatePendingFrame = nil
        if target and target:IsShown() then
            self:PopulateConfigFrame(target)
        end
    end)
end

function MR:RepopulateConfigFrame()
    if cfgFrame and cfgFrame:IsShown() then
        self:PopulateConfigFrame(cfgFrame)
    end
end
