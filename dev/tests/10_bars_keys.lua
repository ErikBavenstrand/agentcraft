-- Action Bars and Key Bindings fixes from review 10: the page plan agrees
-- with Apply, the Ctrl layer (Action Bar 4), side bars 5-8, Undo reporting what it couldn't put back, and
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

test("bars: overflow goes to Action Bars 6-7 when they exist, never drops class spells", function()
  local env = H.boot({ pet = true, setup = function(W) for i = 1, 17 do table.insert(W.fixture.spells, { name = "Fake Spell " .. i, id = 900000 + i }) end end, loaded = function(e) e.G.CreateFrame("Frame", "MultiBar5"); e.G.CreateFrame("Frame", "MultiBar6") end })
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

test("bars: without bars 6-8, everything shares Action Bar 5; professions and tracking give up their slot before class spells", function()
  local env = H.boot({ pet = true, setup = function(W) for i = 1, 6 do table.insert(W.fixture.spells, { name = "Fake Spell " .. i, id = 900000 + i }) end end })
  local p = Info(env, "no extra bars")
  eq(#p.rows, 5, "bars 1-5 only")
  ok(#p.dropped > 0, "more side spells than one bar holds")
  for _, n in ipairs(p.dropped) do ok(not n:find("Fake Spell"), "class spell dropped: " .. n) end
  local onSide = {}
  for i = 1, 12 do if p[5][i].name then onSide[p[5][i].name] = true end end
  for i = 1, 6 do ok(onSide["Fake Spell " .. i], "Fake Spell " .. i .. " on Action Bar 5") end
  env:slash("spells apply")
  noErrors(env)
  ok(env:chatText():find("stay in the spellbook", 1, true), "Apply reports what has no room")
  eq(Info(env, "after").changes, 0)
end)

test("keys: Ctrl binds CTRL-Q .. CTRL-4 to Action Bar 4 (MULTIACTIONBAR3BUTTON1-12)", function()
  local env = H.boot({ bindings = { ["CTRL-1"] = "BONUSACTIONBUTTON1", ["CTRL-R"] = "TOGGLEFPS" } })
  env:slash("keys apply")
  noErrors(env)
  local keys = { "Q", "E", "R", "T", "F", "G", "C", "V", "1", "2", "3", "4" }
  for i, k in ipairs(keys) do eq(env.W.bindings["CTRL-" .. k], "MULTIACTIONBAR3BUTTON" .. i, "CTRL-" .. k) end
  for i, k in ipairs(keys) do
    eq(env.W.bindings[k], "ACTIONBUTTON" .. i, k)
    eq(env.W.bindings["SHIFT-" .. k], "MULTIACTIONBAR1BUTTON" .. i, "SHIFT-" .. k)
    eq(env.W.bindings["ALT-" .. k], "MULTIACTIONBAR2BUTTON" .. i, "ALT-" .. k)
  end
  for _, k in ipairs({ "F13", "F14", "F15", "F16" }) do eq(env.W.bindings[k], nil, k .. " never bound") end
  env:slash("keys undo")
  noErrors(env)
  eq(env.W.bindings["CTRL-1"], "BONUSACTIONBUTTON1", "undo gives CTRL-1 back to the pet bar")
  eq(env.W.bindings["CTRL-R"], "TOGGLEFPS", "undo restores CTRL-R")
  eq(env.W.bindings["CTRL-Q"], nil, "undo clears CTRL-Q")
end)

test("keys: a backup from before the Ctrl layer gains the Ctrl keys on the next Apply", function()
  local env = H.boot({ bindings = { ["CTRL-R"] = "TOGGLEFPS" },
    db = { modules = { Keybinds = { backup = { commands = {}, keys = { Q = "MOVEFORWARD" }, set = "account" } } } } })
  env:slash("keys apply")
  eq(env.W.bindings["CTRL-R"], "MULTIACTIONBAR3BUTTON3")
  env:slash("keys undo")
  noErrors(env)
  eq(env.W.bindings["CTRL-R"], "TOGGLEFPS", "CTRL-R restored though the backup predates it")
  eq(env.W.bindings.Q, "MOVEFORWARD", "the old backup still restores Q")
end)

test("bars: the Ctrl layer fills Action Bar 4; side bars start at Action Bar 5; Ctrl spells never on a side bar", function()
  local env = H.boot({ pet = true, loaded = function(e) e.G.CreateFrame("Frame", "MultiBar5"); e.G.CreateFrame("Frame", "MultiBar6"); e.G.CreateFrame("Frame", "MultiBar7") end })
  local p = Info(env)
  eq(p.rows[4].label, "Action Bar 4")
  eq(p.rows[4].command, "MULTIACTIONBAR3BUTTON")
  eq(p.rows[5].label, "Action Bar 5")
  eq(p[4][1].slot, 25, "Ctrl+Q is slot 25")
  eq(p[4][1].name, "Viper Sting", "Ctrl+Q")
  eq(p[4][5].name, "Scare Beast", "Ctrl+F")
  eq(p[4][11].name, "Feed Pet", "Ctrl+3")
  local ctrl = {}
  for i = 1, 12 do if p[4][i].name then ctrl[p[4][i].name] = true end end
  local sideSlots = 0
  for r = 5, #p.rows do
    ok(p.rows[r].first >= 36, p.rows[r].label .. " is a side bar past Action Bar 4")
    for i = 1, 12 do
      local n = p[r][i].name
      if n then sideSlots = sideSlots + 1; ok(not ctrl[n], n .. " is on the Ctrl layer and on " .. p.rows[r].label) end
    end
  end
  ok(sideSlots > 0, "side bars hold something")
  -- Tracking and professions go to Action Bar 6 when it exists.
  local six
  for r = 5, #p.rows do if p.rows[r].label == "Action Bar 6" then six = r end end
  ok(six, "Action Bar 6 managed")
  local hasTrack = false
  for i = 1, 12 do if (p[six][i].name or ""):find("^Track ") then hasTrack = true end end
  ok(hasTrack, "tracking on Action Bar 6")
  env:slash("spells apply")
  noErrors(env)
  eq(env.W.actions[25] and env.W.actions[25].type, "spell", "slot 25 holds Viper Sting")
  for s = 37, 48 do
    local a = env.W.actions[s]
    if a then ok(a.id ~= 14280 and a.id ~= 14295, "slot " .. s .. " is not a Ctrl spell") end
  end
  eq(Info(env).changes, 0, "plan agrees with apply")
  eq(#env:calls("CreateMacro"), 0, "Apply never creates a macro")
end)
