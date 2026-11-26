-- Warlock layouts (Wowhead WoW Forever guides): Affliction and Demonology
-- share one layout (talent chains on T, F and Shift+E), Destruction has its own Bar 1, Bar 2, Bar 4
-- and controller page 1; Apply fills the bars and the controller by the
-- rotation slots (dev/key-roles.md), the plan agrees afterwards, an
-- installed macro takes its home and nothing creates a macro.
local H = require("harness")

local function T3(aff, demo, destro)
  return { { name = "Affliction", points = aff }, { name = "Demonology", points = demo }, { name = "Destruction", points = destro } }
end

-- Boots the warlock fixture with extra learned spells (talents the fixture
-- keeps in its catalog) and without some it knows (a lower level).
local function Boot(opts, learn, forget)
  opts = opts or {}
  opts.fixture = "warlock"
  local setup = opts.setup
  opts.setup = function(W)
    for i, name in ipairs(learn or {}) do
      table.insert(W.fixture.spells, { name = name, id = 990000 + i })
    end
    if forget then
      local drop = {}
      for _, name in ipairs(forget) do drop[name] = true end
      for i = #W.fixture.spells, 1, -1 do
        if drop[W.fixture.spells[i].name] then table.remove(W.fixture.spells, i) end
      end
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

local function Name(e)
  return type(e) == "table" and (e.macro or e[1]) or e
end

test("warlock: each spec resolves; Affliction and Demonology share, Destruction has its own bars", function()
  local L = Boot().ns.Layout
  local aff = L.KeyboardBars("WARLOCK", "affliction")
  for _, spec in ipairs(L.Specs("WARLOCK")) do
    local kb = L.KeyboardBars("WARLOCK", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    ok(L.ControllerPages("WARLOCK", spec.key), spec.key .. " controller")
    ok(not kb.stances or next(kb.stances) == nil, spec.key .. " has no stance pages")
  end
  local demo = L.KeyboardBars("WARLOCK", "demonology")
  for _, bar in ipairs({ 1, 2, 4 }) do
    for i = 1, 12 do
      eq(Name(demo[bar][i]), Name(aff[bar][i]), "demonology bar " .. bar .. " key " .. i)
    end
  end
  local destro = L.KeyboardBars("WARLOCK", "destruction")
  eq(Name(destro[1][1]), "Incinerate", "destruction Q")
  eq(Name(destro[2][1]), "DrainLife", "destruction Shift+Q")
end)

test("warlock: Affliction is the leveling spec until talents say otherwise", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("WARLOCK").key, "affliction")
  eq(Boot({ talents = T3(5, 31, 0) }).ns.Layout.ActiveSpec("WARLOCK").key, "demonology")
  eq(Boot({ talents = T3(0, 10, 31) }).ns.Layout.ActiveSpec("WARLOCK").key, "destruction")
end)

