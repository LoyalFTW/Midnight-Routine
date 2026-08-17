local addonName, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local CDM_CATEGORY_ORDER = { "Animals", "Devices", "Impacts", "Instruments", "Short", "War2", "War3" }
local CDM_CATEGORY_LABELS = {
    Animals = "Animals", Devices = "Devices", Impacts = "Impacts",
    Instruments = "Instruments", Short = "Short", War2 = "Warcraft 2", War3 = "Warcraft 3",
}

local function StorageKey(modKey, rowKey)
    return tostring(modKey) .. "::" .. tostring(rowKey)
end

local function IsSharedScope()
    return MR.db and MR.db.profile and MR.db.profile.characterWindowLayout ~= true
end

local function GetChosenSoundValue(modKey, rowKey)
    local key = StorageKey(modKey, rowKey)
    if IsSharedScope() then
        local global = MR.db and MR.db.global and MR.db.global.completionSounds
        return global and global[key] or nil
    end
    local char = MR.db and MR.db.char and MR.db.char.completionSounds
    return char and char[key] or nil
end

local function SetChosenSoundValue(modKey, rowKey, value)
    local key = StorageKey(modKey, rowKey)
    if IsSharedScope() then
        if MR.db.global then
            MR.db.global.completionSounds = MR.db.global.completionSounds or {}
            MR.db.global.completionSounds[key] = value
        end
    else
        if MR.db.char then
            MR.db.char.completionSounds = MR.db.char.completionSounds or {}
            MR.db.char.completionSounds[key] = value
        end
    end
end

local function MigrateCompletionSoundsScope(toShared)
    local fromStore = toShared and MR.db.char or MR.db.global
    local fromBucket = fromStore and fromStore.completionSounds
    if type(fromBucket) ~= "table" then return end

    local toStore = toShared and MR.db.global or MR.db.char
    if not toStore then return end
    toStore.completionSounds = toStore.completionSounds or {}
    local toBucket = toStore.completionSounds

    for key, value in pairs(fromBucket) do
        if toBucket[key] == nil then
            toBucket[key] = value
        end
    end
end
ns.MigrateCompletionSoundsScope = MigrateCompletionSoundsScope

local function SpeakRowName(modKey, rowKey)
    if not (C_VoiceChat and C_VoiceChat.SpeakText and C_VoiceChat.GetTtsVoices) then return end

    local voices = C_VoiceChat.GetTtsVoices()
    local voice = voices and voices[1]
    if not (voice and voice.voiceID) then return end

    local mod = MR.moduleByKey and MR.moduleByKey[modKey]
    local row
    if mod then
        for _, r in ipairs(mod.rows) do
            if r.key == rowKey then row = r break end
        end
    end

    local text = tostring((row and (row.label or row.key)) or rowKey)
    text = text:gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", ""):gsub(":%s*$", "")
    if text == "" then return end

    local rate = (C_TTSSettings and C_TTSSettings.GetSpeechRate and C_TTSSettings.GetSpeechRate()) or 0
    local volume = (C_TTSSettings and C_TTSSettings.GetSpeechVolume and C_TTSSettings.GetSpeechVolume()) or 100
    C_VoiceChat.SpeakText(voice.voiceID, text, rate, volume, true)
end

local function PlaySoundByValue(value, modKey, rowKey)
    if value == "tts" then
        SpeakRowName(modKey, rowKey)
        return
    end
    if type(value) ~= "string" then return end
    local kind, rest = value:match("^(%a+):(.+)$")
    if kind == "lsm" then
        local lsm = ns.GetSharedMedia and ns.GetSharedMedia()
        local path = lsm and lsm:Fetch(lsm.MediaType.SOUND, rest, true)
        if path then PlaySoundFile(path, "Master") end
    elseif kind == "cdm" then
        local id = tonumber(rest)
        if id then PlaySound(id, "Master") end
    end
end

local function EnsureCooldownViewerSoundData()
    if not _G.CooldownViewerSoundData and C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, "Blizzard_CooldownViewer")
    end
    return _G.CooldownViewerSoundData
end

