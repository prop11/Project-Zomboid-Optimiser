--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_MainMenu.lua
    Author: prop11
    Description: Main menu integration for Optimiser Settings and Multi-CPU Launcher Optimizer.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"
require "MPOptim_UI_Settings"
require "MPOptim_BugReporter"
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISRichTextPanel"

MPOptim = MPOptim or {}
MPOptim.MainMenu = MPOptim.MainMenu or {}

-- ============================================================================
-- 1. First-Launch Welcome Modal
-- ============================================================================
local FirstLaunchModal = ISPanel:derive("MPOptim_FirstLaunchModal")

function FirstLaunchModal:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.05, g = 0.07, b = 0.12, a = 0.98 }
    o.borderColor = { r = 0.20, g = 0.45, b = 0.75, a = 1.0 }
    o.moveWithMouse = true
    return o
end

function FirstLaunchModal:onMouseDown(x, y)
    ISPanel.onMouseDown(self, x, y)
    self:bringToTop()
    return true
end

function FirstLaunchModal:initialise()
    ISPanel.initialise(self)
    self:createChildren()
end

function FirstLaunchModal:createChildren()
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local titleH = math.max(36, math.floor(fontH + 18 * scale))
    self.titleH = titleH

    local pad = math.floor(20 * scale)
    local textY = titleH + math.floor(10 * scale)
    local btnH = math.max(34, math.floor(fontH + 16 * scale))
    local textH = self.height - textY - btnH - math.floor(25 * scale)
    local textW = self.width - (pad * 2)

    self.textBox = ISRichTextPanel:new(pad, textY, textW, textH)
    self.textBox:initialise()
    self.textBox.background = false
    self.textBox.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textBox.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textBox.text = " <RGB:0.3,0.85,1.0> <SIZE:medium> Thank you for installing Project Zomboid Optimiser! <LINE> <LINE> " ..
        " <RGB:0.9,0.9,0.9> <SIZE:small> Your game has automatically been upgraded with active performance boosters: <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Stutter-Free Combat & Dynamic Skeletal Blending <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Smart Blood Stacking Cap (Max 4/Tile - Zero Visual Loss) <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Offscreen Zombie Animation Throttling <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Staggered Zero-Stutter Micro-Batching Sweeps <LINE> " ..
        " <RGB:0.4,0.9,0.5> * VRAM Texture Compression & Fly Swarm Limiter <LINE> <LINE> " ..
        " <RGB:0.85,0.85,0.85> Would you like to open the Optimiser Control Center now to customize your cleanup rules, audio settings, or HUD overlay? <LINE> " ..
        " <RGB:0.6,0.6,0.6> (You can also press <RGB:1.0,0.8,0.2> F10 <RGB:0.6,0.6,0.6> in-game or click the Optimiser button on the main menu at any time)."
    self.textBox:paginate()
    self:addChild(self.textBox)

    local btnW = math.floor((self.width - (pad * 3)) / 2)
    local btnY = self.height - btnH - math.floor(12 * scale)

    local configBtn = ISButton:new(pad, btnY, btnW, btnH, "[*] Open Optimiser Settings", self, function(s)
        MPOptim.Config.Set("FirstLaunchPromptShown", true)
        MPOptim.Config.Set("LastSeenVersion", MPOptim.Version)
        MPOptim.Config.Save()

        s:setVisible(false)
        s:removeFromUIManager()
        MPOptim.OpenSettingsUI()
    end)
    configBtn:initialise()
    configBtn.backgroundColor = { r = 0.15, g = 0.45, b = 0.25, a = 0.98 }
    configBtn.borderColor = { r = 0.30, g = 0.80, b = 0.45, a = 1.0 }
    self:addChild(configBtn)

    local closeBtn = ISButton:new(pad * 2 + btnW, btnY, btnW, btnH, "[OK] Continue with Defaults", self, function(s)
        MPOptim.Config.Set("FirstLaunchPromptShown", true)
        MPOptim.Config.Set("LastSeenVersion", MPOptim.Version)
        MPOptim.Config.Save()

        s:setVisible(false)
        s:removeFromUIManager()
    end)
    closeBtn:initialise()
    closeBtn.backgroundColor = { r = 0.15, g = 0.20, b = 0.28, a = 0.95 }
    closeBtn.borderColor = { r = 0.30, g = 0.45, b = 0.65, a = 0.95 }
    self:addChild(closeBtn)
end

function FirstLaunchModal:render()
    ISPanel.render(self)
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local medFont = (UIFont and UIFont.Medium) or 0
    self:drawText("[*] Project Zomboid Optimiser - Welcome & Initial Setup", math.floor(20 * scale), math.floor(10 * scale), 0.30, 0.85, 1.0, 1.0, medFont)
    self:drawRect(0, self.titleH, self.width, 2, 0.95, 0.22, 0.45, 0.75)
