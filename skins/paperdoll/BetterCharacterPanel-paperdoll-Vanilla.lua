-- O―――――――――――――――――――――――――――――――――――――――O
-- |   Paperdoll skin for the default UI   |
-- O―――――――――――――――――――――――――――――――――――――――O

BCPSkin_Vanilla = BCPSkin_Vanilla or {}
local skin = BCPSkin_Vanilla

skin.FrameValues = {
    -- Missing enchant indicator bar
    LeftIconsMissingEnchantTexture = "Interface\\Buttons\\WHITE8x8",
    RightIconsMissingEnchantTexture = "Interface\\Buttons\\WHITE8x8",
    SpecialIconsMissingEnchantTexture = "Interface\\Buttons\\WHITE8x8",
    LeftIconsMissingEnchantSize = { 3, 35 },
    RightIconsMissingEnchantSize = { 3, 35 },
    SpecialIconsMissingEnchantSize = { 3, 35 },
    LeftIconsMissingEnchantOffsets = { -1, -1 },
    RightIconsMissingEnchantOffsets = { 1, -1 },
    SpecialIconsMissingEnchantOffsets = { -1, -1 },

    -- Standard left/right enchant text offsets
    LeftIconsPermEnchantOffsets = { 8, 7 },
    LeftIconsTempEnchantOffsets = { 8, -7 },
    RightIconsPermEnchantOffsets = { -7, 7 },
    RightIconsTempEnchantOffsets = { -7, -7 },

    -- Wrist enchant text
    WristsIconPermEnchantTextJustifyH = "LEFT",
    WristsIconPermEnchantTextAnchors = { "LEFT", "RIGHT" },
    WristsIconPermEnchantOffsets = { 8, 16 },
    WristsIconTempEnchantTextJustifyH = "LEFT",
    WristsIconTempEnchantTextAnchors = { "LEFT", "RIGHT" },
    WristsIconTempEnchantOffsets = { 8, 3 },

    -- Main hand enchant text
    MainHandIconPermEnchantTextJustifyH = "RIGHT",
    MainHandIconPermEnchantTextAnchors = { "BOTTOMRIGHT", "BOTTOMLEFT" },
    MainHandIconPermEnchantOffsets = { -8, 6 },
    MainHandIconTempEnchantTextJustifyH = "RIGHT",
    MainHandIconTempEnchantTextAnchors = { "BOTTOMRIGHT", "BOTTOMLEFT" },
    MainHandIconTempEnchantOffsets = { -8, -6 },

    -- Off-hand enchant text
    OffHandIconPermEnchantTextJustifyH = "RIGHT",
    OffHandIconPermEnchantTextAnchors = { "TOPRIGHT", "TOPRIGHT" },
    OffHandIconPermEnchantOffsets = { 0, 16 },
    OffHandIconTempEnchantTextJustifyH = "RIGHT",
    OffHandIconTempEnchantTextAnchors = { "BOTTOMRIGHT", "BOTTOMRIGHT" },
    OffHandIconTempEnchantOffsets = { 0, -12 },

    -- Ranged enchant text
    RangedIconPermEnchantTextJustifyH = "LEFT",
    RangedIconPermEnchantTextAnchors = { "TOPRIGHT", "TOPRIGHT" },
    RangedIconPermEnchantOffsets = { 92, 16 },
    RangedIconTempEnchantTextJustifyH = "LEFT",
    RangedIconTempEnchantTextAnchors = { "BOTTOMRIGHT", "BOTTOMRIGHT" },
    RangedIconTempEnchantOffsets = { 92, -12 },
}

