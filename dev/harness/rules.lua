-- The owner's macro and layout rules, in Lua, for tests that run against the
-- loaded addon tables (ns.MacroLibrary, ns.Layout). dev.ps1 "rules" holds the
-- same rules for PowerShell (Test-Macro, Test-Layout); keep the two in step.
local R = {}

local MENU = { ["/camp"] = true, ["/logout"] = true, ["/quit"] = true, ["/exit"] = true, ["/readycheck"] = true,
  ["/screenshot"] = true, ["/map"] = true, ["/repair"] = true }
local MENU_RUN = { "ToggleWorldMap", "RepairAllItems", "Screenshot%s*%(", "Logout%s*%(", "Quit%s*%(", "DoReadyCheck",
  "UseContainerItem", "SellAllJunk", "ChatFrame_OpenChat", "cameraDistanceMax" }
local ITEM_COMMANDS = { ["/use"] = true, ["/equip"] = true, ["/equipslot"] = true, ["/userandom"] = true }
local CAST_COMMANDS = { ["/cast"] = true, ["/castsequence"] = true, ["/castrandom"] = true }
-- Items dev.ps1 Read-ItemNames adds to the ActionBars utility lists.
local EXTRA_ITEMS = { "Hearthstone", "Shiny Bauble", "Nightcrawlers", "Bright Baubles", "Aquadynamic Fish Attractor" }

