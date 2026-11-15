-- The v2 input model (dev/ui-spec-v2.md §4-5): override bindings, keyboard
-- engaged mode and propagation, the Back stack, focus moves and restore,
-- scroll-follows-focus, glyphs, and the native-style controller bar.
local H = require("harness")
local layout = require("layout")

local function Rect(env, obj) return layout.New(env.W, { w = 1280, h = 800 }):Rect(obj) end

-- A v2 test page: a 3x3 grid of buttons (acId "b1".."b9"), a scroll list of
-- 40 rows, and a Review with two items.
local function GridPage(extra)
  local page = { id = "zgrid", title = "Grid", api = 2, order = 1 }
  page.views = { { key = "one", label = "One" }, { key = "two", label = "Two" } }
  page.Build = function(p, stage)
    local UI = p.ns.UI
    p.buttons = {}
    for i = 1, 9 do
      local b = UI.Button(stage, "B" .. i, 80, function() p.clicked = i end, nil, 28)
      b:SetPoint("TOPLEFT", 20 + ((i - 1) % 3) * 100, -60 - math.floor((i - 1) / 3) * 50)
      b.acId = "b" .. i
      p.buttons[i] = b
    end
    local host = p.ns.UI.Plate(stage)
    host:SetPoint("TOPLEFT", 360, -60)
    host:SetSize(300, 200)
    p.list = UI.ScrollList(host, 30, function(parent)
      local r = p.G.CreateFrame("Button", nil, parent)
      r.text = UI.Text(r, "", "GameFontHighlight")
      r.text:SetPoint("LEFT", 6, 0)
      return r
    end, function(r, d) r.text:SetText(d); r.acId = "row:" .. d end)
    local data = {}
    for i = 1, 40 do data[i] = "Row " .. i end
    p.list:SetData(data)
  end
  page.DefaultFocus = function(p) return p.buttons[1] end
  page.Review = function()
    return { { title = "WILL PLACE", items = { { key = "Q", afterName = "Arcane Shot" }, { key = "E", afterName = "Serpent Sting" } } } }
  end
  page.Commit = function(p) p.committed = (p.committed or 0) + 1; return "Applied 2 changes.", nil, { "b1", "b2" } end
  for k, v in pairs(extra or {}) do page[k] = v end
  return page
end

local function Boot(opts, extra)
  opts = opts or {}
  local page = GridPage(extra)
  local setup = opts.setup
  opts.setup = function(W) W.gamepadUI = W.gamepadUI; if setup then setup(W) end end
  opts.loaded = function(env) page.ns, page.G = env.ns, env.G; env.ns.RegisterPage(page) end
  opts.db = opts.db or { lastPage = "zgrid" }
  local env = H.boot(opts)
  env:slash("")
  env:runTimers(1)
  return env, page
end

local function Key(env, key)
  local f = env.G.AgentcraftFrame
  f:GetScript("OnKeyDown")(f, key)
  local consumed = f._propagate == false
  f:GetScript("OnKeyUp")(f, key)
  return consumed
end

test("overrides: chords and the full pad set while open (controller, no Gamepad UI); never F13-F16; cleared on close", function()
  local env = Boot()
  local o = env.W.overrides
  for _, k in ipairs({ "CTRL-TAB", "CTRL-SHIFT-TAB", "CTRL-ENTER", "CTRL-SPACE", "CTRL-1", "CTRL-5", "PAD1", "PAD2", "PAD3",
                       "PAD4", "PADLSHOULDER", "PADRSHOULDER", "PADDUP", "PADDLEFT" }) do
    ok(o[k], k .. " bound while open")
  end
  for _, k in ipairs({ "F13", "F14", "F15", "F16" }) do eq(o[k], nil, k .. " (back paddle) never bound by the window") end
  eq(o.PAD4.command, "CLICK AgentcraftPadY:LeftButton")
  env:slash("")
  eq(next(env.W.overrides), nil, "all cleared on close")
  noErrors(env)
end)

