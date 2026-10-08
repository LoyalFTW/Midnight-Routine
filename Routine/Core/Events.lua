local _, ns = ...
local MR = ns.MR

function MR:RestoreSavedManagedWindows()
    if not self.db or self:IsManagedWindowsBundleHidden() or self._instanceFramesHidden then
        return
    end
    local windows = {
        { "renownOpen", "renownFrame", "EnsureRenownShown" },
        { "raresOpen", "raresFrame", "EnsureRaresShown" },
        { "gatheringLocOpen", "gatheringLocationsFrame", "EnsureGatheringLocationsShown" },
        { "concentrationTrackerOpen", "concentrationTrackerFrame", "EnsureConcentrationTrackerShown" },
    }
    for _, window in ipairs(windows) do
        local frame = self[window[2]]
        local ensure = self[window[3]]
        if self:GetManagedWindowOpen(window[1])
            and type(ensure) == "function"
            and not (frame and frame.IsShown and frame:IsShown()) then
            ensure(self)
        end
    end
end

function MR:OnEnteringWorld()
    self:RefreshEnteringWorldTracking()
    local temporarilyHidden = self._toggleRestoreState ~= nil
    local mainPanelOpen = self:GetMainPanelOpen()

    local managedBundleVisible = not self:IsManagedWindowsBundleHidden()
    local trackingSurfaceRequested = managedBundleVisible and (
        mainPanelOpen
        or self:GetManagedWindowOpen("renownOpen")
        or self:GetManagedWindowOpen("raresOpen")
        or self:GetManagedWindowOpen("gatheringLocOpen")
        or self:GetManagedWindowOpen("concentrationTrackerOpen")
    )
    if not trackingSurfaceRequested then
        self:MarkBackgroundDataDirty()
    end

    local shouldHideFrames = self:ShouldHideFramesInCurrentInstance()

    if not shouldHideFrames then
        local shouldBuildMainFrame = mainPanelOpen
        if shouldBuildMainFrame and not self.frame then
            self:BuildUI()
        end
        if self:IsThemeColorClassColor() and self._appliedThemeColor ~= self:GetThemeColor() then
            self:ApplyThemeColorSelection()
        end
        if self.frame and not mainPanelOpen then
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
        self:RequestScan(1.0)
        if self.RefreshGatheringLocationsFrame then
            self._deferredInstanceGatheringRefresh = true
        end
        return
    end

    if not self._autoHideOnLoginPending then
        self:MaybeShowWelcomeScreen()
    end
    if not self.isForever and self.OnRenownUpdate and not self._renownUpdateBucketHandle then
        self._renownUpdateBucketHandle = self:RegisterBucketEvent({
            "MAJOR_FACTION_RENOWN_LEVEL_CHANGED",
            "UPDATE_FACTION",
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
    if trackingSurfaceRequested and self.db.profile.peekOnHover and self.ApplyPeekOnHover then
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
        self:ScheduleNextResetCheck()
        if not self._raresInitialSyncComplete and self.SyncAllRareKills then
            self._raresInitialSyncComplete = true
            self:SyncAllRareKills(true)
        end
        if self:HasVisibleMainTrackingSurface()
            or (self.gatheringLocationsFrame and self.gatheringLocationsFrame:IsShown()) then
            self:RefreshPlayerProfessions()
        else
            self:MarkBackgroundDataDirty()
        end
        self:UpdateInstanceFrameVisibility()
        if self.RequestProfessionKnowledgeSurfaceRefresh then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        elseif self.RefreshGatheringLocationsFrame then
            self:RefreshGatheringLocationsFrame()
        end
        if self._autoHideOnLoginPending then
            self._autoHideOnLoginPending = nil
        else
            self:RestoreSavedManagedWindows()
        end
    end, 0.5)
    self:RequestScan(1.0)
end

local managedWindowRestoreFrame = CreateFrame("Frame")
managedWindowRestoreFrame:RegisterEvent("PLAYER_LOGIN")
managedWindowRestoreFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    MR._autoHideOnLoginPending = MR.db and MR.db.profile.autoHideOnLogin == true
    C_Timer.After(0, function()
        if MR._autoHideOnLoginPending then
            MR:AutoHideManagedWindowsOnLogin()
        else
            MR:RestoreSavedManagedWindows()
        end
    end)
end)
