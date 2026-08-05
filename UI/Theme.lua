local _, ns = ...
local LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
ns.MEDIA_DEFAULT_TOKEN = "__MIDNIGHT_DEFAULT__"

local MEDIA_KIND_TO_LSM = {
    font = LSM and LSM.MediaType.FONT or "font",
    background = LSM and LSM.MediaType.BACKGROUND or "background",
}

local DEFAULT_FONT_FLAGS = "OUTLINE"
local GetActiveMediaProfile
local GetResolvedMediaSetting
local ResolveSelectedFontPath

local function NormalizeFontFlags(flags)
    if flags == nil then
        return nil
    end

    if flags == false then
        return ""
    end

    if type(flags) ~= "string" then
        return DEFAULT_FONT_FLAGS
    end

    local normalized = flags:upper():gsub("%s+", "")
    if normalized == "" or normalized == "NONE" then
        return ""
    end

    local tokens = {}
    for token in normalized:gmatch("[^,]+") do
        tokens[token] = true
    end

    local hasMono = tokens.MONOCHROME and true or false
    local hasThick = tokens.THICKOUTLINE and true or false
    local hasOutline = hasThick or tokens.OUTLINE

    if hasThick then
        return hasMono and "THICKOUTLINE, MONOCHROME" or "THICKOUTLINE"
    end

    if hasOutline then
        return hasMono and "OUTLINE, MONOCHROME" or "OUTLINE"
    end

    if hasMono then
        return "MONOCHROME"
    end

    return DEFAULT_FONT_FLAGS
end

ns.NormalizeFontFlags = NormalizeFontFlags

function ns.GetFontFlags(profile)
    profile = profile or GetActiveMediaProfile()

    local flags = (profile and profile.fontFlags) or GetResolvedMediaSetting("fontFlags")
    flags = NormalizeFontFlags(flags)
    if flags == nil then
        return DEFAULT_FONT_FLAGS
    end

    return flags
end

local SCRIPT_FONTS = {
    koKR = "Fonts\\2002.TTF",
    zhCN = "Fonts\\ARKai_T.ttf",
    zhTW = "Fonts\\blei00d.ttf",
    ruRU = "Fonts\\FRIZQT___CYR.TTF",
}

local SCRIPT_RANGES = {
    { 0x0400, 0x04FF, "ruRU" },
    { 0x1100, 0x11FF, "koKR" },
    { 0x3130, 0x318F, "koKR" },
    { 0x3400, 0x4DBF, nil      },
    { 0x4E00, 0x9FFF, nil      },
    { 0xAC00, 0xD7AF, "koKR" },
    { 0xF900, 0xFAFF, nil      },
}

local UTF8 = _G.utf8

local function DetectScriptFont(text)
    if type(text) ~= "string" or text == "" then
        return nil
    end

    if not UTF8 or not UTF8.codes then
        if text:find("[\128-\255]") then
            local loc = GetLocale and GetLocale() or ""
            return SCRIPT_FONTS[loc] or SCRIPT_FONTS.zhCN
        end
        return nil
    end

    local locale = GetLocale and GetLocale() or ""
    for _, cp in UTF8.codes(text) do
        for _, r in ipairs(SCRIPT_RANGES) do
            if cp >= r[1] and cp <= r[2] then
                if r[3] then
                    return SCRIPT_FONTS[r[3]]
                end

                return (locale == "zhTW") and SCRIPT_FONTS.zhTW or SCRIPT_FONTS.zhCN
            end
        end
    end

    return nil
end

local function ResolveDefaultFont()
    if type(STANDARD_TEXT_FONT) == "string" and STANDARD_TEXT_FONT ~= "" then
        return STANDARD_TEXT_FONT
    end
    if GameFontNormal and GameFontNormal.GetFont then
        local font = GameFontNormal:GetFont()
        if type(font) == "string" and font ~= "" then
            return font
        end
    end
    local locale = GetLocale and GetLocale() or ""
    return SCRIPT_FONTS[locale] or "Fonts\\FRIZQT__.TTF"
