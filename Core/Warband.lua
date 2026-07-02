local _, ns = ...
local MR = ns.MR

local DAY_SECONDS = 24 * 60 * 60

local function ParseCharacterKey(charKey)
    if type(charKey) ~= "string" then
        return "Unknown", ""
    end

    local name, realm = charKey:match("^(.-)%s%-%s(.+)$")
    if name and realm then
        return name, realm
    end

    return charKey, ""
end

local function CleanAccountLabel(text)
    if type(text) ~= "string" then
        return tostring(text or "")
    end

    return text:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
end

local function GetProfessionLabelBySkillLine(skillLineID)
    if MR and MR.modules then
        for _, mod in ipairs(MR.modules) do
            if mod.profSkillLine == skillLineID and mod.label then
                return CleanAccountLabel(mod.label)
            end
        end
    end

    return tostring(skillLineID or "")
end

local function EstimateCurrencyQuantity(currencyInfo)
    if type(currencyInfo) ~= "table" then
        return 0, 0
    end

    local quantity = tonumber(currencyInfo.quantity) or 0
    local maxQuantity = tonumber(currencyInfo.maxQuantity) or 0
    local lastUpdated = tonumber(currencyInfo.lastUpdated) or 0
    local cycleMS = tonumber(currencyInfo.rechargingCycleDurationMS) or 0
    local amountPerCycle = tonumber(currencyInfo.rechargingAmountPerCycle) or 1
    if amountPerCycle <= 0 then
        amountPerCycle = 1
    end

    if maxQuantity <= 0 then
        return quantity, maxQuantity
    end

    if lastUpdated <= 0 or cycleMS <= 0 or amountPerCycle <= 0 then
        return math.min(quantity, maxQuantity), maxQuantity
    end

    local now = (GetServerTime and GetServerTime()) or time()
    local elapsed = math.max(0, now - lastUpdated)
    local estimated = quantity + (((elapsed * 1000) / cycleMS) * amountPerCycle)

    return math.min(estimated, maxQuantity), maxQuantity
end

local function IsAltBoardModule(mod)
    if not mod or not mod.key then
        return false
    end

    if mod.resetType == "weekly" then
        return true
    end

    return mod.key:match("^story_campaign_") ~= nil
end


function MR:GetCurrentCharacterKey()
    -- Foundry.DB has no db.keys introspection surface (unlike AceDB) — even
    -- referencing self.db.keys raises, so this is the only path now. Must match
    -- Foundry.DB's own resolveCharKey() exactly (UnitName .. " - " .. GetRealmName,
    -- the same formula AceDB used) since self.db.sv.char is keyed by that function,
    -- not by this one — UnitFullName is a different API with no guarantee its
    -- output matches, and using it here would silently break sv.char lookups.
    local name = UnitName and UnitName("player")
    local realm = GetRealmName and GetRealmName()
    if name and realm and realm ~= "" then
        return string.format("%s - %s", name, realm)
    end

    return name or "Unknown"
end

function MR:GetMainFrameProgressSource()
    local charKey = self.mainAltViewCharKey
    if not (charKey and self.db and self.db.sv and self.db.sv.char) then
        return self.db and self.db.char or nil
    end

    return self.db.sv.char[charKey] or self.db.char
end

function MR:IsMainAltViewActive()
    return self.mainAltViewCharKey ~= nil
end

function MR:GetMainAltViewCharacterKey()
    return self.mainAltViewCharKey
end

function MR:SetMainAltViewCharacter(charKey)
    local currentKey = self:GetCurrentCharacterKey()
    if not charKey or charKey == currentKey then
        self.mainAltViewCharKey = nil
    elseif self.db and self.db.sv and self.db.sv.char and self.db.sv.char[charKey] then
        self.mainAltViewCharKey = charKey
    end

    if self.RefreshUI then
        self:RefreshUI()
    end
    if self.RefreshMainAltPicker then
        self:RefreshMainAltPicker()
    end
end

function MR:GetMainAltViewCharacterInfo()
    local charKey = self.mainAltViewCharKey
    if not (charKey and self.db and self.db.sv and self.db.sv.char and self.db.sv.char[charKey]) then
        return nil
    end

    local name, realm = ParseCharacterKey(charKey)
    return {
        key = charKey,
        name = name,
        realm = realm,
        data = self.db.sv.char[charKey],
    }
end

