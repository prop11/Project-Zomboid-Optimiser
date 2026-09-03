--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/shared/MPOptim_Config.lua
    Author: prop11
    Description: Centralized configuration, presets, and persistence management for client and server optimization rules.
--]]

MPOptim = MPOptim or {}
MPOptim.Config = MPOptim.Config or {}
MPOptim.Config.Current = MPOptim.Config.Current or {}
MPOptim.Version = "1.4.0"

-- Default Configuration Table (Philosophy: High performance impact with ZERO/low visual gameplay degradation by default)
MPOptim.DefaultConfig = {
    -- Dedicated JVM Engine Optimizer Settings (Requires 8GB+ RAM & PZO Optimizer)
    JVM_ZeroStutterGC = true,
    JVM_DeepChunkCache = true,
    JVM_AsyncModelCompile = true,
    JVM_HordeHibernation = true,
    JVM_GLStateOptimizer = true,
    JVM_KahluaGCPacer = true,
    JVM_PowerShield = true,
    JVM_StreamBufferBoost = true,
    JVM_ChunkCacheSize = 500,
    JVM_GCThresholdMB = 6000,

    -- JVM High-Memory Exclusive Features (Requires PZO Optimizer & 8GB+ RAM)

    -- User Interface & Hotkeys
    UI_ShowContextMenu = false,
        UI_FastInventory = true,
    LastSeenVersion = "0.0.0",
    FirstLaunchPromptShown = false,
    UI_ShowHUD = false,
    UI_ShowNotifications = false,
    UI_FastInventory = true,            -- Accelerates inventory rendering for containers with 500+ items
    UI_HUD_PosX = 25,
    UI_HUD_PosY = 25,
    UI_Hotkey = 68,

    -- Audio Replacer & Sound Mod Compatibility
    Audio_ReplacerSafeMode = true,
    Audio_AntiClipping = true,          -- Anti-Clipping Combat Sound Stabilizer (Caps concurrent horde pain voices)

    -- Memory & Garbage Collection Management
    GC_AutoPurge = false,
    GC_SmartIdleGC = false,
    ModShield_Enabled = true,
    Plumbing_ThrottleWaterPipes = true,
    
    GC_PurgeThresholdMB = 2800,

    -- Dynamic Blood Decal Management (Blood_CapPerTile is ON by default: caps stacking with 0 visual loss)
    Blood_CapPerTile = true,            -- Caps max blood decals per tile to prevent GPU overdraw lag
    Blood_MaxPerTile = 4,               -- Maximum blood decals per single square
    Blood_AutoClean = false,            -- Full blood deletion sweep (Default: OFF)
    Blood_IntervalHours = 4,
    Blood_CleanRadius = 30,
    Blood_RemoveWall = false,
    Blood_MaxPerSquare = 4,

    -- Corpse & Audio Optimization (Default: OFF to preserve player loot corpses)
    Corpse_AutoClean = false,
    Corpse_IntervalHours = 6,
    Corpse_CleanEmptyOnly = true,
    Corpse_CleanJunkOnly = false,
    Corpse_CleanAshAndSkeletons = true,
    Corpse_MinAgeHours = 12,
    Corpse_CleanRadius = 30,
    Corpse_MuteFlies = false,
    Corpse_CullShadows = false,         -- Culls 3D shadow projection calculations on dead bodies

    -- Ground Debris & Clutter Purger (Default: OFF to preserve dropped ground items)
    Debris_AutoClean = false,
    Debris_IntervalHours = 12,
    Debris_CleanCasings = true,
    Debris_CleanTrash = true,
    Debris_CleanTwigsAndWood = true,
    Debris_CleanBrokenGlass = true,
    Debris_CleanRottenFood = false,
    Debris_CleanRadius = 35,

    -- B42 Multithreading, GPU & Engine Optimizations (High-Impact, 100% Seamless)
    Horde_ImposterRendering = false,    -- 2D GPU Billboard Imposter Rendering for Distant Zombies (Opt-in)
    Horde_OffscreenAnimDelay = true,    -- Offscreen Zombie Skeletal Animation Throttling
    Threaded_Lighting = false,          -- Multi-Threaded Dynamic Lighting Propagation (Opt-in)
    Threaded_Sound = false,             -- Multi-Threaded 3D Audio (Default: Off to prevent FMOD channel cutouts)
    FBORender_CheapOcclusion = true,
    GFX_BuildingInteriorCull = true,
    Vehicle_PhysicsSleep = false,
    GFX_DynamicZoomLOD = true,
    Animal_ThrottleDistant = true,
    GFX_ForestCanopyCull = true,
    Combat_BurstSmoother = true,
    Horde_AudioConcurrencyLimit = true,
    Horde_CullDistantAttachments = true,
    Horde_StaggeredAITicking = true,    -- Fast Building Cutaway Occlusion Math
    Sound_AutoPruneQueue = false,       -- World Sound Queue Pruner (Default: Off)
    FPS_BackgroundThrottle = false,     -- Smart Alt-Tab & Background FPS Limiter (20 FPS when unfocused)
    FirstLaunchPromptShown = false,     -- First Launch Welcome Dialog Flag

    -- B42 Advanced Multithreading Suite (Worker Threads)
    Threading_Pathfinding = false,      -- Background Zombie Pathfinding Worker Threads
    Threading_Animation = false,        -- Background Skeletal Animation Processing
    Threading_GridStacks = false,       -- Background Multi-Level Grid Calculations
    Threading_Ambient = false,          -- Background Environmental Ambient Sound Processing

    -- Dynamic Lighting & Fire Particle Scaling
    Lighting_AdaptiveFPS = false,       -- Adaptive Dynamic Lighting Refresh Rate
    Lighting_FPS = 30,                  -- Target Lighting FPS (15, 20, 30, 45, 60)
    Fire_ThrottleParticles = false,     -- Throttles fire smoke & flame particles during large fires

    -- Weather, Particles & Animals
    Weather_Optimize = false,           -- Default: OFF to preserve vanilla rain/fog density unless requested
    Weather_MaxRainDensity = 0.70,
    Weather_PuddleOptimization = true,
    Animal_Optimize = true,            -- Animal Pen Audio Limiter
    Animal_MaxAudioEmitters = 4,
    Animal_CleanTracks = true,         -- Build 42 Animal Footprint/Track Entity Purger
    Fire_Optimize = true,
    Fire_MaxEmitters = 8,

    -- Vehicle & High-Speed Performance
    Vehicle_ChunkPriorityMode = true,
    Vehicle_LimitDriveZoom = true,         -- Prevents extreme 200% camera auto-zoom surge while driving, restores on foot
    Vehicle_PreDrivePurge = false,          -- Pre-drive memory sweep upon entering vehicle
    Vehicle_ScaleLightingFPS = true,       -- Scales dynamic lighting rate during high-speed driving
    Vehicle_SpeedThreshold = 20,
    Vehicle_ThrottleRoadsideZombies = false,
    Vehicle_BoostImposterDistance = false,
    Vehicle_SuspendBackgroundCleanups = true,
    Vehicle_ThreadedModelSlots = true,

    -- Graphics & Texture VRAM Optimization
    GFX_EnforceTextureCompression = true,
    GFX_DynamicReflections = false,        -- Dynamic Road, Water & Puddle Reflections (Default: OFF to eliminate driving stutter)
    GFX_ModelLighting = true,           -- Dynamic per-vertex point light highlights on 3D character meshes (Potato: false)
    GFX_CustomShaders = true,              -- Build 42 Multi-Pass GLSL Wall Shader (Potato: false -> Direct Tile Blit)
    Horde_ThrottleStaticAnims = false,  -- Clamps idle/static entity animation rate to 15 FPS (Potato: true)
    Horde_AccelerateAnimFalloff = false,-- Accelerates distant zombie animation LOD falloff (Potato: true)
    Weather_ClampRainParticles = false, -- Clamps rain splashes and drops to 40 max objects (Potato: true)
    Weather_PuddleOptimization = true,  -- Ground-level puddles (perfPuddles=2) & skips 8-neighbor lookups
    Weather_DisableTreeWind = false,    -- Disables barycentric tree mesh sway distortion during storms (Potato: true)

    -- Singleplayer Base & Safehouse Protection
    Base_ProtectPlayerStructures = true,
    Base_ProtectionRadius = 20,
    Admin_ProtectSafehouses = true,
    Admin_BroadcastCleanup = false,
    Admin_StaggerPerTick = 15
}

