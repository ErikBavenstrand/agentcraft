-- Sound, the little motion Blizzard's own panels allow, and the focus ring
-- (dev/ui-rules.md "Motion"; it overrides dev/ui-spec-v2.md §6.6-6.8).
--   UI.Sound(key)           a role ("open", "focus", ...) or a SOUNDKIT key
--   UI.HasAnim(), UI.Reduced()
--   UI.Anim.FadeIn/FadeOut  short fades (<= 0.15 s) for toasts and glows only
--   UI.Anim.Pulse/Blink     glow and flash textures only
--   UI.Anim.Stop(region)    stops every UI.Anim group on region, alpha 1
--   UI.Anim.SlideIn/Squish/Bump/Drift/Cascade  no-op shims (kept so old calls
--                           still work): windows, pages, panels, toasts and
--                           rows never slide, bump, squish, drift or cascade
--   UI.FocusRing            the one ring that marks the focused node
-- Blizzard's panels (CharacterFrame, SettingsPanel) have no AnimationGroup:
-- they show and hide instantly, with a sound. The Options "motion" setting is
-- kept as a harmless key; UI.Reduced() is always true.
local _, ns = ...
local UI = ns.UI

-- Sound ------------------------------------------------------------------------------
-- IDs: https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Mainline/SoundKitConstants.lua
local SOUNDS = {
  open = { "IG_CHARACTER_INFO_OPEN" },
  close = { "IG_CHARACTER_INFO_CLOSE" },
  tab = { "IG_CHARACTER_INFO_TAB" },
  focus = { "GAMEPAD_RADIAL_MENU_HIGHLIGHT", "U_CHAT_SCROLL_BUTTON" },
  view = { "GAMEPAD_RADIAL_MENU_TAB_OVER", "UI_CLASS_TALENT_TAB" },
  activate = { "IG_MAINMENU_OPTION" },
  on = { "IG_MAINMENU_OPTION_CHECKBOX_ON" },
  off = { "IG_MAINMENU_OPTION_CHECKBOX_OFF" },
  review = { "UI_CLASS_TALENT_APPLY_CHANGES" },
  applied = { "UI_CLASS_TALENT_APPLY_COMPLETE", "GS_TITLE_OPTION_OK" },
  installed = { "UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST", "UI_CLASS_TALENT_LEARN_TALENT" },
  page = { "IG_ABILITY_PAGE_TURN" },
}
UI.SOUNDS = SOUNDS

local lastFocusSound = 0
function UI.Sound(key)
  if ns.Setting and ns.Setting("sound") == false then return end
  if not (PlaySound and SOUNDKIT) then return end
  if key == "focus" then
    local now = GetTime and GetTime() or 0
    if now - lastFocusSound < 0.06 then return end
    lastFocusSound = now
  end
  for _, name in ipairs(SOUNDS[key] or { key }) do
    local id = rawget(SOUNDKIT, name)
    if type(id) == "number" then pcall(PlaySound, id) return true end
  end
end

-- Animation --------------------------------------------------------------------------

local MAX_FADE = 0.15

function UI.HasAnim() return UIParent and UIParent.CreateAnimationGroup ~= nil end
-- Always true: there is no "full" motion any more (dev/ui-rules.md rule 1).
-- Callers that branch on it take the instant path.
function UI.Reduced() return true end

local Anim = {}
UI.Anim = Anim

local GROUPS = { "_acFadeIn", "_acFadeOut", "_acPulse", "_acBlink" }

local function Group(region, key)
  if not (region and region.CreateAnimationGroup) then return nil end
  local g = region[key]
  if not g then
    g = region:CreateAnimationGroup()
    region[key] = g
  end
  g:Stop()
  return g
end

local function AddAnim(g, kind, key)
  g._acAnims = g._acAnims or {}
  local a = g._acAnims[key]
  if not a then
    local ok, made = pcall(g.CreateAnimation, g, kind)
    if not ok then return nil end
    a = made
    g._acAnims[key] = a
  end
  return a
end

-- Stops every UI.Anim group on region and leaves it at alpha 1. A toast that
-- shows again while it is still fading out must not be hidden by the fade.
function Anim.Stop(region)
  if not region then return end
  for _, key in ipairs(GROUPS) do
    local g = rawget(region, key)
    if g and g.Stop then
      if g.SetScript then g:SetScript("OnFinished", nil) end
      g:Stop()
    end
  end
  region:SetAlpha(1)
end

-- Shows region at its final state: the shims below end here.
local function Settle(region)
  if not region then return end
  Anim.Stop(region)
  region:Show()
end

-- Fades region from `from` (default 0) to 1 over at most 0.15 s and shows it.
-- Only for small transient elements (toasts, glows), never a window or page.
function Anim.FadeIn(region, dur, from)
  if not region then return end
  local g = UI.HasAnim() and Group(region, "_acFadeIn")
  local a = g and AddAnim(g, "Alpha", "a")
  if rawget(region, "_acFadeOut") then rawget(region, "_acFadeOut"):Stop() end
  region:Show()
  if not a then region:SetAlpha(1) return end
  a:SetFromAlpha(from or 0)
  a:SetToAlpha(1)
  a:SetDuration(math.min(dur or MAX_FADE, MAX_FADE))
  if a.SetSmoothing then a:SetSmoothing("OUT") end
  g:SetToFinalAlpha(true)
  g:SetScript("OnFinished", function() region:SetAlpha(1) end)
  g:Play()
