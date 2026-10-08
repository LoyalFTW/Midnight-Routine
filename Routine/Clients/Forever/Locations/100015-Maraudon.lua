local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100015] = "Maraudon"
tracking.Forever.rareLocations[100015] = {
    [12237] = {},
}
