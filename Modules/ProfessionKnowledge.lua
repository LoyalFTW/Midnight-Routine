local _, ns = ...
local MR = ns.MR

local FONT_HEADERS = ns.FONT_HEADERS
local FONT_ROWS = ns.FONT_ROWS
local StyledFrame = ns.StyledFrame
local RestoreManagedFramePos = ns.RestoreManagedFramePos
local SaveManagedFramePos = ns.SaveManagedFramePos
local SyncManagedFramePos = ns.SyncManagedFramePos
local AnimateManagedFrameHeight = ns.AnimateManagedFrameHeight
local IsManagedHeaderBottom = ns.IsManagedHeaderBottom
local LeftAccent = ns.LeftAccent
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
local hex = ns.Hex
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)

local gatheringLocationsFrame
local gatheringMinimized = false
local gatheringCfgFrame
local PopulateGatheringConfig
local RebuildGatheringLocationsFrame
local configExpandedProfessions = {} 

local function RefreshFonts()
    if ns.EnsureFonts then
        FONT_HEADERS, FONT_ROWS = ns.EnsureFonts()
        return
    end

    FONT_HEADERS = ns.FONT_HEADERS or FONT_HEADERS
    FONT_ROWS = ns.FONT_ROWS or FONT_ROWS
end

local function GetFontFlags()
    if ns.GetFontFlags then
        local flags = ns.GetFontFlags(MR.GetActiveMediaSettings and MR:GetActiveMediaSettings() or (MR.db and MR.db.profile))
        if flags ~= nil then
            return flags
        end
    end

    return "OUTLINE"
end

local DEFAULT_W = 350
local DEFAULT_H = 450
local MIN_W = 250
local MAX_W = 700
local MIN_H = 150
local MAX_H = 800
local TITLE_H = 22


local function IsEntryVisible(entry)
    if entry.kind == "darkmoon" then
        return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() or false
    end
    return true
end

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

local ALL_EXPANSIONS = ns.AllExpansions

local KNOWLEDGE_EXPANSION_MIDNIGHT_KEY = "midnight"

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
    RebuildGatheringLocationsFrame(true)
end

local ENTRY_FALLBACK_ICONS = {
    treasure = "Interface\\Icons\\INV_Misc_Map_01",
    study = "Interface\\Icons\\INV_Inscription_Tradeskill01",
    weeklyQuest = "Interface\\Icons\\INV_Misc_Note_01",
    weeklyDrop = "Interface\\Icons\\INV_Box_01",
    darkmoon = "Interface\\Icons\\INV_Misc_Ticket_Tarot_BlueDragon",
    reference = "Interface\\Icons\\INV_Misc_Book_09",
}

local PROFESSIONS = ns.MidnightProfessions

local RECURRING_SECTION_KEYS = { weekly = true, darkmoon = true, lures = true }

local function IsRecurringSection(section)
    return section and RECURRING_SECTION_KEYS[section.key] == true
end

local function HasProfessionLearned(skillLine, source)
    if source and MR.HasProfessionForModule then
        return MR:HasProfessionForModule(skillLine, source)
    end

    if MR.playerProfessions and MR.playerProfessions[skillLine] then
        return true
    end

    if C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID then
        local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLine)
        if info and (info.skillLevel or 0) > 0 then
            return true
        end
    end

    return false
end

ns.HasProfessionLearned = HasProfessionLearned
function ns.IsProfessionLearnedForSource(profession, source)
    return profession and HasProfessionLearned(profession.skillLine, source) or false
end

local function QuestIDs(entry)
    if entry.questIDs then return entry.questIDs end
    if entry.questID then return { entry.questID } end
    return {}
end

local function Required(entry)
    if entry.mode == "count" then return entry.required or #QuestIDs(entry) end
    return 1
end

local function IsSpellOnCooldown(spellID)
    if not spellID then
        return false
    end

    local startTime, duration = 0, 0
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then
            startTime = info.startTime or 0
            duration = info.duration or 0
        end
    end

    if duration <= 1.5 and GetSpellCooldown then
        local legacyStart, legacyDuration = GetSpellCooldown(spellID)
        startTime = legacyStart or startTime
        duration = legacyDuration or duration
    end

    if duration <= 1.5 then
        return false
    end

    return ((startTime or 0) + duration) > GetTime()
end

ns.IsSpellOnCooldown = IsSpellOnCooldown

local function Completed(entry)
    if entry.spellID then
        return IsSpellOnCooldown(entry.spellID) and 1 or 0
    end

    local total = 0
    for _, questID in ipairs(QuestIDs(entry)) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then total = total + 1 end
    end
    return total
end

local function Progress(entry)
    local completed = Completed(entry)
    local required = Required(entry)
    if entry.mode == "count" then
        return math.min(completed, required), required
    end
    if completed > 0 then return 1, 1 end
    return 0, 1
end

local function IsDone(entry)
    local current, required = Progress(entry)
    return current >= required
end

local function KPDone(entry)
    local current = Progress(entry)
    if entry.mode == "count" then return (entry.kp or 0) * current end
    return current > 0 and (entry.kp or 0) or 0
end

local function KPTotal(entry)
    return (entry.mode == "count" and Required(entry) or 1) * (entry.kp or 0)
end

local function EntryName(entry)
    if ns.ResolveProfessionEntryLabel then
        local label = ns.ResolveProfessionEntryLabel(entry)
        if label and label ~= "" then return label end
    end
    return entry.label or "|cffaaaaaa...|r"
end

local function ProgressText(entry)
    local current, required = Progress(entry)
    if required > 1 then return current .. "/" .. required end
    return current > 0 and (L["Done"] or "Done") or L["ProfKnowledge_StatusPending"]
end

local function SectionStats(section)
    local done, total, kpDone, kpTotal = 0, 0, 0, 0
    for _, entry in ipairs(section.entries) do
        if IsEntryVisible(entry) then
            total = total + 1
            if IsDone(entry) then done = done + 1 end
            kpDone = kpDone + KPDone(entry)
            kpTotal = kpTotal + KPTotal(entry)
        end
    end
    return done, total, kpDone, kpTotal
end

local function SectionHeaderCounts(section)
    local done, trackable = 0, 0
    for _, entry in ipairs(section.entries) do
        if IsEntryVisible(entry) and (entry.questID or entry.questIDs or entry.spellID) then
            trackable = trackable + 1
            if IsDone(entry) then done = done + 1 end
        end
    end
    return done, trackable, #section.entries
end

local function ProfessionStats(profession)
    local done, total, kpDone, kpTotal = 0, 0, 0, 0
    for _, section in ipairs(profession.sections) do
        if not IsRecurringSection(section) then
            local sd, st, skd, skt = SectionStats(section)
            done = done + sd
            total = total + st
            kpDone = kpDone + skd
            kpTotal = kpTotal + skt
        end
    end
    return done, total, kpDone, kpTotal
end

local function ProfessionWeeklyStats(profession)
    local kpDone, kpTotal = 0, 0
    for _, section in ipairs(profession.sections) do
        if IsRecurringSection(section) then
            for _, entry in ipairs(section.entries) do
                if IsEntryVisible(entry) then
                    kpDone = kpDone + KPDone(entry)
                    kpTotal = kpTotal + KPTotal(entry)
                end
            end
        end
    end
    return kpDone, kpTotal
end

local function GetProfessionSkillSummary(skillLineID)
    if not (C_TradeSkillUI and C_TradeSkillUI.GetProfessionInfoBySkillLineID) then
        return nil
    end

    local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
    if not info then
        return nil
    end

    local skill = info.skillLevel or 0
    local maxSkill = info.maxSkillLevel or 0
    if skill <= 0 or maxSkill <= 0 then
        return nil
    end

    local bonus = info.bonusSkillLevel or info.bonusSkill or 0
    if bonus > 0 then
        return string.format("%d/%d +%d", skill, maxSkill, bonus)
    end

    return string.format("%d/%d", skill, maxSkill)
end

