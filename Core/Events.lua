local _, ns = ...
local MR = ns.MR
local Core = assert(ns.CoreInternals, "Core/Foundation.lua must load first")
local DeepCopy = Core.DeepCopy
local MergeMissing = Core.MergeMissing
local RestoreDefaults = Core.RestoreDefaults
local IsTableEmpty = Core.IsTableEmpty
local SCAN_S1 = { "s1_weekly" }
local SCAN_S1_PVP = { "s1_weekly", "pvp_weeklies" }
local SCAN_DELVES = { "delves" }
local SCAN_VAULT_DELVES = { "great_vault", "delves" }
local SCAN_ENCOUNTER = { "great_vault", "delves", "world_bosses", "s1_weekly" }
local SCAN_BOSS = { "world_bosses", "great_vault", "s1_weekly" }

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
    local _, classFile = UnitClass("player")
    if classFile then
        self.db.char.classFile = classFile
    end
    self.db.char.lastSyncAt = GetServerTime()
    self:RebuildTurnInCompletions()
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
    if trackingSurfaceRequested then
        self:RefreshPlayerProfessions()
        self:RefreshProfessionConcentration()
    else
        self:MarkBackgroundDataDirty()
    end

    local shouldHideFrames = self:ShouldHideFramesInCurrentInstance()

    if not shouldHideFrames then
        local shouldBuildMainFrame = mainPanelOpen
        if shouldBuildMainFrame and not self.frame then
            self:BuildUI()
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
    if self.OnRenownUpdate and not self._renownUpdateBucketHandle then
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

function MR:OnCurrencyDisplayUpdate(_, currencyID)
    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return
    end

    local dirty = self:RefreshCurrencyProgress(currencyID, false)

    if self:RefreshModuleScans(SCAN_S1, false) then
        dirty = true
    end

    if self.RefreshDelvesLiveProgress and self:HasVisibleMainTrackingSurface() then
        if self._delvesLiveProgressTimer then
            self:CancelTimer(self._delvesLiveProgressTimer)
        end
        self._delvesLiveProgressTimer = self:ScheduleTimer(function()
            self._delvesLiveProgressTimer = nil
            self:RefreshDelvesLiveProgress(true)
        end, 2)
    end

    if dirty then
        self:RequestDataRefresh()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
end

function MR:OnDelveWidgetUpdate()
    if self._delvesWidgetProgressTimer then
        self:CancelTimer(self._delvesWidgetProgressTimer)
    end
    self._delvesWidgetProgressTimer = self:ScheduleTimer(function()
        self._delvesWidgetProgressTimer = nil
        local visible = self:HasVisibleMainTrackingSurface()
        self:RefreshDelvesLiveProgress(visible)
        if not visible then
            self:MarkBackgroundDataDirty()
        end
    end, 0.2)
end

function MR:OnDelveLootReady()
    if not self.RecordGildedStashLoot then
        return
    end

    local _, matched = self:RecordGildedStashLoot(self:HasVisibleMainTrackingSurface())
    if matched then
        if self._gildedStashLootTimer then
            self:CancelTimer(self._gildedStashLootTimer)
            self._gildedStashLootTimer = nil
        end
        return
    end

    if self._gildedStashLootTimer then
        self:CancelTimer(self._gildedStashLootTimer)
    end
    self._gildedStashLootTimer = self:ScheduleTimer(function()
        self._gildedStashLootTimer = nil
        self:RecordGildedStashLoot(self:HasVisibleMainTrackingSurface())
    end, 0.1)
end

function MR:OnQuestDataChanged()
    self:OnRareProgressChanged()
    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return
    end
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self:ScanAutoUpdateInstanceRows(nil, nil)
        return
    end
    local dirty = false
    if self:RefreshQuestProgress(nil, false) then
        dirty = true
    end
    if self:RefreshModuleScans(SCAN_S1_PVP, false) then
        dirty = true
    end
    if dirty then
        self:RequestDataRefresh()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
end

function MR:OnAreaPoisUpdated()
    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return
    end
    self:RefreshModuleScans(SCAN_DELVES, true)
    if self._areaWeeklyScanTimer then
        return
    end
    self._areaWeeklyScanTimer = self:ScheduleTimer(function()
        self._areaWeeklyScanTimer = nil
        self:RefreshModuleScans(SCAN_S1, true)
    end, 0.05)
end

