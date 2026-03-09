local FONT_HEADERS = MR_FONT_HEADERS
local FONT_ROWS    = MR_FONT_ROWS
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)

local gatheringLocationsFrame
local gatheringMinimized = false

local DEFAULT_W = 350
local DEFAULT_H = 450
local MIN_W = 250
local MAX_W = 700
local MIN_H = 150
local MAX_H = 800
local TITLE_H = 24
local OUTER_PAD = 6

local PROFESSIONS = {
    {
        key        = "tailoring",
        label      = L["Tailoring"],
        color      = { 1.0, 0.67, 0.87 },
        hex        = "ffaadd",
        skillLine  = 2918,
        items = {
            { zone = 2393, x = 35.8, y = 61.2, itemID = 238613, questID = 89079 }, -- A Really Nice Curtain
            { zone = 2393, x = 31.7, y = 68.2, itemID = 238618, questID = 89084 }, -- Particularly Enchanting Tablecloth
            { zone = 2395, x = 46.3, y = 34.8, itemID = 238614, questID = 89080 }, -- Sin'dorei Outfitter's Ruler
            { zone = 2437, x = 40.4, y = 49.4, itemID = 238619, questID = 89085 }, -- Artisan's Cover Comb
            { zone = 2413, x = 70.5, y = 50.8, itemID = 238612, questID = 89078 }, -- A Child's Stuffy
            { zone = 2413, x = 69.8, y = 51.0, itemID = 238615, questID = 89081 }, -- Wooden Weaving Sword
            { zone = 2444, x = 61.9, y = 83.7, itemID = 238616, questID = 89082 }, -- Book of Sin'dorei Stitches
            { zone = 2444, x = 61.4, y = 85.0, itemID = 238617, questID = 89083 }, -- Satin Throw Pillow
        },
    },
    {
        key        = "alchemy",
        label      = L["Alchemy"],
        color      = { 0.2, 0.73, 1.0 },
        hex        = "33bbff",
        skillLine  = 2906,
        items = {
            { zone = 2393, x = 47.8, y = 51.6, itemID = 238538, questID = 89117 }, -- Pristine Potion
            { zone = 2393, x = 49.1, y = 75.6, itemID = 238536, questID = 89115 }, -- Freshly Plucked Peacebloom
            { zone = 2393, x = 45.1, y = 44.8, itemID = 238532, questID = 89111 }, -- Vial of Eversong Oddities
            { zone = 2437, x = 40.4, y = 51.0, itemID = 238535, questID = 89114 }, -- Vial of Zul'Aman Oddities
            { zone = 2536, x = 49.1, y = 23.1, itemID = 238537, questID = 89116 }, -- Measured Ladle
            { zone = 2413, x = 34.7, y = 24.7, itemID = 238534, questID = 89113 }, -- Vial of Rootlands Oddities
            { zone = 2444, x = 41.8, y = 40.5, itemID = 238533, questID = 89112 }, -- Vial of Voidstorm Oddities
            { zone = 2405, x = 32.8, y = 43.3, itemID = 238539, questID = 89118 }, -- Failed Experiment
        },
    },
    {
        key        = "blacksmithing",
        label      = L["Blacksmithing"],
        color      = { 0.67, 0.67, 0.73 },
        hex        = "aaaaaa",
        skillLine  = 2907,
        items = {
            { zone = 2393, x = 49.3, y = 61.3, itemID = 238546, questID = 89183 }, -- Sin'dorei Master's Forgemace
            { zone = 2393, x = 48.5, y = 74.8, itemID = 238547, questID = 89184 }, -- Silvermoon Blacksmith's Hammer
            { zone = 2393, x = 26.9, y = 60.3, itemID = 238540, questID = 89177 }, -- Deconstructed Forge Techniques
            { zone = 2395, x = 56.8, y = 40.7, itemID = 238543, questID = 89180 }, -- Metalworking Cheat Sheet
            { zone = 2395, x = 48.3, y = 75.7, itemID = 238541, questID = 89178 }, -- Silvermoon Smithing Kit
            { zone = 2536, x = 33.2, y = 65.8, itemID = 238542, questID = 89179 }, -- Carefully Racked Spear
            { zone = 2413, x = 66.3, y = 50.8, itemID = 238545, questID = 89182 }, -- Rutaani Floratender's Sword
            { zone = 2444, x = 30.6, y = 68.9, itemID = 238544, questID = 89181 }, -- Voidstorm Defense Spear
        },
    },
    {
        key        = "enchanting",
        label      = L["Enchanting"],
        color      = { 0.73, 0.47, 1.0 },
        hex        = "bb77ff",
        skillLine  = 2909,
        items = {
            { zone = 2395, x = 63.4, y = 32.6, itemID = 238555, questID = 89107 }, -- Sin'dorei Enchanting Rod
            { zone = 2395, x = 60.8, y = 53.1, itemID = 238551, questID = 89103 }, -- Everblazing Sunmote
            { zone = 2395, x = 40.2, y = 61.2, itemID = 238549, questID = 89101 }, -- Enchanted Sunfire Silk
            { zone = 2437, x = 40.4, y = 51.2, itemID = 238554, questID = 89106 }, -- Loa-Blessed Dust
            { zone = 2536, x = 49.1, y = 22.7, itemID = 238548, questID = 89100 }, -- Enchanted Amani Mask
            { zone = 2413, x = 65.8, y = 50.2, itemID = 238553, questID = 89105 }, -- Primal Essence Orb
            { zone = 2413, x = 37.7, y = 65.3, itemID = 238552, questID = 89104 }, -- Entropic Shard
            { zone = 2405, x = 35.5, y = 58.8, itemID = 238550, questID = 89102 }, -- Pure Void Crystal
        },
    },
    {
        key        = "engineering",
        label      = L["Engineering"],
        color      = { 1.0, 0.8, 0.27 },
        hex        = "ffcc44",
        skillLine  = 2910,
        items = {
            { zone = 2393, x = 51.2, y = 57.1, itemID = 238562, questID = 89139 }, -- What To Do When Nothing Works
            { zone = 2393, x = 51.4, y = 74.6, itemID = 238556, questID = 89133 }, -- One Engineer's Junk
            { zone = 2395, x = 39.5, y = 45.8, itemID = 238558, questID = 89135 }, -- Manual of Mistakes and Mishaps
            { zone = 2536, x = 65.1, y = 34.5, itemID = 238561, questID = 89138 }, -- Offline Helper Bot
            { zone = 2437, x = 34.2, y = 87.9, itemID = 238563, questID = 89140 }, -- Handy Wrench
            { zone = 2413, x = 67.9, y = 49.8, itemID = 238559, questID = 89136 }, -- Expeditious Pylon
            { zone = 2444, x = 54.0, y = 51.0, itemID = 238560, questID = 89137 }, -- Ethereal Stormwrench
            { zone = 2444, x = 29.0, y = 39.2, itemID = 238557, questID = 89134 }, -- Miniaturized Transport Skiff
        },
    },
    {
        key        = "inscription",
        label      = L["Inscription"],
        color      = { 0.27, 0.87, 0.67 },
        hex        = "44ddaa",
        skillLine  = 2913,
        items = {
            { zone = 2393, x = 47.7, y = 50.3, itemID = 238578, questID = 89073 }, -- Songwriter's Pen
            { zone = 2395, x = 40.4, y = 61.3, itemID = 238579, questID = 89074 }, -- Songwriter's Quill
            { zone = 2395, x = 39.3, y = 45.4, itemID = 238577, questID = 89072 }, -- Half-Baked Techniques
            { zone = 2395, x = 48.3, y = 75.6, itemID = 238574, questID = 89069 }, -- Spare Ink
            { zone = 2437, x = 40.5, y = 49.4, itemID = 238573, questID = 89068 }, -- Leather-Bound Techniques
            { zone = 2413, x = 52.7, y = 50.0, itemID = 238576, questID = 89070 }, -- Leftover Sanguithorn Pigment
            { zone = 2413, x = 52.4, y = 52.6, itemID = 238575, questID = 89071 }, -- Intrepid Explorer's Marker
            { zone = 2444, x = 60.7, y = 84.1, itemID = 238572, questID = 89067 }, -- Void-Touched Quill
        },
    },
    {
        key        = "jewelcrafting",
        label      = L["Jewelcrafting"],
        color      = { 1.0, 0.47, 0.60 },
        hex        = "ff7799",
        skillLine  = 2914,
        items = {
            { zone = 2393, x = 50.6, y = 56.5, itemID = 238580, questID = 89122 }, -- Sin'dorei Masterwork Chisel
            { zone = 2393, x = 55.5, y = 48.0, itemID = 238585, questID = 89127 }, -- Vintage Soul Gem
            { zone = 2393, x = 28.6, y = 46.5, itemID = 238582, questID = 89124 }, -- Dual-Function Magnifiers
            { zone = 2395, x = 56.7, y = 40.9, itemID = 238583, questID = 89125 }, -- Poorly Rounded Vial
            { zone = 2395, x = 39.7, y = 38.8, itemID = 238587, questID = 89129 }, -- Sin'dorei Gem Faceters
            { zone = 2405, x = 30.6, y = 69.0, itemID = 238581, questID = 89123 }, -- Speculative Voidstorm Crystal
            { zone = 2444, x = 54.2, y = 51.2, itemID = 238586, questID = 89128 }, -- Ethereal Gem Pliers
            { zone = 2444, x = 62.9, y = 53.5, itemID = 238584, questID = 89126 }, -- Shattered Glass
        },
    },
    {
        key        = "leatherworking",
        label      = L["Leatherworking"],
        color      = { 0.8, 0.53, 0.2 },
        hex        = "cc8833",
        skillLine  = 2915,
        items = {
            { zone = 2393, x = 44.8, y = 56.2, itemID = 238595, questID = 89096 }, -- Artisan's Considered Order
            { zone = 2536, x = 45.2, y = 45.3, itemID = 238591, questID = 89092 }, -- Bundle of Tanner's Trinkets
            { zone = 2437, x = 33.1, y = 78.9, itemID = 238588, questID = 89089 }, -- Amani Leatherworker's Tool
            { zone = 2437, x = 30.8, y = 84.1, itemID = 238590, questID = 89091 }, -- Prestigiously Racked Hide
            { zone = 2405, x = 34.8, y = 56.9, itemID = 238589, questID = 89090 }, -- Ethereal Leatherworking Knife
            { zone = 2413, x = 51.8, y = 51.3, itemID = 238593, questID = 89094 }, -- Haranir Leatherworking Mallet
            { zone = 2413, x = 36.1, y = 25.2, itemID = 238594, questID = 89095 }, -- Haranir Leatherworking Knife
            { zone = 2444, x = 53.8, y = 51.6, itemID = 238592, questID = 89093 }, -- Patterns: Beyond the Void
        },
    },
    {
        key        = "herbalism",
        label      = L["Herbalism"],
        color      = { 0.33, 0.8, 0.27 },
        hex        = "55cc44",
        skillLine  = 2912,
        items = {
            { zone = 2393, x = 49.0, y = 75.8, itemID = 238470, questID = 89160 }, -- Simple Leaf Pruners
            { zone = 2395, x = 64.2, y = 30.4, itemID = 238472, questID = 89158 }, -- A Spade
            { zone = 2437, x = 41.9, y = 45.9, itemID = 238469, questID = 89161 }, -- Sweeping Harvester's Scythe
            { zone = 2437, x = 41.8, y = 45.9, itemID = 238473, questID = 89157, altZone = 2413, altX = 76.1, altY = 51.1 }, -- Harvester's Sickle (also in Harandar — loot once)
            { zone = 2413, x = 51.1, y = 55.7, itemID = 238475, questID = 89155 }, -- Planting Shovel
            { zone = 2413, x = 38.1, y = 66.9, itemID = 238468, questID = 89162 }, -- Bloomed Bud
            { zone = 2413, x = 36.6, y = 25.0, itemID = 238471, questID = 89159 }, -- Lightbloom Root
            { zone = 2405, x = 34.6, y = 57.0, itemID = 238474, questID = 89156 }, -- Peculiar Lotus
        },
    },
    {
        key        = "mining",
        label      = L["Mining"],
        color      = { 0.8, 0.8, 0.8 },
        hex        = "cccccc",
        skillLine  = 2916,
        items = {
            { zone = 2395, x = 38.0, y = 45.3, itemID = 238599, questID = 89147 }, -- Solid Ore Punchers
            { zone = 2437, x = 41.9, y = 46.3, itemID = 238597, questID = 89145 }, -- Spelunker's Lucky Charm
            { zone = 2413, x = 38.8, y = 65.9, itemID = 238603, questID = 89151 }, -- Spare Expedition Torch
            { zone = 2536, x = 33.6, y = 66.0, itemID = 238601, questID = 89149 }, -- Amani Expert's Chisel
            { zone = 2405, x = 41.8, y = 38.2, itemID = 238602, questID = 89150 }, -- Star Metal Deposit
            { zone = 2444, x = 28.73, y = 38.56, itemID = 238600, questID = 89148 }, -- Glimmering Void Pearl
            { zone = 2444, x = 54.24, y = 51.59, itemID = 238598, questID = 89146 }, -- Lost Voidstorm Satchel
            { zone = 2444, x = 30.0, y = 69.0, itemID = 238596, questID = 89144 }, -- Miner's Guide to Voidstorm
        },
    },
    {
        key        = "skinning",
        label      = L["Skinning"],
        color      = { 0.78, 0.63, 0.38 },
        hex        = "c8a060",
        skillLine  = 2917,
        items = {
            { zone = 2393, x = 43.2, y = 55.7, itemID = 238633, questID = 89171 }, -- Sin'dorei Tanning Oil
            { zone = 2395, x = 48.5, y = 76.2, itemID = 238635, questID = 89173 }, -- Thalassian Skinning Knife
            { zone = 2437, x = 40.4, y = 36.0, itemID = 238632, questID = 89170 }, -- Amani Tanning Oil
            { zone = 2437, x = 33.1, y = 79.0, itemID = 238634, questID = 89172 }, -- Amani Skinning Knife
            { zone = 2536, x = 45.0, y = 44.7, itemID = 238629, questID = 89167 }, -- Cadre Skinning Knife
            { zone = 2413, x = 69.5, y = 49.2, itemID = 238630, questID = 89168 }, -- Primal Hide
            { zone = 2413, x = 76.0, y = 51.0, itemID = 238628, questID = 89166 }, -- Lightbloom Afflicted Hide
            { zone = 2444, x = 44.2, y = 45.95, itemID = 238631, questID = 89169 }, -- Voidstorm Leather Sample
        },
    },
}