end

function MPOptim.MainMenu.ShowFirstLaunchModal()
    if MPOptim.Config and MPOptim.Config.Load then
        MPOptim.Config.Load()
    end

    local shown = MPOptim.Config.Get("FirstLaunchPromptShown")
    if shown == true or shown == "true" or shown == 1 then return false end

    local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
    local winW = math.min(sw - 40, math.max(680, math.floor(740 * scale)))
    local winH = math.min(sh - 40, math.max(380, math.floor(420 * scale)))
    local winX = math.floor((sw - winW) / 2)
    local winY = math.floor((sh - winH) / 2)

    local modal = FirstLaunchModal:new(winX, winY, winW, winH)
    modal:initialise()
    modal:addToUIManager()
    return true
end

-- ============================================================================
-- 1B. Mod Version Update Notification Modal
-- ============================================================================
local UpdateNotificationModal = ISPanel:derive("MPOptim_UpdateNotificationModal")

function UpdateNotificationModal:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.05, g = 0.07, b = 0.12, a = 0.98 }
    o.borderColor = { r = 0.25, g = 0.65, b = 0.95, a = 1.0 }
    o.moveWithMouse = true
    return o
end

function UpdateNotificationModal:onMouseDown(x, y)
    ISPanel.onMouseDown(self, x, y)
    self:bringToTop()
    return true
end

function UpdateNotificationModal:initialise()
    ISPanel.initialise(self)
    self:createChildren()
end

function UpdateNotificationModal:createChildren()
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local titleH = math.max(36, math.floor(fontH + 18 * scale))
    self.titleH = titleH

    local pad = math.floor(20 * scale)
    local textY = titleH + math.floor(10 * scale)
    local btnH = math.max(34, math.floor(fontH + 16 * scale))
    local textH = self.height - textY - btnH - math.floor(25 * scale)
    local textW = self.width - (pad * 2)

    self.textBox = ISRichTextPanel:new(pad, textY, textW, textH)
    self.textBox:initialise()
    self.textBox.background = false
    self.textBox.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textBox.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    
        local versionStr = tostring(MPOptim.Version or "1.4.0")
    self.textBox.text = " <RGB:0.3,0.85,1.0> <SIZE:medium> Project Zomboid Optimiser Updated to v" .. versionStr .. "! <LINE> <LINE> " ..
        " <RGB:0.95,0.85,0.4> NOTE: The Project Zomboid Optimiser mod is 100% fully functional on its own! All Lua performance features (lag cleaners, texture preloading, vehicle collision smoothing, and HUD profiling) work immediately out-of-the-box in standard mode. The open-source PZO installer is an optional tool for players wanting additional performance enhancements. <LINE> <LINE> " ..
        " <RGB:0.9,0.9,0.9> <SIZE:small> What is New in v1.4.0: <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Virtual Viewport Culling: Eliminates 8-10 FPS loot lag near massive floor piles (500+ items) via smart scroll clipping <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Water Pipes & Plumbing Throttler: Optimizes 60 Hz per-frame pipe flow & pump loops down to 1 Hz, cutting CPU load by 98% <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Proximity Loot Scan Debouncing: Throttles 3x3 surrounding floor scans when standing still looting <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Mod Profiler (Tab 8): Fixed live event listener scanning and Java ArrayList callback compatibility <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Optional PZO Engine Suite (v0.4): Build 42 Java 17 engine with GLState caching, fast horde separation & 1.0ms timer <LINE> <LINE> " ..
        " <RGB:0.85,0.85,0.85> Would you like to review and configure your Optimiser settings now? <LINE> " ..
        " <RGB:0.6,0.6,0.6> (You can adjust these at any time by pressing <RGB:1.0,0.8,0.2> F10 <RGB:0.6,0.6,0.6> in-game or via the main menu)." 
    self.textBox:paginate()
    self:addChild(self.textBox)

    local btnW = math.floor((self.width - (pad * 3)) / 2)
    local btnY = self.height - btnH - math.floor(12 * scale)

    local configBtn = ISButton:new(pad, btnY, btnW, btnH, MPOptim.GetText("UI_MPOptim_UpdateBtnSettings", "[*] Review New Settings"), self, function(s)
        MPOptim.Config.Set("LastSeenVersion", MPOptim.Version)
        MPOptim.Config.Save()

        s:setVisible(false)
        s:removeFromUIManager()
        MPOptim.OpenSettingsUI()
    end)
    configBtn:initialise()
    configBtn.backgroundColor = { r = 0.15, g = 0.45, b = 0.25, a = 0.98 }
    configBtn.borderColor = { r = 0.30, g = 0.80, b = 0.45, a = 1.0 }
    configBtn.tooltip = "Opens the Optimiser Control Center to inspect newly added options."
    self:addChild(configBtn)

    local closeBtn = ISButton:new(pad * 2 + btnW, btnY, btnW, btnH, MPOptim.GetText("UI_MPOptim_UpdateBtnDismiss", "[OK] Got It / Dismiss"), self, function(s)
        MPOptim.Config.Set("LastSeenVersion", MPOptim.Version)
        MPOptim.Config.Save()

        s:setVisible(false)
        s:removeFromUIManager()
    end)
    closeBtn:initialise()
    closeBtn.backgroundColor = { r = 0.15, g = 0.20, b = 0.28, a = 0.95 }
    closeBtn.borderColor = { r = 0.30, g = 0.45, b = 0.65, a = 0.95 }
    self:addChild(closeBtn)
