local BS = BCPDBEnchants.Slot

BCP_SLOTS = {
    { tag = "Head",          slotId = BS.Head,     libSlot = BS.Head,     side = "left" },
    { tag = "Neck",          slotId = BS.Neck,     libSlot = BS.Neck,     side = "left" },
    { tag = "Shoulder",      slotId = BS.Shoulder, libSlot = BS.Shoulder, side = "left" },
    { tag = "Back",          slotId = BS.Cloak,    libSlot = BS.Cloak,    side = "left" },
    { tag = "Chest",         slotId = BS.Chest,    libSlot = BS.Chest,    side = "left" },
    { tag = "Wrist",         slotId = BS.Wrist,    libSlot = BS.Wrist,    side = "left",    valuesKey = "Wrists" },
    { tag = "Hands",         slotId = BS.Hands,    libSlot = BS.Hands,    side = "right" },
    { tag = "Waist",         slotId = BS.Belt,     libSlot = BS.Belt,     side = "right" },
    { tag = "Legs",          slotId = BS.Legs,     libSlot = BS.Legs,     side = "right" },
    { tag = "Feet",          slotId = BS.Feet,     libSlot = BS.Feet,     side = "right" },
    { tag = "Finger1",       slotId = BS.Finger1,  libSlot = BS.Finger1,  side = "right",   frameTag = "Finger0" },
    { tag = "Finger2",       slotId = BS.Finger2,  libSlot = BS.Finger2,  side = "right",   frameTag = "Finger1" },
    { tag = "Trinket1",      slotId = BS.Trinket1, libSlot = BS.Trinket1, side = "right",   frameTag = "Trinket0" },
    { tag = "Trinket2",      slotId = BS.Trinket2, libSlot = BS.Trinket2, side = "right",   frameTag = "Trinket1" },
    { tag = "MainHand",      slotId = BS.MainHand, libSlot = BS.MainHand, side = "special", valuesKey = "MainHand" },
    { tag = "SecondaryHand", slotId = BS.OffHand,  libSlot = BS.OffHand,  side = "special", valuesKey = "OffHand" },
    { tag = "Ranged",        slotId = BS.Range,    libSlot = BS.Range,    side = "special", valuesKey = "Ranged" },
}

BCP_STAT_FRAME_H = 11
BCP_CARD_PADDING = 4
BCP_TITLE_H = 16
BCP_CARD_MARGIN = 1

BCP_BCSSectionPrefixes = {}

local BCPActiveSkin = nil

local function BCP_GetActiveSkin()
    if BCPActiveSkin then
        return BCPActiveSkin
    end

    if BCP_IS_USING_PFUI then
        BCPActiveSkin = BCPSkin_pfUI
    else
        BCPActiveSkin = BCPSkin_Vanilla
    end

    return BCPActiveSkin
end

local function BCP_GetSlotFrame(info, prefix)
    local framePrefix = (prefix == "BCP_") and "Character" or "Inspect"
    local frameTag = info.frameTag or info.tag
    return getglobal(framePrefix .. frameTag .. "Slot")
end

local initialized = {}

local function BCP_Init(prefix, frameValues)
    if initialized[prefix] then
        return
    end

    for _, info in ipairs(BCP_SLOTS) do
        local side = info.side
        local slotFrame = BCP_GetSlotFrame(info, prefix)
        local tex = getglobal(prefix .. info.tag .. "_MissingEnchant")

        if tex then
            local sideKey = (side == "left") and "Left" or "Right"
            local anchorCorner = (side == "left") and "TOPRIGHT" or "TOPLEFT"
            local texFile = frameValues[sideKey .. "IconsMissingEnchantTexture"]
            local texSize = frameValues[sideKey .. "IconsMissingEnchantSize"]
            local texOffsets = frameValues[sideKey .. "IconsMissingEnchantOffsets"]

            if texFile then
                tex:SetTexture(texFile)
            end

            if texSize then
                tex:SetWidth(texSize[1])
                tex:SetHeight(texSize[2])
            end

            if texOffsets and slotFrame then
                tex:ClearAllPoints()
                tex:SetPoint(anchorCorner, slotFrame, anchorCorner, texOffsets[1], texOffsets[2])
            end

            tex:SetVertexColor(1, 0, 0, 0.85)
        end

        if side == "left" or side == "right" or (side == "special" and info.valuesKey) then
            local permFS = getglobal(prefix .. info.tag .. "_Perm")
            local tempFS = getglobal(prefix .. info.tag .. "_Temp")

            if info.valuesKey then
                local vKey = info.valuesKey .. "Icon"

                if permFS and slotFrame then
                    local jh = frameValues[vKey .. "PermEnchantTextJustifyH"]
                    local anchors = frameValues[vKey .. "PermEnchantTextAnchors"]
                    local offsets = frameValues[vKey .. "PermEnchantOffsets"]

                    if jh then
                        permFS:SetJustifyH(jh)
                    end

                    if anchors and offsets then
                        permFS:ClearAllPoints()
                        permFS:SetPoint(anchors[1], slotFrame, anchors[2], offsets[1], offsets[2])
                    end
                end

                if tempFS and slotFrame then
                    local jh = frameValues[vKey .. "TempEnchantTextJustifyH"]
                    local anchors = frameValues[vKey .. "TempEnchantTextAnchors"]
                    local offsets = frameValues[vKey .. "TempEnchantOffsets"]

                    if jh then
                        tempFS:SetJustifyH(jh)
                    end

                    if anchors and offsets then
                        tempFS:ClearAllPoints()
                        tempFS:SetPoint(anchors[1], slotFrame, anchors[2], offsets[1], offsets[2])
                    end
                end
            else
                local sideKey = (side == "left") and "Left" or "Right"
                local textAnchor = (side == "left") and "LEFT" or "RIGHT"
                local slotAnchor = (side == "left") and "RIGHT" or "LEFT"
                local permOffsets = frameValues[sideKey .. "IconsPermEnchantOffsets"]
                local tempOffsets = frameValues[sideKey .. "IconsTempEnchantOffsets"]

                if permFS and permOffsets and slotFrame then
                    permFS:ClearAllPoints()
                    permFS:SetPoint(textAnchor, slotFrame, slotAnchor, permOffsets[1], permOffsets[2])
                end

                if tempFS and tempOffsets and slotFrame then
                    tempFS:ClearAllPoints()
                    tempFS:SetPoint(textAnchor, slotFrame, slotAnchor, tempOffsets[1], tempOffsets[2])
                end
            end
        end
    end

    local enchantCfgSection

    if prefix == "BCP_" then
        enchantCfgSection = BCPConfig and BCPConfig.CharacterPanel
    else
        enchantCfgSection = BCPConfig and BCPConfig.InspectPanel
    end

    local fontScale = (enchantCfgSection and enchantCfgSection.EnchantFontScale) or 1.0

    if fontScale ~= 1.0 then
        for _, info in ipairs(BCP_SLOTS) do
            local permFS = getglobal(prefix .. info.tag .. "_Perm")
            local tempFS = getglobal(prefix .. info.tag .. "_Temp")

            if permFS then
                local fontPath, fontSize, fontFlags = permFS:GetFont()
                if fontPath and fontSize then
                    permFS:SetFont(fontPath, fontSize * fontScale, fontFlags)
                end
            end

            if tempFS then
                local fontPath, fontSize, fontFlags = tempFS:GetFont()
                if fontPath and fontSize then
                    tempFS:SetFont(fontPath, fontSize * fontScale, fontFlags)
                end
            end
        end
    end

    initialized[prefix] = true
