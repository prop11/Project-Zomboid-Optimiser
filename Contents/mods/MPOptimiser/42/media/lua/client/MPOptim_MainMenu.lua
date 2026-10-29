--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_MainMenu.lua
    Author: prop11
    Description: Main menu buttons and the welcome, update and Java engine popups.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"
require "MPOptim_UI_SettingsV2"
require "MPOptim_UIStyle"
require "MPOptim_BugReporter"
require "ISUI/ISButton"

MPOptim = MPOptim or {}
MPOptim.MainMenu = MPOptim.MainMenu or {}
local U = MPOptim.UI
local C, T = U.C, U.T

local GITHUB_URL = "https://github.com/prop11/PZO-Launcher"

local function openLink(url)
    if MPOptim.Utils and MPOptim.Utils.OpenURL then
        MPOptim.Utils.OpenURL(url)
    elseif openUrl then
        openUrl("https://steamcommunity.com/linkfilter/?url=" .. url)
    end
end

local function copyText(str)
    if Clipboard and Clipboard.setClipboard then Clipboard.setClipboard(str) end
end

local function markSeen(firstLaunch)
    if firstLaunch then MPOptim.Config.Set("FirstLaunchPromptShown", true) end
    MPOptim.Config.Set("LastSeenVersion", MPOptim.Version)
    MPOptim.Config.Save()
end

local function hotkeyLine()
    return T("UI_MPOptim_V2_HotkeyLine", "Open the settings any time with F10 in game or the Optimiser button on the main menu.")
end

function MPOptim.MainMenu.ShowFirstLaunchModal()
    if MPOptim.Config and MPOptim.Config.Load then MPOptim.Config.Load() end
    local shown = MPOptim.Config.Get("FirstLaunchPromptShown")
    if shown == true or shown == "true" or shown == 1 then return false end

    U.ShowModal({
        title = T("UI_MPOptim_V2_WelcomeTitle", "Welcome to Project Zomboid Optimiser"),
        width = 640,
        body = {
            { p = T("UI_MPOptim_V2_WelcomeIntro", "Your game is already using these optimizations:") },
            { gap = true },
            { bullet = T("UI_MPOptim_V2_WelcomeB1", "Smoother combat with less animation work for distant zombies"), col = C.good },
            { bullet = T("UI_MPOptim_V2_WelcomeB2", "At most 4 blood stains per tile, which looks the same"), col = C.good },
            { bullet = T("UI_MPOptim_V2_WelcomeB3", "Cleanups spread over many frames so they do not stutter"), col = C.good },
            { bullet = T("UI_MPOptim_V2_WelcomeB4", "Texture compression and fewer fly swarms to save video memory"), col = C.good },
            { gap = true },
            { p = T("UI_MPOptim_V2_WelcomeAsk", "Open the settings now to pick a preset, set cleanup rules or turn on the performance overlay?") },
            { gap = true },
            { p = hotkeyLine(), col = C.dim },
        },
        buttons = {
            { label = T("UI_MPOptim_V2_OpenSettings", "Open settings"), style = "good", onClick = function()
                markSeen(true)
                MPOptim.OpenSettingsUI()
            end },
            { label = T("UI_MPOptim_V2_KeepDefaults", "Keep the defaults"), style = "neutral", onClick = function() markSeen(true) end },
        },
        cancel = 2,
    })
    return true
end

function MPOptim.MainMenu.ShowUpdateModal()
    if MPOptim.Config and MPOptim.Config.Load then MPOptim.Config.Load() end
    if MPOptim.Config.Get("LastSeenVersion") == MPOptim.Version then return end

    U.ShowModal({
        title = string.format(T("UI_MPOptim_V2_UpdatedTitle", "Optimiser updated to v%s"), tostring(MPOptim.Version)),
        width = 680,
        body = {
            { h = T("UI_MPOptim_V2_WhatsNew", "What is new") },
            { bullet = T("UI_MPOptim_V2_New1", "A new settings screen: every setting shows what it saves or costs and whether it is worth it on your PC."), col = C.good },
            { bullet = T("UI_MPOptim_V2_New2", "Every Optimiser window works with a controller."), col = C.good },
            { bullet = T("UI_MPOptim_V2_New3", "Works with Project Real Limbs and Project A-Life."), col = C.good },
            { bullet = T("UI_MPOptim_V2_New4", "Several settings that had no effect now work, and ones that could not work were removed."), col = C.good },
            { gap = true },
            { p = T("UI_MPOptim_V2_LuaOnlyNote", "The mod works fully on its own. The optional PZO Java engine from GitHub adds further engine-level optimizations."), col = C.warn },
            { gap = true },
            { p = hotkeyLine(), col = C.dim },
        },
        buttons = {
            { label = T("UI_MPOptim_V2_OpenSettings", "Open settings"), style = "good", onClick = function()
                markSeen(false)
                MPOptim.OpenSettingsUI()
            end },
            { label = T("UI_MPOptim_V2_Close", "Close"), style = "neutral", onClick = function() markSeen(false) end },
        },
        cancel = 2,
    })