local function GetItemDisplayName(item)
    if item.itemID then
        local name = GetItemInfo(item.itemID)
        if name and name ~= "" then return name end
    end
    return "|cffaaaaaa...|r" 
end

local RebuildGatheringLocationsFrame

local itemCacheFrame = CreateFrame("Frame")
itemCacheFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemCacheFrame:RegisterEvent("QUEST_TURNED_IN")
itemCacheFrame:SetScript("OnEvent", function()
    if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then
        RebuildGatheringLocationsFrame()
    end
end)

local PROF_KEY_TO_NAME = {
    tailoring = L["Tailoring"],
    alchemy = L["Alchemy"],
    blacksmithing = L["Blacksmithing"],
    enchanting = L["Enchanting"],
    engineering = L["Engineering"],
    inscription = L["Inscription"],
    jewelcrafting = L["Jewelcrafting"],
    leatherworking = L["Leatherworking"],
    herbalism = L["Herbalism"],
    mining = L["Mining"],
    skinning = L["Skinning"],
}

local function HasProfessionLearned(skillLine)
    return MR.playerProfessions and MR.playerProfessions[skillLine] or false
end

local gatheringCfgFrame
local PopulateGatheringConfig
local _waypointAlt = {} 

local function GetProfessionColor(profession)
    local colors = MR.db.profile.gatheringProfColors or {}
    local profColors = colors[profession]
    if profColors then
        return profColors[1], profColors[2], profColors[3]
    end
    for _, prof in ipairs(PROFESSIONS) do
        if prof.key == profession then
            return prof.color[1], prof.color[2], prof.color[3]
        end
    end
    return 1, 1, 1
