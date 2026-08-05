local _, ns = ...
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)

local T, S, WQ, WD, DMF, TR, Ref = ns.T, ns.S, ns.WQ, ns.WD, ns.DMF, ns.TR, ns.Ref
local DRAGONFLIGHT_CATCHUP_ITEM_ID = ns.DRAGONFLIGHT_CATCHUP_ITEM_ID

local VALDRAKKEN = 2112
local ZARALEK_CAVERN = 2133

local LOC = {
    treatise = { zone = VALDRAKKEN, x = 35.6, y = 59.0, label = "Crafting Orders - Valdrakken" },
    azley = { zone = VALDRAKKEN, x = 35.8, y = 59.4, label = "Azley - Valdrakken" },
    kayann = { zone = VALDRAKKEN, x = 36.4, y = 62.5, label = "Kayann - Valdrakken" },
    magnolia = { zone = VALDRAKKEN, x = 36.8, y = 63.6, label = "Magnolia Oaken - Valdrakken" },
    dothenos = { zone = VALDRAKKEN, x = 37.0, y = 63.2, label = "Dothenos - Valdrakken" },
    dhurrel = { zone = VALDRAKKEN, x = 37.0, y = 63.2, label = "Dhurrel - Valdrakken" },
    gnoklin = { zone = VALDRAKKEN, x = 37.0, y = 63.2, label = "Gnoklin Quirkcoil - Valdrakken" },
    temnaayu = { zone = VALDRAKKEN, x = 37.0, y = 63.2, label = "Temnaayu - Valdrakken" },
    conflago = { zone = VALDRAKKEN, x = 36.0, y = 71.8, label = "Conflago - Valdrakken" },
    soragosa = { zone = VALDRAKKEN, x = 30.8, y = 61.4, label = "Soragosa - Valdrakken" },
    clinkyclick = { zone = VALDRAKKEN, x = 42.27, y = 48.74, label = "Clinkyclick Shatterboom - Valdrakken" },
    agrikus = { zone = VALDRAKKEN, x = 38.8, y = 75.0, label = "Agrikus - Valdrakken" },
    talendara = { zone = VALDRAKKEN, x = 39.4, y = 73.6, label = "Talendara - Valdrakken" },
    tuluradormi = { zone = VALDRAKKEN, x = 40.80, y = 61.12, label = "Tuluradormi - Valdrakken" },
    metalshaperKuroko = { zone = VALDRAKKEN, x = 37.0, y = 47.6, label = "Metalshaper Kuroko - Valdrakken" },
    hideshaperKoruz = { zone = VALDRAKKEN, x = 28.8, y = 61.6, label = "Hideshaper Koruz - Valdrakken" },
    ralathor = { zone = VALDRAKKEN, x = 28.8, y = 60.4, label = "Ralathor the Rugged - Valdrakken" },
    sekita = { zone = VALDRAKKEN, x = 39.0, y = 51.2, label = "Sekita the Burrower - Valdrakken" },
    threadfinderFulafong = { zone = VALDRAKKEN, x = 31.8, y = 66.6, label = "Threadfinder Fulafong - Valdrakken" },
    dustmongerTopuiz = { zone = ZARALEK_CAVERN, x = 55.8, y = 55.8, label = "Dustmonger Topuiz - Loamm" },
}

local MASTER_NOTE = "Speak with the hidden Dragon Isles profession master."
local WEEKLY_DROP_NOTE = "Loot weekly Dragon Isles profession knowledge drops from treasures and appropriate enemies."

local function QuestLocations(...)
    local locations = {}
    for i = 1, select("#", ...), 2 do
        local questIDs = select(i, ...)
        local location = select(i + 1, ...)
        for _, questID in ipairs(questIDs or {}) do
            locations[questID] = location
        end
    end
    return locations
end

