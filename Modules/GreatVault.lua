local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local DUNGEON_TIERS = {
    { 10, L["Myth"],     "#ff8000" },
    {  7, L["Hero"],     "#0070dd" },
    {  4, L["Champion"], "#f1c232" },
    {  2, L["Veteran"],  "#1eff00" },
    {  0, L["Mythic"],   "#b7b7b7" },
}

local RAID_DIFF = {
    [14] = { L["Normal"], "#1eff00" },
    [15] = { L["Heroic"], "#0070dd" },
    [16] = { L["Mythic"], "#ff8000" },
    [17] = { L["LFR"],    "#b7b7b7" },
}

local DIFF_RANK = { [17]=1, [14]=2, [15]=3, [16]=4 }

local function IsCombinedMode()
    return MR.db and MR.db.profile and MR.db.profile.greatVaultCombined == true
end

local function UpdateMax(current, candidate)
    return math.max(current or 0, candidate or 0)
end

local function GetDungeonTier(level)
    level = level or 0
    for _, t in ipairs(DUNGEON_TIERS) do
        if level >= t[1] then return t[2], t[3] end
    end
    return L["Follower"], "#b7b7b7"
end

local function GetRaidDiffName(diffId)
    local d = RAID_DIFF[diffId]
    return d and d[1] or L["LFR"], d and d[2] or "#b7b7b7"
end

local function SlotLine(tt, slotNum, count, threshold)
    if count >= threshold then
        tt:AddLine(string.format(L["Vault_TT_Slot_Unlocked"], slotNum), 1, 1, 1)
    else
        tt:AddLine(string.format(L["Vault_TT_Slot_Progress"], slotNum, count, threshold), 0.55, 0.55, 0.55)
    end
end

local function IsDungeonVaultMaxed()
    local vd = MR.db and MR.db.char and MR.db.char.progress and MR.db.char.progress["great_vault"] or {}
    return (vd["vault_d_slots"] or 0) >= 3 and (vd["vault_d_max_level"] or 0) >= 10
end

local function IsRaidVaultMaxed()
    local vd = MR.db and MR.db.char and MR.db.char.progress and MR.db.char.progress["great_vault"] or {}
    return (vd["vault_r_slots"] or 0) >= 3 and (vd["vault_r_diff_id"] or 0) == 16
end

local VAULT_SCAN_KEYS = {
    "vault_d_progress",
    "vault_d_max_level",
    "vault_d_slots",
    "vault_d_tier_label",
    "vault_d_tier_color",
    "vault_r_progress",
    "vault_r_diff_id",
    "vault_r_diff_label",
    "vault_r_diff_color",
    "vault_r_slots",
    "vault_w_progress",
    "vault_w_slots",
    "vault_combined_slots",
}

local function GetVaultScanSignature(vaultData)
    local values = {}
    for index, key in ipairs(VAULT_SCAN_KEYS) do
        values[index] = tostring(vaultData[key])
    end
    return table.concat(values, "\031")
end

