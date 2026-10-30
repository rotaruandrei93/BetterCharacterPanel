-- Re-parent a stock Blizzard frame, remembering its original parent so it can be put back before the UI
-- is torn down (/reload, logout). Stock frames still parented to addon-created frames at that point can
-- crash the 1.12 client.
BCP_ReparentedFrames = BCP_ReparentedFrames or {}

function BCP_Reparent(frame, newParent)
    if not frame then
        return
    end

    if not frame.bcpOrigParent then
        frame.bcpOrigParent = frame:GetParent()
        table.insert(BCP_ReparentedFrames, frame)
    end

    frame:SetParent(newParent)
end

-- SetFont only when the font actually changed. Calling it again with the same values on every refresh makes
-- the client look up / rebuild font textures needlessly, which stresses the renderer.
function BCP_SetFontOnce(fs, path, size, flags)
    -- Whole pixel sizes only: every distinct size builds its own font texture.
    if type(size) == "number" then
        size = math.floor(size + 0.5)
    end

    if fs.bcpFontPath ~= path or fs.bcpFontSize ~= size or fs.bcpFontFlags ~= flags then
        fs.bcpFontPath, fs.bcpFontSize, fs.bcpFontFlags = path, size, flags
        fs:SetFont(path, size, flags)
    end
end

local BCP_LogoutFrame = CreateFrame("Frame")
BCP_LogoutFrame:RegisterEvent("PLAYER_LOGOUT")
BCP_LogoutFrame:SetScript("OnEvent", function()
    for _, f in ipairs(BCP_ReparentedFrames) do
        if f.bcpOrigParent then
            f:SetParent(f.bcpOrigParent)
        end
    end
end)

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
                    BCP_SetFontOnce(permFS, fontPath, fontSize * fontScale, fontFlags)
                end
            end

            if tempFS then
                local fontPath, fontSize, fontFlags = tempFS:GetFont()
                if fontPath and fontSize then
                    BCP_SetFontOnce(tempFS, fontPath, fontSize * fontScale, fontFlags)
                end
            end
        end
    end

    initialized[prefix] = true
end

-- itemInfo: pass the already fetched GetEquippedItem() table (or false for "no item") to avoid a second
-- lookup; leave it nil to have it fetched here.
-- Returns: permText, tempText, isMissing, complete. "complete" is false when item data was not available
-- yet, so the caller must not cache the result.
local function GetEnchantTexts(unit, slotId, libSlot, itemInfo)
    if itemInfo == nil then
        itemInfo = GetEquippedItem(unit, slotId)
    end

    if not itemInfo then
        return "", "", false, true
    end

    local permText = ""
    local isMissing = false
    local complete = true
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

        if not ok then
            complete = false
        elseif quality and quality >= BCPConfig.MissingEnchants.MinimumQuality then
            isMissing, complete = BCPLib:IsEquippedItemMissingPermanentEnchant(unit, libSlot, itemInfo)
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

    return permText, tempText, isMissing, complete
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

-- ---------------------------------------------------------------------------------------------------------
-- Stat row text proxies.
-- Better Character Stats writes every row through label:SetText() / text:SetText(). Each SetText makes the
-- client measure and rebuild the string, even when the text did not change, and this addon used to clear all
-- 72 strings first and let BCS write them again (two rebuilds per string per refresh). The proxy forwards
-- everything to the real FontString, but skips SetText when the text is the same, and remembers in which
-- refresh ("generation") it was last written so rows BCS did not write can be blanked afterwards.
-- ---------------------------------------------------------------------------------------------------------
local BCP_TextGen = 0

local BCP_TextProxyMeta = {
    __index = function(t, key)
        local fs = t.bcpFS
        local value = fs[key]

        if type(value) ~= "function" then
            return value
        end

        local cache = t.bcpCache
        local wrapped = cache[key]

        if not wrapped then
            wrapped = function(_, a1, a2, a3, a4, a5, a6)
                return value(fs, a1, a2, a3, a4, a5, a6)
            end

            cache[key] = wrapped
        end

        return wrapped
    end,
}

local function BCP_MakeTextProxy(fs)
    local proxy = { bcpFS = fs, bcpCache = {}, bcpGen = 0, bcpText = nil }

    proxy.SetText = function(self, text)
        if text == nil then
            text = ""
        end

        self.bcpGen = BCP_TextGen

        if self.bcpText ~= text then
            self.bcpText = text
            fs:SetText(text)
        end
    end

    return setmetatable(proxy, BCP_TextProxyMeta)
end

-- ---------------------------------------------------------------------------------------------------------
-- Stat row tooltips.
-- BCS gives every stat row its own OnUpdate (36 Lua calls per frame while the window is open) only to redraw
-- the tooltip every 0.2s while the mouse is over the row. We remove those and run ONE shared updater that
-- exists only while a row's tooltip is actually showing.
-- ---------------------------------------------------------------------------------------------------------
local BCP_TipFrame = CreateFrame("Frame")
local BCP_TipRow, BCP_TipTimer = nil, 0

