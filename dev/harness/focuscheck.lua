-- Focus graph checks for the /ac window (dev/ui-spec-v2.md §11.4), shared by
-- dev/render/render.lua and dev/tests/14_focus.lua.
--
--   local FC = require("focuscheck")
--   local r = FC.Walk(env)     -- the page shown now, from its landing focus
--   r.unreachable  nodes a walk from the landing focus (arrows/D-pad plus
--                  Tab/Shift-Tab) never reaches: the keyboard check
--   r.arrowUnreachable  page nodes (not Inspector) the D-pad never reaches
--                  (arrows, plus A on a node whose acActivate steps into the
--                  Inspector); Tab hops are not counted, a controller has no
--                  Tab: a pad check. r.arrowUnreachableIds: their labels.
--   r.noInspectorEntry  nodes whose Inspector has links/buttons that the pad
--                  can't enter (no move or A lands in it, and no pin + right
--                  edge): a pad check. r.noInspectorEntryIds: their labels.
--   r.actEdges[node] = the Inspector node A on it lands on
--   r.deadends     nodes reached that have no exit at all, or from which the
--                  landing focus can't be reached again (a one-way trap)
--   r.small        focus nodes under 28 px in either side (pad variant check)
--   r.nodes, r.start, r.edges[node][dir] = target
--
-- The walk presses real moves (Focus:Move), so explicit nav* functions run as
-- in game. A move that stays put on a stepping row (an Options choice or the
-- scale slider: Left/Right change the value first) is pressed again until it
-- leaves or stops changing. Settings and scale are put back afterwards. After
-- standing on each node the walk runs timers for 0.3 s (opts.settle = false
-- skips it), so the Inspector's 0.12 s settle has happened, as when the player
-- moves at normal speed.
local FC = {}

local DIRS = { "UP", "DOWN", "LEFT", "RIGHT" }
FC.DIRS = DIRS
FC.MIN_TARGET = 28

local function Copy(t, seen)
  if type(t) ~= "table" then return t end
  seen = seen or {}
  if seen[t] then return seen[t] end
  local c = {}
  seen[t] = c
  for k, v in pairs(t) do c[k] = Copy(v, seen) end
  return c
end

-- Puts src's values back into dst, keeping dst's own subtables (modules hold
-- references to them).
local function Restore(dst, src)
  for k in pairs(dst) do if src[k] == nil then dst[k] = nil end end
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then Restore(dst[k], v) else dst[k] = v end
  end
end

local function Label(n)
  local id = rawget(n, "acId") or rawget(n, "_name")
  if id then return tostring(id) end
  local text = rawget(n, "_text") or (type(n.GetText) == "function" and n:GetText()) or nil
  local site = rawget(n, "_site")
  return string.format("%s#%s%s%s", tostring(rawget(n, "_type") or "Frame"), tostring(n._id or "?"),
    text and (" '" .. tostring(text) .. "'") or "", site and (" [" .. site .. "]") or "")
end
FC.Label = Label

-- The Gamepad UI model (SmartNavigation, forever branch: Utility.lua
-- Utility.FindButtons / SmartNavigation_CanFocusFrame / IsFrameIgnored):
-- every shown frame under root that is a Button (CheckButton, DropdownButton
-- too) or an EditBox, or has an OnMouseDown / OnMouseUp script, and that no
-- SmartNavigation_MarkFrameIgnored mark covers (its own, or an ancestor's
-- that propagates). The D-pad can stop on each of them.
local SN_TYPES = { Button = true, CheckButton = true, DropdownButton = true, EditBox = true, ItemButton = true }
local function SNIgnored(f)
  if rawget(f, "_snIgnoredSelf") then return true end
  local o = f
  while o do
    if rawget(o, "_snIgnored") then return true end
    o = o.GetParent and o:GetParent()
  end
  return false
end
FC.SNIgnored = SNIgnored