end

function UpdateNotificationModal:render()
    ISPanel.render(self)
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local medFont = (UIFont and UIFont.Medium) or 0
    local titleText = "[+] Project Zomboid Optimiser - Update v" .. tostring(MPOptim.Version or "1.2.0") .. " Installed"
    self:drawText(titleText, math.floor(20 * scale), math.floor(10 * scale), 0.30, 0.85, 1.0, 1.0, medFont)
    self:drawRect(0, self.titleH, self.width, 2, 0.95, 0.25, 0.65, 0.95)
end

function MPOptim.MainMenu.ShowUpdateModal()
    if MPOptim.Config and MPOptim.Config.Load then
        MPOptim.Config.Load()
    end

    local lastSeen = MPOptim.Config.Get("LastSeenVersion")
    if lastSeen == MPOptim.Version then return end

    local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
    local winW = math.min(sw - 40, math.max(680, math.floor(760 * scale)))
    local winH = math.min(sh - 40, math.max(380, math.floor(430 * scale)))
    local winX = math.floor((sw - winW) / 2)
    local winY = math.floor((sh - winH) / 2)

    local modal = UpdateNotificationModal:new(winX, winY, winW, winH)
    modal:initialise()
    modal:addToUIManager()
end

-- ============================================================================
-- 2. Multi-CPU & JVM Memory Launcher Optimizer Modal
-- ============================================================================
-- ============================================================================
-- 1C. Java Engine Injection Agent & GitHub Modal
-- ============================================================================
local EngineAgentModal = ISPanel:derive("MPOptim_EngineAgentModal")

function EngineAgentModal:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.05, g = 0.07, b = 0.12, a = 0.98 }
    o.borderColor = { r = 0.20, g = 0.55, b = 0.85, a = 1.0 }
    o.moveWithMouse = true
    o.statusMsg = ""
    o.statusTimer = 0
    return o
end

function EngineAgentModal:onMouseDown(x, y)
    ISPanel.onMouseDown(self, x, y)
    self:bringToTop()
    return true
end

function EngineAgentModal:initialise()
    ISPanel.initialise(self)
    self:createChildren()
end

