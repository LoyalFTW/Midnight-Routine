local addonName, ns = ...
if ns.Inactive then return end
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Tracker = ns.Tracking.API

MR.tracker = Tracker

function MR:ReportTrackingFailure(source, err)
    print(string.format(
        L["Scan_Failed"] or "|cff2ae7c6MidnightRoutine:|r Scan step '%s' failed and was skipped: %s",
        tostring(source), tostring(err)))
end

function MR:OnTrackingWeeklyReset()
    print(L["Weekly_Reset"] or "|cff2ae7c6MidnightRoutine:|r Weekly reset applied.")
end

function MR:OnTrackerLabelsChanged()
    local hasVisibleMain = MR.frame and MR.frame.IsShown and MR.frame:IsShown()
    local hasVisibleDetached = false
    if MR.detachedFrames then
        for _, frame in pairs(MR.detachedFrames) do
            if frame and frame.IsShown and frame:IsShown() then
                hasVisibleDetached = true
                break
            end
        end
    end

    if hasVisibleMain or hasVisibleDetached then
        if MR.RequestUIRefresh then
            MR:RequestUIRefresh(0.02)
        elseif MR.RefreshUI then
            MR:RefreshUI()
        end
    else
        MR._refreshUIDirty = true
        MR._mainPanelNeedsRefresh = true
    end

    if MR.RequestProfessionKnowledgeSurfaceRefresh then
        MR:RequestProfessionKnowledgeSurfaceRefresh(0.02)
    elseif MR.RequestGatheringLocationsRefresh then
        MR.RequestGatheringLocationsRefresh()
    elseif MR.RefreshProfessionKnowledgeSurfaces then
        MR:RefreshProfessionKnowledgeSurfaces()
    end
end

function MR:OnTrackingDataChanged()
    if self:HasVisibleMainTrackingSurface() then
        self:RequestDataRefresh()
    else
        self:MarkBackgroundDataDirty()
    end
end

function MR:OnTrackingKnowledgeSurfacesChanged()
    if self.RequestProfessionKnowledgeSurfaceRefresh then
        self:RequestProfessionKnowledgeSurfaceRefresh()
    elseif self.RefreshGatheringLocationsFrame then
        self:RefreshGatheringLocationsFrame()
    end
end

function MR:OnTrackingStatsInvalidated()
    self._moduleStatsCache = nil
end

function MR:OnTrackingRaresChanged()
    if self.RefreshRares then
        self:RefreshRares()
    end
end

function MR:OnTrackingRenownChanged()
    if self.RefreshRenown then
        self:RefreshRenown()
    end
end

function MR:OnTrackingWarbandCharacterSurfacesChanged()
    if self.RefreshWarbandCharacterSurfaces then
        self:RefreshWarbandCharacterSurfaces()
    end
end

function MR:OnTrackingWarbandDataSurfacesChanged()
    if self.RefreshWarbandDataSurfaces then
        self:RefreshWarbandDataSurfaces()
    end
end

function MR:OnTrackingConfigRepopulateRequested()
    if self.RequestConfigRepopulate then
        self:RequestConfigRepopulate(nil, 0.04)
    end
end

function MR:OnTrackingWarbandBoardRefreshRequested()
    if self.RequestWarbandBoardRefresh then
        self:RequestWarbandBoardRefresh(true)
    end
end

function MR:OnTrackingUIRefreshRequested()
    if self.RequestUIRefresh then
        self:RequestUIRefresh(0.01)
    else
        self:RefreshUI()
    end
end

function MR:OnTrackingDataRefreshRequested()
    if self.RequestDataRefresh then
        self:RequestDataRefresh()
    else
        self:RefreshUI()
    end
end

function MR:OnTrackingConfigRefreshRequested()
    if self.RequestConfigRefresh then
        self:RequestConfigRefresh()
    elseif self.RefreshUI then
        self:RefreshUI()
    end
end

local tracking = ns.Tracking

local function Forward(methodName, default)
    return function(...)
        local method = MR[methodName]
        if method then
            return method(MR, ...)
        end
        return default
    end
end

