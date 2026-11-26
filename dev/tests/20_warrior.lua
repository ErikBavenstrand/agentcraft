-- Warrior layouts: every spec resolves, Protection levels, Apply fills Bar 1,
-- its three stance pages, Shift, Ctrl and the controller with each spec's
-- rotation on the rotation slots (dev/key-roles.md), a level 10 Protection
-- warrior has its rotation on Q R T F (Shield Block, E, comes at 16), the plan agrees afterwards, installed
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

-- Moves the named catalog spells (talents) into the spellbook.
local function Learn(names)
  return function(W)
    local want = {}
    for _, n in ipairs(names) do want[n] = true end
    for _, s in ipairs(W.fixture.catalog) do
      if want[s.name] then table.insert(W.fixture.spells, { name = s.name, id = s.id }) end
    end
  end
end

-- Keeps only the named spells: a low-level spellbook.
local function Only(names)
  return function(W)
    local want, out = {}, {}
    for _, n in ipairs(names) do want[n] = true end
    for _, s in ipairs(W.fixture.spells) do
      if want[s.name] then out[#out + 1] = s end
    end
    W.fixture.spells = out
  end
end

-- Controller slot for page `set`, layer 0-3 (none LT RT LT+RT), button 1-8
-- (Left Up Right Down X Y B A).
local function Pad(set, layer, button)
  local n = layer * 8 + button
  return 180 + (set - 1) * 28 + (n < 5 and n or n - 4)
end

test("warrior: each spec's keyboard and controller resolve with its own rotation", function()
  local env = Boot()
  local L = env.ns.Layout
  for _, spec in ipairs(L.Specs("WARRIOR")) do
    local kb = L.KeyboardBars("WARRIOR", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    eq(#kb.stances, 3, spec.key .. " stance pages")
    ok(L.ControllerPages("WARRIOR", spec.key), spec.key .. " controller")
  end
  eq(L.KeyboardBars("WARRIOR", "prot")[1][1][1], "Sunder Armor", "prot Q")
  eq(L.KeyboardBars("WARRIOR", "arms")[1][1][1], "Mortal Strike", "arms Q")
  eq(L.KeyboardBars("WARRIOR", "fury")[1][1][1], "Bloodthirst", "fury Q")
  eq(L.KeyboardBars("WARRIOR", "prot")[1][2][1], "Shield Block", "prot E: Wowhead's first priority")
  eq(L.ControllerPages("WARRIOR", "prot")[1]["LT X"].macro, "Revenge", "prot reactive")
  eq(L.ControllerPages("WARRIOR", "prot")[1]["RT B"][1], "Taunt", "prot taunt on a face button")
  eq(L.ControllerPages("WARRIOR", "arms")[1]["LT X"].macro, "Overpower", "arms reactive")
  eq(L.ControllerPages("WARRIOR", "fury")[1]["RT X"].macro, "Whirlwind", "fury slot 2")
end)

test("warrior: Protection levels until talents say otherwise", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("WARRIOR").key, "prot")
  eq(Boot({ talents = Talents(31, 5, 0) }).ns.Layout.ActiveSpec("WARRIOR").key, "arms")
  eq(Boot({ talents = Talents(5, 31, 0) }).ns.Layout.ActiveSpec("WARRIOR").key, "fury")
end)

test("warrior: Apply puts the Protection rotation on the rotation slots of every page; no macro is created", function()
  local env = Boot()
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  -- No-stance page (slots 1-12): Q E R T F G C V 1 2 3 4.
  eq(env:slotText(1), "spell:Sunder Armor", "Q slot 1")
  eq(env:slotText(2), "spell:Shield Block", "E slot 2: mitigation")
  eq(env:slotText(3), "spell:Rend", "R slot 3: Rend until Shield Slam")
  eq(env:slotText(4), "spell:Heroic Strike", "T rage dump")
  eq(env:slotText(5), "spell:Taunt", "F taunt")
  eq(env:slotText(6), "spell:Revenge", "G reactive, without the Revenge macro")
  eq(env:slotText(7), "spell:Intercept", "C gap closer, without the Intercept macro")
  eq(env:slotText(8), "spell:Demoralizing Shout", "V pack debuff")
  eq(env:slotText(9), "spell:Charge", "1 opener, without the TankCharge macro")
  eq(env:slotText(10), "spell:Thunder Clap", "2 AoE threat")
  eq(env:slotText(11), "spell:Shield Bash", "3 interrupt, without the BashPummel macro")
  eq(env:slotText(12), "spell:Cleave", "4 pack dump")
  -- Battle (73-84): the stance's own taunt, finisher and proc.
  eq(env:slotText(73), "spell:Sunder Armor", "Battle Q")
  eq(env:slotText(74), "spell:Execute", "Battle E")
  eq(env:slotText(76), "spell:Heroic Strike", "Battle T")
  eq(env:slotText(77), "spell:Mocking Blow", "Battle F taunt")
  eq(env:slotText(78), "spell:Overpower", "Battle G")
  eq(env:slotText(83), "spell:Shield Bash", "Battle 3")
  -- Defensive (85-96): where Protection tanks.
  eq(env:slotText(85), "spell:Sunder Armor", "Defensive Q")
  eq(env:slotText(86), "spell:Shield Block", "Defensive E")
  eq(env:slotText(87), "spell:Rend", "Defensive R")
  eq(env:slotText(88), "spell:Heroic Strike", "Defensive T")
  eq(env:slotText(89), "spell:Taunt", "Defensive F")
  eq(env:slotText(90), "spell:Revenge", "Defensive G")
  eq(env:slotText(94), "spell:Thunder Clap", "Defensive 2")
  eq(env:slotText(96), "spell:Cleave", "Defensive 4")
  -- Berserker (97-108).
  eq(env:slotText(101), nil, "Berserker F: no taunt")
  eq(env:slotText(102), "spell:Berserker Rage", "Berserker G")
  eq(env:slotText(103), "spell:Intercept", "Berserker C")
  eq(env:slotText(106), "spell:Whirlwind", "Berserker 2")
  eq(env:slotText(107), "spell:Pummel", "Berserker 3")
  -- Shift (Bar 2, 61-72) and Ctrl (Bar 4, 25-36).
  eq(env:slotText(61), "spell:Victory Rush", "Shift+Q self-heal")
  eq(env:slotText(62), nil, "Shift+E waits for Last Stand")
  eq(env:slotText(63), "spell:Bloodrage", "Shift+R")
  eq(env:slotText(68), "spell:Shield Wall", "Shift+V emergency")
  eq(env:slotText(69), "spell:Battle Stance", "Shift+1")
  eq(env:slotText(72), "spell:Battle Shout", "Shift+4")
  eq(env:slotText(25), "spell:Challenging Shout", "Ctrl+Q")
  eq(env:slotText(26), "spell:Retaliation", "Ctrl+E")
  eq(env:slotText(28), "spell:Hamstring", "Ctrl+T")
  -- Stance-locked rotation spells never land on a side bar too.
  for s = 37, 48 do
    local t = env:slotText(s)
    ok(t ~= "spell:Overpower" and t ~= "spell:Revenge" and t ~= "spell:Whirlwind" and t ~= "spell:Taunt",
      "side slot " .. s .. ": " .. tostring(t))
  end
  -- Controller page 1: the tank rotation on face buttons and the RT D-pad.
  eq(env:slotText(Pad(1, 2, 8)), "spell:Sunder Armor", "RT A = Q")
  eq(env:slotText(Pad(1, 2, 5)), "spell:Shield Block", "RT X = E")
  eq(env:slotText(Pad(1, 2, 6)), "spell:Rend", "RT Y = R")
  eq(env:slotText(Pad(1, 2, 7)), "spell:Taunt", "RT B = F")
  eq(env:slotText(Pad(1, 1, 8)), "spell:Heroic Strike", "LT A = T")
  eq(env:slotText(Pad(1, 1, 5)), "spell:Revenge", "LT X = G, without the Revenge macro")
  eq(env:slotText(Pad(1, 1, 7)), "spell:Shield Bash", "LT B = 3")
  eq(env:slotText(Pad(1, 1, 6)), "spell:Thunder Clap", "LT Y = 2")
  eq(env:slotText(Pad(1, 2, 2)), "spell:Charge", "RT Up = 1")
  eq(env:slotText(Pad(1, 2, 4)), "spell:Cleave", "RT Down = 4")
  eq(env:slotText(Pad(1, 2, 3)), "spell:Demoralizing Shout", "RT Right = V")
  eq(env:slotText(Pad(1, 0, 2)), "spell:Battle Stance", "none Up")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("warrior: a level 10 Protection warrior has its rotation on Q R T F and the face buttons", function()
  local env = Boot({ level = 10, setup = Only({ "Battle Stance", "Heroic Strike", "Charge", "Rend",
    "Thunder Clap", "Hamstring", "Bloodrage", "Battle Shout", "Defensive Stance", "Sunder Armor", "Taunt" }) })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(85), "spell:Sunder Armor", "Defensive Q")
  eq(env:slotText(86), nil, "Defensive E waits for Shield Block (16)")
  eq(env:slotText(87), "spell:Rend", "Defensive R")
  eq(env:slotText(88), "spell:Heroic Strike", "Defensive T")
  eq(env:slotText(89), "spell:Taunt", "Defensive F")
  eq(env:slotText(93), "spell:Charge", "Defensive 1")
  eq(env:slotText(94), "spell:Thunder Clap", "Defensive 2")
  eq(env:slotText(Pad(1, 2, 8)), "spell:Sunder Armor", "RT A")
  eq(env:slotText(Pad(1, 2, 6)), "spell:Rend", "RT Y")
  eq(env:slotText(Pad(1, 2, 7)), "spell:Taunt", "RT B")
  eq(env:slotText(Pad(1, 1, 8)), "spell:Heroic Strike", "LT A")
  eq(env:slotText(Pad(1, 1, 6)), "spell:Thunder Clap", "LT Y")
end)

test("warrior: Shield Slam takes Protection's slot 3 and Last Stand its Shift+E once talented", function()
  local env = Boot({ talents = Talents(0, 5, 31), setup = Learn({ "Shield Slam", "Last Stand", "Concussion Blow" }) })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(87), "spell:Shield Slam", "Defensive R")
  eq(env:slotText(62), "spell:Last Stand", "Shift+E")
  eq(env:slotText(64), "spell:Concussion Blow", "Shift+T")
  eq(env:slotText(Pad(1, 2, 6)), "spell:Shield Slam", "RT Y")
end)

test("warrior: Fury-Prot gets Bloodthirst on Protection's slot 3 and Death Wish on Ctrl+G", function()
  local env = Boot({ talents = Talents(0, 20, 31), setup = Learn({ "Bloodthirst", "Death Wish" }) })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(87), "spell:Bloodthirst", "Defensive R")
  eq(env:slotText(30), "spell:Death Wish", "Ctrl+G")
  eq(env:slotText(Pad(1, 2, 6)), "spell:Bloodthirst", "RT Y")
end)

