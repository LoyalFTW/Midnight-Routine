local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100002] = "Wailing Caverns"
tracking.Forever.rareLocations[100002] = {
    [3652] = {},
    [3672] = {},
    [5912] = {},
}
