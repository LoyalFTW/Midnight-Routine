local _, ns = ...
local MR = ns.MR

local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local ROW_HEIGHT = 24
local HEADER_HEIGHT = 22
local FRAME_WIDTH = 360
local FRAME_HEIGHT = 460
local FRAME_MIN_WIDTH = 300
local FRAME_MIN_HEIGHT = 280
local FRAME_MAX_WIDTH = 720
local FRAME_MAX_HEIGHT = 820
local TITLE_BAR_HEIGHT = 30
local SEARCH_BAR_HEIGHT = 22
local CHROME_GAP = 8

local function CleanText(text)
    text = tostring(text or "")
    return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function MakeBackdrop()
    if ns.MakeBackdrop then
        return ns.MakeBackdrop()
    end
    return { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 }
end

local function MakeSolidBackdrop()
    return {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    }
end

local function GetRowFont()
    if type(ns.FONT_ROWS) == "string" and ns.FONT_ROWS ~= "" then
        return ns.FONT_ROWS
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function GetHeaderFont()
    if type(ns.FONT_HEADERS) == "string" and ns.FONT_HEADERS ~= "" then
        return ns.FONT_HEADERS
    end
    return GetRowFont()
end

local function GetFontFlags()
    if ns.GetFontFlags then
        return ns.GetFontFlags(MR.GetActiveMediaSettings and MR:GetActiveMediaSettings() or (MR.db and MR.db.profile))
    end
    return "OUTLINE"
end

local function GetFontSize()
    if ns.GetFontSize then
        return ns.GetFontSize()
    end
    return 11
end

local function HookBackdrop(frame)
    if ns.HookBackdropFrame then
        ns.HookBackdropFrame(frame)
    end
end

local function GetBrowserTitle()
    local title = L["Currencies"]
    if not title or title == "Currencies" then
        return "Currencies"
    end
    return title
end

local function FormatQuantity(value)
    value = tonumber(value) or 0
    if BreakUpLargeNumbers then
        return BreakUpLargeNumbers(value)
    end
    return tostring(value)
end

local function CurrencyInfoHasAnyFlag(info, ...)
    if type(info) ~= "table" then
        return false
    end

    for i = 1, select("#", ...) do
        local key = select(i, ...)
        if info[key] then
            return true
        end
    end

    return false
end

local function IsCurrencyWarbandTransferable(currencyID, info)
    if CurrencyInfoHasAnyFlag(
        info,
        "isAccountTransferable",
        "isWarbandTransferable",
        "isTransferable",
        "transferable"
    ) then
        return true
    end

    if C_CurrencyInfo then
        local candidates = {
            "IsCurrencyAccountTransferable",
            "IsCurrencyTransferable",
            "IsAccountTransferableCurrency",
        }
        for _, methodName in ipairs(candidates) do
            local method = C_CurrencyInfo[methodName]
            if type(method) == "function" then
                local ok, result = pcall(method, currencyID)
                if ok and result then
                    return true
                end
            end
        end
    end

    return false
end

