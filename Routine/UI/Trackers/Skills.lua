local _, ns = ...
if ns.Inactive or not ns.MR.isForever then return end

local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")
local WIDTH, HEIGHT, HEADER_HEIGHT, ROW_HEIGHT = 280, 310, 26, 28
local MIN_WIDTH, MAX_WIDTH, BAR_HEIGHT = 220, 700, 17
local CLASS_SKILL_CATEGORY = 7
local DEFAULT_COLOR = { 0.12, 0.40, 0.74 }
local SKILL_LAYOUTS = {
    { key = "standard", label = L["Forever_SkillsLayoutStandard"], description = L["Forever_SkillsLayoutStandardDesc"] },
    { key = "compact", label = L["AltBoard_ConcentrationCompactMode"], description = L["Forever_SkillsLayoutCompactDesc"] },
    { key = "text", label = L["Forever_SkillsLayoutText"], description = L["Forever_SkillsLayoutTextDesc"] },
}

local function GetSkillLayout()
    local layout = MR:GetWindowLayoutValue("skillsLayout")
    if layout then return layout end
    return MR:GetWindowLayoutValue("skillsCompact") and "compact" or "standard"
end

local function IsSkillsLocked()
    return MR.db.profile.locked or MR:GetWindowLayoutValue("skillsLocked") == true
end

local function GetSkillsScale()
    local profile = MR.db.profile
    return (not profile.syncWindowScale and MR:GetWindowLayoutValue("skillsScale")) or profile.scale or 1
end

