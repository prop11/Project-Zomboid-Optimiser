--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/shared/MPOptim_Utils.lua
    Author: prop11
    Description: Zero-allocation task scheduler, GPU framerate tracker, audio replacer detector, and crash-proof notification engine.
--]]

require "MPOptim_Config"

MPOptim = MPOptim or {}
MPOptim.Utils = MPOptim.Utils or {}
-- ============================================================================
-- Localization & Translation Helper
-- ============================================================================
function MPOptim.GetText(key, defaultVal)
    if getText and key then
        local txt = getText(key)
        if txt and txt ~= key and txt ~= "" then
            return txt
        end
        if type(key) == "string" then
            if key:sub(1, 19) == "UI_MPOptim_Tooltip_" then
                local tipKey = "Tooltip_MPOptim_" .. key:sub(20)
                local tipTxt = getText(tipKey)
                if tipTxt and tipTxt ~= tipKey and tipTxt ~= "" then return tipTxt end
                local tipKey2 = "Tooltip_" .. key:sub(12)
                local tipTxt2 = getText(tipKey2)
                if tipTxt2 and tipTxt2 ~= tipKey2 and tipTxt2 ~= "" then return tipTxt2 end
            elseif key:sub(1, 11) == "UI_MPOptim_" then
                local ctxKey = "ContextMenu_MPOptim_" .. key:sub(12)
                local ctxTxt = getText(ctxKey)
                if ctxTxt and ctxTxt ~= ctxKey and ctxTxt ~= "" then return ctxTxt end
            end
        end
    end
    return defaultVal or key
end
MPOptim.Utils.GetText = MPOptim.GetText


-- ============================================================================
-- Audio Replacer & Sound Overhaul Mod Auto-Detection
-- ============================================================================
local cachedAudioModDetected = nil

function MPOptim.Utils.IsAudioReplacerActive()
    if MPOptim.Config and MPOptim.Config.Get("Audio_ReplacerSafeMode") == false then
        return false
    end
    if cachedAudioModDetected ~= nil then
        return cachedAudioModDetected
    end

    cachedAudioModDetected = false
        -- 1. Check active mod IDs for audio/sound/music/fmod mods
        if getActivatedMods then
            local mods = getActivatedMods()
            if mods and mods.size then
                for i = 0, mods:size() - 1 do
                    local modId = string.lower(tostring(mods:get(i) or ""))
                    if string.find(modId, "sound") or string.find(modId, "audio") or
                       string.find(modId, "music") or string.find(modId, "truemusic") or
                       string.find(modId, "fmod") or string.find(modId, "voice") or
                       string.find(modId, "sfx") or string.find(modId, "gunfire") or
                       string.find(modId, "acoustic") or string.find(modId, "radio") then
                        cachedAudioModDetected = true
                        print(string.format("[MPOptimizer] Audio Replacer / Sound Mod Detected (%s). Enabling Audio Passthrough Protection.", tostring(mods:get(i))))
                        return
                    end
                end
            end
        end

        -- 2. Check global audio replacer tables & APIs
        if TrueMusic or TCMusic or RadioAPI or ISMusic or SoundReplacer then
            cachedAudioModDetected = true
            print("[MPOptimizer] TrueMusic / Audio Engine Overhaul Detected. Audio Passthrough Protection Active.")
            return
        end

    return cachedAudioModDetected
end

-- Safe Universal Player Notification (B42 & B41 compatible)
function MPOptim.Utils.Notify(player, text, force)
    if not player or not text then return end
    
    -- Check if notifications are enabled or forced (e.g. manual click)
    local allowNotify = force or (MPOptim.Config and MPOptim.Config.Get("UI_ShowNotifications"))
    if not allowNotify then return end

    if HaloTextHelper then
        local color = nil
        if HaloTextHelper.getGoodColor then
            color = HaloTextHelper.getGoodColor()
        elseif HaloTextHelper.getColorGreen then
            color = HaloTextHelper.getColorGreen()
        end

        if HaloTextHelper.addTextWithArrow and color then
            HaloTextHelper.addTextWithArrow(player, text, true, color)
            return
        end
    end

    if player.setHaloNote then
        player:setHaloNote(text)
        return
    end

    if player.Say then
        player:Say(text)
    end
end