local function GetCurrencyWarbandMarkerInfo(currencyID)
    if MR.GetCurrencyWarbandMarkerInfo then
        return MR:GetCurrencyWarbandMarkerInfo(currencyID)
    end

    if not (currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return nil
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info then
        return nil
    end

    if info.isAccountWide then
        return {
            atlas = "warbands-icon",
            text = ACCOUNT_LEVEL_CURRENCY or "Warband Currency",
        }
    elseif IsCurrencyWarbandTransferable(currencyID, info) then
        return {
            atlas = "warbands-transferable-icon",
            text = ACCOUNT_TRANSFERRABLE_CURRENCY or "Warband Transferable",
        }
    end

    return nil
end

local function AddCurrencyTransferTooltipLines(tooltip, currencyID)
    if MR.AddCurrencyTransferTooltipLines and MR:AddCurrencyTransferTooltipLines(tooltip, currencyID) then
        return true
    end

    if not (tooltip and currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo) then
        return false
    end

    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not IsCurrencyWarbandTransferable(currencyID, info) then
        return false
    end

    local percentage = tonumber(info and (info.transferPercentage or info.accountTransferPercentage or info.currencyTransferPercentage))
    tooltip:AddLine(" ")
    if percentage and percentage > 0 then
        tooltip:AddLine(string.format("Warband Transfer: %d%%", percentage), 0.45, 0.85, 1, true)
    else
        tooltip:AddLine("Warband Transferable", 0.45, 0.85, 1, true)
    end
    return true
end

local function GetCurrencyWarbandStatusText(marker)
    if marker and marker.text then
        return marker.text
    end

    return L["CurrencyBrowser_NotWarbandTransferable"] or "Not Warband transferable"
end

local function SetWarbandFilterButtonState(frame)
    local button = frame and frame.warbandFilterButton
    if not button then
        return
    end

    local active = frame.showWarbandOnly and true or false
    button:SetBackdropColor(active and 0.08 or 0.03, active and 0.18 or 0.06, active and 0.18 or 0.08, 1)
    button:SetBackdropBorderColor(active and 0.30 or 0.16, active and 0.75 or 0.28, active and 0.65 or 0.32, 1)
    if button.icon then
        button.icon:SetVertexColor(active and 1 or 0.58, active and 1 or 0.68, active and 1 or 0.72, active and 1 or 0.9)
    end
end

local function NormalizeSearch(text)
    text = tostring(text or "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    return text:lower()
end

local function GetCollapsedHeaders()
    if not (MR and MR.db and MR.db.char) then
        return {}
    end

    MR.db.char.currencyBrowserCollapsedHeaders = MR.db.char.currencyBrowserCollapsedHeaders or {}
    return MR.db.char.currencyBrowserCollapsedHeaders
end

local function GetHeaderKey(name)
    name = CleanText(name or "")
    if name == "" then
        return "__uncategorized"
    end
    return name
end

local function EntryMatchesSearch(entry, search)
    if search == "" then
        return true
    end

    local name = CleanText(entry.name):lower()
    local id = tostring(entry.currencyID or "")
    return name:find(search, 1, true) ~= nil or id:find(search, 1, true) ~= nil
end

local function AddCurrencyListEntry(entries, info, headerKey, forceOpen)
    if not info then
        return
    end

    if info.isHeader then
        entries[#entries + 1] = {
            isHeader = true,
            name = info.name or "",
            headerKey = headerKey or GetHeaderKey(info.name),
            forceOpen = forceOpen and true or false,
        }
        return
    end

    local currencyID = tonumber(info.currencyID or info.currencyId)
    if not currencyID then
        return
    end

    local currencyInfo = C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID) or nil
    entries[#entries + 1] = {
        currencyID = currencyID,
        name = (currencyInfo and currencyInfo.name) or info.name or ("Currency " .. tostring(currencyID)),
        quantity = (currencyInfo and currencyInfo.quantity) or info.quantity or 0,
        maxQuantity = currencyInfo and currencyInfo.maxQuantity or 0,
        weekly = currencyInfo and currencyInfo.quantityEarnedThisWeek or 0,
        weeklyMax = currencyInfo and currencyInfo.maxWeeklyQuantity or 0,
        icon = currencyInfo and currencyInfo.iconFileID,
        headerKey = headerKey,
    }
end

local function BuildCurrencyEntries(searchText, warbandOnly)
    local entries = {}
    local pendingHeader
    local pendingHeaderKey
    local collapsedHeaders = GetCollapsedHeaders()
    local search = NormalizeSearch(searchText)
    local isSearching = search ~= ""

    if not (C_CurrencyInfo and C_CurrencyInfo.GetCurrencyListSize and C_CurrencyInfo.GetCurrencyListInfo) then
        return entries
    end

    local index = 1
    while index <= C_CurrencyInfo.GetCurrencyListSize() do
        local info = C_CurrencyInfo.GetCurrencyListInfo(index)
        if info and info.isHeader and not info.isHeaderExpanded and C_CurrencyInfo.ExpandCurrencyList then
            C_CurrencyInfo.ExpandCurrencyList(index, true)
        end
        index = index + 1
    end

    index = 1
    while index <= C_CurrencyInfo.GetCurrencyListSize() do
        local info = C_CurrencyInfo.GetCurrencyListInfo(index)
        if info and info.isHeader then
            pendingHeader = info
            pendingHeaderKey = GetHeaderKey(info.name)
        else
            local currencyID = info and tonumber(info.currencyID or info.currencyId)
            if currencyID and not (MR.IsCurrencyInCurrenciesModule and MR:IsCurrencyInCurrenciesModule(currencyID)) then
                local currencyInfo = C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(currencyID) or nil
                local candidate = {
                    currencyID = currencyID,
                    name = (currencyInfo and currencyInfo.name) or info.name or ("Currency " .. tostring(currencyID)),
                }
                local includeCurrency = (not warbandOnly) or (GetCurrencyWarbandMarkerInfo(currencyID) ~= nil)
                if includeCurrency and EntryMatchesSearch(candidate, search) then
                    if pendingHeader then
                        AddCurrencyListEntry(entries, pendingHeader, pendingHeaderKey, isSearching)
                        if collapsedHeaders[pendingHeaderKey] and not isSearching then
                            pendingHeader = nil
                            index = index + 1
                            while index <= C_CurrencyInfo.GetCurrencyListSize() do
                                local nextInfo = C_CurrencyInfo.GetCurrencyListInfo(index)
                                if nextInfo and nextInfo.isHeader then
                                    index = index - 1
                                    break
                                end
                                index = index + 1
                            end
                        else
                            AddCurrencyListEntry(entries, info, pendingHeaderKey)
                            pendingHeader = nil
                        end
                    else
                        AddCurrencyListEntry(entries, info, pendingHeaderKey)
                    end
                elseif pendingHeader and collapsedHeaders[pendingHeaderKey] and not isSearching then
                    AddCurrencyListEntry(entries, pendingHeader, pendingHeaderKey, isSearching)
                    pendingHeader = nil
                end
            end
        end
        index = index + 1
    end

    return entries
end

local function PositionBrowser(frame)
    frame:ClearAllPoints()
    if MR.frame and MR.frame:IsShown() then
        frame:SetPoint("TOPLEFT", MR.frame, "TOPRIGHT", 8, 0)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 220, 0)
    end
