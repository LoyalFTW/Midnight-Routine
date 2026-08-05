local addonName, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Core = assert(ns.CoreInternals, "Core/Foundation.lua must load first")
local DeepCopy = Core.DeepCopy
local MergeMissing = Core.MergeMissing
local RestoreDefaults = Core.RestoreDefaults
local IsTableEmpty = Core.IsTableEmpty
local MODULES_WITH_OPTIONAL_CURRENCY_COMPLETION = Core.optionalCurrencyModules

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
        if self.RefreshWarbandCharacterSurfaces then self:RefreshWarbandCharacterSurfaces() end

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
    elseif msg == "mem" or msg == "memory" then MR:PrintMemoryReport()
    elseif msg == "mem modules" or msg == "memory modules" then
        MR:PrintMemoryReport("modules")
    elseif msg == "mem sources" or msg == "memory sources" or msg == "mem debug" then
        MR:StartMemoryIdleAudit(15)
    elseif msg == "mem clear" or msg == "memory clear" then
        MR._refreshSourceCounts = nil
        MR._trackRefreshSources = nil
        MR._trackRefreshSourcesUntil = nil
        MR._scanCount = 0
        MR._refreshUICount = 0
        MR._refreshUIAttemptCount = 0
        MR._timerRowTickCount = 0
        MR._moduleScanPassCount = 0
        MR._moduleScanModuleCount = 0
        MR._mainRowWidgetCreatedCount = 0
        MR._mainRowWidgetReusedCount = 0
        MR._mainRowWidgetPooledCount = 0
        MR._mainRowOptionalPartCreatedCount = 0
        MR._mainAltPickerRowCreatedCount = 0
        MR._warbandCharacterRowCreatedCount = 0
        MR._warbandDetailCardCreatedCount = 0
        MR._warbandDetailRowCreatedCount = 0
        MR._warbandConcentrationChipCreatedCount = 0
        MR._warbandConcentrationCardCreatedCount = 0
        MR._warbandConcentrationRowCreatedCount = 0
        MR._warbandBoardDataBuildCount = 0
        MR._warbandBoardSelectionRefreshCount = 0
        MR._idleWorkCounts = nil
        MR._trackIdleWork = nil
        MR._lastMemoryReportAddonKB = nil
        MR._lastMemoryReportLuaKB = nil
        if collectgarbage then
            collectgarbage("collect")
        end
        print("|cff2ae7c6MidnightRoutine:|r Memory debug counters cleared.")
    elseif msg == "test" or msg == "selftest" then MR:RunSelfTest()
    else
        print(L["Chat_Commands"])
    end
end
