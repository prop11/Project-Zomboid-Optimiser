--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_HordeOptimizer.lua
    Author: prop11
    Description: Horde 2D Imposter Rendering, GPU Instancing, Skeletal Blending Cap, Animation Falloff, Fog Scaler, Dynamic Lighting, Wall Shader & Puddle Shader Bypasses.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.HordeOptimizer = MPOptim.HordeOptimizer or {}

function MPOptim.HordeOptimizer.Apply()
    if not MPOptim.Config then return end

    if AnimationPlayerRecorder then
        if AnimationPlayerRecorder.setAnimationRecorderMinRangeOfPlayer then
            AnimationPlayerRecorder.setAnimationRecorderMinRangeOfPlayer(0.0)
        end
        if AnimationPlayerRecorder.setAnimationRecorderActiveAll then
            AnimationPlayerRecorder.setAnimationRecorderActiveAll(false)
        end
        if AnimationPlayerRecorder.setAnimationRecorderActiveForType then
            if IsoZombie and IsoZombie.class then
                AnimationPlayerRecorder.setAnimationRecorderActiveForType(IsoZombie.class, false)
            end
            if IsoPlayer and IsoPlayer.class then
                AnimationPlayerRecorder.setAnimationRecorderActiveForType(IsoPlayer.class, false)
            end
        end
    end

    local enableImposters = MPOptim.Config.Get("Horde_ImposterRendering")
    if DebugOptions and DebugOptions.instance then
        local optImposter = DebugOptions.instance.zombieImposterRendering
        if optImposter and optImposter.setValue then
            optImposter:setValue(enableImposters == true)
        end

        local optInstanced = DebugOptions.instance.zombieRenderInstanced
        if optInstanced and optInstanced.setValue then
            optInstanced:setValue(enableImposters == true)
        end

        local optOcclusion = DebugOptions.instance.cheapOcclusionCount
        if optOcclusion and optOcclusion.setValue then
            local enableCheapOcclusion = MPOptim.Config.Get("FBORender_CheapOcclusion") ~= false
            optOcclusion:setValue(enableCheapOcclusion)
        end

        local optThreadSlots = DebugOptions.instance.threadModelSlotInit
        if optThreadSlots and optThreadSlots.setValue then
            local enableThreadSlots = MPOptim.Config.Get("Vehicle_ThreadedModelSlots") ~= false
            optThreadSlots:setValue(enableThreadSlots)
        end

        local optVis = DebugOptions.instance.useNewVisibility
        if optVis and optVis.setValue then
            optVis:setValue(true)
        end
    end

    local enableOffscreenDelay = MPOptim.Config.Get("Horde_OffscreenAnimDelay")
    if DebugOptions and DebugOptions.instance then
        local optAnimDelay = DebugOptions.instance.zombieAnimationDelay
        if optAnimDelay and optAnimDelay.setValue then
            optAnimDelay:setValue(enableOffscreenDelay == true)
        end
    end

    if PerformanceSettings and PerformanceSettings.instance then
        if PerformanceSettings.instance.setNewRoofHiding then
            PerformanceSettings.instance:setNewRoofHiding(true)
        end

        PerformanceSettings.interpolateAnims = true

        local activePreset = MPOptim.Config.GetActivePresetName and MPOptim.Config.GetActivePresetName()

        local throttleStatic = MPOptim.Config.Get("Horde_ThrottleStaticAnims") == true
        local accelFalloff = MPOptim.Config.Get("Horde_AccelerateAnimFalloff") == true
        local enableModelLighting = MPOptim.Config.Get("GFX_ModelLighting") ~= false

        PerformanceSettings.baseStaticAnimFramerate = throttleStatic and 15 or 30
        PerformanceSettings.zombieBonusFullspeedFalloff = accelFalloff and 1 or 4
        PerformanceSettings.modelLighting = enableModelLighting

        if getCore then
            local core = getCore()
            local enableReflections = (MPOptim.Config and MPOptim.Config.Get("GFX_DynamicReflections")) == true
            if core and core.setPerfReflections then
                core:setPerfReflections(enableReflections)
            end
        end

        if activePreset == "Experimental" then
            PerformanceSettings.numberZombiesBlended = 6
            PerformanceSettings.zombieAnimationSpeedFalloffCount = 3
            if PerformanceSettings.instance.setFogQuality then
                PerformanceSettings.instance:setFogQuality(2) -- Fast 2D Legacy Fog
            end
            if PerformanceSettings.instance.setPuddlesQuality then
                PerformanceSettings.instance:setPuddlesQuality(0) -- Flat Ground Puddles
            end
            if PerformanceSettings.instance.setWaterQuality then
                PerformanceSettings.instance:setWaterQuality(2) -- 2D Water
            end
            if PerformanceSettings.setLightingFPS then
                PerformanceSettings.setLightingFPS(15)
            end
        elseif activePreset == "Potato" or activePreset == "PotatoPC" or activePreset == "Aggressive" then
            PerformanceSettings.numberZombiesBlended = 8
            PerformanceSettings.zombieAnimationSpeedFalloffCount = 3
            if PerformanceSettings.instance.setFogQuality then
                PerformanceSettings.instance:setFogQuality(2) -- Fast 2D Legacy Fog
            end
            if PerformanceSettings.instance.setPuddlesQuality then
                PerformanceSettings.instance:setPuddlesQuality(0) -- Flat Ground Puddles
            end
            if PerformanceSettings.instance.setWaterQuality then
                PerformanceSettings.instance:setWaterQuality(2) -- 2D Water
            end
            if PerformanceSettings.setLightingFPS then
                PerformanceSettings.setLightingFPS(15)
            end
        elseif activePreset == "Balanced" then
            PerformanceSettings.numberZombiesBlended = 12
            PerformanceSettings.zombieAnimationSpeedFalloffCount = 4
            if PerformanceSettings.setLightingFPS then
                PerformanceSettings.setLightingFPS(30)
            end
        elseif activePreset == "All Optimisations Disabled" or activePreset == "TestModeVanilla" or activePreset == "Test Mode" then
            PerformanceSettings.numberZombiesBlended = 12
            PerformanceSettings.zombieAnimationSpeedFalloffCount = 4
            PerformanceSettings.baseStaticAnimFramerate = 60
            PerformanceSettings.zombieBonusFullspeedFalloff = 6
            PerformanceSettings.modelLighting = true
            if PerformanceSettings.setLightingFPS then
                PerformanceSettings.setLightingFPS(30)
            end
        else
            -- Custom / Server Profile
            PerformanceSettings.numberZombiesBlended = MPOptim.Config.Get("Horde_NumberZombiesBlended") or 20
            PerformanceSettings.zombieAnimationSpeedFalloffCount = MPOptim.Config.Get("Horde_ZombieSpeedFalloffCount") or 5
            local targetFps = MPOptim.Config.Get("Lighting_FPS") or 30
            if PerformanceSettings.setLightingFPS then
                PerformanceSettings.setLightingFPS(targetFps)
            end
        end
    end

    local enableCustomShaders = (MPOptim.Config and MPOptim.Config.Get("GFX_CustomShaders")) ~= false

    if IsoGridSquare then
        IsoGridSquare.USE_WALL_SHADER = enableCustomShaders
    end

    if IsoPuddles then
        IsoPuddles.isShaderEnable = enableCustomShaders
    end

    if IsoWater then
        IsoWater.isShaderEnable = enableCustomShaders
    end

    -- Threading.Animation MUST be false to prevent Kahlua worker thread assertion crashes during timed actions.
    -- Threading.Sound and Threading.Ambient MUST be false: FMOD and ambient emitter collections are not thread-safe,
    -- and cause TimSort race conditions (ArrayIndexOutOfBoundsException -2) when audio mods like DayZ Ambient play sounds while driving.
    -- Threading.World MUST be false to prevent concurrent FMOD calls during player emitter cleanup.
    -- Subsystems with dedicated thread safety (Lighting, GridStacks, Pathfinding) remain active.
    if DebugOptions and DebugOptions.instance and DebugOptions.instance.setBoolean then
        DebugOptions.instance:setBoolean("Threading.Animation", false)
        DebugOptions.instance:setBoolean("Threading.Sound", false)
        DebugOptions.instance:setBoolean("Threading.Ambient", false)
        DebugOptions.instance:setBoolean("Threading.World", false)
        DebugOptions.instance:setBoolean("Threading.Pathfinding", true)
        DebugOptions.instance:setBoolean("Threading.RecalculateGridStacks", true)
        DebugOptions.instance:setBoolean("Threading.Lighting", true)
    end

    local targetLightingFPS = MPOptim.Config.Get("Lighting_FPS") or 60
    if PerformanceSettings then
        if PerformanceSettings.setLightingFPS then
            PerformanceSettings.setLightingFPS(targetLightingFPS)
        elseif PerformanceSettings.instance and PerformanceSettings.instance.setLightingFPS then
            PerformanceSettings.instance:setLightingFPS(targetLightingFPS)
        end
        PerformanceSettings.lightingFps = targetLightingFPS
    end

    print(string.format("[MPOptimizer] Engine Optimizations Applied (Imposters: %s, BlendedZombies: %s, FalloffCount: %s, LightingFPS: %s)",
        tostring(enableImposters), tostring(PerformanceSettings.numberZombiesBlended or 20),
        tostring(PerformanceSettings.zombieAnimationSpeedFalloffCount or 6),
        tostring(PerformanceSettings.lightingFps or 60)))
