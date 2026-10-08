local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end

local CAPTURE_DEBOUNCE = 0.5
local GUILD_TAB_SLOTS = 98

local function Now()
    return (GetServerTime and GetServerTime()) or time()
end

local function IsEventValid(event)
    return not (C_EventUtils and C_EventUtils.IsEventValid) or C_EventUtils.IsEventValid(event)
end

local function Label(key, default)
    return RoutineData:GetLabel(key, default)
end

local function SnapshotContainer(bagID, name, icon)
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then return nil end
    local ok, slots = pcall(C_Container.GetContainerNumSlots, bagID)
    if not ok or type(slots) ~= "number" or slots <= 0 then return nil end
    local tab = { name = name, icon = icon, slots = slots, items = {} }
    for slot = 1, slots do
        local success, info = pcall(C_Container.GetContainerItemInfo, bagID, slot)
        if success and info and info.itemID then
            local link = info.hyperlink
            tab.items[slot] = {
                id = info.itemID,
                link = link,
                name = (link and link:match("%[(.-)%]")) or (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(info.itemID)),
                icon = info.iconFileID,
                count = tonumber(info.stackCount) or 1,
                quality = info.quality,
            }
        end
    end
    return tab
end

local function BankMetadata(bankType)
    if not (C_Bank and C_Bank.FetchPurchasedBankTabData and Enum and Enum.BankType) then return nil end
    local ok, data = pcall(C_Bank.FetchPurchasedBankTabData, bankType)
    return ok and type(data) == "table" and data or nil
end

