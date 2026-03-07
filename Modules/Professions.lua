local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

MR:RegisterModule({
    key           = "prof_alchemy",
    profSkillLine = 2906,
    label         = L["Alchemy"],
    labelColor    = "#33bbff",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "alch_notebook", spellId = 1270530, spellAmount = 1, label = L["Alch_Quest"],    max = 1 },
        { key = "alch_drops",    spellId = 1264572, spellAmount = 1, label = L["Alch_Drops"],    max = 2 },
        { key = "alch_treatise", questIds = { 95127 },               label = L["Alch_Treatise"], max = 1 },
        { key = "alch_dmf",      questIds = { 29506 },               label = L["Alch_DMF"],     max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_blacksmithing",
    profSkillLine = 2907,
    label         = L["Blacksmithing"],
    labelColor    = "#aaaaaa",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "bs_notebook", spellId = 1270531, spellAmount = 1, label = L["BS_Quest"],    max = 1 },
        { key = "bs_drops",    spellId = 1264601, spellAmount = 1, label = L["BS_Drops"],    max = 2 },
        { key = "bs_treatise", questIds = { 95128 },               label = L["BS_Treatise"], max = 1 },
        { key = "bs_dmf",      questIds = { 29508 },               label = L["BS_DMF"],     max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_enchanting",
    profSkillLine = 2909,
    label         = L["Enchanting"],
    labelColor    = "#bb77ff",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "ench_notebook",   spellId = 1270532, spellAmount = 1, label = L["Ench_Quest"],      max = 1 },
        { key = "ench_drops",      spellId = 1264604, spellAmount = 1, label = L["Ench_Drops"],      max = 2 },
        { key = "ench_de_essence", spellId = 1280988, spellAmount = 1, label = L["Ench_DE_Essence"], max = 5 },
        { key = "ench_de_shard",   spellId = 1280992, spellAmount = 4, label = L["Ench_DE_Shard"],   max = 1 },
        { key = "ench_treatise",   questIds = { 95129 },               label = L["Ench_Treatise"],   max = 1 },
        { key = "ench_dmf",        questIds = { 29510 },               label = L["Ench_DMF"],        max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_engineering",
    profSkillLine = 2910,
    label         = L["Engineering"],
    labelColor    = "#ffcc44",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "eng_notebook", spellId = 1270533, spellAmount = 1, label = L["Eng_Quest"],    max = 1 },
        { key = "eng_drops",    spellId = 1264607, spellAmount = 1, label = L["Eng_Drops"],    max = 2 },
        { key = "eng_treatise", questIds = { 95138 },               label = L["Eng_Treatise"], max = 1 },
        { key = "eng_dmf",      questIds = { 29511 },               label = L["Eng_DMF"],     max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_herbalism",
    profSkillLine = 2912,
    label         = L["Herbalism"],
    labelColor    = "#55cc44",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "herb_notebook", spellId = 1270534, spellAmount = 3, label = L["Herb_Quest"],    max = 1 },
        { key = "herb_drops",    spellId = 1225342, spellAmount = 1, label = L["Herb_Plumes"],   max = 5 },
        { key = "herb_tail",     spellId = 1225344, spellAmount = 4, label = L["Herb_Tail"],     max = 1 },
        { key = "herb_treatise", questIds = { 95130 },               label = L["Herb_Treatise"], max = 1 },
        { key = "herb_dmf",      questIds = { 29514 },               label = L["Herb_DMF"],     max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_inscription",
    profSkillLine = 2913,
    label         = L["Inscription"],
    labelColor    = "#44ddaa",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "insc_notebook", spellId = 1270535, spellAmount = 4, label = L["Insc_Quest"],    max = 1 },
        { key = "insc_drops",    spellId = 1264608, spellAmount = 1, label = L["Insc_Drops"],    max = 2 },
        { key = "insc_treatise", questIds = { 95131 },               label = L["Insc_Treatise"], max = 1 },
        { key = "insc_dmf",      questIds = { 29515 },               label = L["Insc_DMF"],     max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_jewelcrafting",
    profSkillLine = 2914,
    label         = L["Jewelcrafting"],
    labelColor    = "#ff7799",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "jc_notebook", spellId = 1270536, spellAmount = 3, label = L["JC_Quest"],    max = 1 },
        { key = "jc_drops",    spellId = 1264609, spellAmount = 1, label = L["JC_Drops"],    max = 2 },
        { key = "jc_treatise", questIds = { 95133 },               label = L["JC_Treatise"], max = 1 },
        { key = "jc_dmf",      questIds = { 29516 },               label = L["JC_DMF"],     max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_leatherworking",
    profSkillLine = 2915,
    label         = L["Leatherworking"],
    labelColor    = "#cc8833",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "lw_notebook", spellId = 1270537, spellAmount = 2, label = L["LW_Quest"],    max = 1 },
        { key = "lw_drops",    spellId = 1264602, spellAmount = 1, label = L["LW_Drops"],    max = 2 },
        { key = "lw_treatise", questIds = { 95134 },               label = L["LW_Treatise"], max = 1 },
        { key = "lw_dmf",      questIds = { 29517 },               label = L["LW_DMF"],     max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_mining",
    profSkillLine = 2916,
    label         = L["Mining"],
    labelColor    = "#cccccc",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "mine_notebook", spellId = 1270538, spellAmount = 3, label = L["Mine_Quest"],    max = 1 },
        { key = "mine_rock",     spellId = 1223243, spellAmount = 1, label = L["Mine_Rock"],     max = 5 },
        { key = "mine_nodule",   spellId = 1223324, spellAmount = 3, label = L["Mine_Nodule"],   max = 1 },
        { key = "mine_treatise", questIds = { 95135 },               label = L["Mine_Treatise"], max = 1 },
        { key = "mine_dmf",      questIds = { 29518 },               label = L["Mine_DMF"],     max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_skinning",
    profSkillLine = 2917,
    label         = L["Skinning"],
    labelColor    = "#c8a060",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "skin_notebook", spellId = 1270539, spellAmount = 3, label = L["Skin_Quest"],    max = 1 },
        { key = "skin_drops",    spellId = 1225644, spellAmount = 1, label = L["Skin_Drops"],    max = 5 },
        { key = "skin_bone",     spellId = 1225646, spellAmount = 3, label = L["Skin_Bone"],     max = 1 },
        { key = "skin_treatise", questIds = { 95136 },               label = L["Skin_Treatise"], max = 1 },
        { key = "skin_dmf",      questIds = { 29519 },               label = L["Skin_DMF"],     max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_tailoring",
    profSkillLine = 2918,
    label         = L["Tailoring"],
    labelColor    = "#ffaadd",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "tail_notebook", spellId = 1270540, spellAmount = 2, label = L["Tail_Quest"],    max = 1 },
        { key = "tail_drops",    spellId = 1264610, spellAmount = 1, label = L["Tail_Drops"],    max = 2 },
        { key = "tail_treatise", questIds = { 95137 },               label = L["Tail_Treatise"], max = 1 },
        { key = "tail_dmf",      questIds = { 29520 },               label = L["Tail_DMF"],     max = 1 },
    },
})
