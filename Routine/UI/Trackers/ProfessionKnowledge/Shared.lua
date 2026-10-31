local _, ns = ...
if ns.Inactive then return end
if ns.MR.isForever and ns.Forever.hideProfessions then return end
local MR = ns.MR
local PK = {}

local FONT_HEADERS = ns.FONT_HEADERS
local FONT_ROWS = ns.FONT_ROWS
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)

local waypointLocationIndex = {}
local QueueGatheringLocationsRebuild
local knowledgeTracker = MR.tracker:CreateProfessionKnowledgeTracker(MR, {
    namespace = ns,
    waypointLocationIndex = waypointLocationIndex,
    expansions = MR.isForever and ns.Forever.expansions or ns.AllExpansions,
    requestRefresh = function(force) QueueGatheringLocationsRebuild(force) end,
})
local IsEntryVisible = knowledgeTracker.IsEntryVisible
local HasProfessionLearned = knowledgeTracker.HasProfessionLearned
local Required = knowledgeTracker.Required
local Progress = knowledgeTracker.Progress
local IsDone = knowledgeTracker.IsDone
local KPTotal = knowledgeTracker.KPTotal
local ProfessionStats = knowledgeTracker.ProfessionStats
local ProfessionWeeklyStats = knowledgeTracker.ProfessionWeeklyStats
local GetProfessionSkillSummary = knowledgeTracker.GetProfessionSkillSummary
local GetItemCountRemaining = knowledgeTracker.GetItemCountRemaining
local GetProfessionCatchupAmount = knowledgeTracker.GetProfessionCatchupAmount
local GetProfessionCatchupProgress = knowledgeTracker.GetProfessionCatchupProgress
local GetProfessionTaskRows = knowledgeTracker.GetProfessionTaskRows
local IsSkinningLuresModule = knowledgeTracker.IsSkinningLuresModule
local IsProfessionKnowledgeModule = knowledgeTracker.IsProfessionKnowledgeModule
local GetWaypointTarget = knowledgeTracker.GetWaypointTarget
local EnsureGatheringWatchFrame = knowledgeTracker.EnsureGatheringWatchFrame

local function RefreshFonts()
    if ns.EnsureFonts then
        FONT_HEADERS, FONT_ROWS = ns.EnsureFonts()
        return
    end

    FONT_HEADERS = ns.FONT_HEADERS or FONT_HEADERS
    FONT_ROWS = ns.FONT_ROWS or FONT_ROWS
end

local DEFAULT_W = 350
local DEFAULT_H = 450
local MIN_W = 250
local MAX_W = 700
local MIN_H = 150
local MAX_H = 800
local TITLE_H = 22

local PROFESSION_ICONS = {
    alchemy = "Interface\\Icons\\Trade_Alchemy",
    blacksmithing = "Interface\\Icons\\Trade_BlackSmithing",
    enchanting = "Interface\\Icons\\Trade_Engraving",
    engineering = "Interface\\Icons\\Trade_Engineering",
    herbalism = "Interface\\Icons\\Trade_Herbalism",
    inscription = "Interface\\Icons\\INV_Inscription_Tradeskill01",
    jewelcrafting = "Interface\\Icons\\INV_Misc_Gem_01",
    leatherworking = "Interface\\Icons\\Trade_LeatherWorking",
    mining = "Interface\\Icons\\Trade_Mining",
    skinning = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    tailoring = "Interface\\Icons\\Trade_Tailoring",
}

local ALL_EXPANSIONS = MR.isForever and ns.Forever.expansions or ns.AllExpansions

local KNOWLEDGE_EXPANSION_MIDNIGHT_KEY = MR.isForever and "forever" or "midnight"

