local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers["ForeverReputations"] = function(owner, context)
    local ns = context.namespace
    if not ns.MR.isForever then return end
    ns.Forever = ns.Forever or {}
    local F = ns.Forever
    function F.GetFactions()
        local factions = {}
        local modern = C_Reputation and C_Reputation.GetNumFactions and C_Reputation.GetFactionDataByIndex
        local count = modern and C_Reputation.GetNumFactions() or (GetNumFactions and GetNumFactions() or 0)
        for index = 1, count do
            local data
            if modern then
                data = C_Reputation.GetFactionDataByIndex(index)
            elseif GetFactionInfo then
                local name, _, reaction, low, high, standing, _, _, header, _, hasRep, _, id = GetFactionInfo(index)
                data = { name = name, reaction = reaction, currentReactionThreshold = low, nextReactionThreshold = high, currentStanding = standing, isHeader = header, isHeaderWithRep = hasRep, factionID = id }
            end
            if data and data.name and data.factionID and (not data.isHeader or data.isHeaderWithRep) then
                factions[#factions + 1] = { key = "reputation_" .. data.factionID, label = data.name, factionId = data.factionID, maxRenown = 8, color = { 0.35, 0.79, 0.83 }, hex = "59c9d4", reputation = data }
            end
        end
        return factions
    end
    function F.GetReputation(faction)
        local data = C_Reputation and C_Reputation.GetFactionDataByID and C_Reputation.GetFactionDataByID(faction.factionId) or faction.reputation
        if not (C_Reputation and C_Reputation.GetFactionDataByID) then
            for _, current in ipairs(F.GetFactions()) do
                if current.factionId == faction.factionId then data = current.reputation; break end
            end
        end
        local reaction = data and data.reaction or 4
        local low = data and data.currentReactionThreshold or 0
        local high = data and data.nextReactionThreshold or low
        local needed = math.max(1, high - low)
        local current = math.min(needed, math.max(0, (data and data.currentStanding or 0) - low))
        if reaction >= 8 then current = needed end
        return reaction, 8, current, needed
    end
    function F.IsReputationCapped(faction)
        local reaction = F.GetReputation(faction)
        return reaction >= 8
    end
    function F.GetStandingLabel(reaction)
        return _G["FACTION_STANDING_LABEL" .. reaction] or tostring(reaction)
    end
end
