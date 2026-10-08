local _, ns = ...
if ns.Inactive then return end
local MR = ns.MR

local function CleanDisplayLabel(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end
    return text:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
end

function MR:SetWaypoint(target)
    local mapID = target and target.zone
    local x = target and target.x and (target.x / 100)
    local y = target and target.y and (target.y / 100)
    local tomTom = _G and rawget(_G, "TomTom")

    if not mapID or not x or not y then
        return false, "Invalid coordinates"
    end

    if self.ClearMapWaypointPin then
        self:ClearMapWaypointPin()
    end

    local title = target.waypointTitle or CleanDisplayLabel(target.label)

    if tomTom and tomTom.AddWaypoint then
        local ok, waypoint = pcall(function()
            return tomTom:AddWaypoint(mapID, x, y, {
                title = title,
                persistent = false,
                minimap = true,
                world = true,
            })
        end)
        if ok and waypoint then return true, "TomTom" end
    end

    if UiMapPoint and UiMapPoint.CreateFromCoordinates and C_Map and C_Map.SetUserWaypoint
        and (not C_Map.CanSetUserWaypointOnMap or C_Map.CanSetUserWaypointOnMap(mapID)) then
        local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        if point then
            local ok = pcall(C_Map.SetUserWaypoint, point)
            local waypoint = ok and C_Map.GetUserWaypoint and C_Map.GetUserWaypoint()
            if waypoint and waypoint.uiMapID == mapID and C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
            if waypoint and waypoint.uiMapID == mapID then
                return true, "Blizzard"
            end
        end
    end

    if self.SetMapWaypointPin and self:SetMapWaypointPin(target) then
        return true, "Blizzard map"
    end

    return false, "No waypoint API available"
end

function MR:GetRowWaypointTarget(row, activateNavigation)
    if type(row) ~= "table" then
        return nil
    end

    if type(row.getWaypoint) == "function" then
        local ok, target = pcall(row.getWaypoint, row)
        if ok and type(target) == "table" and target.zone and target.x and target.y then
            return target
        end
    end

    local questIds = row.navigationQuestIds or row.questIds
    if type(questIds) == "table" and C_QuestLog and C_QuestLog.GetNextWaypoint then
        for _, questId in ipairs(questIds) do
            local ok, mapID, x, y = pcall(C_QuestLog.GetNextWaypoint, questId)
            if ok and mapID and x and y then
                if activateNavigation ~= false and C_SuperTrack and C_SuperTrack.SetSuperTrackedQuestID then
                    pcall(C_SuperTrack.SetSuperTrackedQuestID, questId)
                end
                local waypointText
                if C_QuestLog.GetNextWaypointText then
                    local textOk, textValue = pcall(C_QuestLog.GetNextWaypointText, questId)
                    if textOk then
                        waypointText = textValue
                    end
                end
                return {
                    zone = mapID,
                    x = x * 100,
                    y = y * 100,
                    label = waypointText or self:GetQuestName(questId, row.label),
                    waypointTitle = waypointText or self:GetQuestName(questId, CleanDisplayLabel(row.label)),
                }
            end
        end
    end

    if row.zone and row.x and row.y then
        return row
    end

    return nil
end

function MR:NavigateToRow(row)
    local target = self:GetRowWaypointTarget(row)
    if not target then
        return false, "No destination available"
    end

    local ok, source = self:SetWaypoint(target)
    return ok, source, target
end
