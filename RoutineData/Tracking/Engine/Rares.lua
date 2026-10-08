local _, addonNS = ...
local tracking = addonNS.Tracking

function tracking.API:CreateRareTracker(MR, zones, context)
    local ZONES = zones
    local MAP_TO_ZONE_KEY = {
        [2395] = "eversong",
        [2393] = "eversong",
        [2437] = "zulaman",
        [2413] = "harandar",
        [2576] = "harandar",
        [2405] = "voidstorm",
        [2444] = "voidstorm",
        [2599] = "val",
        [2600] = "naigtal",
        [2621] = "val",
        [2512] = "coiled_isle",
    }
    local nearbyZones = {}

    local function GetNearbyZoneKey(mapID, continentID)
        if not mapID or not continentID or mapID == continentID or not C_Map.GetMapRectOnMap then return nil end
        if IsInInstance and IsInInstance() then return nil end
        if nearbyZones[mapID] ~= nil then return nearbyZones[mapID] or nil end
        local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(mapID, continentID)
        if not (minX and maxX and minY and maxY) then return nil end
        local x, y = (minX + maxX) / 2, (minY + maxY) / 2
        local nearest, nearestDistance
        for candidateID, key in pairs(MAP_TO_ZONE_KEY) do
            local info = C_Map.GetMapInfo(candidateID)
            if info and info.mapType == 3 and info.parentMapID == continentID then
                local left, right, top, bottom = C_Map.GetMapRectOnMap(candidateID, continentID)
                if left and right and top and bottom then
                    local dx = math.max(left - x, 0, x - right)
                    local dy = math.max(top - y, 0, y - bottom)
                    local distance = dx * dx + dy * dy
                    if distance <= 0.0004 and (not nearestDistance or distance < nearestDistance or (distance == nearestDistance and key < nearest)) then
                        nearest, nearestDistance = key, distance
                    end
                end
            end
        end
        nearbyZones[mapID] = nearest or false
        return nearest
    end

    local function GetCurrentZoneKey()
        if MR.isForever then
            return context.getCurrentForeverZone()
        end
        if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetMapInfo) then
            return nil
        end

        local mapID = C_Map.GetBestMapForUnit("player")
        local currentMapID, continentID = mapID
        local checked = 0
        while mapID and checked < 10 do
            if MAP_TO_ZONE_KEY[mapID] then
                return MAP_TO_ZONE_KEY[mapID]
            end

            local info = C_Map.GetMapInfo(mapID)
            if info and info.mapType == 2 then continentID = mapID end
            if not info or not info.parentMapID or info.parentMapID == 0 then
                break
            end

            mapID = info.parentMapID
            checked = checked + 1
        end

        return GetNearbyZoneKey(currentMapID, continentID)
    end

    local function GetCurrentDayKey()
        if MR.GetLastDailyTimestamp then
            local resetAt = MR:GetLastDailyTimestamp()
            if resetAt and resetAt > 0 then
                return resetAt
            end
        end

        return math.floor(GetServerTime() / 86400)
    end

    local RARE_BY_NPC_ID = {}
    local RARE_BY_QUEST_ID = {}
    local RARES_BY_ZONE_AND_NPC = {}
    local RARE_CRITERIA_COMPLETION = {}
    local RARE_CRITERIA_BY_NPC = {}
    local RARE_QUEST_RESOLVE_AT = {}

    local function GetRareQuestCacheKey(zone, index, rare)
        if rare and rare[6] then
            return "npc:" .. tostring(rare[6])
        end
        return "zone:" .. tostring(zone.key) .. ":" .. tostring(index)
    end

    for _, zone in ipairs(ZONES) do
        for _, mapID in ipairs(zone.mapIDs or {}) do
            MAP_TO_ZONE_KEY[mapID] = MAP_TO_ZONE_KEY[mapID] or zone.key
        end
        local raresByNPC = {}
        RARES_BY_ZONE_AND_NPC[zone] = raresByNPC
        for _, rare in ipairs(zone.rares) do
            if rare[3] then MAP_TO_ZONE_KEY[rare[3]] = MAP_TO_ZONE_KEY[rare[3]] or zone.key end
            if rare[2] then
                RARE_BY_QUEST_ID[rare[2]] = rare
            end
            for _, questID in ipairs(rare.questIDs or {}) do RARE_BY_QUEST_ID[questID] = rare end
            if rare[6] then
                raresByNPC[rare[6]] = rare
                RARE_BY_NPC_ID[rare[6]] = rare
            end
        end
    end

    local function ResolveRareQuestIDs(zone)
        if MR.isForever then return false end
        if not zone or zone.resolveQuestIDs == false then
            return
        end

        local changed = false
        local profile = MR.db and MR.db.profile
        if profile then
            profile.rareQuestIDs = profile.rareQuestIDs or {}
            for index, rare in ipairs(zone.rares) do
                if not rare[2] and rare.resolveQuestID ~= false then
                    local cacheKey = GetRareQuestCacheKey(zone, index, rare)
                    rare[2] = profile.rareQuestIDs[cacheKey]
                    if rare[2] then
                        RARE_BY_QUEST_ID[rare[2]] = rare
                        changed = true
                    end
                end
            end
        end

        local unresolvedMaps = {}
        for _, rare in ipairs(zone.rares) do
            if not rare[2] and rare[3] and rare.resolveQuestID ~= false then unresolvedMaps[rare[3]] = true end
        end
        if not next(unresolvedMaps) or not (C_TaskQuest and C_TaskQuest.GetQuestsForPlayerByMapID) then
            return changed
        end
        local now = GetTime()
        if RARE_QUEST_RESOLVE_AT[zone] and now - RARE_QUEST_RESOLVE_AT[zone] < 30 then
            return changed
        end
        RARE_QUEST_RESOLVE_AT[zone] = now
        for mapID in pairs(unresolvedMaps) do
            for _, info in ipairs(C_TaskQuest.GetQuestsForPlayerByMapID(mapID) or {}) do
                local questID = info.questId or info.questID
                local rare
                if info.x and info.y then
                    local nearestDistance
                    for _, candidate in ipairs(zone.rares) do
                        if not candidate[2] and candidate.resolveQuestID ~= false and candidate[3] == mapID and candidate[4] and candidate[5] then
                            local dx = candidate[4] - info.x * 100
                            local dy = candidate[5] - info.y * 100
                            local distance = dx * dx + dy * dy
                            if distance <= 6.25 and (not nearestDistance or distance < nearestDistance) then
                                rare = candidate
                                nearestDistance = distance
                            end
                        end
                    end
                end
                if rare and questID then
                    local rareIndex
                    for index, candidate in ipairs(zone.rares) do
                        if candidate == rare then
                            rareIndex = index
                            break
                        end
                    end
                    if rareIndex then
                        rare[2] = questID
                        changed = true
                        RARE_BY_QUEST_ID[questID] = rare
                        if profile then
                            profile.rareQuestIDs[GetRareQuestCacheKey(zone, rareIndex, rare)] = questID
                        end
                        if not rare[4] and info.x and info.y then
                            rare[3] = mapID
                            rare[4] = info.x * 100
                            rare[5] = info.y * 100
                        end
                    end
                end
            end
        end
        return changed
    end

    local function SyncRareKillRecord(questId)
        local char = MR.db and MR.db.char
        if not char then return end
        if not char.raresKills then char.raresKills = {} end
        local weekKey = MR:GetCurrentWeekKey()
        if not weekKey or weekKey == 0 then return end
        local dayKey = GetCurrentDayKey()
        local key    = tostring(questId)
        local rec    = char.raresKills[key]
        if not rec or rec.w ~= weekKey then
            char.raresKills[key] = { w = weekKey, d = dayKey }
            return true
        elseif rec.d ~= dayKey then
            char.raresKills[key].d = dayKey
            return true
        end
        return false
    end

    local function IsRareQuestCompleted(rare)
        if not rare then return false end
        if rare.questIDs then
            for _, questID in ipairs(rare.questIDs) do
                local completed = C_QuestLog.IsQuestFlaggedCompleted(questID)
                if rare.questAny and completed then return true end
                if not rare.questAny and not completed then return false end
            end
            return not rare.questAny
        end
        return rare[2] and C_QuestLog.IsQuestFlaggedCompleted(rare[2]) or false
    end

    function MR:SyncRareQuestCompletion(questId)
        questId = tonumber(questId)
        if not questId or not RARE_BY_QUEST_ID[questId] then
            return false
        end
        local rare = RARE_BY_QUEST_ID[questId]
        if rare.questIDs and not IsRareQuestCompleted(rare) then return false end
        return SyncRareKillRecord(rare[2] or questId) == true
    end

    local function GetRareKillStatus(questId)
        local char = MR.db and MR.db.char
        if not char or not char.raresKills then return nil end
        local weekKey = MR:GetCurrentWeekKey()
        if not weekKey or weekKey == 0 then return nil end
        local rec = char.raresKills[tostring(questId)]
        if not rec or rec.w ~= weekKey then return nil end
        return (rec.d == GetCurrentDayKey()) and "today" or "week"
    end

    local function GetRareTrackedKillStatus(rare)
        if not rare then return nil end
        local questStatus = rare[2] and GetRareKillStatus(rare[2]) or nil
        if questStatus then return questStatus end
        return rare[6] and GetRareKillStatus("npc:" .. tostring(rare[6])) or nil
    end

    local function SyncNewAchievementCriteriaKills(zone)
        if not zone or not zone.achievId or type(GetAchievementCriteriaInfo) ~= "function" then
            return
        end
        local rareByNPC = RARES_BY_ZONE_AND_NPC[zone]
        local changed = false
        local byNPC = RARE_CRITERIA_BY_NPC[zone.achievId]
        if not byNPC then
            byNPC = {}
            RARE_CRITERIA_BY_NPC[zone.achievId] = byNPC
        end

        local criteriaCount = type(GetAchievementNumCriteria) == "function" and GetAchievementNumCriteria(zone.achievId) or 0
        for index = 1, (criteriaCount or 0) do
            local ok, _, _, completed, _, _, _, _, assetID = pcall(GetAchievementCriteriaInfo, zone.achievId, index)
            if ok then
                assetID = tonumber(assetID)
                local rare = (assetID and rareByNPC[assetID]) or zone.rares[index]
                if rare then
                    if assetID and assetID > 0 and not rare[6] then
                        rare[6] = assetID
                        rareByNPC[assetID] = rare
                        RARE_BY_NPC_ID[assetID] = rare
                        changed = true
                    end
                    local key = tostring(zone.achievId) .. ":" .. tostring(index)
                    if RARE_CRITERIA_COMPLETION[key] == false and completed == true and assetID then
                        SyncRareKillRecord("npc:" .. tostring(assetID))
                    end
                    if RARE_CRITERIA_COMPLETION[key] ~= (completed == true) then changed = true end
                    RARE_CRITERIA_COMPLETION[key] = completed == true
                    if assetID then byNPC[assetID] = completed == true end
                end
            end
        end
        return changed
    end

    local function GetRareNPCIDFromGUID(guid)
        if not guid or (issecretvalue and issecretvalue(guid)) then return nil end
        if C_CreatureInfo and C_CreatureInfo.GetCreatureID then
            local ok, npcID = pcall(C_CreatureInfo.GetCreatureID, guid)
            if ok and npcID then return tonumber(npcID) end
        end
        if type(guid) ~= "string" then return nil end
        local unitType, npcID = guid:match("(%a+)%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
        if unitType ~= "Creature" and unitType ~= "Vehicle" then return nil end
        return tonumber(npcID)
    end

    function MR:GetRareNPCIDFromGUID(guid)
        return GetRareNPCIDFromGUID(guid)
    end

    function MR:OnRareUnitDied(_, unitGUID)
        local npcID = GetRareNPCIDFromGUID(unitGUID)
        local rare = npcID and RARE_BY_NPC_ID[npcID]
        if not rare and self.isForever then
            for _, zone in ipairs(context.getForeverZones()) do
                for _, candidate in ipairs(zone.rares) do
                    if candidate[6] == npcID then rare = candidate end
                end
            end
        end
        if not rare then return end
        if SyncRareKillRecord("npc:" .. tostring(npcID)) then tracking:Fire("RaresChanged") end
    end

    function MR:OnRareCombatLogEvent()
        if type(CombatLogGetCurrentEventInfo) ~= "function" then return end
        local _, subevent, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo()
        if subevent ~= "UNIT_DIED" then return end
        self:OnRareUnitDied("UNIT_DIED", destGUID)
    end

    local function GetStoredRareKillStatus(charData, key, weekKey, dayKey)
        if type(charData) ~= "table" or type(charData.raresKills) ~= "table" or not key then
            return nil
        end

        local rec = charData.raresKills[key]
        if type(rec) ~= "table" or rec.w ~= weekKey then
            return nil
        end

        return (rec.d == dayKey) and "today" or "week"
    end

    local function BetterKillStatus(a, b)
        if a == "today" or b == "today" then return "today" end
        return a or b
    end

    local function IsAchievementCriteriaCompleted(achievementId, criteriaIndex, rare)
        if MR.isForever then
            local char = MR.db and MR.db.char
            return char and char.raresKills and rare and char.raresKills["npc:" .. tostring(rare[6])] ~= nil or false
        end
        if rare and rare.achievementID and rare.criteriaID then
            local getter = rare.criteriaID < 100 and GetAchievementCriteriaInfo or GetAchievementCriteriaInfoByID
            if type(getter) == "function" then
                local ok, _, _, completed = pcall(getter, rare.achievementID, rare.criteriaID)
                if ok then return completed == true end
            end
            return false
        end
        if (rare and rare.catalogEntry) or not achievementId or not criteriaIndex then
            local char = MR.db and MR.db.char
            return char and char.raresKills and rare and char.raresKills["npc:" .. tostring(rare[6])] ~= nil or false
        end

        local byNPC = RARE_CRITERIA_BY_NPC[achievementId]
        if not byNPC then
            for _, zone in ipairs(ZONES) do
                if zone.achievId == achievementId then
                    SyncNewAchievementCriteriaKills(zone)
                    byNPC = RARE_CRITERIA_BY_NPC[achievementId]
                    break
                end
            end
        end
        local npcID = rare and rare[6]
        if npcID and byNPC and byNPC[npcID] ~= nil then return byNPC[npcID] end
        return RARE_CRITERIA_COMPLETION[tostring(achievementId) .. ":" .. tostring(criteriaIndex)] == true
    end

    local function GetZoneStatus(zone)
        local numDone = 0
        local status  = {}
        for i, rare in ipairs(zone.rares) do
            local name    = rare[1]
            local questId = rare[2]
            local flagged = IsRareQuestCompleted(rare)
            if flagged then SyncRareKillRecord(questId) end
            local killStatus = GetRareTrackedKillStatus(rare)
                               or (flagged and "today")
                               or nil
            local weekly = killStatus ~= nil
            local ever = IsAchievementCriteriaCompleted(zone.achievId, i, rare)
            if weekly then numDone = numDone + 1 end
            status[i] = { name = name, weekly = weekly, ever = ever, killStatus = killStatus }
        end
        return numDone, #zone.rares, status
    end


    local function SetZones(zones)
        ZONES = zones
        wipe(RARE_BY_NPC_ID)
        wipe(RARE_BY_QUEST_ID)
        wipe(RARES_BY_ZONE_AND_NPC)
        for _, zone in ipairs(ZONES) do
            local byNPC = {}
            RARES_BY_ZONE_AND_NPC[zone] = byNPC
            for _, rare in ipairs(zone.rares) do
                if rare[2] then RARE_BY_QUEST_ID[rare[2]] = rare end
                for _, questID in ipairs(rare.questIDs or {}) do RARE_BY_QUEST_ID[questID] = rare end
                if rare[6] then
                    byNPC[rare[6]] = rare
                    RARE_BY_NPC_ID[rare[6]] = rare
                end
            end
        end
    end

    local function SyncAll(resolveQuestIDs)
        local changed = false
        for _, zone in ipairs(ZONES) do
            if SyncNewAchievementCriteriaKills(zone) then changed = true end
            if resolveQuestIDs and ResolveRareQuestIDs(zone) then changed = true end
            for _, rare in ipairs(zone.rares) do
                local questId = rare[2]
                if questId and IsRareQuestCompleted(rare) then
                    if SyncRareKillRecord(questId) then changed = true end
                end
            end
        end
        return changed
    end

function MR:SyncAllRareKills(resolveQuestIDs)
    if context.refreshZones then context.refreshZones() end
    local now = GetTime()
    local remaining = self._lastRareKillSyncAt and (1 - (now - self._lastRareKillSyncAt)) or 0
    if resolveQuestIDs ~= true and remaining > 0 then
        if not self._rareKillSyncTimer then
            self._rareKillSyncTimer = self:ScheduleTimer(function()
                self._rareKillSyncTimer = nil
                if self:SyncAllRareKills() then tracking:Fire("RaresChanged") end
            end, remaining)
        end
        return false
    end
    if self._rareKillSyncTimer then
        self:CancelTimer(self._rareKillSyncTimer)
        self._rareKillSyncTimer = nil
    end
    self._lastRareKillSyncAt = now
    local dayKey = GetCurrentDayKey()
    local weekKey = self:GetCurrentWeekKey()
    local changed = self._lastRareSyncDay ~= dayKey or self._lastRareSyncWeek ~= weekKey
    self._lastRareSyncDay = dayKey
    self._lastRareSyncWeek = weekKey
    if resolveQuestIDs == nil then
        resolveQuestIDs = context.isSurfaceVisible and context.isSurfaceVisible() or false
    end
    if SyncAll(resolveQuestIDs) then changed = true end
    return changed
end


    return {
        GetCurrentZoneKey = GetCurrentZoneKey,
        GetCurrentDayKey = GetCurrentDayKey,
        ResolveRareQuestIDs = ResolveRareQuestIDs,
        SyncRareKillRecord = SyncRareKillRecord,
        GetRareTrackedKillStatus = GetRareTrackedKillStatus,
        IsRareQuestCompleted = IsRareQuestCompleted,
        GetStoredRareKillStatus = GetStoredRareKillStatus,
        BetterKillStatus = BetterKillStatus,
        IsAchievementCriteriaCompleted = IsAchievementCriteriaCompleted,
        GetZoneStatus = GetZoneStatus,
        SetZones = SetZones,
        SyncAll = SyncAll,
    }
end
