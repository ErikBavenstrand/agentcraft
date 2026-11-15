-- The Inspector pane (dev/ui-spec-v2.md §7): the right-hand column that
-- explains whatever is focused, so nothing is hover-only. The window builds
-- one with UI.NewInspector(host) and clears it before each node's acInspect.
--
--   pane:Clear()
--   pane:Header(icon, title [, kind [, glyphKeys]])  56 px icon, title, kind line; glyphKeys {"PADRTRIGGER","PAD1"} = "RT + A"
--   pane:Section(text)                               section title plate
--   pane:Row(label, value [, color, icon])           zebra row
--   pane:Layers(list)                                { {label, icon, name, color}, ... }
--   pane:Diff(now, after)                            { icon, name, color } -> { icon, name, color }
--   pane:Text(text [, color])                        wrapped body text
--   pane:CrossRef(list)                              { {text, fn, color}, ... }: focusable "Also on" lines
--   pane:Code(text)                                  read-only macro text, 7 lines
--   pane:Buttons(list)                               { {label, fn, enabled, confirm, tooltip}, ... } docked at the bottom
--   pane:Empty(text)                                 a dim hint
--   pane:BarCard(bar)                                { title, rows = { {key, icon, name, color, node, focused}, ... } }
--   pane:Glyphs(keys)                                a row of glyphs ("RT + A")
-- Blocks stack top-down with 8 px gaps; overflow scrolls (pane.scroll).
local _, ns = ...
local UI = ns.UI

local GAP = 8
local Pane = {}

-- Ink mode: when the pane sits on light parchment (the Macros book's right
-- page), body text is dark ink and state colours are darkened, as Blizzard's
-- parchment UIs do (QuestFont / GameFontBlack, about 0.18, 0.12, 0.06).
-- pane.inkFn() (set by the window) decides it at each Clear.
local INK, INK_LABEL, INK_DIM = { 0.18, 0.12, 0.06 }, { 0.27, 0.13, 0.0 }, { 0.30, 0.25, 0.20 }
-- Paints fs: kind "body" (white default), "label" (gold default) or "dim".
function Pane:Paint(fs, color, kind)
  if self.ink then
    if color then
      local r, g, b = UI.RGB(color)
      fs:SetTextColor(r * 0.55, g * 0.55, b * 0.55)
    else
      local c = (kind == "label" and INK_LABEL) or (kind == "dim" and INK_DIM) or INK
      fs:SetTextColor(c[1], c[2], c[3])
    end
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0) end
  else
    if color then fs:SetTextColor(UI.RowRGB(color)) -- readable on the zebra bars
    elseif kind == "label" then fs:SetTextColor(1, 0.82, 0)
    elseif kind == "dim" then fs:SetTextColor(0.72, 0.72, 0.72)
    else fs:SetTextColor(1, 1, 1) end
    if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 1) end
  end
end

local function Acquire(self, kind, make)
  self.pools[kind] = self.pools[kind] or { free = {}, used = {} }
  local pool = self.pools[kind]
  local f = table.remove(pool.free)
  if not f then
    f = make()
    if UI.PixelSnap then UI.PixelSnap(f) end
  end
  table.insert(pool.used, f)
  if not rawget(f, "_acNamed") then
    pool.n = (pool.n or 0) + 1
    UI.Name(f, "ac" .. kind .. pool.n)
    rawset(f, "_acNamed", true)
  end
  f:ClearAllPoints()
  f:Show()
  return f
end

-- Places a block at the cursor and advances it.
function Pane:Place(f, h, x)
  f:SetPoint("TOPLEFT", self.child, "TOPLEFT", x or 0, -self.y)
  f:SetPoint("TOPRIGHT", self.child, "TOPRIGHT", 0, -self.y)
  f:SetHeight(h)
  self.y = self.y + h + GAP
  self.child:SetHeight(math.max(self.y, 1))
  if self.UpdateFades then self:UpdateFades() end
  return f
end

