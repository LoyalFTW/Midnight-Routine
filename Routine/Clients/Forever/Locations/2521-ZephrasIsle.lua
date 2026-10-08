local _, addonNS = ...
local tracking = addonNS.Tracking
if not tracking.MR.isForever then return end
tracking.Forever.rareZoneNames[2521] = "Zephras Isle"
tracking.Forever.rareLocations[2521] = {
    [250936] = {{61.2, 37.2}, {61.6, 38.4}},
    [255887] = {{50.2, 51}},
    [256028] = {{52, 46.4}, {54, 48}},
    [256492] = {{53.8, 78.8}, {48, 85.4}, {51.4, 82.4}, {53.6, 80}},
    [259385] = {{66, 53.8}},
    [259388] = {{60.2, 36.8}, {60.2, 34.6}, {57.6, 37}, {57.8, 38.2}},
    [259394] = {{34.2, 60}},
    [259398] = {{62.4, 62}, {63.6, 62.4}},
}
