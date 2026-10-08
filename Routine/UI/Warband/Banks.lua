local _, ns = ...
if ns.Inactive then return end
local MR = ns.MR
local tracking = ns.Tracking
local Warband = assert(ns.WarbandBoardInternal, "UI/Warband/Shared.lua must load first")
local L = Warband.L
local GetWidgetCache = ns.GetWidgetCache
local HideUnusedWidgets = ns.HideUnusedWidgets
local SetOneAnchor = ns.SetOneAnchor
local BANK_CELL_SIZE = 43
local BANK_CELL_STRIDE = 46

tracking.RegisterCallback(MR, "BankSnapshotChanged", function(_, source)
    local frame = MR.altBoardFrame
    if frame and frame:IsShown() and frame.bankPane and frame.bankPane.bankSource == source
        and MR.db and MR.db.profile and MR.db.profile.altBoardView == "banks" then
        MR:RefreshAltBankPane(frame.bankPane)
    end
end)

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
    local store = MR:GetBankSnapshots()
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
    local store = MR:GetBankSnapshots()
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
