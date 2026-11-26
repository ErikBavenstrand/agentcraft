-- Shared building blocks for Agentcraft pages, so every page looks the same.
-- Each widget prefers the client's own Blizzard template or atlas (WoW
-- Forever runs the modern templates with its bronze "Camelot" art) and falls
-- back to plain textures on clients without it. dev/ui-widgets.md lists
-- every function with its template and fallback.
local _, ns = ...
local UI = {}
ns.UI = UI

UI.QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

-- Feature checks ------------------------------------------------------------------

local templateCache, atlasCache = {}, {}

-- True when the client knows the Blizzard template `name`.
function UI.Has(name)
  local v = templateCache[name]
  if v == nil then
    v = (C_XMLUtil and C_XMLUtil.GetTemplateInfo and C_XMLUtil.GetTemplateInfo(name)) ~= nil
    templateCache[name] = v
  end
  return v
end
UI.HasTemplate = UI.Has

-- True when the client has the texture atlas `name`.
function UI.HasAtlas(name)
  local v = atlasCache[name]
  if v == nil then
    v = (C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)) ~= nil
    atlasCache[name] = v
  end
  return v
end

-- True when the Gamepad UI (Blizzard's controller mode) is on.
function UI.GamepadUI()
  if C_InputInterfaceStyle and C_InputInterfaceStyle.GetCurrentStyle and Enum and Enum.InputDeviceInterfaceType then
    local gp = Enum.InputDeviceInterfaceType.Gamepad
    return gp ~= nil and C_InputInterfaceStyle.GetCurrentStyle() == gp
  end
  return C_GamePad and C_GamePad.IsEnabled and C_GamePad.IsEnabled() and true or false
end

-- The first atlas in `list` (a name or a list of names) the client has, or nil.
-- Lists name the WoW Forever atlas first and a retail atlas of the same role
-- after it, so both clients (and the offline renderer) draw real art.
function UI.FirstAtlas(list)
  if type(list) == "string" then return UI.HasAtlas(list) and list or nil end
  for _, name in ipairs(list or {}) do
    if UI.HasAtlas(name) then return name end
  end
end

-- Sets the first available atlas of `list` on texture `tex`. Returns the name
-- it used, or nil (the caller draws its fallback). Pass useAtlasSize = true
-- unless the frame really needs another size (dev/ui-rules.md rule 7).
function UI.SetAtlas(tex, list, useAtlasSize)
  local a = UI.FirstAtlas(list)
  if a then tex:SetAtlas(a, useAtlasSize) end
  return a
end

-- Native width and height of an atlas, or nil.
function UI.AtlasSize(name)
  local info = name and C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(name)
  if type(info) == "table" and (info.width or 0) > 0 and (info.height or 0) > 0 then return info.width, info.height end
end

-- Sets the first atlas of `list` on tex at width w with its own aspect ratio
-- (a uniform scale, never a stretch). Returns the name, or nil.
function UI.SetAtlasWidth(tex, list, w)
  local a = UI.SetAtlas(tex, list, true)
  if not a then return nil end
  local aw, ah = UI.AtlasSize(a)
  if aw and w then tex:SetSize(w, ah * w / aw) end
  return a
end

-- SetRoundLayoutToNearestPixel(true) on frame, its regions and every child
-- frame, as PixelUtil.SetRoundLayoutToNearestPixelRecursively does
-- (Blizzard_SharedXML/PixelUtil.lua). On the Steam Deck (800 px tall) one
-- physical pixel is 0.96 UI units, so whole offsets land on half pixels
-- without it. Objects
-- already done are skipped, so calling it again after a refresh only touches
-- what was created since.
local function SnapOne(r)
  if rawget(r, "_acPx") or not r.SetRoundLayoutToNearestPixel then return end
  pcall(r.SetRoundLayoutToNearestPixel, r, true)
  rawset(r, "_acPx", true)
end
-- A stable path step for the dev capture (UI/Capture.lua names objects by
-- their parentKey): SetParentKey where the client has it. Keys start with
-- "ac" so they never clash with a template's own keys.
function UI.Name(obj, key)
  if type(obj) == "table" and key and obj.SetParentKey then pcall(obj.SetParentKey, obj, key) end
  return obj
end

function UI.PixelSnap(frame)
  if type(frame) ~= "table" then return end
  SnapOne(frame)
  if frame.GetRegions then
    for _, r in ipairs({ frame:GetRegions() }) do if type(r) == "table" then SnapOne(r) end end
  end
  if frame.GetChildren then
    for _, c in ipairs({ frame:GetChildren() }) do UI.PixelSnap(c) end
  end
end

-- Art roles: Forever (Camelot) name first, retail name second. Every name is
-- from Blizzard's UI source or the client atlas table (dev/ui-spec-v2.md §6.4).
UI.ART = {
  title = { "UI-Character-Info-Title" },
  zebra = { "UI-Character-Info-Line-Bounce" },
  zebra2 = { "UI-Character-Info-Line-Bounce2", "UI-Character-Info-Line-Bounce" },
  statBg = { "UI-Character-Info-Stat-BG" },
  stoneBg = { "UI-Character-Info-Stat-StoneBG3" },
  generalBg = { "UI-Character-Info-General-BG" },
  gearSlot = { "UI-Character-Info-GearSlot", "ui-hud-actionbar-iconframe-background" },
  card = { "UI-Character-Info-OutfitCard" },
  cardHover = { "UI-Character-Info-OutfitCard-Hover", "Options_List_Hover" },
  cardSelected = { "UI-Character-Info-OutfitCard-Selected", "Options_List_Active" },
  tick = { "UI-Character-Info-Icon-Tick", "checkmark-minimal" },
  divider = { "common-framedivider" },
  hline = { "UI-Character-Info-ScrollLine-Long", "UI-Character-Info-ScrollLine", "Options_HorizontalDivider" },
  rowHover = { "Options_List_Hover" },
  rowActive = { "Options_List_Active" },
  heroBg = { "Talents-Background-c60" },
  heroFrame = { "Talents-inner-frame-c60", "common-insideframe" },
  ring = { "Talents-Main-Ring-c60", "talents-main-ring-box-c60" },
  smallDivider = { "Talents-small-divider-c60" },
  clouds = { "talents-animations-clouds" },
  particles = { "talents-animations-particles" },
  bookLeft = { "spellbook-Page-Left-C60" },
  bookRight = { "spellbook-Page-Right-C60" },
  socket = { "character-emptysocket" },
  warning = { "services-icon-warning" },
  star = { "auctionhouse-icon-favorite", "PetJournal-FavoritesIcon" },
  meterGreen = { "common-stat-bar-green" },
  meterWhite = { "common-stat-bar-white" },
  meterRed = { "common-stat-bar-red" },
  keycap = { "UI-HUD-ActionBar-IconFrame-Background" },
  slotFlash = { "UI-HUD-ActionBar-IconFrame-Flash" },
  autocast = { "UI-HUD-ActionBar-PetAutoCast-Corners", "gamepad-actionbar-circleslot-petautocastcorners" },
  glowLeft = { "newplayertutorial-yellowGlow-redbutton-left" },
  glowMiddle = { "newplayertutorial-yellowGlow-redbutton-middle" },
  glowRight = { "newplayertutorial-yellowGlow-redbutton-right" },
  -- Native Gamepad action bar HUD (Blizzard_GamepadActionBars).
  padBarBg = { "gamepad-actionbar-bg" },
  padSlotBg = { "gamepad-actionbar-slot-bg-empty" },
  padSelect = { "gamepad-actionbar-slot-frame-select" },
  padFocus = { "gamepad-actionbar-slot-frame-focused", "gamepad-actionbar-slot-frame-select" },
  padSquareFrame = { "gamepad-actionbar-squareslot-frame" },
  padCircleFrame = { "gamepad-actionbar-circleslot-frame" },
  padSquareShadow = { "gamepad-actionbar-squareslot-dropshadow", "gamepad-actionbar-squareslot-xtradropshadow" },
  padCircleShadow = { "gamepad-actionbar-circleslot-dropshadow", "gamepad-actionbar-circleslot-xtradropshadow" },
  -- Focus glows of the slot's own shape. The fx-* and -dropshadow names are
  -- Forever's (Blizzard_GamepadActionBars/ActionBarButton.xml: SquareGlowFocus,
  -- CircleGlowFocus, SquareShadow, CircleShadow); the retail fallback is the
  -- shape's toggle ring, never the round filled targeting-overlayglow, so a
  -- square D-pad slot always keeps square art.
  padSquareGlow = { "gamepad-actionbar-fx-squareglw", "gamepad-actionbar-squareslot-toggle" },
  padCircleGlow = { "gamepad-actionbar-fx-circglw", "gamepad-actionbar-circleslot-toggle" },
  padSquareFocusBg = { "gamepad-actionbar-focus-bg-square" },
  padCircleFocusBg = { "gamepad-actionbar-focus-bg-circ" },
  padSectionFocus = { "gamepad-actionbar-focus-bg-section", "gamepad-actionbar-stance-backing" },
  padPermabound = { "gamepad-actionbar-circleslot-permabound" },
  padSquareMask = { "SquareMask" },
  padCircleMask = { "CircleMask" },
}