end

local function GetEnchantTexts(unit, slotId, libSlot)
    local itemInfo = GetEquippedItem(unit, slotId)

    if not itemInfo then
        return "", "", false
    end

    local permText = ""
    local isMissing = false
    local permId = itemInfo.permanentEnchantId

    if permId and permId ~= 0 then
        local ok, data = pcall(BCPLib.GetPermanentEnchantDataFromEnchantId, BCPLib, permId)

        if ok and data and data.Effect then
            permText = "|cff44ee44" .. data.Effect .. "|r"
        else
            permText = "|cff44ee44" .. BCP_ENCHANTED .. "|r"
        end
    else
        local ok, quality = pcall(GetItemStatsField, itemInfo.itemId, "quality")

        if ok and quality and quality >= BCPConfig.MissingEnchants.MinimumQuality then
            isMissing = BCPLib:IsEquippedItemMissingPermanentEnchant(unit, libSlot)
        end
    end

    local tempText = ""
    local tempId = itemInfo.tempEnchantId

    if tempId and tempId ~= 0 then
        local ok, data = pcall(BCPLib.GetTemporyEnchantDataFromEnchantId, BCPLib, tempId)

        if ok and data and data.Effect then
            tempText = "|cffffff44" .. data.Effect .. "|r"
        else
            tempText = "|cffffff44" .. BCP_TEMP_ENCHANT .. "|r"
        end
    end

    return permText, tempText, isMissing
end

function BCP_GetBCSCategoryOrder()
    if not BCP_IS_USING_BCS or not BCS or type(BCS.PLAYERSTAT_DROPDOWN_OPTIONS) ~= "table" then
        return {}
    end

    if type(BCPConfig.StatPanel.CategoryOrder) ~= "table" then
        BCPConfig.StatPanel.CategoryOrder = {}
    end

    local order = BCPConfig.StatPanel.CategoryOrder
    local bcsCats = BCS.PLAYERSTAT_DROPDOWN_OPTIONS

    for i = table.getn(order), 1, -1 do
        local found = false

        for _, cat in ipairs(bcsCats) do
            if order[i] == cat then
                found = true; break
            end
        end

        if not found then
            table.remove(order, i)
        end
    end

    for _, cat in ipairs(bcsCats) do
        local found = false

        for _, oCat in ipairs(order) do
            if oCat == cat then
                found = true; break
            end
        end

        if not found then
            table.insert(order, cat)
        end
    end

    return order
end

function BCP_CreateBCSCompatStatFrame(skin, parent, name, yOffset, cardWidth)
    local cfg = skin.Config
    local fontScale = (BCPConfig and BCPConfig.StatPanel and BCPConfig.StatPanel.FontScale) or 1.0
    local leftPad = cfg.StatLabelLeftPad or 0
    local rightPad = cfg.StatValueRightPad or 0
    local scaledLabelRightPad = math.floor((cfg.StatLabelRightPad or 40) * fontScale)
    local scaledValueWidth = math.floor((cfg.StatValueWidth or 36) * fontScale)
    local labelWidth = cardWidth - scaledLabelRightPad - (BCP_CARD_PADDING * 2) - leftPad
    local valueWidth = scaledValueWidth
    local scaledStatH = math.ceil(BCP_STAT_FRAME_H * fontScale)
    local labelFontTemplate, valueFontTemplate = skin:GetStatFrameFonts()

    local frame = CreateFrame("Frame", name, parent)
    frame:SetWidth(cardWidth - (BCP_CARD_PADDING * 2))
    frame:SetHeight(scaledStatH)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", BCP_CARD_PADDING, -yOffset)
    frame:EnableMouse(true)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- PERF FIX: the text belongs to the card (6 frames), not to each row frame (36 frames). The row
    -- frame is kept only for mouse/tooltips and the text is anchored to it. Drawing text from many
    -- separate frames inside a scroll area cost about half of the FPS.
    -- (the card's text frame sits above the card's own backdrop; pfUI draws its backdrop as a child frame
    -- that would otherwise dim the text)
    local textParent = parent.bcpTextFrame or parent
    local label = textParent:CreateFontString(nil, "OVERLAY", labelFontTemplate)
    label:SetPoint("LEFT", frame, "LEFT", leftPad, 0)
    label:SetWidth(labelWidth)
    label:SetJustifyH("LEFT")
    label:SetTextColor(1, 1, 1)

    local baseLabelSize = cfg.StatLabelFontSize or 10
    local lFontPath, _, lFontFlags = label:GetFont()
    label:SetFont(lFontPath, baseLabelSize * fontScale, lFontFlags)

    _G[name .. "Label"] = label

    local valueText = textParent:CreateFontString(nil, "OVERLAY", valueFontTemplate)
    valueText:SetPoint("RIGHT", frame, "RIGHT", -rightPad, 0)
    valueText:SetWidth(valueWidth)
    valueText:SetJustifyH("RIGHT")

    local baseValueSize = cfg.StatValueFontSize or 10
    local vFontPath, _, vFontFlags = valueText:GetFont()
    valueText:SetFont(vFontPath, baseValueSize * fontScale, vFontFlags)

    _G[name .. "StatText"] = valueText

    return frame
