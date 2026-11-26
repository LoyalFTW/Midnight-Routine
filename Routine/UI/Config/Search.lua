local _, ns = ...
if ns.Inactive then return end

local MR = ns.MR
local Config = ns.ConfigInternal
local L = Config.L
local ROW_HEIGHT = 40

local function Normalize(text)
    local cleaned = ns.StripColorCodes(text)
    local lower = strlower or string.lower
    return lower(cleaned):match("^%s*(.-)%s*$")
end

local function BuildIndex()
    local entries = {}
    local page
    local section
    local function Group(pageKey, sectionKey)
        page = pageKey
        section = L[sectionKey]
    end
    local function Add(key, keywords, target)
        local label = L[key]
        entries[#entries + 1] = {
            page = page,
            section = ns.StripColorCodes(section),
            label = ns.StripColorCodes(label),
            target = target or label,
            keywords = keywords,
        }
    end
    local function AddOptions(keys)
        for key in keys:gmatch("%S+") do
            Add(key)
        end
    end

    Group("windows", "Config_TabWindows")
    Add("Config_ShowMainFrame", "tracker")
    Add(MR.isForever and "Forever_OpenReputations" or "Config_OpenRenown")
    if MR.isForever then Add("Forever_OpenSkills") end
    if not MR.isForever or not ns.Forever.hideRares then Add("Config_OpenRares") end
    if not MR.isForever or not ns.Forever.hideProfessions then
        Add(MR.isForever and "Forever_Professions" or "Profession_Knowledge")
    end
    Group("windows", "Config_SectionKeyBinding")
    Add("Config_SetKeyBinding", "hotkey shortcut")
    if MR.isForever then AddOptions("Controller_Enable Controller_ShowHints") end
    Group("windows", "Config_SectionCompletion")
    Add("Config_AutoEnableNewModules")
    Add("Config_HideWhenCompleted", "completed tasks")
    Add("Config_HideCurrenciesWhenCompleted", "currency")
    if not MR.isForever then Add("Config_HideActivitiesWhenWeeklyCompleted", "completed weekly tasks") end
    Group("windows", "Config_SectionFrame")
    AddOptions("Config_LockFrame Config_AutoHidePanelHeaders Config_PeekOnHover Config_WindowPriority")
    Group("windows", "Config_SectionVisibility")
    AddOptions("Config_AutoHideOnLogin Config_HideInInstances Config_DisabledInCombat")
    Group("windows", "Config_SectionReminders")
    Add("Config_ResetReminder", "daily weekly reset")
    if MR.db.profile.resetReminder then Add("Config_ResetReminderWindow") end
    Group("windows", "Config_SectionMinimap")
    AddOptions("Config_HideMinimap Config_MinimapShowGold Config_RememberManagedWindowsVisibility")
    if not MR.isForever then
        Group("windows", "Config_SectionTooltips")
        Add("Config_RaresUnitTooltip")
        Group("windows", "Config_SectionAdventureGuide")
        Add("Config_HideAdventureGuideBossIDs")
        Group("windows", "GreatVault_Title")
        Add("Config_CompactGreatVault")
    end

    Group("layout", "Config_TabLayout")
    AddOptions("Config_InterfaceTheme Config_LayoutMode")
    Group("layout", "Config_Display")
    AddOptions("WIDTH HEIGHT SCALE Config_SyncScale")
    Add("BACKGROUND", "opacity transparency")
    AddOptions("Config_ShowIcons Config_HideStatusBoxes")
    Group("layout", "Config_MainHeaderPosition")
    AddOptions("Config_MainHeaderPosition Config_ShowMainCharacterBar Config_AnimatedMinimize Config_ShowSectionHeaders")
    Group("layout", "Config_TabLayout")
    AddOptions("Config_FontSize Config_SyncFontSize Config_ThemeColor Config_UseClassColor")
    Group("layout", "Config_SharedMedia")
    AddOptions("Config_Font Config_FontStyle Config_BackgroundTexture")
    Group("layout", "Config_TooltipPosition")
    AddOptions("Config_TooltipPosition Config_ShowWarbandTooltips Config_TooltipCharacterLimit")

    Group("modules", "Config_TabModules")
    Add("Config_TabModules", "tracking tasks")
    local source = MR.GetMainFrameProgressSource and MR:GetMainFrameProgressSource()
    for _, mod in ipairs(MR:GetOrderedMainModules()) do
        if Config.IsModuleShown(mod) and Config.IsProfessionModuleKnown(mod, source) then
            entries[#entries + 1] = {
                page = page,
                section = section,
                label = ns.StripColorCodes(mod.label or mod.key),
                target = "module:" .. mod.key,
                module = mod,
                keywords = mod.key:gsub("_", " "),
            }
        end
    end
    Group("support", "Config_TabSupport")
    AddOptions("Config_SupportUs Config_SupportPayPal Config_SupportBuyMeACoffee Config_SupportPatreon Config_SupportDiscord Config_Translators")
    Group("reset", "RESETS")
    AddOptions("Config_ResetEverything Config_ResetColors Config_ResetOrder")
    return entries
