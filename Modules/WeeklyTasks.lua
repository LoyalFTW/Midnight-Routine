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
        local db = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end

        for _, a in ipairs(SA_ASSIGNMENTS) do
            if C_QuestLog.IsQuestFlaggedCompleted(a.quest) then
                db[mod.key]["special_assignment"] = 1
                db[mod.key]["sa_active_name"]     = a.name
                return
            end
        end

        for _, a in ipairs(SA_ASSIGNMENTS) do
            if C_QuestLog.IsOnQuest(a.unlock) or C_QuestLog.IsQuestFlaggedCompleted(a.unlock) then
                db[mod.key]["sa_active_name"] = a.name
                return
            end
        end

        db[mod.key]["sa_active_name"] = nil
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
