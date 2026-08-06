local _, ns = ...

local FONT_ROWS = ns.FONT_ROWS

do
    local OVERLAY_KEY = "MR_DungeonIDLabel"

    local function HideOverlay(btn)
        local label = btn and btn[OVERLAY_KEY]
        if label then
            label:Hide()
        end
    end

    local function IsLootFrame(frame)
        if not frame then return false end

        local current = frame
        while current do
            local name = current.GetName and current:GetName() or nil
            if type(name) == "string" and name:find("Loot", 1, true) then
                return true
            end
            current = current.GetParent and current:GetParent() or nil
        end

        return frame.itemID ~= nil
            or frame.itemLink ~= nil
            or frame.lootID ~= nil
    end

    local function ApplyOverlayToButton(btn)
        if not btn then return end
        if not btn.encounterID or btn.encounterID <= 0 then
            HideOverlay(btn)
            return
        end
        if IsLootFrame(btn) then
            HideOverlay(btn)
            return
        end

        local journalEncounterID = btn.encounterID
        local _, _, _, _, _, _, dungeonEncounterID = EJ_GetEncounterInfo(journalEncounterID)
        local displayID = (dungeonEncounterID and dungeonEncounterID > 0) and dungeonEncounterID or journalEncounterID
        local prefix    = (dungeonEncounterID and dungeonEncounterID > 0) and "" or "J:"

        local label = btn[OVERLAY_KEY]
        if not label then
            label = btn:CreateFontString(nil, "OVERLAY")
            label:SetFont(ns.FONT_ROWS or "Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
            label:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -8, 5)
            label:SetTextColor(0.40, 0.85, 1.00, 1)
            btn[OVERLAY_KEY] = label
        end
        label:SetText("|cff55d6ff" .. prefix .. tostring(displayID) .. "|r")
        label:Show()
    end

    local function TryExtractEncounterID(frame)
        if not frame then return end





        ApplyOverlayToButton(frame)
    end

    local function ScanFrameTree(root, depth)
        if not root or depth > 8 then return end
        TryExtractEncounterID(root)
        local ok, children = pcall(function() return {root:GetChildren()} end)
        if not ok then return end
        for _, child in ipairs(children) do
            ScanFrameTree(child, depth + 1)
        end
        if type(root.ForEachFrame) == "function" then
            pcall(function()
                root:ForEachFrame(function(frame)
                    TryExtractEncounterID(frame)
                    local ok2, children2 = pcall(function() return {frame:GetChildren()} end)
                    if ok2 then
                        for _, c in ipairs(children2) do
                            TryExtractEncounterID(c)
                        end
                    end
                end)
            end)
        end
    end

    local function RefreshEJOverlays()
        if not EncounterJournal or not EncounterJournal:IsShown() then return end
        ScanFrameTree(EncounterJournal, 0)
    end

    local function HookScrollBoxIfFound(root, depth)
        if not root or depth > 8 then return false end
        if type(root.ForEachFrame) == "function" and type(root.RegisterCallback) == "function" then
            pcall(function()
                root:RegisterCallback("OnUpdate", function()
                    root:ForEachFrame(TryExtractEncounterID)
                end)
            end)
            return true
        end
        local ok, children = pcall(function() return {root:GetChildren()} end)
        if not ok then return false end
        for _, child in ipairs(children) do
            if HookScrollBoxIfFound(child, depth + 1) then
                return true
            end
        end
        return false
    end

    local ejHookFrame = CreateFrame("Frame")
    ejHookFrame:RegisterEvent("ADDON_LOADED")
    ejHookFrame:SetScript("OnEvent", function(_, event, arg1)
        if event ~= "ADDON_LOADED" or arg1 ~= "Blizzard_EncounterJournal" then return end

        C_Timer.After(0.5, function()
            HookScrollBoxIfFound(EncounterJournal, 0)
            RefreshEJOverlays()
        end)

        for _, fname in ipairs({
            "EncounterJournal_DisplayEncounters",
            "EncounterJournal_DisplayInstance",
            "EncounterJournal_OpenJournal",
        }) do
            if type(_G[fname]) == "function" then
                hooksecurefunc(fname, function()
                    C_Timer.After(0.1, RefreshEJOverlays)
                end)
            end
        end
    end)

end