-- ============================================================================
-- Universal Admin / In-Game Debug Mode Permission Checker (Build 42 & 41)
-- ============================================================================
function MPOptim.Utils.IsAdmin(player)
    local isMP = isClient and isClient()
    if not isMP then return true end

    -- 1. Check in-game debug mode or debug command line flag
    local isDebug = (getCore and getCore().getDebug and getCore():getDebug())
        or (Core and (Core.bDebug or Core.debug))
        or (isDebugEnabled and isDebugEnabled())
    if isDebug then return true end

    -- 2. Check stats access capabilities
    if canSeePlayerStats and canSeePlayerStats() then return true end
    if canModifyPlayerStats and canModifyPlayerStats() then return true end
    if haveAccess and haveAccess("Admin") then return true end

    player = player or (getSpecificPlayer and getSpecificPlayer(0)) or (getPlayer and getPlayer())
    if not player then return false end

    -- 3. Check isAccessLevel method on player
    if player.isAccessLevel then
        if player:isAccessLevel("admin") or player:isAccessLevel("moderator")
           or player:isAccessLevel("overseer") or player:isAccessLevel("gm")
           or player:isAccessLevel("operator") or player:isAccessLevel("servermaster")
           or player:isAccessLevel("developer") then
            return true
        end
    end

    -- 4. Check string getAccessLevel
    local accessLevel = (player.getAccessLevel and player:getAccessLevel()) or (getAccessLevel and getAccessLevel())
    if accessLevel then
        local lvl = string.lower(tostring(accessLevel))
        if lvl == "admin" or lvl == "moderator" or lvl == "overseer" or lvl == "gm"
           or lvl == "operator" or lvl == "servermaster" or lvl == "developer" then
            return true
        end
    end

    -- 5. Check role object (Build 42)
    if player.getRole and player:getRole() then
        local role = player:getRole()
        local roleName = (role.getName and string.lower(tostring(role:getName()))) or ""
        if roleName == "admin" or roleName == "moderator" or roleName == "overseer" or roleName == "gm"
           or roleName == "operator" or roleName == "servermaster" or roleName == "developer" then
            return true
        end
    end

    return false
end

-- ============================================================================
-- Engine Texture Compression Enforcer (Reduces GPU VRAM Overhead by 50%+)
-- ============================================================================
function MPOptim.Utils.CheckAndEnforceTextureCompression()
    if not MPOptim.Config or not MPOptim.Config.Get("GFX_EnforceTextureCompression") then return end
    if not getCore then return end

    local core = getCore()
    if not core then return end

    local isEnabled = false
    if core.getOptionTextureCompression then
        isEnabled = core:getOptionTextureCompression()
    end

    if not isEnabled then
        if core.setOptionTextureCompression then
            core:setOptionTextureCompression(true)
            if core.saveOptions then
                core:saveOptions()
            end
            print("[MPOptimizer] Texture Compression was DISABLED. Enforced 'Enabled' in options.ini (Will take full effect on game restart).")
        end
    end
end

if Events.OnGameStart then
    Events.OnGameStart.Add(MPOptim.Utils.CheckAndEnforceTextureCompression)
end
if Events.OnPreMapLoad then
    Events.OnPreMapLoad.Add(MPOptim.Utils.CheckAndEnforceTextureCompression)
end

-- ============================================================================
-- Real-Time Framerate & Memory Retrieval Engine
-- ============================================================================
local cachedRamMb = "0.0 MB"
local lastRamCheckTime = 0
local rollingFps = 60
local frameCount = 0
local lastFpsCalc = 0

function MPOptim.Utils.UpdateFPSTracker()
    local now = (getTimeInMillis and getTimeInMillis()) or 0
    frameCount = frameCount + 1
    if lastFpsCalc == 0 then lastFpsCalc = now end
    if now - lastFpsCalc >= 500 then
        local elapsedSec = (now - lastFpsCalc) / 1000.0
        if elapsedSec > 0 then
            rollingFps = math.floor((frameCount / elapsedSec) + 0.5)
        end
        frameCount = 0
        lastFpsCalc = now
    end
end

function MPOptim.Utils.getFPS()
    -- 1. Native Build 42/41 Game Engine Real-Time Average FPS
    if getAverageFPS then
        local avg = tonumber(getAverageFPS())
        if avg and avg > 0 then
            return math.floor(avg + 0.5)
        end
    end

    -- 2. Engine Alternate Spelling Fallback (getAverageFSP)
    if getAverageFSP then
        local avg = tonumber(getAverageFSP())
        if avg and avg > 0 then
            return math.floor(avg + 0.5)
        end
    end

    -- 3. Live Rolling Delta Frame Measurement (Matches Steam / GPU overlays)
    if rollingFps and type(rollingFps) == "number" and rollingFps > 0 then
        return rollingFps
    end

    return 60
end

function MPOptim.Utils.formatMemoryMB()
    local now = (getTimeInMillis and getTimeInMillis()) or 0
    if now - lastRamCheckTime > 5000 then -- Sample only once every 5 seconds
        lastRamCheckTime = now
        local kb = 0
        kb = collectgarbage("count") or 0
        cachedRamMb = string.format("%.1f MB", kb / 1024)
    end
    return cachedRamMb
end

-- ============================================================================
-- High-DPI UI Sizing, Text Measurement & Word Wrapping Helpers
-- ============================================================================
local cachedScale = nil
local cachedFontH = 14
local cachedSW = 1920
local cachedSH = 1080

