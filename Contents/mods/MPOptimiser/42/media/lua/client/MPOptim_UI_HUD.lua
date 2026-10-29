--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_UI_HUD.lua
    Author: prop11
    Description: Small performance overlay: active preset, FPS, Lua memory, engine mode and a frame graph.
                 Values refresh twice a second; dragging it saves its position.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"
require "MPOptim_UIStyle"
require "ISUI/ISPanel"

MPOptim = MPOptim or {}
MPOptim.HUD = MPOptim.HUD or {}
local U = MPOptim.UI
local C, T = U.C, U.T

MPOptim_HUD = ISPanel:derive("MPOptim_HUD")

local hudInstance = nil
local frameHistory = {}
local maxFrameHistory = 40
local lastUpdate = 0
local rows = {}

function MPOptim_HUD:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.moveWithMouse = true
    return o
end

function MPOptim_HUD:onMouseUp(x, y)
    ISPanel.onMouseUp(self, x, y)
    if MPOptim.Config then
        MPOptim.Config.Set("UI_HUD_PosX", math.floor(self.x))
        MPOptim.Config.Set("UI_HUD_PosY", math.floor(self.y))
        MPOptim.Config.Save()
    end
end

local function fpsColor(fps)
    if fps < 30 then return C.bad end
    if fps < 55 then return C.warn end
    return C.good
end

local PRESET_NAMES = {
    Balanced = { "UI_MPOptim_Preset_Balanced", "Balanced" },
    Potato = { "UI_MPOptim_Preset_Aggressive", "Max Performance" },
    Experimental = { "UI_MPOptim_V2_PresetExperimental", "Experimental" },
    Server = { "UI_MPOptim_Preset_Server", "Dedicated Server" },
}

local function updateRows()
    local now = getTimestampMs and getTimestampMs() or 0
    if now - lastUpdate < 500 and #rows > 0 then return end
    lastUpdate = now

    local preset = (MPOptim.Config and MPOptim.Config.GetActivePresetName and MPOptim.Config.GetActivePresetName()) or "Custom"
    local pn = PRESET_NAMES[preset]
    local presetStr = pn and T(pn[1], pn[2]) or tostring(preset)

    local fps = (MPOptim.Utils.getFPS and MPOptim.Utils.getFPS()) or 0
    frameHistory[#frameHistory + 1] = fps
    if #frameHistory > maxFrameHistory then table.remove(frameHistory, 1) end

    local isJvm = MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
    local engine
    if isJvm then
        local ramGb = (MPOptim.Utils.GetOptimizedRAM and MPOptim.Utils.GetOptimizedRAM()) or 8
        engine = string.format(T("UI_MPOptim_V2_HudJava", "Java, %s GB"), tostring(ramGb))
    else
        engine = T("UI_MPOptim_V2_EngineLuaShort", "Lua only")
    end

    rows = {
        { T("UI_MPOptim_V2_StatPreset", "Preset"), presetStr, C.accent },
        { T("UI_MPOptim_V2_StatFPS", "Frame rate"), tostring(fps), fpsColor(fps) },
        { T("UI_MPOptim_V2_StatLuaRAM", "Lua memory"), tostring((MPOptim.Utils.formatMemoryMB and MPOptim.Utils.formatMemoryMB()) or "?"), C.text },
        { T("UI_MPOptim_V2_StatEngine", "Engine"), engine, isJvm and C.good or C.dim },
    }
end

function MPOptim_HUD:prerender()
    U.rect(self, 0, 0, self.width, self.height, C.bg, 0.88)
end

function MPOptim_HUD:render()
    updateRows()
    local m = U.metrics()
    local pad = math.floor(8 * m.scale)
    local lineH = m.fh + math.floor(3 * m.scale)

    U.rect(self, 0, 0, 3, self.height, C.accent)
    for i, r in ipairs(rows) do
        local y = pad + (i - 1) * lineH
        U.text(self, r[1], pad + 3, y, C.dim, m.fS)
        local v = U.trim(m.fS, r[2], self.width * 0.55)
        self:drawTextRight(v, self.width - pad, y, r[3][1], r[3][2], r[3][3], 1, m.fS)
    end

    local gx = pad + 3
    local gy = pad + #rows * lineH + math.floor(3 * m.scale)
    local gw = self.width - gx - pad
    local gh = self.height - gy - pad
    U.rect(self, gx, gy, gw, gh, C.well, 0.9)
    -- 60 FPS guide line
    local guideY = gy + gh - 1 - math.floor((60 / 120) * (gh - 2))
    U.rect(self, gx, guideY, gw, 1, C.line, 0.8)
    if #frameHistory > 1 then
        local barW = math.max(1, math.floor(gw / maxFrameHistory))
        for i, val in ipairs(frameHistory) do
            local clamped = math.max(5, math.min(120, val))
            local barH = math.floor((clamped / 120) * (gh - 2))
            local c = fpsColor(val)
            self:drawRect(gx + (i - 1) * barW, gy + gh - 1 - barH, math.max(1, barW - 1), barH, 0.85, c[1], c[2], c[3])
        end
    end
    U.border(self, 0, 0, self.width, self.height, C.line)
end

function MPOptim.SetHUDVisible(visible)
    if not hudInstance then
        local m = U.metrics()
        local w = math.max(190, math.floor(220 * m.scale))
        local h = math.floor(8 * m.scale) * 2 + 4 * (m.fh + math.floor(3 * m.scale)) + math.floor(30 * m.scale)
        local x = (MPOptim.Config and MPOptim.Config.Get("UI_HUD_PosX")) or 25
        local y = (MPOptim.Config and MPOptim.Config.Get("UI_HUD_PosY")) or 25
        hudInstance = MPOptim_HUD:new(x, y, w, h)
        hudInstance:initialise()
        hudInstance:addToUIManager()
    end
    hudInstance:setVisible(visible == true)
end

function MPOptim.ToggleHUD()
    local nextVal = not ((MPOptim.Config and MPOptim.Config.Get("UI_ShowHUD")) or false)
    if MPOptim.Config then
        MPOptim.Config.Set("UI_ShowHUD", nextVal)
        MPOptim.Config.Save()
    end
    MPOptim.SetHUDVisible(nextVal)
end

Events.OnGameStart.Add(function()
    if MPOptim.Config and MPOptim.Config.Get("UI_ShowHUD") then
        MPOptim.SetHUDVisible(true)
    end
end)
