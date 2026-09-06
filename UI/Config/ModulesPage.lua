local _, ns = ...
local MR = ns.MR
local Config = assert(ns.ConfigInternal, "UI/Config/Frame.lua must load first")
local L = Config.L
local MakeBackdrop = ns.MakeBackdrop
local OptionsGap = ns.OptionsGap
local OptionsCheckbox = ns.OptionsCheckbox
local OptionsColorSwatch = ns.OptionsColorSwatch
local hex = ns.Hex
local GetFontFlags = Config.GetFontFlags

function Config.BuildModulesPage(ctx)
    local f = ctx.frame
    local body = ctx.body
    local yOff = ctx.yOff
    local cfgFs = ctx.cfgFs
    local moduleHeaderFs = ctx.moduleHeaderFs
    local moduleRowFs = ctx.moduleRowFs
    local moduleSubFs = ctx.moduleSubFs
    local moduleHeaderH = ctx.moduleHeaderH
    local moduleRowH = ctx.moduleRowH
    local moduleCompactH = ctx.moduleCompactH
    local contentW = ctx.contentW
    local function Gap(h) yOff = OptionsGap(body, yOff, h) end

    local function IsStoryConfigModule(mod)
        return mod and (mod.configGroup == "story" or (type(mod.key) == "string" and mod.key:match("^story_campaign_")))
    end

    Gap(4)
    local toolbarH = math.max(46, cfgFs + moduleSubFs + 25)
    local toolbar = ns.AcquireFrame(body, "modulesFrame1", "Frame", "BackdropTemplate")
    toolbar:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
    toolbar:SetSize(contentW, toolbarH)
    toolbar:SetBackdrop(MakeBackdrop())
    toolbar:SetBackdropColor(0.018, 0.045, 0.070, 0.72)
    toolbar:SetBackdropBorderColor(0, 0, 0, 0)

    local toolbarEdge = ns.AcquireTexture(toolbar, "modulesTexture40", "ARTWORK")
    toolbarEdge:SetPoint("BOTTOMLEFT", toolbar, "BOTTOMLEFT", 0, 0)
    toolbarEdge:SetPoint("BOTTOMRIGHT", toolbar, "BOTTOMRIGHT", 0, 0)
    toolbarEdge:SetHeight(1)
    toolbarEdge:SetColorTexture(0.12, 0.46, 0.48, 0.72)

    local toolbarTitle = ns.AcquireFontString(toolbar, "modulesText22", "OVERLAY")
    toolbarTitle:SetFont(ns.FONT_HEADERS, cfgFs, GetFontFlags())
    toolbarTitle:SetPoint("TOPLEFT", toolbar, "TOPLEFT", 8, -6)
    toolbarTitle:SetText(string.upper(L["Config_TabModules"] or "Modules"))
    toolbarTitle:SetTextColor(0.38, 0.98, 0.88)

    local toolbarHint = ns.AcquireFontString(toolbar, "modulesText23", "OVERLAY")
    toolbarHint:SetFont(ns.FONT_ROWS, moduleSubFs, GetFontFlags())
    toolbarHint:SetPoint("BOTTOMLEFT", toolbar, "BOTTOMLEFT", 8, 5)
    toolbarHint:SetPoint("BOTTOMRIGHT", toolbar, "BOTTOMRIGHT", -8, 5)
    toolbarHint:SetJustifyH("LEFT")
    toolbarHint:SetWordWrap(false)
    toolbarHint:SetText(L["Config_ModulesToolbarHint"] or "Enable, customize, or drag modules to reorder")
    toolbarHint:SetTextColor(0.50, 0.68, 0.70)
    yOff = yOff - toolbarH
    Gap(6)

    if not MR._cfgExpanded then MR._cfgExpanded = {} end

    local function RebuildExpandedState()
        local scroll = f.scroll
        local previousScroll = scroll and scroll:GetVerticalScroll() or 0
        MR:PopulateConfigFrame(f)
        if scroll then
            local scrollChild = scroll:GetScrollChild()
            local contentHeight = scrollChild and scrollChild:GetHeight() or 0
            local maxScroll = math.max(contentHeight - scroll:GetHeight(), 0)
            scroll:SetVerticalScroll(math.max(0, math.min(previousScroll, maxScroll)))
            if f.UpdateScrollBar then f.UpdateScrollBar() end
        end
    end

    local drag = { active = false, srcKey = nil, targetIdx = nil, mode = "module", moduleKey = nil, configGroup = nil }

    local dragGhost = ns.AcquireFrame(body, "modulesFrame2", "Frame", "BackdropTemplate")
    dragGhost:SetHeight(20)
    dragGhost:SetFrameStrata("TOOLTIP")
    dragGhost:SetBackdrop(MakeBackdrop())
    dragGhost:SetBackdropColor(0.08, 0.28, 0.22, 0.95)
    dragGhost:SetBackdropBorderColor(0.2, 0.9, 0.65, 1)
    dragGhost:Hide()
    local dragGhostLbl = ns.AcquireFontString(dragGhost, "modulesText24", "OVERLAY")
    dragGhostLbl:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
    dragGhostLbl:SetPoint("LEFT", dragGhost, "LEFT", 8, 0)
    dragGhostLbl:SetTextColor(0.3, 1, 0.75)

    local dragLine = ns.AcquireFrame(body, "modulesFrame3", "Frame")
    dragLine:SetHeight(2)
    dragLine:SetFrameStrata("TOOLTIP")
    dragLine:Hide()
    local dragLineTex = ns.AcquireTexture(dragLine, "modulesTexture41", "OVERLAY")
    dragLineTex:SetAllPoints()
    dragLineTex:SetColorTexture(0.2, 0.9, 0.65, 1)

    local orderedMods = MR:GetOrderedMainModules()
    local _allMods = {}
    for _, mod in ipairs(orderedMods) do
        _allMods[#_allMods + 1] = mod
    end

    local _cfgModuleRows = {}
    local _cfgRowRows = {}

    local function FormatReleaseSuffix(patchKey)
        if not patchKey then
            return nil
        end
        local patchInfo = MR:GetPatchInfo(patchKey)
        return "|cff667788(" .. (patchInfo.shortLabel or patchInfo.key or patchKey) .. ")|r"
    end

    local function FormatModuleConfigLabel(mod, includePatch)
        if includePatch == false then
            return mod.label or mod.key
        end
        local suffix = FormatReleaseSuffix(MR:GetModulePatchKey(mod))
        if suffix then
            return string.format("%s  %s", mod.label or mod.key, suffix)
        end
        return mod.label or mod.key
    end

    local function FormatRowConfigLabel(mod, row)
        local cleanLabel = (row.label or row.key):gsub("|c%x%x%x%x%x%x%x%x(.-)%|r", "%1"):gsub("|[cCrR]%x*", "")
        local rowPatchKey = MR:GetRowPatchKey(mod, row)
        local suffix = rowPatchKey ~= MR:GetModulePatchKey(mod) and FormatReleaseSuffix(rowPatchKey) or nil
        if suffix then
            return string.format("%s  %s", cleanLabel, suffix)
        end
        return cleanLabel
    end

    local function BuildPatchHeader(patchKey, modKey)
        local patchInfo = MR:GetPatchInfo(patchKey)
        local available = MR:IsPatchAvailable(patchKey)
        local enabled = MR:IsPatchEnabled(patchKey, modKey)
        local ROW_H = moduleHeaderH
        local patchFr = ns.AcquireFrame(body, "modulesFrame4", "Frame", "BackdropTemplate")
        patchFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
        patchFr:SetSize(contentW, ROW_H)
        patchFr:SetBackdrop(MakeBackdrop())
        patchFr:SetBackdropColor(enabled and 0.07 or 0.08, enabled and 0.17 or 0.07, enabled and 0.22 or 0.08, 0.95)
        patchFr:SetBackdropBorderColor(enabled and 0.20 or 0.35, enabled and 0.62 or 0.18, enabled and 0.70 or 0.18, 1)

        local cb = ns.AcquireFrame(patchFr, "modulesFrame5", "CheckButton", "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("LEFT", patchFr, "LEFT", 2, 0)
        cb:SetChecked(enabled)
        cb:SetEnabled(available)
        cb:SetAlpha(available and 1 or 0.45)
        cb:SetScript("OnClick", function(s)
            MR:SetPatchEnabled(patchKey, modKey, s:GetChecked(), true)
            if MR.RequestConfigRefresh then
                MR:RequestConfigRefresh()
            else
                MR:RefreshUI()
            end
        end)

        local lbl = ns.AcquireFontString(patchFr, "modulesText25", "OVERLAY")
        lbl:SetFont(ns.FONT_HEADERS, moduleHeaderFs, GetFontFlags())
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        lbl:SetPoint("RIGHT", patchFr, "RIGHT", -8, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)
        local status = available and (L["Config_PatchFilter"] or "Patch filter")
            or (L["Config_ComingSoon"] or "Coming soon")
        lbl:SetText((patchInfo.label or patchKey) .. "  |cff667788" .. status .. "|r")
        lbl:SetTextColor(enabled and 0.82 or 0.45, enabled and 0.98 or 0.48, enabled and 0.95 or 0.50)

        yOff = yOff - ROW_H
    end

    local function ShouldShowModulePatchHeader(patchKey)
        return patchKey and patchKey ~= "12.0.7"
    end

    local function GetConfigRowsForModule(mod)
        local orderedRows = MR.GetOrderedRows and MR:GetOrderedRows(mod) or (mod.rows or {})
        local rows = {}
        for _, row in ipairs(orderedRows) do
            local visible = not row.isVisible or row.isVisible()
            if (not row.control or (mod.key == "custom_tasks" and row.configGroup)) and visible then
                rows[#rows + 1] = row
            end
        end

        return rows
    end

    local function BuildRowPatchHeader(patchKey, modKey)
        local patchInfo = MR:GetPatchInfo(patchKey)
        local available = MR:IsPatchAvailable(patchKey)
        local enabled = MR:IsPatchEnabled(patchKey, modKey)
        local ROW_H = moduleRowH
        local patchFr = ns.AcquireFrame(body, "modulesFrame6", "Frame", "BackdropTemplate")
        patchFr:SetPoint("TOPLEFT", body, "TOPLEFT", 18, yOff)
        patchFr:SetSize(contentW - 20, ROW_H)
        patchFr:SetBackdrop(MakeBackdrop())
        patchFr:SetBackdropColor(enabled and 0.05 or 0.07, enabled and 0.13 or 0.06, enabled and 0.16 or 0.07, 0.88)
        patchFr:SetBackdropBorderColor(enabled and 0.16 or 0.30, enabled and 0.42 or 0.16, enabled and 0.48 or 0.16, 0.9)

        local cb = ns.AcquireFrame(patchFr, "modulesFrame7", "CheckButton", "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("LEFT", patchFr, "LEFT", 0, 0)
        cb:SetChecked(enabled)
        cb:SetEnabled(available)
        cb:SetAlpha(available and 1 or 0.45)
        cb:SetScript("OnClick", function(s)
            MR:SetPatchEnabled(patchKey, modKey, s:GetChecked(), true)
            if MR.RequestConfigRefresh then
                MR:RequestConfigRefresh()
            else
                MR:RefreshUI()
            end
        end)

        local lbl = ns.AcquireFontString(patchFr, "modulesText26", "OVERLAY")
        lbl:SetFont(ns.FONT_HEADERS, moduleRowFs, GetFontFlags())
        lbl:SetPoint("LEFT", cb, "RIGHT", 1, 0)
        lbl:SetPoint("RIGHT", patchFr, "RIGHT", -6, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetWordWrap(false)
        local status = available and (L["Config_PatchFilter"] or "Patch filter")
            or (L["Config_ComingSoon"] or "Coming soon")
        lbl:SetText((patchInfo.label or patchKey) .. "  |cff667788" .. status .. "|r")
        lbl:SetTextColor(enabled and 0.72 or 0.42, enabled and 0.90 or 0.46, enabled and 0.88 or 0.48)

        yOff = yOff - ROW_H
    end

    local function BuildRowGroupHeader(modKey, groupRows, label)
        local enabled = MR:IsRowGroupEnabled(modKey, groupRows)
        local ROW_H = moduleRowH
        local groupFr = ns.AcquireFrame(body, "modulesFrame8", "Frame", "BackdropTemplate")
        groupFr:SetPoint("TOPLEFT", body, "TOPLEFT", 18, yOff)
        groupFr:SetSize(contentW - 20, ROW_H)
        groupFr:SetBackdrop(MakeBackdrop())
        groupFr:SetBackdropColor(enabled and 0.05 or 0.07, enabled and 0.13 or 0.06, enabled and 0.16 or 0.07, 0.88)
        groupFr:SetBackdropBorderColor(enabled and 0.16 or 0.30, enabled and 0.42 or 0.16, enabled and 0.48 or 0.16, 0.9)

        local cb = ns.AcquireFrame(groupFr, "modulesFrame9", "CheckButton", "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("LEFT", groupFr, "LEFT", 0, 0)
        cb:SetChecked(enabled)
        cb:SetScript("OnClick", function(s)
            MR:SetRowGroupEnabled(modKey, groupRows, s:GetChecked())
            if MR.RequestConfigRepopulate then
                MR:RequestConfigRepopulate(f, 0.04)
            else
                MR:PopulateConfigFrame(f)
            end
        end)

        local lbl = ns.AcquireFontString(groupFr, "modulesText27", "OVERLAY")
        lbl:SetFont(ns.FONT_HEADERS, moduleRowFs, GetFontFlags())
        lbl:SetPoint("LEFT", cb, "RIGHT", 1, 0)
        lbl:SetPoint("RIGHT", groupFr, "RIGHT", -6, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(label)
        lbl:SetTextColor(enabled and 0.72 or 0.42, enabled and 0.90 or 0.46, enabled and 0.88 or 0.48)

        yOff = yOff - ROW_H
    end

    local function BuildCustomTaskGroupHeader(modKey, resetType, configGroup)
        local groupRows = configGroup.rows
        local headerRow
        for _, row in ipairs(groupRows) do
            if row.sectionHeader then
                headerRow = row
                break
            end
        end
        local enabled = MR:IsRowGroupEnabled(modKey, groupRows)
        local expandedKey = "__custom_task_group:" .. resetType
        local expanded = MR._cfgExpanded[expandedKey] ~= false
        local styleKey = headerRow and headerRow.headerBackgroundKey or ("custom_tasks_section_" .. resetType)
        local defaultColor = headerRow and headerRow.labelColor or "#a987d9"
        local ROW_H = moduleHeaderH
        local groupFr = ns.AcquireFrame(body, "modulesFrame10", "Frame", "BackdropTemplate")
        groupFr:SetPoint("TOPLEFT", body, "TOPLEFT", 18, yOff)
        groupFr:SetSize(contentW - 20, ROW_H)
        groupFr:SetBackdrop(MakeBackdrop())

        local function ApplyBackdrop()
            local background = MR:GetHeaderBackgroundColor(styleKey)
            if background then
                local br, bg, bb = hex(background)
                groupFr:SetBackdropColor(br, bg, bb, enabled and 0.88 or 0.52)
            else
                groupFr:SetBackdropColor(enabled and 0.035 or 0.055, enabled and 0.085 or 0.045, enabled and 0.095 or 0.050, 0.88)
            end
            local cr, cg, cb = hex(MR:GetRowColor(modKey, headerRow.key) or defaultColor)
            groupFr:SetBackdropBorderColor(cr * 0.42, cg * 0.42, cb * 0.42, enabled and 0.90 or 0.48)
        end

        local checkbox = ns.AcquireFrame(groupFr, "modulesFrame11", "CheckButton", "UICheckButtonTemplate")
        checkbox:SetSize(20, 20)
        checkbox:SetPoint("LEFT", groupFr, "LEFT", 1, 0)
        checkbox:SetChecked(enabled)
        checkbox:SetScript("OnClick", function(s)
            MR:SetRowGroupEnabled(modKey, groupRows, s:GetChecked())
            RebuildExpandedState()
        end)

        local expandBtn = ns.AcquireFrame(groupFr, "modulesFrame12", "Button")
        expandBtn:SetSize(20, 20)
        expandBtn:SetPoint("RIGHT", groupFr, "RIGHT", -2, 0)
        local expandLbl = ns.AcquireFontString(expandBtn, "modulesText28", "OVERLAY")
        expandLbl:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
        expandLbl:SetPoint("CENTER", expandBtn, "CENTER", 0, 1)
        expandLbl:SetText(expanded and "v" or ">")
        expandLbl:SetTextColor(0.45, 0.75, 0.70)
        expandBtn:SetScript("OnClick", function()
            MR._cfgExpanded[expandedKey] = not expanded
            RebuildExpandedState()
        end)
        expandBtn:SetScript("OnEnter", function()
            expandLbl:SetTextColor(1, 1, 1)
            ns.ShowTooltip(expandBtn, { text = L["Config_ExpandCollapseRows"] })
        end)
        expandBtn:SetScript("OnLeave", function()
            expandLbl:SetTextColor(0.45, 0.75, 0.70)
            ns.HideOwnedTooltip(expandBtn)
        end)

        local hideBtn = ns.AcquireFrame(groupFr, "modulesFrame13", "Button", "BackdropTemplate")
        hideBtn:SetSize(16, 16)
        hideBtn:SetPoint("RIGHT", expandBtn, "LEFT", -2, 0)
        hideBtn:SetBackdrop(MakeBackdrop())
        local hideLbl = ns.AcquireFontString(hideBtn, "modulesText29", "OVERLAY")
        hideLbl:SetFont(ns.FONT_ROWS, 8, GetFontFlags())
        hideLbl:SetPoint("CENTER")
        local function ApplyHideState(hovered)
            local active = MR:IsCustomTaskGroupHideComplete(resetType)
            hideBtn:SetBackdropColor(hovered and 0.08 or 0.05, hovered and 0.22 or 0.10, hovered and 0.32 or 0.18, 1)
            hideBtn:SetBackdropBorderColor(hovered and 0.25 or (active and 0.15 or 0.35), hovered and 0.85 or (active and 0.32 or 0.12), hovered and 0.72 or (active and 0.38 or 0.12), 1)
            hideLbl:SetText(active and "H" or "S")
            hideLbl:SetTextColor(hovered and 1 or (active and 0.45 or 0.55), hovered and 1 or (active and 0.75 or 0.25), hovered and 1 or (active and 0.70 or 0.25))
        end
        ApplyHideState(false)
        hideBtn:SetScript("OnClick", function()
            MR:SetCustomTaskGroupHideComplete(resetType, not MR:IsCustomTaskGroupHideComplete(resetType))
            RebuildExpandedState()
        end)
        hideBtn:SetScript("OnEnter", function()
            ApplyHideState(true)
            ns.ShowTooltip(hideBtn, { text = MR:IsCustomTaskGroupHideComplete(resetType) and L["Config_RowsCollapsed"] or L["Config_RowsShown"] })
        end)
        hideBtn:SetScript("OnLeave", function()
            ApplyHideState(false)
            ns.HideOwnedTooltip(hideBtn)
        end)

        local lbl
        local background = MR:GetHeaderBackgroundColor(styleKey)
        local br, bg, bb = 0.06, 0.08, 0.13
        if background then
            br, bg, bb = hex(background)
        end
        local backgroundSwatch = OptionsColorSwatch(groupFr, br, bg, bb, function(r, g, b)
            MR:SetHeaderBackgroundColor(styleKey, string.format("#%02x%02x%02x", r * 255, g * 255, b * 255))
            ApplyBackdrop()
        end, function()
            MR:ResetHeaderBackgroundColor(styleKey)
            ApplyBackdrop()
            return 0.06, 0.08, 0.13
        end, L["Config_HeaderBackgroundColor"] or "Header Background")
        backgroundSwatch:SetSize(14, 14)
        backgroundSwatch:SetPoint("RIGHT", hideBtn, "LEFT", -2, 0)

        local tr, tg, tb = hex(MR:GetRowColor(modKey, headerRow.key) or defaultColor)
        local colorSwatch = OptionsColorSwatch(groupFr, tr, tg, tb, function(r, g, b)
            MR:SetRowColor(modKey, headerRow.key, string.format("#%02x%02x%02x", r * 255, g * 255, b * 255))
            if lbl then lbl:SetTextColor(r, g, b) end
            ApplyBackdrop()
        end, function()
            MR:ResetRowColor(modKey, headerRow.key)
            if lbl then lbl:SetTextColor(hex(defaultColor)) end
            ApplyBackdrop()
            return hex(defaultColor)
        end, L["Config_HeaderColor"])
        colorSwatch:SetSize(14, 14)
        colorSwatch:SetPoint("RIGHT", backgroundSwatch, "LEFT", -2, 0)

        lbl = ns.AcquireFontString(groupFr, "modulesText30", "OVERLAY")
        lbl:SetFont(ns.FONT_ROWS, moduleRowFs, GetFontFlags())
        lbl:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
        lbl:SetPoint("RIGHT", colorSwatch, "LEFT", -2, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(configGroup.label or resetType)
        local lr, lg, lb = hex(MR:GetRowColor(modKey, headerRow.key) or defaultColor)
        lbl:SetTextColor(enabled and lr or 0.42, enabled and lg or 0.46, enabled and lb or 0.48)

        ApplyBackdrop()
        yOff = yOff - ROW_H
        return expanded
    end

    local CommitDrag

    local function GetActiveDragRows()
        if drag.mode == "row" and drag.moduleKey then
            local rows = _cfgRowRows[drag.moduleKey] or {}
            if drag.configGroup then
                local filtered = {}
                for _, row in ipairs(rows) do
                    if row.configGroup == drag.configGroup then
                        filtered[#filtered + 1] = row
                    end
                end
                return filtered
            end
            return rows
        end
        if drag.mode == "module" and drag.srcKey then
            local sourceMod = MR.moduleByKey and MR.moduleByKey[drag.srcKey]
            if sourceMod then
                local sourceProfession = sourceMod.profSkillLine ~= nil
                local sourceStory = IsStoryConfigModule(sourceMod)
                local sourceExpansion = MR:GetModuleExpansionKey(sourceMod)
                local filtered = {}
                for _, row in ipairs(_cfgModuleRows) do
                    local rowMod = MR.moduleByKey and MR.moduleByKey[row.key]
                    if rowMod then
                        local sameCategory = (rowMod.profSkillLine ~= nil) == sourceProfession
                            and IsStoryConfigModule(rowMod) == sourceStory
                        local sameExpansion = not sourceProfession or MR:GetModuleExpansionKey(rowMod) == sourceExpansion
                        if sameCategory and sameExpansion then
                            filtered[#filtered + 1] = row
                        end
                    end
                end
                return filtered
            end
        end
        return _cfgModuleRows
    end

    local function DragOnUpdate()
        if not drag.active then return end
        if not IsMouseButtonDown("LeftButton") then
            if CommitDrag then
                CommitDrag()
            end
            return
        end
        local rows = GetActiveDragRows()
        if #rows == 0 then return end

        local _, cy = GetCursorPosition()
        local scale  = body:GetEffectiveScale()
        local bLeft  = body:GetLeft()
        local bTop   = body:GetTop()
        if not bLeft or not bTop then return end
        local localY = bTop - cy / scale

        dragGhost:ClearAllPoints()
        dragGhost:SetPoint("TOPLEFT",  body, "TOPLEFT", 4,       -localY + 10)
        dragGhost:SetPoint("TOPRIGHT", body, "TOPRIGHT", -4,     -localY + 10)
        dragGhost:Show()

        local screenCY = cy / UIParent:GetEffectiveScale()
        local slot = #rows
        for i, row in ipairs(rows) do
            local rTop = row.frame:GetTop()
            local rBot = row.frame:GetBottom()
            if rTop and rBot then
                local mid = (rTop + rBot) / 2
                if screenCY > mid then
                    slot = i - 1
                    break
                end
            end
        end
        slot = math.max(0, math.min(slot, #rows))
        drag.targetIdx = slot

        local lineRefFrame
        local lineAtBottom = false
        if slot == 0 then
            lineRefFrame = rows[1].frame
            lineAtBottom = false
        elseif slot >= #rows then
            lineRefFrame = rows[#rows].frame
            lineAtBottom = true
        else
            lineRefFrame = rows[slot].frame
            lineAtBottom = true
        end

        if lineRefFrame then
            local lY = lineAtBottom and (lineRefFrame:GetBottom() or 0) or (lineRefFrame:GetTop() or 0)
            local lLeft  = lineRefFrame:GetLeft()  or 0
            local lRight = lineRefFrame:GetRight() or 0
            local bodyTop   = body:GetTop() or 0
            local bodyLeft  = body:GetLeft() or 0
            local lineBodyY = -(bodyTop - lY)
            local lineBodyL = lLeft - bodyLeft
            local lineBodyR = lRight - bodyLeft
            dragLine:ClearAllPoints()
            dragLine:SetPoint("TOPLEFT",  body, "TOPLEFT", lineBodyL, lineBodyY)
            dragLine:SetPoint("TOPRIGHT", body, "TOPLEFT", lineBodyR, lineBodyY)
            dragLine:Show()
        end

        for _, row in ipairs(rows) do
            row.frame:SetAlpha(row.key == drag.srcKey and 0.3 or 1.0)
        end
    end

    CommitDrag = function()
        if not drag.active then return end
        local rows = GetActiveDragRows()
        local mode, moduleKey = drag.mode, drag.moduleKey
        drag.active = false
        f:SetScript("OnUpdate", nil)
        for _, row in ipairs(rows) do row.frame:SetAlpha(1) end
        dragGhost:Hide()
        dragLine:Hide()

        local slot = drag.targetIdx
        if slot == nil then
            drag.srcKey = nil
            drag.targetIdx = nil
            drag.mode = "module"
            drag.moduleKey = nil
            drag.configGroup = nil
            MR:PopulateConfigFrame(f)
            return
        end

        if mode == "row" then
            local targetRow
            local afterTarget = false
            if slot == 0 then
                targetRow = rows[1]
            elseif slot >= #rows then
                targetRow = rows[#rows]
                afterTarget = true
            else
                targetRow = rows[slot]
                afterTarget = true
            end

            if moduleKey and targetRow and targetRow.key and MR.SetModuleRowPosition then
                MR:SetModuleRowPosition(moduleKey, drag.srcKey, targetRow.key, afterTarget)
            end
            drag.srcKey = nil
            drag.targetIdx = nil
            drag.mode = "module"
            drag.moduleKey = nil
            drag.configGroup = nil
            MR:PopulateConfigFrame(f)
            return
        end

        local allMods = MR:GetOrderedModules("all")
        local visMods = {}
        for _, row in ipairs(rows) do
            for _, m in ipairs(allMods) do
                if m.key == row.key then table.insert(visMods, m); break end
            end
        end
        local srcIdx = nil
        for i, m in ipairs(visMods) do
            if m.key == drag.srcKey then srcIdx = i; break end
        end
        if not srcIdx then MR:PopulateConfigFrame(f); return end

        local insertAt = slot + 1
        if srcIdx < insertAt then insertAt = insertAt - 1 end
        insertAt = math.max(1, math.min(insertAt, #visMods))

        if srcIdx ~= insertAt then
            local moved = table.remove(visMods, srcIdx)
            table.insert(visMods, insertAt, moved)
            local inCfgRows = {}
            for _, row in ipairs(rows) do inCfgRows[row.key] = true end
            local newOrder = {}
            local vi = 1
            for _, m in ipairs(allMods) do
                if inCfgRows[m.key] then
                    table.insert(newOrder, visMods[vi].key); vi = vi + 1
                else
                    table.insert(newOrder, m.key)
                end
            end
            MR:SetModuleOrder(newOrder, "all")
            MR:RefreshUI()
        end
        drag.srcKey = nil; drag.targetIdx = nil; drag.mode = "module"; drag.moduleKey = nil; drag.configGroup = nil
        MR:PopulateConfigFrame(f)
    end

    local professionExpandedKey = "__professions"
    local storyExpandedKey = "__storyCampaigns"
    local professionGroupRendered = false
    local professionGroupOpen = MR._cfgExpanded[professionExpandedKey] == true
    local professionTotal, professionKnown, professionModuleTotal, professionEnabled = 0, 0, 0, 0
    local storyGroupRendered = false
    if MR._cfgExpanded[storyExpandedKey] == nil then
        MR._cfgExpanded[storyExpandedKey] = true
    end
    local storyGroupOpen = MR._cfgExpanded[storyExpandedKey] == true
    local storyTotal, storyEnabled = 0, 0
    local professionSource = MR.GetMainFrameProgressSource and MR:GetMainFrameProgressSource() or nil

    local function IsProfessionKnownForConfig(profession)
        if not profession then
            return false
        end
        if ns.IsProfessionLearnedForSource then
            return ns.IsProfessionLearnedForSource(profession, professionSource)
        end
        return not MR.HasProfessionForModule or MR:HasProfessionForModule(profession.skillLine, professionSource)
    end
    local function IsProfessionModuleKnownForConfig(mod)
        if not mod or not mod.profSkillLine then
            return true
        end
        return not MR.HasProfessionForModule or MR:HasProfessionForModule(mod.profSkillLine, professionSource)
    end
    for _, expansion in ipairs(ns.AllExpansions or {}) do
        for _, profession in ipairs(expansion.professions or {}) do
            professionTotal = professionTotal + 1
            if IsProfessionKnownForConfig(profession) then
                professionKnown = professionKnown + 1
            end
        end
    end
    for _, mod in ipairs(_allMods) do
        if mod.profSkillLine and IsProfessionModuleKnownForConfig(mod) then
            professionModuleTotal = professionModuleTotal + 1
            if MR:IsModuleEnabled(mod.key) then
                professionEnabled = professionEnabled + 1
            end
        elseif IsStoryConfigModule(mod) then
            storyTotal = storyTotal + 1
            if MR:IsModuleEnabled(mod.key) then
                storyEnabled = storyEnabled + 1
            end
        end
    end

    local function BuildProfessionGroupHeader()
        local ROW_H = math.max(42, moduleHeaderFs + moduleSubFs + 17)
        local professionTitle = (L["ProfKnowledge_Title"] or "Profession Knowledge"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        Config.CreateProfessionGroupControl({
            parent = body,
            x = 4,
            y = yOff,
            width = contentW,
            height = ROW_H,
            headerFontSize = moduleHeaderFs,
            subFontSize = moduleSubFs,
            title = professionTitle,
            subtitle = string.format(L["ProfKnowledge_LearnedProfessions"] or "Learned professions %d/%d", professionKnown, professionTotal),
            expanded = professionGroupOpen,
            moduleCount = professionModuleTotal,
            allEnabled = professionModuleTotal > 0 and professionEnabled >= professionModuleTotal,
            onSetEnabled = function(enabled)
                for _, professionMod in ipairs(_allMods) do
                    if professionMod.profSkillLine and IsProfessionModuleKnownForConfig(professionMod) then
                        MR:SetModuleEnabled(professionMod.key, enabled, true)
                    end
                end
                MR:RefreshUI()
                RebuildExpandedState()
            end,
            onToggleExpanded = function()
                MR._cfgExpanded[professionExpandedKey] = not professionGroupOpen
                RebuildExpandedState()
            end,
        })

        yOff = yOff - ROW_H - 3
    end

    local function BuildStoryGroupHeader()
        if storyTotal <= 0 then
            return
        end

        local ROW_H = math.max(22, cfgFs + 10)
        local headerFr = ns.AcquireFrame(body, "modulesFrame18", "Frame", "BackdropTemplate")
        headerFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
        headerFr:SetSize(contentW, ROW_H)
        headerFr:SetBackdrop(MakeBackdrop())
        headerFr:SetBackdropColor(0.105, 0.090, 0.035, 0.96)
        headerFr:SetBackdropBorderColor(0.52, 0.42, 0.14, 0.96)

        local groupToggle = ns.AcquireFrame(headerFr, "modulesFrame19", "CheckButton", "UICheckButtonTemplate")
        groupToggle:SetSize(18, 18)
        groupToggle:SetPoint("LEFT", headerFr, "LEFT", 1, 0)
        groupToggle:SetChecked(storyTotal > 0 and storyEnabled >= storyTotal)
        groupToggle:SetScript("OnClick", function(control)
            local enabled = control:GetChecked() and true or false
            for _, expansion in ipairs(MR:GetSelectableExpansions()) do
                MR:SetStoryCampaignsEnabledPreference(enabled, expansion.key)
            end
            for _, storyMod in ipairs(_allMods) do
                if IsStoryConfigModule(storyMod) then
                    MR:SetModuleEnabled(storyMod.key, enabled, true)
                end
            end
            MR:RefreshUI()
            RebuildExpandedState()
        end)

        local arrowBtn = ns.AcquireFrame(headerFr, "modulesFrame20", "Button")
        arrowBtn:SetSize(22, 22)
        arrowBtn:SetPoint("RIGHT", headerFr, "RIGHT", -3, 0)

        local arrowLbl = ns.AcquireFontString(arrowBtn, "modulesText35", "OVERLAY")
        arrowLbl:SetFont(ns.FONT_HEADERS, 13, GetFontFlags())
        arrowLbl:SetPoint("CENTER", arrowBtn, "CENTER", 0, 1)
        arrowLbl:SetText(storyGroupOpen and "v" or ">")
        arrowLbl:SetTextColor(0.90, 0.82, 0.42)

        local lbl = ns.AcquireFontString(headerFr, "modulesText36", "OVERLAY")
        lbl:SetFont(ns.FONT_HEADERS, moduleHeaderFs, GetFontFlags())
        lbl:SetPoint("LEFT", groupToggle, "RIGHT", 1, 0)
        lbl:SetPoint("RIGHT", headerFr, "RIGHT", -68, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(L["Config_StoryCampaignsSection"] or "STORY CAMPAIGNS")
        lbl:SetTextColor(0.95, 0.88, 0.56)

        local countLbl = ns.AcquireFontString(headerFr, "modulesText37", "OVERLAY")
        countLbl:SetFont(ns.FONT_ROWS, moduleSubFs, GetFontFlags())
        countLbl:SetPoint("RIGHT", arrowBtn, "LEFT", -7, 0)
        countLbl:SetText(string.format("%d/%d", storyEnabled, storyTotal))
        countLbl:SetTextColor(0.62, 0.58, 0.38)

        local function ToggleStoryGroup()
            MR._cfgExpanded[storyExpandedKey] = not storyGroupOpen
            arrowLbl:SetText(MR._cfgExpanded[storyExpandedKey] and "v" or ">")
            RebuildExpandedState()
        end

        headerFr:EnableMouse(true)
        headerFr:SetScript("OnMouseUp", ToggleStoryGroup)
        arrowBtn:SetScript("OnClick", ToggleStoryGroup)
        arrowBtn:SetScript("OnEnter", function()
            arrowLbl:SetTextColor(1, 1, 1)
        end)
        arrowBtn:SetScript("OnLeave", function()
            arrowLbl:SetTextColor(0.90, 0.82, 0.42)
        end)

        yOff = yOff - ROW_H
    end

    local function StartModuleDrag(mod, key)
        if drag.active then return end
        drag.active = true
        f:SetScript("OnUpdate", DragOnUpdate)
        drag.mode = "module"
        drag.moduleKey = nil
        drag.configGroup = nil
        drag.srcKey = key
        drag.targetIdx = nil
        dragGhostLbl:SetText(mod.label)
    end

    local function StartRowDrag(mod, row, owner)
        if drag.active then return end
        drag.active = true
        f:SetScript("OnUpdate", DragOnUpdate)
        drag.mode = "row"
        drag.moduleKey = mod.key
        drag.configGroup = row.configGroup
        drag.srcKey = row.key
        drag.targetIdx = nil
        dragGhostLbl:SetText(FormatRowConfigLabel(mod, row))
        ns.HideOwnedTooltip(owner)
    end

    local function ToggleModuleExpanded(key)
        MR._cfgExpanded[key] = not MR._cfgExpanded[key]
        RebuildExpandedState()
    end

    local function BuildProfessionExpansionHeader(expansionKey)
        local expansionInfo = MR:GetExpansionInfo(expansionKey)
        local stateKey = "__profession_expansion:" .. expansionKey
        local isExpanded = MR._cfgExpanded[stateKey] ~= false
        local frame = ns.AcquireFrame(body, "modulesFrame21", "Button", "BackdropTemplate")
        frame:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        frame:SetSize(contentW - 4, moduleRowH)
        frame:SetBackdrop(MakeBackdrop())
        frame:SetBackdropColor(0.035, 0.055, 0.070, 0.90)
        frame:SetBackdropBorderColor(0.14, 0.30, 0.34, 0.78)
        frame:RegisterForClicks("LeftButtonUp")

        local label = ns.AcquireFontString(frame, "modulesText38", "OVERLAY")
        label:SetFont(ns.FONT_HEADERS, moduleRowFs, GetFontFlags())
        label:SetPoint("LEFT", frame, "LEFT", 7, 0)
        label:SetPoint("RIGHT", frame, "RIGHT", -24, 0)
        label:SetJustifyH("LEFT")
        label:SetText((expansionInfo and (expansionInfo.shortLabel or expansionInfo.label or expansionInfo.key)) or expansionKey)
        label:SetTextColor(0.72, 0.86, 0.88)

        local arrow = ns.AcquireFontString(frame, "modulesText39", "OVERLAY")
        arrow:SetFont(ns.FONT_HEADERS, moduleRowFs, GetFontFlags())
        arrow:SetPoint("RIGHT", frame, "RIGHT", -8, 0)
        arrow:SetText(isExpanded and "v" or ">")
        arrow:SetTextColor(0.45, 0.75, 0.70)

        frame:SetScript("OnClick", function()
            MR._cfgExpanded[stateKey] = not isExpanded
            RebuildExpandedState()
        end)
        frame:SetScript("OnEnter", function()
            frame:SetBackdropColor(0.045, 0.090, 0.105, 0.95)
            frame:SetBackdropBorderColor(0.22, 0.62, 0.62, 0.92)
            label:SetTextColor(0.86, 0.96, 0.96)
            arrow:SetTextColor(1, 1, 1)
        end)
        frame:SetScript("OnLeave", function()
            frame:SetBackdropColor(0.035, 0.055, 0.070, 0.90)
            frame:SetBackdropBorderColor(0.14, 0.30, 0.34, 0.78)
            label:SetTextColor(0.72, 0.86, 0.88)
            arrow:SetTextColor(0.45, 0.75, 0.70)
        end)
        yOff = yOff - moduleRowH
        return isExpanded
    end

    local function RenderModuleRows(mod, moduleAvailable)
        local key = mod.key
        local guide = ns.AcquireTexture(body, "modulesTexture42", "ARTWORK")
        guide:SetWidth(1)
        guide:SetColorTexture(0.20, 0.55, 0.50, 0.35)
        local guideTopY = yOff

        local rows = GetConfigRowsForModule(mod)
        local rowsByGroup = {}
        local rowsByConfigGroup = {}
        for _, row in ipairs(rows) do
            if row.group then
                rowsByGroup[row.group] = rowsByGroup[row.group] or {}
                rowsByGroup[row.group][#rowsByGroup[row.group] + 1] = row
            end
            if row.configGroup then
                local configGroup = rowsByConfigGroup[row.configGroup]
                if not configGroup then
                    configGroup = { rows = {} }
                    rowsByConfigGroup[row.configGroup] = configGroup
                end
                configGroup.rows[#configGroup.rows + 1] = row
                if row.sectionHeader then
                    configGroup.label = row.label
                end
            end
        end

        local lastRowPatchKey
        local lastRowGroup
        local lastConfigGroup
        local configGroupExpanded = true
        for _, row in ipairs(rows) do
            local currentRow = row
            local rowPatchKey = MR:GetRowPatchKey(mod, row)
            if rowPatchKey and rowPatchKey ~= MR:GetModulePatchKey(mod) and rowPatchKey ~= lastRowPatchKey then
                BuildRowPatchHeader(rowPatchKey, mod.key)
                lastRowPatchKey = rowPatchKey
            end
            if row.group and row.group ~= lastRowGroup and rowsByGroup[row.group] then
                BuildRowGroupHeader(key, rowsByGroup[row.group], ns.GetRowGroupLabel(row.group))
            end
            lastRowGroup = row.group

            if row.configGroup and row.configGroup ~= lastConfigGroup then
                local configGroup = rowsByConfigGroup[row.configGroup]
                configGroupExpanded = BuildCustomTaskGroupHeader(key, row.configGroup, configGroup)
            end
            lastConfigGroup = row.configGroup

            if not row.control and (not row.configGroup or configGroupExpanded) then
                local rowAvailable = moduleAvailable and MR:IsPatchAvailable(rowPatchKey)
                local rowFrame = Config.CreateTaskControl({
                    parent = body,
                    configFrame = f,
                    module = mod,
                    row = currentRow,
                    x = 18,
                    y = yOff,
                    width = contentW - 20,
                    height = moduleRowH,
                    fontSize = moduleRowFs,
                    label = FormatRowConfigLabel(mod, currentRow),
                    available = rowAvailable,
                    onDragStart = function(owner)
                        StartRowDrag(mod, currentRow, owner)
                    end,
                    onDragCommit = function()
                        if drag.active and drag.mode == "row" and drag.moduleKey == key then
                            CommitDrag()
                        end
                    end,
                })
                _cfgRowRows[key] = _cfgRowRows[key] or {}
                _cfgRowRows[key][#_cfgRowRows[key] + 1] = { key = currentRow.key, frame = rowFrame, label = currentRow.label, configGroup = currentRow.configGroup }
                yOff = yOff - moduleRowH - 1
            end
        end

        if yOff == guideTopY then
            guide:Hide()
        else
            guide:SetPoint("TOPLEFT", body, "TOPLEFT", 14, guideTopY)
            guide:SetPoint("BOTTOMLEFT", body, "TOPLEFT", 14, yOff + 4)
        end
        Gap(3)
    end

    local lastPatchKey
    local lastProfessionExpansionKey
    local professionExpansionOpen = true
    for _, mod in ipairs(_allMods) do
        local currentMod = mod
        local key = currentMod.key
        local optVisible = not mod.isVisible or mod:isVisible()
        local isStoryConfigModule = IsStoryConfigModule(mod)
        local patchKey = MR:GetModulePatchKey(mod)

        if isStoryConfigModule then
            if not storyGroupRendered then
                Gap(4)
                BuildStoryGroupHeader()
                storyGroupRendered = true
                lastPatchKey = nil
            end
            if not storyGroupOpen then
                optVisible = false
            end
        elseif mod.profSkillLine then
            if not professionGroupRendered then
                if ShouldShowModulePatchHeader(patchKey) and patchKey ~= lastPatchKey then
                    BuildPatchHeader(patchKey, key)
                    lastPatchKey = patchKey
                end
                Gap(5)
                BuildProfessionGroupHeader()
                professionGroupRendered = true
            end
            if not professionGroupOpen or not IsProfessionModuleKnownForConfig(mod) then
                optVisible = false
            end
        end

        if optVisible and not isStoryConfigModule and ShouldShowModulePatchHeader(patchKey) and patchKey ~= lastPatchKey then
            BuildPatchHeader(patchKey, key)
            lastPatchKey = patchKey
        end

        if optVisible and mod.profSkillLine then
            local expansionKey = MR:GetModuleExpansionKey(mod)
            if expansionKey ~= lastProfessionExpansionKey then
                professionExpansionOpen = BuildProfessionExpansionHeader(expansionKey)
                lastProfessionExpansionKey = expansionKey
            end
            if not professionExpansionOpen then
                optVisible = false
            end
        end

        if optVisible then
            local moduleAvailable = MR:IsModuleAvailable(currentMod)
            local moduleHeight = currentMod.profSkillLine and math.max(24, moduleHeaderFs + 14) or moduleHeaderH
            local moduleFrame = Config.CreateModuleControl({
                parent = body,
                configFrame = f,
                module = currentMod,
                x = currentMod.profSkillLine and 8 or 4,
                y = yOff,
                width = currentMod.profSkillLine and (contentW - 4) or contentW,
                height = moduleHeight,
                fontSize = moduleHeaderFs,
                label = FormatModuleConfigLabel(currentMod, false),
                available = moduleAvailable,
                expanded = MR._cfgExpanded[key] == true,
                emphasized = currentMod.profSkillLine ~= nil,
                story = isStoryConfigModule,
                rowIndex = #_cfgModuleRows + 1,
                onDragStart = function()
                    StartModuleDrag(currentMod, key)
                end,
                onDragCommit = function()
                    if drag.active then CommitDrag() end
                end,
                onToggleExpanded = function()
                    ToggleModuleExpanded(key)
                end,
                onEnabledChanged = isStoryConfigModule and function()
                    MR:RefreshUI()
                    if MR.RequestConfigRepopulate then
                        MR:RequestConfigRepopulate(f, 0.04)
                    end
                end or nil,
            })
            _cfgModuleRows[#_cfgModuleRows + 1] = { key = key, frame = moduleFrame, label = currentMod.label }
            yOff = yOff - moduleHeight - 1

            if MR._cfgExpanded[key] then
                RenderModuleRows(currentMod, moduleAvailable)
            end
        end
    end

    return yOff
end