local function GetSkills(frame, pinned)
    local groups, groupsByID, seen = {}, {}, {}
    local api = C_SkillInfo
    if not (api and api.GetNumSkillLines and api.GetSkillLineInfo) then return groups end
    local pinnedGroup = { name = L["Forever_PinnedSkills"], skills = {} }
    groups[1] = pinnedGroup

    local function GetGroup(id)
        local group = groupsByID[id]
        if not group then
            group = { name = frame.skillCategories[id], skills = {} }
            groupsByID[id] = group
            groups[#groups + 1] = group
        end
        return group
    end

    local function Add(info)
        if not info or info.parentSkillLineID ~= 0 then return end
        if info.isHeader then
            if info.skillID == CLASS_SKILL_CATEGORY then return end
            frame.skillCategories[info.skillID] = info.name
            GetGroup(info.skillID).name = info.name
            return
        end
        if info.skillLineCategoryID == CLASS_SKILL_CATEGORY or info.maxRank <= 0 or seen[info.skillID] then return end
        seen[info.skillID] = true
        frame.knownSkills[info.skillID] = true
        local group = pinned[info.skillID] and pinnedGroup or GetGroup(info.skillLineCategoryID)
        group.skills[#group.skills + 1] = info
    end

    for index = 1, api.GetNumSkillLines() do
        Add(api.GetSkillLineInfo(index))
    end
    if api.GetSkillLineInfoByID then
        for id in pairs(frame.knownSkills) do
            if not seen[id] then Add(api.GetSkillLineInfoByID(id)) end
        end
        for id in pairs(pinned) do
            if not seen[id] then Add(api.GetSkillLineInfoByID(id)) end
        end
    end

    local order = MR.db.char.skillsOrder
    for _, group in ipairs(groups) do
        local original = {}
        for index, skill in ipairs(group.skills) do original[skill.skillID] = index end
        table.sort(group.skills, function(a, b)
            local aOrder, bOrder = order[a.skillID] or math.huge, order[b.skillID] or math.huge
            if aOrder == bOrder then return original[a.skillID] < original[b.skillID] end
            return aOrder < bOrder
        end)
    end
    return groups
end

local function CreateSkillRow(frame, refresh)
    local row = CreateFrame("Frame", nil, frame.content)

    row.pin = ns.HeaderToggleButton(row, function()
        return MR.db.char.skillsPinned[row.skillID] and "*" or "+"
    end, L["Forever_PinSkill"], function()
        local pinned = MR.db.char.skillsPinned
        pinned[row.skillID] = not pinned[row.skillID] or nil
        refresh(frame)
        if frame.options and frame.options:IsShown() then frame.options:Refresh() end
    end)
    row.pin:SetPoint("LEFT", row, "LEFT", 4, 0)

    local track = CreateFrame("Frame", nil, row, "BackdropTemplate")
    row.track = track
    track:SetBackdrop(ns.MakeBackdrop())
    track:SetBackdropColor(0.04, 0.04, 0.05, 0.95)
    track:SetBackdropBorderColor(0.37, 0.31, 0.23, 1)

    row.bar = CreateFrame("StatusBar", nil, track)
    row.bar:SetPoint("TOPLEFT", track, "TOPLEFT", 2, -2)
    row.bar:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", -2, 2)
    row.bar:SetStatusBarTexture(ns.GetDefaultBackgroundTexture())

    row.rank = row.bar:CreateFontString(nil, "OVERLAY")
    row.name = row:CreateFontString(nil, "OVERLAY")
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    return row
end

local function RefreshSkills(frame)
    local groups = GetSkills(frame, MR.db.char.skillsPinned)
    local rows = ns.GetWidgetCache(frame, "skillRows")
    local headers = ns.GetWidgetCache(frame, "skillHeaders")
    local fontSize = math.min(14, ns.GetFontSize())
    local hidden, colors = MR.db.char.skillsHidden, MR.db.char.skillsColors
    local layout = GetSkillLayout()
    local barHeight = MR:GetWindowLayoutValue("skillsBarHeight") or BAR_HEIGHT
    local rowHeight = layout == "text" and 21 or barHeight + (layout == "standard" and 11 or 4)
    local showRank = layout == "text" or MR:GetWindowLayoutValue("skillsShowBarRanks") ~= false
    local barFontSize = math.min(fontSize, math.max(8, barHeight - 2))
    local rowCount, headerCount, offset = 0, 0, 0
    for _, group in ipairs(groups) do
        local hasVisibleSkills = false
        for _, skill in ipairs(group.skills) do
            if not hidden[skill.skillID] then
                hasVisibleSkills = true
                break
            end
        end
        if hasVisibleSkills and group.name then
            headerCount = headerCount + 1
            local header = headers[headerCount]
            if not header then
                header = CreateFrame("Frame", nil, frame.content)
                header:SetHeight(20)
                header.label = header:CreateFontString(nil, "OVERLAY")
                header.label:SetPoint("LEFT", 6, 0)
                header.label:SetTextColor(1, 0.80, 0.26)
                headers[headerCount] = header
            end
            ns.SetTwoAnchors(header, "TOPLEFT", frame.content, "TOPLEFT", 0, -offset,
                "TOPRIGHT", frame.content, "TOPRIGHT", 0, -offset)
            header.label:SetFont(ns.FONT_HEADERS, fontSize, ns.GetFontFlags())
            header.label:SetText(group.name)
            header:Show()
            offset = offset + 23
        end
        for _, skill in ipairs(group.skills) do
            if not hidden[skill.skillID] then
                rowCount = rowCount + 1
                local row = rows[rowCount]
                if not row then
                    row = CreateSkillRow(frame, RefreshSkills)
                    rows[rowCount] = row
                end
                ns.SetTwoAnchors(row, "TOPLEFT", frame.content, "TOPLEFT", 0, -offset,
                    "TOPRIGHT", frame.content, "TOPRIGHT", 0, -offset)
                if row.layout ~= layout then
                    row.layout = layout
                    row.track:ClearAllPoints()
                    row.track:SetPoint("RIGHT", row, "RIGHT", -3, 0)
                    row.track:SetShown(layout ~= "text")
                    row.rank:ClearAllPoints()
                    row.name:ClearAllPoints()
                    row.rank:SetParent(layout == "text" and row or row.bar)
                    if layout == "compact" then
                        row.track:SetPoint("LEFT", row.pin, "RIGHT", 5, 0)
                        row.rank:SetPoint("RIGHT", -4, 0)
                        row.name:SetParent(row.bar)
                    else
                        row.track:SetWidth(106)
                        row.name:SetParent(row)
                        row.name:SetPoint("LEFT", row.pin, "RIGHT", 5, 0)
                        if layout == "text" then
                            row.rank:SetPoint("RIGHT", row, "RIGHT", -7, 0)
                            row.name:SetPoint("RIGHT", row.rank, "LEFT", -6, 0)
                        else
                            row.rank:SetPoint("CENTER")
                            row.name:SetPoint("RIGHT", row.track, "LEFT", -6, 0)
                        end
                    end
                end
                row:SetHeight(rowHeight - 3)
                row.track:SetHeight(barHeight)
                row.rank:SetShown(showRank)
                if layout == "compact" then
                    ns.SetTwoAnchors(row.name, "LEFT", row.bar, "LEFT", 4, 0,
                        "RIGHT", showRank and row.rank or row.bar, showRank and "LEFT" or "RIGHT", -6, 0)
                end
                row.skillID = skill.skillID
                row.pin.RefreshLabel()
                row.name:SetFont(ns.FONT_ROWS, layout == "compact" and barFontSize or fontSize, ns.GetFontFlags())
                row.rank:SetFont(ns.FONT_ROWS, layout == "text" and fontSize or barFontSize, ns.GetFontFlags())
                row.name:SetText(skill.name)
                row.rank:SetText(("%d / %d"):format(skill.rank, skill.maxRank))
                row.bar:SetMinMaxValues(0, skill.maxRank)
                row.bar:SetValue(skill.rank)
                row.bar:SetStatusBarColor(unpack(colors[skill.skillID] or DEFAULT_COLOR))
                row:Show()
                offset = offset + rowHeight
            end
        end
    end
    ns.HideUnusedWidgets(rows, rowCount)
    ns.HideUnusedWidgets(headers, headerCount)
    frame.empty:SetShown(rowCount == 0)
    frame.content:SetHeight(math.max(ROW_HEIGHT, offset))
    frame.updateScroll()
end

local function CreateSkillsOptions(frame)
    local options = ns.StyledFrame(UIParent, nil, "DIALOG", 15)
    options:Hide()
    options:SetSize(295, 366)
    local title = ns.TitleBar(options, HEADER_HEIGHT)
    local heading = title:CreateFontString(nil, "OVERLAY")
    heading:SetFont(ns.FONT_HEADERS, 13, ns.GetFontFlags())
    heading:SetPoint("LEFT", 9, 0)
    heading:SetText(L["Forever_SkillsOptions"])
    ns.CloseButton(title, function() options:Hide() end)

    local layoutPage = CreateFrame("Frame", nil, options)
    local modulesPage = CreateFrame("Frame", nil, options)
    for _, page in ipairs({ layoutPage, modulesPage }) do
        page:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -30)
        page:SetPoint("BOTTOMRIGHT", options, "BOTTOMRIGHT")
    end
    local activePage = layoutPage
    local tabs = {
        { page = layoutPage, label = L["Config_TabLayout"] },
        { page = modulesPage, label = L["Config_TabModules"] },
    }
    for index, tab in ipairs(tabs) do
        local button = CreateFrame("Button", nil, options, "BackdropTemplate")
        tab.button = button
        button:SetSize(138, 18)
        button:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 8 + (index - 1) * 141, -5)
        button:SetBackdrop(ns.MakeBackdrop())
        ns.HookBackdropFrame(button, "control")
        local label = button:CreateFontString(nil, "OVERLAY")
        tab.text = label
        label:SetFont(ns.FONT_ROWS, 12, ns.GetFontFlags())
        label:SetPoint("CENTER")
        label:SetText(tab.label)
        button:SetScript("OnClick", function()
            activePage = tab.page
            options:Refresh()
        end)
    end

    local _, content, update = ns.CreateScrollArea(modulesPage,
        { "TOPLEFT", modulesPage, "TOPLEFT", 8, -3 },
        { "BOTTOMRIGHT", modulesPage, "BOTTOMRIGHT", -17, 78 },
        { contentWidth = 270 })
    local rows = ns.GetWidgetCache(options, "skillOptions")
    local headers = ns.GetWidgetCache(options, "skillOptionHeaders")
    local char = MR.db.char
    local addGrip, cancelDrag = ns.CreateRowReorder(options, content, 0)
    local resettingColors = false
    local dropdownY = ns.OptionsSectionLabel(layoutPage, -2, L["Config_Display"], 8, 12)
    local controls = CreateFrame("Frame", nil, layoutPage)
    controls:SetSize(295, 240)
    controls:SetPoint("TOPLEFT", layoutPage, "TOPLEFT", 0, -75)
    local description = layoutPage:CreateFontString(nil, "OVERLAY")
    description:SetFont(ns.FONT_ROWS, 11, ns.GetFontFlags())
    description:SetJustifyH("LEFT")
    description:SetJustifyV("TOP")
    local layoutDropdown = ns.CreateDropdown(layoutPage, {
        style = "gold",
        width = 279,
        height = 22,
        fontSize = 12,
        getOptions = function() return SKILL_LAYOUTS end,
        getSelected = GetSkillLayout,
        onSelect = function(key)
            MR:SetWindowLayoutValue("skillsLayout", key)
            RefreshSkills(frame)
            options:RefreshLayout()
        end,
    })
    layoutDropdown:SetPoint("TOPLEFT", layoutPage, "TOPLEFT", 8, dropdownY)
    description:SetPoint("TOPLEFT", layoutDropdown, "BOTTOMLEFT", 0, -4)
    description:SetPoint("TOPRIGHT", layoutDropdown, "BOTTOMRIGHT", 0, -4)

    local function RefreshLayout()
        layoutDropdown:Update()
        local layout = GetSkillLayout()
        for _, option in ipairs(SKILL_LAYOUTS) do
            if option.key == layout then
                description:SetText(option.description)
                break
            end
        end
        local pool = ns.StartWidgetPool(controls)
        local y = 0
        local function Check(label, key, default, apply)
            y = ns.OptionsCheckbox(controls, y, label, function()
                local value = MR:GetWindowLayoutValue(key)
                if value == nil then return default end
                return value
            end, function(value)
                MR:SetWindowLayoutValue(key, value and true or false)
                if apply then apply() end
            end, nil, nil, nil, 8, nil, 12)
        end
        local function Slider(label, key, default, min, max, step, apply, disabled, getValue)
            y = ns.OptionsSlider(controls, y, label, min, max, step, function()
                return getValue and getValue() or MR:GetWindowLayoutValue(key) or default
            end, function(value)
                MR:SetWindowLayoutValue(key, value)
                apply()
            end, nil, nil, nil, 8, disabled, 12)
        end
        Check(L["Config_LockPosition"], "skillsLocked", false)
        Check(L["Forever_SkillsShowBarRanks"], "skillsShowBarRanks", true, function() RefreshSkills(frame) end)
        Check(L["Forever_SkillsAutoHideHeader"], "skillsAutoHideHeader", false, function()
            MR:RefreshPanelHeaderVisibility(frame)
        end)
        y = ns.OptionsDivider(controls, y - 3, 8)
        Slider(L["WIDTH"], "skillsWidth", WIDTH, MIN_WIDTH, MAX_WIDTH, 1, function() frame:ApplySkillsSize() end)
        Slider(L["Config_BarHeight"], "skillsBarHeight", BAR_HEIGHT, 10, 30, 1,
            function() RefreshSkills(frame) end, layout == "text")
        Slider(L["BACKGROUND"], "skillsBackground", 1, 0, 1, 0.05, function() frame:ApplySkillsBackground() end)
        Slider(L["SCALE"], "skillsScale", 1, 0.5, 2, 0.05,
            function() frame:ApplySkillsScale() end, MR.db.profile.syncWindowScale == true, GetSkillsScale)
        ns.FinishWidgetPool(pool)
    end

    function options:RefreshLayout()
        if activePage == layoutPage then RefreshLayout() end
    end

    function options:Refresh()
        cancelDrag()
        for _, tab in ipairs(tabs) do
            local selected = tab.page == activePage
            tab.page:SetShown(selected)
            tab.button._mrControlActive = selected
            tab.button:SetBackdropColor(selected and 0.11 or 0.05, selected and 0.24 or 0.09, selected and 0.23 or 0.15, 1)
            tab.button:SetBackdropBorderColor(selected and 0.22 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
            tab.text:SetTextColor(selected and 0.85 or 0.62, selected and 1 or 0.75, selected and 0.92 or 0.70)
        end
        if activePage == layoutPage then
            RefreshLayout()
            return
        end
        local groups = GetSkills(frame, char.skillsPinned)
        local offset, headerCount = 0, 0
        for _, row in pairs(rows) do row:Hide() end
        for _, group in ipairs(groups) do
            if group.name and #group.skills > 0 then
                headerCount = headerCount + 1
                local label = headers[headerCount]
                if not label then
                    label = content:CreateFontString(nil, "OVERLAY")
                    label:SetTextColor(1, 0.80, 0.26)
                    headers[headerCount] = label
                end
                ns.SetOneAnchor(label, "TOPLEFT", content, "TOPLEFT", 4, -offset)
                label:SetFont(ns.FONT_HEADERS, 12, ns.GetFontFlags())
                label:SetText(group.name)
                label:Show()
                offset = offset + 19
            end
            for index, skill in ipairs(group.skills) do
                local id = skill.skillID
                local row = rows[id]
                if not row then
                    row = CreateFrame("Frame", nil, content)
                    rows[id] = row
                    row:SetHeight(ROW_HEIGHT)
                    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    ns.ThemeCheckButton(row.check)
                    row.check:SetSize(20, 20)
                    row.check:SetPoint("LEFT", row, "LEFT", 18, 0)
                    row.check:SetScript("OnClick", function(button)
                        char.skillsHidden[id] = not button:GetChecked() or nil
                        RefreshSkills(frame)
                    end)
                    addGrip(row, ROW_HEIGHT, function()
                        local list, frames = row.group, {}
                        for index, entry in ipairs(list) do frames[index] = rows[entry.skillID] end
                        return frames, row.index, row.name:GetText(), function(from, target)
                            table.insert(list, target, table.remove(list, from))
                            for order, entry in ipairs(list) do char.skillsOrder[entry.skillID] = order end
                            RefreshSkills(frame)
                            options:Refresh()
                        end
                    end)
                    local r, g, b = unpack(char.skillsColors[id] or DEFAULT_COLOR)
                    local swatch = ns.OptionsColorSwatch(row, r, g, b, function(red, green, blue)
                        char.skillsColors[id] = { red, green, blue }
                        RefreshSkills(frame)
                    end, function()
                        char.skillsColors[id] = nil
                        if not resettingColors then RefreshSkills(frame) end
                        return unpack(DEFAULT_COLOR)
                    end, skill.name .. L["Color_Reset_Hint"])
                    swatch:SetPoint("RIGHT", -2, 0)
                    row.swatch = swatch
                    row.name = row:CreateFontString(nil, "OVERLAY")
                    row.name:SetPoint("LEFT", row.check, "RIGHT", 3, 0)
                    row.name:SetPoint("RIGHT", swatch, "LEFT", -5, 0)
                    row.name:SetJustifyH("LEFT")
                    row.name:SetWordWrap(false)
                end
                row.group, row.index = group.skills, index
                row.check:SetChecked(not char.skillsHidden[id])
                row.name:SetFont(ns.FONT_ROWS, math.min(14, ns.GetFontSize()), ns.GetFontFlags())
                row.name:SetText(skill.name)
                ns.SetTwoAnchors(row, "TOPLEFT", content, "TOPLEFT", 0, -offset,
                    "TOPRIGHT", content, "TOPRIGHT", 0, -offset)
                row:Show()
                offset = offset + ROW_HEIGHT
            end
        end
        ns.HideUnusedWidgets(headers, headerCount)
        content:SetHeight(math.max(1, offset))
        update()
    end
    local resetY = ns.OptionsSectionLabel(modulesPage, -238, L["RESETS"], 8, 12)
    resetY = ns.OptionsBtn(modulesPage, resetY, L["Config_ResetColors"], function()
        resettingColors = true
        for id, row in pairs(rows) do
            if char.skillsColors[id] then
                local swatch = row.swatch
                swatch:GetScript("OnClick")(swatch, "RightButton")
            end
        end
        wipe(char.skillsColors)
        resettingColors = false
        RefreshSkills(frame)
    end, 279, 8, 12)
    ns.OptionsBtn(modulesPage, resetY, L["Forever_ResetSkillOrder"], function()
        wipe(char.skillsOrder)
        RefreshSkills(frame)
        options:Refresh()
    end, 279, 8, 12)
    return options
end

local function CreateSkillsFrame()
    local frame = ns.StyledFrame(UIParent, nil, "MEDIUM", 10)
    frame:Hide()
    frame:SetSize(WIDTH, HEIGHT)
    MR:RegisterPriorityFrame(frame)
    frame.knownSkills = {}
    frame.skillCategories = {}
    MR.skillsFrame = frame
    local bottom = ns.IsManagedHeaderBottom()
    ns.RestoreManagedFramePos(frame, "skillsPos", 320, 30)

    local title = ns.TitleBar(frame, HEADER_HEIGHT)
    if bottom then
        title:ClearAllPoints()
        title:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT")
        title:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT")
    end
    title:SetScript("OnDragStart", function()
        if not IsSkillsLocked() then
            frame:StartMoving()
            frame.skillsMoving = true
        end
    end)
    title:SetScript("OnDragStop", function()
        if not frame.skillsMoving then return end
        frame.skillsMoving = nil
        frame:StopMovingOrSizing()
        ns.SaveManagedFramePos(frame, "skillsPos", bottom and "bottom" or "top")
    end)
    local heading = title:CreateFontString(nil, "OVERLAY")
    heading:SetFont(ns.FONT_HEADERS, 13, ns.GetFontFlags())
    heading:SetPoint("LEFT", 9, 0)
    heading:SetText(L["Forever_OpenSkills"])
    ns.RegisterThemedFontString(heading, 0.85, 0.65, 0.10)
    local close = ns.CloseButton(title, function() MR:HideSkills() end)

    local scroll, content, update, track = ns.CreateScrollArea(frame,
        { "TOPLEFT", bottom and frame or title, bottom and "TOPLEFT" or "BOTTOMLEFT", 7, -5 },
        { "BOTTOMRIGHT", bottom and title or frame, bottom and "TOPRIGHT" or "BOTTOMRIGHT", -15, 5 },
        { contentWidth = WIDTH - 22 })
    local grip = ns.CreateManagedResizeGrip(frame, bottom, IsSkillsLocked)
    local function StopResize()
        if not grip:GetScript("OnUpdate") then return end
        grip:SetScript("OnUpdate", nil)
        if frame.options and frame.options:IsShown() then frame.options:RefreshLayout() end
    end
    grip:SetScript("OnHide", StopResize)
    grip:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then StopResize() end
    end)
    grip:SetScript("OnMouseDown", function(_, button)
        if button ~= "LeftButton" or IsSkillsLocked() then return end
        ns.SyncManagedFramePos(frame, "skillsPos", bottom and "bottom" or "top")
        local startX, startY = GetCursorPosition()
        local startWidth, startHeight = frame:GetWidth(), frame:GetHeight()
        grip:SetScript("OnUpdate", function()
            if IsSkillsLocked() or not IsMouseButtonDown("LeftButton") then
                StopResize()
                return
            end
            local x, y = GetCursorPosition()
            local scale = frame:GetEffectiveScale()
            local width = math.max(MIN_WIDTH, math.min(MAX_WIDTH, math.floor(startWidth + (x - startX) / scale)))
            local height = math.max(100, math.min(900, math.floor(startHeight + (y - startY) / scale * (bottom and 1 or -1))))
            if width ~= frame:GetWidth() or height ~= frame:GetHeight() then
                MR:SetWindowLayoutValue("skillsWidth", width)
                MR:SetWindowLayoutValue("skillsHeight", height)
                frame:ApplySkillsSize()
            end
        end)
    end)
    function frame:RefreshHeaderPosition()
        local useBottom = ns.IsManagedHeaderBottom()
        if bottom == useBottom then return end
        StopResize()
        bottom = useBottom
        local side = bottom and "BOTTOM" or "TOP"
        title:ClearAllPoints()
        title:SetPoint(side .. "LEFT", self, side .. "LEFT")
        title:SetPoint(side .. "RIGHT", self, side .. "RIGHT")
        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT", bottom and self or title, bottom and "TOPLEFT" or "BOTTOMLEFT", 7, -5)
        scroll:SetPoint("BOTTOMRIGHT", bottom and title or self, bottom and "TOPRIGHT" or "BOTTOMRIGHT", -15, 5)
        local corner = bottom and "TOPRIGHT" or "BOTTOMRIGHT"
        ns.SetOneAnchor(grip, corner, self, corner, -1, bottom and -1 or 1)
        ns.SyncManagedFramePos(self, "skillsPos", bottom and "bottom" or "top")
        ns.RefreshPanelTitleBorder(self)
    end
    frame.content, frame.updateScroll = content, update
    frame.empty = content:CreateFontString(nil, "OVERLAY")
    frame.empty:SetFont(ns.FONT_ROWS, 12, ns.GetFontFlags())
    frame.empty:SetPoint("TOP", 0, -6)
    frame.empty:SetText(L["Forever_NoSkills"])

    function frame:ApplySkillsSize()
        local minimized = MR:GetWindowLayoutValue("skillsMinimized") == true
        local width = MR:GetWindowLayoutValue("skillsWidth") or WIDTH
        local height = MR:GetWindowLayoutValue("skillsHeight") or HEIGHT
        scroll:SetShown(not minimized)
        track:SetShown(not minimized)
        grip:SetShown(not minimized)
        content:SetWidth(width - 22)
        frame:SetSize(width, minimized and HEADER_HEIGHT or height)
        MR:RefreshPanelHeaderVisibility(frame)
    end
    local minimize = ns.HeaderToggleButton(title, function()
        return MR:GetWindowLayoutValue("skillsMinimized") and "+" or "-"
    end,
        L["UI_Collapse"], function()
            ns.SyncManagedFramePos(frame, "skillsPos", bottom and "bottom" or "top")
            MR:SetWindowLayoutValue("skillsMinimized", not MR:GetWindowLayoutValue("skillsMinimized"))
            frame:ApplySkillsSize()
        end)
    minimize:SetPoint("RIGHT", close, "LEFT", -5, 0)
    local gear = ns.HeaderIconButton(title, "Interface\\Buttons\\UI-OptionsButton",
        { 0.85, 0.65, 0.20 }, { 1, 1, 1 }, L["Forever_SkillsOptions"], function()
            local options = frame.options
            if options and options:IsShown() then
                options:Hide()
                return
            end
            options = options or CreateSkillsOptions(frame)
            frame.options = options
            options:SetScale(MR.db.profile.scale or 1)
            ns.SetOneAnchor(options, "TOPLEFT", frame, "TOPRIGHT", 5, 0)
            options:Show()
            options:Refresh()
        end)
    gear:SetPoint("RIGHT", minimize, "LEFT", -5, 0)
    MR:ApplyPanelHeaderAutoHide(frame, title, function()
        return MR:GetWindowLayoutValue("skillsAutoHideHeader") == true
    end)
    function frame:ApplySkillsBackground()
        local bg = ns.COLORS.bg
        local header = ns.COLORS.titlebar
        local alpha = MR:GetWindowLayoutValue("skillsBackground") or 1
        self:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] * alpha)
        title:SetBackdropColor(header[1], header[2], header[3], alpha)
    end
    function frame:ApplySkillsScale()
        self:SetScale(GetSkillsScale())
    end
    frame:ApplySkillsSize()
    frame:ApplySkillsBackground()
    function frame:RefreshSavedLayout()
        StopResize()
        ns.RestoreManagedFramePos(self, "skillsPos", 320, 30)
        self:ApplySkillsSize()
        self:ApplySkillsBackground()
        self:ApplySkillsScale()
        minimize.RefreshLabel()
        RefreshSkills(self)
        if self.options and self.options:IsShown() then self.options:Refresh() end
    end
    frame:HookScript("OnShow", function(self)
        self:RegisterEvent("SKILL_LINES_CHANGED")
        RefreshSkills(self)
    end)
    frame:HookScript("OnHide", function(self)
        self:UnregisterEvent("SKILL_LINES_CHANGED")
        if self.options then self.options:Hide() end
    end)
    frame:SetScript("OnEvent", function(self)
        RefreshSkills(self)
        if self.options and self.options:IsShown() then self.options:Refresh() end
    end)
    return frame
end

function MR:EnsureSkillsShown()
    self:SetManagedWindowOpen("skillsOpen", true)
    if self._instanceFramesHidden then return end
    local frame = self.skillsFrame or CreateSkillsFrame()
    frame:ApplySkillsScale()
    frame:RefreshHeaderPosition()
    frame:Show()
end

function MR:HideSkills(persistState)
    if self.skillsFrame then self.skillsFrame:Hide() end
    if persistState ~= false then self:SetManagedWindowOpen("skillsOpen", false) end
end

function MR:ToggleSkills()
    if self:GetManagedWindowOpen("skillsOpen") and
        (self._instanceFramesHidden or self.skillsFrame and self.skillsFrame:IsShown()) then
        self:HideSkills()
    else
        self:ClearManagedWindowsBundleHidden()
        self:EnsureSkillsShown()
    end
end