function FC.SmartNavTargets(root)
  local out = {}
  local function walk(f, isRoot)
    if f.IsShown and not f:IsShown() then return end
    if not isRoot and not SNIgnored(f) and not rawget(f, "_snContainer") then
      local t = rawget(f, "_type")
      local scripts = rawget(f, "_scripts") or {}
      local w, h = f:GetWidth(), f:GetHeight()
      if (SN_TYPES[t] or scripts.OnMouseDown or scripts.OnMouseUp) and (w or 0) > 0 and (h or 0) > 0 then
        out[#out + 1] = f
      end
    end
    if f.GetChildren then for _, c in ipairs({ f:GetChildren() }) do walk(c) end end
  end
  walk(root, true)
  return out
end

-- Gamepad UI coverage of what is shown now:
--   r.phantoms  frames the Gamepad UI can stop on that are not focus nodes
--               (no Inspector, A does a bare click or nothing, and the
--               window's own moves never lead back): mark them
--               UI.MarkIgnored, make them nodes, or set acDecorative
--   r.hidden    usable focus nodes the Gamepad UI can't reach (an ignore
--               mark covers them)
--   r.inert     usable nodes A does nothing on: no acActivate, no OnClick,
--               not an EditBox. Fine: read-only acReadable nodes that are
--               disabled, and nodes whose acPromptA is (or returns) false:
--               they say A has no job there, and the A prompt hides
function FC.PadCoverage(env)
  local Focus = env.ns.Focus
  local root = Focus:Root()
  local r = { phantoms = {}, hidden = {}, inert = {} }
  if not root then return r end
  for _, f in ipairs(FC.SmartNavTargets(root)) do
    if not rawget(f, "acNode") and not rawget(f, "acDecorative") and not rawget(f, "acSkip") then
      r.phantoms[#r.phantoms + 1] = f
    end
  end
  for _, n in ipairs(Focus:Nodes()) do
    if SNIgnored(n) then r.hidden[#r.hidden + 1] = n end
    local scripts = rawget(n, "_scripts") or {}
    local readOnly = n.IsEnabled and not n:IsEnabled() and rawget(n, "acReadable")
    local pa = rawget(n, "acPromptA")
    if type(pa) == "function" then pa = pa(n) end
    if pa == false then readOnly = true end
    if not readOnly and not rawget(n, "acActivate") and not scripts.OnClick and rawget(n, "_type") ~= "EditBox" then
      r.inert[#r.inert + 1] = n
    end
  end
  return r
end

function FC.Walk(env, opts)
  opts = opts or {}
  local ns = env.ns
  local Focus = ns.Focus
  local UI = ns.UI
  local savedDb = Copy(ns.db or {})
  -- Choice rows on a page (the spec picker) step a per-character value.
  local savedCharSpec = ns.charDB and ns.charDB.spec
  local savedScale = UI.GetScale and UI.GetScale()
  local start = Focus.current
  if not start or not Focus.Usable(start) then start = Focus:Restore() end
  -- The node set as the player sees it on landing: the Inspector settled on
  -- the landing focus (not whatever it explained before).
  if start and opts.settle ~= false and env.runTimers then
    Focus:Set(start, "key", true, true)
    env:runTimers(0.3)
    if not Focus.Usable(start) then start = Focus:Restore() end
  end
  local initial = Focus:Nodes()
  local result = { start = start, nodes = initial, edges = {}, unreachable = {}, deadends = {}, deadendKeys = {}, small = {} }
  if not start then return result end

  -- Nodes are keyed by acId when they have one: Inspector rows are pooled, so
  -- one frame carries different ids as the subject changes. (An Inspector
  -- link with the same id under two subjects is one node here; whether each
  -- subject's Inspector can be entered on the pad is r.noInspectorEntry.)
  local function Key(f) return rawget(f, "acId") or f end
  local initialKeys = {}
  for _, n in ipairs(initial) do initialKeys[n] = Key(n) end
  local frameOf, context = {}, {}
  local startKey = Key(start)
  local seen, order, queue = { [startKey] = true }, { startKey }, { startKey }
  frameOf[startKey] = start
  local tabEdges, actEdges, stale, lost = {}, {}, {}, {}
  local zone, hasInsp = {}, {} -- per key: its focus zone; true when its Inspector has nodes
  -- What the Inspector explained when each Inspector node was found: its
  -- buttons and links belong to that subject, so the walk shows it again
  -- before standing on the node.
  local function Visit(target)
    local k = Key(target)
    if not seen[k] then
      if Focus.ZoneOf(target) == "inspector" then context[k] = Focus.inspected end
      seen[k] = true
      frameOf[k] = target
      order[#order + 1] = k
      queue[#queue + 1] = k
    end
    return k
  end
  -- The page's own view state (the Macros book's page number, a view, a
  -- filter) goes back to how it was before each node is stood on, so a move
  -- that turned a page doesn't change which nodes the rest of the walk sees.
  local page = Focus.getPage and Focus.getPage()
  local pageState = {}
  if type(page) == "table" then
    for k, v in pairs(page) do
      local t = type(v)
      if t == "number" or t == "string" or t == "boolean" then pageState[k] = v end
    end
  end
  local function ResetPage()
    if type(page) ~= "table" then return end
    local changed = false
    for k, v in pairs(pageState) do if page[k] ~= v then page[k] = v; changed = true end end
    if changed and UI.Refresh then pcall(UI.Refresh) end
  end
  -- The frame carrying key now (nil when none is usable).
  local function Resolve(k)
    local f = frameOf[k]
    if type(k) ~= "string" then return Focus.Usable(f) and f or nil end
    if f and rawget(f, "acId") == k and Focus.Usable(f) then return f end
    for _, n in ipairs(Focus:Nodes()) do if rawget(n, "acId") == k then return n end end
  end
  -- Focus key k the way a player does: set it, then let the Inspector settle.
  -- Returns the frame, or nil plus "stale" (gone before) or "lost" (gone after).
  local function Stand(k)
    ResetPage()
    local ctx = context[k]
    if ctx and ctx ~= Focus.inspected and Focus.Usable(ctx) then Focus:Inspect(ctx) end
    local f = Resolve(k)
    if not f then return nil, "stale" end
    Focus:Set(f, "key", true, true)
    if opts.settle ~= false and env.runTimers then env:runTimers(0.3) end
    if Focus.current ~= f or not Focus.Usable(f) or Key(f) ~= k then return nil, "lost" end
    return f
  end
  local qi = 1
  while qi <= #queue do
    local k = queue[qi]; qi = qi + 1
    result.edges[k], tabEdges[k] = {}, {}
    local f, why = Stand(k)
    if not f then
      if why == "stale" then stale[k] = true else lost[k] = true end
    else
      zone[k] = Focus.ZoneOf(f)
      -- Only a node with its own Inspector content (acInspect); others show
      -- the page's default pane, which the pad reaches from any subject.
      if zone[k] ~= "inspector" and f.acInspect then
        for _, n in ipairs(Focus:Nodes()) do
          if Focus.ZoneOf(n) == "inspector" then hasInsp[k] = true break end
        end
      end
      for _, dir in ipairs(DIRS) do
        f = Stand(k)
        if f then
          Focus:Move(dir, "key")
          local target = Focus.current
          -- Stepping rows: keep pressing while the move changes something but stays.
          local tries = 0
          local nav = f["nav" .. dir:sub(1, 1) .. dir:sub(2):lower()]
          while target == f and type(nav) == "function" and tries < 30 do
            tries = tries + 1
            local before = Copy(ns.db or {})
            local beforeValue = type(f.ValueText) == "function" and f:ValueText() or nil
            Focus:Move(dir, "key")
            target = Focus.current
            local changed = beforeValue ~= nil and f:ValueText() ~= beforeValue
            for key, v in pairs(ns.db or {}) do if type(v) ~= "table" and before[key] ~= v then changed = true end end
            if not changed then break end
          end
          if target and target ~= f then result.edges[k][dir] = Visit(target) end
        end
      end
      -- A on a node with its own acActivate (a key, slot or macro card pins
      -- itself and steps into the Inspector): a pad move too. Plain buttons
      -- (default Click) are not pressed, so the walk never runs an action.
      f = Stand(k)
      if f and type(rawget(f, "acActivate")) == "function" and Focus.ZoneOf(f) ~= "inspector" then
        for _ = 1, 2 do -- a macro card's first A selects it, the second steps in
          Focus:Activate("pad")
          if Focus.current ~= f then break end
        end
        local target = Focus.current
        if target and target ~= f and Focus.ZoneOf(target) == "inspector" then actEdges[k] = Visit(target) end
        while Focus.pinned do Focus:Unpin() end
        if ns.Esc and ns.Esc.Remove then pcall(ns.Esc.Remove, "pin") end
      end
      -- Tab / Shift-Tab (keyboard zone hops) count for reachability only.
      for _, delta in ipairs({ 1, -1 }) do
        f = Stand(k)
        if f then
          Focus:NextZone(delta)
          local target = Focus.current
          if target and target ~= f then tabEdges[k][#tabEdges[k] + 1] = Visit(target) end
        end
      end
    end
  end

  -- Back-reachability to the landing focus over the arrow edges.
  local back = { [startKey] = true }
  local grew = true
  while grew do
    grew = false
    for _, k in ipairs(order) do
      if not back[k] then
        for _, t in pairs(result.edges[k]) do
          if back[t] then back[k] = true; grew = true break end
        end
      end
    end
  end

  -- Forward reachability over the arrow edges alone: a controller has no Tab,
  -- so a node only Tab finds is out of reach on the pad.
  local fwd, fq = { [startKey] = true }, { startKey }
  local fi = 1
  while fi <= #fq do
    local k = fq[fi]; fi = fi + 1
    for _, t in pairs(result.edges[k] or {}) do
      if not fwd[t] then fwd[t] = true; fq[#fq + 1] = t end
    end
    local a = actEdges[k]
    if a and not fwd[a] then fwd[a] = true; fq[#fq + 1] = a end
  end
  result.arrowUnreachable = {}
  for _, n in ipairs(initial) do
    if not seen[initialKeys[n]] then result.unreachable[#result.unreachable + 1] = n end
  end
  -- Every page node the walk found. Inspector nodes are left to the entry
  -- check below: they belong to one subject each, and pooled rows share ids.
  -- arrowUnreachableIds: the key's own label (a pooled frame may carry
  -- another id by now).
  result.arrowUnreachableIds = {}
  local function AddArrow(f, k)
    result.arrowUnreachable[#result.arrowUnreachable + 1] = f
    result.arrowUnreachableIds[#result.arrowUnreachableIds + 1] = type(k) == "string" and k or Label(f)
  end
  for _, k in ipairs(order) do
    if not fwd[k] and not stale[k] and zone[k] ~= "inspector" then AddArrow(frameOf[k], k) end
  end
  for _, n in ipairs(result.unreachable) do AddArrow(n, initialKeys[n]) end

  -- Pad entry into each subject's Inspector: from the node itself, Right (or
  -- any move) lands in the Inspector, or A steps in (actEdges), or the node
  -- pins on A (it has SetPinned) and some page node's move enters the pinned
  -- Inspector (the right edge). Without one, that subject's Inspector links
  -- and buttons need Tab.
  local edgeEntry = false
  for _, k in ipairs(order) do
    if zone[k] and zone[k] ~= "inspector" then
      for _, t in pairs(result.edges[k] or {}) do if zone[t] == "inspector" then edgeEntry = true end end
    end
  end
  result.noInspectorEntry, result.noInspectorEntryIds = {}, {}
  for _, k in ipairs(order) do
    if hasInsp[k] and not lost[k] then
      local entry = actEdges[k] ~= nil
      for _, t in pairs(result.edges[k] or {}) do if zone[t] == "inspector" then entry = true end end
      local f = frameOf[k]
      if not entry and edgeEntry and f and type(rawget(f, "SetPinned")) == "function" then entry = true end
      if not entry then
        result.noInspectorEntry[#result.noInspectorEntry + 1] = f
        result.noInspectorEntryIds[#result.noInspectorEntryIds + 1] = type(k) == "string" and k or Label(f)
      end
    end
  end
  for _, k in ipairs(order) do
    if not stale[k] and (lost[k] or next(result.edges[k]) == nil or not back[k]) then
      result.deadends[#result.deadends + 1] = frameOf[k]
      result.deadendKeys[#result.deadendKeys + 1] = k
    end
  end
  result.lost, result.stale, result.tabEdges, result.frameOf = lost, stale, tabEdges, frameOf
  result.actEdges = actEdges
  for _, n in ipairs(initial) do
    local w, h = n:GetWidth(), n:GetHeight()
    if w and h and (w < FC.MIN_TARGET or h < FC.MIN_TARGET) and not rawget(n, "acSmallOK") then
      result.small[#result.small + 1] = n
    end
  end
  result.order = order -- keys (acId or frame); result.frameOf maps them

  -- Put everything back.
  Restore(ns.db, savedDb)
  if ns.charDB then ns.charDB.spec = savedCharSpec end
  if savedScale and UI.SetScale then pcall(UI.SetScale, savedScale) end
  if UI.RefreshPrompts then pcall(UI.RefreshPrompts) end
  if UI.Refresh then pcall(UI.Refresh) end
  if Focus.Usable(start) then Focus:Set(start, "key", true) end
  return result
end

return FC
