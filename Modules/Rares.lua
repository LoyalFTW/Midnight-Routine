local FONT_HEADERS = MR_FONT_HEADERS
local FONT_ROWS    = MR_FONT_ROWS
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)

local MAP_TO_ZONE_KEY = {
    [2395] = "eversong",
    [2393] = "eversong",
    [2437] = "zulaman",
    [2413] = "harandar",
    [2576] = "harandar",
    [2405] = "voidstorm",
}

local function GetCurrentZoneKey()
    local mapID = C_Map.GetBestMapForUnit("player")
    return mapID and MAP_TO_ZONE_KEY[mapID] or nil
end

local ZONES = {
    {
        key      = "eversong",
        label    = L["Zone_EversongWoods"],
        achievId = 61507,
        color    = { 0.85, 0.72, 0.18 },
        rares = {
            { L["Rare_WardenOfWeeds"],           91280 },
            { L["Rare_OverfesterHydra"],           92392 },
            { L["Rare_Crevan"],                   92391 },
            { L["Rare_LadyLiminus"],              92393 },
            { L["Rare_BadZed"],                   92404 },
            { L["Rare_Banuran"],                   92403 },
            { L["Rare_Duskburn"],                  93550 },
            { L["Rare_DameBloodshed"],            93561 },
            { L["Rare_HarriedHawkstrider"],       91315 },
            { L["Rare_BloatedSnapdragon"],        92366 },
            { L["Rare_Coralfang"],                 92389 },
            { L["Rare_Terrinor"],                  92409 },
            { L["Rare_Waverly"],                   92395 },
            { L["Rare_LostGuardian"],             92399 },
            { L["Rare_MalfunctioningConstruct"],  93555 },
        },
    },
    {
        key      = "zulaman",
        label    = L["Zone_ZulAman"],
        achievId = 62122,
        color    = { 0.82, 0.36, 0.14 },
        rares = {
            { L["Rare_NecrohexxerRazka"],        89569 },
            { L["Rare_SkullcrusherHarak"],        89571 },
            { L["Rare_Mrrlokk"],                   91174 },
            { L["Rare_Spinefrill"],                89578 },
            { L["Rare_TinyVermin"],               89580 },
            { L["Rare_DevouringInvader"],     89583 },
            { L["Rare_DepthbornEelamental"],      89573 },
            { L["Rare_AshanEmpowered"],      91073 },
            { L["Rare_SnappingScourge"],      89570 },
            { L["Rare_LightwoodBorer"],           89575 },
            { L["Rare_PoacherRavik"],            91634 },
            { L["Rare_Oophaga"],                   89579 },
            { L["Rare_VoidtouchedCrustacean"],    89581 },
            { L["Rare_ElderOaktalon"],            89572 },
            { L["Rare_DecayingDiamondback"],  91072 },
        },
    },
    {
        key      = "harandar",
        label    = L["Zone_Harandar"],
        achievId = 61264,
        color    = { 0.16, 0.78, 0.55 },
        rares = {
            { L["Rare_Rhazul"],                    91832 },
            { L["Rare_Hakalawe"],                 92142 },
            { L["Rare_QueenLastongue"],          92154 },
            { L["Rare_Stumpy"],                    92168 },
            { L["Rare_Mindrot"],                   92172 },
            { L["Rare_Treetop"],                   92183 },
            { L["Rare_Pterrock"],                  92191 },
            { L["Rare_AnnulusWorldshaker"],   92194 },
            { L["Rare_Chironex"],                  92137 },
            { L["Rare_TallcapTruthspreader"], 92148 },
            { L["Rare_Chlorokyll"],                92161 },
            { L["Rare_Serrasa"],                   92170 },
            { L["Rare_Dracaena"],                  92176 },
            { L["Rare_Oroohna"],                  92190 },
            { L["Rare_Ahluahuhi"],               92193 },
        },
    },
    {
        key      = "voidstorm",
        label    = L["Zone_Voidstorm"],
        achievId = 62130,
        color    = { 0.55, 0.28, 0.95 },
        rares = {
            { L["Rare_SunderethCaller"],      90805 },
            { L["Rare_Tremora"],                   91048 },
            { L["Rare_BaneVilebloods"],    93946 },
            { L["Rare_LotusDarkblossom"],         93947 },
            { L["Rare_Ravengerus"],                93895 },
            { L["Rare_BilemawGluttonous"],    93884 },
            { L["Rare_Nightbrood"],                91051 },
            { L["Rare_TerritorialVoidscythe"],    91050 },
            { L["Rare_ScreammaxaMatriarch"],  93966 },
            { L["Rare_AeonelleBlackstar"],        93944 },
            { L["Rare_QueenOWar"],              93934 },
            { L["Rare_RakshurBonegrinder"],   93953 },
            { L["Rare_Eruundi"],                   91047 },
            { L["Rare_FarthanaMad"],         93896 },
        },
    },
}