MPOptim.DebrisTypes = {
    Casings = {
        ["Base.Bullets9mm_Casing"] = true,
        ["Base.Bullets45_Casing"] = true,
        ["Base.Bullets44_Casing"] = true,
        ["Base.ShotgunShells_Casing"] = true,
        ["Base.223Bullets_Casing"] = true,
        ["Base.308Bullets_Casing"] = true,
        ["Base.556Bullets_Casing"] = true,
        ["Base.Bullets9mm_Shell"] = true,
        ["Base.Bullets45_Shell"] = true,
        ["Base.Bullets44_Shell"] = true,
        ["Base.ShotgunShells_Shell"] = true,
        ["Base.223Bullets_Shell"] = true,
        ["Base.308Bullets_Shell"] = true,
        ["Base.556Bullets_Shell"] = true,
    },
    Trash = {
        ["Base.PopEmpty"] = true,
        ["Base.Pop2Empty"] = true,
        ["Base.Pop3Empty"] = true,
        ["Base.TinCanEmpty"] = true,
        ["Base.CannedMilkEmpty"] = true,
        ["Base.WaterBottleEmpty"] = true,
        ["Base.BeerEmpty"] = true,
        ["Base.WhiskeyEmpty"] = true,
        ["Base.WineEmpty"] = true,
        ["Base.WineEmpty2"] = true,
        ["Base.Cigarettes"] = true,
        ["Base.Cigarette_butt"] = true,
        ["Base.Matches"] = true,
        ["Base.Matchbox"] = true,
        ["Base.Lighter"] = true,
        ["Base.ToiletPaper"] = true,
        ["Base.Tissue"] = true,
        ["Base.RippedSheetsDirty"] = true,
        ["Base.RippedSheets"] = true,
        ["Base.BandageDirty"] = true,
        ["Base.DenimStripsDirty"] = true,
        ["Base.LeatherStripsDirty"] = true,
        ["Base.Plank"] = false,
        ["Base.Ash"] = true,
        ["Base.CardDeck"] = true,
        ["Base.Newspaper"] = true,
    },
    TwigsAndWood = {
        ["Base.Twigs"] = true,
        ["Base.TreeBranch"] = true,
        ["Base.TreeBranch2"] = true,
        ["Base.SharpedStone"] = true,
        ["Base.Stone"] = true,
    },
    Glass = {
        ["Base.Brokenglass"] = true,
        ["Base.BrokenGlass"] = true,
        ["Base.GlassWindowPiece"] = true,
    }
}