skin.Config = {
    -- Outfitter's "Enable none" / "Enable all" buttons: X = inwards offset of the left button from the Head
    -- slot's left edge, XR = inwards offset of the right button from the Hands slot's right edge, Y = height
    -- above the slots' top edge. They sit in the free row under the guild line, left and right of centre.
    OutfitterButtons = { X = 92, XR = 64, Y = 2, W = 74, H = 14 }, -- W/H: button size (stock 80x18), so they fit the row without touching the text above or the frame below

    -- Character model position
    ModelOffsetX = 65,
    ModelOffsetY = -128, -- stock was -120; more negative = lower
    -- Character model size (1.0 = stock). The model's viewport is scaled by this and the model
    -- itself is scaled back by 1/this, so the model is this much bigger but never cropped.
    ModelScale = 1.25,
    -- Extra viewport width / height (1.0 = stock). Raise if the model gets cropped at the sides / top.
    ModelWidthFactor = 1.2,
    ModelHeightFactor = 1.4,

    -- Outfitter window position, relative to the top-right corner of the stats panel
    OutfitterOffsetX = -5,
    OutfitterOffsetY = -5,

    -- BCP added information panel
    InfoFrameXOffset = 357,
    -- Panel edges relative to PaperDollFrame: Top = units ABOVE its top edge, Bottom = units ABOVE its
    -- bottom edge. Fine-tune in game with /bcpalign (saved per character).
    InfoFrameTop = -10,
    InfoFrameWidth = 170,
    InfoFrameBottom = 70,

    -- Resistance icons
    ResistanceItemWidth = 20,
    ResistanceFrameHeight = 20,
    ResistanceItemSpacing = 8,

    -- Scroll frame
    ScrollTopPad = 45,
    ScrollBottomPad = 15,

    -- Backdrop
    BackdropBgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    BackdropEdgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    BackdropTileSize = 32,
    BackdropEdgeSize = 32,
    BackdropInsets = { left = 12, right = 12, top = 12, bottom = 11 },

    -- BCS stats frame
    StatValueWidth = 60,
    StatValueRightPad = 9,
    StatValueFontSize = 9,
    StatLabelRightPad = 10,
    StatLabelLeftPad = 9,
    StatLabelFontSize = 9,

    -- Card layout
    StatCardTitleTopPad = 12,
    StatCardBottomPad = 12,
    StatRowSpacing = 0,

    -- Native stats row height and card widths
    NativeCardWidthExtra = 20,
    NativeStatCardXOffset = -1,
    NativeStatRowHeight = 13,
    NativeStatFrameWidthExtra = -5,
    NativeStatFrameXOffset = 9,

    -- Font
    TitleFont = "Fonts\\FRIZQT__.TTF",
    TitleFontSize = 12,
    TitleFontFlags = "OUTLINE",
}

function skin:ApplyCardBackdrop(card)
    local cfg = self.Config
    card:SetBackdrop({
        bgFile = cfg.BackdropBgFile,
        tile = true,
        tileSize = cfg.BackdropTileSize,
        edgeFile = cfg.BackdropEdgeFile,
        edgeSize = cfg.BackdropEdgeSize,
        insets = cfg.BackdropInsets,
    })
    card:SetBackdropColor(0, 0, 0, 0.65)
end

function skin:GetCardTitleFont()
    local cfg = self.Config

    return cfg.TitleFont, cfg.TitleFontSize, cfg.TitleFontFlags
end

function skin:GetStatFrameFonts()
    return "GameFontNormalSmall", "GameFontHighlightSmall"
end

-- =============================
-- =   Character Frame Hooks   =
-- =============================
function skin:OnCharacterFrameShow() end

function skin:OnCharacterFrameHide() end

function skin:OnCharacterFrameTabClick() end

function skin:OnCharacterFrameShowSubFrame() end

local function BCP_AnchorResistanceFrame(infoFrame, aboveSection, cfg)
    BCP_Reparent(CharacterResistanceFrame, infoFrame)
    CharacterResistanceFrame:ClearAllPoints()
    CharacterResistanceFrame:SetPoint("BOTTOM", aboveSection, "TOP", -6, 12)

    local xOffset = 0

    for _, child in ipairs({ CharacterResistanceFrame:GetChildren() }) do
        child:ClearAllPoints()
        child:SetPoint("TOPLEFT", CharacterResistanceFrame, "TOPLEFT", xOffset, 0)

        -- FIX: center the resistance number inside its icon
        for _, region in ipairs({ child:GetRegions() }) do
            if region:GetObjectType() == "FontString" then
                region:ClearAllPoints()
                region:SetPoint("CENTER", child, "CENTER", 0, 0)
                region:SetDrawLayer("OVERLAY")
            end
        end
        xOffset = xOffset + cfg.ResistanceItemWidth + cfg.ResistanceItemSpacing
    end

    CharacterResistanceFrame:SetWidth(xOffset)
    CharacterResistanceFrame:SetHeight(cfg.ResistanceFrameHeight)

    -- FIX: draw above the panel and cards
    CharacterResistanceFrame:SetFrameStrata("HIGH")
