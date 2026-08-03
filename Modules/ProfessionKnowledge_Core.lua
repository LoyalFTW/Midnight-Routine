local _, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)

local function E(kind, data)
    data.kind = kind
    return data
end

local function T(data) data.mode = data.mode or "single"; return E("treasure", data) end
local function S(data) data.mode = data.mode or "single"; return E("study", data) end
local function WQ(data) data.mode = data.mode or "any"; return E("weeklyQuest", data) end
local function WD(data) data.mode = data.mode or "single"; return E("weeklyDrop", data) end
local function DMF(data)
    data.mode = "single"
    if data.requiredItems == nil and MR.GetDarkmoonRequiredItems then
        data.requiredItems = MR:GetDarkmoonRequiredItems(data.questID)
    end
    return E("darkmoon", data)
end
local function TR(data) data.mode = "single"; return E("treatise", data) end
local function Ref(data) data.mode = "reference"; data.reference = true; return E("reference", data) end

ns.T, ns.S, ns.WQ, ns.WD, ns.DMF, ns.TR, ns.Ref = T, S, WQ, WD, DMF, TR, Ref

ns.DRAGONFLIGHT_CATCHUP_ITEM_ID = 191784

local ALL_EXPANSIONS = {}
ns.AllExpansions = ALL_EXPANSIONS 

local FLAT_SECTIONS = {
    { field = "weekly", key = "weekly", labelKey = "ProfKnowledge_Section_Weekly", fallback = "Weekly Knowledge" },
    { field = "discoveries", key = "discoveries", labelKey = "ProfKnowledge_Section_Discoveries", fallback = "One-Time Discoveries" },
    { field = "treasures", key = "treasures", labelKey = "ProfKnowledge_Section_Discoveries", fallback = "One-Time Discoveries" },
    { field = "studies", key = "studies", labelKey = "ProfKnowledge_Section_Studies", fallback = "Studies" },
    { field = "books", key = "books", labelKey = "ProfKnowledge_Section_Books", fallback = "Knowledge Books" },
    { field = "darkmoon", key = "darkmoon", labelKey = "ProfKnowledge_Section_Darkmoon", fallback = "Darkmoon Faire" },
}

