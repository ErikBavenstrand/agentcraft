-- Shaman layouts: Enhancement (the leveling spec) and Elemental share every
-- bar through fallback chains; Restoration swaps Bar 1 for its heals. No
-- stance pages (Ghost Wolf is a plain spell). Apply fills the bars and the
-- controller, the plan agrees afterwards, and nothing creates a macro.
local H = require("harness")

local function T3(ele, enh, resto)
  return { { name = "Elemental", points = ele }, { name = "Enhancement", points = enh }, { name = "Restoration", points = resto } }
end

-- Boots the shaman fixture, learning `learn` (talents the fixture only has in
-- its catalog) and forgetting `forget` (the fixture is an Enhancement shaman).
local function Boot(opts, learn, forget)
  opts = opts or {}
  opts.fixture = "shaman"
  local setup = opts.setup
  opts.setup = function(W)
    local drop = {}
    for _, name in ipairs(forget or {}) do drop[name] = true end
    for i = #W.fixture.spells, 1, -1 do
      if drop[W.fixture.spells[i].name] then table.remove(W.fixture.spells, i) end
    end
    for i, name in ipairs(learn or {}) do
      table.insert(W.fixture.spells, { name = name, id = 990000 + i })
    end
    if setup then setup(W) end
  end
  return H.boot(opts)
end

test("shaman: each spec's keyboard and controller resolve; no stance pages", function()
  local env = Boot()
  local L = env.ns.Layout
  for _, spec in ipairs(L.Specs("SHAMAN")) do
    local kb = L.KeyboardBars("SHAMAN", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    ok(kb.stances == nil or next(kb.stances) == nil, spec.key .. " has no stance pages")
    ok(L.ControllerPages("SHAMAN", spec.key), spec.key .. " controller")
  end
end)

-- The first spell (or macro) of each key, so resolved copies compare by content.
local function Names(bar)
  local out = {}
  for i = 1, 12 do
    local e = bar[i]
    out[i] = type(e) == "table" and (e.macro or e[1] or (e.racial and "<racial>")) or tostring(e)
  end
  return table.concat(out, ",")
end

test("shaman: the leveling spec until talents say otherwise", function()
  eq(Boot({ level = 8, talents = T3(0, 0, 0) }).ns.Layout.ActiveSpec("SHAMAN").key, "enhancement")
  eq(Boot({ talents = T3(31, 5, 15) }).ns.Layout.ActiveSpec("SHAMAN").key, "elemental")
  eq(Boot({ talents = T3(0, 20, 31) }).ns.Layout.ActiveSpec("SHAMAN").key, "restoration")
end)

test("shaman: Elemental shares Enhancement's bars; Restoration swaps Plain, Shift and Ctrl", function()
  local L = Boot().ns.Layout
  local enh, ele, resto = L.KeyboardBars("SHAMAN", "enhancement"), L.KeyboardBars("SHAMAN", "elemental"), L.KeyboardBars("SHAMAN", "restoration")
  for _, bar in ipairs({ 1, 2, 4 }) do
    eq(Names(ele[bar]), Names(enh[bar]), "Elemental bar " .. bar)
    ok(Names(resto[bar]) ~= Names(enh[bar]), "Resto bar " .. bar .. " differs")
  end
  -- key-roles.md: the Shift row F G C V keeps its roles for the healer.
  for i = 5, 12 do eq(Names({ resto[2][i] }), Names({ enh[2][i] }), "Resto Shift key " .. i) end
  eq(enh[1][4][2], "Lightning Mastery", "T chain: Stormstrike, Lightning Mastery, Riptide")
end)

test("shaman: Enhancement Apply follows the key roles; no macro is created", function()
  local env = Boot({ talents = T3(0, 31, 20) })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Lightning Bolt", "Q main attack")
  eq(env:slotText(2), "spell:Flame Shock", "E DoT")
  eq(env:slotText(3), "spell:Chain Lightning", "R big hitter")
  eq(env:slotText(4), "spell:Stormstrike", "T signature")
  eq(env:slotText(5), nil, "F: ShockCycle waits until installed")
  eq(env:slotText(7), "spell:Ghost Wolf", "C mobility")
  eq(env:slotText(8), "spell:Frost Shock", "V snare")
  eq(env:slotText(9), "spell:Searing Totem", "1 opener")
  eq(env:slotText(10), "spell:Fire Nova", "2 main AoE")
  eq(env:slotText(11), "spell:Earth Shock", "3 interrupt")
  eq(env:slotText(12), "spell:Magma Totem", "4 ground AoE")
  eq(env:slotText(61), "spell:Healing Wave", "Shift+Q self-heal")
  eq(env:slotText(63), "spell:Rage of the Farseer", "Shift+R burst")
  eq(env:slotText(65), nil, "Shift+F: no hard CC")
  eq(env:slotText(69), "spell:Lightning Shield", "Shift+1 (no Water Shield)")
  eq(env:slotText(33), "spell:Call of the Elements", "Ctrl+1")
  eq(env:slotText(73), nil, "no stance page")
  eq(env:slotText(env:padSlot(1, "RT A")), "spell:Lightning Bolt", "controller RT A")
  eq(env:slotText(env:padSlot(1, "RT Left")), "spell:Stormstrike", "controller RT Left")
  eq(env:slotText(env:padSlot(1, "LT Y")), "spell:Ghost Wolf", "controller LT Y")
  eq(env:slotText(env:padSlot(1, "LT+RT B")), "spell:Blood Fury", "controller LT+RT B racial")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("shaman: Elemental gets Lightning Mastery on T", function()
  local env = Boot({ talents = T3(31, 0, 20) }, { "Lightning Mastery" }, { "Stormstrike", "Rage of the Farseer" })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(4), "spell:Lightning Mastery", "T")
  eq(env:slotText(3), "spell:Chain Lightning", "R")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("shaman: Restoration follows the healer rule (heals on plain, damage on Shift)", function()
  local env = Boot({ talents = T3(0, 11, 40) }, { "Riptide", "Water Shield", "Mana Tide Totem", "Nature's Swiftness" },
    { "Stormstrike", "Rage of the Farseer" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Healing Wave", "Q main heal")
  eq(env:slotText(2), "spell:Riptide", "E HoT")
  eq(env:slotText(3), "spell:Lesser Healing Wave", "R")
  eq(env:slotText(4), "spell:Mana Tide Totem", "T spec heal")
  eq(env:slotText(9), "spell:Chain Heal", "1 group heal")
  eq(env:slotText(61), "spell:Lightning Bolt", "Shift+Q")
  eq(env:slotText(62), "spell:Flame Shock", "Shift+E")
  eq(env:slotText(68), "spell:Nature's Swiftness", "Shift+V")
  eq(env:slotText(69), "spell:Water Shield", "Shift+1")
  eq(env:slotText(25), "spell:Grounding Totem", "Ctrl+Q")
  eq(env:slotText(env:padSlot(1, "RT A")), "spell:Healing Wave", "controller RT A")
  eq(env:slotText(env:padSlot(1, "RT X")), "spell:Riptide", "controller RT X")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("shaman: an installed macro takes its home", function()
  local env = Boot({ macros = { "ShockKick", "MagmaNova", "ShockCycle" } })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(5), "macro:ShockCycle", "F")
  eq(env:slotText(11), "macro:ShockKick", "3")
  eq(env:slotText(12), "macro:MagmaNova", "4")
end)
