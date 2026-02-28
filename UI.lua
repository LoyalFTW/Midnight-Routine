local PANEL_MIN_WIDTH = 200
local PANEL_MAX_WIDTH = 500
local FONT_ROWS       = "Fonts\\FRIZQT__.TTF"
local FONT_HEADERS    = "Fonts\\FRIZQT__.TTF"
local TEX_GEAR        = "Interface\\GossipFrame\\DailyActiveQuestIcon"
local TEX_LOCK        = "Interface\\PaperDollInfoFrame\\UI-GearManager-LeatherLoop"

local FONT_SIZE_MIN = 7
local FONT_SIZE_MAX = 20

local ROW_HEIGHT    = 18
local HEADER_HEIGHT = 18
local PADDING       = 6

local function GetFontSize()
    if MR.db and MR.db.profile and MR.db.profile.fontSize then
        return MR.db.profile.fontSize
    end
    return 11
end

local function RecalcLayout()
    local fs = GetFontSize()
    ROW_HEIGHT    = math.max(14, fs + 7)
    HEADER_HEIGHT = math.max(14, fs + 7)
    PADDING       = math.max(4, math.floor(fs * 0.55))
end

local function hex(h)
    h = h:gsub("#","")
    return tonumber(h:sub(1,2),16)/255,
           tonumber(h:sub(3,4),16)/255,
           tonumber(h:sub(5,6),16)/255
end

local COL = {
    complete   = {0,    1,    0.59},
    half       = {1,    0.47, 0   },
    incomplete = {0.6,  0.6,  0.6 },
    bg         = {0.02, 0.03, 0.07, 0.96},
}

local function ApplyTheme()
    if not MR.frame then return end
    local t = MR.db.profile.transparentMode
    local f = MR.frame
    if t then
        f:SetBackdropColor(0, 0, 0, 0)
        f:SetBackdropBorderColor(0.3, 0.6, 0.8, 0.25)
        if MR._titleBar then MR._titleBar:SetBackdropColor(0.02, 0.18, 0.35, 0.45) end
        if MR._scrollBg then MR._scrollBg:SetColorTexture(0, 0, 0, 0) end
    else
        f:SetBackdropColor(COL.bg[1], COL.bg[2], COL.bg[3], COL.bg[4])
        f:SetBackdropBorderColor(0.15, 0.15, 0.2, 1)
        if MR._titleBar then MR._titleBar:SetBackdropColor(0.05, 0.12, 0.22, 1) end
        if MR._scrollBg then MR._scrollBg:SetColorTexture(COL.bg[1], COL.bg[2], COL.bg[3], 0.96) end
    end
end

local function ApplyWidth(newW)
    newW = math.max(PANEL_MIN_WIDTH, math.min(PANEL_MAX_WIDTH, math.floor(newW)))
    MR.db.profile.width = newW
    if MR.frame then MR.frame:SetWidth(newW) end
    if MR.content then MR.content:SetWidth(newW - 13) end
    MR:RefreshUI()
end
MR.ApplyWidth = ApplyWidth

local function ApplyFontSize(newSize)
    newSize = math.max(FONT_SIZE_MIN, math.min(FONT_SIZE_MAX, math.floor(newSize)))
    MR.db.profile.fontSize = newSize
    RecalcLayout()
    MR:RefreshUI()
end
MR.ApplyFontSize = ApplyFontSize

local function WC(rrggbb, text)
    return string.format("|cff%s%s|r", rrggbb, text)
end

local function countColor(done, max)
    if     done >= max then return COL.complete[1],   COL.complete[2],   COL.complete[3]
    elseif done  > 0   then return COL.half[1],       COL.half[2],       COL.half[3]
    else                    return COL.incomplete[1], COL.incomplete[2], COL.incomplete[3]
    end
end

local function SetDotColor(tex, done, max)
    if     done >= max then tex:SetColorTexture(COL.complete[1], COL.complete[2], COL.complete[3], 1)
    elseif done  > 0   then tex:SetColorTexture(COL.half[1],     COL.half[2],     COL.half[3],     1)
    else                    tex:SetColorTexture(0.3, 0.3, 0.3, 1)
    end
