local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100006] = "Gnomeregan"
tracking.Forever.rareLocations[100006] = {
    [6228] = {},
}