local function Trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- "[cond] a; [cond] b" -> { "a", "b" }
local function Targets(args)
  local out = {}
  for part in (args .. ";"):gmatch("([^;]*);") do
    local t = Trim(part:gsub("%b[]", ""))
    t = Trim(t:gsub("^!", ""))
    if t ~= "" then out[#out + 1] = t end
  end
  return out
end
R.Targets = Targets

-- "/castsequence [cond] reset=5 A, B" arguments -> "A; B".
local function SplitList(args)
  local t = args:gsub("%b[]", ""):gsub("reset=%S+", "")
  return (t:gsub(",", ";"))
end

-- Item names the addon knows (ActionBars utility lists plus a few fixed
-- ones): a /cast or #showtooltip of one of these is an item in disguise.
function R.ItemNames(ns)
  local names = {}
  for _, n in ipairs(EXTRA_ITEMS) do names[n] = true end
  local ab = ns and ns.modules and ns.modules.actionbars
  for _, entry in ipairs(ab and ab.utility or {}) do
    if type(entry) == "table" then
      for _, v in ipairs(entry) do if type(v) == "string" then names[v] = true end end
    elseif type(entry) == "string" then names[entry] = true end
  end
  return names
end

-- Returns { { severity = "error"|"warn"|"info", rule = "...", msg = "..." }, ... }
-- items: optional set of item names (R.ItemNames(ns)).
function R.CheckMacro(m, body, items)
  body = body or m.body
  items = items or {}
  local out = {}
  local function Add(sev, rule, msg) out[#out + 1] = { severity = sev, rule = rule, msg = m.name .. ": " .. msg } end
  if #m.name > 16 then Add("error", "macro-name", "name longer than 16 characters") end
  if #body > 255 then Add("error", "macro-length", #body .. " characters; the limit is 255") end
  if body:sub(1, 12) ~= "#showtooltip" then Add("info", "macro-showtooltip", "doesn't start with #showtooltip") end
  local fishItems = {}
  for line in (body .. "\n"):gmatch("(.-)\n") do
    local t = Trim(line)
    local shown = t:match("^#show%a*%s+(.+)$")
    if shown and items[Trim(shown)] then Add("error", "macro-item", "shows item '" .. Trim(shown) .. "' in #showtooltip") end
    local cmd, rest = t:match("^(/%S+)%s*(.*)$")
    if cmd then
      cmd = cmd:lower()
      for cond in rest:gmatch("%[([^%]]*)%]") do
        for c in (cond .. ","):gmatch("([^,]*),") do
          c = Trim(c):lower()
          if c:match("^no?mod") or c:match("^mod") then
            if c:find("alt") and not (c:find("shift") or c:find("ctrl")) then Add("warn", "macro-modifier", "[" .. c .. "] (Alt)")
            else Add("error", "macro-modifier", "[" .. c .. "]: no Shift/Ctrl modifier variants") end
          elseif c:match("^@mouseover") or c:match("^@cursor") or c:match("^target%s*=%s*mouseover") or c:match("^target%s*=%s*cursor") then
            Add("error", "macro-mouse", "[" .. c .. "]: no @mouseover/@cursor")
          elseif c:match("^n?o?btn") or c:match("^n?o?button") then
            Add("warn", "macro-mouse", "[" .. c .. "]: mouse buttons don't exist on a controller")
          end
        end
      end
      if cmd == "/petpassive" then Add("error", "macro-petpassive", "/petpassive")
      elseif cmd == "/petattack" then Add("error", "macro-petattack", "/petattack (the owner wants none)")
      elseif ITEM_COMMANDS[cmd] then
        for _, target in ipairs(Targets(rest)) do
          local tg = cmd == "/equipslot" and target:gsub("^%d+%s*", "") or target
          -- A bare number ("13") or "bag slot" ("0 1") is a slot, not an item name.
          local isSlot = tg:match("^%d+$") or tg:match("^%d+%s+%d+$")
          if not isSlot then
            if m.name == "Fish" and cmd == "/equip" then fishItems[#fishItems + 1] = tg
            else Add("error", "macro-item", cmd .. " " .. tg .. " names an item") end
          end
        end
      elseif cmd == "/equipset" then Add("warn", "macro-equipset", "/equipset")
      elseif CAST_COMMANDS[cmd] then
        local args = cmd == "/cast" and rest or SplitList(rest)
        for _, target in ipairs(Targets(args)) do
          if items[target] then Add("error", "macro-item", cmd .. " " .. target .. " casts an item by name") end
        end
      elseif MENU[cmd] then Add("error", "macro-menu", cmd .. " is covered by a game menu")
      elseif cmd == "/run" or cmd == "/script" or cmd == "/dump" or cmd == "/console" then
        for _, p in ipairs(MENU_RUN) do
          if rest:find(p) then Add("error", "macro-menu", "/run " .. p .. " is covered by a game menu") end
        end
      end
    end
  end
  if #fishItems > 0 then Add("info", "macro-item", "/equip names " .. #fishItems .. " items (Fish exception approved by the owner)") end
  if m.untested then Add("info", "macro-untested", "marked untested") end
  return out
end

local KEYS = { "Q", "E", "R", "T", "F", "G", "C", "V", "1", "2", "3", "4" }
local PAD = { L4 = true, L5 = true, R4 = true, R5 = true }

-- Spell homes per device. Returns a list of problems: { severity, rule, msg }.
-- opts (all optional):
--   lib       { [name] = macro } the library, to check macro names and classes
--   retired   { [name] = body } L.retired
--   flyout    function(id) -> { spell names } to expand radials into homes
-- A back button that repeats a page-1 home is "info" (a mirror, allowed);
-- one that repeats a page 2 or 3 home is an error (owner rule).
function R.CheckLayout(Layout, class, opts)
  opts = opts or {}
  local out = {}
  local function Add(sev, rule, msg) out[#out + 1] = { severity = sev, rule = rule, msg = msg } end
  -- What an entry occupies: its spells, your racial, an item, a utility slot,
  -- a macro, a flyout (and, when opts.flyout knows them, the flyout's spells).
  local function Homes(entry)
    local list = {}
    if type(entry) ~= "table" then return list end
    for _, v in ipairs(entry) do if type(v) == "string" then list[#list + 1] = v end end
    if entry.racial then list[#list + 1] = "<racial>" end
    if entry.item then list[#list + 1] = "<item " .. tostring(entry.item) .. ">" end
    if entry.utility then list[#list + 1] = "<utility " .. tostring(entry.utility) .. ">" end
    if entry.macro then list[#list + 1] = "<macro " .. tostring(entry.macro) .. ">" end
    if entry.flyout then
      list[#list + 1] = "<flyout " .. tostring(entry.flyout) .. ">"
      local own = {}
      for _, v in ipairs(entry) do own[v] = true end
      for _, s in ipairs(opts.flyout and opts.flyout(entry.flyout) or {}) do
        if not own[s] then list[#list + 1] = s end
      end
    end
    return list
  end
  local function CheckEntry(entry, device, label)
    if type(entry) ~= "table" then Add("error", "layout-entry", label .. " is not a table entry") return end
    if device == "keyboard" and (entry.flyout or entry.petauto or entry.overflow) then
      Add("error", "layout-keyboard", label .. " uses a controller-only entry")
    end
    local macro = entry.macro
    if macro and opts.lib then
      local m = opts.lib[macro]
      if not m then
        Add("error", "layout-macro", label .. " uses macro '" .. macro .. "', which is "
          .. ((opts.retired or {})[macro] and "retired" or "not in the macro library"))
      elseif m.class and m.class ~= class then
        Add("error", "layout-macro", label .. " uses macro '" .. macro .. "', a " .. m.class .. " macro, in the " .. class .. " layout")
      end
    end
  end

  local kb = Layout.keyboard and Layout.keyboard[class]
  if kb then
    local homes = {}
    -- Keyed bars from the layout: 1 plain, 2 Shift, 4 Ctrl. Bar 3 (Alt) is
    -- the utility bar, filled by ActionBars, so a [3] here is never read.
    local MOD = { [1] = "", [2] = "Shift+", [4] = "Ctrl+" }
    if kb[3] ~= nil then Add("warn", "layout-keyboard", class .. " keyboard bar 3 is the Alt utility bar (ActionBars.utility); the layout's [3] is ignored") end
    for _, bar in ipairs({ 1, 2, 4 }) do
      local entries = kb[bar] or {}
      if #entries > 12 then Add("error", "layout-keyboard", class .. " keyboard bar " .. bar .. " has " .. #entries .. " entries; it has 12 keys") end
      for i, entry in pairs(entries) do
        local key = MOD[bar] .. (KEYS[i] or ("#" .. tostring(i)))
        CheckEntry(entry, "keyboard", class .. " keyboard " .. key)
        for _, s in ipairs(Homes(entry)) do
          if homes[s] then Add("error", "layout-two-homes", class .. " keyboard: " .. s .. " at " .. homes[s] .. " and " .. key)
          else homes[s] = key end
        end
      end
    end
  end

  local ct = Layout.controller and Layout.controller[class]
  if ct then
    local homes, homePage = {}, {}
    for p, page in ipairs(ct.pages or {}) do
      for key, entry in pairs(page) do
        if key ~= "title" then
          local here = "page " .. p .. " " .. key
          local layer, button = tostring(key):match("^(%S+) (%S+)$")
          local okLayer = layer == "none" or layer == "LT" or layer == "RT" or layer == "LT+RT"
          local okButton = button and ("|A|X|B|Y|Up|Down|Left|Right|"):find("|" .. button .. "|", 1, true)
          if not (okLayer and okButton) then
            Add("error", "layout-key", class .. " controller " .. here .. " is not '<none|LT|RT|LT+RT> <A|X|B|Y|Up|Down|Left|Right>'")
          elseif layer == "none" and (button == "A" or button == "X" or button == "B" or button == "Y") then
            Add("error", "layout-key", class .. " controller " .. here .. ": the Top bar's face buttons are fixed by the Gamepad UI")
          end
          CheckEntry(entry, "controller", class .. " controller " .. here)
          for _, s in ipairs(Homes(entry)) do
            if homes[s] then Add("error", "layout-two-homes", class .. " controller: " .. s .. " at " .. homes[s] .. " and " .. here)
            else homes[s], homePage[s] = here, p end
          end
        end
      end
    end
    local pads = {}
    for key, entry in pairs(ct.paddles or {}) do
      local base = tostring(key):gsub("^LT%+", "")
      if not PAD[base] then Add("error", "layout-key", class .. " back button " .. tostring(key) .. " is not L4/L5/R4/R5 (optionally LT+)") end
      CheckEntry(entry, "controller", class .. " back button " .. tostring(key))
      for _, s in ipairs(Homes(entry)) do
        if pads[s] then Add("error", "layout-two-homes", class .. " back buttons: " .. s .. " on " .. pads[s] .. " and " .. key) end
        pads[s] = key
        if homes[s] then
          if homePage[s] == 1 then
            Add("info", "layout-paddle-mirror", class .. " controller: " .. s .. " on back button " .. key .. " mirrors " .. homes[s])
          else
            Add("error", "layout-two-homes", class .. " controller: " .. s .. " on back button " .. key .. " and " .. homes[s]
              .. "; back buttons may mirror page-1 spells only")
          end
        end
      end
    end
  end
  return out
end

return R
