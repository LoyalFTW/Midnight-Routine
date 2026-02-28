local DUNGEON_TIERS = {
    { 10, "Myth",     "#ff8000" },
    {  7, "Hero",     "#0070dd" },
    {  4, "Champion", "#f1c232" },
    {  2, "Veteran",  "#1eff00" },
    {  0, "Follower", "#b7b7b7" },
}

local RAID_DIFF = {
    [14] = { "Normal", "#1eff00" },
    [15] = { "Heroic", "#0070dd" },
    [16] = { "Mythic", "#ff8000" },
    [17] = { "LFR",    "#b7b7b7" },
}

local DIFF_RANK = { [17]=1, [14]=2, [15]=3, [16]=4 }

local function GetDungeonTier(level)
    level = level or 0
    for _, t in ipairs(DUNGEON_TIERS) do
        if level >= t[1] then return t[2], t[3] end
    end
    return "Follower", "#b7b7b7"
end

local function GetRaidDiffName(diffId)
    local d = RAID_DIFF[diffId]
    return d and d[1] or "Normal", d and d[2] or "#1eff00"
end

MR:RegisterModule({
    key         = "great_vault",
    label       = "Great Vault",
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

        local tierLabel, tierColor   = GetDungeonTier(vd["vault_d_max_level"])
        vd["vault_d_tier_label"]     = tierLabel
        vd["vault_d_tier_color"]     = tierColor

        local raidName, raidColor    = GetRaidDiffName(vd["vault_r_diff_id"])
        vd["vault_r_diff_label"]     = raidName
        vd["vault_r_diff_color"]     = raidColor
    end,

    rows = {
        {
            key              = "vault_r2",
            label            = "|cffff8000Raid x2 Bosses:|r",
            max              = 2,
            vaultLabel       = "Normal",
            vaultColor       = "#1eff00",
            note             = "Defeat 2 Bosses",
            liveKey          = "vault_r_progress",
            liveTierLabelKey = "vault_r_diff_label",
            liveTierColorKey = "vault_r_diff_color",
        },
        {
            key              = "vault_r4",
            label            = "|cffff8000Raid x4 Bosses:|r",
            max              = 4,
            vaultLabel       = "Heroic",
            vaultColor       = "#0070dd",
            note             = "Defeat 4 Bosses",
            liveKey          = "vault_r_progress",
            liveTierLabelKey = "vault_r_diff_label",
            liveTierColorKey = "vault_r_diff_color",
        },
        {
            key              = "vault_r6",
            label            = "|cffff8000Raid x6 Bosses:|r",
            max              = 6,
            vaultLabel       = "Mythic",
            vaultColor       = "#ff8000",
            note             = "Defeat 6 Bosses",
            liveKey          = "vault_r_progress",
            liveTierLabelKey = "vault_r_diff_label",
            liveTierColorKey = "vault_r_diff_color",
        },
        {
            key              = "vault_d1",
            label            = "|cff00ccffDungeon x1:|r",
            max              = 1,
            vaultLabel       = "Veteran",
            vaultColor       = "#1eff00",
            note             = "Complete 1 Heroic, Mythic, or Timewalking Dungeon",
            liveKey          = "vault_d_progress",
            liveTierLabelKey = "vault_d_tier_label",
            liveTierColorKey = "vault_d_tier_color",
        },
        {
            key              = "vault_d4",
            label            = "|cff00ccffDungeon x4:|r",
            max              = 4,
            vaultLabel       = "Champion",
            vaultColor       = "#f1c232",
            note             = "Complete 4 Heroic, Mythic, or Timewalking Dungeons",
            liveKey          = "vault_d_progress",
            liveTierLabelKey = "vault_d_tier_label",
            liveTierColorKey = "vault_d_tier_color",
        },
        {
            key              = "vault_d8",
            label            = "|cff00ccffDungeon x8:|r",
            max              = 8,
            vaultLabel       = "Hero",
            vaultColor       = "#0070dd",
            note             = "Complete 8 Heroic, Mythic, or Timewalking Dungeons",
            liveKey          = "vault_d_progress",
            liveTierLabelKey = "vault_d_tier_label",
            liveTierColorKey = "vault_d_tier_color",
        },
        {
            key        = "vault_w2",
            label      = "|cffc8956cWorld x2:|r",
            max        = 2,
            vaultLabel = "Adventurer",
            vaultColor = "#b7b7b7",
            note       = "Complete 2 Delves or World Activities",
            liveKey    = "vault_w_progress",
        },
        {
            key        = "vault_w4",
            label      = "|cffc8956cWorld x4:|r",
            max        = 4,
            vaultLabel = "Champion",
            vaultColor = "#f1c232",
            note       = "Complete 4 Delves or World Activities",
            liveKey    = "vault_w_progress",
        },
        {
            key        = "vault_w8",
            label      = "|cffc8956cWorld x8:|r",
            max        = 8,
            vaultLabel = "Hero",
            vaultColor = "#0070dd",
            note       = "Complete 8 Delves or World Activities",
            liveKey    = "vault_w_progress",
        },
    },
})