end

local DRAG = { active = false }

local dragUpdater = CreateFrame("Frame")
dragUpdater:SetScript("OnUpdate", function()
    if not DRAG.active then return end
    local cx, cy = GetCursorPosition()
    local s = UIParent:GetEffectiveScale()
    cx, cy = cx / s, cy / s
    if DRAG.ghost then
        DRAG.ghost:ClearAllPoints()
        DRAG.ghost:SetPoint("LEFT", UIParent, "BOTTOMLEFT", cx + 12, cy)
    end
    local sections = DRAG.sections
    if not sections or #sections == 0 then return end
    local bestSlot = #sections
    local bestDist = math.huge
    local slot0Y = sections[1].frame:GetTop() or cy
    local d = math.abs(cy - slot0Y)
    if d < bestDist then bestDist = d; bestSlot = 0 end
    for i, sec in ipairs(sections) do
        local slotY = sec.frame:GetBottom() or cy
        d = math.abs(cy - slotY)
        if d < bestDist then bestDist = d; bestSlot = i end
    end
    DRAG.targetSlot = bestSlot
    if DRAG.dropLine and MR.content then
        local slotY
        if bestSlot == 0 then
            slotY = sections[1] and sections[1].frame:GetTop() or cy
        else
            local sec = sections[bestSlot]
            slotY = sec and (sec.frame:GetBottom() or cy) or cy
        end
        local cL = MR.content:GetLeft()  or 0
        local cR = MR.content:GetRight() or (cL + (MR.db.profile.width or 260))
        DRAG.dropLine:ClearAllPoints()
        DRAG.dropLine:SetPoint("TOPLEFT",  UIParent, "BOTTOMLEFT", cL, slotY)
        DRAG.dropLine:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", cR, slotY)
        DRAG.dropLine:Show()
    end
end)

