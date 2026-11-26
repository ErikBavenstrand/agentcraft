-- Shaman layouts (Wowhead WoW Forever guides): Enhancement (the leveling
-- spec) and Elemental share every bar through fallback chains but Plain F
-- and 4 (Magma vs Searing); Restoration swaps Bar 1 for its heals. No
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

test("shaman: Elemental shares Enhancement's bars but F and 4; Restoration swaps Plain, Shift and Ctrl", function()
  local L = Boot().ns.Layout
  local enh, ele, resto = L.KeyboardBars("SHAMAN", "enhancement"), L.KeyboardBars("SHAMAN", "elemental"), L.KeyboardBars("SHAMAN", "restoration")
  for _, bar in ipairs({ 2, 4 }) do eq(Names(ele[bar]), Names(enh[bar]), "Elemental bar " .. bar) end
  for _, bar in ipairs({ 1, 2, 4 }) do ok(Names(resto[bar]) ~= Names(enh[bar]), "Resto bar " .. bar .. " differs") end
  -- Wowhead: Enhancement keeps Magma Totem up (F, Searing before 26),
  -- Elemental keeps Searing up on one target and Magma on packs (4).
  for i = 1, 12 do
    if i ~= 3 and i ~= 5 and i ~= 12 then eq(Names({ ele[1][i] }), Names({ enh[1][i] }), "Elemental plain key " .. i) end
  end
  -- R: the same chain, but Enhancement's Stormstrike takes StormAttack.
  eq(enh[1][3].macro, "StormAttack", "Enhancement R: StormAttack once installed")
  eq(enh[1][3][1], "Stormstrike", "Enhancement R fallback")
  eq(ele[1][3].macro, nil, "Elemental R: plain chain (Chain Lightning builds)")
  eq(ele[1][3][1], "Stormstrike", "Elemental R chain")
  eq(enh[1][5].macro, "MagmaNova", "Enhancement F")
  eq(enh[1][5][2], "Searing Totem", "Enhancement F: Searing until Magma")
  eq(ele[1][5][1], "Searing Totem", "Elemental F")
  eq(ele[1][12].macro, "MagmaNova", "Elemental 4")
  eq(enh[1][12][1], "Stoneclaw Totem", "Enhancement 4")
  -- key-roles.md: mobility (C), snare (V), opener (1) and interrupt (3) stay
  -- on the same keys for the healer; Shift F G C keep their roles.
  for _, i in ipairs({ 7, 8, 9, 11 }) do eq(Names({ resto[1][i] }), Names({ enh[1][i] }), "Resto plain key " .. i) end
  for i = 5, 7 do eq(Names({ resto[2][i] }), Names({ enh[2][i] }), "Resto Shift key " .. i) end
  eq(enh[1][3][2], "Chain Lightning", "R chain: Stormstrike, Chain Lightning")
  eq(enh[2][3][2], "Lightning Mastery", "Shift+R chain: Rage of the Farseer, Lightning Mastery")
  -- Water Shield is a Restoration talent (row 2 = 20): the damage specs fall
  -- back to Lightning Shield.
  eq(enh[1][4][2], "Lightning Shield", "Enhancement T: Lightning Shield without Water Shield")
  eq(ele[1][4][2], "Lightning Shield", "Elemental T: Lightning Shield without Water Shield")
end)

