local addonName, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Core = assert(ns.CoreInternals, "Core/Foundation.lua must load first")
local DeepCopy = Core.DeepCopy
local MergeMissing = Core.MergeMissing
local RestoreDefaults = Core.RestoreDefaults
local IsTableEmpty = Core.IsTableEmpty
local MODULES_WITH_OPTIONAL_CURRENCY_COMPLETION = Core.optionalCurrencyModules
local IsInRestrictedCombat = Core.IsInRestrictedCombat

function MR:RegisterExpansion(def)
    assert(type(def) == "table", "MR expansion registration requires a table")
    assert(def.key, "MR expansion missing .key")

    local existing = self.expansions[def.key] or {}
    self.expansions[def.key] = {
        key = def.key,
        label = def.label or existing.label or def.key,
        shortLabel = def.shortLabel or existing.shortLabel or def.label or def.key,
        order = def.order or existing.order or 100,
    }
end

function MR:QueueCombatDeferredUpdate(flag)
    if not flag then
        return
    end

    self._combatDeferred = self._combatDeferred or {}
    self._combatDeferred[flag] = true
end

function MR:IsCombatUpdatesDisabled()
    local inCombat = IsInRestrictedCombat()
        or (UnitAffectingCombat and UnitAffectingCombat("player"))
    return inCombat and self.db and self.db.profile and self.db.profile.disabledInCombat == true
end

function MR:ShouldDeferForCombat(flag)
    if not self:IsCombatUpdatesDisabled() then
        return false
    end

    self:QueueCombatDeferredUpdate(flag)
    return true
end

function MR:QueueDeferredProgressUpdate(moduleKey, rowKey, value, maxVal)
    self._combatDeferredProgress = self._combatDeferredProgress or {}
    self._combatDeferredProgress[moduleKey] = self._combatDeferredProgress[moduleKey] or {}
    self._combatDeferredProgress[moduleKey][rowKey] = {
        moduleKey = moduleKey,
        rowKey = rowKey,
        value = value,
        maxVal = maxVal,
    }
    self:QueueCombatDeferredUpdate("refreshUI")
end

function MR:FlushCombatDeferredUpdates()
    if self:IsCombatUpdatesDisabled() then
        return
    end

    local pending = self._combatDeferred
    local deferredProgress = self._combatDeferredProgress

    self._combatDeferred = nil
    self._combatDeferredProgress = nil

    if pending and pending.weeklyReset and self.DoWeeklyReset then
        self:DoWeeklyReset()
        pending.weeklyReset = nil
    end

    if pending and pending.dailyReset and self.DoDailyReset then
        self:DoDailyReset()
        pending.dailyReset = nil
    end

    if pending and pending.instanceVisibility and self.UpdateInstanceFrameVisibility then
        self:UpdateInstanceFrameVisibility()
        pending.instanceVisibility = nil
    end

    if pending and pending.playerProfessions and self.RefreshPlayerProfessions then
        self:RefreshPlayerProfessions()
        pending.playerProfessions = nil
    end

    if pending and pending.professionConcentration and self.RefreshProfessionConcentration then
        self:RefreshProfessionConcentration()
        pending.professionConcentration = nil
    end

    if deferredProgress then
        for _, moduleEntries in pairs(deferredProgress) do
            for _, entry in pairs(moduleEntries) do
                local progressBucket = self.GetProgressBucket and self:GetProgressBucket(entry.moduleKey, entry.rowKey) or self.db.char.progress
                if not progressBucket[entry.moduleKey] then
                    progressBucket[entry.moduleKey] = {}
                end
                progressBucket[entry.moduleKey][entry.rowKey] = math.max(0, math.min(entry.value, entry.maxVal))
            end
        end
    end

    if pending and pending.scan and self.Scan then
        self:Scan()
        pending.scan = nil
    end

    if pending and pending.refreshUI and self.RefreshUI then
        self:RefreshUI()
    end

    if pending and pending.gatheringFrame then
        if self.RequestProfessionKnowledgeSurfaceRefresh then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        elseif self.RefreshGatheringLocationsFrame then
            self:RefreshGatheringLocationsFrame()
        end
    end

    if pending and pending.rares and self.RefreshRares then
        self:RefreshRares()
    end

    if pending and pending.renown and self.RefreshRenown then
        self:RefreshRenown()
    end
