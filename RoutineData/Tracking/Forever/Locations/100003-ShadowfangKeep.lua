local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100003] = "Shadowfang Keep"
tracking.Forever.rareLocations[100003] = {
    [3872] = {},
    [211764] = {},
    [211765] = {},
}
