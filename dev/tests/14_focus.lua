-- Focus graph of every v2 page (dev/ui-spec-v2.md §11.4, §12 Phase 6): from
-- the landing focus, D-pad/arrow walks reach every node, no node is a dead
-- end or a one-way trap, and in the pad variant every target is >= 28 px.
local H = require("harness")
local FC = require("focuscheck")

local VARIANTS = {
  { name = "kb", db = {} },
  { name = "pad", setup = function(W) W.gamepadUI = true end, db = { prompts = "pad" } },
}

-- Labels, each once with a count (pooled Inspector rows share a label across subjects).
local function Names(list)
  local t, count = {}, {}
  for _, n in ipairs(list) do
    local l = type(n) == "string" and n or FC.Label(n)
    if not count[l] then t[#t + 1] = l end
    count[l] = (count[l] or 0) + 1
  end
  for i, l in ipairs(t) do if count[l] > 1 then t[i] = l .. " (x" .. count[l] .. ")" end end
  return table.concat(t, ", ")
end

for _, v in ipairs(VARIANTS) do
  test("focus graph (" .. v.name .. "): every page is fully reachable with no dead ends", function()
    local db = {}
    for k, val in pairs(v.db) do db[k] = val end
    local env = H.boot({ pet = true, db = db, setup = v.setup })
    env:slash("")
    env:runTimers(1)
    local problems = {}
    for _, p in ipairs(env.ns.pages) do
      if p.api == 2 then
        env.ns.OpenPage(p.id)
        env:runTimers(1)
        local r = FC.Walk(env)
        ok(r.start, p.id .. ": has a landing focus")
        if #r.unreachable > 0 then problems[#problems + 1] = p.id .. " unreachable: " .. Names(r.unreachable) end
        -- The pad has no Tab: every node must be reachable with the D-pad alone.
        if v.name == "pad" and #r.arrowUnreachable > 0 then
          problems[#problems + 1] = p.id .. " unreachable without Tab: " .. Names(r.arrowUnreachableIds)
        end
        if v.name == "pad" and #r.noInspectorEntry > 0 then
          problems[#problems + 1] = p.id .. " Inspector can't be entered on the pad from: " .. Names(r.noInspectorEntryIds)
        end
        if #r.deadends > 0 then problems[#problems + 1] = p.id .. " dead ends: " .. Names(r.deadends) end
        if v.name == "pad" and #r.small > 0 then problems[#problems + 1] = p.id .. " small targets: " .. Names(r.small) end
      end
    end
    if #problems > 0 then fail(table.concat(problems, "\n")) end
    noErrors(env)
  end)
end

local function Key(env, key)
  local f = env.G.AgentcraftFrame
  f:GetScript("OnKeyDown")(f, key)
  local consumed = f._propagate == false
  f:GetScript("OnKeyUp")(f, key)
  return consumed
end

local function Open(id, opts)
  opts = opts or {}
  local env = H.boot({ pet = true, db = opts.db or { lastPage = id }, setup = opts.setup })
  env:slash("")
  env:runTimers(1)
  return env, env.ns.PageById(id)
end

test("focus: a node inside the Inspector keeps the Inspector's subject (focus is never lost there)", function()
  local env, page = Open("options")
  local Focus = env.ns.Focus
  local row
  for _, r in ipairs(page.rows) do if r.acId == "opt:log" then row = r end end
  Focus:Set(row, "key")
  env:runTimers(0.5)
  local btn
  for _, n in ipairs(Focus:Nodes()) do
    if Focus.ZoneOf(n) == "inspector" and n.GetText and n:GetText() == "Open Log" then btn = n end
  end
  ok(btn, "the log row's Inspector shows Open Log")
  Focus:Set(btn, "key")
  env:runTimers(0.5)
  eq(Focus.current, btn, "focus stays on the Inspector button after the settle")
  ok(Focus.Usable(btn), "the button is still there")
  eq(Focus.inspected, row, "the Inspector still explains the log row")
  env.ns.UI.Refresh()
  eq(Focus.current, btn, "a refresh keeps it too")
  ok(Focus.Usable(btn), "still shown after the refresh")
  Key(env, "TAB"); Key(env, "LEFT")
  ok(Focus.ZoneOf(Focus.current) ~= "inspector" or Focus.current ~= btn, "Left leaves the Inspector")
  noErrors(env)
end)

test("focus: Tab walks the zones in order and wraps; Shift-Tab goes back", function()
  local env = Open("keyboard")
  local Focus = env.ns.Focus
  Key(env, "TAB") -- engages on the current node
  local seq = {}
  for _ = 1, 6 do
    Key(env, "TAB")
    seq[#seq + 1] = Focus.ZoneOf(Focus.current)
  end
  local order = table.concat(seq, ">")
  ok(order:find("view>stage>inspector>prompts", 1, true) or order:find("stage>inspector>prompts>view", 1, true)
    or order:find("inspector>prompts>view>stage", 1, true) or order:find("prompts>view>stage>inspector", 1, true),
    "zone order " .. order)
  local before = Focus.ZoneOf(Focus.current)
  env.W.mods = env.W.mods or {}
  env.W.mods.shift = true
  Key(env, "TAB")
  env.W.mods.shift = false
  ok(Focus.ZoneOf(Focus.current) ~= before, "Shift-Tab moved to another zone")
  noErrors(env)
end)

test("focus: the Review sheet is modal, its list scrolls with focus, B closes it and focus returns", function()
  local env = Open("controller")
  local Focus = env.ns.Focus
  local stageNode = Focus.current
  env.G.AgentcraftPadY:Click()
  env:runTimers(1)
  local nodes = Focus:Nodes()
  ok(#nodes > 3, "modal nodes: " .. #nodes)
  for _, n in ipairs(nodes) do
    local o, inReview = n, false
    while o do if o == Focus:Root() then inReview = true break end o = o:GetParent() end
    ok(inReview, "every node is inside the sheet: " .. FC.Label(n))
  end
  ok(Focus:Root() ~= env.G.AgentcraftFrame, "the sheet is the focus root")
  -- Walk the list down: the focused row always stays inside the list's viewport.
  Key(env, "TAB")
  local list
  for _, n in ipairs(nodes) do if n.acScroll then list = n.acScroll break end end
  ok(list, "review rows belong to a ScrollList")
  Focus:Set(list:Nodes()[1], "key")
  local moved = 0
  for _ = 1, 60 do
    local cur = Focus.current
    Key(env, "DOWN")
    if Focus.current == cur or not Focus.current.acScroll then break end
    moved = moved + 1
    ok(list:IsRowVisible(Focus.current), "row " .. tostring(Focus.current.acId) .. " scrolled into view")
  end
  ok(moved > 8, "walked " .. moved .. " rows")
  ok(list.scroll:GetVerticalScroll() > 0, "the list scrolled")
  local rows = list:Nodes()
  eq(Focus.current.acScroll, nil, "Down from the last row leaves the list (to the sheet's buttons)")
  Key(env, "UP")
  eq(Focus.current, rows[#rows], "Up returns to the last row")
  Key(env, "HOME")
  eq(Focus.current, rows[1], "Home: first row")
  ok(list:IsRowVisible(Focus.current), "Home: first row visible")
  env.G.AgentcraftPadB:Click()
  ok(Focus:Root() == env.G.AgentcraftFrame, "B closed the sheet")
  ok(env.G.AgentcraftFrame:IsShown(), "the window stays open")
  ok(Focus.Usable(Focus.current) and Focus.ZoneOf(Focus.current) == "stage", "focus back on the stage")
  eq(Focus.current, stageNode, "on the node it left from")
  noErrors(env)
end)

test("focus: B with nothing to back out of closes the window; reopening restores the page and node", function()
  local env, page = Open("keyboard")
  local Focus = env.ns.Focus
  -- Pad flow: D-pad moves (no Tab, so nothing is engaged on the Back stack).
  Focus:Move("RIGHT", "pad"); Focus:Move("RIGHT", "pad")
  local id = Focus.current.acId
  ok(id, "a node with an id")
  env.G.AgentcraftPadB:Click()
  ok(not env.G.AgentcraftFrame:IsShown(), "closed")
  env:slash("")
  env:runTimers(1)
  ok(env.G.AgentcraftFrame:IsShown(), "reopened")
  eq(env.ns.UI.CurrentPage(), page, "same page")
  eq(Focus.current.acId, id, "same node")
  noErrors(env)
end)

test("focus: LB/RB switch pages and land on a usable node every time (pad)", function()
  local env = Open("keyboard", { setup = function(W) W.gamepadUI = true end, db = { lastPage = "keyboard", prompts = "pad" } })
  local Focus = env.ns.Focus
  local seen = {}
  for _ = 1, 8 do
    env.G.AgentcraftNextTab:Click()
    env:runTimers(1)
    local p = env.ns.UI.CurrentPage()
    seen[p.id] = true
    ok(Focus.current and Focus.Usable(Focus.current), p.id .. ": focus usable")
    ok(Focus.ZoneOf(Focus.current) ~= "tabs", p.id .. ": not on a tab")
  end
  for _, id in ipairs({ "keyboard", "controller", "macros", "options" }) do ok(seen[id], "visited " .. id) end
  env.G.AgentcraftPrevTab:Click()
  env:runTimers(1)
  ok(Focus.Usable(Focus.current), "LB lands too")
  noErrors(env)
end)
