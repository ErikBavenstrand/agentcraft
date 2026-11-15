-- Dev capture (/ac capture): walks every page, view, sheet and a few focus
-- moves of the /ac window, takes a PNG screenshot of each state and stores
-- the window's frame tree geometry in AgentcraftDB.capture, so an agent on
-- this PC can see the real UI. scripts/wowdata.ps1 capture reads it back and
-- pairs each step with its screenshot. The user starts it; it never presses
-- keys, never applies anything, and refuses (or stops) in combat.
--   /ac capture [all|quick|<page id>] [noreload]   start (default all)
--   /ac capture stop                               stop and restore
--   /ac capture clear                              drop the stored run
-- luacheck: read globals GetPhysicalScreenSize debugprofilestop GetBuildInfo C_AddOnProfiler ReloadUI StaticPopup_Hide
-- luacheck: read globals StaticPopup_Show RELOADUI CANCEL
local _, ns = ...
local UI = ns.UI

local DC = {}
ns.DevCapture = DC -- ns.Capture is Core.lua's output capture

DC.MAX_OBJECTS = 4000   -- rows per step dump
DC.PROBE_MAX = 6000     -- objects watched by the flicker probe
DC.PROBE_TIME = 1.5     -- seconds of per-frame sampling
DC.SETTLE = 0.3         -- seconds after two frames before the dump; longer than the
                        -- focus ring intro (0.15 s, UI/Fx.lua) and the 0.12 s Inspector settle
DC.SPACING = 1.1        -- seconds between screenshots (file names have 1 s resolution)
DC.SHOT_TIMEOUT = 3

-- One tab-separated row per object; wowdata.ps1 maps them back by this list.
DC.FIELDS = { "path", "type", "shown", "vis", "alpha", "l", "b", "w", "h", "scale", "strata", "level", "layer",
  "points", "tex", "atlas", "tc", "atlasTc", "color", "text", "font", "trunc", "id", "name", "clip" }

local REGION_TYPES = { Texture = true, FontString = true, Line = true, MaskTexture = true }

-- Safe access ---------------------------------------------------------------------------

local function Secret(v) return issecretvalue and issecretvalue(v) end

-- obj:m(...) in a pcall; nothing when the method is missing or raises.
local function Call(obj, m, ...)
  local f = obj and obj[m]
  if type(f) ~= "function" then return end
  local r = { pcall(f, obj, ...) }
  if not r[1] then return end
  return unpack(r, 2, table.maxn(r))
end

local function Num(v, fmt)
  if v == nil or Secret(v) or type(v) ~= "number" then return "" end
  local s = string.format(fmt or "%.1f", v)
  s = s:gsub("(%.%d-)0+$", "%1"):gsub("%.$", "")
  if s == "-0" then s = "0" end
  return s
end

local function Str(v)
  if v == nil then return "" end
  if Secret(v) then return "<secret>" end
  return (tostring(v):gsub("[\t\r]", " "):gsub("\n", "\\n"))
end

local function Bool(v)
  if v == nil or Secret(v) then return "" end
  return v and "1" or "0"
end

local function TypeOf(obj) return Str(Call(obj, "GetObjectType")) end
local function IsRegion(obj) return REGION_TYPES[TypeOf(obj)] == true end

-- The step of a path for obj: its parentKey, else its global name, else
-- Type#index among its parent's regions (r) or children (c).
local function Key(obj, kind, i)
  local key = Call(obj, "GetParentKey")
  if type(key) == "string" and key ~= "" and not Secret(key) then return key end
  local name = Call(obj, "GetName")
  if type(name) == "string" and name ~= "" and not Secret(name) then return name end
  return TypeOf(obj) .. "#" .. kind .. i
end

