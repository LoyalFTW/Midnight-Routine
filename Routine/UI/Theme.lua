local _, ns = ...
if ns.Inactive then return end
local LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
ns.MEDIA_DEFAULT_TOKEN = "__MIDNIGHT_DEFAULT__"

local MEDIA_KIND_TO_LSM = {
    font = LSM and LSM.MediaType.FONT or "font",
    background = LSM and LSM.MediaType.BACKGROUND or "background",
    sound = LSM and LSM.MediaType.SOUND or "sound",
}

local DEFAULT_FONT_FLAGS = "OUTLINE"
local GetActiveMediaProfile
local GetResolvedMediaSetting
local ResolveSelectedFontPath
local fontsReady = false
local fontValidationCache = {}
local fontValidationObject

function ns.GetSharedMedia()
    LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
    return LSM
end

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
    local sharedMedia = ns.GetSharedMedia()
    if not sharedMedia or type(name) ~= "string" or name == "" then
        return fallback
    end

    local mediaType = MEDIA_KIND_TO_LSM[kind]
    local path = mediaType and sharedMedia:Fetch(mediaType, name, true)
    if type(path) == "string" then
        return path
    end

    return fallback
end

local function ResolveMediaPath(kind, name, explicitPath, fallback)
    if name == ns.MEDIA_DEFAULT_TOKEN then
        return fallback
    end

    local registeredPath = FetchSharedMedia(kind, name, nil)
    if type(registeredPath) == "string" and registeredPath ~= "" then
        return registeredPath
    end

    if type(explicitPath) == "string" and explicitPath ~= "" then
        return explicitPath
    end

    return fallback
end

local function HasCustomBackground(profile)
    return type(profile) == "table"
        and type(profile.backgroundMedia) == "string"
        and profile.backgroundMedia ~= ""
        and profile.backgroundMedia ~= ns.MEDIA_DEFAULT_TOKEN
end

local interfaceThemes = {
    retail = {
        background = "Interface\\FrameGeneral\\UI-Background-Rock",
        borderLayout = "SimplePanelTemplate",
        tint = { 0.43, 0.41, 0.38 },
        borderTint = { 0.90, 0.88, 0.83 },
        panelBorderColor = { 0.33, 0.31, 0.28 },
        dropdownArrow = { 0.93, 0.88, 0.79 },
        accent = "#d8bd83",
        titleAtlas = "_UI-Frame-TitleTile",
        windowTitleAtlas = "_UI-Frame-TitleTileBg",
        windowTitleOffsetX = -2,
        windowTitleLeftAdjustment = -1,
        windowTitleOffsetY = 2,
        neutralHeaderArtOnForever = true,
        titleTint = { 1, 1, 1 },
        headerAtlas = "UI-Character-Info-Title",
        headerTint = { 1, 1, 1 },
        headerColor = { 0.16, 0.15, 0.14 },
        contentTint = { 0.095, 0.09, 0.085 },
        contentBorder = { 0.27, 0.25, 0.22 },
        cardTint = { 0.073, 0.069, 0.064 },
        selectedCardBorder = { 0.55, 0.52, 0.45 },
        scrollThumb = { 0.52, 0.50, 0.47 },
        scrollTrack = { 0.05, 0.05, 0.05 },
    },
    forever = {
        background = "Interface\\FrameGeneral\\UI-Background-Rock",
        backgroundAtlas = "UI-Character-Info-Stat-BG",
        borderLayout = "SimplePanelTemplate",
        borderTint = { 1, 0.75, 0.52 },
        panelBorderColor = { 0.45, 0.32, 0.19 },
        dropdownArrow = { 0.85, 0.66, 0.44 },
        tint = { 0.58, 0.52, 0.44 },
        accent = "#dfc49b",
        titleAtlas = "_UI-Frame-TitleTile",
        windowTitleAtlas = "_UI-Frame-TitleTileBg",
        windowTitleLeftAdjustment = -1,
        windowTitleRightAdjustment = 1,
        titleTint = { 0.94, 0.76, 0.55 },
        headerAtlas = "UI-Character-Info-Title",
        headerTint = { 0.95, 0.90, 0.80 },
        headerColor = { 0.24, 0.19, 0.13 },
        contentTint = { 0.12, 0.095, 0.065 },
        contentBorder = { 0.40, 0.32, 0.23 },
        cardTint = { 0.12, 0.088, 0.057 },
        selectedCardBorder = { 0.67, 0.47, 0.28 },
        scrollThumb = { 0.40, 0.25, 0.12 },
        scrollTrack = { 0.10, 0.07, 0.04 },
    },
}

function ns.GetInterfaceTheme()
    local addon = ns.MR
    local profile = addon and addon.db and addon.db.profile
    local key = profile and profile.interfaceTheme
    return interfaceThemes[key], interfaceThemes[key] and key or "routine"
end

function ns.ResolveScrollbarColor(r, g, b, themed)
    local theme = ns.GetInterfaceTheme()
    if theme then return unpack(theme.scrollThumb) end
    if themed ~= false then return ns.ResolveThemeColor(r, g, b) end
    return r, g, b
end

function ns.ApplyScrollbarTrackColor(texture, color)
    local theme = ns.GetInterfaceTheme()
    local tint = theme and theme.scrollTrack or color
    texture:SetColorTexture(tint[1], tint[2], tint[3], color[4] or 1)