end

function ns.GetDefaultFontTexture()
    return ResolveDefaultFont()
end

local function ResolveDefaultBackground()
    return "Interface\\Buttons\\WHITE8X8"
end

function ns.GetDefaultBackgroundTexture()
    return ResolveDefaultBackground()
end

local function FetchSharedMedia(kind, name, fallback)
    if not LSM or type(name) ~= "string" or name == "" then
        return fallback
    end

    local mediaType = MEDIA_KIND_TO_LSM[kind]
    local path = mediaType and LSM:Fetch(mediaType, name, true)
    if type(path) == "string" then
        return path
    end

    return fallback
end

local function ResolveMediaPath(kind, name, explicitPath, fallback)
    if name == ns.MEDIA_DEFAULT_TOKEN then
        return fallback
    end

    if type(explicitPath) == "string" and explicitPath ~= "" then
        return explicitPath
    end

    return FetchSharedMedia(kind, name, fallback)
end

local function HasCustomBackground(profile)
    return type(profile) == "table"
        and type(profile.backgroundMedia) == "string"
        and profile.backgroundMedia ~= ""
        and profile.backgroundMedia ~= ns.MEDIA_DEFAULT_TOKEN
end

function ns.GetSharedMedia()
    return LSM
end

function ns.GetSharedMediaList(kind)
    if not LSM then
        return {}
    end

    local mediaType = MEDIA_KIND_TO_LSM[kind]
    if not mediaType then
        return {}
    end

    return LSM:List(mediaType) or {}
end

GetActiveMediaProfile = function()
    local addon = ns.MR
    if addon and addon.GetActiveMediaSettings then
        return addon:GetActiveMediaSettings()
    end

    return (addon and addon.db and addon.db.profile) or {}
end

GetResolvedMediaSetting = function(key)
    local addon = ns.MR
    if addon and addon.GetMediaSetting then
        return addon:GetMediaSetting(key)
    end

    local profile = GetActiveMediaProfile()
    return profile and profile[key]
end

ResolveSelectedFontPath = function(profile)
    profile = profile or GetActiveMediaProfile()

    local defaultFont = ResolveDefaultFont()
    local sharedFont = (profile and profile.fontMedia) or GetResolvedMediaSetting("fontMedia")
        or (profile and profile.rowFontMedia) or GetResolvedMediaSetting("rowFontMedia")
        or (profile and profile.headerFontMedia) or GetResolvedMediaSetting("headerFontMedia")
    local fontPath = (profile and profile.fontMediaPath) or GetResolvedMediaSetting("fontMediaPath")

    local resolved = ResolveMediaPath("font", sharedFont, fontPath, defaultFont)
    if type(resolved) ~= "string" or resolved == "" then
        return defaultFont
    end

    return resolved
end

function ns.ResolveFontForText(text, preferredFont, profile)
    local baseFont = preferredFont
    if type(baseFont) ~= "string" or baseFont == "" then
        baseFont = ResolveSelectedFontPath(profile)
    end

    local scriptFont = DetectScriptFont(text)
    if not scriptFont then
        return baseFont
    end

    local defaultFont = ResolveDefaultFont()
    if baseFont == defaultFont then
        return scriptFont
    end

    return baseFont
end

function ns.ScriptFontForText(text)
    local baseFont = ResolveSelectedFontPath()
    local resolved = ns.ResolveFontForText(text, baseFont)
    if resolved ~= baseFont then
        return resolved
    end

    return nil
end

function ns.ApplySharedMedia(profile)
    profile = profile or GetActiveMediaProfile()

    local defaultBackground = ResolveDefaultBackground()
    local backgroundMedia = (profile and profile.backgroundMedia) or GetResolvedMediaSetting("backgroundMedia")
    local backgroundPath = (profile and profile.backgroundMediaPath) or GetResolvedMediaSetting("backgroundMediaPath")

    ns.FONT_HEADERS = ResolveSelectedFontPath(profile)
    ns.FONT_ROWS = ns.FONT_HEADERS
    ns.BACKDROP_FILE = ResolveMediaPath("background", backgroundMedia, backgroundPath, defaultBackground)

    return ns.FONT_HEADERS, ns.FONT_ROWS, ns.BACKDROP_FILE