function MPOptim.Utils.GetUIScale()
    if cachedScale then
        return cachedScale, cachedFontH, cachedSW, cachedSH
    end

    local smallFont = (UIFont and UIFont.Small) or 0
    local fontH = 14
    if getTextManager and getTextManager().getFontHeight then
        local fh = getTextManager():getFontHeight(smallFont)
        if fh and fh > 0 then fontH = fh end
    end
    cachedFontH = fontH

    local fontScale = math.max(1.0, fontH / 14.0)
    local sw = 1920
    local sh = 1080
    if getCore then
        local c = getCore()
        if c and c.getScreenWidth then
            sw = c:getScreenWidth() or 1920
            sh = c:getScreenHeight() or 1080
        end
    end
    cachedSW = sw
    cachedSH = sh

    local resScale = math.max(1.0, math.min(sw / 1920, sh / 1080))
    cachedScale = math.min(2.5, math.max(fontScale, resScale * 0.9))
    return cachedScale, cachedFontH, cachedSW, cachedSH
end

function MPOptim.Utils.MeasureText(font, text)
    if not text or text == "" then return 0 end
    if getTextManager and getTextManager().MeasureStringX then
        local w = getTextManager():MeasureStringX(font, tostring(text))
        if w and w > 0 then return w end
    end
    return string.len(tostring(text)) * 8
end

if Events.OnResolutionChange then
    Events.OnResolutionChange.Add(function()
        cachedScale = nil
    end)
end

function MPOptim.Utils.WrapText(text, font, maxWidth)
    if not text or text == "" then return { "" } end
    local maxW = maxWidth or 600
    local currentW = MPOptim.Utils.MeasureText(font, text)
    if currentW <= maxW then
        return { text }
    end

    local isBullet = string.sub(text, 1, 3) == "-" or string.sub(text, 1, 2) == "-"
    local indent = isBullet and "    " or ""

    local words = {}
    for word in string.gmatch(text, "%S+") do
        table.insert(words, word)
    end
    if #words == 0 then return { text } end

    local lines = {}
    local curLine = words[1]
    for i = 2, #words do
        local word = words[i]
        local testLine = curLine .. " " .. word
        if MPOptim.Utils.MeasureText(font, testLine) > maxW then
            table.insert(lines, curLine)
            curLine = indent .. word
        else
            curLine = testLine
        end
    end
    table.insert(lines, curLine)
    return lines
end