test("overrides: with the Gamepad UI and FCM, pad keys only while FCM focus is held (X, Y, LB, RB; never A/B/D-pad)", function()
  local env = Boot({ setup = function(W)
    W.gamepadUI = true
    W.api.GamepadMode = { FrameControlsManager = { FrameShown = function() end, FrameHidden = function() end } }
  end })
  local f = env.G.AgentcraftFrame
  local o = env.W.overrides
  eq(o.PAD4, nil, "no Y before FocusGamepad")
  ok(o["CTRL-TAB"], "keyboard chords still bound")
  f.FocusGamepad()
  ok(o.PAD4 and o.PAD3 and o.PADLSHOULDER and o.PADRSHOULDER, "X, Y, LB, RB bound with focus")
  eq(o.PAD1, nil, "A stays SmartNavigation's"); eq(o.PAD2, nil, "B stays FCM's"); eq(o.PADDUP, nil, "D-pad stays SmartNavigation's")
  f.UnfocusGamepad()
  eq(o.PAD4, nil, "released with focus")
  eq(f.SmartNavigationCloseHandler(), false, "empty Back stack: FCM closes the window")
  noErrors(env)
end)

test("combat: overrides cleared and keyboard released on REGEN_DISABLED; a hide in combat stays clean; rebinds after", function()
  local env = Boot()
  local f = env.G.AgentcraftFrame
  ok(next(env.W.overrides), "bound before combat")
  env:fire("PLAYER_REGEN_DISABLED")
  env.W.inCombat = true
  eq(next(env.W.overrides), nil, "cleared when combat starts")
  ok(not f:IsKeyboardEnabled(), "keyboard released")
  ok(f:GetPropagateKeyboardInput(), "keys propagate")
  eq(Key(env, "TAB"), false, "nothing consumed in combat")
  f:Hide()
  env.W.inCombat = false
  env:fire("PLAYER_REGEN_ENABLED")
  eq(next(env.W.overrides), nil, "still nothing bound after combat (window closed)")
  env:slash("")
  ok(env.W.overrides["CTRL-TAB"], "bound again on the next open")
  ok(f:IsKeyboardEnabled(), "keyboard back")
  noErrors(env)
end)

test("keyboard: nothing consumed until Tab; arrows move, Enter activates; WASD releases; Esc pops engaged then propagates", function()
  local env, page = Boot()
  local Focus = env.ns.Focus
  eq(Key(env, "UP"), false, "arrows pass through while not engaged")
  eq(Key(env, "W"), false, "W passes through")
  eq(Key(env, "TAB"), true, "Tab engages")
  ok(Focus.engaged, "engaged")
  Focus:Set(page.buttons[1], "key")
  eq(Key(env, "RIGHT"), true, "Right consumed")
  eq(Focus.current, page.buttons[2], "Right: B1 -> B2")
  eq(Key(env, "DOWN"), true)
  eq(Focus.current, page.buttons[5], "Down: B2 -> B5")
  eq(Key(env, "ENTER"), true)
  eq(page.clicked, 5, "Enter clicks the focused button")
  eq(Key(env, "W"), false, "W (MOVEFORWARD) propagates")
  ok(not Focus.engaged, "and releases the window")
  Key(env, "TAB")
  ok(Focus.engaged, "engaged again")
  eq(Key(env, "ESCAPE"), true, "Esc pops engaged mode (consumed)")
  ok(not Focus.engaged, "disengaged")
  eq(Key(env, "ESCAPE"), false, "Esc with nothing to pop propagates (UISpecialFrames closes the window)")
  noErrors(env)
end)

