local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end

local SCAN_DEBOUNCE = 1
local MAX_EXPAND_PASSES = 4

local scanning
local scanPending
local pendingTransfer

local function Now()
    return (GetServerTime and GetServerTime()) or time()
end

local function IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

-- A quantity of 0 is dropped so a spent currency does not linger in the snapshot.
local function StoreEntry(record, currencyID, info, now)
    local quantity = info and info.quantity
    if type(quantity) ~= "number" or IsSecret(quantity) then return end
    if quantity <= 0 then
        record.currencies[currencyID] = nil
        return true
    end
    local weekly = info.quantityEarnedThisWeek
    if IsSecret(weekly) or type(weekly) ~= "number" then weekly = nil end
    local maxWeekly = info.maxWeeklyQuantity
    if IsSecret(maxWeekly) or type(maxWeekly) ~= "number" then maxWeekly = nil end
    local entry = record.currencies[currencyID]
    record.currencies[currencyID] = {
        q = quantity,
        w = weekly or (entry and entry.w) or 0,
        mw = maxWeekly or (entry and entry.mw) or 0,
        weeklyAt = weekly ~= nil and now or (entry and entry.weeklyAt),
    }
    return true
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
local function ExpandAllHeaders(collapsed)
    for _ = 1, MAX_EXPAND_PASSES do
        local expanded = false
        for index = C_CurrencyInfo.GetCurrencyListSize(), 1, -1 do
            local info = C_CurrencyInfo.GetCurrencyListInfo(index)
            if info and info.isHeader and not info.isHeaderExpanded then
                collapsed[info.name] = true
                C_CurrencyInfo.ExpandCurrencyList(index, true)
                expanded = true
            end
        end
        if not expanded then break end
    end
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

    local record = self:GetCharacterRecord(charKey, true)
    local snapshot = { currencies = {} }
    for currencyID, entry in pairs(record.currencies) do
        snapshot.currencies[currencyID] = entry
    end
    local now, collapsed = Now(), {}
    local ok = pcall(function()
        ExpandAllHeaders(collapsed)
        local found = {}
        for index = 1, C_CurrencyInfo.GetCurrencyListSize() do
            local info = C_CurrencyInfo.GetCurrencyListInfo(index)
            if info and not info.isHeader then
                local currencyID = ListEntryID(index, info)
                if currencyID then
                    found[currencyID] = true
                    StoreEntry(snapshot, currencyID, info, now)
                end
            end
        end
        -- Currencies that left the list (removed or hidden by the game) are dropped.
        for currencyID in pairs(snapshot.currencies) do
            if not found[currencyID] then snapshot.currencies[currencyID] = nil end
        end
    end)
    local restored = not next(collapsed) or pcall(RestoreCollapsedHeaders, collapsed)
    scanning = nil
    if not ok or not restored then
        scanPending = true
        return
    end
    record.currencies = snapshot.currencies
    record.classFile = select(2, UnitClass("player")) or record.classFile
    record.currencyGUID = UnitGUID("player") or record.currencyGUID
    record.updatedAt.currencies = now
    self:Fire("CurrenciesUpdated", charKey)
end

function RoutineData:UpdateCurrency(currencyID)
    local charKey = self:GetCurrentCharacterKey()
    if not charKey or type(currencyID) ~= "number" or IsSecret(currencyID) then return end
    local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID)
    local record = self:GetCharacterRecord(charKey, true)
    local now = Now()
    if not StoreEntry(record, currencyID, info, now) then return end
    record.currencyGUID = UnitGUID("player") or record.currencyGUID
    record.updatedAt.currencies = now
    self:Fire("CurrenciesUpdated", charKey, currencyID)
end

local function ResolveTransferSource(sourceGUID, fullName)
    local legacyKey
    if type(fullName) == "string" and not IsSecret(fullName) then
        legacyKey = fullName:gsub("%s+", "")
    end
    local matchedKey
    local ambiguous
    for key, record in pairs(RoutineData.db.characters) do
        if record.currencyGUID == sourceGUID then return key end
        if not record.currencyGUID and legacyKey and key:gsub("%s+", "") == legacyKey then
            if matchedKey then ambiguous = true end
            matchedKey = key
        end
    end
    if not ambiguous then return matchedKey end
end

local function CaptureTransfer(sourceGUID, currencyID, amount)
    if pendingTransfer then return end
    if IsSecret(sourceGUID) or IsSecret(currencyID) or IsSecret(amount)
        or type(sourceGUID) ~= "string" or type(currencyID) ~= "number"
        or type(amount) ~= "number" or amount <= 0 then return end
    local currency = C_CurrencyInfo
    if currency.IsCurrencyTransferInProgress and not currency.IsCurrencyTransferInProgress() then return end
    local cost = currency.GetCostToTransferCurrency(currencyID, amount)
    if IsSecret(cost) or type(cost) ~= "number" or cost < amount then return end
    for _, source in ipairs(currency.FetchCurrencyDataFromAccountCharacters(currencyID) or {}) do
        if not IsSecret(source.characterGUID) and source.characterGUID == sourceGUID then
            local quantity = source.quantity
            local key = ResolveTransferSource(sourceGUID, source.fullCharacterName)
            if key and not IsSecret(quantity) and type(quantity) == "number" and quantity >= cost then
                pendingTransfer = { key = key, guid = sourceGUID, id = currencyID, balance = quantity - cost }
            end
            return
        end
    end
end

local function FinishTransfer()
    local transfer = pendingTransfer
    pendingTransfer = nil
    if not transfer then return end
    local record = RoutineData:GetCharacterRecord(transfer.key)
    if record then
        local entry = record.currencies[transfer.id]
        if transfer.balance == 0 then
            record.currencies[transfer.id] = nil
        elseif entry then
            entry.q = transfer.balance
        else
            record.currencies[transfer.id] = { q = transfer.balance, w = 0, mw = 0 }
        end
        record.currencyGUID = transfer.guid
        RoutineData:Fire("CurrenciesUpdated", transfer.key, transfer.id)
    end
    C_Timer.After(0, function() RoutineData:UpdateCurrency(transfer.id) end)
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
    local currency = C_CurrencyInfo
    local canTrackTransfers = currency and currency.RequestCurrencyFromAccountCharacter
        and currency.FetchCurrencyDataFromAccountCharacters and currency.GetCostToTransferCurrency
    if canTrackTransfers and (not (C_EventUtils and C_EventUtils.IsEventValid)
        or (C_EventUtils.IsEventValid("CURRENCY_TRANSFER_SUCCESS") and C_EventUtils.IsEventValid("CURRENCY_TRANSFER_FAILED"))) then
        frame:RegisterEvent("CURRENCY_TRANSFER_SUCCESS")
        frame:RegisterEvent("CURRENCY_TRANSFER_FAILED")
        hooksecurefunc(currency, "RequestCurrencyFromAccountCharacter", CaptureTransfer)
    end
    frame:SetScript("OnEvent", function(_, event, currencyType)
        if event == "CURRENCY_DISPLAY_UPDATE" then
            -- Expanding or collapsing headers also fires this event without a currency, so only
            -- real changes (which carry the currency ID) are handled. That keeps the scan from re-triggering itself.
            if type(currencyType) == "number" and not scanning then
                RoutineData:UpdateCurrency(currencyType)
            end
        elseif event == "CURRENCY_TRANSFER_SUCCESS" then
            FinishTransfer()
        elseif event == "CURRENCY_TRANSFER_FAILED" then
            pendingTransfer = nil
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
