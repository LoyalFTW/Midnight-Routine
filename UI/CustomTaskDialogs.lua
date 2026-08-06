local _, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")
local MakeBackdrop = ns.MakeBackdrop
local FONT_ROWS = ns.FONT_ROWS
local FONT_HEADERS = ns.FONT_HEADERS
local function GetFontSize()
    return (ns.GetFontSize and ns.GetFontSize()) or 11
end
local function GetFontFlags()
    return (ns.GetFontFlags and ns.GetFontFlags()) or "OUTLINE"
end
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


    frame:SetSize(400, 512)

    local function sf(fs, size) if fs then fs:SetFont(ns.FONT_ROWS, size, GetFontFlags()) end end
    sf(frame.title,           math.max(10, fontSize + 1))
    sf(frame.nameLabel,       rowFont)
    sf(frame.questLabel,      rowFont)
    sf(frame.encounterLabel,  rowFont)
    sf(frame.difficultyLabel, rowFont)
    sf(frame.idHint,          hintFont)
    sf(frame.diffHint,        hintFont)
    sf(frame.targetLabel,     rowFont)
    sf(frame.targetHint,      hintFont)
    sf(frame.resetLabel,      rowFont)

    if frame.title then frame.title:SetFont(ns.FONT_HEADERS, math.max(10, fontSize + 1), GetFontFlags()) end

    local checks = { frame.weeklyCheck, frame.dailyCheck, frame.manualQuestCheck, frame.autoUpdateCheck, frame.sharedTaskCheck, frame.accountCompleteCheck }
    for _, cb in ipairs(checks) do
        if cb and cb._text then cb._text:SetFont(ns.FONT_ROWS, rowFont, GetFontFlags()) end
    end
    if frame.difficultyChecks then
        for _, cb in ipairs(frame.difficultyChecks) do
            if cb._text then cb._text:SetFont(ns.FONT_ROWS, rowFont, GetFontFlags()) end
        end
    end

    if frame.input          then ApplyDialogEditBoxFont(frame.input,          editFont) end
    if frame.questInput     then ApplyDialogEditBoxFont(frame.questInput,     editFont) end
    if frame.encounterInput then ApplyDialogEditBoxFont(frame.encounterInput, editFont) end
    if frame.targetInput    then ApplyDialogEditBoxFont(frame.targetInput,    editFont) end

    if frame.saveBtn   and frame.saveBtn._label   then frame.saveBtn._label:SetFont(ns.FONT_HEADERS,   10, GetFontFlags()) end
    if frame.cancelBtn and frame.cancelBtn._label then frame.cancelBtn._label:SetFont(ns.FONT_HEADERS, 10, GetFontFlags()) end
    if frame.deleteBtn and frame.deleteBtn._label then frame.deleteBtn._label:SetFont(ns.FONT_HEADERS, 10, GetFontFlags()) end
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