end

function MPOptim.MainMenu.ShowEngineAgentModal()
    local active = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()
    U.ShowModal({
        title = T("UI_MPOptim_V2_EngineTitle", "PZO Java engine (optional)"),
        width = 660,
        body = {
            { kv = { T("UI_MPOptim_V2_EngineStatus", "Status"), active and T("UI_MPOptim_V2_EngineActive", "Active")
                or T("UI_MPOptim_V2_EngineInactive", "Not installed, the Lua mod works fully on its own") }, col = active and C.good or C.accent },
            { gap = true },
            { p = T("UI_MPOptim_V2_EngineIntro", "The PZO Java engine is a free, open-source add-on that optimizes the game engine itself, beyond what a Lua mod can reach:") },
            { gap = true },
            { bullet = T("UI_MPOptim_V2_EngineB1", "Loads map chunks on several CPU cores"), col = C.good },
            { bullet = T("UI_MPOptim_V2_EngineB2", "Gives the game more memory, sized to your PC"), col = C.good },
            { bullet = T("UI_MPOptim_V2_EngineB3", "Spreads the per-frame scripts of other mods out so they cost less"), col = C.good },
            { bullet = T("UI_MPOptim_V2_EngineB4", "FSR upscaling and the switches on the Java Engine tab"), col = C.good },
            { gap = true },
            { p = T("UI_MPOptim_V2_EngineWhere", "The Steam Workshop can not host it, so it is on GitHub. It only needs installing once."), col = C.dim },
            { kv = { "GitHub", GITHUB_URL }, col = C.accent },
        },
        buttons = {
            { label = T("UI_MPOptim_V2_OpenGitHub", "Open GitHub"), style = "primary", keepOpen = true, onClick = function(modal)
                openLink(GITHUB_URL)
                copyText(GITHUB_URL)
                modal:setStatus(T("UI_MPOptim_V2_OpenedGitHub", "Opened GitHub in your browser and copied the link."))
            end },
            { label = T("UI_MPOptim_V2_CopyLink", "Copy link"), style = "neutral", keepOpen = true, onClick = function(modal)
                copyText(GITHUB_URL)
                modal:setStatus(T("UI_MPOptim_V2_CopiedLink", "Link copied."))
            end },
            { label = T("UI_MPOptim_V2_Close", "Close"), style = "neutral" },
        },
        cancel = 3,
    })
end

-- Shown once by the Java engine after it is installed or updated; onAcknowledge records that it was seen
function MPOptim.MainMenu.ShowEngineNotice(version, fsrActive, onAcknowledge)
    local function ack() if onAcknowledge then pcall(onAcknowledge) end end
    return U.ShowModal({
        title = string.format(T("UI_MPOptim_V2_NoticeTitle", "PZO Java engine v%s is active"), tostring(version)),
        width = 680,
        body = {
            { p = T("UI_MPOptim_V2_NoticeIntro", "Multi-core chunk loading, background simulation and the native timer and power settings are spreading the work of the game over your CPU cores.") },
            { gap = true },
            { kv = { T("UI_MPOptim_V2_NoticeFSR", "FSR upscaling"), fsrActive and T("UI_MPOptim_V2_On", "ON") or T("UI_MPOptim_V2_Off", "OFF") }, col = fsrActive and C.good or C.dim },
            { p = T("UI_MPOptim_V2_NoticeFSRHow", "On a 1440p or 4K screen or a handheld, turn on FSR on the Java Engine tab of the Optimiser settings. The world is drawn at a lower resolution and upscaled; the UI stays sharp."), col = C.dim },
            { gap = true },
            { h = T("UI_MPOptim_V2_NoticeIssues", "Problems?") },
            { p = T("UI_MPOptim_V2_NoticeIssuesBody", "Report crashes or mod conflicts on GitHub or the Steam Workshop page so they can be fixed.") },
            { gap = true },
            { h = T("UI_MPOptim_V2_NoticeLike", "Running better?") },
            { p = T("UI_MPOptim_V2_NoticeLikeBody", "An upvote on the Steam Workshop helps other survivors find PZO.") },
        },
        buttons = {
            { label = T("UI_MPOptim_V2_SteamWorkshop", "Steam Workshop"), style = "primary", keepOpen = true, onClick = function()
                openLink("https://steamcommunity.com/sharedfiles/filedetails/?id=3787481250")
            end },
            { label = T("UI_MPOptim_V2_GitHubIssues", "GitHub issues"), style = "neutral", keepOpen = true, onClick = function()
                openLink(GITHUB_URL .. "/issues")
            end },
            { label = T("UI_MPOptim_V2_GotIt", "Got it"), style = "good", onClick = ack },
        },
        cancel = 3,
        defaultButton = 3,
    })
