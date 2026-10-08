local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers["Prey"] = function(owner, context)
    local ns = context.namespace
    if ns.MR.isForever then return end
    local MR = ns.MR

    local L = context.labels
    local IS_PATCH_12_1 = MR:IsPatchAvailable("12.1.0")
    local PREY_NORMAL_WEEKLY_MAX = 4
    local PREY_HARD_WEEKLY_MAX = IS_PATCH_12_1 and 6 or 4
    local PREY_NIGHTMARE_WEEKLY_MAX = IS_PATCH_12_1 and 5 or 4

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
        for qid = 95021, 95024 do
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
        onScan = function(mod)
            local value = 0

            if C_QuestLog.IsQuestFlaggedCompleted(94446) then
                value = 3
            elseif C_QuestLog.GetQuestObjectives then
                local objectives = C_QuestLog.GetQuestObjectives(94446)
                local objective = objectives and objectives[1]
                value = math.min(tonumber(objective and objective.numFulfilled) or 0, 3)
            end

            return MR:WriteScanProgress(mod.key, "prey_nightmare_weekly", value)
        end,
        rows = {
            {
                key      = "prey_normal_hunts",
                label    = L["Prey_Normal_Label"],
                max      = PREY_NORMAL_WEEKLY_MAX,
                note     = string.format(L["Prey_Normal_Note"], PREY_NORMAL_WEEKLY_MAX),
                questIds = BuildPreyNormalQuestIds(),
            },
            {
                key      = "prey_hard_hunts",
                label    = L["Prey_Hard_Label"],
                max      = PREY_HARD_WEEKLY_MAX,
                note     = string.format(L["Prey_Hard_Note"], PREY_HARD_WEEKLY_MAX),
                questIds = BuildPreyHardQuestIds(),
            },
            {
                key      = "prey_nightmare_hunts",
                label    = L["Prey_Nightmare_Label"],
                max      = PREY_NIGHTMARE_WEEKLY_MAX,
                note     = string.format(L["Prey_Nightmare_Note"], PREY_NIGHTMARE_WEEKLY_MAX),
                questIds = BuildPreyNightmareQuestIds(),
            },
            {
                key  = "prey_nightmare_weekly",
                label = L["Prey_Nightmare_Weekly_Label"],
                max = 3,
                note = L["Prey_Nightmare_Weekly_Note"],
                questIds = { 94446 },
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
end
