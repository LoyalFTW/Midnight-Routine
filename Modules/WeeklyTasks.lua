local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local SA_ASSIGNMENTS = {
    { quest = 91390, unlock = 94865, name = L["SA_Temple"],    zone = 2437, zoneLabel = L["Zone_ZulAman"] },
    { quest = 91796, unlock = 94866, name = L["SA_Ours"],      zone = 2437, zoneLabel = L["Zone_ZulAman"] },
    { quest = 92063, unlock = 94390, name = L["SA_Hunter"],    zone = 2413, zoneLabel = L["Zone_Harandar"] },
    { quest = 92139, unlock = 95435, name = L["SA_Shade"],     zone = 2395, zoneLabel = L["Zone_EversongWoods"] },
    { quest = 92145, unlock = 92848, name = L["SA_Drink"],     zone = 2395, zoneLabel = L["Zone_EversongWoods"] },
    { quest = 93013, unlock = 94391, name = L["SA_Push"],      zone = 2413, zoneLabel = L["Zone_Harandar"] },
    { quest = 93244, unlock = 94795, name = L["SA_Agents"],    zone = 2405, zoneLabel = L["Zone_Voidstorm"] },
    { quest = 93438, unlock = 94743, name = L["SA_Precision"], zone = 2405, zoneLabel = L["Zone_Voidstorm"] },
}

local SEASON_2_AVAILABLE = MR:IsPatchAvailable("12.1.0")
if SEASON_2_AVAILABLE then
    SA_ASSIGNMENTS[#SA_ASSIGNMENTS + 1] = {
        quest = 95918,
        unlock = 96307,
        name = L["SA_WraithWrath"] or "Wraith Wrath",
        zone = 2512,
        zoneLabel = L["Zone_CoiledIsle"] or "The Coiled Isle",
    }
    SA_ASSIGNMENTS[#SA_ASSIGNMENTS + 1] = {
        quest = 95921,
        unlock = 96492,
        name = L["SA_DemandAndSupply"] or "Demand and Supply",
        zone = 2512,
        zoneLabel = L["Zone_CoiledIsle"] or "The Coiled Isle",
    }
    SA_ASSIGNMENTS[#SA_ASSIGNMENTS + 1] = {
        quest = 95922,
        unlock = 96029,
        name = L["SA_FaceTheSwarm"] or "Face the Swarm",
        zone = 2512,
        zoneLabel = L["Zone_CoiledIsle"] or "The Coiled Isle",
    }
end

local UATV_BRANCHES = {
    { quest = 93890, name = L["Unity_Abundance"]     },
    { quest = 93767, name = L["Unity_Arcantina"]     },
    { quest = 94457, name = L["Unity_Battlegrounds"] },
    { quest = 93909, name = L["Unity_Delves"]        },
    { quest = 93911, name = L["Unity_Dungeons"]      },
    { quest = 93769, name = L["Unity_Housing"]       },
    { quest = 93891, name = L["Unity_Legends"]       },
    { quest = 96727, name = L["Unity_OffworldShowdowns"] },
    { quest = 93910, name = L["Unity_Prey"]          },
    { quest = 93912, name = L["Unity_Raids"]         },
    { quest = 93889, name = L["Unity_Soiree"]        },
    { quest = 93892, name = L["Unity_Stormarion"]    },
    { quest = 94385, name = L["Unity_VoidAssaults"] or "Midnight: Void Assaults" },
    { quest = 94386, name = L["Unity_VoidAssaults"] or "Midnight: Void Assaults" },
    { quest = 93913, name = L["Unity_WorldBoss"]     },
    { quest = 93766, name = L["Unity_WorldQuests"]   },
    { quest = 95843, name = L["Unity_RitualSites"] or "Midnight: Ritual Sites" },
    { quest = 95842, name = L["Unity_VoidAssaults"] or "Midnight: Void Assaults" },
}

if SEASON_2_AVAILABLE then
    UATV_BRANCHES[#UATV_BRANCHES + 1] = {
        quest = 98232,
        name = L["Unity_VaultsAtalUtek"] or "Midnight: Vaults of Atal'Utek",
    }
end

local UATV_META_QUEST_IDS = {
    93744,
}

local UATV_SHARED_BRANCH_QUEST_IDS = {
    [94385] = true,
    [94386] = true,
}