-- Absolute Protected Categories & Ground Resource Safeguards
MPOptim.ProtectedCategories = {
    ["Weapon"] = true,
    ["Clothing"] = true,
    ["Container"] = true,
    ["Literature"] = true,
    ["Key"] = true,
    ["Drainable"] = true,
    ["AlarmClock"] = true,
    ["Radio"] = true,
}

-- Absolute Protected Item Types (Never purged by ground cleaner)
MPOptim.ProtectedTypes = {
    ["Base.PetrolCan"] = true,
    ["Base.EmptyPetrolCan"] = true,
    ["Base.GasCan"] = true,
    ["Base.PropaneTank"] = true,
    ["Base.EmptyPropaneTank"] = true,
    ["Base.BlowTorch"] = true,
    ["Base.Log"] = true,
    ["Base.LogStacks2"] = true,
    ["Base.LogStacks3"] = true,
    ["Base.LogStacks4"] = true,
    ["Base.Plank"] = true,
    ["Base.Generator"] = true,
    ["Base.CarBattery"] = true,
    ["Base.CarBatteryHeavy"] = true,
    ["Base.Jack"] = true,
    ["Base.LugWrench"] = true,
    ["Base.TirePump"] = true,
    ["Base.FirstAidKit"] = true,
    ["Base.Toolbox"] = true,
    ["Base.SewingKit"] = true,
    ["Base.WaterBottleFull"] = true,
    ["Base.WaterBottle"] = true,
}

