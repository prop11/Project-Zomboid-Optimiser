--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_BugReporter.lua
    Author: prop11
    Description: Bug report popup (copy diagnostics, open the logs folder, open GitHub issues) and its pause menu button.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"
require "MPOptim_UIStyle"
require "ISUI/ISButton"

MPOptim = MPOptim or {}
MPOptim.BugReporter = MPOptim.BugReporter or {}
local U = MPOptim.UI
local C, T = U.C, U.T

local ISSUES_URL = "https://github.com/prop11/PZO-Launcher/issues/new?title=%5BBug+Report%5D+&labels=bug"

local function bridgeHas(name)
    return type(PZOEngineBridge) == "table" and type(PZOEngineBridge[name]) == "function"
end

function MPOptim.BugReporter.OpenModal()
    local coreVer = (getCore and getCore().getVersionNumber and getCore():getVersionNumber()) or "Build 42"
    local pzoVer = PZOEngineVersion or (bridgeHas("getVersion") and PZOEngineBridge.getVersion()) or MPOptim.Version or "?"
    local isAgent = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()

    return U.ShowModal({
        title = T("UI_MPOptim_V2_BugTitle", "Report a bug"),
        width = 660,
        body = {
            { p = T("UI_MPOptim_V2_BugIntro", "Had a crash, a visual glitch or something odd? A report with your logs gets it fixed fastest.") },
            { gap = true },
            { kv = { T("UI_MPOptim_V2_BugGameVer", "Game version"), tostring(coreVer) }, col = C.warn },
            { kv = { T("UI_MPOptim_V2_BugPzoVer", "PZO version"), "v" .. tostring(pzoVer) }, col = C.accent },
            { kv = { T("UI_MPOptim_V2_StatEngine", "Engine"), isAgent and T("UI_MPOptim_V2_EngineJavaShort", "Java (active)") or T("UI_MPOptim_V2_EngineLuaShort", "Lua only") }, col = isAgent and C.good or C.dim },
            { gap = true },
            { h = T("UI_MPOptim_V2_BugSteps", "Three steps") },
            { bullet = T("UI_MPOptim_V2_BugStep1", "Copy diagnostics: puts your system details and recent errors on the clipboard.") },
            { bullet = T("UI_MPOptim_V2_BugStep2", "Open logs folder: shows console.txt and pzo_engine.log to attach.") },
            { bullet = T("UI_MPOptim_V2_BugStep3", "Open GitHub: start a new issue, paste with Ctrl+V and drag the two log files in.") },
        },
        buttons = {
            { label = T("UI_MPOptim_V2_BugCopy", "Copy diagnostics"), style = "good", keepOpen = true, onClick = function(modal)
                if bridgeHas("copyDiagnosticsToClipboard") then
                    PZOEngineBridge.copyDiagnosticsToClipboard()
                elseif Clipboard and Clipboard.setClipboard then
                    Clipboard.setClipboard("### Project Zomboid Optimiser - Bug Report\n" ..
                        "- Game Version: " .. tostring(coreVer) .. "\n" ..
                        "- PZO Version: v" .. tostring(pzoVer) .. "\n" ..
                        "- Java Engine Active: " .. tostring(isAgent) .. "\n\n" ..
                        "(Please attach ~/Zomboid/console.txt and ~/Zomboid/Lua/pzo_engine.log)")
                end
                modal:setStatus(T("UI_MPOptim_V2_BugCopied", "Diagnostics copied. Paste them into the issue with Ctrl+V."))
            end },
            { label = T("UI_MPOptim_V2_BugLogs", "Open logs folder"), style = "primary", keepOpen = true, onClick = function(modal)
                if bridgeHas("openLogsFolder") then
                    PZOEngineBridge.openLogsFolder()
                    modal:setStatus(T("UI_MPOptim_V2_BugLogsOpened", "Opened the Zomboid folder."))
                else
                    modal:setStatus(T("UI_MPOptim_V2_BugLogsWhere", "Your logs are in your user folder under Zomboid: console.txt"), C.warn)
                end
            end },
            { label = T("UI_MPOptim_V2_BugGitHub", "Open GitHub"), style = "warn", keepOpen = true, onClick = function(modal)
                if bridgeHas("openBrowser") then
                    PZOEngineBridge.openBrowser(ISSUES_URL)
                elseif MPOptim.Utils and MPOptim.Utils.OpenURL then
                    MPOptim.Utils.OpenURL(ISSUES_URL)
                elseif openUrl then
                    openUrl("https://steamcommunity.com/linkfilter/?url=" .. ISSUES_URL)
                end
                modal:setStatus(T("UI_MPOptim_V2_BugGitHubOpened", "Opened GitHub issues in your browser."))
            end },
            { label = T("UI_MPOptim_V2_Close", "Close"), style = "neutral" },
        },
        cancel = 4,
    })
end

local isPauseMenuHooked = false
local function hookPauseMenu()
    if isPauseMenuHooked or not ISPauseMenu then return end
    isPauseMenuHooked = true

    local old_create = ISPauseMenu.create
    ISPauseMenu.create = function(self)
        old_create(self)

        -- Only with the Java engine: the report relies on its log file and diagnostics
        local isAgent = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
        if not isAgent then return end

        local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
        local btnW = math.max(160, math.floor(190 * scale))
        local btnH = math.max(28, math.floor(fontH + 10 * scale))
        local pad = math.floor(16 * scale)

        local bugBtn = ISButton:new(sw - btnW - pad, sh - btnH - pad, btnW, btnH, T("UI_MPOptim_V2_MenuReportBug", "Report a bug"), self, function()
            MPOptim.BugReporter.OpenModal()
        end)
        bugBtn:initialise()
        U.StyleButton(bugBtn, "neutral")
        bugBtn.tooltip = T("UI_MPOptim_V2_MenuReportBugTip", "Copies your diagnostics and shows where your log files are, to attach to a GitHub issue.")
        self:addChild(bugBtn)
    end
end

hookPauseMenu()
Events.OnGameStart.Add(hookPauseMenu)
