local CREST_CAP = 100

MR:RegisterModule({
    key         = "crests",
    label       = "Crest Tracker",
    labelColor  = "#f1c232",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        { key = "crest_adventurer", currencyId = 3383, max = CREST_CAP, label = "|cffb7b7b7Adventurer Dawncrest:|r", note = "Repeatable Outdoor Events · Delve T4\nUpgrades gear to ilvl 224-237" },
        { key = "crest_veteran",    currencyId = 3341, max = CREST_CAP, label = "|cff1eff00Veteran Dawncrest:|r",    note = "Outdoor Events · LFR · Heroic Dungeons · Delves T5-6\nUpgrades gear to ilvl 237-250" },
        { key = "crest_champion",   currencyId = 3343, max = CREST_CAP, label = "|cfff1c232Champion Dawncrest:|r",   note = "Weekly Outdoor Events · Normal Raid · Mythic Dungeon · M+ 2-3 · Delves T7-10\nUpgrades gear to ilvl 250-263" },
        { key = "crest_hero",       currencyId = 3345, max = CREST_CAP, label = "|cff0070ddHero Dawncrest:|r",       note = "Heroic Raid · M+ 4-8 · Delve T11 · Trovehunter T8+\nUpgrades gear to ilvl 263-276" },
        { key = "crest_myth",       currencyId = 3347, max = CREST_CAP, label = "|cffff8000Myth Dawncrest:|r",       note = "Heroic Raid · M+ 9+\nUpgrades gear to ilvl 276-289" },
    },
})