end

function ns.ApplyInterfaceHeader(texture, alpha, title, customColor, windowTitle)
    local theme = ns.GetInterfaceTheme()
    local atlas = theme and (title and theme.titleAtlas or theme.headerAtlas)
    if theme and windowTitle and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(theme.windowTitleAtlas) then
        atlas = theme.windowTitleAtlas
    end
    local atlasInfo = atlas and not customColor and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
    local canSlice = texture.SetTextureSliceMargins and texture.SetTextureSliceMode and Enum and Enum.UITextureSliceMode
    if atlasInfo and (title or canSlice) then
        if texture:GetAtlas() ~= atlas then texture:SetAtlas(atlas) end
        if canSlice then
            local capWidth = title and 0 or math.min(12, math.floor((atlasInfo.width or 48) / 4))
            texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
            texture:SetTextureSliceMargins(capWidth, 0, capWidth, 0)
        end
        texture:SetDesaturated(not not (theme.neutralHeaderArtOnForever and ns.MR and ns.MR.isForever))
        local tint = title and theme.titleTint or theme.headerTint
        texture:SetVertexColor(tint[1], tint[2], tint[3], alpha)
        return true
    end

    if canSlice then texture:SetTextureSliceMargins(0, 0, 0, 0) end
    local color = customColor or (theme and theme.headerColor)
    if color then
        texture:SetDesaturated(false)
        texture:SetColorTexture(color[1], color[2], color[3], alpha)
        texture:SetVertexColor(1, 1, 1)
        return true
    end
    return false
end

function ns.ApplyModuleHeaderBackground(header, hexColor, alpha)
    alpha = alpha or header._mrHeaderAlpha or 0
    header._mrHeaderAlpha = alpha
    local texture = header._hdrBg
    if not ns.ApplyInterfaceHeader(texture, alpha, false, hexColor and { ns.Hex(hexColor) }) then
        texture:SetDesaturated(false)
        texture:SetColorTexture(0.08, 0.09, 0.12, alpha)
        texture:SetVertexColor(1, 1, 1)
    end
end

function ns.GetSharedMediaList(kind)
    local sharedMedia = ns.GetSharedMedia()
    if not sharedMedia then
        return {}
    end

    local mediaType = MEDIA_KIND_TO_LSM[kind]
    if not mediaType then
        return {}
    end

    return sharedMedia:List(mediaType) or {}
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

local function ResolveRegisteredFont(name)
    local sharedMedia = ns.GetSharedMedia()
    if type(name) ~= "string" or name == "" or not sharedMedia
        or not sharedMedia:IsValid(MEDIA_KIND_TO_LSM.font, name) then
        return nil
    end

    local path = FetchSharedMedia("font", name, nil)
    if type(path) ~= "string" or path == "" then
        return nil
    end

    if fontValidationCache[path] == nil then
        fontValidationObject = fontValidationObject or CreateFont("MidnightRoutineMediaValidationFont")
        local ok = pcall(fontValidationObject.SetFont, fontValidationObject, path, 12, "")
        local loadedPath = ok and fontValidationObject:GetFont()
        if type(loadedPath) == "string" and loadedPath:lower():gsub("/", "\\") == path:lower():gsub("/", "\\") then
            fontValidationCache[path] = true
        end
    end

    return fontValidationCache[path] and path or nil
end

local function NormalizeSavedFonts(settings)
    if type(settings) ~= "table" then return end

    for _, key in ipairs({ "fontMedia", "rowFontMedia", "headerFontMedia" }) do
        local name = settings[key]
        local pathKey = key .. "Path"
        if name ~= nil and name ~= ns.MEDIA_DEFAULT_TOKEN then
            local path = ResolveRegisteredFont(name)
            if path then
                settings[pathKey] = path
            else
                settings[key] = ns.MEDIA_DEFAULT_TOKEN
                settings[pathKey] = nil
            end
        else
            if name == nil and settings[pathKey] ~= nil then
                settings[key] = ns.MEDIA_DEFAULT_TOKEN
            end
            settings[pathKey] = nil
        end
    end
end

function ns.ValidateSavedFonts()
    fontsReady = true
    local addon = ns.MR
    local db = addon and addon.db
    if not db then return end

    NormalizeSavedFonts(db.profile)
    NormalizeSavedFonts(db.char and db.char.mediaSettings)
    local saved = db.sv
    if type(saved) ~= "table" then return end

    for _, settings in pairs(type(saved.profiles) == "table" and saved.profiles or {}) do
        NormalizeSavedFonts(settings)
    end
    for _, character in pairs(type(saved.char) == "table" and saved.char or {}) do
        if type(character) == "table" then
            NormalizeSavedFonts(character.mediaSettings)
        end
    end
end

ResolveSelectedFontPath = function(profile)
    profile = profile or GetActiveMediaProfile()

    if fontsReady then
        NormalizeSavedFonts(profile)
    end

    local defaultFont = ResolveDefaultFont()
    local sharedFont = (profile and profile.fontMedia) or GetResolvedMediaSetting("fontMedia")
        or (profile and profile.rowFontMedia) or GetResolvedMediaSetting("rowFontMedia")
        or (profile and profile.headerFontMedia) or GetResolvedMediaSetting("headerFontMedia")
    local resolved = ResolveRegisteredFont(sharedFont)
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

