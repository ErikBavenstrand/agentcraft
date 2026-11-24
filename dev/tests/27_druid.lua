-- Druid layouts: Feral and Balance share the keyboard (caster, Cat, Bear and
-- Moonkin pages, each keeping the key roles of dev/key-roles.md),
-- Restoration follows the healer rule and drops the Moonkin page; Apply
-- fills Bar 1, the form pages (cat 73-84, bear 97-108, moonkin 109-120) and
-- the controller, the plan agrees afterwards, and nothing creates a macro.
local H = require("harness")

local function Boot(opts)
  opts = opts or {}
  opts.fixture = "druid"
  return H.boot(opts)
end

local FERAL = { { name = "Balance", points = 0 }, { name = "Feral Combat", points = 31 }, { name = "Restoration", points = 5 } }
local BALANCE = { { name = "Balance", points = 31 }, { name = "Feral Combat", points = 0 }, { name = "Restoration", points = 10 } }
local RESTO = { { name = "Balance", points = 5 }, { name = "Feral Combat", points = 0 }, { name = "Restoration", points = 31 } }

-- Gamepad slot of a page button (dev/layout-format.md formula; env:padSlot
-- knows only the buttons pinned from the hunter's game).
local LAYER = { none = 0, LT = 1, RT = 2, ["LT+RT"] = 3 }
local BUTTON = { Left = 1, Up = 2, Right = 3, Down = 4, X = 5, Y = 6, B = 7, A = 8 }
local function Pad(set, key)
  local layer, button = key:match("^(%S+) (%S+)$")
  local n = LAYER[layer] * 8 + BUTTON[button]
  return 180 + (set - 1) * 28 + (n < 5 and n or n - 4)
end

test("druid: each spec's keyboard and controller resolve", function()
  local env = Boot()
  local L = env.ns.Layout
  for _, spec in ipairs(L.Specs("DRUID")) do
    local kb = L.KeyboardBars("DRUID", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    ok(L.ControllerPages("DRUID", spec.key), spec.key .. " controller")
  end
end)

test("druid: Feral is the leveling spec until talents say otherwise", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("DRUID").key, "feral")
  eq(Boot({ talents = BALANCE }).ns.Layout.ActiveSpec("DRUID").key, "balance")
  eq(Boot({ talents = RESTO }).ns.Layout.ActiveSpec("DRUID").key, "restoration")
  eq(Boot({ talents = FERAL }).ns.Layout.ActiveSpec("DRUID").key, "feral")
end)

test("druid: Feral Apply keeps the key roles on every form page; no macro is created", function()
  local env = Boot({ talents = FERAL })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  -- Q main attack, E DoT, R big hitter on every page.
  eq(env:slotText(1), "spell:Wrath", "caster Q")
  eq(env:slotText(2), "spell:Moonfire", "caster E")
  eq(env:slotText(8), "spell:Entangling Roots", "caster V: snare")
  eq(env:slotText(12), "spell:Hurricane", "caster 4: ground AoE")
  eq(env:slotText(73), "spell:Claw", "Cat Q (slot 72 + 1)")
  eq(env:slotText(74), "spell:Rake", "Cat E")
  eq(env:slotText(75), "spell:Ferocious Bite", "Cat R")
  eq(env:slotText(79), "spell:Dash", "Cat C: escape")
  eq(env:slotText(81), "spell:Prowl", "Cat 1 (CatOpener not installed)")
  eq(env:slotText(83), "spell:Pounce", "Cat 3: control")
  eq(env:slotText(97), "spell:Maul", "Bear Q (slot 96 + 1)")
  eq(env:slotText(106), "spell:Swipe", "Bear 2: main AoE")
  eq(env:slotText(107), "spell:Bash", "Bear 3: control")
  eq(env:slotText(108), "spell:Demoralizing Roar", "Bear 4")
  eq(env:slotText(109), "spell:Wrath", "Moonkin Q (slot 108 + 1)")
  eq(env:slotText(61), "spell:Regrowth", "Shift+Q self-heal (Regrow not installed)")
  eq(env:slotText(67), "spell:War Stomp", "Shift+C racial")
  eq(env:slotText(68), "spell:Barkskin", "Shift+V emergency")
  eq(env:slotText(69), "spell:Dire Bear Form", "Shift+1: Dire Bear replaces Bear")
  eq(env:slotText(72), "spell:Aquatic Form", "Shift+4: no Moonkin Form, so Aquatic")
  eq(env:slotText(25), "spell:Faerie Fire", "Ctrl+Q")
  eq(env:slotText(Pad(1, "RT A")), "spell:Claw", "controller RT A: Q role (FormAttack not installed)")
  eq(env:slotText(Pad(1, "RT Y")), "spell:Swipe", "controller RT Y: main AoE")
  eq(env:slotText(Pad(1, "LT A")), "spell:Shred", "controller LT A: F role")
  eq(env:slotText(Pad(1, "LT+RT A")), "spell:Barkskin", "controller LT+RT A: emergency")
  eq(env:slotText(Pad(1, "none Up")), "spell:Cat Form", "controller none Up")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("druid: Restoration follows the healer rule and drops the Moonkin page", function()
  local env = Boot({ talents = RESTO })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Regrowth", "Q main heal")
  eq(env:slotText(2), "spell:Rejuvenation", "E HoT")
  eq(env:slotText(3), "spell:Healing Touch", "R big heal")
  eq(env:slotText(8), "spell:Entangling Roots", "V snare unchanged")
  eq(env:slotText(10), "spell:Tranquility", "2")
  eq(env:slotText(61), "spell:Wrath", "Shift+Q damage")
  eq(env:slotText(68), "spell:Barkskin", "Shift+V unchanged")
  eq(env:slotText(73), "spell:Claw", "Cat page shared")
  eq(env:slotText(109), nil, "no Moonkin page")
  eq(env:slotText(Pad(1, "RT A")), "spell:Regrowth", "controller RT A: main heal")
  eq(env:slotText(Pad(1, "LT Up")), "spell:Wrath", "controller LT Up: Shift+Q")
  eq(env:slotText(Pad(2, "LT Y")), "spell:Innervate", "controller page 2 LT Y")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("druid: Balance keeps the shared keyboard; controller roles with caster spells", function()
  local env = Boot({ talents = BALANCE })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(3), "spell:Starfire", "R")
  eq(env:slotText(Pad(1, "RT A")), "spell:Wrath", "controller RT A")
  eq(env:slotText(Pad(1, "RT Right")), "spell:Starfire", "controller RT Right: R role")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("druid: installed macros take their homes", function()
  local env = Boot({ talents = FERAL, macros = { "Regrow", "Rejuv", "HTouch", "CatOpener", "FormAttack", "FormArea" } })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(61), "macro:Regrow", "Shift+Q")
  eq(env:slotText(29), "macro:Rejuv", "Ctrl+F")
  eq(env:slotText(30), "macro:HTouch", "Ctrl+G")
  eq(env:slotText(81), "macro:CatOpener", "Cat 1")
  eq(env:slotText(Pad(1, "RT A")), "macro:FormAttack", "controller RT A")
  eq(env:slotText(Pad(1, "RT Down")), "macro:FormArea", "controller RT Down")
  local resto = Boot({ talents = RESTO, macros = { "Regrow" } })
  resto:slash("spells apply")
  eq(resto:slotText(1), "macro:Regrow", "Restoration Q")
end)
