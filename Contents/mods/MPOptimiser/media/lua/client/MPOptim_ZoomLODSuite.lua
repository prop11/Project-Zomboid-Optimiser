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
-- The preset or user value in force before zooming out; restored instead of a fixed number
local savedBlended = nil

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
            if PerformanceSettings and PerformanceSettings.numberZombiesBlended ~= nil then
                savedBlended = PerformanceSettings.numberZombiesBlended
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
    if savedBlended and PerformanceSettings and PerformanceSettings.numberZombiesBlended ~= nil then
        PerformanceSettings.numberZombiesBlended = savedBlended
    end
    savedBlended = nil
end

Events.OnGameStart.Add(function()
    MPOptim.ZoomLOD.Restore()
end)