end

-- FIX: Outfitter anchors itself to the stock character frame, which is narrower than the stats
-- panel, so it opens on top of it. Anchor it to the right edge of the stats panel instead.
local BCP_OutfitCfg

local function BCP_AnchorOutfitter(cfg)
    local info = BCPVanillaCharacterInformationFrame

    BCP_OutfitCfg = cfg

    if not (OutfitterFrame and info) then
        return
    end

    OutfitterFrame:ClearAllPoints()
    OutfitterFrame:SetPoint("TOPLEFT", info, "TOPRIGHT", cfg.OutfitterOffsetX or 0, cfg.OutfitterOffsetY or 0)

    if not OutfitterFrame.bcpHooked then
        OutfitterFrame.bcpHooked = true

        local origOnShow = OutfitterFrame:GetScript("OnShow")

        OutfitterFrame:SetScript("OnShow", function()
            if origOnShow then
                origOnShow()
            end

            BCP_AnchorOutfitter(cfg)
        end)
    end
end

-- /bcpoutfit x <n> | y <n> : move the Outfitter window live (x > 0 right, y > 0 up). Not saved;
-- tell the number to whoever maintains the file to make it the default.
SLASH_BCPOUTFIT1 = "/bcpoutfit"
SlashCmdList["BCPOUTFIT"] = function(msg)
    local cfg = BCP_OutfitCfg
    local _, _, which, amount = string.find(msg or "", "^(%a+)%s*(-?[%d%.]*)")

    if cfg and (which == "x" or which == "y") and tonumber(amount) then
        if which == "x" then
            cfg.OutfitterOffsetX = tonumber(amount)
        else
            cfg.OutfitterOffsetY = tonumber(amount)
        end
        BCP_AnchorOutfitter(cfg)
    end

    if cfg then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP|r Outfitter offset: x " .. (cfg.OutfitterOffsetX or 0) .. ", y " .. (cfg.OutfitterOffsetY or 0) .. "   (usage: /bcpoutfit x -10, /bcpoutfit y 0)")
    end
end

-- Anchor the stats panel's top and bottom edges independently to PaperDollFrame, so they can be
-- lined up with the window. BCPConfig.InfoAlign holds the user's nudges from /bcpalign.
local BCP_InfoCfg

local function BCP_ApplyInfoFrameAnchors(cfg)
    local info = BCPVanillaCharacterInformationFrame

    if cfg then
        BCP_InfoCfg = cfg
    end

    cfg = BCP_InfoCfg

    if not (info and PaperDollFrame and cfg) then
        return
    end

    local align = (BCPConfig and BCPConfig.InfoAlign) or { Top = 0, Bottom = 0 }
    local top = cfg.InfoFrameTop + (align.Top or 0)
    local bottom = cfg.InfoFrameBottom - (align.Bottom or 0)

    info:ClearAllPoints()
    info:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", cfg.InfoFrameXOffset, top)
    info:SetPoint("BOTTOMLEFT", PaperDollFrame, "BOTTOMLEFT", cfg.InfoFrameXOffset, bottom)
end

SLASH_BCPALIGN1 = "/bcpalign"
SlashCmdList["BCPALIGN"] = function(msg)
    local say = function(text)
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP|r " .. text)
    end

    if not BCPConfig then
        return
    end

    BCPConfig.InfoAlign = BCPConfig.InfoAlign or { Top = 0, Bottom = 0 }

    local align = BCPConfig.InfoAlign
    local _, _, which, amount = string.find(msg or "", "^(%a+)%s*(-?[%d%.]*)")

    if which == "reset" then
        align.Top, align.Bottom = 0, 0
    elseif (which == "top" or which == "bottom") and tonumber(amount) then
        local key = (which == "top") and "Top" or "Bottom"

        align[key] = (align[key] or 0) + tonumber(amount)
    else
        say("/bcpalign top <n>    move the panel's TOP edge up (n>0) or down (n<0)")
        say("/bcpalign bottom <n> move the panel's BOTTOM edge down (n>0) or up (n<0)")
        say("/bcpalign reset      undo all nudges. One unit is about 1 pixel; repeat to keep nudging.")
    end

    BCP_ApplyInfoFrameAnchors()
    say("nudges now: top " .. (align.Top or 0) .. ", bottom " .. (align.Bottom or 0))