function ns.ApplyBackgroundTexture(texture, r, g, b, a, useInterfaceTheme)
    if not texture then
        return
    end

    local profile = GetActiveMediaProfile()
    local custom = HasCustomBackground(profile)
    local theme = useInterfaceTheme and not custom and ns.GetInterfaceTheme()
    local atlas = theme and theme.backgroundAtlas
    if atlas and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas) then
        if texture:GetAtlas() ~= atlas then texture:SetAtlas(atlas) end
        texture:SetVertexColor(theme.tint[1], theme.tint[2], theme.tint[3], a or 1)
        return
    end
    local bgFile = theme and theme.background or ns.BACKDROP_FILE
    if type(bgFile) == "string" and bgFile ~= "" then
        texture:SetTexture(bgFile)
        if custom then
            texture:SetVertexColor(1, 1, 1, a or 1)
        elseif theme then
            texture:SetVertexColor(theme.tint[1], theme.tint[2], theme.tint[3], a or 1)
        else
            texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
        end
        return
    end

    texture:SetTexture(nil)
end

local backdropFrames = setmetatable({}, { __mode = "k" })
local panelBorderAtlases = {
    SimplePanelTemplate = {
        "UI-Frame-SimpleMetal-CornerTopLeft",
        "_UI-Frame-SimpleMetal-EdgeTop",
        "!UI-Frame-SimpleMetal-EdgeLeft",
    },
}
local panelBordersAvailable = {}

local function HasNativePanelBorder(layout)
    if panelBordersAvailable[layout] ~= nil then return panelBordersAvailable[layout] end
    if not (NineSliceUtil and type(NineSliceUtil.ApplyLayoutByName) == "function" and C_Texture and C_Texture.GetAtlasInfo) then
        return false
    end
    for _, atlas in ipairs(panelBorderAtlases[layout]) do
        if not C_Texture.GetAtlasInfo(atlas) then
            panelBordersAvailable[layout] = false
            return false
        end
    end
    panelBordersAvailable[layout] = true
    return true
end

local function GetBackdropTheme(frame)
    if frame._mrUsePanelTheme or frame._mrBackdropRole then
        return ns.GetInterfaceTheme()
    end
end

local function JoinPanelBorderToTitle(frame, border, theme)
    local title = frame._mrNativeTitleOwner
    local anchor = title and title:GetPoint()
    local join = theme and title and anchor and anchor:find("^TOP")
    for _, name in ipairs({ "TopLeftCorner", "TopRightCorner", "TopEdge" }) do
        local piece = border[name]
        if piece then piece:SetShown(not join) end
    end
    for _, side in ipairs({ "Left", "Right" }) do
        local edge = border[side .. "Edge"]
        local corner = border["Top" .. side .. "Corner"]
        if edge and corner then
            local point = "TOP" .. side:upper()
            if join then
                edge:SetPoint(point, border, point, side == "Left" and -5 or 2, 1 - title:GetHeight())
            else
                edge:SetPoint(point, corner, "BOTTOM" .. side:upper(), 0, 0)
            end
        end
    end
end

