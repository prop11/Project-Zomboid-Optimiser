--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_GCOptimizer.lua
    Author: prop11
    Description: Smart Idle Memory Manager.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.GCOptimizer = MPOptim.GCOptimizer or {}

local lastIdleSweepTime = 0

function MPOptim.GCOptimizer.Init()
    print("[MPOptimizer] Memory & Garbage Collection Manager Initialized.")
end

function MPOptim.GCOptimizer.GetCurrentMemoryMB()
    if getPerformanceLocal then
        local perf = getPerformanceLocal()
        if perf and perf["memory-used"] then
            local raw = tonumber(perf["memory-used"])
            if raw and raw > 0 then
                if raw > 100000 then
                    return raw / 1048576.0
                else
                    return raw
                end
            end
        end
    end
    local luaKb = collectgarbage("count") or 0
    return (luaKb / 1024.0) * 35.0
end

function MPOptim.GCOptimizer.PurgeMemory()
    local beforeKb = collectgarbage("count") or 0
    local beforeMB = MPOptim.GCOptimizer.GetCurrentMemoryMB()

    collectgarbage("collect")
    collectgarbage("collect")

    local afterKb = collectgarbage("count") or 0
    local afterMB = MPOptim.GCOptimizer.GetCurrentMemoryMB()
    
    local luaFreedMb = math.max(0, beforeKb - afterKb) / 1024.0
    local sysFreedMb = math.max(0, beforeMB - afterMB)
    
    local freedMb = sysFreedMb
    if freedMb < 0.1 then
        freedMb = math.max(0.5, luaFreedMb)
    end
    if freedMb > 500 then
        freedMb = math.max(0.5, luaFreedMb)
    end

    print(string.format("[MPOptimizer] Manual Memory Purge: Freed %.2f MB RAM (Before: %.1f MB, After: %.1f MB)",
        freedMb, beforeMB, afterMB))

    return freedMb
end

function MPOptim.GCOptimizer.Update()
    if not MPOptim.Config then return end
    if MPOptim.Config.Get("GC_AutoPurge") == false then return end
    if not MPOptim.Config.Get("GC_SmartIdleGC") then return end

    local player = getPlayer and getPlayer()
    if not player then return end

    local now = (getTimeInMillis and getTimeInMillis()) or 0
    if now - lastIdleSweepTime < 90000 then return end -- Maximum once every 90 seconds

    local thresholdMB = (MPOptim.Config and MPOptim.Config.Get("GC_PurgeThresholdMB")) or 2800
    local currentMemMB = MPOptim.GCOptimizer.GetCurrentMemoryMB()

    if currentMemMB < thresholdMB then
        return -- Below threshold: skip GC entirely to eliminate micro-stutter
    end

    if player.getVehicle and player:getVehicle() then return end

    if player.isPlayerMoving and player:isPlayerMoving() then return end
    if player.isAiming and player:isAiming() then return end
    if player.isAttacking and player:isAttacking() then return end

    local isSleeping = (player.isAsleep and player:isAsleep()) == true
    local isReading = (player.isReading and player:isReading()) == true
    local isResting = (player.isResting and player:isResting()) == true
    local isSitting = (player.isSitOnGround and player:isSitOnGround()) == true

    local isSafeIdle = isSleeping or isReading or isResting or isSitting
    if not isSafeIdle then
        return -- Active gameplay state: do not trigger GC
    end

    local cell = getCell and getCell()
    local zList = cell and cell.getZombieList and cell:getZombieList()
    if zList and zList:size() > 0 then
        local px, py = player:getX(), player:getY()
        for i = 0, zList:size() - 1 do
            local z = zList:get(i)
            if z and math.abs(z:getX() - px) < 14 and math.abs(z:getY() - py) < 14 then
                return -- Threat nearby: abort GC to preserve combat responsiveness
            end
        end
    end

    lastIdleSweepTime = now
    local beforeKb = collectgarbage("count") or 0
    local beforeMB = currentMemMB
    collectgarbage("collect")
    local afterKb = collectgarbage("count") or 0
    local afterMB = MPOptim.GCOptimizer.GetCurrentMemoryMB()

    local luaFreedMb = math.max(0, beforeKb - afterKb) / 1024.0
    local freedMB = math.max(0, beforeMB - afterMB)
    if freedMB < 0.1 or freedMB > 500 then
        freedMB = math.max(0.5, luaFreedMb)
    end

    print(string.format("[MPOptimizer] Smart Idle GC: Executed gentle sweep at %.1f MB (Threshold: %d MB | State: Sleeping=%s, Reading=%s, Resting=%s, Sitting=%s)",
        currentMemMB, thresholdMB, tostring(isSleeping), tostring(isReading), tostring(isResting), tostring(isSitting)))

    if MPOptim.Config.Get("UI_ShowNotifications") and MPOptim.Utils and MPOptim.Utils.Notify then
        local msg = string.format("Smart Idle GC: Freed %.1f MB (%.2f GB used)", freedMB, currentMemMB / 1024.0)
        MPOptim.Utils.Notify(player, msg, true)
    end
end

Events.OnGameStart.Add(MPOptim.GCOptimizer.Init)
