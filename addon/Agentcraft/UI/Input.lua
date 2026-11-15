-- One focus, three inputs (dev/ui-spec-v2.md §4-5).
--
--   ns.Focus   the single focus shared by mouse, keyboard and controller:
--              Set, Move, Activate, Restore, Validate, HandleKey, Pin, zones
--   ns.Esc     the Back/Escape layer stack: Push, Remove, Pop, Back, Clear
--   ns.Input   window glue: override bindings (chords, pad), keyboard
--              propagation, combat safety, SmartNavigation sync
--   UI.GlyphAtlas / UI.GlyphMarkup / UI.PromptMode / UI.PadMode /
--   UI.RefreshPrompts / UI.KeyLabel   button prompt glyphs
--
-- Nothing here writes Blizzard tables or methods. Override bindings are owned
-- by the window frame, set only out of combat while it is shown, and cleared
-- on hide and when combat starts (a hide during combat clears them after).
local _, ns = ...
local UI = ns.UI

local Focus = { zones = { "view", "stage", "inspector", "prompts" } }
local Esc = { stack = {} }
local Input = { handlers = {} }
ns.Focus, ns.Esc, ns.Input = Focus, Esc, Input

local function InCombat() return InCombatLockdown and InCombatLockdown() end
local function After(t, fn) if C_Timer and C_Timer.After then C_Timer.After(t, fn) else fn() end end

-- Glyphs ------------------------------------------------------------------------------
-- Atlas names: InputIconTexture.lua (Forever) and the client atlas table.
-- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/InputIcons/InputIconTexture.lua
-- Each list: the Forever name with drop shadow first, then the "-flat" name
-- both clients have.
local function X(base) return { "gamepad-xbox1-" .. base .. "-normal", "gamepad-xbox1-" .. base .. "-flat-normal" } end
UI.GLYPH_FALLBACK = {
  PAD1 = X("buttona"), PAD2 = X("buttonb"), PAD3 = X("buttonx"), PAD4 = X("buttony"),
  PADLSHOULDER = X("trigger-lb"), PADRSHOULDER = X("trigger-rb"),
  PADLTRIGGER = X("trigger-lt"), PADRTRIGGER = X("trigger-rt"),
  PADDUP = X("dpadup"), PADDDOWN = X("dpaddown"), PADDLEFT = X("dpadleft"), PADDRIGHT = X("dpadright"),
  PADDPAD = X("dpadall"),
}
-- The D-pad keys first try the single-direction shields ("donly"): a bold
-- white arrow that stays legible at 22 px, where the full-cross "dpad" art
-- lights only a 5 px arm tip. Same sheet (file 8281847), UiTextureAtlasMember
-- 41414 donlyup, 41399 donlydown, 41404 donlyleft, 41409 donlyright:
-- https://wago.tools/db2/UiTextureAtlasMember
for key, dir in pairs({ PADDUP = "up", PADDDOWN = "down", PADDLEFT = "left", PADDRIGHT = "right" }) do
  table.insert(UI.GLYPH_FALLBACK[key], 1, "gamepad-xbox1-donly" .. dir .. "-flat-normal")
end
local DPAD_KEYS = { PADDUP = true, PADDDOWN = true, PADDLEFT = true, PADDRIGHT = true, PADDPAD = true }
UI.GLYPH_SHAPES = {
  PAD1 = { "gamepad-ps-buttoncrox-normal", "gamepad-ps-32x-x" },
  PAD2 = { "gamepad-ps-buttoncircle-normal", "gamepad-ps-32x-circle" },
  PAD3 = { "gamepad-ps-buttonsquare-normal", "gamepad-ps-32x-square" },
  PAD4 = { "gamepad-ps-buttontriangle-normal", "gamepad-ps-32x-triangle" },
  PADLSHOULDER = { "gamepad-ps-triggerl1-normal", "gamepad-ps-32x-l1" },
  PADRSHOULDER = { "gamepad-ps-triggerr1-normal", "gamepad-ps-32x-r1" },
  PADLTRIGGER = { "gamepad-ps-triggerl2-normal", "gamepad-ps-32x-l2" },
  PADRTRIGGER = { "gamepad-ps-triggerr2-normal", "gamepad-ps-32x-r2" },
  PADDUP = { "gamepad-ps-dpadup-normal", "gamepad-ps-32x-dpad-up" },
  PADDDOWN = { "gamepad-ps-dpaddown-normal", "gamepad-ps-32x-dpad-down" },
  PADDLEFT = { "gamepad-ps-dpadleft-normal", "gamepad-ps-32x-dpad-left" },
  PADDRIGHT = { "gamepad-ps-dpadright-normal", "gamepad-ps-32x-dpad-right" },
}
-- Short names for text and for the layout's "RT A" keys.
UI.PAD_NAMES = { PAD1 = "A", PAD2 = "B", PAD3 = "X", PAD4 = "Y", PADLSHOULDER = "LB", PADRSHOULDER = "RB",
  PADLTRIGGER = "LT", PADRTRIGGER = "RT", PADDUP = "Up", PADDDOWN = "Down", PADDLEFT = "Left", PADDRIGHT = "Right",
  F13 = "L4", F14 = "L5", F15 = "R4", F16 = "R5" }
-- "A", "Up", "LT" ... -> PAD key.
-- PlayStation names too, for text written in the Shapes style ("L2 + Cross").
UI.PAD_KEYS = { A = "PAD1", B = "PAD2", X = "PAD3", Y = "PAD4", LB = "PADLSHOULDER", RB = "PADRSHOULDER",
  LT = "PADLTRIGGER", RT = "PADRTRIGGER", Up = "PADDUP", Down = "PADDDOWN", Left = "PADDLEFT", Right = "PADDRIGHT",
  Cross = "PAD1", Circle = "PAD2", Square = "PAD3", Triangle = "PAD4", L1 = "PADLSHOULDER", R1 = "PADRSHOULDER",
  L2 = "PADLTRIGGER", R2 = "PADRTRIGGER" }