local function ApplyBackdropColor(frame, theme, custom, r, g, b, a)
    local art = frame._mrBackdropArt
    local role = frame._mrBackdropRole
    local headerArt = role == "title" or role == "trackerTitle" or (role == "section" and not frame._mrCustomHeader)
    local controlArt = theme and role == "control" and not custom
    local windowTitle = role == "title" or role == "trackerTitle"
    if theme and windowTitle and not frame._mrNativeTitle then
        local trim = frame._mrTitleTrimOffsets or {}
        local panel = CreateFrame("Frame", nil, frame, "DefaultPanelFlatTemplate")
        panel:EnableMouse(false)
        panel:SetPoint("TOPLEFT", frame, "TOPLEFT", trim.left or 0, trim.top or 0)
        panel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
        panel:SetClipsChildren(true)
        panel:SetFrameLevel(frame:GetFrameLevel())
        panel.TitleContainer:Hide()
        panel.Bg:Hide()
        panel.NineSlice:SetFrameLevel(frame:GetFrameLevel())
        for _, name in ipairs({ "BottomLeftCorner", "BottomRightCorner", "LeftEdge", "RightEdge", "BottomEdge" }) do
            local piece = panel.NineSlice[name]
            if piece then piece:Hide() end
        end
        frame._mrNativeTitle = panel
        local owner = frame:GetParent()
        if owner and owner._mrUsePanelTheme then
            owner._mrNativeTitleOwner = frame
        end
        local border = panel.NineSlice
        local function PositionTitlePieces()
            local currentTheme = GetBackdropTheme(frame)
            local offsetX = currentTheme and currentTheme.windowTitleOffsetX or 0
            local leftAdjustment = currentTheme and currentTheme.windowTitleLeftAdjustment or 0
            local rightAdjustment = currentTheme and currentTheme.windowTitleRightAdjustment or 0
            local offsetY = (22 - frame:GetHeight()) * 0.5 - 2
                + (currentTheme and currentTheme.windowTitleOffsetY or 0) + (trim.top or 0)
            border:ClearAllPoints()
            border:SetPoint("TOPLEFT", frame, "TOPLEFT", offsetX + (trim.left or 0) + leftAdjustment, offsetY)
            border:SetPoint("TOPRIGHT", frame, "TOPRIGHT", offsetX + 4 + (trim.right or -2) + rightAdjustment, offsetY)
            border:SetHeight(100)
            if owner and owner._mrNativeBorder and owner._mrNativeTitleOwner == frame then
                JoinPanelBorderToTitle(owner, owner._mrNativeBorder, currentTheme)
            end
        end
        panel._mrPositionTitlePieces = PositionTitlePieces
        panel:HookScript("OnShow", PositionTitlePieces)
        frame:HookScript("OnSizeChanged", PositionTitlePieces)
    end
    if frame._mrNativeTitle then
        frame._mrNativeTitle:SetShown(theme ~= nil and windowTitle)
        local parentColor = frame:GetParent()._mrBackgroundColor
        frame._mrNativeTitle:SetAlpha(role == "trackerTitle" and parentColor and parentColor[4] or a)
        if theme then
            frame._mrNativeTitle._mrPositionTitlePieces()
            local tr, tg, tb = unpack(theme.titleTint)
            local neutral = theme.neutralHeaderArtOnForever and ns.MR and ns.MR.isForever
            for _, piece in ipairs({ frame._mrNativeTitle.NineSlice:GetRegions() }) do
                piece:SetDesaturated(not not neutral)
                piece:SetVertexColor(tr, tg, tb)
            end
        end
        local owner = frame:GetParent()
        local outerBorder = owner and owner._mrNativeBorder
        if outerBorder and owner._mrNativeTitleOwner == frame then
            JoinPanelBorderToTitle(owner, outerBorder, theme)
        end
    end
    if theme and (headerArt or controlArt or (not custom and frame._mrUsePanelTheme and theme.backgroundAtlas)) then
        if not art then
            art = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
            art:SetAllPoints()
            frame._mrBackdropArt = art
        end
        art:ClearAllPoints()
        if controlArt then
            art:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
            art:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
            ns.ApplyInterfaceHeader(art, a, true)
            local brightness = frame:IsMouseOver() and 0.85 or 0.55
            art:SetVertexColor(brightness, brightness, brightness, a)
        elseif frame._mrUsePanelTheme then
            art:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -5)
            art:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
        else
            art:SetAllPoints()
        end
        if headerArt then
            local parentColor = frame:GetParent()._mrBackgroundColor
            local titleAlpha = frame._mrBackdropRole == "trackerTitle" and parentColor and parentColor[4] or a
            ns.ApplyInterfaceHeader(art, titleAlpha, role ~= "section", nil, role == "title" or role == "trackerTitle")
        elseif not controlArt then
            ns.ApplyBackgroundTexture(art, r, g, b, a, true)
        end
        art:Show()
        if windowTitle and frame._mrNativeTitle then
            art:Hide()
        end
    elseif art then
        art:Hide()
    end

    local tint = theme and (frame._mrUsePanelTheme and theme.tint or theme.contentTint)
    if theme and role == "settingsSection" then
        tint = theme.headerColor
    elseif theme and role == "inset" then
        tint = theme.scrollTrack
    elseif theme and role == "character" then
        tint = frame._selected and theme.headerColor or theme.cardTint
    elseif theme and role == "control" and (frame._mrControlActive or frame:IsMouseOver()) then
        tint = theme.headerColor
    end
    if custom and not frame._mrCustomHeader then
        r, g, b = 1, 1, 1
    elseif tint and not frame._mrCustomHeader then
        r, g, b = unpack(tint)
    end
    local backgroundAlpha = theme and windowTitle and frame._mrNativeTitle and 0 or a
    frame._mrOriginalSetBackdropColor(frame, r, g, b, backgroundAlpha)
    if theme and windowTitle and frame._mrNativeTitle and frame._mrOriginalSetBackdropBorderColor then
        frame._mrOriginalSetBackdropBorderColor(frame, 0, 0, 0, 0)
    end
end

local function ApplyBackdropBorder(frame, theme, r, g, b, a)
    local nativeBorder = frame._mrNativeBorder
    local layout = theme and frame._mrUsePanelTheme and theme.borderLayout
    local useNativeBorder = layout
        and a > 0 and frame:GetHeight() >= 64 and frame:GetWidth() >= 64
        and HasNativePanelBorder(layout)
    if useNativeBorder then
        if not nativeBorder then
            nativeBorder = CreateFrame("Frame", nil, frame)
            nativeBorder:SetFrameLevel(frame:GetFrameLevel())
            nativeBorder:EnableMouse(false)
            nativeBorder.layoutTextureSubLevel = 0
            frame._mrNativeBorder = nativeBorder
        end
        if nativeBorder._mrLayout ~= layout then
            nativeBorder:ClearAllPoints()
            nativeBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, 0)
            nativeBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -1)
            NineSliceUtil.ApplyLayoutByName(nativeBorder, layout)
            nativeBorder._mrLayout = layout
        end
    end
    if nativeBorder then
        nativeBorder:SetShown(not not useNativeBorder)
        if useNativeBorder then
            JoinPanelBorderToTitle(frame, nativeBorder, theme)
            if nativeBorder._mrAppliedTheme ~= theme then
                local tr, tg, tb = 1, 1, 1
                if theme.borderTint then
                    tr, tg, tb = unpack(theme.borderTint)
                end
                for _, texture in ipairs({ nativeBorder:GetRegions() }) do
                    texture:SetVertexColor(tr, tg, tb)
                end
                nativeBorder._mrAppliedTheme = theme
            end
            nativeBorder:SetAlpha(a)
            a = 0
        end
    end
    if theme and not frame._mrCustomHeader then
        if frame._mrUsePanelTheme then
            r, g, b = unpack(theme.panelBorderColor or theme.selectedCardBorder)
        elseif frame._mrBackdropRole == "character" and frame._selected then
            r, g, b = unpack(theme.selectedCardBorder)
        elseif frame._mrBackdropRole == "control" and frame._mrControlActive then
            r, g, b = unpack(theme.selectedCardBorder)
        else
            r, g, b = unpack(theme.contentBorder)
        end
    end
    local role = frame._mrBackdropRole
    if theme and frame._mrNativeTitle and (role == "title" or role == "trackerTitle") then
        a = 0
    end
    frame._mrOriginalSetBackdropBorderColor(frame, r, g, b, a)
