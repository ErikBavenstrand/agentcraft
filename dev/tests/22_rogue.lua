-- Rogue layouts (key roles: dev/key-roles.md): rotation first. Shared Bar 1
-- (Combat changes Q, Subtlety its Bar 1, Stealth page and Ctrl), Apply
-- fills Bar 1, its Stealth page (slots 73-84) and the controller, the plan
-- agrees afterwards, and nothing creates a macro.
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

test("rogue: Apply puts Combat's rotation on Q E R F T, openers on the Stealth page; no macro is created", function()
  local env = Boot({ talents = COMBAT })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Sinister Strike", "Q: builder (Strike not installed)")
  eq(env:slotText(2), "spell:Shank", "E: slot 2")
  eq(env:slotText(3), "spell:Eviscerate", "R: slot 3")
  eq(env:slotText(4), "spell:Rupture", "T: slot 5")
  eq(env:slotText(5), "spell:Slice and Dice", "F: slot 4")
  eq(env:slotText(6), "spell:Riposte", "G: proc")
  eq(env:slotText(9), "spell:Throw", "1: ranged pull")
  eq(env:slotText(10), "spell:Blade Flurry", "2: AoE")
  eq(env:slotText(11), "spell:Kick", "3: interrupt")
  eq(env:slotText(12), "spell:Feint", "4: big pulls")
  eq(env:slotText(69), "spell:Stealth", "Shift+1 (Bar 2 = slots 61-72)")
  eq(env:slotText(63), "spell:Adrenaline Rush", "Shift+R: burst")
  eq(env:slotText(73), "spell:Sinister Strike", "Stealth Q (slot 72 + 1)")
  eq(env:slotText(74), "spell:Garrote", "Stealth E")
  eq(env:slotText(75), "spell:Ambush", "Stealth R")
  eq(env:slotText(81), "spell:Cheap Shot", "Stealth 1: opener")
  eq(env:slotText(82), "spell:Blade Flurry", "Stealth 2: same key as base")
  eq(env:slotText(env:padSlot(1, "RT A")), "spell:Sinister Strike", "controller RT A: slot 1")
  eq(env:slotText(env:padSlot(1, "RT X")), "spell:Shank", "controller RT X: slot 2")
  eq(env:slotText(env:padSlot(1, "RT Y")), "spell:Eviscerate", "controller RT Y: slot 3")
  eq(env:slotText(env:padSlot(1, "RT B")), "spell:Slice and Dice", "controller RT B: slot 4")
  eq(env:slotText(env:padSlot(1, "LT B")), "spell:Kick", "controller LT B: interrupt")
  eq(env:slotText(env:padSlot(1, "RT Up")), "spell:Cheap Shot", "controller RT Up: opener")
  eq(env:slotText(env:padSlot(1, "RT Down")), "spell:Garrote", "controller RT Down: second opener")
  eq(env:slotText(env:padSlot(1, "none Up")), "spell:Stealth", "controller none Up")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("rogue: a level 10 rogue has its rotation on Q E R F", function()
  local env = Boot({ level = 10, talents = { { name = "Assassination", points = 0 }, { name = "Combat", points = 0 }, { name = "Subtlety", points = 0 } } })
  local bar = env.ns.Layout.KeyboardBars("ROGUE", "combat")[1]
  eq(bar[2][2], "Backstab", "E falls back to Backstab before Shank (24)")
  eq(bar[5][1], "Slice and Dice", "F")
end)

test("rogue: installed macros take their homes", function()
  local env = Boot({ talents = COMBAT, macros = { "Strike", "Premed", "Blades", "Poof", "PickGarrote" } })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "macro:Strike", "Q")
  eq(env:slotText(63), "macro:Blades", "Shift+R")
  eq(env:slotText(74), "macro:PickGarrote", "Stealth E")
  eq(env:slotText(75), "macro:Premed", "Stealth R")
  eq(env:slotText(68), "macro:Poof", "Shift+V (Bar 2 = slots 61-72)")
end)