-- Gamepad smart navigation: skip decorative frames, group sections.
function UI.MarkIgnored(frame)
  if SmartNavigation_MarkFrameIgnored then pcall(SmartNavigation_MarkFrameIgnored, frame) end
end
-- The frame itself is not a Gamepad UI stop (it takes a mouse script, such as
-- the stage's right-click Back), but the nodes inside it still are
-- (Utility.lua SmartNavigation_MarkFrameIgnoredContainerFrame).
function UI.MarkContainer(frame)
  if SmartNavigation_MarkFrameIgnoredContainerFrame then pcall(SmartNavigation_MarkFrameIgnoredContainerFrame, frame) end
end

-- Focus nodes (dev/ui-spec-v2.md §4.1): any interactive frame the shared
-- focus (mouse, keys, controller) can land on. opts (all optional):
--   style    acFocusStyle: "slot", "square", "circle", "row", "card", "button", "chip"
--   id       acId, a stable id for focus restore ("key:Q")
--   inspect  acInspect(node, pane): fills the Inspector
--   activate acActivate(node): what A / Enter does (default node:Click())
-- Hovering never moves the focus or changes the Inspector (owner, 2026-11-15:
-- it read as the side column flickering under the mouse); hover shows only
-- the template highlight and the tooltip. A click focuses the node, which
-- fills the Inspector, the same as moving there with keys or the pad.
function UI.Node(w, opts)
  opts = opts or {}
  if not w.acNode then
    w.acNode = true
    -- A click on a node focuses it and engages the keyboard (spec 4.3):
    -- OnMouseDown does not bubble to the window, so the frame's own hook
    -- never sees it.
    w:HookScript("OnMouseDown", function(self)
      local F = ns.Focus
      if not F then return end
      if F.Set and not F.setting then F:Set(self, "click", true, true) end
      if F.Engage and not (InCombatLockdown and InCombatLockdown()) then F:Engage() end
    end)
    -- Gamepad UI: SmartNavigation landed on the node (our jump override
    -- already focused it, then the call is a no-op), and A on it runs the
    -- window's Activate, not a plain click (UI/Input.lua, "The Gamepad UI
    -- follows the window's own focus graph").
    w.OnSmartNavSelect = function(self)
      local F = ns.Focus
      if F and F.Set and F.current ~= self then F:Set(self, "pad") end
    end
    w.OnSmartNavClick = function(self)
      local F = ns.Focus
      if F and F.Usable and F.Usable(self) then
        if F.current ~= self then F:Set(self, "pad", true) end
        F:Activate("pad")
      elseif self.Click then
        self:Click("LeftButton")
      end
      return true
    end
  end
  w.acFocusStyle = opts.style or w.acFocusStyle or "button"
  if opts.id then w.acId = opts.id end
  if opts.inspect then w.acInspect = opts.inspect end
  if opts.activate then w.acActivate = opts.activate end
  return w
end

-- A plain Interface\Buttons\WHITE8x8 texture: our own flat art (plates,
-- gradients, rules). Coloured with SetVertexColor, never SetColorTexture, so
-- it is art, not a "color-fill" (dev/ui-spec-v2.md §11.4).
UI.WHITE = "Interface\\Buttons\\WHITE8x8"
function UI.Flat(parent, layer, r, g, b, a, sub)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub)
  t:SetTexture(UI.WHITE)
  t:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
  return t
end

-- A vertical or horizontal gradient on WHITE8x8 (vignettes, fade masks).
-- c1/c2 are { r, g, b, a } (bottom/left first, as SetGradient takes them).
function UI.Gradient(parent, layer, orientation, c1, c2, sub)
  local t = parent:CreateTexture(nil, layer or "OVERLAY", nil, sub)
  t:SetTexture(UI.WHITE)
  if t.SetGradient and CreateColor then
    t:SetGradient(orientation or "VERTICAL", CreateColor(c1[1], c1[2], c1[3], c1[4]), CreateColor(c2[1], c2[2], c2[3], c2[4]))
  else
    t:SetVertexColor(c1[1], c1[2], c1[3], ((c1[4] or 1) + (c2[4] or 1)) / 2)
  end
  return t
end
-- Top and bottom edge fades over a scroll frame. A parent frame's textures
-- always draw below its child frames, so the gradients live on an overlay
-- frame raised above the scroll child (else the rows cover them).
-- Returns overlay, fadeTop, fadeBottom; overlay:SetTone(r, g, b) recolours.
function UI.EdgeFades(parent, scroll, alphaTop, alphaBottom, hTop, hBottom)
  local ov = CreateFrame("Frame", nil, parent)
  ov:SetAllPoints(scroll)
  ov:SetFrameLevel((scroll:GetFrameLevel() or 0) + 20)
  if ov.EnableMouse then ov:EnableMouse(false) end
  ov.acSkip = true
  if UI.MarkIgnored then UI.MarkIgnored(ov) end
  local top = UI.Gradient(ov, "OVERLAY", "VERTICAL", { 0, 0, 0, 0 }, { 0, 0, 0, alphaTop }, 6)
  top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(hTop or 16)
  local bottom = UI.Gradient(ov, "OVERLAY", "VERTICAL", { 0, 0, 0, alphaBottom }, { 0, 0, 0, 0 }, 6)
  bottom:SetPoint("BOTTOMLEFT"); bottom:SetPoint("BOTTOMRIGHT"); bottom:SetHeight(hBottom or 16)
  function ov:SetTone(r, g, b, aT, aB)
    aT, aB = aT or alphaTop, aB or alphaBottom
    if top.SetGradient and CreateColor then
      top:SetGradient("VERTICAL", CreateColor(r, g, b, 0), CreateColor(r, g, b, aT))
      bottom:SetGradient("VERTICAL", CreateColor(r, g, b, aB), CreateColor(r, g, b, 0))
    else
      top:SetVertexColor(r, g, b, aT / 2); bottom:SetVertexColor(r, g, b, aB / 2)
    end
  end
  return ov, top, bottom
end

function UI.MarkSubSection(frame, key)
  if SmartNavigation_MarkFrameSubSection then pcall(SmartNavigation_MarkFrameSubSection, frame, key) end
end

-- Colours ---------------------------------------------------------------------------
-- Blizzard colour objects (ColorMixin: GetRGB, WrapTextInColorCode), with a
-- small stand-in on clients that lack one. Build coloured strings only with
-- UI.C.X:WrapTextInColorCode(text).

local ColorProto = {}
ColorProto.__index = ColorProto
function ColorProto:GetRGB() return self.r, self.g, self.b end
function ColorProto:GetRGBA() return self.r, self.g, self.b, self.a or 1 end
function ColorProto:GenerateHexColor()
  return string.format("ff%02x%02x%02x", math.floor(self.r * 255 + 0.5), math.floor(self.g * 255 + 0.5), math.floor(self.b * 255 + 0.5))
end
function ColorProto:WrapTextInColorCode(text) return "|c" .. self:GenerateHexColor() .. tostring(text) .. "|r" end

local function NewColor(r, g, b) return setmetatable({ r = r, g = g, b = b, a = 1 }, ColorProto) end

local function Blizz(name, r, g, b)
  local c = _G[name]
  if type(c) == "table" and c.GetRGB and c.WrapTextInColorCode then
    local ok, cr = pcall(c.GetRGB, c)
    if ok and type(cr) == "number" then return c end
  end
  return NewColor(r, g, b)
end

UI.C = {
  NORMAL    = Blizz("NORMAL_FONT_COLOR", 1, 0.82, 0),
  HIGHLIGHT = Blizz("HIGHLIGHT_FONT_COLOR", 1, 1, 1),
  GRAY      = Blizz("GRAY_FONT_COLOR", 0.5, 0.5, 0.5),
  DISABLED  = Blizz("DISABLED_FONT_COLOR", 0.5, 0.5, 0.5),
  GREEN     = Blizz("GREEN_FONT_COLOR", 0.1, 1, 0.1),
  RED       = Blizz("RED_FONT_COLOR", 1, 0.125, 0.125),
  ORANGE    = Blizz("ORANGE_FONT_COLOR", 1, 0.5, 0.25),
  LIGHTBLUE = Blizz("LIGHTBLUE_FONT_COLOR", 0.53, 0.67, 1),
}
-- Dark ink for text drawn straight on light parchment (Blizzard's parchment
-- UIs: QuestFont / GameFontBlack). UI.C's other colours are for dark
-- backgrounds and clash on parchment (dev/ui-rules.md §19).
UI.C.INK = CreateColor and CreateColor(0.18, 0.12, 0.06) or UI.C.NORMAL
UI.C.INK_DIM = CreateColor and CreateColor(0.32, 0.24, 0.16) or UI.C.GRAY
function UI.Ink(fs, dim)
  if not fs then return fs end
  local c = dim and UI.C.INK_DIM or UI.C.INK
  fs:SetTextColor(UI.RGB(c))
  if fs.SetShadowColor then fs:SetShadowColor(0, 0, 0, 0) end
  return fs