local function BCP_TipOnUpdate()
    BCP_TipTimer = BCP_TipTimer - arg1

    if BCP_TipTimer > 0 then
        return
    end

    BCP_TipTimer = 0.2

    local row = BCP_TipRow

    -- IsShown() as well: a tooltip that was hidden must never be brought back by the refresher
    if not (row and row:IsVisible() and GameTooltip:IsShown() and GameTooltip:IsOwned(row)) then
        BCP_TipRow = nil
        BCP_TipFrame:SetScript("OnUpdate", nil)
        return
    end

    local base = row.bcpEnterBase

    if base then
        local previousThis = this

        this = row
        base()
        this = previousThis
    end
end

local function BCP_RowOnEnter()
    local base = this.bcpEnterBase

    if base then
        base()
    end

    BCP_TipRow = this
    BCP_TipTimer = 0.2
    BCP_TipFrame:SetScript("OnUpdate", BCP_TipOnUpdate)
end

-- Called after BCS filled a stat row: drop its per-frame OnUpdate and route its OnEnter through ours.
local function BCP_TidyStatRow(row)
    if row:GetScript("OnUpdate") then
        row:SetScript("OnUpdate", nil)
    end

    local onEnter = row:GetScript("OnEnter")

    if onEnter and onEnter ~= BCP_RowOnEnter then
        row.bcpEnterBase = onEnter
        row:SetScript("OnEnter", BCP_RowOnEnter)
    end
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
    BCP_SetFontOnce(label, lFontPath, baseLabelSize * fontScale, lFontFlags)
    _G[name .. "Label"] = BCP_MakeTextProxy(label)

    local valueText = textParent:CreateFontString(nil, "OVERLAY", valueFontTemplate)
    valueText:SetPoint("RIGHT", frame, "RIGHT", -rightPad, 0)
    valueText:SetWidth(valueWidth)
    valueText:SetJustifyH("RIGHT")

    local baseValueSize = cfg.StatValueFontSize or 10
    local vFontPath, _, vFontFlags = valueText:GetFont()
    BCP_SetFontOnce(valueText, vFontPath, baseValueSize * fontScale, vFontFlags)
    _G[name .. "StatText"] = BCP_MakeTextProxy(valueText)

    return frame
end

local BCP_BCSRefreshing = false
local BCP_BCSDirty = false
local BCP_QueueRefresh -- defined further down; declared here so earlier functions can call it

local BCP_BCSForce = false -- true while a refresh needs BCS to recalculate right now (not throttled)

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
        -- protected, so a failing BCS can never leave the refreshing flag stuck on
        BCP_BCSForce = true
        pcall(BCS.UpdateStats, BCS)
        BCP_BCSForce = false
    end

    if BCS then
        BCS.needScanSkills = true
        BCS:GetMHWeaponSkill()
        BCS:GetOHWeaponSkill()
        BCS:GetRangedWeaponSkill()
        BCS.needScanSkills = false
    end

    for _, sectionInfo in ipairs(BCP_BCSSectionPrefixes) do
        local labels = sectionInfo.labels

        if not labels then
            labels, sectionInfo.values, sectionInfo.rows = {}, {}, {}

            for j = 1, 6 do
                labels[j] = getglobal(sectionInfo.prefix .. j .. "Label")
                sectionInfo.values[j] = getglobal(sectionInfo.prefix .. j .. "StatText")
                sectionInfo.rows[j] = getglobal(sectionInfo.prefix .. j)
            end

            -- Only keep the lookup once the rows really exist
            if labels[1] then
                sectionInfo.labels = labels
            else
                sectionInfo.values, sectionInfo.rows = nil, nil
            end
        end

        local values = sectionInfo.values
        local rows = sectionInfo.rows

        BCP_TextGen = BCP_TextGen + 1
        local gen = BCP_TextGen

        pcall(BCS.UpdatePaperdollStats, BCS, sectionInfo.prefix, sectionInfo.categoryKey)

        for j = 1, 6 do
            local lbl = labels[j]
            local val = values and values[j]
            local row = rows and rows[j]

            -- rows BCS did not write this time are blanked (same end result as clearing first, but the
            -- strings that did get written are only rebuilt when their text really changed)
            if lbl and lbl.bcpFS and lbl.bcpGen ~= gen then
                lbl:SetText("")
            end

            if val and val.bcpFS and val.bcpGen ~= gen then
                val:SetText("")
            end

            if row then
                BCP_TidyStatRow(row)
            end
        end
    end

    if BCSFrame then
        BCSFrame:Hide()
    end

    BCP_BCSRefreshing = false
end

-- BCS recalculates (scans gear/auras/talents and rewrites every stat) on every aura, talent, skill or gear
-- event, often several per second. The first request runs immediately; further ones inside a short window
-- are merged into one trailing run, so a burst of events costs one recalculation instead of one per event.
local BCP_BCS_THROTTLE = 0.15
local BCP_BCSLastRun = 0
local BCP_BCSPending = false
local BCP_BCSTimerFrame = CreateFrame("Frame")
local BCP_OrigBCSUpdateStats

local function BCP_BCSRunNow(self)
    BCP_BCSLastRun = GetTime()
    BCP_BCSPending = false

    BCP_OrigBCSUpdateStats(self)
    BCP_RefreshBCSSections(true)
end

