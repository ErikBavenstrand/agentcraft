-- Mage layouts: rotation first (dev/key-roles.md). Frost shared, Fire and
-- Arcane with their own Bar 1, Shift, Ctrl and controller page 1. Apply fills
-- the bars and the controller, low-level spells fill the rotation slots,
-- talents take their keys, the plan agrees afterwards, an installed macro
-- takes its home and nothing creates a macro.
local H = require("harness")

local function T3(arcane, fire, frost)
  return { { name = "Arcane", points = arcane }, { name = "Fire", points = fire }, { name = "Frost", points = frost } }
end

-- Boots the mage fixture with extra learned spells (talents the fixture
-- keeps in its catalog).
local function Boot(opts, learn)
  opts = opts or {}
  opts.fixture = "mage"
  local setup = opts.setup
  opts.setup = function(W)
    for i, name in ipairs(learn or {}) do
      table.insert(W.fixture.spells, { name = name, id = 980000 + i })
    end
    if setup then setup(W) end
  end
  return H.boot(opts)
end

-- Gamepad slot of "<layer> <button>" on a page (dev/layout-format.md).
local LAYER = { none = 0, LT = 1, RT = 2, ["LT+RT"] = 3 }
local BUTTON = { Left = 1, Up = 2, Right = 3, Down = 4, X = 5, Y = 6, B = 7, A = 8 }
local function Pad(set, key)
  local layer, button = key:match("^(%S+) (%S+)$")
  local n = LAYER[layer] * 8 + BUTTON[button]
  return 180 + (set - 1) * 28 + (n < 5 and n or n - 4)
end

test("mage: each spec's keyboard and controller resolve; no stance pages", function()
  local L = Boot().ns.Layout
  for _, spec in ipairs(L.Specs("MAGE")) do
    local kb = L.KeyboardBars("MAGE", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    ok(L.ControllerPages("MAGE", spec.key), spec.key .. " controller")
    ok(not kb.stances or next(kb.stances) == nil, spec.key .. " has no stance pages")
  end
end)

test("mage: Frost is the leveling spec until talents say otherwise", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("MAGE").key, "frost")
  eq(Boot({ talents = T3(31, 5, 0) }).ns.Layout.ActiveSpec("MAGE").key, "arcane")
  eq(Boot({ talents = T3(0, 31, 10) }).ns.Layout.ActiveSpec("MAGE").key, "fire")
end)

