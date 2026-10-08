local _, ns = ...
if ns.MR.isForever and ns.Forever.hideRares then return end
local MR = ns.MR

local FONT_HEADERS = ns.FONT_HEADERS
local FONT_ROWS = ns.FONT_ROWS
local StyledFrame = ns.StyledFrame
local RestoreManagedFramePos = ns.RestoreManagedFramePos
local SaveManagedFramePos = ns.SaveManagedFramePos
local SyncManagedFramePos = ns.SyncManagedFramePos
local AnimateManagedFrameHeight = ns.AnimateManagedFrameHeight
local IsManagedHeaderBottom = ns.IsManagedHeaderBottom
local TopAccent = ns.TopAccent
local TitleBar = ns.TitleBar
local CloseButton = ns.CloseButton
local HeaderIconButton = ns.HeaderIconButton
local HeaderToggleButton = ns.HeaderToggleButton
local MakeBackdrop = ns.MakeBackdrop
local OptionsGap = ns.OptionsGap
local OptionsDivider = ns.OptionsDivider
local OptionsSectionLabel = ns.OptionsSectionLabel
local OptionsCheckbox = ns.OptionsCheckbox
local OptionsSlider = ns.OptionsSlider
local OptionsBtn = ns.OptionsBtn
local OptionsColorSwatch = ns.OptionsColorSwatch
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)

local function RefreshFonts()
    if ns.EnsureFonts then
        FONT_HEADERS, FONT_ROWS = ns.EnsureFonts()
        return
    end

    FONT_HEADERS = ns.FONT_HEADERS or FONT_HEADERS
    FONT_ROWS = ns.FONT_ROWS or FONT_ROWS
end

local GetFontFlags = ns.GetFontFlags

local ZONES = MR.tracker:CreateRareCatalog(MR, L)

local ZONE_BY_KEY = {}
for _, z in ipairs(ZONES) do ZONE_BY_KEY[z.key] = z end

local rareTracker = MR.tracker:CreateRareTracker(MR, ZONES, {
    getCurrentForeverZone = function() return ns.Forever.GetCurrentRareZoneKey() end,
    getForeverZones = function() return ns.Forever.GetRareZones() end,
    refreshZones = function() MR:RefreshRareTrackingZones() end,
    isSurfaceVisible = function() return MR:IsRareTrackingSurfaceVisible() end,
})
local GetCurrentZoneKey = rareTracker.GetCurrentZoneKey
local GetCurrentDayKey = rareTracker.GetCurrentDayKey
local SyncRareKillRecord = rareTracker.SyncRareKillRecord
local GetRareTrackedKillStatus = rareTracker.GetRareTrackedKillStatus
local IsRareQuestCompleted = rareTracker.IsRareQuestCompleted
local GetStoredRareKillStatus = rareTracker.GetStoredRareKillStatus
local BetterKillStatus = rareTracker.BetterKillStatus
local IsAchievementCriteriaCompleted = rareTracker.IsAchievementCriteriaCompleted
local GetZoneStatus = rareTracker.GetZoneStatus

local function GetCharacterTooltipName(charKey, charData, currentKey)
    local name = type(charKey) == "string" and charKey:match("^(.-)%s%-%s.+$") or nil
    name = name or tostring(charKey or L["Unknown"] or "Unknown")

    if charKey == currentKey then
        name = string.format("%s (%s)", name, L["AltBoard_Current"] or "Current")
    end

    local classColor = charData and charData.classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[charData.classFile]
    if classColor and classColor.colorStr then
        return string.format("|c%s%s|r", classColor.colorStr, name)
    end

    return name
end

local function GetWarbandRareStatuses(rare, expanded)
    local svChars = MR.db and MR.db.sv and MR.db.sv.char
    local questKey = rare and rare[2] and tostring(rare[2]) or nil
    local npcKey = rare and rare[6] and ("npc:" .. tostring(rare[6])) or nil
    if type(svChars) ~= "table" or not (questKey or npcKey) then
        return nil, 0, 0
    end

    local weekKey = MR:GetCurrentWeekKey()
    if not weekKey or weekKey == 0 then
        return nil, 0, 0
    end

    local dayKey = GetCurrentDayKey()
    local currentKey = MR.GetCurrentCharacterKey and MR:GetCurrentCharacterKey() or nil
    local hiddenChars = (MR.db and MR.db.profile and MR.db.profile.altBoardHiddenCharacters) or {}
    local showHidden = MR.db and MR.db.profile and MR.db.profile.altBoardShowHidden == true
    local weeklyReset = MR.GetLastResetTimestamp and MR:GetLastResetTimestamp() or 0
    local rows, killed = {}, 0

    for charKey, charData in pairs(svChars) do
        if type(charData) == "table" and (showHidden or not hiddenChars[charKey]) then
            local status = BetterKillStatus(
                GetStoredRareKillStatus(charData, questKey, weekKey, dayKey),
                GetStoredRareKillStatus(charData, npcKey, weekKey, dayKey)
            )
            local lastSyncAt = tonumber(charData.lastSyncAt) or 0
            local stale = weeklyReset > 0 and lastSyncAt > 0 and lastSyncAt < weeklyReset
            if status then
                killed = killed + 1
            end

            rows[#rows + 1] = {
                key = charKey,
                name = GetCharacterTooltipName(charKey, charData, currentKey),
                status = status,
                stale = stale,
                current = charKey == currentKey,
            }
        end
    end

    local orderIndex = expanded and MR:GetAltBoardCharacterOrderIndex() or nil
    table.sort(rows, function(a, b)
        if a.current ~= b.current then return a.current end
        if orderIndex then
            local aOrder = orderIndex[a.key] or math.huge
            local bOrder = orderIndex[b.key] or math.huge
            if aOrder ~= bOrder then return aOrder < bOrder end
        end
        if (a.status ~= nil) ~= (b.status ~= nil) then return a.status ~= nil end
        if a.status ~= b.status then
            if a.status == "today" then return true end
            if b.status == "today" then return false end
            if a.status == "week" then return true end
            if b.status == "week" then return false end
        end
        if a.stale ~= b.stale then return not a.stale end
        return (a.key or "") < (b.key or "")
    end)

    return rows, killed, #rows
end

local WARBAND_SHORT_LIST_COUNT = 4

local function AddWarbandRareTooltipLines(tip, rare)
    local expanded = IsShiftKeyDown()
    local rows, killed, total = GetWarbandRareStatuses(rare, expanded)
    if not rows or total <= 0 then
        return
    end

    local headerText = L["Rares_Tooltip_WarbandHeader"] or "Warband: %d of %d characters killed this week"
    tip:AddLine(" ")
    tip:AddLine(string.format(headerText, killed, total), 0.65, 0.90, 1)

    local shown = expanded and total or math.min(total, WARBAND_SHORT_LIST_COUNT)
    for i = 1, shown do
        local row = rows[i]
        if row.status == "today" then
            tip:AddDoubleLine(row.name, L["Rares_Tooltip_WarbandToday"] or "Killed today", 0.90, 0.90, 0.90, 0.20, 0.85, 0.45)
        elseif row.status == "week" then
            tip:AddDoubleLine(row.name, L["Rares_Tooltip_WarbandWeek"] or "Killed this week", 0.90, 0.90, 0.90, 0.85, 0.65, 0.10)
        elseif row.stale then
            tip:AddDoubleLine(row.name, L["Rares_Tooltip_WarbandStale"] or "Needs login", 0.65, 0.65, 0.65, 0.70, 0.70, 0.70)
        else
            tip:AddDoubleLine(row.name, L["Rares_Tooltip_WarbandNotKilled"] or "Not killed", 0.90, 0.90, 0.90, 0.50, 0.50, 0.50)
        end
    end

    if not expanded and total > shown then
        tip:AddLine(L["Rares_Tooltip_HoldShiftFullList"] or "Hold Shift for full list", 0.55, 0.55, 0.60)
    end
