local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100001] = "Deadmines"
tracking.Forever.rareLocations[100001] = {
    [596] = {},
    [599] = {},
    [3586] = {},
}