local function CommitSectionDrop()
    local modKey   = DRAG.modKey
    local slot     = DRAG.targetSlot
    local sections = DRAG.sections
    if not modKey or slot == nil or not sections then return end
    local order  = {}
    local srcIdx = nil
    for i, sec in ipairs(sections) do
        table.insert(order, sec.modKey)
        if sec.modKey == modKey then srcIdx = i end
    end
    if not srcIdx then return end
    table.remove(order, srcIdx)
    local insertAt = slot
    if srcIdx <= slot then insertAt = insertAt - 1 end
    insertAt = math.max(0, math.min(insertAt, #order))
    table.insert(order, insertAt + 1, modKey)
    MR:SetModuleOrder(order)
    MR:RefreshUI()
end

local function StopDrag()
    if not DRAG.active then return end
    DRAG.active = false
    CommitSectionDrop()
    if DRAG.ghost      then DRAG.ghost:Hide()      end
    if DRAG.dropLine   then DRAG.dropLine:Hide()   end
    if DRAG.catchFrame then DRAG.catchFrame:Hide() end
    DRAG.modKey = nil; DRAG.targetSlot = nil; DRAG.sections = nil
end

local function StartSectionDrag(modKey, labelText)
    if DRAG.active then StopDrag() end
    local sections = {}
    for _, s in ipairs(MR.sectionRegistry or {}) do
        local top = s.frame:GetTop()
        table.insert(sections, { frame = s.frame, modKey = s.modKey, top = top or 0 })
    end
    table.sort(sections, function(a, b) return a.top > b.top end)
    if #sections == 0 then return end
    DRAG.active     = true
    DRAG.modKey     = modKey
    DRAG.sections   = sections
    DRAG.targetSlot = #sections
    if not DRAG.ghost then
        local w = MR.db.profile.width or 260
        local g = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
        g:SetSize(w - 10, HEADER_HEIGHT)
        g:SetFrameStrata("TOOLTIP")
        g:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        g:SetBackdropColor(0.04, 0.25, 0.25, 0.92)
        g:SetBackdropBorderColor(0.2, 0.85, 0.65, 1)
        local fs = g:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT_HEADERS, 10, "OUTLINE")
        fs:SetPoint("LEFT", g, "LEFT", 8, 0)
        fs:SetTextColor(0.2, 0.9, 0.7)
        g.label = fs
        DRAG.ghost = g
    end
    DRAG.ghost.label:SetText(labelText)
    DRAG.ghost:Show()
    if not DRAG.dropLine then
        local dl = CreateFrame("Frame", nil, UIParent)
        dl:SetHeight(2)
        dl:SetFrameStrata("TOOLTIP")
        local t = dl:CreateTexture(nil, "OVERLAY")
        t:SetAllPoints()
        t:SetColorTexture(0.2, 0.9, 0.7, 1)
        DRAG.dropLine = dl
    end
    DRAG.dropLine:Show()
    if not DRAG.catchFrame then
        local cb = CreateFrame("Button", nil, UIParent)
        cb:SetFrameStrata("FULLSCREEN_DIALOG")
        cb:SetAllPoints(UIParent)
        cb:EnableMouse(true)
        cb:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        cb:SetScript("OnClick", function() StopDrag() end)
        cb:SetScript("OnHide",  function() if DRAG.active then StopDrag() end end)
        cb:SetAlpha(0)
        DRAG.catchFrame = cb
    end
    DRAG.catchFrame:Show()
    DRAG.catchFrame:Raise()
end

function MR:BuildUI()
    if self.frame then self.frame:Show() return end

    RecalcLayout()
    local w = MR.db.profile.width or 260

    local f = CreateFrame("Frame", "MidnightRoutineFrame", UIParent, "BackdropTemplate")
    f:SetWidth(w)
    f:SetHeight(40)
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
    titleAccent:SetPoint("TOPLEFT",    titleBar, "TOPLEFT",    0, 0)
    titleAccent:SetPoint("BOTTOMLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    titleAccent:SetWidth(3)
    titleAccent:SetColorTexture(0.16, 0.78, 0.75, 1)

    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_HEADERS, math.max(9, GetFontSize()), "OUTLINE")
    title:SetPoint("LEFT", titleBar, "LEFT", 10, 0)
    title:SetText("|cff2ae7c6Midnight Routine|r")

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
        "Close",
        "Hide Midnight Routine"
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
        "Minimize",
        "Collapse to header bar"
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
            if MR.scroll       then MR.scroll:Hide()       end
            if MR._scrollBg    then MR._scrollBg:Hide()    end
            if MR._scrollTrack then MR._scrollTrack:Hide() end
            f:SetHeight(HEADER_H)
        else
            if MR.scroll       then MR.scroll:Show()       end
            if MR._scrollBg    then MR._scrollBg:Show()    end
            if MR._scrollTrack then MR._scrollTrack:Show() end
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
        { tex = "Interface\\GossipFrame\\DailyActiveQuestIcon" },
        {0.85, 0.65, 0.20},
        {0.18, 0.13, 0.03},
        {0.95, 0.72, 0.18},
        "Options",
        "/mr for chat commands"
    )
    cfgBtn:SetPoint("RIGHT", minBtn, "LEFT", -BTN_PAD, 0)
    cfgBtn:SetScript("OnClick", function() MR:ToggleConfig() end)

    titleCount:SetPoint("RIGHT", cfgBtn, "LEFT", -6, 0)

    local scroll = CreateFrame("ScrollFrame", "MRScrollFrame", f)
    scroll:SetPoint("TOPLEFT",     titleBar, "BOTTOMLEFT",  0,  -1)
    scroll:SetPoint("BOTTOMRIGHT", f,        "BOTTOMRIGHT", -9,  4)
    scroll:EnableMouseWheel(true)
    self.scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth((MR.db.profile.width or 260) - 13)
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

    self:RefreshUI()
    ApplyTheme()
end

