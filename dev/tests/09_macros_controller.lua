-- Fixes from review 10 for the macro library, Controller and the dev kit:
-- account/character macro tabs, retired macros, secret aura fields, the
-- Controller Undo backup, and the page-1-only back-button mirror rule.
local H = require("harness")

local function LibMacro(env, name)
  for _, m in ipairs(env.ns.MacroLibrary.macros) do if m.name == name then return m end end
  error("no library macro " .. name)
end

-- Macro tabs (harness) -------------------------------------------------------------

test("an installed character macro sits at 121+ and reads as installed", function()
  local env = H.boot({ macros = { "Arcane" } })
  local L = env.ns.MacroLibrary
  local m = LibMacro(env, "Arcane")
  ok(m.perCharacter, "Arcane is a character macro")
  local i = env.G.GetMacroIndexByName("Arcane")
  ok(i > 120, "character macros start at 121: " .. i)
  local acct, char = env.G.GetNumMacros()
  eq(acct, 0, "account macros"); eq(char, 1, "character macros")
  eq((L.State(m)), "installed", "state")
  env:resetCalls()
  L.Install({ m })
  eq(#env:calls("CreateMacro"), 0, "a second Install creates nothing")
  eq(#env:calls("DeleteMacro"), 0, "and deletes nothing")
  noErrors(env)
end)

test("macro indices follow name order, and action slots follow their macro", function()
  local env = H.boot({ setup = function(W)
    W.macros[1] = { name = "Zeta", icon = "x", body = "/say z", perChar = false }
    W.macros[2] = { name = "Beta", icon = "x", body = "/say b", perChar = false }
  end })
  local G = env.G
  eq(G.GetMacroIndexByName("Beta"), 1, "Beta first"); eq(G.GetMacroIndexByName("Zeta"), 2, "Zeta second")
  env.W.actions[1] = { type = "macro", id = 2 }   -- Zeta
  env.W.actions[2] = { type = "macro", id = 1 }   -- Beta
  G.CreateMacro("Alpha", "x", "/say a")
  eq(G.GetActionText(1), "Zeta", "slot 1 still holds Zeta after Alpha sorts in front")
  G.DeleteMacro("Beta")
  eq(env.W.actions[2], nil, "the slot that held Beta is empty")
  eq(G.GetActionText(1), "Zeta", "slot 1 still holds Zeta")
end)

test("a full Character tab refuses CreateMacro and Install says so", function()
  local env = H.boot({ setup = function(W)
    for i = 1, 18 do W.macros[i] = { name = "Mine" .. i, icon = "x", body = "/say " .. i, perChar = true } end
  end })
  eq(env.G.CreateMacro("Extra", "x", "/say x", true), nil, "the 19th character macro is refused")
  env:resetCalls()
  env.ns.MacroLibrary.Install({ LibMacro(env, "Arcane") })
  eq(#env:calls("CreateMacro"), 0, "Install doesn't try")
  ok(env:chatText():find("Character macros full", 1, true), "says the tab is full:\n" .. env:chatText())
end)

test("a character macro in the General tab moves: new copy first, then the old one goes", function()
  local env = H.boot()
  local L = env.ns.MacroLibrary
  local m = LibMacro(env, "Arcane")
  local body = assert(L.Resolve(m))
  env.W.macros[1] = { name = "Arcane", icon = "x", body = body, perChar = false }
  eq((L.State(m)), "update", "a character macro in the General tab shows Update")
  L.Install({ m })
  noErrors(env)
  local i = env.G.GetMacroIndexByName("Arcane")
  ok(i > 120, "now in the Character tab: " .. i)
  local acct = env.G.GetNumMacros()
  eq(acct, 0, "the General copy is gone")
end)

-- Library: older texts and retired macros ------------------------------------------

test("every older library text of a live macro reads as Update, not Name in use", function()
  local env = H.boot()
  local L = env.ns.MacroLibrary
  local checked = 0
  for name, bodies in pairs(L.previous) do
    local m = LibMacro(env, name)
    for _, old in ipairs(bodies) do
      env.W.macros = { { name = name, icon = "x", body = old, perChar = m.perCharacter and true or false } }
      local state = L.State(m)
      ok(state == "update" or state == "installed", name .. ": an older text reads as " .. tostring(state))
      checked = checked + 1
    end
  end
  ok(checked > 0, "L.previous has entries")
end)

test("RetiredDeletable: exact retired texts yes; common texts and shapes only when Agentcraft wrote them", function()
  local env = H.boot()
  local L = env.ns.MacroLibrary
  ok(L.RetiredDeletable("Pull", L.retired.Pull), "Pull's retired text")
  ok(not L.RetiredDeletable("Pull", L.retired.Pull .. "\n/say mine"), "Pull with a line of yours")
  ok(not L.RetiredDeletable("Logout", L.retired.Logout), "a /camp Logout you may have written yourself")
  ok(not L.RetiredDeletable("Feed", "#showtooltip\n/cast Feed Pet\n/use Tough Jerky"), "your own Feed")
  ok(not L.RetiredDeletable("Melee", L.retired.Melee or ""), "a name the library still offers")
  env.G.AgentcraftDB.macroBodies = nil
  env.G.AgentcraftDB.macroWritten = { Feed = { ["#showtooltip\n/cast Feed Pet\n/use Tough Jerky"] = true },
    Logout = { [L.retired.Logout] = true } }
  ok(L.RetiredDeletable("Feed", "#showtooltip\n/cast Feed Pet\n/use Tough Jerky"), "a Feed Agentcraft wrote")
  ok(L.RetiredDeletable("Logout", L.retired.Logout), "a Logout Agentcraft wrote")
end)

test("Controller Apply keeps your own Feed and Logout but deletes a retired /petattack macro", function()
  local env = H.boot({ setup = function(W)
    W.macros[1] = { name = "Feed", icon = "x", body = "#showtooltip\n/cast Feed Pet\n/use Tough Jerky", perChar = false }
    W.macros[2] = { name = "Logout", icon = "x", body = "/camp", perChar = false }
    W.macros[3] = { name = "Pull", icon = "x",
      body = "#showtooltip Serpent Sting\n/petattack [@target,harm,nodead]\n/cast [@target,harm,nodead] Serpent Sting", perChar = true }
  end })
  env:slash("controller apply")
  noErrors(env)
  ok(env.G.GetMacroIndexByName("Feed") > 0, "your Feed is kept")
  ok(env.G.GetMacroIndexByName("Logout") > 0, "your Logout is kept")
  eq(env.G.GetMacroIndexByName("Pull"), 0, "the retired Pull (with /petattack) is deleted")
end)

-- Snapshot: secret aura fields --------------------------------------------------

test("a save while aura fields are secret keeps the last readable buff list", function()
  local env = H.boot()
  local mod = env.ns.modules.snapshot
  mod:Save()
  env.W.secret = "fields"
  mod:Save()
  noErrors(env)
  local snap = mod.db["Tester-Mockrealm"]
  ok(type(snap.buffs) == "table", "buffs saved")
  for i, v in ipairs(snap.buffs) do
    ok(type(v) == "string", "buff " .. i .. " is text, not a secret (" .. type(v) .. ")")
  end
  eq(snap.buffs[1], "Aspect of the Hawk", "the readable list is kept")
end)

-- Controller ------------------------------------------------------------------------

test("Controller: the mock's storage slots match the game (28 per page, fixed face buttons have none)", function()
  local env = H.boot()
  local U = env.G.GamepadActionBarBindingUtil
  eq(U.GetGamepadStorageSlotIndexFromPageAndPageUnitSlotID(1, 2), env:padSlot(1, "none Up"))
  eq(U.GetGamepadStorageSlotIndexFromPageAndPageUnitSlotID(2, 2), env:padSlot(2, "none Up"))
  eq(U.GetGamepadStorageSlotIndexFromPageAndPageUnitSlotID(3, 32), env:padSlot(3, "LT+RT A"))
  eq(U.GetGamepadStorageSlotIndexFromPageAndPageUnitSlotID(1, 5), nil, "Top X is fixed")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(env:padSlot(1, "RT A")), "spell:Arcane Shot", "RT A (slot 200) holds Arcane Shot")
end)

test("Controller Undo keeps an older backup it can't restore without the Gamepad UI", function()
  local env = H.boot()
  local mod = env.ns.modules.controller
  env:slash("controller apply")
  local backup = mod.charDB.backup
  ok(backup and backup.managed and #backup.managed > 0, "Apply saves the managed slot list")
  env.W.gamepad = false
  env:slash("controller undo")
  noErrors(env)
  eq(mod.charDB.backup, nil, "a backup with its slot list undoes without the Gamepad UI")
  env.W.gamepad = true
  env:slash("controller apply")
  mod.charDB.backup.managed = nil   -- as saved before 0.26
  env.W.gamepad = false
  env:slash("controller undo")
  noErrors(env)
  ok(mod.charDB.backup ~= nil, "the older backup is kept")
  ok(env:chatText():find("nothing was changed", 1, true), "Undo says why:\n" .. env:chatText())
end)

test("Controller without the Gamepad UI counts only real missing spells", function()
  local off = H.boot({ setup = function(W) W.gamepad = false end })
  local on = H.boot()
  local a, b = off.ns.modules.controller.Plan(), on.ns.modules.controller.Plan()
  ok(a.missing <= b.missing, "no extra missing without the util: " .. a.missing .. " vs " .. b.missing)
end)

-- Rules (dev kit) -----------------------------------------------------------------

local function Problems(Layout, opts)
  local errors, infos = {}, {}
  for _, p in ipairs(H.rules.CheckLayout(Layout, "HUNTER", opts)) do
    if p.severity == "error" then errors[#errors + 1] = p.msg else infos[#infos + 1] = p.msg end
  end
  return errors, infos
end

test("rules: back buttons may mirror page-1 spells only; macros and radials are homes", function()
  local base = function(paddles)
    return { controller = { HUNTER = {
      pages = { { ["RT A"] = { "Arcane Shot" }, ["none Up"] = { flyout = 253, "Aspect of the Hawk" } },
        { ["RT A"] = { "Revive Pet" }, ["RT B"] = { macro = "Skull" } } },
      paddles = paddles } } }
  end
  local errors, infos = Problems(base({ R5 = { "Arcane Shot" } }))
  eq(#errors, 0, "page-1 mirror: " .. table.concat(errors, "; "))
  eq(#infos, 1, "page-1 mirror is a note")
  errors = Problems(base({ R5 = { "Revive Pet" } }))
  eq(#errors, 1, "a page-2 spell on a back button is a second home")
  local two = base({})
  two.controller.HUNTER.pages[2]["LT A"] = { macro = "Skull" }
  errors = Problems(two)
  eq(#errors, 1, "the same macro twice: " .. table.concat(errors, "; "))
  local radial = base({})
  radial.controller.HUNTER.pages[2]["LT A"] = { "Aspect of the Cheetah" }
  errors = Problems(radial, { flyout = function(id) if id == 253 then return { "Aspect of the Hawk", "Aspect of the Cheetah" } end end })
  eq(#errors, 1, "a spell inside a radial and on its own button: " .. table.concat(errors, "; "))
  local key = base({})
  key.controller.HUNTER.pages[1]["none A"] = { "Wing Clip" }
  errors = Problems(key)
  eq(#errors, 1, "the Top bar's face buttons are fixed")
end)

test("rules: /cast and #showtooltip of an item are errors", function()
  local items = { Hearthstone = true }
  local function Errors(body)
    local n = 0
    for _, p in ipairs(H.rules.CheckMacro({ name = "T" }, body, items)) do if p.severity == "error" then n = n + 1 end end
    return n
  end
  eq(Errors("#showtooltip\n/cast Hearthstone"), 1, "/cast of an item")
  eq(Errors("#showtooltip Hearthstone\n/cast Arcane Shot"), 1, "#showtooltip of an item")
  eq(Errors("#showtooltip\n/castsequence reset=5 Arcane Shot, Hearthstone"), 1, "/castsequence with an item")
  eq(Errors("#showtooltip\n/cast Arcane Shot"), 0, "a plain spell")
end)
