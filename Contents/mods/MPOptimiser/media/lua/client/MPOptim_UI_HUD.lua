--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_UI_HUD.lua
    Author: prop11
    Description: Zero-overhead, statically-batched real-time diagnostics HUD overlay with live Preset/Custom indicator and JVM telemetry.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"
require "ISUI/ISPanel"

MPOptim = MPOptim or {}
MPOptim.HUD = MPOptim.HUD or {}

MPOptim_HUD = ISPanel:derive("MPOptim_HUD")

local hudInstance = nil
local frameHistory = {}
local maxFrameHistory = 40

function MPOptim_HUD:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.05, g = 0.07, b = 0.11, a = 0.88 }
    o.borderColor = { r = 0.22, g = 0.38, b = 0.60, a = 0.95 }
    o.anchorLeft = true
    o.anchorRight = false
    o.anchorTop = true
    o.anchorBottom = false
    o.moveWithMouse = true
    return o
end

function MPOptim_HUD:initialise()
    ISPanel.initialise(self)
end

function MPOptim_HUD:onMouseUp(x, y)
    ISPanel.onMouseUp(self, x, y)
    if MPOptim.Config then
        MPOptim.Config.Set("UI_HUD_PosX", math.floor(self.x))
        MPOptim.Config.Set("UI_HUD_PosY", math.floor(self.y))
        MPOptim.Config.Save()
    end
end

local lastHudUpdate = 0
local cachedPresetStr = "Profile: Balanced"
local cachedPresetR, cachedPresetG, cachedPresetB = 0.35, 0.85, 1.0
local cachedFPSStr = "FPS: 60"
local cachedRAMStr = "Lua RAM: 0.0 MB"
local cachedJvmStr = "JVM Heap: Inactive"
local cachedStatusStr = "Status: Active (F10)"
local cachedFPSR, cachedFPSG, cachedFPSB = 0.35, 0.95, 0.45

function MPOptim_HUD:updateDiagnostics()
    local now = (getTimeInMillis and getTimeInMillis()) or 0
    if now - lastHudUpdate < 500 then return end
    lastHudUpdate = now

    local presetName = "Custom"
    if MPOptim and MPOptim.Config and MPOptim.Config.GetActivePresetName then
        presetName = MPOptim.Config.GetActivePresetName()
    end
    cachedPresetStr = "Profile: " .. tostring(presetName)

    if presetName == "Balanced" then
        cachedPresetR, cachedPresetG, cachedPresetB = 0.35, 0.85, 1.0
    elseif presetName == "Potato" then
        cachedPresetR, cachedPresetG, cachedPresetB = 0.95, 0.75, 0.25
    elseif presetName == "Experimental" then
        cachedPresetR, cachedPresetG, cachedPresetB = 0.95, 0.50, 0.15
    elseif presetName == "Server" then
        cachedPresetR, cachedPresetG, cachedPresetB = 0.45, 0.90, 0.50
    elseif presetName == "All Optimisations Disabled" or presetName == "Test Mode" then
        cachedPresetR, cachedPresetG, cachedPresetB = 0.95, 0.40, 0.30
    else
        cachedPresetR, cachedPresetG, cachedPresetB = 0.80, 0.55, 1.0
    end

    local fps = 60
    if MPOptim and MPOptim.Utils and MPOptim.Utils.getFPS then
        fps = MPOptim.Utils.getFPS()
    end
    cachedFPSStr = "FPS: " .. tostring(fps)

    table.insert(frameHistory, fps)
    if #frameHistory > maxFrameHistory then
        table.remove(frameHistory, 1)
    end

    if fps < 30 then
        cachedFPSR, cachedFPSG, cachedFPSB = 0.95, 0.25, 0.25
    elseif fps < 55 then
        cachedFPSR, cachedFPSG, cachedFPSB = 0.95, 0.85, 0.25
    else
        cachedFPSR, cachedFPSG, cachedFPSB = 0.35, 0.95, 0.45
    end

    local ramStr = (MPOptim and MPOptim.Utils and MPOptim.Utils.formatMemoryMB and MPOptim.Utils.formatMemoryMB()) or "N/A"
    cachedRAMStr = "Lua RAM: " .. tostring(ramStr)

    local isJvm = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
    if isJvm then
        local ramGb = (MPOptim.Utils and MPOptim.Utils.GetOptimizedRAM and MPOptim.Utils.GetOptimizedRAM()) or 8
        local channel = (PZOEngine and PZOEngine.getChannel and PZOEngine.getChannel()) or (PZOEngineBridge and PZOEngineBridge.getChannel and PZOEngineBridge.getChannel()) or "Stable"
        if string.find(string.lower(tostring(channel)), "unstable") or string.find(string.lower(tostring(channel)), "beta") then
            cachedJvmStr = "JVM: " .. tostring(ramGb) .. "GB [Unstable: Culling Active]"
        else
            cachedJvmStr = "JVM: " .. tostring(ramGb) .. "GB G1GC Active"
        end
    else
        cachedJvmStr = "Mode: Standard Lua (100% OK)"
    end
