local addonName, ns = ...

local LibStub  = LibStub
local L        = LibStub("AceLocale-3.0"):GetLocale(addonName)

local F = _G.Foundry_1_0
if not F then
    error(addonName .. " failed to load Foundry-1.0.", 0)
end

local MR = {}
ns.MR = MR
MR.ns = ns

-- Foundry.Lifecycle replaces AceAddon:NewAddon's lifecycle wiring. There is no
-- combined "DB ready" hook (see Foundry/Modules/Lifecycle.lua header comment) --
-- MR:OnInitialize constructs self.db itself, at the same OnAddonLoaded timing
-- AceAddon's OnInitialize used to fire at.
local Lifecycle = F.Lifecycle:New(MR, addonName)

Lifecycle:OnAddonLoaded(function()
    MR:OnInitialize()
end)

Lifecycle:OnLogin(function()
    MR:OnEnable()
end)

-- Foundry.Events replaces the AceEvent-3.0 mixin: one controller owns this
-- addon's frame-event registrations for the addon's lifetime (there is no
-- runtime enable/disable to tear it down against).
local Events = F.Events:New(addonName)
MR.Events = Events

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
        professionConcentration = {},
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

    if not Events:IsRegistered("PLAYER_REGEN_ENABLED") then
        Events:Register("PLAYER_REGEN_ENABLED", function() MR:OnCombatEnded() end)
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

    if pending and pending.gatheringFrame and self.RefreshGatheringLocationsFrame then
        self:RefreshGatheringLocationsFrame()
    end

    if pending and pending.rares and self.RefreshRares then
        self:RefreshRares()
    end

    if pending and pending.renown and self.RefreshRenown then
        self:RefreshRenown()
    end
end