end

local function ApplyBackdropColors(frame, theme, custom)
    ApplyBackdropColor(frame, theme, custom, unpack(frame._mrBackgroundColor))
    local border = frame._mrBorderColor
    if border then
        ApplyBackdropBorder(frame, theme, unpack(border))
    end
end

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
            local theme = GetBackdropTheme(frame)
            local custom = HasCustomBackground(GetActiveMediaProfile())
            local bgFile = theme and frame._mrUsePanelTheme and not custom and theme.background or ns.BACKDROP_FILE or ResolveDefaultBackground()
            if backdrop.bgFile ~= bgFile or frame._mrAppliedBackdropTheme ~= theme
                or frame._mrAppliedCustomBackground ~= custom then
                backdrop.bgFile = bgFile
                if frame._mrUsePanelTheme then
                    backdrop.insets = theme and { left = 3, right = 3, top = 5, bottom = 3 } or frame._mrOriginalBackdropInsets
                end
                frame._mrRefreshingBackground = true
                frame:SetBackdrop(backdrop)
                frame._mrAppliedBackdropTheme = theme
                frame._mrAppliedCustomBackground = custom
                ApplyBackdropColors(frame, theme, custom)
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
    local backdrop = frame:GetBackdrop()
    frame._mrOriginalBackdropInsets = backdrop and backdrop.insets
    frame._mrUsePanelTheme = frame:GetParent() == UIParent and backdrop
        and backdrop.edgeFile == ResolveDefaultBackground()
    backdropFrames[frame] = true
    local originalSetBackdropColor = frame.SetBackdropColor
    local originalSetBackdropBorderColor = frame.SetBackdropBorderColor
    frame._mrOriginalSetBackdropColor = originalSetBackdropColor
    frame._mrOriginalSetBackdropBorderColor = originalSetBackdropBorderColor
    if frame._mrUsePanelTheme then
        frame:HookScript("OnSizeChanged", function(self)
            if self._mrBorderColor then
                ApplyBackdropBorder(self, GetBackdropTheme(self), unpack(self._mrBorderColor))
            end
        end)
    end
    frame.SetBackdropColor = function(self, r, g, b, a)
        if self._mrRefreshingBackground then
            originalSetBackdropColor(self, r, g, b, a)
            return
        end

        self._mrBackgroundColor = { r or 1, g or 1, b or 1, a or 1 }
        ApplyBackdropColor(self, GetBackdropTheme(self), HasCustomBackground(GetActiveMediaProfile()), unpack(self._mrBackgroundColor))
        ns.RefreshFrameBackground(self)
    end
    if type(originalSetBackdropBorderColor) == "function" then
        frame.SetBackdropBorderColor = function(self, r, g, b, a)
            if self._mrRefreshingBackground then
                originalSetBackdropBorderColor(self, r, g, b, a)
                return
            end
            self._mrBorderColor = { r or 1, g or 1, b or 1, a or 1 }
            ApplyBackdropBorder(self, GetBackdropTheme(self), unpack(self._mrBorderColor))
        end
    end
end

function ns.HookBackdropFrame(frame, role, customHeader)
    if frame and role then
        frame._mrBackdropRole = role
        frame._mrCustomHeader = customHeader
    end
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
local DEFAULT_ACCENT = { COLORS.accent[1], COLORS.accent[2], COLORS.accent[3] }

function ns.ApplyThemeAccentColor(hexColor)
    local r, g, b
    if type(hexColor) == "string" then
        r, g, b = ns.Hex(hexColor)
    end
    COLORS.accent[1] = r or DEFAULT_ACCENT[1]
    COLORS.accent[2] = g or DEFAULT_ACCENT[2]
    COLORS.accent[3] = b or DEFAULT_ACCENT[3]
end

local DEFAULT_TITLE_COLOR = { 0.1647, 0.9059, 0.7765 }

function ns.ResolveThemeColor(defaultR, defaultG, defaultB)
    local addon = ns.MR
    local hexColor = addon and addon.GetThemeColor and addon:GetThemeColor()
    if hexColor then
        local r, g, b = ns.Hex(hexColor)
        if r then
            return r, g, b
        end
    end
    return defaultR, defaultG, defaultB
end