end
-- Meanings (spec §4): use these names in page code.
UI.C.ADDED, UI.C.MISSING, UI.C.REMOVED, UI.C.REPLACES = UI.C.GREEN, UI.C.RED, UI.C.ORANGE, UI.C.ORANGE
UI.C.BAR, UI.C.PET, UI.C.FIXED = UI.C.NORMAL, UI.C.LIGHTBLUE, UI.C.GRAY

-- Old { r, g, b } names, kept so existing code works.
local function RGB(c) return { c:GetRGB() } end
UI.GOLD, UI.GREEN, UI.RED, UI.ORANGE, UI.BLUE =
  RGB(UI.C.NORMAL), RGB(UI.C.GREEN), RGB(UI.C.RED), RGB(UI.C.ORANGE), RGB(UI.C.LIGHTBLUE)

-- r, g, b from a colour object or an { r, g, b } list.
function UI.RGB(c)
  if type(c) ~= "table" then return 1, 1, 1 end
  if c.GetRGB then return c:GetRGB() end
  return c[1] or 1, c[2] or 1, c[3] or 1
end

-- r, g, b for text on the tan zebra row bars (UI-Character-Info-Line-Bounce,
-- about rgb 92,68,54). Pure red (MISSING) and mid grey (FIXED, DISABLED,
-- GRAY) reach only about 2:1 there, so they are lifted to a light red and
-- a light grey; every other colour is returned as is.
function UI.RowRGB(c)
  local r, g, b = UI.RGB(c)
  if r > 0.8 and g < 0.35 and b < 0.35 then return 1, 0.5, 0.45 end
  if math.abs(r - g) < 0.06 and math.abs(g - b) < 0.06 and r < 0.72 then return 0.8, 0.8, 0.8 end
  return r, g, b
end

-- Lookups that work on both modern and classic APIs ---------------------------
-- (Parenthesised: C_Spell.GetSpellTexture returns extra values on 12.x, and a
-- tail call would pass them on as more arguments.)

function UI.SpellIcon(spell) -- spell ID or name
  if not spell then return end
  if C_Spell and C_Spell.GetSpellTexture then return (C_Spell.GetSpellTexture(spell)) end
  if GetSpellTexture then return (GetSpellTexture(spell)) end
end

function UI.SpellName(id)
  if C_Spell and C_Spell.GetSpellName then return (C_Spell.GetSpellName(id)) end
  if GetSpellInfo then return (GetSpellInfo(id)) end
end

function UI.ItemIcon(id)
  if not id then return end
  if C_Item and C_Item.GetItemIconByID then return (C_Item.GetItemIconByID(id)) end
  if GetItemIcon then return (GetItemIcon(id)) end
end

function UI.ItemName(id)
  if C_Item and C_Item.GetItemNameByID then return (C_Item.GetItemNameByID(id)) end
  if C_Item and C_Item.GetItemInfo then return (C_Item.GetItemInfo(id)) end
end

-- A key as the default action bars abbreviate it ("SHIFT-Q" -> "s-Q",
-- "BUTTON4" -> "M4"), through GetBindingText when the client has it.
function UI.KeyText(key)
  if not key or key == "" then return "" end
  if GetBindingText then
    local ok, t = pcall(GetBindingText, key, nil, true)
    if ok and type(t) == "string" and t ~= "" then return t end
  end
  key = key:gsub("SHIFT%-", "s-"):gsub("ALT%-", "a-"):gsub("CTRL%-", "c-")
           :gsub("MOUSEWHEELUP", "WU"):gsub("MOUSEWHEELDOWN", "WD"):gsub("BUTTON", "M")
  return key
end

-- A key's full name ("Mouse Button 4", "Shift-Q").
function UI.KeyName(key)
  if not key or key == "" then return "" end
  if GetBindingText then
    local ok, t = pcall(GetBindingText, key)
    if ok and type(t) == "string" and t ~= "" then return t end
  end
  return key
end

-- What a binding command does: { icon, name, tip } or nil when unbound.
local BAR_COMMANDS = {
  { "^ACTIONBUTTON(%d+)$", 0 },
  { "^MULTIACTIONBAR1BUTTON(%d+)$", 60 },
  { "^MULTIACTIONBAR2BUTTON(%d+)$", 48 },
  { "^MULTIACTIONBAR3BUTTON(%d+)$", 24 },
  { "^MULTIACTIONBAR4BUTTON(%d+)$", 36 },
  -- Bars 6-8 of the modern client; classic clients never bind these.
  { "^MULTIACTIONBAR5BUTTON(%d+)$", 144 },
  { "^MULTIACTIONBAR6BUTTON(%d+)$", 156 },
  { "^MULTIACTIONBAR7BUTTON(%d+)$", 168 },
}

function UI.DescribeSlot(slot)
  local kind, id = GetActionInfo(slot)
  local d = { icon = GetActionTexture(slot), kind = "bar", actionKind = kind }
  if kind == "spell" then d.name = UI.SpellName(id)
  elseif kind == "item" then d.name = UI.ItemName(id)
  elseif kind == "macro" then d.name = GetActionText(slot) or "Macro"
  elseif not kind then d.name = "Empty slot"
  elseif kind == "flyout" then d.name = (GetFlyoutInfo and GetFlyoutInfo(id)) or "Flyout"
  else d.name = GetActionText(slot) or kind end
  d.tip = kind and { action = slot } or { title = "Empty slot" }
  return d
end

-- Pet bar command slots (Classic: 1 Attack, 2 Follow, 3 Stay, 8 Aggressive,
-- 9 Defensive, 10 Passive) for when GetPetActionInfo has nothing (no pet
-- out) or a token has no global: { name token, name, texture token, texture }.
-- Tokens and textures: Blizzard_FrameXMLBase/Constants.lua,
-- https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_FrameXMLBase/Constants.lua
local PET_COMMANDS = {
  [1] = { "PET_ACTION_ATTACK", "Attack", "PET_ATTACK_TEXTURE", "Interface\\Icons\\Ability_GhoulFrenzy" },
  [2] = { "PET_ACTION_FOLLOW", "Follow", "PET_FOLLOW_TEXTURE", "Interface\\Icons\\Ability_Tracking" },
  [3] = { "PET_ACTION_WAIT", "Stay", "PET_WAIT_TEXTURE", "Interface\\Icons\\Spell_Nature_TimeStop" },
  [8] = { "PET_MODE_AGGRESSIVE", "Aggressive", "PET_AGGRESSIVE_TEXTURE", "Interface\\Icons\\Ability_Racial_BloodRage" },
  [9] = { "PET_MODE_DEFENSIVE", "Defensive", "PET_DEFENSIVE_TEXTURE", "Interface\\Icons\\Ability_Defend" },
  [10] = { "PET_MODE_PASSIVE", "Passive", "PET_PASSIVE_TEXTURE", "Interface\\Icons\\Ability_Seal" },
}
local PET_BY_TOKEN = {}
for _, e in pairs(PET_COMMANDS) do PET_BY_TOKEN[e[1]] = e; PET_BY_TOKEN[e[3]] = e end
UI.PET_COMMANDS = PET_COMMANDS

-- Name and icon of pet bar slot n: the live pet bar, else the static command table.
function UI.PetSlotInfo(n)
  local name, tex, isToken
  if GetPetActionInfo then name, tex, isToken = GetPetActionInfo(n) end
  if isToken then
    local e = PET_BY_TOKEN[name] or PET_BY_TOKEN[tex]
    local tn, tt = name, tex
    name = (tn and _G[tn]) or (e and e[2]) or tn
    tex = (tt and _G[tt]) or (e and e[4]) or nil
  end
  local e = PET_COMMANDS[n]
  if not name and e then name = _G[e[1]] or e[2] end
  if not tex and e then tex = _G[e[3]] or e[4] end
  return name, tex
end