end

function ns.EnsureFonts()
    local profile = GetActiveMediaProfile()
    local defaultFont = ResolveDefaultFont()

    ns.FONT_HEADERS = ResolveSelectedFontPath(profile)
    ns.FONT_ROWS = ns.FONT_HEADERS

    if type(ns.FONT_HEADERS) ~= "string" or ns.FONT_HEADERS == "" then
        ns.FONT_HEADERS = defaultFont
    end

    if type(ns.FONT_ROWS) ~= "string" or ns.FONT_ROWS == "" then
        ns.FONT_ROWS = defaultFont
    end

    return ns.FONT_HEADERS, ns.FONT_ROWS
end

ns.EnsureFonts()
if type(ns.BACKDROP_FILE) ~= "string" then
    ns.BACKDROP_FILE = ResolveDefaultBackground()
end

function ns.ApplyBackgroundTexture(texture, r, g, b, a)
    if not texture then
        return
    end

    local bgFile = ns.BACKDROP_FILE
    if type(bgFile) == "string" and bgFile ~= "" then
        texture:SetTexture(bgFile)
        local profile = GetActiveMediaProfile()
        if HasCustomBackground(profile) then
            texture:SetVertexColor(1, 1, 1, a or 1)
        else
            texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
        end
        return
    end

    texture:SetTexture(nil)
end

local backdropFrames = setmetatable({}, { __mode = "k" })

function ns.RefreshFrameBackground(frame)
    if not frame then
        return
    end

    local color = frame._mrBackgroundColor
    if not color then
        return
    end

    if type(frame.GetBackdrop) == "function" and type(frame.SetBackdrop) == "function" then
        local backdrop = frame:GetBackdrop()
        if type(backdrop) == "table" then
            local bgFile = ns.BACKDROP_FILE or ResolveDefaultBackground()
            if frame._mrAppliedBackdropFile ~= bgFile then
                backdrop.bgFile = bgFile
                frame._mrRefreshingBackground = true
                frame:SetBackdrop(backdrop)
                frame._mrAppliedBackdropFile = bgFile
                if type(frame._mrOriginalSetBackdropColor) == "function" then
                    local profile = GetActiveMediaProfile()
                    if HasCustomBackground(profile) then
                        frame._mrOriginalSetBackdropColor(frame, 1, 1, 1, color[4] or 1)
                    else
                        frame._mrOriginalSetBackdropColor(frame, color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1)
                    end
                end
                if type(frame._mrOriginalSetBackdropBorderColor) == "function" and frame._mrBorderColor then
                    local border = frame._mrBorderColor
                    frame._mrOriginalSetBackdropBorderColor(frame, border[1] or 1, border[2] or 1, border[3] or 1, border[4] or 1)
                end
                frame._mrRefreshingBackground = nil
            end
        end
    end

end

function ns.RefreshAllFrameBackgrounds()
    for frame in pairs(backdropFrames) do
        if frame and frame.GetParent and frame:GetParent() ~= nil then
            ns.RefreshFrameBackground(frame)
        else
            backdropFrames[frame] = nil
        end
    end
end

