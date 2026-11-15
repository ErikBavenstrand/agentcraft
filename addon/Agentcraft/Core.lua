-- Agentcraft core: module registry, saved settings, enable/disable, slash commands.
-- Works on retail and classic-era clients (only uses APIs common to all).
local ADDON, ns = ...
Agentcraft = ns -- global handle so macros or other addons can reach it
ns.modules, ns.order, ns.commands = {}, {}, {}

-- Output goes to the active ns.Capture buffer when there is one, else to
-- chat. Never reassign the global print: writing a global taints it.
function ns.Out(...)
  local buf = ns._capture
  if not buf then return print(...) end
  local parts = {}
  for i = 1, select("#", ...) do parts[i] = tostring((select(i, ...))) end
  table.insert(buf, table.concat(parts, " "))
end

ns.PREFIX = "|cff33ff99Agentcraft|r:"
function ns.Print(...)
  ns.Out(ns.PREFIX, ...)
end

-- Error handler for xpcall: report through the game's handler (BugSack and
-- the error popup see it) and hand the message back.
local function ReportError(err)
  local handler = geterrorhandler and geterrorhandler()
  if handler then pcall(handler, err) end
  return err
end

local function CopyDefaults(src, dst)
  for k, v in pairs(src) do
    if type(v) == "table" then
      dst[k] = type(dst[k]) == "table" and dst[k] or {}
      CopyDefaults(v, dst[k])
    elseif dst[k] == nil then
      dst[k] = v
    end
  end
  return dst
end

--[[ Register a module. Fields on mod (all optional):
  title         display name ("Action Bars"); default = the module name
  description   one line shown on Options and in /ac modules
  order         sort position on Options (default 500)
  enabled       default on/off (true if omitted)
  defaults      table of default account-wide settings  -> self.db
  charDefaults  table of default per-character settings -> self.charDB
  events        { EVENT_NAME = function(self, ...) end }
  OnEnable(self), OnDisable(self)
  A module that is off gets no events, and its page, footer actions,
  commands and tool actions are gated (see `module` below).
]]
function ns.RegisterModule(name, mod)
  mod.name = name
  mod.title = mod.title or name
  if mod.enabled == nil then mod.enabled = true end
  ns.modules[name:lower()] = mod
  table.insert(ns.order, mod)
  return mod
end

-- The module that owns a page, command or action, given its `module` field
-- (a module key, any case). Returns the module table or nil.
function ns.ModuleOf(key)
  if type(key) ~= "string" then return nil end
  return ns.modules[key:lower()]
end

-- True (plus the module) when the owning module is switched off. key may be a
-- list of module keys ({ "ActionBars", "Keybinds" }): then it is gated only
-- while every listed module is off, and the first off module is returned.
function ns.IsGated(key)
  if type(key) == "table" then
    local first, any = nil, false
    for _, k in ipairs(key) do
      local mod = ns.ModuleOf(k)
      if mod then
        any = true
        if mod.active then return false, mod end
        first = first or mod
      end
    end
    if any then return true, first end
    return false, nil
  end
  local mod = ns.ModuleOf(key)
  if mod and not mod.active then return true, mod end
  return false, mod
end

-- Window settings (ns.db), with their defaults. Read them with ns.Setting(k).
--   sound      true: UI sounds          motion     kept for old saves; ignored (the UI never animates panels)
--   prompts    "auto" | "keyboard" | "pad" (button prompt glyphs)
--   focusTips  true: tooltips also on keyboard/controller focus
--   shortcuts  true: Ctrl+Tab, Ctrl+1..5, Ctrl+Enter, Ctrl+Space, Ctrl+F while the window is open
ns.UI_DEFAULTS = { sound = true, motion = "full", prompts = "auto", focusTips = false, shortcuts = true }
function ns.Setting(k)
  local v = ns.db and ns.db[k]
  if v == nil then return ns.UI_DEFAULTS[k] end
  return v
end

local function OffMessage(mod)
  return (mod.title or mod.name) .. " is turned off. Turn it on in Options or with /ac on " .. mod.name:lower() .. "."
end
ns.ModuleOffMessage = OffMessage

