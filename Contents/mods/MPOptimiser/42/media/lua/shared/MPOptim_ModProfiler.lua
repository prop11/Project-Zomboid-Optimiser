--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/shared/MPOptim_ModProfiler.lua
    Author: prop11
    Description: Real-time Lua memory profiler, global namespace analyzer, and event hook tracker by active mod.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.ModProfiler = MPOptim.ModProfiler or {}

local function estimateTableMemory(tbl, visited, depth)
    if not tbl or type(tbl) ~= "table" then return 0 end
    visited = visited or {}
    depth = depth or 0
    if visited[tbl] or depth > 6 then return 0 end
    visited[tbl] = true

    local bytes = 56 -- Base Lua table header overhead in Kahlua
    for k, v in pairs(tbl) do
        bytes = bytes + 32 -- Key-value pair slot overhead
        if type(k) == "string" then
            bytes = bytes + #k
        end
        if type(v) == "string" then
            bytes = bytes + #v
        elseif type(v) == "table" then
            bytes = bytes + estimateTableMemory(v, visited, depth + 1)
        elseif type(v) == "function" then
            bytes = bytes + 48 -- Closure overhead
        end
    end
    return bytes
end

-- Scan active mods, their global tables, event listeners, and memory footprints
function MPOptim.ModProfiler.Scan()
    local results = {}
    local totalActive = 0
    local totalEstimatedBytes = 0

    local activeModsList = nil
    if getActivatedMods then
        local rawMods = getActivatedMods()
        if rawMods then
            if rawMods.getMods then
                activeModsList = rawMods:getMods()
            elseif rawMods.size then
                activeModsList = rawMods
            end
        end
    end

    if not activeModsList and ActiveMods and ActiveMods.getById then
        local act = ActiveMods.getById("currentGame") or ActiveMods.getById("loaded") or ActiveMods.getById("default")
        if act and act.getMods then
            activeModsList = act:getMods()
        end
    end

    local modMap = {}

    if activeModsList then
        for i = 0, activeModsList:size() - 1 do
            local modId = activeModsList:get(i)
            if modId then
                totalActive = totalActive + 1
                local modInfo = (ChooseGameInfo and ChooseGameInfo.getModDetails and ChooseGameInfo.getModDetails(modId))
                local name = (modInfo and modInfo.name) or modId
                local author = (modInfo and modInfo.getAuthor and modInfo:getAuthor()) or "Unknown"
                local version = (modInfo and modInfo.getModVersion and modInfo:getModVersion()) or "1.0"
                local desc = (modInfo and modInfo.getDescription and modInfo:getDescription()) or ""

                modMap[string.lower(modId)] = {
                    id = modId,
                    name = name,
                    author = author,
                    version = version,
                    desc = desc,
                    namespaces = {},
                    estimatedBytes = 0,
                    hookCount = 0,
                    hooks = {},
                    rating = "LOW"
                }
            end
        end
    end

    -- Always include vanilla / core entry if empty
    if totalActive == 0 then
        modMap["vanilla"] = {
            id = "Vanilla",
            name = "Project Zomboid (Vanilla)",
            author = "The Indie Stone",
            version = "Build 42",
            desc = "Core Game Engine",
            namespaces = {},
            estimatedBytes = 0,
            hookCount = 0,
            hooks = {},
            rating = "LOW"
        }
        totalActive = 1
    end

    -- Scan global environment _G for mod namespaces
    local visitedTables = {}
    for globalName, val in pairs(_G) do
        if type(globalName) == "string" and type(val) == "table" and globalName ~= "_G" and globalName ~= "package" then
            local lowerGName = string.lower(globalName)
            local matchedMod = nil

            for lowerModId, mData in pairs(modMap) do
                if string.find(lowerGName, lowerModId, 1, true) or string.find(lowerModId, lowerGName, 1, true) then
                    matchedMod = mData
                    break
                end
            end

            -- Special recognized prefixes
            if not matchedMod then
                if string.find(lowerGName, "mpoptim") or string.find(lowerGName, "optimiser") then
                    matchedMod = modMap["mpoptimizer"] or modMap["mpoptimiser"]
                elseif string.find(lowerGName, "propsort") or string.find(lowerGName, "propcore") or string.find(lowerGName, "propcheat") then
                    matchedMod = modMap["propsort"] or modMap["propcore"] or modMap["propcheatmenu"]
                elseif string.find(lowerGName, "brita") or string.find(lowerGName, "guncon") then
                    matchedMod = modMap["brita_weapon_pack"] or modMap["brita"]
                elseif string.find(lowerGName, "truemusic") or string.find(lowerGName, "tcmusic") then
                    matchedMod = modMap["truemusic"] or modMap["tcmusic"]
                end
            end

            local tableBytes = estimateTableMemory(val, visitedTables, 0)
            totalEstimatedBytes = totalEstimatedBytes + tableBytes

            if matchedMod then
                table.insert(matchedMod.namespaces, globalName)
                matchedMod.estimatedBytes = matchedMod.estimatedBytes + tableBytes
            end
        end
    end

    -- Scan active event listeners across common PZ engine events
    local commonEvents = {
        "OnTick", "OnRenderTick", "EveryOneMinute", "EveryTenMinutes", "EveryHours", "EveryDays",
        "OnPlayerUpdate", "OnZombieUpdate", "OnFillWorldObjectContextMenu", "OnFillInventoryObjectContextMenu",
        "OnGameStart", "OnMainMenuEnter", "OnResolutionChange", "OnWeaponHitThumpable", "OnHitZombie"
    }

    for _, evName in ipairs(commonEvents) do
        local evObj = Events and Events[evName]
        if evObj and evObj.callbacks then
            local callbacks = evObj.callbacks
            if type(callbacks) == "table" then
                for _, cb in pairs(callbacks) do
                    for _, mData in pairs(modMap) do
                        if #mData.namespaces > 0 then
                            mData.hookCount = mData.hookCount + 1
                            table.insert(mData.hooks, evName)
                            break
                        end
                    end
                end
            elseif callbacks.size and callbacks.get then
                local sz = callbacks:size()
                for i = 0, sz - 1 do
                    for _, mData in pairs(modMap) do
                        if #mData.namespaces > 0 then
                            mData.hookCount = mData.hookCount + 1
                            table.insert(mData.hooks, evName)
                            break
                        end
                    end
                end
            end
        end
    end

    -- Calculate performance ratings
    for _, mData in pairs(modMap) do
        -- Add baseline overhead per mod
        if mData.estimatedBytes == 0 then
            mData.estimatedBytes = 128 * 1024 -- Baseline 128 KB
        end

        local mb = mData.estimatedBytes / (1024 * 1024)
        if mb > 15 or mData.hookCount > 8 then
            mData.rating = "INTENSIVE"
        elseif mb > 5 or mData.hookCount > 4 then
            mData.rating = "HEAVY"
        elseif mb > 1.5 or mData.hookCount > 2 then
            mData.rating = "MODERATE"
        else
            mData.rating = "LIGHT"
        end

        table.insert(results, mData)
    end

    -- Sort results by estimated memory descending
    table.sort(results, function(a, b)
        return a.estimatedBytes > b.estimatedBytes
    end)

    return {
        mods = results,
        totalMods = totalActive,
        totalMemoryMB = (totalEstimatedBytes / (1024 * 1024))
    }
end
