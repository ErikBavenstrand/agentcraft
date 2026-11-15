-- Macros page (dev/ui-spec-v2.md §9.4): an open spellbook. The stage is the
-- left page, the Inspector the right page.
--   View strip: For You | Everything (X / Ctrl+Space), search (Ctrl+F)
--   Tag row:    the most common tags as toggle chips, plus More... (every tag)
--   Book:       2 columns x 6 rows of macro cards (icon, name, one line,
--               state badge), [<] Page n of m [>] below. Off the left or right
--               edge, the wheel and the page buttons turn the page.
--   Inspector:  the focused (or selected) macro: state, description,
--               requirements, its text, where it is used, Install / Pick Up /
--               Remove.
--   Y:          "Install <name>" while the selected macro can be installed,
--               else "Install recommended N" through the Review sheet.
-- Module logic lives in Macros/Library.lua and is untouched: install-once,
-- a macro of yours with the same name is never overwritten, and this page
-- authors no macro text.
-- Art: spellbook-Page-Left/Right-C60 (Forever, Camelot Blizzard_SpellBookTemplates.xml),
-- then retail spellbook-background-evergreen-left/right (Blizzard_SpellBookFrame.xml).
local _, ns = ...
local UI = ns.UI
local L = ns.MacroLibrary

local COLS, ROWS = 2, 6
local PER_PAGE = COLS * ROWS
local CARD_W, CARD_H, STEP_X, STEP_Y = 344, 60, 352, 64
-- The tag row sits on the parchment just below the left page art's top
-- border (stage y ~38-47 in game); the book follows below it.
local BOOK_TOP = -78               -- below the view strip and the tag row
local TAG_Y, TAG_H = -46, 28
local NAV_H = 32
local SEARCH_W = 170
local MAX_TAG_CHIPS = 6

local BOOK_LEFT = { "spellbook-Page-Left-C60", "spellbook-background-evergreen-left" }
local PAGE_PREV = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage"
local PAGE_NEXT = "Interface\\Buttons\\UI-SpellbookIcon-NextPage"
local CHECK_OK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:14|t"
local CHECK_NO = "|TInterface\\RaidFrame\\ReadyCheck-NotReady:14|t"