local function BCP_BCSTrailingOnUpdate()
    if GetTime() - BCP_BCSLastRun < BCP_BCS_THROTTLE then
        return
    end

    BCP_BCSTimerFrame:SetScript("OnUpdate", nil)

    if not BCP_BCSPending then
        return
    end

    if PaperDollFrame and PaperDollFrame:IsVisible() and BCS then
        BCP_BCSRunNow(BCS)
    else
        -- window closed meanwhile: catch up when it opens
        BCP_BCSPending = false
        BCP_BCSDirty = true
    end
end

local function BCP_BCSUpdateStatsHook(self)
    -- Nothing to redraw while the window is closed; remember it and catch up when it opens.
    if not (PaperDollFrame and PaperDollFrame:IsVisible()) then
        BCP_OrigBCSUpdateStats(self)
        BCP_BCSDirty = true
        return
    end

    if BCP_BCSForce or (GetTime() - BCP_BCSLastRun) >= BCP_BCS_THROTTLE then
        BCP_BCSRunNow(self)
    else
        BCP_BCSPending = true
        BCP_BCSTimerFrame:SetScript("OnUpdate", BCP_BCSTrailingOnUpdate)
    end
end

local function BCP_InstallBCSHook()
    if BCP_OrigBCSUpdateStats or not BCS then
        return
    end

    BCP_OrigBCSUpdateStats = BCS.UpdateStats
    BCS.UpdateStats = BCP_BCSUpdateStatsHook
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

            -- pfUI draws its card backdrop as a child frame that would dim the text, so there the text lives
            -- in its own frame above it. With the default UI the backdrop belongs to the card itself and the
            -- text can be drawn straight on the card: one frame less per card inside the scroll area.
            local textHost = card

            if BCP_IS_USING_PFUI then
                textHost = CreateFrame("Frame", nil, card)
                textHost:SetAllPoints(card)
                textHost:SetFrameLevel(card:GetFrameLevel() + 2)
                card.bcpTextFrame = textHost
            end

            local title = textHost:CreateFontString(nil, "OVERLAY")
            local fontPath, fontSize, fontFlags = skin:GetCardTitleFont()
            BCP_SetFontOnce(title, fontPath, math.floor(fontSize * fontScale), fontFlags)
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
            BCP_InstallBCSHook()
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

            local textHost = card

            if BCP_IS_USING_PFUI then
                textHost = CreateFrame("Frame", nil, card)
                textHost:SetAllPoints(card)
                textHost:SetFrameLevel(card:GetFrameLevel() + 2)
            end

            local titleFS = textHost:CreateFontString(nil, "OVERLAY")
            local fontPath, fontSize, fontFlags = skin:GetCardTitleFont()
            BCP_SetFontOnce(titleFS, fontPath, math.floor(fontSize * fontScale), fontFlags)
            titleFS:SetPoint("TOP", card, "TOP", 0, -titleTopPad)
            titleFS:SetWidth(innerWidth)
            titleFS:SetJustifyH("CENTER")
            titleFS:SetTextColor(1, 0.8, 0)
            titleFS:SetText(cardDef.title)

            local rowY = -(titleTopPad + BCP_TITLE_H)

            for _, statFrame in ipairs(cardDef.frames) do
                BCP_Reparent(statFrame, card)
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

    -- The panel width may have changed (wide mode, font scale): put the resistance row back inside it.
    BCP_FitResistanceRow()
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

-- =====================================================
-- =   Resistance icons (shared by every skin)         =
-- =====================================================
-- The row is laid out inside the panel: it is centred between the panel's borders, shrinks (gaps first,
-- then scale) if the panel is too narrow, and steps away from the character window's close button.
-- It stays in the SAME frame strata as the panel (only the frame level is raised), so other windows such
-- as the auction house are drawn over it like over any other part of the character window.
function BCP_SetupResistanceFrame(infoFrame, scrollFrame, cfg)
    local rf = CharacterResistanceFrame

    if not (rf and infoFrame) then
        return
    end

    BCP_Reparent(rf, infoFrame)

    local strata = infoFrame:GetFrameStrata()
    local level = infoFrame:GetFrameLevel() + 20

    rf:SetFrameStrata(strata)
    rf:SetFrameLevel(level)

    if not rf.bcpChildren then
        local list = {}

        for _, child in ipairs({ rf:GetChildren() }) do
            table.insert(list, child)

            -- center the resistance number inside its icon
            for _, region in ipairs({ child:GetRegions() }) do
                if region:GetObjectType() == "FontString" then
                    region:ClearAllPoints()
                    region:SetPoint("CENTER", child, "CENTER", 0, 0)
                    region:SetDrawLayer("OVERLAY")
                end
            end
        end

        rf.bcpChildren = list
    end

    for _, child in ipairs(rf.bcpChildren) do
        child:SetFrameStrata(strata)
        child:SetFrameLevel(level + 1)
    end

    rf.bcpInfo = infoFrame
    rf.bcpCfg = cfg
    rf.bcpScroll = scrollFrame
    rf.bcpFitKey = nil

    BCP_FitResistanceRow()
end