end

local function ScrollFrameByDelta(frame, delta)
    if not (frame and frame.scroll and frame.content) then
        return
    end

    ns.ScrollByDelta(frame.scroll, frame.content, delta, 30, frame.UpdateScrollBar)
end

local function EnsureRow(frame, index)
    frame.rows = frame.rows or {}
    local row = frame.rows[index]
    if row then
        row:Show()
        return row
    end

    row = CreateFrame("Button", nil, frame.content, "BackdropTemplate")
    row._browserFrame = frame
    row:SetHeight(ROW_HEIGHT)
    row:EnableMouseWheel(true)
    row:SetBackdrop(MakeBackdrop())
    HookBackdrop(row)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.warbandIcon = row:CreateTexture(nil, "ARTWORK")
    row.warbandIcon:SetSize(20, 28)
    row.warbandHitBox = CreateFrame("Frame", nil, row)
    row.warbandHitBox:SetSize(20, ROW_HEIGHT)
    row.warbandHitBox:EnableMouse(true)
    row.warbandHitBox:SetScript("OnEnter", function(self)
        local owner = self:GetParent()
        if owner and owner.warbandIcon and self._mrHasMarker then
            owner.warbandIcon:Show()
        end
        ns.ShowTooltip(self, {
            text = self._mrTooltipText or L["CurrencyBrowser_NotWarbandTransferable"] or "Not Warband transferable",
            wrap = true,
        })
    end)
    row.warbandHitBox:SetScript("OnLeave", function(self)
        local owner = self:GetParent()
        if owner and owner.warbandIcon then
            owner.warbandIcon:Hide()
        end
        ns.HideTooltip(self)
    end)

    row.name = row:CreateFontString(nil, "OVERLAY")
    row.name:SetFont(GetRowFont(), math.max(9, GetFontSize() - 1), GetFontFlags())
    row.name:SetJustifyH("LEFT")

    row.count = row:CreateFontString(nil, "OVERLAY")
    row.count:SetFont(GetRowFont(), math.max(9, GetFontSize() - 1), GetFontFlags())
    row.count:SetJustifyH("RIGHT")

    row.add = CreateFrame("Button", nil, row, "BackdropTemplate")
    row.add:SetSize(42, 18)
    row.add:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.add:SetBackdrop(MakeSolidBackdrop())
    row.add:SetBackdropColor(0.05, 0.11, 0.13, 1)
    row.add:SetBackdropBorderColor(0.16, 0.55, 0.45, 1)
    row.add.text = row.add:CreateFontString(nil, "OVERLAY")
    row.add.text:SetFont(GetRowFont(), math.max(8, GetFontSize() - 2), GetFontFlags())
    row.add.text:SetPoint("CENTER")
    row.add.text:SetText(L["CurrencyBrowser_Add"] or "Add")
    row.add.text:SetTextColor(0.48, 0.96, 0.78)
    row.add:SetScript("OnClick", function(self)
        local owner = self:GetParent()
        if owner and owner.currencyID and MR.AddCurrencyToCurrencies then
            MR:AddCurrencyToCurrencies(owner.currencyID)
        end
    end)
    row.add:SetScript("OnEnter", function(self)
        ns.ShowTooltip(self, {
            build = function(tooltip)
                tooltip:SetText(L["CurrencyBrowser_AddTooltipTitle"] or "Add to Currencies", 1, 1, 1)
                tooltip:AddLine(L["CurrencyBrowser_AddTooltipText"] or "Adds this currency to MidnightRoutine's current Currencies section.", 0.55, 0.82, 1, true)
            end,
        })
    end)
    row.add:SetScript("OnLeave", function(self)
        ns.HideTooltip(self)
    end)

    row:SetScript("OnEnter", function(self)
        if self.warbandIcon and self.warbandIcon._mrHasMarker then
            self.warbandIcon:Show()
        end
        if self.currencyID then
            ns.ShowTooltip(self, {
                build = function(tooltip)
                    tooltip:SetCurrencyByID(self.currencyID)
                    AddCurrencyTransferTooltipLines(tooltip, self.currencyID)
                end,
            })
        end
    end)
    row:SetScript("OnLeave", function(self)
        if row.warbandIcon then
            row.warbandIcon:Hide()
        end
        ns.HideTooltip(self)
    end)
    row:SetScript("OnMouseWheel", function(self, delta)
        ScrollFrameByDelta(self._browserFrame, delta)
    end)
    row:SetScript("OnClick", function(self)
        if self.isHeader then
            local collapsed = GetCollapsedHeaders()
            if collapsed[self.headerKey] then
                collapsed[self.headerKey] = nil
            else
                collapsed[self.headerKey] = true
            end
            if MR.RefreshCurrencyBrowserFrame then
                MR:RefreshCurrencyBrowserFrame(true)
            end
        elseif self.currencyID and MR.AddCurrencyToCurrencies then
            MR:AddCurrencyToCurrencies(self.currencyID)
        end
    end)

    frame.rows[index] = row
    return row