end

-- Model viewport size/position. Split out so /bcpmodel can re-apply it live.
local BCP_ModelCfg

function BCP_ApplyModelLayout(cfg)
    BCP_ModelCfg = cfg

    if not (CharacterModelFrame and PaperDollFrame) then
        return
    end

    CharacterModelFrame:ClearAllPoints()

    -- Enlarge the model's viewport and the model together (no cropping), keeping the
    -- frame's centre where the unscaled frame's centre would be.
    local scale = cfg.ModelScale or 1

    if not CharacterModelFrame.bcpOrigW then
        CharacterModelFrame.bcpOrigW = CharacterModelFrame:GetWidth()
        CharacterModelFrame.bcpOrigH = CharacterModelFrame:GetHeight()
    end

    local centerX = cfg.ModelOffsetX + (CharacterModelFrame.bcpOrigW / 2)
    local centerY = cfg.ModelOffsetY - (CharacterModelFrame.bcpOrigH / 2)

    CharacterModelFrame:SetWidth(CharacterModelFrame.bcpOrigW * (cfg.ModelWidthFactor or 1))
    CharacterModelFrame:SetHeight(CharacterModelFrame.bcpOrigH * (cfg.ModelHeightFactor or 1))
    CharacterModelFrame:SetScale(scale)

    -- Scaling the frame also grows the model by roughly scale^2; cancel the extra factor.
    if scale ~= 1 and CharacterModelFrame.SetModelScale then
        CharacterModelFrame:SetModelScale(1 / scale)
    end

    CharacterModelFrame:SetPoint("CENTER", PaperDollFrame, "TOPLEFT", centerX / scale, centerY / scale)
end

-- /bcpmodel <scale> <widthFactor> <heightFactor>   e.g. /bcpmodel 1 1 1 (stock size, cheapest to draw)
-- Live test, not saved. Bigger numbers = more pixels for the 3D model to draw each frame.
SLASH_BCPMODEL1 = "/bcpmodel"
SlashCmdList["BCPMODEL"] = function(msg)
    local cfg = BCP_ModelCfg
    local _, _, a, b, c = string.find(msg or "", "^%s*([%d%.]+)%s+([%d%.]+)%s+([%d%.]+)")

    if cfg and a and tonumber(a) and tonumber(a) > 0 then
        cfg.ModelScale, cfg.ModelWidthFactor, cfg.ModelHeightFactor = tonumber(a), tonumber(b), tonumber(c)
        BCP_ApplyModelLayout(cfg)
    end

    if cfg then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP|r model: scale " .. (cfg.ModelScale or 1) .. ", width " .. (cfg.ModelWidthFactor or 1) .. ", height " .. (cfg.ModelHeightFactor or 1) .. "   (usage: /bcpmodel 1 1 1)")
    end
end

