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
end

function ns.HideTooltip(owner)
    if not GameTooltip then
        return
    end

    if not owner or not GameTooltip.GetOwner or GameTooltip:GetOwner() == owner then
        GameTooltip:Hide()
    end
end

function ns.AddTooltipLines(owner, build)
    if not GameTooltip or type(build) ~= "function" then
        return
    end
    if owner and GameTooltip.GetOwner and GameTooltip:GetOwner() ~= owner then
        return
    end

    build(GameTooltip)
    GameTooltip:Show()
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
        ns.HideTooltip(owner)
    end)
end