end

local _zoneNameCache = {}
local function GetGatheringZoneName(mapID)
    if not mapID then return "Unknown" end
    if _zoneNameCache[mapID] then return _zoneNameCache[mapID] end
    local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    local zoneName = (mapInfo and mapInfo.name) or ("Map " .. tostring(mapID))
    _zoneNameCache[mapID] = zoneName
    return zoneName
end

local function SetGatheringWaypoint(item)
    local mapID = item and item.zone
    local x = item and item.x and (item.x / 100)
    local y = item and item.y and (item.y / 100)
    local tomTom = _G and rawget(_G, "TomTom")
    if not mapID or not x or not y then
        return false, "Invalid coordinates"
    end

    if tomTom and tomTom.AddWaypoint then
        local ok = pcall(function()
            tomTom:AddWaypoint(mapID, x, y, {
                title = GetItemDisplayName(item),
                persistent = false,
                minimap = true,
                world = true,
            })
        end)
        if ok then return true, "TomTom" end
    end

    if UiMapPoint and UiMapPoint.CreateFromCoordinates and C_Map and C_Map.SetUserWaypoint then
        local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        if point then
            C_Map.SetUserWaypoint(point)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
            return true, "Blizzard"
        end
    end

    return false, "No waypoint API available"
end

local function BuildGatheringLocationsFrame()
    local db     = MR.db and MR.db.profile or {}
    local hadProfCache = MR.playerProfessions and next(MR.playerProfessions) ~= nil
    if not hadProfCache and MR.RefreshPlayerProfessions then
        MR:RefreshPlayerProfessions()
    end
    local hasProfCache = MR.playerProfessions and next(MR.playerProfessions) ~= nil
    local alpha  = db.gatheringAlpha or 1.0
    local W      = db.gatheringWidth or DEFAULT_W
    local H      = db.gatheringHeight or DEFAULT_H
    local minimized = db.gatheringMinimized or false
    gatheringMinimized = minimized

    local f = MR_StyledFrame(UIParent, "MRGatheringLocationsFrame", "MEDIUM", 10)
    f:SetSize(W, minimized and TITLE_H or H)
    f:SetBackdropColor(0.03, 0.05, 0.08, 0.97 * alpha)
    f:SetBackdropBorderColor(0.22, 0.18, 0.28, alpha)
    MR_RestoreFramePos(f, "gatheringLocPos", 860, 0)

    f.leftAccent = MR_LeftAccent(f, 0.80, 0.53, 0.20)
    f.topAccent  = MR_TopAccent(f,  0.80, 0.53, 0.20)
    if f.leftAccent then f.leftAccent:SetAlpha(alpha) end
    if f.topAccent  then f.topAccent:SetAlpha(alpha)  end

    local titleBar = MR_TitleBar(f, TITLE_H)
    f.titleBar = titleBar
    titleBar:SetBackdropColor(0, 0, 0, 0)
    titleBar:SetScript("OnDragStart", function() if not db.gatheringLocked then f:StartMoving() end end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local pt, _, rp, x, y = f:GetPoint()
        if MR.db then MR.db.profile.gatheringLocPos = { point = pt, relPoint = rp, x = x, y = y } end
    end)

    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(14, 14)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 8, 0)
    titleIcon:SetTexture("Interface\\AddOns\\MidnightRoutine\\Media\\Icon")
    titleIcon:SetVertexColor(0.80, 0.53, 0.20, 1)

    local closeBtn = MR_CloseButton(titleBar, function()
        f:Hide()
        if MR.db then MR.db.profile.gatheringLocOpen = false end
    end)

    local gearBtn = CreateFrame("Button", nil, titleBar)
    gearBtn:SetSize(14, 14)
    gearBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
    local gearTex = gearBtn:CreateTexture(nil, "ARTWORK")
    gearTex:SetAllPoints()
    gearTex:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    gearTex:SetVertexColor(0.80, 0.53, 0.20, 1)
    gearBtn:SetNormalTexture(gearTex)
    local gearHL = gearBtn:CreateTexture(nil, "HIGHLIGHT")
    gearHL:SetAllPoints()
    gearHL:SetTexture("Interface\\Buttons\\UI-OptionsButton")
    gearHL:SetVertexColor(1, 1, 1, 1)
    gearBtn:SetHighlightTexture(gearHL)
    gearBtn:SetScript("OnEnter",  function()
        gearTex:SetVertexColor(1, 0.82, 0.40, 1)
        GameTooltip:SetOwner(gearBtn, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["ProfKnowledge_OptionsTitle"], 1, 1, 1)
        GameTooltip:Show()
    end)
    gearBtn:SetScript("OnLeave",  function()
        gearTex:SetVertexColor(0.80, 0.53, 0.20, 1)
        GameTooltip:Hide()
    end)
    gearBtn:SetScript("OnClick", function()
        MR:ToggleGatheringLocationsConfig()
    end)

    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY")
    titleTxt:SetFont(FONT_HEADERS, 10, "OUTLINE")
    titleTxt:SetPoint("LEFT",  titleIcon, "RIGHT", 5, 0)
    titleTxt:SetPoint("RIGHT", gearBtn, "LEFT", -48, 0)
    titleTxt:SetJustifyH("LEFT")
    titleTxt:SetText(L["ProfKnowledge_Title"])

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
    thumb:SetColorTexture(0.80, 0.53, 0.20, 0.6)
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
        minLbl:SetText(gatheringMinimized and "+" or "-")
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

    local dragger
    minBtn:SetScript("OnClick", function()
        gatheringMinimized = not gatheringMinimized
        minimized = gatheringMinimized
        if MR.db then MR.db.profile.gatheringMinimized = gatheringMinimized end
        UpdateMinBtn()
        if gatheringMinimized then
            scroll:Hide()
            if dragger then dragger:Hide() end
            f:SetHeight(TITLE_H)
        else
            scroll:Show()
            if dragger then dragger:Show() end
            f:SetHeight(MR.db and MR.db.profile.gatheringHeight or DEFAULT_H)
            f.UpdateScrollBar()
        end
    end)

    local yOff = 0
    local fontName = FONT_ROWS
    local fontSize = db.gatheringFontSize or 9

    for _, prof in ipairs(PROFESSIONS) do
        if HasProfessionLearned(prof.skillLine) then
            local cr, cg, cb = GetProfessionColor(prof.key)
            local header = content:CreateFontString(nil, "OVERLAY")
            header:SetFont(fontName, fontSize + 2, "OUTLINE")
            header:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -yOff)
            header:SetTextColor(cr, cg, cb, 1.0)
            header:SetText(prof.label .. " (" .. #prof.items .. ")")
            yOff = yOff + 20

            local rowHeight = math.max(fontSize + 6, 14)
            local doneCount = 0
            for _, item in ipairs(prof.items) do
                if item.questID and C_QuestLog.IsQuestFlaggedCompleted(item.questID) then
                    doneCount = doneCount + 1
                end
            end
            header:SetText(prof.label .. " (" .. doneCount .. "/" .. #prof.items .. ")")

            for _, item in ipairs(prof.items) do
                local done = item.questID and C_QuestLog.IsQuestFlaggedCompleted(item.questID)

                if done and db.gatheringHideCompleted then
                else

                local row = CreateFrame("Button", nil, content)
                row:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -yOff)
                row:SetSize(W - 24, rowHeight)
                row:RegisterForClicks("LeftButtonUp")

                local hover = row:CreateTexture(nil, "BACKGROUND")
                hover:SetAllPoints()
                hover:SetColorTexture(cr, cg, cb, 0)

                local nameText = row:CreateFontString(nil, "OVERLAY")
                nameText:SetFont(fontName, fontSize - 1, nil)
                nameText:SetPoint("LEFT", row, "LEFT", 2, 0)
                nameText:SetPoint("RIGHT", row, "RIGHT", -126, 0)
                nameText:SetJustifyH("LEFT")
                nameText:SetText(GetItemDisplayName(item))
                if done then
                    nameText:SetTextColor(0.4, 0.4, 0.4)
                else
                    nameText:SetTextColor(0.90, 0.90, 0.90)
                end

                local coordText = row:CreateFontString(nil, "OVERLAY")
                coordText:SetFont(fontName, fontSize - 1, "OUTLINE")
                coordText:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                coordText:SetWidth(122)
                coordText:SetJustifyH("RIGHT")
                coordText:SetText(string.format("%.1f, %.1f", item.x, item.y))
                if done then
                    coordText:SetTextColor(0.4, 0.4, 0.4, 0.6)
                else
                    coordText:SetTextColor(cr, cg, cb, 0.95)
                end

                row:SetScript("OnEnter", function()
                    hover:SetColorTexture(cr, cg, cb, 0.10)
                    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
                    GameTooltip:SetText(GetItemDisplayName(item), 1, 1, 1)
                    if item.altZone then
                        local useAlt = _waypointAlt[item.questID]
                        local nextZone = useAlt and item.altZone or item.zone
                        local nextX    = useAlt and item.altX   or item.x
                        local nextY    = useAlt and item.altY   or item.y
                        local otherZone = useAlt and item.zone    or item.altZone
                        local otherX    = useAlt and item.x       or item.altX
                        local otherY    = useAlt and item.y       or item.altY
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine(L["Gathering_NextWaypoint"], 1, 0.82, 0)
                        GameTooltip:AddLine(GetGatheringZoneName(nextZone), 0.9, 0.9, 0.9)
                        GameTooltip:AddLine(string.format("%.1f, %.1f", nextX, nextY), 0.4, 1, 0.7)
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine(L["Gathering_AltLocationLabel"], 0.65, 0.65, 0.65)
                        GameTooltip:AddLine(GetGatheringZoneName(otherZone), 0.6, 0.6, 0.6)
                        GameTooltip:AddLine(string.format("%.1f, %.1f", otherX, otherY), 0.45, 0.7, 0.55)
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine(L["Gathering_TwoSpawnNote"], 0.6, 0.6, 0.6)
                    else
                        GameTooltip:AddLine(GetGatheringZoneName(item.zone), 0.8, 0.8, 0.8)
                        GameTooltip:AddLine(string.format(L["Gathering_Coords"], item.x, item.y), 0.7, 1, 0.9)
                    end
                    GameTooltip:AddLine(" ")
                    if done then
                        GameTooltip:AddLine(L["Gathering_AlreadyCollected"], 0, 0.8, 0.27)
                    elseif item.altZone then
                        GameTooltip:AddLine(L["Gathering_ClickCycleHint"], 0.27, 0.67, 1)
                    else
                        GameTooltip:AddLine(L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
                    end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function()
                    hover:SetColorTexture(cr, cg, cb, 0)
                    GameTooltip:Hide()
                end)
                row:SetScript("OnClick", function()
                    local useAlt = item.altZone and _waypointAlt[item.questID]
                    local target = useAlt
                        and { zone = item.altZone, x = item.altX, y = item.altY }
                        or item
                    if item.altZone then
                        _waypointAlt[item.questID] = not _waypointAlt[item.questID]
                    end
                    local ok, source = SetGatheringWaypoint(target)
                    local displayName = GetItemDisplayName(item)
                    if ok then
                        print(string.format(L["Waypoint_Set"], source, displayName, target.x, target.y))
                    else
                        print(L["Waypoint_Unavailable"])
                    end
                end)

                yOff = yOff + rowHeight + 1
                end 
            end
            yOff = yOff + 4
        end
    end

    if yOff == 0 then
        local emptyText = content:CreateFontString(nil, "OVERLAY")
        emptyText:SetFont(fontName, fontSize, "OUTLINE")
        emptyText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
        emptyText:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, -10)
        emptyText:SetJustifyH("LEFT")
        emptyText:SetTextColor(0.72, 0.72, 0.72, 0.95)
        if not hasProfCache then
            emptyText:SetText(L["Gathering_Loading"])
        else
            emptyText:SetText(L["Gathering_NoProfessions"])
        end
        yOff = 32

        if not hasProfCache and C_Timer then
            C_Timer.After(0.75, function()
                if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then
                    if MR.RefreshPlayerProfessions then MR:RefreshPlayerProfessions() end
                    gatheringLocationsFrame:Hide()
                    gatheringLocationsFrame = BuildGatheringLocationsFrame()
                end
            end)
        end
    end

    content:SetHeight(yOff)
    scroll:SetVerticalScroll(0)
    f.UpdateScrollBar()

    if not minimized then
        local savedH = db.gatheringHeight or DEFAULT_H
        local naturalH = TITLE_H + 1 + yOff + 6
        f:SetHeight(math.min(savedH, naturalH))
    end

    dragger = CreateFrame("Frame", nil, f)
    dragger:SetSize(12, 12)
    dragger:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    dragger:SetFrameLevel(f:GetFrameLevel() + 10)
    dragger:EnableMouse(true)
    f._dragger = dragger

    local dTex = dragger:CreateTexture(nil, "OVERLAY")
    dTex:SetAllPoints()
    dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    dragger:SetScript("OnEnter", function()
        if not db.gatheringLocked then
            dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        end
    end)
    dragger:SetScript("OnLeave", function()
        dTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    end)

    local dragStartW, dragStartH, dragStartX, dragStartY
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not db.gatheringLocked then
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
                MR.db.profile.gatheringWidth  = newW
                MR.db.profile.gatheringHeight = newH
            end
            RebuildGatheringLocationsFrame()
            if gatheringCfgFrame and gatheringCfgFrame:IsShown() then
                PopulateGatheringConfig(gatheringCfgFrame)
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

    f:SetMovable(not db.gatheringLocked)
    f:SetScale(db.gatheringScale or 1.0)
    MR.gatheringLocationsFrame = f
    f:Show()
    return f
end

RebuildGatheringLocationsFrame = function()
    if gatheringLocationsFrame then gatheringLocationsFrame:Hide() end
    gatheringLocationsFrame = BuildGatheringLocationsFrame()
end

local function SetProfessionColor(profession, r, g, b)
    if not MR.db.profile.gatheringProfColors then
        MR.db.profile.gatheringProfColors = {}
    end
    MR.db.profile.gatheringProfColors[profession] = {r, g, b}
    RebuildGatheringLocationsFrame()
end

local function ResetProfessionColor(profession)
    if MR.db.profile.gatheringProfColors then
        MR.db.profile.gatheringProfColors[profession] = nil
    end
    RebuildGatheringLocationsFrame()
end

local function BuildGatheringConfigFrame()
    local f = CreateFrame("Frame", "MRGatheringConfigFrame", UIParent, "BackdropTemplate")
    f:SetWidth(224)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(20)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop(MR_MakeBackdrop())
    f:SetBackdropColor(0.03, 0.05, 0.02, 0.98)
    f:SetBackdropBorderColor(0.50, 0.40, 0.16, 1)
    f:Hide()

    MR_TopAccent(f, 0.80, 0.53, 0.20)

    local tbar = MR_TitleBar(f, 22)
    tbar:SetBackdropColor(0.10, 0.08, 0.02, 1)
    tbar:SetScript("OnDragStart", function() f:StartMoving() end)
    tbar:SetScript("OnDragStop",  function() f:StopMovingOrSizing() end)

    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(FONT_HEADERS, 10, "OUTLINE")
    ttitle:SetText(L["ProfKnowledge_Config_Title"])
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)

    MR_CloseButton(tbar, function() f:Hide() end)
    f.body = nil
    return f