local ZONE_BY_KEY = {}
for _, z in ipairs(ZONES) do ZONE_BY_KEY[z.key] = z end

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

local function GetZoneStatus(zone)
    local db      = MR.db and MR.db.profile or {}
    local numDone = 0
    local status  = {}
    for i, rare in ipairs(zone.rares) do
        local name    = rare[1]
        local questId = rare[2]
        local weekly  = questId and C_QuestLog.IsQuestFlaggedCompleted(questId) or false
        local _, _, _, achieved = GetAchievementCriteriaInfo(zone.achievId, i)
        local ever = achieved == true
        if weekly then numDone = numDone + 1 end
        status[i] = { name = name, weekly = weekly, ever = ever }
    end
    return numDone, #zone.rares, status
end

local OUTER_PAD  = 6
local DEFAULT_W  = 300
local DEFAULT_H  = 360
local MIN_W      = 160
local MAX_W      = 600
local MIN_H      = 60
local MAX_H      = 800
local TITLE_H    = 26
local ZONE_HDR_H = 26
local BAR_H      = 4
local DOT_SIZE   = 7
local COLS       = 2
local ROW_PAD    = 4

local function GetRowH()
    local db = MR.db and MR.db.profile or {}
    local fs = db.raresFontSize or 9
    return math.max(14, fs + 7)
end

local raresFrame
local raresCfgFrame
local collapsed   = {}
local lastZoneKey = nil

local BuildRaresFrame
local RefreshRaresFrame
local PopulateRaresConfig

