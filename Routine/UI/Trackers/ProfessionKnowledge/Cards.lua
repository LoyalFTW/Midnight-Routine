local _, ns = ...
if ns.Inactive then return end
if ns.MR.isForever and ns.Forever.hideProfessions then return end
local MR = ns.MR
local PK = ns.ProfessionKnowledgeInternal

local MakeBackdrop = ns.MakeBackdrop
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine", true)
local HasProfessionLearned = PK.HasProfessionLearned
local ProfessionStats = PK.ProfessionStats
local ProfessionWeeklyStats = PK.ProfessionWeeklyStats
local GetProfessionSkillSummary = PK.GetProfessionSkillSummary
local GetItemCountRemaining = PK.GetItemCountRemaining
local GetProfessionCatchupAmount = PK.GetProfessionCatchupAmount
local GetProfessionTaskRows = PK.GetProfessionTaskRows
local IsSkinningLuresModule = PK.IsSkinningLuresModule
local IsProfessionKnowledgeModule = PK.IsProfessionKnowledgeModule
local GetFontFlags = ns.GetFontFlags
local PROFESSION_ICONS = PK.PROFESSION_ICONS
local ALL_EXPANSIONS = PK.ALL_EXPANSIONS
local GetProfessionColor = PK.GetProfessionColor
local GetEntryVisibilityId = PK.GetEntryVisibilityId
local IsProfessionCardVisible = PK.IsProfessionCardVisible
local IsProfessionCollapsed = PK.IsProfessionCollapsed
local SetProfessionCollapsed = PK.SetProfessionCollapsed
local VisibleSortedEntries = PK.VisibleSortedEntries
local RenderFrame = PK.RenderFrame
local RenderFontString = PK.RenderFontString
local RenderTexture = PK.RenderTexture
local GetOrderedProfessionSections = PK.GetOrderedProfessionSections
local ShouldShowProfessionSection = PK.ShouldShowProfessionSection
local GetMainMenuEntryColor = PK.GetMainMenuEntryColor
local RenderEntryRow = PK.RenderEntryRow
local RenderReferenceRow = PK.RenderReferenceRow
local RenderCatchupRow = PK.RenderCatchupRow
local RenderProfessionTasksSection = PK.RenderProfessionTasksSection

