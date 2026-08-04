local _, ns = ...
local MR = ns.MR

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

local function IsCurrencyWarbandTransferable(currencyID, info)
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

local function GetCurrencyWarbandKind(currencyID)
    if not (currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return nil
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info then
        return nil
    end

    if info.isAccountWide then
        return "account", info
    end

    if IsCurrencyWarbandTransferable(currencyID, info) then
        return "transfer", info
    end

    return nil, info
end

function MR:GetCurrencyWarbandMarkerInfo(currencyID)
    local kind = GetCurrencyWarbandKind(currencyID)
    if kind == "account" then
        return {
            atlas = "warbands-icon",
            text = ACCOUNT_LEVEL_CURRENCY or "Warband Currency",
        }
    elseif kind == "transfer" then
        return {
            atlas = "warbands-transferable-icon",
            text = ACCOUNT_TRANSFERRABLE_CURRENCY or "Warband Transferable",
        }
    end

    return nil
end

function MR:AddCurrencyTransferTooltipLines(tooltip, currencyID)
    if not (tooltip and currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return false
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not IsCurrencyWarbandTransferable(currencyID, info) then
        return false
    end

    local percentage = tonumber(info and (info.transferPercentage or info.accountTransferPercentage or info.currencyTransferPercentage))
    tooltip:AddLine(" ")
    if percentage and percentage > 0 then
        tooltip:AddLine(string.format("Warband Transfer: %d%%", percentage), 0.45, 0.85, 1, true)
    else
        tooltip:AddLine("Warband Transferable", 0.45, 0.85, 1, true)
    end
    return true
end