test("warrior: Arms gets its rotation in Battle Stance and on the pad", function()
  local env = Boot({ talents = Talents(31, 5, 0), setup = Learn({ "Mortal Strike", "Sweeping Strikes", "Spearing Strike" }) })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(73), "spell:Mortal Strike", "Battle Q")
  eq(env:slotText(74), "spell:Rend", "Battle E")
  eq(env:slotText(75), "spell:Slam", "Battle R")
  eq(env:slotText(76), "spell:Execute", "Battle T")
  eq(env:slotText(77), "spell:Heroic Strike", "Battle F")
  eq(env:slotText(78), "spell:Overpower", "Battle G")
  eq(env:slotText(80), "spell:Spearing Strike", "Battle V")
  eq(env:slotText(84), "spell:Sweeping Strikes", "Battle 4")
  eq(env:slotText(106), "spell:Whirlwind", "Berserker 2")
  eq(env:slotText(27), "spell:Hamstring", "Ctrl+R")
  eq(env:slotText(Pad(1, 2, 8)), "spell:Mortal Strike", "RT A")
  eq(env:slotText(Pad(1, 2, 6)), "spell:Slam", "RT Y")
  eq(env:slotText(Pad(1, 2, 7)), "spell:Heroic Strike", "RT B")
  eq(env:slotText(Pad(1, 1, 8)), "spell:Execute", "LT A")
  eq(env:slotText(Pad(1, 1, 5)), "spell:Overpower", "LT X, without the Overpower macro")
  eq(env:slotText(Pad(1, 2, 3)), "spell:Spearing Strike", "RT Right")
  eq(env:slotText(Pad(1, 3, 1)), "spell:Whirlwind", "LT+RT Left: Whirlwind, without the macro")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("warrior: Fury gets Bloodthirst and Whirlwind on slots 1 and 2", function()
  local env = Boot({ talents = Talents(5, 31, 0), macros = { "Whirlwind", "Overpower" },
    setup = Learn({ "Bloodthirst", "Death Wish", "Piercing Howl", "Reckless Swings" }) })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(97), "spell:Bloodthirst", "Berserker Q")
  eq(env:slotText(98), "spell:Whirlwind", "Berserker E")
  eq(env:slotText(99), "spell:Heroic Strike", "Berserker R")
  eq(env:slotText(108), "spell:Reckless Swings", "Berserker 4")
  eq(env:slotText(74), "macro:Whirlwind", "Battle E dances to Berserker")
  eq(env:slotText(62), "spell:Bloodrage", "Shift+E sustain")
  eq(env:slotText(63), "spell:Death Wish", "Shift+R burst")
  eq(env:slotText(68), "spell:Piercing Howl", "Shift+V escape")
  eq(env:slotText(Pad(1, 2, 8)), "spell:Bloodthirst", "RT A")
  eq(env:slotText(Pad(1, 2, 5)), "macro:Whirlwind", "RT X")
  eq(env:slotText(Pad(1, 2, 6)), "spell:Heroic Strike", "RT Y")
  eq(env:slotText(Pad(1, 1, 5)), "macro:Overpower", "LT X")
  eq(env:slotText(Pad(1, 2, 4)), "spell:Reckless Swings", "RT Down")
  eq(env:slotText(Pad(1, 3, 8)), "spell:Piercing Howl", "LT+RT A")