end

function MR:OnCombatEnded()
    if self.UpdateCombatDisplayState then
        self:UpdateCombatDisplayState()
    end
    self:FlushCombatDeferredUpdates()
end

function MR:OnCombatStarted()
    if self.UpdateCombatDisplayState then
        self:UpdateCombatDisplayState()
    end
end

function MR:GetModuleExpansionKey(modOrKey)
    local mod = modOrKey
    if type(modOrKey) == "string" then
        mod = self.moduleByKey[modOrKey]
    end

    return (mod and mod.expansionKey) or "midnight"
end

function MR:GetModulePatchKey(modOrKey)
    local mod = modOrKey
    if type(modOrKey) == "string" then
        mod = self.moduleByKey[modOrKey]
    end

    return mod and mod.patchKey or nil
end

function MR:GetRowPatchKey(modOrKey, row)
    if row and row.patchKey then
        return row.patchKey
    end
    return self:GetModulePatchKey(modOrKey)
end

function MR:GetExpansionInfo(key)
    key = key or "midnight"
    return self.expansions[key] or {
        key = key,
        label = key,
        shortLabel = key,
        order = 999,
    }
end

local _questNameCache = {}
local _questNamePending = {}

function MR:GetQuestName(questId, fallback)
    if not questId then
        return fallback
    end

    if _questNameCache[questId] then
        return _questNameCache[questId]
    end

    if C_QuestLog and C_QuestLog.GetTitleForQuestID then
        local title = C_QuestLog.GetTitleForQuestID(questId)
        if title and title ~= "" then
            _questNameCache[questId] = title
            _questNamePending[questId] = nil
            return title
        end
    end

    if not _questNamePending[questId] then
        if C_QuestLog and C_QuestLog.RequestLoadQuestByID then
            C_QuestLog.RequestLoadQuestByID(questId)
        end
        _questNamePending[questId] = true
    end

    return fallback
end