end

local menuBtnInstance = nil
local cpuBtnInstance = nil
local pzoIconBtn = nil
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

        local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
        local topMargin = math.floor(16 * scale)
        local rightMargin = math.floor(16 * scale)
        local iconSize = math.max(32, math.floor(fontH + 14 * scale))
        local iconX = sw - iconSize - rightMargin
        local iconY = topMargin
        local btnW = math.max(160, math.floor(190 * scale))
        local btnX = iconX - btnW - math.floor(8 * scale)

        if pzoIconBtn then
            if pzoIconBtn:getX() ~= iconX or pzoIconBtn:getY() ~= iconY then
                pzoIconBtn:setX(iconX)
                pzoIconBtn:setY(iconY)
            end
            if pzoIconBtn:isVisible() ~= isRootVisible then
                pzoIconBtn:setVisible(isRootVisible)
                if isRootVisible then pzoIconBtn:bringToTop() end
            end
            local expectedTooltip = isAgent and T("UI_MPOptim_V2_EngineJava", "Engine: Java (active)") or T("UI_MPOptim_V2_EngineLua", "Engine: Lua only")
            if pzoIconBtn.tooltip ~= expectedTooltip then
                pzoIconBtn.tooltip = expectedTooltip
                U.StyleButton(pzoIconBtn, isAgent and "good" or "neutral")
                pzoIconBtn.textureColor = isAgent and { r = 1.0, g = 1.0, b = 1.0, a = 1.0 } or { r = 0.70, g = 0.70, b = 0.75, a = 0.75 }
            end
        end

        if menuBtnInstance then
            if menuBtnInstance:getX() ~= btnX or menuBtnInstance:getY() ~= iconY then
                menuBtnInstance:setX(btnX)
                menuBtnInstance:setY(iconY)
            end
            if menuBtnInstance:isVisible() ~= isRootVisible then
                menuBtnInstance:setVisible(isRootVisible)
                if isRootVisible then menuBtnInstance:bringToTop() end
            end
        end

        if cpuBtnInstance then
            local shouldShowBtn = isRootVisible and (not isAgent)
            if cpuBtnInstance:getX() ~= btnX then cpuBtnInstance:setX(btnX) end
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
            if updateAlertBtn:getX() ~= btnX then updateAlertBtn:setX(btnX) end
            if updateAlertBtn:isVisible() ~= shouldShowUp then
                updateAlertBtn:setVisible(shouldShowUp)
                if shouldShowUp then updateAlertBtn:bringToTop() end
            end
            if shouldShowUp and latestVer then
                local displayVer = tostring(latestVer)
                if string.sub(displayVer, 1, 1) ~= "v" and string.sub(displayVer, 1, 1) ~= "V" then
                    displayVer = "v" .. displayVer
                end
                updateAlertBtn.title = T("UI_MPOptim_V2_UpdateAvailable", "Update available:") .. " " .. displayVer
            end
        end

        if bugReportBtnInstance then
            local shouldShowBug = isRootVisible and (isAgent == true)
            local bugBtnW = math.max(130, math.floor(150 * scale))
            local bugBtnX = btnX + math.floor((btnW - bugBtnW) / 2)
            if bugReportBtnInstance:getX() ~= bugBtnX then bugReportBtnInstance:setX(bugBtnX) end
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
        if pzoIconBtn then pzoIconBtn:setVisible(isRootVisible) end
        if cpuBtnInstance then cpuBtnInstance:setVisible(isRootVisible) end
        return
    end

    local scale, fontH, sw, sh = MPOptim.Utils.GetUIScale()
    local topMargin = math.floor(16 * scale)
    local rightMargin = math.floor(16 * scale)
    local iconSize = math.max(32, math.floor(fontH + 14 * scale))
    local iconX = sw - iconSize - rightMargin
    local iconY = topMargin

    local btnW = math.max(160, math.floor(190 * scale))
    local btnH = iconSize
    local btnX = iconX - btnW - math.floor(8 * scale)
    local btnY = topMargin

    local isAgent = MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected()

    local iconTex = getTexture("media/ui/app.png") or getTexture("media/ui/pzo_icon.png") or getTexture("media/ui/app.ico") or getTexture("icon.png")
    pzoIconBtn = ISButton:new(iconX, iconY, iconSize, iconSize, "", nil, function()
        MPOptim.MainMenu.ShowEngineAgentModal()
    end)
    pzoIconBtn:initialise()
    if iconTex then
        pzoIconBtn:setImage(iconTex)
        pzoIconBtn.forcedWidthImage = iconSize - 6
        pzoIconBtn.forcedHeightImage = iconSize - 6
    else
        pzoIconBtn.title = "PZO"
    end
    U.StyleButton(pzoIconBtn, isAgent and "good" or "neutral")
    pzoIconBtn.textureColor = isAgent and { r = 1.0, g = 1.0, b = 1.0, a = 1.0 } or { r = 0.70, g = 0.70, b = 0.75, a = 0.75 }
    pzoIconBtn.tooltip = isAgent and T("UI_MPOptim_V2_EngineJava", "Engine: Java (active)") or T("UI_MPOptim_V2_EngineLua", "Engine: Lua only")
    mainScreen:addChild(pzoIconBtn)

    menuBtnInstance = ISButton:new(btnX, btnY, btnW, btnH, T("UI_MPOptim_V2_MenuOptimiser", "Optimiser"), nil, function()
        if isCtrlKeyDown and isCtrlKeyDown() then
            MPOptim.ToggleDevMode()
        else
            MPOptim.OpenSettingsUI()
        end
    end)
    menuBtnInstance:initialise()
    U.StyleButton(menuBtnInstance, "primary")
    mainScreen:addChild(menuBtnInstance)

    local getAgentY = btnY + btnH + math.floor(6 * scale)
    cpuBtnInstance = ISButton:new(btnX, getAgentY, btnW, btnH, T("UI_MPOptim_V2_MenuGetEngine", "Get the Java engine"), nil, function()
        MPOptim.MainMenu.ShowEngineAgentModal()
    end)
    cpuBtnInstance:initialise()
    U.StyleButton(cpuBtnInstance, "neutral")
    cpuBtnInstance.tooltip = T("UI_MPOptim_V2_MenuGetEngineTip", "Optional. The mod works fully without it. Shows what the Java engine adds and where to get it.")
    mainScreen:addChild(cpuBtnInstance)

    local bugBtnW = math.max(130, math.floor(150 * scale))
    local bugBtnH = math.max(22, math.floor(fontH + 6 * scale))
    local bugBtnX = btnX + math.floor((btnW - bugBtnW) / 2)
    local bugBtnY = btnY + btnH + math.floor(6 * scale)

    bugReportBtnInstance = ISButton:new(bugBtnX, bugBtnY, bugBtnW, bugBtnH, T("UI_MPOptim_V2_MenuReportBug", "Report a bug"), nil, function()
        if MPOptim.BugReporter and MPOptim.BugReporter.OpenModal then
            MPOptim.BugReporter.OpenModal()
        end
    end)
    bugReportBtnInstance:initialise()
    U.StyleButton(bugReportBtnInstance, "neutral")
    bugReportBtnInstance.tooltip = T("UI_MPOptim_V2_MenuReportBugTip", "Copies your diagnostics and shows where your log files are, to attach to a GitHub issue.")
    mainScreen:addChild(bugReportBtnInstance)

    local hasUpdate, latestVer, updateUrl = MPOptim.Utils.CheckGitHubUpdate and MPOptim.Utils.CheckGitHubUpdate()
    local updateBtnY = bugBtnY + bugBtnH + math.floor(4 * scale)

    local displayVer = latestVer and tostring(latestVer) or "0.4"
    if string.sub(displayVer, 1, 1) ~= "v" and string.sub(displayVer, 1, 1) ~= "V" then
        displayVer = "v" .. displayVer
    end
    updateAlertBtn = ISButton:new(btnX, updateBtnY, btnW, btnH, T("UI_MPOptim_V2_UpdateAvailable", "Update available:") .. " " .. displayVer, nil, function()
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
    U.StyleButton(updateAlertBtn, "warn")
    updateAlertBtn.tooltip = T("UI_MPOptim_V2_UpdateAvailableTip", "A newer PZO Java engine is on GitHub. Click to open the download page.")
    mainScreen:addChild(updateAlertBtn)

    local isRootVisible = mainScreen.bottomPanel and mainScreen.bottomPanel:isVisible() == true
    menuBtnInstance:setVisible(isRootVisible)
    if pzoIconBtn then pzoIconBtn:setVisible(isRootVisible) end
    if cpuBtnInstance then cpuBtnInstance:setVisible(isRootVisible and (not isAgent)) end
    if bugReportBtnInstance then bugReportBtnInstance:setVisible(isRootVisible and (isAgent == true)) end
    if updateAlertBtn then updateAlertBtn:setVisible(isRootVisible and hasUpdate == true) end

    local isFirst = MPOptim.MainMenu.ShowFirstLaunchModal()
    if not isFirst then
        MPOptim.MainMenu.ShowUpdateModal()
    end
end

Events.OnMainMenuEnter.Add(MPOptim.MainMenu.InjectButton)


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
