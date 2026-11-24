-- Generated item macros (owner decision, 2026-11-24): Fish, Bait, HealPot,
-- ManaPot, Bandage and Food name the best item you carry (Macros/Items.lua)
-- and Agentcraft rewrites them when that changes: debounced, never in
-- combat, only macros it wrote, only when the text changes. Their homes are
-- the same on every class: Alt+Q E R T F G and controller page 2 LT X Y B
-- Left, LT A and none Up.
local H = require("harness")

local CLASSES = { "druid", "hunter", "mage", "paladin", "priest", "rogue", "shaman", "warlock", "warrior" }
local ALT = 48 -- Action Bar 3 is slots 49-60: Alt+Q = 49

-- Controller storage slot for a page and "LT X"-style key (the page pattern
-- of dev/tests/27_druid.lua).
local LAYER = { none = 0, LT = 1, RT = 2, ["LT+RT"] = 3 }
local BUTTON = { Left = 1, Up = 2, Right = 3, Down = 4, X = 5, Y = 6, B = 7, A = 8 }
local function Pad(set, key)
  local layer, button = key:match("^(%S+) (%S+)$")
  local n = LAYER[layer] * 8 + BUTTON[button]
  return 180 + (set - 1) * 28 + (n < 5 and n or n - 4)
end

-- Test items, by ID (fixture IDs above 900000 are made up; names are real).
local ITEMS = {
  [900001] = { name = "Minor Healing Potion", minLevel = 1 },
  [900002] = { name = "Greater Healing Potion", minLevel = 21 },
  [900003] = { name = "Superior Healing Potion", minLevel = 35 },
  [900004] = { name = "Major Healthstone" },
  [900010] = { name = "Lesser Mana Potion", minLevel = 14 },
  [900011] = { name = "Major Mana Potion", minLevel = 49 },
  [900012] = { name = "Mana Citrine" },
  [900020] = { name = "Linen Bandage" },
  [900021] = { name = "Mageweave Bandage" },
  [900022] = { name = "Heavy Runecloth Bandage" },
  [900030] = { name = "Tough Jerky", minLevel = 1 },
  [900031] = { name = "Mutton Chop", minLevel = 15 },
  [900032] = { name = "Conjured Rye", minLevel = 15 },
  [900033] = { name = "Raw Brilliant Smallfish" },
  [900034] = { name = "Spiced Wolf Meat", minLevel = 1 },
  [900035] = { name = "Homemade Cherry Pie", minLevel = 45 },
  [900040] = { name = "Shiny Bauble" },
  [900041] = { name = "Bright Baubles" },
  [900050] = { name = "Strong Fishing Pole", minLevel = 10, classID = 2, subClassID = 20, subType = "Fishing Poles", equipLoc = "INVTYPE_2HWEAPON" },
  [900051] = { name = "Big Iron Fishing Pole", classID = 2, subClassID = 20, subType = "Fishing Poles", equipLoc = "INVTYPE_2HWEAPON" },
}

