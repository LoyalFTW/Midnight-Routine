local addonName, ns = ...
local MR = ns.MR
local Foundry = _G.Foundry_1_0
local Core = assert(ns.CoreInternals, "Core/Foundation.lua must load first")
local DeepCopy = Core.DeepCopy
local MergeMissing = Core.MergeMissing
local RestoreDefaults = Core.RestoreDefaults
local IsTableEmpty = Core.IsTableEmpty
local DEFAULTS = Core.defaults
local CoreData = assert(ns.CoreData, "Core progress must load before lifecycle")
local PruneProgressStore = CoreData.PruneProgressStore

local function CountArray(t)
    return type(t) == "table" and #t or 0
end

local function CountMap(t)
    local count = 0
    if type(t) == "table" then
        for _ in pairs(t) do
            count = count + 1
        end
    end
    return count
end

local function CountPools(pools)
    local count = 0
    for _, pool in pairs(pools or {}) do
        count = count + CountArray(pool)
    end
    return count
end

function MR:PrintMemoryReport(details)
    details = details or ""
    local showSources = details == "sources" or details == "debug" or details == "audit"
    if not showSources then
        self._trackRefreshSources = nil
        self._trackRefreshSourcesUntil = nil
        self._refreshSourceCounts = nil
    end
    if UpdateAddOnMemoryUsage then
        UpdateAddOnMemoryUsage()
    end

    local liveAddonMemory = GetAddOnMemoryUsage and GetAddOnMemoryUsage(addonName) or nil
    local liveLuaMemory = collectgarbage and collectgarbage("count") or nil
    if collectgarbage and details ~= "sources" and details ~= "debug" then
        collectgarbage("collect")
    end
    if UpdateAddOnMemoryUsage then
        UpdateAddOnMemoryUsage()
    end

    local addonMemory = GetAddOnMemoryUsage and GetAddOnMemoryUsage(addonName) or nil
    local luaMemory = collectgarbage and collectgarbage("count") or nil
    local modules, rows, enabledModules = 0, 0, 0
    for _, mod in ipairs(self.modules or {}) do
        modules = modules + 1
        rows = rows + CountArray(mod.rows)
        if self.IsModuleEnabled and self:IsModuleEnabled(mod.key) then
            enabledModules = enabledModules + 1
        end
    end

    local accountTasks = self.db and self.db.global and CountArray(self.db.global.customTasks) or 0
    local charTasks = self.db and self.db.char and CountArray(self.db.char.customTasks) or 0
    local detached = CountMap(self.detachedFrames)
    local activeTimers = CountMap(self._timers)
    local mainRows = 0
    local shownMainRows = 0
    local activeTimerRows = 0
    local pooledMainRows = CountPools(self._mainRowWidgetPools)
    if self._mainSectionFrames then
        for _, section in pairs(self._mainSectionFrames) do
            for _, rowFrame in pairs(section._rows or {}) do
                mainRows = mainRows + 1
                if section:IsShown() and rowFrame:IsShown() then
                    shownMainRows = shownMainRows + 1
                end
            end
        end
    end
    for _, rowFrame in ipairs(self._timerRows or {}) do
        if rowFrame and rowFrame.IsShown and rowFrame:IsShown() and rowFrame._timerUpdate then
            activeTimerRows = activeTimerRows + 1
        end
    end

    print("|cff2ae7c6MidnightRoutine memory|r")
    local lastAddonMemory = self._lastMemoryReportAddonKB
    local lastLuaMemory = self._lastMemoryReportLuaKB
    if liveAddonMemory then
        print(("  Addon live: %.2f MB"):format(liveAddonMemory / 1024))
    end
    if addonMemory then
        local delta = lastAddonMemory and ((addonMemory - lastAddonMemory) / 1024) or nil
        print(delta and ("  Addon retained after GC: %.2f MB (%+.2f)"):format(addonMemory / 1024, delta)
            or ("  Addon retained after GC: %.2f MB"):format(addonMemory / 1024))
        self._lastMemoryReportAddonKB = addonMemory
    end
    if liveLuaMemory then
        print(("  Lua live total (all addons): %.2f MB"):format(liveLuaMemory / 1024))
    end
    if luaMemory then
        local delta = lastLuaMemory and ((luaMemory - lastLuaMemory) / 1024) or nil
        print(delta and ("  Lua retained after GC (all addons): %.2f MB (%+.2f)"):format(luaMemory / 1024, delta)
            or ("  Lua retained after GC (all addons): %.2f MB"):format(luaMemory / 1024))
        self._lastMemoryReportLuaKB = luaMemory
    end
    print(("  Modules: %d enabled / %d loaded"):format(enabledModules, modules))
    print(("  Loaded rows: %d"):format(rows))
    print(("  Main row widgets: %d shown / %d attached / %d pooled"):format(shownMainRows, mainRows, pooledMainRows))
    print(("  Main row lifecycle: %d created / %d reused / %d pooled / %d optional parts"):format(
        self._mainRowWidgetCreatedCount or 0,
        self._mainRowWidgetReusedCount or 0,
        self._mainRowWidgetPooledCount or 0,
        self._mainRowOptionalPartCreatedCount or 0
    ))
    print(("  Main section lifecycle: %d created / %d reused / %d pooled / %d idle"):format(
        self._mainSectionWidgetCreatedCount or 0,
        self._mainSectionWidgetReusedCount or 0,
        self._mainSectionWidgetPooledCount or 0,
        #(self._mainSectionWidgetPool or {})
    ))
    print(("  Main viewport refreshes: %d"):format(self._mainViewportRefreshCount or 0))
    local picker = ns.WarbandBoardState and ns.WarbandBoardState.mainAltPickerFrame
    print(("  Main alt picker: %d cached rows / %d created since clear"):format(
        picker and picker.charButtons and #picker.charButtons or 0,
        self._mainAltPickerRowCreatedCount or 0
    ))
    local board = self.altBoardFrame
    local detailRows = board and board._detailRowPool and #board._detailRowPool or 0
    local boardSnapshots = 0
    local boardDetailedSnapshots = 0
    local boardSnapshotRows = 0
    for _, snapshot in ipairs(board and board._data or {}) do
        boardSnapshots = boardSnapshots + 1
        if snapshot._detailsLoaded then
            boardDetailedSnapshots = boardDetailedSnapshots + 1
        end
        for _, moduleEntry in ipairs(snapshot.modules or {}) do
            boardSnapshotRows = boardSnapshotRows + #(moduleEntry.rows or {})
        end
    end
    local concentrationCards = 0
    local concentrationRows = 0
    local function CountConcentrationCards(cards)
        concentrationCards = concentrationCards + #(cards or {})
        for _, card in ipairs(cards or {}) do
            concentrationRows = concentrationRows + #(card._rows or {})
        end
    end
    CountConcentrationCards(board and board._overviewCards)
    CountConcentrationCards(self.concentrationTrackerFrame and self.concentrationTrackerFrame._concentrationTrackerCards)
    print(("  Warband cache: %d characters / %d detail cards / %d detail rows / %d concentration chips"):format(
        board and board.charButtons and #board.charButtons or 0,
        board and board._detailCards and #board._detailCards or 0,
        detailRows,
        board and board.heroConcentrationWidgets and #board.heroConcentrationWidgets or 0
    ))
    print(("  Warband snapshots: %d total / %d detailed / %d retained rows"):format(
        boardSnapshots,
        boardDetailedSnapshots,
        boardSnapshotRows
    ))
    print(("  Warband concentration cache: %d cards / %d rows; created since clear: %d cards / %d rows"):format(
        concentrationCards,
        concentrationRows,
        self._warbandConcentrationCardCreatedCount or 0,
        self._warbandConcentrationRowCreatedCount or 0
    ))
    print(("  Warband created since clear: %d characters / %d detail cards / %d detail rows / %d chips"):format(
        self._warbandCharacterRowCreatedCount or 0,
        self._warbandDetailCardCreatedCount or 0,
        self._warbandDetailRowCreatedCount or 0,
        self._warbandConcentrationChipCreatedCount or 0
    ))
    print(("  Warband refreshes: %d data builds / %d detail builds / %d selection redraws"):format(
        self._warbandBoardDataBuildCount or 0,
        self._warbandBoardDetailBuildCount or 0,
        self._warbandBoardSelectionRefreshCount or 0
    ))
    print(("  Detached windows: %d"):format(detached))
    print(("  Custom tasks: %d character / %d account"):format(charTasks, accountTasks))
    print(("  Scans / UI redraws: %d / %d"):format(self._scanCount or 0, self._refreshUICount or 0))
    print(("  UI refresh attempts: %d"):format(self._refreshUIAttemptCount or 0))
    print(("  Active timers: %d"):format(activeTimers))
    print(("  Countdown ticker: %s, %d active rows, %d ticks"):format(
        self._timerRowsTicker and "running" or "stopped",
        activeTimerRows,
        self._timerRowTickCount or 0
    ))
    if self.GetProfessionKnowledgeCacheCounts then
        local counts = self:GetProfessionKnowledgeCacheCounts()
        print(("  PK catalog: %d compact records"):format(counts.catalogEntries or 0))
        print(("  PK caches: %d primed modules, items %d, quests %d, pending %d/%d, rewards %d, labels %d"):format(
            counts.primedModules or 0,
            counts.itemNames or 0,
            counts.questTitles or 0,
            counts.questTitlePending or 0,
            counts.pendingQuestRows or 0,
            counts.rewardItems or 0,
            counts.pendingLabels or 0
        ))
    end
    if self.GetProfessionKnowledgeWatchCounts then
        local watchedItems, watchedQuests, watchedCurrencies, watchFrame = self:GetProfessionKnowledgeWatchCounts()
        print(("  PK watches: %d items / %d quests / %d currencies / frame %s"):format(
            watchedItems or 0,
            watchedQuests or 0,
            watchedCurrencies or 0,
            watchFrame and "active" or "dormant"
        ))
    end
    local trackingIndexIDs = 0
    local trackingIndexRows = 0
    for _, index in pairs(self._trackingRowIndexes or {}) do
        for _, entries in pairs(index) do
            trackingIndexIDs = trackingIndexIDs + 1
            trackingIndexRows = trackingIndexRows + #(entries or {})
        end
    end
    print(("  Tracking indexes: %d IDs / %d row references"):format(trackingIndexIDs, trackingIndexRows))
    print(("  PK window since clear: %d builds / %d renders / %d refresh requests"):format(
        self._professionKnowledgeWindowBuildCount or 0,
        self._professionKnowledgeWindowRenderCount or 0,
        self._professionKnowledgeWindowRefreshRequestCount or 0
    ))
    print(("  PK render pool since clear: %d frames / %d labels / %d textures created; %d / %d / %d reused"):format(
        self._professionKnowledgePooledFrameCreatedCount or 0,
        self._professionKnowledgePooledLabelCreatedCount or 0,
        self._professionKnowledgePooledTextureCreatedCount or 0,
        self._professionKnowledgePooledFrameReusedCount or 0,
        self._professionKnowledgePooledLabelReusedCount or 0,
        self._professionKnowledgePooledTextureReusedCount or 0
    ))
    print(("  Rares window: %d cached layouts; since clear %d builds / %d rebuilds / %d layouts / %d refreshes"):format(
        self.GetRaresFrameCacheCount and self:GetRaresFrameCacheCount() or 0,
        self._raresWindowBuildCount or 0,
        self._raresWindowRebuildCount or 0,
        self._raresWindowLayoutCount or 0,
        self._raresWindowRefreshCount or 0
    ))
    print(("  Renown window: %d cached layouts; since clear %d builds / %d rebuilds / %d refreshes"):format(
        self.GetRenownFrameCacheCount and self:GetRenownFrameCacheCount() or 0,
        self._renownWindowBuildCount or 0,
        self._renownWindowRebuildCount or 0,
        self._renownWindowRefreshCount or 0
    ))

    if showSources and self._refreshSourceCounts then
        local top = {}
        for source, count in pairs(self._refreshSourceCounts) do
            top[#top + 1] = { source = source, count = count }
        end
        table.sort(top, function(a, b) return a.count > b.count end)
        if #top > 0 then
            print("  Refresh sources:")
            for i = 1, math.min(#top, 5) do
                print(("    %d - %s"):format(top[i].count, top[i].source))
            end
        end
    end

    if details == "modules" then
        print("  Loaded module rows:")
        for _, mod in ipairs(self.modules or {}) do
            local enabled = self.IsModuleEnabled and self:IsModuleEnabled(mod.key)
            local marker = enabled and "*" or "-"
            print(("    %s %s: %d"):format(marker, tostring(mod.key), CountArray(mod.rows)))
        end
    end

    if collectgarbage and (details == "sources" or details == "debug") then
        collectgarbage("step", 300)
    end
end

function MR:NoteRefreshSource(kind, grouped, stackDepth)
    if not self._trackRefreshSources then
        return
    end

    local source = kind or "refresh"
    local now = GetTime and GetTime() or 0
    if self._trackRefreshSourcesUntil and now > self._trackRefreshSourcesUntil then
        self._trackRefreshSources = nil
        self._trackRefreshSourcesUntil = nil
        return
    end

    if debugstack and not grouped then
        local ok, stack = pcall(debugstack, stackDepth or 3, 6, 0)
        if ok and type(stack) == "string" then
            for line in stack:gmatch("[^\n]+") do
                if not line:find("NoteRefreshSource", 1, true)
                    and not line:find("RequestUIRefresh", 1, true)
                    and not line:find("RequestDataRefresh", 1, true)
                    and not line:find("RefreshUI", 1, true) then
                    source = source .. " " .. line:gsub("^%s+", "")
                    break
                end
            end
        end
    end

    self._refreshSourceCounts = self._refreshSourceCounts or {}
    self._refreshSourceCounts[source] = (self._refreshSourceCounts[source] or 0) + 1
    local trace = self._memoryAuditTrace
    if trace then
        trace.intervalSources[source] = (trace.intervalSources[source] or 0) + 1
    end
end

function MR:NoteIdleWork(kind)
    if not self._trackIdleWork then
        return
    end
    self._idleWorkCounts = self._idleWorkCounts or {}
    self._idleWorkCounts[kind] = (self._idleWorkCounts[kind] or 0) + 1
    local trace = self._memoryAuditTrace
    if trace then
        trace.intervalWork[kind] = (trace.intervalWork[kind] or 0) + 1
    end
end

function MR:NoteIdleWorkTime(kind, elapsed)
    local trace = self._memoryAuditTrace
    if not trace or type(elapsed) ~= "number" then
        return
    end
    self._idleWorkTimes[kind] = (self._idleWorkTimes[kind] or 0) + elapsed
    trace.intervalTimes[kind] = (trace.intervalTimes[kind] or 0) + elapsed
end

local function ReadAuditCPU()
    if not (GetCVar and GetCVar("scriptProfile") == "1" and UpdateAddOnCPUUsage and GetAddOnCPUUsage) then
        return nil
    end
    pcall(UpdateAddOnCPUUsage)
    local ok, value = pcall(GetAddOnCPUUsage, addonName)
    return ok and tonumber(value) or nil
end

local function ReadAuditCounters(self)
    return {
        scans = self._scanCount or 0,
        passes = self._moduleScanPassCount or 0,
        modules = self._moduleScanModuleCount or 0,
        redraws = self._refreshUICount or 0,
        attempts = self._refreshUIAttemptCount or 0,
        ticks = self._timerRowTickCount or 0,
        mainCreated = self._mainRowWidgetCreatedCount or 0,
        mainReused = self._mainRowWidgetReusedCount or 0,
        mainPooled = self._mainRowWidgetPooledCount or 0,
        sectionCreated = self._mainSectionWidgetCreatedCount or 0,
        sectionReused = self._mainSectionWidgetReusedCount or 0,
        sectionPooled = self._mainSectionWidgetPooledCount or 0,
        warbandBuilds = self._warbandBoardDataBuildCount or 0,
        warbandDetailBuilds = self._warbandBoardDetailBuildCount or 0,
        warbandRedraws = self._warbandBoardSelectionRefreshCount or 0,
        pkBuilds = self._professionKnowledgeWindowBuildCount or 0,
        pkRenders = self._professionKnowledgeWindowRenderCount or 0,
        pkRequests = self._professionKnowledgeWindowRefreshRequestCount or 0,
        pkFrames = self._professionKnowledgePooledFrameCreatedCount or 0,
        pkLabels = self._professionKnowledgePooledLabelCreatedCount or 0,
        pkTextures = self._professionKnowledgePooledTextureCreatedCount or 0,
        raresBuilds = self._raresWindowBuildCount or 0,
        raresRebuilds = self._raresWindowRebuildCount or 0,
        raresLayouts = self._raresWindowLayoutCount or 0,
        raresRefreshes = self._raresWindowRefreshCount or 0,
        renownBuilds = self._renownWindowBuildCount or 0,
        renownRebuilds = self._renownWindowRebuildCount or 0,
        renownRefreshes = self._renownWindowRefreshCount or 0,
    }
end

local function FindLargestAuditCount(counts)
    local bestKey
    local bestCount = 0
    for key, count in pairs(counts) do
        if count > bestCount then
            bestKey = key
            bestCount = count
        end
    end
    return bestKey, bestCount
end

local function CaptureMemoryAuditSample(self, trace)
    if self._memoryAuditTrace ~= trace then
        return
    end
    if UpdateAddOnMemoryUsage then
        UpdateAddOnMemoryUsage()
    end
    local now = GetTime and GetTime() or trace.startedAt
    local addonKB = GetAddOnMemoryUsage and GetAddOnMemoryUsage(addonName) or nil
    local luaKB = collectgarbage and collectgarbage("count") or nil
    local cpuMS = ReadAuditCPU()
    local counters = ReadAuditCounters(self)
    local previous = trace.lastCounters
    local source, sourceCount = FindLargestAuditCount(trace.intervalSources)
    local work, workCount = FindLargestAuditCount(trace.intervalWork)
    local timedWork, timedMS = FindLargestAuditCount(trace.intervalTimes)
    local sample = {
        elapsed = math.max(0, now - trace.startedAt),
        addonKB = addonKB,
        luaKB = luaKB,
        cpuMS = cpuMS,
        riseKB = addonKB and trace.lastAddonKB and addonKB - trace.lastAddonKB or 0,
        cpuDeltaMS = cpuMS and trace.lastCPUMS and cpuMS - trace.lastCPUMS or nil,
        source = source,
        sourceCount = sourceCount,
        work = work,
        workCount = workCount,
        timedWork = timedWork,
        timedMS = timedMS,
    }
    for key, value in pairs(counters) do
        sample[key] = previous and value - (previous[key] or 0) or 0
    end
    trace.samples[#trace.samples + 1] = sample
    if addonKB then
        trace.minimumKB = math.min(trace.minimumKB or addonKB, addonKB)
        trace.maximumKB = math.max(trace.maximumKB or addonKB, addonKB)
        trace.sumKB = (trace.sumKB or 0) + addonKB
        trace.memorySamples = (trace.memorySamples or 0) + 1
    end
    trace.lastAddonKB = addonKB
    trace.lastCPUMS = cpuMS
    trace.lastCounters = counters
    wipe(trace.intervalSources)
    wipe(trace.intervalWork)
    wipe(trace.intervalTimes)
end

local function DescribeAuditSample(sample)
    local parts = {}
    local function Add(value, label)
        if value and value > 0 then
            parts[#parts + 1] = value .. " " .. label
        end
    end
    Add(sample.scans, "scans")
    if sample.passes > 0 or sample.modules > 0 then
        parts[#parts + 1] = sample.passes .. "/" .. sample.modules .. " module passes"
    end
    Add(sample.redraws, "redraws")
    Add(sample.attempts, "refresh attempts")
    Add(sample.ticks, "countdown ticks")
    Add(sample.mainCreated, "main rows created")
    Add(sample.mainReused, "main rows reused")
    Add(sample.mainPooled, "main rows pooled")
    Add(sample.sectionCreated, "sections created")
    Add(sample.sectionReused, "sections reused")
    Add(sample.sectionPooled, "sections pooled")
    Add(sample.warbandBuilds, "warband builds")
    Add(sample.warbandDetailBuilds, "warband detail builds")
    Add(sample.warbandRedraws, "warband redraws")
    Add(sample.pkBuilds, "PK builds")
    Add(sample.pkRenders, "PK renders")
    Add(sample.pkRequests, "PK requests")
    if sample.pkFrames > 0 or sample.pkLabels > 0 or sample.pkTextures > 0 then
        parts[#parts + 1] = sample.pkFrames .. "/" .. sample.pkLabels .. "/" .. sample.pkTextures .. " PK objects"
    end
    Add(sample.raresBuilds, "rares builds")
    Add(sample.raresRebuilds, "rares rebuilds")
    Add(sample.raresLayouts, "rares layouts")
    Add(sample.raresRefreshes, "rares refreshes")
    Add(sample.renownBuilds, "renown builds")
    Add(sample.renownRebuilds, "renown rebuilds")
    Add(sample.renownRefreshes, "renown refreshes")
    if sample.source then
        parts[#parts + 1] = sample.sourceCount .. "x " .. sample.source
    end
    if sample.work then
        parts[#parts + 1] = sample.workCount .. "x " .. sample.work
    end
    if sample.timedWork then
        parts[#parts + 1] = ("%.2f ms in %s"):format(sample.timedMS, sample.timedWork)
    end
    return #parts > 0 and table.concat(parts, ", ") or "no tracked addon activity"
end

local function PrintMemoryAuditTrace(trace)
    local samples = trace.samples
    if #samples == 0 or not trace.memorySamples or trace.memorySamples == 0 then
        print("  Memory trace unavailable.")
        return
    end
    local averageKB = trace.sumKB / trace.memorySamples
    local peak
    local largestRise
    local largestDrop
    local totalCPU
    local peakCPU
    for _, sample in ipairs(samples) do
        if sample.addonKB and (not peak or sample.addonKB > peak.addonKB) then
            peak = sample
        end
        if not largestRise or sample.riseKB > largestRise.riseKB then
            largestRise = sample
        end
        if not largestDrop or sample.riseKB < largestDrop.riseKB then
            largestDrop = sample
        end
        if sample.cpuDeltaMS then
            totalCPU = (totalCPU or 0) + sample.cpuDeltaMS
            if not peakCPU or sample.cpuDeltaMS > peakCPU.cpuDeltaMS then
                peakCPU = sample
            end
        end
    end
    print(("|cff2ae7c6MidnightRoutine memory trace|r: %d samples, %.2f MB min / %.2f MB average / %.2f MB peak at %.1fs"):format(
        trace.memorySamples,
        trace.minimumKB / 1024,
        averageKB / 1024,
        trace.maximumKB / 1024,
        peak and peak.elapsed or 0
    ))
    if peak then
        print(("  Peak interval: %s"):format(DescribeAuditSample(peak)))
    end
    if largestRise then
        print(("  Largest one-sample rise: %+.2f MB at %.1fs; %s"):format(
            largestRise.riseKB / 1024,
            largestRise.elapsed,
            DescribeAuditSample(largestRise)
        ))
    end
    if largestDrop then
        print(("  Largest one-sample drop: %+.2f MB at %.1fs"):format(largestDrop.riseKB / 1024, largestDrop.elapsed))
    end
    if totalCPU then
        local elapsed = math.max(samples[#samples].elapsed, 0.001)
        print(("  Addon CPU: %.2f ms total, %.3f ms/s average, %.2f ms busiest sample at %.1fs"):format(
            totalCPU,
            totalCPU / elapsed,
            peakCPU and peakCPU.cpuDeltaMS or 0,
            peakCPU and peakCPU.elapsed or 0
        ))
    else
        print("  Addon CPU unavailable. Enable with /console scriptProfile 1, then /reload.")
    end
    local stride = math.max(1, math.ceil(#samples / 20))
    local timeline = {}
    for index = 1, #samples, stride do
        local sample = samples[index]
        if sample.addonKB then
            timeline[#timeline + 1] = ("%.0fs=%.1f"):format(sample.elapsed, sample.addonKB / 1024)
        end
    end
    local finalSample = samples[#samples]
    local finalToken = finalSample.addonKB and ("%.0fs=%.1f"):format(finalSample.elapsed, finalSample.addonKB / 1024) or nil
    if finalToken and timeline[#timeline] ~= finalToken then
        timeline[#timeline + 1] = finalToken
    end
    for index = 1, #timeline, 7 do
        print("  Live MB timeline: " .. table.concat(timeline, " | ", index, math.min(index + 6, #timeline)))
    end
    local ranked = {}
    for _, sample in ipairs(samples) do
        if sample.riseKB > 0 then
            ranked[#ranked + 1] = sample
        end
    end
    table.sort(ranked, function(a, b) return a.riseKB > b.riseKB end)
    if #ranked > 0 then
        print("  Largest growth intervals:")
        for index = 1, math.min(5, #ranked) do
            local sample = ranked[index]
            print(("    %.1fs: %+.2f MB; %s"):format(sample.elapsed, sample.riseKB / 1024, DescribeAuditSample(sample)))
        end
    end
end

function MR:StartMemoryIdleAudit(duration)
    duration = math.max(1, math.min(600, math.floor(tonumber(duration) or 15)))
    if self._memoryAuditTimer then
        self:CancelTimer(self._memoryAuditTimer)
        self._memoryAuditTimer = nil
    end
    if self._memoryAuditSampler then
        self._memoryAuditSampler:Cancel()
        self._memoryAuditSampler = nil
    end

    if collectgarbage then
        collectgarbage("collect")
    end
    if UpdateAddOnMemoryUsage then
        UpdateAddOnMemoryUsage()
    end
    local startAddonKB = GetAddOnMemoryUsage and GetAddOnMemoryUsage(addonName) or nil
    local startLuaKB = collectgarbage and collectgarbage("count") or nil

    self._refreshSourceCounts = {}
    self._idleWorkCounts = {}
    self._idleWorkTimes = {}
    self._trackRefreshSources = true
    self._trackIdleWork = true
    self._trackRefreshSourcesUntil = (GetTime and GetTime() or 0) + duration + 1
    local trace = {
        startedAt = GetTime and GetTime() or 0,
        samples = {},
        intervalSources = {},
        intervalWork = {},
        intervalTimes = {},
        startAddonKB = startAddonKB,
    }
    self._memoryAuditTrace = trace
    local startScans = self._scanCount or 0
    local startRedraws = self._refreshUICount or 0
    local startAttempts = self._refreshUIAttemptCount or 0
    local startTicks = self._timerRowTickCount or 0
    local startModuleScanPasses = self._moduleScanPassCount or 0
    local startModuleScans = self._moduleScanModuleCount or 0
    CaptureMemoryAuditSample(self, trace)
    if C_Timer and C_Timer.NewTicker then
        self._memoryAuditSampler = C_Timer.NewTicker(1, function()
            CaptureMemoryAuditSample(self, trace)
        end)
    end
    print(("|cff2ae7c6MidnightRoutine:|r Starting a %d-second audit with one-second memory samples. Leave the UI untouched for an idle baseline, or reproduce the issue..."):format(duration))
    self._memoryAuditTimer = self:ScheduleTimer(function()
        self._memoryAuditTimer = nil
        if self._memoryAuditSampler then
            self._memoryAuditSampler:Cancel()
            self._memoryAuditSampler = nil
        end
        CaptureMemoryAuditSample(self, trace)
        print(("|cff2ae7c6MidnightRoutine idle audit|r: %d full scans, %d targeted passes/%d modules, %d redraws, %d refresh attempts, %d countdown ticks"):format(
            (self._scanCount or 0) - startScans,
            (self._moduleScanPassCount or 0) - startModuleScanPasses,
            (self._moduleScanModuleCount or 0) - startModuleScans,
            (self._refreshUICount or 0) - startRedraws,
            (self._refreshUIAttemptCount or 0) - startAttempts,
            (self._timerRowTickCount or 0) - startTicks
        ))
        PrintMemoryAuditTrace(trace)
        self:PrintMemoryReport("audit")
        if self._idleWorkCounts and next(self._idleWorkCounts) then
            local work = {}
            for source, count in pairs(self._idleWorkCounts) do
                work[#work + 1] = { source = source, count = count, elapsed = self._idleWorkTimes[source] or 0 }
            end
            table.sort(work, function(a, b)
                if a.elapsed == b.elapsed then
                    return a.count > b.count
                end
                return a.elapsed > b.elapsed
            end)
            print("  Idle callbacks:")
            for index = 1, math.min(#work, 6) do
                print(("    %.2f ms / %d calls - %s"):format(work[index].elapsed, work[index].count, work[index].source))
            end
        end
        self._trackRefreshSources = nil
        self._trackRefreshSourcesUntil = nil
        self._trackIdleWork = nil
        self._memoryAuditTrace = nil
        trace.samples = nil
        trace.intervalSources = nil
        trace.intervalWork = nil
        trace.intervalTimes = nil
        trace.lastCounters = nil
        self._refreshSourceCounts = nil
        self._idleWorkCounts = nil
        self._idleWorkTimes = nil
        if collectgarbage then
            collectgarbage("collect")
        end
        if UpdateAddOnMemoryUsage then
            UpdateAddOnMemoryUsage()
        end
        local cleanAddonKB = GetAddOnMemoryUsage and GetAddOnMemoryUsage(addonName) or nil
        local cleanLuaKB = collectgarbage and collectgarbage("count") or nil
        if cleanAddonKB then
            print(("  Audit-clean retained: %.2f MB (%+.2f MB from forced-GC start)"):format(
                cleanAddonKB / 1024,
                (cleanAddonKB - (trace.startAddonKB or cleanAddonKB)) / 1024
            ))
            self._lastMemoryReportAddonKB = cleanAddonKB
        end
        if cleanLuaKB then
            self._lastMemoryReportLuaKB = cleanLuaKB
        end
    end, duration)

    self._lastMemoryReportAddonKB = startAddonKB
    self._lastMemoryReportLuaKB = startLuaKB
end

function MR:OnInitialize()
    self.db = Foundry.DB:New({
        name = addonName,
        sv = "MidnightRoutineDB",
        defaults = DEFAULTS,
        defaultProfile = true,
    })
    if self.db.profile.allowUpdatesDuringCombat ~= nil then
        self.db.profile.disabledInCombat = self.db.profile.allowUpdatesDuringCombat ~= true
        self.db.profile.allowUpdatesDuringCombat = nil
    end
    for _, charData in pairs(self.db.sv.char or {}) do
        if type(charData) == "table" then
            PruneProgressStore(charData.progress)
        end
    end
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
    if ns.ApplyThemeAccentColor then
        ns.ApplyThemeAccentColor(self:GetThemeColor())
    end
    if ns.ApplyTitleBarTheme then
        ns.ApplyTitleBarTheme(self:GetThemeColor())
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
    self:SetFrameStrata(DEFAULTS.profile.frameStrata)

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
    if ns.ApplyThemeAccentColor then
        ns.ApplyThemeAccentColor(self:GetThemeColor())
    end
    if ns.ApplyTitleBarTheme then
        ns.ApplyTitleBarTheme(self:GetThemeColor())
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
    if not self.db then return end
    self:SetWindowLayoutValue("panelOpen", open and true or false)
    if self._instanceFramesHidden then
        self._instanceRestoreState = self._instanceRestoreState or {}
        self._instanceRestoreState.panel = open and true or false
    end
end

function MR:GetMainPanelOpen()
    if not self.db then return true end
    return self:GetWindowLayoutValue("panelOpen") ~= false
end

function MR:ShowMainPanel(userSet)
    self:SetMainPanelOpen(true, userSet ~= false)
    self:ClearManagedWindowsBundleHidden()
    if self._instanceFramesHidden then
        return false
    end
    if not self.frame and self.BuildUI then
        self:BuildUI()
    elseif self.frame then
        self.frame:Show()
    end
    return self.frame and self.frame:IsShown() or false
end

function MR:HideMainPanel(userSet)
    if self.HideCurrencyBrowserFrame then
        self:HideCurrencyBrowserFrame()
    end
    if self.frame then
        self.frame:Hide()
    end
    self:SetMainPanelOpen(false, userSet ~= false)
end

function MR:ToggleMainPanel()
    if self.frame and self.frame:IsShown() then
        self:HideMainPanel(true)
        return false
    end
    return self:ShowMainPanel(true)
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
        if self.db.profile.rememberManagedWindowsVisibility then
            self.db.profile.managedWindowsBundleHidden = true
        end
    end

    if self.frame then self.frame:Hide() end
    if self.HideCurrencyBrowserFrame then self:HideCurrencyBrowserFrame() end
    if self.HideDetachedModules then self:HideDetachedModules() end
    if self.HideConfig then self:HideConfig() end
    if self.welcomeFrame then self.welcomeFrame:Hide() end
    if self.HideRenown then self:HideRenown(false) end
    if self.HideRares then self:HideRares(false) end
    if self.HideGatheringLocations then self:HideGatheringLocations(false) end
    if self.HideConcentrationTracker then self:HideConcentrationTracker(false) end
    if self.SuspendHiddenSurfaceWork then self:SuspendHiddenSurfaceWork() end
end

function MR:AutoHideManagedWindowsOnLogin()
    if not self.db then return end
    local state = self:CaptureManagedWindowState()
    state.panel = self:GetMainPanelOpen()
    state.renown = self:GetManagedWindowOpen("renownOpen")
    state.rares = self:GetManagedWindowOpen("raresOpen")
    state.gathering = self:GetManagedWindowOpen("gatheringLocOpen")
    state.concentration = self:GetManagedWindowOpen("concentrationTrackerOpen")
    if self:ManagedWindowStateHasVisibleFrames(state) then
        self._toggleRestoreState = state
        self:SetManagedWindowRestoreState(state)
    end
    self:HideManagedWindows(false)
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

    local state = self:CaptureManagedWindowState()
    if self:ManagedWindowStateHasVisibleFrames(state) then
        self._toggleRestoreState = state
        self:SetManagedWindowRestoreState(state)
        self:HideManagedWindows(true)
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

    return self:ShowMainPanel(true)
end

local toggleWindowsBindingButton = CreateFrame("Button", "MidnightRoutineToggleWindowsBindingButton", UIParent)
toggleWindowsBindingButton:SetScript("OnClick", function()
    MR:ToggleManagedWindows()
end)
ns.TOGGLE_WINDOWS_BINDING = "CLICK MidnightRoutineToggleWindowsBindingButton:LeftButton"

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
    if self.EnableAltBankTracking then self:EnableAltBankTracking() end
    if self.isForever then
        self:RegisterBucketEvent({ "QUEST_LOG_UPDATE", "SKILL_LINES_CHANGED", "UPDATE_FACTION" }, 0.5, "OnForeverProgressChanged")
        self:RegisterEvent("CURRENCY_DISPLAY_UPDATE", "OnForeverProgressChanged")
        self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnEnteringWorld")
        self:RegisterEvent("PLAYER_REGEN_DISABLED", "OnCombatStarted")
        self:RegisterEvent("PLAYER_REGEN_ENABLED", "OnCombatEnded")
        self:ScheduleNextResetCheck()
        return
    end
    self:RegisterBucketEvent({
        "AREA_POIS_UPDATED",
    }, 10, "OnAreaPoisUpdated")

    self:RegisterBucketEvent({
        "QUEST_LOG_UPDATE",
        "UNIT_QUEST_LOG_CHANGED",
        "GOSSIP_SHOW",
        "GOSSIP_CLOSED",
        "QUEST_DETAIL",
        "QUEST_DATA_LOAD_RESULT",
        "QUEST_PROGRESS",
        "QUEST_COMPLETE",
    }, 2, "OnQuestDataChanged")

    self:RegisterBucketEvent({
        "CRITERIA_UPDATE",
        "ACHIEVEMENT_EARNED",
    }, 0.25, "OnRareProgressChanged")

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
        "CALENDAR_UPDATE_EVENT_LIST",
    }, 0.5, "OnCalendarEventsUpdated")

    self:RegisterBucketEvent({
        "CHALLENGE_MODE_COMPLETED",
        "WEEKLY_REWARDS_UPDATE",
        "LFG_COMPLETION_REWARD",
    }, 1, "OnVaultEvent")

    self:RegisterEvent("ENCOUNTER_END",            "OnEncounterEnd")
    self:RegisterEvent("BOSS_KILL",                "OnBossKill")
    self:RegisterEvent("CURRENCY_DISPLAY_UPDATE",  "OnCurrencyDisplayUpdate")
    self:RegisterEvent("PLAYER_MONEY",             "OnPlayerMoney")
    self:RegisterEvent("ACCOUNT_MONEY",            "OnWarbandMoney")
    self:RegisterEvent("BANKFRAME_OPENED",         "OnWarbandMoney")
    self:RegisterEvent("UPDATE_UI_WIDGET",         "OnDelveWidgetUpdate")
    self:RegisterEvent("UPDATE_ALL_UI_WIDGETS",    "OnDelveWidgetUpdate")
    self:RegisterEvent("LOOT_READY",               "OnDelveLootReady")
    self:RegisterEvent("LOOT_OPENED",              "OnDelveLootReady")
    self:RegisterEvent("QUEST_TURNED_IN",          "OnQuestTurnedIn")
    self:RegisterEvent("QUEST_TURNED_IN",          "OnQuestTurnInCompletion")
    self:RegisterEvent("QUEST_ACCEPTED",           "OnQuestAccepted")
    self:RegisterEvent("QUEST_REMOVED",            "OnQuestRemoved")
    self:RegisterEvent("BAG_UPDATE_DELAYED",       "OnBagUpdateDelayed")
    self:RegisterEvent("PLAYER_ENTERING_WORLD",    "OnEnteringWorld")
    self:RegisterEvent("PLAYER_REGEN_DISABLED",    "OnCombatStarted")
    self:RegisterEvent("PLAYER_REGEN_ENABLED",     "OnCombatEnded")
    if C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("UNIT_DIED") then
        self:RegisterEvent("UNIT_DIED", "OnRareUnitDied")
    else
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnRareCombatLogEvent")
    end

    self:ScheduleNextResetCheck()


end