function Pane:Width() return math.max((self.host:GetWidth() or 264) - 8 - 26, 100) end

-- Releases every block. Blocks go back in reverse, so the next fill gets the
-- same frame for the same block: a node focused inside the Inspector (a
-- cross-reference, a BarCard row) stays the same frame with the same content
-- across a re-inspect, instead of swapping with its neighbours.
function Pane:Clear()
  for _, pool in pairs(self.pools) do
    for i = #pool.used, 1, -1 do
      local f = pool.used[i]
      f:Hide()
      table.insert(pool.free, f)
    end
    pool.used = {}
  end
  self.y, self.zebra = 4, 0
  local ok, ink = true, false
  if self.inkFn then ok, ink = pcall(self.inkFn) end
  self.ink = ok and ink and true or false
  self.child:SetHeight(1)
  if self.scroll.SetVerticalScroll then self.scroll:SetVerticalScroll(0) end
  self:LayoutDock(0)
  -- Edge fades: black on the dark stone, parchment-toned on the book page.
  if self.fades then
    if self.ink then self.fades:SetTone(0.62, 0.50, 0.33, 0.6, 0.7) else self.fades:SetTone(0, 0, 0) end
  end
end

-- Puts the scroll back to v (clamped) after a refill of the same subject, so
-- a Refresh doesn't jump the Inspector back to its top.
function Pane:RestoreScroll(v)
  if not (v and v > 0 and self.scroll.SetVerticalScroll) then return end
  local range = math.max((self.child:GetHeight() or 0) - (self.scroll:GetHeight() or 0), 0)
  self.scroll:SetVerticalScroll(math.min(v, range))
  if self.UpdateFades then self:UpdateFades() end
end

local function NewText(parent, font)
  local fs = UI.Text(parent, "", font)
  fs:SetJustifyH("LEFT")
  fs:SetJustifyV("TOP")
  return fs
end

function Pane:Glyphs(keys, parent, size)
  local holder = parent or Acquire(self, "glyphs", function()
    local f = CreateFrame("Frame", nil, self.child)
    f.items = {}
    return f
  end)
  holder.items = holder.items or {}
  for _, g in ipairs(holder.items) do g:Hide() end
  local x = 0
  for i, k in ipairs(keys or {}) do
    local g = holder.items[i * 2 - 1]
    if not g then g = UI.Glyph(holder, k, size or 22, "pad"); holder.items[i * 2 - 1] = g end
    g:SetKey(k)
    g:ClearAllPoints()
    g:SetPoint("LEFT", holder, "LEFT", x, 0)
    g:Show()
    x = x + (g.width or 22) + 4
    if i < #keys then
      local plus = holder.items[i * 2]
      if not plus then
        plus = CreateFrame("Frame", nil, holder)
        plus:SetSize(10, 22)
        plus.t = UI.Text(plus, "+", "GameFontHighlight")
        plus.t:SetPoint("CENTER")
        holder.items[i * 2] = plus
      end
      plus:ClearAllPoints()
      plus:SetPoint("LEFT", holder, "LEFT", x, 0)
      plus:Show()
      x = x + 14
    end
  end
  holder.glyphWidth = x
  if not parent then self:Place(holder, size or 22) end
  return holder
end

