local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100007] = "Scarlet Monastery"
tracking.Forever.rareLocations[100007] = {
    [6488] = {},
    [6489] = {},
    [6490] = {},
}
