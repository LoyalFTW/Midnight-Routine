local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end

local CAPTURE_DEBOUNCE = 0.5
local GUILD_TAB_SLOTS = 98
local MAIL_ATTACHMENTS = 16

local function Now()
    return (GetServerTime and GetServerTime()) or time()
end

local function IsEventValid(event)
    return not (C_EventUtils and C_EventUtils.IsEventValid) or C_EventUtils.IsEventValid(event)
end

local function Label(key, default)
    return RoutineData:GetLabel(key, default)
end

local function SnapshotContainer(bagID, name, icon, requireComplete)
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then return nil, true end
    local bagIndex = Enum and Enum.BagIndex or {}
    local getSlots = GetKeyRingSize and bagID == (bagIndex.Keyring or -2) and GetKeyRingSize or C_Container.GetContainerNumSlots
    local ok, slots = pcall(getSlots, bagID)
    if not ok or type(slots) ~= "number" or slots < 0 then return nil, true end
    if slots == 0 then return nil end
    local tab = { name = name, icon = icon, slots = slots, items = {} }
    for slot = 1, slots do
        local success, info = pcall(C_Container.GetContainerItemInfo, bagID, slot)
        if requireComplete and (not success or (info and not info.itemID)) then return nil, true end
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
    if GetKeyRingSize then
        AddTab(tabs, SnapshotContainer(bagIndex.Keyring or -2, KEYRING or "Keyring"))
    end
    return #tabs > 0 and tabs or nil
end

local function CollectPurchasedBank(bankType)
    local metadata = BankMetadata(bankType)
    if not metadata or #metadata == 0 then return nil end
    local tabs = {}
    for index, info in ipairs(metadata) do
        local tab = SnapshotContainer(info.ID, info.name or string.format(Label("AltBoard_BankTab", "Tab %d"), index), info.icon, true)
        if not tab then return nil end
        tabs[index] = tab
    end
    return tabs
end

local function CollectCharacterBank()
    local bagIndex = Enum and Enum.BagIndex or {}
    local tabs = {}
    if not bagIndex.CharacterBankTab_1 then
        local main = SnapshotContainer(bagIndex.Bank or -1, Label("AltBoard_BankMain", "Bank"), nil, true)
        if not main then return nil end
        tabs[1] = main
        for index = 1, 7 do
            local bagID = NUM_BAG_SLOTS and (NUM_BAG_SLOTS + index)
            if bagID then
                local tab, unavailable = SnapshotContainer(bagID, string.format(Label("AltBoard_BankBag", "Bank bag %d"), index), nil, true)
                if unavailable then return nil end
                AddTab(tabs, tab)
            end
        end
    else
        return CollectPurchasedBank(Enum.BankType and Enum.BankType.Character)
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
    return CollectPurchasedBank(Enum.BankType.Account)
end

local function CollectMail(now)
    if not (GetInboxNumItems and GetInboxHeaderInfo and GetInboxItem) then return nil end
    local tab = { name = INBOX or "Inbox", items = {} }
    local slot = 0
    local numItems, totalItems = GetInboxNumItems()
    if type(numItems) ~= "number" or (numItems == 0 and (totalItems or 0) > 0) then return nil end
    for index = 1, numItems do
        local _, _, sender, subject, _, _, daysLeft, itemCount = GetInboxHeaderInfo(index)
        if sender == nil and subject == nil then return nil end
        itemCount = tonumber(itemCount) or 0
        if itemCount > 0 then
            local expiresAt = type(daysLeft) == "number" and now + daysLeft * 86400 or nil
            local firstSlot = slot
            for attachment = 1, ATTACHMENTS_MAX_RECEIVE or MAIL_ATTACHMENTS do
                local name, itemID, texture, count, quality = GetInboxItem(index, attachment)
                if itemID then
                    local link = GetInboxItemLink and GetInboxItemLink(index, attachment)
                    slot = slot + 1
                    tab.items[slot] = {
                        id = itemID,
                        link = link,
                        name = name or (link and link:match("%[(.-)%]")),
                        icon = texture,
                        count = tonumber(count) or 1,
                        quality = quality,
                        expiresAt = expiresAt,
                    }
                end
            end
            if slot - firstSlot < itemCount then return nil end
        end
    end
    tab.slots = slot
    return tab
end

local function LastEquippedSlot()
    return math.max(INVSLOT_LAST_EQUIPPED or 19, tonumber(CONTAINER_BAG_OFFSET) or 0)
end

