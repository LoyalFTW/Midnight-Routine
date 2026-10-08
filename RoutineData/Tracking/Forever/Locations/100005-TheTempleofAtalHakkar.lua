local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100005] = "The Temple of Atal'Hakkar"
tracking.Forever.rareLocations[100005] = {
    [5399] = {},
    [5400] = {},
}
