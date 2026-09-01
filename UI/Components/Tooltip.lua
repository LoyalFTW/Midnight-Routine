local _, ns = ...

local TOOLTIP_ANCHORS = {
    left = "ANCHOR_LEFT",
    right = "ANCHOR_RIGHT",
    bottom = "ANCHOR_BOTTOM",
    cursor = "ANCHOR_CURSOR",
}

local function GetTooltipPosition(opts)
    local addon = ns.MR
    local position = addon
        and addon.GetWindowLayoutValue
        and addon:GetWindowLayoutValue("tooltipPosition")

    if not position then
        if opts and opts.anchor then
            return nil, opts.anchor
        end
        position = "right"
    end

    if position == "middle" then
        return "middle", "ANCHOR_NONE"
    end

    return position, TOOLTIP_ANCHORS[position] or (opts and opts.anchor) or TOOLTIP_ANCHORS.right
end

function ns.ApplyTooltipPosition(tooltip, owner, opts)
    if not tooltip or not owner then
        return
    end

    local position, anchor = GetTooltipPosition(opts)
    tooltip:SetOwner(owner, anchor)
    if position == "middle" and tooltip.ClearAllPoints then
        tooltip:ClearAllPoints()
        tooltip:SetPoint("CENTER", owner, "CENTER", 0, 0)
    end
end

function ns.ShowTooltip(owner, opts)
    if not owner or not GameTooltip then
        return
    end

    local addon = ns.MR
    local started = addon and addon._scrollProfileArmed and debugprofilestop and debugprofilestop() or nil
    opts = opts or {}
    ns.ApplyTooltipPosition(GameTooltip, owner, opts)
    if GameTooltip.ClearLines then
        GameTooltip:ClearLines()
    end

    if type(opts.build) == "function" then
        opts.build(GameTooltip, owner)
    elseif opts.text then
        local color = opts.color or { 1, 1, 1 }
        GameTooltip:SetText(opts.text, color[1], color[2], color[3], color[4] or 1, opts.wrap == true)
    end

    GameTooltip:Show()
    if started and addon.CaptureScrollProfile then
        local data = owner._mrData or (owner._mrOwner and owner._mrOwner._mrData)
        local mod = data and data.mod
        local row = data and data.row
        local detail = string.format("module=%s row=%s", tostring(mod and mod.key or "unknown"), tostring(row and (row.key or row.label) or "unknown"))
        addon:CaptureScrollProfile("tooltip", debugprofilestop() - started, detail)
    end
end

function ns.HideOwnedTooltip(owner)
    if not owner or not GameTooltip then
        return false
    end

    if GameTooltip.GetOwner and GameTooltip:GetOwner() ~= owner then
        return false
    end

    GameTooltip:Hide()
    return true
end

function ns.AddTooltipLines(owner, build)
    if not owner or not GameTooltip or type(build) ~= "function" then
        return false
    end
    if GameTooltip.GetOwner and GameTooltip:GetOwner() ~= owner then
        return false
    end

    build(GameTooltip)
    GameTooltip:Show()
    return true
end

local warbandTooltip
local warbandShiftWatcher
local warbandHoveredOwner
local warbandHoveredBuild
local warbandLastShiftState = false

local function EnsureWarbandTooltip()
    if warbandTooltip then
        return warbandTooltip
    end

    warbandTooltip = CreateFrame("GameTooltip", "MidnightRoutineWarbandTooltip", UIParent, "GameTooltipTemplate")
    warbandTooltip:SetFrameStrata("TOOLTIP")
    return warbandTooltip
end

local function EnsureWarbandShiftWatcher()
    if warbandShiftWatcher then
        return
    end

    warbandShiftWatcher = CreateFrame("Frame")
    warbandShiftWatcher:SetScript("OnUpdate", function()
        if not warbandHoveredOwner then
            return
        end

        local shiftDown = IsShiftKeyDown()
        if shiftDown ~= warbandLastShiftState then
            warbandLastShiftState = shiftDown
            ns.ShowWarbandTooltip(warbandHoveredOwner, warbandHoveredBuild)
        end
    end)
end

function ns.ShowWarbandTooltip(owner, build)
    if not owner or type(build) ~= "function" or not GameTooltip then
        return false
    end

    local addon = ns.MR
    if not (addon and addon.db and addon.db.profile and addon.db.profile.showWarbandTooltips ~= false) then
        ns.HideWarbandTooltip()
        return false
    end
    if GameTooltip.GetOwner and GameTooltip:GetOwner() ~= owner then
        ns.HideWarbandTooltip()
        return false
    end

    EnsureWarbandShiftWatcher()
    warbandHoveredOwner = owner
    warbandHoveredBuild = build
    warbandLastShiftState = IsShiftKeyDown()

    local tip = EnsureWarbandTooltip()
    tip:SetOwner(owner, "ANCHOR_NONE")
    tip:ClearAllPoints()
    tip:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 0, -2)
    tip:ClearLines()
    build(tip)

    if tip:NumLines() > 0 then
        tip:Show()
        return true
    else
        tip:Hide()
        return false
    end
end

function ns.HideWarbandTooltip()
    warbandHoveredOwner = nil
    warbandHoveredBuild = nil
    if warbandTooltip then
        warbandTooltip:Hide()
    end
end

function ns.BindTooltip(frame, opts)
    if not frame then
        return
    end

    frame:HookScript("OnEnter", function(owner)
        local resolved = type(opts) == "function" and opts(owner) or opts
        ns.ShowTooltip(owner, resolved)
    end)
    frame:HookScript("OnLeave", function(owner)
        ns.HideOwnedTooltip(owner)
    end)
end
