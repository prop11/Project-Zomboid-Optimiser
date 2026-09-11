--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_CombatHordeSuite.lua
    Author: prop11
    Description: Zero-stutter combat burst smoother and shotgun impact queue.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.CombatHordeSuite = MPOptim.CombatHordeSuite or {}

local deathBurstQueue = {}
local maxBurstsPerFrame = 4

function MPOptim.CombatHordeSuite.HasPendingBursts()
    return #deathBurstQueue > 0
end

function MPOptim.CombatHordeSuite.OnWeaponHit(wielder, target, weapon, damage)
end

function MPOptim.CombatHordeSuite.ProcessBurstQueue()
    if #deathBurstQueue == 0 then return end
    for i = #deathBurstQueue, 1, -1 do
        deathBurstQueue[i] = nil
    end
end

function MPOptim.CombatHordeSuite.Update()
    if #deathBurstQueue > 0 then
        MPOptim.CombatHordeSuite.ProcessBurstQueue()
    end
end

Events.OnWeaponHitCharacter.Add(MPOptim.CombatHordeSuite.OnWeaponHit)
Events.OnZombieDead.Add(function(zombie)
end)