function Pane:Header(icon, title, kind, glyphKeys)
  local f = Acquire(self, "header", function()
    local h = CreateFrame("Frame", nil, self.child)
    -- The gear slot is the frame and its empty-slot wings: it goes under
    -- the icon (BACKGROUND), as PaperDollFrame's BorderFrame art. On
    -- ARTWORK sublevel 1 it covered the icon, so every header showed the
    -- winged empty slot (capture s01-s45).
    h.slot = h:CreateTexture(nil, "BACKGROUND", nil, 1)
    h.slot:SetSize(64, 64)
    h.slot:SetPoint("TOPLEFT", 0, 0)
    UI.SetAtlas(h.slot, UI.ART.gearSlot)
    h.icon = h:CreateTexture(nil, "ARTWORK", nil, 1)
    h.icon:SetSize(52, 52)
    h.icon:SetPoint("CENTER", h.slot, "CENTER")
    h.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    h.glyphs = CreateFrame("Frame", nil, h)
    h.glyphs:SetHeight(22)
    h.title = NewText(h, "GameFontNormalMed3")
    h.kind = NewText(h, "GameFontHighlight")
    -- Ink mode only: a dark plate behind the title and kind line. The
    -- parchment page's top band is dark, so dark ink there is unreadable;
    -- on this plate the title stays gold and the kind line light, as on
    -- Blizzard's own book headers.
    h.plate = UI.Gradient(h, "BACKGROUND", "HORIZONTAL", { 0.08, 0.05, 0.02, 0.72 }, { 0.08, 0.05, 0.02, 0.2 })
    h.plate:SetPoint("TOPLEFT", -4, 4)
    h.plate:SetPoint("BOTTOMRIGHT", 4, -4)
    h.plate:Hide()
    return h
  end)
  local w = self:Width()
  local hasIcon = icon ~= nil
  f.slot:SetShown(hasIcon); f.icon:SetShown(hasIcon)
  if hasIcon then f.icon:SetTexture(icon) end
  local x = hasIcon and 72 or 0
  local y = 0
  if glyphKeys and #glyphKeys > 0 then
    f.glyphs:ClearAllPoints()
    f.glyphs:SetPoint("TOPLEFT", x, 0)
    f.glyphs:SetWidth(w - x)
    self:Glyphs(glyphKeys, f.glyphs, 22)
    f.glyphs:Show()
    y = 26
  else
    f.glyphs:Hide()
  end
  f.title:ClearAllPoints()
  f.title:SetPoint("TOPLEFT", x, -y)
  f.title:SetWidth(w - x)
  f.title:SetText(title or "")
  f.plate:SetShown(self.ink)
  local ink = self.ink
  self.ink = false -- the header paints light on its own dark plate
  self:Paint(f.title, nil, "label")
  if f.title.SetMaxLines then f.title:SetMaxLines(2) end
  local th = math.min(f.title:GetStringHeight() or 14, 32)
  f.kind:ClearAllPoints()
  f.kind:SetPoint("TOPLEFT", x, -(y + th + 4))
  f.kind:SetWidth(w - x)
  f.kind:SetText(kind or "")
  self:Paint(f.kind)
  self.ink = ink
  local kh = (kind and kind ~= "") and (f.kind:GetStringHeight() or 12) or 0
  self:Place(f, math.max(hasIcon and 64 or 0, y + th + 4 + kh))
  return f
end

function Pane:Section(text)
  local f = Acquire(self, "section", function()
    local s = CreateFrame("Frame", nil, self.child)
    -- The character sheet's category plate at its own size (196x40,
    -- CharacterStatFrameCategoryTemplate), centred on the row; its
    -- transparent margins reach into the gaps above and below.
    s.plate = s:CreateTexture(nil, "BACKGROUND")
    s.plate:SetPoint("CENTER", 0, 0)
    s.native = UI.SetAtlas(s.plate, UI.ART.title, true)
    if not s.native then
      s.plate:SetAllPoints()
      s.plate:SetTexture(UI.WHITE); s.plate:SetVertexColor(0.9, 0.62, 0.32, 0.18)
    end
    s.plateW = s.plate:GetWidth() or 196
    -- Centred between the title plate's end ornaments (character sheet style).
    s.text = UI.Text(s, "", "GameFontHighlight")
    s.text:SetPoint("CENTER", 0, 1)
    s.text:SetJustifyH("CENTER")
    s.text:SetWordWrap(false)
    return s
  end)
  f.text:SetText(text or "")
  -- Wider than the plate only when the text needs it (never narrower).
  local room = self:Width()
  local sw = (f.text.GetUnboundedStringWidth and f.text:GetUnboundedStringWidth()) or f.text:GetStringWidth() or 0
  local want = math.min(math.ceil(sw) + 44, room)
  if f.native then f.plate:SetWidth(math.max(f.plateW, want)) end
  f.text:SetWidth(math.max(math.max(f.plateW, want) - 44, 1))
  self.zebra = 0
  return self:Place(f, 24)
