local addonName, ns = ...

local ROUTINE_DATA = "RoutineData"
local CHECK_DELAY = 2

local RoutineData = _G.RoutineData
if RoutineData and RoutineData.Tracking then
    ns.Tracking = RoutineData.Tracking
    return
end

ns.Inactive = true

local function ShowPopup()
    if C_AddOns.IsAddOnLoaded(ROUTINE_DATA) then
        return
    end

    local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
    local installed = C_AddOns.DoesAddOnExist(ROUTINE_DATA)

    local dialog = {
        text = L["Dependency_Missing"],
        button1 = OKAY,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    if installed then
        dialog.text = L["Dependency_NeedsRoutineData"]
        dialog.button1 = L["Dependency_Reload"]
        dialog.button2 = CANCEL
        dialog.OnAccept = function()
            C_AddOns.EnableAddOn(ROUTINE_DATA)
            if C_AddOns.SaveAddOns then
                C_AddOns.SaveAddOns()
            end
            ReloadUI()
        end
    end

    StaticPopupDialogs["MIDNIGHTROUTINE_NEEDS_ROUTINEDATA"] = dialog
    StaticPopup_Show("MIDNIGHTROUTINE_NEEDS_ROUTINEDATA")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()
    C_Timer.After(CHECK_DELAY, ShowPopup)
end)
