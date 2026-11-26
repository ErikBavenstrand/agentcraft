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

-- Controller-only use (owner request, 2026-11-24: "make sure Agentcraft is
-- COMPLETELY controller supported") ------------------------------------------
-- The Gamepad UI (Steam Deck): SmartNavigation drives the D-pad and A. The
-- mock records what the window registers with it (UI/Input.lua wires a jump
-- override per direction on every node and OnSmartNavClick), and
-- FC.PadCoverage models which frames it can stop on.

local function SNMock(W)
  W.sn = { refreshes = 0 }
  return {
    RefreshButtonGroups = function() W.sn.refreshes = W.sn.refreshes + 1 end,
    SetTargetButtonForFrame = function(_, _, b) W.sn.target = b end,
    SetScrollFrameForFrame = function(_, _, region) W.sn.scroll = region end,
  }
end

local function PadBoot(opts)
  opts = opts or {}
  local db = { prompts = "pad", lastPage = opts.page }
  local env = H.boot({ fixture = opts.fixture, pet = true, db = db, setup = function(W)
    W.gamepadUI = not opts.noGamepadUI
    W.api.SmartNavigation = SNMock(W)
    W.api.GamepadMode = { FrameControlsManager = { FrameShown = function() end, FrameHidden = function() end } }
  end })
  env:slash("")
  env:runTimers(1)
  if not opts.noGamepadUI then env.G.AgentcraftFrame.FocusGamepad() end
  return env
end

-- The prompt bar button for a pad key ("PAD1"): its label, or nil when hidden.
local function PromptLabel(env, key)
  local found
  local function walk(f)
    if rawget(f, "acId") == "prompt:" .. key then found = f return end
    for _, c in ipairs({ f:GetChildren() }) do if not found then walk(c) end end
  end
  walk(env.G.AgentcraftFrame)
  if not (found and found:IsShown()) then return nil end
  return found.label:GetText()
end

-- Walks the state shown now and adds every pad problem to problems:
-- unreachable or dead-end nodes, Inspectors the pad can't enter, frames the
-- Gamepad UI stops on that are not nodes, nodes it can't reach, nodes A
-- does nothing on, and nodes without their SmartNavigation wiring. Each
-- node's own Inspector is checked too (its links and buttons).
local function PadState(env, label, problems)
  local Focus = env.ns.Focus
  local r = FC.Walk(env)
  if not r.start then problems[#problems + 1] = label .. ": no landing focus" return end
  if #r.arrowUnreachable > 0 then problems[#problems + 1] = label .. " unreachable on the pad: " .. Names(r.arrowUnreachableIds) end
  if #r.noInspectorEntry > 0 then problems[#problems + 1] = label .. " Inspector can't be entered from: " .. Names(r.noInspectorEntryIds) end
  if #r.deadends > 0 then problems[#problems + 1] = label .. " dead ends: " .. Names(r.deadends) end
  local seen, phantoms, hidden, inert, unwired = {}, {}, {}, {}, {}
  local function Cover(subject)
    local c = FC.PadCoverage(env)
    for _, f in ipairs(c.phantoms) do if not seen[f] then seen[f] = true; phantoms[#phantoms + 1] = f end end
    for _, f in ipairs(c.hidden) do if not seen[f] then seen[f] = true; hidden[#hidden + 1] = f end end
    for _, f in ipairs(c.inert) do if not seen[f] then seen[f] = true; inert[#inert + 1] = f end end
    if env.W.gamepadUI then
      for _, n in ipairs(Focus:Nodes()) do
        local o = rawget(n, "_snOverrides")
        local wired = o and type(o.Up) == "function" and type(o.Down) == "function" and type(o.Left) == "function"
          and type(o.Right) == "function" and type(rawget(n, "OnSmartNavClick")) == "function"
        if not wired and not seen[n] then
          seen[n] = true
          unwired[#unwired + 1] = FC.Label(n) .. (subject and (" (Inspector of " .. FC.Label(subject) .. ")") or "")
        end
      end
    end
  end
  Cover()
  for _, k in ipairs(r.order) do
    local f = r.frameOf[k]
    if f and Focus.Usable(f) and Focus.ZoneOf(f) ~= "inspector" and f.acInspect then
      Focus:Set(f, "pad", true, true)
      env:runTimers(0.3)
      Cover(f)
    end
  end
  if #phantoms > 0 then problems[#problems + 1] = label .. " Gamepad UI stops that are not nodes: " .. Names(phantoms) end
  if #hidden > 0 then problems[#problems + 1] = label .. " nodes the Gamepad UI can't reach: " .. Names(hidden) end
  if #inert > 0 then problems[#problems + 1] = label .. " A does nothing on: " .. Names(inert) end
  if #unwired > 0 then problems[#problems + 1] = label .. " not wired to SmartNavigation: " .. table.concat(unwired, ", ") end
end

-- Every view of the page shown now (X cycles them), each walked.
local function Views(env, page, label, problems)
  local n = page.views and #page.views or 0
  for i = 1, math.max(n, 1) do
    PadState(env, label .. (n > 0 and (" view " .. tostring(page.view)) or ""), problems)
    if n > 1 and i < n then env.ns.UI.CycleView(1); env:runTimers(1) end
  end
end

test("pad only (Gamepad UI): every page, view, sheet and sub-view is reachable, wired, with no stray stops", function()
  local env = PadBoot()
  local problems = {}
  for _, p in ipairs(env.ns.pages) do
    if p.api == 2 then
      env.ns.OpenPage(p.id)
      env:runTimers(1)
      Views(env, p, p.id, problems)
    end
  end
  -- Keyboard page as a list.
  local kb = env.ns.PageById("keyboard")
  env.ns.OpenPage("keyboard"); env:runTimers(1)
  kb.mode = 2; env.ns.UI.Refresh(); env:runTimers(1)
  PadState(env, "keyboard list", problems)
  kb.mode = 1; env.ns.UI.Refresh()
  -- Macros: a search that finds nothing (the empty state's Clear button).
  local mp = env.ns.PageById("macros")
  env.ns.OpenPage("macros"); env:runTimers(1)
  mp.query = "zzzz nothing"; env.ns.UI.Refresh(); env:runTimers(1)
  PadState(env, "macros no results", problems)
  mp.query = ""; env.ns.UI.Refresh()
  -- Options log view (A on Open log).
  env.ns.OpenPage("options"); env:runTimers(1)
  local opt = env.ns.PageById("options")
  for _, r in ipairs(opt.rows) do if r.acId == "opt:log" then env.ns.Focus:Set(r, "pad"); r:OnSmartNavClick() end end
  env:runTimers(1)
  local cur = env.ns.Focus.current
  ok(cur and type(cur.acId) == "string" and cur.acId:find("^opt:log"), "A on Open log opens the log view")
  PadState(env, "options log", problems)
  env.G.AgentcraftFrame.SmartNavigationCloseHandler()
  -- The Review sheet of every page that has one (Y opens it).
  for _, id in ipairs({ "keyboard", "controller", "macros" }) do
    env.ns.OpenPage(id); env:runTimers(1)
    env.G.AgentcraftPadY:Click(); env:runTimers(1)
    if env.ns.Focus:Root() ~= env.G.AgentcraftFrame then
      PadState(env, id .. " review", problems)
      env.G.AgentcraftFrame.SmartNavigationCloseHandler(); env:runTimers(1)
      eq(env.ns.Focus:Root(), env.G.AgentcraftFrame, id .. ": B closed the Review sheet")
    end
  end
  if #problems > 0 then fail(table.concat(problems, "\n")) end
  noErrors(env)
end)

test("pad only (Gamepad UI): the Spec and Bar 1 page pickers (warrior) step with Left/Right and never trap", function()
  local env = PadBoot({ fixture = "warrior", page = "keyboard" })
  local problems = {}
  local kb = env.ns.PageById("keyboard")
  ok(kb.stanceRow and kb.stanceRow:IsVisible(), "Bar 1 page picker shown")
  PadState(env, "warrior keyboard", problems)
  env.ns.OpenPage("controller"); env:runTimers(1)
  PadState(env, "warrior controller", problems)
  -- The picker itself: Right changes the value and keeps focus.
  env.ns.OpenPage("keyboard"); env:runTimers(1)
  local Focus = env.ns.Focus
  Focus:Set(kb.stanceRow, "pad")
  local before = kb.stanceRow:ValueText()
  local o = rawget(kb.stanceRow, "_snOverrides")
  ok(o and o.Right, "the picker has its SmartNavigation moves")
  eq(o.Right(), true, "Right on the picker steps the value and stays")
  ok(kb.stanceRow:ValueText() ~= before, "the value changed: " .. before .. " -> " .. kb.stanceRow:ValueText())
  eq(Focus.current, kb.stanceRow, "focus stays on the picker")
  eq(PromptLabel(env, "PAD1"), "Change", "A prompt: Change")
  if #problems > 0 then fail(table.concat(problems, "\n")) end
  noErrors(env)
end)

test("Gamepad UI: A runs the window's Activate (a key pins and steps into the Inspector); the D-pad follows the window's moves", function()
  local env = PadBoot({ page = "keyboard" })
  local Focus = env.ns.Focus
  local key
  for _, n in ipairs(Focus:Nodes()) do if n.acId == "key:Q" then key = n end end
  ok(key, "key Q is a node")
  ok(type(key.OnSmartNavClick) == "function", "OnSmartNavClick set")
  Focus:Set(key, "pad")
  key:OnSmartNavClick()
  eq(Focus.pinned, key, "A pinned the key")
  eq(Focus.ZoneOf(Focus.current), "inspector", "and stepped into the Inspector")
  env.G.AgentcraftFrame.SmartNavigationCloseHandler()
  eq(Focus.current, key, "B (SmartNavigation close) comes back to the key")
  -- Every move SmartNavigation asks for is Focus:Move's answer.
  local o = rawget(key, "_snOverrides")
  local target = o.Right()
  ok(target ~= true and target == Focus.current, "the override hands back where focus went")
  ok(Focus.current ~= key, "Right moved off Q")
  ok(env.W.sn.target ~= nil, "the Gamepad UI cursor was pointed at a node")
  -- Combat: SmartNavigation refuses insecure overrides, so they come off.
  env:fire("PLAYER_REGEN_DISABLED"); env.W.inCombat = true
  eq(rawget(key, "_snOverrides"), nil, "overrides cleared when combat starts")
  env.W.inCombat = false; env:fire("PLAYER_REGEN_ENABLED")
  ok(rawget(key, "_snOverrides"), "and set again after")
  noErrors(env)
end)

test("Gamepad UI: More... lists every tag in the Inspector; A toggles one, B returns to More...", function()
  local env = PadBoot({ page = "macros" })
  local Focus = env.ns.Focus
  local page = env.ns.PageById("macros")
  Focus:Set(page.more, "pad")
  eq(PromptLabel(env, "PAD1"), "Tags", "A prompt: Tags")
  page.more:OnSmartNavClick()
  local cur = Focus.current
  ok(cur and type(cur.acId) == "string" and cur.acId:find("^tagref:"), "A stepped into the tag list: " .. FC.Label(cur))
  local key = cur.acId:match("^tagref:(.+)$")
  cur:OnSmartNavClick()
  env:runTimers(1)
  eq(page.filters[key], true, "A turned tag " .. key .. " on")
  eq(Focus.current.acId, "tagref:" .. key, "focus stays on that tag")
  env.G.AgentcraftFrame.SmartNavigationCloseHandler()
  eq(Focus.current, page.more, "B goes back to More...")
  noErrors(env)
end)

test("pad: the search box gives the keyboard back on B and on a move; its prompt says Type", function()
  local env = PadBoot({ page = "macros", noGamepadUI = true })
  local Focus = env.ns.Focus
  local page = env.ns.PageById("macros")
  local box = page.search
  local cleared = 0
  box.ClearFocus = function() cleared = cleared + 1; env.W.keyFocus = nil end
  box.HasFocus = function() return env.W.keyFocus == box end
  box.SetFocus = function() env.W.keyFocus = box end
  Focus:Set(box, "pad")
  eq(PromptLabel(env, "PAD1"), "Type", "A prompt: Type")
  env.G.AgentcraftPadA:Click()
  eq(env.W.keyFocus, box, "A gave the box the keyboard")
  box:SetText("fish")
  eq(PromptLabel(env, "PAD2"), "Back", "B prompt: Back while typing")
  env.G.AgentcraftPadB:Click()
  eq(box:GetText(), "", "first B clears the text")
  ok(env.G.AgentcraftFrame:IsShown(), "window still open")
  env.G.AgentcraftPadB:Click()
  eq(cleared, 1, "second B leaves the box")
  ok(env.G.AgentcraftFrame:IsShown(), "window still open")
  env.W.keyFocus = box
  env.G.AgentcraftPadDOWN:Click(nil, true)
  env.G.AgentcraftPadDOWN:Click(nil, false)
  ok(cleared >= 2, "a D-pad move hands the keyboard back")
  ok(Focus.current ~= box, "and moved on")
  noErrors(env)
end)

test("pad without the Gamepad UI: A answers Yes and B answers No on our confirm dialogs; prompts say so", function()
  local env = PadBoot({ page = "options", noGamepadUI = true })
  local ran = 0
  env.ns.UI.Confirm("Sure?", function() ran = ran + 1 end)
  ok(env.W.popup, "dialog shown")
  eq(PromptLabel(env, "PAD1"), "Yes", "A prompt: Yes")
  eq(PromptLabel(env, "PAD2"), "No", "B prompt: No")
  env.G.AgentcraftPadB:Click()
  eq(env.W.popup, nil, "B closed it")
  eq(ran, 0, "B said No")
  ok(env.G.AgentcraftFrame:IsShown(), "the window stays open")
  env.ns.UI.Confirm("Sure?", function() ran = ran + 1 end)
  env.G.AgentcraftPadA:Click()
  eq(env.W.popup, nil, "A closed it")
  eq(ran, 1, "A said Yes")
  env:runTimers(0.1)
  ok(PromptLabel(env, "PAD2") ~= "No", "B prompt back to normal")
  noErrors(env)
end)

-- Opening the window without typing /ac ---------------------------------------

local function ReadFile(path)
  local f = assert(io.open(path, "rb"))
  local s = f:read("*a")
  f:close()
  return s
end

test("open: the addon compartment entry (TOC) toggles the window; hover shows a tooltip", function()
  local env = H.boot()
  local meta = env.toc.meta
  eq(meta.AddonCompartmentFunc, "Agentcraft_OnAddonCompartmentClick")
  eq(meta.AddonCompartmentFuncOnEnter, "Agentcraft_OnAddonCompartmentEnter")
  eq(meta.AddonCompartmentFuncOnLeave, "Agentcraft_OnAddonCompartmentLeave")
  ok(meta.IconTexture and meta.IconTexture ~= "", "IconTexture set")
  local G = env.G
  for _, k in ipairs({ "AddonCompartmentFunc", "AddonCompartmentFuncOnEnter", "AddonCompartmentFuncOnLeave" }) do
    ok(type(rawget(G, meta[k])) == "function", meta[k] .. " is a global function")
  end
  G[meta.AddonCompartmentFunc]("Agentcraft", "LeftButton")
  ok(G.AgentcraftFrame and G.AgentcraftFrame:IsShown(), "click opens")
  local btn = G.CreateFrame("Button")
  G[meta.AddonCompartmentFuncOnEnter]("Agentcraft", btn)
  ok(G.GameTooltip:IsShown(), "hover shows the tooltip")
  G[meta.AddonCompartmentFuncOnLeave]("Agentcraft", btn)
  ok(not G.GameTooltip:IsShown(), "leave hides it")
  G[meta.AddonCompartmentFunc]("Agentcraft", "LeftButton")
  ok(not G.AgentcraftFrame:IsShown(), "click again closes")
  noErrors(env)
end)

test("open: Bindings.xml lists Agentcraft's bindings in their own labelled section; each toggles or opens its page", function()
  local env = H.boot()
  local G = env.G
  local xml = ReadFile(H.addonDir .. "/Bindings.xml")
  local names, count = {}, 0
  for attrs, body in xml:gmatch("<Binding%s+([^>]-)>(.-)</Binding>") do
    local b = { name = attrs:match('name="([^"]+)"'), category = attrs:match('category="([^"]+)"'), body = body }
    names[b.name] = b
    count = count + 1
    ok(type(rawget(G, "BINDING_NAME_" .. b.name)) == "string", "BINDING_NAME_" .. b.name .. " labels it")
    eq(rawget(G, b.category), "Agentcraft", b.name .. ": its section is called Agentcraft")
    ok(not attrs:find("default", 1, true), b.name .. ": no default key (nothing bound automatically)")
    ok(not b.body:find("SetBinding", 1, true), b.name .. " never binds anything itself")
  end
  ok(count >= 4, "bindings found: " .. count)
  local function Run(name)
    local chunk = assert(loadstring(names[name].body, name))
    setfenv(chunk, G)
    chunk()
  end
  ok(names.AGENTCRAFT_TOGGLE, "Toggle Agentcraft")
  Run("AGENTCRAFT_TOGGLE")
  ok(G.AgentcraftFrame:IsShown(), "toggle opens")
  Run("AGENTCRAFT_TOGGLE")
  ok(not G.AgentcraftFrame:IsShown(), "toggle closes")
  for _, id in ipairs({ "controller", "keyboard", "macros" }) do
    local name = "AGENTCRAFT_" .. id:upper()
    ok(names[name], name .. " exists")
    Run(name)
    ok(G.AgentcraftFrame:IsShown(), name .. " opens")
    eq(env.ns.UI.CurrentPage().id, id, name .. " shows its page")
  end
  Run("AGENTCRAFT_MACROS")
  ok(not G.AgentcraftFrame:IsShown(), "the page binding on its own page closes the window")
  -- In combat: plain Show/Hide, no protected call, no error.
  env.W.inCombat = true
  Run("AGENTCRAFT_TOGGLE")
  ok(G.AgentcraftFrame:IsShown(), "opens in combat")
  Run("AGENTCRAFT_TOGGLE")
  ok(not G.AgentcraftFrame:IsShown(), "closes in combat")
  env.W.inCombat = false
  eq(#env:calls("ShowUIPanel") + #env:calls("HideUIPanel"), 0, "never ShowUIPanel/HideUIPanel (taint)")
  noErrors(env)
end)

test("open: the Agentcraft macro (/ac) opens the window and has the same home on controller page 3 for every class", function()
  local env = H.boot()
  local m
  for _, x in ipairs(env.ns.MacroLibrary.macros) do if x.name == "Agentcraft" then m = x end end
  ok(m, "library macro Agentcraft")
  eq(m.body, "/ac")
  eq(m.class, nil, "every class")
  local tagged = false
  for _, t in ipairs(m.tags or {}) do if t == "controller" then tagged = true end end
  ok(tagged, "tagged controller")
  -- The body is the addon's slash command alone: the handler toggles the window.
  eq(m.body, env.G.SLASH_AGENTCRAFT1, "the body is /ac")
  env:slash("")
  ok(env.G.AgentcraftFrame:IsShown(), "/ac opens")
  env:slash("")
  ok(not env.G.AgentcraftFrame:IsShown(), "/ac again closes")
  local L = env.ns.Layout
  for _, class in ipairs({ "HUNTER", "WARRIOR", "PALADIN", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }) do
    local keys = { false }
    for _, s in ipairs(L.Specs(class)) do keys[#keys + 1] = s.key end
    for _, sk in ipairs(keys) do
      local pages = L.ControllerPages(class, sk or nil)
      local e = pages and pages[3] and pages[3]["LT+RT Y"]
      ok(type(e) == "table" and e.macro == "Agentcraft",
        class .. (sk and (" " .. sk) or "") .. ": page 3 LT+RT Y is the Agentcraft macro")
    end
  end
  eq(#env:calls("CreateMacro"), 0, "nothing installed it")
  noErrors(env)
end)
