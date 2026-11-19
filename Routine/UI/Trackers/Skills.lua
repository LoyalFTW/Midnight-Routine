local _, ns = ...
if ns.Inactive or not ns.MR.isForever then return end

local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")
local WIDTH, HEIGHT, HEADER_HEIGHT, ROW_HEIGHT = 280, 310, 26, 28
local CLASS_SKILL_CATEGORY = 7
local DEFAULT_COLOR = { 0.12, 0.40, 0.74 }

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
    row:SetHeight(ROW_HEIGHT - 3)

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
    track:SetSize(106, 17)
    track:SetPoint("RIGHT", row, "RIGHT", -3, 0)
    track:SetBackdrop(ns.MakeBackdrop())
    track:SetBackdropColor(0.04, 0.04, 0.05, 0.95)
    track:SetBackdropBorderColor(0.37, 0.31, 0.23, 1)

    row.bar = CreateFrame("StatusBar", nil, track)
    row.bar:SetPoint("TOPLEFT", track, "TOPLEFT", 2, -2)
    row.bar:SetPoint("BOTTOMRIGHT", track, "BOTTOMRIGHT", -2, 2)
    row.bar:SetStatusBarTexture(ns.GetDefaultBackgroundTexture())

    row.rank = row.bar:CreateFontString(nil, "OVERLAY")
    row.rank:SetPoint("CENTER")
    row.name = row:CreateFontString(nil, "OVERLAY")
    row.name:SetPoint("LEFT", row.pin, "RIGHT", 5, 0)
    row.name:SetPoint("RIGHT", track, "LEFT", -6, 0)
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
                header = CreateFrame("Frame", nil, frame.content, "BackdropTemplate")
                header:SetHeight(20)
                header:SetBackdrop(ns.MakeBackdrop())
                ns.HookBackdropFrame(header, "settingsSection")
                header:SetBackdropColor(0.16, 0.11, 0.06, 0.82)
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
                row.skillID = skill.skillID
                row.pin.RefreshLabel()
                row.name:SetFont(ns.FONT_ROWS, fontSize, ns.GetFontFlags())
                row.rank:SetFont(ns.FONT_ROWS, fontSize, ns.GetFontFlags())
                row.name:SetText(skill.name)
                row.rank:SetText(("%d / %d"):format(skill.rank, skill.maxRank))
                row.bar:SetMinMaxValues(0, skill.maxRank)
                row.bar:SetValue(skill.rank)
                row.bar:SetStatusBarColor(unpack(colors[skill.skillID] or DEFAULT_COLOR))
                row:Show()
                offset = offset + ROW_HEIGHT
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
    options:SetSize(295, 310)
    local title = ns.TitleBar(options, HEADER_HEIGHT)
    local heading = title:CreateFontString(nil, "OVERLAY")
    heading:SetFont(ns.FONT_HEADERS, 13, ns.GetFontFlags())
    heading:SetPoint("LEFT", 9, 0)
    heading:SetText(L["Forever_SkillsOptions"])
    ns.CloseButton(title, function() options:Hide() end)

    local _, content, update = ns.CreateScrollArea(options,
        { "TOPLEFT", title, "BOTTOMLEFT", 8, -7 },
        { "BOTTOMRIGHT", options, "BOTTOMRIGHT", -17, 78 },
        { contentWidth = 270 })
    local rows = ns.GetWidgetCache(options, "skillOptions")
    local headers = ns.GetWidgetCache(options, "skillOptionHeaders")
    local char = MR.db.char
    local addGrip, cancelDrag = ns.CreateRowReorder(options, content, 0)
    local resettingColors = false

    function options:Refresh()
        cancelDrag()
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
    local resetY = ns.OptionsSectionLabel(options, -238, L["RESETS"], 8, 12)
    resetY = ns.OptionsBtn(options, resetY, L["Config_ResetColors"], function()
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
    ns.OptionsBtn(options, resetY, L["Forever_ResetSkillOrder"], function()
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
        if not MR.db.profile.locked then frame:StartMoving() end
    end)
    title:SetScript("OnDragStop", function()
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
    function frame:RefreshHeaderPosition()
        local useBottom = ns.IsManagedHeaderBottom()
        if bottom == useBottom then return end
        bottom = useBottom
        local side = bottom and "BOTTOM" or "TOP"
        title:ClearAllPoints()
        title:SetPoint(side .. "LEFT", self, side .. "LEFT")
        title:SetPoint(side .. "RIGHT", self, side .. "RIGHT")
        scroll:ClearAllPoints()
        scroll:SetPoint("TOPLEFT", bottom and self or title, bottom and "TOPLEFT" or "BOTTOMLEFT", 7, -5)
        scroll:SetPoint("BOTTOMRIGHT", bottom and title or self, bottom and "TOPRIGHT" or "BOTTOMRIGHT", -15, 5)
        ns.SyncManagedFramePos(self, "skillsPos", bottom and "bottom" or "top")
        ns.RefreshPanelTitleBorder(self)
    end
    frame.content, frame.updateScroll = content, update
    frame.empty = content:CreateFontString(nil, "OVERLAY")
    frame.empty:SetFont(ns.FONT_ROWS, 12, ns.GetFontFlags())
    frame.empty:SetPoint("TOP", 0, -6)
    frame.empty:SetText(L["Forever_NoSkills"])

    local function ApplyMinimized()
        local minimized = MR:GetWindowLayoutValue("skillsMinimized") == true
        scroll:SetShown(not minimized)
        track:SetShown(not minimized)
        frame:SetHeight(minimized and HEADER_HEIGHT or HEIGHT)
        MR:RefreshPanelHeaderVisibility(frame)
    end
    local minimize = ns.HeaderToggleButton(title, function()
        return MR:GetWindowLayoutValue("skillsMinimized") and "+" or "-"
    end,
        L["UI_Collapse"], function()
            ns.SyncManagedFramePos(frame, "skillsPos", bottom and "bottom" or "top")
            MR:SetWindowLayoutValue("skillsMinimized", not MR:GetWindowLayoutValue("skillsMinimized"))
            ApplyMinimized()
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
            options:SetScale(frame:GetScale())
            options:SetPoint("TOPLEFT", frame, "TOPRIGHT", 5, 0)
            options:Show()
            options:Refresh()
        end)
    gear:SetPoint("RIGHT", minimize, "LEFT", -5, 0)
    MR:ApplyPanelHeaderAutoHide(frame, title)
    ApplyMinimized()
    function frame:RefreshSavedLayout()
        ns.RestoreManagedFramePos(self, "skillsPos", 320, 30)
        ApplyMinimized()
        minimize.RefreshLabel()
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
    frame:SetScale(self.db.profile.scale or 1)
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