end

local BCP_BCSRefreshing = false

function BCP_RefreshBCSSections(skipBCSUpdate)
    if not BCP_IS_USING_BCS then
        return
    end

    if BCP_BCSRefreshing then
        return
    end

    if table.getn(BCP_BCSSectionPrefixes) == 0 then
        return
    end

    BCP_BCSRefreshing = true

    if BCSFrame then
        BCSFrame:Hide()
    end

    if not skipBCSUpdate then
        BCS:UpdateStats()
    end

    if BCS then
        BCS.needScanSkills = true
        BCS:GetMHWeaponSkill()
        BCS:GetOHWeaponSkill()
        BCS:GetRangedWeaponSkill()
        BCS.needScanSkills = false
    end

    for _, sectionInfo in ipairs(BCP_BCSSectionPrefixes) do
        for j = 1, 6 do
            local lbl = getglobal(sectionInfo.prefix .. j .. "Label")
            local val = getglobal(sectionInfo.prefix .. j .. "StatText")

            if lbl then
                lbl:SetText("")
            end

            if val then
                val:SetText("")
            end
        end

        pcall(BCS.UpdatePaperdollStats, BCS, sectionInfo.prefix, sectionInfo.categoryKey)
    end

    if BCSFrame then
        BCSFrame:Hide()
    end

    BCP_BCSRefreshing = false
end