function MR:GetWarbandWeeklyData(showHiddenOverride)
    if not (self and self.db and self.db.sv and self.db.sv.char) then
        return {}
    end

    local results = {}
    local selectedExpansion = self:GetSelectedExpansionKey(true)
    local currentKey = self:GetCurrentCharacterKey()
    local resetAt = self.GetLastResetTimestamp and self:GetLastResetTimestamp() or 0
    local hiddenChars = (self.db and self.db.profile and self.db.profile.altBoardHiddenCharacters) or {}
    local showHidden = showHiddenOverride
    if showHidden == nil then
        showHidden = self.db and self.db.profile and self.db.profile.altBoardShowHidden == true
    else
        showHidden = showHidden == true
    end
    local useCharacterLayout = self:IsCharacterWindowLayoutEnabled()
    local sharedModuleStateBuckets = (not useCharacterLayout)
        and type(self.db.profile.expansionModuleStates) == "table"
        and self.db.profile.expansionModuleStates
        or nil
    local sharedModuleStates = sharedModuleStateBuckets and sharedModuleStateBuckets[selectedExpansion]
        or ((not useCharacterLayout and selectedExpansion == "midnight" and type(self.db.profile.modules) == "table")
            and self.db.profile.modules)
        or {}

    for charKey, charData in pairs(self.db.sv.char) do
        if type(charData) == "table" and type(charData.progress) == "table" then
            local name, realm = ParseCharacterKey(charKey)
            local lastSyncAt = charData.lastSyncAt or 0
            local stale = resetAt > 0 and lastSyncAt > 0 and lastSyncAt < resetAt
            local hidden = hiddenChars[charKey] == true
            local note = self:GetAltBoardCharacterNote(charKey)
            local savedProfessions = type(charData.professions) == "table" and charData.professions or nil
            local snapshot = {
                key = charKey,
                name = name,
                realm = realm,
                classFile = charData.classFile,
                note = note,
                isCurrent = (charKey == currentKey),
                stale = stale,
                hidden = hidden,
                lastSyncAt = lastSyncAt,
                lastResetAt = charData.lastResetAt or 0,
                modules = {},
                totalRows = 0,
                doneRows = 0,
                activeRows = 0,
            }

            local moduleStateBuckets = useCharacterLayout
                and type(charData.expansionModuleStates) == "table"
                and charData.expansionModuleStates
                or nil
            local moduleStates = useCharacterLayout
                and ((moduleStateBuckets and moduleStateBuckets[selectedExpansion])
                    or ((selectedExpansion == "midnight") and type(charData.modules) == "table" and charData.modules)
                    or {})
                or sharedModuleStates

            for _, mod in ipairs(self.modules) do
                if IsAltBoardModule(mod) and self:GetModuleExpansionKey(mod) == selectedExpansion then
                    local moduleSettings = type(moduleStates) == "table" and moduleStates[mod.key] or nil
                    local moduleEnabled = not (moduleSettings and moduleSettings.enabled == false)
                    local moduleVisible = moduleEnabled and (not mod.isVisible or mod:isVisible())
                    local modProgress = charData.progress[mod.key] or {}
                    local knowsProfession = (not mod.profSkillLine)
                        or (snapshot.isCurrent and self.playerProfessions and self.playerProfessions[mod.profSkillLine])
                        or (savedProfessions and savedProfessions[mod.profSkillLine])

                    if moduleVisible and knowsProfession then
                        local moduleEntry = {
                            key = mod.key,
                            label = CleanAccountLabel(mod.label),
                            color = mod.labelColor or "#ffffff",
                            rows = {},
                            totalRows = 0,
                            doneRows = 0,
                        }

                        for _, row in ipairs(mod.rows) do
                            local rowVisible = (not row.isVisible or row.isVisible())
                            local rowEnabled = not (moduleSettings and moduleSettings.hiddenRows and moduleSettings.hiddenRows[row.key] == false)

                            if rowVisible and rowEnabled then
                                local accountProgress = row.accountWideComplete
                                    and MR.db
                                    and MR.db.global
                                    and MR.db.global.customTaskProgress
                                    and MR.db.global.customTaskProgress[mod.key]
                                    or nil
                                local progressSource = accountProgress or modProgress
                                local value = stale and not accountProgress and 0 or tonumber(progressSource[row.key]) or 0
                                local maxValue = tonumber(row.max) or 0
                                if row.trackWeeklyEarned then
                                    value = stale and not accountProgress and 0 or tonumber(progressSource[row.key .. "_collected"]) or value
                                    maxValue = tonumber(row.weeklyCap or row.max) or maxValue
                                end
                                local complete = (row.trackWeeklyEarned or not row.noMax) and maxValue > 0 and value >= maxValue
                                local rowLabel = CleanAccountLabel(row.label)
                                local displayValue
                                local accentLabel = (not stale) and (modProgress[row.liveTierLabelKey or ""] or row.vaultLabel) or nil
                                local accentColor = (not stale) and (modProgress[row.liveTierColorKey or ""] or row.vaultColor) or nil

                                if row.countText and not stale then
                                    displayValue = row.countText
                                elseif row.trackWeeklyEarned then
                                    displayValue = string.format("%d / %d", value, maxValue)
                                elseif row.noMax then
                                    displayValue = tostring(value)
                                else
                                    displayValue = string.format("%d / %d", value, maxValue)
                                end

                                table.insert(moduleEntry.rows, {
                                    key = row.key,
                                    label = rowLabel,
                                    value = value,
                                    max = maxValue,
                                    noMax = row.trackWeeklyEarned and false or (row.noMax and true or false),
                                    currencyId = row.currencyId,
                                    noBlizzardTooltip = row.noBlizzardTooltip and true or false,
                                    trackWeeklyEarned = row.trackWeeklyEarned and true or false,
                                    wallet = tonumber(modProgress[row.key .. "_wallet"]) or 0,
                                    complete = complete,
                                    displayValue = displayValue,
                                    accentLabel = accentLabel,
                                    accentColor = accentColor,
                                })

                                moduleEntry.totalRows = moduleEntry.totalRows + 1
                                snapshot.totalRows = snapshot.totalRows + 1

                                if complete then
                                    moduleEntry.doneRows = moduleEntry.doneRows + 1
                                    snapshot.doneRows = snapshot.doneRows + 1
                                elseif value > 0 then
                                    snapshot.activeRows = snapshot.activeRows + 1
                                end
                            end
                        end

                        if moduleEntry.totalRows > 0 and (mod.resetType == "weekly" or moduleEntry.doneRows < moduleEntry.totalRows) then
                            table.insert(snapshot.modules, moduleEntry)
                        end
                    end
                end
            end

            local savedConcentration = type(charData.professionConcentration) == "table" and charData.professionConcentration or nil
            if savedConcentration then
                snapshot.concentration = {}
                for skillLineID, currencyInfo in pairs(savedConcentration) do
                    if currencyInfo and (savedProfessions == nil or savedProfessions[skillLineID]) then
                        local estimated, maxQuantity = EstimateCurrencyQuantity(currencyInfo)
                        local amountPerCycle = tonumber(currencyInfo.rechargingAmountPerCycle) or 1
                        if amountPerCycle <= 0 then
                            amountPerCycle = 1
                        end
                        table.insert(snapshot.concentration, {
                            skillLineID = skillLineID,
                            label = GetProfessionLabelBySkillLine(skillLineID),
                            currencyID = currencyInfo.currencyID,
                            quantity = tonumber(currencyInfo.quantity) or 0,
                            estimatedQuantity = estimated,
                            maxQuantity = maxQuantity,
                            rechargingCycleDurationMS = tonumber(currencyInfo.rechargingCycleDurationMS) or 0,
                            rechargingAmountPerCycle = amountPerCycle,
                            lastUpdated = tonumber(currencyInfo.lastUpdated) or 0,
                        })
                    end
                end

                table.sort(snapshot.concentration, function(a, b)
                    if a.skillLineID ~= b.skillLineID then
                        return a.skillLineID < b.skillLineID
                    end
                    return (a.label or "") < (b.label or "")
                end)
            end

            local hasConcentration = type(snapshot.concentration) == "table" and #snapshot.concentration > 0
            if (snapshot.totalRows > 0 or hasConcentration) and ((showHidden and hidden) or ((not showHidden) and (not hidden))) then
                table.insert(results, snapshot)
            end
        end
    end

    table.sort(results, function(a, b)
        if a.isCurrent ~= b.isCurrent then
            return a.isCurrent
        end
        if a.stale ~= b.stale then
            return not a.stale
        end
        if a.doneRows ~= b.doneRows then
            return a.doneRows > b.doneRows
        end
        if a.realm ~= b.realm then
            return a.realm < b.realm
        end
        return a.name < b.name
    end)

    return results
