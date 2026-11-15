-- The v2 Keyboard page (dev/ui-spec-v2.md §9.2): Action Bars + Key Bindings
-- on one keyboard. Focus moves (keys, mouse column, view strip, prompts,
-- Inspector), pin and Back, X / chips / Shift preview, the List view with
-- scroll-follows-focus, focus surviving a view change, Review counts and
-- Commit (never a macro), and the half-gated module states.
local H = require("harness")

local function Boot(opts)
  opts = opts or {}
  opts.pet = opts.pet ~= false
  opts.db = opts.db or { lastPage = "keyboard" }
  local env = H.boot(opts)
  env:slash("")
  env:runTimers(1)
  local page = env.ns.PageById("keyboard")
  return env, page
end

local function Count(groups)
  local n = 0
  for _, g in ipairs(groups or {}) do n = n + #g.items end
  return n
end

test("keyboard: one page for bars and keys; old ids alias it; layout keys focusable, movement keys not", function()
  local env, page = Boot()
  local UI = env.ns.UI
  eq(UI.CurrentPage(), page, "opens on the Keyboard page")
  eq(env.ns.PageById("bars"), page, "bars alias")
  eq(env.ns.PageById("keys"), page, "keys alias")
  eq(env.ns.PageById("settings") ~= page, true)
  for _, k in ipairs({ "Q", "E", "R", "T", "F", "G", "C", "V", "1", "2", "3", "4", "Z", "X", "BUTTON3", "BUTTON4", "BUTTON5" }) do
    ok(page.caps[k] and env.ns.Focus.Usable(page.caps[k]), k .. " is a focus target")
  end
  local nodes = env.ns.Focus:Nodes()
  for _, n in ipairs(nodes) do
    local key = n.key and n.key.GetText and n.key:GetText()
    ok(not (key == "W" or key == "A" or key == "S" or key == "D" or key == "5") or n.acSkip, "movement key " .. tostring(key) .. " is not a target")
  end
  -- Every managed key shows a name (icon + name, readable at a glance).
  for _, s in ipairs(page.capList) do
    local text = s.nameText and s.nameText:GetText() or (s.caption and s.caption:GetText())
    ok(text and text ~= "", s.base .. " shows a name")
  end
  noErrors(env)
end)

test("keyboard: spatial moves reach the view strip, the mouse column, the Inspector and the prompt bar", function()
  local env, page = Boot()
  local Focus = env.ns.Focus
  Focus:Set(page.caps["1"], "key")
  Focus:Move("UP")
  eq(Focus.ZoneOf(Focus.current), "view", "Up from the number row reaches the view strip")
  Focus:Set(page.caps.T, "key")
  Focus:Move("RIGHT")
  ok(Focus.current == page.caps.BUTTON3 or Focus.current == page.caps.BUTTON4, "Right of T: the mouse column (" .. tostring(Focus.current.acId) .. ")")
  Focus:Move("RIGHT")
  eq(Focus.ZoneOf(Focus.current), "inspector", "Right of the mouse column: the Inspector")
  Focus:Set(page.caps.V, "key")
  Focus:Move("DOWN")
  eq(Focus.ZoneOf(Focus.current), "prompts", "Down from the bottom row: the prompt bar (the bar mirror is not a target)")
  Focus:Set(page.caps.Q, "key")
  Focus:Move("RIGHT")
  eq(Focus.current, page.caps.E, "Right of Q skips the faint W")
  noErrors(env)
end)

test("keyboard: A pins the key in the Inspector; B unpins before it closes", function()
  local env, page = Boot()
  local Focus, Esc = env.ns.Focus, env.ns.Esc
  Focus:Set(page.caps.R, "key")
  Focus:Activate("key")
  eq(Focus.pinned, page.caps.R, "A pins")
  Focus:Set(page.caps.T, "key")
  eq(Focus.pinned, page.caps.R, "pin holds while focus moves")
  ok(Esc.Pop(), "B pops the pin")
  eq(Focus.pinned, nil)
  ok(env.G.AgentcraftFrame:IsShown(), "window still open")
  noErrors(env)
end)