-- Preset Configurations
MPOptim.Presets = {
    Balanced = {
        Blood_CapPerTile = true,
        Blood_MaxPerTile = 4,
        Blood_AutoClean = false,
        Corpse_AutoClean = false,
        Corpse_MuteFlies = false,
        Corpse_CullShadows = false,
        Debris_AutoClean = false,
        Horde_ImposterRendering = false,
        Horde_OffscreenAnimDelay = true,
        Threaded_Lighting = false,
        Threaded_Sound = false,
        FBORender_CheapOcclusion = true,
    GFX_BuildingInteriorCull = true,
    Vehicle_PhysicsSleep = false,
    GFX_DynamicZoomLOD = true,
    Animal_ThrottleDistant = true,
    GFX_ForestCanopyCull = true,
    Combat_BurstSmoother = true,
    Horde_AudioConcurrencyLimit = true,
    Horde_CullDistantAttachments = true,
    Horde_StaggeredAITicking = true,
        Sound_AutoPruneQueue = false,
        FPS_BackgroundThrottle = false,
        Threading_Pathfinding = false,
        Threading_Animation = false,
        Threading_GridStacks = false,
        Threading_Ambient = false,
        Lighting_AdaptiveFPS = false,
        Lighting_FPS = 30,
        Fire_ThrottleParticles = false,
        Weather_Optimize = false,
        Weather_MaxRainDensity = 0.70,
        Animal_Optimize = true,
        Animal_CleanTracks = true,
        Animal_MaxAudioEmitters = 4,
        Fire_Optimize = true,
        GC_SmartIdleGC = false,
    ModShield_Enabled = true,
    Plumbing_ThrottleWaterPipes = true,
    
        Vehicle_ChunkPriorityMode = true,
        Vehicle_LimitDriveZoom = true,
        Vehicle_PreDrivePurge = false,
        Vehicle_ScaleLightingFPS = true,
        Vehicle_SpeedThreshold = 20,
        Vehicle_ThrottleRoadsideZombies = false,
        Vehicle_BoostImposterDistance = false,
        Vehicle_SuspendBackgroundCleanups = true,
        Vehicle_ThreadedModelSlots = true,
        GFX_EnforceTextureCompression = true,
        GFX_DynamicReflections = false,
        GFX_ModelLighting = true,
        GFX_CustomShaders = true,
        Horde_ThrottleStaticAnims = false,
        Horde_AccelerateAnimFalloff = false,
        
        Weather_ClampRainParticles = false,
        Weather_PuddleOptimization = true,
        Weather_DisableTreeWind = false,
        Base_ProtectPlayerStructures = true,
        Admin_StaggerPerTick = 15
    },
    Potato = {
        GFX_BuildingInteriorCull = true,
        Combat_BurstSmoother = true,
        Horde_AudioConcurrencyLimit = true,
        Horde_CullDistantAttachments = true,
        Horde_StaggeredAITicking = true,
        ModShield_Enabled = true,
    Plumbing_ThrottleWaterPipes = true,
        
        Vehicle_PhysicsSleep = false,
        GFX_DynamicZoomLOD = true,
        Animal_ThrottleDistant = true,
        GFX_ForestCanopyCull = true,
    Combat_BurstSmoother = true,
    Horde_AudioConcurrencyLimit = true,
    Horde_CullDistantAttachments = true,
    Horde_StaggeredAITicking = true,
    Vehicle_PhysicsSleep = false,
    GFX_DynamicZoomLOD = true,
    Animal_ThrottleDistant = true,
    GFX_ForestCanopyCull = true,
    Combat_BurstSmoother = true,
    Horde_AudioConcurrencyLimit = true,
    Horde_CullDistantAttachments = true,
    Horde_StaggeredAITicking = true,
        Blood_CapPerTile = true,
        Blood_MaxPerTile = 1,
        Blood_AutoClean = true,
        Blood_IntervalHours = 2,
        Blood_CleanRadius = 45,
        Corpse_AutoClean = true,
        Corpse_CleanEmptyOnly = false,
        Corpse_CleanJunkOnly = true,
        Corpse_CleanAshAndSkeletons = true,
        Corpse_MinAgeHours = 6,
        Corpse_CleanRadius = 40,
        Corpse_MuteFlies = true,
        Corpse_CullShadows = true,
        Debris_AutoClean = true,
        Debris_IntervalHours = 4,
        Debris_CleanCasings = true,
        Debris_CleanTrash = true,
        Debris_CleanTwigsAndWood = true,
        Debris_CleanBrokenGlass = true,
        Debris_CleanRottenFood = true,
        Horde_ImposterRendering = false,
        Horde_OffscreenAnimDelay = true,
        Threaded_Lighting = false,
        Threaded_Sound = false,
        FBORender_CheapOcclusion = true,
    GFX_BuildingInteriorCull = true,
    Vehicle_PhysicsSleep = false,
    GFX_DynamicZoomLOD = true,
    Animal_ThrottleDistant = true,
    GFX_ForestCanopyCull = true,
    Combat_BurstSmoother = true,
    Horde_AudioConcurrencyLimit = true,
    Horde_CullDistantAttachments = true,
    Horde_StaggeredAITicking = true,
        Sound_AutoPruneQueue = false,
        FPS_BackgroundThrottle = false,
        Threading_Pathfinding = false,
        Threading_Animation = false,
        Threading_GridStacks = false,
        Threading_Ambient = false,
        Lighting_AdaptiveFPS = false,
        Lighting_FPS = 15,
        Fire_ThrottleParticles = true,
        Weather_Optimize = true,
        Weather_MaxRainDensity = 0.50,
        Animal_Optimize = true,
        Animal_CleanTracks = true,
        Animal_MaxAudioEmitters = 2,
        Fire_Optimize = true,
        GC_SmartIdleGC = true,
        ModShield_Enabled = true,
    Plumbing_ThrottleWaterPipes = true,
        
        Vehicle_ChunkPriorityMode = true,
        Vehicle_LimitDriveZoom = true,
        Vehicle_PreDrivePurge = true,
        Vehicle_ScaleLightingFPS = true,
        Vehicle_SpeedThreshold = 20,
        Vehicle_ThrottleRoadsideZombies = false,
        Vehicle_BoostImposterDistance = false,
        Vehicle_SuspendBackgroundCleanups = true,
        Vehicle_ThreadedModelSlots = true,
        GFX_EnforceTextureCompression = true,
        GFX_DynamicReflections = false,
        GFX_ModelLighting = false,
        GFX_CustomShaders = true,
        Horde_ThrottleStaticAnims = true,
        Horde_AccelerateAnimFalloff = true,
        
        Weather_ClampRainParticles = true,
        Weather_PuddleOptimization = true,
        Weather_DisableTreeWind = true,
        Base_ProtectPlayerStructures = true,
        Admin_StaggerPerTick = 25
    },
    Experimental = {
        GFX_BuildingInteriorCull = true,
        Combat_BurstSmoother = true,
        Horde_AudioConcurrencyLimit = true,
        Horde_CullDistantAttachments = true,
        Horde_StaggeredAITicking = true,
        ModShield_Enabled = true,
    Plumbing_ThrottleWaterPipes = true,
        
        Vehicle_PhysicsSleep = false,
        GFX_DynamicZoomLOD = true,
        Animal_ThrottleDistant = true,
        GFX_ForestCanopyCull = true,
    Combat_BurstSmoother = true,
    Horde_AudioConcurrencyLimit = true,
    Horde_CullDistantAttachments = true,
    Horde_StaggeredAITicking = true,
    Vehicle_PhysicsSleep = false,
    GFX_DynamicZoomLOD = true,
    Animal_ThrottleDistant = true,
    GFX_ForestCanopyCull = true,
    Combat_BurstSmoother = true,
    Horde_AudioConcurrencyLimit = true,
    Horde_CullDistantAttachments = true,
    Horde_StaggeredAITicking = true,
        Blood_CapPerTile = true,
        Blood_MaxPerTile = 1,
        Blood_AutoClean = true,
        Blood_IntervalHours = 2,
        Blood_CleanRadius = 45,
        Corpse_AutoClean = true,
        Corpse_CleanEmptyOnly = false,
        Corpse_CleanJunkOnly = true,
        Corpse_CleanAshAndSkeletons = true,
        Corpse_MinAgeHours = 6,
        Corpse_CleanRadius = 40,
        Corpse_MuteFlies = true,
        Corpse_CullShadows = true,
        Debris_AutoClean = true,
        Debris_IntervalHours = 4,
        Debris_CleanCasings = true,
        Debris_CleanTrash = true,
        Debris_CleanTwigsAndWood = true,
        Debris_CleanBrokenGlass = true,
        Debris_CleanRottenFood = true,
        Horde_ImposterRendering = true,
        Horde_OffscreenAnimDelay = true,
        Threaded_Lighting = true,
        Threaded_Sound = false,
        FBORender_CheapOcclusion = true,
    GFX_BuildingInteriorCull = true,
    Vehicle_PhysicsSleep = false,
    GFX_DynamicZoomLOD = true,
    Animal_ThrottleDistant = true,
    GFX_ForestCanopyCull = true,
    Combat_BurstSmoother = true,
    Horde_AudioConcurrencyLimit = true,
    Horde_CullDistantAttachments = true,
    Horde_StaggeredAITicking = true,
        Sound_AutoPruneQueue = false,
        FPS_BackgroundThrottle = false,
        Threading_Pathfinding = true,
        Threading_Animation = true,
        Threading_GridStacks = true,
        Threading_Ambient = true,
        Lighting_AdaptiveFPS = true,
        Lighting_FPS = 15,
        Fire_ThrottleParticles = true,
        Weather_Optimize = true,
        Weather_MaxRainDensity = 0.50,
        Animal_Optimize = true,
        Animal_CleanTracks = true,
        Animal_MaxAudioEmitters = 2,
        Fire_Optimize = true,
        GC_SmartIdleGC = true,
        ModShield_Enabled = true,
    Plumbing_ThrottleWaterPipes = true,
        
        Vehicle_ChunkPriorityMode = true,
        Vehicle_LimitDriveZoom = true,
        Vehicle_PreDrivePurge = false,
        Vehicle_ScaleLightingFPS = true,
        Vehicle_SpeedThreshold = 20,
        Vehicle_ThrottleRoadsideZombies = true,
        Vehicle_BoostImposterDistance = true,
        Vehicle_SuspendBackgroundCleanups = true,
        Vehicle_ThreadedModelSlots = true,
        GFX_EnforceTextureCompression = true,
        GFX_DynamicReflections = false,
        GFX_ModelLighting = false,
        GFX_CustomShaders = true,
        Horde_ThrottleStaticAnims = true,
        Horde_AccelerateAnimFalloff = true,
        
        Weather_ClampRainParticles = true,
        Weather_PuddleOptimization = true,
        Weather_DisableTreeWind = true,
        Base_ProtectPlayerStructures = true,
        Admin_StaggerPerTick = 25
    },
    Server = {
        GFX_BuildingInteriorCull = true,
        Combat_BurstSmoother = true,
        Horde_AudioConcurrencyLimit = true,
        Horde_CullDistantAttachments = true,
        Horde_StaggeredAITicking = true,
        ModShield_Enabled = true,
    Plumbing_ThrottleWaterPipes = true,
        
        Vehicle_PhysicsSleep = false,
        GFX_DynamicZoomLOD = true,
        Animal_ThrottleDistant = true,
        GFX_ForestCanopyCull = true,
    Combat_BurstSmoother = true,
    Horde_AudioConcurrencyLimit = true,
    Horde_CullDistantAttachments = true,
    Horde_StaggeredAITicking = true,
    Vehicle_PhysicsSleep = false,
    GFX_DynamicZoomLOD = true,
    Animal_ThrottleDistant = true,
    GFX_ForestCanopyCull = true,
    Combat_BurstSmoother = true,
    Horde_AudioConcurrencyLimit = true,
    Horde_CullDistantAttachments = true,
    Horde_StaggeredAITicking = true,
        Blood_CapPerTile = true,
        Blood_MaxPerTile = 3,
        Blood_AutoClean = true,
        Blood_IntervalHours = 4,
        Blood_CleanRadius = 40,
        Corpse_AutoClean = true,
        Corpse_CleanEmptyOnly = true,
        Corpse_CleanJunkOnly = true,
        Corpse_CleanAshAndSkeletons = true,
        Corpse_MinAgeHours = 24,
        Corpse_CleanRadius = 40,
        Corpse_MuteFlies = false,
        Corpse_CullShadows = true,
        Debris_AutoClean = true,
        Debris_IntervalHours = 8,
        Debris_CleanCasings = true,
        Debris_CleanTrash = true,
        Debris_CleanTwigsAndWood = true,
        Debris_CleanBrokenGlass = true,
        Debris_CleanRottenFood = true,
        Horde_ImposterRendering = false,
        Horde_OffscreenAnimDelay = true,
        Threaded_Lighting = false,
        Threaded_Sound = false,
        FBORender_CheapOcclusion = true,
    GFX_BuildingInteriorCull = true,
    Vehicle_PhysicsSleep = false,
    GFX_DynamicZoomLOD = true,
    Animal_ThrottleDistant = true,
    GFX_ForestCanopyCull = true,
    Combat_BurstSmoother = true,
    Horde_AudioConcurrencyLimit = true,
    Horde_CullDistantAttachments = true,
    Horde_StaggeredAITicking = true,
        Sound_AutoPruneQueue = false,
        FPS_BackgroundThrottle = false,
        Threading_Pathfinding = false,
        Threading_Animation = false,
        Threading_GridStacks = false,
        Threading_Ambient = false,
        Lighting_AdaptiveFPS = false,
        Lighting_FPS = 30,
        Fire_ThrottleParticles = true,
        Weather_Optimize = true,
        Weather_MaxRainDensity = 0.70,
        Animal_Optimize = true,
        Animal_CleanTracks = true,
        Fire_Optimize = true,
        GC_SmartIdleGC = true,
        ModShield_Enabled = true,
    Plumbing_ThrottleWaterPipes = true,
        
        Admin_ProtectSafehouses = true,
        GFX_DynamicReflections = false,
        GFX_ModelLighting = true,
        GFX_CustomShaders = true,
        Horde_ThrottleStaticAnims = false,
        Horde_AccelerateAnimFalloff = false,
        
        Weather_ClampRainParticles = false,
        Weather_PuddleOptimization = true,
        Weather_DisableTreeWind = false,
        Base_ProtectPlayerStructures = true,
        Admin_StaggerPerTick = 20
    },
    Minimalist = {
        Blood_CapPerTile = false,
        Blood_AutoClean = false,
        Corpse_AutoClean = false,
        Corpse_MuteFlies = false,
        Corpse_CullShadows = false,
        Debris_AutoClean = false,
        Horde_ImposterRendering = false,
        Horde_OffscreenAnimDelay = false,
        Threaded_Lighting = false,
        Threaded_Sound = false,
        FBORender_CheapOcclusion = false,
        Sound_AutoPruneQueue = false,
        FPS_BackgroundThrottle = false,
        Threading_Pathfinding = false,
        Threading_Animation = false,
        Threading_GridStacks = false,
        Threading_Ambient = false,
        Lighting_AdaptiveFPS = false,
        Lighting_FPS = 30,
        Fire_ThrottleParticles = false,
        Weather_Optimize = false,
        Weather_MaxRainDensity = 0.85,
        Animal_Optimize = true,
        Animal_CleanTracks = false,
        Fire_Optimize = true,
        GC_SmartIdleGC = false,
    ModShield_Enabled = true,
    Plumbing_ThrottleWaterPipes = true,
    
        Vehicle_ChunkPriorityMode = true,
        Vehicle_LimitDriveZoom = true,
        Vehicle_PreDrivePurge = false,
        Vehicle_ScaleLightingFPS = true,
        Vehicle_SpeedThreshold = 20,
        Vehicle_ThrottleRoadsideZombies = false,
        Vehicle_BoostImposterDistance = false,
        Vehicle_SuspendBackgroundCleanups = true,
        Vehicle_ThreadedModelSlots = true,
        GFX_DynamicReflections = false,
        GFX_ModelLighting = true,
        GFX_CustomShaders = true,
        Horde_ThrottleStaticAnims = false,
        Horde_AccelerateAnimFalloff = false,
        
        Weather_ClampRainParticles = false,
        Audio_ReplacerSafeMode = true,
        Audio_AntiClipping = true,
        UI_ShowContextMenu = false
    },
    TestModeVanilla = {
        GFX_BuildingInteriorCull = false,
        Combat_BurstSmoother = false,
        Horde_AudioConcurrencyLimit = false,
        Horde_CullDistantAttachments = false,
        Horde_StaggeredAITicking = false,
        ModShield_Enabled = false,
        
        Vehicle_PhysicsSleep = false,
        GFX_DynamicZoomLOD = false,
        Animal_ThrottleDistant = false,
        GFX_ForestCanopyCull = false,
        Blood_CapPerTile = false,
        Blood_AutoClean = false,
        Corpse_AutoClean = false,
        Corpse_MuteFlies = false,
        Corpse_CullShadows = false,
        Debris_AutoClean = false,
        Horde_ImposterRendering = false,
        Horde_OffscreenAnimDelay = false,
        Threaded_Lighting = false,
        Threaded_Sound = false,
        FBORender_CheapOcclusion = false,
        Sound_AutoPruneQueue = false,
        FPS_BackgroundThrottle = false,
        Threading_Pathfinding = false,
        Threading_Animation = false,
        Threading_GridStacks = false,
        Threading_Ambient = false,
        Lighting_AdaptiveFPS = false,
        Lighting_FPS = 15,
        Fire_ThrottleParticles = false,
        Weather_Optimize = false,
        Weather_MaxRainDensity = 1.00,
        Weather_PuddleOptimization = false,
        Animal_Optimize = false,
        Animal_CleanTracks = false,
        Fire_Optimize = false,
        GC_SmartIdleGC = false,
    ModShield_Enabled = true,
    Plumbing_ThrottleWaterPipes = true,
    
        Vehicle_ChunkPriorityMode = false,
        GFX_EnforceTextureCompression = false,
        GFX_DynamicReflections = true,
        GFX_ModelLighting = true,
        GFX_CustomShaders = true,
        Horde_ThrottleStaticAnims = false,
        Horde_AccelerateAnimFalloff = false,
        
        Weather_ClampRainParticles = false,
        Base_ProtectPlayerStructures = false,
        Admin_ProtectSafehouses = false,
        Audio_AntiClipping = false,
        Audio_ReplacerSafeMode = true,
        UI_ShowContextMenu = false
    }
}

