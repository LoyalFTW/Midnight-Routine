local SCAN_THROTTLE       = 2
local DELVE_ACTIVITY_TYPE = 4
local DELVE_T8_MIN_LEVEL  = 8
local DELVERS_BOUNTY_ITEM = 233071

local QUEST_CALL_TO_DELVES  = 84776
local QUEST_MIDNIGHT_DELVES = 93909
local QUEST_NULLAEUS        = 93525

local EXPANSIONS = {
    {
        label  = "Midnight",
        mapIds = { [2395]=true, [2405]=true, [2413]=true, [2437]=true },
        zones  = {
            { uiMapId = 2395, delves = { {8426,8425,93384}, {8438,8437,93372} } },
            { uiMapId = 2405, delves = { {8432,8431,93428}, {8430,8429,93427} } },
            { uiMapId = 2413, delves = { {8434,8433,93421}, {8436,8435,93416} } },
            { uiMapId = 2437, delves = { {8444,8443,93409}, {8442,8441,93410} } },
        },
    },
    {
        label  = "War Within",
        mapIds = { [2248]=true, [2214]=true, [2215]=true, [2255]=true, [2346]=true, [2371]=true },
        zones  = {
            { uiMapId = 2248, delves = { {7779,7864,82939}, {7781,7865,82941}, {7787,7863,82944} } },
            { uiMapId = 2214, delves = { {7782,7866,82945}, {7788,7867,82938}, {8181,8143,85187} } },
            { uiMapId = 2215, delves = { {7780,7869,82940}, {7783,7870,82937}, {7785,7868,82777}, {7789,7871,78508} } },
            { uiMapId = 2255, delves = { {7784,7873,82776}, {7786,7872,82943}, {7790,7874,82942} } },
            { uiMapId = 2346, delves = { {8246,8140,85668} } },
            { uiMapId = 2371, delves = { {8273,8274,0} } },
        },
    },
}

local function GetPlayerExpansion()
    local mapId = C_Map.GetBestMapForUnit("player")
    if mapId then
        for _ = 1, 6 do
            for _, exp in ipairs(EXPANSIONS) do
                if exp.mapIds[mapId] then return exp end
            end
            local info = C_Map.GetMapInfo(mapId)
            if not info or not info.parentMapID or info.parentMapID == 0 then break end
            mapId = info.parentMapID
        end
    end
    return EXPANSIONS[1]
end

for _, exp in ipairs(EXPANSIONS) do
    local total = 0
    for _, zone in ipairs(exp.zones) do total = total + #zone.delves end
    exp.total = total
end