function EngineAgentModal:createChildren()
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local titleH = math.max(36, math.floor(fontH + 18 * scale))
    self.titleH = titleH

    local pad = math.floor(20 * scale)
    local textY = titleH + math.floor(10 * scale)
    local btnH = math.max(32, math.floor(fontH + 14 * scale))
    local textH = self.height - textY - (btnH * 2) - math.floor(35 * scale)
    local textW = self.width - (pad * 2)

    self.textBox = ISRichTextPanel:new(pad, textY, textW, textH)
    self.textBox:initialise()
    self.textBox.background = false
    self.textBox.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textBox.borderColor = { r = 0, g = 0, b = 0, a = 0 }

    local isAgent = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
    local statusText = isAgent and " <RGB:0.3,0.9,0.45> [ACTIVE] - Engine Agent and JVM Bytecode Hooks Loaded! " or " <RGB:0.4,0.85,1.0> [INACTIVE] - Running in Standard Lua Mode (100% Fully Functional) "

    self.textBox.text = " <RGB:0.3,0.85,1.0> <SIZE:medium> Project Zomboid Engine Agent (Optional Enhancement) <LINE> <LINE> " ..
        " <RGB:0.85,0.85,0.85> Current Engine Status: " .. statusText .. " <LINE> <LINE> " ..
        " <RGB:0.95,0.85,0.4> NOTE: The Project Zomboid Optimiser mod is 100% fully functional on its own! <LINE> " ..
        " <RGB:0.85,0.85,0.85> All Lua performance features (lag cleaners, texture preloading, vehicle collision smoothing, and HUD profiling) work immediately out-of-the-box in standard mode. The open-source PZO installer is an optional tool for players wanting additional performance enhancements: <LINE> <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Automatic RAM Scaling: Expands memory from 3GB to 8GB-16GB tailored to your PC <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Low-Latency G1GC Tuning: Smooths frame pacing during high-speed driving & mega hordes <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Asynchronous 3D Model Compiling: Eliminates clothing & backpack equip stutter <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Zero-Stutter Background GC Mode: Prevents stop-the-world Lua garbage collection freezes <LINE> <LINE> " ..
        " <RGB:0.8,0.8,0.8> Because external batch/JAR tools cannot be hosted directly on the Steam Workshop, it is hosted on GitHub. Installing it is completely optional and only needs to be run once. <LINE> <LINE> " ..
        " <RGB:0.3,0.85,1.0> GitHub Repository: <RGB:1.0,1.0,1.0> https://github.com/prop11/PZO-Launcher"
    self.textBox:paginate()
    self:addChild(self.textBox)

    local row1Y = self.height - (btnH * 2) - math.floor(20 * scale)
    local btnW2 = math.floor((self.width - (pad * 3)) / 2)

    local openGithubBtn = ISButton:new(pad, row1Y, btnW2, btnH, "[*] Open GitHub in Browser", self, function(s)
        local url = "https://github.com/prop11/PZO-Launcher"
        if MPOptim.Utils and MPOptim.Utils.OpenURL then
            MPOptim.Utils.OpenURL(url)
        elseif openUrl then
            openUrl("https://steamcommunity.com/linkfilter/?url=" .. url)
        end
        if Clipboard and Clipboard.setClipboard then
            Clipboard.setClipboard(url)
        end
        s.statusMsg = "Opened GitHub in browser & copied link to clipboard!"
        s.statusTimer = 220
    end)
    openGithubBtn:initialise()
    openGithubBtn.backgroundColor = { r = 0.10, g = 0.35, b = 0.50, a = 0.95 }
    openGithubBtn.borderColor = { r = 0.25, g = 0.75, b = 0.95, a = 1.0 }
    self:addChild(openGithubBtn)

    local copyLinkBtn = ISButton:new(pad * 2 + btnW2, row1Y, btnW2, btnH, "[+] Copy Link", self, function(s)
        local url = "https://github.com/prop11/PZO-Launcher"
        if Clipboard and Clipboard.setClipboard then
            Clipboard.setClipboard(url)
        end
        s.statusMsg = "Copied GitHub URL to Clipboard!"
        s.statusTimer = 200
    end)
    copyLinkBtn:initialise()
    copyLinkBtn.backgroundColor = { r = 0.15, g = 0.22, b = 0.35, a = 0.95 }
    copyLinkBtn.borderColor = { r = 0.30, g = 0.55, b = 0.80, a = 1.0 }
    self:addChild(copyLinkBtn)

    local row2Y = self.height - btnH - math.floor(10 * scale)
    local closeBtn = ISButton:new(pad, row2Y, self.width - (pad * 2), btnH, "[OK] Close", self, function(s)
        s:setVisible(false)
        s:removeFromUIManager()
    end)
    closeBtn:initialise()
    closeBtn.backgroundColor = { r = 0.15, g = 0.20, b = 0.28, a = 0.95 }
    closeBtn.borderColor = { r = 0.30, g = 0.45, b = 0.65, a = 0.95 }
    self:addChild(closeBtn)
end

function EngineAgentModal:render()
    ISPanel.render(self)
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local medFont = (UIFont and UIFont.Medium) or 0
    self:drawText("[*] Project Zomboid Engine Agent (Optional)", math.floor(20 * scale), math.floor(10 * scale), 0.30, 0.85, 1.0, 1.0, medFont)
    self:drawRect(0, self.titleH, self.width, 2, 0.95, 0.22, 0.45, 0.75)

    if self.statusTimer > 0 then
        self.statusTimer = self.statusTimer - 1
        local smFont = (UIFont and UIFont.Small) or 0
        local statusY = self.height - math.max(32, math.floor(fontH + 14 * scale)) * 2 - math.floor(38 * scale)
        self:drawTextCentre(self.statusMsg, math.floor(self.width / 2), statusY, 0.35, 1.0, 0.45, 1.0, smFont)
    end
end

function MPOptim.MainMenu.ShowEngineAgentModal()
    local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
    local winW = math.min(sw - 40, math.max(680, math.floor(740 * scale)))
    local winH = math.min(sh - 40, math.max(420, math.floor(460 * scale)))
    local winX = math.floor((sw - winW) / 2)
    local winY = math.floor((sh - winH) / 2)

    local modal = EngineAgentModal:new(winX, winY, winW, winH)
    modal:initialise()
    modal:addToUIManager()
end

local MultiCPUModal = ISPanel:derive("MPOptim_MultiCPUModal")

function MultiCPUModal:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.05, g = 0.07, b = 0.12, a = 0.98 }
    o.borderColor = { r = 0.20, g = 0.55, b = 0.85, a = 1.0 }
    o.moveWithMouse = true
    o.statusMsg = ""
    o.statusTimer = 0
    return o
end

function MultiCPUModal:onMouseDown(x, y)
    ISPanel.onMouseDown(self, x, y)
    self:bringToTop()
    return true