local function HookFrameBackdrop(frame)
    if not frame or frame._mrBackdropHooked or type(frame.SetBackdropColor) ~= "function" then
        if frame and frame._mrBackdropHooked then
            backdropFrames[frame] = true
        end
        return
    end

    frame._mrBackdropHooked = true
    backdropFrames[frame] = true
    local originalSetBackdropColor = frame.SetBackdropColor
    local originalSetBackdropBorderColor = frame.SetBackdropBorderColor
    frame._mrOriginalSetBackdropColor = originalSetBackdropColor
    frame._mrOriginalSetBackdropBorderColor = originalSetBackdropBorderColor
    frame.SetBackdropColor = function(self, r, g, b, a)
        if self._mrRefreshingBackground then
            originalSetBackdropColor(self, r, g, b, a)
            return
        end

        local profile = GetActiveMediaProfile()
        if HasCustomBackground(profile) then
            originalSetBackdropColor(self, 1, 1, 1, a)
        else
            originalSetBackdropColor(self, r, g, b, a)
        end
        self._mrBackgroundColor = { r or 1, g or 1, b or 1, a or 1 }
        ns.RefreshFrameBackground(self)
    end
    if type(originalSetBackdropBorderColor) == "function" then
        frame.SetBackdropBorderColor = function(self, r, g, b, a)
            self._mrBorderColor = { r or 1, g or 1, b or 1, a or 1 }
            originalSetBackdropBorderColor(self, r, g, b, a)
        end
    end
end

function ns.HookBackdropFrame(frame)
    HookFrameBackdrop(frame)
    if frame and frame._mrBackgroundColor then
        ns.RefreshFrameBackground(frame)
    end
end

ns.COLORS = {
    complete = { 0, 1, 0.59 },
    half = { 1, 0.47, 0 },
    incomplete = { 0.6, 0.6, 0.6 },
    bg = { 0.02, 0.03, 0.07, 0.96 },
    accent = { 0.85, 0.65, 0.10 },
    border = { 0.15, 0.15, 0.20 },
    titlebar = { 0.05, 0.12, 0.22 },
}

local COLORS = ns.COLORS

function ns.Hex(h)
    h = h:gsub("#", "")
    return tonumber(h:sub(1, 2), 16) / 255,
        tonumber(h:sub(3, 4), 16) / 255,
        tonumber(h:sub(5, 6), 16) / 255
end

function ns.WrapColor(rrggbb, text)
    return string.format("|cff%s%s|r", rrggbb, text)
end

function ns.CountColor(done, max)
    if max == nil or max <= 0 then
        if done > 0 then
            return COLORS.half[1], COLORS.half[2], COLORS.half[3]
        end
        return COLORS.incomplete[1], COLORS.incomplete[2], COLORS.incomplete[3]
    end
    if done >= max then
        return COLORS.complete[1], COLORS.complete[2], COLORS.complete[3]
    elseif done > 0 then
        return COLORS.half[1], COLORS.half[2], COLORS.half[3]
    end

    return COLORS.incomplete[1], COLORS.incomplete[2], COLORS.incomplete[3]
end

function ns.SetDotColor(tex, done, max)
    if max == nil or max <= 0 then
        if done > 0 then
            tex:SetColorTexture(COLORS.half[1], COLORS.half[2], COLORS.half[3], 1)
        else
            tex:SetColorTexture(COLORS.incomplete[1], COLORS.incomplete[2], COLORS.incomplete[3], 1)
        end
        return
    end
    if done >= max then
        tex:SetColorTexture(COLORS.complete[1], COLORS.complete[2], COLORS.complete[3], 1)
    elseif done > 0 then
        tex:SetColorTexture(COLORS.half[1], COLORS.half[2], COLORS.half[3], 1)
    else
        tex:SetColorTexture(0.3, 0.3, 0.3, 1)
    end
end

ns.LOCALE_SETTINGS = ns.LOCALE_SETTINGS or {
    zhCN = { fontSizeMin = 13, fontSizeDefault = 13 },
    zhTW = { fontSizeMin = 13, fontSizeDefault = 13 },
    koKR = { fontSizeMin = 13, fontSizeDefault = 13 },
}

local localeSettings = (ns.LOCALE_SETTINGS or {})[GetLocale()] or {}
local fontSizeMin = localeSettings.fontSizeMin or 7
local fontSizeDefault = localeSettings.fontSizeDefault or 11

function ns.GetFontSize()
    local addon = ns.MR
    local size

    if addon and addon.db and addon.db.profile and addon.db.profile.fontSize then
        size = addon.db.profile.fontSize
    else
        size = fontSizeDefault
    end

    if size < fontSizeMin then
        size = fontSizeMin
    end

    return size