Tracker:SetEngine(MR)
Tracker:SetEnvironment({
    isRowEnabled = Forward("IsRowEnabled", true),
    isCurrencyInCurrenciesModule = Forward("IsCurrencyInCurrenciesModule", false),
    isDarkmoonVisible = function()
        return MR.IsDarkmoonVisible ~= nil and MR.IsDarkmoonVisible() or false
    end,
    refreshDarkmoonVisibility = Forward("RefreshDarkmoonVisibility"),
    refreshBrewfestVisibility = Forward("RefreshBrewfestVisibility"),
    refreshEncounterProgress = Forward("RefreshEncounterProgress"),
    syncWorldBossKillByName = Forward("SyncCurrentWorldBossKillByName"),
    refreshDelvesLiveProgress = Forward("RefreshDelvesLiveProgress"),
    recordGildedStashLoot = Forward("RecordGildedStashLoot"),
    primeProfessionKnowledgeLabels = Forward("PrimeProfessionKnowledgeModuleLabels"),
    noteRefreshSource = Forward("NoteRefreshSource"),
    queueDeferredProgressUpdate = Forward("QueueDeferredProgressUpdate"),
    isModuleEnabled = function(moduleKey) return MR:IsModuleEnabled(moduleKey) end,
    shouldDefer = function(flag) return MR:ShouldDeferForCombat(flag) end,
    shouldSuspend = function()
        return MR.ShouldSuspendBackgroundWorkInCurrentInstance ~= nil and MR:ShouldSuspendBackgroundWorkInCurrentInstance()
    end,
    isSurfaceVisible = function() return MR:HasVisibleMainTrackingSurface() end,
    markDataDirty = function() MR:MarkBackgroundDataDirty() end,
    isAccountWideCustomTask = function(rowKey)
        return MR.IsCustomTaskAccountWideCompletion ~= nil and MR:IsCustomTaskAccountWideCompletion(rowKey)
    end,
    getSharedCustomTask = function(taskId)
        return MR.GetCustomTaskById ~= nil and MR:GetCustomTaskById(taskId, "shared") or nil
    end,
    getViewSource = function()
        return MR.GetMainFrameProgressSource ~= nil and MR:GetMainFrameProgressSource() or nil
    end,
    shouldHideRelatedWhenComplete = function(moduleKey)
        return MR.db.profile.hideActivitiesWhenWeeklyCompleted
            or (moduleKey ~= nil and MR.IsModuleHideComplete ~= nil and MR:IsModuleHideComplete(moduleKey))
    end,
})
local function RegisterTrackingHandler(event, methodName)
    tracking.RegisterCallback(MR, event, function()
        MR[methodName](MR)
    end)
end

tracking.RegisterCallback(MR, "CustomTasksResetDue", function(_, resetType, forceSharedReset, resetCharacters)
    if MR.ResetCustomTasksByType then
        MR:ResetCustomTasksByType(resetType, forceSharedReset, resetCharacters)
    end
end)
tracking.RegisterCallback(MR, "TrackingFailure", function(_, source, err)
    MR:ReportTrackingFailure(source, err)
end)
RegisterTrackingHandler("InstanceVisibilityRefreshNeeded", "UpdateInstanceFrameVisibility")
tracking.RegisterCallback(MR, "RaresZoneChanged", function()
    if MR.OnRaresZoneChanged then
        MR:OnRaresZoneChanged()
    end
end)
RegisterTrackingHandler("StatsInvalidated", "OnTrackingStatsInvalidated")
RegisterTrackingHandler("RaresChanged", "OnTrackingRaresChanged")
RegisterTrackingHandler("RenownChanged", "OnTrackingRenownChanged")
RegisterTrackingHandler("WarbandCharacterSurfacesChanged", "OnTrackingWarbandCharacterSurfacesChanged")
RegisterTrackingHandler("WarbandDataSurfacesChanged", "OnTrackingWarbandDataSurfacesChanged")
RegisterTrackingHandler("ConfigRepopulateRequested", "OnTrackingConfigRepopulateRequested")
RegisterTrackingHandler("WarbandBoardRefreshRequested", "OnTrackingWarbandBoardRefreshRequested")
RegisterTrackingHandler("ResetApplied", "RefreshUI")
RegisterTrackingHandler("UIRefreshNeeded", "RefreshUI")
RegisterTrackingHandler("UIRefreshRequested", "OnTrackingUIRefreshRequested")
RegisterTrackingHandler("DataRefreshRequested", "OnTrackingDataRefreshRequested")
RegisterTrackingHandler("ConfigRefreshRequested", "OnTrackingConfigRefreshRequested")
RegisterTrackingHandler("WeeklyResetAnnounced", "OnTrackingWeeklyReset")
RegisterTrackingHandler("DataChanged", "OnTrackingDataChanged")
RegisterTrackingHandler("KnowledgeSurfacesChanged", "OnTrackingKnowledgeSurfacesChanged")

Tracker:InstallComponent("Progress", MR, { namespace = ns })
