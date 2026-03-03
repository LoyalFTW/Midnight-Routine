local addonName = "MidnightRoutine"

local LibStub  = LibStub
local AceAddon = LibStub("AceAddon-3.0")
local AceDB    = LibStub("AceDB-3.0")

MR = AceAddon:NewAddon(addonName, "AceEvent-3.0", "AceBucket-3.0", "AceTimer-3.0")

local DEFAULTS = {
    profile = {
        locked          = false,
        scale           = 1.0,
        frameAlpha      = 1.0,
        hideComplete    = true,
        transparentMode = false,
        width           = 260,
        height          = 400,
        fontSize        = 11,
        panelOpen       = true,
        minimap         = { hide = false },
        firstSeen       = false,
        modules         = {},
        moduleOrder     = {},
        position        = { point = "CENTER", x = 0, y = 0 },
        renownOpen          = false,
        renownPos           = nil,
        renownLocked        = false,
        renownWidth         = 280,
        renownBarH          = 18,
        renownAlpha         = 1.0,
        renownShowRep       = true,
        renownShowIcons     = true,
        renownShimmer       = true,
        renownHideMaxed     = false,
        renownHiddenFactions = {},
        renownColors         = {},
        renownOrder          = {},
        renownCompact        = false,
        renownScale          = 1.0,
        renownShowLevel      = true,
        headerColors    = {},
    },
    char = {
        progress = {},
        lastWeek = 0,
    },
}

MR.modules     = {}
MR.moduleByKey = {}

function MR:RegisterModule(def)
    assert(def.key,   "MR module missing .key")
    assert(def.label, "MR module missing .label")
    assert(def.rows,  "MR module missing .rows")
    table.insert(self.modules, def)
    self.moduleByKey[def.key] = def
    self._orderedModulesCache = nil
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
    if self._orderedModulesCache then return self._orderedModulesCache end
    local saved = self.db.profile.moduleOrder
    if not saved or #saved == 0 then
        self._orderedModulesCache = self.modules
        return self.modules
    end
    local result, seen = {}, {}
    for _, mod in ipairs(self.modules) do seen[mod.key] = mod end
    for _, key in ipairs(saved) do
        if seen[key] then table.insert(result, seen[key]); seen[key] = nil end
    end
    for _, mod in ipairs(self.modules) do
        if seen[mod.key] then table.insert(result, mod) end
    end
    self._orderedModulesCache = result
    return result
end

function MR:SetModuleOrder(orderedKeys)
    self.db.profile.moduleOrder  = orderedKeys
    self._orderedModulesCache = nil
end

function MR:IsModuleEnabled(key)
    local mod = self.moduleByKey[key]
    if mod and mod.profSkillLine and not self.playerProfessions[mod.profSkillLine] then
        return false
    end
    local s = self.db.profile.modules[key]
    return not (s and s.enabled == false)
end

function MR:IsModuleOpen(key)
    local s = self.db.profile.modules[key]
    if s == nil then
        local mod = self.moduleByKey[key]
        return not mod or mod.defaultOpen ~= false
    end
    return s.open ~= false
end

function MR:SetModuleOpen(key, open)
    if not self.db.profile.modules[key] then self.db.profile.modules[key] = {} end
    self.db.profile.modules[key].open = open
end

function MR:SetModuleEnabled(key, enabled)
    if not self.db.profile.modules[key] then self.db.profile.modules[key] = {} end
    self.db.profile.modules[key].enabled = enabled
    self:RefreshUI()
end

function MR:IsModuleHideComplete(modKey)
    local s = self.db.profile.modules[modKey]
    if s and s.hideComplete ~= nil then return s.hideComplete end
    return self.db.profile.hideComplete
end

function MR:SetModuleHideComplete(modKey, value)
    if not self.db.profile.modules[modKey] then self.db.profile.modules[modKey] = {} end
    self.db.profile.modules[modKey].hideComplete = value
    self:RefreshUI()
end

