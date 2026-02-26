MR = MR or {}

local DEFAULTS = {
    position        = { point = "CENTER", x = 0, y = 0 },
    locked          = false,
    scale           = 1.0,
    hideComplete    = true,
    modules         = {},
    progress        = {},
    moduleOrder     = {},
    transparentMode = false,
    width           = 260,
}

MR.modules = {}

function MR:RegisterModule(def)
    assert(def.key,   "MR module missing .key")
    assert(def.label, "MR module missing .label")
    assert(def.rows,  "MR module missing .rows")
    table.insert(self.modules, def)
end

function MR:GetOrderedModules()
    local saved = MidnightRoutineDB.moduleOrder
    if not saved or #saved == 0 then return self.modules end
    local byKey = {}
    for _, mod in ipairs(self.modules) do byKey[mod.key] = mod end
    local result = {}
    for _, key in ipairs(saved) do
        if byKey[key] then
            table.insert(result, byKey[key])
            byKey[key] = nil
        end
    end
    for _, mod in ipairs(self.modules) do
        if byKey[mod.key] then table.insert(result, mod) end
    end
    return result
end

function MR:SetModuleOrder(orderedKeys)
    MidnightRoutineDB.moduleOrder = orderedKeys
end

function MR:GetProgress(moduleKey, rowKey)
    local m = MidnightRoutineDB.progress[moduleKey]
    return m and m[rowKey] or 0
end

function MR:SetProgress(moduleKey, rowKey, value, max)
    if not MidnightRoutineDB.progress[moduleKey] then
        MidnightRoutineDB.progress[moduleKey] = {}
    end
    MidnightRoutineDB.progress[moduleKey][rowKey] = math.max(0, math.min(value, max))
    MR:RefreshUI()
end

function MR:BumpProgress(moduleKey, rowKey, delta, max)
    local cur = self:GetProgress(moduleKey, rowKey)
    self:SetProgress(moduleKey, rowKey, cur + delta, max)
end