function MR:OnCombatEnded()
    Events:Unregister("PLAYER_REGEN_ENABLED")

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
        return (legacyKey and m and m[legacyKey]) or 0
    end

    local source = self.GetMainFrameProgressSource and self:GetMainFrameProgressSource() or self.db.char
    local progress = source and source.progress or self.db.char.progress
    local m = progress and progress[moduleKey]
    return m and m[rowKey] or 0
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
        progressBucket[moduleKey][rowKey] = math.max(0, math.min(value, maxVal))
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
    progressBucket[moduleKey][rowKey] = math.max(0, math.min(value, maxVal))
    self:RefreshUI()
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

    local rows = {}
    for _, entry in ipairs(ordered) do
        rows[#rows + 1] = entry.row
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
    if self.RepopulateConfigFrame     then self:RepopulateConfigFrame() end
end

function MR:ApplyFontSizeToAll(v)
    self.db.profile.fontSize          = v
    self.db.profile.raresFontSize     = v
    self.db.profile.gatheringFontSize = v
    self.db.profile.renownFontSize    = v
    if self.ApplyFontSize then self.ApplyFontSize(v) end
    if self.RebuildRaresFrame             then self:RebuildRaresFrame() end
    if self.RebuildGatheringLocationsFrame then self:RebuildGatheringLocationsFrame() end
    if self.RebuildRenownFrame            then self:RebuildRenownFrame() end
    if self.RepopulateRaresConfig     then self:RepopulateRaresConfig() end
    if self.RepopulateGatheringConfig then self:RepopulateGatheringConfig() end
    if self.RepopulateRenownConfig    then self:RepopulateRenownConfig() end
    if self.RepopulateConfigFrame     then self:RepopulateConfigFrame() end
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
        return (legacyKey and modOverrides and modOverrides[legacyKey]) or 0
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

function MR:SetModuleOrder(orderedKeys)
    if self:IsCharacterWindowLayoutEnabled() then
        local expansionKey = self:GetSelectedExpansionKey()
        self.db.char.expansionModuleOrder = self.db.char.expansionModuleOrder or {}
        self.db.char.expansionModuleOrder[expansionKey] = orderedKeys
        if expansionKey == "midnight" then
            self.db.char.moduleOrder = orderedKeys
        end
    else
        local expansionKey = self:GetSelectedExpansionKey()
        self.db.profile.expansionModuleOrder = self.db.profile.expansionModuleOrder or {}
        self.db.profile.expansionModuleOrder[expansionKey] = orderedKeys
        if expansionKey == "midnight" then
            self.db.profile.moduleOrder = orderedKeys
        end
    end
    self._orderedModulesCache = nil
end

function MR:IsModuleEnabled(key)
    local mod = self.moduleByKey[key]
    if mod and mod.profSkillLine and not self.playerProfessions[mod.profSkillLine] then
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
    local storage = self:GetActiveModuleStorage()
    local s = storage and storage[key]
    return not (s and s.enabled == false)
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
    local storage = self:GetActiveModuleStorage()
    local s = storage and storage[key]
    if s == nil then
        local mod = self.moduleByKey[key]
        return not mod or mod.defaultOpen ~= false
    end
    return s.open ~= false
end

function MR:IsModuleDetached(key)
    local storage = self:GetActiveModuleStorage()
    local s = storage and storage[key]
    return s and s.detached == true or false
end

function MR:SetModuleOpen(key, open)
    local storage = self:GetActiveModuleStorage()
    if not storage[key] then storage[key] = {} end
    storage[key].open = open
end

function MR:SetModuleDetached(key, detached)
    local storage = self:GetActiveModuleStorage()
    if not storage[key] then storage[key] = {} end
    storage[key].detached = detached and true or false
end

function MR:GetDetachedModulePosition(key)
    local storage = self:GetActiveModuleStorage()
    local s = storage and storage[key]
    return s and s.detachedPos or nil
end

function MR:SetDetachedModulePosition(key, point, relPoint, x, y)
    local storage = self:GetActiveModuleStorage()
    if not storage[key] then storage[key] = {} end
    storage[key].detachedPos = {
        point = point,
        relPoint = relPoint,
        x = x,
        y = y,
    }
end

function MR:GetDetachedModuleSize(key)
    local storage = self:GetActiveModuleStorage()
    local s = storage and storage[key]
    return s and s.detachedSize or nil
end

function MR:SetDetachedModuleSize(key, width, height)
    local storage = self:GetActiveModuleStorage()
    if not storage[key] then storage[key] = {} end
    storage[key].detachedSize = {
        width = width,
        height = height,
    }
end

function MR:SetModuleEnabled(key, enabled, skipRefresh)
    local storage = self:GetActiveModuleStorage()
    if not storage[key] then storage[key] = {} end
    storage[key].enabled = enabled
    if not skipRefresh then
        self:RefreshUI()
    end
end

function MR:RequestUIRefresh(delay)
    delay = tonumber(delay) or 0.05
    self._refreshRequestPending = true
    if self._refreshRequestTimer then
        self._refreshRequestTimer:Cancel()
        self._refreshRequestTimer = nil
    end

    self._refreshRequestTimer = C_Timer.NewTimer(delay, function()
        self._refreshRequestTimer = nil
        if self._refreshRequestPending then
            self._refreshRequestPending = nil
            self:RefreshUI()
        end
    end)
end

function MR:RequestConfigRefresh()
    self:RequestUIRefresh(0.04)
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

    self:SetWindowLayoutValue(key, value and true or false)
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
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.02)
    else
        self:RefreshUI()
    end
    if self.RequestConfigRepopulate then
        self:RequestConfigRepopulate(nil, 0.06)
    elseif self.RepopulateConfigFrame then
        self:RepopulateConfigFrame()
    end
end

function MR:ResetHeaderColor(modKey)
    if self.db.profile.headerColors then
        self.db.profile.headerColors[modKey] = nil
    end
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.02)
    else
        self:RefreshUI()
    end
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
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.02)
    else
        self:RefreshUI()
    end
    if self.RequestConfigRepopulate then
        self:RequestConfigRepopulate(nil, 0.06)
    elseif self.RepopulateConfigFrame then
        self:RepopulateConfigFrame()
    end
end

function MR:ResetHeaderBackgroundColor(modKey)
    if self.db.profile.headerBackgroundColors then
        self.db.profile.headerBackgroundColors[modKey] = nil
    end
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.02)
    else
        self:RefreshUI()
    end
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

function MR:SetMediaSetting(key, value)
    if not (self and self.db and key) then
        return
    end

    local active = self:GetActiveMediaSettings()
    active[key] = value
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

