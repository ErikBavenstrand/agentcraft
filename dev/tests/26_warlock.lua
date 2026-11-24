-- Warlock layouts: one shared layout for all three specs (talent chains on
-- T, Ctrl+Q, Shift+E and Shift+R), Apply fills the bars and the controller
-- by the shared key roles (dev/key-roles.md), the plan agrees afterwards,
-- an installed macro takes its home and nothing creates a macro.
local H = require("harness")

local function T3(aff, demo, destro)
  return { { name = "Affliction", points = aff }, { name = "Demonology", points = demo }, { name = "Destruction", points = destro } }
end

-- Boots the warlock fixture with extra learned spells (talents the fixture
-- keeps in its catalog).
local function Boot(opts, learn)
  opts = opts or {}
  opts.fixture = "warlock"
  local setup = opts.setup
  opts.setup = function(W)
    for i, name in ipairs(learn or {}) do
      table.insert(W.fixture.spells, { name = name, id = 990000 + i })
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

test("warlock: each spec's keyboard and controller resolve, all sharing one layout", function()
  local L = Boot().ns.Layout
  local aff = L.KeyboardBars("WARLOCK", "affliction")
  for _, spec in ipairs(L.Specs("WARLOCK")) do
    local kb = L.KeyboardBars("WARLOCK", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    ok(L.ControllerPages("WARLOCK", spec.key), spec.key .. " controller")
    for _, bar in ipairs({ 1, 2, 4 }) do
      for i = 1, 12 do
        local a, b = aff[bar][i], kb[bar][i]
        eq(type(b) == "table" and (b[1] or b.macro) or b, type(a) == "table" and (a[1] or a.macro) or a, spec.key .. " bar " .. bar .. " key " .. i)
      end
    end
    ok(not kb.stances or next(kb.stances) == nil, spec.key .. " has no stance pages")
  end
end)

test("warlock: Affliction is the leveling spec until talents say otherwise", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("WARLOCK").key, "affliction")
  eq(Boot({ talents = T3(5, 31, 0) }).ns.Layout.ActiveSpec("WARLOCK").key, "demonology")
  eq(Boot({ talents = T3(0, 10, 31) }).ns.Layout.ActiveSpec("WARLOCK").key, "destruction")
end)

test("warlock: no talents: the leveling bars by key role, Soul Fire on T and Inferno on Shift+R; no macro is created", function()
  local env = Boot()
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Shadow Bolt", "Q main attack")
  eq(env:slotText(2), "spell:Corruption", "E DoT")
  eq(env:slotText(3), "spell:Immolate", "R big hitter")
  eq(env:slotText(4), "spell:Soul Fire", "T: no 31-point talent yet")
  eq(env:slotText(5), "spell:Drain Life", "F (DrainLife not installed)")
  eq(env:slotText(8), "spell:Life Tap", "V")
  eq(env:slotText(9), "spell:Bane of Agony", "1 opener")
  eq(env:slotText(10), "spell:Hellfire", "2 main AoE")
  eq(env:slotText(12), "spell:Rain of Fire", "4 ground AoE")
  eq(env:slotText(61), "spell:Health Funnel", "Shift+Q")
  eq(env:slotText(62), nil, "Shift+E: no build cooldown without talents")
  eq(env:slotText(63), "spell:Inferno", "Shift+R")
  eq(env:slotText(65), "spell:Fear", "Shift+F hard CC")
  eq(env:slotText(67), "spell:Will of the Forsaken", "Shift+C racial")
  eq(env:slotText(69), "spell:Demon Armor", "Shift+1")
  eq(env:slotText(27), "spell:Searing Pain", "Ctrl+R")
  eq(env:slotText(35), "spell:Summon Sayaad", "Ctrl+3")
  eq(env:slotText(Pad(1, "RT A")), "spell:Shadow Bolt", "controller RT A = Q")
  eq(env:slotText(Pad(1, "RT Right")), "spell:Immolate", "controller RT Right = R")
  eq(env:slotText(Pad(1, "LT A")), "spell:Drain Life", "controller LT A = F")
  eq(env:slotText(Pad(1, "LT B")), "spell:Life Tap", "controller LT B = V")
  eq(env:slotText(Pad(3, "RT B")), "spell:Summon Sayaad", "controller page 3 RT B")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("warlock: Affliction gets Wrack on T, Siphon Life on Ctrl+Q and Amplify Curse on Shift+E", function()
  local env = Boot({ talents = T3(31, 0, 0) }, { "Wrack", "Siphon Life", "Amplify Curse" })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(4), "spell:Wrack", "T")
  eq(env:slotText(25), "spell:Siphon Life", "Ctrl+Q")
  eq(env:slotText(62), "spell:Amplify Curse", "Shift+E")
  eq(env:slotText(63), "spell:Inferno", "Shift+R")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("warlock: Demonology and Destruction get their talents on T, Ctrl+Q, Shift+E and Shift+R", function()
  local demo = Boot({ talents = T3(0, 31, 0) }, { "Fel Domination", "Demonic Sacrifice", "Soul Link" })
  demo:slash("spells apply")
  noErrors(demo)
  eq(demo:slotText(4), "spell:Soul Fire", "Demonology T")
  eq(demo:slotText(25), "spell:Soul Link", "Demonology Ctrl+Q")
  eq(demo:slotText(62), "spell:Fel Domination", "Demonology Shift+E")
  eq(demo:slotText(63), "spell:Demonic Sacrifice", "Demonology Shift+R")

  local destro = Boot({ talents = T3(0, 0, 31) }, { "Incinerate", "Conflagrate", "Shadowburn", "Bane of Havoc" })
  destro:slash("spells apply")
  noErrors(destro)
  eq(destro:slotText(4), "spell:Incinerate", "Destruction T")
  eq(destro:slotText(25), "spell:Conflagrate", "Destruction Ctrl+Q")
  eq(destro:slotText(62), "spell:Bane of Havoc", "Destruction Shift+E")
  eq(destro:slotText(63), "spell:Shadowburn", "Destruction Shift+R")
end)

test("warlock: installed macros take their homes; PetSpecial waits until installed", function()
  local env = Boot({ macros = { "DrainLife", "DrainSoul", "PetSpecial" } })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(5), "macro:DrainLife", "F")
  eq(env:slotText(6), "macro:DrainSoul", "G")
  eq(env:slotText(11), "macro:PetSpecial", "3")
  eq(#env:calls("CreateMacro"), 0)

  local bare = Boot()
  bare:slash("spells apply")
  eq(bare:slotText(11), nil, "3 stays empty without the macro")
end)

test("warlock: macros pass the rules", function()
  local env = Boot()
  local count = 0
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "WARLOCK" then
      count = count + 1
      ok(m.perCharacter and m.untested, m.name .. " perCharacter and untested")
      for _, p in ipairs(H.rules.CheckMacro(m)) do
        ok(p.severity ~= "error" and p.severity ~= "warn", m.name .. ": " .. p.msg)
      end
    end
  end
  ok(count >= 4, "warlock macros registered")
end)
