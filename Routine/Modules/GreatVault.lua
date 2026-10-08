local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers["GreatVault"] = function(owner, context)
    local ns = context.namespace
    if ns.MR.isForever then return end
    local MR = ns.MR

    local L = context.labels

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
    local DEFAULT_RAID_THRESHOLDS = { 2, 4, 6 }
    local DEFAULT_DUNGEON_THRESHOLDS = { 1, 4, 8 }
    local DEFAULT_WORLD_THRESHOLDS = { 2, 4, 8 }

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

    local function GetActivityThresholds(activities, defaults)
        local thresholds = {}
        for _, activity in ipairs(activities or {}) do
            local threshold = tonumber(activity.threshold)
            if threshold and threshold > 0 then
                thresholds[#thresholds + 1] = threshold
            end
        end
        if #thresholds == 0 then
            for _, threshold in ipairs(defaults) do
                thresholds[#thresholds + 1] = threshold
            end
        end
        table.sort(thresholds)
        return thresholds
    end

    local function CountUnlockedSlots(activities)
        local unlocked = 0
        for _, activity in ipairs(activities or {}) do
            local threshold = tonumber(activity.threshold) or 0
            if threshold > 0 and (tonumber(activity.progress) or 0) >= threshold then
                unlocked = unlocked + 1
            end
        end
        return unlocked
    end

    local function AddSlotLines(tt, progress, thresholds)
        for index, threshold in ipairs(thresholds or {}) do
            SlotLine(tt, index, progress, threshold)
        end
    end

    local function SetRowMax(mod, rowKey, maxValue)
        for _, row in ipairs(mod.rows or {}) do
            if row.key == rowKey then
                row.max = maxValue
                return
            end
        end
    end

    local function IsDungeonVaultMaxed()
        local vd = MR.db and MR.db.char and MR.db.char.progress and MR.db.char.progress["great_vault"] or {}
        return (vd["vault_d_slots"] or 0) >= (vd["vault_d_slot_count"] or 3) and (vd["vault_d_max_level"] or 0) >= 10
    end

    local function IsRaidVaultMaxed()
        local vd = MR.db and MR.db.char and MR.db.char.progress and MR.db.char.progress["great_vault"] or {}
        return (vd["vault_r_slots"] or 0) >= (vd["vault_r_slot_count"] or 3) and (vd["vault_r_diff_id"] or 0) == 16
    end

    local VAULT_SCAN_KEYS = {
        "vault_d_progress",
        "vault_d_max_level",
        "vault_d_slots",
        "vault_d_slot_count",
        "vault_d_thresholds",
        "vault_d_tier_label",
        "vault_d_tier_color",
        "vault_r_progress",
        "vault_r_diff_id",
        "vault_r_diff_label",
        "vault_r_diff_color",
        "vault_r_slots",
        "vault_r_slot_count",
        "vault_r_thresholds",
        "vault_w_progress",
        "vault_w_slots",
        "vault_w_slot_count",
        "vault_w_thresholds",
        "vault_combined_slots",
        "vault_reward_pending",
        "vault_reward_status",
    }

    local function GetVaultScanSignature(vaultData)
        local values = {}
        for index, key in ipairs(VAULT_SCAN_KEYS) do
            local value = vaultData[key]
            values[index] = type(value) == "table" and table.concat(value, ",") or tostring(value)
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
            vd["vault_d_thresholds"] = GetActivityThresholds(buckets.dungeon, DEFAULT_DUNGEON_THRESHOLDS)
            vd["vault_r_thresholds"] = GetActivityThresholds(buckets.raid, DEFAULT_RAID_THRESHOLDS)
            vd["vault_w_thresholds"] = GetActivityThresholds(buckets.world, DEFAULT_WORLD_THRESHOLDS)
            vd["vault_d_slot_count"] = #vd["vault_d_thresholds"]
            vd["vault_r_slot_count"] = #vd["vault_r_thresholds"]
            vd["vault_w_slot_count"] = #vd["vault_w_thresholds"]
            vd["vault_d_slots"] = CountUnlockedSlots(buckets.dungeon)
            vd["vault_r_slots"] = CountUnlockedSlots(buckets.raid)
            vd["vault_w_slots"] = CountUnlockedSlots(buckets.world)

            local hasAvailableRewards = C_WeeklyRewards and C_WeeklyRewards.HasAvailableRewards
                and C_WeeklyRewards.HasAvailableRewards() == true
            vd["vault_reward_pending"] = hasAvailableRewards and 1 or 0
            vd["vault_reward_status"] = hasAvailableRewards and (L["Vault_RewardWaiting"] or "Reward waiting") or nil

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

            vd["vault_combined_slots"] = (vd["vault_r_slots"] or 0) + (vd["vault_d_slots"] or 0) + (vd["vault_w_slots"] or 0)
            SetRowMax(mod, "vault_raid", vd["vault_r_slot_count"])
            SetRowMax(mod, "vault_dungeon", vd["vault_d_slot_count"])
            SetRowMax(mod, "vault_world", vd["vault_w_slot_count"])
            SetRowMax(mod, "vault_combined", vd["vault_r_slot_count"] + vd["vault_d_slot_count"] + vd["vault_w_slot_count"])
            return before ~= GetVaultScanSignature(vd)
        end,

        rows = {
            {
                key           = "vault_reward",
                label         = L["Vault_RewardAvailable_Label"] or "|cffffcc33Unclaimed Vault Reward:|r",
                max           = 1,
                autoTracked   = true,
                countText     = L["Vault_RewardWaiting"] or "Reward waiting",
                countColor    = { 1.00, 0.82, 0.30 },
                activeNameKey = "vault_reward_status",
                activeNameRequiredKey = "vault_reward_pending",
                noDefaultTooltipHint = true,
                isVisible = function()
                    local vd = MR.db and MR.db.char and MR.db.char.progress and MR.db.char.progress["great_vault"] or {}
                    return vd["vault_reward_pending"] == 1
                end,
                completeFunc = function()
                    return false
                end,
                tooltipFunc = function(tt)
                    tt:AddLine(" ")
                    tt:AddLine(L["Vault_RewardAvailable_Note"] or "A Great Vault reward is waiting to be claimed.", 1.00, 0.82, 0.30, true)
                end,
            },
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
                    AddSlotLines(tt, r, vd["vault_r_thresholds"] or DEFAULT_RAID_THRESHOLDS)
                    tt:AddLine(" ")
                    tt:AddLine("Dungeon", 0.3, 0.8, 1)
                    AddSlotLines(tt, d, vd["vault_d_thresholds"] or DEFAULT_DUNGEON_THRESHOLDS)
                    tt:AddLine(" ")
                    tt:AddLine("World", 0.78, 0.59, 0.42)
                    AddSlotLines(tt, w, vd["vault_w_thresholds"] or DEFAULT_WORLD_THRESHOLDS)
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
                    AddSlotLines(tt, prog, vd["vault_r_thresholds"] or DEFAULT_RAID_THRESHOLDS)
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
                    AddSlotLines(tt, prog, vd["vault_d_thresholds"] or DEFAULT_DUNGEON_THRESHOLDS)
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
                    AddSlotLines(tt, prog, vd["vault_w_thresholds"] or DEFAULT_WORLD_THRESHOLDS)
                end,
            },
        },
    })
end