function BCP_FitResistanceRow()
    local rf = CharacterResistanceFrame
    local info = rf and rf.bcpInfo
    local cfg = rf and rf.bcpCfg
    local children = rf and rf.bcpChildren

    if not (info and cfg and children) then
        return
    end

    local n = table.getn(children)

    if n == 0 then
        return
    end

    local infoW = info:GetWidth()

    if not infoW or infoW <= 0 then
        return
    end

    local itemW = cfg.ResistanceItemWidth
    local itemH = cfg.ResistanceFrameHeight
    local gap = cfg.ResistanceItemSpacing
    local prefScale = cfg.ResistanceScale or 1
    local inset = (cfg.ResistanceSideInset or 12) + 4

    -- Real width of the last icon (the stock icons can be wider than the layout width)
    local lastW = children[n]:GetWidth()

    if not lastW or lastW < itemW then
        lastW = itemW
    end

    -- Some skins draw the visible window lower than the info panel's own top edge (the panel "hangs" above
    -- it). Measure how far, so the row is placed inside what the player actually sees.
    local overhang = 0
    local refFn = cfg.ResistanceRefFrame
    local ref = refFn and refFn()

    if ref then
        local ies = info:GetEffectiveScale()
        local res = ref:GetEffectiveScale()
        local it, rt = info:GetTop(), ref:GetTop()

        if ies and ies > 0 and res and it and rt then
            overhang = (it * ies - rt * res) / ies

            if overhang < 0 then
                overhang = 0
            end
        end
    end

    -- Vertical position
    local bandTop = (cfg.ResistanceBandTop or 12) + overhang
    local rowTop

    if cfg.ResistanceTopAlign then
        rowTop = bandTop
    else
        rowTop = bandTop + (((cfg.ScrollTopPad or 45) - bandTop) - itemH) / 2

        if rowTop < bandTop then
            rowTop = bandTop
        end
    end

    -- Make sure the stats area starts below the row (moves it down only when needed)
    local scroll = rf.bcpScroll

    if cfg.ResistanceTopAlign and scroll then
        local needed = math.ceil(rowTop + itemH * prefScale + 4)
        local current = cfg.ScrollTopPadDyn or cfg.ScrollTopPad or 0

        if needed < (cfg.ScrollTopPad or 0) then
            needed = cfg.ScrollTopPad
        end

        if needed ~= current then
            cfg.ScrollTopPadDyn = needed
            scroll:SetPoint("TOPLEFT", info, "TOPLEFT", cfg.ResistanceScrollX or 0, -needed)

            -- The visible stats area just got shorter: let the scroll bar reach the end of the content
            local barName = scroll:GetName() and string.gsub(scroll:GetName(), "ScrollFrame$", "ScrollBar")
            local bar = barName and getglobal(barName)
            local content = scroll:GetScrollChild()

            if bar and bar:IsShown() and content and content.bcpContentBuilt then
                local minV, maxV = bar:GetMinMaxValues()

                bar:SetMinMaxValues(minV, math.max(0, maxV + (needed - current)))
            end
        end
    end

    local leftBound = inset
    local rightBound = infoW - inset

    -- Keep clear of the close button when it sits on top of the panel
    local btn = CharacterFrameCloseButton

    if btn and btn:IsVisible() then
        local ies = info:GetEffectiveScale()
        local il, it = info:GetLeft(), info:GetTop()
        local bl, br, bt, bb = btn:GetLeft(), btn:GetRight(), btn:GetTop(), btn:GetBottom()

        if ies and ies > 0 and il and it and bl and br and bt and bb then
            local bes = btn:GetEffectiveScale()
            local relL = (bl * bes - il * ies) / ies
            local relR = (br * bes - il * ies) / ies
            local relTop = (it * ies - bt * bes) / ies
            local relBottom = (it * ies - bb * bes) / ies

            if relR > 0 and relL < infoW and relBottom > rowTop and relTop < rowTop + itemH then
                if (relL + relR) / 2 >= infoW / 2 then
                    if relL - 3 < rightBound then
                        rightBound = relL - 3
                    end
                elseif relR + 3 > leftBound then
                    leftBound = relR + 3
                end
            end
        end
    end

    local avail = rightBound - leftBound

    if avail < 40 then
        avail = 40
    end

    -- Fit: shrink the gaps first (down to 1), then the whole row
    local scale = prefScale
    local rowW = (n - 1) * (itemW + gap) + lastW

    if rowW * scale > avail then
        local fitGap = (avail / scale - (n - 1) * itemW - lastW) / (n - 1)

        if fitGap >= 1 then
            gap = fitGap
        else
            gap = 1
            rowW = (n - 1) * (itemW + gap) + lastW
            scale = avail / rowW
        end

        rowW = (n - 1) * (itemW + gap) + lastW
    end

    local x = leftBound + (avail - rowW * scale) / 2

    if x < leftBound then
        x = leftBound
    end

    local key = x .. "|" .. rowTop .. "|" .. scale .. "|" .. gap

    if rf.bcpFitKey == key then
        return
    end

    rf.bcpFitKey = key

    rf:SetScale(scale)
    rf:SetWidth(rowW)
    rf:SetHeight(itemH)
    rf:ClearAllPoints()
    rf:SetPoint("TOPLEFT", info, "TOPLEFT", x / scale, -rowTop / scale)

    for i, child in ipairs(children) do
        child:ClearAllPoints()
        child:SetPoint("TOPLEFT", rf, "TOPLEFT", (i - 1) * (itemW + gap), 0)
    end
end

-- Frame positions are only known a frame after a window is shown, so fit again on the next two frames.
local BCP_FitFrame = CreateFrame("Frame")
local BCP_FitPasses = 0

