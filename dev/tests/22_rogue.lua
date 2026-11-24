-- Rogue layouts (key roles: dev/key-roles.md): one shared layout for all three specs (fallback chains),
-- Apply fills Bar 1, its Stealth page (slots 73-84) and the controller, the
-- plan agrees afterwards, and nothing creates a macro.
local H = require("harness")

local function Boot(opts)
  opts = opts or {}
  opts.fixture = "rogue"
  return H.boot(opts)
end

local COMBAT = { { name = "Assassination", points = 15 }, { name = "Combat", points = 31 }, { name = "Subtlety", points = 5 } }

test("rogue: each spec's keyboard and controller resolve", function()
  local env = Boot()
  local L = env.ns.Layout
  for _, spec in ipairs(L.Specs("ROGUE")) do
    local kb = L.KeyboardBars("ROGUE", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    ok(L.ControllerPages("ROGUE", spec.key), spec.key .. " controller")
  end
end)

test("rogue: Combat is the leveling spec until talents say otherwise", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("ROGUE").key, "combat")
  local env = Boot({ talents = { { name = "Assassination", points = 0 }, { name = "Combat", points = 5 }, { name = "Subtlety", points = 31 } } })
  eq(env.ns.Layout.ActiveSpec("ROGUE").key, "subtlety")
  env = Boot({ talents = { { name = "Assassination", points = 31 }, { name = "Combat", points = 5 }, { name = "Subtlety", points = 0 } } })
  eq(env.ns.Layout.ActiveSpec("ROGUE").key, "assassination")
end)

test("rogue: Apply fills Bar 1, the Stealth page and the controller; no macro is created", function()
  local env = Boot({ talents = COMBAT })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Sinister Strike", "Q (Strike not installed)")
  eq(env:slotText(4), "spell:Shank", "T")
  eq(env:slotText(6), "spell:Riposte", "G: proc")
  eq(env:slotText(9), "spell:Throw", "1: ranged pull")
  eq(env:slotText(69), "spell:Stealth", "Shift+1 (Bar 2 = slots 61-72)")
  eq(env:slotText(63), "spell:Adrenaline Rush", "Shift+R: burst")
  eq(env:slotText(73), "spell:Sinister Strike", "Stealth Q (slot 72 + 1)")
  eq(env:slotText(75), "spell:Ambush", "Stealth R")
  eq(env:slotText(81), "spell:Cheap Shot", "Stealth 1: opener")
  eq(env:slotText(env:padSlot(1, "RT A")), "spell:Sinister Strike", "controller RT A")
  eq(env:slotText(env:padSlot(1, "none Up")), "spell:Stealth", "controller none Up")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("rogue: installed macros take their homes", function()
  local env = Boot({ talents = COMBAT, macros = { "Strike", "Premed", "Blades", "Poof" } })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "macro:Strike", "Q")
  eq(env:slotText(63), "macro:Blades", "Shift+R")
  eq(env:slotText(75), "macro:Premed", "Stealth R")
  eq(env:slotText(68), "macro:Poof", "Shift+V (Bar 2 = slots 61-72)")
end)

test("rogue: Combat's Q is the Strike macro; the other specs share the builder chain", function()
  local L = Boot().ns.Layout
  eq(L.KeyboardBars("ROGUE", "combat")[1][1].macro, "Strike", "combat Q")
  eq(L.KeyboardBars("ROGUE", "subtlety")[1][1][2], "Hemorrhage", "subtlety Q chain")
  eq(L.KeyboardBars("ROGUE", "assassination")[1][1][1], "Mutilate", "assassination Q chain")
  eq(#L.KeyboardBars("ROGUE", "subtlety").stances, 1, "the Stealth page is shared")
end)
