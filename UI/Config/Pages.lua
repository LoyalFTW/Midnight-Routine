local _, ns = ...
local MR = ns.MR
local Config = assert(ns.ConfigInternal, "UI/Config/Frame.lua must load first")
local L = Config.L
local PANEL_MIN_WIDTH = Config.PANEL_MIN_WIDTH
local PANEL_MAX_WIDTH = Config.PANEL_MAX_WIDTH
local PANEL_MIN_HEIGHT = Config.PANEL_MIN_HEIGHT
local PANEL_MAX_HEIGHT = Config.PANEL_MAX_HEIGHT
local FONT_SIZE_MIN = Config.FONT_SIZE_MIN
local FONT_SIZE_MAX = Config.FONT_SIZE_MAX
local DAY_SECONDS = Config.DAY_SECONDS
local FONT_ROWS = ns.FONT_ROWS
local FONT_HEADERS = ns.FONT_HEADERS
local MakeBackdrop = ns.MakeBackdrop
local OptionsGap = ns.OptionsGap
local OptionsDivider = ns.OptionsDivider
local OptionsSectionLabel = ns.OptionsSectionLabel
local OptionsCheckbox = ns.OptionsCheckbox
local OptionsBtn = ns.OptionsBtn
local OptionsSlider = ns.OptionsSlider
local OptionsColorSwatch = ns.OptionsColorSwatch
local ApplyBackgroundTexture = ns.ApplyBackgroundTexture
local hex = ns.Hex
local GetMainHeaderPosition = ns.GetMainHeaderPosition
local IsAnimatedMinimizeEnabled = ns.IsAnimatedMinimizeEnabled
local ApplyMainFrameLayout = ns.ApplyMainFrameLayout
local GetFontSize = Config.GetFontSize
local GetFontFlags = Config.GetFontFlags
local RefreshFonts = Config.RefreshFonts
local SetWindowLayoutValue = Config.SetWindowLayoutValue
local RefreshVisualSettings = Config.RefreshVisualSettings
local ScheduleSettingsGarbageCollect = Config.ScheduleSettingsGarbageCollect
local ReleaseConfigWidgetTree = Config.ReleaseConfigWidgetTree
local RestoreFramePos = Config.RestoreFramePos