local function BCP_FitOnUpdate()
    BCP_FitPasses = BCP_FitPasses - 1
    BCP_FitResistanceRow()

    if BCP_FitPasses <= 0 then
        BCP_FitFrame:SetScript("OnUpdate", nil)
    end
end

function BCP_QueueResistanceFit()
    BCP_FitPasses = 2
    BCP_FitFrame:SetScript("OnUpdate", BCP_FitOnUpdate)
end

-- =====================================================
-- =   Outfitter "Enable none" / "Enable all" buttons   =
-- =====================================================
-- Outfitter's own XML names them OutfitterEnableAll (label "Enable none") and OutfitterEnableNone (label
-- "Enable all"). By default they end up on top of the weapon slots. Here they are moved to the header of the
-- character window, one on each side of the name: "Enable none" above the Head slot (top of the left slot
-- column) and "Enable all" above the Hands slot (top of the right slot column).
-- Nothing is searched: only these global names are used. Adjust live with:
--   /bcpbtn <x> <y> [xRight]  x = how far the left button moves right, xRight = how far the right one moves left
--                         (default: same as x), y = height above the slot. Each skin has its own default.
--   /bcpbtn               (status)    /bcpbtn off | on   (leave Outfitter's own position / use ours)    /bcpbtn debug
local BCP_OUTFITTER_BTN_DEFAULT = { X = 0, Y = 38 }

-- Saved /bcpbtn values win; otherwise the active skin's own default (skin.Config.OutfitterButtons); otherwise ours.
local function BCP_OutfitterBtnCfg()
    local saved = BCPConfig and BCPConfig.OutfitterTop

    if saved and saved.X then
        return saved
    end

    local skin = BCP_GetActiveSkin()

    return (skin and skin.Config and skin.Config.OutfitterButtons) or BCP_OUTFITTER_BTN_DEFAULT
end

local function BCP_OutfitterBtnWanted()
    local cfg = BCPConfig and BCPConfig.OutfitterTop

    return not (cfg and cfg.Off)
end

local BCP_EnsureBtnEnforcer -- defined below; the enforcer only exists once Outfitter's buttons do

function BCP_PlaceOutfitterButtons()
    local left = getglobal("OutfitterEnableAll")
    local right = getglobal("OutfitterEnableNone")
    local leftSlot = getglobal("CharacterHeadSlot")
    local rightSlot = getglobal("CharacterHandsSlot")

    if not (left and right and leftSlot and rightSlot) or not BCP_OutfitterBtnWanted() then
        return
    end

    local c = BCP_OutfitterBtnCfg()
    local xLeft = c.X or 0
    local xRight = c.XR or xLeft
    local y = c.Y or 38

    BCP_BtnPlaceCount = (BCP_BtnPlaceCount or 0) + 1

    -- Optional per-skin button size (skin.Config.OutfitterButtons.W / .H), for tight headers.
    if c.W and c.H then
        left:SetWidth(c.W)
        left:SetHeight(c.H)
        right:SetWidth(c.W)
        right:SetHeight(c.H)
    end

    left:ClearAllPoints()
    left:SetPoint("BOTTOMLEFT", leftSlot, "TOPLEFT", xLeft, y)

    right:ClearAllPoints()
    right:SetPoint("BOTTOMRIGHT", rightSlot, "TOPRIGHT", -xRight, y)

    -- Outfitter may place them again when these windows open, so place them again right after.
    local frames = { OutfitterFrame, OutfitterSlotEnables }

    for _, f in ipairs(frames) do
        if f and not f.bcpBtnHooked then
            f.bcpBtnHooked = true

            local origOnShow = f:GetScript("OnShow")

            f:SetScript("OnShow", function()
                if origOnShow then
                    origOnShow()
                end

                BCP_PlaceOutfitterButtons()
            end)
        end
    end

    BCP_EnsureBtnEnforcer()
end

-- Something else (Outfitter or the UI skin) may move the buttons again after we placed them. While they
-- are visible, check them a few times a second (two cheap anchor reads) and put them back if their anchor
-- is not ours.
-- PERF: the enforcer frame is only created once Outfitter's buttons really exist. Without Outfitter there is
-- nothing to enforce, so no OnUpdate runs at all (it used to run on every frame of an open character window).
-- It is a child of PaperDollFrame, so the client only runs its OnUpdate while the paper doll is visible.
local BCP_BtnEnforcer
local BCP_BtnElapsed = 0
local BCP_BtnLeft, BCP_BtnRight, BCP_BtnLeftSlot, BCP_BtnRightSlot

local function BCP_BtnEnforcerOnUpdate()
    BCP_BtnElapsed = BCP_BtnElapsed + arg1

    if BCP_BtnElapsed < 0.25 then
        return
    end

    BCP_BtnElapsed = 0

    if not (BCP_BtnLeft:IsVisible() and BCP_OutfitterBtnWanted()) then
        return
    end

    local _, relLeft = BCP_BtnLeft:GetPoint()
    local _, relRight = BCP_BtnRight:GetPoint()

    if relLeft ~= BCP_BtnLeftSlot or relRight ~= BCP_BtnRightSlot then
        BCP_PlaceOutfitterButtons()
    end
end

BCP_EnsureBtnEnforcer = function()
    if BCP_BtnEnforcer or not PaperDollFrame then
        return
    end

    BCP_BtnLeft = getglobal("OutfitterEnableAll")
    BCP_BtnRight = getglobal("OutfitterEnableNone")
    BCP_BtnLeftSlot = getglobal("CharacterHeadSlot")
    BCP_BtnRightSlot = getglobal("CharacterHandsSlot")

    if not (BCP_BtnLeft and BCP_BtnRight and BCP_BtnLeftSlot and BCP_BtnRightSlot) then
        return
    end

    BCP_BtnEnforcer = CreateFrame("Frame", nil, PaperDollFrame)
    BCP_BtnEnforcer:SetScript("OnUpdate", BCP_BtnEnforcerOnUpdate)
end

SLASH_BCPBTN1 = "/bcpbtn"
SlashCmdList["BCPBTN"] = function(msg)
    msg = msg or ""

    if not BCPConfig then
        return
    end

    local _, _, x, y, xr = string.find(msg, "^%s*(-?[%d%.]+)%s+(-?[%d%.]+)%s*(-?[%d%.]*)")

    if msg == "reset" then
        BCPConfig.OutfitterTop = nil
    elseif msg == "off" then
        BCPConfig.OutfitterTop = BCPConfig.OutfitterTop or {}
        BCPConfig.OutfitterTop.Off = true
    elseif msg == "on" then
        BCPConfig.OutfitterTop = BCPConfig.OutfitterTop or {}
        BCPConfig.OutfitterTop.Off = nil
    elseif msg == "debug" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP|r placement calls so far: " .. tostring(BCP_BtnPlaceCount or 0) ..
            "  file version: btn-v11")

        local l = getglobal("OutfitterEnableAll")
        local r = getglobal("OutfitterEnableNone")

        for _, b in ipairs({ l, r }) do
            if b then
                local pt, rel, relpt, ox, oy = b:GetPoint()

                DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP|r " .. tostring(b:GetName()) .. ": L=" .. tostring(b:GetLeft()) ..
                    " B=" .. tostring(b:GetBottom()) .. " anchor=" .. tostring(pt) .. " to " .. tostring(rel and rel:GetName()) ..
                    " " .. tostring(relpt) .. " (" .. tostring(ox) .. "," .. tostring(oy) .. ")")
            end
        end
    elseif tonumber(x) and tonumber(y) then
        BCPConfig.OutfitterTop = { X = tonumber(x), Y = tonumber(y), XR = tonumber(xr) }
    end

    BCP_PlaceOutfitterButtons()

    local c = BCP_OutfitterBtnCfg()

    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP|r Outfitter buttons: found=" ..
        tostring((getglobal("OutfitterEnableAll") and getglobal("OutfitterEnableNone")) and true or false) ..
        " slots=" .. tostring((getglobal("CharacterHeadSlot") and getglobal("CharacterHandsSlot")) and true or false) ..
        " active=" .. tostring(BCP_OutfitterBtnWanted()) ..
        "  x " .. (c.X or 0) .. ", xRight " .. (c.XR or c.X or 0) .. ", y " .. (c.Y or 38) ..
        "   (usage: /bcpbtn <x> <y> [xRight] | reset | off | on | debug)")