local function BuildCooldownViewerCategories(rootDescription, isSelected, setSelected)
    local data = EnsureCooldownViewerSoundData()
    if not (data and Enum and Enum.CooldownViewerSoundCategory) then return end

    for _, catKey in ipairs(CDM_CATEGORY_ORDER) do
        local catValue = Enum.CooldownViewerSoundCategory[catKey]
        local entries = catValue and data[catValue]
        if type(entries) == "table" and #entries > 0 then
            local sub = rootDescription:CreateButton(CDM_CATEGORY_LABELS[catKey] or catKey, function() end)
            for _, entry in ipairs(entries) do
                if entry.soundKitID and entry.text then
                    sub:CreateRadio(entry.text, isSelected, setSelected, "cdm:" .. tostring(entry.soundKitID))
                end
            end
        end
    end
end

local function BuildCustomCategory(rootDescription, isSelected, setSelected)
    if not ns.GetSharedMediaList then return end
    local names = ns.GetSharedMediaList("sound")
    if not (names and #names > 0) then return end

    local sub = rootDescription:CreateButton(L["CompletionSound_Custom"] or "Custom", function() end)
    local seen = {}
    for _, name in ipairs(names) do
        if type(name) == "string" and name ~= "" and not seen[name] then
            seen[name] = true
            sub:CreateRadio(name, isSelected, setSelected, "lsm:" .. name)
        end
    end
end

local function OpenCompletionSoundMenu(modKey, rowKey, anchor)
    if not (MenuUtil and MenuUtil.CreateContextMenu) then
        print(L["CompletionSound_MenuUnavailable"] or "|cff2ae7c6MidnightRoutine:|r Sound menu unavailable on this client.")
        return
    end
    if type(modKey) ~= "string" or type(rowKey) ~= "string" then
        return
    end

    local function IsSelected(value)
        local current = GetChosenSoundValue(modKey, rowKey)
        return current == value
    end

    local function SetSelected(value)
        SetChosenSoundValue(modKey, rowKey, value)
        PlaySoundByValue(value, modKey, rowKey)
        if MR.RequestUIRefresh then MR:RequestUIRefresh(0.05) end
    end

    local ok, err = pcall(function()
        MenuUtil.CreateContextMenu(anchor, function(_, rootDescription)
            rootDescription:SetTag("MIDNIGHTROUTINE_COMPLETION_SOUND_PICKER")
            rootDescription:CreateTitle(L["CompletionSound_PickerTitle"] or "Completion Sound")
            rootDescription:CreateRadio(L["CompletionSound_None"] or "Off (no sound)", IsSelected, SetSelected, nil)
            BuildCooldownViewerCategories(rootDescription, IsSelected, SetSelected)
            rootDescription:CreateRadio(L["CompletionSound_TextToSpeech"] or "Text to Speech", IsSelected, SetSelected, "tts")
            BuildCustomCategory(rootDescription, IsSelected, SetSelected)
        end)
    end)
    if not ok then
        print(string.format(L["CompletionSound_MenuError"] or "|cff2ae7c6MidnightRoutine:|r Sound menu failed to open (%s).", tostring(err)))
    end
end

ns.OpenCompletionSoundMenu = OpenCompletionSoundMenu
ns.GetCompletionSoundValue = GetChosenSoundValue

local lastKnownDone = {}

local function CollectConfiguredRowKeys(out, source)
    if type(source) ~= "table" then return end
    for key in pairs(source) do
        out[key] = true
    end
end

local function CheckCompletionSounds()
    local configured = {}
    CollectConfiguredRowKeys(configured, MR.db and MR.db.global and MR.db.global.completionSounds)
    CollectConfiguredRowKeys(configured, MR.db and MR.db.char and MR.db.char.completionSounds)
    if not next(configured) then
        return
    end

    for key in pairs(configured) do
        local modKey, rowKey = key:match("^(.-)::(.+)$")
        if modKey and rowKey then
            local soundValue = GetChosenSoundValue(modKey, rowKey)
            if soundValue then
                local mod = MR.moduleByKey and MR.moduleByKey[modKey]
                local row
                if mod then
                    for _, r in ipairs(mod.rows) do
                        if r.key == rowKey then row = r break end
                    end
                end
                if row then
                    local done = (MR:GetProgress(modKey, rowKey) or 0) >= (row.max or 1)
                    if done and lastKnownDone[key] == false then
                        PlaySoundByValue(soundValue, modKey, rowKey)
                    end
                    lastKnownDone[key] = done
                end
            else
                lastKnownDone[key] = nil
            end
        end
    end
end

C_Timer.NewTicker(2, CheckCompletionSounds)
