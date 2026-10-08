local addonName, addonNS = ...
local tracking = {}
addonNS.Tracking = tracking

local RoutineData = _G.RoutineData or {}
_G.RoutineData = RoutineData
RoutineData.Tracking = tracking
RoutineData.API = RoutineData.API or { version = 1 }
RoutineData.callbacks = RoutineData.callbacks or LibStub("CallbackHandler-1.0"):New(RoutineData)

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
tracking.env = {
    isModuleEnabled = function() return true end,
    shouldDefer = function() return false end,
    shouldSuspend = function() return false end,
    isSurfaceVisible = function() return false end,
    markDataDirty = function() end,
    getViewSource = function() return nil end,
    isAccountWideCustomTask = function() return false end,
    getSharedCustomTask = function() return nil end,
    isRowEnabled = function() return true end,
    isCurrencyInCurrenciesModule = function() return false end,
    isDarkmoonVisible = function() return false end,
    refreshDarkmoonVisibility = function() return nil end,
    refreshBrewfestVisibility = function() return nil end,
    refreshEncounterProgress = function() return nil end,
    syncWorldBossKillByName = function() end,
    refreshDelvesLiveProgress = function() end,
    recordGildedStashLoot = function() return nil end,
    primeProfessionKnowledgeLabels = function() end,
    noteRefreshSource = function() end,
    queueDeferredProgressUpdate = function() end,
    shouldHideRelatedWhenComplete = function() return false end,
}
tracking.callbacks = LibStub("CallbackHandler-1.0"):New(tracking)

function tracking:Fire(event, ...)
    self.callbacks:Fire(event, ...)
end

function API:SetEngine(engine)
    tracking.engine = engine
end

function API:SetEnvironment(provider)
    for name, fn in pairs(provider) do
        assert(type(tracking.env[name]) == "function" and type(fn) == "function", "Unknown tracking environment provider: " .. tostring(name))
        tracking.env[name] = fn
    end
end

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
