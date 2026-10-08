local addonName, ns = ...
local MR = ns.MR
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)
local Tracker = ns.Tracking.API

MR.tracker = Tracker

function MR:ReportTrackingFailure(source, err)
    print(string.format(
        L["Scan_Failed"] or "|cff2ae7c6MidnightRoutine:|r Scan step '%s' failed and was skipped: %s",
        tostring(source), tostring(err)))
end

function MR:OnTrackingWeeklyReset()
    print(L["Weekly_Reset"] or "|cff2ae7c6MidnightRoutine:|r Weekly reset applied.")
end

function MR:OnTrackerLabelsChanged()
    local hasVisibleMain = MR.frame and MR.frame.IsShown and MR.frame:IsShown()
    local hasVisibleDetached = false
    if MR.detachedFrames then
        for _, frame in pairs(MR.detachedFrames) do
            if frame and frame.IsShown and frame:IsShown() then
                hasVisibleDetached = true
                break
            end
        end
    end

    if hasVisibleMain or hasVisibleDetached then
        if MR.RequestUIRefresh then
            MR:RequestUIRefresh(0.02)
        elseif MR.RefreshUI then
            MR:RefreshUI()
        end
    else
        MR._refreshUIDirty = true
        MR._mainPanelNeedsRefresh = true
    end

    if MR.RequestProfessionKnowledgeSurfaceRefresh then
        MR:RequestProfessionKnowledgeSurfaceRefresh(0.02)
    elseif MR.RequestGatheringLocationsRefresh then
        MR.RequestGatheringLocationsRefresh()
    elseif MR.RefreshProfessionKnowledgeSurfaces then
        MR:RefreshProfessionKnowledgeSurfaces()
    end
end

Tracker:InstallComponent("Progress", MR, { namespace = ns })
