local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end
local L = LibStub("AceLocale-3.0"):GetLocale("RoutineData")
local API = RoutineData.API

local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local OBJECT_NAME = "RoutineData"
local ICON = "Interface\\AddOns\\RoutineData\\Media\\MinimapIcon.tga"
local BUTTON_SIZE = 34

local function StyleMinimapButton()
    if not LDBIcon:IsRegistered(OBJECT_NAME) then
        return
    end

    if LDBIcon.SetButtonSize then LDBIcon:SetButtonSize(OBJECT_NAME, BUTTON_SIZE) end
    if LDBIcon.RemoveButtonBorder then LDBIcon:RemoveButtonBorder(OBJECT_NAME) end
    if LDBIcon.RemoveButtonBackground then LDBIcon:RemoveButtonBackground(OBJECT_NAME) end
    if LDBIcon.SetButtonIcon then LDBIcon:SetButtonIcon(OBJECT_NAME, ICON, BUTTON_SIZE, "CENTER", 0, 0) end
end

local function FormatMoney(copper)
    return GetMoneyString and GetMoneyString(copper, true) or tostring(copper)
end

local MAX_LISTED = 5

local broker = LDB:NewDataObject(OBJECT_NAME, {
    type = "data source",
    label = "Routine Data",
    text = "",
    icon = ICON,
    OnClick = function()
        RoutineData:OpenOptions()
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Routine Data")
        local entries = API.GetGoldRanking()
        if #entries == 0 then
            tooltip:AddLine(L["Broker_NoCharacters"], 0.7, 0.7, 0.7)
            tooltip:AddLine(L["Broker_ClickHint"], 0.55, 0.55, 0.60)
            return
        end
        local limit = IsShiftKeyDown() and #entries or MAX_LISTED
        for index, entry in ipairs(entries) do
            if index > limit then break end
            tooltip:AddDoubleLine(RoutineData.CharacterLabel(entry.key, entry.classFile), FormatMoney(entry.gold), 1, 1, 1, 1, 1, 1)
        end
        if #entries > limit then
            tooltip:AddLine(string.format(L["Broker_MoreCharacters"], #entries - limit), 0.55, 0.55, 0.60)
        end
        tooltip:AddLine(" ")
        tooltip:AddDoubleLine(L["Tooltip_Total"], FormatMoney(API.GetTotalGold()), 0.7, 0.7, 0.7, 1, 1, 1)
        tooltip:AddLine(" ")
        tooltip:AddLine(L["Broker_ClickHint"], 0.55, 0.55, 0.60)
    end,
})

local function RefreshText()
    broker.text = FormatMoney(API.GetTotalGold())
end

local routineLoaded = false

local function IsRoutineLoaded()
    local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
    return isLoaded and isLoaded("MidnightRoutine") and true or false
end

function RoutineData:SetMinimapButtonShown(shown)
    local minimap = self.db.settings.minimap
    minimap.hide = not shown
    if shown and not routineLoaded then
        LDBIcon:Show(OBJECT_NAME)
    else
        LDBIcon:Hide(OBJECT_NAME)
    end
end

local shiftWatcher = CreateFrame("Frame")
shiftWatcher:RegisterEvent("MODIFIER_STATE_CHANGED")
shiftWatcher:SetScript("OnEvent", function()
    local button = LDBIcon:GetMinimapButton(OBJECT_NAME)
    if button and GameTooltip:IsShown() and GameTooltip:GetOwner() == button then
        GameTooltip:ClearLines()
        broker.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    end
end)

RoutineData:OnLogin(function(self)
    routineLoaded = IsRoutineLoaded()
    LDBIcon:Register(OBJECT_NAME, broker, routineLoaded and { hide = true } or self.db.settings.minimap)
    StyleMinimapButton()
    RefreshText()
    self.RegisterCallback(broker, "GoldUpdated", RefreshText)
end)
