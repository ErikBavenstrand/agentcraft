-- Druid layouts: Feral and Balance share the keyboard (caster, Cat, Bear and
-- Moonkin pages, each putting its own rotation on the rotation slots of
-- dev/key-roles.md), Restoration follows the healer rule and drops the
-- Moonkin page; Apply fills Bar 1, the form pages (cat 73-84, bear 97-108,
-- moonkin 109-120) and the controller (Feral: Cat on the RT face, Bear on
-- the LT face, plain spells), the plan agrees afterwards, and nothing
-- creates a macro.
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

test("druid: Feral Apply puts each form's rotation on the rotation slots; no macro is created", function()
  local env = Boot({ talents = FERAL })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  -- Caster page: Q E R rotation 1-3, T Roots, V Faerie Fire (V in every form), 2 AoE.
  eq(env:slotText(1), "spell:Wrath", "caster Q")
  eq(env:slotText(2), "spell:Moonfire", "caster E")
  eq(env:slotText(3), "spell:Starfire", "caster R")
  eq(env:slotText(4), "spell:Entangling Roots", "caster T: leveling control")
  eq(env:slotText(8), "spell:Faerie Fire", "caster V: debuff on the boss")
  eq(env:slotText(10), "spell:Hurricane", "caster 2: main AoE")
  -- Cat page (slot 72 + key).
  eq(env:slotText(73), "spell:Claw", "Cat Q: builder")
  eq(env:slotText(74), "spell:Rake", "Cat E: bleed")
  eq(env:slotText(75), "spell:Rip", "Cat R: finisher kept up (Wowhead)")
  eq(env:slotText(76), "spell:Ferocious Bite", "Cat T: execute finisher")
  eq(env:slotText(80), "spell:Faerie Fire", "Cat V: Faerie Fire (no Faerie Fire (Feral) on Forever)")
  eq(env:slotText(5), nil, "caster F: Insect Swarm is a Balance talent, Feral lacks it")
  eq(env:slotText(6), "spell:Nature's Grasp", "caster G: Nature's Grasp is a trainer spell")
  eq(env:slotText(77), "spell:Shred", "Cat F: builder from behind")
  eq(env:slotText(79), "spell:Dash", "Cat C: mobility")
  eq(env:slotText(81), "spell:Prowl", "Cat 1 (CatOpener not installed)")
  eq(env:slotText(82), "spell:Ravage", "Cat 2: Ravage from Prowl")
  eq(env:slotText(83), "spell:Pounce", "Cat 3: stun")
  -- Bear page (slot 96 + key): the whole tank kit on plain keys.
  eq(env:slotText(97), "spell:Maul", "Bear Q")
  eq(env:slotText(100), "spell:Demoralizing Roar", "Bear T")
  eq(env:slotText(101), "spell:Growl", "Bear F: taunt")
  eq(env:slotText(102), "spell:Frenzied Regeneration", "Bear G: mitigation")
  eq(env:slotText(105), "spell:Enrage", "Bear 1: opener")
  eq(env:slotText(106), "spell:Swipe", "Bear 2: AoE threat")
  eq(env:slotText(107), "spell:Bash", "Bear 3: interrupt")
  eq(env:slotText(108), "spell:Challenging Roar", "Bear 4: AoE taunt")
  eq(env:slotText(109), "spell:Wrath", "Moonkin Q (slot 108 + 1)")
  -- Shift and Ctrl.
  eq(env:slotText(61), "spell:Regrowth", "Shift+Q self-heal (Regrow not installed)")
  eq(env:slotText(62), "spell:Barkskin", "Shift+E defensive")
  eq(env:slotText(63), "spell:Innervate", "Shift+R cooldown")
  eq(env:slotText(64), "spell:Rejuvenation", "Shift+T HoT top-off")
  eq(env:slotText(67), "spell:War Stomp", "Shift+C racial")
  eq(env:slotText(68), "spell:Healing Touch", "Shift+V emergency heal")
  eq(env:slotText(69), "spell:Dire Bear Form", "Shift+1: Dire Bear replaces Bear")
  eq(env:slotText(72), "spell:Aquatic Form", "Shift+4: no Moonkin Form, so Aquatic")
  eq(env:slotText(26), "spell:Cower", "Ctrl+E")
  eq(env:slotText(31), "spell:Remove Curse", "Ctrl+C")
  -- Controller page 1: the Cat rotation on the RT face, the Bear kit on the
  -- LT face, plain spells (no macro needed). The fixture has not learned the
  -- Feral talents (Primal Bite, Lacerate, Shifting Power): the next test does.
  eq(env:slotText(Pad(1, "RT A")), "spell:Claw", "RT A: Cat rotation 1")
  eq(env:slotText(Pad(1, "RT X")), "spell:Rake", "RT X: Cat rotation 2")
  eq(env:slotText(Pad(1, "RT Y")), "spell:Rip", "RT Y: Cat rotation 3")
  eq(env:slotText(Pad(1, "RT B")), "spell:Shred", "RT B: Cat rotation 4")
  eq(env:slotText(Pad(1, "LT A")), "spell:Maul", "LT A: Bear attack / rage dump")
  eq(env:slotText(Pad(1, "LT Y")), "spell:Swipe", "LT Y: main AoE threat")
  eq(env:slotText(Pad(1, "LT+RT A")), "spell:Growl", "LT+RT A: taunt")
  eq(env:slotText(Pad(1, "LT+RT Y")), "spell:Ferocious Bite", "LT+RT Y: execute")
  eq(env:slotText(Pad(1, "RT Up")), "spell:Prowl", "RT Up: opener (CatOpener not installed)")
  eq(env:slotText(Pad(1, "RT Down")), "spell:Demoralizing Roar", "RT Down: debuff kept up")
  eq(env:slotText(Pad(1, "RT Left")), "spell:Dash", "RT Left: mobility")
  eq(env:slotText(Pad(1, "RT Right")), "spell:Faerie Fire", "RT Right: pull in both forms")
  eq(env:slotText(Pad(1, "LT Left")), "spell:Frenzied Regeneration", "LT Left: sustain")
  eq(env:slotText(Pad(1, "LT Down")), "spell:Bash", "LT Down: stun")
  eq(env:slotText(Pad(1, "LT Right")), "spell:Barkskin", "LT Right: Shift+E")
  eq(env:slotText(Pad(1, "LT+RT Up")), "spell:Healing Touch", "LT+RT Up: emergency heal")
  eq(env:slotText(Pad(1, "LT+RT Down")), "spell:Challenging Roar", "LT+RT Down: AoE taunt")
  eq(env:slotText(Pad(1, "LT+RT Left")), "spell:Enrage", "LT+RT Left: rage before the pull")
  eq(env:slotText(Pad(1, "none Up")), "spell:Cat Form", "none Up")
  eq(env:slotText(Pad(1, "none Down")), "spell:Rejuvenation", "none Down: top-off between pulls")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("druid: a level 60 Feral tanks from the pad with no macro installed", function()
  local env = Boot({ talents = FERAL, setup = function(W)
    local s = W.fixture.spells
    s[#s + 1] = { name = "Primal Bite", id = 900121 }
    s[#s + 1] = { name = "Lacerate", id = 33745 }
    s[#s + 1] = { name = "Shifting Power", id = 900122 }
  end })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(98), "spell:Lacerate", "Bear E")
  eq(env:slotText(99), "spell:Primal Bite", "Bear R")
  eq(env:slotText(78), "spell:Shifting Power", "Cat G")
  eq(env:slotText(Pad(1, "LT A")), "spell:Maul", "LT A: Maul")
  eq(env:slotText(Pad(1, "LT X")), "spell:Primal Bite", "LT X: Primal Bite on cooldown")
  eq(env:slotText(Pad(1, "LT B")), "spell:Lacerate", "LT B: Lacerate")
  eq(env:slotText(Pad(1, "LT Y")), "spell:Swipe", "LT Y: Swipe")
  eq(env:slotText(Pad(1, "LT+RT A")), "spell:Growl", "LT+RT A: Growl")
  eq(env:slotText(Pad(1, "LT+RT X")), "spell:Shifting Power", "LT+RT X: Shifting Power")
  eq(env:slotText(Pad(1, "RT A")), "spell:Claw", "Cat still on RT A")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("druid: before Cat Form the RT face holds Wrath and Moonfire, the LT face the bear", function()
  local env = Boot({ level = 14, setup = function(W)
    local keep = { Wrath = true, Moonfire = true, ["Healing Touch"] = true, Rejuvenation = true, Thorns = true,
      ["Entangling Roots"] = true, ["Bear Form"] = true, Maul = true, Growl = true, ["Demoralizing Roar"] = true,
      Enrage = true, ["Mark of the Wild"] = true, Regrowth = true, Bash = true }
    local s = {}
    for _, sp in ipairs(W.fixture.spells) do if keep[sp.name] then s[#s + 1] = sp end end
    W.fixture.spells = s
  end })
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(Pad(1, "RT A")), "spell:Wrath", "RT A: Wrath until Claw")
  eq(env:slotText(Pad(1, "RT X")), "spell:Moonfire", "RT X: Moonfire until Rake")
  eq(env:slotText(Pad(1, "LT A")), "spell:Maul", "LT A: Maul")
  eq(env:slotText(Pad(1, "LT+RT A")), "spell:Growl", "LT+RT A: Growl")
  eq(env:slotText(Pad(1, "RT Down")), "spell:Demoralizing Roar", "RT Down")
end)

test("druid: Restoration heals from the plain keys and the face buttons; no Moonkin page", function()
  local env = Boot({ talents = RESTO })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Rejuvenation", "Q most-cast heal")
  eq(env:slotText(2), "spell:Regrowth", "E spike heal")
  eq(env:slotText(3), "spell:Healing Touch", "R big heal")
  eq(env:slotText(4), "spell:Remove Curse", "T dispel")
  eq(env:slotText(8), "spell:Entangling Roots", "V root")
  eq(env:slotText(11), "spell:Abolish Poison", "3 second dispel")
  eq(env:slotText(12), "spell:Tranquility", "4 group emergency")
  eq(env:slotText(61), "spell:Wrath", "Shift+Q damage")
  eq(env:slotText(64), nil, "Shift+T: Insect Swarm is a Balance talent, Resto lacks it")
  eq(env:slotText(25), "spell:Nature's Grasp", "Ctrl+Q cooldown (trainer spell)")
  eq(env:slotText(66), "spell:Innervate", "Shift+G mana")
  eq(env:slotText(68), "spell:Barkskin", "Shift+V emergency")
  eq(env:slotText(73), "spell:Claw", "Cat page shared")
  eq(env:slotText(80), "spell:Faerie Fire", "Faerie Fire's home: V in forms")
  eq(env:slotText(109), nil, "no Moonkin page")
  eq(env:slotText(Pad(1, "RT A")), "spell:Rejuvenation", "RT A: most-cast heal")
  eq(env:slotText(Pad(1, "RT X")), "spell:Regrowth", "RT X: spike heal")
  eq(env:slotText(Pad(1, "RT Y")), "spell:Healing Touch", "RT Y: big heal")
  eq(env:slotText(Pad(1, "LT A")), "spell:Remove Curse", "LT A: dispel")
  eq(env:slotText(Pad(1, "LT B")), "spell:Abolish Poison", "LT B: second dispel")
  eq(env:slotText(Pad(1, "RT Down")), "spell:Tranquility", "RT Down: group emergency")
  eq(env:slotText(Pad(1, "LT Up")), "spell:Wrath", "LT Up: Shift+Q damage")
  eq(env:slotText(Pad(1, "LT+RT X")), "spell:Innervate", "LT+RT X: Shift+G")
  eq(env:slotText(Pad(3, "RT X")), "spell:Soothe Animal", "page 3 RT X")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("druid: Balance keeps the shared keyboard; controller rotation with caster spells", function()
  local env = Boot({ talents = BALANCE })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(3), "spell:Starfire", "R")
  eq(env:slotText(Pad(1, "RT A")), "spell:Wrath", "RT A: rotation 1")
  eq(env:slotText(Pad(1, "RT X")), "spell:Moonfire", "RT X: rotation 2")
  eq(env:slotText(Pad(1, "RT Y")), "spell:Starfire", "RT Y: rotation 3")
  eq(env:slotText(Pad(1, "LT A")), "spell:Entangling Roots", "LT A: rotation 5")
  eq(env:slotText(Pad(1, "LT Y")), "spell:Hurricane", "LT Y: main AoE")
  eq(env:slotText(Pad(1, "RT Right")), "spell:Faerie Fire", "RT Right: debuff before the pull")
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("druid: installed macros take their homes", function()
  local env = Boot({ talents = FERAL, macros = { "Regrow", "Rejuv", "HTouch", "CatOpener" } })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(61), "macro:Regrow", "Shift+Q")
  eq(env:slotText(64), "macro:Rejuv", "Shift+T")
  eq(env:slotText(68), "macro:HTouch", "Shift+V")
  eq(env:slotText(81), "macro:CatOpener", "Cat 1")
  eq(env:slotText(Pad(1, "RT Up")), "macro:CatOpener", "RT Up")
  eq(env:slotText(Pad(1, "LT Up")), "macro:Regrow", "LT Up")
  eq(env:slotText(Pad(1, "none Down")), "macro:Rejuv", "none Down")
  local resto = Boot({ talents = RESTO, macros = { "Rejuv", "HTouch" } })
  resto:slash("spells apply")
  eq(resto:slotText(1), "macro:Rejuv", "Restoration Q")
  eq(resto:slotText(3), "macro:HTouch", "Restoration R")
end)

test("druid: Wowhead's recommended macros take their homes; plain spells without them", function()
  local feral = Boot({ talents = FERAL, macros = { "CatDash", "BearCharge", "Innerv" },
    setup = function(W) table.insert(W.fixture.spells, { name = "Feral Charge", id = 16979 }) end })
  feral:slash("spells apply")
  feral:slash("controller apply")
  noErrors(feral)
  eq(feral:slotText(79), "macro:CatDash", "Cat C")
  eq(feral:slotText(103), "macro:BearCharge", "Bear C")
  eq(feral:slotText(63), "macro:Innerv", "Shift+R")
  eq(feral:slotText(Pad(1, "RT Left")), "macro:CatDash", "RT Left")
  eq(feral:slotText(Pad(1, "LT+RT Right")), "macro:Innerv", "LT+RT Right")
  eq(#feral:calls("CreateMacro"), 0)
  local plain = Boot({ talents = FERAL })
  plain:slash("spells apply")
  eq(plain:slotText(79), "spell:Dash", "Cat C without CatDash")
  local resto = Boot({ talents = RESTO, macros = { "NSTouch", "RemoveCurse", "Innerv" },
    setup = function(W) table.insert(W.fixture.spells, { name = "Nature's Swiftness", id = 17116 }) end })
  resto:slash("spells apply")
  resto:slash("controller apply")
  noErrors(resto)
  eq(resto:slotText(6), "macro:NSTouch", "Restoration G")
  eq(resto:slotText(4), "macro:RemoveCurse", "Restoration T")
  eq(resto:slotText(66), "macro:Innerv", "Restoration Shift+G")
  eq(resto:slotText(Pad(1, "LT X")), "macro:NSTouch", "Restoration LT X")
  eq(resto:slotText(Pad(1, "LT A")), "macro:RemoveCurse", "Restoration LT A")
  eq(resto:slotText(Pad(1, "LT+RT X")), "macro:Innerv", "Restoration LT+RT X")
  eq(#resto:calls("CreateMacro"), 0)
end)

test("druid: macros pass the rules", function()
  local env = Boot()
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "DRUID" then
      ok(m.perCharacter and m.untested, m.name .. " perCharacter and untested")
      for _, p in ipairs(H.rules.CheckMacro(m)) do
        ok(p.severity ~= "error" and p.severity ~= "warn", m.name .. ": " .. p.msg)
      end
    end
  end
end)

test("druid: recommended macros name valid spec keys and carry the recommended tag", function()
  local env = Boot()
  local valid = {}
  for _, spec in ipairs(env.ns.Layout.Specs("DRUID")) do valid[spec.key] = true end
  local perSpec = {}
  for _, m in ipairs(env.ns.MacroLibrary.macros) do
    if m.class == "DRUID" and m.specs then
      ok(#m.specs > 0, m.name .. " has spec keys")
      for _, k in ipairs(m.specs) do
        ok(valid[k], m.name .. ": '" .. tostring(k) .. "' is a DRUID spec key")
        perSpec[k] = (perSpec[k] or 0) + 1
      end
      local tagged = false
      for _, t in ipairs(m.tags or {}) do if t == "recommended" then tagged = true end end
      ok(tagged, m.name .. " has the recommended tag")
    end
  end
  for k in pairs(valid) do ok((perSpec[k] or 0) >= 2, k .. " has recommended macros") end
end)
