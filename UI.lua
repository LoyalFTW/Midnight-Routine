local cfgFrame
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local PANEL_MIN_WIDTH  = 200
local PANEL_MAX_WIDTH  = 500
local PANEL_MIN_HEIGHT = 100
local PANEL_MAX_HEIGHT = 800
local FONT_ROWS    = MR_FONT_ROWS
local FONT_HEADERS = MR_FONT_HEADERS

local FONT_SIZE_MIN = 7
local FONT_SIZE_MAX = 20

local ROW_HEIGHT    = 18
local HEADER_HEIGHT = 18
local PADDING       = 6

local GetFontSize = MR_GetFontSize

local function RecalcLayout()
    local fs = GetFontSize()
    ROW_HEIGHT    = math.max(14, fs + 7)
    HEADER_HEIGHT = math.max(14, fs + 7)
    PADDING       = math.max(4, math.floor(fs * 0.55))
end

local hex = MR_HEX

local COL = MR_COL

local function ApplyTheme()
    if not MR.frame then return end
    local t = MR.db.profile.transparentMode
    local v = MR.db.profile.frameAlpha or 1.0
    local f = MR.frame
    if t then
        f:SetBackdropColor(0, 0, 0, 0)
        f:SetBackdropBorderColor(0.3, 0.6, 0.8, 0.25 * v)
        if MR._titleBar    then MR._titleBar:SetBackdropColor(0.02, 0.18, 0.35, 0.45 * v) end
        if MR._scrollBg    then MR._scrollBg:SetColorTexture(0, 0, 0, 0) end
        if MR._titleAccent then MR._titleAccent:SetAlpha(v) end
    else
        f:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4] * v)
        f:SetBackdropBorderColor(0.15, 0.15, 0.2, v)
        if MR._titleBar    then MR._titleBar:SetBackdropColor(0.05, 0.12, 0.22, v) end
        if MR._scrollBg    then MR._scrollBg:SetColorTexture(COL.bg[1], COL.bg[2], COL.bg[3], 0.96 * v) end
        if MR._titleAccent then MR._titleAccent:SetAlpha(v) end
    end
end

local function ApplyWidth(newW)
    newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, math.floor(newW)))
    MR.db.profile.width = newW
    if MR.frame then MR.frame:SetWidth(newW) end
    MR:RefreshUI()
end
MR.ApplyWidth = ApplyWidth

local function ApplyHeight(newH)
    newH = math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, math.floor(newH)))
    MR.db.profile.height = newH
    if MR.frame then MR.frame:SetHeight(newH) end
    MR:RefreshUI()
end
MR.ApplyHeight = ApplyHeight

local function ApplyFontSize(newSize)
    newSize = math.max(FONT_SIZE_MIN, math.min(FONT_SIZE_MAX, math.floor(newSize)))
    MR.db.profile.fontSize = newSize
    RecalcLayout()
    MR:RefreshUI()
end
MR.ApplyFontSize = ApplyFontSize

local WC          = MR_WC
local countColor  = MR_CountColor
local SetDotColor = MR_SetDotColor

