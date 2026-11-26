-- Hunter specs (Wowhead WoW Forever guides, dev/key-roles.md): BM and MM
-- share one layout through fallback chains; Survival has its own Bar 1,
-- Shift, Ctrl and controller page 1 (no Aimed Shot; Strider Kick on R,
-- Immolation Trap on 3). Apply fills the bars, the plan agrees afterwards,
-- nothing creates a macro.
local H = require("harness")

local function T3(bm, mm, sv)
  return { { name = "Beast Mastery", points = bm }, { name = "Marksmanship", points = mm }, { name = "Survival", points = sv } }
end

-- Boots the hunter fixture with extra learned spells (talents the fixture
-- keeps in its catalog).
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

test("hunter: BM and MM share every bar; Survival has its own", function()
  local L = Boot().ns.Layout
  local bm, mm, sv = L.KeyboardBars("HUNTER", "bm"), L.KeyboardBars("HUNTER", "mm"), L.KeyboardBars("HUNTER", "sv")
  local function Same(a, b, what)
    for i = 1, 12 do
      local x, y = a[i], b[i]
      eq(x and (x[1] or x.macro or tostring(x.racial)), y and (y[1] or y.macro or tostring(y.racial)), what .. " key " .. i)
    end
  end
  for _, bar in ipairs({ 1, 2, 4 }) do Same(mm[bar], bm[bar], "MM bar " .. bar) end
  eq(bm[1][3][1], "Aimed Shot", "BM R")
  eq(bm[1][4][1], "Summon Hawk", "BM T")
  eq(bm[1][11][1], "Explosive Trap", "BM 3: damage trap")
  eq(bm[1][12][1], "Volley", "BM 4: ground AoE")
  eq(bm[2][4][1], "Intimidation", "BM Shift+T: cast-stopper")
  eq(bm[2][10][1], "Aspect of the Monkey", "BM Shift+2")
  eq(bm[4][5][1], "Scare Beast", "BM Ctrl+F")
  eq(bm[4][9][1], "Aspect of the Beast", "BM Ctrl+1")
  eq(sv[1][1].macro, "Arcane", "SV Q")
  eq(sv[1][3][1], "Strider Kick", "SV R")
  eq(sv[1][4][1], "Summon Hawk", "SV T")
  eq(sv[1][11][1], "Immolation Trap", "SV 3")
  eq(sv[1][12][1], "Volley", "SV 4")
  eq(sv[2][4][1], "Counterattack", "SV Shift+T")
  eq(sv[2][6][1], "Concussive Shot", "SV Shift+G")
  eq(sv[1][8][1], "Explosive Trap", "SV V")
  eq(sv[2][10][1], "Aspect of the Beast", "SV Shift+2")
  eq(sv[4][6][1], "Aimed Shot", "SV Ctrl+G")
  eq(sv[4][7][1], "Scare Beast", "SV Ctrl+C")
  eq(sv[4][9][1], "Aspect of the Monkey", "SV Ctrl+1")
end)

