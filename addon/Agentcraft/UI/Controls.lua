-- v2 controls (dev/ui-spec-v2.md §10.2): plates, cards, chips, toggles,
-- meters, keycaps, glyphs, prompts, scroll lists, models, sockets, section
-- titles and zebra rows. Each prefers Blizzard's own art (UI.ART lists the
-- Forever name first, a retail name second) and falls back to our flat art.
local _, ns = ...
local UI = ns.UI

-- Plate ----------------------------------------------------------------------------------
-- Dark panel: a near-black warm fill inside the window's own inner border
-- (NineSlice "InsetFrameTemplate": UI-Frame-Inner* atlases, the same edge
-- InsetFrameTemplate draws), else a bronze (#E69E52) rule top and bottom.
-- The fill is nearly opaque, so a toast or banner never shows the page
-- through it. opts.opaque: fully opaque (sheets).
function UI.Plate(parent, opts)
  local f = CreateFrame("Frame", nil, parent)
  local opaque = opts and opts.opaque
  f.bg = UI.Flat(f, "BACKGROUND", 0.045, 0.04, 0.035, opaque and 1 or 0.94)
  f.bg:SetDrawLayer("BACKGROUND", -7)
  f.bg:SetPoint("TOPLEFT", 2, -2)
  f.bg:SetPoint("BOTTOMRIGHT", -2, 2)
  f.solid = opaque and f.bg or nil
  if type(NineSliceUtil) == "table" and NineSliceUtil.ApplyLayoutByName then
    local ok = pcall(NineSliceUtil.ApplyLayoutByName, f, "InsetFrameTemplate")
    if ok then f.nineSlice = true return f end
  end
  f.bg:SetAllPoints()
  f.top = UI.Flat(f, "BORDER", 0.9, 0.62, 0.32, 0.9)
  f.top:SetPoint("TOPLEFT"); f.top:SetPoint("TOPRIGHT"); f.top:SetHeight(1)
  f.bottom = UI.Flat(f, "BORDER", 0.9, 0.62, 0.32, 0.9)
  f.bottom:SetPoint("BOTTOMLEFT"); f.bottom:SetPoint("BOTTOMRIGHT"); f.bottom:SetHeight(1)
  return f
end

-- Keycap ----------------------------------------------------------------------------------
-- A key label on a keycap plate ("Ctrl+Enter", "L4"): text + 12 px wide, h tall.
function UI.Keycap(parent, text, h)
  local f = CreateFrame("Frame", nil, parent)
  h = h or 22
  -- A key you can see on a dark panel: a lifted fill, a bronze-grey rim and a
  -- darker bottom lip (our own flat art). No stock texture is stretched
  -- across it: square action-button art smears at keycap widths.
  f.fill = UI.Flat(f, "BACKGROUND", 0.2, 0.18, 0.15, 0.95)
  f.fill:SetAllPoints()
  local rim = { 0.62, 0.52, 0.38, 0.9 }
  local function Edge(p1, p2, horiz)
    local t = UI.Flat(f, "BORDER", rim[1], rim[2], rim[3], rim[4])
    t:SetPoint(p1); t:SetPoint(p2)
    if horiz then t:SetHeight(1) else t:SetWidth(1) end
    return t
  end
  f.rimTop = Edge("TOPLEFT", "TOPRIGHT", true)
  f.rimLeft = Edge("TOPLEFT", "BOTTOMLEFT")
  f.rimRight = Edge("TOPRIGHT", "BOTTOMRIGHT")
  f.lip = UI.Flat(f, "BORDER", 0.05, 0.04, 0.03, 0.95)
  f.lip:SetPoint("BOTTOMLEFT", 1, 0); f.lip:SetPoint("BOTTOMRIGHT", -1, 0)
  f.lip:SetHeight(3)
  f.text = UI.Text(f, text or "", h >= 30 and "NumberFontNormalLarge" or "NumberFontNormal")
  f.text:SetPoint("CENTER", 0, 1)
  function f.SetText(self, t)
    self.text:SetText(t or "")
    self:SetSize(math.max(h, math.ceil(self.text:GetStringWidth()) + 12), h)
  end
  f:SetText(text)
  return f
end

-- Glyph -----------------------------------------------------------------------------------
-- A controller button glyph (PAD1 ... PADDRIGHT), or a keycap when there is
-- no atlas. mode: "pad" (always the controller glyph: HUD slots, BarCard),
-- "prompt" (glyph in pad prompt mode, keyboard keycap otherwise; hidden in
-- mouse mode). Text keys ("L4") always draw as keycaps. glyph:SetKey(key).
-- The client's xbox1 "-flat-normal" glyphs sit in a 76x75 cell whose art
-- covers only its middle ~44 px (the rest is transparent), so they are drawn
-- this much larger than the frame, on a child frame the glyph clips, for the
-- art to fill it. Other glyph sets (Forever's "-normal", PlayStation "32x")
-- fill their cells.
local GLYPH_OVERSCAN = 1.6
local function Overscan(atlas)
  return type(atlas) == "string" and atlas:find("^gamepad%-xbox1%-.*%-flat%-normal$") and GLYPH_OVERSCAN or 1
end
UI.GlyphOverscan = Overscan

function UI.Glyph(parent, key, size, mode)
  local g = CreateFrame("Frame", nil, parent)
  size = size or 22
  g:SetSize(size, size)
  g.size, g.mode = size, mode or "pad"
  if g.SetClipsChildren then g:SetClipsChildren(true) end
  g.art = CreateFrame("Frame", nil, g)
  g.art:SetPoint("CENTER")
  g.art:SetSize(size, size)
  g.tex = g.art:CreateTexture(nil, "OVERLAY", nil, 5)
  g.tex:SetAllPoints()
  -- Fit sizes the frame and scales the art with it; a caller's SetSize
  -- also becomes the glyph's size, so later SetKey calls keep it.
  local SetSize = g.SetSize
  function g.Fit(self, w, h)
    SetSize(self, w, h)
    local s = math.min(w, h) * (self.scan or 1)
    if s > 0 then self.art:SetSize(s, s) end
  end
  function g.SetSize(self, w, h)
    h = h or w
    self.size = math.min(w, h)
    self:Fit(w, h)
  end
  g.cap = UI.Keycap(g, "", size)
  g.cap:SetPoint("LEFT")
  g.cap:Hide()
  function g.Refresh(self)
    local k = self.key
    local pm = UI.PromptMode()
    local atlas = k and UI.GlyphAtlas(k)
    if self.mode == "prompt" and pm == "mouse" then
      self.art:Hide(); self.cap:Hide(); self:SetWidth(0.001); self.width = 0
      return
    end
    if atlas and (self.mode == "pad" or pm == "pad") then
      self.tex:SetAtlas(atlas)
      self.scan = Overscan(atlas)
      self.art:Show(); self.cap:Hide()
      self:Fit(self.size, self.size)
    else
      local text = (self.mode == "prompt" and UI.KEY_TEXT[k]) or UI.PAD_NAMES[k] or tostring(k or "")
      self.cap:SetText(text)
      self.art:Hide(); self.cap:Show()
      self:Fit(self.cap:GetWidth(), self.size)
    end
    self.width = self:GetWidth()
  end
  function g.SetKey(self, k) self.key = k; self:Refresh() end
  UI.glyphs[g] = true
  g:SetKey(key)
  return g
end

-- Prompt -----------------------------------------------------------------------------------
-- A prompt-bar button: glyph (or keycap) + label, 28 tall, clickable. With
-- opts.primary it is a gold panel button with the glyph inline at its left.
-- prompt:SetLabel(text), prompt:SetKey(key), prompt:SetGlow(on), prompt.width.
function UI.Prompt(parent, key, label, fn, opts)
  opts = opts or {}
  local b
  if opts.primary then
    b = CreateFrame("Button", nil, parent, UI.Has("UIPanelGoldButtonTemplate") and "UIPanelGoldButtonTemplate" or "UIPanelButtonTemplate")
    b:SetHeight(28)
  else
    b = CreateFrame("Button", nil, parent)
    b:SetHeight(28)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    if not UI.SetAtlas(hl, UI.ART.rowHover) then hl:SetTexture(UI.WHITE); hl:SetVertexColor(1, 1, 1, 0.08) end
    hl:SetBlendMode("ADD")
  end
  b.primary = opts.primary
  b.glyph = UI.Glyph(b, key, 22, "prompt")
  b.glyph:SetPoint("LEFT", opts.primary and 10 or 4, 0)
  b.label = UI.Text(b, label or "", opts.primary and "GameFontHighlight" or "GameFontNormal")
  b.label:SetPoint("LEFT", b.glyph, "RIGHT", 4, 0)
  b.label:SetWordWrap(false)
  b:SetScript("OnClick", function(self)
    if self.disabledReason then return end
    if fn then fn(self) end
  end)
  function b.Relayout(self)
    local gw = self.glyph.width or 0
    local pad = self.primary and 10 or 4
    local w = pad + gw + (gw > 0 and 4 or 0) + math.ceil(self.label:GetStringWidth()) + pad + (self.primary and 6 or 2)
    self.label:ClearAllPoints()
    if gw > 0 then self.label:SetPoint("LEFT", self.glyph, "RIGHT", 4, 0)
    else self.label:SetPoint("LEFT", self, "LEFT", pad + (self.primary and 6 or 0), 0) end
    self:SetWidth(math.max(w, self.primary and 120 or 40))
    self.width = self:GetWidth()
  end
  function b.SetLabel(self, t) self.label:SetText(t or ""); self:Relayout() end
  function b.SetKey(self, k) self.glyph:SetKey(k); self:Relayout() end
  function b.SetGlow(self, on)
    if not self.primary then return end
    if on == self.glowing then return end
    self.glowing = on
    if type(GlowEmitterFactory) == "table" and GlowEmitterFactory.Show and GlowEmitterMixin and GlowEmitterMixin.Anims then
      if on then pcall(GlowEmitterFactory.Show, GlowEmitterFactory, self, GlowEmitterMixin.Anims.FaintFadeAnim)
      else pcall(GlowEmitterFactory.Hide, GlowEmitterFactory, self) end
      return
    end
    if not self.glowTex then
      local l = self:CreateTexture(nil, "BACKGROUND", nil, -1)
      local m = self:CreateTexture(nil, "BACKGROUND", nil, -1)
      local r = self:CreateTexture(nil, "BACKGROUND", nil, -1)
      if UI.SetAtlas(l, UI.ART.glowLeft) and UI.SetAtlas(m, UI.ART.glowMiddle) and UI.SetAtlas(r, UI.ART.glowRight) then
        l:SetSize(16, 40); l:SetPoint("RIGHT", self, "LEFT", 6, 0)
        r:SetSize(16, 40); r:SetPoint("LEFT", self, "RIGHT", -6, 0)
        m:SetPoint("TOPLEFT", l, "TOPRIGHT"); m:SetPoint("BOTTOMRIGHT", r, "BOTTOMLEFT")
        for _, t in ipairs({ l, m, r }) do t:SetBlendMode("ADD") end
        self.glowTex = { l, m, r }
      else
        self.glowTex = {}
      end
    end
    -- The tab glow's slow pulse (0.9 s, TabGlowAnimation in
    -- SharedUIPanelTemplates.xml), stopped while hidden.
    self.glowAnims = self.glowAnims or {}
    for i, t in ipairs(self.glowTex) do
      t:SetShown(on and true or false)
      if on then self.glowAnims[i] = UI.Anim.Pulse(t, 0.35, 1, 0.9)
      elseif self.glowAnims[i] then self.glowAnims[i]:Stop(); self.glowAnims[i] = nil end
    end
  end
  UI.Node(b, { style = "button" })
  b:Relayout()
  return b
end

-- Chips (view strip) -------------------------------------------------------------------------
-- labels: strings or { text=, key= }. onSelect(i, strip, label). strip:Select(i [, silent]),
-- strip:Cycle(delta), strip.buttons, strip.selected. Height 28.
function UI.Chips(parent, labels, onSelect, opts)
  opts = opts or {}
  local strip = CreateFrame("Frame", nil, parent)
  strip:SetHeight(28)
  strip.buttons = {}
  local x = 0
  for i, l in ipairs(labels) do
    local text = type(l) == "table" and l.text or l
    local b = CreateFrame("Button", nil, strip)
    b:SetHeight(28)
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.useAtlas = UI.SetAtlas(b.bg, UI.ART.rowActive) ~= nil
    if not b.useAtlas then b.bg:SetTexture(UI.WHITE); b.bg:SetVertexColor(1, 0.82, 0, 0.14) end
    b.bg:Hide()
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    if not UI.SetAtlas(hl, UI.ART.rowHover) then hl:SetTexture(UI.WHITE); hl:SetVertexColor(1, 1, 1, 0.08) end
    b.text = UI.Text(b, text, "GameFontNormal")
    b.text:SetPoint("CENTER")
    b:SetWidth(math.max(opts.minWidth or 56, math.ceil(b.text:GetStringWidth()) + 24))
    b:SetPoint("LEFT", strip, "LEFT", x, 0)
    x = x + b:GetWidth() + (opts.gap or 4)
    b:SetScript("OnClick", function() UI.Sound("view"); strip:Select(i) end)
    UI.Node(b, { style = "chip", id = (opts.idPrefix or "chip:") .. (type(l) == "table" and l.key or text) })
    b.acInspect = opts.inspect and function(self, pane) opts.inspect(i, pane, self) end or nil
    strip.buttons[i] = b
  end
  strip:SetWidth(math.max(x - (opts.gap or 4), 1))
  function strip.Select(self, i, silent)
    if not self.buttons[i] then return end
    self.selected = i
    for j, b in ipairs(self.buttons) do
      local on = j == i
      b.bg:SetShown(on)
      b.text:SetFontObject(on and "GameFontHighlight" or "GameFontNormal")
    end
    if onSelect and not silent then onSelect(i, self, labels[i]) end
  end
  function strip.Cycle(self, delta)
    local n = #self.buttons
    if n == 0 then return end
    self:Select(((self.selected or 1) - 1 + (delta or 1)) % n + 1)
  end
  strip:Select(opts.selected or 1, true)
  return strip
end

-- Two-segment toggle ("Now | After", "Picture | List"). onChange(i, toggle).
-- toggle:Set(i [, silent]), toggle:Get().
function UI.Toggle2(parent, a, b, onChange)
  local t = UI.Chips(parent, { a, b }, function(i, strip) if onChange then onChange(i, strip) end end, { gap = 0, minWidth = 48 })
  function t.Set(self, i, silent) self:Select(i, silent) end
  function t.Get(self) return self.selected end
  -- One node toggles: A flips it; both halves stay clickable.
  for _, btn in ipairs(t.buttons) do btn.acActivate = function() UI.Sound("view"); t:Cycle(1) end end
  return t
end

-- Meter -------------------------------------------------------------------------------------
-- Readiness bar w x 12: meter:SetValue(done, total [, pending]),
-- meter:AnimateTo(done, total), meter:SetLabel(text) (label above, right).
function UI.Meter(parent, w, h)
  local m = CreateFrame("Frame", nil, parent)
  w, h = w or 200, h or 12
  m:SetSize(w, h)
  m.bg = UI.Flat(m, "BACKGROUND", 0.02, 0.02, 0.02, 0.85)
  m.bg:SetAllPoints()
  m.fill = m:CreateTexture(nil, "ARTWORK")
  m.fill:SetPoint("TOPLEFT", 1, -1)
  m.fill:SetPoint("BOTTOMLEFT", 1, 1)
  m.fill:SetWidth(1)
  m.rules = { UI.Flat(m, "BORDER", 0.9, 0.62, 0.32, 0.7), UI.Flat(m, "BORDER", 0.9, 0.62, 0.32, 0.7) }
  m.rules[1]:SetPoint("TOPLEFT"); m.rules[1]:SetPoint("TOPRIGHT"); m.rules[1]:SetHeight(1)
  m.rules[2]:SetPoint("BOTTOMLEFT"); m.rules[2]:SetPoint("BOTTOMRIGHT"); m.rules[2]:SetHeight(1)
  m.label = UI.Text(m, "", "GameFontHighlightSmall")
  m.label:SetPoint("BOTTOMRIGHT", m, "TOPRIGHT", 0, 2)
  m.label:SetJustifyH("RIGHT")
  m.label._acCaption = true
  m.frac = 0
  -- The fill art changes only when the pending state does, and its shown
  -- state only when it crosses zero: AnimateTo repaints every frame and may
  -- only change the width (ui-rules 11).
  local function Paint(self, frac, pending)
    frac = math.max(0, math.min(1, frac or 0))
    self.frac = frac
    pending = pending and true or false
    if self.fillPending ~= pending then
      self.fillPending = pending
      local list = pending and UI.ART.meterWhite or UI.ART.meterGreen
      if not UI.SetAtlas(self.fill, list) then
        self.fill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        if pending then self.fill:SetVertexColor(1, 0.82, 0.2) else self.fill:SetVertexColor(0.15, 0.85, 0.2) end
      end
    end
    self.fill:SetWidth(math.max(1, (w - 2) * frac))
    local shown = frac > 0
    if self.fillShown ~= shown then self.fillShown = shown; self.fill:SetShown(shown) end
  end
  function m.SetValue(self, done, total, pending)
    self.done, self.total, self.pending = done, total, pending
    Paint(self, (total and total > 0) and (done / total) or 0, pending)
  end
  function m.AnimateTo(self, done, total)
    local to = (total and total > 0) and (done / total) or 0
    if UI.Reduced() or not self.SetScript then return self:SetValue(done, total) end
    local from, t0 = self.frac or 0, 0
    self.done, self.total = done, total
    self:SetScript("OnUpdate", function(s, elapsed)
      t0 = t0 + (elapsed or 0.4)
      local k = math.min(1, t0 / 0.4)
      Paint(s, from + (to - from) * k, false)
      if k >= 1 then s:SetScript("OnUpdate", nil) end
    end)
  end
  function m.SetLabel(self, t) self.label:SetText(t or "") end
  return m
end

-- Card --------------------------------------------------------------------------------------
-- An OutfitCard-style button w x h: card.icon (44 in an icon frame), card.title
-- (GameFontNormalMed3), card.line (GameFontHighlight), card.meter (160x10),
-- card.tick. card:SetSelected(b).
function UI.Card(parent, w, h)
  local c = CreateFrame("Button", nil, parent)
  c:SetSize(w or 420, h or 76)
  -- An opaque dark plate under the translucent card art, so the gold title,
  -- white line and state colours stay readable on light parchment.
  c.plate = c:CreateTexture(nil, "BACKGROUND", nil, -2)
  c.plate:SetPoint("TOPLEFT", 3, -3)
  c.plate:SetPoint("BOTTOMRIGHT", -3, 3)
  c.plate:SetTexture(UI.WHITE)
  c.plate:SetVertexColor(0.06, 0.045, 0.03, 0.92)
  c.bg = c:CreateTexture(nil, "BACKGROUND")
  c.bg:SetAllPoints()
  if not UI.SetAtlas(c.bg, UI.ART.card) then
    c.panel = UI.Panel(c)
    c.panel:SetAllPoints()
    c.panel:SetFrameLevel(math.max(c:GetFrameLevel() - 1, 0))
    c.bg:Hide()
  end
  local hl = c:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  UI.SetAtlas(hl, UI.ART.cardHover)
  c.sel = c:CreateTexture(nil, "ARTWORK", nil, -1)
  c.sel:SetAllPoints()
  UI.SetAtlas(c.sel, UI.ART.cardSelected)
  c.sel:Hide()
  -- Icon in its frame, centred 38 px from the left edge. Forever's
  -- OutfitIcon-Frame is drawn at its atlas size around a 36 px icon, as the
  -- equipment manager draws it (PaperDollFrame.xml); a bigger icon pokes out
  -- past the frame's visible ring. The retail action-button frame wraps a
  -- 44 px icon at 52.
  c.iconFrame = c:CreateTexture(nil, "ARTWORK", nil, 2)
  c.iconFrame:SetPoint("CENTER", c, "LEFT", 38, 0)
  c.icon = c:CreateTexture(nil, "ARTWORK")
  if UI.SetAtlas(c.iconFrame, { "UI-Character-Info-OutfitIcon-Frame" }, true) then
    c.icon:SetSize(36, 36)
  else
    c.iconFrame:SetSize(52, 52)
    UI.SetAtlas(c.iconFrame, { "UI-HUD-ActionBar-IconFrame" })
    c.icon:SetSize(44, 44)
  end
  c.icon:SetPoint("CENTER", c.iconFrame, "CENTER")
  c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  c.title = UI.Text(c, "", "GameFontNormalMed3")
  -- Text starts 76 px in whatever size the frame art has.
  c.title:SetPoint("TOPLEFT", c, "TOPLEFT", 76, -(math.floor(((h or 76) - 52) / 2) + 4))
  c.title:SetJustifyH("LEFT")
  c.title:SetWordWrap(false)
  c.line = UI.Text(c, "", "GameFontHighlight")
  c.line:SetPoint("TOPLEFT", c.title, "BOTTOMLEFT", 0, -8)
  c.line:SetWidth(math.max((w or 420) - 100, 40))
  c.line:SetJustifyH("LEFT")
  c.line:SetWordWrap(false)
  c.meter = UI.Meter(c, 160, 10)
  c.meter:SetPoint("TOPRIGHT", c, "TOPRIGHT", -40, -14)
  c.meter:Hide()
  c.tick = c:CreateTexture(nil, "OVERLAY")
  c.tick:SetSize(24, 24)
  c.tick:SetPoint("TOPRIGHT", -10, -8)
  if not UI.SetAtlas(c.tick, UI.ART.tick) then c.tick:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready") end
  c.tick:Hide()
  function c.SetSelected(self, on) self.sel:SetShown(on and true or false) end
  UI.Node(c, { style = "card" })
  return c
end

-- Scroll list --------------------------------------------------------------------------------
-- A vertical list of rows that fills parent. makeRow(child, i) returns a row
-- frame (made a focus node with style "row" unless it already is one);
-- fillRow(row, data, i) fills it. list:SetData(t), list:Nodes() (shown rows),
-- list:ScrollToNode(node), list:VisibleRows(), list.scroll (the ScrollFrame,
-- for the right stick). One wheel tick = one row. Rows are created as needed
-- and reused (not virtualised: lists here hold at most a few hundred rows).
-- Fade masks at the top and bottom show that more content exists.
function UI.ScrollList(parent, rowHeight, makeRow, fillRow)
  local list = { rowHeight = rowHeight, rows = {}, data = {} }
  local scroll, child = UI.Scroll(parent)
  list.scroll, list.child = scroll, child
  scroll.acList = list
  -- The range from the rows we laid out, not GetVerticalScrollRange: the
  -- client updates that one a frame after the child's height changes, so a
  -- fresh SetData would hide the bottom fade and the bar, then show them
  -- again on the next frame (a flash).
  local function Range()
    return math.max(0, (child:GetHeight() or 0) - (scroll:GetHeight() or 0))
  end
  list.Range = Range
  -- Blizzard's scroll bar hides itself when there is nothing to scroll
  -- (ScrollBar:SetHideIfUnscrollable, kept in step by ScrollUtil); without
  -- it the bar is shown and hidden here, and only when that changes.
  local bar = scroll.ScrollBar
  local barSelf = type(bar) == "table" and type(bar.SetHideIfUnscrollable) == "function"
  if barSelf then pcall(bar.SetHideIfUnscrollable, bar, true) end
  local function Fades()
    local cur = scroll:GetVerticalScroll() or 0
    local range = Range()
    local top, bottom = cur > 0.5, range - cur > 0.5
    if list.topOn ~= top then list.topOn = top; list.fadeTop:SetShown(top) end
    if list.bottomOn ~= bottom then list.bottomOn = bottom; list.fadeBottom:SetShown(bottom) end
    if bar and not barSelf and list.barOn ~= (range > 0.5) then list.barOn = range > 0.5; bar:SetShown(list.barOn) end
  end
  -- On an overlay above the scroll child, so the fades soften the rows.
  list.fades, list.fadeTop, list.fadeBottom = UI.EdgeFades(parent, scroll, 0.6, 0.6, 16, 16)
  list.fadeTop:Hide(); list.fadeBottom:Hide()
  list.topOn, list.bottomOn = false, false
  -- One wheel tick = one row, landing on whole rows; instant, as a
  -- ScrollFrame's wheel is (no easing to jitter against focus moves).
  scroll:EnableMouseWheel(true)
  scroll:SetScript("OnMouseWheel", function(self, delta)
    local step = list.wheelStep or rowHeight
    local cur = self:GetVerticalScroll() or 0
    local v = math.max(0, math.min(Range(), (math.floor(cur / step + 0.5) - delta) * step))
    if math.abs(v - cur) < 0.5 then return end
    self:SetVerticalScroll(v)
    Fades()
    list:KeepFocusVisible()
  end)
  -- Focus never stays off-screen (spec §4.5): after a wheel tick or a
  -- right-stick scroll (SmartNavigation scrolls without a wheel event), move
  -- it to the first fully visible row. Skipped while Focus:Set itself is
  -- scrolling a node into view, so the two never fight.
  function list.KeepFocusVisible(self)
    local F = ns.Focus
    local f = F and F.current
    if not f or F.setting or self.fixing or f.acScroll ~= self or self:IsRowVisible(f) then return end
    self.fixing = true
    for _, r in ipairs(self:Nodes()) do
      if self:IsRowVisible(r) then F:Set(r, F.source == "mouse" and "mouse" or "key", true, true) break end
    end
    self.fixing = nil
  end
  if scroll.HookScript then
    scroll:HookScript("OnVerticalScroll", function() Fades(); list:KeepFocusVisible() end)
  end

  function list.SetWheelStep(self, s) self.wheelStep = s end
  function list.SetData(self, data)
    self.data = data or {}
    for i, d in ipairs(self.data) do
      local row = self.rows[i]
      if not row then
        row = makeRow(child, i)
        if not row.acNode then UI.Node(row, { style = "row" }) end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -(i - 1) * rowHeight)
        row:SetPoint("TOPRIGHT", child, "TOPRIGHT", 0, -(i - 1) * rowHeight)
        if not row._h then row:SetHeight(rowHeight) end
        self.rows[i] = row
      end
      row.acScroll, row.acIndex, row.acData = self, i, d
      row:Show()
      fillRow(row, d, i)
    end
    for i = #self.data + 1, #self.rows do self.rows[i]:Hide() end
    local h = math.max(#self.data * rowHeight, 1)
    if child:GetHeight() ~= h then child:SetHeight(h) end
    local range = Range()
    if (scroll:GetVerticalScroll() or 0) > range then scroll:SetVerticalScroll(range) end
    Fades()
  end
  function list.Nodes(self)
    local out = {}
    for i = 1, #self.data do
      local r = self.rows[i]
      if r and r:IsShown() and (not ns.Focus or ns.Focus.Usable(r)) then out[#out + 1] = r end
    end
    return out
  end
  function list.VisibleRows(self)
    return math.max(1, math.floor((scroll:GetHeight() or rowHeight) / rowHeight))
  end
  function list.IsRowVisible(self, row)
    local i = row.acIndex or 1
    local top = (i - 1) * rowHeight
    local cur = scroll:GetVerticalScroll() or 0
    return top >= cur - 0.5 and top + rowHeight <= cur + (scroll:GetHeight() or 0) + 0.5
  end
  -- Scrolls so the row and one row of context on each side are visible.
  function list.ScrollToNode(self, row)
    local i = row.acIndex
    if not i then return end
    local h = scroll:GetHeight() or 0
    local cur = scroll:GetVerticalScroll() or 0
    local range = Range()
    local top, bottom = (i - 2) * rowHeight, (i + 1) * rowHeight
    local new = cur
    if top < cur then new = top elseif bottom > cur + h then new = bottom - h end
    new = math.max(0, math.min(range, new))
    if new ~= cur then scroll:SetVerticalScroll(new) end
    Fades()
  end
  return list
end

-- Model -------------------------------------------------------------------------------------
-- A PlayerModel of unit, w x h, with the class crest faintly behind it (the
-- model draws over it; without models only the crest shows). The mouse drags
-- to rotate; the controller never captures the stick for it.
function UI.Model(parent, unit, w, h)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetSize(w or 230, h or 300)
  local crest = holder:CreateTexture(nil, "BACKGROUND")
  crest:SetSize(math.min(w or 230, h or 300) * 0.6, math.min(w or 230, h or 300) * 0.6)
  crest:SetPoint("CENTER")
  local _, class = UnitClass("player")
  crest:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
  if class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class] then crest:SetTexCoord(unpack(CLASS_ICON_TCOORDS[class])) end
  crest:SetAlpha(0.25)
  holder.crest = crest
  local ok, m = pcall(CreateFrame, "PlayerModel", nil, holder)
  if ok and m then
    m:SetAllPoints()
    holder.model = m
    function holder.SetUnit(self, u)
      if not self.model.SetUnit then return end
      if u ~= "player" and UnitExists and not UnitExists(u) then self.model:Hide() return end
      self.model:Show()
      pcall(self.model.SetUnit, self.model, u)
      if self.model.SetPortraitZoom then pcall(self.model.SetPortraitZoom, self.model, 0) end
      if self.model.SetCamDistanceScale then pcall(self.model.SetCamDistanceScale, self.model, 1.15) end
      if self.model.SetAnimation then pcall(self.model.SetAnimation, self.model, 0) end
    end
    m:EnableMouse(true)
    local facing, dragX = 0, nil
    -- The drag runs an OnUpdate only while the button is held.
    local function Drag(self)
      if not (dragX and GetCursorPosition) then return end
      local x = GetCursorPosition()
      if x == dragX then return end
      facing = facing + (x - dragX) * 0.01
      dragX = x
      if self.SetFacing then pcall(self.SetFacing, self, facing) end
    end
    local function StopDrag(self) dragX = nil; self:SetScript("OnUpdate", nil) end
    m:SetScript("OnMouseDown", function(self)
      dragX = GetCursorPosition and GetCursorPosition()
      if dragX then self:SetScript("OnUpdate", Drag) end
    end)
    m:SetScript("OnMouseUp", StopDrag)
    m:SetScript("OnHide", StopDrag)
    holder:SetUnit(unit or "player")
  else
    function holder.SetUnit() end
  end
  UI.MarkIgnored(holder)
  return holder
end

-- Socket (back buttons) -------------------------------------------------------------------------
-- An empty gem socket (character-emptysocket, 32) with a keycap label under
-- it. Not a focus target: the back paddles stay free for now (owner rule).
function UI.Socket(parent, label)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(40, 58)
  f.socket = f:CreateTexture(nil, "ARTWORK")
  f.socket:SetSize(32, 32)
  f.socket:SetPoint("TOP")
  if not UI.SetAtlas(f.socket, UI.ART.socket) then f.socket:SetTexture("Interface\\ItemSocketingFrame\\UI-EmptySocket") end
  f.cap = UI.Keycap(f, label or "", 22)
  f.cap:SetPoint("TOP", f.socket, "BOTTOM", 0, -4)
  UI.MarkIgnored(f)
  return f
end

-- Section title and zebra rows ---------------------------------------------------------------------

-- Section header on the character sheet's title plate for a 24 px slot at
-- TOPLEFT x, y, w wide. Returns the font string (fs.plate is the art).
-- The plate keeps its native 40 px height (CharacterFrame.xml draws
-- UI-Character-Info-Title 195-197 x 40, stretched only across), centred on
-- the slot: it reaches 8 px above and below it, so leave 8 px clear there.
-- The width is capped at 360 (the ornaments smear beyond ~2x the atlas
-- width); a wider slot centres the plate in it.
-- The text is centred between the plate's end ornaments, as the character
-- sheet's stat category titles are.
local TITLE_MAX_W = 360
function UI.SectionTitle(parent, text, x, y, w)
  local plate = parent:CreateTexture(nil, "BACKGROUND", nil, 1)
  w = w or 300
  local pw = math.min(w, TITLE_MAX_W)
  local px = (x or 0) + math.floor((w - pw) / 2)
  if UI.SetAtlas(plate, UI.ART.title) then
    plate:SetPoint("TOPLEFT", px, (y or 0) + 8)
    plate:SetSize(pw, 40)
  else
    plate:SetPoint("TOPLEFT", px, y or 0)
    plate:SetSize(pw, 24)
    plate:SetTexture(UI.WHITE); plate:SetVertexColor(0.9, 0.62, 0.32, 0.18)
  end
  local fs = UI.Text(parent, text, "GameFontHighlight")
  fs:SetPoint("LEFT", plate, "LEFT", 22, 0)
  fs:SetPoint("RIGHT", plate, "RIGHT", -22, 0)
  fs:SetJustifyH("CENTER")
  fs:SetWordWrap(false)
  fs.plate = plate
  return fs
end

-- A label / value row on the zebra stripe (index odd/even alternates),
-- w x 24. row.label (gold), row.value (white, right), row:SetValue(text [, color]).
function UI.StatRow(parent, label, value, w, zebraIndex)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(w or 300, 24)
  row.bg = row:CreateTexture(nil, "BACKGROUND")
  row.bg:SetAllPoints()
  local even = (zebraIndex or 1) % 2 == 0
  if UI.SetAtlas(row.bg, even and UI.ART.zebra2 or UI.ART.zebra) then
    if even and not UI.HasAtlas("UI-Character-Info-Line-Bounce2") then row.bg:SetAlpha(0.45) end
  else
    row.bg:SetTexture(UI.WHITE); row.bg:SetVertexColor(1, 1, 1, even and 0.03 or 0.06)
  end
  row.label = UI.Text(row, label or "", "GameFontNormal")
  row.label:SetPoint("LEFT", 8, 0)
  row.label:SetJustifyH("LEFT")
  row.value = UI.Text(row, value or "", "GameFontHighlight")
  row.value:SetPoint("RIGHT", -8, 0)
  row.value:SetPoint("LEFT", row.label, "RIGHT", 8, 0)
  row.value:SetJustifyH("RIGHT")
  row.value:SetWordWrap(false)
  function row.SetValue(self, t, color)
    self.value:SetText(t or "")
    if color then self.value:SetTextColor(UI.RowRGB(color)) else self.value:SetTextColor(1, 1, 1) end
  end
  return row
end

-- Modifier preview ----------------------------------------------------------------------------------
-- Polls Shift / Ctrl / Alt at 20 Hz while frame is shown and calls
-- fn(shift, ctrl, alt) when they change (LT = Shift and RT = Ctrl on the
-- Gamepad UI). Display only: nothing is bound or consumed.
function UI.WatchModifiers(frame, fn)
  local acc, last = 0, nil
  local function Poll()
    local s = IsShiftKeyDown and IsShiftKeyDown() and true or false
    local c = IsControlKeyDown and IsControlKeyDown() and true or false
    local a = IsAltKeyDown and IsAltKeyDown() and true or false
    local key = (s and "s" or "") .. (c and "c" or "") .. (a and "a" or "")
    if key ~= last then
      last = key
      pcall(fn, s, c, a)
    end
  end
  frame.acPollModifiers = Poll
  frame:HookScript("OnUpdate", function(_, elapsed)
    acc = acc + (elapsed or 0)
    if acc < 0.05 then return end
    acc = 0
    Poll()
  end)
  frame:HookScript("OnHide", function() if last and last ~= "" then last = nil; pcall(fn, false, false, false) end end)
  return Poll
end