end

function MR:IsAltBoardCharacterHidden(charKey)
    if not (self and self.db and self.db.profile and charKey) then
        return false
    end

    return self.db.profile.altBoardHiddenCharacters
        and self.db.profile.altBoardHiddenCharacters[charKey] == true
        or false
end

function MR:SetAltBoardCharacterHidden(charKey, hidden)
    if not (self and self.db and self.db.profile and charKey) then
        return
    end

    if not self.db.profile.altBoardHiddenCharacters then
        self.db.profile.altBoardHiddenCharacters = {}
    end

    if hidden then
        self.db.profile.altBoardHiddenCharacters[charKey] = true
    else
        self.db.profile.altBoardHiddenCharacters[charKey] = nil
    end
end

function MR:GetAltBoardCharacterNote(charKey)
    if not (self and self.db and self.db.profile and charKey) then
        return ""
    end

    local notes = self.db.profile.altBoardCharacterNotes
    if type(notes) ~= "table" then
        return ""
    end

    local note = notes[charKey]
    return type(note) == "string" and note or ""
end

function MR:SetAltBoardCharacterNote(charKey, note)
    if not (self and self.db and self.db.profile and charKey) then
        return
    end

    if type(self.db.profile.altBoardCharacterNotes) ~= "table" then
        self.db.profile.altBoardCharacterNotes = {}
    end

    note = type(note) == "string" and note:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if #note > 80 then
        note = note:sub(1, 80)
    end

    if note == "" then
        self.db.profile.altBoardCharacterNotes[charKey] = nil
    else
        self.db.profile.altBoardCharacterNotes[charKey] = note
    end
end

