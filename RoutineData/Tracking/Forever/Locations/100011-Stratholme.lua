local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[100011] = "Stratholme"
tracking.Forever.rareLocations[100011] = {
    [10393] = {},
    [10558] = {},
    [10809] = {},
}