local function SplitFlatWeeklyDarkmoon(profession)
    if not (profession and profession.weekly) then
        return
    end

    local weekly = {}
    local darkmoon = profession.darkmoon
    for _, entry in ipairs(profession.weekly) do
        if entry.kind == "darkmoon" then
            local questID = entry.questID or (entry.questIDs and entry.questIDs[1])
            entry.rowKey = entry.rowKey or (questID and ("weekly_" .. tostring(questID))) or ("dmf_" .. tostring((darkmoon and #darkmoon or 0) + 1))
            darkmoon = darkmoon or {}
            darkmoon[#darkmoon + 1] = entry
        else
            weekly[#weekly + 1] = entry
        end
    end

    profession.weekly = weekly
    profession.darkmoon = darkmoon
end

local function NormalizeProfessionSections(profession)
    if profession.sections then
        for _, section in ipairs(profession.sections) do
            for _, entry in ipairs(section.entries or {}) do
                entry.profKnowledgeSectionKey = entry.profKnowledgeSectionKey or section.key
                entry.profKnowledgeProfessionKey = entry.profKnowledgeProfessionKey or profession.key
            end
        end
        return profession.sections
    end

    SplitFlatWeeklyDarkmoon(profession)

    local sections = {}
    for _, def in ipairs(FLAT_SECTIONS) do
        local entries = profession[def.field]
        if entries and #entries > 0 then
            sections[#sections + 1] = {
                key = def.key,
                label = L[def.labelKey] or def.fallback,
                entries = entries,
            }
        end
    end
    profession.sections = sections
    for _, section in ipairs(sections) do
        for _, entry in ipairs(section.entries or {}) do
            entry.profKnowledgeSectionKey = entry.profKnowledgeSectionKey or section.key
            entry.profKnowledgeProfessionKey = entry.profKnowledgeProfessionKey or profession.key
        end
    end
    return sections
end
ns.NormalizeProfessionSections = NormalizeProfessionSections

function ns.RegisterProfessionExpansion(def)
    for _, profession in ipairs(def.professions or {}) do
        NormalizeProfessionSections(profession)
        for _, section in ipairs(profession.sections or {}) do
            for _, entry in ipairs(section.entries or {}) do
                entry.profKnowledgeExpansionKey = entry.profKnowledgeExpansionKey or def.key
            end
        end
    end
    table.insert(ALL_EXPANSIONS, def)
    if MR and MR.RegisterExpansion then
        local order = def.order
        if not order then
            if def.key == "tww" then
                order = 200
            elseif def.key == "dragonflight" then
                order = 300
            end
        end
        MR:RegisterExpansion({
            key = def.key,
            label = def.label,
            shortLabel = def.shortLabel or def.label,
            order = order,
        })
    end
end


local function FindSection(profession, key)
    for _, section in ipairs(profession.sections) do
        if section.key == key then
            return section
        end
    end
    return nil
end

local function ColorToHex(color)
    if not color then return nil end
    return string.format("#%02x%02x%02x",
        math.floor((color[1] or 1) * 255 + 0.5),
        math.floor((color[2] or 1) * 255 + 0.5),
        math.floor((color[3] or 1) * 255 + 0.5))
end

local Slug

local pendingLabelRows
local itemLabelWatchFrame
local questTitleWatchFrame
local TrackPendingLabel
local TrackPendingQuestTitle
local EnsureQuestTitleWatchFrame
local itemNameCache = {}
local questTitleCache = {}
local questTitlePending = {}
local pendingQuestTitleRows = {}
local questRewardItemCache = {}
local labelRefreshPending
local PENDING_PLACEHOLDER = {}

local function UpsertPendingRow(bucket, row, payload)
    if type(bucket) ~= "table" or type(row) ~= "table" then
        return
    end

    local rowKey = row.key
    for index, existing in ipairs(bucket) do
        local existingRow = type(existing) == "table" and (existing.row or existing) or nil
        if existing == row or existingRow == row or (rowKey and existingRow and existingRow.key == rowKey) then
            bucket[index] = payload or row
            return
        end
    end

    bucket[#bucket + 1] = payload or row
end

local function CountMapEntries(map)
    local count = 0
    if type(map) == "table" then
        for _ in pairs(map) do
            count = count + 1
        end
    end
    return count
end

function MR:GetProfessionKnowledgeCacheCounts()
    for questID in pairs(pendingQuestTitleRows) do
        if not questTitlePending[questID] and not questTitleCache[questID] then
            pendingQuestTitleRows[questID] = nil
        end
    end

    return {
        itemNames = CountMapEntries(itemNameCache),
        questTitles = CountMapEntries(questTitleCache),
        questTitlePending = CountMapEntries(questTitlePending),
        pendingQuestRows = CountMapEntries(pendingQuestTitleRows),
        rewardItems = CountMapEntries(questRewardItemCache),
        pendingLabels = CountMapEntries(pendingLabelRows),
    }
end

local function RequestLabelRefresh()
    if labelRefreshPending then return end
    labelRefreshPending = true
    C_Timer.After(0.08, function()
        labelRefreshPending = false
        local hasVisibleMain = MR.frame and MR.frame.IsShown and MR.frame:IsShown()
        local hasVisibleDetached = false
        if MR.detachedFrames then
            for _, frame in pairs(MR.detachedFrames) do
                if frame and frame.IsShown and frame:IsShown() then
                    hasVisibleDetached = true
                    break
                end
            end
        end

        if hasVisibleMain or hasVisibleDetached then
            if MR.RequestUIRefresh then
                MR:RequestUIRefresh(0.02)
            elseif MR.RefreshUI then
                MR:RefreshUI()
            end
        else
            MR._refreshUIDirty = true
            MR._mainPanelNeedsRefresh = true
        end

        if MR.RequestProfessionKnowledgeSurfaceRefresh then
            MR:RequestProfessionKnowledgeSurfaceRefresh(0.02)
        elseif MR.RequestGatheringLocationsRefresh then
            MR.RequestGatheringLocationsRefresh()
        elseif MR.RefreshProfessionKnowledgeSurfaces then
            MR:RefreshProfessionKnowledgeSurfaces()
        end
    end)
end

local WEEKLY_DROP_ITEM_LABELS = {
    [259188] = "Lightbloomed Spore Sample",
    [259189] = "Aged Cruor",
    [259190] = "Thalassian Whestone",
    [259191] = "Infused Quenching Oil",
    [259192] = "Voidstorm Ashes",
    [259193] = "Lost Thalassian Vellum",
    [259194] = "Dance Gear",
    [259195] = "Dawn Capacitor",
    [259196] = "Brilliant Phoenix Ink",
    [259197] = "Loa-Blessed Rune",
    [259198] = "Void-Touched Eversong Diamond Fragments",
    [259199] = "Harandar Stone Sample",
    [259200] = "Amani Tanning Oil",
    [259201] = "Thalassian Mana Oil",
    [259202] = "Embroidered Memento",
    [259203] = "Finely Woven Lynx Collar",
}

local function GetWeeklyEntryRowKey(entry, index, rowKeyCounts)
    local rowKey = entry and entry.rowKey
    if not rowKey then
        local questID = entry and (entry.questID or (entry.questIDs and entry.questIDs[1]))
        if questID then
            return "weekly_" .. questID
        end
        if entry and entry.itemID then
            return "weekly_item_" .. entry.itemID
        end
        return "weekly_" .. tostring(index) .. "_" .. Slug(entry and (entry.label or entry.note))
    end
    if (rowKeyCounts and rowKeyCounts[rowKey] or 0) <= 1 then
        return rowKey
    end
    return rowKey .. "_" .. tostring(entry.itemID or entry.questID or index)
end

local function GetQuestRewardItemID(questID, dataLoaded)
    if not questID then return nil end
    if questRewardItemCache[questID] ~= nil then
        return questRewardItemCache[questID] or nil
    end
    if GetNumQuestLogRewards and GetQuestLogRewardInfo then
        local ok, numRewards = pcall(GetNumQuestLogRewards, questID)
        if ok and numRewards and numRewards > 0 then
            local okInfo, _, _, _, _, _, itemID = pcall(GetQuestLogRewardInfo, 1, questID)
            if okInfo and itemID then
                questRewardItemCache[questID] = itemID
                return itemID
            end
        end
        if dataLoaded then
            questRewardItemCache[questID] = false
        end
    end
    return nil
end

local function GetQuestTitle(entry)
    local questID = entry and (entry.questID or (entry.questIDs and entry.questIDs[1]))
    if questID and C_QuestLog and C_QuestLog.GetTitleForQuestID then
        if questTitleCache[questID] then
            return questTitleCache[questID]
        end
        local title = C_QuestLog.GetTitleForQuestID(questID)
        if title and title ~= "" then
            questTitleCache[questID] = title
            questTitlePending[questID] = nil
            pendingQuestTitleRows[questID] = nil
            return title
        end
        if C_QuestLog.RequestLoadQuestByID and not questTitlePending[questID] then
            pcall(C_QuestLog.RequestLoadQuestByID, questID)
            questTitlePending[questID] = true
            EnsureQuestTitleWatchFrame()
        end
    end
    return nil
end

local function IsGenericKnowledgeTreasureTitle(title)
    title = tostring(title or ""):lower()
    title = title:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    title = title:gsub("[^%w%s]", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    return title == "knowledge treasure" or title == "knowledge treasures"
end

function EnsureQuestTitleWatchFrame()
    if questTitleWatchFrame then return end
    questTitleWatchFrame = CreateFrame("Frame")
    questTitleWatchFrame:RegisterEvent("QUEST_DATA_LOAD_RESULT")
    questTitleWatchFrame:SetScript("OnEvent", function(_, _, loadedQuestID, success)
        if not loadedQuestID then return end

        questTitlePending[loadedQuestID] = nil
        if success then
            local loadedTitle = C_QuestLog.GetTitleForQuestID(loadedQuestID)
            if loadedTitle and loadedTitle ~= "" then
                questTitleCache[loadedQuestID] = loadedTitle
            end
            local rewardItemID = GetQuestRewardItemID(loadedQuestID, true)
            if rewardItemID and not GetItemInfo(rewardItemID) then
                TrackPendingLabel(PENDING_PLACEHOLDER, rewardItemID)
            end
        end

        local registrations = pendingQuestTitleRows[loadedQuestID]
        if registrations then
            pendingQuestTitleRows[loadedQuestID] = nil
            for _, registration in ipairs(registrations) do
                registration.row.label = ns.ResolveProfessionEntryLabel(registration.entry, registration.fallback, registration.preferFallback)
            end
        end
        RequestLabelRefresh()
    end)
end

function ns.GetCoordinateFallback(entry, prefix)
    local zoneName
    if entry and entry.zone and C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, entry.zone)
        if ok and info and info.name and info.name ~= "" then
            zoneName = info.name
        end
    end
    if entry and entry.x and entry.y then
        if zoneName then
            return ("%s - %s (%.1f, %.1f)"):format(prefix or "Knowledge Treasure", zoneName, entry.x, entry.y)
        end
        return ("%s (%.1f, %.1f)"):format(prefix or "Knowledge Treasure", entry.x, entry.y)
    end
    if zoneName then
        return ("%s - %s"):format(prefix or "Knowledge Treasure", zoneName)
    end
    return prefix
end

function ns.ResolveProfessionEntryLabel(entry, fallback, preferFallback)
    if entry and entry.itemID then
        if itemNameCache[entry.itemID] then
            return itemNameCache[entry.itemID]
        end
        local itemName = GetItemInfo(entry.itemID)
        if itemName and itemName ~= "" then
            itemNameCache[entry.itemID] = itemName
            return itemName
        end

        TrackPendingLabel(PENDING_PLACEHOLDER, entry.itemID)
    end

    if entry and entry.preferFallbackLabel then
        local label = entry.label or entry.mainMenuLabel or fallback
        if label and label ~= "" then
            return label
        end
    end

    if entry and not entry.itemID then
        local questID = entry.questID or (entry.questIDs and entry.questIDs[1])
        local rewardItemID = GetQuestRewardItemID(questID)
        if rewardItemID then
            if itemNameCache[rewardItemID] then
                return itemNameCache[rewardItemID]
            end
            local rewardName = GetItemInfo(rewardItemID)
            if rewardName and rewardName ~= "" then
                itemNameCache[rewardItemID] = rewardName
                return rewardName
            end
            TrackPendingLabel(PENDING_PLACEHOLDER, rewardItemID)
        end
    end

    local questTitle = GetQuestTitle(entry)
    if questTitle then
        if preferFallback and IsGenericKnowledgeTreasureTitle(questTitle) then
            return fallback or questTitle
        end
        return questTitle
    end

    return entry and (entry.label or entry.mainMenuLabel or (preferFallback and fallback) or entry.note or fallback) or fallback
end

function TrackPendingQuestTitle(row, entry, fallback, preferFallback)
    local questID = entry and (entry.questID or (entry.questIDs and entry.questIDs[1]))
    if not (row and questID) then return end
    if questTitleCache[questID] then return end
    if not questTitlePending[questID] then return end

    pendingQuestTitleRows[questID] = pendingQuestTitleRows[questID] or {}
    UpsertPendingRow(pendingQuestTitleRows[questID], row, {
        row = row,
        entry = entry,
        fallback = fallback,
        preferFallback = preferFallback,
    })
    EnsureQuestTitleWatchFrame()
end

local function GetWeeklyEntryLabel(entry)
    return ns.ResolveProfessionEntryLabel(entry, (entry and entry.itemID and WEEKLY_DROP_ITEM_LABELS[entry.itemID]) or "Weekly Knowledge")
end

local function BuildWeeklyGroupedRows(section)
    local rows, orderByKey = {}, {}
    local rowKeyCounts = {}
    for _, entry in ipairs(section.entries or {}) do
        if entry.rowKey then
            rowKeyCounts[entry.rowKey] = (rowKeyCounts[entry.rowKey] or 0) + 1
        end
    end

    for index, entry in ipairs(section.entries or {}) do
        local rowKey = entry.rowKey
        local questIds = {}
        if entry.questIDs then
            for _, qid in ipairs(entry.questIDs) do table.insert(questIds, qid) end
        elseif entry.questID then
            table.insert(questIds, entry.questID)
        end

        local key = GetWeeklyEntryRowKey(entry, index, rowKeyCounts)
        local label = GetWeeklyEntryLabel(entry)
        local row = {
            key = key,
            professionKnowledgeEntry = entry,
            colorKey = rowKey,
            questIds = questIds,
            label = label,
            max = (entry.mode == "count") and (entry.required or #questIds) or 1,
            mode = entry.mode,
            required = entry.required,
            note = entry.note,
            itemID = entry.itemID,
            kind = entry.kind,
            kp = entry.kp,
            kpTotal = ((entry.mode == "count") and (entry.required or #questIds) or 1) * (entry.kp or 0),
            zone = entry.zone,
            x = entry.x,
            y = entry.y,
            questLocations = entry.questLocations,
            profKnowledgeSectionKey = (entry.kind == "darkmoon") and "darkmoon" or "weekly",
            rowKey = entry.rowKey or key,
            isVisible = (entry.kind == "darkmoon") and function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end or nil,
            group = (entry.kind == "darkmoon") and "darkmoon" or "weekly",
        }
        rows[#rows + 1] = row
        orderByKey[key] = ((entry.mainMenuOrder or 999) * 1000) + index

        if entry.itemID and TrackPendingLabel and not GetItemInfo(entry.itemID) then
            TrackPendingLabel(row, entry.itemID)
        end
        if #questIds > 0 then
            TrackPendingQuestTitle(row, entry, (entry and entry.itemID and WEEKLY_DROP_ITEM_LABELS[entry.itemID]) or "Weekly Knowledge", entry.preferFallbackLabel)
        end
    end
    table.sort(rows, function(a, b) return orderByKey[a.key] < orderByKey[b.key] end)
    return rows
end

function TrackPendingLabel(row, itemID)
    pendingLabelRows = pendingLabelRows or {}
    pendingLabelRows[itemID] = pendingLabelRows[itemID] or {}
    UpsertPendingRow(pendingLabelRows[itemID], row)

    if not itemLabelWatchFrame then
        itemLabelWatchFrame = CreateFrame("Frame")
        itemLabelWatchFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        itemLabelWatchFrame:SetScript("OnEvent", function(self, event, resolvedItemID)
            local rows = pendingLabelRows and pendingLabelRows[resolvedItemID]
            if not rows then return end
            local name = GetItemInfo(resolvedItemID)
            if not name or name == "" then return end
            itemNameCache[resolvedItemID] = name
            for _, row in ipairs(rows) do
                row.label = name
            end
            pendingLabelRows[resolvedItemID] = nil
            RequestLabelRefresh()
            if not next(pendingLabelRows) then
                self:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
            end
        end)
    else
        itemLabelWatchFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    end
end

local ROW_GROUP_LABEL_KEYS = {
    weekly = "ProfKnowledge_Section_Weekly",
    catchup = "Prof_Catchup",
    discoveries = "ProfKnowledge_Section_Discoveries",
    studies = "ProfKnowledge_Section_Studies",
    treasures = "ProfKnowledge_Section_Discoveries",
    books = "ProfKnowledge_Section_Books",
    darkmoon = "ProfKnowledge_Section_Darkmoon",
}

local ROW_GROUP_LABEL_FALLBACKS = {
    treasures = "One-Time Discoveries",
    books = "Knowledge Books",
}

function ns.GetRowGroupLabel(group)
    local labelKey = ROW_GROUP_LABEL_KEYS[group]
    local label = (labelKey and L[labelKey]) or ROW_GROUP_LABEL_FALLBACKS[group] or group
    if group == "catchup" then
        label = tostring(label or "Catch-Up Knowledge")
        label = label:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub(":%s*$", "")
    end
    return label
end

function ns.GetProfessionModuleKey(expansionKey, profession)
    if not profession then return nil end
    if not expansionKey or expansionKey == "midnight" then
        return "prof_" .. profession.key
    end
    return "prof_" .. expansionKey .. "_" .. profession.key
end

function Slug(value)
    value = tostring(value or "row"):lower()
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    value = value:gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if value == "" then value = "row" end
    return value
end

function ns.GetEntryMainMenuKey(sectionKey, entry)
    if entry.rowKey then
        return entry.rowKey
    end
    local questID = entry.questID or (entry.questIDs and entry.questIDs[1])
    if sectionKey == "discoveries" then
        return questID and ("disc_" .. questID) or nil
    elseif sectionKey == "studies" then
        return questID and ("study_" .. questID) or nil
    elseif sectionKey == "treasures" then
        return questID and ("treasure_" .. questID) or nil
    elseif sectionKey == "books" then
        if questID then
            return "book_" .. questID
        end
    end
    if entry.itemID then
        return sectionKey .. "_item_" .. entry.itemID
    end
    return sectionKey .. "_" .. Slug(entry.label or entry.note)
end

function ns.BuildMainMenuRows(profession, expansion)
    local rows = {}
    local darkmoonRows = {}

    local weekly = FindSection(profession, "weekly")
    if weekly then
        for _, row in ipairs(BuildWeeklyGroupedRows(weekly)) do
            if row.group == "darkmoon" then
                darkmoonRows[#darkmoonRows + 1] = row
            else
                rows[#rows + 1] = row
            end
        end
    end

    local sharedCatchupItemID = expansion and expansion.sharedCatchupItemID
    if profession.catchupCurrency or sharedCatchupItemID then
        rows[#rows + 1] = {
            key = "prof_catchup",
            profKnowledgeCatchup = true,
            profKnowledgeProfessionLabel = profession.label,
            profKnowledgeProfessionKey = profession.key,
            profKnowledgeExpansionKey = (expansion and expansion.key) or "midnight",
            currencyId = profession.catchupCurrency,
            itemId = sharedCatchupItemID,
            itemID = sharedCatchupItemID,
            noMax = sharedCatchupItemID and true or nil,
            noBlizzardTooltip = true,
            hideWallet = true,
            label = L["Prof_Catchup"],
            note = L["Prof_Catchup_Note"],
            max = 0,
            kpTotal = 0,
            group = "catchup",
        }
    end

    for _, sectionKey in ipairs({ "discoveries", "studies", "treasures", "books" }) do
        local section = FindSection(profession, sectionKey)
        if section then
            for _, entry in ipairs(section.entries) do
                local key = ns.GetEntryMainMenuKey(sectionKey, entry)
                if key then
                    local fallbackLabel = ns.GetRowGroupLabel(sectionKey) or profession.label
                    local preferFallback = sectionKey == "treasures"
                    if preferFallback then
                        fallbackLabel = ns.GetCoordinateFallback(entry, "Knowledge Treasure")
                    end
                    local row = {
                        key = key,
                        professionKnowledgeEntry = entry,
                        questIds = entry.questIDs or { entry.questID },
                        label = ns.ResolveProfessionEntryLabel(entry, fallbackLabel, preferFallback),
                        max = 1,
                        note = entry.note,
                        itemID = entry.itemID,
                        kind = entry.kind,
                        kp = entry.kp,
                        kpTotal = entry.kp or 0,
                        zone = entry.zone,
                        x = entry.x,
                        y = entry.y,
                        questLocations = entry.questLocations,
                        profKnowledgeSectionKey = sectionKey,
                        rowKey = entry.rowKey or key,
                        group = sectionKey,
                    }
                    rows[#rows + 1] = row
                    if entry.itemID and not GetItemInfo(entry.itemID) then
                        TrackPendingLabel(row, entry.itemID)
                    end
                    if entry.questID or entry.questIDs then
                        TrackPendingQuestTitle(row, entry, fallbackLabel, preferFallback)
                    end
                end
            end
        end
    end

    local darkmoon = FindSection(profession, "darkmoon")
    if darkmoon then
        for _, entry in ipairs(darkmoon.entries) do
            if entry.rowKey and entry.questID then
                darkmoonRows[#darkmoonRows + 1] = {
                    key = entry.rowKey,
                    professionKnowledgeEntry = entry,
                    questIds = { entry.questID },
                    label = ns.ResolveProfessionEntryLabel(entry, entry.mainMenuLabel),
                    max = 1,
                    note = entry.note,
                    itemID = entry.itemID,
                    kind = entry.kind,
                    kp = entry.kp,
                    kpTotal = entry.kp or 0,
                    zone = entry.zone,
                    x = entry.x,
                    y = entry.y,
                    questLocations = entry.questLocations,
                    profKnowledgeSectionKey = "darkmoon",
                    rowKey = entry.rowKey,
                    isVisible = function() return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible() end,
                    group = "darkmoon",
                }
            end
        end
    end

    for _, row in ipairs(darkmoonRows) do
        rows[#rows + 1] = row
    end

    return rows
end

function ns.BuildLureRows(profession)
    local lures = FindSection(profession, "lures")
    if not lures then return nil end

    local rows = {}
    for _, entry in ipairs(lures.entries) do
        if entry.rowKey and entry.questID then
            rows[#rows + 1] = {
                key = entry.rowKey,
                professionKnowledgeEntry = entry,
                questIds = { entry.questID },
                label = ns.ResolveProfessionEntryLabel(entry, entry.mainMenuLabel or entry.label),
                max = 1,
                note = entry.note,
                itemID = entry.itemID,
                kind = entry.kind,
                kp = entry.kp,
                kpTotal = entry.kp or 0,
                zone = entry.zone,
                x = entry.x,
                y = entry.y,
                questLocations = entry.questLocations,
                profKnowledgeSectionKey = "lures",
                rowKey = entry.rowKey,
                isVisible = entry.isVisible,
                group = "lures",
            }
        end
    end
    return rows
end

function ns.RegisterProfessionMainMenuModule(profession, expansion)
    if not (MR and MR.RegisterModule) then
        return
    end

    local expansionKey = (expansion and expansion.key) or "midnight"
    local rows = ns.BuildMainMenuRows(profession, expansion)
    if #rows > 0 then
        MR:RegisterModule({
            key = ns.GetProfessionModuleKey(expansionKey, profession),
            expansionKey = expansionKey,
            profSkillLine = profession.skillLine,
            label = profession.label,
            labelColor = ColorToHex(profession.color),
            defaultEnabled = expansionKey == "midnight",
            resetType = "weekly",
            defaultOpen = false,
            rows = rows,
        })
    end

    local lureRows = expansionKey == "midnight" and ns.BuildLureRows(profession)
    if lureRows and #lureRows > 0 then
        MR:RegisterModule({
            key = "skin_lures",
            profSkillLine = profession.skillLine,
            label = L["Skin_Lures_Title"],
            labelColor = ColorToHex(profession.color),
            resetType = "daily",
            defaultOpen = false,
            rows = lureRows,
        })
    end

end
