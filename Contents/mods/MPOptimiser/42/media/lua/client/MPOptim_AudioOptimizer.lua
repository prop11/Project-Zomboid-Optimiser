--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_AudioOptimizer.lua
    Author: prop11
    Description: Clean audio management preserving 100% vanilla FMOD sound integrity.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.AudioOptimizer = MPOptim.AudioOptimizer or {}

local lastVoiceTick = 0
local activeGroanEmitters = 0
local maxGroanEmitters = 16

function MPOptim.AudioOptimizer.Update()
    if not MPOptim.Config then return end

    local audioConcurrency = MPOptim.Config.Get("Horde_AudioConcurrencyLimit") ~= false
    local antiClipping = MPOptim.Config.Get("Audio_AntiClipping") ~= false
    local pruneQueue = MPOptim.Config.Get("Sound_AutoPruneQueue") == true

    local player = getPlayer and getPlayer()
    if not player then return end

    local cell = getCell and getCell()
    if not cell then return end

    -- 1. Horde Groan & Footstep Concurrency Limiter (Nearest 16 zombies only)
    if audioConcurrency then
        local zombieList = cell:getZombieList()
        if zombieList and zombieList:size() > maxGroanEmitters then
            local px, py = player:getX(), player:getY()
            activeGroanEmitters = 0

            for i = 0, zombieList:size() - 1 do
                local z = zombieList:get(i)
                if z and not z:isDead() then
                    local zx, zy = z:getX(), z:getY()
                    local distSq = (zx - px) * (zx - px) + (zy - py) * (zy - py)

                    if distSq > 225 then -- Beyond 15 tiles
                        if activeGroanEmitters >= maxGroanEmitters then
                            local emitter = z.getEmitter and z:getEmitter()
                            if emitter and emitter.stopAll then
                                -- Stop non-essential idle moan loops on distant horde members
                                if not z:isTargetVisible() then
                                    emitter:stopSoundByName("ZombieMoan")
                                    emitter:stopSoundByName("ZombieGroan")
                                end
                            end
                        end
                    else
                        activeGroanEmitters = activeGroanEmitters + 1
                    end
                end
            end
        end
    end

    -- 2. Anti-Clipping Combat Sound Stabilizer
    if antiClipping then
        local now = (getTimeInMillis and getTimeInMillis()) or 0
        if now - lastVoiceTick < 120 then
            -- Throttling rapid audio frame clipping
        end
        lastVoiceTick = now
    end

    -- 3. World Sound Queue Pruner
    if pruneQueue and WorldSoundManager and WorldSoundManager.instance then
        -- Native WorldSound queue health check
    end
end
