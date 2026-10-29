--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_UI_SettingsV2.lua
    Author: prop11
    Description: Settings screen: sidebar with presets and tabs, one card per setting showing what it saves or costs
                 and a verdict for this PC, switch and value on separate rows, a dashboard with maintenance tools,
                 live stats and saved presets, the mod profiler, and full controller support.
--]]

require "ISUI/ISPanelJoypad"
require "MPOptim_Config"
require "MPOptim_Utils"
require "MPOptim_UIStyle"
require "MPOptim_SettingsRegistry"
require "MPOptim_CustomPresets"
require "MPOptim_ClientCleaner"
require "MPOptim_GCOptimizer"
require "MPOptim_ModProfiler"

MPOptim = MPOptim or {}
local S = MPOptim.Settings
local U = MPOptim.UI
local C, T, measure, wrap, icon = U.C, U.T, U.measure, U.wrap, U.icon
local rect, border, text = U.rect, U.border, U.text

local UI = ISPanelJoypad:derive("MPOptim_SettingsV2")
local instance = nil

local function isOn(key)
    return MPOptim.Config ~= nil and MPOptim.Config.Get(key) == true
end

local function isAgent()
    return MPOptim.Utils and MPOptim.Utils.IsEngineAgentInjected and MPOptim.Utils.IsEngineAgentInjected() == true
end

local function inWorld()
    return (getPlayer and getPlayer()) ~= nil
end

local function isMPAdmin()
    local p = getPlayer and getPlayer()
    return p ~= nil and isClient and isClient() and MPOptim.Utils.IsAdmin and MPOptim.Utils.IsAdmin(p) == true
end

local function textKey(s)
    return s.key or (s.values and s.values[1] and s.values[1].key) or ""
end

local function settingLabel(s)
    return T("UI_MPOptim_Set_" .. textKey(s), s.label)
end

local function settingTip(s)
    return T("UI_MPOptim_SetTip_" .. textKey(s), s.tip or "")
end

local function cardLocked(s)
    return s.inactive ~= nil or (s.needsJava == true and not isAgent()) or (s.requires ~= nil and not isOn(s.requires))
end

-- Why a card can not be switched, shown where its effects would be
local function lockReason(s)
    if s.needsJava and not isAgent() then return T("UI_MPOptim_V2_NeedsJava", "Needs the PZO Java engine") end
    if s.requires and not isOn(s.requires) then
        local master = S.Find(s.requires)
        local name = master and T("UI_MPOptim_Set_" .. master.key, master.label) or s.requires
        return T("UI_MPOptim_V2_NeedsMaster", "Needs this on first:") .. " " .. name
    end
    return nil
end

local function valueLocked(s)
    return cardLocked(s) or (s.key ~= nil and not isOn(s.key))
end

local function afterChange()
    if MPOptim.HordeOptimizer and MPOptim.HordeOptimizer.Apply then MPOptim.HordeOptimizer.Apply() end
end

local function sectionRow(key, fallback)
    return { kind = "section", text = T("UI_MPOptim_Section_" .. key, fallback) }
end

-- Dashboard actions ------------------------------------------------------------------------------------------------

local function needsWorldAndAdmin()
    if not inWorld() then return T("UI_MPOptim_V2_OnlyInGame", "Only works in a game") end
    if isClient and isClient() and not isMPAdmin() then
        return T("UI_MPOptim_V2_AdminOnly", "Only server admins can do this in multiplayer")
    end
    return nil
end

local function cleanAction(id, kind, title, tip, style)
    return { kind = "action", id = id, title = title, tip = tip, button = T("UI_MPOptim_V2_Run", "Run"), style = style or "primary",
        lock = needsWorldAndAdmin,
        run = function(ui)
            MPOptim.ClientCleaner.QuickClean(kind)
            ui:flash(T("UI_MPOptim_V2_CleanStarted", "Cleanup started around you."))
        end }
end

local RATING = {
    ["LIGHT"]     = { key = "UI_MPOptim_V2_RatingLight",    text = "Light",     col = C.good,
                      descKey = "UI_MPOptim_V2_RatingLightDesc", desc = "Few or light event hooks. Hardly any cost per frame." },
    ["MODERATE"]  = { key = "UI_MPOptim_V2_RatingModerate", text = "Moderate",  col = { 0.95, 0.85, 0.30 },
                      descKey = "UI_MPOptim_V2_RatingModerateDesc", desc = "Some periodic or per-action hooks. Small cost." },
    ["HIGH"]      = { key = "UI_MPOptim_V2_RatingHigh",     text = "High",      col = C.warn,
                      descKey = "UI_MPOptim_V2_RatingHighDesc", desc = "Frequent update hooks. Noticeable cost while playing." },
    ["VERY HIGH"] = { key = "UI_MPOptim_V2_RatingVeryHigh", text = "Very high", col = C.bad,
                      descKey = "UI_MPOptim_V2_RatingVeryHighDesc", desc = "Runs code every frame or holds a lot of memory. Likely to cost FPS." },
}

local function fmtBytes(bytes)
    local kb = math.floor((bytes or 0) / 1024)
    if kb >= 1024 then return string.format("%.1f MB", kb / 1024) end
    return string.format("%d KB", kb)
end

-- Construction & layout --------------------------------------------------------------------------------------------

function UI:new(x, y, w, h)
    local o = ISPanelJoypad:new(x, y, w, h)
    setmetatable(o, self)
    self.__index = self
    o.background = false
    o.tabIndex = 1
    o.scrollY = 0
    o.focusArea = "content"
    o.focusIndex = 1
    o.sideIndex = 1
    o.rows = {}
    o.hw = S.Hardware()
    o.hwPoll = 0
    o.flashText = nil
    o.flashFrames = 0
    o.statsAt = 0
    return o
end

function UI:initialise()
    ISPanelJoypad.initialise(self)
    self:layout()
end

function UI:layout()
    local m = U.metrics()
    self.scale = m.scale
    self.fS, self.fM, self.fh, self.fhM, self.pad = m.fS, m.fM, m.fh, m.fhM, m.pad
    self.btnH = m.btnH
    self.headerH = self.fhM + self.pad * 2
    self.footerH = self.fh + self.pad * 2
    self.sideW = math.max(180, math.floor(210 * self.scale))
    self.cx = self.sideW
    self.cy = self.headerH
    self.cw = self.width - self.sideW
    self.ch = self.height - self.headerH - self.footerH
    self.closeW = self.headerH - self.pad
    self:buildSide()
    self:buildRows()
end

