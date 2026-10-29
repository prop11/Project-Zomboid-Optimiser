--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_SettingsRegistry.lua
    Author: prop11
    Description: Every setting the settings screen shows: where it lives, its controls, and what it does to each resource.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.Settings = MPOptim.Settings or {}
local S = MPOptim.Settings

-- Resources a setting can affect, in display order. Icons are media/ui/MPOptim/Icon_<id>_<size>.png.
S.Resources = {
    { id = "CPU",    label = "CPU" },
    { id = "RAM",    label = "RAM" },
    { id = "VRAM",   label = "VRAM" },
    { id = "GPU",    label = "GPU" },
    { id = "FPS",    label = "FPS" },
    { id = "Smooth", label = "Smoothness" },
    { id = "Visual", label = "Visuals" },
    { id = "Load",   label = "Load times" },
}

S.Tabs = {
    { id = "dashboard", label = "Dashboard",       textKey = "UI_MPOptim_TabDashboard" },
    { id = "graphics",  label = "Graphics & CPU",  textKey = "UI_MPOptim_TabGraphics" },
    { id = "hordes",    label = "Hordes & Combat", textKey = "UI_MPOptim_TabHordes" },
    { id = "vehicles",  label = "Vehicles",        textKey = "UI_MPOptim_TabVehicles" },
    { id = "cleanup",   label = "World Cleanup",   textKey = "UI_MPOptim_TabCleanup" },
    { id = "java",      label = "Java Engine",     textKey = "UI_MPOptim_TabJava" },
    { id = "profiler",  label = "Mod Profiler",    textKey = "UI_MPOptim_TabProfiler" },
}

local function applyHorde()
    if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
end

local function applyWeather()
    if MPOptim.WeatherOptimizer and MPOptim.WeatherOptimizer.Update then MPOptim.WeatherOptimizer.Update() end
end

local function applyFire()
    if MPOptim.FireOptimizer and MPOptim.FireOptimizer.Apply then MPOptim.FireOptimizer.Apply() end
end

local function applyAnimals()
    if MPOptim.AnimalOptimizer and MPOptim.AnimalOptimizer.Update then MPOptim.AnimalOptimizer.Update() end
end

local function fmtSuffix(suffix)
    return function(v) return tostring(v) .. suffix end
end

