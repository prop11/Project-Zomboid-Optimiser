--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_BuildingOptimizer.lua
    Author: prop11
    Description: High-performance, zero-stutter Multi-Story Building Occlusion Culling with state-delta caching.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.BuildingOptimizer = MPOptim.BuildingOptimizer or {}

local lastSqX = -9999
local lastSqY = -9999
local lastSqZ = -9999
local appliedMinZ = -1
local appliedMaxZ = -1
local wasCulled = false
local windowGraceTimer = 0

-- Fast native state applier that ONLY touches engine properties on actual delta change
local function applyZRange(cell, minZ, maxZ)
    if appliedMinZ == minZ and appliedMaxZ == maxZ then return end
    
    appliedMinZ = minZ
    appliedMaxZ = maxZ

    if cell.setMinZ then cell:setMinZ(minZ) end
    if cell.setMaxZ then cell:setMaxZ(maxZ) end

    if cell.chunkMap then
        local player = getPlayer and getPlayer()
        local pIdx = (player and player.getPlayerNum and player:getPlayerNum()) or 0
        local cm = cell.chunkMap[pIdx]
        if cm then
            if cm.minHeight ~= nil then cm.minHeight = minZ end
            if cm.maxHeight ~= nil then cm.maxHeight = maxZ end
        end
    end
end

function MPOptim.BuildingOptimizer.Update()
    if not MPOptim.Config or not MPOptim.Config.Get("GFX_BuildingInteriorCull") then
        if wasCulled then
            MPOptim.BuildingOptimizer.Restore()
        end
        return
    end

    local player = getPlayer and getPlayer()
    if not player then return end

    -- Vehicles are always exterior and travel at high speeds: skip building interior scan
    if player.getVehicle and player:getVehicle() then
        if wasCulled then
            MPOptim.BuildingOptimizer.Restore()
        end
        return
    end

    local currentSquare = player.getCurrentSquare and player:getCurrentSquare()
    if not currentSquare then return end

    local px = currentSquare:getX()
    local py = currentSquare:getY()
    local pZ = math.floor(player:getZ() or 0)

    local isOutside = (currentSquare.isOutside and currentSquare:isOutside()) == true
    local room = player.getCurrentRoom and player:getCurrentRoom()
    local building = currentSquare.getBuilding and currentSquare:getBuilding()

    -- 1. If player is outdoors or in an unroofed space, restore baseline rendering smoothly
    if isOutside or (room == nil and building == nil) then
        if wasCulled then
            MPOptim.BuildingOptimizer.Restore()
        end
        lastSqX, lastSqY, lastSqZ = px, py, pZ
        return
    end

    -- 2. Skip perimeter rescanning if player hasn't moved squares
    if px == lastSqX and py == lastSqY and pZ == lastSqZ and wasCulled then
        return
    end
    lastSqX, lastSqY, lastSqZ = px, py, pZ

    local cell = getCell and getCell()
    if not cell or not cell.getGridSquare then return end

    local nearWindowOrBalcony = false
    local nearStairs = false

    -- Fast 5x5 spatial scan using native boolean flags only (0 string allocations)
    for dx = -2, 2 do
        for dy = -2, 2 do
            local sq = cell:getGridSquare(px + dx, py + dy, pZ)
            if sq then
                if sq:isOutside() then
                    nearWindowOrBalcony = true
                elseif (sq.hasWindowOrWindowFrame and sq:hasWindowOrWindowFrame()) or (sq.hasWindow and sq:hasWindow()) then
                    nearWindowOrBalcony = true
                elseif (sq.HasStairs and sq:HasStairs()) or (sq.HasStairsBelow and sq:HasStairsBelow()) then
                    nearStairs = true
                end
            end
            if nearWindowOrBalcony and nearStairs then break end
        end
        if nearWindowOrBalcony and nearStairs then break end
    end

    local now = (getTimeInMillis and getTimeInMillis()) or 0

    if nearWindowOrBalcony then
        windowGraceTimer = now + 2000 -- 2.0s smooth hysteresis buffer
        if wasCulled then
            MPOptim.BuildingOptimizer.Restore()
        end
        return
    end

    -- If grace timer is active, wait until player is settled deep inside
    if now < windowGraceTimer then
        return
    end

    -- 3. Upper Floors (Z >= 2) Occlusion Clamping
    if pZ >= 2 then
        local targetMinZ = nearStairs and math.max(0, pZ - 2) or math.max(0, pZ - 1)
        local targetMaxZ = nearStairs and math.min(32, pZ + 2) or math.min(32, pZ + 1)

        applyZRange(cell, targetMinZ, targetMaxZ)
        wasCulled = true
        return
    end

    -- For ground and 1st floor (Z <= 1), keep standard baseline to avoid roof flicker
    if wasCulled then
        MPOptim.BuildingOptimizer.Restore()
    end
end

function MPOptim.BuildingOptimizer.Restore()
    local cell = getCell and getCell()
    if cell then
        applyZRange(cell, 0, 32)
    end
    wasCulled = false
    appliedMinZ = -1
    appliedMaxZ = -1
end

Events.OnPlayerMove.Add(MPOptim.BuildingOptimizer.Update)
Events.OnGameStart.Add(function()
    appliedMinZ = -1
    appliedMaxZ = -1
    wasCulled = false
    MPOptim.BuildingOptimizer.Restore()
end)
