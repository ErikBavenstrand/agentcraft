-- Paladin layouts: every spec resolves, Retribution levels, Apply fills the
-- bars and the controller (no stance pages) by the rotation slots
-- (dev/key-roles.md), Protection and Holy get their own rotations on the
-- plain keys and the RT/LT face buttons, the plan agrees afterwards, and
-- nothing creates a macro. Rotations: the Wowhead Forever guides (Layouts/Paladin.lua).
local H = require("harness")

-- Boots the paladin fixture, learning `learn` (talents the fixture keeps in
-- its catalog).
local function Boot(opts, learn)
  opts = opts or {}
  opts.fixture = "paladin"
  local setup = opts.setup
  opts.setup = function(W)
    for i, name in ipairs(learn or {}) do
      table.insert(W.fixture.spells, { name = name, id = 995000 + i })
    end
    if setup then setup(W) end
  end
  return H.boot(opts)
end

local function Talents(holy, prot, ret)
  return { { name = "Holy", points = holy }, { name = "Protection", points = prot }, { name = "Retribution", points = ret } }
end

-- Controller slot for page `set`, layer 0-3 (none LT RT LT+RT), button 1-8
-- (Left Up Right Down X Y B A).
local function Pad(set, layer, button)
  local n = layer * 8 + button
  return 180 + (set - 1) * 28 + (n < 5 and n or n - 4)
end

test("paladin: each spec's keyboard and controller resolve", function()
  local env = Boot()
  local L = env.ns.Layout
  for _, spec in ipairs(L.Specs("PALADIN")) do
    local kb = L.KeyboardBars("PALADIN", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    ok(L.ControllerPages("PALADIN", spec.key), spec.key .. " controller")
  end
end)

test("paladin: Retribution levels until talents say otherwise", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("PALADIN").key, "ret")
  eq(Boot({ talents = Talents(31, 5, 0) }).ns.Layout.ActiveSpec("PALADIN").key, "holy")
  eq(Boot({ talents = Talents(0, 31, 5) }).ns.Layout.ActiveSpec("PALADIN").key, "prot")
end)