MPOptim.Presets.Aggressive = MPOptim.Presets.Potato
MPOptim.Presets.PotatoPC = MPOptim.Presets.Potato

function MPOptim.Config.GetActivePresetName()
    if not MPOptim.Config.Current or not MPOptim.Presets then
        return "Custom"
    end

    local function matches(presetTbl)
        if not presetTbl then return false end
        for k, v in pairs(presetTbl) do
            if MPOptim.Config.Current[k] ~= v then
                return false
            end
        end
        return true
    end

    if matches(MPOptim.Presets.Balanced) then
        return "Balanced"
    elseif matches(MPOptim.Presets.Potato) then
        return "Potato"
    elseif matches(MPOptim.Presets.Experimental) then
        return "Experimental"
    elseif matches(MPOptim.Presets.Server) then
        return "Server"
    elseif matches(MPOptim.Presets.TestModeVanilla) then
        return "Test Mode"
    end

    return "Custom"
end

function MPOptim.Config.ApplyPreset(presetName)
    local preset = MPOptim.Presets[presetName]
    if not preset then return false end
    for k, v in pairs(preset) do
        MPOptim.Config.Set(k, v)
    end
    MPOptim.Config.Save()
    return true
end

local CONFIG_FILENAME = "MPOptim_Settings.ini"

