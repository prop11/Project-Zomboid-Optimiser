--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_ContextMenu.lua
    Author: prop11
    Description: Right-click world context menu integration with admin multiplayer security.
--]]

require "MPOptim_Config"
require "MPOptim_Utils"

local function onFillWorldObjectContextMenu(player, context, worldobjects, test)
    if test and ISWorldObjectContextMenu and ISWorldObjectContextMenu.Test then return true end

    -- Check if right-click context menu is enabled in user settings
    if MPOptim.Config and not MPOptim.Config.Get("UI_ShowContextMenu") then
        return
    end

    local playerObj = (getSpecificPlayer and getSpecificPlayer(player)) or (getPlayer and getPlayer())
    if not playerObj then return end

    local isMP = isClient and isClient()
    local accessLevel = playerObj.getAccessLevel and playerObj:getAccessLevel()
    local isAdmin = MPOptim.Utils and MPOptim.Utils.IsAdmin and MPOptim.Utils.IsAdmin(playerObj)

    local title = MPOptim.GetText("UI_MPOptim_Title", "Project Zomboid Optimiser")
    local rootOption = context:addOption(title, worldobjects, nil)
    local subMenu = ISContextMenu:getNew(context)
    context:addSubMenu(rootOption, subMenu)

    subMenu:addOption(MPOptim.GetText("UI_MPOptim_OpenPanel", "Open Control Panel (F10)"), nil, function()
        if MPOptim.OpenSettingsUI then MPOptim.OpenSettingsUI() end
    end)

    subMenu:addOption(MPOptim.GetText("UI_MPOptim_PurgeRAM", "Instant Memory Purge (GC)"), nil, function()
        local freed = 0
        if MPOptim.GCOptimizer and MPOptim.GCOptimizer.PurgeMemory then
            freed = MPOptim.GCOptimizer.PurgeMemory()
        end
        if MPOptim.Utils and MPOptim.Utils.Notify then
            local msg = string.format(MPOptim.GetText("UI_MPOptim_FreedRAM", "Freed %.1f MB RAM"), freed)
            MPOptim.Utils.Notify(playerObj, msg, true)
        end
    end)

    subMenu:addOption(MPOptim.GetText("UI_MPOptim_ToggleHUD", "Toggle Performance HUD"), nil, function()
        if MPOptim.ToggleHUD then MPOptim.ToggleHUD() end
    end)

    -- In Multiplayer, world cleanups (Blood, Corpses, Debris) are strictly restricted to Admins
    if isAdmin then
        subMenu:addOption(MPOptim.GetText("UI_MPOptim_CleanBloodArea", "Clean Blood in Area (30m)"), nil, function()
            if MPOptim.ClientCleaner then MPOptim.ClientCleaner.QuickClean("blood", 30) end
        end)

        subMenu:addOption(MPOptim.GetText("UI_MPOptim_CleanCorpseArea", "Clean Corpses in Area (30m)"), nil, function()
            if MPOptim.ClientCleaner then MPOptim.ClientCleaner.QuickClean("corpse", 30) end
        end)

        subMenu:addOption(MPOptim.GetText("UI_MPOptim_CleanDebrisArea", "Clean Ground Debris (35m)"), nil, function()
            if MPOptim.ClientCleaner then MPOptim.ClientCleaner.QuickClean("debris", 35) end
        end)

        if isMP then
            subMenu:addOption(MPOptim.GetText("UI_MPOptim_AdminCleanArea", "Admin: Synchronized Server Clean (75m)"), nil, function()
                if MPOptim.Network and MPOptim.Network.SendAdminCleanRequest then
                    MPOptim.Network.SendAdminCleanRequest(math.floor(playerObj:getX()), math.floor(playerObj:getY()), math.floor(playerObj:getZ()), 75)
                elseif MPOptim.ClientCleaner then
                    MPOptim.ClientCleaner.QuickClean("all", 75)
                end
            end)
        end
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