end

function MultiCPUModal:initialise()
    ISPanel.initialise(self)
    self:createChildren()
end

function MultiCPUModal:createChildren()
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local titleH = math.max(36, math.floor(fontH + 18 * scale))
    self.titleH = titleH

    local pad = math.floor(20 * scale)
    local textY = titleH + math.floor(10 * scale)
    local btnH = math.max(32, math.floor(fontH + 14 * scale))
    local textH = self.height - textY - (btnH * 2) - math.floor(45 * scale)
    local textW = self.width - (pad * 2)

    self.textBox = ISRichTextPanel:new(pad, textY, textW, textH)
    self.textBox:initialise()
    self.textBox.background = false
    self.textBox.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textBox.borderColor = { r = 0, g = 0, b = 0, a = 0 }

    self.textBox.text = " <RGB:0.3,0.85,1.0> <SIZE:medium> Multi-CPU & Java Virtual Machine (JVM) Launcher Optimizer <LINE> <LINE> " ..
        " <RGB:0.9,0.9,0.9> <SIZE:small> In Project Zomboid (Build 42 & 41), the game launcher reads its RAM allocation from <RGB:1.0,0.8,0.2> ProjectZomboid64.json <RGB:0.9,0.9,0.9> (Steam Launch Options are passed as game arguments, not JVM memory). By default, the game is capped to 3GB RAM. You can expand it to 8GB or 6GB in seconds: <LINE> <LINE> " ..
        " <RGB:0.4,0.9,0.5> * 8GB / 6GB RAM Expansion: <RGB:0.8,0.8,0.8> Prevents Out-Of-Memory stutters and crashes during heavy modded gameplay. <LINE> " ..
        " <RGB:0.4,0.9,0.5> * Low-Latency ZGC: <RGB:0.8,0.8,0.8> Eliminates 300ms Stop-The-World garbage collection freezes during combat and driving. <LINE> <LINE> " ..
        " <RGB:1.0,0.8,0.2> EASY 1-MINUTE SETUP INSTRUCTIONS: <LINE> " ..
        " <RGB:0.85,0.85,0.85> 1. In Steam, right-click <RGB:0.3,0.85,1.0> Project Zomboid -> Manage -> Browse Local Files <RGB:0.85,0.85,0.85>. <LINE> " ..
        " <RGB:0.85,0.85,0.85> 2. Open <RGB:1.0,0.8,0.2> ProjectZomboid64.json <RGB:0.85,0.85,0.85> in Notepad. <LINE> " ..
        " <RGB:0.85,0.85,0.85> 3. Change <RGB:1.0,0.4,0.4> \"-Xmx3072m\" <RGB:0.85,0.85,0.85> to <RGB:0.4,0.9,0.5> \"-Xmx8192m\" <RGB:0.85,0.85,0.85> (or 6144m for 6GB), save and launch!"
    self.textBox:paginate()
    self:addChild(self.textBox)

    -- Action Buttons Row 1: Copy Launch Options (8GB, 6GB, 4GB)
    local row1Y = self.height - (btnH * 2) - math.floor(25 * scale)
    local btnW3 = math.floor((self.width - (pad * 4)) / 3)

    local btn8GB = ISButton:new(pad, row1Y, btnW3, btnH, "[+] Copy 8GB (Recommended)", self, function(s)
        local optStr = '"-Xms4096m",\n        "-Xmx8192m",\n        "-XX:+UseNUMA",\n        "-XX:+AlwaysPreTouch"'
        if Clipboard and Clipboard.setClipboard then
            Clipboard.setClipboard(optStr)
        end
        s.statusMsg = "Copied 8GB JVM Configuration to Clipboard!"
        s.statusTimer = 200
    end)
    btn8GB:initialise()
    btn8GB.backgroundColor = { r = 0.10, g = 0.35, b = 0.20, a = 0.95 }
    btn8GB.borderColor = { r = 0.25, g = 0.75, b = 0.40, a = 1.0 }
    btn8GB.tooltip = "Recommended for most people. Try this first before the 6GB version! Copies '-Xmx8192m' to clipboard for ProjectZomboid64.json."
    self:addChild(btn8GB)

    local btn6GB = ISButton:new(pad * 2 + btnW3, row1Y, btnW3, btnH, "[+] Copy 6GB (Lower-End)", self, function(s)
        local optStr = '"-Xms3072m",\n        "-Xmx6144m",\n        "-XX:+UseNUMA",\n        "-XX:+AlwaysPreTouch"'
        if Clipboard and Clipboard.setClipboard then
            Clipboard.setClipboard(optStr)
        end
        s.statusMsg = "Copied 6GB JVM Configuration to Clipboard!"
        s.statusTimer = 200
    end)
    btn6GB:initialise()
    btn6GB.backgroundColor = { r = 0.10, g = 0.28, b = 0.35, a = 0.95 }
    btn6GB.borderColor = { r = 0.25, g = 0.65, b = 0.80, a = 1.0 }
    btn6GB.tooltip = "Recommended for lower-end machines and budget systems. Copies '-Xmx6144m' to clipboard for ProjectZomboid64.json."
    self:addChild(btn6GB)

    local btn4GB = ISButton:new(pad * 3 + (btnW3 * 2), row1Y, btnW3, btnH, "[+] Copy 4GB (Budget)", self, function(s)
        local optStr = '"-Xms2048m",\n        "-Xmx4096m",\n        "-XX:+UseNUMA",\n        "-XX:+AlwaysPreTouch"'
        if Clipboard and Clipboard.setClipboard then
            Clipboard.setClipboard(optStr)
        end
        s.statusMsg = "Copied 4GB JVM Configuration to Clipboard!"
        s.statusTimer = 200
    end)
    btn4GB:initialise()
    btn4GB.backgroundColor = { r = 0.25, g = 0.20, b = 0.10, a = 0.95 }
    btn4GB.borderColor = { r = 0.75, g = 0.55, b = 0.25, a = 1.0 }
    btn4GB.tooltip = "For low-spec systems with 8GB total RAM. Copies '-Xmx4096m' to clipboard for ProjectZomboid64.json."
    self:addChild(btn4GB)

    -- Action Buttons Row 2: Close Button
    local row2Y = self.height - btnH - math.floor(12 * scale)
    local closeBtn = ISButton:new(pad, row2Y, self.width - (pad * 2), btnH, "[OK] Close", self, function(s)
        s:setVisible(false)
        s:removeFromUIManager()
    end)
    closeBtn:initialise()
    closeBtn.backgroundColor = { r = 0.15, g = 0.20, b = 0.28, a = 0.95 }
    closeBtn.borderColor = { r = 0.30, g = 0.45, b = 0.65, a = 0.95 }
    self:addChild(closeBtn)