end)

test("warrior: installed stance-dance macros take their homes on every page they sit on", function()
  local env = Boot({ macros = { "Overpower", "Revenge", "TankCharge", "BashPummel", "Intercept", "ShieldWall" } })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(6), "macro:Revenge", "G")
  eq(env:slotText(90), "spell:Revenge", "Defensive G stays the plain spell")
  eq(env:slotText(9), "macro:TankCharge", "1")
  eq(env:slotText(81), "macro:TankCharge", "Battle 1")
  eq(env:slotText(93), "macro:TankCharge", "Defensive 1")
  eq(env:slotText(105), "macro:TankCharge", "Berserker 1")
  eq(env:slotText(91), "macro:Intercept", "Defensive C")
  eq(env:slotText(103), "spell:Intercept", "Berserker C stays the plain spell")
  eq(env:slotText(11), "macro:BashPummel", "3")
  eq(env:slotText(83), "spell:Shield Bash", "Battle 3")
  eq(env:slotText(68), "macro:ShieldWall", "Shift+V")
  eq(env:slotText(Pad(1, 1, 5)), "macro:Revenge", "controller LT X")
  eq(env:slotText(Pad(1, 2, 2)), "macro:TankCharge", "controller RT Up")
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

test("warrior: installed recommended wrappers take Q, R and the taunt; their fallbacks hold until then", function()
  local env = Boot({ talents = Talents(0, 5, 31), macros = { "Sunder", "ShieldSlam", "Taunt" },
    setup = Learn({ "Shield Slam" }) })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "macro:Sunder", "Q")
  eq(env:slotText(73), "macro:Sunder", "Battle Q")
  eq(env:slotText(85), "macro:Sunder", "Defensive Q")
  eq(env:slotText(97), "macro:Sunder", "Berserker Q")
  eq(env:slotText(87), "macro:ShieldSlam", "Defensive R")
  eq(env:slotText(5), "macro:Taunt", "F")
  eq(env:slotText(89), "spell:Taunt", "Defensive F stays the plain spell")
  eq(env:slotText(Pad(1, 2, 8)), "macro:Sunder", "controller RT A")
  eq(env:slotText(Pad(1, 2, 6)), "macro:ShieldSlam", "controller RT Y")
  eq(env:slotText(Pad(1, 2, 7)), "macro:Taunt", "controller RT B")
  eq(#env:calls("CreateMacro"), 0)
  -- Before Shield Slam, Rend holds R even with ShieldSlam installed.
  local low = Boot({ macros = { "ShieldSlam", "MortalStrike", "Bloodthirst" } })
  low:slash("spells apply")
  eq(low:slotText(87), "spell:Rend", "Defensive R before Shield Slam")
end)

