local _, ns = ...
local MR = ns.MR

local LDB     = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")
local L       = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local GLOW_PULSE_INTERVAL = 1.5

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
    icon = "Interface\\AddOns\\MidnightRoutine\\Media\\Icon.tga",

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

-- Foundry.Lifecycle's controller allows exactly one raw OnLogin hook per
-- controller (Core.lua already claims it for MR:OnEnable()), so this can't
-- register a second OnLogin subscriber directly. Instead this becomes an
-- OnEnable-time subscriber: Core.lua's OnEnable calls MR:InitMinimapButton()
-- at login, the same "chain a module init off the single login hook" pattern
-- Foundry-based addons use elsewhere. One-shot by construction (OnLogin only
-- fires once), so no UnregisterAllEvents equivalent is needed.
function MR:InitMinimapButton()
    if not self.db or not self.db.profile then
        return
    end

    self.db.profile.minimap = self.db.profile.minimap or { hide = false }

    if not LDBIcon:IsRegistered("MidnightRoutine") then
        LDBIcon:Register("MidnightRoutine", minimapObject, self.db.profile.minimap)
    end

    if not self.db.profile.firstSeen then
        C_Timer.After(2.0, function()
            if MR and MR.db and MR.db.profile and not MR.db.profile.firstSeen then
                StartGlow()
            end
        end)
    end
end

function MR:SetMinimapHidden(hide)
    if not self.db or not self.db.profile then return end
    self.db.profile.minimap = self.db.profile.minimap or { hide = false }
    self.db.profile.minimap.hide = hide and true or false
    if LDBIcon:IsRegistered("MidnightRoutine") then
        if hide then LDBIcon:Hide("MidnightRoutine")
        else         LDBIcon:Show("MidnightRoutine") end
    end
end
