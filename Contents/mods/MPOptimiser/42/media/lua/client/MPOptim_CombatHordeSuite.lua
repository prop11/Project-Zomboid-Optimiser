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
    if not MPOptim.Config or not MPOptim.Config.Get("Combat_BurstSmoother") then return end
    if not target or not target.isZombie or not target:isZombie() then return end

    if target:isDead() or (damage and damage > 2.0) then
        table.insert(deathBurstQueue, {
            target = target,
            x = target:getX(),
            y = target:getY(),
            z = target:getZ(),
            tick = (getTimeInMillis and getTimeInMillis()) or 0
        })
    end
end

function MPOptim.CombatHordeSuite.ProcessBurstQueue()
    if #deathBurstQueue == 0 then return end

    local count = math.min(#deathBurstQueue, maxBurstsPerFrame)
    for i = 1, count do
        local entry = table.remove(deathBurstQueue, 1)
        if entry and entry.target and entry.target.getSquare then
            local sq = entry.target:getSquare()
            if sq and sq.splatBlood then
                sq:splatBlood(1, 0.4)
            end
        end
    end
end

function MPOptim.CombatHordeSuite.Update()
    if #deathBurstQueue > 0 then
        MPOptim.CombatHordeSuite.ProcessBurstQueue()
    end
end

Events.OnWeaponHitCharacter.Add(MPOptim.CombatHordeSuite.OnWeaponHit)
Events.OnZombieDead.Add(function(zombie)
    if not MPOptim.Config or not MPOptim.Config.Get("Combat_BurstSmoother") then return end
    if zombie then
        table.insert(deathBurstQueue, {
            target = zombie,
            x = zombie:getX(),
            y = zombie:getY(),
            z = zombie:getZ(),
            tick = (getTimeInMillis and getTimeInMillis()) or 0
        })
    end
end)
