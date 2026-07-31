local _, ns = ...
local MR = ns.MR

local registeredCampaigns = {}
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")
local retryAttempts = 0
local retryScheduled = false

local TryRegisterCampaigns

local function ScheduleCampaignRegister(delay)
    if retryScheduled or not C_Timer then
        return
    end
    retryScheduled = true
    C_Timer.After(delay or 1, function()
        retryScheduled = false
        if TryRegisterCampaigns then
            TryRegisterCampaigns()
        end
    end)
end

local function GetChapterPosition(chapterIds, chapterId)
    for i, cid in ipairs(chapterIds) do
        if cid == chapterId then return i end
    end
end

local function IsChapterDone(campaignId, chapterId, chapterIds)
    local currentChapterId = C_CampaignInfo.GetCurrentChapterID and
                             C_CampaignInfo.GetCurrentChapterID(campaignId)
    if not currentChapterId then return false end
    local thisPos    = GetChapterPosition(chapterIds, chapterId)
    local currentPos = GetChapterPosition(chapterIds, currentChapterId)
    if not thisPos or not currentPos then return false end
    return thisPos < currentPos
end

local function IsCampaignFullyComplete(campaignId, chapterIds)
    for _, chapterId in ipairs(chapterIds) do
        if not IsChapterDone(campaignId, chapterId, chapterIds) then return false end
    end
    return true
end

