local addonName, ns = ...

local Foundry = _G.Foundry_1_0
if not Foundry then
    error(addonName .. " requires Foundry-1.0 to be loaded before Core/Foundation.lua", 0)
end

local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local MR = {
    name = addonName,
}
ns.MR = MR
MR.ns = ns
MR._eventController = Foundry.Events:New(addonName)
MR._timers = {}
MR._buckets = {}

local MODULES_WITH_OPTIONAL_CURRENCY_COMPLETION = {
    currencies = true,
    pvp_currencies = true,
}

local DEFAULTS = {
    profile = {
        locked          = false,
        scale           = 1.0,
        minimized       = false,
        frameAlpha      = 1.0,
        hideFramesInInstances = false,
        hideAdventureGuideBossIDs = false,
        disabledInCombat = true,
        rememberManagedWindowsVisibility = false,
        managedWindowsBundleHidden       = false,
        transparentMode = false,
        keepIconsVisibleInTextMode = true,
        keepHeadersVisibleInTextMode = true,
        autoHidePanelHeaders = false,
        width           = 260,
        height          = 400,
        fontSize        = 11,
        fontMedia       = nil,
        fontFlags       = "OUTLINE",
        backgroundMedia = nil,
        minimap         = { hide = false },
        managedWindowRestoreState = nil,
        firstSeen       = false,
        welcomeSuppressed = false,
        position        = { point = "CENTER", x = 0, y = 0 },
        collapsedPosition = nil,
        panelOpen          = true,
        renownOpen          = false,
        raresOpen           = false,
        concentrationTrackerOpen = false,
        raresPos            = nil,
        raresLocked         = false,
        raresWidth          = 300,
        raresHeight         = 360,
        currencyBrowserWidth = 360,
        currencyBrowserHeight = 460,
        raresFontSize       = 9,
        raresShimmer        = true,
        raresHiddenZones    = {},
        raresCompact        = false,
        raresMinimized      = false,
        raresScale          = 1.0,
        raresAlpha          = 1.0,
        raresHideKilled     = false,
        raresShowAllZones   = false,
        raresColors         = {},
        renownPos           = nil,
        renownLocked        = false,
        renownWidth         = 280,
        renownBarH          = 18,
        renownAlpha         = 1.0,
        renownShowRep       = true,
        renownShowIcons     = true,
        renownShimmer       = true,
        renownHideMaxed     = false,
        renownHiddenFactions = {},
        renownColors         = {},
        renownOrder          = {},
        renownCompact        = false,
        renownEmblemMode     = false,
        renownAutoHideHeader = false,
        renownMinimized      = false,
        renownScale          = 1.0,
        renownShowLevel      = true,
        renownFontSize       = 9,
        gatheringLocOpen     = false,
        gatheringLocPos      = nil,
        gatheringLocked      = false,
        gatheringWidth       = 350,
        gatheringHeight      = 450,
        gatheringMinimized   = false,
        gatheringAlpha       = 1.0,
        gatheringFontSize    = 9,
        gatheringScale       = 1.0,
        gatheringProfColors  = {},
        gatheringCollapsedProfessions = {},
        gatheringHideCompleted = false,
        professionKnowledgeShowTasks = true,
        professionKnowledgeHideMainTasks = false,
        collapsedProfessionExpansions = {},
        professionKnowledgeTaskCategories = {
            quests = true,
            drops = true,
            treatises = true,
            darkmoon = true,
            catchup = true,
            other = true,
        },
        headerColors    = {},
        headerBackgroundColors = {},
        rowColors       = {},
        syncWindowScale     = false,
        syncWindowFontSize  = false,
        peekOnHover         = false,
        animatedMinimize    = false,
        mainHeaderPosition  = "top",
        tooltipPosition     = "right",
        showMainCharacterBar = true,
        characterWindowLayout = false,
        autoEnableNewModules = true,
        knownModules = {},
        selectedExpansion   = "midnight",
        altBoardSelectedExpansion = "midnight",
        altBoardHiddenCharacters = {},
        altBoardCharacterNotes = {},
        altBoardShowHidden = false,
        altBoardView = "character",
        altBoardCollapsedModules = {},
        altBoardCharacterOrder = {},
        altBoardConcentrationOrder = {},
        concentrationTrackerAlpha = 1.0,
        concentrationTrackerCompact = false,
        concentrationTrackerHiddenCharacters = {},
        expansionModuleStates = {},
        expansionModuleOrder = {},
        patchStates = {},
    },
    char = {
        progress = {},
        professions = {},
        professionsScanned = false,
        professionConcentration = {},
        professionModuleStates = {},
        rowVisibility = {},
        customTasks = {},
        customTaskNextId = 1,
        customTaskDiffProgress = {},
        currencyBrowserHiddenDefaults = {},
        currencyBrowserCustom = {},
        currencyBrowserCustomOrder = {},
        currencyBrowserCollapsedHeaders = {},
        lastWeek = 0,
        lastSyncAt = 0,
        manualOverrides = {},
        welcomeSeen = false,
        raresKills = {},
        lastDailyAt = 0,
        lastResetAt = 0,
        hideComplete = true,
        modules      = {},
        moduleOrder  = {},
        settingsMigrated = false,
        windowLayout = {},
        mediaSettings = {},
        expansionModuleStates = {},
        expansionModuleOrder = {},
    },
    global = {
        customTasks = {},
        customTaskNextId = 1,
        customTaskProgress = {},
        customTaskManualOverrides = {},
        customTaskDiffProgress = {},
    },
}

