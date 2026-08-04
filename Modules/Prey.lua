local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")
local PREY_WEEKLY_MAX = MR:IsPatchAvailable("12.1.0") and 5 or 4

local function BuildPreyNormalQuestIds()
    local ids = {}
    for qid = 91095, 91124 do
        ids[#ids + 1] = qid
    end
    return ids
end

local function BuildPreyHardQuestIds()
    local ids = {}
    for qid = 91210, 91242, 2 do
        ids[#ids + 1] = qid
    end
    for qid = 91243, 91255 do
        ids[#ids + 1] = qid
    end
    return ids
end

local function BuildPreyNightmareQuestIds()
    local ids = {}
    for qid = 91211, 91241, 2 do
        ids[#ids + 1] = qid
    end
    for qid = 91256, 91269 do
        ids[#ids + 1] = qid
    end
    return ids
end

MR:RegisterModule({
    key         = "prey",
    label       = L["Prey_Title"],
    labelColor  = "#cc2244",
    resetType   = "weekly",
    defaultOpen = true,
    rows = {
        {
            key      = "prey_normal_hunts",
            label    = L["Prey_Normal_Label"],
            max      = PREY_WEEKLY_MAX,
            note     = L["Prey_Normal_Note"],
            questIds = BuildPreyNormalQuestIds(),
        },
        {
            key      = "prey_hard_hunts",
            label    = L["Prey_Hard_Label"],
            max      = PREY_WEEKLY_MAX,
            note     = L["Prey_Hard_Note"],
            questIds = BuildPreyHardQuestIds(),
        },
        {
            key      = "prey_nightmare_hunts",
            label    = L["Prey_Nightmare_Label"],
            max      = PREY_WEEKLY_MAX,
            note     = L["Prey_Nightmare_Note"],
            questIds = BuildPreyNightmareQuestIds(),
        },
        {
            key        = "prey_remnants",
            label      = L["Prey_Remnants_Label"],
            currencyId = 3392,
            noMax      = true,
            note       = L["Prey_Remnants_Note"],
        },
    },
})