end

local function ApplyRow(row, entry, y)
    row._entry = entry
    row._layoutY = y

    local rowFont = GetRowFont()
    local rowSize = math.max(9, GetFontSize() - 1)
    row.name:SetFont(rowFont, rowSize, GetFontFlags())
    row.count:SetFont(rowFont, rowSize, GetFontFlags())
    row.add.text:SetFont(rowFont, math.max(8, GetFontSize() - 2), GetFontFlags())
    row:SetBackdrop(MakeBackdrop())
    HookBackdrop(row)
    row.add:SetBackdrop(MakeSolidBackdrop())
    row.add:SetBackdropColor(0.05, 0.11, 0.13, 1)
    row.add:SetBackdropBorderColor(0.16, 0.55, 0.45, 1)

    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", row:GetParent(), "TOPLEFT", 0, -y)
    row:SetPoint("TOPRIGHT", row:GetParent(), "TOPRIGHT", 0, -y)
    row.currencyID = entry.currencyID
    row.isHeader = entry.isHeader and true or false
    row.headerKey = entry.headerKey

    if entry.isHeader then
        row:EnableMouse(true)
        local collapsed = (not entry.forceOpen) and GetCollapsedHeaders()[entry.headerKey] and true or false
        row:SetBackdropColor(0.06, 0.08, 0.13, 0.95)
        row:SetBackdropBorderColor(0.18, 0.22, 0.32, 1)
        row.icon:Hide()
        row.warbandIcon:Hide()
        row.warbandHitBox:Hide()
        row.add:Hide()
        row.name:ClearAllPoints()
        row.count:ClearAllPoints()
        row.name:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.count:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        row.name:SetPoint("RIGHT", row.count, "LEFT", -8, 0)
        row.name:SetText(CleanText(entry.name))
        row.name:SetTextColor(0.82, 0.66, 0.98)
        row.count:SetText(collapsed and "+" or "-")
        row.count:SetTextColor(0.50, 0.95, 0.80)
        return HEADER_HEIGHT
    end

    row:EnableMouse(true)
    row:SetBackdropColor(0.02, 0.03, 0.05, 0.88)
    row:SetBackdropBorderColor(0.10, 0.13, 0.18, 1)
    row.icon:Show()
    row.warbandIcon:Hide()
    row.add:Show()
    row.add:SetBackdropColor(0.05, 0.11, 0.13, 1)
    row.add:SetBackdropBorderColor(0.16, 0.55, 0.45, 1)
    row.icon:SetTexture(entry.icon or 134400)
    row.name:ClearAllPoints()
    row.count:ClearAllPoints()
    row.icon:ClearAllPoints()
    row.warbandIcon:ClearAllPoints()
    local warbandMarker = entry.currencyID and GetCurrencyWarbandMarkerInfo(entry.currencyID) or nil
    row.warbandIcon:SetPoint("LEFT", row, "LEFT", -1, 0)
    row.warbandIcon._mrHasMarker = warbandMarker and true or false
    row.warbandIcon._mrTooltipText = GetCurrencyWarbandStatusText(warbandMarker)
    if warbandMarker and row.warbandIcon.SetAtlas then
        row.warbandIcon:SetAtlas(warbandMarker.atlas)
        row.warbandIcon:SetTexCoord(0, 1, 0, 1)
    end
    row.warbandHitBox:ClearAllPoints()
    row.warbandHitBox:SetPoint("CENTER", row.warbandIcon, "CENTER", 0, 0)
    row.warbandHitBox._mrHasMarker = warbandMarker and true or false
    row.warbandHitBox._mrTooltipText = GetCurrencyWarbandStatusText(warbandMarker)
    row.warbandHitBox:Show()
    row.icon:SetPoint("RIGHT", row.add, "LEFT", -8, 0)
    row.count:SetPoint("RIGHT", row.icon, "LEFT", -4, 0)
    row.name:SetPoint("LEFT", row, "LEFT", 20, 0)
    row.name:SetPoint("RIGHT", row.count, "LEFT", -8, 0)
    row.name:SetText(CleanText(entry.name))
    row.name:SetTextColor(0.92, 0.94, 0.98)

    local countText = FormatQuantity(entry.quantity)
    if entry.maxQuantity and entry.maxQuantity > 0 then
        countText = countText .. " / " .. FormatQuantity(entry.maxQuantity)
    elseif entry.weeklyMax and entry.weeklyMax > 0 then
        countText = FormatQuantity(entry.weekly) .. " / " .. FormatQuantity(entry.weeklyMax)
    end
    row.count:SetText(countText)
    row.count:SetTextColor(0.84, 0.76, 0.46)
    return ROW_HEIGHT
end

local function ClampScroll(frame)
    if not (frame and frame.scroll and frame.content) then
        return
    end

    local maxScroll = math.max((frame.content:GetHeight() or 0) - (frame.scroll:GetHeight() or 0), 0)
    local current = frame.scroll:GetVerticalScroll() or 0
    if current > maxScroll then
        frame.scroll:SetVerticalScroll(maxScroll)
    elseif current < 0 then
        frame.scroll:SetVerticalScroll(0)
    end
    if frame.UpdateScrollBar then
        frame:UpdateScrollBar()
    end
