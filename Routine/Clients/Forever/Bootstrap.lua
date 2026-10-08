local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers["ForeverBootstrap"] = function(owner, context)
    local ns = context.namespace
    local L = context.labels
    local MR = ns.MR

    if not MR.isForever then
        return
    end

    MR:RegisterExpansion({ key = "forever", label = "WoW Forever", order = 1 })

    function MR:OnForeverProgressChanged()
        self:RequestScan(0.2)
    end

    local function RefreshProfessions(mod)
        ns.Forever.RefreshProfessions()
        local rows = {}
        for _, profession in ipairs(ns.Forever.professions) do
            local key = "profession_" .. profession.skillLine
            rows[#rows + 1] = { key = key, label = profession.label, max = profession.maxRank, mode = "count", autoTracked = true, icon = profession.icon }
            MR:WriteScanProgress(mod.key, key, profession.rank)
        end
        mod.rows = rows
        if MR.RefreshGatheringLocationsFrame then MR:RefreshGatheringLocationsFrame() end
        MR._moduleStatsCache = nil
        return true
    end

    local function RefreshReputations(mod)
        local rows = {}
        for _, faction in ipairs(ns.Forever.GetFactions()) do
            local _, _, current, max = ns.Forever.GetReputation(faction)
            rows[#rows + 1] = { key = faction.key, label = faction.label, max = max, autoTracked = true }
            MR:WriteScanProgress(mod.key, faction.key, current)
        end
        mod.rows = rows
        if MR.RefreshRenown then MR:RefreshRenown() end
        if MR.RepopulateRenownConfig then MR:RepopulateRenownConfig() end
        MR._moduleStatsCache = nil
        return true
    end

    local function RefreshRares(mod)
        local changed = MR.SyncAllRareKills and MR:SyncAllRareKills() or false
        if MR.RefreshRares then MR:RefreshRares() end
        return changed
    end

    if not ns.Forever.hideProfessions then
    MR:RegisterModule({
        key = "forever_professions",
        expansionKey = "forever",
        label = L["Forever_Professions"],
        labelColor = "#c9853f",
        defaultOpen = true,
        rows = {},
        onScan = RefreshProfessions,
        scanReturnsChanged = true,
        isVisible = function() return false end,
    })
    end

    MR:RegisterModule({
        key = "forever_reputations",
        expansionKey = "forever",
        label = L["Forever_Reputations"],
        labelColor = "#58c9d4",
        defaultOpen = true,
        rows = {},
        onScan = RefreshReputations,
        scanReturnsChanged = true,
        isVisible = function() return false end,
    })

    if not ns.Forever.hideRares then
    MR:RegisterModule({
        key = "forever_rares",
        expansionKey = "forever",
        label = L["Forever_Rares"],
        labelColor = "#d6a8ff",
        defaultOpen = true,
        rows = {},
        onScan = RefreshRares,
        scanReturnsChanged = true,
        isVisible = function() return false end,
    })
    end

    local rareWatcher = CreateFrame("Frame")
    if not ns.Forever.hideRares then
        rareWatcher:RegisterEvent("PLAYER_TARGET_CHANGED")
        rareWatcher:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
        rareWatcher:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    end
    rareWatcher:RegisterEvent("SKILL_LINES_CHANGED")
    rareWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    if not ns.Forever.hideRares and C_EventUtils and C_EventUtils.IsEventValid and C_EventUtils.IsEventValid("UNIT_DIED") then
        rareWatcher:RegisterEvent("UNIT_DIED")
    end
    rareWatcher:RegisterEvent("UPDATE_FACTION")
    rareWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    rareWatcher:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    rareWatcher:SetScript("OnEvent", function(_, event, unitGUID)
        if event == "UNIT_DIED" then
            if MR.OnRareUnitDied then MR:OnRareUnitDied(event, unitGUID) end
            return
        end
        if event == "SKILL_LINES_CHANGED" then
            if MR.RequestScan then MR:RequestScan(0.2) end
            return
        end
        if event == "ZONE_CHANGED_NEW_AREA" then
            if MR.OnRaresZoneChanged then MR:OnRaresZoneChanged() end
            return
        end
        if event == "PLAYER_ENTERING_WORLD" or event == "CURRENCY_DISPLAY_UPDATE" then
            if MR.RefreshCurrenciesModule then MR:RefreshCurrenciesModule(false) end
            if MR.RequestScan then MR:RequestScan(0.2) end
            return
        end
        if event == "UPDATE_FACTION" then
            if MR.RequestScan then MR:RequestScan(0.2) end
            return
        end
        local unit = event == "UPDATE_MOUSEOVER_UNIT" and "mouseover" or event == "NAME_PLATE_UNIT_ADDED" and unitGUID or "target"
        if not ns.Forever.hideRares and ns.Forever.DiscoverRare(unit) then
            RefreshRares(MR.moduleByKey.forever_rares)
            if MR.RepopulateRaresConfig then MR:RepopulateRaresConfig() end
        end
    end)
end