end

PopulateGatheringConfig = function(f)
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
    if not db then db = {} end
    local yOff = -28
    local P    = 8

    local cfgFs = MR.db.profile.syncWindowFontSize and (db.gatheringFontSize or 9) or 9

    local function Gap(h)      yOff = MR_OptionsGap(body, yOff, h) end
    local function Divider()   yOff = MR_OptionsDivider(body, yOff, P) end
    local function SecLabel(t) yOff = MR_OptionsSectionLabel(body, yOff, t, P, cfgFs) end
    local function Check(lbl, get, set, r, g, b)
        yOff = MR_OptionsCheckbox(body, yOff, lbl, get, set,
            r or 0.78, g or 0.78, b or 0.88, P,
            function() PopulateGatheringConfig(f) end, cfgFs)
    end
    local function Slider(lbl, mn, mx, st, get, set, r, g, b, disabled)
        yOff = MR_OptionsSlider(body, yOff, lbl, mn, mx, st, get, set, r, g, b, P, disabled, cfgFs)
    end
    local function Btn(lbl, fn) yOff = MR_OptionsBtn(body, yOff, lbl, fn, 184, P, cfgFs) end

    SecLabel(L["DISPLAY"])
    Check(L["Lock Position"],
         function() return db.gatheringLocked end,
         function(v)
            db.gatheringLocked = v
            if gatheringLocationsFrame then
            	gatheringLocationsFrame:SetMovable(not v)
	    end
         end)
        Check(L["Config_HideWhenCompleted"],
            function() return db.gatheringHideCompleted end,
            function(v)
                db.gatheringHideCompleted = v
                RebuildGatheringLocationsFrame()
            end)

    Gap(4); Divider()
    SecLabel(L["SIZE & OPACITY"])
    Slider(L["WIDTH"], MIN_W, MAX_W, 10,
        function() return db.gatheringWidth or DEFAULT_W end,
        function(v)
            db.gatheringWidth = math.floor(v / 10) * 10
            RebuildGatheringLocationsFrame()
        end,
        0.80, 0.53, 0.20)
    Slider(L["HEIGHT"], MIN_H, MAX_H, 10,
        function() return db.gatheringHeight or DEFAULT_H end,
        function(v)
            db.gatheringHeight = math.floor(v / 10) * 10
            if gatheringLocationsFrame and not db.gatheringMinimized then
                gatheringLocationsFrame:SetHeight(db.gatheringHeight)
            end
        end,
        0.60, 0.80, 0.40)
    local syncFs = MR.db.profile.syncWindowFontSize
    Slider(L["FONT SIZE"], 7, 16, 1,
        function() return db.gatheringFontSize or 9 end,
        function(v) db.gatheringFontSize = math.floor(v); RebuildGatheringLocationsFrame(); PopulateGatheringConfig(f) end,
        0.78, 0.55, 0.16, syncFs)

    do
        local presets = { {"S", 8}, {"M", 9}, {"L", 11}, {"XL", 13} }
        local btnW    = 42
        for i, p in ipairs(presets) do
            local isActive = (not syncFs) and ((db.gatheringFontSize or 9) == p[2])
            local pb = CreateFrame("Button", nil, body, "BackdropTemplate")
            pb:SetSize(btnW - 2, 16)
            pb:SetPoint("TOPLEFT", body, "TOPLEFT", P + (i-1) * btnW, yOff - 2)
            pb:SetBackdrop(MR_MakeBackdrop())
            pb:SetBackdropColor(isActive and 0.12 or 0.05, isActive and 0.35 or 0.10, isActive and 0.32 or 0.18, syncFs and 0.4 or 1)
            pb:SetBackdropBorderColor(isActive and 0.25 or 0.18, isActive and 0.85 or 0.40, isActive and 0.70 or 0.45, syncFs and 0.4 or 1)
            local pfs = pb:CreateFontString(nil, "OVERLAY")
            pfs:SetFont(FONT_ROWS, cfgFs, "OUTLINE")
            pfs:SetPoint("CENTER")
            pfs:SetText(p[1])
            pfs:SetTextColor(syncFs and 0.35 or (isActive and 0.2 or 0.6), syncFs and 0.35 or (isActive and 0.95 or 0.75), syncFs and 0.35 or (isActive and 0.75 or 0.65))
            if not syncFs then
                pb:SetScript("OnClick", function()
                    db.gatheringFontSize = p[2]
                    RebuildGatheringLocationsFrame()
                    PopulateGatheringConfig(f)
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
        function() return db.gatheringAlpha or 1.0 end,
        function(v)
            db.gatheringAlpha = math.floor(v * 20) / 20
            if gatheringLocationsFrame then
                gatheringLocationsFrame:SetBackdropColor(0.03, 0.05, 0.08, 0.97 * v)
                gatheringLocationsFrame:SetBackdropBorderColor(0.22, 0.18, 0.28, v)
                if gatheringLocationsFrame.leftAccent then gatheringLocationsFrame.leftAccent:SetAlpha(v) end
                if gatheringLocationsFrame.topAccent then gatheringLocationsFrame.topAccent:SetAlpha(v) end
            end
        end,
        0.40, 0.40, 0.40)
    Slider(L["SCALE"], 0.5, 2.0, 0.05,
        function() return db.gatheringScale or 1.0 end,
        function(v)
            db.gatheringScale = v
            if gatheringLocationsFrame then gatheringLocationsFrame:SetScale(v) end
        end,
        0.45, 0.22, 0.82, MR.db.profile.syncWindowScale)

    Gap(4); Divider()
    SecLabel(L["PROFESSION COLORS"])

    for _, profession in ipairs(PROFESSIONS) do
        if HasProfessionLearned(profession.skillLine) then
            local cr, cg, cb = GetProfessionColor(profession.key)
            local ROW_H2 = 22
            local rowFr  = CreateFrame("Frame", nil, body)
            rowFr:SetPoint("TOPLEFT",  body, "TOPLEFT",  P,  yOff)
            rowFr:SetPoint("TOPRIGHT", body, "TOPRIGHT", -P, yOff)
            rowFr:SetHeight(ROW_H2)

            local nameLbl
            local swatch = MR_OptionsColorSwatch(rowFr, cr, cg, cb,
                function(r, g, b)
                    SetProfessionColor(profession.key, r, g, b)
                    if nameLbl then nameLbl:SetTextColor(r, g, b) end
                end,
                function()
                    ResetProfessionColor(profession.key)
                    local dr, dg, db2 = profession.color[1], profession.color[2], profession.color[3]
                    if nameLbl then nameLbl:SetTextColor(dr, dg, db2) end
                    return dr, dg, db2
                end,
                profession.label .. " color  -  right-click to reset")
            swatch:SetPoint("RIGHT", rowFr, "RIGHT", 0, 0)

            nameLbl = rowFr:CreateFontString(nil, "OVERLAY")
            nameLbl:SetFont(FONT_ROWS, 10, "OUTLINE")
            nameLbl:SetPoint("LEFT",  rowFr,  "LEFT",  0,  0)
            nameLbl:SetPoint("RIGHT", swatch, "LEFT", -4,  0)
            nameLbl:SetText(profession.label)
            nameLbl:SetTextColor(cr, cg, cb)
            nameLbl:SetJustifyH("LEFT")

            yOff = yOff - (ROW_H2 + 2)
        end
    end

    Gap(4); Divider()
    Btn(L["Reset All Colors"], function()
        MR.db.profile.gatheringProfColors = {}
        RebuildGatheringLocationsFrame()
        PopulateGatheringConfig(f)
    end)

    local totalH = math.abs(yOff) + 10
    f:SetHeight(totalH)
    body:SetHeight(totalH)
