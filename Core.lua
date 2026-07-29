local addonName, ns = ...

local Foundry = _G.Foundry_1_0
if not Foundry then
    error(addonName .. " requires Foundry-1.0 to be loaded before Core.lua", 0)
end

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local MR = {
    name = addonName,
}
ns.MR = MR
MR.ns = ns
MR._eventController = Foundry.Events:New(addonName)
MR._timers = {}
MR._buckets = {}

local function ResolveCallback(owner, callback)
    if type(callback) == "function" then
        return callback, false
    end
    if type(callback) == "string" and type(owner[callback]) == "function" then
        return owner[callback], true
    end
    return nil
end

function MR:RegisterEvent(event, callback)
    local fn, bindSelf = ResolveCallback(self, callback or event)
    if not fn then
        error(("MidnightRoutine:RegisterEvent(%s) missing callback"):format(tostring(event)), 2)
    end

    if self._eventController:IsRegistered(event) then
        self._eventController:Unregister(event)
    end

    self._eventController:Register(event, function(firedEvent, ...)
        if bindSelf then
            fn(self, firedEvent, ...)
        else
            fn(firedEvent, ...)
        end
    end)
end

function MR:UnregisterEvent(event)
    self._eventController:Unregister(event)
end

function MR:UnregisterAllEvents()
    self._eventController:UnregisterAll()
end

function MR:RegisterBucketEvent(events, interval, callback)
    local fn, bindSelf = ResolveCallback(self, callback)
    if not fn then
        error("MidnightRoutine:RegisterBucketEvent missing callback", 2)
    end

    local bucket = self._eventController:RegisterBucket({
        events = events,
        interval = interval,
        handler = function()
            if bindSelf then
                fn(self)
            else
                fn()
            end
        end,
    })

    self._buckets[bucket] = true
    return bucket
end

function MR:UnregisterBucket(bucket)
    if bucket and bucket.Cancel then
        bucket:Cancel()
        self._buckets[bucket] = nil
    end
end

function MR:ScheduleTimer(callback, delay, ...)
    local fn, bindSelf = ResolveCallback(self, callback)
    if not fn then
        error("MidnightRoutine:ScheduleTimer missing callback", 2)
    end

    local argc = select("#", ...)
    local args = argc > 0 and { ... } or nil
    local timer
    timer = C_Timer.NewTimer(delay, function()
        self._timers[timer] = nil
        if bindSelf and args then
            fn(self, unpack(args, 1, argc))
        elseif bindSelf then
            fn(self)
        elseif args then
            fn(unpack(args, 1, argc))
        else
            fn()
        end
    end)
    self._timers[timer] = true
    return timer
end

function MR:ScheduleRepeatingTimer(callback, delay, ...)
    local fn, bindSelf = ResolveCallback(self, callback)
    if not fn then
        error("MidnightRoutine:ScheduleRepeatingTimer missing callback", 2)
    end

    local argc = select("#", ...)
    local args = argc > 0 and { ... } or nil
    local timer = C_Timer.NewTicker(delay, function()
        if bindSelf and args then
            fn(self, unpack(args, 1, argc))
        elseif bindSelf then
            fn(self)
        elseif args then
            fn(unpack(args, 1, argc))
        else
            fn()
        end
    end)
    self._timers[timer] = true
    return timer
end

function MR:CancelTimer(timer)
    if timer and timer.Cancel then
        timer:Cancel()
        self._timers[timer] = nil
    end
end

function MR:CancelAllTimers()
    for timer in pairs(self._timers) do
        if timer.Cancel then
            timer:Cancel()
        end
        self._timers[timer] = nil
    end
end

local MODULES_WITH_OPTIONAL_CURRENCY_COMPLETION = {
    currencies = true,
    pvp_currencies = true,
}

local DEFAULTS = {
    profile = {
        locked          = false,
        scale           = 1.0,
        minimized       = false,
        frameAlpha      = 1.0,
        hideFramesInInstances = false,
        rememberManagedWindowsVisibility = false,
        managedWindowsBundleHidden       = false,
        transparentMode = false,
        keepIconsVisibleInTextMode = true,
        keepHeadersVisibleInTextMode = true,
        autoHidePanelHeaders = false,
        width           = 260,
        height          = 400,
        fontSize        = 11,
        fontMedia       = nil,
        fontFlags       = "OUTLINE",
        backgroundMedia = nil,
        minimap         = { hide = false },
        managedWindowRestoreState = nil,
        firstSeen       = false,
        welcomeSuppressed = false,
        position        = { point = "CENTER", x = 0, y = 0 },
        collapsedPosition = nil,
        renownOpen          = false,
        raresOpen           = false,
        concentrationTrackerOpen = false,
        raresPos            = nil,
        raresLocked         = false,
        raresWidth          = 300,
        raresHeight         = 360,
        currencyBrowserWidth = 360,
        currencyBrowserHeight = 460,
        raresFontSize       = 9,
        raresShimmer        = true,
        raresHiddenZones    = {},
        raresCompact        = false,
        raresMinimized      = false,
        raresScale          = 1.0,
        raresAlpha          = 1.0,
        raresHideKilled     = false,
        raresShowAllZones   = false,
        raresColors         = {},
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
        renownEmblemMode     = false,
        renownAutoHideHeader = false,
        renownMinimized      = false,
        renownScale          = 1.0,
        renownShowLevel      = true,
        renownFontSize       = 9,
        gatheringLocOpen     = false,
        gatheringLocPos      = nil,
        gatheringLocked      = false,
        gatheringWidth       = 350,
        gatheringHeight      = 450,
        gatheringMinimized   = false,
        gatheringAlpha       = 1.0,
        gatheringFontSize    = 9,
        gatheringScale       = 1.0,
        gatheringProfColors  = {},
        gatheringCollapsedProfessions = {},
        gatheringHideCompleted = false,
        professionKnowledgeShowTasks = true,
        professionKnowledgeHideMainTasks = false,
        professionKnowledgeTaskCategories = {
            quests = true,
            drops = true,
            treatises = true,
            darkmoon = true,
            catchup = true,
            other = true,
        },
        headerColors    = {},
        headerBackgroundColors = {},
        rowColors       = {},
        syncWindowScale     = false,
        syncWindowFontSize  = false,
        peekOnHover         = false,
        animatedMinimize    = false,
        mainHeaderPosition  = "top",
        showMainCharacterBar = true,
        characterWindowLayout = false,
        selectedExpansion   = "midnight",
        altBoardSelectedExpansion = "midnight",
        altBoardHiddenCharacters = {},
        altBoardCharacterNotes = {},
        altBoardShowHidden = false,
        altBoardView = "character",
        altBoardCollapsedModules = {},
        altBoardCharacterOrder = {},
        altBoardConcentrationOrder = {},
        concentrationTrackerAlpha = 1.0,
        concentrationTrackerCompact = false,
        concentrationTrackerHiddenCharacters = {},
        expansionModuleStates = {},
        expansionModuleOrder = {},
        patchStates = {},
    },
    char = {
        progress = {},
        professions = {},
        professionsScanned = false,
        professionConcentration = {},
        professionModuleStates = {},
        rowVisibility = {},
        customTasks = {},
        customTaskNextId = 1,
        customTaskDiffProgress = {},
        currencyBrowserHiddenDefaults = {},
        currencyBrowserCustom = {},
        currencyBrowserCustomOrder = {},
        currencyBrowserCollapsedHeaders = {},
        lastWeek = 0,
        lastSyncAt = 0,
        manualOverrides = {},
        welcomeSeen = false,
        raresKills = {},
        lastDailyAt = 0,
        hideComplete = true,
        panelOpen    = true,
        panelOpenUserSet = false,
        modules      = {},
        moduleOrder  = {},
        settingsMigrated = false,
        windowLayout = {},
        mediaSettings = {},
        expansionModuleStates = {},
        expansionModuleOrder = {},
    },
    global = {
        customTasks = {},
        customTaskNextId = 1,
        customTaskProgress = {},
        customTaskManualOverrides = {},
        customTaskDiffProgress = {},
    },
}