MR:RegisterModule({
    key         = "great_vault",
    label       = L["GreatVault_Title"],
    labelColor  = "#ff8000",
    resetType   = "weekly",
    defaultOpen = true,
    scanReturnsChanged = true,

    onScan = function(mod)
        local db = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end
        local vd = db[mod.key]
        local buckets = MR.GetWeeklyRewardActivityBuckets and MR:GetWeeklyRewardActivityBuckets() or nil
        if not buckets then return false end
        local before = GetVaultScanSignature(vd)

        vd["vault_d_progress"]  = 0
        vd["vault_d_max_level"] = 0
        vd["vault_r_progress"]  = 0
        vd["vault_r_diff_id"]   = nil
        vd["vault_w_progress"]  = 0

        for _, act in ipairs(buckets.dungeon) do
            vd["vault_d_progress"] = UpdateMax(vd["vault_d_progress"], act.progress)
            if (act.level or 0) > (vd["vault_d_max_level"] or 0) then
                vd["vault_d_max_level"] = act.level or 0
            end
        end

        for _, act in ipairs(buckets.raid) do
            local prog = act.progress or 0
            vd["vault_r_progress"] = UpdateMax(vd["vault_r_progress"], prog)
            local difficultyId = act.difficultyId
            if (not difficultyId) and C_WeeklyRewards and C_WeeklyRewards.GetDifficultyIDForActivityTier and act.activityTierID then
                difficultyId = C_WeeklyRewards.GetDifficultyIDForActivityTier(act.activityTierID)
            end
            if (not difficultyId or not DIFF_RANK[difficultyId]) and DIFF_RANK[act.level] then
                difficultyId = act.level
            end
            local newRank = DIFF_RANK[difficultyId]
            if newRank and newRank > (DIFF_RANK[vd["vault_r_diff_id"]] or 0) then
                vd["vault_r_diff_id"] = difficultyId
            end
        end

        for _, act in ipairs(buckets.world) do
            vd["vault_w_progress"] = UpdateMax(vd["vault_w_progress"], act.progress)
        end

        if vd["vault_r_progress"] > 0 then
            local raidName, raidColor = GetRaidDiffName(vd["vault_r_diff_id"])
            vd["vault_r_diff_label"] = raidName
            vd["vault_r_diff_color"] = raidColor
        else
            vd["vault_r_diff_label"] = nil
            vd["vault_r_diff_color"] = nil
        end

        if vd["vault_d_progress"] > 0 then
            local tierLabel, tierColor = GetDungeonTier(vd["vault_d_max_level"])
            vd["vault_d_tier_label"] = tierLabel
            vd["vault_d_tier_color"] = tierColor
        else
            vd["vault_d_tier_label"] = nil
            vd["vault_d_tier_color"] = nil
        end

        local r = vd["vault_r_progress"]
        vd["vault_r_slots"] = (r >= 6 and 3) or (r >= 4 and 2) or (r >= 2 and 1) or 0

        local d = vd["vault_d_progress"]
        vd["vault_d_slots"] = (d >= 8 and 3) or (d >= 4 and 2) or (d >= 1 and 1) or 0

        local w = vd["vault_w_progress"]
        vd["vault_w_slots"] = (w >= 8 and 3) or (w >= 4 and 2) or (w >= 2 and 1) or 0

        vd["vault_combined_slots"] = (vd["vault_r_slots"] or 0) + (vd["vault_d_slots"] or 0) + (vd["vault_w_slots"] or 0)
        return before ~= GetVaultScanSignature(vd)
    end,

    rows = {
        {
            key           = "vault_combined",
            label         = L["GreatVault_Title"],
            max           = 9,
            liveKey       = "vault_combined_slots",
            isVisible     = function() return IsCombinedMode() end,
            completeFunc  = function()
                return IsRaidVaultMaxed() and IsDungeonVaultMaxed()
            end,
            tooltipFunc = function(tt)
                local vd = MR.db.char.progress["great_vault"] or {}
                local r  = vd["vault_r_progress"] or 0
                local d  = vd["vault_d_progress"] or 0
                local w  = vd["vault_w_progress"] or 0
                tt:AddLine(" ")
                tt:AddLine("Raid", 0.9, 0.7, 0.3)
                SlotLine(tt, 1, r, 2)
                SlotLine(tt, 2, r, 4)
                SlotLine(tt, 3, r, 6)
                tt:AddLine(" ")
                tt:AddLine("Dungeon", 0.3, 0.8, 1)
                SlotLine(tt, 1, d, 1)
                SlotLine(tt, 2, d, 4)
                SlotLine(tt, 3, d, 8)
                tt:AddLine(" ")
                tt:AddLine("World", 0.78, 0.59, 0.42)
                SlotLine(tt, 1, w, 2)
                SlotLine(tt, 2, w, 4)
                SlotLine(tt, 3, w, 8)
            end,
        },
        {
            key              = "vault_raid",
            label            = L["Vault_Raid_Label"],
            max              = 3,
            liveKey          = "vault_r_slots",
            liveTierLabelKey = "vault_r_diff_label",
            liveTierColorKey = "vault_r_diff_color",
            isVisible        = function() return not IsCombinedMode() end,
            completeFunc     = function()
                return IsRaidVaultMaxed()
            end,
            tooltipFunc = function(tt)
                local vd   = MR.db.char.progress["great_vault"] or {}
                local prog = vd["vault_r_progress"] or 0
                tt:AddLine(" ")
                tt:AddLine(string.format(L["Vault_TT_Raid_Header"], prog), 0.9, 0.7, 0.3)
                SlotLine(tt, 1, prog, 2)
                SlotLine(tt, 2, prog, 4)
                SlotLine(tt, 3, prog, 6)
            end,
        },
        {
            key              = "vault_dungeon",
            label            = L["Vault_Dungeon_Label"],
            max              = 3,
            liveKey          = "vault_d_slots",
            liveTierLabelKey = "vault_d_tier_label",
            liveTierColorKey = "vault_d_tier_color",
            isVisible        = function() return not IsCombinedMode() end,
            completeFunc     = function()
                return IsDungeonVaultMaxed()
            end,
            tooltipFunc = function(tt)
                local vd   = MR.db.char.progress["great_vault"] or {}
                local prog = vd["vault_d_progress"] or 0
                tt:AddLine(" ")
                tt:AddLine(string.format(L["Vault_TT_Dungeon_Header"], prog), 0.3, 0.8, 1)
                SlotLine(tt, 1, prog, 1)
                SlotLine(tt, 2, prog, 4)
                SlotLine(tt, 3, prog, 8)
            end,
        },
        {
            key         = "vault_world",
            label       = L["Vault_World_Label"],
            max         = 3,
            liveKey     = "vault_w_slots",
            isVisible   = function() return not IsCombinedMode() end,
            tooltipFunc = function(tt)
                local vd   = MR.db.char.progress["great_vault"] or {}
                local prog = vd["vault_w_progress"] or 0
                tt:AddLine(" ")
                tt:AddLine(string.format(L["Vault_TT_World_Header"], prog), 0.78, 0.59, 0.42)
                SlotLine(tt, 1, prog, 2)
                SlotLine(tt, 2, prog, 4)
                SlotLine(tt, 3, prog, 8)
            end,
        },
    },
})
