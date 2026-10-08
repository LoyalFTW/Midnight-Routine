local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100010] = "Zul'Farrak"
tracking.Forever.rareLocations[100010] = {
    [10080] = {},
    [10081] = {},
    [10082] = {},
}
