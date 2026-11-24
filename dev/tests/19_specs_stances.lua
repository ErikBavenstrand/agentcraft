-- Per-class layouts (Layouts/*.lua), specs and Bar 1 stance pages:
-- every class registers and passes the rules, spec detection (talents,
-- level, the character's choice), spec overrides, stance pages placed into
-- their bonus bar slots and put back by Undo, and the hunter unchanged by
-- the move out of Modules/Layout.lua.
local H = require("harness")

local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

local function Pad(t)
  for i = 1, 12 do if t[i] == nil then t[i] = false end end
  return t
end

-- A small warrior layout with all three stance pages.
local function WarriorLayout()
  return {
    specs = {
      { key = "arms", name = "Arms", tab = 1 },
      { key = "fury", name = "Fury", tab = 2, keyboard = { [2] = Pad({ { "Bloodrage" }, { "Battle Shout" } }) } },
      { key = "prot", name = "Protection", tab = 3, default = true },
    },
    keyboard = {
      [1] = Pad({ { "Heroic Strike" }, { "Rend" }, { "Execute" } }),
      [2] = Pad({ { "Battle Shout" }, { "Bloodrage" } }),
      [4] = Pad({}),
      stances = {
        battle = Pad({ offset = 1, label = "Battle", { "Heroic Strike" }, { "Overpower" }, { "Execute" } }),
        defensive = Pad({ offset = 2, label = "Defensive", { "Heroic Strike" }, { "Revenge" }, { "Sunder Armor" } }),
        berserker = Pad({ offset = 3, label = "Berserker", { "Heroic Strike" }, { "Whirlwind" }, { "Execute" } }),
      },
    },
  }
end

local function Warrior(opts)
  opts = opts or {}
  opts.fixture = "warrior"
  local loaded = opts.loaded
  opts.loaded = function(e)
    e.ns.Layout.Register("WARRIOR", WarriorLayout())
    if loaded then loaded(e) end
  end
  return H.boot(opts)
end

test("layouts: every class registers specs with one leveling default", function()
  local env = H.boot()
  local L = env.ns.Layout
  for _, class in ipairs(CLASSES) do
    local specs = L.Specs(class)
    eq(#specs, 3, class .. " specs")
    local defaults = 0
    for _, s in ipairs(specs) do if s.default then defaults = defaults + 1 end end
    eq(defaults, 1, class .. " default specs")
  end
end)

test("layouts: the rules accept every class (stubs too), checked against its fixture's spells", function()
  local env = H.boot()
  local lib = {}
  for _, m in ipairs(env.ns.MacroLibrary.macros) do lib[m.name] = m end
  local errors = {}
  for _, class in ipairs(CLASSES) do
    local fx = H.LoadFixture(class:lower())
    eq(fx.class[2], class, "fixture " .. class:lower() .. ".lua class token")
    local opts = { lib = lib, retired = env.ns.MacroLibrary.retired, spells = H.rules.FixtureSpells(fx) }
    if class == "HUNTER" then
      opts.flyout = function(id)
        local out = {}
        local _, _, n = env.G.GetFlyoutInfo(id)
        for slot = 1, n or 0 do out[#out + 1] = select(4, env.G.GetFlyoutSlotInfo(id, slot)) end
        return out
      end
    end
    for _, p in ipairs(H.rules.CheckLayout(env.ns.Layout, class, opts)) do
      if p.severity == "error" then errors[#errors + 1] = p.msg
      elseif p.severity == "warn" then note(p.msg) end
    end
  end
  if #errors > 0 then fail(table.concat(errors, "\n")) end
end)

test("layouts: every class boots with its fixture; the Keyboard and Controller pages open", function()
  for _, class in ipairs(CLASSES) do
    local env = H.boot({ fixture = class:lower(), db = { lastPage = "keyboard" } })
    env:slash("")
    env:runTimers(1)
    env.ns.OpenPage("controller")
    env:runTimers(1)
    env:slash("spells")
    noErrors(env)
  end
end)

test("hunter: unchanged by the move; one shared layout for all three specs", function()
  local env = H.boot()
  local L = env.ns.Layout
  eq(L.keyboard.HUNTER, L.classes.HUNTER.keyboard, "L.keyboard.HUNTER is the registered table")
  local kb = L.KeyboardBars("HUNTER")
  eq(kb[1][1].macro, "Arcane", "Q")
  eq(kb[2][2][1], "Bestial Wrath", "Shift+E chain")
  eq(kb[4][12][1], "Beast Lore", "Ctrl+4")
  eq(#kb.stances, 0, "no stance pages")
  for _, key in ipairs({ "bm", "mm", "sv" }) do
    local pages = L.ControllerPages("HUNTER", key)
    eq(pages[1]["RT A"].macro, "Arcane", key .. " controller RT A")
    eq(L.KeyboardBars("HUNTER", key)[1][4][1], "Summon Hawk", key .. " T")
  end
  local spec, auto = L.ActiveSpec("HUNTER")
  eq(spec.key, "bm", "no talents: the leveling spec")
  eq(auto, true)
  eq(L.SpecLabel("HUNTER"), "Automatic (Beast Mastery)")
end)

test("specs: detection by talent points, level and ties; the character's choice wins", function()
  local L
  local function Detect(opts)
    local env = H.boot(opts)
    L = env.ns.Layout
    return (L.DetectSpec("WARRIOR")), env
  end
  local W3 = function(a, f, p) return { { name = "Arms", points = a }, { name = "Fury", points = f }, { name = "Protection", points = p } } end
  eq(Detect({ fixture = "warrior", level = 5, talents = W3(0, 0, 0) }), "prot", "below 10: the leveling spec")
  eq(Detect({ fixture = "warrior", level = 9, talents = W3(31, 0, 0) }), "prot", "points below 10 don't count")
  eq(Detect({ fixture = "warrior", talents = W3(0, 0, 0) }), "prot", "no points: the leveling spec")
  eq(Detect({ fixture = "warrior", talents = W3(31, 5, 15) }), "arms", "most points")
  eq(Detect({ fixture = "warrior", talents = W3(2, 31, 18) }), "fury", "most points")
  eq(Detect({ fixture = "warrior", talents = W3(20, 0, 20) }), "prot", "a tie keeps the leveling spec")
  eq(Detect({ fixture = "warrior", talents = W3(20, 20, 0) }), "arms", "a tie without it: the first tab")
  -- Tab order is matched by name when the client names the tabs.
  eq(Detect({ fixture = "warrior", talents = { { name = "Protection", points = 30 }, { name = "Arms", points = 1 }, { name = "Fury", points = 0 } } }),
    "prot", "by tab name, not position")
  -- Druid's tab is "Feral Combat", the spec "Feral Combat" too.
  local env = H.boot({ fixture = "druid", talents = { { name = "Balance", points = 0 }, { name = "Feral Combat", points = 21 }, { name = "Restoration", points = 5 } } })
  eq((env.ns.Layout.DetectSpec("DRUID")), "feral")

  -- The choice (charDB.spec) wins over the talents; "auto" goes back.
  env = H.boot({ fixture = "warrior", talents = W3(31, 0, 0), charDB = { spec = "fury" } })
  L = env.ns.Layout
  local spec, auto, detected = L.ActiveSpec("WARRIOR")
  eq(spec.key, "fury"); eq(auto, false); eq(detected, "arms")
  eq(L.SpecLabel("WARRIOR"), "Fury")
  L.SetSpecChoice("auto")
  eq(env.ns.charDB.spec, nil, "Automatic clears the choice")
  eq(L.SpecLabel("WARRIOR"), "Automatic (Arms)")
  -- A stale choice (a key the class doesn't have) counts as Automatic.
  env.ns.charDB.spec = "gone"
  eq(L.ActiveSpec("WARRIOR").key, "arms")
end)

test("specs: a spec's own bar replaces that bar only; the rest stays shared", function()
  local env = Warrior()
  local L = env.ns.Layout
  local fury = L.KeyboardBars("WARRIOR", "fury")
  eq(fury[2][1][1], "Bloodrage", "fury Shift+Q from its own bar 2")
  eq(fury[1][1][1], "Heroic Strike", "bar 1 shared")
  eq(#fury.stances, 3, "stance pages shared")
  eq(L.KeyboardBars("WARRIOR", "arms")[2][1][1], "Battle Shout", "arms keeps the shared bar 2")
  eq(fury[1][4], nil, "false (an empty key) becomes nil")
end)

test("stances: Apply puts each stance page into its bonus bar slots; plan agrees; Undo restores", function()
  local env = Warrior({ talents = { { name = "Arms", points = 31 }, { name = "Fury", points = 0 }, { name = "Protection", points = 0 } } })
  local L = env.ns.Layout
  local pages = L.StancePages("WARRIOR")
  eq(#pages, 3)
  eq(pages[1].key, "battle"); eq(pages[1].first, 72)
  eq(pages[2].key, "defensive"); eq(pages[2].first, 84)
  eq(pages[3].key, "berserker"); eq(pages[3].first, 96)
  -- Something of yours on the Defensive page before the first Apply.
  env.W.actions[86] = { type = "spell", id = 772 } -- Rend on Defensive W... slot 2
  env.W.actions[110] = { type = "spell", id = 78 } -- moonkin-range slot: not managed
  local AB = env.ns.modules.actionbars
  local plan = AB.Plan()
  eq(#plan.stances, 3, "plan lists the stance pages")
  ok(plan.changes > 0)
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Heroic Strike", "no-stance page Q")
  eq(env:slotText(73), "spell:Heroic Strike", "Battle Q")
  eq(env:slotText(74), "spell:Overpower", "Battle E")
  eq(env:slotText(75), "spell:Execute", "Battle R")
  eq(env:slotText(86), "spell:Revenge", "Defensive E")
  eq(env:slotText(87), "spell:Sunder Armor", "Defensive R")
  eq(env:slotText(98), "spell:Whirlwind", "Berserker E")
  eq(env:slotText(76), nil, "an empty key stays empty")
  eq(env:slotText(110), "spell:Heroic Strike", "an unmanaged bonus bar is left alone")
  eq(AB.Plan().changes, 0, "no changes after Apply")
  -- Overpower and Revenge never land on a side bar too.
  for s = 37, 48 do
    local t = env:slotText(s)
    ok(t ~= "spell:Overpower" and t ~= "spell:Revenge" and t ~= "spell:Whirlwind", "side slot " .. s .. ": " .. tostring(t))
  end
  env:slash("spells undo")
  noErrors(env)
  eq(env:slotText(86), "spell:Rend", "your Defensive E back")
  eq(env:slotText(73), nil, "Battle Q empty again")
  eq(env:slotText(110), "spell:Heroic Strike", "still untouched")
  eq(env.ns.modules.actionbars.charDB.stanceBars, nil)
end)

test("stances: a spec without stance pages clears the pages Apply filled before; Undo still restores", function()
  local env = Warrior()
  env.W.actions[98] = { type = "spell", id = 6572 } -- yours: Revenge on Berserker E
  env:slash("spells apply")
  eq(env:slotText(98), "spell:Whirlwind")
  -- The arms spec drops its stance pages (a spec override with stances = false each).
  local def = env.ns.Layout.classes.WARRIOR
  def.specs[3].keyboard = { stances = { battle = false, defensive = false, berserker = false } }
  eq(#env.ns.Layout.StancePages("WARRIOR"), 0)
  local plan = env.ns.modules.actionbars.Plan()
  eq(#plan.stances, 3, "the old pages are still listed, to clear")
  eq(plan.stances[1][1].state, "clear")
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(73), nil, "cleared")
  eq(env.ns.modules.actionbars.charDB.stanceBars, nil, "no stance page managed now")
  env:slash("spells undo")
  eq(env:slotText(98), "spell:Revenge", "Undo restores the first backup")
end)

test("stances: Bar 1's keybinds need nothing extra; the bonus offset is read from the client", function()
  local env = Warrior({ bonusOffset = 2 })
  eq(env.ns.Layout.BonusOffset(), 2)
  env.W.bonusOffset = 0
  eq(env.ns.Layout.BonusOffset(), 0)
  env:slash("keys apply")
  noErrors(env)
  eq(env.W.bindings.Q, "ACTIONBUTTON1", "Q still fires Action Bar 1 (the game pages it)")
end)

test("rules: stance pages may repeat a spell on the same key only; 12 entries; one default", function()
  local env = Warrior()
  local L = env.ns.Layout
  local function Errors()
    -- The fury spec's own bar 2 makes the merged keyboard be checked again:
    -- the same finding then shows as "WARRIOR (fury) ...", counted once here.
    local out, seen = {}, {}
    for _, p in ipairs(H.rules.CheckLayout(L, "WARRIOR", {})) do
      local msg = p.msg:gsub("^WARRIOR %(%a+%)", "WARRIOR")
      if p.severity == "error" and not seen[msg] then seen[msg] = true; out[#out + 1] = msg end
    end
    return out
  end
  eq(#Errors(), 0, table.concat(Errors(), "\n"))
  local st = L.keyboard.WARRIOR.stances
  st.battle[4] = { "Execute" } -- Execute on R elsewhere, T here
  local e = Errors()
  ok(#e == 1 and e[1]:find("Execute", 1, true), table.concat(e, "\n"))
  st.battle[4] = false
  L.keyboard.WARRIOR[2][3] = { "Overpower" } -- Overpower on a stance page and on Shift
  e = Errors()
  ok(#e == 1 and e[1]:find("Overpower", 1, true), table.concat(e, "\n"))
  L.keyboard.WARRIOR[2][3] = false
  st.defensive[12] = nil
  e = Errors()
  ok(#e == 1 and e[1]:find("no entry 12", 1, true), table.concat(e, "\n"))
  st.defensive[12] = false
  st.defensive.offset = 7
  e = Errors()
  ok(#e == 1 and e[1]:find("offset", 1, true), table.concat(e, "\n"))
  st.defensive.offset = 2
  L.keyboard.WARRIOR[1][5] = { flyout = 1, "Charge" }
  e = Errors()
  ok(#e == 1 and e[1]:find("controller-only", 1, true), table.concat(e, "\n"))
  L.keyboard.WARRIOR[1][5] = false
  L.classes.WARRIOR.specs[1].default = true
  e = Errors()
  ok(#e == 1 and e[1]:find("2 default specs", 1, true), table.concat(e, "\n"))
end)

test("capture: each step records the bonus bar offset and the paged slots", function()
  local env = Warrior({ bonusOffset = 1 })
  env:slash("spells apply")
  local bars = env.ns.DevCapture.BarPaging()
  eq(bars["C_ActionBar.GetBonusBarOffset"], "1")
  eq(bars.GetBonusBarOffset, "1")
  ok(bars.bonus1:find("^spell:78 spell:7384 "), "Battle page slots: " .. tostring(bars.bonus1))
  ok(bars.bar1:find("^spell:78 "), "Bar 1: " .. tostring(bars.bar1))
  eq(bars.bonus4, "- - - - - - - - - - - -", "an unused bonus bar")
  eq(bars.spec, "Automatic (Protection)")
  noErrors(env)
end)

test("keyboard page: the Bar 1 page picker previews a stance page; the Inspector lists the key on every page", function()
  local env = Warrior({ db = { lastPage = "keyboard" }, bonusOffset = 2 })
  env:slash("")
  env:runTimers(1)
  local page = env.ns.PageById("keyboard")
  ok(page.stanceRow:IsShown(), "stance picker shown for a class with stance pages")
  ok(page.specRow:IsShown(), "spec picker shown")
  eq(page.specRow:ValueText(), "Automatic (Protection)")
  eq(page.stance, "defensive", "opens on the stance you are in")
  eq(page.stanceRow:ValueText(), "Defensive")
  -- E on the Plain layer shows the Defensive page's Revenge (After view).
  page.after = 2
  env.ns.UI.Refresh()
  eq(page.caps.E.cell.after.name, "Revenge")
  eq(page.caps.E.cell.slot, 86)
  -- The picker steps to Berserker: E becomes Whirlwind.
  page.stanceRow.Choose(4)
  env:runTimers(1)
  eq(page.stance, "berserker")
  eq(page.caps.E.cell.after.name, "Whirlwind")
  -- The Inspector lists E on every page.
  env.ns.Focus:Set(page.caps.E, "key")
  env:runTimers(0.5)
  local text = {}
  local function Walk(f)
    for _, r in ipairs({ f:GetRegions() }) do if r.GetText and r:GetText() then text[#text + 1] = r:GetText() end end
    for _, c in ipairs({ f:GetChildren() }) do Walk(c) end
  end
  Walk(env.ns.UI.pane and env.ns.UI.pane.frame or env.G.UIParent)
  local all = table.concat(text, "|")
  ok(all:find("E in each stance", 1, true), "stance section")
  ok(all:find("Overpower", 1, true) and all:find("Revenge", 1, true) and all:find("Whirlwind", 1, true), "every page's E")
  -- Review counts the stance pages.
  local groups = page:Review()
  local n = 0
  for _, g in ipairs(groups) do for _, it in ipairs(g.items) do if tostring(it.key):find("^Battle: ") then n = n + 1 end end end
  ok(n >= 3, "Battle page slots in the Review sheet: " .. n)
  -- Spec picker: choosing Fury refreshes the plan (fury's own Shift bar).
  page.specRow.Choose(3)
  env:runTimers(1)
  eq(env.ns.charDB.spec, "fury")
  eq(page.specRow:ValueText(), "Fury")
  noErrors(env)
end)

test("/ac spec shows and sets the spec; an unknown key is refused", function()
  local env = Warrior()
  env:slash("spec")
  ok(env:chatText():find("spec: Automatic (Protection)", 1, true), env:chatText())
  env:slash("spec fury")
  eq(env.ns.charDB.spec, "fury")
  env:slash("spec nope")
  eq(env.ns.charDB.spec, "fury", "unchanged")
  ok(env:chatText():find("unknown spec 'nope'", 1, true), env:chatText())
  env:slash("spec auto")
  eq(env.ns.charDB.spec, nil)
  noErrors(env)
end)

test("focus: with stance pages, the Keyboard page is fully reachable on the pad, no dead ends", function()
  local FC = require("focuscheck")
  local env = Warrior({ db = { lastPage = "keyboard", prompts = "pad" }, setup = function(W) W.gamepadUI = true end })
  env:slash("")
  env:runTimers(1)
  for _, id in ipairs({ "keyboard", "controller" }) do
    env.ns.OpenPage(id)
    env:runTimers(1)
    local r = FC.Walk(env)
    local function Names(list) local t = {} for i, n in ipairs(list) do t[i] = type(n) == "string" and n or FC.Label(n) end return table.concat(t, ", ") end
    eq(#r.unreachable, 0, id .. " unreachable: " .. Names(r.unreachable))
    eq(#r.arrowUnreachable, 0, id .. " unreachable without Tab: " .. Names(r.arrowUnreachableIds or {}))
    eq(#r.deadends, 0, id .. " dead ends: " .. Names(r.deadends))
    eq(#r.small, 0, id .. " small targets: " .. Names(r.small))
  end
  eq(env.ns.charDB.spec, nil, "the walk put the spec choice back")
  noErrors(env)
end)
