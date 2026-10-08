local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers["ForeverFeatures"] = function(owner, context)
    local ns = context.namespace
    if not ns.MR.isForever then return end
    ns.Forever = ns.Forever or {}
    ns.Forever.hideRares = false
    ns.Forever.hideProfessions = true
end