function MR:ApplyPanelHeaderAutoHide(frame, titleBar)
    if not frame or not titleBar then return end

    if not frame._mrPanelHeaderAutoHideHooked then
        frame._mrHeaderHoverElapsed = 0
        frame:EnableMouse(true)
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
            if isHovering ~= self._mrHeaderHovering then
                self._mrHeaderHovering = isHovering
                self:UpdatePanelHeaderVisibility(isHovering)
            end
        end)
        frame._mrPanelHeaderAutoHideHooked = true
    end

    frame.UpdatePanelHeaderVisibility = function(self, isHovering)
        local hideHeaders = MR.db and MR.db.profile and MR.db.profile.autoHidePanelHeaders
        titleBar:SetAlpha((hideHeaders and not isHovering) and 0 or 1)
        self._mrHeaderHovering = isHovering
    end

    frame:UpdatePanelHeaderVisibility(MR:IsCursorWithinBounds(frame))
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
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.02)
    else
        self:RefreshUI()
    end
    if self.RequestConfigRepopulate then
        self:RequestConfigRepopulate(nil, 0.06)
    elseif self.RepopulateConfigFrame then
        self:RepopulateConfigFrame()
    end
end

function MR:ResetRowColor(modKey, rowKey)
    local p = self.db.profile.rowColors
    if p and p[modKey] then
        p[modKey][rowKey] = nil
    end
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.02)
    else
        self:RefreshUI()
    end
    if self.RequestConfigRepopulate then
        self:RequestConfigRepopulate(nil, 0.06)
    elseif self.RepopulateConfigFrame then
        self:RepopulateConfigFrame()
    end
end

