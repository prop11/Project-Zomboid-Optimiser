--[[
    Multiplayer Performance Optimizer (Build 42)
    File: media/lua/server/MPOptim_ServerManager.lua
    Author: prop11
    Description: Dedicated server automated maintenance engine and sector task scheduler. Automatically applies Server preset.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

if not isServer or not isServer() then return end

MPOptim = MPOptim or {}
MPOptim.ServerManager = MPOptim.ServerManager or {}

local serverHoursCount = 0

-- Automatically apply the official Server Preset if no custom INI exists
local function initServerProfile()
    if MPOptim.Config and MPOptim.Presets and MPOptim.Presets.Server then
        if not MPOptim.Config.Current or next(MPOptim.Config.Current) == nil then
            MPOptim.Config.ApplyPreset("Server")
            print("[MPOptimizer] Server Profile automatically activated for Dedicated Server.")
        end
    end
end

initServerProfile()
Events.OnServerStarted = Events.OnServerStarted or Events.OnGameStart
if Events.OnServerStarted then Events.OnServerStarted.Add(initServerProfile) end

function MPOptim.ServerManager.RunScheduledSweep()
    local players = getOnlinePlayers and getOnlinePlayers()
    if not players or players:size() == 0 then return end

    print("[MPOptimizer] Initiating Server-Wide Scheduled Performance Sweep...")

    local options = {
        cleanBlood = MPOptim.Config and MPOptim.Config.Get("Blood_AutoClean"),
        cleanCorpses = MPOptim.Config and MPOptim.Config.Get("Corpse_AutoClean"),
        cleanDebris = MPOptim.Config and MPOptim.Config.Get("Debris_AutoClean"),
        removeWallBlood = (MPOptim.Config and MPOptim.Config.Get("Blood_RemoveWall")) or false,
        cleanEmptyOnly = (MPOptim.Config and MPOptim.Config.Get("Corpse_CleanEmptyOnly")) or true
    }

    local rad = 40
    if MPOptim.Config then
        rad = math.max(MPOptim.Config.Get("Blood_CleanRadius") or 35, MPOptim.Config.Get("Debris_CleanRadius") or 45)
    end

    for i = 0, players:size() - 1 do
        local p = players:get(i)
        if p then
            local px = math.floor(p:getX())
            local py = math.floor(p:getY())
            local area = {
                minX = px - rad,
                maxX = px + rad,
                minY = py - rad,
                maxY = py + rad,
                minZ = 0,
                maxZ = 7
            }

            if MPOptim.StaggerQueue and MPOptim.StaggerQueue.AddAreaJob then
                MPOptim.StaggerQueue.AddAreaJob(area, options, nil, function(results, durationMs)
                    if MPOptim.Config and MPOptim.Config.Get("Admin_BroadcastCleanup") then
                        local msg = string.format("[Server Maintenance] Cleaned %d blood, %d corpses, %d debris in player zone (%d ms)",
                            results.bloodCleaned or 0, results.corpsesCleaned or 0, results.debrisCleaned or 0, durationMs)
                        print(msg)
                    end
                end)
            end
        end
    end
end

Events.EveryHours.Add(function()
    serverHoursCount = serverHoursCount + 1
    local interval = (MPOptim.Config and MPOptim.Config.Get("Blood_IntervalHours")) or 4

    if serverHoursCount >= interval then
        serverHoursCount = 0
        MPOptim.ServerManager.RunScheduledSweep()
    end
end)

print("[MPOptimizer] Server Manager Initialized successfully.")
