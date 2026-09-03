--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_AnimalOptimizer.lua
    Author: prop11
    Description: Build 42 livestock pens audio emitter culler and distant animal simulation throttler.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.AnimalOptimizer = MPOptim.AnimalOptimizer or {}

function MPOptim.AnimalOptimizer.Update()
    if not MPOptim.Config then return end
    if MPOptim.Config.Get("Animal_Optimize") == false then return end
    if not MPOptim.Config.Get("Animal_ThrottleDistant") then return end

    local cell = getCell and getCell()
    if not cell then return end

    -- Build 42 Animal list evaluation
    local animalList = cell.getAnimalList and cell:getAnimalList()
    if not animalList or animalList:size() == 0 then return end

    local player = getPlayer and getPlayer()
    local px = player and player:getX() or 0
    local py = player and player:getY() or 0
    local maxEmitters = MPOptim.Config.Get("Animal_MaxAudioEmitters") or 4
    local activeEmitters = 0

    for i = 0, animalList:size() - 1 do
        local animal = animalList:get(i)
        if animal then
            local ax, ay = animal:getX(), animal:getY()
            local distSq = (ax - px) * (ax - px) + (ay - py) * (ay - py)

            -- If animal is distant (> 35 tiles), throttle voice emitters
            if distSq > 1225 then
                local emitter = animal.getEmitter and animal:getEmitter()
                if emitter and emitter.stopAll then
                    if activeEmitters >= maxEmitters then
                        emitter:stopAll()
                    end
                end
            else
                activeEmitters = activeEmitters + 1
            end
        end
    end
end
