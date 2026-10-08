local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end
local L = LibStub("AceLocale-3.0"):GetLocale("RoutineData")
local API = RoutineData.API
local CharacterLabel = RoutineData.CharacterLabel

local function CharacterDetail(entry, settings)
    local parts = {}
    if settings.tooltipBags and entry.bags > 0 then
        parts[#parts + 1] = string.format("%s: %d", L["Tooltip_Bags"], entry.bags)
    end
    if settings.tooltipBank and entry.bank > 0 then
        parts[#parts + 1] = string.format("%s: %d", L["Tooltip_Bank"], entry.bank)
    end
    return table.concat(parts, "  ")
end

local function AddOwnerLines(tooltip, itemID)
    local settings = RoutineData.db.settings
    local counts = API.GetItemCounts(itemID)
    local lines = {}

    for _, entry in ipairs(counts.characters) do
        local detail = CharacterDetail(entry, settings)
        if detail ~= "" then
            lines[#lines + 1] = { CharacterLabel(entry.key, entry.classFile), detail }
        end
    end
    if settings.tooltipWarband and counts.warband > 0 then
        lines[#lines + 1] = { L["Tooltip_WarbandBank"], tostring(counts.warband) }
    end
    if settings.tooltipGuild then
        for _, guild in ipairs(counts.guilds) do
            lines[#lines + 1] = { string.format("<%s>", guild.name or guild.key), tostring(guild.count) }
        end
    end

    if #lines == 0 then return end
    tooltip:AddLine(" ")
    for _, line in ipairs(lines) do
        tooltip:AddDoubleLine(line[1], line[2], 1, 1, 1, 1, 1, 1)
    end
end

-- Addons that already add per-character item counts to tooltips. When one is
-- loaded we stay quiet by default so players don't see every count twice.
local INVENTORY_TOOLTIP_ADDONS = {
    "Syndicator", "Baganator", "Bagnon", "BagSync", "ArkInventory", "DataStore", "Altoholic",
}

local otherAddonLoaded
local function OtherInventoryAddonLoaded()
    if otherAddonLoaded == nil then
        otherAddonLoaded = false
        for _, name in ipairs(INVENTORY_TOOLTIP_ADDONS) do
            if C_AddOns.IsAddOnLoaded(name) then
                otherAddonLoaded = true
                break
            end
        end
    end
    return otherAddonLoaded
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
    if info and info.isAccountWide then return end

    local entries = API.GetCurrencyCounts(currencyID)
    if #entries == 0 then return end

    tooltip:AddLine(" ")
    local total = 0
    for _, entry in ipairs(entries) do
        local detail = BreakUpLargeNumbers and BreakUpLargeNumbers(entry.quantity) or tostring(entry.quantity)
        if entry.maxWeekly > 0 then
            detail = string.format(L["Tooltip_CurrencyWeekly"], detail, entry.weekly, entry.maxWeekly)
        end
        tooltip:AddDoubleLine(CharacterLabel(entry.key, entry.classFile), detail, 1, 1, 1, 1, 1, 1)
        total = total + entry.quantity
    end
    if #entries > 1 then
        tooltip:AddDoubleLine(L["Tooltip_Total"], BreakUpLargeNumbers and BreakUpLargeNumbers(total) or tostring(total), 0.7, 0.7, 0.7, 0.7, 0.7, 0.7)
    end
end

local function OnCurrencyTooltip(tooltip, data)
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip then return end
    if not (RoutineData.db and RoutineData.db.settings.tooltipCurrency) then return end
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
