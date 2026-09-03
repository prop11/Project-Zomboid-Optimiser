--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_FireAudioOptimizer.lua
    Author: prop11
    Description: Burning horde fire particle throttling and character dynamic light culling via IsoFireManager.java and ParticlesFire.java.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.FireOptimizer = MPOptim.FireOptimizer or {}

function MPOptim.FireOptimizer.Apply()
    if not MPOptim.Config then return end
    local fireOptimize = MPOptim.Config.Get("Fire_Optimize") ~= false
    local throttleFire = MPOptim.Config.Get("Fire_ThrottleParticles") == true
    local activePreset = MPOptim.Config.GetActivePresetName and MPOptim.Config.GetActivePresetName()
    local isPotato = (activePreset == "Potato" or activePreset == "PotatoPC" or activePreset == "Aggressive" or activePreset == "Experimental")
    local maxEmitters = MPOptim.Config.Get("Fire_MaxEmitters") or 8

    -- Hook ParticlesFire.java (Hidden particle pool unexposed in vanilla options)
    if ParticlesFire and ParticlesFire.instance then
        if fireOptimize and (throttleFire or isPotato) then
            ParticlesFire.instance.maxParticles = math.max(30, maxEmitters * 5)
            ParticlesFire.instance.maxVortices = 2
        else
            ParticlesFire.instance.maxParticles = 250
            ParticlesFire.instance.maxVortices = 6
        end
    end

    -- Hook IsoFireManager.java static settings
    if IsoFireManager then
        if fireOptimize and (throttleFire or isPotato) then
            IsoFireManager.maxFireObjects = math.max(20, maxEmitters * 4)
            IsoFireManager.lightCalcFromBurningCharacters = false
            IsoFireManager.smokeAlpha = 0.20
        else
            IsoFireManager.maxFireObjects = 75
            IsoFireManager.lightCalcFromBurningCharacters = true
            IsoFireManager.smokeAlpha = 0.30
        end
    end
end

MPOptim.FireOptimizer.Update = MPOptim.FireOptimizer.Apply

Events.OnGameStart.Add(MPOptim.FireOptimizer.Apply)
Events.OnMainMenuEnter.Add(MPOptim.FireOptimizer.Apply)