end

BCP_RefreshCount = {}

-- Widgets per slot, looked up once per panel (instead of 3 string concatenations + global lookups per
-- slot on every refresh), together with what is currently displayed so unchanged slots cost nothing.
local BCP_SlotRefs = {}
local BCP_RefCtx = {}

local function BCP_GetSlotRefs(prefix)
    local refs = BCP_SlotRefs[prefix]

    if refs then
        return refs
    end

    refs = {}

    local found = false

    for i, info in ipairs(BCP_SLOTS) do
        local perm = getglobal(prefix .. info.tag .. "_Perm")
        local temp = getglobal(prefix .. info.tag .. "_Temp")
        local missing = getglobal(prefix .. info.tag .. "_MissingEnchant")

        if perm or temp or missing then
            found = true
        end

        refs[i] = {
            perm = perm,
            temp = temp,
            missing = missing,
            itemId = false,
            permId = false,
            tempId = false,
            settled = false,
        }
    end

    -- Don't keep a lookup made before the XML widgets exist
    if found then
        BCP_SlotRefs[prefix] = refs
    end

    return refs
end

local function BCP_ApplyRef(ref, permText, tempText, showMissing)
    if ref.permText ~= permText then
        ref.permText = permText

        if ref.perm then
            ref.perm:SetText(permText)
        end
    end

    if ref.tempText ~= tempText then
        ref.tempText = tempText

        if ref.temp then
            ref.temp:SetText(tempText)
        end
    end

    if ref.shownMissing ~= showMissing then
        ref.shownMissing = showMissing

        if ref.missing then
            if showMissing then
                ref.missing:Show()
            else
                ref.missing:Hide()
            end
        end
    end
end