local function GetCurrencyRemaining(currencyID)
    if not (currencyID and currencyID > 0 and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return 0
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info then
        return 0
    end

    local maxQuantity = info.maxQuantity or 0
    local quantity = info.quantity or 0
    if maxQuantity > 0 then
        return math.max(maxQuantity - quantity, 0)
    end

    return quantity
end

local function GetItemCountRemaining(itemID)
    if not (itemID and C_Item and C_Item.GetItemCount) then
        return 0
    end
    return C_Item.GetItemCount(itemID, false, false, true) or 0
end

local function GetProfessionCatchupAmount(profession, expansion)
    if profession.catchupCurrency then
        return GetCurrencyRemaining(profession.catchupCurrency)
    end

    if expansion and expansion.sharedCatchupItemID then
        return GetItemCountRemaining(expansion.sharedCatchupItemID)
    end

    return 0
end

local function GetProfessionCatchupProgress(profession)
    if not (profession.catchupCurrency and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return nil
    end
    local info = C_CurrencyInfo.GetCurrencyInfo(profession.catchupCurrency)
    if not info then
        return nil
    end

    if info.maxQuantity and info.maxQuantity > 0 then
        local done = (info.useTotalEarnedForMaxQty and info.totalEarned) or info.quantity or 0
        return done, info.maxQuantity
    elseif info.maxWeeklyQuantity and info.maxWeeklyQuantity > 0 then
        return info.quantityEarnedThisWeek or 0, info.maxWeeklyQuantity
    end

    return nil
end

local function GetProfessionTaskCategory(row)
    local key = row and row.key or ""
    if key:find("treatise") then
        return "treatises"
    elseif key:find("dmf") then
        return "darkmoon"
    elseif key == "prof_catchup" then
        return "catchup"
    elseif key:find("drop") or key:find("rock") or key:find("plumes") or key:find("bone") or key:find("essence") or key:find("shard") or key:find("tail") or key:find("nodule") then
        return "drops"
    elseif key:find("quest") or key:find("notebook") then
        return "quests"
    end

    return "other"
end

local function GetProfessionTaskModules(profession, filterFn)
    local modules = {}
    if not (profession and profession.skillLine and MR.modules) then
        return modules
    end

    for _, mod in ipairs(MR.modules) do
        if mod.profSkillLine == profession.skillLine and MR:IsModuleEnabled(mod.key) then
            local modVisible = not mod.isVisible or mod:isVisible()
            if modVisible and (not filterFn or filterFn(mod)) then
                modules[#modules + 1] = mod
            end
        end
    end

    table.sort(modules, function(a, b)
        return (a.order or 9999) < (b.order or 9999)
    end)
    return modules
end

local function GetProfessionTaskProgress(mod, row)
    local current = MR:GetProgress(mod.key, row.key) or 0
    local max = tonumber(row.max)
    if max and max > 0 and not row.noMax then
        return math.min(current, max), max, current >= max
    end

    return current, nil, current and current > 0
end

local function GetProfessionTaskProgressText(mod, row)
    local current, max, done = GetProfessionTaskProgress(mod, row)
    if max then
        return string.format("%d/%d", current or 0, max)
    end

    if row.max == 0 or row.noMax then
        return tostring(current or 0)
    end

    return done and (L["Done"] or "Done") or (L["ProfKnowledge_StatusPending"] or "Pending")
end

local function GetProfessionTaskRows(profession, filterFn)
    local rows = {}
    local doneCount, totalCount = 0, 0
    local db = MR.db and MR.db.profile or {}

    for _, mod in ipairs(GetProfessionTaskModules(profession, filterFn)) do
        for _, row in ipairs(mod.rows or {}) do
            local rowVisible = not row.isVisible or row.isVisible()
            local category = GetProfessionTaskCategory(row)
            local rowEnabled = MR:IsRowEnabled(mod.key, row.key)
            if rowVisible and rowEnabled then
                local current, max, done = GetProfessionTaskProgress(mod, row)
                if not (done and db.gatheringHideCompleted) then
                    rows[#rows + 1] = {
                        mod = mod,
                        row = row,
                        category = category,
                        group = row.group or category,
                        done = done,
                        current = current,
                        max = max,
                    }
                end
                if max then
                    totalCount = totalCount + 1
                    if done then doneCount = doneCount + 1 end
                end
            end
        end
    end

    return rows, doneCount, totalCount
end

local function IsSkinningLuresModule(mod)
    return mod and mod.key == "skin_lures"
end

local function IsProfessionKnowledgeModule(mod)
    return not IsSkinningLuresModule(mod)
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
    if entry.itemID and C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(entry.itemID)
        if icon then
            return icon
        end
    end

    if entry.itemID then
        local icon = GetItemIcon(entry.itemID)
        if icon then
            return icon
        end
    end

    return ENTRY_FALLBACK_ICONS[entry.kind] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local watchedItemIDs = {}
for _, expansion in ipairs(ALL_EXPANSIONS or {}) do
    for _, profession in ipairs(expansion.professions or {}) do
        for _, section in ipairs(profession.sections or {}) do
            for _, entry in ipairs(section.entries or {}) do
                if entry.itemID then watchedItemIDs[entry.itemID] = true end
            end
        end
    end
end

local waypointAlt = {}
local waypointLocationIndex = {}
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
    local mapID = entry and entry.zone
    local x = entry and entry.x and (entry.x / 100)
    local y = entry and entry.y and (entry.y / 100)
    local tomTom = _G and rawget(_G, "TomTom")
    if not mapID or not x or not y then return false, "Invalid coordinates" end

    if tomTom and tomTom.AddWaypoint then
        local ok = pcall(function()
            tomTom:AddWaypoint(mapID, x, y, { title = EntryName(entry), persistent = false, minimap = true, world = true })
        end)
        if ok then return true, "TomTom" end
    end

    if UiMapPoint and UiMapPoint.CreateFromCoordinates and C_Map and C_Map.SetUserWaypoint then
        local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        if point then
            C_Map.SetUserWaypoint(point)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
            return true, "Blizzard"
        end
    end

    return false, "No waypoint API available"
end

local function GetQuestSpecificLocations(entry)
    local locations = {}
    local seen = {}
    if entry and entry.questLocations then
        for _, questID in ipairs(QuestIDs(entry)) do
            local location = entry.questLocations[questID]
            if location and location.zone and location.x and location.y then
                local key = tostring(location.zone) .. ":" .. tostring(location.x) .. ":" .. tostring(location.y)
                if not seen[key] then
                    seen[key] = true
                    locations[#locations + 1] = location
                end
            end
        end
    end
    return locations
end

local function GetWaypointTarget(entry, cycleKey)
    local locations = GetQuestSpecificLocations(entry)
    if #locations > 0 then
        for _, questID in ipairs(QuestIDs(entry)) do
            if C_QuestLog and C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(questID) then
                local location = entry.questLocations[questID]
                if location and location.zone and location.x and location.y then
                    return location, #locations
                end
            end
        end
        local index = waypointLocationIndex[cycleKey] or 1
        if index < 1 or index > #locations then index = 1 end
        return locations[index], #locations
    end
    if entry and entry.zone and entry.x and entry.y then
        return entry, 1
    end
    return nil, 0
end

local itemCacheFrame = CreateFrame("Frame")
itemCacheFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemCacheFrame:RegisterEvent("QUEST_TURNED_IN")
itemCacheFrame:RegisterEvent("QUEST_LOG_UPDATE")
itemCacheFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
itemCacheFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
itemCacheFrame:RegisterEvent("TRADE_SKILL_SHOW")
itemCacheFrame:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
local itemCacheRefreshPending
local function QueueGatheringLocationsRebuild()
    if not (gatheringLocationsFrame and gatheringLocationsFrame:IsShown()) then return end
    if itemCacheRefreshPending then return end
    itemCacheRefreshPending = true
    C_Timer.After(0.12, function()
        itemCacheRefreshPending = false
        if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then
            RebuildGatheringLocationsFrame()
        end
    end)
end

itemCacheFrame:SetScript("OnEvent", function(self, event, itemID)
    if event == "GET_ITEM_INFO_RECEIVED" then
        if not watchedItemIDs[itemID] then return end
    end
    if event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" then
        if MR.RefreshPlayerProfessions then MR:RefreshPlayerProfessions() end
        if MR.RequestScan then MR:RequestScan(1) end
    end
    QueueGatheringLocationsRebuild()
end)

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

local function ApplyGatheringFrameTheme(frame, opts)
    if not frame then
        return
    end

    opts = opts or {}
    local alpha = opts.alpha or 1
    local bg = opts.bg or { 0.03, 0.05, 0.09, 0.97 * alpha }
    local border = opts.border or { 0.24, 0.31, 0.42, alpha }
    local accent = opts.accent or { 0.18, 0.78, 0.72 }

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

local function RenderEntryRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, entry, sectionKey)
    local current, required = Progress(entry)
    local done = current >= required
    if done and db.gatheringHideCompleted then return cardY end

    local row = CreateFrame("Button", nil, card, "BackdropTemplate")
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
    row:SetSize(cardW - 24, rowHeight + 4)
    row:RegisterForClicks("LeftButtonUp")
    row:SetBackdrop(MakeBackdrop())
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(0, 0, 0, 0)

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(cr, cg, cb, 0)

    local statusBox = CreateFrame("Frame", nil, row, "BackdropTemplate")
    statusBox:SetSize(14, 14)
    statusBox:SetPoint("LEFT", row, "LEFT", 5, 0)
    statusBox:SetBackdrop(MakeBackdrop())
    statusBox:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * contentAlpha)
    if done then
        statusBox:SetBackdropBorderColor(0.24, 0.76, 0.46, 0.95 * chromeAlpha)
    else
        statusBox:SetBackdropBorderColor(0.24, 0.28, 0.34, 0.95 * chromeAlpha)
    end

    local statusFill = statusBox:CreateTexture(nil, "ARTWORK")
    statusFill:SetPoint("TOPLEFT", statusBox, "TOPLEFT", 2, -2)
    statusFill:SetPoint("BOTTOMRIGHT", statusBox, "BOTTOMRIGHT", -2, 2)
    statusFill:SetColorTexture(done and 0.20 or 0.09, done and 0.72 or 0.10, done and 0.42 or 0.14, (done and 0.85 or 0.70) * contentAlpha)

    local statusCheck = statusBox:CreateFontString(nil, "OVERLAY")
    statusCheck:SetFont(FONT_HEADERS, 9, GetFontFlags())
    statusCheck:SetPoint("CENTER", statusBox, "CENTER", 0, 1)
    statusCheck:SetText("x")
    statusCheck:SetTextColor(0.03, 0.08, 0.04, 1)
    statusCheck:SetShown(done)

    local rowIcon = row:CreateTexture(nil, "ARTWORK")
    rowIcon:SetSize(14, 14)
    rowIcon:SetPoint("LEFT", statusBox, "RIGHT", 6, 0)
    rowIcon:SetTexture(GetEntryIcon(entry))
    rowIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local statusText = row:CreateFontString(nil, "OVERLAY")
    statusText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
    statusText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    statusText:SetWidth(46)
    statusText:SetJustifyH("RIGHT")
    if done then
        statusText:SetText(L["Done"] or "Done")
        statusText:SetTextColor(0.32, 0.80, 0.50, 0.95)
    else
        statusText:SetText("+" .. tostring(KPTotal(entry)))
        statusText:SetTextColor(cr, cg, cb, 0.95)
    end

    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
    nameText:SetPoint("LEFT", rowIcon, "RIGHT", 6, 0)
    nameText:SetPoint("RIGHT", statusText, "LEFT", -8, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    nameText:SetText(EntryDisplayLabel(entry, sectionKey))
    nameText:SetTextColor(done and 0.45 or cr, done and 0.45 or cg, done and 0.45 or cb)

    row:SetScript("OnEnter", function()
        hover:SetColorTexture(cr, cg, cb, 0.12 * accentAlpha)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetText(EntryDisplayLabel(entry, sectionKey), 1, 1, 1)
        GameTooltip:AddLine(string.format(L["ProfKnowledge_KPValue"], KPDone(entry), KPTotal(entry)), 0.80, 0.80, 0.90)
        GameTooltip:AddLine(string.format(L["ProfKnowledge_RowProgress"], current, required), 0.70, 0.90, 1)
        local cycleKey = entry.rowKey or entry.itemID or entry.label
        local target, targetCount = GetWaypointTarget(entry, cycleKey)
        if target then
            local altKey = entry.itemID or entry.label
            local useAlt = entry.altZone and waypointAlt[altKey]
            local mapID = useAlt and entry.altZone or target.zone
            local mapX = useAlt and entry.altX or target.x
            local mapY = useAlt and entry.altY or target.y
            GameTooltip:AddLine(" ")
            if target.label then
                GameTooltip:AddLine(target.label, 0.75, 0.90, 1)
            end
            GameTooltip:AddLine(GetGatheringZoneName(mapID), 0.85, 0.85, 0.85)
            GameTooltip:AddLine(string.format(L["Gathering_Coords"], mapX, mapY), 0.7, 1, 0.9)
            if entry.altZone then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["Gathering_AltLocationLabel"], 0.65, 0.65, 0.65)
                GameTooltip:AddLine(GetGatheringZoneName(useAlt and entry.zone or entry.altZone), 0.6, 0.6, 0.6)
                GameTooltip:AddLine(string.format("%.1f, %.1f", useAlt and entry.x or entry.altX, useAlt and entry.y or entry.altY), 0.45, 0.7, 0.55)
            end
        else
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(L["ProfKnowledge_NoWaypoint"], 0.65, 0.65, 0.65)
        end
        if entry.note and entry.note ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(entry.note, 0.65, 0.85, 0.95, true)
        end
        GameTooltip:AddLine(" ")
        if done then
            GameTooltip:AddLine(L["Gathering_AlreadyCollected"], 0, 0.8, 0.27)
        elseif target then
            GameTooltip:AddLine((entry.altZone or targetCount > 1) and L["Gathering_ClickCycleHint"] or L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        hover:SetColorTexture(cr, cg, cb, 0)
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function()
        local cycleKey = entry.rowKey or entry.itemID or entry.label
        local target, targetCount = GetWaypointTarget(entry, cycleKey)
        if not target then return end
        local altKey = entry.itemID or entry.label
        local useAlt = entry.altZone and waypointAlt[altKey]
        target = useAlt and { itemID = entry.itemID, label = entry.label, zone = entry.altZone, x = entry.altX, y = entry.altY } or target
        if entry.altZone then waypointAlt[altKey] = not waypointAlt[altKey] end
        if targetCount > 1 then
            waypointLocationIndex[cycleKey] = ((waypointLocationIndex[cycleKey] or 1) % targetCount) + 1
        end
        local ok, source = SetGatheringWaypoint(target)
        if ok then print(string.format(L["Waypoint_Set"], source, EntryDisplayLabel(entry, sectionKey), target.x, target.y)) else print(L["Waypoint_Unavailable"]) end
    end)

    return cardY + rowHeight + 6
end

local function RenderReferenceRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, cr, cg, cb, entry, sectionKey)
    local row = CreateFrame("Button", nil, card, "BackdropTemplate")
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
    row:SetSize(cardW - 24, rowHeight + 4)
    row:RegisterForClicks("LeftButtonUp")
    row:SetBackdrop(MakeBackdrop())
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(0, 0, 0, 0)

    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(cr, cg, cb, 0)

    local statusBox = CreateFrame("Frame", nil, row, "BackdropTemplate")
    statusBox:SetSize(14, 14)
    statusBox:SetPoint("LEFT", row, "LEFT", 5, 0)
    statusBox:SetBackdrop(MakeBackdrop())
    statusBox:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * contentAlpha)
    statusBox:SetBackdropBorderColor(0.24, 0.28, 0.34, 0.95 * chromeAlpha)

    local statusFill = statusBox:CreateTexture(nil, "ARTWORK")
    statusFill:SetPoint("TOPLEFT", statusBox, "TOPLEFT", 2, -2)
    statusFill:SetPoint("BOTTOMRIGHT", statusBox, "BOTTOMRIGHT", -2, 2)
    statusFill:SetColorTexture(0.09, 0.10, 0.14, 0.70 * contentAlpha)

    local rowIcon = row:CreateTexture(nil, "ARTWORK")
    rowIcon:SetSize(14, 14)
    rowIcon:SetPoint("LEFT", statusBox, "RIGHT", 6, 0)
    rowIcon:SetTexture(GetEntryIcon(entry))
    rowIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local kpText = row:CreateFontString(nil, "OVERLAY")
    kpText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
    kpText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    kpText:SetWidth(46)
    kpText:SetJustifyH("RIGHT")
    kpText:SetText("+" .. tostring(entry.kp or 0))
    kpText:SetTextColor(cr, cg, cb, 0.95)

    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
    nameText:SetPoint("LEFT", rowIcon, "RIGHT", 6, 0)
    nameText:SetPoint("RIGHT", kpText, "LEFT", -8, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    nameText:SetText(EntryDisplayLabel(entry, sectionKey))
    nameText:SetTextColor(cr, cg, cb)

    row:SetScript("OnEnter", function()
        hover:SetColorTexture(cr, cg, cb, 0.12 * chromeAlpha)
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        GameTooltip:SetText(EntryDisplayLabel(entry, sectionKey), 1, 1, 1)
        GameTooltip:AddLine(string.format(L["ProfKnowledge_KPValue"], 0, entry.kp or 0), 0.80, 0.80, 0.90)
        if entry.note and entry.note ~= "" then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(entry.note, 0.70, 0.82, 0.92, true)
        end
        if entry.zone and entry.x and entry.y then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(GetGatheringZoneName(entry.zone), 0.85, 0.85, 0.85)
            GameTooltip:AddLine(string.format(L["Gathering_Coords"], entry.x, entry.y), 0.7, 1, 0.9)
            GameTooltip:AddLine(L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(L["ProfKnowledge_ReferenceOnly"] or "One-time source, not auto-tracked.", 0.6, 0.6, 0.6, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function()
        hover:SetColorTexture(cr, cg, cb, 0)
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function()
        if not (entry.zone and entry.x and entry.y) then return end
        local ok, source = SetGatheringWaypoint(entry)
        if ok then print(string.format(L["Waypoint_Set"], source, EntryDisplayLabel(entry, sectionKey), entry.x, entry.y)) else print(L["Waypoint_Unavailable"]) end
    end)

    return cardY + rowHeight + 6
end

local function RenderCatchupRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, profession, expansion)
    local amount = GetProfessionCatchupAmount(profession, expansion)
    if amount <= 0 then
        return cardY
    end

    local sectionChip = CreateFrame("Frame", nil, card, "BackdropTemplate")
    sectionChip:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
    sectionChip:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -cardY)
    sectionChip:SetHeight(18)
    sectionChip:SetBackdrop(MakeBackdrop())
    sectionChip:SetBackdropColor(0.045, 0.055, 0.095, 0.78 * contentAlpha)
    sectionChip:SetBackdropBorderColor(0, 0, 0, 0)

    local sectionHeader = sectionChip:CreateFontString(nil, "OVERLAY")
    sectionHeader:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
    sectionHeader:SetPoint("LEFT", sectionChip, "LEFT", 6, 0)
    sectionHeader:SetPoint("RIGHT", sectionChip, "RIGHT", -8, 0)
    sectionHeader:SetJustifyH("LEFT")
    sectionHeader:SetWordWrap(false)
    sectionHeader:SetTextColor(0.84, 0.70, 0.95, 0.95)
    sectionHeader:SetText(ns.GetRowGroupLabel and ns.GetRowGroupLabel("catchup") or "Catch-Up Knowledge")
    cardY = cardY + 22

    local row = CreateFrame("Frame", nil, card, "BackdropTemplate")
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
    row:SetSize(cardW - 24, rowHeight + 4)
    row:SetBackdrop(MakeBackdrop())
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(0, 0, 0, 0)

    local statusBox = CreateFrame("Frame", nil, row, "BackdropTemplate")
    statusBox:SetSize(14, 14)
    statusBox:SetPoint("LEFT", row, "LEFT", 5, 0)
    statusBox:SetBackdrop(MakeBackdrop())
    statusBox:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * contentAlpha)
    statusBox:SetBackdropBorderColor(0.24, 0.28, 0.34, 0.95 * chromeAlpha)

    local statusFill = statusBox:CreateTexture(nil, "ARTWORK")
    statusFill:SetPoint("TOPLEFT", statusBox, "TOPLEFT", 2, -2)
    statusFill:SetPoint("BOTTOMRIGHT", statusBox, "BOTTOMRIGHT", -2, 2)
    statusFill:SetColorTexture(0.09, 0.10, 0.14, 0.70 * contentAlpha)

    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", statusBox, "RIGHT", 6, 0)
    local sharedCatchupItemID = expansion and expansion.sharedCatchupItemID
    local currencyInfo = profession.catchupCurrency and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(profession.catchupCurrency)
    local itemIcon = sharedCatchupItemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(sharedCatchupItemID)
    icon:SetTexture(itemIcon or (currencyInfo and currencyInfo.iconFileID) or "Interface\\Icons\\INV_Misc_Coin_01")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local done, max = GetProfessionCatchupProgress(profession)

    local statusText
    if done and max then
        statusText = row:CreateFontString(nil, "OVERLAY")
        statusText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
        statusText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        statusText:SetWidth(56)
        statusText:SetJustifyH("RIGHT")
        statusText:SetText(string.format("%d/%d", done, max))
        if ns.CountColor then
            statusText:SetTextColor(ns.CountColor(done, max))
        else
            statusText:SetTextColor(cr, cg, cb)
        end
    end

    local nameText = row:CreateFontString(nil, "OVERLAY")
    nameText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
    nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    if statusText then
        nameText:SetPoint("RIGHT", statusText, "LEFT", -8, 0)
    else
        nameText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    end
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    nameText:SetText(L["Prof_Catchup"] or "Catch-Up Knowledge")
    nameText:SetTextColor(cr, cg, cb)

    return cardY + rowHeight + 10
end

local function RenderProfessionTasksSection(card, cardW, cardY, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, profession, taskRowsOverride, suppressSingleGroupHeader)
    local taskRows = taskRowsOverride or GetProfessionTaskRows(profession, IsProfessionKnowledgeModule)
    if #taskRows == 0 then
        return cardY
    end

    local grouped = {}
    for _, entry in ipairs(taskRows) do
        local group = GetProfessionTaskDisplayGroup(entry.group or entry.category or "other")
        grouped[group] = grouped[group] or {}
        grouped[group][#grouped[group] + 1] = entry
    end

    local rowHeight = math.max(fontSize + 9, 20)

    local function RenderGroupHeader(label)
        local headerFrame = CreateFrame("Frame", nil, card, "BackdropTemplate")
        headerFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
        headerFrame:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -cardY)
        headerFrame:SetHeight(18)
        headerFrame:SetBackdrop(MakeBackdrop())
        headerFrame:SetBackdropColor(0.045, 0.055, 0.095, 0.78 * contentAlpha)
        headerFrame:SetBackdropBorderColor(0, 0, 0, 0)

        local headerText = headerFrame:CreateFontString(nil, "OVERLAY")
        headerText:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
        headerText:SetPoint("LEFT", headerFrame, "LEFT", 6, 0)
        headerText:SetPoint("RIGHT", headerFrame, "RIGHT", -8, 0)
        headerText:SetJustifyH("LEFT")
        headerText:SetWordWrap(false)
        headerText:SetText(label)
        headerText:SetTextColor(0.84, 0.70, 0.95, 0.95)
        cardY = cardY + 20
    end

    local function RenderTaskRow(task)
        local row = task.row
        local mod = task.mod
        local catchupDone, catchupMax
        if row.key == "prof_catchup" then
            catchupDone, catchupMax = GetProfessionCatchupProgress(profession)
            if catchupMax then
                task.current = catchupDone or 0
                task.max = catchupMax
                task.done = (catchupDone or 0) >= catchupMax
            else
                task.current = row.itemId and GetItemCountRemaining(row.itemId) or (task.current or 0)
                task.max = nil
                task.done = false
            end
        end

        local rr, rg, rb = cr, cg, cb
        local rowColor = MR:GetRowColor(mod.key, row.key) or (row.colorKey and MR:GetRowColor(mod.key, row.colorKey)) or MR:GetHeaderColor(mod.key)
        if rowColor then
            rr, rg, rb = hex(rowColor)
        end

        local taskFrame = CreateFrame("Button", nil, card, "BackdropTemplate")
        taskFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
        taskFrame:SetSize(cardW - 24, rowHeight + 3)
        taskFrame:RegisterForClicks("LeftButtonUp")
        taskFrame:SetBackdrop(MakeBackdrop())
        taskFrame:SetBackdropColor(0, 0, 0, 0)
        taskFrame:SetBackdropBorderColor(0, 0, 0, 0)

        local hover = taskFrame:CreateTexture(nil, "BACKGROUND")
        hover:SetAllPoints()
        hover:SetColorTexture(rr, rg, rb, 0)

        local statusBtn = CreateFrame("Button", nil, taskFrame, "BackdropTemplate")
        statusBtn:SetSize(14, 14)
        statusBtn:SetPoint("LEFT", taskFrame, "LEFT", 5, 0)
        statusBtn:SetBackdrop(MakeBackdrop())

        local statusFill = statusBtn:CreateTexture(nil, "ARTWORK")
        statusFill:SetPoint("TOPLEFT", statusBtn, "TOPLEFT", 2, -2)
        statusFill:SetPoint("BOTTOMRIGHT", statusBtn, "BOTTOMRIGHT", -2, 2)

        local statusCheck = statusBtn:CreateFontString(nil, "OVERLAY")
        statusCheck:SetFont(FONT_HEADERS, 9, GetFontFlags())
        statusCheck:SetPoint("CENTER", statusBtn, "CENTER", 0, 1)
        statusCheck:SetText("x")

        local maxValue = (type(row.max) == "number" and row.max > 0 and row.max)
            or (type(task.max) == "number" and task.max > 0 and task.max)
            or 1
        local canManualToggle = not (row.key == "prof_catchup" and not catchupMax)
        local manualOverride = MR:GetManualOverride(mod.key, row.key) or 0
        local forcedComplete = canManualToggle and maxValue and manualOverride >= maxValue
        local activeDone = forcedComplete and maxValue or (task.current or 0)
        local function ApplyStatus()
            statusBtn:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * contentAlpha)
            if forcedComplete then
                statusBtn:SetBackdropBorderColor(0.88, 0.74, 0.22, 0.95 * chromeAlpha)
                statusFill:SetColorTexture(0.88, 0.74, 0.22, 0.85 * contentAlpha)
                statusCheck:SetTextColor(0.10, 0.08, 0.02, 1)
                statusCheck:Show()
            elseif task.done then
                statusBtn:SetBackdropBorderColor(0.24, 0.76, 0.46, 0.95 * chromeAlpha)
                statusFill:SetColorTexture(0.20, 0.72, 0.42, 0.85 * contentAlpha)
                statusCheck:SetTextColor(0.03, 0.08, 0.04, 1)
                statusCheck:Show()
            elseif maxValue and activeDone > 0 then
                statusBtn:SetBackdropBorderColor(0.62, 0.52, 0.22, 0.95 * chromeAlpha)
                statusFill:SetColorTexture(0.78, 0.62, 0.22, 0.70 * contentAlpha)
                statusCheck:Hide()
            else
                statusBtn:SetBackdropBorderColor(0.24, 0.28, 0.34, 0.95 * chromeAlpha)
                statusFill:SetColorTexture(0.09, 0.10, 0.14, 0.70 * contentAlpha)
                statusCheck:Hide()
            end
        end
        ApplyStatus()
        statusBtn:EnableMouse(canManualToggle)

        local rowIcon = taskFrame:CreateTexture(nil, "ARTWORK")
        rowIcon:SetSize(14, 14)
        rowIcon:SetPoint("LEFT", statusBtn, "RIGHT", 6, 0)
        rowIcon:SetTexture(GetEntryIcon(row))
        rowIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        local valueText = taskFrame:CreateFontString(nil, "OVERLAY")
        valueText:SetFont(FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
        valueText:SetPoint("RIGHT", taskFrame, "RIGHT", -8, 0)
        valueText:SetWidth(row.key == "prof_catchup" and 56 or 44)
        valueText:SetJustifyH("RIGHT")
        valueText:SetWordWrap(false)
        if row.key == "prof_catchup" and catchupDone and catchupMax then
            valueText:SetText(string.format("%d/%d", catchupDone, catchupMax))
            if ns.CountColor then
                valueText:SetTextColor(ns.CountColor(catchupDone, catchupMax))
            else
                valueText:SetTextColor(rr, rg, rb, 0.95)
            end
        elseif row.key == "prof_catchup" then
            valueText:SetText(tostring(task.current or 0))
            valueText:SetTextColor(rr, rg, rb, 0.95)
        elseif task.done then
            valueText:SetText(L["Done"] or "Done")
            valueText:SetTextColor(0.32, 0.80, 0.50, 0.95)
        elseif (row.kpTotal or 0) > 0 then
            valueText:SetText("+" .. tostring(row.kpTotal))
            valueText:SetTextColor(rr, rg, rb, 0.95)
        else
            valueText:SetText("")
        end

        local nameText = taskFrame:CreateFontString(nil, "OVERLAY")
        nameText:SetFont(FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
        nameText:SetPoint("LEFT", rowIcon, "RIGHT", 6, 0)
        nameText:SetPoint("RIGHT", valueText, "LEFT", -8, 0)
        nameText:SetJustifyH("LEFT")
        nameText:SetWordWrap(false)
        nameText:SetText(StripInlineColor(row.label or mod.label or row.key))
        nameText:SetTextColor(task.done and 0.46 or rr, task.done and 0.46 or rg, task.done and 0.46 or rb, task.done and 0.82 or 1)

        taskFrame:SetScript("OnEnter", function()
            hover:SetColorTexture(rr, rg, rb, 0.10 * accentAlpha)
            GameTooltip:SetOwner(taskFrame, "ANCHOR_RIGHT")
            GameTooltip:SetText(StripInlineColor(row.label or mod.label or row.key), 1, 1, 1)
            if row.note and row.note ~= "" then
                GameTooltip:AddLine(row.note, 0.70, 0.82, 0.92, true)
            end
            local target, targetCount = GetWaypointTarget(row, row.key)
            if target then
                GameTooltip:AddLine(" ")
                if target.label then
                    GameTooltip:AddLine(target.label, 0.75, 0.90, 1)
                end
                GameTooltip:AddLine(GetGatheringZoneName(target.zone), 0.85, 0.85, 0.85)
                GameTooltip:AddLine(string.format(L["Gathering_Coords"], target.x, target.y), 0.7, 1, 0.9)
                GameTooltip:AddLine(targetCount > 1 and L["Gathering_ClickCycleHint"] or L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
            end
            GameTooltip:Show()
        end)
        taskFrame:SetScript("OnLeave", function()
            hover:SetColorTexture(rr, rg, rb, 0)
            GameTooltip:Hide()
        end)
        taskFrame:SetScript("OnClick", function()
            local target, targetCount = GetWaypointTarget(row, row.key)
            if target then
                if targetCount > 1 then
                    waypointLocationIndex[row.key] = ((waypointLocationIndex[row.key] or 1) % targetCount) + 1
                end
                local ok, source = SetGatheringWaypoint(target)
                if ok then
                    print(string.format(L["Waypoint_Set"], source, StripInlineColor(row.label or mod.label or row.key), target.x, target.y))
                else
                    print(L["Waypoint_Unavailable"])
                end
            end
        end)
        statusBtn:SetScript("OnClick", function()
            if not canManualToggle then return end
            local currentOverride = MR:GetManualOverride(mod.key, row.key) or 0
            MR:SetManualOverride(mod.key, row.key, currentOverride >= maxValue and 0 or maxValue, maxValue)
            RebuildGatheringLocationsFrame()
            if MR.RefreshUI then
                MR:RefreshUI()
            end
        end)
        statusBtn:SetScript("OnEnter", function()
            if not canManualToggle then return end
            hover:SetColorTexture(rr, rg, rb, 0.10 * accentAlpha)
            GameTooltip:SetOwner(statusBtn, "ANCHOR_RIGHT")
            GameTooltip:SetText(StripInlineColor(row.label or mod.label or row.key), 1, 1, 1)
            GameTooltip:AddLine(" ")
            if forcedComplete then
                GameTooltip:AddLine(L["Tooltip_ManualDot_Active"] or "Manually marked complete. Click to clear.", 1, 0.85, 0.1, true)
            else
                GameTooltip:AddLine(L["Tooltip_ManualDot_Hint"] or "Click to manually mark complete.", 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()
        end)
        statusBtn:SetScript("OnLeave", function()
            hover:SetColorTexture(rr, rg, rb, 0)
            GameTooltip:Hide()
        end)

        cardY = cardY + rowHeight + 3
    end

    for _, group in ipairs(PROFESSION_TASK_GROUP_ORDER) do
        local groupRows = grouped[group]
        if groupRows and #groupRows > 0 then
            if not suppressSingleGroupHeader then
                RenderGroupHeader(GetProfessionTaskGroupLabel(group))
            end
            for _, task in ipairs(groupRows) do
                RenderTaskRow(task)
            end
            cardY = cardY + 3
        end
    end

    return cardY
end

local function RenderSkinningLuresCard(content, width, yOff, fontSize, contentAlpha, chromeAlpha, accentAlpha, db, expansion, profession)
    local taskRows, taskDone, taskTotal = GetProfessionTaskRows(profession, IsSkinningLuresModule)
    if #taskRows == 0 then
        return yOff
    end

    local cr, cg, cb = GetProfessionColor(profession.key)
    local cardW = math.max(1, width - 20)
    local collapsedRowH = math.max(24, fontSize + 15)
    local collapsedIconSize = math.max(16, math.min(20, fontSize + 7))
    local collapseKey = profession.key .. "_lures"
    local isCollapsed = IsProfessionCollapsed(expansion.key, collapseKey)

    local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
    card:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -yOff)
    card:SetWidth(cardW)
    card:SetBackdrop(MakeBackdrop())
    card:SetBackdropColor(0.018, 0.022, 0.028, (isCollapsed and 0.58 or 0.86) * contentAlpha)
    card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)

    local iconPlate = CreateFrame("Frame", nil, card, "BackdropTemplate")
    iconPlate:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
    iconPlate:SetSize(28, 28)
    iconPlate:SetBackdrop(MakeBackdrop())
    iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.95 * chromeAlpha)
    iconPlate:SetBackdropBorderColor(cr * 0.55, cg * 0.55, cb * 0.55, 0.85 * chromeAlpha)

    local iconTex = iconPlate:CreateTexture(nil, "ARTWORK")
    iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
    iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
    iconTex:SetTexture(PROFESSION_ICONS[profession.key] or "Interface\\Icons\\INV_Misc_QuestionMark")
    iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local cardGlow = card:CreateTexture(nil, "BACKGROUND")
    cardGlow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    cardGlow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    cardGlow:SetColorTexture(1, 1, 1, isCollapsed and 0 or (0.025 * contentAlpha))

    local header = card:CreateFontString(nil, "OVERLAY")
    header:SetFont(FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
    if isCollapsed then
        iconPlate:ClearAllPoints()
        iconPlate:SetPoint("LEFT", card, "LEFT", 7, 0)
        iconPlate:SetSize(collapsedIconSize, collapsedIconSize)
        iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.70 * chromeAlpha)
        iconPlate:SetBackdropBorderColor(cr * 0.42, cg * 0.42, cb * 0.42, 0.70 * chromeAlpha)
        iconTex:ClearAllPoints()
        iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
        iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
        header:SetPoint("LEFT", iconPlate, "RIGHT", 6, 0)
        header:SetPoint("RIGHT", card, "RIGHT", -118, 0)
    else
        header:SetPoint("TOPLEFT", iconPlate, "TOPRIGHT", 8, -1)
        header:SetPoint("TOPRIGHT", card, "TOPRIGHT", -128, -1)
    end
    header:SetJustifyH("LEFT")
    header:SetWordWrap(false)
    header:SetTextColor(0.96, 0.97, 0.98, 1)
    header:SetText(L["Skin_Lures_Title"] or "Skinning Lures")

    local headerMeta = card:CreateFontString(nil, "OVERLAY")
    headerMeta:SetFont(FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
    if isCollapsed then
        headerMeta:SetPoint("RIGHT", card, "RIGHT", -10, 0)
        headerMeta:SetWidth(106)
    else
        headerMeta:SetPoint("TOPRIGHT", card, "TOPRIGHT", -30, -10)
        headerMeta:SetWidth(98)
    end
    headerMeta:SetJustifyH("RIGHT")
    headerMeta:SetWordWrap(false)
    headerMeta:SetTextColor(0.88, 0.91, 0.94, 0.95)
    headerMeta:SetText(string.format("%d / %d", taskDone, taskTotal))

    local collapseBtn = CreateFrame("Button", nil, card)
    collapseBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -7, -8)
    collapseBtn:SetSize(18, 18)
    collapseBtn:RegisterForClicks("LeftButtonUp")

    local collapseLbl = collapseBtn:CreateFontString(nil, "OVERLAY")
    collapseLbl:SetFont(FONT_HEADERS, math.max(10, fontSize), GetFontFlags())
    collapseLbl:SetPoint("CENTER")
    collapseLbl:SetText(isCollapsed and "+" or "-")
    collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
    collapseBtn:SetShown(not isCollapsed)

    local function ToggleLuresCard()
        SetProfessionCollapsed(expansion.key, collapseKey, not IsProfessionCollapsed(expansion.key, collapseKey))
        RebuildGatheringLocationsFrame()
    end

    local headerHit = CreateFrame("Button", nil, card)
    headerHit:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    headerHit:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    headerHit:SetHeight(isCollapsed and collapsedRowH or 44)
    headerHit:RegisterForClicks("LeftButtonUp")
    headerHit:SetScript("OnClick", ToggleLuresCard)
    headerHit:SetScript("OnEnter", function()
        card:SetBackdropBorderColor(cr * 0.52, cg * 0.52, cb * 0.52, math.min(1, chromeAlpha + 0.15) * chromeAlpha)
        collapseLbl:SetTextColor(1, 1, 1, 1)
    end)
    headerHit:SetScript("OnLeave", function()
        card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)
        collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
    end)
    collapseBtn:SetScript("OnClick", ToggleLuresCard)

    local cardY = isCollapsed and collapsedRowH or 36
    if not isCollapsed then
        cardY = RenderProfessionTasksSection(card, cardW, cardY, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, profession, taskRows, true)
    end

    card:SetHeight(isCollapsed and collapsedRowH or (cardY + 8))
    return yOff + card:GetHeight() + (isCollapsed and 3 or 8)