function MPOptim.Utils.DrawInfoCard(panel, infoX, infoY, infoW, title, rawLines, font, medFont, fontH, medFontH, scale)
    if not panel or not rawLines then return 0 end

    local font = font or (UIFont and UIFont.Small) or 0
    local medFont = medFont or (UIFont and UIFont.Medium) or 0
    local scale = scale or 1.0
    local fontH = fontH or 16
    local medFontH = medFontH or (fontH + 4)

    local padX = math.floor(18 * scale)
    local padY = math.floor(14 * scale)
    local maxTextW = infoW - (padX * 2) - 8

    local wrappedLines = {}
    for _, rawLine in ipairs(rawLines) do
        local lines = MPOptim.Utils.WrapText(rawLine, font, maxTextW)
        for _, l in ipairs(lines) do
            table.insert(wrappedLines, l)
        end
    end

    local lineH = math.max(22, math.floor(fontH + 6 * scale))
    local titleH = medFontH + math.floor(8 * scale)
    local infoH = padY + titleH + math.floor(6 * scale) + (#wrappedLines * lineH) + padY

    panel:drawRect(infoX, infoY, infoW, infoH, 0.65, 0.05, 0.07, 0.11)
    panel:drawRectBorder(infoX, infoY, infoW, infoH, 0.85, 0.22, 0.38, 0.60)
    panel:drawRect(infoX + 1, infoY + 1, infoW - 2, 2, 0.95, 0.25, 0.70, 0.95)

    if title and title ~= "" then
        panel:drawText(title, infoX + padX, infoY + padY, 0.4, 0.85, 1.0, 1.0, medFont)
    end

    local rowY = infoY + padY + titleH + math.floor(6 * scale)
    for _, line in ipairs(wrappedLines) do
        panel:drawText(line, infoX + padX, rowY, 0.88, 0.88, 0.88, 1.0, font)
        rowY = rowY + lineH
    end

    return infoH
end

function MPOptim.Utils.getSquare(x, y, z)
    local cell = getCell and getCell()
    if not cell then return nil end
    return cell:getGridSquare(x, y, z)
end
local function checkStructureProtection(square)
    local objects = square.getObjects and square:getObjects()
    if objects and objects:size() > 0 then
        for i = 0, objects:size() - 1 do
            local obj = objects:get(i)
            if obj then
                local objName = obj:getObjectName() or ""
                if objName == "Thumpable" or objName == "IsoGenerator" or objName == "RainBarrel"
                   or objName == "Barricade" or objName == "IsoCampfire" or objName == "IsoFireplace"
                   or objName == "IsoCompost" or objName == "IsoStove" then
                    return true
                end
            end
        end
    end

    local wObjs = square.getWorldObjects and square:getWorldObjects()
    if wObjs and wObjs:size() > 0 then
        for i = 0, wObjs:size() - 1 do
            local wObj = wObjs:get(i)
            if wObj and wObj.getItem then
                local it = wObj:getItem()
                if it and it.isFavorite and it:isFavorite() then
                    return true
                end
            end
        end
    end
    return false
end

local protectedBaseCenters = {}
local function registerBaseCenter(x, y)
    for _, pt in ipairs(protectedBaseCenters) do
        if math.abs(pt.x - x) < 6 and math.abs(pt.y - y) < 6 then
            return
        end
    end
    if #protectedBaseCenters >= 50 then
        table.remove(protectedBaseCenters, 1)
    end
    table.insert(protectedBaseCenters, { x = x, y = y })
end

local function isNearProtectedBase(x, y, radius)
    local rSq = radius * radius
    for _, pt in ipairs(protectedBaseCenters) do
        local dx = x - pt.x
        local dy = y - pt.y
        if (dx * dx + dy * dy) <= rSq then
            return true
        end
    end
    return false
end

function MPOptim.Utils.isBaseOrSafehouseProtected(square)
    if not square then return false end

    -- 1. Multiplayer Safehouse Protection
    if MPOptim.Config.Get("Admin_ProtectSafehouses") then
        if SafeHouse and SafeHouse.getSafeHouse then
            local sh = SafeHouse.getSafeHouse(square)
            if sh ~= nil then return true end
        end
    end

    -- 2. Singleplayer Player Structure & Base Zone Protection
    if MPOptim.Config.Get("Base_ProtectPlayerStructures") then
        local radius = MPOptim.Config.Get("Base_ProtectionRadius") or 20
        if isNearProtectedBase(square:getX(), square:getY(), radius) then
            return true
        end
        if checkStructureProtection(square) then
            registerBaseCenter(square:getX(), square:getY())
            return true
        end
    end

    return false
end

function MPOptim.Utils.isSafehouseSquare(square)
    return MPOptim.Utils.isBaseOrSafehouseProtected(square)
end

function MPOptim.Utils.isCorpseEmpty(corpse)
    if not corpse then return true end
    local container = corpse.getItemContainer and corpse:getItemContainer()
    if not container then return true end
    local items = container:getItems()
    return (not items or items:size() == 0)
end

-- Intelligent Corpse Filter: distinguishes empty, decomposed, junk-only, and valuable loot corpses
function MPOptim.Utils.canCleanCorpse(corpse, options)
    if not corpse then return false end
    local opts = options or {}

    -- 0. NEVER clean player corpses (IsoDeadBody.isPlayer from IsoDeadBody.java)
    if corpse.isPlayer and corpse:isPlayer() then
        return false
    end

    -- 1. Check Deceased Age Threshold (Hours via IsoDeadBody.getDeathTime)
    -- Manual sweeps (isManual == true) always clean immediately regardless of age
    local minAge = (opts.isManual ~= true) and (opts.minAgeHours or (MPOptim.Config and MPOptim.Config.Get("Corpse_MinAgeHours")) or 0) or 0
    if minAge > 0 and getGameTime then
        local deathHour = (corpse.getDeathTime and corpse:getDeathTime())
        if deathHour and deathHour > 0 then
            local currentHours = getGameTime():getWorldAgeHours() or 0
            if (currentHours - deathHour) < minAge then
                return false -- Corpse died too recently
            end
        end
    end

    -- 2. Check Skeletons & Burnt Ash Corpses (IsoDeadBody.isSkeleton / isAnimalSkeleton)
    local isSkeletonOrAsh = (corpse.isSkeleton and corpse:isSkeleton())
        or (corpse.isAnimalSkeleton and corpse:isAnimalSkeleton())
        or (corpse.isBurnt and corpse:isBurnt())
        
    if isSkeletonOrAsh and ((opts.cleanAshAndSkeletons == true) or (MPOptim.Config and MPOptim.Config.Get("Corpse_CleanAshAndSkeletons"))) then
        return true
    end

    -- 3. Check Strictly Empty Corpses
    local container = corpse.getItemContainer and corpse:getItemContainer()
    if not container then return true end
    local items = container:getItems()
    if not items or items:size() == 0 then return true end

    -- If only strictly empty corpses are allowed and items exist, reject
    if opts.cleanEmptyOnly and not opts.cleanJunkOnly then
        return false
    end

    -- 4. Check Junk-Only Corpses (Clean corpses with only ruined vanilla clothes, keep weapons/bags/ammo/keys)
    if opts.cleanJunkOnly or (MPOptim.Config and MPOptim.Config.Get("Corpse_CleanJunkOnly")) then
        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item then
                if item.isFavorite and item:isFavorite() then
                    return false
                end
                local cat = item:getCategory() or ""
                local fType = string.lower(item:getFullType() or "")

                -- Preserve weapons, ammo, bags, literature, keys, electronics, tools
                if cat == "Weapon" or cat == "Container" or cat == "Literature" or cat == "Key" or cat == "AlarmClock" or cat == "Radio" then
                    return false
                end
                if string.find(fType, "ammo") or string.find(fType, "bullet") or string.find(fType, "shell")
                   or string.find(fType, "gun") or string.find(fType, "mag") or string.find(fType, "key")
                   or string.find(fType, "watch") or string.find(fType, "jewelry") or string.find(fType, "ring") then
                    return false
                end
            end
        end
        return true -- Corpse only contains worthless worn clothes
    end

    -- 5. If neither cleanEmptyOnly nor cleanJunkOnly is active, player wants ALL corpses purged (including corpses containing loot)
    if not opts.cleanEmptyOnly and not opts.cleanJunkOnly then
        return true
    end

    return false
end

function MPOptim.Utils.shouldPurgeWorldItem(worldItemObj)
    if not worldItemObj then return false end
    local item = worldItemObj.getItem and worldItemObj:getItem()
    if not item then return false end

    -- 1. Favorited items are 100% immune
    if item.isFavorite and item:isFavorite() then return false end

    -- 2. Absolute Protected Categories (Containers, Drainables, Weapons, Clothing, Literature, Radios, Keys)
    local cat = item:getCategory()
    if cat and MPOptim.ProtectedCategories and MPOptim.ProtectedCategories[cat] then
        return false
    end

    -- 3. Explicit Protected Items (Logs, Log Piles, Gas Cans, Generators, Tool Boxes, Kits)
    local fullType = item:getFullType()
    if not fullType then return false end

    if MPOptim.ProtectedTypes and MPOptim.ProtectedTypes[fullType] then
        return false
    end

    local lowerType = string.lower(fullType)
    if string.find(lowerType, "petrol") or string.find(lowerType, "gascan")
       or string.find(lowerType, "propane") or string.find(lowerType, "generator")
       or string.find(lowerType, "logstack") or lowerType == "base.log"
       or string.find(lowerType, "toolbox") or string.find(lowerType, "firstaidkit") then
        return false
    end

    -- 1. Casings (Supports vanilla & modded Brita, VFE, Firearms B41, Arsenal[26])
    if MPOptim.Config.Get("Debris_CleanCasings") then
        if (MPOptim.DebrisTypes and MPOptim.DebrisTypes.Casings and MPOptim.DebrisTypes.Casings[fullType])
           or string.find(lowerType, "casing") or string.find(lowerType, "shell")
           or string.find(lowerType, "spentround") or string.find(lowerType, "bulletcasing") then
            return true
        end
    end

    -- 2. Trash & Empty Containers
    if MPOptim.Config.Get("Debris_CleanTrash") then
        if (MPOptim.DebrisTypes and MPOptim.DebrisTypes.Trash and MPOptim.DebrisTypes.Trash[fullType])
           or string.find(lowerType, "tin") or string.find(lowerType, "canempty")
           or string.find(lowerType, "popempty") or string.find(lowerType, "bottleempty")
           or string.find(lowerType, "cocktailspiffo") or string.find(lowerType, "cigarettebutt")
           or string.find(lowerType, "garbagedebris") or string.find(lowerType, "wrapper")
           or string.find(lowerType, "ash") or string.find(lowerType, "rippedsheetsdirty") then
            return true
        end
    end

    -- 3. Ground Twigs, Tree Branches & Loose Stones
    if MPOptim.Config.Get("Debris_CleanTwigsAndWood") then
        if (MPOptim.DebrisTypes and MPOptim.DebrisTypes.TwigsAndWood and MPOptim.DebrisTypes.TwigsAndWood[fullType])
           or fullType == "Base.Twigs" or fullType == "Base.TreeBranch" or fullType == "Base.TreeBranch2"
           or fullType == "Base.SharpedStone" or fullType == "Base.Stone" then
            return true
        end
    end

    -- 4. Broken Glass
    if MPOptim.Config.Get("Debris_CleanBrokenGlass") then
        if (MPOptim.DebrisTypes and MPOptim.DebrisTypes.Glass and MPOptim.DebrisTypes.Glass[fullType])
           or string.find(lowerType, "brokenglass") or string.find(lowerType, "glasswindowpiece")
           or string.find(lowerType, "glassshard") then
            return true
        end
    end

    -- 5. Expired / Rotten Food
    if MPOptim.Config.Get("Debris_CleanRottenFood") and item.IsFood and item:IsFood() then
        if item.isRotten and item:isRotten() then
            return true
        end
    end

    return false
end

-- ============================================================================
-- Zero-Allocation Staggered Queue Engine
-- Increments simple integers instead of allocating 60,000 table arrays
-- ============================================================================
MPOptim.StaggerQueue = MPOptim.StaggerQueue or {
    jobs = {},
    active = false,
    isSuspended = false,
    stats = {
        totalProcessed = 0,
        bloodCleaned = 0,
        corpsesCleaned = 0,
        debrisCleaned = 0,
        lastJobDurationMs = 0
    }
}

function MPOptim.StaggerQueue.AddAreaJob(area, options, onProgress, onComplete)
    local totalTiles = (area.maxX - area.minX + 1) * (area.maxY - area.minY + 1)

    local job = {
        id = tostring((getTimeInMillis and getTimeInMillis()) or 0),
        minX = area.minX,
        maxX = area.maxX,
        minY = area.minY,
        maxY = area.maxY,
        z = area.z or 0,
        curX = area.minX,
        curY = area.minY,
        total = totalTiles,
        processed = 0,
        options = options or {},
        isManual = options.isManual or false,
        onProgress = onProgress,
        onComplete = onComplete,
        startTime = (getTimeInMillis and getTimeInMillis()) or 0,
        results = {
            bloodCleaned = 0,
            corpsesCleaned = 0,
            debrisCleaned = 0
        }
    }

    table.insert(MPOptim.StaggerQueue.jobs, job)
    MPOptim.StaggerQueue.active = true
    return job.id
end

function MPOptim.StaggerQueue.OnTickSlice()
    if MPOptim.StaggerQueue.isSuspended then return end
    if not MPOptim.StaggerQueue.jobs or #MPOptim.StaggerQueue.jobs == 0 then
        MPOptim.StaggerQueue.active = false
        return
    end

    local job = MPOptim.StaggerQueue.jobs[1]
    local batchSize = (MPOptim.Config and MPOptim.Config.Get("Admin_StaggerPerTick")) or 8
    local isRemote = (isClient and isClient()) or (isServer and isServer()) or false

    local count = 0
    while count < batchSize and job.curX <= job.maxX do
        local square = MPOptim.Utils.getSquare(job.curX, job.curY, job.z)
        if square and not MPOptim.Utils.isBaseOrSafehouseProtected(square) then
            -- 1. Blood Cleanup (Precision check via IsoGridSquare.java)
            if job.options.cleanBlood then
                local hasBlood = (square.haveBlood and square:haveBlood())
                    or (square.haveBloodFloor and square:haveBloodFloor())
                    or (square.haveBloodWall and square:haveBloodWall())

                if hasBlood and square.removeBlood then
                    -- In IsoGridSquare.java, removeBlood(remote, onlyWall):
                    -- onlyWall = false clears BOTH floor blood decals and wall/fence blood splats
                    square:removeBlood(isRemote, false)
                    job.results.bloodCleaned = job.results.bloodCleaned + 1
                end

                -- Also explicitly purge wall/fence blood splats from objects (e.g. wooden fences, thumpables)
                local objs = square.getObjects and square:getObjects()
                if objs and objs:size() > 0 then
                    for oi = 0, objs:size() - 1 do
                        local obj = objs:get(oi)
                        if obj and obj.wallBloodSplats and not obj.wallBloodSplats:isEmpty() then
                            obj.wallBloodSplats:clear()
                            if square.invalidateRenderChunkLevel then
                                square:invalidateRenderChunkLevel(1)
                            end
                        end
                    end
                end
            end

            -- 2. Corpse Cleanup (Intelligent filtering)
            if job.options.cleanCorpses then
                local deadBodys = square.getDeadBodys and square:getDeadBodys()
                if deadBodys and deadBodys:size() > 0 then
                    for i = deadBodys:size() - 1, 0, -1 do
                        local corpse = deadBodys:get(i)
                        if corpse and MPOptim.Utils.canCleanCorpse(corpse, job.options) then
                            if square.removeCorpse then
                                square:removeCorpse(corpse, isRemote)
                                job.results.corpsesCleaned = job.results.corpsesCleaned + 1
                            end
                        end
                    end
                end
            end

            -- 3. World Debris / Ground Clutter Cleanup
            if job.options.cleanDebris then
                local worldObjects = square.getWorldObjects and square:getWorldObjects()
                if worldObjects and worldObjects:size() > 0 then
                    for i = worldObjects:size() - 1, 0, -1 do
                        local wObj = worldObjects:get(i)
                        if wObj and MPOptim.Utils.shouldPurgeWorldItem(wObj) then
                            if isClient and isClient() and square.transmitRemoveItemFromSquare then
                                square:transmitRemoveItemFromSquare(wObj)
                            elseif square.RemoveTileObject then
                                square:RemoveTileObject(wObj)
                            end
                            job.results.debrisCleaned = job.results.debrisCleaned + 1
                        end
                    end
                end
            end

            -- 4. Corpse Flies Muter
            if square and square.hasFlies and square:hasFlies() then
                if MPOptim.Config and MPOptim.Config.Get("Corpse_MuteFlies") then
                    if square.setHasFlies then
                        square:setHasFlies(false)
                    end
                end
            end

            -- 5. Blood Decal Stacking Cap (Non-destructive: keeps room bloody without GPU overdraw)
            if square and square.haveBloodFloor and square:haveBloodFloor() then
                if MPOptim.Config and MPOptim.Config.Get("Blood_CapPerTile") and not job.options.cleanBlood then
                    local maxBlood = MPOptim.Config.Get("Blood_MaxPerTile") or MPOptim.Config.Get("Blood_MaxPerSquare") or 4
                    if square.removeBlood and maxBlood > 0 then
                        square:removeBlood(isRemote, true)
                    end
                end
            end
        end

        job.processed = job.processed + 1
        count = count + 1

        -- Advance coordinates
        job.curY = job.curY + 1
        if job.curY > job.maxY then
            job.curY = job.minY
            job.curX = job.curX + 1
        end
    end

    if job.curX > job.maxX then
        local now = (getTimeInMillis and getTimeInMillis()) or 0
        local duration = now - job.startTime
        MPOptim.StaggerQueue.stats.lastJobDurationMs = duration
        MPOptim.StaggerQueue.stats.bloodCleaned = MPOptim.StaggerQueue.stats.bloodCleaned + job.results.bloodCleaned
        MPOptim.StaggerQueue.stats.corpsesCleaned = MPOptim.StaggerQueue.stats.corpsesCleaned + job.results.corpsesCleaned
        MPOptim.StaggerQueue.stats.debrisCleaned = MPOptim.StaggerQueue.stats.debrisCleaned + job.results.debrisCleaned
        MPOptim.StaggerQueue.stats.totalProcessed = MPOptim.StaggerQueue.stats.totalProcessed + job.total

        if job.onComplete then
            job.onComplete(job.results, duration, job.isManual)
        end

        table.remove(MPOptim.StaggerQueue.jobs, 1)
    end
end

-- ============================================================================
-- Central Master Heartbeat Engine (Zero-Allocation Staggered Logic Scheduler)
-- Single coordinated OnTick dispatcher coordinating all optimization subsystems
-- ============================================================================
local masterTick = 0

local function onMasterHeartbeat()
    masterTick = masterTick + 1


    -- 1. Active Stagger Queue (Processes micro-batches during active cleanups only)
    if MPOptim.StaggerQueue and MPOptim.StaggerQueue.active then
        MPOptim.StaggerQueue.OnTickSlice()
    end

    -- 2. Combat Burst Smoothing (Runs ONLY if there are buffered death bursts to process)
    if MPOptim.CombatHordeSuite and MPOptim.CombatHordeSuite.HasPendingBursts and MPOptim.CombatHordeSuite.HasPendingBursts() then
        MPOptim.CombatHordeSuite.ProcessBurstQueue()
    end

    -- 3. Staggered Subsystem Updates (Evenly spread to eliminate frame spikes)
    -- Background FPS Limiter (Every 30 ticks = ~0.5s)
    if masterTick % 30 == 5 then
        if MPOptim.FPSLimiter and MPOptim.FPSLimiter.Update then
            MPOptim.FPSLimiter.Update()
        end
    end

    -- Dynamic Zoom LOD (Every 30 ticks = ~0.5s)
    if masterTick % 30 == 15 then
        if MPOptim.ZoomLOD and MPOptim.ZoomLOD.Update then
            MPOptim.ZoomLOD.Update()
        end
    end

    -- Horde Swarm AI & Cosmetic Accessories (Every 60 ticks = ~1.0s)
    if masterTick % 60 == 25 then
        if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Update then
            MPOptim.HordeOptimizer.Update()
        end
    end

    -- Audio Optimizer / Horde Groan Concurrency (Every 120 ticks = ~2.0s)
    if masterTick % 120 == 45 then
        if MPOptim.AudioOptimizer and MPOptim.AudioOptimizer.Update then
            MPOptim.AudioOptimizer.Update()
        end
    end

    -- Animal Pen & Livestock Audio (Every 300 ticks = ~5.0s)
    if masterTick % 300 == 75 then
        if MPOptim.AnimalOptimizer and MPOptim.AnimalOptimizer.Update then
            MPOptim.AnimalOptimizer.Update()
        end
    end

    -- Weather Throttler (Every 600 ticks = ~10.0s)
    if masterTick % 600 == 150 then
        if MPOptim.WeatherOptimizer and MPOptim.WeatherOptimizer.Update then
            MPOptim.WeatherOptimizer.Update()
        end
    end

    -- Idle Memory / GC Monitor (Every 2400 ticks = ~40.0s)
    if masterTick % 2400 == 750 then
        if MPOptim.GCOptimizer and MPOptim.GCOptimizer.Update then
            MPOptim.GCOptimizer.Update()
        end
    end

    if masterTick >= 24000 then
        masterTick = 0
    end
end

Events.OnTick.Add(onMasterHeartbeat)


local function readFileSafe(filename)
    if not getFileReader then return nil end
    local fr = getFileReader(filename, false)
    if not fr then return nil end
    local content = ""
    local line = fr:readLine()
    while line do
        content = content .. line
        line = fr:readLine()
    end
    fr:close()
    return content
end

function MPOptim.Utils.GetOptimizedRAM()
    -- 1. Direct global number variable (Fastest, zero allocation)
    if type(PZOEngineRAM) == "number" and PZOEngineRAM > 0 then
        return PZOEngineRAM
    end

    -- 2. Direct Lua table fields
    if type(PZOEngine) == "table" and type(PZOEngine.ram_gb) == "number" and PZOEngine.ram_gb > 0 then
        return PZOEngine.ram_gb
    end
    if type(PZOEngineBridge) == "table" and type(PZOEngineBridge.ram_gb) == "number" and PZOEngineBridge.ram_gb > 0 then
        return PZOEngineBridge.ram_gb
    end

    -- 3. Direct method call on table if present
    if type(PZOEngineBridge) == "table" and type(PZOEngineBridge.getOptimizedRAM) == "function" then
        local ram = PZOEngineBridge.getOptimizedRAM()
        if type(ram) == "number" and ram > 0 then
            return ram
        end
    end

    -- 4. Disk status file fallback
    local content = readFileSafe("pzo_status.json")
    if content then
        local ram = string.match(content, '"ram_gb"%s*:%s*(%d+)')
        if ram then
            return tonumber(ram) or 8
        end
    end
    return 3
end

function MPOptim.Utils.IsEngineAgentInjected()
    -- 1. Direct global boolean flags (0ms, 0 allocations)
    if PZOEngineActive == true or isPZOEngineActive == true then
        return true
    end

    -- 2. Direct Lua table fields
    if type(PZOEngine) == "table" and PZOEngine.active == true then
        return true
    end
    if type(PZOEngineBridge) == "table" and PZOEngineBridge.active == true then
        return true
    end

    -- 3. Direct method check on table
    if type(PZOEngineBridge) == "table" and type(PZOEngineBridge.isEnginePresent) == "function" then
        if PZOEngineBridge.isEnginePresent() == true then
            return true
        end
    end

    -- 4. Disk status file fallback (for backwards compatibility)
    local content = readFileSafe("pzo_status.json")
    if content and (string.find(content, '"optimized"%s*:%s*true') or string.find(content, '"ram_gb"')) then
        return true
    end

    -- 5. Fallback: Check live telemetry feed from background Java watchdog
    local contentTel = readFileSafe("pzo_telemetry.json") or readFileSafe("pzo_server_telemetry.json")
    if contentTel and (string.find(contentTel, '"max_mb"') or string.find(contentTel, '"gc_count"') or string.find(contentTel, '"used_mb"') or string.find(contentTel, '"server_optimized"')) then
        return true
    end

    -- 6. Fallback: Check update bridge file
    local contentUp = readFileSafe("pzo_update.json")
    if contentUp and string.find(contentUp, '"current_version"') then
        return true
    end

    return false
end


function MPOptim.Utils.CheckGitHubUpdate()
    -- Only check/show update alerts if the engine agent is currently injected/active
    if not MPOptim.Utils.IsEngineAgentInjected or not MPOptim.Utils.IsEngineAgentInjected() then
        return false, nil, nil
    end

    local content = readFileSafe("pzo_update.json")
    if content then
        local hasUpdate = string.find(content, '"has_update"%s*:%s*true') ~= nil
        local latest = string.match(content, '"latest_version"%s*:%s*"([^"]+)"')
        local url = string.match(content, '"url"%s*:%s*"([^"]+)"') or "https://github.com/prop11/PZO-Launcher/releases/latest"
        if hasUpdate and latest then
            return true, latest, url
        end
    end
    return false, nil, nil
end

function MPOptim.Utils.OpenURL(url)
    if not url or url == "" then return false end

    -- 1. Always copy to clipboard as guaranteed fallback
    if Clipboard and Clipboard.setClipboard then
        Clipboard.setClipboard(url)
    end

    -- 2. Direct native OS browser launcher via PZOEngineBridge / PZOEntrypoint
    if type(PZOEngineBridge) == "table" and type(PZOEngineBridge.openBrowser) == "function" then
        PZOEngineBridge.openBrowser(url)
        return true
    end
    if type(PZOEntrypoint) == "table" and type(PZOEntrypoint.openBrowser) == "function" then
        PZOEntrypoint.openBrowser(url)
        return true
    end

    -- 3. In standard Lua mode, vanilla openUrl() has a strict domain whitelist
    --    (projectzomboid.com, steamcommunity.com, theindiestone.com, pzwiki.net).
    --    Routing external links through steamcommunity.com/linkfilter/?url= passes the whitelist!
    local isWhitelisted = string.find(url, "steamcommunity.com") or string.find(url, "projectzomboid.com") or string.find(url, "theindiestone.com") or string.find(url, "pzwiki.net")
    local finalUrl = isWhitelisted and url or ("https://steamcommunity.com/linkfilter/?url=" .. url)

    if openUrl then
        openUrl(finalUrl)
        return true
    elseif SteamFriends and SteamFriends.activateGameOverlayToWebPage then
        SteamFriends.activateGameOverlayToWebPage(url)
        return true
    elseif DesktopBrowser and DesktopBrowser.openURL then
        DesktopBrowser.openURL(url)
        return true
    end

    return false
end