local themedTextures = setmetatable({}, { __mode = "k" })
local themedFontStrings = setmetatable({}, { __mode = "k" })
local themedVertexTextures = setmetatable({}, { __mode = "k" })
local themedBackdropColors = setmetatable({}, { __mode = "k" })
local themedBackdropBorders = setmetatable({}, { __mode = "k" })
local themedStateRefreshers = setmetatable({}, { __mode = "k" })

local function ApplyThemedColor(target, method, defaultR, defaultG, defaultB, alpha)
    local isBorder = method == "SetBackdropBorderColor"
    local isBackground = method == "SetBackdropColor"
    local theme = (isBorder or isBackground) and ns.GetInterfaceTheme()
    local addon = ns.MR
    local profile = addon and addon.db and addon.db.profile
    local r, g, b
    if theme and profile and profile.themeColorMode == "default" then
        r, g, b = unpack(isBorder and theme.contentBorder or theme.contentTint)
    else
        r, g, b = ns.ResolveThemeColor(defaultR, defaultG, defaultB)
    end
    target[method](target, r, g, b, alpha or 1)
end

function ns.RegisterThemedFontString(fontString, defaultR, defaultG, defaultB, alpha)
    if not fontString then
        return fontString
    end
    themedFontStrings[fontString] = { defaultR, defaultG, defaultB, alpha or 1 }
    ApplyThemedColor(fontString, "SetTextColor", defaultR, defaultG, defaultB, alpha)
    return fontString
end

function ns.RegisterThemedVertexTexture(texture, defaultR, defaultG, defaultB, alpha)
    if not texture then
        return texture
    end
    themedVertexTextures[texture] = { defaultR, defaultG, defaultB, alpha or 1 }
    ApplyThemedColor(texture, "SetVertexColor", defaultR, defaultG, defaultB, alpha)
    return texture
end

function ns.RegisterThemedBackdropColor(frame, defaultR, defaultG, defaultB, alpha)
    if not frame then
        return frame
    end
    themedBackdropColors[frame] = { defaultR, defaultG, defaultB, alpha or 1 }
    ApplyThemedColor(frame, "SetBackdropColor", defaultR, defaultG, defaultB, alpha)
    return frame
end

function ns.RegisterThemedBackdropBorder(frame, defaultR, defaultG, defaultB, alpha)
    if not frame then
        return frame
    end
    themedBackdropBorders[frame] = { defaultR, defaultG, defaultB, alpha or 1 }
    ApplyThemedColor(frame, "SetBackdropBorderColor", defaultR, defaultG, defaultB, alpha)
    return frame
end

function ns.RegisterThemedTexture(texture, defaultR, defaultG, defaultB, alpha)
    if not texture then
        return texture
    end
    alpha = alpha or 1
    themedTextures[texture] = { defaultR, defaultG, defaultB, alpha }
    local r, g, b = ns.ResolveThemeColor(defaultR, defaultG, defaultB)
    texture:SetColorTexture(r, g, b, alpha)
    return texture
end

function ns.RegisterThemedState(target, refresher)
    if not target or type(refresher) ~= "function" then
        return target
    end
    themedStateRefreshers[target] = refresher
    refresher(target)
    return target
end

function ns.ThemeCheckButton(button)
    if not button or not button.GetCheckedTexture then
        return button
    end
    local texture = button:GetCheckedTexture()
    if texture then
        ns.RegisterThemedVertexTexture(texture, 0.85, 0.65, 0.10, 1)
    end
    return button
end

function ns.RefreshThemedTextures()
    for texture, def in pairs(themedTextures) do
        local r, g, b = ns.ResolveThemeColor(def[1], def[2], def[3])
        texture:SetColorTexture(r, g, b, def[4])
    end
    for fontString, def in pairs(themedFontStrings) do
        ApplyThemedColor(fontString, "SetTextColor", def[1], def[2], def[3], def[4])
    end
    for texture, def in pairs(themedVertexTextures) do
        ApplyThemedColor(texture, "SetVertexColor", def[1], def[2], def[3], def[4])
    end
    for frame, def in pairs(themedBackdropColors) do
        ApplyThemedColor(frame, "SetBackdropColor", def[1], def[2], def[3], def[4])
    end
    for frame, def in pairs(themedBackdropBorders) do
        ApplyThemedColor(frame, "SetBackdropBorderColor", def[1], def[2], def[3], def[4])
    end
    for target, refresher in pairs(themedStateRefreshers) do
        refresher(target)
    end
end

function ns.StripColorCodes(text)
    if type(text) ~= "string" then
        return text
    end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    text = text:gsub("|r", "")
    return text
end

function ns.ApplyTitleBarTheme(hexColor)
    local r, g, b
    if type(hexColor) == "string" then
        r, g, b = ns.Hex(hexColor)
    end
    r = r or DEFAULT_TITLE_COLOR[1]
    g = g or DEFAULT_TITLE_COLOR[2]
    b = b or DEFAULT_TITLE_COLOR[3]

    local addon = ns.MR
    if addon and addon.titleText then
        addon.titleText:SetTextColor(r, g, b)
    end
    if addon and addon._scrollThumbTex then
        local sr, sg, sb = ns.ResolveScrollbarColor(r, g, b, false)
        addon._scrollThumbTex:SetColorTexture(sr, sg, sb, 0.75)
    end
    if ns.RefreshThemedTextures then
        ns.RefreshThemedTextures()
    end
