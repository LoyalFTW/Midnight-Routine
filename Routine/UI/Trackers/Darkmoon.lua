local _, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local function GetRequiredItemDisplay(item)
    local itemID = item and item.itemID
    local name = item and item.fallback or "Unknown item"
    local icon

    if itemID then
        if C_Item and C_Item.GetItemNameByID then
            name = C_Item.GetItemNameByID(itemID) or name
        end
        if C_Item and C_Item.GetItemIconByID then
            icon = C_Item.GetItemIconByID(itemID)
        end
        if C_Item and C_Item.RequestLoadItemDataByID then
            C_Item.RequestLoadItemDataByID(itemID)
        end
    end

    local prefix = icon and ("|T" .. icon .. ":14:14:0:0|t ") or ""
    return string.format("%s%dx %s", prefix, tonumber(item.count) or 1, name)
end


function MR:AddDarkmoonMaterialsToTooltip(tooltip, questId, requiredItems)
    if not tooltip then return end
    if requiredItems == nil then
        requiredItems = self:GetDarkmoonRequiredItems(questId)
    end

    tooltip:AddLine(" ")
    if type(requiredItems) == "table" and #requiredItems > 0 then
        tooltip:AddLine(L["ProfKnowledge_DMFMaterials"] or "Bring these materials:", 1, 0.82, 0.25)
        for _, item in ipairs(requiredItems) do
            tooltip:AddLine(GetRequiredItemDisplay(item), 0.88, 0.88, 0.88)
        end
    else
        tooltip:AddLine(L["ProfKnowledge_DMFNoMaterials"] or "No materials need to be brought.", 0.55, 0.82, 0.62, true)
    end
end

