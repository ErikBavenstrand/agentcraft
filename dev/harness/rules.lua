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
            if (m.name == "Fish" and cmd == "/equip") or (m.name == "Bait" and cmd == "/use") then fishItems[#fishItems + 1] = tg
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
  if #fishItems > 0 then Add("info", "macro-item", "names " .. #fishItems .. " fishing items (Fish / Bait exception approved by the owner)") end
  if m.untested then Add("info", "macro-untested", "marked untested") end
  return out
end


local KEYS = { "Q", "E", "R", "T", "F", "G", "C", "V", "1", "2", "3", "4" }
local PAD = { L4 = true, L5 = true, R4 = true, R5 = true }
-- Fields a layout entry may have besides its spell names.
local ENTRY_FIELDS = { macro = "string", flyout = "any", utility = "number", item = "string", racial = "boolean",
  petauto = "boolean", overflow = "boolean", upgrade = "boolean", covers = "table", profession = "number" }
local KEYBOARD_FIELDS = { [1] = true, [2] = true, [3] = true, [4] = true, stances = true }
local SPEC_FIELDS = { key = true, name = true, tab = true, default = true, keyboard = true, controller = true }
-- Classic bonus bar offsets (Layout.STANCE_OFFSETS is the addon's copy).
local STANCE_OFFSETS = {
  WARRIOR = { battle = 1, defensive = 2, berserker = 3 },
  DRUID = { cat = 1, bear = 3, moonkin = 4 },
  ROGUE = { stealth = 1 },
  PRIEST = { shadowform = 1 },
}
R.STANCE_OFFSETS = STANCE_OFFSETS

local function SortedKeys(t)
  local k = {}
  for n in pairs(t) do k[#k + 1] = tostring(n) end
  table.sort(k)
  return table.concat(k, ", ")
end

-- Spell homes per device, for every spec of a class. Returns a list of
-- problems: { severity, rule, msg }.
-- opts (all optional):
--   lib       { [name] = macro } the library, to check macro names and classes
--   retired   { [name] = body } L.retired
--   flyout    function(id) -> { spell names } to expand radials into homes
--   spells    { [name] = true } every spell name the class may name (its
--             fixture, R.FixtureSpells): a name outside it is a warning
-- A back button that repeats a page-1 home is "info" (a mirror, allowed);
-- one that repeats a page 2 or 3 home is an error (owner rule).
-- Bar 1's stance pages may repeat a spell on the same key (the key is its
-- one home); on another key, or on Shift/Ctrl too, it is a second home.
function R.CheckLayout(Layout, class, opts)
  opts = opts or {}
  local out = {}
  local function Add(sev, rule, msg) out[#out + 1] = { severity = sev, rule = rule, msg = msg } end
  local profNames = Layout.ProfessionSpellNames and Layout.ProfessionSpellNames()
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
    if entry.profession then list[#list + 1] = "<profession " .. tostring(entry.profession) .. ">" end
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
    if entry == false and device == "keyboard" then return end -- a key left empty on purpose
    if type(entry) ~= "table" then Add("error", "layout-entry", label .. " is not a table entry") return end
    for k, v in pairs(entry) do
      if type(k) == "number" then
        if type(v) ~= "string" then Add("error", "layout-entry", label .. ": entry [" .. k .. "] is not a spell name") end
      elseif not ENTRY_FIELDS[k] then
        Add("error", "layout-entry", label .. ": unknown field '" .. tostring(k) .. "'")
      elseif ENTRY_FIELDS[k] ~= "any" and type(v) ~= ENTRY_FIELDS[k] then
        Add("error", "layout-entry", label .. ": " .. k .. " should be a " .. ENTRY_FIELDS[k])
      end
    end
    if opts.spells then
      for _, v in ipairs(entry) do
        if type(v) == "string" and not opts.spells[v] then
          Add("warn", "layout-unknown-spell", label .. ": '" .. v .. "' is not a spell in the " .. class .. " fixture")
        end
      end
      for _, v in ipairs(type(entry.covers) == "table" and entry.covers or {}) do
        if not opts.spells[v] then Add("warn", "layout-unknown-spell", label .. ": covers '" .. tostring(v) .. "', not a spell in the " .. class .. " fixture") end
      end
    end
    if device == "keyboard" and (entry.flyout or entry.petauto or entry.overflow or entry.profession) then
      Add("error", "layout-keyboard", label .. " uses a controller-only entry")
    end
    if type(entry.profession) == "number" and (entry.profession < 1 or entry.profession % 1 ~= 0) then
      Add("error", "layout-entry", label .. ": profession must be 1 or more (the Nth profession spell)")
    end
    -- Profession spells live in the shared { profession = n } slots and on
    -- Action Bar 6: a class layout never gives one a home of its own.
    if profNames then
      for _, v in ipairs(entry) do
        if type(v) == "string" and profNames[v] then
          Add("error", "layout-profession", label .. ": '" .. v .. "' is a profession spell; the shared profession slots are its home")
        end
      end
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
  -- A bar or stance page: 12 entries (false = a key left empty on purpose).
  local function CheckTwelve(entries, label)
    if type(entries) ~= "table" then Add("error", "layout-keyboard", label .. " is not a table") return false end
    local n = 0
    for k in pairs(entries) do if type(k) == "number" then n = math.max(n, k) end end
    if n > 12 then Add("error", "layout-keyboard", label .. " has " .. n .. " entries; it has 12 keys") end
    for i = 1, 12 do
      if entries[i] == nil then Add("error", "layout-keyboard", label .. " has no entry " .. i .. " (" .. KEYS[i] .. "); write false for a key left empty") end
    end
    return true
  end

  local function CheckKeyboard(kb, who)
    if type(kb) ~= "table" then Add("error", "layout-keyboard", who .. " keyboard is not a table") return end
    for k in pairs(kb) do
      if not KEYBOARD_FIELDS[k] then Add("error", "layout-keyboard", who .. " keyboard: unknown field '" .. tostring(k) .. "' (bars [1], [2], [4] and stances)") end
    end
    -- Keyed bars from the layout: 1 plain, 2 Shift, 4 Ctrl. Bar 3 (Alt) is
    -- the utility bar, filled by ActionBars, so a [3] here is never read.
    local MOD = { [1] = "", [2] = "Shift+", [4] = "Ctrl+" }
    if kb[3] ~= nil then Add("warn", "layout-keyboard", who .. " keyboard bar 3 is the Alt utility bar (ActionBars.utility); the layout's [3] is ignored") end
    -- homes[name] = { key = "Shift+E", bar1 = key index on a Bar 1 page or nil, pages = { [page] = true } }
    local homes = {}
    local function Home(entry, key, page, i)
      for _, s in ipairs(Homes(entry)) do
        local h = homes[s]
        if not h then
          homes[s] = { key = key, bar1 = page and i or nil, pages = { [page or ""] = true } }
        elseif page and h.bar1 == i and not h.pages[page] then
          h.pages[page] = true -- the same key on another stance page: still one home
        else
          Add("error", "layout-two-homes", who .. " keyboard: " .. s .. " at " .. h.key .. " and " .. key)
        end
      end
    end
    for _, bar in ipairs({ 1, 2, 4 }) do
      local entries = kb[bar]
      if entries ~= nil and CheckTwelve(entries, who .. " keyboard bar " .. bar) then
        for i = 1, 12 do
          local entry = entries[i]
          local key = MOD[bar] .. KEYS[i]
          if entry ~= nil then
            CheckEntry(entry, "keyboard", who .. " keyboard " .. key)
            Home(entry, key, bar == 1 and "base" or nil, i)
          end
        end
      end
    end
    if kb.stances == nil then return end
    if type(kb.stances) ~= "table" then Add("error", "layout-stance", who .. " keyboard stances is not a table") return end
    local offsets = {}
    for sk, st in pairs(kb.stances) do
      local label = who .. " stance page " .. tostring(sk)
      if type(st) ~= "table" then
        Add("error", "layout-stance", label .. " is not a table")
      else
        for k in pairs(st) do
          if type(k) ~= "number" and k ~= "offset" and k ~= "label" then
            Add("error", "layout-stance", label .. ": unknown field '" .. tostring(k) .. "' (offset, label and 12 entries)")
          end
        end
        local off = st.offset
        local known = STANCE_OFFSETS[class]
        if type(off) ~= "number" or off < 1 or off > 4 or off % 1 ~= 0 then
          Add("error", "layout-stance", label .. ": offset must be 1-4 (bonus bars 7-10, slots 73-120)")
        else
          if offsets[off] then Add("error", "layout-stance", label .. ": offset " .. off .. " is also " .. offsets[off]) end
          offsets[off] = tostring(sk)
          if not known then
            Add("warn", "layout-stance", label .. ": " .. class .. " has no stance, form or stealth paging")
          elseif not known[sk] then
            Add("warn", "layout-stance", label .. ": not a known " .. class .. " stance (known: " .. SortedKeys(known) .. ")")
          elseif known[sk] ~= off then
            Add("warn", "layout-stance", label .. ": offset " .. off .. ", but " .. tostring(sk) .. " is bonus bar offset " .. known[sk])
          end
        end
        if st.label ~= nil and type(st.label) ~= "string" then Add("error", "layout-stance", label .. ": label should be a string") end
        if CheckTwelve(st, label) then
          for i = 1, 12 do
            local entry = st[i]
            if entry ~= nil then
              local key = (type(st.label) == "string" and st.label or tostring(sk)) .. ": " .. KEYS[i]
              CheckEntry(entry, "keyboard", who .. " keyboard " .. key)
              Home(entry, key, tostring(sk), i)
            end
          end
        end
      end
    end
  end

  local function CheckController(ct, who)
    if type(ct) ~= "table" then Add("error", "layout-key", who .. " controller is not a table") return end
    local homes, homePage = {}, {}
    for p, page in ipairs(ct.pages or {}) do
      for key, entry in pairs(page) do
        if key ~= "title" then
          local here = "page " .. p .. " " .. key
          local layer, button = tostring(key):match("^(%S+) (%S+)$")
          local okLayer = layer == "none" or layer == "LT" or layer == "RT" or layer == "LT+RT"
          local okButton = button and ("|A|X|B|Y|Up|Down|Left|Right|"):find("|" .. button .. "|", 1, true)
          if not (okLayer and okButton) then
            Add("error", "layout-key", who .. " controller " .. here .. " is not '<none|LT|RT|LT+RT> <A|X|B|Y|Up|Down|Left|Right>'")
          elseif layer == "none" and (button == "A" or button == "X" or button == "B" or button == "Y") then
            Add("error", "layout-key", who .. " controller " .. here .. ": the Top bar's face buttons are fixed by the Gamepad UI")
          end
          CheckEntry(entry, "controller", who .. " controller " .. here)
          for _, s in ipairs(Homes(entry)) do
            if homes[s] then Add("error", "layout-two-homes", who .. " controller: " .. s .. " at " .. homes[s] .. " and " .. here)
            else homes[s], homePage[s] = here, p end
          end
        end
      end
    end
    local pads = {}
    for key, entry in pairs(ct.paddles or {}) do
      local base = tostring(key):gsub("^LT%+", "")
      if not PAD[base] then Add("error", "layout-key", who .. " back button " .. tostring(key) .. " is not L4/L5/R4/R5 (optionally LT+)") end
      CheckEntry(entry, "controller", who .. " back button " .. tostring(key))
      for _, s in ipairs(Homes(entry)) do
        if pads[s] then Add("error", "layout-two-homes", who .. " back buttons: " .. s .. " on " .. pads[s] .. " and " .. key) end
        pads[s] = key
        if homes[s] then
          if homePage[s] == 1 then
            Add("info", "layout-paddle-mirror", who .. " controller: " .. s .. " on back button " .. key .. " mirrors " .. homes[s])
          else
            Add("error", "layout-two-homes", who .. " controller: " .. s .. " on back button " .. key .. " and " .. homes[s]
              .. "; back buttons may mirror page-1 spells only")
          end
        end
      end
    end
  end

  -- Specs: keys unique, tabs 1-3 unique, exactly one leveling default.
  local def = Layout.classes and Layout.classes[class]
  local specs = def and def.specs or {}
  if def then
    if #specs == 0 then Add("error", "layout-spec", class .. " declares no specs") end
    local keys, tabs, defaults = {}, {}, 0
    for i, s in ipairs(specs) do
      local who = class .. " spec " .. i
      for k in pairs(s) do
        if not SPEC_FIELDS[k] then Add("error", "layout-spec", who .. ": unknown field '" .. tostring(k) .. "'") end
      end
      if type(s.key) ~= "string" or s.key == "" then Add("error", "layout-spec", who .. " has no key")
      elseif keys[s.key] then Add("error", "layout-spec", who .. ": key '" .. s.key .. "' is used twice")
      else keys[s.key] = true end
      if type(s.name) ~= "string" or s.name == "" then Add("error", "layout-spec", who .. " has no name") end
      if type(s.tab) ~= "number" or s.tab < 1 or s.tab > 3 then Add("error", "layout-spec", who .. ": tab must be 1-3 (the talent tab)")
      elseif tabs[s.tab] then Add("error", "layout-spec", who .. ": tab " .. s.tab .. " is also spec " .. tabs[s.tab])
      else tabs[s.tab] = tostring(s.key) end
      if s.default then defaults = defaults + 1 end
      if type(s.controller) == "table" then
        for k in pairs(s.controller) do
          if k ~= "pages" and k ~= "paddles" then Add("error", "layout-spec", who .. " controller: unknown field '" .. tostring(k) .. "' (pages, paddles)") end
        end
      end
    end
    if #specs > 0 and defaults ~= 1 then
      Add("error", "layout-spec", class .. " has " .. defaults .. " default specs; mark exactly one (the leveling spec)")
    end
  end

  -- The shared layout once, then each spec that overrides a device, merged.
  local kb = Layout.keyboard and Layout.keyboard[class]
  local ct = Layout.controller and Layout.controller[class]
  -- A class page never names a shared button (Layouts/Shared.lua): the
  -- shared one would replace it on every character.
  local sharedPages = Layout.shared and Layout.shared.controller and Layout.shared.controller.pages or {}
  local function CheckSharedKeys(pages, who)
    for p, page in pairs(type(pages) == "table" and pages or {}) do
      local add = type(page) == "table" and sharedPages[p]
      if add then
        for key in pairs(page) do
          if key ~= "title" and add[key] ~= nil then
            Add("error", "layout-shared", who .. " controller page " .. tostring(p) .. " " .. tostring(key)
              .. " is a shared button (Layouts/Shared.lua); leave it out of the class page")
          end
        end
      end
    end
  end
  if kb ~= nil then CheckKeyboard(kb, class) end
  if ct ~= nil then
    CheckSharedKeys(ct.pages, class)
    CheckController(Layout.WithShared and Layout.WithShared(ct) or ct, class)
  end
  for _, s in ipairs(specs) do
    if type(s.controller) == "table" then CheckSharedKeys(s.controller.pages, class .. " (" .. tostring(s.key) .. ")") end
  end
  -- A finding the shared layout already gave is not repeated for each spec.
  local shared = {}
  for _, p in ipairs(out) do shared[p.msg] = true end
  for _, s in ipairs(specs) do
    if type(s.key) == "string" and (s.keyboard ~= nil or s.controller ~= nil) and Layout.Resolve then
      local r = Layout.Resolve(class, s.key)
      local who = class .. " (" .. s.key .. ")"
      local before = #out
      if s.keyboard ~= nil and r.keyboard then CheckKeyboard(r.keyboard, who) end
      if s.controller ~= nil and r.controller then CheckController(r.controller, who) end
      for j = #out, before + 1, -1 do
        local m = out[j].msg
        if m:sub(1, #who) == who and shared[class .. m:sub(#who + 1)] then table.remove(out, j) end
      end
    end
  end
  return out
end

-- Every spell name a fixture models (spellbook, catalog, professions,
-- flyouts, otherSpells): opts.spells for CheckLayout.
function R.FixtureSpells(fx)
  local names = {}
  local function Add(list)
    for _, s in ipairs(list or {}) do names[type(s) == "table" and s.name or s] = true end
  end
  Add(fx.spells); Add(fx.catalog); Add(fx.otherSpells)
  for _, p in ipairs(fx.professions or {}) do names[p.name] = true; Add(p.spells) end
  for _, f in ipairs(fx.flyouts or {}) do Add(f.spells) end
  return names
end

return R
