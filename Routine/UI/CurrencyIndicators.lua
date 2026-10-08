local _, ns = ...
local MR = ns.MR

local function IsCurrencyWarbandTransferable(currencyID, info)
    return MR.tracker:IsCurrencyWarbandTransferable(currencyID, info)
end

local function GetCurrencyWarbandKind(currencyID)
    return MR.tracker:GetCurrencyWarbandKind(currencyID)
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
