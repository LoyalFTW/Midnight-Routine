local _, addonNS = ...
local tracking = addonNS.Tracking

function tracking.API:GetFactionRenownCap(factionId, fallback)
    if C_MajorFactions and C_MajorFactions.GetRenownLevels and factionId then
        local levels = C_MajorFactions.GetRenownLevels(factionId)
        if levels and #levels > 0 then
            return #levels
        end
    end
    return fallback or 20
end

local function NormalizeJourneyKey(name, factionId, delvesFactionId)
    if delvesFactionId and factionId == delvesFactionId then
        return "delvers_journey"
    end
    local lower = name and name:lower() or ""
    if lower:find("delver", 1, true) then
        return "delvers_journey"
    end
    if lower:find("preyseeker", 1, true) then
        return "preyseekers_journey"
    end
    return nil
end


function tracking.API:GetMajorFactionData(factionId)
    if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
        return C_MajorFactions.GetMajorFactionData(factionId)
    end
end

function tracking.API:GetRenownData(factionId, fallback)
    local data = self:GetMajorFactionData(factionId)
    local maximum = self:GetFactionRenownCap(factionId, fallback)
    if not data then return 0, maximum, 0, 2500 end
    return data.renownLevel or 0, maximum, data.renownReputationEarned or 0, data.renownLevelThreshold or 2500
end

function tracking.API:HasMaximumRenown(factionId)
    return C_MajorFactions and C_MajorFactions.HasMaximumRenown
        and C_MajorFactions.HasMaximumRenown(factionId) or false
end

function tracking.API:GetJourneyFactions()
    local journeys = {}
    local delvesFactionId = C_DelvesUI and C_DelvesUI.GetDelvesFactionForSeason and C_DelvesUI.GetDelvesFactionForSeason()
    if delvesFactionId then
        local data = self:GetMajorFactionData(delvesFactionId)
        journeys[#journeys + 1] = { key = "delvers_journey", name = data and data.name, factionId = delvesFactionId }
    end
    local extraJourney
    if C_MajorFactions and C_MajorFactions.GetMajorFactionIDs then
        for _, factionId in ipairs(C_MajorFactions.GetMajorFactionIDs() or {}) do
            local isJourney = C_MajorFactions.ShouldDisplayMajorFactionAsJourney
                and C_MajorFactions.ShouldDisplayMajorFactionAsJourney(factionId)
            if isJourney then
                local data = self:GetMajorFactionData(factionId)
                local key = NormalizeJourneyKey(data and data.name, factionId, delvesFactionId)
                if key == "preyseekers_journey" or (not key and factionId ~= delvesFactionId) then
                    extraJourney = { key = "preyseekers_journey", name = data and data.name, factionId = factionId }
                end
            end
        end
    end
    if extraJourney then journeys[#journeys + 1] = extraJourney end
    return journeys
end
