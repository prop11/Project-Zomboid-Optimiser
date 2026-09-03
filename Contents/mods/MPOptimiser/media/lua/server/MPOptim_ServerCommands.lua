--[[
    Multiplayer Performance Optimizer (Build 42)
    File: media/lua/server/MPOptim_ServerCommands.lua
    Author: prop11
    Description: Server command processors and maintenance triggers.
--]]

if not isServer() then return end

MPOptim = MPOptim or {}
MPOptim.ServerCommands = MPOptim.ServerCommands or {}

-- Force trigger a manual server sweep from console or RCON
function MPOptim.ServerCommands.ForceSweep()
    if MPOptim.ServerManager and MPOptim.ServerManager.RunScheduledSweep then
        MPOptim.ServerManager.RunScheduledSweep()
    end
end