function MR:BuildUI()
    if self.frame then self.frame:Show() return end

    RecalcLayout()
    local w = MR.db.profile.width or 260
    local h = MR.db.profile.height or 400

    local f = CreateFrame("Frame", "MidnightRoutineFrame", UIParent, "BackdropTemplate")
    f:SetWidth(w)
    f:SetHeight(h)
    f:SetFrameStrata("MEDIUM")
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4])
    f:SetBackdropBorderColor(0.15, 0.15, 0.2, 1)
    f:SetMovable(true)
    f:SetClampedToScreen(true)

    local p = MR.db.profile.position
    if p and p.point then
        f:SetPoint(p.point, UIParent, p.relPoint or p.point, p.x or 0, p.y or 0)
    else
        f:SetPoint("CENTER")
    end
    f:SetScale(MR.db.profile.scale or 1)
    self.frame = f

    f:SetScript("OnShow", function()
        MR:Scan()
    end)

    local HEADER_H = 24

    local scrollBg = f:CreateTexture(nil, "BACKGROUND")
    scrollBg:SetPoint("TOPLEFT",     f, "TOPLEFT",     0, -HEADER_H)
    scrollBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0,   0)
    scrollBg:SetColorTexture(COL.bg[1], COL.bg[2], COL.bg[3], 0.96)
    MR._scrollBg = scrollBg

    local titleBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    MR._titleBar = titleBar
    titleBar:SetPoint("TOPLEFT")
    titleBar:SetPoint("TOPRIGHT")
    titleBar:SetHeight(HEADER_H)
    titleBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    titleBar:SetBackdropColor(0.04, 0.10, 0.20, 1)
    titleBar:SetBackdropBorderColor(0.10, 0.28, 0.35, 1)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        if not MR.db.profile.locked then f:StartMoving() end
    end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local pt, _, rp, x, y = f:GetPoint()
        MR.db.profile.position = { point = pt, relPoint = rp, x = x, y = y }
    end)

    local titleAccent = titleBar:CreateTexture(nil, "ARTWORK")
    MR._titleAccent = titleAccent
    titleAccent:SetPoint("TOPLEFT",    titleBar, "TOPLEFT",    0, 0)
    titleAccent:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    titleAccent:SetWidth(3)
    titleAccent:SetColorTexture(0.16, 0.78, 0.75, 1)

    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(14, 14)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    titleIcon:SetTexture("Interface\\AddOns\\MidnightRoutine\\Media\\Icon")
    titleIcon:SetVertexColor(0.16, 0.78, 0.75, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), "OUTLINE")
    title:SetPoint("LEFT", titleIcon, "RIGHT", 5, 0)
    title:SetText(L["Title"])

    local titleCount = titleBar:CreateFontString(nil, "OVERLAY")
    titleCount:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), "OUTLINE")
    titleCount:SetTextColor(0.45, 0.55, 0.55)
    self.titleCount = titleCount

    local BTN_SIZE   = 16
    local BTN_PAD    = 3
    local BTN_MARGIN = 4

    local function MakeHeaderBtn(icon, normalColor, hoverBg, hoverBorder, tooltipText, tooltipSub)
        local btn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
        btn:SetSize(BTN_SIZE, BTN_SIZE)
        btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        btn:SetBackdropColor(0.06, 0.12, 0.22, 0.85)
        btn:SetBackdropBorderColor(0.15, 0.35, 0.40, 0.9)

        local iconObj
        if icon.tex then
            local t = btn:CreateTexture(nil, "OVERLAY")
            t:SetSize(BTN_SIZE - 2, BTN_SIZE - 2)
            t:SetPoint("CENTER", btn, "CENTER", 0, 0)
            t:SetTexture(icon.tex)
            t:SetVertexColor(normalColor[1], normalColor[2], normalColor[3])
            iconObj = t
            btn._iconTex = t
        else
            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_HEADERS, 12, "OUTLINE")
            lbl:SetPoint("CENTER", btn, "CENTER", 0, 1)
            lbl:SetText(icon.text)
            lbl:SetTextColor(normalColor[1], normalColor[2], normalColor[3])
            iconObj = lbl
            btn._lbl = lbl
        end

        btn._normalColor = normalColor
        btn._iconObj     = iconObj
        btn._isTexture   = (icon.tex ~= nil)

        btn:SetScript("OnEnter", function(s)
            btn:SetBackdropColor(hoverBg[1], hoverBg[2], hoverBg[3], 1)
            btn:SetBackdropBorderColor(hoverBorder[1], hoverBorder[2], hoverBorder[3], 1)
            if btn._isTexture then
                btn._iconObj:SetVertexColor(1, 1, 1)
            else
                btn._iconObj:SetTextColor(1, 1, 1)
            end
            if tooltipText then
                GameTooltip:SetOwner(s, "ANCHOR_BOTTOM")
                GameTooltip:SetText(tooltipText, 1, 1, 1)
                if tooltipSub then GameTooltip:AddLine(tooltipSub, 0.6, 0.6, 0.6) end
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function()
            btn:SetBackdropColor(0.06, 0.12, 0.22, 0.85)
            btn:SetBackdropBorderColor(0.15, 0.35, 0.40, 0.9)
            if btn._isTexture then
                btn._iconObj:SetVertexColor(normalColor[1], normalColor[2], normalColor[3])
            else
                btn._iconObj:SetTextColor(normalColor[1], normalColor[2], normalColor[3])
            end
            GameTooltip:Hide()
        end)
        return btn
    end

    local closeBtn = MakeHeaderBtn(
        { text = "x" },
        {0.75, 0.28, 0.28},
        {0.35, 0.06, 0.06},
        {0.90, 0.25, 0.25},
        L["Close"],
        L["UI_HideAddon"]
    )
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -BTN_MARGIN, 0)
    closeBtn:SetScript("OnClick", function()
        f:Hide()
        MR.db.profile.panelOpen = false
    end)

    local minBtn = MakeHeaderBtn(
        { text = "-" },
        {0.25, 0.80, 0.68},
        {0.06, 0.22, 0.28},
        {0.20, 0.80, 0.65},
        L["Minimize"],
        L["UI_CollapseHint"]
    )
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -BTN_PAD, 0)
    self.minBtn = minBtn

    local function UpdateMinimizeVisual()
        minBtn._lbl:SetText(MR.db.profile.minimized and "+" or "-")
    end
    UpdateMinimizeVisual()
    self.UpdateMinimizeVisual = UpdateMinimizeVisual

    local function ApplyMinimizeState()
        if MR.db.profile.minimized then
            local left = f:GetLeft()
            local top  = f:GetTop()
            if left and top then
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
                MR.db.profile.position = { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = left, y = top }
            end
            if MR.scroll       then MR.scroll:Hide()       end
            if MR._scrollBg    then MR._scrollBg:Hide()    end
            if MR._scrollTrack then MR._scrollTrack:Hide() end
            if MR._dragger     then MR._dragger:Hide()     end
            f:SetHeight(HEADER_H)
        else
            if MR.scroll       then MR.scroll:Show()       end
            if MR._scrollBg    then MR._scrollBg:Show()    end
            if MR._scrollTrack then MR._scrollTrack:Show() end
            if MR._dragger     then MR._dragger:Show()     end
            MR:RefreshUI()
        end
        UpdateMinimizeVisual()
    end
    self.ApplyMinimizeState = ApplyMinimizeState

    minBtn:SetScript("OnClick", function()
        MR.db.profile.minimized = not MR.db.profile.minimized
        ApplyMinimizeState()
    end)

    local cfgBtn = MakeHeaderBtn(
        { tex = "Interface\\Buttons\\UI-OptionsButton" },
        {0.85, 0.65, 0.20},
        {0.18, 0.13, 0.03},
        {0.95, 0.72, 0.18},
        L["Options"],
        L["UI_ChatHint"]
    )
    cfgBtn:SetPoint("RIGHT", minBtn, "LEFT", -BTN_PAD, 0)
    cfgBtn:SetScript("OnClick", function()
        MR:ToggleConfig()
        MR:DismissFirstTimeGlow()
    end)

    local origCfgEnter = cfgBtn:GetScript("OnEnter")
    cfgBtn:SetScript("OnEnter", function(s)
        origCfgEnter(s)
        if MR.db and not MR.db.profile.firstSeen then
            GameTooltip:AddLine(L["Options_Glow"], 1, 1, 1)
            GameTooltip:AddLine(L["UI_ModularHint"], 0.9, 0.85, 0.3)
            GameTooltip:Show()
        end
    end)

    local cfgShine = CreateFrame("Frame", nil, cfgBtn)
    cfgShine:SetSize(28, 28)
    cfgShine:SetPoint("CENTER", cfgBtn, "CENTER", 0, 0)
    cfgShine:Hide()
    local function MakeSparkle(parent, x, y)
        local t = parent:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\ItemSocketingFrame\\UI-ItemSockingFrame-Glow")
        t:SetSize(10, 10)
        t:SetPoint("CENTER", parent, "CENTER", x, y)
        t:SetBlendMode("ADD")
        return t
    end
    cfgShine._sparks = {
        MakeSparkle(cfgShine, -9,  9),
        MakeSparkle(cfgShine,  9,  9),
        MakeSparkle(cfgShine, -9, -9),
        MakeSparkle(cfgShine,  9, -9),
    }
    local elapsed = 0
    cfgShine:SetScript("OnUpdate", function(self, dt)
        elapsed = elapsed + dt
        local alpha = 0.5 + 0.5 * math.sin(elapsed * 4)
        for _, s in ipairs(self._sparks) do s:SetAlpha(alpha) end
    end)
    cfgShine.Play = function(self) self:Show() end
    cfgShine.Stop = function(self) self:Hide() end
    self.cfgShine = cfgShine

    self.cfgBtn = cfgBtn

    titleCount:SetPoint("RIGHT", cfgBtn, "LEFT", -6, 0)

    local scroll = CreateFrame("ScrollFrame", "MRScrollFrame", f)
    scroll:SetPoint("TOPLEFT",     titleBar, "BOTTOMLEFT",  0,  -1)
    scroll:SetPoint("BOTTOMRIGHT", f,        "BOTTOMRIGHT", -9,  4)
    scroll:EnableMouseWheel(true)
    self.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth((MR.db.profile.width or 260) - 9)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    self.content = content

    local track = CreateFrame("Frame", nil, f)
    self._scrollTrack = track
    track:SetPoint("TOPLEFT",    scroll, "TOPRIGHT",    1, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    track:SetWidth(5)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0, 0, 0, 0.3)

    local thumb = track:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(5)
    thumb:SetColorTexture(0.25, 0.65, 0.65, 0.75)

    local function UpdateScrollBar()
        local viewH    = scroll:GetHeight()
        local contentH = content:GetHeight()
        if contentH <= viewH or viewH <= 0 then thumb:Hide() return end
        thumb:Show()
        local trackH = math.max(track:GetHeight(), 1)
        local thumbH = math.max(trackH * (viewH / contentH), 14)
        local pct    = scroll:GetVerticalScroll() / (contentH - viewH)
        thumb:SetHeight(thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -((trackH - thumbH) * pct))
    end

    scroll:SetScript("OnMouseWheel", function(_, delta)
        local cur = scroll:GetVerticalScroll()
        local max = math.max(content:GetHeight() - scroll:GetHeight(), 0)
        scroll:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, max)))
        UpdateScrollBar()
    end)
    scroll:SetScript("OnScrollRangeChanged", function() UpdateScrollBar() end)
    scroll:SetScript("OnVerticalScroll",     function() UpdateScrollBar() end)
    self.UpdateScrollBar = UpdateScrollBar

    self.widgets         = {}
    self.sectionRegistry = {}

    local dragger = CreateFrame("Frame", nil, f)
    dragger:SetSize(12, 12)
    dragger:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    dragger:SetFrameLevel(f:GetFrameLevel() + 10)
    dragger:EnableMouse(true)

    local dTex = dragger:CreateTexture(nil, "OVERLAY")
    dTex:SetAllPoints()
    dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

    dragger:SetScript("OnEnter", function()
        if not MR.db.profile.locked then
            dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        end
    end)
    dragger:SetScript("OnLeave", function()
        dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)

    local dragStartW, dragStartH, dragStartX, dragStartY
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not MR.db.profile.locked then
            dragStartW = f:GetWidth()
            dragStartH = f:GetHeight()
            dragStartX, dragStartY = GetCursorPosition()
            local scale = f:GetEffectiveScale()
            dragStartX = dragStartX / scale
            dragStartY = dragStartY / scale
            dragger._dragging = true
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            local newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, math.floor(f:GetWidth())))
            local newH = math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, math.floor(f:GetHeight())))
            MR.db.profile.width  = newW
            MR.db.profile.height = newH
            f:SetWidth(newW)
            f:SetHeight(newH)
            MR:RefreshUI()
            if cfgFrame and cfgFrame:IsShown() then MR:PopulateConfigFrame(cfgFrame) end
        end
    end)
    dragger:SetScript("OnUpdate", function()
        if not dragger._dragging then return end
        local cx, cy = GetCursorPosition()
        local scale = f:GetEffectiveScale()
        cx = cx / scale
        cy = cy / scale
        local dx = cx - dragStartX
        local dy = dragStartY - cy
        local newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, dragStartW + dx))
        local newH = math.max(PANEL_MIN_HEIGHT, math.min(PANEL_MAX_HEIGHT, dragStartH + dy))
        f:SetWidth(newW)
        f:SetHeight(newH)
    end)
    self._dragger = dragger

    self:RefreshUI()
    ApplyTheme()
