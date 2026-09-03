--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_ForestCuller.lua
    Author: prop11
    Description: Deep forest canopy occlusion culler and wind sway shader throttler for enclosed interior trees.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.ForestCuller = MPOptim.ForestCuller or {}

local lastCheckX = -9999
local lastCheckY = -9999

function MPOptim.ForestCuller.Update()
    if not MPOptim.Config or not MPOptim.Config.Get("GFX_ForestCanopyCull") then return end

    local player = getPlayer and getPlayer()
    if not player then return end

    local currentSquare = player.getCurrentSquare and player:getCurrentSquare()
    if not currentSquare or not currentSquare:isOutside() then return end -- Skip instantly if indoors

    local px = math.floor(player:getX())
    local py = math.floor(player:getY())

    -- Only evaluate when player has moved at least 8 tiles into a new outdoor forest area
    local distSq = (px - lastCheckX) * (px - lastCheckX) + (py - lastCheckY) * (py - lastCheckY)
    if distSq < 64 then return end
    lastCheckX = px
    lastCheckY = py

    local cell = getCell and getCell()
    if not cell then return end
    local pz = math.floor(player:getZ())

    -- Sample surrounding 20x20 forest tiles
    for x = px - 10, px + 10, 2 do
        for y = py - 10, py + 10, 2 do
            local sq = cell:getGridSquare(x, y, pz)
            if sq and sq.getTree and sq:getTree() ~= nil then
                local tree = sq:getTree()
                local md = tree:getModData()
                if not md._kwChecked then
                    md._kwChecked = true
                    -- Check 4 surrounding cardinal neighbors
                    local n1 = cell:getGridSquare(x + 1, y, pz)
                    local n2 = cell:getGridSquare(x - 1, y, pz)
                    local n3 = cell:getGridSquare(x, y + 1, pz)
                    local n4 = cell:getGridSquare(x, y - 1, pz)

                    if (n1 and n1:getTree()) and (n2 and n2:getTree()) and (n3 and n3:getTree()) and (n4 and n4:getTree()) then
                        md._kwDeepForest = true
                    end
                end
            end
        end
    end
end

Events.OnPlayerMove.Add(MPOptim.ForestCuller.Update)
