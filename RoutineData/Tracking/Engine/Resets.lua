local _, addonNS = ...
local tracking = addonNS.Tracking
local env = tracking.env

tracking.installers.Resets = function(MR, context)
    local DAY_SECONDS = 24 * 60 * 60
    local WEEK_SECONDS = 7 * DAY_SECONDS

    local function ResetSavedCharacters(self, resetType, resetAt, forceReset)
        local moduleKeys = {}
        local resetCharacters = {}
        for _, mod in ipairs(self.modules) do
            if mod.resetType == resetType then
                moduleKeys[#moduleKeys + 1] = mod.key
            end
        end

        local currentReset = false
        local function resetCharacter(charData)
            if type(charData) ~= "table" then
                return
            end
            local stampKey = resetType == "daily" and "lastDailyAt" or "lastResetAt"
            local previousResetAt = tonumber(charData[stampKey])
            if not forceReset and resetAt and previousResetAt and previousResetAt > 0 and resetAt <= previousResetAt + 300 then
                if charData == self.db.char then
                    currentReset = true
                end
                return
            end
            if type(charData.progress) == "table" then
                for _, moduleKey in ipairs(moduleKeys) do
                    charData.progress[moduleKey] = {}
                end
            end
            if type(charData.manualOverrides) == "table" then
                for _, moduleKey in ipairs(moduleKeys) do
                    charData.manualOverrides[moduleKey] = nil
                end
            end
            if type(charData.questTurnInCompletions) == "table" then
                for _, moduleKey in ipairs(moduleKeys) do
                    charData.questTurnInCompletions[moduleKey] = nil
                end
            end
            if resetType == "daily" then
                if resetAt then charData.lastDailyAt = resetAt end
            else
                if resetAt then charData.lastResetAt = resetAt end
                charData.raresKills = {}
            end
            resetCharacters[#resetCharacters + 1] = charData
            if charData == self.db.char then
                currentReset = true
            end
        end

        local characters = self:GetCharacters()
        if type(characters) == "table" then
            for _, charData in pairs(characters) do
                resetCharacter(charData)
            end
        end
        if self.db and self.db.char and not currentReset then
            resetCharacter(self.db.char)
        end
        return resetCharacters
    end

    local function HasSavedCharacterResetPending(self, resetType, resetAt)
        local characters = self:GetCharacters()
        if type(characters) ~= "table" then
            return false
        end
        for _, charData in pairs(characters) do
            if type(charData) == "table" then
                local stampKey = resetType == "daily" and "lastDailyAt" or "lastResetAt"
                local previousResetAt = tonumber(charData[stampKey])
                if not previousResetAt or previousResetAt == 0 or resetAt > previousResetAt + 300 then
                    return true
                end
            end
        end
        return false
    end

    local function GetResetTimestampFromCountdown(secondsUntilReset, cycleSeconds)
        if type(secondsUntilReset) ~= "number" then
            return nil
        end

        secondsUntilReset = math.floor(secondsUntilReset)
        if secondsUntilReset <= 0 then
            return nil
        end

        if secondsUntilReset > cycleSeconds then
            return nil
        end

        return GetServerTime() + secondsUntilReset - cycleSeconds
    end

    local function GetResetCountdown(getter)
        if type(getter) ~= "function" then
            return nil
        end
        local ok, seconds = pcall(getter)
        if not ok or type(seconds) ~= "number" or seconds < 0 then
            return nil
        end
        return seconds
    end

    function MR:ScheduleNextResetCheck()
        if self._scheduledResetTimer then
            self:CancelTimer(self._scheduledResetTimer)
            self._scheduledResetTimer = nil
        end

        local daily = C_DateAndTime and GetResetCountdown(C_DateAndTime.GetSecondsUntilDailyReset)
        local weekly = C_DateAndTime and GetResetCountdown(C_DateAndTime.GetSecondsUntilWeeklyReset)
        local seconds
        if daily and weekly then
            seconds = math.min(daily, weekly)
        else
            seconds = daily or weekly
        end

        local delay = seconds and math.max(1, seconds + 2) or 60
        self._scheduledResetTimer = self:ScheduleTimer(function()
            self._scheduledResetTimer = nil
            self:CheckScheduledResets()
        end, delay)
    end

    function MR:GetLastDailyTimestamp()
        if C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset then
            local ts = GetResetTimestampFromCountdown(C_DateAndTime.GetSecondsUntilDailyReset(), DAY_SECONDS)
            if ts then
                return ts
            end
        end

        return nil
    end

    function MR:CheckDailyReset()
        local lastDailyAt = self:GetLastDailyTimestamp()
        if not lastDailyAt then return end
        local prevDailyAt = self.db.char.lastDailyAt
        if not prevDailyAt or prevDailyAt == 0 or lastDailyAt > prevDailyAt + 300
            or HasSavedCharacterResetPending(self, "daily", lastDailyAt) then
            if env.shouldDefer("dailyReset") then
                return
            end
            self:DoDailyReset()
        end
    end

    function MR:DoDailyReset()
        if env.shouldDefer("dailyReset") then
            return
        end

        local ts = self:GetLastDailyTimestamp()

        self._scanSuppressedUntil = math.max(self._scanSuppressedUntil or 0, GetTime() + 15)

        local resetCharacters = ResetSavedCharacters(self, "daily", ts)
        tracking:Fire("CustomTasksResetDue", "daily", false, resetCharacters)
        tracking:Fire("ResetApplied", "daily")
        self:RequestScan(20)
    end

    function MR:GetLastResetTimestamp()
        if C_DateAndTime and C_DateAndTime.GetSecondsUntilWeeklyReset then
            local ts = GetResetTimestampFromCountdown(C_DateAndTime.GetSecondsUntilWeeklyReset(), WEEK_SECONDS)
            if ts then
                return ts
            end
        end

        return nil
    end

    function MR:GetCurrentWeekKey()
        return self:GetLastResetTimestamp() or 0
    end

    function MR:CheckWeeklyReset()
        local lastResetAt = self:GetLastResetTimestamp()
        if not lastResetAt then return end

        local prevResetAt = self.db.char.lastResetAt

        if not prevResetAt or prevResetAt == 0 or lastResetAt > prevResetAt + 300
            or HasSavedCharacterResetPending(self, "weekly", lastResetAt) then
            if env.shouldDefer("weeklyReset") then
                return
            end
            self:DoWeeklyReset()
        end
    end

    function MR:DoWeeklyReset(manual)
        if manual then
            self._manualWeeklyResetPending = true
        end
        if env.shouldDefer("weeklyReset") then
            return
        end

        local prevResetAt = self.db.char.lastResetAt
        local firstRun = not prevResetAt or prevResetAt == 0
        local announceReset = not firstRun or self._manualWeeklyResetPending
        local forceCustomReset = self._manualWeeklyResetPending == true
        self._manualWeeklyResetPending = nil

        local ts = self:GetLastResetTimestamp()

        self._scanSuppressedUntil = math.max(self._scanSuppressedUntil or 0, GetTime() + 15)

        local resetCharacters = ResetSavedCharacters(self, "weekly", ts, forceCustomReset)
        tracking:Fire("CustomTasksResetDue", "weekly", forceCustomReset, resetCharacters)
        tracking:Fire("ResetApplied", "weekly")
        self:RequestScan(20)
        if announceReset then
            tracking:Fire("WeeklyResetAnnounced")
        end
    end
    local TRACKED_DATA_DEFAULTS = {
        progress = function() return {} end,
        manualOverrides = function() return {} end,
        rowVisibility = function() return {} end,
        professions = function() return {} end,
        professionsScanned = function() return false end,
        professionConcentration = function() return {} end,
        customTaskDiffProgress = function() return {} end,
        raresKills = function() return {} end,
        lastWeek = function() return 0 end,
        lastSyncAt = function() return 0 end,
        lastDailyAt = function() return 0 end,
        lastResetAt = function() return 0 end,
        questTurnInCompletions = false,
        knownProfessionLines = false,
        mythicPlusScore = false,
        gold = false,
        classFile = false,
    }

    function MR:IsTrackedDataKey(key)
        return TRACKED_DATA_DEFAULTS[key] ~= nil
    end

    function MR:WipeTrackedData()
        local charData = self.db and self.db.char
        if not charData then
            return
        end

        for key, makeDefault in pairs(TRACKED_DATA_DEFAULTS) do
            if makeDefault then
                charData[key] = makeDefault()
            else
                charData[key] = nil
            end
        end
    end

    function MR:CheckScheduledResets()
        self:CheckWeeklyReset()
        self:CheckDailyReset()
        if env.refreshDarkmoonVisibility() then
            tracking:Fire("DataChanged")
            tracking:Fire("KnowledgeSurfacesChanged")
        end
        self:ScheduleNextResetCheck()
    end
end
