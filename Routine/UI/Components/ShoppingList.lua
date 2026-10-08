local _, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale("MidnightRoutine")

local CALLER_ID = "MidnightRoutine"
local LIST_NAME = "Routine"

function ns.CreateDarkmoonShoppingButton(parent)
    local button = ns.HeaderIconButton(parent, "Interface\\Icons\\INV_Misc_Bag_10",
        { 1, 1, 1 }, { 1, 1, 1 },
        nil,
        function() MR:AddDarkmoonItemsToShoppingList() end)
    button._iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local onEnter = button:GetScript("OnEnter")
    button:SetScript("OnEnter", function(self)
        if onEnter then onEnter(self) end
        ns.ShowTooltip(self, {
            anchor = "ANCHOR_BOTTOM",
            build = function(tooltip)
                tooltip:SetText(L["DMF_Shopping_Title"], 1, 1, 1)
                tooltip:AddLine(L["DMF_Shopping_Required"], 1, 0.82, 0.25, true)
                tooltip:AddLine(L["DMF_Shopping_Tooltip"], 0.70, 0.82, 0.92, true)
            end,
        })
    end)
    return button
end

local function GetAPI()
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if api and api.GetShoppingListItems and api.ConvertFromSearchString
        and api.ConvertToSearchString and api.CreateShoppingList then
        return api
    end
end

local function AddItem(itemID, count)
    local api = GetAPI()
    if not api or not (C_Item and C_Item.GetItemNameByID and C_Item.GetItemCount) then return end
    local name = C_Item.GetItemNameByID(itemID)
    if not name then return end
    local missing = math.max(0, count - C_Item.GetItemCount(itemID))
    if missing == 0 then return 0 end

    local ok, existing = pcall(api.GetShoppingListItems, CALLER_ID, LIST_NAME)
    local searchStrings = {}
    local found = false
    local changed = not ok
    for _, searchString in ipairs(ok and existing or {}) do
        local term = api.ConvertFromSearchString(CALLER_ID, searchString)
        if term.searchString == name and term.isExact and not found then
            found = true
            if (tonumber(term.quantity) or 0) < missing then
                term.quantity = missing
                searchString = api.ConvertToSearchString(CALLER_ID, term)
                changed = true
            end
        end
        searchStrings[#searchStrings + 1] = searchString
    end
    if not found then
        searchStrings[#searchStrings + 1] = api.ConvertToSearchString(CALLER_ID, {
            searchString = name,
            isExact = true,
            categoryKey = "",
            quantity = missing,
        })
        changed = true
    end
    if changed then
        api.CreateShoppingList(CALLER_ID, LIST_NAME, searchStrings)
    end
    return missing
end

function MR:AddDarkmoonItemsToShoppingList()
    if not GetAPI() then
        print(L["DMF_Shopping_Unavailable"])
        return
    end
    if not self.GetDarkmoonShoppingItems then return end
    local requiredItems = self:GetDarkmoonShoppingItems()
    local remaining = #requiredItems
    if remaining == 0 then
        print(L["DMF_Shopping_NoQuests"])
        return
    end
    local missing = 0
    local failed = false
    local function FinishItem(itemID, count)
        local ok, quantity = pcall(AddItem, itemID, count)
        if ok and quantity then
            missing = missing + quantity
        else
            failed = true
        end
        remaining = remaining - 1
        if remaining == 0 then
            print(L[failed and "DMF_Shopping_Failed"
                or (missing > 0 and "DMF_Shopping_Added" or "DMF_Shopping_None")])
        end
    end
    for _, item in ipairs(requiredItems) do
        local itemID = tonumber(item.itemID)
        local count = tonumber(item.count) or 1
        if itemID and itemID > 0 and count > 0 then
            if C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID) then
                FinishItem(itemID, count)
            elseif Item and Item.CreateFromItemID then
                Item:CreateFromItemID(itemID):ContinueOnItemLoad(function()
                    FinishItem(itemID, count)
                end)
            else
                FinishItem(itemID, count)
            end
        else
            FinishItem(itemID, count)
        end
    end
end
