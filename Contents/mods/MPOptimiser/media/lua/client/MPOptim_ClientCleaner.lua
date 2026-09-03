--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_ClientCleaner.lua
    Author: prop11
    Description: Silent automated local zone cleaning scheduler with zero stutter.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.ClientCleaner = MPOptim.ClientCleaner or {}

local hoursPassedBlood = 0
local hoursPassedDebris = 0

function MPOptim.ClientCleaner.CleanAroundPlayer(radius, options, onComplete)
    local player = getPlayer and getPlayer()
    if not player then return end

    local px = math.floor(player:getX())
    local py = math.floor(player:getY())
    local pz = math.floor(player:getZ())
    local rad = radius or (MPOptim.Config and MPOptim.Config.Get("Blood_CleanRadius")) or 30

    local area = {
        minX = px - rad,
        maxX = px + rad,
        minY = py - rad,
        maxY = py + rad,
        z = pz
    }

    local cleanOpts = options or {
        cleanBlood = MPOptim.Config and MPOptim.Config.Get("Blood_AutoClean"),
        cleanCorpses = MPOptim.Config and MPOptim.Config.Get("Corpse_AutoClean"),
        cleanDebris = MPOptim.Config and MPOptim.Config.Get("Debris_AutoClean"),
        removeWallBlood = MPOptim.Config and MPOptim.Config.Get("Blood_RemoveWall"),
        cleanEmptyOnly = MPOptim.Config and MPOptim.Config.Get("Corpse_CleanEmptyOnly"),
        cleanJunkOnly = MPOptim.Config and MPOptim.Config.Get("Corpse_CleanJunkOnly"),
        cleanAshAndSkeletons = MPOptim.Config and MPOptim.Config.Get("Corpse_CleanAshAndSkeletons"),
        minAgeHours = MPOptim.Config and MPOptim.Config.Get("Corpse_MinAgeHours"),
        isManual = false
    }

    if MPOptim.StaggerQueue and MPOptim.StaggerQueue.AddAreaJob then
        MPOptim.StaggerQueue.AddAreaJob(area, cleanOpts, nil, function(results, durationMs, isManual)
            if onComplete then
                onComplete(results, durationMs, isManual)
            end
        end)
    end
end

-- Quick clean initiated manually by player in menu
function MPOptim.ClientCleaner.QuickClean(cleanType, radius)
    local rad = radius or (MPOptim.Config and MPOptim.Config.Get("Blood_CleanRadius")) or 30
    local opts = {
        cleanBlood = (cleanType == "all" or cleanType == "blood"),
        cleanCorpses = (cleanType == "all" or cleanType == "corpse"),
        cleanDebris = (cleanType == "all" or cleanType == "debris"),
        removeWallBlood = (MPOptim.Config and MPOptim.Config.Get("Blood_RemoveWall")) or false,
        cleanEmptyOnly = (MPOptim.Config and MPOptim.Config.Get("Corpse_CleanEmptyOnly")),
        cleanJunkOnly = (MPOptim.Config and MPOptim.Config.Get("Corpse_CleanJunkOnly")),
        cleanAshAndSkeletons = (MPOptim.Config and MPOptim.Config.Get("Corpse_CleanAshAndSkeletons")),
        minAgeHours = 0, -- Manual clean always purges immediately
        isManual = true
    }

    MPOptim.ClientCleaner.CleanAroundPlayer(rad, opts, function(results, durationMs, isManual)
        local player = getPlayer and getPlayer()
        if player and isManual then
            local text = string.format("Optimized: %d blood, %d corpses, %d debris cleaned",
                results.bloodCleaned or 0, results.corpsesCleaned or 0, results.debrisCleaned or 0)

            -- Force notification popup on manual button clicks
            if MPOptim.Utils and MPOptim.Utils.Notify then
                MPOptim.Utils.Notify(player, text, true)
            end
        end
    end)
end

local hoursPassedBlood = 0
local hoursPassedDebris = 0
local hoursPassedCorpse = 0

-- Background hourly cleanup routine
Events.EveryHours.Add(function()
    hoursPassedBlood = hoursPassedBlood + 1
    hoursPassedDebris = hoursPassedDebris + 1
    hoursPassedCorpse = hoursPassedCorpse + 1

    local bloodInterval = (MPOptim.Config and MPOptim.Config.Get("Blood_IntervalHours")) or 4
    local debrisInterval = (MPOptim.Config and MPOptim.Config.Get("Debris_IntervalHours")) or 12
    local corpseInterval = (MPOptim.Config and MPOptim.Config.Get("Corpse_IntervalHours")) or 6

    local shouldCleanBlood = MPOptim.Config and MPOptim.Config.Get("Blood_AutoClean") and (hoursPassedBlood >= bloodInterval)
    local shouldCleanDebris = MPOptim.Config and MPOptim.Config.Get("Debris_AutoClean") and (hoursPassedDebris >= debrisInterval)
    local shouldCleanCorpses = MPOptim.Config and MPOptim.Config.Get("Corpse_AutoClean") and (hoursPassedCorpse >= corpseInterval)

    if shouldCleanBlood or shouldCleanDebris or shouldCleanCorpses then
        local rad = 30
        if MPOptim.Config then
            rad = math.max(MPOptim.Config.Get("Blood_CleanRadius") or 30,
                  math.max(MPOptim.Config.Get("Debris_CleanRadius") or 35,
                           MPOptim.Config.Get("Corpse_CleanRadius") or 30))
        end

        MPOptim.ClientCleaner.CleanAroundPlayer(rad, {
            cleanBlood = shouldCleanBlood,
            cleanCorpses = shouldCleanCorpses,
            cleanDebris = shouldCleanDebris,
            removeWallBlood = (MPOptim.Config and MPOptim.Config.Get("Blood_RemoveWall")) or false,
            cleanEmptyOnly = (MPOptim.Config and MPOptim.Config.Get("Corpse_CleanEmptyOnly")),
            cleanJunkOnly = (MPOptim.Config and MPOptim.Config.Get("Corpse_CleanJunkOnly")),
            cleanAshAndSkeletons = (MPOptim.Config and MPOptim.Config.Get("Corpse_CleanAshAndSkeletons")),
            minAgeHours = (MPOptim.Config and MPOptim.Config.Get("Corpse_MinAgeHours")) or 6,
            isManual = false
        }, function(results, durationMs, isManual)
            local player = getPlayer and getPlayer()
            if player and MPOptim.Config and MPOptim.Config.Get("UI_ShowNotifications") then
                local bCount = results.bloodCleaned or 0
                local cCount = results.corpsesCleaned or 0
                local dCount = results.debrisCleaned or 0
                if (bCount > 0 or cCount > 0 or dCount > 0) then
                    local text = string.format("Auto-Clean: %d blood, %d corpses, %d debris swept", bCount, cCount, dCount)
                    if MPOptim.Utils and MPOptim.Utils.Notify then
                        MPOptim.Utils.Notify(player, text, false)
                    end
                end
            end
        end)

        if shouldCleanBlood then hoursPassedBlood = 0 end
        if shouldCleanDebris then hoursPassedDebris = 0 end
        if shouldCleanCorpses then hoursPassedCorpse = 0 end
    end
end)
