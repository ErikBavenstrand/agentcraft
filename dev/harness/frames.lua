-- Frame model for the WoW API mock (Lua 5.1).
--
-- CreateFrame returns objects that record what the game would draw: parent,
-- strata and level, shown state, size, anchors, scale, alpha, backdrop, and
-- their regions (textures and font strings). dev/harness/layout.lua turns the
-- anchors into rectangles and dev/render/render.lua draws them as HTML.
--
-- Every object keeps the old mock behaviour: scripts, events, Show/Hide with
-- OnShow/OnHide, and any capitalised method the model doesn't know is a no-op
-- (lowercase keys stay nil: they are the addon's own fields).
--
-- Tables to extend:
--   M.FONTS      font objects (GameFontNormal, ...): face, size, colour, flags
--   M.TEMPLATES  Blizzard templates: default size, child regions, methods
-- A template name not in M.TEMPLATES is recorded in obj._unknownTemplates and
-- drawn as a dashed box by the renderer.
local M = {}

local function noop() end

M.STRATA = { "WORLD", "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN",
  "FULLSCREEN_DIALOG", "TOOLTIP" }
M.STRATA_INDEX = {}
for i, s in ipairs(M.STRATA) do M.STRATA_INDEX[s] = i end
M.LAYERS = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 }

-- Fonts ------------------------------------------------------------------------
-- face: "friz" (Friz Quadrata, the UI font) or "arialn" (Arial Narrow, chat and
-- numbers). Colours are the client's; sizes are the default UI's.
local GOLD, WHITE, GRAY = { 1, 0.82, 0 }, { 1, 1, 1 }, { 0.5, 0.5, 0.5 }
M.FONTS = {
  GameFontNormal = { face = "friz", size = 12, color = GOLD, shadow = true },
  GameFontHighlight = { face = "friz", size = 12, color = WHITE, shadow = true },
  GameFontDisable = { face = "friz", size = 12, color = GRAY, shadow = true },
  GameFontGreen = { face = "friz", size = 12, color = { 0.1, 1, 0.1 }, shadow = true },
  GameFontRed = { face = "friz", size = 12, color = { 1, 0.1, 0.1 }, shadow = true },
  GameFontWhite = { face = "friz", size = 12, color = WHITE, shadow = true },
  GameFontBlack = { face = "friz", size = 12, color = { 0, 0, 0 } },
  GameFontNormalSmall = { face = "friz", size = 10, color = GOLD, shadow = true },
  GameFontHighlightSmall = { face = "friz", size = 10, color = WHITE, shadow = true },
  GameFontDisableSmall = { face = "friz", size = 10, color = GRAY, shadow = true },
  GameFontGreenSmall = { face = "friz", size = 10, color = { 0.1, 1, 0.1 }, shadow = true },
  GameFontRedSmall = { face = "friz", size = 10, color = { 1, 0.1, 0.1 }, shadow = true },
  GameFontNormalMed2 = { face = "friz", size = 13, color = GOLD, shadow = true },
  GameFontHighlightMed2 = { face = "friz", size = 13, color = WHITE, shadow = true },
  GameFontNormalMedium = { face = "friz", size = 14, color = GOLD, shadow = true },
  GameFontNormalMed3 ={ face = "friz", size = 14, color = GOLD, shadow = true },
  GameFontHighlightMedium = { face = "friz", size = 14, color = WHITE, shadow = true },
  GameFontNormalLarge = { face = "friz", size = 16, color = GOLD, shadow = true },
  GameFontHighlightLarge = { face = "friz", size = 16, color = WHITE, shadow = true },
  GameFontDisableLarge = { face = "friz", size = 16, color = GRAY, shadow = true },
  GameFontNormalHuge = { face = "friz", size = 20, color = GOLD, shadow = true },
  GameFontHighlightHuge = { face = "friz", size = 20, color = WHITE, shadow = true },
  NumberFontNormal = { face = "arialn", size = 14, color = WHITE, outline = true },
  NumberFontNormalSmall = { face = "arialn", size = 12, color = WHITE, outline = true },
  NumberFontNormalSmallGray = { face = "arialn", size = 12, color = { 0.6, 0.6, 0.6 }, outline = true },
  NumberFontNormalLarge = { face = "arialn", size = 16, color = WHITE, outline = true },
  ChatFontNormal = { face = "arialn", size = 14, color = WHITE, shadow = true },
  ChatFontSmall = { face = "arialn", size = 12, color = WHITE, shadow = true },
  SystemFont_Small = { face = "friz", size = 10, color = WHITE },
  SystemFont_Med1 = { face = "friz", size = 12, color = WHITE },
  SystemFont_Large = { face = "friz", size = 16, color = WHITE },
  GameTooltipText = { face = "friz", size = 12, color = WHITE },
  GameTooltipHeaderText = { face = "friz", size = 14, color = WHITE },
}
M.DEFAULT_FONT = "GameFontNormal"

-- Text measurement ---------------------------------------------------------------
-- Approximate glyph widths in em, close enough to Friz Quadrata for layout
-- checks; Arial Narrow is about 82% as wide.
local function GlyphEm(c)
  if c == " " then return 0.27 end
  if c:find("[ilI%.,:;'!|`]") then return 0.27 end
  if c:find("[fjrt%(%)%[%]%-/\"]") then return 0.36 end
  if c:find("[mwMW@]") then return 0.86 end
  if c:find("%u") then return 0.66 end
  if c:find("%d") then return 0.56 end
  if c:byte() >= 128 then return 0.18 end  -- UTF-8 bytes: ~0.55em per 3-byte glyph
  return 0.52
end

