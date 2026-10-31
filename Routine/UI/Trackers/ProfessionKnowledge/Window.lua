local _, ns = ...
if ns.Inactive then return end
if ns.MR.isForever and ns.Forever.hideProfessions then return end
local MR = ns.MR
local PK = ns.ProfessionKnowledgeInternal

local StyledFrame = ns.StyledFrame
local RestoreManagedFramePos = ns.RestoreManagedFramePos
local SaveManagedFramePos = ns.SaveManagedFramePos
local SyncManagedFramePos = ns.SyncManagedFramePos
local AnimateManagedFrameHeight = ns.AnimateManagedFrameHeight
local IsManagedHeaderBottom = ns.IsManagedHeaderBottom
local TitleBar = ns.TitleBar
local CloseButton = ns.CloseButton
local HeaderIconButton = ns.HeaderIconButton
local HeaderToggleButton = ns.HeaderToggleButton
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)
local EnsureGatheringWatchFrame = PK.EnsureGatheringWatchFrame
local PopulateGatheringConfig = PK.PopulateGatheringConfig
local RefreshFonts = PK.RefreshFonts
local GetFontFlags = ns.GetFontFlags
local DEFAULT_W = PK.DEFAULT_W
local DEFAULT_H = PK.DEFAULT_H
local MIN_W = PK.MIN_W
local MAX_W = PK.MAX_W
local MIN_H = PK.MIN_H
local MAX_H = PK.MAX_H
local TITLE_H = PK.TITLE_H
local GetKnowledgeExpansionOptions = PK.GetKnowledgeExpansionOptions
local GetSelectedKnowledgeExpansion = PK.GetSelectedKnowledgeExpansion
local SetSelectedKnowledgeExpansion = PK.SetSelectedKnowledgeExpansion
local StripInlineColor = PK.StripInlineColor
local ApplyGatheringFrameTheme = PK.ApplyGatheringFrameTheme
local BeginProfessionRender = PK.BeginProfessionRender
local EndProfessionRender = PK.EndProfessionRender
local RenderFrame = PK.RenderFrame
local RenderFontString = PK.RenderFontString
local BuildProfessionCards = PK.BuildProfessionCards
local BuildGatheringConfigFrame = PK.BuildGatheringConfigFrame

local gatheringLocationsFrame
local gatheringMinimized = false
local gatheringCfgFrame
local RebuildGatheringLocationsFrame
local gatheringFrameInteractionActive = false
local gatheringRebuildPending

local function BuildKnowledgeExpansionDropdown(parent, opts)
    opts = opts or {}
    opts.style = "gold"
    opts.dynamicWidth = true
    opts.dynamicMenuWidth = true
    opts.labelInset = 6
    opts.labelRightInset = -14
    opts.caretInset = -5
    opts.textYOffset = 0
    opts.heightPadding = 6
    return ns.CreateDropdown(parent, opts)
end

local function CreateKnowledgeExpansionDropdown(titleBar, gearBtn)
    local dropdown = BuildKnowledgeExpansionDropdown(titleBar, {
        width = 122,
        height = 18,
        maxHeight = 18,
        fontSize = function()
            local db = MR.db and MR.db.profile or {}
            return math.max(8, db.gatheringFontSize or db.fontSize or 9)
        end,
        alpha = function()
            local db = MR.db and MR.db.profile or {}
            return db.gatheringAlpha or 1
        end,
        getOptions = GetKnowledgeExpansionOptions,
        getSelected = GetSelectedKnowledgeExpansion,
        onSelect = SetSelectedKnowledgeExpansion,
    })
    dropdown:SetPoint("RIGHT", gearBtn, "LEFT", -4, 0)
    dropdown:Update()
    return dropdown, GetSelectedKnowledgeExpansion()
end

