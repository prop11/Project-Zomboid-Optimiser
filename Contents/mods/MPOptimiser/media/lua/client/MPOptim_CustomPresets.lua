--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_CustomPresets.lua
    Author: prop11
    Description: Custom User Presets save, load, delete, and sharing engine.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.CustomPresets = MPOptim.CustomPresets or {}
MPOptim.CustomPresets.Data = MPOptim.CustomPresets.Data or {}

local PRESETS_FILENAME = "MPOptim_CustomPresets.ini"

function MPOptim.CustomPresets.LoadAll()
    MPOptim.CustomPresets.Data = {}

    -- Seed built-in sample presets if needed
    MPOptim.CustomPresets.Data["Solo Balanced (No Cleanups)"] = {
        Blood_CapPerTile = true,
        Blood_AutoClean = false,
        Corpse_AutoClean = false,
        Corpse_CullShadows = true,
        Debris_AutoClean = false,
        GFX_BuildingInteriorCull = true,
        Vehicle_PhysicsSleep = false,
        GFX_DynamicZoomLOD = true,
        Animal_ThrottleDistant = true,
        GFX_ForestCanopyCull = true,
        Lighting_FPS = 30,
        Vehicle_ChunkPriorityMode = true,
        Vehicle_LimitDriveZoom = true,
        Vehicle_ScaleLightingFPS = true,
        Vehicle_SuspendBackgroundCleanups = true,
        GFX_EnforceTextureCompression = true,
        GFX_WallShader = true,
        GFX_ModelLighting = true,
        Weather_PuddleOptimization = true,
        Weather_DisableTreeWind = false
    }

    if not getFileReader then return end
    local reader = getFileReader(PRESETS_FILENAME, false)
    if not reader then return end

    local curSection = nil
    local line = reader:readLine()
    while line do
        local trimmed = string.match(line, "^%s*(.-)%s*$") or ""
        if trimmed ~= "" and string.sub(trimmed, 1, 1) ~= "#" and string.sub(trimmed, 1, 1) ~= ";" then
            local sectionName = string.match(trimmed, "^%[Preset:(.+)%]$")
            if sectionName then
                curSection = string.match(sectionName, "^%s*(.-)%s*$")
                MPOptim.CustomPresets.Data[curSection] = MPOptim.CustomPresets.Data[curSection] or {}
            elseif curSection then
                local k, v = string.match(trimmed, "^([^=]+)=(.*)$")
                if k and v then
                    local key = string.match(k, "^%s*(.-)%s*$")
                    local rawVal = string.match(v, "^%s*(.-)%s*$")
                    if rawVal == "true" then
                        MPOptim.CustomPresets.Data[curSection][key] = true
                    elseif rawVal == "false" then
                        MPOptim.CustomPresets.Data[curSection][key] = false
                    else
                        local num = tonumber(rawVal)
                        if num then
                            MPOptim.CustomPresets.Data[curSection][key] = num
                        else
                            MPOptim.CustomPresets.Data[curSection][key] = rawVal
                        end
                    end
                end
            end
        end
        line = reader:readLine()
    end
    reader:close()
end

function MPOptim.CustomPresets.SaveAll()
    if not getFileWriter then return false end
    local writer = getFileWriter(PRESETS_FILENAME, true, false)
    if not writer then return false end

    writer:writeln("# Project Zomboid Optimiser - Custom User Presets")
    for name, configTbl in pairs(MPOptim.CustomPresets.Data) do
        writer:writeln("")
        writer:writeln("[Preset:" .. tostring(name) .. "]")
        for k, v in pairs(configTbl) do
            writer:writeln(tostring(k) .. "=" .. tostring(v))
        end
    end
    writer:close()
    return true
end

function MPOptim.CustomPresets.GetList()
    local names = {}
    for name, _ in pairs(MPOptim.CustomPresets.Data) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

function MPOptim.CustomPresets.SavePreset(name, configTbl)
    if not name or string.trim(name) == "" then return false end
    local cleanName = string.trim(name)
    MPOptim.CustomPresets.Data[cleanName] = {}

    local source = configTbl or MPOptim.Config.Current
    for k, v in pairs(source) do
        MPOptim.CustomPresets.Data[cleanName][k] = v
    end

    MPOptim.CustomPresets.SaveAll()
    return true
end

function MPOptim.CustomPresets.LoadPreset(name)
    local data = MPOptim.CustomPresets.Data[name]
    if not data then return false end

    for k, v in pairs(data) do
        MPOptim.Config.Set(k, v)
    end
    MPOptim.Config.Save()

    local inWorld = (getPlayer and getPlayer()) ~= nil

    if inWorld then
        if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then
            MPOptim.HordeOptimizer.Apply()
        end
        if MPOptim.BuildingOptimizer and MPOptim.BuildingOptimizer.Update then
            MPOptim.BuildingOptimizer.Update()
        end
        if MPOptim.ZoomLOD and MPOptim.ZoomLOD.Update then
            MPOptim.ZoomLOD.Update()
        end
        if MPOptim.VehicleSleeper and MPOptim.VehicleSleeper.Update then
            MPOptim.VehicleSleeper.Update()
        end
    end

    return true
end

function MPOptim.CustomPresets.DeletePreset(name)
    if MPOptim.CustomPresets.Data[name] then
        MPOptim.CustomPresets.Data[name] = nil
        MPOptim.CustomPresets.SaveAll()
        return true
    end
    return false
end

Events.OnGameBoot.Add(function()
    MPOptim.CustomPresets.LoadAll()
end)

Events.OnMainMenuEnter.Add(function()
    MPOptim.CustomPresets.LoadAll()
end)