local function GetVisibleZones()
    local db  = MR.db and MR.db.profile or {}
    local key = GetCurrentZoneKey()
    local function zoneVisible(z)
        return not (db.raresHiddenZones and db.raresHiddenZones[z.key])
    end
    if key and ZONE_BY_KEY[key] and zoneVisible(ZONE_BY_KEY[key]) then
        return { ZONE_BY_KEY[key] }
    end
    local result = {}
    for _, z in ipairs(ZONES) do
        if zoneVisible(z) then result[#result + 1] = z end
    end
    return result
end

local function ContentHeight(visible, W)
    local db    = MR.db and MR.db.profile or {}
    local ROW_H = GetRowH()
    local cols  = (W >= 220) and COLS or 1
    local h     = 0
    local singleZone = #visible == 1
    for _, zone in ipairs(visible) do
        if not singleZone then
            h = h + ZONE_HDR_H + BAR_H
        else
            h = h + BAR_H
        end
        if not collapsed[zone.key] then
            local count = 0
            for _, rare in ipairs(zone.rares) do
                local questId = rare[2]
                local weekly  = questId and C_QuestLog.IsQuestFlaggedCompleted(questId) or false
                if not (db.raresHideKilled and weekly) then count = count + 1 end
            end
            if count > 0 then
                h = h + math.ceil(count / cols) * ROW_H + 10
            end
        end
        h = h + 4
    end
    return h
end

local function RebuildRaresFrame()
    if raresFrame then raresFrame:Hide(); raresFrame = nil end
    if MR.db and MR.db.profile.raresCollapsed then
        for k, v in pairs(MR.db.profile.raresCollapsed) do collapsed[k] = v end
    end
    raresFrame = BuildRaresFrame()
    raresFrame:Show()
    raresFrame:SetScale((MR.db and MR.db.profile.raresScale) or 1.0)
    RefreshRaresFrame()
end

BuildRaresFrame = function()
    local db         = MR.db and MR.db.profile or {}
    local W          = db.raresWidth  or DEFAULT_W
    local H          = db.raresHeight or DEFAULT_H
    local alpha      = math.max(db.raresAlpha or 1.0, 0.3)
    local minimized  = db.raresMinimized or false
    local visible    = GetVisibleZones()
    local singleZone = #visible == 1
    local cols       = (W >= 220) and COLS or 1
    local ROW_H      = GetRowH()

    local f = MR_StyledFrame(UIParent, "MRRaresFrame", "MEDIUM", 10)
    f:SetSize(W, minimized and TITLE_H or H)
    f:SetBackdropColor(0.03, 0.02, 0.09, 0.97 * alpha)
    f:SetBackdropBorderColor(0.18, 0.10, 0.30, alpha)
    MR_RestoreFramePos(f, "raresPos", 580, 0)

    f.leftAccent = MR_LeftAccent(f, 0.55, 0.28, 0.95)
    f.topAccent  = MR_TopAccent(f,  0.55, 0.28, 0.95)
    if f.leftAccent then f.leftAccent:SetAlpha(alpha) end
    if f.topAccent  then f.topAccent:SetAlpha(alpha)  end

    local titleBar = MR_TitleBar(f, TITLE_H)
    f.titleBar = titleBar
    titleBar:SetBackdropColor(0, 0, 0, 0)
    titleBar:SetClipsChildren(true)
    titleBar:SetScript("OnDragStart", function() if not db.raresLocked then f:StartMoving() end end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local pt, _, rp, x, y = f:GetPoint()
        if MR.db then MR.db.profile.raresPos = { point = pt, relPoint = rp, x = x, y = y } end
    end)

    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(14, 14)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    titleIcon:SetTexture("Interface\\AddOns\\MidnightRoutine\\Media\\Icon")
    titleIcon:SetVertexColor(0.65, 0.38, 1.0, 1)

    local closeBtn = MR_CloseButton(titleBar, function()
        f:Hide()
        if raresCfgFrame then raresCfgFrame:Hide() end
        if MR.db then MR.db.profile.raresOpen = false end
    end)

    local gearBtn = CreateFrame("Button", nil, titleBar)
    gearBtn:SetSize(14, 14)
    gearBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
    local gearTex = gearBtn:CreateTexture(nil, "ARTWORK")
    gearTex:SetAllPoints()
    gearTex:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    gearTex:SetVertexColor(0.55, 0.30, 0.90, 1)
    gearBtn:SetNormalTexture(gearTex)
    local gearHL = gearBtn:CreateTexture(nil, "HIGHLIGHT")
    gearHL:SetAllPoints()
    gearHL:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    gearHL:SetVertexColor(1, 1, 1, 1)
    gearBtn:SetHighlightTexture(gearHL)
    gearBtn:SetScript("OnClick",  function() MR:ToggleRaresConfig() end)
    gearBtn:SetScript("OnEnter",  function()
        gearTex:SetVertexColor(0.9, 0.6, 1, 1)
        GameTooltip:SetOwner(gearBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["Rares_OptionsTitle"], 1, 1, 1)
        GameTooltip:Show()
    end)
    gearBtn:SetScript("OnLeave",  function()
        gearTex:SetVertexColor(0.55, 0.30, 0.90, 1)
        GameTooltip:Hide()
    end)

    local minBtn = CreateFrame("Button", nil, titleBar, "BackdropTemplate")
    minBtn:SetSize(16, 16)
    minBtn:SetPoint("RIGHT", gearBtn, "LEFT", -4, 0)
    minBtn:SetBackdrop(MR_MakeBackdrop())
    minBtn:SetBackdropColor(0.06, 0.12, 0.22, 0.85)
    minBtn:SetBackdropBorderColor(0.15, 0.35, 0.40, 0.9)
    local minLbl = minBtn:CreateFontString(nil, "OVERLAY")
    minLbl:SetFont(FONT_HEADERS, 12, "OUTLINE")
    minLbl:SetPoint("CENTER", minBtn, "CENTER", 0, 1)
    minLbl:SetTextColor(0.25, 0.80, 0.68)
    local function UpdateMinBtn()
        minLbl:SetText((MR.db and MR.db.profile.raresMinimized) and "+" or "-")
    end
    UpdateMinBtn()
    minBtn:SetScript("OnEnter", function()
        minBtn:SetBackdropColor(0.06, 0.22, 0.28, 1)
        minBtn:SetBackdropBorderColor(0.20, 0.80, 0.65, 1)
        minLbl:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(minBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["UI_Collapse"], 1, 1, 1)
        GameTooltip:Show()
    end)
    minBtn:SetScript("OnLeave", function()
        minBtn:SetBackdropColor(0.06, 0.12, 0.22, 0.85)
        minBtn:SetBackdropBorderColor(0.15, 0.35, 0.40, 0.9)
        minLbl:SetTextColor(0.25, 0.80, 0.68)
        GameTooltip:Hide()
    end)

    local totalDoneLabel = titleBar:CreateFontString(nil, "OVERLAY")
    totalDoneLabel:SetFont(FONT_ROWS, 9, "OUTLINE")
    totalDoneLabel:SetTextColor(0.45, 0.45, 0.55)
    totalDoneLabel:SetPoint("RIGHT", minBtn, "LEFT", -6, 0)
    totalDoneLabel:SetWordWrap(false)
    f.totalDoneLabel = totalDoneLabel

    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY")
    titleTxt:SetFont(FONT_HEADERS, 10, "OUTLINE")
    titleTxt:SetPoint("LEFT",  titleIcon, "RIGHT", 5, 0)
    titleTxt:SetPoint("RIGHT", totalDoneLabel, "LEFT", -6, 0)
    titleTxt:SetJustifyH("LEFT")
    titleTxt:SetWordWrap(false)
    if singleZone then
        local cr, cg, cb = GetZoneColor(visible[1])
        local hex = string.format("%02x%02x%02x",
            math.floor(cr*255), math.floor(cg*255), math.floor(cb*255))
        titleTxt:SetText(string.format(
            "|cffaa66ffRares|r  |cff333344-|r  |cff%s%s|r", hex, visible[1].label))
    else
        titleTxt:SetText(L["Rares_Title"])
    end

    local function ApplyMinimized(isMin)
        if MR.db then MR.db.profile.raresMinimized = isMin end
        UpdateMinBtn()
        if isMin then
            if f._scroll      then f._scroll:Hide()   end
            if f._dragger     then f._dragger:Hide()   end
            local left = f:GetLeft()
            local top  = f:GetTop()
            if left and top then
                f:ClearAllPoints()
                f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
                if MR.db then MR.db.profile.raresPos = { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = left, y = top } end
            end
            f:SetHeight(TITLE_H)
        else
            if f._scroll  then f._scroll:Show()  end
            if f._dragger then f._dragger:Show()  end
            f:SetHeight(MR.db and MR.db.profile.raresHeight or DEFAULT_H)
        end
    end
    f.ApplyMinimized = ApplyMinimized

    minBtn:SetScript("OnClick", function()
        local isMin = not (MR.db and MR.db.profile.raresMinimized)
        ApplyMinimized(isMin)
    end)

    local scroll = CreateFrame("ScrollFrame", nil, f)
    scroll:SetPoint("TOPLEFT",     titleBar, "BOTTOMLEFT",  0, -1)
    scroll:SetPoint("BOTTOMRIGHT", f,        "BOTTOMRIGHT", -8, 4)
    scroll:EnableMouseWheel(true)
    f._scroll = scroll

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(W - 8)
    content:SetHeight(1)
    scroll:SetScrollChild(content)
    f._content = content

    local track = CreateFrame("Frame", nil, f)
    track:SetPoint("TOPLEFT",    scroll, "TOPRIGHT",    1, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    track:SetWidth(5)
    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    trackBg:SetColorTexture(0, 0, 0, 0.3)
    local thumb = track:CreateTexture(nil, "OVERLAY")
    thumb:SetWidth(5)
    thumb:SetColorTexture(0.55, 0.28, 0.95, 0.6)
    f._track = track
    f._thumb = thumb

    local function UpdateScrollBar()
        local viewH    = scroll:GetHeight()
        local contentH = content:GetHeight()
        if contentH <= viewH or viewH <= 0 then thumb:Hide(); return end
        thumb:Show()
        local trackH = math.max(track:GetHeight(), 1)
        local thumbH = math.max(trackH * (viewH / contentH), 14)
        local pct    = scroll:GetVerticalScroll() / math.max(contentH - viewH, 1)
        thumb:SetHeight(thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -((trackH - thumbH) * pct))
    end
    scroll:SetScript("OnMouseWheel",        function(_, d) scroll:SetVerticalScroll(math.max(0, math.min(scroll:GetVerticalScroll() - d * 30, math.max(content:GetHeight() - scroll:GetHeight(), 0)))); UpdateScrollBar() end)
    scroll:SetScript("OnScrollRangeChanged", function() UpdateScrollBar() end)
    scroll:SetScript("OnVerticalScroll",     function() UpdateScrollBar() end)
    f.UpdateScrollBar = UpdateScrollBar

    f.shimmerElapsed  = 0
    f.shimmerTextures = {}
    if db.raresShimmer then
        f:SetScript("OnUpdate", function(self, dt)
            self.shimmerElapsed = self.shimmerElapsed + dt
            local pulse = 0.06 + 0.04 * math.sin(self.shimmerElapsed * 2)
            for _, tex in ipairs(self.shimmerTextures) do tex:SetAlpha(pulse) end
        end)
    end

    f.zoneData = {}
    local yOff = 2
    local innerW = W - 8 - (OUTER_PAD * 2)
    local colW   = innerW / cols

    for _, zone in ipairs(visible) do
        local cr, cg, cb  = GetZoneColor(zone)
        local isCollapsed = (not singleZone) and collapsed[zone.key]

        local zCount
        if not singleZone then
            local zHdr = CreateFrame("Button", nil, content, "BackdropTemplate")
            zHdr:SetPoint("TOPLEFT",  content, "TOPLEFT",  OUTER_PAD, -yOff)
            zHdr:SetPoint("TOPRIGHT", content, "TOPRIGHT", -OUTER_PAD, -yOff)
            zHdr:SetHeight(ZONE_HDR_H)
            zHdr:SetBackdrop(MR_MakeBackdrop())
            zHdr:SetBackdropColor(cr*0.10, cg*0.10, cb*0.10, 0.98 * alpha)
            zHdr:SetBackdropBorderColor(cr*0.45, cg*0.45, cb*0.45, alpha)

            local stripe = zHdr:CreateTexture(nil, "ARTWORK")
            stripe:SetPoint("TOPLEFT",    zHdr, "TOPLEFT",    0, 0)
            stripe:SetPoint("BOTTOMLEFT", zHdr, "BOTTOMLEFT", 0, 0)
            stripe:SetWidth(3)
            stripe:SetColorTexture(cr, cg, cb, 1)

            local arrow = zHdr:CreateFontString(nil, "OVERLAY")
            arrow:SetFont(FONT_ROWS, 9, "OUTLINE")
            arrow:SetPoint("LEFT", zHdr, "LEFT", 10, 1)
            arrow:SetText(isCollapsed and "|cff555555+|r" or "|cff777777-|r")

            local zName = zHdr:CreateFontString(nil, "OVERLAY")
            zName:SetFont(FONT_HEADERS, 10, "OUTLINE")
            zName:SetPoint("LEFT", arrow, "RIGHT", 5, 0)
            zName:SetTextColor(cr, cg, cb)
            zName:SetText(zone.label)

            zCount = zHdr:CreateFontString(nil, "OVERLAY")
            zCount:SetFont(FONT_ROWS, 9, "OUTLINE")
            zCount:SetPoint("RIGHT", zHdr, "RIGHT", -8, 0)
            zCount:SetTextColor(0.5, 0.5, 0.5)

            yOff = yOff + ZONE_HDR_H

            zHdr:SetScript("OnClick", function()
                collapsed[zone.key] = not collapsed[zone.key]
                if MR.db then
                    if not MR.db.profile.raresCollapsed then MR.db.profile.raresCollapsed = {} end
                    MR.db.profile.raresCollapsed[zone.key] = collapsed[zone.key]
                end
                RebuildRaresFrame()
            end)
            zHdr:SetScript("OnEnter", function()
                zHdr:SetBackdropColor(cr*0.18, cg*0.18, cb*0.18, 0.98)
                zHdr:SetBackdropBorderColor(cr*0.75, cg*0.75, cb*0.75, 1)
            end)
            zHdr:SetScript("OnLeave", function()
                zHdr:SetBackdropColor(cr*0.10, cg*0.10, cb*0.10, 0.98 * alpha)
                zHdr:SetBackdropBorderColor(cr*0.45, cg*0.45, cb*0.45, alpha)
            end)
        end

        local barBg = CreateFrame("Frame", nil, content, "BackdropTemplate")
        barBg:SetPoint("TOPLEFT",  content, "TOPLEFT",  OUTER_PAD,  -yOff)
        barBg:SetPoint("TOPRIGHT", content, "TOPRIGHT", -OUTER_PAD, -yOff)
        barBg:SetHeight(BAR_H)
        barBg:SetBackdrop(MR_MakeBackdrop(false))
        barBg:SetBackdropColor(0.04, 0.04, 0.04, alpha)

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
        for _, rare in ipairs(zone.rares) do
            local questId = rare[2]
            local weekly  = questId and C_QuestLog.IsQuestFlaggedCompleted(questId) or false
            if not (db.raresHideKilled and weekly) then
                visibleRares[#visibleRares + 1] = rare
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
        body:SetBackdrop(MR_MakeBackdrop())
        body:SetBackdropColor(cr*0.04, cg*0.04, cb*0.04, 0.85 * alpha)
        body:SetBackdropBorderColor(cr*0.20, cg*0.20, cb*0.20, 0.65 * alpha)
        if isCollapsed then body:Hide() end

        body.dotList      = {}
        body.nameLbls     = {}
        body.visibleRares = visibleRares

        for i, rare in ipairs(visibleRares) do
            local col  = (i - 1) % cols
            local row  = math.floor((i - 1) / cols)
            local xPos = ROW_PAD + col * colW
            local yPos = -(row * ROW_H) - 5

            local dot = body:CreateTexture(nil, "ARTWORK")
            dot:SetSize(DOT_SIZE, DOT_SIZE)
            dot:SetPoint("TOPLEFT", body, "TOPLEFT", xPos + 2, yPos - (ROW_H - DOT_SIZE) * 0.5)
            dot:SetColorTexture(0.28, 0.28, 0.28, 1)

            local lbl = body:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, db.raresFontSize or 9, "OUTLINE")
            lbl:SetPoint("TOPLEFT", body, "TOPLEFT", xPos + DOT_SIZE + 5, yPos)
            lbl:SetWidth(colW - DOT_SIZE - 10)
            lbl:SetHeight(ROW_H)
            lbl:SetJustifyH("LEFT")
            lbl:SetJustifyV("MIDDLE")
            lbl:SetText(rare[1])
            lbl:SetTextColor(0.58, 0.58, 0.58)

            body.dotList[i]  = dot
            body.nameLbls[i] = lbl
        end

        f.zoneData[zone.key] = {
            zone    = zone,
            zCount  = zCount,
            barFill = barFill,
            barBg   = barBg,
            body    = body,
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
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not db.raresLocked then
            dragStartW  = f:GetWidth()
            dragStartH  = f:GetHeight()
            local scale = f:GetEffectiveScale()
            dragStartX, dragStartY = GetCursorPosition()
            dragStartX = dragStartX / scale
            dragStartY = dragStartY / scale
            dragger._dragging = true
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            local newW = math.max(MIN_W, math.min(MAX_W, math.floor(f:GetWidth())))
            local newH = math.max(MIN_H, math.min(MAX_H, math.floor(f:GetHeight())))
            if MR.db then
                MR.db.profile.raresWidth  = newW
                MR.db.profile.raresHeight = newH
            end
            RebuildRaresFrame()
            if raresCfgFrame and raresCfgFrame:IsShown() then
                PopulateRaresConfig(raresCfgFrame)
            end
        end
    end)
    dragger:SetScript("OnUpdate", function()
        if not dragger._dragging then return end
        local cx, cy = GetCursorPosition()
        local scale  = f:GetEffectiveScale()
        cx = cx / scale;  cy = cy / scale
        f:SetWidth( math.max(MIN_W, math.min(MAX_W, dragStartW + (cx - dragStartX))))
        f:SetHeight(math.max(MIN_H, math.min(MAX_H, dragStartH + (dragStartY - cy))))
    end)

    if minimized then
        scroll:Hide()
        dragger:Hide()
        f:SetHeight(TITLE_H)
    end

    f:SetMovable(not db.raresLocked)
    f:Hide()
    return f
end

RefreshRaresFrame = function()
    if not raresFrame or not raresFrame:IsShown() then return end

    local grandDone  = 0
    local grandTotal = 0

    for _, zone in ipairs(ZONES) do
        local zd = raresFrame.zoneData and raresFrame.zoneData[zone.key]
        if zd then
            local numDone, numTotal, status = GetZoneStatus(zone)
            grandDone  = grandDone  + numDone
            grandTotal = grandTotal + numTotal
            local cr, cg, cb = GetZoneColor(zone)

            local cc
            if numDone >= numTotal then cc = "e8c830"
            elseif numDone > 0     then cc = "e07030"
            else                        cc = "555566" end

            if zd.zCount then
                zd.zCount:SetText(string.format(
                    "|cff%s%d|r |cff333344/|r |cff666688%d|r", cc, numDone, numTotal))
            end

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
                    local dot = body.dotList[i]
                    local lbl = body.nameLbls[i]
                    if dot and lbl then
                        local questId = rare[2]
                        local weekly  = questId and C_QuestLog.IsQuestFlaggedCompleted(questId) or false
                        local ever    = false
                        for _, s in ipairs(status) do
                            if s.name == rare[1] then ever = s.ever; break end
                        end
                        if weekly then
                            dot:SetColorTexture(0.12, 0.88, 0.50, 1)
                            lbl:SetTextColor(0.30, 0.72, 0.40)
                        elseif ever then
                            dot:SetColorTexture(0.88, 0.70, 0.12, 1)
                            lbl:SetTextColor(0.75, 0.60, 0.20)
                        else
                            dot:SetColorTexture(0.28, 0.28, 0.28, 1)
                            lbl:SetTextColor(0.58, 0.58, 0.58)
                        end
                    end
                end
            end
        end
    end

    if raresFrame.totalDoneLabel then
        local gc = grandDone >= grandTotal and "00e882" or "555566"
        raresFrame.totalDoneLabel:SetText(
            string.format("|cff%s%d|r |cff333344/%d|r", gc, grandDone, grandTotal))
    end

    if raresFrame.UpdateScrollBar then raresFrame.UpdateScrollBar() end
end

local function BuildRaresConfigFrame()
    local f = CreateFrame("Frame", "MRRaresConfigFrame", UIParent, "BackdropTemplate")
    f:SetWidth(224)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(20)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop(MR_MakeBackdrop())
    f:SetBackdropColor(0.03, 0.02, 0.10, 0.98)
    f:SetBackdropBorderColor(0.30, 0.16, 0.55, 1)
    f:Hide()

    MR_TopAccent(f, 0.55, 0.28, 0.95)

    local tbar = MR_TitleBar(f, 22)
    tbar:SetBackdropColor(0.07, 0.04, 0.14, 1)
    tbar:SetScript("OnDragStart", function() f:StartMoving() end)
    tbar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(MR_FONT_HEADERS, 10, "OUTLINE")
    ttitle:SetText(L["Rares_Config_Title"])
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)

    MR_CloseButton(tbar, function() f:Hide() end)
    f.body = nil
    return f
end

PopulateRaresConfig = function(f)
    if f.body then
        f.body:EnableMouse(false)
        f.body:Hide()
        f.body:SetParent(UIParent)
        f.body = nil
    end

    local body = CreateFrame("Frame", nil, f)
    body:SetPoint("TOPLEFT",  f, "TOPLEFT",  0, 0)
    body:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.body = body

    local db   = MR.db.profile
    local yOff = -28
    local P    = 8

    local function Gap(h)      yOff = MR_OptionsGap(body, yOff, h) end
    local function Divider()   yOff = MR_OptionsDivider(body, yOff, P) end
    local function SecLabel(t) yOff = MR_OptionsSectionLabel(body, yOff, t, P) end
    local function Check(lbl, get, set, r, g, b)
        yOff = MR_OptionsCheckbox(body, yOff, lbl, get, set,
            r or 0.78, g or 0.78, b or 0.88, P,
            function() PopulateRaresConfig(f) end)
    end
    local function Slider(lbl, mn, mx, st, get, set, r, g, b)
        yOff = MR_OptionsSlider(body, yOff, lbl, mn, mx, st, get, set, r, g, b, P)
    end
    local function Btn(lbl, fn) yOff = MR_OptionsBtn(body, yOff, lbl, fn, 184, P) end

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
                if v then
                    raresFrame:SetScript("OnUpdate", function(self, dt)
                        self.shimmerElapsed = (self.shimmerElapsed or 0) + dt
                        local pulse = 0.06 + 0.04 * math.sin(self.shimmerElapsed * 2)
                        if self.shimmerTextures then
                            for _, tex in ipairs(self.shimmerTextures) do tex:SetAlpha(pulse) end
                        end
                    end)
                else
                    raresFrame:SetScript("OnUpdate", nil)
                    if raresFrame.shimmerTextures then
                        for _, tex in ipairs(raresFrame.shimmerTextures) do tex:SetAlpha(0) end
                    end
                end
            end
        end)
    Check(L["Config_HideKilled"],
        function() return db.raresHideKilled end,
        function(v) db.raresHideKilled = v; RebuildRaresFrame() end)

    Gap(4); Divider()
    SecLabel(L["Config_SizeOpacity"])
    Slider(L["WIDTH"], MIN_W, MAX_W, 10,
        function() return db.raresWidth or DEFAULT_W end,
        function(v)
            db.raresWidth = math.floor(v / 10) * 10
            RebuildRaresFrame()
        end,
        0.55, 0.28, 0.95)
    Slider(L["HEIGHT"], MIN_H, MAX_H, 10,
        function() return db.raresHeight or DEFAULT_H end,
        function(v)
            db.raresHeight = math.floor(v / 10) * 10
            if raresFrame and not db.raresMinimized then
                raresFrame:SetHeight(db.raresHeight)
            end
        end,
        0.16, 0.75, 0.78)
    Slider(L["Config_FontSize"], 7, 16, 1,
        function() return db.raresFontSize or 9 end,
        function(v) db.raresFontSize = math.floor(v); RebuildRaresFrame() end,
        0.78, 0.55, 0.16)

    do
        local presets = { {"S", 8}, {"M", 9}, {"L", 11}, {"XL", 13} }
        local btnW    = 42
        for i, p in ipairs(presets) do
            local isActive = ((db.raresFontSize or 9) == p[2])
            local pb = CreateFrame("Button", nil, body, "BackdropTemplate")
            pb:SetSize(btnW - 2, 16)
            pb:SetPoint("TOPLEFT", body, "TOPLEFT", P + (i-1) * btnW, yOff - 2)
            pb:SetBackdrop(MR_MakeBackdrop())
            pb:SetBackdropColor(isActive and 0.12 or 0.05, isActive and 0.35 or 0.10, isActive and 0.32 or 0.18, 1)
            pb:SetBackdropBorderColor(isActive and 0.25 or 0.18, isActive and 0.85 or 0.40, isActive and 0.70 or 0.45, 1)
            local pfs = pb:CreateFontString(nil, "OVERLAY")
            pfs:SetFont(FONT_ROWS, 9, "OUTLINE")
            pfs:SetPoint("CENTER")
            pfs:SetText(p[1])
            pfs:SetTextColor(isActive and 0.2 or 0.6, isActive and 0.95 or 0.75, isActive and 0.75 or 0.65)
            pb:SetScript("OnClick", function()
                db.raresFontSize = p[2]
                RebuildRaresFrame()
                PopulateRaresConfig(f)
            end)
            pb:SetScript("OnEnter", function() pb:SetBackdropColor(0.10, 0.28, 0.28, 1); pb:SetBackdropBorderColor(0.25, 0.90, 0.75, 1) end)
            pb:SetScript("OnLeave", function()
                pb:SetBackdropColor(isActive and 0.12 or 0.05, isActive and 0.35 or 0.10, isActive and 0.32 or 0.18, 1)
                pb:SetBackdropBorderColor(isActive and 0.25 or 0.18, isActive and 0.85 or 0.40, isActive and 0.70 or 0.45, 1)
            end)
        end
        yOff = yOff - 22
    end

    Slider(L["BACKGROUND"], 0, 1, 0.05,
        function() return db.raresAlpha or 1.0 end,
        function(v)
            db.raresAlpha = v
            if raresFrame then
                raresFrame:SetBackdropColor(0.03, 0.02, 0.09, 0.97 * v)
                raresFrame:SetBackdropBorderColor(0.18, 0.10, 0.30, v)
                if raresFrame.leftAccent then raresFrame.leftAccent:SetAlpha(v) end
                if raresFrame.topAccent  then raresFrame.topAccent:SetAlpha(v)  end
                if raresFrame.zoneData then
                    for _, zd in pairs(raresFrame.zoneData) do
                        local zone = zd.zone
                        local cr, cg, cb = GetZoneColor(zone)
                        zd.barBg:SetBackdropColor(0.04, 0.04, 0.04, v)
                        zd.body:SetBackdropColor(cr*0.04, cg*0.04, cb*0.04, 0.85 * v)
                        zd.body:SetBackdropBorderColor(cr*0.20, cg*0.20, cb*0.20, 0.65 * v)
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
        0.45, 0.22, 0.82)

    Gap(4); Divider()
    SecLabel(L["Config_ZoneSettings"])

    for _, zone in ipairs(ZONES) do
        local cr, cg, cb = GetZoneColor(zone)
        local ROW_H2 = 22
        local rowFr  = CreateFrame("Frame", nil, body)
        rowFr:SetPoint("TOPLEFT",  body, "TOPLEFT",  P,  yOff)
        rowFr:SetPoint("TOPRIGHT", body, "TOPRIGHT", -P, yOff)
        rowFr:SetHeight(ROW_H2)

        local nameLbl
        local swatch = MR_OptionsColorSwatch(rowFr, cr, cg, cb,
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
        nameLbl:SetFont(MR_FONT_ROWS, 10, "OUTLINE")
        nameLbl:SetPoint("LEFT",  rowFr,  "LEFT",  0,  0)
        nameLbl:SetPoint("RIGHT", swatch, "LEFT", -4,  0)
        nameLbl:SetText(zone.label)
        nameLbl:SetTextColor(cr, cg, cb)
        nameLbl:SetJustifyH("LEFT")

        yOff = yOff - (ROW_H2 + 2)
    end

    Gap(4); Divider()
    SecLabel(L["RESETS"])
    Btn(L["Config_ResetColors"], function()
        db.raresColors = {}
        RebuildRaresFrame()
        PopulateRaresConfig(f)
    end)

    local totalH = math.abs(yOff) + 10
    f:SetHeight(totalH)
    body:SetHeight(totalH)
end

function MR:ToggleRaresConfig()
    if not raresCfgFrame then
        raresCfgFrame = BuildRaresConfigFrame()
    end
    if raresCfgFrame:IsShown() then
        raresCfgFrame:Hide()
        return
    end
    if raresFrame and raresFrame:IsShown() then
        raresCfgFrame:SetPoint("TOPLEFT", raresFrame, "TOPRIGHT", 4, 0)
    elseif MR.frame then
        raresCfgFrame:SetPoint("TOPLEFT", MR.frame, "TOPRIGHT", 4, 0)
    else
        raresCfgFrame:SetPoint("CENTER")
    end
    PopulateRaresConfig(raresCfgFrame)
    raresCfgFrame:Show()
end

function MR:ToggleRares()
    if MR.db and MR.db.profile.raresCollapsed then
        for k, v in pairs(MR.db.profile.raresCollapsed) do collapsed[k] = v end
    end

    if not raresFrame then
        raresFrame = BuildRaresFrame()
    end
    if raresFrame:IsShown() then
        self:HideRares()
    else
        raresFrame:Show()
        if self.db then self.db.profile.raresOpen = true end
        raresFrame:SetScale((MR.db and MR.db.profile.raresScale) or 1.0)
        lastZoneKey = GetCurrentZoneKey()
        RefreshRaresFrame()
    end
end

function MR:HideRares(persistState)
    if raresFrame then raresFrame:Hide() end
    if raresCfgFrame then raresCfgFrame:Hide() end
    if persistState ~= false and self.db then
        self.db.profile.raresOpen = false
    end
end

function MR:EnsureRaresShown()
    if MR.db and MR.db.profile.raresCollapsed then
        for k, v in pairs(MR.db.profile.raresCollapsed) do collapsed[k] = v end
    end
    if raresFrame and raresFrame:IsShown() then

        RebuildRaresFrame()
    else

        if raresFrame then raresFrame:Hide(); raresFrame = nil end
        raresFrame = BuildRaresFrame()
        raresFrame:Show()
        raresFrame:SetScale((MR.db and MR.db.profile.raresScale) or 1.0)
        lastZoneKey = GetCurrentZoneKey()
        RefreshRaresFrame()
        if self.db then self.db.profile.raresOpen = true end
    end
end

function MR:OnRaresZoneChanged()
    if not raresFrame or not raresFrame:IsShown() then return end
    local newKey = GetCurrentZoneKey()
    if newKey == lastZoneKey then return end
    lastZoneKey = newKey
    RebuildRaresFrame()
end

function MR:RefreshRares()
    RefreshRaresFrame()
end