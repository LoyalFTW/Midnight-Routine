local _, ns = ...
if ns.Inactive then return end
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")
local MakeBackdrop = ns.MakeBackdrop
local FONT_ROWS = ns.FONT_ROWS
local FONT_HEADERS = ns.FONT_HEADERS
local GetFontSize = ns.GetFontSize
local GetFontFlags = ns.GetFontFlags
local function GetLocaleFont()
    return (ns.GetDefaultFontTexture and ns.GetDefaultFontTexture()) or "Fonts\\FRIZQT__.TTF"
end
local function Text(key, fallback)
    local value = L[key]
    return (value and value ~= key) and value or fallback
end
local function RefreshFonts()
    if ns.EnsureFonts then
        FONT_HEADERS, FONT_ROWS = ns.EnsureFonts()
    end
    local fallback = GetLocaleFont()
    if not FONT_ROWS or FONT_ROWS == "" then FONT_ROWS = fallback end
    if not FONT_HEADERS or FONT_HEADERS == "" then FONT_HEADERS = fallback end
end
local function SetFontForText(fontString, text, size, flags)
    if not fontString then return end
    local fontPath = FONT_ROWS
    if ns.ResolveFontForText then
        fontPath = ns.ResolveFontForText(text, FONT_ROWS)
    elseif ns.ScriptFontForText then
        fontPath = ns.ScriptFontForText(text) or FONT_ROWS
    end
    fontString:SetFont(fontPath, size, flags)
end

local function ApplyDialogEditBoxFont(editBox, fontSize)
    if not editBox then return end
    SetFontForText(editBox, editBox.GetText and editBox:GetText() or "", math.max(9, fontSize), GetFontFlags())
end

local function ApplyCustomTaskDialogTheme(frame)
    if not frame then return end

    RefreshFonts()
    local fontSize  = GetFontSize()
    local rowFont   = math.max(8,  fontSize - 1)
    local hintFont  = math.max(7,  fontSize - 2)
    local editFont  = math.max(9,  fontSize)


    local function sf(fs, size)
        if fs then SetFontForText(fs, fs:GetText(), size, GetFontFlags()) end
    end
    sf(frame.title,           math.max(10, fontSize + 1))
    sf(frame.trackingLabel,   rowFont)
    sf(frame.progressHeader,  rowFont)
    sf(frame.behaviorHeader,  rowFont)
    sf(frame.nameLabel,       rowFont)
    sf(frame.categoryLabel,   rowFont)
    sf(frame.questLabel,      rowFont)
    sf(frame.encounterLabel,  rowFont)
    sf(frame.difficultyLabel, rowFont)
    sf(frame.diffHint,        hintFont)
    sf(frame.targetLabel,     rowFont)
    sf(frame.resetLabel,      rowFont)

    if frame.title then frame.title:SetFont(ns.FONT_HEADERS, math.max(10, fontSize + 1), GetFontFlags()) end

    local checks = { frame.categorySeparateModuleCheck, frame.orderedQuestCheck, frame.manualQuestCheck, frame.autoUpdateCheck, frame.sharedTaskCheck, frame.accountCompleteCheck, frame.cityReminderCheck }
    for _, cb in ipairs(checks) do
        sf(cb._text, rowFont)
    end
    if frame.difficultyChecks then
        for _, cb in ipairs(frame.difficultyChecks) do
            sf(cb._text, rowFont)
        end
    end

    for _, group in ipairs(frame.choiceGroups) do
        for _, button in ipairs(group) do
            SetFontForText(button._label, button._label:GetText(), rowFont, GetFontFlags())
        end
    end

    if frame.input          then ApplyDialogEditBoxFont(frame.input,          editFont) end
    if frame.categoryInput  then ApplyDialogEditBoxFont(frame.categoryInput,  editFont) end
    if frame.questInput     then ApplyDialogEditBoxFont(frame.questInput,     editFont) end
    if frame.encounterInput then ApplyDialogEditBoxFont(frame.encounterInput, editFont) end
    if frame.targetInput    then ApplyDialogEditBoxFont(frame.targetInput,    editFont) end
    if frame.categoryDropdown and frame.categoryDropdown.ApplyFonts then frame.categoryDropdown:ApplyFonts() end

    sf(frame.saveBtn._label, rowFont)
    sf(frame.cancelBtn._label, rowFont)
    sf(frame.deleteBtn._label, rowFont)
    frame:LayoutFields()
end

local function ApplyCustomTasksTitleDialogTheme(frame)
    if not frame then
        return
    end

    RefreshFonts()
    local fontSize = GetFontSize()
    local rowFont = math.max(8, fontSize - 1)
    local hintFont = math.max(8, fontSize - 2)
    local editFont = math.max(9, fontSize)
    local boxHeight = math.max(32, fontSize + 20)
    local hintGap = math.max(8, math.floor(fontSize * 0.7))
    local frameWidth = math.max(340, 220 + (fontSize * 8))
    local frameHeight = math.max(190, 150 + (fontSize * 9))

    frame:SetSize(frameWidth, frameHeight)

    if frame.titleText then
        frame.titleText:SetFont(ns.FONT_HEADERS, math.max(10, fontSize + 1), GetFontFlags())
        frame.titleText:SetWidth(frameWidth - 24)
    end
    if frame.subtitle then
        frame.subtitle:SetFont(ns.FONT_ROWS, rowFont, GetFontFlags())
        frame.subtitle:SetWidth(frameWidth - 24)
    end
    if frame.inputBg then
        frame.inputBg:SetHeight(boxHeight)
    end
    if frame.input then
        ApplyDialogEditBoxFont(frame.input, editFont)
    end
    if frame.hint then
        frame.hint:SetFont(ns.FONT_ROWS, hintFont, GetFontFlags())
        frame.hint:ClearAllPoints()
        frame.hint:SetPoint("TOPLEFT", frame.inputBg, "BOTTOMLEFT", 0, -hintGap)
        frame.hint:SetPoint("TOPRIGHT", frame.inputBg, "BOTTOMRIGHT", 0, -hintGap)
    end
    if frame.saveBtn and frame.saveBtn._label then
        frame.saveBtn._label:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
    end
    if frame.cancelBtn and frame.cancelBtn._label then
        frame.cancelBtn._label:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
    end
end

local function ApplyCustomTaskCategoryDialogTheme(frame)
    if not frame then return end
    RefreshFonts()
    local fontSize = GetFontSize()
    frame:SetSize(math.max(440, 330 + (fontSize * 10)), math.max(286, 220 + (fontSize * 6)))
    if frame.titleText then frame.titleText:SetFont(ns.FONT_HEADERS, math.max(10, fontSize + 1), GetFontFlags()) end
    if frame.subtitle then frame.subtitle:SetFont(ns.FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags()) end
    if frame.nameLabel then frame.nameLabel:SetFont(ns.FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags()) end
    if frame.input then ApplyDialogEditBoxFont(frame.input, math.max(9, fontSize)) end
    if frame.hint then frame.hint:SetFont(ns.FONT_ROWS, math.max(8, fontSize - 2), GetFontFlags()) end
    if frame.separateModuleCheck and frame.separateModuleCheck._text then
        frame.separateModuleCheck._text:SetFont(ns.FONT_ROWS, math.max(8, fontSize - 1), GetFontFlags())
    end
    for _, button in ipairs({ frame.saveBtn, frame.cancelBtn, frame.removeBtn, frame.deleteAllBtn }) do
        if button and button._label then
            button._label:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
        end
    end
end

