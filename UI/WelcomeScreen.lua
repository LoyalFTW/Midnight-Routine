local _, ns = ...
local MR = ns.MR

local FONT_HEADERS = ns.FONT_HEADERS
local FONT_ROWS = ns.FONT_ROWS
local MakeBackdrop = ns.MakeBackdrop
local hex = ns.Hex
local StyledFrame = ns.StyledFrame
local TitleBar = ns.TitleBar
local L            = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local pendingEnabled = {}
local pendingRenown      = false
local pendingRares       = false
local pendingGathering   = false
local pendingCharacterLayout = false
local pendingAutoEnableNewModules = true
local checkboxRefs   = {}

local function RefreshFonts()
    local readableFont = GameFontNormal and select(1, GameFontNormal:GetFont())
        or STANDARD_TEXT_FONT
        or "Fonts\\FRIZQT__.TTF"
    FONT_ROWS = readableFont
    FONT_HEADERS = readableFont
end

local function GetFontFlags()
    return ""
end

local function IsStoryModule(mod)
    return mod and (mod.configGroup == "story" or (type(mod.key) == "string" and mod.key:match("^story_campaign_")))
end

local function BuildWelcomeScreen()
    RefreshFonts()
    wipe(pendingEnabled)
    wipe(checkboxRefs)

    for _, mod in ipairs(MR:GetOrderedModules()) do
        pendingEnabled[mod.key] = MR:IsModuleEnabled(mod.key)
    end

    pendingRenown = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("renownOpen") or false
    pendingRares = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("raresOpen") or false
    pendingGathering = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("gatheringLocOpen") or false
    pendingCharacterLayout = MR:IsCharacterWindowLayoutEnabled()
    pendingAutoEnableNewModules = MR:ShouldAutoEnableNewModules()

    local f = StyledFrame(UIParent, nil, "FULLSCREEN_DIALOG", 200)
    f:SetSize(460, 680)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
    f:SetBackdropColor(0.02, 0.04, 0.10, 0.98)
    f:SetBackdropBorderColor(0.16, 0.78, 0.75, 1)

    local titleBar = TitleBar(f, 40)
    titleBar:SetBackdropColor(0.035, 0.08, 0.16, 1)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY")
    titleTxt:SetFont(ns.FONT_HEADERS, 14, GetFontFlags())
    titleTxt:SetPoint("LEFT", titleBar, "LEFT", 14, 1)
    titleTxt:SetText(L["Welcome_Title"])

    local function ScrollByDelta(delta)
        if not f._welcomeScroll or not f._welcomeContent then
            return
        end
        ns.ScrollByDelta(f._welcomeScroll, f._welcomeContent, delta, 40, f.UpdateWelcomeScrollBar)
    end

    local headerInset = 18
    local headerTop = -54

    local heading = f:CreateFontString(nil, "OVERLAY")
    heading:SetFont(ns.FONT_HEADERS, 16, GetFontFlags())
    heading:SetPoint("TOPLEFT",  f, "TOPLEFT",  headerInset, headerTop)
    heading:SetPoint("TOPRIGHT", f, "TOPRIGHT", -headerInset, headerTop)
    heading:SetJustifyH("LEFT")
    heading:SetText(L["Welcome_Heading"])

    local hintTop = headerTop - 20

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont(ns.FONT_ROWS, 11, GetFontFlags())
    hint:SetPoint("TOPLEFT",  f, "TOPLEFT",  headerInset, hintTop)
    hint:SetPoint("TOPRIGHT", f, "TOPRIGHT", -headerInset, hintTop)
    hint:SetJustifyH("LEFT")
    hint:SetText(L["Welcome_Hint"])

    local setupPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    setupPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 14, hintTop - 28)
    setupPanel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, hintTop - 28)
    setupPanel:SetHeight(120)
    setupPanel:SetBackdrop(MakeBackdrop())
    setupPanel:SetBackdropColor(0.015, 0.045, 0.075, 0.94)
    setupPanel:SetBackdropBorderColor(0.12, 0.38, 0.40, 0.90)

    local layoutLabel = setupPanel:CreateFontString(nil, "OVERLAY")
    layoutLabel:SetFont(ns.FONT_HEADERS, 11, GetFontFlags())
    layoutLabel:SetPoint("TOPLEFT", setupPanel, "TOPLEFT", 10, -9)
    layoutLabel:SetText(L["Welcome_LayoutMode"] or "Layout Mode")
    layoutLabel:SetTextColor(0.72, 0.92, 0.90)

    local modeButtons = {}
    local function RefreshModeButtons()
        for _, entry in ipairs(modeButtons) do
            local active = pendingCharacterLayout == entry.characterMode
            entry.button:SetBackdropColor(active and 0.08 or 0.025, active and 0.23 or 0.07, active and 0.20 or 0.11, 1)
            entry.button:SetBackdropBorderColor(active and 0.18 or 0.10, active and 0.78 or 0.25, active and 0.68 or 0.30, 1)
            entry.title:SetTextColor(active and 0.90 or 0.63, active and 1.00 or 0.74, active and 0.94 or 0.72)
            entry.desc:SetTextColor(active and 0.64 or 0.43, active and 0.82 or 0.50, active and 0.80 or 0.52)
        end
    end
    local function CreateModeButton(label, desc, characterMode, anchorPoint, relativePoint, x)
        local btn = CreateFrame("Button", nil, setupPanel, "BackdropTemplate")
        btn:SetPoint(anchorPoint, setupPanel, relativePoint, x, -27)
        btn:SetSize(206, 52)
        btn:SetBackdrop(MakeBackdrop())

        local modeTitle = btn:CreateFontString(nil, "OVERLAY")
        modeTitle:SetFont(ns.FONT_HEADERS, 12, GetFontFlags())
        modeTitle:SetPoint("TOPLEFT", btn, "TOPLEFT", 8, -7)
        modeTitle:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -8, -7)
        modeTitle:SetJustifyH("LEFT")
        modeTitle:SetText(label)

        local modeDesc = btn:CreateFontString(nil, "OVERLAY")
        modeDesc:SetFont(ns.FONT_ROWS, 9, GetFontFlags())
        modeDesc:SetPoint("TOPLEFT", modeTitle, "BOTTOMLEFT", 0, -4)
        modeDesc:SetPoint("TOPRIGHT", modeTitle, "BOTTOMRIGHT", 0, -4)
        modeDesc:SetJustifyH("LEFT")
        modeDesc:SetWordWrap(true)
        modeDesc:SetText(desc)

        modeButtons[#modeButtons + 1] = {
            button = btn,
            title = modeTitle,
            desc = modeDesc,
            characterMode = characterMode,
        }
        btn:SetScript("OnClick", function()
            pendingCharacterLayout = characterMode
            RefreshModeButtons()
        end)
    end

    CreateModeButton(
        L["Config_LayoutShared"] or "Shared",
        L["Welcome_LayoutSharedDesc"] or "One layout shared by every character.",
        false, "TOPLEFT", "TOPLEFT", 8
    )
    CreateModeButton(
        L["Config_LayoutCharacter"] or "Per Character",
        L["Welcome_LayoutCharacterDesc"] or "Each character keeps its own layout.",
        true, "TOPRIGHT", "TOPRIGHT", -8
    )
    RefreshModeButtons()

    local autoCb = CreateFrame("CheckButton", nil, setupPanel, "UICheckButtonTemplate")
    autoCb:SetSize(20, 20)
    autoCb:SetPoint("BOTTOMLEFT", setupPanel, "BOTTOMLEFT", 7, 6)
    autoCb:SetChecked(pendingAutoEnableNewModules)
    autoCb:SetScript("OnClick", function(self)
        pendingAutoEnableNewModules = self:GetChecked() and true or false
    end)

    local autoLabel = setupPanel:CreateFontString(nil, "OVERLAY")
    autoLabel:SetFont(ns.FONT_ROWS, 10, GetFontFlags())
    autoLabel:SetPoint("LEFT", autoCb, "RIGHT", 2, 0)
    autoLabel:SetText(L["Welcome_AutoEnableNewModules"] or "Automatically Enable New Modules")
    autoLabel:SetTextColor(0.78, 0.90, 0.88)

    local autoInfo = setupPanel:CreateFontString(nil, "OVERLAY")
    autoInfo:SetFont(ns.FONT_ROWS, 9, GetFontFlags())
    autoInfo:SetPoint("LEFT", autoLabel, "RIGHT", 7, 0)
    autoInfo:SetPoint("RIGHT", setupPanel, "RIGHT", -8, 0)
    autoInfo:SetJustifyH("RIGHT")
    autoInfo:SetWordWrap(false)
    autoInfo:SetText(pendingAutoEnableNewModules
        and (L["Welcome_AutoEnableOn"] or "New modules start enabled")
        or (L["Welcome_AutoEnableOff"] or "New modules require opt-in"))
    autoInfo:SetTextColor(0.45, 0.68, 0.66)
    autoCb:HookScript("OnClick", function()
        autoInfo:SetText(pendingAutoEnableNewModules
            and (L["Welcome_AutoEnableOn"] or "New modules start enabled")
            or (L["Welcome_AutoEnableOff"] or "New modules require opt-in"))
    end)

    local function MakeDivider(parent, y)
        local d = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        d:SetPoint("TOPLEFT",  parent, "TOPLEFT",   8, y)
        d:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, y)
        d:SetHeight(1)
        d:SetBackdrop(MakeBackdrop(false))
        d:SetBackdropColor(0.16, 0.78, 0.75, 0.25)
        return d
    end
    local footer = CreateFrame("Frame", nil, f, "BackdropTemplate")
    footer:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
    footer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    footer:SetHeight(112)
    footer:SetBackdrop(MakeBackdrop(false))
    if ns.HookBackdropFrame then
        ns.HookBackdropFrame(footer)
    end
    footer:SetBackdropColor(0.03, 0.08, 0.16, 0.96)

    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT", setupPanel, "BOTTOMLEFT", 0, -12)
    scroll:SetPoint("TOPRIGHT", setupPanel, "BOTTOMRIGHT", -10, -12)
    scroll:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 14, 12)
    scroll:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", -24, 12)
    f._welcomeScroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(400, 1)
    f._welcomeContent = content

    local track = CreateFrame("Frame", nil, f)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 4, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 4, 0)
    track:SetWidth(6)

    local UpdateScrollBar, thumb, _, thumbTex = ns.AttachScrollList(scroll, content, track, {
        minThumbHeight = 18,
        wheelStep = 40,
        trackColor = { 0.00, 0.00, 0.00, 0.32 },
        thumbColor = { 0.24, 0.72, 0.72, 0.82 },
    })
    f._welcomeTrack = track
    f._welcomeThumb = thumb
    f.UpdateWelcomeScrollBar = UpdateScrollBar

    content:EnableMouseWheel(true)
    content:SetScript("OnMouseWheel", function(_, delta)
        ScrollByDelta(delta)
    end)
    f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel", function(_, delta)
        ScrollByDelta(delta)
    end)

    local scrollBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
    scrollBg:SetPoint("TOPLEFT", scroll, "TOPLEFT", -4, 4)
    scrollBg:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 4, -4)
    scrollBg:SetFrameLevel(scroll:GetFrameLevel() - 1)
    scrollBg:SetBackdrop(MakeBackdrop())
    scrollBg:SetBackdropColor(0.01, 0.025, 0.055, 0.72)
    scrollBg:SetBackdropBorderColor(0.10, 0.30, 0.34, 0.72)

    thumb:SetScript("OnEnter", function()
        thumbTex:SetColorTexture(0.36, 0.86, 0.82, 0.95)
    end)
    thumb:SetScript("OnLeave", function()
        thumbTex:SetColorTexture(0.24, 0.72, 0.72, 0.82)
    end)

    local yOff = -4

    local welcomeModules = {}
    local welcomeOrder = {}
    for index, mod in ipairs(MR:GetOrderedModules()) do
        welcomeModules[#welcomeModules + 1] = mod
        welcomeOrder[mod.key] = index
    end
    table.sort(welcomeModules, function(a, b)
        local aStory = IsStoryModule(a)
        local bStory = IsStoryModule(b)
        if aStory ~= bStory then
            return not aStory
        end
        return (welcomeOrder[a.key] or 9999) < (welcomeOrder[b.key] or 9999)
    end)

    local function BuildSectionHeader(text)
        local section = CreateFrame("Frame", nil, content, "BackdropTemplate")
        section:SetPoint("TOPLEFT", content, "TOPLEFT", 8, yOff)
        section:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, yOff)
        section:SetHeight(22)
        section:SetBackdrop(MakeBackdrop(false))
        section:SetBackdropColor(0.03, 0.08, 0.12, 0.72)

        local line = section:CreateTexture(nil, "ARTWORK")
        line:SetHeight(1)
        line:SetPoint("BOTTOMLEFT", section, "BOTTOMLEFT", 0, 0)
        line:SetPoint("BOTTOMRIGHT", section, "BOTTOMRIGHT", 0, 0)
        line:SetColorTexture(0.16, 0.78, 0.75, 0.22)

        local fs = section:CreateFontString(nil, "OVERLAY")
        fs:SetFont(ns.FONT_HEADERS, 11, GetFontFlags())
        fs:SetPoint("LEFT", section, "LEFT", 2, 1)
        fs:SetPoint("RIGHT", section, "RIGHT", -2, 1)
        fs:SetJustifyH("LEFT")
        fs:SetText(text)
        fs:SetTextColor(0.72, 0.92, 0.90)
        yOff = yOff - 26
    end

    BuildSectionHeader("Routine Modules")

    local storyHeaderRendered = false
    for _, mod in ipairs(welcomeModules) do
        local skip = mod.profSkillLine and not MR.playerProfessions[mod.profSkillLine]
        if not skip then
            local key = mod.key
            local isStory = IsStoryModule(mod)
            if isStory and not storyHeaderRendered then
                yOff = yOff - 4
                BuildSectionHeader("Story Campaigns")
                storyHeaderRendered = true
            end

            local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
            row:SetPoint("TOPLEFT",  content, "TOPLEFT",  8, yOff)
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, yOff)
            row:SetHeight(26)
            row:SetBackdrop(MakeBackdrop())
            row:SetBackdropColor(0.015, 0.035, 0.075, 0.55)
            row:SetBackdropBorderColor(0.06, 0.13, 0.17, 0.72)
            row:EnableMouseWheel(true)
            row:SetScript("OnMouseWheel", function(_, delta)
                ScrollByDelta(delta)
            end)
            row:SetScript("OnEnter", function()
                row:SetBackdropColor(0.03, 0.09, 0.13, 0.82)
                row:SetBackdropBorderColor(0.14, 0.42, 0.45, 0.95)
            end)
            row:SetScript("OnLeave", function()
                row:SetBackdropColor(0.015, 0.035, 0.075, 0.55)
                row:SetBackdropBorderColor(0.06, 0.13, 0.17, 0.72)
            end)

            local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("LEFT", row, "LEFT", 7, 0)
            cb:SetChecked(pendingEnabled[key])
            cb:SetScript("OnClick", function(s)
                pendingEnabled[key] = s:GetChecked()
            end)
            checkboxRefs[key] = cb

            local lbl = row:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(ns.FONT_ROWS, 12, GetFontFlags())
            lbl:SetPoint("LEFT",  cb,  "RIGHT",  4, 0)
            lbl:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetWordWrap(false)
            local colHex = (mod.labelColor or "#dddddd"):gsub("#","")
            lbl:SetText(string.format("|cff%s%s|r", colHex, mod.label))

            local rowHeight = 26
            row:SetHeight(rowHeight)
            yOff = yOff - (rowHeight + 3)
        end
    end

    local function CreateUtilityPanel(title, desc, getChecked, setChecked, borderColor)
        local panel = CreateFrame("Frame", nil, content, "BackdropTemplate")
        panel:SetPoint("TOPLEFT",  content, "TOPLEFT",  8, yOff)
        panel:SetPoint("TOPRIGHT", content, "TOPRIGHT", -8, yOff)
        panel:SetHeight(58)
        panel:SetBackdrop(MakeBackdrop())
        panel:SetBackdropColor(0.018, 0.040, 0.075, 0.78)
        panel:SetBackdropBorderColor(0.10, 0.24, 0.28, 0.85)
        panel:EnableMouseWheel(true)
        panel:SetScript("OnMouseWheel", function(_, delta)
            ScrollByDelta(delta)
        end)
        panel:SetScript("OnEnter", function()
            panel:SetBackdropColor(0.03, 0.075, 0.10, 0.90)
            panel:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 0.90)
        end)
        panel:SetScript("OnLeave", function()
            panel:SetBackdropColor(0.018, 0.040, 0.075, 0.78)
            panel:SetBackdropBorderColor(0.10, 0.24, 0.28, 0.85)
        end)

        local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        cb:SetSize(22, 22)
        cb:SetPoint("TOPLEFT", panel, "TOPLEFT", 7, -9)
        cb:SetChecked(getChecked())
        cb:SetScript("OnClick", function(s)
            setChecked(s:GetChecked())
        end)

        local titleFs = panel:CreateFontString(nil, "OVERLAY")
        titleFs:SetFont(ns.FONT_HEADERS, 13, GetFontFlags())
        titleFs:SetPoint("TOPLEFT",  cb, "TOPRIGHT", 4, -1)
        titleFs:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -10)
        titleFs:SetJustifyH("LEFT")
        titleFs:SetWordWrap(false)
        titleFs:SetText(title)

        local descFs = panel:CreateFontString(nil, "OVERLAY")
        descFs:SetFont(ns.FONT_ROWS, 11, GetFontFlags())
        descFs:SetPoint("TOPLEFT",  panel, "TOPLEFT", 14, -31)
        descFs:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -31)
        descFs:SetJustifyH("LEFT")
        descFs:SetJustifyV("TOP")
        descFs:SetWordWrap(true)
        descFs:SetText(desc)

        local titleHeight = math.max(14, math.ceil(titleFs:GetStringHeight() or 14))
        local descTop = 14 + titleHeight + 8
        descFs:ClearAllPoints()
        descFs:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -descTop)
        descFs:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -descTop)

        local descHeight = math.max(14, math.ceil(descFs:GetStringHeight() or 14))
        panel:SetHeight(math.max(62, descTop + descHeight + 10))
        yOff = yOff - panel:GetHeight() - 8

        return panel
    end

    yOff = yOff - 8

    CreateUtilityPanel(
        L["Welcome_Renown"],
        L["Welcome_Renown_Desc"],
        function() return pendingRenown end,
        function(val) pendingRenown = val end,
        { 0.65, 0.50, 0.10, 0.90 }
    )

    CreateUtilityPanel(
        L["Welcome_Rares"],
        L["Welcome_Rares_Desc"],
        function() return pendingRares end,
        function(val) pendingRares = val end,
        { 0.65, 0.20, 0.10, 0.90 }
    )

    CreateUtilityPanel(
        L["Welcome_ProfKnowledge"],
        L["Welcome_ProfKnowledge_Desc"],
        function() return pendingGathering end,
        function(val) pendingGathering = val end,
        { 0.65, 0.57, 0.10, 0.90 }
    )

    content:SetHeight(math.abs(yOff) + 20)
    UpdateScrollBar()

    local footerDivider = CreateFrame("Frame", nil, f, "BackdropTemplate")
    footerDivider:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 8, 8)
    footerDivider:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", -8, 8)
    footerDivider:SetHeight(1)
    footerDivider:SetBackdrop(MakeBackdrop(false))
    footerDivider:SetBackdropColor(0.16, 0.78, 0.75, 0.35)

    local allOn = true
    for _, mod in ipairs(welcomeModules) do
        local skip = mod.profSkillLine and not MR.playerProfessions[mod.profSkillLine]
        if not skip and not pendingEnabled[mod.key] then
            allOn = false
            break
        end
    end
    local enableAllBtn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    enableAllBtn:SetPoint("TOPLEFT",  footer, "TOPLEFT",  12, -14)
    enableAllBtn:SetPoint("TOPRIGHT", footer, "TOPRIGHT", -12, -14)
    enableAllBtn:SetHeight(24)
    enableAllBtn:SetBackdrop(MakeBackdrop())
    enableAllBtn:SetBackdropColor(0.04, 0.14, 0.22, 1)
    enableAllBtn:SetBackdropBorderColor(0.18, 0.55, 0.60, 1)

    local eaLbl = enableAllBtn:CreateFontString(nil, "OVERLAY")
    eaLbl:SetFont(ns.FONT_ROWS, 11, GetFontFlags())
    eaLbl:SetPoint("CENTER")
    eaLbl:SetText(allOn and L["Welcome_Disable_All"] or L["Welcome_Enable_All"])

    enableAllBtn:SetScript("OnClick", function()
        allOn = not allOn
        for _, mod in ipairs(MR:GetOrderedModules()) do
            local skip = mod.profSkillLine and not MR.playerProfessions[mod.profSkillLine]
            if not skip then
                pendingEnabled[mod.key] = allOn
                if checkboxRefs[mod.key] then
                    checkboxRefs[mod.key]:SetChecked(allOn)
                end
            end
        end
        eaLbl:SetText(allOn and L["Welcome_Disable_All"] or L["Welcome_Enable_All"])
    end)
    enableAllBtn:SetScript("OnEnter", function()
        enableAllBtn:SetBackdropColor(0.06, 0.22, 0.32, 1)
        enableAllBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
    end)
    enableAllBtn:SetScript("OnLeave", function()
        enableAllBtn:SetBackdropColor(0.04, 0.14, 0.22, 1)
        enableAllBtn:SetBackdropBorderColor(0.18, 0.55, 0.60, 1)
    end)

    local suppressCb = CreateFrame("CheckButton", nil, footer, "UICheckButtonTemplate")
    suppressCb:SetSize(20, 20)
    suppressCb:SetPoint("TOPLEFT", footer, "TOPLEFT", 12, -46)
    suppressCb:SetChecked(false)

    local suppressLbl = footer:CreateFontString(nil, "OVERLAY")
    suppressLbl:SetFont(ns.FONT_ROWS, 11, GetFontFlags())
    suppressLbl:SetPoint("LEFT", suppressCb, "RIGHT", 2, 0)
    suppressLbl:SetPoint("RIGHT", footer, "RIGHT", -12, 0)
    suppressLbl:SetJustifyH("LEFT")
    suppressLbl:SetWordWrap(true)
    suppressLbl:SetText(L["Welcome_SuppressAll"])
    suppressLbl:SetTextColor(0.6, 0.6, 0.6)

    local confirmBtn = CreateFrame("Button", nil, footer, "BackdropTemplate")
    confirmBtn:SetPoint("BOTTOMLEFT",  footer, "BOTTOMLEFT",  12, 10)
    confirmBtn:SetPoint("BOTTOMRIGHT", footer, "BOTTOMRIGHT", -12, 10)
    confirmBtn:SetHeight(28)
    confirmBtn:SetBackdrop(MakeBackdrop())
    confirmBtn:SetBackdropColor(0.05, 0.20, 0.12, 1)
    confirmBtn:SetBackdropBorderColor(0.15, 0.78, 0.42, 1)

    local confirmLbl = confirmBtn:CreateFontString(nil, "OVERLAY")
    confirmLbl:SetFont(ns.FONT_HEADERS, 13, GetFontFlags())
    confirmLbl:SetPoint("CENTER")
    confirmLbl:SetText(L["Welcome_Confirm"])
    local cr, cg, cb = hex("#00ff96")
    confirmLbl:SetTextColor(cr, cg, cb)

    confirmBtn:SetScript("OnClick", function()
        local anyEnabled = false
        MR.db.profile.characterWindowLayout = pendingCharacterLayout and true or false
        for key, val in pairs(pendingEnabled) do
            MR:SetModuleEnabled(key, val, true)
            if val then anyEnabled = true end
        end
        MR:SetAutoEnableNewModules(pendingAutoEnableNewModules)
        MR:DismissFirstTimeGlow()
        MR.db.char.welcomeSeen = true
        if suppressCb:GetChecked() then
            MR.db.profile.welcomeSuppressed = true
        end
        f:Hide()

        C_Timer.After(0, function()
            if not MR.db then
                return
            end

            local prevRenown = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("renownOpen") or false
            local prevRares = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("raresOpen") or false
            local prevGathering = MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("gatheringLocOpen") or false

            if pendingRenown ~= prevRenown then
                if pendingRenown and MR.EnsureRenownShown then
                    MR:EnsureRenownShown()
                elseif pendingRenown and MR.ToggleRenown then
                    MR:ToggleRenown()
                elseif not pendingRenown and MR.HideRenown then
                    MR:HideRenown(false)
                end
            end
            if pendingRares ~= prevRares then
                if pendingRares and MR.EnsureRaresShown then
                    MR:EnsureRaresShown()
                elseif pendingRares and MR.ToggleRares then
                    MR:ToggleRares()
                elseif not pendingRares and MR.HideRares then
                    MR:HideRares(false)
                end
            end
            if pendingGathering ~= prevGathering then
                if pendingGathering and MR.EnsureGatheringLocationsShown then
                    MR:EnsureGatheringLocationsShown()
                elseif pendingGathering and MR.ToggleGatheringLocations then
                    MR:ToggleGatheringLocations()
                elseif not pendingGathering and MR.HideGatheringLocations then
                    MR:HideGatheringLocations(false)
                end
            end

            MR:RefreshUI()
            if anyEnabled and MR.frame then
                MR.frame:Show()
                MR:SetMainPanelOpen(true, true)
                if MR.ClearManagedWindowsBundleHidden then
                    MR:ClearManagedWindowsBundleHidden()
                end
            end
        end)
    end)
    confirmBtn:SetScript("OnEnter", function()
        confirmBtn:SetBackdropColor(0.08, 0.32, 0.20, 1)
        confirmBtn:SetBackdropBorderColor(0.20, 1.00, 0.55, 1)
        confirmLbl:SetTextColor(1, 1, 1)
    end)
    confirmBtn:SetScript("OnLeave", function()
        confirmBtn:SetBackdropColor(0.05, 0.20, 0.12, 1)
        confirmBtn:SetBackdropBorderColor(0.15, 0.78, 0.42, 1)
        local r, g, b = hex("#00ff96")
        confirmLbl:SetTextColor(r, g, b)
    end)

    f:SetAlpha(0)
    local fadeEl = 0
    f:SetScript("OnUpdate", function(self, dt)
        fadeEl = fadeEl + dt
        local a = math.min(fadeEl / 0.4, 1)
        self:SetAlpha(a)
        if a >= 1 then self:SetScript("OnUpdate", nil) end
    end)

    return f