end

function MR:RefreshCurrencyBrowserFrame(keepScroll)
    local frame = self.currencyBrowserFrame
    if not frame then
        return
    end

    if not (self.frame and self.frame:IsShown()) or (self.db and self.db.profile and self.db.profile.minimized) then
        frame:Hide()
        return
    end

    if frame.content and frame.scroll then
        frame.content:SetWidth(math.max(frame.scroll:GetWidth(), 1))
    end

    SetWarbandFilterButtonState(frame)
    local entries = BuildCurrencyEntries(frame.searchInput and frame.searchInput:GetText() or "", frame.showWarbandOnly)
    local currencyCount = 0
    local y = 0
    for index, entry in ipairs(entries) do
        if not entry.isHeader then
            currencyCount = currencyCount + 1
        end
        local row = EnsureRow(frame, index)
        local height = ApplyRow(row, entry, y)
        row:SetHeight(height)
        y = y + height + 2
    end

    for index = #entries + 1, #(frame.rows or {}) do
        frame.rows[index]:Hide()
    end

    frame.content:SetHeight(math.max(y, frame.scroll:GetHeight()))
    if frame.count then
        frame.count:SetText("")
        frame.count:Hide()
    end
    if keepScroll then
        ClampScroll(frame)
    else
        frame.scroll:SetVerticalScroll(0)
        if frame.UpdateScrollBar then
            frame:UpdateScrollBar()
        end
    end
end

function MR:HideCurrencyBrowserFrame()
    if self.currencyBrowserFrame then
        self.currencyBrowserFrame:Hide()
    end
end

function MR:ApplyCurrencyBrowserTheme()
    local frame = self.currencyBrowserFrame
    if not frame then
        return
    end

    local rowFont = GetRowFont()
    local headerFont = GetHeaderFont()
    local fontSize = GetFontSize()
    local flags = GetFontFlags()

    frame:SetBackdrop(MakeBackdrop())
    HookBackdrop(frame)
    frame:SetBackdropColor(0.02, 0.03, 0.05, 0.97)
    frame:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)

    if frame.title then frame.title:SetFont(headerFont, math.max(10, fontSize + 2), flags) end
    if frame.count then frame.count:SetFont(rowFont, math.max(8, fontSize - 2), flags) end
    if frame.closeText then frame.closeText:SetFont(headerFont, math.max(9, fontSize), flags) end
    if frame.refreshText then frame.refreshText:SetFont(rowFont, math.max(8, fontSize - 2), flags) end
    if frame.searchInput then frame.searchInput:SetFont(rowFont, math.max(9, fontSize - 1), flags) end
    if frame.searchPlaceholder then frame.searchPlaceholder:SetFont(rowFont, math.max(9, fontSize - 1), flags) end

    if frame.titleBar then
        frame.titleBar:SetBackdrop(MakeBackdrop())
        HookBackdrop(frame.titleBar)
        frame.titleBar:SetBackdropColor(0.03, 0.06, 0.12, 0.98)
        frame.titleBar:SetBackdropBorderColor(0.17, 0.24, 0.32, 1)
    end

    if frame.closeButton then
        frame.closeButton:SetBackdrop(MakeBackdrop())
        HookBackdrop(frame.closeButton)
        frame.closeButton:SetBackdropColor(0.07, 0.09, 0.12, 1)
        frame.closeButton:SetBackdropBorderColor(0.28, 0.34, 0.42, 1)
    end
    if frame.refreshButton then
        frame.refreshButton:SetBackdrop(MakeBackdrop())
        HookBackdrop(frame.refreshButton)
        frame.refreshButton:SetBackdropColor(0.05, 0.10, 0.13, 1)
        frame.refreshButton:SetBackdropBorderColor(0.18, 0.48, 0.42, 1)
    end
    if frame.warbandFilterButton then
        frame.warbandFilterButton:SetBackdrop(MakeBackdrop())
        HookBackdrop(frame.warbandFilterButton)
        SetWarbandFilterButtonState(frame)
    end
    if frame.searchBg then
        frame.searchBg:SetBackdrop(MakeBackdrop())
        HookBackdrop(frame.searchBg)
        frame.searchBg:SetBackdropColor(0.02, 0.04, 0.06, 1)
        frame.searchBg:SetBackdropBorderColor(0.16, 0.28, 0.32, 1)
    end

    if frame.LayoutChrome then
        frame:LayoutChrome()
    end

    for _, row in ipairs(frame.rows or {}) do
        if row:IsShown() and row._entry then
            ApplyRow(row, row._entry, row._layoutY or 0)
        elseif row.name then
            row.name:SetFont(rowFont, math.max(9, fontSize - 1), flags)
        end
    end
    if frame.count then
        frame.count:Hide()
    end
end