test("shaman: Enhancement Apply puts the rotation on the rotation slots; no macro is created", function()
  local env = Boot({ talents = T3(0, 31, 20) })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Lightning Bolt", "Q slot 1")
  eq(env:slotText(2), "spell:Flame Shock", "E slot 2")
  eq(env:slotText(3), "spell:Stormstrike", "R slot 3")
  eq(env:slotText(4), "spell:Lightning Shield", "T slot 5 (no Water Shield)")
  eq(env:slotText(5), "spell:Magma Totem", "F slot 4: Magma kept up (Wowhead)")
  eq(env:slotText(6), "spell:Purge", "G reactive")
  eq(env:slotText(7), "spell:Ghost Wolf", "C mobility")
  eq(env:slotText(8), "spell:Frost Shock", "V snare")
  eq(env:slotText(9), "spell:Call of the Elements", "1 opener")
  eq(env:slotText(10), "spell:Fire Nova", "2 main AoE")
  eq(env:slotText(11), "spell:Earth Shock", "3 interrupt")
  eq(env:slotText(12), "spell:Stoneclaw Totem", "4 packs")
  eq(env:slotText(61), "spell:Healing Wave", "Shift+Q self-heal")
  eq(env:slotText(63), "spell:Rage of the Farseer", "Shift+R burst")
  eq(env:slotText(65), nil, "Shift+F: no hard CC")
  eq(env:slotText(68), "spell:Lesser Healing Wave", "Shift+V: LHW until Nature's Swiftness")
  eq(env:slotText(72), "spell:Windfury Weapon", "Shift+4")
  eq(env:slotText(36), "spell:Totemic Recall", "Ctrl+4")
  eq(env:slotText(73), nil, "no stance page")
  eq(env:slotText(env:padSlot(1, "RT A")), "spell:Lightning Bolt", "controller RT A")
  eq(env:slotText(env:padSlot(1, "RT Y")), "spell:Stormstrike", "controller RT Y")
  eq(env:slotText(env:padSlot(1, "RT B")), "spell:Magma Totem", "controller RT B")
  eq(env:slotText(env:padSlot(1, "RT Down")), "spell:Stoneclaw Totem", "controller RT Down")
  eq(env:slotText(env:padSlot(1, "LT B")), "spell:Earth Shock", "controller LT B interrupt")
  eq(env:slotText(env:padSlot(1, "RT Left")), "spell:Ghost Wolf", "controller RT Left")
  eq(env:slotText(env:padSlot(1, "LT+RT B")), "spell:Blood Fury", "controller LT+RT B racial")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("shaman: a level 10 Enhancement shaman has its rotation on Q E F and 3", function()
  local env = Boot({ level = 10, talents = T3(0, 0, 0) }, nil,
    { "Stormstrike", "Rage of the Farseer", "Chain Lightning", "Fire Nova", "Ghost Wolf", "Frost Shock",
      "Call of the Elements", "Magma Totem", "Purge" })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Lightning Bolt", "Q")
  eq(env:slotText(2), "spell:Flame Shock", "E")
  eq(env:slotText(5), "spell:Searing Totem", "F")
  eq(env:slotText(11), "spell:Earth Shock", "3")
end)

test("shaman: Elemental gets Chain Lightning on R and Lightning Mastery on Shift+R", function()
  local env = Boot({ talents = T3(31, 0, 20) }, { "Lightning Mastery" }, { "Stormstrike", "Rage of the Farseer" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(3), "spell:Chain Lightning", "R")
  eq(env:slotText(63), "spell:Lightning Mastery", "Shift+R")
  eq(env:slotText(5), "spell:Searing Totem", "F: Searing on one target")
  eq(env:slotText(12), "spell:Magma Totem", "4: Magma on packs")
  eq(env:slotText(env:padSlot(1, "RT B")), "spell:Searing Totem", "controller RT B")
  eq(env:slotText(env:padSlot(1, "RT Down")), "spell:Magma Totem", "controller RT Down")
  eq(env:slotText(env:padSlot(1, "RT Y")), "spell:Chain Lightning", "controller RT Y")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("shaman: Restoration heals from plain keys and RT/LT face buttons", function()
  local env = Boot({ talents = T3(0, 11, 40) }, { "Riptide", "Water Shield", "Mana Tide Totem", "Nature's Swiftness" },
    { "Stormstrike", "Rage of the Farseer" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Healing Wave", "Q main heal")
  eq(env:slotText(2), "spell:Riptide", "E HoT (Wowhead: before Healing Wave and Chain Heal)")
  eq(env:slotText(3), "spell:Chain Heal", "R group heal")
  eq(env:slotText(4), "spell:Cure Poison", "T dispel")
  eq(env:slotText(5), "spell:Lesser Healing Wave", "F fast heal")
  eq(env:slotText(6), "spell:Cure Disease", "G dispel")
  eq(env:slotText(10), "spell:Healing Stream Totem", "2 group heal totem")
  eq(env:slotText(11), "spell:Earth Shock", "3 interrupt")
  eq(env:slotText(61), "spell:Lightning Bolt", "Shift+Q")
  eq(env:slotText(62), "spell:Flame Shock", "Shift+E")
  eq(env:slotText(63), "spell:Mana Tide Totem", "Shift+R")
  eq(env:slotText(68), "spell:Nature's Swiftness", "Shift+V")
  eq(env:slotText(69), "spell:Water Shield", "Shift+1")
  eq(env:slotText(25), "spell:Grounding Totem", "Ctrl+Q")
  eq(env:slotText(26), "spell:Magma Totem", "Ctrl+E: AoE damage if mana allows")
  eq(env:slotText(env:padSlot(1, "RT A")), "spell:Healing Wave", "controller RT A")
  eq(env:slotText(env:padSlot(1, "RT X")), "spell:Riptide", "controller RT X")
  eq(env:slotText(env:padSlot(1, "RT Y")), "spell:Chain Heal", "controller RT Y")
  eq(env:slotText(env:padSlot(1, "RT B")), "spell:Lesser Healing Wave", "controller RT B")
  eq(env:slotText(env:padSlot(1, "LT A")), "spell:Cure Poison", "controller LT A")
  eq(env:slotText(env:padSlot(1, "LT X")), "spell:Cure Disease", "controller LT X")
  eq(env:slotText(env:padSlot(1, "LT B")), "spell:Earth Shock", "controller LT B")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("shaman: an installed macro takes its home", function()
  local env = Boot({ macros = { "ShockKick", "MagmaNova", "WaveHeal" } })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(11), "macro:ShockKick", "3")
  eq(env:slotText(5), "macro:MagmaNova", "F")
  eq(env:slotText(61), "macro:WaveHeal", "Shift+Q")
end)

test("shaman: installed recommended macros take their homes (Enhancement and Restoration)", function()
  local env = Boot({ talents = T3(0, 31, 20), macros = { "StormAttack", "ShamanBurst" } })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(3), "macro:StormAttack", "R")
  eq(env:slotText(63), "macro:ShamanBurst", "Shift+R")
  eq(env:slotText(env:padSlot(1, "RT Y")), "macro:StormAttack", "controller RT Y")
  eq(env.ns.Layout.ControllerPages("SHAMAN", "enhancement")[1]["LT+RT Y"].macro, "ShamanBurst", "controller LT+RT Y")
  env = Boot({ talents = T3(0, 11, 40), macros = { "RiptideHeal", "ChainHeal", "LesserWave", "WaveHeal", "NSWave" } },
    { "Riptide", "Water Shield", "Mana Tide Totem", "Nature's Swiftness" }, { "Stormstrike", "Rage of the Farseer" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "macro:WaveHeal", "Q")
  eq(env:slotText(2), "macro:RiptideHeal", "E")
  eq(env:slotText(3), "macro:ChainHeal", "R")
  eq(env:slotText(5), "macro:LesserWave", "F")
  eq(env:slotText(68), "macro:NSWave", "Shift+V")
  eq(env:slotText(env:padSlot(1, "RT X")), "macro:RiptideHeal", "controller RT X")
  eq(env:slotText(env:padSlot(1, "RT Y")), "macro:ChainHeal", "controller RT Y")
  eq(env:slotText(env:padSlot(1, "RT B")), "macro:LesserWave", "controller RT B")
end)

test("shaman: every shaman macro with specs names real spec keys and is tagged recommended", function()
  local env = Boot()
  local valid = {}
  for _, s in ipairs(env.ns.Layout.Specs("SHAMAN")) do valid[s.key] = true end
  local tagged = {}
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "SHAMAN" and m.specs then
      ok(#m.specs > 0, m.name .. ": specs not empty")
      for _, k in ipairs(m.specs) do ok(valid[k], m.name .. ": unknown spec key " .. tostring(k)) end
      local rec = false
      for _, t in ipairs(m.tags or {}) do if t == "recommended" then rec = true end end
      ok(rec, m.name .. ": tagged recommended")
      for _, k in ipairs(m.specs) do tagged[k] = (tagged[k] or 0) + 1 end
    end
  end
  for k in pairs(valid) do
    ok((tagged[k] or 0) >= 2 and tagged[k] <= 6, k .. ": 2-6 recommended macros, got " .. tostring(tagged[k]))
  end
end)