-- Keyboard prompt text for each pad key (§5.2).
UI.KEY_TEXT = { PAD1 = "Enter", PAD2 = "Esc", PAD3 = "Ctrl+Space", PAD4 = "Ctrl+Enter",
  PADLSHOULDER = "Ctrl+Shift+Tab", PADRSHOULDER = "Ctrl+Tab", PADDUP = "Up", PADDDOWN = "Down",
  PADDLEFT = "Left", PADDRIGHT = "Right", PADLTRIGGER = "Shift", PADRTRIGGER = "Ctrl" }

-- "Letters", "Shapes" or "Reverse" for the active controller, or nil.
function UI.LabelStyle()
  if not (C_GamePad and C_GamePad.GetDeviceMappedState) then return nil end
  local ok, state = pcall(function()
    local id = C_GamePad.GetActiveDeviceID and C_GamePad.GetActiveDeviceID()
    return C_GamePad.GetDeviceMappedState(id)
  end)
  if not ok or type(state) ~= "table" then return nil end
  local s = state.labelStyle
  if Enum and Enum.GamePadLabelStyle and type(s) == "number" then
    for name, v in pairs(Enum.GamePadLabelStyle) do if v == s then return name end end
  end
  return type(s) == "string" and s or nil
end

-- The client's icon-set utility atlas for a key, or nil.
local function UtilAtlas(key)
  local util = InputIconTextureSetUtility
  if type(util) ~= "table" or not util.GetNormalActiveInputIconButtonTexture then return nil end
  local ok, a = pcall(util.GetNormalActiveInputIconButtonTexture, key)
  return ok and type(a) == "string" and a or nil
end

-- The glyph set for the whole controller ("Shapes" or "Letters"), worked out
-- from PAD1 (or the mapped label style) so every key, D-pad included, uses
-- the same set.
function UI.GlyphStyle()
  local a = UtilAtlas("PAD1")
  if a and a:find("%-ps%-") then return "Shapes" end
  return UI.LabelStyle() == "Shapes" and "Shapes" or "Letters"
end

-- The glyph atlas for a pad key ("PAD1", "PADLSHOULDER", ...), or nil.
function UI.GlyphAtlas(key)
  if not key then return nil end
  local style = UI.GlyphStyle()
  -- D-pad on Letters: the single-direction shields beat the utility's
  -- full-cross art.
  if DPAD_KEYS[key] and style ~= "Shapes" then
    local a = UI.FirstAtlas(UI.GLYPH_FALLBACK[key])
    if a then return a end
  end
  local u = UtilAtlas(key)
  if u and (style ~= "Shapes" or u:find("%-ps%-")) then
    if UI.HasAtlas(u) then return u end
    local flat = u:gsub("%-normal$", "-flat-normal")
    if UI.HasAtlas(flat) then return flat end
  end
  if style == "Shapes" then
    local a = UI.FirstAtlas(UI.GLYPH_SHAPES[key])
    if a then return a end
  end
  return UI.FirstAtlas(UI.GLYPH_FALLBACK[key])
end

-- The text a key prompt shows in keyboard mode.
function UI.KeyLabel(key) return UI.KEY_TEXT[key] or UI.PAD_NAMES[key] or tostring(key or "") end

-- Inline glyph for a font string, or "[A]" without the atlas.
function UI.GlyphMarkup(key, size)
  local a = UI.GlyphAtlas(key)
  if a and CreateAtlasMarkup then return CreateAtlasMarkup(a, size or 18, size or 18) end
  return "[" .. (UI.PAD_NAMES[key] or tostring(key)) .. "]"
end

-- Prompt mode: "pad", "keyboard" or "mouse" (Options › Button prompts;
-- "auto" follows the Gamepad UI, then the last device used).
UI.lastDevice = nil
function UI.PromptMode()
  local s = ns.Setting and ns.Setting("prompts") or "auto"
  if s == "pad" or s == "keyboard" then return s end
  if UI.GamepadUI() then return "pad" end
  return UI.lastDevice or "mouse"
end
function UI.PadMode() return UI.PromptMode() == "pad" end

function UI.NoteDevice(d)
  if d == UI.lastDevice then return end
  UI.lastDevice = d
  UI.RefreshPrompts()
end

-- Re-skins every UI.Glyph and tells the window to re-flow its prompt bar.
UI.glyphs = setmetatable({}, { __mode = "k" })
function UI.RefreshPrompts()
  for g in pairs(UI.glyphs) do
    if g.Refresh then pcall(g.Refresh, g) end
  end
  if Input.onPrompts then pcall(Input.onPrompts) end
end

-- Escape / Back layer stack -------------------------------------------------------------
-- Push(closeFn, tag): a layer that Back closes (Review sheet, sub-view,
-- pinned Inspector, keyboard engaged mode). Pop() closes the top layer, or
-- asks the page (page:Back()), and says whether anything closed.

function Esc.Push(fn, tag)
  if tag then Esc.Remove(tag) end
  table.insert(Esc.stack, { fn = fn, tag = tag })
  return tag
end

function Esc.Remove(tag)
  for i = #Esc.stack, 1, -1 do
    if Esc.stack[i].tag == tag then table.remove(Esc.stack, i) end
  end
end

function Esc.Has(tag)
  for _, e in ipairs(Esc.stack) do if e.tag == tag then return true end end
  return false
end

