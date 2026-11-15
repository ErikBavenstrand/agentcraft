-- Action Bars and Key Bindings fixes from review 10: the page plan agrees
-- with Apply, side bars 6-8, Undo reporting what it couldn't put back, and
-- the old account keybind backup.
local H = require("harness")

local function Info(env, _label)
  local p = env.ns.modules.actionbars.Plan()
  return p
end

test("bars: plan agrees with apply (0 changes after apply), kept slot not counted", function()
  local env = H.boot({ pet = true })
  env.W.actions[25] = { type = "companion", id = 7 }
  env.W.actions[5] = { type = "spell", id = 999999 } -- something in a keyed slot
  Info(env, "before")
  env:slash("spells apply")
  noErrors(env)
  local p = Info(env, "after")
  eq(p.changes, 0, "no changes after apply")
  eq(env.W.actions[25] and env.W.actions[25].type, "companion", "kept slot untouched")
  eq(p[4][1].state, "kept")
end)

test("bars: overflow goes to Action Bar 6 when the bar exists, never drops class spells", function()
  local env = H.boot({ pet = true, setup = function(W) for i = 1, 20 do table.insert(W.fixture.spells, { name = "Fake Spell " .. i, id = 900000 + i }) end end, loaded = function(e) e.G.CreateFrame("Frame", "MultiBar5"); e.G.CreateFrame("Frame", "MultiBar6") end })
  Info(env, "with bars 6-7")
  env:slash("spells apply")
  noErrors(env)
  local p = Info(env, "after")
  eq(p.changes, 0, "no changes after apply")
  eq(#p.dropped, 0, "nothing dropped")
  env:resetCalls()
  env:slash("spells undo")
  noErrors(env)
  for s = 145, 180 do ok(env.W.actions[s] == nil, "slot " .. s .. " restored to empty") end
end)

test("bars: undo reports a macro it can't put back", function()
  local env = H.boot({ macros = { "Arcane" } })
  local i = env.G.GetMacroIndexByName("Arcane")
  env.W.actions[61] = { type = "macro", id = i }
  env:slash("spells apply")
  env.G.DeleteMacro("Arcane")
  env:resetCalls()
  env:slash("spells undo")
  noErrors(env)
  ok(env:chatText():find("couldn't put back: Arcane", 1, true), env:chatText())
end)

test("keys: undo never rebinds a key to a macro that's gone", function()
  local env = H.boot({ bindings = { Z = "MACRO Gone", Q = "MOVEFORWARD" } })
  env:slash("keys apply")
  env:resetCalls()
  env:slash("keys undo")
  noErrors(env)
  eq(env.W.bindings.Z, nil, "Z left unbound")
  eq(env.W.bindings.Q, "MOVEFORWARD", "Q restored")
  ok(env:chatText():find("Z (macro Gone)", 1, true), env:chatText())
end)

test("keys: a character on its own binds finds the pre-0.26 account backup", function()
  local env = H.boot({
    db = { modules = { Keybinds = { backup = { commands = {}, keys = { Q = "MOVEFORWARD" } } } } },
    loaded = function(e) e.G.CHARACTER_BINDINGS = 2; e.G.GetCurrentBindingSet = function() return 2 end end,
  })
  env:slash("keys apply")
  env:slash("keys undo")
  noErrors(env)
  eq(env.W.bindings.Q, "MOVEFORWARD", "Q restored from the old account backup")
  ok(env.G.AgentcraftDB.modules.Keybinds.backup ~= nil, "account backup kept (copied, not moved)")
end)

test("keyboard page (old id keys): status, replaces, pin", function()
  local env = H.boot({ bindings = { Q = "MOVEFORWARD" } })
  env.ns.OpenPage("keys")
  noErrors(env)
  local page = env.ns.PageById("keys")
  eq(page.id, "keyboard", "keys is an alias of the Keyboard page")
  ok(not tostring(page.Status(page)):find("Up to date", 1, true), "Q bound elsewhere: something to apply")
  ok(page.caps.Q.cell.bindState == "replaces", "Q replaces your bind")
  local E = page.caps.E
  E:Click()
  eq(env.ns.Focus.pinned, E, "A / click pins the key")
  E:Click()
  eq(env.ns.Focus.pinned, nil, "again unpins")
  env:slash("spells apply")
  env:slash("keys apply")
  env.ns.OpenPage("keys")
  ok(tostring(page.Status(page)):find("Up to date", 1, true), "up to date after both applies: " .. tostring(page.Status(page)))
end)

test("bars: without bars 6-8, professions and tracking give up their slot before class spells", function()
  local env = H.boot({ pet = true, setup = function(W) for i = 1, 20 do table.insert(W.fixture.spells, { name = "Fake Spell " .. i, id = 900000 + i }) end end })
  local p = Info(env, "no extra bars")
  env:slash("spells apply")
  noErrors(env)
  for _, n in ipairs(p.dropped) do ok(not n:find("Fake Spell"), "class spell dropped: " .. n) end
  eq(Info(env, "after").changes, 0)
end)