--[[
    Each entry:
      key          config key of the switch (nil for a value-only setting)
      values       list of value rows { key, values, format(v), label }; each is its own row under the card, locked
                   while the switch is off
      impact       what turning the switch ON does: resource id -> -3..3, positive = better for the player
                   (saves the resource, smoother, looks better), negative = worse. Only effects the code really has.
      valueHint    one line on what the value(s) trade off
      requires     config key of a master switch this one only works under
      experimental may cause problems; never recommended over leaving it off
      needsJava    only works with the PZO Java engine
      note         caveat shown on the card (deletes things, takes effect next launch, ...)
      recommend    fixed verdict ("on"/"off") for settings that protect things rather than trade resources
      noVerdict    a preference with no resource trade-off; no verdict shown
      onChange     called after the switch is set
      onValueChange called after a value is set
    Labels and descriptions are translated through UI_MPOptim_Set_<key> / UI_MPOptim_SetTip_<key> (the first value's
    key for a value-only setting) and value labels through UI_MPOptim_SetValue_<value key>; the English here is the
    fallback.
--]]
S.List = {
    -- Dashboard ---------------------------------------------------------------------------------------------------
    { tab = "dashboard", section = "Interface",
      key = "UI_ShowHUD",
      label = "Performance Overlay",
      tip = "A small box with your FPS, Lua memory and a frame graph. Drag it to move it.",
      noVerdict = true,
      onChange = function(on)
          if getPlayer and getPlayer() and MPOptim.SetHUDVisible then MPOptim.SetHUDVisible(on) end
      end },
    { tab = "dashboard", section = "Interface",
      key = "UI_ShowNotifications",
      label = "Cleanup Messages",
      tip = "Shows a short message over your character when a cleanup or memory sweep runs.",
      noVerdict = true },
    { tab = "dashboard", section = "Interface",
      key = "UI_ShowContextMenu",
      label = "Right-Click Menu Entry",
      tip = "Adds the Optimiser to the right-click menu in the world for quick cleanups and this screen.",
      noVerdict = true },

    -- Graphics & CPU ----------------------------------------------------------------------------------------------
    { tab = "graphics", section = "Textures & memory",
      key = "GFX_EnforceTextureCompression",
      label = "Enforce Texture Compression",
      tip = "Turns on the game's texture compression in options.ini. Textures use far less video memory and load with fewer hitches.",
      note = "Takes full effect after a restart.",
      impact = { VRAM = 3, Visual = -1 },
      onChange = function(on)
          if on and MPOptim.Utils and MPOptim.Utils.CheckAndEnforceTextureCompression then MPOptim.Utils.CheckAndEnforceTextureCompression() end
      end },
    { tab = "graphics", section = "Textures & memory",
      key = "UI_FastInventory",
      label = "Faster Inventory Tooltips",
      tip = "Skips rebuilding the inventory item tooltip while the mouse is not moving.",
      impact = { CPU = 1 } },

    { tab = "graphics", section = "Occlusion & culling",
      key = "GFX_BuildingInteriorCull",
      label = "Multi-Story Building Occlusion",
      tip = "Inside a multi-story building, floors you cannot see are not drawn. Restored outside and in vehicles.",
      impact = { GPU = 2, CPU = 1 },
      onChange = function() if MPOptim.BuildingOptimizer and MPOptim.BuildingOptimizer.Update then MPOptim.BuildingOptimizer.Update() end end },
    { tab = "graphics", section = "Occlusion & culling",
      key = "FBORender_CheapOcclusion",
      label = "Cheaper Cutaway Occlusion",
      tip = "Uses the game's cheaper occlusion count for cutaway walls and upper floors.",
      impact = { CPU = 1 },
      onChange = applyHorde },
    { tab = "graphics", section = "Occlusion & culling",
      key = "GFX_ForestCanopyCull",
      label = "Bake Distant Swaying Trees",
      tip = "Trees and bushes far from you are drawn into the chunk's cached image instead of being redrawn every frame with wind sway. Stands down when Atmospherics is active.",
      impact = { GPU = 2, CPU = 1, Visual = -1 },
      needsJava = true },
    { tab = "graphics", section = "Occlusion & culling",
      key = "GFX_DynamicZoomLOD",
      label = "Zoomed-Out Animation LOD",
      tip = "When zoomed out to 150 percent or more, fewer zombies get fully blended animations. Your normal setting comes back when you zoom in.",
      impact = { CPU = 2, Visual = -1 },
      onChange = function() if MPOptim.ZoomLOD and MPOptim.ZoomLOD.Update then MPOptim.ZoomLOD.Update() end end },

    { tab = "graphics", section = "Lighting & shaders",
      key = "GFX_CustomShaders",
      label = "Wall, Puddle and Water Shaders",
      tip = "The game's wall, puddle and water shaders (on in vanilla). Turning them off saves GPU time but looks flatter. Turn off if you see shader glitches on your GPU.",
      impact = { GPU = -1, Visual = 2 },
      onChange = function() applyHorde() applyWeather() end },
    { tab = "graphics", section = "Lighting & shaders",
      key = "GFX_ModelLighting",
      label = "Dynamic Lighting on Characters",
      tip = "Lights characters and zombies with nearby light sources (on in vanilla). Off uses the room's ambient light instead.",
      impact = { GPU = -1, CPU = -1, Visual = 2 },
      onChange = applyHorde },
    { tab = "graphics", section = "Lighting & shaders",
      key = "Threaded_Lighting",
      label = "Multi-Threaded Lighting",
      tip = "Moves dynamic lighting updates to a background thread. May cause short stalls in heavy combat.",
      impact = { CPU = 2, Smooth = -1 },
      experimental = true,
      onChange = applyHorde },
    { tab = "graphics", section = "Lighting & shaders",
      label = "Lighting Refresh Rate",
      tip = "How many times a second dynamic lighting is recalculated. Presets set this too.",
      impact = {},
      values = { { key = "Lighting_FPS", values = { 15, 20, 30, 45, 60 }, format = fmtSuffix(" FPS"), label = "Refresh rate" } },
      valueHint = "Lower saves CPU; lights update less often.",
      onValueChange = applyHorde },

    { tab = "graphics", section = "System & mod protection",
      key = "ModShield_Enabled",
      label = "ModShield",
      tip = "Mods that force a full memory sweep mid-game are held back until you sleep, read or rest. Each repeated mod error is printed only 3 times. Broken vehicle repair recipes from mods are repaired.",
      impact = { Smooth = 2 } },
    { tab = "graphics", section = "System & mod protection",
      key = "Plumbing_ThrottleWaterPipes",
      label = "Water Pipes Throttle",
      tip = "Runs the per-frame updates of Water Pipes and irrigation mods once a second. Only matters with those mods.",
      impact = { CPU = 2 } },
    { tab = "graphics", section = "System & mod protection",
      key = "GC_SmartIdleGC",
      label = "Smart Idle Memory Sweep",
      tip = "Runs a full memory sweep only while you sleep, read or rest, and only above the threshold below.",
      impact = { RAM = 1 },
      values = { { key = "GC_PurgeThresholdMB", values = { 1200, 1600, 2000, 2400, 2800, 3200, 4000 }, format = fmtSuffix(" MB"), label = "Sweep above" } },
      valueHint = "Lower sweeps more often." },

    -- Hordes & Combat ---------------------------------------------------------------------------------------------
    { tab = "hordes", section = "Animation",
      key = "Horde_ThrottleStaticAnims",
      label = "Slower Idle Animations",
      tip = "Characters standing still, sleeping or idle update their animation 15 times a second instead of 30.",
      impact = { CPU = 2, Visual = -1 },
      onChange = applyHorde },
    { tab = "hordes", section = "Animation",
      key = "Horde_AccelerateAnimFalloff",
      label = "Earlier Animation LOD for Far Zombies",
      tip = "Distant zombies switch to cheaper, stepped animation sooner.",
      impact = { CPU = 1, Visual = -1 },
      onChange = applyHorde },
    { tab = "hordes", section = "Animation",
      key = "Horde_OffscreenAnimDelay",
      label = "Off-Screen Animation Delay",
      tip = "Uses the game's animation delay for zombies outside your view, so their skeletons update less often.",
      impact = { CPU = 2 },
      onChange = applyHorde },
    { tab = "hordes", section = "Animation",
      key = "Horde_CullDistantAttachments",
      label = "Distant Zombie Attachment Culling",
      tip = "Items worn on belts, backs and holsters of zombies more than 25 tiles from you are not drawn. Their items are untouched and reappear as they come closer.",
      impact = { GPU = 1, CPU = 1, Visual = -1 },
      needsJava = true },

    { tab = "hordes", section = "Combat & swarms",
      key = "Combat_BurstSmoother",
      label = "Multi-Kill Hitch Smoother",
      tip = "Blood and corpse changes from many kills at once re-draw many cached chunk images in one frame. They are spread over a few frames instead; the old image shows meanwhile.",
      impact = { Smooth = 2 },
      needsJava = true },
    { tab = "hordes", section = "Combat & swarms",
      key = "Horde_AudioConcurrencyLimit",
      label = "Horde Voice Limit",
      tip = "Fewer zombies groan at once: only the nearest ones, as set below, get a voice (the game allows 20).",
      impact = { CPU = 1 },
      needsJava = true,
      values = { { key = "Horde_VoiceLimit", values = { 8, 12, 16, 20 }, format = fmtSuffix(" voices"), label = "Voices at once" } },
      valueHint = "Lower is quieter in big hordes." },
    { tab = "hordes", section = "Combat & swarms",
      key = "Horde_ImposterRendering",
      label = "2D Imposters for Distant Zombies",
      tip = "Distant zombies in large hordes are drawn as flat 2D images, with instanced rendering. May stutter when zombies change state.",
      impact = { GPU = 2, Visual = -2, Smooth = -1 },
      experimental = true,
      onChange = applyHorde },

    -- Vehicles ----------------------------------------------------------------------------------------------------
    { tab = "vehicles", section = "Driving",
      key = "Vehicle_ChunkPriorityMode",
      label = "Driving Optimizations",
      tip = "Master switch for the driving options below. They start above the speed set here and stop again once you slow down.",
      impact = {},
      noVerdict = true,
      values = { { key = "Vehicle_SpeedThreshold", values = { 10, 15, 20, 25, 30, 40, 50 }, format = fmtSuffix(" km/h"), label = "Start above" } } },
    { tab = "vehicles", section = "Driving",
      key = "Vehicle_SuspendBackgroundCleanups", requires = "Vehicle_ChunkPriorityMode",
      label = "Pause Cleanups While Driving",
      tip = "Pauses this mod's background sweeps (blood, corpses, debris) while driving fast.",
      impact = { Smooth = 1 } },
    { tab = "vehicles", section = "Driving",
      key = "Vehicle_PreDrivePurge", requires = "Vehicle_ChunkPriorityMode",
      label = "Memory Sweep When Getting In",
      tip = "Runs one full memory sweep when you get in a vehicle: a short hitch then, instead of one landing mid-drive.",
      impact = { RAM = 1, Smooth = -1 } },
    { tab = "vehicles", section = "Driving",
      key = "Vehicle_LimitDriveZoom", requires = "Vehicle_ChunkPriorityMode",
      label = "No Auto-Zoom While Driving",
      tip = "Stops the camera zooming out with speed. Less to draw, but you see less of the road ahead.",
      impact = { GPU = 1, Visual = -1 } },
    { tab = "vehicles", section = "Driving",
      key = "Vehicle_ScaleLightingFPS", requires = "Vehicle_ChunkPriorityMode",
      label = "Slower Lighting While Driving",
      tip = "Halves the lighting refresh rate (not below 30) while driving fast. New road chunks may light up a moment late.",
      impact = { CPU = 1, Visual = -1 } },
    { tab = "vehicles", section = "Driving",
      key = "Vehicle_ThreadedModelSlots",
      label = "Background 3D Model Loading",
      tip = "Vehicle parts and clothing models are prepared on background threads instead of stalling the frame.",
      impact = { Smooth = 2 },
      onChange = applyHorde },
    { tab = "vehicles", section = "Driving",
      key = "Vehicle_ThrottleRoadsideZombies", requires = "Vehicle_ChunkPriorityMode",
      label = "Cheaper Roadside Zombies",
      tip = "While driving fast, fewer zombies get fully blended animations. Restored when you slow down.",
      impact = { CPU = 2, Visual = -1 },
      experimental = true },
    { tab = "vehicles", section = "Driving",
      key = "Vehicle_BoostImposterDistance", requires = "Vehicle_ChunkPriorityMode",
      label = "2D Imposters While Driving",
      tip = "While driving fast, distant zombies are drawn as flat 2D images. Restored when you slow down.",
      impact = { GPU = 2, Visual = -2 },
      experimental = true },
    { tab = "vehicles", section = "Visuals",
      key = "GFX_DynamicReflections",
      label = "Road and Puddle Reflections",
      tip = "The game's reflection pass on roads and puddles. Looks better, costs GPU, most of all in rain.",
      impact = { GPU = -2, Visual = 2 },
      onChange = function(on) if getCore and getCore().setPerfReflections then getCore():setPerfReflections(on == true) end end },

    -- World Cleanup -----------------------------------------------------------------------------------------------
    { tab = "cleanup", section = "Blood",
      key = "Blood_CapPerTile",
      label = "Blood Stacking Cap",
      tip = "Limits how many blood splats pile up on one tile.",
      impact = { GPU = 1 } },
    { tab = "cleanup", section = "Blood",
      key = "Blood_AutoClean",
      label = "Automatic Blood Cleanup",
      tip = "Removes floor blood around you on a timer.",
      impact = { GPU = 1, Visual = -1 },
      values = { { key = "Blood_CleanRadius", values = { 15, 20, 30, 40, 50, 60 }, format = fmtSuffix(" tiles"), label = "Radius" },
                 { key = "Blood_IntervalHours", values = { 1, 2, 4, 8, 12, 24 }, format = fmtSuffix(" hours"), label = "Every" } } },
    { tab = "cleanup", section = "Blood",
      key = "Blood_RemoveWall", requires = "Blood_AutoClean",
      label = "Include Wall Blood",
      tip = "Blood cleanup also removes splatter on walls, not just floors.",
      impact = { GPU = 1, Visual = -1 } },

    { tab = "cleanup", section = "Corpses",
      key = "Corpse_AutoClean",
      label = "Automatic Corpse Cleanup",
      tip = "Removes old zombie corpses around you on a timer, outside safehouses and player bases.",
      note = "Deletes corpses and anything still on them that the options below allow.",
      impact = { CPU = 2, RAM = 1, Load = 1 },
      values = { { key = "Corpse_MinAgeHours", values = { 0, 4, 6, 12, 24, 48, 72 }, format = function(v) return v == 0 and "Any age" or (tostring(v) .. " hours old") end, label = "Older than" },
                 { key = "Corpse_CleanRadius", values = { 15, 20, 30, 40, 50, 60 }, format = fmtSuffix(" tiles"), label = "Radius" },
                 { key = "Corpse_IntervalHours", values = { 1, 2, 4, 6, 12, 24 }, format = fmtSuffix(" hours"), label = "Every" } } },
    { tab = "cleanup", section = "Corpses",
      key = "Corpse_CleanEmptyOnly", requires = "Corpse_AutoClean",
      label = "Only Empty Corpses",
      tip = "Only removes corpses with nothing left on them.",
      impact = {}, noVerdict = true },
    { tab = "cleanup", section = "Corpses",
      key = "Corpse_CleanJunkOnly", requires = "Corpse_AutoClean",
      label = "Also Junk-Only Corpses",
      tip = "Also removes corpses carrying only junk; any corpse with weapons, bags, ammo or keys is kept.",
      impact = {}, noVerdict = true },
    { tab = "cleanup", section = "Corpses",
      key = "Corpse_CullShadows",
      label = "No Shadows Under Corpses",
      tip = "Turns off the game's corpse shadows.",
      impact = { GPU = 1, Visual = -1 },
      onChange = applyHorde },

    { tab = "cleanup", section = "Ground clutter",
      key = "Debris_AutoClean",
      label = "Automatic Debris Cleanup",
      tip = "Removes the kinds of ground clutter chosen below around you on a timer. Logs, player bases and safehouses are never touched.",
      note = "Deletes items from the ground.",
      impact = { CPU = 1, Load = 1 },
      values = { { key = "Debris_CleanRadius", values = { 15, 25, 35, 45, 60, 75 }, format = fmtSuffix(" tiles"), label = "Radius" },
                 { key = "Debris_IntervalHours", values = { 2, 4, 8, 12, 24, 48 }, format = fmtSuffix(" hours"), label = "Every" } } },
    { tab = "cleanup", section = "Ground clutter",
      key = "Debris_CleanCasings", requires = "Debris_AutoClean",
      label = "Spent Casings and Shells", tip = "Bullet casings and shotgun shells.", impact = {}, noVerdict = true },
    { tab = "cleanup", section = "Ground clutter",
      key = "Debris_CleanTrash", requires = "Debris_AutoClean",
      label = "Trash", tip = "Empty cans, bottles, wrappers, ashes and cigarette butts.", impact = {}, noVerdict = true },
    { tab = "cleanup", section = "Ground clutter",
      key = "Debris_CleanTwigsAndWood", requires = "Debris_AutoClean",
      label = "Twigs, Branches and Stones", tip = "Fallen twigs, branches and loose stones. Logs are never removed.", impact = {}, noVerdict = true },
    { tab = "cleanup", section = "Ground clutter",
      key = "Debris_CleanBrokenGlass", requires = "Debris_AutoClean",
      label = "Broken Glass", tip = "Glass shards on the ground.", impact = {}, noVerdict = true },
    { tab = "cleanup", section = "Ground clutter",
      key = "Debris_CleanRottenFood", requires = "Debris_AutoClean",
      label = "Rotten Food", tip = "Fully rotten food lying on the ground.", impact = {}, noVerdict = true },
    { tab = "cleanup", section = "Ground clutter",
      key = "Animal_CleanTracks",
      label = "Old Animal Tracks",
      tip = "Removes aged animal footprints far from you.",
      impact = { CPU = 1, Load = 1 } },

    { tab = "cleanup", section = "Weather, fire and animals",
      key = "Weather_Optimize",
      label = "Storm Optimization",
      tip = "Caps rain strength at the level below and uses the game's ground-only puddle mode. The two options under it need this on.",
      note = "Rain is lighter in strong storms.",
      impact = { GPU = 1, CPU = 1, Visual = -1 },
      values = { { key = "Weather_MaxRainDensity", values = { 0.40, 0.50, 0.60, 0.70, 0.85, 1.00 }, format = function(v) return tostring(math.floor(v * 100 + 0.5)) .. " percent" end, label = "Max rain" } },
      onChange = applyWeather, onValueChange = applyWeather },
    { tab = "cleanup", section = "Weather, fire and animals",
      key = "Weather_PuddleOptimization", requires = "Weather_Optimize",
      label = "Cap Fog Density",
      tip = "Caps fog strength at 85 percent.",
      impact = { GPU = 1, Visual = -1 },
      onChange = applyWeather },
    { tab = "cleanup", section = "Weather, fire and animals",
      key = "Weather_DisableTreeWind", requires = "Weather_Optimize",
      label = "No Tree Wind Sway",
      tip = "Turns off the game's wind sway on trees and plants. Turned back on when you switch this off.",
      impact = { CPU = 1, GPU = 1, Visual = -1 },
      onChange = applyWeather },
    { tab = "cleanup", section = "Weather, fire and animals",
      key = "Weather_ClampRainParticles",
      label = "Fewer Rain Splashes",
      tip = "Caps rain drops and splashes on screen at 40.",
      impact = { GPU = 1, Visual = -1 },
      onChange = applyWeather },
    { tab = "cleanup", section = "Weather, fire and animals",
      key = "Fire_ThrottleParticles",
      label = "Lighter Fire Effects",
      tip = "Caps fire particles, fire objects and smoke in large fires, and burning characters no longer light their surroundings.",
      impact = { GPU = 1, CPU = 1, Visual = -1 },
      values = { { key = "Fire_MaxEmitters", values = { 4, 6, 8, 12, 16, 24 }, format = tostring, label = "Fire effect budget" } },
      valueHint = "Higher allows bigger fires to look fuller.",
      onChange = applyFire, onValueChange = applyFire },
    { tab = "cleanup", section = "Weather, fire and animals",
      key = "Animal_Optimize",
      label = "Animal Optimizations",
      tip = "Master switch for the animal option below.",
      impact = {}, noVerdict = true,
      onChange = applyAnimals },
    { tab = "cleanup", section = "Weather, fire and animals",
      key = "Animal_ThrottleDistant", requires = "Animal_Optimize",
      label = "Quiet Distant Animals",
      tip = "Animals more than 35 tiles away stop making sounds once the number below are already heard nearby.",
      impact = { CPU = 1 },
      values = { { key = "Animal_MaxAudioEmitters", values = { 2, 4, 6, 8, 12 }, format = fmtSuffix(" animals"), label = "Heard at once" } },
      onChange = applyAnimals, onValueChange = applyAnimals },

    { tab = "cleanup", section = "Protection",
      key = "Base_ProtectPlayerStructures",
      label = "Protect Player Bases",
      tip = "Player-built structures, barrels, fuel cans and generators are never touched by any cleanup.",
      impact = {}, recommend = "on" },
    { tab = "cleanup", section = "Protection",
      key = "Admin_ProtectSafehouses",
      label = "Protect Safehouses",
      tip = "Nothing inside a claimed safehouse is touched by any cleanup.",
      impact = {}, recommend = "on" },
    { tab = "cleanup", section = "Protection",
      label = "Cleanup Scan Speed",
      tip = "How many tiles background cleanups check per frame.",
      impact = {},
      values = { { key = "Admin_StaggerPerTick", values = { 5, 10, 15, 20, 25, 35, 50 }, format = fmtSuffix(" tiles per frame"), label = "Scan speed" } },
      valueHint = "Higher finishes sweeps sooner but costs more per frame." },

    -- Java Engine -------------------------------------------------------------------------------------------------
    { tab = "java", section = "Memory and CPU",
      key = "JVM_ZeroStutterGC",
      label = "Collect Memory in Spare Frame Time",
      tip = "When the Java heap is about to need a collection, it is started in a frame that has time to spare, instead of landing mid-step during combat or driving.",
      impact = { Smooth = 2 }, needsJava = true },
    { tab = "java", section = "Memory and CPU",
      key = "JVM_PowerShield",
      label = "CPU Power Shield",
      tip = "Sets the 0.5 ms system timer, exempts the game from Windows power throttling, and on CPUs with enough cores uses MMCSS game scheduling and a higher process priority.",
      note = "Takes effect on the next launch.",
      impact = { Smooth = 2, FPS = 1 }, needsJava = true },
    { tab = "java", section = "Memory and CPU",
      key = "JVM_GLStateOptimizer",
      label = "Skip Repeated GPU State Uploads",
      tip = "Shader values and bone matrices identical to what the GPU already has are not sent again.",
      impact = { CPU = 1, FPS = 1 }, needsJava = true },
    { tab = "java", section = "Memory and CPU",
      key = "JVM_AsyncModelCompile",
      label = "Background Texture Downscaling",
      tip = "Clothing and vehicle textures larger than your texture size option are shrunk on a worker thread instead of in the frame, removing a 100 to 250 ms hitch per large texture.",
      impact = { Smooth = 2 }, needsJava = true },

    { tab = "java", section = "Zombies",
      key = "JVM_HordeHibernation",
      label = "Slower Updates for Unseen Zombies",
      tip = "Zombies no player can see update less often when your frame rate is high, as the game already does at lower frame rates.",
      impact = { CPU = 2 }, needsJava = true },
    { tab = "java", section = "Zombies",
      key = "JVM_BytecodeBloodCap",
      label = "One Blood Splat per Tile",
      tip = "A tile that already has blood gets no more, which avoids re-drawing its chunk image on every hit.",
      impact = { Smooth = 1, Visual = -1 }, needsJava = true },

    { tab = "java", section = "Pathfinding",
      key = "JVM_PathfindNativeAStar",
      label = "Faster Native Pathfinding",
      tip = "A faster priority queue inside the game's pathfinding library, so paths are found sooner in hordes and complex buildings.",
      impact = { CPU = 2 }, needsJava = true },
    { tab = "java", section = "Pathfinding",
      key = "JVM_PathfindBudget",
      label = "Pathfinding Time Budget",
      tip = "Answers queued path requests until the time below is used up, instead of the game's fixed 2 per pass, so zombies start moving sooner.",
      impact = { Smooth = 1 }, needsJava = true,
      values = { { key = "JVM_PathfindBudgetMs", values = { 1, 2, 3, 5, 8, 10 }, format = fmtSuffix(" ms"), label = "Budget" } } },
    { tab = "java", section = "Pathfinding",
      key = "JVM_PathfindSquareMerge",
      label = "Merge Repeated Square Updates",
      tip = "Several changes to the same square in one pass are sent to the pathfinder as one.",
      impact = { CPU = 1 }, needsJava = true },
    { tab = "java", section = "Pathfinding",
      key = "JVM_PathfindVehicleThrottle",
      label = "Fewer Vehicle Navmesh Updates",
      tip = "A moving vehicle's shape is re-sent to the pathfinder only after it moves a quarter tile or every 250 ms.",
      impact = { CPU = 1 }, needsJava = true },

    { tab = "java", section = "Mod scripts",
      key = "Mod_PacedEventRate",
      label = "Mod Per-Frame Scripts at 60 Hz",
      tip = "Other mods' per-frame scripts run 60 times a second on average, spread over frames. At 60 FPS or less nothing changes, and they always run on a frame with a key or mouse press. Real Limbs and Project A-Life are left alone.",
      impact = { CPU = 2, FPS = 1 }, needsJava = true },
    { tab = "java", section = "Mod scripts",
      key = "Mod_ZombieScriptLOD",
      label = "Mod Zombie Scripts LOD",
      tip = "Other mods' per-zombie scripts run every frame within 15 tiles of you, every 3rd frame to 30 tiles and every 6th beyond. Real Limbs and Project A-Life are left alone.",
      impact = { CPU = 2 }, needsJava = true },

    { tab = "java", section = "FSR upscaling",
      key = "JVM_FSREnabled",
      label = "AMD FSR 1.0 Upscaling",
      tip = "Renders the world below your resolution and upscales it with FSR 1.0. The UI stays sharp.",
      note = "If FSR was off when the game started, switching it on applies on the next launch.",
      impact = { GPU = 3, FPS = 2, Visual = -1 }, needsJava = true,
      values = { { key = "JVM_FSRScale", values = { 50, 59, 67, 77, 85, 90 }, format = function(v)
                    local names = { [50] = "Performance", [59] = "Balanced", [67] = "Quality", [77] = "Ultra Quality" }
                    return (names[v] and (names[v] .. " ") or "") .. tostring(v) .. " percent" end, label = "Render scale" },
                 { key = "JVM_FSRSharpness", values = { 0, 20, 40, 60, 80, 100 }, format = fmtSuffix(" percent"), label = "Sharpness" } },
      valueHint = "Lower scale is faster and softer." },
    { tab = "java", section = "FSR upscaling",
      key = "JVM_FSRDynamic", requires = "JVM_FSREnabled",
      label = "Dynamic Resolution",
      tip = "Lowers the render scale (down to 65 percent) when a frame runs over your target frame time, and raises it again when there is headroom.",
      impact = { Smooth = 1, Visual = -1 }, needsJava = true },
}