end

local function BuildProfessionCards(content, width, yOff, fontSize, contentAlpha, borderAlpha, chromeAlpha, accentAlpha, db, filterExpansionKey)
    local professionSource = MR.GetMainFrameProgressSource and MR:GetMainFrameProgressSource() or nil
    for _, expansion in ipairs(ALL_EXPANSIONS) do
      if not filterExpansionKey or expansion.key == filterExpansionKey then
        local learnedProfessions = {}
        for _, profession in ipairs(expansion.professions) do
            if HasProfessionLearned(profession.skillLine, professionSource) then
                learnedProfessions[#learnedProfessions + 1] = profession
            end
        end

        local visibleProfessions = {}
        for _, profession in ipairs(learnedProfessions) do
            if IsProfessionCardVisible(expansion.key, profession.key) then
                visibleProfessions[#visibleProfessions + 1] = profession
            end
        end

        for _, profession in ipairs(visibleProfessions) do
                local doneSources, totalSources, kpDone, kpTotal = ProfessionStats(profession)
                local weeklyDone, weeklyTotal = ProfessionWeeklyStats(profession)
                local weeklyRemaining = math.max(0, weeklyTotal - weeklyDone)
                local catchupAmount = GetProfessionCatchupAmount(profession, expansion)
                local skillSummary = GetProfessionSkillSummary(profession.skillLine)
                local isCollapsed = IsProfessionCollapsed(expansion.key, profession.key)
                local _, taskDone, taskTotal = GetProfessionTaskRows(profession, IsProfessionKnowledgeModule)
                local useTaskHeader = taskTotal > 0
                local cr, cg, cb = GetProfessionColor(profession.key)
                local cardW = math.max(1, width - 20)
                local collapsedRowH = math.max(24, fontSize + 15)
                local collapsedIconSize = math.max(16, math.min(20, fontSize + 7))
                local headerRightPad = useTaskHeader and 128 or 96

                local card = CreateFrame("Frame", nil, content, "BackdropTemplate")
                card:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -yOff)
                card:SetWidth(cardW)
                card:SetBackdrop(MakeBackdrop())
                card:SetBackdropColor(0.018, 0.022, 0.028, (isCollapsed and 0.58 or 0.86) * contentAlpha)
                card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)

                local iconPlate = CreateFrame("Frame", nil, card, "BackdropTemplate")
                iconPlate:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
                iconPlate:SetSize(28, 28)
                iconPlate:SetBackdrop(MakeBackdrop())
                iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.95 * chromeAlpha)
                iconPlate:SetBackdropBorderColor(cr * 0.55, cg * 0.55, cb * 0.55, 0.85 * chromeAlpha)

                local iconTex = iconPlate:CreateTexture(nil, "ARTWORK")
                iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
                iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
                iconTex:SetTexture(PROFESSION_ICONS[profession.key] or "Interface\\Icons\\INV_Misc_QuestionMark")
                iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

                local cardGlow = card:CreateTexture(nil, "BACKGROUND")
                cardGlow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
                cardGlow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
                cardGlow:SetColorTexture(1, 1, 1, isCollapsed and 0 or (0.025 * contentAlpha))

                local header = card:CreateFontString(nil, "OVERLAY")
                header:SetFont(FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
                if isCollapsed then
                    iconPlate:ClearAllPoints()
                    iconPlate:SetPoint("LEFT", card, "LEFT", 7, 0)
                    iconPlate:SetSize(collapsedIconSize, collapsedIconSize)
                    iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.70 * chromeAlpha)
                    iconPlate:SetBackdropBorderColor(cr * 0.42, cg * 0.42, cb * 0.42, 0.70 * chromeAlpha)
                    iconTex:ClearAllPoints()
                    iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
                    iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
                    header:SetPoint("LEFT", iconPlate, "RIGHT", 6, 0)
                    header:SetPoint("RIGHT", card, "RIGHT", -(useTaskHeader and 118 or 64), 0)
                else
                    header:SetPoint("TOPLEFT", iconPlate, "TOPRIGHT", 8, -1)
                    header:SetPoint("TOPRIGHT", card, "TOPRIGHT", -headerRightPad, -1)
                end
                header:SetJustifyH("LEFT")
                header:SetWordWrap(false)
                header:SetTextColor(0.96, 0.97, 0.98, 1)
                header:SetText(profession.label)

                local headerSub = card:CreateFontString(nil, "OVERLAY")
                headerSub:SetFont(FONT_ROWS, math.max(8, fontSize - 2), GetFontFlags())
                headerSub:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
                headerSub:SetPoint("RIGHT", card, "RIGHT", -12, 0)
                headerSub:SetJustifyH("LEFT")
                headerSub:SetTextColor(0.66, 0.72, 0.78, 0.95)
                headerSub:SetWordWrap(false)

                local headerMeta = card:CreateFontString(nil, "OVERLAY")
                headerMeta:SetFont(FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
                if isCollapsed then
                    headerMeta:SetPoint("RIGHT", card, "RIGHT", -10, 0)
                    headerMeta:SetWidth(useTaskHeader and 106 or 48)
                else
                    headerMeta:SetPoint("TOPRIGHT", card, "TOPRIGHT", -30, -10)
                    headerMeta:SetWidth(useTaskHeader and 98 or 64)
                end
                headerMeta:SetJustifyH("RIGHT")
                headerMeta:SetWordWrap(false)
                headerMeta:SetTextColor(0.88, 0.91, 0.94, 0.95)
                headerMeta:SetText(useTaskHeader and string.format("%d / %d", taskDone, taskTotal) or string.format("%d/%d", doneSources, totalSources))

                local collapseBtn = CreateFrame("Button", nil, card)
                collapseBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -7, -8)
                collapseBtn:SetSize(18, 18)
                collapseBtn:RegisterForClicks("LeftButtonUp")

                local collapseLbl = collapseBtn:CreateFontString(nil, "OVERLAY")
                collapseLbl:SetFont(FONT_HEADERS, math.max(10, fontSize), GetFontFlags())
                collapseLbl:SetPoint("CENTER")
                collapseLbl:SetText(isCollapsed and "+" or "-")
                collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
                collapseBtn:SetShown(not isCollapsed)

                local function ToggleProfessionCard()
                    SetProfessionCollapsed(expansion.key, profession.key, not IsProfessionCollapsed(expansion.key, profession.key))
                    RebuildGatheringLocationsFrame()
                end

                local headerHit = CreateFrame("Button", nil, card)
                headerHit:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
                headerHit:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
                headerHit:SetHeight(isCollapsed and collapsedRowH or 44)
                headerHit:RegisterForClicks("LeftButtonUp")
                headerHit:SetScript("OnClick", ToggleProfessionCard)
                headerHit:SetScript("OnEnter", function()
                    card:SetBackdropBorderColor(cr * 0.52, cg * 0.52, cb * 0.52, math.min(1, chromeAlpha + 0.15) * chromeAlpha)
                    collapseLbl:SetTextColor(1, 1, 1, 1)
                end)
                headerHit:SetScript("OnLeave", function()
                    card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)
                    collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
                end)
                collapseBtn:SetScript("OnClick", ToggleProfessionCard)

                if isCollapsed then
                    headerSub:Hide()
                    headerMeta:SetText(useTaskHeader and string.format("%d / %d", taskDone, taskTotal) or string.format("%d/%d", doneSources, totalSources))
                else
                    if useTaskHeader then
                        headerSub:Hide()
                        headerMeta:SetText(string.format("%d / %d", taskDone, taskTotal))
                    else
                        local catchupHidden
                        local moduleKey = ns.GetProfessionModuleKey and ns.GetProfessionModuleKey(expansion.key, profession) or ("prof_" .. profession.key)
                        if moduleKey then
                            catchupHidden = not MR:IsRowEnabled(moduleKey, "prof_catchup")
                        else
                            catchupHidden = db.gatheringEntryVisibility and db.gatheringEntryVisibility["prof_catchup"] == false
                        end
                        if catchupHidden then
                            headerSub:SetText(string.format(L["ProfKnowledge_HeaderSubFormatNoCatchup"] or "Skill %s   Weekly +%d", skillSummary or "--", weeklyRemaining))
                        else
                            headerSub:SetText(string.format(L["ProfKnowledge_HeaderSubFormat"], skillSummary or "--", weeklyRemaining, catchupAmount))
                        end
                        headerMeta:SetText(string.format("%d/%d KP", kpDone, kpTotal))
                    end
                end

                local cardY = isCollapsed and collapsedRowH or 54

                if not isCollapsed then
                    local rowHeight = math.max(fontSize + 11, 22)
                    if taskTotal > 0 then
                        cardY = RenderProfessionTasksSection(card, cardW, cardY, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, profession)
                    else
                    local entryVisibility = db.gatheringEntryVisibility
                    local catchupRendered = false
                    for _, section in ipairs(GetOrderedProfessionSections(profession)) do
                        if ShouldShowProfessionSection(section) then
                        local visibleEntries = {}
                        local mainMenuKey = ns.GetEntryMainMenuKey
                        for i, entry in ipairs(section.entries) do
                            local rowKey = mainMenuKey and mainMenuKey(section.key, entry)
                            local visible
                            if rowKey then
                                local modKey = (section.key == "lures") and "skin_lures"
                                    or (ns.GetProfessionModuleKey and ns.GetProfessionModuleKey(expansion.key, profession))
                                    or ("prof_" .. profession.key)
                                visible = MR:IsRowEnabled(modKey, rowKey)
                            else
                                local entryId = GetEntryVisibilityId(expansion.key, profession.key, section.key, i)
                                visible = not (entryVisibility and entryVisibility[entryId] == false)
                            end
                            if visible then
                                visibleEntries[#visibleEntries + 1] = entry
                            end
                        end

                        if #visibleEntries > 0 then
                            local sectionChip = CreateFrame("Frame", nil, card, "BackdropTemplate")
                            sectionChip:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
                            sectionChip:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -cardY)
                            sectionChip:SetHeight(18)
                            sectionChip:SetBackdrop(MakeBackdrop())
                            sectionChip:SetBackdropColor(0.045, 0.055, 0.095, 0.78 * contentAlpha)
                            sectionChip:SetBackdropBorderColor(0, 0, 0, 0)

                            local sectionHeader = sectionChip:CreateFontString(nil, "OVERLAY")
                            sectionHeader:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
                            sectionHeader:SetPoint("LEFT", sectionChip, "LEFT", 6, 0)
                            sectionHeader:SetPoint("RIGHT", sectionChip, "RIGHT", -8, 0)
                            sectionHeader:SetJustifyH("LEFT")
                            sectionHeader:SetWordWrap(false)
                            sectionHeader:SetTextColor(0.84, 0.70, 0.95, 0.95)
                            sectionHeader:SetText(section.label)
                            cardY = cardY + 22

                            for _, entry in ipairs(VisibleSortedEntries(visibleEntries)) do
                                local rr, rg, rb = GetMainMenuEntryColor(expansion.key, profession, section.key, entry, cr, cg, cb)
                                if entry.questID or entry.questIDs or entry.spellID then
                                    cardY = RenderEntryRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, rr, rg, rb, db, entry, section.key)
                                else
                                    cardY = RenderReferenceRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, rr, rg, rb, entry, section.key)
                                end
                            end
                            cardY = cardY + 4
                        end
                        if section.key == "weekly" and not catchupRendered then
                            cardY = RenderCatchupRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, profession, expansion)
                            catchupRendered = true
                        end
                        end
                    end
                    if not catchupRendered then
                        cardY = RenderCatchupRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, profession, expansion)
                    end
                    end
                end

                card:SetHeight(isCollapsed and collapsedRowH or (cardY + 8))
                yOff = yOff + card:GetHeight() + (isCollapsed and 3 or 8)
                if expansion.key == "midnight" and profession.key == "skinning" then
                    yOff = RenderSkinningLuresCard(content, width, yOff, fontSize, contentAlpha, chromeAlpha, accentAlpha, db, expansion, profession)
                end
        end

        if #visibleProfessions > 0 and expansion.sharedCatchupItemID then
            local shardCount = GetItemCountRemaining(expansion.sharedCatchupItemID)
            local shardRow = content:CreateFontString(nil, "OVERLAY")
            shardRow:SetFont(FONT_ROWS, fontSize - 1, GetFontFlags())
            shardRow:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -yOff)
            shardRow:SetTextColor(0.70, 0.85, 1.00, 0.90)
            shardRow:SetText(string.format(L["ProfKnowledge_LegacyDragonShard"] or "Dragon Shards of Knowledge: %d", shardCount))
            yOff = yOff + 18 + 6
        end
      end
    end

    return yOff