end

function MR:ShowWelcomeScreen()
    self._welcomePending = nil
    if self.welcomeFrame then
        self.welcomeFrame:Hide()
        self.welcomeFrame = nil
    end
    self.welcomeFrame = BuildWelcomeScreen()
    self.welcomeFrame:Show()
end

function MR:MaybeShowWelcomeScreen()
    if self.db.profile.welcomeSuppressed then return end
    if self.db.char.welcomeSeen then return end
    if self._welcomePending then return end
    if self.welcomeFrame and self.welcomeFrame:IsShown() then return end

    self._welcomePending = true
    local ticks = 0
    local checker = CreateFrame("Frame")
    checker:SetScript("OnUpdate", function(frame)
        ticks = ticks + 1
        if ticks >= 5 then
            frame:SetScript("OnUpdate", nil)
            frame:Hide()
            MR._welcomePending = nil
            if MR.db and MR.db.profile and not MR.db.profile.welcomeSuppressed
                and MR.db.char and not MR.db.char.welcomeSeen then
                MR:ShowWelcomeScreen()
                if MR.cfgShine and not MR.db.profile.firstSeen then
                    MR.cfgShine:Play()
                end
            end
        end
    end)
end

function MR:DismissFirstTimeGlow()
    if self.db and self.db.profile and not self.db.profile.firstSeen then
        self.db.profile.firstSeen = true
    end

    if self._firstSeenGlowTimer then
        self._firstSeenGlowTimer:Cancel()
        self._firstSeenGlowTimer = nil
    end

    if self.cfgShine then
        self.cfgShine:Stop()
    end
end
