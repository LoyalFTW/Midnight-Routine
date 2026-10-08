local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers["ForeverRares"] = function(owner, context)
    local ns = context.namespace
    if not ns.MR.isForever then return end
    local L = context.labels
    local F = ns.Forever
    local cachedZones, cachedChar, cachedRevision
    local revision = 0
    local localizedNames = {}
    local waypointIndices = {}
    function F.GetRareZones()
        local char = ns.MR.db and ns.MR.db.char
        if cachedZones and cachedChar == char and cachedRevision == revision then return cachedZones end
        local zones, byKey = {}, {}
        local saved = char and char.foreverRares or {}
        local function AddRare(mapID, npcID, name, points, observed)
            local key = tostring(mapID or 0)
            local zone = byKey[key]
            if not zone then
                local info = mapID and mapID > 0 and mapID < 100000 and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
                zone = { key = key, label = info and info.name or F.rareZoneNames[mapID or 0] or L["Forever_DiscoveredRares"], color = { 0.84, 0.66, 1 }, rares = {} }
                zones[#zones + 1], byKey[key] = zone, zone
            end
            local point = points and points[1]
            local rare = { name, nil, mapID and mapID > 0 and mapID < 100000 and mapID or nil, point and point[1], point and point[2], npcID }
            rare.locations = points or {}
            rare.observedLocation = observed
            rare.locationKey = key .. ":" .. npcID
            zone.rares[#zone.rares + 1] = rare
        end
        for mapID, entries in pairs(F.rareLocations) do
            for npcID, points in pairs(entries) do
                local observation = saved[tostring(npcID)]
                if mapID ~= 0 or type(observation) ~= "table" or not observation.mapID then
                    local data = F.rareCatalog[npcID]
                    AddRare(mapID, npcID, localizedNames[npcID] or data.name, points, false)
                end
            end
        end
        for id, observation in pairs(saved) do
            local npcID = tonumber(id)
            local data = type(observation) == "table" and observation or { name = observation }
            local known = npcID and F.rareCatalog[npcID]
            local unknownLocation = known and F.rareLocations[0] and F.rareLocations[0][npcID]
            if npcID and (not known or (unknownLocation and data.mapID)) then
                local points = data.x and data.y and { { data.x, data.y } } or {}
                AddRare(data.mapID or 0, npcID, data.name or (known and known.name) or tostring(npcID), points, true)
            end
        end
        table.sort(zones, function(a, b) return a.label < b.label end)
        for _, zone in ipairs(zones) do
            table.sort(zone.rares, function(a, b)
                if a[1] == b[1] then return a[6] < b[6] end
                return a[1] < b[1]
            end)
        end
        cachedZones, cachedChar, cachedRevision = zones, char, revision
        return zones
    end
    function F.GetCurrentRareZoneKey()
        if IsInInstance and IsInInstance() and GetInstanceInfo then
            local name = GetInstanceInfo()
            local normalized = name and name:lower():gsub("^the%s+", "")
            for mapID, label in pairs(F.rareZoneNames) do
                if mapID >= 100000 and normalized == label:lower():gsub("^the%s+", "") then return tostring(mapID) end
            end
        end
        local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        for _ = 1, 10 do
            if not mapID then break end
            if F.rareLocations[mapID] then return tostring(mapID) end
            local info = C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
            if not info or not info.parentMapID or info.parentMapID == 0 or info.parentMapID == mapID then break end
            mapID = info.parentMapID
        end
        return mapID and tostring(mapID) or nil
    end
    function F.GetRareWaypoint(rare)
        if not rare or not rare[3] or #rare.locations == 0 then return nil end
        local index = waypointIndices[rare.locationKey] or 1
        local point = rare.locations[index] or rare.locations[1]
        return { label = rare[1], waypointTitle = rare[1], zone = rare[3], x = point[1], y = point[2] }
    end
    function F.AdvanceRareWaypoint(rare)
        if rare and #rare.locations > 1 then
            waypointIndices[rare.locationKey] = ((waypointIndices[rare.locationKey] or 1) % #rare.locations) + 1
        end
    end
    function F.DiscoverRare(unit)
        unit = unit or "target"
        local char = ns.MR.db and ns.MR.db.char
        if not (char and UnitClassification and UnitGUID and UnitName and ns.MR.GetRareNPCIDFromGUID) then return false end
        local guid, name = UnitGUID(unit), UnitName(unit)
        local npcID = ns.MR:GetRareNPCIDFromGUID(guid)
        if not (npcID and name) then return false end
        local known = F.rareCatalog[npcID]
        local classification = UnitClassification(unit)
        if not known and classification ~= "rare" and classification ~= "rareelite" then return false end
        local changed = localizedNames[npcID] ~= name
        localizedNames[npcID] = name
        local undocumented = F.rareLocations[0] and F.rareLocations[0][npcID]
        if not known or undocumented then
            char.foreverRares = char.foreverRares or {}
            local id = tostring(npcID)
            local old = char.foreverRares[id]
            if type(old) ~= "table" or not old.mapID then
                local mapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
                local position = mapID and C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(mapID, "player")
                local x, y
                if position then x, y = position:GetXY() end
                char.foreverRares[id] = { name = name, mapID = mapID, x = x and x * 100, y = y and y * 100 }
                changed = true
            end
        end
        if changed then revision = revision + 1 end
        return changed
    end
end