local function CollectEquipped()
    if not GetInventoryItemID then return nil end
    local tab = { items = {} }
    local function Add(slot, stacked)
        local itemID = GetInventoryItemID("player", slot)
        if not itemID then return end
        local count = stacked and GetInventoryItemCount and GetInventoryItemCount("player", slot)
        local link = GetInventoryItemLink and GetInventoryItemLink("player", slot)
        tab.items[slot] = {
            id = itemID,
            link = link,
            name = link and link:match("%[(.-)%]"),
            icon = GetInventoryItemTexture and GetInventoryItemTexture("player", slot),
            count = tonumber(count) or 1,
        }
    end
    for slot = INVSLOT_FIRST_EQUIPPED or 1, LastEquippedSlot() do
        Add(slot)
    end
    if INVSLOT_AMMO and INVSLOT_AMMO < (INVSLOT_FIRST_EQUIPPED or 1) then
        Add(INVSLOT_AMMO, true)
    end
    return tab
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

function RoutineData:CaptureMail()
    local charKey = self:GetCurrentCharacterKey()
    local now = Now()
    local tab = CollectMail(now)
    if not charKey or not tab then return end
    local record = self:GetCharacterRecord(charKey, true)
    record.mail = CountTab(tab)
    record.updatedAt.mail = now
    self.db.snapshots.mail[charKey] = { tabs = { tab }, updatedAt = now }
    self:Fire("ItemsUpdated", charKey, "mail")
end

function RoutineData:CaptureEquipped()
    local charKey = self:GetCurrentCharacterKey()
    local tab = CollectEquipped()
    if not charKey or not tab then return end
    local now = Now()
    local record = self:GetCharacterRecord(charKey, true)
    record.equipped = CountTab(tab)
    record.updatedAt.equipped = now
    self.db.snapshots.equipped[charKey] = { tabs = { tab }, updatedAt = now }
    self:Fire("ItemsUpdated", charKey, "equipped")
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

local function CollectGuildTab(index, name, icon, now)
    if not GetGuildBankItemLink then return nil end
    local tab = { name = name, icon = icon, slots = GUILD_TAB_SLOTS, items = {}, updatedAt = now }
    for slot = 1, GUILD_TAB_SLOTS do
        local texture, count, _, _, quality = GetGuildBankItemInfo(index, slot)
        if texture then
            local link = GetGuildBankItemLink(index, slot)
            if not link then return nil end
            tab.items[slot] = {
                id = tonumber(link:match("item:(%d+)")),
                link = link,
                name = link:match("%[(.-)%]"),
                icon = texture,
                count = tonumber(count) or 1,
                quality = quality,
            }
        end
    end
    return tab
end

-- Only the tab currently open can be read, so other tabs keep their last snapshot.
function RoutineData:CaptureGuildBank(readItems)
    if not (GetNumGuildBankTabs and GetGuildBankTabInfo and GetGuildBankItemInfo) then return end
    local guildName, realm, guildKey = CurrentGuildIdentity()
    local charKey = self:GetCurrentCharacterKey()
    if not guildKey or not charKey then return end
    local numTabs = GetNumGuildBankTabs()
    if not numTabs or numTabs <= 0 then return end

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

    snapshot.numTabs = numTabs
    local currentTab = readItems and GetCurrentGuildBankTab and GetCurrentGuildBankTab()
    local now = Now()
    for index = 1, numTabs do
        local name, icon, canView = GetGuildBankTabInfo(index)
        local tabName = name or string.format(Label("AltBoard_BankTab", "Tab %d"), index)
        local old = snapshot.tabs[index]
        local tab = canView and index == currentTab and CollectGuildTab(index, tabName, icon, now)
        if canView == false then
            snapshot.tabs[index] = nil
        elseif tab then
            snapshot.tabs[index] = tab
            guild.tabs[index] = CountTab(tab)
            guild.tabUpdatedAt = guild.tabUpdatedAt or {}
            guild.tabUpdatedAt[index] = now
            guild.updatedAt = now
            snapshot.updatedAt = now
        elseif canView and not old then
            snapshot.tabs[index] = { name = tabName, icon = icon, slots = GUILD_TAB_SLOTS, items = {}, uncaptured = true }
        elseif old then
            old.name = name or old.name
            old.icon = icon or old.icon
        end
    end
    self:Fire("ItemsUpdated", charKey, "guild")
end

-- Events -----------------------------------------------------------------------

local function ModernAuctionHouse()
    return C_AuctionHouse and C_AuctionHouse.GetOwnedAuctionInfo and C_AuctionHouse.GetNumOwnedAuctions
        and Enum and Enum.AuctionStatus and C_AuctionHouse