local function BuildGatheringLocationsFrame(isRetry)
    EnsureGatheringWatchFrame()
    MR._professionKnowledgeWindowBuildCount = (MR._professionKnowledgeWindowBuildCount or 0) + 1
    if MR.NoteRefreshSource then MR:NoteRefreshSource("ProfessionKnowledge:Build", true) end
    RefreshFonts()
    local db = MR.db and MR.db.profile or {}
    local hadProfCache = MR.playerProfessions and next(MR.playerProfessions) ~= nil
    if not hadProfCache and MR.RefreshPlayerProfessions then MR:RefreshPlayerProfessions() end
    local hasProfCache = MR.playerProfessions and next(MR.playerProfessions) ~= nil
    local professionsScanned = MR.db and MR.db.char and MR.db.char.professionsScanned == true
    local alpha = db.gatheringAlpha or 1.0
    local width = db.gatheringWidth or DEFAULT_W
    local height = db.gatheringHeight or DEFAULT_H
    local minimized = db.gatheringMinimized or false
    local headerBottom = IsManagedHeaderBottom()
    gatheringMinimized = minimized
    local panelAlpha = math.max(0, math.min(alpha, 1))
    local contentAlpha = panelAlpha
    local borderAlpha = 0.20 + (0.75 * panelAlpha)
    local accentAlpha = 0.10 + (0.85 * panelAlpha)
    local chromeAlpha = panelAlpha

    local function ApplyFrameHeight(frame, targetHeight)
        AnimateManagedFrameHeight(frame, targetHeight, function(self)
            self:SetScript("OnUpdate", nil)
        end)
    end

    local frame = StyledFrame(UIParent, nil, "MEDIUM", 10)
    MR:RegisterPriorityFrame(frame)
    frame:SetSize(width, minimized and TITLE_H or height)
    RestoreManagedFramePos(frame, "gatheringLocPos", 860, 0)
    frame.leftAccent = nil
    ApplyGatheringFrameTheme(frame, {
        alpha = alpha,
        bg = { 0.03, 0.05, 0.09, 0.97 * alpha },
        border = { 0.24, 0.31, 0.42, alpha },
        accent = { 0.18, 0.78, 0.72 },
        headerHeight = 64,
    })

    local titleBar = TitleBar(frame, TITLE_H)
    frame.titleBar = titleBar
    titleBar:SetFrameLevel(frame:GetFrameLevel() + 20)
    titleBar:SetBackdropColor(0, 0, 0, 0)
    titleBar:ClearAllPoints()
    if headerBottom then
        titleBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        titleBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    else
        titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    end
    local function StartGatheringFrameMove()
        local currentDb = MR.db and MR.db.profile or db
        if currentDb.gatheringLocked then return end
        gatheringFrameInteractionActive = true
        frame._gatheringMoving = true
        frame:StartMoving()
    end

    local function StopGatheringFrameMove()
        if frame._gatheringMoving then
            frame._gatheringMoving = nil
            frame:StopMovingOrSizing()
            SaveManagedFramePos(frame, "gatheringLocPos", headerBottom and "bottom" or "top")
        end
        gatheringFrameInteractionActive = false
        if gatheringRebuildPending then
            local pendingResetScroll = gatheringRebuildPending == "reset"
            gatheringRebuildPending = nil
            RebuildGatheringLocationsFrame(pendingResetScroll)
        end
    end

    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", StartGatheringFrameMove)
    frame:SetScript("OnDragStop", StopGatheringFrameMove)
    titleBar:SetScript("OnDragStart", StartGatheringFrameMove)
    titleBar:SetScript("OnDragStop", function()
        StopGatheringFrameMove()
    end)
    if MR.ApplyPanelHeaderAutoHide then MR:ApplyPanelHeaderAutoHide(frame, titleBar) end

    local closeBtn = CloseButton(titleBar, function()
        gatheringFrameInteractionActive = false
        gatheringRebuildPending = nil
        if frame.expansionDropdown then
            if frame.expansionDropdown._popup then frame.expansionDropdown._popup:Hide() end
            if frame.expansionDropdown._dismiss then frame.expansionDropdown._dismiss:Hide() end
        end
        frame:Hide()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", false) end
    end)
    closeBtn:SetFrameLevel(titleBar:GetFrameLevel() + 2)

    local gearBtn = HeaderIconButton(
        titleBar,
        "Interface\\Buttons\\UI-OptionsButton",
        {0.85, 0.65, 0.20},
        {1, 1, 1},
        L["ProfKnowledge_OptionsTitle"],
        function() MR:ToggleGatheringLocationsConfig() end
    )
    gearBtn:SetFrameLevel(titleBar:GetFrameLevel() + 2)
    local shoppingButton = ns.CreateDarkmoonShoppingButton(titleBar)
    shoppingButton:SetFrameLevel(titleBar:GetFrameLevel() + 2)
    shoppingButton:SetPoint("RIGHT", gearBtn, "LEFT", -3, 0)
    shoppingButton:SetShown(MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() or false)

    local expansionDropdown, selectedExpansion = CreateKnowledgeExpansionDropdown(titleBar,
        shoppingButton:IsShown() and shoppingButton or gearBtn)
    frame.expansionDropdown = expansionDropdown
    expansionDropdown:SetFrameLevel(titleBar:GetFrameLevel() + 2)
    expansionDropdown:ClearAllPoints()
    expansionDropdown:SetPoint("LEFT", titleBar, "LEFT", 8, -1)

    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY")
    titleTxt:SetFont(ns.FONT_HEADERS, math.max(10, (db.gatheringFontSize or 9) + 1), GetFontFlags())
    titleTxt:SetPoint("LEFT", titleBar, "LEFT", 9, 0)
    titleTxt:SetPoint("RIGHT", expansionDropdown, "LEFT", -6, 0)
    titleTxt:SetJustifyH("LEFT")
    titleTxt:SetText(StripInlineColor(L["ProfKnowledge_Title"] or "Profession Knowledge"))
    ns.RegisterThemedFontString(titleTxt, 0.78, 0.88, 0.92)
    titleTxt:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetFrameLevel(frame:GetFrameLevel() + 1)
    if headerBottom then
        scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
        scroll:SetPoint("BOTTOMRIGHT", titleBar, "TOPRIGHT", -8, 1)
    else
        scroll:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -1)
        scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 4)
    end
    local content = CreateFrame("Frame", nil, scroll)
    content:SetFrameLevel(scroll:GetFrameLevel() + 1)
    content:SetWidth(width - 8)
    content:SetHeight(1)

    local track = CreateFrame("Frame", nil, frame)
    track:SetFrameLevel(frame:GetFrameLevel() + 1)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 1, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    track:SetWidth(5)
    frame._scroll = scroll
    frame._scrollTrack = track

    local UpdateScrollBar, _, trackBg, thumbTex = ns.AttachScrollList(scroll, content, track)
    trackBg:SetColorTexture(0, 0, 0, 0.3 * chromeAlpha)
    ns.RegisterThemedTexture(thumbTex, 0.80, 0.53, 0.20, 0.6 * chromeAlpha)
    frame.UpdateScrollBar = UpdateScrollBar

    local ApplyMinimized

    local function UpdateMinBtn() return gatheringMinimized and "+" or "-" end
    local minBtn = HeaderToggleButton(titleBar, UpdateMinBtn, L["UI_Collapse"], function()
        gatheringMinimized = not gatheringMinimized
        minimized = gatheringMinimized
        if MR.db then MR.db.profile.gatheringMinimized = gatheringMinimized end
        ApplyMinimized(gatheringMinimized)
    end)
    minBtn:SetFrameLevel(titleBar:GetFrameLevel() + 2)
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -3, 0)
    gearBtn:SetPoint("RIGHT", minBtn, "LEFT", -3, 0)
    if chromeAlpha <= 0.001 then
        for _, headerBtn in ipairs({ closeBtn, gearBtn, minBtn, shoppingButton }) do
            if headerBtn.SetBackdropColor then
                headerBtn:SetBackdropColor(0, 0, 0, 0)
                headerBtn:SetBackdropBorderColor(0, 0, 0, 0)
            end
        end
    end

    local yOff = 0
    local RenderContent

    local dragger = CreateFrame("Frame", nil, frame)
    dragger:SetSize(12, 12)
    if headerBottom then
        dragger:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
    else
        dragger:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    end
    dragger:SetFrameLevel(frame:GetFrameLevel() + 10)
    dragger:EnableMouse(true)
    frame._dragger = dragger
    local dTex = dragger:CreateTexture(nil, "OVERLAY")
    dTex:SetAllPoints()
    dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    dragger:SetScript("OnEnter", function() if not db.gatheringLocked then dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight") end end)
    dragger:SetScript("OnLeave", function() dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up") end)

    local dragStartW, dragStartH, dragStartX, dragStartY
    local function UpdateGatheringResize()
        if not dragger._dragging then
            dragger:SetScript("OnUpdate", nil)
            return
        end
        local cx, cy = GetCursorPosition()
        local scale = frame:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        frame:SetWidth(math.max(MIN_W, math.min(MAX_W, dragStartW + (cx - dragStartX))))
        frame:SetHeight(math.max(MIN_H, math.min(MAX_H, dragStartH + (dragStartY - cy))))
    end
    dragger:SetScript("OnMouseDown", function(_, button)
        local currentDb = MR.db and MR.db.profile or db
        if button == "LeftButton" and not currentDb.gatheringLocked then
            dragStartW, dragStartH = frame:GetWidth(), frame:GetHeight()
            local scale = frame:GetEffectiveScale()
            dragStartX, dragStartY = GetCursorPosition()
            dragStartX, dragStartY = dragStartX / scale, dragStartY / scale
            dragger._dragging = true
            gatheringFrameInteractionActive = true
            dragger:SetScript("OnUpdate", UpdateGatheringResize)
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            dragger:SetScript("OnUpdate", nil)
            if MR.db then
                MR.db.profile.gatheringWidth = math.max(MIN_W, math.min(MAX_W, math.floor(frame:GetWidth())))
                MR.db.profile.gatheringHeight = math.max(MIN_H, math.min(MAX_H, math.floor(frame:GetHeight())))
            end
            gatheringFrameInteractionActive = false
            local pendingResetScroll = gatheringRebuildPending == "reset"
            gatheringRebuildPending = nil
            RebuildGatheringLocationsFrame(pendingResetScroll)
            if gatheringCfgFrame and gatheringCfgFrame:IsShown() then PopulateGatheringConfig(gatheringCfgFrame) end
        end
    end)
    dragger:SetScript("OnHide", function()
        dragger._dragging = false
        gatheringFrameInteractionActive = false
        dragger:SetScript("OnUpdate", nil)
    end)

    ApplyMinimized = function(isMin, animate)
        gatheringMinimized = isMin and true or false
        minimized = gatheringMinimized
        if MR.db then MR.db.profile.gatheringMinimized = gatheringMinimized end
        if minBtn.RefreshLabel then minBtn:RefreshLabel() end

        if gatheringMinimized then
            SyncManagedFramePos(frame, "gatheringLocPos", headerBottom and "bottom" or "top")
            if frame._scroll then frame._scroll:Hide() end
            if frame._scrollTrack then frame._scrollTrack:Hide() end
            if frame._dragger then frame._dragger:Hide() end
            if frame._gatheringHeaderGlow then frame._gatheringHeaderGlow:Hide() end
            frame._mrAnimTick = nil
            frame:SetScript("OnUpdate", nil)
            frame:SetHeight(TITLE_H)
        else
            SyncManagedFramePos(frame, "gatheringLocPos", headerBottom and "bottom" or "top")
            if frame._scroll then frame._scroll:Show() end
            if frame._scrollTrack then frame._scrollTrack:Show() end
            if frame._dragger then frame._dragger:Show() end
            if frame._gatheringHeaderGlow then
                frame._gatheringHeaderGlow:SetHeight(64)
                frame._gatheringHeaderGlow:Show()
            end
            local savedH = db.gatheringHeight or DEFAULT_H
            local naturalH = TITLE_H + 1 + yOff + 6
            local targetHeight = math.min(savedH, naturalH)
            if animate == false then
                frame:SetHeight(targetHeight)
            else
                ApplyFrameHeight(frame, targetHeight)
            end
            if frame.UpdateScrollBar then frame.UpdateScrollBar() end
        end
    end

    RenderContent = function(resetScroll)
        shoppingButton:SetShown(MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() or false)
        MR._professionKnowledgeWindowRenderCount = (MR._professionKnowledgeWindowRenderCount or 0) + 1
        if MR.NoteRefreshSource then MR:NoteRefreshSource("ProfessionKnowledge:Render", true) end
        RefreshFonts()
        db = MR.db and MR.db.profile or db
        hadProfCache = MR.playerProfessions and next(MR.playerProfessions) ~= nil
        if not hadProfCache and MR.RefreshPlayerProfessions then
            MR:RefreshPlayerProfessions()
        end
        hasProfCache = MR.playerProfessions and next(MR.playerProfessions) ~= nil
        professionsScanned = MR.db and MR.db.char and MR.db.char.professionsScanned == true
        alpha = db.gatheringAlpha or 1.0
        width = db.gatheringWidth or DEFAULT_W
        height = db.gatheringHeight or DEFAULT_H
        minimized = db.gatheringMinimized or false
        headerBottom = IsManagedHeaderBottom()
        panelAlpha = math.max(0, math.min(alpha, 1))
        contentAlpha = panelAlpha
        borderAlpha = 0.20 + (0.75 * panelAlpha)
        accentAlpha = 0.10 + (0.85 * panelAlpha)
        chromeAlpha = panelAlpha
        selectedExpansion = GetSelectedKnowledgeExpansion()

        local savedScroll = not resetScroll and scroll:GetVerticalScroll() or 0
        frame:SetWidth(width)
        content:SetWidth(width - 8)
        frame:SetScale(db.gatheringScale or 1.0)
        frame:SetMovable(not db.gatheringLocked)

        ApplyGatheringFrameTheme(frame, {
            alpha = alpha,
            bg = { 0.03, 0.05, 0.09, 0.97 * alpha },
            border = { 0.24, 0.31, 0.42, alpha },
            accent = { 0.18, 0.78, 0.72 },
            headerHeight = 64,
        })

        titleBar:ClearAllPoints()
        scroll:ClearAllPoints()
        dragger:ClearAllPoints()
        if headerBottom then
            titleBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
            titleBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
            scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
            scroll:SetPoint("BOTTOMRIGHT", titleBar, "TOPRIGHT", -8, 1)
            dragger:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
        else
            titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            scroll:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -1)
            scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 4)
            dragger:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        end

        titleTxt:SetFont(ns.FONT_HEADERS, math.max(10, (db.gatheringFontSize or 9) + 1), GetFontFlags())
        expansionDropdown:Update()
        trackBg:SetColorTexture(0, 0, 0, 0.3 * chromeAlpha)
        local tr, tg, tb = ns.ResolveThemeColor(0.80, 0.53, 0.20)
        thumbTex:SetColorTexture(tr, tg, tb, 0.6 * chromeAlpha)

        frame._emptyDrag = nil
        BeginProfessionRender(content)
        yOff = BuildProfessionCards(content, width, 0, db.gatheringFontSize or 9, contentAlpha, borderAlpha, chromeAlpha, accentAlpha, db, selectedExpansion)
        frame._professionKnowledgeEmptyState = yOff == 0
        if yOff == 0 then
            local emptyText = RenderFontString(content, "OVERLAY")
            emptyText:SetFont(ns.FONT_ROWS, db.gatheringFontSize or 9, GetFontFlags())
            emptyText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
            emptyText:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, -10)
            emptyText:SetJustifyH("LEFT")
            emptyText:SetTextColor(0.72, 0.72, 0.72, 0.95)
            emptyText:SetText((hasProfCache or professionsScanned) and L["Gathering_NoProfessions"] or L["Gathering_Loading"])
            yOff = 32

            local emptyDrag = RenderFrame("Frame", frame)
            emptyDrag:SetFrameLevel(scroll:GetFrameLevel() + 3)
            emptyDrag:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
            emptyDrag:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 0, 0)
            emptyDrag:EnableMouse(true)
            emptyDrag:RegisterForDrag("LeftButton")
            emptyDrag:SetScript("OnDragStart", StartGatheringFrameMove)
            emptyDrag:SetScript("OnDragStop", StopGatheringFrameMove)
            frame._emptyDrag = emptyDrag
        end
        EndProfessionRender()

        content:SetHeight(math.max(yOff, 1))
        scroll:SetVerticalScroll(savedScroll)
        UpdateScrollBar()
        ApplyMinimized(minimized, false)
    end

    frame.ApplyMinimized = ApplyMinimized
    frame.RefreshContent = function(_, resetScroll)
        RenderContent(resetScroll)
    end

    RenderContent(true)

    MR.gatheringLocationsFrame = frame
    frame:Show()
    return frame
