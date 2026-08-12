local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")
local crestRows
local defaultCrestRows

local function CleanLabel(text)
    text = tostring(text or "")
    return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub(":$", "")
end

local function PlainLabel(text, default)
    local value = text or default or ""
    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub(":$","")
    if value == "" then
        return default or ""
    end
    return value
end

local function ItemLabel(itemID, fallback, color)
    local itemName = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    return string.format("|cff%s%s:|r", color or "e8c96e", itemName or fallback or ("Item " .. tostring(itemID)))
end

local function CurrencyLabel(currencyID, fallback, color)
    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID)
    local currencyName = info and info.name
    return string.format("|cff%s%s:|r", color or "e8c96e", currencyName or fallback or ("Currency " .. tostring(currencyID)))
end

local function IsCurrencyDiscovered(currencyID)
    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info then
        return false
    end

    return info.discovered == true
        or (tonumber(info.quantity) or 0) > 0
        or (tonumber(info.quantityEarnedThisWeek) or 0) > 0
        or (tonumber(info.totalEarned) or 0) > 0
end

local function RefreshCrestItemLabels()
    if not crestRows then return end
    local dirty = false
    for _, row in ipairs(crestRows) do
        if row.itemId then
            local nextLabel = ItemLabel(row.itemId, row.fallbackLabel, row.labelColorHex)
            if row.label ~= nextLabel then
                row.label = nextLabel
                dirty = true
            end
        end
    end
    if dirty then
        if MR.RequestUIRefresh then
            MR:RequestUIRefresh(0.05)
        elseif MR.RefreshUI then
            MR:RefreshUI()
        end
    end
end

local function GetCurrencyStorage()
    if not (MR and MR.db and MR.db.char) then
        return nil, nil, nil
    end

    MR.db.char.currencyBrowserHiddenDefaults = MR.db.char.currencyBrowserHiddenDefaults or {}
    MR.db.char.currencyBrowserCustom = MR.db.char.currencyBrowserCustom or {}
    MR.db.char.currencyBrowserCustomOrder = MR.db.char.currencyBrowserCustomOrder or {}
    return MR.db.char.currencyBrowserHiddenDefaults, MR.db.char.currencyBrowserCustom, MR.db.char.currencyBrowserCustomOrder
end

local function RemoveCurrencyProgress(currencyID, rowKey)
    if not (MR and MR.db and MR.db.char) then
        return
    end

    local progress = MR.db.char.progress and MR.db.char.progress.currencies
    if progress and rowKey then
        progress[rowKey] = nil
        progress[rowKey .. "_wallet"] = nil
        progress[rowKey .. "_collected"] = nil
    end

    local overrides = MR.db.char.manualOverrides and MR.db.char.manualOverrides.currencies
    if overrides and rowKey then
        overrides[rowKey] = nil
    end
end

local function BuildCustomCurrencyRow(currencyID, saved)
    local fallbackName = type(saved) == "table" and saved.name or nil
    return {
        key = "custom_currency_" .. tostring(currencyID),
        currencyId = currencyID,
        noMax = true,
        removableCurrency = true,
        customCurrency = true,
        label = CurrencyLabel(currencyID, fallbackName),
        note = L["CurrencyBrowser_CustomNote"] or "Added from the Blizzard currency browser.",
        tooltipFunc = function(tip)
            tip:AddLine(" ")
            tip:AddLine(L["CurrencyBrowser_RemoveHint"] or "Shift-right-click to remove from Currencies and return it to the browser.", 1, 0.72, 0.45, true)
        end,
        onRightClick = function()
            if IsShiftKeyDown() and MR.RemoveCurrencyFromCurrencies then
                MR:RemoveCurrencyFromCurrencies(currencyID)
                return true
            end
            return false
        end,
    }
end

local function CopyDefaultCurrencyRow(row)
    local copy = {}
    for key, value in pairs(row) do
        copy[key] = value
    end
    if row.currencyId then
        copy.removableCurrency = true
        copy.tooltipFunc = function(tip)
            tip:AddLine(" ")
            tip:AddLine(L["CurrencyBrowser_RemoveHint"] or "Shift-right-click to remove from Currencies and return it to the browser.", 1, 0.72, 0.45, true)
        end
        copy.onRightClick = function()
            if IsShiftKeyDown() and MR.RemoveCurrencyFromCurrencies then
                MR:RemoveCurrencyFromCurrencies(row.currencyId)
                return true
            end
            return false
        end
    end
    return copy
end