end

local function RowFrame(self)
  return Acquire(self, "row", function()
    local r = CreateFrame("Frame", nil, self.child)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(18, 18)
    r.label = UI.Text(r, "", "GameFontNormal")
    r.label:SetJustifyH("LEFT")
    r.label:SetWordWrap(false)
    r.value = UI.Text(r, "", "GameFontHighlight")
    r.value:SetJustifyH("RIGHT")
    r.value:SetWordWrap(false)
    return r
  end)
end

-- Stat-row stripes as on the character sheet: every other row shows the
-- stripe (PaperDollFrame alternates them), at the stripe's own height,
-- centred and as wide as the pane. Never squashed or stretched vertically.
local function Zebra(self, r)
  self.zebra = self.zebra + 1
  local bg = r.bg
  bg:ClearAllPoints()
  bg:SetAlpha(1)
  if self.zebra % 2 == 0 then bg:Hide() return end
  if UI.SetAtlas(bg, UI.ART.zebra2, true) then
    bg:SetPoint("CENTER")
    bg:SetWidth(self:Width())
  else
    bg:SetAllPoints()
    bg:SetTexture(UI.WHITE); bg:SetVertexColor(1, 1, 1, 0.06)
  end
  bg:Show()
  -- The stripes are dark: on parchment only a hint, so ink stays readable.
  if self.ink then bg:SetAlpha(0.12) end
end

