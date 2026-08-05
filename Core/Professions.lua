local _, ns = ...
local MR = ns.MR

local PARENT_TO_MIDNIGHT = {
    [171]=2906, [164]=2907, [333]=2909, [202]=2910, [182]=2912,
    [773]=2913, [755]=2914, [165]=2915, [186]=2916, [393]=2917, [197]=2918,
}

local PROFESSION_TIER_LEARN_SPELLS = {
    [2906] = 471003, [2871] = 423321, [2823] = 366261, 
    [2907] = 471004, [2872] = 423332, [2822] = 365677, 
    [2909] = 471006, [2874] = 423334, [2825] = 366255, 
    [2910] = 471007, [2875] = 423335, [2827] = 366254, 
    [2912] = 471009, [2877] = 441327, [2832] = 366242, 
    [2913] = 471010, [2878] = 423338, [2828] = 366251, 
    [2914] = 471011, [2879] = 423339, [2829] = 366250, 
    [2915] = 471012, [2880] = 423340, [2830] = 366249,
    [2916] = 471013, [2881] = 423341, [2833] = 366264, 
    [2917] = 471014, [2882] = 423342, [2834] = 366263, 
    [2918] = 471015, [2883] = 423343, [2831] = 366258, 
}

local PROFESSION_CONCENTRATION_CURRENCIES = {
    [2906] = 3161,
    [2907] = 3162,
    [2909] = 3163,
    [2910] = 3164,
    [2913] = 3165,
    [2914] = 3166,
    [2915] = 3167,
    [2918] = 3168,
}

MR.playerProfessions = MR.playerProfessions or {}

local function CopyProfessionMap(source)
    local copy = {}
    if type(source) ~= "table" then
        return copy
    end

    for skillLineID, learned in pairs(source) do
        if learned then
            copy[skillLineID] = true
        end
    end

    return copy
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

local function ProfessionMapsEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end

    for skillLineID, learned in pairs(a) do
        if learned and not b[skillLineID] then
            return false
        end
    end

    for skillLineID, learned in pairs(b) do
        if learned and not a[skillLineID] then
            return false
        end
    end

    return true
end

local function CharacterDataHasProfession(charData, skillLineID)
    if type(charData) ~= "table" then
        return false
    end

    local professions = charData.professions
    if type(professions) == "table" and professions[skillLineID] then
        return true
    end
    if charData.professionsScanned or HasAnyProfessionRecord(professions) then
        return false
    end

    local concentration = charData.professionConcentration
    return type(concentration) == "table" and concentration[skillLineID] ~= nil
end

function MR:HasProfessionForModule(skillLineID, charData)
    if not skillLineID then
        return true
    end

    if charData ~= nil then
        if self.db and charData == self.db.char and self.playerProfessions and self.playerProfessions[skillLineID] then
            return true
        end
        return CharacterDataHasProfession(charData, skillLineID)
    end

    if self.playerProfessions and self.playerProfessions[skillLineID] then
        return true
    end

    if CharacterDataHasProfession(self.db and self.db.char, skillLineID) then
        return true
    end

    return false
end

local function ConcentrationDataEqual(a, b)
    if a == b then
        return true
    end
    if type(a) ~= "table" or type(b) ~= "table" then
        return false
    end

    for skillLineID, infoA in pairs(a) do
        local infoB = b[skillLineID]
        if type(infoA) ~= "table" or type(infoB) ~= "table" then
            return false
        end
        if (infoA.currencyID or 0) ~= (infoB.currencyID or 0)
            or (infoA.quantity or 0) ~= (infoB.quantity or 0)
            or (infoA.maxQuantity or 0) ~= (infoB.maxQuantity or 0)
            or (infoA.rechargingCycleDurationMS or 0) ~= (infoB.rechargingCycleDurationMS or 0)
            or (infoA.rechargingAmountPerCycle or 0) ~= (infoB.rechargingAmountPerCycle or 0)
            or (infoA.lastUpdated or 0) ~= (infoB.lastUpdated or 0) then
            return false
        end
    end

    for skillLineID in pairs(b) do
        if a[skillLineID] == nil then
            return false
        end
    end

    return true
end

