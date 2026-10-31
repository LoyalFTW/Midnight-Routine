local _, ns = ...
if ns.Inactive then return end
if ns.MR.isForever and ns.Forever.hideProfessions then return end
local MR = ns.MR
local PK = ns.ProfessionKnowledgeInternal

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)
local waypointLocationIndex = PK.waypointLocationIndex
local Required = PK.Required
local Progress = PK.Progress
local GetWaypointTarget = PK.GetWaypointTarget
local EntryName = PK.EntryName
local waypointAlt = PK.waypointAlt
local GetGatheringZoneName = PK.GetGatheringZoneName
local SetGatheringWaypoint = PK.SetGatheringWaypoint
local StripInlineColor = PK.StripInlineColor
local NormalizeTooltipLabel = PK.NormalizeTooltipLabel
local EntryDisplayLabel = PK.EntryDisplayLabel

local function ResolveProfessionKnowledgeTooltipEntry(entry)
    return (entry and entry.professionKnowledgeEntry) or entry
end

local function IsDuplicateSourceLabel(label, entry, sectionKey, displayLabel)
    local normalized = NormalizeTooltipLabel(label)
    if normalized == "" then
        return true
    end

    local candidates = {
        displayLabel,
        entry and entry.label,
        entry and entry.mainMenuLabel,
        entry and entry.note,
    }
    if entry then
        candidates[#candidates + 1] = EntryDisplayLabel(entry, sectionKey)
        candidates[#candidates + 1] = EntryName(entry)
        if ns.ResolveProfessionEntryLabel then
            candidates[#candidates + 1] = ns.ResolveProfessionEntryLabel(entry)
        end
    end

    for _, candidate in ipairs(candidates) do
        if candidate and NormalizeTooltipLabel(candidate) == normalized then
            return true
        end
    end
    return false
end

local function AddProfessionKnowledgeTooltip(tooltip, entry, sectionKey, current, required, opts)
    entry = ResolveProfessionKnowledgeTooltipEntry(entry)
    if not (tooltip and entry) then
        return nil, 0
    end

    opts = opts or {}
    sectionKey = sectionKey or entry.profKnowledgeSectionKey or entry.group
    local displayLabel = EntryDisplayLabel(entry, sectionKey)
    local cleanDisplayLabel = NormalizeTooltipLabel(displayLabel)
    current = current ~= nil and current or Progress(entry)
    required = required or Required(entry)
    if current == true then
        current = required or 1
    elseif current == false then
        current = 0
    end

    tooltip:SetText(displayLabel, 1, 1, 1)

    local cycleKey = entry.rowKey or entry.key or entry.itemID or entry.label
    local target, targetCount = GetWaypointTarget(entry, cycleKey)
    if target then
        local altKey = entry.itemID or entry.label
        local useAlt = entry.altZone and waypointAlt[altKey]
        local mapID = useAlt and entry.altZone or target.zone
        local mapX = useAlt and entry.altX or target.x
        local mapY = useAlt and entry.altY or target.y

        tooltip:AddLine(" ")
        if not opts.sourceOnly and target.label and not IsDuplicateSourceLabel(target.label, entry, sectionKey, displayLabel) then
            tooltip:AddLine(target.label, 0.75, 0.90, 1)
        end
        tooltip:AddLine(GetGatheringZoneName(mapID), 0.85, 0.85, 0.85)
        tooltip:AddLine(string.format(L["Gathering_Coords"], mapX, mapY), 0.7, 1, 0.9)
        if entry.altZone then
            tooltip:AddLine(" ")
            tooltip:AddLine(L["Gathering_AltLocationLabel"], 0.65, 0.65, 0.65)
            tooltip:AddLine(GetGatheringZoneName(useAlt and entry.zone or entry.altZone), 0.6, 0.6, 0.6)
            tooltip:AddLine(string.format("%.1f, %.1f", useAlt and entry.x or entry.altX, useAlt and entry.y or entry.altY), 0.45, 0.7, 0.55)
        end
    else
        tooltip:AddLine(" ")
        tooltip:AddLine(L["ProfKnowledge_NoWaypoint"], 0.65, 0.65, 0.65)
    end

    if entry.note and entry.note ~= "" and NormalizeTooltipLabel(entry.note) ~= cleanDisplayLabel then
        tooltip:AddLine(" ")
        tooltip:AddLine(entry.note, 0.65, 0.85, 0.95, true)
    end

    if entry.kind == "darkmoon" and MR.AddDarkmoonMaterialsToTooltip then
        MR:AddDarkmoonMaterialsToTooltip(tooltip, entry.questID, entry.requiredItems)
    end

    if entry.reference then
        tooltip:AddLine(" ")
        tooltip:AddLine(L["ProfKnowledge_ReferenceOnly"] or "One-time source, not auto-tracked.", 0.6, 0.6, 0.6, true)
    end

    tooltip:AddLine(" ")
    if opts.sourceOnly and target then
        tooltip:AddLine((entry.altZone or targetCount > 1) and L["Gathering_ClickCycleHint"] or L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
    elseif (current or 0) >= (required or 1) then
        tooltip:AddLine(L["Gathering_AlreadyCollected"], 0, 0.8, 0.27)
    elseif target then
        tooltip:AddLine((entry.altZone or targetCount > 1) and L["Gathering_ClickCycleHint"] or L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
    end

    return target, targetCount
end

function MR:ShowProfessionKnowledgeSourceTooltip(owner, entry, sectionKey)
    entry = ResolveProfessionKnowledgeTooltipEntry(entry)
    if not (owner and entry) then
        return false
    end

    sectionKey = sectionKey or entry.profKnowledgeSectionKey or entry.group
    ns.ShowTooltip(owner, {
        build = function(tooltip)
            AddProfessionKnowledgeTooltip(tooltip, entry, sectionKey, nil, nil, { sourceOnly = true })
        end,
    })
    return true
end

function MR:ShowProfessionKnowledgeCatchupTooltip(owner, entry)
    if not (owner and entry) then
        return false
    end

    ns.ShowTooltip(owner, {
        build = function(tooltip)
            tooltip:SetText(StripInlineColor(L["Prof_Catchup"] or "Catch-Up Knowledge"), 1, 1, 1)
            if entry.profKnowledgeProfessionLabel then
                tooltip:AddLine(entry.profKnowledgeProfessionLabel, 0.85, 0.85, 0.85)
            end
            if entry.note and entry.note ~= "" then
                tooltip:AddLine(" ")
                tooltip:AddLine(entry.note, 0.70, 0.82, 0.92, true)
            end
        end,
    })
    return true
end

function MR:SetProfessionKnowledgeWaypoint(entry, sectionKey)
    entry = ResolveProfessionKnowledgeTooltipEntry(entry)
    if not entry then
        return false
    end

    sectionKey = sectionKey or entry.profKnowledgeSectionKey or entry.group
    local cycleKey = entry.rowKey or entry.key or entry.itemID or entry.label
    local target, targetCount = GetWaypointTarget(entry, cycleKey)
    if not target then
        return false
    end

    local altKey = entry.itemID or entry.label
    local useAlt = entry.altZone and waypointAlt[altKey]
    target = useAlt and { itemID = entry.itemID, label = entry.label, zone = entry.altZone, x = entry.altX, y = entry.altY } or target
    if entry.altZone then waypointAlt[altKey] = not waypointAlt[altKey] end
    if targetCount > 1 then
        waypointLocationIndex[cycleKey] = ((waypointLocationIndex[cycleKey] or 1) % targetCount) + 1
    end

    local ok, source = SetGatheringWaypoint(target)
    if ok then
        print(string.format(L["Waypoint_Set"], source, EntryDisplayLabel(entry, sectionKey), target.x, target.y))
    else
        print(L["Waypoint_Unavailable"])
    end
    return ok
end