function MPOptim.Config.Save()
    if not getFileWriter then return false end
    local writer = getFileWriter(CONFIG_FILENAME, true, false)
    if not writer then return end
    writer:writeln("# Project Zomboid Optimiser Config")
    for k, v in pairs(MPOptim.Config.Current) do
        writer:writeln(tostring(k) .. "=" .. tostring(v))
    end
    writer:close()
    if MPOptim.ModOptions and MPOptim.ModOptions.SyncFromConfig then
        MPOptim.ModOptions.SyncFromConfig()
    end
    return true
end

function MPOptim.Config.Load()
    MPOptim.Config.Current = MPOptim.Config.Current or {}
    if not getFileReader then return false end
    local reader = getFileReader(CONFIG_FILENAME, false)
    if not reader then return end

    local line = reader:readLine()
    while line do
        local trimmed = string.match(line, "^%s*(.-)%s*$") or ""
        if trimmed ~= "" and string.sub(trimmed, 1, 1) ~= "#" and string.sub(trimmed, 1, 1) ~= ";" then
            local k, v = string.match(trimmed, "^([^=]+)=(.*)$")
            if k and v then
                local key = string.match(k, "^%s*(.-)%s*$")
                local rawVal = string.match(v, "^%s*(.-)%s*$")
                if MPOptim.DefaultConfig[key] ~= nil then
                    local currentType = type(MPOptim.DefaultConfig[key])
                    if currentType == "boolean" then
                        MPOptim.Config.Current[key] = (rawVal == "true" or rawVal == "1")
                    elseif currentType == "number" then
                        local num = tonumber(rawVal)
                        if num then MPOptim.Config.Current[key] = num end
                    else
                        MPOptim.Config.Current[key] = rawVal
                    end
                end
            end
        end
        line = reader:readLine()
    end
    reader:close()
    return true
