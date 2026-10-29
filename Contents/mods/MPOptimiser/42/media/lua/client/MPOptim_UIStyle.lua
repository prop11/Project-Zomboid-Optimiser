--[[
    Project Zomboid Optimiser (Build 42 & 41)
    File: media/lua/client/MPOptim_UIStyle.lua
    Author: prop11
    Description: Shared look for every Optimiser window: colours, text helpers, buttons, controller focus handling and
                 a styled popup (MPOptim.UI.ShowModal) used by the menus, the bug reporter and the settings screen.
--]]

require "ISUI/ISPanelJoypad"
require "ISUI/ISTextEntryBox"
require "ISUI/ISButton"
require "MPOptim_Utils"

MPOptim = MPOptim or {}
MPOptim.UI = MPOptim.UI or {}
local U = MPOptim.UI

U.C = {
    bg     = { 0.07, 0.08, 0.11 },
    side   = { 0.09, 0.10, 0.14 },
    card   = { 0.11, 0.13, 0.18 },
    cardHi = { 0.14, 0.18, 0.25 },
    line   = { 0.18, 0.24, 0.35 },
    accent = { 0.35, 0.85, 1.00 },
    text   = { 0.92, 0.93, 0.95 },
    dim    = { 0.60, 0.64, 0.70 },
    good   = { 0.45, 0.90, 0.55 },
    bad    = { 0.95, 0.45, 0.40 },
    warn   = { 0.95, 0.70, 0.30 },
    well   = { 0.05, 0.07, 0.10 },
}
local C = U.C

-- Button looks: background, border
local BUTTON = {
    primary = { { 0.10, 0.27, 0.38 }, C.accent },
    good    = { { 0.13, 0.34, 0.21 }, C.good },
    danger  = { { 0.34, 0.13, 0.13 }, C.bad },
    warn    = { { 0.32, 0.22, 0.09 }, C.warn },
    neutral = { C.card, C.line },
}

-- Labels are drawn every frame; the language only changes with a Lua reload
local textCache = {}
function U.T(key, fallback)
    local t = textCache[key]
    if t == nil then
        t = MPOptim.GetText(key, fallback)
        textCache[key] = t
    end
    return t
end
local T = U.T

function U.measure(font, str)
    return MPOptim.Utils.MeasureText(font, str)
end
local measure = U.measure