local function GetKnowledgeExpansionOptions()
    local options = {}
    for _, expansion in ipairs(ALL_EXPANSIONS) do
        options[#options + 1] = { key = expansion.key, label = expansion.label }
    end
    return options
end

local function GetSelectedKnowledgeExpansion()
    local key = MR.db and MR.db.profile and MR.db.profile.gatheringSelectedKnowledgeExpansion
    for _, expansion in ipairs(ALL_EXPANSIONS) do
        if expansion.key == key then
            return key
        end
    end
    return KNOWLEDGE_EXPANSION_MIDNIGHT_KEY
end

local function SetSelectedKnowledgeExpansion(key)
    if not (MR.db and MR.db.profile) then
        return
    end
    MR.db.profile.gatheringSelectedKnowledgeExpansion = key
    PK.RebuildGatheringLocationsFrame(true)
end

local ENTRY_FALLBACK_ICONS = {
    treasure = "Interface\\Icons\\INV_Misc_Map_01",
    study = "Interface\\Icons\\INV_Inscription_Tradeskill01",
    weeklyQuest = "Interface\\Icons\\INV_Misc_Note_01",
    weeklyDrop = "Interface\\Icons\\INV_Box_01",
    darkmoon = "Interface\\Icons\\INV_Misc_Ticket_Tarot_BlueDragon",
    reference = "Interface\\Icons\\INV_Misc_Book_09",
}

local PROFESSIONS = MR.isForever and ns.Forever.professions or ns.MidnightProfessions

local function EntryName(entry)
    if ns.ResolveProfessionEntryLabel then
        local label = ns.ResolveProfessionEntryLabel(entry)
        if label and label ~= "" then return label end
    end
    return entry.label or "|cffaaaaaa...|r"
end

local function GetProfessionTaskDisplayGroup(group)
    if group == "treasures" then
        return "discoveries"
    end
    return group
end

local PROFESSION_TASK_GROUP_ORDER = {
    "weekly",
    "catchup",
    "discoveries",
    "studies",
    "books",
    "darkmoon",
    "lures",
    "other",
}

local function GetProfessionTaskGroupLabel(group)
    if group == "lures" then
        return L["Skin_Lures_Title"] or "Skinning Lures"
    end
    if ns.GetRowGroupLabel then
        return ns.GetRowGroupLabel(group)
    end
    return group
end

local function GetEntryIcon(entry)
    if entry.icon then return entry.icon end
    if entry.itemID and C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(entry.itemID)
        if icon then
            return icon
        end
    end

    return ENTRY_FALLBACK_ICONS[entry.kind] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local waypointAlt = {}
local zoneNameCache = {}

local function GetGatheringZoneName(mapID)
    if not mapID then return L["ProfKnowledge_NoWaypoint"] end
    if zoneNameCache[mapID] then return zoneNameCache[mapID] end
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    local zoneName = (info and info.name) or ("Map " .. tostring(mapID))
    zoneNameCache[mapID] = zoneName
    return zoneName
end

local function SetGatheringWaypoint(entry)
    if not (entry and MR.SetWaypoint) then return false, "Invalid coordinates" end
    return MR:SetWaypoint({
        zone = entry.zone,
        x = entry.x,
        y = entry.y,
        label = entry.label,
        waypointTitle = EntryName(entry),
    })
end

local itemCacheRefreshPending
QueueGatheringLocationsRebuild = function(force)
    local locationsFrame = PK.GetLocationsFrame()
    if not (locationsFrame and locationsFrame:IsShown()) then return end
    if locationsFrame._professionKnowledgeEmptyState and not force then return end
    if itemCacheRefreshPending then return end
    itemCacheRefreshPending = true
    C_Timer.After(0.12, function()
        itemCacheRefreshPending = false
        local currentFrame = PK.GetLocationsFrame()
        if currentFrame and currentFrame:IsShown() then
            PK.RebuildGatheringLocationsFrame()
        end
    end)
end

local function GetProfessionColor(professionKey)
    local colors = MR.db.profile.gatheringProfColors or {}
    local saved = colors[professionKey]
    if saved then return saved[1], saved[2], saved[3] end
    for _, profession in ipairs(PROFESSIONS) do
        if profession.key == professionKey then
            return profession.color[1], profession.color[2], profession.color[3]
        end
    end
    return 1, 1, 1
end

local function StripInlineColor(text)
    text = tostring(text or "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    return text
end

local function NormalizeTooltipLabel(text)
    text = StripInlineColor(text):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return text:lower()
end

local function GetProfessionStateKey(expansionKey, professionKey)
    return tostring(expansionKey or "midnight") .. ":" .. tostring(professionKey or "")
end

local function GetEntryVisibilityId(expansionKey, professionKey, sectionKey, index)
    return expansionKey .. ":" .. professionKey .. ":" .. sectionKey .. ":" .. index
end

local function IsProfessionCardVisible(expansionKey, professionKey)
    local profile = MR.db and MR.db.profile
    local visibility = profile and profile.gatheringProfessionVisibility
    local key = GetProfessionStateKey(expansionKey, professionKey)
    return not (visibility and visibility[key] == false)
end

local function SetProfessionCardVisible(expansionKey, professionKey, visible)
    if not (MR.db and MR.db.profile) then
        return
    end
    MR.db.profile.gatheringProfessionVisibility = MR.db.profile.gatheringProfessionVisibility or {}
    local key = GetProfessionStateKey(expansionKey, professionKey)
    if visible then
        MR.db.profile.gatheringProfessionVisibility[key] = nil
    else
        MR.db.profile.gatheringProfessionVisibility[key] = false
    end
    if MR.RequestProfessionKnowledgeSurfaceRefresh then
        MR:RequestProfessionKnowledgeSurfaceRefresh()
    elseif MR.RefreshProfessionKnowledgeSurfaces then
        MR:RefreshProfessionKnowledgeSurfaces()
    end
    if MR.RepopulateConfigFrame then MR:RepopulateConfigFrame() end
end

ns.IsProfessionKnowledgeProfessionVisible = IsProfessionCardVisible
ns.SetProfessionKnowledgeProfessionVisible = SetProfessionCardVisible

local function MigrateProfessionCollapsedState()
    local profile = MR.db and MR.db.profile
    if not profile or profile.gatheringProfessionCollapsedMigrated then
        return
    end
    local old = profile.gatheringCollapsedProfessions
    if old then
        profile.gatheringProfessionCollapsed = profile.gatheringProfessionCollapsed or {}
        for professionKey, value in pairs(old) do
            local key = GetProfessionStateKey("midnight", professionKey)
            if profile.gatheringProfessionCollapsed[key] == nil then
                profile.gatheringProfessionCollapsed[key] = value
            end
        end
    end
    profile.gatheringProfessionCollapsedMigrated = true
end

local function IsProfessionCollapsed(expansionKey, professionKey)
    local profile = MR.db and MR.db.profile
    if not profile then
        return true
    end
    MigrateProfessionCollapsedState()
    local states = profile.gatheringProfessionCollapsed
    local key = GetProfessionStateKey(expansionKey, professionKey)
    return not (states and states[key] == false)
end

local function SetProfessionCollapsed(expansionKey, professionKey, collapsed)
    if not (MR.db and MR.db.profile) then
        return
    end

    MigrateProfessionCollapsedState()
    MR.db.profile.gatheringProfessionCollapsed = MR.db.profile.gatheringProfessionCollapsed or {}
    local key = GetProfessionStateKey(expansionKey, professionKey)
    if collapsed then
        MR.db.profile.gatheringProfessionCollapsed[key] = nil
    else
        MR.db.profile.gatheringProfessionCollapsed[key] = false
    end
end

local function EntryDisplayLabel(entry, sectionKey)
    if sectionKey == "treasures" and ns.ResolveProfessionEntryLabel and ns.GetCoordinateFallback then
        local fallback = ns.GetCoordinateFallback(entry, L["ProfKnowledge_Section_Discoveries"] or "One-Time Discovery")
        local resolved = ns.ResolveProfessionEntryLabel(entry, fallback, true)
        if resolved and resolved ~= "" then
            return resolved
        end
    end

    local name = EntryName(entry)
    if name and name ~= "|cffaaaaaa...|r" then
        return name
    end
    return entry.note or entry.label or L["ProfKnowledge_WeeklyDrop"] or "Weekly source"
end

PK.waypointLocationIndex = waypointLocationIndex
PK.IsEntryVisible = IsEntryVisible
PK.HasProfessionLearned = HasProfessionLearned
PK.Required = Required
PK.Progress = Progress
PK.IsDone = IsDone
PK.KPTotal = KPTotal
PK.ProfessionStats = ProfessionStats
PK.ProfessionWeeklyStats = ProfessionWeeklyStats
PK.GetProfessionSkillSummary = GetProfessionSkillSummary
PK.GetItemCountRemaining = GetItemCountRemaining
PK.GetProfessionCatchupAmount = GetProfessionCatchupAmount
PK.GetProfessionCatchupProgress = GetProfessionCatchupProgress
PK.GetProfessionTaskRows = GetProfessionTaskRows
PK.IsSkinningLuresModule = IsSkinningLuresModule
PK.IsProfessionKnowledgeModule = IsProfessionKnowledgeModule
PK.GetWaypointTarget = GetWaypointTarget
PK.EnsureGatheringWatchFrame = EnsureGatheringWatchFrame
PK.RefreshFonts = RefreshFonts
PK.DEFAULT_W = DEFAULT_W
PK.DEFAULT_H = DEFAULT_H
PK.MIN_W = MIN_W
PK.MAX_W = MAX_W
PK.MIN_H = MIN_H
PK.MAX_H = MAX_H
PK.TITLE_H = TITLE_H
PK.PROFESSION_ICONS = PROFESSION_ICONS
PK.ALL_EXPANSIONS = ALL_EXPANSIONS
PK.GetKnowledgeExpansionOptions = GetKnowledgeExpansionOptions
PK.GetSelectedKnowledgeExpansion = GetSelectedKnowledgeExpansion
PK.SetSelectedKnowledgeExpansion = SetSelectedKnowledgeExpansion
PK.EntryName = EntryName
PK.GetProfessionTaskDisplayGroup = GetProfessionTaskDisplayGroup
PK.PROFESSION_TASK_GROUP_ORDER = PROFESSION_TASK_GROUP_ORDER
PK.GetProfessionTaskGroupLabel = GetProfessionTaskGroupLabel
PK.GetEntryIcon = GetEntryIcon
PK.waypointAlt = waypointAlt
PK.GetGatheringZoneName = GetGatheringZoneName
PK.SetGatheringWaypoint = SetGatheringWaypoint
PK.GetProfessionColor = GetProfessionColor
PK.StripInlineColor = StripInlineColor
PK.NormalizeTooltipLabel = NormalizeTooltipLabel
PK.GetEntryVisibilityId = GetEntryVisibilityId
PK.IsProfessionCardVisible = IsProfessionCardVisible
PK.SetProfessionCardVisible = SetProfessionCardVisible
PK.IsProfessionCollapsed = IsProfessionCollapsed
PK.SetProfessionCollapsed = SetProfessionCollapsed
PK.EntryDisplayLabel = EntryDisplayLabel

ns.ProfessionKnowledgeInternal = PK