MR.modules     = {}
MR.moduleByKey = {}
MR.pinnedModuleOrder = {
    midnight_activities = 1,
    s1_weekly = 2,
}
MR.expansions  = {
    midnight = {
        key = "midnight",
        label = L["Expansion_Midnight"] or "Midnight",
        shortLabel = L["Expansion_Midnight"] or "Midnight",
        order = 100,
    },
}
MR.patches = {
    ["12.0.0"] = {
        key = "12.0.0",
        label = L["Patch_1200"] or "12.0.0 Launch",
        shortLabel = "12.0.0",
        order = 120000,
    },
    ["12.0.5"] = {
        key = "12.0.5",
        label = L["Patch_1205"] or "12.0.5",
        shortLabel = "12.0.5",
        order = 120005,
    },
    ["12.0.7"] = {
        key = "12.0.7",
        label = L["Patch_1207"] or "12.0.7 Revelations",
        shortLabel = "12.0.7",
        order = 120007,
    },
}

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function MergeMissing(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return dst
    end

    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = DeepCopy(v)
        elseif type(dst[k]) == "table" and type(v) == "table" then
            MergeMissing(dst[k], v)
        end
    end

    return dst
end

local function RestoreDefaults(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return dst
    end

    wipe(dst)
    for k, v in pairs(src) do
        dst[k] = DeepCopy(v)
    end

    return dst
end

local function IsTableEmpty(t)
    return type(t) ~= "table" or next(t) == nil
end

function MR:ReleaseFrameTree(frame)
    if not frame then
        return
    end

    if frame._mrExternalFrames then
        for _, external in ipairs(frame._mrExternalFrames) do
            self:ReleaseFrameTree(external)
        end
        frame._mrExternalFrames = nil
    end

    if frame.GetChildren then
        local children = { frame:GetChildren() }
        for _, child in ipairs(children) do
            self:ReleaseFrameTree(child)
        end
    end

    if frame.SetScript and frame.HasScript then
        for _, scriptName in ipairs({
            "OnUpdate",
            "OnEvent",
            "OnClick",
            "OnEnter",
            "OnLeave",
            "OnMouseDown",
            "OnMouseUp",
            "OnDragStart",
            "OnDragStop",
            "OnShow",
            "OnHide",
        }) do
            if frame:HasScript(scriptName) then
                frame:SetScript(scriptName, nil)
            end
        end
    end

    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end
    if frame.Hide then
        frame:Hide()
    end
    if frame.SetParent then
        frame:SetParent(nil)
    end
end

function MR:CaptureFrameScreenPosition(frame)
    if not frame or not frame.GetLeft or not frame.GetTop then
        return nil, nil
    end

    return frame:GetLeft(), frame:GetTop()
end

function MR:RestoreFrameScreenPosition(frame, left, top)
    if not frame or not left or not top or not UIParent then
        return
    end
    if not frame.ClearAllPoints or not frame.SetPoint then
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
end

local function IsInRestrictedCombat()
    return InCombatLockdown and InCombatLockdown()
end

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

    if self.RegisterEvent then
        self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEnded")
    end
end

function MR:ShouldDeferForCombat(flag)
    if not IsInRestrictedCombat() then
        return false
    end

    self:QueueCombatDeferredUpdate(flag)
    return true
end

function MR:QueueDeferredProgressUpdate(moduleKey, rowKey, value, maxVal)
    self._combatDeferredProgress = self._combatDeferredProgress or {}
    self._combatDeferredProgress[#self._combatDeferredProgress + 1] = {
        moduleKey = moduleKey,
        rowKey = rowKey,
        value = value,
        maxVal = maxVal,
    }
    self:QueueCombatDeferredUpdate("refreshUI")
end

function MR:FlushCombatDeferredUpdates()
    if IsInRestrictedCombat() then
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
        for _, entry in ipairs(deferredProgress) do
            local progressBucket = self.GetProgressBucket and self:GetProgressBucket(entry.moduleKey, entry.rowKey) or self.db.char.progress
            if not progressBucket[entry.moduleKey] then
                progressBucket[entry.moduleKey] = {}
            end
            progressBucket[entry.moduleKey][entry.rowKey] = math.max(0, math.min(entry.value, entry.maxVal))
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
    if self.UnregisterEvent then
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    end

    self:FlushCombatDeferredUpdates()
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

    if self.BuildSpellIndex then
        self:BuildSpellIndex()
    end

    if self.db then
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

function MR:GetProgress(moduleKey, rowKey)
    if moduleKey == "custom_tasks" and self.IsCustomTaskAccountWideCompletion and self:IsCustomTaskAccountWideCompletion(rowKey) then
        local progress = self.db and self.db.global and self.db.global.customTaskProgress
        local m = progress and progress[moduleKey]
        if m and m[rowKey] ~= nil then
            return m[rowKey]
        end

        local taskId = type(rowKey) == "string" and rowKey:match("^shared_task_(%d+)")
        local legacyKey = taskId and ("task_" .. taskId) or nil
        local legacyValue = legacyKey and m and m[legacyKey] or nil
        if legacyValue ~= nil then
            return legacyValue
        end

        local source = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or nil
        local function readLocalProgress(localProgress)
            local localModule = localProgress and localProgress[moduleKey]
            return localModule and (localModule[rowKey] or (legacyKey and localModule[legacyKey])) or nil
        end
        local selectedValue = readLocalProgress(source and source.progress)
        local currentValue = readLocalProgress(self.db and self.db.char and self.db.char.progress)
        local localValue = selectedValue
        if currentValue ~= nil and (localValue == nil or (tonumber(currentValue) or 0) > (tonumber(localValue) or 0)) then
            localValue = currentValue
        end
        if localValue ~= nil then
            local globalProgress = self.db and self.db.global and self.db.global.customTaskProgress
            if globalProgress then
                globalProgress[moduleKey] = globalProgress[moduleKey] or {}
                globalProgress[moduleKey][rowKey] = localValue
            end
            return localValue
        end

        return 0
    end

    local source = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or self.db.char
    local progress = source and source.progress or self.db.char.progress
    local m = progress and progress[moduleKey]
    return m and m[rowKey] or 0
end

function MR:IsRowVisibleForCharacter(mod, row, charData)
    if not row or not row.isVisible then
        return true
    end

    if mod and (mod.key == "darkmoon_faire" or (type(row.key) == "string" and row.key:match("_dmf$"))) then
        return row.isVisible() == true
    end

    charData = charData or (self.GetMainFrameProgressSource and self:GetMainFrameProgressSource()) or (self.db and self.db.char)
    if type(charData) == "table" and self.db and charData ~= self.db.char then
        local visibility = charData.rowVisibility
        local moduleVisibility = type(visibility) == "table" and mod and visibility[mod.key] or nil
        local savedVisible = type(moduleVisibility) == "table" and moduleVisibility[row.key] or nil
        if savedVisible ~= nil then
            return savedVisible == true
        end

        local progress = type(charData.progress) == "table" and mod and charData.progress[mod.key] or nil
        if type(progress) == "table" and (tonumber(progress[row.key]) or 0) > 0 then
            return true
        end
    end

    return row.isVisible() == true
end

function MR:GetProgressBucket(moduleKey, rowKey)
    if moduleKey == "custom_tasks" and self.IsCustomTaskAccountWideCompletion and self:IsCustomTaskAccountWideCompletion(rowKey) then
        self.db.global.customTaskProgress = self.db.global.customTaskProgress or {}
        return self.db.global.customTaskProgress
    end

    return self.db.char.progress
end

function MR:GetManualOverrideBucket(moduleKey, rowKey)
    if moduleKey == "custom_tasks" and self.IsCustomTaskAccountWideCompletion and self:IsCustomTaskAccountWideCompletion(rowKey) then
        self.db.global.customTaskManualOverrides = self.db.global.customTaskManualOverrides or {}
        return self.db.global.customTaskManualOverrides
    end

    return self.db.char.manualOverrides
end

local function IsDefaultProgressValue(value)
    return type(value) == "number" and value == 0
end

local function RemoveEmptyProgressBucket(progress, modKey)
    if progress[modKey] and next(progress[modKey]) == nil then
        progress[modKey] = nil
    end
end

local function SetProgressValue(progress, modKey, rowKey, val)
    if IsDefaultProgressValue(val) then
        local bucket = progress[modKey]
        if not bucket or bucket[rowKey] == nil then
            RemoveEmptyProgressBucket(progress, modKey)
            return false
        end
        bucket[rowKey] = nil
        RemoveEmptyProgressBucket(progress, modKey)
        return true
    end

    if not progress[modKey] then progress[modKey] = {} end
    if progress[modKey][rowKey] == val then return false end
    progress[modKey][rowKey] = val
    return true
end

local function PruneProgressStore(progress)
    if type(progress) ~= "table" then
        return false
    end

    local dirty = false
    for modKey, bucket in pairs(progress) do
        if type(bucket) == "table" then
            for rowKey, value in pairs(bucket) do
                if IsDefaultProgressValue(value) then
                    bucket[rowKey] = nil
                    dirty = true
                end
            end
            if next(bucket) == nil then
                progress[modKey] = nil
                dirty = true
            end
        end
    end

    return dirty
end

function MR:SetProgress(moduleKey, rowKey, value, maxVal, bypassInstanceSuspend)
    local progressBucket = self.GetProgressBucket and self:GetProgressBucket(moduleKey, rowKey) or self.db.char.progress
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() and not bypassInstanceSuspend then
        if not progressBucket[moduleKey] then
            progressBucket[moduleKey] = {}
        end
        if moduleKey == "custom_tasks" and type(rowKey) == "string" and rowKey:match("^shared_task_") then
            local taskId = rowKey:match("^shared_task_(%d+)")
            if taskId then
                progressBucket[moduleKey]["task_" .. taskId] = nil
            end
        end
        SetProgressValue(progressBucket, moduleKey, rowKey, math.max(0, math.min(value, maxVal)))
        return
    end

    if self:ShouldDeferForCombat("refreshUI") then
        self:QueueDeferredProgressUpdate(moduleKey, rowKey, value, maxVal)
        return
    end

    if not progressBucket[moduleKey] then
        progressBucket[moduleKey] = {}
    end
    if moduleKey == "custom_tasks" and type(rowKey) == "string" and rowKey:match("^shared_task_") then
        local taskId = rowKey:match("^shared_task_(%d+)")
        if taskId then
            progressBucket[moduleKey]["task_" .. taskId] = nil
        end
    end
    SetProgressValue(progressBucket, moduleKey, rowKey, math.max(0, math.min(value, maxVal)))
    self:RefreshUI()
    local mod = self.moduleByKey and self.moduleByKey[moduleKey]
    if mod and mod.profSkillLine and self.RefreshProfessionKnowledgeSurfaces then
        self:RequestProfessionKnowledgeSurfaceRefresh()
    end
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

function MR:GetOrderedRows(mod)
    if not mod or type(mod.rows) ~= "table" then
        return {}
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

    local storage = self.GetActiveModuleStorage and self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod)) or nil
    local state = storage and storage[mod.key]
    local savedOrder = state and state.rowOrder
    if type(savedOrder) ~= "table" or #savedOrder == 0 then
        return baseRows
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
    return rows
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
    }
end

function MR:ApplyScaleToAll(v)
    self.db.profile.scale          = v
    self.db.profile.raresScale     = v
    self.db.profile.renownScale    = v
    self.db.profile.gatheringScale = v
    if self.frame then self.frame:SetScale(v) end
    local rf = self.raresFrame
    if rf and rf:IsShown() then rf:SetScale(v) end
    local rnf = self.renownFrame
    if rnf and rnf:IsShown() then rnf:SetScale(v) end
    local gf = self.gatheringLocationsFrame
    if gf and gf:IsShown() then gf:SetScale(v) end
    if self.detachedFrames then
        for _, frame in pairs(self.detachedFrames) do
            frame:SetScale(v)
        end
    end
    if self.RepopulateRaresConfig     then self:RepopulateRaresConfig() end
    if self.RepopulateGatheringConfig then self:RepopulateGatheringConfig() end
    if self.RepopulateRenownConfig    then self:RepopulateRenownConfig() end
    if self.RequestConfigRepopulate then
        self:RequestConfigRepopulate(nil, 0.06)
    elseif self.RepopulateConfigFrame then
        self:RepopulateConfigFrame()
    end
end

function MR:ApplyFontSizeToAll(v)
    self.db.profile.fontSize          = v
    self.db.profile.raresFontSize     = v
    self.db.profile.gatheringFontSize = v
    self.db.profile.renownFontSize    = v
    if self.ApplySharedMediaSettings then
        self:ApplySharedMediaSettings()
    elseif self.RequestVisualRefresh then
        self:RequestVisualRefresh({ config = false })
    end
    if self.raresFrame and self.raresFrame.IsShown and self.raresFrame:IsShown() and self.RebuildRaresFrame then
        self:RebuildRaresFrame()
    end
    if self.RebuildRenownFrame            then self:RebuildRenownFrame() end
    if self.RepopulateRaresConfig     then self:RepopulateRaresConfig() end
    if self.RepopulateGatheringConfig then self:RepopulateGatheringConfig() end
    if self.RepopulateRenownConfig    then self:RepopulateRenownConfig() end
    if self.RequestConfigRepopulate then
        self:RequestConfigRepopulate(nil, 0.06)
    elseif self.RepopulateConfigFrame then
        self:RepopulateConfigFrame()
    end
end

function MR:BumpProgress(moduleKey, rowKey, delta, maxVal, bypassInstanceSuspend)
    local current = self:GetProgress(moduleKey, rowKey)
    self:SetProgress(moduleKey, rowKey, current + delta, maxVal, bypassInstanceSuspend)
end