end

RebuildGatheringLocationsFrame = function(resetScroll)
    MR._professionKnowledgeWindowRefreshRequestCount = (MR._professionKnowledgeWindowRefreshRequestCount or 0) + 1
    if MR.NoteRefreshSource then MR:NoteRefreshSource("ProfessionKnowledge:RefreshRequest", true) end
    RefreshFonts()
    if gatheringFrameInteractionActive then
        gatheringRebuildPending = resetScroll and "reset" or true
        return
    end

    if not gatheringLocationsFrame then
        gatheringLocationsFrame = BuildGatheringLocationsFrame()
    elseif gatheringLocationsFrame.RefreshContent then
        gatheringLocationsFrame:RefreshContent(resetScroll)
    end

end

function MR.RequestGatheringLocationsRefresh()
    if gatheringLocationsFrame then
        RebuildGatheringLocationsFrame()
    end
end

function MR:ToggleGatheringLocationsConfig()
    if not gatheringCfgFrame then
        gatheringCfgFrame = BuildGatheringConfigFrame()
        PopulateGatheringConfig(gatheringCfgFrame)
    end
    if gatheringCfgFrame:IsShown() then gatheringCfgFrame:Hide()
    else
        gatheringCfgFrame:Show()
        gatheringCfgFrame:ClearAllPoints()
        local anchored = false
        if gatheringLocationsFrame then
            local x, y = gatheringLocationsFrame:GetCenter()
            if x and y then
                gatheringCfgFrame:SetPoint("LEFT", gatheringLocationsFrame, "RIGHT", 10, 0)
                gatheringCfgFrame:SetScale(gatheringLocationsFrame:GetScale())
                anchored = true
            end
        end
        if not anchored and MR.frame then
            gatheringCfgFrame:SetPoint("TOPLEFT", MR.frame, "TOPRIGHT", 4, 0)
            gatheringCfgFrame:SetScale(MR.frame:GetScale())
        elseif not anchored then
            gatheringCfgFrame:SetPoint("CENTER")
            gatheringCfgFrame:SetScale(1)
        end
        if MR.CaptureFrameScreenPosition and MR.RestoreFrameScreenPosition then
            local left, top = MR:CaptureFrameScreenPosition(gatheringCfgFrame)
            MR:RestoreFrameScreenPosition(gatheringCfgFrame, left, top)
        end
    end