function UI.DescribeCommand(command)
  if not command or command == "" then return nil end
  for _, c in ipairs(BAR_COMMANDS) do
    local n = command:match(c[1])
    if n then return UI.DescribeSlot(c[2] + tonumber(n)) end
  end
  local pet = command:match("^BONUSACTIONBUTTON(%d+)$")
  if pet then
    pet = tonumber(pet)
    local live = GetPetActionInfo and GetPetActionInfo(pet)
    local name, tex = UI.PetSlotInfo(pet)
    local label = name or ((pet >= 4 and pet <= 7) and ("Pet ability " .. (pet - 3)) or ("Pet slot " .. pet))
    return { icon = tex, name = label, kind = "pet",
             tip = live and { pet = pet } or { title = label, text = "Pet bar slot " .. pet .. "." } }
  end
  -- Direct binds to a macro, spell or item by name. A bind to a macro that
  -- doesn't exist does nothing in game, so say so.
  local macro = command:match("^MACRO (.+)$")
  if macro then
    local index = GetMacroIndexByName and GetMacroIndexByName(macro) or 0
    if index > 0 then
      local _, icon = GetMacroInfo(index)
      return { icon = icon, name = macro, kind = "macro", tip = { title = "Macro: " .. macro } }
    end
    return { name = macro .. " (missing)", kind = "missing",
             tip = { title = "Macro: " .. macro, text = "No macro with this name exists, so this key does nothing.", color = UI.C.RED } }
  end
  local spell = command:match("^SPELL (.+)$")
  if spell then
    return { icon = UI.SpellIcon(spell), name = spell, kind = "spell", tip = { title = spell } }
  end
  local item = command:match("^ITEM (.+)$")
  if item then
    local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(item)
    return { icon = icon, name = item, kind = "item", tip = { title = item } }
  end
  local name = _G["BINDING_NAME_" .. command] or command
  return { name = name, kind = "other", tip = { title = name } }
end

-- Basic pieces ------------------------------------------------------------------

function UI.Text(parent, text, font)
  local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
  if text then fs:SetText(text) end
  return fs
end

-- Flat colour fill and 1px border: fallbacks only. Prefer UI.Inset/UI.Panel.
function UI.Fill(frame, r, g, b, a, layer)
  local t = frame:CreateTexture(nil, layer or "BACKGROUND")
  t:SetAllPoints()
  t:SetColorTexture(r, g, b, a)
  return t
end

-- 1px border; returns the 4 textures (recolour with UI.SetBorder).
function UI.Border(frame, r, g, b, a, layer)
  local edges = {}
  for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local t = frame:CreateTexture(nil, layer or "BORDER", nil, 7)
    t:SetColorTexture(r, g, b, a)
    if side == "TOP" or side == "BOTTOM" then
      t:SetPoint(side .. "LEFT"); t:SetPoint(side .. "RIGHT"); t:SetHeight(1)
    else
      t:SetPoint("TOP" .. side); t:SetPoint("BOTTOM" .. side); t:SetWidth(1)
    end
    edges[#edges + 1] = t
  end
  return edges
end

-- color: { r, g, b }, a colour object, or nil to hide.
function UI.SetBorder(edges, color, a)
  for _, t in ipairs(edges) do
    if color then
      local r, g, b = UI.RGB(color)
      t:SetColorTexture(r, g, b, a or 1); t:Show()
    else
      t:Hide()
    end
  end
end

-- Recessed panel well (the window's own inset look). Caller anchors it.
function UI.Inset(parent)
  if UI.Has("InsetFrameTemplate") then
    return CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
  end
  local f = CreateFrame("Frame", nil, parent)
  f.Bg = UI.Fill(f, 0, 0, 0, 0.35)
  f.edges = UI.Border(f, 1, 1, 1, 0.08)
  return f
end

-- A sub-panel inside a page (controller bars, macro detail). Caller anchors it.
function UI.Panel(parent)
  local f
  if UI.Has("InsetFrameTemplate3") then
    f = CreateFrame("Frame", nil, parent, "InsetFrameTemplate3")
  else
    f = CreateFrame("Frame", nil, parent)
    f.Bg = UI.Fill(f, 0, 0, 0, 0.25)
    f.edges = UI.Border(f, 1, 1, 1, 0.08)
  end
  return f
end

-- A thin horizontal rule. With x, y, width it is placed at TOPLEFT x, y of
-- the parent; otherwise the caller anchors it.
function UI.Divider(parent, x, y, width)
  local t = parent:CreateTexture(nil, "ARTWORK")
  -- The character sheet's scroll line at its own height (it is more than
  -- 1 px of art; squashing it to 1 px blurred it).
  if not UI.SetAtlas(t, UI.ART.hline, true) then
    t:SetColorTexture(1, 1, 1, 0.1)
    t:SetHeight(1)
  end
  if x then
    t:SetPoint("TOPLEFT", x, y or 0)
    t:SetWidth(width or math.max(parent:GetWidth() - x, 1))
  end
  return t
end

-- Tooltips ------------------------------------------------------------------------

local function Resolve(v, ...)
  if type(v) == "function" then return v(...) end
  return v
end

-- Fills GameTooltip: a title (white) and body lines. lines is a string, a
-- list of strings, or a list of { text, color } pairs.
function UI.ShowTooltip(owner, title, lines, anchor)
  GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
  if GameTooltip_SetTitle then GameTooltip_SetTitle(GameTooltip, title or "")
  else GameTooltip:SetText(title or "", 1, 1, 1) end
  if type(lines) == "string" then lines = { lines } end
  for _, line in ipairs(lines or {}) do
    local text, color = line, nil
    if type(line) == "table" then text, color = line[1], line[2] end
    if text and text ~= "" then
      if color then
        local r, g, b = UI.RGB(color)
        GameTooltip:AddLine(text, r, g, b, true)
      elseif GameTooltip_AddNormalLine then
        GameTooltip_AddNormalLine(GameTooltip, text, true)
      else
        GameTooltip:AddLine(text, 1, 0.82, 0, true)
      end
    end
  end
  GameTooltip:Show()
end

-- title and text may be functions (re-read every time the tooltip opens).
-- The widget becomes a focus node; widget.acTip(widget) shows the tooltip
-- (the focus core calls it on keyboard/controller focus when Options ›
-- "Tooltips on focus" is on), and the default Inspector shows the same text.
function UI.Tooltip(widget, title, text)
  widget.acTip = function(self)
    local t = Resolve(title, self)
    if not t or t == "" then return end
    UI.ShowTooltip(self, t, Resolve(text, self))
  end
  if not widget.acInspect then
    widget.acInspect = function(self, pane)
      local t = Resolve(title, self)
      if not t or t == "" then return end
      pane:Header(nil, t)
      local body = Resolve(text, self)
      if type(body) == "table" then
        for _, line in ipairs(body) do pane:Text(type(line) == "table" and line[1] or line) end
      elseif body then pane:Text(body) end
    end
  end
  widget:HookScript("OnEnter", function(self) self:acTip() end)
  widget:HookScript("OnLeave", GameTooltip_Hide)
  UI.Node(widget)
end

-- Buttons -----------------------------------------------------------------------

-- Width that fits a button's text: max(min, text + 28).
function UI.FitButton(b, min)
  local fs = b.GetFontString and b:GetFontString()
  local w = fs and fs:GetStringWidth() or 0
  b:SetWidth(math.max(min or 80, math.floor(w + 28 + 0.5)))
end

-- Red panel button. width nil = fit the text (at least 80). height: 22 by
-- default, 26 for buttons inside pages (gamepad target size).
function UI.Button(parent, text, width, onClick, tooltip, height)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(width or 80, height or 22)
  b:SetText(text)
  if not width then UI.FitButton(b) end
  b:SetScript("OnClick", onClick)
  if tooltip then UI.Tooltip(b, text, tooltip) end
  UI.Node(b, { style = "button" })
  return b
end

-- The window's primary prompt (footer "Review & Apply 4", the Review sheet's
-- Apply): a stock red UIPanelButtonTemplate, 28 tall, with the button glyph
-- inline at its left (pad / keyboard prompt modes) and the label after it.
-- The button is always as wide as glyph + label + padding, so the label (and
-- the count in it) stays inside the art. UIPanelGoldButtonTemplate was used
-- before: its art has transparent margins (about 8 px left, 20 px right), so
-- the label ran over the art's right edge in the capture.
-- "Glow" (changes are ready) is the button's own highlight locked on, a
-- static Blizzard state: GlowEmitterFactory drew a dark box with
-- zero-height NineSlice edges around the button.
-- Same interface as UI.Prompt: SetLabel, SetKey, Relayout, SetGlow, glyph,
-- label, width, primary, disabledReason. maxW caps the width (the label
-- truncates past it).
local PRIMARY_PAD, PRIMARY_MIN = 14, 120
function UI.PrimaryPrompt(parent, key, label, fn, maxW)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetHeight(28)
  b:SetText("")
  b.primary = true
  b.maxW = maxW or 300
  b.glyph = UI.Glyph(b, key, 22, "prompt")
  b.label = UI.Text(b, label or "", "GameFontNormal")
  b.label:SetJustifyH("LEFT")
  b.label:SetWordWrap(false)
  if b.label.SetMaxLines then b.label:SetMaxLines(1) end
  local function Paint(self)
    self.label:SetFontObject(self:IsEnabled() and "GameFontNormal" or "GameFontDisable")
  end
  b:HookScript("OnEnable", Paint)
  b:HookScript("OnDisable", Paint)
  b:SetScript("OnClick", function(self)
    if self.disabledReason then return end
    if fn then fn(self) end
  end)
  function b.Relayout(self)
    local gw = self.glyph.width or 0
    local gap = gw > 0 and 4 or 0
    local fs = self.label
    local tw = math.ceil((fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth()) or fs:GetStringWidth() or 0)
    local room = self.maxW - 2 * PRIMARY_PAD - gw - gap
    tw = math.max(math.min(tw, room), 1)
    fs:SetWidth(tw + 1)
    local content = gw + gap + tw + 1
    local w = math.max(content + 2 * PRIMARY_PAD, PRIMARY_MIN)
    self:SetWidth(w)
    local x = math.floor((w - content) / 2)
    self.glyph:ClearAllPoints()
    self.glyph:SetPoint("LEFT", self, "LEFT", x, 0)
    fs:ClearAllPoints()
    fs:SetPoint("LEFT", self, "LEFT", x + gw + gap, 0)
    self.width = w
  end
  function b.SetLabel(self, t) self.label:SetText(t or ""); self:Relayout() end
  function b.SetKey(self, k) self.glyph:SetKey(k); self:Relayout() end
  function b.SetGlow(self, on)
    on = on and true or false
    if on == self.glowing then return end
    self.glowing = on
    if on and self.LockHighlight then self:LockHighlight()
    elseif self.UnlockHighlight then self:UnlockHighlight() end
  end
  -- Focus also locks the highlight (Input.lua); keep it locked on blur while
  -- the button glows.
  b.acOnBlur = function(self) if self.glowing and self.LockHighlight then self:LockHighlight() end end
  UI.Node(b, { style = "button" })
  Paint(b)
  b:Relayout()
  return b