end

function ns.MakeBackdrop(edge)
    local backdrop = {}

    if type(ns.BACKDROP_FILE) == "string" and ns.BACKDROP_FILE ~= "" then
        backdrop.bgFile = ns.BACKDROP_FILE
    end

    if edge == false then
        return backdrop
    end

    backdrop.edgeFile = ResolveDefaultBackground()
    backdrop.edgeSize = 1
    return backdrop
end

function ns.StyledFrame(parent, name, strata, level)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    frame:SetFrameStrata(strata or "MEDIUM")
    frame:SetFrameLevel(level or 10)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetBackdrop(ns.MakeBackdrop())
    HookFrameBackdrop(frame)
    frame:SetBackdropColor(COLORS.bg[1], COLORS.bg[2], COLORS.bg[3], COLORS.bg[4])
    frame:SetBackdropBorderColor(COLORS.border[1], COLORS.border[2], COLORS.border[3], 1)
    return frame
end

function ns.TopAccent(parent, r, g, b)
    r, g, b = r or COLORS.accent[1], g or COLORS.accent[2], b or COLORS.accent[3]
    local tex = parent:CreateTexture(nil, "BORDER")
    tex:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    tex:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    tex:SetHeight(2)
    tex:SetColorTexture(r, g, b, 1)
    return tex
end

function ns.LeftAccent(parent, r, g, b)
    r, g, b = r or COLORS.accent[1], g or COLORS.accent[2], b or COLORS.accent[3]

    local group = CreateFrame("Frame", nil, parent)
    group:SetAllPoints(parent)

    local topRule = group:CreateTexture(nil, "BORDER")
    topRule:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, 0)
    topRule:SetWidth(44)
    topRule:SetHeight(2)
    topRule:SetColorTexture(r, g, b, 0.95)
    group.topRule = topRule

    local notch = group:CreateTexture(nil, "BORDER")
    notch:SetPoint("TOPLEFT", topRule, "BOTTOMRIGHT", 4, 0)
    notch:SetWidth(10)
    notch:SetHeight(2)
    notch:SetColorTexture(r, g, b, 0.65)
    group.notch = notch

    local glow = group:CreateTexture(nil, "ARTWORK")
    glow:SetPoint("TOPLEFT", topRule, "BOTTOMLEFT", 0, -2)
    glow:SetWidth(58)
    glow:SetHeight(8)
    glow:SetColorTexture(r, g, b, 0.14)
    group.glow = glow

    return group
end

function ns.SaveFramePos(frame, key)
    local addon = ns.MR
    if not addon or not addon.db then
        return
    end

    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, relPoint, x, y = frame:GetPoint()
        addon.db.profile[key] = { point = point, relPoint = relPoint, x = x, y = y }
    end)
end

function ns.GetManagedHeaderPosition()
    local addon = ns.MR
    if addon and addon.GetManagedHeaderPosition then
        return addon:GetManagedHeaderPosition()
    end

    return "top"
end

function ns.IsManagedHeaderBottom()
    return ns.GetManagedHeaderPosition() == "bottom"
end

function ns.IsManagedAnimatedMinimizeEnabled()
    local addon = ns.MR
    return addon and addon.IsManagedAnimatedMinimizeEnabled and addon:IsManagedAnimatedMinimizeEnabled() == true
end

function ns.CaptureManagedFrameAnchor(frame, anchorMode, fallback)
    if not frame then
        return fallback
    end

    local left, top, bottom = frame:GetLeft(), frame:GetTop(), frame:GetBottom()
    if anchorMode == "bottom" and left and bottom then
        return { point = "BOTTOMLEFT", relPoint = "BOTTOMLEFT", x = left, y = bottom }
    end

    if left and top then
        return { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = left, y = top }
    end

    if fallback and fallback.point then
        return {
            point = fallback.point,
            relPoint = fallback.relPoint or fallback.point,
            x = fallback.x or 0,
            y = fallback.y or 0,
        }
    end

    local point, _, relPoint, x, y = frame:GetPoint()
    if point then
        return { point = point, relPoint = relPoint or point, x = x or 0, y = y or 0 }
    end

    return nil
