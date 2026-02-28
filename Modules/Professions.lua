MR:RegisterModule({
    key           = "prof_alchemy",
    profSkillLine = 2906,
    label         = "Alchemy",
    labelColor    = "#33bbff",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "alch_notebook", spellId = 1270530, spellAmount = 1, label = "|cff33bbffWeekly Quest:|r",              max = 1 },
        { key = "alch_drops",    spellId = 1264572, spellAmount = 1, label = "|cff33bbffWeekly Drops – Spore/Cruor:|r", max = 2 },
        { key = "alch_treatise", spellId = 1282284, spellAmount = 1, label = "|cff33bbffTreatise:|r",                   max = 1 },
        { key = "alch_dmf",      questIds = { 29506 },               label = "|cff33bbffDarkmoon Faire:|r",            max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_blacksmithing",
    profSkillLine = 2907,
    label         = "Blacksmithing",
    labelColor    = "#aaaaaa",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "bs_notebook", spellId = 1270531, spellAmount = 1, label = "|cffaaaaaaWeekly Quest:|r",            max = 1 },
        { key = "bs_drops",    spellId = 1264601, spellAmount = 1, label = "|cffaaaaaaWeekly Drops – Oil/Stone:|r", max = 2 },
        { key = "bs_treatise", spellId = 1282300, spellAmount = 1, label = "|cffaaaaaa Treatise:|r",               max = 1 },
        { key = "bs_dmf",      questIds = { 29508 },               label = "|cffaaaaaa Darkmoon Faire:|r",         max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_enchanting",
    profSkillLine = 2909,
    label         = "Enchanting",
    labelColor    = "#bb77ff",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "ench_notebook",   spellId = 1270532, spellAmount = 1, label = "|cffbb77ffWeekly Quest:|r",               max = 1 },
        { key = "ench_drops",      spellId = 1264604, spellAmount = 1, label = "|cffbb77ffWeekly Drops – Ashes/Vellum:|r", max = 2 },
        { key = "ench_de_essence", spellId = 1280988, spellAmount = 1, label = "|cffbb77ffDE – Arcane Essence:|r",         max = 5 },
        { key = "ench_de_shard",   spellId = 1280992, spellAmount = 4, label = "|cffbb77ffDE – Mana Shard:|r",             max = 1 },
        { key = "ench_treatise",   spellId = 1282301, spellAmount = 1, label = "|cffbb77ffTreatise:|r",                    max = 1 },
        { key = "ench_dmf",        questIds = { 29510 },               label = "|cffbb77ffDarkmoon Faire:|r",              max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_engineering",
    profSkillLine = 2910,
    label         = "Engineering",
    labelColor    = "#ffcc44",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "eng_notebook", spellId = 1270533, spellAmount = 1, label = "|cffffcc44Weekly Quest:|r",                  max = 1 },
        { key = "eng_drops",    spellId = 1264607, spellAmount = 1, label = "|cffffcc44Weekly Drops – Gear/Capacitor:|r",  max = 2 },
        { key = "eng_treatise", spellId = 1282302, spellAmount = 1, label = "|cffffcc44Treatise:|r",                       max = 1 },
        { key = "eng_dmf",      questIds = { 29511 },               label = "|cffffcc44Darkmoon Faire:|r",                max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_herbalism",
    profSkillLine = 2912,
    label         = "Herbalism",
    labelColor    = "#55cc44",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "herb_notebook", spellId = 1270534, spellAmount = 3, label = "|cff55cc44Weekly Quest:|r",                   max = 1 },
        { key = "herb_drops",    spellId = 1225342, spellAmount = 1, label = "|cff55cc44Weekly Gather – Phoenix Plumes:|r",  max = 5 },
        { key = "herb_tail",     spellId = 1225344, spellAmount = 4, label = "|cff55cc44Weekly Gather – Phoenix Tail:|r",    max = 1 },
        { key = "herb_treatise", spellId = 1282303, spellAmount = 1, label = "|cff55cc44Treatise:|r",                        max = 1 },
        { key = "herb_dmf",      questIds = { 29514 },               label = "|cff55cc44Darkmoon Faire:|r",                  max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_inscription",
    profSkillLine = 2913,
    label         = "Inscription",
    labelColor    = "#44ddaa",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "insc_notebook", spellId = 1270535, spellAmount = 4, label = "|cff44ddaaWeekly Quest:|r",           max = 1 },
        { key = "insc_drops",    spellId = 1264608, spellAmount = 1, label = "|cff44ddaaWeekly Drops – Ink/Rune:|r", max = 2 },
        { key = "insc_treatise", spellId = 1282304, spellAmount = 1, label = "|cff44ddaaTreatise:|r",               max = 1 },
        { key = "insc_dmf",      questIds = { 29515 },               label = "|cff44ddaaDarkmoon Faire:|r",         max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_jewelcrafting",
    profSkillLine = 2914,
    label         = "Jewelcrafting",
    labelColor    = "#ff7799",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "jc_notebook", spellId = 1270536, spellAmount = 3, label = "|cffff7799Weekly Quest:|r",              max = 1 },
        { key = "jc_drops",    spellId = 1264609, spellAmount = 1, label = "|cffff7799Weekly Drops – Gems/Stone:|r",  max = 2 },
        { key = "jc_treatise", spellId = 1282305, spellAmount = 1, label = "|cffff7799Treatise:|r",                   max = 1 },
        { key = "jc_dmf",      questIds = { 29516 },               label = "|cffff7799Darkmoon Faire:|r",            max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_leatherworking",
    profSkillLine = 2915,
    label         = "Leatherworking",
    labelColor    = "#cc8833",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "lw_notebook", spellId = 1270537, spellAmount = 2, label = "|cffcc8833Weekly Quest:|r",         max = 1 },
        { key = "lw_drops",    spellId = 1264602, spellAmount = 1, label = "|cffcc8833Weekly Drops – Oil:|r",   max = 2 },
        { key = "lw_treatise", spellId = 1282306, spellAmount = 1, label = "|cffcc8833Treatise:|r",             max = 1 },
        { key = "lw_dmf",      questIds = { 29517 },               label = "|cffcc8833Darkmoon Faire:|r",       max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_mining",
    profSkillLine = 2916,
    label         = "Mining",
    labelColor    = "#cccccc",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "mine_notebook", spellId = 1270538, spellAmount = 3, label = "|cffccccccWeekly Quest:|r",                   max = 1 },
        { key = "mine_rock",     spellId = 1223243, spellAmount = 1, label = "|cffccccccWeekly Gather – Rock Specimens:|r",  max = 5 },
        { key = "mine_nodule",   spellId = 1223324, spellAmount = 3, label = "|cffccccccWeekly Gather – Septarian Nodule:|r", max = 1 },
        { key = "mine_treatise", spellId = 1282307, spellAmount = 1, label = "|cffccccccTreatise:|r",                        max = 1 },
        { key = "mine_dmf",      questIds = { 29518 },               label = "|cffccccccDarkmoon Faire:|r",                  max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_skinning",
    profSkillLine = 2917,
    label         = "Skinning",
    labelColor    = "#c8a060",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "skin_notebook", spellId = 1270539, spellAmount = 3, label = "|cffc8a060Weekly Quest:|r",                     max = 1 },
        { key = "skin_drops",    spellId = 1225644, spellAmount = 1, label = "|cffc8a060Weekly Gather – Hide/Sample:|r",       max = 5 },
        { key = "skin_bone",     spellId = 1225646, spellAmount = 3, label = "|cffc8a060Weekly Gather – Mana-Infused Bone:|r",  max = 1 },
        { key = "skin_treatise", spellId = 1282308, spellAmount = 1, label = "|cffc8a060Treatise:|r",                          max = 1 },
        { key = "skin_dmf",      questIds = { 29519 },               label = "|cffc8a060Darkmoon Faire:|r",                    max = 1 },
    },
})

MR:RegisterModule({
    key           = "prof_tailoring",
    profSkillLine = 2918,
    label         = "Tailoring",
    labelColor    = "#ffaadd",
    resetType     = "weekly",
    defaultOpen   = false,
    rows = {
        { key = "tail_notebook", spellId = 1270540, spellAmount = 2, label = "|cffffaaddWeekly Quest:|r",               max = 1 },
        { key = "tail_drops",    spellId = 1264610, spellAmount = 1, label = "|cffffaaddWeekly Drops – Collar/Memento:|r", max = 2 },
        { key = "tail_treatise", spellId = 1282309, spellAmount = 1, label = "|cffffaaddTreatise:|r",                    max = 1 },
        { key = "tail_dmf",      questIds = { 29520 },               label = "|cffffaaddDarkmoon Faire:|r",              max = 1 },
    },
})