end

local zombieScanCursor = 0
local BATCH_SIZE = 35

function MPOptim.HordeOptimizer.Update()
    if MPOptim.Config and MPOptim.Config.Get("Lighting_AdaptiveFPS") then
        local curFPS = (MPOptim.Utils and MPOptim.Utils.getFPS and MPOptim.Utils.getFPS()) or 60
        local desiredLightFPS = (curFPS > 75) and 60 or ((curFPS > 45) and 45 or 30)
        if PerformanceSettings and PerformanceSettings.lightingFps ~= desiredLightFPS then
            if PerformanceSettings.setLightingFPS then
                PerformanceSettings.setLightingFPS(desiredLightFPS)
            end
            PerformanceSettings.lightingFps = desiredLightFPS
        end
    end

    local cullAttachments = MPOptim.Config and MPOptim.Config.Get("Horde_CullDistantAttachments") == true
    local staggeredAI = MPOptim.Config and MPOptim.Config.Get("Horde_StaggeredAITicking") == true

    if not cullAttachments and not staggeredAI then return end

    local player = getPlayer and getPlayer()
    if not player then return end

    local cell = getCell and getCell()
    if not cell then return end

    local zombieList = cell:getZombieList()
    if not zombieList or zombieList:size() == 0 then return end

    local zCount = zombieList:size()
    if zCount < 20 then return end -- Only engage during larger crowds

    local px, py = player:getX(), player:getY()

    local scanStart = zombieScanCursor % zCount
    local scanEnd = math.min(scanStart + BATCH_SIZE, zCount)

    for i = scanStart, scanEnd - 1 do
        local zombie = zombieList:get(i)
        if zombie and not zombie:isDead() then
            local zx, zy = zombie:getX(), zombie:getY()
            local distSq = (zx - px) * (zx - px) + (zy - py) * (zy - py)

            if distSq > 625 then
                if cullAttachments and zombie.getAttachedItems then
                    local items = zombie:getAttachedItems()
                    if items and items:size() > 0 and not zombie:isTargetVisible() then
                    end
                end

                if staggeredAI and (i % 3 ~= 0) and not zombie:isTargetVisible() then
                    if zombie.setPathFindIndex then
                        zombie:setPathFindIndex(-1)
                    end
                end
            end
        end
    end

    zombieScanCursor = (scanEnd >= zCount) and 0 or scanEnd
end

Events.OnGameStart.Add(MPOptim.HordeOptimizer.Apply)
Events.OnMainMenuEnter.Add(MPOptim.HordeOptimizer.Apply)