end

local function BuildKnowledgeExpansionDropdown(parent, opts)
    opts = opts or {}

    local function ResolveDropdownFontSize()
        if type(opts.fontSize) == "function" then
            return opts.fontSize() or 8
        end

        if type(opts.fontSize) == "number" then
            return opts.fontSize
        end

        local db = MR.db and MR.db.profile or {}
        return math.max(8, db.gatheringFontSize or db.fontSize or 9)
    end

    local function ResolveDropdownAlpha()
        if type(opts.alpha) == "function" then
            local value = opts.alpha()
            if type(value) == "number" then
                return math.max(0, math.min(value, 1))
            end
        elseif type(opts.alpha) == "number" then
            return math.max(0, math.min(opts.alpha, 1))
        end

        return 1
    end

    local function EstimateDropdownTextWidth(text, fontSize)
        text = tostring(text or "")
        return (#text * math.max(fontSize or 8, 8) * 0.58) + 34
    end

    local function ResolveOptionListWidth(optionList, fontSize)
        local width = opts.width or 78
        for _, option in ipairs(optionList or {}) do
            width = math.max(width, EstimateDropdownTextWidth(option.label, fontSize))
        end
        return math.min(opts.maxWidth or 220, math.ceil(width))
    end

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(opts.width or 78, opts.height or 18)
    btn:SetBackdrop(MakeBackdrop())
    btn:SetBackdropColor(0.05, 0.12, 0.20, 0.95)
    btn:SetBackdropBorderColor(0.40, 0.32, 0.18, 1)

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT_ROWS, ResolveDropdownFontSize(), GetFontFlags())
    label:SetPoint("LEFT", btn, "LEFT", 6, 0)
    label:SetPoint("RIGHT", btn, "RIGHT", -14, 0)
    label:SetJustifyH("LEFT")
    label:SetTextColor(0.90, 0.80, 0.55)
    btn._label = label

    local caret = btn:CreateFontString(nil, "OVERLAY")
    caret:SetFont(FONT_HEADERS, math.max(9, ResolveDropdownFontSize() + 1), GetFontFlags())
    caret:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
    caret:SetText("v")
    caret:SetTextColor(0.85, 0.75, 0.55)
    btn._caret = caret

    local popup = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(50)
    popup:SetBackdrop(MakeBackdrop())
    popup:SetBackdropColor(0.04, 0.09, 0.15, 0.98)
    popup:SetBackdropBorderColor(0.40, 0.32, 0.18, 1)
    popup:Hide()
    popup.buttons = {}

    function btn:ApplyFonts()
        local labelSize = ResolveDropdownFontSize()
        local caretSize = math.max(9, labelSize + 1)
        local rowHeight = math.max(18, labelSize + 10)
        local minWidth = opts.width or 78
        local maxWidth = opts.maxWidth or 220
        local minHeight = opts.height or 18
        local maxHeight = opts.maxHeight or minHeight
        local alpha = ResolveDropdownAlpha()

        self:SetHeight(math.min(maxHeight, math.max(minHeight, labelSize + 6)))
        self:SetBackdropColor(0.05, 0.12, 0.20, 0.95 * alpha)
        self:SetBackdropBorderColor(0.40, 0.32, 0.18, alpha)
        if self._label then
            self._label:SetFont(FONT_ROWS, labelSize, GetFontFlags())
            local textWidth = math.max((self._label:GetStringWidth() or 0) + 30, EstimateDropdownTextWidth(self._label:GetText(), labelSize))
            self:SetWidth(math.max(minWidth, math.min(maxWidth, math.ceil(textWidth))))
        end
        if self._caret then
            self._caret:SetFont(FONT_HEADERS, caretSize, GetFontFlags())
        end

        for _, row in ipairs(popup.buttons) do
            if row._label then
                row._label:SetFont(FONT_ROWS, labelSize, GetFontFlags())
            end
            if row._check then
                row._check:SetFont(FONT_HEADERS, caretSize, GetFontFlags())
            end
            row:SetHeight(rowHeight)
        end
    end

    local dismiss = CreateFrame("Frame", nil, UIParent)
    dismiss:SetAllPoints(UIParent)
    dismiss:SetFrameStrata("DIALOG")
    dismiss:SetFrameLevel(49)
    dismiss:EnableMouse(true)
    dismiss:Hide()
    dismiss:SetScript("OnMouseDown", function()
        popup:Hide()
        dismiss:Hide()
    end)

    btn:SetScript("OnEnter", function(selfBtn)
        local alpha = ResolveDropdownAlpha()
        selfBtn:SetBackdropColor(0.08, 0.18, 0.28, 0.98 * alpha)
        selfBtn:SetBackdropBorderColor(0.85, 0.70, 0.35, alpha)
    end)
    btn:SetScript("OnLeave", function(selfBtn)
        local alpha = ResolveDropdownAlpha()
        selfBtn:SetBackdropColor(0.05, 0.12, 0.20, 0.95 * alpha)
        selfBtn:SetBackdropBorderColor(0.40, 0.32, 0.18, alpha)
    end)

    function btn:Update()
        local optionList = opts.getOptions()
        local selectedKey = opts.getSelected()
        for _, option in ipairs(optionList) do
            if option.key == selectedKey then
                self._label:SetText(option.label)
                break
            end
        end
        self:ApplyFonts()
    end

    local function EnsurePopupButton(index)
        local row = popup.buttons[index]
        if row then
            return row
        end

        row = CreateFrame("Button", nil, popup, "BackdropTemplate")
        row:SetHeight(18)
        row:SetBackdrop(MakeBackdrop())
        row:SetBackdropColor(0.05, 0.12, 0.20, 0.94)
        row:SetBackdropBorderColor(0.12, 0.26, 0.32, 0.95)

        row._label = row:CreateFontString(nil, "OVERLAY")
        row._label:SetFont(FONT_ROWS, ResolveDropdownFontSize(), GetFontFlags())
        row._label:SetPoint("LEFT", row, "LEFT", 8, 1)
        row._label:SetPoint("RIGHT", row, "RIGHT", -22, 1)
        row._label:SetJustifyH("LEFT")

        row._check = row:CreateFontString(nil, "OVERLAY")
        row._check:SetFont(FONT_HEADERS, math.max(9, ResolveDropdownFontSize() + 1), GetFontFlags())
        row._check:SetPoint("RIGHT", row, "RIGHT", -7, 1)

        row:SetScript("OnEnter", function(selfRow)
            local alpha = ResolveDropdownAlpha()
            selfRow:SetBackdropColor(0.08, 0.18, 0.28, 0.98 * alpha)
            selfRow:SetBackdropBorderColor(0.85, 0.70, 0.35, alpha)
        end)
        row:SetScript("OnLeave", function(selfRow)
            local active = selfRow._checked == true
            local alpha = ResolveDropdownAlpha()
            selfRow:SetBackdropColor(active and 0.10 or 0.05, active and 0.22 or 0.12, active and 0.30 or 0.20, (active and 0.98 or 0.94) * alpha)
            selfRow:SetBackdropBorderColor(active and 0.55 or 0.12, active and 0.46 or 0.26, active and 0.20 or 0.32, (active and 1 or 0.95) * alpha)
        end)

        popup.buttons[index] = row
        return row
    end

    btn:SetScript("OnClick", function(selfBtn)
        local optionList = opts.getOptions()
        if #optionList <= 1 then
            return
        end

        local selectedKey = opts.getSelected()
        local labelSize = ResolveDropdownFontSize()
        local rowHeight = math.max(18, labelSize + 10)
        selfBtn:ApplyFonts()
        local rowWidth = math.max(selfBtn:GetWidth(), ResolveOptionListWidth(optionList, labelSize), 130)
        popup:ClearAllPoints()
        popup:SetPoint("TOPLEFT", selfBtn, "BOTTOMLEFT", 0, -4)
        popup:SetSize(rowWidth, (#optionList * (rowHeight + 2)) + 6)
        local menuAlpha = ResolveDropdownAlpha()
        popup:SetBackdropColor(0.04, 0.09, 0.15, 0.98 * menuAlpha)
        popup:SetBackdropBorderColor(0.40, 0.32, 0.18, menuAlpha)

        for index, option in ipairs(optionList) do
            local row = EnsurePopupButton(index)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", popup, "TOPLEFT", 3, -3 - ((index - 1) * (rowHeight + 2)))
            row:SetSize(rowWidth - 6, rowHeight)
            row._checked = option.key == selectedKey
            row._label:SetText(option.label)
            row._label:SetTextColor(row._checked and 0.96 or 0.85, row._checked and 0.90 or 0.80, row._checked and 0.65 or 0.75)
            row._check:SetText(row._checked and "x" or "")
            row._check:SetTextColor(0.90, 0.80, 0.55)
            row:SetBackdropColor(row._checked and 0.10 or 0.05, row._checked and 0.22 or 0.12, row._checked and 0.30 or 0.20, (row._checked and 0.98 or 0.94) * menuAlpha)
            row:SetBackdropBorderColor(row._checked and 0.55 or 0.12, row._checked and 0.46 or 0.26, row._checked and 0.20 or 0.32, (row._checked and 1 or 0.95) * menuAlpha)
            row:SetScript("OnClick", function()
                opts.onSelect(option.key)
                popup:Hide()
                dismiss:Hide()
            end)
            row:Show()
        end

        for index = #optionList + 1, #popup.buttons do
            popup.buttons[index]:Hide()
        end

        if popup:IsShown() then
            popup:Hide()
            dismiss:Hide()
        else
            dismiss:Show()
            popup:Show()
        end
    end)

    return btn
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
    RefreshFonts()
    local db = MR.db and MR.db.profile or {}
    local hadProfCache = MR.playerProfessions and next(MR.playerProfessions) ~= nil
    if not hadProfCache and MR.RefreshPlayerProfessions then MR:RefreshPlayerProfessions() end
    local hasProfCache = MR.playerProfessions and next(MR.playerProfessions) ~= nil
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
    titleBar:SetBackdropColor(0, 0, 0, 0)
    titleBar:ClearAllPoints()
    if headerBottom then
        titleBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
        titleBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    else
        titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    end
    titleBar:SetScript("OnDragStart", function() if not db.gatheringLocked then frame:StartMoving() end end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        SaveManagedFramePos(frame, "gatheringLocPos", headerBottom and "bottom" or "top")
    end)
    if MR.ApplyPanelHeaderAutoHide then MR:ApplyPanelHeaderAutoHide(frame, titleBar) end

    local titleIcon = titleBar:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(16, 16)
    titleIcon:SetPoint("LEFT", titleBar, "LEFT", 9, 0)
    titleIcon:SetTexture("Interface\\AddOns\\MidnightRoutine\\Media\\Icon")
    titleIcon:SetVertexColor(0.18, 0.82, 0.74, 1)
    titleIcon:Hide()

    local closeBtn = CloseButton(titleBar, function()
        frame:Hide()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", false) end
    end)

    local gearBtn = HeaderIconButton(
        titleBar,
        "Interface\\Buttons\\UI-OptionsButton",
        {0.85, 0.65, 0.20},
        {1, 1, 1},
        L["ProfKnowledge_OptionsTitle"],
        function() MR:ToggleGatheringLocationsConfig() end
    )

    local expansionDropdown, selectedExpansion = CreateKnowledgeExpansionDropdown(titleBar, gearBtn)
    frame.expansionDropdown = expansionDropdown
    expansionDropdown:ClearAllPoints()
    expansionDropdown:SetPoint("LEFT", titleBar, "LEFT", 8, -1)

    local titleTxt = titleBar:CreateFontString(nil, "OVERLAY")
    titleTxt:SetFont(FONT_HEADERS, math.max(10, (db.gatheringFontSize or 9) + 1), GetFontFlags())
    titleTxt:SetPoint("LEFT", titleIcon, "RIGHT", 5, 0)
    titleTxt:SetPoint("RIGHT", expansionDropdown, "LEFT", -6, 0)
    titleTxt:SetJustifyH("LEFT")
    titleTxt:SetText(StripInlineColor(L["ProfKnowledge_Title"] or "Profession Knowledge"))
    titleTxt:SetTextColor(1, 1, 1)
    titleTxt:Hide()

    local scroll = CreateFrame("ScrollFrame", nil, frame)
    if headerBottom then
        scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
        scroll:SetPoint("BOTTOMRIGHT", titleBar, "TOPRIGHT", -8, 1)
    else
        scroll:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -1)
        scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 4)
    end
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(width - 8)
    content:SetHeight(1)

    local track = CreateFrame("Frame", nil, frame)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 1, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 1, 0)
    track:SetWidth(5)
    frame._scroll = scroll
    frame._scrollTrack = track

    local UpdateScrollBar, _, trackBg, thumbTex = ns.AttachScrollList(scroll, content, track)
    trackBg:SetColorTexture(0, 0, 0, 0.3 * chromeAlpha)
    thumbTex:SetColorTexture(0.80, 0.53, 0.20, 0.6 * chromeAlpha)
    frame.UpdateScrollBar = UpdateScrollBar

    local ApplyMinimized

    local function UpdateMinBtn() return gatheringMinimized and "+" or "-" end
    local minBtn = HeaderToggleButton(titleBar, UpdateMinBtn, L["UI_Collapse"], function()
        gatheringMinimized = not gatheringMinimized
        minimized = gatheringMinimized
        if MR.db then MR.db.profile.gatheringMinimized = gatheringMinimized end
        ApplyMinimized(gatheringMinimized)
    end)
    minBtn:SetPoint("RIGHT", closeBtn, "LEFT", -3, 0)
    gearBtn:SetPoint("RIGHT", minBtn, "LEFT", -3, 0)
    if chromeAlpha <= 0.001 then
        for _, headerBtn in ipairs({ closeBtn, gearBtn, minBtn }) do
            if headerBtn.SetBackdropColor then
                headerBtn:SetBackdropColor(0, 0, 0, 0)
                headerBtn:SetBackdropBorderColor(0, 0, 0, 0)
            end
        end
    end

    local yOff = 0
    local fontSize = db.gatheringFontSize or 9

    yOff = BuildProfessionCards(content, width, yOff, fontSize, contentAlpha, borderAlpha, chromeAlpha, accentAlpha, db, selectedExpansion)

    if yOff == 0 then
        local emptyText = content:CreateFontString(nil, "OVERLAY")
        emptyText:SetFont(FONT_ROWS, fontSize, GetFontFlags())
        emptyText:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
        emptyText:SetPoint("TOPRIGHT", content, "TOPRIGHT", -10, -10)
        emptyText:SetJustifyH("LEFT")
        emptyText:SetTextColor(0.72, 0.72, 0.72, 0.95)
        emptyText:SetText(hasProfCache and L["Gathering_NoProfessions"] or L["Gathering_Loading"])
        yOff = 32
        if not hasProfCache and not isRetry and C_Timer then
            C_Timer.After(0.75, function()
                if gatheringLocationsFrame and gatheringLocationsFrame:IsShown() then
                    if MR.RefreshPlayerProfessions then MR:RefreshPlayerProfessions() end
                    gatheringLocationsFrame:Hide()
                    gatheringLocationsFrame = BuildGatheringLocationsFrame(true)
                end
            end)
        end
    end

    content:SetHeight(yOff)
    scroll:SetVerticalScroll(0)
    UpdateScrollBar()

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
    dragger:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not db.gatheringLocked then
            dragStartW, dragStartH = frame:GetWidth(), frame:GetHeight()
            local scale = frame:GetEffectiveScale()
            dragStartX, dragStartY = GetCursorPosition()
            dragStartX, dragStartY = dragStartX / scale, dragStartY / scale
            dragger._dragging = true
        end
    end)
    dragger:SetScript("OnMouseUp", function(_, button)
        if button == "LeftButton" and dragger._dragging then
            dragger._dragging = false
            if MR.db then
                MR.db.profile.gatheringWidth = math.max(MIN_W, math.min(MAX_W, math.floor(frame:GetWidth())))
                MR.db.profile.gatheringHeight = math.max(MIN_H, math.min(MAX_H, math.floor(frame:GetHeight())))
            end
            RebuildGatheringLocationsFrame()
            if gatheringCfgFrame and gatheringCfgFrame:IsShown() then PopulateGatheringConfig(gatheringCfgFrame) end
        end
    end)
    dragger:SetScript("OnUpdate", function()
        if not dragger._dragging then return end
        local cx, cy = GetCursorPosition()
        local scale = frame:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        frame:SetWidth(math.max(MIN_W, math.min(MAX_W, dragStartW + (cx - dragStartX))))
        frame:SetHeight(math.max(MIN_H, math.min(MAX_H, dragStartH + (dragStartY - cy))))
    end)

    ApplyMinimized = function(isMin)
        gatheringMinimized = isMin and true or false
        minimized = gatheringMinimized
        if MR.db then MR.db.profile.gatheringMinimized = gatheringMinimized end
        if minBtn.RefreshLabel then minBtn:RefreshLabel() end

        if gatheringMinimized then
            SyncManagedFramePos(frame, "gatheringLocPos", headerBottom and "bottom" or "top")
            if frame._scroll then frame._scroll:Hide() end
            if frame._scrollTrack then frame._scrollTrack:Hide() end
            if frame._dragger then frame._dragger:Hide() end
            frame._mrAnimTick = nil
            frame:SetScript("OnUpdate", nil)
            frame:SetHeight(TITLE_H)
        else
            SyncManagedFramePos(frame, "gatheringLocPos", headerBottom and "bottom" or "top")
            if frame._scroll then frame._scroll:Show() end
            if frame._scrollTrack then frame._scrollTrack:Show() end
            if frame._dragger then frame._dragger:Show() end
            local savedH = db.gatheringHeight or DEFAULT_H
            local naturalH = TITLE_H + 1 + yOff + 6
            ApplyFrameHeight(frame, math.min(savedH, naturalH))
            if frame.UpdateScrollBar then frame.UpdateScrollBar() end
        end
    end
    frame.ApplyMinimized = ApplyMinimized

    ApplyMinimized(minimized)

    frame:SetMovable(not db.gatheringLocked)
    frame:SetScale(db.gatheringScale or 1.0)
    MR.gatheringLocationsFrame = frame
    frame:Show()
    return frame