-- Pop order follows the layer, not the push order (spec §4.4): the Review
-- sheet, then a sub-view (any other tag), then a pin, then keyboard engaged
-- mode; the newest layer wins among equals. So Esc in the Review sheet closes
-- the sheet even though Tab engaged the keyboard after it opened.
-- fromPad: the keyboard 'engaged' layer is not a layer for a controller,
-- so it is dropped silently and Back goes on to the page or the close.
local RANK = { review = 1, pin = 3, engaged = 4 }
function Esc.Pop(fromPad)
  local best, bestRank
  for i = #Esc.stack, 1, -1 do
    local tag = Esc.stack[i].tag
    local r = RANK[tag] or 2
    if not (fromPad and tag == "engaged") and (not bestRank or r < bestRank) then best, bestRank = i, r end
  end
  if fromPad and not best and Esc.Has("engaged") then
    if Focus.engaged then Focus:Disengage() else Esc.Remove("engaged") end
  end
  local e = best and table.remove(Esc.stack, best)
  if e then
    local ok, err = pcall(e.fn)
    if not ok and ns.LogLine then ns.LogLine("Back: " .. tostring(err)) end
    return true
  end
  local page = Focus.getPage and Focus.getPage()
  if page and page.Back then
    local ok, popped = pcall(page.Back, page)
    if ok and popped then return true end
  end
  -- Every page: Back from inside the Inspector returns to what it explains
  -- (the slot, key or card), never straight to closing the window.
  local target = Esc.InspectorBackTarget()
  if target then
    Focus:Set(target, Focus.source == "mouse" and "key" or Focus.source)
    return true
  end
  return false
end

-- The node Back from the Inspector returns to, or nil when focus is not in
-- the Inspector (or what it explains is gone).
function Esc.InspectorBackTarget()
  local cur, t = Focus.current, Focus.inspected
  if not (cur and Focus.ZoneOf and Focus.ZoneOf(cur) == "inspector") then return nil end
  if not t or t == cur or not (Focus.Usable and Focus.Usable(t)) or Focus.ZoneOf(t) == "inspector" then return nil end
  return t
end

-- Says whether Back would close a layer (not counting keyboard engaged mode).
function Esc.HasLayers()
  for _, e in ipairs(Esc.stack) do if e.tag ~= "engaged" then return true end end
  return false
end

-- Says whether B / Esc goes back (a layer, the page's own Back, or out of
-- the Inspector) instead of closing the window: the prompt bar's B label.
function Esc.CanBack()
  if Esc.HasLayers() then return true end
  local page = Focus.getPage and Focus.getPage()
  if page and page.CanBack then
    local ok, can = pcall(page.CanBack, page)
    if ok and can then return true end
  end
  return Esc.InspectorBackTarget() ~= nil
end

-- Back from the pad: pop a layer, else close the window.
function Esc.Back()
  if Esc.Pop(true) then return true end
  if Input.handlers.close then Input.handlers.close() end
  return false
end

-- Clears every layer except the ones whose tag is in keep ({ engaged = true }).
function Esc.Clear(keep)
  for i = #Esc.stack, 1, -1 do
    local t = Esc.stack[i].tag
    if not (keep and t and keep[t]) then table.remove(Esc.stack, i) end
  end
end

-- Focus core ----------------------------------------------------------------------------

Focus.modal = {}

function Focus:SetHost(host, getPage)
  self.host, self.getPage = host, getPage
  UI.FocusRing:SetHost(host)
end