function MR:ScanQuests()
    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do
            if row.questIds then
                local done = 0
                for _, qid in ipairs(row.questIds) do
                    if C_QuestLog.IsQuestFlaggedCompleted(qid) then
                        done = done + 1
                    end
                end
                done = math.min(done, row.max or #row.questIds)
                if not MidnightRoutineDB.progress[mod.key] then
                    MidnightRoutineDB.progress[mod.key] = {}
                end
                MidnightRoutineDB.progress[mod.key][row.key] = done
            end
        end
    end
    MR:RefreshUI()
end

MR.playerProfessions = MR.playerProfessions or {}

local PARENT_TO_MIDNIGHT = {
    [171] = 2906,
    [164] = 2907,
    [333] = 2909,
    [202] = 2910,
    [182] = 2912,
    [773] = 2913,
    [755] = 2914,
    [165] = 2915,
    [186] = 2916,
    [393] = 2917,
    [197] = 2918,
}

function MR:RefreshPlayerProfessions()
    self.playerProfessions = {}
    if C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines then
        local lines = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
        if lines then
            for _, skillLineID in pairs(lines) do
                local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID and
                             C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
                if info and (info.skillLevel or 0) > 0 then
                    self.playerProfessions[skillLineID] = true
                    if info.parentProfessionID then
                        local midnightID = PARENT_TO_MIDNIGHT[info.parentProfessionID]
                        if midnightID then
                            self.playerProfessions[midnightID] = true
                        end
                    end
                end
            end
        end
    end
    for _, idx in pairs({ GetProfessions() }) do
        if idx then
            local _, _, _, _, _, _, parentSkillLine = GetProfessionInfo(idx)
            if parentSkillLine then
                local midnightID = PARENT_TO_MIDNIGHT[parentSkillLine]
                if midnightID then
                    self.playerProfessions[midnightID] = true
                end
            end
        end
    end
end

function MR:IsModuleEnabled(key)
    for _, mod in ipairs(self.modules) do
        if mod.key == key and mod.profSkillLine then
            return self.playerProfessions[mod.profSkillLine] == true
        end
    end
    local s = MidnightRoutineDB and MidnightRoutineDB.modules and MidnightRoutineDB.modules[key]
    if s ~= nil and s.enabled == false then return false end
    return true
end

function MR:IsModuleOpen(key)
    local s = MidnightRoutineDB.modules[key]
    if s == nil then
        for _, m in ipairs(self.modules) do
            if m.key == key then return m.defaultOpen ~= false end
        end
        return true
    end
    return s.open ~= false
end

function MR:SetModuleOpen(key, open)
    if not MidnightRoutineDB.modules[key] then MidnightRoutineDB.modules[key] = {} end
    MidnightRoutineDB.modules[key].open = open
end

function MR:SetModuleEnabled(key, enabled)
    for _, mod in ipairs(self.modules) do
        if mod.key == key and mod.profSkillLine then return end
    end
    if not MidnightRoutineDB.modules[key] then MidnightRoutineDB.modules[key] = {} end
    MidnightRoutineDB.modules[key].enabled = enabled
    MR:RefreshUI()
end

function MR:CheckWeeklyReset()
    local currentWeek = math.floor(GetServerTime() / 604800)
    if MidnightRoutineDB.lastWeek ~= currentWeek then
        MidnightRoutineDB.lastWeek = currentWeek
        self:DoWeeklyReset()
    end
end

function MR:DoWeeklyReset()
    for _, mod in ipairs(self.modules) do
        if mod.resetType == "weekly" or mod.resetType == "daily" then
            MidnightRoutineDB.progress[mod.key] = {}
        end
    end
    self:ScanQuests()
    print("|cff2ae7c6MidnightRoutine:|r Weekly reset applied.")
end

SLASH_MIDROUTE1 = "/mr"
SLASH_MIDROUTE2 = "/midroute"
SlashCmdList["MIDROUTE"] = function(msg)
    msg = msg:lower():trim()
    if msg == "reset" then
        MR:DoWeeklyReset()
    elseif msg == "lock" then
        MidnightRoutineDB.locked = true
        MR.frame:SetMovable(false)
        print("|cff2ae7c6MidnightRoutine:|r Frame locked.")
    elseif msg == "unlock" then
        MidnightRoutineDB.locked = false
        MR.frame:SetMovable(true)
        print("|cff2ae7c6MidnightRoutine:|r Frame unlocked.")
    elseif msg == "hide" then
        MR.frame:Hide()
    elseif msg == "show" then
        MR.frame:Show()
    elseif msg:match("^scale %d") then
        local s = tonumber(msg:match("scale (%S+)"))
        if s and s >= 0.5 and s <= 2 then
            MidnightRoutineDB.scale = s
            MR.frame:SetScale(s)
        end
    elseif msg == "big" then
        if MR.ApplyWidth then MR.ApplyWidth(500) end
        print("|cff2ae7c6MidnightRoutine:|r Max width applied.")
    elseif msg == "small" then
        if MR.ApplyWidth then MR.ApplyWidth(200) end
        print("|cff2ae7c6MidnightRoutine:|r Min width applied.")
    else
        print("|cff2ae7c6/mr|r commands: show, hide, lock, unlock, reset, scale <0.5-2>, big, small")
    end
end

local bootstrap = CreateFrame("Frame")
bootstrap:RegisterEvent("ADDON_LOADED")
bootstrap:RegisterEvent("PLAYER_LOGIN")
bootstrap:RegisterEvent("PLAYER_ENTERING_WORLD")
bootstrap:RegisterEvent("QUEST_TURNED_IN")
bootstrap:RegisterEvent("QUEST_LOG_UPDATE")
bootstrap:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
bootstrap:RegisterEvent("LFG_COMPLETION_REWARD")
bootstrap:RegisterEvent("SKILL_LINES_CHANGED")
bootstrap:RegisterEvent("TRADE_SKILL_LIST_UPDATE")

local function DeferredProfessionRefresh()
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        MR:RefreshPlayerProfessions()
        MR:RefreshUI()
    end)
end

bootstrap:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "MidnightRoutine" then
        if not MidnightRoutineDB then MidnightRoutineDB = {} end
        for k, v in pairs(DEFAULTS) do
            if MidnightRoutineDB[k] == nil then
                MidnightRoutineDB[k] = v
            end
        end

    elseif event == "PLAYER_LOGIN" then
        MR:CheckWeeklyReset()
        MR:ScanQuests()

    elseif event == "PLAYER_ENTERING_WORLD" then
        MR:RefreshPlayerProfessions()
        if not MR.frame then
            MR:BuildUI()
        else
            MR:RefreshUI()
        end
        DeferredProfessionRefresh()

    elseif event == "SKILL_LINES_CHANGED" then
        MR:RefreshPlayerProfessions()
        MR:RefreshUI()

    elseif event == "TRADE_SKILL_LIST_UPDATE" then
        MR:RefreshPlayerProfessions()
        MR:RefreshUI()

    elseif event == "QUEST_TURNED_IN"
        or event == "QUEST_LOG_UPDATE"
        or event == "UNIT_QUEST_LOG_CHANGED" then
        MR:ScanQuests()

    elseif event == "LFG_COMPLETION_REWARD" then
        MR:ScanQuests()
    end
end)