end

local function CollectOwnedAuctions(tab, now, auctionHouse)
    if auctionHouse.HasFullOwnedAuctionResults and not auctionHouse.HasFullOwnedAuctionResults() then return false end
    for index = 1, auctionHouse.GetNumOwnedAuctions() do
        local auction = auctionHouse.GetOwnedAuctionInfo(index)
        if not auction or auction.status == nil then return false end
        if auction.status == Enum.AuctionStatus.Active then
            local itemID = auction.itemKey and auction.itemKey.itemID
            if not itemID or not auction.quantity then return false end
            local link = auction.itemLink
            tab.items[index] = {
                id = itemID,
                link = link,
                name = link and link:match("%[(.-)%]"),
                icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(itemID),
                count = auction.quantity,
                petSpeciesID = auction.itemKey.battlePetSpeciesID and auction.itemKey.battlePetSpeciesID > 0
                    and auction.itemKey.battlePetSpeciesID or nil,
                expiresAt = auction.timeLeftSeconds and now + auction.timeLeftSeconds,
            }
        end
    end
    return true
end

local LEGACY_AUCTION_MAX_SECONDS = { 1800, 7200, 43200, 172800 }

local function CollectLegacyAuctions(tab, now)
    if not (GetNumAuctionItems and GetAuctionItemInfo and GetAuctionItemTimeLeft) then return false end
    local count, total = GetNumAuctionItems("owner")
    if not count or (total and total > count) then return false end
    for index = 1, count do
        local name, icon, quantity, quality, _, _, _, _, _, _, _, _, _, _, _, saleStatus, itemID = GetAuctionItemInfo("owner", index)
        if saleStatus == nil then return false end
        if saleStatus == 0 then
            if not itemID or not quantity then return false end
            local seconds = LEGACY_AUCTION_MAX_SECONDS[GetAuctionItemTimeLeft("owner", index)]
            tab.items[index] = {
                id = itemID,
                link = GetAuctionItemLink and GetAuctionItemLink("owner", index),
                name = name,
                icon = icon,
                quality = quality,
                count = quantity,
                expiresAt = seconds and now + seconds,
            }
        end
    end
    return true
end

function RoutineData:CaptureAuctions()
    local charKey = self:GetCurrentCharacterKey()
    if not charKey then return end
    local now = Now()
    local tab = { name = AUCTIONS or "Auctions", items = {} }
    local auctionHouse = ModernAuctionHouse()
    local complete
    if auctionHouse then
        complete = CollectOwnedAuctions(tab, now, auctionHouse)
    else
        complete = CollectLegacyAuctions(tab, now)
    end
    if not complete then return end
    self:GetCharacterRecord(charKey, true)
    self.db.snapshots.auctions[charKey] = { tabs = { tab }, updatedAt = now }
    self:Fire("ItemsUpdated", charKey, "auctions")
end

local state = {}

local function QueryOwnedAuctions()
    local session = state.auctionHouse
    local auctionHouse = ModernAuctionHouse()
    if not (session and not session.queried and auctionHouse and auctionHouse.QueryOwnedAuctions) then return end
    session.queried = true
    auctionHouse.QueryOwnedAuctions({})
end

local function OpenAuctionHouse()
    if state.auctionHouse then return end
    local session = {}
    state.auctionHouse = session
    if ModernAuctionHouse() then
        C_Timer.After(CAPTURE_DEBOUNCE, function()
            if state.auctionHouse == session and C_AuctionHouse.IsThrottledMessageSystemReady
                and C_AuctionHouse.IsThrottledMessageSystemReady() then
                QueryOwnedAuctions()
            end
        end)
    elseif GetOwnerAuctionItems then
        GetOwnerAuctionItems()
    end
end

local function Debounced(key, func, sessionKey)
    local queue = sessionKey and state[sessionKey] or (not sessionKey and state)
    if not queue or queue[key] then return end
    queue[key] = true
    C_Timer.After(CAPTURE_DEBOUNCE, function()
        queue[key] = nil
        if not sessionKey or state[sessionKey] == queue then func(RoutineData) end
    end)
end

local function CaptureOpenBank()
    RoutineData:CaptureCharacterBank()
    RoutineData:CaptureWarbandBank()
end

local function QueueBankUpdate(bankType)
    local types = Enum and Enum.BankType
    if not types or bankType == nil or bankType == types.Character then
        Debounced("bank", RoutineData.CaptureCharacterBank, "bankOpen")
    end
    if not types or bankType == nil or bankType == types.Account then
        Debounced("warband", RoutineData.CaptureWarbandBank, "bankOpen")
    end