end

function MR:RefreshUI()
    if not self.frame or not self.content then return end

    RecalcLayout()

    for _, w in ipairs(self.widgets or {}) do
        w:Hide(); w:SetParent(nil)
    end
    self.widgets         = {}
    self.sectionRegistry = {}

    local allDone, allTotal = 0, 0

    local frameW   = MR.db.profile.width or 260
    local usableW  = frameW - 9
    local MIN_COL  = 200
    local numCols  = math.max(1, math.floor(usableW / MIN_COL))
    local colW     = math.floor(usableW / numCols)

    local visibleMods = {}
    for _, mod in ipairs(MR:GetOrderedModules()) do
        local modVisible = not mod.isVisible or mod:isVisible()
        if MR:IsModuleEnabled(mod.key) and modVisible then
            local h = self:MeasureSection(mod)
            table.insert(visibleMods, { mod = mod, h = h })
            for _, row in ipairs(mod.rows) do
                local rowVisible = not row.isVisible or row.isVisible()
                if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
                    allTotal = allTotal + 1
                    if MR:GetProgress(mod.key, row.key) >= row.max then allDone = allDone + 1 end
                end
            end
        end
    end

    local cols = {}
    for i = 1, numCols do cols[i] = 0 end

    local totalModH = 0
    for _, entry in ipairs(visibleMods) do totalModH = totalModH + entry.h end

    local modColAssign = {}
    local curCol = 1
    for _, entry in ipairs(visibleMods) do
        if curCol < numCols and cols[curCol] >= totalModH / numCols then
            curCol = curCol + 1
        end
        table.insert(modColAssign, { mod = entry.mod, col = curCol, yOff = cols[curCol] })
        cols[curCol] = cols[curCol] + entry.h
    end

    for _, assign in ipairs(modColAssign) do
        local xOff = (assign.col - 1) * colW
        self:BuildSection(assign.mod, assign.yOff, xOff, colW, assign.col)
    end

    for c = 2, numCols do
        local sep = CreateFrame("Frame", nil, self.content)
        sep:SetWidth(1)
        sep:SetPoint("TOPLEFT",    self.content, "TOPLEFT",    (c - 1) * colW, 0)
        sep:SetPoint("BOTTOMLEFT", self.content, "BOTTOMLEFT", (c - 1) * colW, 0)
        local sepTex = sep:CreateTexture(nil, "ARTWORK")
        sepTex:SetAllPoints()
        sepTex:SetColorTexture(1, 1, 1, 0.08)
        table.insert(self.widgets, sep)
    end

    self.titleCount:SetText(string.format("%d / %d", allDone, allTotal))
    self.titleCount:SetTextColor(countColor(allDone, allTotal))

    local totalH = 0
    for c = 1, numCols do if cols[c] > totalH then totalH = cols[c] end end

    self.content:SetWidth(usableW)

    self.content:SetHeight(math.max(totalH, 1))
    local userH = MR.db.profile.height or 400
    self.frame:SetHeight(math.max(PANEL_MIN_HEIGHT, math.min(userH, PANEL_MAX_HEIGHT)))

    if self.scroll then
        local maxScroll = math.max(math.max(totalH, 1) - self.scroll:GetHeight(), 0)
        local cur = self.scroll:GetVerticalScroll()
        if cur > maxScroll then
            self.scroll:SetVerticalScroll(maxScroll)
        end
    end

    if self.UpdateScrollBar then self.UpdateScrollBar() end

    if MR.db.profile.minimized then
        if self.scroll       then self.scroll:Hide()       end
        if self._scrollBg    then self._scrollBg:Hide()    end
        if self._scrollTrack then self._scrollTrack:Hide() end
        if self._dragger     then self._dragger:Hide()     end
        self.frame:SetHeight(24)
        if self.UpdateMinimizeVisual then self.UpdateMinimizeVisual() end
    else
        if self._dragger then self._dragger:Show() end
    end