function Focus:Root() return self.modal[#self.modal] or self.host end

-- A modal layer (Review sheet): focus stays inside root until PopModal.
function Focus:PushModal(root)
  table.insert(self.modal, root)
  self:Restore()
end
function Focus:PopModal(root)
  for i = #self.modal, 1, -1 do if self.modal[i] == root then table.remove(self.modal, i) end end
  self:Restore()
end

local function Usable(n)
  if not n or n.acSkip then return false end
  if n.IsVisible and not n:IsVisible() then return false end
  if n.IsEnabled and not n:IsEnabled() and not n.acReadable then return false end
  return true
end
Focus.Usable = Usable

-- The zone a node lives in: the acZone of its nearest marked ancestor.
local function ZoneOf(n)
  local o = n
  while o do
    local z = rawget(o, "acZone")
    if z then return z end
    o = o.GetParent and o:GetParent()
  end
  return "stage"
end
Focus.ZoneOf = ZoneOf

-- The Tab stop a node belongs to: the acTabGroup or acZone of its nearest
-- marked ancestor. A tab group splits a zone for Tab only (the Review
-- sheet's list and its Back / Apply buttons are one modal zone, two stops).
local function TabGroupOf(n)
  local o = n
  while o do
    local z = rawget(o, "acTabGroup") or rawget(o, "acZone")
    if z then return z end
    o = o.GetParent and o:GetParent()
  end
  return "stage"
end
Focus.TabGroupOf = TabGroupOf

-- Every usable node under the root (tabs only when includeTabs), in tree order.
function Focus:Nodes(includeTabs)
  local list = {}
  local root = self:Root()
  if not root then return list end
  local function walk(f)
    if f.IsShown and not f:IsShown() then return end
    if rawget(f, "acZone") == "tabs" and not includeTabs then return end
    if f.acNode and Usable(f) then list[#list + 1] = f end
    if f.GetChildren then
      for _, c in ipairs({ f:GetChildren() }) do walk(c) end
    end
  end
  walk(root)
  return list
end

-- Screen-space rectangle of a frame: l, b, w, h (scaled).
local function ScreenRect(n)
  if not n.GetRect then return nil end
  local l, b, w, h = n:GetRect()
  if not l then return nil end
  local s = n.GetEffectiveScale and n:GetEffectiveScale() or 1
  return l * s, b * s, w * s, h * s
end
Focus.ScreenRect = ScreenRect

local DIRS = { UP = "navUp", DOWN = "navDown", LEFT = "navLeft", RIGHT = "navRight" }

-- The nearest scrolling ancestor of n (a ScrollFrame), or nil.
local function ScrollAncestor(n)
  local p = n.GetParent and n:GetParent()
  while p do
    if p.GetVerticalScroll and p.GetScrollChild and p:GetScrollChild() then return p end
    p = p.GetParent and p:GetParent()
  end
end
Focus.ScrollAncestor = ScrollAncestor

-- True when n is scrolled out of its scroll frame's viewport (less than half
-- of it, up to 16 px, visible), so spatial moves from outside that list never
-- land on it.
local function Clipped(n, sf)
  sf = sf or ScrollAncestor(n)
  if not sf then return false end
  local l, b, w, h = ScreenRect(n)
  local sl, sb, sw, sh = ScreenRect(sf)
  if not (l and sl) then return false end
  local iy = math.min(b + h, sb + sh) - math.max(b, sb)
  local ix = math.min(l + w, sl + sw) - math.max(l, sl)
  return iy < math.min(h * 0.5, 16) or ix < math.min(w * 0.5, 16)
end
Focus.Clipped = Clipped

-- The best node from cur in direction dir among list: explicit nav* first
-- (a node, a function returning a node, or false = stop), then spatial,
-- scored by distance along + 2 x the gap across (keyboard-nav research).
function Focus.Neighbor(cur, dir, list)
  local explicit = cur and cur[DIRS[dir]]
  if type(explicit) == "function" then explicit = explicit(cur, dir) end
  if explicit == false then return nil, true end
  if type(explicit) == "table" and Usable(explicit) then return explicit end
  local cl, cb, cw, ch = ScreenRect(cur)
  if not cl then return nil end
  local cx, cy = cl + cw / 2, cb + ch / 2
  local best, bestScore
  -- Stepping inside a list may reach its next hidden row (it scrolls into
  -- view); from anywhere else, hidden rows are not targets.
  local curScroll = ScrollAncestor(cur)
  for _, n in ipairs(list) do
    local sf = n ~= cur and ScrollAncestor(n)
    if sf and sf ~= curScroll and Clipped(n, sf) then sf = false end
    if n ~= cur and sf ~= false then
      local l, b, w, h = ScreenRect(n)
      if l then
        local x, y = l + w / 2, b + h / 2
        local along, gap, cross
        if dir == "RIGHT" then along = l - (cl + cw) ; cross = y - cy
        elseif dir == "LEFT" then along = cl - (l + w); cross = y - cy
        elseif dir == "UP" then along = b - (cb + ch); cross = x - cx
        else along = cb - (b + h); cross = x - cx end
        -- Edge distance may be negative for overlapping rects; then use centres.
        local centreAlong = (dir == "RIGHT" and x - cx) or (dir == "LEFT" and cx - x) or (dir == "UP" and y - cy) or (cy - y)
        if centreAlong > 1 then
          along = math.max(along, 0) + centreAlong * 0.05
          if dir == "RIGHT" or dir == "LEFT" then
            gap = math.max(0, math.max(b, cb) - math.min(b + h, cb + ch))
          else
            gap = math.max(0, math.max(l, cl) - math.min(l + w, cl + cw))
          end
          local score = along + 2 * gap + 0.1 * math.abs(cross)
          if not bestScore or score < bestScore then best, bestScore = n, score end
        end
      end
    end
  end
  return best
end

local function Page() return Focus.getPage and Focus.getPage() end

-- Brings node into view inside every scrolling ancestor, keeping one row of
-- context above and below it ("nearest + 1").
function Focus.ScrollIntoView(node)
  if node.acScroll and node.acScroll.ScrollToNode then
    node.acScroll:ScrollToNode(node)
    return
  end
  local p = node.GetParent and node:GetParent()
  while p do
    if p.GetVerticalScroll and p.GetScrollChild and p:GetScrollChild() and p.GetTop then
      local top, bottom = p:GetTop(), p:GetBottom()
      local nt, nb = node:GetTop(), node:GetBottom()
      if top and nt then
        local margin = math.min((nt - nb), 40)
        local cur, range = p:GetVerticalScroll(), (p.GetVerticalScrollRange and p:GetVerticalScrollRange() or 0)
        local new = cur
        if nt > top then new = cur - (nt - top) - margin
        elseif nb < bottom then new = cur + (bottom - nb) + margin end
        new = math.max(0, math.min(range, new))
        if new ~= cur then p:SetVerticalScroll(new) end
      end
      return
    end
    p = p.GetParent and p:GetParent()
  end
end

local function Unhighlight(n)
  if n and (n.acFocusStyle == "button" or n.acFocusStyle == "chip") and n.UnlockHighlight then n:UnlockHighlight() end
end

-- Moves the focus to node. source: "mouse", "key" or "pad".
function Focus:Set(node, source, quiet, noScroll)
  if not node or not self.host then return end
  source = source or "key"
  local old = self.current
  if old == node and source == "mouse" then return end
  self.setting = true
  self.current, self.source = node, source
  if old and old ~= node then
    Unhighlight(old)
    if old.acOnBlur then pcall(old.acOnBlur, old) end
  end
  if (node.acFocusStyle == "button" or node.acFocusStyle == "chip") and node.LockHighlight then node:LockHighlight() end
  if node.acOnFocus then pcall(node.acOnFocus, node, source) end
  UI.FocusRing:Attach(node)
  if source ~= "mouse" then
    -- Where the cursor was when the keys or the pad took the focus: until
    -- it moves, OnEnter from a refresh under it does not steal the focus.
    if GetCursorPosition then self.keyCursor = { GetCursorPosition() } end
    if not noScroll then Focus.ScrollIntoView(node) end
    if GameTooltip_Hide then GameTooltip_Hide() end
    if not quiet then UI.Sound("focus") end
  end
  local page = Page()
  if page and node.acId then page.lastFocusId = node.acId end
  local prevZone = self.lastZone
  self.lastZone, self.lastIndex = ZoneOf(node), nil
  -- A zone change re-aims the right stick (the page's ScrollRegion follows
  -- focus into and out of the Inspector) and refreshes the prompt labels.
  if prevZone ~= self.lastZone and self.onZoneChange then pcall(self.onZoneChange, node, self.lastZone, prevZone) end
  self.lastByZone = self.lastByZone or setmetatable({}, { __mode = "v" })
  self.lastIdByZone = self.lastIdByZone or {}
  local tg = TabGroupOf(node)
  self.lastByZone[tg], self.lastIdByZone[tg] = node, node.acId
  local l, b, w, h = ScreenRect(node)
  if l then self.lastRect = { l + w / 2, b + h / 2 } end
  -- Inspector after a short settle, so sweeping a grid doesn't flicker it.
  self.gen = (self.gen or 0) + 1
  local gen = self.gen
  -- A node inside the Inspector never re-inspects: the pane keeps explaining
  -- what was focused before, so its buttons and links stay where they are.
  if not self.pinned and self.lastZone ~= "inspector" then
    After(0.12, function() if gen == self.gen and self.current == node then self:Inspect(node) end end)
  end
  if source ~= "mouse" and ns.Setting and ns.Setting("focusTips") and node.acTip then
    After(0.25, function() if gen == self.gen and self.current == node then pcall(node.acTip, node) end end)
  end
  self.setting = false
end

-- True while the mouse should not take the focus: the cursor has not moved
-- since a key or pad move, or a dev capture is running (Focus.ignoreMouse).
function Focus:MouseStill()
  if self.ignoreMouse then return true end
  local k = self.keyCursor
  if not (k and k[1] and GetCursorPosition) then return false end
  local x, y = GetCursorPosition()
  if not x then return false end
  if math.abs(x - k[1]) <= 1 and math.abs(y - k[2]) <= 1 then return true end
  self.keyCursor = nil
  return false
end

function Focus:Inspect(node)
  node = node or self.current
  if node and ZoneOf(node) == "inspector" then node = self.inspected or node
  elseif node then self.inspected = node end
  if self.onInspect then pcall(self.onInspect, node) end
end

-- Pins the Inspector to node until Back (A on a slot pins it).
function Focus:Pin(node)
  node = node or self.current
  if not node then return end
  self.pinned = node
  self:Inspect(node)
  if node.SetPinned then pcall(node.SetPinned, node, true) end
  Esc.Push(function() self:Unpin() end, "pin")
end
function Focus:Unpin()
  local n = self.pinned
  self.pinned = nil
  Esc.Remove("pin")
  if n and n.SetPinned then pcall(n.SetPinned, n, false) end
  if self.current then self:Inspect(self.current) end
end

function Focus:Clear()
  Unhighlight(self.current)
  self.current, self.pinned = nil, nil
  UI.FocusRing:Hide()
end

-- Focus that disappeared, or nothing focused: the restore ladder (§4.1).
function Focus:Restore()
  local nodes = self:Nodes()
  if #nodes == 0 then self:Clear() return nil end
  local page = Page()
  local pick
  local want = page and page.lastFocusId
  if self.modal[#self.modal] then want = nil end
  if want then
    for _, n in ipairs(nodes) do if n.acId == want then pick = n break end end
  end
  if not pick and self.lastRect then
    local bx, by, best = self.lastRect[1], self.lastRect[2], nil
    for _, n in ipairs(nodes) do
      local l, b, w, h = ScreenRect(n)
      if l and ZoneOf(n) == self.lastZone then
        local d = (l + w / 2 - bx) ^ 2 + (b + h / 2 - by) ^ 2
        if not best or d < best then best, pick = d, n end
      end
    end
  end
  if not pick and self.modal[#self.modal] and self.modal[#self.modal].acDefault then
    pick = self.modal[#self.modal].acDefault
    if not Usable(pick) then pick = nil end
  end
  if not pick and page and page.DefaultFocus and not self.modal[#self.modal] then
    local ok, n = pcall(page.DefaultFocus, page)
    if ok and Usable(n) then pick = n end
  end
  if not pick then
    for _, n in ipairs(nodes) do if ZoneOf(n) == "stage" then pick = n break end end
  end
  pick = pick or nodes[1]
  self:Set(pick, self.source or "key", true)
  Input.SyncSmartNav(pick)
  return pick
end

-- After a refresh: keep a focus that is still usable, else restore.
function Focus:Validate()
  local n = self.current
  if n and Usable(n) then
    local inRoot, o = false, n
    local root = self:Root()
    while o do if o == root then inRoot = true break end o = o.GetParent and o:GetParent() end
    if inRoot then UI.FocusRing:Attach(n); return n end
  end
  if self.host and self.host:IsShown() then return self:Restore(true) end
end

-- D-pad / arrow move. Returns true (the key is always consumed once engaged).
function Focus:Move(dir, source)
  local cur = self.current
  if not cur or not Usable(cur) then self:Restore(); return true end
  local list = self:Nodes()
  -- Right at the Inspector's edge stops there: the window edge is to its
  -- right, and the spatial pick fell through to the prompt bar below
  -- (capture options:focus-right).
  if dir == "RIGHT" and ZoneOf(cur) == "inspector" then
    local own = {}
    for _, n in ipairs(list) do if ZoneOf(n) == "inspector" then own[#own + 1] = n end end
    list = own
  end
  local target, stopped = Focus.Neighbor(cur, dir, list)
  if target then self:Set(target, source or "key")
  elseif not stopped and cur.acEdge then pcall(cur.acEdge, cur, dir) end
  return true
end

-- A / Enter / Space on the focused node.
function Focus:Activate(source)
  local n = self.current
  if not n or not Usable(n) then self:Restore(); n = self.current end
  if not n then return false end
  -- No press squish: Blizzard buttons show their pushed art, nothing scales.
  if n.acActivate then
    pcall(n.acActivate, n, source)
  elseif n.Click then
    n:Click("LeftButton")
  end
  return true
end

-- Tab / Shift-Tab: next zone with nodes (view -> stage -> inspector -> prompts).
function Focus:NextZone(delta)
  local nodes = self:Nodes()
  if #nodes == 0 then return false end
  local byZone, order = {}, {}
  for _, n in ipairs(nodes) do
    local z = TabGroupOf(n)
    if not byZone[z] then byZone[z] = {}; order[#order + 1] = z end
    table.insert(byZone[z], n)
  end
  local seq = {}
  for _, z in ipairs(self.zones) do if byZone[z] then seq[#seq + 1] = z end end
  for _, z in ipairs(order) do
    local known = false
    for _, s in ipairs(seq) do if s == z then known = true end end
    if not known then seq[#seq + 1] = z end
  end
  local cur = self.current and TabGroupOf(self.current)
  local idx = 0
  for i, z in ipairs(seq) do if z == cur then idx = i end end
  local nextZone = seq[((idx - 1 + (delta or 1)) % #seq) + 1]
  if idx == 0 then nextZone = seq[1] end
  -- Land on the node last focused in that zone while it is still there
  -- (not in the Inspector: its pooled rows change with the subject).
  local target = byZone[nextZone][1]
  local last = nextZone ~= "inspector" and self.lastByZone and self.lastByZone[nextZone]
  if last and rawget(last, "acId") == self.lastIdByZone[nextZone] then
    for _, n in ipairs(byZone[nextZone]) do if n == last then target = n break end end
  end
  self:Set(target, "key")
  return true
end

-- PgUp/PgDn/Home/End inside the focused list (nodes sharing node.acScroll).
-- Without a focused list the page may take them with page:ListJump(kind)
-- (the Macros book turns pages); it returns true when it handled the key.
function Focus:ListJump(kind)
  local cur = self.current
  local list = cur and cur.acScroll
  if not (list and list.Nodes) then
    local page = Page()
    if page and page.ListJump then
      local ok, handled = pcall(page.ListJump, page, kind)
      return (ok and handled) and true or false
    end
    return false
  end
  local rows = list:Nodes()
  if #rows == 0 then return false end
  local idx = 1
  for i, r in ipairs(rows) do if r == cur then idx = i end end
  local page = list.VisibleRows and list:VisibleRows() or 8
  if kind == "HOME" then idx = 1
  elseif kind == "END" then idx = #rows
  elseif kind == "PAGEUP" then idx = math.max(1, idx - page)
  else idx = math.min(#rows, idx + page) end
  self:Set(rows[idx], "key")
  return true
end

-- Keyboard engaged mode: arrows/Enter/Space go to the window (§4.3).
function Focus:Engage()
  if self.engaged then return end
  self.engaged = true
  Esc.Push(function() Focus:Disengage() end, "engaged")
end
function Focus:Disengage()
  if not self.engaged then return end
  self.engaged = false
  Esc.Remove("engaged")
  Input.StopRepeat()
end

-- Keys a movement binding owns: they release the window (WASD never consumed).
local PASS = { MOVEFORWARD = true, MOVEBACKWARD = true, TURNLEFT = true, TURNRIGHT = true, STRAFELEFT = true,
  STRAFERIGHT = true, JUMP = true, TOGGLEAUTORUN = true }
local ARROWS = { UP = "UP", DOWN = "DOWN", LEFT = "LEFT", RIGHT = "RIGHT" }

-- One OnKeyDown key. Returns true when the window consumed it.
function Focus:HandleKey(key)
  if InCombat() then return false end
  local binding = GetBindingFromClick and GetBindingFromClick(key)
  if key == "ESCAPE" or binding == "TOGGLEGAMEMENU" then
    if Input.escRegistered then return false end
    return Esc.Pop()
  end
  local shift = IsShiftKeyDown and IsShiftKeyDown()
  if key == "TAB" then
    UI.NoteDevice("keyboard")
    if not self.engaged then
      self:Engage()
      if not self.current or not Usable(self.current) then self:Restore() return true end
      self:Set(self.current, "key", true)
      return true
    end
    self:NextZone(shift and -1 or 1)
    return true
  end
  if not self.engaged then return false end
  if ARROWS[key] then
    UI.NoteDevice("keyboard")
    self:Move(ARROWS[key], "key")
    Input.StartRepeat(key, ARROWS[key], "key")
    return true
  end
  if key == "ENTER" or key == "SPACE" or key == "NUMPADENTER" then
    UI.NoteDevice("keyboard")
    return self:Activate("key")
  end
  if key == "PAGEUP" or key == "PAGEDOWN" or key == "HOME" or key == "END" then
    return self:ListJump(key)
  end
  if binding and PASS[binding] then
    self:Disengage()
    return false
  end
  return false
end

-- Window glue ------------------------------------------------------------------------------

-- Held arrows repeat after 0.35 s, every 0.08 s, until the key is released.
-- source ("key" or "pad") is the device the repeated moves record.
function Input.StartRepeat(key, dir, source)
  Input.repeatKey = key
  Input.repeatSource = source or "key"
  Input.repeatGen = (Input.repeatGen or 0) + 1
  local gen = Input.repeatGen
  if not (C_Timer and C_Timer.After) then return end
  C_Timer.After(0.35, function()
    if gen ~= Input.repeatGen or not C_Timer.NewTicker then return end
    Input.ticker = C_Timer.NewTicker(0.08, function(t)
      if gen ~= Input.repeatGen or InCombat() or not (Focus.host and Focus.host:IsShown()) then
        if t and t.Cancel then t:Cancel() end
        return
      end
      Focus:Move(dir, Input.repeatSource or "key")
    end)
  end)
end
function Input.StopRepeat()
  Input.repeatGen = (Input.repeatGen or 0) + 1
  Input.repeatKey = nil
  if Input.ticker and Input.ticker.Cancel then Input.ticker:Cancel() end
  Input.ticker = nil
end

local function OnKeyDown(self, key)
  if InCombat() then return end
  if GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus() then return end
  local ok, handled = pcall(Focus.HandleKey, Focus, key)
  if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(not (ok and handled)) end
end
local function OnKeyUp(self, key)
  if key == Input.repeatKey then Input.StopRepeat() end
  if not InCombat() and self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(true) end
end

-- Hidden named buttons the override bindings click.
local function Hidden(name, fn, device)
  local b = CreateFrame("Button", name, Input.host)
  b:SetScript("OnClick", function()
    if device then UI.NoteDevice(device) end
    if InCombat() then return end
    -- A window chord engages the keyboard (spec 4.3), so the arrows that
    -- follow go to the window, not to the character.
    if device == "keyboard" then Focus:Engage() end
    fn()
  end)
  b:Hide()
  b.acSkip = true
  return b
end

local function H(name) return function(...) local f = Input.handlers[name] if f then return f(...) end end end

function Input.Setup(host)
  Input.host = host
  -- SetPropagateKeyboardInput is protected in combat, and a keyboard-enabled
  -- frame that does not propagate would eat every keybind until combat ends.
  -- In combat the keyboard stays off; Input.LeaveCombat turns it on.
  if not InCombat() then
    host:EnableKeyboard(true)
    if host.SetPropagateKeyboardInput then host:SetPropagateKeyboardInput(true) end
  end
  host:SetScript("OnKeyDown", OnKeyDown)
  host:SetScript("OnKeyUp", OnKeyUp)
  Hidden("AgentcraftPrevTab", function() H("page")(-1) end, "pad")
  Hidden("AgentcraftNextTab", function() H("page")(1) end, "pad")
  Hidden("AgentcraftPadY", H("primary"), "pad")
  Hidden("AgentcraftPadX", H("view"), "pad")
  Hidden("AgentcraftPadA", function() Focus:Activate("pad") end, "pad")
  Hidden("AgentcraftPadB", function() Esc.Back() end, "pad")
  -- The D-pad repeats while held, like the arrow keys: the binding clicks on
  -- the press (down = true) and on the release (down = false).
  for _, d in ipairs({ "UP", "DOWN", "LEFT", "RIGHT" }) do
    local b = Hidden("AgentcraftPad" .. d, nil, "pad")
    if b.RegisterForClicks then pcall(b.RegisterForClicks, b, "AnyDown", "AnyUp") end
    b:SetScript("OnClick", function(_, _, down)
      if down == false then
        if Input.repeatKey == "PAD" .. d then Input.StopRepeat() end
        return
      end
      UI.NoteDevice("pad")
      if InCombat() then return end
      Focus:Move(d, "pad")
      if down then Input.StartRepeat("PAD" .. d, d, "pad") end
    end)
  end
  Hidden("AgentcraftKeyPrev", function() H("page")(-1) end, "keyboard")
  Hidden("AgentcraftKeyNext", function() H("page")(1) end, "keyboard")
  Hidden("AgentcraftKeyPrimary", H("primary"), "keyboard")
  Hidden("AgentcraftKeyView", H("view"), "keyboard")
  Hidden("AgentcraftKeySearch", H("search"), "keyboard")
  for i = 1, 5 do Hidden("AgentcraftKeyPage" .. i, function() H("pageIndex")(i) end, "keyboard") end
  -- Escape through the game menu's handler registry when the client has it.
  -- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_GameMenuEsc/Blizzard_GameMenuEsc.lua
  if RegisterGameMenuEscHandler and GameMenuEscPriority and GameMenuEscPriority.AddOn then
    local ok = pcall(RegisterGameMenuEscHandler, GameMenuEscPriority.AddOn, function()
      if not (host:IsShown()) then return false end
      return Esc.Pop()
    end)
    Input.escRegistered = ok
  end
  local ev = CreateFrame("Frame")
  for _, e in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "INPUT_DEVICE_INTERFACE_TRANSITION",
                       "GAME_PAD_ACTIVE_CHANGED", "GAME_PAD_CONNECTED", "GAME_PAD_DISCONNECTED" }) do
    pcall(ev.RegisterEvent, ev, e)
  end
  ev:SetScript("OnEvent", function(_, event, arg)
    if event == "PLAYER_REGEN_DISABLED" then Input.EnterCombat()
    elseif event == "PLAYER_REGEN_ENABLED" then Input.LeaveCombat()
    else
      if event == "GAME_PAD_ACTIVE_CHANGED" and arg then UI.NoteDevice("pad") end
      UI.RefreshPrompts()
      Input.Apply()
    end
  end)
  Input.events = ev
  -- A world click ends keyboard engaged mode (spec §4.3), so the arrow keys
  -- move the character again. Registered only while the window is shown
  -- (Input.Apply / Input.Release).
  local mouse = CreateFrame("Frame")
  mouse:SetScript("OnEvent", function() Input.OnGlobalMouseDown() end)
  Input.mouse = mouse
  local mgr = InputDeviceIconSetManager
  if type(mgr) == "table" and mgr.RegisterActiveInputDeviceIconSetUpdatedCallback then
    pcall(mgr.RegisterActiveInputDeviceIconSetUpdatedCallback, mgr, UI.RefreshPrompts, UI)
  end
end

-- GLOBAL_MOUSE_DOWN: drop engaged mode when the click lands outside the
-- window on the world (WorldFrame or nothing). Clicks on other UI (a menu the
-- window opened, the chat box) leave it as it is.
function Input.OnGlobalMouseDown()
  local host = Input.host
  if not (Focus.engaged and host and host:IsShown()) then return end
  if host.IsMouseOver and host:IsMouseOver() then return end
  local top
  local GetFoci, GetFocus = _G["GetMouseFoci"], _G["GetMouseFocus"]
  if GetFoci then
    local ok, foci = pcall(GetFoci)
    top = ok and type(foci) == "table" and foci[1] or nil
  elseif GetFocus then
    local ok, f = pcall(GetFocus)
    top = ok and f or nil
  end
  if top == nil or top == _G["WorldFrame"] then Focus:Disengage() end
end

local function WatchMouse(on)
  local m = Input.mouse
  if not m then return end
  if on then pcall(m.RegisterEvent, m, "GLOBAL_MOUSE_DOWN")
  elseif m.UnregisterEvent then pcall(m.UnregisterEvent, m, "GLOBAL_MOUSE_DOWN") end
end

local function FCMPresent()
  return type(GamepadMode) == "table" and GamepadMode.FrameControlsManager ~= nil
end

-- Which pad bindings the window owns now: "focus" (Gamepad UI with FCM
-- focus: X, Y, LB, RB only), "full" (a controller without Gamepad UI
-- navigation: D-pad, A, B too) or nil.
function Input.PadSet()
  local gp = UI.GamepadUI()
  if gp then
    if Input.padFocus then return "focus" end
    if not FCMPresent() then return "full" end
    return nil
  end
  if C_GamePad and C_GamePad.IsEnabled and C_GamePad.IsEnabled() then return "full" end
  return nil
end

-- (Re)sets the window's override bindings. Out of combat only; queued otherwise.
function Input.Apply()
  local host = Input.host
  if host then WatchMouse(host:IsShown()) end
  if not host or not (SetOverrideBindingClick and ClearOverrideBindings) then return end
  if InCombat() then Input.pendingApply = true return end
  Input.pendingApply = nil
  ClearOverrideBindings(host)
  if not host:IsShown() then return end
  local function Bind(key, button) SetOverrideBindingClick(host, true, key, button) end
  if ns.Setting("shortcuts") ~= false then
    Bind("CTRL-TAB", "AgentcraftKeyNext")
    Bind("CTRL-SHIFT-TAB", "AgentcraftKeyPrev")
    Bind("CTRL-ENTER", "AgentcraftKeyPrimary")
    Bind("CTRL-SPACE", "AgentcraftKeyView")
    Bind("CTRL-F", "AgentcraftKeySearch")
    for i = 1, 5 do Bind("CTRL-" .. i, "AgentcraftKeyPage" .. i) end
  end
  local set = Input.PadSet()
  if set then
    Bind("PAD4", "AgentcraftPadY")
    Bind("PAD3", "AgentcraftPadX")
    Bind("PADLSHOULDER", "AgentcraftPrevTab")
    Bind("PADRSHOULDER", "AgentcraftNextTab")
    if set == "full" then
      Bind("PAD1", "AgentcraftPadA")
      Bind("PAD2", "AgentcraftPadB")
      Bind("PADDUP", "AgentcraftPadUP")
      Bind("PADDDOWN", "AgentcraftPadDOWN")
      Bind("PADDLEFT", "AgentcraftPadLEFT")
      Bind("PADDRIGHT", "AgentcraftPadRIGHT")
    end
  end
  -- The back paddles (F13-F16) are never bound by the window (owner rule).
end

function Input.Release()
  local host = Input.host
  if not host then return end
  Input.StopRepeat()
  Focus:Disengage()
  WatchMouse(false)
  if InCombat() then Input.pendingClear = true return end
  if ClearOverrideBindings then ClearOverrideBindings(host) end
end

-- FrameControlsManager focus (Gamepad UI): frame.FocusGamepad / UnfocusGamepad.
function Input.SetPadFocus(on)
  Input.padFocus = on and true or false
  if on then UI.NoteDevice("pad") end
  Input.Apply()
end

-- PLAYER_REGEN_DISABLED: still unlocked inside the handler.
function Input.EnterCombat()
  local host = Input.host
  if not host then return end
  Input.StopRepeat()
  Focus:Disengage()
  if ClearOverrideBindings then pcall(ClearOverrideBindings, host) end
  if host.SetPropagateKeyboardInput then pcall(host.SetPropagateKeyboardInput, host, true) end
  pcall(host.EnableKeyboard, host, false)
  if Input.onCombat then pcall(Input.onCombat, true) end
end

function Input.LeaveCombat()
  local host = Input.host
  if not host then return end
  if Input.pendingClear and ClearOverrideBindings then ClearOverrideBindings(host) end
  Input.pendingClear = nil
  if host:IsShown() then
    host:EnableKeyboard(true)
    if host.SetPropagateKeyboardInput then host:SetPropagateKeyboardInput(true) end
    Input.Apply()
  end
  if Input.pendingSmartNav then
    -- Replay with the region for the current page and zone (the window's
    -- resolver), else the one queued in combat, so the right stick keeps
    -- aiming at the page's scroll region.
    local region = Input.scrollRegionFn and Input.scrollRegionFn()
    Input.SyncSmartNav(Focus.current, region or Input.pendingRegion)
  end
  if Input.onCombat then pcall(Input.onCombat, false) end
end

-- Gamepad UI navigation: pick up rebuilt buttons, aim the pointer, register
-- the right-stick scroll frame. Never SelectButton (§4.2). Queued in combat.
function Input.SyncSmartNav(node, scrollRegion)
  local SN = SmartNavigation
  local host = Input.host
  if type(SN) ~= "table" or not host or not UI.GamepadUI() then return end
  if InCombat() then Input.pendingSmartNav = true; Input.pendingRegion = scrollRegion return end
  Input.pendingSmartNav, Input.pendingRegion = nil, nil
  if SN.RefreshButtonGroups then pcall(SN.RefreshButtonGroups, SN, host) end
  if node and SN.SetTargetButtonForFrame then pcall(SN.SetTargetButtonForFrame, SN, host, node) end
  local region = scrollRegion or (node and node.acScroll and node.acScroll.scroll)
  if region and SN.SetScrollFrameForFrame then pcall(SN.SetScrollFrameForFrame, SN, host, region) end
end