test("back stack: Review sheet, then pin, close in order; Y opens Review; Commit runs and focus returns", function()
  local env, page = Boot()
  local Focus, Esc = env.ns.Focus, env.ns.Esc
  Focus:Set(page.buttons[3], "key")
  Focus:Pin(page.buttons[3])
  ok(Esc.Has("pin"), "pin is a layer")
  env.G.AgentcraftPadY:Click()
  ok(Esc.Has("review"), "Y opens the Review sheet")
  ok(Focus.ZoneOf(Focus.current) == "review", "focus moved into the sheet")
  local nodes = Focus:Nodes()
  for _, n in ipairs(nodes) do ok(Focus.ZoneOf(n) == "review", "focus is modal: only sheet nodes") end
  ok(Esc.Pop(), "first Back closes the sheet")
  ok(not Esc.Has("review") and Esc.Has("pin"), "pin still there")
  ok(Esc.Pop(), "second Back unpins")
  eq(Focus.pinned, nil)
  env.G.AgentcraftPadY:Click()
  env.ns.UI.Commit()
  eq(page.committed, 1, "Commit ran once")
  ok(not Esc.Has("review"), "sheet closed after Apply")
  eq(#env:calls("CreateMacro"), 0, "the shell never creates macros")
  ok(Focus.current and Focus.ZoneOf(Focus.current) ~= "review", "focus back on the page")
  noErrors(env)
end)

test("focus restore: survives refresh, falls to the nearest node when its node hides, and comes back by id", function()
  local env, page = Boot()
  local Focus = env.ns.Focus
  Focus:Set(page.buttons[5], "key")
  env.ns.UI.Refresh()
  eq(Focus.current, page.buttons[5], "same node after Refresh")
  page.buttons[5]:Hide()
  env.ns.UI.Refresh()
  ok(Focus.current ~= page.buttons[5] and Focus.current ~= nil, "moved off the hidden node")
  local n = Focus.current
  ok(n == page.buttons[2] or n == page.buttons[4] or n == page.buttons[6] or n == page.buttons[8], "to a neighbour: " .. tostring(n.acId))
  page.buttons[5]:Show()
  page.lastFocusId = "b9"
  Focus:Restore()
  eq(Focus.current, page.buttons[9], "restore by acId")
  noErrors(env)
end)

test("pages: RB / Ctrl+Tab / Ctrl+n switch pages; X cycles the view strip", function()
  local env, page = Boot()
  local UI = env.ns.UI
  eq(UI.CurrentPage(), page)
  env.G.AgentcraftNextTab:Click()
  ok(UI.CurrentPage() ~= page, "RB: next page")
  env.G.AgentcraftKeyPrev:Click()
  eq(UI.CurrentPage(), page, "Ctrl+Shift+Tab: back")
  eq(page.view, "one")
  env.G.AgentcraftPadX:Click()
  eq(page.view, "two", "X: next view")
  env.G.AgentcraftKeyView:Click()
  eq(page.view, "one", "Ctrl+Space wraps")
  env.G.AgentcraftKeyPage2:Click()
  ok(UI.CurrentPage() ~= page, "Ctrl+2 jumps")
  noErrors(env)
end)

test("spatial moves: no dead end leaving the grid; explicit nav false stops; Left from the list goes back to the grid", function()
  local env, page = Boot()
  local Focus = env.ns.Focus
  Focus:Set(page.buttons[3], "key")
  Focus:Move("RIGHT")
  eq(Focus.current.acScroll, page.list, "Right of the grid lands in the list")
  Focus:Move("LEFT")
  ok(Focus.current == page.buttons[3] or Focus.current == page.buttons[6], "Left comes back: " .. tostring(Focus.current.acId))
  Focus:Set(page.buttons[1], "key")
  Focus:Move("UP")
  eq(Focus.ZoneOf(Focus.current), "view", "Up from the top row reaches the view strip")
  page.buttons[1].navRight = false
  Focus:Set(page.buttons[1], "key")
  Focus:Move("RIGHT")
  eq(Focus.current, page.buttons[1], "navRight = false stops")
  Focus:Set(page.buttons[7], "key")
  Focus:Move("DOWN")
  eq(Focus.ZoneOf(Focus.current), "prompts", "Down from the bottom row reaches the prompt bar")
  noErrors(env)
end)

test("scroll follows focus: row 25 comes into view with a row of context; wheel steps one row; Home/End", function()
  local env, page = Boot()
  local Focus = env.ns.Focus
  local list = page.list
  local rows = list:Nodes()
  eq(#rows, 40)
  Focus:Set(rows[25], "key")
  local v = list.scroll:GetVerticalScroll()
  local h = list.scroll:GetHeight()
  ok(v <= 23 * 30 and v + h >= 26 * 30, string.format("row 25 visible with context (scroll %d, height %d)", v, h))
  list.scroll:SetVerticalScroll(0)
  list.scroll:GetScript("OnMouseWheel")(list.scroll, -1)
  eq(list.scroll:GetVerticalScroll(), 30, "one wheel tick = one row")
  Focus:Set(rows[3], "key")
  Focus.engaged = true
  Focus:ListJump("END")
  eq(Focus.current, rows[40], "End: last row")
  Focus:ListJump("HOME")
  eq(Focus.current, rows[1], "Home: first row")
  noErrors(env)
end)

test("controller bar: native layout (Y above A, Left left of Right), no overlaps, every slot has its glyph", function()
  local env = Boot()
  local UI = env.ns.UI
  local parent = env.G.CreateFrame("Frame", nil, env.G.UIParent)
  parent:SetSize(712, 512); parent:SetPoint("CENTER")
  local bars = {}
  for layer = 0, 3 do
    local b = UI.PadBar(parent, layer)
    local off = UI.PAD_BAR_OFFSETS[layer]
    b:SetPoint("CENTER", parent, "TOPLEFT", 362 + off[1], -236 + off[2])
    bars[layer] = b
  end
  local rects = {}
  local pr = Rect(env, parent)
  for layer, b in pairs(bars) do
    local y, a = Rect(env, b.slots.Y), Rect(env, b.slots.A)
    ok(y.t < a.t, "layer " .. layer .. ": Y above A")
    ok(Rect(env, b.slots.Left).l < Rect(env, b.slots.Right).l, "layer " .. layer .. ": Left left of Right")
    for name, s in pairs(b.slots) do
      ok(s.glyphKey, name .. " has a glyph")
      local r = Rect(env, s)
      ok(r.l >= pr.l - 0.5 and r.r <= pr.r + 0.5 and r.t >= pr.t - 0.5 and r.b <= pr.b + 0.5, "layer " .. layer .. " " .. name .. " inside the stage")
      rects[#rects + 1] = { r = r, n = layer .. name }
    end
  end
  for i = 1, #rects do
    for j = i + 1, #rects do
      local a, b = rects[i].r, rects[j].r
      ok(not (a.l < b.r - 0.5 and b.l < a.r - 0.5 and a.t < b.b - 0.5 and b.t < a.b - 0.5), rects[i].n .. " overlaps " .. rects[j].n)
    end
  end
  -- D-pad diamond: Right goes on to face X.
  eq(bars[2].slots.Right.navRight, bars[2].slots.X)
  noErrors(env)
end)

test("glyphs: real atlas names; PlayStation set with Shapes; keycaps in keyboard prompt mode", function()
  local env = Boot()
  local UI = env.ns.UI
  eq(UI.GlyphAtlas("PAD1"), "gamepad-xbox1-buttona-flat-normal")
  eq(UI.GlyphAtlas("PADLSHOULDER"), "gamepad-xbox1-trigger-lb-flat-normal")
  env.W.labelStyle = "Shapes"
  eq(UI.GlyphAtlas("PAD1"), "gamepad-ps-32x-x")
  env.W.labelStyle = nil
  -- The one-direction glyph, not the full-cross fallback: the four directions must differ.
  eq(UI.GlyphAtlas("PADDDOWN"), "gamepad-xbox1-donlydown-flat-normal")
  eq(UI.GlyphAtlas("PADDUP"), "gamepad-xbox1-donlyup-flat-normal")
  eq(UI.GlyphAtlas("PADDLEFT"), "gamepad-xbox1-donlyleft-flat-normal")
  eq(UI.GlyphAtlas("PADDRIGHT"), "gamepad-xbox1-donlyright-flat-normal")
  ok(env.G.C_Texture.GetAtlasInfo(UI.GlyphAtlas("PADDDOWN")), "D-pad down atlas exists")
  local g = UI.Glyph(env.G.UIParent, "PAD4", 22, "prompt")
  UI.NoteDevice("keyboard")
  ok(g.cap:IsShown() and g.cap.text:GetText() == "Ctrl+Enter", "keyboard mode shows the key: " .. tostring(g.cap.text:GetText()))
  UI.NoteDevice("pad")
  ok(g.tex:IsShown(), "pad mode shows the glyph")
  noErrors(env)
end)

test("harness: MinimalSliderWithSteppersTemplate draws the real Minimal_SliderBar atlases", function()
  local env = H.boot({})
  local s = env.G.CreateFrame("Frame", nil, env.G.UIParent, "MinimalSliderWithSteppersTemplate")
  eq(s.Slider.Left._atlas, "Minimal_SliderBar_Left")
  eq(s.Slider.Middle._atlas, "_Minimal_SliderBar_Middle")
  eq(s.Slider.Right._atlas, "Minimal_SliderBar_Right")
  eq(s.Slider.Thumb._atlas, "Minimal_SliderBar_Button")
  eq(env.G.C_Texture.GetAtlasInfo("minimal-slider-bar"), nil, "the invented stand-in is gone")
  s:Init(1, 0.8, 1.25, 9)
  s.Forward:Click()
  ok(math.abs(s:GetValue() - 1.05) < 1e-6, "the forward stepper steps")
end)