-- A row value that is wider than its room wraps to a second line (and the
-- row grows to 36 px) instead of being cut ("Waiting · Raw Bristle Whisker
-- Catfish is cleared when you apply" lost its end in the capture). More
-- than two lines truncate with "...". Returns the row height.
local function FitValue(fs, room)
  fs:SetWidth(math.max(math.floor(room), 1))
  local full = (fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth()) or fs:GetStringWidth() or 0
  local two = full > room
  fs:SetWordWrap(two)
  if fs.SetMaxLines then fs:SetMaxLines(two and 2 or 1) end
  return two and 36 or 24
end

function Pane:Row(label, value, color, icon)
  local r = RowFrame(self)
  Zebra(self, r)
  r.icon:ClearAllPoints()
  r.label:ClearAllPoints(); r.value:ClearAllPoints()
  local x = 6
  if icon then
    r.icon:SetPoint("LEFT", x, 0); r.icon:SetTexture(icon); r.icon:SetDesaturated(false); r.icon:Show()
    x = x + 22
  else r.icon:Hide() end
  r.label:SetPoint("LEFT", x, 0)
  r.label:SetText(label or "")
  self:Paint(r.label, nil, "label")
  local lw = math.min(math.ceil(r.label:GetStringWidth()) + 2, math.floor(self:Width() * 0.55))
  r.label:SetWidth(lw)
  r.value:SetPoint("RIGHT", -6, 0)
  r.value:SetJustifyH("RIGHT")
  r.value:SetText(value or "")
  self:Paint(r.value, color)
  local h = FitValue(r.value, self:Width() - x - lw - 6 - 6)
  return self:Place(r, h)
end


-- One row per layer: label (gold, 64 px), icon, name in its state colour.
function Pane:Layers(list)
  for _, l in ipairs(list or {}) do
    local r = RowFrame(self)
    Zebra(self, r)
    r.label:ClearAllPoints(); r.value:ClearAllPoints(); r.icon:ClearAllPoints()
    r.label:SetPoint("LEFT", 6, 0)
    r.label:SetWidth(64)
    r.label:SetText(l.label or l[1] or "")
    self:Paint(r.label, nil, "label")
    r.icon:SetPoint("LEFT", 74, 0)
    local icon = l.icon or l[2]
    r.icon:SetTexture(icon or UI.QUESTION)
    r.icon:SetDesaturated(icon == nil)
    r.icon:Show()
    r.value:SetPoint("LEFT", 98, 0)
    r.value:SetJustifyH("LEFT")
    r.value:SetText(l.name or l[3] or "Empty")
    self:Paint(r.value, l.color or l[4])
    self:Place(r, FitValue(r.value, self:Width() - 98 - 6))
  end
  -- Row frames are shared with Pane:Row, which right-justifies; restored there.
end

function Pane:Diff(now, after)
  local f = Acquire(self, "diff", function()
    local d = CreateFrame("Frame", nil, self.child)
    d.a = UI.Slot(d, 32); d.a:SetPoint("TOPLEFT", 0, -2); d.a:EnableMouse(false); d.a.acSkip = true
    d.b = UI.Slot(d, 32); d.b:SetPoint("TOPLEFT", 0, -38); d.b:EnableMouse(false); d.b.acSkip = true
    d.an = UI.Text(d, "", "GameFontHighlight"); d.an:SetPoint("LEFT", d.a, "RIGHT", 8, 0); d.an:SetJustifyH("LEFT"); d.an:SetWordWrap(false)
    d.bn = UI.Text(d, "", "GameFontHighlight"); d.bn:SetPoint("LEFT", d.b, "RIGHT", 8, 0); d.bn:SetJustifyH("LEFT"); d.bn:SetWordWrap(false)
    d.arrow = d:CreateTexture(nil, "ARTWORK")
    d.arrow:SetSize(16, 16)
    d.arrow:SetPoint("TOP", d.a, "BOTTOM", 0, 1)
    d.arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    d.arrow:SetRotation(-math.pi / 2)
    d.nowL = UI.Text(d, "Now", "GameFontNormal"); d.nowL:SetPoint("TOPRIGHT", 0, -10)
    d.afterL = UI.Text(d, "After", "GameFontNormal"); d.afterL:SetPoint("TOPRIGHT", 0, -46)
    return d
  end)
  local w = self:Width()
  for _, p in ipairs({ { f.a, f.an, now }, { f.b, f.bn, after } }) do
    local slot, fs, v = p[1], p[2], p[3] or {}
    slot:SetIcon(v.icon or v[1])
    fs:SetText(v.name or v[2] or "Empty")
    -- Two lines before "...": long item names ("Raw Bristle Whisker Catfish")
    -- were cut at one line in the capture.
    fs:SetWidth(w - 40 - 44)
    fs:SetWordWrap(true)
    if fs.SetMaxLines then fs:SetMaxLines(2) end
    local c = v.color or v[3]
    self:Paint(fs, c)
    slot:SetMark(c or nil)
  end
  return self:Place(f, 72)
end

function Pane:Text(text, color)
  if not text or text == "" then return end
  local f = Acquire(self, "text", function()
    local t = CreateFrame("Frame", nil, self.child)
    t.fs = NewText(t, "GameFontHighlight")
    t.fs:SetPoint("TOPLEFT", 6, 0) -- in line with row labels and links
    return t
  end)
  f.fs:SetWidth(self:Width() - 12)
  f.fs:SetFontObject("GameFontHighlight")
  f.fs:SetText(text)
  self:Paint(f.fs, color)
  return self:Place(f, math.ceil(f.fs:GetStringHeight() or 12))
end

function Pane:Empty(text)
  local f = self:Text(text)
  if f then f.fs:SetFontObject("GameFontDisable"); self:Paint(f.fs, nil, "dim") end
  return f
end

-- "Also on: ..." lines; each is a focusable button that runs its fn (jump there).
function Pane:CrossRef(list)
  for _, e in ipairs(list or {}) do
    local b = Acquire(self, "xref", function()
      local x = CreateFrame("Button", nil, self.child)
      local hl = x:CreateTexture(nil, "HIGHLIGHT")
      hl:SetAllPoints()
      UI.SetAtlas(hl, UI.ART.rowHover)
      x.fs = UI.Text(x, "", "GameFontHighlight")
      x.fs:SetPoint("LEFT", 6, 0)
      x.fs:SetJustifyH("LEFT")
      x.fs:SetWordWrap(true)
      if x.fs.SetMaxLines then x.fs:SetMaxLines(2) end
      x:SetScript("OnClick", function(btn) if btn.fn then btn.fn() end end)
      UI.Node(x, { style = "row" })
      return x
    end)
    b.fs:SetText(e.text or e[1] or "")
    self:Paint(b.fs, e.color or e[3])
    b.fn = e.fn or e[2]
    b.acId = "xref:" .. tostring(e.text or e[1])
    b:SetEnabled(b.fn ~= nil)
    b.acReadable = true
    -- A long link wraps to a second line instead of being cut off. The
    -- width is set first and the unbounded width decides (GetStringWidth of
    -- a wrapped string is never wider than its box, so long links got a
    -- one-line 28 px row and lost their second line in the capture).
    local room = self:Width() - 12
    b.fs:SetWidth(room)
    local full = (b.fs.GetUnboundedStringWidth and b.fs:GetUnboundedStringWidth()) or b.fs:GetStringWidth() or 0
    self:Place(b, full > room and 42 or 28)
  end
end

function Pane:Code(text)
  local f = Acquire(self, "code", function()
    local c = CreateFrame("Frame", nil, self.child)
    c.well = UI.Inset(c)
    c.well:SetAllPoints()
    c.box = UI.LogBox(c, "ChatFontNormal")
    return c
  end)
  f.box:SetTextIfChanged(text or "")
  return self:Place(f, 7 * 14 + 14)
end

-- Bottom-docked buttons (cleared with the pane).
function Pane:Buttons(list)
  local dock = self.dock
  for _, b in ipairs(dock.buttons) do b:Hide() end
  local x, y, w = 0, 0, self.host:GetWidth() - 16
  local n = 0
  for _, e in ipairs(list or {}) do
    n = n + 1
    local b = dock.buttons[n]
    if not b then
      b = UI.Button(dock, "", nil, function(btn)
        local en = btn.entry
        if not en or not en.fn then return end
        if en.confirm then UI.Confirm(type(en.confirm) == "function" and en.confirm() or en.confirm, en.fn) else en.fn() end
      end, nil, 28)
      dock.buttons[n] = b
      if UI.PixelSnap then UI.PixelSnap(b) end
    end
    b.entry = e
    b:SetText(e.label or e[1] or "")
    UI.FitButton(b, 80)
    if x > 0 and x + b:GetWidth() > w then x = 0; y = y + 32 end
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", dock, "TOPLEFT", x, -y)
    b:SetEnabled(e.enabled ~= false and (type(e.enabled) ~= "function" or e.enabled() ~= false))
    b:Show()
    x = x + b:GetWidth() + 6
  end
  self:LayoutDock(n > 0 and (y + 32) or 0)
end

function Pane:LayoutDock(h)
  self.dockHeight = h or 0
  self.dock:SetHeight(math.max(self.dockHeight, 0.001))
  self.dock:SetShown(self.dockHeight > 0)
  local actionsH = self.actionsHeight or 0
  self.dock:ClearAllPoints()
  self.dock:SetPoint("BOTTOMLEFT", self.host, "BOTTOMLEFT", 8, 8 + actionsH)
  self.dock:SetPoint("BOTTOMRIGHT", self.host, "BOTTOMRIGHT", -8, 8 + actionsH)
  self.child:SetWidth(self:Width())
  self.scroll:ClearAllPoints()
  self.scroll:SetPoint("TOPLEFT", self.host, "TOPLEFT", 8, -8)
  self.scroll:SetPoint("BOTTOMRIGHT", self.host, "BOTTOMRIGHT", -8 - 18, 8 + actionsH + self.dockHeight + (self.dockHeight > 0 and 6 or 0))
  if self.UpdateFades then self:UpdateFades() end
end

-- The Controller BarCard: the 8 buttons of one bar, glyph + icon + name.
function Pane:BarCard(bar)
  if bar.title then self:Section(bar.title) end
  for _, r in ipairs(bar.rows or {}) do
    local b = Acquire(self, "barrow", function()
      local x = CreateFrame("Button", nil, self.child)
      x.bg = x:CreateTexture(nil, "BACKGROUND")
      x.bg:SetAllPoints()
      local hl = x:CreateTexture(nil, "HIGHLIGHT")
      hl:SetAllPoints()
      UI.SetAtlas(hl, UI.ART.rowHover)
      x.glyph = UI.Glyph(x, nil, 28, "pad")
      x.glyph:SetPoint("LEFT", 2, 0)
      x.icon = x:CreateTexture(nil, "ARTWORK")
      x.icon:SetSize(26, 26)
      x.icon:SetPoint("LEFT", 34, 0)
      x.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      -- Empty buttons: the slot's engraved empty art on its own texture, so
      -- the icon texture never mixes an atlas with SetTexCoord.
      x.empty = x:CreateTexture(nil, "ARTWORK")
      x.empty:SetSize(26, 26)
      x.empty:SetPoint("CENTER", x.icon, "CENTER")
      x.empty:SetAlpha(0.8)
      x.empty:Hide()
      -- D-pad rows name the direction too: the cross glyphs differ only by
      -- which arm is lit, which is hard to see at this size.
      x.dir = UI.Text(x, "", "GameFontNormalSmall")
      x.dir:SetPoint("RIGHT", -18, 0)
      x.dir:SetJustifyH("RIGHT")
      x.name = UI.Text(x, "", "GameFontHighlight")
      x.name:SetPoint("LEFT", x.icon, "RIGHT", 6, 0)
      x.name:SetPoint("RIGHT", -18, 0)
      x.name:SetJustifyH("LEFT")
      -- Two lines in the 32 px row ("Gnomish Rocket Boots (or better)"), then "...".
      x.name:SetWordWrap(true)
      if x.name.SetMaxLines then x.name:SetMaxLines(2) end
      x.dot = x:CreateTexture(nil, "OVERLAY")
      x.dot:SetSize(10, 10)
      x.dot:SetPoint("RIGHT", -4, 0)
      x.dot:SetTexture(UI.WHITE)
      x:SetScript("OnClick", function(btn)
        if btn.node and ns.Focus then ns.Focus:Set(btn.node, "key") end
      end)
      UI.Node(x, { style = "row" })
      x.acReadable = true
      return x
    end)
    Zebra(self, b)
    if r.focused and UI.SetAtlas(b.bg, UI.ART.rowActive) then
      -- The settings list's selected-row art is made to stretch across a row.
      b.bg:ClearAllPoints()
      b.bg:SetAllPoints()
      b.bg:SetAlpha(1)
      b.bg:Show()
    end
    b.glyph:SetKey(r.key)
    -- Empty buttons show the slot's engraved empty art (as on the HUD); the
    -- question mark is kept for spells that are missing or still waiting.
    local empty = r.icon == nil and (r.empty == true or r.name == nil or r.name == "Empty")
    local emptyArt = empty and UI.PAD_EMPTY and UI.PAD_EMPTY[r.key]
    if emptyArt and UI.SetAtlas(b.empty, emptyArt) then
      b.empty:Show()
      b.icon:Hide()
    else
      b.empty:Hide()
      b.icon:SetTexture(r.icon or UI.QUESTION)
      b.icon:SetDesaturated(r.icon == nil or r.faded == true)
      b.icon:Show()
    end
    b.name:SetText(r.name or "Empty")
    local c = r.color
    if c then b.name:SetTextColor(UI.RowRGB(c))
    elseif empty then b.name:SetTextColor(0.8, 0.8, 0.8)
    else b.name:SetTextColor(1, 1, 1) end
    if c then b.dot:SetVertexColor(UI.RGB(c)); b.dot:Show() else b.dot:Hide() end
    local dir = r.key and r.key:find("^PADD") and UI.PAD_NAMES[r.key] or ""
    b.dir:SetText(dir)
    b.name:SetPoint("RIGHT", b, "RIGHT", dir ~= "" and -(22 + math.ceil(b.dir:GetStringWidth() or 0)) or -18, 0)
    b.node = r.node
    -- Sideways out of the card goes back to that button on the HUD, never
    -- down to the prompt bar; Right is the window edge.
    b.navLeft = r.node or nil
    b.navRight = false
    b.acId = "barcard:" .. tostring(r.key)
    self:Place(b, 32)
  end
end

-- A persistent action dock under everything (v1 footer actions live here).
-- Returns the holder frame; the window fills it.
function Pane:ActionsDock()
  return self.actions
end
function Pane:SetActionsHeight(h)
  self.actionsHeight = h or 0
  self.actions:SetHeight(math.max(self.actionsHeight, 0.001))
  self.actions:SetShown(self.actionsHeight > 0)
  self:LayoutDock(self.dockHeight or 0)
end

function UI.NewInspector(host)
  local pane = { host = host, pools = {}, y = 4, zebra = 0 }
  for k, v in pairs(Pane) do pane[k] = v end
  local scroll, child = UI.Scroll(host)
  pane.scroll, pane.child = scroll, child
  UI.Name(scroll, "acScroll"); UI.Name(child, "acContent")
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local range = self.GetVerticalScrollRange and self:GetVerticalScrollRange() or 0
    self:SetVerticalScroll(math.max(0, math.min(range, (self:GetVerticalScroll() or 0) - delta * 24)))
  end)
  -- Fades at the top and bottom edge (as Blizzard's ScrollBox shadows), so a
  -- line cut by the edge reads as "more below", not as a glitch.
  -- They sit on an overlay frame above the scroll child: textures on host
  -- itself would draw under the content and fade nothing.
  pane.fades, pane.fadeTop, pane.fadeBottom = UI.EdgeFades(host, scroll, 0.75, 0.85, 14, 18)
  function pane.UpdateFades(self)
    local cur = self.scroll:GetVerticalScroll() or 0
    local range = self.scroll.GetVerticalScrollRange and self.scroll:GetVerticalScrollRange() or 0
    self.fadeTop:SetShown(cur > 0.5)
    self.fadeBottom:SetShown(range - cur > 0.5)
  end
  -- Focus inside the Inspector never stays off-screen (spec §4.5): after a
  -- wheel tick or a right-stick scroll, move it to the first visible node.
  function pane.KeepFocusVisible(self)
    local F = ns.Focus
    local cur = F and F.current
    if not cur or F.setting or self.fixing or not (F.Clipped and F.Clipped(cur, self.scroll)) then return end
    local o = cur
    while o and o ~= self.child do o = o.GetParent and o:GetParent() end
    if not o then return end
    self.fixing = true
    for _, n in ipairs(F:Nodes()) do
      local p = n
      while p and p ~= self.child do p = p.GetParent and p:GetParent() end
      if p and not F.Clipped(n, self.scroll) then F:Set(n, F.source == "mouse" and "mouse" or "key", true, true) break end
    end
    self.fixing = nil
  end
  if scroll.HookScript then
    scroll:HookScript("OnVerticalScroll", function() pane:UpdateFades(); pane:KeepFocusVisible() end)
    scroll:HookScript("OnScrollRangeChanged", function() pane:UpdateFades() end)
  end
  pane.dock = UI.Name(CreateFrame("Frame", nil, host), "acDock")
  pane.dock.buttons = {}
  pane.actions = UI.Name(CreateFrame("Frame", nil, host), "acActions")
  pane.actions:SetPoint("BOTTOMLEFT", 8, 8)
  pane.actions:SetPoint("BOTTOMRIGHT", -8, 8)
  pane.actions:SetHeight(0.001)
  pane.actionsHeight = 0
  pane:LayoutDock(0)
  return pane
end