end

function MR:MeasureSection(mod)
    local isOpen = MR:IsModuleOpen(mod.key)
    local hideComplete = MR:IsModuleHideComplete(mod.key)
    local h = HEADER_HEIGHT + 1
    if isOpen then
        for _, row in ipairs(mod.rows) do
            local rowVisible = not row.isVisible or row.isVisible()
            if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
                local done = MR:GetProgress(mod.key, row.key)
                local isComplete = not row.noMax and done >= row.max
                local collapsed  = hideComplete and isComplete
                h = h + (collapsed and 8 or ROW_HEIGHT)
            end
        end
    end
    return h
end

function MR:BuildSection(mod, yOff, xOff, colW, col)
    local isOpen = MR:IsModuleOpen(mod.key)

    local secDone, secTotal = 0, 0
    for _, row in ipairs(mod.rows) do
        local rowVisible = not row.isVisible or row.isVisible()
        if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
            secTotal = secTotal + 1
            if MR:GetProgress(mod.key, row.key) >= row.max then secDone = secDone + 1 end
        end
    end
    local allDone = (secTotal > 0) and (secDone == secTotal)

    local hdrFrame = CreateFrame("Frame", nil, self.content)
    hdrFrame:SetPoint("TOPLEFT", self.content, "TOPLEFT", xOff, -yOff)
    hdrFrame:SetSize(colW, HEADER_HEIGHT)
    hdrFrame:EnableMouse(true)

    local hdrBg = hdrFrame:CreateTexture(nil, "BACKGROUND")
    hdrBg:SetAllPoints()
    hdrBg:SetColorTexture(0, 0, 0, MR.db.profile.transparentMode and 0.45 or 0.55)

    local hdrHover = hdrFrame:CreateTexture(nil, "BORDER")
    hdrHover:SetAllPoints()
    hdrHover:SetColorTexture(1, 1, 1, 0)

    local accent = hdrFrame:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT")
    accent:SetSize(2, HEADER_HEIGHT)
    if allDone then
        accent:SetColorTexture(COL.complete[1], COL.complete[2], COL.complete[3], 1)
    else
        local customColor = MR:GetHeaderColor(mod.key)
        local lr,lg,lb = hex(customColor or mod.labelColor or "#ffffff")
        accent:SetColorTexture(lr, lg, lb, 1)
    end

    local lbl = hdrFrame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_HEADERS, GetFontSize(), "OUTLINE")
    lbl:SetPoint("LEFT", hdrFrame, "LEFT", 8, 0)
    local customColor = MR:GetHeaderColor(mod.key)
    lbl:SetText(allDone
        and WC("00ff96", mod.label)
        or  WC((customColor or mod.labelColor or "#ffffff"):gsub("#",""), mod.label))

    local cnt = hdrFrame:CreateFontString(nil, "OVERLAY")
    cnt:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), "OUTLINE")
    cnt:SetPoint("RIGHT", hdrFrame, "RIGHT", -18, 0)
    cnt:SetText(string.format("%d/%d", secDone, secTotal))
    cnt:SetTextColor(countColor(secDone, secTotal))

    local arrow = hdrFrame:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(8, 8)
    arrow:SetPoint("RIGHT", hdrFrame, "RIGHT", -5, 0)
    if isOpen then
        arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    else
        arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    end
    arrow:SetVertexColor(0.45, 0.45, 0.45)

    hdrFrame:EnableMouse(true)
    hdrFrame:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" then
            MR:SetModuleOpen(mod.key, not MR:IsModuleOpen(mod.key))
            MR:RefreshUI()
        end
    end)
    hdrFrame:SetScript("OnEnter", function()
        hdrHover:SetColorTexture(1, 1, 1, 0.05)
        GameTooltip:SetOwner(hdrFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(mod.label, 1, 1, 1)
        GameTooltip:AddLine(L["Tooltip_ExpandCollapse"], 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    hdrFrame:SetScript("OnLeave", function()
        hdrHover:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
    end)

    table.insert(self.widgets, hdrFrame)
    table.insert(self.sectionRegistry, { frame = hdrFrame, modKey = mod.key, col = col or 1, yOff = yOff })

    yOff = yOff + HEADER_HEIGHT

    local div = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
    div:SetPoint("TOPLEFT", self.content, "TOPLEFT", xOff, -yOff)
    div:SetSize(colW, 1)
    div:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    div:SetBackdropColor(1, 1, 1, 0.06)
    table.insert(self.widgets, div)

    if isOpen then
        local hideComplete = MR:IsModuleHideComplete(mod.key)
        for _, row in ipairs(mod.rows) do
            local rowVisible = not row.isVisible or row.isVisible()
            if rowVisible and MR:IsRowEnabled(mod.key, row.key) then
                local done      = MR:GetProgress(mod.key, row.key)
                local isComplete = not row.noMax and done >= row.max
                local collapsed  = hideComplete and isComplete
                yOff = self:BuildRow(mod, row, done, yOff, collapsed, xOff, colW)
            end
        end
    end

    self.sectionRegistry[#self.sectionRegistry].bottom = yOff

    return yOff
end

function MR:BuildRow(mod, row, done, yOff, collapsed, xOff, colW)
    xOff = xOff or 0
    colW = colW or ((MR.db.profile.width or 260) - 13)
    local isAutoTracked = (row.questIds ~= nil) or (row.liveKey ~= nil) or (row.spellId ~= nil) or (row.currencyId ~= nil)
    local isComplete    = not row.noMax and done >= row.max
    local GHOST_H       = 8
    local rowH          = collapsed and GHOST_H or ROW_HEIGHT

    local rowFrame = CreateFrame("Frame", nil, self.content)
    rowFrame:SetPoint("TOPLEFT", self.content, "TOPLEFT", xOff, -yOff)
    rowFrame:SetSize(colW, rowH)
    rowFrame:EnableMouse(true)

    if collapsed then
        local line = rowFrame:CreateTexture(nil, "ARTWORK")
        line:SetPoint("LEFT",  rowFrame, "LEFT",  PADDING + 10, 0)
        line:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
        line:SetHeight(1)
        line:SetColorTexture(0.25, 0.25, 0.25, 0.5)

        local dot = rowFrame:CreateTexture(nil, "ARTWORK")
        dot:SetSize(4, 4)
        dot:SetPoint("LEFT", rowFrame, "LEFT", PADDING, 0)
        dot:SetColorTexture(0.25, 0.55, 0.25, 0.6)

        rowFrame:SetScript("OnEnter", function()
            GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(L["Tooltip_DonePrefix"] .. row.label, 0.4, 0.85, 0.4, 1, true)
            GameTooltip:AddLine(L["Tooltip_CompletedWeek"], 0.3, 0.6, 0.3)
            GameTooltip:Show()
        end)
        rowFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

        table.insert(self.widgets, rowFrame)
        return yOff + rowH
    end

    local hover = rowFrame:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0)

    rowFrame:SetScript("OnEnter", function()
        hover:SetColorTexture(1, 1, 1, 0.04)
        GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(row.label, 1, 1, 1, 1, true)
        if row.note then GameTooltip:AddLine(row.note, 0.7, 0.7, 0.7, true) end
        if row.tooltipFunc then
            row.tooltipFunc(GameTooltip)
        end
        if row.liveKey then
            GameTooltip:AddLine(L["Tooltip_AutoBlizzard"], 0.4, 0.8, 1)
        elseif row.questIds then
            GameTooltip:AddLine(L["Tooltip_AutoQuest"], 0.4, 1, 0.6)
        elseif row.spellId then
            GameTooltip:AddLine(L["Tooltip_AutoItem"], 0.9, 0.6, 1)
        elseif row.currencyId then
            GameTooltip:AddLine(L["Tooltip_AutoCurrency"], 1, 0.8, 0.2)
        else
            GameTooltip:AddLine(L["Tooltip_ManualClick"], 0.5, 0.5, 0.5)
        end
        GameTooltip:Show()
    end)
    rowFrame:SetScript("OnLeave", function()
        hover:SetColorTexture(1, 1, 1, 0)
        GameTooltip:Hide()
    end)

    if not isAutoTracked then
        rowFrame:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                MR:BumpProgress(mod.key, row.key, 1, row.max)
            elseif button == "RightButton" then
                MR:BumpProgress(mod.key, row.key, -1, row.max)
            end
        end)
    end

    local dot = rowFrame:CreateTexture(nil, "ARTWORK")
    dot:SetSize(6, 6)
    dot:SetPoint("LEFT", rowFrame, "LEFT", PADDING, 0)
    SetDotColor(dot, done, row.max)

    local lbl = rowFrame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_ROWS, GetFontSize(), "OUTLINE")
    lbl:SetPoint("LEFT",  rowFrame, "LEFT",  PADDING + 10, 0)
    lbl:SetPoint("RIGHT", rowFrame, "RIGHT", -52, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(row.label)
    if isComplete then lbl:SetTextColor(0.38, 0.38, 0.38) end

    if isComplete then
        local strike = rowFrame:CreateTexture(nil, "OVERLAY")
        strike:SetHeight(1)
        strike:SetPoint("LEFT",  lbl, "LEFT",  0, 0)
        strike:SetPoint("RIGHT", lbl, "RIGHT", 0, 0)
        strike:SetColorTexture(0.35, 0.35, 0.35, 0.7)
    end

    local countFS = rowFrame:CreateFontString(nil, "OVERLAY")
    countFS:SetFont(FONT_ROWS, GetFontSize(), "OUTLINE")
    countFS:SetPoint("RIGHT", rowFrame, "RIGHT", -4, 0)
    countFS:SetJustifyH("RIGHT")
    countFS:SetText(row.noMax and tostring(done) or string.format("%d / %d", done, row.max))
    countFS:SetTextColor(countColor(done, row.max))

    if row.vaultLabel then
        local vl = rowFrame:CreateFontString(nil, "OVERLAY")
        vl:SetFont(FONT_ROWS, math.max(7, GetFontSize() - 2), "OUTLINE")
        vl:SetPoint("RIGHT", countFS, "LEFT", -4, 0)
        vl:SetText(row.vaultLabel)
        vl:SetTextColor(hex(row.vaultColor or "#ffffff"))
    end

    table.insert(self.widgets, rowFrame)
    return yOff + rowH
end

function MR:ToggleConfig()
    if cfgFrame and cfgFrame:IsShown() then cfgFrame:Hide() return end
    if not cfgFrame then cfgFrame = self:BuildConfigFrame() end
    self:PopulateConfigFrame(cfgFrame)
    cfgFrame:Show()
end

function MR:HideConfig()
    if cfgFrame then cfgFrame:Hide() end
end

function MR:BuildConfigFrame()
    local f = CreateFrame("Frame", "MRConfigFrame", UIParent, "BackdropTemplate")
    f:SetWidth(240)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
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
    tbar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    tbar:SetBackdropColor(0.06, 0.10, 0.20, 1)
    tbar:EnableMouse(true)
    tbar:RegisterForDrag("LeftButton")
    tbar:SetScript("OnDragStart", function() f:StartMoving() end)
    tbar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(FONT_HEADERS, 11, "OUTLINE")
    ttitle:SetText(L["Config_Title"])
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)

    local closeBtn = CreateFrame("Button", nil, tbar, "UIPanelCloseButton")
    closeBtn:SetSize(18, 18)
    closeBtn:SetPoint("RIGHT", tbar, "RIGHT", -2, 0)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    return f
end

function MR:PopulateConfigFrame(f)
    if f.body then
        local children = { f.body:GetChildren() }
        for _, child in ipairs(children) do
            local grandchildren = { child:GetChildren() }
            for _, gc in ipairs(grandchildren) do
                if gc:GetObjectType() == "Button" then
                    gc:SetScript("OnClick", nil)
                    gc:SetScript("OnEnter", nil)
                    gc:SetScript("OnLeave", nil)
                end
                gc:EnableMouse(false)
                gc:Hide()
            end
            if child:GetObjectType() == "Button" then
                child:SetScript("OnClick", nil)
                child:SetScript("OnEnter", nil)
                child:SetScript("OnLeave", nil)
            end
            child:EnableMouse(false)
            child:Hide()
        end
        f.body:Hide()
        f.body:SetParent(UIParent)
        f.body = nil
    end

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    body:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.body = body

    local yOff = -26

    local function Gap(h)          yOff = MR_OptionsGap(body, yOff, h) end
    local function Divider()       yOff = MR_OptionsDivider(body, yOff, 4) end
    local function SectionLabel(t) yOff = MR_OptionsSectionLabel(body, yOff, t, 8) end
    local function Checkbox(label, getVal, setVal, color)
        local r, g, b
        if color then r, g, b = hex(color) end
        yOff = MR_OptionsCheckbox(body, yOff, label, getVal, setVal, r, g, b, 4, nil)
    end
    local function Btn(label, onClick) yOff = MR_OptionsBtn(body, yOff, label, onClick, 192, 8) end

    SectionLabel(L["Config_RenownTracker"])
    Checkbox(L["Config_OpenRenown"],
        function() return MR.db and MR.db.profile.renownOpen end,
        function(v)
            MR.db.profile.renownOpen = v
            if MR.ToggleRenown then MR:ToggleRenown() end
        end, "#d9b82e")
    Gap(4); Divider()
    SectionLabel(L["Config_RaresFrame"])
    Checkbox(L["Config_OpenRares"],
        function() return MR.db and MR.db.profile.raresOpen end,
        function(v)
            MR.db.profile.raresOpen = v
            if MR.ToggleRares then MR:ToggleRares() end
        end, "#e05050")
    Gap(4); Divider()
    SectionLabel(L["Config_GatheringLocations"])
    Checkbox(L["Config_OpenGathering"],
        function() return MR.db and MR.db.profile.gatheringLocOpen end,
        function(v)
            MR.db.profile.gatheringLocOpen = v
            if MR.ToggleGatheringLocations then MR:ToggleGatheringLocations() end
        end, "#c9853f")
    Gap(4); Divider()
    SectionLabel(L["OPTIONS"])
    Checkbox(L["Config_CollapseCompleted"],
        function() return MR.db.profile.hideComplete end,
        function(v)
            MR.db.profile.hideComplete = v
            for _, mod in ipairs(MR.modules) do
                if MR.db.profile.modules[mod.key] then
                    MR.db.profile.modules[mod.key].hideComplete = nil
                end
            end
            MR:RefreshUI()
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

    Gap(6)
    yOff = MR_OptionsSlider(body, yOff, L["WIDTH"], PANEL_MIN_WIDTH, PANEL_MAX_WIDTH, 10,
        function() return MR.db.profile.width or 260 end,
        function(v) ApplyWidth(v); MR:PopulateConfigFrame(f) end,
        0.16, 0.78, 0.75, 8)

    Gap(6)
    yOff = MR_OptionsSlider(body, yOff, L["HEIGHT"], PANEL_MIN_HEIGHT, PANEL_MAX_HEIGHT, 10,
        function() return MR.db.profile.height or 400 end,
        function(v) ApplyHeight(v); MR:PopulateConfigFrame(f) end,
        0.16, 0.75, 0.78, 8)

    Gap(6)
    yOff = MR_OptionsSlider(body, yOff, L["Config_FontSize"], FONT_SIZE_MIN, FONT_SIZE_MAX, 1,
        function() return GetFontSize() end,
        function(v) ApplyFontSize(math.floor(v)); MR:PopulateConfigFrame(f) end,
        0.78, 0.55, 0.16, 8)

    local presets = { {"S", 9}, {"M", 11}, {"L", 14}, {"XL", 17} }
    local btnW = 42
    for i, p in ipairs(presets) do
        local pb = CreateFrame("Button", nil, body, "BackdropTemplate")
        pb:SetSize(btnW - 2, 16)
        pb:SetPoint("TOPLEFT", body, "TOPLEFT", 8 + (i-1) * btnW, yOff - 18)
        pb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        local isActive = (GetFontSize() == p[2])
        pb:SetBackdropColor(isActive and 0.12 or 0.05, isActive and 0.35 or 0.10, isActive and 0.32 or 0.18, 1)
        pb:SetBackdropBorderColor(isActive and 0.25 or 0.18, isActive and 0.85 or 0.40, isActive and 0.70 or 0.45, 1)
        local pfs = pb:CreateFontString(nil, "OVERLAY")
        pfs:SetFont(FONT_ROWS, 9, "OUTLINE")
        pfs:SetPoint("CENTER")
        pfs:SetText(p[1])
        pfs:SetTextColor(isActive and 0.2 or 0.6, isActive and 0.95 or 0.75, isActive and 0.75 or 0.65)
        pb:SetScript("OnClick", function()
            ApplyFontSize(p[2])
            MR:PopulateConfigFrame(f)
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

    Gap(4)
    yOff = MR_OptionsSlider(body, yOff, L["BACKGROUND"], 0, 1, 0.05,
        function() return MR.db.profile.frameAlpha or 1.0 end,
        function(v)
            MR.db.profile.frameAlpha = v
            ApplyTheme()
        end,
        0.40, 0.40, 0.40, 8)

    Gap(4)
    yOff = MR_OptionsSlider(body, yOff, L["SCALE"], 0.5, 2.0, 0.05,
        function() return MR.db.profile.scale or 1.0 end,
        function(v)
            MR.db.profile.scale = v
            if MR.frame then MR.frame:SetScale(v) end
        end,
        0.55, 0.22, 0.82, 8)

    Gap(4); Divider()
    SectionLabel(L["Config_ModuleSettings"])

    if not MR._cfgExpanded then MR._cfgExpanded = {} end

    local function BuildHideCompleteBtn(parent, key, anchorRight)
        local hideActive = MR:IsModuleHideComplete(key)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(16, 16)
        if anchorRight == parent then
            btn:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
        else
            btn:SetPoint("RIGHT", anchorRight, "LEFT", -2, 0)
        end
        btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
        btn:SetBackdropBorderColor(
            hideActive and 0.15 or 0.35,
            hideActive and 0.32 or 0.12,
            hideActive and 0.38 or 0.12, 1)
        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT_ROWS, 8, "OUTLINE")
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
        fs:SetText(hideActive and "H" or "S")
        fs:SetTextColor(hideActive and 0.45 or 0.55, hideActive and 0.75 or 0.25, hideActive and 0.70 or 0.25)
        btn:SetScript("OnClick", function()
            MR:SetModuleHideComplete(key, not MR:IsModuleHideComplete(key))
            MR:PopulateConfigFrame(f)
        end)
        btn:SetScript("OnEnter", function()
            btn:SetBackdropColor(0.08, 0.22, 0.32, 1)
            btn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
            fs:SetTextColor(1, 1, 1)
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetText(MR:IsModuleHideComplete(key) and L["Config_RowsCollapsed"] or L["Config_RowsShown"], 1, 1, 1)
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
        local swatch = MR_OptionsColorSwatch(parent, r, g, b,
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

    local drag = { active = false, srcKey = nil, targetIdx = nil }

    local dragGhost = CreateFrame("Frame", nil, body, "BackdropTemplate")
    dragGhost:SetHeight(20)
    dragGhost:SetFrameStrata("DIALOG")
    dragGhost:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    dragGhost:SetBackdropColor(0.08, 0.28, 0.22, 0.95)
    dragGhost:SetBackdropBorderColor(0.2, 0.9, 0.65, 1)
    dragGhost:Hide()
    local dragGhostLbl = dragGhost:CreateFontString(nil, "OVERLAY")
    dragGhostLbl:SetFont(FONT_HEADERS, 10, "OUTLINE")
    dragGhostLbl:SetPoint("LEFT", dragGhost, "LEFT", 8, 0)
    dragGhostLbl:SetTextColor(0.3, 1, 0.75)

    local dragLine = CreateFrame("Frame", nil, body)
    dragLine:SetHeight(2)
    dragLine:SetFrameStrata("DIALOG")
    dragLine:Hide()
    local dragLineTex = dragLine:CreateTexture(nil, "OVERLAY")
    dragLineTex:SetAllPoints()
    dragLineTex:SetColorTexture(0.2, 0.9, 0.65, 1)

    local _allMods = MR:GetOrderedModules()
    local _cfgRows = {}

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

    for _, mod in ipairs(_allMods) do
        local key = mod.key
        local optVisible = not mod.isVisible or mod:isVisible()

        if mod.profSkillLine then
            if MR.playerProfessions[mod.profSkillLine] then
                local ROW_H = 22
                local headerFr = CreateFrame("Frame", nil, body)
                headerFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
                headerFr:SetSize(196, ROW_H)

                local grip = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
                grip:SetSize(16, ROW_H - 2)
                grip:SetPoint("LEFT", headerFr, "LEFT", 1, 0)
                grip:RegisterForClicks("LeftButtonUp")
                grip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
                grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
                grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
                local gripLbl = grip:CreateFontString(nil, "OVERLAY")
                gripLbl:SetFont(FONT_HEADERS, 13, "OUTLINE")
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
                    MR:SetModuleEnabled(key, s:GetChecked())
                end)

                local hideBtn = BuildHideCompleteBtn(headerFr, key, headerFr)
                local colorSwatch = BuildColorSwatch(headerFr, key, mod, hideBtn)

                local lbl = headerFr:CreateFontString(nil, "OVERLAY")
                lbl:SetFont(FONT_ROWS, 10, "OUTLINE")
                lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
                lbl:SetPoint("RIGHT", colorSwatch, "LEFT", -2, 0)
                lbl:SetText(mod.label)
                lbl:SetJustifyH("LEFT")
                local customColor = MR:GetHeaderColor(key)
                if customColor or mod.labelColor then
                    lbl:SetTextColor(hex(customColor or mod.labelColor))
                else
                    lbl:SetTextColor(0.88, 0.88, 0.88)
                end

                yOff = yOff - ROW_H
            end

        elseif optVisible then
            local ROW_H = 22
            local headerFr = CreateFrame("Frame", nil, body)
            headerFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
            headerFr:SetSize(196, ROW_H)

            local cb = CreateFrame("CheckButton", nil, headerFr, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("LEFT", headerFr, "LEFT", 18, 0)
            cb:SetChecked(MR:IsModuleEnabled(key))
            cb:SetScript("OnClick", function(s)
                MR:SetModuleEnabled(key, s:GetChecked())
            end)

            local isExp = MR._cfgExpanded[key]
            local arrowBtn = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
            arrowBtn:SetSize(16, 16)
            arrowBtn:SetPoint("RIGHT", headerFr, "RIGHT", 0, 0)
            arrowBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
            arrowBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
            local arrowLbl = arrowBtn:CreateFontString(nil, "OVERLAY")
            arrowLbl:SetFont(FONT_HEADERS, 10, "OUTLINE")
            arrowLbl:SetPoint("CENTER", arrowBtn, "CENTER", 0, 1)
            arrowLbl:SetText(isExp and "v" or ">")
            arrowLbl:SetTextColor(0.45, 0.75, 0.70)
            arrowBtn:SetScript("OnClick", function()
                MR._cfgExpanded[key] = not MR._cfgExpanded[key]
                MR:PopulateConfigFrame(f)
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
            grip:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            grip:SetBackdropColor(0.12, 0.22, 0.20, 0.6)
            grip:SetBackdropBorderColor(0.30, 0.55, 0.48, 0.7)
            local gripLbl = grip:CreateFontString(nil, "OVERLAY")
            gripLbl:SetFont(FONT_HEADERS, 13, "OUTLINE")
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
            local colorSwatch = BuildColorSwatch(headerFr, key, mod, hideBtn)

            local lbl = headerFr:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, 10, "OUTLINE")
            lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
            lbl:SetPoint("RIGHT", colorSwatch, "LEFT", -2, 0)
            lbl:SetText(mod.label)
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

                for _, row in ipairs(mod.rows) do
                    local rkey    = row.key
                    local enabled = MR:IsRowEnabled(key, rkey)

                    local rowFr = CreateFrame("Frame", nil, body)
                    rowFr:SetPoint("TOPLEFT", body, "TOPLEFT", 18, yOff)
                    rowFr:SetSize(176, 18)

                    local rdot = rowFr:CreateTexture(nil, "ARTWORK")
                    rdot:SetSize(5, 5)
                    rdot:SetPoint("LEFT", rowFr, "LEFT", 0, 0)
                    local customColor = MR:GetHeaderColor(key)
                    if customColor or mod.labelColor then
                        rdot:SetColorTexture(hex(customColor or mod.labelColor))
                    else
                        rdot:SetColorTexture(0.4, 0.4, 0.4, 1)
                    end
                    rdot:SetAlpha(enabled and 0.8 or 0.25)

                    local cleanLabel = row.label:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
                    local rlbl = rowFr:CreateFontString(nil, "OVERLAY")
                    rlbl:SetFont(FONT_ROWS, 9, "OUTLINE")
                    rlbl:SetPoint("LEFT", rowFr, "LEFT", 10, 0)
                    rlbl:SetPoint("RIGHT", rowFr, "RIGHT", -20, 0)
                    rlbl:SetJustifyH("LEFT")
                    rlbl:SetText(cleanLabel)
                    rlbl:SetTextColor(enabled and 0.80 or 0.35, enabled and 0.80 or 0.35, enabled and 0.80 or 0.35)

                    local eyeBtn = CreateFrame("Button", nil, rowFr, "BackdropTemplate")
                    eyeBtn:SetSize(14, 14)
                    eyeBtn:SetPoint("RIGHT", rowFr, "RIGHT", 0, 0)
                    eyeBtn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
                    eyeBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                    eyeBtn:SetBackdropBorderColor(
                        enabled and 0.15 or 0.35,
                        enabled and 0.32 or 0.12,
                        enabled and 0.38 or 0.12, 1)
                    local eyeLbl = eyeBtn:CreateFontString(nil, "OVERLAY")
                    eyeLbl:SetFont(FONT_ROWS, 9, "OUTLINE")
                    eyeLbl:SetPoint("CENTER", eyeBtn, "CENTER", 0, 0)
                    eyeLbl:SetText(enabled and "o" or "-")
                    eyeLbl:SetTextColor(
                        enabled and 0.25 or 0.55,
                        enabled and 0.85 or 0.25,
                        enabled and 0.70 or 0.25)

                    eyeBtn:SetScript("OnClick", function()
                        MR:SetRowEnabled(key, rkey, not MR:IsRowEnabled(key, rkey))
                        MR:RefreshUI()
                        MR:PopulateConfigFrame(f)
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
                        eyeBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                        eyeBtn:SetBackdropBorderColor(
                            enabled and 0.15 or 0.35,
                            enabled and 0.32 or 0.12,
                            enabled and 0.38 or 0.12, 1)
                        eyeLbl:SetTextColor(
                            enabled and 0.25 or 0.55,
                            enabled and 0.85 or 0.25,
                            enabled and 0.70 or 0.25)
                        GameTooltip:Hide()
                    end)

                    yOff = yOff - 19
                end

                guide:SetPoint("TOPLEFT",    body, "TOPLEFT", 14, guideTopY)
                guide:SetPoint("BOTTOMLEFT", body, "TOPLEFT", 14, yOff + 4)

                Gap(3)
            end
        end
    end

    Gap(4); Divider()
    SectionLabel(L["RESETS"])
    Btn(L["Config_ResetEverything"], function()
        MR.db.char.progress = {}
        MR.db.profile.headerColors = {}
        MR:Scan()
        MR:PopulateConfigFrame(f)
    end)
    Btn(L["Config_ResetColors"], function()
        MR.db.profile.headerColors = {}
        MR:RefreshUI()
        MR:PopulateConfigFrame(f)
    end)
    Btn(L["Config_ResetOrder"], function()
        MR.db.profile.moduleOrder = {}
        MR._orderedModulesCache = nil
        MR:RefreshUI()
        MR:PopulateConfigFrame(f)
    end)

    Gap(8)
    local totalH = math.abs(yOff) + 8
    body:SetHeight(totalH)
    f:SetHeight(totalH)
end
