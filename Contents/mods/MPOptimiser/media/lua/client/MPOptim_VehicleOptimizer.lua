--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_VehicleOptimizer.lua
    Author: prop11
    Description: Anti-stutter vehicle streamer, camera auto-zoom limiter & restoration, and chunk I/O bandwidth prioritizer.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.VehicleOptimizer = MPOptim.VehicleOptimizer or {}

local wasInVehicle = false
local isDrivingFast = false
local savedLightingFPS = nil
local lightingWasThrottled = false
local savedAutoZoom = nil
local autoZoomWasDisabled = false
local fastStreak = 0
local slowStreak = 0

local function restoreVehicleState(player)
    fastStreak = 0
    slowStreak = 0

    if lightingWasThrottled and PerformanceSettings then
        if savedLightingFPS and PerformanceSettings.setLightingFPS then
            PerformanceSettings.setLightingFPS(savedLightingFPS)
        end
        lightingWasThrottled = false
        savedLightingFPS = nil
    end

    if autoZoomWasDisabled and getCore then
        local core = getCore()
        local playerNum = (player and player.getPlayerNum and player:getPlayerNum()) or 0
        if core and core.setAutoZoom and savedAutoZoom ~= nil then
            core:setAutoZoom(playerNum, savedAutoZoom)
        end
        autoZoomWasDisabled = false
        savedAutoZoom = nil
    end
end

