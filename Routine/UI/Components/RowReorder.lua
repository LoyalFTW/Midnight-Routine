local _, ns = ...
if ns.Inactive then return end

function ns.CreateRowReorder(owner, body, padding)
    local view = owner._rowReorderView
    if not view then
        local driver = CreateFrame("Frame", nil, owner)
        driver:SetAllPoints(owner)
        local ghost = CreateFrame("Frame", nil, driver, "BackdropTemplate")
        ghost:SetHeight(20)
        ghost:SetFrameStrata("TOOLTIP")
        ghost:SetBackdrop(ns.MakeBackdrop())
        ghost:SetBackdropColor(0.10, 0.08, 0.02, 0.95)
        ghost:SetBackdropBorderColor(0.9, 0.72, 0.1, 1)
        local label = ghost:CreateFontString(nil, "OVERLAY")
        label:SetFont(ns.FONT_HEADERS, 10, ns.GetFontFlags())
        label:SetPoint("LEFT", ghost, "LEFT", 8, 0)
        label:SetTextColor(1, 0.85, 0.2)
        local line = CreateFrame("Frame", nil, driver)
        line:SetHeight(2)
        line:SetFrameStrata("TOOLTIP")
        local texture = line:CreateTexture(nil, "OVERLAY")
        texture:SetAllPoints()
        texture:SetColorTexture(0.9, 0.72, 0.1, 1)
        driver:Hide()
        view = { driver = driver, ghost = ghost, label = label, line = line }
        owner._rowReorderView = view
    elseif view.cancel then
        view.cancel()
    end

    local driver, ghost, line = view.driver, view.ghost, view.line
    local source, rows, drop, slot
    local function Cancel()
        if source then rows[source]:SetAlpha(1) end
        source, rows, drop, slot = nil, nil, nil, nil
        driver:SetScript("OnUpdate", nil)
        driver:Hide()
    end
    view.cancel = Cancel
    driver:SetScript("OnHide", Cancel)

    local function Update()
        local _, cursorY = GetCursorPosition()
        local y = cursorY / body:GetEffectiveScale()
        if not body:GetTop() then return end
        local offset = y - body:GetTop() + 10
        ghost:SetPoint("TOPLEFT", body, "TOPLEFT", padding, offset)
        ghost:SetPoint("TOPRIGHT", body, "TOPRIGHT", -padding, offset)
        slot = #rows
        for index, row in ipairs(rows) do
            local top, bottom = row:GetTop(), row:GetBottom()
            if top and bottom and y > (top + bottom) / 2 then
                slot = index - 1
                break
            end
        end
        local row = rows[math.max(1, slot)]
        local edge = slot == 0 and "TOP" or "BOTTOM"
        line:SetPoint("TOPLEFT", row, edge .. "LEFT")
        line:SetPoint("TOPRIGHT", row, edge .. "RIGHT")
    end

    local function AddGrip(row, height, getDrag)
        local grip = CreateFrame("Button", nil, row)
        grip:SetSize(14, height)
        grip:SetPoint("LEFT", row, "LEFT", 2, 0)
        local label = grip:CreateFontString(nil, "OVERLAY")
        label:SetFont(ns.FONT_HEADERS, 11, ns.GetFontFlags())
        label:SetPoint("CENTER")
        label:SetText("=")
        label:SetTextColor(0.28, 0.22, 0.08)
        grip:SetScript("OnEnter", function() label:SetTextColor(0.9, 0.75, 0.2) end)
        grip:SetScript("OnLeave", function() label:SetTextColor(0.28, 0.22, 0.08) end)
        grip:SetScript("OnMouseDown", function(_, button)
            if button ~= "LeftButton" or source then return end
            local list, index, text, onDrop = getDrag()
            if not index or #list < 2 then return end
            rows, source, drop = list, index, onDrop
            view.label:SetText(text)
            rows[source]:SetAlpha(0.3)
            Update()
            driver:SetScript("OnUpdate", function()
                Update()
                if IsMouseButtonDown("LeftButton") then return end
                local from, callback = source, drop
                local target = slot and math.max(1, slot + (source > slot and 1 or 0))
                Cancel()
                if target and from ~= target then callback(from, target) end
            end)
            driver:Show()
        end)
    end
    return AddGrip, Cancel
end
