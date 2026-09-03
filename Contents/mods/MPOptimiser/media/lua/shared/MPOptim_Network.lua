--[[
    Multiplayer Performance Optimizer (Build 42 & 41)
    File: media/lua/shared/MPOptim_Network.lua
    Author: prop11
    Description: Multiplayer network protocol, command dispatch, and server config disk synchronizer.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.Network = MPOptim.Network or {}
MPOptim.Network.ModuleName = "MPOptimizer"

-- ============================================================================
-- Client-Side Network Senders
-- ============================================================================
if isClient and isClient() then

    function MPOptim.Network.SendAdminCleanRequest(x, y, z, radius, options)
        local args = {
            x = x,
            y = y,
            z = z,
            radius = radius or 40,
            options = options or {
                cleanBlood = true,
                cleanCorpses = true,
                cleanDebris = true,
                removeWallBlood = false,
                cleanEmptyOnly = true
            }
        }
        sendClientCommand(MPOptim.Network.ModuleName, "AdminCleanArea", args)
    end

    function MPOptim.Network.RequestServerStats()
        sendClientCommand(MPOptim.Network.ModuleName, "GetStats", {})
    end

    function MPOptim.Network.SendAdminConfigUpdate(configTable)
        local data = configTable or (MPOptim.Config and MPOptim.Config.Current) or {}
        sendClientCommand(MPOptim.Network.ModuleName, "UpdateConfig", data)
    end

    Events.OnServerCommand.Add(function(module, command, args)
        if module ~= MPOptim.Network.ModuleName then return end

        if command == "CleanComplete" then
            if args and args.message then
                local player = getPlayer and getPlayer()
                if player and MPOptim.Utils and MPOptim.Utils.Notify then
                    MPOptim.Utils.Notify(player, args.message, true)
                end
            end
        elseif command == "ConfigSaved" then
            if args and args.message then
                local player = getPlayer and getPlayer()
                if player and MPOptim.Utils and MPOptim.Utils.Notify then
                    MPOptim.Utils.Notify(player, args.message, true)
                end
            end
        elseif command == "StatsResponse" then
            if MPOptim.OnServerStatsReceived then
                MPOptim.OnServerStatsReceived(args)
            end
        elseif command == "SyncConfig" then
            if args and MPOptim.Config then
                for k, v in pairs(args) do
                    MPOptim.Config.Set(k, v)
                end
            end
        end
    end)
end

-- ============================================================================
-- Server-Side Command Handlers
-- ============================================================================
if isServer and isServer() then

    Events.OnClientCommand.Add(function(module, command, player, args)
        if module ~= MPOptim.Network.ModuleName then return end
        if not player then return end

        local isAdmin = MPOptim.Utils and MPOptim.Utils.IsAdmin and MPOptim.Utils.IsAdmin(player)

        if command == "AdminCleanArea" then
            if not isAdmin then
                print("[MPOptimizer] Unauthorized cleanup request by: " .. tostring(player:getUsername()))
                return
            end

            local cx = args.x or math.floor(player:getX())
            local cy = args.y or math.floor(player:getY())
            local rad = math.min(150, args.radius or 50)

            local area = {
                minX = cx - rad,
                maxX = cx + rad,
                minY = cy - rad,
                maxY = cy + rad,
                minZ = 0,
                maxZ = 7
            }

            print(string.format("[MPOptimizer] Server Admin Cleanup at (%d, %d) Radius: %d requested by %s", cx, cy, rad, player:getUsername()))

            if MPOptim.StaggerQueue and MPOptim.StaggerQueue.AddAreaJob then
                MPOptim.StaggerQueue.AddAreaJob(area, args.options, nil, function(results, durationMs)
                    local msg = string.format("[MPOptimizer] Cleaned: %d blood, %d corpses, %d debris (%d ms)",
                        results.bloodCleaned or 0, results.corpsesCleaned or 0, results.debrisCleaned or 0, durationMs)
                    
                    print(msg)
                    sendServerCommand(player, MPOptim.Network.ModuleName, "CleanComplete", { message = msg, results = results })
                end)
            end

        elseif command == "GetStats" then
            local sq = MPOptim.StaggerQueue and MPOptim.StaggerQueue.stats
            local stats = {
                totalCorpsesCleaned = (sq and sq.corpsesCleaned) or 0,
                totalBloodCleaned = (sq and sq.bloodCleaned) or 0,
                totalDebrisCleaned = (sq and sq.debrisCleaned) or 0,
                totalProcessed = (sq and sq.totalProcessed) or 0,
                activeQueueJobs = (MPOptim.StaggerQueue and #MPOptim.StaggerQueue.jobs) or 0,
                serverMemoryMB = (MPOptim.Utils and MPOptim.Utils.formatMemoryMB and MPOptim.Utils.formatMemoryMB()) or "N/A"
            }
            sendServerCommand(player, MPOptim.Network.ModuleName, "StatsResponse", stats)

        elseif command == "UpdateConfig" then
            if not isAdmin then
                print("[MPOptimizer] Unauthorized UpdateConfig request rejected for player: " .. tostring(player:getUsername()))
                return
            end
            if args and MPOptim.Config then
                for k, v in pairs(args) do
                    MPOptim.Config.Set(k, v)
                end
                MPOptim.Config.Save()
                local msg = MPOptim.GetText("UI_MPOptim_SyncSuccess", "Server Optimiser settings saved to server disk successfully!")
                sendServerCommand(player, MPOptim.Network.ModuleName, "ConfigSaved", { message = msg })
                sendServerCommand(MPOptim.Network.ModuleName, "SyncConfig", MPOptim.Config.Current)
                print("[MPOptimizer] Server config updated and saved to disk by admin: " .. tostring(player:getUsername()))
            end
        end
    end)

end
