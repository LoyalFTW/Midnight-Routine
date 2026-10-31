local _, ns = ...
if ns.Inactive then return end
if ns.MR.isForever and ns.Forever.hideProfessions then return end
local MR = ns.MR
local PK = ns.ProfessionKnowledgeInternal

local MakeBackdrop = ns.MakeBackdrop
local hex = ns.Hex
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)
local waypointLocationIndex = PK.waypointLocationIndex
local Progress = PK.Progress
local KPTotal = PK.KPTotal
local GetItemCountRemaining = PK.GetItemCountRemaining
local GetProfessionCatchupAmount = PK.GetProfessionCatchupAmount
local GetProfessionCatchupProgress = PK.GetProfessionCatchupProgress
local GetProfessionTaskRows = PK.GetProfessionTaskRows
local IsProfessionKnowledgeModule = PK.IsProfessionKnowledgeModule
local GetWaypointTarget = PK.GetWaypointTarget
local GetFontFlags = ns.GetFontFlags
local GetProfessionTaskDisplayGroup = PK.GetProfessionTaskDisplayGroup
local PROFESSION_TASK_GROUP_ORDER = PK.PROFESSION_TASK_GROUP_ORDER
local GetProfessionTaskGroupLabel = PK.GetProfessionTaskGroupLabel
local GetEntryIcon = PK.GetEntryIcon
local GetGatheringZoneName = PK.GetGatheringZoneName
local SetGatheringWaypoint = PK.SetGatheringWaypoint
local StripInlineColor = PK.StripInlineColor
local EntryDisplayLabel = PK.EntryDisplayLabel
local RenderFrame = PK.RenderFrame
local RenderFontString = PK.RenderFontString
local RenderTexture = PK.RenderTexture

