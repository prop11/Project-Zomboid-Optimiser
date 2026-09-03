--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_BugReporter.lua
    Author: prop11
    Description: In-game Bug & Crash Reporter modal and launcher integration.
                 Allows one-click copying of system diagnostics and opening logs folder for GitHub issue submissions.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"
require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISRichTextPanel"

MPOptim = MPOptim or {}
MPOptim.BugReporter = MPOptim.BugReporter or {}

-- ============================================================================
-- 1. Bug & Crash Report Modal Dialog
-- ============================================================================
local BugReportModal = ISPanel:derive("MPOptim_BugReportModal")

function BugReportModal:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.06, g = 0.08, b = 0.12, a = 0.98 }
    o.borderColor = { r = 0.75, g = 0.30, b = 0.25, a = 1.0 }
    o.moveWithMouse = true
    o.statusMsg = nil
    o.statusTimer = 0
    return o
end

function BugReportModal:onMouseDown(x, y)
    ISPanel.onMouseDown(self, x, y)
    self:bringToTop()
    return true
end

function BugReportModal:initialise()
    ISPanel.initialise(self)
    self:createChildren()
end

function BugReportModal:createChildren()
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local titleH = math.max(36, math.floor(fontH + 18 * scale))
    self.titleH = titleH

    local pad = math.floor(20 * scale)
    local textY = titleH + math.floor(8 * scale)
    local btnH = math.max(34, math.floor(fontH + 16 * scale))
    local actionAreaH = (btnH * 2) + math.floor(30 * scale)
    local textH = self.height - textY - actionAreaH
    local textW = self.width - (pad * 2)

    local coreVer = (getCore and getCore().getVersionNumber and getCore():getVersionNumber()) or "Build 42"
    local pzoVer = (PZOEngineVersion or (PZOEngineBridge and PZOEngineBridge.getVersion and PZOEngineBridge.getVersion()) or MPOptim.Version or "0.8.2-unstable")
    local isAgent = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
    local agentStatus = isAgent and "ACTIVE (Native JVM Acceleration)" or "Inactive (Vanilla Heap / Standalone Mod Mode)"

    local guideText = " <RGB:1.0,0.4,0.35> <SIZE:medium> Project Zomboid Optimiser - Bug & Crash Reporter <LINE> <LINE> " ..
        " <RGB:0.85,0.85,0.85> <SIZE:small> If you encountered a crash, visual glitch, or unexpected behavior, we are here to help! <LINE> " ..
        " <RGB:0.7,0.7,0.7> - Game Version: <RGB:1.0,0.8,0.2> " .. tostring(coreVer) .. " <RGB:0.7,0.7,0.7> | PZO Version: <RGB:0.3,0.85,1.0> v" .. tostring(pzoVer) .. " <LINE> " ..
        " <RGB:0.7,0.7,0.7> - Engine Optimization Status: <RGB:0.4,0.9,0.5> " .. tostring(agentStatus) .. " <LINE> <LINE> " ..
        " <RGB:0.9,0.9,0.9> <SIZE:small> Quick 3-Step Submission Guide: <LINE> " ..
        " <RGB:0.3,0.85,1.0> 1. Click <RGB:1.0,0.9,0.3> '[[*] Copy Diagnostics & Logs]' <RGB:0.3,0.85,1.0> to copy your system spec and recent errors to clipboard. <LINE> " ..
        " <RGB:0.3,0.85,1.0> 2. Click <RGB:1.0,0.9,0.3> '[[*] Open Logs Folder]' <RGB:0.3,0.85,1.0> to locate your <RGB:1.0,1.0,1.0> console.txt <RGB:0.3,0.85,1.0> & <RGB:1.0,1.0,1.0> pzo_engine.log <RGB:0.3,0.85,1.0> files. <LINE> " ..
        " <RGB:0.3,0.85,1.0> 3. Click <RGB:1.0,0.9,0.3> '[[*] Submit Issue on GitHub]' <RGB:0.3,0.85,1.0> to open our issue tracker, paste your clipboard (<RGB:1.0,0.8,0.2> Ctrl+V <RGB:0.3,0.85,1.0>), and drag & drop your logs!"

    self.textBox = ISRichTextPanel:new(pad, textY, textW, textH)
    self.textBox:initialise()
    self.textBox.background = false
    self.textBox.backgroundColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textBox.borderColor = { r = 0, g = 0, b = 0, a = 0 }
    self.textBox.text = guideText
    self.textBox:paginate()
    self:addChild(self.textBox)

    -- Action Row 1: Copy Diagnostics & Open Logs Folder
    local btnY1 = self.height - actionAreaH + math.floor(6 * scale)
    local btnW_half = math.floor((self.width - (pad * 3)) / 2)

    local copyBtn = ISButton:new(pad, btnY1, btnW_half, btnH, "[[*]] Copy Diagnostics to Clipboard", self, function(s)
        local copied = false
        if type(PZOEngineBridge) == "table" and type(PZOEngineBridge.copyDiagnosticsToClipboard) == "function" then
            PZOEngineBridge.copyDiagnosticsToClipboard()
            copied = true
        end

        if not copied and Clipboard and Clipboard.setClipboard then
            local fallbackReport = "### Project Zomboid Optimiser - Bug Diagnostic Report\n" ..
                "- Game Version: " .. tostring(coreVer) .. "\n" ..
                "- PZO Version: v" .. tostring(pzoVer) .. "\n" ..
                "- Engine Active: " .. tostring(isAgent) .. "\n" ..
                "- OS / Arch: " .. tostring(System and System.getProperty and System.getProperty("os.name") or "Unknown") .. "\n\n" ..
                "*(Please attach your ~/Zomboid/console.txt and ~/Zomboid/Lua/pzo_engine.log)*"
            Clipboard.setClipboard(fallbackReport)
            copied = true
        end

        s.statusMsg = "[OK] System diagnostics & error logs copied to clipboard! (Ready to paste on GitHub with Ctrl+V)"
        s.statusTimer = 240
    end)
    copyBtn:initialise()
    copyBtn.backgroundColor = { r = 0.12, g = 0.35, b = 0.22, a = 0.95 }
    copyBtn.borderColor = { r = 0.25, g = 0.85, b = 0.45, a = 1.0 }
    copyBtn.tooltip = "Copies your system specifications, active mod version, and recent console.txt error stack traces directly to your OS clipboard."
    self:addChild(copyBtn)

    local openFolderBtn = ISButton:new(pad * 2 + btnW_half, btnY1, btnW_half, btnH, "[[*]] Open Zomboid Logs Folder", self, function(s)
        local opened = false
        if type(PZOEngineBridge) == "table" and type(PZOEngineBridge.openLogsFolder) == "function" then
            PZOEngineBridge.openLogsFolder()
            opened = true
        end

        if not opened then
            s.statusMsg = "Logs are located in: " .. tostring(System and System.getProperty and System.getProperty("user.home") or "~") .. "/Zomboid/console.txt"
            s.statusTimer = 300
        else
            s.statusMsg = "[OK] Opened Zomboid logs folder in your file explorer."
            s.statusTimer = 240
        end
    end)
    openFolderBtn:initialise()
    openFolderBtn.backgroundColor = { r = 0.15, g = 0.25, b = 0.40, a = 0.95 }
    openFolderBtn.borderColor = { r = 0.30, g = 0.70, b = 0.95, a = 1.0 }
    openFolderBtn.tooltip = "Opens your user Zomboid directory in Windows Explorer / macOS Finder / Linux File Manager to easily drag & drop console.txt and pzo_engine.log."
    self:addChild(openFolderBtn)

    -- Action Row 2: Submit on GitHub & Close
    local btnY2 = btnY1 + btnH + math.floor(8 * scale)
    local ghBtn = ISButton:new(pad, btnY2, btnW_half, btnH, "[[*]] Open GitHub Issues Page", self, function(s)
        local ghUrl = "https://github.com/prop11/PZO-Launcher/issues/new?title=%5BBug+Report%5D+&labels=bug"
        if type(PZOEngineBridge) == "table" and type(PZOEngineBridge.openBrowser) == "function" then
            PZOEngineBridge.openBrowser(ghUrl)
        elseif MPOptim.Utils and MPOptim.Utils.OpenURL then
            MPOptim.Utils.OpenURL(ghUrl)
        elseif openUrl then
            openUrl("https://steamcommunity.com/linkfilter/?url=" .. ghUrl)
        end
        s.statusMsg = "[OK] Opened GitHub Issues tracker in your web browser."
        s.statusTimer = 240
    end)
    ghBtn:initialise()
    ghBtn.backgroundColor = { r = 0.35, g = 0.18, b = 0.10, a = 0.95 }
    ghBtn.borderColor = { r = 0.95, g = 0.55, b = 0.20, a = 1.0 }
    ghBtn.tooltip = "Opens the official PZO GitHub Issues page in your default browser to create a new bug report."
    self:addChild(ghBtn)

    local closeBtn = ISButton:new(pad * 2 + btnW_half, btnY2, btnW_half, btnH, "[X] Close", self, function(s)
        s:setVisible(false)
        s:removeFromUIManager()
    end)
    closeBtn:initialise()
    closeBtn.backgroundColor = { r = 0.15, g = 0.18, b = 0.22, a = 0.95 }
    closeBtn.borderColor = { r = 0.40, g = 0.45, b = 0.55, a = 0.95 }
    self:addChild(closeBtn)