local function BCP_Refresh(unit, prefix)
    BCP_RefreshCount[prefix] = (BCP_RefreshCount[prefix] or 0) + 1
    local skin = BCP_GetActiveSkin()
    BCP_Init(prefix, skin.FrameValues)

    local refs = BCP_GetSlotRefs(prefix)
    local cfg = BCPConfig
    local missingCfg = cfg.MissingEnchants
    local showPerm, showTemp

    if unit == "player" then
        showPerm = cfg.PermanentEnchants.ShowOnCharPanel
        showTemp = cfg.TemporaryEnchants.ShowOnCharPanel
    else
        showPerm = cfg.PermanentEnchants.ShowOnInspect
        showTemp = cfg.TemporaryEnchants.ShowOnInspect
    end

    local unitLevel = UnitLevel(unit)

    -- Everything besides the item itself that changes what is shown, folded into one number. When it
    -- changes (a setting was toggled, another level) every slot is worked out again.
    local ctx = (showPerm and 1 or 0) + (showTemp and 2 or 0) + (missingCfg.Show and 4 or 0) +
        (missingCfg.OnlyAtLevel60 and 8 or 0) + (missingCfg.MinimumQuality or 0) * 16 + (unitLevel or 0) * 256

    if BCP_RefCtx[prefix] ~= ctx then
        BCP_RefCtx[prefix] = ctx

        for i = 1, table.getn(refs) do
            refs[i].settled = false
        end
    end

    local canShowMissing = missingCfg.Show and (not missingCfg.OnlyAtLevel60 or (unitLevel and unitLevel == 60))

    for i, info in ipairs(BCP_SLOTS) do
        local ref = refs[i]
        local itemInfo = GetEquippedItem(unit, info.slotId)
        local itemId, permId, tempId = 0, 0, 0

        if itemInfo then
            itemId = itemInfo.itemId or 0
            permId = itemInfo.permanentEnchantId or 0
            tempId = itemInfo.tempEnchantId or 0
        end

        if not ref.settled or ref.itemId ~= itemId or ref.permId ~= permId or ref.tempId ~= tempId then
            local permText, tempText, isMissing, complete = GetEnchantTexts(unit, info.slotId, info.libSlot, itemInfo or false)

            ref.itemId, ref.permId, ref.tempId = itemId, permId, tempId
            ref.settled = complete

            if not showPerm then
                permText = ""
            end

            if not showTemp then
                tempText = ""
            end

            BCP_ApplyRef(ref, permText, tempText, (isMissing and canShowMissing) and true or false)
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
    BCP_HideStockStatPanels()
    BCP_PlaceOutfitterButtons()
    BCP_Refresh("player", "BCP_")

    -- Layout positions settle a frame later, so fit the resistance row now and again right after
    BCP_FitResistanceRow()
    BCP_QueueResistanceFit()

    if BCP_BCSDirty then
        BCP_BCSDirty = false
        BCP_QueueRefresh(false, true)
    end
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

BCP_QueueRefresh = function(items, stats)
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
local BCP_GUIDFallbackTimer = 0

BCP_GUIDFallbackFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")

-- Only attached while a refresh is pending, so it costs nothing the rest of the time.
local function BCP_GUIDFallbackOnUpdate()
    BCP_GUIDFallbackTimer = BCP_GUIDFallbackTimer - arg1

    if BCP_GUIDFallbackTimer > 0 then
        return
    end

    BCP_GUIDFallbackFrame:SetScript("OnUpdate", nil)

    if not PaperDollFrame or not PaperDollFrame:IsVisible() then
        return
    end

    BCP_Refresh("player", "BCP_")

    if BCP_IS_USING_BCS and BCS then
        BCS.needScanGear = true
        BCS.needScanSkills = true
        BCS:UpdateStats()
    end
end

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

    -- Nothing to refresh while the window is closed (it refreshes itself when it opens)
    if not (PaperDollFrame and PaperDollFrame:IsVisible()) then
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

    BCP_GUIDFallbackTimer = 0.2
    BCP_GUIDFallbackFrame:SetScript("OnUpdate", BCP_GUIDFallbackOnUpdate)
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
    local refs = BCP_GetSlotRefs("BCP_Inspect_")

    for i = 1, table.getn(refs) do
        local ref = refs[i]

        -- forget what was shown, so the next refresh works the slot out again
        ref.settled = false
        ref.permText, ref.tempText, ref.shownMissing = nil, nil, nil

        if ref.perm then ref.perm:SetText("") end
        if ref.temp then ref.temp:SetText("") end
        if ref.missing then ref.missing:Hide() end
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

    -- Everything is in place: stop reacting to every target change. ADDON_LOADED stays registered, in case
    -- another addon redefines the inspect window later.
    if BCP_InspectHooksReady and InspectFrame and InspectFrame.bcpHideHooked and InspectPaperDollFrame and
        InspectPaperDollFrame.bcpHideHooked then
        BCP_InspectHookFrame:UnregisterEvent("PLAYER_TARGET_CHANGED")
        BCP_InspectHookFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
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


-- ====================================
-- =   /bcpperf  (what does it cost?) =
-- ====================================
-- Open the Character tab, type /bcpperf and leave the mouse alone for about 20 seconds. Each part of the
-- window is hidden in turn while the frame rate is measured, and the cost of every part is printed in
-- milliseconds per frame. Nothing is changed permanently: everything is shown again at the end (or when you
-- type /bcpperf again, or close the window).
-- Tip: if every line comes out the same, your FPS is being held by VSync or a frame limiter; switch it off
-- while testing.
local BCP_PerfFrame = CreateFrame("Frame")
local BCP_PerfRun = nil