test("mage: no talents: the Frost rotation fills Q E R F and the pad's face buttons; no macro is created", function()
  local env = Boot()
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Frostbolt", "Q slot 1")
  eq(env:slotText(2), "spell:Cone of Cold", "E slot 2")
  eq(env:slotText(3), "spell:Frost Nova", "R slot 3")
  eq(env:slotText(4), "spell:Frostfire Bolt", "T Frost-immune nuke")
  eq(env:slotText(5), "spell:Arcane Missiles", "F slot 4: Missile Barrage")
  eq(env:slotText(6), nil, "G: no Ice Lance yet")
  eq(env:slotText(7), "spell:Blink", "C mobility")
  eq(env:slotText(8), "spell:Flamestrike", "V second ground AoE")
  eq(env:slotText(9), nil, "1: no Ice Barrier yet")
  eq(env:slotText(10), "spell:Arcane Explosion", "2 main AoE")
  eq(env:slotText(11), "spell:Counterspell", "3 interrupt")
  eq(env:slotText(12), "spell:Blizzard", "4 ground AoE")
  eq(env:slotText(61), "spell:Evocation", "Shift+Q sustain")
  eq(env:slotText(62), "spell:Mana Shield", "Shift+E defensive")
  eq(env:slotText(64), nil, "Shift+T waits for PolyFocus")
  eq(env:slotText(65), "spell:Polymorph", "Shift+F hard CC")
  eq(env:slotText(67), "spell:Perception", "Shift+C racial")
  eq(env:slotText(69), "spell:Ice Armor", "Shift+1 (ArmorSwap not installed)")
  eq(env:slotText(33), "spell:Arcane Brilliance", "Ctrl+1")
  eq(env:slotText(Pad(1, "RT A")), "spell:Frostbolt", "controller RT A = Q")
  eq(env:slotText(Pad(1, "RT X")), "spell:Cone of Cold", "controller RT X = E")
  eq(env:slotText(Pad(1, "RT Y")), "spell:Frost Nova", "controller RT Y = R")
  eq(env:slotText(Pad(1, "RT B")), "spell:Arcane Missiles", "controller RT B = F")
  eq(env:slotText(Pad(1, "LT B")), "spell:Counterspell", "controller LT B = 3")
  eq(env:slotText(Pad(1, "LT Y")), "spell:Arcane Explosion", "controller LT Y = 2")
  eq(env:slotText(Pad(1, "RT Down")), "spell:Blizzard", "controller RT Down = 4")
  eq(env:slotText(Pad(1, "RT Left")), "spell:Blink", "controller RT Left = C")
  eq(env:slotText(Pad(2, "RT A")), "spell:Ice Armor", "controller page 2 RT A")
  eq(env:slotText(Pad(2, "RT Left")), "spell:Teleport: Stormwind", "controller page 2 RT Left (Alliance)")
  eq(env:slotText(Pad(3, "RT A")), "spell:Slow Fall", "controller page 3 RT A")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("mage: a level 10 Frost mage has its rotation on Q E R F", function()
  local env = Boot({ level = 10, setup = function(W)
    local keep = { Fireball = true, Frostbolt = true, ["Fire Blast"] = true, ["Arcane Missiles"] = true,
      ["Frost Nova"] = true, ["Frost Armor"] = true, ["Arcane Intellect"] = true, Polymorph = true, Perception = true }
    local spells = {}
    for _, s in ipairs(W.fixture.spells) do if keep[s.name] then spells[#spells + 1] = s end end
    W.fixture.spells = spells
  end })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Frostbolt", "Q")
  eq(env:slotText(2), "spell:Fire Blast", "E until Cone of Cold")
  eq(env:slotText(3), "spell:Frost Nova", "R")
  eq(env:slotText(5), "spell:Arcane Missiles", "F")
  eq(env:slotText(4), "spell:Fireball", "T until Frostfire Bolt")
end)

test("mage: Frost talents take G, 1, Shift+R and Shift+V", function()
  local env = Boot({ talents = T3(10, 0, 41) }, { "Ice Lance", "Ice Barrier", "Ice Block", "Cold Snap" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(6), "spell:Ice Lance", "G reactive")
  eq(env:slotText(9), "spell:Ice Barrier", "1 pre-pull shield")
  eq(env:slotText(63), "spell:Cold Snap", "Shift+R")
  eq(env:slotText(68), "spell:Ice Block", "Shift+V emergency")
  eq(env:slotText(Pad(1, "LT X")), "spell:Ice Lance", "controller LT X = G")
  eq(env:slotText(Pad(1, "RT Up")), "spell:Ice Barrier", "controller RT Up = 1")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("mage: Fire and Arcane put their own rotations on the same slots", function()
  local fire = Boot({ talents = T3(0, 31, 0) }, { "Pyroblast", "Combustion", "Blast Wave" })
  fire:slash("spells apply")
  fire:slash("controller apply")
  noErrors(fire)
  eq(fire:slotText(1), "spell:Fireball", "Fire Q")
  eq(fire:slotText(2), "spell:Scorch", "Fire E")
  eq(fire:slotText(3), "spell:Fire Blast", "Fire R")
  eq(fire:slotText(4), "spell:Blast Wave", "Fire T")
  eq(fire:slotText(5), "spell:Arcane Missiles", "Fire F: Missile Barrage")
  eq(fire:slotText(6), "spell:Pyroblast", "Fire G")
  eq(fire:slotText(8), "spell:Frost Nova", "Fire V control")
  eq(fire:slotText(9), "spell:Frostfire Bolt", "Fire 1 Frostfire filler")
  eq(fire:slotText(12), "spell:Flamestrike", "Fire 4")
  eq(fire:slotText(25), "spell:Blizzard", "Fire Ctrl+Q")
  eq(fire:slotText(63), "spell:Combustion", "Fire Shift+R")
  eq(fire:slotText(66), "spell:Cone of Cold", "Fire Shift+G")
  eq(fire:slotText(Pad(1, "RT A")), "spell:Fireball", "Fire controller RT A = Q")
  eq(fire:slotText(Pad(1, "RT B")), "spell:Arcane Missiles", "Fire controller RT B = F")
  eq(fire:slotText(Pad(1, "RT Up")), "spell:Frostfire Bolt", "Fire controller RT Up = 1")
  eq(fire:slotText(Pad(1, "LT X")), "spell:Pyroblast", "Fire controller LT X = G")
  eq(fire.ns.modules.actionbars.Plan().changes, 0, "Fire up to date after Apply")

  local arcane = Boot({ talents = T3(31, 20, 0) },
    { "Arcane Blast", "Arcane Wrath", "Presence of Mind", "Arcane Power", "Pyroblast" })
  arcane:slash("spells apply")
  arcane:slash("controller apply")
  noErrors(arcane)
  eq(arcane:slotText(1), "spell:Arcane Blast", "Arcane Q")
  eq(arcane:slotText(2), "spell:Arcane Missiles", "Arcane E")
  eq(arcane:slotText(3), "spell:Arcane Wrath", "Arcane R")
  eq(arcane:slotText(4), "spell:Scorch", "Arcane T filler")
  eq(arcane:slotText(5), "spell:Fire Blast", "Arcane F")
  eq(arcane:slotText(6), "spell:Pyroblast", "Arcane G")
  eq(arcane:slotText(8), "spell:Frost Nova", "Arcane V control")
  eq(arcane:slotText(9), "spell:Frostbolt", "Arcane 1 pull")
  eq(arcane:slotText(26), "spell:Presence of Mind", "Arcane Ctrl+E cooldown")
  eq(arcane:slotText(63), "spell:Arcane Power", "Arcane Shift+R")
  eq(arcane:slotText(Pad(1, "RT A")), "spell:Arcane Blast", "Arcane controller RT A = Q")
  eq(arcane:slotText(Pad(1, "RT X")), "spell:Arcane Missiles", "Arcane controller RT X = E")
  eq(arcane:slotText(Pad(1, "LT A")), "spell:Scorch", "Arcane controller LT A = T")
  eq(arcane:slotText(Pad(1, "LT+RT Down")), "spell:Presence of Mind", "Arcane controller LT+RT Down = Ctrl+E")
  eq(arcane.ns.modules.actionbars.Plan().changes, 0, "Arcane up to date after Apply")
end)

test("mage: installed macros take their homes", function()
  local env = Boot({ talents = T3(0, 0, 31), macros = { "BlockLance", "BlockBreak", "CounterFocus", "PolyFocus", "ArmorSwap", "ConjureBoth" } },
    { "Ice Lance", "Ice Block" })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(6), "macro:BlockLance", "G")
  eq(env:slotText(68), "macro:BlockBreak", "Shift+V")
  eq(env:slotText(64), "macro:PolyFocus", "Shift+T")
  eq(env:slotText(27), "macro:CounterFocus", "Ctrl+R")
  eq(env:slotText(69), "macro:ArmorSwap", "Shift+1")
  eq(env:slotText(34), "macro:ConjureBoth", "Ctrl+2")
  eq(#env:calls("CreateMacro"), 0)
end)

test("mage: Counter and Decurse take the interrupt and decurse homes in every spec", function()
  for _, t in ipairs({ { T3(0, 0, 31), {} }, { T3(0, 31, 0), { "Pyroblast" } }, { T3(31, 20, 0), { "Arcane Blast" } } }) do
    local env = Boot({ talents = t[1], macros = { "Counter", "Decurse" } }, t[2])
    env:slash("spells apply")
    env:slash("controller apply")
    noErrors(env)
    local key = env.ns.Layout.ActiveSpec("MAGE").key
    eq(env:slotText(11), "macro:Counter", key .. " 3 interrupt")
    eq(env:slotText(32), "macro:Decurse", key .. " Ctrl+V decurse")
    eq(env:slotText(Pad(1, "LT B")), "macro:Counter", key .. " controller LT B")
    eq(env:slotText(Pad(1, "none Left")), "macro:Decurse", key .. " controller none Left")
    eq(#env:calls("CreateMacro"), 0)
  end
end)

test("mage: macros pass the rules", function()
  local env = Boot()
  local count = 0
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "MAGE" then
      count = count + 1
      ok(m.perCharacter and m.untested, m.name .. " perCharacter and untested")
      for _, p in ipairs(H.rules.CheckMacro(m)) do
        ok(p.severity ~= "error" and p.severity ~= "warn", m.name .. ": " .. p.msg)
      end
    end
  end
  eq(count, 9, "mage macros registered")
end)

test("mage: recommended macros name valid spec keys and carry the recommended tag", function()
  local env = Boot()
  local valid = {}
  for _, spec in ipairs(env.ns.Layout.Specs("MAGE")) do valid[spec.key] = true end
  local perSpec = {}
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "MAGE" and m.specs then
      ok(#m.specs > 0, m.name .. " has spec keys")
      for _, k in ipairs(m.specs) do
        ok(valid[k], m.name .. ": '" .. tostring(k) .. "' is a MAGE spec key")
        perSpec[k] = (perSpec[k] or 0) + 1
      end
      local tagged = false
      for _, t in ipairs(m.tags or {}) do if t == "recommended" then tagged = true end end
      ok(tagged, m.name .. " has the recommended tag")
    end
  end
  for k in pairs(valid) do ok((perSpec[k] or 0) >= 2, k .. " has recommended macros") end
end)
