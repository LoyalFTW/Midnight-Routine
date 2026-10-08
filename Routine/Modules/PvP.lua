local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers["PvP"] = function(owner, context)
    local ns = context.namespace
    if ns.MR.isForever then return end
    local MR = ns.MR

    local L = context.labels

    local HONOR_CAP        = 15000
    local CONQUEST_CAP     = 1600
    local BLOODY_TOKEN_CAP = 1600

    local CURRENCY_HONOR        = 1792
    local CURRENCY_CONQUEST     = 1602
    local CURRENCY_BLOODY_TOKEN = 2123

    local QUEST_ENSHROUDED_IN_ARENAS = 93499
    local QUEST_ENSHROUDED_IN_BATTLE = 93506
    local QUEST_ENSHROUDED_IN_WAR    = 93505
    local QUEST_ENSHROUDED_SOLO      = 93502
    local QUEST_SPARKS_EVERSONG      = 93423
    local QUEST_SPARKS_ZULAMAN        = 93424
    local QUEST_SPARKS_HARANDAR       = 93425
    local QUEST_SPARKS_VOIDSTORM      = 93426
    local QUEST_SOMETHING_DIFFERENT   = 47148

    local ZERELLA_NPC_ID = 254971
    local ZERELLA_MAP_ID = 2393
    local ZERELLA_X = 36.2
    local ZERELLA_Y = 81.0
    local ZERELLA_PROGRESS_KEY = "pvp_weeklies"
    local ZERELLA_RESOLVED_KEY = "zerella_offer_resolved"

    local ZERELLA_WEEKLIES = {
        {
            key = "enshrouded_in_arenas",
            questId = QUEST_ENSHROUDED_IN_ARENAS,
            label = L["PvP_EnshroudedArenas_Label"] or "|cffcc3333Enshrouded in Arenas:|r",
            note = L["PvP_ZerellaWeekly_Note"] or "Rotating weekly from Zerella in Silvermoon.",
        },
        {
            key = "enshrouded_in_battle",
            questId = QUEST_ENSHROUDED_IN_BATTLE,
            label = L["PvP_EnshroudedBattle_Label"] or "|cffcc3333Enshrouded in Battle:|r",
            note = L["PvP_ZerellaWeekly_Note"] or "Rotating weekly from Zerella in Silvermoon.",
        },
        {
            key = "enshrouded_in_war",
            questId = QUEST_ENSHROUDED_IN_WAR,
            label = L["PvP_EnshroudedWar_Label"] or "|cffcc3333Enshrouded in War:|r",
            note = L["PvP_ZerellaWeekly_Note"] or "Rotating weekly from Zerella in Silvermoon.",
        },
        {
            key = "enshrouded_solo",
            questId = QUEST_ENSHROUDED_SOLO,
            label = L["PvP_EnshroudedSolo_Label"] or "|cffcc3333Enshrouded Solo:|r",
            note = L["PvP_ZerellaWeekly_Note"] or "Rotating weekly from Zerella in Silvermoon.",
        },
        {
            key = "something_different",
            questId = QUEST_SOMETHING_DIFFERENT,
            label = L["PvP_Brawl_Label"],
            note = L["PvP_Brawl_Note"],
        },
        {
            key = "sparks_of_war_eversong",
            questId = QUEST_SPARKS_EVERSONG,
            label = L["PvP_Sparks_Eversong"] or "Sparks of War: Eversong Woods",
            note = L["PvP_Sparks_Note"],
        },
        {
            key = "sparks_of_war_harandar",
            questId = QUEST_SPARKS_HARANDAR,
            label = L["PvP_Sparks_Harandar"],
            note = L["PvP_Sparks_Note"],
        },
        {
            key = "sparks_of_war_voidstorm",
            questId = QUEST_SPARKS_VOIDSTORM,
            label = L["PvP_Sparks_Voidstorm"],
            note = L["PvP_Sparks_Note"],
        },
        {
            key = "sparks_of_war_zulaman",
            questId = QUEST_SPARKS_ZULAMAN,
            label = L["PvP_Sparks_ZA"],
            note = L["PvP_Sparks_Note"],
        },
    }

    local function GetPvPWeekliesProgress()
        return MR and MR.db and MR.db.char and MR.db.char.progress and MR.db.char.progress[ZERELLA_PROGRESS_KEY]
    end

    local function GetOfferedKey(rowKey)
        return rowKey .. "_offered_this_week"
    end

    local IsQuestCurrentlyActive

    local ColorsEqual = tracking.Helpers.ColorsEqual

    local function SyncZerellaOfferState(progressBucket)
        if type(progressBucket) ~= "table" then
            return false
        end

        local anyTracked = false
        for _, weekly in ipairs(ZERELLA_WEEKLIES) do
            if IsQuestCurrentlyActive(weekly.questId)
                or (C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(weekly.questId))
                or progressBucket[weekly.key .. "_seen_active"]
                or (tonumber(progressBucket[weekly.key]) or 0) > 0
            then
                anyTracked = true
            end
        end

        if not anyTracked then
            return false
        end

        local changed = progressBucket[ZERELLA_RESOLVED_KEY] ~= true
        progressBucket[ZERELLA_RESOLVED_KEY] = true
        for _, weekly in ipairs(ZERELLA_WEEKLIES) do
            local offered = (IsQuestCurrentlyActive(weekly.questId)
                or (C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(weekly.questId))
                or progressBucket[weekly.key .. "_seen_active"]
                or (tonumber(progressBucket[weekly.key]) or 0) > 0) and true or false
            local offeredKey = GetOfferedKey(weekly.key)
            if progressBucket[offeredKey] ~= offered then
                progressBucket[offeredKey] = offered
                changed = true
            end
        end

        return changed
    end

    IsQuestCurrentlyActive = function(questId)
        if not questId then
            return false
        end

        if C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(questId) then
            return true
        end

        if MR.IsQuestOfferVisible and MR:IsQuestOfferVisible(questId) then
            return true
        end

        if GetQuestID and GetQuestID() == questId then
            return true
        end

        if C_GossipInfo and C_GossipInfo.GetAvailableQuests then
            local availableQuests = C_GossipInfo.GetAvailableQuests()
            if availableQuests then
                for _, info in ipairs(availableQuests) do
                    if info.questID == questId then
                        return true
                    end
                end
            end
        end

        return false
    end

    local function UpdateRotatingWeeklyQuestState(progressBucket, row, questId)
        if type(progressBucket) ~= "table" or type(row) ~= "table" or not row.key or not questId then
            return false, false, false
        end

        local seenKey = row.key .. "_seen_active"
        local isActive = IsQuestCurrentlyActive(questId)
        local isCompleted = C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questId) or false
        local wasDone = (tonumber(progressBucket[row.key]) or 0) > 0
        local prevSeenActive = progressBucket[seenKey] and true or false
        local prevValue = tonumber(progressBucket[row.key]) or 0
        local prevCountText = row.countText
        local prevCountColor = row.countColor

        if isActive then
            progressBucket[seenKey] = true
        end

        local isDone = wasDone
        if isCompleted and (isActive or progressBucket[seenKey]) then
            isDone = true
        elseif not isActive and not wasDone then
            isDone = false
        end

        progressBucket[row.key] = isDone and 1 or 0
        row.countText = isDone and (L["Done"] or "Done") or (isActive and (L["Weekly_SA_Count_ActiveSingle"] or "Active") or nil)
        row.countColor = isDone and { 0.4, 0.85, 0.4 } or (isActive and { 1, 0.9, 0.3 } or nil)

        local changed = prevSeenActive ~= (progressBucket[seenKey] and true or false)
            or prevValue ~= (progressBucket[row.key] or 0)
            or prevCountText ~= row.countText
            or not ColorsEqual(prevCountColor, row.countColor)

        return isActive, isDone, changed
    end

    local function IsTrackedPvPWeeklyVisible(rowKey, questId)
        local mdb = GetPvPWeekliesProgress()
        local seenActive = mdb and mdb[rowKey .. "_seen_active"]
        local seenDone = mdb and (tonumber(mdb[rowKey]) or 0) > 0

        return IsQuestCurrentlyActive(questId)
            or seenActive
            or seenDone
    end

    MR:RegisterModule({
        key         = "pvp_currencies",
        label       = L["PvP_CurrenciesTitle"],
        labelColor  = "#cc3333",
        resetType   = "weekly",
        defaultOpen = true,
        rows = {
            {
                key        = "honor",
                currencyId = CURRENCY_HONOR,
                max        = HONOR_CAP,
                label      = L["PvP_Honor_Label"],
                note       = L["PvP_Honor_Note"],
            },
            {
                key        = "conquest",
                currencyId = CURRENCY_CONQUEST,
                max        = CONQUEST_CAP,
                label      = L["PvP_Conquest_Label"],
                note       = L["PvP_Conquest_Note"],
            },
            {
                key        = "bloody_tokens",
                currencyId = CURRENCY_BLOODY_TOKEN,
                max        = BLOODY_TOKEN_CAP,
                label      = L["PvP_BloodyTokens_Label"],
                note       = L["PvP_BloodyTokens_Note"],
            },
        },
    })

    MR:RegisterModule({
        key         = "pvp_weeklies",
        label       = L["PvP_WeekliesTitle"],
        labelColor  = "#cc3333",
        resetType   = "weekly",
        defaultOpen = true,
        scanReturnsChanged = true,
        onScan = function(mod)
            local progress = MR.db.char.progress
            if not progress[mod.key] then
                progress[mod.key] = {}
            end

            local progressBucket = progress[mod.key]
            local changed = SyncZerellaOfferState(progressBucket)

            for _, row in ipairs(mod.rows) do
                local _, _, rowChanged = UpdateRotatingWeeklyQuestState(progressBucket, row, row.questIds and row.questIds[1] or nil)
                changed = changed or rowChanged
                if row.key == "zerella_check" then
                    if row.countText ~= nil or row.countColor ~= nil then
                        changed = true
                    end
                    row.countText = nil
                    row.countColor = nil
                end
            end

            return changed
        end,
        rows = (function()
            local rows = {
                {
                    key = "zerella_check",
                    label = L["PvP_ZerellaCheck_Label"] or "|cffcc3333Go meet Zerella:|r",
                    max = 1,
                    note = L["PvP_ZerellaCheck_Note"] or "Talk to NPC 254971 in Silvermoon to reveal this week's PvP quests.",
                    zone = ZERELLA_MAP_ID,
                    x = ZERELLA_X,
                    y = ZERELLA_Y,
                    npcID = ZERELLA_NPC_ID,
                    waypointTitle = "Zerella (254971)",
                    isVisible = function()
                        local mdb = GetPvPWeekliesProgress()
                        return not (mdb and mdb[ZERELLA_RESOLVED_KEY])
                    end,
                },
            }

            for _, weekly in ipairs(ZERELLA_WEEKLIES) do
                rows[#rows + 1] = {
                    key = weekly.key,
                    label = weekly.label,
                    max = 1,
                    note = weekly.note,
                    questIds = { weekly.questId },
                    isVisible = function()
                        local mdb = GetPvPWeekliesProgress()
                        if not (mdb and mdb[ZERELLA_RESOLVED_KEY]) then
                            return false
                        end
                        if mdb[GetOfferedKey(weekly.key)] then
                            return true
                        end
                        return IsTrackedPvPWeeklyVisible(weekly.key, weekly.questId)
                    end,
                }
            end

            return rows
        end)(),
    })
end
