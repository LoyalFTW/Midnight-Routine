local _, ns = ...
local MR = ns.MR

local NormalizeIconInfo
local GetRowIconInfo
local GetModuleIconInfo
local ShouldShowModuleHeaderIcon
local GetModuleFallbackIconInfo
local ApplyIconToTexture

local MODULE_ICON_FALLBACKS = {
    currencies          = { texture = "Interface\\Icons\\INV_Misc_Coin_17" },
    midnight_activities = { texture = "Interface\\Icons\\Ability_Creature_Cursed_04" },
    omnium_folio        = { texture = "Interface\\Icons\\INV_Enchant_VoidSphere" },
    pvp_currencies      = { texture = "Interface\\TargetingFrame\\UI-PVP-FFA" },
    pvp_weeklies        = { texture = "Interface\\TargetingFrame\\UI-PVP-HORDE" },
    s1_weekly           = { texture = "Interface\\Icons\\INV_Misc_Note_01" },
    world_bosses        = { texture = "Interface\\Icons\\Ability_Hunter_BeastCall" },
    timewalking         = { texture = "Interface\\Icons\\Achievement_Quests_Completed_08" },
    prof_alchemy        = { texture = "Interface\\Icons\\Trade_Alchemy" },
    prof_blacksmithing  = { texture = "Interface\\Icons\\Trade_BlackSmithing" },
    prof_enchanting     = { texture = "Interface\\Icons\\Trade_Engraving" },
    prof_engineering    = { texture = "Interface\\Icons\\Trade_Engineering" },
    prof_herbalism      = { texture = "Interface\\Icons\\Trade_Herbalism" },
    prof_inscription    = { texture = "Interface\\Icons\\INV_Inscription_Tradeskill01" },
    prof_jewelcrafting  = { texture = "Interface\\Icons\\INV_Misc_Gem_01" },
    prof_leatherworking = { texture = "Interface\\Icons\\INV_Misc_ArmorKit_17" },
    prof_mining         = { texture = "Interface\\Icons\\Trade_Mining" },
    prof_skinning       = { texture = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01" },
    prof_tailoring      = { texture = "Interface\\Icons\\Trade_Tailoring" },
    skin_lures          = { texture = "Interface\\Icons\\INV_Misc_Food_50" },
}

ShouldShowModuleHeaderIcon = function()
    return false
end

GetModuleFallbackIconInfo = function(modKey)
    if not modKey or modKey == "" then
        return nil
    end

    local exact = MODULE_ICON_FALLBACKS[modKey]
    if exact then
        return exact
    end

    if modKey:match("^story_campaign_") then
        return { texture = "Interface\\GossipFrame\\AvailableQuestIcon" }
    end

    return nil
end

local ROW_ICON_FALLBACKS = {
    vault_raid          = { texture = "Interface\\LFGFrame\\LFGICON-RAIDFINDER" },
    vault_dungeon       = { texture = "Interface\\LFGFrame\\LFGICON-HEROICDUNGEON" },
    vault_world         = { texture = "Interface\\Icons\\INV_Misc_Map_01" },
    sparks_of_war       = { texture = "Interface\\TargetingFrame\\UI-PVP-FFA" },
    preparing_battle    = { texture = "Interface\\Icons\\Ability_Warrior_BattleShout" },
    something_different = { texture = "Interface\\Icons\\Achievement_BG_winBrawl" },
    early_training      = { texture = "Interface\\Icons\\INV_Sword_04" },
    call_to_delves      = { texture = "Interface\\Icons\\INV_Misc_Spyglass_03" },
    abundance           = { texture = "Interface\\Icons\\INV_Enchant_VoidSphere" },
    lost_legends        = { texture = "Interface\\Icons\\Achievement_Quests_Completed_08" },
    saltherils_soiree   = { texture = "Interface\\Icons\\INV_Drink_11" },
    fortify_runestones  = { texture = "Interface\\Icons\\INV_Stone_15" },
    unity_against_void  = { texture = "Interface\\Icons\\Spell_Shadow_ArcaneTorrent" },
    special_assignment  = { texture = "Interface\\Icons\\INV_Letter_15" },
    tw_dungeon          = { texture = "Interface\\LFGFrame\\LFGICON-HEROICDUNGEON" },
    tw_raid             = { texture = "Interface\\LFGFrame\\LFGICON-RAIDFINDER" },
}

NormalizeIconInfo = function(info)
    if not info then
        return nil
    end

    if type(info) == "number" then
        return { texture = info }
    end

    if type(info) == "string" then
        return { texture = info }
    end

    if type(info) == "table" then
        return {
            atlas = info.atlas,
            texture = info.texture or info.tex or info.fileID,
            texCoord = info.texCoord,
            tint = info.tint,
        }
    end

    return nil
end

GetRowIconInfo = function(mod, row)
    if not row then
        return nil
    end
    if row._mrResolvedIconInfo then
        return row._mrResolvedIconInfo
    end

    local explicit = NormalizeIconInfo(row.icon)
    if explicit then
        row._mrResolvedIconInfo = explicit
        return explicit
    end

    if row.currencyId and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
        local info = C_CurrencyInfo.GetCurrencyInfo(row.currencyId)
        if info and info.iconFileID then
            row._mrResolvedIconInfo = { texture = info.iconFileID }
            return row._mrResolvedIconInfo
        end
    end

    local itemId = row.itemId or row.itemID
    if itemId and C_Item and C_Item.GetItemIconByID then
        local icon = C_Item.GetItemIconByID(itemId)
        if icon then
            row._mrResolvedIconInfo = { texture = icon }
            return row._mrResolvedIconInfo
        end
    end

    if row.spellId then
        local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(row.spellId)
        if icon then
            row._mrResolvedIconInfo = { texture = icon }
            return row._mrResolvedIconInfo
        end
    end

    local fallback = ROW_ICON_FALLBACKS[row.key]
    if fallback then
        row._mrResolvedIconInfo = fallback
        return fallback
    end

    local moduleFallback = GetModuleFallbackIconInfo(mod and mod.key or "")
    if moduleFallback then
        row._mrResolvedIconInfo = moduleFallback
    end
    return moduleFallback
end

GetModuleIconInfo = function(mod)
    if not mod then
        return nil
    end
    if mod._mrResolvedIconInfo then
        return mod._mrResolvedIconInfo
    end

    if mod.key == "great_vault" then
        local keyIcon = GetRowIconInfo(nil, { currencyId = 3028 })
        if keyIcon then
            mod._mrResolvedIconInfo = keyIcon
            return keyIcon
        end
    end

    local explicit = NormalizeIconInfo(mod.icon)
    if explicit then
        mod._mrResolvedIconInfo = explicit
        return explicit
    end

    if mod.rows then
        local rows = MR.GetOrderedRows and MR:GetOrderedRows(mod) or mod.rows
        for _, row in ipairs(rows) do
            local rowIcon = GetRowIconInfo(mod, row)
            if rowIcon then
                mod._mrResolvedIconInfo = rowIcon
                return rowIcon
            end
        end
    end

    local fallback = GetModuleFallbackIconInfo(mod.key)
    if fallback then
        mod._mrResolvedIconInfo = fallback
    end
    return fallback
end

ApplyIconToTexture = function(texture, info, fallbackTexCoord)
    if not texture then
        return false
    end

    info = NormalizeIconInfo(info)
    if not info then
        texture:Hide()
        return false
    end

    texture:Show()
    local left, right, top, bottom
    if info.texCoord then
        left, right, top, bottom = unpack(info.texCoord)
    elseif fallbackTexCoord then
        left, right, top, bottom = unpack(fallbackTexCoord)
    else
        left, right, top, bottom = 0.08, 0.92, 0.08, 0.92
    end

    if info.atlas and texture.SetAtlas then
        if texture._mrIconAtlas ~= info.atlas then
            texture:SetAtlas(info.atlas, true)
            texture._mrIconAtlas = info.atlas
            texture._mrIconTexture = nil
        end
        left, right, top, bottom = 0, 1, 0, 1
    else
        if texture._mrIconTexture ~= info.texture or texture._mrIconAtlas ~= nil then
            texture:SetTexture(info.texture)
            texture._mrIconTexture = info.texture
            texture._mrIconAtlas = nil
        end
    end
    if texture._mrIconLeft ~= left or texture._mrIconRight ~= right
        or texture._mrIconTop ~= top or texture._mrIconBottom ~= bottom then
        texture:SetTexCoord(left, right, top, bottom)
        texture._mrIconLeft, texture._mrIconRight = left, right
        texture._mrIconTop, texture._mrIconBottom = top, bottom
    end

    if info.tint then
        texture:SetVertexColor(info.tint[1] or 1, info.tint[2] or 1, info.tint[3] or 1, info.tint[4] or 1)
    else
        texture:SetVertexColor(1, 1, 1, 1)
    end

    return true
end


ns.UIIcons = {
    GetRow = GetRowIconInfo,
    GetModule = GetModuleIconInfo,
    ShouldShowModuleHeader = ShouldShowModuleHeaderIcon,
    ApplyToTexture = ApplyIconToTexture,
}