--[[ Register a slash subcommand: /ac <name> <args>
  help   one line for /ac help, written after the usage ("open Action Bars, or apply/undo the layout")
  opts   optional table:
           usage   what follows "/ac" in the help ("bars [apply|undo]"); default = name
           module  module key; the command refuses to run while that module is off
           hidden  true: not listed in /ac help (unless ns.db.dev)
]]
function ns.RegisterCommand(name, help, fn, opts)
  opts = type(opts) == "table" and opts or {}
  name = name:lower()
  ns.commands[name] = { name = name, help = help, fn = fn, usage = opts.usage, hidden = opts.hidden,
    module = opts.module }
end

-- Other names for a command: /ac bars runs /ac spells.
ns.aliases = { bars = "spells" }

--[[ Register a page in the Agentcraft window (one side tab). dev/ui-widgets.md
  has the full v2 contract; the short version:
  id        unique string
  title     tab and window text
  icon      side-tab icon: file ID, texture path, "atlas:<name>", or function(page)
  order     sort position (lower = earlier tab)
  module    module key, or a list of keys, whose switch gates the page: while
            every listed module is off the page shows a "turned off" note with
            a [Turn On] button, and its actions hide
  aliases   old ids ns.OpenPage still accepts ({ "bars", "keys" })
  description  Inspector text while its side tab is focused
  api       2 for a v2 page: Build(page, stage, pane) gets the 712x512 stage
            and the Inspector pane. Without it the page is a v1 page:
  Build(page, frame)   called once, the first time the page is opened. The
                       frame is 600x450, centred in the stage. Use the widgets in ns.UI.
  v2 extras (all optional): views, toggles, Zones, DefaultFocus, ScrollRegion,
  Review, Commit, primary, prompts, Back, ListJump, hideDivider, readiness, DefaultInspect,
  disableFrameFocusPaging (see dev/ui-widgets.md)
  section, OnShoulder: v1 fields, ignored by the v2 window]]
