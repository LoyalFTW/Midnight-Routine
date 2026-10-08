local _, addonNS = ...
local tracking = addonNS.Tracking

tracking.installers["ForeverProfessions"] = function(owner, context)
    local ns = context.namespace
    if not ns.MR.isForever then return end
    ns.Forever = ns.Forever or {}
    local F = ns.Forever
    F.professions = {}
    F.expansions = { { key = "forever", label = "WoW Forever", professions = F.professions } }
    local keys = { [171] = "alchemy", [164] = "blacksmithing", [333] = "enchanting", [202] = "engineering", [182] = "herbalism", [773] = "inscription", [755] = "jewelcrafting", [165] = "leatherworking", [186] = "mining", [393] = "skinning", [197] = "tailoring", [185] = "cooking", [129] = "firstaid", [356] = "fishing" }
    function F.RefreshProfessions()
        wipe(F.professions)
        if not (GetProfessions and GetProfessionInfo) then return end
        local indices = { GetProfessions() }
        for slot = 1, 5 do
            if indices[slot] then
                local name, icon, rank, maxRank, _, _, skillLine = GetProfessionInfo(indices[slot])
                if name and skillLine and maxRank and maxRank > 0 then
                    F.professions[#F.professions + 1] = { key = keys[skillLine] or tostring(skillLine), label = name, skillLine = skillLine, rank = rank or 0, maxRank = maxRank, icon = icon, color = { 0.80, 0.53, 0.20 }, sections = {} }
                end
            end
        end
    end
    function F.HasProfession(skillLine)
        for _, profession in ipairs(F.professions) do
            if profession.skillLine == skillLine then return true end
        end
        return false
    end
end
