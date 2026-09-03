--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_FPSLimiter.lua
    Author: prop11
    Description: Focus loss is natively handled by the PZ engine via Options -> General -> 'Pause On Focus Loss' (focusloss in options.ini).
--]]

require "MPOptim_Config"

MPOptim = MPOptim or {}
MPOptim.FPSLimiter = MPOptim.FPSLimiter or {}

local isThrottled = false
local savedFPS = nil

function MPOptim.FPSLimiter.Update()
    if not MPOptim.Config or not MPOptim.Config.Get("FPS_BackgroundThrottle") then
        if isThrottled and PerformanceSettings and savedFPS then
            if PerformanceSettings.setLockFPS then
                PerformanceSettings.setLockFPS(savedFPS)
            end
            isThrottled = false
            savedFPS = nil
        end
        return
    end

    local isWindowActive = true
    -- Native PZO Engine bridge check (zero overhead, pure native window state, Build 41 & 42 compatible)
    local bridge = (type(PZOEngineBridge) == "table" and PZOEngineBridge) or (type(PZOEngine) == "table" and PZOEngine)
    if bridge and type(bridge.isWindowActive) == "function" then
        local active = bridge.isWindowActive()
        if type(active) == "boolean" then
            isWindowActive = active
        end
    end

    if not isWindowActive then
        if not isThrottled and PerformanceSettings then
            local curFPS = PerformanceSettings.getLockFPS and PerformanceSettings.getLockFPS()
            if curFPS and curFPS > 20 then
                savedFPS = curFPS
                if PerformanceSettings.setLockFPS then
                    PerformanceSettings.setLockFPS(20)
                end
                isThrottled = true
            end
        end
    else
        if isThrottled and PerformanceSettings and savedFPS then
            if PerformanceSettings.setLockFPS then
                PerformanceSettings.setLockFPS(savedFPS)
            end
            isThrottled = false
            savedFPS = nil
        end
    end
end