function MR:GetAvailableExpansions()
    local seen = {}
    local result = {}

    for key, info in pairs(self.expansions or {}) do
        seen[key] = true
        result[#result + 1] = self:GetExpansionInfo(key)
    end

    for _, mod in ipairs(self.modules) do
        local key = self:GetModuleExpansionKey(mod)
        if not seen[key] then
            seen[key] = true
            result[#result + 1] = self:GetExpansionInfo(key)
        end
    end

    table.sort(result, function(a, b)
        local ao = a.order or 999
        local bo = b.order or 999
        if ao ~= bo then
            return ao < bo
        end
        return (a.label or a.key) < (b.label or b.key)
    end)

    return result
end

function MR:GetSelectableExpansions()
    local counts = {}
    for _, mod in ipairs(self.modules) do
        local key = self:GetModuleExpansionKey(mod)
        counts[key] = (counts[key] or 0) + 1
    end

    local result = {}
    for key, count in pairs(counts) do
        if count > 0 then
            result[#result + 1] = self:GetExpansionInfo(key)
        end
    end

    table.sort(result, function(a, b)
        local ao = a.order or 999
        local bo = b.order or 999
        if ao ~= bo then
            return ao < bo
        end
        return (a.label or a.key) < (b.label or b.key)
    end)

    return result
end

function MR:GetSelectedExpansionKey(forAltBoard)
    if not (self and self.db and self.db.profile) then
        return "midnight"
    end

    local key = forAltBoard and self.db.profile.altBoardSelectedExpansion or self.db.profile.selectedExpansion
    if key and self.expansions[key] then
        return key
    end

    return "midnight"
end

function MR:SetSelectedExpansionKey(key, forAltBoard)
    key = key or "midnight"
    if not self.expansions[key] then
        key = "midnight"
    end

    if forAltBoard then
        self.db.profile.altBoardSelectedExpansion = key
        if self.altBoardFrame and self.altBoardFrame:IsShown() then
            if self.RequestWarbandBoardRefresh then
                self:RequestWarbandBoardRefresh(true)
            elseif self.RefreshWarbandBoard then
                self:RefreshWarbandBoard()
            end
        end
        return
    end

    self.db.profile.selectedExpansion = key
    self._orderedModulesCache = nil
    self._orderedAllModulesCache = nil
    if self.RefreshUI then
        self:RefreshUI()
    end
end

function MR:GetVisibleExpansionModules(expansionKey)
    expansionKey = expansionKey or self:GetSelectedExpansionKey()
    local result = {}
    for _, mod in ipairs(self.modules) do
        if self:GetModuleExpansionKey(mod) == expansionKey then
            result[#result + 1] = mod
        end
    end
    return result
end

function MR:RegisterModule(def)
    assert(def.key,   "MR module missing .key")
    assert(def.label, "MR module missing .label")
    assert(def.rows,  "MR module missing .rows")
    def.expansionKey = def.expansionKey or "midnight"

    if self.moduleByKey[def.key] then
        error(("MR duplicate module key: %s"):format(tostring(def.key)))
    end

    table.insert(self.modules, def)
    self.moduleByKey[def.key] = def
    self._orderedModulesCache = nil
    self._orderedAllModulesCache = nil

    if self.RebuildTurnInCompletions then
        self:RebuildTurnInCompletions()
    end

    if self.db and not def.skipRegisterScan then
        if self.Scan then
            self:Scan()
        elseif self.RefreshUI then
            self:RefreshUI()
        end
    end
end

function MR:GetWeeklyRewardActivityBuckets()
    local buckets = {
        dungeon = {},
        raid = {},
        world = {},
    }

    if not (C_WeeklyRewards and C_WeeklyRewards.GetActivities) then
        return buckets
    end

    local activities = C_WeeklyRewards.GetActivities()
    if not activities then
        return buckets
    end

    for _, activity in ipairs(activities) do
        if activity.type == 1 then
            table.insert(buckets.dungeon, activity)
        elseif activity.type == 3 then
            table.insert(buckets.raid, activity)
        elseif activity.type == 6 then
            table.insert(buckets.world, activity)
        elseif activity.type == 4 and #buckets.world == 0 then
            table.insert(buckets.world, activity)
        end
    end

    return buckets
end


function MR:GetPatchInfo(key)
    key = key or "general"
    if key == "general" then
        return {
            key = "general",
            label = L["Patch_General"] or "General",
            shortLabel = L["Patch_GeneralShort"] or "General",
            order = 0,
        }
    end
    return self.patches[key] or {
        key = key,
        label = key,
        shortLabel = key,
        order = 999999,
    }
end

function MR:GetPatchSortOrder(key)
    if not key then
        return 0
    end
    local info = self:GetPatchInfo(key)
    return info.order or 999999
end

local function OrderedRowsCacheMatches(cache, sourceRows, savedOrder)
    local savedCount = savedOrder and #savedOrder or 0
    if not cache or #cache.sourceRows ~= #sourceRows or #cache.savedOrder ~= savedCount then
        return false
    end
    for index, row in ipairs(sourceRows) do
        if cache.sourceRows[index] ~= row then
            return false
        end
    end
    if savedOrder then
        for index, rowKey in ipairs(savedOrder) do
            if cache.savedOrder[index] ~= rowKey then
                return false
            end
        end
    end
    return true
end

local function CacheOrderedRows(mod, sourceRows, savedOrder, rows)
    local sourceSnapshot = {}
    local orderSnapshot = {}
    for index, row in ipairs(sourceRows) do sourceSnapshot[index] = row end
    if savedOrder then
        for index, rowKey in ipairs(savedOrder) do orderSnapshot[index] = rowKey end
    end
    mod._orderedRowsCache = {
        sourceRows = sourceSnapshot,
        savedOrder = orderSnapshot,
        rows = rows,
    }
    return rows
end

function MR:GetOrderedRows(mod)
    if not mod or type(mod.rows) ~= "table" then
        return {}
    end

    local storage = self.GetActiveModuleStorage and self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod)) or nil
    local state = storage and storage[mod.key]
    local savedOrder = state and state.rowOrder
    if type(savedOrder) ~= "table" then
        savedOrder = nil
    end
    if OrderedRowsCacheMatches(mod._orderedRowsCache, mod.rows, savedOrder) then
        return mod._orderedRowsCache.rows
    end

    local ordered = {}
    for index, row in ipairs(mod.rows) do
        ordered[#ordered + 1] = { row = row, index = index }
    end

    table.sort(ordered, function(a, b)
        local ao = self:GetPatchSortOrder(self:GetRowPatchKey(mod, a.row))
        local bo = self:GetPatchSortOrder(self:GetRowPatchKey(mod, b.row))
        if ao ~= bo then
            return ao < bo
        end
        return a.index < b.index
    end)

    local baseRows = {}
    for _, entry in ipairs(ordered) do
        baseRows[#baseRows + 1] = entry.row
    end

    if not savedOrder or #savedOrder == 0 then
        return CacheOrderedRows(mod, mod.rows, savedOrder, baseRows)
    end

    local byKey, used, reorderedRows, rows = {}, {}, {}, {}
    for _, row in ipairs(baseRows) do
        if row and row.key and not row.control then
            byKey[row.key] = row
        end
    end
    for _, rowKey in ipairs(savedOrder) do
        local row = byKey[rowKey]
        if row and not used[rowKey] then
            reorderedRows[#reorderedRows + 1] = row
            used[rowKey] = true
        end
    end
    for _, row in ipairs(baseRows) do
        if row and row.key and not row.control and not used[row.key] then
            reorderedRows[#reorderedRows + 1] = row
        end
    end

    local reorderedIndex = 1
    for _, row in ipairs(baseRows) do
        if row and row.control then
            rows[#rows + 1] = row
        else
            rows[#rows + 1] = reorderedRows[reorderedIndex] or row
            reorderedIndex = reorderedIndex + 1
        end
    end
    return CacheOrderedRows(mod, mod.rows, savedOrder, rows)
end

function MR:RegisterPatch(def)
    assert(type(def) == "table", "MR patch registration requires a table")
    assert(def.key, "MR patch missing .key")

    local existing = self.patches[def.key] or {}
    self.patches[def.key] = {
        key = def.key,
        label = def.label or existing.label or def.key,
        shortLabel = def.shortLabel or existing.shortLabel or def.label or def.key,
        order = def.order or existing.order or 999999,
        minInterface = def.minInterface or existing.minInterface,
    }
end


function MR:GetProfessionKnowledgePosition()
    if not self.db then
        return nil
    end
    if self:IsCharacterWindowLayoutEnabled() then
        return tonumber(self.db.char and self.db.char.professionKnowledgePosition)
    end
    return tonumber(self.db.profile and self.db.profile.professionKnowledgePosition)
end

function MR:SetProfessionKnowledgePosition(position)
    if not self.db then
        return
    end
    position = math.max(0, math.floor((tonumber(position) or 0) + 0.5))
    if self:IsCharacterWindowLayoutEnabled() then
        self.db.char.professionKnowledgePosition = position
    else
        self.db.profile.professionKnowledgePosition = position
    end
    self._orderedAllModulesCache = nil
end

function MR:GetOrderedModules(expansionKey)
    if expansionKey == "all" then
        if self._orderedAllModulesCache then
            return self._orderedAllModulesCache
        end

        local normalModules, professionBlocks, trailing = {}, {}, {}
        for _, expansion in ipairs(self:GetSelectableExpansions()) do
            for _, mod in ipairs(self:GetOrderedModules(expansion.key)) do
                if mod.profSkillLine then
                    professionBlocks[expansion.key] = professionBlocks[expansion.key] or {}
                    professionBlocks[expansion.key][#professionBlocks[expansion.key] + 1] = mod
                elseif mod.configGroup == "story" or (type(mod.key) == "string" and mod.key:match("^story_campaign_")) then
                    trailing[#trailing + 1] = mod
                else
                    normalModules[#normalModules + 1] = mod
                end
            end
        end
        local professionModules = {}
        for _, expansion in ipairs(self:GetSelectableExpansions()) do
            for _, mod in ipairs(professionBlocks[expansion.key] or {}) do
                professionModules[#professionModules + 1] = mod
            end
        end
        local position = self:GetProfessionKnowledgePosition()
        if position == nil then
            position = #normalModules
        end
        position = math.max(0, math.min(math.floor(position), #normalModules))
        local result = {}
        for index = 0, #normalModules do
            if index == position then
                for _, mod in ipairs(professionModules) do
                    result[#result + 1] = mod
                end
            end
            if index < #normalModules then
                result[#result + 1] = normalModules[index + 1]
            end
        end
        for _, mod in ipairs(trailing) do
            result[#result + 1] = mod
        end
        self._orderedAllModulesCache = result
        return result
    end

    expansionKey = expansionKey or self:GetSelectedExpansionKey()
    if expansionKey == self:GetSelectedExpansionKey() and self._orderedModulesCache then
        return self._orderedModulesCache
    end
    local modules = self:GetVisibleExpansionModules(expansionKey)
    local saved = self:GetActiveModuleOrderStorage(expansionKey)
    local function ApplyPinnedModuleOrder(source)
        if type(source) ~= "table" or not self.pinnedModuleOrder then
            return source
        end

        local result = {}
        local pinned = {}
        for _, mod in ipairs(source) do
            local pin = mod and self.pinnedModuleOrder[mod.key]
            if pin then
                pinned[#pinned + 1] = { mod = mod, pin = pin }
            else
                result[#result + 1] = mod
            end
        end

        table.sort(pinned, function(a, b)
            if a.pin ~= b.pin then
                return a.pin < b.pin
            end
            return (a.mod.key or "") < (b.mod.key or "")
        end)

        for i = #pinned, 1, -1 do
            table.insert(result, 1, pinned[i].mod)
        end
        return result
    end

    if not saved or #saved == 0 then
        modules = ApplyPinnedModuleOrder(modules)
        if expansionKey == self:GetSelectedExpansionKey() then
            self._orderedModulesCache = modules
        end
        return modules
    end
    local result, seen = {}, {}
    for _, mod in ipairs(modules) do seen[mod.key] = mod end
    for _, key in ipairs(saved) do
        if seen[key] then table.insert(result, seen[key]); seen[key] = nil end
    end
    for _, mod in ipairs(modules) do
        if seen[mod.key] then table.insert(result, mod) end
    end
    result = ApplyPinnedModuleOrder(result)
    if expansionKey == self:GetSelectedExpansionKey() then
        self._orderedModulesCache = result
    end
    return result
end

function MR:GetActiveModuleStorage(expansionKey)
    if not (self and self.db) then
        return nil
    end

    expansionKey = expansionKey or self:GetSelectedExpansionKey()

    if self:IsCharacterWindowLayoutEnabled() then
        self.db.char.expansionModuleStates = self.db.char.expansionModuleStates or {}
        if expansionKey == "midnight" then
            self.db.char.modules = self.db.char.modules or {}
            self.db.char.expansionModuleStates[expansionKey] = self.db.char.modules
        else
            self.db.char.expansionModuleStates[expansionKey] = self.db.char.expansionModuleStates[expansionKey] or {}
        end
        return self.db.char.expansionModuleStates[expansionKey]
    end

    self.db.profile.expansionModuleStates = self.db.profile.expansionModuleStates or {}
    if expansionKey == "midnight" then
        self.db.profile.modules = self.db.profile.modules or {}
        self.db.profile.expansionModuleStates[expansionKey] = self.db.profile.modules
    else
        self.db.profile.expansionModuleStates[expansionKey] = self.db.profile.expansionModuleStates[expansionKey] or {}
    end
    return self.db.profile.expansionModuleStates[expansionKey]
end

function MR:GetActiveProfessionModuleStorage(charData)
    if not self then
        return nil
    end

    charData = charData or (self.GetMainFrameProgressSource and self:GetMainFrameProgressSource()) or (self.db and self.db.char)
    if type(charData) ~= "table" then
        return nil
    end

    charData.professionModuleStates = charData.professionModuleStates or {}
    return charData.professionModuleStates
end

function MR:GetActiveModuleOrderStorage(expansionKey)
    if not (self and self.db) then
        return nil
    end

    expansionKey = expansionKey or self:GetSelectedExpansionKey()

    if self:IsCharacterWindowLayoutEnabled() then
        self.db.char.expansionModuleOrder = self.db.char.expansionModuleOrder or {}
        if expansionKey == "midnight" then
            self.db.char.moduleOrder = self.db.char.moduleOrder or {}
            self.db.char.expansionModuleOrder[expansionKey] = self.db.char.moduleOrder
        else
            self.db.char.expansionModuleOrder[expansionKey] = self.db.char.expansionModuleOrder[expansionKey] or {}
        end
        return self.db.char.expansionModuleOrder[expansionKey]
    end

    self.db.profile.expansionModuleOrder = self.db.profile.expansionModuleOrder or {}
    if expansionKey == "midnight" then
        self.db.profile.moduleOrder = self.db.profile.moduleOrder or {}
        self.db.profile.expansionModuleOrder[expansionKey] = self.db.profile.moduleOrder
    else
        self.db.profile.expansionModuleOrder[expansionKey] = self.db.profile.expansionModuleOrder[expansionKey] or {}
    end
    return self.db.profile.expansionModuleOrder[expansionKey]
end

function MR:SetModuleOrder(orderedKeys, expansionKey)
    if expansionKey == "all" then
        local grouped = {}
        for _, key in ipairs(orderedKeys or {}) do
            local mod = self.moduleByKey and self.moduleByKey[key]
            local modExpansionKey = self:GetModuleExpansionKey(mod)
            grouped[modExpansionKey] = grouped[modExpansionKey] or {}
            grouped[modExpansionKey][#grouped[modExpansionKey] + 1] = key
        end

        for key, order in pairs(grouped) do
            self:SetModuleOrder(order, key)
        end
        self._orderedModulesCache = nil
        self._orderedAllModulesCache = nil
        return
    end

    expansionKey = expansionKey or self:GetSelectedExpansionKey()
    if self:IsCharacterWindowLayoutEnabled() then
        self.db.char.expansionModuleOrder = self.db.char.expansionModuleOrder or {}
        self.db.char.expansionModuleOrder[expansionKey] = orderedKeys
        if expansionKey == "midnight" then
            self.db.char.moduleOrder = orderedKeys
        end
    else
        self.db.profile.expansionModuleOrder = self.db.profile.expansionModuleOrder or {}
        self.db.profile.expansionModuleOrder[expansionKey] = orderedKeys
        if expansionKey == "midnight" then
            self.db.profile.moduleOrder = orderedKeys
        end
    end
    self._orderedModulesCache = nil
    self._orderedAllModulesCache = nil
end

function MR:IsModuleEnabled(key)
    local mod = self.moduleByKey[key]
    if mod and not self:IsModuleAvailable(mod) then
        return false
    end
    local professionSource = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or nil
    local storage = (mod and mod.profSkillLine) and self:GetActiveProfessionModuleStorage(professionSource)
        or self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod or key))
    local s = storage and storage[key]
    if mod and mod.profSkillLine and self.HasProfessionForModule and not self:HasProfessionForModule(mod.profSkillLine, professionSource) then
        return false
    end
    if mod and not self:IsPatchEnabled(mod.patchKey, key) then
        local hasEnabledPatchRows = false
        for _, row in ipairs(mod.rows or {}) do
            if self:GetRowPatchKey(mod, row) ~= mod.patchKey and self:IsPatchEnabled(self:GetRowPatchKey(mod, row), key) then
                hasEnabledPatchRows = true
                break
            end
        end
        if not hasEnabledPatchRows then
            return false
        end
    end
    if not s and not self:ShouldAutoEnableNewModules() and not self:IsModuleKnown(key) then
        return false
    end
    if mod and mod.profSkillLine then
        if not s and mod.defaultEnabled == false then
            return false
        end
        return not (s and s.enabled == false and s.professionDisabled == true)
    end
    if not s and mod and mod.defaultEnabled == false then
        return false
    end
    return not (s and s.enabled == false)
end

function MR:ShouldAutoEnableNewModules()
    return not (self.db and self.db.profile and self.db.profile.autoEnableNewModules == false)
end

function MR:GetActiveKnownModuleStorage()
    if not (self.db and self.db.profile) then return nil end
    self.db.profile.knownModules = self.db.profile.knownModules or {}
    return self.db.profile.knownModules
end

function MR:IsModuleKnown(key)
    local known = self:GetActiveKnownModuleStorage()
    return known and known[key] == true or false
end

function MR:SetAutoEnableNewModules(enabled)
    if not (self.db and self.db.profile) then return end
    enabled = enabled ~= false
    local wasEnabled = self:ShouldAutoEnableNewModules()
    if not enabled and wasEnabled then
        local known = self:GetActiveKnownModuleStorage()
        if known then
            for _, mod in ipairs(self.modules or {}) do
                if self:IsModuleAvailable(mod) then
                    known[mod.key] = true
                end
            end
        end
    end
    self.db.profile.autoEnableNewModules = enabled
    self._moduleStatsCache = nil
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.01)
    elseif self.RefreshUI then
        self:RefreshUI()
    end
end

function MR:GetStoryCampaignsEnabledPreference()
    if not self.db then
        return nil
    end
    local settings = self:IsCharacterWindowLayoutEnabled() and self.db.char or self.db.profile
    return settings and settings.storyCampaignsEnabled
end

function MR:SetStoryCampaignsEnabledPreference(enabled)
    if not self.db then
        return
    end
    local settings = self:IsCharacterWindowLayoutEnabled() and self.db.char or self.db.profile
    settings.storyCampaignsEnabled = enabled and true or false
end

function MR:ShouldHideProfessionModuleInMain(mod)
    local profile = self.db and self.db.profile
    if not (profile and profile.professionKnowledgeShowTasks ~= false and profile.professionKnowledgeHideMainTasks == true) then
        return false
    end

    return type(mod) == "table" and mod.profSkillLine ~= nil
end

function MR:IsPatchEnabled(patchKey, modKey)
    if not patchKey then
        return true
    end
    if not self:IsPatchAvailable(patchKey) then
        return false
    end
    local states = self.db and self.db.profile and self.db.profile.patchStates
    local state = states and states[patchKey]
    if not state then
        return true
    end
    if modKey and state.modules and state.modules[modKey] ~= nil then
        return state.modules[modKey] ~= false
    end
    return state.enabled ~= false
end

function MR:IsPatchAvailable(patchKey)
    if not patchKey then
        return true
    end

    local info = self:GetPatchInfo(patchKey)
    if not info.minInterface then
        return true
    end

    local interfaceVersion = GetBuildInfo and select(4, GetBuildInfo()) or 0
    return (tonumber(interfaceVersion) or 0) >= info.minInterface
end

function MR:IsModuleAvailable(modOrKey)
    local mod = modOrKey
    if type(modOrKey) == "string" then
        mod = self.moduleByKey and self.moduleByKey[modOrKey]
    end
    return not mod or self:IsPatchAvailable(mod.patchKey)
end

function MR:SetPatchEnabled(patchKey, modKey, enabled, skipRefresh)
    if not (self and self.db and self.db.profile and patchKey and modKey) then
        return
    end
    if not self:IsPatchAvailable(patchKey) then
        return
    end

    self.db.profile.patchStates = self.db.profile.patchStates or {}
    self.db.profile.patchStates[patchKey] = self.db.profile.patchStates[patchKey] or {}
    self.db.profile.patchStates[patchKey].modules = self.db.profile.patchStates[patchKey].modules or {}
    self.db.profile.patchStates[patchKey].modules[modKey] = enabled and true or false
    if not skipRefresh then
        self:RefreshUI()
    end
end

function MR:IsModuleOpen(key)
    local mod = self.moduleByKey and self.moduleByKey[key]
    local storage = self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod or key))
    local s = storage and storage[key]
    if s == nil then
        local mod = self.moduleByKey[key]
        return not mod or mod.defaultOpen ~= false
    end
    return s.open ~= false
end

function MR:IsModuleDetached(key)
    local mod = self.moduleByKey and self.moduleByKey[key]
    local storage = self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod or key))
    local s = storage and storage[key]
    return s and s.detached == true or false
end

function MR:SetModuleOpen(key, open)
    local mod = self.moduleByKey and self.moduleByKey[key]
    local storage = self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod or key))
    if not storage[key] then storage[key] = {} end
    storage[key].open = open
end

function MR:SetModuleDetached(key, detached)
    local mod = self.moduleByKey and self.moduleByKey[key]
    local storage = self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod or key))
    if not storage[key] then storage[key] = {} end
    storage[key].detached = detached and true or false
end

function MR:GetDetachedModulePosition(key)
    local mod = self.moduleByKey and self.moduleByKey[key]
    local storage = self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod or key))
    local s = storage and storage[key]
    return s and s.detachedPos or nil
end

function MR:SetDetachedModulePosition(key, point, relPoint, x, y)
    local mod = self.moduleByKey and self.moduleByKey[key]
    local storage = self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod or key))
    if not storage[key] then storage[key] = {} end
    storage[key].detachedPos = {
        point = point,
        relPoint = relPoint,
        x = x,
        y = y,
    }
end

function MR:GetDetachedModuleSize(key)
    local mod = self.moduleByKey and self.moduleByKey[key]
    local storage = self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod or key))
    local s = storage and storage[key]
    return s and s.detachedSize or nil
end

function MR:SetDetachedModuleSize(key, width, height)
    local mod = self.moduleByKey and self.moduleByKey[key]
    local storage = self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod or key))
    if not storage[key] then storage[key] = {} end
    storage[key].detachedSize = {
        width = width,
        height = height,
    }
end

function MR:SetModuleEnabled(key, enabled, skipRefresh)
    local mod = self.moduleByKey and self.moduleByKey[key]
    if mod and not self:IsModuleAvailable(mod) then
        return
    end
    local professionSource = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or nil
    local storage = (mod and mod.profSkillLine) and self:GetActiveProfessionModuleStorage(professionSource)
        or self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod or key))
    if not storage[key] then storage[key] = {} end
    storage[key].enabled = enabled
    if mod and mod.profSkillLine then
        storage[key].professionManual = enabled and true or nil
        storage[key].professionDisabled = enabled and nil or true
    end
    if enabled and mod and self.PrimeModuleData then
        self:PrimeModuleData(mod)
        self._moduleStatsCache = nil
    end
    if not skipRefresh then
        if self.RequestUIRefresh then
            self:RequestUIRefresh(0.01)
        else
            self:RefreshUI()
        end
    end
end

