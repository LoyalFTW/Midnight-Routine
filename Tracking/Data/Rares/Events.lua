local _, addonNS = ...
local tracking = addonNS.Tracking
if tracking.MR.isForever then return end
tracking.rareCatalogs = tracking.rareCatalogs or {}
tracking.rareCatalogs[#tracking.rareCatalogs + 1] = {
    label = "World Events",
    color = { 0.25, 0.78, 0.68 },
    rares = {
        { "Lord Kazzak", 47461, 17, 33.80, 48.60, 121818, catalogEntry = true },
        { "Azuregos", 47462, 76, 49.60, 82.60, 121820, catalogEntry = true },
        { "Lethon", 47463, 26, 63.60, 28.60, 121821, catalogEntry = true },
        { "Taerar", 47463, 63, 93.90, 40.60, 121911, catalogEntry = true },
        { "Ysondre", 47463, 69, 51.20, 11.60, 121912, catalogEntry = true },
        { "Emeriss", 47463, 47, 46.60, 39.40, 121913, catalogEntry = true },
        { "Doomwalker", 60214, 71, 58.72, 84.63, 167749, catalogEntry = true },
        { "Treasure Goblin", nil, 1, 44.04, 19.34, 205490, catalogEntry = true, resolveQuestID = false },
        { "Treasure Goblin", nil, 84, 33.83, 34.34, 205490, catalogEntry = true, resolveQuestID = false },
        { "Treasure Goblin", nil, 2248, 54.57, 54.84, 205490, catalogEntry = true, resolveQuestID = false },
        { "Treasure Goblin", nil, 2339, 69.87, 91.62, 205490, catalogEntry = true, resolveQuestID = false },
        { "Treasure Goblin", nil, 2346, nil, nil, 205490, catalogEntry = true, resolveQuestID = false },
        { "Sha of Anger", 84282, 71, 33.71, 55.71, 226646, catalogEntry = true },
        { "Archavon the Stonewatcher", 84256, 71, 45.99, 28.97, 227257, catalogEntry = true },
    },
}