-- Every object under root as a list plus obj -> path, plus obj -> its
-- nearest clipping ancestor (a ScrollFrame or a frame that clips children).
-- Hidden frames are listed but not entered unless all is true.
local function Collect(root, rootPath, cap, all)
  local list, paths, clips, truncated = {}, {}, {}, false
  local function visit(obj, path, clip)
    if paths[obj] then return end
    if #list >= cap then truncated = true return end
    list[#list + 1] = obj
    paths[obj], clips[obj] = path, clip
    if IsRegion(obj) then return end
    if not all and not Call(obj, "IsShown") then return end
    local inner = clip
    if TypeOf(obj) == "ScrollFrame" or Call(obj, "DoesClipChildren") == true then inner = obj end
    local regions = { Call(obj, "GetRegions") }
    -- A frame's own regions are clipped by its ancestors, not by itself.
    for i, r in ipairs(regions) do if type(r) == "table" then visit(r, path .. "/" .. Key(r, "r", i), clip) end end
    local children = { Call(obj, "GetChildren") }
    for i, c in ipairs(children) do if type(c) == "table" then visit(c, path .. "/" .. Key(c, "c", i), inner) end end
  end
  visit(root, rootPath, nil)
  return list, paths, truncated, clips
end
DC.Collect = Collect

-- Geometry dump ---------------------------------------------------------------------------

local function Points(obj, paths)
  local n = Call(obj, "GetNumPoints")
  if type(n) ~= "number" or Secret(n) or n == 0 then return "" end
  local out = {}
  for i = 1, math.min(n, 8) do
    local p, rel, rp, x, y = Call(obj, "GetPoint", i)
    if p then
      local relName = ""
      if type(rel) == "table" then relName = paths[rel] or Str(Call(rel, "GetDebugName")) end
      out[#out + 1] = string.format("%s@%s:%s(%s,%s)", Str(p), relName, Str(rp), Num(x), Num(y))
    end
  end
  return table.concat(out, ";")
end

local function TexFields(obj)
  local tex = Call(obj, "GetTexture")
  local atlas = Call(obj, "GetAtlas")
  local c = { Call(obj, "GetTexCoord") }
  local tc = ""
  if #c >= 8 then
    local def = { 0, 0, 0, 1, 1, 0, 1, 1 }
    local same = true
    for i = 1, 8 do
      if type(c[i]) ~= "number" or Secret(c[i]) or math.abs(c[i] - def[i]) > 0.0005 then same = false end
    end
    if not same then
      local s = {}
      for i = 1, 8 do s[i] = Num(c[i], "%.4f") end
      tc = table.concat(s, ",")
    end
  end
  -- A texcoord that differs from the atlas's own: SetTexCoord after SetAtlas.
  local atlasTc = ""
  if type(atlas) == "string" and atlas ~= "" and #c >= 8 and C_Texture and C_Texture.GetAtlasInfo then
    local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
    if ok and type(info) == "table" and info.leftTexCoord then
      local want = { info.leftTexCoord, info.topTexCoord, info.leftTexCoord, info.bottomTexCoord,
        info.rightTexCoord, info.topTexCoord, info.rightTexCoord, info.bottomTexCoord }
      atlasTc = "0"
      for i = 1, 8 do
        if type(c[i]) == "number" and not Secret(c[i]) and type(want[i]) == "number" and math.abs(c[i] - want[i]) > 0.001 then
          atlasTc = "1"
        end
      end
    end
  end
  local r, g, b, a = Call(obj, "GetVertexColor")
  local color = ""
  if type(r) == "number" and not Secret(r) and (r < 0.999 or (g or 1) < 0.999 or (b or 1) < 0.999 or (a or 1) < 0.999) then
    color = Num(r, "%.2f") .. "," .. Num(g, "%.2f") .. "," .. Num(b, "%.2f") .. "," .. Num(a or 1, "%.2f")
  end
  return Str(tex), Str(atlas), tc, atlasTc, color
end

-- "1" when obj lies wholly outside its clipping ancestor (scrolled out of
-- view), "p" when partly, else "". Compared in screen pixels.
local function Clipped(clip, l, b, w, h, s)
  if not clip or type(l) ~= "number" or Secret(l) then return "" end
  local cl, cb, cw, ch = Call(clip, "GetRect")
  local cs = Call(clip, "GetEffectiveScale") or 1
  if type(cl) ~= "number" or Secret(cl) or type(cs) ~= "number" or Secret(cs) then return "" end
  s = (type(s) == "number" and not Secret(s)) and s or 1
  local x1, y1, x2, y2 = l * s, b * s, (l + (w or 0)) * s, (b + (h or 0)) * s
  local c1, d1, c2, d2 = cl * cs, cb * cs, (cl + cw) * cs, (cb + ch) * cs
  if x2 <= c1 + 0.5 or x1 >= c2 - 0.5 or y2 <= d1 + 0.5 or y1 >= d2 - 0.5 then return "1" end
  if x1 < c1 - 0.5 or x2 > c2 + 0.5 or y1 < d1 - 0.5 or y2 > d2 + 0.5 then return "p" end
  return ""
end

-- One row (a string) for obj; short for hidden objects.
local function Row(obj, path, paths, clip)
  local typ = TypeOf(obj)
  local shown, vis = Call(obj, "IsShown"), Call(obj, "IsVisible")
  if not vis then return path .. "\t" .. typ .. "\t" .. Bool(shown) .. "\t0" end
  local l, b, w, h = Call(obj, "GetRect")
  local scale = Call(obj, "GetEffectiveScale")
  local v = {
    path, typ, Bool(shown), Bool(vis), Num(Call(obj, "GetEffectiveAlpha"), "%.2f"),
    Num(l), Num(b), Num(w), Num(h), Num(scale, "%.3f"),
  }
  local strata, level, layer
  level, layer = "", ""
  if REGION_TYPES[typ] then
    local dl, sub = Call(obj, "GetDrawLayer")
    layer = Str(dl) .. (sub and (":" .. Num(sub, "%d")) or "")
    local parent = Call(obj, "GetParent")
    strata = Str(Call(parent, "GetFrameStrata"))
  else
    strata, level = Str(Call(obj, "GetFrameStrata")), Num(Call(obj, "GetFrameLevel"), "%d")
  end
  v[11], v[12], v[13] = strata, level, layer
  v[14] = Points(obj, paths)
  local tex, atlas, tc, atlasTc, color, text, font, trunc = "", "", "", "", "", "", "", ""
  if typ == "Texture" or typ == "MaskTexture" or typ == "Line" then
    tex, atlas, tc, atlasTc, color = TexFields(obj)
  elseif typ == "FontString" then
    text = Str(Call(obj, "GetText"))
    if #text > 200 then text = text:sub(1, 200) .. "..." end
    local file, size, flags = Call(obj, "GetFont")
    font = Num(size) .. (flags and flags ~= "" and (":" .. Str(flags)) or "")
    if type(file) == "string" then font = font .. ":" .. (file:match("([^\\/]+)$") or file) end
    trunc = Bool(Call(obj, "IsTruncated"))
    local r, g, bl, a = Call(obj, "GetTextColor")
    if type(r) == "number" and not Secret(r) then
      color = Num(r, "%.2f") .. "," .. Num(g, "%.2f") .. "," .. Num(bl, "%.2f") .. "," .. Num(a or 1, "%.2f")
    end
  end
  v[15], v[16], v[17], v[18], v[19], v[20], v[21], v[22] = tex, atlas, tc, atlasTc, color, text, font, trunc
  v[23] = Str(rawget(obj, "acId"))
  v[24] = Str(Call(obj, "GetName"))
  v[25] = Clipped(clip, l, b, w, h, scale)
  return table.concat(v, "\t")
end

-- Rows for every object under root (and extra roots such as a popup).
-- With dict ({ list = {}, index = {} }), each path is stored once in
-- dict.list and rows (and anchor targets) name it as "#<n>": the run keeps
-- one path table for every step, which keeps the SavedVariables small.
function DC.Dump(root, extra, dict)
  local rows, truncated = {}, false
  local roots = { root }
  for _, r in ipairs(extra or {}) do roots[#roots + 1] = r end
  local all, labels, clipOf = {}, {}, {}
  for _, r in ipairs(roots) do
    local name = Call(r, "GetName")
    local list, paths, cut, clips = Collect(r, type(name) == "string" and name or TypeOf(r), DC.MAX_OBJECTS - #all)
    truncated = truncated or cut
    for _, obj in ipairs(list) do
      if not labels[obj] then
        local label = paths[obj]
        if dict then
          local n = dict.index[label]
          if not n then
            n = #dict.list + 1
            dict.list[n], dict.index[label] = label, n
          end
          label = "#" .. n
        end
        all[#all + 1], labels[obj], clipOf[obj] = obj, label, clips[obj]
      end
    end
  end
  for _, obj in ipairs(all) do
    local ok, row = pcall(Row, obj, labels[obj], labels, clipOf[obj])
    rows[#rows + 1] = ok and row or (labels[obj] .. "\t" .. TypeOf(obj) .. "\terror: " .. Str(row))
  end
  return rows, truncated
end

-- Flicker probe ---------------------------------------------------------------------------
-- Samples each watched object every frame: shown, own alpha and position.
-- A hit is an object that shows/hides twice or more, or whose alpha or
-- position reverses direction (a fade restarted, a jitter) within the probe.

local probe
local probeFrame = CreateFrame("Frame")

-- Call without the table Call builds: the probe runs every frame.
local function Fast(obj, m)
  local f = obj[m]
  if type(f) ~= "function" then return nil end
  local ok, v = pcall(f, obj)
  if ok then return v end
end

local function Round(v, step)
  if type(v) ~= "number" or Secret(v) then return nil end
  return math.floor(v / step + 0.5) * step
end

local function Recollect()
  -- Hidden frames are watched (their own shown flag) but not entered; a
  -- subtree that shows joins on the next re-collect (every 15 frames).
  local list, paths = Collect(probe.root, probe.rootPath, DC.PROBE_MAX, false)
  probe.list, probe.paths = list, paths
end

local function Note(st, t, kind, from, to)
  st.ev = st.ev or {}
  if #st.ev < 8 then st.ev[#st.ev + 1] = string.format("%.3f %s %s>%s", t, kind, tostring(from), tostring(to)) end
end

local function Track(st, key, val, t, eps)
  local last = st[key]
  if val == nil or last == nil then st[key] = val return end
  local d = val - last
  if math.abs(d) <= eps then return end
  local dir = d > 0 and 1 or -1
  local dk = key .. "dir"
  if st[dk] and st[dk] ~= dir then st.rev = (st.rev or 0) + 1 end
  st[dk] = dir
  st.changes = (st.changes or 0) + 1
  Note(st, t, key, last, val)
  st[key] = val
end

function DC.ProbeSample()
  if not probe then return end
  probe.frames = probe.frames + 1
  if probe.frames % 15 == 0 then Recollect() end
  local t = GetTime() - probe.t0
  for _, obj in ipairs(probe.list) do
    local st = probe.state[obj]
    local shown = Fast(obj, "IsShown") and true or false
    local alpha = Round(Fast(obj, "GetAlpha"), 0.01)
    local x, y
    if shown then x, y = Round(Fast(obj, "GetLeft"), 0.5), Round(Fast(obj, "GetBottom"), 0.5) end
    if not st then
      probe.state[obj] = { shown = shown, a = alpha, x = x, y = y }
    else
      if st.shown ~= shown then
        st.flips = (st.flips or 0) + 1
        st.changes = (st.changes or 0) + 1
        Note(st, t, "shown", st.shown and 1 or 0, shown and 1 or 0)
        st.shown = shown
      end
      Track(st, "a", alpha, t, 0.011)
      if shown then Track(st, "x", x, t, 0.6); Track(st, "y", y, t, 0.6) end
      if not st.hit and ((st.flips or 0) >= 2 or (st.rev or 0) >= 1) then
        st.hit = true
        probe.hits[#probe.hits + 1] = obj
      end
    end
  end
end

function DC.ProbeStart(root, rootPath)
  probe = { root = root, rootPath = rootPath or "AgentcraftFrame", t0 = GetTime(), frames = 0,
    state = setmetatable({}, { __mode = "k" }), hits = {} }
  if debugprofilestop then probe.p0 = debugprofilestop() end
  Recollect()
  probeFrame:SetScript("OnUpdate", function() DC.ProbeSample() end)
end

local function Metric(name)
  if not (C_AddOnProfiler and C_AddOnProfiler.GetAddOnMetric and Enum and Enum.AddOnProfilerMetric) then return nil end
  local m = Enum.AddOnProfilerMetric[name]
  if m == nil then return nil end
  local ok, v = pcall(C_AddOnProfiler.GetAddOnMetric, "Agentcraft", m)
  if ok and type(v) == "number" and not Secret(v) then return v end
end

-- Stops sampling; returns the probe summary table for the step record.
function DC.ProbeStop()
  probeFrame:SetScript("OnUpdate", nil)
  local p = probe
  probe = nil
  if not p then return nil end
  local out = { frames = p.frames, watched = #p.list, seconds = tonumber(Num(GetTime() - p.t0, "%.2f")), changed = 0, hits = {} }
  for obj, st in pairs(p.state) do
    if (st.changes or 0) > 0 then out.changed = out.changed + 1 end
    if st.hit then
      out.hits[#out.hits + 1] = { path = p.paths[obj] or "?", type = TypeOf(obj), flips = st.flips or 0,
        reversals = st.rev or 0, changes = st.changes or 0, events = table.concat(st.ev or {}, "; ") }
    end
  end
  table.sort(out.hits, function(a, b) return a.path < b.path end)
  while #out.hits > 200 do table.remove(out.hits) end
  out.recentAverageMs = Metric("RecentAverageTime")
  out.peakMs = Metric("PeakTime")
  return out
end

-- Driving the window ----------------------------------------------------------------------

local Focus = ns.Focus

local function Window() return ns.UI.Frame and ns.UI.Frame() end
local function Current() return ns.UI.CurrentPage and ns.UI.CurrentPage() end
local function Source() return (UI.PadMode and UI.PadMode()) and "pad" or "key" end

local function SortedPages()
  local list = {}
  for _, p in ipairs(ns.pages) do list[#list + 1] = p end
  table.sort(list, function(a, b)
    if (a.order or 500) ~= (b.order or 500) then return (a.order or 500) < (b.order or 500) end
    return tostring(a.id) < tostring(b.id)
  end)
  return list
end

local function Open(id) ns.OpenPage(id) end

-- Selects a view chip (as a click would), or sets page.view directly.
local function View(page, key)
  for i, v in ipairs(page.views or {}) do
    if v.key == key then
      if page.strip and page.strip.chips then page.strip.chips:Select(i)
      else
        page.view = key
        if page.OnView then pcall(page.OnView, page, key) end
        ns.UI.Refresh()
      end
      return true
    end
  end
end

-- Sets a strip toggle (mode, after) to index i through its own setter.
local function Toggle(page, key, i)
  if not i then return end
  for _, tg in ipairs(page.strip and page.strip.toggles or {}) do
    if tg.def and tg.def.key == key then tg:Set(i); return true end
  end
  for _, t in ipairs(page.toggles or {}) do
    if t.key == key and t.set then pcall(t.set, page, i); ns.UI.Refresh(); return true end
  end
end

local function NodeWhere(test)
  for _, n in ipairs(Focus:Nodes()) do if test(n) then return n end end
end

local function FocusFirst()
  local n = NodeWhere(function(x) return Focus.ZoneOf(x) == "stage" end) or Focus:Nodes()[1]
  if n then Focus:Set(n, Source()) end
  return n
end

local function Move(dir, times)
  for _ = 1, times or 1 do Focus:Move(dir, Source()) end
end

-- Focus the first row of a scroll list, then page past its fold.
local function ListFold()
  local n = NodeWhere(function(x) return rawget(x, "acScroll") ~= nil end)
  if not n then return "no scroll list here" end
  Focus:Set(n, Source())
  Focus:ListJump("PAGEDOWN")
  Focus:ListJump("PAGEDOWN")
end

-- Steps ------------------------------------------------------------------------------------
-- step = { name, page, apply(ctx) -> err?, after(ctx), probe = bool, shot = false }

local function PageSteps(page, ctx, opts)
  local id, s = page.id, {}
  local function add(name, apply, extra)
    local st = { name = id .. ":" .. name, page = id, apply = apply }
    for k, v in pairs(extra or {}) do st[k] = v end
    s[#s + 1] = st
  end
  local quick = opts.quick
  add("open", function()
    Open(id)
    ctx.saved[id] = { view = page.view, mode = page.mode, after = page.after }
  end, { probe = not quick })

  -- Each further view on the strip (Keyboard layers, Controller sets, Macros scope).
  for i, v in ipairs(page.views or {}) do
    if i > 1 then add("view-" .. v.key, function() View(page, v.key) end) end
  end
  local first = page.views and page.views[1] and page.views[1].key
  if first then add("view-reset", function() View(page, first) end, { shot = false }) end

  local hasMode, hasAfter = false, false
  for _, t in ipairs(page.toggles or {}) do
    if t.key == "mode" then hasMode = true end
    if t.key == "after" then hasAfter = true end
  end
  if hasMode then
    add("list", function()
      local was = ctx.saved[id] and ctx.saved[id].mode or 1
      Toggle(page, "mode", was == 2 and 1 or 2)
    end)
    if not quick then
      add("list-focus", function() FocusFirst(); Move("DOWN", 2) end, { probe = true })
      add("list-fold", function() return ListFold() end)
    end
    add("mode-reset", function() Toggle(page, "mode", ctx.saved[id] and ctx.saved[id].mode) end, { shot = false })
  end
  if hasAfter then
    add("now", function()
      local was = ctx.saved[id] and ctx.saved[id].after or 2
      Toggle(page, "after", was == 1 and 2 or 1)
    end)
    add("after-reset", function() Toggle(page, "after", ctx.saved[id] and ctx.saved[id].after) end, { shot = false })
  end

  if id == "macros" then
    add("page-2", function()
      if not page.ListJump then return "no ListJump" end
      page:ListJump("PAGEDOWN")
    end, { after = function() if page.ListJump then page:ListJump("HOME") end end })
    add("tag", function()
      for _, c in ipairs(page.chips or {}) do
        if c:IsShown() and c.tagKey then ctx.tagChip = c; c:Click(); return end
      end
      return "no tag chip shown"
    end, { after = function() if ctx.tagChip then ctx.tagChip:Click(); ctx.tagChip = nil end end })
  end

  if id == "options" then
    add("log", function()
      if not page.OpenLog then return "no log view" end
      page:OpenLog()
    end, { after = function() if page.CloseLog then page:CloseLog(true); ns.UI.Refresh() end end })
    add("toast", function() ns.UI.ShowToast("Dev capture: sample toast", "result") end)
    add("confirm", function()
      if not UI.Confirm then return "no UI.Confirm" end
      ctx.popup = UI.Confirm("Agentcraft dev capture: sample dialog. Yes and No do nothing.", function() end)
      if type(ctx.popup) ~= "table" then ctx.popup = nil end
    end, { after = function()
      if StaticPopup_Hide then pcall(StaticPopup_Hide, "AGENTCRAFT_CONFIRM") end
      if ctx.popup and ctx.popup.Hide then ctx.popup:Hide() end
      ctx.popup = nil
    end })
  end

  -- Review can be set per Refresh (Macros sets it only while no single card
  -- is installable), so check again when the step runs.
  if page.Review or page.Commit or page.reviewLabel then
    add("review", function()
      if not page.Review then return "no Review sheet in this state" end
      ns.UI.OpenReview()
    end, { after = function() ns.UI.CloseReview() end, probe = not quick })
    if not quick then
      add("review-fold", function()
        if not page.Review then return "no Review sheet in this state" end
        ns.UI.OpenReview()
        return ListFold()
      end, { after = function() ns.UI.CloseReview() end })
    end
  end

  if not quick then
    add("focus-first", function() return FocusFirst() == nil and "no focus node" or nil end, { probe = true })
    add("focus-right", function() Move("RIGHT", 2) end, { probe = true })
    add("focus-down", function() Move("DOWN", 2) end, { probe = true })
  end
  return s
end

-- The whole run for suite "all", "quick" or a page id.
function DC.BuildSteps(suite, ctx)
  ctx = ctx or { saved = {} }
  ctx.saved = ctx.saved or {}
  suite = suite or "all"
  local quick = suite == "quick"
  local only = (suite ~= "all" and suite ~= "quick") and ns.PageById(suite) or nil
  local steps = {}
  local pages = {}
  for _, p in ipairs(SortedPages()) do
    if not only or p == only then pages[#pages + 1] = p end
  end
  for _, p in ipairs(pages) do
    for _, st in ipairs(PageSteps(p, ctx, { quick = quick })) do steps[#steps + 1] = st end
  end
  -- Controller prompts (glyphs, LB/RB): the open view of each page again.
  if not quick then
    steps[#steps + 1] = { name = "pad:on", shot = false, apply = function()
      ns.db.prompts = "pad"
      if UI.RefreshPrompts then UI.RefreshPrompts() end
      ns.UI.Refresh()
    end }
    for _, p in ipairs(pages) do
      local id = p.id
      steps[#steps + 1] = { name = "pad:" .. id, page = id, apply = function() Open(id); FocusFirst() end }
    end
    steps[#steps + 1] = { name = "pad:off", shot = false, apply = function()
      ns.db.prompts = ctx.prompts
      if UI.RefreshPrompts then UI.RefreshPrompts() end
      ns.UI.Refresh()
    end }
  end
  return steps, ctx
end

-- Runner -----------------------------------------------------------------------------------

local run -- the active run: { steps, i, ctx, record, ... }
local events = CreateFrame("Frame")

local function After(sec, fn)
  C_Timer.After(sec, function()
    if run and not run.done then fn() end
  end)
end

local function GetCV(name)
  if C_CVar and C_CVar.GetCVar then
    local ok, v = pcall(C_CVar.GetCVar, name)
    if ok then return v end
  end
end
local function SetCV(name, v)
  if v ~= nil and C_CVar and C_CVar.SetCVar then pcall(C_CVar.SetCVar, name, v) end
end

local function Restore(r)
  if r.restored then return end
  r.restored = true
  if Focus then Focus.ignoreMouse = nil end
  DC.ProbeStop()
  events:UnregisterEvent("SCREENSHOT_SUCCEEDED")
  events:UnregisterEvent("SCREENSHOT_FAILED")
  SetCV("screenshotFormat", r.cvars.screenshotFormat)
  SetCV("screenshotQuality", r.cvars.screenshotQuality)
  if ns.db then ns.db.prompts = r.ctx.prompts end
  if UI.RefreshPrompts then pcall(UI.RefreshPrompts) end
  pcall(ns.UI.CloseReview)
  if StaticPopup_Hide then pcall(StaticPopup_Hide, "AGENTCRAFT_CONFIRM") end
  local f = Window()
  for id, s in pairs(r.ctx.saved) do
    local page = ns.PageById(id)
    if page and page.frame then
      if s.view and page.view ~= s.view then pcall(View, page, s.view) end
      if s.mode and page.mode ~= s.mode then pcall(Toggle, page, "mode", s.mode) end
      if s.after and page.after ~= s.after then pcall(Toggle, page, "after", s.after) end
    end
  end
  if f and f:IsShown() then
    if r.startPage then pcall(ns.OpenPage, r.startPage) end
    if not r.wasShown and not InCombatLockdown() then pcall(ns.ToggleUI) end
  end
  if ns.db then ns.db.lastPage = r.lastPage end
end

local function Finish(reason)
  local r = run
  if not r or r.done then return end
  r.done = true
  Restore(r)
  local rec = r.record
  rec.finished = date("%Y-%m-%d %H:%M:%S")
  rec.stopped = reason
  local shots, failed, hits = 0, 0, 0
  for _, s in ipairs(rec.steps) do
    if s.shot and s.shot.ok then shots = shots + 1 elseif s.shot then failed = failed + 1 end
    if s.probe then hits = hits + #s.probe.hits end
  end
  rec.summary = { steps = #rec.steps, screenshots = shots, failedScreenshots = failed, flickerHits = hits }
  run = nil
  if reason then
    ns.Print("Capture stopped (" .. reason .. ") after " .. #rec.steps .. " steps. Type /reload to save what was captured.")
    return
  end
  ns.Print(string.format("Capture done: %d steps, %d screenshots%s, %d flicker hits.", #rec.steps, shots,
    failed > 0 and (", " .. failed .. " failed") or "", hits))
  if r.noReload then
    ns.Print("Type /reload to write the capture to disk.")
    return
  end
  ns.Print("Reloading to write the capture to disk. If nothing happens, type /reload.")
  C_Timer.After(1, function()
    if not InCombatLockdown() and ReloadUI then pcall(ReloadUI) end
    -- Still here a second later: the client refused a reload that no key or
    -- click started (the real client did, so nothing reached disk). A click
    -- on the dialog is a hardware event, which ReloadUI accepts.
    C_Timer.After(1, function() DC.AskReload() end)
  end)
end

-- A dialog with a Reload button, plus the instruction in chat.
function DC.AskReload()
  ns.Print("Capture done — click Reload in the dialog, or type /reload, to write it to disk.")
  if not (StaticPopupDialogs and StaticPopup_Show) then return end
  local dialogs = StaticPopupDialogs
  if not dialogs.AGENTCRAFT_CAPTURE_RELOAD then -- luacheck: ignore 143
    dialogs.AGENTCRAFT_CAPTURE_RELOAD = { -- luacheck: ignore 142
      text = "Agentcraft capture done.\nReload the UI to write it to disk?",
      button1 = RELOADUI or "Reload",
      button2 = CANCEL or "Cancel",
      OnAccept = function() if ReloadUI then ReloadUI() end end,
      timeout = 0,
      whileDead = 1,
      hideOnEscape = 1,
      preferredIndex = 3,
    }
  end
  StaticPopup_Show("AGENTCRAFT_CAPTURE_RELOAD")
end

local Next

local function Shoot(st, rec)
  local r = run
  local wait = 0
  if r.lastShot then wait = math.max(0, r.lastShot + DC.SPACING - GetTime()) end
  After(wait, function()
    rec.shot = { time = date("%m%d%y_%H%M%S"), ms = debugprofilestop and debugprofilestop() or nil }
    r.lastShot = GetTime()
    r.waiting = { rec = rec, st = st }
    local token = {}
    r.waiting.token = token
    local ok, err = pcall(Screenshot)
    if not ok then
      rec.shot.ok, rec.shot.err = false, Str(err)
      r.waiting = nil
      return Next()
    end
    After(DC.SHOT_TIMEOUT, function()
      if r.waiting and r.waiting.token == token then
        rec.shot.ok, rec.shot.err = false, "timeout"
        r.waiting = nil
        Next()
      end
    end)
  end)
end

local function Settled(st, rec, tries)
  local f = Window()
  local valid = Call(f, "IsRectValid")
  if valid == false and tries < 10 then
    return After(0, function() Settled(st, rec, tries + 1) end)
  end
  rec.rectValid = valid ~= false
  local cur = Current()
  rec.currentPage = cur and cur.id or nil
  rec.view, rec.mode, rec.after = cur and cur.view, cur and cur.mode, cur and cur.after
  rec.prompts = UI.PromptMode and UI.PromptMode() or nil
  local n = Focus.current
  rec.focus = n and (rawget(n, "acId") or Str(Call(n, "GetDebugName"))) or nil
  rec.focusZone = n and Focus.ZoneOf(n) or nil
  rec.window = { Call(f, "GetRect") }
  rec.windowScale = Call(f, "GetEffectiveScale")
  rec.ms = debugprofilestop and debugprofilestop() or nil
  rec.rows, rec.truncated = DC.Dump(f, run.ctx.popup and { run.ctx.popup } or nil, run.dict)
  Shoot(st, rec)
end

local function AfterApply(st, rec)
  After(0, function()
    After(0, function()
      After(DC.SETTLE, function() Settled(st, rec, 0) end)
    end)
  end)
end

Next = function()
  local r = run
  if not r or r.done then return end
  local prev = r.steps[r.i]
  if prev and prev.after then
    local ok, err = pcall(prev.after, r.ctx)
    if not ok then r.record.errors[#r.record.errors + 1] = prev.name .. " (after): " .. Str(err) end
  end
  r.i = r.i + 1
  local st = r.steps[r.i]
  if not st then return Finish() end
  local f = Window()
  if not f or not f:IsShown() then return Finish("the window was closed") end
  local rec = { name = st.name, page = st.page, index = #r.record.steps + 1 }
  local ok, err = pcall(st.apply, r.ctx)
  if not ok then rec.error = Str(err) elseif type(err) == "string" then rec.note = err end
  if st.shot == false then
    if rec.error then r.record.errors[#r.record.errors + 1] = st.name .. ": " .. rec.error end
    return After(0, Next)
  end
  r.record.steps[#r.record.steps + 1] = rec
  if st.probe then
    DC.ProbeStart(f, "AgentcraftFrame")
    After(DC.PROBE_TIME, function()
      rec.probe = DC.ProbeStop()
      AfterApply(st, rec)
    end)
  else
    AfterApply(st, rec)
  end
end

events:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_REGEN_DISABLED" then
    if run and not run.done then Finish("combat started") end
    return
  end
  local r = run
  if not (r and r.waiting) then return end
  local rec = r.waiting.rec
  r.waiting = nil
  rec.shot.ok = event == "SCREENSHOT_SUCCEEDED"
  if not rec.shot.ok then rec.shot.err = "SCREENSHOT_FAILED" end
  After(0, Next)
end)
events:RegisterEvent("PLAYER_REGEN_DISABLED")

function DC.Running() return run ~= nil end

function DC.Start(args)
  args = tostring(args or "")
  local words = {}
  for w in args:lower():gmatch("%S+") do words[#words + 1] = w end
  local suite, noReload = "all", false
  for _, w in ipairs(words) do
    if w == "noreload" then noReload = true else suite = w end
  end
  if suite == "stop" then
    if run then Finish("stopped by /ac capture stop") else ns.Print("No capture is running.") end
    return
  end
  if suite == "clear" then
    if ns.db then ns.db.capture = nil end
    return ns.Print("Stored capture cleared (on disk after /reload).")
  end
  if InCombatLockdown() then return ns.Print("Not in combat: start the capture after combat ends.") end
  if run then return ns.Print("A capture is already running. /ac capture stop ends it.") end
  if not (Screenshot and C_Timer) then return ns.Print("Screenshots aren't available on this client.") end
  if suite ~= "all" and suite ~= "quick" and not ns.PageById(suite) then
    return ns.Print("Unknown suite '" .. suite .. "'. Use all, quick or a page id (keyboard, controller, macros, options).")
  end
  local f = Window()
  local wasShown = f and f:IsShown() or false
  local cur = Current()
  local ctx = { saved = {}, prompts = ns.db and ns.db.prompts }
  local steps = DC.BuildSteps(suite, ctx)
  local build = { GetBuildInfo and GetBuildInfo() }
  local sw, sh
  if GetPhysicalScreenSize then sw, sh = GetPhysicalScreenSize() end
  local record = {
    runId = date("%Y%m%d_%H%M%S"), started = date("%Y-%m-%d %H:%M:%S"), suite = suite,
    version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("Agentcraft", "Version") or nil,
    build = { version = build[1], build = build[2], date = build[3], toc = build[4] },
    screen = { w = sw, h = sh },
    ui = { w = UIParent:GetWidth(), h = UIParent:GetHeight(), scale = UIParent:GetEffectiveScale() },
    fields = DC.FIELDS, paths = {}, steps = {}, errors = {},
  }
  ns.db.capture = record
  -- The cursor stays wherever it was parked; a refresh that lays a node
  -- under it must not move the focus the steps set (steps 01-06 of the
  -- first real capture inspected an Inspector link under the cursor).
  if Focus then Focus.ignoreMouse = true end
  run = {
    steps = steps, i = 0, ctx = ctx, record = record, noReload = noReload, wasShown = wasShown,
    dict = { list = record.paths, index = {} },
    startPage = cur and cur.id, lastPage = ns.db.lastPage,
    cvars = { screenshotFormat = GetCV("screenshotFormat"), screenshotQuality = GetCV("screenshotQuality") },
  }
  record.cvars = run.cvars
  SetCV("screenshotFormat", "png")
  SetCV("screenshotQuality", "10")
  events:RegisterEvent("SCREENSHOT_SUCCEEDED")
  events:RegisterEvent("SCREENSHOT_FAILED")
  local shots = 0
  for _, st in ipairs(steps) do if st.shot ~= false then shots = shots + 1 end end
  ns.Print(string.format("Capture started: %d screenshots, about %d s. Don't touch the mouse or keys (park the cursor outside the window); /ac capture stop ends it.",
    shots, math.floor(shots * 1.6 + 0.5)))
  if not wasShown then ns.ToggleUI() end
  After(0.2, Next)
end

ns.RegisterCommand("capture", "screenshot every page, view and sheet of this window with its geometry (for agents)",
  function(arg) DC.Start(arg) end, { usage = "capture [all|quick|<page>|stop|clear] [noreload]" })