end

-- Check box row: the whole row (box + label) is one button that toggles the
-- box. onClick(row, checked) runs after a click. row:SetChecked/GetChecked,
-- row.box, row.label, row.desc (when desc is given).
local CheckRow = {}
function CheckRow:SetChecked(v) self.box:SetChecked(v and true or false) end
function CheckRow:GetChecked() return self.box:GetChecked() and true or false end
function CheckRow:SetEnabled(v)
  self.box:SetEnabled(v and true or false)
  self:EnableMouse(v and true or false)
  self.label:SetFontObject(v and "GameFontNormal" or "GameFontDisable")
end

function UI.Check(parent, label, desc, onClick)
  local row = CreateFrame("Button", nil, parent)
  row:SetSize(300, desc and 36 or 28)
  local box
  if UI.Has("MinimalCheckboxTemplate") then
    box = CreateFrame("CheckButton", nil, row, "MinimalCheckboxTemplate")
  else
    box = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
  end
  box:SetSize(28, 28)
  box:SetPoint("TOPLEFT", 0, desc and -4 or 0)
  row.box = box
  row.label = UI.Text(row, label or "", "GameFontNormal")
  row.label:SetJustifyH("LEFT")
  row.label:SetWordWrap(false)
  if desc then
    row.label:SetPoint("TOPLEFT", box, "TOPRIGHT", 4, -2)
    row.label:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, -6)
    row.desc = UI.Text(row, desc, "GameFontHighlightSmall")
    row.desc:SetPoint("TOPLEFT", row.label, "BOTTOMLEFT", 0, -2)
    row.desc:SetPoint("TOPRIGHT", row.label, "BOTTOMRIGHT", 0, -2)
    row.desc:SetJustifyH("LEFT")
    row.desc:SetWordWrap(false)
  else
    row.label:SetPoint("LEFT", box, "RIGHT", 4, 0)
    row.label:SetPoint("RIGHT", row, "RIGHT", 0, 0)
  end
  for k, v in pairs(CheckRow) do row[k] = v end
  box:SetScript("OnClick", function()
    if onClick then onClick(row, row:GetChecked()) end
  end)
  row:SetScript("OnClick", function()
    if box.IsEnabled and not box:IsEnabled() then return end
    box:SetChecked(not box:GetChecked())
    if onClick then onClick(row, row:GetChecked()) end
  end)
  row:SetScript("OnEnter", function() if box.LockHighlight then box:LockHighlight() end end)
  row:SetScript("OnLeave", function() if box.UnlockHighlight then box:UnlockHighlight() end end)
  -- The row is the focus node (A toggles it); the box itself is not, nor a
  -- Gamepad UI stop.
  UI.Node(row, { style = "row" })
  UI.MarkIgnored(box)
  if row.acInspect == nil then
    row.acInspect = function(self, pane)
      pane:Header(nil, label or "", self:GetChecked() and "On" or "Off")
      if desc then pane:Text(desc) end
    end
  end
  return row
end

-- Top tabs. Returns a bar frame (caller anchors its TOPLEFT; it is 32 tall)
-- with bar.Tabs, bar:Select(i, silent), bar.selected, bar:SetLabel(i, text).
-- onSelect(i, bar) runs when the player picks a tab.
function UI.Tabs(parent, labels, onSelect, maxWidth)
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetSize(maxWidth or 580, 32)
  bar.Tabs = {}
  local modern = UI.Has("PanelTopTabButtonTemplate") and PanelTemplates_SetNumTabs and PanelTemplates_SetTab
  for i, text in ipairs(labels) do
    local tab
    if modern then
      tab = CreateFrame("Button", nil, bar, "PanelTopTabButtonTemplate")
    else
      tab = CreateFrame("Button", nil, bar, "UIPanelButtonTemplate")
      tab:SetHeight(26)
    end
    tab:SetID(i)
    tab:SetText(text)
    if i == 1 then tab:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
    else tab:SetPoint("LEFT", bar.Tabs[i - 1], "RIGHT", modern and 0 or 4, 0) end
    tab:SetScript("OnClick", function()
      if PlaySound and SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_TAB then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB) end
      bar:Select(i)
    end)
    bar.Tabs[i] = tab
  end
  local function Fit()
    if modern then
      if PanelTemplates_ResizeTabsToFit then pcall(PanelTemplates_ResizeTabsToFit, bar, maxWidth or 580)
      elseif PanelTemplates_TabResize then
        for _, tab in ipairs(bar.Tabs) do pcall(PanelTemplates_TabResize, tab, 0) end
      end
    else
      for _, tab in ipairs(bar.Tabs) do UI.FitButton(tab) end
    end
  end
  if modern then PanelTemplates_SetNumTabs(bar, #labels) end
  Fit()
  function bar:Select(i, silent)
    self.selected = i
    if modern then
      PanelTemplates_SetTab(self, i)
    else
      for j, tab in ipairs(self.Tabs) do
        if j == i then tab:LockHighlight() else tab:UnlockHighlight() end
      end
    end
    if onSelect and not silent then onSelect(i, self) end
  end
  function bar:SetLabel(i, text)
    if self.Tabs[i] then self.Tabs[i]:SetText(text); Fit() end
  end
  bar:Select(1, true)
  return bar
end

-- Menus (dropdowns) -------------------------------------------------------------

-- True when the client has the modern Menu API dropdowns.
function UI.HasMenu()
  return UI.Has("WowStyle1DropdownTemplate") and UI.Has("WowStyle1FilterDropdownTemplate")
end

local function MenuFallback(parent, text, setupFn)
  local b = UI.Button(parent, text, nil, function(self)
    if MenuUtil and MenuUtil.CreateContextMenu then MenuUtil.CreateContextMenu(self, setupFn) end
  end)
  b.fallback = true
  function b.SetupMenu(self, fn) setupFn = fn end
  function b.GenerateMenu() end
  function b.SetDefaultText(self, t) self:SetText(t) end
  return b
end

-- Filter button (checkbox menu, as in Collections). setupFn(owner, root) uses
-- root:CreateTitle / CreateCheckbox / CreateButton / CreateDivider. Call
-- dd:GenerateMenu() after the state it shows changes. Without the Menu API
-- it is a plain button (dd.fallback = true) that opens a context menu.
function UI.Filter(parent, setupFn, text)
  if not UI.Has("WowStyle1FilterDropdownTemplate") then return MenuFallback(parent, text or FILTER or "Filter", setupFn) end
  local dd = CreateFrame("DropdownButton", nil, parent, "WowStyle1FilterDropdownTemplate")
  if text and dd.SetText then dd:SetText(text) end
  dd:SetupMenu(setupFn)
  return dd
end

-- Selection dropdown (radio menu). setupFn(owner, root) uses root:CreateRadio.
function UI.Dropdown(parent, setupFn, width, defaultText)
  if not UI.Has("WowStyle1DropdownTemplate") then return MenuFallback(parent, defaultText or "", setupFn) end
  local dd = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
  if width then dd:SetWidth(width) end
  if defaultText and dd.SetDefaultText then dd:SetDefaultText(defaultText) end
  dd:SetupMenu(setupFn)
  return dd
end

-- Horizontal slider with steppers. onChange(value) runs on every change.
-- Returns the slider frame; move it with holder:SetSliderValue(v); the
-- value is shown in holder.valueText to its right.
function UI.Slider(parent, min, max, step, value, onChange, width, format)
  format = format or function(v) return string.format("%.2f", v) end
  local holder
  if UI.Has("MinimalSliderWithSteppersTemplate") then
    holder = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
    holder:SetSize(width or 200, 20)
    local steps = math.floor((max - min) / step + 0.5)
    if holder.Init then holder:Init(value, min, max, steps) end
    if holder.RegisterCallback and MinimalSliderWithSteppersMixin and MinimalSliderWithSteppersMixin.Event then
      holder:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, v)
        if holder.valueText then holder.valueText:SetText(format(v)) end
        if onChange then onChange(v) end
      end, holder)
    end
    function holder.SetSliderValue(self, v) if self.SetValue then self:SetValue(v) end end
  else
    holder = CreateFrame("Slider", nil, parent, UI.Has("OptionsSliderTemplate") and "OptionsSliderTemplate" or nil)
    holder:SetSize(width or 200, 16)
    holder:SetOrientation("HORIZONTAL")
    holder:SetMinMaxValues(min, max)
    holder:SetValueStep(step)
    if holder.SetObeyStepOnDrag then holder:SetObeyStepOnDrag(true) end
    holder:SetValue(value)
    holder:SetScript("OnValueChanged", function(_, v)
      v = math.floor(v / step + 0.5) * step
      if holder.valueText then holder.valueText:SetText(format(v)) end
      if onChange then onChange(v) end
    end)
    function holder.SetSliderValue(self, v) self:SetValue(v) end
  end
  holder.valueText = UI.Text(holder, format(value), "GameFontHighlight")
  holder.valueText:SetPoint("LEFT", holder, "RIGHT", 8, 0)
  return holder