function MR:IsRowEnabled(modKey, rowKey)
    local s = self.db.profile.modules[modKey]
    if not s or not s.hiddenRows then return true end
    return s.hiddenRows[rowKey] ~= false
end

function MR:SetRowEnabled(modKey, rowKey, enabled)
    if not self.db.profile.modules[modKey] then self.db.profile.modules[modKey] = {} end
    if not self.db.profile.modules[modKey].hiddenRows then
        self.db.profile.modules[modKey].hiddenRows = {}
    end
    self.db.profile.modules[modKey].hiddenRows[rowKey] = enabled and true or false
end

function MR:GetHeaderColor(modKey)
    if self.db.profile.headerColors and self.db.profile.headerColors[modKey] then
        return self.db.profile.headerColors[modKey]
    end
    local mod = self.moduleByKey[modKey]
    return mod and mod.labelColor or "#ffffff"
end

function MR:SetHeaderColor(modKey, hexColor)
    if not self.db.profile.headerColors then
        self.db.profile.headerColors = {}
    end
    self.db.profile.headerColors[modKey] = hexColor
    self:RefreshUI()
end

function MR:ResetHeaderColor(modKey)
    if self.db.profile.headerColors then
        self.db.profile.headerColors[modKey] = nil
    end
    self:RefreshUI()
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

local spellIndex = {}

function MR:BuildSpellIndex()
    wipe(spellIndex)
    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do
            if row.spellId then
                spellIndex[row.spellId] = {
                    modKey = mod.key,
                    rowKey = row.key,
                    amount = row.spellAmount or 1,
                    max    = row.max or 1,
                }
            end
        end
    end
end

local function WriteProgress(progress, modKey, rowKey, val)
    if not progress[modKey] then progress[modKey] = {} end
    if progress[modKey][rowKey] == val then return false end
    progress[modKey][rowKey] = val
    return true
end

function MR:Scan()
    local progress = self.db.char.progress
    local dirty    = false

    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do
            if row.questIds then
                local done = 0
                for _, qid in ipairs(row.questIds) do
                    if C_QuestLog.IsQuestFlaggedCompleted(qid) then done = done + 1 end
                end
                if WriteProgress(progress, mod.key, row.key, math.min(done, row.max or done)) then
                    dirty = true
                end
            end
            if row.currencyId then
                local info = C_CurrencyInfo.GetCurrencyInfo(row.currencyId)
                if info then
                    local hasWeeklyCap = info.maxWeeklyQuantity and info.maxWeeklyQuantity > 0
                    local raw
                    if hasWeeklyCap then
                        raw = info.quantityEarnedThisWeek
                    elseif row.max and info.quantity >= row.max then
                        raw = row.max
                    else
                        raw = info.quantity
                    end
                    local val = row.noMax and raw or math.min(raw, row.max or raw)
                    if WriteProgress(progress, mod.key, row.key, val) then dirty = true end
                end
            end
        end

        if mod.onScan then
            local before = progress[mod.key] and next(progress[mod.key])
            mod.onScan(mod)
            if progress[mod.key] and next(progress[mod.key]) ~= before then dirty = true end
        end

        local mdb = progress[mod.key]
        if mdb then
            for _, row in ipairs(mod.rows) do
                if row.liveKey and row.liveKey ~= row.key and mdb[row.liveKey] ~= nil then
                    local capped = row.noMax and mdb[row.liveKey] or math.min(mdb[row.liveKey], row.max)
                    if mdb[row.key] ~= capped then mdb[row.key] = capped; dirty = true end
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

    if dirty then self:RefreshUI() end
end

function MR:GetCurrentWeekKey()
    local secondsUntilReset = C_DateAndTime.GetSecondsUntilWeeklyReset()
    if not secondsUntilReset or secondsUntilReset <= 0 then return nil end
    return math.floor((GetServerTime() + secondsUntilReset) / 604800)
end