end

local function ToggleGatheringLocations()
    if MR._instanceFramesHidden then
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", true) end
        return
    end
    if not gatheringLocationsFrame then
        gatheringLocationsFrame = BuildGatheringLocationsFrame()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", true) end
    elseif gatheringLocationsFrame:IsShown() then
        gatheringLocationsFrame:Hide()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", false) end
    else
        if MR.ClearManagedWindowsBundleHidden then MR:ClearManagedWindowsBundleHidden() end
        gatheringLocationsFrame:RefreshContent()
        gatheringLocationsFrame:Show()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", true) end
    end
end

MR.ToggleGatheringLocations = ToggleGatheringLocations

function MR:ShowGatheringLocations()
    if self.ClearManagedWindowsBundleHidden then self:ClearManagedWindowsBundleHidden() end
    if self._instanceFramesHidden then
        if self.SetManagedWindowOpen then self:SetManagedWindowOpen("gatheringLocOpen", true) end
        return
    end
    if not gatheringLocationsFrame then
        gatheringLocationsFrame = BuildGatheringLocationsFrame()
    else
        gatheringLocationsFrame:RefreshContent()
        gatheringLocationsFrame:Show()
    end
    if self.SetManagedWindowOpen then self:SetManagedWindowOpen("gatheringLocOpen", true) end