end

RebuildGatheringLocationsFrame = function(resetScroll)
    RefreshFonts()
    local wasShown = gatheringLocationsFrame and gatheringLocationsFrame:IsShown()
    -- Preserving scroll position only makes sense when the rebuild is for
    -- the SAME content (e.g. a label finished resolving in the background).
    -- Switching expansions swaps in a whole different profession list, so
    -- reapplying an old offset (possibly scrolled near the bottom of a
    -- taller list) onto shorter content clamps to a spot that skips right
    -- past the new list's own header/top cards — resetScroll opts out of
    -- that for callers where the content is genuinely changing.
    local savedScroll = not resetScroll and gatheringLocationsFrame and gatheringLocationsFrame._scroll and gatheringLocationsFrame._scroll:GetVerticalScroll()
    if gatheringLocationsFrame then gatheringLocationsFrame:Hide() end
    gatheringLocationsFrame = BuildGatheringLocationsFrame()
    if not wasShown then gatheringLocationsFrame:Hide() end

    -- BuildGatheringLocationsFrame always resets scroll to 0 as part of its
    -- own layout pass, so this has to happen synchronously right after it
    -- returns — a deferred (C_Timer.After) restore would let that reset
    -- render for one visible frame first, showing up as a flash-to-top on
    -- every single rebuild.
    if savedScroll and savedScroll > 0 and gatheringLocationsFrame._scroll then
        gatheringLocationsFrame._scroll:SetVerticalScroll(savedScroll)
        if gatheringLocationsFrame.UpdateScrollBar then
            gatheringLocationsFrame.UpdateScrollBar()
        end
    end
