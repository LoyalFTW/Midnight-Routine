local _, ns = ...
if ns.Inactive then return end
if ns.MR.isForever and ns.Forever.hideProfessions then return end
local MR = ns.MR
local PK = ns.ProfessionKnowledgeInternal

local TopAccent = ns.TopAccent
local hex = ns.Hex
local IsEntryVisible = PK.IsEntryVisible
local IsDone = PK.IsDone

local function ApplyGatheringFrameTheme(frame, opts)
    if not frame then
        return
    end

    opts = opts or {}
    local alpha = opts.alpha or 1
    local bg = opts.bg or { 0.03, 0.05, 0.09, 0.97 * alpha }
    local border = opts.border or { 0.24, 0.31, 0.42, alpha }
    local accent = opts.accent or { 0.18, 0.78, 0.72 }
    if ns.ResolveThemeColor then
        accent[1], accent[2], accent[3] = ns.ResolveThemeColor(accent[1], accent[2], accent[3])
    end

    frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
    frame:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)

    if not frame._gatheringTopAccent then
        frame._gatheringTopAccent = TopAccent(frame, accent[1], accent[2], accent[3])
    else
        frame._gatheringTopAccent:SetColorTexture(accent[1], accent[2], accent[3], 1)
    end
    frame.topAccent = frame._gatheringTopAccent
    frame.topAccent:SetAlpha(alpha)

    if not frame._gatheringGlow then
        frame._gatheringGlow = frame:CreateTexture(nil, "BACKGROUND")
        frame._gatheringGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
        frame._gatheringGlow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    end
    frame._gatheringGlow:SetColorTexture(bg[1], math.min(bg[2] + 0.07, 1), math.min(bg[3] + 0.07, 1), 0.30 * alpha)

    if opts.headerGlow ~= false then
        if not frame._gatheringHeaderGlow then
            frame._gatheringHeaderGlow = frame:CreateTexture(nil, "BORDER")
            frame._gatheringHeaderGlow:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
            frame._gatheringHeaderGlow:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
            frame._gatheringHeaderGlow:SetHeight(opts.headerHeight or 64)
        end
        frame._gatheringHeaderGlow:SetHeight(opts.headerHeight or 64)
        frame._gatheringHeaderGlow:SetColorTexture(accent[1] * 0.45, accent[2] * 0.45, accent[3] * 0.45, 0.22 * alpha)
        frame._gatheringHeaderGlow:Show()
    elseif frame._gatheringHeaderGlow then
        frame._gatheringHeaderGlow:Hide()
    end
end