end

local function OpenGuildBank()
    if state.guildBankOpen then return end
    local session = {}
    state.guildBankOpen = session
    C_Timer.After(0.4, function()
        if state.guildBankOpen == session then RoutineData:CaptureGuildBank() end
    end)
end

local handlers = {
    PLAYER_ENTERING_WORLD = function(isInitialLogin, isReloadingUi)
        local captureEquipped = isInitialLogin or isReloadingUi or isInitialLogin == nil
        C_Timer.After(1, function()
            RoutineData:CaptureBags()
            if captureEquipped then RoutineData:CaptureEquipped() end
            RoutineData:RefreshCharacterGuild()
        end)
    end,
    PLAYER_EQUIPMENT_CHANGED = function(slot)
        if (tonumber(slot) or 0) > LastEquippedSlot() then return end
        Debounced("equipped", function() RoutineData:CaptureEquipped() end)
    end,
    UNIT_INVENTORY_CHANGED = function(unit)
        if unit ~= "player" or state.inventoryReady then return end
        state.inventoryReady = true
        Debounced("equipped", function() RoutineData:CaptureEquipped() end)
    end,
    PLAYER_GUILD_UPDATE = function(unit)
        if not unit or unit == "player" then RoutineData:RefreshCharacterGuild() end
    end,
    GUILD_ROSTER_UPDATE = function()
        RoutineData:RefreshCharacterGuild()
    end,
    BANKFRAME_OPENED = function()
        if state.bankOpen then return end
        local session = {}
        state.bankOpen = session
        C_Timer.After(0.3, function()
            if state.bankOpen == session then CaptureOpenBank() end
        end)
    end,
    BANKFRAME_CLOSED = function()
        state.bankOpen = nil
    end,
    BAG_UPDATE_DELAYED = function()
        Debounced("bags", RoutineData.CaptureBags)
        QueueBankUpdate()
    end,
    PLAYERBANKSLOTS_CHANGED = function()
        Debounced("bank", RoutineData.CaptureCharacterBank, "bankOpen")
    end,
    PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED = function()
        Debounced("warband", RoutineData.CaptureWarbandBank, "bankOpen")
    end,
    BANK_TABS_CHANGED = QueueBankUpdate,
    BANK_TAB_SETTINGS_UPDATED = QueueBankUpdate,
    MAIL_SHOW = function()
        state.mailOpen = state.mailOpen or {}
    end,
    MAIL_CLOSED = function()
        state.mailOpen = nil
    end,
    MAIL_INBOX_UPDATE = function()
        Debounced("mail", RoutineData.CaptureMail, "mailOpen")
    end,
    GUILDBANKFRAME_OPENED = function()
        OpenGuildBank()
    end,
    GUILDBANKFRAME_CLOSED = function()
        state.guildBankOpen = nil
    end,
    GUILDBANKBAGSLOTS_CHANGED = function()
        if state.guildBankOpen then RoutineData:CaptureGuildBank(true) end
    end,
    GUILDBANK_UPDATE_TABS = function()
        Debounced("guild", RoutineData.CaptureGuildBank, "guildBankOpen")
    end,
    AUCTION_HOUSE_SHOW = OpenAuctionHouse,
    AUCTION_HOUSE_CLOSED = function()
        state.auctionHouse = nil
    end,
    AUCTION_HOUSE_THROTTLED_SYSTEM_READY = QueryOwnedAuctions,
    OWNED_AUCTIONS_UPDATED = function()
        if state.auctionHouse and ModernAuctionHouse() then RoutineData:CaptureAuctions() end
    end,
    AUCTION_OWNED_LIST_UPDATE = function()
        if state.auctionHouse and not ModernAuctionHouse() then RoutineData:CaptureAuctions() end
    end,
    PLAYER_INTERACTION_MANAGER_FRAME_SHOW = function(interactionType)
        if Enum and Enum.PlayerInteractionType and interactionType == Enum.PlayerInteractionType.Auctioneer then
            OpenAuctionHouse()
        end
        if Enum and Enum.PlayerInteractionType and interactionType == Enum.PlayerInteractionType.GuildBanker then
            OpenGuildBank()
        end
    end,
    PLAYER_INTERACTION_MANAGER_FRAME_HIDE = function(interactionType)
        if Enum and Enum.PlayerInteractionType and interactionType == Enum.PlayerInteractionType.Auctioneer then
            state.auctionHouse = nil
        end
        if Enum and Enum.PlayerInteractionType and interactionType == Enum.PlayerInteractionType.GuildBanker then
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