function BCP_BuildScrollContent(skin, contentFrame, scrollFrame, scrollBar, bcsCardPrefix, bcsCatPrefix, nativeCardPrefix)
    if not contentFrame then
        return
    end

    local infoFrame = scrollFrame and scrollFrame:GetParent()
    local cfg = skin.Config
    local fontScale = (BCPConfig and BCPConfig.StatPanel and BCPConfig.StatPanel.FontScale) or 1.0
    local isWideMode = BCP_IS_USING_BCS and BCPConfig and BCPConfig.StatPanel and BCPConfig.StatPanel.WideMode
    local baseInfoWidth = math.floor(cfg.InfoFrameWidth * fontScale)
    local resistanceFrameWidth = ((cfg.ResistanceItemWidth + cfg.ResistanceItemSpacing) * 5) - cfg.ResistanceItemSpacing
    local paddingAddition = (BCP_IS_USING_PFUI and 15) or 35

    if baseInfoWidth <= resistanceFrameWidth then
        baseInfoWidth = resistanceFrameWidth + paddingAddition
    end

    if infoFrame then
        infoFrame:SetWidth(baseInfoWidth)
    end

    local scrollPaddingX = (BCP_IS_USING_PFUI and 2) or 17
    local contentW = baseInfoWidth - scrollPaddingX
    local maxH = (scrollFrame and scrollFrame:GetHeight()) or 400

    if isWideMode then
        -- FIX: removed the extra +75 so cards wrap to the next column instead of overflowing the panel
    elseif BCP_IS_USING_BCS then
        local scrollbarWidth = (BCP_IS_USING_PFUI and 20) or 25

        contentW = contentW - scrollbarWidth
    end

    contentFrame:SetWidth(contentW)

    local titleTopPad = cfg.StatCardTitleTopPad or BCP_CARD_PADDING
    local bottomPad = cfg.StatCardBottomPad or BCP_CARD_PADDING
    local rowSpacing = cfg.StatRowSpacing or 0
    local columnSpacing = 4
    local cardWidth = contentW - (BCP_CARD_MARGIN * 2)
    local scaledStatH = math.ceil(BCP_STAT_FRAME_H * fontScale)
    local yOffset = 0

    if BCP_IS_USING_BCS then
        local categoryOrder = BCP_GetBCSCategoryOrder()
        local currentX = BCP_CARD_MARGIN
        local currentY = 0

        for i, categoryKey in ipairs(categoryOrder) do
            local rowStep = scaledStatH + rowSpacing
            local cardH = titleTopPad + BCP_TITLE_H + (6 * rowStep) - rowSpacing + bottomPad

            if isWideMode and currentY + cardH > maxH and currentY > 0 then
                currentX = currentX + cardWidth + columnSpacing
                currentY = 0
            end

            local card = CreateFrame("Frame", bcsCardPrefix .. i, contentFrame)
            card:SetWidth(cardWidth)
            card:SetHeight(cardH)
            card:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", currentX, -currentY)

            skin:ApplyCardBackdrop(card)

            local titleFrame = CreateFrame("Frame", nil, card)
            titleFrame:SetAllPoints(card)
            titleFrame:SetFrameLevel(card:GetFrameLevel() + 2)
            card.bcpTextFrame = titleFrame

            local title = titleFrame:CreateFontString(nil, "OVERLAY")
            local fontPath, fontSize, fontFlags = skin:GetCardTitleFont()
            title:SetFont(fontPath, math.floor(fontSize * fontScale), fontFlags)
            title:SetPoint("TOP", card, "TOP", 0, -titleTopPad)
            title:SetWidth(cardWidth - (BCP_CARD_PADDING * 2))
            title:SetJustifyH("CENTER")
            title:SetTextColor(1, 0.8, 0)
            title:SetText(BCS.L[categoryKey] or categoryKey)

            local rowPrefix = bcsCatPrefix .. i .. "_"
            BCP_BCSSectionPrefixes[i] = { prefix = rowPrefix, categoryKey = categoryKey }

            local rowYStart = titleTopPad + BCP_TITLE_H

            for j = 1, 6 do
                BCP_CreateBCSCompatStatFrame(skin, card, rowPrefix .. j, rowYStart + ((j - 1) * rowStep), cardWidth)
            end

            currentY = currentY + cardH + 3
            if not isWideMode then
                yOffset = currentY
            end
        end

        if isWideMode then
            local totalContentWidth = currentX + cardWidth + BCP_CARD_MARGIN
            contentFrame:SetWidth(totalContentWidth)

            if infoFrame then
                -- FIX (Vanilla skin): the scroll area sits 12px in from the left edge but only 5px in from the
                -- right, so the right column ran into the border art. Add 7px so both sides match.
                local wideRightExtra = (not BCP_IS_USING_PFUI) and 7 or 0
                infoFrame:SetWidth(totalContentWidth + scrollPaddingX + wideRightExtra)

                if BCP_IS_USING_PFUI and BCPPFUIUnifiedBackdrop and BCPPFUIUnifiedBackdrop.backdrop then
                    BCPPFUIUnifiedBackdrop.backdrop:SetPoint("BOTTOMRIGHT", -30 + infoFrame:GetWidth() + 5, 72)
                end
            end

            contentFrame:SetHeight(maxH)
        else
            contentFrame:SetWidth(contentW)
            contentFrame:SetHeight(yOffset)

            if BCP_IS_USING_PFUI and BCPPFUIUnifiedBackdrop and BCPPFUIUnifiedBackdrop.backdrop and infoFrame then
                BCPPFUIUnifiedBackdrop.backdrop:SetPoint("BOTTOMRIGHT", -30 + infoFrame:GetWidth() + 5, 72)
            end
        end

        if not contentFrame.bcpHooked then
            contentFrame.bcpHooked = true
            local _Orig_BCS_UpdateStats = BCS.UpdateStats

            BCS.UpdateStats = function(self)
                _Orig_BCS_UpdateStats(self)

                BCP_RefreshBCSSections(true)
            end
        end
    else
        local FRAME_H = math.ceil((cfg.NativeStatRowHeight or BCP_STAT_FRAME_H) * fontScale)
        local cardWidthExtra = cfg.NativeCardWidthExtra or 17
        local cardXOffset = cfg.NativeStatCardXOffset or 0
        local statFrameWidthExtra = cfg.NativeStatFrameWidthExtra or 0
        local statFrameXOffset = cfg.NativeStatFrameXOffset or 0
        local nativeCards = {
            {
                title = "Base Stats",
                frames = {
                    CharacterStatFrame1,
                    CharacterStatFrame2,
                    CharacterStatFrame3,
                    CharacterStatFrame4,
                    CharacterStatFrame5,
                    CharacterArmorFrame,
                },
            },
            {
                title = "Attack Ratings",
                frames = {
                    CharacterAttackFrame,
                    CharacterAttackPowerFrame,
                    CharacterDamageFrame,
                    CharacterRangedAttackFrame,
                    CharacterRangedAttackPowerFrame,
                    CharacterRangedDamageFrame,
                },
            },
        }

        local catTotal = table.getn(nativeCards)
        local innerWidth = cardWidth - (BCP_CARD_PADDING * 2)
        local frameRightPadding = 22
        local calculatedFrameW = (cardWidth + cardWidthExtra) - (BCP_CARD_PADDING + statFrameXOffset) - frameRightPadding +
            statFrameWidthExtra

        for i, cardDef in ipairs(nativeCards) do
            local rowCount = table.getn(cardDef.frames)
            local rowStep = FRAME_H + rowSpacing
            local cardH = titleTopPad + BCP_TITLE_H + (rowCount * rowStep) - rowSpacing + bottomPad

            local card = CreateFrame("Frame", nativeCardPrefix .. i, contentFrame)
            card:SetWidth(cardWidth + cardWidthExtra)
            card:SetHeight(cardH)
            card:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", BCP_CARD_MARGIN + cardXOffset, -yOffset)

            skin:ApplyCardBackdrop(card)

            local titleFrame = CreateFrame("Frame", nil, card)
            titleFrame:SetAllPoints(card)
            titleFrame:SetFrameLevel(card:GetFrameLevel() + 2)

            local titleFS = titleFrame:CreateFontString(nil, "OVERLAY")
            local fontPath, fontSize, fontFlags = skin:GetCardTitleFont()
            titleFS:SetFont(fontPath, math.floor(fontSize * fontScale), fontFlags)
            titleFS:SetPoint("TOP", card, "TOP", 0, -titleTopPad)
            titleFS:SetWidth(innerWidth)
            titleFS:SetJustifyH("CENTER")
            titleFS:SetTextColor(1, 0.8, 0)
            titleFS:SetText(cardDef.title)

            local rowY = -(titleTopPad + BCP_TITLE_H)

            for _, statFrame in ipairs(cardDef.frames) do
                statFrame:SetParent(card)
                statFrame:ClearAllPoints()
                statFrame:SetPoint("TOPLEFT", card, "TOPLEFT", BCP_CARD_PADDING + statFrameXOffset, rowY)
                statFrame:SetWidth(calculatedFrameW)
                statFrame:Show()
                rowY = rowY - rowStep
            end

            yOffset = yOffset + cardH

            if i < catTotal then
                yOffset = yOffset + 3
            end
        end

        contentFrame:SetHeight(yOffset)
    end

    if scrollFrame and scrollBar then
        if isWideMode then
            scrollBar:SetMinMaxValues(0, 0)
            scrollBar:Hide()
        else
            local contentH = contentFrame:GetHeight()
            local frameH = scrollFrame:GetHeight()

            scrollBar:SetMinMaxValues(0, math.max(0, contentH - frameH))
            scrollBar:Show()
        end
    end

    BCP_RefreshBCSSections(false)