local function RenderEntryRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, entry, sectionKey)
    local current, required = Progress(entry)
    local done = current >= required
    if done and db.gatheringHideCompleted then return cardY end

    local row = RenderFrame("Button", card, "BackdropTemplate")
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
    row:SetSize(cardW - 24, rowHeight + 4)
    row:RegisterForClicks("LeftButtonUp")
    row:SetBackdrop(MakeBackdrop())
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(0, 0, 0, 0)

    local hover = RenderTexture(row, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(cr, cg, cb, 0)

    local statusBox = RenderFrame("Frame", row, "BackdropTemplate")
    statusBox:SetSize(14, 14)
    statusBox:SetPoint("LEFT", row, "LEFT", 5, 0)
    statusBox:SetBackdrop(MakeBackdrop())
    statusBox:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * contentAlpha)
    if done then
        statusBox:SetBackdropBorderColor(0.24, 0.76, 0.46, 0.95 * chromeAlpha)
    else
        statusBox:SetBackdropBorderColor(0.24, 0.28, 0.34, 0.95 * chromeAlpha)
    end

    local statusFill = RenderTexture(statusBox, "ARTWORK")
    statusFill:SetPoint("TOPLEFT", statusBox, "TOPLEFT", 2, -2)
    statusFill:SetPoint("BOTTOMRIGHT", statusBox, "BOTTOMRIGHT", -2, 2)
    statusFill:SetColorTexture(done and 0.20 or 0.09, done and 0.72 or 0.10, done and 0.42 or 0.14, (done and 0.85 or 0.70) * contentAlpha)

    local statusCheck = RenderFontString(statusBox, "OVERLAY")
    statusCheck:SetFont(ns.FONT_HEADERS, 9, GetFontFlags())
    statusCheck:SetPoint("CENTER", statusBox, "CENTER", 0, 1)
    statusCheck:SetText("x")
    statusCheck:SetTextColor(0.03, 0.08, 0.04, 1)
    statusCheck:SetShown(done)

    local rowIcon = RenderTexture(row, "ARTWORK")
    rowIcon:SetSize(14, 14)
    rowIcon:SetPoint("LEFT", statusBox, "RIGHT", 6, 0)
    rowIcon:SetTexture(GetEntryIcon(entry))
    rowIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local statusText = RenderFontString(row, "OVERLAY")
    statusText:SetFont(ns.FONT_ROWS, fontSize - 1, GetFontFlags())
    statusText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    statusText:SetWidth(46)
    statusText:SetJustifyH("RIGHT")
    if done then
        statusText:SetText(L["Done"] or "Done")
        statusText:SetTextColor(0.32, 0.80, 0.50, 0.95)
    else
        statusText:SetText("+" .. tostring(KPTotal(entry)))
        statusText:SetTextColor(cr, cg, cb, 0.95)
    end

    local nameText = RenderFontString(row, "OVERLAY")
    nameText:SetFont(ns.FONT_ROWS, fontSize - 1, GetFontFlags())
    nameText:SetPoint("LEFT", rowIcon, "RIGHT", 6, 0)
    nameText:SetPoint("RIGHT", statusText, "LEFT", -8, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    nameText:SetText(EntryDisplayLabel(entry, sectionKey))
    nameText:SetTextColor(done and 0.45 or cr, done and 0.45 or cg, done and 0.45 or cb)

    row:SetScript("OnEnter", function()
        hover:SetColorTexture(cr, cg, cb, 0.12 * accentAlpha)
        MR:ShowProfessionKnowledgeSourceTooltip(row, entry, sectionKey)
    end)
    row:SetScript("OnLeave", function(selfRow)
        hover:SetColorTexture(cr, cg, cb, 0)
        ns.HideOwnedTooltip(selfRow)
    end)
    row:SetScript("OnClick", function()
        MR:SetProfessionKnowledgeWaypoint(entry, sectionKey)
    end)

    return cardY + rowHeight + 6
end

local function RenderReferenceRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, cr, cg, cb, entry, sectionKey)
    local row = RenderFrame("Button", card, "BackdropTemplate")
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
    row:SetSize(cardW - 24, rowHeight + 4)
    row:RegisterForClicks("LeftButtonUp")
    row:SetBackdrop(MakeBackdrop())
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(0, 0, 0, 0)

    local hover = RenderTexture(row, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(cr, cg, cb, 0)

    local statusBox = RenderFrame("Frame", row, "BackdropTemplate")
    statusBox:SetSize(14, 14)
    statusBox:SetPoint("LEFT", row, "LEFT", 5, 0)
    statusBox:SetBackdrop(MakeBackdrop())
    statusBox:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * contentAlpha)
    statusBox:SetBackdropBorderColor(0.24, 0.28, 0.34, 0.95 * chromeAlpha)

    local statusFill = RenderTexture(statusBox, "ARTWORK")
    statusFill:SetPoint("TOPLEFT", statusBox, "TOPLEFT", 2, -2)
    statusFill:SetPoint("BOTTOMRIGHT", statusBox, "BOTTOMRIGHT", -2, 2)
    statusFill:SetColorTexture(0.09, 0.10, 0.14, 0.70 * contentAlpha)

    local rowIcon = RenderTexture(row, "ARTWORK")
    rowIcon:SetSize(14, 14)
    rowIcon:SetPoint("LEFT", statusBox, "RIGHT", 6, 0)
    rowIcon:SetTexture(GetEntryIcon(entry))
    rowIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local kpText = RenderFontString(row, "OVERLAY")
    kpText:SetFont(ns.FONT_ROWS, fontSize - 1, GetFontFlags())
    kpText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    kpText:SetWidth(46)
    kpText:SetJustifyH("RIGHT")
    kpText:SetText("+" .. tostring(entry.kp or 0))
    kpText:SetTextColor(cr, cg, cb, 0.95)

    local nameText = RenderFontString(row, "OVERLAY")
    nameText:SetFont(ns.FONT_ROWS, fontSize - 1, GetFontFlags())
    nameText:SetPoint("LEFT", rowIcon, "RIGHT", 6, 0)
    nameText:SetPoint("RIGHT", kpText, "LEFT", -8, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    nameText:SetText(EntryDisplayLabel(entry, sectionKey))
    nameText:SetTextColor(cr, cg, cb)

    row:SetScript("OnEnter", function()
        hover:SetColorTexture(cr, cg, cb, 0.12 * chromeAlpha)
        MR:ShowProfessionKnowledgeSourceTooltip(row, entry, sectionKey)
    end)
    row:SetScript("OnLeave", function(selfRow)
        hover:SetColorTexture(cr, cg, cb, 0)
        ns.HideOwnedTooltip(selfRow)
    end)
    row:SetScript("OnClick", function()
        MR:SetProfessionKnowledgeWaypoint(entry, sectionKey)
    end)

    return cardY + rowHeight + 6
end

local function RenderCatchupRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, profession, expansion)
    local amount = GetProfessionCatchupAmount(profession, expansion)
    if amount <= 0 then
        return cardY
    end

    local sectionChip = RenderFrame("Frame", card, "BackdropTemplate")
    sectionChip:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
    sectionChip:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -cardY)
    sectionChip:SetHeight(18)
    sectionChip:SetBackdrop(MakeBackdrop())
    sectionChip:SetBackdropColor(0.045, 0.055, 0.095, 0.78 * contentAlpha)
    sectionChip:SetBackdropBorderColor(0, 0, 0, 0)

    local sectionHeader = RenderFontString(sectionChip, "OVERLAY")
    sectionHeader:SetFont(ns.FONT_ROWS, fontSize - 1, GetFontFlags())
    sectionHeader:SetPoint("LEFT", sectionChip, "LEFT", 6, 0)
    sectionHeader:SetPoint("RIGHT", sectionChip, "RIGHT", -8, 0)
    sectionHeader:SetJustifyH("LEFT")
    sectionHeader:SetWordWrap(false)
    sectionHeader:SetTextColor(0.84, 0.70, 0.95, 0.95)
    sectionHeader:SetText(ns.GetRowGroupLabel and ns.GetRowGroupLabel("catchup") or "Catch-Up Knowledge")
    cardY = cardY + 22

    local row = RenderFrame("Frame", card, "BackdropTemplate")
    row:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
    row:SetSize(cardW - 24, rowHeight + 4)
    row:EnableMouse(true)
    row:SetBackdrop(MakeBackdrop())
    row:SetBackdropColor(0, 0, 0, 0)
    row:SetBackdropBorderColor(0, 0, 0, 0)

    local hover = RenderTexture(row, "BACKGROUND")
    hover:SetAllPoints()
    hover:SetColorTexture(cr, cg, cb, 0)

    local statusBox = RenderFrame("Frame", row, "BackdropTemplate")
    statusBox:SetSize(14, 14)
    statusBox:SetPoint("LEFT", row, "LEFT", 5, 0)
    statusBox:SetBackdrop(MakeBackdrop())
    statusBox:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * contentAlpha)
    statusBox:SetBackdropBorderColor(0.24, 0.28, 0.34, 0.95 * chromeAlpha)

    local statusFill = RenderTexture(statusBox, "ARTWORK")
    statusFill:SetPoint("TOPLEFT", statusBox, "TOPLEFT", 2, -2)
    statusFill:SetPoint("BOTTOMRIGHT", statusBox, "BOTTOMRIGHT", -2, 2)
    statusFill:SetColorTexture(0.09, 0.10, 0.14, 0.70 * contentAlpha)

    local icon = RenderTexture(row, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", statusBox, "RIGHT", 6, 0)
    local sharedCatchupItemID = expansion and expansion.sharedCatchupItemID
    local currencyInfo = profession.catchupCurrency and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(profession.catchupCurrency)
    local itemIcon = sharedCatchupItemID and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(sharedCatchupItemID)
    icon:SetTexture(itemIcon or (currencyInfo and currencyInfo.iconFileID) or "Interface\\Icons\\INV_Misc_Coin_01")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local done, max = GetProfessionCatchupProgress(profession)

    local statusText
    if done and max then
        statusText = RenderFontString(row, "OVERLAY")
        statusText:SetFont(ns.FONT_ROWS, fontSize - 1, GetFontFlags())
        statusText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        statusText:SetWidth(56)
        statusText:SetJustifyH("RIGHT")
        statusText:SetText(string.format("%d/%d", done, max))
        if ns.CountColor then
            statusText:SetTextColor(ns.CountColor(done, max))
        else
            statusText:SetTextColor(cr, cg, cb)
        end
    end

    local nameText = RenderFontString(row, "OVERLAY")
    nameText:SetFont(ns.FONT_ROWS, fontSize - 1, GetFontFlags())
    nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    if statusText then
        nameText:SetPoint("RIGHT", statusText, "LEFT", -8, 0)
    else
        nameText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    end
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    nameText:SetText(L["Prof_Catchup"] or "Catch-Up Knowledge")
    nameText:SetTextColor(cr, cg, cb)

    local catchupTooltip = {
        profKnowledgeCatchup = true,
        profKnowledgeProfessionLabel = profession and profession.label,
        profKnowledgeProfessionKey = profession and profession.key,
        profKnowledgeExpansionKey = expansion and expansion.key,
        note = L["Prof_Catchup_Note"],
    }
    row:SetScript("OnEnter", function()
        hover:SetColorTexture(cr, cg, cb, 0.10 * accentAlpha)
        MR:ShowProfessionKnowledgeCatchupTooltip(row, catchupTooltip)
    end)
    row:SetScript("OnLeave", function(selfRow)
        hover:SetColorTexture(cr, cg, cb, 0)
        ns.HideOwnedTooltip(selfRow)
    end)

    return cardY + rowHeight + 10
end

local function RenderProfessionTasksSection(card, cardW, cardY, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, profession, taskRowsOverride, suppressSingleGroupHeader)
    local taskRows = taskRowsOverride or GetProfessionTaskRows(profession, IsProfessionKnowledgeModule)
    if #taskRows == 0 then
        return cardY
    end

    local grouped = {}
    for _, entry in ipairs(taskRows) do
        local group = GetProfessionTaskDisplayGroup(entry.group or entry.category or "other")
        grouped[group] = grouped[group] or {}
        grouped[group][#grouped[group] + 1] = entry
    end

    local rowHeight = math.max(fontSize + 9, 20)

    local function RenderGroupHeader(label)
        local headerFrame = RenderFrame("Frame", card, "BackdropTemplate")
        headerFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
        headerFrame:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -cardY)
        headerFrame:SetHeight(18)
        headerFrame:SetBackdrop(MakeBackdrop())
        headerFrame:SetBackdropColor(0.045, 0.055, 0.095, 0.78 * contentAlpha)
        headerFrame:SetBackdropBorderColor(0, 0, 0, 0)

        local headerText = RenderFontString(headerFrame, "OVERLAY")
        headerText:SetFont(ns.FONT_ROWS, fontSize - 1, GetFontFlags())
        headerText:SetPoint("LEFT", headerFrame, "LEFT", 6, 0)
        headerText:SetPoint("RIGHT", headerFrame, "RIGHT", -8, 0)
        headerText:SetJustifyH("LEFT")
        headerText:SetWordWrap(false)
        headerText:SetText(label)
        headerText:SetTextColor(0.84, 0.70, 0.95, 0.95)
        cardY = cardY + 20
    end

    local function RenderTaskRow(task)
        local row = task.row
        local mod = task.mod
        local catchupDone, catchupMax
        if row.key == "prof_catchup" then
            catchupDone, catchupMax = GetProfessionCatchupProgress(profession)
            if catchupMax then
                task.current = catchupDone or 0
                task.max = catchupMax
                task.done = (catchupDone or 0) >= catchupMax
            else
                task.current = row.itemId and GetItemCountRemaining(row.itemId) or (task.current or 0)
                task.max = nil
                task.done = false
            end
        end

        local rr, rg, rb = cr, cg, cb
        local rowColor = MR:GetRowColor(mod.key, row.key) or (row.colorKey and MR:GetRowColor(mod.key, row.colorKey)) or MR:GetHeaderColor(mod.key)
        if rowColor then
            rr, rg, rb = hex(rowColor)
        end

        local taskFrame = RenderFrame("Button", card, "BackdropTemplate")
        taskFrame:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -cardY)
        taskFrame:SetSize(cardW - 24, rowHeight + 3)
        taskFrame:RegisterForClicks("LeftButtonUp")
        taskFrame:SetBackdrop(MakeBackdrop())
        taskFrame:SetBackdropColor(0, 0, 0, 0)
        taskFrame:SetBackdropBorderColor(0, 0, 0, 0)

        local hover = RenderTexture(taskFrame, "BACKGROUND")
        hover:SetAllPoints()
        hover:SetColorTexture(rr, rg, rb, 0)

        local statusBtn = RenderFrame("Button", taskFrame, "BackdropTemplate")
        statusBtn:SetSize(14, 14)
        statusBtn:SetPoint("LEFT", taskFrame, "LEFT", 5, 0)
        statusBtn:SetBackdrop(MakeBackdrop())

        local statusFill = RenderTexture(statusBtn, "ARTWORK")
        statusFill:SetPoint("TOPLEFT", statusBtn, "TOPLEFT", 2, -2)
        statusFill:SetPoint("BOTTOMRIGHT", statusBtn, "BOTTOMRIGHT", -2, 2)

        local statusCheck = RenderFontString(statusBtn, "OVERLAY")
        statusCheck:SetFont(ns.FONT_HEADERS, 9, GetFontFlags())
        statusCheck:SetPoint("CENTER", statusBtn, "CENTER", 0, 1)
        statusCheck:SetText("x")

        local maxValue = (type(row.max) == "number" and row.max > 0 and row.max)
            or (type(task.max) == "number" and task.max > 0 and task.max)
            or 1
        local canManualToggle = not MR.isForever and not (row.key == "prof_catchup" and not catchupMax)
        local manualOverride = MR:GetManualOverride(mod.key, row.key) or 0
        local forcedComplete = canManualToggle and maxValue and manualOverride >= maxValue
        local activeDone = forcedComplete and maxValue or (task.current or 0)
        local function ApplyStatus()
            statusBtn:SetBackdropColor(0.03, 0.04, 0.06, 0.95 * contentAlpha)
            if forcedComplete then
                statusBtn:SetBackdropBorderColor(0.88, 0.74, 0.22, 0.95 * chromeAlpha)
                statusFill:SetColorTexture(0.88, 0.74, 0.22, 0.85 * contentAlpha)
                statusCheck:SetTextColor(0.10, 0.08, 0.02, 1)
                statusCheck:Show()
            elseif task.done then
                statusBtn:SetBackdropBorderColor(0.24, 0.76, 0.46, 0.95 * chromeAlpha)
                statusFill:SetColorTexture(0.20, 0.72, 0.42, 0.85 * contentAlpha)
                statusCheck:SetTextColor(0.03, 0.08, 0.04, 1)
                statusCheck:Show()
            elseif maxValue and activeDone > 0 then
                statusBtn:SetBackdropBorderColor(0.62, 0.52, 0.22, 0.95 * chromeAlpha)
                statusFill:SetColorTexture(0.78, 0.62, 0.22, 0.70 * contentAlpha)
                statusCheck:Hide()
            else
                statusBtn:SetBackdropBorderColor(0.24, 0.28, 0.34, 0.95 * chromeAlpha)
                statusFill:SetColorTexture(0.09, 0.10, 0.14, 0.70 * contentAlpha)
                statusCheck:Hide()
            end
        end
        ApplyStatus()
        statusBtn:EnableMouse(canManualToggle)

        local rowIcon = RenderTexture(taskFrame, "ARTWORK")
        rowIcon:SetSize(14, 14)
        rowIcon:SetPoint("LEFT", statusBtn, "RIGHT", 6, 0)
        rowIcon:SetTexture(GetEntryIcon(row))
        rowIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        local valueText = RenderFontString(taskFrame, "OVERLAY")
        valueText:SetFont(ns.FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
        valueText:SetPoint("RIGHT", taskFrame, "RIGHT", -8, 0)
        valueText:SetWidth(row.key == "prof_catchup" and 56 or 44)
        valueText:SetJustifyH("RIGHT")
        valueText:SetWordWrap(false)
        if row.key == "prof_catchup" and catchupDone and catchupMax then
            valueText:SetText(string.format("%d/%d", catchupDone, catchupMax))
            if ns.CountColor then
                valueText:SetTextColor(ns.CountColor(catchupDone, catchupMax))
            else
                valueText:SetTextColor(rr, rg, rb, 0.95)
            end
        elseif row.key == "prof_catchup" then
            valueText:SetText(tostring(task.current or 0))
            valueText:SetTextColor(rr, rg, rb, 0.95)
        elseif row.mode == "count" then
            valueText:SetText(string.format("%d/%d", task.current or 0, task.max or maxValue))
            if ns.CountColor then
                valueText:SetTextColor(ns.CountColor(task.current or 0, task.max or maxValue))
            else
                valueText:SetTextColor(rr, rg, rb, 0.95)
            end
        elseif task.done then
            valueText:SetText(L["Done"] or "Done")
            valueText:SetTextColor(0.32, 0.80, 0.50, 0.95)
        elseif (row.kpTotal or 0) > 0 then
            valueText:SetText("+" .. tostring(row.kpTotal))
            valueText:SetTextColor(rr, rg, rb, 0.95)
        else
            valueText:SetText("")
        end

        local nameText = RenderFontString(taskFrame, "OVERLAY")
        nameText:SetFont(ns.FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
        nameText:SetPoint("LEFT", rowIcon, "RIGHT", 6, 0)
        nameText:SetPoint("RIGHT", valueText, "LEFT", -8, 0)
        nameText:SetJustifyH("LEFT")
        nameText:SetWordWrap(false)
        nameText:SetText(StripInlineColor(row.label or mod.label or row.key))
        nameText:SetTextColor(task.done and 0.46 or rr, task.done and 0.46 or rg, task.done and 0.46 or rb, task.done and 0.82 or 1)

        taskFrame:SetScript("OnEnter", function()
            hover:SetColorTexture(rr, rg, rb, 0.10 * accentAlpha)
            if row.profKnowledgeCatchup and MR.ShowProfessionKnowledgeCatchupTooltip then
                MR:ShowProfessionKnowledgeCatchupTooltip(taskFrame, row)
            elseif row.professionKnowledgeEntry or row.profKnowledgeSectionKey then
                MR:ShowProfessionKnowledgeSourceTooltip(taskFrame, row, row.profKnowledgeSectionKey)
            else
                ns.ShowTooltip(taskFrame, {
                    build = function(tooltip)
                        tooltip:SetText(StripInlineColor(row.label or mod.label or row.key), 1, 1, 1)
                        if row.note and row.note ~= "" then
                            tooltip:AddLine(row.note, 0.70, 0.82, 0.92, true)
                        end
                        local target, targetCount = GetWaypointTarget(row, row.key)
                        if target then
                            tooltip:AddLine(" ")
                            if target.label then
                                tooltip:AddLine(target.label, 0.75, 0.90, 1)
                            end
                            tooltip:AddLine(GetGatheringZoneName(target.zone), 0.85, 0.85, 0.85)
                            tooltip:AddLine(string.format(L["Gathering_Coords"], target.x, target.y), 0.7, 1, 0.9)
                            tooltip:AddLine(targetCount > 1 and L["Gathering_ClickCycleHint"] or L["Gathering_ClickWaypoint"], 0.45, 0.85, 1)
                        end
                    end,
                })
            end
        end)
        taskFrame:SetScript("OnLeave", function()
            hover:SetColorTexture(rr, rg, rb, 0)
            ns.HideOwnedTooltip(taskFrame)
        end)
        taskFrame:SetScript("OnClick", function()
            if row.professionKnowledgeEntry or row.profKnowledgeSectionKey then
                MR:SetProfessionKnowledgeWaypoint(row, row.profKnowledgeSectionKey)
                return
            end
            local target, targetCount = GetWaypointTarget(row, row.key)
            if target then
                if targetCount > 1 then
                    waypointLocationIndex[row.key] = ((waypointLocationIndex[row.key] or 1) % targetCount) + 1
                end
                local ok, source = SetGatheringWaypoint(target)
                if ok then
                    print(string.format(L["Waypoint_Set"], source, StripInlineColor(row.label or mod.label or row.key), target.x, target.y))
                else
                    print(L["Waypoint_Unavailable"])
                end
            end
        end)
        statusBtn:SetScript("OnClick", function()
            if not canManualToggle then return end
            local currentOverride = MR:GetManualOverride(mod.key, row.key) or 0
            MR:SetManualOverride(mod.key, row.key, currentOverride >= maxValue and 0 or maxValue, maxValue)
            PK.RebuildGatheringLocationsFrame()
            if MR.RefreshUI then
                MR:RefreshUI()
            end
        end)
        statusBtn:SetScript("OnEnter", function()
            if not canManualToggle then return end
            hover:SetColorTexture(rr, rg, rb, 0.10 * accentAlpha)
            if row.profKnowledgeCatchup and MR.ShowProfessionKnowledgeCatchupTooltip then
                MR:ShowProfessionKnowledgeCatchupTooltip(statusBtn, row)
                return
            elseif row.professionKnowledgeEntry or row.profKnowledgeSectionKey then
                MR:ShowProfessionKnowledgeSourceTooltip(statusBtn, row, row.profKnowledgeSectionKey)
                return
            end

            ns.ShowTooltip(statusBtn, {
                build = function(tooltip)
                    tooltip:SetText(StripInlineColor(row.label or mod.label or row.key), 1, 1, 1)
                    tooltip:AddLine(" ")
                    if forcedComplete then
                        tooltip:AddLine(L["Tooltip_ManualDot_Active"] or "Manually marked complete. Click to clear.", 1, 0.85, 0.1, true)
                    else
                        tooltip:AddLine(L["Tooltip_ManualDot_Hint"] or "Click to manually mark complete.", 0.7, 0.7, 0.7, true)
                    end
                end,
            })
        end)
        statusBtn:SetScript("OnLeave", function()
            hover:SetColorTexture(rr, rg, rb, 0)
            ns.HideOwnedTooltip(statusBtn)
        end)

        cardY = cardY + rowHeight + 3
    end

    for _, group in ipairs(PROFESSION_TASK_GROUP_ORDER) do
        local groupRows = grouped[group]
        if groupRows and #groupRows > 0 then
            if not suppressSingleGroupHeader then
                RenderGroupHeader(GetProfessionTaskGroupLabel(group))
            end
            for _, task in ipairs(groupRows) do
                RenderTaskRow(task)
            end
            cardY = cardY + 3
        end
    end

    return cardY
end

PK.RenderEntryRow = RenderEntryRow
PK.RenderReferenceRow = RenderReferenceRow
PK.RenderCatchupRow = RenderCatchupRow
PK.RenderProfessionTasksSection = RenderProfessionTasksSection