end

-- Fades out over at most 0.15 s, then hides and runs onDone.
function Anim.FadeOut(region, dur, onDone)
  if not region then return end
  if rawget(region, "_acFadeIn") then rawget(region, "_acFadeIn"):Stop() end
  local g = UI.HasAnim() and Group(region, "_acFadeOut")
  local a = g and AddAnim(g, "Alpha", "a")
  local function done() region:Hide(); region:SetAlpha(1); if onDone then onDone() end end
  if not a then return done() end
  a:SetFromAlpha(region:GetAlpha() or 1)
  a:SetToAlpha(0)
  a:SetDuration(math.min(dur or MAX_FADE, MAX_FADE))
  g:SetToFinalAlpha(true)
  g:SetScript("OnFinished", done)
  g:Play()
end

-- No-op shims: the region ends shown, at alpha 1, at its anchored place and
-- scale. Kept so callers in other files keep working.
function Anim.SlideIn(region) Settle(region) end
function Anim.Squish() end
function Anim.Bump() end
function Anim.Drift() end
-- Proc cascades are not used (dev/ui-rules.md rule 4). Returns 0.
function Anim.Cascade() return 0 end

-- Looping alpha pulse between from and to (BOUNCE), for a glow texture only
-- (Blizzard's tab glow). Returns the group, or nil. Stop it with group:Stop().
function Anim.Pulse(region, from, to, dur)
  if not region then return end
  if not UI.HasAnim() then region:SetAlpha(to or 1) return nil end
  local g = Group(region, "_acPulse")
  local a = g and AddAnim(g, "Alpha", "a")
  if not a then region:SetAlpha(to or 1) return nil end
  a:SetFromAlpha(from or 0.55)
  a:SetToAlpha(to or 1)
  a:SetDuration(dur or 0.9)
  g:SetLooping("BOUNCE")
  g:Play()
  return g
end

-- One-shot flash of a glow/flash texture (an ADD-blended highlight, never a
-- frame that holds content): alpha 0 -> 1 -> 0, at most 0.3 s in all. This is
-- the short highlight intro rule 3 allows, so it plays with reduced motion
-- too (UI.Reduced() is always true now); nothing moves or scales.
function Anim.Blink(region, dur)
  if not region then return end
  region:Show()
  local half = math.min(dur or 0.3, 0.3) / 2
  local g = UI.HasAnim() and Group(region, "_acBlink")
  local a = g and AddAnim(g, "Alpha", "in")
  local b = g and AddAnim(g, "Alpha", "out")
  if not (a and b) then region:SetAlpha(0) return end
  a:SetFromAlpha(0); a:SetToAlpha(1); a:SetDuration(half); a:SetOrder(1)
  b:SetFromAlpha(1); b:SetToAlpha(0); b:SetDuration(half); b:SetOrder(2)
  g:SetToFinalAlpha(true)
  g:SetScript("OnFinished", function() region:SetAlpha(0) end)
  g:Play()
end

-- Focus ring --------------------------------------------------------------------------
-- One frame, made once, re-anchored only when the focused node changes. Its
-- art follows node.acFocusStyle. The glow texture fades in over 0.15 s on a
-- new node (as Blizzard's ActionBarFocusFX); the frame itself never moves,
-- scales or pulses, and a Refresh that keeps the focus leaves it alone.

local Ring = {}
UI.FocusRing = Ring

local OUTSET = { slot = 3, square = 5, circle = 5, row = 0, card = 2, button = 2, chip = 1 }
local INTRO = 0.15

local function Build(host)
  local f = CreateFrame("Frame", nil, host)
  f:SetFrameStrata("HIGH")
  f:EnableMouse(false)
  f:Hide()
  f.glow = f:CreateTexture(nil, "OVERLAY", nil, 1)
  f.glow:SetAllPoints()
  f.glow:SetBlendMode("ADD")
  f.edge = f:CreateTexture(nil, "OVERLAY", nil, 2)
  f.edge:SetAllPoints()
  -- Bronze bar at the left edge of a focused row (our own 2px art).
  f.bar = UI.Flat(f, "OVERLAY", 0.9, 0.62, 0.32, 0.95, 3)
  f.bar:SetPoint("TOPLEFT")
  f.bar:SetPoint("BOTTOMLEFT")
  f.bar:SetWidth(2)
  -- A copy of the focused key's hotkey letter, drawn above the ring's glow
  -- so the key you are on is the one whose letter stays readable.
  f.hotkey = f:CreateFontString(nil, "OVERLAY", nil, 7)
  f.hotkey:SetFontObject("NumberFontNormal")
  f.hotkey:SetJustifyH("RIGHT")
  if f.hotkey.SetShadowColor then f.hotkey:SetShadowColor(0, 0, 0, 1) end
  if f.hotkey.SetShadowOffset then f.hotkey:SetShadowOffset(1, -1) end
  f.hotkey:Hide()
  UI.MarkIgnored(f)
  f.acSkip = true
  if UI.PixelSnap then UI.PixelSnap(f) end
  return f
end

-- Mirrors the slot's hotkey text; re-anchors only when the key frame changes.
local function MirrorHotkey(f, node, style)
  local k = node.key
  local text = style == "slot" and type(k) == "table" and k.GetText and k:GetText()
  if not text or text == "" or (k.IsShown and not k:IsShown()) then f.hotkey:Hide() return end
  if f.hotkeyFor ~= k then
    if k.GetFontObject and k:GetFontObject() then f.hotkey:SetFontObject(k:GetFontObject()) end
    f.hotkey:ClearAllPoints()
    f.hotkey:SetPoint("TOPRIGHT", k, "TOPRIGHT")
    f.hotkeyFor = k
  end
  if f.hotkey:GetText() ~= text then f.hotkey:SetText(text) end
  if k.GetTextColor then f.hotkey:SetTextColor(k:GetTextColor()) end
  f.hotkey:Show()
end

local function Art(f, style)
  f.glow:Show(); f.edge:Show(); f.bar:Hide()
  f.glowAlpha = 1
  f.edge:SetAlpha(1)
  if style == "square" or style == "circle" then
    if not UI.SetAtlas(f.glow, style == "square" and UI.ART.padSquareGlow or UI.ART.padCircleGlow) then f.glow:Hide() end
    -- The focused-frame edge is square art: on a circle slot it drew a square
    -- box over the face-button glyph (capture s14/s24). Circles get only
    -- their round glow.
    if style == "circle" or not UI.SetAtlas(f.edge, UI.ART.padFocus) then f.edge:Hide() end
  elseif style == "row" then
    if not UI.SetAtlas(f.glow, UI.ART.rowHover) then f.glow:Hide() end
    f.edge:Hide()
    f.bar:Show()
  elseif style == "card" then
    if not UI.SetAtlas(f.glow, UI.ART.cardHover) then f.glow:Hide() end
    f.edge:Hide()
  elseif style == "button" or style == "chip" then
    if not UI.SetAtlas(f.glow, UI.ART.rowHover) then f.glow:Hide() end
    f.glowAlpha = 0.6
    f.edge:Hide()
  else -- slot
    if not UI.SetAtlas(f.glow, "UI-HUD-ActionBar-IconFrame-Mouseover") then f.glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square") end
    f.edge:Hide()
  end
  f.glow:SetAlpha(f.glowAlpha)
end

-- The glow's short intro on a new node (alpha only, glow texture only).
local function Intro(f)
  local tex = f.glow
  if not (UI.HasAnim() and tex:IsShown() and tex.CreateAnimationGroup) then return end
  -- A held D-pad moves every 0.08 s: the ring then just follows, at full
  -- alpha, instead of fading in again on every step.
  local now = GetTime and GetTime() or 0
  local rapid = f.lastIntro and now - f.lastIntro < 0.25
  f.lastIntro = now
  if rapid then
    if f.intro then f.intro:Stop() end
    tex:SetAlpha(f.glowAlpha or 1)
    return
  end
  local g = f.intro
  if not g then
    g = tex:CreateAnimationGroup()
    local ok, a = pcall(g.CreateAnimation, g, "Alpha")
    if not ok then return end
    a:SetFromAlpha(0)
    a:SetDuration(INTRO)
    if a.SetSmoothing then a:SetSmoothing("OUT") end
    g.alpha = a
    g:SetToFinalAlpha(true)
    f.intro = g
  end
  g:Stop()
  g.alpha:SetToAlpha(f.glowAlpha or 1)
  g:SetScript("OnFinished", function() tex:SetAlpha(f.glowAlpha or 1) end)
  g:Play()
end

function Ring:SetHost(host) self.host = host end

function Ring:Attach(node)
  if not node or not self.host then return self:Hide() end
  if not self.frame then self.frame = Build(self.host) end
  local f = self.frame
  local style = node.acFocusStyle or "button"
  -- Same node, same style: nothing to move (Focus:Validate calls this after
  -- every Refresh). Only the hotkey text may have changed.
  if node == self.node and style == f.style and f:IsShown() then
    MirrorHotkey(f, node, style)
    return
  end
  local o = OUTSET[style] or 2
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", node, "TOPLEFT", -o, o)
  f:SetPoint("BOTTOMRIGHT", node, "BOTTOMRIGHT", o, -o)
  if f.style ~= style then Art(f, style); f.style = style end
  MirrorHotkey(f, node, style)
  f:Show()
  self.node = node
  Intro(f)
end

function Ring:Hide()
  if self.frame then
    if self.frame.intro then self.frame.intro:Stop() end
    self.frame:Hide()
  end
  self.node = nil
end
