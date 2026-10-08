local addonName, addonNS = ...
local tracking = {}
addonNS.Tracking = tracking

local API = {
    name = addonName,
}
local installed = setmetatable({}, { __mode = "k" })
local interfaceVersion = GetBuildInfo and tonumber((select(4, GetBuildInfo()))) or 0
API.isForever = interfaceVersion >= 16000 and interfaceVersion < 17000
tracking.MR = { isForever = API.isForever }
tracking.Forever = {}
tracking.API = API
tracking.installers = {}

function API:InstallComponent(component, owner, context)
    assert(type(owner) == "table", "Routine tracking engine requires a consumer")
    local installer = assert(tracking.installers[component], "Routine tracking engine component is unavailable: " .. tostring(component))
    local components = installed[owner]
    if components and components[component] then
        return
    end
    installer(owner, context or {})
    if not components then
        components = {}
        installed[owner] = components
    end
    components[component] = true
end