local function CleanDisplayLabel(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end
    return text:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
end

function MR:SetWaypoint(target)
    local mapID = target and target.zone
    local x = target and target.x and (target.x / 100)
    local y = target and target.y and (target.y / 100)
    local tomTom = _G and rawget(_G, "TomTom")

    if not mapID or not x or not y then
        return false, "Invalid coordinates"
    end

    local title = target.waypointTitle or CleanDisplayLabel(target.label)

    if tomTom and tomTom.AddWaypoint then
        local ok = pcall(function()
            tomTom:AddWaypoint(mapID, x, y, {
                title = title,
                persistent = false,
                minimap = true,
                world = true,
            })
        end)
        if ok then return true, "TomTom" end
    end

    if UiMapPoint and UiMapPoint.CreateFromCoordinates and C_Map and C_Map.SetUserWaypoint then
        local point = UiMapPoint.CreateFromCoordinates(mapID, x, y)
        if point then
            C_Map.SetUserWaypoint(point)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
            return true, "Blizzard" end
    end

    return false, "No waypoint API available"
end

function MR:GetManualOverride(modKey, rowKey)
    if modKey == "custom_tasks" and self.IsCustomTaskAccountWideCompletion and self:IsCustomTaskAccountWideCompletion(rowKey) then
        local m = self.db and self.db.global and self.db.global.customTaskManualOverrides
        local modOverrides = m and m[modKey]
        if modOverrides and modOverrides[rowKey] ~= nil then
            return modOverrides[rowKey]
        end

        local taskId = type(rowKey) == "string" and rowKey:match("^shared_task_(%d+)")
        local legacyKey = taskId and ("task_" .. taskId) or nil
        local legacyValue = legacyKey and modOverrides and modOverrides[legacyKey] or nil
        if legacyValue ~= nil then
            return legacyValue
        end

        local source = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or nil
        local function readLocalOverride(localOverrides)
            local localModule = localOverrides and localOverrides[modKey]
            return localModule and (localModule[rowKey] or (legacyKey and localModule[legacyKey])) or nil
        end
        local selectedValue = readLocalOverride(source and source.manualOverrides)
        local currentValue = readLocalOverride(self.db and self.db.char and self.db.char.manualOverrides)
        local localValue = selectedValue
        if currentValue ~= nil and (localValue == nil or (tonumber(currentValue) or 0) > (tonumber(localValue) or 0)) then
            localValue = currentValue
        end
        if localValue ~= nil then
            local globalOverrides = self.db and self.db.global and self.db.global.customTaskManualOverrides
            if globalOverrides then
                globalOverrides[modKey] = globalOverrides[modKey] or {}
                globalOverrides[modKey][rowKey] = localValue
            end
            return localValue
        end

        return 0
    end

    local source = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or self.db.char
    local m = source and source.manualOverrides or self.db.char.manualOverrides
    return (m and m[modKey] and m[modKey][rowKey]) or 0
end

function MR:SetManualOverride(modKey, rowKey, val, maxVal)
    local overrides = self.GetManualOverrideBucket and self:GetManualOverrideBucket(modKey, rowKey) or self.db.char.manualOverrides
    if not overrides then return end
    if not overrides[modKey] then overrides[modKey] = {} end
    if modKey == "custom_tasks" and type(rowKey) == "string" and rowKey:match("^shared_task_") then
        local taskId = rowKey:match("^shared_task_(%d+)")
        if taskId then
            overrides[modKey]["task_" .. taskId] = nil
        end
    end
    if val <= 0 then
        overrides[modKey][rowKey] = nil
        self:SetProgress(modKey, rowKey, 0, maxVal or 1)
        self:Scan()
    else
        overrides[modKey][rowKey] = maxVal and math.min(val, maxVal) or val
        self:SetProgress(modKey, rowKey, overrides[modKey][rowKey], maxVal)
    end
end

function MR:GetOrderedModules(expansionKey)
    if expansionKey == "all" then
        if self._orderedAllModulesCache then
            return self._orderedAllModulesCache
        end

        local result, professionBlocks, trailing = {}, {}, {}
        for _, expansion in ipairs(self:GetSelectableExpansions()) do
            for _, mod in ipairs(self:GetOrderedModules(expansion.key)) do
                if mod.profSkillLine then
                    professionBlocks[expansion.key] = professionBlocks[expansion.key] or {}
                    professionBlocks[expansion.key][#professionBlocks[expansion.key] + 1] = mod
                elseif mod.configGroup == "story" or (type(mod.key) == "string" and mod.key:match("^story_campaign_")) then
                    trailing[#trailing + 1] = mod
                else
                    result[#result + 1] = mod
                end
            end
        end
        for _, expansion in ipairs(self:GetSelectableExpansions()) do
            for _, mod in ipairs(professionBlocks[expansion.key] or {}) do
                result[#result + 1] = mod
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
    local professionSource = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or nil
    local storage = (mod and mod.profSkillLine) and self:GetActiveProfessionModuleStorage(professionSource) or self:GetActiveModuleStorage()
    local s = storage and storage[key]
    if mod and mod.profSkillLine and self.HasProfessionForModule and not self:HasProfessionForModule(mod.profSkillLine, professionSource) then
        return false
    end
    if mod and not self:IsPatchEnabled(mod.patchKey) then
        local hasEnabledPatchRows = false
        for _, row in ipairs(mod.rows or {}) do
            if self:GetRowPatchKey(mod, row) ~= mod.patchKey and self:IsPatchEnabled(self:GetRowPatchKey(mod, row)) then
                hasEnabledPatchRows = true
                break
            end
        end
        if not hasEnabledPatchRows then
            return false
        end
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

function MR:ShouldHideProfessionModuleInMain(mod)
    local profile = self.db and self.db.profile
    if not (profile and profile.professionKnowledgeShowTasks ~= false and profile.professionKnowledgeHideMainTasks == true) then
        return false
    end

    return type(mod) == "table" and mod.profSkillLine ~= nil
end

function MR:IsPatchEnabled(patchKey)
    if not patchKey then
        return true
    end
    local states = self.db and self.db.profile and self.db.profile.patchStates
    local state = states and states[patchKey]
    return not (state and state.enabled == false)
end

function MR:SetPatchEnabled(patchKey, enabled, skipRefresh)
    if not (self and self.db and self.db.profile and patchKey) then
        return
    end

    self.db.profile.patchStates = self.db.profile.patchStates or {}
    self.db.profile.patchStates[patchKey] = self.db.profile.patchStates[patchKey] or {}
    self.db.profile.patchStates[patchKey].enabled = enabled and true or false
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
    local professionSource = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or nil
    local storage = (mod and mod.profSkillLine) and self:GetActiveProfessionModuleStorage(professionSource) or self:GetActiveModuleStorage()
    if not storage[key] then storage[key] = {} end
    storage[key].enabled = enabled
    if mod and mod.profSkillLine then
        storage[key].professionManual = enabled and true or nil
        storage[key].professionDisabled = enabled and nil or true
    end
    if not skipRefresh then
        self:RefreshUI()
    end
end

function MR:RequestUIRefresh(delay)
    if not self.ScheduleTimer then
        self:RefreshUI()
        return
    end

    delay = tonumber(delay) or 0.05
    self._refreshRequestPending = true
    if self._refreshRequestTimer and self.CancelTimer then
        self:CancelTimer(self._refreshRequestTimer)
        self._refreshRequestTimer = nil
    end

    self._refreshRequestTimer = self:ScheduleTimer(function()
        self._refreshRequestTimer = nil
        if self._refreshRequestPending then
            self._refreshRequestPending = nil
            self:RefreshUI()
        end
    end, delay)
end

function MR:RequestConfigRefresh()
    self:RequestUIRefresh(0.04)
end

function MR:RequestConfigRepopulate(reason, delay)
    if not self.ScheduleTimer then
        if self.RepopulateConfigFrame then
            self:RepopulateConfigFrame(reason)
        end
        return
    end

    delay = tonumber(delay) or 0.06
    self._configRepopulatePending = reason or true
    if self._configRepopulateTimer and self.CancelTimer then
        self:CancelTimer(self._configRepopulateTimer)
        self._configRepopulateTimer = nil
    end

    self._configRepopulateTimer = self:ScheduleTimer(function()
        local pendingReason = self._configRepopulatePending
        self._configRepopulateTimer = nil
        self._configRepopulatePending = nil
        if pendingReason and self.RepopulateConfigFrame then
            self:RepopulateConfigFrame(pendingReason == true and nil or pendingReason)
        end
    end, delay)
end

function MR:RequestVisualRefresh(opts)
    opts = type(opts) == "table" and opts or {}

    if opts.applySharedMedia and ns.ApplySharedMedia then
        ns.ApplySharedMedia(self.GetActiveMediaSettings and self:GetActiveMediaSettings() or (self.db and self.db.profile))
    end

    if opts.refreshBackgrounds and ns.RefreshAllFrameBackgrounds then
        ns.RefreshAllFrameBackgrounds()
    end

    if opts.main ~= false then
        if self.RequestUIRefresh then
            self:RequestUIRefresh(opts.mainDelay or 0.02)
        elseif self.RefreshUI then
            self:RefreshUI()
        end
    end

    if opts.profession ~= false then
        if self.RequestProfessionKnowledgeSurfaceRefresh then
            self:RequestProfessionKnowledgeSurfaceRefresh(opts.professionDelay or 0.04)
        elseif self.RefreshGatheringLocationsFrame then
            self:RefreshGatheringLocationsFrame()
        end
    end

    if opts.config ~= false then
        if self.RequestConfigRepopulate then
            self:RequestConfigRepopulate(opts.configReason, opts.configDelay or 0.06)
        elseif self.RepopulateConfigFrame then
            self:RepopulateConfigFrame(opts.configReason)
        end
    end
end

function MR:IsModuleHideComplete(modKey)
    local storage = self:GetActiveModuleStorage()
    local s = storage and storage[modKey]
    if s and s.hideComplete ~= nil then return s.hideComplete end
    if MODULES_WITH_OPTIONAL_CURRENCY_COMPLETION[modKey] then
        return false
    end
    return self.db.char.hideComplete
end

function MR:SetModuleHideComplete(modKey, value, skipRefresh)
    local storage = self:GetActiveModuleStorage()
    if not storage[modKey] then storage[modKey] = {} end
    if storage[modKey].hideComplete == value then
        return
    end
    storage[modKey].hideComplete = value
    if not skipRefresh then
        self:RefreshUI()
    end
end

function MR:RefreshProfessionKnowledgeSurfaces()
    if self._suspendProfessionKnowledgeSurfaceRefresh then
        return
    end
    if self.RebuildGatheringLocationsFrame then
        self:RebuildGatheringLocationsFrame()
    end
    if self.RepopulateGatheringConfig then
        self:RepopulateGatheringConfig()
    end
end

function MR:RequestProfessionKnowledgeSurfaceRefresh(delay)
    if not self.ScheduleTimer then
        self:RefreshProfessionKnowledgeSurfaces()
        return
    end

    delay = tonumber(delay) or 0.04
    self._professionKnowledgeSurfaceRefreshPending = true
    if self._professionKnowledgeSurfaceRefreshTimer and self.CancelTimer then
        self:CancelTimer(self._professionKnowledgeSurfaceRefreshTimer)
        self._professionKnowledgeSurfaceRefreshTimer = nil
    end

    self._professionKnowledgeSurfaceRefreshTimer = self:ScheduleTimer(function()
        self._professionKnowledgeSurfaceRefreshTimer = nil
        if self._professionKnowledgeSurfaceRefreshPending then
            self._professionKnowledgeSurfaceRefreshPending = nil
            self:RefreshProfessionKnowledgeSurfaces()
        end
    end, delay)
end

function MR:IsRowEnabled(modKey, rowKey)
    local mod = self.moduleByKey and self.moduleByKey[modKey]
    if mod then
        for _, row in ipairs(mod.rows or {}) do
            if row.key == rowKey and not self:IsPatchEnabled(self:GetRowPatchKey(mod, row)) then
                return false
            end
        end
    end

    local storage = self:GetActiveModuleStorage()
    local s = storage and storage[modKey]
    if not s or not s.hiddenRows then return true end
    return s.hiddenRows[rowKey] ~= false
end

function MR:SetRowEnabled(modKey, rowKey, enabled, skipRefresh)
    local storage = self:GetActiveModuleStorage()
    if not storage[modKey] then storage[modKey] = {} end
    if not storage[modKey].hiddenRows then
        storage[modKey].hiddenRows = {}
    end
    storage[modKey].hiddenRows[rowKey] = enabled and true or false
    if not skipRefresh then
        self:RefreshUI()
    end
    self:RequestProfessionKnowledgeSurfaceRefresh()
end

function MR:IsRowGroupEnabled(modKey, rows)
    if not (modKey and type(rows) == "table") then
        return true
    end
    for _, row in ipairs(rows) do
        if not self:IsRowEnabled(modKey, row.key) then
            return false
        end
    end
    return true
end

function MR:SetRowGroupEnabled(modKey, rows, enabled)
    if not (modKey and type(rows) == "table") then
        return
    end
    self._suspendProfessionKnowledgeSurfaceRefresh = true
    for _, row in ipairs(rows) do
        self:SetRowEnabled(modKey, row.key, enabled, true)
    end
    self._suspendProfessionKnowledgeSurfaceRefresh = nil
    self:RefreshUI()
    self:RequestProfessionKnowledgeSurfaceRefresh()
end

function MR:SetModuleRowOrder(modKey, orderedKeys)
    if not (self and self.db and modKey and type(orderedKeys) == "table") then
        return false
    end

    local mod = self.moduleByKey and self.moduleByKey[modKey]
    if not mod then
        return false
    end

    local storage = self:GetActiveModuleStorage(self:GetModuleExpansionKey(mod))
    if not storage then
        return false
    end
    storage[modKey] = storage[modKey] or {}

    local valid = {}
    for _, row in ipairs(mod.rows or {}) do
        if row and row.key then
            valid[row.key] = true
        end
    end

    local cleaned, seen = {}, {}
    for _, rowKey in ipairs(orderedKeys) do
        if valid[rowKey] and not seen[rowKey] then
            cleaned[#cleaned + 1] = rowKey
            seen[rowKey] = true
        end
    end

    storage[modKey].rowOrder = cleaned
    self._moduleStatsCache = nil
    return true
end

function MR:SetModuleRowPosition(modKey, rowKey, targetRowKey, afterTarget)
    if not (modKey and rowKey and targetRowKey) or rowKey == targetRowKey then
        return false
    end

    local mod = self.moduleByKey and self.moduleByKey[modKey]
    if not mod then
        return false
    end

    local rows = self:GetOrderedRows(mod)
    local order, seen = {}, {}
    for _, row in ipairs(rows or {}) do
        if row and row.key and not row.control and not seen[row.key] then
            order[#order + 1] = row.key
            seen[row.key] = true
        end
    end

    if not seen[rowKey] then
        order[#order + 1] = rowKey
        seen[rowKey] = true
    end
    if not seen[targetRowKey] then
        order[#order + 1] = targetRowKey
        seen[targetRowKey] = true
    end

    local fromIndex, targetIndex
    for index, existingKey in ipairs(order) do
        if existingKey == rowKey then
            fromIndex = index
        elseif existingKey == targetRowKey then
            targetIndex = index
        end
    end
    if not fromIndex or not targetIndex or fromIndex == targetIndex then
        return false
    end

    local insertIndex = targetIndex
    if fromIndex < targetIndex then
        insertIndex = insertIndex - 1
    end
    if afterTarget then
        insertIndex = insertIndex + 1
    end
    insertIndex = math.max(1, math.min(#order, insertIndex))
    if insertIndex == fromIndex then
        return false
    end

    local moved = table.remove(order, fromIndex)
    table.insert(order, insertIndex, moved)
    if not self:SetModuleRowOrder(modKey, order) then
        return false
    end
    if self.RefreshUI then
        self:RefreshUI()
    end
    if self.RequestWarbandBoardRefresh then
        self:RequestWarbandBoardRefresh(false)
    end
    return true
end

function MR:IsCharacterWindowLayoutEnabled()
    return self.db and self.db.profile and self.db.profile.characterWindowLayout == true
end

function MR:GetWindowLayoutValue(key)
    if not (self and self.db and key) then return nil end

    if self:IsCharacterWindowLayoutEnabled() then
        local charLayout = self.db.char and self.db.char.windowLayout
        if charLayout and charLayout[key] ~= nil then
            return charLayout[key]
        end
    end

    return self.db.profile[key]
end

function MR:SetWindowLayoutValue(key, value)
    if not (self and self.db and key) then return end

    if self:IsCharacterWindowLayoutEnabled() then
        if not self.db.char.windowLayout then
            self.db.char.windowLayout = {}
        end
        self.db.char.windowLayout[key] = value
    else
        self.db.profile[key] = value
    end
end

function MR:GetManagedWindowOpen(key)
    if not key then
        return false
    end

    return self:GetWindowLayoutValue(key) == true
end

function MR:SetManagedWindowOpen(key, value)
    if not key then
        return
    end

    local newValue = value and true or false
    local oldValue = self:GetWindowLayoutValue(key) == true
    self:SetWindowLayoutValue(key, newValue)

    if oldValue ~= newValue then
        if self.RequestConfigRepopulate then
            self:RequestConfigRepopulate(nil, 0.01)
        elseif self.RepopulateConfigFrame then
            self:RepopulateConfigFrame()
        end
    end
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
    self:RequestVisualRefresh()
end

function MR:ResetHeaderColor(modKey)
    if self.db.profile.headerColors then
        self.db.profile.headerColors[modKey] = nil
    end
    self:RequestVisualRefresh()
end

function MR:GetHeaderBackgroundColor(modKey)
    if self.db.profile.headerBackgroundColors and self.db.profile.headerBackgroundColors[modKey] then
        return self.db.profile.headerBackgroundColors[modKey]
    end
    return nil
end

function MR:SetHeaderBackgroundColor(modKey, hexColor)
    if not self.db.profile.headerBackgroundColors then
        self.db.profile.headerBackgroundColors = {}
    end
    self.db.profile.headerBackgroundColors[modKey] = hexColor
    self:RequestVisualRefresh()
end

function MR:ResetHeaderBackgroundColor(modKey)
    if self.db.profile.headerBackgroundColors then
        self.db.profile.headerBackgroundColors[modKey] = nil
    end
    self:RequestVisualRefresh()
end

function MR:GetActiveMediaSettings()
    if not (self and self.db) then
        return {}
    end

    if self:IsCharacterWindowLayoutEnabled() then
        self.db.char.mediaSettings = self.db.char.mediaSettings or {}
        return self.db.char.mediaSettings
    end

    return self.db.profile
end

function MR:GetMediaSetting(key)
    if not (self and self.db and key) then
        return nil
    end

    local active = self:GetActiveMediaSettings()
    if active[key] ~= nil then
        return active[key]
    end

    return self.db.profile[key]
end

function MR:SetMediaSetting(key, value, skipRefresh)
    if not (self and self.db and key) then
        return
    end

    local active = self:GetActiveMediaSettings()
    active[key] = value
    if not skipRefresh then
        self:RequestVisualRefresh({
            applySharedMedia = true,
            refreshBackgrounds = true,
        })
    end
end

function MR:IsCursorWithinBounds(target)
    if not target or not target.IsShown or not target:IsShown() then
        return false
    end

    local left = target:GetLeft()
    local right = target:GetRight()
    local top = target:GetTop()
    local bottom = target:GetBottom()
    if not left or not right or not top or not bottom then
        return false
    end

    local cursorX, cursorY = GetCursorPosition()
    local uiScale = UIParent and UIParent:GetEffectiveScale() or 1
    cursorX = cursorX / uiScale
    cursorY = cursorY / uiScale

    return cursorX >= left and cursorX <= right and cursorY >= bottom and cursorY <= top
end

function MR:ApplyPanelHeaderAutoHide(frame, titleBar, shouldHideFunc)
    if not frame or not titleBar then return end

    if not frame._mrPanelHeaderAutoHideHooked then
        frame._mrHeaderHoverElapsed = 0
        frame:EnableMouse(true)
        frame:HookScript("OnEnter", function(self)
            if self.UpdatePanelHeaderVisibility then
                self:UpdatePanelHeaderVisibility(true)
            end
        end)
        frame:HookScript("OnLeave", function(self)
            if self.UpdatePanelHeaderVisibility then
                self:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(self))
            end
        end)
        frame:HookScript("OnShow", function(self)
            if self.UpdatePanelHeaderVisibility then
                self:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(self))
            end
        end)
        frame:HookScript("OnUpdate", function(self, elapsed)
            if not self.UpdatePanelHeaderVisibility then return end
            self._mrHeaderHoverElapsed = (self._mrHeaderHoverElapsed or 0) + (elapsed or 0)
            if self._mrHeaderHoverElapsed < 0.05 then return end
            self._mrHeaderHoverElapsed = 0
            local isHovering = MR:IsCursorWithinBounds(self)
            self:UpdatePanelHeaderVisibility(isHovering)
        end)
        frame._mrPanelHeaderAutoHideHooked = true
    end

    frame.UpdatePanelHeaderVisibility = function(self, isHovering)
        local hideHeaders = MR.db and MR.db.profile and MR.db.profile.autoHidePanelHeaders
        if shouldHideFunc then
            hideHeaders = hideHeaders or shouldHideFunc(self)
        end
        titleBar:SetAlpha((hideHeaders and not isHovering) and 0 or 1)
        self._mrHeaderHovering = isHovering
    end

    frame:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(frame))
end

function MR:RefreshPanelHeaderVisibility(frame)
    if frame and frame.UpdatePanelHeaderVisibility then
        frame:UpdatePanelHeaderVisibility(self:IsCursorWithinBounds(frame))
    end
end

function MR:GetRowColor(modKey, rowKey)
    local p = self.db.profile.rowColors
    if p and p[modKey] and p[modKey][rowKey] then
        return p[modKey][rowKey]
    end
end

function MR:SetRowColor(modKey, rowKey, hexColor)
    if not self.db.profile.rowColors then self.db.profile.rowColors = {} end
    if not self.db.profile.rowColors[modKey] then self.db.profile.rowColors[modKey] = {} end
    self.db.profile.rowColors[modKey][rowKey] = hexColor
    self:RequestVisualRefresh()
end

function MR:ResetRowColor(modKey, rowKey)
    local p = self.db.profile.rowColors
    if p and p[modKey] then
        p[modKey][rowKey] = nil
    end
    self:RequestVisualRefresh()
end

local PARENT_TO_MIDNIGHT = {
    [171]=2906, [164]=2907, [333]=2909, [202]=2910, [182]=2912,
    [773]=2913, [755]=2914, [165]=2915, [186]=2916, [393]=2917, [197]=2918,
}

local PROFESSION_TIER_LEARN_SPELLS = {
    [2906] = 471003, [2871] = 423321, [2823] = 366261, 
    [2907] = 471004, [2872] = 423332, [2822] = 365677, 
    [2909] = 471006, [2874] = 423334, [2825] = 366255, 
    [2910] = 471007, [2875] = 423335, [2827] = 366254, 
    [2912] = 471009, [2877] = 441327, [2832] = 366242, 
    [2913] = 471010, [2878] = 423338, [2828] = 366251, 
    [2914] = 471011, [2879] = 423339, [2829] = 366250, 
    [2915] = 471012, [2880] = 423340, [2830] = 366249,
    [2916] = 471013, [2881] = 423341, [2833] = 366264, 
    [2917] = 471014, [2882] = 423342, [2834] = 366263, 
    [2918] = 471015, [2883] = 423343, [2831] = 366258, 
}

local PROFESSION_CONCENTRATION_CURRENCIES = {
    [2906] = 3161,
    [2907] = 3162,
    [2909] = 3163,
    [2910] = 3164,
    [2913] = 3165,
    [2914] = 3166,
    [2915] = 3167,
    [2918] = 3168,
}

MR.playerProfessions = MR.playerProfessions or {}

local function CopyProfessionMap(source)
    local copy = {}
    if type(source) ~= "table" then
        return copy
    end

    for skillLineID, learned in pairs(source) do
        if learned then
            copy[skillLineID] = true
        end
    end

    return copy
end

local function HasAnyProfessionRecord(source)
    if type(source) ~= "table" then
        return false
    end

    for _, learned in pairs(source) do
        if learned then
            return true
        end
    end

    return false
end

local function ProfessionMapsEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end

    for skillLineID, learned in pairs(a) do
        if learned and not b[skillLineID] then
            return false
        end
    end

    for skillLineID, learned in pairs(b) do
        if learned and not a[skillLineID] then
            return false
        end
    end

    return true
end

local function CharacterDataHasProfession(charData, skillLineID)
    if type(charData) ~= "table" then
        return false
    end

    local professions = charData.professions
    if type(professions) == "table" and professions[skillLineID] then
        return true
    end
    if charData.professionsScanned or HasAnyProfessionRecord(professions) then
        return false
    end

    local concentration = charData.professionConcentration
    return type(concentration) == "table" and concentration[skillLineID] ~= nil
end

function MR:HasProfessionForModule(skillLineID, charData)
    if not skillLineID then
        return true
    end

    if charData ~= nil then
        if self.db and charData == self.db.char and self.playerProfessions and self.playerProfessions[skillLineID] then
            return true
        end
        return CharacterDataHasProfession(charData, skillLineID)
    end

    if self.playerProfessions and self.playerProfessions[skillLineID] then
        return true
    end

    if CharacterDataHasProfession(self.db and self.db.char, skillLineID) then
        return true
    end

    return false
end

local function ConcentrationDataEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end

    for skillLineID, infoA in pairs(a) do
        local infoB = b[skillLineID]
        if type(infoA) ~= "table" or type(infoB) ~= "table" then
            return false
        end
        if (infoA.currencyID or 0) ~= (infoB.currencyID or 0)
            or (infoA.quantity or 0) ~= (infoB.quantity or 0)
            or (infoA.maxQuantity or 0) ~= (infoB.maxQuantity or 0)
            or (infoA.rechargingCycleDurationMS or 0) ~= (infoB.rechargingCycleDurationMS or 0)
            or (infoA.rechargingAmountPerCycle or 0) ~= (infoB.rechargingAmountPerCycle or 0)
            or (infoA.lastUpdated or 0) ~= (infoB.lastUpdated or 0) then
            return false
        end
    end

    for skillLineID in pairs(b) do
        if a[skillLineID] == nil then
            return false
        end
    end

    return true
end

function MR:RefreshPlayerProfessions()
    if self:ShouldDeferForCombat("playerProfessions") then
        return
    end

    local previousProfessions = CopyProfessionMap(self.playerProfessions)
    wipe(self.playerProfessions)
    local found = false
    local scanned = false

    if C_SpellBook and C_SpellBook.IsSpellKnown then
        scanned = true
        for tierSkillLine, learnSpellID in pairs(PROFESSION_TIER_LEARN_SPELLS) do
            if C_SpellBook.IsSpellKnown(learnSpellID) then
                self.playerProfessions[tierSkillLine] = true
                found = true
            end
        end
    end

    if C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines then
        local lines = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
        if lines then
            scanned = true
            for _, skillLineID in ipairs(lines) do
                local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID and
                             C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
                if info and (info.skillLevel or 0) > 0 then
                    self.playerProfessions[skillLineID] = true
                    found = true
                    if info.parentProfessionID then
                        local mid = PARENT_TO_MIDNIGHT[info.parentProfessionID]
                        if mid then
                            self.playerProfessions[mid] = true
                            found = true
                        end
                    end
                end
            end
        end
    end
    if GetProfessions and GetProfessionInfo then
        local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
        scanned = true
        for _, idx in ipairs({ prof1, prof2, archaeology, fishing, cooking }) do
            if idx then
                local _, _, _, _, _, _, parentSkillLine = GetProfessionInfo(idx)
                if parentSkillLine then
                    local mid = PARENT_TO_MIDNIGHT[parentSkillLine]
                    if mid then
                        self.playerProfessions[mid] = true
                        found = true
                    end
                end
            end
        end
    end

    if self.db and self.db.char then
        self.db.char.knownProfessionLines = nil
        if scanned then
            self.db.char.professions = CopyProfessionMap(self.playerProfessions)
            self.db.char.professionsScanned = true
            if not found then
                self.db.char.professionConcentration = {}
            end
        elseif HasAnyProfessionRecord(self.db.char.professions) then
            for skillLineID, learned in pairs(self.db.char.professions) do
                if learned then
                    self.playerProfessions[skillLineID] = true
                end
            end
        end
    end

    local changed = not ProfessionMapsEqual(previousProfessions, self.playerProfessions)

    if changed and self.RefreshProfessionKnowledgeSurfaces then
        self:RequestProfessionKnowledgeSurfaceRefresh()
    end
    if changed and self.RequestConfigRefresh then
        self:RequestConfigRefresh()
    elseif changed and self.RefreshUI then
        self:RefreshUI()
    end

    return changed, found, scanned
end

function MR:RefreshProfessionConcentration()
    if not (self and self.db and self.db.char) then
        return false
    end

    if self:ShouldDeferForCombat("professionConcentration") then
        return false
    end

    local previous = self.db.char.professionConcentration
    local concentration = {}
    for skillLineID, currencyID in pairs(PROFESSION_CONCENTRATION_CURRENCIES) do
        if self.playerProfessions and self.playerProfessions[skillLineID] then
            local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID)
            if info then
                local quantity = info.quantity or 0
                local maxQuantity = info.maxQuantity or 0
                local cycleMS = info.rechargingCycleDurationMS or 0
                local amountPerCycle = info.rechargingAmountPerCycle or 1
                if amountPerCycle <= 0 then
                    amountPerCycle = 1
                end
                local lastUpdated = GetServerTime()
                local previousInfo = type(previous) == "table" and previous[skillLineID] or nil

                if type(previousInfo) == "table" then
                    local previousQuantity = tonumber(previousInfo.quantity) or 0
                    local previousMax = tonumber(previousInfo.maxQuantity) or 0
                    local previousUpdated = tonumber(previousInfo.lastUpdated) or 0
                    local previousCycleMS = tonumber(previousInfo.rechargingCycleDurationMS) or cycleMS
                    local previousAmountPerCycle = tonumber(previousInfo.rechargingAmountPerCycle) or amountPerCycle
                    if previousCycleMS <= 0 then
                        previousCycleMS = cycleMS
                    end
                    if previousAmountPerCycle <= 0 then
                        previousAmountPerCycle = amountPerCycle
                    end

                    if quantity == previousQuantity
                        and previousMax > 0
                        and previousQuantity < previousMax
                        and previousUpdated > 0
                        and previousCycleMS > 0
                        and previousAmountPerCycle > 0 then
                        lastUpdated = previousUpdated
                    end
                end

                concentration[skillLineID] = {
                    currencyID = currencyID,
                    quantity = quantity,
                    maxQuantity = maxQuantity,
                    rechargingCycleDurationMS = cycleMS,
                    rechargingAmountPerCycle = amountPerCycle,
                    name = info.name,
                    iconFileID = info.iconFileID,
                    quality = info.quality or 0,
                    lastUpdated = lastUpdated,
                }
            end
        end
    end

    self.db.char.professionConcentration = concentration
    return not ConcentrationDataEqual(previous, concentration)
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

local function WriteProgress(progress, modKey, rowKey, val, overrides)
    if overrides and overrides[modKey] then
        local mo = overrides[modKey][rowKey]
        if mo and mo > val then val = mo end
    end
    return SetProgressValue(progress, modKey, rowKey, val)
end

local function ValuesEqual(a, b)
    if a == b then
        return true
    end

    if type(a) ~= type(b) then
        return false
    end

    if type(a) ~= "table" then
        return false
    end

    for key, value in pairs(a) do
        if not ValuesEqual(value, b[key]) then
            return false
        end
    end

    for key in pairs(b) do
        if a[key] == nil then
            return false
        end
    end

    return true
end

local function UpdateCurrencyProgressForRow(self, progress, mod, row)
    local info = C_CurrencyInfo.GetCurrencyInfo(row.currencyId)
    if not info then
        return false
    end

    local dirty = false
    local wallet  = info.quantity or 0
    local weekly  = info.quantityEarnedThisWeek or 0
    local weeklyCap = (info.maxWeeklyQuantity and info.maxWeeklyQuantity > 0)
                      and info.maxWeeklyQuantity or nil
    local dynamicCap = nil
    local raw = wallet

    if info.maxQuantity and info.maxQuantity > 0 then
        dynamicCap = info.maxQuantity
        if info.useTotalEarnedForMaxQty and info.totalEarned ~= nil then
            raw = info.totalEarned
        else
            raw = wallet
        end
    elseif weeklyCap and not row.noMax then
        dynamicCap = weeklyCap
        raw = weekly
    end

    if dynamicCap and row.max ~= dynamicCap then
        row.max = dynamicCap
        dirty = true
    end

    local walletKey = row.key .. "_wallet"
    local previousWallet = progress[mod.key] and progress[mod.key][walletKey]

    if SetProgressValue(progress, mod.key, walletKey, wallet) then
        dirty = true
    end

    if row.trackWeeklyEarned then
        local collectedKey = row.key .. "_collected"
        local trackingCap = row.weeklyCap or weeklyCap or row.max
        local collected = progress[mod.key] and tonumber(progress[mod.key][collectedKey]) or 0

        if previousWallet ~= nil and wallet > previousWallet then
            collected = collected + (wallet - previousWallet)
        end

        collected = math.max(collected, weekly, wallet)
        if trackingCap and trackingCap > 0 then
            collected = math.min(collected, trackingCap)
        end

        if SetProgressValue(progress, mod.key, collectedKey, collected) then
            dirty = true
        end
    end

    local val = row.noMax and raw or math.min(raw, row.max or raw)
    if WriteProgress(progress, mod.key, row.key, val, self.db.char.manualOverrides) then
        dirty = true
    end

    return dirty
end

local function UpdateQuestProgressForRow(self, progress, mod, row)
    local done = 0
    if row.questIds then
        for _, qid in ipairs(row.questIds) do
            if C_QuestLog.IsQuestFlaggedCompleted(qid) then
                done = done + 1
            end
        end
    end

    local value = math.min(done, row.max or done)
    local progressBucket = (self.GetProgressBucket and self:GetProgressBucket(mod.key, row.key)) or progress
    local overridesBucket = (self.GetManualOverrideBucket and self:GetManualOverrideBucket(mod.key, row.key)) or self.db.char.manualOverrides

    if row.accountWideComplete and value == 0 then
        local existing = progressBucket[mod.key] and progressBucket[mod.key][row.key] or 0
        if existing > 0 then
            return false
        end
    end

    return WriteProgress(progressBucket, mod.key, row.key, value, overridesBucket)
end

local function UpdateItemProgressForRow(self, progress, mod, row)
    local count = 0
    if C_Item and C_Item.GetItemCount then
        count = C_Item.GetItemCount(row.itemId, false, false, true) or 0
    elseif GetItemCount then
        count = GetItemCount(row.itemId, false, false) or 0
    end

    local value = row.noMax and count or math.min(count, row.max or count)
    return WriteProgress(progress, mod.key, row.key, value, self.db.char.manualOverrides)
end

function MR:RequestScan(delay)
    delay = tonumber(delay) or 0

    if self._scanSuppressedUntil then
        local remaining = self._scanSuppressedUntil - GetTime()
        if remaining > delay then
            delay = remaining + 0.1
        end
    end

    if delay > 0 then
        local targetAt = GetTime() + delay

        if self._requestedScanTimer and self._requestedScanAt and self._requestedScanAt >= targetAt then
            return
        end

        if self._requestedScanTimer then
            self:CancelTimer(self._requestedScanTimer)
        end
        self._requestedScanAt = targetAt
        self._requestedScanTimer = self:ScheduleTimer(function()
            self._requestedScanTimer = nil
            self._requestedScanAt = nil
            self:Scan()
        end, delay)
        return
    end

    self:Scan()
end





function MR:ScanAutoUpdateInstanceRows(changedQuestId, changedEncounterId, difficultyId)
    if not (self and self.db and self.db.char and self.db.char.progress) then
        return
    end

    if difficultyId and MR.CANONICAL_DIFFICULTY then
        difficultyId = MR.CANONICAL_DIFFICULTY[difficultyId] or difficultyId
    end
    local progress = self.db.char.progress
    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do

            if row.autoUpdateInstances and row.questIds and (changedQuestId == nil or (function()
                for _, qid in ipairs(row.questIds) do
                    if qid == changedQuestId then return true end
                end
            end)()) then
                if not row.turnInTracked then
                    UpdateQuestProgressForRow(self, progress, mod, row)
                elseif row.allowQuestFlagBackfill then
                    local progressBucket = (self.GetProgressBucket and self:GetProgressBucket(mod.key, row.key)) or progress
                    local cur = progressBucket[mod.key] and progressBucket[mod.key][row.key] or 0
                    if cur <= 0 then
                        UpdateQuestProgressForRow(self, progress, mod, row)
                    end
                end
            end


            if row.encounterIds and (changedEncounterId == nil or (function()
                for _, eid in ipairs(row.encounterIds) do
                    if eid == changedEncounterId then return true end
                end
            end)()) then

                local diffOk = (not difficultyId) or (not row.encounterDifficulties) or (row.encounterDifficulties[difficultyId] == true)
                if diffOk then
                    local progressBucket = (self.GetProgressBucket and self:GetProgressBucket(mod.key, row.key)) or progress
                    if not progressBucket[mod.key] then progressBucket[mod.key] = {} end
                    local cur = progressBucket[mod.key][row.key] or 0
                    local maxVal = row.max or 1


                    if difficultyId and row.taskId then
                        if self.db then
                            local diffProgress
                            if row.accountWideComplete then
                                self.db.global.customTaskDiffProgress = self.db.global.customTaskDiffProgress or {}
                                diffProgress = self.db.global.customTaskDiffProgress
                            elseif self.db.char then
                                self.db.char.customTaskDiffProgress = self.db.char.customTaskDiffProgress or {}
                                diffProgress = self.db.char.customTaskDiffProgress
                            end
                            local key = row.key or tostring(row.taskId)
                            if diffProgress then
                                diffProgress[key] = diffProgress[key] or {}
                                local diffState = diffProgress[key]
                                if not diffState[difficultyId] then
                                    diffState[difficultyId] = true
                                    if cur < maxVal then
                                        progressBucket[mod.key][row.key] = cur + 1
                                        self._moduleStatsCache = nil
                                    end
                                end
                            end
                        end
                    elseif not row.taskId then

                        if cur < maxVal then
                            progressBucket[mod.key][row.key] = maxVal
                            self._moduleStatsCache = nil
                        end
                    end


                end
            end
        end
    end
end

function MR:RefreshCurrencyProgress(currencyId, refreshUI)
    if not (self and self.db and self.db.char and self.db.char.progress) then
        return false
    end

    local progress = self.db.char.progress
    local dirty = false

    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do
            if row.currencyId and (currencyId == nil or row.currencyId == currencyId) then
                if UpdateCurrencyProgressForRow(self, progress, mod, row) then
                    dirty = true
                end
            end
        end
    end

    if dirty then
        self._moduleStatsCache = nil
        if refreshUI ~= false then
            self:RefreshUI()
        end
    end

    return dirty
end

function MR:RefreshQuestProgress(questId, refreshUI)
    if not (self and self.db and self.db.char and self.db.char.progress) then
        return false
    end

    local progress = self.db.char.progress
    local dirty = false

    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do
            if row.questIds then
                local shouldUpdate = questId == nil
                if not shouldUpdate then
                    for _, qid in ipairs(row.questIds) do
                        if qid == questId then
                            shouldUpdate = true
                            break
                        end
                    end
                end

                if shouldUpdate then
                    if row.turnInTracked and row.allowQuestFlagBackfill then
                        local progressBucket = (self.GetProgressBucket and self:GetProgressBucket(mod.key, row.key)) or progress
                        local currentValue = progressBucket[mod.key] and progressBucket[mod.key][row.key] or 0
                        if currentValue <= 0 and UpdateQuestProgressForRow(self, progress, mod, row) then
                            dirty = true
                        end
                    elseif not row.turnInTracked then
                        if UpdateQuestProgressForRow(self, progress, mod, row) then
                            dirty = true
                        end
                    end
                end
            end
        end
    end

    if dirty then
        self._moduleStatsCache = nil
        if refreshUI ~= false then
            self:RefreshUI()
        end
    end

    return dirty
end

function MR:RefreshItemProgress(itemId, refreshUI)
    if not (self and self.db and self.db.char and self.db.char.progress) then
        return false
    end

    local progress = self.db.char.progress
    local dirty = false

    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do
            if row.itemId and not row.noItemProgress and (itemId == nil or row.itemId == itemId) then
                if UpdateItemProgressForRow(self, progress, mod, row) then
                    dirty = true
                end
            end
        end
    end

    if dirty then
        self._moduleStatsCache = nil
        if refreshUI ~= false then
            self:RefreshUI()
        end
    end

    return dirty
end

function MR:RefreshModuleScans(moduleKeys, refreshUI)
    if not (self and self.db and self.db.char and self.db.char.progress and moduleKeys) then
        return false
    end

    local ran = false
    local dirty = false
    for _, moduleKey in ipairs(moduleKeys) do
        local mod = self.moduleByKey and self.moduleByKey[moduleKey]
        if mod and mod.onScan then
            if not self.db.char.progress[moduleKey] then
                self.db.char.progress[moduleKey] = {}
            end
            local beforeProgress = DeepCopy(self.db.char.progress[moduleKey])
            local beforeRows = {}
            for _, row in ipairs(mod.rows or {}) do
                beforeRows[row.key] = {
                    countColor = DeepCopy(row.countColor),
                    countText = row.countText,
                    isVisible = row.isVisible and row.isVisible() or nil,
                    max = row.max,
                    note = row.note,
                    vaultColor = row.vaultColor,
                    vaultLabel = row.vaultLabel,
                }
            end

            local changed = mod.onScan(mod) == true
            if PruneProgressStore(self.db.char.progress) then
                changed = true
            end
            if self.db.global and PruneProgressStore(self.db.global.customTaskProgress) then
                changed = true
            end
            if not changed and not ValuesEqual(beforeProgress, self.db.char.progress[moduleKey]) then
                changed = true
            end
            if not changed then
                for _, row in ipairs(mod.rows or {}) do
                    local beforeRow = beforeRows[row.key]
                    local afterRow = {
                        countColor = DeepCopy(row.countColor),
                        countText = row.countText,
                        isVisible = row.isVisible and row.isVisible() or nil,
                        max = row.max,
                        note = row.note,
                        vaultColor = row.vaultColor,
                        vaultLabel = row.vaultLabel,
                    }
                    if not ValuesEqual(beforeRow, afterRow) then
                        changed = true
                        break
                    end
                end
            end

            self.db.char.rowVisibility = self.db.char.rowVisibility or {}
            self.db.char.rowVisibility[moduleKey] = self.db.char.rowVisibility[moduleKey] or {}
            local visibilityBucket = self.db.char.rowVisibility[moduleKey]
            for _, row in ipairs(mod.rows or {}) do
                local currentVisible = row.isVisible and row.isVisible() == true or nil
                if visibilityBucket[row.key] ~= currentVisible then
                    changed = true
                end
                visibilityBucket[row.key] = currentVisible
            end

            if changed then
                dirty = true
            end
            ran = true
        end
    end

    if dirty then
        self._moduleStatsCache = nil
        if refreshUI then
            self:RefreshUI()
        end
    end

    return dirty
end

function MR:Scan()
    if self:ShouldDeferForCombat("scan") then
        return
    end

    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self:ScanAutoUpdateInstanceRows(nil, nil)
        return
    end

    local now = GetTime and GetTime() or 0
    local minScanInterval = 0.25

    if self._requestedScanTimer then
        self:CancelTimer(self._requestedScanTimer)
        self._requestedScanTimer = nil
    end

    if self._scanInProgress then
        self._scanPending = true
        return
    end

    if self._lastScanAt and (now - self._lastScanAt) < minScanInterval then
        self._scanPending = true
        if not self._scanThrottleTimer then
            local delay = math.max(minScanInterval - (now - self._lastScanAt), 0.01)
            self._scanThrottleTimer = self:ScheduleTimer(function()
                self._scanThrottleTimer = nil
                if self._scanPending then
                    self._scanPending = nil
                    self:Scan()
                end
            end, delay)
        end
        return
    end

    if self._scanSuppressedUntil and GetTime() < self._scanSuppressedUntil then
        return
    end

    self._scanInProgress = true
    self.db.char.lastSyncAt = GetServerTime()
    local concentrationChanged = self:RefreshProfessionConcentration()

    local progress = self.db.char.progress
    local dirty    = concentrationChanged and true or false

    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do
            if row.questIds and not row.turnInTracked then
                if UpdateQuestProgressForRow(self, progress, mod, row) then
                    dirty = true
                end
            elseif row.questIds and row.turnInTracked and row.allowQuestFlagBackfill then
                local currentValue = progress[mod.key] and progress[mod.key][row.key] or 0
                if currentValue <= 0 and UpdateQuestProgressForRow(self, progress, mod, row) then
                    dirty = true
                end
            end
            if row.currencyId then
                if UpdateCurrencyProgressForRow(self, progress, mod, row) then
                    dirty = true
                end
            end
            if row.itemId and not row.noItemProgress then
                if UpdateItemProgressForRow(self, progress, mod, row) then
                    dirty = true
                end
            end
        end

        if mod.onScan then
            local before = progress[mod.key] and next(progress[mod.key])
            local changed = mod.onScan(mod)
            if changed or (progress[mod.key] and next(progress[mod.key]) ~= before) then dirty = true end
        end

        local mdb = progress[mod.key]
        if mdb then
            for _, row in ipairs(mod.rows) do
                if row.liveKey and row.liveKey ~= row.key and mdb[row.liveKey] ~= nil then
                    local capped = row.noMax and mdb[row.liveKey] or math.min(mdb[row.liveKey], row.max)
                    local _ov = self.db.char.manualOverrides
                    if _ov and _ov[mod.key] then
                        local mo = _ov[mod.key][row.key]
                        if mo and mo > capped then capped = mo end
                    end
                    if SetProgressValue(progress, mod.key, row.key, capped) then dirty = true end
                end
                if row.liveTierLabelKey then
                    row.vaultLabel = mdb[row.liveTierLabelKey]
                end
                if row.liveTierColorKey then
                    row.vaultColor = mdb[row.liveTierColorKey]
                end
            end
        end
    end

    if PruneProgressStore(progress) then dirty = true end
    if self.db.global and PruneProgressStore(self.db.global.customTaskProgress) then dirty = true end

    if dirty then self:RefreshUI() end
    if self.SyncAllRareKills then self:SyncAllRareKills() end
    if self.RefreshRares  then self:RefreshRares()  end
    if self.RefreshRenown then self:RefreshRenown() end

    self._lastScanAt = GetTime and GetTime() or now
    self._scanInProgress = nil

    if self._scanPending and not self._scanThrottleTimer then
        self._scanPending = nil
        self._scanThrottleTimer = self:ScheduleTimer(function()
            self._scanThrottleTimer = nil
            self:Scan()
        end, minScanInterval)
    end
end

local STATIC_TURN_IN_COMPLETIONS = {
    [89268] = { mod = "s1_weekly",           row = "lost_legends"        },
    [89289] = { mod = "s1_weekly",           row = "saltherils_soiree"   },
    [91966] = { mod = "s1_weekly",           row = "saltherils_soiree"   },
    [90573] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [90574] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [90575] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [90576] = { mod = "s1_weekly",           row = "fortify_runestones"  },
    [93744] = { mod = "s1_weekly",           row = "unity_against_void"  },
    [96727] = { mod = "s1_weekly",           row = "unity_against_void"  },
    [90962] = { mod = "midnight_activities", row = "stormarion_assault"  },
    [94835] = { mod = "pvp_weeklies",        row = "early_training"      },
}

local TURN_IN_COMPLETIONS = {}

function MR:RebuildTurnInCompletions()
    wipe(TURN_IN_COMPLETIONS)

    for questID, entry in pairs(STATIC_TURN_IN_COMPLETIONS) do
        TURN_IN_COMPLETIONS[questID] = entry
    end

    for _, mod in ipairs(self.modules) do
        for _, row in ipairs(mod.rows) do
            if row.turnInTracked and row.questIds then
                for _, questID in ipairs(row.questIds) do
                    TURN_IN_COMPLETIONS[questID] = {
                        mod = mod.key,
                        row = row.key,
                    }
                end
            end
        end
    end
end

function MR:OnInitialize()
    self.db = Foundry.DB:New({
        name = addonName,
        sv = "MidnightRoutineDB",
        defaults = DEFAULTS,
        defaultProfile = true,
    })
    self:MigrateLegacySettings()
    if self.RefreshCustomTasksModule then
        self:RefreshCustomTasksModule()
    end
    if self.RefreshCurrenciesModule then
        self:RefreshCurrenciesModule(false)
    end
    if ns.ApplySharedMedia then
        ns.ApplySharedMedia(self.GetActiveMediaSettings and self:GetActiveMediaSettings() or self.db.profile)
    end
end

function MR:ResetAllSettings()
    if not self.db then
        return
    end

    local welcomeSeen = self.db.char and self.db.char.welcomeSeen
    local welcomeSuppressed = self.db.profile and self.db.profile.welcomeSuppressed
    local firstSeen = self.db.profile and self.db.profile.firstSeen

    RestoreDefaults(self.db.profile, DEFAULTS.profile)
    RestoreDefaults(self.db.char, DEFAULTS.char)

    self.db.char.welcomeSeen = welcomeSeen and true or false
    self.db.profile.welcomeSuppressed = welcomeSuppressed and true or false
    self.db.profile.firstSeen = firstSeen and true or false

    self._orderedModulesCache = nil
    self._orderedAllModulesCache = nil
    self._moduleStatsCache = nil
    if self.RefreshCustomTasksModule then
        self:RefreshCustomTasksModule()
    end
    if self.RefreshCurrenciesModule then
        self:RefreshCurrenciesModule(false)
    end

    if ns.ApplySharedMedia then
        ns.ApplySharedMedia(self.GetActiveMediaSettings and self:GetActiveMediaSettings() or self.db.profile)
    end
    if self.ApplySharedMediaSettings then
        self:ApplySharedMediaSettings()
    else
        self:RefreshUI()
    end

    self:RequestScan(0.05)
end

function MR:MigrateLegacySettings()
    local ch = self.db and self.db.char
    local pr = self.db and self.db.profile
    if not ch or not pr or ch.settingsMigrated then
        return
    end

    if IsTableEmpty(ch.modules) and type(pr.modules) == "table" then
        ch.modules = DeepCopy(pr.modules)
    elseif type(pr.modules) == "table" then
        MergeMissing(ch.modules, pr.modules)
    end

    if IsTableEmpty(ch.moduleOrder) and type(pr.moduleOrder) == "table" and #pr.moduleOrder > 0 then
        ch.moduleOrder = DeepCopy(pr.moduleOrder)
    end

    if ch.hideComplete == DEFAULTS.char.hideComplete and pr.hideComplete ~= nil then
        ch.hideComplete = pr.hideComplete
    end

    ch.settingsMigrated = true
end

local INSTANCE_HIDE_TYPES = {
    party = true,
    raid = true,
    arena = true,
    pvp = true,
    scenario = true,
}

function MR:ShouldHideFramesInCurrentInstance()
    if not self.db or not self.db.profile.hideFramesInInstances then return false end
    local inInstance, instanceType = IsInInstance()
    if not inInstance then return false end
    return INSTANCE_HIDE_TYPES[instanceType] == true
end

function MR:ShouldSuspendBackgroundWorkInCurrentInstance()
    return self:ShouldHideFramesInCurrentInstance()
end

function MR:ResumeDeferredInstanceWork()
    if self._deferredInstanceGatheringRefresh then
        self._deferredInstanceGatheringRefresh = nil
        if self.RequestProfessionKnowledgeSurfaceRefresh then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        elseif self.RefreshGatheringLocationsFrame then
            self:RefreshGatheringLocationsFrame()
        end
    end
end

function MR:CaptureManagedWindowState()
    local detached = {}
    if self.detachedFrames then
        for key, frame in pairs(self.detachedFrames) do
            if frame and frame:IsShown() then
                detached[key] = true
            end
        end
    end

    return {
        panel = self.frame and self.frame:IsShown() or false,
        renown = self.renownFrame and self.renownFrame:IsShown() or false,
        rares = self.raresFrame and self.raresFrame:IsShown() or false,
        gathering = self.gatheringLocationsFrame and self.gatheringLocationsFrame:IsShown() or false,
        concentration = self.concentrationTrackerFrame and self.concentrationTrackerFrame:IsShown() or false,
        detached = detached,
    }
end

function MR:ManagedWindowStateHasVisibleFrames(state)
    if not state then return false end
    return state.panel
        or state.renown
        or state.rares
        or state.gathering
        or state.concentration
        or (state.detached and next(state.detached) ~= nil)
end

function MR:SetMainPanelOpen(open, userSet)
    if not (self.db and self.db.char) then return end
    self.db.char.panelOpen = open and true or false
    if userSet then
        self.db.char.panelOpenUserSet = true
    end
end

function MR:PersistManagedWindowState(state)
    if not self.db or not state then return end

    self:SetMainPanelOpen(state.panel, true)
    self:SetManagedWindowOpen("renownOpen", state.renown)
    self:SetManagedWindowOpen("raresOpen", state.rares)
    self:SetManagedWindowOpen("gatheringLocOpen", state.gathering)
    self:SetManagedWindowOpen("concentrationTrackerOpen", state.concentration)
end

function MR:SetManagedWindowRestoreState(state)
    if not self.db then return end

    if state and self:ManagedWindowStateHasVisibleFrames(state) then
        self.db.profile.managedWindowRestoreState = DeepCopy(state)
    else
        self.db.profile.managedWindowRestoreState = nil
    end
end

function MR:IsManagedWindowsBundleHidden()
    local p = self.db and self.db.profile
    return p and p.rememberManagedWindowsVisibility and p.managedWindowsBundleHidden or false
end

function MR:ClearManagedWindowsBundleHidden()
    if self.db and self.db.profile then
        self.db.profile.managedWindowsBundleHidden = false
    end
end

function MR:HideManagedWindows(persistState)
    if persistState then
        self:PersistManagedWindowState({
            panel = false,
            renown = false,
            rares = false,
            gathering = false,
            concentration = false,
        })
        if self.db.profile.rememberManagedWindowsVisibility then
            self.db.profile.managedWindowsBundleHidden = true
        end
    end

    if self.frame then self.frame:Hide() end
    if self.HideCurrencyBrowserFrame then self:HideCurrencyBrowserFrame() end
    if self.HideDetachedModules then self:HideDetachedModules() end
    if self.HideConfig then self:HideConfig() end
    if self.HideRenown then self:HideRenown(false) end
    if self.HideRares then self:HideRares(false) end
    if self.HideGatheringLocations then self:HideGatheringLocations(false) end
    if self.HideConcentrationTracker then self:HideConcentrationTracker(false) end
end

function MR:RestoreManagedWindows(state, persistState)
    state = state or {}
    if persistState then
        self:PersistManagedWindowState(state)
        self:ClearManagedWindowsBundleHidden()
    end

    if state.panel then
        if not self.frame and self.BuildUI then
            self:BuildUI()
        elseif self.frame then
            self.frame:Show()
        end
    end

    if state.renown and self.EnsureRenownShown then
        self:EnsureRenownShown()
    end
    if state.rares and self.EnsureRaresShown then
        self:EnsureRaresShown()
    end
    if state.gathering and self.EnsureGatheringLocationsShown then
        self:EnsureGatheringLocationsShown()
    end
    if state.concentration and self.EnsureConcentrationTrackerShown then
        self:EnsureConcentrationTrackerShown()
    end

    if state.detached and self.detachedFrames then
        for key in pairs(state.detached) do
            local frame = self.detachedFrames[key]
            if frame then
                frame:Show()
            end
        end
    end
end

function MR:ToggleManagedWindows()
    if self._instanceFramesHidden then
        return false
    end

    local restoreState = self._toggleRestoreState
        or (self.db and self.db.profile and self.db.profile.managedWindowRestoreState)

    if restoreState and self:ManagedWindowStateHasVisibleFrames(restoreState) then
        self:RestoreManagedWindows(restoreState, true)
        self._toggleRestoreState = nil
        self:SetManagedWindowRestoreState(nil)
        return true
    end

    local state = self:CaptureManagedWindowState()
    if self:ManagedWindowStateHasVisibleFrames(state) then
        self._toggleRestoreState = state
        self:SetManagedWindowRestoreState(state)
        self:HideManagedWindows(true)
        return false
    end

    if not self.frame and self.BuildUI then
        self:BuildUI()
    end
    if self.frame then
        self.frame:Show()
    end
    self:SetMainPanelOpen(true, true)
    self:ClearManagedWindowsBundleHidden()
    return true
end

function MR:UpdateInstanceFrameVisibility()
    if self:ShouldDeferForCombat("instanceVisibility") then
        return
    end

    if not self.db then return end

    local shouldHide = self:ShouldHideFramesInCurrentInstance()
    if shouldHide then
        if self._instanceFramesHidden then return end

        self._instanceFramesHidden = true
        self._instanceRestoreState = self:CaptureManagedWindowState()
        self:HideManagedWindows()
        return
    end

    if not self._instanceFramesHidden then return end

    local state = self._instanceRestoreState or {}
    self._instanceFramesHidden = false
    self._instanceRestoreState = nil

    self:RestoreManagedWindows(state)
    if self:IsManagedWindowsBundleHidden() then
        self:HideManagedWindows(false)
    end
    self:ResumeDeferredInstanceWork()
end

function MR:OnEnable()
    self:RegisterBucketEvent({
        "AREA_POIS_UPDATED",
    }, 0.75, "OnAreaPoisUpdated")

    self:RegisterBucketEvent({
        "QUEST_LOG_UPDATE",
        "UNIT_QUEST_LOG_CHANGED",
        "GOSSIP_SHOW",
        "GOSSIP_CLOSED",
        "QUEST_DETAIL",
        "QUEST_DATA_LOAD_RESULT",
        "QUEST_PROGRESS",
        "QUEST_COMPLETE",
    }, 0.5, "OnQuestDataChanged")

    self:RegisterBucketEvent({
        "SKILL_LINES_CHANGED",
        "TRADE_SKILL_LIST_UPDATE",
        "SKILL_LINE_SPECS_RANKS_CHANGED",
        "TRADE_SKILL_SHOW",
        "LEARNED_SPELL_IN_SKILL_LINE",
    }, 1, "OnProfessionChange")

    self:RegisterBucketEvent({
        "ZONE_CHANGED_NEW_AREA",
    }, 0.5, "OnZoneChanged")

    self:RegisterBucketEvent({
        "CHALLENGE_MODE_COMPLETED",
        "WEEKLY_REWARDS_UPDATE",
        "LFG_COMPLETION_REWARD",
    }, 1, "OnVaultEvent")

    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "OnSpellCast")
    self:RegisterEvent("ENCOUNTER_END",            "OnEncounterEnd")
    self:RegisterEvent("BOSS_KILL",                "OnBossKill")
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE",  "OnCurrencyDisplayUpdate")
    self:RegisterEvent("QUEST_TURNED_IN",          "OnQuestTurnedIn")
    self:RegisterEvent("QUEST_ACCEPTED",           "OnQuestAccepted")
    self:RegisterEvent("QUEST_REMOVED",            "OnQuestRemoved")
    self:RegisterEvent("BAG_UPDATE_DELAYED",       "OnBagUpdateDelayed")
    self:RegisterEvent("PLAYER_ENTERING_WORLD",    "OnEnteringWorld")

    self:ScheduleRepeatingTimer("CheckWeeklyReset", 60)
    self:ScheduleRepeatingTimer("CheckDailyReset",  60)

    if not self._questTurnInFrame then
        local addon = self
        local f = CreateFrame("Frame")
        f:RegisterEvent("QUEST_TURNED_IN")
        f:SetScript("OnEvent", function(_, _, questID)
            local entry = TURN_IN_COMPLETIONS[questID]
            if not entry or not addon.db then return end
            local ch = addon.db.char
            local modProgress = ch.progress and ch.progress[entry.mod]
            if entry.mod == "s1_weekly" and entry.row == "saltherils_soiree" then
                if not modProgress or modProgress["soiree_active_quest"] ~= questID then
                    return
                end
                modProgress["soiree_completed_name"] = modProgress["soiree_active_name"]
            elseif entry.mod == "s1_weekly" and entry.row == "unity_against_void" then
                if modProgress then
                    modProgress["uatv_completed_branch_name"] = modProgress["uatv_branch_name"]
                end
            elseif entry.mod == "s1_weekly" and entry.row == "ritual_sites" then
                if modProgress then
                    modProgress["ritual_site_completed_name"] = modProgress["ritual_site_active_name"]
                        or modProgress["ritual_site_completed_name"]
                    modProgress["ritual_site_completed_map_id"] = modProgress["ritual_site_active_map_id"]
                        or modProgress["ritual_site_completed_map_id"]
                end
            end
            if not ch.progress[entry.mod] then ch.progress[entry.mod] = {} end
            ch.progress[entry.mod][entry.row] = 1
            addon:RefreshUI()
        end)
        self._questTurnInFrame = f
    end
end

function MR:OnEnteringWorld()
    local _, classFile = UnitClass("player")
    if classFile then
        self.db.char.classFile = classFile
    end
    self.db.char.lastSyncAt = GetServerTime()
    self:RefreshPlayerProfessions()
    self:RefreshProfessionConcentration()
    self:RebuildTurnInCompletions()
    self:BuildSpellIndex()
    local temporarilyHidden = self._toggleRestoreState ~= nil

    if not self.db.profile.firstSeen and not self.db.char.panelOpenUserSet then
        self:SetMainPanelOpen(false, false)
        self:SetManagedWindowOpen("renownOpen", false)
    end

    local shouldHideFrames = self:ShouldHideFramesInCurrentInstance()

    if not shouldHideFrames then
        if not self.frame then
            self:BuildUI()
        end
        if self.frame and self.db.char.panelOpen == false then
            self.frame:Hide()
        end
    end
    if temporarilyHidden then
        self:HideManagedWindows()
    elseif self:IsManagedWindowsBundleHidden() then
        self:HideManagedWindows(false)
    end

    self:UpdateInstanceFrameVisibility()
    shouldHideFrames = self._instanceFramesHidden == true

    if shouldHideFrames then
        self:RequestScan(0.35)
        if self.RefreshGatheringLocationsFrame then
            self._deferredInstanceGatheringRefresh = true
        end
        return
    end

    self:MaybeShowWelcomeScreen()
    if self.OnRenownUpdate and not self._renownUpdateBucketHandle then
        self._renownUpdateBucketHandle = self:RegisterBucketEvent({
            "MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
            "UPDATE_FACTION",
            "COMBAT_TEXT_UPDATE",
        }, 1, "OnRenownUpdate")
    end
    if not shouldHideFrames and not temporarilyHidden and not self:IsManagedWindowsBundleHidden() then
        if self:GetManagedWindowOpen("renownOpen") and self.EnsureRenownShown then
            self:EnsureRenownShown()
        end
        if self:GetManagedWindowOpen("raresOpen") and self.EnsureRaresShown then
            self:EnsureRaresShown()
        end
        if self:GetManagedWindowOpen("gatheringLocOpen") and self.EnsureGatheringLocationsShown then
            self:EnsureGatheringLocationsShown()
        end
        if self:GetManagedWindowOpen("concentrationTrackerOpen") and self.EnsureConcentrationTrackerShown then
            self:EnsureConcentrationTrackerShown()
        end
    end
    if self.db.profile.peekOnHover and self.ApplyPeekOnHover then
        if self._enteringWorldPeekTimer then
            self:CancelTimer(self._enteringWorldPeekTimer)
        end
        self._enteringWorldPeekTimer = self:ScheduleTimer(function()
            self._enteringWorldPeekTimer = nil
            self:ApplyPeekOnHover(true)
        end, 2.5)
    end
    if self._enteringWorldRefreshTimer then
        self:CancelTimer(self._enteringWorldRefreshTimer)
    end
    self._enteringWorldRefreshTimer = self:ScheduleTimer(function()
        self._enteringWorldRefreshTimer = nil
        self:CheckWeeklyReset()
        self:CheckDailyReset()
        self:RefreshPlayerProfessions()
        self:RequestScan(0.35)
        self:UpdateInstanceFrameVisibility()
        if self.RequestProfessionKnowledgeSurfaceRefresh then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        elseif self.RefreshGatheringLocationsFrame then
            self:RefreshGatheringLocationsFrame()
        end
    end, 0.5)
    if self._enteringWorldScanTimer then
        self:CancelTimer(self._enteringWorldScanTimer)
    end
    self._enteringWorldScanTimer = self:ScheduleTimer(function()
        self._enteringWorldScanTimer = nil
        self:RequestScan()
    end, 5)
    self:RequestScan(0.35)
end

function MR:OnCurrencyDisplayUpdate(_, currencyID)
    local dirty = self:RefreshCurrencyProgress(currencyID, false)

    if self:RefreshModuleScans({ "s1_weekly" }, false) then
        dirty = true
    end

    if currencyID == 3290 and self.RefreshDelvesLiveProgress then
        if self._delvesLiveProgressTimer then
            self:CancelTimer(self._delvesLiveProgressTimer)
        end
        self._delvesLiveProgressTimer = self:ScheduleTimer(function()
            self._delvesLiveProgressTimer = nil
            self:RefreshDelvesLiveProgress(true)
        end, 2)
    end

    if dirty then
        self:RefreshUI()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
end

function MR:OnQuestDataChanged()
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self:ScanAutoUpdateInstanceRows(nil, nil)
        return
    end
    local dirty = false
    if self:RefreshQuestProgress(nil, false) then
        dirty = true
    end
    if self:RefreshModuleScans({ "s1_weekly", "pvp_weeklies" }, false) then
        dirty = true
    end
    if dirty then
        self:RefreshUI()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
end

function MR:OnAreaPoisUpdated()
    self:RefreshModuleScans({ "delves", "s1_weekly" }, true)
end

function MR:OnQuestTurnedIn(_, questID)
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self:ScanAutoUpdateInstanceRows(questID, nil)
        return
    end
    local dirty = false
    if self:RefreshQuestProgress(questID, false) then
        dirty = true
    end
    if self:RefreshModuleScans({ "s1_weekly", "pvp_weeklies" }, false) then
        dirty = true
    end
    if dirty then
        self:RefreshUI()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
end

function MR:OnQuestAccepted(_, questID)
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self:ScanAutoUpdateInstanceRows(questID, nil)
        return
    end
    local dirty = false
    if self:RefreshQuestProgress(questID, false) then
        dirty = true
    end
    if self:RefreshModuleScans({ "s1_weekly", "pvp_weeklies" }, false) then
        dirty = true
    end
    if dirty then
        self:RefreshUI()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
end

function MR:OnQuestRemoved(_, questID)
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self:ScanAutoUpdateInstanceRows(questID, nil)
        return
    end
    local dirty = false
    if self:RefreshQuestProgress(questID, false) then
        dirty = true
    end
    if self:RefreshModuleScans({ "s1_weekly", "pvp_weeklies" }, false) then
        dirty = true
    end
    if dirty then
        self:RefreshUI()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
end

function MR:OnBagUpdateDelayed()
    local dirty = self:RefreshItemProgress()

    if self:RefreshModuleScans({ "s1_weekly" }, false) then
        dirty = true
    end

    if dirty then
        self:RefreshUI()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
end

function MR:OnProfessionChange()
    self:RefreshPlayerProfessions()
    self:RefreshProfessionConcentration()
    self:RefreshUI()
    if self.RequestProfessionKnowledgeSurfaceRefresh then
        self:RequestProfessionKnowledgeSurfaceRefresh()
    elseif self.RefreshGatheringLocationsFrame then
        self:RefreshGatheringLocationsFrame()
    end
end

function MR:OnSpellCast(_, unit, _, spellID)
    if unit ~= "player" then return end
    local entry = spellIndex[spellID]
    if not entry then return end
    self:BumpProgress(entry.modKey, entry.rowKey, entry.amount, entry.max)
end

function MR:OnVaultEvent()
    self:RefreshModuleScans({ "great_vault", "delves" }, true)
end

function MR:OnZoneChanged()
    self:UpdateInstanceFrameVisibility()
    self:RefreshModuleScans({ "delves", "s1_weekly" }, true)
    if self.OnRaresZoneChanged then
        self:OnRaresZoneChanged()
    end
end

function MR:OnEncounterEnd(_, encounterId, encounterName, difficultyID, _, success)
    if success == 1 then
        if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
            self:ScanAutoUpdateInstanceRows(nil, tonumber(encounterId), tonumber(difficultyID))
            return
        end
        if encounterName and self.SyncCurrentWorldBossKillByName then
            self:SyncCurrentWorldBossKillByName(encounterName)
        end
        if self.RefreshEncounterProgress then
            self:RefreshEncounterProgress(tonumber(encounterId), true, tonumber(difficultyID))
        end
        self:RefreshModuleScans({ "great_vault", "delves", "world_bosses", "s1_weekly" }, true)
    end
end

function MR:OnBossKill(_, bossId, bossName)
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self:ScanAutoUpdateInstanceRows(nil, tonumber(bossId))
        return
    end
    if self.SyncCurrentWorldBossKillByName then
        local nameForSync = (type(bossName) == "string" and bossName ~= "") and bossName or tostring(bossId or "")
        if nameForSync ~= "" then
            self:SyncCurrentWorldBossKillByName(nameForSync)
        end
    end
    if self.RefreshEncounterProgress then
        self:RefreshEncounterProgress(tonumber(bossId), true)
    end
    self:RefreshModuleScans({ "world_bosses", "great_vault", "s1_weekly" }, true)
end

local function BuildFakeCharacterData(self)
    local progress = {}
    local rowIndex = 0
    for _, mod in ipairs(self.modules) do
        local modProgress = {}
        for _, row in ipairs(mod.rows) do
            if row.key and not row.control then
                rowIndex = rowIndex + 1
                local maxVal = tonumber(row.max) or 1
                if maxVal <= 0 then maxVal = 1 end
                local phase = rowIndex % 3
                local value
                if phase == 0 then
                    value = maxVal
                elseif phase == 1 then
                    value = math.floor(maxVal / 2)
                else
                    value = 0
                end
                modProgress[row.key] = value
                if row.trackWeeklyEarned then
                    modProgress[row.key .. "_collected"] = value
                end
            end
        end
        if next(modProgress) then
            progress[mod.key] = modProgress
        end
    end

    return {
        progress = progress,
        manualOverrides = {},
        professions = {},
        professionConcentration = {},
        professionsScanned = true,
        classFile = "DEATHKNIGHT",
        lastSyncAt = (GetServerTime and GetServerTime()) or time(),
        lastResetAt = 0,
        hideComplete = true,
    }
end

local function SelfTestCheck(fn)
    local ok, statusOrErr, detail = pcall(fn)
    if not ok then
        return "fail", tostring(statusOrErr)
    end
    if statusOrErr == true then
        return "pass", detail
    elseif statusOrErr == false then
        return "fail", detail
    elseif statusOrErr == "warn" then
        return "warn", detail
    end
    return "fail", "test returned an unexpected value"
end

function MR:RunSelfTest()
    local PASS, FAIL, WARN = "|cff00ff96PASS|r", "|cffff5555FAIL|r", "|cffffd27aWARN|r"
    local counts = { pass = 0, fail = 0, warn = 0 }

    local function report(label, status, detail)
        counts[status] = counts[status] + 1
        local tag = status == "pass" and PASS or (status == "fail" and FAIL or WARN)
        print(("  %s %s%s"):format(tag, label, detail and detail ~= "" and (" - " .. detail) or ""))
    end

    local function run(label, fn)
        local status, detail = SelfTestCheck(fn)
        report(label, status, detail)
    end

    print("|cff2ae7c6MidnightRoutine:|r Running self-test...")

    run("Saved variables loaded", function()
        if not self.db then return false, "MR.db is nil" end
        if not self.db.profile then return false, "db.profile missing" end
        if not self.db.char then return false, "db.char missing" end
        if not self.db.global then return false, "db.global missing" end
        return true
    end)

    run("Modules registered", function()
        local count = #self.modules
        if count == 0 then return false, "no modules registered" end
        for _, mod in ipairs(self.modules) do
            if not mod.key or not mod.label or not mod.rows then
                return false, ("module '%s' missing key/label/rows"):format(tostring(mod.key))
            end
        end
        return true, count .. " modules"
    end)

    run("Quest tracking (C_QuestLog)", function()
        if not (C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted) then
            return false, "C_QuestLog.IsQuestFlaggedCompleted unavailable"
        end
        local questRows, questIds = 0, 0
        for _, mod in ipairs(self.modules) do
            for _, row in ipairs(mod.rows) do
                if row.questIds then
                    questRows = questRows + 1
                    for _, qid in ipairs(row.questIds) do
                        questIds = questIds + 1
                        local ok = pcall(C_QuestLog.IsQuestFlaggedCompleted, qid)
                        if not ok then
                            return false, ("quest id %s (module '%s') raised an error"):format(tostring(qid), mod.key)
                        end
                    end
                end
            end
        end
        if questIds == 0 then return "warn", "no quest-tracked rows found" end
        return true, ("%d rows / %d quest IDs checked"):format(questRows, questIds)
    end)

    run("Currency tracking (C_CurrencyInfo)", function()
        if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
            return false, "C_CurrencyInfo.GetCurrencyInfo unavailable"
        end
        local n = 0
        for _, mod in ipairs(self.modules) do
            for _, row in ipairs(mod.rows) do
                if row.currencyId then
                    n = n + 1
                    local ok = pcall(C_CurrencyInfo.GetCurrencyInfo, row.currencyId)
                    if not ok then
                        return false, ("currency id %s (module '%s') raised an error"):format(tostring(row.currencyId), mod.key)
                    end
                end
            end
        end
        if n == 0 then return "warn", "no currency-tracked rows found" end
        return true, n .. " currency rows checked"
    end)

    run("Item tracking (C_Item)", function()
        local n = 0
        for _, mod in ipairs(self.modules) do
            for _, row in ipairs(mod.rows) do
                if row.itemId then
                    n = n + 1
                    if C_Item and C_Item.GetItemCount then
                        local ok = pcall(C_Item.GetItemCount, row.itemId, false, false, true)
                        if not ok then
                            return false, ("item id %s (module '%s') raised an error"):format(tostring(row.itemId), mod.key)
                        end
                    end
                end
            end
        end
        if n == 0 then return "warn", "no item-tracked rows found" end
        return true, n .. " item rows checked"
    end)

    run("Progress read/write", function()
        local mod = self.modules[1]
        local row = mod and mod.rows and mod.rows[1]
        if not row then return "warn", "no rows available to test" end
        local before = self:GetProgress(mod.key, row.key)
        self:SetProgress(mod.key, row.key, before, row.max or before, true)
        return true
    end)

    run("Scan() executes cleanly", function()
        self:Scan()
        return true
    end)

    run("Current character key", function()
        local key = self:GetCurrentCharacterKey()
        if not key or key == "" or key == "Unknown" then
            return false, "could not resolve current character key"
        end
        return true, key
    end)

    run("Warband saved character data", function()
        if not (self.db and self.db.sv and self.db.sv.char) then
            return false, "db.sv.char missing"
        end
        local count = 0
        for _ in pairs(self.db.sv.char) do count = count + 1 end
        if count == 0 then return "warn", "no characters recorded yet" end
        return true, count .. " character(s) recorded"
    end)

    run("Warband weekly data (Alt Board)", function()
        local results = self:GetWarbandWeeklyData(true)
        if type(results) ~= "table" then return false, "did not return a table" end
        return true, #results .. " character snapshot(s)"
    end)

    run("Simulated alt (fake data pipeline)", function()
        if not (self.db and self.db.sv and self.db.sv.char) then
            return false, "db.sv.char missing"
        end

        local fakeKey = "MRTestAlt - MRTestRealm"
        if self.db.sv.char[fakeKey] then
            return "warn", "a leftover test alt was already present; skipped to avoid clobbering it"
        end

        local restoreViewKey = self.mainAltViewCharKey
        local totalRows, doneRows = 0, 0

        local ok, err = pcall(function()
            self.db.sv.char[fakeKey] = BuildFakeCharacterData(self)

            local function findFake(results)
                for _, snap in ipairs(results) do
                    if snap.key == fakeKey then return snap end
                end
                return nil
            end

            local snapshot = findFake(self:GetWarbandWeeklyData(false))
            if not snapshot then
                error("fake alt did not appear in GetWarbandWeeklyData(false)")
            end
            totalRows, doneRows = snapshot.totalRows, snapshot.doneRows
            if totalRows <= 0 then
                error("fake alt reported zero total rows; module/row aggregation is broken")
            end
            if doneRows < 0 or doneRows > totalRows then
                error(("done-row count out of range (%d/%d)"):format(doneRows, totalRows))
            end

            self:SetAltBoardCharacterHidden(fakeKey, true)
            if findFake(self:GetWarbandWeeklyData(false)) then
                error("fake alt still shown after being hidden")
            end
            if not findFake(self:GetWarbandWeeklyData(true)) then
                error("fake alt missing from the hidden-only view")
            end

            self:SetAltBoardCharacterHidden(fakeKey, false)
            if not findFake(self:GetWarbandWeeklyData(false)) then
                error("fake alt did not reappear after being unhidden")
            end

            self:SetMainAltViewCharacter(fakeKey)
            if self:GetMainFrameProgressSource() ~= self.db.sv.char[fakeKey] then
                error("SetMainAltViewCharacter did not switch the progress source to the fake alt")
            end
        end)

        self:SetMainAltViewCharacter(restoreViewKey)
        self.db.sv.char[fakeKey] = nil
        if self.db.profile and self.db.profile.altBoardHiddenCharacters then
            self.db.profile.altBoardHiddenCharacters[fakeKey] = nil
        end
        if self.db.profile and type(self.db.profile.altBoardCharacterOrder) == "table" then
            for i = #self.db.profile.altBoardCharacterOrder, 1, -1 do
                if self.db.profile.altBoardCharacterOrder[i] == fakeKey then
                    table.remove(self.db.profile.altBoardCharacterOrder, i)
                end
            end
        end
        self._moduleStatsCache = nil
        if self.RefreshUI then self:RefreshUI() end
        if self.RefreshWarbandBoard then self:RefreshWarbandBoard() end
        if self.RefreshMainAltPicker then self:RefreshMainAltPicker() end

        if not ok then
            return false, tostring(err)
        end
        return true, ("%d/%d rows complete on simulated alt; hide/show + main-alt view verified"):format(doneRows, totalRows)
    end)

    run("Main/Alt view switching", function()
        if type(self.SetMainAltViewCharacter) ~= "function" or type(self.GetMainFrameProgressSource) ~= "function" then
            return false, "main/alt view API missing"
        end
        local source = self:GetMainFrameProgressSource()
        if type(source) ~= "table" or type(source.progress) ~= "table" then
            return false, "progress source malformed"
        end
        return true
    end)

    run("Main UI frame", function()
        if not self.frame then
            return "warn", "main frame not built yet (open with /mr main)"
        end
        return true
    end)

    local total = counts.pass + counts.fail + counts.warn
    print(("|cff2ae7c6MidnightRoutine:|r Self-test complete: %d/%d passed%s%s"):format(
        counts.pass, total,
        counts.fail > 0 and (", " .. counts.fail .. " failed") or "",
        counts.warn > 0 and (", " .. counts.warn .. " warnings") or ""
    ))
end

SLASH_MIDROUTE1 = "/mr"
SLASH_MIDROUTE2 = "/midroute"
SlashCmdList["MIDROUTE"] = function(msg)
    msg = (msg or ""):lower():trim()
    local function ApplyMainScale(value)
        if MR.db.profile.syncWindowScale and MR.ApplyScaleToAll then
            MR:ApplyScaleToAll(value)
        else
            MR.db.profile.scale = value
            if MR.frame then MR.frame:SetScale(value) end
        end
    end

    if msg == "reset" then
        MR:DoWeeklyReset()
    elseif msg == "lock" then
        MR.db.profile.locked = true
        if MR.frame then MR.frame:SetMovable(false) end
        print(L["Frame_Locked"])
    elseif msg == "unlock" then
        MR.db.profile.locked = false
        if MR.frame then MR.frame:SetMovable(true) end
        print(L["Frame_Unlocked"])
    elseif msg == "hide" then
        if MR.frame then MR.frame:Hide() end
        MR:SetMainPanelOpen(false, true)
    elseif msg == "show" then
        if not MR.frame and MR.BuildUI then
            MR:BuildUI()
        end
        if MR.frame then MR.frame:Show() end
        MR:SetMainPanelOpen(true, true)
        MR:ClearManagedWindowsBundleHidden()
    elseif msg == "toggle" then
        MR:ToggleManagedWindows()
    elseif msg == "main" or msg == "main toggle" then
        if not MR.frame and MR.BuildUI then
            MR:BuildUI()
        end
        if MR.frame then
            if MR.frame:IsShown() then
                MR.frame:Hide()
                MR:SetMainPanelOpen(false, true)
            else
                MR.frame:Show()
                MR:SetMainPanelOpen(true, true)
                MR:ClearManagedWindowsBundleHidden()
            end
        end
    elseif msg == "main show" then
        if not MR.frame and MR.BuildUI then
            MR:BuildUI()
        end
        if MR.frame then MR.frame:Show() end
        MR:SetMainPanelOpen(true, true)
        MR:ClearManagedWindowsBundleHidden()
    elseif msg == "main hide" then
        if MR.frame then MR.frame:Hide() end
        MR:SetMainPanelOpen(false, true)
    elseif msg == "minimap" then
        local newHide = not (MR.db.profile.minimap and MR.db.profile.minimap.hide)
        MR:SetMinimapHidden(newHide)
        if newHide then
            print(L["Minimap_Hidden"])
        else
            print(L["Minimap_Shown"])
        end
    elseif msg == "scale" or msg == "scale toggle" then
        local current = tonumber(MR.db.profile.scale) or 1.0
        local target = math.abs(current - 0.5) < 0.001 and 2.0 or 0.5
        ApplyMainScale(target)
    elseif msg:match("^scale %d") then
        local s = tonumber(msg:match("scale (%S+)"))
        if s and s >= 0.5 and s <= 2 then
            ApplyMainScale(s)
        end
    elseif msg == "big" then if MR.ApplyWidth then MR.ApplyWidth(500) end
    elseif msg == "small" then if MR.ApplyWidth then MR.ApplyWidth(200) end
    elseif msg == "welcome" then MR:ShowWelcomeScreen()
    elseif msg == "renown" then MR:ToggleRenown()
    elseif msg == "renown config" then MR:ToggleRenownConfig()
    elseif msg == "rares" then MR:ToggleRares()
    elseif msg == "rares config" then MR:ToggleRaresConfig()
    elseif msg == "gathering" then MR:ToggleGatheringLocations()
    elseif msg == "test" or msg == "selftest" then MR:RunSelfTest()
    else
        print(L["Chat_Commands"])
    end
end
