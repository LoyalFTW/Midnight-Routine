local _, ns = ...
if not ns.MR.isForever then return end
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)
local F = ns.Forever

function F.GetProfessionTasks(profession)
    local mod = ns.MR.moduleByKey.forever_professions
    local row = { key = "profession_" .. profession.skillLine, label = L["Forever_Skill"], mode = "count", max = profession.maxRank, autoTracked = true, icon = profession.icon }
    local done = profession.rank >= profession.maxRank
    local rows = {}
    if ns.MR:IsRowEnabled(mod.key, row.key) and not (done and ns.MR.db.profile.gatheringHideCompleted) then
        rows[1] = { mod = mod, row = row, group = "other", category = "other", current = profession.rank, max = profession.maxRank, done = done }
    end
    return rows, done and 1 or 0, 1
end

function F.AddRareLocationTooltip(tooltip, rare)
    if rare.observedLocation then
        tooltip:AddLine(L["Forever_RareRecordedLocation"], 0.7, 0.7, 0.7, true)
    end
    local target = F.GetRareWaypoint(rare)
    if target then
        tooltip:AddLine(string.format(L["Gathering_Coords"], target.x, target.y), 0.7, 1, 0.9)
        if #rare.locations > 1 then
            tooltip:AddLine(string.format(L["Forever_RareLocationCount"], #rare.locations), 0.7, 0.7, 0.7, true)
        end
    else
        tooltip:AddLine(L["Forever_RareLocationUnknown"], 0.7, 0.7, 0.7, true)
    end
end
