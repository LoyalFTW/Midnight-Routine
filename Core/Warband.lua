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

local function HasAnyProfessionRecord(source)
    if type(source) ~= "table" then
        return false
    end

    for _, learned in pairs(source) do
        if learned then
            return true
        end
    end

    return false
end

local function GetConcentrationOrderIndex(order)
    local index = {}
    if type(order) == "table" then
        for pos, skillLineID in ipairs(order) do
            index[tonumber(skillLineID) or skillLineID] = pos
        end
    end
    return index
end

local function GetCharacterOrderIndex(order)
    local index = {}
    if type(order) == "table" then
        for pos, charKey in ipairs(order) do
            if type(charKey) == "string" and charKey ~= "" then
                index[charKey] = pos
            end
        end
    end
    return index
end

function MR:GetAltBoardCharacterOrder()
    if not (self and self.db and self.db.profile) then
        return {}
    end

    self.db.profile.altBoardCharacterOrder = self.db.profile.altBoardCharacterOrder or {}
    return self.db.profile.altBoardCharacterOrder
end

function MR:SetAltBoardCharacterOrder(order)
    if not (self and self.db and self.db.profile) then
        return
    end

    local cleaned, seen = {}, {}
    if type(order) == "table" then
        for _, charKey in ipairs(order) do
            if type(charKey) == "string" and charKey ~= "" and not seen[charKey] then
                cleaned[#cleaned + 1] = charKey
                seen[charKey] = true
            end
        end
    end

    self.db.profile.altBoardCharacterOrder = cleaned
end

function MR:MoveAltBoardCharacter(charKey, direction)
    direction = tonumber(direction) or 0
    if type(charKey) ~= "string" or charKey == "" or direction == 0 then
        return false
    end

    local order = {}
    local seen = {}
    for _, existingKey in ipairs(self:GetAltBoardCharacterOrder()) do
        if type(existingKey) == "string" and existingKey ~= "" and not seen[existingKey] then
            order[#order + 1] = existingKey
            seen[existingKey] = true
        end
    end

    if self.db and self.db.sv and type(self.db.sv.char) == "table" then
        local currentKey = self:GetCurrentCharacterKey()
        local hiddenChars = (self.db and self.db.profile and self.db.profile.altBoardHiddenCharacters) or {}
        local discovered = {}
        for existingKey in pairs(self.db.sv.char) do
            if type(existingKey) == "string" and existingKey ~= "" and not seen[existingKey] then
                local name, realm = ParseCharacterKey(existingKey)
                discovered[#discovered + 1] = {
                    key = existingKey,
                    name = name,
                    realm = realm,
                    isCurrent = existingKey == currentKey,
                    hidden = hiddenChars[existingKey] == true,
                }
                seen[existingKey] = true
            end
        end
        table.sort(discovered, function(a, b)
            if a.hidden ~= b.hidden then
                return not a.hidden
            end
            if a.isCurrent ~= b.isCurrent then
                return a.isCurrent
            end
            if a.realm ~= b.realm then
                return a.realm < b.realm
            end
            return a.name < b.name
        end)
        for _, entry in ipairs(discovered) do
            order[#order + 1] = entry.key
        end
    end

    if not seen[charKey] then
        order[#order + 1] = charKey
        seen[charKey] = true
    end

    local pos
    for index, existingKey in ipairs(order) do
        if existingKey == charKey then
            pos = index
            break
        end
    end

    if not pos then
        return false
    end

    local target = math.max(1, math.min(#order, pos + direction))
    if target == pos then
        return false
    end

    local moved = table.remove(order, pos)
    table.insert(order, target, moved)
    self:SetAltBoardCharacterOrder(order)

    if self.RefreshWarbandBoard then
        self:RefreshWarbandBoard()
    end
    if self.RefreshMainAltPicker then
        self:RefreshMainAltPicker()
    end
    if self.RefreshConcentrationTracker then
        self:RefreshConcentrationTracker()
    end
    return true
end

function MR:SetAltBoardCharacterPosition(charKey, targetCharKey, afterTarget)
    if type(charKey) ~= "string" or charKey == "" or type(targetCharKey) ~= "string" or targetCharKey == "" or charKey == targetCharKey then
        return false
    end

    local order = {}
    local seen = {}
    for _, existingKey in ipairs(self:GetAltBoardCharacterOrder()) do
        if type(existingKey) == "string" and existingKey ~= "" and not seen[existingKey] then
            order[#order + 1] = existingKey
            seen[existingKey] = true
        end
    end

    if self.db and self.db.sv and type(self.db.sv.char) == "table" then
        local currentKey = self:GetCurrentCharacterKey()
        local hiddenChars = (self.db and self.db.profile and self.db.profile.altBoardHiddenCharacters) or {}
        local discovered = {}
        for existingKey in pairs(self.db.sv.char) do
            if type(existingKey) == "string" and existingKey ~= "" and not seen[existingKey] then
                local name, realm = ParseCharacterKey(existingKey)
                discovered[#discovered + 1] = {
                    key = existingKey,
                    name = name,
                    realm = realm,
                    isCurrent = existingKey == currentKey,
                    hidden = hiddenChars[existingKey] == true,
                }
                seen[existingKey] = true
            end
        end
        table.sort(discovered, function(a, b)
            if a.hidden ~= b.hidden then
                return not a.hidden
            end
            if a.isCurrent ~= b.isCurrent then
                return a.isCurrent
            end
            if a.realm ~= b.realm then
                return a.realm < b.realm
            end
            return a.name < b.name
        end)
        for _, entry in ipairs(discovered) do
            order[#order + 1] = entry.key
        end
    end

    if not seen[charKey] then
        order[#order + 1] = charKey
        seen[charKey] = true
    end
    if not seen[targetCharKey] then
        order[#order + 1] = targetCharKey
        seen[targetCharKey] = true
    end

    local fromIndex, targetIndex
    for index, existingKey in ipairs(order) do
        if existingKey == charKey then
            fromIndex = index
        elseif existingKey == targetCharKey then
            targetIndex = index
        end
    end
    if not fromIndex or not targetIndex or fromIndex == targetIndex then
        return false
    end

    local insertIndex = targetIndex
    if fromIndex < targetIndex then
        insertIndex = insertIndex - 1
    end
    if afterTarget then
        insertIndex = insertIndex + 1
    end
    insertIndex = math.max(1, math.min(#order, insertIndex))
    if insertIndex == fromIndex then
        return false
    end

    local moved = table.remove(order, fromIndex)
    table.insert(order, insertIndex, moved)
    self:SetAltBoardCharacterOrder(order)

    if self.RefreshWarbandBoard then
        self:RefreshWarbandBoard()
    end
    if self.RefreshMainAltPicker then
        self:RefreshMainAltPicker()
    end
    if self.RefreshConcentrationTracker then
        self:RefreshConcentrationTracker()
    end
    return true
end

function MR:GetAltBoardConcentrationOrder()
    if not (self and self.db and self.db.profile) then
        return {}
    end

    self.db.profile.altBoardConcentrationOrder = self.db.profile.altBoardConcentrationOrder or {}
    return self.db.profile.altBoardConcentrationOrder
end

function MR:SetAltBoardConcentrationOrder(order)
    if not (self and self.db and self.db.profile) then
        return
    end

    local cleaned, seen = {}, {}
    if type(order) == "table" then
        for _, skillLineID in ipairs(order) do
            skillLineID = tonumber(skillLineID)
            if skillLineID and not seen[skillLineID] then
                cleaned[#cleaned + 1] = skillLineID
                seen[skillLineID] = true
            end
        end
    end

    self.db.profile.altBoardConcentrationOrder = cleaned
end

function MR:MoveAltBoardConcentrationProfession(skillLineID, direction)
    skillLineID = tonumber(skillLineID)
    direction = tonumber(direction) or 0
    if not skillLineID or direction == 0 then
        return false
    end

    local order = {}
    local seen = {}
    for _, existingID in ipairs(self:GetAltBoardConcentrationOrder()) do
        existingID = tonumber(existingID)
        if existingID and not seen[existingID] then
            order[#order + 1] = existingID
            seen[existingID] = true
        end
    end

    local discovered = {}
    if self.db and self.db.sv and type(self.db.sv.char) == "table" then
        for _, charData in pairs(self.db.sv.char) do
            local concentration = type(charData) == "table" and charData.professionConcentration or nil
            if type(concentration) == "table" then
                for existingID in pairs(concentration) do
                    existingID = tonumber(existingID)
                    if existingID and not seen[existingID] then
                        discovered[#discovered + 1] = existingID
                        seen[existingID] = true
                    end
                end
            end
        end
    end
    table.sort(discovered)
    for _, existingID in ipairs(discovered) do
        order[#order + 1] = existingID
    end

    if not seen[skillLineID] then
        order[#order + 1] = skillLineID
        seen[skillLineID] = true
    end

    local pos
    for index, existingID in ipairs(order) do
        if existingID == skillLineID then
            pos = index
            break
        end
    end

    if not pos then
        return false
    end

    local target = math.max(1, math.min(#order, pos + direction))
    if target == pos then
        return false
    end

    local moved = table.remove(order, pos)
    table.insert(order, target, moved)
    self:SetAltBoardConcentrationOrder(order)

    if self.RefreshWarbandBoard then
        self:RefreshWarbandBoard()
    end
    if self.RefreshConcentrationTracker then
        self:RefreshConcentrationTracker()
    end
    return true
end

function MR:SetAltBoardConcentrationProfessionPosition(skillLineID, targetSkillLineID, afterTarget)
    skillLineID = tonumber(skillLineID)
    targetSkillLineID = tonumber(targetSkillLineID)
    if not skillLineID or not targetSkillLineID or skillLineID == targetSkillLineID then
        return false
    end

    local order = {}
    local seen = {}
    for _, existingID in ipairs(self:GetAltBoardConcentrationOrder()) do
        existingID = tonumber(existingID)
        if existingID and not seen[existingID] then
            order[#order + 1] = existingID
            seen[existingID] = true
        end
    end

    local discovered = {}
    if self.db and self.db.sv and type(self.db.sv.char) == "table" then
        for _, charData in pairs(self.db.sv.char) do
            local concentration = type(charData) == "table" and charData.professionConcentration or nil
            if type(concentration) == "table" then
                for existingID in pairs(concentration) do
                    existingID = tonumber(existingID)
                    if existingID and not seen[existingID] then
                        discovered[#discovered + 1] = existingID
                        seen[existingID] = true
                    end
                end
            end
        end
    end
    table.sort(discovered)
    for _, existingID in ipairs(discovered) do
        order[#order + 1] = existingID
    end

    if not seen[skillLineID] then
        order[#order + 1] = skillLineID
        seen[skillLineID] = true
    end
    if not seen[targetSkillLineID] then
        order[#order + 1] = targetSkillLineID
        seen[targetSkillLineID] = true
    end

    local fromIndex, targetIndex
    for index, existingID in ipairs(order) do
        if existingID == skillLineID then
            fromIndex = index
        elseif existingID == targetSkillLineID then
            targetIndex = index
        end
    end
    if not fromIndex or not targetIndex or fromIndex == targetIndex then
        return false
    end

    local insertIndex = targetIndex
    if fromIndex < targetIndex then
        insertIndex = insertIndex - 1
    end
    if afterTarget then
        insertIndex = insertIndex + 1
    end
    insertIndex = math.max(1, math.min(#order, insertIndex))
    if insertIndex == fromIndex then
        return false
    end

    local moved = table.remove(order, fromIndex)
    table.insert(order, insertIndex, moved)

    self:SetAltBoardConcentrationOrder(order)

    if self.RefreshWarbandBoard then
        self:RefreshWarbandBoard()
    end
    if self.RefreshConcentrationTracker then
        self:RefreshConcentrationTracker()
    end
    return true
end


function MR:GetCurrentCharacterKey()
    if self.db and self.db.GetNativeHandles then
        local handles = self.db:GetNativeHandles()
        if handles and handles.charKey then
            return handles.charKey
        end
    end

    local name, realm = UnitFullName and UnitFullName("player")
    if name and realm and realm ~= "" then
        return string.format("%s - %s", name, realm)
    end

    return UnitName and UnitName("player") or "Unknown"
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

    self._moduleStatsCache = nil
    if self.RefreshUI then
        self:RefreshUI()
    end
    if self.RefreshMainAltPicker then
        self:RefreshMainAltPicker()
    end
    if self.RequestConfigRepopulate then
        self:RequestConfigRepopulate(nil, 0.04)
    end
    if self.RebuildGatheringLocationsFrame then
        self:RebuildGatheringLocationsFrame()
    end
    if self.RepopulateGatheringConfig then
        self:RepopulateGatheringConfig()
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
            local savedConcentration = type(charData.professionConcentration) == "table" and charData.professionConcentration or nil
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
                    local professionModuleStates = type(charData.professionModuleStates) == "table" and charData.professionModuleStates or nil
                    local professionSettings = mod.profSkillLine and professionModuleStates and professionModuleStates[mod.key] or nil
                    local effectiveSettings = professionSettings or moduleSettings
                    local moduleEnabled = not (effectiveSettings and effectiveSettings.enabled == false)
                    if mod.profSkillLine then
                        moduleEnabled = not (effectiveSettings and effectiveSettings.enabled == false and effectiveSettings.professionDisabled == true)
                    end
                    local moduleVisible = moduleEnabled and (not mod.isVisible or mod:isVisible())
                    local modProgress = charData.progress[mod.key] or {}
                    local knowsProfession = (not mod.profSkillLine)
                        or (snapshot.isCurrent and self.HasProfessionForModule and self:HasProfessionForModule(mod.profSkillLine))
                        or (savedProfessions and savedProfessions[mod.profSkillLine])
                        or ((not charData.professionsScanned) and (not HasAnyProfessionRecord(savedProfessions)) and savedConcentration and savedConcentration[mod.profSkillLine] ~= nil)

                    if moduleVisible and knowsProfession then
                        local moduleEntry = {
                            key = mod.key,
                            label = CleanAccountLabel(mod.label),
                            color = mod.labelColor or "#ffffff",
                            rows = {},
                            totalRows = 0,
                            doneRows = 0,
                        }

                        local orderedRows = self.GetOrderedRows and self:GetOrderedRows(mod) or mod.rows
                        for _, row in ipairs(orderedRows) do
                            local rowVisible = self.IsRowVisibleForCharacter and self:IsRowVisibleForCharacter(mod, row, charData) or (not row.isVisible or row.isVisible())
                            local rowEnabled = not (effectiveSettings and effectiveSettings.hiddenRows and effectiveSettings.hiddenRows[row.key] == false)

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
                                local accentLabel = (not stale) and (modProgress[row.liveTierLabelKey or ""] or (snapshot.isCurrent and row.vaultLabel)) or nil
                                local accentColor = (not stale) and (modProgress[row.liveTierColorKey or ""] or (snapshot.isCurrent and row.vaultColor)) or nil

                                if row.countText and not stale and snapshot.isCurrent then
                                    displayValue = row.countText
                                elseif complete and row.completedNameKey and not stale and modProgress[row.completedNameKey] then
                                    displayValue = modProgress[row.completedNameKey]
                                elseif (not complete) and row.activeNameKey and not stale and modProgress[row.activeNameKey] then
                                    displayValue = modProgress[row.activeNameKey]
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

                local concentrationOrderIndex = GetConcentrationOrderIndex(self:GetAltBoardConcentrationOrder())
                table.sort(snapshot.concentration, function(a, b)
                    local aOrder = concentrationOrderIndex[a.skillLineID] or math.huge
                    local bOrder = concentrationOrderIndex[b.skillLineID] or math.huge
                    if aOrder ~= bOrder then
                        return aOrder < bOrder
                    end
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

    local characterOrderIndex = GetCharacterOrderIndex(self:GetAltBoardCharacterOrder())
    table.sort(results, function(a, b)
        local aOrder = characterOrderIndex[a.key] or math.huge
        local bOrder = characterOrderIndex[b.key] or math.huge
        if aOrder ~= bOrder then
            return aOrder < bOrder
        end
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