end

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
    r, g, b = r or DEFAULT_ACCENT[1], g or DEFAULT_ACCENT[2], b or DEFAULT_ACCENT[3]
    local tex = parent:CreateTexture(nil, "BORDER")
    tex:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    tex:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    tex:SetHeight(2)
    ns.RegisterThemedTexture(tex, r, g, b, 1)
    ns.RegisterThemedState(tex, function()
        tex:SetShown(not ns.GetInterfaceTheme())
    end)
    return tex
end

function ns.LeftAccent(parent, r, g, b)
    r, g, b = r or DEFAULT_ACCENT[1], g or DEFAULT_ACCENT[2], b or DEFAULT_ACCENT[3]

    local group = CreateFrame("Frame", nil, parent)
    group:SetAllPoints(parent)

    local topRule = group:CreateTexture(nil, "BORDER")
    topRule:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, 0)
    topRule:SetWidth(44)
    topRule:SetHeight(2)
    ns.RegisterThemedTexture(topRule, r, g, b, 0.95)
    group.topRule = topRule

    local notch = group:CreateTexture(nil, "BORDER")
    notch:SetPoint("TOPLEFT", topRule, "BOTTOMRIGHT", 4, 0)
    notch:SetWidth(10)
    notch:SetHeight(2)
    ns.RegisterThemedTexture(notch, r, g, b, 0.65)
    group.notch = notch

    local glow = group:CreateTexture(nil, "ARTWORK")
    glow:SetPoint("TOPLEFT", topRule, "BOTTOMLEFT", 0, -2)
    glow:SetWidth(58)
    glow:SetHeight(8)
    ns.RegisterThemedTexture(glow, r, g, b, 0.14)
    group.glow = glow

    return group
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
    local frame = ns.AcquireFrame(body, "optDivider", "Frame", "BackdropTemplate")
    frame:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    frame:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad, yOff)
    frame:SetHeight(1)
    frame:SetBackdrop(ns.MakeBackdrop(false))
    ns.RegisterThemedBackdropColor(frame, 0.18, 0.78, 0.72, 0.24)
    return yOff - 5
end

function ns.OptionsSectionLabel(body, yOff, text, pad, fontSize)
    pad = pad or 8
    local frame = ns.AcquireFrame(body, "optSectionLabel", "Frame", "BackdropTemplate")
    frame:SetPoint("TOPLEFT", body, "TOPLEFT", pad - 2, yOff)
    frame:SetPoint("TOPRIGHT", body, "TOPRIGHT", -pad + 2, yOff)
    frame:SetHeight(17)
    frame:SetBackdrop(ns.MakeBackdrop())
    ns.HookBackdropFrame(frame, "settingsSection")
    frame:SetBackdropColor(0.025, 0.12, 0.15, 0.92)
    ns.RegisterThemedBackdropBorder(frame, 0.12, 0.42, 0.44, 0.58)

    local fs = ns.AcquireFontString(frame, "text", "OVERLAY")
    fs:SetFont(ns.FONT_HEADERS or ns.FONT_ROWS, math.max(fontSize or 9, 10), ns.GetFontFlags())
    fs:SetText(text)
    ns.RegisterThemedFontString(fs, 0.46, 0.92, 0.84)
    fs:SetPoint("LEFT", frame, "LEFT", 6, 0)
    fs:SetPoint("RIGHT", frame, "RIGHT", -6, 0)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return yOff - 20
end