end

function MPOptim.Config.Get(key)
    if MPOptim.Config and MPOptim.Config.Current and MPOptim.Config.Current[key] ~= nil then
        return MPOptim.Config.Current[key]
    end
    if MPOptim.DefaultConfig and MPOptim.DefaultConfig[key] ~= nil then
        return MPOptim.DefaultConfig[key]
    end
    return nil
end

function MPOptim.Config.SyncToEngine()
    local bridge = (type(PZOEngineBridge) == "table" and PZOEngineBridge) or (type(PZOEngine) == "table" and PZOEngine)
    if bridge then
        if type(bridge.setJvmOption) == "function" then
            local boolKeys = { "JVM_GLStateOptimizer", "JVM_StreamBufferBoost", "JVM_ZeroStutterGC", "JVM_DeepChunkCache", "JVM_PowerShield", "JVM_AsyncModelCompile", "JVM_HordeHibernation" }
            for _, k in ipairs(boolKeys) do
                local val = MPOptim.Config.Get(k)
                if val ~= nil then
                    bridge.setJvmOption(k, val == true)
                end
            end
        end
        if type(bridge.setJvmIntOption) == "function" then
            local intKeys = { "JVM_ChunkCacheSize", "JVM_GCThresholdMB" }
            for _, k in ipairs(intKeys) do
                local val = tonumber(MPOptim.Config.Get(k))
                if val then
                    bridge.setJvmIntOption(k, val)
                end
            end
        end
    end