local function VisibleSortedEntries(entries)
    local list = {}
    for i, entry in ipairs(entries or {}) do
        if IsEntryVisible(entry) then
            list[#list + 1] = { entry = entry, index = i, done = IsDone(entry) }
        end
    end
    table.sort(list, function(a, b)
        if a.done ~= b.done then return not a.done end
        return a.index < b.index
    end)
    local result = {}
    for i, item in ipairs(list) do
        result[i] = item.entry
    end
    return result
end

local renderArena
local renderScriptNames = {
    "OnClick",
    "OnEnter",
    "OnLeave",
    "OnMouseDown",
    "OnMouseUp",
    "OnDragStart",
    "OnDragStop",
    "OnUpdate",
}

local function ResetRenderRegions(parent)
    if parent._pkFontStrings then
        for _, bucket in pairs(parent._pkFontStrings) do
            bucket.used = 0
            for _, region in ipairs(bucket) do
                region:Hide()
            end
        end
    end
    if parent._pkTextures then
        for _, bucket in pairs(parent._pkTextures) do
            bucket.used = 0
            for _, region in ipairs(bucket) do
                region:Hide()
            end
        end
    end
end

local function BeginProfessionRender(content)
    renderArena = content._pkRenderArena
    if not renderArena then
        renderArena = { frames = {} }
        content._pkRenderArena = renderArena
    end
    for _, bucket in pairs(renderArena.frames) do
        bucket.used = 0
        for _, frame in ipairs(bucket) do
            ns.HideOwnedTooltip(frame)
            frame:Hide()
        end
    end
    ResetRenderRegions(content)
end

local function EndProfessionRender()
    renderArena = nil
end

local function RenderFrame(frameType, parent, template)
    local key = frameType .. ":" .. tostring(template or "")
    local bucket = renderArena.frames[key]
    if not bucket then
        bucket = { used = 0 }
        renderArena.frames[key] = bucket
    end
    bucket.used = bucket.used + 1
    local frame = bucket[bucket.used]
    if not frame then
        frame = CreateFrame(frameType, nil, parent, template)
        bucket[bucket.used] = frame
        MR._professionKnowledgePooledFrameCreatedCount = (MR._professionKnowledgePooledFrameCreatedCount or 0) + 1
    else
        MR._professionKnowledgePooledFrameReusedCount = (MR._professionKnowledgePooledFrameReusedCount or 0) + 1
        frame:SetParent(parent)
    end
    frame:ClearAllPoints()
    frame:SetAlpha(1)
    frame._mrHover = nil
    frame._entry = nil
    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end
    if frame.HasScript then
        for _, scriptName in ipairs(renderScriptNames) do
            if frame:HasScript(scriptName) then
                frame:SetScript(scriptName, nil)
            end
        end
    end
    if frame.EnableMouse then
        frame:EnableMouse(frameType == "Button")
    end
    ResetRenderRegions(frame)
    frame:Show()
    return frame
end

local function RenderFontString(parent, layer)
    parent._pkFontStrings = parent._pkFontStrings or {}
    local key = layer or "OVERLAY"
    local bucket = parent._pkFontStrings[key]
    if not bucket then
        bucket = { used = 0 }
        parent._pkFontStrings[key] = bucket
    end
    bucket.used = bucket.used + 1
    local region = bucket[bucket.used]
    if not region then
        region = parent:CreateFontString(nil, key)
        bucket[bucket.used] = region
        MR._professionKnowledgePooledLabelCreatedCount = (MR._professionKnowledgePooledLabelCreatedCount or 0) + 1
    else
        MR._professionKnowledgePooledLabelReusedCount = (MR._professionKnowledgePooledLabelReusedCount or 0) + 1
    end
    region:ClearAllPoints()
    region:SetAlpha(1)
    region:Show()
    return region
end

local function RenderTexture(parent, layer)
    parent._pkTextures = parent._pkTextures or {}
    local key = layer or "ARTWORK"
    local bucket = parent._pkTextures[key]
    if not bucket then
        bucket = { used = 0 }
        parent._pkTextures[key] = bucket
    end
    bucket.used = bucket.used + 1
    local region = bucket[bucket.used]
    if not region then
        region = parent:CreateTexture(nil, key)
        bucket[bucket.used] = region
        MR._professionKnowledgePooledTextureCreatedCount = (MR._professionKnowledgePooledTextureCreatedCount or 0) + 1
    else
        MR._professionKnowledgePooledTextureReusedCount = (MR._professionKnowledgePooledTextureReusedCount or 0) + 1
    end
    region:ClearAllPoints()
    region:SetAlpha(1)
    region:SetTexture(nil)
    region:SetBlendMode("BLEND")
    region:SetTexCoord(0, 1, 0, 1)
    region:SetVertexColor(1, 1, 1, 1)
    region:Show()
    return region
end

local SECTION_RENDER_ORDER = {
    weekly = 1,
    catchup = 2,
    discoveries = 3,
    treasures = 3,
    books = 3,
    studies = 4,
    darkmoon = 5,
    lures = 6,
}

local function GetOrderedProfessionSections(profession)
    local sections = {}
    for index, section in ipairs(profession.sections or {}) do
        sections[#sections + 1] = { section = section, index = index }
    end
    table.sort(sections, function(a, b)
        local ao = SECTION_RENDER_ORDER[a.section.key] or 50
        local bo = SECTION_RENDER_ORDER[b.section.key] or 50
        if ao ~= bo then return ao < bo end
        return a.index < b.index
    end)
    local ordered = {}
    for index, item in ipairs(sections) do
        ordered[index] = item.section
    end
    return ordered
end

local function ShouldShowProfessionSection(section)
    if section and section.key == "darkmoon" then
        return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() or false
    end
    return true
end

local function GetMainMenuEntryColor(expansionKey, profession, sectionKey, entry, fallbackR, fallbackG, fallbackB)
    local rowKey = ns.GetEntryMainMenuKey and ns.GetEntryMainMenuKey(sectionKey, entry)
    if rowKey then
        local modKey = (sectionKey == "lures") and "skin_lures"
            or (ns.GetProfessionModuleKey and ns.GetProfessionModuleKey(expansionKey, profession))
            or ("prof_" .. profession.key)
        local color = MR:GetRowColor(modKey, rowKey) or MR:GetHeaderColor(modKey)
        if color then
            return hex(color)
        end
    end
    return fallbackR, fallbackG, fallbackB
end

PK.ApplyGatheringFrameTheme = ApplyGatheringFrameTheme
PK.VisibleSortedEntries = VisibleSortedEntries
PK.BeginProfessionRender = BeginProfessionRender
PK.EndProfessionRender = EndProfessionRender
PK.RenderFrame = RenderFrame
PK.RenderFontString = RenderFontString
PK.RenderTexture = RenderTexture
PK.GetOrderedProfessionSections = GetOrderedProfessionSections
PK.ShouldShowProfessionSection = ShouldShowProfessionSection
PK.GetMainMenuEntryColor = GetMainMenuEntryColor