local function EnsureCustomTaskDialog()
    if MR.customTaskDialog then
        return MR.customTaskDialog
    end


    local PAD  = 14
    local GAP  = 7
    local IGAP = 6
    local IH   = 28
    local frame = ns.StyledFrame(UIParent, nil, "DIALOG", 80)
    MR:RegisterPriorityFrame(frame)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    frame:Hide()

    local function BindHelp(control, key, fallback)
        if control and ns.BindTooltip then
            ns.BindTooltip(control, {
                text = Text(key, fallback),
                wrap = true,
            })
        end
    end

    local header = ns.TitleBar(frame, 28)
    header:SetScript("OnDragStart", function()
        frame.moving = true
        frame:SetClampedToScreen(false)
        frame:StartMoving()
    end)
    local function StopMoving()
        if not frame.moving then return end
        frame.moving = nil
        frame:StopMovingOrSizing()
        if frame.layoutPending then frame:LayoutFields() end
        frame:SetClampedToScreen(true)
    end
    header:SetScript("OnDragStop", StopMoving)
    frame:SetScript("OnHide", StopMoving)

    local close = ns.CloseButton(header, function() frame:Hide() end)
    local title = header:CreateFontString(nil, "OVERLAY")
    title:SetFont(ns.FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
    title:SetPoint("LEFT", header, "LEFT", PAD, 0)
    title:SetPoint("RIGHT", close, "LEFT", -6, 0)
    title:SetJustifyH("LEFT")
    title:SetText(L["CustomTasks_Title"] or "Custom Tasks")
    ns.RegisterThemedFontString(title, 0.92, 0.97, 1)
    frame.title = title

    local function MakeLabel(anchorFrame, anchorPoint, xOff, yOff, text)
        local lbl = frame:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(ns.FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
        lbl:SetPoint("TOPLEFT", anchorFrame, anchorPoint, xOff, yOff)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(text)
        lbl:SetTextColor(0.74, 0.84, 0.92)
        return lbl
    end

    local function MakeInputBg(anchorFrame, anchorPoint, xOff, yOff, w, h)
        local bg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        if w then
            bg:SetSize(w, h or IH)
            bg:SetPoint("TOPLEFT", anchorFrame, anchorPoint, xOff, yOff)
        else
            bg:SetHeight(h or IH)
            bg:SetPoint("TOPLEFT",  anchorFrame, anchorPoint, xOff, yOff)
            bg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, 0)
        end
        bg:SetBackdrop(MakeBackdrop())
        ns.HookBackdropFrame(bg, "content")
        bg:SetBackdropColor(0.04, 0.09, 0.16, 0.98)
        bg:SetBackdropBorderColor(0.16, 0.36, 0.42, 1)
        return bg
    end

    local function MakeEditBox(bg, maxLen, isNumeric)
        local eb = CreateFrame("EditBox", nil, bg)
        eb:SetAutoFocus(false)
        eb:SetPoint("TOPLEFT",     bg, "TOPLEFT",     6, -6)
        eb:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -6,  6)
        eb:SetFontObject(ChatFontNormal)
        eb:SetTextInsets(0, 0, 0, 0)
        eb:SetMaxLetters(maxLen or 120)
        eb:SetTextColor(0.95, 0.97, 1)
        if isNumeric then eb:SetNumeric(true) end
        eb:SetScript("OnEscapePressed", function() frame:Hide() end)
        eb:SetScript("OnTextChanged", function(selfEdit)
            ApplyDialogEditBoxFont(selfEdit, GetFontSize())
            if frame.RefreshSmartState and not frame.loadingTask then frame:RefreshSmartState() end
        end)
        return eb
    end


    local nameLabel = MakeLabel(header, "BOTTOMLEFT", 0, -8, L["CustomTasks_NameLabel"])
    local nameBg    = MakeInputBg(nameLabel, "BOTTOMLEFT", 0, -IGAP)
    local input     = MakeEditBox(nameBg, 120)
    input:SetScript("OnEscapePressed", function() frame:Hide() end)
    frame.nameLabel = nameLabel
    frame.inputBg   = nameBg
    frame.input     = input
    BindHelp(input, "CustomTasks_TaskNameTooltip", "The name shown for this custom task.")


    local categoryLabel = MakeLabel(nameBg, "BOTTOMLEFT", 0, -GAP, Text("CustomTasks_CategoryLabel", "Category (optional)"))
    local categoryBg = MakeInputBg(categoryLabel, "BOTTOMLEFT", 0, -IGAP)
    local categoryInput = MakeEditBox(categoryBg, 80)
    categoryInput:SetPoint("BOTTOMRIGHT", categoryBg, "BOTTOMRIGHT", -32, 6)
    frame.categoryLabel = categoryLabel
    frame.categoryBg = categoryBg
    frame.categoryInput = categoryInput
    BindHelp(categoryInput, "CustomTasks_CategoryTooltip", "Type a new category name or choose an existing category. Leave blank for no category.")

    local categoryDropdown = ns.CreateDropdown(categoryBg, {
        width = 26,
        arrowOnly = true,
        menuAnchor = categoryBg,
        height = IH,
        fontSize = function() return math.max(8, GetFontSize() - 1) end,
        maxVisibleRows = 9,
        getOptions = function()
            local options = {
                { key = "", label = Text("CustomTasks_NoCategory", "No category") },
            }
            local current = (frame.categoryInput and frame.categoryInput:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
            local foundCurrent = current == ""
            local categories = MR.GetCustomTaskCategories and MR:GetCustomTaskCategories(frame.resetType) or {}
            for _, category in ipairs(categories) do
                options[#options + 1] = { key = category, label = category }
                if category == current then
                    foundCurrent = true
                end
            end
            if not foundCurrent then
                options[#options + 1] = { key = current, label = current }
            end
            return options
        end,
        getSelected = function()
            return (frame.categoryInput and frame.categoryInput:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
        end,
        onSelect = function(category)
            if frame.categoryInput then
                frame.categoryInput:SetText(category or "")
            end
        end,
    })
    categoryDropdown:SetPoint("RIGHT", categoryBg, "RIGHT", 0, 0)
    frame.categoryDropdown = categoryDropdown

    local categorySeparateModuleCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    ns.ThemeCheckButton(categorySeparateModuleCheck)
    categorySeparateModuleCheck:SetSize(20, 20)
    categorySeparateModuleCheck:SetPoint("TOPLEFT", categoryBg, "BOTTOMLEFT", 0, -3)
    local categorySeparateModuleText = frame:CreateFontString(nil, "OVERLAY")
    categorySeparateModuleText:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    categorySeparateModuleText:SetPoint("LEFT", categorySeparateModuleCheck, "RIGHT", 2, 0)
    categorySeparateModuleText:SetText(Text("CustomTasks_ShowAsSeparateModule", "Show as a separate module"))
    categorySeparateModuleText:SetTextColor(0.84, 0.90, 0.96)
    categorySeparateModuleCheck._text = categorySeparateModuleText
    frame.categorySeparateModuleCheck = categorySeparateModuleCheck
    BindHelp(categorySeparateModuleCheck, "CustomTasks_SeparateModuleTaskTooltip", "New categories can choose this setting here. Existing categories keep their current setting; manage them from the category's module options.")

    function frame:RefreshCategoryModuleState()
        local category = (self.categoryInput and self.categoryInput:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local exists = false
        if category ~= "" and MR.GetCustomTaskCategories then
            for _, existingCategory in ipairs(MR:GetCustomTaskCategories(self.resetType)) do
                if existingCategory == category then
                    exists = true
                    break
                end
            end
        end
        self.categorySeparateModuleCheck:SetShown(category ~= "")
        self.categorySeparateModuleCheck._text:SetShown(category ~= "")
        if category == "" then
            self.categorySeparateModuleCheck:SetChecked(false)
            self.categorySeparateModuleCheck:Disable()
            self.categorySeparateModuleCheck:SetAlpha(0.40)
            self.categorySeparateModuleCheck._text:SetAlpha(0.40)
            self.categorySeparateModuleCheck:EnableMouse(true)
            return
        end
        if exists then
            self.categorySeparateModuleCheck:SetChecked(MR:IsCustomTaskCategorySeparateModule(self.resetType, category))
            self.categorySeparateModuleCheck:Disable()
            self.categorySeparateModuleCheck:SetAlpha(0.58)
            self.categorySeparateModuleCheck._text:SetAlpha(0.58)
        else
            self.categorySeparateModuleCheck:Enable()
            self.categorySeparateModuleCheck:SetAlpha(1)
            self.categorySeparateModuleCheck._text:SetAlpha(1)
        end
        self.categorySeparateModuleCheck:EnableMouse(true)
    end

    categoryInput:SetScript("OnTextChanged", function(selfEdit)
        ApplyDialogEditBoxFont(selfEdit, GetFontSize())
        if frame.categoryDropdown then frame.categoryDropdown:Update() end
        local wasShown = categorySeparateModuleCheck:IsShown()
        frame:RefreshCategoryModuleState()
        if frame.LayoutFields and not frame.loadingTask and wasShown ~= categorySeparateModuleCheck:IsShown() then
            frame:LayoutFields()
        end
    end)


    local trackingLabel = MakeLabel(categorySeparateModuleCheck, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_TrackBy"])
    frame.trackingLabel = trackingLabel

    local questLabel = MakeLabel(trackingLabel, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_QuestIdsLabel"] or "Quest ID(s)")
    local questBg    = MakeInputBg(questLabel, "BOTTOMLEFT", 0, -IGAP)
    local questInput = MakeEditBox(questBg, 120)
    frame.questLabel = questLabel
    frame.questBg    = questBg
    frame.questInput = questInput
    BindHelp(questInput, "CustomTasks_QuestIdsTooltip", "Enter one or more quest IDs separated by commas or spaces. Target 1 completes when any listed quest is done; increase Target to require more.")

    local encounterLabel = MakeLabel(trackingLabel, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_EncounterIdsLabel"] or "Encounter ID(s)")
    local encounterBg    = MakeInputBg(encounterLabel, "BOTTOMLEFT", 0, -IGAP)
    local encounterInput = MakeEditBox(encounterBg, 120)
    frame.encounterLabel  = encounterLabel
    frame.encounterBg     = encounterBg
    frame.encounterInput  = encounterInput
    BindHelp(encounterInput, "CustomTasks_EncounterIdsTooltip", "Enter one or more encounter IDs for automatic boss-kill tracking. Quest IDs and encounter IDs cannot be combined in one task.")


    local DIFF_OPTIONS = {
        { id = 17, label = "LFR" },
        { id = 14, label = "Normal" },
        { id = 15, label = "Heroic" },
        { id = 16, label = "Mythic" },
    }
    local difficultyLabel = MakeLabel(encounterBg, "BOTTOMLEFT", 0, -GAP, Text("CustomTasks_EncounterDifficultyHeader", "Encounter difficulties"))
    frame.difficultyLabel = difficultyLabel

    frame.difficultyChecks = {}
    local prevDiffCheck = nil
    for i, opt in ipairs(DIFF_OPTIONS) do
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        ns.ThemeCheckButton(cb)
        cb:SetSize(20, 20)
        if i == 1 then
            cb:SetPoint("TOPLEFT", difficultyLabel, "BOTTOMLEFT", 0, -4)
        else
            cb:SetPoint("LEFT", prevDiffCheck._text, "RIGHT", 14, 0)
        end
        cb:SetChecked(true)
        local cbText = frame:CreateFontString(nil, "OVERLAY")
        cbText:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        cbText:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        cbText:SetText(opt.label)
        cbText:SetTextColor(0.84, 0.90, 0.96)
        cb._text  = cbText
        cb._diffId = opt.id
        frame.difficultyChecks[i] = cb
        BindHelp(cb, "CustomTasks_DifficultyTooltip", "Choose which raid difficulties are tracked. Each selected difficulty can contribute once.")
        prevDiffCheck = cb
    end

    local diffHint = frame:CreateFontString(nil, "OVERLAY")
    diffHint:SetFont(ns.FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    diffHint:SetPoint("TOPLEFT", difficultyLabel, "BOTTOMLEFT", 0, -24)
    diffHint:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, 0)
    diffHint:SetJustifyH("LEFT")
    diffHint:SetText(Text("CustomTasks_DifficultyHint", "Each selected difficulty is tracked once."))
    diffHint:SetTextColor(0.40, 0.52, 0.62)
    frame.diffHint = diffHint






    local progressHeader = MakeLabel(header, "BOTTOMLEFT", 0, 0, L["CustomTasks_ProgressHeader"])
    frame.progressHeader = progressHeader

    local targetLabel = MakeLabel(progressHeader, "BOTTOMLEFT", 0, -8, L["CustomTasks_TargetLabel"] or "Target")
    local targetBg = MakeInputBg(targetLabel, "BOTTOMLEFT", 0, -IGAP)
    local targetInput = MakeEditBox(targetBg, 3, true)
    targetInput:ClearAllPoints()
    targetInput:SetPoint("TOPLEFT", targetBg, "TOPLEFT", 8, -5)
    targetInput:SetPoint("BOTTOMLEFT", targetBg, "BOTTOMLEFT", 8, 5)

    local function GetCounterTarget()
        return math.min(999, math.max(2, math.floor(tonumber(targetInput:GetText()) or 2)))
    end

    local stepper = CreateFrame("Frame", nil, targetBg)
    stepper:SetWidth(18)
    stepper:SetPoint("TOPRIGHT", targetBg, "TOPRIGHT", -2, -2)
    stepper:SetPoint("BOTTOMRIGHT", targetBg, "BOTTOMRIGHT", -2, 2)

    local function StepTarget(delta)
        frame.counterTarget = tostring(math.min(999, math.max(2, GetCounterTarget() + delta)))
        targetInput:SetText(frame.counterTarget)
    end

    local increase = ns.HeaderButton(stepper, {
        text = "^",
        fontSize = 9,
        iconY = -1,
        themed = true,
        onClick = function() StepTarget(1) end,
    })
    increase:SetPoint("TOPLEFT", stepper, "TOPLEFT")
    increase:SetPoint("BOTTOMRIGHT", stepper, "RIGHT")

    local decrease = ns.HeaderButton(stepper, {
        text = "v",
        fontSize = 9,
        themed = true,
        onClick = function() StepTarget(-1) end,
    })
    decrease:SetPoint("TOPLEFT", stepper, "LEFT")
    decrease:SetPoint("BOTTOMRIGHT", stepper, "BOTTOMRIGHT")

    local function RefreshTargetStepper()
        local value = GetCounterTarget()
        local enabled = targetInput:IsEnabled()
        increase:SetEnabled(enabled and value < 999)
        decrease:SetEnabled(enabled and value > 2)
        increase:SetAlpha(increase:IsEnabled() and 1 or 0.45)
        decrease:SetAlpha(decrease:IsEnabled() and 1 or 0.45)
    end

    targetInput:SetScript("OnTextChanged", function(selfEdit, userInput)
        ApplyDialogEditBoxFont(selfEdit, GetFontSize())
        if userInput then frame.counterTarget = selfEdit:GetText() end
        RefreshTargetStepper()
    end)
    frame.targetLabel = targetLabel
    frame.targetBg    = targetBg
    frame.targetInput = targetInput
    ns.BindTooltip(targetInput, function()
        return {
            text = string.format("%s\n0/%d", L["CustomTasks_ProgressTargetTooltip"], GetCounterTarget()),
            wrap = true,
        }
    end)

    local orderedQuestCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    ns.ThemeCheckButton(orderedQuestCheck)
    orderedQuestCheck:SetSize(20, 20)
    orderedQuestCheck:SetPoint("TOPLEFT", targetBg, "BOTTOMLEFT", 0, -4)
    local orderedQuestText = frame:CreateFontString(nil, "OVERLAY")
    orderedQuestText:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    orderedQuestText:SetPoint("LEFT", orderedQuestCheck, "RIGHT", 2, 0)
    orderedQuestText:SetText(Text("CustomTasks_OrderedQuestSequence", "Track quest IDs in entered order"))
    orderedQuestText:SetTextColor(0.84, 0.90, 0.96)
    orderedQuestCheck._text = orderedQuestText
    orderedQuestCheck:SetScript("OnClick", function(selfBtn)
        frame.orderedQuestSequence = selfBtn:GetChecked() and true or false
        if frame.RefreshSmartState then frame:RefreshSmartState() end
    end)
    frame.orderedQuestCheck = orderedQuestCheck
    BindHelp(orderedQuestCheck, "CustomTasks_OrderedQuestSequenceTooltip", "Preserves the entered quest-ID order and counts only consecutive completed steps. Target is set automatically to the number of unique IDs.")

    local resetLabel = MakeLabel(header, "BOTTOMLEFT", 0, 0, L["CustomTasks_ResetType"])
    frame.resetLabel = resetLabel
    local behaviorHeader = MakeLabel(header, "BOTTOMLEFT", 0, 0, L["CustomTasks_BehaviorHeader"])
    ns.RegisterThemedFontString(behaviorHeader, 0.38, 0.78, 0.86)
    frame.behaviorHeader = behaviorHeader

    local manualQuestCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    ns.ThemeCheckButton(manualQuestCheck)
    manualQuestCheck:SetSize(20, 20)
    manualQuestCheck:SetPoint("TOPLEFT", behaviorHeader, "BOTTOMLEFT", 0, -6)
    local manualQuestText = frame:CreateFontString(nil, "OVERLAY")
    manualQuestText:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    manualQuestText:SetPoint("LEFT", manualQuestCheck, "RIGHT", 2, 0)
    manualQuestText:SetText(L["CustomTasks_ManualQuestClicks"] or "Allow manual clicks")
    manualQuestText:SetTextColor(0.84, 0.90, 0.96)
    manualQuestCheck._text = manualQuestText
    manualQuestCheck:SetScript("OnClick", function(selfBtn)
        frame.allowManualQuestClicks = selfBtn:GetChecked() and true or false
        if frame.RefreshSmartState then frame:RefreshSmartState() end
    end)
    frame.manualQuestCheck = manualQuestCheck
    BindHelp(manualQuestCheck, "CustomTasks_ManualQuestClicksTooltip", "Allows a single-target quest task to be checked or unchecked manually when automatic quest detection is not enough.")

    local autoUpdateCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    ns.ThemeCheckButton(autoUpdateCheck)
    autoUpdateCheck:SetSize(20, 20)
    autoUpdateCheck:SetPoint("TOPLEFT", manualQuestCheck, "BOTTOMLEFT", 0, -4)
    local autoUpdateText = frame:CreateFontString(nil, "OVERLAY")
    autoUpdateText:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    autoUpdateText:SetPoint("LEFT", autoUpdateCheck, "RIGHT", 2, 0)
    autoUpdateText:SetText(L["CustomTasks_AutoUpdateInstances"] or "Auto-update in instances")
    autoUpdateText:SetTextColor(0.84, 0.90, 0.96)
    autoUpdateCheck._text = autoUpdateText
    autoUpdateCheck:SetScript("OnClick", function(selfBtn)
        frame.autoUpdateInstances = selfBtn:GetChecked() and true or false
    end)
    frame.autoUpdateCheck = autoUpdateCheck
    BindHelp(autoUpdateCheck, "CustomTasks_AutoUpdateInstancesTooltip", "Updates this task while inside dungeons, raids, scenarios, and other instances.")

    local sharedTaskCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    ns.ThemeCheckButton(sharedTaskCheck)
    sharedTaskCheck:SetSize(20, 20)
    sharedTaskCheck:SetPoint("TOPLEFT", autoUpdateCheck, "BOTTOMLEFT", 0, -4)
    local sharedTaskText = frame:CreateFontString(nil, "OVERLAY")
    sharedTaskText:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    sharedTaskText:SetPoint("LEFT", sharedTaskCheck, "RIGHT", 2, 0)
    sharedTaskText:SetText(Text("CustomTasks_SharedTask", "Show on all alts"))
    sharedTaskText:SetTextColor(0.84, 0.90, 0.96)
    sharedTaskCheck._text = sharedTaskText
    sharedTaskCheck:SetScript("OnClick", function(selfBtn)
        frame.taskScope = selfBtn:GetChecked() and "shared" or "character"
        if not selfBtn:GetChecked() then
            frame.accountWideComplete = false
            if frame.accountCompleteCheck then
                frame.accountCompleteCheck:SetChecked(false)
                frame.accountCompleteCheck:Disable()
                if frame.accountCompleteCheck._text then
                    frame.accountCompleteCheck._text:SetAlpha(0.40)
                end
            end
        else
            if frame.accountCompleteCheck then
                frame.accountCompleteCheck:Enable()
                if frame.accountCompleteCheck._text then
                    frame.accountCompleteCheck._text:SetAlpha(1)
                end
            end
        end
    end)
    frame.sharedTaskCheck = sharedTaskCheck
    BindHelp(sharedTaskCheck, "CustomTasks_SharedTaskTooltip", "Shows this task on every character. Completion remains separate for each character unless Complete on all alts is enabled.")

    local accountCompleteCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    ns.ThemeCheckButton(accountCompleteCheck)
    accountCompleteCheck:SetSize(20, 20)
    accountCompleteCheck:SetPoint("TOPLEFT", sharedTaskCheck, "BOTTOMLEFT", 0, -4)
    local accountCompleteText = frame:CreateFontString(nil, "OVERLAY")
    accountCompleteText:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    accountCompleteText:SetPoint("LEFT", accountCompleteCheck, "RIGHT", 2, 0)
    accountCompleteText:SetText(Text("CustomTasks_AccountComplete", "Complete on all alts"))
    accountCompleteText:SetTextColor(0.84, 0.90, 0.96)
    accountCompleteCheck._text = accountCompleteText
    accountCompleteCheck:SetScript("OnClick", function(selfBtn)
        frame.accountWideComplete = selfBtn:GetChecked() and true or false
    end)
    frame.accountCompleteCheck = accountCompleteCheck
    BindHelp(accountCompleteCheck, "CustomTasks_AccountCompleteTooltip", "Shares this task's completion across all characters. This is available only when Show on all alts is enabled.")

    local cityReminderCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    ns.ThemeCheckButton(cityReminderCheck)
    cityReminderCheck:SetSize(20, 20)
    cityReminderCheck:SetPoint("TOPLEFT", accountCompleteCheck, "TOPLEFT", 182, 0)
    local cityReminderText = frame:CreateFontString(nil, "OVERLAY")
    cityReminderText:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    cityReminderText:SetPoint("LEFT", cityReminderCheck, "RIGHT", 2, 0)
    cityReminderText:SetText(L["CustomTasks_CityReminder"])
    cityReminderText:SetTextColor(0.84, 0.90, 0.96)
    cityReminderCheck._text = cityReminderText
    frame.cityReminderCheck = cityReminderCheck
    BindHelp(cityReminderCheck, "CustomTasks_CityReminderTooltip", L["CustomTasks_CityReminderTooltip"])

    local function CreateDialogButton(label, color, borderColor)
        local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        btn:SetBackdrop(MakeBackdrop())
        local text = btn:CreateFontString(nil, "OVERLAY")
        SetFontForText(text, label, math.max(8, GetFontSize() - 1), GetFontFlags())
        text:SetPoint("CENTER", btn)
        text:SetText(label)
        text:SetTextColor(0.92, 0.96, 1)
        btn._label = text

        local function RefreshStyle(self)
            local hovered = self:IsMouseOver()
            local theme = MR.db.profile.themeColorMode == "default" and ns.GetInterfaceTheme()
            local fill = color or (theme and (hovered and theme.headerColor or theme.contentTint)) or ns.COLORS.bg
            local edge = borderColor or (theme and (hovered and theme.selectedCardBorder or theme.contentBorder))
            local r, g, b
            if edge then r, g, b = unpack(edge) else r, g, b = ns.ResolveThemeColor(0.28, 0.34, 0.42) end
            local lift = hovered and (color or not theme) and 0.04 or 0
            self:SetBackdropColor(fill[1] + lift, fill[2] + lift, fill[3] + lift, 0.95)
            self:SetBackdropBorderColor(r, g, b, hovered and 1 or 0.8)
        end

        ns.RegisterThemedState(btn, RefreshStyle)
        btn:SetScript("OnEnter", RefreshStyle)
        btn:SetScript("OnLeave", RefreshStyle)
        return btn
    end

    local saveBtn = CreateDialogButton(L["CustomTasks_Save"], { 0.10, 0.26, 0.20 }, { 0.28, 0.78, 0.50 })
    local cancelBtn = CreateDialogButton(L["CustomTasks_Cancel"])
    local deleteBtn = CreateDialogButton(L["CustomTasks_Delete"], { 0.22, 0.08, 0.08 }, { 0.72, 0.20, 0.20 })

    saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, PAD)
    cancelBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0)
    deleteBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, PAD)

    cancelBtn:SetScript("OnClick", function() frame:Hide() end)
    deleteBtn:SetScript("OnClick", function()
        if frame.taskId then MR:DeleteCustomTask(frame.taskId, frame.originalTaskScope or frame.taskScope) end
        frame:Hide()
    end)
    frame.saveBtn   = saveBtn
    frame.cancelBtn = cancelBtn
    frame.deleteBtn = deleteBtn
    BindHelp(saveBtn, "CustomTasks_SaveTooltip", "Save this custom task.")
    BindHelp(cancelBtn, "CustomTasks_CancelTooltip", "Close without saving changes.")
    BindHelp(deleteBtn, "CustomTasks_DeleteTooltip", "Permanently delete this custom task.")


    local function ChoiceGroup(field, choices, onSelect)
        local group = {}
        for _, choice in ipairs(choices) do
            local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
            button:SetBackdrop(MakeBackdrop())
            local label = button:CreateFontString(nil, "OVERLAY")
            SetFontForText(label, choice.label, math.max(8, GetFontSize() - 1), GetFontFlags())
            label:SetPoint("CENTER", button)
            label:SetText(choice.label)
            button._label = label
            button.value = choice.value
            function button:RefreshStyle()
                local selected = frame[field] == self.value
                local r, g, b = ns.ResolveThemeColor(0.28, 0.64, 0.65)
                local theme = ns.GetInterfaceTheme and ns.GetInterfaceTheme()
                if theme and MR.db.profile.themeColorMode == "default" then
                    local active = selected or self:IsMouseOver()
                    local fill = active and theme.headerColor or theme.contentTint
                    r, g, b = unpack(active and theme.selectedCardBorder or theme.contentBorder)
                    self:SetBackdropColor(fill[1], fill[2], fill[3], 1)
                else
                    local intensity = selected and 0.58 or (self:IsMouseOver() and 0.32 or 0.18)
                    self:SetBackdropColor(0.05 + r * intensity, 0.05 + g * intensity, 0.05 + b * intensity, 1)
                end
                self:SetBackdropBorderColor(r, g, b, selected and 1 or 0.55)
                self._label:SetTextColor(0.94, 0.96, 0.98, self:IsEnabled() and 1 or 0.55)
            end
            ns.RegisterThemedState(button, button.RefreshStyle)
            button:SetScript("OnEnter", button.RefreshStyle)
            button:SetScript("OnLeave", button.RefreshStyle)
            button:SetScript("OnClick", function(self)
                frame[field] = self.value
                if onSelect then onSelect() end
                frame:RefreshSmartState()
            end)
            group[#group + 1] = button
        end
        return group
    end

    local trackingChoices = ChoiceGroup("trackingMode", {
        { value = "manual", label = L["CustomTasks_ModeManual"] },
        { value = "quest", label = L["CustomTasks_ModeQuest"] },
        { value = "encounter", label = L["CustomTasks_ModeEncounter"] },
    })
    local progressChoices = ChoiceGroup("displayProgressMode", {
        { value = "checkbox", label = L["CustomTasks_ModeCheckbox"] },
        { value = "counter", label = L["CustomTasks_ModeCounter"] },
    }, function() frame.progressMode = frame.displayProgressMode end)
    local resetChoices = ChoiceGroup("resetType", {
        { value = "weekly", label = L["CustomTasks_WeeklyHeader"] },
        { value = "daily", label = L["CustomTasks_DailyHeader"] },
        { value = "none", label = L["CustomTasks_ResetNone"] },
    }, function()
        categoryDropdown:Update()
        frame:RefreshCategoryModuleState()
    end)
    BindHelp(resetChoices[1], "CustomTasks_ResetWeeklyTooltip", "Clears this task at the regional weekly reset.")
    BindHelp(resetChoices[2], "CustomTasks_ResetDailyTooltip", "Clears this task at the regional daily reset.")
    BindHelp(resetChoices[3], "CustomTasks_ResetNoneTooltip", "Keeps this task completed until you manually change or delete it.")
    frame.choiceGroups = { trackingChoices, progressChoices, resetChoices }

    local progressDivider = frame:CreateTexture(nil, "ARTWORK")
    local behaviorDivider = frame:CreateTexture(nil, "ARTWORK")
    local footerDivider = frame:CreateTexture(nil, "ARTWORK")
    ns.RegisterThemedTexture(progressDivider, 0.20, 0.44, 0.48, 0.34)
    ns.RegisterThemedTexture(behaviorDivider, 0.20, 0.44, 0.48, 0.34)
    ns.RegisterThemedTexture(footerDivider, 0.20, 0.44, 0.48, 0.34)

    function frame:LayoutFields()
        if self.moving then
            self.layoutPending = true
            return
        end
        self.layoutPending = nil
        local width = 376
        local contentWidth = width - 2 * PAD
        local controlHeight = math.max(IH, GetFontSize() + 12)
        local y = header:GetHeight() + 10
        local labelWidth = math.max(categoryLabel:GetUnboundedStringWidth(), trackingLabel:GetUnboundedStringWidth(),
            progressHeader:GetUnboundedStringWidth(), resetLabel:GetUnboundedStringWidth()) + 10
        labelWidth = math.min(math.ceil(labelWidth), 145)

        local function place(control, x, top)
            control:ClearAllPoints()
            control:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + x, -top)
        end

        local function divider(line)
            place(line, 0, y)
            line:SetSize(contentWidth, 1)
            y = y + 8
        end

        local function inputRow(label, bg)
            place(label, 0, y)
            y = y + label:GetStringHeight() + 4
            place(bg, 0, y)
            bg:SetSize(contentWidth, controlHeight)
            y = y + controlHeight + GAP
        end

        local function checkRow(left, right, rightX)
            place(left, 0, y)
            local rowHeight = math.max(20, left._text:GetStringHeight())
            if right then
                local leftWidth = 24 + left._text:GetStringWidth()
                local rightWidth = 24 + right._text:GetStringWidth()
                if leftWidth <= rightX and rightX + rightWidth <= contentWidth then
                    place(right, rightX, y)
                    rowHeight = math.max(rowHeight, right._text:GetStringHeight())
                else
                    place(right, 0, y + rowHeight + 2)
                    rowHeight = rowHeight + 2 + math.max(20, right._text:GetStringHeight())
                end
            end
            y = y + rowHeight + 3
        end

        local function choiceRow(label, choices, accessoryWidth)
            local gapWidth = (#choices - 1) * 3
            local minimumWidth = 0
            for _, button in ipairs(choices) do
                minimumWidth = math.max(minimumWidth, button._label:GetUnboundedStringWidth() + 8)
            end
            minimumWidth = minimumWidth * #choices + gapWidth
            local minLabelWidth = math.ceil(label:GetUnboundedStringWidth()) + 10
            local x = accessoryWidth and minLabelWidth or labelWidth
            local inline = minLabelWidth <= x and minimumWidth <= contentWidth - x
            if not inline then x = 0 end
            local top = inline and y or y + label:GetStringHeight() + 4
            local accessoryFits = accessoryWidth and minimumWidth + accessoryWidth <= contentWidth - x
            local available = contentWidth - x - gapWidth - (accessoryFits and accessoryWidth or 0)
            local buttonWidth = math.floor(available / #choices)
            place(label, 0, inline and y + math.max(0, (controlHeight - label:GetStringHeight()) / 2) or y)
            label:SetWidth(inline and x - 5 or contentWidth)
            for index, button in ipairs(choices) do
                place(button, x + (index - 1) * (buttonWidth + 3), top)
                button:SetSize(buttonWidth, controlHeight)
                button._label:SetWidth(buttonWidth - 4)
                button._label:SetJustifyH("CENTER")
                button._label:SetWordWrap(false)
            end
            y = top + controlHeight + GAP
            return accessoryFits and top or nil
        end

        inputRow(nameLabel, nameBg)
        local function alignedInput(label, bg)
            if label:GetUnboundedStringWidth() > labelWidth - 6 then
                inputRow(label, bg)
                return
            end
            place(label, 0, y + math.max(0, (controlHeight - label:GetStringHeight()) / 2))
            place(bg, labelWidth, y)
            bg:SetSize(contentWidth - labelWidth, controlHeight)
            y = y + controlHeight + GAP
        end

        alignedInput(categoryLabel, categoryBg)
        categoryDropdown:SetHeight(controlHeight - 2)
        if categorySeparateModuleCheck:IsShown() then checkRow(categorySeparateModuleCheck) end
        y = y + 3
        choiceRow(trackingLabel, trackingChoices)
        if self.trackingMode == "quest" then
            alignedInput(questLabel, questBg)
            checkRow(orderedQuestCheck, manualQuestCheck, math.ceil(contentWidth / 2))
        elseif self.trackingMode == "encounter" then
            alignedInput(encounterLabel, encounterBg)
            place(difficultyLabel, 0, y)
            y = y + difficultyLabel:GetStringHeight() + 4
            local x = 0
            for _, button in ipairs(self.difficultyChecks) do
                local optionWidth = 24 + button._text:GetStringWidth()
                if x > 0 and x + optionWidth > contentWidth then
                    y = y + 23
                    x = 0
                end
                place(button, x, y)
                x = x + optionWidth + 11
            end
            y = y + 22
            place(diffHint, 0, y)
            diffHint:SetWidth(contentWidth)
            y = y + diffHint:GetStringHeight() + GAP
        end

        divider(progressDivider)
        local isCounter = self.displayProgressMode == "counter"
        local targetWidth = math.max(58, GetFontSize() * 3 + 24)
        local targetLabelWidth = math.ceil(targetLabel:GetUnboundedStringWidth())
        local progressLabelWidth = math.ceil(progressHeader:GetUnboundedStringWidth()) + 10
        local choiceWidth = math.max(progressChoices[1]._label:GetUnboundedStringWidth(),
            progressChoices[2]._label:GetUnboundedStringWidth()) * 2 + 19
        local showTargetLabel = progressLabelWidth + choiceWidth + targetWidth + targetLabelWidth + 18 <= contentWidth
        local targetTop = choiceRow(progressHeader, progressChoices,
            targetWidth + (showTargetLabel and targetLabelWidth + 18 or 10))
        targetLabel:SetShown(isCounter and (showTargetLabel or not targetTop))
        if isCounter then
            local top = targetTop or y
            local targetX = contentWidth - targetWidth
            local labelX = targetTop and targetX - targetLabelWidth - 8 or 0
            place(targetLabel, labelX, top + math.max(0, (controlHeight - targetLabel:GetStringHeight()) / 2))
            place(targetBg, targetX, top)
            targetBg:SetSize(targetWidth, controlHeight)
            targetInput:SetWidth(targetWidth - 30)
            if not targetTop then y = y + controlHeight + GAP end
        end
        choiceRow(resetLabel, resetChoices)
        divider(behaviorDivider)
        place(behaviorHeader, 0, y)
        y = y + behaviorHeader:GetStringHeight() + 5
        local columnWidth = math.floor((contentWidth - 10) / 2)
        local function sharingRow(left, right)
            place(left, 0, y)
            place(right, columnWidth + 10, y)
            for _, button in ipairs({ left, right }) do
                button._text:ClearAllPoints()
                button._text:SetPoint("TOPLEFT", button, "TOPRIGHT", 2, -3)
                button._text:SetWidth(columnWidth - 22)
                button._text:SetJustifyH("LEFT")
                button._text:SetWordWrap(true)
            end
            y = y + math.max(20, left._text:GetStringHeight(), right._text:GetStringHeight()) + 3
        end
        sharingRow(autoUpdateCheck, sharedTaskCheck)
        sharingRow(cityReminderCheck, accountCompleteCheck)
        y = y + 3
        divider(footerDivider)
        local footerButtons = { deleteBtn, cancelBtn, saveBtn }
        local actionWidth = 74
        for _, button in ipairs(footerButtons) do
            actionWidth = math.max(actionWidth, math.ceil(button._label:GetUnboundedStringWidth()) + 18)
        end
        actionWidth = math.min(actionWidth, math.floor((contentWidth - 16) / 3))
        for _, button in ipairs(footerButtons) do
            button:SetSize(actionWidth, controlHeight)
            button._label:SetWidth(actionWidth - 8)
            button._label:SetJustifyH("CENTER")
            button._label:SetWordWrap(false)
        end
        local height = math.ceil(y + controlHeight + PAD)
        if self:GetWidth() ~= width or self:GetHeight() ~= height then self:SetSize(width, height) end
    end

    function frame:RefreshSmartState()
        local isQuest = self.trackingMode == "quest"
        local isEncounter = self.trackingMode == "encounter"
        local questCount = 0
        local seen = {}
        for token in (self.questInput:GetText() or ""):gmatch("%d+") do
            local id = tonumber(token)
            if id > 0 and not seen[id] then
                seen[id] = true
                questCount = questCount + 1
            end
        end

        local ordered = isQuest and questCount > 1 and self.orderedQuestSequence
        local showManual = isQuest and questCount > 0 and not ordered
        self.displayProgressMode = ordered and "counter" or (self.progressMode or "checkbox")
        local isCounter = self.displayProgressMode == "counter"
        questLabel:SetShown(isQuest)
        questBg:SetShown(isQuest)
        orderedQuestCheck:SetShown(isQuest)
        orderedQuestText:SetShown(isQuest)
        orderedQuestCheck:SetEnabled(questCount > 1)
        orderedQuestCheck:EnableMouse(true)
        orderedQuestCheck:SetChecked(ordered)
        orderedQuestText:SetAlpha(questCount > 1 and 1 or 0.45)
        manualQuestCheck:SetShown(isQuest)
        manualQuestText:SetShown(isQuest)
        manualQuestCheck:SetEnabled(showManual)
        manualQuestCheck:EnableMouse(true)
        manualQuestCheck:SetChecked(showManual and self.allowManualQuestClicks)
        manualQuestText:SetAlpha(showManual and 1 or 0.45)
        encounterLabel:SetShown(isEncounter)
        encounterBg:SetShown(isEncounter)
        difficultyLabel:SetShown(isEncounter)
        diffHint:SetShown(isEncounter)
        for _, button in ipairs(self.difficultyChecks) do
            button:SetShown(isEncounter)
            button._text:SetShown(isEncounter)
        end

        local target = ordered and tostring(questCount) or self.counterTarget
        if target and targetInput:GetText() ~= target then targetInput:SetText(target) end
        targetBg:SetShown(isCounter)
        targetInput:SetEnabled(not ordered)
        RefreshTargetStepper()
        targetInput:SetAlpha(ordered and 0.55 or 1)
        for _, button in ipairs(progressChoices) do
            button:SetEnabled(not ordered)
        end

        for _, group in ipairs(self.choiceGroups) do
            for _, button in ipairs(group) do
                button:RefreshStyle()
            end
        end
        local isShared = self.taskScope == "shared"
        accountCompleteCheck:SetEnabled(isShared)
        accountCompleteCheck:EnableMouse(true)
        accountCompleteCheck:SetChecked(isShared and self.accountWideComplete)
        accountCompleteText:SetAlpha(isShared and 1 or 0.40)
        local layoutKey = tostring(self.trackingMode) .. ":" .. self.displayProgressMode
        if self.layoutKey ~= layoutKey then
            self.layoutKey = layoutKey
            self:LayoutFields()
        end
    end

    function frame:Commit()
        local text = self.input:GetText() or ""
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then
            if UIErrorsFrame and UIErrorsFrame.AddMessage then
                UIErrorsFrame:AddMessage(L["CustomTasks_EmptyError"] or "Enter a task name first.", 1, 0.25, 0.25)
            end
            self.input:SetFocus()
            return
        end

        local isQuest = self.trackingMode == "quest"
        local isEncounter = self.trackingMode == "encounter"
        local idsInput = isQuest and self.questInput or (isEncounter and self.encounterInput)
        if idsInput then
            local hasId = false
            for token in idsInput:GetText():gmatch("%d+") do
                if tonumber(token) > 0 then hasId = true break end
            end
            if not hasId then
                if UIErrorsFrame and UIErrorsFrame.AddMessage then
                    UIErrorsFrame:AddMessage(L[isQuest and "CustomTasks_QuestIdRequired" or "CustomTasks_EncounterIdRequired"], 1, 0.25, 0.25)
                end
                idsInput:SetFocus()
                return
            end
        end

        local questIds = isQuest and self.questInput:GetText() or ""
        local encounterIds = isEncounter and self.encounterInput:GetText() or ""
        local ordered = isQuest and self.orderedQuestCheck:GetChecked() or false
        local manualClicks = isQuest and self.manualQuestCheck:GetChecked() or false
        local maxValue = self.displayProgressMode == "counter" and GetCounterTarget() or 1

        local encounterDifficulties = nil
        if isEncounter then
            local allChecked = true
            for _, cb in ipairs(self.difficultyChecks) do
                if not cb:GetChecked() then allChecked = false break end
            end
            if not allChecked then
                encounterDifficulties = {}
                for _, cb in ipairs(self.difficultyChecks) do
                    if cb:GetChecked() then encounterDifficulties[cb._diffId] = true end
                end
            end
        end

        local category = (self.categoryInput and self.categoryInput:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local remindInCity = self.cityReminderCheck:GetChecked() and true or false
        local saved
        local savedTaskId = self.taskId
        if self.taskId then
            saved, savedTaskId = MR:UpdateCustomTask(self.taskId, text, self.resetType, maxValue, questIds, manualClicks, encounterIds, self.autoUpdateInstances, encounterDifficulties, self.taskScope, self.originalTaskScope, self.accountWideComplete, ordered, category, remindInCity)
        else
            savedTaskId = MR:AddCustomTask(text, self.resetType, maxValue, questIds, manualClicks, encounterIds, self.autoUpdateInstances, encounterDifficulties, self.taskScope, self.accountWideComplete, ordered, category, remindInCity)
            saved = savedTaskId ~= nil
        end
        if saved and category ~= "" and MR.SetCustomTaskCategorySeparateModule then
            local savedTask = MR.GetCustomTaskById and MR:GetCustomTaskById(savedTaskId, self.taskScope) or nil
            MR:SetCustomTaskCategorySeparateModule(savedTask and savedTask.resetType or self.resetType, category, self.categorySeparateModuleCheck:GetChecked())
        end
        self:Hide()
        if saved and remindInCity then MR:QueueCityTaskReminder() end
    end

    saveBtn:SetScript("OnClick",  function() frame:Commit() end)
    input:SetScript("OnEnterPressed",         function() frame:Commit() end)
    questInput:SetScript("OnEnterPressed",    function() frame:Commit() end)
    encounterInput:SetScript("OnEnterPressed",function() frame:Commit() end)
    targetInput:SetScript("OnEnterPressed",   function() frame:Commit() end)
    categoryInput:SetScript("OnEnterPressed", function() frame:Commit() end)

    MR.customTaskDialog = frame
    ApplyCustomTaskDialogTheme(frame)
    return frame
end


function MR:ShowCustomTaskDialog(taskId, presetResetType, taskScope)
    local dialog = EnsureCustomTaskDialog()
    taskScope = taskScope == "shared" and "shared" or "character"
    local task = taskId and self.GetCustomTaskById and self:GetCustomTaskById(taskId, taskScope) or nil

    dialog.loadingTask = true
    dialog.taskId = task and task.id or nil
    dialog.taskScope = (task and task.scope) or taskScope
    dialog.originalTaskScope = dialog.taskScope
    dialog.resetType = (task and task.resetType) or presetResetType or "weekly"
    dialog.title:SetText(task and (L["CustomTasks_EditTitle"] or "Edit Custom Task") or (L["CustomTasks_AddTitle"] or "Add Custom Task"))
    dialog.input:SetText(task and task.label or "")
    dialog.categoryInput:SetText((task and task.category) or "")
    dialog.questInput:SetText((task and task.questIds and table.concat(task.questIds, ", ")) or "")
    dialog.encounterInput:SetText((task and task.encounterIds and table.concat(task.encounterIds, ", ")) or "")
    dialog.trackingMode = dialog.questInput:GetText() ~= "" and "quest"
        or (dialog.encounterInput:GetText() ~= "" and "encounter" or "manual")
    local taskMax = tonumber(task and task.max) or 1
    dialog.progressMode = taskMax > 1 and "counter" or "checkbox"
    dialog.counterTarget = tostring(math.max(2, taskMax))
    dialog.targetInput:SetText(dialog.counterTarget)
    dialog.allowManualQuestClicks = task and task.allowManualQuestClicks or false
    dialog.orderedQuestSequence = task and task.orderedQuestSequence or false
    dialog.autoUpdateInstances = task and task.autoUpdateInstances or false
    dialog.accountWideComplete = task and task.accountWideComplete or false
    dialog.cityReminderCheck:SetChecked(task and task.remindInCity == true)
    if dialog.autoUpdateCheck then
        dialog.autoUpdateCheck:SetChecked(dialog.autoUpdateInstances)
    end
    if dialog.orderedQuestCheck then
        dialog.orderedQuestCheck:SetChecked(dialog.orderedQuestSequence)
    end
    if dialog.sharedTaskCheck then
        dialog.sharedTaskCheck:SetChecked(dialog.taskScope == "shared")
    end
    if dialog.accountCompleteCheck then
        dialog.accountCompleteCheck:SetChecked(dialog.accountWideComplete)
    end

    local storedDiffs = task and task.encounterDifficulties or nil
    if dialog.difficultyChecks then
        for _, cb in ipairs(dialog.difficultyChecks) do
            cb:SetChecked(storedDiffs == nil or storedDiffs[cb._diffId] == true)
        end
    end
    dialog.deleteBtn:SetShown(task ~= nil)
    dialog.loadingTask = false
    if dialog.categoryDropdown then
        dialog.categoryDropdown:Update()
    end
    if dialog.RefreshCategoryModuleState then
        dialog:RefreshCategoryModuleState()
    end
    ApplyCustomTaskDialogTheme(dialog)
    dialog:RefreshSmartState()
    dialog:Show()
    dialog.input:SetFocus()
    dialog.input:HighlightText(0, -1)
end

local function EnsureCustomTasksTitleDialog()
    if MR.customTasksTitleDialog then
        return MR.customTasksTitleDialog
    end

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(340, 190)
    MR:RegisterPriorityFrame(frame)
    frame:SetFrameLevel(80)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    frame:SetBackdrop(MakeBackdrop())
    ns.HookBackdropFrame(frame)
    frame:SetBackdropColor(0.03, 0.08, 0.14, 0.98)
    frame:SetBackdropBorderColor(0.20, 0.44, 0.48, 1)
    frame:Hide()

    local dragRegion = CreateFrame("Frame", nil, frame)
    dragRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    dragRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    dragRegion:SetHeight(26)
    dragRegion:EnableMouse(true)
    dragRegion:RegisterForDrag("LeftButton")
    dragRegion:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    dragRegion:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(ns.FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -12)
    title:SetJustifyH("LEFT")
    title:SetText(L["CustomTasks_EditModuleTitle"] or "Rename custom task title")
    ns.RegisterThemedFontString(title, 0.92, 0.97, 1)

    local subtitle = frame:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    subtitle:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -6)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(L["CustomTasks_EditModuleTitleNote"] or "Click to rename the Custom Tasks header for this character.")
    subtitle:SetTextColor(0.68, 0.78, 0.86)
    frame.titleText = title
    frame.subtitle = subtitle

    local inputBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    inputBg:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -14)
    inputBg:SetPoint("TOPRIGHT", subtitle, "BOTTOMRIGHT", 0, -14)
    inputBg:SetHeight(34)
    inputBg:SetBackdrop(MakeBackdrop())
    ns.HookBackdropFrame(inputBg, "content")
    inputBg:SetBackdropColor(0.05, 0.10, 0.18, 0.98)
    inputBg:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

    local input = CreateFrame("EditBox", nil, inputBg, "InputBoxTemplate")
    input:SetAutoFocus(false)
    input:SetPoint("TOPLEFT", inputBg, "TOPLEFT", 8, -8)
    input:SetPoint("BOTTOMRIGHT", inputBg, "BOTTOMRIGHT", -8, 8)
    input:SetFontObject(ChatFontNormal)
    input:SetTextInsets(0, 0, 0, 0)
    input:SetMaxLetters(120)
    input:SetTextColor(0.95, 0.97, 1)
    input:SetScript("OnEscapePressed", function()
        frame:Hide()
    end)
    frame.input = input

    local hint = frame:CreateFontString(nil, "OVERLAY")
    hint:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
    hint:SetPoint("TOPLEFT", inputBg, "BOTTOMLEFT", 0, -8)
    hint:SetPoint("TOPRIGHT", inputBg, "BOTTOMRIGHT", 0, -8)
    hint:SetJustifyH("LEFT")
    hint:SetText(L["CustomTasks_EditModuleTitleHint"] or "Leave it as Custom Tasks, or rename it to something like Weekly Goals.")
    hint:SetTextColor(0.60, 0.72, 0.82)
    frame.hint = hint

    local function CreateDialogButton(width, label, color, borderColor)
        local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        btn:SetSize(width, 24)
        btn:SetBackdrop(MakeBackdrop())
        btn:SetBackdropColor(color[1], color[2], color[3], 0.95)
        btn:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)

        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont(ns.FONT_HEADERS, 10, GetFontFlags())
        text:SetPoint("CENTER", btn, "CENTER", 0, 1)
        text:SetText(label)
        text:SetTextColor(0.92, 0.96, 1)
        btn._label = text

        btn:SetScript("OnEnter", function(selfBtn)
            selfBtn:SetBackdropColor(color[1] + 0.04, color[2] + 0.04, color[3] + 0.04, 1)
            selfBtn:SetBackdropBorderColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(color[1], color[2], color[3], 0.95)
            selfBtn:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
        end)

        return btn
    end

    local saveBtn = CreateDialogButton(92, L["CustomTasks_Save"] or "Save", { 0.10, 0.26, 0.20 }, { 0.28, 0.78, 0.50 })
    saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 12)
    frame.saveBtn = saveBtn

    local cancelBtn = CreateDialogButton(92, L["CustomTasks_Cancel"] or "Cancel", { 0.10, 0.12, 0.16 }, { 0.28, 0.34, 0.42 })
    cancelBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0)
    cancelBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame.cancelBtn = cancelBtn

    function frame:Commit()
        local text = self.input:GetText() or ""
        MR:SetCustomTasksTitle(text)
        self:Hide()
    end

    saveBtn:SetScript("OnClick", function()
        frame:Commit()
    end)
    input:SetScript("OnEnterPressed", function()
        frame:Commit()
    end)

    MR.customTasksTitleDialog = frame
    ApplyCustomTasksTitleDialogTheme(frame)
    return frame
end

function MR:ShowCustomTasksTitleDialog()
    local dialog = EnsureCustomTasksTitleDialog()
    dialog.input:SetText(self.GetCustomTasksTitle and self:GetCustomTasksTitle() or (L["CustomTasks_Title"] or "Custom Tasks"))
    ApplyCustomTasksTitleDialogTheme(dialog)
    dialog:Show()
    dialog.input:SetFocus()
    dialog.input:HighlightText(0, -1)
end

local function EnsureCustomTaskCategoryDialog()
    if MR.customTaskCategoryDialog then
        return MR.customTaskCategoryDialog
    end

    RefreshFonts()

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(440, 286)
    MR:RegisterPriorityFrame(frame)
    frame:SetFrameLevel(82)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 55)
    frame:SetBackdrop(MakeBackdrop())
    ns.HookBackdropFrame(frame)
    frame:SetBackdropColor(0.03, 0.08, 0.14, 0.99)
    frame:SetBackdropBorderColor(0.20, 0.44, 0.48, 1)
    frame:Hide()

    local dragRegion = CreateFrame("Frame", nil, frame)
    dragRegion:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -8)
    dragRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    dragRegion:SetHeight(28)
    dragRegion:EnableMouse(true)
    dragRegion:RegisterForDrag("LeftButton")
    dragRegion:SetScript("OnDragStart", function() frame:StartMoving() end)
    dragRegion:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 14, -14)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, -14)
    title:SetJustifyH("LEFT")
    title:SetText(Text("CustomTasks_ManageCategoryTitle", "Manage Category"))
    ns.RegisterThemedFontString(title, 0.92, 0.97, 1)
    frame.titleText = title

    local separator = frame:CreateTexture(nil, "ARTWORK")
    separator:SetHeight(1)
    separator:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    separator:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -8)
    ns.RegisterThemedTexture(separator, 0.20, 0.44, 0.48, 0.5)

    local subtitle = frame:CreateFontString(nil, "OVERLAY")
    subtitle:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    subtitle:SetPoint("TOPLEFT", separator, "BOTTOMLEFT", 0, -9)
    subtitle:SetPoint("TOPRIGHT", separator, "BOTTOMRIGHT", 0, -9)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(Text("CustomTasks_ManageCategoryNote", "Rename this category, show it as its own module, remove only the separator, or permanently delete every task inside it."))
    subtitle:SetTextColor(0.68, 0.78, 0.86)
    frame.subtitle = subtitle

    local nameLabel = frame:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    nameLabel:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)
    nameLabel:SetText(Text("CustomTasks_CategoryName", "Category name"))
    nameLabel:SetTextColor(0.55, 0.70, 0.82)
    frame.nameLabel = nameLabel

    local inputBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    inputBg:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -5)
    inputBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -14, 0)
    inputBg:SetHeight(34)
    inputBg:SetBackdrop(MakeBackdrop())
    ns.HookBackdropFrame(inputBg, "content")
    inputBg:SetBackdropColor(0.05, 0.10, 0.18, 0.98)
    inputBg:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

    local input = CreateFrame("EditBox", nil, inputBg, "InputBoxTemplate")
    input:SetAutoFocus(false)
    input:SetPoint("TOPLEFT", inputBg, "TOPLEFT", 8, -8)
    input:SetPoint("BOTTOMRIGHT", inputBg, "BOTTOMRIGHT", -8, 8)
    input:SetFontObject(ChatFontNormal)
    input:SetTextInsets(0, 0, 0, 0)
    input:SetMaxLetters(80)
    input:SetTextColor(0.95, 0.97, 1)
    input:SetScript("OnEscapePressed", function() frame:Hide() end)
    input:SetScript("OnTextChanged", function(selfInput)
        ApplyDialogEditBoxFont(selfInput, GetFontSize())
        if frame.ResetDeleteState then frame:ResetDeleteState() end
    end)
    frame.input = input

    local hint = frame:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 2), GetFontFlags())
    hint:SetPoint("TOPLEFT", inputBg, "BOTTOMLEFT", 0, -8)
    hint:SetPoint("TOPRIGHT", inputBg, "BOTTOMRIGHT", 0, -8)
    hint:SetJustifyH("LEFT")
    hint:SetText(Text("CustomTasks_ManageCategoryHint", "Removing only the category keeps its tasks directly under the reset section."))
    hint:SetTextColor(0.60, 0.72, 0.82)
    frame.hint = hint

    local separateModuleCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    ns.ThemeCheckButton(separateModuleCheck)
    separateModuleCheck:SetSize(20, 20)
    separateModuleCheck:SetPoint("TOPLEFT", hint, "BOTTOMLEFT", -4, -9)
    local separateModuleText = separateModuleCheck:CreateFontString(nil, "OVERLAY")
    separateModuleText:SetFont(FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
    separateModuleText:SetPoint("LEFT", separateModuleCheck, "RIGHT", 2, 0)
    separateModuleText:SetText(Text("CustomTasks_ShowAsSeparateModule", "Show as a separate module"))
    separateModuleText:SetTextColor(0.78, 0.90, 0.94)
    separateModuleCheck._text = separateModuleText
    frame.separateModuleCheck = separateModuleCheck

    local function CreateDialogButton(width, label, color, borderColor)
        local button = CreateFrame("Button", nil, frame, "BackdropTemplate")
        button:SetSize(width, 24)
        button:SetBackdrop(MakeBackdrop())
        button:SetBackdropColor(color[1], color[2], color[3], 0.95)
        button:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
        local buttonLabel = button:CreateFontString(nil, "OVERLAY")
        buttonLabel:SetFont(FONT_HEADERS, 10, GetFontFlags())
        buttonLabel:SetPoint("CENTER", button, "CENTER", 0, 1)
        buttonLabel:SetText(label)
        buttonLabel:SetTextColor(0.92, 0.96, 1)
        button._label = buttonLabel
        button:SetScript("OnEnter", function(selfButton)
            selfButton:SetBackdropColor(color[1] + 0.04, color[2] + 0.04, color[3] + 0.04, 1)
            selfButton:SetBackdropBorderColor(1, 1, 1, 1)
        end)
        button:SetScript("OnLeave", function(selfButton)
            selfButton:SetBackdropColor(color[1], color[2], color[3], 0.95)
            selfButton:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
        end)
        return button
    end

    local saveBtn = CreateDialogButton(92, L["CustomTasks_Save"] or "Save", { 0.10, 0.26, 0.20 }, { 0.28, 0.78, 0.50 })
    saveBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 12)
    frame.saveBtn = saveBtn

    local cancelBtn = CreateDialogButton(92, L["CustomTasks_Cancel"] or "Cancel", { 0.10, 0.12, 0.16 }, { 0.28, 0.34, 0.42 })
    cancelBtn:SetPoint("RIGHT", saveBtn, "LEFT", -8, 0)
    cancelBtn:SetScript("OnClick", function() frame:Hide() end)
    frame.cancelBtn = cancelBtn

    local removeBtn = CreateDialogButton(164, Text("CustomTasks_RemoveCategoryOnly", "Remove Category Only"), { 0.18, 0.12, 0.05 }, { 0.68, 0.44, 0.15 })
    removeBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 14, 46)
    removeBtn:SetScript("OnClick", function()
        if MR.RemoveCustomTaskCategory then
            MR:RemoveCustomTaskCategory(frame.resetType, frame.category)
        end
        frame:Hide()
    end)
    frame.removeBtn = removeBtn

    local deleteAllBtn = CreateDialogButton(204, Text("CustomTasks_DeleteCategoryTasks", "Delete Category + All Tasks"), { 0.22, 0.06, 0.06 }, { 0.76, 0.18, 0.18 })
    deleteAllBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -14, 46)
    deleteAllBtn:SetScript("OnClick", function()
        if not frame.deleteArmed then
            frame.deleteArmed = true
            deleteAllBtn._label:SetText(Text("CustomTasks_ConfirmDeleteCategoryTasks", "Click Again to Delete Everything"))
            hint:SetText(Text("CustomTasks_DeleteCategoryWarning", "This permanently deletes every task in this category and its saved progress."))
            hint:SetTextColor(1, 0.38, 0.38)
            return
        end
        if MR.DeleteCustomTaskCategory then
            MR:DeleteCustomTaskCategory(frame.resetType, frame.category)
        end
        frame:Hide()
    end)
    frame.deleteAllBtn = deleteAllBtn

    function frame:ResetDeleteState()
        self.deleteArmed = false
        self.deleteAllBtn._label:SetText(Text("CustomTasks_DeleteCategoryTasks", "Delete Category + All Tasks"))
        self.hint:SetText(Text("CustomTasks_ManageCategoryHint", "Removing only the category keeps its tasks directly under the reset section."))
        self.hint:SetTextColor(0.60, 0.72, 0.82)
    end

    function frame:Commit()
        local newCategory = self.input:GetText() or ""
        newCategory = newCategory:gsub("^%s+", ""):gsub("%s+$", "")
        if newCategory == "" then
            if UIErrorsFrame and UIErrorsFrame.AddMessage then
                UIErrorsFrame:AddMessage(Text("CustomTasks_CategoryEmptyError", "Enter a category name first."), 1, 0.25, 0.25)
            end
            self.input:SetFocus()
            return
        end
        if MR.RenameCustomTaskCategory then
            MR:RenameCustomTaskCategory(self.resetType, self.category, newCategory)
        end
        if MR.SetCustomTaskCategorySeparateModule then
            MR:SetCustomTaskCategorySeparateModule(self.resetType, newCategory, self.separateModuleCheck:GetChecked())
        end
        self:Hide()
    end

    saveBtn:SetScript("OnClick", function() frame:Commit() end)
    input:SetScript("OnEnterPressed", function() frame:Commit() end)
    frame:SetScript("OnHide", function(selfFrame) selfFrame:ResetDeleteState() end)

    MR.customTaskCategoryDialog = frame
    ApplyCustomTaskCategoryDialogTheme(frame)
    return frame
