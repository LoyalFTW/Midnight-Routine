local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end
local L = LibStub("AceLocale-3.0"):GetLocale("RoutineData")
local API = RoutineData.API
local CharacterLabel = RoutineData.CharacterLabel

local function FormatCount(value)
    return BreakUpLargeNumbers and BreakUpLargeNumbers(value) or tostring(value)
end

local function AddSection(tooltip, title, total)
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(title, total and FormatCount(total) or "", 0.35, 0.88, 0.78, 0.95, 0.85, 0.55)
end

local function SortOwners(entries)
    local current = API.GetCurrentCharacterKey()
    table.sort(entries, function(a, b)
        if (a.key == current) ~= (b.key == current) then return a.key == current end
        if a.total ~= b.total then return a.total > b.total end
        return a.key < b.key
    end)
    return current
end

local function OwnerLabel(entry, current)
    local label = CharacterLabel(entry.key, entry.classFile)
    if entry.key == current then
        label = label .. " |cff70ddbf" .. L["Tooltip_Current"] .. "|r"
    end
    return label
end

local function AddOwnerLines(tooltip, itemID)
    local settings = RoutineData.db.settings
    local counts = API.GetItemCounts(itemID)
    local entries = {}
    local bagTotal, bankTotal, mailTotal, equippedTotal = 0, 0, 0, 0

    for _, entry in ipairs(counts.characters) do
        entry.visibleBags = settings.tooltipBags and entry.bags or 0
        entry.visibleBank = settings.tooltipBank and entry.bank or 0
        entry.visibleMail = settings.tooltipMail and entry.mail or 0
        entry.visibleEquipped = settings.tooltipEquipped and entry.equipped or 0
        entry.total = entry.visibleBags + entry.visibleBank + entry.visibleMail + entry.visibleEquipped
        if entry.total > 0 and not RoutineData:IsCharacterHidden(entry.key) then
            entries[#entries + 1] = entry
            bagTotal = bagTotal + entry.visibleBags
            bankTotal = bankTotal + entry.visibleBank
            mailTotal = mailTotal + entry.visibleMail
            equippedTotal = equippedTotal + entry.visibleEquipped
        end
    end
    local warband = settings.tooltipWarband and counts.warband or 0
    local total = bagTotal + bankTotal + mailTotal + equippedTotal + warband
    if total > 0 then
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine(L["Tooltip_Inventory"], L["Tooltip_Total"] .. ": " .. FormatCount(total), 0.35, 0.88, 0.78, 0.95, 0.85, 0.55)
        local current = SortOwners(entries)
        local shown = RoutineData:GetTooltipCharacterLimit(#entries)
        for index = 1, shown do
            local entry = entries[index]
            local detail = {}
            if entry.visibleBags > 0 then detail[#detail + 1] = "|cffb5d7f3" .. L["Tooltip_Bags"] .. ": " .. FormatCount(entry.visibleBags) .. "|r" end
            if entry.visibleBank > 0 then detail[#detail + 1] = "|cffffd17a" .. L["Tooltip_Bank"] .. ": " .. FormatCount(entry.visibleBank) .. "|r" end
            if entry.visibleMail > 0 then detail[#detail + 1] = "|cffd9b8f5" .. L["Tooltip_Mail"] .. ": " .. FormatCount(entry.visibleMail) .. "|r" end
            if entry.visibleEquipped > 0 then detail[#detail + 1] = "|cff9ee6a0" .. L["Tooltip_Equipped"] .. ": " .. FormatCount(entry.visibleEquipped) .. "|r" end
            tooltip:AddDoubleLine(OwnerLabel(entry, current), table.concat(detail, "  |cff687582·|r  "), 0.90, 0.93, 0.96, 0.90, 0.93, 0.96)
        end
        if #entries > shown then
            tooltip:AddLine(string.format(L["Tooltip_MoreCharactersShift"], #entries - shown), 0.60, 0.68, 0.74, true)
        end
        if warband > 0 then
            tooltip:AddDoubleLine(L["Tooltip_WarbandBank"], FormatCount(warband), 0.35, 0.88, 0.78, 0.35, 0.88, 0.78)
        end
    end

    if settings.tooltipGuild and #counts.guilds > 0 then
        local guildTotal = 0
        for _, guild in ipairs(counts.guilds) do guildTotal = guildTotal + guild.count end
        AddSection(tooltip, L["Tooltip_GuildStorage"], guildTotal)
        for index = 1, math.min(#counts.guilds, 4) do
            local guild = counts.guilds[index]
            local name = guild.name or guild.key
            if guild.realm and guild.realm ~= GetRealmName() then name = name .. "-" .. guild.realm end
            tooltip:AddDoubleLine("<" .. name .. ">", FormatCount(guild.count), 0.72, 0.76, 0.90, 0.90, 0.93, 0.96)
        end
        if #counts.guilds > 4 then
            tooltip:AddLine(string.format(L["Tooltip_MoreGuilds"], #counts.guilds - 4), 0.60, 0.68, 0.74, true)
        end
    end
end
-- Addons that already add per-character item counts to tooltips. When one is
-- loaded we stay quiet by default so players don't see every count twice.
local INVENTORY_TOOLTIP_ADDONS = {
    "Syndicator", "Baganator", "Bagnon", "BagSync", "ArkInventory", "DataStore", "Altoholic",
}

local function OtherInventoryAddonLoaded()
    for _, name in ipairs(INVENTORY_TOOLTIP_ADDONS) do
        if C_AddOns.IsAddOnLoaded(name) then
            return true
        end
    end
    return false
end

function RoutineData:IsYieldingItemTooltips()
    return self.db.settings.tooltipYield and OtherInventoryAddonLoaded()
end

local function OnItemTooltip(tooltip, data)
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    if not (RoutineData.db and RoutineData.db.settings.tooltipItems) then return end
    if RoutineData:IsYieldingItemTooltips() then return end
    local itemID = data and data.id
    if type(itemID) ~= "number" or (issecretvalue and issecretvalue(itemID)) then return end
    -- A tooltip error must never break other addons' tooltips.
    pcall(AddOwnerLines, tooltip, itemID)
end

local function AddCurrencyLines(tooltip, currencyID)
    -- Account-wide currencies have the same balance everywhere, so per-character lines add nothing.
    local info = C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID)
    local function SafeNumber(value)
        if issecretvalue and issecretvalue(value) then return nil end
        return tonumber(value)
    end
    if info and info.isAccountWide then
        AddSection(tooltip, L["Tooltip_SharedBalance"], SafeNumber(info.quantity) or 0)
        return
    end

    local entries = {}
    for _, entry in ipairs(API.GetCurrencyCounts(currencyID)) do
        if not RoutineData:IsCharacterHidden(entry.key) then entries[#entries + 1] = entry end
    end
    local current = API.GetCurrentCharacterKey()
    local currentEntry
    for _, entry in ipairs(entries) do
        if entry.key == current then currentEntry = entry break end
    end
    local quantity = info and SafeNumber(info.quantity)
    if quantity and current and not RoutineData:IsCharacterHidden(current) then
        if not currentEntry then
            currentEntry = { key = current, classFile = API.GetCharacterClass(current) }
            entries[#entries + 1] = currentEntry
        end
        currentEntry.quantity = quantity
        currentEntry.weekly = SafeNumber(info.quantityEarnedThisWeek) or 0
        currentEntry.maxWeekly = SafeNumber(info.maxWeeklyQuantity) or 0
    end
    if #entries == 0 then return end

    local total = 0
    for _, entry in ipairs(entries) do
        entry.total = tonumber(entry.quantity) or 0
        total = total + entry.total
    end
    SortOwners(entries)
    AddSection(tooltip, L["Tooltip_CurrencyBalances"], total)
    local lastReset = RoutineData:GetLastWeeklyReset()
    local shown = RoutineData:GetTooltipCharacterLimit(#entries)
    for index = 1, shown do
        local entry = entries[index]
        tooltip:AddDoubleLine(OwnerLabel(entry, current), FormatCount(entry.total), 0.90, 0.93, 0.96, 0.90, 0.93, 0.96)
        if entry.maxWeekly > 0 then
            local record = RoutineData.db.characters[entry.key]
            local updated = record and record.updatedAt and record.updatedAt.currencies or 0
            if entry.key ~= current and updated < lastReset then
                tooltip:AddLine("  " .. L["Tooltip_WeeklyNeedsLogin"], 0.85, 0.66, 0.35, true)
            else
                local remaining = math.max(0, entry.maxWeekly - entry.weekly)
                local detail = string.format(L["Tooltip_WeeklyProgress"], FormatCount(entry.weekly), FormatCount(entry.maxWeekly), FormatCount(remaining))
                tooltip:AddLine("  " .. detail, remaining == 0 and 0.35 or 0.60, remaining == 0 and 0.88 or 0.68, remaining == 0 and 0.60 or 0.74, true)
            end
        end
    end
    if #entries > shown then
        tooltip:AddLine(string.format(L["Tooltip_MoreCharactersShift"], #entries - shown), 0.60, 0.68, 0.74, true)
    end
    local maximum = info and SafeNumber(info.maxQuantity)
    local capProgress = info and info.useTotalEarnedForMaxQty and SafeNumber(info.totalEarned) or quantity
    if maximum and maximum > 0 and capProgress then
        tooltip:AddDoubleLine(L["Tooltip_CurrentCap"], FormatCount(capProgress) .. " / " .. FormatCount(maximum), 0.60, 0.68, 0.74, 0.90, 0.93, 0.96)
        tooltip:AddLine(string.format(L["Tooltip_CapRemaining"], FormatCount(math.max(0, maximum - capProgress))), 0.60, 0.68, 0.74, true)
    end
    tooltip:AddLine(L["Tooltip_SavedCurrency"], 0.48, 0.55, 0.62, true)
end
function RoutineData:IsYieldingCurrencyTooltips()
    return self.db.settings.tooltipYield and OtherInventoryAddonLoaded()
end

local function OnCurrencyTooltip(tooltip, data)
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    if not (RoutineData.db and RoutineData.db.settings.tooltipCurrency) then return end
    if RoutineData:IsYieldingCurrencyTooltips() then return end
    local currencyID = data and data.id
    if type(currencyID) ~= "number" or (issecretvalue and issecretvalue(currencyID)) then return end
    pcall(AddCurrencyLines, tooltip, currencyID)
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, OnItemTooltip)
    if Enum.TooltipDataType.Currency then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Currency, OnCurrencyTooltip)
    end
end

local shiftWatcher = CreateFrame("Frame")
shiftWatcher:RegisterEvent("MODIFIER_STATE_CHANGED")
shiftWatcher:SetScript("OnEvent", function(_, _, key)
    if key ~= "LSHIFT" and key ~= "RSHIFT" then return end
    for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
        local data = tooltip:IsShown() and tooltip.GetTooltipData and tooltip:GetTooltipData()
        if data and Enum and Enum.TooltipDataType
            and (data.type == Enum.TooltipDataType.Item or data.type == Enum.TooltipDataType.Currency)
            and tooltip.RefreshData then
            tooltip:RefreshData()
        end
    end
end)