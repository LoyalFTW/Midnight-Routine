local _, ns = ...
local RoutineData = _G.RoutineData
local API = RoutineData.API
local tracking = RoutineData.Tracking

local function Engine()
    local engine = tracking.engine
    return engine and engine.db and engine or nil
end

local function SavedRecord(charKey)
    local engine = Engine()
    return engine and type(charKey) == "string" and engine:GetCharacter(charKey) or nil
end

function API.IsReady()
    return Engine() ~= nil
end

local baseGetCharacters = API.GetCharacters

function API.GetCharacters()
    local seen, keys = {}, {}
    local function add(charKey)
        if not seen[charKey] then
            seen[charKey] = true
            keys[#keys + 1] = charKey
        end
    end
    for _, charKey in ipairs(baseGetCharacters and RoutineData.db and baseGetCharacters() or {}) do
        add(charKey)
    end
    local engine = Engine()
    for charKey, charData in pairs(engine and engine:GetCharacters() or {}) do
        if type(charData) == "table" then
            add(charKey)
        end
    end
    table.sort(keys)
    return keys
end

function API.GetGold(charKey)
    local own = RoutineData.db and RoutineData.db.characters[charKey]
    local gold = own and tonumber(own.gold)
    if gold then
        return gold
    end
    local record = SavedRecord(charKey)
    return record and tonumber(record.gold) or 0
end

function API.GetGoldRanking()
    local entries = {}
    for _, charKey in ipairs(API.GetCharacters()) do
        local record = SavedRecord(charKey)
        entries[#entries + 1] = {
            key = charKey,
            classFile = (API.GetCharacterClass and API.GetCharacterClass(charKey)) or (record and record.classFile),
            gold = API.GetGold(charKey),
        }
    end
    table.sort(entries, function(a, b)
        if a.gold ~= b.gold then return a.gold > b.gold end
        return a.key < b.key
    end)
    return entries
end

function API.GetCharacterInfo(charKey)
    local record = SavedRecord(charKey)
    local own = RoutineData.db and type(charKey) == "string" and RoutineData.db.characters[charKey] or nil
    if not (record or own) then
        return nil
    end
    local name, realm = charKey:match("^(.-)%s%-%s(.+)$")
    local lastSyncAt = record and tonumber(record.lastSyncAt)
        or own and tonumber(own.updatedAt and (own.updatedAt.gold or own.updatedAt.bags))
    return {
        key = charKey,
        name = name or charKey,
        realm = realm or "",
        classFile = record and record.classFile or own and own.classFile,
        gold = API.GetGold(charKey),
        mythicPlusScore = record and tonumber(record.mythicPlusScore),
        lastSyncAt = lastSyncAt or 0,
        updatedAt = own and own.updatedAt and CopyTable(own.updatedAt) or {},
    }
end

function API.GetProgress(charKey, moduleKey, rowKey)
    if not SavedRecord(charKey) then
        return 0
    end
    return Engine():GetProgress(moduleKey, rowKey, charKey)
end

function API.GetManualOverride(charKey, moduleKey, rowKey)
    if not SavedRecord(charKey) then
        return 0
    end
    return Engine():GetManualOverride(moduleKey, rowKey, charKey)
end

function API.GetProfessions(charKey)
    local record = SavedRecord(charKey)
    return record and record.professions and CopyTable(record.professions) or nil
end

function API.GetConcentration(charKey)
    local record = SavedRecord(charKey)
    return record and record.professionConcentration and CopyTable(record.professionConcentration) or nil
end

function API.GetRareCatalog()
    local entries = {}
    if RoutineData.isForever then
        local byNPC = {}
        for npcID, rare in pairs(tracking.Forever.rareCatalog or {}) do
            local entry = { npcID = npcID, name = rare.name, locations = {} }
            byNPC[npcID] = entry
            entries[#entries + 1] = entry
        end
        for mapID, rares in pairs(tracking.Forever.rareLocations or {}) do
            for npcID, points in pairs(rares) do
                local entry = byNPC[npcID]
                if entry then
                    for _, point in ipairs(points) do
                        entry.locations[#entry.locations + 1] = { mapID = mapID, x = point[1], y = point[2] }
                    end
                end
            end
        end
        table.sort(entries, function(a, b) return a.npcID < b.npcID end)
        return entries
    end

    for _, catalog in ipairs(tracking.rareCatalogs or {}) do
        for _, rare in ipairs(catalog.rares) do
            local locations = {}
            if rare[3] then
                locations[1] = { mapID = rare[3], x = rare[4], y = rare[5] }
            end
            entries[#entries + 1] = {
                npcID = rare[6],
                name = rare[1],
                locations = locations,
                catalog = catalog.label,
                questID = rare[2],
                questIDs = rare.questIDs and CopyTable(rare.questIDs),
                questAny = rare.questAny,
                achievementID = rare.achievementID,
                criteriaID = rare.criteriaID,
                faction = rare.faction,
                patch = rare.patch,
                eventName = rare.eventName,
                spawnNote = rare.spawnNote,
            }
        end
    end
    return entries
end

function API.GetRareKillSnapshot(charKey)
    local db = RoutineData.db
    local record = db and type(charKey) == "string" and db.characters[charKey]
    if type(record) ~= "table" then return nil end
    local updatedAt = type(record.updatedAt) == "table" and record.updatedAt.rares or nil
    if type(record.rares) ~= "table" and not updatedAt then return nil end
    return {
        kills = type(record.rares) == "table" and CopyTable(record.rares) or {},
        updatedAt = updatedAt,
    }
end

function API.GetRareKills(charKey)
    local record = SavedRecord(charKey)
    return record and record.raresKills and CopyTable(record.raresKills) or nil
end

function API.GetWarbandGold()
    local engine = Engine()
    local global = engine and engine.db.global
    return global and tonumber(global.warbandGold) or 0
end

function API.GetLastReset(resetType)
    local engine = Engine()
    if not engine then
        return nil
    end
    if resetType == "daily" then
        return engine:GetLastDailyTimestamp()
    end
    return engine:GetLastResetTimestamp()
end

function API.GetCurrentWeekKey()
    local engine = Engine()
    return engine and engine:GetCurrentWeekKey() or 0
end

function API.GetBankSnapshots()
    local view = RoutineData:GetBankSnapshotView()
    return view and CopyTable(view) or nil
end

local bridge = {}

tracking.RegisterCallback(bridge, "ResetApplied", function(_, resetType)
    RoutineData.callbacks:Fire(resetType == "weekly" and "WeeklyReset" or "DailyReset")
end)

for _, event in ipairs({ "DataRefreshRequested", "DataChanged" }) do
    tracking.RegisterCallback(bridge, event, function()
        RoutineData.callbacks:Fire("DataChanged")
    end)
end

tracking.RegisterCallback(bridge, "TrackingFailure", function(_, source, err)
    RoutineData.callbacks:Fire("TrackingFailure", source, err)
end)
