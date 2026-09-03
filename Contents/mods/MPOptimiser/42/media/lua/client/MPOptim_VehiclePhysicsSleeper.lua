--[[
    Project Zomboid Optimiser (Build 42)
    File: media/lua/client/MPOptim_VehiclePhysicsSleeper.lua
    Author: prop11
    Description: Safe vehicle physics state synchronizer. Ensures all player and modded vehicles (KI5, Filibuster, etc.) remain fully responsive with active physics.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.VehicleSleeper = MPOptim.VehicleSleeper or {}

local function forEachVehicle(cell, callback)
    if not cell or not cell.getVehicles then return end
    local vehicles = cell:getVehicles()
    if not vehicles then return end

    if vehicles.iterator then
        local it = vehicles:iterator()
        while it and it.hasNext and it:hasNext() do
            local veh = it:next()
            if veh then callback(veh) end
        end
        return
    end

    if vehicles.size and vehicles.get then
        local sz = vehicles:size()
        if type(sz) == "number" and sz > 0 then
            for i = 0, sz - 1 do
                local veh = vehicles:get(i)
                if veh then callback(veh) end
            end
        end
        return
    end
end

-- Ensure vehicles are always awake and responsive
function MPOptim.VehicleSleeper.WakeAll()
    local cell = getCell and getCell()
    if not cell then return end
    forEachVehicle(cell, function(veh)
        if veh and veh.isPhysicsActive and not veh:isPhysicsActive() and veh.setPhysicsActive then
            veh:setPhysicsActive(true)
        end
        if veh and veh.setNeedPartsUpdate then
            veh:setNeedPartsUpdate(true)
        end
    end)
end

function MPOptim.VehicleSleeper.Update()
    -- Maintain active physics and part synchronization on all nearby vehicles
    MPOptim.VehicleSleeper.WakeAll()
end

Events.OnGameStart.Add(function()
    MPOptim.VehicleSleeper.WakeAll()
end)

Events.OnEnterVehicle.Add(function(character)
    MPOptim.VehicleSleeper.WakeAll()
end)

Events.OnExitVehicle.Add(function(character)
    MPOptim.VehicleSleeper.WakeAll()
end)
