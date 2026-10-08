local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers["ProfessionKnowledgeCore"] = function(owner, context)
    local ns = context.namespace
    if ns.MR.isForever then return end
    local MR = ns.MR
    local L = context.labels

    local ENTRY_FIELDS = {
        "kind", "mode", "itemID", "questID", "questIDs", "kp", "zone", "x", "y",
        "altZone", "altX", "altY", "note", "rowKey", "mainMenuLabel", "mainMenuOrder",
        "label", "required", "requiredItems", "preferFallbackLabel", "questLocations",
        "isVisible", "reference", "profKnowledgeSectionKey", "profKnowledgeProfessionKey",
        "profKnowledgeExpansionKey", "key", "colorKey", "questIds", "max", "kpTotal", "group",
    }

    local ENTRY_FIELD_INDEX = {}
    for index, field in ipairs(ENTRY_FIELDS) do
        ENTRY_FIELD_INDEX[field] = index
    end

    local ENTRY_META = {
        __index = function(entry, key)
            local index = ENTRY_FIELD_INDEX[key]
            if not index then return nil end
            return rawget(entry, index)
        end,
        __newindex = function(entry, key, value)
            local index = ENTRY_FIELD_INDEX[key]
            if index then
                rawset(entry, index, value)
            else
                rawset(entry, key, value)
            end
        end,
    }

    local compactEntryCount = 0

    local function E(kind, data)
        data.kind = kind
        local entry = {}
        for index, field in ipairs(ENTRY_FIELDS) do
            local value = data[field]
            if value ~= nil then
                entry[index] = value
            end
        end
        for key, value in pairs(data) do
            if not ENTRY_FIELD_INDEX[key] then
                entry[key] = value
            end
        end
        compactEntryCount = compactEntryCount + 1
        return setmetatable(entry, ENTRY_META)
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
    local EnsureQuestTitleWatchFrame
    local questTitlePending = {}
    local questTitleFailed = {}
    local itemLabelFailed = {}
    local questRewardItemCache = {}
    local labelRefreshPending
    local labelGeneration = 0

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
        local primedModules = 0
        for _, mod in ipairs(self.modules or {}) do
            if mod._professionKnowledgePrimed then
                primedModules = primedModules + 1
            end
        end

        return {
            itemNames = 0,
            questTitles = 0,
            questTitlePending = CountMapEntries(questTitlePending),
            pendingQuestRows = 0,
            rewardItems = CountMapEntries(questRewardItemCache),
            pendingLabels = CountMapEntries(pendingLabelRows),
            primedModules = primedModules,
            catalogEntries = compactEntryCount,
        }
    end

    local function RequestLabelRefresh()
        if labelRefreshPending then return end
        labelRefreshPending = true
        C_Timer.After(2, function()
            labelRefreshPending = false
            MR:OnTrackerLabelsChanged()
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
            local title = C_QuestLog.GetTitleForQuestID(questID)
            if title and title ~= "" then
                questTitlePending[questID] = nil
                questTitleFailed[questID] = nil
                return title
            end
            if C_QuestLog.RequestLoadQuestByID and not questTitlePending[questID] and not questTitleFailed[questID] then
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
            if not questTitlePending[loadedQuestID] then return end

            questTitlePending[loadedQuestID] = nil
            local changed = false
            if success then
                local title = C_QuestLog.GetTitleForQuestID(loadedQuestID)
                changed = title and title ~= "" or false
                local rewardItemID = GetQuestRewardItemID(loadedQuestID, true)
                if rewardItemID then
                    local rewardName = GetItemInfo(rewardItemID)
                    if rewardName and rewardName ~= "" then
                        changed = true
                    else
                        TrackPendingLabel(rewardItemID)
                    end
                end
            end

            if changed then
                questTitleFailed[loadedQuestID] = nil
                labelGeneration = labelGeneration + 1
                RequestLabelRefresh()
            else
                questTitleFailed[loadedQuestID] = true
            end
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
            local itemName = GetItemInfo(entry.itemID)
            if itemName and itemName ~= "" then
                itemLabelFailed[entry.itemID] = nil
                return itemName
            end

            if not itemLabelFailed[entry.itemID] then
                TrackPendingLabel(entry.itemID)
            end
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
                local rewardName = GetItemInfo(rewardItemID)
                if rewardName and rewardName ~= "" then
                    itemLabelFailed[rewardItemID] = nil
                    return rewardName
                end
                if not itemLabelFailed[rewardItemID] then
                    TrackPendingLabel(rewardItemID)
                end
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

    local function GetWeeklyEntryLabel(entry)
        return entry and (entry.label or entry.mainMenuLabel or (entry.itemID and WEEKLY_DROP_ITEM_LABELS[entry.itemID]) or entry.note) or "Weekly Knowledge"
    end

    local function IsDarkmoonRowVisible()
        return MR.IsDarkmoonVisible and MR.IsDarkmoonVisible()
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
            local questIds = entry.questIDs
            local questCount = questIds and #questIds or (entry.questID and 1 or 0)

            local key = GetWeeklyEntryRowKey(entry, index, rowKeyCounts)
            local required = (entry.mode == "count") and (entry.required or questCount) or 1
            local row = entry
            row.key = key
            row.colorKey = rowKey
            row.questIds = questIds
            row.label = GetWeeklyEntryLabel(entry)
            row.max = required
            row.kpTotal = required * (entry.kp or 0)
            row.profKnowledgeSectionKey = (entry.kind == "darkmoon") and "darkmoon" or "weekly"
            row.rowKey = entry.rowKey or key
            row.isVisible = (entry.kind == "darkmoon") and IsDarkmoonRowVisible or nil
            row.group = (entry.kind == "darkmoon") and "darkmoon" or "weekly"
            rows[#rows + 1] = row
            orderByKey[key] = ((entry.mainMenuOrder or 999) * 1000) + index
        end
        table.sort(rows, function(a, b) return orderByKey[a.key] < orderByKey[b.key] end)
        return rows
    end

    function TrackPendingLabel(itemID)
        if not itemID then return end
        pendingLabelRows = pendingLabelRows or {}
        pendingLabelRows[itemID] = true

        if not itemLabelWatchFrame then
            itemLabelWatchFrame = CreateFrame("Frame")
            itemLabelWatchFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
            itemLabelWatchFrame:SetScript("OnEvent", function(self, event, resolvedItemID, success)
                if not (pendingLabelRows and pendingLabelRows[resolvedItemID]) then return end
                pendingLabelRows[resolvedItemID] = nil
                local name = success ~= false and GetItemInfo(resolvedItemID)
                if name and name ~= "" then
                    itemLabelFailed[resolvedItemID] = nil
                    labelGeneration = labelGeneration + 1
                    RequestLabelRefresh()
                else
                    itemLabelFailed[resolvedItemID] = true
                end
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
        holidays = "Holidays_Title",
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
                        local row = entry
                        row.key = key
                        row.questIds = entry.questIDs
                        row.label = entry.label or entry.mainMenuLabel or fallbackLabel
                        row.max = 1
                        row.kpTotal = entry.kp or 0
                        row.profKnowledgeSectionKey = sectionKey
                        row.rowKey = entry.rowKey or key
                        row.group = sectionKey
                        rows[#rows + 1] = row
                    end
                end
            end
        end

        local darkmoon = FindSection(profession, "darkmoon")
        if darkmoon then
            for _, entry in ipairs(darkmoon.entries) do
                if entry.rowKey and entry.questID then
                    entry.key = entry.rowKey
                    entry.questIds = entry.questIDs
                    entry.label = entry.label or entry.mainMenuLabel or L["ProfKnowledge_Section_Darkmoon"]
                    entry.max = 1
                    entry.kpTotal = entry.kp or 0
                    entry.profKnowledgeSectionKey = "darkmoon"
                    entry.isVisible = IsDarkmoonRowVisible
                    entry.group = "darkmoon"
                    darkmoonRows[#darkmoonRows + 1] = entry
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
                entry.key = entry.rowKey
                entry.questIds = entry.questIDs
                entry.label = entry.label or entry.mainMenuLabel or L["Skin_Lures_Title"]
                entry.max = 1
                entry.kpTotal = entry.kp or 0
                entry.profKnowledgeSectionKey = "lures"
                entry.group = "lures"
                rows[#rows + 1] = entry
            end
        end
        return rows
    end

    function MR:PrimeProfessionKnowledgeModuleLabels(mod)
        if not (mod and mod.profSkillLine) then
            return
        end
        if mod._professionKnowledgeLabelGeneration == labelGeneration then return end
        mod._professionKnowledgeLabelGeneration = labelGeneration
        mod._professionKnowledgePrimed = true
        for _, row in ipairs(mod.rows or {}) do
            local entry = row.professionKnowledgeEntry or (row.profKnowledgeSectionKey and row)
            if entry then
                if not row.questIds and entry.questID then
                    row.questIds = { entry.questID }
                end
                local fallback
                local preferFallback = entry.preferFallbackLabel == true or row.group == "treasures"
                if row.group == "weekly" then
                    fallback = (entry.itemID and WEEKLY_DROP_ITEM_LABELS[entry.itemID]) or "Weekly Knowledge"
                elseif row.group == "treasures" then
                    fallback = ns.GetCoordinateFallback(entry, "Knowledge Treasure")
                else
                    fallback = entry.mainMenuLabel or ns.GetRowGroupLabel(row.group) or mod.label
                end
                row.label = ns.ResolveProfessionEntryLabel(entry, fallback, preferFallback)
            end
        end
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
end