-- Splits WoW markup into runs: { text=, color= } or { icon=path, size= }.
-- Handles |cAARRGGBB..|r, |T path:size..|t, |H..|h..|h, |n and ||.
function M.ParseMarkup(text)
  text = tostring(text or "")
  local runs, color, i, buf = {}, nil, 1, {}
  local function flush()
    if #buf > 0 then runs[#runs + 1] = { text = table.concat(buf), color = color }; buf = {} end
  end
  while i <= #text do
    local c = text:sub(i, i)
    if c == "|" then
      local n = text:sub(i + 1, i + 1)
      if n == "c" and text:sub(i + 2, i + 9):match("^%x%x%x%x%x%x%x%x$") then
        flush()
        local hex = text:sub(i + 2, i + 9)
        color = { tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, tonumber(hex:sub(7, 8), 16) / 255 }
        i = i + 10
      elseif n == "r" then
        flush(); color = nil; i = i + 2
      elseif n == "T" then
        local e = text:find("|t", i + 2, true)
        if not e then buf[#buf + 1] = c; i = i + 1
        else
          flush()
          local spec = text:sub(i + 2, e - 1)
          local path, h = spec:match("^([^:]*):?(%d*)")
          runs[#runs + 1] = { icon = path, size = tonumber(h) or 0 }
          i = e + 2
        end
      elseif n == "A" then
        local e = text:find("|a", i + 2, true)
        if not e then buf[#buf + 1] = c; i = i + 1
        else
          flush()
          local atlas, h = text:sub(i + 3, e - 1):match("^([^:]*):?(%d*)")
          runs[#runs + 1] = { icon = "atlas:" .. atlas, size = tonumber(h) or 0 }
          i = e + 2
        end
      elseif n == "H" then
        local e = text:find("|h", i + 2, true)
        i = e and e + 2 or i + 2
      elseif n == "h" then
        i = i + 2
      elseif n == "n" then
        buf[#buf + 1] = "\n"; i = i + 2
      elseif n == "|" then
        buf[#buf + 1] = "|"; i = i + 2
      else
        buf[#buf + 1] = c; i = i + 1
      end
    else
      buf[#buf + 1] = c; i = i + 1
    end
  end
  flush()
  return runs
end

local function FaceScale(font) return font.face == "arialn" and 0.82 or 1 end

-- Width of each visible line (no wrapping), in UI units.
local function LineWidths(text, font)
  local size, k = font.size or 12, FaceScale(font)
  local widths, w = {}, 0
  for _, run in ipairs(M.ParseMarkup(text)) do
    if run.icon then
      w = w + (run.size > 0 and run.size or size)
    else
      for ch in run.text:gmatch(".") do
        if ch == "\n" then widths[#widths + 1] = w; w = 0
        else w = w + GlyphEm(ch) * size * k end
      end
    end
  end
  widths[#widths + 1] = w
  return widths
end

function M.MeasureText(text, font)
  local best = 0
  for _, w in ipairs(LineWidths(text, font)) do if w > best then best = w end end
  return best
end

-- The visible text with markup stripped (icons stand in as "MM", as in CountLines).
function M.PlainText(text)
  local plain = {}
  for _, run in ipairs(M.ParseMarkup(text)) do
    plain[#plain + 1] = run.icon and "MM" or run.text
  end
  return table.concat(plain)
end

function M.LineHeight(font, spacing) return (font.size or 12) + (spacing or 0) end

-- Number of lines the text needs when wrapped at `width` (greedy, by words;
-- a word longer than the line breaks anywhere, as the client does).
function M.CountLines(text, font, width)
  local plain = {}
  for _, run in ipairs(M.ParseMarkup(text)) do
    plain[#plain + 1] = run.icon and "MM" or run.text
  end
  local size, k = font.size or 12, FaceScale(font)
  local lines = 0
  for para in (table.concat(plain) .. "\n"):gmatch("(.-)\n") do
    lines = lines + 1
    if width and width > 0 then
      local x = 0
      for space, word in para:gmatch("(%s*)(%S+)") do
        local ww = 0
        for ch in word:gmatch(".") do ww = ww + GlyphEm(ch) * size * k end
        local sw = #space * 0.27 * size * k
        if x > 0 and x + sw + ww > width then
          lines = lines + 1; x = 0; sw = 0
        end
        while ww > width and width > size do  -- unbreakable word
          lines = lines + 1; ww = ww - width
        end
        x = x + sw + ww
      end
    end
  end
  return lines
end

-- Resolves a font object name/table/spec into a plain spec table.
function M.FontSpec(W, f)
  if type(f) == "string" then
    local fo = W and W.fonts and W.fonts[f]
    if fo then return fo._spec end
    return M.FONTS[f] or M.FONTS[M.DEFAULT_FONT]
  end
  if type(f) == "table" then
    if f._spec then return f._spec end
    if f.size then return f end
  end
  return M.FONTS[M.DEFAULT_FONT]
end

-- Object model ----------------------------------------------------------------------

local Base = {}                                       -- every visible object
local Region = setmetatable({}, { __index = Base })   -- textures, font strings
local Texture = setmetatable({}, { __index = Region })
local FontString = setmetatable({}, { __index = Region })
local Frame = setmetatable({}, { __index = Base })
local Button = setmetatable({}, { __index = Frame })
local CheckButton = setmetatable({}, { __index = Button })
local EditBox = setmetatable({}, { __index = Frame })
local ScrollFrame = setmetatable({}, { __index = Frame })
local Slider = setmetatable({}, { __index = Frame })
local Generic = {}                                    -- animation groups etc.
M.classes = { Base = Base, Region = Region, Texture = Texture, FontString = FontString, Frame = Frame,
  Button = Button, CheckButton = CheckButton, EditBox = EditBox, ScrollFrame = ScrollFrame, Slider = Slider }

local CLASS_OF = {
  Frame = Frame, Button = Button, CheckButton = CheckButton, EditBox = EditBox, ScrollFrame = ScrollFrame,
  Slider = Slider, EventFrame = Frame, StatusBar = Frame, Cooldown = Frame, GameTooltip = Frame, Model = Frame, PlayerModel = Frame,
  SimpleHTML = Frame, MessageFrame = Frame, ScrollingMessageFrame = Frame, ColorSelect = Frame,
  DropdownButton = Button, ItemButton = Button,
  Texture = Texture, MaskTexture = Texture, Line = Texture, FontString = FontString,
}
local REGION = { Texture = true, MaskTexture = true, Line = true, FontString = true }

-- The first stack level in the addon's own files: "Macros/Page.lua:72".
local function CreationSite(W)
  local dir = W.addonDir
  if not dir then return nil end
  for level = 3, 14 do
    local info = debug.getinfo(level, "Sl")
    if not info then break end
    local src = info.source or ""
    local at = src:find(dir, 1, true)
    if at then
      return src:sub(at + #dir + 1) .. ":" .. tostring(info.currentline)
    end
  end
end

local NewObject

local function AddChild(parent, o)
  if not parent or type(parent) ~= "table" or not rawget(parent, "_world") then return end
  local list = o._region and "_regions" or "_children"
  parent[list] = parent[list] or {}
  table.insert(parent[list], o)
end

local function RemoveChild(parent, o)
  local list = parent and parent[o._region and "_regions" or "_children"]
  if not list then return end
  for i, c in ipairs(list) do if c == o then table.remove(list, i) return end end
end

NewObject = function(W, otype, name, parent)
  otype = otype or "Frame"
  local cls = CLASS_OF[otype] or (otype:match("Button$") and Button) or (REGION[otype] and Region) or Generic
  W.nextObjectId = (W.nextObjectId or 0) + 1
  local o = {
    _type = otype, _name = name, _parent = parent, _world = W, _id = W.nextObjectId,
    _scripts = {}, _events = {}, _attr = {}, _shown = true, _points = {}, _alpha = 1, _scale = 1,
    _site = CreationSite(W), _region = REGION[otype] or nil, _drawable = cls ~= Generic or nil,
  }
  setmetatable(o, {
    __index = function(_, k)
      local m = cls[k]
      if m ~= nil then return m end
      -- Unmocked widget methods are no-ops; lowercase keys are addon fields.
      if type(k) == "string" and k:match("^%u") then
        if k:match("^Create") then
          return function(self) return NewObject(W, k:sub(7), nil, self) end
        end
        return noop
      end
      return nil
    end,
  })
  if o._drawable then AddChild(parent, o) end
  return o
end
M.NewObject = NewObject

-- Base: scripts, visibility, geometry ------------------------------------------------

function Base:SetScript(name, fn) self._scripts[name] = fn end
function Base:GetScript(name) return self._scripts[name] end
function Base:HookScript(name, fn)
  local old = self._scripts[name]
  self._scripts[name] = old and function(...) old(...); fn(...) end or fn
end
function Base:HasScript() return true end
function Base:RegisterEvent(ev) self._events[ev] = true end
function Base:RegisterUnitEvent(ev) self._events[ev] = true end
function Base:UnregisterEvent(ev) self._events[ev] = nil end
function Base:UnregisterAllEvents() self._events = {} end
function Base:IsEventRegistered(ev) return self._events[ev] == true end
function Base:Show()
  local was = self._shown
  self._shown = true
  if not was and self._scripts.OnShow then self._scripts.OnShow(self) end
end
function Base:Hide()
  local was = self._shown
  self._shown = false
  if was and self._scripts.OnHide then self._scripts.OnHide(self) end
end
function Base:SetShown(v) if v then self:Show() else self:Hide() end end
function Base:IsShown() return self._shown end
function Base:IsVisible()
  local o = self
  while o do
    if not o._shown then return false end
    o = o._parent
  end
  return true
end
function Base:GetName() return self._name end
function Base:GetDebugName() return self._name or (self._type .. "#" .. self._id) end
function Base:GetParent() return self._parent end
function Base:SetParent(p)
  if type(p) == "string" then p = self._world.G and self._world.G[p] end
  if p == self._parent then return end
  RemoveChild(self._parent, self)
  self._parent = p
  if self._drawable then AddChild(p, self) end
end
function Base:GetObjectType() return self._type end
function Base:IsObjectType(t) return self._type == t or (t == "Frame" and not self._region) or (t == "Region" and self._region == true) end
function Base:SetAttribute(k, v) self._attr[k] = v end
function Base:GetAttribute(k) return self._attr[k] end

function Base:SetWidth(w) self._w = w end
function Base:SetHeight(h) self._h = h end
function Base:SetSize(w, h) self._w, self._h = w, h or w end

-- Size as the game reports it: explicit, else resolved from anchors.
local function Resolved(self)
  local W = self._world
  local layout = package.loaded.layout or require("layout")
  local ok, rect = pcall(function()
    return layout.New(W, W.screen or { w = 1280, h = 800 }):Rect(self)
  end)
  if ok then return rect end
end
-- How many of an axis' three anchor kinds (edge, edge, centre) are set: two
-- or more means the anchors, not SetWidth/SetHeight, decide the size.
function M.AxisKinds(points, axis)
  local seen, n = {}, 0
  for _, p in ipairs(points) do
    local k
    if axis == "h" then k = p.point:find("LEFT") and "a" or p.point:find("RIGHT") and "b" or "c"
    else k = p.point:find("TOP") and "a" or p.point:find("BOTTOM") and "b" or "c" end
    if not seen[k] then seen[k] = true; n = n + 1 end
  end
  return n
end
function Base:GetWidth()
  if M.AxisKinds(self._points, "h") < 2 then
    if self._w then return self._w end
    if self._type == "FontString" then return self:GetStringWidth() end
  end
  local r = Resolved(self)
  if r then return (r.r - r.l) / r.scale end
  return self._w or 0
end
function Base:GetHeight()
  if M.AxisKinds(self._points, "v") < 2 then
    if self._h then return self._h end
    if self._type == "FontString" then return self:GetStringHeight() end
  end
  local r = Resolved(self)
  if r then return (r.b - r.t) / r.scale end
  return self._h or 0
end
function Base:GetSize() return self:GetWidth(), self:GetHeight() end
function Base:GetRect()
  local r = Resolved(self)
  if not r then return nil end
  local H = (self._world.screen or { h = 800 }).h
  return r.l / r.scale, (H - r.b) / r.scale, (r.r - r.l) / r.scale, (r.b - r.t) / r.scale
end
function Base:GetLeft() local l = self:GetRect() return l end
function Base:GetBottom() local _, b = self:GetRect() return b end
function Base:GetTop() local _, b, _, h = self:GetRect() return b and b + h end
function Base:GetRight() local l, _, w = self:GetRect() return l and l + w end
function Base:GetCenter()
  local l, b, w, h = self:GetRect()
  if l then return l + w / 2, b + h / 2 end
end

local POINTS = { TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true, RIGHT = true,
  BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true }

-- SetPoint(point [, relativeTo [, relativePoint]] [, x, y]) in all its forms.
-- relativeTo may be a frame, a global name, or nil (the parent).
function Base:SetPoint(point, a, b, c, d)
  point = tostring(point or "CENTER"):upper()
  local rel, relPoint, x, y
  if type(a) == "number" then
    rel, relPoint, x, y = nil, point, a, b
  else
    rel = a
    if type(b) == "string" then relPoint, x, y = b:upper(), c, d
    elseif type(b) == "number" then relPoint, x, y = point, b, c
    else relPoint, x, y = point, c, d end
  end
  if type(rel) == "string" then
    local name = rel
    rel = self._world.G and rawget(self._world.G, name)
    if not rel then
      self._badAnchors = self._badAnchors or {}
      self._badAnchors[#self._badAnchors + 1] = "SetPoint relative to unknown frame name '" .. name .. "'"
    end
  end
  if not POINTS[point] or not POINTS[relPoint] then
    self._badAnchors = self._badAnchors or {}
    self._badAnchors[#self._badAnchors + 1] = "SetPoint with unknown point " .. point .. "/" .. tostring(relPoint)
  end
  local entry = { point = point, rel = rel or false, relPoint = relPoint, x = x or 0, y = y or 0 }
  for i, p in ipairs(self._points) do
    if p.point == point then self._points[i] = entry return end
  end
  self._points[#self._points + 1] = entry
end
function Base:SetAllPoints(rel)
  if rel == true then rel = nil end
  if type(rel) == "string" then rel = self._world.G and rawget(self._world.G, rel) end
  self._points = {
    { point = "TOPLEFT", rel = rel or false, relPoint = "TOPLEFT", x = 0, y = 0 },
    { point = "BOTTOMRIGHT", rel = rel or false, relPoint = "BOTTOMRIGHT", x = 0, y = 0 },
  }
end
function Base:ClearAllPoints() self._points = {} end
function Base:ClearPoint(point)
  for i, p in ipairs(self._points) do if p.point == point then table.remove(self._points, i) return end end
end
function Base:GetNumPoints() return #self._points end
function Base:GetPoint(i)
  local p = self._points[i or 1]
  if p then return p.point, p.rel or self._parent, p.relPoint, p.x, p.y end
end
function Base:SetScale(s) self._scale = s or 1 end
function Base:GetScale() return self._scale end
function Base:GetEffectiveScale()
  local s, o = 1, self
  while o do s = s * (o._scale or 1); o = o._parent end
  return s
end
function Base:SetAlpha(a) self._alpha = a or 1 end
function Base:GetAlpha() return self._alpha end
function Base:GetEffectiveAlpha()
  local s, o = 1, self
  while o do s = s * (o._alpha or 1); o = o._parent end
  return s
end

-- Animation groups ------------------------------------------------------------------
-- CreateAnimationGroup / CreateAnimation: a setter sink. Play() fires OnPlay
-- and, for a non-looping group, OnFinished at once; an Alpha animation's end
-- value sticks only with SetToFinalAlpha(true), as in game. So a render shows
-- the final frame and code may never rely on a finished translation or scale.
local AnimGroup, Anim = {}, {}
AnimGroup.__index = function(_, k)
  local m = AnimGroup[k]
  if m ~= nil then return m end
  if type(k) == "string" and k:match("^%u") then return noop end
end
Anim.__index = function(_, k)
  local m = Anim[k]
  if m ~= nil then return m end
  if type(k) == "string" and k:match("^Set") then
    return function(self, ...) rawset(self, "_" .. k:sub(4), { ... }); return self end
  end
  if type(k) == "string" and k:match("^%u") then return noop end
end
function AnimGroup:CreateAnimation(kind, name)
  local a = setmetatable({ _kind = kind or "Animation", _group = self, _scripts = {} }, Anim)
  table.insert(self._anims, a)
  if name then self[name] = a end
  return a
end
function AnimGroup:SetScript(n, fn) self._scripts[n] = fn end
function AnimGroup:GetScript(n) return self._scripts[n] end
function AnimGroup:HookScript(n, fn)
  local old = self._scripts[n]
  self._scripts[n] = old and function(...) old(...); fn(...) end or fn
end
function AnimGroup:SetLooping(l) self._looping = l end
function AnimGroup:GetLooping() return self._looping or "NONE" end
function AnimGroup:SetToFinalAlpha(v) self._toFinal = v and true or false end
function AnimGroup:IsPlaying() return self._playing == true end
function AnimGroup:IsReverse() return self._reverse == true end
function AnimGroup:GetProgress() return self._playing and 0 or 1 end
function AnimGroup:GetParent() return self._parent end
function AnimGroup:GetAnimations() return unpack(self._anims) end
function AnimGroup:Play(reverse)
  self._reverse = reverse and true or false
  local W = self._parent._world
  W.animPlays = (W.animPlays or 0) + 1
  if self._scripts.OnPlay then self._scripts.OnPlay(self) end
  if self._looping and self._looping ~= "NONE" then self._playing = true return end
  self._playing = false
  if self._toFinal then
    for _, a in ipairs(self._anims) do
      local to = rawget(a, "_ToAlpha")
      if a._kind == "Alpha" and to then
        local target = rawget(a, "_target") or self._parent
        target:SetAlpha(self._reverse and (rawget(a, "_FromAlpha") or { 1 })[1] or to[1])
      end
    end
  end
  if self._scripts.OnFinished then self._scripts.OnFinished(self, false) end
end
AnimGroup.Restart = AnimGroup.Play
function AnimGroup:Stop()
  local was = self._playing
  self._playing = false
  if was and self._scripts.OnStop then self._scripts.OnStop(self) end
end
function AnimGroup:Finish() self:Stop() end
function AnimGroup:Pause() self._playing = false end
function Anim:SetTarget(t) rawset(self, "_target", t); return self end
function Anim:SetChildKey(k) rawset(self, "_target", self._group._parent[k]); return self end
function Anim:SetScript(n, fn) self._scripts[n] = fn end
function Anim:GetRegionParent() return self._group._parent end
function Anim:GetTarget() return rawget(self, "_target") or self._group._parent end
function Base:CreateAnimationGroup(name)
  local g = setmetatable({ _parent = self, _anims = {}, _scripts = {} }, AnimGroup)
  if name then self[name] = g end
  return g
end
M.AnimGroup = AnimGroup

-- Keyboard input (UIHANDLER_OnKeyDown): what a frame takes and passes on.
function Base:EnableKeyboard(v) self._keyboard = v and true or false end
function Base:IsKeyboardEnabled() return self._keyboard == true end
function Base:SetPropagateKeyboardInput(v)
  local W = self._world
  if W.inCombat then
    W.errors[#W.errors + 1] = "SetPropagateKeyboardInput called in combat (protected)"
    return
  end
  self._propagate = v and true or false
end
function Base:GetPropagateKeyboardInput() return self._propagate ~= false end
function Base:LockHighlight() self._lockedHighlight = true end
function Base:UnlockHighlight() self._lockedHighlight = false end
function Base:SetMouseClickEnabled(v) self._mouseClick = v ~= false end
function Base:SetMouseMotionEnabled(v) self._mouseMotion = v ~= false end

-- Frame -------------------------------------------------------------------------------

function Frame:SetFrameStrata(s) self._strata = s end
function Frame:GetFrameStrata()
  local o = self
  while o do if o._strata then return o._strata end o = o._parent end
  return "MEDIUM"
end
function Frame:SetFrameLevel(l) self._level = l end
function Frame:GetFrameLevel()
  if self._level then return self._level end
  local p = self._parent
  return (p and p.GetFrameLevel and p:GetFrameLevel() or 0) + 1
end
function Frame:SetToplevel(v) self._toplevel = v end
function Frame:SetClipsChildren(v) self._clips = v and true or false end
function Frame:DoesClipChildren() return self._clips == true end
function Frame:GetChildren() return unpack(self._children or {}) end
function Frame:GetNumChildren() return #(self._children or {}) end
function Frame:GetRegions() return unpack(self._regions or {}) end
function Frame:GetNumRegions() return #(self._regions or {}) end
function Frame:SetID(id) self._idNum = id end
function Frame:GetID() return self._idNum or 0 end
function Frame:EnableMouse(v) self._mouse = v ~= false end
function Frame:IsMouseEnabled() return self._mouse == true end
function Frame:IsMouseOver() return false end
function Frame:IsEnabled() return self._enabled ~= false end
function Frame:SetEnabled(v) self._enabled = v and true or false end
function Frame:Enable() self._enabled = true end
function Frame:Disable() self._enabled = false end
function Frame:GetChecked() return self._checked end
function Frame:SetChecked(v) self._checked = v end
-- Text on any frame type (Button, EditBox; the old mock allowed it everywhere).
function Frame:SetText(t) self._text = t end
function Frame:GetText() return self._text end

function Frame:CreateTexture(name, layer, template, sublevel)
  local t = NewObject(self._world, "Texture", name, self)
  t._layer, t._sublevel = layer or "ARTWORK", sublevel or 0
  if template then M.ApplyTemplates(t, template) end
  if name then rawset(self._world.G or {}, name, t) end
  return t
end
function Frame:CreateMaskTexture(name, layer)
  local t = NewObject(self._world, "MaskTexture", name, self)
  t._layer, t._sublevel, t._mask = layer or "ARTWORK", 0, true
  return t
end
function Frame:CreateLine(name, layer)
  local t = NewObject(self._world, "Line", name, self)
  t._layer, t._sublevel = layer or "ARTWORK", 0
  return t
end
function Frame:CreateFontString(name, layer, font)
  local fs = NewObject(self._world, "FontString", name, self)
  fs._layer, fs._sublevel = layer or "ARTWORK", 0
  if font then fs._font = font end
  if name then rawset(self._world.G or {}, name, fs) end
  return fs
end

-- Backdrop (BackdropTemplate mixin; plain frames lack it on the modern client).
function Frame:SetBackdrop(b)
  if not self._hasBackdropMixin then self._backdropWithoutTemplate = true end
  self._backdrop = b
end
function Frame:GetBackdrop() return self._backdrop end
function Frame:SetBackdropColor(r, g, b, a) self._backdropColor = { r, g, b, a or 1 } end
function Frame:SetBackdropBorderColor(r, g, b, a) self._backdropBorderColor = { r, g, b, a or 1 } end
function Frame:ApplyBackdrop() end

-- PortraitFrameTemplate etc. supply the real portrait; this keeps old tests
-- that call it on a plain frame working.
function Frame:GetPortrait()
  if not self._portrait then
    self._portrait = self:CreateTexture(nil, "OVERLAY")
    self._portrait._fromTemplate = true
  end
  return self._portrait
end

-- Regions -----------------------------------------------------------------------------

function Region:SetDrawLayer(layer, sub) self._layer = layer or self._layer; self._sublevel = sub or self._sublevel end
function Region:GetDrawLayer() return self._layer, self._sublevel end
function Region:SetText(t) self._text = t end
function Region:GetText() return self._text end

function Texture:SetTexture(tex)
  self._color, self._atlas = nil, nil
  self._file = tex
  if type(tex) == "string" and tex == "" then self._file = nil end
end
function Texture:GetTexture() return self._file or (self._atlas and ("atlas:" .. self._atlas)) end
function Texture:GetTextureFileID() return type(self._file) == "number" and self._file or nil end
function Texture:GetTextureFilePath() return self._file end
function Texture:SetColorTexture(r, g, b, a)
  self._file, self._atlas = nil, nil
  self._color = { r or 1, g or 1, b or 1, a or 1 }
end
function Texture:SetAtlas(atlas, useAtlasSize)
  self._file, self._color = nil, nil
  self._atlas = atlas
  self._useAtlasSize = useAtlasSize and true or nil
end
function Texture:GetAtlas() return self._atlas end
function Texture:SetTexCoord(...)
  local n = select("#", ...)
  if n >= 8 then
    local ulx, uly, _, lly, urx = ...
    self._texcoord = { ulx, urx, uly, lly }
  elseif n >= 4 then
    self._texcoord = { ... }
  else
    self._texcoord = nil
  end
end
function Texture:GetTexCoord()
  local t = self._texcoord or { 0, 1, 0, 1 }
  return t[1], t[3], t[1], t[4], t[2], t[3], t[2], t[4]
end
function Texture:SetVertexColor(r, g, b, a) self._vertex = { r or 1, g or 1, b or 1, a or 1 } end
function Texture:GetVertexColor() local v = self._vertex or { 1, 1, 1, 1 } return v[1], v[2], v[3], v[4] end
function Texture:SetDesaturated(v) self._desaturated = v and true or false end
function Texture:IsDesaturated() return self._desaturated == true end
function Texture:SetBlendMode(m) self._blend = m end
function Texture:GetBlendMode() return self._blend or "BLEND" end
function Texture:SetGradient(orientation, c1, c2) self._gradient = { orientation, c1, c2 } end
function Texture:SetRotation(r) self._rotation = r end
function Texture:SetHorizTile(v) self._htile = v end
function Texture:SetVertTile(v) self._vtile = v end
function Texture:AddMaskTexture(m) self._masks = self._masks or {}; table.insert(self._masks, m) end
function Texture:SetMask(path) self._maskFile = path end

function FontString:SetText(t)
  if t ~= nil then t = tostring(t) end
  self._text = t
end
function FontString:SetFormattedText(fmt, ...) self._text = string.format(fmt, ...) end
function FontString:GetText() return self._text end
function FontString:SetFontObject(f) self._font = f; self._fontFace = nil end
function FontString:GetFontObject()
  local f = self._font
  if type(f) == "string" then return self._world.fonts and self._world.fonts[f] or f end
  return f
end
function FontString:SetFont(path, size, flags)
  local base = M.FontSpec(self._world, self._font)
  local face = tostring(path or ""):lower():find("arialn") and "arialn" or "friz"
  self._fontFace = { face = face, size = size or base.size, color = base.color, shadow = base.shadow,
    outline = flags and tostring(flags):find("OUTLINE") and true or nil, path = path }
  return true
end
function FontString:GetFont()
  local f = self:Spec()
  return f.path or (f.face == "arialn" and "Fonts\\ARIALN.TTF" or "Fonts\\FRIZQT__.TTF"), f.size, f.outline and "OUTLINE" or ""
end
function FontString:Spec()
  return self._fontFace or M.FontSpec(self._world, self._font)
end
function FontString:SetTextColor(r, g, b, a) self._textColor = { r or 1, g or 1, b or 1, a or 1 } end
function FontString:GetTextColor()
  local c = self._textColor or self:Spec().color or WHITE
  return c[1], c[2], c[3], c[4] or 1
end
function FontString:SetJustifyH(j) self._justifyH = j end
function FontString:GetJustifyH() return self._justifyH or "CENTER" end
function FontString:SetJustifyV(j) self._justifyV = j end
function FontString:GetJustifyV() return self._justifyV or "MIDDLE" end
function FontString:SetWordWrap(v) self._wordWrap = v and true or false end
function FontString:CanWordWrap() return self._wordWrap ~= false end
function FontString:SetNonSpaceWrap(v) self._nonSpaceWrap = v end
function FontString:SetMaxLines(n) self._maxLines = n end
function FontString:GetMaxLines() return self._maxLines or 0 end
function FontString:SetSpacing(s) self._spacing = s end
function FontString:GetSpacing() return self._spacing or 0 end
function FontString:SetShadowColor(r, g, b, a) self._shadowColor = { r, g, b, a } end
function FontString:SetShadowOffset(x, y) self._shadowOffset = { x, y } end
function FontString:GetStringWidth() return M.MeasureText(self._text or "", self:Spec()) end
function FontString:GetUnboundedStringWidth() return self:GetStringWidth() end
function FontString:GetStringHeight()
  local spec = self:Spec()
  local lines
  if self._w and self._wordWrap ~= false then lines = M.CountLines(self._text or "", spec, self._w)
  else lines = #LineWidths(self._text or "", spec) end
  return lines * M.LineHeight(spec, self._spacing)
end
function FontString:GetNumLines() return math.floor(self:GetStringHeight() / M.LineHeight(self:Spec(), self._spacing)) end
function FontString:IsTruncated() return false end

-- Button ------------------------------------------------------------------------------

local STATE_LAYER = { normal = "ARTWORK", pushed = "ARTWORK", disabled = "ARTWORK", highlight = "HIGHLIGHT",
  checked = "OVERLAY", disabledChecked = "OVERLAY" }

local function StateTexture(self, state, tex, blend)
  local key = "_" .. state .. "Texture"
  local t = self[key]
  if type(tex) == "table" and rawget(tex, "_world") then
    if t and t ~= tex then t:Hide() end
    tex:SetParent(self)
    t = tex
  else
    if not t then
      t = self:CreateTexture(nil, STATE_LAYER[state])
      t:SetAllPoints()
    end
    if tex == nil then t._file = nil
    elseif type(tex) == "string" and tex:find("^atlas:") then t:SetAtlas(tex:sub(7))
    else t:SetTexture(tex) end
  end
  t._buttonState = state
  t._layer = STATE_LAYER[state]
  if blend then t._blend = blend end
  rawset(self, key, t)
  return t
end
function Button:SetNormalTexture(t) return StateTexture(self, "normal", t) end
function Button:SetPushedTexture(t) return StateTexture(self, "pushed", t) end
function Button:SetDisabledTexture(t) return StateTexture(self, "disabled", t) end
function Button:SetHighlightTexture(t, blend) return StateTexture(self, "highlight", t, blend) end
function Button:SetNormalAtlas(a) return StateTexture(self, "normal", "atlas:" .. a) end
function Button:SetPushedAtlas(a) return StateTexture(self, "pushed", "atlas:" .. a) end
function Button:SetDisabledAtlas(a) return StateTexture(self, "disabled", "atlas:" .. a) end
function Button:SetHighlightAtlas(a, blend) return StateTexture(self, "highlight", "atlas:" .. a, blend) end
function Button:GetNormalTexture() return rawget(self, "_normalTexture") end
function Button:GetPushedTexture() return rawget(self, "_pushedTexture") end
function Button:GetDisabledTexture() return rawget(self, "_disabledTexture") end
function Button:GetHighlightTexture() return rawget(self, "_highlightTexture") end
function CheckButton:SetCheckedTexture(t) return StateTexture(self, "checked", t) end
function CheckButton:SetDisabledCheckedTexture(t) return StateTexture(self, "disabledChecked", t) end
function CheckButton:GetCheckedTexture() return rawget(self, "_checkedTexture") end

function Button:GetFontString()
  if not rawget(self, "_fontString") then
    local fs = self:CreateFontString(nil, "OVERLAY", self._normalFont or "GameFontNormal")
    fs:SetPoint("CENTER")
    fs._buttonText = true
    rawset(self, "_fontString", fs)
  end
  return self._fontString
end
function Button:SetFontString(fs) rawset(self, "_fontString", fs); fs._buttonText = true end
function Button:SetText(t)
  self._text = t
  self:GetFontString():SetText(t)
end
function Button:SetFormattedText(fmt, ...) self:SetText(string.format(fmt, ...)) end
function Button:GetText() return self._text end
function Button:SetNormalFontObject(f) self._normalFont = f; if rawget(self, "_fontString") then self._fontString._font = f end end
function Button:SetHighlightFontObject(f) self._highlightFont = f end
function Button:SetDisabledFontObject(f) self._disabledFont = f end
function Button:GetTextWidth() return self:GetFontString():GetStringWidth() end
function Button:Click(...) if self._scripts.OnClick then self._scripts.OnClick(self, ...) end end

-- EditBox -----------------------------------------------------------------------------

function EditBox:SetText(t) self._text = t ~= nil and tostring(t) or "" end
function EditBox:GetText() return self._text or "" end
function EditBox:SetFontObject(f) self._font = f end
function EditBox:GetFontObject() return self._font end
function EditBox:Spec() return M.FontSpec(self._world, self._font or "ChatFontNormal") end
function EditBox:SetMultiLine(v) self._multiLine = v and true or false end
function EditBox:IsMultiLine() return self._multiLine == true end
function EditBox:SetTextInsets(l, r, t, b) self._insets = { l or 0, r or 0, t or 0, b or 0 } end
function EditBox:SetJustifyH(j) self._justifyH = j end
function EditBox:SetTextColor(r, g, b, a) self._textColor = { r, g, b, a or 1 } end
function EditBox:SetCursorPosition(p) self._cursor = p end
function EditBox:GetCursorPosition() return self._cursor or 0 end
function EditBox:HasFocus() return false end
function EditBox:GetNumLetters() return #(self._text or "") end

-- ScrollFrame -------------------------------------------------------------------------

function ScrollFrame:SetScrollChild(c)
  self._scrollChild = c
  if c and c._parent ~= self then c:SetParent(self) end
end
function ScrollFrame:GetScrollChild() return self._scrollChild end
function ScrollFrame:SetVerticalScroll(v) self._vscroll = v end
function ScrollFrame:GetVerticalScroll() return self._vscroll or 0 end
function ScrollFrame:SetHorizontalScroll(v) self._hscroll = v end
function ScrollFrame:GetHorizontalScroll() return self._hscroll or 0 end
function ScrollFrame:GetVerticalScrollRange()
  local c = self._scrollChild
  if not c then return 0 end
  return math.max(0, c:GetHeight() - self:GetHeight())
end
function ScrollFrame:UpdateScrollChildRect() end

-- Slider ------------------------------------------------------------------------------

function Slider:SetMinMaxValues(a, b) self._min, self._max = a, b end
function Slider:GetMinMaxValues() return self._min or 0, self._max or 1 end
function Slider:SetValueStep(s) self._step = s end
function Slider:GetValueStep() return self._step or 0 end
function Slider:SetValue(v)
  if self._min then v = math.max(self._min, math.min(self._max or v, v)) end
  local old = self._value
  self._value = v
  if old ~= v and self._scripts.OnValueChanged then self._scripts.OnValueChanged(self, v, false) end
end
function Slider:GetValue() return self._value or self._min or 0 end
function Slider:SetOrientation(o) self._orientation = o end

-- Templates ------------------------------------------------------------------------------
-- Each entry: size = { w, h } default size; build(f) adds child regions and
-- methods. Textures created here are marked _fromTemplate (layout checks skip
-- them) and may carry _fallback = { r, g, b, a }: the colour drawn when the
-- real texture file isn't in dev/render/textures/. Paths are the classic-style
-- files of the same look, so they exist in Gethe/wow-ui-textures.

local function T(f, layer, file, fallback, sub)
  local t = f:CreateTexture(nil, layer, nil, sub)
  if file then t:SetTexture(file) end
  t._fallback, t._fromTemplate = fallback, true
  return t
end
local function FS(f, font, layer)
  local fs = f:CreateFontString(nil, layer or "OVERLAY", font)
  fs._fromTemplate = true
  return fs
end
local function Child(ftype, parent, template)
  local c = M.CreateFrame(parent._world, ftype, nil, parent, template)
  c._fromTemplate = true
  return c
end

-- A metal-style frame border made of four edges (NineSlice stand-in).
local function Border(f, inset, color, width)
  width = width or 3
  local edges = {}
  for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local t = T(f, "BORDER", nil, nil, 7)
    t:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
    if side == "TOP" or side == "BOTTOM" then
      t:SetPoint(side .. "LEFT", -inset, side == "TOP" and inset or -inset)
      t:SetPoint(side .. "RIGHT", inset, side == "TOP" and inset or -inset)
      t:SetHeight(width)
    else
      t:SetPoint("TOP" .. side, side == "LEFT" and -inset or inset, inset)
      t:SetPoint("BOTTOM" .. side, side == "LEFT" and -inset or inset, -inset)
      t:SetWidth(width)
    end
    edges[#edges + 1] = t
  end
  return edges
end

local function CloseButton(f)
  local b = Child("Button", f, "UIPanelCloseButton")
  b:SetPoint("TOPRIGHT", 4, 5)
  return b
end

local METAL = { 0.42, 0.40, 0.38, 1 }

-- Portrait coordinates in Interface\TargetingFrame\UI-Classes-Circles.
local CLASS_TCOORDS = {
  WARRIOR = { 0, 0.25, 0, 0.25 }, MAGE = { 0.25, 0.49609375, 0, 0.25 },
  ROGUE = { 0.49609375, 0.7421875, 0, 0.25 }, DRUID = { 0.7421875, 0.98828125, 0, 0.25 },
  HUNTER = { 0, 0.25, 0.25, 0.5 }, SHAMAN = { 0.25, 0.49609375, 0.25, 0.5 },
  PRIEST = { 0.49609375, 0.7421875, 0.25, 0.5 }, WARLOCK = { 0.7421875, 0.98828125, 0.25, 0.5 },
  PALADIN = { 0, 0.25, 0.5, 0.75 }, DEATHKNIGHT = { 0.25, 0.49609375, 0.5, 0.75 },
}

-- Atlases C_Texture.GetAtlasInfo reports as present: { w, h, color } where
-- color is what the renderer draws when dev/render/textures has no PNG for
-- the atlas (a fill, or a 2px outline when the 4th field is "ring"). Keys are
-- lower case (atlas names are case-insensitive).
M.ATLASES = {
  ["options_list_active"] = { 200, 26, { 1, 0.82, 0, 0.16 } },
  ["options_list_hover"] = { 200, 26, { 1, 1, 1, 0.08 } },
  ["options_categoryheader_1"] = { 200, 22, { 0.35, 0.3, 0.22, 0.45 } },
  ["options_horizontaldivider"] = { 400, 1, { 1, 0.82, 0, 0.3 } },
  ["ui-character-info-scrollline-long"] = { 300, 1, { 1, 1, 1, 0.15 } },
  ["ui-hud-actionbar-iconframe"] = { 46, 45, { 0.55, 0.5, 0.42, 0.9 }, "ring" },
  ["ui-hud-actionbar-iconframe-mask"] = { 45, 45 },
  ["ui-hud-actionbar-iconframe-mouseover"] = { 46, 45, { 1, 1, 1, 0.15 } },
  ["ui-hud-actionbar-iconframe-down"] = { 46, 45, { 0, 0, 0, 0.3 } },
  ["ui-hud-actionbar-iconframe-border"] = { 46, 45, { 1, 1, 1, 1 }, "ring" },
  ["ui-hud-actionbar-iconframe-slot"] = { 46, 45, { 0.02, 0.02, 0.02, 0.75 } },
  ["ui-hud-actionbar-flyout"] = { 18, 10, { 1, 0.82, 0, 0.9 } },
  ["services-icon-warning"] = { 16, 16, { 1, 0.75, 0.1, 0.9 } },
  ["checkbox-minimal"] = { 30, 29, { 0.1, 0.09, 0.08, 0.95 } },
  ["checkmark-minimal"] = { 30, 29, { 1, 0.82, 0, 0.6 } },
  ["checkmark-minimal-disabled"] = { 30, 29, { 0.5, 0.5, 0.5, 0.6 } },
  ["common-dropdown-textholder"] = { 120, 25, { 0.08, 0.07, 0.06, 0.95 } },
  ["common-dropdown-a-button"] = { 25, 25, { 0.5, 0.42, 0.28, 0.95 } },
  ["uiframe-tab-left"] = { 35, 36, { 0.18, 0.15, 0.12, 1 } },
  ["uiframe-activetab-left"] = { 35, 36, { 0.32, 0.27, 0.2, 1 } },
  -- Real names from UiTextureAtlasMember (wago.tools) and MinimalSlider.xml:
  -- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/Slider/MinimalSlider.xml
  ["minimal_sliderbar_left"] = { 11, 17, { 0.3, 0.26, 0.2, 1 } },
  ["_minimal_sliderbar_middle"] = { 1, 17, { 0.3, 0.26, 0.2, 1 } },
  ["minimal_sliderbar_right"] = { 11, 17, { 0.3, 0.26, 0.2, 1 } },
  ["minimal_sliderbar_button"] = { 20, 19, { 0.8, 0.65, 0.35, 1 } },
  ["minimal_sliderbar_button_left"] = { 11, 19, { 0.8, 0.65, 0.35, 1 } },
  ["minimal_sliderbar_button_right"] = { 9, 18, { 0.8, 0.65, 0.35, 1 } },
  -- v2 window art (every name is in the retail UiTextureAtlasMember table;
  -- Forever-only names are tried first by the addon and are absent here).
  ["gamepad-xbox1-buttona-flat-normal"] = { 76, 75, { 0.2, 0.7, 0.2, 1 } },
  ["gamepad-xbox1-buttonb-flat-normal"] = { 76, 75, { 0.8, 0.2, 0.2, 1 } },
  ["gamepad-xbox1-buttonx-flat-normal"] = { 76, 75, { 0.2, 0.4, 0.9, 1 } },
  ["gamepad-xbox1-buttony-flat-normal"] = { 76, 75, { 0.9, 0.8, 0.2, 1 } },
  ["gamepad-xbox1-trigger-lb-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-xbox1-trigger-rb-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-xbox1-trigger-lt-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-xbox1-trigger-rt-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-xbox1-dpadup-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-xbox1-dpaddown-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-xbox1-dpadleft-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-xbox1-dpadright-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-xbox1-dpadall-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  -- One-direction D-pad glyphs (UiTextureAtlasMember 41414/41399/41404/41409 on file 8281847).
  ["gamepad-xbox1-donlyup-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-xbox1-donlydown-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-xbox1-donlyleft-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-xbox1-donlyright-flat-normal"] = { 76, 75, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-ps-32x-x"] = { 32, 32, { 0.4, 0.5, 0.9, 1 } },
  ["gamepad-ps-32x-circle"] = { 32, 32, { 0.9, 0.3, 0.3, 1 } },
  ["gamepad-ps-32x-square"] = { 32, 32, { 0.8, 0.4, 0.8, 1 } },
  ["gamepad-ps-32x-triangle"] = { 32, 32, { 0.3, 0.8, 0.6, 1 } },
  ["gamepad-ps-32x-l1"] = { 32, 32, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-ps-32x-r1"] = { 32, 32, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-ps-32x-l2"] = { 32, 32, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-ps-32x-r2"] = { 32, 32, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-ps-32x-dpad-up"] = { 32, 32, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-ps-32x-dpad-down"] = { 32, 32, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-ps-32x-dpad-left"] = { 32, 32, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-ps-32x-dpad-right"] = { 32, 32, { 0.5, 0.5, 0.5, 1 } },
  ["gamepad-actionbar-bg"] = { 139, 138, { 0.05, 0.05, 0.06, 0.8 } },
  ["gamepad-actionbar-slot-bg-empty"] = { 38, 38, { 0.04, 0.04, 0.05, 0.9 } },
  ["gamepad-actionbar-slot-frame-select"] = { 38, 38, { 1, 0.82, 0, 1 }, "ring" },
  ["gamepad-actionbar-slot-frame-focused"] = { 38, 38, { 1, 0.9, 0.5, 1 }, "ring" },
  ["gamepad-actionbar-squareslot-frame"] = { 44, 45, { 0.55, 0.5, 0.42, 1 }, "ring" },
  ["gamepad-actionbar-circleslot-frame"] = { 46, 46, { 0.55, 0.5, 0.42, 1 }, "ring" },
  ["gamepad-actionbar-squareslot-xtradropshadow"] = { 55, 56, { 0, 0, 0, 0.4 } },
  ["gamepad-actionbar-circleslot-xtradropshadow"] = { 57, 58, { 0, 0, 0, 0.4 } },
  ["gamepad-actionbar-squareslot-empty-dpadup"] = { 44, 45, { 0.1, 0.1, 0.1, 0.9 } },
  ["gamepad-actionbar-squareslot-empty-dpaddown"] = { 44, 45, { 0.1, 0.1, 0.1, 0.9 } },
  ["gamepad-actionbar-squareslot-empty-dpadleft"] = { 44, 45, { 0.1, 0.1, 0.1, 0.9 } },
  ["gamepad-actionbar-squareslot-empty-dpadright"] = { 44, 45, { 0.1, 0.1, 0.1, 0.9 } },
  ["gamepad-actionbar-circleslot-empty-xba"] = { 46, 46, { 0.1, 0.1, 0.1, 0.9 } },
  ["gamepad-actionbar-circleslot-empty-xbb"] = { 46, 46, { 0.1, 0.1, 0.1, 0.9 } },
  ["gamepad-actionbar-circleslot-empty-xbx"] = { 46, 46, { 0.1, 0.1, 0.1, 0.9 } },
  ["gamepad-actionbar-circleslot-empty-xby"] = { 46, 46, { 0.1, 0.1, 0.1, 0.9 } },
  ["gamepad-actionbar-circleslot-permabound"] = { 46, 47, { 0.6, 0.5, 0.3, 0.6 }, "ring" },
  ["gamepad-actionbar-squareslot-permabound"] = { 43, 44, { 0.6, 0.5, 0.3, 0.6 }, "ring" },
  ["gamepad-actionbar-circleslot-petautocastcorners"] = { 38, 37, { 1, 0.82, 0, 0.8 }, "ring" },
  ["gamepad-actionbar-squareslot-petautocastcorners"] = { 34, 34, { 1, 0.82, 0, 0.8 }, "ring" },
  ["gamepad-actionbar-targeting-overlayglow"] = { 67, 67, { 1, 0.8, 0.3, 0.35 } },
  ["gamepad-ability-icon-jump"] = { 64, 64, { 0.4, 0.4, 0.5, 1 } },
  ["128-redbutton-exit"] = { 128, 128, { 0.6, 0.15, 0.1, 1 } },
  ["squaremask"] = { 64, 64 },
  ["circlemask"] = { 64, 64 },
  ["ui-character-info-title"] = { 196, 40, { 0.25, 0.2, 0.12, 0.8 } },
  ["ui-character-info-line-bounce"] = { 157, 19, { 1, 1, 1, 0.05 } },
  ["talents-animations-clouds"] = { 1612, 774, { 1, 1, 1, 0.03 } },
  ["talents-animations-particles"] = { 1308, 774, { 1, 1, 1, 0.03 } },
  ["talents-background-bottombar"] = { 1612, 82, { 0.1, 0.08, 0.06, 0.9 } },
  ["character-emptysocket"] = { 21, 21, { 0.2, 0.2, 0.2, 1 } },
  ["questsharing-padlock"] = { 24, 29, { 0.7, 0.6, 0.4, 1 } },
  ["ui-hud-actionbar-iconframe-background"] = { 46, 45, { 0.08, 0.07, 0.06, 0.95 } },
  ["ui-hud-actionbar-iconframe-flash"] = { 46, 45, { 1, 0.9, 0.5, 0.5 } },
  ["ui-hud-actionbar-petautocast-corners"] = { 46, 46, { 1, 0.82, 0, 0.8 }, "ring" },
  ["newplayertutorial-yellowglow-redbutton-left"] = { 50, 98, { 1, 0.8, 0.2, 0.3 } },
  ["newplayertutorial-yellowglow-redbutton-middle"] = { 4, 98, { 1, 0.8, 0.2, 0.3 } },
  ["newplayertutorial-yellowglow-redbutton-right"] = { 50, 98, { 1, 0.8, 0.2, 0.3 } },
  ["common-insideframe"] = { 107, 107, { 0.3, 0.25, 0.2, 0.8 }, "ring" },
  -- The retail spellbook spread (Blizzard_PlayerSpells/SpellBook/Blizzard_SpellBookFrame.xml);
  -- the Macros page draws its book on it after the Forever C60 pages.
  ["spellbook-background-evergreen-left"] = { 800, 780, { 0.22, 0.17, 0.11, 1 } },
  ["spellbook-background-evergreen-right"] = { 800, 780, { 0.22, 0.17, 0.11, 1 } },
}
-- Class and spec art the retail table has (the talent frame and character sheet).
for _, class in ipairs({ "deathknight", "demonhunter", "druid", "hunter", "mage", "monk", "paladin", "priest", "rogue",
  "shaman", "warlock", "warrior" }) do
  M.ATLASES["ui-character-info-" .. class .. "-bg"] = { 231, 320, { 0.12, 0.1, 0.08, 1 } }
end
for _, s in ipairs({ "deathknight-blood", "deathknight-frost", "deathknight-unholy", "druid-balance", "druid-feral",
  "druid-guardian", "druid-restoration", "hunter-beastmastery", "hunter-marksmanship", "hunter-survival", "mage-arcane",
  "mage-fire", "mage-frost", "paladin-holy", "paladin-protection", "paladin-retribution", "priest-discipline",
  "priest-holy", "priest-shadow", "rogue-assassination", "rogue-outlaw", "rogue-subtlety", "shaman-elemental",
  "shaman-enhancement", "shaman-restoration", "warlock-affliction", "warlock-demonology", "warlock-destruction",
  "warrior-arms", "warrior-fury", "warrior-protection" }) do
  M.ATLASES["talents-background-" .. s] = { 1612, 774, { 0.1, 0.09, 0.08, 1 } }
end

-- Menu API emulation (DropdownButton:SetupMenu): the generator runs against a
-- description that records every entry, so tests can read dd._menu.
local function NewMenuDescription()
  local d = { entries = {} }
  local function add(kind, text, a, b, c)
    local e = NewMenuDescription()
    e.kind, e.text, e.isSelected, e.setSelected, e.data = kind, text, a, b, c
    table.insert(d.entries, e)
    return e
  end
  function d.CreateTitle(_, text) return add("title", text) end
  function d.CreateDivider() return add("divider") end
  function d.CreateSpacer() return add("spacer") end
  function d.CreateButton(_, text, fn, data) return add("button", text, nil, fn, data) end
  function d.CreateCheckbox(_, text, isSelected, setSelected, data) return add("checkbox", text, isSelected, setSelected, data) end
  function d.CreateRadio(_, text, isSelected, setSelected, data) return add("radio", text, isSelected, setSelected, data) end
  function d.SetTooltip() end
  function d.SetEnabled(self, v) self.enabled = v end
  function d.SetScrollMode() end
  function d.AddInitializer() end
  function d.SetTag() end
  return d
end
M.NewMenuDescription = NewMenuDescription

local function GenerateMenu(dd)
  if not dd._menuGen then return end
  local root = NewMenuDescription()
  dd._menuGen(dd, root)
  dd._menu = root.entries
  -- A selection dropdown shows its selected radio's text.
  if dd._selectionText then
    local text
    for _, e in ipairs(root.entries) do
      if e.kind == "radio" and e.isSelected and e.isSelected(e.data) then text = e.text break end
    end
    dd:SetText(text or dd._defaultText or "")
  end
end

M.TEMPLATES = {
  BackdropTemplate = {
    doc = "Backdrop mixin: SetBackdrop, SetBackdropColor, SetBackdropBorderColor.",
    build = function(f) f._hasBackdropMixin = true end,
  },
  UIPanelButtonTemplate = {
    doc = "Red panel button, 3-slice; text GameFontNormal (disabled GameFontDisable).",
    size = { 40, 22 },
    build = function(f)
      f.Left = T(f, "BACKGROUND", "Interface\\Buttons\\UI-Panel-Button-Up", { 0.5, 0.06, 0.04, 1 })
      f.Left:SetTexCoord(0, 0.09375, 0, 0.6875)
      f.Left:SetPoint("TOPLEFT"); f.Left:SetPoint("BOTTOMLEFT"); f.Left:SetWidth(12)
      f.Right = T(f, "BACKGROUND", "Interface\\Buttons\\UI-Panel-Button-Up", { 0.5, 0.06, 0.04, 1 })
      f.Right:SetTexCoord(0.53125, 0.625, 0, 0.6875)
      f.Right:SetPoint("TOPRIGHT"); f.Right:SetPoint("BOTTOMRIGHT"); f.Right:SetWidth(12)
      f.Middle = T(f, "BACKGROUND", "Interface\\Buttons\\UI-Panel-Button-Up", { 0.5, 0.06, 0.04, 1 })
      f.Middle:SetTexCoord(0.09375, 0.53125, 0, 0.6875)
      f.Middle:SetPoint("TOPLEFT", f.Left, "TOPRIGHT"); f.Middle:SetPoint("BOTTOMRIGHT", f.Right, "BOTTOMLEFT")
      local hl = f:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
      hl:SetTexCoord(0, 0.625, 0, 0.6875)
      hl._fromTemplate = true
      f._normalFont, f._highlightFont, f._disabledFont = "GameFontNormal", "GameFontHighlight", "GameFontDisable"
      f._disabledArt = { "Interface\\Buttons\\UI-Panel-Button-Disabled", { 0.25, 0.22, 0.2, 1 } }
      local fs = f:GetFontString()
      fs._fromTemplate = true
      f.Text = fs
    end,
  },
  UIPanelCloseButton = {
    doc = "Red X close button, 32x32 art.",
    size = { 32, 32 },
    build = function(f)
      local n = f:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
      n._fallback, n._fromTemplate = { 0.55, 0.08, 0.05, 1 }, true
      local h = f:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
      h._fromTemplate = true
    end,
  },
  UICheckButtonTemplate = {
    doc = "Check box 32x32 with a .Text label (GameFontNormalSmall) to its right.",
    size = { 32, 32 },
    build = function(f)
      local n = f:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
      n._fallback, n._fromTemplate = { 0.12, 0.12, 0.12, 1 }, true
      local h = f:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
      h._fromTemplate = true
      local c = f:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
      c._fallback, c._fromTemplate = { 1, 0.82, 0, 0.45 }, true
      local d = f:SetDisabledCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
      d._fallback, d._fromTemplate = { 0.5, 0.5, 0.5, 0.9 }, true
      f.Text = FS(f, "GameFontNormalSmall", "ARTWORK")
      f.Text:SetPoint("LEFT", f, "RIGHT", -2, 1)
      f.text = f.Text
    end,
  },
  InputBoxTemplate = {
    doc = "Single-line edit box, 3-slice border (Common-Input-Border), ChatFontNormal.",
    build = function(f)
      f._font = "ChatFontNormal"
      f._insets = { 0, 0, 0, 0 }
      local L = T(f, "BACKGROUND", "Interface\\Common\\Common-Input-Border", { 0.05, 0.05, 0.05, 0.9 })
      L:SetTexCoord(0, 0.0625, 0, 0.625); L:SetSize(8, 20); L:SetPoint("LEFT", -5, 0)
      local R = T(f, "BACKGROUND", "Interface\\Common\\Common-Input-Border", { 0.05, 0.05, 0.05, 0.9 })
      R:SetTexCoord(0.9375, 1, 0, 0.625); R:SetSize(8, 20); R:SetPoint("RIGHT", 0, 0)
      local Mi = T(f, "BACKGROUND", "Interface\\Common\\Common-Input-Border", { 0.05, 0.05, 0.05, 0.9 })
      Mi:SetTexCoord(0.0625, 0.9375, 0, 0.625); Mi:SetHeight(20)
      Mi:SetPoint("LEFT", L, "RIGHT"); Mi:SetPoint("RIGHT", R, "LEFT")
      f.Left, f.Right, f.Middle = L, R, Mi
    end,
  },
  SearchBoxTemplate = {
    doc = "InputBoxTemplate + magnifier icon, grey 'Search' instructions, clear button.",
    inherits = { "InputBoxTemplate" },
    build = function(f)
      f._insets = { 16, 20, 0, 0 }
      f.searchIcon = T(f, "OVERLAY", "Interface\\Common\\UI-Searchbox-Icon", { 0.7, 0.7, 0.7, 0.8 })
      f.searchIcon:SetSize(14, 14)
      f.searchIcon:SetPoint("LEFT", 1, -2)
      f.Instructions = FS(f, "GameFontDisableSmall", "ARTWORK")
      f.Instructions:SetText("Search")
      f.Instructions:SetJustifyH("LEFT")
      f.Instructions:SetPoint("TOPLEFT", f, "TOPLEFT", 16, 0)
      f.Instructions:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -20, 0)
      f.Instructions._searchInstructions = true
      local clear = Child("Button", f)
      clear:SetSize(17, 17)
      clear:SetPoint("RIGHT", -3, 0)
      local ct = T(clear, "ARTWORK", "Interface\\FriendsFrame\\ClearBroadcastIcon", { 0.6, 0.6, 0.6, 0.6 })
      ct:SetSize(17, 17); ct:SetPoint("CENTER")
      clear:Hide()  -- shown only while there is text
      f.clearButton = clear
    end,
  },
  InsetFrameTemplate = {
    doc = "Recessed dark panel with a thin border (NineSlice 'InsetFrameTemplate').",
    build = function(f)
      f.Bg = T(f, "BACKGROUND", "Interface\\FrameGeneral\\UI-Background-Marble", { 0.06, 0.06, 0.06, 0.95 }, -6)
      f.Bg:SetAllPoints()
      f._insetBorder = Border(f, 0, { 0.25, 0.23, 0.2, 1 }, 1)
    end,
  },
  PortraitFrameTemplate = {
    doc = "Modern window: metal border, dark Bg, title bar (SetTitle), portrait circle top-left, close button.",
    build = function(f)
      f.Bg = T(f, "BACKGROUND", "Interface\\FrameGeneral\\UI-Background-Rock", { 0.09, 0.085, 0.08, 1 }, -6)
      f.Bg:SetPoint("TOPLEFT", 2, -21)
      f.Bg:SetPoint("BOTTOMRIGHT", -2, 2)
      f.TitleBg = T(f, "BACKGROUND", nil, nil, -5)
      f.TitleBg:SetColorTexture(0.16, 0.13, 0.1, 1)
      f.TitleBg:SetPoint("TOPLEFT", 2, -2)
      f.TitleBg:SetPoint("TOPRIGHT", -2, -2)
      f.TitleBg:SetHeight(19)
      f.NineSlice = Border(f, 0, METAL, 3)
      f.TitleContainer = Child("Frame", f)
      f.TitleContainer:SetPoint("TOPLEFT", 58, -1)
      f.TitleContainer:SetPoint("TOPRIGHT", -24, -1)
      f.TitleContainer:SetHeight(20)
      f.TitleContainer.TitleText = FS(f.TitleContainer, "GameFontNormal")
      f.TitleContainer.TitleText:SetPoint("TOP", 0, -5)
      f.TitleContainer.TitleText:SetPoint("LEFT", 60, 0)
      f.TitleContainer.TitleText:SetPoint("RIGHT", -60, 0)
      f.TitleContainer.TitleText:SetWordWrap(false)
      f.PortraitContainer = Child("Frame", f)
      f.PortraitContainer:SetSize(1, 1)
      f.PortraitContainer:SetPoint("TOPLEFT")
      local p = T(f.PortraitContainer, "OVERLAY", nil, { 0.2, 0.2, 0.2, 1 }, -1)
      p:SetSize(62, 62)
      p:SetPoint("TOPLEFT", f, "TOPLEFT", -5, 7)
      p._circle = true
      f.PortraitContainer.portrait = p
      local ring = T(f.PortraitContainer, "OVERLAY", nil, nil, 1)
      ring._ring = METAL
      ring:SetSize(66, 66)
      ring:SetPoint("CENTER", p, "CENTER")
      f._portrait = p
      f.CloseButton = CloseButton(f)
      function f.SetTitle(self, text) self.TitleContainer.TitleText:SetText(text) end
      function f.GetTitleText(self) return self.TitleContainer.TitleText end
      function f.SetPortraitToAsset(self, tex) self._portrait:SetTexture(tex) end
      function f.SetPortraitTextureRaw(self, tex) self._portrait:SetTexture(tex) end
      function f.SetPortraitToUnit() end
      function f.SetPortraitToClassIcon(self, class)
        local c = CLASS_TCOORDS[class]
        self._portrait:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        if c then self._portrait:SetTexCoord(c[1], c[2], c[3], c[4]) end
      end
    end,
  },
  ButtonFrameTemplate = {
    doc = "PortraitFrameTemplate + Inset (InsetFrameTemplate) TOPLEFT 4,-60 to BOTTOMRIGHT -6,26.",
    inherits = { "PortraitFrameTemplate" },
    build = function(f)
      f.Inset = Child("Frame", f, "InsetFrameTemplate")
      f.Inset:SetPoint("TOPLEFT", 4, -60)
      f.Inset:SetPoint("BOTTOMRIGHT", -6, 26)
    end,
  },
  BasicFrameTemplate = {
    doc = "Old-style window: dark Bg, title bar, TitleText, CloseButton.",
    build = function(f)
      f.Bg = T(f, "BACKGROUND", "Interface\\DialogFrame\\UI-DialogBox-Background", { 0.05, 0.05, 0.05, 0.92 }, -6)
      f.Bg:SetPoint("TOPLEFT", 2, -2); f.Bg:SetPoint("BOTTOMRIGHT", -2, 2)
      f.TitleBg = T(f, "BACKGROUND", nil, nil, -5)
      f.TitleBg:SetColorTexture(0.16, 0.13, 0.1, 1)
      f.TitleBg:SetPoint("TOPLEFT", 2, -3); f.TitleBg:SetPoint("TOPRIGHT", -25, -3); f.TitleBg:SetHeight(18)
      Border(f, 0, METAL, 2)
      f.TitleText = FS(f, "GameFontHighlight")
      f.TitleText:SetPoint("TOP", 0, -5)
      f.CloseButton = CloseButton(f)
    end,
  },
  BasicFrameTemplateWithInset = {
    doc = "BasicFrameTemplate + InsetBg TOPLEFT 4,-24 to BOTTOMRIGHT -6,4.",
    inherits = { "BasicFrameTemplate" },
    build = function(f)
      f.InsetBg = T(f, "BACKGROUND", nil, nil, -4)
      f.InsetBg:SetColorTexture(0.02, 0.02, 0.02, 0.8)
      f.InsetBg:SetPoint("TOPLEFT", 4, -24); f.InsetBg:SetPoint("BOTTOMRIGHT", -6, 4)
    end,
  },
  UIPanelScrollBarTemplate = {
    doc = "Vertical scroll bar 16 wide: up/down buttons and a thumb.",
    size = { 16, 100 },
    build = function(f)
      local up = Child("Button", f)
      up:SetSize(18, 16); up:SetPoint("BOTTOM", f, "TOP", 0, 0)
      local un = up:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up")
      un._fallback, un._fromTemplate = { 0.35, 0.3, 0.25, 1 }, true
      un:SetTexCoord(0.2, 0.8, 0.25, 0.75)
      local down = Child("Button", f)
      down:SetSize(18, 16); down:SetPoint("TOP", f, "BOTTOM", 0, 0)
      local dn = down:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
      dn._fallback, dn._fromTemplate = { 0.35, 0.3, 0.25, 1 }, true
      dn:SetTexCoord(0.2, 0.8, 0.25, 0.75)
      local track = T(f, "BACKGROUND", nil, nil)
      track:SetColorTexture(0, 0, 0, 0.35)
      track:SetAllPoints()
      local thumb = T(f, "ARTWORK", "Interface\\Buttons\\UI-ScrollBar-Knob", { 0.55, 0.5, 0.4, 1 })
      thumb:SetTexCoord(0.2, 0.8, 0.125, 0.875)
      thumb:SetSize(18, 24)
      thumb:SetPoint("TOP", 0, 0)
      f.ScrollUpButton, f.ScrollDownButton, f.ThumbTexture = up, down, thumb
    end,
  },
  UIPanelScrollFrameTemplate = {
    doc = "ScrollFrame + ScrollBar (UIPanelScrollBarTemplate) outside its right edge (+6, -16..+16).",
    build = function(f)
      local bar = Child("Slider", f, "UIPanelScrollBarTemplate")
      bar:SetPoint("TOPLEFT", f, "TOPRIGHT", 6, -16)
      bar:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", 6, 16)
      bar:SetWidth(16)
      f.ScrollBar = bar
      if f._name then rawset(f._world.G or {}, f._name .. "ScrollBar", bar) end
    end,
  },
  ScrollFrameTemplate = {
    doc = "Modern ScrollFrame with a MinimalScrollBar inside the right edge.",
    build = function(f)
      local bar = Child("Frame", f, "MinimalScrollBar")
      bar:SetPoint("TOPLEFT", f, "TOPRIGHT", 8, 0)
      bar:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", 8, 0)
      f.ScrollBar = bar
    end,
  },
  MinimalScrollBar = {
    doc = "Thin modern scroll bar: track + thumb, 8 wide.",
    size = { 8, 100 },
    build = function(f)
      local track = T(f, "BACKGROUND", nil, nil)
      track:SetColorTexture(0, 0, 0, 0.4); track:SetAllPoints()
      local thumb = T(f, "ARTWORK", nil, nil)
      thumb:SetColorTexture(0.6, 0.55, 0.45, 1); thumb:SetPoint("TOPLEFT"); thumb:SetPoint("TOPRIGHT"); thumb:SetHeight(30)
    end,
  },
  WowScrollBoxList = {
    doc = "ScrollBox list: a clipping frame (contents are not populated by the mock).",
    build = function(f) f._clips = true end,
  },
  WowScrollBox = {
    doc = "ScrollBox: a clipping frame.",
    build = function(f) f._clips = true end,
  },
  WowTrimScrollBar = {
    doc = "Trimmed modern scroll bar: like MinimalScrollBar, 18 wide.",
    inherits = { "MinimalScrollBar" },
    size = { 18, 100 },
  },
  TooltipBackdropTemplate = {
    doc = "Tooltip-style backdrop: dark fill, grey border.",
    build = function(f)
      f._hasBackdropMixin = true
      f._backdrop = { bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 16 }
      f._backdropColor = { 0.05, 0.05, 0.05, 0.92 }
      f._backdropBorderColor = { 0.6, 0.6, 0.6, 1 }
    end,
  },
  InsetFrameTemplate3 = {
    doc = "Lighter nested inset (sub-panels inside a page).",
    build = function(f)
      f.Bg = T(f, "BACKGROUND", nil, nil, -6)
      f.Bg:SetColorTexture(0, 0, 0, 0.3); f.Bg:SetAllPoints()
      f._insetBorder = Border(f, 0, { 0.3, 0.27, 0.22, 1 }, 1)
    end,
  },
  InsetFrameTemplate4 = {
    doc = "Borderless dark inset.",
    build = function(f)
      f.Bg = T(f, "BACKGROUND", nil, nil, -6)
      f.Bg:SetColorTexture(0, 0, 0, 0.25); f.Bg:SetAllPoints()
    end,
  },
  MagicButtonTemplate = {
    doc = "UIPanelButtonTemplate for ButtonFrameTemplate's 26px bottom bar, 80x22 (border art when chained).",
    inherits = { "UIPanelButtonTemplate" },
    size = { 80, 22 },
  },
  UIPanelCloseButtonNoScripts = {
    doc = "UIPanelCloseButton without its OnClick (small X).",
    inherits = { "UIPanelCloseButton" },
  },
  MinimalCheckboxTemplate = {
    doc = "Modern check box 30x29: atlases checkbox-minimal / checkmark-minimal(-disabled). No label.",
    size = { 30, 29 },
    build = function(f)
      local n = f:SetNormalAtlas("checkbox-minimal")
      n._fallback, n._fromTemplate = { 0.1, 0.09, 0.08, 0.95 }, true
      local c = f:SetCheckedTexture("atlas:checkmark-minimal")
      c._fallback, c._fromTemplate = { 1, 0.82, 0, 0.6 }, true
      local d = f:SetDisabledCheckedTexture("atlas:checkmark-minimal-disabled")
      d._fallback, d._fromTemplate = { 0.5, 0.5, 0.5, 0.6 }, true
      local h = f:SetHighlightAtlas("checkbox-minimal", "ADD")
      h._fromTemplate = true
    end,
  },
  PanelTabButtonTemplate = {
    doc = "Bottom tab: 3-slice (uiframe-tab-*), GameFontNormalSmall; selected tab is disabled with white text (PanelTemplates_SetTab).",
    size = { 115, 32 },
    build = function(f)
      local function Slices(active)
        local l = T(f, "BACKGROUND", nil, active and { 0.32, 0.27, 0.2, 1 } or { 0.18, 0.15, 0.12, 1 })
        l:SetAtlas(active and "uiframe-activetab-left" or "uiframe-tab-left")
        l:SetAllPoints()
        if active then l:Hide() end
        return l
      end
      f.Middle = Slices(false)
      f.MiddleActive = Slices(true)
      f._normalFont, f._highlightFont, f._disabledFont = "GameFontNormalSmall", "GameFontHighlightSmall", "GameFontHighlightSmall"
      local fs = f:GetFontString()
      fs._fromTemplate = true
      fs:ClearAllPoints(); fs:SetPoint("CENTER", 0, 2)
      f.Text = fs
    end,
  },
  PanelTopTabButtonTemplate = {
    doc = "Top tab (PanelTabButtonTemplate turned upside down), 32 tall.",
    inherits = { "PanelTabButtonTemplate" },
  },
  WowStyle1DropdownTemplate = {
    doc = "DropdownButton 120x25 (common-dropdown-textholder + arrow); SetupMenu records the menu in dd._menu and shows the selected radio's text.",
    size = { 120, 25 },
    build = function(f)
      f.Background = T(f, "BACKGROUND", nil, { 0.08, 0.07, 0.06, 0.95 })
      f.Background:SetAtlas("common-dropdown-textholder"); f.Background:SetAllPoints()
      f.Arrow = T(f, "ARTWORK", nil, { 0.5, 0.42, 0.28, 0.95 })
      f.Arrow:SetAtlas("common-dropdown-a-button"); f.Arrow:SetSize(20, 20); f.Arrow:SetPoint("RIGHT", -2, 0)
      local fs = FS(f, "GameFontHighlightSmall")
      fs:SetPoint("LEFT", 8, 0); fs:SetPoint("RIGHT", f.Arrow, "LEFT", -2, 0)
      fs:SetJustifyH("LEFT"); fs:SetWordWrap(false)
      f:SetFontString(fs)
      f.Text = fs
      f._selectionText = true
      function f.SetupMenu(self, gen) self._menuGen = gen; GenerateMenu(self) end
      function f.GenerateMenu(self) GenerateMenu(self) end
      function f.SetDefaultText(self, t) self._defaultText = t; if (self._text or "") == "" then self:SetText(t) end end
      function f.OverrideText(self, t) self:SetText(t) end
    end,
  },
  WowStyle1FilterDropdownTemplate = {
    doc = "Filter DropdownButton 93x22 ('Filter' + arrow); SetupMenu records the menu in dd._menu.",
    size = { 93, 22 },
    build = function(f)
      f.Background = T(f, "BACKGROUND", nil, { 0.08, 0.07, 0.06, 0.95 })
      f.Background:SetAtlas("common-dropdown-textholder"); f.Background:SetAllPoints()
      f.Arrow = T(f, "ARTWORK", nil, { 0.5, 0.42, 0.28, 0.95 })
      f.Arrow:SetAtlas("common-dropdown-a-button"); f.Arrow:SetSize(16, 16); f.Arrow:SetPoint("RIGHT", -3, 0)
      local fs = FS(f, "GameFontHighlightSmall")
      fs:SetPoint("CENTER", -6, 0)
      f:SetFontString(fs)
      f.Text = fs
      fs:SetText("Filter")
      f._text = "Filter"
      function f.SetupMenu(self, gen) self._menuGen = gen; GenerateMenu(self) end
      function f.GenerateMenu(self) GenerateMenu(self) end
      function f.SetDefaultText(self, t) self:SetText(t) end
      function f.ValidateResetState() end
    end,
  },
  ScrollingEditBoxTemplate = {
    doc = "Scrolling multi-line EditBox: GetEditBox(), GetScrollBox(), SetText, GetInputText; clips its contents.",
    build = function(f)
      f._clips = true
      local box = Child("Frame", f)
      box:SetAllPoints()
      box._clips = true
      local edit = Child("EditBox", box)
      edit:SetMultiLine(true)
      edit._font = "GameFontHighlightSmall"
      edit:SetPoint("TOPLEFT", 0, 0)
      edit:SetPoint("TOPRIGHT", 0, 0)
      f.ScrollBox, f.EditBox = box, edit
      function f.GetEditBox(self) return self.EditBox end
      function f.GetScrollBox(self) return self.ScrollBox end
      function f.SetText(self, t) self.EditBox:SetText(t) end
      function f.GetInputText(self) return self.EditBox:GetText() end
      function f.ClearText(self) self.EditBox:SetText("") end
    end,
  },
  MinimalSliderWithSteppersTemplate = {
    doc = "Slider with back/forward steppers, 250x40 (MinimalSlider.xml art): Init(value, min, max, steps), SetValue, RegisterCallback(OnValueChanged).",
    size = { 250, 40 },
    build = function(f)
      -- Copied from MinimalSliderTemplate / MinimalSliderWithSteppersTemplate
      -- (Blizzard_SharedXML/Shared/Slider/MinimalSlider.xml).
      local s = Child("Slider", f)
      s:SetPoint("TOPLEFT", 19, 0); s:SetPoint("BOTTOMRIGHT", -19, 0)
      local left = T(s, "BACKGROUND", nil, { 0.3, 0.26, 0.2, 1 })
      left:SetAtlas("Minimal_SliderBar_Left", true); left:SetPoint("LEFT")
      local right = T(s, "BACKGROUND", nil, { 0.3, 0.26, 0.2, 1 })
      right:SetAtlas("Minimal_SliderBar_Right", true); right:SetPoint("RIGHT")
      local middle = T(s, "BACKGROUND", nil, { 0.3, 0.26, 0.2, 1 })
      middle:SetAtlas("_Minimal_SliderBar_Middle", true)
      middle:SetPoint("TOPLEFT", left, "TOPRIGHT"); middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT")
      s.Left, s.Right, s.Middle = left, right, middle
      local thumb = T(s, "ARTWORK", nil, { 0.8, 0.65, 0.35, 1 })
      thumb:SetAtlas("Minimal_SliderBar_Button", true); thumb:SetPoint("CENTER")
      s.Thumb = thumb
      local back = Child("Button", f)
      back:SetSize(11, 19); back:SetPoint("RIGHT", s, "LEFT", -4, 0)
      local bt = back:SetNormalAtlas("Minimal_SliderBar_Button_Left")
      bt._fallback, bt._fromTemplate = { 0.8, 0.65, 0.35, 1 }, true
      local fwd = Child("Button", f)
      fwd:SetSize(9, 18); fwd:SetPoint("LEFT", s, "RIGHT", 4, 0)
      local ft = fwd:SetNormalAtlas("Minimal_SliderBar_Button_Right")
      ft._fallback, ft._fromTemplate = { 0.8, 0.65, 0.35, 1 }, true
      back:SetScript("OnClick", function() s:SetValue(s:GetValue() - (s._step or 1)) end)
      fwd:SetScript("OnClick", function() s:SetValue(s:GetValue() + (s._step or 1)) end)
      f.Slider, f.Back, f.Forward = s, back, fwd
      f._callbacks = {}
      s:SetScript("OnValueChanged", function(_, v)
        for _, cb in ipairs(f._callbacks) do cb.fn(cb.owner, v) end
      end)
      function f.Init(self, value, min, max, steps)
        self._steps = steps
        self.Slider._step = (steps and steps > 0) and (max - min) / steps or 1
        self.Slider:SetMinMaxValues(min, max)
        self.Slider:SetValue(value)
      end
      function f.SetValue(self, v) self.Slider:SetValue(v) end
      function f.GetValue(self) return self.Slider:GetValue() end
      function f.RegisterCallback(self, _, fn, owner) table.insert(self._callbacks, { fn = fn, owner = owner }) end
    end,
  },
  OptionsSliderTemplate = {
    doc = "Old horizontal slider 144x17 with Low/High/Text labels.",
    size = { 144, 17 },
    build = function(f)
      local track = T(f, "BACKGROUND", "Interface\\Buttons\\UI-SliderBar-Background", { 0.15, 0.13, 0.1, 1 })
      track:SetAllPoints()
      f.Text = FS(f, "GameFontHighlight"); f.Text:SetPoint("BOTTOM", f, "TOP", 0, 2)
    end,
  },
  LargeSideTabButtonTemplate = {
    doc = "Side tab 43x55 (CharacterFrame / spellbook side tabs): background art, icon, SetIcon, SetChecked.",
    size = { 43, 55 },
    build = function(f)
      f.Background = T(f, "BACKGROUND", "Interface\\SpellBook\\SpellBook-SkillLineTab", { 0.25, 0.2, 0.14, 1 })
      f.Background:SetSize(64, 64); f.Background:SetPoint("TOPLEFT", -3, 11)
      f.Icon = T(f, "ARTWORK", nil, nil)
      f.Icon:SetSize(30, 30); f.Icon:SetPoint("CENTER", -4, 0)
      f.SelectedTexture = T(f, "OVERLAY", "Interface\\Buttons\\CheckButtonHilight", { 1, 0.82, 0, 0.3 })
      f.SelectedTexture:SetBlendMode("ADD"); f.SelectedTexture:SetSize(36, 36); f.SelectedTexture:SetPoint("CENTER", f.Icon)
      f.SelectedTexture:Hide()
      local h = f:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
      h._fromTemplate = true
      function f.SetIcon(self, tex) self.Icon:SetTexture(tex) end
      function f.SetChecked(self, v) self._checked = v and true or false; self.SelectedTexture:SetShown(self._checked) end
      function f.GetChecked(self) return self._checked end
    end,
  },
  UIPanelGoldButtonTemplate = {
    doc = "Gold-trimmed panel button (UIPanelButtonTemplate look in the mock).",
    inherits = { "UIPanelButtonTemplate" },
  },
  ShadowOverlayTemplate = {
    doc = "Inner vignette over a panel (corner shadows); no layout effect.",
    build = function(f) f:EnableMouse(false) end,
  },
  SecureActionButtonTemplate = { doc = "Secure button: no visuals of its own." },
  SecureHandlerBaseTemplate = { doc = "Secure handler: no visuals." },
}

function M.ApplyTemplates(f, templates)
  if type(templates) ~= "string" then return end
  for name in templates:gmatch("[^,%s]+") do
    local tpl = M.TEMPLATES[name]
    if not tpl then
      f._unknownTemplates = f._unknownTemplates or {}
      table.insert(f._unknownTemplates, name)
    else
      for _, parent in ipairs(tpl.inherits or {}) do M.ApplyTemplates(f, parent) end
      if tpl.size and not f._w then f._w, f._h = tpl.size[1], tpl.size[2] end
      if tpl.build and not f._region then tpl.build(f) end
      f._templates = f._templates or {}
      table.insert(f._templates, name)
    end
  end
end

-- CreateFrame(type, name, parent, templates, id). Named frames become globals.
function M.CreateFrame(W, ftype, name, parent, templates, id)
  if type(parent) == "string" then parent = W.G and rawget(W.G, parent) end
  local f = NewObject(W, ftype or "Frame", name, parent)
  if id then f._idNum = id end
  W.frames[#W.frames + 1] = f
  if name and W.G then rawset(W.G, name, f) end
  if templates then M.ApplyTemplates(f, templates) end
  return f
end

-- Font objects: globals like GameFontNormal with GetFont/SetFont/SetTextColor.
local FontObject = {}
FontObject.__index = function(_, k)
  local m = FontObject[k]
  if m then return m end
  if type(k) == "string" and k:match("^%u") then return noop end
end
function FontObject:GetFont() local s = self._spec return s.face == "arialn" and "Fonts\\ARIALN.TTF" or "Fonts\\FRIZQT__.TTF", s.size, s.outline and "OUTLINE" or "" end
function FontObject:GetTextColor() local c = self._spec.color or WHITE return c[1], c[2], c[3], 1 end
function FontObject:SetTextColor(r, g, b) self._spec.color = { r, g, b } end
function FontObject:SetFont(path, size, flags)
  self._spec.size = size or self._spec.size
  self._spec.face = tostring(path or ""):lower():find("arialn") and "arialn" or self._spec.face
  self._spec.outline = flags and tostring(flags):find("OUTLINE") and true or nil
end
function FontObject:GetName() return self._name end
function FontObject:GetObjectType() return "Font" end
function FontObject:CopyFontObject(other) local s = M.FontSpec(nil, other) for k, v in pairs(s) do self._spec[k] = v end end

function M.NewFontObject(name, spec)
  local s = {}
  for k, v in pairs(spec or M.FONTS[M.DEFAULT_FONT]) do s[k] = v end
  return setmetatable({ _name = name, _spec = s, _fontObject = true }, FontObject)
end

-- Adds the frame API to the mock's API table A.
function M.Install(W, A, toc)
  W.addonDir = toc and toc.dir
  W.screen = W.screen or { w = 1280, h = 800 }
  W.fonts = {}
  for name, spec in pairs(M.FONTS) do
    local fo = M.NewFontObject(name, spec)
    W.fonts[name] = fo
    A[name] = fo
  end
  A.CreateFont = function(name)
    local fo = M.NewFontObject(name)
    if name then W.fonts[name] = fo; rawset(W.G or {}, name, fo) end
    return fo
  end
  A.CreateFrame = function(ftype, name, parent, templates, id)
    return M.CreateFrame(W, ftype, name, parent, templates, id)
  end
  local ui = NewObject(W, "Frame", "UIParent", nil)
  ui._isScreen = true
  A.UIParent = ui
  A.WorldFrame = ui
  A.GetScreenWidth = function() return W.screen.w end
  A.GetScreenHeight = function() return W.screen.h end
  A.GameTooltip = NewObject(W, "GameTooltip", "GameTooltip", ui)
  A.GameTooltip._shown = false
  A.RaidWarningFrame = NewObject(W, "Frame", "RaidWarningFrame", ui)
  A.LootFrame = NewObject(W, "Frame", "LootFrame", ui)
  A.LootFrame._shown = false
  -- Templates the mock emulates exist; the addon checks with GetTemplateInfo.
  A.C_XMLUtil = {
    GetTemplateInfo = function(name)
      local tpl = M.TEMPLATES[name]
      if not tpl then return nil end
      return { type = "Frame", width = tpl.size and tpl.size[1] or 0, height = tpl.size and tpl.size[2] or 0 }
    end,
  }
  A.CLASS_ICON_TCOORDS = CLASS_TCOORDS
  M.InstallUI(W, A)
end

-- Colour objects (ColorMixin): GetRGB, GetRGBA, WrapTextInColorCode, ...
local ColorMixin = {}
ColorMixin.__index = ColorMixin
function ColorMixin:GetRGB() return self.r, self.g, self.b end
function ColorMixin:GetRGBA() return self.r, self.g, self.b, self.a end
function ColorMixin:GenerateHexColor()
  return string.format("ff%02x%02x%02x", math.floor(self.r * 255 + 0.5), math.floor(self.g * 255 + 0.5), math.floor(self.b * 255 + 0.5))
end
function ColorMixin:GenerateHexColorMarkup() return "|c" .. self:GenerateHexColor() end
function ColorMixin:WrapTextInColorCode(text) return "|c" .. self:GenerateHexColor() .. tostring(text) .. "|r" end
function ColorMixin:IsEqualTo(o) return o and self.r == o.r and self.g == o.g and self.b == o.b end
local function CreateColor(r, g, b, a) return setmetatable({ r = r, g = g, b = b, a = a or 1 }, ColorMixin) end
M.CreateColor = CreateColor

local CLASS_COLORS = {
  HUNTER = { 0.67, 0.83, 0.45 }, WARRIOR = { 0.78, 0.61, 0.43 }, MAGE = { 0.25, 0.78, 0.92 },
  ROGUE = { 1, 0.96, 0.41 }, PRIEST = { 1, 1, 1 }, WARLOCK = { 0.53, 0.53, 0.93 },
  PALADIN = { 0.96, 0.55, 0.73 }, DRUID = { 1, 0.49, 0.04 }, SHAMAN = { 0, 0.44, 0.87 },
}

local function Rec(W, name, ...)
  local list = W.calls[name]
  if not list then list = {}; W.calls[name] = list end
  list[#list + 1] = { n = select("#", ...), ... }
end

-- Key names as GetBindingText gives them (full, or abbreviated like the bars).
local KEY_NAMES = { BUTTON1 = "Left Mouse Button", BUTTON2 = "Right Mouse Button", BUTTON3 = "Middle Mouse",
  BUTTON4 = "Mouse Button 4", BUTTON5 = "Mouse Button 5", MOUSEWHEELUP = "Mouse Wheel Up",
  MOUSEWHEELDOWN = "Mouse Wheel Down", SPACE = "Spacebar", ESCAPE = "Escape" }
local KEY_SHORT = { BUTTON3 = "M3", BUTTON4 = "M4", BUTTON5 = "M5", MOUSEWHEELUP = "MwU", MOUSEWHEELDOWN = "MwD", SPACE = "Spc" }
local MODIFIERS = { SHIFT = "Shift", ALT = "Alt", CTRL = "Ctrl", META = "Meta" }
local function BindingText(key, prefix, abbreviate)
  if not key or key == "" then return "" end
  local mods, base = {}, key
  while true do
    local m, rest = base:match("^(%u+)%-(.+)$")
    if not m or not MODIFIERS[m] then break end
    mods[#mods + 1] = m
    base = rest
  end
  local out = {}
  for _, m in ipairs(mods) do
    out[#out + 1] = abbreviate and (m:sub(1, 1):lower() .. "-") or (MODIFIERS[m] .. "-")
  end
  local name = abbreviate and (KEY_SHORT[base] or base) or (KEY_NAMES[base] or base)
  return (prefix or "") .. table.concat(out) .. name
end
M.BindingText = BindingText

-- UI globals the window uses: panels, popups, colours, atlases, tabs, menus,
-- binding overrides and the Gamepad UI style.
--   W.popup         the last StaticPopup shown ({ which, info, text, data })
--   W.AcceptPopup() clicks its first button (runs OnAccept); false if none
--   W.overrides     [key] = { owner, command } from SetOverrideBindingClick
--   W.gamepadUI     true: C_InputInterfaceStyle reports the Gamepad UI
function M.InstallUI(W, A)
  W.popups, W.overrides = {}, {}
  A.ShowUIPanel = function(f) Rec(W, "ShowUIPanel", f); if f then f:Show() end end
  A.HideUIPanel = function(f) Rec(W, "HideUIPanel", f); if f then f:Hide() end end
  A.StaticPopupDialogs = {}
  A.StaticPopup_Show = function(which, t1, t2, data)
    Rec(W, "StaticPopup_Show", which, t1, t2, data)
    local info = A.StaticPopupDialogs[which]
    if not info then return nil end
    local args = { t1, t2 }
    local n = 0
    local text = tostring(info.text or ""):gsub("%%s", function() n = n + 1; return tostring(args[n] or "") end)
    local dialog = { which = which, info = info, text = text, data = data }
    W.popups[#W.popups + 1] = dialog
    W.popup = dialog
    return dialog
  end
  A.StaticPopup_Hide = function() W.popup = nil end
  A.StaticPopup_Visible = function(which) return W.popup and W.popup.which == which and W.popup or nil end
  W.AcceptPopup = function()
    local d = W.popup
    if not d then return false end
    W.popup = nil
    if d.info.OnAccept then d.info.OnAccept(d, d.data) end
    return true
  end
  A.GetBindingText = BindingText
  A.NOT_BOUND, A.YES, A.NO, A.OKAY, A.CANCEL = "Not Bound", "Yes", "No", "Okay", "Cancel"
  A.SEARCH, A.FILTER, A.RESET = "Search", "Filter", "Reset"
  A.C_Texture = setmetatable({
    GetAtlasInfo = function(name)
      local a = type(name) == "string" and M.ATLASES[name:lower()]
      if not a then return nil end
      return { width = a[1], height = a[2], file = "atlas:" .. name,
        leftTexCoord = 0, rightTexCoord = 1, topTexCoord = 0, bottomTexCoord = 1 }
    end,
  }, { __index = function() return noop end })
  A.CreateAtlasMarkup = function(atlas, w, h) return string.format("|A:%s:%d:%d|a", atlas, h or w or 0, w or 0) end
  A.SetOverrideBindingClick = function(owner, _, key, button, mouse)
    Rec(W, "SetOverrideBindingClick", owner, key, button)
    W.overrides[key] = { owner = owner, command = "CLICK " .. tostring(button) .. ":" .. (mouse or "LeftButton") }
  end
  A.SetOverrideBinding = function(owner, _, key, command)
    W.overrides[key] = command and { owner = owner, command = command } or nil
  end
  A.ClearOverrideBindings = function(owner)
    Rec(W, "ClearOverrideBindings", owner)
    for k, v in pairs(W.overrides) do if v.owner == owner then W.overrides[k] = nil end end
  end
  A.CreateColor = CreateColor
  A.NORMAL_FONT_COLOR = CreateColor(1, 0.82, 0)
  A.HIGHLIGHT_FONT_COLOR = CreateColor(1, 1, 1)
  A.WHITE_FONT_COLOR = CreateColor(1, 1, 1)
  A.GRAY_FONT_COLOR = CreateColor(0.5, 0.5, 0.5)
  A.DISABLED_FONT_COLOR = CreateColor(0.5, 0.5, 0.5)
  A.RED_FONT_COLOR = CreateColor(1, 0.125, 0.125)
  A.GREEN_FONT_COLOR = CreateColor(0.1, 1, 0.1)
  A.ORANGE_FONT_COLOR = CreateColor(1, 0.5, 0.25)
  A.YELLOW_FONT_COLOR = CreateColor(1, 1, 0)
  A.LIGHTBLUE_FONT_COLOR = CreateColor(0.53, 0.67, 1)
  A.C_ClassColor = {
    GetClassColor = function(class)
      local c = CLASS_COLORS[class]
      return c and CreateColor(c[1], c[2], c[3]) or nil
    end,
  }
  A.GameTooltip_SetTitle = function(tt, text) tt:SetText(text) end
  A.GameTooltip_AddNormalLine = function(tt, text) tt:AddLine(text) end
  A.GameTooltip_AddHighlightLine = function(tt, text) tt:AddLine(text) end
  A.GameTooltip_AddColoredLine = function(tt, text) tt:AddLine(text) end
  A.SmartNavigation_MarkFrameIgnored = noop
  A.SmartNavigation_MarkFrameSubSection = noop
  A.ScrollUtil = { RegisterScrollBoxWithScrollBar = noop, InitScrollBoxListWithScrollBar = noop }
  A.MinimalSliderWithSteppersMixin = { Event = { OnValueChanged = "OnValueChanged" } }
  A.C_InputInterfaceStyle = { GetCurrentStyle = function() return W.gamepadUI and 1 or 0 end }
  if type(A.Enum) == "table" then
    rawset(A.Enum, "InputDeviceInterfaceType", { KeyboardAndMouse = 0, Gamepad = 1 })
  end
  -- Tabs: PanelTemplates_* (the selected tab is disabled, with white text and active art).
  local function Tabs(frame) return frame.Tabs or {} end
  A.PanelTemplates_SetNumTabs = function(frame, n) frame.numTabs = n end
  A.PanelTemplates_GetSelectedTab = function(frame) return frame.selectedTab end
  A.PanelTemplates_UpdateTabs = function(frame)
    for i, tab in ipairs(Tabs(frame)) do
      local sel = i == frame.selectedTab
      tab:SetEnabled(not sel)
      if tab.Middle then tab.Middle:SetShown(not sel) end
      if tab.MiddleActive then tab.MiddleActive:SetShown(sel) end
    end
  end
  A.PanelTemplates_SetTab = function(frame, id)
    frame.selectedTab = id
    A.PanelTemplates_UpdateTabs(frame)
  end
  A.PanelTemplates_TabResize = function(tab, padding, absoluteSize, minWidth, maxWidth)
    local w = absoluteSize or (tab:GetTextWidth() + 20 + (padding or 0))
    if minWidth then w = math.max(w, minWidth) end
    if maxWidth then w = math.min(w, maxWidth) end
    tab:SetWidth(w)
  end
  A.PanelTemplates_ResizeTabsToFit = function(frame, maxWidth)
    local total = 0
    for _, tab in ipairs(Tabs(frame)) do A.PanelTemplates_TabResize(tab, 0); total = total + tab:GetWidth() end
    if maxWidth and total > maxWidth then
      local k = maxWidth / total
      for _, tab in ipairs(Tabs(frame)) do tab:SetWidth(tab:GetWidth() * k) end
    end
  end
  M.InstallInput(W, A)
end

-- Input, glyph, sound and effect globals the v2 window reads (dev/ui-spec-v2.md §11.3).
--   W.mods          { shift=, ctrl=, alt= } drives IsShiftKeyDown & co.
--   W.keyFocus      what GetCurrentKeyBoardFocus returns
--   W.labelStyle    "Letters" (default), "Shapes" or "Reverse" for the glyph utility
--   W.framerate     GetFramerate (default 60)
--   W.vibrations    C_GamePad.SetVibration calls
-- Absent on purpose (false, so the addon's existence checks see "missing"):
-- GamepadMode, SmartNavigation, NineSliceUtil, GlowEmitterFactory unless a test
-- sets W.api.<name> in setup(W), RegisterGameMenuEscHandler.
local MOVEMENT = { W = "MOVEFORWARD", S = "MOVEBACKWARD", A = "STRAFELEFT", D = "STRAFERIGHT", Q = "TURNLEFT",
  E = "TURNRIGHT", SPACE = "JUMP", UP = "MOVEFORWARD", DOWN = "MOVEBACKWARD", LEFT = "TURNLEFT", RIGHT = "TURNRIGHT",
  NUMLOCK = "TOGGLEAUTORUN", ESCAPE = "TOGGLEGAMEMENU" }
local GLYPHS = {
  Letters = { PAD1 = "gamepad-xbox1-buttona-normal", PAD2 = "gamepad-xbox1-buttonb-normal", PAD3 = "gamepad-xbox1-buttonx-normal",
    PAD4 = "gamepad-xbox1-buttony-normal", PADLSHOULDER = "gamepad-xbox1-trigger-lb-normal", PADRSHOULDER = "gamepad-xbox1-trigger-rb-normal",
    PADLTRIGGER = "gamepad-xbox1-trigger-lt-normal", PADRTRIGGER = "gamepad-xbox1-trigger-rt-normal", PADDUP = "gamepad-xbox1-dpadup-normal",
    PADDDOWN = "gamepad-xbox1-dpaddown-normal", PADDLEFT = "gamepad-xbox1-dpadleft-normal", PADDRIGHT = "gamepad-xbox1-dpadright-normal" },
  Shapes = { PAD1 = "gamepad-ps-buttoncrox-normal", PAD2 = "gamepad-ps-buttoncircle-normal", PAD3 = "gamepad-ps-buttonsquare-normal",
    PAD4 = "gamepad-ps-buttontriangle-normal", PADLSHOULDER = "gamepad-ps-triggerl1-normal", PADRSHOULDER = "gamepad-ps-triggerr1-normal",
    PADLTRIGGER = "gamepad-ps-triggerl2-normal", PADRTRIGGER = "gamepad-ps-triggerr2-normal" },
}
function M.InstallInput(W, A)
  W.mods, W.vibrations = W.mods or {}, W.vibrations or {}
  A.IsShiftKeyDown = function() return W.mods.shift and true or false end
  A.IsControlKeyDown = function() return W.mods.ctrl and true or false end
  A.IsAltKeyDown = function() return W.mods.alt and true or false end
  A.IsModifierKeyDown = function() return (W.mods.shift or W.mods.ctrl or W.mods.alt) and true or false end
  A.GetBindingFromClick = function(key)
    local b = W.bindings and W.bindings[key]
    if b and b ~= "" then return b end
    return MOVEMENT[key]
  end
  A.GetCurrentKeyBoardFocus = function() return W.keyFocus end
  A.GetFramerate = function() return W.framerate or 60 end
  A.RegisterGameMenuEscHandler = false
  A.GameMenuEscPriority = { AddOn = 3 }
  A.GamepadMode = false
  A.SmartNavigation = false
  A.NineSliceUtil = false
  A.GlowEmitterFactory = false
  A.InputIconTextureSetUtility = {
    GetNormalActiveInputIconButtonTexture = function(key)
      local set = GLYPHS[W.labelStyle or "Letters"] or GLYPHS.Letters
      return set[key]
    end,
  }
  A.InputDeviceIconSetManager = { RegisterActiveInputDeviceIconSetUpdatedCallback = function(_, fn, owner)
    W.iconSetCallbacks = W.iconSetCallbacks or {}
    table.insert(W.iconSetCallbacks, { fn = fn, owner = owner })
  end }
  local sk = A.SOUNDKIT or {}
  A.SOUNDKIT = sk
  for k, v in pairs({ IG_CHARACTER_INFO_OPEN = 839, IG_CHARACTER_INFO_CLOSE = 840, IG_CHARACTER_INFO_TAB = 841,
    U_CHAT_SCROLL_BUTTON = 1115, UI_CLASS_TALENT_TAB = 207760, IG_MAINMENU_OPTION = 852,
    IG_MAINMENU_OPTION_CHECKBOX_ON = 856, IG_MAINMENU_OPTION_CHECKBOX_OFF = 857, UI_CLASS_TALENT_APPLY_CHANGES = 207767,
    UI_CLASS_TALENT_APPLY_COMPLETE = 212391, GS_TITLE_OPTION_OK = 798, UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST = 73919,
    UI_CLASS_TALENT_LEARN_TALENT = 217825, IG_ABILITY_PAGE_TURN = 836 }) do sk[k] = v end
end

return M
