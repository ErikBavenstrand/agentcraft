-- Mage layouts: Frost shared, Fire and Arcane with their own Bar 1 and
-- controller page 1 (Fire also its own Ctrl bar), all on the key roles of
-- dev/key-roles.md. Apply fills the bars and the controller, talents take
-- their keys, the plan agrees afterwards, an installed macro takes its home
-- and nothing creates a macro.
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

test("mage: no talents: the Frost bars and controller follow the key roles; no macro is created", function()
  local env = Boot()
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Fire Blast", "Q instant attack")
  eq(env:slotText(2), "spell:Scorch", "E debuff")
  eq(env:slotText(3), "spell:Frostbolt", "R cast nuke")
  eq(env:slotText(4), "spell:Arcane Missiles", "T")
  eq(env:slotText(5), "spell:Fireball", "F")
  eq(env:slotText(6), nil, "G: no Ice Lance yet")
  eq(env:slotText(7), "spell:Blink", "C escape")
  eq(env:slotText(8), "spell:Cone of Cold", "V snare")
  eq(env:slotText(10), "spell:Arcane Explosion", "2 main AoE")
  eq(env:slotText(11), "spell:Counterspell", "3 interrupt")
  eq(env:slotText(12), "spell:Blizzard", "4 ground AoE")
  eq(env:slotText(61), "spell:Evocation", "Shift+Q sustain")
  eq(env:slotText(62), "spell:Mana Shield", "Shift+E: no Ice Barrier yet")
  eq(env:slotText(64), nil, "Shift+T waits for PolyFocus")
  eq(env:slotText(65), "spell:Polymorph", "Shift+F hard CC")
  eq(env:slotText(66), "spell:Frost Nova", "Shift+G AoE control")
  eq(env:slotText(67), "spell:Perception", "Shift+C racial")
  eq(env:slotText(69), "spell:Ice Armor", "Shift+1 (ArmorSwap not installed)")
  eq(env:slotText(25), "spell:Flamestrike", "Ctrl+Q")
  eq(env:slotText(33), "spell:Arcane Brilliance", "Ctrl+1")
  eq(env:slotText(Pad(1, "RT A")), "spell:Fire Blast", "controller RT A = Q")
  eq(env:slotText(Pad(1, "RT B")), "spell:Counterspell", "controller RT B = 3")
  eq(env:slotText(Pad(1, "RT Right")), "spell:Frostbolt", "controller RT Right = R")
  eq(env:slotText(Pad(1, "LT Y")), "spell:Blink", "controller LT Y = C")
  eq(env:slotText(Pad(1, "LT+RT X")), "spell:Frost Nova", "controller LT+RT X = Shift+G")
  eq(env:slotText(Pad(2, "RT A")), "spell:Ice Armor", "controller page 2 RT A")
  eq(env:slotText(Pad(2, "RT Left")), "spell:Teleport: Stormwind", "controller page 2 RT Left (Alliance)")
  eq(env:slotText(Pad(3, "RT A")), "spell:Slow Fall", "controller page 3 RT A")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("mage: Frost talents take G, Shift+E, Shift+R and Shift+V", function()
  local env = Boot({ talents = T3(10, 0, 41) }, { "Ice Lance", "Ice Barrier", "Ice Block", "Cold Snap" })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(6), "spell:Ice Lance", "G proc")
  eq(env:slotText(62), "spell:Ice Barrier", "Shift+E")
  eq(env:slotText(63), "spell:Cold Snap", "Shift+R")
  eq(env:slotText(68), "spell:Ice Block", "Shift+V emergency")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("mage: Fire and Arcane fill the same roles with their own spells", function()
  local fire = Boot({ talents = T3(0, 31, 0) }, { "Pyroblast", "Combustion", "Blast Wave" })
  fire:slash("spells apply")
  fire:slash("controller apply")
  noErrors(fire)
  eq(fire:slotText(2), "spell:Scorch", "Fire E")
  eq(fire:slotText(3), "spell:Fireball", "Fire R")
  eq(fire:slotText(4), "spell:Blast Wave", "Fire T")
  eq(fire:slotText(6), "spell:Pyroblast", "Fire G")
  eq(fire:slotText(9), "spell:Frostfire Bolt", "Fire 1 opener")
  eq(fire:slotText(12), "spell:Flamestrike", "Fire 4")
  eq(fire:slotText(25), "spell:Blizzard", "Fire Ctrl+Q")
  eq(fire:slotText(63), "spell:Combustion", "Fire Shift+R")
  eq(fire:slotText(Pad(1, "RT Up")), "spell:Frostfire Bolt", "Fire controller RT Up = 1")
  eq(fire.ns.modules.actionbars.Plan().changes, 0, "Fire up to date after Apply")

  local arcane = Boot({ talents = T3(31, 0, 0) }, { "Arcane Blast", "Arcane Wrath", "Presence of Mind", "Arcane Power" })
  arcane:slash("spells apply")
  noErrors(arcane)
  eq(arcane:slotText(2), "spell:Arcane Wrath", "Arcane E")
  eq(arcane:slotText(3), "spell:Arcane Blast", "Arcane R")
  eq(arcane:slotText(4), "spell:Presence of Mind", "Arcane T")
  eq(arcane:slotText(6), "spell:Arcane Missiles", "Arcane G")
  eq(arcane:slotText(63), "spell:Arcane Power", "Arcane Shift+R")
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
  eq(count, 6, "mage macros registered")
end)