end

function MR:EnsureGatheringLocationsShown()
    if self._instanceFramesHidden then
        if self.SetManagedWindowOpen then self:SetManagedWindowOpen("gatheringLocOpen", true) end
        return
    end
    if not gatheringLocationsFrame then
        gatheringLocationsFrame = BuildGatheringLocationsFrame()
    else
        gatheringLocationsFrame:RefreshContent()
        gatheringLocationsFrame:Show()
    end
    if self.SetManagedWindowOpen then self:SetManagedWindowOpen("gatheringLocOpen", true) end
end

function MR:RefreshGatheringLocationsFrame()
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self._deferredInstanceGatheringRefresh = true
        return
    end

    if self.ShouldDeferForCombat and self:ShouldDeferForCombat("gatheringFrame") then
        return
    end

    if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then RebuildGatheringLocationsFrame() end
end

function MR:HideGatheringLocations(persistState)
    if gatheringLocationsFrame then gatheringLocationsFrame:Hide() end
    if gatheringCfgFrame then gatheringCfgFrame:Hide() end
    if persistState ~= false and self.db then self:SetManagedWindowOpen("gatheringLocOpen", false) end
end

function MR:RepopulateGatheringConfig()
    if gatheringCfgFrame and gatheringCfgFrame:IsShown() then PopulateGatheringConfig(gatheringCfgFrame) end
end

function MR:RebuildGatheringLocationsFrame()
    if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then RebuildGatheringLocationsFrame() end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "MidnightRoutine" then
        if MR.db then
            gatheringMinimized = MR.db.profile.gatheringMinimized or false
        end
        eventFrame:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if MR.db
            and MR.GetManagedWindowOpen
            and MR:GetManagedWindowOpen("gatheringLocOpen")
            and not (MR.IsManagedWindowsBundleHidden and MR:IsManagedWindowsBundleHidden()) then
            MR:ShowGatheringLocations()
        end
        eventFrame:UnregisterEvent("PLAYER_LOGIN")
    end
end)

function PK.GetLocationsFrame()
    return gatheringLocationsFrame
end

PK.RebuildGatheringLocationsFrame = RebuildGatheringLocationsFrame
