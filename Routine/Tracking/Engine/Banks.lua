local _, addonNS = ...
if addonNS.Inactive then return end
local tracking = addonNS.Tracking

tracking.installers["Banks"] = function(owner, context)
    local MR = context.namespace.MR
    local L = context.labels
    local RoutineData = _G.RoutineData

    RoutineData:SetLabelProvider(function(key) return L[key] end)

    function MR:GetBankSnapshots()
        return RoutineData.API.GetBankSnapshots()
    end

    RoutineData.API.RegisterCallback(MR, "ItemsUpdated", function(_, _, source)
        tracking:Fire("BankSnapshotChanged", source == "bank" and "character" or source)
    end)
end