local function RenderSkinningLuresCard(content, width, yOff, fontSize, contentAlpha, chromeAlpha, accentAlpha, db, expansion, profession)
    local taskRows, taskDone, taskTotal = GetProfessionTaskRows(profession, IsSkinningLuresModule)
    if #taskRows == 0 then
        return yOff
    end

    local cr, cg, cb = GetProfessionColor(profession.key)
    local cardW = math.max(1, width - 20)
    local collapsedRowH = math.max(24, fontSize + 15)
    local collapsedIconSize = math.max(16, math.min(20, fontSize + 7))
    local collapseKey = profession.key .. "_lures"
    local isCollapsed = IsProfessionCollapsed(expansion.key, collapseKey)

    local card = RenderFrame("Frame", content, "BackdropTemplate")
    card:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -yOff)
    card:SetWidth(cardW)
    card:SetBackdrop(MakeBackdrop())
    card:SetBackdropColor(0.018, 0.022, 0.028, (isCollapsed and 0.58 or 0.86) * contentAlpha)
    card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)

    local iconPlate = RenderFrame("Frame", card, "BackdropTemplate")
    iconPlate:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
    iconPlate:SetSize(28, 28)
    iconPlate:SetBackdrop(MakeBackdrop())
    iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.95 * chromeAlpha)
    iconPlate:SetBackdropBorderColor(cr * 0.55, cg * 0.55, cb * 0.55, 0.85 * chromeAlpha)

    local iconTex = RenderTexture(iconPlate, "ARTWORK")
    iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
    iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
    iconTex:SetTexture(profession.icon or PROFESSION_ICONS[profession.key] or "Interface\\Icons\\INV_Misc_QuestionMark")
    iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    local cardGlow = RenderTexture(card, "BACKGROUND")
    cardGlow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    cardGlow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
    cardGlow:SetColorTexture(1, 1, 1, isCollapsed and 0 or (0.025 * contentAlpha))

    local header = RenderFontString(card, "OVERLAY")
    header:SetFont(ns.FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
    if isCollapsed then
        iconPlate:ClearAllPoints()
        iconPlate:SetPoint("LEFT", card, "LEFT", 7, 0)
        iconPlate:SetSize(collapsedIconSize, collapsedIconSize)
        iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.70 * chromeAlpha)
        iconPlate:SetBackdropBorderColor(cr * 0.42, cg * 0.42, cb * 0.42, 0.70 * chromeAlpha)
        iconTex:ClearAllPoints()
        iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
        iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
        header:SetPoint("LEFT", iconPlate, "RIGHT", 6, 0)
        header:SetPoint("RIGHT", card, "RIGHT", -118, 0)
    else
        header:SetPoint("TOPLEFT", iconPlate, "TOPRIGHT", 8, -1)
        header:SetPoint("TOPRIGHT", card, "TOPRIGHT", -128, -1)
    end
    header:SetJustifyH("LEFT")
    header:SetWordWrap(false)
    header:SetTextColor(0.96, 0.97, 0.98, 1)
    header:SetText(L["Skin_Lures_Title"] or "Skinning Lures")

    local headerMeta = RenderFontString(card, "OVERLAY")
    headerMeta:SetFont(ns.FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
    if isCollapsed then
        headerMeta:SetPoint("RIGHT", card, "RIGHT", -10, 0)
        headerMeta:SetWidth(106)
    else
        headerMeta:SetPoint("TOPRIGHT", card, "TOPRIGHT", -30, -10)
        headerMeta:SetWidth(98)
    end
    headerMeta:SetJustifyH("RIGHT")
    headerMeta:SetWordWrap(false)
    headerMeta:SetTextColor(0.88, 0.91, 0.94, 0.95)
    headerMeta:SetText(string.format("%d / %d", taskDone, taskTotal))

    local collapseBtn = RenderFrame("Button", card)
    collapseBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -7, -8)
    collapseBtn:SetSize(18, 18)
    collapseBtn:RegisterForClicks("LeftButtonUp")

    local collapseLbl = RenderFontString(collapseBtn, "OVERLAY")
    collapseLbl:SetFont(ns.FONT_HEADERS, math.max(10, fontSize), GetFontFlags())
    collapseLbl:SetPoint("CENTER")
    collapseLbl:SetText(isCollapsed and "+" or "-")
    collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
    collapseBtn:SetShown(not isCollapsed)

    local function ToggleLuresCard()
        SetProfessionCollapsed(expansion.key, collapseKey, not IsProfessionCollapsed(expansion.key, collapseKey))
        PK.RebuildGatheringLocationsFrame()
    end

    local headerHit = RenderFrame("Button", card)
    headerHit:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    headerHit:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
    headerHit:SetHeight(isCollapsed and collapsedRowH or 44)
    headerHit:RegisterForClicks("LeftButtonUp")
    headerHit:SetScript("OnClick", ToggleLuresCard)
    headerHit:SetScript("OnEnter", function()
        card:SetBackdropBorderColor(cr * 0.52, cg * 0.52, cb * 0.52, math.min(1, chromeAlpha + 0.15) * chromeAlpha)
        collapseLbl:SetTextColor(1, 1, 1, 1)
    end)
    headerHit:SetScript("OnLeave", function()
        card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)
        collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
    end)
    collapseBtn:SetScript("OnClick", ToggleLuresCard)

    local cardY = isCollapsed and collapsedRowH or 36
    if not isCollapsed then
        cardY = RenderProfessionTasksSection(card, cardW, cardY, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, profession, taskRows, true)
    end

    card:SetHeight(isCollapsed and collapsedRowH or (cardY + 8))
    return yOff + card:GetHeight() + (isCollapsed and 3 or 8)
end

