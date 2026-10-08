local _, addonNS = ...
local tracking = addonNS.Tracking

function tracking.API:InstallContent(owner, context)
    context.progressData = context.namespace.CoreData
    self:InstallComponent("Professions", owner, context)
    self:InstallComponent("Scanner", owner, context)
    self:InstallComponent("Resets", owner, context)
    self:InstallComponent("Events", owner, context)
    self:InstallComponent("Warband", owner, context)
    self:InstallComponent("Activities", owner, context)
    self:InstallComponent("OmniumFolio", owner, context)
    self:InstallComponent("WeeklyTasks", owner, context)
    self:InstallComponent("PvP", owner, context)
    self:InstallComponent("GreatVault", owner, context)
    self:InstallComponent("Crests", owner, context)
    self:InstallComponent("Delves", owner, context)
    self:InstallComponent("Prey", owner, context)
    self:InstallComponent("StoryCampaign", owner, context)
    self:InstallComponent("WorldEvents", owner, context)
    self:InstallComponent("Timewalking", owner, context)
    self:InstallComponent("DarkmoonFaire", owner, context)
    self:InstallComponent("CustomTasks", owner, context)
    if owner.isForever then
        self:InstallComponent("ForeverFeatures", owner, context)
        local forever = context.namespace.Forever
        forever.rareLocations = tracking.Forever.rareLocations
        forever.rareZoneNames = tracking.Forever.rareZoneNames
        forever.rareCatalog = tracking.Forever.rareCatalog
        self:InstallComponent("ForeverProfessions", owner, context)
        self:InstallComponent("ForeverReputations", owner, context)
        self:InstallComponent("ForeverRares", owner, context)
        self:InstallComponent("ForeverBootstrap", owner, context)
    end
    self:InstallComponent("ProfessionKnowledgeCore", owner, context)
    self:InstallComponent("ProfessionKnowledgeMidnight", owner, context)
    self:InstallComponent("ProfessionKnowledgeTheWarWithin", owner, context)
    self:InstallComponent("ProfessionKnowledgeDragonflight", owner, context)
end