end

function MR:ToggleGatheringLocationsConfig()
    if not gatheringCfgFrame then
        gatheringCfgFrame = BuildGatheringConfigFrame()
        PopulateGatheringConfig(gatheringCfgFrame)
    end

    if gatheringCfgFrame:IsShown() then
        gatheringCfgFrame:Hide()
    else
        gatheringCfgFrame:Show()
        if gatheringLocationsFrame then
            local x, y = gatheringLocationsFrame:GetCenter()
            if x and y then
                gatheringCfgFrame:SetPoint("LEFT", gatheringLocationsFrame, "RIGHT", 10, 0)
                gatheringCfgFrame:SetScale(gatheringLocationsFrame:GetScale())
            end
        end
    end
end

local function ToggleGatheringLocations()
    if not gatheringLocationsFrame then
        gatheringLocationsFrame = BuildGatheringLocationsFrame()
        if MR.db then MR.db.profile.gatheringLocOpen = true end
    elseif gatheringLocationsFrame:IsShown() then
        gatheringLocationsFrame:Hide()
        if MR.db then MR.db.profile.gatheringLocOpen = false end
    else
        gatheringLocationsFrame:Show()
        if MR.db then MR.db.profile.gatheringLocOpen = true end
    end
end

MR.ToggleGatheringLocations = ToggleGatheringLocations

