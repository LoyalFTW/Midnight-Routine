local addonName = "MidnightRoutine"

local LibStub   = LibStub
local AceAddon  = LibStub("AceAddon-3.0")
local AceDB     = LibStub("AceDB-3.0")

MR = AceAddon:NewAddon(addonName, "AceEvent-3.0", "AceBucket-3.0", "AceTimer-3.0")

local DEFAULTS = {
    profile = {
        locked          = false,
        scale           = 1.0,
        hideComplete    = true,
        transparentMode = false,
        width           = 260,
        fontSize        = 11,
        panelOpen       = true,
        minimap         = { hide = false },
        modules         = {},
        moduleOrder     = {},
        position        = { point = "CENTER", x = 0, y = 0 },
    },
    char = {
        progress = {},
        lastWeek = 0,
    },
}

MR.modules = {}

function MR:RegisterModule(def)
    assert(def.key,   "MR module missing .key")
    assert(def.label, "MR module missing .label")
    assert(def.rows,  "MR module missing .rows")
    table.insert(self.modules, def)
end

function MR:GetProgress(moduleKey, rowKey)
    local m = self.db.char.progress[moduleKey]
    return m and m[rowKey] or 0
end

function MR:SetProgress(moduleKey, rowKey, value, maxVal)
    if not self.db.char.progress[moduleKey] then
        self.db.char.progress[moduleKey] = {}
    end
    self.db.char.progress[moduleKey][rowKey] = math.max(0, math.min(value, maxVal))
    self:RefreshUI()
end

function MR:BumpProgress(moduleKey, rowKey, delta, maxVal)
    self:SetProgress(moduleKey, rowKey, self:GetProgress(moduleKey, rowKey) + delta, maxVal)
end

function MR:GetOrderedModules()
    local saved = self.db.profile.moduleOrder
    if not saved or #saved == 0 then return self.modules end
    local byKey, result = {}, {}
    for _, mod in ipairs(self.modules) do byKey[mod.key] = mod end
    for _, key in ipairs(saved) do
        if byKey[key] then table.insert(result, byKey[key]); byKey[key] = nil end
    end
    for _, mod in ipairs(self.modules) do
        if byKey[mod.key] then table.insert(result, mod) end
    end
    return result
end

function MR:SetModuleOrder(orderedKeys)
    self.db.profile.moduleOrder = orderedKeys
end

function MR:IsModuleEnabled(key)
    for _, mod in ipairs(self.modules) do
        if mod.key == key and mod.profSkillLine then
            return self.playerProfessions[mod.profSkillLine] == true
        end
    end
    local s = self.db.profile.modules[key]
    return not (s and s.enabled == false)
end

function MR:IsModuleOpen(key)
    local s = self.db.profile.modules[key]
    if s == nil then
        for _, m in ipairs(self.modules) do
            if m.key == key then return m.defaultOpen ~= false end
        end
        return true
    end
    return s.open ~= false
end

function MR:SetModuleOpen(key, open)
    if not self.db.profile.modules[key] then self.db.profile.modules[key] = {} end
    self.db.profile.modules[key].open = open
end

function MR:SetModuleEnabled(key, enabled)
    for _, mod in ipairs(self.modules) do
        if mod.key == key and mod.profSkillLine then return end
    end
    if not self.db.profile.modules[key] then self.db.profile.modules[key] = {} end
    self.db.profile.modules[key].enabled = enabled
    self:RefreshUI()
end

function MR:IsRowEnabled(modKey, rowKey)
    local s = self.db.profile.modules[modKey]
    if not s or not s.hiddenRows then return true end
    local v = s.hiddenRows[rowKey]
    return v ~= false
end

function MR:SetRowEnabled(modKey, rowKey, enabled)
    if not self.db.profile.modules[modKey] then self.db.profile.modules[modKey] = {} end
    if not self.db.profile.modules[modKey].hiddenRows then
        self.db.profile.modules[modKey].hiddenRows = {}
    end
    self.db.profile.modules[modKey].hiddenRows[rowKey] = enabled and true or false
