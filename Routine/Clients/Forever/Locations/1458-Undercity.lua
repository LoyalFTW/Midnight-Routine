local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[1458] = "Undercity"
tracking.Forever.rareLocations[1458] = {
    [204070] = {{23.2, 42.2}, {22.2, 41.8}, {22.6, 43.2}, {23.2, 39.6}, {23.4, 41.4}},
}