end

function MR:ShowCustomTaskCategoryDialog(resetType, category)
    local dialog = EnsureCustomTaskCategoryDialog()
    dialog.resetType = resetType
    dialog.category = category
    dialog.titleText:SetText(Text("CustomTasks_ManageCategoryTitle", "Manage Category") .. ": " .. tostring(category or ""))
    dialog.input:SetText(category or "")
    dialog.separateModuleCheck:SetChecked(self:IsCustomTaskCategorySeparateModule(resetType, category))
    dialog:ResetDeleteState()
    ApplyCustomTaskCategoryDialogTheme(dialog)
    dialog:Show()
    dialog.input:SetFocus()
    dialog.input:HighlightText(0, -1)
end

function MR:RefreshCustomTaskDialogThemes()
    if self.customTaskDialog then
        ApplyCustomTaskDialogTheme(self.customTaskDialog)
    end
    if self.customTasksTitleDialog then
        ApplyCustomTasksTitleDialogTheme(self.customTasksTitleDialog)
    end
    if self.customTaskCategoryDialog then
        ApplyCustomTaskCategoryDialogTheme(self.customTaskCategoryDialog)
    end
end

do
    local CITY_MAPS = {
        [84] = 84,
        [85] = 85,
        [86] = 85,
        [87] = 87,
        [88] = 88,
        [89] = 89,
        [90] = 90,
        [103] = 103,
        [110] = 110,
        [111] = 111,
        [1453] = 84,
        [1454] = 85,
        [1455] = 87,
        [1456] = 88,
        [1457] = 89,
        [1458] = 90,
        [2112] = 2112,
        [2339] = 2339,
        [2393] = 2393,
    }
    local WIDTH, CONTENT_INSET, MAX_CONTENT_HEIGHT = 350, 32, 230
    local dialog, currentCity, shownThisVisit, pendingTimer, waitingForCombat
    local visibleRowCount = 0

    local function ResolveCityMap(mapID)
        for _ = 1, 12 do
            if not mapID or mapID == 0 then return end
            if CITY_MAPS[mapID] then return CITY_MAPS[mapID] end
            local info = C_Map.GetMapInfo(mapID)
            if not info then return end
            mapID = info.parentMapID
        end
    end

    local function GetCurrentCity()
        if IsInInstance() then return false end
        local playerMap = C_Map.GetBestMapForUnit("player")
        local minimap = C_Minimap and C_Minimap.GetUiMapID and C_Minimap.GetUiMapID()
        local city = ResolveCityMap(playerMap) or ResolveCityMap(minimap)
        if city then return city end
        local realZone, zone = GetRealZoneText(), GetZoneText()
        for cityMapID, cityID in pairs(CITY_MAPS) do
            if cityMapID == cityID then
                local info = C_Map.GetMapInfo(cityMapID)
                if info and info.name and info.name ~= "" and (info.name == realZone or info.name == zone) then
                    return cityID
                end
            end
        end
        if playerMap or minimap or (realZone and realZone ~= "") then return false end
    end

    local function IsReminderLocked()
        return MR:GetWindowLayoutValue("cityReminderLocked") == true
    end

    local function LayoutReminderRows()
        local rows = ns.GetWidgetCache(dialog, "reminderRows")
        local width = dialog:GetWidth() - CONTENT_INSET
        local height = 0
        dialog.content:SetWidth(width)
        for index = 1, visibleRowCount do
            local row = rows[index]
            row:SetWidth(width)
            ns.SetOneAnchor(row, "TOPLEFT", dialog.content, "TOPLEFT", 0, -height)
            height = height + row:GetStringHeight() + 6
        end
        dialog.content:SetHeight(height)
        return height
    end

    local function ApplyReminderSize()
        local size = MR:GetWindowLayoutValue("cityReminderSize") or {}
        dialog:SetWidth(size.width or WIDTH)
        local contentHeight = LayoutReminderRows()
        dialog:SetHeight(size.height or math.max(70, 46 + math.min(MAX_CONTENT_HEIGHT, contentHeight)))
        dialog.updateScroll()
    end

    local function CreateReminderOptions()
        local options = ns.StyledFrame(dialog, nil, "DIALOG", dialog:GetFrameLevel() + 20)
        MR:RegisterPriorityFrame(options)
        options:SetSize(230, 107)
        options:SetPoint("TOPLEFT", dialog, "TOPRIGHT", 5, 0)
        local header = ns.TitleBar(options, 26)
        local label = header:CreateFontString(nil, "OVERLAY")
        label:SetFont(ns.FONT_HEADERS, 12, ns.GetFontFlags())
        label:SetPoint("LEFT", 10, 0)
        label:SetText(L["CustomTasks_CityReminderOptions"])
        ns.CloseButton(header, function() options:Hide() end)
        local y = ns.OptionsCheckbox(options, -35, L["Config_LockPosition"], IsReminderLocked, function(value)
            MR:SetWindowLayoutValue("cityReminderLocked", value and true or false)
        end, nil, nil, nil, 8, nil, 12)
        ns.OptionsBtn(options, y - 8, L["CustomTasks_CityReminderResetWindow"], function()
            MR:SetWindowLayoutValue("cityReminderPos", { point = "CENTER", relPoint = "CENTER", x = 0, y = 140 })
            MR:SetWindowLayoutValue("cityReminderSize", {})
            ns.RestoreManagedFramePos(dialog, "cityReminderPos", 0, 140)
            ApplyReminderSize()
        end, 214, 8, 12)
        return options
    end

    local function ShowReminder(tasks)
        local fontSize = math.min(16, math.max(11, ns.GetFontSize()))
        if not dialog then
            dialog = ns.StyledFrame(UIParent, nil, "DIALOG", 20)
            MR:RegisterPriorityFrame(dialog)
            dialog:EnableMouse(true)
            local header = ns.TitleBar(dialog, 28)
            local moving
            local function FinishMove()
                if not moving then return end
                moving = nil
                dialog:StopMovingOrSizing()
                ns.SyncManagedFramePos(dialog, "cityReminderPos", "top")
            end
            header:SetScript("OnDragStart", function()
                if IsReminderLocked() then return end
                moving = true
                dialog:StartMoving()
            end)
            header:SetScript("OnDragStop", FinishMove)
            local title = header:CreateFontString(nil, "OVERLAY")
            title:SetPoint("LEFT", 10, 0)
            dialog.title = title
            local close = ns.CloseButton(header, function() dialog:Hide() end)
            local options
            local gear = ns.HeaderIconButton(header, "Interface\\Buttons\\UI-OptionsButton",
                { 0.85, 0.65, 0.20 }, { 1, 1, 1 }, L["CustomTasks_CityReminderOptions"], function()
                    if options and options:IsShown() then
                        options:Hide()
                        return
                    end
                    options = options or CreateReminderOptions()
                    options:Show()
                    options:Raise()
                end)
            gear:SetPoint("RIGHT", close, "LEFT", -5, 0)
            dialog.scroll, dialog.content, dialog.updateScroll = ns.CreateScrollArea(dialog,
                { "TOPLEFT", header, "BOTTOMLEFT", 10, -8 },
                { "BOTTOMRIGHT", dialog, "BOTTOMRIGHT", -22, 10 },
                { contentWidth = WIDTH - CONTENT_INSET })
            local grip = ns.CreateManagedResizeGrip(dialog, false, IsReminderLocked)
            local resizing
            local function FinishResize()
                if not resizing then return end
                resizing = nil
                grip:SetScript("OnUpdate", nil)
                MR:SetWindowLayoutValue("cityReminderSize", { width = dialog:GetWidth(), height = dialog:GetHeight() })
            end
            grip:SetScript("OnMouseDown", function(_, button)
                if button ~= "LeftButton" or IsReminderLocked() then return end
                ns.SyncManagedFramePos(dialog, "cityReminderPos", "top")
                local startX, startY = GetCursorPosition()
                local startW, startH = dialog:GetWidth(), dialog:GetHeight()
                resizing = true
                grip:SetScript("OnUpdate", function()
                    if IsReminderLocked() or not IsMouseButtonDown("LeftButton") then
                        FinishResize()
                        return
                    end
                    local x, y = GetCursorPosition()
                    local scale = dialog:GetEffectiveScale()
                    local width = math.max(260, math.min(720, math.floor(startW + (x - startX) / scale)))
                    local height = math.max(70, math.min(650, math.floor(startH + (startY - y) / scale)))
                    if width == dialog:GetWidth() and height == dialog:GetHeight() then return end
                    local widthChanged = width ~= dialog:GetWidth()
                    dialog:SetSize(width, height)
                    if widthChanged then LayoutReminderRows() end
                    dialog.updateScroll()
                end)
            end)
            grip:SetScript("OnMouseUp", function(_, button)
                if button == "LeftButton" then FinishResize() end
            end)
            dialog:HookScript("OnHide", function()
                FinishMove()
                FinishResize()
                if options then options:Hide() end
            end)
        end

        dialog.title:SetFont(ns.FONT_HEADERS, fontSize + 1, ns.GetFontFlags())
        dialog.title:SetText(L["CustomTasks_CityReminderTitle"])
        local rows = ns.GetWidgetCache(dialog, "reminderRows")
        for index, task in ipairs(tasks) do
            local row = rows[index]
            if not row then
                row = dialog.content:CreateFontString(nil, "OVERLAY")
                row:SetJustifyH("LEFT")
                row:SetJustifyV("TOP")
                row:SetWordWrap(true)
                rows[index] = row
            end
            row:SetFont(ns.FONT_ROWS, fontSize, ns.GetFontFlags())
            row:SetText("• " .. task)
            row:Show()
        end
        visibleRowCount = #tasks
        ns.HideUnusedWidgets(rows, visibleRowCount)
        ns.RestoreManagedFramePos(dialog, "cityReminderPos", 0, 140)
        ApplyReminderSize()
        dialog:Show()
        dialog:Raise()
        dialog.scroll:SetVerticalScroll(0)
        dialog.updateScroll()
    end

    local function CheckCity(retries)
        pendingTimer = nil
        if not MR.db then return end
        local city = GetCurrentCity()
        if not city and retries > 0 then
            pendingTimer = C_Timer.NewTimer(1, function() CheckCity(retries - 1) end)
            return
        end
        if city == nil then return end
        if city ~= currentCity then
            currentCity, shownThisVisit = city, false
            if dialog then dialog:Hide() end
        end
        waitingForCombat = nil
        if not city or shownThisVisit then return end
        if InCombatLockdown() then
            waitingForCombat = true
            return
        end
        local tasks = MR:GetPendingCityReminderTasks()
        if #tasks == 0 then return end
        ShowReminder(tasks)
        shownThisVisit = true
    end

    function MR:QueueCityTaskReminder()
        if pendingTimer then return end
        pendingTimer = C_Timer.NewTimer(0.75, function() CheckCity(2) end)
    end

    function MR:PrintCityTaskReminderStatus()
        if not self.db then
            print("Routine city reminders: settings are still loading.")
            return
        end
        local city = GetCurrentCity()
        local tasks, optedIn = self:GetPendingCityReminderTasks()
        local _, instanceType = IsInInstance()
        local minimap = C_Minimap and C_Minimap.GetUiMapID and C_Minimap.GetUiMapID()
        print(("Routine city reminders: zone=%s, map=%s, minimap=%s, city=%s, instance=%s, opted in=%d, unfinished=%d, shown this visit=%s, visible=%s"):format(
            tostring(GetRealZoneText()), tostring(C_Map.GetBestMapForUnit("player")), tostring(minimap),
            tostring(city), tostring(instanceType), optedIn, #tasks,
            tostring(city == currentCity and shownThisVisit == true), tostring(dialog and dialog:IsVisible() or false)))
        self:QueueCityTaskReminder()
    end

    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    watcher:RegisterEvent("ZONE_CHANGED")
    watcher:RegisterEvent("ZONE_CHANGED_INDOORS")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function(_, event)
        if event ~= "PLAYER_REGEN_ENABLED" or waitingForCombat then
            MR:QueueCityTaskReminder()
        end
    end)
end
