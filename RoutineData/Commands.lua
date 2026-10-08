local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end
local L = LibStub("AceLocale-3.0"):GetLocale("RoutineData")
local API = RoutineData.API

local TOGGLES = {
    tooltip = "tooltipItems",
    yield = "tooltipYield",
    currency = "tooltipCurrency",
    rares = "tooltipRares",
    bags = "tooltipBags",
    bank = "tooltipBank",
    warband = "tooltipWarband",
    guild = "tooltipGuild",
}

local function PrintHelp()
    RoutineData:Print(L["Cmd_Help_Title"])
    print("  " .. L["Cmd_Help_Options"])
    print("  " .. L["Cmd_Help_Forget"])
    print("  " .. L["Cmd_Help_Chars"])
    print("  " .. L["Cmd_Help_Item"])
    print("  " .. L["Cmd_Help_Toggle"])
    print("  " .. L["Cmd_Help_ToggleMinimap"])
    print("  " .. L["Cmd_Help_ToggleCurrency"])
    print("  " .. L["Cmd_Help_ToggleRares"])
    print("  " .. L["Cmd_Help_ToggleYield"])
end

local function PrintCharacters()
    local keys = API.GetCharacters()
    if #keys == 0 then
        RoutineData:Print(L["Cmd_NoCharacters"])
        return
    end
    for _, charKey in ipairs(keys) do
        local record = RoutineData.db.characters[charKey]
        local updated = record and record.updatedAt.bags
        print(string.format("  %s%s", charKey, updated and ("  " .. string.format(L["Cmd_BagsUpdated"], date("%Y-%m-%d %H:%M", updated))) or ""))
    end
end

local function PrintItem(argument)
    local itemID = tonumber(argument) or tonumber(argument:match("item:(%d+)"))
    if not itemID then
        RoutineData:Print(L["Cmd_UsageItem"])
        return
    end
    local counts = API.GetItemCounts(itemID)
    RoutineData:Print(string.format(L["Cmd_ItemTotal"], itemID, API.GetTotalItemCount(itemID)))
    for _, entry in ipairs(counts.characters) do
        print(string.format("  %s  %s: %d  %s: %d", entry.key, L["Tooltip_Bags"], entry.bags, L["Tooltip_Bank"], entry.bank))
    end
    if counts.warband > 0 then print(string.format("  %s %d", L["Tooltip_WarbandBank"], counts.warband)) end
    for _, guild in ipairs(counts.guilds) do
        print(string.format("  <%s> %d", guild.name or guild.key, guild.count))
    end
end

local function Forget(charKey)
    if charKey == "" then
        RoutineData:Print(L["Cmd_UsageForget"])
    elseif charKey == RoutineData:GetCurrentCharacterKey() then
        RoutineData:Print(L["Cmd_ForgetCurrent"])
    elseif RoutineData:ForgetCharacter(charKey) then
        RoutineData:Print(string.format(L["Cmd_Removed"], charKey))
    else
        RoutineData:Print(string.format(L["Cmd_NoData"], charKey))
    end
end

local function Toggle(name)
    if name == "minimap" then
        local shown = RoutineData.db.settings.minimap.hide
        RoutineData:SetMinimapButtonShown(shown)
        RoutineData:Print(shown and L["Cmd_MinimapShown"] or L["Cmd_MinimapHidden"])
        return
    end
    local setting = TOGGLES[name]
    if not setting then
        RoutineData:Print(L["Cmd_UsageToggle"])
        return
    end
    local settings = RoutineData.db.settings
    settings[setting] = not settings[setting]
    RoutineData:Print(string.format(settings[setting] and L["Cmd_ToggleOn"] or L["Cmd_ToggleOff"], name))
end

SLASH_ROUTINEDATA1 = "/rdata"
SLASH_ROUTINEDATA2 = "/routinedata"
SlashCmdList["ROUTINEDATA"] = function(message)
    local command, rest = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "chars" then
        PrintCharacters()
    elseif command == "item" then
        PrintItem(rest)
    elseif command == "toggle" then
        Toggle(rest:lower())
    elseif command == "forget" then
        Forget(rest)
    elseif command == "options" or command == "config" then
        RoutineData:OpenOptions()
    else
        PrintHelp()
    end
end