end

local function GetZoneColor(zone)
    local db = MR.db and MR.db.profile or {}
    if db.raresColors and db.raresColors[zone.key] then
        local c = db.raresColors[zone.key]
        return c[1], c[2], c[3]
    end
    return zone.color[1], zone.color[2], zone.color[3]
end

local function SetZoneColor(zone, r, g, b)
    local db = MR.db.profile
    if not db.raresColors then db.raresColors = {} end
    db.raresColors[zone.key] = { r, g, b }
end

local function ResetZoneColor(zone)
    local db = MR.db.profile
    if db.raresColors then db.raresColors[zone.key] = nil end
end

local OUTER_PAD  = 6
local DEFAULT_W  = 300
local DEFAULT_H  = 360
local MIN_W      = 160
local MAX_W      = 600
local MIN_H      = 60
local MAX_H      = 800
local TITLE_H    = 26
local ZONE_HDR_H = 28
local BAR_H      = 4
local DOT_SIZE   = 8
local COLS       = 2
local ROW_PAD    = 5

local function GetRowH()
    local db = MR.db and MR.db.profile or {}
    local fs = db.raresFontSize or 9
    return math.max(17, fs + 8)
end

local function SetRareRowVisual(row, dot, lbl, status, ever, cr, cg, cb, alpha, hover)
    alpha = alpha or 1
    if row then
        if hover then
            row:SetBackdropColor(0.035 + cr * 0.075, 0.040 + cg * 0.075, 0.050 + cb * 0.075, 0.98 * alpha)
            row:SetBackdropBorderColor(cr * 0.55, cg * 0.55, cb * 0.55, 0.82 * alpha)
        else
            row:SetBackdropColor(0, 0, 0, 0)
            row:SetBackdropBorderColor(0, 0, 0, 0)
        end
    end

    if not (dot and lbl) then return end

    if status == "today" then
        dot:SetBackdropColor(0.10, 0.55, 0.28, 1)
        dot:SetBackdropBorderColor(0.22, 0.95, 0.55, 1)
        lbl:SetTextColor(0.58, 0.92, 0.66)
    elseif status == "week" then
        dot:SetBackdropColor(0.62, 0.38, 0.08, 1)
        dot:SetBackdropBorderColor(0.95, 0.70, 0.18, 1)
        lbl:SetTextColor(0.86, 0.68, 0.30)
    elseif ever then
        dot:SetBackdropColor(0.43, 0.34, 0.08, 1)
        dot:SetBackdropBorderColor(0.82, 0.64, 0.18, 1)
        lbl:SetTextColor(0.72, 0.64, 0.42)
    else
        dot:SetBackdropColor(0.12, 0.13, 0.15, 1)
        dot:SetBackdropBorderColor(0.32, 0.35, 0.40, 1)
        lbl:SetTextColor(0.70, 0.72, 0.76)
    end
end

local raresFrame
local raresCfgFrame
local raresFrameCache = {}
local collapsed   = {}
for _, zone in ipairs(ZONES) do
    if zone.defaultCollapsed then collapsed[zone.key] = true end
end
local lastZoneKey = nil
local lastVisibleZoneMode = nil
local hoveredWarbandHit
local lastWarbandShiftState = false

local BuildRaresFrame
local RefreshRaresFrame
local LayoutRaresFrame
local PopulateRaresConfig

local RARES_UPDATE_INTERVAL = 0.05
local RARES_POLL_INTERVAL = 0.1

local function ApplyRaresFrameUpdater(frame)
    if not frame then return end

    frame.raresPollElapsed = 0
    frame.raresUpdateElapsed = 0
    frame:SetScript("OnUpdate", function(self, dt)
        dt = dt or 0

        self.raresUpdateElapsed = (self.raresUpdateElapsed or 0) + dt
        if self.raresUpdateElapsed < RARES_UPDATE_INTERVAL then return end
        dt = self.raresUpdateElapsed
        self.raresUpdateElapsed = 0

        if MR.db and MR.db.profile and MR.db.profile.raresShimmer then
            self.shimmerElapsed = (self.shimmerElapsed or 0) + dt
            local pulse = 0.06 + 0.04 * math.sin(self.shimmerElapsed * 2)
            for _, tex in ipairs(self.shimmerTextures or {}) do
                tex:SetAlpha(pulse)
            end
        end

        self.raresPollElapsed = (self.raresPollElapsed or 0) + dt
        if self.raresPollElapsed < RARES_POLL_INTERVAL then return end
        self.raresPollElapsed = 0

        if self.UpdatePanelHeaderVisibility then
            self:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(self))
        end

        if hoveredWarbandHit then
            local shiftDown = IsShiftKeyDown()
            if shiftDown ~= lastWarbandShiftState then
                lastWarbandShiftState = shiftDown
                local onEnter = hoveredWarbandHit:GetScript("OnEnter")
                if onEnter then onEnter(hoveredWarbandHit) end
            end
        end
    end)
end

local function RefreshForeverRareZones()
    if not MR.isForever then return end
    local zones = ns.Forever.GetRareZones()
    if ZONES == zones then return end
    ZONES = zones
    wipe(ZONE_BY_KEY)
    rareTracker.SetZones(ZONES)
    for _, zone in ipairs(ZONES) do
        ZONE_BY_KEY[zone.key] = zone
    end
end