end

-- FIX: keep the (enlarged) model frame above PaperDollFrame itself, so it still receives the
-- mouse for click-rotating, but below the item slots, so it never blocks clicks on them.
function BCP_LayerModelBehindSlots()
    if not (PaperDollFrame and CharacterModelFrame) then
        return
    end

    local base = PaperDollFrame:GetFrameLevel()
    local slots = {
        "Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist", "Hands", "Waist",
        "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1", "MainHand", "SecondaryHand",
        "Ranged", "Ammo",
    }

    CharacterModelFrame:SetFrameLevel(base + 1)

    for _, slotName in ipairs(slots) do
        local slot = getglobal("Character" .. slotName .. "Slot")

        if slot then
            slot:SetFrameLevel(base + 3)
        end
    end
end

-- FIX: the empty black panel under the model is a stock stats frame. Hide every candidate,
-- including a skin backdrop, and re-hide it if another addon shows it again.
local function BCP_HideStockStatPanels()
    local names = { "CharacterAttributesFrame", "BetterCharacterAttributesFrame" }

    -- The stray black panel is made of unnamed frames (about 221x77 and 227x82)
    -- directly under PaperDollFrame, found with /bcpfind.
    if PaperDollFrame then
        for _, child in ipairs({ PaperDollFrame:GetChildren() }) do
            local w, h = child:GetWidth(), child:GetHeight()

            if not child:GetName() and w and h and w >= 215 and w <= 232 and h >= 72 and h <= 86 then
                child:Hide()

                if not child.bcpKeepHidden then
                    child.bcpKeepHidden = true

                    local origOnShow = child:GetScript("OnShow")

                    child:SetScript("OnShow", function()
                        if origOnShow then
                            origOnShow()
                        end

                        this:Hide()
                    end)
                end
            end
        end
    end

    for _, name in ipairs(names) do
        local f = getglobal(name)

        if f then
            f:Hide()

            if f.backdrop then
                f.backdrop:Hide()
            end

            if not f.bcpKeepHidden then
                f.bcpKeepHidden = true

                local origOnShow = f:GetScript("OnShow")

                f:SetScript("OnShow", function()
                    if origOnShow then
                        origOnShow()
                    end

                    this:Hide()
                end)
            end
        end
    end
end

BCP_RefreshCount = {}

local function BCP_Refresh(unit, prefix)
    BCP_RefreshCount[prefix] = (BCP_RefreshCount[prefix] or 0) + 1
    local skin = BCP_GetActiveSkin()
    BCP_Init(prefix, skin.FrameValues)

    if prefix == "BCP_" then
        -- Hide the stock stats panels (and keep them hidden if something shows them again)
        BCP_HideStockStatPanels()
    end

    for _, info in ipairs(BCP_SLOTS) do
        local tag = info.tag
        local permText, tempText, isMissing = GetEnchantTexts(unit, info.slotId, info.libSlot)

        local permFS = getglobal(prefix .. tag .. "_Perm")

        if unit == "player" and not BCPConfig.PermanentEnchants.ShowOnCharPanel then
            permText = ""
        end

        if unit ~= "player" and not BCPConfig.PermanentEnchants.ShowOnInspect then
            permText = ""
        end

        if unit == "player" and not BCPConfig.TemporaryEnchants.ShowOnCharPanel then
            tempText = ""
        end

        if unit ~= "player" and not BCPConfig.TemporaryEnchants.ShowOnInspect then
            tempText = ""
        end

        if permFS then
            permFS:SetText(permText)
        end

        local tempFS = getglobal(prefix .. tag .. "_Temp")

        if tempFS then
            tempFS:SetText(tempText)
        end

        local missingTex = getglobal(prefix .. tag .. "_MissingEnchant")
        local unitLevel = UnitLevel(unit)

        if missingTex then
            if isMissing and BCPConfig.MissingEnchants.Show and (not BCPConfig.MissingEnchants.OnlyAtLevel60 or (unitLevel and unitLevel == 60)) then
                missingTex:Show()
            else
                missingTex:Hide()
            end
        end
    end
end


-- =============================
-- =   Character Frame Hooks   =
-- =============================

local _Orig_CharacterFrame_OnShow = CharacterFrame_OnShow

function CharacterFrame_OnShow()
    if _Orig_CharacterFrame_OnShow then
        _Orig_CharacterFrame_OnShow()
    end

    BCP_GetActiveSkin():OnCharacterFrameShow()
end

local _Orig_CharacterFrame_OnHide = CharacterFrame_OnHide

function CharacterFrame_OnHide()
    BCP_GetActiveSkin():OnCharacterFrameHide()

    if _Orig_CharacterFrame_OnHide then
        _Orig_CharacterFrame_OnHide()
    end
end

local _Orig_CharacterFrameTab_OnClick = CharacterFrameTab_OnClick

