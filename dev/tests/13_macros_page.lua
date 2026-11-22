-- Macros page v2 (dev/ui-spec-v2.md §9.4): the spellbook spread. Focus lands
-- on the first card, arrows walk the grid and turn the book at its edges onto
-- the mirrored slot, PgUp/PgDn/Home/End and the wheel turn pages, filters and
-- search narrow the book, Y installs, Review installs exactly the
-- recommended list, and a cross-reference opens the macro's page.
local H = require("harness")

local function Boot(opts)
  opts = opts or {}
  opts.db = opts.db or { lastPage = "macros" }
  local env = H.boot(opts)
  env:slash("")
  env:runTimers(1)
  return env, env.ns.PageById("macros")
end

local function Key(env, key)
  local f = env.G.AgentcraftFrame
  f:GetScript("OnKeyDown")(f, key)
  local consumed = f._propagate == false
  f:GetScript("OnKeyUp")(f, key)
  return consumed
end

test("macros: opens as the v2 book with the first card focused and selected", function()
  local env, page = Boot()
  ok(page and page.api == 2, "v2 page")
  ok(page.frame:IsShown(), "page shown")
  eq(env.ns.Focus.current, page.cards[1], "first card focused")
  ok(page.selected, "a macro is selected")
  ok(#page.shown > 12, "the fixture fills more than one page: " .. #page.shown)
  noErrors(env)
end)

test("macros: arrows walk the grid; the right edge turns onto the mirrored slot and back", function()
  local env, page = Boot()
  local Focus = env.ns.Focus
  Key(env, "TAB")
  Key(env, "RIGHT")
  eq(Focus.current, page.cards[2], "Right -> card 2")
  eq(page.selected, page.cards[2].macro, "focus selects")
  Key(env, "DOWN")
  eq(Focus.current, page.cards[4], "Down -> card 4")
  local before = page.cards[4].macro
  Key(env, "RIGHT")
  eq(page.pageNum, 2, "turned to page 2")
  eq(Focus.current, page.cards[3], "landed on row 2, left column")
  ok(page.cards[3].macro ~= before, "new macros on the page")
  Key(env, "LEFT")
  eq(page.pageNum, 1, "back to page 1")
  eq(Focus.current, page.cards[4], "mirrored: row 2, right column")
  Key(env, "LEFT"); Key(env, "LEFT")
  eq(page.pageNum, 1, "the first page's left edge stops")
  eq(Focus.current, page.cards[3], "stays on the left column")
  noErrors(env)
end)

test("macros: Up from the top row reaches the view zone; Down from the last row reaches the page buttons", function()
  local env, page = Boot()
  local Focus = env.ns.Focus
  Key(env, "TAB")
  Key(env, "UP")
  eq(Focus.ZoneOf(Focus.current), "view", "tag row: " .. tostring(Focus.current.acId))
  Key(env, "DOWN")
  eq(Focus.current, page.cards[1], "Down from the tags -> first card")
  for _ = 1, 6 do Key(env, "DOWN") end
  ok(Focus.current == page.next or Focus.current == page.prev, "page button: " .. tostring(Focus.current.acId))
  Key(env, "UP")
  ok(Focus.current.acMacroCard, "Up from the page button -> a card")
  noErrors(env)
end)

test("macros: PgDn/PgUp turn the book, End/Home jump to the last/first page, focus stays on its slot", function()
  local env, page = Boot()
  local Focus = env.ns.Focus
  Key(env, "TAB")
  Key(env, "RIGHT")
  local slot = Focus.current
  ok(Key(env, "PAGEDOWN"), "PgDn consumed")
  eq(page.pageNum, 2, "PgDn -> page 2")
  eq(Focus.current, slot, "same card slot")
  Key(env, "PAGEUP")
  eq(page.pageNum, 1, "PgUp -> page 1")
  Key(env, "END")
  local last = math.ceil(#page.shown / 12)
  eq(page.pageNum, last, "End -> last page")
  ok(env.ns.Focus.Usable(Focus.current), "focus usable on the last page")
  Key(env, "HOME")
  eq(page.pageNum, 1, "Home -> first page")
  noErrors(env)
end)

test("macros: the wheel turns pages; a refresh keeps the page", function()
  local env, page = Boot()
  local f = page.book
  f:GetScript("OnMouseWheel")(f, -1)
  eq(page.pageNum, 2, "wheel down -> page 2")
  env.ns.UI.Refresh()
  eq(page.pageNum, 2, "a refresh keeps the page")
  f:GetScript("OnMouseWheel")(f, 1)
  eq(page.pageNum, 1)
  noErrors(env)
end)

test("macros: tags and search filter; the empty state offers a focusable Clear", function()
  local env, page = Boot()
  local n = #page.shown
  page.chips[1]:Click()
  ok(#page.shown < n and #page.shown > 0, "tag narrows " .. n .. " -> " .. #page.shown)
  page.search:SetText("zzzz-nothing")
  page.search:GetScript("OnTextChanged")(page.search)
  env:runTimers(1)
  eq(#page.shown, 0, "nothing matches")
  ok(page.empty:IsShown(), "empty state")
  ok(env.ns.Focus.Usable(page.empty.button), "Clear is a focus target")
  page.empty.button:Click()
  eq(#page.shown, n, "cleared")
  noErrors(env)
end)

test("macros: Y installs the selected ready macro, then means Review", function()
  local env, page = Boot()
  local L = env.ns.MacroLibrary
  local target
  for _, c in ipairs(page.cards) do if c:IsShown() and L.State(c.macro) == "ready" then target = c break end end
  ok(target, "a ready card")
  env.ns.Focus:Set(target, "key")
  ok(page.primary and not page.Review, "direct install mode")
  env.G.AgentcraftPadY:Click()
  eq(L.State(target.macro), "installed", "installed " .. target.macro.name)
  ok(page.Review and not page.primary, "review mode after the install")
  noErrors(env)
end)

test("macros: Review then Commit writes exactly the recommended list; OpenPage turns to a macro", function()
  local env, page = Boot()
  local L = env.ns.MacroLibrary
  page.selected = nil
  for _, m in ipairs(page.shown) do
    local st = L.State(m)
    if st ~= "ready" and st ~= "update" then page.selected = m break end
  end
  env.ns.UI.Refresh()
  ok(page.Review, "review mode")
  page.Review(page)
  local rec = #page.reviewList
  ok(rec > 0, "something to install")
  env.ns.UI.OpenReview()
  env.ns.UI.Commit()
  eq(#env:calls("CreateMacro") + #env:calls("EditMacro"), rec, "writes exactly the recommended")
  local last = page.shown[#page.shown]
  env.ns.OpenPage("macros", "macro:" .. last.name)
  env:runTimers(1)
  eq(page.pageNum, math.ceil(#page.shown / 12), "turned to the macro's page")
  eq(env.ns.Focus.current.macro, last, "focus on it")
  noErrors(env)
end)

test("macros: the first Esc in the search box clears it", function()
  local env, page = Boot()
  local box = page.search
  box:SetText("pet")
  box:GetScript("OnEscapePressed")(box)
  eq(box:GetText(), "", "first Esc clears")
  noErrors(env)
end)

-- A pane stand-in that records what the Inspector would show.
local function FakePane()
  local p = { sections = {}, refs = {}, texts = {} }
  local cur
  function p:Header() end
  function p:Row() end
  function p:Code() end
  function p:Buttons() end
  function p:Empty() end
  function p:Text(t) if t then p.texts[#p.texts + 1] = t end end
  function p:Section(s) cur = s; p.sections[#p.sections + 1] = s; p.refs[s] = {} end
  function p:CrossRef(list) for _, r in ipairs(list) do table.insert(p.refs[cur or "?"], r) end end
  return p
end

local function CardOf(_, page, name)
  for _ = 1, 4 do
    for _, c in ipairs(page.cards) do if c:IsShown() and c.macro and c.macro.name == name then return c end end
    page.next:Click()
  end
end

test("macros: End from card 12 onto the short last page keeps focus on a shown card and selects it", function()
  local env, page = Boot()
  -- The fixture's professions add profession macros to For You; without
  -- them the book has a different length, so one of the two ends short.
  if #page.shown % 12 == 0 then env, page = Boot({ setup = function(W) W.fixture.professions = nil end }) end
  local Focus = env.ns.Focus
  ok(#page.shown % 12 ~= 0 and #page.shown % 12 < 12, "the last page is short: " .. #page.shown)
  Key(env, "TAB")
  Focus:Set(page.cards[12], "key")
  Key(env, "END")
  eq(page.pageNum, math.ceil(#page.shown / 12), "last page")
  ok(Focus.current and Focus.current.acMacroCard and Focus.current:IsShown(), "focus on a shown card: " .. tostring(Focus.current and Focus.current.acId))
  eq(page.selected, Focus.current.macro, "the selection is the macro on screen")
  eq(page.lastFocusId, "macro:" .. Focus.current.macro.name, "remembers the shown card")
  noErrors(env)
end)

test("macros: A on Next up to the last page keeps focus on Next; Right off the last card stops", function()
  local env, page = Boot()
  local Focus = env.ns.Focus
  local last = math.ceil(#page.shown / 12)
  Key(env, "TAB")
  Focus:Set(page.next, "key")
  for _ = 1, last + 2 do Key(env, "ENTER") end
  eq(page.pageNum, last, "on the last page")
  eq(Focus.current, page.next, "focus stays on Next")
  local n = #page.shown - (last - 1) * 12
  Focus:Set(page.cards[n], "key")
  Key(env, "RIGHT")
  if n % 2 == 0 then eq(Focus.current, page.cards[n], "the last page's right edge stops") end
  ok(Focus.current.acMacroCard, "still in the grid")
  noErrors(env)
end)

test("macros: the Inspector names the layout's homes by key and glyph", function()
  local env, page = Boot()
  local c = CardOf(env, page, "Opener")
  ok(c, "Opener card")
  local pane = FakePane()
  c.acInspect(c, pane)
  local homes = pane.refs["Home"]
  ok(homes and #homes >= 2, "a Home section with keyboard and controller")
  local kb, pad
  for _, r in ipairs(homes) do
    if r.text:find("^Keyboard:") and r.text:find("1", 1, true) then kb = r end
    if r.text:find("^Controller:") then pad = r end
  end
  ok(kb, "keyboard 1")
  ok(pad and not pad.text:find("Action bar"), "controller chord: " .. tostring(pad and pad.text))
  for _, t in ipairs(pane.texts) do ok(not t:find("Pick Up, then click"), "no hand placement hint for a homed macro") end
  pad.fn()
  eq(env.ns.UI.CurrentPage and env.ns.UI.CurrentPage() and env.ns.UI.CurrentPage().id or env.ns.PageById("controller").frame:IsShown() and "controller", "controller", "the link opens the Controller page")
  noErrors(env)
end)

test("macros: untested cards carry the word Untested", function()
  local env, page = Boot()
  local c = CardOf(env, page, "Melee")
  ok(c, "Melee card")
  local shown = (c.badge:GetText() or "") .. " " .. (c.line:GetText() or "")
  ok(shown:find("Untested", 1, true), "labelled: " .. shown)
  noErrors(env)
end)

test("macros: A on the selected card steps into the Inspector; B comes back to the card", function()
  local env, page = Boot()
  local Focus = env.ns.Focus
  Key(env, "TAB")
  Focus:Set(page.cards[1], "key")
  env:runTimers(1)
  eq(page.selected, page.cards[1].macro, "focus selected card 1")
  Key(env, "ENTER")
  eq(Focus.ZoneOf(Focus.current), "inspector", "A enters the Inspector: " .. tostring(Focus.current and Focus.current.acId))
  env.G.AgentcraftPadB:Click()
  eq(Focus.current, page.cards[1], "B returns to the card")
  ok(env.G.AgentcraftFrame:IsShown(), "window still open")
  noErrors(env)
end)