end

function MPOptim.Config.Set(key, value)
    if not MPOptim.Config.Current then MPOptim.Config.Current = {} end
    MPOptim.Config.Current[key] = value

    local bridge = (type(PZOEngineBridge) == "table" and PZOEngineBridge) or (type(PZOEngine) == "table" and PZOEngine)
    if bridge then
        if string.find(key, "^JVM_") then
            if type(value) == "boolean" and type(bridge.setJvmOption) == "function" then
                bridge.setJvmOption(key, value)
            elseif type(value) == "number" and type(bridge.setJvmIntOption) == "function" then
                bridge.setJvmIntOption(key, value)
            end
        end
    end
end

function MPOptim.Config.ResetDefaults()
    for k, v in pairs(MPOptim.DefaultConfig) do
        MPOptim.Config.Current[k] = v
    end
    MPOptim.Config.Save()
    MPOptim.Config.SyncToEngine()
end

Events.OnGameStart.Add(MPOptim.Config.Load)
Events.OnGameStart.Add(MPOptim.Config.SyncToEngine)
if Events.OnMainMenuEnter then
    Events.OnMainMenuEnter.Add(MPOptim.Config.Load)
    Events.OnMainMenuEnter.Add(MPOptim.Config.SyncToEngine)
end
if Events.OnGameBoot then
    Events.OnGameBoot.Add(MPOptim.Config.Load)
    Events.OnGameBoot.Add(MPOptim.Config.SyncToEngine)
end

-- Immediately load settings from disk on file load
MPOptim.Config.Load()
MPOptim.Config.SyncToEngine()