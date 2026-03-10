local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local DUNGEON_TIERS = {
    { 10, L["Myth"],     "#ff8000" },
    {  7, L["Hero"],     "#0070dd" },
    {  4, L["Champion"], "#f1c232" },
    {  2, L["Veteran"],  "#1eff00" },
    {  0, L["Follower"], "#b7b7b7" },
}

local RAID_DIFF = {
    [14] = { L["Normal"], "#1eff00" },
    [15] = { L["Heroic"], "#0070dd" },
    [16] = { L["Mythic"], "#ff8000" },
    [17] = { L["LFR"],    "#b7b7b7" },
}

local DIFF_RANK = { [17]=1, [14]=2, [15]=3, [16]=4 }

local function GetDungeonTier(level)
    level = level or 0
    for _, t in ipairs(DUNGEON_TIERS) do
        if level >= t[1] then return t[2], t[3] end
    end
    return L["Follower"], "#b7b7b7"
end

local function GetRaidDiffName(diffId)
    local d = RAID_DIFF[diffId]
    return d and d[1] or L["Normal"], d and d[2] or "#1eff00"
end

local function SlotLine(tt, slotNum, count, threshold)
    if count >= threshold then
        tt:AddLine(string.format(L["Vault_TT_Slot_Unlocked"], slotNum), 1, 1, 1)
    else
        tt:AddLine(string.format(L["Vault_TT_Slot_Needed"], slotNum, count, threshold), 0.55, 0.55, 0.55)
    end
end

MR:RegisterModule({
    key         = "great_vault",
    label       = L["GreatVault_Title"],
    labelColor  = "#ff8000",
    resetType   = "weekly",
    defaultOpen = true,

    onScan = function(mod)
        if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then return end
        local activities = C_WeeklyRewards.GetActivities()
        if not activities then return end
        local db = MR.db.char.progress
        if not db[mod.key] then db[mod.key] = {} end
        local vd = db[mod.key]

        vd["vault_d_progress"]  = 0
        vd["vault_d_max_level"] = 0
        vd["vault_r_progress"]  = 0
        vd["vault_r_diff_id"]   = 14
        vd["vault_w_progress"]  = 0

        for _, act in ipairs(activities) do
            if act.type == 1 then
                vd["vault_d_progress"] = act.progress or 0
                if (act.level or 0) > (vd["vault_d_max_level"] or 0) then
                    vd["vault_d_max_level"] = act.level or 0
                end
            elseif act.type == 3 then
                local prog = act.progress or 0
                if prog > vd["vault_r_progress"] then
                    vd["vault_r_progress"] = prog
                end
                local newRank = DIFF_RANK[act.difficultyId]
                if newRank and newRank > (DIFF_RANK[vd["vault_r_diff_id"]] or 0) then
                    vd["vault_r_diff_id"] = act.difficultyId
                end
            elseif act.type == 4 then
                vd["vault_w_progress"] = act.progress or 0
            end
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
    end,

    rows = {
        {
            key              = "vault_raid",
            label            = L["Vault_Raid_Label"],
            max              = 3,
            liveKey          = "vault_r_slots",
            liveTierLabelKey = "vault_r_diff_label",
            liveTierColorKey = "vault_r_diff_color",
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
