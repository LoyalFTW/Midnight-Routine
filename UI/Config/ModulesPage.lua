local _, ns = ...
local MR = ns.MR
local Config = assert(ns.ConfigInternal, "UI/Config/Frame.lua must load first")
local L = Config.L
local FONT_ROWS = ns.FONT_ROWS
local FONT_HEADERS = ns.FONT_HEADERS
local MakeBackdrop = ns.MakeBackdrop
local OptionsGap = ns.OptionsGap
local OptionsDivider = ns.OptionsDivider
local OptionsSectionLabel = ns.OptionsSectionLabel
local OptionsCheckbox = ns.OptionsCheckbox
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
    local function Divider() yOff = OptionsDivider(body, yOff, 4) end
    local function SectionLabel(text) yOff = OptionsSectionLabel(body, yOff, text, 8, cfgFs) end

        Gap(4); Divider()
        SectionLabel(L["Config_ModuleSettings"])
        local dragHint = body:CreateFontString(nil, "OVERLAY")
        dragHint:SetFont(ns.FONT_ROWS, math.max(8, cfgFs - 1), GetFontFlags())
        dragHint:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        dragHint:SetPoint("TOPRIGHT", body, "TOPRIGHT", -8, yOff)
        dragHint:SetJustifyH("RIGHT")
        dragHint:SetWordWrap(false)
        dragHint:SetText(L["Config_DragRowsHint"])
        dragHint:SetTextColor(0.42, 0.62, 0.64)
        yOff = yOff - math.max(13, cfgFs + 2)
        Gap(2)

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

    local drag = { active = false, srcKey = nil, targetIdx = nil, mode = "module", moduleKey = nil }

    local dragGhost = CreateFrame("Frame", nil, body, "BackdropTemplate")
    dragGhost:SetHeight(20)
    dragGhost:SetFrameStrata("DIALOG")
    dragGhost:SetBackdrop(MakeBackdrop())
    dragGhost:SetBackdropColor(0.08, 0.28, 0.22, 0.95)
    dragGhost:SetBackdropBorderColor(0.2, 0.9, 0.65, 1)
    dragGhost:Hide()
    local dragGhostLbl = dragGhost:CreateFontString(nil, "OVERLAY")
    dragGhostLbl:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
    dragGhostLbl:SetPoint("LEFT", dragGhost, "LEFT", 8, 0)
    dragGhostLbl:SetTextColor(0.3, 1, 0.75)

    local dragLine = CreateFrame("Frame", nil, body)
    dragLine:SetHeight(2)
    dragLine:SetFrameStrata("DIALOG")
    dragLine:Hide()
    local dragLineTex = dragLine:CreateTexture(nil, "OVERLAY")
    dragLineTex:SetAllPoints()
    dragLineTex:SetColorTexture(0.2, 0.9, 0.65, 1)

    local function IsStoryConfigModule(mod)
        return mod and (mod.configGroup == "story" or (type(mod.key) == "string" and mod.key:match("^story_campaign_")))
    end

    local orderedMods = MR:GetOrderedModules("all")
    local orderIndex = {}
    for index, mod in ipairs(orderedMods) do
        orderIndex[mod.key] = index
    end
    local weeklyAnchor = orderIndex.weeklies or orderIndex.weekly_tasks or orderIndex.weekly or 2

    local function GetConfigSortOrder(mod)
        if mod and MR:GetModulePatchKey(mod) == "12.0.7" then
            return weeklyAnchor + 0.35
        end
        return orderIndex[mod.key] or 9999
    end

    local _allMods = {}
    for _, mod in ipairs(orderedMods) do
        _allMods[#_allMods + 1] = mod
    end
    table.sort(_allMods, function(a, b)
        local aStory = IsStoryConfigModule(a)
        local bStory = IsStoryConfigModule(b)
        if aStory ~= bStory then
            return not aStory
        end
        local aSort = GetConfigSortOrder(a)
        local bSort = GetConfigSortOrder(b)
        if aSort ~= bSort then
            return aSort < bSort
        end
        local ao = MR.GetPatchSortOrder and MR:GetPatchSortOrder(MR:GetModulePatchKey(a)) or 999999
        local bo = MR.GetPatchSortOrder and MR:GetPatchSortOrder(MR:GetModulePatchKey(b)) or 999999
        if ao ~= bo then
            return ao < bo
        end
        return (orderIndex[a.key] or 9999) < (orderIndex[b.key] or 9999)
    end)

    local _cfgRows = {}
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

    local function BuildPatchHeader(patchKey)
        local patchInfo = MR:GetPatchInfo(patchKey)
        local available = MR:IsPatchAvailable(patchKey)
        local enabled = MR:IsPatchEnabled(patchKey)
        local ROW_H = moduleHeaderH
        local patchFr = CreateFrame("Frame", nil, body, "BackdropTemplate")
        patchFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
        patchFr:SetSize(contentW, ROW_H)
        patchFr:SetBackdrop(MakeBackdrop())
        patchFr:SetBackdropColor(enabled and 0.07 or 0.08, enabled and 0.17 or 0.07, enabled and 0.22 or 0.08, 0.95)
        patchFr:SetBackdropBorderColor(enabled and 0.20 or 0.35, enabled and 0.62 or 0.18, enabled and 0.70 or 0.18, 1)

        local cb = CreateFrame("CheckButton", nil, patchFr, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("LEFT", patchFr, "LEFT", 2, 0)
        cb:SetChecked(enabled)
        cb:SetEnabled(available)
        cb:SetAlpha(available and 1 or 0.45)
        cb:SetScript("OnClick", function(s)
            MR:SetPatchEnabled(patchKey, s:GetChecked(), true)
            if MR.RequestConfigRefresh then
                MR:RequestConfigRefresh()
            else
                MR:RefreshUI()
            end
        end)

        local lbl = patchFr:CreateFontString(nil, "OVERLAY")
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
            if not row.control and visible then
                rows[#rows + 1] = row
            end
        end

        return rows
    end

    local function BuildRowPatchHeader(patchKey)
        local patchInfo = MR:GetPatchInfo(patchKey)
        local available = MR:IsPatchAvailable(patchKey)
        local enabled = MR:IsPatchEnabled(patchKey)
        local ROW_H = moduleRowH
        local patchFr = CreateFrame("Frame", nil, body, "BackdropTemplate")
        patchFr:SetPoint("TOPLEFT", body, "TOPLEFT", 18, yOff)
        patchFr:SetSize(contentW - 20, ROW_H)
        patchFr:SetBackdrop(MakeBackdrop())
        patchFr:SetBackdropColor(enabled and 0.05 or 0.07, enabled and 0.13 or 0.06, enabled and 0.16 or 0.07, 0.88)
        patchFr:SetBackdropBorderColor(enabled and 0.16 or 0.30, enabled and 0.42 or 0.16, enabled and 0.48 or 0.16, 0.9)

        local cb = CreateFrame("CheckButton", nil, patchFr, "UICheckButtonTemplate")
        cb:SetSize(18, 18)
        cb:SetPoint("LEFT", patchFr, "LEFT", 0, 0)
        cb:SetChecked(enabled)
        cb:SetEnabled(available)
        cb:SetAlpha(available and 1 or 0.45)
        cb:SetScript("OnClick", function(s)
            MR:SetPatchEnabled(patchKey, s:GetChecked(), true)
            if MR.RequestConfigRefresh then
                MR:RequestConfigRefresh()
            else
                MR:RefreshUI()
            end
        end)

        local lbl = patchFr:CreateFontString(nil, "OVERLAY")
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
        local groupFr = CreateFrame("Frame", nil, body, "BackdropTemplate")
        groupFr:SetPoint("TOPLEFT", body, "TOPLEFT", 18, yOff)
        groupFr:SetSize(contentW - 20, ROW_H)
        groupFr:SetBackdrop(MakeBackdrop())
        groupFr:SetBackdropColor(enabled and 0.05 or 0.07, enabled and 0.13 or 0.06, enabled and 0.16 or 0.07, 0.88)
        groupFr:SetBackdropBorderColor(enabled and 0.16 or 0.30, enabled and 0.42 or 0.16, enabled and 0.48 or 0.16, 0.9)

        local cb = CreateFrame("CheckButton", nil, groupFr, "UICheckButtonTemplate")
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

        local lbl = groupFr:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(ns.FONT_HEADERS, moduleRowFs, GetFontFlags())
        lbl:SetPoint("LEFT", cb, "RIGHT", 1, 0)
        lbl:SetPoint("RIGHT", groupFr, "RIGHT", -6, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(label)
        lbl:SetTextColor(enabled and 0.72 or 0.42, enabled and 0.90 or 0.46, enabled and 0.88 or 0.48)

        yOff = yOff - ROW_H
    end

    local CommitDrag

    local function DragOnUpdate()
        if not drag.active then return end
        if not IsMouseButtonDown("LeftButton") then
            if CommitDrag then
                CommitDrag()
            end
            return
        end
        local rows = (drag.mode == "row" and drag.moduleKey and _cfgRowRows[drag.moduleKey]) or _cfgRows or {}
        if #rows == 0 then return end

        local cx, cy = GetCursorPosition()
        local scale  = body:GetEffectiveScale()
        local bLeft  = body:GetLeft()
        local bTop   = body:GetTop()
        if not bLeft or not bTop then return end
        local localX = cx / scale - bLeft
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
        local rows = (drag.mode == "row" and drag.moduleKey and _cfgRowRows[drag.moduleKey]) or _cfgRows or {}
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
            MR:PopulateConfigFrame(f)
            return
        end

        local allMods = MR:GetOrderedModules("all")
        local visMods = {}
        for _, row in ipairs(_cfgRows) do
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
            for _, row in ipairs(_cfgRows) do inCfgRows[row.key] = true end
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
        drag.srcKey = nil; drag.targetIdx = nil; drag.mode = "module"; drag.moduleKey = nil
        MR:PopulateConfigFrame(f)
    end

    local professionGroupRendered = false
    local professionGroupOpen = MR._cfgExpanded.__professions == true
    local professionTotal, professionKnown = 0, 0
    local storyGroupRendered = false
    if MR._cfgExpanded.__storyCampaigns == nil then
        MR._cfgExpanded.__storyCampaigns = true
    end
    local storyGroupOpen = MR._cfgExpanded.__storyCampaigns == true
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
        if IsStoryConfigModule(mod) then
            storyTotal = storyTotal + 1
            if MR:IsModuleEnabled(mod.key) then
                storyEnabled = storyEnabled + 1
            end
        end
    end

    local function BuildProfessionGroupHeader()
        local ROW_H = math.max(38, moduleHeaderFs + moduleSubFs + 14)
        local headerFr = CreateFrame("Frame", nil, body, "BackdropTemplate")
        headerFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
        headerFr:SetSize(contentW, ROW_H)
        headerFr:SetBackdrop(MakeBackdrop())
        headerFr:SetBackdropColor(0.020, 0.085, 0.100, 0.98)
        headerFr:SetBackdropBorderColor(0.24, 0.76, 0.70, 1)

        local badge = CreateFrame("Frame", nil, headerFr, "BackdropTemplate")
        badge:SetSize(28, 24)
        badge:SetPoint("LEFT", headerFr, "LEFT", 7, 0)
        badge:SetBackdrop(MakeBackdrop())
        badge:SetBackdropColor(0.06, 0.17, 0.18, 0.95)
        badge:SetBackdropBorderColor(0.28, 0.82, 0.74, 0.95)

        local badgeText = badge:CreateFontString(nil, "OVERLAY")
        badgeText:SetFont(ns.FONT_HEADERS, moduleHeaderFs, GetFontFlags())
        badgeText:SetPoint("CENTER")
        badgeText:SetText("PK")
        badgeText:SetTextColor(0.60, 1.00, 0.90)

        local arrowBtn = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
        arrowBtn:SetSize(16, 16)
        arrowBtn:SetPoint("RIGHT", headerFr, "RIGHT", -3, 0)
        arrowBtn:SetBackdrop(MakeBackdrop())
        arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
        arrowBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)

        local arrowLbl = arrowBtn:CreateFontString(nil, "OVERLAY")
        arrowLbl:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
        arrowLbl:SetPoint("CENTER", arrowBtn, "CENTER", 0, 1)
        arrowLbl:SetText(professionGroupOpen and "v" or ">")
        arrowLbl:SetTextColor(0.45, 0.75, 0.70)

        local lbl = headerFr:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(ns.FONT_HEADERS, moduleHeaderFs, GetFontFlags())
        lbl:SetPoint("TOPLEFT", badge, "TOPRIGHT", 8, -1)
        lbl:SetPoint("RIGHT", arrowBtn, "LEFT", -6, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetText("Profession Knowledge")
        lbl:SetTextColor(0.88, 1.00, 0.94)

        local sub = headerFr:CreateFontString(nil, "OVERLAY")
        sub:SetFont(ns.FONT_ROWS, moduleSubFs, GetFontFlags())
        sub:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -1)
        sub:SetPoint("RIGHT", arrowBtn, "LEFT", -6, 0)
        sub:SetJustifyH("LEFT")
        sub:SetText(string.format("Learned professions %d/%d", professionKnown, professionTotal))
        sub:SetTextColor(0.58, 0.80, 0.78, 0.95)

        local function ToggleProfessionGroup()
            MR._cfgExpanded.__professions = not professionGroupOpen
            arrowLbl:SetText(MR._cfgExpanded.__professions and "v" or ">")
            RebuildExpandedState()
        end

        headerFr:EnableMouse(true)
        headerFr:SetScript("OnMouseUp", ToggleProfessionGroup)
        arrowBtn:SetScript("OnClick", ToggleProfessionGroup)
        arrowBtn:SetScript("OnEnter", function()
            arrowBtn:SetBackdropColor(0.08, 0.22, 0.32, 1)
            arrowBtn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
            arrowLbl:SetTextColor(1, 1, 1)
        end)
        arrowBtn:SetScript("OnLeave", function()
            arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
            arrowBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
            arrowLbl:SetTextColor(0.45, 0.75, 0.70)
        end)

        yOff = yOff - ROW_H - 3
    end

    local function GetProfessionEntryVisibilityId(expansionKey, professionKey, sectionKey, index)
        return tostring(expansionKey) .. ":" .. tostring(professionKey) .. ":" .. tostring(sectionKey) .. ":" .. tostring(index)
    end

    local function CleanProfessionConfigLabel(text)
        text = tostring(text or "")
        text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        return text
    end

    local function RenderLegacyProfessionConfigRows()
        local expansions = ns.AllExpansions or {}
        local profile = MR.db and MR.db.profile
        if not profile then return end
        profile.gatheringEntryVisibility = profile.gatheringEntryVisibility or {}
        local entryVisibility = profile.gatheringEntryVisibility
        local renderedAny = false

        local function GroupEnabled(expansionKey, profession, section)
            for index in ipairs(section.entries or {}) do
                local entryId = GetProfessionEntryVisibilityId(expansionKey, profession.key, section.key, index)
                if entryVisibility[entryId] == false then
                    return false
                end
            end
            return true
        end

        local function SetGroupEnabled(expansionKey, profession, section, enabled)
            for index in ipairs(section.entries or {}) do
                local entryId = GetProfessionEntryVisibilityId(expansionKey, profession.key, section.key, index)
                entryVisibility[entryId] = enabled and true or false
            end
            if MR.RebuildGatheringLocationsFrame then MR:RebuildGatheringLocationsFrame() end
            MR:PopulateConfigFrame(f)
        end

        local function ProfessionEnabled(expansionKey, profession)
            if ns.IsProfessionKnowledgeProfessionVisible then
                return ns.IsProfessionKnowledgeProfessionVisible(expansionKey, profession.key)
            end
            return true
        end

        local function SetProfessionEnabled(expansionKey, profession, enabled)
            if ns.SetProfessionKnowledgeProfessionVisible then
                ns.SetProfessionKnowledgeProfessionVisible(expansionKey, profession.key, enabled)
            end
            MR:PopulateConfigFrame(f)
        end

        for _, expansion in ipairs(expansions) do
            if expansion.key ~= "midnight" then
                local learned = {}
                for _, profession in ipairs(expansion.professions or {}) do
                    if IsProfessionKnownForConfig(profession) then
                        learned[#learned + 1] = profession
                    end
                end
                if #learned > 0 then
                    if not renderedAny then
                        Gap(4)
                        renderedAny = true
                    end

                    local expH = moduleRowH
                    local expFr = CreateFrame("Frame", nil, body, "BackdropTemplate")
                    expFr:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
                    expFr:SetSize(contentW - 4, expH)
                    expFr:SetBackdrop(MakeBackdrop())
                    expFr:SetBackdropColor(0.035, 0.055, 0.070, 0.90)
                    expFr:SetBackdropBorderColor(0.14, 0.30, 0.34, 0.78)
                    local expLbl = expFr:CreateFontString(nil, "OVERLAY")
                    expLbl:SetFont(ns.FONT_HEADERS, moduleRowFs, GetFontFlags())
                    expLbl:SetPoint("LEFT", expFr, "LEFT", 7, 0)
                    expLbl:SetPoint("RIGHT", expFr, "RIGHT", -7, 0)
                    expLbl:SetJustifyH("LEFT")
                    expLbl:SetText(string.format("%s  |cff667788%d|r", expansion.label or expansion.key, #learned))
                    expLbl:SetTextColor(0.72, 0.86, 0.88)
                    yOff = yOff - expH

                    for _, profession in ipairs(learned) do
                        local rowH = moduleHeaderH
                        local rowKey = "__pk:" .. expansion.key .. ":" .. profession.key
                        local isExp = MR._cfgExpanded[rowKey]
                        local professionEnabled = ProfessionEnabled(expansion.key, profession)
                        local rowFr = CreateFrame("Frame", nil, body, "BackdropTemplate")
                        rowFr:SetPoint("TOPLEFT", body, "TOPLEFT", 14, yOff)
                        rowFr:SetSize(contentW - 10, rowH)
                        rowFr:SetBackdrop(MakeBackdrop())
                        rowFr:SetBackdropColor(0.018, 0.025, 0.032, 0.86)
                        rowFr:SetBackdropBorderColor(0.16, 0.24, 0.28, 0.72)

                        local enableBtn = CreateFrame("CheckButton", nil, rowFr, "UICheckButtonTemplate")
                        enableBtn:SetSize(18, 18)
                        enableBtn:SetPoint("LEFT", rowFr, "LEFT", 4, 0)
                        enableBtn:SetChecked(professionEnabled)
                        enableBtn:SetScript("OnClick", function(s)
                            SetProfessionEnabled(expansion.key, profession, s:GetChecked() and true or false)
                        end)
                        enableBtn:SetScript("OnEnter", function()
                            ns.ShowTooltip(enableBtn, {
                                text = enableBtn:GetChecked() and (L["Config_DisableModule"] or "Disable this profession") or (L["Config_EnableModule"] or "Enable this profession"),
                            })
                        end)
                        enableBtn:SetScript("OnLeave", function() ns.HideTooltip(enableBtn) end)

                        local expandBtn = CreateFrame("Button", nil, rowFr, "BackdropTemplate")
                        expandBtn:SetSize(16, 16)
                        expandBtn:SetPoint("RIGHT", rowFr, "RIGHT", -4, 0)
                        expandBtn:SetBackdrop(MakeBackdrop())
                        expandBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
                        expandBtn:SetBackdropBorderColor(0.15, 0.32, 0.38, 1)
                        local expandLbl = expandBtn:CreateFontString(nil, "OVERLAY")
                        expandLbl:SetFont(ns.FONT_HEADERS, 9, GetFontFlags())
                        expandLbl:SetPoint("CENTER", expandBtn, "CENTER", 0, 1)
                        expandLbl:SetText(isExp and "v" or ">")
                        expandLbl:SetTextColor(0.45, 0.75, 0.70)
                        expandBtn:SetScript("OnClick", function()
                            MR._cfgExpanded[rowKey] = not isExp
                            expandLbl:SetText(MR._cfgExpanded[rowKey] and "v" or ">")
                            RebuildExpandedState()
                        end)

                        local lbl = rowFr:CreateFontString(nil, "OVERLAY")
                        lbl:SetFont(ns.FONT_ROWS, moduleRowFs, GetFontFlags())
                        lbl:SetPoint("LEFT", enableBtn, "RIGHT", 6, 0)
                        lbl:SetPoint("RIGHT", expandBtn, "LEFT", -6, 0)
                        lbl:SetJustifyH("LEFT")
                        lbl:SetText(profession.label)
                        lbl:SetTextColor(0.80, 0.86, 0.88)
                        yOff = yOff - rowH

                        if isExp then
                            for _, section in ipairs(profession.sections or {}) do
                                if #section.entries > 0 then
                                    local enabled = GroupEnabled(expansion.key, profession, section)
                                    local groupFr = CreateFrame("Frame", nil, body, "BackdropTemplate")
                                    groupFr:SetPoint("TOPLEFT", body, "TOPLEFT", 26, yOff)
                                    groupFr:SetSize(contentW - 22, moduleCompactH)
                                    groupFr:SetBackdrop(MakeBackdrop())
                                    groupFr:SetBackdropColor(enabled and 0.035 or 0.055, enabled and 0.085 or 0.045, enabled and 0.095 or 0.050, 0.72)
                                    groupFr:SetBackdropBorderColor(enabled and 0.10 or 0.24, enabled and 0.32 or 0.12, enabled and 0.34 or 0.12, 0.70)

                                    local cb = CreateFrame("CheckButton", nil, groupFr, "UICheckButtonTemplate")
                                    cb:SetSize(18, 18)
                                    cb:SetPoint("LEFT", groupFr, "LEFT", 0, 0)
                                    cb:SetChecked(enabled)
                                    cb:SetScript("OnClick", function(s)
                                        SetGroupEnabled(expansion.key, profession, section, s:GetChecked() and true or false)
                                    end)

                                    local sectionLbl = groupFr:CreateFontString(nil, "OVERLAY")
                                    sectionLbl:SetFont(ns.FONT_ROWS, moduleSubFs, GetFontFlags())
                                    sectionLbl:SetPoint("LEFT", cb, "RIGHT", 1, 0)
                                    sectionLbl:SetPoint("RIGHT", groupFr, "RIGHT", -5, 0)
                                    sectionLbl:SetJustifyH("LEFT")
                                    sectionLbl:SetText(CleanProfessionConfigLabel(section.label))
                                    sectionLbl:SetTextColor(enabled and 0.72 or 0.42, enabled and 0.90 or 0.46, enabled and 0.88 or 0.48)
                                    yOff = yOff - moduleCompactH
                                end
                            end
                            Gap(2)
                        end
                    end
                end
            end
        end
    end

    local function BuildStoryGroupHeader()
        if storyTotal <= 0 then
            return
        end

        local ROW_H = moduleHeaderH
        local headerFr = CreateFrame("Frame", nil, body, "BackdropTemplate")
        headerFr:SetPoint("TOPLEFT", body, "TOPLEFT", 4, yOff)
        headerFr:SetSize(contentW, ROW_H)
        headerFr:SetBackdrop(MakeBackdrop())
        headerFr:SetBackdropColor(0.07, 0.10, 0.15, 0.95)
        headerFr:SetBackdropBorderColor(0.38, 0.34, 0.16, 0.95)

        local cb = CreateFrame("CheckButton", nil, headerFr, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("LEFT", headerFr, "LEFT", 2, 0)
        cb:SetChecked(MR:GetStoryCampaignsEnabledPreference() ~= false)
        cb:SetScript("OnClick", function(s)
            local enabled = s:GetChecked() and true or false
            MR:SetStoryCampaignsEnabledPreference(enabled)
            for _, storyMod in ipairs(_allMods) do
                if IsStoryConfigModule(storyMod) then
                    MR:SetModuleEnabled(storyMod.key, enabled, true)
                end
            end
            MR:RefreshUI()
            if MR.RequestConfigRepopulate then
                MR:RequestConfigRepopulate(f, 0.04)
            end
        end)

        local arrowBtn = CreateFrame("Button", nil, headerFr, "BackdropTemplate")
        arrowBtn:SetSize(16, 16)
        arrowBtn:SetPoint("RIGHT", headerFr, "RIGHT", -3, 0)
        arrowBtn:SetBackdrop(MakeBackdrop())
        arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
        arrowBtn:SetBackdropBorderColor(0.28, 0.26, 0.12, 1)

        local arrowLbl = arrowBtn:CreateFontString(nil, "OVERLAY")
        arrowLbl:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
        arrowLbl:SetPoint("CENTER", arrowBtn, "CENTER", 0, 1)
        arrowLbl:SetText(storyGroupOpen and "v" or ">")
        arrowLbl:SetTextColor(0.90, 0.82, 0.42)

        local lbl = headerFr:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(ns.FONT_HEADERS, moduleHeaderFs, GetFontFlags())
        lbl:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        lbl:SetPoint("RIGHT", arrowBtn, "LEFT", -6, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(string.format("Story Campaigns  |cff667788%d/%d|r", storyEnabled, storyTotal))
        lbl:SetTextColor(0.95, 0.88, 0.56)

        local function ToggleStoryGroup()
            MR._cfgExpanded.__storyCampaigns = not storyGroupOpen
            arrowLbl:SetText(MR._cfgExpanded.__storyCampaigns and "v" or ">")
            RebuildExpandedState()
        end

        headerFr:EnableMouse(true)
        headerFr:SetScript("OnMouseUp", ToggleStoryGroup)
        arrowBtn:SetScript("OnClick", ToggleStoryGroup)
        arrowBtn:SetScript("OnEnter", function()
            arrowBtn:SetBackdropColor(0.14, 0.16, 0.16, 1)
            arrowBtn:SetBackdropBorderColor(0.88, 0.78, 0.32, 1)
            arrowLbl:SetTextColor(1, 1, 1)
        end)
        arrowBtn:SetScript("OnLeave", function()
            arrowBtn:SetBackdropColor(0.05, 0.10, 0.18, 1)
            arrowBtn:SetBackdropBorderColor(0.28, 0.26, 0.12, 1)
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
        drag.srcKey = key
        drag.targetIdx = nil
        dragGhostLbl:SetText(mod.label)
    end

    local function StartRowDrag(mod, row)
        if drag.active then return end
        drag.active = true
        f:SetScript("OnUpdate", DragOnUpdate)
        drag.mode = "row"
        drag.moduleKey = mod.key
        drag.srcKey = row.key
        drag.targetIdx = nil
        dragGhostLbl:SetText(FormatRowConfigLabel(mod, row))
        ns.HideTooltip()
    end

    local function ToggleModuleExpanded(key)
        MR._cfgExpanded[key] = not MR._cfgExpanded[key]
        RebuildExpandedState()
    end

    local function BuildProfessionExpansionHeader(expansionKey)
        local expansionInfo = MR:GetExpansionInfo(expansionKey)
        local frame = CreateFrame("Frame", nil, body, "BackdropTemplate")
        frame:SetPoint("TOPLEFT", body, "TOPLEFT", 8, yOff)
        frame:SetSize(contentW - 4, moduleRowH)
        frame:SetBackdrop(MakeBackdrop())
        frame:SetBackdropColor(0.035, 0.055, 0.070, 0.90)
        frame:SetBackdropBorderColor(0.14, 0.30, 0.34, 0.78)

        local label = frame:CreateFontString(nil, "OVERLAY")
        label:SetFont(ns.FONT_HEADERS, moduleRowFs, GetFontFlags())
        label:SetPoint("LEFT", frame, "LEFT", 7, 0)
        label:SetPoint("RIGHT", frame, "RIGHT", -7, 0)
        label:SetJustifyH("LEFT")
        label:SetText((expansionInfo and (expansionInfo.shortLabel or expansionInfo.label or expansionInfo.key)) or expansionKey)
        label:SetTextColor(0.72, 0.86, 0.88)
        yOff = yOff - moduleRowH
    end

    local function RenderModuleRows(mod, moduleAvailable)
        local key = mod.key
        local guide = body:CreateTexture(nil, "ARTWORK")
        guide:SetWidth(1)
        guide:SetColorTexture(0.20, 0.55, 0.50, 0.35)
        local guideTopY = yOff

        local rows = GetConfigRowsForModule(mod)
        local rowsByGroup = {}
        for _, row in ipairs(rows) do
            if row.group then
                rowsByGroup[row.group] = rowsByGroup[row.group] or {}
                rowsByGroup[row.group][#rowsByGroup[row.group] + 1] = row
            end
        end

        local lastRowPatchKey
        local lastRowGroup
        for _, row in ipairs(rows) do
            local currentRow = row
            local rowPatchKey = MR:GetRowPatchKey(mod, row)
            if rowPatchKey and rowPatchKey ~= MR:GetModulePatchKey(mod) and rowPatchKey ~= lastRowPatchKey then
                BuildRowPatchHeader(rowPatchKey)
                lastRowPatchKey = rowPatchKey
            end
            if row.group and row.group ~= lastRowGroup and rowsByGroup[row.group] then
                BuildRowGroupHeader(key, rowsByGroup[row.group], ns.GetRowGroupLabel(row.group))
            end
            lastRowGroup = row.group

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
                onDragStart = function()
                    StartRowDrag(mod, currentRow)
                end,
                onDragCommit = function()
                    if drag.active and drag.mode == "row" and drag.moduleKey == key then
                        CommitDrag()
                    end
                end,
            })
            _cfgRowRows[key] = _cfgRowRows[key] or {}
            _cfgRowRows[key][#_cfgRowRows[key] + 1] = { key = currentRow.key, frame = rowFrame, label = currentRow.label }
            yOff = yOff - moduleRowH - 1
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
    for _, mod in ipairs(_allMods) do
        local currentMod = mod
        local key = currentMod.key
        local optVisible = not mod.isVisible or mod:isVisible()
        local isStoryConfigModule = IsStoryConfigModule(mod)
        local patchKey = MR:GetModulePatchKey(mod)

        if isStoryConfigModule then
            if not storyGroupRendered then
                Gap(2)
                Divider()
                Gap(2)
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
                    BuildPatchHeader(patchKey)
                    lastPatchKey = patchKey
                end
                BuildProfessionGroupHeader()
                professionGroupRendered = true
            end
            if not professionGroupOpen or not IsProfessionModuleKnownForConfig(mod) then
                optVisible = false
            end
        end

        if optVisible and not isStoryConfigModule and ShouldShowModulePatchHeader(patchKey) and patchKey ~= lastPatchKey then
            BuildPatchHeader(patchKey)
            lastPatchKey = patchKey
        end

        if optVisible then
            if mod.profSkillLine then
                local expansionKey = MR:GetModuleExpansionKey(mod)
                if expansionKey ~= lastProfessionExpansionKey then
                    BuildProfessionExpansionHeader(expansionKey)
                    lastProfessionExpansionKey = expansionKey
                end
            end

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
            _cfgRows[#_cfgRows + 1] = { key = key, frame = moduleFrame, label = currentMod.label }
            yOff = yOff - moduleHeight

            if MR._cfgExpanded[key] then
                RenderModuleRows(currentMod, moduleAvailable)
            end
        end
    end

    return yOff
end

