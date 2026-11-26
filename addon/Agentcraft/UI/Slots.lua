-- Keyboard keys and native-style controller slots (dev/ui-spec-v2.md §9.2-9.3).
--   UI.KeySlot(parent, size)          a keyboard key: Slot + key letter + caption + pips
--   UI.PadSlot(parent, shape, size)   a Gamepad action bar slot, "square" (D-pad) or "circle" (face)
--   UI.PadBar(parent, layer)          one bar of the native Gamepad HUD: two diamonds of PadSlots
-- The controller art copies Blizzard_GamepadActionBars (ActionBarButton.xml,
-- ActionBarButton.lua, ActionBarStyles.lua): https://github.com/Gethe/wow-ui-source/tree/forever/Interface/AddOns/Blizzard_GamepadActionBars
local _, ns = ...
local UI = ns.UI

-- KeySlot ----------------------------------------------------------------------------------
-- The hotkey sits top-right, right-justified, as ActionButtonTemplate's HotKey
-- (Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml: TOPRIGHT with the
-- keyboard offset -4, -5). NumberFont* fonts are outlined, so nothing is drawn
-- behind the letter. (The focus ring redraws the letter above itself, see
-- UI.FocusRing, so the focused key's letter is never covered.)
-- The caption and pips are placed by UI.Slot (Widgets.lua).
local function SetKeyText(self, text) self.key:SetText(text or "") end

function UI.KeySlot(parent, size)
  local s = UI.Slot(parent, size)
  s.key:SetFontObject(size >= 44 and "NumberFontNormal" or "NumberFontNormalSmallGray")
  s.key:ClearAllPoints()
  s.key:SetPoint("TOPRIGHT", -4, -5)
  s.key:SetJustifyH("RIGHT")
  s.SetKey = SetKeyText
  s:SetCaption("")
  return s
end

-- PadSlot ----------------------------------------------------------------------------------
-- The art of GamepadActionBarButtonTemplate (ActionBarButton.xml, and
-- SetShapeToSquare / SetShapeToCircle in ActionBarButton.lua):
--   drop shadow      4 px out on every side (the collapsed shadow distance)
--   empty slot art   SlotArt, all points, only while nothing is placed
--   icon             all points, under a Square/CircleMask inset 3 px
--   normal / pushed  the shape's border-normal / border-pressed (button states)
--   highlight        border-hover (mouse)
--   Border           UI-HUD-ActionBar-IconFrame-Border (square) or
--                    circleslot-iconframe-border, tinted for a state, as
--                    ActionButton tints it for equipped items
--   checked          border-selected, 4 px out (the checked distance): pinned
--   permabound       circleslot-permabound, TOPLEFT 3,-2 / BOTTOMRIGHT -2,3
--   button glyph     15 px, TOPRIGHT -1,-1 (square) or 0,-3 (circle)
-- Forever names come first, then a retail atlas of the same role, so the
-- offline renderer still draws real art. Every texture is made here once;
-- the setters only toggle and tint.
-- Has every UI.Slot method plus SetGlyph(key [, corner]), SetPinned(b),
-- SetPermabound(b), SetEmptyKey(key).
local EMPTY = {
  PADDUP = { "gamepad-actionbar-squareslot-generic-dpadup-normal", "gamepad-actionbar-squareslot-empty-dpadup" },
  PADDDOWN = { "gamepad-actionbar-squareslot-generic-dpaddown-normal", "gamepad-actionbar-squareslot-empty-dpaddown" },
  PADDLEFT = { "gamepad-actionbar-squareslot-generic-dpadleft-normal", "gamepad-actionbar-squareslot-empty-dpadleft" },
  PADDRIGHT = { "gamepad-actionbar-squareslot-generic-dpadright-normal", "gamepad-actionbar-squareslot-empty-dpadright" },
  PAD1 = { "gamepad-actionbar-circleslot-xbox-a-normal", "gamepad-actionbar-circleslot-empty-xba" },
  PAD2 = { "gamepad-actionbar-circleslot-xbox-b-normal", "gamepad-actionbar-circleslot-empty-xbb" },
  PAD3 = { "gamepad-actionbar-circleslot-xbox-x-normal", "gamepad-actionbar-circleslot-empty-xbx" },
  PAD4 = { "gamepad-actionbar-circleslot-xbox-y-normal", "gamepad-actionbar-circleslot-empty-xby" },
}
UI.PAD_EMPTY = EMPTY
-- The face buttons' empty art follows the controller's label style, as
-- INPUT_DEVICE_ACTION_BUTTON_TEXTURE_SETS does (ActionBarButton.lua): Shapes
-- draws the PlayStation symbols, Reverse swaps the letters (A/B, X/Y).
local EMPTY_STYLE = {
  Shapes = { PAD1 = "gamepad-actionbar-circleslot-ps-cross-normal", PAD2 = "gamepad-actionbar-circleslot-ps-circle-normal",
    PAD3 = "gamepad-actionbar-circleslot-ps-square-normal", PAD4 = "gamepad-actionbar-circleslot-ps-triangle-normal" },
  Reverse = { PAD1 = "gamepad-actionbar-circleslot-xbox-b-normal", PAD2 = "gamepad-actionbar-circleslot-xbox-a-normal",
    PAD3 = "gamepad-actionbar-circleslot-xbox-y-normal", PAD4 = "gamepad-actionbar-circleslot-xbox-x-normal" },
}
local function EmptyList(key)
  local style = (UI.GlyphStyle and UI.GlyphStyle() == "Shapes" and "Shapes")
    or (UI.LabelStyle and UI.LabelStyle() == "Reverse" and "Reverse") or nil
  local own = style and EMPTY_STYLE[style][key]
  if own then return { own, EMPTY[key] and EMPTY[key][2] } end
  return EMPTY[key]
end

local SHAPE_ART = {
  square = {
    normal = { "gamepad-actionbar-squareslot-border-normal", "gamepad-actionbar-squareslot-frame" },
    pushed = { "gamepad-actionbar-squareslot-border-pressed" },
    hover = { "gamepad-actionbar-squareslot-border-hover" },
    selected = { "gamepad-actionbar-squareslot-border-selected", "gamepad-actionbar-slot-frame-select" },
    border = { "UI-HUD-ActionBar-IconFrame-Border" },
    glyphX = -1, glyphY = -1,
  },
  circle = {
    normal = { "gamepad-actionbar-circleslot-border-normal", "gamepad-actionbar-circleslot-frame" },
    pushed = { "gamepad-actionbar-circleslot-border-pressed" },
    hover = { "gamepad-actionbar-circleslot-border-hover" },
    selected = { "gamepad-actionbar-circleslot-border-selected", "gamepad-actionbar-slot-frame-select" },
    border = { "gamepad-actionbar-circleslot-iconframe-border", "UI-HUD-ActionBar-IconFrame-Border" },
    glyphX = 0, glyphY = -3,
  },
}
local GLYPH_SIZE = 15

local Pad = {}

-- The empty slot art shows only while no icon is placed; the plain slot
-- background stands in where the client has no empty art. The empty art
-- already draws the button (arrow, letter or symbol), so the corner glyph
-- hides meanwhile: one button name per slot, never two.
local function SyncEmpty(self)
  local bare = not self.icon:IsShown()
  local art = bare and self.hasEmptyArt == true
  self.empty:SetShown(art)
  self.bg:SetShown(bare and not self.hasEmptyArt and self.hasBg == true)
  if self.glyphKey then self.glyph:SetShown(not art) end
end

local function ResolveEmpty(self)
  local key = self.emptyKey
  local a = key and UI.FirstAtlas(EmptyList(key))
  if a and a ~= self.emptyAtlas then self.empty:SetAtlas(a) end
  self.emptyAtlas = a
  self.hasEmptyArt = a ~= nil
end

function Pad:SetIcon(tex, faded)
  faded = faded == true
  -- A bare slot shows its empty art: pick it up for the current label style.
  if tex == nil and self.emptyKey then ResolveEmpty(self) end
  self.icon:SetTexture(tex)
  -- A file icon after an atlas icon (the Controller page's "atlas:" icons)
  -- would keep the atlas's coordinates; the mask rounds it, so show it whole.
  if tex ~= nil then self.icon:SetTexCoord(0, 1, 0, 1) end
  self.icon:SetShown(tex ~= nil)
  self.icon:SetDesaturated(faded)
  self.icon:SetAlpha(faded and 0.45 or 1)
  SyncEmpty(self)
end

local function Tint(t, color)
  if color then
    local r, g, b = UI.RGB(color)
    t:SetVertexColor(r, g, b, 1)
    t:Show()
  else
    t:Hide()
  end
end
function Pad:SetMark(color) Tint(self.mark, color) end
function Pad:SetEdge(color) Tint(self.edgeRing, color) end

function Pad:SetGlyph(key, corner)
  self.glyphKey = key
  if not key then self.glyph:Hide() return end
  self.glyph:SetKey(key)
  local c = corner or self.glyphCorner or "TOPRIGHT"
  if self.glyphAt ~= c then
    self.glyphAt = c
    local art = SHAPE_ART[self.shape]
    local ox = c:find("LEFT") and -art.glyphX or art.glyphX
    local oy = c:find("BOTTOM") and -art.glyphY or art.glyphY
    self.glyph:ClearAllPoints()
    self.glyph:SetPoint(c, self, c, ox, oy)
  end
  self.glyph:Show()
  SyncEmpty(self)
end

function Pad:SetEmptyKey(key)
  self.emptyKey = key
  ResolveEmpty(self)
  SyncEmpty(self)
end

-- Re-syncs empty art and glyph after the icon texture was set directly
-- (an atlas icon via SetAtlas, which SetIcon cannot take).
function Pad:RefreshEmpty() SyncEmpty(self) end

function Pad:SetPinned(on) self.select:SetShown(on and self.hasSelect and true or false) end
function Pad:SetPermabound(on) self.perma:SetShown(on and self.hasPerma and true or false) end

-- Sets a button state atlas (Normal / Pushed / Highlight) and returns its
-- texture, anchored to the whole button as UpdateButtonArtAnchoring does.
local function StateArt(b, kind, list)
  local a = UI.FirstAtlas(list)
  local set = b["Set" .. kind .. "Atlas"]
  if not a or type(set) ~= "function" then return nil end
  local made = set(b, a)
  local get = b["Get" .. kind .. "Texture"]
  local t = (type(get) == "function" and get(b)) or made
  if type(t) ~= "table" then return nil end
  t:ClearAllPoints()
  t:SetAllPoints(b)
  return t
end

function UI.PadSlot(parent, shape, size)
  size = size or 46
  local circle = shape == "circle"
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size, size)
  b.shape = circle and "circle" or "square"
  local art = SHAPE_ART[b.shape]

  b.shadow = b:CreateTexture(nil, "BACKGROUND", nil, -2)
  b.shadow:SetPoint("TOPLEFT", -4, 4)
  b.shadow:SetPoint("BOTTOMRIGHT", 4, -4)
  if not UI.SetAtlas(b.shadow, circle and UI.ART.padCircleShadow or UI.ART.padSquareShadow) then b.shadow:Hide() end

  b.bg = b:CreateTexture(nil, "BACKGROUND", nil, -1)
  b.bg:SetPoint("TOPLEFT", 3, -3)
  b.bg:SetPoint("BOTTOMRIGHT", -3, 3)
  b.hasBg = UI.SetAtlas(b.bg, UI.ART.padSlotBg) ~= nil
  b.bg:Hide()

  b.icon = b:CreateTexture(nil, "BACKGROUND", nil, 1)
  b.icon:SetAllPoints()
  b.icon:Hide()
  local masked = false
  if b.CreateMaskTexture then
    local mask = b:CreateMaskTexture(nil, "BACKGROUND")
    mask:SetPoint("TOPLEFT", 3, -3)
    mask:SetPoint("BOTTOMRIGHT", -3, 3)
    local a = UI.FirstAtlas(circle and UI.ART.padCircleMask or UI.ART.padSquareMask)
    if a then mask:SetAtlas(a)
    elseif circle then mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE") end
    if a or circle then b.icon:AddMaskTexture(mask); masked = true end
    b.iconMask = mask
  end
  if not masked then
    b.icon:ClearAllPoints()
    b.icon:SetPoint("TOPLEFT", 3, -3)
    b.icon:SetPoint("BOTTOMRIGHT", -3, 3)
  end

  b.empty = b:CreateTexture(nil, "BACKGROUND", nil, 2)
  b.empty:SetAllPoints()
  b.empty:Hide()

  b.frameArt = StateArt(b, "Normal", art.normal)
  if not b.frameArt then
    b.frameArt = b:CreateTexture(nil, "ARTWORK", nil, 2)
    b.frameArt:SetAllPoints()
    UI.SetAtlas(b.frameArt, art.normal)
  end
  b.pushedArt = StateArt(b, "Pushed", art.pushed)
  b.hoverArt = StateArt(b, "Highlight", art.hover)

  -- State rings: the shape's own Border art, tinted (never the slot frame).
  b.mark = b:CreateTexture(nil, "OVERLAY", nil, 1)
  b.mark:SetAllPoints()
  UI.SetAtlas(b.mark, art.border)
  b.mark:Hide()
  b.edgeRing = b:CreateTexture(nil, "OVERLAY", nil, 0)
  b.edgeRing:SetAllPoints()
  UI.SetAtlas(b.edgeRing, art.border)
  b.edgeRing:Hide()

  b.select = b:CreateTexture(nil, "OVERLAY", nil, 2)
  b.select:SetPoint("TOPLEFT", -4, 4)
  b.select:SetPoint("BOTTOMRIGHT", 4, -4)
  b.hasSelect = UI.SetAtlas(b.select, art.selected) ~= nil
  b.select:Hide()

  b.perma = b:CreateTexture(nil, "OVERLAY", nil, 3)
  b.perma:SetPoint("TOPLEFT", 3, -2)
  b.perma:SetPoint("BOTTOMRIGHT", -2, 3)
  b.hasPerma = UI.SetAtlas(b.perma, UI.ART.padPermabound) ~= nil
  b.perma:Hide()

  -- Fields UI.Slot methods use.
  b.edge = {}
  b.flyout = b:CreateTexture(nil, "OVERLAY", nil, 4)
  b.flyout:SetPoint("TOP", 0, -1)
  if not UI.SetAtlas(b.flyout, "UI-HUD-ActionBar-Flyout", true) then
    b.flyout:SetSize(14, 8)
    b.flyout:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
  end
  b.flyout:Hide()
  b.plus = UI.Text(b, "+", "GameFontGreenSmall")
  b.plus:SetPoint("TOPLEFT", 4, -2)
  b.plus:Hide()
  b.key = UI.Text(b, "", "NumberFontNormalSmallGray")
  b.key:SetPoint("TOPRIGHT", -4, -5)
  b.key:SetJustifyH("RIGHT")
  b.key:Hide()
  b.center = UI.Text(b, "", "GameFontHighlightSmall")
  b.center:SetPoint("CENTER")
  b.glyph = UI.Glyph(b, nil, GLYPH_SIZE, "pad")
  b.glyph:SetFrameLevel(b:GetFrameLevel() + 3)
  b.glyph:Hide()

  -- Borrow the UI.Slot methods from one hidden prototype.
  if not UI._slotProto then
    UI._slotProto = UI.Slot(UIParent, 1)
    UI._slotProto:Hide()
    UI._slotProto.acSkip = true
  end
  local slot = UI._slotProto
  -- The Slot mixin's own methods (UI.SlotMethods), unless Pad has its own.
  -- Not "b[k] == nil": a widget model may answer every unknown method (the
  -- dev harness turns them into no-ops), and SetState / SetBadge would be lost.
  for k, v in pairs(UI.SlotMethods or slot) do
    if type(v) == "function" and k:match("^%u") and Pad[k] == nil then b[k] = v end
  end
  for k, v in pairs(Pad) do b[k] = v end
  b.SetKey = function(self, text) self.key:SetText(text or ""); self.key:SetShown(text ~= nil and text ~= "") end
  b:SetScript("OnEnter", slot:GetScript("OnEnter"))
  b:SetScript("OnLeave", GameTooltip_Hide)
  b.acTip, b.acInspect = slot.acTip, slot.acInspect
  UI.Node(b, { style = b.shape })
  SyncEmpty(b)
  return b
end

-- PadBar ----------------------------------------------------------------------------------
-- One bar of the native HUD: the D-pad diamond (squares) on the left, the
-- face diamond (circles) on the right, Y on top and A at the bottom.
-- Offsets follow the native expanded layout, spaced to 48 px between slot
-- centres so 46 px slots never overlap (spec §9.3 x1.15 table, widened).
-- Bars sit 194 px left/right and 108 px up/down of the cross centre.
UI.PAD_BUTTONS = { "Up", "Right", "Down", "Left", "Y", "B", "A", "X" } -- native order
UI.PAD_OFFSETS = {
  Up = { -86, 30, "square", "PADDUP" }, Down = { -86, -30, "square", "PADDDOWN" },
  Left = { -134, 0, "square", "PADDLEFT" }, Right = { -38, 0, "square", "PADDRIGHT" },
  Y = { 80, 30, "circle", "PAD4" }, A = { 80, -30, "circle", "PAD1" },
  X = { 32, 0, "circle", "PAD3" }, B = { 128, 0, "circle", "PAD2" },
}
-- Bar centres relative to the HUD's cross centre (stage 362, 236), y up.
UI.PAD_BAR_OFFSETS = { [0] = { 0, 108 }, { -194, 0 }, { 194, 0 }, { 0, -108 } }
UI.PAD_LAYER_TRIGGERS ={ [0] = {}, { "PADLTRIGGER" }, { "PADRTRIGGER" }, { "PADLTRIGGER", "PADRTRIGGER" } }
local SECTION_FOCUS = { "gamepad-actionbar-focus-bg-section" }

-- layer: 0 = no trigger, 1 = LT, 2 = RT, 3 = LT + RT. size: slot size (46).
-- bar.slots[name] (name from UI.PAD_BUTTONS), bar.title, bar.triggers,
-- bar:SetExpanded(b), bar:SetTitle(text).
function UI.PadBar(parent, layer, size)
  size = size or 46
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetSize(300, 110)
  bar.layer = layer or 0
  -- No backing behind the diamonds: the native bar's LeftButtonFrame /
  -- RightButtonFrame (gamepad-actionbar-bg) stay hidden in both the
  -- collapsed and the expanded style (ActionBarStyles.lua), so the slots
  -- stand on their own drop shadows. bar.backs stays for callers.
  bar.backs = {}
  -- The focused bar's BackgroundFocus (ActionBarTemplates.xml): the soft
  -- gamepad-actionbar-focus-bg-section band at alpha 0.375, 512x160 behind
  -- a 266x86 bar. (Not gamepad-actionbar-stance-backing: that is the stance
  -- bar's winged watermark, and stretched it draws big grey wings.)
  bar.section = bar:CreateTexture(nil, "BACKGROUND", nil, -1)
  bar.section:SetSize(512, 160)
  bar.section:SetPoint("CENTER")
  if not UI.SetAtlas(bar.section, SECTION_FOCUS) then bar.section:SetTexture(nil) end
  bar.section:SetAlpha(0.375)
  bar.section:Hide()

  bar.slots = {}
  for _, name in ipairs(UI.PAD_BUTTONS) do
    local o = UI.PAD_OFFSETS[name]
    local s = UI.PadSlot(bar, o[3], size)
    s:SetPoint("CENTER", bar, "CENTER", o[1], o[2])
    s.padName, s.padKey = name, o[4]
    s:SetGlyph(o[4])
    s:SetEmptyKey(o[4])
    s.acId = "pad:" .. bar.layer .. ":" .. name
    bar.slots[name] = s
  end
  -- The Blizzard diamond moves (explicit), leaving the bar spatially.
  local S = bar.slots
  S.Up.navDown, S.Up.navLeft, S.Up.navRight = S.Down, S.Left, S.Right
  S.Down.navUp, S.Down.navLeft, S.Down.navRight = S.Up, S.Left, S.Right
  S.Left.navRight, S.Left.navUp, S.Left.navDown = S.Right, S.Up, S.Down
  S.Right.navLeft, S.Right.navUp, S.Right.navDown, S.Right.navRight = S.Left, S.Up, S.Down, S.X
  S.X.navLeft, S.X.navRight, S.X.navUp, S.X.navDown = S.Right, S.B, S.Y, S.A
  S.Y.navDown, S.Y.navLeft, S.Y.navRight = S.A, S.X, S.B
  S.A.navUp, S.A.navLeft, S.A.navRight = S.Y, S.X, S.B
  S.B.navLeft, S.B.navUp, S.B.navDown = S.X, S.Y, S.A

  bar.title = UI.Text(bar, "", "GameFontNormal")
  bar.title:SetPoint("BOTTOM", bar, "TOP", 0, 2)
  -- Trigger glyphs under the bar (LT, RT or both), as the native HUD shows them.
  bar.triggers = {}
  local keys = UI.PAD_LAYER_TRIGGERS[bar.layer] or {}
  for i, k in ipairs(keys) do
    local g = UI.Glyph(bar, k, 28, "pad")
    g:SetPoint("TOP", bar, "BOTTOM", (#keys == 2) and (i == 1 and -16 or 16) or 0, -2)
    bar.triggers[i] = g
  end
  function bar.SetTitle(self, t) self.title:SetText(t or "") end
  -- Expanded (the focused bar): the section glow only. The bar never scales
  -- (ui-rules 1); a scaled bar also lands its art on half pixels.
  function bar.SetExpanded(self, on)
    on = on and true or false
    if self.expanded == on then return end
    self.expanded = on
    self.section:SetShown(on)
  end
  -- Not a Gamepad UI stop itself; its slots inside are (a plain ignore mark
  -- would hide them too).
  UI.MarkContainer(bar)
  return bar
end