end

function ns.ApplyManagedFrameAnchor(frame, pos)
    if not (frame and pos and pos.point) then
        return false
    end

    frame:ClearAllPoints()
    frame:SetPoint(pos.point, UIParent, pos.relPoint or pos.point, pos.x or 0, pos.y or 0)
    return true
end

function ns.RestoreManagedFramePos(frame, key, defaultX, defaultY, fallbackPos)
    local addon = ns.MR
    local pos
    if addon and addon.GetWindowLayoutValue and key then
        pos = addon:GetWindowLayoutValue(key)
    elseif addon and addon.db and addon.db.profile and key then
        pos = addon.db.profile[key]
    end

    pos = pos or fallbackPos
    if pos and pos.point then
        ns.ApplyManagedFrameAnchor(frame, pos)
        return pos
    end

    local defaultPos = {
        point = "CENTER",
        relPoint = "CENTER",
        x = defaultX or 0,
        y = defaultY or 0,
    }
    ns.ApplyManagedFrameAnchor(frame, defaultPos)
    return defaultPos
end

function ns.SaveManagedFramePos(frame, key, anchorMode, fallbackPos)
    local addon = ns.MR
    if not (addon and addon.SetWindowLayoutValue and key) then
        return nil
    end

    local pos = ns.CaptureManagedFrameAnchor(frame, anchorMode, fallbackPos)
    if pos then
        addon:SetWindowLayoutValue(key, pos)
    end
    return pos
end

function ns.SyncManagedFramePos(frame, key, anchorMode, fallbackPos)
    local pos = ns.SaveManagedFramePos(frame, key, anchorMode, fallbackPos)
    if pos then
        ns.ApplyManagedFrameAnchor(frame, pos)
    end
    return pos
end

function ns.AnimateManagedFrameHeight(frame, targetHeight, onFinished, onUpdate, driverFrame)
    if not frame then
        return
    end

    local driver = driverFrame or frame
    if not ns.IsManagedAnimatedMinimizeEnabled() then
        frame:SetHeight(targetHeight)
        if onFinished then onFinished(frame) end
        return
    end

    local startHeight = frame:GetHeight() or targetHeight
    local delta = targetHeight - startHeight
    if math.abs(delta) < 1 then
        frame:SetHeight(targetHeight)
        if onFinished then onFinished(frame) end
        return
    end

    driver._mrAnimTick = 0
    driver:SetScript("OnUpdate", function(self, dt)
        if onUpdate then
            onUpdate(frame, dt)
        end

        self._mrAnimTick = (self._mrAnimTick or 0) + (dt or 0)
        local duration = math.min(0.18, math.max(0.06, math.abs(delta) / 1600))
        local progress = math.min(self._mrAnimTick / duration, 1)
        local eased = 1 - ((1 - progress) * (1 - progress) * (1 - progress))
        frame:SetHeight(startHeight + (delta * eased))
        if progress >= 1 then
            frame:SetHeight(targetHeight)
            self._mrAnimTick = nil
            if onFinished then
                onFinished(frame)
            else
                self:SetScript("OnUpdate", nil)
            end
        end
    end)
end

function ns.RestoreFramePos(frame, key, defaultX, defaultY)
    ns.RestoreManagedFramePos(frame, key, defaultX, defaultY)
end

function ns.OptionsGap(body, yOff, height)
    return yOff - (height or 4)
end

function ns.OptionsDivider(body, yOff, pad)
    pad = pad or 8
    local frame = CreateFrame("Frame", nil, body, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    frame:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
    frame:SetHeight(1)
    frame:SetBackdrop(ns.MakeBackdrop(false))
    frame:SetBackdropColor(1, 1, 1, 0.07)
    return yOff - 4
end

function ns.OptionsSectionLabel(body, yOff, text, pad, fontSize)
    pad = pad or 8
    local fs = body:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ns.FONT_ROWS, fontSize or 9, ns.GetFontFlags())
    fs:SetText("|cff888888" .. text .. "|r")
    fs:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    fs:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return yOff - 12