function MR:PopulateConfigFrame(f)
    if f.body then
        ReleaseConfigWidgetTree(f.body)
        f.body = nil
    end

    local bodyParent = (f.scroll and f.scroll:GetScrollChild()) or f
    local body = CreateFrame("Frame", nil, bodyParent)
    body:SetPoint("TOPLEFT",  bodyParent, "TOPLEFT",  0, 0)
    body:SetPoint("TOPRIGHT", bodyParent, "TOPRIGHT", 0, 0)
    f.body = body

    local yOff = f.scroll and -4 or -26
    local cfgFs = GetFontSize()
    local moduleHeaderFs = math.max(FONT_SIZE_MIN, cfgFs - 1)
    local moduleRowFs = math.max(FONT_SIZE_MIN, cfgFs - 2)
    local moduleSubFs = math.max(FONT_SIZE_MIN, cfgFs - 3)
    local moduleHeaderH = math.max(22, moduleHeaderFs + 12)
    local moduleRowH = math.max(18, moduleRowFs + 9)
    local moduleCompactH = math.max(16, moduleSubFs + 8)
    local contentW = (f:GetWidth() or 344) - 16
    local activePage = MR._cfgPage or "windows"

    if activePage ~= "windows" and activePage ~= "layout" and activePage ~= "modules" and activePage ~= "reset" and activePage ~= "support" then
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
        local caption = body:CreateFontString(nil, "OVERLAY")
        caption:SetFont(ns.FONT_ROWS, cfgFs, GetFontFlags())
        caption:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        caption:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
        caption:SetJustifyH("LEFT")
        caption:SetWordWrap(false)
        caption:SetText("|cff888888" .. label .. "|r")

        yOff = yOff - 14

        local row = CreateFrame("Frame", nil, body)
        row:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        row:SetSize(contentW, 26)

        local dropdown = ns.CreateDropdown(row, {
            width = math.max(170, contentW - 28),
            height = 20,
            maxHeight = 20,
            maxWidth = 420,
            fontSize = cfgFs,
            getOptions = function()
                return choices
            end,
            getSelected = getVal,
            onSelect = function(value, choice)
                setVal(value, choice)
            end,
            dynamicMenuWidth = true,
            maxVisibleRows = 10,
            style = "teal",
        })
        dropdown:SetPoint("LEFT", row, "LEFT", 0, 0)

        local resetBtn = ns.CloseButton(row, function()
            local resetValue = getResetValue and getResetValue() or choices[1].value
            for _, choice in ipairs(choices) do
                if choice.value == resetValue then
                    setVal(choice.value, choice)
                    dropdown:Update()
                    return
                end
            end
            setVal(choices[1].value, choices[1])
            dropdown:Update()
        end)
        resetBtn:ClearAllPoints()
        resetBtn:SetSize(20, 20)
        resetBtn:SetPoint("RIGHT", row, "RIGHT", 0, 0)

        row._mrExternalFrames = { dropdown._popup, dropdown._dismiss }
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
        if ns.MigrateCompletionSoundsScope then
            ns.MigrateCompletionSoundsScope(not enabled)
        end
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
        if MR.raresFrame and MR.raresFrame.IsShown and MR.raresFrame:IsShown() and MR.RebuildRaresFrame then
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
            { key = "support", label = L["Config_TabSupport"] or "Support" },
            { key = "reset",   label = L["Config_TabReset"]   or "Reset"   },
        }
        local tabW = math.floor((contentW - 6) / #tabs)
        local tabFs = math.min(cfgFs, 10)
        local tabY = yOff
        for i, tab in ipairs(tabs) do
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(tabW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", 8 + (i - 1) * (tabW + 2), tabY)
            btn:SetBackdrop(MakeBackdrop())
            if btn.SetClipsChildren then btn:SetClipsChildren(true) end
            local isActive = activePage == tab.key
            btn:SetBackdropColor(isActive and 0.11 or 0.05, isActive and 0.24 or 0.09, isActive and 0.23 or 0.15, 1)
            btn:SetBackdropBorderColor(isActive and 0.22 or 0.16, isActive and 0.82 or 0.28, isActive and 0.70 or 0.36, 1)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(ns.FONT_ROWS, tabFs, GetFontFlags())
            lbl:SetPoint("LEFT", btn, "LEFT", 2, 0)
            lbl:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
            lbl:SetJustifyH("CENTER")
            lbl:SetWordWrap(false)
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
            function() return MR:GetMainPanelOpen() end,
            function(v)
                if v then
                    MR:ShowMainPanel(true)
                else
                    MR:HideMainPanel(true)
                end
            end, "#2ae7c6")

        Checkbox(L["Config_OpenRenown"],
            function() return MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("renownOpen") end,
            function(v)
                if v and MR.ClearManagedWindowsBundleHidden then MR:ClearManagedWindowsBundleHidden() end
                if v and MR.EnsureRenownShown then MR:EnsureRenownShown()
                elseif not v and MR.HideRenown then MR:HideRenown() end
            end, "#d9b82e")

        Checkbox(L["Config_OpenRares"],
            function() return MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("raresOpen") end,
            function(v)
                if v and MR.ClearManagedWindowsBundleHidden then MR:ClearManagedWindowsBundleHidden() end
                if v and MR.EnsureRaresShown then MR:EnsureRaresShown()
                elseif not v and MR.HideRares then MR:HideRares() end
            end, "#e05050")

        Checkbox(L["Profession_Knowledge"],
            function() return MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("gatheringLocOpen") end,
            function(v)
                if v and MR.ClearManagedWindowsBundleHidden then MR:ClearManagedWindowsBundleHidden() end
                if v and MR.EnsureGatheringLocationsShown then MR:EnsureGatheringLocationsShown()
                elseif not v and MR.HideGatheringLocations then MR:HideGatheringLocations() end
            end, "#c9853f")

        Gap(4); Divider()
        SectionLabel(L["OPTIONS"])
        Checkbox(L["Config_AutoEnableNewModules"] or "Automatically Enable New Modules",
            function() return MR:ShouldAutoEnableNewModules() end,
            function(v)
                MR:SetAutoEnableNewModules(v)
                MR:PopulateConfigFrame(f)
            end, "#2ae7c6")
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
                if MR.frame then MR.frame:SetMovable(not v) end
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
        Checkbox(L["Config_HideAdventureGuideBossIDs"],
            function() return MR.db.profile.hideAdventureGuideBossIDs == true end,
            function(v)
                MR.db.profile.hideAdventureGuideBossIDs = v and true or false
                if MR.RefreshEncounterJournalOverlays then
                    MR:RefreshEncounterJournalOverlays()
                end
            end)
        Checkbox(L["Config_DisabledInCombat"] or "Disabled in Combat",
            function() return MR.db.profile.disabledInCombat == true end,
            function(v)
                MR.db.profile.disabledInCombat = v and true or false
                if MR.UpdateCombatDisplayState then
                    MR:UpdateCombatDisplayState()
                end
                if v ~= true and MR.FlushCombatDeferredUpdates then
                    MR:FlushCombatDeferredUpdates()
                end
                MR:PopulateConfigFrame(f)
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
                if MR.RefreshPanelHeaderVisibility then
                    MR:RefreshPanelHeaderVisibility(MR.frame)
                    MR:RefreshPanelHeaderVisibility(MR.renownFrame)
                    MR:RefreshPanelHeaderVisibility(MR.raresFrame)
                    MR:RefreshPanelHeaderVisibility(MR.gatheringLocationsFrame)
                    MR:RefreshPanelHeaderVisibility(MR.concentrationTrackerFrame)
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
            lbl:SetFont(ns.FONT_ROWS, cfgFs, GetFontFlags())
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

        Gap(6)
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
                RefreshVisualSettings()
                ScheduleSettingsGarbageCollect()
            end,
            0.40, 0.40, 0.40, 8, nil, cfgFs)

        Gap(4); Divider()
        SectionLabel(L["Config_MainHeaderPosition"] or "Header & Sections")

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
            lbl:SetFont(ns.FONT_ROWS, cfgFs, GetFontFlags())
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
                if MR.raresFrame and MR.raresFrame.IsShown and MR.raresFrame:IsShown() and MR.RebuildRaresFrame then
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
            0.16, 0.78, 0.75, 8, nil, cfgFs)

        Gap(2)
        yOff = OptionsCheckbox(body, yOff,
            L["Config_ShowSectionHeaders"] or "Show Section Headers",
            function() return MR.db.profile.keepHeadersVisibleInTextMode ~= false end,
            function(v)
                MR.db.profile.keepHeadersVisibleInTextMode = v
                RefreshVisualSettings()
                ScheduleSettingsGarbageCollect()
            end,
            0.16, 0.78, 0.75, 8, nil, cfgFs)

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
            pfs:SetFont(ns.FONT_ROWS, cfgFs, GetFontFlags())
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
            0.55, 0.22, 0.82, 8, nil, cfgFs)

        Gap(4); Divider()
        SectionLabel(L["Config_SharedMedia"] or "Shared Media")
        MediaSelector(L["Config_Font"] or "Font", "font",
            function() return MR.GetMediaSetting and MR:GetMediaSetting("fontMedia") or MR.db.profile.fontMedia end,
            function(value, path)
                if MR.SetMediaSetting then
                    MR:SetMediaSetting("fontMedia", value, true)
                    MR:SetMediaSetting("fontMediaPath", path, true)
                else
                    MR.db.profile.fontMedia = value
                    MR.db.profile.fontMediaPath = path
                end
                MR:ApplySharedMediaSettings()
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate("fontMedia", 0.02)
                else
                    MR:PopulateConfigFrame(f)
                end
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
                    MR:SetMediaSetting("fontFlags", value, true)
                else
                    MR.db.profile.fontFlags = value
                end
                MR:ApplySharedMediaSettings()
                if MR.RequestConfigRepopulate then
                    MR:RequestConfigRepopulate("fontFlags", 0.02)
                else
                    MR:PopulateConfigFrame(f)
                end
            end,
            function()
                return "OUTLINE"
            end)
        MediaSelector(L["Config_BackgroundTexture"] or "Background texture", "background",
            function() return MR.GetMediaSetting and MR:GetMediaSetting("backgroundMedia") or MR.db.profile.backgroundMedia end,
            function(value, path)
                if MR.SetMediaSetting then
                    MR:SetMediaSetting("backgroundMedia", value, true)
                    MR:SetMediaSetting("backgroundMediaPath", path, true)
                else
                    MR.db.profile.backgroundMedia = value
                    MR.db.profile.backgroundMediaPath = path
                end
                MR:ApplySharedMediaSettings()
            end)

        Gap(4); Divider()
        SectionLabel(L["Config_TooltipPosition"] or "Tooltip Position")

        local tooltipChoices = {
            { label = L["Config_TooltipLeft"] or "Left", value = "left" },
            { label = L["Config_TooltipRight"] or "Right", value = "right" },
            { label = L["Config_TooltipMiddle"] or "Middle", value = "middle" },
            { label = L["Config_TooltipBottom"] or "Bottom", value = "bottom" },
            { label = L["Config_TooltipCursor"] or "Cursor", value = "cursor" },
        }
        local tooltipY = yOff - 4
        local tooltipBtnW = math.floor((contentW - ((#tooltipChoices - 1) * 2)) / #tooltipChoices)
        local function CreateTooltipPositionButton(choice, index)
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(tooltipBtnW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", 8 + (index - 1) * (tooltipBtnW + 2), tooltipY)
            btn:SetBackdrop(MakeBackdrop())
            local current = MR.GetWindowLayoutValue and MR:GetWindowLayoutValue("tooltipPosition") or MR.db.profile.tooltipPosition
            local active = (current or "right") == choice.value
            btn:SetBackdropColor(active and 0.12 or 0.05, active and 0.30 or 0.09, active and 0.24 or 0.16, 1)
            btn:SetBackdropBorderColor(active and 0.24 or 0.16, active and 0.82 or 0.28, active and 0.70 or 0.36, 1)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(ns.FONT_ROWS, math.min(cfgFs, 10), GetFontFlags())
            lbl:SetPoint("LEFT", btn, "LEFT", 2, 0)
            lbl:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
            lbl:SetJustifyH("CENTER")
            lbl:SetWordWrap(false)
            lbl:SetText(choice.label)
            lbl:SetTextColor(active and 0.92 or 0.70, active and 1.0 or 0.78, active and 0.94 or 0.74)

            btn:SetScript("OnClick", function()
                SetWindowLayoutValue("tooltipPosition", choice.value)
                MR:PopulateConfigFrame(f)
            end)
            btn:SetScript("OnEnter", function()
                local selected = ((MR.GetWindowLayoutValue and MR:GetWindowLayoutValue("tooltipPosition")) or "right") == choice.value
                if not selected then
                    btn:SetBackdropColor(0.08, 0.20, 0.25, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.92, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = ((MR.GetWindowLayoutValue and MR:GetWindowLayoutValue("tooltipPosition")) or "right") == choice.value
                btn:SetBackdropColor(selected and 0.12 or 0.05, selected and 0.30 or 0.09, selected and 0.24 or 0.16, 1)
                btn:SetBackdropBorderColor(selected and 0.24 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.92 or 0.70, selected and 1.0 or 0.78, selected and 0.94 or 0.74)
            end)
        end

        for index, choice in ipairs(tooltipChoices) do
            CreateTooltipPositionButton(choice, index)
        end
        yOff = yOff - 30

        Gap(4)
        yOff = OptionsCheckbox(body, yOff,
            L["Config_ShowWarbandTooltips"] or "Show Warband Info in Tooltips",
            function() return MR.db.profile.showWarbandTooltips ~= false end,
            function(v) MR.db.profile.showWarbandTooltips = v end,
            0.24, 0.82, 0.70, 8, nil, cfgFs)
    end

    if activePage == "modules" then
        yOff = Config.BuildModulesPage({
            frame = f,
            body = body,
            yOff = yOff,
            cfgFs = cfgFs,
            moduleHeaderFs = moduleHeaderFs,
            moduleRowFs = moduleRowFs,
            moduleSubFs = moduleSubFs,
            moduleHeaderH = moduleHeaderH,
            moduleRowH = moduleRowH,
            moduleCompactH = moduleCompactH,
            contentW = contentW,
        })
    end

    if activePage == "support" then
        local function CopyableLinkRow(label, url, accentHex)
            local capLabel = body:CreateFontString(nil, "OVERLAY")
            capLabel:SetFont(ns.FONT_ROWS, cfgFs, GetFontFlags())
            capLabel:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
            capLabel:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
            capLabel:SetJustifyH("LEFT")
            capLabel:SetWordWrap(false)
            capLabel:SetText("|c" .. (accentHex or "ffcfe9e5") .. label .. "|r")

            yOff = yOff - 14

            local boxBg = CreateFrame("Frame", nil, body, "BackdropTemplate")
            boxBg:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
            boxBg:SetSize(math.max(192, contentW), 20)
            boxBg:SetBackdrop(MakeBackdrop())
            boxBg:SetBackdropColor(0.05, 0.12, 0.20, 0.95)
            boxBg:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
            boxBg:EnableMouse(true)

            local eb = CreateFrame("EditBox", nil, boxBg)
            eb:SetAutoFocus(false)
            eb:SetPoint("TOPLEFT", boxBg, "TOPLEFT", 6, -3)
            eb:SetPoint("BOTTOMRIGHT", boxBg, "BOTTOMRIGHT", -6, 3)
            eb:SetFont(ns.FONT_ROWS, cfgFs, GetFontFlags())
            eb:SetTextColor(0.76, 0.97, 0.94)
            eb:SetText(url)
            eb:SetCursorPosition(0)
            eb:SetScript("OnEditFocusGained", function(selfEb)
                selfEb:HighlightText(0, -1)
            end)
            eb:SetScript("OnEscapePressed", function(selfEb) selfEb:ClearFocus() end)
            eb:SetScript("OnEnterPressed", function(selfEb) selfEb:ClearFocus() end)
            eb:SetScript("OnEditFocusLost", function(selfEb)
                selfEb:HighlightText(0, 0)
                selfEb:SetText(url)
                selfEb:SetCursorPosition(0)
            end)

            boxBg:SetScript("OnEnter", function(selfBg)
                selfBg:SetBackdropBorderColor(0.26, 0.78, 0.72, 1)
            end)
            boxBg:SetScript("OnLeave", function(selfBg)
                selfBg:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
            end)
            boxBg:SetScript("OnMouseDown", function()
                eb:SetFocus()
            end)

            yOff = yOff - 28
        end

        SectionLabel(L["Config_SupportUs"] or "Support Us")
        Gap(2)

        CopyableLinkRow(L["Config_SupportPayPal"] or "PayPal",
            "https://www.paypal.com/donate/?business=Jhookftw1@hotmail.com", "ff5ea0e0")
        CopyableLinkRow(L["Config_SupportBuyMeACoffee"] or "Buy Me a Coffee",
            "https://www.buymeacoffee.com/azroaddons", "ffffc95c")
        CopyableLinkRow(L["Config_SupportPatreon"] or "Patreon",
            "https://www.patreon.com/join/AzroAddons", "ffff8a7a")
        CopyableLinkRow(L["Config_SupportDiscord"] or "Discord",
            "https://discord.gg/5jvvmr3bMB", "ff8a93ff")

        Gap(4); Divider()
        SectionLabel(L["Config_Translators"] or "Translators")

        local translators = {
            { lang = "Traditional Chinese",     name = "BlueNightSky" },
            { lang = "Simplified Chinese",      name = "Nanjuekaien1" },
            { lang = "Latin American Spanish",  name = "DarkChiken" },
            { lang = "Russian",                 name = "Hubbotu" },
            { lang = "German",                  name = "Paspatu" },
            { lang = "Korean",                  name = "Crazyyoungs" },
        }

        for _, t in ipairs(translators) do
            local row = CreateFrame("Frame", nil, body)
            row:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
            row:SetSize(contentW, 16)

            local dot = row:CreateTexture(nil, "ARTWORK")
            dot:SetSize(5, 5)
            dot:SetPoint("LEFT", row, "LEFT", 0, 0)
            dot:SetColorTexture(0.20, 0.66, 0.63, 0.9)

            local rowFs = row:CreateFontString(nil, "OVERLAY")
            rowFs:SetFont(ns.FONT_ROWS, cfgFs, GetFontFlags())
            rowFs:SetPoint("LEFT", row, "LEFT", 10, 0)
            rowFs:SetPoint("RIGHT", row, "RIGHT", 0, 0)
            rowFs:SetJustifyH("LEFT")
            rowFs:SetWordWrap(false)
            rowFs:SetText("|cff9fb8c9" .. t.lang .. ":|r  |cff76f7ee" .. t.name .. "|r")

            yOff = yOff - 18
        end

        Gap(6)
        local wanted = body:CreateFontString(nil, "OVERLAY")
        wanted:SetFont(ns.FONT_ROWS, math.max(8, cfgFs - 1), GetFontFlags())
        wanted:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        wanted:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
        wanted:SetJustifyH("LEFT")
        wanted:SetWordWrap(true)
        wanted:SetText("|cffffd27a" .. (L["Config_TranslatorsWanted"] or "Always looking for translators \226\128\148 join our Discord!") .. "|r")
        yOff = yOff - (2 * (math.max(8, cfgFs - 1) + 4)) - 4
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
            local expansionKey = MR:GetSelectedExpansionKey()
            if MR:IsCharacterWindowLayoutEnabled() then
                MR.db.char.moduleOrder = {}
                MR.db.char.professionKnowledgePosition = nil
                if MR.db.char.expansionModuleOrder then
                    MR.db.char.expansionModuleOrder[expansionKey] = {}
                end
            else
                MR.db.profile.moduleOrder = {}
                MR.db.profile.professionKnowledgePosition = nil
                if MR.db.profile.expansionModuleOrder then
                    MR.db.profile.expansionModuleOrder[expansionKey] = {}
                end
            end
            local storage = MR:GetActiveModuleStorage(expansionKey)
            if storage then
                for _, state in pairs(storage) do
                    if type(state) == "table" then
                        state.rowOrder = nil
                    end
                end
            end
            MR._orderedModulesCache = nil
            MR._orderedAllModulesCache = nil
            MR._moduleStatsCache = nil
            MR:RefreshUI()
            MR:PopulateConfigFrame(f)
        end)
    end

    Gap(8)
    local totalH = math.abs(yOff) + 8
    local maxBodyH = math.max(220, math.min(PANEL_MAX_HEIGHT - 22, (UIParent:GetHeight() or 768) - 120))
    body:SetHeight(totalH)
    bodyParent:SetHeight(totalH)
    if f.scroll then
        f:SetHeight(math.min(totalH + 22, maxBodyH + 22))
        if f.UpdateScrollBar then f.UpdateScrollBar() end
    else
        f:SetHeight(totalH)
    end
end