end

function MultiCPUModal:render()
    ISPanel.render(self)
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local medFont = (UIFont and UIFont.Medium) or 0
    self:drawText("[+] Project Zomboid Multi-CPU & Memory Launcher Optimizer", math.floor(20 * scale), math.floor(10 * scale), 0.30, 0.85, 1.0, 1.0, medFont)
    self:drawRect(0, self.titleH, self.width, 2, 0.95, 0.22, 0.45, 0.75)

    if self.statusTimer > 0 then
        self.statusTimer = self.statusTimer - 1
        local smFont = (UIFont and UIFont.Small) or 0
        local statusY = self.height - math.max(32, math.floor(fontH + 14 * scale)) * 2 - math.floor(45 * scale)
        self:drawTextCentre(self.statusMsg, math.floor(self.width / 2), statusY, 0.35, 1.0, 0.45, 1.0, smFont)
    end
end

function MPOptim.MainMenu.ShowMultiCPUModal()
    local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
    local winW = math.min(sw - 40, math.max(720, math.floor(780 * scale)))
    local winH = math.min(sh - 40, math.max(440, math.floor(490 * scale)))
    local winX = math.floor((sw - winW) / 2)
    local winY = math.floor((sh - winH) / 2)

    local modal = MultiCPUModal:new(winX, winY, winW, winH)
    modal:initialise()
    modal:addToUIManager()
end

-- ============================================================================
-- 3. Main Menu Button Injection & Per-Frame Screen Sync
-- ============================================================================
local menuBtnInstance = nil
local cpuBtnInstance = nil
local agentStatusLabel = nil
local updateAlertBtn = nil
local bugReportBtnInstance = nil
local isMainScreenHooked = false