function ns.OptionsCheckbox(body, yOff, label, getVal, setVal, r, g, b, pad, onRefresh, fontSize, themed)
    pad = pad or 8
    local frame = ns.AcquireFrame(body, "optCheckbox", "CheckButton", "UICheckButtonTemplate")
    ns.ThemeCheckButton(frame)
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

    local lbl = ns.AcquireFontString(frame, "label", "OVERLAY")
    lbl:SetFont(ns.FONT_ROWS, fontSize or 10, ns.GetFontFlags())
    lbl:SetText(label)
    if themed then
        lbl:SetTextColor(0.94, 0.96, 0.98)
    else
        lbl:SetTextColor(r or 0.88, g or 0.88, b or 0.88)
    end
    lbl:SetPoint("LEFT", frame, "RIGHT", 2, 0)
    lbl:SetPoint("RIGHT", body, "RIGHT", -pad, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetWordWrap(false)
    return yOff - 19
end

function ns.OptionsBtn(body, yOff, label, onClick, width, pad, fontSize, style)
    pad = pad or 8
    width = width or 184
    local primary = style == "primary"
    local height = primary and 24 or 20

    local btn = ns.AcquireFrame(body, "optBtn", "Button", "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    btn:SetBackdrop(ns.MakeBackdrop())
    ns.HookBackdropFrame(btn, "control")
    btn:SetBackdropColor(primary and 0.04 or 0.05, primary and 0.25 or 0.10, primary and 0.28 or 0.18, 1)
    local borderR = primary and 0.20 or 0.18
    local borderG = primary and 0.82 or 0.40
    local borderB = primary and 0.72 or 0.45
    ns.RegisterThemedBackdropBorder(btn, borderR, borderG, borderB, 1)

    local fs = ns.AcquireFontString(btn, "label", "OVERLAY")
    fs:SetFont(primary and (ns.FONT_HEADERS or ns.FONT_ROWS) or ns.FONT_ROWS, fontSize or 10, ns.GetFontFlags())
    fs:SetPoint("LEFT", btn, "LEFT", 6, 0)
    fs:SetWidth(width - 12)
    fs:SetJustifyH(primary and "CENTER" or "LEFT")
    fs:SetWordWrap(false)
    fs:SetText(label)
    fs:SetTextColor(primary and 1 or 0.92, primary and 1 or 0.94, primary and 1 or 0.96)

    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.08, 0.22, 0.32, 1)
        local r, g, b = ns.ResolveThemeColor(0.25, 0.85, 0.72)
        btn:SetBackdropBorderColor(r, g, b, 1)
        fs:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(primary and 0.04 or 0.05, primary and 0.25 or 0.10, primary and 0.28 or 0.18, 1)
        local r, g, b = ns.ResolveThemeColor(borderR, borderG, borderB)
        btn:SetBackdropBorderColor(r, g, b, 1)
        fs:SetTextColor(primary and 1 or 0.92, primary and 1 or 0.94, primary and 1 or 0.96)
    end)
    ns.RegisterThemedState(btn, function()
        if btn:IsMouseOver() then
            btn:SetBackdropColor(0.08, 0.22, 0.32, 1)
            local r, g, b = ns.ResolveThemeColor(0.25, 0.85, 0.72)
            btn:SetBackdropBorderColor(r, g, b, 1)
            fs:SetTextColor(1, 1, 1)
        else
            btn:SetBackdropColor(primary and 0.04 or 0.05, primary and 0.25 or 0.10, primary and 0.28 or 0.18, 1)
            local r, g, b = ns.ResolveThemeColor(borderR, borderG, borderB)
            btn:SetBackdropBorderColor(r, g, b, 1)
            fs:SetTextColor(primary and 1 or 0.92, primary and 1 or 0.94, primary and 1 or 0.96)
        end
    end)

    return yOff - height - 2
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

    local lbl = ns.AcquireFontString(body, "optSliderLabel", "OVERLAY")
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

    local bg = ns.AcquireFrame(body, "optSliderTrack", "Frame", "BackdropTemplate")
    bg:SetPoint("TOPLEFT", body, "TOPLEFT", pad, yOff)
    bg:SetSize(sliderW, 14)
    bg:SetBackdrop(ns.MakeBackdrop())
    bg:SetBackdropColor(0, 0, 0, disabled and 0.25 or 0.5)
    bg:SetBackdropBorderColor(0.25, 0.25, 0.3, disabled and 0.4 or 1)

    local fill = ns.AcquireTexture(bg, "fill", "ARTWORK")
    fill:SetPoint("LEFT", bg, "LEFT", 2, 0)
    fill:SetHeight(10)
    if disabled then
        fill:SetColorTexture(fillR, fillG, fillB, 0.4)
    else
        ns.RegisterThemedTexture(fill, fillR, fillG, fillB, 0.85)
    end

    local valBox = ns.AcquireFrame(body, "optSliderValueBox", "Frame", "BackdropTemplate")
    valBox:SetPoint("LEFT", bg, "RIGHT", 4, 0)
    valBox:SetSize(valueBoxW, 14)
    valBox:SetBackdrop(ns.MakeBackdrop())
    valBox:SetBackdropColor(0, 0, 0, disabled and 0.25 or 0.5)
    valBox:SetBackdropBorderColor(0.25, 0.25, 0.3, disabled and 0.4 or 1)

    local valTxt = ns.AcquireFontString(valBox, "text", "OVERLAY")
    valTxt:SetFont(ns.FONT_ROWS, fontSize or 9, ns.GetFontFlags())
    valTxt:SetPoint("CENTER", valBox, "CENTER", 0, 0)
    valTxt:SetTextColor(disabled and 0.4 or 1, disabled and 0.4 or 1, disabled and 0.4 or 1)

    local function UpdateVis(value)
        local pct = (value - min) / (max - min)
        fill:SetWidth(math.max(2, (bg:GetWidth() - 4) * pct))
        valTxt:SetText(string.format("%.2f", value):gsub("%.?0+$", ""))
    end

    local slider = ns.AcquireFrame(bg, "slider", "Slider")
    slider:SetScript("OnValueChanged", nil)
    slider:SetScript("OnMouseUp", nil)
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

    slider:EnableMouse(not disabled)
    if not disabled then
        slider:SetScript("OnValueChanged", function(self, value)
            UpdateVis(value)
        end)
        slider:SetScript("OnMouseUp", function(self)
            setVal(self:GetValue())
        end)
    end

    return yOff - 16
end

function ns.OptionsColorSwatch(parent, r, g, b, onPick, onReset, tooltip, onBegin, onCancel)
    local swatch = ns.AcquireFrame(parent, "colorSwatch", "Button", "BackdropTemplate")
    swatch:SetSize(16, 16)
    swatch:SetBackdrop({
        bgFile = ResolveDefaultBackground(),
        edgeFile = ResolveDefaultBackground(),
        edgeSize = 1,
    })
    swatch:SetBackdropColor(0.02, 0.02, 0.02, 1)
    swatch:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local fill = ns.AcquireTexture(swatch, "fill", "ARTWORK")
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
            if onBegin then
                onBegin()
            end
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
                    if onCancel then
                        onCancel(r, g, b)
                    elseif onPick then
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
        ns.HideOwnedTooltip(swatch)
    end)
    return swatch
end
