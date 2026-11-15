-- Options page v2 (dev/ui-spec-v2.md §9.5): the ledger rows are focus nodes;
-- A toggles a module, choice and slider rows step with Left/Right and hand
-- focus on at their ends, the Log sub-view is a Back layer.
local H = require("harness")

local function Open(opts)
  opts = opts or {}
  opts.db = opts.db or { lastPage = "settings" }
  local env = H.boot(opts)
  env:slash("")
  env:runTimers(1)
  local page = env.ns.PageById("options")
  return env, page
end

local function Row(page, id)
  for _, r in ipairs(page.rows) do if r.acId == id then return r end end
end

test("options: alias 'options' opens the v2 ledger; every module has a row; default focus is the first module", function()
  local env, page = Open()
  ok(page and page.api == 2, "v2 page found by its alias")
  ok(page.frame and page.frame:IsShown(), "page shown")
  for _, mod in ipairs(env.ns.order) do ok(Row(page, "opt:mod:" .. mod.name), "row for " .. mod.name) end
  for _, k in ipairs({ "scale", "prompts", "sound", "focusTips", "shortcuts", "reset" }) do
    ok(Row(page, "opt:set:" .. k), "row for setting " .. k)
  end
  ok(Row(page, "opt:log"), "log row")
  ok(Row(page, "opt:tool:Snapshot:Save Now"), "Snapshot tool row")
  eq(page:DefaultFocus(), page.moduleRows[1])
  noErrors(env)
end)

test("options: A on a module row turns it off and on; the row and box follow", function()
  local env, page = Open()
  local Focus = env.ns.Focus
  local row = Row(page, "opt:mod:Fishing")
  Focus:Set(row, "pad")
  env.G.AgentcraftPadA:Click()
  ok(not env.ns.modules.fishing.active, "fishing off")
  eq(env.G.AgentcraftDB.enabled.Fishing, false, "saved")
  ok(not row.box:GetChecked(), "box unchecked")
  eq(row.value:GetText(), "Off")
  env.G.AgentcraftPadA:Click()
  ok(env.ns.modules.fishing.active, "fishing back on")
  ok(row.box:GetChecked(), "box checked")
  noErrors(env)
end)

test("options: D-pad moves down the rows; a choice row steps with Right and hands focus on at its end", function()
  local env, page = Open()
  local Focus = env.ns.Focus
  local prompts = Row(page, "opt:set:prompts")
  Focus:Set(Row(page, "opt:set:scale"), "pad")
  env.G.AgentcraftPadDOWN:Click()
  eq(Focus.current, prompts, "Down: scale -> button prompts")
  eq(env.ns.Setting("prompts"), "auto")
  env.G.AgentcraftPadRIGHT:Click()
  eq(env.ns.Setting("prompts"), "keyboard", "Right steps the choice")
  eq(Focus.current, prompts, "focus stays while stepping")
  env.G.AgentcraftPadRIGHT:Click()
  eq(env.ns.Setting("prompts"), "pad")
  env.G.AgentcraftPadRIGHT:Click()
  eq(env.ns.Setting("prompts"), "pad", "no wrap at the end")
  ok(Focus.current ~= prompts and Focus.ZoneOf(Focus.current) ~= nil, "at the end Right moves focus on (no dead end)")
  Focus:Set(prompts, "pad")
  env.G.AgentcraftPadA:Click()
  eq(env.ns.Setting("prompts"), "auto", "A cycles and wraps")
  noErrors(env)
end)

test("options: toggles write ns.db; shortcuts off unbinds the Ctrl chords", function()
  local env, page = Open()
  local Focus = env.ns.Focus
  ok(env.W.overrides["CTRL-TAB"], "chords bound")
  Focus:Set(Row(page, "opt:set:shortcuts"), "pad")
  env.G.AgentcraftPadA:Click()
  eq(env.G.AgentcraftDB.shortcuts, false)
  eq(env.W.overrides["CTRL-TAB"], nil, "chords cleared")
  ok(env.W.overrides.PAD1, "pad overrides kept")
  Focus:Set(Row(page, "opt:set:sound"), "pad")
  env.G.AgentcraftPadA:Click()
  eq(env.G.AgentcraftDB.sound, false, "sound off")
  noErrors(env)
end)

test("options: scale row steps 0.05 with Left/Right; A goes back to automatic", function()
  local env, page = Open()
  local UI, Focus = env.ns.UI, env.ns.Focus
  local row = Row(page, "opt:set:scale")
  Focus:Set(row, "pad")
  local s0 = UI.GetScale()
  env.G.AgentcraftPadLEFT:Click()
  ok(math.abs(UI.GetScale() - (s0 - 0.05)) < 0.001, "Left: -0.05")
  eq(Focus.current, row, "focus stays")
  env.G.AgentcraftPadA:Click()
  eq(env.G.AgentcraftDB.scale, nil, "A: automatic")
  noErrors(env)
end)

test("options: Open log shows the Log sub-view; B returns to the ledger with focus on the log row", function()
  local env, page = Open()
  local Focus, Esc = env.ns.Focus, env.ns.Esc
  env.ns.LogLine("hello from the test")
  Focus:Set(Row(page, "opt:log"), "pad")
  env.G.AgentcraftPadA:Click()
  ok(page.logView:IsShown() and not page.ledger:IsShown(), "log view replaces the ledger")
  ok(Esc.Has("log"), "the log is a Back layer")
  eq(Focus.current, page.logWell, "focus in the log")
  ok(page.logBox:GetText():find("hello from the test", 1, true), "log text shown")
  env.G.AgentcraftPadB:Click()
  ok(not page.logView:IsShown() and page.ledger:IsShown(), "B returns")
  eq(Focus.current, Row(page, "opt:log"), "focus back on Open log")
  ok(env.G.AgentcraftFrame:IsShown(), "window still open")
  -- A page switch closes the sub-view, so B never closes the window by surprise.
  Focus:Set(Row(page, "opt:log"), "pad")
  env.G.AgentcraftPadA:Click()
  env.G.AgentcraftNextTab:Click()
  ok(not page.logView:IsShown(), "closed on page switch")
  noErrors(env)
end)
