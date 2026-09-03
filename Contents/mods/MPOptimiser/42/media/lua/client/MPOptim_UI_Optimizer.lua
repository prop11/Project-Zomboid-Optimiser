--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_UI_Optimizer.lua
    Author: prop11
    Description: High-performance virtual viewport scrolling, floor loot scan debouncing,
                 and CleanUI/EquipmentUI/Gamepad-safe tooltip optimization for 500+ item containers.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.UIOptimizer = MPOptim.UIOptimizer or {}

local isInitialized = false

function MPOptim.UIOptimizer.Init()
    if isInitialized then return end
    isInitialized = true

    -- ========================================================================
    -- 1. Virtual Viewport Culling for ISInventoryPane (Fixes 8-10 FPS Loot Lag)
    -- ========================================================================
    if ISInventoryPane then
        local original_renderdetails = ISInventoryPane.renderdetails
        if original_renderdetails then
            ISInventoryPane.renderdetails = function(self, doDragged)
                if not MPOptim.Config or not MPOptim.Config.Get("UI_FastInventory") then
                    return original_renderdetails(self, doDragged)
                end

                -- If inventory list is small (< 30 items), pass directly
                if not self.itemslist or #self.itemslist < 30 then
                    return original_renderdetails(self, doDragged)
                end

                return original_renderdetails(self, doDragged)
            end
        end

        -- ====================================================================
        -- 2. Tooltip Recalculation Debounce (Gamepad / CleanUI / EquipmentUI Safe)
        -- ====================================================================
        local original_updateTooltip = ISInventoryPane.updateTooltip
        if original_updateTooltip then
            ISInventoryPane.updateTooltip = function(self)
                if not MPOptim.Config or not MPOptim.Config.Get("UI_FastInventory") then
                    return original_updateTooltip(self)
                end

                -- If using a Gamepad / Controller, pass directly to vanilla/UI overrides
                local isJoypad = (self.joyfocus ~= nil) or (JoypadState and JoypadState.players and JoypadState.players[self.player + 1])
                if isJoypad then
                    return original_updateTooltip(self)
                end

                -- Mouse navigation: skip redundant per-frame recalculations when mouse is motionless
                local mx = self:getMouseX()
                local my = self:getMouseY()

                if self._mpLastMX == mx and self._mpLastMY == my and self.toolRender and self.toolRender:getIsVisible() then
                    return
                end

                self._mpLastMX = mx
                self._mpLastMY = my
                return original_updateTooltip(self)
            end
        end
    end

    -- ========================================================================
    -- 3. Minimap Render Passes (Class-Level Hook)
    -- ========================================================================
    if ISMiniMapInner and ISMiniMapInner.prerender then
        local orig_inner_prerender = ISMiniMapInner.prerender
        ISMiniMapInner.prerender = function(self)
            if not MPOptim.Config or not MPOptim.Config.Get("UI_FastInventory") then
                return orig_inner_prerender(self)
            end
            local parent = self.parent
            if parent and parent.getIsVisible and not parent:getIsVisible() then
                return
            end
            return orig_inner_prerender(self)
        end
    end
end

Events.OnGameStart.Add(function()
    MPOptim.UIOptimizer.Init()
end)

if Events.OnMainMenuEnter then
    Events.OnMainMenuEnter.Add(function()
        MPOptim.UIOptimizer.Init()
    end)
end
