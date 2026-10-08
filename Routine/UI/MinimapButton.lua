local _, ns = ...
if ns.Inactive then return end
local MR = ns.MR

local LDB     = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local L       = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local GLOW_PULSE_INTERVAL = 1.5
local LDB_NAME = "MidnightRoutine"
local MINIMAP_ICON = "Interface\\AddOns\\MidnightRoutine\\Media\\MinimapIcon.tga"

local function StopGlow()
    if MR._firstSeenGlowTimer then
        MR._firstSeenGlowTimer:Cancel()
        MR._firstSeenGlowTimer = nil
    end

    local shine = MR.cfgShine
    if shine then
        shine:Stop()
    end
end

local function StartGlow()
    if not MR.db or not MR.db.profile or MR.db.profile.firstSeen then
        StopGlow()
        return
    end

    local shine = MR.cfgShine
    if not shine then return end

    shine:Play()
    if MR._firstSeenGlowTimer then
        MR._firstSeenGlowTimer:Cancel()
    end
    MR._firstSeenGlowTimer = C_Timer.NewTicker(GLOW_PULSE_INTERVAL, function()
        if not MR.db or not MR.db.profile or MR.db.profile.firstSeen then
            StopGlow()
        end
    end)
end

function MR:DismissFirstTimeGlow()
    if self.db and self.db.profile and not self.db.profile.firstSeen then
        self.db.profile.firstSeen = true
    end

    StopGlow()
end

local MAX_LISTED_CHARACTERS = 5

local function FormatMoney(copper)
    return GetMoneyString and GetMoneyString(copper, true) or tostring(copper)
end

local ACCENT = { 0.165, 0.906, 0.776 }
local CURRENT_MARKER = "|TInterface\\Buttons\\UI-CheckBox-Check:12:12:0:-1|t "

local function CharacterGoldName(entry, currentKey)
    local name, realm = MR:ParseCharacterKey(entry.key)
    local color = entry.classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[entry.classFile]
    local text = color and color:WrapTextInColorCode(name) or name
    if realm ~= "" and realm ~= GetRealmName() then
        text = text .. " |cff8c8c99" .. realm .. "|r"
    end
    if entry.key == currentKey then
        text = CURRENT_MARKER .. text
    end
    return text
end

