-- Paladin layouts: every spec resolves, Retribution levels, Apply fills the
-- bars and the controller (no stance pages) by the shared key roles
-- (dev/key-roles.md), Holy's heals swap onto the plain keys, the plan
-- agrees afterwards, and nothing creates a macro.
local H = require("harness")

local function Boot(opts)
  opts = opts or {}
  opts.fixture = "paladin"
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

test("paladin: Apply fills the Retribution bars by key role and the controller; no macro is created", function()
  local env = Boot({ talents = Talents(0, 5, 31) })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Holy Strike", "Q main attack")
  eq(env:slotText(2), "spell:Judgement", "E maintained debuff")
  eq(env:slotText(3), "spell:Exorcism", "R big hitter without the ExoJudge macro")
  eq(env:slotText(5), "spell:Seal of Command", "F: Seal of Command replaces Righteousness")
  eq(env:slotText(6), "spell:Hammer of Wrath", "G proc without the HammerJudge macro")
  eq(env:slotText(8), "spell:Seal of Justice", "V")
  eq(env:slotText(9), "spell:Seal of the Crusader", "1 opener")
  eq(env:slotText(12), "spell:Consecration", "4 ground AoE")
  eq(env:slotText(61), "spell:Flash of Light", "Shift+Q self-heal without the SmartFlash macro")
  eq(env:slotText(62), "spell:Lay on Hands", "Shift+E")
  eq(env:slotText(64), "spell:Cleanse", "Shift+T: Cleanse replaces Purify")
  eq(env:slotText(65), "spell:Hammer of Justice", "Shift+F hard CC")
  eq(env:slotText(68), "spell:Divine Shield", "Shift+V: Divine Shield replaces Divine Protection")
  eq(env:slotText(70), "spell:Seal of Fury", "Shift+2")
  eq(env:slotText(25), nil, "Ctrl+Q free")
  eq(env:slotText(29), "spell:Redemption", "Ctrl+F")
  eq(env:slotText(33), "spell:Devotion Aura", "Ctrl+1")
  for slot = 73, 84 do eq(env:slotText(slot), nil, "no stance page (slot " .. slot .. ")") end
  eq(env:slotText(Pad(1, 2, 8)), "spell:Holy Strike", "controller RT A = Q")
  eq(env:slotText(Pad(1, 2, 5)), "spell:Judgement", "controller RT X = E")
  eq(env:slotText(Pad(1, 1, 8)), "spell:Seal of Command", "controller LT A = F")
  eq(env:slotText(Pad(1, 1, 4)), "spell:Hammer of Justice", "controller LT Down = Shift+F")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("paladin: Holy puts its heals on the plain keys and its damage on Shift", function()
  local env = Boot({ talents = Talents(31, 0, 5) })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Flash of Light", "Q main heal")
  eq(env:slotText(2), "spell:Cleanse", "E")
  eq(env:slotText(3), "spell:Holy Light", "R big heal")
  eq(env:slotText(9), "spell:Seal of Wisdom", "1")
  eq(env:slotText(5), "spell:Seal of Command", "F as shared")
  eq(env:slotText(61), "spell:Holy Strike", "Shift+Q")
  eq(env:slotText(62), "spell:Judgement", "Shift+E")
  eq(env:slotText(64), "spell:Lay on Hands", "Shift+T")
  eq(env:slotText(71), "spell:Seal of the Crusader", "Shift+3")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("paladin: installed macros take their homes", function()
  local env = Boot({ macros = { "SmartFlash", "ExoJudge" } })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(61), "macro:SmartFlash", "Shift+Q")
  eq(env:slotText(3), "macro:ExoJudge", "R")
  eq(env:slotText(1), "spell:Holy Strike", "Q keeps Holy Strike")
end)