-- ==============================
-- =   Paper Doll Frame Hooks   =
-- ==============================
function skin:OnPaperDollShow()
    local cfg = self.Config

    -- Allows click rotating the character's model instead of using the arrows
    -- Shift the model downward to center it
    if CharacterModelFrame then
        BCPLib:EnableClickRotate(CharacterModelFrame)
        CharacterModelFrame:ClearAllPoints()

        BCP_ApplyModelLayout(cfg)

        -- Model above the paper doll (so it gets clicks) but below the item slots
        BCP_LayerModelBehindSlots()
    end

    local fontScale = (BCPConfig and BCPConfig.StatPanel and BCPConfig.StatPanel.FontScale) or 1.0
    local isWideMode = BCP_IS_USING_BCS and BCPConfig and BCPConfig.StatPanel and BCPConfig.StatPanel.WideMode

    if PaperDollFrame then
        local scaledInfoWidth = math.floor(cfg.InfoFrameWidth * fontScale)
        local resistanceFrameWidth = ((cfg.ResistanceItemWidth + cfg.ResistanceItemSpacing) * 5) -
            cfg.ResistanceItemSpacing

        if scaledInfoWidth <= resistanceFrameWidth then
            scaledInfoWidth = resistanceFrameWidth + 35
        end

        if not BCPVanillaCharacterInformationFrame then
            local infoFrame = CreateFrame("Frame", "BCPVanillaCharacterInformationFrame", PaperDollFrame)
            infoFrame:SetBackdrop({
                bgFile = cfg.BackdropBgFile,
                tile = true,
                tileSize = cfg.BackdropTileSize,
                edgeFile = cfg.BackdropEdgeFile,
                edgeSize = cfg.BackdropEdgeSize,
                insets = cfg.BackdropInsets,
            })
            infoFrame:SetBackdropBorderColor(1, 1, 1, 1)
        end

        if not (isWideMode and BCPVanillaStatsContent and BCPVanillaStatsContent.bcpContentBuilt) then
            BCPVanillaCharacterInformationFrame:SetWidth(scaledInfoWidth)
        end

        BCP_ApplyInfoFrameAnchors(cfg)
    end

    if not BCPVanillaStatsScrollFrame and BCPVanillaCharacterInformationFrame and CharacterResistanceFrame then
        local scrollFrame = CreateFrame("ScrollFrame", "BCPVanillaStatsScrollFrame", BCPVanillaCharacterInformationFrame)
        scrollFrame:EnableMouseWheel(true)

        local contentFrame = CreateFrame("Frame", "BCPVanillaStatsContent", scrollFrame)
        contentFrame:SetHeight(1)
        scrollFrame:SetScrollChild(contentFrame)

        if BCP_IS_USING_BCS then
            local scrollbar = CreateFrame("Slider", "BCPVanillaStatsScrollBar", scrollFrame, "UIPanelScrollBarTemplate")
            scrollbar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -25, -16)
            scrollbar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -25, 16)
            scrollbar:SetMinMaxValues(0, 0)
            scrollbar:SetValueStep(1)
            scrollbar:SetValue(0)

            scrollbar:SetScript("OnValueChanged", function()
                scrollFrame:SetVerticalScroll(scrollbar:GetValue())
            end)

            scrollFrame:SetScript("OnMouseWheel", function()
                local _, maxVal = scrollbar:GetMinMaxValues()
                local newVal = math.max(0, math.min(maxVal, scrollbar:GetValue() + arg1 * -20))
                scrollbar:SetValue(newVal)
            end)
        end

        scrollFrame:SetScript("OnUpdate", function()
            scrollFrame:SetScript("OnUpdate", nil)

            local w = scrollFrame:GetWidth()
            contentFrame:SetWidth(w)

            if BCPVanillaStatsContent and not BCPVanillaStatsContent.bcpContentBuilt then
                BCPVanillaStatsContent.bcpContentBuilt = true
                self:BuildScrollContent()
            end
        end)
    end

    if BCPVanillaStatsScrollFrame and BCPVanillaCharacterInformationFrame then
        local bottomPad = isWideMode and 0 or cfg.ScrollBottomPad

        BCPVanillaStatsScrollFrame:ClearAllPoints()
        BCPVanillaStatsScrollFrame:SetPoint("TOPLEFT", BCPVanillaCharacterInformationFrame, "TOPLEFT", 12,
            -cfg.ScrollTopPad)
        BCPVanillaStatsScrollFrame:SetPoint("BOTTOMRIGHT", BCPVanillaCharacterInformationFrame, "BOTTOMRIGHT",
            isWideMode and -12 or -5, bottomPad)
    end

    if BCPVanillaStatsScrollFrame and CharacterResistanceFrame and not BCPVanillaResistanceAnchored then
        BCP_AnchorResistanceFrame(BCPVanillaCharacterInformationFrame, BCPVanillaStatsScrollFrame, cfg)
        BCPVanillaResistanceAnchored = true
    end

    if CharacterResistanceFrame then
        CharacterResistanceFrame:Show()
    end

    BCP_AnchorOutfitter(cfg)
end

-- ======================================
-- =   Inspect Paper Doll Frame Hooks   =
-- ======================================
function skin:OnInspectShow()
    -- Allows click rotating the character's model instead of using the arrows
    if InspectModelFrame then
        BCPLib:EnableClickRotate(InspectModelFrame)
    end
end

function skin:BuildScrollContent()
    BCP_BuildScrollContent(
        self,
        BCPVanillaStatsContent,
        BCPVanillaStatsScrollFrame,
        BCPVanillaStatsScrollBar,
        "BCPVanillaBCSCard",
        "BCPVanillaBCSCat",
        "BCPVanillaNativeCard"
    )
end
