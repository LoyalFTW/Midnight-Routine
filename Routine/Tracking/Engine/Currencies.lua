local _, addonNS = ...
local tracking = addonNS.Tracking

local function CurrencyInfoHasAnyFlag(info, ...)
    if type(info) ~= "table" then
        return false
    end

    for i = 1, select("#", ...) do
        local key = select(i, ...)
        if info[key] then
            return true
        end
    end

    return false
end

function tracking.API:IsCurrencyWarbandTransferable(currencyID, info)
    if CurrencyInfoHasAnyFlag(
        info,
        "isAccountTransferable",
        "isWarbandTransferable",
        "isTransferable",
        "transferable"
    ) then
        return true
    end

    if C_CurrencyInfo then
        local candidates = {
            "IsCurrencyAccountTransferable",
            "IsCurrencyTransferable",
            "IsAccountTransferableCurrency",
        }
        for _, methodName in ipairs(candidates) do
            local method = C_CurrencyInfo[methodName]
            if type(method) == "function" then
                local ok, result = pcall(method, currencyID)
                if ok and result then
                    return true
                end
            end
        end
    end

    return false
end

function tracking.API:GetCurrencyWarbandKind(currencyID)
    if not (currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then return nil end
    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info then return nil end
    if info.isAccountWide then return "account", info end
    if self:IsCurrencyWarbandTransferable(currencyID, info) then return "transfer", info end
    return nil, info
end

function tracking.API:CreateCurrencyBrowserQuery(MR, context)
local GetHeaderKey = context.getHeaderKey
local GetCollapsedHeaders = context.getCollapsedHeaders
local NormalizeSearch = context.normalizeSearch
local EntryMatchesSearch = context.entryMatchesSearch
local GetCurrencyWarbandMarkerInfo = context.getWarbandMarker
local function AddCurrencyListEntry(entries, info, headerKey, forceOpen)
    if not info then
        return
    end

    if info.isHeader then
        entries[#entries + 1] = {
            isHeader = true,
            name = info.name or "",
            headerKey = headerKey or GetHeaderKey(info.name),
            forceOpen = forceOpen and true or false,
        }
        return
    end

    local currencyID = tonumber(info.currencyID or info.currencyId)
    if not currencyID then
        return
    end

    local currencyInfo = C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID) or nil
    entries[#entries + 1] = {
        currencyID = currencyID,
        name = (currencyInfo and currencyInfo.name) or info.name or ("Currency " .. tostring(currencyID)),
        quantity = (currencyInfo and currencyInfo.quantity) or info.quantity or 0,
        maxQuantity = currencyInfo and currencyInfo.maxQuantity or 0,
        weekly = currencyInfo and currencyInfo.quantityEarnedThisWeek or 0,
        weeklyMax = currencyInfo and currencyInfo.maxWeeklyQuantity or 0,
        icon = currencyInfo and currencyInfo.iconFileID,
        headerKey = headerKey,
    }
end

local function BuildCurrencyEntries(searchText, warbandOnly)
    local entries = {}
    local pendingHeader
    local pendingHeaderKey
    local collapsedHeaders = GetCollapsedHeaders()
    local search = NormalizeSearch(searchText)
    local isSearching = search ~= ""

    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize and C_CurrencyInfo.GetCurrencyListInfo) then
        return entries
    end

    local index = 1
    while index <= C_CurrencyInfo.GetCurrencyListSize() do
        local info = C_CurrencyInfo.GetCurrencyListInfo(index)
        if info and info.isHeader and not info.isHeaderExpanded and C_CurrencyInfo.ExpandCurrencyList then
            C_CurrencyInfo.ExpandCurrencyList(index, true)
        end
        index = index + 1
    end

    index = 1
    while index <= C_CurrencyInfo.GetCurrencyListSize() do
        local info = C_CurrencyInfo.GetCurrencyListInfo(index)
        if info and info.isHeader then
            pendingHeader = info
            pendingHeaderKey = GetHeaderKey(info.name)
        else
            local currencyID = info and tonumber(info.currencyID or info.currencyId)
            if currencyID and not (MR.IsCurrencyInCurrenciesModule and MR:IsCurrencyInCurrenciesModule(currencyID)) then
                local currencyInfo = C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID) or nil
                local candidate = {
                    currencyID = currencyID,
                    name = (currencyInfo and currencyInfo.name) or info.name or ("Currency " .. tostring(currencyID)),
                }
                local includeCurrency = (not warbandOnly) or (GetCurrencyWarbandMarkerInfo(currencyID) ~= nil)
                if includeCurrency and EntryMatchesSearch(candidate, search) then
                    if pendingHeader then
                        AddCurrencyListEntry(entries, pendingHeader, pendingHeaderKey, isSearching)
                        if collapsedHeaders[pendingHeaderKey] and not isSearching then
                            pendingHeader = nil
                            index = index + 1
                            while index <= C_CurrencyInfo.GetCurrencyListSize() do
                                local nextInfo = C_CurrencyInfo.GetCurrencyListInfo(index)
                                if nextInfo and nextInfo.isHeader then
                                    index = index - 1
                                    break
                                end
                                index = index + 1
                            end
                        else
                            AddCurrencyListEntry(entries, info, pendingHeaderKey)
                            pendingHeader = nil
                        end
                    else
                        AddCurrencyListEntry(entries, info, pendingHeaderKey)
                    end
                elseif pendingHeader and collapsedHeaders[pendingHeaderKey] and not isSearching then
                    AddCurrencyListEntry(entries, pendingHeader, pendingHeaderKey, isSearching)
                    pendingHeader = nil
                end
            end
        end
        index = index + 1
    end

    return entries
end

return { BuildEntries = BuildCurrencyEntries }
end
