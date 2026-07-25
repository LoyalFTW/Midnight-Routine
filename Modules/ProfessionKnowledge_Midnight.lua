local _, ns = ...
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)

local T, S, WQ, WD, DMF = ns.T, ns.S, ns.WQ, ns.WD, ns.DMF

local function KnowsLureRecipe(itemID)
    if not itemID then return true end
    if C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfoForItemID then
        return C_TradeSkillUI.GetRecipeInfoForItemID(itemID) ~= nil
    end
    return true
end

local PROFESSIONS = {
    { key = "alchemy", label = L["Alchemy"], color = { 0.20, 0.73, 1.00 }, skillLine = 2906, catchupCurrency = 3189, sections = {
        { key = "discoveries", label = L["ProfKnowledge_Section_Discoveries"], entries = {
            T{ itemID = 238538, questID = 89117, kp = 3, zone = 2393, x = 47.8, y = 51.6 }, T{ itemID = 238536, questID = 89115, kp = 3, zone = 2393, x = 49.1, y = 75.6 },
            T{ itemID = 238532, questID = 89111, kp = 3, zone = 2393, x = 45.1, y = 44.8 }, T{ itemID = 238535, questID = 89114, kp = 3, zone = 2437, x = 40.4, y = 51.0 },
            T{ itemID = 238537, questID = 89116, kp = 3, zone = 2536, x = 49.1, y = 23.1 }, T{ itemID = 238534, questID = 89113, kp = 3, zone = 2413, x = 34.7, y = 24.7 },
            T{ itemID = 238533, questID = 89112, kp = 3, zone = 2444, x = 41.8, y = 40.5 }, T{ itemID = 238539, questID = 89118, kp = 3, zone = 2405, x = 32.8, y = 43.3 },
        } },
        { key = "studies", label = L["ProfKnowledge_Section_Studies"], entries = { S{ itemID = 262645, questID = 93794, kp = 10, zone = 2405, x = 52.6, y = 72.9, note = L["ProfKnowledge_StudyUnlock"] } } },
        { key = "weekly", label = L["ProfKnowledge_Section_Weekly"], entries = {
            WQ{ itemID = 245755, questID = 95127, kp = 1, zone = 2393, x = 45.0, y = 55.6, note = L["ProfKnowledge_TreatiseNote"], rowKey = "alch_treatise", mainMenuLabel = L["Alch_Treatise"], mainMenuOrder = 3 },
            WQ{ itemID = 263454, questID = 93690, kp = 1, zone = 2393, x = 45.0, y = 55.2, note = L["ProfKnowledge_ServiceQuest"], rowKey = "alch_notebook", mainMenuLabel = L["Alch_Quest"], mainMenuOrder = 1 },
            WD{ itemID = 259188, questID = 93528, kp = 1, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "alch_drops", mainMenuLabel = L["Alch_Drops"], mainMenuOrder = 2 }, WD{ itemID = 259189, questID = 93529, kp = 1, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "alch_drops", mainMenuLabel = L["Alch_Drops"], mainMenuOrder = 2 },
        } },
        { key = "darkmoon", label = L["ProfKnowledge_Section_Darkmoon"], entries = { DMF{ label = L["ProfKnowledge_DMF_Alchemy"], questID = 29506, kp = 3, zone = 407, x = 50.5, y = 69.6, note = L["ProfKnowledge_DMFNote"], rowKey = "alch_dmf", mainMenuLabel = L["DMF_Alch_Label"] } } },
    } },
    { key = "blacksmithing", label = L["Blacksmithing"], color = { 0.67, 0.67, 0.73 }, skillLine = 2907, catchupCurrency = 3199, sections = {
        { key = "discoveries", label = L["ProfKnowledge_Section_Discoveries"], entries = {
            T{ itemID = 238546, questID = 89183, kp = 3, zone = 2393, x = 49.3, y = 61.3 }, T{ itemID = 238547, questID = 89184, kp = 3, zone = 2393, x = 48.5, y = 74.8 },
            T{ itemID = 238540, questID = 89177, kp = 3, zone = 2393, x = 26.9, y = 60.3 }, T{ itemID = 238543, questID = 89180, kp = 3, zone = 2395, x = 56.8, y = 40.7 },
            T{ itemID = 238541, questID = 89178, kp = 3, zone = 2395, x = 48.3, y = 75.7 }, T{ itemID = 238542, questID = 89179, kp = 3, zone = 2536, x = 33.2, y = 65.8 },
            T{ itemID = 238545, questID = 89182, kp = 3, zone = 2413, x = 66.3, y = 50.8 }, T{ itemID = 238544, questID = 89181, kp = 3, zone = 2444, x = 30.6, y = 68.9 },
        } },
        { key = "studies", label = L["ProfKnowledge_Section_Studies"], entries = { S{ itemID = 262644, questID = 93795, kp = 10, zone = 2405, x = 52.6, y = 72.9, note = L["ProfKnowledge_StudyUnlock"] } } },
        { key = "weekly", label = L["ProfKnowledge_Section_Weekly"], entries = {
            WQ{ itemID = 245763, questID = 95128, kp = 1, zone = 2393, x = 45.0, y = 55.6, note = L["ProfKnowledge_TreatiseNote"], rowKey = "bs_treatise", mainMenuLabel = L["BS_Treatise"], mainMenuOrder = 3 },
            WQ{ itemID = 263455, questID = 93691, kp = 2, zone = 2393, x = 45.0, y = 55.2, note = L["ProfKnowledge_ServiceQuest"], rowKey = "bs_notebook", mainMenuLabel = L["BS_Quest"], mainMenuOrder = 1 },
            WD{ itemID = 259190, questID = 93530, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "bs_drops", mainMenuLabel = L["BS_Drops"], mainMenuOrder = 2 }, WD{ itemID = 259191, questID = 93531, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "bs_drops", mainMenuLabel = L["BS_Drops"], mainMenuOrder = 2 },
        } },
        { key = "darkmoon", label = L["ProfKnowledge_Section_Darkmoon"], entries = { DMF{ label = L["ProfKnowledge_DMF_Blacksmithing"], questID = 29508, kp = 3, zone = 407, x = 51.1, y = 82.0, note = L["ProfKnowledge_DMFNote"], rowKey = "bs_dmf", mainMenuLabel = L["DMF_BS_Label"] } } },
    } },
    { key = "enchanting", label = L["Enchanting"], color = { 0.73, 0.47, 1.00 }, skillLine = 2909, catchupCurrency = 3198, sections = {
        { key = "discoveries", label = L["ProfKnowledge_Section_Discoveries"], entries = {
            T{ itemID = 238555, questID = 89107, kp = 3, zone = 2395, x = 63.4, y = 32.6 }, T{ itemID = 238551, questID = 89103, kp = 3, zone = 2395, x = 60.8, y = 53.1 },
            T{ itemID = 238549, questID = 89101, kp = 3, zone = 2395, x = 40.2, y = 61.2 }, T{ itemID = 238554, questID = 89106, kp = 3, zone = 2437, x = 40.4, y = 51.2 },
            T{ itemID = 238548, questID = 89100, kp = 3, zone = 2536, x = 49.1, y = 22.7 }, T{ itemID = 238553, questID = 89105, kp = 3, zone = 2413, x = 65.8, y = 50.2 },
            T{ itemID = 238552, questID = 89104, kp = 3, zone = 2413, x = 37.7, y = 65.3 }, T{ itemID = 238550, questID = 89102, kp = 3, zone = 2405, x = 35.5, y = 58.8 },
        } },
        { key = "studies", label = L["ProfKnowledge_Section_Studies"], entries = {
            S{ itemID = 257600, questID = 92374, kp = 10, zone = 2395, x = 43.4, y = 47.4, note = L["ProfKnowledge_StudyUnlock"] },
            S{ itemID = 250445, questID = 92186, kp = 10, zone = 2437, x = 31.6, y = 26.3, note = L["ProfKnowledge_StudyUnlock"] },
        } },
        { key = "weekly", label = L["ProfKnowledge_Section_Weekly"], entries = {
            WQ{ itemID = 245759, questID = 95129, kp = 1, zone = 2393, x = 45.0, y = 55.6, note = L["ProfKnowledge_TreatiseNote"], rowKey = "ench_treatise", mainMenuLabel = L["Ench_Treatise"], mainMenuOrder = 5 },
            WQ{ itemID = 263464, questIDs = { 93699, 93698, 93697 }, kp = 3, zone = 2393, x = 47.8, y = 53.8, note = L["ProfKnowledge_TrainerQuest"], rowKey = "ench_notebook", mainMenuLabel = L["Ench_Quest"], mainMenuOrder = 1 },
            WD{ itemID = 267654, questIDs = { 95048, 95049, 95050, 95051, 95052 }, kp = 1, required = 5, mode = "count", note = L["ProfKnowledge_DisenchantFive"], rowKey = "ench_de_essence", mainMenuLabel = L["Ench_DE_Essence"], mainMenuOrder = 3 },
            WD{ itemID = 267655, questID = 95053, kp = 4, note = L["ProfKnowledge_DisenchantBonus"], rowKey = "ench_de_shard", mainMenuLabel = L["Ench_DE_Shard"], mainMenuOrder = 4 },
            WD{ itemID = 259192, questID = 93532, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "ench_drops", mainMenuLabel = L["Ench_Drops"], mainMenuOrder = 2 }, WD{ itemID = 259193, questID = 93533, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "ench_drops", mainMenuLabel = L["Ench_Drops"], mainMenuOrder = 2 },
        } },
        { key = "darkmoon", label = L["ProfKnowledge_Section_Darkmoon"], entries = { DMF{ label = L["ProfKnowledge_DMF_Enchanting"], questID = 29510, kp = 3, zone = 407, x = 53.2, y = 75.9, note = L["ProfKnowledge_DMFNote"], rowKey = "ench_dmf", mainMenuLabel = L["DMF_Ench_Label"] } } },
    } },
    { key = "engineering", label = L["Engineering"], color = { 1.00, 0.80, 0.27 }, skillLine = 2910, catchupCurrency = 3197, sections = {
        { key = "discoveries", label = L["ProfKnowledge_Section_Discoveries"], entries = {
            T{ itemID = 238562, questID = 89139, kp = 3, zone = 2393, x = 51.2, y = 57.1 }, T{ itemID = 238556, questID = 89133, kp = 3, zone = 2393, x = 51.4, y = 74.6 },
            T{ itemID = 238558, questID = 89135, kp = 3, zone = 2395, x = 39.5, y = 45.8 }, T{ itemID = 238561, questID = 89138, kp = 3, zone = 2536, x = 65.1, y = 34.5 },
            T{ itemID = 238563, questID = 89140, kp = 3, zone = 2437, x = 34.2, y = 87.9 }, T{ itemID = 238559, questID = 89136, kp = 3, zone = 2413, x = 67.9, y = 49.8 },
            T{ itemID = 238560, questID = 89137, kp = 3, zone = 2444, x = 54.0, y = 51.0 }, T{ itemID = 238557, questID = 89134, kp = 3, zone = 2444, x = 29.0, y = 39.2 },
        } },
        { key = "studies", label = L["ProfKnowledge_Section_Studies"], entries = { S{ itemID = 262646, questID = 93796, kp = 10, zone = 2405, x = 52.6, y = 72.9, note = L["ProfKnowledge_StudyUnlock"] } } },
        { key = "weekly", label = L["ProfKnowledge_Section_Weekly"], entries = {
            WQ{ itemID = 245809, questID = 95138, kp = 1, zone = 2393, x = 45.0, y = 55.6, note = L["ProfKnowledge_TreatiseNote"], rowKey = "eng_treatise", mainMenuLabel = L["Eng_Treatise"], mainMenuOrder = 3 },
            WQ{ itemID = 263456, questID = 93692, kp = 1, zone = 2393, x = 45.0, y = 55.2, note = L["ProfKnowledge_ServiceQuest"], rowKey = "eng_notebook", mainMenuLabel = L["Eng_Quest"], mainMenuOrder = 1 },
            WD{ itemID = 259194, questID = 93534, kp = 1, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "eng_drops", mainMenuLabel = L["Eng_Drops"], mainMenuOrder = 2 }, WD{ itemID = 259195, questID = 93535, kp = 1, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "eng_drops", mainMenuLabel = L["Eng_Drops"], mainMenuOrder = 2 },
        } },
        { key = "darkmoon", label = L["ProfKnowledge_Section_Darkmoon"], entries = { DMF{ label = L["ProfKnowledge_DMF_Engineering"], questID = 29511, kp = 3, zone = 407, x = 49.3, y = 60.8, note = L["ProfKnowledge_DMFNote"], rowKey = "eng_dmf", mainMenuLabel = L["DMF_Eng_Label"] } } },
    } },
    { key = "herbalism", label = L["Herbalism"], color = { 0.33, 0.80, 0.27 }, skillLine = 2912, catchupCurrency = 3196, sections = {
        { key = "discoveries", label = L["ProfKnowledge_Section_Discoveries"], entries = {
            T{ itemID = 238470, questID = 89160, kp = 3, zone = 2393, x = 49.0, y = 75.8 }, T{ itemID = 238472, questID = 89158, kp = 3, zone = 2395, x = 64.2, y = 30.4 },
            T{ itemID = 238469, questID = 89161, kp = 3, zone = 2437, x = 41.9, y = 45.9 }, T{ itemID = 238473, questID = 89157, kp = 3, zone = 2437, x = 41.8, y = 45.9, altZone = 2413, altX = 76.1, altY = 51.1 },
            T{ itemID = 238475, questID = 89155, kp = 3, zone = 2413, x = 51.1, y = 55.7 }, T{ itemID = 238468, questID = 89162, kp = 3, zone = 2413, x = 38.1, y = 66.9 },
            T{ itemID = 238471, questID = 89159, kp = 3, zone = 2413, x = 36.6, y = 25.0 }, T{ itemID = 238474, questID = 89156, kp = 3, zone = 2405, x = 34.6, y = 57.0 },
        } },
        { key = "studies", label = L["ProfKnowledge_Section_Studies"], entries = {
            S{ itemID = 258410, questID = 93411, kp = 10, zone = 2413, x = 51.0, y = 50.8, note = L["ProfKnowledge_StudyUnlock"] },
            S{ itemID = 250443, questID = 92174, kp = 10, zone = 2437, x = 31.6, y = 26.3, note = L["ProfKnowledge_StudyUnlock"] },
        } },
        { key = "weekly", label = L["ProfKnowledge_Section_Weekly"], entries = {
            WQ{ itemID = 245761, questID = 95130, kp = 1, zone = 2393, x = 45.0, y = 55.6, note = L["ProfKnowledge_TreatiseNote"], rowKey = "herb_treatise", mainMenuLabel = L["Herb_Treatise"], mainMenuOrder = 4 },
            WQ{ itemID = 263462, questIDs = { 93700, 93701, 93702, 93703, 93704 }, kp = 3, zone = 2393, x = 48.3, y = 51.4, note = L["ProfKnowledge_TrainerQuest"], rowKey = "herb_notebook", mainMenuLabel = L["Herb_Quest"], mainMenuOrder = 1 },
            WD{ itemID = 238465, questIDs = { 81425, 81426, 81427, 81428, 81429 }, kp = 1, required = 5, mode = "count", note = L["ProfKnowledge_GatherFive"], rowKey = "herb_drops", mainMenuLabel = L["Herb_Plumes"], mainMenuOrder = 2 },
            WD{ itemID = 238466, questID = 81430, kp = 4, note = L["ProfKnowledge_GatherBonus"], rowKey = "herb_tail", mainMenuLabel = L["Herb_Tail"], mainMenuOrder = 3 },
        } },
        { key = "darkmoon", label = L["ProfKnowledge_Section_Darkmoon"], entries = { DMF{ label = L["ProfKnowledge_DMF_Herbalism"], questID = 29514, kp = 3, zone = 407, x = 55.0, y = 70.8, note = L["ProfKnowledge_DMFNote"], rowKey = "herb_dmf", mainMenuLabel = L["DMF_Herb_Label"] } } },
    } },
    { key = "inscription", label = L["Inscription"], color = { 0.27, 0.87, 0.67 }, skillLine = 2913, catchupCurrency = 3195, sections = {
        { key = "discoveries", label = L["ProfKnowledge_Section_Discoveries"], entries = {
            T{ itemID = 238578, questID = 89073, kp = 3, zone = 2393, x = 47.7, y = 50.3 }, T{ itemID = 238579, questID = 89074, kp = 3, zone = 2395, x = 40.4, y = 61.3 },
            T{ itemID = 238577, questID = 89072, kp = 3, zone = 2395, x = 39.3, y = 45.4 }, T{ itemID = 238574, questID = 89069, kp = 3, zone = 2395, x = 48.3, y = 75.6 },
            T{ itemID = 238573, questID = 89068, kp = 3, zone = 2437, x = 40.5, y = 49.4 }, T{ itemID = 238575, questID = 89070, kp = 3, zone = 2413, x = 52.4, y = 52.6 },
            T{ itemID = 238576, questID = 89071, kp = 3, zone = 2413, x = 52.7, y = 50.0 }, T{ itemID = 238572, questID = 89067, kp = 3, zone = 2444, x = 60.7, y = 84.1 },
        } },
        { key = "studies", label = L["ProfKnowledge_Section_Studies"], entries = { S{ itemID = 258411, questID = 93412, kp = 10, zone = 2413, x = 51.0, y = 50.8, note = L["ProfKnowledge_StudyUnlock"] } } },
        { key = "weekly", label = L["ProfKnowledge_Section_Weekly"], entries = {
            WQ{ itemID = 245757, questID = 95131, kp = 1, zone = 2393, x = 45.0, y = 55.6, note = L["ProfKnowledge_TreatiseNote"], rowKey = "insc_treatise", mainMenuLabel = L["Insc_Treatise"], mainMenuOrder = 3 },
            WQ{ itemID = 263457, questID = 93693, kp = 4, zone = 2393, x = 45.0, y = 55.2, note = L["ProfKnowledge_ServiceQuest"], rowKey = "insc_notebook", mainMenuLabel = L["Insc_Quest"], mainMenuOrder = 1 },
            WD{ itemID = 259196, questID = 93536, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "insc_drops", mainMenuLabel = L["Insc_Drops"], mainMenuOrder = 2 }, WD{ itemID = 259197, questID = 93537, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "insc_drops", mainMenuLabel = L["Insc_Drops"], mainMenuOrder = 2 },
        } },
        { key = "darkmoon", label = L["ProfKnowledge_Section_Darkmoon"], entries = { DMF{ label = L["ProfKnowledge_DMF_Inscription"], questID = 29515, kp = 3, zone = 407, x = 53.3, y = 75.8, note = L["ProfKnowledge_DMFNote"], rowKey = "insc_dmf", mainMenuLabel = L["DMF_Insc_Label"] } } },
    } },
    { key = "jewelcrafting", label = L["Jewelcrafting"], color = { 1.00, 0.47, 0.60 }, skillLine = 2914, catchupCurrency = 3194, sections = {
        { key = "discoveries", label = L["ProfKnowledge_Section_Discoveries"], entries = {
            T{ itemID = 238580, questID = 89122, kp = 3, zone = 2393, x = 50.6, y = 56.5 }, T{ itemID = 238585, questID = 89127, kp = 3, zone = 2393, x = 55.5, y = 48.0 },
            T{ itemID = 238582, questID = 89124, kp = 3, zone = 2393, x = 28.6, y = 46.5 }, T{ itemID = 238583, questID = 89125, kp = 3, zone = 2395, x = 56.7, y = 40.9 },
            T{ itemID = 238587, questID = 89129, kp = 3, zone = 2395, x = 39.7, y = 38.8 }, T{ itemID = 238581, questID = 89123, kp = 3, zone = 2444, x = 30.6, y = 69.0 },
            T{ itemID = 238586, questID = 89128, kp = 3, zone = 2444, x = 54.2, y = 51.2 }, T{ itemID = 238584, questID = 89126, kp = 3, zone = 2444, x = 62.9, y = 53.5 },
        } },
        { key = "studies", label = L["ProfKnowledge_Section_Studies"], entries = { S{ itemID = 257599, questID = 93222, kp = 10, zone = 2395, x = 43.4, y = 47.4, note = L["ProfKnowledge_StudyUnlock"] } } },
        { key = "weekly", label = L["ProfKnowledge_Section_Weekly"], entries = {
            WQ{ itemID = 245760, questID = 95133, kp = 1, zone = 2393, x = 45.0, y = 55.6, note = L["ProfKnowledge_TreatiseNote"], rowKey = "jc_treatise", mainMenuLabel = L["JC_Treatise"], mainMenuOrder = 3 },
            WQ{ itemID = 263458, questID = 93694, kp = 3, zone = 2393, x = 45.0, y = 55.2, note = L["ProfKnowledge_ServiceQuest"], rowKey = "jc_notebook", mainMenuLabel = L["JC_Quest"], mainMenuOrder = 1 },
            WD{ itemID = 259199, questID = 93539, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "jc_drops", mainMenuLabel = L["JC_Drops"], mainMenuOrder = 2 }, WD{ itemID = 259198, questID = 93538, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "jc_drops", mainMenuLabel = L["JC_Drops"], mainMenuOrder = 2 },
        } },
        { key = "darkmoon", label = L["ProfKnowledge_Section_Darkmoon"], entries = { DMF{ label = L["ProfKnowledge_DMF_Jewelcrafting"], questID = 29516, kp = 3, zone = 407, x = 55.0, y = 70.8, note = L["ProfKnowledge_DMFNote"], rowKey = "jc_dmf", mainMenuLabel = L["DMF_JC_Label"] } } },
    } },
    { key = "leatherworking", label = L["Leatherworking"], color = { 0.80, 0.53, 0.20 }, skillLine = 2915, catchupCurrency = 3193, sections = {
        { key = "discoveries", label = L["ProfKnowledge_Section_Discoveries"], entries = {
            T{ itemID = 238595, questID = 89096, kp = 3, zone = 2393, x = 44.8, y = 56.2 }, T{ itemID = 238591, questID = 89092, kp = 3, zone = 2536, x = 45.2, y = 45.3 },
            T{ itemID = 238588, questID = 89089, kp = 3, zone = 2437, x = 33.1, y = 78.9 }, T{ itemID = 238590, questID = 89091, kp = 3, zone = 2437, x = 30.8, y = 84.1 },
            T{ itemID = 238589, questID = 89090, kp = 3, zone = 2405, x = 34.8, y = 56.9 }, T{ itemID = 238593, questID = 89094, kp = 3, zone = 2413, x = 51.8, y = 51.3 },
            T{ itemID = 238594, questID = 89095, kp = 3, zone = 2413, x = 36.1, y = 25.2 }, T{ itemID = 238592, questID = 89093, kp = 3, zone = 2444, x = 53.8, y = 51.6 },
        } },
        { key = "studies", label = L["ProfKnowledge_Section_Studies"], entries = { S{ itemID = 250922, questID = 92371, kp = 10, zone = 2437, x = 45.8, y = 65.8, note = L["ProfKnowledge_StudyUnlock"] } } },
        { key = "weekly", label = L["ProfKnowledge_Section_Weekly"], entries = {
            WQ{ itemID = 245758, questID = 95134, kp = 1, zone = 2393, x = 45.0, y = 55.6, note = L["ProfKnowledge_TreatiseNote"], rowKey = "lw_treatise", mainMenuLabel = L["LW_Treatise"], mainMenuOrder = 3 },
            WQ{ itemID = 263459, questID = 93695, kp = 2, zone = 2393, x = 45.0, y = 55.2, note = L["ProfKnowledge_ServiceQuest"], rowKey = "lw_notebook", mainMenuLabel = L["LW_Quest"], mainMenuOrder = 1 },
            WD{ itemID = 259200, questID = 93540, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "lw_drops", mainMenuLabel = L["LW_Drops"], mainMenuOrder = 2 }, WD{ itemID = 259201, questID = 93541, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "lw_drops", mainMenuLabel = L["LW_Drops"], mainMenuOrder = 2 },
        } },
        { key = "darkmoon", label = L["ProfKnowledge_Section_Darkmoon"], entries = { DMF{ label = L["ProfKnowledge_DMF_Leatherworking"], questID = 29517, kp = 3, zone = 407, x = 49.3, y = 60.8, note = L["ProfKnowledge_DMFNote"], rowKey = "lw_dmf", mainMenuLabel = L["DMF_LW_Label"] } } },
    } },
    { key = "mining", label = L["Mining"], color = { 0.80, 0.80, 0.80 }, skillLine = 2916, catchupCurrency = 3192, sections = {
        { key = "discoveries", label = L["ProfKnowledge_Section_Discoveries"], entries = {
            T{ itemID = 238599, questID = 89147, kp = 3, zone = 2395, x = 38.0, y = 45.3 }, T{ itemID = 238597, questID = 89145, kp = 3, zone = 2437, x = 41.9, y = 46.3 },
            T{ itemID = 238603, questID = 89151, kp = 3, zone = 2413, x = 38.8, y = 65.9 }, T{ itemID = 238601, questID = 89149, kp = 3, zone = 2536, x = 33.6, y = 66.0 },
            T{ itemID = 238602, questID = 89150, kp = 3, zone = 2444, x = 34.2, y = 75.9 }, T{ itemID = 238600, questID = 89148, kp = 3, zone = 2444, x = 28.7, y = 38.6 },
            T{ itemID = 238598, questID = 89146, kp = 3, zone = 2444, x = 54.2, y = 51.6 }, T{ itemID = 238596, questID = 89144, kp = 3, zone = 2444, x = 30.0, y = 69.0 },
        } },
        { key = "studies", label = L["ProfKnowledge_Section_Studies"], entries = {
            S{ itemID = 250924, questID = 92372, kp = 10, zone = 2437, x = 45.8, y = 65.8, note = L["ProfKnowledge_StudyUnlock"] },
            S{ itemID = 250444, questID = 92187, kp = 10, zone = 2437, x = 31.6, y = 26.3, note = L["ProfKnowledge_StudyUnlock"] },
        } },
        { key = "weekly", label = L["ProfKnowledge_Section_Weekly"], entries = {
            WQ{ itemID = 245762, questID = 95135, kp = 1, zone = 2393, x = 45.0, y = 55.6, note = L["ProfKnowledge_TreatiseNote"], rowKey = "mine_treatise", mainMenuLabel = L["Mine_Treatise"], mainMenuOrder = 4 },
            WQ{ itemID = 263463, questIDs = { 93705, 93706, 93707, 93708, 93709 }, kp = 3, zone = 2393, x = 42.6, y = 52.8, note = L["ProfKnowledge_TrainerQuest"], rowKey = "mine_notebook", mainMenuLabel = L["Mine_Quest"], mainMenuOrder = 1 },
            WD{ itemID = 237496, questIDs = { 88673, 88674, 88675, 88676, 88677 }, kp = 1, required = 5, mode = "count", note = L["ProfKnowledge_MiningFive"], rowKey = "mine_rock", mainMenuLabel = L["Mine_Rock"], mainMenuOrder = 2 },
            WD{ itemID = 237506, questID = 88678, kp = 3, note = L["ProfKnowledge_MiningBonus"], rowKey = "mine_nodule", mainMenuLabel = L["Mine_Nodule"], mainMenuOrder = 3 },
        } },
        { key = "darkmoon", label = L["ProfKnowledge_Section_Darkmoon"], entries = { DMF{ label = L["ProfKnowledge_DMF_Mining"], questID = 29518, kp = 3, zone = 407, x = 49.3, y = 60.9, note = L["ProfKnowledge_DMFNote"], rowKey = "mine_dmf", mainMenuLabel = L["DMF_Mine_Label"] } } },
    } },
    { key = "skinning", label = L["Skinning"], color = { 0.78, 0.63, 0.38 }, skillLine = 2917, catchupCurrency = 3191, sections = {
        { key = "discoveries", label = L["ProfKnowledge_Section_Discoveries"], entries = {
            T{ itemID = 238633, questID = 89171, kp = 3, zone = 2393, x = 43.2, y = 55.7 }, T{ itemID = 238635, questID = 89173, kp = 3, zone = 2395, x = 48.5, y = 76.2 },
            T{ itemID = 238632, questID = 89170, kp = 3, zone = 2437, x = 40.4, y = 36.0 }, T{ itemID = 238634, questID = 89172, kp = 3, zone = 2437, x = 33.1, y = 79.0 },
            T{ itemID = 238629, questID = 89167, kp = 3, zone = 2536, x = 45.0, y = 44.7 }, T{ itemID = 238630, questID = 89168, kp = 3, zone = 2413, x = 69.5, y = 49.2 },
            T{ itemID = 238628, questID = 89166, kp = 3, zone = 2413, x = 76.0, y = 51.0 }, T{ itemID = 238631, questID = 89169, kp = 3, zone = 2444, x = 45.5, y = 42.4 },
        } },
        { key = "studies", label = L["ProfKnowledge_Section_Studies"], entries = {
            S{ itemID = 250923, questID = 92373, kp = 10, zone = 2437, x = 45.8, y = 65.8, note = L["ProfKnowledge_StudyUnlock"] },
            S{ itemID = 250360, questID = 92188, kp = 10, zone = 2437, x = 31.6, y = 26.3, note = L["ProfKnowledge_StudyUnlock"] },
        } },
        { key = "weekly", label = L["ProfKnowledge_Section_Weekly"], entries = {
            WQ{ itemID = 245828, questID = 95136, kp = 1, zone = 2393, x = 45.0, y = 55.6, note = L["ProfKnowledge_TreatiseNote"], rowKey = "skin_treatise", mainMenuLabel = L["Skin_Treatise"], mainMenuOrder = 4 },
            WQ{ itemID = 263461, questIDs = { 93710, 93711, 93712, 93713, 93714 }, kp = 3, zone = 2393, x = 43.2, y = 55.6, note = L["ProfKnowledge_TrainerQuest"], rowKey = "skin_notebook", mainMenuLabel = L["Skin_Quest"], mainMenuOrder = 1 },
            WD{ itemID = 238625, questIDs = { 88534, 88549, 88536, 88537, 88530 }, kp = 1, required = 5, mode = "count", note = L["ProfKnowledge_SkinningFive"], rowKey = "skin_drops", mainMenuLabel = L["Skin_Drops"], mainMenuOrder = 2 },
            WD{ itemID = 238626, questID = 88529, kp = 3, note = L["ProfKnowledge_SkinningBonus"], rowKey = "skin_bone", mainMenuLabel = L["Skin_Bone"], mainMenuOrder = 3 },
        } },
        { key = "darkmoon", label = L["ProfKnowledge_Section_Darkmoon"], entries = { DMF{ label = L["ProfKnowledge_DMF_Skinning"], questID = 29519, kp = 3, zone = 407, x = 55.0, y = 70.8, note = L["ProfKnowledge_DMFNote"], rowKey = "skin_dmf", mainMenuLabel = L["DMF_Skin_Label"] } } },
        { key = "lures", label = L["Skin_Lures_Title"], entries = {
            WQ{ questID = 88545, zone = 2395, x = 41.95, y = 80.05, label = L["Skin_Lure_Eversong"], note = L["Skin_Lure_Eversong_Note"], rowKey = "lure_eversong", mainMenuLabel = L["Skin_Lure_Eversong"] },
            WQ{ questID = 88526, zone = 2437, x = 47.69, y = 53.25, label = L["Skin_Lure_Zulaman"], note = L["Skin_Lure_Zulaman_Note"], rowKey = "lure_zulaman", mainMenuLabel = L["Skin_Lure_Zulaman"], isVisible = function() return KnowsLureRecipe(238653) end },
            WQ{ questID = 88531, zone = 2413, x = 66.28, y = 47.91, label = L["Skin_Lure_Harandar"], note = L["Skin_Lure_Harandar_Note"], rowKey = "lure_harandar", mainMenuLabel = L["Skin_Lure_Harandar"], isVisible = function() return KnowsLureRecipe(238654) end },
            WQ{ questID = 88532, zone = 2405, x = 54.60, y = 65.80, label = L["Skin_Lure_Voidstorm"], note = L["Skin_Lure_Voidstorm_Note"], rowKey = "lure_voidstorm", mainMenuLabel = L["Skin_Lure_Voidstorm"], isVisible = function() return KnowsLureRecipe(238655) end },
            WQ{ questID = 88524, zone = 2405, x = 43.25, y = 82.75, label = L["Skin_Lure_Grand"], note = L["Skin_Lure_Grand_Note"], rowKey = "lure_grand", mainMenuLabel = L["Skin_Lure_Grand"], isVisible = function() return KnowsLureRecipe(238656) end },
        } },
    } },
    { key = "tailoring", label = L["Tailoring"], color = { 1.00, 0.67, 0.87 }, skillLine = 2918, catchupCurrency = 3190, sections = {
        { key = "discoveries", label = L["ProfKnowledge_Section_Discoveries"], entries = {
            T{ itemID = 238613, questID = 89079, kp = 3, zone = 2393, x = 35.8, y = 61.2 }, T{ itemID = 238618, questID = 89084, kp = 3, zone = 2393, x = 31.7, y = 68.2 },
            T{ itemID = 238614, questID = 89080, kp = 3, zone = 2395, x = 46.3, y = 34.8 }, T{ itemID = 238619, questID = 89085, kp = 3, zone = 2437, x = 40.4, y = 49.4 },
            T{ itemID = 238612, questID = 89078, kp = 3, zone = 2413, x = 70.5, y = 50.8 }, T{ itemID = 238615, questID = 89081, kp = 3, zone = 2413, x = 69.8, y = 51.0 },
            T{ itemID = 238616, questID = 89082, kp = 3, zone = 2444, x = 61.9, y = 83.7 }, T{ itemID = 238617, questID = 89083, kp = 3, zone = 2444, x = 61.4, y = 85.0 },
        } },
        { key = "studies", label = L["ProfKnowledge_Section_Studies"], entries = { S{ itemID = 257601, questID = 93201, kp = 10, zone = 2395, x = 43.4, y = 47.4, note = L["ProfKnowledge_StudyUnlock"] } } },
        { key = "weekly", label = L["ProfKnowledge_Section_Weekly"], entries = {
            WQ{ itemID = 245756, questID = 95137, kp = 1, zone = 2393, x = 45.0, y = 55.6, note = L["ProfKnowledge_TreatiseNote"], rowKey = "tail_treatise", mainMenuLabel = L["Tail_Treatise"], mainMenuOrder = 3 },
            WQ{ itemID = 263460, questID = 93696, kp = 2, zone = 2393, x = 45.0, y = 55.2, note = L["ProfKnowledge_ServiceQuest"], rowKey = "tail_notebook", mainMenuLabel = L["Tail_Quest"], mainMenuOrder = 1 },
            WD{ itemID = 259202, questID = 93542, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "tail_drops", mainMenuLabel = L["Tail_Drops"], mainMenuOrder = 2 }, WD{ itemID = 259203, questID = 93543, kp = 2, note = L["ProfKnowledge_WeeklyDrop"], rowKey = "tail_drops", mainMenuLabel = L["Tail_Drops"], mainMenuOrder = 2 },
        } },
        { key = "darkmoon", label = L["ProfKnowledge_Section_Darkmoon"], entries = { DMF{ label = L["ProfKnowledge_DMF_Tailoring"], questID = 29520, kp = 3, zone = 407, x = 55.6, y = 55.0, note = L["ProfKnowledge_DMFNote"], rowKey = "tail_dmf", mainMenuLabel = L["DMF_Tail_Label"] } } },
    } },
}

ns.MidnightProfessions = PROFESSIONS

local MIDNIGHT_EXPANSION = {
    key = "midnight",
    label = L["Expansion_Midnight"] or "Midnight",
    professions = PROFESSIONS,
}

ns.RegisterProfessionExpansion(MIDNIGHT_EXPANSION)

for _, profession in ipairs(PROFESSIONS) do
    ns.RegisterProfessionMainMenuModule(profession)
end