test("warlock: no talents: Wowhead's rotation on the plain keys and RT/LT face; no macro is created", function()
  local env = Boot()
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Drain Life", "Q slot 1 filler (DrainLife not installed)")
  eq(env:slotText(2), "spell:Corruption", "E slot 2")
  eq(env:slotText(3), "spell:Bane of Agony", "R slot 3")
  eq(env:slotText(4), "spell:Searing Pain", "T slot 5: no Siphon Life yet")
  eq(env:slotText(5), "spell:Immolate", "F slot 4: Immolate until Wrack")
  eq(env:slotText(6), "spell:Life Tap", "G reactive")
  eq(env:slotText(7), "spell:Death Coil", "C escape")
  eq(env:slotText(8), "spell:Shoot", "V wand finisher")
  eq(env:slotText(9), "spell:Shadow Bolt", "1 opener")
  eq(env:slotText(10), "spell:Hellfire", "2 main AoE")
  eq(env:slotText(11), nil, "3 PetSpecial waits until installed")
  eq(env:slotText(12), "spell:Rain of Fire", "4 ground AoE")
  eq(env:slotText(61), "spell:Health Funnel", "Shift+Q")
  eq(env:slotText(62), nil, "Shift+E: no spec cooldown without talents")
  eq(env:slotText(63), "spell:Soul Fire", "Shift+R")
  eq(env:slotText(64), "spell:Drain Soul", "Shift+T shards")
  eq(env:slotText(65), "spell:Fear", "Shift+F hard CC")
  eq(env:slotText(67), "spell:Will of the Forsaken", "Shift+C racial")
  eq(env:slotText(69), "spell:Demon Armor", "Shift+1")
  eq(env:slotText(25), "spell:Curse of the Elements", "Ctrl+Q")
  eq(env:slotText(26), "spell:Curse of Recklessness", "Ctrl+E")
  eq(env:slotText(29), "spell:Create Spellstone", "Ctrl+F")
  eq(env:slotText(35), "spell:Summon Succubus", "Ctrl+3")
  eq(env:slotText(Pad(1, "RT A")), "spell:Drain Life", "controller RT A = Q")
  eq(env:slotText(Pad(1, "RT X")), "spell:Corruption", "controller RT X = E")
  eq(env:slotText(Pad(1, "RT Y")), "spell:Bane of Agony", "controller RT Y = R")
  eq(env:slotText(Pad(1, "RT B")), "spell:Immolate", "controller RT B = F")
  eq(env:slotText(Pad(1, "LT X")), "spell:Life Tap", "controller LT X = G")
  eq(env:slotText(Pad(1, "LT Y")), "spell:Hellfire", "controller LT Y = 2")
  eq(env:slotText(Pad(1, "RT Up")), "spell:Shadow Bolt", "controller RT Up = 1")
  eq(env:slotText(Pad(1, "RT Right")), "spell:Shoot", "controller RT Right = V")
  eq(env:slotText(Pad(1, "LT Left")), "spell:Drain Soul", "controller LT Left = Shift+T")
  eq(env:slotText(Pad(2, "RT Left")), "spell:Create Spellstone", "controller page 2 RT Left")
  eq(env:slotText(Pad(3, "RT B")), "spell:Summon Succubus", "controller page 3 RT B")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("warlock: before Drain Life (14), Q waits; Shadow Bolt stays on 1 and RT Up", function()
  local env = Boot({ level = 12 }, nil, { "Drain Life" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), nil, "Q")
  eq(env:slotText(9), "spell:Shadow Bolt", "1")
  eq(env:slotText(Pad(1, "RT A")), nil, "RT A")
  eq(env:slotText(Pad(1, "RT Up")), "spell:Shadow Bolt", "RT Up")
end)

test("warlock: Affliction talents: Siphon Life on T, Wrack on F, Amplify Curse on Shift+E", function()
  local env = Boot({ talents = T3(31, 0, 0) }, { "Wrack", "Siphon Life", "Amplify Curse", "Demonic Sacrifice" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(4), "spell:Siphon Life", "T")
  eq(env:slotText(5), "spell:Wrack", "F (Wrack macro not installed)")
  eq(env:slotText(9), "spell:Shadow Bolt", "1: Shadow Trance procs")
  eq(env:slotText(62), "spell:Amplify Curse", "Shift+E")
  eq(env:slotText(32), "spell:Demonic Sacrifice", "Ctrl+V")
  eq(env:slotText(Pad(1, "LT A")), "spell:Siphon Life", "controller LT A = T")
  eq(env:slotText(Pad(1, "RT B")), "spell:Wrack", "controller RT B = F")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("warlock: Demonology gets Searing Pain (Demonic Brand) on T, Immolate on F and its talents", function()
  local demo = Boot({ talents = T3(0, 31, 0) }, { "Fel Domination", "Demonic Sacrifice", "Soul Link" })
  demo:slash("spells apply")
  noErrors(demo)
  eq(demo:slotText(4), "spell:Searing Pain", "T")
  eq(demo:slotText(5), "spell:Immolate", "F")
  eq(demo:slotText(62), "spell:Fel Domination", "Shift+E")
  eq(demo:slotText(63), "spell:Soul Fire", "Shift+R")
  eq(demo:slotText(31), "spell:Soul Link", "Ctrl+C")
  eq(demo:slotText(32), "spell:Demonic Sacrifice", "Ctrl+V")
end)

test("warlock: Destruction: Incinerate, Immolate, Conflagrate, Corruption, Shadowburn on Q E R F T; Drain Life on Shift+Q", function()
  local destro = Boot({ talents = T3(0, 0, 31) }, { "Incinerate", "Conflagrate", "Shadowburn", "Bane of Havoc", "Amplify Curse" })
  destro:slash("spells apply")
  destro:slash("controller apply")
  noErrors(destro)
  eq(destro:slotText(1), "spell:Incinerate", "Q")
  eq(destro:slotText(2), "spell:Immolate", "E")
  eq(destro:slotText(3), "spell:Conflagrate", "R")
  eq(destro:slotText(4), "spell:Shadowburn", "T")
  eq(destro:slotText(5), "spell:Corruption", "F")
  eq(destro:slotText(8), "spell:Shoot", "V")
  eq(destro:slotText(9), "spell:Bane of Agony", "1")
  eq(destro:slotText(12), "spell:Bane of Havoc", "4")
  eq(destro:slotText(61), "spell:Drain Life", "Shift+Q self-heal")
  eq(destro:slotText(62), "spell:Amplify Curse", "Shift+E")
  eq(destro:slotText(64), "spell:Drain Soul", "Shift+T")
  eq(destro:slotText(31), "spell:Health Funnel", "Ctrl+C")
  eq(destro:slotText(32), "spell:Rain of Fire", "Ctrl+V")
  eq(destro:slotText(Pad(1, "RT A")), "spell:Incinerate", "controller RT A")
  eq(destro:slotText(Pad(1, "RT Y")), "spell:Conflagrate", "controller RT Y")
  eq(destro:slotText(Pad(1, "RT B")), "spell:Corruption", "controller RT B")
  eq(destro:slotText(Pad(1, "LT A")), "spell:Shadowburn", "controller LT A")
  eq(destro:slotText(Pad(1, "LT Up")), "spell:Drain Life", "controller LT Up")
  eq(destro:slotText(Pad(1, "RT Down")), "spell:Bane of Havoc", "controller RT Down")
  eq(destro.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")

  local low = Boot({ level = 20, talents = T3(0, 0, 11) })
  low:slash("spells apply")
  noErrors(low)
  eq(low:slotText(1), "spell:Shadow Bolt", "Q before Incinerate")
  eq(low:slotText(3), nil, "R waits for Conflagrate (row 3 = 25)")
  eq(low:slotText(5), "spell:Corruption", "F")
end)

test("warlock: installed macros take their homes; PetSpecial waits until installed", function()
  local env = Boot({ macros = { "DrainLife", "DrainSoul", "PetSpecial" } })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "macro:DrainLife", "Q")
  eq(env:slotText(64), "macro:DrainSoul", "Shift+T")
  eq(env:slotText(11), "macro:PetSpecial", "3")
  eq(#env:calls("CreateMacro"), 0)
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

test("warlock: recommended macros name valid spec keys and carry the recommended tag", function()
  local env = Boot()
  local valid = {}
  for _, spec in ipairs(env.ns.Layout.Specs("WARLOCK")) do valid[spec.key] = true end
  local perSpec = {}
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "WARLOCK" and m.specs then
      ok(#m.specs > 0, m.name .. " has spec keys")
      for _, k in ipairs(m.specs) do
        ok(valid[k], m.name .. ": '" .. tostring(k) .. "' is a WARLOCK spec key")
        perSpec[k] = (perSpec[k] or 0) + 1
      end
      local tagged = false
      for _, t in ipairs(m.tags or {}) do if t == "recommended" then tagged = true end end
      ok(tagged, m.name .. " has the recommended tag")
    end
  end
  for k in pairs(valid) do ok((perSpec[k] or 0) >= 2, k .. " has recommended macros") end
end)
