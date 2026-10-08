local _, ns = ...
local RoutineData = ns.RoutineData
if not RoutineData then return end

local CAPTURE_DEBOUNCE = 0.5
local LOGIN_DELAY = 1

function RoutineData:CaptureGold()
    local charKey = self:GetCurrentCharacterKey()
    local money = GetMoney and GetMoney()
    if not charKey or type(money) ~= "number" then return end
    local record = self:GetCharacterRecord(charKey, true)
    record.gold = money
    record.classFile = select(2, UnitClass("player")) or record.classFile
    record.updatedAt.gold = (GetServerTime and GetServerTime()) or time()
    self:Fire("GoldUpdated", charKey)
end

local queued
local function QueueCapture()
    if queued then return end
    queued = true
    C_Timer.After(CAPTURE_DEBOUNCE, function()
        queued = nil
        RoutineData:CaptureGold()
    end)
end

RoutineData:OnLogin(function()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_MONEY")
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" then
            C_Timer.After(LOGIN_DELAY, function() RoutineData:CaptureGold() end)
        else
            QueueCapture()
        end
    end)
end)