function S.ValuesOf(s)
    return s.values or {}
end

function S.ForTab(tabId)
    local out = {}
    for _, s in ipairs(S.List) do
        if s.tab == tabId then out[#out + 1] = s end
    end
    return out
end

function S.IsConverted(tabId)
    for _, s in ipairs(S.List) do
        if s.tab == tabId then return true end
    end
    return false
end

function S.Find(key)
    for _, s in ipairs(S.List) do
        if s.key == key then return s end
    end
    return nil
end

-- Hardware ---------------------------------------------------------------------------------------------------------

local hwCache = nil

local function parseSummary(str)
    local hw = {}
    for k, v in string.gmatch(str or "", "([^;=]+)=([^;]*)") do hw[k] = v end
    hw.cores = tonumber(hw.cores)
    hw.threads = tonumber(hw.threads)
    hw.ramMb = tonumber(hw.ramMb)
    hw.vramMb = tonumber(hw.vramMb)
    return hw
end

-- The Java engine reads it once in the background; without it only RAM (from the engine) or nothing is known
function S.Hardware()
    if hwCache and hwCache.complete then return hwCache end
    local bridge = (type(PZOEngineBridge) == "table" and PZOEngineBridge) or (type(PZOEngine) == "table" and PZOEngine)
    local str = bridge and type(bridge.getHardwareSummary) == "function" and bridge.getHardwareSummary() or ""
    local hw = parseSummary(str)
    hw.complete = (hw.cores ~= nil)
    if not hw.ramMb and type(PZOEngineRAM) == "number" and PZOEngineRAM > 0 then hw.ramMb = PZOEngineRAM * 1024 end
    hwCache = hw
    return hw
end

local function isIntegratedGpu(name)
    local n = string.lower(name or "")
    return n:find("uhd") or n:find("iris") or n:find("intel%(r%) hd") or n:find("radeon%(tm%) graphics")
        or n:find("vega %d graphics") or n:find("680m") or n:find("780m") or n:find("890m") or n:find("steam deck")
end

-- How short this PC is on each resource: 2 = scarce, 1 = normal, 0.25 = plentiful
function S.Scarcity(hw)
    local s = { CPU = 1, RAM = 1, VRAM = 1, GPU = 1, FPS = 1, Smooth = 1.5, Visual = 1, Load = 1 }
    if hw.threads then
        if hw.threads <= 8 then s.CPU = 2 elseif hw.cores and hw.cores >= 8 then s.CPU = 0.25 end
    end
    if hw.ramMb then
        if hw.ramMb < 12000 then s.RAM = 2 elseif hw.ramMb >= 24000 then s.RAM = 0.25 end
    end
    if hw.gpu then
        local weak = isIntegratedGpu(hw.gpu) or (hw.vramMb and hw.vramMb < 4500)
        if weak then
            s.GPU, s.VRAM = 2, 2
        elseif hw.vramMb and hw.vramMb >= 10000 then
            s.GPU, s.VRAM = 0.25, 0.25
        end
    end
    s.FPS = math.max(s.CPU, s.GPU)
    return s
end

-- "on", "off" or "optional": what this PC should do with the switch; "none" when the setting has no effect
function S.Verdict(setting, hw)
    if setting.inactive then return "none" end
    if not setting.key or setting.noVerdict then return nil end
    if setting.recommend then return setting.recommend end
    local scarcity = S.Scarcity(hw or S.Hardware())
    local score = 0
    for res, v in pairs(setting.impact or {}) do
        local w = scarcity[res] or 1
        if res == "Visual" then w = 1 end
        score = score + v * w
    end
    if setting.experimental then
        return score > 0 and "optional" or "off"
    end
    if score >= 0.75 then return "on" end
    if score <= -0.75 then return "off" end
    return "optional"
end

-- One line per resource the switch changes, for tooltips: "Saves VRAM (a lot)"
function S.ImpactLines(setting)
    local sizes = { "a little", "noticeably", "a lot" }
    local lines = {}
    for _, r in ipairs(S.Resources) do
        local v = setting.impact and setting.impact[r.id]
        if v and v ~= 0 then
            local verb
            if r.id == "Visual" then
                verb = v > 0 and "Looks better" or "Looks worse"
            elseif r.id == "Smooth" then
                verb = v > 0 and "Fewer stutters" or "May stutter"
            elseif r.id == "FPS" then
                verb = v > 0 and "Higher FPS" or "Lower FPS"
            elseif r.id == "Load" then
                verb = v > 0 and "Faster loading" or "Slower loading"
            else
                verb = (v > 0 and "Saves " or "Uses more ") .. r.label
            end
            lines[#lines + 1] = verb .. " (" .. sizes[math.min(3, math.abs(v))] .. ")"
        end
    end
    return lines
end

-- "All optimizations": every switch that saves resources overall, except experimental ones, ones that delete things
-- (notes) and ones the Java engine is missing for. Visual quality options are left as they are.
function S.ApplyAllOptimizations()
    if not MPOptim.Config then return end
    local isAgent = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
    for _, s in ipairs(S.List) do
        if s.key and not s.inactive and not s.experimental and not s.note and not s.noVerdict and not s.recommend
                and (not s.needsJava or isAgent) then
            local net = 0
            for res, v in pairs(s.impact or {}) do
                if res ~= "Visual" then net = net + v end
            end
            if net > 0 then
                MPOptim.Config.Set(s.key, true)
                if s.onChange then pcall(s.onChange, true) end
            end
        end
    end
    MPOptim.Config.Save()
end
