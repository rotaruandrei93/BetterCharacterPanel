BCPLib = BCPLib or {}

local BS = BCPDBEnchants.Slot

local SlotPermanentEnchants = {
    [BS.Head] = { BCPDBEnchants.HeadPermanentEnchants },
    [BS.Neck] = { BCPDBEnchants.NeckPermanentEnchants },
    [BS.Shoulder] = { BCPDBEnchants.ShoulderPermanentEnchants },
    [BS.Chest] = { BCPDBEnchants.ChestPermanentEnchants },
    [BS.Belt] = { BCPDBEnchants.BeltPermanentEnchants },
    [BS.Legs] = { BCPDBEnchants.LegsPermanentEnchants },
    [BS.Feet] = { BCPDBEnchants.FeetPermanentEnchants },
    [BS.Wrist] = { BCPDBEnchants.WristPermanentEnchants },
    [BS.Hands] = { BCPDBEnchants.HandsPermanentEnchants },
    [BS.Finger1] = { BCPDBEnchants.FingerPermanentEnchants },
    [BS.Finger2] = { BCPDBEnchants.FingerPermanentEnchants },
    [BS.Cloak] = { BCPDBEnchants.CloakPermanentEnchants },
    [BS.MainHand] = { BCPDBEnchants.OneHandedPermanentEnchants, BCPDBEnchants.TwoHandedPermanentEnchants },
    [BS.OffHand] = { BCPDBEnchants.OneHandedPermanentEnchants },
    [BS.Range] = { BCPDBEnchants.RangedPermanentEnchants },
}

-- There are other vanilla realms outside of TWoW; add them here and in the database when found
local function GetRealmPhase(realmName)
    if realmName == "Nordanaar" then
        return BCPDBEnchants.PhaseTWOWNordanaar
    end

    if realmName == "Tel'Abim" then
        return BCPDBEnchants.PhaseTWOWTelAbim
    end

    if realmName == "Ambershire" then
        return BCPDBEnchants.PhaseTWOWAmbershire
    end

    if realmName == "Eversong Wilds" then
        return BCPDBEnchants.PhaseTWOWEversongWilds
    end

    return nil
end

-- The realm never changes during a session: look its phase table up once.
local cachedRealmPhase = nil
local cachedRealmKnown = false

local function GetCurrentRealmPhase()
    if cachedRealmKnown then
        return cachedRealmPhase, true
    end

    local realm = GetRealmName()

    if not realm or realm == "" then
        return nil, false
    end

    cachedRealmPhase = GetRealmPhase(realm)
    cachedRealmKnown = true

    return cachedRealmPhase, true
end

-- Results of the "is this item missing an enchant?" check, per slot and item id. The answer for a given
-- item in a given slot never changes during a session, so the (long) enchant tables are walked only once.
local MissingEnchantCache = {}

-- Taken from pfUI by Shagu
local function HookScript(f, script, func)
    local prev = f:GetScript(script)

    f:SetScript(script, function(a1, a2, a3, a4, a5, a6, a7, a8, a9)
        if prev then
            prev(a1, a2, a3, a4, a5, a6, a7, a8, a9)
        end

        func(a1, a2, a3, a4, a5, a6, a7, a8, a9)
    end)
end

-- Taken from pfUI by Shagu
local isTurtleWoW = false

function BCPLib:IsPlayingOnTurtleWoW()
    if isTurtleWoW then
        return true
    end

    if not TargetHPText or not TargetHPPercText then
        return false
    end

    isTurtleWoW = true

    return true
end

function BCPLib:GetPermanentEnchantDataFromEnchantId(enchantId)
    local entry = BCPDBEnchants.PermanentEnchants[enchantId]

    if not entry then
        return nil
    end

    return {
        Name = entry[1],
        Effect = entry[2],
    }
end

function BCPLib:GetTemporyEnchantDataFromEnchantId(enchantId)
    local entry = BCPDBEnchants.TemporaryEnchants[enchantId]

    if not entry then
        return nil
    end

    return {
        Name = entry[1],
        Effect = entry[2],
    }
end

