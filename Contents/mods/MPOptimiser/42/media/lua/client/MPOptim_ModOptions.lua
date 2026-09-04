--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_ModOptions.lua
    Author: prop11
    Description: Full two-way synchronization with official PZAPI ModOptions and community ModOptions frameworks.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.ModOptions = MPOptim.ModOptions or {}

local MOD_ID = "MPOptimizer"
local MOD_NAME = "Project Zomboid Optimiser"

local registeredPzApiOptions = nil

function MPOptim.ModOptions.SyncFromConfig()
    if not MPOptim.Config or not MPOptim.Config.Current then return end

    -- 1. Sync Native PZAPI.ModOptions instance
    local pzOpt = registeredPzApiOptions
    if not pzOpt and PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.getOptions then
        pzOpt = PZAPI.ModOptions:getOptions(MOD_ID)
    end

    if pzOpt then
        local keyOpt = pzOpt:getOption("OptimizerHotkey")
        if keyOpt then
            local kVal = MPOptim.Config.Get("UI_Hotkey") or 68
            if keyOpt.setKey then keyOpt:setKey(kVal) end
            if keyOpt.setValue then keyOpt:setValue(kVal) end
            keyOpt.key = kVal
            keyOpt.value = kVal
        end

        for optKey, val in pairs(MPOptim.Config.Current) do
            local o = pzOpt:getOption(optKey)
            if o then
                if o.setValue then o:setValue(val) end
                o.value = val
            end
        end
    end
end

