-- Warrior layouts: every spec resolves, Protection levels, Apply fills Bar 1,
-- its three stance pages, Shift, Ctrl and the controller by the shared key
-- roles (dev/key-roles.md), the plan agrees afterwards, installed
-- stance-dance macros take their homes, and nothing creates a macro.
local H = require("harness")

local function Boot(opts)
  opts = opts or {}
  opts.fixture = "warrior"
  return H.boot(opts)
end

local function Talents(arms, fury, prot)
  return { { name = "Arms", points = arms }, { name = "Fury", points = fury }, { name = "Protection", points = prot } }
end

-- Controller slot for page `set`, layer 0-3 (none LT RT LT+RT), button 1-8
-- (Left Up Right Down X Y B A).
local function Pad(set, layer, button)
  local n = layer * 8 + button
  return 180 + (set - 1) * 28 + (n < 5 and n or n - 4)
end

test("warrior: each spec's keyboard and controller resolve; the keyboard is shared", function()
  local env = Boot()
  local L = env.ns.Layout
  for _, spec in ipairs(L.Specs("WARRIOR")) do
    local kb = L.KeyboardBars("WARRIOR", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    eq(#kb.stances, 3, spec.key .. " stance pages")
    eq(kb[1][4][1], "Mortal Strike", spec.key .. " T chain")
    local pages = L.ControllerPages("WARRIOR", spec.key)
    ok(pages, spec.key .. " controller")
    eq(pages[1]["RT A"][1], "Heroic Strike", spec.key .. " RT A")
  end
  eq(L.ControllerPages("WARRIOR", "prot")[1]["LT X"].macro, "Revenge", "prot proc")
  eq(L.ControllerPages("WARRIOR", "arms")[1]["LT X"].macro, "Overpower", "arms proc")
  eq(L.ControllerPages("WARRIOR", "fury")[1]["RT Y"].macro, "Whirlwind", "fury AoE")
end)

test("warrior: Protection levels until talents say otherwise", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("WARRIOR").key, "prot")
  eq(Boot({ talents = Talents(31, 5, 0) }).ns.Layout.ActiveSpec("WARRIOR").key, "arms")
  eq(Boot({ talents = Talents(5, 31, 0) }).ns.Layout.ActiveSpec("WARRIOR").key, "fury")
end)

test("warrior: Apply fills Bar 1, its stance pages, Shift, Ctrl and the controller by key role; no macro is created", function()
  local env = Boot()
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  -- No-stance page (slots 1-12).
  eq(env:slotText(1), "spell:Heroic Strike", "Q main attack")
  eq(env:slotText(2), "spell:Rend", "E DoT")
  eq(env:slotText(3), "spell:Execute", "R big hitter")
  eq(env:slotText(4), nil, "T: no build signature learned")
  eq(env:slotText(5), "spell:Sunder Armor", "F builder")
  eq(env:slotText(6), "spell:Overpower", "G proc, without the Overpower macro")
  eq(env:slotText(7), "spell:Intercept", "C escape, without the Intercept macro")
  eq(env:slotText(8), "spell:Hamstring", "V snare")
  eq(env:slotText(9), "spell:Charge", "1 opener, without the TankCharge macro")
  eq(env:slotText(10), "spell:Cleave", "2 AoE")
  eq(env:slotText(11), "spell:Shield Bash", "3 interrupt, without the BashPummel macro")
  eq(env:slotText(12), "spell:Thunder Clap", "4 ground AoE")
  -- Battle (73-84), Defensive (85-96), Berserker (97-108).
  eq(env:slotText(73), "spell:Heroic Strike", "Battle Q")
  eq(env:slotText(78), "spell:Overpower", "Battle G")
  eq(env:slotText(79), nil, "Battle C empty")
  eq(env:slotText(83), "spell:Shield Bash", "Battle 3")
  eq(env:slotText(85), "spell:Heroic Strike", "Defensive Q")
  eq(env:slotText(87), nil, "Defensive R empty")
  eq(env:slotText(90), "spell:Revenge", "Defensive G")
  eq(env:slotText(96), "spell:Thunder Clap", "Defensive 4")
  eq(env:slotText(98), nil, "Berserker E empty")
  eq(env:slotText(99), "spell:Execute", "Berserker R")
  eq(env:slotText(102), "spell:Berserker Rage", "Berserker G")
  eq(env:slotText(103), "spell:Intercept", "Berserker C")
  eq(env:slotText(105), nil, "Berserker 1 waits for ChargeIntercept")
  eq(env:slotText(106), "spell:Whirlwind", "Berserker 2")
  eq(env:slotText(107), "spell:Pummel", "Berserker 3")
  -- Shift (Bar 2, 61-72) and Ctrl (Bar 4, 25-36).
  eq(env:slotText(61), "spell:Victory Rush", "Shift+Q self-heal")
  eq(env:slotText(62), "spell:Shield Block", "Shift+E: without talents, Shield Block")
  eq(env:slotText(68), "spell:Shield Wall", "Shift+V emergency")
  eq(env:slotText(69), "spell:Battle Stance", "Shift+1")
  eq(env:slotText(71), "spell:Berserker Stance", "Shift+3")
  eq(env:slotText(72), "spell:Battle Shout", "Shift+4")
  eq(env:slotText(29), "spell:Taunt", "Ctrl+F")
  eq(env:slotText(33), "spell:Bloodrage", "Ctrl+1")
  -- Stance-locked spells never land on a side bar too.
  for s = 37, 48 do
    local t = env:slotText(s)
    ok(t ~= "spell:Overpower" and t ~= "spell:Revenge" and t ~= "spell:Whirlwind" and t ~= "spell:Taunt",
      "side slot " .. s .. ": " .. tostring(t))
  end
  -- Controller page 1 (Protection).
  eq(env:slotText(Pad(1, 2, 8)), "spell:Heroic Strike", "controller RT A = Q")
  eq(env:slotText(Pad(1, 2, 5)), "spell:Rend", "controller RT X = E")
  eq(env:slotText(Pad(1, 2, 7)), "spell:Shield Bash", "controller RT B = 3")
  eq(env:slotText(Pad(1, 1, 5)), "spell:Revenge", "controller LT X = G, without the Revenge macro")
  eq(env:slotText(Pad(1, 1, 7)), "spell:Hamstring", "controller LT B = V")
  eq(env:slotText(Pad(1, 0, 2)), "spell:Battle Stance", "controller none Up")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("warrior: Fury's controller page 1 swaps in Overpower and Whirlwind", function()
  local env = Boot({ talents = Talents(5, 31, 0), macros = { "Whirlwind", "Overpower" } })
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(Pad(1, 2, 6)), "macro:Whirlwind", "RT Y")
  eq(env:slotText(Pad(1, 1, 5)), "macro:Overpower", "LT X")
  eq(env:slotText(Pad(1, 2, 8)), "spell:Heroic Strike", "RT A")
end)

test("warrior: installed stance-dance macros take their homes on every page they sit on", function()
  local env = Boot({ macros = { "Overpower", "Revenge", "TankCharge", "BashPummel", "ChargeIntercept" } })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(6), "macro:Overpower", "G")
  eq(env:slotText(78), "spell:Overpower", "Battle G stays the plain spell")
  eq(env:slotText(90), "macro:Revenge", "Defensive G")
  eq(env:slotText(9), "macro:TankCharge", "1")
  eq(env:slotText(81), "macro:TankCharge", "Battle 1")
  eq(env:slotText(93), "macro:TankCharge", "Defensive 1")
  eq(env:slotText(105), "macro:ChargeIntercept", "Berserker 1")
  eq(env:slotText(11), "macro:BashPummel", "3")
  eq(env:slotText(83), "spell:Shield Bash", "Battle 3")
  eq(env:slotText(Pad(1, 1, 5)), "macro:Revenge", "controller LT X")
  eq(#env:calls("CreateMacro"), 0)
end)

test("warrior: every macro fits the limits", function()
  local env = Boot()
  local n = 0
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "WARRIOR" then
      n = n + 1
      ok(#m.name <= 16, m.name)
      ok(#m.body <= 255, m.name .. " body length " .. #m.body)
      eq(m.perCharacter, true, m.name .. " perCharacter")
      eq(m.untested, true, m.name .. " untested")
    end
  end
  ok(n >= 10, "warrior macros: " .. n)
end)