MR.modules     = {}
MR.moduleByKey = {}
MR.pinnedModuleOrder = {
    midnight_activities = 1,
    s1_weekly = 2,
}
MR.expansions  = {
    midnight = {
        key = "midnight",
        label = L["Expansion_Midnight"] or "Midnight",
        shortLabel = L["Expansion_Midnight"] or "Midnight",
        order = 100,
    },
}
MR.patches = {
    ["12.0.0"] = {
        key = "12.0.0",
        label = L["Patch_1200"] or "12.0.0 Launch",
        shortLabel = "12.0.0",
        order = 120000,
    },
    ["12.0.5"] = {
        key = "12.0.5",
        label = L["Patch_1205"] or "12.0.5",
        shortLabel = "12.0.5",
        order = 120005,
    },
    ["12.0.7"] = {
        key = "12.0.7",
        label = L["Patch_1207"] or "12.0.7 Revelations",
        shortLabel = "12.0.7",
        order = 120007,
    },
    ["12.1.0"] = {
        key = "12.1.0",
        label = L["Patch_1210"] or "12.1 Curse of Ula'tek",
        shortLabel = "12.1",
        order = 120100,
    },
}

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end

    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function MergeMissing(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return dst
    end

    for k, v in pairs(src) do
        if dst[k] == nil then
            dst[k] = DeepCopy(v)
        elseif type(dst[k]) == "table" and type(v) == "table" then
            MergeMissing(dst[k], v)
        end
    end

    return dst
end

local function RestoreDefaults(dst, src)
    if type(dst) ~= "table" or type(src) ~= "table" then
        return dst
    end

    wipe(dst)
    for k, v in pairs(src) do
        dst[k] = DeepCopy(v)
    end

    return dst
end

local function IsTableEmpty(t)
    return type(t) ~= "table" or next(t) == nil
end

function MR:ReleaseFrameTree(frame)
    if not frame then
        return
    end

    if frame._mrExternalFrames then
        for _, external in ipairs(frame._mrExternalFrames) do
            self:ReleaseFrameTree(external)
        end
        frame._mrExternalFrames = nil
    end

    if frame.GetChildren then
        local children = { frame:GetChildren() }
        for _, child in ipairs(children) do
            self:ReleaseFrameTree(child)
        end
    end

    if frame.SetScript and frame.HasScript then
        for _, scriptName in ipairs({
            "OnUpdate",
            "OnEvent",
            "OnClick",
            "OnEnter",
            "OnLeave",
            "OnMouseDown",
            "OnMouseUp",
            "OnDragStart",
            "OnDragStop",
            "OnShow",
            "OnHide",
        }) do
            if frame:HasScript(scriptName) then
                frame:SetScript(scriptName, nil)
            end
        end
    end

    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end
    if frame.EnableMouse then
        frame:EnableMouse(false)
    end
    if frame.Hide then
        frame:Hide()
    end
    if frame.SetParent then
        frame:SetParent(nil)
    end
end

function MR:CaptureFrameScreenPosition(frame)
    if not frame or not frame.GetLeft or not frame.GetTop then
        return nil, nil
    end

    return frame:GetLeft(), frame:GetTop()
end

function MR:RestoreFrameScreenPosition(frame, left, top)
    if not frame or not left or not top or not UIParent then
        return
    end
    if not frame.ClearAllPoints or not frame.SetPoint then
        return
    end

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
end

local function IsInRestrictedCombat()
    return InCombatLockdown and InCombatLockdown()
end


ns.CoreInternals = {
    defaults = DEFAULTS,
    DeepCopy = DeepCopy,
    MergeMissing = MergeMissing,
    RestoreDefaults = RestoreDefaults,
    IsTableEmpty = IsTableEmpty,
    IsInRestrictedCombat = IsInRestrictedCombat,
    optionalCurrencyModules = MODULES_WITH_OPTIONAL_CURRENCY_COMPLETION,
}