local function GetVisibleZones()
    RefreshForeverRareZones()
    local db  = MR.db and MR.db.profile or {}
    local key = GetCurrentZoneKey()
    local function zoneVisible(z)
        return not (db.raresHiddenZones and db.raresHiddenZones[z.key])
    end
    if not db.raresShowAllZones then
        local zone = key and ZONE_BY_KEY[key]
        return zone and zoneVisible(zone) and { zone } or {}
    end
    local result = {}
    for _, z in ipairs(ZONES) do
        if zoneVisible(z) then result[#result + 1] = z end
    end
    return result
end

local function GetRaresLayoutKey()
    local db = MR.db and MR.db.profile or {}
    local parts = { IsManagedHeaderBottom() and "bottom" or "top" }
    for _, zone in ipairs(GetVisibleZones()) do
        parts[#parts + 1] = zone.key
        for _, rare in ipairs(zone.rares) do
            local questId = rare[2]
            local flagged = IsRareQuestCompleted(rare)
            local killStat = GetRareTrackedKillStatus(rare) or (flagged and "today") or nil
            if not (db.raresHideKilled and killStat == "today") then
                parts[#parts + 1] = tostring(questId or (MR.isForever and rare[6]) or rare[1]) .. (MR.isForever and (":" .. rare[1]) or "")
            end
        end
    end
    return table.concat(parts, ":")
end

local function RebuildRaresFrame()
    MR._raresWindowRebuildCount = (MR._raresWindowRebuildCount or 0) + 1
    if MR.NoteRefreshSource then MR:NoteRefreshSource("Rares:Rebuild", true) end
    RefreshFonts()
    local wasShown = raresFrame and raresFrame:IsShown()
    if raresFrame then
        raresFrameCache[raresFrame.layoutKey or GetRaresLayoutKey()] = raresFrame
        raresFrame:Hide()
    end
    if MR.db and MR.db.profile.raresCollapsed then
        for k, v in pairs(MR.db.profile.raresCollapsed) do collapsed[k] = v end
    end
    local layoutKey = GetRaresLayoutKey()
    raresFrame = raresFrameCache[layoutKey]
    if not raresFrame then
        raresFrame = BuildRaresFrame()
        raresFrameCache[layoutKey] = raresFrame
    end
    RestoreManagedFramePos(raresFrame, "raresPos", 580, 0)
    MR.raresFrame = raresFrame
    if wasShown then
        raresFrame:Show()
    end
    raresFrame:SetScale((MR.db and MR.db.profile.raresScale) or 1.0)
    if LayoutRaresFrame then LayoutRaresFrame(raresFrame) end
    RefreshRaresFrame()
end

BuildRaresFrame = function()
    MR._raresWindowBuildCount = (MR._raresWindowBuildCount or 0) + 1
    if MR.NoteRefreshSource then MR:NoteRefreshSource("Rares:Build", true) end
    RefreshFonts()
    local db         = MR.db and MR.db.profile or {}
    local W          = db.raresWidth  or DEFAULT_W
    local H          = db.raresHeight or DEFAULT_H
    local alpha      = math.max(0, math.min(db.raresAlpha or 1.0, 1.0))
    local minimized  = db.raresMinimized or false
    local visible    = GetVisibleZones()
    local singleZone = #visible == 1
    local cols       = (W >= 220) and COLS or 1
    local ROW_H      = GetRowH()
    local headerBottom = IsManagedHeaderBottom()

    local function ApplyFrameHeight(frame, targetHeight)
        AnimateManagedFrameHeight(frame, targetHeight, function(self)
            ApplyRaresFrameUpdater(self)
        end)
    end

    local f = StyledFrame(UIParent, nil, "MEDIUM", 10)
    MR:RegisterPriorityFrame(f)
    f.layoutKey = GetRaresLayoutKey()
    f:SetSize(W, minimized and TITLE_H or H)
    f:SetBackdropColor(0.018, 0.024, 0.034, 0.97 * alpha)
    f:SetBackdropBorderColor(0.13, 0.28, 0.34, alpha)
    RestoreManagedFramePos(f, "raresPos", 580, 0)

    f.leftAccent = nil
    f.topAccent  = TopAccent(f, ns.ResolveThemeColor(0.25, 0.78, 0.68))
    if ns.RegisterThemedTexture then ns.RegisterThemedTexture(f.topAccent, 0.25, 0.78, 0.68) end
    if f.leftAccent then f.leftAccent:SetAlpha(alpha) end
    if f.topAccent  then f.topAccent:SetAlpha(alpha)  end

    local titleBar = TitleBar(f, TITLE_H)
    f.titleBar = titleBar
    titleBar:SetBackdropColor(0, 0, 0, 0)
    titleBar:SetClipsChildren(true)
    titleBar:ClearAllPoints()
    if headerBottom then
        titleBar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)
        titleBar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    else
        titleBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
        titleBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    end
    titleBar:SetScript("OnDragStart", function() if not db.raresLocked then f:StartMoving() end end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        SaveManagedFramePos(f, "raresPos", headerBottom and "bottom" or "top")
    end)
    if MR.ApplyPanelHeaderAutoHide then MR:ApplyPanelHeaderAutoHide(f, titleBar) end

    local closeBtn = CloseButton(titleBar, function()
        f:Hide()
        if raresCfgFrame then raresCfgFrame:Hide() end
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("raresOpen", false) end
    end)

    local gearBtn = HeaderIconButton(
        titleBar,
        "Interface\\Buttons\\UI-OptionsButton",
        {0.85, 0.65, 0.20},
        {1, 1, 1},
        L["Rares_OptionsTitle"],
        function() MR:ToggleRaresConfig() end
    )

    local ApplyMinimized

    local function UpdateMinBtn()
        return (MR.db and MR.db.profile.raresMinimized) and "+" or "-"
    end
    local minBtn = HeaderToggleButton(titleBar, UpdateMinBtn, L["UI_Collapse"], function()
        local isMin = not (MR.db and MR.db.profile.raresMinimized)
        ApplyMinimized(isMin)
    end)
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -3, 0)
    gearBtn:SetPoint("RIGHT", minBtn, "LEFT", -3, 0)
    UpdateMinBtn()

    local titleFontSize = math.max(9, (db.raresFontSize or 9) + 1)
    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY")
    f.titleText = titleTxt
    titleTxt:SetFont(ns.FONT_HEADERS, titleFontSize, GetFontFlags())
    titleTxt:SetPoint("LEFT",  titleBar, "LEFT", 9, 0)
    titleTxt:SetPoint("RIGHT", gearBtn, "LEFT", -6, 0)
    titleTxt:SetJustifyH("LEFT")
    titleTxt:SetWordWrap(false)
    if singleZone then
        titleTxt:SetText("Rares  -  " .. visible[1].label)
    else
        titleTxt:SetText("Rares  -  Midnight")
    end
    ns.RegisterThemedFontString(titleTxt, 0.85, 0.90, 0.89)

    ApplyMinimized = function(isMin)
        if MR.db then MR.db.profile.raresMinimized = isMin end
        if minBtn.RefreshLabel then minBtn:RefreshLabel() end
        if isMin then
            if f._scroll      then f._scroll:Hide()   end
            if f._track       then f._track:Hide()    end
            if f._thumb       then f._thumb:Hide()    end
            if f._dragger     then f._dragger:Hide()   end
            SyncManagedFramePos(f, "raresPos", headerBottom and "bottom" or "top")
            ApplyFrameHeight(f, TITLE_H)
        else
            SyncManagedFramePos(f, "raresPos", headerBottom and "bottom" or "top")
            if f._scroll  then f._scroll:Show()  end
            if f._track   then f._track:Show()   end
            if f._dragger then f._dragger:Show()  end
            ApplyFrameHeight(f, MR.db and MR.db.profile.raresHeight or DEFAULT_H)
            if f.UpdateScrollBar then f.UpdateScrollBar() end
        end
    end
    f.ApplyMinimized = ApplyMinimized

    local scroll = CreateFrame("ScrollFrame", nil, f)
    if headerBottom then
        scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -4)
        scroll:SetPoint("BOTTOMRIGHT", titleBar, "TOPRIGHT", -8, 1)
    else
        scroll:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -1)
        scroll:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 4)
    end
    f._scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(W - 8, 1)
    f._content = content

    local track = CreateFrame("Frame", nil, f)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 1, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    track:SetWidth(5)
    f._track = track

    local UpdateScrollBar, thumb = ns.AttachScrollList(scroll, content, track, {
        hideTrack = true,
        trackColor = { 0, 0, 0, 0.22 },
        thumbColor = { 0.25, 0.78, 0.68, 0.62 },
    })
    f._thumb = thumb
    f.UpdateScrollBar = UpdateScrollBar

    f.shimmerElapsed  = 0
    f.shimmerTextures = {}
    ApplyRaresFrameUpdater(f)

    f.zoneData = {}
    f.visibleZones = visible
    local yOff = 2
    local innerW = W - 8 - (OUTER_PAD * 2)
    local colW   = innerW / cols

    for _, zone in ipairs(visible) do
        local cr, cg, cb  = GetZoneColor(zone)
        local isCollapsed = (not singleZone) and collapsed[zone.key]
        local zHdr
        local arrow
        local zName
        local zCount

        if not singleZone then
            local zoneHeaderFontSize = math.max(8, db.raresFontSize or 9)
            zHdr = CreateFrame("Button", nil, content, "BackdropTemplate")
            zHdr:SetPoint("TOPLEFT",  content, "TOPLEFT",  OUTER_PAD, -yOff)
            zHdr:SetPoint("TOPRIGHT", content, "TOPRIGHT", -OUTER_PAD, -yOff)
            zHdr:SetHeight(ZONE_HDR_H)
            zHdr:SetBackdrop(MakeBackdrop())
            zHdr:SetBackdropColor(0.020 + cr * 0.040, 0.025 + cg * 0.040, 0.032 + cb * 0.040, 0.94 * alpha)
            zHdr:SetBackdropBorderColor(cr*0.34, cg*0.34, cb*0.34, 0.76 * alpha)

            arrow = zHdr:CreateFontString(nil, "OVERLAY")
            arrow:SetFont(ns.FONT_ROWS, zoneHeaderFontSize, GetFontFlags())
            arrow:SetPoint("LEFT", zHdr, "LEFT", 9, 1)
            arrow:SetText(isCollapsed and "|cff889095+|r" or "|cff889095-|r")

            zName = zHdr:CreateFontString(nil, "OVERLAY")
            zName:SetFont(ns.FONT_HEADERS, math.max(9, zoneHeaderFontSize + 1), GetFontFlags())
            zName:SetPoint("LEFT", arrow, "RIGHT", 5, 0)
            zName:SetTextColor(0.90, 0.92, 0.90)
            zName:SetText(zone.label)
            zName:SetPoint("RIGHT", zHdr, "RIGHT", -50, 0)
            zName:SetJustifyH("LEFT")
            zName:SetWordWrap(false)

            local zDone, zTotal = GetZoneStatus(zone)
            zCount = zHdr:CreateFontString(nil, "OVERLAY")
            zCount:SetFont(ns.FONT_ROWS, zoneHeaderFontSize, GetFontFlags())
            zCount:SetPoint("RIGHT", zHdr, "RIGHT", -9, 0)
            zCount:SetJustifyH("RIGHT")
            zCount:SetTextColor(cr, cg, cb)
            zCount:SetText(string.format("%d/%d", zDone, zTotal))

            yOff = yOff + ZONE_HDR_H

            zHdr:SetScript("OnClick", function()
                collapsed[zone.key] = not collapsed[zone.key]
                if MR.db then
                    if not MR.db.profile.raresCollapsed then MR.db.profile.raresCollapsed = {} end
                    MR.db.profile.raresCollapsed[zone.key] = collapsed[zone.key]
                end
                LayoutRaresFrame(f)
                RefreshRaresFrame()
            end)
            zHdr:SetScript("OnEnter", function()
                zHdr:SetBackdropColor(0.030 + cr * 0.070, 0.035 + cg * 0.070, 0.045 + cb * 0.070, 0.98)
                zHdr:SetBackdropBorderColor(cr*0.68, cg*0.68, cb*0.68, 0.95)
            end)
            zHdr:SetScript("OnLeave", function()
                zHdr:SetBackdropColor(0.020 + cr * 0.040, 0.025 + cg * 0.040, 0.032 + cb * 0.040, 0.94 * alpha)
                zHdr:SetBackdropBorderColor(cr*0.34, cg*0.34, cb*0.34, 0.76 * alpha)
            end)
        end

        local barBg = CreateFrame("Frame", nil, content, "BackdropTemplate")
        barBg:SetPoint("TOPLEFT",  content, "TOPLEFT",  OUTER_PAD,  -yOff)
        barBg:SetPoint("TOPRIGHT", content, "TOPRIGHT", -OUTER_PAD, -yOff)
        barBg:SetHeight(BAR_H)
        barBg:SetBackdrop(MakeBackdrop(false))
        barBg:SetBackdropColor(0.010, 0.012, 0.016, 0.82 * alpha)

        local barFill = barBg:CreateTexture(nil, "ARTWORK")
        barFill:SetPoint("TOPLEFT",    barBg, "TOPLEFT",    0, 0)
        barFill:SetPoint("BOTTOMLEFT", barBg, "BOTTOMLEFT", 0, 0)
        barFill:SetWidth(1)
        barFill:SetColorTexture(cr, cg, cb, 0.80)

        local shimmer = barBg:CreateTexture(nil, "OVERLAY")
        shimmer:SetAllPoints(barFill)
        shimmer:SetColorTexture(1, 1, 1, 0)
        f.shimmerTextures[#f.shimmerTextures + 1] = shimmer

        yOff = yOff + BAR_H

        local visibleRares = {}
        local zoneIdxList  = {}
        for zIdx, rare in ipairs(zone.rares) do
            local questId = rare[2]
            local flagged = IsRareQuestCompleted(rare)
            if flagged then SyncRareKillRecord(questId) end
            local killStat = GetRareTrackedKillStatus(rare)
                             or (flagged and "today")
                             or nil
            if not (db.raresHideKilled and killStat == "today") then
                visibleRares[#visibleRares + 1] = rare
                zoneIdxList[#zoneIdxList + 1]   = zIdx
            end
        end

        local bodyH = 0
        if not isCollapsed and #visibleRares > 0 then
            bodyH = math.ceil(#visibleRares / cols) * ROW_H + 10
        end

        local body = CreateFrame("Frame", nil, content, "BackdropTemplate")
        body:SetPoint("TOPLEFT",  content, "TOPLEFT",  OUTER_PAD,  -yOff)
        body:SetPoint("TOPRIGHT", content, "TOPRIGHT", -OUTER_PAD, -yOff)
        body:SetHeight(math.max(bodyH, 1))
        body:SetBackdrop(MakeBackdrop())
        body:SetBackdropColor(0.012 + cr * 0.020, 0.016 + cg * 0.020, 0.022 + cb * 0.020, 0.66 * alpha)
        body:SetBackdropBorderColor(cr*0.18, cg*0.18, cb*0.18, 0.42 * alpha)
        if isCollapsed then body:Hide() end

        body.dotList      = {}
        body.nameLbls     = {}
        body.rowBtns      = {}
        body.visibleRares = visibleRares
        body.zoneIdxList  = zoneIdxList

        for i, rare in ipairs(visibleRares) do
            local col      = (i - 1) % cols
            local row      = math.floor((i - 1) / cols)
            local xPos     = ROW_PAD + col * colW
            local yPos     = -(row * ROW_H) - 5
            local zoneIdx  = zoneIdxList[i]

            local hit = CreateFrame("Button", nil, body, "BackdropTemplate")
            hit:SetPoint("TOPLEFT",  body, "TOPLEFT",  xPos, yPos)
            hit:SetWidth(colW - 5)
            hit:SetHeight(ROW_H)
            hit:SetBackdrop(MakeBackdrop())
            hit:EnableMouse(true)

            local dot = CreateFrame("Frame", nil, hit, "BackdropTemplate")
            dot:SetSize(DOT_SIZE, DOT_SIZE)
            dot:SetPoint("LEFT", hit, "LEFT", 4, 0)
            dot:SetBackdrop(MakeBackdrop())

            local lbl = hit:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(ns.FONT_ROWS, db.raresFontSize or 9, GetFontFlags())
            lbl:SetPoint("LEFT", dot, "RIGHT", 5, 0)
            lbl:SetPoint("RIGHT", hit, "RIGHT", -4, 0)
            lbl:SetHeight(ROW_H)
            lbl:SetJustifyH("LEFT")
            lbl:SetJustifyV("MIDDLE")
            lbl:SetText(rare[1])

            local questId = rare[2]
            local flagged = IsRareQuestCompleted(rare)
            if flagged then SyncRareKillRecord(questId) end
            local killStat = GetRareTrackedKillStatus(rare)
                             or (flagged and "today") or nil
            local achieved = IsAchievementCriteriaCompleted(zone.achievId, zoneIdx, rare)
            SetRareRowVisual(hit, dot, lbl, killStat, achieved, cr, cg, cb, alpha, false)

            hit:SetScript("OnEnter", function()
                hit._mrHover = true
                hoveredWarbandHit = hit
                lastWarbandShiftState = IsShiftKeyDown()
                local questId = rare[2]
                local flagged = IsRareQuestCompleted(rare)
                if flagged then SyncRareKillRecord(questId) end
                local killStat = GetRareTrackedKillStatus(rare)
                                 or (flagged and "today") or nil
                local achieved = IsAchievementCriteriaCompleted(zone.achievId, zoneIdx, rare)
                SetRareRowVisual(hit, dot, lbl, killStat, achieved, cr, cg, cb, alpha, true)
                ns.ShowTooltip(hit, {
                    build = function(tooltip)
                        tooltip:AddLine(rare[1], 1, 1, 1)
                        if killStat == "today" then
                            tooltip:AddLine(L["Rares_Tooltip_KilledToday"], 0.20, 0.85, 0.45)
                        elseif killStat == "week" then
                            tooltip:AddLine(L["Rares_Tooltip_KilledWeek"], 0.85, 0.65, 0.10)
                        elseif achieved then
                            tooltip:AddLine(L["Rares_Tooltip_EverKilled"], 0.88, 0.70, 0.12)
                        else
                            tooltip:AddLine(L["Rares_Tooltip_NotKilled"], 0.50, 0.50, 0.50)
                        end
                        AddWarbandRareTooltipLines(tooltip, rare)
                        if MR.isForever then ns.Forever.AddRareLocationTooltip(tooltip, rare) end
                        if rare[3] and rare[4] and rare[5] then
                            tooltip:AddLine(" ")
                            tooltip:AddLine(L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
                        end
                    end,
                })
            end)
            hit:SetScript("OnLeave", function()
                hit._mrHover = nil
                if hoveredWarbandHit == hit then hoveredWarbandHit = nil end
                local questId = rare[2]
                local flagged = IsRareQuestCompleted(rare)
                if flagged then SyncRareKillRecord(questId) end
                local killStat = GetRareTrackedKillStatus(rare)
                                 or (flagged and "today") or nil
                local achieved = IsAchievementCriteriaCompleted(zone.achievId, zoneIdx, rare)
                SetRareRowVisual(hit, dot, lbl, killStat, achieved, cr, cg, cb, alpha, false)
                ns.HideOwnedTooltip(hit)
            end)
            hit:SetScript("OnMouseUp", function(_, button)
                if button ~= "LeftButton" or not (rare[3] and rare[4] and rare[5]) then return end

                local target = MR.isForever and ns.Forever.GetRareWaypoint(rare) or {
                    label = rare[1],
                    waypointTitle = rare[1],
                    zone = rare[3],
                    x = rare[4],
                    y = rare[5],
                }
                if not target then return end
                local ok, source = MR:SetWaypoint(target)
                if ok then
                    print(string.format(L["Waypoint_Set"], source, rare[1], target.x, target.y))
                    if MR.isForever then ns.Forever.AdvanceRareWaypoint(rare) end
                else
                    print(L["Waypoint_Unavailable"])
                end
            end)

            body.dotList[i]  = dot
            body.nameLbls[i] = lbl
            body.rowBtns[i]  = hit
        end

        f.zoneData[zone.key] = {
            zone    = zone,
            header  = zHdr,
            arrow   = arrow,
            name    = zName,
            count   = zCount,
            barFill = barFill,
            barBg   = barBg,
            body    = body,
            bodyHeight = bodyH,
        }

        yOff = yOff + bodyH + 4
    end

    local contentH = math.max(yOff, 1)
    content:SetHeight(contentH)

    if not minimized then
        local savedH  = db.raresHeight or DEFAULT_H
        local naturalH = TITLE_H + 1 + contentH + 6
        f:SetHeight(math.min(savedH, naturalH))
    end

    local dragger = CreateFrame("Frame", nil, f)
    dragger:SetSize(12, 12)
    dragger:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    dragger:SetFrameLevel(f:GetFrameLevel() + 10)
    dragger:EnableMouse(true)
    f._dragger = dragger

    local dTex = dragger:CreateTexture(nil, "OVERLAY")
    dTex:SetAllPoints()
    dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    dragger:SetScript("OnEnter", function()
        if not db.raresLocked then
            dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        end
    end)
    dragger:SetScript("OnLeave", function()
        dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)

    local dragStartW, dragStartH, dragStartX, dragStartY
    local function UpdateRaresResize()
        if not dragger._dragging then
            dragger:SetScript("OnUpdate", nil)
            return
        end
        local cx, cy = GetCursorPosition()
        local scale  = f:GetEffectiveScale()
        cx = cx / scale;  cy = cy / scale
        f:SetWidth( math.max(MIN_W, math.min(MAX_W, dragStartW + (cx - dragStartX))))
        f:SetHeight(math.max(MIN_H, math.min(MAX_H, dragStartH + (dragStartY - cy))))
    end
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not db.raresLocked then
            dragStartW  = f:GetWidth()
            dragStartH  = f:GetHeight()
            local scale = f:GetEffectiveScale()
            dragStartX, dragStartY = GetCursorPosition()
            dragStartX = dragStartX / scale
            dragStartY = dragStartY / scale
            dragger._dragging = true
            dragger:SetScript("OnUpdate", UpdateRaresResize)
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            dragger:SetScript("OnUpdate", nil)
            local newW = math.max(MIN_W, math.min(MAX_W, math.floor(f:GetWidth())))
            local newH = math.max(MIN_H, math.min(MAX_H, math.floor(f:GetHeight())))
            if MR.db then
                MR.db.profile.raresWidth  = newW
                MR.db.profile.raresHeight = newH
            end
            LayoutRaresFrame(f)
        end
    end)
    dragger:SetScript("OnHide", function()
        dragger._dragging = false
        dragger:SetScript("OnUpdate", nil)
    end)

    if minimized then
        scroll:Hide()
        track:Hide()
        thumb:Hide()
        dragger:Hide()
        f:SetHeight(TITLE_H)
    end

    f:SetMovable(not db.raresLocked)
    f:Hide()
    return f
end

RefreshRaresFrame = function()
    if not raresFrame or not raresFrame:IsShown() then return end
    MR._raresWindowRefreshCount = (MR._raresWindowRefreshCount or 0) + 1
    if MR.NoteRefreshSource then MR:NoteRefreshSource("Rares:Refresh", true) end

    local db = MR.db and MR.db.profile or {}
    if db.raresHideKilled and raresFrame.zoneData then
        for _, zd in pairs(raresFrame.zoneData) do
            local body = zd.body
            if body and body.visibleRares then
                for _, rare in ipairs(body.visibleRares) do
                    local questId = rare[2]
                    local flagged = IsRareQuestCompleted(rare)
                    if flagged then SyncRareKillRecord(questId) end
                    local killStat = GetRareTrackedKillStatus(rare)
                                     or (flagged and "today")
                                     or nil
                    if killStat == "today" then
                        RebuildRaresFrame()
                        return
                    end
                end
            end
        end
    end

    for _, zone in ipairs(ZONES) do
        local zd = raresFrame.zoneData and raresFrame.zoneData[zone.key]
        if zd then
            local numDone, numTotal, status = GetZoneStatus(zone)
            local cr, cg, cb = GetZoneColor(zone)

            local barW = zd.barBg:GetWidth()
            if barW and barW > 0 then
                local pct   = numTotal > 0 and (numDone / numTotal) or 0
                local fillW = math.max(1, barW * pct)
                zd.barFill:SetWidth(fillW)
                if numDone >= numTotal then
                    zd.barFill:SetColorTexture(0.90, 0.78, 0.18, 1)
                else
                    zd.barFill:SetColorTexture(cr, cg, cb, 0.80)
                end
            end

            local body = zd.body
            if body and body:IsShown() then
                for i, rare in ipairs(body.visibleRares or {}) do
                    local dot      = body.dotList[i]
                    local lbl      = body.nameLbls[i]
                    local rowBtn   = body.rowBtns and body.rowBtns[i]
                    local zoneIdx  = body.zoneIdxList and body.zoneIdxList[i] or i
                    if dot and lbl then
                        local questId = rare[2]
                        local flagged = IsRareQuestCompleted(rare)
                        if flagged then SyncRareKillRecord(questId) end
                        local killStat = GetRareTrackedKillStatus(rare)
                                         or (flagged and "today") or nil
                        local ever = IsAchievementCriteriaCompleted(zone.achievId, zoneIdx, rare)
                        SetRareRowVisual(rowBtn, dot, lbl, killStat, ever, cr, cg, cb, db.raresAlpha or 1.0, rowBtn and rowBtn._mrHover)
                    end
                end
            end
        end
    end

    if raresFrame.UpdateScrollBar then raresFrame.UpdateScrollBar() end
end

local function BuildRaresConfigFrame()
    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetWidth(268)
    MR:RegisterPriorityFrame(f)
    f:SetFrameLevel(20)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop(MakeBackdrop())
    if ns.HookBackdropFrame then ns.HookBackdropFrame(f) end
    f:SetBackdropColor(0.018, 0.024, 0.034, 0.98)
    f:SetBackdropBorderColor(0.13, 0.28, 0.34, 1)
    f:Hide()

    if ns.RegisterThemedTexture then
        ns.RegisterThemedTexture(TopAccent(f, ns.ResolveThemeColor(0.25, 0.78, 0.68)), 0.25, 0.78, 0.68)
    else
        TopAccent(f, ns.ResolveThemeColor(0.25, 0.78, 0.68))
    end

    local tbar = TitleBar(f, 22)
    tbar:SetBackdropColor(0.026, 0.040, 0.052, 1)
    tbar:SetScript("OnDragStart", function() f:StartMoving() end)
    tbar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
    ttitle:SetText("Rares Options")
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)
    ns.RegisterThemedFontString(ttitle, 0.85, 0.90, 0.89)

    CloseButton(tbar, function() f:Hide() end)
    f.body = nil
    return f
end

PopulateRaresConfig = function(f)
    RefreshForeverRareZones()
    RefreshFonts()
    local keepLeft, keepTop
    if f.IsShown and f:IsShown() and MR.CaptureFrameScreenPosition then
        keepLeft, keepTop = MR:CaptureFrameScreenPosition(f)
    end

    if f.body then
        if MR.ReleaseFrameTree then
            MR:ReleaseFrameTree(f.body)
        else
            f.body:EnableMouse(false)
            f.body:Hide()
            f.body:SetParent(nil)
        end
        f.body = nil
    end

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    body:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.body = body

    local db   = MR.db.profile
    local yOff = -28
    local P    = 8
    local contentW = (f:GetWidth() or 224) - (P * 2)
    local activePage = MR._raresCfgPage or "display"

    local cfgFs = (ns.GetFontSize and ns.GetFontSize()) or (MR.db and MR.db.profile and MR.db.profile.fontSize) or 9

    if activePage ~= "display" and activePage ~= "zones" and activePage ~= "reset" then
        activePage = "display"
        MR._raresCfgPage = activePage
    end

    local function Gap(h)      yOff = OptionsGap(body, yOff, h) end
    local function Divider()   yOff = OptionsDivider(body, yOff, P) end
    local function SecLabel(t) yOff = OptionsSectionLabel(body, yOff, t, P, cfgFs) end
    local function Check(lbl, get, set, r, g, b)
        yOff = OptionsCheckbox(body, yOff, lbl, get, set,
            r or 0.78, g or 0.78, b or 0.88, P,
            function() PopulateRaresConfig(f) end, cfgFs)
    end
    local function Slider(lbl, mn, mx, st, get, set, r, g, b, disabled)
        yOff = OptionsSlider(body, yOff, lbl, mn, mx, st, get, set, r, g, b, P, disabled, cfgFs)
    end
    local function Btn(lbl, fn) yOff = OptionsBtn(body, yOff, lbl, fn, math.max(184, contentW), P, cfgFs) end

    do
        local tabs = {
            { key = "display", label = L["Config_TabLayout"] or "Layout" },
            { key = "zones", label = L["Config_TabColors"] or "Colors" },
            { key = "reset", label = L["Config_TabReset"] or "Reset" },
        }
        local tabW = math.floor((contentW - 4) / #tabs)
        for i, tab in ipairs(tabs) do
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(tabW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", P + (i - 1) * (tabW + 2), yOff)
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
                MR._raresCfgPage = tab.key
                PopulateRaresConfig(f)
            end)
            btn:SetScript("OnEnter", function()
                if activePage ~= tab.key then
                    btn:SetBackdropColor(0.08, 0.18, 0.24, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.90, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = (MR._raresCfgPage or "display") == tab.key
                btn:SetBackdropColor(selected and 0.11 or 0.05, selected and 0.24 or 0.09, selected and 0.23 or 0.15, 1)
                btn:SetBackdropBorderColor(selected and 0.22 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.85 or 0.62, selected and 1.0 or 0.75, selected and 0.92 or 0.70)
            end)
        end
        yOff = yOff - 26
    end

    if activePage == "display" then
        SecLabel(L["Config_Display"])
        Check(L["Config_LockPosition"],
            function() return db.raresLocked end,
            function(v)
                db.raresLocked = v
                if raresFrame then raresFrame:SetMovable(not v) end
            end)
        Check(L["Config_ShimmerAnim"],
            function() return db.raresShimmer ~= false end,
            function(v)
                db.raresShimmer = v
                if raresFrame then
                    if not v and raresFrame.shimmerTextures then
                        for _, tex in ipairs(raresFrame.shimmerTextures) do tex:SetAlpha(0) end
                    end
                    ApplyRaresFrameUpdater(raresFrame)
                end
            end)
        Check(L["Config_HideKilled"],
            function() return db.raresHideKilled end,
            function(v) db.raresHideKilled = v; RebuildRaresFrame() end)
        Check(L["Config_RaresShowAllZones"],
            function() return db.raresShowAllZones end,
            function(v)
                db.raresShowAllZones = v
                lastVisibleZoneMode = v and "all" or GetCurrentZoneKey()
                RebuildRaresFrame()
            end)

        Gap(4); Divider()
        Slider(L["WIDTH"], MIN_W, MAX_W, 10,
            function() return db.raresWidth or DEFAULT_W end,
            function(v)
                db.raresWidth = math.floor(v / 10) * 10
                LayoutRaresFrame(raresFrame)
            end,
            0.25, 0.78, 0.68)
        Slider(L["HEIGHT"], MIN_H, MAX_H, 10,
            function() return db.raresHeight or DEFAULT_H end,
            function(v)
                db.raresHeight = math.floor(v / 10) * 10
                if raresFrame and not db.raresMinimized then
                    raresFrame:SetHeight(db.raresHeight)
                end
            end,
            0.16, 0.75, 0.78)
        local syncFs = MR.db.profile.syncWindowFontSize
        Slider(L["Config_FontSize"], 7, 16, 1,
            function() return db.raresFontSize or 9 end,
            function(v) db.raresFontSize = math.floor(v); LayoutRaresFrame(raresFrame); RefreshRaresFrame() end,
            0.78, 0.55, 0.16, syncFs)

        do
            local presets = { {"S", 8}, {"M", 9}, {"L", 11}, {"XL", 13} }
            local btnW = math.floor((contentW - 6) / #presets)
            for i, p in ipairs(presets) do
                local isActive = (not syncFs) and ((db.raresFontSize or 9) == p[2])
                local pb = CreateFrame("Button", nil, body, "BackdropTemplate")
                pb:SetSize(btnW, 16)
                pb:SetPoint("TOPLEFT", body, "TOPLEFT", P + (i - 1) * (btnW + 2), yOff - 2)
                pb:SetBackdrop(MakeBackdrop())
                pb:SetBackdropColor(isActive and 0.12 or 0.05, isActive and 0.35 or 0.10, isActive and 0.32 or 0.18, syncFs and 0.4 or 1)
                pb:SetBackdropBorderColor(isActive and 0.25 or 0.18, isActive and 0.85 or 0.40, isActive and 0.70 or 0.45, syncFs and 0.4 or 1)
                local pfs = pb:CreateFontString(nil, "OVERLAY")
                pfs:SetFont(ns.FONT_ROWS, cfgFs, GetFontFlags())
                pfs:SetPoint("CENTER")
                pfs:SetText(p[1])
                pfs:SetTextColor(syncFs and 0.35 or (isActive and 0.2 or 0.6), syncFs and 0.35 or (isActive and 0.95 or 0.75), syncFs and 0.35 or (isActive and 0.75 or 0.65))
                if not syncFs then
                    pb:SetScript("OnClick", function()
                        db.raresFontSize = p[2]
                        LayoutRaresFrame(raresFrame)
                        RefreshRaresFrame()
                        PopulateRaresConfig(f)
                    end)
                    pb:SetScript("OnEnter", function() pb:SetBackdropColor(0.10, 0.28, 0.28, 1); pb:SetBackdropBorderColor(0.25, 0.90, 0.75, 1) end)
                    pb:SetScript("OnLeave", function()
                        pb:SetBackdropColor(isActive and 0.12 or 0.05, isActive and 0.35 or 0.10, isActive and 0.32 or 0.18, 1)
                        pb:SetBackdropBorderColor(isActive and 0.25 or 0.18, isActive and 0.85 or 0.40, isActive and 0.70 or 0.45, 1)
                    end)
                else
                    pb:EnableMouse(false)
                end
            end
            yOff = yOff - 22
        end

        Slider(L["BACKGROUND"], 0, 1, 0.05,
            function() return db.raresAlpha or 1.0 end,
            function(v)
                db.raresAlpha = v
                if raresFrame then
                    raresFrame:SetBackdropColor(0.018, 0.024, 0.034, 0.97 * v)
                    raresFrame:SetBackdropBorderColor(0.13, 0.28, 0.34, v)
                    if raresFrame.leftAccent then raresFrame.leftAccent:SetAlpha(v) end
                    if raresFrame.topAccent  then raresFrame.topAccent:SetAlpha(v)  end
                    if raresFrame.zoneData then
                        for _, zd in pairs(raresFrame.zoneData) do
                            local zone = zd.zone
                            local cr, cg, cb = GetZoneColor(zone)
                            zd.barBg:SetBackdropColor(0.010, 0.012, 0.016, 0.82 * v)
                            zd.body:SetBackdropColor(0.012 + cr * 0.020, 0.016 + cg * 0.020, 0.022 + cb * 0.020, 0.66 * v)
                            zd.body:SetBackdropBorderColor(cr*0.18, cg*0.18, cb*0.18, 0.42 * v)
                        end
                    end
                end
            end,
            0.40, 0.40, 0.40)
        Slider(L["SCALE"], 0.5, 2.0, 0.05,
            function() return db.raresScale or 1.0 end,
            function(v)
                db.raresScale = v
                if raresFrame then raresFrame:SetScale(v) end
            end,
            0.45, 0.22, 0.82, MR.db.profile.syncWindowScale == true)
    elseif activePage == "zones" then
        SecLabel(L["Config_ZoneSettings"])

        for _, zone in ipairs(ZONES) do
            local cr, cg, cb = GetZoneColor(zone)
            local ROW_H2 = 22
            local rowFr  = CreateFrame("Frame", nil, body)
            rowFr:SetPoint("TOPLEFT",  body, "TOPLEFT",  P,  yOff)
            rowFr:SetPoint("TOPRIGHT", body, "TOPRIGHT", -P, yOff)
            rowFr:SetHeight(ROW_H2)

            local nameLbl
            local zoneEnabled = not (db.raresHiddenZones and db.raresHiddenZones[zone.key])

            local enableBtn = CreateFrame("CheckButton", nil, rowFr, "UICheckButtonTemplate")
            ns.ThemeCheckButton(enableBtn)
            enableBtn:SetSize(20, 20)
            enableBtn:SetPoint("LEFT", rowFr, "LEFT", 0, 0)
            enableBtn:SetChecked(zoneEnabled)
            enableBtn:SetScript("OnClick", function(s)
                if not db.raresHiddenZones then db.raresHiddenZones = {} end
                db.raresHiddenZones[zone.key] = (not s:GetChecked()) or nil
                RebuildRaresFrame()
                PopulateRaresConfig(f)
            end)

            local swatch = OptionsColorSwatch(rowFr, cr, cg, cb,
                function(r, g, b)
                    SetZoneColor(zone, r, g, b)
                    if nameLbl then nameLbl:SetTextColor(r, g, b) end
                    RebuildRaresFrame()
                end,
                function()
                    ResetZoneColor(zone)
                    local dr, dg, db2 = zone.color[1], zone.color[2], zone.color[3]
                    if nameLbl then nameLbl:SetTextColor(dr, dg, db2) end
                    RebuildRaresFrame()
                    return dr, dg, db2
                end,
                zone.label .. L["Color_Reset_Hint"])
            swatch:SetPoint("RIGHT", rowFr, "RIGHT", 0, 0)

            nameLbl = rowFr:CreateFontString(nil, "OVERLAY")
            nameLbl:SetFont(ns.FONT_ROWS, 10, GetFontFlags())
            nameLbl:SetPoint("LEFT",  enableBtn, "RIGHT", 2,  0)
            nameLbl:SetPoint("RIGHT", swatch, "LEFT", -4,  0)
            nameLbl:SetText(zone.label)
            nameLbl:SetTextColor(cr, cg, cb)
            nameLbl:SetJustifyH("LEFT")
            nameLbl:SetAlpha(zoneEnabled and 1 or 0.5)

            yOff = yOff - (ROW_H2 + 2)
        end
    else
        SecLabel(L["RESETS"])
        Btn(L["Config_ResetColors"], function()
            db.raresColors = {}
            RebuildRaresFrame()
            PopulateRaresConfig(f)
        end)
    end

    local totalH = math.abs(yOff) + 10
    f:SetHeight(totalH)
    body:SetHeight(totalH)
    if keepLeft and keepTop and MR.RestoreFrameScreenPosition then
        MR:RestoreFrameScreenPosition(f, keepLeft, keepTop)
    end
end

LayoutRaresFrame = function(frame)
    if not frame or not frame._content then return end
    MR._raresWindowLayoutCount = (MR._raresWindowLayoutCount or 0) + 1
    if MR.NoteRefreshSource then MR:NoteRefreshSource("Rares:Layout", true) end
    local db = MR.db and MR.db.profile or {}
    local width = db.raresWidth or DEFAULT_W
    local cols = width >= 220 and COLS or 1
    local rowHeight = GetRowH()
    local innerW = width - 8 - (OUTER_PAD * 2)
    local colW = innerW / cols
    local yOff = 2
    local singleZone = #(frame.visibleZones or {}) == 1

    frame:SetWidth(width)
    frame._content:SetWidth(width - 8)
    if frame.titleText then
        frame.titleText:SetFont(ns.FONT_HEADERS, math.max(9, (db.raresFontSize or 9) + 1), GetFontFlags())
    end

    for _, zone in ipairs(frame.visibleZones or {}) do
        local data = frame.zoneData and frame.zoneData[zone.key]
        if data then
            local isCollapsed = (not singleZone) and collapsed[zone.key]
            if data.header then
                data.arrow:SetFont(ns.FONT_ROWS, math.max(8, db.raresFontSize or 9), GetFontFlags())
                data.name:SetFont(ns.FONT_HEADERS, math.max(9, (db.raresFontSize or 9) + 1), GetFontFlags())
                data.count:SetFont(ns.FONT_ROWS, math.max(8, db.raresFontSize or 9), GetFontFlags())
                data.header:ClearAllPoints()
                data.header:SetPoint("TOPLEFT", frame._content, "TOPLEFT", OUTER_PAD, -yOff)
                data.header:SetPoint("TOPRIGHT", frame._content, "TOPRIGHT", -OUTER_PAD, -yOff)
                data.arrow:SetText(isCollapsed and "|cff889095+|r" or "|cff889095-|r")
                yOff = yOff + ZONE_HDR_H
            end

            data.barBg:ClearAllPoints()
            data.barBg:SetPoint("TOPLEFT", frame._content, "TOPLEFT", OUTER_PAD, -yOff)
            data.barBg:SetPoint("TOPRIGHT", frame._content, "TOPRIGHT", -OUTER_PAD, -yOff)
            yOff = yOff + BAR_H

            data.body:ClearAllPoints()
            data.body:SetPoint("TOPLEFT", frame._content, "TOPLEFT", OUTER_PAD, -yOff)
            data.body:SetPoint("TOPRIGHT", frame._content, "TOPRIGHT", -OUTER_PAD, -yOff)
            local visibleCount = #(data.body.visibleRares or {})
            data.bodyHeight = visibleCount > 0 and (math.ceil(visibleCount / cols) * rowHeight + 10) or 0
            for index, hit in ipairs(data.body.rowBtns or {}) do
                local col = (index - 1) % cols
                local row = math.floor((index - 1) / cols)
                hit:ClearAllPoints()
                hit:SetPoint("TOPLEFT", data.body, "TOPLEFT", ROW_PAD + col * colW, -(row * rowHeight) - 5)
                hit:SetWidth(colW - 5)
                hit:SetHeight(rowHeight)
                local label = data.body.nameLbls and data.body.nameLbls[index]
                if label then
                    label:SetFont(ns.FONT_ROWS, db.raresFontSize or 9, GetFontFlags())
                    label:SetHeight(rowHeight)
                end
            end
            if isCollapsed then
                data.body:Hide()
            else
                data.body:SetHeight(math.max(data.bodyHeight or 0, 1))
                data.body:Show()
                yOff = yOff + (data.bodyHeight or 0)
            end
            yOff = yOff + 4
        end
    end

    frame._content:SetHeight(math.max(yOff, 1))
    if not db.raresMinimized then
        local naturalH = TITLE_H + 1 + math.max(yOff, 1) + 6
        frame:SetHeight(math.min(db.raresHeight or DEFAULT_H, naturalH))
    end
    if frame.UpdateScrollBar then frame.UpdateScrollBar() end
end

function MR:ToggleRaresConfig()
    if not raresCfgFrame then
        raresCfgFrame = BuildRaresConfigFrame()
    end
    if raresCfgFrame:IsShown() then
        raresCfgFrame:Hide()
        return
    end
    raresCfgFrame:ClearAllPoints()
    if raresFrame and raresFrame:IsShown() then
        raresCfgFrame:SetPoint("TOPLEFT", raresFrame, "TOPRIGHT", 4, 0)
        raresCfgFrame:SetScale(raresFrame:GetScale())
    elseif MR.frame then
        raresCfgFrame:SetPoint("TOPLEFT", MR.frame, "TOPRIGHT", 4, 0)
        raresCfgFrame:SetScale(MR.frame:GetScale())
    else
        raresCfgFrame:SetPoint("CENTER")
        raresCfgFrame:SetScale(1)
    end
    PopulateRaresConfig(raresCfgFrame)
    raresCfgFrame:Show()
    if MR.CaptureFrameScreenPosition and MR.RestoreFrameScreenPosition then
        local left, top = MR:CaptureFrameScreenPosition(raresCfgFrame)
        MR:RestoreFrameScreenPosition(raresCfgFrame, left, top)
    end
end

function MR:ToggleRares()
    if MR.db and MR.db.profile.raresCollapsed then
        for k, v in pairs(MR.db.profile.raresCollapsed) do collapsed[k] = v end
    end

    if raresFrame and raresFrame:IsShown() then
        self:HideRares()
    else
        if self.ClearManagedWindowsBundleHidden then self:ClearManagedWindowsBundleHidden() end
        if self._instanceFramesHidden then
            if self.SetManagedWindowOpen then self:SetManagedWindowOpen("raresOpen", true) end
            return
        end
        if not raresFrame or raresFrame.layoutKey ~= GetRaresLayoutKey() then
            RebuildRaresFrame()
        end
        MR.raresFrame = raresFrame
        raresFrame:Show()
        if self.SetManagedWindowOpen then self:SetManagedWindowOpen("raresOpen", true) end
        raresFrame:SetScale((MR.db and MR.db.profile.raresScale) or 1.0)
        lastZoneKey = GetCurrentZoneKey()
        lastVisibleZoneMode = (MR.db and MR.db.profile and MR.db.profile.raresShowAllZones) and "all" or lastZoneKey
        self:SyncAllRareKills(true)
        RefreshRaresFrame()
    end
end

function MR:HideRares(persistState)
    if raresFrame then raresFrame:Hide() end
    if raresCfgFrame then raresCfgFrame:Hide() end
    if persistState ~= false and self.db then
        self:SetManagedWindowOpen("raresOpen", false)
    end
end

function MR:EnsureRaresShown()
    if self._instanceFramesHidden then
        if self.SetManagedWindowOpen then self:SetManagedWindowOpen("raresOpen", true) end
        return
    end
    if MR.db and MR.db.profile.raresCollapsed then
        for k, v in pairs(MR.db.profile.raresCollapsed) do collapsed[k] = v end
    end
    if not raresFrame or raresFrame.layoutKey ~= GetRaresLayoutKey() then
        RebuildRaresFrame()
    end
    MR.raresFrame = raresFrame
    raresFrame:Show()
    raresFrame:SetScale((MR.db and MR.db.profile.raresScale) or 1.0)
    lastZoneKey = GetCurrentZoneKey()
    lastVisibleZoneMode = (MR.db and MR.db.profile and MR.db.profile.raresShowAllZones) and "all" or lastZoneKey
    self:SyncAllRareKills(true)
    RefreshRaresFrame()
    if self.SetManagedWindowOpen then self:SetManagedWindowOpen("raresOpen", true) end
end

function MR:OnRaresZoneChanged()
    if not raresFrame or not raresFrame:IsShown() then return end
    local newKey = GetCurrentZoneKey()
    local db = MR.db and MR.db.profile or {}
    if not db.raresShowAllZones and newKey == lastZoneKey then return end
    if db.raresShowAllZones and lastVisibleZoneMode == "all" then
        lastZoneKey = newKey
        return
    end
    lastZoneKey = newKey
    lastVisibleZoneMode = db.raresShowAllZones and "all" or newKey
    RebuildRaresFrame()
end

function MR:RefreshRareTrackingZones()
    RefreshForeverRareZones()
end

function MR:IsRareTrackingSurfaceVisible()
    return raresFrame and raresFrame:IsShown() or false
end

function MR:RefreshRares()
    if not raresFrame or not raresFrame:IsShown() then
        return
    end

    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        return
    end

    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("rares") then
        return
    end

    if self.isForever and raresFrame and raresFrame:IsShown() and raresFrame.layoutKey ~= GetRaresLayoutKey() then
        RebuildRaresFrame()
        self.raresFrame = raresFrame
    end
    RefreshRaresFrame()
end

function MR:RebuildRaresFrame()
    if raresFrame and raresFrame:IsShown() then
        RebuildRaresFrame()
    end
end

function MR:RepopulateRaresConfig()
    if raresCfgFrame and raresCfgFrame:IsShown() then
        PopulateRaresConfig(raresCfgFrame)
    end
end

function MR:GetRaresFrameCacheCount()
    local count = 0
    for _ in pairs(raresFrameCache) do count = count + 1 end
    return count
end