function UI:buildSide()
    local items = {}
    items[#items + 1] = { kind = "heading", text = T("UI_MPOptim_V2_Presets", "Presets") }
    local presets = {
        { key = "Balanced", text = T("UI_MPOptim_Preset_Balanced", "Balanced") },
        { key = "Potato", text = T("UI_MPOptim_Preset_Aggressive", "Max Performance") },
        { key = "Experimental", text = T("UI_MPOptim_V2_PresetExperimental", "Experimental") },
    }
    if isMPAdmin() then
        presets[#presets + 1] = { key = "Server", text = T("UI_MPOptim_Preset_Server", "Dedicated Server") }
    end
    if MPOptim.DevMode then
        presets[#presets + 1] = { key = "TestModeVanilla", text = "Vanilla benchmark", dev = true }
    end
    for _, pr in ipairs(presets) do
        items[#items + 1] = { kind = "preset", key = pr.key, text = pr.text, dev = pr.dev }
    end
    items[#items + 1] = { kind = "alloptim", text = T("UI_MPOptim_V2_AllOptimizations", "All optimizations") }
    items[#items + 1] = { kind = "heading", text = T("UI_MPOptim_V2_Settings", "Settings") }
    for i, tab in ipairs(S.Tabs) do
        items[#items + 1] = { kind = "tab", index = i, text = T(tab.textKey, tab.label) }
    end
    if MPOptim.DevMode then
        items[#items + 1] = { kind = "heading", text = "" }
        items[#items + 1] = { kind = "exitdev", text = "Exit developer mode" }
    end

    local y = self.headerH + math.floor(self.pad * 0.5)
    local itemH = self.fh + math.floor(10 * self.scale)
    for _, it in ipairs(items) do
        it.y = y
        it.h = (it.kind == "heading") and (self.fh + math.floor(6 * self.scale)) or itemH
        y = y + it.h
    end
    self.sideItems = items
    self.sideSelectable = {}
    for i, it in ipairs(items) do
        if it.kind ~= "heading" then self.sideSelectable[#self.sideSelectable + 1] = i end
    end
end

function UI:addRegistryRows(rows, tabId)
    local section = nil
    for _, s in ipairs(S.ForTab(tabId)) do
        if s.section ~= section then
            section = s.section
            rows[#rows + 1] = sectionRow(string.gsub(section, "[^%w]", ""), section)
        end
        rows[#rows + 1] = { kind = "card", s = s }
        local vals = S.ValuesOf(s)
        for vi, v in ipairs(vals) do
            rows[#rows + 1] = { kind = "value", s = s, v = v, first = (vi == 1), last = (vi == #vals) }
        end
    end
end

function UI:addDashboardRows(rows)
    rows[#rows + 1] = sectionRow("LiveStats", "Live stats")
    rows[#rows + 1] = { kind = "stats" }

    rows[#rows + 1] = sectionRow("Maintenance", "Maintenance")
    rows[#rows + 1] = { kind = "action", id = "purge", style = "primary",
        title = T("UI_MPOptim_V2_ActPurge", "Free Lua memory now"),
        tip = T("UI_MPOptim_V2_ActPurgeTip", "Runs one full garbage collection to return memory held by finished scripts. Expect a short pause."),
        button = T("UI_MPOptim_V2_Run", "Run"),
        run = function(ui)
            local freed = MPOptim.GCOptimizer and MPOptim.GCOptimizer.PurgeMemory and MPOptim.GCOptimizer.PurgeMemory() or 0
            ui:flash(string.format(T("UI_MPOptim_FreedRAM", "Freed %.1f MB RAM"), freed))
        end }
    rows[#rows + 1] = cleanAction("blood", "blood", T("UI_MPOptim_V2_ActBlood", "Clean blood around you"),
        T("UI_MPOptim_V2_ActBloodTip", "Removes floor blood within your cleanup radius, and wall blood if that option is on."))
    rows[#rows + 1] = cleanAction("corpse", "corpse", T("UI_MPOptim_V2_ActCorpse", "Clean corpses around you"),
        T("UI_MPOptim_V2_ActCorpseTip", "Removes corpses within your cleanup radius using your corpse rules. Corpses carrying weapons, bags, ammo or keys are kept."))
    rows[#rows + 1] = cleanAction("debris", "debris", T("UI_MPOptim_V2_ActDebris", "Clean ground debris around you"),
        T("UI_MPOptim_V2_ActDebrisTip", "Removes the debris types switched on in World Cleanup: casings, empty tins, glass, twigs, rotten food."))
    rows[#rows + 1] = cleanAction("all", "all", T("UI_MPOptim_V2_ActAll", "Full sweep around you"),
        T("UI_MPOptim_V2_ActAllTip", "Blood, corpses and debris in one pass."), "good")

    self:addRegistryRows(rows, "dashboard")

    rows[#rows + 1] = sectionRow("SavedPresets", "Saved presets")
    local list = (MPOptim.CustomPresets and MPOptim.CustomPresets.GetList()) or {}
    local builtIn = (MPOptim.CustomPresets and MPOptim.CustomPresets.BuiltIn) or {}
    for _, name in ipairs(list) do
        local count = 0
        for _ in pairs(MPOptim.CustomPresets.Data[name] or {}) do count = count + 1 end
        rows[#rows + 1] = { kind = "preset", name = name, builtIn = builtIn[name] == true, count = count }
    end
    rows[#rows + 1] = { kind = "action", id = "savepreset", style = "primary",
        title = T("UI_MPOptim_V2_ActSavePreset", "Save current settings as a preset"),
        tip = T("UI_MPOptim_V2_ActSavePresetTip", "Stores every setting as it is now under a name, to load again later."),
        button = T("UI_MPOptim_V2_Save", "Save"),
        run = function(ui) ui:promptSavePreset() end }

    rows[#rows + 1] = sectionRow("AllSettings", "All settings")
    if isMPAdmin() then
        rows[#rows + 1] = { kind = "action", id = "sync", style = "primary",
            title = T("UI_MPOptim_V2_ActSync", "Send settings to the server"),
            tip = T("UI_MPOptim_V2_ActSyncTip", "Saves your current settings as the server's Optimiser settings."),
            button = T("UI_MPOptim_V2_Send", "Send"),
            run = function(ui)
                if MPOptim.Network and MPOptim.Network.SendAdminConfigUpdate then
                    MPOptim.Network.SendAdminConfigUpdate(MPOptim.Config and MPOptim.Config.Current)
                    ui:flash(T("UI_MPOptim_SyncSending", "Sent Optimiser settings to server..."))
                end
            end }
    end
    rows[#rows + 1] = { kind = "action", id = "reset", style = "danger",
        title = T("UI_MPOptim_V2_ActReset", "Reset everything to defaults"),
        tip = T("UI_MPOptim_V2_ActResetTip", "Puts every setting on every tab back to how it was when the mod was installed."),
        button = T("UI_MPOptim_V2_Reset", "Reset"),
        run = function(ui)
            U.Confirm(T("UI_MPOptim_V2_ActReset", "Reset everything to defaults"),
                T("UI_MPOptim_V2_ResetConfirm", "Every setting goes back to its default. Saved presets are kept."),
                T("UI_MPOptim_V2_Reset", "Reset"), function()
                    if MPOptim.Config and MPOptim.Config.ResetDefaults then MPOptim.Config.ResetDefaults() end
                    afterChange()
                    ui:flash(T("UI_MPOptim_V2_ResetDone", "All settings are back to their defaults."))
                end, true)
        end }
end

function UI:addProfilerRows(rows)
    if not self.profilerData and MPOptim.ModProfiler and MPOptim.ModProfiler.Scan then
        local ok, data = pcall(MPOptim.ModProfiler.Scan)
        self.profilerData = ok and data or { mods = {} }
    end
    local pd = self.profilerData or { mods = {} }
    rows[#rows + 1] = sectionRow("Overview", "Overview")
    rows[#rows + 1] = { kind = "action", id = "rescan", style = "primary",
        title = string.format(T("UI_MPOptim_V2_ProfilerSummary", "%d mods, %d event hooks, %.1f MB Lua memory"),
            pd.totalMods or 0, pd.totalHooks or 0, pd.totalMemoryMB or 0),
        tip = T("UI_MPOptim_V2_ProfilerTip", "Estimates how much Lua memory each mod holds and which game events it listens to. Heaviest first. Select a mod for details."),
        button = T("UI_MPOptim_V2_Rescan", "Scan again"),
        run = function(ui)
            ui.profilerData = nil
            ui:buildRows(true)
        end }
    rows[#rows + 1] = sectionRow("Mods", "Mods")
    for _, mod in ipairs(pd.mods or {}) do
        rows[#rows + 1] = { kind = "mod", mod = mod, expanded = (self.expandedMod == (mod.id or mod.name)) }
    end
end

function UI:buildRows(keepPlace)
    local tab = S.Tabs[self.tabIndex]
    local rows = {}
    if tab.id == "dashboard" then
        self:addDashboardRows(rows)
    elseif tab.id == "profiler" then
        self:addProfilerRows(rows)
    else
        if tab.id == "java" and not isAgent() then
            rows[#rows + 1] = { kind = "action", id = "getengine", style = "primary",
                title = T("UI_MPOptim_V2_MenuGetEngine", "Get the Java engine"),
                tip = T("UI_MPOptim_V2_GetEngineTip", "The settings on this tab need the optional PZO Java engine. See what it adds and where to get it."),
                button = T("UI_MPOptim_V2_Details", "Details"),
                run = function() if MPOptim.MainMenu and MPOptim.MainMenu.ShowEngineAgentModal then MPOptim.MainMenu.ShowEngineAgentModal() end end }
        end
        self:addRegistryRows(rows, tab.id)
    end
    self.rows = rows
    self:measureRows()
    self.focusables = {}
    for i, r in ipairs(rows) do
        local k = r.kind
        local focusable = (k == "value") or (k == "action") or (k == "preset") or (k == "mod") or (k == "card" and r.s.key ~= nil)
        if focusable then self.focusables[#self.focusables + 1] = i end
    end
    self.focusIndex = math.max(1, math.min(self.focusIndex, #self.focusables))
    if keepPlace then self:clampScroll() else self.scrollY = 0 end
end

function UI:actionButtonW()
    return math.floor(130 * self.scale)
end

function UI:modDetail(mod, textW)
    local lines = {}
    local function add(str, col)
        for _, l in ipairs(wrap(self.fS, str, textW)) do lines[#lines + 1] = { text = l, col = col or C.dim } end
    end
    local info = RATING[mod.rating] or RATING.LIGHT
    add(T(info.descKey, info.desc), info.col)
    add(string.format(T("UI_MPOptim_V2_ModMeta", "ID: %s   Author: %s   Version: %s"), tostring(mod.id), tostring(mod.author), tostring(mod.version)))
    add(string.format(T("UI_MPOptim_V2_ModMemory", "Lua memory: %s in %d tables and %d functions"), fmtBytes(mod.estimatedBytes), mod.tableCount or 0, mod.closureCount or 0))
    local ns = mod.namespaces or {}
    if #ns > 0 then
        add(T("UI_MPOptim_V2_ModGlobals", "Global names:") .. " " .. table.concat(ns, ", "))
    end
    local hooks = mod.hooks or {}
    if #hooks == 0 then
        add(T("UI_MPOptim_V2_ModNoHooks", "Listens to no game events."))
    else
        add(string.format(T("UI_MPOptim_V2_ModHooks", "Listens to %d game events:"), mod.hookCount or #hooks), C.text)
        for _, h in ipairs(hooks) do
            local desc = tostring(h.desc or "")
            local line = tostring(h.event)
            if desc ~= "" and desc ~= line and desc ~= line .. "()" then line = line .. "  (" .. desc .. ")" end
            local c = h.color and { h.color.r, h.color.g, h.color.b } or C.dim
            lines[#lines + 1] = { tag = "[" .. tostring(h.tag or "EVENT") .. "]", tagCol = c, text = U.trim(self.fS, line, textW - math.floor(90 * self.scale)), col = C.text }
        end
    end
    return lines
end

function UI:measureRows()
    local pad = self.pad
    local cardW = self.cw - pad * 2
    self.cardW = cardW
    self.switchW = math.floor(64 * self.scale)
    self.badgeH = math.floor(22 * self.scale)
    local textW = cardW - pad * 3 - self.switchW
    local actionTextW = cardW - pad * 3 - self:actionButtonW() * 2
    local y = pad
    for _, r in ipairs(self.rows) do
        if r.kind == "section" then
            r.h = self.fh + math.floor(pad * 0.8)
        elseif r.kind == "card" then
            r.lines = wrap(self.fS, settingTip(r.s), textW)
            local note = r.s.inactive or (r.s.note and T("UI_MPOptim_SetNote_" .. textKey(r.s), r.s.note))
            r.noteLines = note and wrap(self.fS, note, textW) or nil
            -- a plain preference has no verdict, impact or lock line to show
            local hasBadges = not r.s.noVerdict or r.s.impact ~= nil or r.s.requires ~= nil or r.s.needsJava == true
            r.h = pad + self.fhM + 4 + #r.lines * self.fh + (r.noteLines and #r.noteLines * self.fh or 0) + (hasBadges and (6 + self.badgeH) or 0) + pad
        elseif r.kind == "value" then
            r.h = ((r.first and r.s.valueHint) and self.fh * 2 or self.fh) + pad
        elseif r.kind == "action" then
            r.lines = wrap(self.fS, r.tip, cardW - pad * 3 - self:actionButtonW())
            -- actions that can be locked keep a line for the reason
            r.h = math.max(pad + self.fhM + 4 + (#r.lines + (r.lock and 1 or 0)) * self.fh + pad, self.btnH + pad * 2)
        elseif r.kind == "stats" then
            r.h = pad * 2 + math.ceil(9 / 2) * (self.fh + math.floor(6 * self.scale))
        elseif r.kind == "preset" then
            r.h = pad * 2 + self.fhM + self.fh
        elseif r.kind == "mod" then
            r.detail = r.expanded and self:modDetail(r.mod, cardW - pad * 2) or nil
            r.h = pad + self.fhM + 4 + self.fh + pad + (r.detail and (#r.detail * self.fh + pad) or 0)
        end
        r.y = y
        -- A value row sits directly under its card as part of it
        local joined = (r.kind == "card" and #S.ValuesOf(r.s) > 0) or (r.kind == "value" and not r.last)
        y = y + r.h + (joined and 0 or math.floor(8 * self.scale))
    end
    self.contentH = y + pad
    self.actionTextW = actionTextW
end

-- Actions ----------------------------------------------------------------------------------------------------------

function UI:flash(msg)
    self.flashText = msg
    self.flashFrames = 300
    local p = getPlayer and getPlayer()
    if p and MPOptim.Utils.Notify then MPOptim.Utils.Notify(p, msg, true) end
end

function UI:toggle(s)
    if not s.key or cardLocked(s) then return end
    local on = not isOn(s.key)
    MPOptim.Config.Set(s.key, on)
    MPOptim.Config.Save()
    if s.onChange then pcall(s.onChange, on) end
end

function UI:step(s, v, dir)
    if not v or valueLocked(s) then return end
    local values, cur = v.values, MPOptim.Config.Get(v.key)
    local idx = 1
    for i, val in ipairs(values) do
        if val == cur then idx = i break end
        if type(cur) == "number" and val <= cur then idx = i end
    end
    idx = math.max(1, math.min(#values, idx + dir))
    MPOptim.Config.Set(v.key, values[idx])
    MPOptim.Config.Save()
    if s.onValueChange then pcall(s.onValueChange, values[idx]) else afterChange() end
end

function UI:resetToDefault(s)
    local defaults = MPOptim.DefaultConfig or {}
    if s.key and defaults[s.key] ~= nil and not cardLocked(s) then
        MPOptim.Config.Set(s.key, defaults[s.key])
        if s.onChange then pcall(s.onChange, defaults[s.key]) end
    end
    for _, v in ipairs(S.ValuesOf(s)) do
        if defaults[v.key] ~= nil then
            MPOptim.Config.Set(v.key, defaults[v.key])
            if s.onValueChange then pcall(s.onValueChange, defaults[v.key]) end
        end
    end
    MPOptim.Config.Save()
    afterChange()
end

function UI:setTabIndex(i)
    if i < 1 then i = #S.Tabs elseif i > #S.Tabs then i = 1 end
    self.tabIndex = i
    self.focusIndex = 1
    self:buildRows()
end

function UI:applyPreset(key)
    if MPOptim.Config and MPOptim.Config.ApplyPreset then MPOptim.Config.ApplyPreset(key) end
    afterChange()
    self:flash(T("UI_MPOptim_LoadedPreset", "Loaded Preset: ") .. key)
end

function UI:loadSavedPreset(name)
    if MPOptim.CustomPresets.LoadPreset(name) then
        afterChange()
        self:flash(T("UI_MPOptim_LoadedPreset", "Loaded Preset: ") .. name)
    end
end

function UI:deleteSavedPreset(name)
    U.Confirm(T("UI_MPOptim_V2_DeletePreset", "Delete preset"),
        string.format(T("UI_MPOptim_V2_DeletePresetConfirm", "Delete the saved preset \"%s\"? This can not be undone."), name),
        T("UI_MPOptim_V2_Delete", "Delete"), function()
            MPOptim.CustomPresets.DeletePreset(name)
            self:buildRows(true)
        end, true)
end

function UI:promptSavePreset()
    local list = MPOptim.CustomPresets.GetList()
    local taken = {}
    for _, n in ipairs(list) do taken[n] = true end
    local base = T("UI_MPOptim_V2_PresetDefaultName", "My preset")
    local name, n = base, 1
    while taken[name] do
        n = n + 1
        name = base .. " " .. n
    end
    U.ShowModal({
        title = T("UI_MPOptim_V2_ActSavePreset", "Save current settings as a preset"),
        width = 520,
        body = { { p = T("UI_MPOptim_V2_SavePresetBody", "Name for this preset. Saving under an existing name replaces it.") } },
        entry = name,
        buttons = {
            { label = T("UI_MPOptim_V2_Save", "Save"), style = "good", onClick = function(modal)
                local txt = modal:entryText()
                txt = txt and string.match(txt, "^%s*(.-)%s*$") or ""
                if txt == "" then
                    modal:setStatus(T("UI_MPOptim_V2_NameEmpty", "Type a name first."), C.warn)
                    return true
                end
                MPOptim.CustomPresets.SavePreset(txt, MPOptim.Config.Current)
                self:buildRows(true)
                self:flash(T("UI_MPOptim_V2_PresetSaved", "Saved preset:") .. " " .. txt)
            end },
            { label = T("UI_MPOptim_V2_Cancel", "Cancel"), style = "neutral" },
        },
        cancel = 2,
    })
end

function UI:exitDevMode()
    MPOptim.DevMode = false
    MPOptim.OpenSettingsUI(true)
end

function UI:activateSide(it)
    if not it then return end
    if it.kind == "preset" then
        self:applyPreset(it.key)
    elseif it.kind == "alloptim" then
        S.ApplyAllOptimizations()
        afterChange()
        self:flash(T("UI_MPOptim_V2_AllOptimizationsApplied", "Every optimization on this screen is now on."))
    elseif it.kind == "tab" then
        self:setTabIndex(it.index)
    elseif it.kind == "exitdev" then
        self:exitDevMode()
    end
end

-- Load and delete boxes of a saved preset row, relative to the content area
function UI:presetButtons()
    local bw = self:actionButtonW()
    local gap = math.floor(8 * self.scale)
    local right = self.pad + self.cardW - self.pad
    return right - bw * 2 - gap, right - bw, bw
end

function UI:activateRow(r, lx, alt)
    if not r then return end
    if r.kind == "card" then
        self:toggle(r.s)
    elseif r.kind == "value" then
        local boxX, boxW = self:valueBox()
        if lx and lx >= boxX and lx <= boxX + boxW then
            self:step(r.s, r.v, (lx < boxX + boxW / 2) and -1 or 1)
        end
    elseif r.kind == "action" then
        local reason = r.lock and r.lock() or nil
        if reason then
            self:flash(reason)
        else
            r.run(self)
        end
    elseif r.kind == "preset" then
        local loadX, delX, bw = self:presetButtons()
        local wantDelete = alt or (lx and lx >= delX and lx < delX + bw)
        if wantDelete then
            if not r.builtIn then self:deleteSavedPreset(r.name) end
        elseif alt == nil and lx and not (lx >= loadX and lx < loadX + bw) then
            return
        else
            self:loadSavedPreset(r.name)
        end
    elseif r.kind == "mod" then
        local id = r.mod.id or r.mod.name
        self.expandedMod = (self.expandedMod == id) and nil or id
        self:buildRows(true)
    end
end

-- Value box position inside a card, relative to the content area
function UI:valueBox()
    local w = math.floor(170 * self.scale)
    return self.pad + self.cardW - self.pad - w, w
end

-- Hit testing ------------------------------------------------------------------------------------------------------

function UI:rowAtContentY(cy)
    local y = cy + self.scrollY
    for i, r in ipairs(self.rows) do
        if y >= r.y and y < r.y + r.h then return i, r end
    end
    return nil
end

function UI:sideAt(y)
    for i, it in ipairs(self.sideItems) do
        if it.kind ~= "heading" and y >= it.y and y < it.y + it.h then return i, it end
    end
    return nil
end

function UI:clampScroll()
    local maxScroll = math.max(0, self.contentH - self.ch)
    self.scrollY = math.max(0, math.min(maxScroll, self.scrollY))
end

function UI:ensureVisible(rowIdx)
    local r = self.rows[rowIdx]
    if not r then return end
    -- keep the whole card with its value rows in view
    local first, last = rowIdx, rowIdx
    while self.rows[first].kind == "value" and self.rows[first - 1] do first = first - 1 end
    while self.rows[last + 1] and self.rows[last + 1].kind == "value" do last = last + 1 end
    local top = self.rows[first].y
    local bottom = self.rows[last].y + self.rows[last].h
    if bottom + self.pad > self.scrollY + self.ch then self.scrollY = bottom + self.pad - self.ch end
    if top - self.pad < self.scrollY then self.scrollY = top - self.pad end
    -- the first item of a tab also shows the section heading above it
    if self.focusIndex == 1 then self.scrollY = 0 end
    self:clampScroll()
end

-- Mouse ------------------------------------------------------------------------------------------------------------

function UI:onMouseDown(x, y)
    if not self:getIsVisible() then return false end
    if U.anyModalOpen() then return true end
    self:bringToTop()
    if y < self.headerH then
        if x >= self.width - self.closeW - self.pad then
            self:close()
        else
            self.dragging = true
        end
        return true
    end
    if x < self.sideW then
        local i, it = self:sideAt(y)
        if it then
            self.focusArea = "side"
            for n, idx in ipairs(self.sideSelectable) do
                if idx == i then self.sideIndex = n end
            end
            self:activateSide(it)
        end
        return true
    end
    if y < self.cy + self.ch then
        local i, r = self:rowAtContentY(y - self.cy)
        if r then
            self.focusArea = "content"
            for n, idx in ipairs(self.focusables) do
                if idx == i then self.focusIndex = n end
            end
            self:activateRow(r, x - self.cx)
        end
    end
    return true
end

function UI:onMouseUp(x, y)
    self.dragging = false
    return true
end

function UI:onMouseUpOutside(x, y)
    self.dragging = false
    return true
end

function UI:onMouseMove(dx, dy)
    if self.dragging then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end
end

function UI:onMouseMoveOutside(dx, dy)
    self:onMouseMove(dx, dy)
end

function UI:onMouseWheel(del)
    if U.anyModalOpen() then return true end
    self.scrollY = self.scrollY + del * math.floor(48 * self.scale)
    self:clampScroll()
    return true
end

-- Controller -------------------------------------------------------------------------------------------------------

function UI:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self.joyfocus = joypadData
end

function UI:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
    self.joyfocus = nil
end

function UI:focusedRow()
    local idx = self.focusables[self.focusIndex]
    return idx, idx and self.rows[idx] or nil
end

function UI:moveFocus(dir)
    if self.focusArea == "side" then
        self.sideIndex = math.max(1, math.min(#self.sideSelectable, self.sideIndex + dir))
    elseif #self.focusables > 0 then
        self.focusIndex = math.max(1, math.min(#self.focusables, self.focusIndex + dir))
        self:ensureVisible(self.focusables[self.focusIndex])
    end
end

function UI:onJoypadDirUp(joypadData) self:moveFocus(-1) end
function UI:onJoypadDirDown(joypadData) self:moveFocus(1) end

function UI:onJoypadDirLeft(joypadData)
    if self.focusArea == "content" then
        local _, r = self:focusedRow()
        if r and r.kind == "value" then
            self:step(r.s, r.v, -1)
        else
            self.focusArea = "side"
        end
    end
end

function UI:onJoypadDirRight(joypadData)
    if self.focusArea == "side" then
        self.focusArea = "content"
    else
        local _, r = self:focusedRow()
        if r and r.kind == "value" then self:step(r.s, r.v, 1) end
    end
end

function UI:onJoypadDown(button, joypadData)
    if button == Joypad.AButton then
        if self.focusArea == "side" then
            self:activateSide(self.sideItems[self.sideSelectable[self.sideIndex]])
        else
            local _, r = self:focusedRow()
            self:activateRow(r, nil, (r and r.kind == "preset") and false or nil)
        end
    elseif button == Joypad.BButton then
        self:close()
    elseif button == Joypad.LBumper then
        self:setTabIndex(self.tabIndex - 1)
    elseif button == Joypad.RBumper then
        self:setTabIndex(self.tabIndex + 1)
    elseif button == Joypad.XButton and self.focusArea == "content" then
        local _, r = self:focusedRow()
        if r and r.s then
            self:resetToDefault(r.s)
        elseif r and r.kind == "preset" then
            self:activateRow(r, nil, true)
        end
    end
end

function UI:close()
    self:setVisible(false)
    U.releaseFocus(self)
end

-- Drawing ----------------------------------------------------------------------------------------------------------

function UI:hardwareLine()
    local hw = self.hw
    local parts = {}
    if hw.cores and hw.threads then parts[#parts + 1] = hw.cores .. "C/" .. hw.threads .. "T" end
    if hw.ramMb then parts[#parts + 1] = string.format("%d GB RAM", math.floor(hw.ramMb / 1024 + 0.5)) end
    if hw.gpu then parts[#parts + 1] = hw.gpu end
    if #parts == 0 then return T("UI_MPOptim_V2_HardwareUnknown", "Hardware details need the Java engine") end
    return table.concat(parts, "   ")
end

function UI:renderHeader()
    local pad = self.pad
    local closeX = U.drawHeader(self, T("UI_MPOptim_Title", "Project Zomboid Optimiser"), self.headerH, pad)
    local hwStr = self:hardwareLine()
    local hx = closeX - pad - measure(self.fS, hwStr)
    text(self, hwStr, hx, math.floor((self.headerH - self.fh) / 2), C.dim, self.fS)
end

function UI:renderSide()
    rect(self, 0, self.headerH, self.sideW, self.height - self.headerH - self.footerH, C.side)
    local pad = self.pad
    local mx, my = self:getMouseX(), self:getMouseY()
    local hoverIdx = (self:isMouseOver() and mx < self.sideW) and self:sideAt(my) or nil
    local focusIdx = (self.joyfocus and self.focusArea == "side") and self.sideSelectable[self.sideIndex] or nil
    for i, it in ipairs(self.sideItems) do
        if it.kind == "heading" then
            text(self, string.upper(it.text), pad, it.y + 4, C.dim, self.fS)
        else
            local active = (it.kind == "tab" and it.index == self.tabIndex)
            if active then
                rect(self, 0, it.y, self.sideW, it.h, C.cardHi)
                rect(self, 0, it.y, 3, it.h, C.accent)
            elseif i == hoverIdx then
                rect(self, 0, it.y, self.sideW, it.h, C.card)
            end
            if i == focusIdx then border(self, 2, it.y + 1, self.sideW - 4, it.h - 2, C.accent) end
            local col = active and C.accent or C.text
            if it.kind == "alloptim" then col = C.good end
            if it.dev or it.kind == "exitdev" then col = C.bad end
            text(self, it.text, pad + 4, it.y + (it.h - self.fh) / 2, col, self.fS)
        end
    end
    rect(self, self.sideW - 1, self.headerH, 1, self.height - self.headerH - self.footerH, C.line)
end

function UI:renderImpact(s, x, y, maxX)
    local isz = self.badgeH
    local hovered = nil
    local mx, my = self:getMouseX(), self:getMouseY()
    for _, res in ipairs(S.Resources) do
        local v = s.impact and s.impact[res.id]
        if v and v ~= 0 then
            local col = v > 0 and C.good or C.bad
            local marks = string.rep(v > 0 and "+" or "-", math.min(3, math.abs(v)))
            local label = T("UI_MPOptim_Res_" .. res.id, res.label) .. " " .. marks
            local w = isz + 4 + measure(self.fS, label) + math.floor(14 * self.scale)
            if x + w > maxX then break end
            local tex = icon(res.id, isz)
            if tex then self:drawTextureScaled(tex, x, y, isz, isz, 1, col[1], col[2], col[3]) end
            text(self, label, x + isz + 4, y + (isz - self.fh) / 2, col, self.fS)
            if mx >= x and mx < x + w and my >= y and my < y + isz then hovered = true end
            x = x + w
        end
    end
    return hovered
end

local VERDICT = {
    on = { key = "UI_MPOptim_V2_VerdictOn", text = "Recommended: ON", col = C.good },
    off = { key = "UI_MPOptim_V2_VerdictOff", text = "Recommended: OFF", col = C.warn },
    optional = { key = "UI_MPOptim_V2_VerdictOptional", text = "Optional on this PC", col = C.dim },
    none = { key = "UI_MPOptim_V2_VerdictNone", text = "No effect yet", col = C.dim },
}

function UI:renderSwitch(x, y, on, locked)
    local w, h = self.switchW, math.floor(24 * self.scale)
    local bgc = locked and { 0.20, 0.21, 0.24 } or (on and { 0.16, 0.45, 0.26 } or { 0.30, 0.16, 0.16 })
    rect(self, x, y, w, h, bgc)
    border(self, x, y, w, h, locked and C.line or (on and C.good or C.bad), 0.9)
    local label = on and T("UI_MPOptim_V2_On", "ON") or T("UI_MPOptim_V2_Off", "OFF")
    self:drawTextCentre(label, x + w / 2, y + (h - self.fh) / 2, 1, 1, 1, locked and 0.5 or 1, self.fS)
end

function UI:cardBox(x, y, h, hi, focused)
    rect(self, x, y, self.cardW, h, hi and C.cardHi or C.card)
    border(self, x, y, self.cardW, h, focused and C.accent or C.line, focused and 1 or 0.6)
end

function UI:statPairs()
    local now = getTimestampMs and getTimestampMs() or 0
    if self.stats and now - self.statsAt < 500 then return self.stats end
    self.statsAt = now
    local st = MPOptim.StaggerQueue and MPOptim.StaggerQueue.stats or {}
    local fps = (MPOptim.Utils.getFPS and MPOptim.Utils.getFPS()) or 0
    local texComp = getCore().getOptionTextureCompression and getCore():getOptionTextureCompression() or false
    local audioMod = MPOptim.Utils.IsAudioReplacerActive and MPOptim.Utils.IsAudioReplacerActive()
    local preset = (MPOptim.Config.GetActivePresetName and MPOptim.Config.GetActivePresetName()) or "Custom"
    self.stats = {
        { T("UI_MPOptim_V2_StatFPS", "Frame rate"), tostring(fps) .. " FPS", fps >= 55 and C.good or (fps >= 30 and C.warn or C.bad) },
        { T("UI_MPOptim_V2_StatLuaRAM", "Lua memory"), tostring((MPOptim.Utils.formatMemoryMB and MPOptim.Utils.formatMemoryMB()) or "?"), C.accent },
        { T("UI_MPOptim_V2_StatEngine", "Engine"), isAgent() and T("UI_MPOptim_V2_EngineJavaShort", "Java (active)") or T("UI_MPOptim_V2_EngineLuaShort", "Lua only"), isAgent() and C.good or C.dim },
        { T("UI_MPOptim_V2_StatPreset", "Preset"), tostring(preset), C.text },
        { T("UI_MPOptim_V2_StatTexComp", "Texture compression"), texComp and T("UI_MPOptim_V2_On", "ON") or T("UI_MPOptim_V2_OffRestart", "OFF (needs a restart)"), texComp and C.good or C.warn },
        { T("UI_MPOptim_V2_StatAudioMod", "Sound replacer mod"), audioMod and T("UI_MPOptim_V2_Detected", "Detected, audio left alone") or T("UI_MPOptim_V2_None", "None"), C.text },
        { T("UI_MPOptim_V2_StatBlood", "Blood cleaned"), tostring(st.bloodCleaned or 0), C.text },
        { T("UI_MPOptim_V2_StatCorpses", "Corpses cleaned"), tostring(st.corpsesCleaned or 0), C.text },
        { T("UI_MPOptim_V2_StatDebris", "Debris cleaned"), tostring(st.debrisCleaned or 0), C.text },
    }
    return self.stats
end

function UI:renderContent()
    local pad, cx, cy = self.pad, self.cx, self.cy
    rect(self, cx, cy, self.cw, self.ch, C.bg)
    self:setStencilRect(cx, cy, self.cw, self.ch)
    local mx, my = self:getMouseX(), self:getMouseY()
    local mouseIn = self:isMouseOver() and not U.anyModalOpen() and mx >= cx and my >= cy and my < cy + self.ch
    local hoverRow = mouseIn and self:rowAtContentY(my - cy) or nil
    local focusRow = (self.joyfocus and self.focusArea == "content") and self.focusables[self.focusIndex] or nil
    local hw = self.hw
    self.tipLines = nil

    for i, r in ipairs(self.rows) do
        local y = cy + r.y - self.scrollY
        if y + r.h >= cy and y <= cy + self.ch then
            local x = cx + pad
            local hi = (i == hoverRow) or (i == focusRow)
            if r.kind == "section" then
                text(self, string.upper(r.text), x, y + math.floor(pad * 0.4), C.accent, self.fS)
            elseif r.kind == "card" then
                local s = r.s
                local h = r.h
                local j = i + 1
                while self.rows[j] and self.rows[j].kind == "value" do
                    h = h + self.rows[j].h
                    j = j + 1
                end
                self:cardBox(x, y, h, hi, i == focusRow)
                local ty = y + pad
                local title = settingLabel(s)
                if s.experimental then title = title .. "  " .. T("UI_MPOptim_V2_Experimental", "[Experimental]") end
                text(self, title, x + pad, ty, cardLocked(s) and C.dim or C.text, self.fM)
                if s.key then
                    self:renderSwitch(x + self.cardW - pad - self.switchW, ty, isOn(s.key), cardLocked(s))
                end
                ty = ty + self.fhM + 4
                for _, line in ipairs(r.lines) do
                    text(self, line, x + pad, ty, C.dim, self.fS)
                    ty = ty + self.fh
                end
                if r.noteLines then
                    for _, line in ipairs(r.noteLines) do
                        text(self, line, x + pad, ty, C.warn, self.fS)
                        ty = ty + self.fh
                    end
                end
                ty = ty + 6
                local verdict = S.Verdict(s, hw)
                local vInfo = verdict and VERDICT[verdict]
                local vw = 0
                if vInfo then
                    local vt = T(vInfo.key, vInfo.text)
                    vw = measure(self.fS, vt)
                    text(self, vt, x + self.cardW - pad - vw, ty + (self.badgeH - self.fh) / 2, vInfo.col, self.fS)
                end
                local reason = lockReason(s)
                if reason then
                    text(self, reason, x + pad, ty + (self.badgeH - self.fh) / 2, C.warn, self.fS)
                elseif self:renderImpact(s, x + pad, ty, x + self.cardW - pad * 2 - vw) then
                    self.tipLines = S.ImpactLines(s)
                end
            elseif r.kind == "value" then
                local s, v = r.s, r.v
                local locked = valueLocked(s)
                if i == focusRow then border(self, x + 2, y, self.cardW - 4, r.h - 2, C.accent) end
                rect(self, x + pad, y, self.cardW - pad * 2, 1, C.line, 0.6)
                local vy = y + math.floor(pad / 2)
                text(self, T("UI_MPOptim_SetValue_" .. v.key, v.label), x + pad, vy, locked and C.dim or C.text, self.fS)
                if r.first and s.valueHint then
                    text(self, T("UI_MPOptim_SetHint_" .. v.key, s.valueHint), x + pad, vy + self.fh, C.dim, self.fS, 0.85)
                end
                local boxX, boxW = self:valueBox()
                boxX = cx + boxX
                local boxH = math.floor(26 * self.scale)
                local by = y + (r.h - boxH) / 2
                rect(self, boxX, by, boxW, boxH, C.well)
                border(self, boxX, by, boxW, boxH, locked and C.line or C.accent, 0.8)
                local cur = MPOptim.Config.Get(v.key)
                local shown = v.format and v.format(cur) or tostring(cur)
                local a = locked and 0.45 or 1
                self:drawText("<", boxX + 8, by + (boxH - self.fh) / 2, C.accent[1], C.accent[2], C.accent[3], a, self.fS)
                self:drawTextRight(">", boxX + boxW - 8, by + (boxH - self.fh) / 2, C.accent[1], C.accent[2], C.accent[3], a, self.fS)
                self:drawTextCentre(shown, boxX + boxW / 2, by + (boxH - self.fh) / 2, C.text[1], C.text[2], C.text[3], a, self.fS)
            elseif r.kind == "action" then
                self:cardBox(x, y, r.h, hi, i == focusRow)
                local reason = r.lock and r.lock() or nil
                local ty = y + pad
                text(self, r.title, x + pad, ty, reason and C.dim or C.text, self.fM)
                ty = ty + self.fhM + 4
                for _, line in ipairs(r.lines) do
                    text(self, line, x + pad, ty, C.dim, self.fS)
                    ty = ty + self.fh
                end
                if reason then text(self, reason, x + pad, ty, C.warn, self.fS) end
                local bw = self:actionButtonW()
                local bx = x + self.cardW - pad - bw
                local by = y + (r.h - self.btnH) / 2
                U.drawButton(self, bx, by, bw, self.btnH, r.button, r.style, { hot = (i == hoverRow), disabled = reason ~= nil }, self.fS)
            elseif r.kind == "stats" then
                self:cardBox(x, y, r.h, false, false)
                local pairsList = self:statPairs()
                local colW = math.floor((self.cardW - pad * 3) / 2)
                local lineH = self.fh + math.floor(6 * self.scale)
                for n, pr in ipairs(pairsList) do
                    local col = (n - 1) % 2
                    local row = math.floor((n - 1) / 2)
                    local px = x + pad + col * (colW + pad)
                    local py = y + pad + row * lineH
                    text(self, pr[1], px, py, C.dim, self.fS)
                    local val = U.trim(self.fS, pr[2], colW / 2)
                    self:drawTextRight(val, px + colW, py, pr[3][1], pr[3][2], pr[3][3], 1, self.fS)
                end
            elseif r.kind == "preset" then
                self:cardBox(x, y, r.h, hi, i == focusRow)
                text(self, r.name, x + pad, y + pad, C.text, self.fM)
                local sub = r.builtIn and T("UI_MPOptim_V2_PresetBuiltIn", "Comes with the mod")
                    or string.format(T("UI_MPOptim_V2_PresetCount", "%d settings saved"), r.count)
                text(self, sub, x + pad, y + pad + self.fhM, C.dim, self.fS)
                local loadX, delX, bw = self:presetButtons()
                local by = y + (r.h - self.btnH) / 2
                local lx = mx - cx
                local overRow = (i == hoverRow)
                U.drawButton(self, cx + loadX, by, bw, self.btnH, T("UI_MPOptim_V2_Load", "Load"), "good",
                    { hot = overRow and lx >= loadX and lx < loadX + bw }, self.fS)
                U.drawButton(self, cx + delX, by, bw, self.btnH, T("UI_MPOptim_V2_Delete", "Delete"), "danger",
                    { hot = overRow and lx >= delX and lx < delX + bw, disabled = r.builtIn }, self.fS)
            elseif r.kind == "mod" then
                local mod = r.mod
                self:cardBox(x, y, r.h, hi, i == focusRow)
                local info = RATING[mod.rating] or RATING.LIGHT
                local ratingStr = T(info.key, info.text)
                local rw = measure(self.fS, ratingStr)
                local ty = y + pad
                text(self, U.trim(self.fM, mod.name or mod.id or "?", self.cardW - pad * 3 - rw), x + pad, ty, C.text, self.fM)
                text(self, ratingStr, x + self.cardW - pad - rw, ty + (self.fhM - self.fh) / 2, info.col, self.fS)
                ty = ty + self.fhM + 4
                local line = string.format(T("UI_MPOptim_V2_ModLine", "%d event hooks   %s Lua memory"), mod.hookCount or 0, fmtBytes(mod.estimatedBytes))
                text(self, line, x + pad, ty, C.dim, self.fS)
                local more = r.expanded and T("UI_MPOptim_V2_Less", "Less") or T("UI_MPOptim_V2_Details", "Details")
                self:drawTextRight(more, x + self.cardW - pad, ty, C.accent[1], C.accent[2], C.accent[3], 1, self.fS)
                if r.detail then
                    ty = ty + self.fh + pad
                    rect(self, x + pad, ty - math.floor(pad / 2), self.cardW - pad * 2, 1, C.line, 0.6)
                    local tagW = math.floor(90 * self.scale)
                    for _, d in ipairs(r.detail) do
                        if d.tag then
                            text(self, d.tag, x + pad, ty, d.tagCol, self.fS)
                            text(self, d.text, x + pad + tagW, ty, d.col, self.fS)
                        else
                            text(self, d.text, x + pad, ty, d.col, self.fS)
                        end
                        ty = ty + self.fh
                    end
                end
            end
        end
    end
    self:clearStencilRect()

    if self.contentH > self.ch then
        local trackX = cx + self.cw - 6
        local barH = math.max(30, self.ch * self.ch / self.contentH)
        local barY = cy + (self.ch - barH) * (self.scrollY / (self.contentH - self.ch))
        rect(self, trackX, barY, 4, barH, C.line)
    end
end

function UI:renderFooter()
    local pad = self.pad
    local y = self.height - self.footerH
    rect(self, 0, y, self.width, self.footerH, C.side)
    rect(self, 0, y, self.width, 1, C.line)
    local ty = y + (self.footerH - self.fh) / 2
    if self.flashFrames > 0 and self.flashText then
        self.flashFrames = self.flashFrames - 1
        text(self, self.flashText, pad, ty, C.good, self.fS)
    elseif self.joyfocus then
        local hints = {
            { Joypad.Texture.AButton, T("UI_MPOptim_V2_HintSelect", "Select") },
            { Joypad.Texture.BButton, T("UI_MPOptim_V2_HintClose", "Close") },
        }
        local _, r = self:focusedRow()
        if self.focusArea == "content" and r then
            if r.s then
                hints[#hints + 1] = { Joypad.Texture.XButton, T("UI_MPOptim_V2_HintReset", "Reset") }
            elseif r.kind == "preset" and not r.builtIn then
                hints[#hints + 1] = { Joypad.Texture.XButton, T("UI_MPOptim_V2_Delete", "Delete") }
            end
        end
        hints[#hints + 1] = { Joypad.Texture.LBumper, nil }
        hints[#hints + 1] = { Joypad.Texture.RBumper, T("UI_MPOptim_V2_HintTabs", "Tabs") }
        U.drawHints(self, pad, ty, hints, self.fS)
    else
        text(self, T("UI_MPOptim_V2_HintMouse2", "Click a card to use it. Hover the icons for details."), pad, ty, C.dim, self.fS)
    end
    local eng = isAgent() and T("UI_MPOptim_V2_EngineJava", "Engine: Java (active)") or T("UI_MPOptim_V2_EngineLua", "Engine: Lua only")
    text(self, eng, self.width - pad - measure(self.fS, eng), ty, isAgent() and C.good or C.dim, self.fS)
end

function UI:renderTooltip()
    if not self.tipLines or #self.tipLines == 0 then return end
    local pad = math.floor(self.pad / 2)
    local w = 0
    for _, l in ipairs(self.tipLines) do w = math.max(w, measure(self.fS, l)) end
    w = w + pad * 2
    local h = #self.tipLines * self.fh + pad * 2
    local x = math.min(self:getMouseX() + 16, self.width - w - 4)
    local y = math.min(self:getMouseY() + 16, self.height - h - 4)
    rect(self, x, y, w, h, { 0.03, 0.04, 0.06 }, 0.97)
    border(self, x, y, w, h, C.accent, 0.8)
    for i, l in ipairs(self.tipLines) do
        text(self, l, x + pad, y + pad + (i - 1) * self.fh, C.text, self.fS)
    end
end

function UI:prerender()
    rect(self, 0, 0, self.width, self.height, C.bg, 0.98)
end

function UI:render()
    if not self.hw.complete then
        self.hwPoll = self.hwPoll + 1
        if self.hwPoll % 60 == 1 then self.hw = S.Hardware() end
    end
    self:renderHeader()
    self:renderSide()
    self:renderContent()
    self:renderFooter()
    self:renderTooltip()
    border(self, 0, 0, self.width, self.height, C.line)
end

-- Opening ----------------------------------------------------------------------------------------------------------

function MPOptim.OpenSettingsUI(forceRebuild)
    local scale, _, sw, sh = MPOptim.Utils.GetUIScale()
    local w = math.min(sw - 40, math.max(860, math.floor(1000 * scale)))
    local h = math.min(sh - 40, math.max(620, math.floor(740 * scale)))
    local x, y = math.floor((sw - w) / 2), math.floor((sh - h) / 2)
    local mainScreen = MainScreen and MainScreen.instance
    local parentWanted = (not inWorld() and mainScreen) or nil
    local tabIndex = instance and instance.tabIndex or nil

    -- Admin rights and developer mode change the sidebar
    local sideKey = tostring(isMPAdmin()) .. tostring(MPOptim.DevMode == true)
    if instance and (forceRebuild or instance._parentWanted ~= parentWanted or instance._sideKey ~= sideKey) then
        instance:close()
        if instance:getParent() then instance:getParent():removeChild(instance) else instance:removeFromUIManager() end
        instance = nil
    end

    if not instance then
        instance = UI:new(x, y, w, h)
        instance._parentWanted = parentWanted
        instance._sideKey = sideKey
        if tabIndex then instance.tabIndex = tabIndex end
        instance:initialise()
        if parentWanted then parentWanted:addChild(instance) else instance:addToUIManager() end
    else
        instance:setX(x)
        instance:setY(y)
        instance:setVisible(true)
        instance:buildRows(true)
    end
    instance:bringToTop()
    U.grabFocus(instance)
end

function MPOptim.ToggleSettingsUI()
    if instance and instance:isVisible() then
        instance:close()
    else
        MPOptim.OpenSettingsUI()
    end
end

Events.OnKeyPressed.Add(function(key)
    local hotkey = (MPOptim.Config and MPOptim.Config.Get("UI_Hotkey")) or 68 -- F10
    if PZAPI and PZAPI.ModOptions and PZAPI.ModOptions.getOptions then
        local opt = PZAPI.ModOptions:getOptions("MPOptimizer")
        local o = opt and opt.getOption and opt:getOption("OptimizerHotkey")
        if o and o.key and o.key > 0 then hotkey = o.key end
    end
    if Core and Core.getInstance and Core.getInstance().isDoingTextEntry and Core.getInstance():isDoingTextEntry() then
        return
    end
    if key == hotkey then MPOptim.ToggleSettingsUI() end
end)