test("keyboard: X cycles Plain > Shift > Alt > Side bars; Shift held previews; the Inspector shows all three layers", function()
  local env, page = Boot()
  local UI = env.ns.UI
  eq(page.view, "plain")
  local plainQ = page.caps.Q.cell
  UI.CycleView(1)
  eq(page.view, "shift", "X: Shift layer")
  eq(page.caps.Q.cell.layer, 2, "keys show the Shift layer")
  ok(page.barTitle:GetText():find("Action Bar 2", 1, true), "bar mirror follows: " .. page.barTitle:GetText())
  UI.CycleView(1); UI.CycleView(1)
  eq(page.view, "side", "X: Side bars")
  ok(page.side:IsShown() and not page.picture:IsShown(), "side bars view shown")
  UI.CycleView(1)
  eq(page.view, "plain", "wraps")
  -- Live preview (display only).
  env.W.mods = env.W.mods or {}
  env.W.mods.shift = true
  page.frame.acPollModifiers()
  eq(page.caps.Q.cell.layer, 2, "holding Shift previews the Shift layer")
  eq(page.view, "plain", "the chip stays")
  env.W.mods.shift = false
  page.frame.acPollModifiers()
  eq(page.caps.Q.cell.layer, 1, "release returns")
  ok(plainQ.bind == "Q", "plain Q cell")
  eq(#env:calls("SetBinding"), 0, "preview binds nothing")
  noErrors(env)
end)

test("keyboard: List view lists every key's three layers; scroll follows focus; focus survives the view change", function()
  local env, page = Boot()
  local Focus = env.ns.Focus
  Focus:Set(page.caps.E, "key")
  local toggle = page.strip.toggles[#page.strip.toggles] -- toggles are built right to left: the first one is last
  for _, t in ipairs(page.strip.toggles) do if t.def.key == "mode" then toggle = t end end
  toggle:Select(2)
  eq(page.mode, 2, "List view")
  ok(page.listFrame:IsShown() and not page.picture:IsShown(), "list shown")
  eq(Focus.current.acId, "list:E:1", "focus moved to the same key in the list: " .. tostring(Focus.current and Focus.current.acId))
  local list = page.list
  local rows = list:Nodes()
  eq(#rows, 17, "one row per key (12 bar keys, Z X, three mouse buttons)")
  Focus:Move("RIGHT")
  eq(Focus.current.acId, "list:E:2", "Right: the Shift cell of the same key")
  Focus:Move("DOWN")
  eq(Focus.current.acId, "list:R:2", "Down: next key, same layer")
  -- The last row comes into view when focused.
  local last = list:Nodes()[#list:Nodes()]
  Focus:Set(last, "key")
  ok(list:IsRowVisible(last), "scrolled to the last row")
  -- Wheel scrolls one row and keeps focus on screen.
  list.scroll:GetScript("OnMouseWheel")(list.scroll, 1)
  list.scroll:GetScript("OnMouseWheel")(list.scroll, 1)
  for _ = 1, 20 do list.scroll:GetScript("OnMouseWheel")(list.scroll, 1) end
  eq(list.scroll:GetVerticalScroll(), 0, "wheel up to the top")
  ok(list:IsRowVisible(Focus.current), "focus followed the wheel onto a visible row")
  Focus.engaged = true
  Focus:ListJump("END")
  ok(Focus.current.acId:find(":2$") ~= nil, "End stays in the Shift column: " .. Focus.current.acId)
  -- Back to the picture: focus on the same key.
  Focus:Set(rows[3], "key")
  local base = rows[3].data.base
  toggle:Select(1)
  eq(Focus.current, page.caps[base], "picture again: focus on " .. base)
  noErrors(env)
end)

test("keyboard: Review counts match the plan; Commit applies bars then keys, never makes a macro; then up to date", function()
  local env, page = Boot({ bindings = { Q = "MOVEFORWARD" } })
  local UI = env.ns.UI
  local groups = page.Review(page)
  local d = page.data
  eq(Count(groups), d.plan.changes + d.diff.keys + d.diff.extra, "review items = bar changes + keys + unbinds")
  local keys
  for _, g in ipairs(groups) do if g.title == "KEYS" then keys = g end end
  ok(keys, "a KEYS group")
  local q
  for _, it in ipairs(keys.items) do if it.key == "Q" then q = it end end
  ok(q and q.note == "replaces your bind", "Q replaces your bind")
  env:resetCalls()
  UI.OpenReview()
  UI.Commit()
  eq(#env:calls("CreateMacro"), 0, "Commit never creates a macro")
  ok(#env:calls("PlaceAction") > 0, "bars placed")
  ok(#env:calls("SetBinding") > 0, "keys bound")
  eq(Count(page.Review(page)), 0, "nothing left to review")
  ok(tostring(page.Status(page)):find("Up to date", 1, true), "up to date: " .. tostring(page.Status(page)))
  local done, total = page.readiness(page)
  eq(done, total, "meter full")
  noErrors(env)
end)

test("keyboard: Key Bindings off keeps the page (bars only); both off gates it", function()
  local env, page = Boot()
  local ns = env.ns
  ns.SetModuleEnabled(ns.ModuleOf("Keybinds"), false)
  ns.OpenPage("keyboard")
  ok(not ns.IsGated(page.module), "one module on: not gated")
  for _, g in ipairs(page.Review(page)) do
    ok(g.title ~= "KEYS" and g.title ~= "WILL UNBIND", "no key changes while Key Bindings is off: " .. g.title)
  end
  ns.SetModuleEnabled(ns.ModuleOf("ActionBars"), false)
  ns.OpenPage("keyboard")
  ok(ns.IsGated(page.module), "both off: gated")
  noErrors(env)
end)