--[[ v1 fields still read:
  Refresh(page)        called on open, after footer actions, and when bars,
                       binds, bags or spells change while the window is open
  Status(page)         optional; returns the one-line summary under the page
                       title, and optionally a second value: a string or a
                       list of lines shown in the summary's tooltip
  OnShoulder(page, delta)  optional; LB/RB (delta -1/1) on the gamepad. Return
                       true when handled, else the window switches pages
  actions = { {
    label     string or function(page) -> string (re-read on every Refresh)
    fn        function(page); what it prints shows in the status line
    tooltip   string or function(page) -> string
    enabled   function(page) -> bool (re-read on every Refresh)
    confirm   string or function(page) -> string|nil: ask first (nil = don't ask)
    primary   true: placed rightmost (other actions keep their order)
  }, ... }             footer buttons, the last one sits rightmost
]]
ns.pages = {}
function ns.RegisterPage(page)
  table.insert(ns.pages, page)
  return page
end

-- The page with this id or alias, or nil.
function ns.PageById(id)
  for _, p in ipairs(ns.pages) do if p.id == id then return p end end
  for _, p in ipairs(ns.pages) do
    for _, a in ipairs(p.aliases or {}) do if a == id then return p end end
  end
end

-- Small extra buttons shown on the Options page, grouped by section. A
-- section named like a module (e.g. "Snapshot") is gated by that module.
--   status   optional function() -> string: text shown left of the button
ns.actions = {}
function ns.RegisterAction(section, label, fn, tooltip, status)
  local entry = { section = section, label = label, tooltip = tooltip, status = status, module = section }
  entry.fn = function(...)
    local gated, mod = ns.IsGated(entry.module)
    if gated then return ns.Print(OffMessage(mod)) end
    return fn(...)
  end
  table.insert(ns.actions, entry)
end

-- The log behind Options > Log: newest last, at most 100 entries, each
-- "|cff888888HH:MM:SS|r  text" with the "Agentcraft:" prefix stripped.
ns.log = {}
function ns.LogLine(text)
  text = tostring(text or "")
  if text == "" then return end
  table.insert(ns.log, "|cff888888" .. date("%H:%M:%S") .. "|r  " .. text)
  while #ns.log > 100 do table.remove(ns.log, 1) end
end

-- Removes the chat prefix from every line of captured output.
function ns.StripPrefix(text)
  local lines = {}
  for line in (tostring(text or "") .. "\n"):gmatch("(.-)\n") do
    lines[#lines + 1] = (line:gsub("^|cff33ff99Agentcraft|r:%s*", ""))
  end
  return (table.concat(lines, "\n"):gsub("\n+$", ""))
end

-- Run fn, keep what it printed in the log, and return the text (prefix
-- stripped) plus the error message when fn raised.
function ns.Run(fn)
  local out, err = ns.Capture(fn)
  out = ns.StripPrefix(out)
  ns.LogLine(out)
  return out, err
end

-- Run fn and return everything it printed through ns.Print / ns.Out as one
-- string (used by the window to show output instead of spamming chat), plus
-- the error message when fn raised (also appended to the text).
function ns.Capture(fn)
  local buf, outer = {}, ns._capture
  ns._capture = buf
  local ok, err = pcall(fn)
  ns._capture = outer
  if not ok then table.insert(buf, "|cffff4444error:|r " .. tostring(err)) end
  return table.concat(buf, "\n"), (not ok) and tostring(err) or nil
end

local frame = CreateFrame("Frame")
local loaded = false

local function IsEnabled(mod)
  local state = ns.db.enabled[mod.name]
  if state == nil then return mod.enabled end
  return state
end
ns.IsModuleEnabled = function(mod) return IsEnabled(mod) end

-- Turn a module on or off for this session without saving the choice.
-- OnEnable/OnDisable errors are reported, and a module whose OnEnable fails
-- stays off. Returns true when the module ended up in the asked state. A
-- module already in the asked state is left alone (no second OnEnable).
local function Activate(mod, on)
  if not on then
    if mod.active == false then return true end
    mod.active = false
    if mod.OnDisable then xpcall(mod.OnDisable, ReportError, mod) end
    return true
  end
  if mod.active then return true end
  for ev in pairs(mod.events or {}) do
    -- pcall: an event that doesn't exist on this game version would error.
    pcall(frame.RegisterEvent, frame, ev)
  end
  if mod.OnEnable and not xpcall(mod.OnEnable, ReportError, mod) then
    mod.active = false
    ns.Print("|cffff4444" .. (mod.title or mod.name) .. " failed to start|r (see the Lua error).")
    return false
  end
  mod.active = true
  return true
end

local function RefreshUI()
  if ns.UI and ns.UI.Refresh then pcall(ns.UI.Refresh) end
end

-- The user's choice: save it, then apply it. Only explicit choices are saved,
-- so a module's shipped default can still change later. The choice is saved
-- even when the module fails to start, so "off" always sticks.
local function SetEnabled(mod, on)
  ns.db.enabled[mod.name] = on
  return Activate(mod, on)
end
function ns.SetModuleEnabled(mod, on) return SetEnabled(mod, on) end

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    if ... ~= ADDON or loaded then return end
    loaded = true
    AgentcraftDB = AgentcraftDB or {}
    AgentcraftCharDB = AgentcraftCharDB or {}
    ns.db, ns.charDB = AgentcraftDB, AgentcraftCharDB
    -- Counts loads. If it keeps resetting to 1, the client isn't reading
    -- SavedVariables back (a known WoW Forever beta bug).
    ns.db.loadCount = (ns.db.loadCount or 0) + 1
    ns.db.enabled = ns.db.enabled or {}
    ns.db.modules = ns.db.modules or {}
    ns.charDB.modules = ns.charDB.modules or {}
    -- Every module gets its settings first, so one module failing to start
    -- can't leave the ones after it without a db.
    for _, mod in ipairs(ns.order) do
      ns.db.modules[mod.name] = CopyDefaults(mod.defaults or {}, ns.db.modules[mod.name] or {})
      ns.charDB.modules[mod.name] = CopyDefaults(mod.charDefaults or {}, ns.charDB.modules[mod.name] or {})
      mod.db, mod.charDB = ns.db.modules[mod.name], ns.charDB.modules[mod.name]
    end
    for _, mod in ipairs(ns.order) do
      if IsEnabled(mod) then Activate(mod, true) else mod.active = false end
    end
    return
  end
  for _, mod in ipairs(ns.order) do
    local handler = mod.active and mod.events and mod.events[event]
    -- xpcall: one module's error is reported but the rest still get the event.
    if handler then xpcall(handler, ReportError, mod, ...) end
  end
end)

-- Built-in commands
ns.RegisterCommand("modules", "list modules and whether they are on", function()
  for _, mod in ipairs(ns.order) do
    local state = mod.active and "|cff00ff00on|r" or "|cffff4444off|r"
    ns.Out(string.format("  %s (%s) [%s] %s", mod.title or mod.name, mod.name:lower(), state, mod.description or ""))
  end
end)

local function Toggle(arg, on)
  local mod = ns.modules[(arg or ""):lower()]
  if not mod then return ns.Print("No module named '" .. (arg or "") .. "'. Try /ac modules.") end
  -- Compare the saved choice too: a module whose OnEnable failed is off but
  -- still saved as on, and "/ac off" must be able to save the off choice.
  if (mod.active and true or false) == on and IsEnabled(mod) == on then
    return ns.Print((mod.title or mod.name) .. " is already " .. (on and "on." or "off."))
  end
  if SetEnabled(mod, on) then ns.Print((mod.title or mod.name) .. (on and " turned on." or " turned off.")) end
  RefreshUI()
end
ns.RegisterCommand("on", "turn a module on", function(arg) Toggle(arg, true) end, { usage = "on <module>" })
ns.RegisterCommand("off", "turn a module off", function(arg) Toggle(arg, false) end, { usage = "off <module>" })

ns.RegisterCommand("scale", "set the window scale (0.8 to 1.25 in 0.05 steps; no number resets it)", function(arg)
  local v = tonumber(arg)
  if arg ~= "" and not v then return ns.Print("Usage: /ac scale 0.8-1.25") end
  if ns.UI and ns.UI.SetScale then ns.UI.SetScale(v) end
  local s = ns.UI and ns.UI.GetScale and ns.UI.GetScale()
  ns.Print("Window scale " .. (s and string.format("%.2f", s) or "reset") .. (v and "." or " (automatic)."))
end, { usage = "scale [0.8-1.25]" })

ns.RegisterCommand("reset", "move the window back to the centre and reset its scale", function()
  if ns.UI and ns.UI.ResetPosition then ns.UI.ResetPosition() end
  ns.Print("Window position and scale reset.")
end)

-- Every visible command as "/ac usage – help", sorted (Window's /ac help prints it).
function ns.CommandHelp()
  local names, out = {}, {}
  for name, c in pairs(ns.commands) do
    if not c.hidden or (ns.db and ns.db.dev) then names[#names + 1] = name end
  end
  for alias, target in pairs(ns.aliases) do
    if ns.commands[target] and not ns.commands[alias] then names[#names + 1] = alias end
  end
  table.sort(names)
  for _, name in ipairs(names) do
    local c = ns.commands[name]
    if c then
      out[#out + 1] = "/ac " .. (c.usage or name) .. " – " .. (c.help or "")
    else
      out[#out + 1] = "/ac " .. name .. " – same as /ac " .. ns.aliases[name]
    end
  end
  return out
end

local function ShowHelp()
  local help = ns.commands.help
  if help then return help.fn("") end
  ns.Print("Commands (/ac alone opens the window):")
  for _, line in ipairs(ns.CommandHelp()) do ns.Out("  " .. line) end
end

SLASH_AGENTCRAFT1 = "/ac"
SLASH_AGENTCRAFT2 = "/agentcraft"
SlashCmdList.AGENTCRAFT = function(msg)
  local cmd, rest = (msg or ""):match("^(%S*)%s*(.-)$")
  cmd = cmd:lower()
  local entry = ns.commands[cmd] or ns.commands[ns.aliases[cmd] or ""]
  if entry then
    local gated, mod = ns.IsGated(entry.module)
    if gated then return ns.Print(OffMessage(mod)) end
    -- Catch errors so a bug in a module prints a message instead of
    -- leaving the chat box stuck.
    local ok, err = pcall(entry.fn, rest)
    if not ok then ns.Print("|cffff4444error:|r " .. tostring(err)) end
    return
  end
  if cmd == "" and ns.ToggleUI then
    local ok, err = pcall(ns.ToggleUI)
    if not ok then ns.Print("|cffff4444error:|r " .. tostring(err)) end
    return
  end
  if cmd ~= "" then ns.Print("Unknown command '" .. cmd .. "'.") end
  ShowHelp()
end
