local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100004] = "Razorfen Kraul"
tracking.Forever.rareLocations[100004] = {
    [4425] = {},
    [4438] = {},
    [4842] = {},
}