function MPOptim.VehicleOptimizer.Update()
    local player = getPlayer and getPlayer()

    if not MPOptim.Config or not MPOptim.Config.Get("Vehicle_ChunkPriorityMode") then
        if isDrivingFast or wasInVehicle then
            isDrivingFast = false
            wasInVehicle = false
            restoreVehicleState(player)
            if MPOptim.StaggerQueue then MPOptim.StaggerQueue.isSuspended = false end
        end
        return
    end

    if not player then return end

    local vehicle = player.getVehicle and player:getVehicle()
    if vehicle then
        -- 1. Initial Vehicle Entry: Camera Zoom Protection
        if not wasInVehicle then
            wasInVehicle = true

            -- Opt-in gentle incremental GC step (Non-blocking: prevents entry hitches)
            if MPOptim.Config.Get("Vehicle_PreDrivePurge") == true then
                collectgarbage("step", 250)
            end

            -- Prevent extreme 200% camera auto-zoom from quadrupling visible draw calls
            if MPOptim.Config.Get("Vehicle_LimitDriveZoom") ~= false and getCore then
                local core = getCore()
                local playerNum = (player.getPlayerNum and player:getPlayerNum()) or 0
                if core and core.getAutoZoom and core.setAutoZoom then
                    if savedAutoZoom == nil then
                        savedAutoZoom = core:getAutoZoom(playerNum)
                    end
                    if savedAutoZoom == true then
                        core:setAutoZoom(playerNum, false)
                        autoZoomWasDisabled = true
                    end
                end
            end
        end

        local speed = math.abs((vehicle.getCurrentSpeedKmHour and vehicle:getCurrentSpeedKmHour()) or 0)
        local speedThreshold = (MPOptim.Config and MPOptim.Config.Get("Vehicle_SpeedThreshold")) or 35
        local stopThreshold = math.max(10, speedThreshold - 15) -- Generous hysteresis buffer prevents rapid toggling

        -- Dynamic Chunk Streaming & Driving Mode (> threshold km/h with 3-step debounce)
        if speed > speedThreshold then
            fastStreak = fastStreak + 1
            slowStreak = 0

            if fastStreak >= 3 and not isDrivingFast then
                isDrivingFast = true

                -- 1. Scale Dynamic Lighting Rate While Driving (Preserves high-refresh smoothness)
                if MPOptim.Config.Get("Vehicle_ScaleLightingFPS") ~= false and PerformanceSettings then
                    local curLightFPS = (PerformanceSettings.getLightingFPS and PerformanceSettings.getLightingFPS()) or PerformanceSettings.lightingFps or 60
                    local targetDrivingFPS = math.max(30, math.floor(curLightFPS * 0.5))
                    if curLightFPS and curLightFPS > targetDrivingFPS then
                        savedLightingFPS = curLightFPS
                        if PerformanceSettings.setLightingFPS then
                            PerformanceSettings.setLightingFPS(targetDrivingFPS)
                        end
                        lightingWasThrottled = true
                    end
                end

                -- Ground-Level Puddle Optimization while driving (perfPuddles = 2: Skips 31 vertical levels AND 8-neighbor lookups)
                if getCore and getCore().getPerfPuddles and getCore().setPerfPuddles then
                    local curPerf = getCore():getPerfPuddles()
                    if curPerf < 2 then
                        getCore():setPerfPuddles(2)
                    end
                end

                -- 2. Suspend background sweep queues so 100% CPU/disk I/O goes to road chunk streaming
                if MPOptim.Config.Get("Vehicle_SuspendBackgroundCleanups") ~= false then
                    if MPOptim.StaggerQueue then
                        MPOptim.StaggerQueue.isSuspended = true
                    end
                end

                -- 3. Multi-Threaded 3D Model Slot Initialization (Build 42)
                if MPOptim.Config.Get("Vehicle_ThreadedModelSlots") ~= false and DebugOptions and DebugOptions.instance then
                    local optModelInit = DebugOptions.instance.threadModelSlotInit
                    if optModelInit and optModelInit.setValue then optModelInit:setValue(true) end
                end

                -- 4. Roadside Zombie Mesh Skinning Throttle (Opt-in / Experimental)
                if MPOptim.Config.Get("Vehicle_ThrottleRoadsideZombies") == true and PerformanceSettings then
                    local activePreset = MPOptim.Config.GetActivePresetName and MPOptim.Config.GetActivePresetName()
                    if activePreset == "Experimental" then
                        PerformanceSettings.numberZombiesBlended = 6
                        PerformanceSettings.zombieAnimationSpeedFalloffCount = 3
                    end
                end

                -- 5. Force 2D Billboard Imposters on Road Chunks (Opt-in / Experimental)
                if MPOptim.Config.Get("Vehicle_BoostImposterDistance") == true and DebugOptions and DebugOptions.instance then
                    local activePreset = MPOptim.Config.GetActivePresetName and MPOptim.Config.GetActivePresetName()
                    if activePreset == "Experimental" then
                        local optImposter = DebugOptions.instance.zombieImposterRendering
                        if optImposter and optImposter.setValue then optImposter:setValue(true) end
                        local optInstanced = DebugOptions.instance.zombieRenderInstanced
                        if optInstanced and optInstanced.setValue then optInstanced:setValue(true) end
                    end
                end
            end
        elseif speed <= stopThreshold then
            slowStreak = slowStreak + 1
            fastStreak = 0

            if slowStreak >= 3 and isDrivingFast then
                isDrivingFast = false

                if lightingWasThrottled and PerformanceSettings then
                    if savedLightingFPS and PerformanceSettings.setLightingFPS then
                        PerformanceSettings.setLightingFPS(savedLightingFPS)
                    end
                    lightingWasThrottled = false
                    savedLightingFPS = nil
                end

                if MPOptim.StaggerQueue then
                    MPOptim.StaggerQueue.isSuspended = false
                end
            end
        else
            -- Inside hysteresis band (between stopThreshold and speedThreshold):
            -- Maintain current driving state without changing streaks
            fastStreak = 0
            slowStreak = 0
        end
    else
        if wasInVehicle or isDrivingFast then
            wasInVehicle = false
            isDrivingFast = false
            restoreVehicleState(player)
            if MPOptim.StaggerQueue then
                MPOptim.StaggerQueue.isSuspended = false
            end
        end
    end
end

local vehicleTickCounter = 0
Events.OnTick.Add(function()
    vehicleTickCounter = vehicleTickCounter + 1
    if vehicleTickCounter % 15 == 0 then
        MPOptim.VehicleOptimizer.Update()
    end
end)
