-- Priest layouts (roles: dev/key-roles.md). Shadow levels on the shared
-- layout with the Shadowform page; Discipline and Holy put heals on the
-- plain keys and damage on Shift (healer rule) and drop that page. Apply
-- fills the bars, the plan agrees afterwards, nothing creates a macro, and
-- installed macros take their homes.
local H = require("harness")

local function T3(disc, holy, shadow)
  return { { name = "Discipline", points = disc }, { name = "Holy", points = holy }, { name = "Shadow", points = shadow } }
end

-- Boots the priest fixture with extra learned spells (talents the fixture
-- keeps in its catalog).
local function Boot(opts, learn)
  opts = opts or {}
  opts.fixture = "priest"
  local setup = opts.setup
  opts.setup = function(W)
    for i, name in ipairs(learn or {}) do
      table.insert(W.fixture.spells, { name = name, id = 990000 + i })
    end
    if setup then setup(W) end
  end
  return H.boot(opts)
end

local SHADOW = { "Mind Flay", "Vampiric Embrace", "Shadowform", "Silence" }

local function Pad(layer, button)
  local n = layer * 8 + button
  return 180 + (n < 5 and n or n - 4)
end

test("priest: each spec's keyboard and controller resolve", function()
  local env = Boot()
  local L = env.ns.Layout
  for _, spec in ipairs(L.Specs("PRIEST")) do
    local kb = L.KeyboardBars("PRIEST", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    ok(L.ControllerPages("PRIEST", spec.key), spec.key .. " controller")
  end
end)

test("priest: Shadow levels; talents pick Discipline or Holy", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("PRIEST").key, "shadow")
  eq(Boot({ talents = T3(31, 20, 0) }).ns.Layout.ActiveSpec("PRIEST").key, "discipline")
  eq(Boot({ talents = T3(10, 31, 0) }).ns.Layout.ActiveSpec("PRIEST").key, "holy")
  eq(Boot({ talents = T3(0, 15, 36) }).ns.Layout.ActiveSpec("PRIEST").key, "shadow")
end)

