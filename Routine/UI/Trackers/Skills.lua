local _, ns = ...
if ns.Inactive or not ns.MR.isForever then return end

local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")
local WIDTH, HEIGHT, HEADER_HEIGHT, ROW_HEIGHT = 280, 310, 26, 28
local CLASS_SKILL_CATEGORY = 7

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
    row.bar:SetStatusBarColor(0.12, 0.40, 0.74)

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
    local rowCount, headerCount, offset = 0, 0, 0
    for _, group in ipairs(groups) do
        if #group.skills > 0 and group.name then
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
            row:Show()
            offset = offset + ROW_HEIGHT
        end
    end
    ns.HideUnusedWidgets(rows, rowCount)
    ns.HideUnusedWidgets(headers, headerCount)
    frame.empty:SetShown(rowCount == 0)
    frame.content:SetHeight(math.max(ROW_HEIGHT, offset))
    frame.updateScroll()
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
    frame:HookScript("OnHide", function(self) self:UnregisterEvent("SKILL_LINES_CHANGED") end)
    frame:SetScript("OnEvent", RefreshSkills)
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