local UATV_BRANCH_QUEST_IDS = {}
for _, branch in ipairs(UATV_BRANCHES) do
    UATV_BRANCH_QUEST_IDS[#UATV_BRANCH_QUEST_IDS + 1] = branch.quest
end

local HALDURON_WEEKLIES = {
    { quest = 93751, name = L["Halduron_WindrunnerSpire"]     },
    { quest = 93752, name = L["Halduron_MurderRow"]           },
    { quest = 93753, name = L["Halduron_MagistersTerrace"]   },
    { quest = 93754, name = L["Halduron_MaisaraCaverns"]     },
    { quest = 93755, name = L["Halduron_DenOfNalorakk"]      },
    { quest = 93756, name = L["Halduron_BlindingVale"]       },
    { quest = 93757, name = L["Halduron_VoidscarArena"]      },
    { quest = 93758, name = L["Halduron_NexusPointXenas"]    },
    { quest = 95468, name = L["Halduron_HopeDarkestCorners"] },
}

local ARCANTINA_WEEKLIES = {
    { quest = 92319, name = L["Arcantina_AFavorToAxe"] },
    { quest = 92321, name = L["Arcantina_AFrostbittenTally"] },
    { quest = 92320, name = L["Arcantina_StillBehindEnemyPortals"] },
    { quest = 92322, name = L["Arcantina_TimearForeseesProofOfDemise"] },
    { quest = 92323, name = L["Arcantina_WhereTheFireOnceBurned"] },
    { quest = 92324, name = L["Arcantina_UncrownedsColdCase"] },
    { quest = 92325, name = L["Arcantina_HellscreamsHeritage"] },
    { quest = 92326, name = L["Arcantina_TheFragranceOfTheDunes"] },
    { quest = 92327, name = L["Arcantina_AGenerationalMoment"] },
}

local VOID_ASSAULT_WEEKLIES = {
    { quest = 94385, mapId = 2395, name = L["Zone_EversongWoods"] or "Eversong Woods" },
    { quest = 94386, mapId = 2437, name = L["Zone_ZulAman"] or "Zul'Aman" },
}

local RITUAL_SITE_WEEKLIES = {
    { quest = 94880, mapId = 2395, name = L["Zone_EversongWoods"] or "Eversong Woods" },
    { quest = 94878, mapId = 2437, name = L["Zone_ZulAman"] or "Zul'Aman" },
}

local VOID_INVASION_SHOWDOWNS = {
    { quest = 96716, mapId = 2601, name = L["Weekly_Showdown_Val"] or "Showdown on Val" },
    { quest = 96720, mapId = 2600, name = L["Weekly_Showdown_Naigtal"] or "Showdown on Naigtal" },
    { quest = 96717, mapId = 2600, name = L["Weekly_Showdown_Naigtal"] or "Showdown on Naigtal" },
    { quest = 96718, mapId = 2600, name = L["Weekly_Showdown_Naigtal_Heroic"] or "Showdown on Naigtal (Heroic)" },
    { quest = 96713, mapId = 2601, name = L["Weekly_Showdown_Val"] or "Showdown on Val" },
    { quest = 96714, mapId = 2601, name = L["Weekly_Showdown_Val_Heroic"] or "Showdown on Val (Heroic)" },
}

local VOID_INVASION_DANGEROUS_HEROIC = {
    { quest = 97083, mapId = 2601, name = L["Weekly_DangerousEnemies_Val"] or "Dangerous Enemies: Val (Heroic)" },
    { quest = 97086, mapId = 2600, name = L["Weekly_DangerousEnemies_Naigtal"] or "Dangerous Enemies: Naigtal (Heroic)" },
}

local VOID_INVASION_DISRUPTION_HEROIC = {
    { quest = 97081, mapId = 2601, name = L["Weekly_MoreDisruptions_Val"] or "More Disruptions: Val (Heroic)" },
    { quest = 97087, mapId = 2600, name = L["Weekly_MoreDisruptions_Naigtal"] or "More Disruption: Naigtal (Heroic)" },
}

local ABYSS_ANGLERS_WEEKLY_QUEST_ID = 92447
local ABYSS_ANGLERS_INTRO_QUEST_ID = 96388

local LOST_LEGENDS_FIRST_TIME_RELICS = {
    { quest = 88993, name = L["Legends_WeynansWard"] },
    { quest = 88994, name = L["Legends_CauldronOfEchoes"] },
    { quest = 88995, name = L["Legends_AlnharasBloom"] },
    { quest = 88996, name = L["Legends_EcholessFlame"] },
    { quest = 88997, name = L["Legends_RussulasOutreach"] },
    { quest = 88998, name = L["Legends_RootOfTheWorld"] },
    { quest = 88999, name = L["Legends_SkysHope"] },
    { quest = 90733, name = L["Legends_TheListener"] or "The Listener" },
    { quest = 90734, name = L["Legends_InTheNameOfTheGoddess"] or "In the Name of the Goddess" },
}

local LOST_LEGENDS_REPEAT_RELICS = {
    { quest = 92716, name = L["Legends_WeynansWard"] },
    { quest = 92719, name = L["Legends_CauldronOfEchoes"] },
    { quest = 92720, name = L["Legends_AlnharasBloom"] },
    { quest = 92721, name = L["Legends_EcholessFlame"] },
    { quest = 92722, name = L["Legends_RussulasOutreach"] },
    { quest = 92724, name = L["Legends_RootOfTheWorld"] },
    { quest = 92725, name = L["Legends_SkysHope"] },
}

local LOST_LEGENDS_PATHS = {
    { master = 89268, relics = LOST_LEGENDS_FIRST_TIME_RELICS },
    { master = 92713, relics = LOST_LEGENDS_REPEAT_RELICS },
}

local LOST_LEGENDS_ALL_RELICS = {}
for _, path in ipairs(LOST_LEGENDS_PATHS) do
    for _, variant in ipairs(path.relics) do
        LOST_LEGENDS_ALL_RELICS[#LOST_LEGENDS_ALL_RELICS + 1] = variant
    end
end

local LOST_LEGENDS_QUEST_IDS = {}
for _, variant in ipairs(LOST_LEGENDS_ALL_RELICS) do
    LOST_LEGENDS_QUEST_IDS[#LOST_LEGENDS_QUEST_IDS + 1] = variant.quest
end

local function GetMainWeeklyProgress()
    local source = MR.GetMainFrameProgressSource and MR:GetMainFrameProgressSource() or (MR.db and MR.db.char)
    local progress = source and source.progress
    return progress and progress["s1_weekly"] or {}
end

local MIDNIGHT_MAP_IDS = {
    [2393] = true,
    [2395] = true,
    [2405] = true,
    [2413] = true,
    [2437] = true,
    [2512] = true,
    [2576] = true,
    [2635] = true,
    [2600] = true,
    [2601] = true,
}

local function IsPlayerInMidnightArea()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo) then
        return false
    end

    local mapId = C_Map.GetBestMapForUnit("player")
    local checked = 0
    while mapId and checked < 10 do
        if MIDNIGHT_MAP_IDS[mapId] then
            return true
        end

        local info = C_Map.GetMapInfo(mapId)
        if not info or not info.parentMapID or info.parentMapID == 0 then
            break
        end

        mapId = info.parentMapID
        checked = checked + 1
    end

    return false
end

local function IsPlayerInMapHierarchy(targetMapId)
    if not targetMapId or not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo) then
        return false
    end

    local mapId = C_Map.GetBestMapForUnit("player")
    local checked = 0
    while mapId and checked < 10 do
        if mapId == targetMapId then
            return true
        end

        local info = C_Map.GetMapInfo(mapId)
        if not info or not info.parentMapID or info.parentMapID == 0 then
            break
        end

        mapId = info.parentMapID
        checked = checked + 1
    end

    return false
end

local function GetMapName(_, fallback)
    return fallback
end

local function NormalizeActivityText(text)
    if type(text) ~= "string" then
        return ""
    end

    return text:lower():gsub("[^%a%d]", "")
end

local function ColorsEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end
    return (a[1] or 0) == (b[1] or 0)
        and (a[2] or 0) == (b[2] or 0)
        and (a[3] or 0) == (b[3] or 0)
        and (a[4] or 0) == (b[4] or 0)
end

local function ResolveVariantName(variant)
    if not variant then
        return nil
    end

    return MR:GetQuestName(variant.quest, variant.name)
end

local function GetVariantName(variants, index, fallback)
    local variant = variants and variants[index or 1]
    return (variant and variant.name) or fallback
end

local function GetVariantDisplayName(variant, fallback)
    return (variant and variant.name) or fallback or "Unknown"
end

local function IsQuestCurrentlyActive(questId)
    if not questId then
        return false
    end

    if C_QuestLog.IsOnQuest(questId) then
        return true
    end

    if C_QuestLog.IsWorldQuest and C_QuestLog.IsWorldQuest(questId) then
        if C_TaskQuest and C_TaskQuest.GetQuestTimeLeftSeconds then
            local timeLeft = C_TaskQuest.GetQuestTimeLeftSeconds(questId)
            if timeLeft and timeLeft > 0 then
                return true
            end
        end
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
        return false, false
    end

    local seenKey = row.key .. "_seen_active"
    local isActive = IsQuestCurrentlyActive(questId)
    local isCompleted = C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(questId) or false
    local wasDone = (tonumber(progressBucket[row.key]) or 0) > 0

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

    return isActive, isDone
end

local function ResolveDynamicAssignmentQuest(assignment)
    if assignment.quest or not assignment.dynamicTitle then
        return assignment.quest
    end
    if not (C_TaskQuest and C_TaskQuest.GetQuestsOnMap) then
        return nil
    end

    local expected = assignment.dynamicTitle:lower()
    for _, taskInfo in ipairs(C_TaskQuest.GetQuestsOnMap(assignment.zone) or {}) do
        local questId = taskInfo.questId or taskInfo.questID
        local title = questId and MR:GetQuestName(questId)
        if title and title:lower():find(expected, 1, true) then
            assignment.quest = questId
            return questId
        end
    end

    return nil
end

local function CollectSpecialAssignments()
    local completed = {}
    local active = {}
    local allowActive = IsPlayerInMidnightArea()

    for _, assignment in ipairs(SA_ASSIGNMENTS) do
        local questId = ResolveDynamicAssignmentQuest(assignment)
        local entry = {
            quest = questId,
            unlock = assignment.unlock,
            name = MR:GetQuestName(questId, assignment.name),
            zone = assignment.zone,
            zoneName = GetMapName(assignment.zone, assignment.zoneLabel),
        }

        if questId and C_QuestLog.IsQuestFlaggedCompleted(questId) then
            table.insert(completed, entry)
        elseif allowActive and (IsQuestCurrentlyActive(questId) or IsQuestCurrentlyActive(assignment.unlock)) then
            table.insert(active, entry)
        end
    end

    return completed, active
end

local function FindActiveQuestVariant(variants)
    for _, variant in ipairs(variants) do
        if IsQuestCurrentlyActive(variant.quest) then
            return {
                quest = variant.quest,
                name = ResolveVariantName(variant),
            }
        end
    end
    return nil
end

local function IsAnyQuestActive(questIds)
    for _, questId in ipairs(questIds or {}) do
        if IsQuestCurrentlyActive(questId) then
            return true
        end
    end

    return false
end

local function IsAnyQuestCompleted(questIds)
    if not (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) then
        return false
    end

    for _, questId in ipairs(questIds or {}) do
        if C_QuestLog.IsQuestFlaggedCompleted(questId) then
            return true
        end
    end

    return false
end

local function FindActiveUATVBranch(metaActive)
    local activeBranch = FindActiveQuestVariant(UATV_BRANCHES)
    if activeBranch and UATV_SHARED_BRANCH_QUEST_IDS[activeBranch.quest] and not metaActive then
        return nil
    end

    return activeBranch
end

local function IsSharedUATVBranchName(name)
    if type(name) ~= "string" or name == "" then
        return false
    end

    for _, branch in ipairs(UATV_BRANCHES) do
        if UATV_SHARED_BRANCH_QUEST_IDS[branch.quest] and name == ResolveVariantName(branch) then
            return true
        end
    end

    return false
end

local function CollectQuestVariants(variants)
    local completed = {}
    local active = {}

    for _, variant in ipairs(variants) do
        local entry = {
            quest = variant.quest,
            name = ResolveVariantName(variant),
        }

        if C_QuestLog.IsQuestFlaggedCompleted(variant.quest) then
            table.insert(completed, entry)
        elseif IsQuestCurrentlyActive(variant.quest) then
            table.insert(active, entry)
        end
    end

    return completed, active
end

local function FindActivityZoneFromAreaPois(variants, matchTerms)
    if not (C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIForMap and C_AreaPoiInfo.GetAreaPOIInfo) then
        return nil, nil, nil
    end

    for _, variant in ipairs(variants or {}) do
        local poiIds = C_AreaPoiInfo.GetAreaPOIForMap(variant.mapId)
        if poiIds then
            for _, poiId in ipairs(poiIds) do
                local info = C_AreaPoiInfo.GetAreaPOIInfo(variant.mapId, poiId)
                local poiName = info and info.name
                local normalized = NormalizeActivityText(poiName)
                if normalized ~= "" then
                    for _, term in ipairs(matchTerms) do
                        if normalized:find(term, 1, true) then
                            return variant.name, poiName, variant.mapId
                        end
                    end
                end
            end
        end
    end

    return nil, nil, nil
end

MR:RegisterModule({
    key         = "s1_weekly",
    label       = L["Weekly_SeasonTitle"],
    labelColor  = "#2ae7c6",
    resetType   = "weekly",
    defaultOpen = true,
    scanReturnsChanged = true,

    onScan = function(mod)
        local db = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end
        local previousRitualActiveName = db[mod.key]["ritual_site_active_name"]
        local previousRitualActiveMapId = db[mod.key]["ritual_site_active_map_id"]
        local previousRitualCompletedName = db[mod.key]["ritual_site_completed_name"]
        local previousRitualCompletedMapId = db[mod.key]["ritual_site_completed_map_id"]
        local previousUATVActiveName = db[mod.key]["uatv_branch_name"]
        local previousUATVCompletedName = db[mod.key]["uatv_completed_branch_name"]
        local beforeProgress = {}
        for key, value in pairs(db[mod.key]) do
            beforeProgress[key] = value
        end
        local beforeRows = {}
        for _, row in ipairs(mod.rows) do
            beforeRows[row.key] = {
                label = row.label,
                countText = row.countText,
                countColor = row.countColor and { unpack(row.countColor) } or nil,
                max = row.max,
                note = row.note,
            }
        end
        db[mod.key]["special_assignment"] = 0
        db[mod.key]["sa_active_name"] = nil
        db[mod.key]["sa_active_names"] = nil
        db[mod.key]["sa_active_zones"] = nil
        db[mod.key]["halduron_active_name"] = nil
        db[mod.key]["halduron_active_names"] = nil
        db[mod.key]["halduron_completed_name"] = nil
        db[mod.key]["halduron_completed_names"] = nil
        db[mod.key]["arcantina_active_name"] = nil
        db[mod.key]["arcantina_active_names"] = nil
        db[mod.key]["arcantina_completed_name"] = nil
        db[mod.key]["arcantina_completed_names"] = nil
        db[mod.key]["void_assault_active_name"] = nil
        db[mod.key]["void_assault_active_poi_name"] = nil
        db[mod.key]["void_assault_completed_name"] = nil
        db[mod.key]["ritual_site_active_name"] = nil
        db[mod.key]["ritual_site_active_map_id"] = nil
        db[mod.key]["ritual_site_active_poi_name"] = nil
        db[mod.key]["ritual_site_completed_name"] = nil
        db[mod.key]["ritual_site_completed_map_id"] = nil
        db[mod.key]["showdown_active_name"] = nil
        db[mod.key]["showdown_completed_name"] = nil

        local completedAssignments, activeAssignments = CollectSpecialAssignments()
        local totalAssignments = math.max(#completedAssignments + #activeAssignments, 1)
        db[mod.key]["special_assignment"] = #completedAssignments

        local detectedAssignments = (#activeAssignments > 0) and activeAssignments or completedAssignments
        if #detectedAssignments > 0 then
            local names = {}
            local zones = {}
            for _, assignment in ipairs(detectedAssignments) do
                names[#names + 1] = assignment.name
                zones[#zones + 1] = assignment.zoneName or ""
            end
            db[mod.key]["sa_active_name"] = names[1]
            db[mod.key]["sa_active_names"] = table.concat(names, " || ")
            db[mod.key]["sa_active_zones"] = table.concat(zones, " || ")
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "special_assignment" then
                row.max = totalAssignments
                if #activeAssignments > 0 then
                    row.countText = string.format(
                        L["Weekly_SA_Count_Active"] or "%d active",
                        #activeAssignments
                    )
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = string.format(
                        L["Weekly_SA_Note_Multi"] or "Detected %d active special assignments this week. Hover for the full list and zones.",
                        #activeAssignments
                    )
                elseif #completedAssignments > 1 then
                    row.countText = string.format(
                        L["Weekly_SA_Count_Completed"] or "%d done",
                        #completedAssignments
                    )
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = string.format(
                        L["Weekly_SA_Note_CompletedMulti"] or "Completed %d special assignments this week. Hover for the full list and zones.",
                        #completedAssignments
                    )
                elseif #completedAssignments == 1 and totalAssignments == 1 then
                    row.countText = L["Done"] or "Done"
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = L["Weekly_SA_Note"]
                elseif #completedAssignments > 0 then
                    row.countText = string.format(
                        L["Weekly_SA_Count_Completed"] or "%d done",
                        #completedAssignments
                    )
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = string.format(
                        L["Weekly_SA_Note_CompletedMulti"] or "Completed %d special assignments this week. Hover for the full list and zones.",
                        #completedAssignments
                    )
                elseif #detectedAssignments == 1 then
                    row.countText = L["Weekly_SA_Count_ActiveSingle"] or "Active"
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = L["Weekly_SA_Note"]
                else
                    row.countText = nil
                    row.countColor = nil
                    row.note = L["Weekly_SA_Note"]
                end
                break
            end
        end

        local completedVoidAssaultWeeklies, activeVoidAssaultWeeklies = CollectQuestVariants(VOID_ASSAULT_WEEKLIES)
        local activeVoidAssaultZone, activeVoidAssaultPoiName = FindActivityZoneFromAreaPois(
            VOID_ASSAULT_WEEKLIES,
            { "voidstrike", "voidincursion", "voidassault" }
        )
        if #activeVoidAssaultWeeklies > 0 then
            db[mod.key]["void_assault_active_name"] = activeVoidAssaultWeeklies[1].name
        elseif activeVoidAssaultZone then
            db[mod.key]["void_assault_active_name"] = activeVoidAssaultZone
        end
        db[mod.key]["void_assault_active_poi_name"] = activeVoidAssaultPoiName
        if #completedVoidAssaultWeeklies > 0 then
            db[mod.key]["void_assault_completed_name"] = completedVoidAssaultWeeklies[1].name
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "void_assaults" then
                if #completedVoidAssaultWeeklies > 0 then
                    row.countText = db[mod.key]["void_assault_completed_name"] or (L["Done"] or "Done")
                    row.countColor = { 0.4, 0.85, 0.4 }
                elseif db[mod.key]["void_assault_active_name"] then
                    row.countText = db[mod.key]["void_assault_active_name"]
                    row.countColor = { 1, 0.9, 0.3 }
                else
                    row.countText = nil
                    row.countColor = nil
                end
                break
            end
        end

        local activeLegendVariant = FindActiveQuestVariant(LOST_LEGENDS_ALL_RELICS)
        db[mod.key]["legends_active_name"] = activeLegendVariant and activeLegendVariant.name or nil
        for _, row in ipairs(mod.rows) do
            if row.key == "lost_legends" then
                row.label = activeLegendVariant
                    and ("|cff2ae7c6" .. activeLegendVariant.name .. ":|r")
                    or L["Weekly_Legends_Label"]
                break
            end
        end

        if activeLegendVariant then
            db[mod.key]["lost_legends"] = 0
            db[mod.key]["legends_completed_name"] = nil
        else
            for _, variant in ipairs(LOST_LEGENDS_REPEAT_RELICS) do
                if C_QuestLog.IsQuestFlaggedCompleted(variant.quest) then
                    db[mod.key]["lost_legends"] = 1
                    db[mod.key]["legends_completed_name"] = variant.name
                    break
                end
            end

            if (tonumber(db[mod.key]["lost_legends"]) or 0) >= 1
                and not db[mod.key]["legends_completed_name"] then
                for _, variant in ipairs(LOST_LEGENDS_FIRST_TIME_RELICS) do
                    if C_QuestLog.IsQuestFlaggedCompleted(variant.quest) then
                        db[mod.key]["legends_completed_name"] = variant.name
                        break
                    end
                end
            end
        end

        local completedRitualSiteWeeklies, activeRitualSiteWeeklies = CollectQuestVariants(RITUAL_SITE_WEEKLIES)
        local activeRitualSiteZone, activeRitualSitePoiName, activeRitualSiteMapId = FindActivityZoneFromAreaPois(
            RITUAL_SITE_WEEKLIES,
            { "ritualsite", "ritual" }
        )
        local activeRitualSiteVariant = activeRitualSiteWeeklies[1]
        local completedRitualSiteVariant = completedRitualSiteWeeklies[1]
        local ritualMetaDone = C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(95843) or false

        if activeRitualSiteVariant then
            db[mod.key]["ritual_site_active_name"] = activeRitualSiteVariant.name
            db[mod.key]["ritual_site_active_map_id"] = activeRitualSiteVariant.mapId
        elseif activeRitualSiteZone then
            db[mod.key]["ritual_site_active_name"] = activeRitualSiteZone
            db[mod.key]["ritual_site_active_map_id"] = activeRitualSiteMapId
        end
        db[mod.key]["ritual_site_active_poi_name"] = activeRitualSitePoiName

        if completedRitualSiteVariant then
            db[mod.key]["ritual_site_completed_name"] = completedRitualSiteVariant.name
            db[mod.key]["ritual_site_completed_map_id"] = completedRitualSiteVariant.mapId
        elseif ritualMetaDone then
            db[mod.key]["ritual_site_completed_name"] = previousRitualCompletedName
                or previousRitualActiveName
                or db[mod.key]["ritual_site_active_name"]
            db[mod.key]["ritual_site_completed_map_id"] = previousRitualCompletedMapId
                or previousRitualActiveMapId
                or db[mod.key]["ritual_site_active_map_id"]
        elseif not activeRitualSiteVariant
            and not activeRitualSiteZone
            and not IsQuestCurrentlyActive(95843)
            and previousRitualActiveMapId
            and IsPlayerInMapHierarchy(previousRitualActiveMapId) then
            db[mod.key]["ritual_sites"] = 1
            db[mod.key]["ritual_site_completed_name"] = previousRitualCompletedName or previousRitualActiveName
            db[mod.key]["ritual_site_completed_map_id"] = previousRitualCompletedMapId or previousRitualActiveMapId
        elseif (tonumber(db[mod.key]["ritual_sites"]) or 0) > 0 then
            db[mod.key]["ritual_site_completed_name"] = previousRitualCompletedName
                or db[mod.key]["ritual_site_active_name"]
                or previousRitualActiveName
            db[mod.key]["ritual_site_completed_map_id"] = previousRitualCompletedMapId
                or db[mod.key]["ritual_site_active_map_id"]
                or previousRitualActiveMapId
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "ritual_sites" then
                if db[mod.key]["ritual_site_completed_name"]
                    or ritualMetaDone
                    or (tonumber(db[mod.key]["ritual_sites"]) or 0) > 0 then
                    row.countText = db[mod.key]["ritual_site_completed_name"] or (L["Done"] or "Done")
                    row.countColor = { 0.4, 0.85, 0.4 }
                elseif db[mod.key]["ritual_site_active_name"] then
                    row.countText = db[mod.key]["ritual_site_active_name"]
                    row.countColor = { 1, 0.9, 0.3 }
                else
                    row.countText = nil
                    row.countColor = nil
                end
                break
            end
        end

        local completedArcantinaWeeklies, activeArcantinaWeeklies = CollectQuestVariants(ARCANTINA_WEEKLIES)
        if #activeArcantinaWeeklies > 0 then
            local names = {}
            for _, variant in ipairs(activeArcantinaWeeklies) do
                names[#names + 1] = variant.name
            end
            db[mod.key]["arcantina_active_name"] = names[1]
            db[mod.key]["arcantina_active_names"] = table.concat(names, " || ")
        end

        if #completedArcantinaWeeklies > 0 then
            local names = {}
            for _, variant in ipairs(completedArcantinaWeeklies) do
                names[#names + 1] = variant.name
            end
            db[mod.key]["arcantina_weekly"] = 1
            db[mod.key]["arcantina_completed_name"] = names[1]
            db[mod.key]["arcantina_completed_names"] = table.concat(names, " || ")
        else
            db[mod.key]["arcantina_weekly"] = db[mod.key]["arcantina_weekly"] or 0
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "arcantina_weekly" then
                if #activeArcantinaWeeklies > 1 then
                    row.countText = string.format(L["Weekly_SA_Count_Active"] or "%d active", #activeArcantinaWeeklies)
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = L["Weekly_Arcantina_Note"]
                elseif #activeArcantinaWeeklies == 1 then
                    row.countText = activeArcantinaWeeklies[1].name
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = L["Weekly_Arcantina_Note"]
                elseif #completedArcantinaWeeklies > 1 then
                    row.countText = string.format(L["Weekly_SA_Count_Completed"] or "%d done", #completedArcantinaWeeklies)
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = L["Weekly_Arcantina_Note"]
                elseif #completedArcantinaWeeklies == 1 then
                    row.countText = completedArcantinaWeeklies[1].name
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = L["Weekly_Arcantina_Note"]
                else
                    row.countText = nil
                    row.countColor = nil
                    row.note = L["Weekly_Arcantina_Note"]
                end
                break
            end
        end

        local completedHalduronWeeklies, activeHalduronWeeklies = CollectQuestVariants(HALDURON_WEEKLIES)
        if #activeHalduronWeeklies > 0 then
            local names = {}
            for _, variant in ipairs(activeHalduronWeeklies) do
                names[#names + 1] = variant.name
            end
            db[mod.key]["halduron_active_name"] = names[1]
            db[mod.key]["halduron_active_names"] = table.concat(names, " || ")
        end

        if #completedHalduronWeeklies > 0 then
            local names = {}
            for _, variant in ipairs(completedHalduronWeeklies) do
                names[#names + 1] = variant.name
            end
            db[mod.key]["halduron_weekly"] = 1
            db[mod.key]["halduron_completed_name"] = names[1]
            db[mod.key]["halduron_completed_names"] = table.concat(names, " || ")
        else
            db[mod.key]["halduron_weekly"] = db[mod.key]["halduron_weekly"] or 0
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "halduron_weekly" then
                if #activeHalduronWeeklies > 1 then
                    row.countText = string.format(L["Weekly_SA_Count_Active"] or "%d active", #activeHalduronWeeklies)
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = L["Weekly_Halduron_Note"]
                elseif #activeHalduronWeeklies == 1 then
                    row.countText = activeHalduronWeeklies[1].name
                    row.countColor = { 1, 0.9, 0.3 }
                    row.note = L["Weekly_Halduron_Note"]
                elseif #completedHalduronWeeklies > 1 then
                    row.countText = string.format(L["Weekly_SA_Count_Completed"] or "%d done", #completedHalduronWeeklies)
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = L["Weekly_Halduron_Note"]
                elseif #completedHalduronWeeklies == 1 then
                    row.countText = completedHalduronWeeklies[1].name
                    row.countColor = { 0.4, 0.85, 0.4 }
                    row.note = L["Weekly_Halduron_Note"]
                else
                    row.countText = nil
                    row.countColor = nil
                    row.note = L["Weekly_Halduron_Note"]
                end
                break
            end
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "call_to_delves" then
                UpdateRotatingWeeklyQuestState(db[mod.key], row, 93595)
                break
            end
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "abyss_anglers" then
                local isDone = C_QuestLog.IsQuestFlaggedCompleted
                    and C_QuestLog.IsQuestFlaggedCompleted(ABYSS_ANGLERS_WEEKLY_QUEST_ID)
                local isActive = IsQuestCurrentlyActive(ABYSS_ANGLERS_WEEKLY_QUEST_ID)
                    or IsQuestCurrentlyActive(ABYSS_ANGLERS_INTRO_QUEST_ID)

                db[mod.key]["abyss_anglers"] = isDone and 1 or 0
                if isDone then
                    row.countText = L["Done"] or "Done"
                    row.countColor = { 0.4, 0.85, 0.4 }
                elseif isActive then
                    row.countText = L["Weekly_SA_Count_ActiveSingle"] or "Active"
                    row.countColor = { 1, 0.9, 0.3 }
                else
                    row.countText = nil
                    row.countColor = nil
                end
                break
            end
        end

        local completedShowdowns, activeShowdowns = CollectQuestVariants(VOID_INVASION_SHOWDOWNS)
        if #activeShowdowns > 0 then
            db[mod.key]["showdown_active_name"] = activeShowdowns[1].name
        end
        if #completedShowdowns > 0 then
            db[mod.key]["void_invasion_showdown"] = 1
            db[mod.key]["showdown_completed_name"] = completedShowdowns[1].name
        else
            db[mod.key]["void_invasion_showdown"] = db[mod.key]["void_invasion_showdown"] or 0
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "void_invasion_showdown" then
                if db[mod.key]["showdown_completed_name"] or (tonumber(db[mod.key]["void_invasion_showdown"]) or 0) > 0 then
                    row.countText = db[mod.key]["showdown_completed_name"] or (L["Done"] or "Done")
                    row.countColor = { 0.4, 0.85, 0.4 }
                elseif db[mod.key]["showdown_active_name"] then
                    row.countText = db[mod.key]["showdown_active_name"]
                    row.countColor = { 1, 0.9, 0.3 }
                else
                    row.countText = nil
                    row.countColor = nil
                end
                break
            end
        end

        local uatvMetaActive = IsAnyQuestActive(UATV_META_QUEST_IDS)
        local uatvMetaCompleted = IsAnyQuestCompleted(UATV_META_QUEST_IDS)
        local activeUATVBranch = FindActiveUATVBranch(uatvMetaActive)
        local previousUATVNameUsable = not IsSharedUATVBranchName(previousUATVActiveName)
            or uatvMetaActive
            or uatvMetaCompleted
        db[mod.key]["uatv_meta_active"] = uatvMetaActive and true or nil
        db[mod.key]["uatv_branch_name"] = activeUATVBranch and activeUATVBranch.name or nil
        db[mod.key]["uatv_branch_quest"] = activeUATVBranch and activeUATVBranch.quest or nil
        db[mod.key]["uatv_completed_branch_name"] = nil
        db[mod.key]["unity_against_void"] = 0

        if uatvMetaCompleted then
            db[mod.key]["unity_against_void"] = 1
            db[mod.key]["uatv_completed_branch_name"] = previousUATVCompletedName
                or (previousUATVNameUsable and previousUATVActiveName or nil)
                or db[mod.key]["uatv_branch_name"]
        end

        if db[mod.key]["unity_against_void"] < 1 then
            for _, branch in ipairs(UATV_BRANCHES) do
                if C_QuestLog.IsQuestFlaggedCompleted(branch.quest)
                    and (not UATV_SHARED_BRANCH_QUEST_IDS[branch.quest] or uatvMetaActive or uatvMetaCompleted) then
                    db[mod.key]["unity_against_void"] = 1
                    db[mod.key]["uatv_completed_branch_name"] = branch.name
                    break
                end
            end
        end

        if db[mod.key]["unity_against_void"] < 1
            and activeUATVBranch
            and activeUATVBranch.quest == 93913
            and MR.IsCurrentWorldBossCompleted
            and MR:IsCurrentWorldBossCompleted() then
            db[mod.key]["unity_against_void"] = 1
            db[mod.key]["uatv_completed_branch_name"] = activeUATVBranch.name
        end

        if (tonumber(db[mod.key]["unity_against_void"]) or 0) >= 1
            and not db[mod.key]["uatv_completed_branch_name"] then
            db[mod.key]["uatv_completed_branch_name"] = previousUATVCompletedName
                or (previousUATVNameUsable and previousUATVActiveName or nil)
                or db[mod.key]["uatv_branch_name"]
        end

        for _, row in ipairs(mod.rows) do
            if row.key == "unity_against_void" then
                local completedBranch = db[mod.key]["uatv_completed_branch_name"]
                local activeBranch = db[mod.key]["uatv_branch_name"]
                local unityProgress = db[mod.key]["unity_against_void"] or 0

                if completedBranch or unityProgress >= 1 then
                    row.countText = completedBranch or (L["Done"] or "Done")
                    row.countColor = { 0.4, 0.85, 0.4 }
                elseif activeBranch then
                    row.countText = activeBranch
                    row.countColor = { 1, 0.9, 0.3 }
                else
                    row.countText = nil
                    row.countColor = nil
                end
                break
            end
        end

        local soireeVariants = {
            { quest = 91966, name = "Saltheril's Soiree" },
            { quest = 89289, name = L["Weekly_Soiree_Label"] },
        }
        local activeSoireeVariant = FindActiveQuestVariant(soireeVariants)
        db[mod.key]["soiree_active_quest"] = activeSoireeVariant and activeSoireeVariant.quest or nil
        db[mod.key]["soiree_active_name"] = activeSoireeVariant and activeSoireeVariant.name or nil
        db[mod.key]["soiree_completed_name"] = nil

        for _, variant in ipairs(soireeVariants) do
            if C_QuestLog.IsQuestFlaggedCompleted(variant.quest) then
                db[mod.key]["saltherils_soiree"] = 1
                db[mod.key]["soiree_completed_name"] = variant.name
                break
            end
        end
        if C_QuestLog and C_QuestLog.GetQuestObjectives then
            local fulfilled
            if C_QuestLog.IsQuestFlaggedCompleted(96995) then
                fulfilled = 3
            else
                local objectives = C_QuestLog.GetQuestObjectives(96995)
                local objective = objectives and objectives[1]
                fulfilled = objective and tonumber(objective.numFulfilled)
            end
            if fulfilled then
                db[mod.key]["turn_back_surge"] = math.min(fulfilled, 3)
            end
        end

        for key, value in pairs(db[mod.key]) do
            if beforeProgress[key] ~= value then
                return true
            end
        end
        for key in pairs(beforeProgress) do
            if db[mod.key][key] ~= beforeProgress[key] then
                return true
            end
        end
        for _, row in ipairs(mod.rows) do
            local beforeRow = beforeRows[row.key]
            if beforeRow then
                if beforeRow.label ~= row.label
                    or beforeRow.countText ~= row.countText
                    or beforeRow.max ~= row.max
                    or beforeRow.note ~= row.note
                    or not ColorsEqual(beforeRow.countColor, row.countColor) then
                    return true
                end
            end
        end
        return false
    end,

    rows = {
        {
            key      = "void_assaults",
            label    = L["Weekly_VoidAssaults_Label"] or "|cff2ae7c6Void Assaults:|r",
            max      = 1,
            note     = L["Weekly_VoidAssaults_Note"] or "Complete the active Void Assault weekly in Eversong Woods or Zul'Aman for a Spark of Radiance.",
            questIds = { 94385, 94386 },
            patchKey = "12.0.5",
            completedNameKey = "void_assault_completed_name",
            activeNameKey = "void_assault_active_name",
            tooltipFunc = function(tip)
                local completedVariants, activeVariants = CollectQuestVariants(VOID_ASSAULT_WEEKLIES)
                local s1db = GetMainWeeklyProgress()
                local completedName = s1db["void_assault_completed_name"]
                local activeName = s1db["void_assault_active_name"]
                local activePoiName = s1db["void_assault_active_poi_name"]
                local fallbackName = L["Done"] or "Done"

                tip:AddLine(" ")
                if completedName or #completedVariants > 0 then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (completedName or GetVariantName(completedVariants, 1, fallbackName)), 0.4, 0.85, 0.4)
                elseif activeName or #activeVariants > 0 then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (activeName or GetVariantName(activeVariants, 1, L["Weekly_VoidAssaults_Label"] or "Void Assaults")), 1, 0.9, 0.3)
                    if activePoiName then
                        tip:AddLine("    " .. activePoiName, 0.65, 0.82, 1)
                    end
                else
                    tip:AddLine(L["Tooltip_No_VoidAssaults"] or "|cffaaaaaa? No Void Assault weekly detected.|r", 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_VoidAssaults"] or "  Visit the active assault zone in Eversong Woods or Zul'Aman.", 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "ritual_sites",
            label    = L["Weekly_RitualSites_Label"] or "|cff2ae7c6Ritual Sites:|r",
            max      = 1,
            note     = L["Weekly_RitualSites_Note"] or "Complete a Ritual Site in Midnight for a Spark of Radiance.",
            questIds = { 95843, 94880, 94878 },
            patchKey = "12.0.5",
            turnInTracked = true,
            allowQuestFlagBackfill = true,
            completedNameKey = "ritual_site_completed_name",
            activeNameKey = "ritual_site_active_name",
            tooltipFunc = function(tip)
                local completedVariants, activeVariants = CollectQuestVariants(RITUAL_SITE_WEEKLIES)
                local s1db = GetMainWeeklyProgress()
                local completedName = s1db["ritual_site_completed_name"]
                local activeName = s1db["ritual_site_active_name"]
                local activePoiName = s1db["ritual_site_active_poi_name"]
                local rowDone = (tonumber(s1db["ritual_sites"]) or 0) > 0
                local fallbackName = L["Done"] or "Done"

                tip:AddLine(" ")
                if completedName or #completedVariants > 0 or rowDone or (C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(95843)) then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (completedName or GetVariantName(completedVariants, 1, fallbackName)), 0.4, 0.85, 0.4)
                elseif activeName or #activeVariants > 0 or IsQuestCurrentlyActive(95843) then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (activeName or GetVariantName(activeVariants, 1, L["Weekly_RitualSites_Label"] or "Ritual Sites")), 1, 0.9, 0.3)
                    if activePoiName then
                        tip:AddLine("    " .. activePoiName, 0.65, 0.82, 1)
                    end
                else
                    tip:AddLine(L["Tooltip_No_RitualSites"] or "|cffaaaaaa? Ritual Sites weekly not yet detected.|r", 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_RitualSites"] or "  Complete a Ritual Site in the active location to reveal this week's progress.", 0.7, 0.7, 0.7)
                end
            end,
        },




















        {
            key      = "abyss_anglers",
            label    = L["Weekly_AbyssAnglers_Label"] or "|cff2ae7c6Abyss Anglers:|r",
            max      = 1,
            note     = L["Weekly_AbyssAnglers_Note"] or "Complete an Abyss Anglers dive in Zul'Aman. This helps cover the new weekly-capped activity tied to up to 3 Fused Vitality purchases.",
            questIds = { ABYSS_ANGLERS_WEEKLY_QUEST_ID },
            patchKey = "12.0.5",
            tooltipFunc = function(tip)
                tip:AddLine(" ")
                if C_QuestLog.IsQuestFlaggedCompleted
                    and C_QuestLog.IsQuestFlaggedCompleted(ABYSS_ANGLERS_WEEKLY_QUEST_ID) then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (L["Weekly_AbyssAnglers_Label"] or "Abyss Anglers"), 0.4, 0.85, 0.4)
                elseif IsQuestCurrentlyActive(ABYSS_ANGLERS_WEEKLY_QUEST_ID) or IsQuestCurrentlyActive(ABYSS_ANGLERS_INTRO_QUEST_ID) then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (L["Weekly_AbyssAnglers_Label"] or "Abyss Anglers"), 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_AbyssAnglers"] or "|cffaaaaaa? Abyss Anglers not yet detected this week.|r", 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_AbyssAnglers"] or "  Visit Depthdiver Jeju off the coast of Zul'Aman to start a dive.", 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "void_invasion_showdown",
            label    = L["Weekly_Showdown_Label"] or "|cff2ae7c6Void Invasion Showdown:|r",
            max      = 1,
            note     = L["Weekly_Showdown_Note"] or "Complete the active Naigtal or Val Showdown. Normal or Heroic counts.",
            questIds = { 96716, 96720, 96717, 96718, 96713, 96714 },
            patchKey = "12.0.7",
            turnInTracked = true,
            allowQuestFlagBackfill = true,
            completedNameKey = "showdown_completed_name",
            activeNameKey = "showdown_active_name",
            tooltipFunc = function(tip)
                local completedVariants, activeVariants = CollectQuestVariants(VOID_INVASION_SHOWDOWNS)
                local s1db = GetMainWeeklyProgress()
                local completedName = s1db["showdown_completed_name"]
                local activeName = s1db["showdown_active_name"]
                local rowDone = (tonumber(s1db["void_invasion_showdown"]) or 0) > 0
                local fallbackName = L["Done"] or "Done"

                tip:AddLine(" ")
                if completedName or #completedVariants > 0 or rowDone then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (completedName or GetVariantName(completedVariants, 1, fallbackName)), 0.4, 0.85, 0.4)
                elseif activeName or #activeVariants > 0 then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (activeName or GetVariantName(activeVariants, 1, L["Weekly_Showdown_Label"] or "Void Invasion Showdown")), 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Showdown"] or "|cffaaaaaa? Void Invasion Showdown not yet detected this week.|r", 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Showdown"] or "  Visit the active Void Invasion zone in Naigtal or Val.", 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "void_invasion_dangerous_heroic",
            label    = L["Weekly_DangerousEnemies_Label"] or "|cff2ae7c6Dangerous Enemies:|r",
            max      = 1,
            note     = L["Weekly_DangerousEnemies_Note"] or "Complete the active heroic Dangerous Enemies weekly on Naigtal or Val.",
            questIds = { 97083, 97086 },
            patchKey = "12.0.7",
            turnInTracked = true,
            allowQuestFlagBackfill = true,
            completedNameKey = "dangerous_heroic_completed_name",
            activeNameKey = "dangerous_heroic_active_name",
            tooltipFunc = function(tip)
                local completedVariants, activeVariants = CollectQuestVariants(VOID_INVASION_DANGEROUS_HEROIC)
                local s1db = GetMainWeeklyProgress()
                local completedName = s1db["dangerous_heroic_completed_name"]
                local activeName = s1db["dangerous_heroic_active_name"]
                local rowDone = (tonumber(s1db["void_invasion_dangerous_heroic"]) or 0) > 0
                local fallbackName = L["Done"] or "Done"

                tip:AddLine(" ")
                if completedName or #completedVariants > 0 or rowDone then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (completedName or GetVariantName(completedVariants, 1, fallbackName)), 0.4, 0.85, 0.4)
                elseif activeName or #activeVariants > 0 then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (activeName or GetVariantName(activeVariants, 1, L["Weekly_DangerousEnemies_Label"] or "Dangerous Enemies")), 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_DangerousEnemies"] or "|cffaaaaaa? Dangerous Enemies not yet detected this week.|r", 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Showdown"] or "  Visit the active Void Invasion zone in Naigtal or Val.", 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "void_invasion_disruption_heroic",
            label    = L["Weekly_MoreDisruptions_Label"] or "|cff2ae7c6More Disruptions:|r",
            max      = 1,
            note     = L["Weekly_MoreDisruptions_Note"] or "Complete the active heroic More Disruptions weekly on Naigtal or Val.",
            questIds = { 97081, 97087 },
            patchKey = "12.0.7",
            turnInTracked = true,
            allowQuestFlagBackfill = true,
            completedNameKey = "disruption_heroic_completed_name",
            activeNameKey = "disruption_heroic_active_name",
            tooltipFunc = function(tip)
                local completedVariants, activeVariants = CollectQuestVariants(VOID_INVASION_DISRUPTION_HEROIC)
                local s1db = GetMainWeeklyProgress()
                local completedName = s1db["disruption_heroic_completed_name"]
                local activeName = s1db["disruption_heroic_active_name"]
                local rowDone = (tonumber(s1db["void_invasion_disruption_heroic"]) or 0) > 0
                local fallbackName = L["Done"] or "Done"

                tip:AddLine(" ")
                if completedName or #completedVariants > 0 or rowDone then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (completedName or GetVariantName(completedVariants, 1, fallbackName)), 0.4, 0.85, 0.4)
                elseif activeName or #activeVariants > 0 then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (activeName or GetVariantName(activeVariants, 1, L["Weekly_MoreDisruptions_Label"] or "More Disruptions")), 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_MoreDisruptions"] or "|cffaaaaaa? More Disruptions not yet detected this week.|r", 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Showdown"] or "  Visit the active Void Invasion zone in Naigtal or Val.", 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "arcantina_weekly",
            label    = L["Weekly_Arcantina_Label"],
            max      = 1,
            note     = L["Weekly_Arcantina_Note"],
            patchKey = "12.0.0",
            turnInTracked = true,
            questIds = { 92319, 92321, 92320, 92322, 92323, 92324, 92325, 92326, 92327 },
            completedNameKey = "arcantina_completed_name",
            activeNameKey = "arcantina_active_name",
            tooltipFunc = function(tip)
                local completedVariants, activeVariants = CollectQuestVariants(ARCANTINA_WEEKLIES)

                tip:AddLine(" ")
                if #activeVariants > 0 then
                    tip:AddLine(L["Tooltip_Active_Week"], 1, 1, 1)
                    for _, variant in ipairs(activeVariants) do
                        tip:AddLine("  " .. GetVariantDisplayName(variant), 1, 0.9, 0.3)
                    end
                elseif #completedVariants > 0 then
                    tip:AddLine(L["Tooltip_Done_Completed"], 1, 1, 1)
                    for _, variant in ipairs(completedVariants) do
                        tip:AddLine("  " .. GetVariantDisplayName(variant), 0.4, 0.85, 0.4)
                    end
                else
                    tip:AddLine(L["Tooltip_No_Arcantina"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Arcantina"], 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "halduron_weekly",
            label    = L["Weekly_Halduron_Label"],
            max      = 1,
            note     = L["Weekly_Halduron_Note"],
            patchKey = "12.0.0",
            questIds = { 93751, 93752, 93753, 93754, 93755, 93756, 93757, 93758, 95468 },
            completedNameKey = "halduron_completed_name",
            activeNameKey = "halduron_active_name",
            tooltipFunc = function(tip)
                local completedVariants, activeVariants = CollectQuestVariants(HALDURON_WEEKLIES)

                tip:AddLine(" ")
                if #activeVariants > 0 then
                    tip:AddLine(L["Tooltip_Active_Week"], 1, 1, 1)
                    for _, variant in ipairs(activeVariants) do
                        tip:AddLine("  " .. GetVariantDisplayName(variant), 1, 0.9, 0.3)
                    end
                elseif #completedVariants > 0 then
                    tip:AddLine(L["Tooltip_Done_Completed"], 1, 1, 1)
                    for _, variant in ipairs(completedVariants) do
                        tip:AddLine("  " .. GetVariantDisplayName(variant), 0.4, 0.85, 0.4)
                    end
                else
                    tip:AddLine(L["Tooltip_No_Halduron"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Halduron"], 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "call_to_delves",
            label    = L["Weekly_CallToDelves_Label"],
            max      = 1,
            note     = L["Delves_Call_Note"],
            patchKey = "12.0.0",
            isVisible = function()
                local mdb = GetMainWeeklyProgress()
                return IsQuestCurrentlyActive(93595) or ((mdb and tonumber(mdb["call_to_delves"])) or 0) > 0
            end,
        },
        {
            key      = "abundance",
            label    = L["Weekly_Abundance_Label"],
            max      = 1,
            patchKey = "12.0.0",
            questIds = { 89507 },
        },
        {
            key      = "neighborhood",
            label    = L["Weekly_Neighborhood_Label"] or "|cff2ae7c6Neighborhood:|r",
            max      = 1,
            note     = L["Weekly_Neighborhood_Note"] or "Complete one of the weekly neighborhood tasks.",
            patchKey = "12.0.0",
            turnInTracked = true,
            questIds = { 95413, 95416, 95438, 95440 },
            completedNameKey = "neighborhood_completed_name",
            activeNameKey = "neighborhood_active_name",
        },
        {
            key      = "lost_legends",
            label    = L["Weekly_Legends_Label"],
            max      = 1,
            patchKey = "12.0.0",
            turnInTracked = true,
            questIds = LOST_LEGENDS_QUEST_IDS,
            completedNameKey = "legends_completed_name",
            activeNameKey = "legends_active_name",
            zone = 2413,
            x = 54.2,
            y = 53.0,
            waypointTitle = "Zur'ashar Kassameh",
            tooltipFunc = function(tip)
                local s1db = GetMainWeeklyProgress()
                local isDone = MR:GetProgress("s1_weekly", "lost_legends") >= 1
                local completedName = (isDone and s1db["legends_completed_name"]) or nil
                local activeName = s1db["legends_active_name"]

                tip:AddLine(" ")
                if completedName then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. completedName, 0.4, 0.85, 0.4)
                elseif isDone then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. (L["Done"] or "Done"), 0.4, 0.85, 0.4)
                elseif activeName then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. activeName, 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Legends"], 1, 1, 1)
                end
            end,
        },
        {
            key      = "saltherils_soiree",
            label    = L["Weekly_Soiree_Label"],
            max      = 1,
            note     = L["Weekly_Soiree_Note"],
            patchKey = "12.0.0",
            turnInTracked = true,
            questIds = { 89289, 91966 },
            completedNameKey = "soiree_completed_name",
            activeNameKey = "soiree_active_name",
            tooltipFunc = function(tip)
                local variants = {
                    { quest = 91966, name = "Saltheril's Soiree" },
                    { quest = 89289, name = L["Weekly_Soiree_Label"] },
                }

                local s1db = GetMainWeeklyProgress()
                local completedName = (MR:GetProgress("s1_weekly", "saltherils_soiree") >= 1 and s1db["soiree_completed_name"]) or nil
                local activeName = s1db["soiree_active_name"]

                tip:AddLine(" ")
                if completedName then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. completedName, 0.4, 0.85, 0.4)
                elseif activeName then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. activeName, 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Soiree"], 1, 1, 1)
                end
            end,
        },
        {
            key      = "fortify_runestones",
            label    = L["Weekly_Fortify_Label"],
            max      = 1,
            note     = L["Weekly_Fortify_Note"],
            patchKey = "12.0.0",
            questIds = { 90573, 90574, 90575, 90576 },

            tooltipFunc = function(tip)
                local variants = {
                    { quest = 90573, name = L["Magisters"]                },
                    { quest = 90574, name = L["Subfaction_BloodKnights"]  },
                    { quest = 90575, name = L["Farstriders"]              },
                    { quest = 90576, name = L["Subfaction_ShadesOfTheRow"] },
                }
                local completedName, activeName = nil, nil
                for _, v in ipairs(variants) do
                    if C_QuestLog.IsQuestFlaggedCompleted(v.quest) then
                        completedName = v.name; break
                    end
                end
                if not completedName then
                    for _, v in ipairs(variants) do
                        if IsQuestCurrentlyActive(v.quest) then
                            activeName = v.name; break
                        end
                    end
                end
                tip:AddLine(" ")
                if completedName then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. completedName, 0.4, 0.85, 0.4)
                elseif activeName then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. activeName, 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Subfaction"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Haven"], 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "unity_against_void",
            label    = L["Weekly_Unity_Label"],
            max      = 1,
            note     = L["Weekly_Unity_Note"],
            patchKey = "12.0.0",
            turnInTracked = true,
            questIds = UATV_META_QUEST_IDS,
            branchQuestIds = UATV_BRANCH_QUEST_IDS,
            completedNameKey = "uatv_completed_branch_name",
            activeNameKey = "uatv_branch_name",
            activeNameRequiredKey = "uatv_meta_active",

            tooltipFunc = function(tip)
                local s1db = GetMainWeeklyProgress()
                local activeBranchInfo = FindActiveUATVBranch(IsAnyQuestActive(UATV_META_QUEST_IDS))
                local completedBranch = (MR:GetProgress("s1_weekly", "unity_against_void") >= 1 and s1db["uatv_completed_branch_name"]) or nil
                local activeBranch = (activeBranchInfo and activeBranchInfo.name) or (s1db["uatv_meta_active"] and s1db["uatv_branch_name"] or nil)

                tip:AddLine(" ")
                if completedBranch or MR:GetProgress("s1_weekly", "unity_against_void") >= 1 then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    if completedBranch then
                        tip:AddLine("  " .. completedBranch, 0.4, 0.85, 0.4)
                    end
                elseif activeBranch then
                    tip:AddLine(L["Tooltip_Active_Progress"], 1, 1, 1)
                    tip:AddLine("  " .. activeBranch, 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Activity"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Pick_Activity"], 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "special_assignment",
            label    = L["Weekly_SA_Label"],
            max      = 1,
            note     = L["Weekly_SA_Note"],
            patchKey = "12.0.0",

            questIds = { 91390, 91796, 92063, 92139, 92145, 93013, 93244, 93438 },
            tooltipFunc = function(tip)
                local completedAssignments, activeAssignments = CollectSpecialAssignments()
                local zoneLabel = L["Tooltip_SA_Zone"] or "Zone:"

                tip:AddLine(" ")
                if #activeAssignments > 0 then
                    tip:AddLine(L["Tooltip_Active_Week"], 1, 1, 1)
                    for _, assignment in ipairs(activeAssignments) do
                        tip:AddLine("  " .. assignment.name, 1, 0.9, 0.3)
                        if assignment.zoneName then
                            tip:AddLine("    " .. zoneLabel .. " " .. assignment.zoneName, 0.65, 0.82, 1)
                        end
                    end
                elseif #completedAssignments > 0 then
                    tip:AddLine(L["Tooltip_Done_Completed"], 1, 1, 1)
                    for _, assignment in ipairs(completedAssignments) do
                        tip:AddLine("  " .. assignment.name, 0.4, 0.85, 0.4)
                        if assignment.zoneName then
                            tip:AddLine("    " .. zoneLabel .. " " .. assignment.zoneName, 0.55, 0.7, 0.55)
                        end
                    end
                else
                    tip:AddLine(L["Tooltip_No_Assignment"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Silvermoon"], 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "turn_back_surge",
            label    = L["Weekly_TurnBackSurge_Label"] or "Turn Back the Surge:",
            max      = 3,
            note     = L["Weekly_TurnBackSurge_Note"] or "Defeat 3 Curse Surges on the Coiled Isle.",
            patchKey = "12.1.0",
            questIds = { 96995 },
        },
        {
            key      = "trailing_xalatath",
            label    = L["Weekly_TrailingXalatath_Label"] or "Trailing Xal'atath:",
            max      = 1,
            note     = L["Weekly_TrailingXalatath_Note"] or "Complete the weekly Trailing Xal'atath task on the Coiled Isle.",
            patchKey = "12.1.0",
            questIds = { 98172 },
        },
        {
            key      = "purging_vaults",
            label    = L["Weekly_PurgingVaults_Label"] or "Purging the Vaults:",
            max      = 1,
            note     = L["Weekly_PurgingVaults_Note"] or "Complete Purging the Vaults after unlocking it on the Coiled Isle.",
            patchKey = "12.1.0",
            questIds = { 95520 },
        },
        {
            key      = "nymrissa_lair",
            label    = L["Weekly_Nymrissa_Label"] or "Lair: Nymrissa Wavecaller:",
            max      = 1,
            note     = L["Weekly_Nymrissa_Note"] or "Complete the Tidebound Grotto Lair weekly reward.",
            patchKey = "12.1.0",
            questIds = { 97128 },
            zone = 2512,
            x = 59.9,
            y = 66.3,
            waypointTitle = L["Weekly_Nymrissa_Waypoint"] or "The Tidebound Grotto Lair Entrance",
        },
        {
            key      = "vaults_weekly_reward",
            label    = L["Weekly_VaultsReward_Label"] or "Vaults Weekly Reward:",
            max      = 1,
            note     = L["Weekly_VaultsReward_Note"] or "Use the weekly Vaults opportunity for a chance at improved gear.",
            patchKey = "12.1.0",
            zone = 2512,
            x = 45.72,
            y = 64.94,
            waypointTitle = L["Weekly_VaultsReward_Waypoint"] or "Vaults of Atal'Utek Entrance",
        },
    },
})