test("rogue: each spec's builder on Q; Subtlety keeps Garrote and Premeditation on one key in and out of Stealth; Death Mark on the finisher key", function()
  local L = Boot().ns.Layout
  eq(L.KeyboardBars("ROGUE", "combat")[1][1].macro, "Strike", "combat Q")
  eq(L.KeyboardBars("ROGUE", "assassination")[1][1][1], "Mutilate", "assassination Q chain")
  local sub = L.KeyboardBars("ROGUE", "subtlety")
  eq(sub[1][1][1], "Hemorrhage", "subtlety Q")
  eq(sub[1][9][1], "Garrote", "subtlety 1: Garrote (after Ghostly Strike)")
  eq(sub[1][3][1], "Death Mark", "subtlety R: Death Mark, the excess-CP finisher (Wowhead)")
  eq(sub[1][3][2], "Eviscerate", "subtlety R: Eviscerate without Death Mark (Hemo Seal Fate)")
  eq(sub[1][10][1], "Premeditation", "subtlety 2: Premeditation (no AoE)")
  eq(sub[1][8][1], "Gouge", "subtlety V: Gouge, as every spec")
  ok(not sub[4][4], "subtlety Ctrl+T: free again")
  eq(#sub.stances, 1, "one Stealth page")
  eq(sub.stances[1].key, "stealth", "the Stealth page")
  local st = sub.stances[1].entries
  eq(st[9][1], "Garrote", "subtlety Stealth 1: same key as base")
  eq(st[10][1], "Premeditation", "subtlety Stealth 2: same key as base")
  eq(L.ControllerPages("ROGUE", "subtlety")[1]["RT Y"][1], "Death Mark", "subtlety controller RT Y")
  eq(L.ControllerPages("ROGUE", "subtlety")[1]["LT Y"][1], "Premeditation", "subtlety controller LT Y")
  eq(L.ControllerPages("ROGUE", "assassination")[1]["RT A"][1], "Mutilate", "assassination controller RT A")
end)

test("rogue: Combat has Blade Flurry + Adrenaline Rush on Shift+R and Cold Blood on its own key (Wowhead)", function()
  local L = Boot().ns.Layout
  local kb = L.KeyboardBars("ROGUE", "combat")
  eq(kb[2][3].macro, "Blades", "combat Shift+R: Blades")
  eq(kb[2][3][1], "Adrenaline Rush", "combat Shift+R fallback")
  eq(kb[4][3][1], "Cold Blood", "combat Ctrl+R: Cold Blood")
  for _, s in ipairs(kb[2][3]) do ok(s ~= "Cold Blood", "Cold Blood has one home") end
  eq(L.KeyboardBars("ROGUE", "assassination")[2][3][2], "Cold Blood", "assassination Shift+R chain keeps Cold Blood")
  eq(L.ControllerPages("ROGUE", "combat")[1]["LT+RT Right"][1], "Cold Blood", "combat controller LT+RT Right")
end)

-- Learns `names` (talents the fixture keeps in its catalog) on boot.
local function Learn(names)
  return function(W)
    for i, name in ipairs(names) do table.insert(W.fixture.spells, { name = name, id = 990000 + i }) end
  end
end

test("rogue: installed recommended macros take the builder and Stealth homes in every spec", function()
  local env = Boot({ talents = { { name = "Assassination", points = 31 }, { name = "Combat", points = 5 }, { name = "Subtlety", points = 15 } },
    setup = Learn({ "Mutilate" }), macros = { "MutiAttack", "StealthOn" } })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "macro:MutiAttack", "assassination Q")
  eq(env:slotText(73), "macro:MutiAttack", "assassination Stealth Q")
  eq(env:slotText(69), "macro:StealthOn", "Shift+1")
  eq(env:slotText(env:padSlot(1, "RT A")), "macro:MutiAttack", "assassination controller RT A")
  eq(env:slotText(env:padSlot(1, "none Up")), "macro:StealthOn", "controller none Up")
  env = Boot({ talents = { { name = "Assassination", points = 0 }, { name = "Combat", points = 5 }, { name = "Subtlety", points = 31 } },
    setup = Learn({ "Hemorrhage", "Premeditation" }), macros = { "HemoAttack", "StealthOn" } })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "macro:HemoAttack", "subtlety Q")
  eq(env:slotText(73), "macro:HemoAttack", "subtlety Stealth Q")
  eq(env:slotText(69), "macro:StealthOn", "subtlety Shift+1")
  eq(env:slotText(env:padSlot(1, "RT A")), "macro:HemoAttack", "subtlety controller RT A")
  local L = env.ns.Layout
  eq(L.KeyboardBars("ROGUE", "combat")[2][9].macro, "StealthOn", "combat Shift+1")
  eq(L.ControllerPages("ROGUE", "combat")[1]["none Up"].macro, "StealthOn", "combat controller none Up")
end)

test("rogue: every rogue macro with specs names real spec keys and is tagged recommended", function()
  local env = Boot()
  local valid = {}
  for _, s in ipairs(env.ns.Layout.Specs("ROGUE")) do valid[s.key] = true end
  local count = {}
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "ROGUE" and m.specs then
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
