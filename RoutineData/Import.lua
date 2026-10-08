local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end
local L = LibStub("AceLocale-3.0"):GetLocale("RoutineData")

-- One-time import of the bank/bag snapshots Routine collected before RoutineData existed.
-- Only fills gaps; never overwrites anything RoutineData has captured itself.

local function CountTab(tab)
    local counts = {}
    for _, item in pairs(tab and tab.items or {}) do
        if type(item) == "table" and item.id then
            counts[item.id] = (counts[item.id] or 0) + (tonumber(item.count) or 1)
        end
    end
    return counts
end

local function CountTabs(snapshot)
    local combined = {}
    for _, tab in pairs(snapshot and snapshot.tabs or {}) do
        for itemID, count in pairs(CountTab(tab)) do
            combined[itemID] = (combined[itemID] or 0) + count
        end
    end
    return combined
end

local function ImportCharacterSnapshots(legacy, field, snapshots)
    for charKey, snapshot in pairs(snapshots or {}) do
        local record = RoutineData:GetCharacterRecord(charKey, true)
        if not record.updatedAt[field] then
            record[field] = CountTabs(snapshot)
            record.updatedAt[field] = snapshot.updatedAt
        end
        local charData = legacy.char and legacy.char[charKey]
        record.classFile = record.classFile or (charData and charData.classFile)
    end
end

local function ImportWarband(db, snapshot)
    if not snapshot or db.warband.updatedAt then return end
    local tabs = {}
    for index, tab in pairs(snapshot.tabs or {}) do
        tabs[index] = CountTab(tab)
    end
    db.warband = { tabs = tabs, updatedAt = snapshot.updatedAt }
end

local function ImportGuilds(db, store)
    for charKey, guildKey in pairs(store.characterGuilds or {}) do
        if db.characterGuilds[charKey] == nil then db.characterGuilds[charKey] = guildKey end
    end
    for _, snapshot in pairs(store.characterGuildBanks or {}) do
        local guildKey = snapshot.guildKey
        if guildKey and not db.guilds[guildKey] then
            local tabs = {}
            for index, tab in pairs(snapshot.tabs or {}) do
                if not tab.uncaptured then tabs[index] = CountTab(tab) end
            end
            db.guilds[guildKey] = { name = snapshot.name, realm = snapshot.realm, tabs = tabs, updatedAt = snapshot.updatedAt }
        end
    end
end

local function CopyTable(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, child in pairs(value) do
        copy[key] = CopyTable(child)
    end
    return copy
end

local function ImportDetailedSnapshots(db, store)
    local snapshots = db.snapshots
    for field, target in pairs({ bags = snapshots.bags, characters = snapshots.characters }) do
        for charKey, snapshot in pairs(store[field] or {}) do
            if target[charKey] == nil then target[charKey] = CopyTable(snapshot) end
        end
    end
    for charKey, snapshot in pairs(store.characterGuildBanks or {}) do
        if snapshots.guildBanks[charKey] == nil then snapshots.guildBanks[charKey] = CopyTable(snapshot) end
    end
    if store.warband and not snapshots.warband then
        snapshots.warband = CopyTable(store.warband)
    end
end

local function ImportGold(db, legacy)
    for charKey, charData in pairs(legacy.char or {}) do
        if type(charData) == "table" and tonumber(charData.gold) then
            local record = RoutineData:GetCharacterRecord(charKey, true)
            if not record.updatedAt.gold then
                record.gold = charData.gold
                record.updatedAt.gold = charData.lastSyncAt
            end
            record.classFile = record.classFile or charData.classFile
        end
    end
end

RoutineData:OnLogin(function(self)
    local db = self.db
    local legacy = _G.MidnightRoutineDB
    if type(legacy) ~= "table" then return end

    if not db.imported.routineGold then
        ImportGold(db, legacy)
        db.imported.routineGold = true
    end

    local store = legacy.global and legacy.global.altBankSnapshots
    if type(store) ~= "table" then return end

    if not db.imported.routineBanks then
        ImportCharacterSnapshots(legacy, "bags", store.bags)
        ImportCharacterSnapshots(legacy, "bank", store.characters)
        ImportWarband(db, store.warband)
        ImportGuilds(db, store)
        db.imported.routineBanks = true
        self:Print(L["Import_Done"])
    end

    if not db.imported.routineSnapshots then
        ImportDetailedSnapshots(db, store)
        db.imported.routineSnapshots = true
    end
end)