function U.wrap(font, text, maxW)
    local lines, line = {}, ""
    for word in string.gmatch(text or "", "%S+") do
        local test = (line == "") and word or (line .. " " .. word)
        if line ~= "" and measure(font, test) > maxW then
            lines[#lines + 1] = line
            line = word
        else
            line = test
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

function U.trim(font, text, maxW)
    text = tostring(text or "")
    if measure(font, text) <= maxW then return text end
    local lo, hi, best = 1, #text, ""
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        local cand = string.sub(text, 1, mid) .. "..."
        if measure(font, cand) <= maxW then
            best = cand
            lo = mid + 1
        else
            hi = mid - 1
        end
    end
    return best ~= "" and best or "..."
end

local iconCache = {}
function U.icon(id, px)
    local size = 24
    for _, n in ipairs({ 24, 32, 48, 64 }) do
        size = n
        if n >= px then break end
    end
    local path = "media/ui/MPOptim/Icon_" .. id .. "_" .. size .. ".png"
    if iconCache[path] == nil then iconCache[path] = getTexture(path) or false end
    return iconCache[path] or nil
end

function U.metrics()
    local scale = MPOptim.Utils.GetUIScale()
    local tm = getTextManager()
    local m = { scale = scale, fS = UIFont.Small, fM = UIFont.Medium }
    m.fh = tm:getFontHeight(m.fS)
    m.fhM = tm:getFontHeight(m.fM)
    m.pad = math.floor(12 * scale)
    m.btnH = m.fh + math.floor(14 * scale)
    return m
end

function U.rect(p, x, y, w, h, c, a)
    p:drawRect(x, y, w, h, a or 1, c[1], c[2], c[3])
end

function U.border(p, x, y, w, h, c, a)
    p:drawRectBorder(x, y, w, h, a or 1, c[1], c[2], c[3])
end

function U.text(p, str, x, y, c, font, a)
    p:drawText(str, x, y, c[1], c[2], c[3], a or 1, font)
end

-- One button drawn in place. state: hot (mouse over), focus (controller), disabled
function U.drawButton(p, x, y, w, h, label, style, state, font)
    state = state or {}
    local look = BUTTON[style or "neutral"] or BUTTON.neutral
    local bgc, edge = look[1], look[2]
    if state.disabled then
        bgc, edge = { 0.15, 0.16, 0.19 }, C.line
    elseif state.hot then
        bgc = { math.min(1, bgc[1] + 0.06), math.min(1, bgc[2] + 0.06), math.min(1, bgc[3] + 0.06) }
    end
    U.rect(p, x, y, w, h, bgc)
    U.border(p, x, y, w, h, edge, state.disabled and 0.6 or 0.9)
    if state.focus then
        U.border(p, x - 2, y - 2, w + 4, h + 4, C.accent)
        U.border(p, x - 1, y - 1, w + 2, h + 2, C.accent)
    end
    font = font or UIFont.Small
    local fh = getTextManager():getFontHeight(font)
    local a = state.disabled and 0.45 or 1
    p:drawTextCentre(label, x + w / 2, y + (h - fh) / 2, C.text[1], C.text[2], C.text[3], a, font)
end

-- Gives a vanilla ISButton the same colours
function U.StyleButton(btn, style)
    if not btn then return end
    local look = BUTTON[style or "neutral"] or BUTTON.neutral
    local bgc, edge = look[1], look[2]
    btn.backgroundColor = { r = bgc[1], g = bgc[2], b = bgc[3], a = 0.95 }
    btn.backgroundColorMouseOver = { r = math.min(1, bgc[1] + 0.06), g = math.min(1, bgc[2] + 0.06), b = math.min(1, bgc[3] + 0.06), a = 1 }
    btn.borderColor = { r = edge[1], g = edge[2], b = edge[3], a = 0.9 }
    btn.textColor = { r = C.text[1], g = C.text[2], b = C.text[3], a = 1 }
end

-- Controller hints: list of { texture, label }; returns the x after the last one
function U.drawHints(p, x, y, hints, font)
    font = font or UIFont.Small
    local fh = getTextManager():getFontHeight(font)
    local isz = fh + 4
    local gap = math.floor(fh * 1.2)
    for _, h in ipairs(hints) do
        if h[1] then
            p:drawTextureScaled(h[1], x, y - 2, isz, isz, 1)
            x = x + isz + 4
        end
        if h[2] then
            U.text(p, h[2], x, y, C.dim, font)
            x = x + measure(font, h[2]) + gap
        end
    end
    return x
end

-- Window header: title bar with a close box. Returns the close box x.
function U.drawHeader(p, title, headerH, pad, titleCol)
    local m = U.metrics()
    U.rect(p, 0, 0, p.width, headerH, C.side)
    U.text(p, title, pad, math.floor((headerH - m.fhM) / 2), titleCol or C.accent, m.fM)
    local closeW = headerH - pad
    local closeX = p.width - closeW - pad
    local cy = math.floor(pad / 2)
    local over = p:isMouseOver() and p:getMouseY() < headerH and p:getMouseX() >= closeX
    U.rect(p, closeX, cy, closeW, closeW, over and { 0.60, 0.18, 0.18 } or { 0.40, 0.13, 0.13 })
    p:drawTextCentre("X", closeX + closeW / 2, cy + (closeW - m.fh) / 2, 1, 1, 1, 1, m.fS)
    U.rect(p, 0, headerH - 2, p.width, 2, C.line)
    return closeX
end

-- Controller focus -------------------------------------------------------------------------------------------------

-- Windows that own the controller, newest last. The main menu asks for the top one (see hookMainScreenFocus).
U.focusStack = U.focusStack or {}

local function unstack(panel)
    for i = #U.focusStack, 1, -1 do
        if U.focusStack[i] == panel then table.remove(U.focusStack, i) end
    end
end

function U.topFocus()
    for i = #U.focusStack, 1, -1 do
        local p = U.focusStack[i]
        if p:isReallyVisible() then return p end
    end
    return nil
end

function U.anyModalOpen()
    for i = #U.focusStack, 1, -1 do
        local p = U.focusStack[i]
        if p.isMPOptimModal and p:isReallyVisible() then return true end
    end
    return false
end

-- A controller that has not been used yet activates on its first A press and takes the main menu's current focus:
-- while one of these windows is open that must be the window, not the menu buttons behind it.
function U.hookMainScreenFocus()
    if not MainScreen or MainScreen._mpoptimFocusHook then return end
    local original = MainScreen.getCurrentFocusForController
    if type(original) ~= "function" then return end
    MainScreen._mpoptimFocusHook = true
    MainScreen.getCurrentFocusForController = function(self)
        local top = U.topFocus()
        if top then return top end
        return original(self)
    end
end

function U.grabFocus(panel)
    U.hookMainScreenFocus()
    unstack(panel)
    U.focusStack[#U.focusStack + 1] = panel
    local p = getPlayer and getPlayer()
    if p then
        local num = p:getPlayerNum()
        if JoypadState.players[num + 1] then
            panel.prevFocus = getJoypadFocus(num)
            panel.focusPlayer = num
            setJoypadFocus(num, panel)
        end
        return
    end
    local jd = JoypadState.getMainMenuJoypad()
    if jd then
        panel.prevFocus = jd.focus
        jd.focus = panel
        updateJoypadFocus(jd)
    end
end

function U.releaseFocus(panel)
    unstack(panel)
    local prev = panel.prevFocus
    local back = (prev and prev ~= panel and prev:isReallyVisible()) and prev or U.topFocus()
    if panel.focusPlayer ~= nil then
        setJoypadFocus(panel.focusPlayer, back)
        panel.focusPlayer = nil
    else
        local jd = panel.joyfocus or JoypadState.getMainMenuJoypad()
        if jd and jd.focus == panel then
            jd.focus = back or MainScreen.instance
            updateJoypadFocus(jd)
        end
    end
    panel.prevFocus = nil
end

-- Styled popup -----------------------------------------------------------------------------------------------------
--[[
    MPOptim.UI.ShowModal{
        title = "...", titleCol = C.accent, width = 640 (unscaled),
        body = { { h = "Heading" }, { p = "Paragraph", col = C.dim }, { bullet = "Point" }, { kv = { "Label", "Value" }, col = C.good }, { gap = true } },
        entry = "default text"         -- optional text box under the body; read it with modal:entryText()
        buttons = { { label = "OK", style = "good", onClick = function(modal) end, keepOpen = false }, ... },
        cancel = 2,                    -- button run by B / the close box (default: close without running one)
        onClose = function(modal) end,
    }
    onClick returning true also keeps the popup open.
--]]
local Modal = ISPanelJoypad:derive("MPOptim_StyledModal")

function Modal:new(opts)
    local m = U.metrics()
    local sw = getCore():getScreenWidth()
    local w = math.min(sw - 40, math.max(420, math.floor((opts.width or 640) * m.scale)))
    local o = ISPanelJoypad:new(0, 0, w, 200)
    setmetatable(o, self)
    self.__index = self
    o.opts = opts
    o.m = m
    o.background = false
    o.scrollY = 0
    o.focusBtn = opts.defaultButton or 1
    o.statusText = nil
    o.statusFrames = 0
    o.isMPOptimModal = true
    return o
end

function Modal:buildLines()
    local m = self.m
    local maxW = self.width - m.pad * 2 - 8
    local indent = measure(m.fS, "-") + math.floor(10 * m.scale)
    local lines, y = {}, 0
    local function add(l, h)
        l.y = y
        lines[#lines + 1] = l
        y = y + h
    end
    for _, b in ipairs(self.opts.body or {}) do
        if b.gap then
            y = y + math.floor(m.fh * 0.6)
        elseif b.h then
            for _, s in ipairs(U.wrap(m.fM, b.h, maxW)) do add({ text = s, font = m.fM, col = b.col or C.accent }, m.fhM) end
            y = y + 4
        elseif b.bullet then
            for i, s in ipairs(U.wrap(m.fS, b.bullet, maxW - indent)) do
                add({ text = s, font = m.fS, col = b.col or C.text, x = indent, marker = (i == 1) }, m.fh)
            end
        elseif b.kv then
            add({ label = b.kv[1], value = b.kv[2], font = m.fS, col = b.col or C.text }, m.fh + 2)
        else
            for _, s in ipairs(U.wrap(m.fS, b.p, maxW)) do add({ text = s, font = m.fS, col = b.col or C.text }, m.fh) end
        end
    end
    self.lines = lines
    self.bodyH = y
end

function Modal:initialise()
    ISPanelJoypad.initialise(self)
    local m = self.m
    local pad = m.pad
    self.headerH = m.fhM + pad * 2
    self:buildLines()

    local buttons = self.opts.buttons or { { label = T("UI_MPOptim_V2_Close", "Close"), style = "neutral" } }
    self.buttons = buttons
    local perRow = (#buttons == 4) and 2 or math.min(3, #buttons)
    local rowsN = math.ceil(#buttons / perRow)
    local btnGap = math.floor(10 * m.scale)
    local btnsH = rowsN * m.btnH + (rowsN - 1) * btnGap
    self.entryH = self.opts.entry and (m.fh + math.floor(12 * m.scale)) or 0
    local statusH = m.fh + pad

    local sh = getCore():getScreenHeight()
    local fixed = self.headerH + pad + (self.entryH > 0 and self.entryH + pad or 0) + statusH + btnsH + pad
    local maxBody = math.max(m.fh * 3, sh - 80 - fixed)
    self.bodyViewH = math.min(self.bodyH, maxBody)
    self:setHeight(fixed + self.bodyViewH)
    self.bodyY = self.headerH + pad

    local y = self.bodyY + self.bodyViewH + pad
    if self.opts.entry then
        local e = ISTextEntryBox:new(tostring(self.opts.entry), pad, y, self.width - pad * 2, self.entryH)
        e:initialise()
        e:instantiate()
        e.backgroundColor = { r = C.well[1], g = C.well[2], b = C.well[3], a = 1 }
        e.borderColor = { r = C.accent[1], g = C.accent[2], b = C.accent[3], a = 0.8 }
        self:addChild(e)
        self.entry = e
        y = y + self.entryH + pad
    end
    self.statusY = y
    y = y + statusH

    local bw = math.floor((self.width - pad * 2 - btnGap * (perRow - 1)) / perRow)
    for i, b in ipairs(buttons) do
        local col = (i - 1) % perRow
        local row = math.floor((i - 1) / perRow)
        b.x = pad + col * (bw + btnGap)
        b.y = y + row * (m.btnH + btnGap)
        b.w = bw
        b.h = m.btnH
    end

    local sw = getCore():getScreenWidth()
    self:setX(math.floor((sw - self.width) / 2))
    self:setY(math.floor((sh - self.height) / 2))
end

function Modal:entryText()
    return self.entry and self.entry:getText() or nil
end

function Modal:setStatus(msg, col)
    self.statusText = msg
    self.statusCol = col or C.good
    self.statusFrames = 360
end

function Modal:activate(i)
    local b = self.buttons[i]
    if not b then return end
    local keep = false
    if b.onClick then
        local ok, res = pcall(b.onClick, self)
        keep = ok and res == true
    end
    if not keep and not b.keepOpen then self:close() end
end

function Modal:cancel()
    if self.opts.cancel then
        self:activate(self.opts.cancel)
    else
        self:close()
    end
end

function Modal:close()
    if self.closed then return end
    self.closed = true
    self:setVisible(false)
    U.releaseFocus(self)
    self:removeFromUIManager()
    if self.opts.onClose then pcall(self.opts.onClose, self) end
end

function Modal:buttonAt(x, y)
    for i, b in ipairs(self.buttons) do
        if x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h then return i end
    end
    return nil
end

function Modal:clampScroll()
    self.scrollY = math.max(0, math.min(math.max(0, self.bodyH - self.bodyViewH), self.scrollY))
end

function Modal:onMouseDown(x, y)
    if not self:getIsVisible() then return false end
    self:bringToTop()
    if y < self.headerH then
        if x >= self.width - (self.headerH - self.m.pad) - self.m.pad then
            self:cancel()
        else
            self.dragging = true
        end
        return true
    end
    local i = self:buttonAt(x, y)
    if i then
        self.focusBtn = i
        self:activate(i)
    end
    return true
end

function Modal:onMouseUp() self.dragging = false return true end
function Modal:onMouseUpOutside() self.dragging = false return true end

function Modal:onMouseMove(dx, dy)
    if self.dragging then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
    end
end

function Modal:onMouseMoveOutside(dx, dy) self:onMouseMove(dx, dy) end

function Modal:onMouseWheel(del)
    self.scrollY = self.scrollY + del * self.m.fh * 3
    self:clampScroll()
    return true
end

function Modal:onGainJoypadFocus(joypadData)
    ISPanelJoypad.onGainJoypadFocus(self, joypadData)
    self.joyfocus = joypadData
end

function Modal:onLoseJoypadFocus(joypadData)
    ISPanelJoypad.onLoseJoypadFocus(self, joypadData)
    self.joyfocus = nil
end

function Modal:onJoypadDirLeft() self.focusBtn = (self.focusBtn - 2) % #self.buttons + 1 end
function Modal:onJoypadDirRight() self.focusBtn = self.focusBtn % #self.buttons + 1 end
function Modal:onJoypadDirUp() self:onMouseWheel(-1) end
function Modal:onJoypadDirDown() self:onMouseWheel(1) end

function Modal:onJoypadDown(button, joypadData)
    if button == Joypad.AButton then
        self:activate(self.focusBtn)
    elseif button == Joypad.BButton then
        self:cancel()
    elseif button == Joypad.YButton and self.entry and OnScreenKeyboard and not OnScreenKeyboard.IsVisible() then
        pcall(function()
            local osk = OnScreenKeyboard.Show(joypadData.player, self.entry, joypadData)
            osk.prevFocus = self
            joypadData.focus = osk
        end)
    end
end

function Modal:prerender()
    U.rect(self, 0, 0, self.width, self.height, C.bg, 0.98)
end

function Modal:render()
    local m, pad = self.m, self.m.pad
    U.drawHeader(self, self.opts.title or "", self.headerH, pad, self.opts.titleCol)

    local by = self.bodyY
    self:setStencilRect(pad, by, self.width - pad * 2, self.bodyViewH)
    for _, l in ipairs(self.lines) do
        local y = by + l.y - self.scrollY
        if y + m.fhM >= by and y <= by + self.bodyViewH then
            if l.label then
                U.text(self, l.label, pad, y, C.dim, l.font)
                U.text(self, tostring(l.value), pad + math.floor(self.width * 0.42), y, l.col, l.font)
            else
                if l.marker then U.text(self, "-", pad, y, C.accent, l.font) end
                U.text(self, l.text, pad + (l.x or 0), y, l.col, l.font)
            end
        end
    end
    self:clearStencilRect()
    if self.bodyH > self.bodyViewH then
        local barH = math.max(20, self.bodyViewH * self.bodyViewH / self.bodyH)
        local barY = by + (self.bodyViewH - barH) * (self.scrollY / (self.bodyH - self.bodyViewH))
        U.rect(self, self.width - pad / 2 - 2, barY, 4, barH, C.line)
    end

    local sy = self.statusY + math.floor(pad / 4)
    if self.statusFrames > 0 and self.statusText then
        self.statusFrames = self.statusFrames - 1
        self:drawTextCentre(self.statusText, self.width / 2, sy, self.statusCol[1], self.statusCol[2], self.statusCol[3], 1, m.fS)
    elseif self.joyfocus then
        local hints = {
            { Joypad.Texture.AButton, T("UI_MPOptim_V2_HintSelect", "Select") },
            { Joypad.Texture.BButton, T("UI_MPOptim_V2_HintClose", "Close") },
        }
        if self.entry then hints[#hints + 1] = { Joypad.Texture.YButton, T("UI_MPOptim_V2_HintType", "Type a name") } end
        U.drawHints(self, pad, sy, hints, m.fS)
    end

    local mx, my = self:getMouseX(), self:getMouseY()
    local hot = self:isMouseOver() and self:buttonAt(mx, my) or nil
    for i, b in ipairs(self.buttons) do
        U.drawButton(self, b.x, b.y, b.w, b.h, b.label, b.style, { hot = (i == hot), focus = (self.joyfocus ~= nil and i == self.focusBtn) }, m.fS)
    end
    U.border(self, 0, 0, self.width, self.height, C.line)
end

function U.ShowModal(opts)
    local modal = Modal:new(opts)
    modal:initialise()
    modal:addToUIManager()
    modal:setAlwaysOnTop(true)
    modal:bringToTop()
    U.grabFocus(modal)
    return modal
end

-- Yes/no question; onYes runs only when confirmed
function U.Confirm(title, text, yesLabel, onYes, danger)
    return U.ShowModal({
        title = title,
        width = 520,
        body = { { p = text } },
        buttons = {
            { label = yesLabel, style = danger and "danger" or "good", onClick = function() onYes() end },
            { label = T("UI_MPOptim_V2_Cancel", "Cancel"), style = "neutral" },
        },
        cancel = 2,
        defaultButton = 2,
    })
end
