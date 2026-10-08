local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers.Events = function(MR, context)
local SCAN_S1 = { "s1_weekly" }
local SCAN_S1_PVP = { "s1_weekly", "pvp_weeklies", "prey", "midnight_activities" }
local SCAN_DELVES = { "delves" }
local SCAN_VAULT_DELVES = { "great_vault", "delves" }
local SCAN_ENCOUNTER = { "great_vault", "delves", "world_bosses", "s1_weekly" }
local SCAN_BOSS = { "world_bosses", "great_vault", "s1_weekly" }

function MR:RefreshEnteringWorldTracking()
    local _, classFile = UnitClass("player")
    if classFile then
        self.db.char.classFile = classFile
    end
    self.db.char.lastSyncAt = GetServerTime()
    if not self.isForever and self.RefreshCurrentMythicPlusScore then
        self:RefreshCurrentMythicPlusScore()
        self:ScheduleTimer(function()
            if self:RefreshCurrentMythicPlusScore() then
                self:RequestDataRefresh()
            end
        end, 2)
    end
    if self.RefreshCurrentGold then
        self:RefreshCurrentGold()
    end
    if not self.isForever and self.RefreshWarbandGold then
        self:RefreshWarbandGold()
    end
    self:RebuildTurnInCompletions()
end

local function ProcessCurrencyDisplayUpdates(self)
    self._currencyDisplayUpdateTimer = nil

    local dirty = false
    if self._pendingAllCurrencyDisplays then
        dirty = self:RefreshCurrencyProgress(nil, false)
    else
        for currencyID in pairs(self._pendingCurrencyDisplayIDs or {}) do
            if self:RefreshCurrencyProgress(currencyID, false) then
                dirty = true
            end
        end
    end
    if self._pendingCurrencyDisplayIDs then
        wipe(self._pendingCurrencyDisplayIDs)
    end
    self._pendingAllCurrencyDisplays = nil

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

function MR:OnCurrencyDisplayUpdate(_, currencyID)
    self._pendingCurrencyDisplayIDs = self._pendingCurrencyDisplayIDs or {}
    if currencyID then
        self._pendingCurrencyDisplayIDs[currencyID] = true
    else
        self._pendingAllCurrencyDisplays = true
    end
    if self._currencyDisplayUpdateTimer then
        return
    end
    self._currencyDisplayUpdateTimer = self:ScheduleTimer(function()
        ProcessCurrencyDisplayUpdates(self)
    end, 0.1)
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
    local changed = self.SyncAllRareKills and self:SyncAllRareKills()
    if changed and self.RefreshRares then
        self:RefreshRares()
    end
end

function MR:OnQuestTurnedIn(_, questID)
    local dirty = self:RecordQuestTurnInProgress(questID)
    local rareChanged = self.SyncRareQuestCompletion and self:SyncRareQuestCompletion(questID)
    if self.ShouldSuspendBackgroundWorkInCurrentInstance and self:ShouldSuspendBackgroundWorkInCurrentInstance() then
        self:ScanAutoUpdateInstanceRows(questID, nil)
        if dirty then self:MarkBackgroundDataDirty() end
        if rareChanged and self.RefreshRares then self:RefreshRares() end
        return
    end
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
    if rareChanged and self.RefreshRares then self:RefreshRares() end
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
    local scoreChanged = self.RefreshCurrentMythicPlusScore and self:RefreshCurrentMythicPlusScore()
    self:RefreshModuleScans(SCAN_VAULT_DELVES, true)
    if scoreChanged then
        self:RequestDataRefresh()
    end
    if self.RefreshCurrentMythicPlusScore then
        self:ScheduleTimer(function()
            if self:RefreshCurrentMythicPlusScore() then
                self:RequestDataRefresh()
            end
        end, 2)
    end
end

function MR:OnPlayerMoney()
    if self.RefreshCurrentGold and self:RefreshCurrentGold() then
        self:RequestDataRefresh()
    end
end

function MR:OnWarbandMoney()
    if self.RefreshWarbandGold and self:RefreshWarbandGold() then
        self:RequestDataRefresh()
    end
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
    local darkmoonChanged = self.RefreshDarkmoonVisibility and self:RefreshDarkmoonVisibility()
    local brewfestChanged = self.RefreshBrewfestVisibility and self:RefreshBrewfestVisibility()
    if not darkmoonChanged and not brewfestChanged then
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

end
