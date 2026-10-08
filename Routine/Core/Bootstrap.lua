local addonName, ns = ...
local MR = ns.MR
local Foundry = _G.Foundry_1_0

if not MR then
    error(addonName .. ": core object is missing during bootstrap", 0)
end

if not Foundry or not Foundry.Lifecycle then
    error(addonName .. ": Foundry Lifecycle module is not loaded", 0)
end

local lifecycle = Foundry.Lifecycle:New(MR, addonName)
MR._lifecycle = lifecycle

lifecycle:OnAddonLoaded(function(addon)
    if addon.isForever then
        lifecycle:OnLogin(function(loginAddon)
            if loginAddon.OnInitialize then
                loginAddon:OnInitialize()
            end
            if loginAddon.InitializeMinimapButton then
                loginAddon:InitializeMinimapButton()
            end
            if loginAddon.OnEnable then
                loginAddon:OnEnable()
            end
        end)
        return
    end
    if addon.OnInitialize then
        addon:OnInitialize()
    end

    lifecycle:OnLogin(function(loginAddon)
        if loginAddon.OnEnable then
            loginAddon:OnEnable()
        end
    end)
end)