local function BuildProfessionCards(content, width, yOff, fontSize, contentAlpha, borderAlpha, chromeAlpha, accentAlpha, db, filterExpansionKey)
    if MR.isForever then ns.Forever.RefreshProfessions() end
    local professionSource = MR.GetMainFrameProgressSource and MR:GetMainFrameProgressSource() or nil
    for _, expansion in ipairs(ALL_EXPANSIONS) do
      if not filterExpansionKey or expansion.key == filterExpansionKey then
        local learnedProfessions = {}
        for _, profession in ipairs(expansion.professions) do
            if HasProfessionLearned(profession.skillLine, professionSource) then
                learnedProfessions[#learnedProfessions + 1] = profession
            end
        end

        local visibleProfessions = {}
        for _, profession in ipairs(learnedProfessions) do
            if IsProfessionCardVisible(expansion.key, profession.key) then
                visibleProfessions[#visibleProfessions + 1] = profession
            end
        end

        for _, profession in ipairs(visibleProfessions) do
                local doneSources, totalSources, kpDone, kpTotal = ProfessionStats(profession)
                local weeklyDone, weeklyTotal = ProfessionWeeklyStats(profession)
                local weeklyRemaining = math.max(0, weeklyTotal - weeklyDone)
                local catchupAmount = GetProfessionCatchupAmount(profession, expansion)
                local skillSummary = GetProfessionSkillSummary(profession.skillLine)
                local isCollapsed = IsProfessionCollapsed(expansion.key, profession.key)
                local _, taskDone, taskTotal = GetProfessionTaskRows(profession, IsProfessionKnowledgeModule)
                local useTaskHeader = taskTotal > 0
                local cr, cg, cb = GetProfessionColor(profession.key)
                local cardW = math.max(1, width - 20)
                local collapsedRowH = math.max(24, fontSize + 15)
                local collapsedIconSize = math.max(16, math.min(20, fontSize + 7))
                local headerRightPad = useTaskHeader and 128 or 96

                local card = RenderFrame("Frame", content, "BackdropTemplate")
                card:SetPoint("TOPLEFT", content, "TOPLEFT", 6, -yOff)
                card:SetWidth(cardW)
                card:SetBackdrop(MakeBackdrop())
                card:SetBackdropColor(0.018, 0.022, 0.028, (isCollapsed and 0.58 or 0.86) * contentAlpha)
                card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)

                local iconPlate = RenderFrame("Frame", card, "BackdropTemplate")
                iconPlate:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -8)
                iconPlate:SetSize(28, 28)
                iconPlate:SetBackdrop(MakeBackdrop())
                iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.95 * chromeAlpha)
                iconPlate:SetBackdropBorderColor(cr * 0.55, cg * 0.55, cb * 0.55, 0.85 * chromeAlpha)

                local iconTex = RenderTexture(iconPlate, "ARTWORK")
                iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
                iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
                iconTex:SetTexture(PROFESSION_ICONS[profession.key] or "Interface\\Icons\\INV_Misc_QuestionMark")
                iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)

                local cardGlow = RenderTexture(card, "BACKGROUND")
                cardGlow:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
                cardGlow:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -1, 1)
                cardGlow:SetColorTexture(1, 1, 1, isCollapsed and 0 or (0.025 * contentAlpha))

                local header = RenderFontString(card, "OVERLAY")
                header:SetFont(ns.FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
                if isCollapsed then
                    iconPlate:ClearAllPoints()
                    iconPlate:SetPoint("LEFT", card, "LEFT", 7, 0)
                    iconPlate:SetSize(collapsedIconSize, collapsedIconSize)
                    iconPlate:SetBackdropColor(0.015, 0.018, 0.024, 0.70 * chromeAlpha)
                    iconPlate:SetBackdropBorderColor(cr * 0.42, cg * 0.42, cb * 0.42, 0.70 * chromeAlpha)
                    iconTex:ClearAllPoints()
                    iconTex:SetPoint("TOPLEFT", iconPlate, "TOPLEFT", 2, -2)
                    iconTex:SetPoint("BOTTOMRIGHT", iconPlate, "BOTTOMRIGHT", -2, 2)
                    header:SetPoint("LEFT", iconPlate, "RIGHT", 6, 0)
                    header:SetPoint("RIGHT", card, "RIGHT", -(useTaskHeader and 118 or 64), 0)
                else
                    header:SetPoint("TOPLEFT", iconPlate, "TOPRIGHT", 8, -1)
                    header:SetPoint("TOPRIGHT", card, "TOPRIGHT", -headerRightPad, -1)
                end
                header:SetJustifyH("LEFT")
                header:SetWordWrap(false)
                header:SetTextColor(0.96, 0.97, 0.98, 1)
                header:SetText(profession.label)

                local headerSub = RenderFontString(card, "OVERLAY")
                headerSub:SetFont(ns.FONT_ROWS, math.max(8, fontSize - 2), GetFontFlags())
                headerSub:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
                headerSub:SetPoint("RIGHT", card, "RIGHT", -12, 0)
                headerSub:SetJustifyH("LEFT")
                headerSub:SetTextColor(0.66, 0.72, 0.78, 0.95)
                headerSub:SetWordWrap(false)

                local headerMeta = RenderFontString(card, "OVERLAY")
                headerMeta:SetFont(ns.FONT_HEADERS, math.max(9, fontSize), GetFontFlags())
                if isCollapsed then
                    headerMeta:SetPoint("RIGHT", card, "RIGHT", -10, 0)
                    headerMeta:SetWidth(useTaskHeader and 106 or 48)
                else
                    headerMeta:SetPoint("TOPRIGHT", card, "TOPRIGHT", -30, -10)
                    headerMeta:SetWidth(useTaskHeader and 98 or 64)
                end
                headerMeta:SetJustifyH("RIGHT")
                headerMeta:SetWordWrap(false)
                headerMeta:SetTextColor(0.88, 0.91, 0.94, 0.95)
                headerMeta:SetText(useTaskHeader and string.format("%d / %d", taskDone, taskTotal) or string.format("%d/%d", doneSources, totalSources))

                local collapseBtn = RenderFrame("Button", card)
                collapseBtn:SetPoint("TOPRIGHT", card, "TOPRIGHT", -7, -8)
                collapseBtn:SetSize(18, 18)
                collapseBtn:RegisterForClicks("LeftButtonUp")

                local collapseLbl = RenderFontString(collapseBtn, "OVERLAY")
                collapseLbl:SetFont(ns.FONT_HEADERS, math.max(10, fontSize), GetFontFlags())
                collapseLbl:SetPoint("CENTER")
                collapseLbl:SetText(isCollapsed and "+" or "-")
                collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
                collapseBtn:SetShown(not isCollapsed)

                local function ToggleProfessionCard()
                    SetProfessionCollapsed(expansion.key, profession.key, not IsProfessionCollapsed(expansion.key, profession.key))
                    PK.RebuildGatheringLocationsFrame()
                end

                local headerHit = RenderFrame("Button", card)
                headerHit:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
                headerHit:SetPoint("TOPRIGHT", card, "TOPRIGHT", 0, 0)
                headerHit:SetHeight(isCollapsed and collapsedRowH or 44)
                headerHit:RegisterForClicks("LeftButtonUp")
                headerHit:SetScript("OnClick", ToggleProfessionCard)
                headerHit:SetScript("OnEnter", function()
                    card:SetBackdropBorderColor(cr * 0.52, cg * 0.52, cb * 0.52, math.min(1, chromeAlpha + 0.15) * chromeAlpha)
                    collapseLbl:SetTextColor(1, 1, 1, 1)
                end)
                headerHit:SetScript("OnLeave", function()
                    card:SetBackdropBorderColor(0.12, 0.15, 0.18, (isCollapsed and 0.48 or 0.74) * chromeAlpha)
                    collapseLbl:SetTextColor(0.84, 0.90, 0.95, 0.95)
                end)
                collapseBtn:SetScript("OnClick", ToggleProfessionCard)

                if isCollapsed then
                    headerSub:Hide()
                    headerMeta:SetText(useTaskHeader and string.format("%d / %d", taskDone, taskTotal) or string.format("%d/%d", doneSources, totalSources))
                else
                    if useTaskHeader then
                        headerSub:Hide()
                        headerMeta:SetText(string.format("%d / %d", taskDone, taskTotal))
                    else
                        local catchupHidden
                        local moduleKey = ns.GetProfessionModuleKey and ns.GetProfessionModuleKey(expansion.key, profession) or ("prof_" .. profession.key)
                        if moduleKey then
                            catchupHidden = not MR:IsRowEnabled(moduleKey, "prof_catchup")
                        else
                            catchupHidden = db.gatheringEntryVisibility and db.gatheringEntryVisibility["prof_catchup"] == false
                        end
                        if catchupHidden then
                            headerSub:SetText(string.format(L["ProfKnowledge_HeaderSubFormatNoCatchup"] or "Skill %s   Weekly +%d", skillSummary or "--", weeklyRemaining))
                        else
                            headerSub:SetText(string.format(L["ProfKnowledge_HeaderSubFormat"], skillSummary or "--", weeklyRemaining, catchupAmount))
                        end
                        headerMeta:SetText(string.format("%d/%d KP", kpDone, kpTotal))
                    end
                end

                local cardY = isCollapsed and collapsedRowH or 54

                if not isCollapsed then
                    local rowHeight = math.max(fontSize + 11, 22)
                    if taskTotal > 0 then
                        cardY = RenderProfessionTasksSection(card, cardW, cardY, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, db, profession)
                    else
                    local entryVisibility = db.gatheringEntryVisibility
                    local catchupRendered = false
                    for _, section in ipairs(GetOrderedProfessionSections(profession)) do
                        if ShouldShowProfessionSection(section) then
                        local visibleEntries = {}
                        local mainMenuKey = ns.GetEntryMainMenuKey
                        for i, entry in ipairs(section.entries) do
                            local rowKey = mainMenuKey and mainMenuKey(section.key, entry)
                            local visible
                            if rowKey then
                                local modKey = (section.key == "lures") and "skin_lures"
                                    or (ns.GetProfessionModuleKey and ns.GetProfessionModuleKey(expansion.key, profession))
                                    or ("prof_" .. profession.key)
                                visible = MR:IsRowEnabled(modKey, rowKey)
                            else
                                local entryId = GetEntryVisibilityId(expansion.key, profession.key, section.key, i)
                                visible = not (entryVisibility and entryVisibility[entryId] == false)
                            end
                            if visible then
                                visibleEntries[#visibleEntries + 1] = entry
                            end
                        end

                        if #visibleEntries > 0 then
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
                            sectionHeader:SetText(section.label)
                            cardY = cardY + 22

                            for _, entry in ipairs(VisibleSortedEntries(visibleEntries)) do
                                local rr, rg, rb = GetMainMenuEntryColor(expansion.key, profession, section.key, entry, cr, cg, cb)
                                if entry.questID or entry.questIDs or entry.spellID then
                                    cardY = RenderEntryRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, rr, rg, rb, db, entry, section.key)
                                else
                                    cardY = RenderReferenceRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, rr, rg, rb, entry, section.key)
                                end
                            end
                            cardY = cardY + 4
                        end
                        if section.key == "weekly" and not catchupRendered then
                            cardY = RenderCatchupRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, profession, expansion)
                            catchupRendered = true
                        end
                        end
                    end
                    if not catchupRendered then
                        cardY = RenderCatchupRow(card, cardW, cardY, rowHeight, fontSize, contentAlpha, chromeAlpha, accentAlpha, cr, cg, cb, profession, expansion)
                    end
                    end
                end

                card:SetHeight(isCollapsed and collapsedRowH or (cardY + 8))
                yOff = yOff + card:GetHeight() + (isCollapsed and 3 or 8)
                if expansion.key == "midnight" and profession.key == "skinning" then
                    yOff = RenderSkinningLuresCard(content, width, yOff, fontSize, contentAlpha, chromeAlpha, accentAlpha, db, expansion, profession)
                end
        end

        if #visibleProfessions > 0 and expansion.sharedCatchupItemID then
            local shardCount = GetItemCountRemaining(expansion.sharedCatchupItemID)
            local shardRow = RenderFontString(content, "OVERLAY")
            shardRow:SetFont(ns.FONT_ROWS, fontSize - 1, GetFontFlags())
            shardRow:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -yOff)
            shardRow:SetTextColor(0.70, 0.85, 1.00, 0.90)
            shardRow:SetText(string.format(L["ProfKnowledge_LegacyDragonShard"] or "Dragon Shards of Knowledge: %d", shardCount))
            yOff = yOff + 18 + 6
        end
      end
    end

    return yOff
end

PK.BuildProfessionCards = BuildProfessionCards
