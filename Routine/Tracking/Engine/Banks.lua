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

    function MR:GetBankSnapshot(source, charKey)
        local api = RoutineData.API
        if api.GetBankSnapshot then
            return api.GetBankSnapshot(source, charKey)
        end

        local store = self:GetBankSnapshots()
        if not store then return nil end
        local guildKey = charKey and store.characterGuilds[charKey]
        if source == "warband" then return store.warband, guildKey end
        if not charKey then return nil end
        if source == "guild" then
            local snapshot = store.characterGuildBanks[charKey]
            if type(guildKey) == "string" and snapshot and snapshot.guildKey == guildKey then
                return snapshot, guildKey
            end
            return nil, guildKey
        end
        if source == "bags" then return store.bags and store.bags[charKey], guildKey end
        if source == "character" then return store.characters[charKey], guildKey end
    end

    RoutineData.API.RegisterCallback(MR, "ItemsUpdated", function(_, _, source)
        tracking:Fire("BankSnapshotChanged", source == "bank" and "character" or source)
    end)
end