-- itemInfo is optional (the GetEquippedItem table, when the caller already has it).
-- Returns: isMissing, complete. "complete" is false when the item data could not be read yet; such an
-- answer must not be remembered by the caller.
function BCPLib:IsEquippedItemMissingPermanentEnchant(unit, slot, itemInfo)
    if slot == BS.Shirt or slot == BS.Trinket1 or slot == BS.Trinket2 or slot == BS.Tabard then
        return false, true
    end

    if not itemInfo then
        itemInfo = GetEquippedItem(unit, slot)
    end

    if not itemInfo then
        return false, true
    end

    if itemInfo.permanentEnchantId and itemInfo.permanentEnchantId ~= 0 then
        return false, true
    end

    local enchantTables = SlotPermanentEnchants[slot]

    if not enchantTables then
        return false, true
    end

    local itemId = itemInfo.itemId
    local slotCache = MissingEnchantCache[slot]

    if not slotCache then
        slotCache = {}
        MissingEnchantCache[slot] = slotCache
    end

    if itemId then
        local cached = slotCache[itemId]

        if cached ~= nil then
            return cached, true
        end
    end

    local realmPhase, realmKnown = GetCurrentRealmPhase()

    local okLevel, itemLevel = pcall(GetItemLevel, itemInfo.itemId)

    if not okLevel then
        return false, false
    end

    itemLevel = itemLevel or 0

    local okSub, itemSubClass = pcall(GetItemStatsField, itemInfo.itemId, "subclass")

    if not okSub then
        return false, false
    end

    local okClass, itemClass = pcall(GetItemStatsField, itemInfo.itemId, "class")

    if not okClass then
        return false, false
    end

    -- Dirty quick hack that offsets by 100 the subclass to share one item-type namespace with weapons
    if itemClass == 4 and itemSubClass then
        itemSubClass = itemSubClass + 100
    end

    local result = false
    local isTurtle = BCPLib:IsPlayingOnTurtleWoW()

    for _, enchantTable in ipairs(enchantTables) do
        for _, enchantData in pairs(enchantTable) do
            local itemTypes = enchantData[1]
            local itemLevelReq = enchantData[2]
            local phaseLocked = enchantData[3]
            local turtleWoWOnly = enchantData[4]

            if not turtleWoWOnly or isTurtle then
                local phaseOk = true

                if phaseLocked then
                    phaseOk = realmPhase ~= nil and realmPhase[phaseLocked] == true
                end

                if phaseOk and itemLevel >= itemLevelReq then
                    local itemTypeOk = true

                    if itemTypes and table.getn(itemTypes) > 0 then
                        itemTypeOk = false

                        for _, requiredType in ipairs(itemTypes) do
                            if itemSubClass == requiredType then
                                itemTypeOk = true
                                break
                            end
                        end
                    end

                    if itemTypeOk then
                        result = true
                        break
                    end
                end
            end
        end

        if result then
            break
        end
    end

    -- Only remember answers that were worked out with complete information
    if itemId and realmKnown then
        slotCache[itemId] = result
    end

    return result, realmKnown
end

function BCPLib:GetItemLevelFromEquipmentSlot(unit, slot)
    local okEquippedItem, itemInfo = pcall(GetEquippedItem, unit, slot)

    if not okEquippedItem or not itemInfo then
        return nil
    end

    local okItemLevel, result = pcall(GetItemLevel, itemInfo.itemId)

    if not okItemLevel then
        return nil
    end

    return result
end

function BCPLib:GetColorFromEquipmentSlot(unit, slot)
    local itemInfo = GetEquippedItem(unit, slot)

    if not itemInfo then
        return nil
    end

    local ok, quality = pcall(GetItemStatsField, itemInfo.itemId, "quality")

    if not ok then
        return nil
    end

    if quality == 0 then     -- Poor
        return "|cff9d9d9d"
    elseif quality == 1 then -- Common
        return "|cffffffff"
    elseif quality == 2 then -- Uncommon
        return "|cff1eff00"
    elseif quality == 3 then -- Rare
        return "|cff0070dd"
    elseif quality == 4 then -- Epic
        return "|cffa335ee"
    else                     -- Legendary
        return "|cffff8000"
    end
end

-- Taken from pfUI by Shagu
-- Installed only once per frame: this is called every time a window opens, and each call used to wrap the
-- frame's OnUpdate in one more layer, so the per-frame work grew with every open.
-- PERF: the rotating OnUpdate is attached only while the mouse button is held (OnMouseDown) and removed on
-- release (OnMouseUp / OnHide), so an idle model costs no Lua call per frame at all.
function BCPLib:EnableClickRotate(frame)
    if frame.bcpClickRotate then
        return
    end

    frame.bcpClickRotate = true
    frame:EnableMouse(true)

    -- whatever OnUpdate the frame already had (kept running, and put back when the drag ends)
    local prevUpdate = frame:GetScript("OnUpdate")

    local function RotateOnUpdate()
        if prevUpdate then
            prevUpdate()
        end

        if not this.rotate then
            return
        end

        local x = GetCursorPosition()
        local curx = this.curx

        if curx and curx ~= x then
            this.rotation = (this.rotation or 0) + (x - curx) * 0.025
            this:SetRotation(this.rotation)
        end

        this.curx = x
    end

    local function StopRotate()
        this.rotate, this.curx = nil, nil
        this:SetScript("OnUpdate", prevUpdate)
    end

    HookScript(frame, "OnMouseDown", function()
        if arg1 == "LeftButton" then
            this.rotate = true
            this.curx = GetCursorPosition()
            this:SetScript("OnUpdate", RotateOnUpdate)
        end
    end)

    HookScript(frame, "OnMouseUp", StopRotate)

    -- A window closed in the middle of a drag must not start spinning by itself when it opens again
    HookScript(frame, "OnHide", function()
        if this.rotate then
            StopRotate()
        end
    end)
end

function BCPLib:IsUsingTwoHandedWeapon(unit)
    local okInfo, itemInfo = pcall(GetEquippedItem, unit, BS.MainHand)

    if not okInfo or not itemInfo then
        return false
    end

    local okType, inventoryType = pcall(GetItemStatsField, itemInfo.itemId, "inventoryType")

    if not okType or not inventoryType then
        return nil
    end

    if inventoryType == 17 then
        return true
    end

    return false
end
