local _, ns = ...
local MR = ns.MR
local Warband = assert(ns.WarbandBoardInternal, "UI/Warband/Shared.lua must load first")
local L = Warband.L
local GetWidgetCache = ns.GetWidgetCache
local HideUnusedWidgets = ns.HideUnusedWidgets
local SetOneAnchor = ns.SetOneAnchor
local BANK_CELL_SIZE = 43
local BANK_CELL_STRIDE = 46

local function RefreshVisibleBankSource(source)
    local frame = MR.altBoardFrame
    if frame and frame:IsShown() and frame.bankPane and frame.bankPane.bankSource == source
        and MR.db and MR.db.profile and MR.db.profile.altBoardView == "banks" then
        MR:RefreshAltBankPane(frame.bankPane)
    end
end

local function Now()
    return (GetServerTime and GetServerTime()) or time()
end

local function Store()
    if not (MR.db and MR.db.global) then return nil end
    MR.db.global.altBankSnapshots = MR.db.global.altBankSnapshots or { characters = {}, bags = {}, characterGuilds = {}, characterGuildBanks = {} }
    local store = MR.db.global.altBankSnapshots
    store.characters = store.characters or {}
    store.bags = store.bags or {}
    store.characterGuilds = store.characterGuilds or {}
    store.characterGuildBanks = store.characterGuildBanks or {}
    return store
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

function MR:RefreshAltCharacterGuild()
    local store = Store()
    local charKey = self.GetCurrentCharacterKey and self:GetCurrentCharacterKey()
    if not store or not charKey then return end
    local _, _, guildKey = CurrentGuildIdentity()
    if guildKey then
        store.characterGuilds[charKey] = guildKey
    elseif IsInGuild and not IsInGuild() then
        store.characterGuilds[charKey] = false
    else
        return
    end
    RefreshVisibleBankSource("guild")
end