function MR:CheckWeeklyReset()
    local currentWeek = self:GetCurrentWeekKey()
    if not currentWeek then return end
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
    self:Scan()
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
        "CURRENCY_DISPLAY_UPDATE",
    }, 1, "Scan")

    self:RegisterBucketEvent({
        "AREA_POIS_UPDATED",
    }, 2, "Scan")

    self:RegisterBucketEvent({
        "SKILL_LINES_CHANGED",
        "TRADE_SKILL_LIST_UPDATE",
        "SKILL_LINE_SPECS_RANKS_CHANGED",
        "TRADE_SKILL_SHOW",
    }, 1, "OnProfessionChange")

    self:RegisterBucketEvent({
        "ZONE_CHANGED_NEW_AREA",
        "ZONE_CHANGED",
    }, 0.5, "OnZoneChanged")

    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellCast")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED", "OnVaultEvent")
    self:RegisterEvent("ENCOUNTER_END",            "OnEncounterEnd")
    self:RegisterEvent("WEEKLY_REWARDS_UPDATE",    "OnVaultEvent")
    self:RegisterEvent("PLAYER_ENTERING_WORLD",    "OnEnteringWorld")

end

function MR:OnEnteringWorld()
    self:RefreshPlayerProfessions()
    self:BuildSpellIndex()

    if not self.db.profile.firstSeen then
        self.db.profile.panelOpen  = false
        self.db.profile.renownOpen = false
    end

    if not self.frame then
        self:BuildUI()
    else
        self:RefreshUI()
    end
    if self.frame and self.db.profile.panelOpen == false then
        self.frame:Hide()
    end
    self:MaybeShowWelcomeScreen()
    if self.OnRenownUpdate then
        self:RegisterEvent("MAJOR_FACTION_RENOWN_LEVEL_CHANGED", "OnRenownUpdate")
        self:RegisterBucketEvent({
            "UPDATE_FACTION",
            "COMBAT_TEXT_UPDATE",
        }, 1, "OnRenownUpdate")
    end
    if self.db.profile.renownOpen and self.ToggleRenown then
        self:ScheduleTimer(function() self:ToggleRenown() end, 1.5)
    end
    self:ScheduleTimer(function()
        self:CheckWeeklyReset()
        self:RefreshPlayerProfessions()
        self:RefreshUI()
    end, 0.5)
    self:ScheduleTimer(function() self:Scan() end, 5)
    self:Scan()
end

function MR:OnProfessionChange()
    self:RefreshPlayerProfessions()
    self:RefreshUI()
end

function MR:OnSpellCast(_, unit, _, spellID)
    if unit ~= "player" then return end
    local entry = spellIndex[spellID]
    if not entry then return end
    self:BumpProgress(entry.modKey, entry.rowKey, entry.amount, entry.max)
end

function MR:OnVaultEvent()
    self:ScheduleTimer(function() self:Scan() end, 1.5)
end

function MR:OnZoneChanged()
    self:Scan()
    self:RefreshUI()
end

function MR:OnEncounterEnd(_, _, _, _, _, success)
    if success == 1 then
        self:ScheduleTimer(function() self:Scan() end, 1.5)
    end
end

SLASH_MIDROUTE1 = "/mr"
SLASH_MIDROUTE2 = "/midroute"
SlashCmdList["MIDROUTE"] = function(msg)
    msg = (msg or ""):lower():trim()
    if     msg == "reset"   then MR:DoWeeklyReset()
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
    elseif msg == "big"   then if MR.ApplyWidth then MR.ApplyWidth(500) end
    elseif msg == "small"   then if MR.ApplyWidth then MR.ApplyWidth(200) end
    elseif msg == "welcome" then MR:ShowWelcomeScreen()
    elseif msg == "renown"  then MR:ToggleRenown()
    elseif msg == "renown config" then MR:ToggleRenownConfig()
    else
        print("|cff2ae7c6/mr|r commands: show, hide, lock, unlock, reset, minimap, scale <0.5-2>, big, small, welcome, renown")
    end
end
