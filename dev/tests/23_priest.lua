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

test("priest: a Shadow priest without talents gets Smite, the wand and the shield on Shift", function()
  local env = Boot({ level = 10 })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Smite", "Q (no Mind Flay yet)")
  eq(env:slotText(2), "spell:Shadow Word: Pain", "E")
  eq(env:slotText(3), "spell:Mind Blast", "R")
  eq(env:slotText(5), "spell:Shoot", "F")
  eq(env:slotText(62), "spell:Power Word: Shield", "Shift+E")
  eq(#env:calls("CreateMacro"), 0)
end)

test("priest: Shadow Apply fills Bar 1, the Shadowform page and the controller; no macro is created", function()
  local env = Boot({ talents = T3(5, 0, 46) }, SHADOW)
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Mind Flay", "Q")
  eq(env:slotText(2), "spell:Shadow Word: Pain", "E")
  eq(env:slotText(3), "spell:Mind Blast", "R")
  eq(env:slotText(4), "spell:Vampiric Embrace", "T")
  eq(env:slotText(7), "spell:Fade", "C")
  eq(env:slotText(8), nil, "V empty (no snare)")
  eq(env:slotText(9), "spell:Holy Fire", "1")
  eq(env:slotText(11), "spell:Silence", "3")
  eq(env:slotText(12), "spell:Devouring Plague", "4")
  eq(env:slotText(61), "spell:Flash Heal", "Shift+Q")
  eq(env:slotText(67), "spell:Will of the Forsaken", "Shift+C racial")
  eq(env:slotText(68), "spell:Dark Sacrifice", "Shift+V: the Undead level 20 spell")
  eq(env:slotText(71), "spell:Shadowform", "Shift+3")
  eq(env:slotText(26), "spell:Touch of Weakness", "Ctrl+E: the Undead level 10 spell")
  eq(env:slotText(30), "spell:Greater Heal", "Ctrl+G: the top heal")
  -- Shadowform page: slots 73-84.
  eq(env:slotText(73), "spell:Mind Flay", "Shadowform Q")
  eq(env:slotText(76), "spell:Vampiric Embrace", "Shadowform T")
  eq(env:slotText(81), nil, "Shadowform 1 waits for MindPull")
  eq(env:slotText(82), nil, "Shadowform 2 empty (no Holy Nova in form)")
  eq(env:slotText(84), "spell:Devouring Plague", "Shadowform 4")
  eq(env:slotText(Pad(2, 8)), "spell:Mind Flay", "controller RT A")
  eq(env:slotText(Pad(2, 3)), "spell:Mind Blast", "controller RT Right")
  eq(env:slotText(Pad(1, 1)), "spell:Mind Control", "controller LT Left")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("priest: Discipline heals on the plain keys, damage on Shift, no Shadowform page", function()
  local env = Boot({ talents = T3(36, 15, 0) }, { "Penance", "Power Infusion", "Inner Focus" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Flash Heal", "Q main heal")
  eq(env:slotText(2), "spell:Renew", "E HoT")
  eq(env:slotText(3), "spell:Greater Heal", "R big heal")
  eq(env:slotText(4), "spell:Penance", "T spec heal")
  eq(env:slotText(9), "spell:Prayer of Healing", "1 group heal")
  eq(env:slotText(11), "spell:Dispel Magic", "3 (no Silence)")
  eq(env:slotText(12), "spell:Power Word: Shield", "4")
  eq(env:slotText(61), "spell:Smite", "Shift+Q")
  eq(env:slotText(63), "spell:Mind Blast", "Shift+R")
  eq(env:slotText(64), "spell:Holy Fire", "Shift+T")
  eq(env:slotText(71), "spell:Power Infusion", "Shift+3 (Empower not installed)")
  eq(env:slotText(29), "spell:Mind Control", "Ctrl+F")
  eq(env:slotText(73), nil, "no Shadowform page")
  eq(env:slotText(Pad(2, 8)), "spell:Flash Heal", "controller RT A")
  eq(env:slotText(Pad(2, 1)), "spell:Penance", "controller RT Left")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("priest: Holy gets Prayer of Mending on T and Holy Nova on 2", function()
  local env = Boot({ talents = T3(15, 36, 0) }, { "Prayer of Mending", "Holy Nova" })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(4), "spell:Prayer of Mending", "T")
  eq(env:slotText(10), "spell:Holy Nova", "2")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("priest: installed macros take their homes", function()
  local env = Boot({ talents = T3(0, 5, 46), macros = { "MindPull", "Flay" } }, SHADOW)
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "macro:Flay", "Q")
  eq(env:slotText(73), "macro:Flay", "Shadowform Q")
  eq(env:slotText(81), "macro:MindPull", "Shadowform 1")
end)
