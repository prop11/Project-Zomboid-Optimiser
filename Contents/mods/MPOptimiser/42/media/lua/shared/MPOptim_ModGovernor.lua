--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/shared/MPOptim_ModGovernor.lua
    Author: prop11
    Description: 3rd-Party Mod Event Pacer (60Hz clamp & staggered frame spreading)
                 and Zombie Script LOD (distance-based execution tiers).
--]]

require "MPOptim_Config"

MPOptim = MPOptim or {}
MPOptim.ModGovernor = MPOptim.ModGovernor or {}

MPOptim.ModGovernor.FrameCount = 0
MPOptim.ModGovernor.ModCounter = 0
MPOptim.ModGovernor.FnToWrapper = {}
MPOptim.ModGovernor.WrapperToFn = {}
MPOptim.ModGovernor.InternalFns = {}

function MPOptim.ModGovernor.RegisterInternal(fn)
    if fn and type(fn) == "function" then
        MPOptim.ModGovernor.InternalFns[fn] = true
    end
end

-- Advances global governor frame counter
local function onGovernorTick()
    MPOptim.ModGovernor.FrameCount = (MPOptim.ModGovernor.FrameCount + 1) % 600000
end
MPOptim.ModGovernor.RegisterInternal(onGovernorTick)

function MPOptim.ModGovernor.WrapHook(evName, fn)
    if not fn or type(fn) ~= "function" then return fn end

    if MPOptim.ModGovernor.FnToWrapper[fn] then
        return MPOptim.ModGovernor.FnToWrapper[fn]
    end

    if MPOptim.ModGovernor.InternalFns[fn] then
        return fn
    end

    local wrapped = nil

    if evName == "OnTick" or evName == "OnPlayerUpdate" or evName == "OnTickEvenPaused" then
        local modIdx = MPOptim.ModGovernor.ModCounter
        MPOptim.ModGovernor.ModCounter = modIdx + 1

        local now = (getTimeInMillis and getTimeInMillis()) or 0
        local lastExecTime = now - ((modIdx % 6) * 2.7)

        wrapped = function(...)
            if not MPOptim.Config or MPOptim.Config.Get("Mod_PacedEventRate") ~= false then
                local curTime = (getTimeInMillis and getTimeInMillis()) or 0
                local elapsed = curTime - lastExecTime
                if elapsed < 16.0 then
                    return
                end
                lastExecTime = curTime
            end
            return fn(...)
        end

    elseif evName == "OnZombieUpdate" then
        wrapped = function(zombie, ...)
            if not zombie then return end

            if not MPOptim.Config or MPOptim.Config.Get("Mod_ZombieScriptLOD") ~= false then
                local player = getPlayer and getPlayer()
                if player then
                    local distSq = 0
                    if zombie.DistToSquared then
                        distSq = zombie:DistToSquared(player)
                    else
                        local zx = (zombie.getX and zombie:getX()) or 0
                        local zy = (zombie.getY and zombie:getY()) or 0
                        local px = (player.getX and player:getX()) or 0
                        local py = (player.getY and player:getY()) or 0
                        local dx = zx - px
                        local dy = zy - py
                        distSq = dx * dx + dy * dy
                    end

                    -- Near zombies (< 20 tiles) execute every single frame.
                    -- Far zombies (> 20 tiles) execute once every 6 frames in round-robin batches.
                    if distSq > 400.0 then
                        local zid = (zombie.getID and zombie:getID()) or (zombie.getOnlineID and zombie:getOnlineID()) or 0
                        local fCount = MPOptim.ModGovernor.FrameCount or 0
                        if (zid + fCount) % 6 ~= 0 then
                            return
                        end
                    end
                end
            end

            return fn(zombie, ...)
        end
    else
        return fn
    end

    MPOptim.ModGovernor.FnToWrapper[fn] = wrapped
    MPOptim.ModGovernor.WrapperToFn[wrapped] = fn
    return wrapped
end

function MPOptim.ModGovernor.UnwrapHook(fnOrWrapped)
    if not fnOrWrapped then return nil, nil end
    local wrapped = MPOptim.ModGovernor.FnToWrapper[fnOrWrapped] or fnOrWrapped
    local original = MPOptim.ModGovernor.WrapperToFn[fnOrWrapped] or fnOrWrapped

    MPOptim.ModGovernor.FnToWrapper[original] = nil
    MPOptim.ModGovernor.WrapperToFn[wrapped] = nil
    return wrapped, original
end

-- Initialize frame ticker
if Events and Events.OnTick and Events.OnTick.Add then
    Events.OnTick.Add(onGovernorTick)
end