function MR:OnRareProgressChanged()
    local raresVisible = self.raresFrame and self.raresFrame.IsShown and self.raresFrame:IsShown()
    if self.SyncAllRareKills then
        self:SyncAllRareKills()
    end
    if raresVisible and self.RefreshRares then
        self:RefreshRares()
    end
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
    if self:RefreshModuleScans(SCAN_S1_PVP, false) then
        dirty = true
    end
    if dirty then
        self:RequestDataRefresh()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
    if self.SyncAllRareKills then self:SyncAllRareKills() end
    if self.RefreshRares then self:RefreshRares() end
end

function MR:OnQuestAccepted(_, questID)
    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return
    end

    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self:ScanAutoUpdateInstanceRows(questID, nil)
        return
    end
    local dirty = false
    if self:RefreshQuestProgress(questID, false) then
        dirty = true
    end
    if self:RefreshModuleScans(SCAN_S1_PVP, false) then
        dirty = true
    end
    if dirty then
        self:RequestDataRefresh()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
end

function MR:OnQuestRemoved(_, questID)
    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return
    end

    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self:ScanAutoUpdateInstanceRows(questID, nil)
        return
    end
    local dirty = false
    if self:RefreshQuestProgress(questID, false) then
        dirty = true
    end
    if self:RefreshModuleScans(SCAN_S1_PVP, false) then
        dirty = true
    end
    if dirty then
        self:RequestDataRefresh()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
end

function MR:OnBagUpdateDelayed()
    if not self:HasVisibleMainTrackingSurface() then
        self:MarkBackgroundDataDirty()
        return
    end
    local dirty = self:RefreshItemProgress(nil, false)

    if self:RefreshModuleScans(SCAN_S1, false) then
        dirty = true
    end
    if self:RefreshModuleScans(SCAN_DELVES, false) then
        dirty = true
    end

    if dirty then
        self:RequestDataRefresh()
        if self.RefreshProfessionKnowledgeSurfaces then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
end

function MR:OnProfessionChange()
    if not self:HasVisibleMainTrackingSurface()
        and not (self.gatheringLocationsFrame and self.gatheringLocationsFrame:IsShown()) then
        self:MarkBackgroundDataDirty()
        return
    end
    self:RefreshPlayerProfessions()
    local concentrationChanged = self:RefreshProfessionConcentration() == true
    if concentrationChanged then
        self:RequestDataRefresh()
    end
    if concentrationChanged and self.RequestProfessionKnowledgeSurfaceRefresh then
        self:RequestProfessionKnowledgeSurfaceRefresh()
    elseif concentrationChanged and self.RefreshGatheringLocationsFrame then
        self:RefreshGatheringLocationsFrame()
    end
end

function MR:OnVaultEvent()
    self:RefreshModuleScans(SCAN_VAULT_DELVES, true)
end

function MR:OnZoneChanged()
    self:UpdateInstanceFrameVisibility()
    local darkmoonChanged = self.RefreshDarkmoonVisibility and self:RefreshDarkmoonVisibility()
    self:RefreshModuleScans(SCAN_DELVES, true)
    if darkmoonChanged then
        if self:HasVisibleMainTrackingSurface() then
            self:RequestDataRefresh()
        else
            self:MarkBackgroundDataDirty()
        end
        if self.RequestProfessionKnowledgeSurfaceRefresh then
            self:RequestProfessionKnowledgeSurfaceRefresh()
        end
    end
    if self.OnRaresZoneChanged then
        self:OnRaresZoneChanged()
    end
end

function MR:OnCalendarEventsUpdated()
    if not (self.RefreshDarkmoonVisibility and self:RefreshDarkmoonVisibility()) then
        return
    end
    if self:HasVisibleMainTrackingSurface() then
        self:RequestDataRefresh()
    else
        self:MarkBackgroundDataDirty()
    end
    if self.RequestProfessionKnowledgeSurfaceRefresh then
        self:RequestProfessionKnowledgeSurfaceRefresh()
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
        local dirty = self.RefreshEncounterProgress
            and self:RefreshEncounterProgress(tonumber(encounterId), false, tonumber(difficultyID))
        if self:RefreshModuleScans(SCAN_ENCOUNTER, false) then
            dirty = true
        end
        if dirty then
            self:RequestDataRefresh()
        end
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
    local dirty = self.RefreshEncounterProgress
        and self:RefreshEncounterProgress(tonumber(bossId), false)
    if self:RefreshModuleScans(SCAN_BOSS, false) then
        dirty = true
    end
    if dirty then
        self:RequestDataRefresh()
    end
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
