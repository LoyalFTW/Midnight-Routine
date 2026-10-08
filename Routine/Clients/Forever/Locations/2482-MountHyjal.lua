local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[2482] = "Mount Hyjal"
tracking.Forever.rareLocations[2482] = {
    [266901] = {{59.6, 49.2}, {58.8, 41.8}},
}
