--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_ZoomLODSuite.lua
    Author: prop11
    Description: Real-time dynamic Zoom LOD controller and sub-pixel render optimizer.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.ZoomLOD = MPOptim.ZoomLOD or {}

local lastZoomState = "NORMAL"

function MPOptim.ZoomLOD.Update()
    if not MPOptim.Config or not MPOptim.Config.Get("GFX_DynamicZoomLOD") then
        if lastZoomState ~= "NORMAL" then
            MPOptim.ZoomLOD.Restore()
        end
        return
    end

    local core = getCore and getCore()
    if not core or not core.getZoom then return end

    local player = getPlayer and getPlayer()
    local pIdx = (player and player.getPlayerNum and player:getPlayerNum()) or 0
    local curZoom = core:getZoom(pIdx) or 1.0

    if curZoom >= 1.50 then
        if lastZoomState ~= "HIGH_ZOOM" then
            lastZoomState = "HIGH_ZOOM"
            -- At high zoom-out, throttle distant skeletal blend passes to save thousands of sub-pixel draw calls
            if PerformanceSettings and PerformanceSettings.numberZombiesBlended ~= nil then
                PerformanceSettings.numberZombiesBlended = 4
            end
        end
    else
        if lastZoomState ~= "NORMAL" then
            MPOptim.ZoomLOD.Restore()
        end
    end
end

function MPOptim.ZoomLOD.Restore()
    lastZoomState = "NORMAL"
    if PerformanceSettings and PerformanceSettings.numberZombiesBlended ~= nil then
        PerformanceSettings.numberZombiesBlended = 10
    end
end

Events.OnGameStart.Add(function()
    MPOptim.ZoomLOD.Restore()
end)
