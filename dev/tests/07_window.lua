-- The /ac window (UI/Window.lua), the shared widgets (UI/Widgets.lua) and
-- the Core.lua registration fields they read.
local H = require("harness")
local layout = require("layout")

local function Rect(env, obj)
  return layout.New(env.W, { w = 1280, h = 800 }):Rect(obj)
end

local function Overlap(a, b)
  return a and b and a.l < b.r - 0.5 and b.l < a.r - 0.5 and a.t < b.b - 0.5 and b.t < a.b - 0.5
end

local function PageById(env, id)
  for _, p in ipairs(env.ns.pages) do if p.id == id then return p end end
end

-- Registers a test page before the addon loads (pages are read when the window builds).
local function WithPage(page, opts)
  opts = opts or {}
  opts.loaded = function(env) page.ns = env.ns; env.ns.RegisterPage(page) end
  return H.boot(opts)
end

test("window: PortraitFrameTemplate 1000x640, MEDIUM strata, 712x512 stage, v1 pages get a 600x450 frame", function()
  local env = H.boot({})
  env:slash("")
  local f = env.G.AgentcraftFrame
  ok(f, "AgentcraftFrame exists")
  ok(f:IsShown(), "window shown")
  eq(f._templates[#f._templates], "PortraitFrameTemplate")
  eq(f:GetWidth(), 1000); eq(f:GetHeight(), 640)
  local st = env.ns.UI.stage
  eq(math.floor(st:GetWidth() + 0.5), 712); eq(math.floor(st:GetHeight() + 0.5), 512)
  eq(f:GetFrameStrata(), "MEDIUM")
  eq(#env:calls("ShowUIPanel"), 0, "never through ShowUIPanel: it taints Blizzard's panel manager (Escape got blocked)")
  local page = env.ns.UI.CurrentPage()
  ok(page and page.frame, "a page opens first on a fresh install")
  if page.api ~= 2 then eq(page.frame:GetWidth(), 600); eq(page.frame:GetHeight(), 450) end
  noErrors(env)
end)

test("window: the attic never overlaps, even with a 110-character summary", function()
  local long = string.rep("Up to date and lots more words ", 4):sub(1, 110)
  local env = WithPage({ id = "zz", title = "A Rather Long Page Title For Testing", section = "addon",
    Build = function() end, Status = function() return long end })
  env.ns.OpenPage("zz")
  local f = env.G.AgentcraftFrame
  local title, summary, who
  for _, r in ipairs(f._regions or {}) do
    if r._type == "FontString" then
      if r._text == "A Rather Long Page Title For Testing" then title = r end
      if (r._text or ""):find("^Level ") then who = r end
    end
  end
  for _, c in ipairs(f._children or {}) do
    for _, r in ipairs(c._regions or {}) do if r._text == long then summary = r end end
  end
  ok(title and summary and who, "title, summary and character line found")
  local tr, sr, wr = Rect(env, title), Rect(env, summary), Rect(env, who)
  ok(not Overlap(tr, sr), "title vs summary")
  ok(not Overlap(sr, wr), "summary vs character line")
  ok(not Overlap(tr, wr), "title vs character line")
  ok(sr.r <= Rect(env, f).r - 11, "summary stays inside the window (truncates)")
  ok(who._text:find("Level 60", 1, true), "character line: " .. tostring(who._text))
  noErrors(env)
end)

test("footer: confirm asks first, labels and enabled re-read, primary sits rightmost", function()
  local ran, count = 0, 2
  local env = WithPage({ id = "zz", title = "Test", section = "addon", Build = function() end,
    actions = {
      { label = "Apply", primary = true, fn = function(p) ran = ran + 1; p.ns.Out("applied") end,
        confirm = function() return "Apply it?" end, enabled = function() return count > 0 end },
      { label = function() return "Remove (" .. count .. ")" end, fn = function() count = count - 1 end },
    } })
  env.ns.OpenPage("zz")
  local page = PageById(env, "zz")
  local buttons = page.footerFrame.buttons
  eq(#buttons, 2)
  eq(buttons[2]:GetText(), "Apply", "primary action is rightmost")
  eq(buttons[1]:GetText(), "Remove (2)")
  buttons[2]:Click()
  eq(ran, 0, "Apply waits for the dialog")
  eq(#env:calls("StaticPopup_Show"), 1)
  eq(env.W.popup.text, "Apply it?")
  ok(env.W.AcceptPopup(), "dialog accepted")
  eq(ran, 1, "Apply ran after Yes")
  buttons[1]:Click()
  buttons[1]:Click()
  eq(buttons[1]:GetText(), "Remove (0)", "label re-read after the action")
  ok(not buttons[2]:IsEnabled(), "Apply disabled when enabled() is false")
  noErrors(env)
end)

test("every footer action with confirm goes through StaticPopup_Show", function()
  local env = H.boot({ pet = true })
  env:slash("")
  for _, page in ipairs(env.ns.pages) do
    env.ns.OpenPage(page.id)
    for _, b in ipairs(page.footerFrame and page.footerFrame.buttons or {}) do
      local a = b.action
      local text = type(a.confirm) == "function" and a.confirm(page) or a.confirm
      if text and b:IsEnabled() then
        env:resetCalls()
        env.W.inCombat = true -- so a confirmed Apply can't change anything
        b:Click()
        env.W.inCombat = false
        eq(#env:calls("StaticPopup_Show"), 1, page.id .. " '" .. b:GetText() .. "' asks first")
        env.W.popup = nil
      end
    end
  end
end)

test("status: first line plus (+N more); errors are red, logged and cleared by a good refresh", function()
  local fail = false
  local env = WithPage({ id = "zz", title = "Test", section = "addon", Build = function() end,
    Refresh = function() if fail then error("boom") end end,
    actions = { { label = "Go", fn = function(p) p.ns.Out("one"); p.ns.Out("two"); p.ns.Out("three") end } } })
  env.ns.OpenPage("zz")
  local page = PageById(env, "zz")
  page.footerFrame.buttons[1]:Click()
  local f = env.G.AgentcraftFrame
  local status
  for _, c in ipairs(f._children) do
    for _, cc in ipairs(c._children or {}) do if cc.text and cc.kind then status = cc end end
  end
  ok(status, "status button found")
  ok(status.text:GetText():find("^one"), status.text:GetText())
  ok((status.more:GetText() or ""):find("(+2 more)", 1, true), status.more:GetText())
  eq(#status.lines, 3)
  fail = true
  env.ns.UI.Refresh()
  eq(status.kind, "error")
  ok(status.text:GetText():find("Error: ", 1, true), status.text:GetText())
  ok(env.ns.log[#env.ns.log]:find("boom", 1, true), "error logged")
  fail = false
  env.ns.UI.Refresh()
  ok(status.kind ~= "error", "a good refresh clears the error")
end)

test("a page whose Build raises hides its footer and says so; the next visit retries", function()
  local tries = 0
  local env = WithPage({ id = "zz", title = "Broken", section = "addon",
    Build = function() tries = tries + 1; if tries == 1 then error("bad build") end end,
    actions = { { label = "Go", fn = function() end } } })
  env.ns.OpenPage("zz")
  local page = PageById(env, "zz")
  eq(page.frame, nil)
  ok(not (page.footerFrame and page.footerFrame:IsShown()), "footer hidden")
  ok(env.ns.log[#env.ns.log]:find("bad build", 1, true), "error in the log")
  env.ns.OpenPage("settings")
  env.ns.OpenPage("zz")
  ok(page.frame, "built on the next visit")
  ok(page.footerFrame:IsShown(), "footer back")
end)

test("module off: page gated, actions hidden, commands refused; on again: back to normal", function()
  local env = H.boot({ pet = true })
  env:slash("")
  env:slash("off controller")
  ok(not env.ns.modules.controller.active, "controller off")
  eq(env.G.AgentcraftDB.enabled.Controller, false, "choice saved")
  env:resetCalls()
  env:slash("controller apply")
  eq(#env:calls("PlaceAction"), 0, "no bars changed")
  eq(#env:calls("SetBinding"), 0, "no keys bound")
  ok(env:chatText():find("turned off", 1, true), env:chatText())
  env.ns.OpenPage("controller")
  local page = PageById(env, "controller")
  ok(not (page.frame and page.frame:IsShown()), "page content hidden")
  ok(not (page.footerFrame and page.footerFrame:IsShown()), "Apply/Undo hidden")
  env:slash("on controller")
  ok(env.ns.modules.controller.active, "controller on")
  ok(page.frame and page.frame:IsShown(), "page builds and shows once the module is on")
  ok(page.footerFrame and page.footerFrame:IsShown(), "actions back")
  noErrors(env)
end)

test("module off: its tool action (Snapshot > Save now) does nothing", function()
  local env = H.boot({})
  env:slash("off snapshot")
  local action
  for _, a in ipairs(env.ns.actions) do if a.section == "Snapshot" then action = a end end
  ok(action, "Snapshot action registered")
  local out = env.ns.Run(action.fn)
  ok(out:find("turned off", 1, true), out)
  env:resetCalls()
  env:slash("snapshot")
  ok(env:chatText():find("turned off", 1, true), env:chatText())
end)

test("/ac off saves the choice for a module whose OnEnable failed", function()
  local env = H.boot({ loaded = function(e)
    e.ns.modules.fishing.OnEnable = function() error("broken on this client") end
  end })
  ok(not env.ns.modules.fishing.active, "failed module is off")
  env:resetCalls()
  env:slash("off fishing")
  eq(env.G.AgentcraftDB.enabled.Fishing, false, "off choice saved")
  ok(not env:chatText():find("already", 1, true), env:chatText())
end)

test("SetModuleEnabled on an already-on module doesn't run OnEnable again", function()
  local n = 0
  local env = H.boot({ loaded = function(e) e.ns.modules.fishing.OnEnable = function() n = n + 1 end end })
  eq(n, 1)
  env.ns.SetModuleEnabled(env.ns.modules.fishing, true)
  eq(n, 1, "no second OnEnable")
end)

test("last page is remembered; LB/RB overrides set while open and cleared on close", function()
  local env = H.boot({ db = { lastPage = "macros" } })
  env:slash("")
  ok(PageById(env, "macros").frame and PageById(env, "macros").frame:IsShown(), "opens the last page")
  ok(env.W.overrides.PADLSHOULDER and env.W.overrides.PADRSHOULDER, "LB/RB bound while open")
  eq(env.W.overrides.PADRSHOULDER.command, "CLICK AgentcraftNextTab:LeftButton")
  env.ns.OpenPage("settings")
  eq(env.G.AgentcraftDB.lastPage, "options")
  env.G.AgentcraftNextTab:Click()
  ok(env.G.AgentcraftDB.lastPage ~= "options", "RB moves to another page")
  env:slash("")  -- close
  ok(not env.G.AgentcraftFrame:IsShown(), "closed")
  eq(next(env.W.overrides), nil, "overrides cleared")
end)

test("Gamepad UI on: Overview (or Controller) opens first and the window scales to 1.1", function()
  local env = H.boot({ setup = function(W) W.gamepadUI = true end })
  env:slash("")
  local want = PageById(env, "overview") or PageById(env, "controller")
  ok(want.frame and want.frame:IsShown(), want.id .. " first")
  eq(env.G.AgentcraftFrame:GetScale(), 1.1)
end)

test("/ac scale clamps to the screen; /ac reset clears position and scale", function()
  local env = H.boot({})
  env:slash("")
  env:slash("scale 1.25")
  eq(env.G.AgentcraftDB.scale, 1.25)
  local s = env.G.AgentcraftFrame:GetScale()
  ok(s <= (800 - 20) / 640 + 1e-6 and s <= (1280 - 20) / 1044 + 1e-6 and s <= 1.25, "scale " .. s .. " fits 1280x800")
  env:slash("scale 3")
  eq(env.G.AgentcraftDB.scale, 1.25, "clamped to 1.25")
  env.G.AgentcraftDB.window = { "TOPLEFT", "TOPLEFT", 10, -10 }
  env:slash("reset")
  eq(env.G.AgentcraftDB.window, nil)
  eq(env.G.AgentcraftDB.scale, nil)
  eq(env.G.AgentcraftFrame:GetScale(), 1)
  noErrors(env)
end)

test("slash: unknown command says so, /ac bars is /ac spells, shots hidden unless dev", function()
  local env = H.boot({})
  env:resetCalls()
  env:slash("frobnicate")
  ok(env:chatText():find("Unknown command 'frobnicate'.", 1, true), env:chatText())
  ok(not env:chatText():find("/ac shots", 1, true), "shots hidden")
  ok(env:chatText():find("/ac spells", 1, true), "help listed")
  env.G.AgentcraftDB.dev = true
  env:resetCalls()
  env:slash("help")
  ok(env:chatText():find("/ac shots", 1, true), "shots listed with dev on")
  env:resetCalls()
  env:slash("bars")
  ok(not env:chatText():find("Unknown command", 1, true), "/ac bars runs /ac spells: " .. env:chatText())
  noErrors(env)
end)

test("ns.Run strips the chat prefix and keeps errors apart", function()
  local env = H.boot({})
  local out, err = env.ns.Run(function() env.ns.Print("hello") end)
  eq(out, "hello")
  eq(err, nil)
  ok(not env.ns.log[#env.ns.log]:find("Agentcraft|r:", 1, true), "log line has no prefix")
  local _, err2 = env.ns.Run(function() error("nope") end)
  ok(err2 and err2:find("nope", 1, true), tostring(err2))
end)

test("widgets: slot fades only for faded == true; colour objects wrap text", function()
  local env = H.boot({})
  local UI = env.ns.UI
  local parent = env.G.CreateFrame("Frame", nil, env.G.UIParent)
  local s = UI.Slot(parent, 36)
  s:SetIcon(136243, 136243) -- extra return value from C_Spell.GetSpellTexture
  ok(not s.icon:IsDesaturated(), "a number is not 'faded'")
  s:SetIcon(136243, true)
  ok(s.icon:IsDesaturated(), "true fades")
  eq(UI.C.ADDED:WrapTextInColorCode("x"), "|cff1aff1ax|r")
  eq(UI.GREEN[2], 1)
  eq(select("#", UI.SpellIcon("Arcane Shot")), 1, "SpellIcon returns one value")
  local row = UI.Check(parent, "Label", "Description", function() end)
  eq(row.box._templates[1], "MinimalCheckboxTemplate")
  row:Click()
  ok(row:GetChecked(), "clicking the row checks the box")
  local tabs = UI.Tabs(parent, { "One", "Two" }, function() end)
  tabs.Tabs[2]:Click()
  eq(tabs.selected, 2)
  ok(not tabs.Tabs[2]:IsEnabled() and tabs.Tabs[1]:IsEnabled(), "selected tab is the disabled (active) one")
  local dd = UI.Filter(parent, function(_, root) root:CreateCheckbox("Hunter", function() return true end, function() end) end)
  eq(dd._menu[1].text, "Hunter")
  local box = UI.LogBox(parent)
  ok(box:SetTextIfChanged("a"), "first set")
  ok(not box:SetTextIfChanged("a"), "same text is not set again")
  local called = false
  UI.Confirm("Sure?", function() called = true end)
  ok(not called and env.W.AcceptPopup() and called, "Confirm runs on Yes")
  local leg = UI.LegendItem(parent, "added", "Added")
  ok(leg.slot.mark:IsShown(), "legend slot shows its mark")
  eq(UI.KeyText("SHIFT-BUTTON4"), "s-M4")
  noErrors(env)
end)

test("an action's error stays in the status line after the refresh that follows it", function()
  local env = WithPage({ id = "zz", title = "Test", section = "addon", Build = function() end,
    actions = { { label = "Bad", fn = function() error("action failed") end } } })
  env.ns.OpenPage("zz")
  local page = PageById(env, "zz")
  page.footerFrame.buttons[1]:Click()
  local status
  for _, c in ipairs(env.G.AgentcraftFrame._children) do
    for _, cc in ipairs(c._children or {}) do if cc.text and cc.kind then status = cc end end
  end
  ok(status and status.kind == "error", "error shown")
  ok(status.text:GetText():find("action failed", 1, true), status.text:GetText())
end)