function MR:RefreshUI()
    if not self.frame then return end

    RecalcLayout()

    for _, w in ipairs(self.widgets or {}) do
        w:Hide(); w:SetParent(nil)
    end
    self.widgets         = {}
    self.sectionRegistry = {}

    local yOff = 0
    local allDone, allTotal = 0, 0

    for _, mod in ipairs(MR:GetOrderedModules()) do
        local modVisible = not mod.isVisible or mod:isVisible()
        if MR:IsModuleEnabled(mod.key) and modVisible then
            yOff = self:BuildSection(mod, yOff)
            for _, row in ipairs(mod.rows) do
                if MR:IsRowEnabled(mod.key, row.key) then
                    allTotal = allTotal + 1
                    if MR:GetProgress(mod.key, row.key) >= row.max then allDone = allDone + 1 end
                end
            end
        end
    end

    self.titleCount:SetText(string.format("%d / %d", allDone, allTotal))
    self.titleCount:SetTextColor(countColor(allDone, allTotal))

    self.content:SetHeight(math.max(yOff, 1))
    self.frame:SetHeight(math.max(math.min(24 + yOff + 6, 600), 30))

    if self.scroll then
        local maxScroll = math.max(math.max(yOff, 1) - self.scroll:GetHeight(), 0)
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
        self.frame:SetHeight(24)
        if self.UpdateMinimizeVisual then self.UpdateMinimizeVisual() end
    end
end