end

function MR.RequestGatheringLocationsRefresh()
    if gatheringLocationsFrame then
        RebuildGatheringLocationsFrame()
    end
end

local function SetProfessionColor(professionKey, r, g, b)
    if not MR.db.profile.gatheringProfColors then MR.db.profile.gatheringProfColors = {} end
    MR.db.profile.gatheringProfColors[professionKey] = { r, g, b }
    if MR.RequestVisualRefresh then
        MR:RequestVisualRefresh({ main = false })
    else
        RebuildGatheringLocationsFrame()
        if MR.RepopulateConfigFrame then MR:RepopulateConfigFrame() end
        if MR.RepopulateGatheringConfig then MR:RepopulateGatheringConfig() end
    end
end

local function ResetProfessionColor(professionKey)
    if MR.db.profile.gatheringProfColors then MR.db.profile.gatheringProfColors[professionKey] = nil end
    if MR.RequestVisualRefresh then
        MR:RequestVisualRefresh({ main = false })
    else
        RebuildGatheringLocationsFrame()
        if MR.RepopulateConfigFrame then MR:RepopulateConfigFrame() end
        if MR.RepopulateGatheringConfig then MR:RepopulateGatheringConfig() end
    end
end

local function BuildGatheringConfigFrame()
    local frame = StyledFrame(UIParent, nil, "HIGH", 20)
    frame:SetWidth(268)
    ApplyGatheringFrameTheme(frame, {
        alpha = 1,
        bg = { 0.03, 0.05, 0.09, 0.98 },
        border = { 0.24, 0.31, 0.42, 1 },
        accent = { 0.18, 0.78, 0.72 },
        headerHeight = 44,
    })
    frame._configMinHeight = 250
    frame:Hide()

    local tbar = TitleBar(frame, 22)
    tbar:SetBackdropColor(0.05, 0.12, 0.22, 1)
    tbar:SetScript("OnDragStart", function() frame:StartMoving() end)
    tbar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)
    local ttitle = tbar:CreateFontString(nil, "OVERLAY")
    ttitle:SetFont(FONT_HEADERS, 10, GetFontFlags())
    ttitle:SetText(L["ProfKnowledge_Config_Title"])
    ttitle:SetPoint("LEFT", tbar, "LEFT", 8, 0)
    CloseButton(tbar, function() frame:Hide() end)

    local scroll = CreateFrame("ScrollFrame", nil, frame)
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -22)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -8, 0)
    local scrollContent = CreateFrame("Frame", nil, scroll)
    scrollContent:SetSize(frame:GetWidth() or 268, 1)

    local track = CreateFrame("Frame", nil, frame)
    track:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -25)
    track:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    track:SetWidth(4)

    if ns.AttachScrollList then
        frame.UpdateConfigScrollBar = ns.AttachScrollList(scroll, scrollContent, track)
        frame.configScroll = scroll
        frame.configScrollTrack = track
    else
        scroll:Hide()
        track:Hide()
    end

    frame.body = nil
    return frame
