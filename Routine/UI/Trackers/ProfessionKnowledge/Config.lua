local _, ns = ...
if ns.Inactive then return end
if ns.MR.isForever and ns.Forever.hideProfessions then return end
local MR = ns.MR
local PK = ns.ProfessionKnowledgeInternal

local StyledFrame = ns.StyledFrame
local TitleBar = ns.TitleBar
local CloseButton = ns.CloseButton
local MakeBackdrop = ns.MakeBackdrop
local OptionsGap = ns.OptionsGap
local OptionsDivider = ns.OptionsDivider
local OptionsSectionLabel = ns.OptionsSectionLabel
local OptionsCheckbox = ns.OptionsCheckbox
local OptionsSlider = ns.OptionsSlider
local OptionsBtn = ns.OptionsBtn
local OptionsColorSwatch = ns.OptionsColorSwatch
local hex = ns.Hex
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)
local HasProfessionLearned = PK.HasProfessionLearned
local EnsureGatheringWatchFrame = PK.EnsureGatheringWatchFrame
local RefreshFonts = PK.RefreshFonts
local GetFontFlags = ns.GetFontFlags
local DEFAULT_W = PK.DEFAULT_W
local DEFAULT_H = PK.DEFAULT_H
local MIN_W = PK.MIN_W
local MAX_W = PK.MAX_W
local MIN_H = PK.MIN_H
local MAX_H = PK.MAX_H
local ALL_EXPANSIONS = PK.ALL_EXPANSIONS
local GetProfessionColor = PK.GetProfessionColor
local StripInlineColor = PK.StripInlineColor
local GetEntryVisibilityId = PK.GetEntryVisibilityId
local IsProfessionCardVisible = PK.IsProfessionCardVisible
local SetProfessionCardVisible = PK.SetProfessionCardVisible
local EntryDisplayLabel = PK.EntryDisplayLabel
local ApplyGatheringFrameTheme = PK.ApplyGatheringFrameTheme
local GetOrderedProfessionSections = PK.GetOrderedProfessionSections
local ShouldShowProfessionSection = PK.ShouldShowProfessionSection

local PopulateGatheringConfig
local configExpandedProfessions = {}
local configCollapsedExpansions = {}

local function SetProfessionColor(professionKey, r, g, b)
    if not MR.db.profile.gatheringProfColors then MR.db.profile.gatheringProfColors = {} end
    MR.db.profile.gatheringProfColors[professionKey] = { r, g, b }
    if MR.RequestVisualRefresh then
        MR:RequestVisualRefresh({ main = false })
    else
        PK.RebuildGatheringLocationsFrame()
        if MR.RepopulateConfigFrame then MR:RepopulateConfigFrame() end
        if MR.RepopulateGatheringConfig then MR:RepopulateGatheringConfig() end
    end
end

local function ResetProfessionColor(professionKey)
    if MR.db.profile.gatheringProfColors then MR.db.profile.gatheringProfColors[professionKey] = nil end
    if MR.RequestVisualRefresh then
        MR:RequestVisualRefresh({ main = false })
    else
        PK.RebuildGatheringLocationsFrame()
        if MR.RepopulateConfigFrame then MR:RepopulateConfigFrame() end
        if MR.RepopulateGatheringConfig then MR:RepopulateGatheringConfig() end
    end
end