end


local PARENT_TO_MIDNIGHT = {
    [171]=2906, [164]=2907, [333]=2909, [202]=2910, [182]=2912,
    [773]=2913, [755]=2914, [165]=2915, [186]=2916, [393]=2917, [197]=2918,
}

MR.playerProfessions = MR.playerProfessions or {}

function MR:RefreshPlayerProfessions()
    wipe(self.playerProfessions)


    if C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines then
        local lines = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
        if lines then
            for _, skillLineID in ipairs(lines) do
                local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID and
                             C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)

                if info and (info.skillLevel or 0) > 0 then
                    self.playerProfessions[skillLineID] = true
                    if info.parentProfessionID then
                        local mid = PARENT_TO_MIDNIGHT[info.parentProfessionID]
                        if mid then self.playerProfessions[mid] = true end
                    end
                end
            end
        end
    end


    for _, idx in ipairs({ GetProfessions() }) do
        if idx then
            local _, _, _, _, _, _, parentSkillLine = GetProfessionInfo(idx)
            if parentSkillLine then
                local mid = PARENT_TO_MIDNIGHT[parentSkillLine]
                if mid then self.playerProfessions[mid] = true end
            end
        end
    end
end


local function Snapshot(progress)
    local snap = {}
    for mk, rows in pairs(progress) do
        snap[mk] = {}
        for rk, v in pairs(rows) do snap[mk][rk] = v end
    end
    return snap
end

local function SnapshotChanged(before, after)
    for mk, rows in pairs(after) do
        if not before[mk] then return true end
        for rk, v in pairs(rows) do
            if before[mk][rk] ~= v then return true end
        end
    end
    return false
end

function MR:ScanQuests()
    local progress = self.db.char.progress
    local before   = Snapshot(progress)


    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do
            if row.questIds then
                local done = 0
                for _, qid in ipairs(row.questIds) do
                    if C_QuestLog.IsQuestFlaggedCompleted(qid) then done = done + 1 end
                end
                done = math.min(done, row.max or #row.questIds)
                if not progress[mod.key] then progress[mod.key] = {} end
                progress[mod.key][row.key] = done
            end
        end
    end


    for _, mod in ipairs(self.modules) do
        if mod.onScan then mod.onScan(mod) end
    end


    for _, mod in ipairs(self.modules) do
        local mdb = progress[mod.key]
        if mdb then
            for _, row in ipairs(mod.rows) do
                if row.liveKey and mdb[row.liveKey] ~= nil then
                    mdb[row.key] = math.min(mdb[row.liveKey], row.max)
                end
                if row.liveTierLabelKey and mdb[row.liveTierLabelKey] then
                    row.vaultLabel = mdb[row.liveTierLabelKey]
                end
                if row.liveTierColorKey and mdb[row.liveTierColorKey] then
                    row.vaultColor = mdb[row.liveTierColorKey]
                end
            end
        end
    end


    if SnapshotChanged(before, Snapshot(progress)) then
        self:RefreshUI()
    end
end


function MR:GetCurrentWeekKey()
    local secondsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
    return math.floor((GetServerTime() + secondsUntilReset) / 604800)
end

function MR:CheckWeeklyReset()
    local currentWeek = self:GetCurrentWeekKey()
    if self.db.char.lastWeek ~= currentWeek then
        self.db.char.lastWeek = currentWeek
        self:DoWeeklyReset()
    end
end

function MR:DoWeeklyReset()
    for _, mod in ipairs(self.modules) do
        if mod.resetType == "weekly" then
            self.db.char.progress[mod.key] = {}
        end
    end
    self:ScanQuests()
    print("|cff2ae7c6MidnightRoutine:|r Weekly reset applied.")
end


function MR:OnInitialize()

    self.db = AceDB:New("MidnightRoutineDB", DEFAULTS, true)
end

function MR:OnEnable()


    self:RegisterBucketEvent({
        "QUEST_LOG_UPDATE",
        "UNIT_QUEST_LOG_CHANGED",
        "QUEST_TURNED_IN",
        "LFG_COMPLETION_REWARD",
    }, 1, "ScanQuests")


    self:RegisterBucketEvent({
        "SKILL_LINES_CHANGED",
        "TRADE_SKILL_LIST_UPDATE",
        "SKILL_LINE_SPECS_RANKS_CHANGED",
        "TRADE_SKILL_SHOW",
    }, 1, "OnProfessionChange")


    self:RegisterBucketEvent({
        "CURRENCY_DISPLAY_UPDATE",
    }, 2, "OnCurrencyChanged")


    self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "OnVaultEvent")
    self:RegisterEvent("ENCOUNTER_END",            "OnEncounterEnd")
    self:RegisterEvent("WEEKLY_REWARDS_UPDATE",    "OnVaultEvent")
    self:RegisterEvent("PLAYER_ENTERING_WORLD",    "OnEnteringWorld")