end

PopulateGatheringConfig = function(frame)
    RefreshFonts()
    if frame.body then
        frame.body:EnableMouse(false)
        frame.body:Hide()
        frame.body:SetParent(UIParent)
        frame.body = nil
    end

    local bodyParent = (frame.configScroll and frame.configScroll:GetScrollChild()) or frame
    local body = CreateFrame("Frame", nil, bodyParent)
    body:SetPoint("TOPLEFT", bodyParent, "TOPLEFT", 0, 0)
    body:SetPoint("TOPRIGHT", bodyParent, "TOPRIGHT", 0, 0)
    frame.body = body

    local db = MR.db.profile
    local yOff, pad = frame.configScroll and -6 or -28, 8
    local contentW = (frame:GetWidth() or 224) - (pad * 2)
    local activePage = MR._gatheringCfgPage or "display"
    local cfgFs = (ns.GetFontSize and ns.GetFontSize()) or (MR.db and MR.db.profile and MR.db.profile.fontSize) or 9

    if activePage ~= "display" and activePage ~= "modules" and activePage ~= "reset" then
        activePage = "display"
        MR._gatheringCfgPage = activePage
    end

    local function Gap(h) yOff = OptionsGap(body, yOff, h) end
    local function Divider() yOff = OptionsDivider(body, yOff, pad) end
    local function SecLabel(text) yOff = OptionsSectionLabel(body, yOff, text, pad, cfgFs) end
    local function Check(label, getValue, setValue, r, g, b)
        yOff = OptionsCheckbox(body, yOff, label, getValue, setValue, r or 0.78, g or 0.78, b or 0.88, pad, function() PopulateGatheringConfig(frame) end, cfgFs)
    end
    local function Slider(label, mn, mx, st, getValue, setValue, r, g, b, disabled)
        yOff = OptionsSlider(body, yOff, label, mn, mx, st, getValue, setValue, r, g, b, pad, disabled, cfgFs)
    end
    local function Btn(label, fn) yOff = OptionsBtn(body, yOff, label, fn, math.max(184, contentW), pad, cfgFs) end

    do
        local tabs = {
            { key = "display", label = L["Config_TabLayout"] or "Layout" },
            { key = "modules", label = L["Config_TabModules"] or "Modules" },
            { key = "reset", label = L["Config_TabReset"] or "Reset" },
        }
        local tabW = math.floor((contentW - 4) / #tabs)
        for i, tab in ipairs(tabs) do
            local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
            btn:SetSize(tabW, 18)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", pad + (i - 1) * (tabW + 2), yOff)
            btn:SetBackdrop(MakeBackdrop())
            local isActive = activePage == tab.key
            btn:SetBackdropColor(isActive and 0.11 or 0.05, isActive and 0.24 or 0.09, isActive and 0.23 or 0.15, 1)
            btn:SetBackdropBorderColor(isActive and 0.22 or 0.16, isActive and 0.82 or 0.28, isActive and 0.70 or 0.36, 1)

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, cfgFs, GetFontFlags())
            lbl:SetPoint("CENTER")
            lbl:SetText(tab.label)
            lbl:SetTextColor(isActive and 0.85 or 0.62, isActive and 1.0 or 0.75, isActive and 0.92 or 0.70)

            btn:SetScript("OnClick", function()
                MR._gatheringCfgPage = tab.key
                PopulateGatheringConfig(frame)
            end)
            btn:SetScript("OnEnter", function()
                if activePage ~= tab.key then
                    btn:SetBackdropColor(0.08, 0.18, 0.24, 1)
                    btn:SetBackdropBorderColor(0.24, 0.74, 0.68, 1)
                    lbl:SetTextColor(0.90, 0.98, 0.96)
                end
            end)
            btn:SetScript("OnLeave", function()
                local selected = (MR._gatheringCfgPage or "display") == tab.key
                btn:SetBackdropColor(selected and 0.11 or 0.05, selected and 0.24 or 0.09, selected and 0.23 or 0.15, 1)
                btn:SetBackdropBorderColor(selected and 0.22 or 0.16, selected and 0.82 or 0.28, selected and 0.70 or 0.36, 1)
                lbl:SetTextColor(selected and 0.85 or 0.62, selected and 1.0 or 0.75, selected and 0.92 or 0.70)
            end)
        end
        yOff = yOff - 26
    end

    if activePage == "display" then
        SecLabel(L["Config_Display"])
        Check(L["Config_LockPosition"], function() return db.gatheringLocked end, function(value)
            db.gatheringLocked = value
            if gatheringLocationsFrame then gatheringLocationsFrame:SetMovable(not value) end
        end)
        Check(L["Config_HideWhenCompleted"], function() return db.gatheringHideCompleted end, function(value)
            db.gatheringHideCompleted = value
            RebuildGatheringLocationsFrame()
        end)
        Gap(4); Divider()
        Slider(L["WIDTH"], MIN_W, MAX_W, 10, function() return db.gatheringWidth or DEFAULT_W end, function(value)
            db.gatheringWidth = math.floor(value / 10) * 10
            RebuildGatheringLocationsFrame()
        end, 0.80, 0.53, 0.20)
        Slider(L["HEIGHT"], MIN_H, MAX_H, 10, function() return db.gatheringHeight or DEFAULT_H end, function(value)
            db.gatheringHeight = math.floor(value / 10) * 10
            if gatheringLocationsFrame and not db.gatheringMinimized then gatheringLocationsFrame:SetHeight(db.gatheringHeight) end
        end, 0.60, 0.80, 0.40)
        local syncFs = MR.db.profile.syncWindowFontSize
        Slider(L["Config_FontSize"], 7, 16, 1, function() return db.gatheringFontSize or 9 end, function(value)
            db.gatheringFontSize = math.floor(value)
            RebuildGatheringLocationsFrame()
            PopulateGatheringConfig(frame)
        end, 0.78, 0.55, 0.16, syncFs)
        Slider(L["BACKGROUND"], 0, 1, 0.05, function() return db.gatheringAlpha or 1.0 end, function(value)
            db.gatheringAlpha = math.floor(value * 20) / 20
            RebuildGatheringLocationsFrame()
            PopulateGatheringConfig(frame)
        end, 0.40, 0.40, 0.40)
        Slider(L["SCALE"], 0.5, 2.0, 0.05, function() return db.gatheringScale or 1.0 end, function(value)
            db.gatheringScale = value
            if gatheringLocationsFrame then gatheringLocationsFrame:SetScale(value) end
        end, 0.45, 0.22, 0.82, MR.db.profile.syncWindowScale == true)
    elseif activePage == "modules" then
        db.gatheringEntryVisibility = db.gatheringEntryVisibility or {}
        local entryVisibility = db.gatheringEntryVisibility
        local function EntryCheck(indent, entry, sectionKey, getValue, setValue, r, g, b)
            yOff = OptionsCheckbox(body, yOff, EntryDisplayLabel(entry, sectionKey), getValue, function(value)
                setValue(value)
                PopulateGatheringConfig(frame)
            end, r or 0.78, g or 0.78, b or 0.88, indent, function() end, cfgFs)
        end
        local function GroupHeader(indent, text, modKey, groupRows, getEnabled, setEnabled)
            local hasRows = modKey and type(groupRows) == "table" and #groupRows > 0
            local hasToggle = hasRows or (getEnabled and setEnabled)
            local enabled = true
            if hasToggle then
                enabled = getEnabled and getEnabled() or (hasRows and MR:IsRowGroupEnabled(modKey, groupRows) or true)
            end
            local btn = CreateFrame(hasToggle and "Button" or "Frame", nil, body, hasToggle and "BackdropTemplate" or nil)
            btn:SetPoint("TOPLEFT", body, "TOPLEFT", indent, yOff)
            btn:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
            btn:SetHeight(16)
            if hasToggle then
                btn:SetBackdrop(MakeBackdrop())
                btn:SetBackdropColor(enabled and 0.035 or 0.055, enabled and 0.085 or 0.045, enabled and 0.095 or 0.050, 0.72)
                btn:SetBackdropBorderColor(enabled and 0.10 or 0.24, enabled and 0.32 or 0.12, enabled and 0.34 or 0.12, 0.70)
            end

            local cb
            if hasToggle then
                cb = CreateFrame("CheckButton", nil, btn, "UICheckButtonTemplate")
                cb:SetSize(18, 18)
                cb:SetPoint("LEFT", btn, "LEFT", 0, 0)
                cb:SetChecked(enabled)
                cb:SetScript("OnClick", function(s)
                    local value = s:GetChecked() and true or false
                    if setEnabled then
                        setEnabled(value)
                    elseif hasRows then
                        MR:SetRowGroupEnabled(modKey, groupRows, value)
                    end
                    RebuildGatheringLocationsFrame()
                    PopulateGatheringConfig(frame)
                end)
            end

            local lbl = btn:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_ROWS, math.max(8, cfgFs - 1), GetFontFlags())
            lbl:SetPoint("LEFT", cb or btn, cb and "RIGHT" or "LEFT", cb and 1 or 0, 0)
            lbl:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetWordWrap(false)
            lbl:SetText(text)
            lbl:SetTextColor(enabled and 0.72 or 0.42, enabled and 0.90 or 0.46, enabled and 0.88 or 0.48, 0.95)

            if hasToggle then
                btn:SetScript("OnClick", function()
                    local value = not (getEnabled and getEnabled() or (hasRows and MR:IsRowGroupEnabled(modKey, groupRows) or enabled))
                    if setEnabled then
                        setEnabled(value)
                    elseif hasRows then
                        MR:SetRowGroupEnabled(modKey, groupRows, value)
                    end
                    RebuildGatheringLocationsFrame()
                    PopulateGatheringConfig(frame)
                end)
                btn:SetScript("OnEnter", function()
                    lbl:SetTextColor(0.85, 0.95, 0.98, 1)
                end)
                btn:SetScript("OnLeave", function()
                    local isEnabled = getEnabled and getEnabled() or (hasRows and MR:IsRowGroupEnabled(modKey, groupRows) or enabled)
                    lbl:SetTextColor(isEnabled and 0.72 or 0.42, isEnabled and 0.90 or 0.46, isEnabled and 0.88 or 0.48, 0.95)
                end)
            end

            yOff = yOff - 16
        end
        local function ModuleRowControl(indent, modKey, rowData)
            local rowKey = rowData.key
            local enabled = MR:IsRowEnabled(modKey, rowKey)
            local cleanLabel = StripInlineColor(rowData.label or rowKey)
            local effectiveColor = MR:GetRowColor(modKey, rowKey) or (rowData.colorKey and MR:GetRowColor(modKey, rowData.colorKey)) or MR:GetHeaderColor(modKey)
            local er, eg, eb = hex(effectiveColor)

            local rowFr = CreateFrame("Frame", nil, body)
            rowFr:SetPoint("TOPLEFT", body, "TOPLEFT", indent, yOff)
            rowFr:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
            rowFr:SetHeight(16)

            local bullet = rowFr:CreateTexture(nil, "ARTWORK")
            bullet:SetSize(5, 5)
            bullet:SetPoint("LEFT", rowFr, "LEFT", 0, 0)
            bullet:SetColorTexture(er, eg, eb)

            local rlbl = rowFr:CreateFontString(nil, "OVERLAY")
            rlbl:SetFont(FONT_ROWS, math.max(8, cfgFs - 1), GetFontFlags())
            rlbl:SetPoint("LEFT", rowFr, "LEFT", 10, 0)
            rlbl:SetPoint("RIGHT", rowFr, "RIGHT", -32, 0)
            rlbl:SetJustifyH("LEFT")
            rlbl:SetWordWrap(false)
            rlbl:SetText(cleanLabel)

            local eyeBtn = CreateFrame("Button", nil, rowFr, "BackdropTemplate")
            eyeBtn:SetSize(14, 14)
            eyeBtn:SetPoint("RIGHT", rowFr, "RIGHT", 0, 0)
            eyeBtn:SetBackdrop(MakeBackdrop())
            local eyeLbl = eyeBtn:CreateFontString(nil, "OVERLAY")
            eyeLbl:SetFont(FONT_ROWS, 9, GetFontFlags())
            eyeLbl:SetPoint("CENTER", eyeBtn, "CENTER", 0, 0)

            local function ApplyState(isEnabled)
                bullet:SetAlpha(isEnabled and 0.8 or 0.25)
                if isEnabled then
                    rlbl:SetTextColor(er, eg, eb)
                else
                    rlbl:SetTextColor(0.35, 0.35, 0.35)
                end
                eyeBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                eyeBtn:SetBackdropBorderColor(
                    isEnabled and 0.15 or 0.35,
                    isEnabled and 0.32 or 0.12,
                    isEnabled and 0.38 or 0.12, 1)
                eyeLbl:SetText(isEnabled and "o" or "-")
                eyeLbl:SetTextColor(
                    isEnabled and 0.25 or 0.55,
                    isEnabled and 0.85 or 0.25,
                    isEnabled and 0.70 or 0.25)
            end
            ApplyState(enabled)

            eyeBtn:SetScript("OnClick", function()
                enabled = not MR:IsRowEnabled(modKey, rowKey)
                MR:SetRowEnabled(modKey, rowKey, enabled, true)
                RebuildGatheringLocationsFrame()
                ApplyState(enabled)
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
                ApplyState(enabled)
                GameTooltip:Hide()
            end)

            local rsr, rsg, rsb = hex(MR:GetRowColor(modKey, rowKey) or (rowData.colorKey and MR:GetRowColor(modKey, rowData.colorKey)) or MR:GetHeaderColor(modKey))
            local rowSwatch = OptionsColorSwatch(rowFr, rsr, rsg, rsb,
                function(nr, ng, nb)
                    MR:SetRowColor(modKey, rowKey, string.format("#%02x%02x%02x", nr * 255, ng * 255, nb * 255))
                    er, eg, eb = nr, ng, nb
                    bullet:SetColorTexture(er, eg, eb)
                    if enabled then rlbl:SetTextColor(er, eg, eb) end
                end,
                function()
                    MR:ResetRowColor(modKey, rowKey)
                    local dr, dg, db2 = hex((rowData.colorKey and MR:GetRowColor(modKey, rowData.colorKey)) or MR:GetHeaderColor(modKey))
                    er, eg, eb = dr, dg, db2
                    bullet:SetColorTexture(er, eg, eb)
                    if enabled then rlbl:SetTextColor(er, eg, eb) end
                    return dr, dg, db2
                end,
                L["Config_RowColor"])
            rowSwatch:SetSize(14, 14)
            rowSwatch:SetPoint("RIGHT", eyeBtn, "LEFT", -2, 0)

            yOff = yOff - 17
        end
        local function ExpansionHeader(text)
            local ROW_H = 26
            local header = CreateFrame("Frame", nil, body, "BackdropTemplate")
            header:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
            header:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
            header:SetHeight(ROW_H)
            header:SetBackdrop(MakeBackdrop())
            header:SetBackdropColor(0.020, 0.085, 0.100, 0.95)
            header:SetBackdropBorderColor(0.22, 0.68, 0.64, 0.92)

            local lbl = header:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT_HEADERS, math.max(10, cfgFs), GetFontFlags())
            lbl:SetPoint("LEFT", header, "LEFT", 9, 0)
            lbl:SetPoint("RIGHT", header, "RIGHT", -8, 0)
            lbl:SetJustifyH("LEFT")
            lbl:SetWordWrap(false)
            lbl:SetText(text)
            lbl:SetTextColor(0.88, 1.00, 0.94, 0.98)

            yOff = yOff - ROW_H - 2
        end
        local function IsProfessionEnabled(expansion, profession)
            return IsProfessionCardVisible(expansion.key, profession.key)
        end
        local function SetProfessionEnabled(expansion, profession, enabled)
            SetProfessionCardVisible(expansion.key, profession.key, enabled)
            PopulateGatheringConfig(frame)
        end
        local professionSource = MR.GetMainFrameProgressSource and MR:GetMainFrameProgressSource() or nil
        for _, expansion in ipairs(ALL_EXPANSIONS) do
            local learnedProfessions = {}
            for _, profession in ipairs(expansion.professions) do
                if HasProfessionLearned(profession.skillLine, professionSource) then
                    learnedProfessions[#learnedProfessions + 1] = profession
                end
            end
            if #learnedProfessions > 0 then
            Gap(4)
            ExpansionHeader(expansion.label)
            for _, profession in ipairs(learnedProfessions) do
                    local cr, cg, cb = GetProfessionColor(profession.key)
                    local profExpandKey = expansion.key .. ":" .. profession.key
                    local isExpanded = configExpandedProfessions[profExpandKey]
                    local row = CreateFrame("Frame", nil, body, "BackdropTemplate")
                    row:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
                    row:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
                    row:SetHeight(28)
                    row:SetBackdrop(MakeBackdrop())
                    row:SetBackdropColor(0.018 + cr * 0.035, 0.024 + cg * 0.035, 0.030 + cb * 0.035, 0.90)
                    row:SetBackdropBorderColor(cr * 0.42, cg * 0.42, cb * 0.42, 0.82)
                    local nameLbl
                    local professionEnabled = IsProfessionEnabled(expansion, profession)
                    local toggleBtn = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                    toggleBtn:SetSize(20, 20)
                    toggleBtn:SetPoint("LEFT", row, "LEFT", 5, 0)
                    toggleBtn:SetChecked(professionEnabled)
                        toggleBtn:SetScript("OnClick", function()
                            SetProfessionEnabled(expansion, profession, toggleBtn:GetChecked() and true or false)
                        end)
                        toggleBtn:SetScript("OnEnter", function()
                            GameTooltip:SetOwner(toggleBtn, "ANCHOR_RIGHT")
                            GameTooltip:SetText(toggleBtn:GetChecked() and "Hide this profession in the Profession Knowledge window" or "Show this profession in the Profession Knowledge window", 1, 1, 1)
                            GameTooltip:Show()
                        end)
                        toggleBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                        local expandBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
                        expandBtn:SetSize(18, 18)
                        expandBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                        expandBtn:SetBackdrop(MakeBackdrop())
                        expandBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                        expandBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
                        local expandLbl = expandBtn:CreateFontString(nil, "OVERLAY")
                        expandLbl:SetFont(FONT_HEADERS, cfgFs, GetFontFlags())
                        expandLbl:SetPoint("CENTER", expandBtn, "CENTER", 0, 1)
                        expandLbl:SetText(isExpanded and "v" or ">")
                        expandLbl:SetTextColor(0.45, 0.75, 0.70)
                        expandBtn:SetScript("OnClick", function()
                            configExpandedProfessions[profExpandKey] = not isExpanded
                            PopulateGatheringConfig(frame)
                        end)
                        expandBtn:SetScript("OnEnter", function()
                            expandBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
                            expandBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
                            expandLbl:SetTextColor(1, 1, 1)
                            GameTooltip:SetOwner(expandBtn, "ANCHOR_RIGHT")
                            GameTooltip:SetText(L["Config_ExpandCollapseRows"] or "Expand to show/hide individual sources", 1, 1, 1)
                            GameTooltip:Show()
                        end)
                        expandBtn:SetScript("OnLeave", function()
                            expandBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                            expandBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
                            expandLbl:SetTextColor(0.45, 0.75, 0.70)
                            GameTooltip:Hide()
                        end)

                        local swatch = OptionsColorSwatch(row, cr, cg, cb, function(r, g, b)
                            SetProfessionColor(profession.key, r, g, b)
                            if nameLbl then nameLbl:SetTextColor(r, g, b) end
                        end, function()
                            ResetProfessionColor(profession.key)
                            local dr, dg, db2 = GetProfessionColor(profession.key)
                            if nameLbl then nameLbl:SetTextColor(dr, dg, db2) end
                            return dr, dg, db2
                        end, profession.label .. L["Color_Reset_Hint"])
                        swatch:SetPoint("RIGHT", expandBtn, "LEFT", -4, 0)
                        nameLbl = row:CreateFontString(nil, "OVERLAY")
                        nameLbl:SetFont(FONT_ROWS, 10, GetFontFlags())
                        nameLbl:SetPoint("LEFT", toggleBtn, "RIGHT", 6, 0)
                        nameLbl:SetPoint("RIGHT", swatch, "LEFT", -4, 0)
                        nameLbl:SetJustifyH("LEFT")
                        nameLbl:SetText(profession.label)
                        nameLbl:SetTextColor(cr, cg, cb)
                        yOff = yOff - 30

                        if isExpanded then
                            if ns.BuildMainMenuRows then
                                local modKey = (ns.GetProfessionModuleKey and ns.GetProfessionModuleKey(expansion.key, profession)) or ("prof_" .. profession.key)
                                local rowsByGroup, groupOrder = {}, {}
                                for _, row in ipairs(ns.BuildMainMenuRows(profession, expansion)) do
                                    if not row.isVisible or row.isVisible() then
                                    local g = row.group or "other"
                                    if not rowsByGroup[g] then
                                        rowsByGroup[g] = {}
                                        groupOrder[#groupOrder + 1] = g
                                    end
                                    table.insert(rowsByGroup[g], row)
                                    end
                                end

                                for _, g in ipairs(groupOrder) do
                                    local groupRows = rowsByGroup[g]
                                    GroupHeader(pad + 22, ns.GetRowGroupLabel(g), modKey, groupRows)
                                    for _, row in ipairs(groupRows) do
                                        ModuleRowControl(pad + 26, modKey, row)
                                    end
                                end

                                local lureRows = expansion.key == "midnight" and ns.BuildLureRows(profession)
                                if lureRows and #lureRows > 0 then
                                    GroupHeader(pad + 22, L["Skin_Lures_Title"], "skin_lures", lureRows)
                                    for _, row in ipairs(lureRows) do
                                        ModuleRowControl(pad + 26, "skin_lures", row)
                                    end
                                end
                            else
                                for _, section in ipairs(GetOrderedProfessionSections(profession)) do
                                    if ShouldShowProfessionSection(section) and #section.entries > 0 then
                                        local function IsSectionEnabled()
                                            for i in ipairs(section.entries) do
                                                local entryId = GetEntryVisibilityId(expansion.key, profession.key, section.key, i)
                                                if entryVisibility[entryId] == false then
                                                    return false
                                                end
                                            end
                                            return true
                                        end
                                        local function SetSectionEnabled(value)
                                            for i in ipairs(section.entries) do
                                                local entryId = GetEntryVisibilityId(expansion.key, profession.key, section.key, i)
                                                entryVisibility[entryId] = value and true or false
                                            end
                                        end
                                        GroupHeader(pad + 22, section.label, nil, nil, IsSectionEnabled, SetSectionEnabled)

                                        for i, entry in ipairs(section.entries) do
                                            local entryId = GetEntryVisibilityId(expansion.key, profession.key, section.key, i)
                                            EntryCheck(pad + 26, entry, section.key, function()
                                                return entryVisibility[entryId] ~= false
                                            end, function(value)
                                                entryVisibility[entryId] = value and true or false
                                                RebuildGatheringLocationsFrame()
                                            end, cr, cg, cb)
                                        end
                                    end
                                end
                            end
                        end
            end
            end
        end
    else
        SecLabel(L["RESETS"])
        Btn(L["Config_ResetColors"], function()
            MR.db.profile.gatheringProfColors = {}
            RebuildGatheringLocationsFrame()
            PopulateGatheringConfig(frame)
        end)
    end

    local totalH = math.abs(yOff) + 10
    if activePage == "display" then
        frame._configMinHeight = math.max(frame._configMinHeight or 0, totalH)
    end
    totalH = math.max(totalH, frame._configMinHeight or totalH)
    body:SetHeight(totalH)
    bodyParent:SetHeight(totalH)
    if frame.configScroll then
        local maxBodyH = math.max(220, math.min(560, (UIParent:GetHeight() or 768) - 120))
        frame:SetHeight(math.min(totalH + 22, maxBodyH + 22))
        if frame.UpdateConfigScrollBar then frame.UpdateConfigScrollBar() end
    else
        frame:SetHeight(totalH)
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
        if gatheringLocationsFrame then
            local x, y = gatheringLocationsFrame:GetCenter()
            if x and y then
                gatheringCfgFrame:ClearAllPoints()
                gatheringCfgFrame:SetPoint("LEFT", gatheringLocationsFrame, "RIGHT", 10, 0)
                gatheringCfgFrame:SetScale(gatheringLocationsFrame:GetScale())
            end
        end
    end
end

local function ToggleGatheringLocations()
    if not gatheringLocationsFrame then
        gatheringLocationsFrame = BuildGatheringLocationsFrame()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", true) end
    elseif gatheringLocationsFrame:IsShown() then
        gatheringLocationsFrame:Hide()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", false) end
    else
        gatheringLocationsFrame:Show()
        if MR.SetManagedWindowOpen then MR:SetManagedWindowOpen("gatheringLocOpen", true) end
    end
end

MR.ToggleGatheringLocations = ToggleGatheringLocations

function MR:ShowGatheringLocations()
    if not gatheringLocationsFrame then gatheringLocationsFrame = BuildGatheringLocationsFrame() else gatheringLocationsFrame:Show() end
    if self.SetManagedWindowOpen then self:SetManagedWindowOpen("gatheringLocOpen", true) end
end

function MR:EnsureGatheringLocationsShown()
    if not gatheringLocationsFrame then gatheringLocationsFrame = BuildGatheringLocationsFrame() else gatheringLocationsFrame:Show() end
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
        if MR.db and MR.GetManagedWindowOpen and MR:GetManagedWindowOpen("gatheringLocOpen") then
            MR:ShowGatheringLocations()
        end
        eventFrame:UnregisterEvent("PLAYER_LOGIN")
    end
end)