local function BuildGatheringConfigFrame()
    EnsureGatheringWatchFrame()
    local frame = StyledFrame(UIParent, nil, "HIGH", 20)
    MR:RegisterPriorityFrame(frame)
    frame:SetWidth(268)
    ApplyGatheringFrameTheme(frame, {
        alpha = 1,
        bg = { 0.03, 0.05, 0.09, 0.98 },
        border = { 0.24, 0.31, 0.42, 1 },
        accent = { 0.18, 0.78, 0.72 },
        headerHeight = 44,
    })
    frame._configMinHeight = 250
    frame:Hide()

    local tbar = TitleBar(frame, 22)
    tbar:SetBackdropColor(0.05, 0.12, 0.22, 1)
    tbar:SetScript("OnDragStart", function() frame:StartMoving() end)
    tbar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
    ttitle:SetText(MR.isForever and L["Forever_Professions"] or ns.StripColorCodes(L["ProfKnowledge_Config_Title"]))
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)
    ns.RegisterThemedFontString(ttitle, 0.79, 0.52, 0.25)
    CloseButton(tbar, function() frame:Hide() end)

    local scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -22)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 0)
    local scrollContent = CreateFrame("Frame", nil, scroll)
    scrollContent:SetSize(frame:GetWidth() or 268, 1)

    local track = CreateFrame("Frame", nil, frame)
    track:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -25)
    track:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    track:SetWidth(4)

    if ns.AttachScrollList then
        frame.UpdateConfigScrollBar = ns.AttachScrollList(scroll, scrollContent, track)
        frame.configScroll = scroll
        frame.configScrollTrack = track
    else
        scroll:Hide()
        track:Hide()
    end

    frame.body = nil
    return frame
end