function MR:ShowCurrencyBrowserFrame()
    if not (self.frame and self.frame:IsShown()) or (self.db and self.db.profile and self.db.profile.minimized) then
        return
    end

    if not self.currencyBrowserFrame then
        local frame = CreateFrame("Frame", "MidnightRoutineCurrencyBrowserFrame", UIParent, "BackdropTemplate")
        local savedW = self.db and self.db.profile and tonumber(self.db.profile.currencyBrowserWidth) or FRAME_WIDTH
        local savedH = self.db and self.db.profile and tonumber(self.db.profile.currencyBrowserHeight) or FRAME_HEIGHT
        frame:SetSize(
            math.max(FRAME_MIN_WIDTH, math.min(FRAME_MAX_WIDTH, savedW or FRAME_WIDTH)),
            math.max(FRAME_MIN_HEIGHT, math.min(FRAME_MAX_HEIGHT, savedH or FRAME_HEIGHT))
        )
        frame:SetFrameStrata("DIALOG")
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
        if self.frame and self.frame.HookScript and not self._currencyBrowserMainHideHooked then
            self.frame:HookScript("OnHide", function()
                if MR.HideCurrencyBrowserFrame then
                    MR:HideCurrencyBrowserFrame()
                end
            end)
            self._currencyBrowserMainHideHooked = true
        end
        frame:SetBackdrop(MakeBackdrop())
        HookBackdrop(frame)
        frame:SetBackdropColor(0.02, 0.03, 0.05, 0.97)
        frame:SetBackdropBorderColor(0.18, 0.22, 0.28, 1)

        local titleBar = ns.TitleBar(frame, TITLE_BAR_HEIGHT)
        frame.titleBar = titleBar
        titleBar:SetBackdropColor(0.03, 0.06, 0.12, 0.98)
        titleBar:SetBackdropBorderColor(0.17, 0.24, 0.32, 1)
        titleBar:SetScript("OnDragStart", function()
            frame:StartMoving()
        end)
        titleBar:SetScript("OnDragStop", function()
            frame:StopMovingOrSizing()
        end)

        frame.title = titleBar:CreateFontString(nil, "OVERLAY")
        frame.title:SetFont(GetHeaderFont(), math.max(10, GetFontSize() + 2), GetFontFlags())
        frame.title:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
        frame.title:SetJustifyH("LEFT")
        frame.title:SetText(GetBrowserTitle())
        frame.title:SetTextColor(0.30, 0.90, 0.75)

        frame.count = titleBar:CreateFontString(nil, "OVERLAY")
        frame.count:SetFont(GetRowFont(), math.max(8, GetFontSize() - 2), GetFontFlags())
        frame.count:SetTextColor(0.62, 0.68, 0.76)
        frame.count:Hide()

        local close = ns.HeaderButton(titleBar, {
            size = 20,
            text = "x",
            font = GetHeaderFont(),
            fontSize = math.max(9, GetFontSize()),
            color = { 0.90, 0.58, 0.58, 1 },
            background = { 0.07, 0.09, 0.12, 1 },
            border = { 0.28, 0.34, 0.42, 1 },
            hoverBackground = { 0.24, 0.07, 0.07, 1 },
            hoverBorder = { 0.80, 0.24, 0.24, 1 },
            onClick = function() frame:Hide() end,
        })
        frame.closeButton = close
        close.text = close._lbl
        frame.closeText = close.text

        local refresh = ns.HeaderButton(titleBar, {
            width = 64,
            height = 20,
            text = L["CurrencyBrowser_Refresh"] or "Refresh",
            font = GetRowFont(),
            fontSize = math.max(8, GetFontSize() - 2),
            color = { 0.50, 0.95, 0.80, 1 },
            background = { 0.05, 0.10, 0.13, 1 },
            border = { 0.18, 0.48, 0.42, 1 },
            onClick = function() MR:RefreshCurrencyBrowserFrame() end,
        })
        frame.refreshButton = refresh
        refresh.text = refresh._lbl
        frame.refreshText = refresh.text

        local warbandFilter = CreateFrame("Button", nil, frame, "BackdropTemplate")
        frame.warbandFilterButton = warbandFilter
        warbandFilter:SetSize(24, SEARCH_BAR_HEIGHT)
        warbandFilter:SetBackdrop(MakeBackdrop())
        HookBackdrop(warbandFilter)
        warbandFilter.icon = warbandFilter:CreateTexture(nil, "ARTWORK")
        warbandFilter.icon:SetSize(20, 28)
        warbandFilter.icon:SetPoint("CENTER", warbandFilter, "CENTER", 0, 0)
        if warbandFilter.icon.SetAtlas then
            warbandFilter.icon:SetAtlas("warbands-transferable-icon")
        end
        warbandFilter:SetScript("OnClick", function(selfButton)
            local owner = selfButton:GetParent()
            owner.showWarbandOnly = not owner.showWarbandOnly
            SetWarbandFilterButtonState(owner)
            if MR.RefreshCurrencyBrowserFrame then
                MR:RefreshCurrencyBrowserFrame(false)
            end
        end)
        warbandFilter:SetScript("OnEnter", function(selfButton)
            ns.ShowTooltip(selfButton, {
                build = function(tooltip)
                    if selfButton:GetParent().showWarbandOnly then
                        tooltip:SetText(L["CurrencyBrowser_WarbandFilterActive"] or "Showing Warband currencies", 1, 1, 1, 1, true)
                        tooltip:AddLine(L["CurrencyBrowser_WarbandFilterDisable"] or "Click to show all currencies.", 0.55, 0.82, 1, true)
                    else
                        tooltip:SetText(L["CurrencyBrowser_WarbandFilterTitle"] or "Show Warband currencies only", 1, 1, 1, 1, true)
                        tooltip:AddLine(L["CurrencyBrowser_WarbandFilterText"] or "Filters to Warband transferable and Warband-wide currencies.", 0.55, 0.82, 1, true)
                    end
                end,
            })
        end)
        warbandFilter:SetScript("OnLeave", function(selfButton)
            ns.HideTooltip(selfButton)
        end)
        SetWarbandFilterButtonState(frame)

        local searchBg = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.searchBg = searchBg
        searchBg:SetBackdrop(MakeBackdrop())
        HookBackdrop(searchBg)
        searchBg:SetBackdropColor(0.02, 0.04, 0.06, 1)
        searchBg:SetBackdropBorderColor(0.16, 0.28, 0.32, 1)

        local searchInput = CreateFrame("EditBox", nil, searchBg, "InputBoxTemplate")
        searchInput:SetAutoFocus(false)
        searchInput:SetFont(GetRowFont(), math.max(9, GetFontSize() - 1), GetFontFlags())
        searchInput:SetPoint("LEFT", searchBg, "LEFT", 8, 0)
        searchInput:SetPoint("RIGHT", searchBg, "RIGHT", -8, 0)
        searchInput:SetHeight(18)
        searchInput:SetMaxLetters(80)
        searchInput:SetTextColor(0.92, 0.94, 0.98)
        searchInput:SetScript("OnTextChanged", function()
            MR:RefreshCurrencyBrowserFrame(false)
        end)
        searchInput:SetScript("OnEscapePressed", function(selfEdit)
            selfEdit:SetText("")
            selfEdit:ClearFocus()
        end)
        searchInput:SetScript("OnEnterPressed", function(selfEdit)
            selfEdit:ClearFocus()
        end)
        frame.searchInput = searchInput

        frame.searchPlaceholder = searchBg:CreateFontString(nil, "OVERLAY")
        frame.searchPlaceholder:SetFont(GetRowFont(), math.max(9, GetFontSize() - 1), GetFontFlags())
        frame.searchPlaceholder:SetPoint("LEFT", searchBg, "LEFT", 10, 0)
        frame.searchPlaceholder:SetText(L["CurrencyBrowser_SearchPlaceholder"] or "Search currencies...")
        frame.searchPlaceholder:SetTextColor(0.38, 0.46, 0.52)
        searchInput:HookScript("OnTextChanged", function(selfEdit)
            frame.searchPlaceholder:SetShown((selfEdit:GetText() or "") == "")
        end)

        frame.scroll = CreateFrame("ScrollFrame", nil, frame)
        frame:EnableMouseWheel(true)
        frame:SetScript("OnMouseWheel", function(_, delta)
            ScrollFrameByDelta(frame, delta)
        end)

        frame.content = CreateFrame("Frame", nil, frame.scroll)
        frame.content:SetSize(FRAME_WIDTH - 32, FRAME_HEIGHT - 76)
        frame.content:EnableMouseWheel(true)
        frame.content:SetScript("OnMouseWheel", function(_, delta)
            ScrollFrameByDelta(frame, delta)
        end)

        local track = CreateFrame("Frame", nil, frame)
        track:SetPoint("TOPLEFT", frame.scroll, "TOPRIGHT", 3, 0)
        track:SetPoint("BOTTOMLEFT", frame.scroll, "BOTTOMRIGHT", 3, 0)
        track:SetWidth(5)
        frame.scrollTrack = track

        local UpdateScrollBar, thumb = ns.AttachScrollList(frame.scroll, frame.content, track, {
            hideTrack = true,
            thumbColor = { 0.25, 0.65, 0.65, 0.75 },
        })
        frame.UpdateScrollBar = UpdateScrollBar
        frame.scrollThumb = thumb

        function frame:LayoutChrome()
            titleBar:SetHeight(TITLE_BAR_HEIGHT)
            close:ClearAllPoints()
            close:SetSize(20, 20)
            close:SetPoint("RIGHT", titleBar, "RIGHT", -8, 0)

            refresh:ClearAllPoints()
            refresh:SetSize(64, 20)
            refresh:SetPoint("RIGHT", close, "LEFT", -6, 0)

            self.title:ClearAllPoints()
            self.title:SetPoint("LEFT", titleBar, "LEFT", 12, 0)
            self.title:SetPoint("RIGHT", refresh, "LEFT", -10, 0)

            if self.warbandFilterButton then
                self.warbandFilterButton:ClearAllPoints()
                self.warbandFilterButton:SetSize(24, SEARCH_BAR_HEIGHT)
                self.warbandFilterButton:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 8, -CHROME_GAP)
            end

            searchBg:ClearAllPoints()
            if self.warbandFilterButton then
                searchBg:SetPoint("TOPLEFT", self.warbandFilterButton, "TOPRIGHT", 6, 0)
            else
                searchBg:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 8, -CHROME_GAP)
            end
            searchBg:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", -8, -CHROME_GAP)
            searchBg:SetHeight(SEARCH_BAR_HEIGHT)

            self.scroll:ClearAllPoints()
            if self.warbandFilterButton then
                self.scroll:SetPoint("TOPLEFT", self.warbandFilterButton, "BOTTOMLEFT", 0, -CHROME_GAP)
            else
                self.scroll:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 8, -(CHROME_GAP + SEARCH_BAR_HEIGHT + CHROME_GAP))
            end
            self.scroll:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -18, 12)
            if self.content then
                self.content:SetWidth(math.max(self.scroll:GetWidth(), 1))
            end
            if self.UpdateScrollBar then
                self:UpdateScrollBar()
            end
        end

        local dragger = CreateFrame("Frame", nil, frame)
        frame.resizeDragger = dragger
        dragger:SetSize(12, 12)
        dragger:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        dragger:SetFrameLevel(frame:GetFrameLevel() + 10)
        dragger:EnableMouse(true)

        local dragTex = dragger:CreateTexture(nil, "OVERLAY")
        dragTex:SetAllPoints()
        dragTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

        dragger:SetScript("OnEnter", function()
            dragTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        end)
        dragger:SetScript("OnLeave", function()
            dragTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        end)

        local dragStartW, dragStartH, dragStartX, dragStartY
        dragger:SetScript("OnMouseDown", function(_, button)
            if button ~= "LeftButton" then return end
            dragStartW = frame:GetWidth()
            dragStartH = frame:GetHeight()
            dragStartX, dragStartY = GetCursorPosition()
            local scale = frame:GetEffectiveScale()
            dragStartX = dragStartX / scale
            dragStartY = dragStartY / scale
            dragger._dragging = true
        end)
        dragger:SetScript("OnMouseUp", function(_, button)
            if button ~= "LeftButton" or not dragger._dragging then return end
            dragger._dragging = false
            local newW = math.max(FRAME_MIN_WIDTH, math.min(FRAME_MAX_WIDTH, math.floor(frame:GetWidth())))
            local newH = math.max(FRAME_MIN_HEIGHT, math.min(FRAME_MAX_HEIGHT, math.floor(frame:GetHeight())))
            frame:SetSize(newW, newH)
            if MR.db and MR.db.profile then
                MR.db.profile.currencyBrowserWidth = newW
                MR.db.profile.currencyBrowserHeight = newH
            end
            if MR.RefreshCurrencyBrowserFrame then
                MR:RefreshCurrencyBrowserFrame(true)
            end
        end)
        dragger:SetScript("OnUpdate", function()
            if not dragger._dragging then return end
            local cx, cy = GetCursorPosition()
            local scale = frame:GetEffectiveScale()
            cx = cx / scale
            cy = cy / scale
            local dx = cx - dragStartX
            local dy = dragStartY - cy
            local newW = math.max(FRAME_MIN_WIDTH, math.min(FRAME_MAX_WIDTH, dragStartW + dx))
            local newH = math.max(FRAME_MIN_HEIGHT, math.min(FRAME_MAX_HEIGHT, dragStartH + dy))
            frame:SetSize(newW, newH)
            frame.content:SetWidth(math.max(frame.scroll:GetWidth(), 1))
            if frame.UpdateScrollBar then
                frame:UpdateScrollBar()
            end
        end)

        frame:SetScript("OnSizeChanged", function(selfFrame)
            if selfFrame.LayoutChrome then
                selfFrame:LayoutChrome()
                return
            end
            if selfFrame.content and selfFrame.scroll then
                selfFrame.content:SetWidth(math.max(selfFrame.scroll:GetWidth(), 1))
            end
            if selfFrame.UpdateScrollBar then
                selfFrame:UpdateScrollBar()
            end
        end)

        self.currencyBrowserFrame = frame
    end

    PositionBrowser(self.currencyBrowserFrame)
    self.currencyBrowserFrame:Show()
    if self.ApplyCurrencyBrowserTheme then
        self:ApplyCurrencyBrowserTheme()
    end
    if self.currencyBrowserFrame.LayoutChrome then
        self.currencyBrowserFrame:LayoutChrome()
    end
    self:RefreshCurrencyBrowserFrame()
end

function MR:ToggleCurrencyBrowserFrame()
    if not (self.frame and self.frame:IsShown()) or (self.db and self.db.profile and self.db.profile.minimized) then
        if self.HideCurrencyBrowserFrame then
            self:HideCurrencyBrowserFrame()
        end
        return
    end

    if self.currencyBrowserFrame and self.currencyBrowserFrame:IsShown() then
        self.currencyBrowserFrame:Hide()
    else
        self:ShowCurrencyBrowserFrame()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
eventFrame:SetScript("OnEvent", function()
    if MR.currencyBrowserFrame and MR.currencyBrowserFrame:IsShown() then
        MR:RefreshCurrencyBrowserFrame()
    end
end)
