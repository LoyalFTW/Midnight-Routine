local _, ns = ...

local function SetColor(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

function ns.ScrollByDelta(scroll, content, delta, step, onUpdate)
    if not scroll or not content then
        return
    end

    local maxScroll = math.max((content:GetHeight() or 0) - (scroll:GetHeight() or 0), 0)
    local nextScroll = (scroll:GetVerticalScroll() or 0) - (delta * (step or 30))
    scroll:SetVerticalScroll(math.max(0, math.min(nextScroll, maxScroll)))
    if onUpdate then onUpdate() end
end

function ns.AttachScrollList(scroll, content, track, opts)
    opts = opts or {}
    scroll:EnableMouseWheel(true)
    scroll:SetScrollChild(content)

    local trackBg = track:CreateTexture(nil, "BACKGROUND")
    trackBg:SetAllPoints()
    SetColor(trackBg, opts.trackColor or { 0, 0, 0, 0.3 })

    local thumb = CreateFrame("Button", nil, track)
    thumb:SetPoint("LEFT", track, "LEFT", 0, 0)
    thumb:SetPoint("RIGHT", track, "RIGHT", 0, 0)
    thumb:EnableMouse(true)
    thumb:RegisterForClicks("LeftButtonDown", "LeftButtonUp")

    local thumbTex = thumb:CreateTexture(nil, "OVERLAY")
    thumbTex:SetAllPoints()
    SetColor(thumbTex, opts.thumbColor or { 0.20, 0.66, 0.63, 0.7 })

    local function GetContentHeight()
        return content:GetHeight() or 0
    end

    local lastNotifiedScroll
    local function UpdateScrollBar()
        if not scroll:IsShown() then
            track:Hide()
            thumb:Hide()
            return
        end

        local viewHeight = scroll:GetHeight()
        local contentHeight = GetContentHeight()
        local maxScroll = math.max(contentHeight - viewHeight, 0)
        local currentScroll = math.max(0, math.min(scroll:GetVerticalScroll(), maxScroll))
        if currentScroll ~= scroll:GetVerticalScroll() then
            scroll:SetVerticalScroll(currentScroll)
        end

        if opts.showTrack == false then
            track:Hide()
            thumb:Hide()
            return
        elseif maxScroll <= 0 or viewHeight <= 0 then
            scroll:SetVerticalScroll(0)
            thumb:Hide()
            if opts.hideTrack then track:Hide() end
            return
        end

        track:Show()
        thumb:Show()
        local trackHeight = math.max(track:GetHeight(), 1)
        local thumbHeight = math.max(trackHeight * (viewHeight / contentHeight), opts.minThumbHeight or 14)
        local percent = currentScroll / math.max(maxScroll, 1)
        thumb:SetHeight(thumbHeight)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, -((trackHeight - thumbHeight) * percent))
        thumb:SetPoint("RIGHT", track, "RIGHT", 0, 0)

        if opts.onScroll and currentScroll ~= lastNotifiedScroll then
            lastNotifiedScroll = currentScroll
            opts.onScroll(currentScroll, viewHeight)
        end
    end

    local function SetScrollFromCursor(cursorY, grabOffset)
        local maxScroll = math.max(GetContentHeight() - scroll:GetHeight(), 0)
        if maxScroll <= 0 then
            scroll:SetVerticalScroll(0)
            UpdateScrollBar()
            return
        end

        local trackTop, trackBottom = track:GetTop(), track:GetBottom()
        if not trackTop or not trackBottom then return end

        local trackHeight = math.max(trackTop - trackBottom, 1)
        local thumbHeight = thumb:GetHeight()
        local movable = math.max(trackHeight - thumbHeight, 1)
        local offset = grabOffset or (thumbHeight * 0.5)
        local y = math.max(0, math.min((trackTop - cursorY) - offset, movable))
        scroll:SetVerticalScroll(maxScroll * (y / movable))
        UpdateScrollBar()
    end

    local function StartDragging(button, grabOffset)
        button._grabOffset = grabOffset
        button:SetScript("OnUpdate", function(self)
            if not IsMouseButtonDown("LeftButton") then
                self._grabOffset = nil
                self:SetScript("OnUpdate", nil)
                return
            end

            local _, cursorY = GetCursorPosition()
            SetScrollFromCursor(cursorY / UIParent:GetEffectiveScale(), self._grabOffset)
        end)
    end

    track:SetScript("OnMouseDown", function(_, mouseButton)
        if mouseButton ~= "LeftButton" or not thumb:IsShown() then return end
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / UIParent:GetEffectiveScale()
        local grabOffset = thumb:GetHeight() * 0.5
        SetScrollFromCursor(cursorY, grabOffset)
        StartDragging(thumb, grabOffset)
    end)

    thumb:SetScript("OnMouseDown", function(self, mouseButton)
        if mouseButton ~= "LeftButton" or not self:IsShown() then return end
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / UIParent:GetEffectiveScale()
        local thumbTop = self:GetTop()
        StartDragging(self, thumbTop and (thumbTop - cursorY) or (self:GetHeight() * 0.5))
    end)
    thumb:SetScript("OnMouseUp", function(self)
        self._grabOffset = nil
        self:SetScript("OnUpdate", nil)
    end)

    scroll:SetScript("OnMouseWheel", function(_, delta)
        local addon = ns.MR
        local started = addon and addon._scrollProfileArmed and scroll == addon.scroll and debugprofilestop and debugprofilestop() or nil
        ns.ScrollByDelta(scroll, content, delta, opts.wheelStep, UpdateScrollBar)
        if started and addon.CaptureScrollProfile then
            addon:CaptureScrollProfile("wheel dispatch", debugprofilestop() - started, "delta=" .. tostring(delta))
        end
    end)
    scroll:SetScript("OnSizeChanged", UpdateScrollBar)
    scroll:SetScript("OnScrollRangeChanged", UpdateScrollBar)
    scroll:SetScript("OnVerticalScroll", UpdateScrollBar)
    scroll:HookScript("OnShow", UpdateScrollBar)
    scroll:HookScript("OnHide", function()
        track:Hide()
        thumb:Hide()
    end)
    UpdateScrollBar()

    return UpdateScrollBar, thumb, trackBg, thumbTex
end

function ns.CreateScrollArea(parent, topLeftAnchor, bottomRightAnchor, opts)
    opts = opts or {}
    local scroll = CreateFrame("ScrollFrame", nil, parent)
    scroll:SetPoint(topLeftAnchor[1], topLeftAnchor[2], topLeftAnchor[3], topLeftAnchor[4], topLeftAnchor[5])
    scroll:SetPoint(bottomRightAnchor[1], bottomRightAnchor[2], bottomRightAnchor[3], bottomRightAnchor[4], bottomRightAnchor[5])

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(opts.contentWidth or 1, opts.contentHeight or 1)

    local track = CreateFrame("Frame", nil, parent)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", opts.trackOffset or 3, 0)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", opts.trackOffset or 3, 0)
    track:SetWidth(opts.trackWidth or 5)

    local update = ns.AttachScrollList(scroll, content, track, opts)
    return scroll, content, update, track
end