PopulateGatheringConfig = function(frame)
    if MR.isForever then ns.Forever.RefreshProfessions() end
    RefreshFonts()
    local keepLeft, keepTop
    if frame.IsShown and frame:IsShown() and MR.CaptureFrameScreenPosition then
        keepLeft, keepTop = MR:CaptureFrameScreenPosition(frame)
    end

    if frame.body then
        if MR.ReleaseFrameTree then
            MR:ReleaseFrameTree(frame.body)
        else
            frame.body:EnableMouse(false)
            frame.body:Hide()
            frame.body:SetParent(nil)
        end
        frame.body = nil
    end

    local bodyParent = (frame.configScroll and frame.configScroll:GetScrollChild()) or frame
    local body = CreateFrame("Frame", nil, bodyParent)
    body:SetPoint("TOPLEFT", bodyParent, "TOPLEFT", 0, 0)
    body:SetPoint("TOPRIGHT", bodyParent, "TOPRIGHT", 0, 0)
    frame.body = body

    local db = MR.db.profile
    local yOff, pad = frame.configScroll and -6 or -28, 8
    local contentW = (frame:GetWidth() or 224) - (pad * 2)
    local activePage = MR._gatheringCfgPage or "display"
    local cfgFs = (ns.GetFontSize and ns.GetFontSize()) or (MR.db and MR.db.profile and MR.db.profile.fontSize) or 9

    if activePage ~= "display" and activePage ~= "modules" and activePage ~= "reset" then
        activePage = "display"
        MR._gatheringCfgPage = activePage
    end

    local function Gap(h) yOff = OptionsGap(body, yOff, h) end
    local function Divider() yOff = OptionsDivider(body, yOff, pad) end
    local function SecLabel(text) yOff = OptionsSectionLabel(body, yOff, text, pad, cfgFs) end
    local function Check(label, getValue, setValue, r, g, b)
        yOff = OptionsCheckbox(body, yOff, label, getValue, setValue, r or 0.78, g or 0.78, b or 0.88, pad, function() PopulateGatheringConfig(frame) end, cfgFs)
    end
    local function Slider(label, mn, mx, st, getValue, setValue, r, g, b, disabled)
        yOff = OptionsSlider(body, yOff, label, mn, mx, st, getValue, setValue, r, g, b, pad, disabled, cfgFs)
    end
    local function Btn(label, fn) yOff = OptionsBtn(body, yOff, label, fn, math.max(184, contentW), pad, cfgFs) end

    do
        local tabs = {
            { key = "display", label = L["Config_TabLayout"] or "Layout" },
            { key = "modules", label = L["Config_TabModules"] or "Modules" },
            { key = "reset", label = L["Config_TabReset"] or "Reset" },
        }
        local tabW = math.floor((contentW - 4) / #tabs)
        for i, tab in ipairs(tabs) do
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(tabW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", pad + (i - 1) * (tabW + 2), yOff)
            btn:SetBackdrop(MakeBackdrop())
            local isActive = activePage == tab.key
            btn:SetBackdropColor(isActive and 0.11 or 0.05, isActive and 0.24 or 0.09, isActive and 0.23 or 0.15, 1)
            btn:SetBackdropBorderColor(isActive and 0.22 or 0.16, isActive and 0.82 or 0.28, isActive and 0.70 or 0.36, 1)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(ns.FONT_ROWS, cfgFs, GetFontFlags())
            lbl:SetPoint("CENTER")
            lbl:SetText(tab.label)
            lbl:SetTextColor(isActive and 0.85 or 0.62, isActive and 1.0 or 0.75, isActive and 0.92 or 0.70)

            btn:SetScript("OnClick", function()
                MR._gatheringCfgPage = tab.key
                PopulateGatheringConfig(frame)
            end)
            btn:SetScript("OnEnter", function()
                if activePage ~= tab.key then
                    btn:SetBackdropColor(0.08, 0.18, 0.24, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.90, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = (MR._gatheringCfgPage or "display") == tab.key
                btn:SetBackdropColor(selected and 0.11 or 0.05, selected and 0.24 or 0.09, selected and 0.23 or 0.15, 1)
                btn:SetBackdropBorderColor(selected and 0.22 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.85 or 0.62, selected and 1.0 or 0.75, selected and 0.92 or 0.70)
            end)
        end
        yOff = yOff - 26
    end

    if activePage == "display" then
        SecLabel(L["Config_Display"])
        Check(L["Config_LockPosition"], function() return db.gatheringLocked end, function(value)
            db.gatheringLocked = value
            local locationsFrame = PK.GetLocationsFrame()
            if locationsFrame then locationsFrame:SetMovable(not value) end
        end)
        Check(L["Config_HideWhenCompleted"], function() return db.gatheringHideCompleted end, function(value)
            db.gatheringHideCompleted = value
            PK.RebuildGatheringLocationsFrame()
        end)
        Gap(4); Divider()
        Slider(L["WIDTH"], MIN_W, MAX_W, 10, function() return db.gatheringWidth or DEFAULT_W end, function(value)
            db.gatheringWidth = math.floor(value / 10) * 10
            PK.RebuildGatheringLocationsFrame()
        end, 0.80, 0.53, 0.20)
        Slider(L["HEIGHT"], MIN_H, MAX_H, 10, function() return db.gatheringHeight or DEFAULT_H end, function(value)
            db.gatheringHeight = math.floor(value / 10) * 10
            local locationsFrame = PK.GetLocationsFrame()
            if locationsFrame and not db.gatheringMinimized then locationsFrame:SetHeight(db.gatheringHeight) end
        end, 0.60, 0.80, 0.40)
        local syncFs = MR.db.profile.syncWindowFontSize
        Slider(L["Config_FontSize"], 7, 16, 1, function() return db.gatheringFontSize or 9 end, function(value)
            db.gatheringFontSize = math.floor(value)
            PK.RebuildGatheringLocationsFrame()
            PopulateGatheringConfig(frame)
        end, 0.78, 0.55, 0.16, syncFs)
        Slider(L["BACKGROUND"], 0, 1, 0.05, function() return db.gatheringAlpha or 1.0 end, function(value)
            db.gatheringAlpha = math.floor(value * 20) / 20
            PK.RebuildGatheringLocationsFrame()
            PopulateGatheringConfig(frame)
        end, 0.40, 0.40, 0.40)
        Slider(L["SCALE"], 0.5, 2.0, 0.05, function() return db.gatheringScale or 1.0 end, function(value)
            db.gatheringScale = value
            local locationsFrame = PK.GetLocationsFrame()
            if locationsFrame then locationsFrame:SetScale(value) end
        end, 0.45, 0.22, 0.82, MR.db.profile.syncWindowScale == true)
    elseif activePage == "modules" then
        db.gatheringEntryVisibility = db.gatheringEntryVisibility or {}
        local entryVisibility = db.gatheringEntryVisibility
        local function EntryCheck(indent, entry, sectionKey, getValue, setValue, r, g, b)
            yOff = OptionsCheckbox(body, yOff, EntryDisplayLabel(entry, sectionKey), getValue, function(value)
                setValue(value)
                PopulateGatheringConfig(frame)
            end, r or 0.78, g or 0.78, b or 0.88, indent, function() end, cfgFs)
        end
        local function GroupHeader(indent, text, modKey, groupRows, getEnabled, setEnabled)
            local hasRows = modKey and type(groupRows) == "table" and #groupRows > 0
            local hasToggle = hasRows or (getEnabled and setEnabled)
            local enabled = true
            if hasToggle then
                enabled = getEnabled and getEnabled() or (hasRows and MR:IsRowGroupEnabled(modKey, groupRows) or true)
            end
            local btn = CreateFrame(hasToggle and "Button" or "Frame", nil, body, hasToggle and "BackdropTemplate" or nil)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", indent, yOff)
            btn:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
            btn:SetHeight(16)
            if hasToggle then
                btn:SetBackdrop(MakeBackdrop())
                btn:SetBackdropColor(enabled and 0.035 or 0.055, enabled and 0.085 or 0.045, enabled and 0.095 or 0.050, 0.72)
                btn:SetBackdropBorderColor(enabled and 0.10 or 0.24, enabled and 0.32 or 0.12, enabled and 0.34 or 0.12, 0.70)
            end

            local cb
            if hasToggle then
                cb = CreateFrame("CheckButton", nil, btn, "UICheckButtonTemplate")
                ns.ThemeCheckButton(cb)
                cb:SetSize(18, 18)
                cb:SetPoint("LEFT", btn, "LEFT", 0, 0)
                cb:SetChecked(enabled)
                cb:SetScript("OnClick", function(s)
                    local value = s:GetChecked() and true or false
                    if setEnabled then
                        setEnabled(value)
                    elseif hasRows then
                        MR:SetRowGroupEnabled(modKey, groupRows, value)
                    end
                    PK.RebuildGatheringLocationsFrame()
                    PopulateGatheringConfig(frame)
                end)
            end

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(ns.FONT_ROWS, math.max(8, cfgFs - 1), GetFontFlags())
            lbl:SetPoint("LEFT", cb or btn, cb and "RIGHT" or "LEFT", cb and 1 or 0, 0)
            lbl:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetWordWrap(false)
            lbl:SetText(text)
            lbl:SetTextColor(enabled and 0.72 or 0.42, enabled and 0.90 or 0.46, enabled and 0.88 or 0.48, 0.95)

            if hasToggle then
                btn:SetScript("OnClick", function()
                    local value = not (getEnabled and getEnabled() or (hasRows and MR:IsRowGroupEnabled(modKey, groupRows) or enabled))
                    if setEnabled then
                        setEnabled(value)
                    elseif hasRows then
                        MR:SetRowGroupEnabled(modKey, groupRows, value)
                    end
                    PK.RebuildGatheringLocationsFrame()
                    PopulateGatheringConfig(frame)
                end)
                btn:SetScript("OnEnter", function()
                    lbl:SetTextColor(0.85, 0.95, 0.98, 1)
                end)
                btn:SetScript("OnLeave", function()
                    local isEnabled = getEnabled and getEnabled() or (hasRows and MR:IsRowGroupEnabled(modKey, groupRows) or enabled)
                    lbl:SetTextColor(isEnabled and 0.72 or 0.42, isEnabled and 0.90 or 0.46, isEnabled and 0.88 or 0.48, 0.95)
                end)
            end

            yOff = yOff - 16
        end
        local function ModuleRowControl(indent, modKey, rowData)
            local rowKey = rowData.key
            local enabled = MR:IsRowEnabled(modKey, rowKey)
            local cleanLabel = StripInlineColor(rowData.label or rowKey)
            local effectiveColor = MR:GetRowColor(modKey, rowKey) or (rowData.colorKey and MR:GetRowColor(modKey, rowData.colorKey)) or MR:GetHeaderColor(modKey)
            local er, eg, eb = hex(effectiveColor)

            local rowFr = CreateFrame("Frame", nil, body)
            rowFr:SetPoint("TOPLEFT", body, "TOPLEFT", indent, yOff)
            rowFr:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
            rowFr:SetHeight(16)

            local bullet = rowFr:CreateTexture(nil, "ARTWORK")
            bullet:SetSize(5, 5)
            bullet:SetPoint("LEFT", rowFr, "LEFT", 0, 0)
            bullet:SetColorTexture(er, eg, eb)

            local rlbl = rowFr:CreateFontString(nil, "OVERLAY")
            rlbl:SetFont(ns.FONT_ROWS, math.max(8, cfgFs - 1), GetFontFlags())
            rlbl:SetPoint("LEFT", rowFr, "LEFT", 10, 0)
            rlbl:SetPoint("RIGHT", rowFr, "RIGHT", -32, 0)
            rlbl:SetJustifyH("LEFT")
            rlbl:SetWordWrap(false)
            rlbl:SetText(cleanLabel)

            local eyeBtn = CreateFrame("Button", nil, rowFr, "BackdropTemplate")
            eyeBtn:SetSize(14, 14)
            eyeBtn:SetPoint("RIGHT", rowFr, "RIGHT", 0, 0)
            eyeBtn:SetBackdrop(MakeBackdrop())
            local eyeLbl = eyeBtn:CreateFontString(nil, "OVERLAY")
            eyeLbl:SetFont(ns.FONT_ROWS, 9, GetFontFlags())
            eyeLbl:SetPoint("CENTER", eyeBtn, "CENTER", 0, 0)

            local function ApplyState(isEnabled)
                bullet:SetAlpha(isEnabled and 0.8 or 0.25)
                if isEnabled then
                    rlbl:SetTextColor(er, eg, eb)
                else
                    rlbl:SetTextColor(0.35, 0.35, 0.35)
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
            ApplyState(enabled)

            eyeBtn:SetScript("OnClick", function()
                enabled = not MR:IsRowEnabled(modKey, rowKey)
                MR:SetRowEnabled(modKey, rowKey, enabled, true)
                PK.RebuildGatheringLocationsFrame()
                ApplyState(enabled)
            end)
            eyeBtn:SetScript("OnEnter", function()
                eyeBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
                eyeBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
                eyeLbl:SetTextColor(1, 1, 1)
                ns.ShowTooltip(eyeBtn, { text = enabled and L["Config_HideRow"] or L["Config_ShowRow"] })
            end)
            eyeBtn:SetScript("OnLeave", function()
                ApplyState(enabled)
                ns.HideOwnedTooltip(eyeBtn)
            end)

            local rsr, rsg, rsb = hex(MR:GetRowColor(modKey, rowKey) or (rowData.colorKey and MR:GetRowColor(modKey, rowData.colorKey)) or MR:GetHeaderColor(modKey))
            local rowSwatch = OptionsColorSwatch(rowFr, rsr, rsg, rsb,
                function(nr, ng, nb)
                    MR:SetRowColor(modKey, rowKey, string.format("#%02x%02x%02x", nr * 255, ng * 255, nb * 255))
                    er, eg, eb = nr, ng, nb
                    bullet:SetColorTexture(er, eg, eb)
                    if enabled then rlbl:SetTextColor(er, eg, eb) end
                end,
                function()
                    MR:ResetRowColor(modKey, rowKey)
                    local dr, dg, db2 = hex((rowData.colorKey and MR:GetRowColor(modKey, rowData.colorKey)) or MR:GetHeaderColor(modKey))
                    er, eg, eb = dr, dg, db2
                    bullet:SetColorTexture(er, eg, eb)
                    if enabled then rlbl:SetTextColor(er, eg, eb) end
                    return dr, dg, db2
                end,
                L["Config_RowColor"])
            rowSwatch:SetSize(14, 14)
            rowSwatch:SetPoint("RIGHT", eyeBtn, "LEFT", -2, 0)

            yOff = yOff - 17
        end
        local function ExpansionHeader(expansion)
            local ROW_H = 26
            local isExpanded = not configCollapsedExpansions[expansion.key]
            local header = CreateFrame("Button", nil, body, "BackdropTemplate")
            header:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
            header:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
            header:SetHeight(ROW_H)
            header:SetBackdrop(MakeBackdrop())
            header:SetBackdropColor(0.020, 0.085, 0.100, 0.95)
            header:SetBackdropBorderColor(0.22, 0.68, 0.64, 0.92)
            header:RegisterForClicks("LeftButtonUp")

            local lbl = header:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(ns.FONT_HEADERS, math.max(10, cfgFs), GetFontFlags())
            lbl:SetPoint("LEFT", header, "LEFT", 9, 0)
            lbl:SetPoint("RIGHT", header, "RIGHT", -28, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetWordWrap(false)
            lbl:SetText(expansion.label)
            lbl:SetTextColor(0.88, 1.00, 0.94, 0.98)

            local arrow = header:CreateFontString(nil, "OVERLAY")
            arrow:SetFont(ns.FONT_HEADERS, math.max(10, cfgFs), GetFontFlags())
            arrow:SetPoint("RIGHT", header, "RIGHT", -9, 0)
            arrow:SetText(isExpanded and "v" or ">")
            arrow:SetTextColor(0.64, 0.90, 0.84, 0.98)

            header:SetScript("OnClick", function()
                configCollapsedExpansions[expansion.key] = isExpanded and true or nil
                PopulateGatheringConfig(frame)
            end)
            header:SetScript("OnEnter", function()
                header:SetBackdropColor(0.025, 0.115, 0.130, 0.98)
                header:SetBackdropBorderColor(0.32, 0.88, 0.78, 1)
                arrow:SetTextColor(1, 1, 1, 1)
            end)
            header:SetScript("OnLeave", function()
                header:SetBackdropColor(0.020, 0.085, 0.100, 0.95)
                header:SetBackdropBorderColor(0.22, 0.68, 0.64, 0.92)
                arrow:SetTextColor(0.64, 0.90, 0.84, 0.98)
            end)

            yOff = yOff - ROW_H - 2
            return isExpanded
        end
        local function IsProfessionEnabled(expansion, profession)
            return IsProfessionCardVisible(expansion.key, profession.key)
        end
        local function SetProfessionEnabled(expansion, profession, enabled)
            SetProfessionCardVisible(expansion.key, profession.key, enabled)
            PopulateGatheringConfig(frame)
        end
        local professionSource = MR.GetMainFrameProgressSource and MR:GetMainFrameProgressSource() or nil
        for _, expansion in ipairs(ALL_EXPANSIONS) do
            local learnedProfessions = {}
            for _, profession in ipairs(expansion.professions) do
                if HasProfessionLearned(profession.skillLine, professionSource) then
                    learnedProfessions[#learnedProfessions + 1] = profession
                end
            end
            if #learnedProfessions > 0 then
            Gap(4)
            local expansionOpen = ExpansionHeader(expansion)
            if expansionOpen then
                for _, profession in ipairs(learnedProfessions) do
                    local cr, cg, cb = GetProfessionColor(profession.key)
                    local profExpandKey = expansion.key .. ":" .. profession.key
                    local isExpanded = configExpandedProfessions[profExpandKey]
                    local row = CreateFrame("Frame", nil, body, "BackdropTemplate")
                    row:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
                    row:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
                    row:SetHeight(28)
                    row:SetBackdrop(MakeBackdrop())
                    row:SetBackdropColor(0.018 + cr * 0.035, 0.024 + cg * 0.035, 0.030 + cb * 0.035, 0.90)
                    row:SetBackdropBorderColor(cr * 0.42, cg * 0.42, cb * 0.42, 0.82)
                    local nameLbl
                    local professionEnabled = IsProfessionEnabled(expansion, profession)
                    local toggleBtn = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    ns.ThemeCheckButton(toggleBtn)
                    toggleBtn:SetSize(20, 20)
                    toggleBtn:SetPoint("LEFT", row, "LEFT", 5, 0)
                    toggleBtn:SetChecked(professionEnabled)
                        toggleBtn:SetScript("OnClick", function()
                            SetProfessionEnabled(expansion, profession, toggleBtn:GetChecked() and true or false)
                        end)
                        toggleBtn:SetScript("OnEnter", function()
                            ns.ShowTooltip(toggleBtn, {
                                text = toggleBtn:GetChecked() and "Hide this profession in the Profession Knowledge window" or "Show this profession in the Profession Knowledge window",
                            })
                        end)
                        toggleBtn:SetScript("OnLeave", function() ns.HideOwnedTooltip(toggleBtn) end)

                        local expandBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
                        expandBtn:SetSize(18, 18)
                        expandBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                        expandBtn:SetBackdrop(MakeBackdrop())
                        expandBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                        expandBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
                        local expandLbl = expandBtn:CreateFontString(nil, "OVERLAY")
                        expandLbl:SetFont(ns.FONT_HEADERS, cfgFs, GetFontFlags())
                        expandLbl:SetPoint("CENTER", expandBtn, "CENTER", 0, 1)
                        expandLbl:SetText(isExpanded and "v" or ">")
                        expandLbl:SetTextColor(0.45, 0.75, 0.70)
                        expandBtn:SetScript("OnClick", function()
                            configExpandedProfessions[profExpandKey] = not isExpanded
                            PopulateGatheringConfig(frame)
                        end)
                        expandBtn:SetScript("OnEnter", function()
                            expandBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
                            expandBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
                            expandLbl:SetTextColor(1, 1, 1)
                            ns.ShowTooltip(expandBtn, { text = L["Config_ExpandCollapseRows"] or "Expand to show/hide individual sources" })
                        end)
                        expandBtn:SetScript("OnLeave", function()
                            expandBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                            expandBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
                            expandLbl:SetTextColor(0.45, 0.75, 0.70)
                            ns.HideOwnedTooltip(expandBtn)
                        end)

                        local swatch = OptionsColorSwatch(row, cr, cg, cb, function(r, g, b)
                            SetProfessionColor(profession.key, r, g, b)
                            if nameLbl then nameLbl:SetTextColor(r, g, b) end
                        end, function()
                            ResetProfessionColor(profession.key)
                            local dr, dg, db2 = GetProfessionColor(profession.key)
                            if nameLbl then nameLbl:SetTextColor(dr, dg, db2) end
                            return dr, dg, db2
                        end, profession.label .. L["Color_Reset_Hint"])
                        swatch:SetPoint("RIGHT", expandBtn, "LEFT", -4, 0)
                        nameLbl = row:CreateFontString(nil, "OVERLAY")
                        nameLbl:SetFont(ns.FONT_ROWS, 10, GetFontFlags())
                        nameLbl:SetPoint("LEFT", toggleBtn, "RIGHT", 6, 0)
                        nameLbl:SetPoint("RIGHT", swatch, "LEFT", -4, 0)
                        nameLbl:SetJustifyH("LEFT")
                        nameLbl:SetText(profession.label)
                        nameLbl:SetTextColor(cr, cg, cb)
                        yOff = yOff - 30

                        if isExpanded then
                            if MR.isForever then
                                local tasks = ns.Forever.GetProfessionTasks(profession)
                                for _, task in ipairs(tasks) do
                                    ModuleRowControl(pad + 26, task.mod.key, task.row)
                                end
                            elseif ns.BuildMainMenuRows then
                                local modKey = (ns.GetProfessionModuleKey and ns.GetProfessionModuleKey(expansion.key, profession)) or ("prof_" .. profession.key)
                                local rowsByGroup, groupOrder = {}, {}
                                for _, row in ipairs(ns.BuildMainMenuRows(profession, expansion)) do
                                    if not row.isVisible or row.isVisible() then
                                    local g = row.group or "other"
                                    if not rowsByGroup[g] then
                                        rowsByGroup[g] = {}
                                        groupOrder[#groupOrder + 1] = g
                                    end
                                    table.insert(rowsByGroup[g], row)
                                    end
                                end

                                for _, g in ipairs(groupOrder) do
                                    local groupRows = rowsByGroup[g]
                                    GroupHeader(pad + 22, ns.GetRowGroupLabel(g), modKey, groupRows)
                                    for _, row in ipairs(groupRows) do
                                        ModuleRowControl(pad + 26, modKey, row)
                                    end
                                end

                                local lureRows = expansion.key == "midnight" and ns.BuildLureRows(profession)
                                if lureRows and #lureRows > 0 then
                                    GroupHeader(pad + 22, L["Skin_Lures_Title"], "skin_lures", lureRows)
                                    for _, row in ipairs(lureRows) do
                                        ModuleRowControl(pad + 26, "skin_lures", row)
                                    end
                                end
                            else
                                for _, section in ipairs(GetOrderedProfessionSections(profession)) do
                                    if ShouldShowProfessionSection(section) and #section.entries > 0 then
                                        local function IsSectionEnabled()
                                            for i in ipairs(section.entries) do
                                                local entryId = GetEntryVisibilityId(expansion.key, profession.key, section.key, i)
                                                if entryVisibility[entryId] == false then
                                                    return false
                                                end
                                            end
                                            return true
                                        end
                                        local function SetSectionEnabled(value)
                                            for i in ipairs(section.entries) do
                                                local entryId = GetEntryVisibilityId(expansion.key, profession.key, section.key, i)
                                                entryVisibility[entryId] = value and true or false
                                            end
                                        end
                                        GroupHeader(pad + 22, section.label, nil, nil, IsSectionEnabled, SetSectionEnabled)

                                        for i, entry in ipairs(section.entries) do
                                            local entryId = GetEntryVisibilityId(expansion.key, profession.key, section.key, i)
                                            EntryCheck(pad + 26, entry, section.key, function()
                                                return entryVisibility[entryId] ~= false
                                            end, function(value)
                                                entryVisibility[entryId] = value and true or false
                                                PK.RebuildGatheringLocationsFrame()
                                            end, cr, cg, cb)
                                        end
                                    end
                                end
                            end
                        end
                end
            end
            end
        end
    else
        SecLabel(L["RESETS"])
        Btn(L["Config_ResetColors"], function()
            MR.db.profile.gatheringProfColors = {}
            PK.RebuildGatheringLocationsFrame()
            PopulateGatheringConfig(frame)
        end)
    end

    local totalH = math.abs(yOff) + 10
    if activePage == "display" then
        frame._configMinHeight = math.max(frame._configMinHeight or 0, totalH)
    end
    totalH = math.max(totalH, frame._configMinHeight or totalH)
    body:SetHeight(totalH)
    bodyParent:SetHeight(totalH)
    if frame.configScroll then
        local maxBodyH = math.max(220, math.min(560, (UIParent:GetHeight() or 768) - 120))
        frame:SetHeight(math.min(totalH + 22, maxBodyH + 22))
        if frame.UpdateConfigScrollBar then frame.UpdateConfigScrollBar() end
    else
        frame:SetHeight(totalH)
    end
    if keepLeft and keepTop and MR.RestoreFrameScreenPosition then
        MR:RestoreFrameScreenPosition(frame, keepLeft, keepTop)
    end

end

PK.PopulateGatheringConfig = PopulateGatheringConfig
PK.BuildGatheringConfigFrame = BuildGatheringConfigFrame
