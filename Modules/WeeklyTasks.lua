MR:RegisterModule({
    key         = "s1_weekly",
    label       = "Season 1 Weeklies",
    labelColor  = "#2ae7c6",
    resetType   = "weekly",
    defaultOpen = true,

    onScan = function(mod)
        local SA_ASSIGNMENTS = {
            { quest = 91390, unlock = 94865, name = "What Remains of a Temple Broken" },
            { quest = 91796, unlock = 94866, name = "Ours Once More!"                 },
            { quest = 92063, unlock = 94390, name = "A Hunter's Regret"               },
            { quest = 92139, unlock = 95435, name = "Shade and Claw"                  },
            { quest = 92145, unlock = 92848, name = "The Grand Magister's Drink"      },
            { quest = 93013, unlock = 94391, name = "Push Back the Light"             },
            { quest = 93244, unlock = 94795, name = "Agents of the Shield"            },
            { quest = 93438, unlock = 94743, name = "Precision Excision"              },
        }

        local UATV_BRANCHES = {
            { quest = 93909, name = "Midnight: Delves"    },
            { quest = 93911, name = "Midnight: Dungeons"  },
            { quest = 93912, name = "Midnight: Raids"     },  
            { quest = 93910, name = "Midnight: PvP"       },  
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
                db[mod.key]["uatv_branch_name"] = "Unknown activity"
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
            label    = "|cff2ae7c6Weekly: Abundance:|r",
            max      = 1,
            questIds = { 89507 },
        },
        {
            key      = "lost_legends",
            label    = "|cff2ae7c6Lost Legends:|r",
            max      = 1,
            questIds = { 89268 },
        },
        {
            key      = "high_esteem",
            label    = "|cff2ae7c6High Esteem:|r",
            max      = 1,
            questIds = { 91629 },
        },
        {
            key      = "favor_of_court",
            label    = "|cff2ae7c6Favor of the Court:|r",
            max      = 1,
            note     = "Choose a subfaction (Magisters, Blood Knights, Farstriders, or Shades of the Row) to invite to Saltheril's Haven. Your choice determines which Fortify the Runestones quest is available this week.",
            questIds = { 89289 },
            tooltipFunc = function(tip)
                local SUBFACTIONS = {
                    { quest = 90573, name = "Magisters"       },
                    { quest = 90574, name = "Blood Knights"   },
                    { quest = 90575, name = "Farstriders"     },
                    { quest = 90576, name = "Shades of the Row" },
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
                    tip:AddLine("|cff00ff96✓ Choice made this week:|r", 1, 1, 1)
                    tip:AddLine("  " .. (chosenFaction or "Subfaction selected"), 0.4, 0.85, 0.4)
                elseif chosenFaction then
                    tip:AddLine("|cffffff00» Active this week:|r", 1, 1, 1)
                    tip:AddLine("  " .. chosenFaction, 1, 0.9, 0.3)
                else
                    tip:AddLine("|cffaaaaaa? No subfaction chosen yet.|r", 1, 1, 1)
                    tip:AddLine("  Visit Saltheril's Haven in Eversong Woods.", 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "saltherils_soiree",
            label    = "|cff2ae7c6Saltheril's Soiree:|r",
            max      = 1,
            note     = "Attend Saltheril's Soiree and complete 2 favors for the nobles. Rewards a Spark of Radiance.",
            questIds = { 93889 },
        },
        {
            key      = "fortify_runestones",
            label    = "|cff2ae7c6Fortify the Runestones:|r",
            max      = 1,
            questIds = { 90575, 90576, 90574, 90573 },
        },
        {
            key      = "stand_your_ground",
            label    = "|cff2ae7c6Stand Your Ground:|r",
            max      = 1,
            questIds = { 94581 },
        },
        {
            key      = "unity_against_void",
            label    = "|cff2ae7c6Unity Against the Void:|r",
            max      = 1,
            note     = "Choose one activity: Delves, Dungeons, Raids, or PvP. Completing it rewards an Apex Cache.",
            questIds = { 93744, 93909, 93911, 93912, 93910 },
            tooltipFunc = function(tip)
                local BRANCHES = {
                    { quest = 93909, name = "Midnight: Delves"   },
                    { quest = 93911, name = "Midnight: Dungeons" },
                    { quest = 93912, name = "Midnight: Raids"    },
                    { quest = 93910, name = "Midnight: PvP"      },
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
                    tip:AddLine("|cff00ff96✓ Completed this week:|r", 1, 1, 1)
                    tip:AddLine("  " .. (doneBranch or "Activity completed"), 0.4, 0.85, 0.4)
                elseif activeName then
                    tip:AddLine("|cffffff00» In progress:|r", 1, 1, 1)
                    tip:AddLine("  " .. activeName, 1, 0.9, 0.3)
                else
                    tip:AddLine("|cffaaaaaa? No activity chosen yet.|r", 1, 1, 1)
                    tip:AddLine("  Pick Delves, Dungeons, Raids, or PvP in Silvermoon.", 0.7, 0.7, 0.7)
                end
            end,
        },
        {
            key      = "special_assignment",
            label    = "|cff2ae7c6Special Assignment:|r",
            max      = 1,
            note     = "One Special Assignment is available each week. Complete it for bonus rewards.",
            questIds = { 91390, 91796, 92063, 92139, 92145, 93013, 93244, 93438 },
            tooltipFunc = function(tip)
                local assignments = {
                    { quest = 91390, unlock = 94865, name = "What Remains of a Temple Broken" },
                    { quest = 91796, unlock = 94866, name = "Ours Once More!"                 },
                    { quest = 92063, unlock = 94390, name = "A Hunter's Regret"               },
                    { quest = 92139, unlock = 95435, name = "Shade and Claw"                  },
                    { quest = 92145, unlock = 92848, name = "The Grand Magister's Drink"      },
                    { quest = 93013, unlock = 94391, name = "Push Back the Light"             },
                    { quest = 93244, unlock = 94795, name = "Agents of the Shield"            },
                    { quest = 93438, unlock = 94743, name = "Precision Excision"              },
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
                    tip:AddLine("|cff00ff96✓ Completed this week:|r", 1, 1, 1)
                    tip:AddLine("  " .. activeAssignment.name, 0.4, 0.85, 0.4)
                elseif activeAssignment then
                    tip:AddLine("|cffffff00» Active this week:|r", 1, 1, 1)
                    tip:AddLine("  " .. activeAssignment.name, 1, 0.9, 0.3)
                    if objectiveText then
                        tip:AddLine(" ")
                        tip:AddLine(objectiveText, 0.7, 0.7, 0.7, true)
                    end
                else
                    tip:AddLine("|cffaaaaaa? Active assignment not yet detected.|r", 1, 1, 1)
                    tip:AddLine("  Visit Silvermoon to reveal this week's assignment.", 0.7, 0.7, 0.7)
                end
            end,
        },
    },
})