-- Boots a class with the test items known; bags = { itemID, ... } in bag 0.
-- skills = { ["First Aid"] = 150, Fishing = 50 } replaces the professions.
local function Boot(opts)
  opts = opts or {}
  return H.boot({ fixture = opts.fixture or "hunter", level = opts.level, macros = opts.macros, setup = function(W)
    for id, it in pairs(ITEMS) do W.fixture.items[id] = it end
    if opts.bags then
      local bag = { 6948 }
      for _, id in ipairs(opts.bags) do bag[#bag + 1] = id end
      W.fixture.bags = { [0] = bag }
    end
    if opts.skills then
      local list = {}
      for name, rank in pairs(opts.skills) do list[#list + 1] = { name = name, rank = rank, spells = {} } end
      table.sort(list, function(a, b) return a.name < b.name end)
      W.fixture.professions = list
    end
    if opts.mainHand ~= nil then W.fixture.equipped[16] = opts.mainHand or nil end
  end })
end

local function Lib(env, name)
  for _, m in ipairs(env.ns.MacroLibrary.macros) do if m.name == name then return m end end
  error("no library macro " .. name)
end

local function Body(env, name) return (env.ns.MacroLibrary.Resolve(Lib(env, name))) end

local function SetBags(env, ids)
  local bag = { 6948 }
  for _, id in ipairs(ids) do bag[#bag + 1] = id end
  env.W.fixture.bags = { [0] = bag }
end

local function MacroText(env, name)
  for _, m in ipairs(env.W.macros) do if m.name == name then return m.body, m end end
end

local function Install(env, names)
  local list = {}
  for _, n in ipairs(names) do list[#list + 1] = Lib(env, n) end
  env.ns.MacroLibrary.Install(list)
end

-- Selection ------------------------------------------------------------------------

test("item macros: HealPot takes a Healthstone first, else the best potion your level allows", function()
  local env = Boot({ level = 30, bags = { 900001, 900002, 900003 } })
  eq(Body(env, "HealPot"), "#showtooltip Greater Healing Potion\n/use Greater Healing Potion", "Superior needs 35")
  SetBags(env, { 900001, 900002, 900003, 900004 })
  eq(Body(env, "HealPot"), "#showtooltip Major Healthstone\n/use Major Healthstone", "the warlock's Healthstone first")
  SetBags(env, {})
  eq(Body(env, "HealPot"), "#showtooltip\n/run print(\"Agentcraft: no healing potion in your bags\")", "none carried")
end)

test("item macros: ManaPot takes a mana gem first, then the best potion; warriors and rogues get none", function()
  local env = Boot({ level = 40, bags = { 900010, 900011 } })
  eq(Body(env, "ManaPot"), "#showtooltip Lesser Mana Potion\n/use Lesser Mana Potion", "Major needs 49")
  SetBags(env, { 900010, 900012 })
  eq(Body(env, "ManaPot"), "#showtooltip Mana Citrine\n/use Mana Citrine", "the mage's gem first")
  local L = env.ns.MacroLibrary
  ok(L.Fits(Lib(env, "ManaPot")), "fits a hunter")
  for _, class in ipairs({ "warrior", "rogue" }) do
    local w = Boot({ fixture = class })
    ok(not w.ns.MacroLibrary.Fits(Lib(w, "ManaPot")), class .. ": ManaPot not offered")
    local e = w.ns.modules.actionbars.Plan()[3][2]
    eq(e.kind, "macro", class .. ": Alt+E keeps its macro home")
    eq(e.item.reason, "nomana", class .. ": empty for good")
    eq(w.ns.modules.controller.InstallText("ManaPot"), "Empty · your class has no mana")
    eq(w.ns.modules.controller.InstallText("HealPot"), "Waiting · install HealPot on the Macros page")
  end
end)

test("item macros: Bandage takes the best bandage your First Aid skill allows, on yourself", function()
  local env = Boot({ bags = { 900020, 900021, 900022 }, skills = { ["First Aid"] = 160 } })
  eq(Body(env, "Bandage"), "#showtooltip Mageweave Bandage\n/use [@player] Mageweave Bandage", "Heavy Runecloth needs 225")
  local none = Boot({ bags = { 900020, 900021, 900022 }, skills = { Fishing = 150 } })
  eq(Body(none, "Bandage"), "#showtooltip\n/run print(\"Agentcraft: no bandage you can use in your bags\")", "no First Aid: none usable")
end)

test("item macros: Food prefers conjured food, skips raw fish, eats buff food only when nothing else", function()
  local env = Boot({ level = 20, bags = { 900030, 900031, 900032, 900033, 900034, 900035 } })
  eq(Body(env, "Food"), "#showtooltip Conjured Rye\n/use Conjured Rye", "conjured wins its tier; the pie needs 45")
  SetBags(env, { 900030, 900031 })
  eq(Body(env, "Food"), "#showtooltip Mutton Chop\n/use Mutton Chop", "best tier for your level")
  SetBags(env, { 900033, 900034 })
  eq(Body(env, "Food"), "#showtooltip Spiced Wolf Meat\n/use Spiced Wolf Meat", "buff food when nothing else; never raw fish")
  SetBags(env, { 900033 })
  eq(Body(env, "Food"), "#showtooltip\n/run print(\"Agentcraft: no food in your bags\")", "raw fish is not food")
end)

test("item macros: Fish equips only a pole you carry; Bait uses only a lure you carry", function()
  local env = Boot({ bags = { 900050 }, mainHand = 12784, skills = { Fishing = 50 } })
  local body = Body(env, "Fish")
  ok(body:find("\n/equip Strong Fishing Pole$"), "equips the carried pole: " .. body)
  local equips = 0
  for _ in body:gmatch("/equip ") do equips = equips + 1 end
  eq(equips, 1, "one /equip, of a pole you carry")
  ok(body:find("[equipped:Fishing Poles] Fishing", 1, true), "keeps the pole-type cast check")
  SetBags(env, { 900050, 900051 })
  ok(Body(env, "Fish"):find("/equip Strong Fishing Pole", 1, true), "Big Iron needs Fishing 100")
  local skilled = Boot({ bags = { 900050, 900051 }, mainHand = 12784, skills = { Fishing = 150 } })
  ok(Body(skilled, "Fish"):find("/equip Big Iron Fishing Pole", 1, true), "the best pole your skill allows")
  local held = Boot({ bags = {}, mainHand = 900051, skills = { Fishing = 150 } })
  ok(Body(held, "Fish"):find("/equip Big Iron Fishing Pole", 1, true), "a pole in your hands counts as carried")
  local none = Boot({ bags = {}, mainHand = 12784 })
  eq(Body(none, "Fish"), "#showtooltip Fishing\n/run print(\"Agentcraft: no fishing pole in your bags\")")

  SetBags(env, { 900040, 900041 })
  eq(Body(env, "Bait"), "#showtooltip Shiny Bauble\n/use Shiny Bauble\n/use 16", "Bright Baubles needs Fishing 100")
  eq(Body(skilled, "Bait"), "#showtooltip\n/run print(\"Agentcraft: no fishing bait in your bags\")", "no lure carried")
end)

test("item macros: every listed item makes a body of 255 characters or less that passes the rules", function()
  local env = Boot({ level = 60, skills = { ["First Aid"] = 300, Fishing = 300 }, mainHand = 12784 })
  local L = env.ns.MacroLibrary
  local items = H.rules.ItemNames(env.ns)
  local kinds = { poles = "Fish", baits = "Bait", healthstones = "HealPot", healpots = "HealPot",
    managems = "ManaPot", manapots = "ManaPot", bandages = "Bandage", food = "Food", buffFood = "Food" }
  local n, errors = 0, {}
  for list, macro in pairs(kinds) do
    for k, e in ipairs(L.ITEMS[list]) do
      local id = 910000 + n
      env.W.fixture.items[id] = { name = e[1], classID = list == "poles" and 2 or 0,
        subClassID = list == "poles" and 20 or 0, subType = list == "poles" and "Fishing Poles" or nil }
      SetBags(env, { id })
      local body = Body(env, macro)
      ok(body and #body <= 255, e[1] .. ": " .. tostring(body and #body))
      ok(body and body:find(e[1], 1, true), list .. " " .. k .. " picks " .. e[1] .. ": " .. tostring(body))
      for _, p in ipairs(H.rules.CheckMacro(Lib(env, macro), body, items)) do
        if p.severity == "error" then errors[#errors + 1] = p.msg end
      end
      n = n + 1
    end
  end
  ok(n > 60, "lists checked: " .. n)
  if #errors > 0 then fail(table.concat(errors, "\n")) end
  -- A hand-written macro naming one of these items is still an error.
  local bad = 0
  for _, p in ipairs(H.rules.CheckMacro({ name = "Mine" }, "#showtooltip Major Healing Potion\n/use Major Healing Potion", items)) do
    if p.severity == "error" and p.rule == "macro-item" then bad = bad + 1 end
  end
  eq(bad, 2, "hand-written: #showtooltip and /use of an item are errors")
end)

-- Updating -------------------------------------------------------------------------

test("item macros: installed copies follow your bags, debounced, only when the text changes", function()
  local env = Boot({ level = 30, bags = { 900001 } })
  Install(env, { "HealPot" })
  local text, m = MacroText(env, "HealPot")
  eq(text, "#showtooltip Minor Healing Potion\n/use Minor Healing Potion")
  ok(m.perChar, "a character macro")
  eq(m.icon, "INV_Misc_QuestionMark", "question-mark icon: the button shows the item")
  env:resetCalls()
  SetBags(env, { 900001, 900002 })
  env:fire("BAG_UPDATE_DELAYED")
  env:runTimers(0.5)
  eq(#env:calls("EditMacro"), 0, "waits a second")
  env:fire("BAG_UPDATE_DELAYED")
  env:runTimers(0.8)
  eq(#env:calls("EditMacro"), 0, "a second event restarts the wait")
  env:runTimers(1)
  eq(#env:calls("EditMacro"), 1, "one rewrite for the burst")
  eq(MacroText(env, "HealPot"), "#showtooltip Greater Healing Potion\n/use Greater Healing Potion")
  env:fire("BAG_UPDATE_DELAYED")
  env:runTimers(2)
  eq(#env:calls("EditMacro"), 1, "same best item: not written again")
  -- Level and skill changes count too.
  SetBags(env, { 900002, 900003 })
  env.W.fixture.level = 40
  env:fire("PLAYER_LEVEL_UP", 40)
  env:runTimers(2)
  eq(MacroText(env, "HealPot"), "#showtooltip Superior Healing Potion\n/use Superior Healing Potion", "level 35 potion after the level up")
  SetBags(env, {})
  env:fire("BAG_UPDATE_DELAYED")
  env:runTimers(2)
  eq(MacroText(env, "HealPot"), "#showtooltip\n/run print(\"Agentcraft: no healing potion in your bags\")", "out of potions")
  eq(#env:calls("CreateMacro"), 0, "never creates one")
  noErrors(env)
end)

test("item macros: never rewritten in combat; the update waits until combat ends", function()
  local env = Boot({ level = 30, bags = { 900001 }, skills = { ["First Aid"] = 100 } })
  Install(env, { "HealPot", "Bandage" })
  env:resetCalls()
  env.W.inCombat = true
  SetBags(env, { 900002, 900020 })
  env:fire("BAG_UPDATE_DELAYED")
  env:runTimers(5)
  eq(#env:calls("EditMacro"), 0, "nothing in combat")
  ok(env.ns.modules.itemmacros.Queued(), "queued")
  env.W.inCombat = false
  env:fire("PLAYER_REGEN_ENABLED")
  env:runTimers(2)
  eq(#env:calls("EditMacro"), 2, "both rewritten after combat")
  eq(MacroText(env, "Bandage"), "#showtooltip Linen Bandage\n/use [@player] Linen Bandage")
  ok(not env.ns.modules.itemmacros.Queued(), "queue empty")
  noErrors(env)
end)

test("item macros: only a copy Agentcraft wrote, in the character tab, is ever rewritten", function()
  local env = Boot({ level = 30, bags = { 900001 } })
  -- Your own HealPot and Food, and an old account-tab Bait from before
  -- the item macros were per character.
  env.W.macros[#env.W.macros + 1] = { name = "HealPot", icon = "x", body = "/use Minor Healing Potion\n/say gulp", perChar = true }
  env.W.macros[#env.W.macros + 1] = { name = "Food", icon = "x", body = "/use Tough Jerky", perChar = true }
  local oldBait = "#showtooltip\n/use Shiny Bauble\n/use Nightcrawlers\n/use Bright Baubles\n/use Aquadynamic Fish Attractor\n/use 16"
  env.W.macros[#env.W.macros + 1] = { name = "Bait", icon = "x", body = oldBait, perChar = false }
  env:resetCalls()
  SetBags(env, { 900002, 900030, 900040 })
  env:fire("BAG_UPDATE_DELAYED")
  env:runTimers(2)
  eq(#env:calls("EditMacro"), 0, "none rewritten")
  local L = env.ns.MacroLibrary
  eq((L.State(Lib(env, "HealPot"))), "taken", "your HealPot is yours")
  eq((L.State(Lib(env, "Bait"))), "update", "the old Bait shows Update (moves it to the character tab)")
  Install(env, { "Bait" })
  local text, m = MacroText(env, "Bait")
  ok(m.perChar, "Update moved Bait to the character tab")
  eq(text, "#showtooltip Shiny Bauble\n/use Shiny Bauble\n/use 16")
  noErrors(env)
end)

-- Homes ----------------------------------------------------------------------------

local HOMES = {
  { alt = 1, key = "LT X", macro = "HealPot" },
  { alt = 2, key = "LT Y", macro = "ManaPot" },
  { alt = 3, key = "LT B", macro = "Bandage" },
  { alt = 4, key = "LT Left", macro = "Food" },
  { alt = 5, key = "none Up", macro = "Fish" },
  { alt = 6, key = "LT A", macro = "Bait" },
}

test("item macros: every class and spec has the same Alt keys and shared controller buttons", function()
  local seen
  for _, fixture in ipairs(CLASSES) do
    local env = Boot({ fixture = fixture })
    local AB, Layout = env.ns.modules.actionbars, env.ns.Layout
    local _, class = env.G.UnitClass("player")
    local found = {}
    for _, h in ipairs(HOMES) do
      local e = AB.utility[h.alt]
      eq(type(e) == "table" and e.macro, h.macro, fixture .. " Alt key " .. h.alt)
      found[#found + 1] = h.macro
    end
    local profile = AB.Plan()
    ok(profile, fixture .. " has a plan")
    -- No class layout overrides the Alt bar or the shared buttons.
    eq((Layout.KeyboardBars(class) or {})[3], nil, fixture .. ": no class Alt bar")
    local specs = { false }
    for _, s in ipairs((Layout.classes and Layout.classes[class] and Layout.classes[class].specs) or {}) do specs[#specs + 1] = s.key end
    ok(#specs >= 2, fixture .. ": its specs are checked too")
    for _, spec in ipairs(specs) do
      local pages = Layout.ControllerPages(class, spec or nil)
      for _, h in ipairs(HOMES) do
        local e = pages[2][h.key]
        local first = type(e) == "table" and (e.macro or e[1])
        eq(first, h.macro, fixture .. " " .. tostring(spec or "base") .. " page 2 " .. h.key)
      end
    end
    local sig = table.concat(found, ",")
    if seen then eq(sig, seen, fixture .. ": same homes as every class") end
    seen = sig
  end
end)

test("item macros: installed, Apply puts them on their homes on every class; Apply never creates them", function()
  for _, fixture in ipairs(CLASSES) do
    local env = Boot({ fixture = fixture })
    env:slash("spells apply")
    env:slash("controller apply")
    eq(#env:calls("CreateMacro"), 0, fixture .. ": Apply never creates a macro")
    local noMana = fixture == "warrior" or fixture == "rogue"
    for _, h in ipairs(HOMES) do
      if h.alt <= 4 then eq(env:slotText(ALT + h.alt), nil, fixture .. " Alt key " .. h.alt .. " waits") end
    end
    local names = { "HealPot", "Bandage", "Food" }
    if not noMana then names[#names + 1] = "ManaPot" end
    Install(env, names)
    env:resetCalls()
    env:slash("spells apply")
    env:slash("controller apply")
    noErrors(env)
    eq(#env:calls("CreateMacro"), 0, fixture .. ": Apply still creates none")
    for _, h in ipairs(HOMES) do
      if h.alt <= 4 then
        local want = "macro:" .. h.macro
        if h.macro == "ManaPot" and noMana then want = nil end
        eq(env:slotText(ALT + h.alt), want, fixture .. " Alt key " .. h.alt)
        eq(env:slotText(Pad(2, h.key)), want, fixture .. " controller page 2 " .. h.key)
      end
    end
  end
end)

test("item macros: the Macros page says it updates itself; homes list Alt and the controller", function()
  local env = H.boot({ db = { lastPage = "macros" }, setup = function(W)
    for id, it in pairs(ITEMS) do W.fixture.items[id] = it end
    W.fixture.bags = { [0] = { 6948, 900001 } }
  end })
  env:slash("")
  env:runTimers(1)
  local page = env.ns.PageById("macros")
  local card
  for _ = 1, 8 do
    for _, c in ipairs(page.cards) do if c:IsShown() and c.macro and c.macro.name == "HealPot" then card = c end end
    if card then break end
    page.next:Click()
  end
  ok(card, "HealPot card on the For You pages")
  local pane = { texts = {}, rows = {}, refs = {} }
  function pane:Header() end
  function pane:Code() end
  function pane:Buttons() end
  function pane:Empty() end
  function pane:Section() end
  function pane:Row(a, b) self.rows[#self.rows + 1] = tostring(a) .. "=" .. tostring(b) end
  function pane:Text(t) if t then self.texts[#self.texts + 1] = t end end
  function pane:CrossRef(list) for _, r in ipairs(list) do self.refs[#self.refs + 1] = r.text end end
  card.acInspect(card, pane)
  local texts = table.concat(pane.texts, "\n")
  ok(texts:find("Updates itself from your bags", 1, true), "updates line: " .. texts)
  ok(table.concat(pane.rows, "\n"):find("Uses=Minor Healing Potion", 1, true), "names the item it uses now")
  local refs = table.concat(pane.refs, "\n")
  ok(refs:find("Keyboard:", 1, true), "keyboard home (Alt+Q): " .. refs)
  ok(refs:find("Controller:", 1, true), "controller home (page 2 LT X): " .. refs)
  noErrors(env)
end)