function MR:RefreshPlayerProfessions()
    if self:ShouldDeferForCombat("playerProfessions") then
        return
    end

    local previousProfessions = CopyProfessionMap(self.playerProfessions)
    wipe(self.playerProfessions)
    local found = false
    local scanned = false

    if C_SpellBook and C_SpellBook.IsSpellKnown then
        scanned = true
        for tierSkillLine, learnSpellID in pairs(PROFESSION_TIER_LEARN_SPELLS) do
            if C_SpellBook.IsSpellKnown(learnSpellID) then
                self.playerProfessions[tierSkillLine] = true
                found = true
            end
        end
    end

    if C_TradeSkillUI and C_TradeSkillUI.GetAllProfessionTradeSkillLines then
        local lines = C_TradeSkillUI.GetAllProfessionTradeSkillLines()
        if lines then
            scanned = true
            for _, skillLineID in ipairs(lines) do
                local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID and
                             C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
                if info and (info.skillLevel or 0) > 0 then
                    self.playerProfessions[skillLineID] = true
                    found = true
                    if info.parentProfessionID then
                        local mid = PARENT_TO_MIDNIGHT[info.parentProfessionID]
                        if mid then
                            self.playerProfessions[mid] = true
                            found = true
                        end
                    end
                end
            end
        end
    end
    if GetProfessions and GetProfessionInfo then
        local prof1, prof2, archaeology, fishing, cooking = GetProfessions()
        scanned = true
        for _, idx in ipairs({ prof1, prof2, archaeology, fishing, cooking }) do
            if idx then
                local _, _, _, _, _, _, parentSkillLine = GetProfessionInfo(idx)
                if parentSkillLine then
                    local mid = PARENT_TO_MIDNIGHT[parentSkillLine]
                    if mid then
                        self.playerProfessions[mid] = true
                        found = true
                    end
                end
            end
        end
    end

    if self.db and self.db.char then
        self.db.char.knownProfessionLines = nil
        if scanned then
            if not ProfessionMapsEqual(self.db.char.professions, self.playerProfessions) then
                self.db.char.professions = CopyProfessionMap(self.playerProfessions)
            end
            self.db.char.professionsScanned = true
            if not found then
                self.db.char.professionConcentration = {}
            end
        elseif HasAnyProfessionRecord(self.db.char.professions) then
            for skillLineID, learned in pairs(self.db.char.professions) do
                if learned then
                    self.playerProfessions[skillLineID] = true
                end
            end
        end
    end

    local changed = not ProfessionMapsEqual(previousProfessions, self.playerProfessions)

    if changed and self.RefreshProfessionKnowledgeSurfaces then
        self:RequestProfessionKnowledgeSurfaceRefresh()
    end
    if changed and self.RequestConfigRefresh then
        self:RequestConfigRefresh()
    elseif changed and self.RefreshUI then
        self:RefreshUI()
    end

    return changed, found, scanned
end

function MR:RefreshProfessionConcentration()
    if not (self and self.db and self.db.char) then
        return false
    end

    if self:ShouldDeferForCombat("professionConcentration") then
        return false
    end

    local previous = self.db.char.professionConcentration
    local concentration = {}
    for skillLineID, currencyID in pairs(PROFESSION_CONCENTRATION_CURRENCIES) do
        if self.playerProfessions and self.playerProfessions[skillLineID] then
            local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID)
            if info then
                local quantity = info.quantity or 0
                local maxQuantity = info.maxQuantity or 0
                local cycleMS = info.rechargingCycleDurationMS or 0
                local amountPerCycle = info.rechargingAmountPerCycle or 1
                if amountPerCycle <= 0 then
                    amountPerCycle = 1
                end
                local lastUpdated = GetServerTime()
                local previousInfo = type(previous) == "table" and previous[skillLineID] or nil

                if type(previousInfo) == "table" then
                    local previousQuantity = tonumber(previousInfo.quantity) or 0
                    local previousMax = tonumber(previousInfo.maxQuantity) or 0
                    local previousUpdated = tonumber(previousInfo.lastUpdated) or 0
                    local previousCycleMS = tonumber(previousInfo.rechargingCycleDurationMS) or cycleMS
                    local previousAmountPerCycle = tonumber(previousInfo.rechargingAmountPerCycle) or amountPerCycle
                    if previousCycleMS <= 0 then
                        previousCycleMS = cycleMS
                    end
                    if previousAmountPerCycle <= 0 then
                        previousAmountPerCycle = amountPerCycle
                    end

                    if quantity == previousQuantity
                        and maxQuantity == previousMax
                        and previousUpdated > 0
                        and cycleMS == previousCycleMS
                        and amountPerCycle == previousAmountPerCycle then
                        lastUpdated = previousUpdated
                    end
                end

                concentration[skillLineID] = {
                    currencyID = currencyID,
                    quantity = quantity,
                    maxQuantity = maxQuantity,
                    rechargingCycleDurationMS = cycleMS,
                    rechargingAmountPerCycle = amountPerCycle,
                    name = info.name,
                    iconFileID = info.iconFileID,
                    quality = info.quality or 0,
                    lastUpdated = lastUpdated,
                }
            end
        end
    end

    self.db.char.professionConcentration = concentration
    return not ConcentrationDataEqual(previous, concentration)
end
