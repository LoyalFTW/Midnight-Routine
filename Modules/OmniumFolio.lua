local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local OMNIUM_WEEKLIES = {
    { quest = 96410, label = L["Omnium_Week1_Label"], fallback = "Week 1: The Omnium Folio" },
    { quest = 96441, label = L["Omnium_Week2_Label"], fallback = "Week 2: Ritualized Arcana" },
    { quest = 96442, label = L["Omnium_Week3_Label"], fallback = "Week 3: Leyline Assaults" },
    { quest = 96443, label = L["Omnium_Week4_Label"], fallback = "Week 4: Magical Primessence" },
    { quest = 96444, label = L["Omnium_Week5_Label"], fallback = "Week 5: Off-World Magic" },
}

local function IsQuestActive(questId)
    if not questId or not C_QuestLog then
        return false
    end

    if C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(questId) then
        return true
    end

    if C_QuestLog.GetLogIndexForQuestID and C_QuestLog.GetLogIndexForQuestID(questId) then
        return true
    end

    if C_GossipInfo and C_GossipInfo.GetAvailableQuests then
        local quests = C_GossipInfo.GetAvailableQuests()
        for _, info in ipairs(quests or {}) do
            if info.questID == questId then
                return true
            end
        end
    end

    return false
end

local function BuildRows()
    local rows = {
        {
            key = "folio_progress",
            label = L["Omnium_Progress_Label"] or "|cffc792ffOmnium Folio Progress:|r",
            max = 5,
            note = L["Omnium_Progress_Note"] or "Complete the five Seeking Knowledge quests to unlock every Omnium Folio rune row. Missed weeks can be caught up until you are current.",
            patchKey = "12.0.7",
            control = true,
            sectionHeader = true,
            hideStatus = true,
            noDefaultTooltipHint = true,
        },
    }

    for index, weekly in ipairs(OMNIUM_WEEKLIES) do
        rows[#rows + 1] = {
            key = "week_" .. index,
            label = weekly.label or weekly.fallback,
            max = 1,
            note = L["Omnium_Weekly_Note"] or "Seeking Knowledge quest from Grand Magister Rommath at the Sunstrider Omnium. If you are behind, missed quests can be completed back-to-back.",
            questIds = { weekly.quest },
            patchKey = "12.0.7",
            tooltipFunc = function(tip)
                tip:AddLine(" ")
                tip:AddLine(MR:GetQuestName(weekly.quest, weekly.fallback), 0.76, 0.55, 1)
                tip:AddLine(string.format(L["Omnium_QuestID_Format"] or "Quest ID: %d", weekly.quest), 0.6, 0.7, 0.8)
            end,
        }
    end

    return rows
end

MR:RegisterModule({
    key = "omnium_folio",
    label = L["Omnium_Title"] or "Omnium Folio",
    labelColor = "#c792ff",
    resetType = "weekly",
    defaultOpen = true,
    patchKey = "12.0.7",

    onScan = function(mod)
        local db = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end

        local beforeProgress = db[mod.key].folio_progress
        local beforeActiveName = db[mod.key].active_week_name
        local completed = 0
        local activeName
        for index, weekly in ipairs(OMNIUM_WEEKLIES) do
            local rowKey = "week_" .. index
            local done = C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(weekly.quest)
            db[mod.key][rowKey] = done and 1 or 0
            if done then
                completed = completed + 1
            elseif not activeName and IsQuestActive(weekly.quest) then
                activeName = MR:GetQuestName(weekly.quest, weekly.fallback)
            end
        end

        db[mod.key].folio_progress = completed
        db[mod.key].active_week_name = activeName

        for _, row in ipairs(mod.rows) do
            if row.key == "folio_progress" then
                if completed >= 5 then
                    row.countText = L["Done"] or "Done"
                    row.countColor = { 0.4, 0.85, 0.4 }
                elseif activeName then
                    row.countText = activeName
                    row.countColor = { 1, 0.9, 0.3 }
                else
                    row.countText = string.format("%d / 5", completed)
                    row.countColor = nil
                end
                break
            end
        end

        return beforeProgress ~= completed or beforeActiveName ~= activeName
    end,

    rows = BuildRows(),
})