local function registerNativeOptions()
    if not PZAPI or not PZAPI.ModOptions or not PZAPI.ModOptions.create then return end
    if PZAPI.ModOptions.getOptions and PZAPI.ModOptions:getOptions(MOD_ID) then
        registeredPzApiOptions = PZAPI.ModOptions:getOptions(MOD_ID)
        MPOptim.ModOptions.SyncFromConfig()
        return
    end

    local opt = PZAPI.ModOptions:create(MOD_ID, MOD_NAME)
    if opt then
        registeredPzApiOptions = opt

        opt:addTitle("General & Hotkeys")
        opt:addKeyBind("OptimizerHotkey", "Open Optimiser Console Hotkey", (MPOptim.Config and MPOptim.Config.Get("UI_Hotkey")) or 68, "Hotkey used to toggle the Project Zomboid Optimiser Control Center (Default: F10)")
        opt:addTickBox("UI_ShowContextMenu", "Show in Context Menu", (MPOptim.Config and MPOptim.Config.Get("UI_ShowContextMenu")) == true, "Show 'Project Zomboid Optimiser' in right-click world context menu")
        opt:addTickBox("UI_ShowHUD", "Show Diagnostics HUD (FPS/RAM)", (MPOptim.Config and MPOptim.Config.Get("UI_ShowHUD")) == true, "On-screen diagnostics overlay in top-left")
        opt:addTickBox("UI_ShowNotifications", "Show Sweep Notifications", (MPOptim.Config and MPOptim.Config.Get("UI_ShowNotifications")) == true, "Shows overhead status text during automated cleanups")
        opt:addTickBox("UI_FastInventory", "Optimize Inventory & Containers", (MPOptim.Config and MPOptim.Config.Get("UI_FastInventory")) ~= false, "Accelerates inventory rendering for containers with 500+ items")

        opt:addTitle("Hardware, GPU & VRAM Boosters")
        opt:addTickBox("GFX_EnforceTextureCompression", "Enforce Texture Compression (VRAM Saver)", (MPOptim.Config and MPOptim.Config.Get("GFX_EnforceTextureCompression")) ~= false, "Forces texture compression in options.ini to cut VRAM usage in half")
        opt:addTickBox("GFX_DynamicReflections", "Dynamic Road & Puddle Reflections", (MPOptim.Config and MPOptim.Config.Get("GFX_DynamicReflections")) == true, "Disabling eliminates secondary reflection passes on roads and puddles, curing Build 42 driving stutter")
        opt:addTickBox("GFX_ModelLighting", "3D Model Dynamic Vertex Lighting", (MPOptim.Config and MPOptim.Config.Get("GFX_ModelLighting")) ~= false, "Disabling shades 3D characters with ambient light, saving GPU vertex shader passes")
        opt:addTickBox("Horde_ThrottleStaticAnims", "Throttle Idle/Static Animations (15 FPS)", (MPOptim.Config and MPOptim.Config.Get("Horde_ThrottleStaticAnims")) == true, "Clamps idle/standing animation update rate to 15 FPS to save CPU")
        opt:addTickBox("Horde_AccelerateAnimFalloff", "Accelerate Distant Zombie Animation LOD", (MPOptim.Config and MPOptim.Config.Get("Horde_AccelerateAnimFalloff")) == true, "Transitions distant horde zombies into stepped LOD animation poses sooner")
        opt:addTickBox("Weather_ClampRainParticles", "Clamp Rain & Splash Particle Pool (40 Objects)", (MPOptim.Config and MPOptim.Config.Get("Weather_ClampRainParticles")) == true, "Caps active splash and raindrop objects to 40 max during storms")
        opt:addTickBox("Fire_ThrottleParticles", "Throttle Fire Smoke & Flame Vortices", (MPOptim.Config and MPOptim.Config.Get("Fire_ThrottleParticles")) == true, "Caps active fire particles to 50 and vortices to 2 during large fires")
        opt:addTickBox("Blood_CapPerTile", "Smart Blood Decal Stacking Cap", (MPOptim.Config and MPOptim.Config.Get("Blood_CapPerTile")) ~= false, "Eliminates GPU overdraw lag in combat by capping decals per tile")
        opt:addTickBox("Corpse_CullShadows", "Cull 3D Shadows on Dead Corpses", (MPOptim.Config and MPOptim.Config.Get("Corpse_CullShadows")) == true, "Disables dynamic shadow projection on dead bodies to save draw calls")
        opt:addTickBox("Weather_Optimize", "Optimize Rain Storms & Fog", (MPOptim.Config and MPOptim.Config.Get("Weather_Optimize")) == true, "Reduces rain particle density and fog shader overhead during storms")
        opt:addTickBox("Weather_PuddleOptimization", "Ground-Level Puddle Optimization", (MPOptim.Config and MPOptim.Config.Get("Weather_PuddleOptimization")) ~= false, "Enforces Ground Only puddle mode (perfPuddles=2) to skip 8-neighbor tile queries while keeping full shader reflections on roads")
        opt:addTickBox("Weather_DisableTreeWind", "Disable Storm Tree Wind Sway (CPU Saver)", (MPOptim.Config and MPOptim.Config.Get("Weather_DisableTreeWind")) == true, "Disables barycentric tree sway recalculation during storms, preventing CPU stalls when driving through forests")

        opt:addTitle("Vehicles & Anti-Stutter Chunk Streaming")
        opt:addTickBox("Vehicle_PhysicsSleep", "Parked Vehicle Physics Sleeper", (MPOptim.Config and MPOptim.Config.Get("Vehicle_PhysicsSleep")) == true, "Puts stationary parked vehicles into Bullet physics sleep mode")
        opt:addTickBox("Vehicle_ChunkPriorityMode", "Anti-Stutter Vehicle Streamer (Master Switch)", (MPOptim.Config and MPOptim.Config.Get("Vehicle_ChunkPriorityMode")) ~= false, "Prioritizes road chunk loading bandwidth and throttles non-essential systems while driving")
        opt:addTickBox("Vehicle_LimitDriveZoom", "Prevent Extreme Auto-Zoom While Driving", (MPOptim.Config and MPOptim.Config.Get("Vehicle_LimitDriveZoom")) == true, "Limits auto-zoom while driving to save draw calls. (Keep OFF to allow road chunks to stream ahead at high speed)")
        opt:addTickBox("Vehicle_PreDrivePurge", "Pre-Drive RAM Purge on Vehicle Entry", (MPOptim.Config and MPOptim.Config.Get("Vehicle_PreDrivePurge")) == true, "Runs a quick memory cleanup when entering a vehicle")
        opt:addTickBox("Vehicle_ScaleLightingFPS", "Scale Dynamic Lighting While Driving", (MPOptim.Config and MPOptim.Config.Get("Vehicle_ScaleLightingFPS")) == true, "Reduces dynamic lighting update rate during high-speed travel")
        opt:addTickBox("Vehicle_SuspendBackgroundCleanups", "Suspend Background Sweeps While Driving", (MPOptim.Config and MPOptim.Config.Get("Vehicle_SuspendBackgroundCleanups")) ~= false, "Temporarily pauses tile sweeps and RAM purges while driving for smooth road loading")
        opt:addTickBox("Vehicle_ThreadedModelSlots", "Multi-Threaded 3D Model Loading (Build 42)", (MPOptim.Config and MPOptim.Config.Get("Vehicle_ThreadedModelSlots")) ~= false, "Offloads 3D vehicle parts and clothing loading to background threads")

        opt:addTitle("Memory & Automated Cleanups")
        opt:addTickBox("GC_SmartIdleGC", "Smart Idle Garbage Collection", (MPOptim.Config and MPOptim.Config.Get("GC_SmartIdleGC")) == true, "Runs gentle memory sweeps only during sleep, reading, and safe resting")
        opt:addSlider("GC_PurgeThresholdMB", "Smart Idle GC RAM Threshold (MB)", 1200, 4000, 200, (MPOptim.Config and MPOptim.Config.Get("GC_PurgeThresholdMB")) or 2800, "Memory usage threshold in MB required before Smart Idle GC triggers a background sweep")
        opt:addTickBox("Blood_AutoClean", "Dynamic Blood Decal Cleanup", (MPOptim.Config and MPOptim.Config.Get("Blood_AutoClean")) == true, "Periodically cleans accumulated floor blood decals")
        opt:addTickBox("Corpse_AutoClean", "Automated Corpse Cleanup", (MPOptim.Config and MPOptim.Config.Get("Corpse_AutoClean")) == true, "Periodically purges empty and junk zombie corpses")
        opt:addSlider("Corpse_IntervalHours", "Corpse Sweep Interval (Hours)", 1, 24, 1, (MPOptim.Config and MPOptim.Config.Get("Corpse_IntervalHours")) or 6, "In-game hours between automated zombie corpse sweeps")
        opt:addTickBox("Debris_AutoClean", "Ground Debris & Trash Cleanup", (MPOptim.Config and MPOptim.Config.Get("Debris_AutoClean")) == true, "Cleans spent bullet casings, empty cans, and glass shards")
        opt:addTickBox("Animal_CleanTracks", "Purge Aged Animal Tracks", (MPOptim.Config and MPOptim.Config.Get("Animal_CleanTracks")) ~= false, "Deletes aged animal footprint entities to reduce save bloat")
        opt:addTickBox("Base_ProtectPlayerStructures", "Protect Player Base Structures", (MPOptim.Config and MPOptim.Config.Get("Base_ProtectPlayerStructures")) ~= false, "Shields player-built bases, water barrels, generators, and loot")

        opt:addTitle("JVM Engine & Hardware Extensions (Optional)")
        opt:addTickBox("JVM_ZeroStutterGC", "Zero-Stutter Background GC Mode", (MPOptim.Config and MPOptim.Config.Get("JVM_ZeroStutterGC")) ~= false, "Offloads memory garbage collection to background G1GC threads")
        opt:addTickBox("JVM_DeepChunkCache", "Deep RAM Chunk Cache (Zero Disk I/O)", (MPOptim.Config and MPOptim.Config.Get("JVM_DeepChunkCache")) ~= false, "Retains visited road and town chunks in RAM")
        opt:addTickBox("JVM_AsyncModelCompile", "Asynchronous 3D Model Compiling", (MPOptim.Config and MPOptim.Config.Get("JVM_AsyncModelCompile")) ~= false, "Compiles character clothing and vehicle textures in background threads")
        opt:addTickBox("JVM_HordeHibernation", "Distant Horde Spatial Hibernation", (MPOptim.Config and MPOptim.Config.Get("JVM_HordeHibernation")) ~= false, "Hibernates distant off-screen zombie pathfinding state in RAM")

        opt.apply = function(self)
            local keyOpt = self:getOption("OptimizerHotkey")
            if keyOpt and keyOpt.key and keyOpt.key > 0 then
                MPOptim.Config.Set("UI_Hotkey", keyOpt.key)
            end

            for _, optKey in ipairs({
                "UI_ShowContextMenu", "UI_ShowHUD", "UI_ShowNotifications", "UI_FastInventory",
                "GFX_EnforceTextureCompression", "GFX_DynamicReflections", "GFX_ModelLighting", "Horde_ThrottleStaticAnims", "Horde_AccelerateAnimFalloff",
                "Weather_ClampRainParticles", "Fire_ThrottleParticles",
                "Blood_CapPerTile", "Corpse_CullShadows", "Weather_Optimize", "Weather_PuddleOptimization", "Weather_DisableTreeWind",
                "Vehicle_PhysicsSleep", "Vehicle_ChunkPriorityMode", "Vehicle_LimitDriveZoom", "Vehicle_PreDrivePurge", "Vehicle_ScaleLightingFPS",
                "Vehicle_SuspendBackgroundCleanups", "Vehicle_ThreadedModelSlots",
                "GC_SmartIdleGC", "GC_PurgeThresholdMB", "Blood_AutoClean", "Corpse_AutoClean", "Corpse_IntervalHours", "Debris_AutoClean",
                "Animal_CleanTracks", "Base_ProtectPlayerStructures",
                "JVM_ZeroStutterGC", "JVM_DeepChunkCache", "JVM_AsyncModelCompile", "JVM_HordeHibernation"
            }) do
                local o = self:getOption(optKey)
                if o and o.value ~= nil then
                    MPOptim.Config.Set(optKey, o.value)
                end
            end

            MPOptim.Config.Save()

            if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then
                MPOptim.HordeOptimizer.Apply()
            end
        end

        MPOptim.ModOptions.SyncFromConfig()
    end
end

-- Hook MainOptions prerender to ensure ModOptions tab always shows latest F10 values
local isMainOptionsHooked = false
local function hookMainOptions()
    if isMainOptionsHooked or not MainOptions or not MainOptions.prerender then return end
    isMainOptionsHooked = true

    local old_MainOptions_prerender = MainOptions.prerender
    MainOptions.prerender = function(self)
        old_MainOptions_prerender(self)
        if MPOptim.ModOptions and MPOptim.ModOptions.SyncFromConfig then
            MPOptim.ModOptions.SyncFromConfig()
        end
    end
end

if Events.OnGameBoot then Events.OnGameBoot.Add(registerNativeOptions) end
if Events.OnGameBoot then Events.OnGameBoot.Add(hookMainOptions) end
if Events.OnMainMenuEnter then Events.OnMainMenuEnter.Add(hookMainOptions) end
registerNativeOptions()
hookMainOptions()
