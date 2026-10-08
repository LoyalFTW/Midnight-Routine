local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end

local SCAN_DEBOUNCE = 1
local MAX_EXPAND_PASSES = 4

local scanning
local scanPending

local function Now()
    return (GetServerTime and GetServerTime()) or time()
end

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

-- A quantity of 0 is dropped so a spent currency does not linger in the snapshot.
local function StoreEntry(record, currencyID, info)
    local quantity = info and info.quantity
    if type(quantity) ~= "number" or IsSecret(quantity) then return end
    if quantity <= 0 then
        record.currencies[currencyID] = nil
        return
    end
    record.currencies[currencyID] = {
        q = quantity,
        w = tonumber(info.quantityEarnedThisWeek) or 0,
        mw = tonumber(info.maxWeeklyQuantity) or 0,
    }
end

local function CurrencyIDFromLink(link)
    return link and tonumber(link:match("currency:(%d+)"))
end

local function ListEntryID(index, info)
    local currencyID = tonumber(info.currencyID or info.currencyId)
    if currencyID then return currencyID end
    local getLink = C_CurrencyInfo.GetCurrencyListLink
    return getLink and CurrencyIDFromLink(getLink(index)) or nil
end

-- Headers hide their children while collapsed, so expand everything, read it, then restore the
-- player's own collapsed state. Expansion state is tracked by header name.
local function ExpandAllHeaders()
    local collapsed = {}
    for _ = 1, MAX_EXPAND_PASSES do
        local expanded = false
        for index = C_CurrencyInfo.GetCurrencyListSize(), 1, -1 do
            local info = C_CurrencyInfo.GetCurrencyListInfo(index)
            if info and info.isHeader and not info.isHeaderExpanded then
                C_CurrencyInfo.ExpandCurrencyList(index, true)
                collapsed[info.name] = true
                expanded = true
            end
        end
        if not expanded then break end
    end
    return collapsed
end

local function RestoreCollapsedHeaders(collapsed)
    for index = C_CurrencyInfo.GetCurrencyListSize(), 1, -1 do
        local info = C_CurrencyInfo.GetCurrencyListInfo(index)
        if info and info.isHeader and collapsed[info.name] then
            C_CurrencyInfo.ExpandCurrencyList(index, false)
        end
    end
end

local function CanScanList()
    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize and C_CurrencyInfo.ExpandCurrencyList) then return false end
    if InCombatLockdown() then return false end
    -- Do not rearrange the list while the player is looking at it.
    if CharacterFrame and CharacterFrame:IsShown() then return false end
    return true
end

function RoutineData:ScanCurrencies()
    local charKey = self:GetCurrentCharacterKey()
    if not charKey or scanning then return end
    if not CanScanList() then
        scanPending = true
        return
    end
    scanPending = nil
    scanning = true

    local ok, err = pcall(function()
        local collapsed = ExpandAllHeaders()
        local record = self:GetCharacterRecord(charKey, true)
        local found = {}
        for index = 1, C_CurrencyInfo.GetCurrencyListSize() do
            local info = C_CurrencyInfo.GetCurrencyListInfo(index)
            if info and not info.isHeader then
                local currencyID = ListEntryID(index, info)
                if currencyID then
                    found[currencyID] = true
                    StoreEntry(record, currencyID, info)
                end
            end
        end
        -- Currencies that left the list (removed or hidden by the game) are dropped.
        for currencyID in pairs(record.currencies) do
            if not found[currencyID] then record.currencies[currencyID] = nil end
        end
        record.classFile = select(2, UnitClass("player")) or record.classFile
        record.updatedAt.currencies = Now()
        RestoreCollapsedHeaders(collapsed)
    end)
    scanning = nil
    if not ok then
        scanPending = true
        return
    end
    self:Fire("CurrenciesUpdated", charKey)
end

function RoutineData:UpdateCurrency(currencyID)
    local charKey = self:GetCurrentCharacterKey()
    if not charKey or type(currencyID) ~= "number" or IsSecret(currencyID) then return end
    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID)
    local record = self:GetCharacterRecord(charKey, true)
    StoreEntry(record, currencyID, info)
    record.updatedAt.currencies = Now()
    self:Fire("CurrenciesUpdated", charKey, currencyID)
end

local fullScanQueued
local function QueueFullScan()
    if fullScanQueued then return end
    fullScanQueued = true
    C_Timer.After(SCAN_DEBOUNCE, function()
        fullScanQueued = nil
        RoutineData:ScanCurrencies()
    end)
end

RoutineData:OnLogin(function()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:SetScript("OnEvent", function(_, event, currencyType)
        if event == "CURRENCY_DISPLAY_UPDATE" then
            -- Expanding or collapsing headers also fires this event without a currency, so only
            -- real changes (which carry the currency ID) are handled. That keeps the scan from re-triggering itself.
            if type(currencyType) == "number" and not scanning then
                RoutineData:UpdateCurrency(currencyType)
            end
        elseif event == "PLAYER_REGEN_ENABLED" then
            if scanPending then QueueFullScan() end
        else
            QueueFullScan()
        end
    end)
    -- Closing the character frame is the other moment a deferred scan can finally run.
    if CharacterFrame then
        CharacterFrame:HookScript("OnHide", function()
            if scanPending then QueueFullScan() end
        end)
    end
end)