end

function BugReportModal:prerender()
    ISPanel.prerender(self)
    local scale, fontH = MPOptim.Utils.GetUIScale()
    local medFont = (UIFont and UIFont.Medium) or 0
    local titleY = math.floor(10 * scale)

    self:drawTextCentre("PROJECT ZOMBOID OPTIMISER - BUG & ERROR REPORTER", math.floor(self.width / 2), titleY, 1.0, 0.45, 0.40, 1.0, medFont)
    self:drawRect(0, self.titleH, self.width, 1, 0.8, 0.75, 0.30, 0.25)

    if self.statusTimer and self.statusTimer > 0 then
        self.statusTimer = self.statusTimer - 1
        local smFont = (UIFont and UIFont.Small) or 0
        local statusY = self.height - math.max(34, math.floor(fontH + 16 * scale)) * 2 - math.floor(28 * scale)
        self:drawTextCentre(self.statusMsg or "", math.floor(self.width / 2), statusY, 0.35, 1.0, 0.50, 1.0, smFont)
    end
end

-- ============================================================================
-- 2. Open Bug Reporter Modal Helper
-- ============================================================================
function MPOptim.BugReporter.OpenModal()
    local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
    local winW = math.min(sw - 40, math.max(680, math.floor(740 * scale)))
    local winH = math.min(sh - 40, math.max(420, math.floor(460 * scale)))
    local winX = math.floor((sw - winW) / 2)
    local winY = math.floor((sh - winH) / 2)

    local modal = BugReportModal:new(winX, winY, winW, winH)
    modal:initialise()
    modal:addToUIManager()
    modal:bringToTop()
    return modal