test("hunter: every spec's Wowhead rotation sits on plain keys and page 1 rotation buttons", function()
  local L = Boot().ns.Layout
  local common = { "Arcane Shot", "Serpent Sting", "Raptor Strike", "Mongoose Bite", "Wing Clip",
    "Hunter's Mark", "Multi-Shot", "Volley", "Summon Hawk" }
  local extra = {
    bm = { "Aimed Shot", "Explosive Trap", "Concussive Shot" },
    mm = { "Aimed Shot", "Sniper Shot", "Explosive Trap", "Concussive Shot" },
    sv = { "Strider Kick", "Immolation Trap", "Explosive Trap" },  -- Concussive: Shift+G (melee spec)
  }
  -- RT and LT face buttons and the RT D-pad (key-roles.md, controller page 1).
  local good = { ["RT A"] = true, ["RT X"] = true, ["RT Y"] = true, ["RT B"] = true, ["LT A"] = true, ["LT X"] = true,
    ["LT B"] = true, ["LT Y"] = true, ["RT Up"] = true, ["RT Down"] = true, ["RT Left"] = true, ["RT Right"] = true }
  local function Has(e, name)
    for _, n in ipairs(e) do if n == name then return true end end
    return false
  end
  for _, spec in ipairs(L.Specs("HUNTER")) do
    local kb, pages = L.KeyboardBars("HUNTER", spec.key), L.ControllerPages("HUNTER", spec.key)
    local list = {}
    for _, n in ipairs(common) do list[#list + 1] = n end
    for _, n in ipairs(extra[spec.key]) do list[#list + 1] = n end
    for _, name in ipairs(list) do
      local plain, pad = false, false
      for i = 1, 12 do if kb[1][i] and Has(kb[1][i], name) then plain = true end end
      for key, e in pairs(pages[1]) do if good[key] and type(e) == "table" and Has(e, name) then pad = true end end
      ok(plain, spec.key .. ": " .. name .. " on a plain key")
      ok(pad, spec.key .. ": " .. name .. " on a page 1 rotation button")
    end
  end
end)

test("hunter: the leveling spec until talents say otherwise", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("HUNTER").key, "bm")
  eq(Boot({ talents = T3(5, 31, 15) }).ns.Layout.ActiveSpec("HUNTER").key, "mm")
  eq(Boot({ talents = T3(0, 20, 31) }).ns.Layout.ActiveSpec("HUNTER").key, "sv")
end)

test("hunter: BM at 32 with Summon Hawk and Intimidation; no macro is created", function()
  local env = Boot({ level = 32, talents = T3(20, 0, 0) }, { "Summon Hawk", "Intimidation" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Arcane Shot", "Q")
  eq(env:slotText(2), "spell:Serpent Sting", "E")
  eq(env:slotText(3), "spell:Aimed Shot", "R")
  eq(env:slotText(4), "spell:Summon Hawk", "T")
  eq(env:slotText(5), "spell:Raptor Strike", "F")
  eq(env:slotText(6), "spell:Mongoose Bite", "G")
  eq(env:slotText(7), "spell:Wing Clip", "C")
  eq(env:slotText(8), "spell:Concussive Shot", "V")
  eq(env:slotText(9), "spell:Hunter's Mark", "1")
  eq(env:slotText(10), "spell:Multi-Shot", "2")
  eq(env:slotText(11), "spell:Explosive Trap", "3")
  eq(env:slotText(12), "spell:Volley", "4")
  eq(env:slotText(64), "spell:Intimidation", "Shift+T")
  eq(env:slotText(70), "spell:Aspect of the Monkey", "Shift+2")
  local function Pad(key) return env:slotText(env:padSlot(1, key)) end
  eq(Pad("RT A"), "spell:Arcane Shot", "RT A")
  eq(Pad("RT X"), "spell:Serpent Sting", "RT X")
  eq(Pad("RT Y"), "spell:Aimed Shot", "RT Y")
  eq(Pad("RT B"), "spell:Raptor Strike", "RT B")
  eq(Pad("LT A"), "spell:Summon Hawk", "LT A")
  eq(Pad("LT X"), "spell:Mongoose Bite", "LT X")
  eq(Pad("LT B"), "spell:Explosive Trap", "LT B")
  eq(Pad("LT Y"), "spell:Multi-Shot", "LT Y")
  eq(Pad("LT Left"), "spell:Intimidation", "LT Left")
  eq(Pad("RT Up"), "spell:Hunter's Mark", "RT Up")
  eq(Pad("RT Down"), "spell:Volley", "RT Down")
  eq(Pad("RT Left"), "spell:Wing Clip", "RT Left")
  eq(Pad("RT Right"), "spell:Concussive Shot", "RT Right")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("hunter: a level 10 hunter has its rotation on Q E F and the opener on 1", function()
  local keep = { ["Auto Shot"] = true, ["Arcane Shot"] = true, ["Serpent Sting"] = true, ["Raptor Strike"] = true,
    ["Hunter's Mark"] = true, ["Concussive Shot"] = true, ["Track Beasts"] = true }
  local env = Boot({ level = 10, setup = function(W)
    local spells = {}
    for _, s in ipairs(W.fixture.spells) do if keep[s.name] then spells[#spells + 1] = s end end
    W.fixture.spells = spells
  end })
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Arcane Shot", "Q")
  eq(env:slotText(2), "spell:Serpent Sting", "E")
  eq(env:slotText(5), "spell:Raptor Strike", "F")
  eq(env:slotText(8), "spell:Concussive Shot", "V")
  eq(env:slotText(9), "spell:Hunter's Mark", "1")
end)

test("hunter: Marksmanship gets Sniper Shot on T, Scatter Shot on Shift+T and Trueshot Aura on Shift+E", function()
  local env = Boot({ talents = T3(5, 31, 15) }, { "Sniper Shot", "Trueshot Aura", "Scatter Shot" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(4), "spell:Sniper Shot", "T")
  eq(env:slotText(3), "spell:Aimed Shot", "R")
  eq(env:slotText(11), "spell:Explosive Trap", "3")
  eq(env:slotText(64), "spell:Scatter Shot", "Shift+T")
  eq(env:slotText(62), "spell:Trueshot Aura", "Shift+E")
  eq(env:slotText(29), "spell:Scare Beast", "Ctrl+F")
  eq(env:slotText(env:padSlot(1, "LT A")), "spell:Sniper Shot", "controller LT A")
  eq(env:slotText(env:padSlot(1, "LT Left")), "spell:Scatter Shot", "controller LT Left")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("hunter: Survival gets Strider Kick on R, Immolation Trap on 3, Deterrence, Counterattack and Beast", function()
  local env = Boot({ talents = T3(0, 20, 31) }, { "Strider Kick", "Deterrence", "Counterattack", "Aspect of the Beast" })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Arcane Shot", "Q")
  eq(env:slotText(3), "spell:Strider Kick", "R")
  eq(env:slotText(5), "spell:Raptor Strike", "F")
  eq(env:slotText(11), "spell:Immolation Trap", "3")
  eq(env:slotText(12), "spell:Volley", "4")
  eq(env:slotText(62), "spell:Deterrence", "Shift+E")
  eq(env:slotText(64), "spell:Counterattack", "Shift+T")
  eq(env:slotText(66), "spell:Concussive Shot", "Shift+G")
  eq(env:slotText(8), "spell:Explosive Trap", "V")
  eq(env:slotText(70), "spell:Aspect of the Beast", "Shift+2")
  eq(env:slotText(28), "spell:Disengage", "Ctrl+T")
  eq(env:slotText(29), "spell:Frost Trap", "Ctrl+F")
  eq(env:slotText(30), "spell:Aimed Shot", "Ctrl+G")
  eq(env:slotText(33), "spell:Aspect of the Monkey", "Ctrl+1")
  local function Pad(key) return env:slotText(env:padSlot(1, key)) end
  eq(Pad("RT Y"), "spell:Strider Kick", "controller RT Y")
  eq(Pad("RT B"), "spell:Raptor Strike", "controller RT B")
  eq(Pad("LT B"), "spell:Immolation Trap", "controller LT B")
  eq(Pad("LT Left"), "spell:Counterattack", "controller LT Left")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("hunter: recommended macros name real spec keys, and every spec has some", function()
  local env = H.boot({ fixture = "hunter" })
  local keys, per = {}, {}
  for _, spec in ipairs(env.ns.Layout.Specs("HUNTER")) do keys[spec.key] = true; per[spec.key] = 0 end
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "HUNTER" and m.specs then
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