local DRAGONFLIGHT_EXPANSION = {
        key = "dragonflight",
        label = L["ProfKnowledge_LegacySection_Dragonflight"] or "Dragonflight",
        shortLabel = L["ProfKnowledge_LegacySection_Dragonflight"] or "Dragonflight",
        sharedCatchupItemID = DRAGONFLIGHT_CATCHUP_ITEM_ID,
        professions = {
            { key = "alchemy", label = L["Alchemy"], skillLine = 2823, weekly = {
                TR{ itemID = 194697, questID = 74108, kp = 1, note = L["ProfKnowledge_TreatiseNote"], zone = LOC.treatise.zone, x = LOC.treatise.x, y = LOC.treatise.y, mainMenuOrder = 3 },
                WQ{ questIDs = { 75363, 75371, 77932, 77933, 66937, 66938, 66940, 72427, 70530, 70531, 70532, 70533 }, label = "Draconic Alchemy Notes", kp = 3, note = L["ProfKnowledge_WeeklyProfessionQuest"], rowKey = "df_alch_draconic_weekly", mainMenuOrder = 1, preferFallbackLabel = true, questLocations = QuestLocations({ 75363, 75371 }, LOC.kayann, { 77932, 77933 }, LOC.magnolia, { 66937 }, LOC.dothenos, { 66938, 66940, 72427 }, LOC.dhurrel, { 70530, 70531, 70532, 70533 }, LOC.conflago) },
                WD{ questIDs = { 66373, 66374, 70504, 70511 }, label = "Draconic Alchemy Drops", kp = 1, required = 4, mode = "count", note = WEEKLY_DROP_NOTE, rowKey = "df_alch_drops", mainMenuOrder = 2, preferFallbackLabel = true },
            }, darkmoon = {
                DMF{ label = L["ProfKnowledge_DMF_Alchemy"], questID = 29506, kp = 3, zone = 407, x = 50.5, y = 69.6, note = L["ProfKnowledge_DMFNote"], rowKey = "df_alch_dmf", mainMenuLabel = L["DMF_Alch_Label"] },
            }, treasures = {
                T{ questID = 70289, itemID = 198685, kp = 3, zone = 2022, x = 25.1, y = 73.3, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70274, itemID = 198663, kp = 3, zone = 2022, x = 55.0, y = 81.0, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70305, itemID = 198710, kp = 3, zone = 2023, x = 79.2, y = 83.8, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70208, itemID = 198599, kp = 3, zone = 2024, x = 16.4, y = 38.5, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70309, itemID = 198712, kp = 3, zone = 2024, x = 67.0, y = 13.2, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70278, itemID = 201003, kp = 3, zone = 2025, x = 55.2, y = 30.5, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70301, itemID = 198697, kp = 3, zone = 2025, x = 59.5, y = 38.4, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75649, itemID = 205212, kp = 3, zone = 2133, x = 62.10, y = 41.12, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75646, itemID = 205211, kp = 3, zone = 2133, x = 52.68, y = 18.30, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75651, itemID = 205213, kp = 3, zone = 2133, x = 40.48, y = 59.18, note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, discoveries = {
                S{ label = "Hidden Master: Grigori Vialtry", questID = 70247, kp = 5, zone = 2022, x = 60.92, y = 75.84, note = MASTER_NOTE },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_100_artisan_s_mettle_preferred_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_150_artisan_s_mettle_valued_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_200_artisan_s_mettle_esteemed_rep"] },
            } },
            { key = "blacksmithing", label = L["Blacksmithing"], skillLine = 2822, weekly = {
                TR{ itemID = 198454, questID = 74109, kp = 1, note = L["ProfKnowledge_TreatiseNote"], zone = LOC.treatise.zone, x = LOC.treatise.x, y = LOC.treatise.y, mainMenuOrder = 3 },
                WQ{ questIDs = { 70589, 75148, 75569, 77935, 77936, 66517, 66897, 66941, 72398, 70211, 70233, 70234, 70235 }, label = "Draconic Blacksmith's Writ", kp = 3, note = L["ProfKnowledge_WeeklyProfessionQuest"], rowKey = "df_bs_draconic_weekly", mainMenuOrder = 1, preferFallbackLabel = true, questLocations = QuestLocations({ 70589 }, LOC.azley, { 75148, 75569 }, LOC.kayann, { 77935, 77936 }, LOC.magnolia, { 66517, 66897, 66941, 72398 }, LOC.dhurrel, { 70211, 70233, 70234, 70235 }, LOC.metalshaperKuroko) },
                WD{ questIDs = { 66381, 66382, 70512, 70513 }, label = "Draconic Blacksmithing Drops", kp = 1, required = 4, mode = "count", note = WEEKLY_DROP_NOTE, rowKey = "df_bs_drops", mainMenuOrder = 2, preferFallbackLabel = true },
            }, darkmoon = {
                DMF{ label = L["ProfKnowledge_DMF_Blacksmithing"], questID = 29508, kp = 3, zone = 407, x = 51.1, y = 82.0, note = L["ProfKnowledge_DMFNote"], rowKey = "df_bs_dmf", mainMenuLabel = L["DMF_BS_Label"] },
            }, treasures = {
                T{ questID = 70232, itemID = 198791, kp = 3, zone = 2022, x = 56.4, y = 19.5, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70246, itemID = 201007, kp = 3, zone = 2022, x = 22.0, y = 87.0, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70312, itemID = 201005, kp = 3, zone = 2022, x = 65.5, y = 25.7, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70296, itemID = 201008, kp = 3, zone = 2022, x = 35.5, y = 64.3, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70310, itemID = 201010, kp = 3, zone = 2022, x = 34.5, y = 67.1, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70313, itemID = 201004, kp = 3, zone = 2023, x = 81.1, y = 37.9, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70353, itemID = 201009, kp = 3, zone = 2023, x = 50.9, y = 66.5, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70314, itemID = 201011, kp = 3, zone = 2024, x = 53.1, y = 65.3, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70311, itemID = 201006, kp = 3, zone = 2025, x = 52.2, y = 80.5, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76079, itemID = 205987, kp = 3, zone = 2133, x = 48.30, y = 21.95, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76078, itemID = 205986, kp = 3, zone = 2133, x = 57.15, y = 54.64, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76080, itemID = 205988, kp = 3, zone = 2133, x = 27.53, y = 42.87, note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, discoveries = {
                S{ label = "Hidden Master: Grekka Anvilsmash", questID = 70250, kp = 5, zone = 2022, x = 43.32, y = 66.60, note = MASTER_NOTE },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_100_artisan_s_mettle_preferred_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_150_artisan_s_mettle_valued_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_200_artisan_s_mettle_esteemed_rep"] },
            } },
            { key = "enchanting", label = L["Enchanting"], skillLine = 2825, weekly = {
                TR{ itemID = 194702, questID = 74110, kp = 1, note = L["ProfKnowledge_TreatiseNote"], zone = LOC.treatise.zone, x = LOC.treatise.x, y = LOC.treatise.y, mainMenuOrder = 5 },
                WQ{ questIDs = { 75150, 75865, 77910, 77937, 66884, 66900, 66935, 72423, 72155, 72172, 72173, 72175 }, label = "Draconic Enchanter's Script", kp = 3, note = L["ProfKnowledge_WeeklyProfessionQuest"], rowKey = "df_ench_draconic_weekly", mainMenuOrder = 1, preferFallbackLabel = true, questLocations = QuestLocations({ 75150, 75865 }, LOC.kayann, { 77910 }, LOC.dustmongerTopuiz, { 77937 }, LOC.magnolia, { 66884, 66900, 72423 }, LOC.temnaayu, { 66935 }, LOC.gnoklin, { 72155, 72172, 72173, 72175 }, LOC.soragosa) },
                WD{ questIDs = { 66377, 66378, 70514, 70515 }, label = "Draconic Enchanting Drops", kp = 1, required = 4, mode = "count", note = WEEKLY_DROP_NOTE, rowKey = "df_ench_drops", mainMenuOrder = 2, preferFallbackLabel = true },
            }, darkmoon = {
                DMF{ label = L["ProfKnowledge_DMF_Enchanting"], questID = 29510, kp = 3, zone = 407, x = 53.2, y = 75.9, note = L["ProfKnowledge_DMFNote"], rowKey = "df_ench_dmf", mainMenuLabel = L["DMF_Ench_Label"] },
            }, treasures = {
                T{ questID = 70320, itemID = 198798, kp = 3, zone = 2022, x = 57.5, y = 83.6, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70283, itemID = 198675, kp = 3, zone = 2022, x = 68.0, y = 26.8, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70272, itemID = 201012, kp = 3, zone = 2022, x = 57.5, y = 58.5, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70291, itemID = 198689, kp = 3, zone = 2023, x = 61.4, y = 67.6, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70336, itemID = 198799, kp = 3, zone = 2024, x = 38.5, y = 59.2, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70290, itemID = 201013, kp = 3, zone = 2024, x = 45.1, y = 61.2, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70298, itemID = 198694, kp = 3, zone = 2024, x = 21.0, y = 45.0, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70342, itemID = 198800, kp = 3, zone = 2025, x = 59.9, y = 70.4, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75508, itemID = 204990, kp = 3, zone = 2133, x = 48.00, y = 17.00, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75510, itemID = 205001, kp = 3, zone = 2133, x = 36.66, y = 69.33, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75509, itemID = 204999, kp = 3, zone = 2133, x = 62.39, y = 53.80, note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, discoveries = {
                S{ label = "Hidden Master: Shalasar Glimmerdusk", questID = 70251, kp = 5, zone = 2023, x = 62.42, y = 18.70, note = MASTER_NOTE },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_100_artisan_s_mettle_preferred_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_150_artisan_s_mettle_valued_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_200_artisan_s_mettle_esteemed_rep"] },
            } },
            { key = "engineering", label = L["Engineering"], skillLine = 2827, weekly = {
                TR{ itemID = 198510, questID = 74111, kp = 1, note = L["ProfKnowledge_TreatiseNote"], zone = LOC.treatise.zone, x = LOC.treatise.x, y = LOC.treatise.y, mainMenuOrder = 3 },
                WQ{ questIDs = { 70591, 75575, 75608, 77891, 77938, 66890, 66891, 66942, 72396, 70539, 70540, 70545, 70557 }, label = "Draconic Engineering Details", kp = 2, note = L["ProfKnowledge_WeeklyProfessionQuest"], rowKey = "df_eng_draconic_weekly", mainMenuOrder = 1, preferFallbackLabel = true, questLocations = QuestLocations({ 70591 }, LOC.azley, { 75575, 75608 }, LOC.kayann, { 77891, 77938 }, LOC.magnolia, { 66890, 72396 }, LOC.dothenos, { 66891, 66942 }, LOC.gnoklin, { 70539, 70540, 70545, 70557 }, LOC.clinkyclick) },
                WD{ questIDs = { 66379, 66380, 70516, 70517 }, label = "Draconic Engineering Drops", kp = 1, required = 4, mode = "count", note = WEEKLY_DROP_NOTE, rowKey = "df_eng_drops", mainMenuOrder = 2, preferFallbackLabel = true },
            }, darkmoon = {
                DMF{ label = L["ProfKnowledge_DMF_Engineering"], questID = 29511, kp = 3, zone = 407, x = 49.3, y = 60.8, note = L["ProfKnowledge_DMFNote"], rowKey = "df_eng_dmf", mainMenuLabel = L["DMF_Eng_Label"] },
            }, treasures = {
                T{ questID = 70270, itemID = 201014, kp = 3, zone = 2022, x = 56.0, y = 44.9, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70275, itemID = 198789, kp = 3, zone = 2022, x = 49.09, y = 77.54, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75186, itemID = 204475, kp = 3, zone = 2133, x = 37.82, y = 58.83, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75184, itemID = 204471, kp = 3, zone = 2133, x = 50.51, y = 47.93, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75431, itemID = 204853, kp = 3, zone = 2133, x = 49.44, y = 79.01, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75430, itemID = 204850, kp = 3, zone = 2133, x = 57.65, y = 73.94, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75183, itemID = 204470, kp = 3, zone = 2133, x = 48.17, y = 27.93, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75188, itemID = 204480, kp = 3, zone = 2133, x = 49.87, y = 59.25, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75180, itemID = 204469, kp = 3, zone = 2133, x = 48.48, y = 48.64, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75433, itemID = 204855, kp = 3, zone = 2133, x = 48.10, y = 16.59, note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, discoveries = {
                S{ label = "Hidden Master: Frizz Buzzcrank", questID = 70252, kp = 5, zone = 2024, x = 17.8, y = 21.7, note = MASTER_NOTE },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_100_artisan_s_mettle_preferred_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_150_artisan_s_mettle_valued_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_200_artisan_s_mettle_esteemed_rep"] },
            } },
            { key = "herbalism", label = L["Herbalism"], skillLine = 2832, weekly = {
                TR{ itemID = 194704, questID = 74107, kp = 1, note = L["ProfKnowledge_TreatiseNote"], zone = LOC.treatise.zone, x = LOC.treatise.x, y = LOC.treatise.y, mainMenuOrder = 4 },
                WQ{ questIDs = { 70613, 70614, 70615, 70616 }, label = "Draconic Herbalism Field Notes", kp = 3, note = L["ProfKnowledge_WeeklyProfessionQuest"], rowKey = "df_herb_draconic_weekly", mainMenuOrder = 1, preferFallbackLabel = true, questLocations = QuestLocations({ 70613, 70614, 70615, 70616 }, LOC.agrikus) },
                WQ{ questIDs = { 71857, 71858, 71859, 71860, 71861 }, itemID = 200677, kp = 1, required = 5, mode = "count", note = L["ProfKnowledge_GatherFive"], rowKey = "df_herb_gathering", mainMenuOrder = 2 },
                WQ{ questID = 71864, itemID = 200678, kp = 3, note = L["ProfKnowledge_GatherBonus"], rowKey = "df_herb_bonus", mainMenuOrder = 3 },
            }, darkmoon = {
                DMF{ label = L["ProfKnowledge_DMF_Herbalism"], questID = 29514, kp = 3, zone = 407, x = 55.0, y = 70.8, note = L["ProfKnowledge_DMFNote"], rowKey = "df_herb_dmf", mainMenuLabel = L["DMF_Herb_Label"] },
            }, discoveries = {
                S{ label = "Hidden Master: Hua Greenpaw", questID = 70253, kp = 10, zone = 2023, x = 58.42, y = 50.04, note = MASTER_NOTE },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_100_artisan_s_mettle_preferred_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_150_artisan_s_mettle_valued_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_200_artisan_s_mettle_esteemed_rep"] },
            } },
            { key = "inscription", label = L["Inscription"], skillLine = 2828, weekly = {
                TR{ itemID = 194699, questID = 74105, kp = 1, note = L["ProfKnowledge_TreatiseNote"], zone = LOC.treatise.zone, x = LOC.treatise.x, y = LOC.treatise.y, mainMenuOrder = 3 },
                WQ{ questIDs = { 70592, 75149, 75573, 77889, 77914, 66943, 66944, 66945, 72438, 70558, 70559, 70560, 70561 }, label = "Draconic Scribe's Glyphs", kp = 3, note = L["ProfKnowledge_WeeklyProfessionQuest"], rowKey = "df_insc_draconic_weekly", mainMenuOrder = 1, preferFallbackLabel = true, questLocations = QuestLocations({ 70592 }, LOC.azley, { 75149, 75573 }, LOC.kayann, { 77889, 77914 }, LOC.magnolia, { 66943, 66945, 72438 }, LOC.dothenos, { 66944 }, LOC.gnoklin, { 70558, 70559, 70560, 70561 }, LOC.talendara) },
                WD{ questIDs = { 66375, 66376, 70518, 70519 }, label = "Draconic Inscription Drops", kp = 1, required = 4, mode = "count", note = WEEKLY_DROP_NOTE, rowKey = "df_insc_drops", mainMenuOrder = 2, preferFallbackLabel = true },
            }, darkmoon = {
                DMF{ label = L["ProfKnowledge_DMF_Inscription"], questID = 29515, kp = 3, zone = 407, x = 53.3, y = 75.8, note = L["ProfKnowledge_DMFNote"], rowKey = "df_insc_dmf", mainMenuLabel = L["DMF_Insc_Label"] },
            }, treasures = {
                T{ questID = 70306, itemID = 198704, kp = 3, zone = 2022, x = 67.87, y = 57.96, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70307, itemID = 198703, kp = 3, zone = 2023, x = 85.7, y = 25.2, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70297, itemID = 198693, kp = 3, zone = 2024, x = 46.2, y = 23.9, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70293, itemID = 198686, kp = 3, zone = 2024, x = 43.7, y = 30.9, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70281, itemID = 198669, kp = 3, zone = 2112, x = 13.2, y = 63.68, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70264, itemID = 198659, kp = 3, zone = 2025, x = 56.3, y = 41.2, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70248, itemID = 198672, kp = 3, zone = 2025, x = 47.24, y = 40.1, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70287, itemID = 201015, kp = 3, zone = 2025, x = 56.1, y = 40.9, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76120, itemID = 206034, kp = 3, zone = 2133, x = 53.01, y = 74.27, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76121, itemID = 206035, kp = 3, zone = 2133, x = 54.57, y = 20.21, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76117, itemID = 206031, kp = 3, zone = 2133, x = 36.73, y = 46.32, note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, discoveries = {
                S{ label = "Hidden Master: Lydiara Whisperfeather", questID = 70254, kp = 5, zone = 2024, x = 40.20, y = 64.3, note = MASTER_NOTE },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_100_artisan_s_mettle_preferred_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_150_artisan_s_mettle_valued_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_200_artisan_s_mettle_esteemed_rep"] },
            } },
            { key = "jewelcrafting", label = L["Jewelcrafting"], skillLine = 2829, weekly = {
                TR{ itemID = 194703, questID = 74112, kp = 1, note = L["ProfKnowledge_TreatiseNote"], zone = LOC.treatise.zone, x = LOC.treatise.x, y = LOC.treatise.y, mainMenuOrder = 3 },
                WQ{ questIDs = { 70593, 75362, 75602, 77892, 77912, 66516, 66949, 66950, 72428, 70562, 70563, 70564, 70565 }, label = "Draconic Jewelcrafting Designs", kp = 3, note = L["ProfKnowledge_WeeklyProfessionQuest"], rowKey = "df_jc_draconic_weekly", mainMenuOrder = 1, preferFallbackLabel = true, questLocations = QuestLocations({ 70593 }, LOC.azley, { 75362, 75602 }, LOC.kayann, { 77892, 77912 }, LOC.magnolia, { 66516, 72428 }, LOC.gnoklin, { 66949, 66950 }, LOC.temnaayu, { 70562, 70563, 70564, 70565 }, LOC.tuluradormi) },
                WD{ questIDs = { 66388, 66389, 70520, 70521 }, label = "Draconic Jewelcrafting Drops", kp = 1, required = 4, mode = "count", note = WEEKLY_DROP_NOTE, rowKey = "df_jc_drops", mainMenuOrder = 2, preferFallbackLabel = true },
            }, darkmoon = {
                DMF{ label = L["ProfKnowledge_DMF_Jewelcrafting"], questID = 29516, kp = 3, zone = 407, x = 55.0, y = 70.8, note = L["ProfKnowledge_DMFNote"], rowKey = "df_jc_dmf", mainMenuLabel = L["DMF_JC_Label"] },
            }, treasures = {
                T{ questID = 70292, itemID = 198687, kp = 3, zone = 2022, x = 50.4, y = 45.1, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70273, itemID = 201017, kp = 3, zone = 2022, x = 33.9, y = 63.7, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70282, itemID = 198670, kp = 3, zone = 2023, x = 25.2, y = 35.4, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70263, itemID = 198657, kp = 3, zone = 2023, x = 61.8, y = 13.0, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70277, itemID = 198664, kp = 3, zone = 2024, x = 45.0, y = 61.3, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70271, itemID = 201016, kp = 3, zone = 2024, x = 44.6, y = 61.2, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70285, itemID = 198682, kp = 3, zone = 2025, x = 59.8, y = 65.2, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70261, itemID = 198656, kp = 3, zone = 2025, x = 56.91, y = 43.72, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75654, itemID = 205219, kp = 3, zone = 2133, x = 54.41, y = 32.47, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75653, itemID = 205216, kp = 3, zone = 2133, x = 34.47, y = 45.43, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75652, itemID = 205214, kp = 3, zone = 2133, x = 40.37, y = 80.66, note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, discoveries = {
                S{ label = "Hidden Master: Pluutar", questID = 70255, kp = 5, zone = 2024, x = 46.23, y = 40.84, note = MASTER_NOTE },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_100_artisan_s_mettle_preferred_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_150_artisan_s_mettle_valued_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_200_artisan_s_mettle_esteemed_rep"] },
            } },
            { key = "leatherworking", label = L["Leatherworking"], skillLine = 2830, weekly = {
                TR{ itemID = 194700, questID = 74113, kp = 1, note = L["ProfKnowledge_TreatiseNote"], zone = LOC.treatise.zone, x = LOC.treatise.x, y = LOC.treatise.y, mainMenuOrder = 3 },
                WQ{ questIDs = { 70594, 75354, 75368, 77945, 77946, 66363, 66364, 66951, 72407, 70567, 70568, 70569, 70571 }, label = "Draconic Leatherworking Designs", kp = 3, note = L["ProfKnowledge_WeeklyProfessionQuest"], rowKey = "df_lw_draconic_weekly", mainMenuOrder = 1, preferFallbackLabel = true, questLocations = QuestLocations({ 70594 }, LOC.azley, { 75354, 75368 }, LOC.kayann, { 77945, 77946 }, LOC.magnolia, { 66363 }, LOC.dhurrel, { 66364, 66951, 72407 }, LOC.temnaayu, { 70567, 70568, 70569, 70571 }, LOC.hideshaperKoruz) },
                WD{ questIDs = { 66384, 66385, 70522, 70523 }, label = "Draconic Leatherworking Drops", kp = 1, required = 4, mode = "count", note = WEEKLY_DROP_NOTE, rowKey = "df_lw_drops", mainMenuOrder = 2, preferFallbackLabel = true },
            }, darkmoon = {
                DMF{ label = L["ProfKnowledge_DMF_Leatherworking"], questID = 29517, kp = 3, zone = 407, x = 49.3, y = 60.8, note = L["ProfKnowledge_DMFNote"], rowKey = "df_lw_dmf", mainMenuLabel = L["DMF_LW_Label"] },
            }, treasures = {
                T{ questID = 70308, itemID = 198711, kp = 3, zone = 2022, x = 39.0, y = 86.0, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70280, itemID = 198667, kp = 3, zone = 2022, x = 64.3, y = 25.4, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70300, itemID = 198696, kp = 3, zone = 2023, x = 86.4, y = 53.7, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70269, itemID = 201018, kp = 3, zone = 2024, x = 12.5, y = 49.4, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70266, itemID = 198658, kp = 3, zone = 2024, x = 16.7, y = 38.8, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70286, itemID = 198683, kp = 3, zone = 2024, x = 57.5, y = 41.3, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70294, itemID = 198690, kp = 3, zone = 2025, x = 56.8, y = 30.5, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75495, itemID = 204986, kp = 3, zone = 2133, x = 41.16, y = 48.81, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75496, itemID = 204987, kp = 3, zone = 2133, x = 45.25, y = 21.12, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 75502, itemID = 204988, kp = 3, zone = 2133, x = 49.56, y = 54.80, note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, discoveries = {
                S{ label = "Hidden Master: Erden", questID = 70256, kp = 5, zone = 2023, x = 82.45, y = 50.67, note = MASTER_NOTE },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_100_artisan_s_mettle_preferred_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_150_artisan_s_mettle_valued_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_200_artisan_s_mettle_esteemed_rep"] },
            } },
            { key = "mining", label = L["Mining"], skillLine = 2833, weekly = {
                TR{ itemID = 194708, questID = 74106, kp = 1, note = L["ProfKnowledge_TreatiseNote"], zone = LOC.treatise.zone, x = LOC.treatise.x, y = LOC.treatise.y, mainMenuOrder = 4 },
                WQ{ questIDs = { 70617, 70618, 72156, 72157 }, label = "Draconic Mining Field Notes", kp = 3, note = L["ProfKnowledge_WeeklyProfessionQuest"], rowKey = "df_mine_draconic_weekly", mainMenuOrder = 1, preferFallbackLabel = true, questLocations = QuestLocations({ 70617, 70618, 72156, 72157 }, LOC.sekita) },
                WQ{ questIDs = { 72160, 72161, 72162, 72163, 72164 }, itemID = 201300, kp = 1, required = 5, mode = "count", note = L["ProfKnowledge_MiningFive"], rowKey = "df_mine_gathering", mainMenuOrder = 2 },
                WQ{ questID = 72165, itemID = 201301, kp = 3, note = L["ProfKnowledge_MiningBonus"], rowKey = "df_mine_bonus", mainMenuOrder = 3 },
            }, darkmoon = {
                DMF{ label = L["ProfKnowledge_DMF_Mining"], questID = 29518, kp = 3, zone = 407, x = 49.3, y = 60.9, note = L["ProfKnowledge_DMFNote"], rowKey = "df_mine_dmf", mainMenuLabel = L["DMF_Mine_Label"] },
            }, discoveries = {
                S{ label = "Hidden Master: Bridgette Holdug", questID = 70258, kp = 10, zone = 2025, x = 61.42, y = 76.95, note = MASTER_NOTE },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_100_artisan_s_mettle_preferred_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_150_artisan_s_mettle_valued_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_200_artisan_s_mettle_esteemed_rep"] },
            } },
            { key = "skinning", label = L["Skinning"], skillLine = 2834, weekly = {
                TR{ itemID = 201023, questID = 74114, kp = 1, note = L["ProfKnowledge_TreatiseNote"], zone = LOC.treatise.zone, x = LOC.treatise.x, y = LOC.treatise.y, mainMenuOrder = 4 },
                WQ{ questIDs = { 70619, 70620, 72158, 72159 }, label = "Draconic Skinning Field Notes", kp = 3, note = L["ProfKnowledge_WeeklyProfessionQuest"], rowKey = "df_skin_draconic_weekly", mainMenuOrder = 1, preferFallbackLabel = true, questLocations = QuestLocations({ 70619, 70620, 72158, 72159 }, LOC.ralathor) },
                WQ{ questIDs = { 70381, 70383, 70384, 70385, 70386 }, itemID = 198837, kp = 1, required = 5, mode = "count", note = L["ProfKnowledge_SkinningFive"], rowKey = "df_skin_gathering", mainMenuOrder = 2 },
                WQ{ questID = 70389, itemID = 198841, kp = 3, note = L["ProfKnowledge_SkinningBonus"], rowKey = "df_skin_bonus", mainMenuOrder = 3 },
            }, darkmoon = {
                DMF{ label = L["ProfKnowledge_DMF_Skinning"], questID = 29519, kp = 3, zone = 407, x = 55.0, y = 70.8, note = L["ProfKnowledge_DMFNote"], rowKey = "df_skin_dmf", mainMenuLabel = L["DMF_Skin_Label"] },
            }, discoveries = {
                S{ label = "Hidden Master: Zenzi", questID = 70259, kp = 10, zone = 2022, x = 73.34, y = 69.72, note = MASTER_NOTE },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_100_artisan_s_mettle_preferred_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_150_artisan_s_mettle_valued_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_200_artisan_s_mettle_esteemed_rep"] },
            } },
            { key = "tailoring", label = L["Tailoring"], skillLine = 2831, weekly = {
                TR{ itemID = 194698, questID = 74115, kp = 1, note = L["ProfKnowledge_TreatiseNote"], zone = LOC.treatise.zone, x = LOC.treatise.x, y = LOC.treatise.y, mainMenuOrder = 3 },
                WQ{ questIDs = { 70595, 75407, 75600, 77947, 77949, 66899, 66952, 66953, 72410, 70572, 70582, 70586, 70587 }, label = "Draconic Tailoring Examples", kp = 3, note = L["ProfKnowledge_WeeklyProfessionQuest"], rowKey = "df_tail_draconic_weekly", mainMenuOrder = 1, preferFallbackLabel = true, questLocations = QuestLocations({ 70595 }, LOC.azley, { 75407, 75600 }, LOC.kayann, { 77947, 77949 }, LOC.magnolia, { 66899, 66953, 72410 }, LOC.gnoklin, { 66952 }, LOC.dothenos, { 70572, 70582, 70586, 70587 }, LOC.threadfinderFulafong) },
                WD{ questIDs = { 66386, 66387, 70524, 70525 }, label = "Draconic Tailoring Drops", kp = 1, required = 4, mode = "count", note = WEEKLY_DROP_NOTE, rowKey = "df_tail_drops", mainMenuOrder = 2, preferFallbackLabel = true },
            }, darkmoon = {
                DMF{ label = L["ProfKnowledge_DMF_Tailoring"], questID = 29520, kp = 3, zone = 407, x = 55.6, y = 55.0, note = L["ProfKnowledge_DMFNote"], rowKey = "df_tail_dmf", mainMenuLabel = L["DMF_Tail_Label"] },
            }, treasures = {
                T{ questID = 70302, itemID = 198699, kp = 3, zone = 2022, x = 74.7, y = 37.9, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70304, itemID = 198702, kp = 3, zone = 2022, x = 24.9, y = 69.7, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70295, itemID = 198692, kp = 3, zone = 2023, x = 35.34, y = 40.12, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70303, itemID = 201020, kp = 3, zone = 2023, x = 66.1, y = 52.9, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70284, itemID = 198680, kp = 3, zone = 2024, x = 16.2, y = 38.8, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70267, itemID = 198662, kp = 3, zone = 2024, x = 40.7, y = 54.5, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70288, itemID = 198684, kp = 3, zone = 2025, x = 60.4, y = 79.7, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 70372, itemID = 201019, kp = 3, zone = 2025, x = 58.6, y = 45.8, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76102, itemID = 206019, kp = 3, zone = 2133, x = 47.21, y = 48.55, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76116, itemID = 206030, kp = 3, zone = 2133, x = 44.52, y = 15.65, note = L["ProfKnowledge_TreasureNoteSkill25"] },
                T{ questID = 76110, itemID = 206025, kp = 3, zone = 2133, x = 59.11, y = 73.14, note = L["ProfKnowledge_TreasureNoteSkill25"] },
            }, discoveries = {
                S{ label = "Hidden Master: Elysa Raywinder", questID = 70260, kp = 5, zone = VALDRAKKEN, x = 27.96, y = 45.79, note = MASTER_NOTE },
            }, books = {
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_100_artisan_s_mettle_preferred_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_150_artisan_s_mettle_valued_rep"] },
                Ref{ kp = 15, zone = 13862, x = 35.6, y = 59.0, note = L["ProfKnowledge_Note_rabul_valdrakken_200_artisan_s_mettle_esteemed_rep"] },
            } },
        },
}

ns.RegisterProfessionExpansion(DRAGONFLIGHT_EXPANSION)
