local _, addonNS = ...
local tracking = addonNS.Tracking
if tracking.MR.isForever then return end
tracking.rareCatalogs = tracking.rareCatalogs or {}
tracking.rareCatalogs[#tracking.rareCatalogs + 1] = {
    label = "Wrath of the Lich King",
    color = { 0.25, 0.78, 0.68 },
    rares = {
        { "Old Crystalbark", nil, 114, 21.00, 28.40, 32357, catalogEntry = true, resolveQuestID = false },
        { "Fumblub Gearwind", nil, 114, 62.60, 34.80, 32358, catalogEntry = true, resolveQuestID = false },
        { "Icehorn", nil, 114, 80.40, 46.00, 32361, catalogEntry = true, resolveQuestID = false },
        { "Perobas the Bloodthirster", nil, 117, 49.80, 4.60, 32377, catalogEntry = true, resolveQuestID = false },
        { "Vigdis the War Maiden", nil, 117, 68.60, 48.40, 32386, catalogEntry = true, resolveQuestID = false },
        { "King Ping", nil, 117, 26.00, 63.80, 32398, catalogEntry = true, resolveQuestID = false },
        { "Tukemuth", nil, 115, 68.80, 57.80, 32400, catalogEntry = true, resolveQuestID = false },
        { "Crazed Indu'le Survivor", nil, 115, 15.60, 45.60, 32409, catalogEntry = true, resolveQuestID = false },
        { "Scarlet Highlord Daion", nil, 115, 69.20, 74.80, 32417, catalogEntry = true, resolveQuestID = false },
        { "Grocklar", nil, 116, 10.60, 39.20, 32422, catalogEntry = true, resolveQuestID = false },
        { "Seething Hate", nil, 116, 28.00, 45.40, 32429, catalogEntry = true, resolveQuestID = false },
        { "Syreian the Bonecarver", nil, 116, 61.50, 36.00, 32438, catalogEntry = true, resolveQuestID = false },
        { "Zul'drak Sentinel", nil, 121, 21.20, 82.60, 32447, catalogEntry = true, resolveQuestID = false },
        { "Griegen", nil, 121, 14.40, 56.20, 32471, catalogEntry = true, resolveQuestID = false },
        { "Terror Spinner", nil, 120, 71.60, 75.00, 32475, catalogEntry = true, resolveQuestID = false },
        { "Terror Spinner", nil, 121, 53.20, 31.40, 32475, catalogEntry = true, resolveQuestID = false },
        { "Aotona", nil, 119, 40.20, 59.00, 32481, catalogEntry = true, resolveQuestID = false },
        { "King Krush", nil, 119, 25.80, 48.80, 32485, catalogEntry = true, resolveQuestID = false },
        { "Putridus the Ancient", nil, 118, 68.40, 64.20, 32487, catalogEntry = true, resolveQuestID = false },
        { "Time-Lost Proto-Drake", nil, 120, 31.00, 69.40, 32491, catalogEntry = true, resolveQuestID = false },
        { "Hildana Deathstealer", nil, 118, 37.70, 24.10, 32495, catalogEntry = true, resolveQuestID = false },
        { "Dirkee", nil, 120, 37.80, 58.40, 32500, catalogEntry = true, resolveQuestID = false },
        { "High Thane Jorfus", nil, 118, 31.20, 62.20, 32501, catalogEntry = true, resolveQuestID = false },
        { "Loque'nahak", nil, 119, 20.60, 70.00, 32517, catalogEntry = true, resolveQuestID = false },
        { "Vyragosa", nil, 120, 31.05, 69.45, 32630, catalogEntry = true, resolveQuestID = false },
        { "Gondria", nil, 121, 61.00, 61.60, 33776, catalogEntry = true, resolveQuestID = false },
        { "Skoll", nil, 120, 27.80, 50.40, 35189, catalogEntry = true, resolveQuestID = false },
        { "Arcturis", nil, 116, 31.00, 55.80, 38453, catalogEntry = true, resolveQuestID = false },
    },
}