local function SnapshotContainer(bagID, label, icon)
    if not (C_Container and C_Container.GetContainerNumSlots and C_Container.GetContainerItemInfo) then return nil end
    local ok, slots = pcall(C_Container.GetContainerNumSlots, bagID)
    if not ok or type(slots) ~= "number" or slots <= 0 then return nil end
    local tab = { name = label, icon = icon, slots = slots, items = {} }
    for slot = 1, slots do
        local success, info = pcall(C_Container.GetContainerItemInfo, bagID, slot)
        if success and info and info.itemID then
            local link = info.hyperlink
            local name = (link and link:match("%[(.-)%]")) or (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(info.itemID))
            tab.items[slot] = {
                id = info.itemID,
                link = link,
                name = name,
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

local function CollectBags()
    local bagIndex = Enum and Enum.BagIndex or {}
    local tabs = {}
    local backpack = SnapshotContainer(bagIndex.Backpack or 0, L["AltBoard_BankBackpack"] or "Backpack")
    if backpack then tabs[#tabs + 1] = backpack end
    for index = 1, 5 do
        local bagID = bagIndex["Bag_" .. index] or index
        local tab = SnapshotContainer(bagID, string.format(L["AltBoard_BagSlot"] or "Bag %d", index))
        if tab then tabs[#tabs + 1] = tab end
    end
    return tabs
end

local function CollectCharacterBank()
    local bagIndex = Enum and Enum.BagIndex or {}
    local tabs = {}
    if not bagIndex.CharacterBankTab_1 then
        local bank = SnapshotContainer(bagIndex.Bank or -1, L["AltBoard_BankMain"] or "Bank")
        if bank then tabs[#tabs + 1] = bank end
        for index = 1, 7 do
            local bagID = NUM_BAG_SLOTS and (NUM_BAG_SLOTS + index)
            if bagID then
                local tab = SnapshotContainer(bagID, string.format(L["AltBoard_BankBag"] or "Bank bag %d", index))
                if tab then tabs[#tabs + 1] = tab end
            end
        end
    else
        local metadata = BankMetadata(Enum and Enum.BankType and Enum.BankType.Character)
        for index = 1, 9 do
            local bagID = bagIndex["CharacterBankTab_" .. index]
            if bagID then
                local info = metadata and metadata[index]
                local tab = SnapshotContainer(bagID, (info and info.name) or string.format(L["AltBoard_BankTab"] or "Tab %d", index), info and info.icon)
                if tab then tabs[#tabs + 1] = tab end
            end
        end
    end
    return tabs
end

local function CollectWarbandBank()
    if MR.isForever or not (Enum and Enum.BagIndex and Enum.BankType and Enum.BankType.Account and C_Bank) then return nil end
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
            local tab = SnapshotContainer(bagID, (info and info.name) or string.format(L["AltBoard_BankTab"] or "Tab %d", index), info and info.icon)
            if tab then tabs[#tabs + 1] = tab end
        end
    end
    return tabs
end

function MR:CaptureAltBank(source)
    local store = Store()
    if not store then return end
    local tabs
    if source == "character" then
        tabs = CollectCharacterBank()
        if #tabs == 0 then return end
        local key = self:GetCurrentCharacterKey()
        if not key then return end
        store.characters[key] = { tabs = tabs, updatedAt = Now() }
    elseif source == "warband" then
        tabs = CollectWarbandBank()
        if not tabs or #tabs == 0 then return end
        store.warband = { tabs = tabs, updatedAt = Now() }
    end
    RefreshVisibleBankSource(source)
end

function MR:CaptureAltBags()
    local store = Store()
    if not store then return end
    local tabs = CollectBags()
    if #tabs == 0 then return end
    local key = self:GetCurrentCharacterKey()
    if not key then return end
    store.bags[key] = { tabs = tabs, updatedAt = Now() }
    RefreshVisibleBankSource("bags")
end

function MR:CaptureAltGuildBank()
    local store = Store()
    if not store or not (GetGuildInfo and GetNumGuildBankTabs and GetGuildBankTabInfo and GetGuildBankItemInfo) then return end
    local guildName, realm, guildKey = CurrentGuildIdentity()
    local charKey = self:GetCurrentCharacterKey()
    if not guildKey or not charKey then return end
    store.characterGuilds[charKey] = guildKey
    local snapshot = store.characterGuildBanks[charKey]
    if not snapshot or snapshot.guildKey ~= guildKey then snapshot = { tabs = {}, guildKey = guildKey } end
    snapshot.name = guildName
    snapshot.realm = realm
    snapshot.money = GetGuildBankMoney and GetGuildBankMoney() or snapshot.money
    local numTabs = GetNumGuildBankTabs() or 0
    if numTabs == 0 then
        RefreshVisibleBankSource("guild")
        return
    end
    snapshot.numTabs = numTabs
    local currentTab = GetCurrentGuildBankTab and GetCurrentGuildBankTab()
    for index = 1, numTabs do
        local name, icon, canView = GetGuildBankTabInfo(index)
        if canView then
            local old = snapshot.tabs[index]
            if index == currentTab then
                local tab = { name = name or string.format(L["AltBoard_BankTab"] or "Tab %d", index), icon = icon, slots = 98, items = {} }
                for slot = 1, 98 do
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
            elseif not old then
                snapshot.tabs[index] = { name = name or string.format(L["AltBoard_BankTab"] or "Tab %d", index), icon = icon, slots = 98, items = {}, uncaptured = true }
            else
                old.name = name or old.name
                old.icon = icon or old.icon
            end
        else
            snapshot.tabs[index] = nil
        end
    end
    snapshot.updatedAt = Now()
    store.characterGuildBanks[charKey] = snapshot
    RefreshVisibleBankSource("guild")
end

function MR:EnableAltBankTracking()
    local function RegisterIfValid(event, callback)
        if not (C_EventUtils and C_EventUtils.IsEventValid) or C_EventUtils.IsEventValid(event) then
            MR:RegisterEvent(event, callback)
        end
    end
    local function CaptureOpenBank()
        MR._altBankOpen = true
        C_Timer.After(0.3, function()
            if MR._altBankOpen then
                MR:CaptureAltBank("character")
                if not MR.isForever then MR:CaptureAltBank("warband") end
            end
        end)
    end
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        C_Timer.After(1, function()
            MR:CaptureAltBags()
            MR:RefreshAltCharacterGuild()
        end)
    end)
    RegisterIfValid("PLAYER_GUILD_UPDATE", function(_, unit)
        if not unit or unit == "player" then MR:RefreshAltCharacterGuild() end
    end)
    RegisterIfValid("GUILD_ROSTER_UPDATE", function() MR:RefreshAltCharacterGuild() end)
    self:RegisterEvent("BANKFRAME_OPENED", CaptureOpenBank)
    self:RegisterEvent("BANKFRAME_CLOSED", function() MR._altBankOpen = nil end)
    self:RegisterEvent("BAG_UPDATE_DELAYED", function()
        MR:CaptureAltBags()
        if MR._altBankOpen then
            MR:CaptureAltBank("character")
            if not MR.isForever then MR:CaptureAltBank("warband") end
        end
    end)
    RegisterIfValid("PLAYERBANKSLOTS_CHANGED", function()
        if MR._altBankOpen then MR:CaptureAltBank("character") end
    end)
    if not self.isForever then
        RegisterIfValid("PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED", function()
            if MR._altBankOpen then MR:CaptureAltBank("warband") end
        end)
    end
    local function OpenGuildBank()
        MR._altGuildBankOpen = true
        C_Timer.After(0.4, function()
            if MR._altGuildBankOpen then MR:CaptureAltGuildBank() end
        end)
    end
    if Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.GuildBanker then
        self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, interactionType)
            if interactionType == Enum.PlayerInteractionType.GuildBanker then OpenGuildBank() end
        end)
        self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, interactionType)
            if interactionType == Enum.PlayerInteractionType.GuildBanker then MR._altGuildBankOpen = nil end
        end)
    else
        RegisterIfValid("GUILDBANKFRAME_OPENED", OpenGuildBank)
        RegisterIfValid("GUILDBANKFRAME_CLOSED", function() MR._altGuildBankOpen = nil end)
    end
    RegisterIfValid("GUILDBANKBAGSLOTS_CHANGED", function()
        if MR._altGuildBankOpen then MR:CaptureAltGuildBank() end
    end)
    RegisterIfValid("GUILDBANK_UPDATE_TABS", function()
        if MR._altGuildBankOpen then MR:CaptureAltGuildBank() end
    end)
    RegisterIfValid("GUILDBANK_UPDATE_MONEY", function()
        if MR._altGuildBankOpen then MR:CaptureAltGuildBank() end
    end)
end

local function MakeSourceButton(parent, label, key, index)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(120, 24)
    button:SetBackdrop(ns.MakeBackdrop())
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 12 + (index - 1) * 126, -12)
    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont(ns.FONT_ROWS, math.max(9, Warband.GetFontSize() - 1), Warband.GetFontFlags())
    text:SetPoint("LEFT", button, "LEFT", 4, 0)
    text:SetPoint("RIGHT", button, "RIGHT", -4, 0)
    text:SetHeight(22)
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")
    text:SetText(label)
    button._label = text
    button:SetScript("OnClick", function()
        parent.bankSource = key
        MR:RefreshWarbandBoardSelection()
    end)
    return button
end

function MR:CreateAltBankPane(frame, rightPane, tabBar)
    local pane = CreateFrame("Frame", nil, rightPane, "BackdropTemplate")
    pane:SetPoint("TOPLEFT", tabBar, "BOTTOMLEFT", 0, -12)
    pane:SetPoint("BOTTOMRIGHT", rightPane, "BOTTOMRIGHT", -10, 10)
    pane:SetBackdrop(ns.MakeBackdrop())
    Warband.WBApplySurface(pane, "soft")
    pane:Hide()
    pane.bankSource = "character"
    pane.sourceButtons = {}
    pane.sourceOrder = { "bags", "character" }
    local bags = MakeSourceButton(pane, L["AltBoard_BankBags"] or "Bags", "bags", 1)
    pane.sourceButtons.bags = bags
    local character = MakeSourceButton(pane, L["AltBoard_BankCharacter"] or "Character bank", "character", 2)
    pane.sourceButtons.character = character
    if not self.isForever then
        local warband = MakeSourceButton(pane, L["AltBoard_BankWarband"] or "Warband bank", "warband", 3)
        pane.sourceButtons.warband = warband
        pane.sourceOrder[#pane.sourceOrder + 1] = "warband"
        pane.sourceButtons.guild = MakeSourceButton(pane, L["AltBoard_BankGuild"] or "Guild bank", "guild", 4)
    else
        pane.sourceButtons.guild = MakeSourceButton(pane, L["AltBoard_BankGuild"] or "Guild bank", "guild", 3)
    end
    pane.sourceOrder[#pane.sourceOrder + 1] = "guild"
    local search = CreateFrame("EditBox", nil, pane, "BackdropTemplate")
    search:SetSize(190, 24)
    search:SetPoint("TOPLEFT", pane, "TOPLEFT", 12, -48)
    search:SetBackdrop(ns.MakeBackdrop())
    search:SetBackdropColor(0.01, 0.018, 0.03, 0.94)
    search:SetBackdropBorderColor(0.08, 0.14, 0.20, 0.72)
    search:SetFont(ns.FONT_ROWS, math.max(9, Warband.GetFontSize() - 1), Warband.GetFontFlags())
    search:SetTextInsets(9, 9, 0, 0)
    search:SetTextColor(0.9, 0.95, 1)
    search:SetAutoFocus(false)
    search:SetScript("OnTextChanged", function() MR:RefreshAltBankPane(pane) end)
    search:SetScript("OnEscapePressed", function(selfBox) selfBox:ClearFocus() end)
    pane.search = search
    local searchHint = pane:CreateFontString(nil, "OVERLAY")
    searchHint:SetFont(ns.FONT_ROWS, math.max(8, Warband.GetFontSize() - 2), Warband.GetFontFlags())
    searchHint:SetPoint("LEFT", search, "RIGHT", 9, 0)
    searchHint:SetText(L["AltBoard_BankSearch"] or "Search items")
    ns.RegisterThemedFontString(searchHint, 0.55, 0.69, 0.74)
    local heading = pane:CreateFontString(nil, "OVERLAY")
    heading:SetFont(ns.FONT_HEADERS, math.max(10, Warband.GetFontSize()), Warband.GetFontFlags())
    heading:SetPoint("TOPLEFT", search, "BOTTOMLEFT", 0, -12)
    heading:SetPoint("RIGHT", pane, "RIGHT", -12, 0)
    heading:SetJustifyH("LEFT")
    ns.RegisterThemedFontString(heading, 0.90, 0.95, 1.00)
    pane.heading = heading
    local scroll, content, update = Warband.WBCreateScrollArea(pane,
        { "TOPLEFT", heading, "BOTTOMLEFT", 0, -10 },
        { "BOTTOMRIGHT", pane, "BOTTOMRIGHT", -12, 10 })
    content:SetSize(490, 1)
    pane.scroll = scroll
    pane.content = content
    pane.update = update
    pane.headers = GetWidgetCache(pane, "headers")
    pane.cells = GetWidgetCache(pane, "cells")
    frame.bankPane = pane
end

local function GetSnapshot(pane, selected)
    local store = Store()
    if not store then return nil end
    if pane.bankSource == "warband" then return store.warband end
    if pane.bankSource == "guild" then
        local guildKey = selected and store.characterGuilds[selected.key]
        local snapshot = selected and store.characterGuildBanks[selected.key]
        if type(guildKey) ~= "string" or not snapshot or snapshot.guildKey ~= guildKey then return nil end
        return snapshot
    end
    if pane.bankSource == "bags" then return selected and store.bags and store.bags[selected.key] or nil end
    return selected and store.characters[selected.key] or nil
end

local function EnsureHeader(pane, index)
    local headers = GetWidgetCache(pane, "headers")
    local header = headers[index]
    if header then return header end
    header = CreateFrame("Frame", nil, pane.content, "BackdropTemplate")
    header:SetBackdrop(ns.MakeBackdrop())
    Warband.WBApplySurface(header, "soft")
    header.icon = header:CreateTexture(nil, "ARTWORK")
    header.icon:SetSize(20, 20)
    header.icon:SetPoint("LEFT", 8, 0)
    header.text = header:CreateFontString(nil, "OVERLAY")
    header.text:SetFont(ns.FONT_HEADERS, math.max(9, Warband.GetFontSize()), Warband.GetFontFlags())
    header.text:SetPoint("LEFT", header.icon, "RIGHT", 8, 0)
    header.text:SetJustifyH("LEFT")
    ns.RegisterThemedFontString(header.text, 0.90, 0.95, 1.00)
    header.count = header:CreateFontString(nil, "OVERLAY")
    header.count:SetFont(ns.FONT_ROWS, math.max(8, Warband.GetFontSize() - 2), Warband.GetFontFlags())
    header.count:SetPoint("RIGHT", -8, 0)
    ns.RegisterThemedFontString(header.count, 0.57, 0.73, 0.77)
    headers[index] = header
    return header
end

local function EnsureCell(pane, index)
    local cells = GetWidgetCache(pane, "cells")
    local cell = cells[index]
    if cell then return cell end
    cell = CreateFrame("Button", nil, pane.content, "BackdropTemplate")
    cell:SetSize(BANK_CELL_SIZE, BANK_CELL_SIZE)
    cell:SetBackdrop(ns.MakeBackdrop())
    cell:SetBackdropColor(0.02, 0.04, 0.06, 0.95)
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetPoint("TOPLEFT", 2, -2)
    cell.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    cell.count = cell:CreateFontString(nil, "OVERLAY")
    cell.count:SetFont(ns.FONT_ROWS, 9, "OUTLINE")
    cell.count:SetPoint("BOTTOMRIGHT", -3, 3)
    cell:SetScript("OnEnter", function(selfCell)
        local item = selfCell.item
        if not item then return end
        ns.ShowTooltip(selfCell, {
            build = function(tooltip)
                if item.link then tooltip:SetHyperlink(item.link)
                elseif item.id then tooltip:SetItemByID(item.id)
                else tooltip:SetText(item.name or "") end
            end,
        })
    end)
    cell:SetScript("OnLeave", function(selfCell) ns.HideOwnedTooltip(selfCell) end)
    cell:SetScript("OnClick", function(selfCell)
        if selfCell.item and selfCell.item.link and IsModifiedClick and IsModifiedClick("CHATLINK") then
            HandleModifiedItemClick(selfCell.item.link)
        end
    end)
    cells[index] = cell
    return cell
end

function MR:ResetAltBankPane(pane)
    if not pane then return end
    HideUnusedWidgets(pane.headers, 0)
    HideUnusedWidgets(pane.cells, 0, function(cell)
        cell.item = nil
        ns.HideOwnedTooltip(cell)
    end)
end

function MR:RefreshAltBankPane(pane, selected)
    if not pane then return end
    if not selected and self.altBoardFrame then
        local data = self.altBoardFrame._data or {}
        for _, entry in ipairs(data) do
            if entry.key == self.altBoardFrame.selectedCharKey then selected = entry break end
        end
    end
    if self.isForever and pane.bankSource == "warband" then pane.bankSource = "character" end
    local sourceWidth = math.max(80, math.floor(((pane:GetWidth() > 0 and pane:GetWidth() or 540) - 24 - (#pane.sourceOrder - 1) * 6) / #pane.sourceOrder))
    for index, key in ipairs(pane.sourceOrder) do
        local button = pane.sourceButtons[key]
        button:SetWidth(sourceWidth)
        SetOneAnchor(button, "TOPLEFT", pane, "TOPLEFT", 12 + (index - 1) * (sourceWidth + 6), -12)
        Warband.WBStylePillButton(button, key == pane.bankSource)
    end
    local store = Store()
    local guildState = selected and store and store.characterGuilds[selected.key]
    local guildName = type(guildState) == "string" and guildState:match(":(.+)$")
    local snapshot = GetSnapshot(pane, selected)
    local name = pane.bankSource == "bags" and (selected and string.format(L["AltBoard_BagOwner"] or "%s's bags", selected.name) or (L["AltBoard_BankBags"] or "Bags"))
        or pane.bankSource == "character" and (selected and selected.name or (L["AltBoard_Characters"] or "Character"))
        or pane.bankSource == "guild" and (selected and (selected.name .. "  |  " .. (guildName or (guildState == false and (L["AltBoard_GuildNone"] or "No guild") or (L["AltBoard_GuildUnknown"] or "Guild not recorded")))) or (L["AltBoard_BankGuild"] or "Guild bank"))
        or (L["AltBoard_BankWarband"] or "Warband bank")
    local updated = snapshot and snapshot.updatedAt and Warband.WBFormatTimestamp(snapshot.updatedAt)
    local money = pane.bankSource == "warband" and self.db and self.db.global and self.db.global.warbandGold
        or pane.bankSource == "guild" and snapshot and snapshot.money
    local moneyText = money and Warband.WBFormatMoney(money)
    pane.heading:SetText(name .. (moneyText and moneyText ~= "" and ("  |cffd7b85d|  " .. moneyText .. "|r") or "")
        .. (updated and ("  |cff728892|  " .. updated .. "|r") or ""))
    local query = (pane.search:GetText() or ""):lower()
    local headerIndex, cellIndex, y = 0, 0, 0
    local contentWidth = math.max(490, pane.scroll:GetWidth() - 18)
    local columns = math.max(1, math.floor((contentWidth - 4) / BANK_CELL_STRIDE))
    pane.content:SetWidth(contentWidth)
    for tabIndex = 1, snapshot and (snapshot.numTabs or #snapshot.tabs) or 0 do
        local tab = snapshot.tabs[tabIndex]
        if tab then
            local items = {}
            local occupied = 0
            for slot = 1, tab.slots or 0 do
                local item = tab.items and tab.items[slot]
                if item then
                    occupied = occupied + 1
                    local itemName = (item.name or (item.id and GetItemInfo and GetItemInfo(item.id)) or ""):lower()
                    if query == "" or itemName:find(query, 1, true) then items[#items + 1] = item end
                end
            end
            if query == "" or #items > 0 then
                headerIndex = headerIndex + 1
                local header = EnsureHeader(pane, headerIndex)
                SetOneAnchor(header, "TOPLEFT", pane.content, "TOPLEFT", 0, -y)
                header:SetWidth(contentWidth)
                header:SetHeight(30)
                header.icon:SetTexture(tab.icon or "Interface\\Icons\\INV_Misc_Bag_10")
                header.text:SetText(tab.name or "Bank")
                header.count:SetText(tab.uncaptured and (L["AltBoard_BankNotVisited"] or "Visit this tab to capture") or (occupied .. " / " .. (tab.slots or 0)))
                header:Show()
                y = y + 37
                for index, item in ipairs(items) do
                    cellIndex = cellIndex + 1
                    local cell = EnsureCell(pane, cellIndex)
                    SetOneAnchor(cell, "TOPLEFT", pane.content, "TOPLEFT", ((index - 1) % columns) * BANK_CELL_STRIDE + 2, -y - math.floor((index - 1) / columns) * BANK_CELL_STRIDE)
                    cell.item = item
                    cell.icon:SetTexture(item.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
                    cell.count:SetText((item.count or 1) > 1 and item.count or "")
                    local color = item.quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[item.quality]
                    cell:SetBackdropBorderColor(color and color.r or 0.12, color and color.g or 0.22, color and color.b or 0.28, 0.9)
                    cell:Show()
                end
                y = y + math.max(1, math.ceil(#items / columns)) * BANK_CELL_STRIDE + 10
            end
        end
    end
    HideUnusedWidgets(pane.headers, headerIndex)
    HideUnusedWidgets(pane.cells, cellIndex, function(cell)
        cell.item = nil
        ns.HideOwnedTooltip(cell)
    end)
    if headerIndex == 0 then
        headerIndex = 1
        local header = EnsureHeader(pane, headerIndex)
        SetOneAnchor(header, "TOPLEFT", pane.content, "TOPLEFT", 0, 0)
        header:SetWidth(contentWidth)
        header:SetHeight(40)
        header.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
        local emptyText
        if query ~= "" then
            emptyText = L["AltBoard_BankNoMatches"] or "No matching items"
        elseif pane.bankSource == "guild" then
            if not selected then
                emptyText = L["AltBoard_BankSelectCharacter"] or "Select a character"
            elseif guildState == false then
                emptyText = L["AltBoard_GuildNone"] or "No guild"
            elseif not guildState then
                emptyText = L["AltBoard_GuildRecordPrompt"] or "Log into this character to record their guild"
            else
                emptyText = L["AltBoard_GuildVisitPrompt"] or "Visit this character's guild bank to save its contents"
            end
        elseif pane.bankSource == "bags" then
            emptyText = L["AltBoard_BagLoginPrompt"] or "Log into this character to save their bags"
        else
            emptyText = L["AltBoard_BankVisitPrompt"] or "Visit this bank to save its contents"
        end
        header.text:SetText(emptyText)
        header.count:SetText("")
        header:Show()
        y = 44
    end
    pane.content:SetHeight(math.max(y, 1))
    pane.update()
end
