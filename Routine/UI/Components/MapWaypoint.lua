local _, ns = ...
local MR = ns.MR

local activeTarget
local dataProvider

MidnightRoutineMapWaypointPinMixin = CreateFromMixins(MapCanvasPinMixin)

function MidnightRoutineMapWaypointPinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_TOPMOST")
    self:SetScalingLimits(1, 1, 1.25)
end

function MidnightRoutineMapWaypointPinMixin:OnAcquired(target)
    self.target = target
    self:SetPosition(target.x / 100, target.y / 100)
    self.Icon:SetAtlas("Waypoint-MapPin-Tracked")
    self:Show()
end

function MidnightRoutineMapWaypointPinMixin:OnReleased()
    self.target = nil
end

function MidnightRoutineMapWaypointPinMixin:OnMouseEnter()
    local target = self.target
    if not target then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(target.waypointTitle or target.label or "MidnightRoutine")
    GameTooltip:AddLine(string.format("%.1f, %.1f", target.x, target.y), 0.7, 1, 0.9)
    GameTooltip:Show()
end

function MidnightRoutineMapWaypointPinMixin:OnMouseLeave()
    GameTooltip:Hide()
end

MidnightRoutineMapWaypointDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)

function MidnightRoutineMapWaypointDataProviderMixin:RemoveAllData()
    local map = self:GetMap()
    if map then
        map:RemoveAllPinsByTemplate("MidnightRoutineMapWaypointPinTemplate")
    end
end

function MidnightRoutineMapWaypointDataProviderMixin:RefreshAllData()
    self:RemoveAllData()
    local map = self:GetMap()
    if map and activeTarget and map:GetMapID() == activeTarget.zone then
        map:AcquirePin("MidnightRoutineMapWaypointPinTemplate", activeTarget)
    end
end

local function EnsureDataProvider()
    if dataProvider then return true end
    if not WorldMapFrame and C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_WorldMap")
    end
    if not (WorldMapFrame and MapCanvasDataProviderMixin) then return false end
    dataProvider = CreateFromMixins(MidnightRoutineMapWaypointDataProviderMixin)
    WorldMapFrame:AddDataProvider(dataProvider)
    return true
end

function MR:SetMapWaypointPin(target)
    if not (target and target.zone and target.x and target.y) then return false end
    if not EnsureDataProvider() then return false end
    activeTarget = {
        zone = target.zone,
        x = target.x,
        y = target.y,
        label = target.label,
        waypointTitle = target.waypointTitle,
    }
    dataProvider:RefreshAllData()
    return true
end

function MR:ClearMapWaypointPin()
    activeTarget = nil
    if dataProvider then
        dataProvider:RefreshAllData()
    end
end
