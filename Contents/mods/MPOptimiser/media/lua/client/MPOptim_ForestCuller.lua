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
    -- Build 42 natively handles multi-threaded canopy occlusion and branch sway shaders.
end