local function ScanExpansion(exp, mdb)
    if not (C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIInfo) then return end

    local done    = 0
    local total   = 0
    local entries = {}

    for _, zone in ipairs(exp.zones) do
        local zoneName = (C_Map.GetMapInfo(zone.uiMapId) or {}).name or "Unknown"
        for _, pair in ipairs(zone.delves) do
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(zone.uiMapId, pair[1])
            if poiInfo then
                total = total + 1
                local questDone = pair[3] ~= 0 and C_QuestLog.IsQuestFlaggedCompleted(pair[3])
                if questDone then
                    done = done + 1
                    entries[#entries + 1] = "|cff808080" .. zoneName .. ": " .. (poiInfo.name or "?") .. " \xE2\x9C\x93|r"
                else
                    entries[#entries + 1] = zoneName .. ": " .. (poiInfo.name or "?")
                end
            end
        end
    end

    mdb["bountiful_live"]    = done
    mdb["bountiful_total"]   = total
    mdb["bountiful_entries"] = table.concat(entries, "\n")
    mdb["bountiful_exp"]     = exp.label
end

local bountifulRow
local lastScan = 0

MR:RegisterModule({
    key         = "delves",
    label       = "Delves",
    labelColor  = "#c8956c",
    resetType   = "weekly",
    defaultOpen = false,

    onScan = function(mod)
        local now = GetTime()
        local db  = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end
        local mdb = db[mod.key]

        local exp = GetPlayerExpansion()
        if exp then
            ScanExpansion(exp, mdb)
            bountifulRow.max = mdb["bountiful_total"] > 0 and mdb["bountiful_total"] or exp.total
        else
            mdb["bountiful_live"]    = 0
            mdb["bountiful_total"]   = 0
            mdb["bountiful_entries"] = ""
            mdb["bountiful_exp"]     = nil
        end

        if (now - lastScan) < SCAN_THROTTLE then return end
        lastScan = now

        if C_WeeklyRewards and C_WeeklyRewards.GetActivities then
            local activities = C_WeeklyRewards.GetActivities()
            if activities then
                for _, act in ipairs(activities) do
                    if act.type == DELVE_ACTIVITY_TYPE then
                        local runs = act.progress or 0
                        local t8   = ((act.level or 0) >= DELVE_T8_MIN_LEVEL) and 1 or 0
                        if mdb["delve_runs"] ~= runs then mdb["delve_runs"] = runs end
                        if mdb["delve_t8"]   ~= t8   then mdb["delve_t8"]   = t8   end
                        break
                    end
                end
            end
        end

        local bountyCount = C_Item.GetItemCount and C_Item.GetItemCount(DELVERS_BOUNTY_ITEM) or 0
        local bountyUsed  = (bountyCount == 0) and 1 or 0
        if mdb["delve_bounty"] ~= bountyUsed then
            mdb["delve_bounty"] = bountyUsed
        end
    end,

    rows = {
        {
            key      = "delve_weekly",
            label    = "|cffc8956cA Call to Delves (5):|r",
            max      = 1,
            note     = "Weekly from Archmage Aethas in Silvermoon",
            questIds = { QUEST_CALL_TO_DELVES },
        },
        {
            key      = "delve_valeera",
            label    = "|cffc8956cMidnight: Delves (3):|r",
            max      = 1,
            note     = "Weekly from Valeera Sanguinar at Delver's HQ — rewards Spark of Radiance",
            questIds = { QUEST_MIDNIGHT_DELVES },
        },
        {
            key     = "delve_runs",
            label   = "|cffc8956cDelve Runs:|r",
            max     = 8,
            note    = "Feeds Great Vault World slot (2/4/8)",
            liveKey = "delve_runs",
        },
        {
            key   = "delve_t8",
            label = "|cffc8956cTier 8 Delve Cleared:|r",
            max   = 1,
            note  = "Complete 8x Tier 8+ to maximise Great Vault ilvl",
        },
        {
            key     = "delve_bounty",
            label   = "|cffc8956cDelver's Bounty Used:|r",
            max     = 1,
            note    = "Loot drop from Nullaeus — use before killing the Delve boss",
            liveKey = "delve_bounty",
        },
        {
            key      = "delve_nullaeus",
            label    = "|cffc8956cNullaeus Defeated:|r",
            max      = 1,
            note     = "Summon via Beacon of Hope after checkpoint — Torment's Rise",
            questIds = { QUEST_NULLAEUS },
        },
        {
            key     = "bountiful_count",
            label   = "|cffc8956cBountiful Delves Done:|r",
            max     = 4,
            note    = "Bountiful delves completed today out of those currently active.",
            liveKey = "bountiful_live",
            isVisible = function()
                local mdb = MR.db.char.progress["delves"]
                return mdb and mdb["bountiful_exp"] ~= nil
            end,
            tooltipFunc = function(tip)
                local mdb     = MR.db.char.progress["delves"]
                local expName = mdb and mdb["bountiful_exp"]
                local entries = mdb and mdb["bountiful_entries"]
                tip:AddLine(" ")
                if expName then
                    tip:AddLine(expName .. " \xe2\x80\x94 today's bountifuls:", 1, 1, 1)
                end
                if entries and entries ~= "" then
                    for line in entries:gmatch("[^\n]+") do
                        tip:AddLine("  " .. line, 0.9, 0.85, 0.6)
                    end
                else
                    tip:AddLine("No bountiful delves detected.", 0.6, 0.6, 0.6)
                end
            end,
        },
    },
})

do
    local mod = MR.moduleByKey["delves"]
    for _, r in ipairs(mod.rows) do
        if r.key == "bountiful_count" then bountifulRow = r; break end
    end
end