end

function ns.OptionsCheckbox(body, yOff, label, getVal, setVal, r, g, b, pad, onRefresh, fontSize)
    pad = pad or 8
    local frame = CreateFrame("CheckButton", nil, body, "UICheckButtonTemplate")
    frame:SetSize(20, 20)
    frame:SetPoint("TOPLEFT", body, "TOPLEFT", pad - 2, yOff)
    frame:SetChecked(getVal())
    frame:EnableMouse(true)
    frame:SetScript("OnClick", function(self)
        setVal(self:GetChecked())
        if onRefresh then
            onRefresh()
        end
    end)

    local lbl = frame:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(ns.FONT_ROWS, fontSize or 10, ns.GetFontFlags())
    lbl:SetText(label)
    lbl:SetTextColor(r or 0.88, g or 0.88, b or 0.88)
    lbl:SetPoint("LEFT", frame, "RIGHT", 2, 0)
    lbl:SetPoint("RIGHT", body, "RIGHT", -pad, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetWordWrap(false)
    return yOff - 19
end

function ns.OptionsBtn(body, yOff, label, onClick, width, pad, fontSize)
    pad = pad or 8
    width = width or 184

    local btn = CreateFrame("Button", nil, body, "BackdropTemplate")
    btn:SetSize(width, 20)
    btn:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    btn:SetBackdrop(ns.MakeBackdrop())
    btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
    btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)

    local fs = btn:CreateFontString(nil, "OVERLAY")
    fs:SetFont(ns.FONT_ROWS, fontSize or 10, ns.GetFontFlags())
    fs:SetPoint("LEFT", btn, "LEFT", 6, 0)
    fs:SetWidth(width - 12)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    fs:SetText(label)
    fs:SetTextColor(0.70, 0.88, 0.85)

    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.08, 0.22, 0.32, 1)
        btn:SetBackdropBorderColor(0.25, 0.85, 0.72, 1)
        fs:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.05, 0.10, 0.18, 1)
        btn:SetBackdropBorderColor(0.18, 0.40, 0.45, 1)
        fs:SetTextColor(0.70, 0.88, 0.85)
    end)

    return yOff - 22
end