local PARENT_TO_MIDNIGHT = {
    [171]=2906, [164]=2907, [333]=2909, [202]=2910, [182]=2912,
    [773]=2913, [755]=2914, [165]=2915, [186]=2916, [393]=2917, [197]=2918,
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

    if self.db and self.db.char then
        self.db.char.professions = CopyProfessionMap(self.playerProfessions)
    end
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
    if not progress[modKey] then progress[modKey] = {} end
    if overrides and overrides[modKey] then
        local mo = overrides[modKey][rowKey]
        if mo and mo > val then val = mo end
    end
    if progress[modKey][rowKey] == val then return false end
    progress[modKey][rowKey] = val
    return true
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

    if not progress[mod.key] then progress[mod.key] = {} end
    local walletKey = row.key .. "_wallet"
    local previousWallet = progress[mod.key][walletKey]

    if progress[mod.key][walletKey] ~= wallet then
        progress[mod.key][walletKey] = wallet
        dirty = true
    end

    if row.trackWeeklyEarned then
        local collectedKey = row.key .. "_collected"
        local trackingCap = row.weeklyCap or weeklyCap or row.max
        local collected = tonumber(progress[mod.key][collectedKey]) or 0

        if previousWallet ~= nil and wallet > previousWallet then
            collected = collected + (wallet - previousWallet)
        end

        collected = math.max(collected, weekly, wallet)
        if trackingCap and trackingCap > 0 then
            collected = math.min(collected, trackingCap)
        end

        if progress[mod.key][collectedKey] ~= collected then
            progress[mod.key][collectedKey] = collected
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

    if delay > 0 then
        if self._requestedScanTimer then
            self._requestedScanTimer:Cancel()
        end
        self._requestedScanTimer = C_Timer.NewTimer(delay, function()
            self._requestedScanTimer = nil
            self:Scan()
        end)
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
        self._requestedScanTimer:Cancel()
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
            self._scanThrottleTimer = C_Timer.NewTimer(delay, function()
                self._scanThrottleTimer = nil
                if self._scanPending then
                    self._scanPending = nil
                    self:Scan()
                end
            end)
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
                    if mdb[row.key] ~= capped then mdb[row.key] = capped; dirty = true end
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

    if dirty then self:RefreshUI() end
    if self.SyncAllRareKills then self:SyncAllRareKills() end
    if self.RefreshRares  then self:RefreshRares()  end
    if self.RefreshRenown then self:RefreshRenown() end

    self._lastScanAt = GetTime and GetTime() or now
    self._scanInProgress = nil

    if self._scanPending and not self._scanThrottleTimer then
        self._scanPending = nil
        self._scanThrottleTimer = C_Timer.NewTimer(minScanInterval, function()
            self._scanThrottleTimer = nil
            self:Scan()
        end)
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
    self.db = F.DB:New({
        name = addonName,
        sv = "MidnightRoutineDB",
        defaultProfile = true,
        defaults = DEFAULTS,
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
        if self.RefreshGatheringLocationsFrame then
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

function MR:PersistManagedWindowState(state)
    if not self.db or not state then return end

    self.db.char.panelOpen = state.panel and true or false
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
    self.db.char.panelOpen = true
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
    Events:RegisterBucket({
        events = "AREA_POIS_UPDATED",
        interval = 0.75,
        handler = function() MR:OnAreaPoisUpdated() end,
    })

    Events:RegisterBucket({
        events = {
            "QUEST_LOG_UPDATE",
            "UNIT_QUEST_LOG_CHANGED",
            "GOSSIP_SHOW",
            "GOSSIP_CLOSED",
            "QUEST_DETAIL",
            "QUEST_DATA_LOAD_RESULT",
            "QUEST_PROGRESS",
            "QUEST_COMPLETE",
        },
        interval = 0.5,
        handler = function() MR:OnQuestDataChanged() end,
    })

    Events:RegisterBucket({
        events = {
            "SKILL_LINES_CHANGED",
            "TRADE_SKILL_LIST_UPDATE",
            "SKILL_LINE_SPECS_RANKS_CHANGED",
            "TRADE_SKILL_SHOW",
        },
        interval = 1,
        handler = function() MR:OnProfessionChange() end,
    })

    Events:RegisterBucket({
        events = "ZONE_CHANGED_NEW_AREA",
        interval = 0.5,
        handler = function() MR:OnZoneChanged() end,
    })

    Events:RegisterBucket({
        events = {
            "CHALLENGE_MODE_COMPLETED",
            "WEEKLY_REWARDS_UPDATE",
            "LFG_COMPLETION_REWARD",
        },
        interval = 1,
        handler = function() MR:OnVaultEvent() end,
    })

    Events:Register("UNIT_SPELLCAST_SUCCEEDED", function(...) MR:OnSpellCast(...) end)
    Events:Register("ENCOUNTER_END",            function(...) MR:OnEncounterEnd(...) end)
    Events:Register("BOSS_KILL",                function(...) MR:OnBossKill(...) end)
    Events:Register("CURRENCY_DISPLAY_UPDATE",  function(...) MR:OnCurrencyDisplayUpdate(...) end)
    Events:Register("QUEST_TURNED_IN",          function(...) MR:OnQuestTurnedIn(...) end)
    Events:Register("QUEST_ACCEPTED",           function(...) MR:OnQuestAccepted(...) end)
    Events:Register("QUEST_REMOVED",            function(...) MR:OnQuestRemoved(...) end)
    Events:Register("BAG_UPDATE_DELAYED",       function(...) MR:OnBagUpdateDelayed(...) end)
    Events:Register("PLAYER_ENTERING_WORLD",    function(...) MR:OnEnteringWorld(...) end)

    C_Timer.NewTicker(60, function() MR:CheckWeeklyReset() end)
    C_Timer.NewTicker(60, function() MR:CheckDailyReset() end)

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

    -- MinimapButton.lua's login-gated setup can't register its own
    -- Foundry.Lifecycle OnLogin hook (one hook per phase per controller,
    -- and this controller's login phase already runs MR:OnEnable) -- so it
    -- is chained here instead.
    if self.InitMinimapButton then
        self:InitMinimapButton()
    end

    -- ProfessionKnowledge.lua's login-gated setup can't register its own
    -- Foundry.Lifecycle OnLogin hook either (same one-hook-per-phase
    -- limitation) -- chained here for the same reason as InitMinimapButton
    -- above.
    if self.InitProfessionKnowledge then
        self:InitProfessionKnowledge()
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

    if not self.db.profile.firstSeen then
        self.db.char.panelOpen     = false
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
        self._renownUpdateBucketHandle = Events:RegisterBucket({
            events = {
                "MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
                "UPDATE_FACTION",
                "COMBAT_TEXT_UPDATE",
            },
            interval = 1,
            handler = function() MR:OnRenownUpdate() end,
        })
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
            self._enteringWorldPeekTimer:Cancel()
        end
        self._enteringWorldPeekTimer = C_Timer.NewTimer(2.5, function()
            self._enteringWorldPeekTimer = nil
            self:ApplyPeekOnHover(true)
        end)
    end
    if self._enteringWorldRefreshTimer then
        self._enteringWorldRefreshTimer:Cancel()
    end
    self._enteringWorldRefreshTimer = C_Timer.NewTimer(0.5, function()
        self._enteringWorldRefreshTimer = nil
        self:CheckWeeklyReset()
        self:CheckDailyReset()
        self:RefreshPlayerProfessions()
        self:RequestScan(0.35)
        self:UpdateInstanceFrameVisibility()
        if self.RefreshGatheringLocationsFrame then
            self:RefreshGatheringLocationsFrame()
        end
    end)
    if self._enteringWorldScanTimer then
        self._enteringWorldScanTimer:Cancel()
    end
    self._enteringWorldScanTimer = C_Timer.NewTimer(5, function()
        self._enteringWorldScanTimer = nil
        self:RequestScan()
    end)
    self:RequestScan(0.35)
end

function MR:OnCurrencyDisplayUpdate(_, currencyID)
    local dirty = self:RefreshCurrencyProgress(currencyID, false)

    if self:RefreshModuleScans({ "s1_weekly" }, false) then
        dirty = true
    end

    if currencyID == 3290 and self.RefreshDelvesLiveProgress then
        if self._delvesLiveProgressTimer then
            self._delvesLiveProgressTimer:Cancel()
        end
        self._delvesLiveProgressTimer = C_Timer.NewTimer(2, function()
            self._delvesLiveProgressTimer = nil
            self:RefreshDelvesLiveProgress(true)
        end)
    end

    if dirty then
        self:RefreshUI()
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
    end
end

function MR:OnBagUpdateDelayed()
    local dirty = self:RefreshItemProgress()

    if self:RefreshModuleScans({ "s1_weekly" }, false) then
        dirty = true
    end

    if dirty then
        self:RefreshUI()
    end
end

function MR:OnProfessionChange()
    self:RefreshPlayerProfessions()
    self:RefreshProfessionConcentration()
    self:RefreshUI()
    if self.RefreshGatheringLocationsFrame then
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

-- Foundry.Commands replaces the manual SlashCmdList/SLASH_MIDROUTEn dispatch
-- table. Longest-prefix, word-boundary matching means a two-word alias like
-- "main toggle" is not registered as its own subcommand name -- it is the
-- base word ("main") registered once, with the handler switching on the
-- trimmed remainder. This preserves the original if/elseif chain's behavior,
-- including its exact-match semantics: an unrecognized remainder (e.g.
-- "main foobar") falls through to the same Chat_Commands message the
-- original's final `else` printed for any unmatched full command.
local function ApplyMainScale(value)
    if MR.db.profile.syncWindowScale and MR.ApplyScaleToAll then
        MR:ApplyScaleToAll(value)
    else
        MR.db.profile.scale = value
        if MR.frame then MR.frame:SetScale(value) end
    end
end

-- Wraps a no-argument leaf command so it only fires on an exact match (no
-- trailing remainder), matching the original chain's exact-string elseif
-- checks (e.g. "/mr lock foo" fell through to the unknown-command message,
-- not into "lock").
local function ExactOnly(fn)
    return function(rest)
        if rest ~= "" then
            print(L["Chat_Commands"])
            return
        end
        fn()
    end
end

local Commands = F.Commands:New({
    name = "MidRoute",
    slashes = { "/mr", "/midroute" },
    defaultHandler = function() print(L["Chat_Commands"]) end,
    unknownMessage = function() return L["Chat_Commands"] end,
})
MR.Commands = Commands

Commands:Register({
    name = "reset",
    handler = ExactOnly(function() MR:DoWeeklyReset() end),
})

Commands:Register({
    name = "lock",
    handler = ExactOnly(function()
        MR.db.profile.locked = true
        if MR.frame then MR.frame:SetMovable(false) end
        print(L["Frame_Locked"])
    end),
})

Commands:Register({
    name = "unlock",
    handler = ExactOnly(function()
        MR.db.profile.locked = false
        if MR.frame then MR.frame:SetMovable(true) end
        print(L["Frame_Unlocked"])
    end),
})

Commands:Register({
    name = "hide",
    handler = ExactOnly(function()
        if MR.frame then MR.frame:Hide() end
        MR.db.char.panelOpen = false
    end),
})

Commands:Register({
    name = "show",
    handler = ExactOnly(function()
        if MR.frame then MR.frame:Show() end
        MR.db.char.panelOpen = true
        MR:ClearManagedWindowsBundleHidden()
    end),
})

Commands:Register({
    name = "toggle",
    handler = ExactOnly(function() MR:ToggleManagedWindows() end),
})

Commands:Register({
    name = "main",
    args = "[show|hide]",
    handler = function(rest)
        rest = (rest or ""):lower()
        if rest == "" or rest == "toggle" then
            if not MR.frame and MR.BuildUI then
                MR:BuildUI()
            end
            if MR.frame then
                if MR.frame:IsShown() then
                    MR.frame:Hide()
                    MR.db.char.panelOpen = false
                else
                    MR.frame:Show()
                    MR.db.char.panelOpen = true
                    MR:ClearManagedWindowsBundleHidden()
                end
            end
        elseif rest == "show" then
            if not MR.frame and MR.BuildUI then
                MR:BuildUI()
            end
            if MR.frame then MR.frame:Show() end
            MR.db.char.panelOpen = true
            MR:ClearManagedWindowsBundleHidden()
        elseif rest == "hide" then
            if MR.frame then MR.frame:Hide() end
            MR.db.char.panelOpen = false
        else
            print(L["Chat_Commands"])
        end
    end,
})

Commands:Register({
    name = "minimap",
    handler = ExactOnly(function()
        local newHide = not (MR.db.profile.minimap and MR.db.profile.minimap.hide)
        MR:SetMinimapHidden(newHide)
        if newHide then
            print(L["Minimap_Hidden"])
        else
            print(L["Minimap_Shown"])
        end
    end),
})

Commands:Register({
    name = "scale",
    args = "[value]",
    handler = function(rest)
        rest = (rest or ""):lower()
        if rest == "" or rest == "toggle" then
            local current = tonumber(MR.db.profile.scale) or 1.0
            local target = math.abs(current - 0.5) < 0.001 and 2.0 or 0.5
            ApplyMainScale(target)
        elseif rest:match("^%d") then
            local s = tonumber(rest:match("^(%d+%.?%d*)"))
            if s and s >= 0.5 and s <= 2 then
                ApplyMainScale(s)
            end
        else
            print(L["Chat_Commands"])
        end
    end,
})

Commands:Register({
    name = "big",
    handler = ExactOnly(function() if MR.ApplyWidth then MR.ApplyWidth(500) end end),
})

Commands:Register({
    name = "small",
    handler = ExactOnly(function() if MR.ApplyWidth then MR.ApplyWidth(200) end end),
})

Commands:Register({
    name = "welcome",
    handler = ExactOnly(function() MR:ShowWelcomeScreen() end),
})

Commands:Register({
    name = "renown",
    args = "[config]",
    handler = function(rest)
        rest = (rest or ""):lower()
        if rest == "" then
            MR:ToggleRenown()
        elseif rest == "config" then
            MR:ToggleRenownConfig()
        else
            print(L["Chat_Commands"])
        end
    end,
})

Commands:Register({
    name = "rares",
    args = "[config]",
    handler = function(rest)
        rest = (rest or ""):lower()
        if rest == "" then
            MR:ToggleRares()
        elseif rest == "config" then
            MR:ToggleRaresConfig()
        else
            print(L["Chat_Commands"])
        end
    end,
})

Commands:Register({
    name = "gathering",
    handler = ExactOnly(function() MR:ToggleGatheringLocations() end),
})
