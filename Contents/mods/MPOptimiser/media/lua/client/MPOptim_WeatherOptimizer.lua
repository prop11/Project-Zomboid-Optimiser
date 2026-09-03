--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_WeatherOptimizer.lua
    Author: prop11
    Description: Dynamic Rain particle buffer clamp, screen-space puddle throttling, and fog alpha scaling.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.WeatherOptimizer = MPOptim.WeatherOptimizer or {}

function MPOptim.WeatherOptimizer.Update()
    if not MPOptim.Config then return end

    local activePreset = MPOptim.Config.GetActivePresetName and MPOptim.Config.GetActivePresetName()
    local isPotato = (activePreset == "Potato" or activePreset == "PotatoPC" or activePreset == "Aggressive" or activePreset == "Experimental")
    local maxRain = (MPOptim.Config and MPOptim.Config.Get("Weather_MaxRainDensity")) or 0.70
    local clampRain = MPOptim.Config.Get("Weather_ClampRainParticles") == true

    -- 1. Rain Particle Buffer Clamping via RainManager.java
    if RainManager then
        local maxSplashes = (clampRain or isPotato) and 40 or math.min(60, math.floor(100 * maxRain))
        RainManager.maxRainSplashObjects = maxSplashes
        RainManager.maxRaindropObjects = maxSplashes
    end

    -- 2. Custom Shaders Master Toggle Evaluation
    local enableCustomShaders = (MPOptim.Config and MPOptim.Config.Get("GFX_CustomShaders")) ~= false
    if IsoPuddles then
        IsoPuddles.isShaderEnable = enableCustomShaders and not isPotato
    end

    -- 3. Direct Particle Buffer Scaling via IsoWeatherFX.java
    if not MPOptim.Config.Get("Weather_Optimize") and not isPotato then return end

    local clim = getClimateManager and getClimateManager()
    if not clim then return end

    local fx = (clim.getWeatherFX and clim:getWeatherFX()) or (IsoWeatherFX and IsoWeatherFX.instance)
    if fx then
        if fx.precipitationIntensityRain and fx.precipitationIntensityRain.getTarget then
            local targetRain = fx.precipitationIntensityRain:getTarget()
            if targetRain and targetRain > maxRain then
                if fx.precipitationIntensityRain.setTarget then
                    fx.precipitationIntensityRain:setTarget(maxRain)
                end
            end
        end

        if MPOptim.Config.Get("Weather_PuddleOptimization") and fx.fogIntensity and fx.fogIntensity.getTarget then
            local targetFog = fx.fogIntensity:getTarget()
            local maxFog = isPotato and 0.65 or 0.85
            if targetFog and targetFog > maxFog then
                if fx.fogIntensity.setTarget then
                    fx.fogIntensity:setTarget(maxFog)
                end
            end
        end
    end

    -- 4. Ground-Level Puddle Optimization (perfPuddles = 2: Skips 31 vertical levels AND bypasses 8-neighbor tile lookups)
    if getCore and getCore().getPerfPuddles and getCore().setPerfPuddles then
        local curPerf = getCore():getPerfPuddles()
        if curPerf < 2 then
            getCore():setPerfPuddles(2)
        end
    end

    -- 5. Wind Sprite Distortion on Roadside Trees (Disabled on potato/aggressive or when configured)
    if getCore and getCore().setOptionDoWindSpriteEffects then
        if isPotato or (MPOptim.Config and MPOptim.Config.Get("Weather_DisableTreeWind") == true) then
            if getCore().getOptionDoWindSpriteEffects and getCore():getOptionDoWindSpriteEffects() == true then
                getCore():setOptionDoWindSpriteEffects(false)
            end
        end
    end

    -- 6. Split lighting chunk updates (Smooths out lightning strike spikes)
    if DebugOptions and DebugOptions.instance and DebugOptions.instance.lightingSplitUpdate then
        local splitOpt = DebugOptions.instance.lightingSplitUpdate
        if splitOpt.setValue then splitOpt:setValue(true) end
    end
end

MPOptim.WeatherOptimizer.ApplyOptimizations = MPOptim.WeatherOptimizer.Update

Events.EveryOneMinute.Add(MPOptim.WeatherOptimizer.Update)
Events.OnGameStart.Add(MPOptim.WeatherOptimizer.Update)