function CharacterFrameTab_OnClick()
    if _Orig_CharacterFrameTab_OnClick then
        _Orig_CharacterFrameTab_OnClick()
    end

    BCP_GetActiveSkin():OnCharacterFrameTabClick()
end

local _Orig_CharacterFrame_ShowSubFrame = CharacterFrame_ShowSubFrame

function CharacterFrame_ShowSubFrame(arg1)
    BCP_GetActiveSkin():OnCharacterFrameShowSubFrame()

    if _Orig_CharacterFrame_ShowSubFrame then
        _Orig_CharacterFrame_ShowSubFrame(arg1)
    end
end

-- =================================
-- =   Paper Doll Frame Hooks   =
-- =================================

local _Orig_PaperDollFrame_OnShow = PaperDollFrame_OnShow

function PaperDollFrame_OnShow()
    if _Orig_PaperDollFrame_OnShow then
        _Orig_PaperDollFrame_OnShow()
    end

    PaperDollFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

    -- Hide vanilla model rotate buttons
    if CharacterModelFrameRotateLeftButton then
        CharacterModelFrameRotateLeftButton:Hide()
    end

    if CharacterModelFrameRotateRightButton then
        CharacterModelFrameRotateRightButton:Hide()
    end

    -- Hide the default BCS panel
    if BCP_IS_USING_BCS and BCSFrame then
        BCSFrame:Hide()
    end

    BCP_GetActiveSkin():OnPaperDollShow()
    BCP_Refresh("player", "BCP_")
end

local _Orig_PaperDollFrame_OnEvent = PaperDollFrame_OnEvent

-- PERF FIX: every paper doll event used to trigger a full refresh (tooltip scans of all slots plus a
-- full BCS stat recalculation). Events now only set a flag; one refresh runs at most every 0.3s,
-- and only while the window is open.
local BCP_QueueFrame = CreateFrame("Frame")
local BCP_QueueItems, BCP_QueueStats, BCP_QueueTimer = false, false, 0

local function BCP_QueueOnUpdate()
    BCP_QueueTimer = BCP_QueueTimer - arg1

    if BCP_QueueTimer > 0 then
        return
    end

    BCP_QueueFrame:SetScript("OnUpdate", nil)

    local doItems, doStats = BCP_QueueItems, BCP_QueueStats
    BCP_QueueItems, BCP_QueueStats = false, false

    if not (PaperDollFrame and PaperDollFrame:IsVisible()) then
        return
    end

    if doItems then
        BCP_Refresh("player", "BCP_")
    end

    if doStats then
        BCP_RefreshBCSSections(false)
    end
end

local function BCP_QueueRefresh(items, stats)
    if items then BCP_QueueItems = true end
    if stats then BCP_QueueStats = true end

    if not BCP_QueueFrame:GetScript("OnUpdate") then
        BCP_QueueTimer = 0.3
        BCP_QueueFrame:SetScript("OnUpdate", BCP_QueueOnUpdate)
    end
end

function PaperDollFrame_OnEvent(event, arg1)
    if _Orig_PaperDollFrame_OnEvent then
        _Orig_PaperDollFrame_OnEvent(event, arg1)
    end

    if PaperDollFrame:IsVisible() then
        BCP_QueueRefresh(true, false)
    end

    if event == "UNIT_INVENTORY_CHANGED" then
        local inspectUnit = (InspectFrame and InspectFrame.unit and InspectFrame.unit ~= "" and InspectFrame.unit) or "target"

        if arg1 == inspectUnit and InspectPaperDollFrame and InspectPaperDollFrame:IsVisible() then
            BCP_Refresh(inspectUnit, "BCP_Inspect_")
        end

        if arg1 == "player" and PaperDollFrame:IsVisible() then
            BCP_QueueRefresh(false, true)
        end
    end
end

local BCP_GUIDFallbackFrame = CreateFrame("Frame")
local BCP_GUIDFallbackPending = false
local BCP_GUIDFallbackTimer = 0

BCP_GUIDFallbackFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
BCP_GUIDFallbackFrame:SetScript("OnUpdate", function()
    if not BCP_GUIDFallbackPending then
        return
    end

    BCP_GUIDFallbackTimer = BCP_GUIDFallbackTimer - arg1

    if BCP_GUIDFallbackTimer > 0 then
        return
    end

    BCP_GUIDFallbackPending = false

    if not PaperDollFrame or not PaperDollFrame:IsVisible() then
        return
    end

    BCP_Refresh("player", "BCP_")

    if BCP_IS_USING_BCS and BCS then
        BCS.needScanGear = true
        BCS.needScanSkills = true
        BCS:UpdateStats()
    end
end)

BCP_GUIDFallbackFrame:SetScript("OnEvent", function()
    if event ~= "UNIT_INVENTORY_CHANGED" then
        return
    end

    if arg1 == "player" then
        return
    end

    if arg1 == nil then
        return
    end

    local isPlayer = false
    local ok, result = pcall(UnitIsUnit, "player", arg1)

    if ok and result then
        isPlayer = true
    end

    if not isPlayer then
        return
    end

    BCP_GUIDFallbackPending = true
    BCP_GUIDFallbackTimer = 0.2
end)

-- ===========================
-- =   Inspect Frame Hooks   =
-- ===========================

local function BCP_GetInspectUnit()
    if InspectFrame and InspectFrame.unit and InspectFrame.unit ~= "" then
        return InspectFrame.unit
    end

    return "target"
end

function BCP_ClearInspectTexts()
    for _, info in ipairs(BCP_SLOTS) do
        local permFS = getglobal("BCP_Inspect_" .. info.tag .. "_Perm")
        local tempFS = getglobal("BCP_Inspect_" .. info.tag .. "_Temp")
        local missingTex = getglobal("BCP_Inspect_" .. info.tag .. "_MissingEnchant")

        if permFS then permFS:SetText("") end
        if tempFS then tempFS:SetText("") end
        if missingTex then missingTex:Hide() end
    end
