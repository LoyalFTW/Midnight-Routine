local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100013] = "Dire Maul"
tracking.Forever.rareLocations[100013] = {
    [11447] = {},
    [11467] = {},
    [11497] = {},
    [11498] = {},
    [14506] = {},
}
