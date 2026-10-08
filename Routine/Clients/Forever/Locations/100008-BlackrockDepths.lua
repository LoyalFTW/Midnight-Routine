local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100008] = "Blackrock Depths"
tracking.Forever.rareLocations[100008] = {
    [8923] = {},
    [8924] = {},
    [9024] = {},
    [9041] = {},
    [9042] = {},
}
