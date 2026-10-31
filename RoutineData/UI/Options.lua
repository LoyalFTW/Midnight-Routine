local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end
local L = LibStub("AceLocale-3.0"):GetLocale("RoutineData")

local VARIABLE_PREFIX = "RoutineData_"

local category, layout

local function AddCheckbox(variableTable, key, name, tooltip, default)
    local setting = Settings.RegisterAddOnSetting(
        category, VARIABLE_PREFIX .. key, key, variableTable, Settings.VarType.Boolean, name, default)
    Settings.CreateCheckbox(category, setting, tooltip)
    return setting
end

local function AddHeader(text)
    if layout and CreateSettingsListSectionHeaderInitializer then
        layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(text))
    end
end

function RoutineData:OpenOptions()
    if category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(category:GetID())
    end
end

RoutineData:OnLogin(function(self)
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterAddOnSetting) then return end
    local settings = self.db.settings
    settings.tooltipCharacterLimit = self:GetTooltipCharacterCount()

    category, layout = Settings.RegisterVerticalLayoutCategory("Routine Data")

    local limitSetting = Settings.RegisterAddOnSetting(
        category, VARIABLE_PREFIX .. "tooltipCharacterLimit", "tooltipCharacterLimit", settings,
        Settings.VarType.Number, L["Options_CharacterLimit"], 5)
    Settings.CreateDropdown(category, limitSetting, function()
        local options = Settings.CreateControlTextContainer()
        options:Add(0, L["Options_AllCharacters"])
        for count = 1, 70 do options:Add(count, tostring(count)) end
        return options:GetData()
    end, L["Options_CharacterLimitDesc"])

    AddHeader(L["Options_ItemTooltips"])
    AddCheckbox(settings, "tooltipItems", L["Options_ItemOwners"],
        L["Options_ItemOwnersDesc"], true)
    AddCheckbox(settings, "tooltipYield", L["Options_Yield"],
        L["Options_YieldDesc"], true)
    AddCheckbox(settings, "tooltipBags", L["Options_Bags"], L["Options_BagsDesc"], true)
    AddCheckbox(settings, "tooltipBank", L["Options_Bank"], L["Options_BankDesc"], true)
    AddCheckbox(settings, "tooltipMail", L["Options_Mail"], L["Options_MailDesc"], true)
    AddCheckbox(settings, "tooltipEquipped", L["Options_Equipped"], L["Options_EquippedDesc"], true)
    if not self.isForever then
        AddCheckbox(settings, "tooltipWarband", L["Options_Warband"], L["Options_WarbandDesc"], true)
    end
    AddCheckbox(settings, "tooltipGuild", L["Options_Guild"], L["Options_GuildDesc"], true)

    AddHeader(L["Options_OtherTooltips"])
    AddCheckbox(settings, "tooltipCurrency", L["Options_Currency"],
        L["Options_CurrencyDesc"], true)
    AddCheckbox(settings, "tooltipRares", L["Options_Rares"],
        L["Options_RaresDesc"], true)

    AddHeader(L["Options_Minimap"])
    local hideSetting = AddCheckbox(settings.minimap, "hide", L["Options_HideMinimap"],
        L["Options_HideMinimapDesc"], false)
    hideSetting:SetValueChangedCallback(function(_, value)
        self:SetMinimapButtonShown(not value)
    end)

    self:RegisterRosterOptions(category)
    Settings.RegisterAddOnCategory(category)
end)