function MR:ShowGatheringLocations()
    if not gatheringLocationsFrame then
        gatheringLocationsFrame = BuildGatheringLocationsFrame()
    else
        gatheringLocationsFrame:Show()
    end
    if self.db then self.db.profile.gatheringLocOpen = true end
end

function MR:EnsureGatheringLocationsShown()
    if not gatheringLocationsFrame then
        gatheringLocationsFrame = BuildGatheringLocationsFrame()
    else
        gatheringLocationsFrame:Show()
    end
end

function MR:RefreshGatheringLocationsFrame()
    if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then
        RebuildGatheringLocationsFrame()
    end
end

function MR:HideGatheringLocations(persistState)
    if gatheringLocationsFrame then gatheringLocationsFrame:Hide() end
    if gatheringCfgFrame then gatheringCfgFrame:Hide() end
    if persistState ~= false and self.db then
        self.db.profile.gatheringLocOpen = false
    end
end

function MR:RepopulateGatheringConfig()
    if gatheringCfgFrame and gatheringCfgFrame:IsShown() then
        PopulateGatheringConfig(gatheringCfgFrame)
    end
end

function MR:RebuildGatheringLocationsFrame()
    if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then
        RebuildGatheringLocationsFrame()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == "MidnightRoutine" then
        if MR.db then
            gatheringMinimized = MR.db.profile.gatheringMinimized or false
            if MR.db.profile.gatheringLocOpen then
                MR:ShowGatheringLocations()
            end
        end
        eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end)