end

function MR:OnEnteringWorld()
    self:CheckWeeklyReset()
    self:RefreshPlayerProfessions()

    if not self.frame then
        self:BuildUI()
    else
        self:RefreshUI()
    end

    if self.frame and self.db.profile.panelOpen == false then
        self.frame:Hide()
    end


    self:ScheduleTimer(function()
        self:RefreshPlayerProfessions()
        self:RefreshUI()
    end, 0.5)

    self:ScanQuests()
end

function MR:OnProfessionChange()
    self:RefreshPlayerProfessions()
    self:RefreshUI()
end

function MR:OnCurrencyChanged()

    local progress = self.db.char.progress
    local before   = Snapshot(progress)
    for _, mod in ipairs(self.modules) do
        if mod.onScan and mod.currencyTracked then
            mod.onScan(mod)
        end
    end
    if SnapshotChanged(before, Snapshot(progress)) then
        self:RefreshUI()
    end
end

function MR:OnVaultEvent()

    self:ScheduleTimer(function() self:ScanQuests() end, 1.5)
end

function MR:OnEncounterEnd(_, _, _, _, _, success)
    if success == 1 then
        self:ScheduleTimer(function() self:ScanQuests() end, 1.5)
    end
end


SLASH_MIDROUTE1 = "/mr"
SLASH_MIDROUTE2 = "/midroute"
SlashCmdList["MIDROUTE"] = function(msg)
    msg = (msg or ""):lower():trim()
    if     msg == "reset"   then
        MR:DoWeeklyReset()
    elseif msg == "lock"    then
        MR.db.profile.locked = true
        if MR.frame then MR.frame:SetMovable(false) end
        print("|cff2ae7c6MidnightRoutine:|r Frame locked.")
    elseif msg == "unlock"  then
        MR.db.profile.locked = false
        if MR.frame then MR.frame:SetMovable(true) end
        print("|cff2ae7c6MidnightRoutine:|r Frame unlocked.")
    elseif msg == "hide"    then
        if MR.frame then MR.frame:Hide() end
        MR.db.profile.panelOpen = false
    elseif msg == "show"    then
        if MR.frame then MR.frame:Show() end
        MR.db.profile.panelOpen = true
    elseif msg == "minimap" then
        local newHide = not (MR.db.profile.minimap and MR.db.profile.minimap.hide)
        MR:SetMinimapHidden(newHide)
        print("|cff2ae7c6MidnightRoutine:|r Minimap icon " .. (newHide and "hidden" or "shown") .. ".")
    elseif msg:match("^scale %d") then
        local s = tonumber(msg:match("scale (%S+)"))
        if s and s >= 0.5 and s <= 2 then
            MR.db.profile.scale = s
            if MR.frame then MR.frame:SetScale(s) end
        end
    elseif msg == "big"     then
        if MR.ApplyWidth then MR.ApplyWidth(500) end
    elseif msg == "small"   then
        if MR.ApplyWidth then MR.ApplyWidth(200) end
    else
        print("|cff2ae7c6/mr|r – commands: show, hide, lock, unlock, reset, minimap, scale <0.5-2>, big, small")
    end
end