function MR:IsCurrencyInCurrenciesModule(currencyID)
    currencyID = tonumber(currencyID)
    if not currencyID then
        return false
    end

    local hiddenDefaults, custom = GetCurrencyStorage()
    custom = custom or {}
    if custom[currencyID] then
        return true
    end

    for _, row in ipairs(defaultCrestRows or {}) do
        if tonumber(row.currencyId) == currencyID then
            return not (hiddenDefaults and hiddenDefaults[currencyID])
        end
    end

    return false
end

function MR:RefreshCurrenciesModule(refreshUI)
    if not crestRows then
        return false
    end

    local hiddenDefaults, custom, customOrder = GetCurrencyStorage()
    local previousCount = #crestRows
    wipe(crestRows)

    for _, row in ipairs(defaultCrestRows or {}) do
        if row.currencyId and custom and custom[row.currencyId] then
            custom[row.currencyId] = nil
            RemoveCurrencyProgress(row.currencyId, "custom_currency_" .. tostring(row.currencyId))
        end
        if not (row.currencyId and hiddenDefaults and hiddenDefaults[row.currencyId]) then
            crestRows[#crestRows + 1] = CopyDefaultCurrencyRow(row)
        end
    end

    if custom and customOrder then
        local seen = {}
        for index = #customOrder, 1, -1 do
            local currencyID = tonumber(customOrder[index])
            if not currencyID or not custom[currencyID] or seen[currencyID] then
                table.remove(customOrder, index)
            else
                seen[currencyID] = true
            end
        end

        for _, currencyID in ipairs(customOrder) do
            if custom[currencyID] then
                crestRows[#crestRows + 1] = BuildCustomCurrencyRow(currencyID, custom[currencyID])
            end
        end
    end

    RefreshCrestItemLabels()
    MR._moduleStatsCache = nil
    if refreshUI ~= false and MR.RefreshUI then
        MR:RefreshUI()
    end
    return previousCount ~= #crestRows
end

function MR:AddCurrencyToCurrencies(currencyID)
    currencyID = tonumber(currencyID)
    if not currencyID then
        return false
    end

    local hiddenDefaults, custom, customOrder = GetCurrencyStorage()
    if not hiddenDefaults or not custom or not customOrder then
        return false
    end

    for _, row in ipairs(defaultCrestRows or {}) do
        if tonumber(row.currencyId) == currencyID then
            hiddenDefaults[currencyID] = nil
            self:RefreshCurrenciesModule(false)
            self:RefreshCurrencyProgress(currencyID, false)
            if self.RefreshCurrencyBrowserFrame then self:RefreshCurrencyBrowserFrame() end
            if self.RefreshUI then self:RefreshUI() end
            print(string.format(L["CurrencyBrowser_AddedMessage"] or "|cff2ae7c6MidnightRoutine:|r Added %s to Currencies.", CleanLabel(CurrencyLabel(currencyID))))
            return true
        end
    end

    if custom[currencyID] then
        return false
    end

    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID)
    custom[currencyID] = {
        name = CleanLabel((info and info.name) or ("Currency " .. tostring(currencyID))),
    }
    customOrder[#customOrder + 1] = currencyID

    self:RefreshCurrenciesModule(false)
    self:RefreshCurrencyProgress(currencyID, false)
    if self.RefreshCurrencyBrowserFrame then self:RefreshCurrencyBrowserFrame() end
    if self.RefreshUI then self:RefreshUI() end
    print(string.format(L["CurrencyBrowser_AddedMessage"] or "|cff2ae7c6MidnightRoutine:|r Added %s to Currencies.", custom[currencyID].name))
    return true
end

function MR:RemoveCurrencyFromCurrencies(currencyID)
    currencyID = tonumber(currencyID)
    if not currencyID then
        return false
    end

    local hiddenDefaults, custom, customOrder = GetCurrencyStorage()
    if not hiddenDefaults or not custom or not customOrder then
        return false
    end

    local removed = false
    local removedName
    if custom[currencyID] then
        removedName = custom[currencyID].name
        custom[currencyID] = nil
        for index = #customOrder, 1, -1 do
            if tonumber(customOrder[index]) == currencyID then
                table.remove(customOrder, index)
            end
        end
        RemoveCurrencyProgress(currencyID, "custom_currency_" .. tostring(currencyID))
        removed = true
    else
        for _, row in ipairs(defaultCrestRows or {}) do
            if tonumber(row.currencyId) == currencyID then
                hiddenDefaults[currencyID] = true
                removedName = CleanLabel(CurrencyLabel(currencyID))
                RemoveCurrencyProgress(currencyID, row.key)
                removed = true
                break
            end
        end
    end

    if not removed then
        return false
    end

    self:RefreshCurrenciesModule(false)
    if self.RefreshCurrencyBrowserFrame then self:RefreshCurrencyBrowserFrame() end
    if self.RefreshUI then self:RefreshUI() end
    print(string.format(L["CurrencyBrowser_RemovedMessage"] or "|cff2ae7c6MidnightRoutine:|r Removed %s from Currencies.", removedName or ("Currency " .. tostring(currencyID))))
    return true
end

defaultCrestRows = {
    {
        key = "mistcrest_adventurer",
        currencyId = 3442,
        noMax = true,
        isVisible = function() return IsCurrencyDiscovered(3442) end,
        label = CurrencyLabel(3442, "Adventurer Mistcrest", "b7b7b7"),
    },
    {
        key = "mistcrest_veteran",
        currencyId = 3443,
        noMax = true,
        isVisible = function() return IsCurrencyDiscovered(3443) end,
        label = CurrencyLabel(3443, "Veteran Mistcrest", "1eff00"),
    },
    {
        key = "mistcrest_champion",
        currencyId = 3444,
        noMax = true,
        isVisible = function() return IsCurrencyDiscovered(3444) end,
        label = CurrencyLabel(3444, "Champion Mistcrest", "f1c232"),
    },
    {
        key = "mistcrest_hero",
        currencyId = 3445,
        noMax = true,
        isVisible = function() return IsCurrencyDiscovered(3445) end,
        label = CurrencyLabel(3445, "Hero Mistcrest", "0070dd"),
    },
    {
        key = "mistcrest_myth",
        currencyId = 3446,
        noMax = true,
        isVisible = function() return IsCurrencyDiscovered(3446) end,
        label = CurrencyLabel(3446, "Myth Mistcrest", "ff8000"),
    },
	{
		key = "field_accolade",
		currencyId = 3405,
		noMax = true,
        label = CurrencyLabel(3405, nil),
	},
    {
        key = "manaflux",
        currencyId = 3378,
        noMax = true,
        label = CurrencyLabel(3378, nil),
    },
    {
        key = "untainted_mana_crystals",
        currencyId = 3356,
        noMax = true,
        label = CurrencyLabel(3356, nil),
    },
    {
        key = "voidlight_marl",
        currencyId = 3316,
        noMax = true,
        label = CurrencyLabel(3316, nil),
    },
    {
        key = "shards",
        currencyId = 3310,
        max = 600,
        label = CurrencyLabel(3310, nil),
    },
    {
        key = "restored_coffer_key",
        currencyId = 3028,
        noMax = true,
        label = CurrencyLabel(3028),
    },
    {
        key = "spark_radiance",
        itemId = 232875,
        noMax = true,
        fallbackLabel = PlainLabel(L["Currency_SparkRadiance_Label"], "Spark of Radiance"),
        labelColorHex = "e8c96e",
    },
    {
        key = "spark_tides",
        itemId = 274476,
        noMax = true,
        patchKey = "12.1.0",
        fallbackLabel = "Spark of Tides",
        labelColorHex = "58c9d4",
    },
    {
        key = "undercoin",
        currencyId = 2803,
        noMax = true,
        label = CurrencyLabel(2803, nil),
    },
    {
        key = "shard_dundun",
        currencyId = 3376,
        noMax = true,
        weeklyCap = 8,
        trackWeeklyEarned = true,
        label = CurrencyLabel(3376, nil),
    },
    {
        key = "nebulous_voidcore",
        currencyId = 3418,
        label = CurrencyLabel(3418, "Nebulous Voidcore"),
    },
    {
        key = "corrosive_coin",
        currencyId = 3448,
        noMax = true,
        patchKey = "12.1.0",
        label = CurrencyLabel(3448, "Corrosive Coin", "2eae6b"),
    },
    {
        key = "corrosive_soul",
        itemId = 273000,
        noMax = true,
        patchKey = "12.1.0",
        fallbackLabel = "Corrosive Soul",
        labelColorHex = "58c9d4",
    },
}
crestRows = {}
MR:RefreshCurrenciesModule(false)

RefreshCrestItemLabels()

MR:RegisterModule({
    key         = "currencies",
    label       = L["Currencies"],
    labelColor  = "#f1c232",
    resetType   = "weekly",
    defaultOpen = true,
    rows = crestRows,
})

local itemCacheFrame = CreateFrame("Frame")
itemCacheFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemCacheFrame:SetScript("OnEvent", function(_, _, itemID)
    if itemID ~= 232875 and itemID ~= 273000 and itemID ~= 274476 then return end
    RefreshCrestItemLabels()
end)