end

-- ============================================================================
-- 3. Pause Screen (ISPauseMenu) Button Injection
-- ============================================================================
local isPauseMenuHooked = false
local function hookPauseMenu()
    if isPauseMenuHooked or not ISPauseMenu then return end
    isPauseMenuHooked = true

    local old_ISPauseMenu_create = ISPauseMenu.create
    ISPauseMenu.create = function(self)
        old_ISPauseMenu_create(self)

        -- ONLY display Bug Report button if JVM Engine agent is actively injected
        local isAgent = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
        if not isAgent then return end

        local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
        local btnW = math.max(160, math.floor(190 * scale))
        local btnH = math.max(28, math.floor(fontH + 10 * scale))
        local pad = math.floor(16 * scale)

        -- Place button in the bottom right corner of the screen
        local bugBtn = ISButton:new(sw - btnW - pad, sh - btnH - pad, btnW, btnH, "[[!]] Report Bug / Logs", self, function()
            MPOptim.BugReporter.OpenModal()
        end)
        bugBtn:initialise()
        bugBtn.backgroundColor = { r = 0.32, g = 0.12, b = 0.12, a = 0.92 }
        bugBtn.borderColor = { r = 0.85, g = 0.35, b = 0.30, a = 1.0 }
        bugBtn.tooltip = "Encountering a bug, glitch, or crash? Click to package your console.txt and pzo_engine.log to submit to GitHub."
        self:addChild(bugBtn)
    end
end

hookPauseMenu()
Events.OnGameStart.Add(hookPauseMenu)