test("priest: only Shadow has the Shadowform page; Discipline and Holy share their bars", function()
  local L = Boot().ns.Layout
  local function First(e) if type(e) ~= "table" then return tostring(e) end return e.macro or e[1] or (e.racial and "racial") or "?" end
  local disc, holy = L.KeyboardBars("PRIEST", "discipline"), L.KeyboardBars("PRIEST", "holy")
  for _, bar in ipairs({ 1, 2, 4 }) do
    for i = 1, 12 do eq(First(holy[bar][i]), First(disc[bar][i]), "Holy bar " .. bar .. " key " .. i) end
  end
  local sf = L.StancePages("PRIEST", "shadow")
  eq(#sf, 1, "Shadow has one stance page")
  eq(sf[1] and sf[1].key, "shadowform", "it is Shadowform")
  eq(sf[1] and sf[1].offset, 1, "Shadowform offset")
  eq(#L.StancePages("PRIEST", "discipline"), 0, "Discipline drops it")
  eq(#L.StancePages("PRIEST", "holy"), 0, "Holy drops it")
end)


test("priest: a level 10 Shadow priest has its rotation on Q E R F and the shield on 1", function()
  local env = Boot({ level = 10 })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Smite", "Q (no Mind Flay yet)")
  eq(env:slotText(2), "spell:Shadow Word: Pain", "E")
  eq(env:slotText(3), "spell:Mind Blast", "R (MindPull not installed)")
  eq(env:slotText(5), "spell:Shoot", "F wand")
  eq(env:slotText(9), "spell:Power Word: Shield", "1 pull")
  eq(env:slotText(11), "spell:Dispel Magic", "3 until Silence")
  eq(#env:calls("CreateMacro"), 0)
end)

test("priest: Shadow Apply fills Bar 1, the Shadowform page and the controller; no macro is created", function()
  local env = Boot({ talents = T3(5, 0, 46) }, SHADOW)
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Mind Flay", "Q slot 1")
  eq(env:slotText(2), "spell:Shadow Word: Pain", "E slot 2")
  eq(env:slotText(3), "spell:Mind Blast", "R slot 3")
  eq(env:slotText(4), "spell:Vampiric Embrace", "T slot 5")
  eq(env:slotText(5), "spell:Shoot", "F slot 4")
  eq(env:slotText(6), "spell:Shadow Word: Death", "G reactive")
  eq(env:slotText(7), "spell:Fade", "C")
  eq(env:slotText(8), nil, "V empty (no snare)")
  eq(env:slotText(9), "spell:Power Word: Shield", "1 pull")
  eq(env:slotText(10), "spell:Devouring Plague", "2 AoE")
  eq(env:slotText(11), "spell:Silence", "3 interrupt")
  eq(env:slotText(12), nil, "4 Holy Nova not learned")
  eq(env:slotText(61), "spell:Flash Heal", "Shift+Q")
  eq(env:slotText(62), "spell:Touch of Weakness", "Shift+E: the Undead level 10 spell")
  eq(env:slotText(67), "spell:Will of the Forsaken", "Shift+C racial")
  eq(env:slotText(68), "spell:Dark Sacrifice", "Shift+V: the Undead level 20 spell")
  eq(env:slotText(71), "spell:Shadowform", "Shift+3")
  eq(env:slotText(25), "spell:Holy Fire", "Ctrl+Q")
  eq(env:slotText(30), "spell:Greater Heal", "Ctrl+G: the top heal")
  -- Shadowform page: slots 73-84.
  eq(env:slotText(73), "spell:Mind Flay", "Shadowform Q")
  eq(env:slotText(75), "spell:Mind Blast", "Shadowform R")
  eq(env:slotText(76), "spell:Vampiric Embrace", "Shadowform T")
  eq(env:slotText(81), "spell:Power Word: Shield", "Shadowform 1")
  eq(env:slotText(82), "spell:Devouring Plague", "Shadowform 2")
  eq(env:slotText(84), nil, "Shadowform 4 empty (Holy Nova cancels the form)")
  eq(env:slotText(Pad(2, 8)), "spell:Mind Flay", "controller RT A")
  eq(env:slotText(Pad(2, 5)), "spell:Shadow Word: Pain", "controller RT X")
  eq(env:slotText(Pad(2, 6)), "spell:Mind Blast", "controller RT Y")
  eq(env:slotText(Pad(2, 7)), "spell:Shoot", "controller RT B")
  eq(env:slotText(Pad(1, 8)), "spell:Vampiric Embrace", "controller LT A")
  eq(env:slotText(Pad(1, 7)), "spell:Silence", "controller LT B")
  eq(env:slotText(Pad(1, 6)), "spell:Devouring Plague", "controller LT Y")
  eq(env:slotText(Pad(2, 2)), "spell:Power Word: Shield", "controller RT Up")
  eq(env:slotText(Pad(1, 1)), "spell:Mind Control", "controller LT Left")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("priest: Discipline heals on the plain keys, damage on Shift, no Shadowform page", function()
  local env = Boot({ talents = T3(36, 15, 0) }, { "Penance", "Power Infusion", "Inner Focus" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Heal", "Q main heal")
  eq(env:slotText(2), "spell:Renew", "E HoT")
  eq(env:slotText(3), "spell:Penance", "R slot 3: Penance (Disc priority 2)")
  eq(env:slotText(4), "spell:Dispel Magic", "T dispel")
  eq(env:slotText(5), "spell:Flash Heal", "F fast heal")
  eq(env:slotText(6), nil, "G waits for Prayer of Mending (Holy)")
  eq(env:slotText(8), "spell:Greater Heal", "V big slow heal")
  eq(env:slotText(25), "spell:Devouring Plague", "Ctrl+Q damage cooldown")
  eq(env:slotText(9), "spell:Power Word: Shield", "1 shield")
  eq(env:slotText(10), "spell:Prayer of Healing", "2 group heal")
  eq(env:slotText(11), "spell:Abolish Disease", "3 second dispel")
  eq(env:slotText(61), "spell:Smite", "Shift+Q")
  eq(env:slotText(62), "spell:Shadow Word: Pain", "Shift+E")
  eq(env:slotText(63), "spell:Mind Blast", "Shift+R")
  eq(env:slotText(64), "spell:Holy Fire", "Shift+T")
  eq(env:slotText(65), "spell:Shoot", "Shift+F wand")
  eq(env:slotText(71), "spell:Power Infusion", "Shift+3 (Empower not installed)")
  eq(env:slotText(29), "spell:Shackle Undead", "Ctrl+F")
  eq(env:slotText(30), "spell:Mind Control", "Ctrl+G")
  eq(env:slotText(73), nil, "no Shadowform page")
  eq(env:slotText(Pad(2, 8)), "spell:Heal", "controller RT A")
  eq(env:slotText(Pad(2, 5)), "spell:Renew", "controller RT X")
  eq(env:slotText(Pad(2, 6)), "spell:Power Word: Shield", "controller RT Y (moved)")
  eq(env:slotText(Pad(2, 7)), "spell:Flash Heal", "controller RT B")
  eq(env:slotText(Pad(2, 2)), "spell:Penance", "controller RT Up (slot 3, moved)")
  eq(env:slotText(Pad(2, 3)), "spell:Greater Heal", "controller RT Right = V")
  eq(env:slotText(Pad(3, 2)), "spell:Devouring Plague", "controller LT+RT Up = Ctrl+Q")
  eq(env:slotText(Pad(1, 8)), "spell:Dispel Magic", "controller LT A")
  eq(env:slotText(Pad(1, 5)), nil, "controller LT X waits for Prayer of Mending")
  eq(env:slotText(Pad(1, 6)), "spell:Prayer of Healing", "controller LT Y")
  eq(env:slotText(Pad(1, 2)), "spell:Smite", "controller LT Up")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("priest: a low-level healer has Lesser Heal on Q until Heal", function()
  local env = Boot({ talents = T3(0, 5, 0), setup = function(W)
    for i = #W.fixture.spells, 1, -1 do
      local n = W.fixture.spells[i].name
      if n == "Heal" or n == "Greater Heal" or n == "Binding Heal" then table.remove(W.fixture.spells, i) end
    end
  end })
  env:slash("spells apply")
  noErrors(env)
  eq(env.ns.Layout.ActiveSpec("PRIEST").key, "holy")
  eq(env:slotText(1), "spell:Lesser Heal", "Q")
  eq(env:slotText(3), nil, "R waits for Penance (Disc talent, 30) / Binding Heal (trainer, 56)")
  eq(env:slotText(8), nil, "V waits for Greater Heal (40)")
end)

test("priest: Holy gets Binding Heal on R, Prayer of Mending on G and Holy Nova on 4", function()
  local env = Boot({ talents = T3(15, 36, 0) }, { "Prayer of Mending", "Holy Nova" })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(6), "spell:Prayer of Mending", "G")
  eq(env:slotText(3), "spell:Binding Heal", "R: Binding Heal, a trainer spell (56), without Penance")
  for _, s in ipairs(env.W.fixture.catalog) do ok(s.name ~= "Binding Heal", "Binding Heal is a trainer spell, not a talent") end
  eq(env:slotText(8), "spell:Greater Heal", "V")
  eq(env:slotText(12), "spell:Holy Nova", "4")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("priest: installed macros take their homes", function()
  local env = Boot({ talents = T3(0, 5, 46), macros = { "MindPull", "Flay" } }, SHADOW)
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "macro:Flay", "Q")
  eq(env:slotText(73), "macro:Flay", "Shadowform Q")
  eq(env:slotText(3), "macro:MindPull", "R")
  eq(env:slotText(75), "macro:MindPull", "Shadowform R")
end)

test("priest: installed self-cast macros take their homes in every spec", function()
  local heal = { "PriestHeal", "PriestRenew", "PriestFlash", "PriestShield", "DispelMagic" }
  local env = Boot({ talents = T3(36, 15, 0), macros = heal }, { "Penance", "Power Infusion", "Inner Focus" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "macro:PriestHeal", "Discipline Q")
  eq(env:slotText(2), "macro:PriestRenew", "Discipline E")
  eq(env:slotText(4), "macro:DispelMagic", "Discipline T")
  eq(env:slotText(5), "macro:PriestFlash", "Discipline F")
  eq(env:slotText(9), "macro:PriestShield", "Discipline 1")
  eq(env:slotText(Pad(2, 8)), "macro:PriestHeal", "controller RT A")
  eq(env:slotText(Pad(2, 5)), "macro:PriestRenew", "controller RT X")
  eq(env:slotText(Pad(2, 6)), "macro:PriestShield", "controller RT Y")
  eq(env:slotText(Pad(2, 7)), "macro:PriestFlash", "controller RT B")
  eq(env:slotText(Pad(1, 8)), "macro:DispelMagic", "controller LT A")
  local holy = env.ns.Layout.KeyboardBars("PRIEST", "holy")[1]
  eq(holy[1].macro, "PriestHeal", "Holy Q")
  eq(holy[9].macro, "PriestShield", "Holy 1")
  env = Boot({ talents = T3(0, 5, 46), macros = { "ShadowOn", "PriestShield", "PriestFlash", "PriestRenew" } }, SHADOW)
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(9), "macro:PriestShield", "Shadow 1")
  eq(env:slotText(81), "macro:PriestShield", "Shadowform 1")
  eq(env:slotText(61), "macro:PriestFlash", "Shadow Shift+Q")
  eq(env:slotText(71), "macro:ShadowOn", "Shadow Shift+3")
  eq(env:slotText(29), "macro:PriestRenew", "Shadow Ctrl+F")
end)

test("priest: every priest macro with specs names real spec keys and is tagged recommended", function()
  local env = Boot()
  local valid = {}
  for _, s in ipairs(env.ns.Layout.Specs("PRIEST")) do valid[s.key] = true end
  local count = {}
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "PRIEST" and m.specs then
      ok(#m.specs > 0, m.name .. ": specs not empty")
      local rec = false
      for _, t in ipairs(m.tags or {}) do if t == "recommended" then rec = true end end
      ok(rec, m.name .. ": tagged recommended")
      for _, k in ipairs(m.specs) do
        ok(valid[k], m.name .. ": unknown spec key " .. tostring(k))
        count[k] = (count[k] or 0) + 1
      end
    end
  end
  for k in pairs(valid) do
    ok((count[k] or 0) >= 2 and count[k] <= 6, k .. ": 2-6 recommended macros, got " .. tostring(count[k]))
  end
end)
