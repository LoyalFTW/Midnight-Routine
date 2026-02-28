local PVP_RED          = "|cffcc3333"
local PVP_GOLD         = "|cffffb347"

local HONOR_CAP        = 15000
local CONQUEST_CAP     = 1600
local BLOODY_TOKEN_CAP = 1600

local CURRENCY_HONOR        = 1792
local CURRENCY_CONQUEST     = 1602
local CURRENCY_BLOODY_TOKEN = 2123

local QUEST_SPARKS_ZULAMAN        = 93424
local QUEST_PRESERVING_BATTLE     = 80184
local QUEST_PRESERVING_SOLO       = 80185
local QUEST_PRESERVING_SKIRMISHES = 80187
local QUEST_PRESERVING_ARENAS     = 80188

MR:RegisterModule({
    key         = "pvp_currencies",
    label       = "PvP Currencies",
    labelColor  = "#cc3333",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        {
            key        = "honor",
            currencyId = CURRENCY_HONOR,
            max        = HONOR_CAP,
            label      = PVP_RED .. "Honor:|r",
            note       = "Earn from Battlegrounds, Skirmishes, Rated PvP\nCap: 15,000 · Buys Galactic Aspirant (Honor) gear",
        },
        {
            key        = "conquest",
            currencyId = CURRENCY_CONQUEST,
            max        = CONQUEST_CAP,
            label      = PVP_GOLD .. "Conquest:|r",
            note       = "Season 1 starts March 17 · Cap: 1,600 week 1, +800/week\nVendor: Irissa Bloodstar in Silvermoon",
        },
        {
            key        = "bloody_tokens",
            currencyId = CURRENCY_BLOODY_TOKEN,
            max        = BLOODY_TOKEN_CAP,
            label      = PVP_RED .. "Bloody Tokens:|r",
            note       = "War Mode currency · Cap: 1,600 week 1, +800/week\nVendor: Knight-Lord Bloodvalor in Silvermoon\nBuys Galactic Warmonger (Veteran Track) gear",
        },
    },
})

MR:RegisterModule({
    key         = "pvp_weeklies",
    label       = "PvP Weeklies",
    labelColor  = "#cc3333",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        {
            key      = "sparks_of_war",
            label    = PVP_RED .. "Sparks of War:|r",
            max      = 1,
            note     = "Collect 100 Sparks in any Midnight zone with War Mode on\nPick up from Zerella in Silvermoon · /way #2393 36.25 81.14\nRewards: 1,000 Bloody Tokens · 500 Honor · 50 Conquest",
            questIds = { QUEST_SPARKS_ZULAMAN },
        },
        {
            key      = "preserving_solo",
            label    = PVP_RED .. "Preserving Solo:|r",
            max      = 1,
            note     = "Complete 12 rounds of Solo Shuffle\nRewards: ~175 Conquest · 500 Honor",
            questIds = { QUEST_PRESERVING_SOLO },
        },
        {
            key      = "preserving_skirmishes",
            label    = PVP_RED .. "Preserving in Skirmishes:|r",
            max      = 1,
            note     = "Earn 1,000 Honor in Arena Skirmishes\nRewards: ~125 Conquest · 350 Honor",
            questIds = { QUEST_PRESERVING_SKIRMISHES },
        },
        {
            key      = "preserving_arenas",
            label    = PVP_RED .. "Preserving in Arenas:|r",
            max      = 1,
            note     = "Earn Honor in Rated Arenas\nRewards: ~125 Conquest · 350 Honor",
            questIds = { QUEST_PRESERVING_ARENAS },
        },
        {
            key      = "preserving_battle",
            label    = PVP_RED .. "Preserving in Battle:|r",
            max      = 1,
            note     = "Complete Battlegrounds for Honor & Conquest\nRewards: ~175 Conquest · 500 Honor",
            questIds = { QUEST_PRESERVING_BATTLE },
        },
    },
})
