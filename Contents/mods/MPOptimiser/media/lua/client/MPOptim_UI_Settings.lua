--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_UI_Settings.lua
    Author: prop11
    Description: Comprehensive, high-DPI responsive in-game Control Center with hover tooltips, live diagnostics, 2-column layout, presets, and Mod Resource Profiler.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"
require "MPOptim_ClientCleaner"
require "MPOptim_GCOptimizer"
require "MPOptim_HordeOptimizer"
require "MPOptim_BuildingOptimizer"
require "MPOptim_VehiclePhysicsSleeper"
require "MPOptim_ZoomLODSuite"
require "MPOptim_AnimalOptimizer"
require "MPOptim_ForestCuller"
require "MPOptim_CustomPresets"
require "MPOptim_ModShield"
require "MPOptim_CombatHordeSuite"
require "ISUI/ISComboBox"
require "ISUI/ISTextBox"
require "MPOptim_ModProfiler"
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISTickBox"
require "ISUI/ISLabel"
require "ISUI/ISToolTip"
require "ISUI/ISScrollingListBox"

local MPOptim_SettingsUI = ISPanel:derive("MPOptim_SettingsUI")
local settingsInstance = nil

function MPOptim_SettingsUI:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self

    o.backgroundColor = { r = 0.05, g = 0.07, b = 0.11, a = 0.98 }
    o.borderColor = { r = 0.18, g = 0.32, b = 0.52, a = 1.0 }
    o.moveWithMouse = true
    o.currentTab = 1
    o.tickboxes = {}
    o.steppers = {}
    o.tickboxMap = {}
    o.stepperMap = {}
    o.selectedModData = nil

    return o
end

function MPOptim_SettingsUI:onMouseDown(x, y)
    if not self:getIsVisible() then return false end
    self.downX = x
    self.downY = y
    self.moving = true
    self:bringToTop()
    return true
end

function MPOptim_SettingsUI:onMouseUp(x, y)
    self.moving = false
    return true
end

function MPOptim_SettingsUI:onMouseUpOutside(x, y)
    self.moving = false
    return true
end

