local _, addonNS = ...
local tracking = addonNS.Tracking

function tracking.API:CreateRenownCatalog(L)
local BASE_FACTIONS = {
    {
        key       = "silvermoon",
        label     = L["Faction_SilvermoonCourt"],
        factionId = 2710,
        maxRenown = 20,
        color     = { 0.85, 0.72, 0.18 },
        hex       = "d9b82e",
    },
    {
        key       = "amani",
        label     = L["Faction_AmaniTribe"],
        factionId = 2696,
        maxRenown = 20,
        color     = { 0.82, 0.36, 0.14 },
        hex       = "d15c24",
    },
    {
        key       = "harati",
        label     = L["Faction_Harati"],
        factionId = 2704,
        maxRenown = 20,
        color     = { 0.16, 0.78, 0.55 },
        hex       = "29c78c",
    },
    {
        key       = "singularity",
        label     = L["Faction_TheSingularity"],
        factionId = 2699,
        maxRenown = 20,
        color     = { 0.45, 0.22, 0.82 },
        hex       = "7238d1",
    },
    {
        key       = "zuljarras_forces",
        label     = L["Faction_ZuljarrasForces"] or "Zul'jarra's Forces",
        factionId = 2772,
        maxRenown = 20,
        color     = { 0.18, 0.68, 0.42 },
        hex       = "2eae6b",
        patchKey  = "12.1.0",
    },
}

return BASE_FACTIONS
end