end

-- Scrolling -----------------------------------------------------------------------

-- Scroll frame filling the parent (minus 18px on the right for the scroll
-- bar) with a child to put rows in. Returns scroll, child. Set the child's
-- height to the total row height; its width follows the scroll frame.
function UI.Scroll(parent)
  local modern = UI.Has("ScrollFrameTemplate")
  local scroll = CreateFrame("ScrollFrame", nil, parent, modern and "ScrollFrameTemplate" or "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, 0)
  scroll:SetPoint("BOTTOMRIGHT", modern and -18 or -26, 0)
  local child = CreateFrame("Frame", nil, scroll)
  local w = parent:GetWidth() - (modern and 18 or 26)
  child:SetSize(w > 0 and w or 1, 1)
  scroll:SetScrollChild(child)
  -- The modern template's MinimalScrollBar stays up with empty arrows when
  -- nothing scrolls (Options Inspector in the capture): hide it then, as
  -- Blizzard's lists do (scrollBarHideIfUnscrollable).
  local bar = modern and type(scroll.ScrollBar) == "table" and scroll.ScrollBar
  -- The bar's arrows and thumb are mouse-only: the right stick scrolls
  -- (SetScrollFrameForFrame) and focus scrolls into view, so the Gamepad UI
  -- never stops on them.
  if type(scroll.ScrollBar) == "table" then UI.MarkIgnored(scroll.ScrollBar) end
  if bar and bar.SetHideIfUnscrollable then
    pcall(bar.SetHideIfUnscrollable, bar, true)
    if bar.Update then pcall(bar.Update, bar) end
  end
  scroll:HookScript("OnSizeChanged", function(self, width) if width and width > 0 then child:SetWidth(width) end end)
  return scroll, child
end

-- Read-only, selectable multi-line text (log, macro code) that fills the
-- parent. box:SetTextIfChanged(text) changes the text only when it differs,
-- so a selection survives refreshes; box:GetText(); box.edit is the EditBox.
function UI.LogBox(parent, font)
  local box, edit
  if UI.Has("ScrollingEditBoxTemplate") then
    box = CreateFrame("Frame", nil, parent, "ScrollingEditBoxTemplate")
    box:SetPoint("TOPLEFT", 6, -6)
    box:SetPoint("BOTTOMRIGHT", -20, 6)
    edit = box.GetEditBox and box:GetEditBox()
    if box.SetInterpolateScroll then pcall(box.SetInterpolateScroll, box, true) end
    if UI.Has("MinimalScrollBar") and ScrollUtil and ScrollUtil.RegisterScrollBoxWithScrollBar and box.GetScrollBox then
      local bar = CreateFrame("EventFrame", nil, parent, "MinimalScrollBar")
      bar:SetPoint("TOPLEFT", box, "TOPRIGHT", 6, 0)
      bar:SetPoint("BOTTOMLEFT", box, "BOTTOMRIGHT", 6, 0)
      pcall(ScrollUtil.RegisterScrollBoxWithScrollBar, box:GetScrollBox(), bar)
      box.ScrollBar = bar
    end
  end
  if not edit then
    if box then box:Hide() end
    box = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    box:SetPoint("TOPLEFT", 6, -6)
    box:SetPoint("BOTTOMRIGHT", -26, 6)
    edit = CreateFrame("EditBox", nil, box)
    edit:SetMultiLine(true)
    local w = parent:GetWidth() - 40
    edit:SetWidth(w > 0 and w or 400)
    box:SetScrollChild(edit)
  end
  edit:SetAutoFocus(false)
  edit:SetFontObject(font or "ChatFontNormal")
  -- Read-only text, scrolled with the right stick (the page's ScrollRegion):
  -- the Gamepad UI never stops on the box or its scroll bar, and A never
  -- hands it the keyboard.
  UI.MarkIgnored(edit)
  if box.ScrollBar then UI.MarkIgnored(box.ScrollBar) end
  edit:HookScript("OnEscapePressed", edit.ClearFocus)
  -- Read-only: undo typing, but allow selecting and copying.
  edit:HookScript("OnTextChanged", function(self, userInput)
    if userInput then self:SetText(box.stored or "") end
  end)
  box.edit = edit
  function box.SetTextIfChanged(self, text)
    text = text or ""
    if self.stored == text then return false end
    self.stored = text
    edit:SetText(text)
    if edit.SetCursorPosition then edit:SetCursorPosition(0) end
    return true
  end
  function box.GetText(self) return self.stored or "" end
  return box
end

-- Confirm dialog ------------------------------------------------------------------

-- Asks text (Yes / No); onAccept runs on Yes. Without StaticPopup it runs
-- right away.
function UI.Confirm(text, onAccept)
  if not (StaticPopupDialogs and StaticPopup_Show) then return onAccept() end
  if not StaticPopupDialogs.AGENTCRAFT_CONFIRM then
    StaticPopupDialogs.AGENTCRAFT_CONFIRM = {
      text = "%s",
      button1 = YES or "Yes",
      button2 = NO or "No",
      OnAccept = function(_, data) if type(data) == "function" then data() end end,
      -- The prompt bar's Yes / No (controller without the Gamepad UI) go back to A / B.
      OnHide = function()
        UI.confirmData = nil
        if UI.RefreshPrompts and C_Timer then C_Timer.After(0, UI.RefreshPrompts) end
      end,
      timeout = 0,
      whileDead = 1,
      hideOnEscape = 1,
      showAlert = 1,
      preferredIndex = 3,
    }
  end
  -- Kept for a controller without the Gamepad UI: pad A answers Yes through
  -- UI.AnswerPopup (UI/Input.lua), which runs it the way OnAccept does.
  UI.confirmData = onAccept
  local dialog = StaticPopup_Show("AGENTCRAFT_CONFIRM", text, nil, onAccept)
  if UI.RefreshPrompts then UI.RefreshPrompts() end
  return dialog
end

-- Empty and error states -----------------------------------------------------------

-- A centred message (GameFontHighlight) with an optional button, covering
-- the parent. Hidden until shown. empty:SetText(text),
-- empty:SetButton(text, onClick) (nil text hides the button).
function UI.Empty(parent, text, buttonText, onClick)
  local f = CreateFrame("Frame", nil, parent)
  f:SetAllPoints()
  f.text = UI.Text(f, text or "", "GameFontHighlight")
  f.text:SetPoint("LEFT", 20, 14)
  f.text:SetPoint("RIGHT", -20, 14)
  f.text:SetJustifyH("CENTER")
  f.button = UI.Button(f, buttonText or "", nil, function() if f.onClick then f.onClick() end end, nil, 26)
  f.button:SetPoint("TOP", f.text, "BOTTOM", 0, -12)
  function f.SetText(self, t) self.text:SetText(t or "") end
  function f.SetButton(self, t, fn)
    self.onClick = fn
    if t then self.button:SetText(t); UI.FitButton(self.button); self.button:Show() else self.button:Hide() end
  end
  f:SetButton(buttonText, onClick)
  f:Hide()
  return f
end

-- Action-slot style icon button ----------------------------------------------
--   slot:SetIcon(texture, faded)   faded must be true to fade (desaturate, 45%)
--   slot:SetKey("s-Q")             key text, top right
--   slot:SetMark(color or nil)     state glow/border (Added green, Missing red, Removed orange)
--   slot:SetEdge(color or nil)     thin coloured outline (Key Bindings: bar/pet/replaces)
--   slot:SetBadge(kind or nil)     "flyout" (corner arrow) or "added" (+)
--   slot:SetState(state)           one of UI.SLOT_STATES (mark/edge/badge in one call)
--   slot:SetTip({ action= | pet= | spellID= | itemID= | title=, text=, color=, lines= })
--   colors: a UI.C colour object or { r, g, b }
local Slot = {}
UI.SlotMethods = Slot
local MODERN_SLOT -- chosen once, on the first UI.Slot

function Slot:SetIcon(tex, faded)
  faded = faded == true
  if tex == "" then tex = nil end
  self.icon:SetTexture(tex)
  self.icon:SetShown(tex ~= nil)
  self.icon:SetDesaturated(faded)
  self.icon:SetAlpha(faded and 0.45 or 1)
end

function Slot:SetKey(text) self.key:SetText(text or "") end

function Slot:SetMark(color)
  if color then
    local r, g, b = UI.RGB(color)
    self.mark:SetVertexColor(r, g, b)
    self.mark:Show()
  else
    self.mark:Hide()
  end
end

function Slot:SetEdge(color) UI.SetBorder(self.edge, color, 0.9) end

function Slot:SetBadge(kind)
  self.flyout:SetShown(kind == "flyout")
  self.plus:SetShown(kind == "added")
end

-- What a tip describes, as { icon, title, kind } for the Inspector header.
function UI.DescribeTip(t, icon)
  if not t then return { icon = icon } end
  local d = { icon = icon, title = t.title }
  if t.action then
    local s = UI.DescribeSlot(t.action)
    d.title, d.icon, d.kind = d.title or s.name, d.icon or s.icon, "Action slot " .. t.action
  elseif t.pet and GetPetActionInfo then
    local name, tex, isToken = GetPetActionInfo(t.pet)
    if isToken then name, tex = _G[name], _G[tex] end
    d.title, d.icon, d.kind = d.title or name, d.icon or tex, "Pet ability"
  elseif t.spellID then
    d.title, d.icon, d.kind = d.title or UI.SpellName(t.spellID), d.icon or UI.SpellIcon(t.spellID), "Spell"
    d.desc = C_Spell and C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(t.spellID)
  elseif t.itemID then
    d.title, d.icon, d.kind = d.title or UI.ItemName(t.itemID), d.icon or UI.ItemIcon(t.itemID), "Item"
  end
  return d
end

-- Default Inspector for a slot: header from its tip and icon, then the tip's
-- text and lines. Pages set slot.acInspect themselves for richer content.
local function SlotInspect(self, pane)
  local t = self.tip
  local d = UI.DescribeTip(t, self.icon:IsShown() and self.icon:GetTexture() or nil)
  pane:Header(d.icon, d.title or (t and t.title) or "Empty", d.kind)
  if t and t.text then pane:Text(t.text, t.color or UI.C.GREEN) end
  if d.desc and d.desc ~= "" then pane:Text(d.desc) end
  for _, line in ipairs(t and t.lines or {}) do
    if type(line) == "table" then pane:Text(line[1], line[2]) else pane:Text(line) end
  end
end

function Slot:SetTip(tip) self.tip = tip end

-- Name under the slot (GameFontHighlightSmall, one line, truncated to the
-- slot width + 16). nil or "" hides it. It sits under the layer pips when
-- the slot shows them.
local function PlaceCaption(self)
  if not self.caption then return end
  self.caption:ClearAllPoints()
  self.caption:SetPoint("TOP", self, "BOTTOM", 0, (self.pipCount or 0) > 0 and -6 or -2)
end
function Slot:SetCaption(text, color)
  if not self.caption then
    local w = self:GetWidth() or 36
    self.caption = UI.Text(self, "", "GameFontHighlightSmall")
    self.caption:SetWidth(math.max(w + 16, 20))
    self.caption:SetJustifyH("CENTER")
    self.caption:SetWordWrap(false)
    self.caption._acCaption = true
    PlaceCaption(self)
  end
  self.caption:SetText(text or "")
  if color then self.caption:SetTextColor(UI.RGB(color)) else self.caption:SetTextColor(1, 1, 1) end
  self.caption:SetShown(text ~= nil and text ~= "")
end

-- n layer pips in a strip just under the icon frame (not on the art); lit
-- (index) is the shown layer, used[i] says the layer holds something.
-- n = 0 hides them. (Keyboard page: Plain / Shift / Ctrl / Alt.) Each pip is a
-- 10x4 bar on a dark 12x6 backing, so it reads on any background.
function Slot:SetPips(n, lit, used)
  self.pips = self.pips or {}
  n = n or 0
  for i = 1, math.max(n, #self.pips) do
    local p = self.pips[i]
    if not p and i <= n then
      p = UI.Flat(self, "OVERLAY", 1, 0.82, 0, 1, 3)
      p:SetSize(10, 4)
      p.back = UI.Flat(self, "OVERLAY", 0, 0, 0, 0.85, 2)
      p.back:SetSize(12, 6)
      p.back:SetPoint("CENTER", p, "CENTER")
      self.pips[i] = p
    end
    if p then
      if i <= n then
        p:ClearAllPoints()
        -- Step 13 for an odd count, 14 for an even one, so every offset is a
        -- whole pixel (4 pips: -21, -7, 7, 21).
        local step = n % 2 == 0 and 14 or 13
        p:SetPoint("TOP", self, "BOTTOM", (i - ((n + 1) / 2)) * step, -1)
        local on = used == nil or (used and used[i])
        if i == lit then p:SetVertexColor(1, 0.82, 0, 1)
        elseif on then p:SetVertexColor(0.85, 0.7, 0.35, 0.8)
        else p:SetVertexColor(0.4, 0.4, 0.4, 0.6) end
        p:Show(); p.back:Show()
      else p:Hide(); p.back:Hide() end
    end
  end
  self.pipCount = n
  PlaceCaption(self)
end

-- One-shot proc flash (ActionButtonSpellAlertTemplate when the client has
-- it, else the icon frame's Flash atlas fading in and out).
function Slot:Flash()
  if UI.Has("ActionButtonSpellAlertTemplate") and not self.procFrame then
    local ok, f = pcall(CreateFrame, "Frame", nil, self, "ActionButtonSpellAlertTemplate")
    if ok and f then
      local w = self:GetWidth() or 36
      f:SetSize(w * 1.4, w * 1.4)
      f:SetPoint("CENTER")
      self.procFrame = f
    end
  end
  local f = self.procFrame
  if f and type(f.ProcStartAnim) == "table" then
    f:Show()
    if type(f.ProcStartFlipbook) == "table" then f.ProcStartFlipbook:Show() end
    f.ProcStartAnim:Play()
    return
  end
  if not self.flashTex then
    self.flashTex = self:CreateTexture(nil, "OVERLAY", nil, 4)
    self.flashTex:SetAllPoints()
    if not UI.SetAtlas(self.flashTex, UI.ART.slotFlash) then self.flashTex:SetTexture("Interface\\Buttons\\UI-QuickslotRed") end
    self.flashTex:SetBlendMode("ADD")
    self.flashTex:SetAlpha(0)
  end
  if UI.Anim and UI.Anim.Blink then UI.Anim.Blink(self.flashTex, 0.35) end
end

-- Pet autocast ants (AutoCastOverlayTemplate), or the corner art fallback.
function Slot:SetAutoCast(on)
  if UI.Has("AutoCastOverlayTemplate") and not self.autoCast then
    local ok, f = pcall(CreateFrame, "Frame", nil, self, "AutoCastOverlayTemplate")
    if ok and f then f:SetAllPoints(); self.autoCast = f end
  end
  local f = self.autoCast
  if f and f.ShowAutoCastEnabled then
    f:SetShown(on and true or false)
    pcall(f.ShowAutoCastEnabled, f, on and true or false)
    return
  end
  if not self.autoTex then
    self.autoTex = self:CreateTexture(nil, "OVERLAY", nil, 3)
    self.autoTex:SetPoint("TOPLEFT", -2, 2)
    self.autoTex:SetPoint("BOTTOMRIGHT", 2, -2)
    if not UI.SetAtlas(self.autoTex, UI.ART.autocast) then
      self.autoTex:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
    end
  end
  self.autoTex:SetShown(on and true or false)
end

function Slot:SetFocusStyle(style) self.acFocusStyle = style end

UI.SLOT_STATES = {
  added = { mark = "ADDED" }, missing = { mark = "MISSING", fade = true }, removed = { mark = "REMOVED", fade = true },
  replaces = { edge = "REPLACES" }, bar = { edge = "BAR" }, pet = { edge = "PET" },
  flyout = { badge = "flyout" }, fixed = { fade = true }, empty = {},
}
function Slot:SetState(state)
  local s = UI.SLOT_STATES[state or "empty"] or {}
  self:SetMark(s.mark and UI.C[s.mark] or nil)
  self:SetEdge(s.edge and UI.C[s.edge] or nil)
  self:SetBadge(s.badge)
  if self.icon:IsShown() then
    self.icon:SetDesaturated(s.fade == true)
    self.icon:SetAlpha(s.fade and 0.45 or 1)
  end
end

local function SlotEnter(self)
  local t = self.tip
  if not t then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  if t.action then GameTooltip:SetAction(t.action)
  elseif t.pet then GameTooltip:SetPetAction(t.pet)
  elseif t.spellID then GameTooltip:SetSpellByID(t.spellID)
  elseif t.itemID then GameTooltip:SetItemByID(t.itemID)
  elseif GameTooltip_SetTitle then GameTooltip_SetTitle(GameTooltip, t.title or "")
  else GameTooltip:SetText(t.title or "", 1, 1, 1) end
  if t.text then
    local r, g, b = UI.RGB(t.color or UI.C.GREEN)
    GameTooltip:AddLine(t.text, r, g, b, true)
  end
  for _, line in ipairs(t.lines or {}) do
    local text, color = line, nil
    if type(line) == "table" then text, color = line[1], line[2] end
    local r, g, b = UI.RGB(color or UI.C.NORMAL)
    GameTooltip:AddLine(text, r, g, b, true)
  end
  GameTooltip:Show()
end

function UI.Slot(parent, size)
  if MODERN_SLOT == nil then
    MODERN_SLOT = UI.HasAtlas("UI-HUD-ActionBar-IconFrame") and UI.HasAtlas("UI-HUD-ActionBar-IconFrame-Mask")
  end
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size, size)
  Mixin(b, Slot)

  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetAllPoints()
  b.icon:Hide() -- shown by SetIcon with a texture; an empty slot draws no blank icon
  if MODERN_SLOT then
    b.bg = b:CreateTexture(nil, "BACKGROUND")
    b.bg:SetAllPoints()
    b.bg:SetAtlas(UI.HasAtlas("ui-hud-actionbar-iconframe-slot") and "ui-hud-actionbar-iconframe-slot" or "UI-HUD-ActionBar-IconFrame")
    local mask = b:CreateMaskTexture(nil, "ARTWORK")
    mask:SetAllPoints(b.icon)
    mask:SetAtlas("UI-HUD-ActionBar-IconFrame-Mask")
    b.icon:AddMaskTexture(mask)
    b.iconMask = mask
    b.frameArt = b:CreateTexture(nil, "ARTWORK", nil, 2)
    b.frameArt:SetAllPoints()
    b.frameArt:SetAtlas("UI-HUD-ActionBar-IconFrame")
    b.mark = b:CreateTexture(nil, "OVERLAY")
    b.mark:SetAllPoints()
    b.mark:SetAtlas(UI.HasAtlas("UI-HUD-ActionBar-IconFrame-Border") and "UI-HUD-ActionBar-IconFrame-Border" or "UI-HUD-ActionBar-IconFrame")
    b.mark:SetBlendMode("ADD")
    if UI.HasAtlas("UI-HUD-ActionBar-IconFrame-Mouseover") then b:SetHighlightAtlas("UI-HUD-ActionBar-IconFrame-Mouseover", "ADD") end
    if UI.HasAtlas("UI-HUD-ActionBar-IconFrame-Down") then b:SetPushedAtlas("UI-HUD-ActionBar-IconFrame-Down") end
  else
    b.bg = UI.Fill(b, 0, 0, 0, 0.55)
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    b.frameArt = b:CreateTexture(nil, "ARTWORK", nil, 2)
    b.frameArt:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    b.frameArt:SetSize(size * 66 / 36, size * 66 / 36)
    b.frameArt:SetPoint("CENTER", 0, -1)
    b.mark = b:CreateTexture(nil, "OVERLAY")
    b.mark:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    b.mark:SetBlendMode("ADD")
    b.mark:SetSize(size * 1.75, size * 1.75)
    b.mark:SetPoint("CENTER")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
  end
  b.mark:Hide()

  b.edge = UI.Border(b, 1, 1, 1, 0, "OVERLAY")
  UI.SetBorder(b.edge, nil)

  b.flyout = b:CreateTexture(nil, "OVERLAY", nil, 2)
  b.flyout:SetSize(12, 12)
  b.flyout:SetPoint("TOPRIGHT", -1, -1)
  if UI.HasAtlas("UI-HUD-ActionBar-Flyout") then b.flyout:SetAtlas("UI-HUD-ActionBar-Flyout")
  else b.flyout:SetTexture("Interface\\Buttons\\Arrow-Up-Up") end
  b.flyout:Hide()
  b.plus = UI.Text(b, "+", "GameFontGreenSmall")
  b.plus:SetPoint("TOPLEFT", 2, -1)
  b.plus:Hide()

  b.key = UI.Text(b, "", size >= 40 and "NumberFontNormal" or "NumberFontNormalSmall")
  b.key:SetPoint("TOPRIGHT", -2, -3)
  b.key:SetWidth(math.max(size - 4, 1))
  b.key:SetJustifyH("RIGHT")
  b.key:SetWordWrap(false)
  b.center = UI.Text(b, "", "GameFontHighlightSmall")
  b.center:SetPoint("CENTER")

  b:SetScript("OnEnter", SlotEnter)
  b:SetScript("OnLeave", GameTooltip_Hide)
  b.acTip = SlotEnter
  b.acInspect = SlotInspect
  UI.Node(b, { style = "slot" })
  return b
end

-- Legends ---------------------------------------------------------------------------

local LEGEND_ICON = "Interface\\Icons\\INV_Misc_Book_09"

-- An 18px slot drawn in `state` (see UI.SLOT_STATES) plus a label: the
-- legend shows exactly what it describes. Returns a frame sized to fit;
-- chain several with SetPoint("LEFT", previous, "RIGHT", 12, 0).
function UI.LegendItem(parent, state, text)
  local f = CreateFrame("Frame", nil, parent)
  local slot = UI.Slot(f, 18)
  slot:SetPoint("LEFT")
  slot:EnableMouse(false)
  slot.acSkip = true -- decorative: not a focus target
  if state ~= "empty" then slot:SetIcon(state == "missing" and UI.QUESTION or LEGEND_ICON) else slot:SetIcon(nil) end
  slot:SetState(state)
  f.slot = slot
  f.label = UI.Text(f, text, "GameFontHighlight")
  f.label:SetPoint("LEFT", slot, "RIGHT", 5, 0)
  f:SetSize(18 + 5 + f.label:GetStringWidth(), 20)
  UI.MarkIgnored(f)
  return f
end

-- Small coloured square + label, for legends (deprecated: use UI.LegendItem).
function UI.Swatch(parent, color, text)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(10, 10)
  local r, g, b = UI.RGB(color)
  UI.Fill(f, r, g, b, 0.9, "ARTWORK")
  local fs = UI.Text(f, text, "GameFontHighlightSmall")
  fs:SetPoint("LEFT", f, "RIGHT", 5, 0)
  f.label = fs
  return f
end

-- Section headers ------------------------------------------------------------------

-- White section title (GameFontHighlightMedium) with a divider under it.
--   UI.Header(parent, text, x, y, width, opts)   or   UI.Header(parent, text, x, y, opts)
--   width defaults to the parent's width minus x (590 if unknown)
--   opts.hint  adds an (i) button after the title with this tooltip
-- Returns the font string (fs.rule = divider, fs.hint = hint button). The
-- header is 18px tall: put the next row at y - 24.
function UI.Header(parent, text, x, y, width, opts)
  if type(width) == "table" then width, opts = nil, width end
  x, y = x or 0, y or 0
  if not width then
    local pw = parent:GetWidth() or 0
    width = pw > x and (pw - x) or 590
  end
  local fs = UI.Text(parent, text, "GameFontHighlightMedium")
  fs:SetPoint("TOPLEFT", x, y)
  fs:SetJustifyH("LEFT")
  -- v2: the character sheet's section title plate (UI-Character-Info-Title)
  -- behind the text; the old divider rule only as a fallback. opts.hint is
  -- kept in the signature but no longer draws an (i) button: the Inspector
  -- explains the focused element instead.
  local rule = parent:CreateTexture(nil, "BACKGROUND", nil, 1)
  if UI.SetAtlas(rule, UI.ART.title, true) then
    -- At the plate's own height (196x40 in CharacterFrame), centred on the
    -- text line; wider only when the text needs it. Kept inside the parent.
    local _, ah = UI.AtlasSize(UI.FirstAtlas(UI.ART.title))
    ah = ah or 40
    local tw = math.ceil(fs:GetStringWidth() or 0) + 48
    if tw > (rule:GetWidth() or 0) then rule:SetWidth(math.min(tw, math.max(width, 1))) end
    local top = math.min(y + (ah - 18) / 2, 0)
    rule:SetPoint("TOPLEFT", parent, "TOPLEFT", math.max(x - 16, 0), math.floor(top))
  else
    rule:SetTexture(UI.WHITE)
    rule:SetVertexColor(0.9, 0.62, 0.32, 0.6)
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -3)
    rule:SetWidth(width)
  end
  fs.rule = rule
  fs.hintText = opts and opts.hint
  return fs
end