end

local function FindMatches(entries, query)
    local words = {}
    for word in query:gmatch("%S+") do words[#words + 1] = word end
    local results = {}
    for index, entry in ipairs(entries) do
        local label = Normalize(entry.label)
        local searchable = label .. " " .. Normalize(entry.section) .. " " .. (entry.keywords or "")
        local score = 0
        for _, word in ipairs(words) do
            if label:find(word, 1, true) then
                score = score + 2
            elseif searchable:find(word, 1, true) then
                score = score + 1
            else
                score = nil
                break
            end
        end
        if score then
            if label == query then
                score = score + 6
            elseif label:find(query, 1, true) == 1 then
                score = score + 4
            elseif label:find(query, 1, true) then
                score = score + 2
            end
            results[#results + 1] = { entry = entry, score = score, index = index }
        end
    end
    table.sort(results, function(a, b)
        if a.score == b.score then return a.index < b.index end
        return a.score > b.score
    end)
    return results
end

function Config.BuildSearch(frame)
    local field = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    field:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28)
    field:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -28)
    field:SetHeight(24)
    field:SetBackdrop(ns.MakeBackdrop())
    ns.HookBackdropFrame(field, "content")
    field:SetBackdropColor(0.02, 0.04, 0.06, 1)
    ns.RegisterThemedBackdropBorder(field, 0.16, 0.28, 0.32, 1)

    local icon = field:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    icon:SetSize(15, 15)
    icon:SetPoint("LEFT", 7, 0)

    local input = CreateFrame("EditBox", nil, field)
    input:SetPoint("TOPLEFT", field, "TOPLEFT", 27, -2)
    input:SetPoint("BOTTOMRIGHT", field, "BOTTOMRIGHT", -26, 2)
    input:SetAutoFocus(false)
    input:SetMaxLetters(80)
    input:SetFontObject(GameFontHighlight)

    local placeholder = field:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    placeholder:SetPoint("LEFT", input, "LEFT")
    placeholder:SetText(L["Config_SearchPlaceholder"])

    local clear = CreateFrame("Button", nil, field)
    clear:SetSize(24, 24)
    clear:SetPoint("RIGHT")
    clear:SetNormalFontObject(GameFontHighlight)
    clear:SetHighlightFontObject(GameFontNormal)
    clear:SetText("×")
    clear:SetScript("OnEnter", function(self)
        ns.ShowTooltip(self, { build = function(tooltip) tooltip:SetText(L["Config_SearchClear"]) end })
    end)
    clear:SetScript("OnLeave", ns.HideOwnedTooltip)
    clear:Hide()

    local scroll, content, updateScroll = ns.CreateScrollArea(frame,
        { "TOPLEFT", frame, "TOPLEFT", 6, -58 },
        { "BOTTOMRIGHT", frame, "BOTTOMRIGHT", -9, 4 },
        { trackWidth = 4, hideTrack = true })
    scroll:Hide()
    local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOP", 0, -12)
    empty:SetText(L["Config_SearchNoResults"])

    local rows = {}
    local entries
    local results

    local function PositionMarker(marker, offset)
        marker:ClearAllPoints()
        marker:SetPoint("TOPLEFT", frame.body, "TOPLEFT", 2, offset + 1)
        marker:SetPoint("TOPRIGHT", frame.body, "TOPRIGHT", -10, offset + 1)
    end

    local function OpenResult(entry)
        input:SetText("")
        input:ClearFocus()
        if entry.module then
            local mod = entry.module
            MR._cfgExpanded = MR._cfgExpanded or {}
            if Config.IsStoryModule(mod) then
                MR._cfgExpanded.__storyCampaigns = true
            elseif mod.profSkillLine then
                MR._cfgExpanded.__professions = true
                MR._cfgExpanded["__profession_expansion:" .. MR:GetModuleExpansionKey(mod)] = true
            end
        end
        MR._cfgPage = entry.page
        MR:PopulateConfigFrame(frame)
        field:SetScript("OnUpdate", function(self)
            self:SetScript("OnUpdate", nil)
            if MR._cfgPage ~= entry.page then return end
            local offset = frame.searchTargets[entry.target]
            if frame.scroll then
                local viewHeight = frame.scroll:GetHeight()
                local maxScroll = math.max(frame.scroll:GetScrollChild():GetHeight() - viewHeight, 0)
                local targetScroll = offset and math.max(0, -offset - viewHeight / 3) or 0
                frame.scroll:SetVerticalScroll(math.min(maxScroll, targetScroll))
                if frame.UpdateScrollBar then frame.UpdateScrollBar() end
            end
            if not offset then return end

            local marker = frame.searchMarker
            if not marker then
                marker = CreateFrame("Frame", nil, frame.body, "BackdropTemplate")
                marker:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
                marker:SetBackdropBorderColor(1, 1, 1, 1)
                marker:SetHeight(20)
                marker:EnableMouse(false)
                marker:Hide()
                marker:SetScript("OnEvent", function(self) self:Hide() end)
                marker:SetScript("OnShow", function(self)
                    self.elapsed = 0
                    self:SetAlpha(1)
                    self:RegisterEvent("GLOBAL_MOUSE_DOWN")
                    self:SetScript("OnUpdate", function(outline, elapsed)
                        outline.elapsed = outline.elapsed + elapsed
                        if outline.elapsed >= 3.2 then
                            outline:SetAlpha(1)
                            outline:SetScript("OnUpdate", nil)
                            return
                        end
                        outline:SetAlpha(0.7 + 0.3 * math.cos(outline.elapsed * math.pi / 0.8))
                    end)
                end)
                marker:SetScript("OnHide", function(self)
                    self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
                    self:SetScript("OnUpdate", nil)
                end)
                frame.searchMarker = marker
            end
            marker:SetFrameLevel(frame.body:GetFrameLevel() + 20)
            marker.entry = entry
            PositionMarker(marker, offset)
            marker:Show()
        end)
    end

    local function CreateResultRow(index)
        local row = CreateFrame("Button", nil, content, "BackdropTemplate")
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(index - 1) * ROW_HEIGHT)
        row:SetHeight(ROW_HEIGHT)
        row:SetBackdrop(ns.MakeBackdrop())
        ns.HookBackdropFrame(row, "content")
        row:SetBackdropColor(0.04, 0.09, 0.14, 1)
        row:SetBackdropBorderColor(0.12, 0.23, 0.26, 1)
        row:SetHighlightTexture("Interface\\Buttons\\UI-Listbox-Highlight2")

        local arrow = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        arrow:SetPoint("RIGHT", -10, 0)
        arrow:SetText("›")

        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.label:SetPoint("TOPLEFT", 10, -6)
        row.label:SetPoint("TOPRIGHT", -26, -6)
        row.label:SetJustifyH("LEFT")
        row.label:SetWordWrap(false)

        row.section = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.section:SetPoint("BOTTOMLEFT", 10, 6)
        row.section:SetPoint("BOTTOMRIGHT", -26, 6)
        row.section:SetJustifyH("LEFT")
        row.section:SetWordWrap(false)

        row:SetScript("OnClick", function(self) OpenResult(self.entry) end)
        rows[index] = row
        return row
    end

    local function RefreshResults()
        local text = input:GetText() or ""
        local query = Normalize(text)
        local searching = query ~= ""
        placeholder:SetShown(text == "")
        clear:SetShown(text ~= "")
        scroll:SetShown(searching)
        if frame.scroll then frame.scroll:SetShown(not searching) end
        if not searching then
            entries = nil
            results = nil
            return
        end

        entries = entries or BuildIndex()
        results = FindMatches(entries, query)
        content:SetWidth(math.max(1, frame:GetWidth() - 15))
        for index, result in ipairs(results) do
            local row = rows[index] or CreateResultRow(index)
            row.entry = result.entry
            row.label:SetText(result.entry.label)
            row.section:SetText(result.entry.section)
            row:Show()
        end
        for index = #results + 1, #rows do
            rows[index].entry = nil
            rows[index]:Hide()
        end
        empty:SetShown(#results == 0)
        content:SetHeight(math.max(ROW_HEIGHT, #results * ROW_HEIGHT))
        scroll:SetVerticalScroll(0)
        updateScroll()
    end

    local function ClearSearch()
        input:SetText("")
        input:ClearFocus()
    end

    frame.RefreshConfigSearch = function()
        entries = nil
        local marker = frame.searchMarker
        if marker and marker:IsShown() then
            local entry = marker.entry
            local offset = entry.page == (MR._cfgPage or "windows") and frame.searchTargets[entry.target]
            if offset then
                PositionMarker(marker, offset)
            else
                marker:Hide()
            end
        end
        if input:GetText() ~= "" then RefreshResults() end
    end
    input:SetScript("OnTextChanged", RefreshResults)
    input:SetScript("OnEscapePressed", ClearSearch)
    input:SetScript("OnEnterPressed", function()
        if results and results[1] then
            OpenResult(results[1].entry)
        else
            input:ClearFocus()
        end
    end)
    clear:SetScript("OnClick", function()
        ns.HideOwnedTooltip(clear)
        input:SetText("")
        input:SetFocus()
    end)
    frame:HookScript("OnHide", function()
        field:SetScript("OnUpdate", nil)
        if frame.searchMarker then frame.searchMarker:Hide() end
        ClearSearch()
    end)
end
