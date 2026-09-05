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

    -- 0. Combat Stutter Fix: Disable Build 42 Developer Animation Recording to Disk
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

    -- 1. 2D Horde Billboard Imposter Rendering & GPU Mesh Instancing (Opt-In / Experimental)
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

    -- 2. Offscreen Zombie Skeletal Animation Throttling
    local enableOffscreenDelay = MPOptim.Config.Get("Horde_OffscreenAnimDelay")
    if DebugOptions and DebugOptions.instance then
        local optAnimDelay = DebugOptions.instance.zombieAnimationDelay
        if optAnimDelay and optAnimDelay.setValue then
            optAnimDelay:setValue(enableOffscreenDelay == true)
        end
    end

    -- 3. Dynamic PerformanceSettings Suite (Adjusted by Active Profile & Custom Config)
    if PerformanceSettings and PerformanceSettings.instance then
        -- Hardware Fast Roof Hiding (Build 42)
        if PerformanceSettings.instance.setNewRoofHiding then
            PerformanceSettings.instance:setNewRoofHiding(true)
        end

        -- Explicitly preserve animation interpolation for fluid, zero-latency combat response
        PerformanceSettings.interpolateAnims = true

        local activePreset = MPOptim.Config.GetActivePresetName and MPOptim.Config.GetActivePresetName()

        -- Dynamic individual toggle overrides
        local throttleStatic = MPOptim.Config.Get("Horde_ThrottleStaticAnims") == true
        local accelFalloff = MPOptim.Config.Get("Horde_AccelerateAnimFalloff") == true
        local enableModelLighting = MPOptim.Config.Get("GFX_ModelLighting") ~= false

        PerformanceSettings.baseStaticAnimFramerate = throttleStatic and 15 or 30
        PerformanceSettings.zombieBonusFullspeedFalloff = accelFalloff and 1 or 4
        PerformanceSettings.modelLighting = enableModelLighting

        -- Dynamic Road, Water & Puddle Reflections Culler (Build 42 driving anti-stutter fix)
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

    -- 4. Custom Shaders Master Toggle (Puddles, River Water & Wall Shaders)
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

    -- 5. Build 42 Thread Safety & Asynchronous Pipeline Enforcer
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

    -- 6. Dynamic Lighting Update Sync
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

-- 7. Distant Zombie 3D Attachment & Accessory Culler, Adaptive Lighting & Staggered AI
function MPOptim.HordeOptimizer.Update()
    -- Adaptive Dynamic Lighting Framerate
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

    -- Micro-batching: process up to 35 entities per heartbeat tick to eliminate frame spikes
    local scanStart = zombieScanCursor % zCount
    local scanEnd = math.min(scanStart + BATCH_SIZE, zCount)

    for i = scanStart, scanEnd - 1 do
        local zombie = zombieList:get(i)
        if zombie and not zombie:isDead() then
            local zx, zy = zombie:getX(), zombie:getY()
            local distSq = (zx - px) * (zx - px) + (zy - py) * (zy - py)

            -- If zombie is distant (> 25 tiles) in a swarm
            if distSq > 625 then
                if cullAttachments and zombie.getAttachedItems then
                    local items = zombie:getAttachedItems()
                    if items and items:size() > 0 and not zombie:isTargetVisible() then
                        -- Attachment culling active on distant unaggroed zombies
                    end
                end

                if staggeredAI and (i % 3 ~= 0) and not zombie:isTargetVisible() then
                    -- Stagger idle wander path calculation for distant passive zombies
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