local function Trim(s) return ((s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end

local function After(sec, fn)
  if C_Timer and C_Timer.After then C_Timer.After(sec, fn) else fn() end
end

-- The current pet's own icon for a pet ability (pet spells are not in the
-- player's spellbook, so C_Spell lookups by name miss them).
local function PetAbilityIcon(name)
  if not (name and GetPetActionInfo) then return end
  for i = 1, NUM_PET_ACTION_SLOTS or 10 do
    local ok, n, tex, isToken = pcall(GetPetActionInfo, i)
    if ok and not isToken and n == name and tex then return tex end
  end
end

local function DisplayIcon(m)
  if m.petAbility then
    local tex = PetAbilityIcon(m.petAbility)
    if tex then return tex end
  end
  if m.icon then
    local tex = UI.SpellIcon(m.icon)
    if tex then return tex end
    if C_Item and C_Item.GetItemInfoInstant then
      local itemTex = select(5, C_Item.GetItemInfoInstant(m.icon))
      if itemTex then return itemTex end
    end
  end
  return "Interface\\Icons\\" .. (m.iconFile or "INV_Misc_QuestionMark")
end

local function CategoryTitle(key)
  for _, c in ipairs(L.categories) do if c.key == key then return c.title end end
  return key
end

local function IsInstalled(st) return st == "installed" or st == "update" end
local function CanInstall(st) return st == "ready" or st == "update" end

-- Badge word and colour for a state; nil for a macro that is ready to install.
local function Badge(m, st, why)
  if st == "installed" then return "Installed", UI.C.GREEN end
  if st == "update" then return "Update", UI.C.NORMAL end
  if st == "taken" then return "Name in use", UI.C.ORANGE end
  if st == "blocked" then
    local spell = L.MissingSpell(m)
    return spell and ("Requires " .. spell) or "Can't install", UI.C.RED, not spell and why or nil
  end
end

-- Wraps every case-insensitive match of q in text with a colour code.
local function Highlight(text, q, hex)
  text = text or ""
  if not q or q == "" then return text end
  local lower, out, i = text:lower(), {}, 1
  while true do
    local s, e = lower:find(q, i, true)
    if not s then break end
    out[#out + 1] = text:sub(i, s - 1)
    out[#out + 1] = "|cff" .. hex .. text:sub(s, e) .. "|r"
    i = e + 1
  end
  out[#out + 1] = text:sub(i)
  return table.concat(out)
end

-- One line, cut at a word with "..." when it is wider than the text box.
local function FitLine(fs, text, plain)
  fs:SetText(text)
  local w = fs:GetWidth()
  if not (w and w > 0) or fs:GetStringWidth() <= w then return end
  local cut = plain or text
  while #cut > 0 do
    cut = cut:gsub("%s*%S+$", "")
    fs:SetText(cut .. "...")
    if fs:GetStringWidth() <= w then return end
  end
end

-- Filtering ---------------------------------------------------------------------------

local function Matches(page, m)
  for key in pairs(page.filters) do
    if not L.HasTag(m, key) then return false end
  end
  local q = page.query
  if q ~= "" then
    local hay = m.name .. " " .. (m.desc or "")
    for _, t in ipairs(L.Tags(m)) do hay = hay .. " " .. t.label end
    if not hay:lower():find(q, 1, true) then return false end
  end
  return true
end

local function Filtered(page)
  local list = {}
  for _, m in ipairs(page.entries) do if Matches(page, m) then list[#list + 1] = m end end
  return list
end

-- Tags of the macros in the current scope (class tags left out: the scope
-- already says whose they are), most used first, with counts.
local function AvailableTags(page)
  local counts, tags = {}, {}
  for _, m in ipairs(page.entries) do
    for _, t in ipairs(L.Tags(m)) do
      if not counts[t.key] then tags[#tags + 1] = t end
      counts[t.key] = (counts[t.key] or 0) + 1
    end
  end
  return tags, counts
end

local function ChipTags(page)
  local tags, counts = AvailableTags(page)
  local list = {}
  for _, t in ipairs(tags) do if t.type ~= "class" then list[#list + 1] = t end end
  table.sort(list, function(a, b)
    if counts[a.key] ~= counts[b.key] then return counts[a.key] > counts[b.key] end
    return a.label < b.label
  end)
  return list, counts
end

-- Recommended: macros for this character that install or update cleanly.
-- Untested ones wait until you pick them yourself, and new macros stop when
-- their macro tab (General 120 / Character 18) has no free slot.
local function FreeSlots()
  local acct, char = 0, 0
  if GetNumMacros then acct, char = GetNumMacros() end
  return (MAX_ACCOUNT_MACROS or 120) - (acct or 0), (MAX_CHARACTER_MACROS or 18) - (char or 0)
end

local function Recommended()
  local list = {}
  local freeAcct, freeChar = FreeSlots()
  for _, m in ipairs(L.Entries(false)) do
    local st = L.State(m)
    if not m.untested and CanInstall(st) then
      if st == "update" then list[#list + 1] = m
      elseif m.perCharacter and freeChar > 0 then list[#list + 1] = m; freeChar = freeChar - 1
      elseif not m.perCharacter and freeAcct > 0 then list[#list + 1] = m; freeAcct = freeAcct - 1 end
    end
  end
  return list
end

local function SelectedInstallable(page)
  local m = page.selected
  return m and CanInstall((L.State(m))) and m or nil
end

-- Where the macro lives: its homes in the layouts (Apply puts it there) and
-- where it sits now, both named by key or controller glyph, never by an
-- action bar number. Each line opens that page on that key.

local KB_KEYS = { "Q", "E", "R", "T", "F", "G", "C", "V", "1", "2", "3", "4" }
local KB_VIEW = { [""] = "plain", ["SHIFT-"] = "shift", ["ALT-"] = "alt" }
local PAD_LAYER = { none = 0, LT = 1, RT = 2, ["LT+RT"] = 3 }
-- Action slot -> binding command (ActionBars' BAR_SLOT table).
local SLOT_COMMANDS = {
  { "ACTIONBUTTON", 0 }, { "MULTIACTIONBAR1BUTTON", 60 }, { "MULTIACTIONBAR2BUTTON", 48 },
  { "MULTIACTIONBAR3BUTTON", 24 }, { "MULTIACTIONBAR4BUTTON", 36 }, { "MULTIACTIONBAR5BUTTON", 144 },
  { "MULTIACTIONBAR6BUTTON", 156 }, { "MULTIACTIONBAR7BUTTON", 168 },
}

local function PlayerClass()
  if not UnitClass then return end
  local _, class = UnitClass("player")
  return class
end

-- Opens a page with a view chosen and focus on one node.
local function OpenAt(id, view, focusId)
  local p = ns.PageById and ns.PageById(id)
  if not p then return end
  if view and p.view ~= view then
    p.view = view
    if p.OnView then pcall(p.OnView, p, view) end
  end
  ns.OpenPage(id, focusId)
end

-- The view a page will show (1 picture, 2 list): its live mode once built,
-- else the persisted choice its Build will read, so a focus id made before
-- the first visit names a node that exists after Build.
local function KeyboardMode(p)
  if p.mode then return p.mode end
  local saved = type(ns.db) == "table" and type(ns.db.keyboardPage) == "table" and ns.db.keyboardPage or nil
  return (saved and saved.mode == 2) and 2 or 1
end
local function ControllerMode(p)
  if p.mode then return p.mode end
  return (type(ns.db) == "table" and ns.db.controllerView == 2) and 2 or 1
end

local function OpenKeyboard(base, view)
  if not (ns.PageById and ns.PageById("keyboard")) then return ns.OpenPage("bars") end
  local p = ns.PageById("keyboard")
  local focusId = base and ((KeyboardMode(p) == 2 and ("list:" .. base .. ":" .. ((view == "shift" and 2) or (view == "alt" and 3) or 1)))
    or ("key:" .. base)) or nil
  OpenAt("keyboard", base and view or nil, focusId)
end

local function OpenController(set, layer, button)
  local p = ns.PageById and ns.PageById("controller")
  if not p then return end
  OpenAt("controller", tostring(set), (ControllerMode(p) == 2 and "list:" or "pad:") .. layer .. ":" .. button)
end

-- The right book page's art has a dark border band along its top; while it
-- dresses the Inspector, every header starts below that band so the ink
-- title stays readable (the Inspector's own top inset is only 8 px).
local BOOK_TOP_CLEAR = 16
local bookRight -- page.right of the built page, or nil
local function BookHeader(pane, ...)
  if bookRight and bookRight.IsShown and bookRight:IsShown() and type(pane.y) == "number" then
    pane.y = pane.y + BOOK_TOP_CLEAR
  end
  return pane:Header(...)
end

-- "Shift + Q" for a keyboard key ("SHIFT-Q").
local function KeyWords(key)
  local mod, base = key:match("^(%u+)%-(.+)$")
  local names = { SHIFT = "Shift", ALT = "Alt", CTRL = "Ctrl" }
  if mod and names[mod] then return names[mod] .. " + " .. ((UI.KeyText and base:len() > 1 and UI.KeyText(base)) or base) end
  return (UI.KeyText and key:len() > 1 and UI.KeyText(key)) or key
end

-- Inline glyphs for a controller chord ("RT Up" -> [RT] + [D-pad up]).
local function ChordGlyphs(layer, button)
  local parts = {}
  for _, k in ipairs(UI.PAD_LAYER_TRIGGERS and UI.PAD_LAYER_TRIGGERS[layer] or {}) do parts[#parts + 1] = UI.GlyphMarkup(k, 18) end
  local key = UI.PAD_OFFSETS and UI.PAD_OFFSETS[button] and UI.PAD_OFFSETS[button][4]
  parts[#parts + 1] = key and UI.GlyphMarkup(key, 18) or button
  return table.concat(parts, " + ")
end

local function ControllerTitle(set)
  local pages = ns.Layout and ns.Layout.ControllerPages and ns.Layout.ControllerPages(PlayerClass())
  local t = pages and pages[set] and pages[set].title
  return "set " .. set .. (t and (" · " .. t) or "")
end

-- Homes in this class's layouts: { text, fn } cross-references.
local function Homes(m)
  local out, class = {}, PlayerClass()
  local kb = class and ns.Layout and ns.Layout.KeyboardBars and ns.Layout.KeyboardBars(class)
  for bar, list in ipairs(kb or {}) do
    for i, e in ipairs(list or {}) do
      if type(e) == "table" and e.macro == m.name and KB_KEYS[i] then
        local prefix = bar == 2 and "SHIFT-" or ""
        out[#out + 1] = { text = "Keyboard:  " .. KeyWords(prefix .. KB_KEYS[i]),
          fn = function() OpenKeyboard(KB_KEYS[i], KB_VIEW[prefix]) end }
      end
    end
  end
  local pages = class and ns.Layout and ns.Layout.ControllerPages and ns.Layout.ControllerPages(class)
  for set, def in ipairs(pages or {}) do
    local keys = {}
    for key, e in pairs(def) do
      if type(e) == "table" and e.macro == m.name then keys[#keys + 1] = key end
    end
    table.sort(keys)
    for _, key in ipairs(keys) do
      local layer, button = key:match("^(%S+) (%S+)$")
      if layer and PAD_LAYER[layer] then
        out[#out + 1] = { text = "Controller:  " .. ChordGlyphs(PAD_LAYER[layer], button) .. "  (" .. ControllerTitle(set) .. ")",
          fn = function() OpenController(set, PAD_LAYER[layer], button) end }
      end
    end
  end
  return out
end

-- Controller slots by action slot, from the Controller plan (nil without one).
local function PadSlots()
  local C = ns.modules and ns.modules.controller
  if not (C and C.Plan and C.active) then return nil end
  local ok, plan = pcall(C.Plan)
  if not ok or type(plan) ~= "table" then return nil end
  local out = {}
  for set = 1, 3 do
    for slotID, p in pairs(plan[set] or {}) do
      if type(slotID) == "number" and type(p) == "table" and p.slot and p.key then out[p.slot] = { set = set, key = p.key } end
    end
  end
  return out
end

-- Where the macro sits now: { text, fn } for each action slot and key bound to it.
local function UsedBy(m, index)
  local out = {}
  if not (index and index > 0) then return out end
  local pad
  if GetActionInfo then
    for slot = 1, 180 do
      local kind, id = GetActionInfo(slot)
      if kind == "macro" and id == index then
        local ref
        for _, sc in ipairs(SLOT_COMMANDS) do
          local n = slot - sc[2]
          if n >= 1 and n <= 12 then
            local key = GetBindingKey and GetBindingKey(sc[1] .. n)
            if key then
              local prefix, base = key:match("^(%u+%-)(.+)$")
              prefix, base = prefix or "", base or key
              local view = KB_VIEW[prefix]
              ref = { text = "Keyboard:  " .. KeyWords(key), fn = function() OpenKeyboard(view and base or nil, view) end }
            end
            break
          end
        end
        if not ref then
          if pad == nil then pad = PadSlots() or false end
          local p = pad and pad[slot]
          local layer, button
          if p then layer, button = p.key:match("^(%S+) (%S+)$") end
          if layer and PAD_LAYER[layer] then
            local set = p.set
            ref = { text = "Controller:  " .. ChordGlyphs(PAD_LAYER[layer], button) .. "  (" .. ControllerTitle(set) .. ")",
              fn = function() OpenController(set, PAD_LAYER[layer], button) end }
          else
            ref = { text = "Action bar slot, no key bound", fn = function() OpenKeyboard() end }
          end
        end
        out[#out + 1] = ref
        if #out >= 4 then break end
      end
    end
  end
  if GetBindingKey then
    for _, key in ipairs({ GetBindingKey("MACRO " .. m.name) }) do
      out[#out + 1] = { text = "Key:  " .. KeyWords(key), fn = function() OpenKeyboard() end }
    end
  end
  -- Same key twice (bar slot and its binding) reads once.
  local seen, uniq = {}, {}
  for _, r in ipairs(out) do if not seen[r.text] then seen[r.text] = true; uniq[#uniq + 1] = r end end
  return uniq
end

-- Inspector (the right page) -------------------------------------------------------------

local function InstallOne(page, m)
  local card = page.cardFor and page.cardFor[m.name]
  UI.RunAction(function() L.Install({ m }) end)
  if IsInstalled((L.State(m))) then
    UI.Sound("installed")
    if card and card.Flash then card:Flash() end
  end
end

local function FillInspector(page, m, pane)
  if not m then
    BookHeader(pane, "Interface\\Icons\\INV_Misc_Book_09", "Macros", "Library")
    pane:Empty(page.anyShown == false and "No macros match. Clear the tags or the search." or "Move to a macro to read it here.")
    return
  end
  local st, index, why = L.State(m)
  local blocked = st == "blocked"
  BookHeader(pane, DisplayIcon(m), m.name,
    (m.perCharacter and "Character macro" or "General macro") .. " · " .. CategoryTitle(m.category))
  local word, color, reason = Badge(m, st, why)
  local stateLine = {
    installed = "Installed · up to date",
    update = "Installed · Update writes the newer text",
    taken = "Your own macro has this name; it is never overwritten",
    ready = "Not installed yet",
  }
  pane:Row("State", word and (st == "blocked" and word or (stateLine[st] or word)) or stateLine.ready,
    color or UI.C.HIGHLIGHT)
  if reason then pane:Text(reason, UI.C.RED) end
  if st == "ready" then
    local freeAcct, freeChar = FreeSlots()
    if (m.perCharacter and freeChar <= 0) or (not m.perCharacter and freeAcct <= 0) then
      pane:Row("No room", (m.perCharacter and "Character" or "General") .. " macros are full", UI.C.ORANGE)
    end
  end
  if m.untested then pane:Row("Untested", "not yet confirmed in game", UI.C.ORANGE) end
  if m.desc and m.desc ~= "" then pane:Text(m.desc) end
  local req = L.Requirements(m)
  if #req > 0 then
    pane:Section("Requires")
    for _, r in ipairs(req) do
      pane:Row((r[2] and CHECK_OK or CHECK_NO) .. " " .. r[1], r[2] and "Known" or "Not learned",
        r[2] and UI.C.GREEN or UI.C.RED, UI.SpellIcon(r[1]))
    end
  end
  local homes = Homes(m)
  if #homes > 0 then
    pane:Section("Home")
    pane:CrossRef(homes)
    if not IsInstalled(st) then
      pane:Text("Install it, then Apply on the Keyboard or Controller page puts it here. Until then those keys cast the plain spell.", UI.C.DISABLED)
    end
  end
  local used = UsedBy(m, index)
  if #used > 0 then
    pane:Section("On your bars now")
    pane:CrossRef(used)
  elseif IsInstalled(st) then
    if #homes > 0 then
      pane:Text("Not on a bar yet: Apply on the Keyboard or Controller page places it.", UI.C.DISABLED)
    else
      pane:Text("Not on a bar yet: Pick Up, then click an action button.", UI.C.DISABLED)
    end
  end
  pane:Section("Macro")
  pane:Code(L.Resolve(m) or m.body)
  if st == "taken" then
    pane:Text("Rename or delete your own '" .. m.name .. "' in /macro to install this one.", UI.C.DISABLED)
  end
  local label = st == "update" and "Update" or st == "installed" and "Installed" or "Install"
  pane:Buttons({
    { label = label, enabled = CanInstall(st) and not blocked and not InCombatLockdown(),
      fn = function() InstallOne(page, m) end },
    { label = "Pick Up", enabled = IsInstalled(st), fn = function() L.PickUp(m) end },
    { label = "Remove", enabled = IsInstalled(st),
      confirm = "Remove '" .. m.name .. "' and unbind its keys?",
      fn = function() UI.RunAction(function() L.Remove({ m }) end) end },
  })
end

-- Book ----------------------------------------------------------------------------------

local Refresh -- forward

local function PageCount(page) return math.max(1, math.ceil(#(page.shown or {}) / PER_PAGE)) end

-- The card at (row, col) on the current page, or the last one shown.
local function CardAt(page, row, col)
  local c = page.cards[(row - 1) * COLS + col]
  if c and c:IsShown() then return c end
  for i = PER_PAGE, 1, -1 do if page.cards[i]:IsShown() then return page.cards[i] end end
end

-- Turns the book by delta pages. Returns true when it turned.
local function TurnPage(page, delta)
  local n = PageCount(page)
  local want = math.max(1, math.min(n, page.pageNum + delta))
  if want == page.pageNum then return false end
  page.pageNum = want
  -- Instant, as the spellbook turns its pages: the page-turn sound only.
  UI.Sound("page")
  local before = ns.Focus.current
  page.turning = true
  ns.UI.Refresh()
  page.turning = nil
  local cur = ns.Focus.current
  local source = ns.Focus.source or "key"
  -- A focused card slot that the shorter last page leaves empty (the refresh
  -- may already have moved focus to a page button) hands focus to the
  -- nearest card still shown, so focus stays in the grid.
  if before and before.acMacroCard and not before:IsShown() then
    local card = CardAt(page, before.row, before.col)
    if card then
      if ns.Focus.current ~= card then ns.Focus:Set(card, source, true) end
      cur = card
    end
  end
  -- Focus on a card stays on that card frame (now another macro); remember it.
  if cur and cur.acMacroCard and cur:IsShown() and cur.acId then page.lastFocusId = cur.acId
  elseif page.lastFocusId and page.lastFocusId:find("^macro:") then page.lastFocusId = nil end
  -- A page button that just turned disabled keeps focus (it reads as the
  -- end of the book; another A does nothing), so a second A never turns back.
  -- The focused card now shows another macro, but no focus event fires (the
  -- frame is the same): select it as acOnFocus would, so Y and the prompt
  -- act on the macro on screen, not one from the previous page.
  if cur and cur.acMacroCard and cur.macro and cur:IsShown() and ns.Focus.current == cur
    and ns.Focus.source ~= "mouse" and page.selected ~= cur.macro then
    page.selected = cur.macro
    ns.UI.Refresh()
  end
  if cur then ns.Focus:Inspect(ns.Focus.current) end
  return true
end

local function MakeCard(page, parent, i)
  local row, col = math.floor((i - 1) / COLS) + 1, (i - 1) % COLS + 1
  local c = UI.Card(parent, CARD_W, CARD_H)
  c:SetPoint("TOPLEFT", parent, "TOPLEFT", 8 + (col - 1) * STEP_X, -(row - 1) * STEP_Y)
  c.row, c.col, c.acMacroCard = row, col, true
  c.line:SetWidth(CARD_W - 76 - 12)
  -- State badge, top right: icon + word.
  c.badge = UI.Text(c, "", "GameFontNormal")
  c.badge:SetPoint("TOPRIGHT", c, "TOPRIGHT", -10, -9)
  c.badge:SetJustifyH("RIGHT")
  c.badge:SetWordWrap(false)
  c.badgeIcon = c:CreateTexture(nil, "OVERLAY")
  c.badgeIcon:SetSize(16, 16)
  c.badgeIcon:SetPoint("RIGHT", c.badge, "LEFT", -3, 0)
  c.warn = c:CreateTexture(nil, "OVERLAY")
  c.warn:SetSize(16, 16)
  if not UI.SetAtlas(c.warn, UI.ART.warning) then c.warn:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew") end
  -- Proc flash over the icon (install ceremony).
  c.flash = c:CreateTexture(nil, "OVERLAY", nil, 3)
  c.flash:SetPoint("TOPLEFT", c.iconFrame, "TOPLEFT", -4, 4)
  c.flash:SetPoint("BOTTOMRIGHT", c.iconFrame, "BOTTOMRIGHT", 4, -4)
  if UI.SetAtlas(c.flash, UI.ART.slotFlash) then c.flash:SetBlendMode("ADD") end
  c.flash:SetAlpha(0)
  function c.Flash(self) UI.Anim.Blink(self.flash, 0.5) end

  c:RegisterForDrag("LeftButton")
  c:SetScript("OnDragStart", function(self)
    if self.macro and IsInstalled((L.State(self.macro))) then L.PickUp(self.macro) end
  end)
  c:SetScript("OnClick", function(self)
    if not self.macro then return end
    UI.Sound("activate")
    page.selected = self.macro
    ns.UI.Refresh()
  end)
  c.acInspect = function(self, pane) FillInspector(page, self.macro, pane) end
  -- A / Enter: select; on the macro already selected (D-pad focus selects),
  -- step into the Inspector so its Home links and buttons are reachable
  -- without a mouse. B comes back to this card (page.Back).
  c.acActivate = function(self, source)
    if not self.macro then return end
    UI.Sound("activate")
    local was = page.selected == self.macro
    page.selected = self.macro
    ns.UI.Refresh()
    if not was then return end
    local F = ns.Focus
    F:Inspect(self)
    local best, bestTop
    for _, n in ipairs(F:Nodes()) do
      if F.ZoneOf(n) == "inspector" then
        local top = n.GetTop and n:GetTop() or 0
        if not bestTop or top > bestTop then best, bestTop = n, top end
      end
    end
    if best then F:Set(best, source or "key") end
  end
  -- D-pad / keyboard focus selects (Y and the Inspector act on what you
  -- look at); mouse hover only inspects, a click selects.
  c.acOnFocus = function(self, source)
    if source == "mouse" or not self.macro or page.selected == self.macro then return end
    page.selected = self.macro
    ns.UI.Refresh()
  end
  -- Off the left edge: previous page, mirrored slot; off the right edge: next
  -- page. Stop at the first page's left edge and the last page's right edge.
  -- Inside the grid every move is explicit (spatial scoring would prefer a
  -- nearby tag chip over the card beside this one).
  local function Shown(r, cc)
    local t = page.cards[(r - 1) * COLS + cc]
    return t and t:IsShown() and t or nil
  end
  if col == 1 then
    c.navLeft = function()
      if TurnPage(page, -1) then return CardAt(page, row, COLS) end
      return false
    end
    c.navRight = function()
      local t = Shown(row, col + 1)
      if t then return t end
      if TurnPage(page, 1) then return CardAt(page, row, 1) end
      return false -- the last page's right edge stops, like the first page's left
    end
  else
    c.navLeft = function() return Shown(row, col - 1) end
  end
  if col == COLS then
    c.navRight = function()
      if TurnPage(page, 1) then return CardAt(page, row, 1) end
      return false -- the last page's right edge stops, like the first page's left
    end
  end
  c.navUp = function() return row > 1 and Shown(row - 1, col) or nil end
  c.navDown = function()
    local t = row < ROWS and (Shown(row + 1, col) or Shown(row + 1, 1))
    if t then return t end
    -- Bottom of the page: the page buttons, else the prompt bar (spatial).
    if page.next:IsShown() and page.next:IsEnabled() then return page.next end
    if page.prev:IsShown() and page.prev:IsEnabled() then return page.prev end
    return nil
  end
  return c
end

local function FillCard(page, c, m)
  c.macro = m
  c.acId = "macro:" .. m.name
  page.cardFor[m.name] = c
  local st, _, why = L.State(m)
  c.icon:SetTexture(DisplayIcon(m))
  c.icon:SetDesaturated(st == "blocked" or st == "taken")
  c.icon:SetAlpha(st == "blocked" and 0.6 or 1)
  local word, color = Badge(m, st, why)
  -- Untested: the warning triangle carries a word. Without another badge it
  -- is the badge ("Untested", orange); next to one, the line starts with it.
  local untestedBadge = m.untested and not word
  if untestedBadge then word, color = "Untested", UI.C.ORANGE end
  c.badge:SetText(word or "")
  if color then c.badge:SetTextColor(UI.RGB(color)) end
  c.badge:SetWidth(math.min(math.ceil(c.badge:GetStringWidth()) + 2, 130))
  if word then FitLine(c.badge, word) end
  local hasIcon = st == "installed"
  if hasIcon and not c.badgeArt then
    c.badgeArt = true
    if not UI.SetAtlas(c.badgeIcon, UI.ART.tick) then c.badgeIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready") end
  end
  c.badgeIcon:SetShown(hasIcon)
  local right = (word and c.badge:GetWidth() + 4 or 0) + (hasIcon and 19 or 0)
  local warnAt = untestedBadge and "badge" or right
  if c.warnAt ~= warnAt then
    c.warnAt = warnAt
    c.warn:ClearAllPoints()
    if untestedBadge then c.warn:SetPoint("RIGHT", c.badge, "LEFT", -3, 0)
    else c.warn:SetPoint("TOPRIGHT", c, "TOPRIGHT", -10 - right, -9) end
  end
  if untestedBadge then right = right + 19 end
  c.warn:SetShown(m.untested and true or false)
  local titleW = CARD_W - 76 - 14 - right - ((m.untested and not untestedBadge) and 20 or 0)
  c.title:SetWidth(math.max(titleW, 40))
  FitLine(c.title, Highlight(m.name, page.query, "ffffff"), m.name)
  local desc = m.desc or ""
  if m.untested and not untestedBadge then
    FitLine(c.line, UI.C.ORANGE:WrapTextInColorCode("Untested") .. " · " .. Highlight(desc, page.query, "ffd100"),
      "Untested · " .. desc)
  else
    FitLine(c.line, Highlight(desc, page.query, "ffd100"), desc)
  end
  c:SetSelected(page.selected == m)
  c:Show()
end

-- Tag chips ---------------------------------------------------------------------------

local function ResetFilters(page)
  wipe(page.filters)
  page.query = ""
  if page.search and page.search:GetText() ~= "" then page.search:SetText("") end
  page.pageNum = 1
  ns.UI.Refresh()
end

local function ToggleTag(page, key)
  page.filters[key] = not page.filters[key] or nil
  page.pageNum = 1
  UI.Sound(page.filters[key] and "on" or "off")
  ns.UI.Refresh()
end

local function MakeChip(page, parent)
  local b = CreateFrame("Button", nil, parent)
  b:SetHeight(TAG_H)
  -- A dark plate, as the cards have: the tag row sits on the parchment's
  -- dark top band, where neither gold nor dark ink read (capture, 0.31.0).
  b.plate = b:CreateTexture(nil, "BACKGROUND", nil, -1)
  b.plate:SetAllPoints()
  b.plate:SetTexture(UI.WHITE)
  b.plate:SetVertexColor(0.06, 0.045, 0.03, 0.92)
  b.bg = b:CreateTexture(nil, "BACKGROUND")
  b.bg:SetAllPoints()
  if not UI.SetAtlas(b.bg, UI.ART.rowActive) then b.bg:SetTexture(UI.WHITE); b.bg:SetVertexColor(1, 0.82, 0, 0.14) end
  b.bg:Hide()
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  if not UI.SetAtlas(hl, UI.ART.rowHover) then hl:SetTexture(UI.WHITE); hl:SetVertexColor(1, 1, 1, 0.08) end
  hl:SetBlendMode("ADD")
  -- Every chip shows the Settings panel's check box (checkbox-minimal, the
  -- tick checkmark-minimal on top while the tag is on), so a chip reads as
  -- a filter toggle and turning one on never shifts the chips after it.
  b.box = b:CreateTexture(nil, "ARTWORK")
  b.box:SetSize(16, 16)
  b.box:SetPoint("LEFT", 4, 0)
  b.tick = b:CreateTexture(nil, "ARTWORK", nil, 1)
  b.tick:SetAllPoints(b.box)
  if UI.SetAtlas(b.box, { "checkbox-minimal" }) then
    UI.SetAtlas(b.tick, { "checkmark-minimal" })
  else
    b.box:Hide()
    b.tick:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
  end
  b.text = UI.Text(b, "", "GameFontNormal")  -- gold on the chip's dark plate
  b.text:SetPoint("LEFT", 24, 0)
  b:SetScript("OnClick", function(self) if self.tagKey then ToggleTag(page, self.tagKey) end end)
  UI.Node(b, { style = "chip" })
  b.acInspect = function(self, pane)
    BookHeader(pane, "Interface\\Icons\\INV_Misc_Book_09", "Tag: " .. (self.tagLabel or ""), "Filter")
    pane:Text((self.count or 0) .. " macros here have this tag.")
    pane:Text(page.filters[self.tagKey] and "On: only macros with this tag show. A turns it off."
      or "A shows only macros with this tag. Tags combine.", UI.C.DISABLED)
  end
  return b
end

local function LayoutTags(page)
  local tags, counts = ChipTags(page)
  local maxX = 712 - 8 - page.more:GetWidth() - 8
  -- Each chip is shown or hidden once, and re-laid only when its tag, state
  -- or place changed (no hide-all-then-show on every refresh).
  local x, shownKeys = 8, {}
  for i = 1, MAX_TAG_CHIPS do
    local b = page.chips[i]
    local t = tags[i]
    local show = false
    if t then
      local on = page.filters[t.key] == true
      if b.tagKey ~= t.key or b.tagOn ~= on or b.tagLabel ~= t.label then
        b.text:SetText(t.label)
        b.text:SetFontObject(on and "GameFontHighlight" or "GameFontNormal")
        b.tick:SetShown(on)
        b.bg:SetShown(on)
        local w = math.ceil(b.text:GetStringWidth()) + 32
        if b.tagW ~= w then b.tagW = w; b.tagX = nil end
      end
      b.tagKey, b.tagLabel, b.tagOn, b.count = t.key, t.label, on, counts[t.key]
      local w = b.tagW
      if x + w <= maxX then
        if b.tagX ~= x then
          b.tagX = x
          b:SetWidth(w)
          b:ClearAllPoints()
          b:SetPoint("TOPLEFT", page.frame, "TOPLEFT", x, TAG_Y)
        end
        b.acId = "tag:" .. t.key
        show = true
        shownKeys[t.key] = true
        x = x + w + 4
      end
    end
    if not show then b.acId = nil end
    if b:IsShown() ~= show then b:SetShown(show) end
  end
  -- More... counts the filters that have no chip of their own.
  local hidden = 0
  for key in pairs(page.filters) do if not shownKeys[key] then hidden = hidden + 1 end end
  local label = hidden > 0 and ("More (" .. hidden .. ")") or "More..."
  if page.more.SetText then page.more:SetText(label) end
  if page.more.GenerateMenu then page.more:GenerateMenu() end
end

local TYPE_TITLES = { class = "Class", race = "Race", profession = "Profession", topic = "Topic", status = "Status" }

local function MoreMenu(page)
  return function(_, root)
    local tags, counts = AvailableTags(page)
    table.sort(tags, function(a, b)
      local oa, ob = L.tagTypes[a.type].order, L.tagTypes[b.type].order
      if oa ~= ob then return oa < ob end
      return a.label < b.label
    end)
    local lastType
    for _, t in ipairs(tags) do
      if t.type ~= lastType then
        if lastType and root.CreateDivider then root:CreateDivider() end
        root:CreateTitle(TYPE_TITLES[t.type] or t.type)
        lastType = t.type
      end
      root:CreateCheckbox(t.label .. " (" .. counts[t.key] .. ")",
        function(key) return page.filters[key] == true end,
        function(key) ToggleTag(page, key) end, t.key)
    end
    if next(page.filters) or page.query ~= "" then
      if root.CreateDivider then root:CreateDivider() end
      root:CreateButton("Clear tags and search", function() ResetFilters(page) end)
    end
  end
end

-- Search ----------------------------------------------------------------------------

local function FocusFirstCard(page)
  local c = page.cards[1]
  if c and c:IsShown() then ns.Focus:Set(c, "key") end
end

local function BuildSearch(page, f)
  local holder = CreateFrame("Frame", nil, f)
  holder.acZone = "view"
  holder:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, -6)
  holder:SetSize(SEARCH_W, 28)
  holder:SetFrameLevel(f:GetFrameLevel() + 12)
  local box = CreateFrame("EditBox", nil, holder, UI.Has("SearchBoxTemplate") and "SearchBoxTemplate" or "InputBoxTemplate")
  box:SetAllPoints()
  box:SetAutoFocus(false)
  if box.Instructions and box.Instructions.SetText then box.Instructions:SetText(SEARCH or "Search") end
  page.searchGen = 0
  box:HookScript("OnTextChanged", function(self)
    page.searchGen = page.searchGen + 1
    local gen = page.searchGen
    After(0.15, function()
      if gen ~= page.searchGen then return end
      local q = Trim(self:GetText()):lower()
      if q == page.query then return end
      page.query = q
      page.pageNum = 1
      ns.UI.Refresh()
    end)
  end)
  -- Esc: the first press clears the text, the second leaves the box.
  box:SetScript("OnEscapePressed", function(self)
    if self:GetText() ~= "" then self:SetText("") else self:ClearFocus() end
  end)
  box:SetScript("OnEnterPressed", function(self) self:ClearFocus(); FocusFirstCard(page) end)
  box:HookScript("OnArrowPressed", function(self, key)
    if key == "DOWN" then self:ClearFocus(); FocusFirstCard(page) end
  end)
  UI.Node(box, { style = "row", id = "macros:search", activate = function(self) self:SetFocus() end })
  box.navDown = function() return page.chips[1]:IsShown() and page.chips[1] or page.cards[1] end
  box.acInspect = function(_, pane)
    BookHeader(pane, "Interface\\Icons\\INV_Misc_Spyglass_03", "Search", "Macros")
    pane:Text("Finds macros by name, description and tag. A or Ctrl+F types; Enter or Down goes to the results; Esc clears, then leaves.")
  end
  page.search = box
end

-- Page ----------------------------------------------------------------------------------

local function SetScope(page, all)
  page.showAll = all
  page.entries = L.Entries(all)
  local tags = {}
  for _, t in ipairs((AvailableTags(page))) do tags[t.key] = true end
  for key in pairs(page.filters) do if not tags[key] then page.filters[key] = nil end end
  page.pageNum = 1
end

local function ReviewRecommended(page)
  local install, update = {}, {}
  for _, m in ipairs(Recommended()) do
    local st = L.State(m)
    local item = { key = m.perCharacter and "Character" or "General",
      nowName = st == "update" and "Older text" or "Not installed",
      afterIcon = DisplayIcon(m), afterName = m.name,
      note = m.untested and "untested" or (st == "update" and "newer text" or nil),
      color = m.untested and UI.C.ORANGE or UI.C.ADDED }
    if st == "update" then update[#update + 1] = item else install[#install + 1] = item end
  end
  local groups = {}
  if #install > 0 then groups[#groups + 1] = { title = "WILL INSTALL", items = install } end
  if #update > 0 then groups[#groups + 1] = { title = "WILL UPDATE", items = update } end
  page.reviewList = Recommended()
  return groups
end

local macrosPage = ns.RegisterPage({
  id = "macros",
  api = 2,
  title = "Macros",
  icon = "Interface\\Icons\\INV_Misc_Book_09",
  order = 30,
  aliases = { "library" },
  description = "Your macro book. Macros for your class, race and professions; install one, then put it on a bar. "
    .. "Installing never overwrites a macro of your own.",
  views = { { key = "you", label = "For You" }, { key = "all", label = "Everything" } },
  view = "you",
  viewLabel = "Scope",
  reviewLabel = "Install recommended",
  reviewNote = "Only missing or outdated library macros are written. A macro of your own with the same name is never touched.",
  hideDivider = true, -- the stage and the Inspector read as one open book

  -- PgUp/PgDn turn the book, Home/End jump to the first or last page; focus
  -- stays on the same card slot (Focus:ListJump hands these keys to the page).
  ListJump = function(page, kind)
    local n = PageCount(page)
    local delta
    if kind == "PAGEUP" then delta = -1
    elseif kind == "PAGEDOWN" then delta = 1
    elseif kind == "HOME" then delta = 1 - page.pageNum
    elseif kind == "END" then delta = n - page.pageNum end
    if not delta then return false end
    if delta ~= 0 then TurnPage(page, delta) end
    return true
  end,

  Build = function(page, f, pane)
    page.filters, page.cards, page.chips, page.cardFor = {}, {}, {}, {}
    page.query, page.showAll, page.pageNum = "", false, 1
    page.entries = L.Entries(false)
    page.pane = pane

    -- Left page of the book; the right page dresses the Inspector while shown.
    local bg = f:CreateTexture(nil, "BACKGROUND", nil, 2)
    bg:SetPoint("TOPLEFT", 3, -3); bg:SetPoint("BOTTOMRIGHT", -3, 3)
    if not UI.SetAtlas(bg, BOOK_LEFT) then
      bg:Hide()
      page.paper = UI.Gradient(f, "BACKGROUND", "VERTICAL", { 0.10, 0.07, 0.04, 0.85 }, { 0.20, 0.15, 0.09, 0.55 }, 2)
      page.paper:SetPoint("TOPLEFT", 3, -3); page.paper:SetPoint("BOTTOMRIGHT", -3, 3)
    end
    page.bg = bg
    -- No right book page under the Inspector: on light parchment the state
    -- colours (red, orange, grey) clashed in game. The Inspector keeps the
    -- same dark pane on every page (dev/ui-rules.md §19).
    page.right, bookRight = nil, nil

    BuildSearch(page, f)

    -- Tag row (zone "view": Up from the book's top row lands here).
    local tagRow = CreateFrame("Frame", nil, f)
    tagRow.acZone = "view"
    tagRow:SetAllPoints()
    tagRow:SetFrameLevel(f:GetFrameLevel() + 11)
    tagRow:EnableMouse(false)
    for i = 1, MAX_TAG_CHIPS do page.chips[i] = MakeChip(page, tagRow) end
    page.more = UI.Filter(tagRow, MoreMenu(page), "More...")
    page.more:SetSize(96, TAG_H)
    page.more:SetPoint("TOPRIGHT", f, "TOPRIGHT", -12, TAG_Y)
    -- WowStyle1FilterDropdownTemplate pins its Text to TOP for its native
    -- 18 px height; at the 28 px pad-target height that left the label high
    -- above the arrow. Centre it vertically.
    local moreText = rawget(page.more, "Text")
    if type(moreText) == "table" and moreText.ClearAllPoints then
      moreText:ClearAllPoints()
      moreText:SetPoint("CENTER", page.more, "CENTER", 0, -1)
    end
    UI.Node(page.more, { style = "button", id = "macros:more" })
    page.more.acInspect = function(_, pane2)
      BookHeader(pane2, "Interface\\Icons\\INV_Misc_Book_09", "Every tag", "Filter")
      pane2:Text("Opens the full tag list: class, race, profession, topic and status. Tags combine.")
    end

    -- The book: 12 cards, then the page buttons.
    page.book = CreateFrame("Frame", nil, f)
    page.book:SetPoint("TOPLEFT", f, "TOPLEFT", 0, BOOK_TOP)
    page.book:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, NAV_H + 16)
    page.book:EnableMouseWheel(true)
    page.book:SetScript("OnMouseWheel", function(_, delta) TurnPage(page, delta > 0 and -1 or 1) end)
    for i = 1, PER_PAGE do page.cards[i] = MakeCard(page, page.book, i) end

    page.empty = UI.Empty(page.book, "No macros match these tags.", "Clear tags", function() ResetFilters(page) end)
    page.empty.button.acId = "macros:clear"

    local nav = CreateFrame("Frame", nil, f)
    nav:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 10)
    nav:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 10)
    nav:SetHeight(NAV_H)
    nav:EnableMouseWheel(true)
    nav:SetScript("OnMouseWheel", function(_, delta) TurnPage(page, delta > 0 and -1 or 1) end)
    -- As the spellbook lays it out: the page buttons fixed at the bottom
    -- right, "Page n of m · chapters" right-aligned before them (centred
    -- text moved the buttons whenever its width changed). The text never
    -- runs past its box; the client cuts it with "...".
    page.pageText = UI.Ink(UI.Text(nav, "", "GameFontNormal"))  -- on the parchment
    page.pageText:SetJustifyH("RIGHT")
    page.pageText:SetWordWrap(false)
    page.pageText:SetWidth(440)
    local function PageButton(path, delta, id)
      local b = CreateFrame("Button", nil, nav)
      b:SetSize(NAV_H, NAV_H)
      b:SetNormalTexture(path .. "-Up")
      b:SetPushedTexture(path .. "-Down")
      b:SetDisabledTexture(path .. "-Disabled")
      b:SetScript("OnClick", function() TurnPage(page, delta) end)
      UI.Node(b, { style = "slot", id = id })
      -- Stays focusable when disabled at the end of the book (A does nothing
      -- there; TurnPage returns false), so focus never jumps to the twin.
      b.acReadable = true
      b.acInspect = function(self, pane2)
        BookHeader(pane2, "Interface\\Icons\\INV_Misc_Book_09", delta < 0 and "Previous page" or "Next page",
          "Page " .. page.pageNum .. " of " .. PageCount(page))
        if not self:IsEnabled() then
          pane2:Text(delta < 0 and "This is the first page." or "This is the last page.", UI.C.NORMAL)
        end
        pane2:Text("The mouse wheel, and Left or Right off the edge of the book, turn pages too.", UI.C.DISABLED)
      end
      return b
    end
    page.prev = PageButton(PAGE_PREV, -1, "macros:prev")
    page.next = PageButton(PAGE_NEXT, 1, "macros:next")
    page.next:SetPoint("RIGHT", nav, "RIGHT", -12, 0)
    page.prev:SetPoint("RIGHT", page.next, "LEFT", -4, 0)
    page.pageText:SetPoint("RIGHT", page.prev, "LEFT", -8, 0)
    -- Up from the page buttons: the last card in that column.
    local function LastIn(col)
      for i = PER_PAGE - COLS + col, 1, -COLS do
        if page.cards[i]:IsShown() then return page.cards[i] end
      end
    end
    page.prev.navUp = function() return LastIn(1) end
    page.next.navUp = function() return LastIn(COLS) or LastIn(1) end
    page.prev.navRight = function() return page.next:IsEnabled() and page.next or nil end
    page.next.navLeft = function() return page.prev:IsEnabled() and page.prev or nil end
  end,

  Refresh = function(page) return Refresh(page) end,

  Status = function()
    local acct, char = 0, 0
    if GetNumMacros then acct, char = GetNumMacros() end
    local text = string.format("General %d/%d  ·  Character %d/%d",
      acct or 0, MAX_ACCOUNT_MACROS or 120, char or 0, MAX_CHARACTER_MACROS or 18)
    local rec = #Recommended()
    if rec > 0 then text = text .. "  ·  " .. UI.C.ADDED:WrapTextInColorCode(rec .. " recommended") end
    return text, "Macros in use: General (every character) and Character (this character only)."
  end,

  -- In place: recommended macros installed, out of every macro for you
  -- that can be installed (untested ones only count once installed).
  readiness = function()
    local done, total = 0, 0
    for _, m in ipairs(L.Entries(false)) do
      local st = L.State(m)
      if st == "installed" then done, total = done + 1, total + 1
      elseif (st == "ready" or st == "update") and not m.untested then total = total + 1 end
    end
    if total == 0 then return nil end
    return done, total
  end,

  prompts = function() return { { key = "PAD1", label = "Select" }, { key = "PAD3", label = "Scope" } } end,

  OnView = function(page, key) SetScope(page, key == "all") end,

  -- B inside the Inspector (entered with A on a card) goes back to that card.
  Back = function(page)
    local F = ns.Focus
    if not (F and F.current and F.ZoneOf(F.current) == "inspector") then return false end
    local card = page.selected and page.cardFor and page.cardFor[page.selected.name]
    if not (card and card:IsShown() and card.macro == page.selected) then return false end
    F:Set(card, F.source or "pad")
    return true
  end,

  Search = function(page) if page.search then page.search:SetFocus() end end,

  DefaultFocus = function(page)
    local sel = page.selected and page.cardFor[page.selected.name]
    if sel and sel:IsShown() and sel.macro == page.selected then return sel end
    if page.cards[1]:IsShown() then return page.cards[1] end
    return page.empty.button
  end,

  DefaultInspect = function(page, pane) FillInspector(page, page.selected, pane) end,

  -- Right stick: the cards are paged, never scrolled, so the stick always
  -- reads the Inspector (its macro body overflows on long macros, §4.5).
  ScrollRegion = function(page) return page.pane and page.pane.scroll or nil end,

  Commit = function(page)
    local list = page.reviewList or Recommended()
    L.Install(list)
    local ids = {}
    for _, m in ipairs(list) do
      if IsInstalled((L.State(m))) then ids[#ids + 1] = "macro:" .. m.name end
    end
    return nil, nil, ids
  end,
})

-- ns.OpenPage("macros", "macro:<name>") (a cross-reference from another page)
-- sets page.lastFocusId after the refresh and then looks for that node. A
-- macro on another page of the book has no card yet, so writing such an id
-- turns the book to it first. lastFocusId lives in a backing field so every
-- write passes through here (the focus core writes it on each move).
local lastFocusKey = "_acLastFocusId"
setmetatable(macrosPage, {
  __index = function(t, k) if k == "lastFocusId" then return rawget(t, lastFocusKey) end end,
  __newindex = function(t, k, v)
    if k ~= "lastFocusId" then return rawset(t, k, v) end
    rawset(t, lastFocusKey, v)
    local want = type(v) == "string" and v:match("^macro:(.+)$")
    if not want or t.turning or not t.shown or not t.cardFor or t.cardFor[want] then return end
    for i, m in ipairs(t.shown) do
      if m.name == want then
        local n = math.floor((i - 1) / PER_PAGE) + 1
        if n ~= t.pageNum then
          t.pageNum = n
          ns.UI.Refresh()
        end
        return
      end
    end
  end,
})

-- Y: install the selected macro directly while it can be installed, else
-- install every recommended macro through the Review sheet. The shell reads
-- page.Review / page.primary each time it lays out the prompts.
local primaryInstall = {
  label = function(p)
    local m = SelectedInstallable(p)
    return m and ((L.State(m) == "update" and "Update " or "Install ") .. m.name) or "Install"
  end,
  enabled = function(p) return SelectedInstallable(p) ~= nil end,
  -- DoPrimary already runs this through UI.RunAction.
  fn = function(p)
    local m = SelectedInstallable(p)
    if not m then return end
    L.Install({ m })
    if IsInstalled((L.State(m))) then
      UI.Sound("installed")
      local card = p.cardFor[m.name]
      if card and card.Flash then card:Flash() end
    end
  end,
}

Refresh = function(page)
  L.Invalidate()
  if SelectedInstallable(page) then
    page.Review, page.primary = nil, primaryInstall
  else
    page.Review, page.primary = ReviewRecommended, nil
  end

  page.shown = Filtered(page)
  local shown = page.shown
  page.anyShown = #shown > 0
  -- A selection the filters hide is dropped; the first match is selected.
  local keep = false
  for _, m in ipairs(shown) do if m == page.selected then keep = true break end end
  if not keep then page.selected = shown[1] end

  -- Focus that names a macro on another page (a cross-reference, or a
  -- refresh after a filter change) opens that page of the book.
  local want = page.lastFocusId and page.lastFocusId:match("^macro:(.+)$")
  if want and not page.turning then
    for i, m in ipairs(shown) do
      if m.name == want then page.pageNum = math.floor((i - 1) / PER_PAGE) + 1 break end
    end
  end
  local n = PageCount(page)
  page.pageNum = math.max(1, math.min(n, page.pageNum or 1))

  LayoutTags(page)
  wipe(page.cardFor)
  local first = (page.pageNum - 1) * PER_PAGE
  for i = 1, PER_PAGE do
    local m = shown[first + i]
    local c = page.cards[i]
    if m then FillCard(page, c, m) else c.macro = nil; c.acId = nil; c:Hide() end
  end
  if page.right then page.right:Show() end

  local filtered = next(page.filters) ~= nil or page.query ~= ""
  page.empty:SetShown(#shown == 0)
  if #shown == 0 then
    page.empty:SetText(page.query ~= "" and ("No macros match \"" .. page.query .. "\".")
      or filtered and "No macros match these tags." or "No macros for this character yet. Try Everything.")
    page.empty:SetButton(filtered and (page.query ~= "" and "Clear search and tags" or "Clear tags") or nil,
      function() ResetFilters(page) end)
  end
  -- "Page 1 of 3 · Combat, Pet": the chapters on this spread.
  local chapters, seen = {}, {}
  for i = first + 1, math.min(first + PER_PAGE, #shown) do
    local cat = shown[i].category
    if not seen[cat] then seen[cat] = true; chapters[#chapters + 1] = CategoryTitle(cat) end
  end
  page.pageText:SetText(#shown == 0 and "" or ("Page " .. page.pageNum .. " of " .. n
    .. (#chapters > 0 and ("  ·  " .. UI.C.INK:WrapTextInColorCode(table.concat(chapters, ", "))) or "")))
  page.prev:SetEnabled(page.pageNum > 1)
  page.next:SetEnabled(page.pageNum < n)
  page.prev:SetShown(n > 1)
  page.next:SetShown(n > 1)
end

ns.RegisterCommand("macros", "open the Macros page", function() ns.OpenPage("macros") end, { usage = "macros" })