local function AddCampaignID(ids, seen, campaignId)
    campaignId = tonumber(campaignId)
    if campaignId and not seen[campaignId] then
        ids[#ids + 1] = campaignId
        seen[campaignId] = true
    end
end

local function CollectCampaignIDs()
    local ids, seen = {}, {}
    if not C_CampaignInfo then
        return ids
    end

    local function AddFromList(list)
        if type(list) ~= "table" then
            return
        end
        for _, value in ipairs(list) do
            if type(value) == "table" then
                AddCampaignID(ids, seen, value.campaignID or value.campaignId or value.id)
            else
                AddCampaignID(ids, seen, value)
            end
        end
    end

    if C_CampaignInfo.GetAvailableCampaigns then
        local ok, list = pcall(C_CampaignInfo.GetAvailableCampaigns)
        if ok then
            AddFromList(list)
        end
    end
    if C_CampaignInfo.GetCampaignIDs then
        local ok, list = pcall(C_CampaignInfo.GetCampaignIDs)
        if ok then
            AddFromList(list)
        end
    end
    if C_CampaignInfo.GetCurrentCampaignID then
        local ok, campaignId = pcall(C_CampaignInfo.GetCurrentCampaignID)
        if ok then
            AddCampaignID(ids, seen, campaignId)
        end
    end
    if C_CampaignInfo.GetCurrentCampaignInfo then
        local ok, info = pcall(C_CampaignInfo.GetCurrentCampaignInfo)
        if ok and type(info) == "table" then
            AddCampaignID(ids, seen, info.campaignID or info.campaignId or info.id)
        end
    end

    return ids
end

local function ScanCampaign(mod)
    if not C_CampaignInfo then return end
    local db = MR.db.char.progress
    if not db[mod.key] then db[mod.key] = {} end
    local dirty = false
    for _, chapterId in ipairs(mod._chapterIds) do
        local key = "ch_" .. chapterId
        local value = IsChapterDone(mod._campaignId, chapterId, mod._chapterIds) and 1 or 0
        if db[mod.key][key] ~= value then
            db[mod.key][key] = value
            dirty = true
        end
    end
    return dirty
end

local function AreStoryCampaignsEnabled()
    local charDB = MR.db and MR.db.char
    if not charDB then
        return true
    end
    local savedPreference = MR.GetStoryCampaignsEnabledPreference and MR:GetStoryCampaignsEnabledPreference()
    if savedPreference ~= nil then
        return savedPreference ~= false
    end

    local storage = MR.GetActiveModuleStorage and MR:GetActiveModuleStorage() or charDB.modules
    local sawDisabled = false
    for key, state in pairs(storage or {}) do
        if type(key) == "string" and key:match("^story_campaign_") and type(state) == "table" then
            if state.enabled == true then
                if MR.SetStoryCampaignsEnabledPreference then
                    MR:SetStoryCampaignsEnabledPreference(true)
                end
                return true
            elseif state.enabled == false then
                sawDisabled = true
            end
        end
    end

    if sawDisabled then
        if MR.SetStoryCampaignsEnabledPreference then
            MR:SetStoryCampaignsEnabledPreference(false)
        end
        return false
    end
    return true
end

TryRegisterCampaigns = function()
    if not C_CampaignInfo then return end
    local configFrame = MR.GetConfigFrame and MR:GetConfigFrame() or nil
    local configVisible = configFrame and configFrame.IsShown and configFrame:IsShown()
    local trackingVisible = MR.HasVisibleMainTrackingSurface and MR:HasVisibleMainTrackingSurface()
    if not trackingVisible and not configVisible then
        MR._storyCampaignRegistrationDirty = true
        if MR.MarkBackgroundDataDirty then MR:MarkBackgroundDataDirty() end
        return
    end
    if not (MR.db and MR.db.char and MR.db.char.progress) then
        ScheduleCampaignRegister(1)
        return
    end
    local ids = CollectCampaignIDs()
    if not ids or #ids == 0 then
        if retryAttempts < 6 then
            retryAttempts = retryAttempts + 1
            ScheduleCampaignRegister(math.min(12, 1 + (retryAttempts * 2)))
        end
        return
    end
    local storyCampaignsEnabled = AreStoryCampaignsEnabled()
    local didRegister = false
    local registeredAny = false
    for _, campaignId in ipairs(ids) do
        if registeredCampaigns[campaignId] then
            local mod = registeredCampaigns[campaignId]
            if MR:IsModuleEnabled(mod.key) and ScanCampaign(mod) then
                didRegister = true
            end
        else
            local info = C_CampaignInfo.GetCampaignInfo and C_CampaignInfo.GetCampaignInfo(campaignId)
            local chapterIds = C_CampaignInfo.GetChapterIDs and C_CampaignInfo.GetChapterIDs(campaignId)
                or (C_CampaignInfo.GetCampaignChapterIDs and C_CampaignInfo.GetCampaignChapterIDs(campaignId))
            if chapterIds and #chapterIds > 0 then
                local name = (info and info.name and info.name ~= "") and info.name or (L["Story_CampaignPrefix"] .. campaignId)
                local mapId = info and info.uiMapID
                local mapInfo = mapId and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapId)
                local zoneName = mapInfo and mapInfo.name
                local label = zoneName and (L["Story_StoryPrefix"] .. zoneName .. " - " .. name) or (L["Story_StoryPrefix"] .. name)
                local rows = {}
                for _, chapterId in ipairs(chapterIds) do
                    local ch = C_CampaignInfo.GetCampaignChapterInfo and C_CampaignInfo.GetCampaignChapterInfo(chapterId)
                    local chapterName = (ch and ch.name and ch.name ~= "") and ch.name or (L["Story_ChapterPrefix"] .. chapterId)
                    table.insert(rows, {
                        key = "ch_" .. chapterId,
                        label = "|cffffff88" .. chapterName .. ":|r",
                        max = 1,
                    })
                end
                local mod = {
                    key = "story_campaign_" .. campaignId,
                    label = label,
                    labelColor = "#ffff99",
                    configGroup = "story",
                    defaultEnabled = storyCampaignsEnabled,
                    resetType = "never",
                    defaultOpen = true,
                    skipRegisterScan = true,
                    scanReturnsChanged = true,
                    rows = rows,
                    _campaignId = campaignId,
                    _chapterIds = chapterIds,
                    onScan = function(self) return ScanCampaign(self) end,
                    isVisible = function(self)
                        return not IsCampaignFullyComplete(self._campaignId, self._chapterIds)
                    end,
                }
                MR:RegisterModule(mod)
                registeredCampaigns[campaignId] = mod
                registeredAny = true
                if MR:IsModuleEnabled(mod.key) and ScanCampaign(mod) then
                    didRegister = true
                end
            end
        end
    end
    if didRegister then
        if MR.RequestUIRefresh then
            MR:RequestUIRefresh(0.05)
        elseif MR.RefreshUI then
            MR:RefreshUI()
        end
    end
    if registeredAny and MR.RequestConfigRepopulate then
        MR:RequestConfigRepopulate(nil, 0.05)
    end
end

function MR:RefreshStoryCampaignRegistration()
    MR._storyCampaignRegistrationDirty = nil
    TryRegisterCampaigns()
end

if CreateFrame then
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
    eventFrame:SetScript("OnEvent", function(_, event)
        local configFrame = MR.GetConfigFrame and MR:GetConfigFrame() or nil
        local configVisible = configFrame and configFrame.IsShown and configFrame:IsShown()
        local trackingVisible = MR.HasVisibleMainTrackingSurface and MR:HasVisibleMainTrackingSurface()
        if not trackingVisible and not configVisible then
            MR._storyCampaignRegistrationDirty = true
            if MR.MarkBackgroundDataDirty then MR:MarkBackgroundDataDirty() end
            return
        end
        if event == "PLAYER_LOGIN" then
            retryAttempts = 0
            ScheduleCampaignRegister(1)
        elseif event == "PLAYER_ENTERING_WORLD" then
            ScheduleCampaignRegister(1)
        elseif event == "QUEST_LOG_UPDATE" then
            ScheduleCampaignRegister(0.5)
        end
    end)
end