end

-- The other player's gear data can arrive a moment after the window opens, so refresh a few more times.
local BCP_InspectRetryFrame = CreateFrame("Frame")
local BCP_InspectRetryElapsed, BCP_InspectRetryStep = 0, 1
local BCP_InspectRetryTimes = { 0.4, 1.0, 2.0, 3.5 }

local function BCP_InspectRetryOnUpdate()
    BCP_InspectRetryElapsed = BCP_InspectRetryElapsed + arg1

    if BCP_InspectRetryElapsed < BCP_InspectRetryTimes[BCP_InspectRetryStep] then
        return
    end

    BCP_InspectRetryStep = BCP_InspectRetryStep + 1

    if InspectPaperDollFrame and InspectPaperDollFrame:IsVisible() then
        BCP_Refresh(BCP_GetInspectUnit(), "BCP_Inspect_")
    end

    if BCP_InspectRetryStep > table.getn(BCP_InspectRetryTimes) or not (InspectPaperDollFrame and InspectPaperDollFrame:IsVisible()) then
        BCP_InspectRetryFrame:SetScript("OnUpdate", nil)
    end
end

function BCP_StartInspectRetry()
    BCP_InspectRetryElapsed, BCP_InspectRetryStep = 0, 1
    BCP_InspectRetryFrame:SetScript("OnUpdate", BCP_InspectRetryOnUpdate)
end

-- Draw the enchant texts above the inspect window's background (pfUI draws that as a child frame, which
-- otherwise dims the text).
local function BCP_FixInspectLayer()
    if not (BCP_Inspect and InspectPaperDollFrame) then
        return
    end

    local top = InspectPaperDollFrame
    local topLevel = top:GetFrameLevel()

    if InspectFrame then
        BCP_Inspect:SetFrameStrata(InspectFrame:GetFrameStrata())
        topLevel = math.max(topLevel, InspectFrame:GetFrameLevel())
    else
        BCP_Inspect:SetFrameStrata(top:GetFrameStrata())
    end

    BCP_Inspect:SetFrameLevel(topLevel + 20)
end

local function BCP_InspectShowBody()
    if InspectModelRotateLeftButton then
        InspectModelRotateLeftButton:Hide()
    end

    if InspectModelRotateRightButton then
        InspectModelRotateRightButton:Hide()
    end

    BCP_GetActiveSkin():OnInspectShow()
    BCP_FixInspectLayer()
    BCP_ClearInspectTexts()
    BCP_Refresh(BCP_GetInspectUnit(), "BCP_Inspect_")
    BCP_StartInspectRetry()
end

-- Never leave the inspected player's enchant texts / red "missing enchant" bars behind.
local function BCP_HookInspectHide(frame)
    if not frame or frame.bcpHideHooked then
        return
    end

    frame.bcpHideHooked = true
    local origOnHide = frame:GetScript("OnHide")

    frame:SetScript("OnHide", function()
        if origOnHide then
            origOnHide()
        end

        BCP_ClearInspectTexts()
    end)
end

-- The inspect window can be created after this file loads (load-on-demand or another addon), and our own
-- BCP_Inspect frame (from the XML) is created after this file too. So the hooks are installed lazily, and
-- again after every addon load, until everything is in place. Safe to call any number of times.
local BCP_InspectShowFn

function BCP_InstallInspectHooks()
    -- 1. Wrap the game's InspectPaperDollFrame_OnShow, even if it was (re)defined after we loaded.
    if InspectPaperDollFrame_OnShow and InspectPaperDollFrame_OnShow ~= BCP_InspectShowFn then
        local orig = InspectPaperDollFrame_OnShow

        BCP_InspectShowFn = function()
            orig()
            BCP_InspectShowBody()
        end

        InspectPaperDollFrame_OnShow = BCP_InspectShowFn
    end

    -- 2. Our enchant texts must live inside the inspect window, so they hide and show with it.
    if BCP_Inspect and InspectPaperDollFrame and BCP_Inspect:GetParent() ~= InspectPaperDollFrame then
        BCP_Inspect:SetParent(InspectPaperDollFrame)
        BCP_Inspect:ClearAllPoints()
        BCP_Inspect:SetAllPoints(InspectPaperDollFrame)
    end

    BCP_FixInspectLayer()

    BCP_HookInspectHide(InspectFrame)
    BCP_HookInspectHide(InspectPaperDollFrame)

    -- 3. Some inspect windows never call InspectPaperDollFrame_OnShow: refresh when our own frame is shown.
    if BCP_Inspect and not BCP_Inspect.bcpShowHooked then
        BCP_Inspect.bcpShowHooked = true
        local origShow = BCP_Inspect:GetScript("OnShow")

        BCP_Inspect:SetScript("OnShow", function()
            if origShow then
                origShow()
            end

            BCP_FixInspectLayer()
            BCP_ClearInspectTexts()
            BCP_Refresh(BCP_GetInspectUnit(), "BCP_Inspect_")
            BCP_StartInspectRetry()
        end)
    end

    BCP_InspectHooksReady = (BCP_Inspect and BCP_Inspect.bcpShowHooked and BCP_InspectShowFn) and true or false
end

local BCP_InspectHookFrame = CreateFrame("Frame")
BCP_InspectHookFrame:RegisterEvent("ADDON_LOADED")
BCP_InspectHookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
BCP_InspectHookFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
BCP_InspectHookFrame:SetScript("OnEvent", function()
    BCP_InstallInspectHooks()
end)

BCP_InstallInspectHooks()