test("paladin: Apply fills the Retribution rotation slots and the controller; no macro is created", function()
  local env = Boot({ talents = Talents(0, 5, 31) }, { "Repentance", "Seal of Command" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Holy Strike", "Q slot 1")
  eq(env:slotText(2), "spell:Judgement", "E slot 2")
  eq(env:slotText(3), "spell:Seal of Righteousness", "R slot 3: the seal")
  eq(env:slotText(4), "spell:Seal of Command", "T slot 5: Seal of Command without Holy Shock")
  eq(env:slotText(5), "spell:Exorcism", "F slot 4 without the ExoJudge macro")
  eq(env:slotText(6), "spell:Hammer of Wrath", "G reactive without the HammerJudge macro")
  eq(env:slotText(8), "spell:Seal of Justice", "V")
  eq(env:slotText(9), "spell:Seal of the Crusader", "1 opener")
  eq(env:slotText(10), "spell:Consecration", "2 main AoE")
  eq(env:slotText(11), "spell:Hammer of Justice", "3 interrupt")
  eq(env:slotText(12), "spell:Holy Wrath", "4 secondary AoE")
  eq(env:slotText(61), "spell:Flash of Light", "Shift+Q self-heal without the SmartFlash macro")
  eq(env:slotText(62), "spell:Divine Shield", "Shift+E: Divine Shield replaces Divine Protection")
  eq(env:slotText(64), "spell:Cleanse", "Shift+T: Cleanse replaces Purify")
  eq(env:slotText(65), "spell:Repentance", "Shift+F hard CC without the Repent macro")
  eq(env:slotText(68), "spell:Lay on Hands", "Shift+V emergency")
  eq(env:slotText(63), nil, "Shift+R: Divine Favor, not learned")
  eq(env:slotText(71), "spell:Seal of Fury", "Shift+3")
  eq(env:slotText(72), "spell:Holy Light", "Shift+4 without the SmartLight macro")
  eq(env:slotText(25), "spell:Turn Undead", "Ctrl+Q")
  eq(env:slotText(29), "spell:Redemption", "Ctrl+F")
  eq(env:slotText(33), "spell:Devotion Aura", "Ctrl+1")
  for slot = 73, 84 do eq(env:slotText(slot), nil, "no stance page (slot " .. slot .. ")") end
  eq(env:slotText(Pad(1, 2, 8)), "spell:Holy Strike", "controller RT A = Q")
  eq(env:slotText(Pad(1, 2, 5)), "spell:Judgement", "controller RT X = E")
  eq(env:slotText(Pad(1, 2, 6)), "spell:Seal of Righteousness", "controller RT Y = R")
  eq(env:slotText(Pad(1, 2, 7)), "spell:Exorcism", "controller RT B = F")
  eq(env:slotText(Pad(1, 1, 8)), "spell:Seal of Command", "controller LT A = T")
  eq(env:slotText(Pad(1, 1, 7)), "spell:Hammer of Justice", "controller LT B = 3 interrupt")
  eq(env:slotText(Pad(1, 1, 6)), "spell:Consecration", "controller LT Y = 2 AoE")
  eq(env:slotText(Pad(1, 1, 4)), "spell:Repentance", "controller LT Down = Shift+F")
  eq(env:slotText(Pad(1, 3, 3)), "spell:Holy Light", "controller LT+RT Right = Shift+4")
  eq(env:slotText(Pad(1, 0, 4)), "spell:Seal of Wisdom", "controller none Down")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("paladin: a Shockadin Retribution gets Holy Shock on T and Divine Favor on Shift+R", function()
  local env = Boot({ talents = Talents(21, 0, 30) }, { "Holy Shock", "Divine Favor" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(3), "spell:Seal of Righteousness", "R: the only seal")
  eq(env:slotText(4), "spell:Holy Shock", "T")
  eq(env:slotText(63), "spell:Divine Favor", "Shift+R")
  eq(env:slotText(Pad(1, 1, 8)), "spell:Holy Shock", "controller LT A")
  eq(env:slotText(Pad(1, 3, 6)), "spell:Divine Favor", "controller LT+RT Y")
end)

test("paladin: a level 10 Retribution paladin has its rotation on Q E R", function()
  local env = Boot({ level = 10 })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Holy Strike", "Q")
  eq(env:slotText(2), "spell:Judgement", "E")
  eq(env:slotText(3), "spell:Seal of Righteousness", "R")
end)

test("paladin: Protection tanks from the plain keys and the face buttons", function()
  local env = Boot({ talents = Talents(0, 31, 5) }, { "Holy Shield", "Swift Judgement", "Templar's Bulwark" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Holy Strike", "Q")
  eq(env:slotText(2), "spell:Judgement", "E: threat and taunt")
  eq(env:slotText(3), "spell:Holy Shield", "R")
  eq(env:slotText(4), "spell:Seal of Fury", "T: the tank seal")
  eq(env:slotText(5), "spell:Exorcism", "F")
  eq(env:slotText(6), "spell:Hammer of Wrath", "G: execute")
  eq(env:slotText(10), "spell:Consecration", "2 AoE threat")
  eq(env:slotText(12), "spell:Holy Wrath", "4")
  eq(env:slotText(62), "spell:Templar's Bulwark", "Shift+E the only defensive cooldown")
  eq(env:slotText(63), "spell:Swift Judgement", "Shift+R threat cooldown, backup taunt")
  eq(env:slotText(65), "spell:Divine Shield", "Shift+F")
  eq(env:slotText(69), "spell:Righteous Fury", "Shift+1")
  eq(env:slotText(Pad(1, 2, 6)), "spell:Holy Shield", "controller RT Y")
  eq(env:slotText(Pad(1, 1, 8)), "spell:Seal of Fury", "controller LT A")
  eq(env:slotText(Pad(1, 1, 5)), "spell:Hammer of Wrath", "controller LT X")
  eq(env:slotText(Pad(1, 1, 6)), "spell:Consecration", "controller LT Y")
  eq(env:slotText(Pad(1, 1, 3)), "spell:Templar's Bulwark", "controller LT Right")
  eq(env:slotText(Pad(1, 3, 6)), "spell:Swift Judgement", "controller LT+RT Y")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("paladin: a Holy Shock Protection paladin gets Holy Shock on R", function()
  local env = Boot({ talents = Talents(21, 30, 0) }, { "Holy Shock" })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(3), "spell:Holy Shock", "R")
end)

test("paladin: Holy heals from the plain keys and the face buttons, damage on Shift", function()
  local env = Boot({ talents = Talents(31, 0, 5) }, { "Holy Shock", "Light's Vigil", "Divine Favor", "Oath of Light" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Flash of Light", "Q main heal")
  eq(env:slotText(2), "spell:Judgement", "E: judge Seal of Light")
  eq(env:slotText(3), "spell:Holy Light", "R big heal")
  eq(env:slotText(4), "spell:Cleanse", "T dispel")
  eq(env:slotText(5), "spell:Holy Shock", "F instant heal")
  eq(env:slotText(6), "spell:Divine Favor", "G")
  eq(env:slotText(9), "spell:Seal of Light", "1: Wowhead's healer seal")
  eq(env:slotText(10), "spell:Light's Vigil", "2 group heal")
  eq(env:slotText(12), "spell:Voice of Truth", "4: trainer spell (20)")
  eq(env:slotText(71), "spell:Oath of Light", "Shift+3: the 1-hour Oath (talent, row 3)")
  eq(env:slotText(64), "spell:Seal of Righteousness", "Shift+T solo seal")
  eq(env:slotText(69), "spell:Seal of Wisdom", "Shift+1")
  eq(env:slotText(61), "spell:Holy Strike", "Shift+Q")
  eq(env:slotText(63), "spell:Exorcism", "Shift+R")
  eq(env:slotText(66), "spell:Consecration", "Shift+G")
  eq(env:slotText(Pad(1, 2, 8)), "spell:Flash of Light", "controller RT A")
  eq(env:slotText(Pad(1, 2, 5)), "spell:Judgement", "controller RT X")
  eq(env:slotText(Pad(1, 2, 6)), "spell:Holy Light", "controller RT Y")
  eq(env:slotText(Pad(1, 2, 7)), "spell:Holy Shock", "controller RT B")
  eq(env:slotText(Pad(1, 1, 8)), "spell:Cleanse", "controller LT A dispel")
  eq(env:slotText(Pad(1, 1, 6)), "spell:Light's Vigil", "controller LT Y group heal")
  eq(env:slotText(Pad(1, 2, 4)), "spell:Voice of Truth", "controller RT Down")
  eq(env:slotText(Pad(1, 0, 3)), "spell:Oath of Light", "controller none Right")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("paladin: installed macros take their homes", function()
  local env = Boot({ macros = { "SmartFlash", "ExoJudge" } })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(61), "macro:SmartFlash", "Shift+Q")
  eq(env:slotText(5), "macro:ExoJudge", "F")
  eq(env:slotText(1), "spell:Holy Strike", "Q keeps Holy Strike")
end)

test("paladin: installed recommended macros take their homes in every spec", function()
  local ret = Boot({ talents = Talents(21, 0, 30), macros = { "HolyStrike", "ShockAny", "HoJ", "LayOnHands" } }, { "Holy Shock" })
  ret:slash("spells apply")
  ret:slash("controller apply")
  noErrors(ret)
  eq(ret:slotText(1), "macro:HolyStrike", "ret Q")
  eq(ret:slotText(4), "macro:ShockAny", "ret T (Shockadin)")
  eq(ret:slotText(11), "macro:HoJ", "ret 3")
  eq(ret:slotText(68), "macro:LayOnHands", "ret Shift+V")
  eq(ret:slotText(Pad(1, 2, 8)), "macro:HolyStrike", "ret RT A")
  eq(ret:slotText(Pad(1, 1, 8)), "macro:ShockAny", "ret LT A")
  eq(ret:slotText(Pad(1, 1, 7)), "macro:HoJ", "ret LT B")
  eq(ret:slotText(Pad(1, 3, 8)), "macro:LayOnHands", "ret LT+RT A")
  eq(#ret:calls("CreateMacro"), 0)
  -- Without Holy Shock, Seal of Command keeps T even with ShockAny installed.
  local sc = Boot({ talents = Talents(0, 5, 31), macros = { "ShockAny" } }, { "Seal of Command" })
  sc:slash("spells apply")
  eq(sc:slotText(4), "spell:Seal of Command", "T without Holy Shock")
  local prot = Boot({ talents = Talents(0, 31, 5), macros = { "HolyStrike", "HoJ", "LayOnHands" } }, { "Holy Shield" })
  prot:slash("spells apply")
  prot:slash("controller apply")
  eq(prot:slotText(1), "macro:HolyStrike", "prot Q")
  eq(prot:slotText(11), "macro:HoJ", "prot 3")
  eq(prot:slotText(68), "macro:LayOnHands", "prot Shift+V")
  eq(prot:slotText(Pad(1, 2, 8)), "macro:HolyStrike", "prot RT A")
  local holy = Boot({ talents = Talents(31, 0, 5), macros = { "HoJ", "LayOnHands", "HolyStrike" } }, { "Holy Shock" })
  holy:slash("spells apply")
  holy:slash("controller apply")
  eq(holy:slotText(11), "macro:HoJ", "holy 3")
  eq(holy:slotText(68), "macro:LayOnHands", "holy Shift+V")
  eq(holy:slotText(61), "spell:Holy Strike", "holy Shift+Q keeps the plain Holy Strike")
  eq(holy:slotText(Pad(1, 1, 7)), "macro:HoJ", "holy LT B")
end)

test("paladin: recommended macros name real spec keys, and every spec has some", function()
  local env = Boot()
  local keys, per = {}, {}
  for _, spec in ipairs(env.ns.Layout.Specs("PALADIN")) do keys[spec.key] = true; per[spec.key] = 0 end
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "PALADIN" and m.specs then
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