local BCP_PERF_SETTLE = 0.6 -- seconds to let a change settle before counting
local BCP_PERF_LENGTH = 2.5 -- seconds measured per step

local BCP_PERF_PHASES = {
    { name = "everything on", parts = {} },
    { name = "3D character model hidden", parts = { "model" } },
    { name = "stats panel hidden (cards, text, background)", parts = { "stats" } },
    { name = "enchant texts hidden", parts = { "enchants" } },
    { name = "resistance icons hidden", parts = { "resist" } },
    { name = "all of Better Character Panel hidden (model kept)", parts = { "stats", "enchants", "resist" } },
    { name = "everything on again (drift check)", parts = {} },
}

local function BCP_PerfSay(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffBCP perf|r " .. text)
end

local function BCP_PerfFrameFor(part)
    if part == "model" then
        return CharacterModelFrame
    elseif part == "stats" then
        return BCPPFUICharacterInformationFrame or BCPVanillaCharacterInformationFrame
    elseif part == "enchants" then
        return getglobal("BCP")
    elseif part == "resist" then
        return CharacterResistanceFrame
    end

    return nil
end

local function BCP_PerfRestore(run)
    for _, f in ipairs(run.hidden) do
        f:Show()
    end

    run.hidden = {}
end

local function BCP_PerfBegin(run)
    local phase = BCP_PERF_PHASES[run.index]

    run.hidden = {}

    for _, part in ipairs(phase.parts) do
        local f = BCP_PerfFrameFor(part)

        if f and f:IsShown() then
            f:Hide()
            table.insert(run.hidden, f)
        end
    end

    run.phaseStart = GetTime()
    run.measureStart = nil
    run.frames = 0
end

local function BCP_PerfFinish(run)
    local results = run.results
    local count = table.getn(BCP_PERF_PHASES)
    local base = (results[1] + results[count]) / 2
    local lo, hi = results[1], results[1]

    for i = 1, count do
        if results[i] < lo then lo = results[i] end
        if results[i] > hi then hi = results[i] end
    end

    BCP_PerfSay(string.format("everything on: %.1f FPS  (%.2f ms per frame)", base, 1000 / base))

    for i = 2, count - 1 do
        local saved = (1000 / base) - (1000 / results[i])

        BCP_PerfSay(string.format("%s: %.1f FPS  ->  this part costs about %.2f ms per frame", BCP_PERF_PHASES[i].name,
            results[i], saved))
    end

    BCP_PerfSay(string.format("drift between the two 'everything on' runs: %.1f FPS (differences below that are noise)",
        math.abs(results[1] - results[count])))

    if hi - lo < 1.5 then
        BCP_PerfSay("All results are almost identical: your FPS is probably capped (VSync or a frame limiter). Turn it off and run /bcpperf again.")
    end

    BCP_PerfSay("Reference: close the Character window and compare with the FPS you get in the world. To shrink the 3D model use /bcpmodel 1 1 1 (saved; /bcpmodel reset undoes it).")
end

local function BCP_PerfStop(run, reason)
    BCP_PerfFrame:SetScript("OnUpdate", nil)
    BCP_PerfRestore(run)
    BCP_PerfRun = nil

    if reason then
        BCP_PerfSay(reason)
    end
end

local function BCP_PerfOnUpdate()
    local run = BCP_PerfRun

    if not run then
        BCP_PerfFrame:SetScript("OnUpdate", nil)
        return
    end

    if not (PaperDollFrame and PaperDollFrame:IsVisible()) then
        BCP_PerfStop(run, "stopped: the Character window was closed.")
        return
    end

    local now = GetTime()

    if not run.measureStart then
        if now - run.phaseStart >= BCP_PERF_SETTLE then
            run.measureStart = now
            run.frames = 0
        end

        return
    end

    run.frames = run.frames + 1

    local elapsed = now - run.measureStart

    if elapsed < BCP_PERF_LENGTH then
        return
    end

    run.results[run.index] = run.frames / elapsed
    BCP_PerfRestore(run)
    run.index = run.index + 1

    if run.index > table.getn(BCP_PERF_PHASES) then
        BCP_PerfStop(run)
        BCP_PerfFinish(run)
    else
        BCP_PerfBegin(run)
    end
end

SLASH_BCPPERF1 = "/bcpperf"
SlashCmdList["BCPPERF"] = function()
    if BCP_PerfRun then
        BCP_PerfStop(BCP_PerfRun, "cancelled.")
        return
    end

    if not (PaperDollFrame and PaperDollFrame:IsVisible()) then
        BCP_PerfSay("Open the Character window (Character tab) first, then type /bcpperf again.")
        return
    end

    BCP_PerfRun = { index = 1, results = {}, hidden = {} }

    BCP_PerfSay("measuring, about " .. math.floor(table.getn(BCP_PERF_PHASES) * (BCP_PERF_SETTLE + BCP_PERF_LENGTH)) ..
        " seconds. Keep the Character window open and the mouse still. Type /bcpperf again to cancel.")

    BCP_PerfBegin(BCP_PerfRun)
    BCP_PerfFrame:SetScript("OnUpdate", BCP_PerfOnUpdate)
end