-- ====================================
-- =   /bcpfind  (panel finder)       =
-- ====================================
-- Lists visible frames/textures about the size of the stray black panel.
-- "/bcpfind hide" also hides them until the next /reload.

local function BCP_FindCandidate(obj)
    local w, h = obj:GetWidth(), obj:GetHeight()

    return w and h and w >= 150 and w <= 300 and h >= 40 and h <= 130
end

local function BCP_FindDescribe(obj, parent)
    local name = obj:GetName() or "<anon>"
    local pname = (parent and parent:GetName()) or "<anon>"
    local extra = ""

    if obj:GetObjectType() == "Texture" then
        extra = " tex=" .. tostring(obj:GetTexture())
    end

    return string.format("%s [%s] in %s  %dx%d%s", name, obj:GetObjectType(), pname,
        math.floor(obj:GetWidth() + 0.5), math.floor(obj:GetHeight() + 0.5), extra)
end

local function BCP_FindScan(frame, depth, hide, found)
    if depth > 5 then
        return
    end

    for _, region in ipairs({ frame:GetRegions() }) do
        if region:IsShown() and BCP_FindCandidate(region) then
            DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP|r " .. BCP_FindDescribe(region, frame))
            found.n = found.n + 1

            if hide then
                region:Hide()
            end
        end
    end

    for _, child in ipairs({ frame:GetChildren() }) do
        if child:IsShown() and BCP_FindCandidate(child) then
            DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP|r " .. BCP_FindDescribe(child, frame))
            found.n = found.n + 1

            if hide then
                child:Hide()
            end
        end

        BCP_FindScan(child, depth + 1, hide, found)
    end
end

SLASH_BCPFIND1 = "/bcpfind"
SlashCmdList["BCPFIND"] = function(msg)
    local hide = (msg == "hide")
    local found = { n = 0 }

    if not PaperDollFrame then
        return
    end

    BCP_FindScan(PaperDollFrame, 0, hide, found)

    if found.n == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP|r nothing of that size found. Open the Character tab first.")
    elseif hide then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP|r hid " .. found.n .. " object(s). /reload undoes it.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP|r " .. found.n .. " found. Type /bcpfind hide to hide them.")
    end
end


-- ====================================
-- =   /bcpinspect  (inspect check)   =
-- ====================================
-- Open someone's inspect window, wait a few seconds, then type /bcpinspect and send me the lines it prints.
SLASH_BCPINSPECT1 = "/bcpinspect"
SlashCmdList["BCPINSPECT"] = function()
    local function say(t) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCPi|r " .. t) end
    local function vis(f) if not f then return "nil" end return (f:IsVisible() and "visible" or (f:IsShown() and "shown-but-hidden-parent" or "hidden")) end

    local unit = BCP_GetInspectUnit()
    say("file version: inspect-fix-4   hooks: showHooked=" .. tostring(BCP_Inspect and BCP_Inspect.bcpShowHooked) .. " hideHooked=" .. tostring(InspectFrame and InspectFrame.bcpHideHooked) .. " installed=" .. tostring(BCP_InspectHooksReady) .. " BCP_Inspect parent=" .. tostring(BCP_Inspect and BCP_Inspect:GetParent() and BCP_Inspect:GetParent():GetName()) .. "   refresh runs so far: player=" .. tostring(BCP_RefreshCount["BCP_"]) .. " inspect=" .. tostring(BCP_RefreshCount["BCP_Inspect_"]))

    local ok, err = pcall(BCP_Refresh, unit, "BCP_Inspect_")
    say("forced refresh: " .. (ok and "ran without error" or ("ERROR: " .. tostring(err))))

    say("unit=" .. tostring(unit) .. "  InspectFrame " .. vis(InspectFrame) .. "  InspectPaperDollFrame " .. vis(InspectPaperDollFrame) .. "  BCP_Inspect " .. vis(BCP_Inspect))
    say("ShowOnInspect perm=" .. tostring(BCPConfig and BCPConfig.PermanentEnchants and BCPConfig.PermanentEnchants.ShowOnInspect) .. " temp=" .. tostring(BCPConfig and BCPConfig.TemporaryEnchants and BCPConfig.TemporaryEnchants.ShowOnInspect))

    local shown, withLink, withText = 0, 0, 0
    local firstEnchantLine

    for _, info in ipairs(BCP_SLOTS) do
        local link = GetInventoryItemLink(unit, info.slotId)
        local fs = getglobal("BCP_Inspect_" .. info.tag .. "_Perm")
        local txt = fs and fs:GetText()

        if link then withLink = withLink + 1 end
        if txt and txt ~= "" then withText = withText + 1 end
        if fs and fs:IsVisible() then shown = shown + 1 end

        if link and not firstEnchantLine then
            local perm = GetEnchantTexts(unit, info.slotId, info.libSlot)
            firstEnchantLine = info.tag .. ": link " .. tostring(string.gsub(link, "|", "!")) .. "  ->  enchant text '" .. tostring(perm) .. "'"
        end
    end

    say("slots with item link: " .. withLink .. " / " .. table.getn(BCP_SLOTS) .. ",  enchant texts set: " .. withText .. ",  texts visible: " .. shown)
    if firstEnchantLine then say(firstEnchantLine) end

    local legs = getglobal("BCP_Inspect_Legs_Perm")
    if legs then
        local p, rel, relp, x, y = legs:GetPoint()
        say("Legs text: '" .. tostring(legs:GetText()) .. "' anchored to " .. tostring(rel and rel:GetName()) .. " alpha " .. tostring(legs:GetAlpha()) .. " parent " .. tostring(legs:GetParent() and legs:GetParent():GetName()))
    else
        say("BCP_Inspect_Legs_Perm does not exist")
    end
end