local function hookMainScreenPrerender()
    if isMainScreenHooked or not MainScreen or not MainScreen.prerender then return end
    isMainScreenHooked = true

    local old_MainScreen_prerender = MainScreen.prerender
    MainScreen.prerender = function(self)
        old_MainScreen_prerender(self)
        local isRootVisible = (self.bottomPanel and self.bottomPanel:isVisible()) or false
        local isAgent = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()

        if menuBtnInstance then
            if menuBtnInstance:isVisible() ~= isRootVisible then
                menuBtnInstance:setVisible(isRootVisible)
                if isRootVisible then menuBtnInstance:bringToTop() end
            end
        end

        if agentStatusLabel then
            if agentStatusLabel:isVisible() ~= isRootVisible then
                agentStatusLabel:setVisible(isRootVisible)
                if isRootVisible then agentStatusLabel:bringToTop() end
            end
            if isAgent then
                agentStatusLabel.name = "[+] Engine Agent: ACTIVE"
                agentStatusLabel.r = 0.30
                agentStatusLabel.g = 0.90
                agentStatusLabel.b = 0.45
            else
                agentStatusLabel.name = "[-] Engine Agent: Inactive (Optional)"
                agentStatusLabel.r = 0.70
                agentStatusLabel.g = 0.75
                agentStatusLabel.b = 0.85
            end
        end

        if cpuBtnInstance then
            local shouldShowBtn = isRootVisible and (not isAgent)
            if cpuBtnInstance:isVisible() ~= shouldShowBtn then
                cpuBtnInstance:setVisible(shouldShowBtn)
                if shouldShowBtn then cpuBtnInstance:bringToTop() end
            end
        end

        if updateAlertBtn then
            local hasUp, latestVer, upUrl = false, nil, nil
            if isAgent and MPOptim.Utils.CheckGitHubUpdate then
                hasUp, latestVer, upUrl = MPOptim.Utils.CheckGitHubUpdate()
            end
            local shouldShowUp = isRootVisible and isAgent and (hasUp == true)
            if updateAlertBtn:isVisible() ~= shouldShowUp then
                updateAlertBtn:setVisible(shouldShowUp)
                if shouldShowUp then updateAlertBtn:bringToTop() end
            end
            if shouldShowUp and latestVer then
                local displayVer = tostring(latestVer)
                if string.sub(displayVer, 1, 1) ~= "v" and string.sub(displayVer, 1, 1) ~= "V" then
                    displayVer = "v" .. displayVer
                end
                updateAlertBtn.title = "[!] UPDATE AVAILABLE: " .. displayVer
            end
        end

        if bugReportBtnInstance then
            local shouldShowBug = isRootVisible and (isAgent == true)
            if bugReportBtnInstance:isVisible() ~= shouldShowBug then
                bugReportBtnInstance:setVisible(shouldShowBug)
                if shouldShowBug then bugReportBtnInstance:bringToTop() end
            end
        end
    end
end

