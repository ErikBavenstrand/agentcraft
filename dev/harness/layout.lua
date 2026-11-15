-- Layout solver: turns the frame model's anchors (dev/harness/frames.lua)
-- into absolute rectangles in screen pixels.
--
--   local s = layout.New(W, { w = 1280, h = 800 })
--   local r = s:Rect(obj)   -- { l, r, t, b, scale } (t < b: y grows down) or nil
--   s.problems[obj]         -- why obj has no rectangle (cycle, no anchors, ...)
--
-- WoW semantics: anchors are y-up (positive y moves up); a point with no
-- relativeTo is relative to the parent; offsets and sizes are in the region's
-- effective scale (product of SetScale up the parent chain). A scroll child
-- sits at its scroll frame's top-left and keeps its own size. UIParent (and a
-- frame with no parent) is the whole screen.
local frames = require("frames")

local L = {}
local Solver = {}
Solver.__index = Solver

function L.New(W, screen)
  return setmetatable({ W = W, screen = screen or W.screen or { w = 1280, h = 800 }, cache = {}, visiting = {},
    stack = {}, problems = {}, notes = {} }, Solver)
end

local function Label(o)
  if o._name then return o._name end
  return o._type .. "#" .. tostring(o._id) .. (o._site and (" (" .. o._site .. ")") or "")
end
L.Label = Label

function Solver:Scale(o)
  local s = 1
  while o do s = s * (o._scale or 1); o = o._parent end
  return s
end

local function AnchorX(r, point)
  if point:find("LEFT") then return r.l elseif point:find("RIGHT") then return r.r end
  return (r.l + r.r) / 2
end
local function AnchorY(r, point)
  if point:find("TOP") then return r.t elseif point:find("BOTTOM") then return r.b end
  return (r.t + r.b) / 2
end

-- SetAtlas(name, true) sizes the texture to the atlas (frames.ATLASES).
local function AtlasSize(o)
  if not (o._useAtlasSize and o._atlas) then return nil end
  return frames.ATLASES and frames.ATLASES[o._atlas:lower()]
end

-- Size a region wants on one axis when its anchors don't decide it.
function Solver:NaturalWidth(o, scale)
  if o._w then return o._w * scale end
  if o._type == "FontString" then return frames.MeasureText(o._text or "", o:Spec()) * scale end
  local a = AtlasSize(o)
  if a then return a[1] * scale end
  return nil
end

function Solver:NaturalHeight(o, scale, width)
  if o._h then return o._h * scale end
  local a = AtlasSize(o)
  if a then return a[2] * scale end
  if o._type == "FontString" then
    local spec = o:Spec()
    local text = o._text or ""
    local lines
    local constrained = o._w or frames.AxisKinds(o._points, "h") >= 2
    if constrained and o._wordWrap ~= false and width then lines = frames.CountLines(text, spec, width / scale)
    else
      lines = 1
      for _ in text:gmatch("\n") do lines = lines + 1 end
      for _ in text:gmatch("|n") do lines = lines + 1 end
    end
    if o._maxLines and o._maxLines > 0 then lines = math.min(lines, o._maxLines) end
    return lines * frames.LineHeight(spec, o._spacing) * scale
  end
  if o._type == "EditBox" and o._multiLine then
    local spec = o:Spec()
    local lines = width and frames.CountLines(o._text or "", spec, width / scale) or 1
    return lines * frames.LineHeight(spec) * scale
  end
  return nil
end

function Solver:Fail(o, why)
  self.problems[o] = self.problems[o] or why
  self.cache[o] = false
  return nil
end

-- Returns { l, r, t, b, scale } or nil (see self.problems[o]).
function Solver:Rect(o)
  local c = self.cache[o]
  if c ~= nil then return c or nil end
  if self.visiting[o] then
    local chain = {}
    local started = false
    for _, s in ipairs(self.stack) do
      if s == o then started = true end
      if started then chain[#chain + 1] = Label(s) end
    end
    chain[#chain + 1] = Label(o)
    self.problems[o] = "circular anchors: " .. table.concat(chain, " -> ")
    return nil
  end
  self.visiting[o] = true
  self.stack[#self.stack + 1] = o
  local r = self:Compute(o)
  self.stack[#self.stack] = nil
  self.visiting[o] = nil
  if r then self.cache[o] = r elseif self.cache[o] == nil then self.cache[o] = false end
  return r
end

function Solver:Compute(o)
  local scale = self:Scale(o)
  if o._isScreen or (not o._parent and #o._points == 0) then
    return { l = 0, r = self.screen.w, t = 0, b = self.screen.h, scale = scale }
  end
  local parent = o._parent
  -- Scroll child: top-left of the scroll frame, own size.
  if parent and parent._scrollChild == o then
    local pr = self:Rect(parent)
    if not pr then return self:Fail(o, "its scroll frame has no rectangle") end
    local w = self:NaturalWidth(o, scale) or 0
    local l = pr.l - (parent._hscroll or 0) * scale
    local t = pr.t - (parent._vscroll or 0) * scale
    local h = self:NaturalHeight(o, scale, w) or 0
    return { l = l, r = l + w, t = t, b = t + h, scale = scale }
  end
  if #o._points == 0 then return self:Fail(o, "no anchors (SetPoint never called)") end

  local hl, hr, hc, vt, vb, vc
  for _, p in ipairs(o._points) do
    local rel = p.rel or parent
    if not rel then
      return self:Fail(o, "anchored to its parent but has none")
    end
    if rel == o then return self:Fail(o, "anchored to itself") end
    local rr = self:Rect(rel)
    if not rr then
      local why = self.problems[rel]
      if why and why:find("^circular") then self.problems[o] = self.problems[o] or why end
      return self:Fail(o, "anchored (" .. p.point .. ") to " .. Label(rel) .. ", which has no rectangle"
        .. (why and (": " .. why) or ""))
    end
    local x = AnchorX(rr, p.relPoint) + (p.x or 0) * scale
    local y = AnchorY(rr, p.relPoint) - (p.y or 0) * scale
    if p.point:find("LEFT") then hl = x elseif p.point:find("RIGHT") then hr = x else hc = x end
    if p.point:find("TOP") then vt = y elseif p.point:find("BOTTOM") then vb = y else vc = y end
  end

  local l, r
  if hl and hr then l, r = hl, hr
  elseif hl and hc then l, r = hl, 2 * hc - hl
  elseif hr and hc then l, r = 2 * hc - hr, hr
  else
    local w = self:NaturalWidth(o, scale)
    if not w then
      self.notes[o] = "no width"
      w = 0
    end
    if hl then l, r = hl, hl + w
    elseif hr then l, r = hr - w, hr
    else l, r = hc - w / 2, hc + w / 2 end
  end

  local t, b
  if vt and vb then t, b = vt, vb
  elseif vt and vc then t, b = vt, 2 * vc - vt
  elseif vb and vc then t, b = 2 * vc - vb, vb
  else
    local h = self:NaturalHeight(o, scale, r - l)
    if not h then
      self.notes[o] = (self.notes[o] and (self.notes[o] .. ", ") or "") .. "no height"
      h = 0
    end
    if vt then t, b = vt, vt + h
    elseif vb then t, b = vb - h, vb
    else t, b = vc - h / 2, vc + h / 2 end
  end
  return { l = l, r = r, t = t, b = b, scale = scale }
end

return L