local function EnsureCustomTaskDialog()
    if MR.customTaskDialog then
        return MR.customTaskDialog
    end


    local PAD  = 14
    local GAP  = 10
    local IGAP = 6
    local IH   = 28
    local LH   = 14

    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(400, 512)
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(80)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    frame:SetBackdrop(MakeBackdrop())
    frame:SetBackdropColor(0.03, 0.08, 0.14, 0.98)
    frame:SetBackdropBorderColor(0.20, 0.44, 0.48, 1)
    frame:Hide()

    local dragRegion = CreateFrame("Frame", nil, frame)
    dragRegion:SetPoint("TOPLEFT",  frame, "TOPLEFT",  8, -8)
    dragRegion:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
    dragRegion:SetHeight(26)
    dragRegion:EnableMouse(true)
    dragRegion:RegisterForDrag("LeftButton")
    dragRegion:SetScript("OnDragStart", function() frame:StartMoving() end)
    dragRegion:SetScript("OnDragStop",  function() frame:StopMovingOrSizing() end)


    local title = frame:CreateFontString(nil, "OVERLAY")
    title:SetFont(ns.FONT_HEADERS, math.max(10, GetFontSize() + 1), GetFontFlags())
    title:SetPoint("TOPLEFT",  frame, "TOPLEFT",  PAD, -PAD)
    title:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, -PAD)
    title:SetJustifyH("LEFT")
    title:SetText(L["CustomTasks_Title"] or "Custom Tasks")
    title:SetTextColor(0.92, 0.97, 1)
    frame.title = title


    local sep = frame:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  title, "BOTTOMLEFT",  0, -8)
    sep:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -8)
    sep:SetColorTexture(0.20, 0.44, 0.48, 0.5)


    local function MakeLabel(anchorFrame, anchorPoint, xOff, yOff, text)
        local lbl = frame:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(ns.FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
        lbl:SetPoint("TOPLEFT", anchorFrame, anchorPoint, xOff, yOff)
        lbl:SetJustifyH("LEFT")
        lbl:SetText(text)
        lbl:SetTextColor(0.55, 0.70, 0.82)
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
        bg:SetBackdropColor(0.04, 0.09, 0.16, 0.98)
        bg:SetBackdropBorderColor(0.16, 0.36, 0.42, 1)
        return bg
    end

    local function MakeEditBox(bg, maxLen, isNumeric)
        local eb = CreateFrame("EditBox", nil, bg, "InputBoxTemplate")
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
            if frame.RefreshSmartState then frame:RefreshSmartState() end
        end)
        return eb
    end


    local nameLabel = MakeLabel(sep, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_NameLabel"] or "Task name")
    nameLabel:SetTextColor(0.74, 0.84, 0.92)
    local nameBg    = MakeInputBg(nameLabel, "BOTTOMLEFT", 0, -IGAP)
    local input     = MakeEditBox(nameBg, 120)
    input:SetScript("OnEscapePressed", function() frame:Hide() end)
    frame.nameLabel = nameLabel
    frame.inputBg   = nameBg
    frame.input     = input


    local COL2W = 170

    local questLabel = MakeLabel(nameBg, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_QuestIdsLabel"] or "Quest ID(s)")
    local questBg    = MakeInputBg(questLabel, "BOTTOMLEFT", 0, -IGAP, COL2W, IH)
    local questInput = MakeEditBox(questBg, 120)
    frame.questLabel = questLabel
    frame.questBg    = questBg
    frame.questInput = questInput

    local encounterLabel = MakeLabel(nameBg, "BOTTOMLEFT", COL2W + GAP, -GAP, L["CustomTasks_EncounterIdsLabel"] or "Encounter ID(s)")
    local encounterBg    = MakeInputBg(encounterLabel, "BOTTOMLEFT", 0, -IGAP, COL2W, IH)
    local encounterInput = MakeEditBox(encounterBg, 120)
    frame.encounterLabel  = encounterLabel
    frame.encounterBg     = encounterBg
    frame.encounterInput  = encounterInput


    local idHint = frame:CreateFontString(nil, "OVERLAY")
    idHint:SetFont(ns.FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    idHint:SetPoint("TOPLEFT",  questBg, "BOTTOMLEFT",  0, -4)
    idHint:SetPoint("TOPRIGHT", frame,   "TOPRIGHT",   -PAD, 0)
    idHint:SetJustifyH("LEFT")
    idHint:SetText("Enter quest IDs for quest tracking, or encounter IDs for boss-kill tracking. Cannot combine both.")
    idHint:SetTextColor(0.46, 0.58, 0.70)
    frame.idHint = idHint


    local DIFF_OPTIONS = {
        { id = 17, label = "LFR" },
        { id = 14, label = "Normal" },
        { id = 15, label = "Heroic" },
        { id = 16, label = "Mythic" },
    }
    local difficultyLabel = MakeLabel(idHint, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_DifficultyLabel"] or "Difficulties")
    difficultyLabel:SetTextColor(0.74, 0.84, 0.92)
    frame.difficultyLabel = difficultyLabel

    frame.difficultyChecks = {}
    local prevDiffCheck = nil
    for i, opt in ipairs(DIFF_OPTIONS) do
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
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
        prevDiffCheck = cb
    end

    local diffHint = frame:CreateFontString(nil, "OVERLAY")
    diffHint:SetFont(ns.FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    diffHint:SetPoint("TOPLEFT", difficultyLabel, "BOTTOMLEFT", 0, -24)
    diffHint:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, 0)
    diffHint:SetJustifyH("LEFT")
    diffHint:SetText(Text("CustomTasks_DifficultyHint", "Leave all checked for any difficulty."))
    diffHint:SetTextColor(0.40, 0.52, 0.62)
    frame.diffHint = diffHint






    local targetLabel = MakeLabel(diffHint, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_TargetLabel"] or "Target")
    targetLabel:SetTextColor(0.74, 0.84, 0.92)
    local targetBg    = MakeInputBg(targetLabel, "BOTTOMLEFT", 0, -IGAP, 60, IH)
    local targetInput = MakeEditBox(targetBg, 3, true)
    targetInput:SetScript("OnTextChanged", function(selfEdit)
        ApplyDialogEditBoxFont(selfEdit, GetFontSize())
    end)
    local targetHint = frame:CreateFontString(nil, "OVERLAY")
    targetHint:SetFont(ns.FONT_ROWS, math.max(7, GetFontSize() - 2), GetFontFlags())
    targetHint:SetPoint("LEFT",  targetBg, "RIGHT", 8, 0)
    targetHint:SetPoint("RIGHT", frame,    "RIGHT", -PAD, 0)
    targetHint:SetJustifyH("LEFT")
    targetHint:SetText("1 = checkbox   2+ = counter (e.g. 0/3)")
    targetHint:SetTextColor(0.46, 0.58, 0.70)
    frame.targetLabel = targetLabel
    frame.targetBg    = targetBg
    frame.targetInput = targetInput
    frame.targetHint  = targetHint


    local resetLabel = MakeLabel(targetBg, "BOTTOMLEFT", 0, -GAP, L["CustomTasks_ResetType"] or "Resets")
    resetLabel:SetTextColor(0.74, 0.84, 0.92)
    frame.resetLabel = resetLabel

    local function CreateResetCheckbox(anchorTo, anchorPt, xOff, yOff, labelText, value)
        local cb = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPLEFT", anchorTo, anchorPt, xOff, yOff)
        local text = frame:CreateFontString(nil, "OVERLAY")
        text:SetFont(ns.FONT_ROWS, math.max(8, GetFontSize() - 1), GetFontFlags())
        text:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        text:SetText(labelText)
        text:SetTextColor(0.84, 0.90, 0.96)
        cb._text  = text
        cb._value = value
        cb:SetScript("OnClick", function(selfBtn)
            if not selfBtn:GetChecked() then selfBtn:SetChecked(true) end
            frame.resetType = selfBtn._value
            if frame.RefreshResetChecks then frame:RefreshResetChecks() end
        end)
        return cb
    end


    local weeklyCheck = CreateResetCheckbox(resetLabel, "BOTTOMLEFT", 0, -4, L["CustomTasks_ResetWeekly"] or "Weekly", "weekly")
    local dailyCheck  = CreateResetCheckbox(weeklyCheck, "TOPLEFT", 0, 0, L["CustomTasks_ResetDaily"] or "Daily", "daily")
    dailyCheck:ClearAllPoints()
    dailyCheck:SetPoint("LEFT", weeklyCheck._text, "RIGHT", 14, 0)
    frame.weeklyCheck = weeklyCheck
    frame.dailyCheck  = dailyCheck


    local manualQuestCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    manualQuestCheck:SetSize(20, 20)
    manualQuestCheck:SetPoint("TOPLEFT", weeklyCheck, "BOTTOMLEFT", 0, -GAP)
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
    frame.manualQuestHint  = frame:CreateFontString(nil, "OVERLAY")

    local autoUpdateCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
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
    frame.autoUpdateHint  = frame:CreateFontString(nil, "OVERLAY")

    local sharedTaskCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
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

    local accountCompleteCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
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


    local function CreateDialogButton(width, label, color, borderColor)
        local btn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        btn:SetSize(width, 26)
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
            selfBtn:SetBackdropColor(color[1]+0.04, color[2]+0.04, color[3]+0.04, 1)
            selfBtn:SetBackdropBorderColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(selfBtn)
            selfBtn:SetBackdropColor(color[1], color[2], color[3], 0.95)
            selfBtn:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
        end)
        return btn
    end

    local saveBtn   = CreateDialogButton(88, L["CustomTasks_Save"]   or "Save",   {0.10,0.26,0.20},{0.28,0.78,0.50})
    local cancelBtn = CreateDialogButton(88, L["CustomTasks_Cancel"] or "Cancel", {0.10,0.12,0.16},{0.28,0.34,0.42})
    local deleteBtn = CreateDialogButton(88, L["CustomTasks_Delete"] or "Delete", {0.22,0.08,0.08},{0.72,0.20,0.20})

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


    function frame:RefreshSmartState()
        local hasQuestIds    = self.questInput    and (self.questInput:GetText()    or ""):match("%d") ~= nil
        local hasEncounterIds = self.encounterInput and (self.encounterInput:GetText() or ""):match("%d") ~= nil


        if self.manualQuestCheck then
            self.manualQuestCheck:EnableMouse(hasQuestIds)
            self.manualQuestCheck:SetChecked(hasQuestIds and self.allowManualQuestClicks == true or false)
            if self.manualQuestCheck._text then
                self.manualQuestCheck._text:SetAlpha(hasQuestIds and 1 or 0.50)
            end
        end


        if self.encounterInput then
            local disableEncounter = hasQuestIds
            self.encounterInput:EnableMouse(not disableEncounter)
            self.encounterInput:SetAlpha(disableEncounter and 0.40 or 1)
            if disableEncounter then self.encounterInput:SetText("") end
        end
        if self.encounterLabel then self.encounterLabel:SetAlpha(hasQuestIds and 0.40 or 1) end


        if self.questInput then
            local disableQuest = hasEncounterIds and not hasQuestIds
            self.questInput:EnableMouse(not disableQuest)
            self.questInput:SetAlpha(disableQuest and 0.40 or 1)
        end
        if self.questLabel then self.questLabel:SetAlpha(hasEncounterIds and not hasQuestIds and 0.40 or 1) end


        local enableTarget = hasQuestIds
        if self.targetInput then
            self.targetInput:EnableMouse(enableTarget)
            self.targetInput:SetAlpha(enableTarget and 1 or 0.40)
        end
        if self.targetBg    then self.targetBg:SetAlpha(enableTarget and 1 or 0.40) end
        if self.targetLabel then self.targetLabel:SetAlpha(enableTarget and 1 or 0.40) end
        if self.targetHint  then self.targetHint:SetAlpha(enableTarget and 1 or 0.40) end


        local showDiff = hasEncounterIds and not hasQuestIds
        if self.difficultyLabel then self.difficultyLabel:SetShown(showDiff) end
        if self.diffHint        then self.diffHint:SetShown(showDiff) end
        if self.difficultyChecks then
            for _, cb in ipairs(self.difficultyChecks) do
                cb:SetShown(showDiff)
                if cb._text then cb._text:SetShown(showDiff) end
            end
        end

        local isShared = self.taskScope == "shared"
        if self.accountCompleteCheck then
            if isShared then
                self.accountCompleteCheck:Enable()
            else
                self.accountWideComplete = false
                self.accountCompleteCheck:SetChecked(false)
                self.accountCompleteCheck:Disable()
            end
            if self.accountCompleteCheck._text then
                self.accountCompleteCheck._text:SetAlpha(isShared and 1 or 0.40)
            end
        end
    end

    function frame:RefreshResetChecks()
        local isDaily = self.resetType == "daily"
        if self.weeklyCheck then self.weeklyCheck:SetChecked(not isDaily) end
        if self.dailyCheck  then self.dailyCheck:SetChecked(isDaily) end
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

        local maxValue = math.floor(tonumber(self.targetInput:GetText() or "") or 1)
        if maxValue < 1 then maxValue = 1 elseif maxValue > 999 then maxValue = 999 end

        local encounterDifficulties = nil
        if self.difficultyChecks then
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

        if self.taskId then
            MR:UpdateCustomTask(self.taskId, text, self.resetType, maxValue, self.questInput:GetText() or "", self.allowManualQuestClicks, self.encounterInput and self.encounterInput:GetText() or "", self.autoUpdateInstances, encounterDifficulties, self.taskScope, self.originalTaskScope, self.accountWideComplete)
        else
            MR:AddCustomTask(text, self.resetType, maxValue, self.questInput:GetText() or "", self.allowManualQuestClicks, self.encounterInput and self.encounterInput:GetText() or "", self.autoUpdateInstances, encounterDifficulties, self.taskScope, self.accountWideComplete)
        end
        self:Hide()
    end

    saveBtn:SetScript("OnClick",  function() frame:Commit() end)
    input:SetScript("OnEnterPressed",         function() frame:Commit() end)
    questInput:SetScript("OnEnterPressed",    function() frame:Commit() end)
    encounterInput:SetScript("OnEnterPressed",function() frame:Commit() end)
    targetInput:SetScript("OnEnterPressed",   function() frame:Commit() end)

    if frame.RefreshSmartState then frame:RefreshSmartState() end
    MR.customTaskDialog = frame
    ApplyCustomTaskDialogTheme(frame)
    return frame
end


function MR:ShowCustomTaskDialog(taskId, presetResetType, taskScope)
    local dialog = EnsureCustomTaskDialog()
    taskScope = taskScope == "shared" and "shared" or "character"
    local task = taskId and self.GetCustomTaskById and self:GetCustomTaskById(taskId, taskScope) or nil

    dialog.taskId = task and task.id or nil
    dialog.taskScope = (task and task.scope) or taskScope
    dialog.originalTaskScope = dialog.taskScope
    dialog.resetType = (task and task.resetType) or presetResetType or "weekly"
    dialog.title:SetText(task and (L["CustomTasks_EditTitle"] or "Edit Custom Task") or (L["CustomTasks_AddTitle"] or "Add Custom Task"))
    dialog.input:SetText(task and task.label or "")
    dialog.questInput:SetText((task and task.questIds and table.concat(task.questIds, ", ")) or "")
    dialog.encounterInput:SetText((task and task.encounterIds and table.concat(task.encounterIds, ", ")) or "")
    dialog.targetInput:SetText(tostring((task and task.max) or 1))
    dialog.allowManualQuestClicks = task and task.allowManualQuestClicks or false
    dialog.autoUpdateInstances = task and task.autoUpdateInstances or false
    dialog.accountWideComplete = task and task.accountWideComplete or false
    if dialog.autoUpdateCheck then
        dialog.autoUpdateCheck:SetChecked(dialog.autoUpdateInstances)
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
    if dialog.RefreshResetChecks then
        dialog:RefreshResetChecks()
    end
    if dialog.RefreshSmartState then
        dialog:RefreshSmartState()
    end
    ApplyCustomTaskDialogTheme(dialog)
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
    frame:SetFrameStrata("DIALOG")
    frame:SetFrameLevel(80)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    frame:SetBackdrop(MakeBackdrop())
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
    title:SetTextColor(0.92, 0.97, 1)

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

function MR:RefreshCustomTaskDialogThemes()
    if self.customTaskDialog then
        ApplyCustomTaskDialogTheme(self.customTaskDialog)
    end
    if self.customTasksTitleDialog then
        ApplyCustomTasksTitleDialogTheme(self.customTasksTitleDialog)
    end
end