local function AddGoldLines(tt)
    local api = _G.RoutineData and _G.RoutineData.API
    local entries = api and api.GetGoldRanking and api.GetGoldRanking() or {}
    if #entries == 0 then
        return
    end

    local currentKey = MR:GetCurrentCharacterKey()
    local limit = IsShiftKeyDown() and #entries or MAX_LISTED_CHARACTERS
    local total = 0
    for _, entry in ipairs(entries) do
        total = total + entry.gold
    end

    tt:AddLine(" ")
    tt:AddDoubleLine(L["Minimap_GoldHeader"], string.format(L["Minimap_GoldCount"], #entries),
        ACCENT[1], ACCENT[2], ACCENT[3], 0.55, 0.55, 0.60)
    for index, entry in ipairs(entries) do
        if index > limit then break end
        tt:AddDoubleLine(CharacterGoldName(entry, currentKey), FormatMoney(entry.gold), 1, 1, 1, 1, 1, 1)
    end
    if #entries > limit then
        tt:AddLine(string.format(L["Minimap_GoldMore"], #entries - limit), 0.55, 0.55, 0.60)
    end
    tt:AddLine(" ")
    tt:AddDoubleLine(L["Minimap_GoldTotal"], FormatMoney(total), ACCENT[1], ACCENT[2], ACCENT[3], 1, 1, 1)
end

local minimapObject = LDB:NewDataObject("MidnightRoutine", {
    type = "launcher",
    text = "MidnightRoutine",
    icon = MINIMAP_ICON,

    OnClick = function(_, button)
        if button == "LeftButton" then
            if MR.ToggleManagedWindows then
                MR:ToggleManagedWindows()
            end
        elseif button == "RightButton" then
            if MR.ToggleConfig then MR:ToggleConfig() end
        end
    end,

    OnTooltipShow = function(tt)
        local owner = tt.GetOwner and tt:GetOwner() or nil
        if ns.ApplyTooltipPosition and owner and not ns.IsDefaultTooltipPosition() then
            ns.ApplyTooltipPosition(tt, owner)
        end
        tt:AddLine(L["Title"], 1, 1, 1)
        tt:AddLine(L["Minimap_LeftClick"],  0.8, 0.8, 0.8)
        tt:AddLine(L["Minimap_RightClick"],     0.8, 0.8, 0.8)
        tt:AddLine(L["Minimap_HideHint"], 0.5, 0.5, 0.5)
        if MR.db and MR.db.profile.minimapShowGold ~= false then
            AddGoldLines(tt)
        end
    end,
})

local shiftWatcher = CreateFrame("Frame")
shiftWatcher:RegisterEvent("MODIFIER_STATE_CHANGED")
shiftWatcher:SetScript("OnEvent", function()
    local button = LDBIcon:GetMinimapButton(LDB_NAME)
    if button and GameTooltip:IsShown() and GameTooltip:GetOwner() == button then
        GameTooltip:ClearLines()
        minimapObject.OnTooltipShow(GameTooltip)
        GameTooltip:Show()
    end
end)

local function StyleMinimapButton()
    if not LDBIcon:IsRegistered(LDB_NAME) then
        return
    end

    if LDBIcon.SetButtonSize then LDBIcon:SetButtonSize(LDB_NAME, 34) end
    if LDBIcon.RemoveButtonBorder then LDBIcon:RemoveButtonBorder(LDB_NAME) end
    if LDBIcon.RemoveButtonBackground then LDBIcon:RemoveButtonBackground(LDB_NAME) end
    if LDBIcon.SetButtonIcon then LDBIcon:SetButtonIcon(LDB_NAME, MINIMAP_ICON, 34, "CENTER", 0, 0) end
end

function MR:InitializeMinimapButton()
    if not self.db or not self.db.profile then
        return false
    end
    if self._minimapInitialized then return true end

    MR.db.profile.minimap = MR.db.profile.minimap or { hide = false }
    MR.db.profile.minimap.showInCompartment = true

    if not LDBIcon:IsRegistered(LDB_NAME) then
        LDBIcon:Register(LDB_NAME, minimapObject, MR.db.profile.minimap)
    end
    if LDBIcon.IsButtonCompartmentAvailable and LDBIcon:IsButtonCompartmentAvailable() then
        LDBIcon:AddButtonToCompartment(LDB_NAME, MINIMAP_ICON)
    end
    StyleMinimapButton()
    if MR.db.profile.minimap.hide then
        LDBIcon:Hide(LDB_NAME)
    else
        LDBIcon:Show(LDB_NAME)
    end
    self._minimapInitialized = true

    if not MR.db.profile.firstSeen then
        C_Timer.After(2.0, function()
            if MR and MR.db and MR.db.profile and not MR.db.profile.firstSeen then
                StartGlow()
            end
        end)
    end
    return true
end

local mmLoader = CreateFrame("Frame")
mmLoader:RegisterEvent("PLAYER_LOGIN")
mmLoader:SetScript("OnEvent", function(self)
    if MR:InitializeMinimapButton() then self:UnregisterAllEvents() end
end)

function MR:SetMinimapHidden(hide)
    if not self.db or not self.db.profile then return end
    self.db.profile.minimap = self.db.profile.minimap or { hide = false }
    self.db.profile.minimap.hide = hide and true or false
    if LDBIcon:IsRegistered(LDB_NAME) then
        if hide then LDBIcon:Hide(LDB_NAME)
        else         LDBIcon:Show(LDB_NAME) end
    end
end