local function AddTab(tabs, tab)
    if tab then tabs[#tabs + 1] = tab end
end

local function CountTab(tab)
    local counts = {}
    for _, item in pairs(tab and tab.items or {}) do
        if type(item) == "table" and item.id then
            counts[item.id] = (counts[item.id] or 0) + (tonumber(item.count) or 1)
        end
    end
    return counts
end

local function CountTabs(tabs)
    local combined = {}
    for _, tab in pairs(tabs) do
        for itemID, count in pairs(CountTab(tab)) do
            combined[itemID] = (combined[itemID] or 0) + count
        end
    end
    return combined
end

local function CollectBags()
    local bagIndex = Enum and Enum.BagIndex or {}
    local tabs = {}
    AddTab(tabs, SnapshotContainer(bagIndex.Backpack or 0, Label("AltBoard_BankBackpack", "Backpack")))
    for index = 1, 5 do
        local bagID = bagIndex["Bag_" .. index] or index
        AddTab(tabs, SnapshotContainer(bagID, string.format(Label("AltBoard_BagSlot", "Bag %d"), index)))
    end
    return #tabs > 0 and tabs or nil
end

local function CollectCharacterBank()
    local bagIndex = Enum and Enum.BagIndex or {}
    local tabs = {}
    if not bagIndex.CharacterBankTab_1 then
        AddTab(tabs, SnapshotContainer(bagIndex.Bank or -1, Label("AltBoard_BankMain", "Bank")))
        for index = 1, 7 do
            local bagID = NUM_BAG_SLOTS and (NUM_BAG_SLOTS + index)
            if bagID then
                AddTab(tabs, SnapshotContainer(bagID, string.format(Label("AltBoard_BankBag", "Bank bag %d"), index)))
            end
        end
    else
        local metadata = BankMetadata(Enum and Enum.BankType and Enum.BankType.Character)
        for index = 1, 9 do
            local bagID = bagIndex["CharacterBankTab_" .. index]
            if bagID then
                local info = metadata and metadata[index]
                AddTab(tabs, SnapshotContainer(bagID, (info and info.name) or string.format(Label("AltBoard_BankTab", "Tab %d"), index), info and info.icon))
            end
        end
    end
    return #tabs > 0 and tabs or nil
end

local function CollectWarbandBank()
    if not (Enum and Enum.BagIndex and Enum.BankType and Enum.BankType.Account and C_Bank) then return nil end
    if C_PlayerInfo and C_PlayerInfo.HasAccountInventoryLock and not C_PlayerInfo.HasAccountInventoryLock() then return nil end
    if C_Bank.FetchBankLockedReason then
        local ok, reason = pcall(C_Bank.FetchBankLockedReason, Enum.BankType.Account)
        if not ok or (reason ~= nil and reason ~= (Enum.BankLockedReason and Enum.BankLockedReason.None or 0)) then return nil end
    end
    local metadata = BankMetadata(Enum.BankType.Account)
    local tabs = {}
    for index = 1, 9 do
        local bagID = Enum.BagIndex["AccountBankTab_" .. index]
        if bagID then
            local info = metadata and metadata[index]
            AddTab(tabs, SnapshotContainer(bagID, (info and info.name) or string.format(Label("AltBoard_BankTab", "Tab %d"), index), info and info.icon))
        end
    end
    return #tabs > 0 and tabs or nil
end

local function CurrentGuildIdentity()
    if not GetGuildInfo then return nil end
    local guildName, _, _, guildRealm = GetGuildInfo("player")
    if not guildName then return nil end
    local realm = guildRealm or (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName and GetRealmName())
    if not realm then return nil end
    realm = realm:gsub("%s+", "")
    return guildName, realm, realm .. ":" .. guildName
end

-- Capture ----------------------------------------------------------------------

function RoutineData:CaptureBags()
    local charKey = self:GetCurrentCharacterKey()
    local tabs = CollectBags()
    if not charKey or not tabs then return end
    local now = Now()
    local record = self:GetCharacterRecord(charKey, true)
    record.bags = CountTabs(tabs)
    record.classFile = select(2, UnitClass("player")) or record.classFile
    record.updatedAt.bags = now
    self.db.snapshots.bags[charKey] = { tabs = tabs, updatedAt = now }
    self:Fire("ItemsUpdated", charKey, "bags")
end

function RoutineData:CaptureCharacterBank()
    local charKey = self:GetCurrentCharacterKey()
    local tabs = CollectCharacterBank()
    if not charKey or not tabs then return end
    local now = Now()
    local record = self:GetCharacterRecord(charKey, true)
    record.bank = CountTabs(tabs)
    record.updatedAt.bank = now
    self.db.snapshots.characters[charKey] = { tabs = tabs, updatedAt = now }
    self:Fire("ItemsUpdated", charKey, "bank")
end

function RoutineData:CaptureWarbandBank()
    local tabs = CollectWarbandBank()
    if not tabs then return end
    local now = Now()
    local counts = {}
    for index, tab in ipairs(tabs) do
        counts[index] = CountTab(tab)
    end
    self.db.warband = { tabs = counts, updatedAt = now }
    self.db.snapshots.warband = { tabs = tabs, updatedAt = now }
    self:Fire("ItemsUpdated", nil, "warband")
end

function RoutineData:RefreshCharacterGuild()
    local charKey = self:GetCurrentCharacterKey()
    if not charKey then return end
    local _, _, guildKey = CurrentGuildIdentity()
    if guildKey then
        self.db.characterGuilds[charKey] = guildKey
    elseif IsInGuild and not IsInGuild() then
        self.db.characterGuilds[charKey] = false
    else
        return
    end
    self:Fire("ItemsUpdated", charKey, "guild")
end

-- Only the tab currently open can be read, so other tabs keep their last snapshot.
function RoutineData:CaptureGuildBank()
    if not (GetNumGuildBankTabs and GetGuildBankTabInfo and GetGuildBankItemInfo) then return end
    local guildName, realm, guildKey = CurrentGuildIdentity()
    local charKey = self:GetCurrentCharacterKey()
    if not guildKey or not charKey then return end

    self.db.characterGuilds[charKey] = guildKey
    local guild = self.db.guilds[guildKey]
    if not guild then
        guild = { tabs = {} }
        self.db.guilds[guildKey] = guild
    end
    guild.name = guildName
    guild.realm = realm

    local snapshot = self.db.snapshots.guildBanks[charKey]
    if not snapshot or snapshot.guildKey ~= guildKey then
        snapshot = { tabs = {}, guildKey = guildKey }
    end
    snapshot.name = guildName
    snapshot.realm = realm
    snapshot.money = GetGuildBankMoney and GetGuildBankMoney() or snapshot.money
    self.db.snapshots.guildBanks[charKey] = snapshot

    local numTabs = GetNumGuildBankTabs() or 0
    if numTabs == 0 then
        self:Fire("ItemsUpdated", charKey, "guild")
        return
    end
    snapshot.numTabs = numTabs
    local currentTab = GetCurrentGuildBankTab and GetCurrentGuildBankTab()
    for index = 1, numTabs do
        local name, icon, canView = GetGuildBankTabInfo(index)
        local tabName = name or string.format(Label("AltBoard_BankTab", "Tab %d"), index)
        local old = snapshot.tabs[index]
        if not canView then
            guild.tabs[index] = nil
            snapshot.tabs[index] = nil
        elseif index == currentTab then
            local tab = { name = tabName, icon = icon, slots = GUILD_TAB_SLOTS, items = {} }
            for slot = 1, GUILD_TAB_SLOTS do
                local texture, count, _, _, quality = GetGuildBankItemInfo(index, slot)
                if texture then
                    local link = GetGuildBankItemLink and GetGuildBankItemLink(index, slot)
                    tab.items[slot] = {
                        id = link and tonumber(link:match("item:(%d+)")),
                        link = link,
                        name = link and link:match("%[(.-)%]"),
                        icon = texture,
                        count = tonumber(count) or 1,
                        quality = quality,
                    }
                end
            end
            snapshot.tabs[index] = tab
            guild.tabs[index] = CountTab(tab)
        elseif not old then
            snapshot.tabs[index] = { name = tabName, icon = icon, slots = GUILD_TAB_SLOTS, items = {}, uncaptured = true }
        else
            old.name = name or old.name
            old.icon = icon or old.icon
        end
    end
    for index in pairs(guild.tabs) do
        if index > numTabs then guild.tabs[index] = nil end
    end
    local now = Now()
    guild.updatedAt = now
    snapshot.updatedAt = now
    self:Fire("ItemsUpdated", charKey, "guild")
end

-- Events -----------------------------------------------------------------------

local state = {}

local function Debounced(key, func)
    if state[key] then return end
    state[key] = true
    C_Timer.After(CAPTURE_DEBOUNCE, function()
        state[key] = nil
        func()
    end)
end

local function CaptureOpenBank()
    RoutineData:CaptureCharacterBank()
    RoutineData:CaptureWarbandBank()
end

local handlers = {
    PLAYER_ENTERING_WORLD = function()
        C_Timer.After(1, function()
            RoutineData:CaptureBags()
            RoutineData:RefreshCharacterGuild()
        end)
    end,
    PLAYER_GUILD_UPDATE = function(unit)
        if not unit or unit == "player" then RoutineData:RefreshCharacterGuild() end
    end,
    GUILD_ROSTER_UPDATE = function()
        RoutineData:RefreshCharacterGuild()
    end,
    BANKFRAME_OPENED = function()
        state.bankOpen = true
        C_Timer.After(0.3, function()
            if state.bankOpen then CaptureOpenBank() end
        end)
    end,
    BANKFRAME_CLOSED = function()
        state.bankOpen = nil
    end,
    BAG_UPDATE_DELAYED = function()
        Debounced("bags", function()
            RoutineData:CaptureBags()
            if state.bankOpen then CaptureOpenBank() end
        end)
    end,
    PLAYERBANKSLOTS_CHANGED = function()
        if state.bankOpen then Debounced("bank", function() RoutineData:CaptureCharacterBank() end) end
    end,
    PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED = function()
        if state.bankOpen then Debounced("warband", function() RoutineData:CaptureWarbandBank() end) end
    end,
    GUILDBANKFRAME_OPENED = function()
        state.guildBankOpen = true
        C_Timer.After(0.4, function()
            if state.guildBankOpen then RoutineData:CaptureGuildBank() end
        end)
    end,
    GUILDBANKFRAME_CLOSED = function()
        state.guildBankOpen = nil
    end,
    GUILDBANKBAGSLOTS_CHANGED = function()
        if state.guildBankOpen then Debounced("guild", function() RoutineData:CaptureGuildBank() end) end
    end,
    GUILDBANK_UPDATE_TABS = function()
        if state.guildBankOpen then Debounced("guild", function() RoutineData:CaptureGuildBank() end) end
    end,
    PLAYER_INTERACTION_MANAGER_FRAME_SHOW = function(interactionType)
        if Enum.PlayerInteractionType and interactionType == Enum.PlayerInteractionType.GuildBanker then
            state.guildBankOpen = true
            C_Timer.After(0.4, function()
                if state.guildBankOpen then RoutineData:CaptureGuildBank() end
            end)
        end
    end,
    PLAYER_INTERACTION_MANAGER_FRAME_HIDE = function(interactionType)
        if Enum.PlayerInteractionType and interactionType == Enum.PlayerInteractionType.GuildBanker then
            state.guildBankOpen = nil
        end
    end,
}

RoutineData:OnLogin(function()
    local frame = CreateFrame("Frame")
    for event in pairs(handlers) do
        if IsEventValid(event) then frame:RegisterEvent(event) end
    end
    frame:SetScript("OnEvent", function(_, event, ...)
        handlers[event](...)
    end)
end)