test("warrior: Arms and Fury wrappers take slot 1 once installed", function()
  local arms = Boot({ talents = Talents(31, 5, 0), macros = { "MortalStrike" }, setup = Learn({ "Mortal Strike" }) })
  arms:slash("spells apply")
  arms:slash("controller apply")
  eq(arms:slotText(73), "macro:MortalStrike", "Battle Q")
  eq(arms:slotText(Pad(1, 2, 8)), "macro:MortalStrike", "controller RT A")
  local fury = Boot({ talents = Talents(5, 31, 0), macros = { "Bloodthirst" }, setup = Learn({ "Bloodthirst" }) })
  fury:slash("spells apply")
  fury:slash("controller apply")
  eq(fury:slotText(97), "macro:Bloodthirst", "Berserker Q")
  eq(fury:slotText(Pad(1, 2, 8)), "macro:Bloodthirst", "controller RT A")
end)

test("warrior: recommended macros name real spec keys, and every spec has some", function()
  local env = Boot()
  local keys, per = {}, {}
  for _, spec in ipairs(env.ns.Layout.Specs("WARRIOR")) do keys[spec.key] = true; per[spec.key] = 0 end
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "WARRIOR" and m.specs then
      local tagged = false
      for _, t in ipairs(m.tags or {}) do if t == "recommended" then tagged = true end end
      ok(tagged, m.name .. " has the recommended tag")
      for _, k in ipairs(m.specs) do
        ok(keys[k], m.name .. ": spec key " .. tostring(k))
        if per[k] then per[k] = per[k] + 1 end
      end
    end
  end
  for k, n in pairs(per) do ok(n >= 2, k .. " recommended macros: " .. n) end
end)
