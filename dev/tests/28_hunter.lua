-- Hunter specs: Beast Mastery keeps the owner's tuned layout, Marksmanship
-- gets its talents through the shared chains, Survival has its own Shift
-- and Ctrl bars (Aspect of the Beast on Shift+2, Wyvern Sting on Ctrl+T).
-- Apply fills the bars, the plan agrees afterwards, nothing creates a macro.
local H = require("harness")

local function T3(bm, mm, sv)
  return { { name = "Beast Mastery", points = bm }, { name = "Marksmanship", points = mm }, { name = "Survival", points = sv } }
end

-- Boots the hunter fixture with extra learned spells (talents the fixture
-- only names for the rules).
local function Boot(opts, learn)
  opts = opts or {}
  opts.fixture = "hunter"
  local setup = opts.setup
  opts.setup = function(W)
    for i, name in ipairs(learn or {}) do
      table.insert(W.fixture.spells, { name = name, id = 990000 + i })
    end
    if setup then setup(W) end
  end
  return H.boot(opts)
end

test("hunter: each spec's keyboard and controller resolve", function()
  local env = Boot()
  local L = env.ns.Layout
  for _, spec in ipairs(L.Specs("HUNTER")) do
    local kb = L.KeyboardBars("HUNTER", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    ok(L.ControllerPages("HUNTER", spec.key), spec.key .. " controller")
  end
end)

test("hunter: BM and MM share every bar; only Survival overrides Shift and Ctrl", function()
  local L = Boot().ns.Layout
  local bm, mm, sv = L.KeyboardBars("HUNTER", "bm"), L.KeyboardBars("HUNTER", "mm"), L.KeyboardBars("HUNTER", "sv")
  local function Same(a, b, what)
    for i = 1, 12 do
      local x, y = a[i], b[i]
      eq(x and (x[1] or x.macro or tostring(x.racial)), y and (y[1] or y.macro or tostring(y.racial)), what .. " key " .. i)
    end
  end
  for _, bar in ipairs({ 1, 2, 4 }) do Same(mm[bar], bm[bar], "MM bar " .. bar) end
  Same(sv[1], bm[1], "SV bar 1 shared")
  eq(bm[2][10][1], "Aspect of the Monkey", "BM Shift+2")
  eq(bm[4][9][1], "Aspect of the Beast", "BM Ctrl+1")
  eq(sv[2][10][1], "Aspect of the Beast", "SV Shift+2")
  eq(sv[4][9][1], "Aspect of the Monkey", "SV Ctrl+1")
  eq(sv[4][4][1], "Wyvern Sting", "SV Ctrl+T")
  eq(bm[1][4][3], "Strider Kick", "T chain ends in Strider Kick")
end)

test("hunter: the leveling spec until talents say otherwise", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("HUNTER").key, "bm")
  eq(Boot({ talents = T3(5, 31, 15) }).ns.Layout.ActiveSpec("HUNTER").key, "mm")
  eq(Boot({ talents = T3(0, 20, 31) }).ns.Layout.ActiveSpec("HUNTER").key, "sv")
end)

test("hunter: BM with Summon Hawk keeps it on T; no macro is created", function()
  local env = Boot({ level = 32, talents = T3(20, 0, 0) }, { "Summon Hawk" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Arcane Shot", "Q")
  eq(env:slotText(4), "spell:Summon Hawk", "T")
  eq(env:slotText(70), "spell:Aspect of the Monkey", "Shift+2")
  eq(env:padSlot(1, "RT Left") and env:slotText(env:padSlot(1, "RT Left")), "spell:Summon Hawk", "controller RT Left")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("hunter: Marksmanship gets Sniper Shot on T and Trueshot Aura on Shift+E", function()
  local env = Boot({ talents = T3(5, 31, 15) }, { "Sniper Shot", "Trueshot Aura" })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(4), "spell:Sniper Shot", "T")
  eq(env:slotText(3), "spell:Aimed Shot", "R")
  eq(env:slotText(62), "spell:Trueshot Aura", "Shift+E")
  eq(env:slotText(64), "spell:Counterattack", "Shift+T: the fixture's Counterattack comes first in the chain")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("hunter: Survival gets Strider Kick, Deterrence, Beast on Shift+2 and Wyvern Sting on Ctrl+T", function()
  local env = Boot({ talents = T3(0, 20, 31) }, { "Strider Kick", "Deterrence", "Aspect of the Beast", "Wyvern Sting" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(4), "spell:Strider Kick", "T")
  eq(env:slotText(62), "spell:Deterrence", "Shift+E")
  eq(env:slotText(70), "spell:Aspect of the Beast", "Shift+2")
  eq(env:slotText(33), "spell:Aspect of the Monkey", "Ctrl+1")
  eq(env:slotText(28), "spell:Wyvern Sting", "Ctrl+T")
  eq(env:slotText(env:padSlot(1, "RT Left")), "spell:Strider Kick", "controller RT Left")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)