function MR:BuildSection(mod, yOff)
    local isOpen = MR:IsModuleOpen(mod.key)

    local secDone, secTotal = 0, 0
    for _, row in ipairs(mod.rows) do
        secTotal = secTotal + 1
        if MR:GetProgress(mod.key, row.key) >= row.max then secDone = secDone + 1 end
    end
    local allDone = (secDone == secTotal)

    local hdrFrame = CreateFrame("Frame", nil, self.content)
    hdrFrame:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -yOff)
    hdrFrame:SetSize((MR.db.profile.width or 260) - 13, HEADER_HEIGHT)
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
        local lr,lg,lb = hex(mod.labelColor or "#ffffff")
        accent:SetColorTexture(lr, lg, lb, 1)
    end

    local lbl = hdrFrame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_HEADERS, GetFontSize(), "OUTLINE")
    lbl:SetPoint("LEFT", hdrFrame, "LEFT", 8, 0)
    lbl:SetText(allDone
        and WC("00ff96", mod.label)
        or  WC((mod.labelColor or "#ffffff"):gsub("#",""), mod.label))

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

    local gripTip = hdrFrame:CreateFontString(nil, "OVERLAY")
    gripTip:SetFont(FONT_ROWS, math.max(6, GetFontSize() - 4), "OUTLINE")
    gripTip:SetPoint("LEFT", hdrFrame, "LEFT", 2, 0)
    gripTip:SetText("||")
    gripTip:SetTextColor(0.2, 0.2, 0.25)

    hdrFrame:EnableMouse(true)
    hdrFrame:SetScript("OnMouseDown", function(_, button)
        if button == "RightButton" then
            StartSectionDrag(mod.key, mod.label)
        end
    end)
    hdrFrame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            if DRAG.active then StopDrag() end
        elseif button == "LeftButton" then
            if not DRAG.active then
                MR:SetModuleOpen(mod.key, not MR:IsModuleOpen(mod.key))
                MR:RefreshUI()
            end
        end
    end)
    hdrFrame:SetScript("OnEnter", function()
        hdrHover:SetColorTexture(1, 1, 1, 0.05)
        gripTip:SetTextColor(0.3, 0.8, 0.65)
        GameTooltip:SetOwner(hdrFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(mod.label, 1, 1, 1)
        GameTooltip:AddLine("Left-click: expand/collapse", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Right-click drag: reorder sections", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    hdrFrame:SetScript("OnLeave", function()
        hdrHover:SetColorTexture(1, 1, 1, 0)
        gripTip:SetTextColor(0.2, 0.2, 0.25)
        GameTooltip:Hide()
    end)

    table.insert(self.widgets, hdrFrame)
    table.insert(self.sectionRegistry, { frame = hdrFrame, modKey = mod.key })

    yOff = yOff + HEADER_HEIGHT

    local div = CreateFrame("Frame", nil, self.content, "BackdropTemplate")
    div:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -yOff)
    div:SetSize((MR.db.profile.width or 260) - 13, 1)
    div:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    div:SetBackdropColor(1, 1, 1, 0.06)
    table.insert(self.widgets, div)

    if isOpen then
        for _, row in ipairs(mod.rows) do
            if MR:IsRowEnabled(mod.key, row.key) then
                local done = MR:GetProgress(mod.key, row.key)
                if not (MR.db.profile.hideComplete and not row.noMax and done >= row.max) then
                    yOff = self:BuildRow(mod, row, done, yOff)
                end
            end
        end
    end

    self.sectionRegistry[#self.sectionRegistry].bottom = yOff

    return yOff
end

function MR:BuildRow(mod, row, done, yOff)
    local isAutoTracked = (row.questIds ~= nil) or (row.liveKey ~= nil) or (row.spellTracked == true)
    local isComplete    = not row.noMax and done >= row.max

    local rowFrame = CreateFrame("Frame", nil, self.content)
    rowFrame:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -yOff)
    rowFrame:SetSize((MR.db.profile.width or 260) - 13, ROW_HEIGHT)
    rowFrame:EnableMouse(true)

    local hover = rowFrame:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0)

    rowFrame:SetScript("OnEnter", function()
        hover:SetColorTexture(1, 1, 1, 0.04)
        GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
        GameTooltip:SetText(row.label, 1, 1, 1, 1, true)
        if row.note then GameTooltip:AddLine(row.note, 0.7, 0.7, 0.7, true) end
        if row.liveKey then
            GameTooltip:AddLine("Auto-tracked via Blizzard API", 0.4, 0.8, 1)
        elseif row.questIds then
            GameTooltip:AddLine("Auto-tracked via quest log", 0.4, 1, 0.6)
        elseif row.spellTracked then
            GameTooltip:AddLine("Auto-tracked via item use", 0.9, 0.6, 1)
        else
            GameTooltip:AddLine("Left-click: +1   Right-click: -1", 0.5, 0.5, 0.5)
        end
        if row.resetType then
            GameTooltip:AddLine("Resets: " .. row.resetType, 0.5, 0.5, 0.5)
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

    if row.questIds then
        local star = rowFrame:CreateTexture(nil, "OVERLAY")
        star:SetSize(7, 7)
        star:SetPoint("LEFT", rowFrame, "LEFT", PADDING, 4)
        star:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        star:SetAlpha(0.45)
    elseif row.liveKey then
        local star = rowFrame:CreateTexture(nil, "OVERLAY")
        star:SetSize(7, 7)
        star:SetPoint("LEFT", rowFrame, "LEFT", PADDING, 4)
        star:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        star:SetVertexColor(0.2, 0.6, 1)
        star:SetAlpha(0.55)
    elseif row.spellTracked then
        local star = rowFrame:CreateTexture(nil, "OVERLAY")
        star:SetSize(7, 7)
        star:SetPoint("LEFT", rowFrame, "LEFT", PADDING, 4)
        star:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        star:SetVertexColor(0.8, 0.4, 1)
        star:SetAlpha(0.55)
    end

    local lbl = rowFrame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT_ROWS, GetFontSize(), "OUTLINE")
    lbl:SetPoint("LEFT",  rowFrame, "LEFT",  PADDING + 10, 0)
    lbl:SetPoint("RIGHT", rowFrame, "RIGHT", -52, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(row.label)
    if isComplete then lbl:SetTextColor(0.38, 0.38, 0.38) end

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
    return yOff + ROW_HEIGHT
end

local cfgFrame

function MR:ToggleConfig()
    if cfgFrame and cfgFrame:IsShown() then cfgFrame:Hide() return end
    if not cfgFrame then cfgFrame = self:BuildConfigFrame() end
    self:PopulateConfigFrame(cfgFrame)
    cfgFrame:Show()
end

function MR:BuildConfigFrame()
    local f = CreateFrame("Frame", "MRConfigFrame", UIParent, "BackdropTemplate")
    f:SetWidth(210)
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
    ttitle:SetText("|cffff8000Options|r")
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

    local function Gap(h) yOff = yOff - (h or 4) end

    local function Divider()
        local fr = CreateFrame("Frame", nil, body, "BackdropTemplate")
        fr:SetPoint("TOPLEFT",  body, "TOPLEFT",  4, yOff)
        fr:SetPoint("TOPRIGHT", body, "TOPRIGHT", -4, yOff)
        fr:SetHeight(1)
        fr:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        fr:SetBackdropColor(1, 1, 1, 0.08)
        yOff = yOff - 6
    end

    local function SectionLabel(text)
        local fr = CreateFrame("Frame", nil, body)
        fr:SetPoint("TOPLEFT",  body, "TOPLEFT",  8, yOff)
        fr:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
        fr:SetHeight(14)
        local fs = fr:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT_ROWS, 9, "OUTLINE")
        fs:SetText("|cff888888" .. text .. "|r")
        fs:SetPoint("LEFT", fr)
        fs:SetJustifyH("LEFT")
        yOff = yOff - 16
    end

    local function Checkbox(label, getVal, setVal, color)
        local fr = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
        fr:SetSize(20, 20)
        fr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
        fr:SetChecked(getVal())
        fr:EnableMouse(true)
        fr:SetScript("OnClick", function(s) setVal(s:GetChecked()) end)
        local lbl = fr:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT_ROWS, 10, "OUTLINE")
        lbl:SetText(label)
        if color then lbl:SetTextColor(hex(color)) else lbl:SetTextColor(0.88, 0.88, 0.88) end
        lbl:SetPoint("LEFT", fr, "RIGHT", 0, 0)
        yOff = yOff - 22
    end

    local function Btn(label, onClick)
        local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
        btn:SetSize(192, 20)
        btn:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        btn:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
        btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT_ROWS, 10, "OUTLINE")
        fs:SetPoint("CENTER")
        fs:SetText(label)
        fs:SetTextColor(0.70, 0.88, 0.85)
        btn:SetScript("OnClick", onClick)
        btn:SetScript("OnEnter", function()
            btn:SetBackdropColor(0.08, 0.22, 0.32, 1)
            btn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
            fs:SetTextColor(1, 1, 1)
        end)
        btn:SetScript("OnLeave", function()
            btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
            btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
            fs:SetTextColor(0.70, 0.88, 0.85)
        end)
        yOff = yOff - 26
    end

    SectionLabel("OPTIONS")
    Checkbox("Hide Completed",
        function() return MR.db.profile.hideComplete end,
        function(v) MR.db.profile.hideComplete = v; MR:RefreshUI() end)
    Checkbox("Lock Frame",
        function() return MR.db.profile.locked end,
        function(v)
            MR.db.profile.locked = v
            MR.frame:SetMovable(not v)
        end)
    Checkbox("Transparent Mode",
        function() return MR.db.profile.transparentMode end,
        function(v)
            MR.db.profile.transparentMode = v
            ApplyTheme()
        end)
    Checkbox("Hide Minimap Icon",
        function() return MR.db.profile.minimap and MR.db.profile.minimap.hide or false end,
        function(v) MR:SetMinimapHidden(v) end)

    Gap(6)
    local sliderLabel = body:CreateFontString(nil, "OVERLAY")
    sliderLabel:SetFont(FONT_ROWS, 9, "OUTLINE")
    sliderLabel:SetText("|cff888888WIDTH|r")
    sliderLabel:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    yOff = yOff - 14

    local sliderBg = CreateFrame("Frame", nil, body, "BackdropTemplate")
    sliderBg:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    sliderBg:SetSize(150, 14)
    sliderBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    sliderBg:SetBackdropColor(0, 0, 0, 0.5)
    sliderBg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local sliderFill = sliderBg:CreateTexture(nil, "ARTWORK")
    sliderFill:SetPoint("LEFT", sliderBg, "LEFT", 2, 0)
    sliderFill:SetHeight(10)
    sliderFill:SetColorTexture(0.16, 0.78, 0.75, 0.85)

    local sliderValBox = CreateFrame("Frame", nil, body, "BackdropTemplate")
    sliderValBox:SetPoint("LEFT", sliderBg, "RIGHT", 5, 0)
    sliderValBox:SetSize(38, 14)
    sliderValBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    sliderValBox:SetBackdropColor(0, 0, 0, 0.5)
    sliderValBox:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local sliderValText = sliderValBox:CreateFontString(nil, "OVERLAY")
    sliderValText:SetFont(FONT_ROWS, 9, "OUTLINE")
    sliderValText:SetPoint("CENTER", sliderValBox, "CENTER", 0, 0)

    local slider = CreateFrame("Slider", nil, sliderBg)
    slider:SetAllPoints(sliderBg)
    slider:SetMinMaxValues(PANEL_MIN_WIDTH, PANEL_MAX_WIDTH)
    slider:SetValueStep(10)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local thumb = slider:GetThumbTexture()
    if thumb then thumb:Hide() end

    local function UpdateSliderVisual(w)
        local pct = (w - PANEL_MIN_WIDTH) / (PANEL_MAX_WIDTH - PANEL_MIN_WIDTH)
        sliderFill:SetWidth(math.max(2, (sliderBg:GetWidth() - 4) * pct))
        sliderValText:SetText(w)
    end

    slider:SetValue(MR.db.profile.width or 260)
    UpdateSliderVisual(MR.db.profile.width or 260)

    slider:SetScript("OnValueChanged", function(s, v)
        v = math.floor(v / 10) * 10
        UpdateSliderVisual(v)
    end)
    slider:SetScript("OnMouseUp", function(s)
        ApplyWidth(s:GetValue())
        MR:PopulateConfigFrame(f)
    end)

    yOff = yOff - 18

    Gap(6)
    local fsLabel = body:CreateFontString(nil, "OVERLAY")
    fsLabel:SetFont(FONT_ROWS, 9, "OUTLINE")
    fsLabel:SetText("|cff888888FONT SIZE|r")
    fsLabel:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    yOff = yOff - 14

    local fsBg = CreateFrame("Frame", nil, body, "BackdropTemplate")
    fsBg:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
    fsBg:SetSize(150, 14)
    fsBg:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    fsBg:SetBackdropColor(0, 0, 0, 0.5)
    fsBg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local fsFill = fsBg:CreateTexture(nil, "ARTWORK")
    fsFill:SetPoint("LEFT", fsBg, "LEFT", 2, 0)
    fsFill:SetHeight(10)
    fsFill:SetColorTexture(0.78, 0.55, 0.16, 0.85)

    local fsValBox = CreateFrame("Frame", nil, body, "BackdropTemplate")
    fsValBox:SetPoint("LEFT", fsBg, "RIGHT", 5, 0)
    fsValBox:SetSize(38, 14)
    fsValBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    fsValBox:SetBackdropColor(0, 0, 0, 0.5)
    fsValBox:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local fsValText = fsValBox:CreateFontString(nil, "OVERLAY")
    fsValText:SetFont(FONT_ROWS, 9, "OUTLINE")
    fsValText:SetPoint("CENTER", fsValBox, "CENTER", 0, 0)

    local fsSlider = CreateFrame("Slider", nil, fsBg)
    fsSlider:SetAllPoints(fsBg)
    fsSlider:SetMinMaxValues(FONT_SIZE_MIN, FONT_SIZE_MAX)
    fsSlider:SetValueStep(1)
    fsSlider:SetObeyStepOnDrag(true)
    fsSlider:SetOrientation("HORIZONTAL")
    fsSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local fsThumb = fsSlider:GetThumbTexture()
    if fsThumb then fsThumb:Hide() end

    local function UpdateFsVisual(sz)
        local pct = (sz - FONT_SIZE_MIN) / (FONT_SIZE_MAX - FONT_SIZE_MIN)
        fsFill:SetWidth(math.max(2, (fsBg:GetWidth() - 4) * pct))
        fsValText:SetText(sz)
    end

    local currentFs = GetFontSize()
    fsSlider:SetValue(currentFs)
    UpdateFsVisual(currentFs)

    fsSlider:SetScript("OnValueChanged", function(s, v)
        v = math.floor(v)
        UpdateFsVisual(v)
    end)
    fsSlider:SetScript("OnMouseUp", function(s)
        ApplyFontSize(s:GetValue())
        MR:PopulateConfigFrame(f)
    end)

    local presetRow = CreateFrame("Frame", nil, body)
    presetRow:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff - 18)
    presetRow:SetSize(192, 18)

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

    Gap(4); Divider()
    SectionLabel("MODULES")

    if not MR._cfgExpanded then MR._cfgExpanded = {} end

    for _, mod in ipairs(self.modules) do
        local key = mod.key
        local optVisible = not mod.isVisible or mod:isVisible()

        if mod.profSkillLine then
            if MR.playerProfessions[mod.profSkillLine] then
                local fr = CreateFrame("Frame", nil, body)
                fr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
                fr:SetSize(192, 20)
                local dot = fr:CreateTexture(nil, "ARTWORK")
                dot:SetSize(8, 8)
                dot:SetPoint("LEFT", fr, "LEFT", 6, 0)
                dot:SetColorTexture(0.16, 0.78, 0.75, 1)
                local lbl = fr:CreateFontString(nil, "OVERLAY")
                lbl:SetFont(FONT_ROWS, 10, "OUTLINE")
                lbl:SetPoint("LEFT", fr, "LEFT", 20, 0)
                lbl:SetText(mod.label)
                if mod.labelColor then lbl:SetTextColor(hex(mod.labelColor)) else lbl:SetTextColor(0.88, 0.88, 0.88) end
                local note = fr:CreateFontString(nil, "OVERLAY")
                note:SetFont(FONT_ROWS, 8, "OUTLINE")
                note:SetPoint("RIGHT", fr, "RIGHT", -4, 0)
                note:SetText("auto")
                note:SetTextColor(0.4, 0.4, 0.4)
                yOff = yOff - 22
            end

        elseif optVisible then
            local ROW_H = 22
            local headerFr = CreateFrame("Frame", nil, body)
            headerFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
            headerFr:SetSize(196, ROW_H)

            local cb = CreateFrame("CheckButton", nil, headerFr, "UICheckButtonTemplate")
            cb:SetSize(20, 20)
            cb:SetPoint("LEFT", headerFr, "LEFT", 0, 0)
            cb:SetChecked(MR:IsModuleEnabled(key))
            cb:SetScript("OnClick", function(s)
                MR:SetModuleEnabled(key, s:GetChecked())
            end)

            local lbl = headerFr:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, 10, "OUTLINE")
            lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
            lbl:SetPoint("RIGHT", headerFr, "RIGHT", -20, 0)
            lbl:SetText(mod.label)
            lbl:SetJustifyH("LEFT")
            if mod.labelColor then lbl:SetTextColor(hex(mod.labelColor)) else lbl:SetTextColor(0.88, 0.88, 0.88) end

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
            end)
            arrowBtn:SetScript("OnLeave", function()
                arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                arrowBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
                arrowLbl:SetTextColor(0.45, 0.75, 0.70)
            end)

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
                    if mod.labelColor then
                        rdot:SetColorTexture(hex(mod.labelColor))
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
                        GameTooltip:SetText(enabled and "Click to hide this row" or "Click to show this row", 1, 1, 1)
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
    SectionLabel("RESETS")
    Btn("Simulate Weekly Reset", function()
        MR:DoWeeklyReset()
        MR:PopulateConfigFrame(f)
    end)
    Btn("Reset Everything", function()
        MR.db.char.progress = {}
        MR:ScanQuests()
        MR:PopulateConfigFrame(f)
    end)
    Btn("Reset Section Order", function()
        MR.db.profile.moduleOrder = {}
        MR:RefreshUI()
        MR:PopulateConfigFrame(f)
    end)

    Gap(8)
    local totalH = math.abs(yOff) + 8
    body:SetHeight(totalH)
    f:SetHeight(totalH)
end
