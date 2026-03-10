local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local HONOR_CAP        = 15000
local CONQUEST_CAP     = 1600
local BLOODY_TOKEN_CAP = 1600

local CURRENCY_HONOR        = 1792
local CURRENCY_CONQUEST     = 1602
local CURRENCY_BLOODY_TOKEN = 2123

local QUEST_SPARKS_ZULAMAN        = 93424
local QUEST_SPARKS_HARANDAR       = 93425
local QUEST_PRESERVING_BATTLE     = 80184
local QUEST_PRESERVING_SOLO       = 80185
local QUEST_PRESERVING_SKIRMISHES = 80187
local QUEST_PRESERVING_ARENAS     = 80188
local QUEST_EARLY_TRAINING        = 94835

MR:RegisterModule({
    key         = "pvp_currencies",
    label       = L["PvP_CurrenciesTitle"],
    labelColor  = "#cc3333",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        {
            key        = "honor",
            currencyId = CURRENCY_HONOR,
            max        = HONOR_CAP,
            label      = L["PvP_Honor_Label"],
            note       = L["PvP_Honor_Note"],
        },
        {
            key        = "conquest",
            currencyId = CURRENCY_CONQUEST,
            max        = CONQUEST_CAP,
            label      = L["PvP_Conquest_Label"],
            note       = L["PvP_Conquest_Note"],
        },
        {
            key        = "bloody_tokens",
            currencyId = CURRENCY_BLOODY_TOKEN,
            max        = BLOODY_TOKEN_CAP,
            label      = L["PvP_BloodyTokens_Label"],
            note       = L["PvP_BloodyTokens_Note"],
        },
    },
})

MR:RegisterModule({
    key         = "pvp_weeklies",
    label       = L["PvP_WeekliesTitle"],
    labelColor  = "#cc3333",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        {
            key      = "sparks_of_war",
            label    = L["PvP_Sparks_Label"],
            max      = 1,
            note     = L["PvP_Sparks_Note"],
            questIds = { QUEST_SPARKS_ZULAMAN, QUEST_SPARKS_HARANDAR },
            tooltipFunc = function(tip)
                local variants = {
                    { quest = QUEST_SPARKS_ZULAMAN,  name = L["PvP_Sparks_ZA"] },
                    { quest = QUEST_SPARKS_HARANDAR, name = L["PvP_Sparks_Harandar"] },
                }

                local completedName = nil
                local activeName = nil

                for _, v in ipairs(variants) do
                    if C_QuestLog.IsQuestFlaggedCompleted(v.quest) then
                        completedName = v.name
                        break
                    end
                end

                if not completedName then
                    for _, v in ipairs(variants) do
                        if C_QuestLog.IsOnQuest(v.quest) then
                            activeName = v.name
                            break
                        end
                    end
                end

                tip:AddLine(" ")
                if completedName then
                    tip:AddLine(L["Tooltip_Done_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. completedName, 0.4, 0.85, 0.4)
                elseif activeName then
                    tip:AddLine(L["Tooltip_Active_Variant"], 1, 1, 1)
                    tip:AddLine("  " .. activeName, 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Sparks"], 1, 1, 1)
                end
            end,
        },
        {
            key      = "preserving_solo",
            label    = L["PvP_Solo_Label"],
            max      = 1,
            note     = L["PvP_Solo_Note"],
            questIds = { QUEST_PRESERVING_SOLO },
        },
        {
            key      = "preserving_skirmishes",
            label    = L["PvP_Skirmishes_Label"],
            max      = 1,
            note     = L["PvP_Skirmishes_Note"],
            questIds = { QUEST_PRESERVING_SKIRMISHES },
        },
        {
            key      = "preserving_arenas",
            label    = L["PvP_Arenas_Label"],
            max      = 1,
            note     = L["PvP_Arenas_Note"],
            questIds = { QUEST_PRESERVING_ARENAS },
        },
        {
            key      = "preserving_battle",
            label    = L["PvP_Battle_Label"],
            max      = 1,
            note     = L["PvP_Battle_Note"],
            questIds = { QUEST_PRESERVING_BATTLE },
        },
        {
            key      = "early_training",
            label    = L["PvP_Training_Label"],
            max      = 1,
            note     = L["PvP_Training_Note"],
            questIds = { QUEST_EARLY_TRAINING },
        },
    },
})
