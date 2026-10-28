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

-- =========================================================================
-- COMMAND PROCESSOR & RUNTIME TOGGLES (Benchmarking & Tuning)
-- =========================================================================
function MPOptim.ModGovernor.ProcessCommand(cmdText)
    if not cmdText or type(cmdText) ~= "string" then
        return false, "No command provided"
    end
    local lower = string.lower(string.match(cmdText, "^%s*(.-)%s*$") or "")
    local parts = {}
    for word in string.gmatch(lower, "%S+") do
        table.insert(parts, word)
    end
    if #parts == 0 then
        local pState = MPOptim.Config.Get("Mod_PacedEventRate") and "ON" or "OFF"
        local lState = MPOptim.Config.Get("Mod_ZombieScriptLOD") and "ON" or "OFF"
        return true, string.format("Governor Status: Pacing=%s | ZombieLOD=%s | FrameCount=%d", pState, lState, MPOptim.ModGovernor.FrameCount or 0)
    end

    local action = parts[1]
    local val = parts[2]

    if action == "pace" or action == "pacing" or action == "mod_paced" then
        local enable = true
        if val == "0" or val == "off" or val == "false" or val == "disable" then
            enable = false
        elseif val == "toggle" or val == nil then
            enable = not MPOptim.Config.Get("Mod_PacedEventRate")
        end
        MPOptim.Config.Set("Mod_PacedEventRate", enable)
        MPOptim.Config.Save()
        return true, "Mod Event Pacing (60Hz clamp & frame spread): " .. (enable and "ENABLED" or "DISABLED")

    elseif action == "lod" or action == "zombie_lod" or action == "zombies" then
        local enable = true
        if val == "0" or val == "off" or val == "false" or val == "disable" then
            enable = false
        elseif val == "toggle" or val == nil then
            enable = not MPOptim.Config.Get("Mod_ZombieScriptLOD")
        end
        MPOptim.Config.Set("Mod_ZombieScriptLOD", enable)
        MPOptim.Config.Save()
        return true, "Zombie Script LOD (near-player focus): " .. (enable and "ENABLED" or "DISABLED")

    elseif action == "benchmark" or action == "bench" then
        if val == "baseline" or val == "vanilla" or val == "off" then
            MPOptim.Config.Set("Mod_PacedEventRate", false)
            MPOptim.Config.Set("Mod_ZombieScriptLOD", false)
            MPOptim.Config.Save()
            return true, "BENCHMARK BASELINE ACTIVE: Mod Pacing & Zombie LOD DISABLED"
        elseif val == "optimized" or val == "pzo" or val == "on" then
            MPOptim.Config.Set("Mod_PacedEventRate", true)
            MPOptim.Config.Set("Mod_ZombieScriptLOD", true)
            MPOptim.Config.Save()
            return true, "BENCHMARK OPTIMIZED ACTIVE: Mod Pacing & Zombie LOD ENABLED"
        else
            return true, "Usage: /pzo benchmark baseline | /pzo benchmark optimized"
        end

    elseif action == "status" then
        local pacing = MPOptim.Config.Get("Mod_PacedEventRate") and "ON (60Hz Clamp)" or "OFF (Unrestricted)"
        local lod = MPOptim.Config.Get("Mod_ZombieScriptLOD") and "ON (Near Focus & Stagger)" or "OFF (Every Frame)"
        return true, string.format("PZO Governor: Pacing=%s | ZombieLOD=%s | FrameCount=%d", pacing, lod, MPOptim.ModGovernor.FrameCount or 0)
    end

    return false, "Unknown PZO command: " .. tostring(action) .. ". Usage: /pzo pace on|off, /pzo lod on|off, /pzo benchmark baseline|optimized, /pzo status"
end

-- Global console shortcuts
function pzo_toggle_pacing(opt)
    local state = (opt == nil and not MPOptim.Config.Get("Mod_PacedEventRate")) or (opt == true or opt == 1 or opt == "on")
    MPOptim.Config.Set("Mod_PacedEventRate", state)
    MPOptim.Config.Save()
    print("[PZO] Mod Event Pacing set to: " .. tostring(state))
    return state
end

function pzo_toggle_lod(opt)
    local state = (opt == nil and not MPOptim.Config.Get("Mod_ZombieScriptLOD")) or (opt == true or opt == 1 or opt == "on")
    MPOptim.Config.Set("Mod_ZombieScriptLOD", state)
    MPOptim.Config.Save()
    print("[PZO] Zombie Script LOD set to: " .. tostring(state))
    return state
end

function pzo_status()
    local pacing = MPOptim.Config.Get("Mod_PacedEventRate") and "ON" or "OFF"
    local lod = MPOptim.Config.Get("Mod_ZombieScriptLOD") and "ON" or "OFF"
    local msg = string.format("[PZO Status] Mod Pacing=%s | Zombie LOD=%s | FrameCount=%d", pacing, lod, MPOptim.ModGovernor.FrameCount or 0)
    print(msg)
    return msg
end

-- Register in-game chat command (/pzo ...)
local function hookGovernorChat()
    if not ISChat or not ISChat.onCommandEntered or ISChat._pzoGovernorHooked then return end
    ISChat._pzoGovernorHooked = true
    local origOnCommandEntered = ISChat.onCommandEntered

    ISChat.onCommandEntered = function(self, ...)
        local chat = ISChat.instance
        if chat and chat.textEntry then
            local text = chat.textEntry:getText() or ""
            local trimmed = string.match(text, "^%s*(.-)%s*$") or ""
            local lower = string.lower(trimmed)
            if string.sub(lower, 1, 5) == "/pzo " or lower == "/pzo" then
                local cmdBody = string.sub(trimmed, 6)
                local handled, reply = MPOptim.ModGovernor.ProcessCommand(cmdBody)
                if handled then
                    chat.textEntry:setText("")
                    if chat.unfocus then chat:unfocus() end
                    local pObj = getPlayer and getPlayer()
                    if pObj and MPOptim.Utils and MPOptim.Utils.Notify then
                        MPOptim.Utils.Notify(pObj, "[PZO] " .. (reply or "Command processed"), true)
                    end
                    if print then
                        print("[PZO Command] " .. (reply or "Command processed"))
                    end
                    return
                end
            end
        end
        return origOnCommandEntered(self, ...)
    end
end

if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(hookGovernorChat)
end