end

function MPOptim_HUD:render()
    if not self:isVisible() then return end
    ISPanel.render(self)

    self:updateDiagnostics()

    local font = (UIFont and UIFont.Small) or 0
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local padX = math.floor(10 * scale)
    local padY = math.floor(8 * scale)
    local lineH = math.max(16, math.floor(fontH + 4 * scale))

    self:drawText(cachedPresetStr, padX, padY + (0 * lineH), cachedPresetR, cachedPresetG, cachedPresetB, 1.0, font)
    self:drawText(cachedFPSStr, padX, padY + (1 * lineH), cachedFPSR, cachedFPSG, cachedFPSB, 1.0, font)
    self:drawText(cachedRAMStr, padX, padY + (2 * lineH), 0.90, 0.90, 0.90, 1.0, font)
    self:drawText(cachedJvmStr, padX, padY + (3 * lineH), 0.35, 0.85, 1.0, 1.0, font)

    -- Mini Frametime Graph
    local graphX = padX
    local graphY = padY + (4 * lineH) + math.floor(4 * scale)
    local graphW = self.width - (padX * 2)
    local graphH = math.floor(22 * scale)

    self:drawRect(graphX, graphY, graphW, graphH, 0.60, 0.02, 0.04, 0.08)
    self:drawRectBorder(graphX, graphY, graphW, graphH, 0.80, 0.18, 0.30, 0.45)

    if #frameHistory > 1 then
        local barW = math.max(1, math.floor(graphW / maxFrameHistory))
        for i, val in ipairs(frameHistory) do
            local clamped = math.max(10, math.min(120, val))
            local barH = math.floor((clamped / 120.0) * (graphH - 2))
            local bx = graphX + ((i - 1) * barW)
            local by = graphY + graphH - 1 - barH
            local r, g, b = 0.30, 0.90, 0.45
            if val < 30 then r, g, b = 0.95, 0.25, 0.25
            elseif val < 55 then r, g, b = 0.95, 0.80, 0.25 end
            self:drawRect(bx, by, barW, barH, 0.90, r, g, b)
        end
    end
end

function MPOptim.SetHUDVisible(visible)
    if not hudInstance then
        local scale, fontH = MPOptim.Utils.GetUIScale()
        local w = math.max(180, math.floor(210 * scale))
        local h = math.max(100, math.floor(125 * scale))
        local x = (MPOptim.Config and MPOptim.Config.Get("UI_HUD_PosX")) or 25
        local y = (MPOptim.Config and MPOptim.Config.Get("UI_HUD_PosY")) or 25
        hudInstance = MPOptim_HUD:new(x, y, w, h)
        hudInstance:initialise()
        hudInstance:addToUIManager()
    end
    hudInstance:setVisible(visible == true)
end

function MPOptim.ToggleHUD()
    local cur = (MPOptim.Config and MPOptim.Config.Get("UI_ShowHUD")) or false
    local nextVal = not cur
    if MPOptim.Config then
        MPOptim.Config.Set("UI_ShowHUD", nextVal)
        MPOptim.Config.Save()
    end
    MPOptim.SetHUDVisible(nextVal)
end

local function onGameStartHUD()
    local isShow = (MPOptim.Config and MPOptim.Config.Get("UI_ShowHUD")) or false
    if isShow then
        MPOptim.SetHUDVisible(true)
    end
end

Events.OnGameStart.Add(onGameStartHUD)
