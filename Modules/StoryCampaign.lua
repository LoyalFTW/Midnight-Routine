local registeredCampaigns = {}

local SKIP_STATES = { [3] = true }

local function GetChapterPosition(chapterIds, chapterId)
    for i, cid in ipairs(chapterIds) do
        if cid == chapterId then return i end
    end
    return nil
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
        if not IsChapterDone(campaignId, chapterId, chapterIds) then
            return false
        end
    end
    return true
end

local function ScanCampaign(mod)
    if not C_CampaignInfo then return end
    local db = MR.db.char.progress
    if not db[mod.key] then db[mod.key] = {} end
    for _, chapterId in ipairs(mod._chapterIds) do
        db[mod.key]["ch_" .. chapterId] = IsChapterDone(mod._campaignId, chapterId, mod._chapterIds) and 1 or 0
    end
end

local function TryRegisterCampaigns()
    if not C_CampaignInfo or not C_CampaignInfo.GetAvailableCampaigns then return end
    local ids = C_CampaignInfo.GetAvailableCampaigns()
    if not ids or #ids == 0 then return end

    local didRegister = false

    for _, campaignId in ipairs(ids) do
        if not registeredCampaigns[campaignId] then
            local state = C_CampaignInfo.GetState and C_CampaignInfo.GetState(campaignId)

            if not SKIP_STATES[state] then
                local info       = C_CampaignInfo.GetCampaignInfo(campaignId)
                local chapterIds = C_CampaignInfo.GetChapterIDs and C_CampaignInfo.GetChapterIDs(campaignId)

                if chapterIds and #chapterIds > 0 then
                    local name     = (info and info.name and info.name ~= "") and info.name or ("Campaign " .. campaignId)
                    local mapId    = info and info.uiMapID
                    local mapInfo  = mapId and C_Map.GetMapInfo and C_Map.GetMapInfo(mapId)
                    local zoneName = mapInfo and mapInfo.name
                    local label    = zoneName and ("Story: " .. zoneName .. " \xe2\x80\x94 " .. name) or ("Story: " .. name)

                    local rows = {}
                    for _, chapterId in ipairs(chapterIds) do
                        local ch          = C_CampaignInfo.GetCampaignChapterInfo and C_CampaignInfo.GetCampaignChapterInfo(chapterId)
                        local chapterName = (ch and ch.name and ch.name ~= "") and ch.name or ("Chapter " .. chapterId)
                        table.insert(rows, {
                            key   = "ch_" .. chapterId,
                            label = "|cffffff88" .. chapterName .. ":|r",
                            max   = 1,
                        })
                    end

                    local mod = {
                        key         = "story_campaign_" .. campaignId,
                        label       = label,
                        labelColor  = "#ffff99",
                        resetType   = "never",
                        defaultOpen = true,
                        rows        = rows,
                        _campaignId = campaignId,
                        _chapterIds = chapterIds,
                        onScan      = function(self) ScanCampaign(self) end,
                        isVisible   = function(self)
                            return not IsCampaignFullyComplete(self._campaignId, self._chapterIds)
                        end,
                    }

                    MR:RegisterModule(mod)
                    ScanCampaign(mod)
                    registeredCampaigns[campaignId] = true
                    didRegister = true
                end
            end
        end
    end

    if didRegister and MR.RefreshUI then
        MR:RefreshUI()
    end
end

local function ScanAllAndRefresh()
    TryRegisterCampaigns()
    for _, mod in ipairs(MR.modules) do
        if mod.onScan then mod:onScan() end
    end
    if MR.RefreshUI then MR:RefreshUI() end
end

MR:RegisterEvent("PLAYER_LOGIN", function()
    C_Timer.After(1, TryRegisterCampaigns)
end)

MR:RegisterBucketEvent({ "QUEST_TURNED_IN", "QUEST_LOG_UPDATE" }, 1, function()
    C_Timer.After(0.5, ScanAllAndRefresh)
end)