function ns.OptionsSlider(body, yOff, label, min, max, step, getVal, setVal, fillR, fillG, fillB, pad, disabled, fontSize)
    pad = pad or 8
    if disabled then
        fillR, fillG, fillB = 0.30, 0.30, 0.30
    else
        fillR = fillR or 0.85
        fillG = fillG or 0.65
        fillB = fillB or 0.10
    end

    local lbl = body:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(ns.FONT_ROWS, fontSize or 9, ns.GetFontFlags())
    lbl:SetText("|cff" .. (disabled and "555555" or "888888") .. label .. "|r")
    lbl:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    lbl:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
    lbl:SetJustifyH("LEFT")
    lbl:SetWordWrap(false)

    local labelGap = math.max(14, (fontSize or 9) + 4)
    yOff = yOff - labelGap

    local bodyWidth = body:GetWidth()
    if not bodyWidth or bodyWidth <= 0 then
        local parent = body.GetParent and body:GetParent() or nil
        bodyWidth = parent and parent:GetWidth() or 220
    end

    local valueBoxW = 44
    local sliderW = math.max(96, bodyWidth - (pad * 2) - valueBoxW - 4)

    local bg = CreateFrame("Frame", nil, body, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    bg:SetSize(sliderW, 14)
    bg:SetBackdrop(ns.MakeBackdrop())
    bg:SetBackdropColor(0, 0, 0, disabled and 0.25 or 0.5)
    bg:SetBackdropBorderColor(0.25, 0.25, 0.3, disabled and 0.4 or 1)

    local fill = bg:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("LEFT", bg, "LEFT", 2, 0)
    fill:SetHeight(10)
    fill:SetColorTexture(fillR, fillG, fillB, disabled and 0.4 or 0.85)

    local valBox = CreateFrame("Frame", nil, body, "BackdropTemplate")
    valBox:SetPoint("LEFT", bg, "RIGHT", 4, 0)
    valBox:SetSize(valueBoxW, 14)
    valBox:SetBackdrop(ns.MakeBackdrop())
    valBox:SetBackdropColor(0, 0, 0, disabled and 0.25 or 0.5)
    valBox:SetBackdropBorderColor(0.25, 0.25, 0.3, disabled and 0.4 or 1)

    local valTxt = valBox:CreateFontString(nil, "OVERLAY")
    valTxt:SetFont(ns.FONT_ROWS, fontSize or 9, ns.GetFontFlags())
    valTxt:SetPoint("CENTER", valBox, "CENTER", 0, 0)
    valTxt:SetTextColor(disabled and 0.4 or 1, disabled and 0.4 or 1, disabled and 0.4 or 1)

    local function UpdateVis(value)
        local pct = (value - min) / (max - min)
        fill:SetWidth(math.max(2, (bg:GetWidth() - 4) * pct))
        valTxt:SetText(string.format("%.2f", value):gsub("%.?0+$", ""))
    end

    local slider = CreateFrame("Slider", nil, bg)
    slider:SetAllPoints(bg)
    slider:SetMinMaxValues(min, max)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:Hide()
    end

    slider:SetValue(getVal())
    UpdateVis(getVal())

    if disabled then
        slider:EnableMouse(false)
    else
        slider:SetScript("OnValueChanged", function(self, value)
            UpdateVis(value)
        end)
        slider:SetScript("OnMouseUp", function(self)
            setVal(self:GetValue())
        end)
    end

    return yOff - 16
end

function ns.OptionsColorSwatch(parent, r, g, b, onPick, onReset, tooltip)
    local swatch = CreateFrame("Button", nil, parent, "BackdropTemplate")
    swatch:SetSize(16, 16)
    swatch:SetBackdrop({
        bgFile = ResolveDefaultBackground(),
        edgeFile = ResolveDefaultBackground(),
        edgeSize = 1,
    })
    swatch:SetBackdropColor(0.02, 0.02, 0.02, 1)
    swatch:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local fill = swatch:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", swatch, "TOPLEFT", 2, -2)
    fill:SetPoint("BOTTOMRIGHT", swatch, "BOTTOMRIGHT", -2, 2)
    fill:SetColorTexture(r, g, b, 1)
    swatch._fill = fill

    local function UpdateFill()
        if swatch._fill then
            swatch._fill:SetColorTexture(r, g, b, 1)
        end
    end

    swatch:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b,
                hasOpacity = false,
                swatchFunc = function()
                    local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                    r, g, b = nr, ng, nb
                    UpdateFill()
                    if onPick then
                        onPick(r, g, b)
                    end
                end,
                cancelFunc = function(prev)
                    r, g, b = prev.r, prev.g, prev.b
                    UpdateFill()
                    if onPick then
                        onPick(r, g, b)
                    end
                end,
            })
        elseif button == "RightButton" and onReset then
            r, g, b = onReset()
            UpdateFill()
        end
    end)
    swatch:SetScript("OnEnter", function()
        swatch:SetBackdropBorderColor(0.9, 0.9, 0.9, 1)
        ns.ShowTooltip(swatch, {
            build = function(activeTooltip)
                activeTooltip:SetText(tooltip or "Color", 1, 1, 1)
                activeTooltip:AddLine("Left-click: Pick color", 0.5, 0.5, 0.5)
                if onReset then
                    activeTooltip:AddLine("Right-click: Reset", 0.5, 0.5, 0.5)
                end
            end,
        })
    end)
    swatch:SetScript("OnLeave", function()
        swatch:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        ns.HideTooltip(swatch)
    end)
    return swatch
end
