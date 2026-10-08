local _, addonNS = ...
local tracking = addonNS.Tracking

function tracking.API:AppendRareCatalog(MR, L, zones)
    local byMap, byNPC, byQuest = {}, {}, {}
    for _, zone in ipairs(zones) do
        for _, mapID in ipairs(zone.mapIDs or {}) do byMap[mapID] = zone end
        for _, rare in ipairs(zone.rares) do
            if rare[3] then byMap[rare[3]] = zone end
            if rare[6] then byNPC[rare[6]] = rare end
            if rare[2] then byQuest[rare[2]] = rare end
        end
    end
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    for _, catalog in ipairs(tracking.rareCatalogs or {}) do
        for _, rare in ipairs(catalog.rares) do
            if (not rare.patch or MR:IsPatchAvailable(rare.patch)) and (not rare.faction or not faction or rare.faction == faction) then
                local known = byNPC[rare[6]] or (catalog.label == "Midnight" and byQuest[rare[2]])
                if known then
                    known[6] = known[6] or rare[6]
                    known[2] = known[2] or rare[2]
                    byNPC[known[6]] = known
                    local zone = known[3] and byMap[known[3]]
                    if zone and not byMap[rare[3]] then
                        zone.mapIDs = zone.mapIDs or {}
                        zone.mapIDs[#zone.mapIDs + 1] = rare[3]
                        byMap[rare[3]] = zone
                    end
                else
                    local mapID = rare[3]
                    local zone = byMap[mapID]
                    if not zone then
                        local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
                        zone = {
                            key = "rare_map_" .. mapID,
                            label = catalog.label .. " - " .. (info and info.name or L["Unknown"]),
                            mapIDs = { mapID },
                            color = catalog.color,
                            defaultCollapsed = catalog.label ~= "Midnight",
                            resolveQuestIDs = false,
                            rares = {},
                        }
                        zones[#zones + 1] = zone
                        byMap[mapID] = zone
                    end
                    zone.rares[#zone.rares + 1] = rare
                end
            end
        end
    end
    return zones
end