function MPOptim_SettingsUI:onMouseMove(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function MPOptim_SettingsUI:onMouseMoveOutside(dx, dy)
    if self.moving then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        self:bringToTop()
    end
end

function MPOptim_SettingsUI:initialise()
    ISPanel.initialise(self)
    self:createChildren()
end

function MPOptim_SettingsUI:createChildren()
    local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
    local winW = self.width
    local winH = self.height
    local smallFont = (UIFont and UIFont.Small) or 0
    local medFont = (UIFont and UIFont.Medium) or 0

    local titleH = math.max(34, math.floor(fontH + 16 * scale))
    self.titleH = titleH

    -- Close Button [X]
    local closeBtnW = math.max(28, math.floor(28 * scale))
    local closeBtnH = math.max(24, math.floor(fontH + 8 * scale))
    self.closeBtn = ISButton:new(winW - closeBtnW - math.floor(12 * scale), math.floor(6 * scale), closeBtnW, closeBtnH, "X", self, function(s)
        s:setVisible(false)
    end)
    self.closeBtn:initialise()
    self.closeBtn.backgroundColor = { r = 0.60, g = 0.15, b = 0.15, a = 0.95 }
    self.closeBtn.borderColor = { r = 0.85, g = 0.25, b = 0.25, a = 1.0 }
    self.closeBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_CloseBtn", "Close the Optimiser Control Center")
    self:addChild(self.closeBtn)

    -- Preset Profiles Header (Dynamic MP Admin & Dev Mode detection)
    local inWorld = (getPlayer and getPlayer()) ~= nil
    local isMP = isClient and isClient()
    local player = inWorld and getPlayer()
    local isMPAdmin = inWorld and isMP and MPOptim.Utils and MPOptim.Utils.IsAdmin and MPOptim.Utils.IsAdmin(player)
    local isDevMode = (MPOptim.DevMode == true)

    local presetList = {
        { text = "[*] Balanced", key = "Balanced", tip = MPOptim.GetText("UI_MPOptim_Tooltip_Preset_Balanced", "Recommended for modern systems. Stutter-free combat, safe blood cap (4/tile), texture compression, and safehouse protection with zero visual loss.") },
        { text = "[+] Potato", key = "Potato", tip = MPOptim.GetText("UI_MPOptim_Tooltip_Preset_Potato", "Aggressive stutter-free boost for low-end hardware. Caps blood to 1/tile, culls corpse shadows, clamps rain particles, 15 FPS lighting refresh, and automated cleanup sweeps.") },
        { text = "[!] Experimental", key = "Experimental", tip = MPOptim.GetText("UI_MPOptim_Tooltip_Preset_Experimental", "EXPERIMENTAL (Advanced testing): Enables 2D billboard imposters, GPU mesh instancing, and threaded lighting. WARNING: May cause micro-stutters during combat state transitions."), isExp = true }
    }

    -- Dedicated Server preset profile is strictly shown only to Admins in an active Multiplayer session
    if isMPAdmin then
        table.insert(presetList, { text = "[#] Server", key = "Server", tip = MPOptim.GetText("UI_MPOptim_Tooltip_Preset_Server", "Optimized profile for multiplayer dedicated servers. Automates scheduled sweeps, protects safehouses, and purges world clutter.") })
    end

    if isDevMode then
        table.insert(presetList, { text = "[DEV] Test Mode", key = "TestModeVanilla", tip = "DEVELOPER BENCHMARK: Disables 100 percent of mod features to benchmark pure vanilla performance.", isTest = true })
    end

    local numButtons = #presetList + (isDevMode and 1 or 0)
    local presetY = titleH + math.floor(8 * scale)
    local presetH = math.max(26, math.floor(fontH + 8 * scale))
    local presetMargin = math.floor(20 * scale)
    local presetGap = math.floor(6 * scale)
    local presetW = math.floor((winW - (presetMargin * 2) - (presetGap * (numButtons - 1))) / numButtons)

    self.presetButtons = {}
    for idx, p in ipairs(presetList) do
        local px = presetMargin + ((idx - 1) * (presetW + presetGap))
        local btn = ISButton:new(px, presetY, presetW, presetH, p.text, self, function(s)
            if MPOptim.Config and MPOptim.Config.ApplyPreset then
                MPOptim.Config.ApplyPreset(p.key)
                s:refreshAllControls()
                if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then
                    MPOptim.HordeOptimizer.Apply()
                end
                local pObj = getPlayer and getPlayer()
                if pObj and MPOptim.Utils and MPOptim.Utils.Notify then
                    local msg = p.isTest and "TEST MODE ACTIVE: All optimizations disabled (Vanilla Benchmark)" or ("Applied Profile: " .. p.text)
                    MPOptim.Utils.Notify(pObj, msg, not p.isTest)
                end
            end
        end)
        btn:initialise()
        if p.isTest then
            btn.backgroundColor = { r = 0.38, g = 0.12, b = 0.12, a = 0.95 }
            btn.borderColor = { r = 0.95, g = 0.35, b = 0.35, a = 1.0 }
        elseif p.isExp then
            btn.backgroundColor = { r = 0.25, g = 0.14, b = 0.06, a = 0.90 }
            btn.borderColor = { r = 0.85, g = 0.50, b = 0.15, a = 0.90 }
        else
            btn.backgroundColor = { r = 0.10, g = 0.18, b = 0.28, a = 0.90 }
            btn.borderColor = { r = 0.25, g = 0.45, b = 0.70, a = 0.90 }
        end
        btn.tooltip = p.tip
        self:addChild(btn)
        table.insert(self.presetButtons, btn)
    end

    if isDevMode then
        local exitDevPx = presetMargin + ((#presetList) * (presetW + presetGap))
        local exitDevBtn = ISButton:new(exitDevPx, presetY, presetW, presetH, "[X] Exit Dev", self, function(s)
            MPOptim.DevMode = false
            local pObj = getPlayer and getPlayer()
            if pObj and MPOptim.Utils and MPOptim.Utils.Notify then
                MPOptim.Utils.Notify(pObj, "Developer Mode Deactivated.", false)
            end
            s:setVisible(false)
            s:removeFromUIManager()
            MPOptim.OpenSettingsUI(true)
        end)
        exitDevBtn:initialise()
        exitDevBtn.backgroundColor = { r = 0.55, g = 0.15, b = 0.15, a = 0.95 }
        exitDevBtn.borderColor = { r = 0.95, g = 0.30, b = 0.30, a = 1.0 }
        exitDevBtn.tooltip = "Deactivate Developer Mode and restore the standard user interface."
        self:addChild(exitDevBtn)
    end

    -- Navigation Tab Buttons (8 Tabs)
    local tabY = presetY + presetH + math.floor(10 * scale)
    local tabH = math.max(30, math.floor(fontH + 12 * scale))
    local tabMargin = math.floor(20 * scale)
    local tabGap = math.floor(4 * scale)
    local tabW = math.floor((winW - (tabMargin * 2) - (tabGap * 7)) / 8)

    self.tab1Btn = ISButton:new(tabMargin + (0 * (tabW + tabGap)), tabY, tabW, tabH, MPOptim.GetText("UI_MPOptim_TabQuick", "Quick Actions"), self, function(s) s:setTab(1) end)
    self.tab2Btn = ISButton:new(tabMargin + (1 * (tabW + tabGap)), tabY, tabW, tabH, MPOptim.GetText("UI_MPOptim_TabGC", "General"), self, function(s) s:setTab(2) end)
    self.tab3Btn = ISButton:new(tabMargin + (2 * (tabW + tabGap)), tabY, tabW, tabH, MPOptim.GetText("UI_MPOptim_TabVehicles", "Vehicles"), self, function(s) s:setTab(3) end)
    self.tab4Btn = ISButton:new(tabMargin + (3 * (tabW + tabGap)), tabY, tabW, tabH, MPOptim.GetText("UI_MPOptim_TabBlood", "Blood & Corpses"), self, function(s) s:setTab(4) end)
    self.tab5Btn = ISButton:new(tabMargin + (4 * (tabW + tabGap)), tabY, tabW, tabH, MPOptim.GetText("UI_MPOptim_TabDebris", "World Debris"), self, function(s) s:setTab(5) end)
    self.tab6Btn = ISButton:new(tabMargin + (5 * (tabW + tabGap)), tabY, tabW, tabH, MPOptim.GetText("UI_MPOptim_TabAdmin", "Audio & Climate"), self, function(s) s:setTab(6) end)
    self.tab7Btn = ISButton:new(tabMargin + (6 * (tabW + tabGap)), tabY, tabW, tabH, MPOptim.GetText("UI_MPOptim_TabJVM", "[+] JVM Engine"), self, function(s) s:setTab(7) end)
    self.tab8Btn = ISButton:new(tabMargin + (7 * (tabW + tabGap)), tabY, tabW, tabH, MPOptim.GetText("UI_MPOptim_TabProfiler", "Mod Profiler"), self, function(s) s:setTab(8) end)

    local tabButtons = { self.tab1Btn, self.tab2Btn, self.tab3Btn, self.tab4Btn, self.tab5Btn, self.tab6Btn, self.tab7Btn, self.tab8Btn }
    local tabTooltips = {
        MPOptim.GetText("UI_MPOptim_Tooltip_Tab1", "Instant one-click manual cleanup tools and live real-time performance diagnostics."),
        MPOptim.GetText("UI_MPOptim_Tooltip_Tab2", "Interface settings, memory management, multi-threading, shaders, and building occlusion."),
        MPOptim.GetText("UI_MPOptim_Tooltip_TabVehicles", "Anti-stutter vehicle road streaming, parked car physics sleeper, auto-zoom limiter, and roadside entity throttles."),
        MPOptim.GetText("UI_MPOptim_Tooltip_Tab3", "Floor blood decal management, corpse cleanup rules, and corpse 3D shadow culling."),
        MPOptim.GetText("UI_MPOptim_Tooltip_Tab4", "Ground clutter purger for spent bullet casings, empty cans, broken glass, and twigs."),
        MPOptim.GetText("UI_MPOptim_Tooltip_Tab5", "Animal audio emitter limiter, track entity purger, fire smoke scalers, and weather particle controls."),
        MPOptim.GetText("UI_MPOptim_Tooltip_TabJVM", "Optional hardware-level JVM optimizations: zero-stutter background GC, deep RAM chunk caching, async 3D model compiling, and horde hibernation."),
        MPOptim.GetText("UI_MPOptim_Tooltip_Tab6", "Real-time breakdown of Lua memory consumption, active global tables, and event hooks for every loaded mod.")
    }

    for i, btn in ipairs(tabButtons) do
        btn:initialise()
        btn.backgroundColor = { r = 0.10, g = 0.14, b = 0.22, a = 0.85 }
        btn.borderColor = { r = 0.20, g = 0.30, b = 0.45, a = 0.80 }
        btn.tooltip = tabTooltips[i]
        self:addChild(btn)
    end

    -- Sub-Panel Container Dimensions
    local subX = tabMargin
    local subY = tabY + tabH + math.floor(8 * scale)
    local subW = winW - (tabMargin * 2)
    local bottomH = math.max(48, math.floor(fontH + 26 * scale))
    local subH = winH - subY - bottomH - math.floor(8 * scale)

    self.tickSpacing = math.max(28, math.floor(fontH + 12 * scale))
    local tickBoxH = math.max(20, math.floor(fontH + 6 * scale))

    -- Reusable TickBox Creator with Hover Tooltips
    local function addTick(panel, y, text, configKey, onToggle, customX, customW, tooltipText)
        local bx = customX or math.floor(20 * scale)
        local bw = customW or (subW - math.floor(40 * scale))
        local box = ISTickBox:new(bx, y, bw, tickBoxH, "", panel, function(target, index, selected)
            if MPOptim.Config then
                MPOptim.Config.Set(configKey, selected)
                MPOptim.Config.Save()
            end
            if onToggle then onToggle(selected) end
            if self.updateDependencies then self:updateDependencies() end
        end)
        box:initialise()
        box:addOption(text)
        local isChecked = (MPOptim.Config and MPOptim.Config.Get(configKey)) or false
        box:setSelected(1, isChecked)
        if tooltipText then
            box.tooltip = tooltipText
        end
        panel:addChild(box)
        table.insert(self.tickboxes, { box = box, key = configKey })
        self.tickboxMap[configKey] = box
        return box
    end

    -- Reusable Value Tweaker / Stepper Creator with Hover Tooltips
    local function addStepper(panel, y, label, configKey, valuesList, formatFn, tooltipText)
        local stepperH = math.max(26, math.floor(fontH + 8 * scale))
        local btnW = math.max(28, math.floor(28 * scale))
        local dispW = math.floor(150 * scale)
        local rightSideX = subW - math.floor(20 * scale) - (btnW * 2) - dispW - math.floor(10 * scale)

        local labelObj = ISLabel:new(math.floor(20 * scale), y + math.floor(4 * scale), fontH, label, 0.90, 0.90, 0.90, 1.0, smallFont, true)
        labelObj:initialise()
        if tooltipText then
            labelObj.tooltip = tooltipText
        end
        panel:addChild(labelObj)

        local currentVal = MPOptim.Config and MPOptim.Config.Get(configKey)
        local curIdx = 1
        for i, val in ipairs(valuesList) do
            if val == currentVal then curIdx = i break end
        end

        local dispBox = ISPanel:new(rightSideX + btnW + math.floor(5 * scale), y, dispW, stepperH)
        dispBox:initialise()
        dispBox.backgroundColor = { r = 0.04, g = 0.06, b = 0.09, a = 0.90 }
        dispBox.borderColor = { r = 0.20, g = 0.35, b = 0.55, a = 0.90 }
        if tooltipText then
            dispBox.tooltip = tooltipText
        end
        panel:addChild(dispBox)

        local function getDisplayText()
            local v = valuesList[curIdx]
            if formatFn then return formatFn(v) end
            return tostring(v)
        end

        dispBox.render = function(p)
            local str = getDisplayText()
            local strW = MPOptim.Utils.MeasureText(smallFont, str)
            local textX = math.floor((p.width - strW) / 2)
            local textY = math.floor((p.height - fontH) / 2)
            p:drawRect(0, 0, p.width, p.height, p.backgroundColor.a, p.backgroundColor.r, p.backgroundColor.g, p.backgroundColor.b)
            p:drawRectBorder(0, 0, p.width, p.height, p.borderColor.a, p.borderColor.r, p.borderColor.g, p.borderColor.b)
            p:drawText(str, textX, textY, 0.35, 0.85, 1.0, 1.0, smallFont)
        end

        local leftBtn = ISButton:new(rightSideX, y, btnW, stepperH, "<", panel, function()
            if curIdx > 1 then
                curIdx = curIdx - 1
                MPOptim.Config.Set(configKey, valuesList[curIdx])
                MPOptim.Config.Save()
                if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
            end
        end)
        leftBtn:initialise()
        leftBtn.backgroundColor = { r = 0.12, g = 0.20, b = 0.32, a = 0.95 }
        leftBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_Stepper_Prev", "Decrease value")
        panel:addChild(leftBtn)

        local rightBtn = ISButton:new(rightSideX + btnW + dispW + math.floor(10 * scale), y, btnW, stepperH, ">", panel, function()
            if curIdx < #valuesList then
                curIdx = curIdx + 1
                MPOptim.Config.Set(configKey, valuesList[curIdx])
                MPOptim.Config.Save()
                if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
            end
        end)
        rightBtn:initialise()
        rightBtn.backgroundColor = { r = 0.12, g = 0.20, b = 0.32, a = 0.95 }
        rightBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_Stepper_Next", "Increase value")
        panel:addChild(rightBtn)

        local stepperObj = {
            key = configKey,
            values = valuesList,
            update = function()
                local val = MPOptim.Config and MPOptim.Config.Get(configKey)
                for i, v in ipairs(valuesList) do
                    if v == val then curIdx = i break end
                end
            end,
            setEnable = function(enabled)
                leftBtn.enable = (enabled == true)
                rightBtn.enable = (enabled == true)
                if enabled then
                    labelObj.color = { r = 0.90, g = 0.90, b = 0.90, a = 1.0 }
                    dispBox.backgroundColor = { r = 0.04, g = 0.06, b = 0.09, a = 0.90 }
                    dispBox.borderColor = { r = 0.20, g = 0.35, b = 0.55, a = 0.90 }
                else
                    labelObj.color = { r = 0.45, g = 0.45, b = 0.45, a = 0.60 }
                    dispBox.backgroundColor = { r = 0.03, g = 0.04, b = 0.06, a = 0.40 }
                    dispBox.borderColor = { r = 0.12, g = 0.18, b = 0.25, a = 0.40 }
                end
            end
        }
        table.insert(self.steppers, stepperObj)
        self.stepperMap[configKey] = stepperObj
        return stepperObj
    end

    -- Helper function to guarantee robust Java UIElement scrolling with hardware stencil clipping
    local function makeScrollable(panel, targetContentHeight)
        panel.targetScrollHeight = targetContentHeight or panel.height
        panel:addScrollBars(false)
        if panel.vscroll then
            panel.vscroll.doSetStencil = true
            panel.vscroll.background = true
            panel.vscroll.backgroundColor = { r = 0.04, g = 0.06, b = 0.10, a = 0.85 }
            panel.vscroll.borderColor = { r = 0.20, g = 0.32, b = 0.48, a = 0.90 }
        end
        panel.prerender = function(p)
            if p.javaObject then
                p.javaObject:setScrollChildren(true)
                p.javaObject:setScrollHeight(p.targetScrollHeight or p.height)
                p:updateScrollbars()
            end
            p:setStencilRect(0, 0, p.width, p.height)
            ISPanel.prerender(p)
        end
        panel.render = function(p)
            ISPanel.render(p)
            p:clearStencilRect()
        end
        panel.onMouseWheel = function(p, del)
            p:setYScroll(p:getYScroll() - (del * 45))
            return true
        end
    end

    local function forwardFocus(p, parentWin)
        p.onMouseDown = function(self, x, y)
            if parentWin and parentWin.bringToTop then parentWin:bringToTop() end
            return ISPanel.onMouseDown(self, x, y)
        end
    end

    -- ========================================================================
    -- TAB 1: QUICK ACTIONS & LIVE DIAGNOSTICS
    -- ========================================================================
    self.panelTab1 = ISPanel:new(subX, subY, subW, subH)
    self.panelTab1:initialise()
    forwardFocus(self.panelTab1, self)
    self.panelTab1.backgroundColor = { r = 0.06, g = 0.08, b = 0.13, a = 1.0 }
    self.panelTab1.borderColor = { r = 0.18, g = 0.28, b = 0.44, a = 0.90 }
    self:addChild(self.panelTab1)

    local leftColW = math.floor(subW * 0.46)
    local startBtnX = math.floor(20 * scale)
    local startBtnY = math.floor(18 * scale)
    local btnH = math.max(34, math.floor(fontH + 16 * scale))
    local btnSpacing = btnH + math.floor(10 * scale)

    self.purgeRamBtn = ISButton:new(startBtnX, startBtnY + (0 * btnSpacing), leftColW, btnH, MPOptim.GetText("UI_MPOptim_PurgeRAM", "Instant Memory Purge (GC)"), self, function(s)
        local freed = 0
        if MPOptim.GCOptimizer and MPOptim.GCOptimizer.PurgeMemory then
            freed = MPOptim.GCOptimizer.PurgeMemory()
        end
        local player = getPlayer and getPlayer()
        if player and MPOptim.Utils and MPOptim.Utils.Notify then
            local msg = string.format(MPOptim.GetText("UI_MPOptim_FreedRAM", "Freed %.1f MB RAM"), freed)
            MPOptim.Utils.Notify(player, msg, true)
        end
    end)
    self.purgeRamBtn:initialise()
    self.purgeRamBtn.backgroundColor = { r = 0.15, g = 0.35, b = 0.60, a = 0.95 }
    self.purgeRamBtn.borderColor = { r = 0.30, g = 0.65, b = 0.95, a = 1.0 }
    self.purgeRamBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_PurgeRAM", "Instantly forces a dual-pass garbage collection cycle to reclaim orphaned Lua tables, closures, and dead userdata.")
    self.panelTab1:addChild(self.purgeRamBtn)

    -- Dynamic admin permissions managed via self:updateAdminPermissions()

    self.cleanBloodBtn = ISButton:new(startBtnX, startBtnY + (1 * btnSpacing), leftColW, btnH, MPOptim.GetText("UI_MPOptim_CleanBlood", "Clean Blood Decals in Radius"), self, function(s)
        if MPOptim.ClientCleaner then MPOptim.ClientCleaner.QuickClean("blood") end
    end)
    self.cleanBloodBtn:initialise()
    self.cleanBloodBtn.backgroundColor = { r = 0.12, g = 0.20, b = 0.32, a = 0.95 }
    self.cleanBloodBtn.borderColor = { r = 0.25, g = 0.48, b = 0.75, a = 1.0 }
    self.cleanBloodBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_CleanBlood", "Manually removes floor and wall blood decals within your configured radius.")
    self.panelTab1:addChild(self.cleanBloodBtn)

    self.cleanCorpsesBtn = ISButton:new(startBtnX, startBtnY + (2 * btnSpacing), leftColW, btnH, MPOptim.GetText("UI_MPOptim_CleanCorpse", "Clean Corpses in Radius"), self, function(s)
        if MPOptim.ClientCleaner then MPOptim.ClientCleaner.QuickClean("corpse") end
    end)
    self.cleanCorpsesBtn:initialise()
    self.cleanCorpsesBtn.backgroundColor = { r = 0.12, g = 0.20, b = 0.32, a = 0.95 }
    self.cleanCorpsesBtn.borderColor = { r = 0.25, g = 0.48, b = 0.75, a = 1.0 }
    self.cleanCorpsesBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_CleanCorpse", "Manually purges empty or junk zombie corpses in radius while strictly preserving weapons, bags, ammo, and keys.")
    self.panelTab1:addChild(self.cleanCorpsesBtn)

    self.cleanDebrisBtn = ISButton:new(startBtnX, startBtnY + (3 * btnSpacing), leftColW, btnH, MPOptim.GetText("UI_MPOptim_CleanDebris", "Clean Ground Debris in Radius"), self, function(s)
        if MPOptim.ClientCleaner then MPOptim.ClientCleaner.QuickClean("debris") end
    end)
    self.cleanDebrisBtn:initialise()
    self.cleanDebrisBtn.backgroundColor = { r = 0.12, g = 0.20, b = 0.32, a = 0.95 }
    self.cleanDebrisBtn.borderColor = { r = 0.25, g = 0.48, b = 0.75, a = 1.0 }
    self.cleanDebrisBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_CleanDebris", "Manually clears spent bullet casings, empty tins, broken glass, and twigs from the ground.")
    self.panelTab1:addChild(self.cleanDebrisBtn)

    self.cleanAllBtn = ISButton:new(startBtnX, startBtnY + (4 * btnSpacing), leftColW, btnH, MPOptim.GetText("UI_MPOptim_CleanAll", "Full Clean Sweep (All in Radius)"), self, function(s)
        if MPOptim.ClientCleaner then MPOptim.ClientCleaner.QuickClean("all") end
    end)
    self.cleanAllBtn:initialise()
    self.cleanAllBtn.backgroundColor = { r = 0.14, g = 0.42, b = 0.28, a = 0.98 }
    self.cleanAllBtn.borderColor = { r = 0.28, g = 0.75, b = 0.48, a = 1.0 }
    self.cleanAllBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_CleanAll", "Performs an immediate all-in-one maintenance sweep (Blood + Corpses + Ground Debris + RAM Purge) in your local area.")
    self.panelTab1:addChild(self.cleanAllBtn)

    -- ========================================================================
    -- TAB 1: CUSTOM USER PRESET MANAGER (SAVE / LOAD / DELETE)
    -- ========================================================================
    local presetSectionY = startBtnY + (5 * btnSpacing) + math.floor(8 * scale)
    local presetHeaderH = math.max(22, math.floor(fontH + 6 * scale))

    -- Engine Agent Detection Indicator
    local isAgent = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
    local agentText = isAgent and "[+] Engine Agent: ACTIVE (JVM Injected)" or "[-] Engine Agent: Inactive (Standard Lua Mode - Fully Functional)"
    local ar, ag, ab = 0.55, 0.60, 0.70
    if isAgent then ar, ag, ab = 0.30, 0.90, 0.45 end
    local agentLabel = ISLabel:new(startBtnX, presetSectionY - math.floor(18 * scale), fontH, agentText, ar, ag, ab, 1.0, smallFont, true)
    agentLabel:initialise()
    self.panelTab1:addChild(agentLabel)

    local customHeader = ISLabel:new(startBtnX, presetSectionY, fontH, "[*] CUSTOM USER PRESET PROFILES", 0.30, 0.85, 1.0, 1.0, smallFont, true)
    customHeader:initialise()
    self.panelTab1:addChild(customHeader)

    local comboY = presetSectionY + presetHeaderH + math.floor(4 * scale)
    local comboH = math.max(26, math.floor(fontH + 8 * scale))
    self.presetCombo = ISComboBox:new(startBtnX, comboY, leftColW, comboH, self, function(target, box)
        -- Selected preset changed
    end)
    self.presetCombo:initialise()
    self.presetCombo.backgroundColor = { r = 0.04, g = 0.07, b = 0.12, a = 0.95 }
    self.presetCombo.borderColor = { r = 0.25, g = 0.45, b = 0.70, a = 0.90 }
    self.panelTab1:addChild(self.presetCombo)

    local function getComboSelectedName(combo)
        if not combo then return nil end
        if combo.getOptionText and combo.selected and combo.selected > 0 then
            return combo:getOptionText(combo.selected)
        end
        if combo.options and combo.selected and combo.options[combo.selected] then
            local opt = combo.options[combo.selected]
            if type(opt) == "table" then
                return opt.text or opt.data
            elseif type(opt) == "string" then
                return opt
            end
        end
        if combo.getValue then
            return combo:getValue()
        end
        return nil
    end

    self.refreshCustomPresets = function(s)
        if not s.presetCombo then return end
        s.presetCombo:clear()
        if MPOptim.CustomPresets and MPOptim.CustomPresets.LoadAll then
            MPOptim.CustomPresets.LoadAll()
        end
        local list = (MPOptim.CustomPresets and MPOptim.CustomPresets.GetList()) or {}
        for _, name in ipairs(list) do
            s.presetCombo:addOption(name)
        end
        if #list == 0 then
            s.presetCombo:addOption("No Saved Presets")
        end
    end
    self:refreshCustomPresets()

    -- Preset Actions Row (Load, Save Current, Delete)
    local actRowY = comboY + comboH + math.floor(8 * scale)
    local actBtnH = math.max(28, math.floor(fontH + 10 * scale))
    local actSpacing = math.floor(6 * scale)
    local actBtnW = math.floor((leftColW - (actSpacing * 2)) / 3)

    -- 1. Load Button
    local loadBtn = ISButton:new(startBtnX + (0 * (actBtnW + actSpacing)), actRowY, actBtnW, actBtnH, "[>] LOAD", self, function(s)
        local selName = getComboSelectedName(s.presetCombo)
        if selName and selName ~= "No Saved Presets" then
            if MPOptim.CustomPresets and MPOptim.CustomPresets.LoadPreset then
                MPOptim.CustomPresets.LoadPreset(selName)
                s:refreshAllControls()
                local player = getPlayer and getPlayer()
                if player and MPOptim.Utils and MPOptim.Utils.Notify then
                    MPOptim.Utils.Notify(player, "Applied Custom Preset: " .. selName, true)
                end
            end
        end
    end)
    loadBtn:initialise()
    loadBtn.backgroundColor = { r = 0.10, g = 0.40, b = 0.50, a = 0.95 }
    loadBtn.borderColor = { r = 0.20, g = 0.75, b = 0.85, a = 1.0 }
    loadBtn.tooltip = "Loads the selected custom preset profile and applies all configured optimization toggles immediately."
    self.panelTab1:addChild(loadBtn)

    -- 2. Save Button
    local saveBtn = ISButton:new(startBtnX + (1 * (actBtnW + actSpacing)), actRowY, actBtnW, actBtnH, "[+] SAVE AS", self, function(s)
        local sw, sh = getCore():getScreenWidth(), getCore():getScreenHeight()
        local boxW = math.max(340, math.floor(380 * scale))
        local boxH = math.max(150, math.floor(160 * scale))
        local boxX = math.floor((sw - boxW) / 2)
        local boxY = math.floor((sh - boxH) / 2)

        local modal = ISTextBox:new(boxX, boxY, boxW, boxH, "Save Current Settings as Custom Preset:", "My Preset", s, function(target, button)
            if button.internal == "OK" then
                local txt = button.parent.entry:getText()
                if txt and string.trim(txt) ~= "" then
                    local cleanName = string.trim(txt)
                    MPOptim.CustomPresets.SavePreset(cleanName, MPOptim.Config.Current)
                    target:refreshCustomPresets()
                    local player = getPlayer and getPlayer()
                    if player and MPOptim.Utils and MPOptim.Utils.Notify then
                        MPOptim.Utils.Notify(player, "Saved Preset: " .. cleanName, true)
                    end
                end
            end
        end)
        modal:initialise()
        modal:addToUIManager()
    end)
    saveBtn:initialise()
    saveBtn.backgroundColor = { r = 0.35, g = 0.25, b = 0.10, a = 0.95 }
    saveBtn.borderColor = { r = 0.85, g = 0.60, b = 0.20, a = 1.0 }
    saveBtn.tooltip = "Saves your current checkbox and slider settings into a new named preset profile."
    self.panelTab1:addChild(saveBtn)

    -- 3. Delete Button
    local delBtn = ISButton:new(startBtnX + (2 * (actBtnW + actSpacing)), actRowY, actBtnW, actBtnH, "[X] DELETE", self, function(s)
        local selName = getComboSelectedName(s.presetCombo)
        if selName and selName ~= "No Saved Presets" then
            if MPOptim.CustomPresets and MPOptim.CustomPresets.DeletePreset then
                MPOptim.CustomPresets.DeletePreset(selName)
                s:refreshCustomPresets()
                local player = getPlayer and getPlayer()
                if player and MPOptim.Utils and MPOptim.Utils.Notify then
                    MPOptim.Utils.Notify(player, "Deleted Preset: " .. selName, false)
                end
            end
        end
    end)
    delBtn:initialise()
    delBtn.backgroundColor = { r = 0.45, g = 0.15, b = 0.15, a = 0.95 }
    delBtn.borderColor = { r = 0.85, g = 0.30, b = 0.30, a = 1.0 }
    delBtn.tooltip = "Permanently deletes the selected custom preset profile."
    self.panelTab1:addChild(delBtn)

    -- 4. Custom Shaders Quick Toggle with Warning Banner in Tab 1
    local shaderTickY = actRowY + actBtnH + math.floor(14 * scale)
    addTick(self.panelTab1, shaderTickY, MPOptim.GetText("UI_ModOptions_GFX_CustomShaders", "Enable Custom Shaders (GPU Boost)"), "GFX_CustomShaders", function(sel)
        if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
        if MPOptim.WeatherOptimizer and MPOptim.WeatherOptimizer.Update then MPOptim.WeatherOptimizer.Update() end
    end, startBtnX, leftColW, MPOptim.GetText("UI_MPOptim_Tooltip_GFX_CustomShaders", "Enables GPU-accelerated water & wall shaders for maximum FPS. WARNING: If you experience graphical issues or glitches on your GPU, disable this."))

    local shaderWarnLabel = ISLabel:new(startBtnX, shaderTickY + math.floor(22 * scale), fontH, MPOptim.GetText("UI_MPOptim_ShaderWarning", "[!] Disable this if experiencing graphical issues or driver glitches"), 0.95, 0.55, 0.20, 1.0, smallFont, true)
    shaderWarnLabel:initialise()
    self.panelTab1:addChild(shaderWarnLabel)

    -- 5. Server Sync Section (Syncs and persists client config to dedicated server disk)
    local syncY = shaderTickY + math.floor(45 * scale)
    local syncH = math.max(28, math.floor(fontH + 10 * scale))
    self.syncServerBtn = ISButton:new(startBtnX, syncY, leftColW, syncH, MPOptim.GetText("UI_MPOptim_SyncServer", "[#] SYNC SETTINGS TO SERVER"), self, function(s)
        local isMP = isClient and isClient()
        local player = getPlayer and getPlayer()
        if not isMP then
            if MPOptim.Config and MPOptim.Config.Save then
                MPOptim.Config.Save()
            end
            if player and MPOptim.Utils and MPOptim.Utils.Notify then
                MPOptim.Utils.Notify(player, MPOptim.GetText("UI_MPOptim_SyncSinglePlayer", "Single Player / Local Game: Settings saved to local disk!"), true)
            end
            return
        end

        if not MPOptim.Utils or not MPOptim.Utils.IsAdmin(player) then
            if player and MPOptim.Utils and MPOptim.Utils.Notify then
                MPOptim.Utils.Notify(player, MPOptim.GetText("UI_MPOptim_SyncNeedAdmin", "Syncing settings to server requires Server Admin permissions or Debug Mode."), false)
            end
            return
        end

        if MPOptim.Network and MPOptim.Network.SendAdminConfigUpdate then
            MPOptim.Network.SendAdminConfigUpdate(MPOptim.Config and MPOptim.Config.Current)
            if player and MPOptim.Utils and MPOptim.Utils.Notify then
                MPOptim.Utils.Notify(player, MPOptim.GetText("UI_MPOptim_SyncSending", "Sent Optimiser settings to server..."), true)
            end
        end
    end)
    self.syncServerBtn:initialise()
    self.syncServerBtn.backgroundColor = { r = 0.18, g = 0.28, b = 0.45, a = 0.95 }
    self.syncServerBtn.borderColor = { r = 0.40, g = 0.70, b = 1.0, a = 1.0 }
    self.syncServerBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_SyncServer", "Transfers and saves your current Optimiser settings directly into the dedicated server configuration file on disk, without needing to manually edit or upload server files.")
    self.panelTab1:addChild(self.syncServerBtn)

    self.updateAdminPermissions = function(s)
        local inWorld = (getPlayer and getPlayer()) ~= nil
        local isMP = isClient and isClient()
        local player = inWorld and getPlayer()
        local isMPAdmin = inWorld and isMP and MPOptim.Utils and MPOptim.Utils.IsAdmin and MPOptim.Utils.IsAdmin(player)
        local adminOnlyTip = MPOptim.GetText("UI_MPOptim_AdminOnlyTip", "Manual area cleanups in Multiplayer are restricted to Server Administrators.")

        -- In Single Player / local host, player can use manual cleanup buttons freely
        local canClean = not isMP or isMPAdmin

        if s.cleanBloodBtn then
            s.cleanBloodBtn:setEnable(canClean)
            s.cleanBloodBtn.tooltip = canClean and MPOptim.GetText("UI_MPOptim_Tooltip_CleanBlood", "Manually removes floor and wall blood decals within your configured radius.") or adminOnlyTip
        end
        if s.cleanCorpsesBtn then
            s.cleanCorpsesBtn:setEnable(canClean)
            s.cleanCorpsesBtn.tooltip = canClean and MPOptim.GetText("UI_MPOptim_Tooltip_CleanCorpse", "Manually purges empty or junk zombie corpses in radius while strictly preserving weapons, bags, ammo, and keys.") or adminOnlyTip
        end
        if s.cleanDebrisBtn then
            s.cleanDebrisBtn:setEnable(canClean)
            s.cleanDebrisBtn.tooltip = canClean and MPOptim.GetText("UI_MPOptim_Tooltip_CleanDebris", "Manually clears spent bullet casings, empty tins, broken glass, and twigs from the ground.") or adminOnlyTip
        end
        if s.cleanAllBtn then
            s.cleanAllBtn:setEnable(canClean)
            s.cleanAllBtn.tooltip = canClean and MPOptim.GetText("UI_MPOptim_Tooltip_CleanAll", "Performs an immediate all-in-one maintenance sweep (Blood + Corpses + Ground Debris + RAM Purge) in your local area.") or adminOnlyTip
        end

        -- Server Sync Button: STRICTLY visible only to Admins in an active Multiplayer session
        if s.syncServerBtn then
            s.syncServerBtn:setVisible(isMPAdmin == true)
            s.syncServerBtn:setEnable(isMPAdmin == true)
        end
    end

    self:updateAdminPermissions()

    -- Tab 1 Live Diagnostics Card
    self.panelTab1.render = function(p)
        if not p:isVisible() or not p.parent or p.parent.currentTab ~= 1 then return end
        ISPanel.render(p)

        local font = (UIFont and UIFont.Small) or 0
        local medFont = (UIFont and UIFont.Medium) or 0
        local sc, fH = MPOptim.Utils.GetUIScale()
        local mFontH = fH + 4
        if getTextManager and getTextManager().getFontHeight then
            mFontH = getTextManager():getFontHeight(medFont)
        end

        local cardX = startBtnX + leftColW + math.floor(20 * sc)
        local cardY = startBtnY
        local cardW = p.width - cardX - math.floor(20 * sc)
        local padX = math.floor(18 * sc)
        local padY = math.floor(16 * sc)
        local diagLineH = math.max(26, math.floor(fH + 10 * sc))

        local isAudioMod = MPOptim.Utils and MPOptim.Utils.IsAudioReplacerActive and MPOptim.Utils.IsAudioReplacerActive()
        local audioStatusStr = isAudioMod and "Protected (Audio Mod Active)" or "Active (Safe Mode)"

        local isTexComp = (getCore and getCore().getOptionTextureCompression and getCore():getOptionTextureCompression()) or false
        local texCompStr = isTexComp and "Active (Optimized VRAM)" or "Disabled (Needs Enable/Restart)"
        local texCompR, texCompG, texCompB = 0.40, 0.95, 0.45
        if not isTexComp then
            texCompR, texCompG, texCompB = 0.95, 0.45, 0.25
        end

        local rows = {
            { text = "- Lua RAM Footprint: " .. tostring((MPOptim.Utils and MPOptim.Utils.formatMemoryMB and MPOptim.Utils.formatMemoryMB()) or "N/A"), r = 0.92, g = 0.92, b = 0.92 },
            { text = "- Real-Time GPU Framerate: " .. tostring((MPOptim.Utils and MPOptim.Utils.getFPS and MPOptim.Utils.getFPS()) or 60) .. " FPS", r = 0.95, g = 0.85, b = 0.35 },
            { text = "- Texture Compression: " .. texCompStr, r = texCompR, g = texCompG, b = texCompB },
            { text = "- Sound Replacer Support: " .. audioStatusStr, r = 0.35, g = 0.90, b = 1.0 },
            { text = "- Blood Decals Cleaned: " .. tostring((MPOptim.StaggerQueue and MPOptim.StaggerQueue.stats and MPOptim.StaggerQueue.stats.bloodCleaned) or 0), r = 0.92, g = 0.92, b = 0.92 },
            { text = "- Corpses Purged: " .. tostring((MPOptim.StaggerQueue and MPOptim.StaggerQueue.stats and MPOptim.StaggerQueue.stats.corpsesCleaned) or 0), r = 0.92, g = 0.92, b = 0.92 },
            { text = "- Ground Debris Cleared: " .. tostring((MPOptim.StaggerQueue and MPOptim.StaggerQueue.stats and MPOptim.StaggerQueue.stats.debrisCleaned) or 0), r = 0.92, g = 0.92, b = 0.92 },
            { text = "- Base Protection: Active (Safehouses & SP Structures)", r = 0.40, g = 0.95, b = 0.45 },
        }

        local cardH = padY + mFontH + math.floor(10 * sc) + (#rows * diagLineH) + padY

        p:drawRect(cardX, cardY, cardW, cardH, 0.70, 0.05, 0.07, 0.11)
        p:drawRectBorder(cardX, cardY, cardW, cardH, 0.85, 0.22, 0.38, 0.60)
        p:drawRect(cardX + 1, cardY + 1, cardW - 2, 2, 0.95, 0.20, 0.75, 1.0)

        p:drawText("Live Optimization Diagnostics", cardX + padX, cardY + padY, 0.4, 0.85, 1.0, 1.0, medFont)

        local rowY = cardY + padY + mFontH + math.floor(10 * sc)
        for _, row in ipairs(rows) do
            p:drawText(row.text, cardX + padX, rowY, row.r, row.g, row.b, 1.0, font)
            rowY = rowY + diagLineH
        end
    end

    -- ========================================================================
    -- TAB 2: GENERAL, ENGINE & GRAPHICS SUITE (2-Column Layout)
    -- ========================================================================
    self.panelTab2 = ISPanel:new(subX, subY, subW, subH)
    self.panelTab2:initialise()
    forwardFocus(self.panelTab2, self)
    self.panelTab2.backgroundColor = { r = 0.06, g = 0.08, b = 0.13, a = 1.0 }
    self.panelTab2.borderColor = { r = 0.18, g = 0.28, b = 0.44, a = 0.90 }
    self:addChild(self.panelTab2)

    local startOptY = math.floor(14 * scale)
    local colW = math.floor((subW - math.floor(80 * scale)) / 2)
    local col1X = math.floor(16 * scale)
    local col2X = col1X + colW + math.floor(16 * scale)

    -- Left Column: Interface, Memory & Mod Shield (Slots 0 - 7)
    addTick(self.panelTab2, startOptY + (0 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_UI_ShowContextMenu", "Show in Right-Click Context Menu"), "UI_ShowContextMenu", nil, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_UI_ShowContextMenu", "Adds 'Project Zomboid Optimiser' options to right-click world menus for fast access."))
    addTick(self.panelTab2, startOptY + (1 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_UI_ShowHUD", "Show Diagnostics Overlay (FPS / RAM HUD)"), "UI_ShowHUD", function(sel)
        if MPOptim.SetHUDVisible then MPOptim.SetHUDVisible(sel) end
    end, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_UI_ShowHUD", "Displays a lightweight real-time FPS and Lua memory counter in the top-left corner of the screen."))
    addTick(self.panelTab2, startOptY + (2 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_UI_ShowNotifications", "Show Overhead Status Text During Sweeps"), "UI_ShowNotifications", nil, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_UI_ShowNotifications", "Displays green overhead text whenever automated cleanups or memory purges occur."))
    addTick(self.panelTab2, startOptY + (3 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_GC_SmartIdleGC", "Smart Idle Garbage Collection (RAM Purge)"), "GC_SmartIdleGC", nil, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_GC_SmartIdleGC", "Runs gentle memory sweeps only during sleep, reading, and safe resting when RAM exceeds your threshold."))
    addTick(self.panelTab2, startOptY + (4 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_ModShield_Enabled", "Enable ModShield (3rd-Party Mod Protection)"), "ModShield_Enabled", nil, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_ModShield_Enabled", "Comprehensive protection suite against 3rd-party mods: neutralizes forced GC freezes during combat/driving, throttles disk I/O log spam (100% preserves errors), and shields Build 42 vehicle mechanics from malformed recipe crashes."))
    addTick(self.panelTab2, startOptY + (8 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Plumbing_ThrottleWaterPipes", "Water Pipes & Plumbing Throttler (Fixes Lag)"), "Plumbing_ThrottleWaterPipes", nil, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Plumbing_ThrottleWaterPipes", "Throttles expensive 60 Hz per-frame pipe flow loops in Water Pipes and irrigation mods down to 1 Hz, dropping CPU load by 98% with zero gameplay loss."))
    addTick(self.panelTab2, startOptY + (5 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_GFX_EnforceTextureCompression", "Enforce Texture Compression (50+ percent VRAM)"), "GFX_EnforceTextureCompression", function(sel)
        if sel and MPOptim.Utils and MPOptim.Utils.CheckAndEnforceTextureCompression then
            MPOptim.Utils.CheckAndEnforceTextureCompression()
        end
    end, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_GFX_EnforceTextureCompression", "Forces texture compression in options.ini, cutting VRAM usage in half and stopping texture loading hitching."))
    addTick(self.panelTab2, startOptY + (6 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_GFX_BuildingInteriorCull", "Multi-Story Building Occlusion Culling"), "GFX_BuildingInteriorCull", function(sel)
        if MPOptim.BuildingOptimizer and MPOptim.BuildingOptimizer.Update then MPOptim.BuildingOptimizer.Update() end
    end, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_GFX_BuildingInteriorCull", "Culls hidden lower floors and unviewable exterior ground tiles when inside multi-story buildings and skyscrapers. Automatically restores near windows & balconies."))
    addTick(self.panelTab2, startOptY + (7 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_UI_FastInventory", "Optimize Inventory & Large Item Lists"), "UI_FastInventory", nil, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_UI_FastInventory", "Accelerates inventory rendering and eliminates scrolling stutters in containers with 500+ items via tooltip throttling and bulk transfer debounce."))

    -- Right Column: Character Mesh & Multi-Threading (Slots 0 - 7)
    addTick(self.panelTab2, startOptY + (0 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_GFX_ModelLighting", "3D Model Dynamic Vertex Lighting"), "GFX_ModelLighting", function(sel)
        if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
    end, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_GFX_ModelLighting", "Uncheck in Potato Mode to shade character/zombie meshes with ambient room light rather than per-vertex dynamic point lights."))
    addTick(self.panelTab2, startOptY + (1 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Horde_ThrottleStaticAnims", "Throttle Idle/Static Character Animations (15 FPS)"), "Horde_ThrottleStaticAnims", function(sel)
        if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
    end, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Horde_ThrottleStaticAnims", "Reduces skeletal animation update frequency for idle, sleeping, or standing characters to 15 FPS to save massive CPU cycles."))
    addTick(self.panelTab2, startOptY + (2 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Horde_AccelerateAnimFalloff", "Accelerate Distant Zombie Animation LOD Falloff"), "Horde_AccelerateAnimFalloff", function(sel)
        if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
    end, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Horde_AccelerateAnimFalloff", "Transitions distant zombies into stepped LOD animation poses sooner, eliminating frame drops when large swarms approach."))
    addTick(self.panelTab2, startOptY + (3 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Horde_OffscreenAnimDelay", "Offscreen Zombie Animation Throttling"), "Horde_OffscreenAnimDelay", function(sel)
        if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
    end, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Horde_OffscreenAnimDelay", "Skips skeletal mesh bone and animation math for zombies outside your camera view."))
    addTick(self.panelTab2, startOptY + (4 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_FBORender_CheapOcclusion", "Fast Building Cutaway Occlusion Math"), "FBORender_CheapOcclusion", function(sel)
        if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
    end, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_FBORender_CheapOcclusion", "Optimizes cutaway wall and multi-story occlusion calculations for smooth interior frame rates."))
    addTick(self.panelTab2, startOptY + (5 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_GFX_DynamicZoomLOD", "Dynamic Zoom-Level LOD & Sub-Pixel Culling"), "GFX_DynamicZoomLOD", function(sel)
        if MPOptim.ZoomLOD and MPOptim.ZoomLOD.Update then MPOptim.ZoomLOD.Update() end
    end, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_GFX_DynamicZoomLOD", "Dynamically scales sub-pixel ground debris and skeleton blending when zoomed out to 150-250 percent to eliminate zoom-out frame lag."))
    addTick(self.panelTab2, startOptY + (6 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_GFX_ForestCanopyCull", "Deep Forest Canopy Occlusion Culler"), "GFX_ForestCanopyCull", function(sel)
        if MPOptim.ForestCuller and MPOptim.ForestCuller.Update then MPOptim.ForestCuller.Update() end
    end, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_GFX_ForestCanopyCull", "Culls wind sway vertex math on fully enclosed deep interior trees, keeping 100 percent of outer forest canopy silhouette intact."))
    addTick(self.panelTab2, startOptY + (7 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Threaded_Lighting", "[EXPERIMENTAL] Multi-Threaded Dynamic Lighting"), "Threaded_Lighting", function(sel)
        if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
    end, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Threaded_Lighting", "[EXPERIMENTAL] Offloads real-time dynamic lighting and shadow propagation math to background worker threads. WARNING: May cause main-thread sync stalls during intense combat."))

    -- Advanced Steppers Section (Tab 2)
    local stepY2 = startOptY + (8 * self.tickSpacing) + math.floor(14 * scale)
    local stepGap = math.max(36, math.floor(fontH + 16 * scale))
    addStepper(self.panelTab2, stepY2 + (0 * stepGap), MPOptim.GetText("UI_ModOptions_Lighting_FPS", "Dynamic Lighting Refresh Rate"), "Lighting_FPS", { 15, 20, 30, 45, 60 }, function(v) return tostring(v) .. " FPS" end, MPOptim.GetText("UI_MPOptim_Tooltip_Lighting_FPS", "Controls the target update framerate for dynamic lighting propagation. Lower values (15-30 FPS) save huge CPU cycles."))
    addStepper(self.panelTab2, stepY2 + (1 * stepGap), MPOptim.GetText("UI_ModOptions_GC_PurgeThresholdMB", "GC Purge RAM Threshold"), "GC_PurgeThresholdMB", { 1200, 1600, 2000, 2400, 2800, 3200, 4000 }, function(v) return tostring(v) .. " MB" end, MPOptim.GetText("UI_MPOptim_Tooltip_GC_PurgeThresholdMB", "Memory usage cutoff threshold required before Smart Idle Garbage Collection triggers a background sweep."))

    makeScrollable(self.panelTab2, stepY2 + (2 * stepGap) + math.floor(35 * scale))

        -- ========================================================================
    -- TAB 3: VEHICLES & ROAD STREAMING SUITE (Dedicated Vehicle Tab)
    -- ========================================================================
    self.panelTab3 = ISPanel:new(subX, subY, subW, subH)
    self.panelTab3:initialise()
    forwardFocus(self.panelTab3, self)
    self.panelTab3.backgroundColor = { r = 0.06, g = 0.08, b = 0.13, a = 1.0 }
    self.panelTab3.borderColor = { r = 0.18, g = 0.28, b = 0.44, a = 0.90 }
    self:addChild(self.panelTab3)

    -- Left Column: Vehicle Streaming & Optimization Controls (Slots 0 - 6)
    addTick(self.panelTab3, startOptY + (0 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Vehicle_PhysicsSleep", "Parked Vehicle Physics Sleeping"), "Vehicle_PhysicsSleep", function(sel)
        if MPOptim.VehicleSleeper and MPOptim.VehicleSleeper.Update then MPOptim.VehicleSleeper.Update() end
    end, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Vehicle_PhysicsSleep", "Puts stationary, empty parked vehicles into Bullet physics sleep mode to eliminate physics lag in car compounds & parking lots."))
    addTick(self.panelTab3, startOptY + (1 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Vehicle_ChunkPriorityMode", "Anti-Stutter Vehicle Streamer (Master Switch)"), "Vehicle_ChunkPriorityMode", nil, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Vehicle_ChunkPriorityMode", "Prioritizes road chunk loading bandwidth and throttles non-essential systems while driving."))
    addTick(self.panelTab3, startOptY + (2 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Vehicle_LimitDriveZoom", "Prevent Extreme Auto-Zoom While Driving"), "Vehicle_LimitDriveZoom", nil, col1X + math.floor(15 * scale), colW - math.floor(15 * scale), MPOptim.GetText("UI_MPOptim_Tooltip_Vehicle_LimitDriveZoom", "Prevents camera auto-zoom while driving to reduce draw calls. Keep OFF (recommended) to allow the camera to expand road lookahead so chunks stream far ahead at high speeds."))
    addTick(self.panelTab3, startOptY + (3 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Vehicle_PreDrivePurge", "Pre-Drive RAM Purge on Vehicle Entry"), "Vehicle_PreDrivePurge", nil, col1X + math.floor(15 * scale), colW - math.floor(15 * scale), MPOptim.GetText("UI_MPOptim_Tooltip_Vehicle_PreDrivePurge", "[OPT-IN] Performs a gentle incremental memory sweep upon entering a car. Default: Off to ensure 100% stutter-free vehicle entrance."))
    addTick(self.panelTab3, startOptY + (4 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Vehicle_ScaleLightingFPS", "Scale Dynamic Lighting Rate While Driving"), "Vehicle_ScaleLightingFPS", nil, col1X + math.floor(15 * scale), colW - math.floor(15 * scale), MPOptim.GetText("UI_MPOptim_Tooltip_Vehicle_ScaleLightingFPS", "Scales dynamic lighting update rate during high-speed travel. Keep OFF (recommended) so newly streamed road chunks are lit promptly without lighting lag."))
    addTick(self.panelTab3, startOptY + (5 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Vehicle_SuspendBackgroundCleanups", "Suspend Background Sweeps While Driving"), "Vehicle_SuspendBackgroundCleanups", nil, col1X + math.floor(15 * scale), colW - math.floor(15 * scale), MPOptim.GetText("UI_MPOptim_Tooltip_Vehicle_SuspendBackgroundCleanups", "Temporarily pauses tile sweeps, corpse checks, and RAM purges while driving for smooth road loading."))
    addTick(self.panelTab3, startOptY + (6 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Vehicle_ThreadedModelSlots", "Multi-Threaded 3D Model Loading (Build 42)"), "Vehicle_ThreadedModelSlots", nil, col1X + math.floor(15 * scale), colW - math.floor(15 * scale), MPOptim.GetText("UI_MPOptim_Tooltip_Vehicle_ThreadedModelSlots", "Offloads 3D vehicle parts and clothing loading to background threads instead of freezing the render loop."))
    addTick(self.panelTab3, startOptY + (7 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_GFX_DynamicReflections", "Dynamic Road & Puddle Reflections"), "GFX_DynamicReflections", function(sel)
        if getCore and getCore().setPerfReflections then
            getCore():setPerfReflections(sel == true)
        end
    end, col1X + math.floor(15 * scale), colW - math.floor(15 * scale), MPOptim.GetText("UI_MPOptim_Tooltip_GFX_DynamicReflections", "Disabling eliminates secondary reflection passes on roads and puddles, curing Build 42 driving and rain stutter."))

    -- Right Column: Roadside Entities & Swarm Enhancements (Slots 0 - 6)
    addTick(self.panelTab3, startOptY + (0 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Vehicle_ThrottleRoadsideZombies", "[EXPERIMENTAL] Throttle Roadside Zombie Mesh Skinning"), "Vehicle_ThrottleRoadsideZombies", nil, col2X + math.floor(15 * scale), colW - math.floor(15 * scale), MPOptim.GetText("UI_MPOptim_Tooltip_Vehicle_ThrottleRoadsideZombies", "[EXPERIMENTAL] Reduces zombie skeletal blending to 2-4 meshes when speeding past road entities to eliminate hitches on severe CPU bottlenecks."))
    addTick(self.panelTab3, startOptY + (1 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Vehicle_BoostImposterDistance", "[EXPERIMENTAL] Force 2D Billboard Imposters on Road Chunks"), "Vehicle_BoostImposterDistance", nil, col2X + math.floor(15 * scale), colW - math.floor(15 * scale), MPOptim.GetText("UI_MPOptim_Tooltip_Vehicle_BoostImposterDistance", "[EXPERIMENTAL] Renders newly streamed roadside zombies as lightweight 2D billboard imposters before 3D models load."))
    addTick(self.panelTab3, startOptY + (2 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Horde_ImposterRendering", "[EXPERIMENTAL] 2D Zombie Imposter Rendering (Horde Boost)"), "Horde_ImposterRendering", function(sel)
        if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
    end, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Horde_ImposterRendering", "[EXPERIMENTAL] Renders distant zombies in large 100+ hordes as 2D billboard imposters & enables GPU mesh instancing. WARNING: May cause micro-stutters during combat state transitions."))
    addTick(self.panelTab3, startOptY + (3 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Combat_BurstSmoother", "Combat Burst & Shotgun Blast Hitch Smoother"), "Combat_BurstSmoother", nil, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Combat_BurstSmoother", "Buffers simultaneous multi-kill impact bursts across 2-3 frames to eliminate combat freezing during shotgun blasts & katana multi-hits."))
    addTick(self.panelTab3, startOptY + (4 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Horde_AudioConcurrencyLimit", "Horde Audio & Groan Concurrency Limiter"), "Horde_AudioConcurrencyLimit", nil, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Horde_AudioConcurrencyLimit", "Limits simultaneous overlapping zombie groan and footstep audio emitters to the nearest 16 zombies to stop audio crackling and FMOD CPU lag."))
    addTick(self.panelTab3, startOptY + (5 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Horde_CullDistantAttachments", "Distant Zombie 3D Attachment & Accessory Culler"), "Horde_CullDistantAttachments", nil, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Horde_CullDistantAttachments", "Suppresses tiny non-essential 3D cosmetic accessories on distant zombies in large 30+ swarms."))
    addTick(self.panelTab3, startOptY + (6 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Horde_StaggeredAITicking", "Staggered Swarm AI & Pathfinding Round-Robin"), "Horde_StaggeredAITicking", nil, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_Horde_StaggeredAITicking", "Staggers zombie A* navigation recalculations across a 4-phase round-robin cycle to drop swarm AI CPU load by 75 percent."))

    -- Steppers Section (Tab 3)
    local stepY3 = startOptY + (8 * self.tickSpacing) + math.floor(14 * scale)
    addStepper(self.panelTab3, stepY3 + (0 * stepGap), MPOptim.GetText("UI_ModOptions_Vehicle_SpeedThreshold", "Streaming Activation Speed"), "Vehicle_SpeedThreshold", { 10, 15, 20, 25, 30, 40, 50 }, function(v) return tostring(v) .. " km/h" end, MPOptim.GetText("UI_MPOptim_Tooltip_Vehicle_SpeedThreshold", "Driving speed in km/h required to trigger high-speed chunk streaming prioritization."))
    makeScrollable(self.panelTab3, stepY3 + (1 * stepGap) + math.floor(35 * scale))

    -- ========================================================================
    -- TAB 4: BLOOD & CORPSES SUB-PANEL
    -- ========================================================================
    self.panelTab4 = ISPanel:new(subX, subY, subW, subH)
    self.panelTab4:initialise()
    forwardFocus(self.panelTab4, self)
    self.panelTab4.backgroundColor = { r = 0.06, g = 0.08, b = 0.13, a = 1.0 }
    self.panelTab4.borderColor = { r = 0.18, g = 0.28, b = 0.44, a = 0.90 }
    self:addChild(self.panelTab4)

    addTick(self.panelTab4, startOptY + (0 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Blood_CapPerTile", "Smart Blood Decal Stacking Cap (Max 4/Tile - Zero Visual Loss)"), "Blood_CapPerTile", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Blood_CapPerTile", "Caps overlapping blood splats to max 4 per single tile. Eliminates severe GPU overdraw lag during large battles while keeping the scene 100 percent bloody."))
    addTick(self.panelTab4, startOptY + (1 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Blood_AutoClean", "Enable Automated Blood Decal Cleanup"), "Blood_AutoClean", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Blood_AutoClean", "Periodically purges blood decals within your configured radius on a timer."))
    addTick(self.panelTab4, startOptY + (2 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Blood_RemoveWall", "Include Wall Blood Decals (Default: Off / Floor only)"), "Blood_RemoveWall", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Blood_RemoveWall", "When blood cleanup runs, also cleans wall splatters in addition to floor decals."))
    addTick(self.panelTab4, startOptY + (3 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Corpse_AutoClean", "Enable Automated Corpse Cleanup"), "Corpse_AutoClean", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Corpse_AutoClean", "Periodically purges zombie bodies outside safehouses based on age."))
    addTick(self.panelTab4, startOptY + (4 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Corpse_CleanEmptyOnly", "Only Clean Empty Corpses (0 items in inventory)"), "Corpse_CleanEmptyOnly", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Corpse_CleanEmptyOnly", "Only purges bodies that have already been completely looted by players."))
    addTick(self.panelTab4, startOptY + (5 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Corpse_CleanJunkOnly", "Clean Junk Corpses (Preserves weapons, bags, ammo & keys)"), "Corpse_CleanJunkOnly", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Corpse_CleanJunkOnly", "Cleans corpses with junk clothes/pens, but strictly preserves any corpse with weapons, bags, ammo, or keys."))
    addTick(self.panelTab4, startOptY + (6 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Corpse_CullShadows", "Cull Dynamic 3D Shadows on Dead Corpses"), "Corpse_CullShadows", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Corpse_CullShadows", "Disables dynamic shadow projection math on dead zombie bodies, saving massive draw calls in graveyard areas."))

    local stepY4 = startOptY + (7 * self.tickSpacing) + math.floor(20 * scale)
    addStepper(self.panelTab4, stepY4 + (0 * stepGap), MPOptim.GetText("UI_ModOptions_Blood_CleanRadius", "Blood Clean Radius"), "Blood_CleanRadius", { 15, 20, 30, 40, 50, 60 }, function(v) return tostring(v) .. " Tiles" end, MPOptim.GetText("UI_MPOptim_Tooltip_Blood_CleanRadius", "Distance in tiles around the player to perform blood cleanup sweeps."))
    addStepper(self.panelTab4, stepY4 + (1 * stepGap), MPOptim.GetText("UI_ModOptions_Blood_IntervalHours", "Blood Sweep Interval"), "Blood_IntervalHours", { 1, 2, 4, 8, 12, 24 }, function(v) return tostring(v) .. " Hours" end, MPOptim.GetText("UI_MPOptim_Tooltip_Blood_IntervalHours", "In-game hours between automated blood cleanup sweeps."))
    addStepper(self.panelTab4, stepY4 + (2 * stepGap), MPOptim.GetText("UI_ModOptions_Corpse_MinAgeHours", "Corpse Min Age Before Cleanup"), "Corpse_MinAgeHours", { 0, 4, 6, 12, 24, 48, 72 }, function(v) return v == 0 and "Immediately" or (tostring(v) .. " Hours Old") end, MPOptim.GetText("UI_MPOptim_Tooltip_Corpse_MinAgeHours", "Minimum age in in-game hours a zombie body must exist before it is eligible for cleanup."))
    addStepper(self.panelTab4, stepY4 + (3 * stepGap), MPOptim.GetText("UI_ModOptions_Corpse_CleanRadius", "Corpse Clean Radius"), "Corpse_CleanRadius", { 15, 20, 30, 40, 50, 60 }, function(v) return tostring(v) .. " Tiles" end, MPOptim.GetText("UI_MPOptim_Tooltip_Corpse_CleanRadius", "Distance in tiles around the player to check and clean corpses."))
    addStepper(self.panelTab4, stepY4 + (4 * stepGap), MPOptim.GetText("UI_ModOptions_Corpse_IntervalHours", "Corpse Sweep Interval"), "Corpse_IntervalHours", { 1, 2, 4, 6, 12, 24 }, function(v) return tostring(v) .. " Hours" end, MPOptim.GetText("UI_MPOptim_Tooltip_Corpse_IntervalHours", "In-game hours between automated zombie corpse sweeps."))
    makeScrollable(self.panelTab4, stepY4 + (5 * stepGap) + math.floor(35 * scale))

    -- ========================================================================
    -- TAB 5: WORLD DEBRIS SUB-PANEL
    -- ========================================================================
    self.panelTab5 = ISPanel:new(subX, subY, subW, subH)
    self.panelTab5:initialise()
    forwardFocus(self.panelTab5, self)
    self.panelTab5.backgroundColor = { r = 0.06, g = 0.08, b = 0.13, a = 1.0 }
    self.panelTab5.borderColor = { r = 0.18, g = 0.28, b = 0.44, a = 0.90 }
    self:addChild(self.panelTab5)

    addTick(self.panelTab5, startOptY + (0 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Debris_AutoClean", "Enable Ground Debris Auto-Cleanup"), "Debris_AutoClean", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Debris_AutoClean", "Enables scheduled periodic purging of ground trash and spent shell casings."))
    addTick(self.panelTab5, startOptY + (1 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Debris_CleanCasings", "Clean Spent Bullet Casings & Shells (Vanilla, Brita & VFE)"), "Debris_CleanCasings", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Debris_CleanCasings", "Cleans dropped spent bullet casings and shotgun shells after firefights."))
    addTick(self.panelTab5, startOptY + (2 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Debris_CleanTrash", "Clean Empty Cans, Pop Tins, Bottles, Ashes & Cigarette Butts"), "Debris_CleanTrash", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Debris_CleanTrash", "Removes discarded empty food cans, empty soda bottles, candy wrappers, and cigarette butts."))
    addTick(self.panelTab5, startOptY + (3 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Debris_CleanTwigsAndWood", "Clean Ground Twigs, Tree Branches & Loose Stones"), "Debris_CleanTwigsAndWood", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Debris_CleanTwigsAndWood", "Cleans fallen forest twigs and loose stones (Logs and log stacks are permanently protected)."))
    addTick(self.panelTab5, startOptY + (4 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Debris_CleanBrokenGlass", "Clean Broken Glass Shards on Ground"), "Debris_CleanBrokenGlass", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Debris_CleanBrokenGlass", "Cleans dangerous broken window glass shards on the floor to prevent tire punctures and lacerations."))
    addTick(self.panelTab5, startOptY + (5 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Debris_CleanRottenFood", "Clean Rotten & Expired Food on Ground (Default: Off)"), "Debris_CleanRottenFood", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Debris_CleanRottenFood", "Purges completely rotten expired food items left dropped on the ground to reduce save bloat."))

    local stepY5 = startOptY + (6 * self.tickSpacing) + math.floor(20 * scale)
    addStepper(self.panelTab5, stepY5 + (0 * stepGap), MPOptim.GetText("UI_ModOptions_Debris_CleanRadius", "Debris Clean Radius"), "Debris_CleanRadius", { 15, 25, 35, 45, 60, 75 }, function(v) return tostring(v) .. " Tiles" end, MPOptim.GetText("UI_MPOptim_Tooltip_Debris_CleanRadius", "Distance in tiles around the player to search for ground debris."))
    addStepper(self.panelTab5, stepY5 + (1 * stepGap), MPOptim.GetText("UI_ModOptions_Debris_IntervalHours", "Debris Sweep Interval"), "Debris_IntervalHours", { 2, 4, 8, 12, 24, 48 }, function(v) return tostring(v) .. " Hours" end, MPOptim.GetText("UI_MPOptim_Tooltip_Debris_IntervalHours", "In-game hours between ground clutter and trash cleanup sweeps."))
    makeScrollable(self.panelTab5, stepY5 + (2 * stepGap) + math.floor(35 * scale))

    -- ========================================================================
    -- TAB 6: AUDIO, CLIMATE & BASE PROTECTION
    -- ========================================================================
    self.panelTab6 = ISPanel:new(subX, subY, subW, subH)
    self.panelTab6:initialise()
    forwardFocus(self.panelTab6, self)
    self.panelTab6.backgroundColor = { r = 0.06, g = 0.08, b = 0.13, a = 1.0 }
    self.panelTab6.borderColor = { r = 0.18, g = 0.28, b = 0.44, a = 0.90 }
    self:addChild(self.panelTab6)

    addTick(self.panelTab6, startOptY + (0 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Weather_ClampRainParticles", "Clamp Rain & Splash Particle Pool (40 Objects)"), "Weather_ClampRainParticles", function(sel)
        if MPOptim.WeatherOptimizer and MPOptim.WeatherOptimizer.Update then MPOptim.WeatherOptimizer.Update() end
    end, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Weather_ClampRainParticles", "Caps active rain splash and streak particle object pool to 40 max to eliminate hundreds of draw calls during storms."))
    addTick(self.panelTab6, startOptY + (1 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Fire_ThrottleParticles", "Throttle Fire Smoke & Flame Vortex Particles"), "Fire_ThrottleParticles", function(sel)
        if MPOptim.FireOptimizer and MPOptim.FireOptimizer.Apply then MPOptim.FireOptimizer.Apply() end
    end, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Fire_ThrottleParticles", "Caps maximum active fire particles to 50 and vortices to 2 during large building and zombie fires."))
    addTick(self.panelTab6, startOptY + (2 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Animal_ThrottleDistant", "Distant Wildlife & Livestock Pen Throttling"), "Animal_ThrottleDistant", function(sel)
        if MPOptim.AnimalOptimizer and MPOptim.AnimalOptimizer.Update then MPOptim.AnimalOptimizer.Update() end
    end, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Animal_Optimize", "Caps simultaneous animal sound emitters in crowded livestock pens."))
    addTick(self.panelTab6, startOptY + (3 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Animal_Optimize", "Optimize Build 42 Animal Pens & Wildlife Audio Loops"), "Animal_Optimize", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Animal_Optimize", "Caps simultaneous animal sound emitters in crowded livestock pens."))
    addTick(self.panelTab6, startOptY + (4 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Animal_CleanTracks", "Purge Aged Build 42 Animal Footprints & Track Entities"), "Animal_CleanTracks", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Animal_CleanTracks", "Deletes distant animal track footprint entities outside tracking radius to save CPU and savefile size."))
    addTick(self.panelTab6, startOptY + (5 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Weather_Optimize", "Optimize Weather Particle Density & Volumetric Fog"), "Weather_Optimize", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Weather_Optimize", "Cuts rain particle density and fog shader overhead during heavy storms."))
    addTick(self.panelTab6, startOptY + (6 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Base_ProtectPlayerStructures", "Protect Player Structures (Barrels, Walls, Generators)"), "Base_ProtectPlayerStructures", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Base_ProtectPlayerStructures", "Shields player-built bases, water collector barrels, fuel cans, and generators from all sweeps."))
    addTick(self.panelTab6, startOptY + (7 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Admin_ProtectSafehouses", "Protect Claimed Safehouses in Multiplayer"), "Admin_ProtectSafehouses", nil, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Admin_ProtectSafehouses", "Guarantees that items and crates within claimed faction/player safehouses are strictly protected."))
    addTick(self.panelTab6, startOptY + (8 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Weather_PuddleOptimization", "Ground-Level Puddle Optimization (perfPuddles=2)"), "Weather_PuddleOptimization", function(sel)
        if MPOptim.WeatherOptimizer and MPOptim.WeatherOptimizer.Update then MPOptim.WeatherOptimizer.Update() end
    end, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Weather_PuddleOptimization", "Bypasses 8 adjacent tile queries on 10,000+ exterior squares while preserving full high-quality shader puddle reflections on roads."))
    addTick(self.panelTab6, startOptY + (9 * self.tickSpacing), MPOptim.GetText("UI_ModOptions_Weather_DisableTreeWind", "Disable Storm Tree Wind Sway (CPU Saver)"), "Weather_DisableTreeWind", function(sel)
        if MPOptim.WeatherOptimizer and MPOptim.WeatherOptimizer.Update then MPOptim.WeatherOptimizer.Update() end
    end, nil, nil, MPOptim.GetText("UI_MPOptim_Tooltip_Weather_DisableTreeWind", "Disables barycentric tree mesh sway distortion calculations during storms, preventing CPU stalls when speeding down forest highways."))

    local stepY6 = startOptY + (10 * self.tickSpacing) + math.floor(20 * scale)
    addStepper(self.panelTab6, stepY6 + (0 * stepGap), MPOptim.GetText("UI_ModOptions_Animal_MaxAudioEmitters", "Max Concurrent Animal Emitters"), "Animal_MaxAudioEmitters", { 2, 4, 6, 8, 12 }, function(v) return tostring(v) .. " Emitters" end, MPOptim.GetText("UI_MPOptim_Tooltip_Animal_MaxAudioEmitters", "Maximum allowed active animal audio emitters in an area."))
    addStepper(self.panelTab6, stepY6 + (1 * stepGap), MPOptim.GetText("UI_ModOptions_Fire_MaxEmitters", "Max Concurrent Fire Screams"), "Fire_MaxEmitters", { 4, 6, 8, 12, 16, 24 }, function(v) return tostring(v) .. " Screams" end, MPOptim.GetText("UI_MPOptim_Tooltip_Fire_MaxEmitters", "Caps overlapping burning zombie scream sound loops."))
    addStepper(self.panelTab6, stepY6 + (2 * stepGap), MPOptim.GetText("UI_ModOptions_Weather_MaxRainDensity", "Max Rain Particle Density"), "Weather_MaxRainDensity", { 0.40, 0.50, 0.60, 0.70, 0.85, 1.00 }, function(v) return string.format("%d%% Density", math.floor(v * 100)) end, MPOptim.GetText("UI_MPOptim_Tooltip_Weather_MaxRainDensity", "Maximum rain particle density limit during stormy weather."))
    addStepper(self.panelTab6, stepY6 + (3 * stepGap), MPOptim.GetText("UI_ModOptions_Admin_StaggerPerTick", "Micro-Batch Rate (Tiles / Tick)"), "Admin_StaggerPerTick", { 5, 10, 15, 20, 25, 35, 50 }, function(v) return tostring(v) .. " Tiles/Tick" end, MPOptim.GetText("UI_MPOptim_Tooltip_Admin_StaggerPerTick", "Number of tiles scanned per engine frame during background sweeps."))
    makeScrollable(self.panelTab6, stepY6 + (4 * stepGap) + math.floor(35 * scale))

    -- ========================================================================
    -- TAB 7: DEDICATED JVM ENGINE & HARDWARE OPTIMIZER SUITE
    -- ========================================================================
    self.panelTab7 = ISPanel:new(subX, subY, subW, subH)
    self.panelTab7:initialise()
    forwardFocus(self.panelTab7, self)
    self.panelTab7.backgroundColor = { r = 0.06, g = 0.08, b = 0.13, a = 1.0 }
    self.panelTab7.borderColor = { r = 0.18, g = 0.28, b = 0.44, a = 0.90 }
    self:addChild(self.panelTab7)

    local isJvmActive = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
    local ramGb = (MPOptim.Utils and MPOptim.Utils.GetOptimizedRAM and MPOptim.Utils.GetOptimizedRAM()) or 3
    local isHighRam = isJvmActive and (ramGb >= 6)

    -- Tab 7 Dynamic Header & Status Banner
    local jvmBannerH = math.max(75, math.floor(88 * scale))
    local jvmBanner = ISPanel:new(col1X, startOptY, subW - (col1X * 2), jvmBannerH)
    jvmBanner:initialise()
    jvmBanner.backgroundColor = isJvmActive and { r = 0.08, g = 0.22, b = 0.14, a = 0.95 } or { r = 0.22, g = 0.14, b = 0.06, a = 0.95 }
    jvmBanner.borderColor = isJvmActive and { r = 0.25, g = 0.85, b = 0.45, a = 1.0 } or { r = 0.85, g = 0.55, b = 0.20, a = 1.0 }
    self.panelTab7:addChild(jvmBanner)

    local statusTitle = isHighRam and ("[+] JVM HARDWARE ACCELERATION: ACTIVE (" .. tostring(ramGb) .. "GB HIGH-RAM MODE)") or (isJvmActive and ("[+] JVM HARDWARE ACCELERATION: ACTIVE (" .. tostring(ramGb) .. "GB BUDGET MODE)") or "[-] OPTIONAL JVM ENGINE SUITE: INACTIVE (Standard Lua Mode)")
    local stR, stG, stB = isJvmActive and 0.30 or 0.95, isJvmActive and 0.90 or 0.65, isJvmActive and 0.45 or 0.25
    local bannerTitleLbl = ISLabel:new(math.floor(16 * scale), math.floor(10 * scale), fontH, statusTitle, stR, stG, stB, 1.0, smallFont, true)
    bannerTitleLbl:initialise()
    jvmBanner:addChild(bannerTitleLbl)

    local statusDesc = isHighRam and "Uncapped Deep Chunk Caching, FastMath Raycasting, and Async Texture Preloading Active." or (isJvmActive and "Low-Latency G1GC & Async Compiling Active. Chunk caching auto-scaled for 4GB stability." or "The mod is 100% fully functional in Standard Mode. To optionally unlock 8GB-16GB RAM and background GC, install the optional PZO tool.")
    local bannerDescLbl = ISLabel:new(math.floor(16 * scale), math.floor(30 * scale), fontH, statusDesc, 0.85, 0.88, 0.95, 1.0, smallFont, true)
    bannerDescLbl:initialise()
    jvmBanner:addChild(bannerDescLbl)

    local jvmStatsLbl = ISLabel:new(math.floor(16 * scale), math.floor(48 * scale), fontH, "JVM Heap: " .. tostring(ramGb * 1024) .. " MB | GC Engine: Low-Latency G1GC | Threads: Multi-Threaded", 0.40, 0.85, 1.0, 1.0, smallFont, true)
    jvmStatsLbl:initialise()
    jvmBanner:addChild(jvmStatsLbl)

    if not isJvmActive then
        local getPzoBtn = ISButton:new(jvmBanner.width - math.floor(180 * scale) - math.floor(12 * scale), math.floor(22 * scale), math.floor(180 * scale), math.floor(36 * scale), "[*] Optional PZO Tool (GitHub)", self, function(s)
            if MPOptim.MainMenu and MPOptim.MainMenu.ShowEngineAgentModal then
                MPOptim.MainMenu.ShowEngineAgentModal()
            end
        end)
        getPzoBtn:initialise()
        getPzoBtn.backgroundColor = { r = 0.10, g = 0.30, b = 0.45, a = 0.95 }
        getPzoBtn.borderColor = { r = 0.30, g = 0.75, b = 1.0, a = 1.0 }
        jvmBanner:addChild(getPzoBtn)
    end

    -- Live Purge RAM Button when JVM is active
    if isJvmActive then
        local purgeJvmBtn = ISButton:new(jvmBanner.width - math.floor(190 * scale) - math.floor(12 * scale), math.floor(22 * scale), math.floor(190 * scale), math.floor(36 * scale), "[[!]] Force Clean JVM RAM", self, function(s)
            if type(PZOEngineBridge) == "table" and type(PZOEngineBridge.purgeRAM) == "function" then
                PZOEngineBridge.purgeRAM()
            end
            if collectgarbage then
                collectgarbage("collect")
            end
            local pObj = getPlayer and getPlayer()
            if pObj and MPOptim.Utils and MPOptim.Utils.Notify then
                MPOptim.Utils.Notify(pObj, "[!] JVM Heap & Native RAM Cache Purged.", true)
            end
        end)
        purgeJvmBtn:initialise()
        purgeJvmBtn.backgroundColor = { r = 0.12, g = 0.35, b = 0.22, a = 0.95 }
        purgeJvmBtn.borderColor = { r = 0.25, g = 0.85, b = 0.45, a = 1.0 }
        purgeJvmBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_JVM_PurgeRAM", "Immediately triggers a native JVM and Kahlua memory collection cycle to release unreferenced heap memory.")
        jvmBanner:addChild(purgeJvmBtn)
    end

    -- Tab 7 Controls Section
    local jvmControlsY = startOptY + jvmBannerH + math.floor(16 * scale)
    local jvmPrefix = isJvmActive and "[+] " or "[LOCKED] "
    local jvmTipLock = isJvmActive and "" or " (Optional: Requires external PZO installer for 8GB+ RAM. The rest of the mod is 100% functional without this)."

    -- Left Column (Slots 0 - 3)
    addTick(self.panelTab7, jvmControlsY + (0 * self.tickSpacing), jvmPrefix .. MPOptim.GetText("UI_ModOptions_JVM_ZeroStutterGC", "Zero-Stutter Background GC Mode"), "JVM_ZeroStutterGC", nil, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_JVM_ZeroStutterGC", "Eliminates in-game stop-the-world Lua garbage collection pauses during combat and driving by offloading memory management to background G1GC worker threads") .. jvmTipLock)

    addTick(self.panelTab7, jvmControlsY + (1 * self.tickSpacing), jvmPrefix .. MPOptim.GetText("UI_ModOptions_JVM_DeepChunkCache", "Deep RAM Chunk Cache (Zero Disk I/O Lag)"), "JVM_DeepChunkCache", nil, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_JVM_DeepChunkCache", "Keeps recently streamed road and town chunks cached in 8GB+ RAM to completely eliminate disk read stutters when turning around or retracing paths") .. jvmTipLock)

    addTick(self.panelTab7, jvmControlsY + (2 * self.tickSpacing), jvmPrefix .. MPOptim.GetText("UI_ModOptions_JVM_GLStateOptimizer", "OpenGL Uniform & Matrix Caching"), "JVM_GLStateOptimizer", nil, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_JVM_GLStateOptimizer", "Filters redundant shader uniform uploads (lighting, fog, ambient color) and 3D clothing bone matrices before sending them to the GPU driver. Boosts FPS in dense cities.") .. jvmTipLock)

    addTick(self.panelTab7, jvmControlsY + (3 * self.tickSpacing), jvmPrefix .. MPOptim.GetText("UI_ModOptions_JVM_PowerShield", "CPU Power & P-Core Priority Shield"), "JVM_PowerShield", nil, col1X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_JVM_PowerShield", "Locks Windows/Linux multimedia high-performance thread scheduling and prioritizes Performance Cores (P-Cores) over Efficiency Cores on Intel 12th-15th Gen and AMD X3D CPUs.") .. jvmTipLock)

    -- Right Column (Slots 0 - 3)
    addTick(self.panelTab7, jvmControlsY + (0 * self.tickSpacing), jvmPrefix .. MPOptim.GetText("UI_ModOptions_JVM_AsyncModelCompile", "Asynchronous 3D Model Compilation"), "JVM_AsyncModelCompile", nil, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_JVM_AsyncModelCompile", "Compiles character clothing, armor, and vehicle 3D textures across background CPU threads to eliminate equipment swap frame drops") .. jvmTipLock)

    addTick(self.panelTab7, jvmControlsY + (1 * self.tickSpacing), jvmPrefix .. MPOptim.GetText("UI_ModOptions_JVM_HordeHibernation", "Distant Horde Spatial Hibernation"), "JVM_HordeHibernation", nil, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_JVM_HordeHibernation", "Hibernates distant off-screen zombie pathfinding and animation state in RAM buffers to save massive CPU cycles in mega-horde territory") .. jvmTipLock)

    addTick(self.panelTab7, jvmControlsY + (2 * self.tickSpacing), jvmPrefix .. MPOptim.GetText("UI_ModOptions_JVM_KahluaGCPacer", "Kahlua Incremental Lua GC Pacing"), "JVM_KahluaGCPacer", nil, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_JVM_KahluaGCPacer", "Smoothly collects Lua garbage in 50-step increments every frame to prevent dead mod tables from accumulating and triggering 20-30ms stutter spikes during vehicle travel.") .. jvmTipLock)

    addTick(self.panelTab7, jvmControlsY + (3 * self.tickSpacing), jvmPrefix .. MPOptim.GetText("UI_ModOptions_JVM_StreamBufferBoost", "Direct NIO Vehicle Stream Buffers"), "JVM_StreamBufferBoost", nil, col2X, colW, MPOptim.GetText("UI_MPOptim_Tooltip_JVM_StreamBufferBoost", "Enables 128KB page-aligned direct NIO memory stream buffers and ChunkBufferPool for stutter-free road chunk loading at 70+ mph.") .. jvmTipLock)

    -- Attach click-interceptor for locked boxes to open modal when clicked
    if not isJvmActive then
        local jvmKeys = { "JVM_ZeroStutterGC", "JVM_DeepChunkCache", "JVM_GLStateOptimizer", "JVM_PowerShield", "JVM_AsyncModelCompile", "JVM_HordeHibernation", "JVM_KahluaGCPacer", "JVM_StreamBufferBoost" }
        for _, k in ipairs(jvmKeys) do
            local box = self.tickboxMap[k]
            if box then
                box.enable = false
                box:setSelected(1, false)
                local old_onMouseDown = box.onMouseDown
                box.onMouseDown = function(b, x, y)
                    if MPOptim.MainMenu and MPOptim.MainMenu.ShowEngineAgentModal then
                        MPOptim.MainMenu.ShowEngineAgentModal()
                    end
                    return false
                end
            end
        end
    end

    -- Advanced Steppers Section (Tab 7)
    local stepY7 = jvmControlsY + (4 * self.tickSpacing) + math.floor(14 * scale)
    addStepper(self.panelTab7, stepY7 + (0 * stepGap), "Deep Chunk RAM Cache Size", "JVM_ChunkCacheSize", { 250, 500, 750, 1000, 1500 }, function(v) return tostring(v) .. " Chunks" end, "Number of world chunks retained in RAM cache for instant zero-lag road streaming.")
    addStepper(self.panelTab7, stepY7 + (1 * stepGap), "JVM Heap Clean Threshold", "JVM_GCThresholdMB", { 4000, 6000, 8000, 10000, 12000 }, function(v) return tostring(v) .. " MB" end, "Target memory threshold before gentle background GC sweeps cycle.")
    makeScrollable(self.panelTab7, stepY7 + (2 * stepGap) + math.floor(35 * scale))

    -- ========================================================================
    -- TAB 8: MOD RESOURCE USAGE & PROFILER
    -- ========================================================================
    self.panelTab8 = ISPanel:new(subX, subY, subW, subH)
    self.panelTab8:initialise()
    forwardFocus(self.panelTab8, self)
    self.panelTab8.backgroundColor = { r = 0.06, g = 0.08, b = 0.13, a = 1.0 }
    self.panelTab8.borderColor = { r = 0.18, g = 0.28, b = 0.44, a = 0.90 }
    self:addChild(self.panelTab8)

    local profilerLeftW = math.floor(subW * 0.48)
    local profilerListY = math.floor(48 * scale)
    local profilerListH = subH - profilerListY - math.floor(16 * scale)

    self.modListBox = ISScrollingListBox:new(math.floor(16 * scale), profilerListY, profilerLeftW, profilerListH)
    self.modListBox:initialise()
    self.modListBox:instantiate()
    self.modListBox.itemheight = math.max(34, math.floor(fontH + 18 * scale))
    self.modListBox.selected = 1
    self.modListBox.backgroundColor = { r = 0.04, g = 0.06, b = 0.09, a = 0.95 }
    self.modListBox.borderColor = { r = 0.20, g = 0.35, b = 0.55, a = 0.90 }

    self.modListBox.doDrawItem = function(list, y, item, alt)
        if list.selected == item.index then
            list:drawRect(0, y, list:getWidth(), item.height - 1, 0.30, 0.20, 0.50, 0.85)
        elseif alt then
            list:drawRect(0, y, list:getWidth(), item.height - 1, 0.10, 1.0, 1.0, 1.0)
        end
        list:drawRectBorder(0, y, list:getWidth(), item.height, 0.25, 0.20, 0.30, 0.45)

        local data = item.item
        local memKb = math.floor(data.estimatedBytes / 1024)
        local memStr = (memKb > 1024) and string.format("%.1f MB", memKb / 1024) or string.format("%d KB", memKb)

        local ratingColor = { r = 0.40, g = 0.95, b = 0.45 }
        if data.rating == "MODERATE" then
            ratingColor = { r = 0.95, g = 0.85, b = 0.35 }
        elseif data.rating == "HEAVY" then
            ratingColor = { r = 0.95, g = 0.50, b = 0.20 }
        elseif data.rating == "INTENSIVE" then
            ratingColor = { r = 0.95, g = 0.25, b = 0.25 }
        end

        local textY = y + math.floor((item.height - fontH) / 2)
        list:drawText(data.name, math.floor(10 * scale), textY, 0.92, 0.92, 0.92, 1.0, smallFont)
        list:drawText("[" .. data.rating .. "]", list:getWidth() - math.floor(150 * scale), textY, ratingColor.r, ratingColor.g, ratingColor.b, 1.0, smallFont)
        list:drawText(memStr, list:getWidth() - math.floor(70 * scale), textY, 0.70, 0.85, 1.0, 1.0, smallFont)

        return y + item.height
    end

    self.modListBox.onMouseDown = function(list, x, y)
        local row = list:rowAt(x, y)
        if row > 0 and row <= #list.items then
            list.selected = row
            self.selectedModData = list.items[row].item
        end
    end

    self.panelTab8:addChild(self.modListBox)

    -- Refresh Profiler Button
    local reScanBtnW = math.floor(170 * scale)
    local reScanBtnH = math.max(28, math.floor(fontH + 10 * scale))
    self.reScanBtn = ISButton:new(math.floor(16 * scale), math.floor(12 * scale), reScanBtnW, reScanBtnH, "[*] Re-Scan Mod Memory", self, function(s)
        s:refreshModProfiler()
    end)
    self.reScanBtn:initialise()
    self.reScanBtn.backgroundColor = { r = 0.12, g = 0.25, b = 0.40, a = 0.95 }
    self.reScanBtn.borderColor = { r = 0.25, g = 0.60, b = 0.95, a = 1.0 }
    self.reScanBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_ReScanProfiler", "Scans the active Lua VM to measure memory tables and active event hooks for all mods.")
    self.panelTab8:addChild(self.reScanBtn)

    -- Tab 7 Details Card Render
    self.panelTab8.render = function(p)
        if not p:isVisible() or not p.parent or p.parent.currentTab ~= 8 then return end
        ISPanel.render(p)

        local font = (UIFont and UIFont.Small) or 0
        local medFont = (UIFont and UIFont.Medium) or 0
        local sc, fH = MPOptim.Utils.GetUIScale()
        local lineH = math.max(22, math.floor(fH + 8 * sc))

        -- Header text
        local profSummary = (self.profilerData and string.format("Active Mods: %d | Total Estimated Memory: %.1f MB", self.profilerData.totalMods, self.profilerData.totalMemoryMB)) or "Scanning..."
        p:drawText(profSummary, math.floor(200 * sc), math.floor(16 * sc), 0.35, 0.85, 1.0, 1.0, font)

        -- Right Details Card
        local cardX = math.floor(16 * sc) + profilerLeftW + math.floor(16 * sc)
        local cardY = profilerListY
        local cardW = p.width - cardX - math.floor(16 * sc)
        local cardH = profilerListH

        p:drawRect(cardX, cardY, cardW, cardH, 0.70, 0.05, 0.07, 0.11)
        p:drawRectBorder(cardX, cardY, cardW, cardH, 0.85, 0.22, 0.38, 0.60)
        p:drawRect(cardX + 1, cardY + 1, cardW - 2, 2, 0.95, 0.20, 0.75, 1.0)

        local pad = math.floor(16 * sc)
        local currY = cardY + pad

        local mod = self.selectedModData
        if not mod then
            p:drawText("Select a mod on the left to inspect its resource usage.", cardX + pad, currY, 0.70, 0.70, 0.70, 1.0, font)
            return
        end

        p:drawText(mod.name, cardX + pad, currY, 0.40, 0.85, 1.0, 1.0, medFont)
        currY = currY + lineH + math.floor(6 * sc)

        local memKb = math.floor(mod.estimatedBytes / 1024)
        local memStr = (memKb > 1024) and string.format("%.2f MB", memKb / 1024) or string.format("%d KB", memKb)

        local detailLines = {
            "Mod ID: " .. tostring(mod.id),
            "Author: " .. tostring(mod.author),
            "Version: " .. tostring(mod.version),
            "Lua Memory Footprint: " .. memStr,
            "Engine Event Hooks: " .. tostring(mod.hookCount) .. " active listeners",
            "Performance Rating: [" .. tostring(mod.rating) .. "]"
        }

        for _, line in ipairs(detailLines) do
            p:drawText(line, cardX + pad, currY, 0.90, 0.90, 0.90, 1.0, font)
            currY = currY + lineH
        end
    end


    -- ========================================================================
    -- Bottom Bar: Reset Defaults & Save Buttons
    -- ========================================================================
    local bBtnH = math.max(34, math.floor(fontH + 16 * scale))
    local bBtnW = math.floor(180 * scale)
    local bBtnY = winH - bBtnH - math.floor(14 * scale)

    self.resetBtn = ISButton:new(tabMargin, bBtnY, bBtnW, bBtnH, MPOptim.GetText("UI_MPOptim_Reset", "Reset Defaults"), self, function(s)
        if MPOptim.Config and MPOptim.Config.ResetDefaults then
            MPOptim.Config.ResetDefaults()
            s:refreshAllControls()
            if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then
                MPOptim.HordeOptimizer.Apply()
            end
            local player = getPlayer and getPlayer()
            if player and MPOptim.Utils and MPOptim.Utils.Notify then
                MPOptim.Utils.Notify(player, "Restored Factory Optimization Defaults", true)
            end
        end
    end)
    self.resetBtn:initialise()
    self.resetBtn.backgroundColor = { r = 0.22, g = 0.12, b = 0.12, a = 0.95 }
    self.resetBtn.borderColor = { r = 0.60, g = 0.25, b = 0.25, a = 0.95 }
    self.resetBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_ResetBtn", "Resets all configuration values to factory balanced defaults.")
    self:addChild(self.resetBtn)

    self.saveBtn = ISButton:new(winW - tabMargin - bBtnW, bBtnY, bBtnW, bBtnH, MPOptim.GetText("UI_MPOptim_Save", "Save Settings"), self, function(s)
        if MPOptim.Config and MPOptim.Config.Save then
            MPOptim.Config.Save()
            if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then
                MPOptim.HordeOptimizer.Apply()
            end
            local player = getPlayer and getPlayer()
            if player and MPOptim.Utils and MPOptim.Utils.Notify then
                MPOptim.Utils.Notify(player, "Optimiser Settings Saved", true)
            end
        end
        s:setVisible(false)
    end)
    self.saveBtn:initialise()
    self.saveBtn.backgroundColor = { r = 0.12, g = 0.40, b = 0.25, a = 0.98 }
    self.saveBtn.borderColor = { r = 0.25, g = 0.75, b = 0.45, a = 1.0 }
    self.saveBtn.tooltip = MPOptim.GetText("UI_MPOptim_Tooltip_SaveBtn", "Saves your configuration to disk and closes the Optimiser Control Center.")
    self:addChild(self.saveBtn)

    self:updateDependencies()
    self:setTab(1)
end

function MPOptim_SettingsUI:refreshModProfiler()
    if not MPOptim.ModProfiler or not self.modListBox then return end
    self.modListBox:clear()

    local pData = MPOptim.ModProfiler.Scan()
    self.profilerData = pData

    if pData and pData.mods then
        for idx, mod in ipairs(pData.mods) do
            if mod and mod.name then
                self.modListBox:addItem(mod.name, mod)
            end
        end

        if #pData.mods > 0 then
            self.modListBox.selected = 1
            self.selectedModData = pData.mods[1]
        end
    end
end

local function setPanelVisibleRecursive(panel, isVis)
    if not panel then return end
    panel:setVisible(isVis)
    if panel.getChildren then
        local children = panel:getChildren()
        if children then
            for _, child in pairs(children) do
                if child and child.setVisible then
                    child:setVisible(isVis)
                end
            end
        end
    end
end

function MPOptim_SettingsUI:setTab(tabIdx)
    self.currentTab = tabIdx
    local activeColor = { r = 0.18, g = 0.38, b = 0.65, a = 1.0 }
    local inactiveColor = { r = 0.10, g = 0.14, b = 0.22, a = 0.85 }

    local tabs = { self.tab1Btn, self.tab2Btn, self.tab3Btn, self.tab4Btn, self.tab5Btn, self.tab6Btn, self.tab7Btn, self.tab8Btn }
    local panels = { self.panelTab1, self.panelTab2, self.panelTab3, self.panelTab4, self.panelTab5, self.panelTab6, self.panelTab7, self.panelTab8 }

    for i, btn in ipairs(tabs) do
        if i == tabIdx then
            btn.backgroundColor = activeColor
            btn.borderColor = { r = 0.40, g = 0.70, b = 1.0, a = 1.0 }
        else
            btn.backgroundColor = inactiveColor
            btn.borderColor = { r = 0.20, g = 0.30, b = 0.45, a = 0.80 }
        end
    end

    for i, panel in ipairs(panels) do
        setPanelVisibleRecursive(panel, i == tabIdx)
    end

    if tabIdx == 1 and self.updateAdminPermissions then
        self:updateAdminPermissions()
    end

    if tabIdx == 8 and (not self.profilerData or #self.modListBox.items == 0) then
        self:refreshModProfiler()
    end
end

function MPOptim_SettingsUI:updateDependencies()
    local function isTick(key)
        return (MPOptim.Config and MPOptim.Config.Get(key)) == true
    end

    local function setBoxEnable(key, enable)
        local box = self.tickboxMap[key]
        if box then
            box.enable = (enable == true)
        end
    end

    local function setStepEnable(key, enable)
        local step = self.stepperMap[key]
        if step and step.setEnable then
            step.setEnable(enable == true)
        end
    end

    -- Tab 2 Dependencies (With Strict Parent-Child Locking)
    local vehMaster = isTick("Vehicle_ChunkPriorityMode")
    setStepEnable("Vehicle_SpeedThreshold", vehMaster)
    setBoxEnable("Vehicle_LimitDriveZoom", vehMaster)
    setBoxEnable("Vehicle_PreDrivePurge", vehMaster)
    setBoxEnable("Vehicle_ScaleLightingFPS", vehMaster)
    setBoxEnable("Vehicle_ThrottleRoadsideZombies", vehMaster)
    setBoxEnable("Vehicle_BoostImposterDistance", vehMaster)
    setBoxEnable("Vehicle_SuspendBackgroundCleanups", vehMaster)
    setBoxEnable("Vehicle_ThreadedModelSlots", vehMaster)

    local smartGC = isTick("GC_SmartIdleGC")
    setStepEnable("GC_PurgeThresholdMB", smartGC)

    local threadLight = (MPOptim.Config and MPOptim.Config.Get("Threaded_Lighting")) ~= false
    setStepEnable("Lighting_FPS", threadLight)

    -- Tab 3 Blood & Corpse Dependencies
    local bloodAuto = isTick("Blood_AutoClean")
    setBoxEnable("Blood_RemoveWall", bloodAuto)
    setStepEnable("Blood_CleanRadius", bloodAuto)
    setStepEnable("Blood_IntervalHours", bloodAuto)

    local corpseAuto = isTick("Corpse_AutoClean")
    setBoxEnable("Corpse_CleanEmptyOnly", corpseAuto)
    setBoxEnable("Corpse_CleanJunkOnly", corpseAuto)
    setStepEnable("Corpse_MinAgeHours", corpseAuto)
    setStepEnable("Corpse_CleanRadius", corpseAuto)

    -- Tab 4 Debris Dependencies
    local debrisAuto = isTick("Debris_AutoClean")
    setBoxEnable("Debris_CleanCasings", debrisAuto)
    setBoxEnable("Debris_CleanTrash", debrisAuto)
    setBoxEnable("Debris_CleanTwigsAndWood", debrisAuto)
    setBoxEnable("Debris_CleanBrokenGlass", debrisAuto)
    setBoxEnable("Debris_CleanRottenFood", debrisAuto)
    setStepEnable("Debris_CleanRadius", debrisAuto)
    setStepEnable("Debris_IntervalHours", debrisAuto)

    -- Tab 5 Audio & Climate Dependencies
    local animalOpt = isTick("Animal_Optimize")
    setStepEnable("Animal_MaxAudioEmitters", animalOpt)

    local fireOpt = isTick("Fire_Optimize") or isTick("Fire_ThrottleParticles")
    setStepEnable("Fire_MaxEmitters", fireOpt)

    local weatherOpt = isTick("Weather_Optimize")
    setStepEnable("Weather_MaxRainDensity", weatherOpt)

    -- Tab 7 JVM Hardware Extensions Locking
    local isJvmActive = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
    local jvmKeys = { "JVM_ZeroStutterGC", "JVM_DeepChunkCache", "JVM_AsyncModelCompile", "JVM_HordeHibernation" }
    for _, k in ipairs(jvmKeys) do
        setBoxEnable(k, isJvmActive == true)
        if not isJvmActive then
            local box = self.tickboxMap[k]
            if box then
                box.enable = false
                box:setSelected(1, false)
            end
        end
    end
    setStepEnable("JVM_ChunkCacheSize", isJvmActive == true)
    setStepEnable("JVM_GCThresholdMB", isJvmActive == true)
end

function MPOptim_SettingsUI:refreshAllControls()
    for _, t in ipairs(self.tickboxes) do
        local val = (MPOptim.Config and MPOptim.Config.Get(t.key)) or false
        t.box:setSelected(1, val)
    end
    for _, s in ipairs(self.steppers) do
        s.update()
    end
    self:updateDependencies()
    if self.currentTab == 7 then
        self:refreshModProfiler()
    end
end

function MPOptim_SettingsUI:render()
    ISPanel.render(self)
    local medFont = (UIFont and UIFont.Medium) or 0
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local titleText = MPOptim.GetText("UI_MPOptim_Title", "Project Zomboid Optimiser")
    self:drawText(titleText, math.floor(20 * scale), math.floor(10 * scale), 0.30, 0.85, 1.0, 1.0, medFont)
    self:drawRect(0, self.titleH, self.width, 2, 0.95, 0.22, 0.36, 0.58)
end

function MPOptim_SettingsUI:onMouseWheel(del)
    local activePanel = nil
    if self.currentTab == 2 then activePanel = self.panelTab2
    elseif self.currentTab == 3 then activePanel = self.panelTab3
    elseif self.currentTab == 4 then activePanel = self.panelTab4
    elseif self.currentTab == 5 then activePanel = self.panelTab5
    elseif self.currentTab == 6 then activePanel = self.panelTab6
    end
    if activePanel and activePanel.setYScroll and activePanel.getYScroll then
        activePanel:setYScroll(activePanel:getYScroll() - (del * 40))
        return true
    end
    return false
end

function MPOptim.OpenSettingsUI(forceRebuild)
    local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
    local winW = math.min(sw - 40, math.max(820, math.floor(960 * scale)))
    local winH = math.min(sh - 40, math.max(620, math.floor(720 * scale)))
    local winX = math.floor((sw - winW) / 2)
    local winY = math.floor((sh - winH) / 2)

    local mainScreen = MainScreen and MainScreen.instance
    local inWorld = (getPlayer and getPlayer()) ~= nil

    local inWorld = (getPlayer and getPlayer()) ~= nil
    local isMP = isClient and isClient()
    local player = inWorld and getPlayer()
    local isMPAdmin = inWorld and isMP and MPOptim.Utils and MPOptim.Utils.IsAdmin and MPOptim.Utils.IsAdmin(player)
    local currentDevMode = (MPOptim.DevMode == true)

    if settingsInstance and (forceRebuild or settingsInstance._builtWithDevMode ~= currentDevMode or settingsInstance._builtWithMPAdmin ~= isMPAdmin) then
        settingsInstance:setVisible(false)
        if settingsInstance:getParent() then
            settingsInstance:getParent():removeChild(settingsInstance)
        else
            settingsInstance:removeFromUIManager()
        end
        settingsInstance = nil
    end

    if not inWorld and mainScreen then
        -- Main Menu Hierarchy Mode (Child of MainScreen)
        if not settingsInstance then
            settingsInstance = MPOptim_SettingsUI:new(winX, winY, winW, winH)
            settingsInstance._builtWithDevMode = currentDevMode
            settingsInstance._builtWithMPAdmin = isMPAdmin
            settingsInstance:initialise()
            mainScreen:addChild(settingsInstance)
        else
            if settingsInstance:getParent() ~= mainScreen then
                if settingsInstance:getParent() then
                    settingsInstance:getParent():removeChild(settingsInstance)
                else
                    settingsInstance:removeFromUIManager()
                end
                mainScreen:addChild(settingsInstance)
            end
            settingsInstance:setX(winX)
            settingsInstance:setY(winY)
            settingsInstance:refreshAllControls()
            settingsInstance:setVisible(true)
        end
    else
        -- In-World HUD Mode (Top-level UIManager)
        if not settingsInstance then
            settingsInstance = MPOptim_SettingsUI:new(winX, winY, winW, winH)
            settingsInstance._builtWithDevMode = currentDevMode
            settingsInstance._builtWithMPAdmin = isMPAdmin
            settingsInstance:initialise()
            settingsInstance:addToUIManager()
        else
            if settingsInstance:getParent() then
                settingsInstance:getParent():removeChild(settingsInstance)
                settingsInstance:addToUIManager()
            end
            settingsInstance:setX(winX)
            settingsInstance:setY(winY)
            settingsInstance:refreshAllControls()
            settingsInstance:setVisible(true)
            if UIManager and UIManager.getUI and not UIManager.getUI():contains(settingsInstance) then
                settingsInstance:addToUIManager()
            end
        end
    end

    if settingsInstance and settingsInstance.bringToTop then
        settingsInstance:bringToTop()
    end
end

function MPOptim.ToggleSettingsUI()
    if settingsInstance and settingsInstance:isVisible() then
        settingsInstance:setVisible(false)
    else
        MPOptim.OpenSettingsUI()
    end
end

Events.OnKeyPressed.Add(function(key)
    local hotkey = (MPOptim.Config and MPOptim.Config.Get("UI_Hotkey")) or 68 -- Default F10
    if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.getOptions then
        local opt = PZAPI.ModOptions:getOptions("MPOptimizer")
        if opt and opt.getOption then
            local o = opt:getOption("OptimizerHotkey")
            if o and o.key and o.key > 0 then
                hotkey = o.key
            end
        end
    end

    if Core and Core.getInstance and Core.getInstance().isDoingTextEntry and Core.getInstance():isDoingTextEntry() then
        return
    end

    if key == hotkey then
        MPOptim.ToggleSettingsUI()
    end
end)
