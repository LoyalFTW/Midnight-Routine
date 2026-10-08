local addonName, ns = ...

local RoutineData = _G.RoutineData or {}
_G.RoutineData = RoutineData

RoutineData.isForever = RoutineData.Tracking.API.isForever

ns.RoutineData = RoutineData

function RoutineData.CharacterLabel(charKey, classFile)
    local name, realm = charKey:match("^(.-)%s%-%s(.+)$")
    name = name or charKey
    if realm and realm ~= GetRealmName() then
        name = name .. "-" .. realm
    end
    local color = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    return color and color:WrapTextInColorCode(name) or name
end

local API = RoutineData.API

local DB_VERSION = 1

local DEFAULTS = {
    settings = {
        tooltipItems = true,
        tooltipYield = true,
        tooltipCurrency = true,
        tooltipRares = true,
        minimap = { hide = false },
        tooltipBags = true,
        tooltipBank = true,
        tooltipWarband = true,
        tooltipGuild = true,
    },
}

local function MergeMissing(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then target[key] = {} end
            MergeMissing(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
end

function RoutineData:GetDB()
    return self.db
end

function RoutineData:Print(message)
    print("|cff2ae7c6RoutineData|r: " .. tostring(message))
end

local SURNAME_WAIT_SECONDS = 5

local function LegacyCharacterKey()
    local name, realm = UnitName("player"), GetRealmName()
    if type(name) == "string" and name ~= "" and type(realm) == "string" and realm ~= "" then
        return name .. " - " .. realm
    end
end

function RoutineData:ResolveCharacterKey()
    local regional = type(_G.RegionalUniqueNamesEnabled) == "function" and _G.RegionalUniqueNamesEnabled() == true
        and type(_G.UnitNameUnmodified) == "function"
    local name, surname
    if regional then
        name, surname = _G.UnitNameUnmodified("player")
    else
        name = UnitName("player")
    end
    local realm = GetRealmName()
    if type(name) ~= "string" or name == "" or name == UNKNOWNOBJECT or type(realm) ~= "string" or realm == "" then
        return nil
    end
    if not regional then
        return name .. " - " .. realm
    end
    if type(surname) == "string" then
        return name .. " " .. surname
    end
    self.surnameWaitStart = self.surnameWaitStart or GetTime()
    if GetTime() - self.surnameWaitStart >= SURNAME_WAIT_SECONDS then
        return name
    end
end

function RoutineData:MigrateLegacyCharacterKey(key)
    local db = self.db
    local legacy = LegacyCharacterKey()
    if not (db and legacy and legacy ~= key and db.characters[legacy] and not db.characters[key]) then return end

    db.characters[key], db.characters[legacy] = db.characters[legacy], nil
    for _, store in ipairs({ db.characterGuilds, db.snapshots.characters, db.snapshots.bags, db.snapshots.guildBanks }) do
        if store[legacy] ~= nil and store[key] == nil then
            store[key], store[legacy] = store[legacy], nil
        end
    end
end

function RoutineData:GetCurrentCharacterKey()
    if self.currentKey then return self.currentKey end

    local engine = self.Tracking.engine
    local handles = engine and engine.db and engine.db.GetNativeHandles and engine.db:GetNativeHandles()
    local key = handles and handles.charKey or self:ResolveCharacterKey()
    if key then
        self.currentKey = key
        self:MigrateLegacyCharacterKey(key)
    end
    return key
end

function RoutineData:GetCharacterRecord(charKey, create)
    local characters = self.db.characters
    local record = characters[charKey]
    if not record and create then
        record = { bags = {}, bank = {}, currencies = {}, updatedAt = {} }
        characters[charKey] = record
    end
    if record and not record.currencies then record.currencies = {} end
    return record
end

-- Removes everything stored for one character. Returns true when a record existed.
function RoutineData:ForgetCharacter(charKey)
    if not self.db.characters[charKey] then return false end
    self.db.characters[charKey] = nil
    self.db.characterGuilds[charKey] = nil
    self.db.snapshots.characters[charKey] = nil
    self.db.snapshots.bags[charKey] = nil
    self.db.snapshots.guildBanks[charKey] = nil
    self:Fire("CharacterRemoved", charKey)
    return true
end

function RoutineData:SetLabelProvider(provider)
    self.labelProvider = provider
end

function RoutineData:GetLabel(key, default)
    local provider = self.labelProvider
    return provider and provider(key) or default
end

function RoutineData:GetBankSnapshotView()
    local db = self.db
    if not (db and db.snapshots) then return nil end
    return {
        characters = db.snapshots.characters,
        bags = db.snapshots.bags,
        warband = db.snapshots.warband,
        characterGuilds = db.characterGuilds,
        characterGuildBanks = db.snapshots.guildBanks,
    }
end

function RoutineData:Fire(event, ...)
    self.callbacks:Fire(event, ...)
end

-- Files register work to run once at PLAYER_LOGIN, after the DB is ready.
RoutineData.loginHandlers = {}
function RoutineData:OnLogin(handler)
    self.loginHandlers[#self.loginHandlers + 1] = handler
end

-- Public API -----------------------------------------------------------------

function API.GetVersion()
    return API.version
end

function API.RegisterCallback(owner, event, method)
    return RoutineData.RegisterCallback(owner, event, method)
end

function API.UnregisterCallback(owner, event)
    return RoutineData.UnregisterCallback(owner, event)
end

function API.GetCurrentCharacterKey()
    return RoutineData:GetCurrentCharacterKey()
end

function API.GetCharacters()
    local keys = {}
    for charKey in pairs(RoutineData.db.characters) do
        keys[#keys + 1] = charKey
    end
    table.sort(keys)
    return keys
end

function API.GetCharacterClass(charKey)
    local record = RoutineData.db.characters[charKey]
    return record and record.classFile or nil
end

local function SumTabs(tabs, itemID)
    local total = 0
    for _, items in pairs(tabs or {}) do
        total = total + (items[itemID] or 0)
    end
    return total
end

-- Returns { characters = { {key, classFile, bags, bank}, ... }, warband = n, guilds = { {key, name, realm, count}, ... } }
-- Only characters/guilds that hold the item are listed.
function API.GetItemCounts(itemID)
    local db = RoutineData.db
    local result = { characters = {}, warband = 0, guilds = {} }
    if not db or type(itemID) ~= "number" then return result end

    for charKey, record in pairs(db.characters) do
        local bags = record.bags[itemID] or 0
        local bank = record.bank[itemID] or 0
        if bags > 0 or bank > 0 then
            result.characters[#result.characters + 1] = {
                key = charKey,
                classFile = record.classFile,
                bags = bags,
                bank = bank,
            }
        end
    end
    table.sort(result.characters, function(a, b) return a.key < b.key end)

    result.warband = SumTabs(db.warband.tabs, itemID)

    for guildKey, guild in pairs(db.guilds) do
        local count = SumTabs(guild.tabs, itemID)
        if count > 0 then
            result.guilds[#result.guilds + 1] = { key = guildKey, name = guild.name, realm = guild.realm, count = count }
        end
    end
    table.sort(result.guilds, function(a, b) return a.key < b.key end)

    return result
end

function API.GetGold(charKey)
    local record = RoutineData.db.characters[charKey]
    return record and record.gold or 0
end

function API.GetTotalGold()
    local total = 0
    for _, record in pairs(RoutineData.db.characters) do
        total = total + (record.gold or 0)
    end
    return total
end

-- Start of the current weekly reset window, used to ignore stale "earned this week" values.
function RoutineData:GetLastWeeklyReset()
    local untilReset = C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset and C_DateAndTime.GetSecondsUntilWeeklyReset()
    if not untilReset then return 0 end
    return GetServerTime() + untilReset - 7 * 24 * 3600
end

-- Returns { {key, classFile, quantity, weekly, maxWeekly}, ... } for characters holding the currency.
-- `weekly` is the amount earned this week, or 0 when the snapshot predates the last weekly reset.
function API.GetCurrencyCounts(currencyID)
    local result = {}
    local db = RoutineData.db
    if not db or type(currencyID) ~= "number" then return result end
    local lastReset = RoutineData:GetLastWeeklyReset()
    for charKey, record in pairs(db.characters) do
        local entry = record.currencies and record.currencies[currencyID]
        if entry then
            local fresh = (record.updatedAt.currencies or 0) >= lastReset
            result[#result + 1] = {
                key = charKey,
                classFile = record.classFile,
                quantity = entry.q,
                weekly = fresh and entry.w or 0,
                maxWeekly = entry.mw or 0,
            }
        end
    end
    table.sort(result, function(a, b) return a.key < b.key end)
    return result
end

function API.GetTotalItemCount(itemID)
    local counts = API.GetItemCounts(itemID)
    local total = counts.warband
    for _, entry in ipairs(counts.characters) do
        total = total + entry.bags + entry.bank
    end
    for _, entry in ipairs(counts.guilds) do
        total = total + entry.count
    end
    return total
end

-- Lifecycle ------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event, loadedName)
    if event == "ADDON_LOADED" then
        if loadedName ~= addonName then return end
        RoutineDataDB = RoutineDataDB or {}
        local db = RoutineDataDB
        db.version = db.version or DB_VERSION
        db.characters = db.characters or {}
        db.warband = db.warband or { tabs = {} }
        db.guilds = db.guilds or {}
        db.characterGuilds = db.characterGuilds or {}
        db.snapshots = db.snapshots or {}
        db.snapshots.characters = db.snapshots.characters or {}
        db.snapshots.bags = db.snapshots.bags or {}
        db.snapshots.guildBanks = db.snapshots.guildBanks or {}
        db.imported = db.imported or {}
        db.settings = db.settings or {}
        MergeMissing(db, DEFAULTS)
        RoutineData.db = db
    elseif event == "PLAYER_LOGIN" then
        frame:UnregisterEvent("PLAYER_LOGIN")
        RoutineData.loggedIn = true
        -- One failing handler must not stop the rest from starting.
        for _, handler in ipairs(RoutineData.loginHandlers) do
            xpcall(handler, geterrorhandler(), RoutineData)
        end
        RoutineData:Fire("DataReady")
    end
end)