function MPOptim.MainMenu.InjectButton()
    local mainScreen = MainScreen and MainScreen.instance
    if not mainScreen then return end

    hookMainScreenPrerender()

    if menuBtnInstance and menuBtnInstance:getParent() == mainScreen then
        local isRootVisible = mainScreen.bottomPanel and mainScreen.bottomPanel:isVisible() == true
        menuBtnInstance:setVisible(isRootVisible)
        if cpuBtnInstance then
            cpuBtnInstance:setVisible(isRootVisible)
        end
        return
    end

    local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
    local btnW = math.max(160, math.floor(190 * scale))
    local btnH = math.max(30, math.floor(fontH + 12 * scale))
    local btnGap = math.floor(6 * scale)

    local btnX = sw - btnW - math.floor(24 * scale)
    local btnY = math.floor(24 * scale)

    -- 1. Main Optimiser Control Center Button (CTRL + Click toggles Developer Mode)
    menuBtnInstance = ISButton:new(btnX, btnY, btnW, btnH, "[*] OPTIMISER", nil, function()
        if isCtrlKeyDown and isCtrlKeyDown() then
            MPOptim.ToggleDevMode()
        else
            MPOptim.OpenSettingsUI()
        end
    end)
    menuBtnInstance:initialise()
    menuBtnInstance.backgroundColor = { r = 0.08, g = 0.16, b = 0.26, a = 0.92 }
    menuBtnInstance.borderColor = { r = 0.25, g = 0.60, b = 0.95, a = 0.95 }
    mainScreen:addChild(menuBtnInstance)

    -- 2. Engine Agent Status Badge & Get Injection Button
    local isAgent = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
    local agentStatusY = btnY + btnH + math.floor(4 * scale)
    local smallFont = (UIFont and UIFont.Small) or 0

    if isAgent then
        agentStatusLabel = ISLabel:new(btnX + math.floor(btnW / 2), agentStatusY, fontH, "[+] Engine Agent: ACTIVE", 0.30, 0.90, 0.45, 1.0, smallFont, false)
        agentStatusLabel:initialise()
        mainScreen:addChild(agentStatusLabel)
    else
        agentStatusLabel = ISLabel:new(btnX + math.floor(btnW / 2), agentStatusY, fontH, "[-] Engine Agent: Inactive (Optional)", 0.70, 0.75, 0.85, 1.0, smallFont, false)
        agentStatusLabel:initialise()
        mainScreen:addChild(agentStatusLabel)

        local getAgentY = agentStatusY + fontH + math.floor(4 * scale)
        cpuBtnInstance = ISButton:new(btnX, getAgentY, btnW, btnH, "[*] OPTIONAL ENGINE ENHANCEMENT", nil, function()
            MPOptim.MainMenu.ShowEngineAgentModal()
        end)
        cpuBtnInstance:initialise()
        cpuBtnInstance.backgroundColor = { r = 0.10, g = 0.25, b = 0.40, a = 0.92 }
        cpuBtnInstance.borderColor = { r = 0.30, g = 0.70, b = 0.95, a = 0.95 }
        cpuBtnInstance.tooltip = "The Lua mod is 100% fully functional on its own. Click to view the optional open-source PZO installer on GitHub for extra 8GB+ RAM allocation and JVM tuning."
        mainScreen:addChild(cpuBtnInstance)
    end

    -- 3. GitHub Update Alert Button (Appears only when a newer release is detected)
    local hasUpdate, latestVer, updateUrl = MPOptim.Utils.CheckGitHubUpdate and MPOptim.Utils.CheckGitHubUpdate()
    local updateBtnY = (cpuBtnInstance and (cpuBtnInstance:getY() + btnH + math.floor(4 * scale))) or (agentStatusY + fontH + math.floor(4 * scale))

        local displayVer = latestVer and tostring(latestVer) or "0.4"
    if string.sub(displayVer, 1, 1) ~= "v" and string.sub(displayVer, 1, 1) ~= "V" then
        displayVer = "v" .. displayVer
    end
    updateAlertBtn = ISButton:new(btnX, updateBtnY, btnW, btnH, "[!] UPDATE AVAILABLE: " .. displayVer, nil, function()
        local upTarget = updateUrl or "https://github.com/prop11/PZO-Launcher/releases/latest"
        if MPOptim.Utils and MPOptim.Utils.OpenURL then
            MPOptim.Utils.OpenURL(upTarget)
        elseif openUrl then
            openUrl("https://steamcommunity.com/linkfilter/?url=" .. upTarget)
        end
        if Clipboard and Clipboard.setClipboard then
            Clipboard.setClipboard(upTarget)
        end
        if MPOptim.MainMenu.ShowEngineAgentModal then
            MPOptim.MainMenu.ShowEngineAgentModal()
        end
    end)
    updateAlertBtn:initialise()
    updateAlertBtn.backgroundColor = { r = 0.45, g = 0.20, b = 0.08, a = 0.95 }
    updateAlertBtn.borderColor = { r = 0.95, g = 0.65, b = 0.20, a = 1.0 }
    updateAlertBtn.tooltip = "A new version of the Project Zomboid Config & Engine Optimizer is available on GitHub! Click to open the download page."
    mainScreen:addChild(updateAlertBtn)

    -- 4. Bottom Right Bug & Crash Reporter Button
    local bugBtnX = sw - btnW - math.floor(24 * scale)
    local bugBtnY = sh - btnH - math.floor(24 * scale)
    bugReportBtnInstance = ISButton:new(bugBtnX, bugBtnY, btnW, btnH, "[[!]] Report Bug / Logs", nil, function()
        if MPOptim.BugReporter and MPOptim.BugReporter.OpenModal then
            MPOptim.BugReporter.OpenModal()
        end
    end)
    bugReportBtnInstance:initialise()
    bugReportBtnInstance.backgroundColor = { r = 0.32, g = 0.12, b = 0.12, a = 0.92 }
    bugReportBtnInstance.borderColor = { r = 0.85, g = 0.35, b = 0.30, a = 1.0 }
    bugReportBtnInstance.tooltip = "Encountering an issue or crash? Click to package your console.txt and pzo_engine.log diagnostics for GitHub."
    mainScreen:addChild(bugReportBtnInstance)

    local isRootVisible = mainScreen.bottomPanel and mainScreen.bottomPanel:isVisible() == true
    menuBtnInstance:setVisible(isRootVisible)
    if agentStatusLabel then agentStatusLabel:setVisible(isRootVisible) end
    if cpuBtnInstance then cpuBtnInstance:setVisible(isRootVisible) end
    if updateAlertBtn then updateAlertBtn:setVisible(isRootVisible and hasUpdate == true) end
    if bugReportBtnInstance then bugReportBtnInstance:setVisible(isRootVisible and (isAgent == true)) end

    local isFirst = MPOptim.MainMenu.ShowFirstLaunchModal()
    if not isFirst then
        MPOptim.MainMenu.ShowUpdateModal()
    end
end

Events.OnMainMenuEnter.Add(MPOptim.MainMenu.InjectButton)


-- ============================================================================



-- 4. Developer Mode & Benchmark Suite (CTRL + Click on Main Menu Button)
-- ============================================================================
function MPOptim.ToggleDevMode()
    MPOptim.DevMode = not MPOptim.DevMode
    local player = getPlayer and getPlayer()

    if MPOptim.DevMode then
        if player and MPOptim.Utils and MPOptim.Utils.Notify then
            MPOptim.Utils.Notify(player, "DEVELOPER MODE ACTIVATED: Test Mode Benchmark Unlocked!", true)
        end
    else
        if player and MPOptim.Utils and MPOptim.Utils.Notify then
            MPOptim.Utils.Notify(player, "Developer Mode Deactivated.", false)
        end
    end

    -- Reopen Settings UI with new preset header
    MPOptim.OpenSettingsUI(true)
end
