local _, ns = ...
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
        tt:AddLine(L["Title"], 1, 1, 1)
        tt:AddLine(L["Minimap_LeftClick"],  0.8, 0.8, 0.8)
        tt:AddLine(L["Minimap_RightClick"],     0.8, 0.8, 0.8)
        tt:AddLine(L["Minimap_HideHint"], 0.5, 0.5, 0.5)
    end,
})

local function StyleMinimapButton()
    if not LDBIcon:IsRegistered(LDB_NAME) then
        return
    end

    LDBIcon:SetButtonSize(LDB_NAME, 34)
    LDBIcon:RemoveButtonBorder(LDB_NAME)
    LDBIcon:RemoveButtonBackground(LDB_NAME)
    LDBIcon:SetButtonIcon(LDB_NAME, MINIMAP_ICON, 34, "CENTER", 0, 0)
end

local mmLoader = CreateFrame("Frame")
mmLoader:RegisterEvent("PLAYER_LOGIN")
mmLoader:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents()

    if not MR.db or not MR.db.profile then
        return
    end

    MR.db.profile.minimap = MR.db.profile.minimap or { hide = false }

    if not LDBIcon:IsRegistered(LDB_NAME) then
        LDBIcon:Register(LDB_NAME, minimapObject, MR.db.profile.minimap)
    end
    StyleMinimapButton()

    if not MR.db.profile.firstSeen then
        C_Timer.After(2.0, function()
            if MR and MR.db and MR.db.profile and not MR.db.profile.firstSeen then
                StartGlow()
            end
        end)
    end
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
