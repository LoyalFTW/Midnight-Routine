local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

MR:RegisterModule({
    key         = "s1_weekly",
    label       = L["Weekly_SeasonTitle"],
    labelColor  = "#2ae7c6",
    resetType   = "weekly",
    defaultOpen = true,

    onScan = function(mod)
        local SA_ASSIGNMENTS = {
            { quest = 91390, unlock = 94865, name = L["SA_Temple"] },
            { quest = 91796, unlock = 94866, name = L["SA_Ours"]                 },
            { quest = 92063, unlock = 94390, name = L["SA_Hunter"]               },
            { quest = 92139, unlock = 95435, name = L["SA_Shade"]                  },
            { quest = 92145, unlock = 92848, name = L["SA_Drink"]      },
            { quest = 93013, unlock = 94391, name = L["SA_Push"]             },
            { quest = 93244, unlock = 94795, name = L["SA_Agents"]            },
            { quest = 93438, unlock = 94743, name = L["SA_Precision"]              },
        }

        local UATV_BRANCHES = {
            { quest = 93909, name = L["Unity_Delves"]    },
            { quest = 93911, name = L["Unity_Dungeons"]  },
            { quest = 93912, name = L["Unity_Raids"]     },
            { quest = 93910, name = L["Unity_PvP"]       },
        }

        local db = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end

        for _, a in ipairs(SA_ASSIGNMENTS) do
            if C_QuestLog.IsQuestFlaggedCompleted(a.quest) then
                db[mod.key]["special_assignment"] = 1
                db[mod.key]["sa_active_name"]     = a.name

                break
            end
        end

        if not db[mod.key]["sa_active_name"] then
            for _, a in ipairs(SA_ASSIGNMENTS) do
                if C_QuestLog.IsOnQuest(a.unlock) or C_QuestLog.IsQuestFlaggedCompleted(a.unlock) then
                    db[mod.key]["sa_active_name"] = a.name
                    break
                end
            end
        end

        if C_QuestLog.IsQuestFlaggedCompleted(93744) then

            for _, b in ipairs(UATV_BRANCHES) do
                if C_QuestLog.IsQuestFlaggedCompleted(b.quest) then
                    db[mod.key]["uatv_branch_name"] = b.name
                    break
                end
            end
            if not db[mod.key]["uatv_branch_name"] then
                db[mod.key]["uatv_branch_name"] = L["Weekly_UnknownActivity"]
            end
        else

            db[mod.key]["uatv_branch_name"] = nil
            for _, b in ipairs(UATV_BRANCHES) do
                if C_QuestLog.IsOnQuest(b.quest) then
                    db[mod.key]["uatv_branch_name"] = b.name
                    break
                end
            end
        end
    end,

    rows = {
        {
            key      = "abundance",
            label    = L["Weekly_Abundance_Label"],
            max      = 1,
            questIds = { 89507 },
        },
        {
            key      = "lost_legends",
            label    = L["Weekly_Legends_Label"],
            max      = 1,
            questIds = { 89268 },
        },
        {
            key      = "high_esteem",
            label    = L["Weekly_Esteem_Label"],
            max      = 1,
            questIds = { 91629 },
        },
        {
            key      = "favor_of_court",
            label    = L["Weekly_Favor_Label"],
            max      = 1,
            note     = L["Weekly_Favor_Note"],
            questIds = { 89289 },
            tooltipFunc = function(tip)
                local SUBFACTIONS = {
                    { quest = 90573, name = L["Magisters"]       },
                    { quest = 90574, name = L["Subfaction_BloodKnights"]   },
                    { quest = 90575, name = L["Farstriders"]     },
                    { quest = 90576, name = L["Subfaction_ShadesOfTheRow"] },
                }

                local chosenFaction = nil
                for _, f in ipairs(SUBFACTIONS) do
                    if C_QuestLog.IsQuestFlaggedCompleted(f.quest) or C_QuestLog.IsOnQuest(f.quest) then
                        chosenFaction = f.name
                        break
                    end
                end

                tip:AddLine(" ")
                if C_QuestLog.IsQuestFlaggedCompleted(89289) then
                    tip:AddLine(L["Tooltip_Done_Choice"], 1, 1, 1)
                    tip:AddLine("  " .. (chosenFaction or L["Tooltip_SubfactionSelected"]), 0.4, 0.85, 0.4)
                elseif chosenFaction then
                    tip:AddLine(L["Tooltip_Active_Week"], 1, 1, 1)
                    tip:AddLine("  " .. chosenFaction, 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Subfaction"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Haven"], 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "saltherils_soiree",
            label    = L["Weekly_Soiree_Label"],
            max      = 1,
            note     = L["Weekly_Soiree_Note"],
            questIds = { 93889, 91966 },
            tooltipFunc = function(tip)
                local variants = {
                    { quest = 93889, name = "Midnight: Saltheril's Soiree" },
                    { quest = 91966, name = "Saltheril's Soiree" },
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
                    tip:AddLine(L["Tooltip_No_Soiree"], 1, 1, 1)
                end
            end,
        },
        {
            key      = "fortify_runestones",
            label    = L["Weekly_Fortify_Label"],
            max      = 1,
            questIds = { 90575, 90576, 90574, 90573 },
        },
        {
            key      = "stand_your_ground",
            label    = L["Weekly_Stand_Label"],
            max      = 1,
            questIds = { 92365, 94581 },
        },
        {
            key      = "unity_against_void",
            label    = L["Weekly_Unity_Label"],
            max      = 1,
            note     = L["Weekly_Unity_Note"],

            questIds = { 93744, 93909, 93911, 93912, 93910 },
            tooltipFunc = function(tip)
                local BRANCHES = {
                    { quest = 93909, name = L["Unity_Delves"]   },
                    { quest = 93911, name = L["Unity_Dungeons"] },
                    { quest = 93912, name = L["Unity_Raids"]    },
                    { quest = 93910, name = L["Unity_PvP"]      },
                }

                local metaDone   = C_QuestLog.IsQuestFlaggedCompleted(93744)
                local activeName = nil
                local doneBranch = nil

                for _, b in ipairs(BRANCHES) do
                    if C_QuestLog.IsQuestFlaggedCompleted(b.quest) then
                        doneBranch = b.name
                        break
                    end
                end

                if not doneBranch then
                    for _, b in ipairs(BRANCHES) do
                        if C_QuestLog.IsOnQuest(b.quest) then
                            activeName = b.name
                            break
                        end
                    end
                end

                tip:AddLine(" ")
                if metaDone or doneBranch then
                    tip:AddLine(L["Tooltip_Done_Completed"], 1, 1, 1)
                    tip:AddLine("  " .. (doneBranch or L["Tooltip_ActivityCompleted"]), 0.4, 0.85, 0.4)
                elseif activeName then
                    tip:AddLine(L["Tooltip_Active_Progress"], 1, 1, 1)
                    tip:AddLine("  " .. activeName, 1, 0.9, 0.3)
                else
                    tip:AddLine(L["Tooltip_No_Activity"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Pick_Activity"], 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "special_assignment",
            label    = L["Weekly_SA_Label"],
            max      = 1,
            note     = L["Weekly_SA_Note"],

            questIds = { 91390, 91796, 92063, 92139, 92145, 93013, 93244, 93438 },
            tooltipFunc = function(tip)
                local assignments = {
                    { quest = 91390, unlock = 94865, name = L["SA_Temple"] },
                    { quest = 91796, unlock = 94866, name = L["SA_Ours"] },
                    { quest = 92063, unlock = 94390, name = L["SA_Hunter"] },
                    { quest = 92139, unlock = 95435, name = L["SA_Shade"] },
                    { quest = 92145, unlock = 92848, name = L["SA_Drink"] },
                    { quest = 93013, unlock = 94391, name = L["SA_Push"] },
                    { quest = 93244, unlock = 94795, name = L["SA_Agents"] },
                    { quest = 93438, unlock = 94743, name = L["SA_Precision"] },
                }

                local activeAssignment  = nil
                local completedThisWeek = false
                local objectiveText     = nil

                for _, a in ipairs(assignments) do
                    if C_QuestLog.IsQuestFlaggedCompleted(a.quest) then
                        completedThisWeek = true
                        activeAssignment  = a
                        break
                    end
                end

                if not completedThisWeek then
                    for _, a in ipairs(assignments) do
                        if C_QuestLog.IsOnQuest(a.unlock) or
                           C_QuestLog.IsQuestFlaggedCompleted(a.unlock) then
                            activeAssignment = a

                            local objectives = C_QuestLog.GetQuestObjectives(a.unlock)
                            if objectives and objectives[1] and objectives[1].text and
                               objectives[1].text ~= "" then
                                objectiveText = objectives[1].text
                            end
                            break
                        end
                    end
                end

                tip:AddLine(" ")
                if completedThisWeek and activeAssignment then
                    tip:AddLine(L["Tooltip_Done_Completed"], 1, 1, 1)
                    tip:AddLine("  " .. activeAssignment.name, 0.4, 0.85, 0.4)
                elseif activeAssignment then
                    tip:AddLine(L["Tooltip_Active_Week"], 1, 1, 1)
                    tip:AddLine("  " .. activeAssignment.name, 1, 0.9, 0.3)
                    if objectiveText then
                        tip:AddLine(" ")
                        tip:AddLine(objectiveText, 0.7, 0.7, 0.7, true)
                    end
                else
                    tip:AddLine(L["Tooltip_No_Assignment"], 1, 1, 1)
                    tip:AddLine(L["Tooltip_Visit_Silvermoon"], 0.7, 0.7, 0.7)
                end
            end,
        },
    },
})
