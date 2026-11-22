-- The v2 Controller page (dev/ui-spec-v2.md §9.3): the native Gamepad HUD
-- cross, glyph placement, focus moves inside and between bars, X cycling
-- sets, LT/RT (Shift/Ctrl) previews, the List view, the Review count and
-- Commit (never creates macros), the back buttons and the Gamepad-UI-off plate.
local H = require("harness")
local layout = require("layout")

local function Solver(env) return layout.New(env.W, { w = 1280, h = 800 }) end

local function PageById(env, id)
  for _, p in ipairs(env.ns.pages) do if p.id == id then return p end end
end

local function Overlap(a, b)
  return a and b and a.l < b.r - 1 and b.l < a.r - 1 and a.t < b.b - 1 and b.t < a.b - 1
end

local function Inside(r, box)
  return r and box and r.l >= box.l - 0.5 and r.r <= box.r + 0.5 and r.t >= box.t - 0.5 and r.b <= box.b + 0.5
end

local function Open(opts)
  local env = H.boot(opts or { pet = true })
  env:slash("")
  env.ns.OpenPage("controller")
  env:runTimers(1)
  return env, PageById(env, "controller")
end

local NAMES = { "Up", "Right", "Down", "Left", "Y", "B", "A", "X" }

test("controller HUD: four bars on three rows, no slot overlaps, every slot and glyph inside the stage", function()
  local env, page = Open()
  noErrors(env)
  eq(page.api, 2, "a v2 page")
  local s = Solver(env)
  local stage = s:Rect(page.frame)
  local rects = {}
  for layer = 0, 3 do
    for _, n in ipairs(NAMES) do
      local slot = page.bars[layer].slots[n]
      local r = s:Rect(slot)
      ok(Inside(r, stage), "bar " .. layer .. " " .. n .. " inside the stage")
      -- An empty slot names its button with the empty art instead of the glyph.
      ok(slot.glyph:IsShown() or slot.empty:IsShown(), "bar " .. layer .. " " .. n .. " shows its glyph")
      ok(Inside(s:Rect(slot.glyph), stage), "bar " .. layer .. " " .. n .. " glyph inside the stage")
      rects[#rects + 1] = { r = r, slot = slot, name = layer .. ":" .. n }
    end
  end
  for i = 1, #rects do
    for j = i + 1, #rects do
      ok(not Overlap(rects[i].r, rects[j].r), "slots " .. rects[i].name .. " and " .. rects[j].name .. " overlap")
    end
  end
  -- A glyph never sits on another slot (Y's glyph on X, say).
  for _, a in ipairs(rects) do
    local g = s:Rect(a.slot.glyph)
    for _, b in ipairs(rects) do
      if b.slot ~= a.slot then ok(not Overlap(g, b.r), "glyph of " .. a.name .. " covers slot " .. b.name) end
    end
  end
  local function C(f) local r = s:Rect(f); return (r.l + r.r) / 2, (r.t + r.b) / 2 end
  local tx, ty = C(page.bars[0].slots.Y)
  local _, ly = C(page.bars[1].slots.Y)
  local _, ry = C(page.bars[2].slots.Y)
  local _, by = C(page.bars[3].slots.Y)
  ok(ty < ly and ly == ry and ry < by, "Top above Left/Right above Bottom")
  ok(C(page.bars[1].slots.B) < C(page.bars[2].slots.Left), "Left bar entirely left of the Right bar")
  ok(tx > 0, "sanity")
  -- Native diamonds: Y on top, A at the bottom, X left, B right.
  for layer = 0, 3 do
    local S = page.bars[layer].slots
    local yx, yy = C(S.Y); local ax, ay = C(S.A); local xx, xy = C(S.X); local bx, byy = C(S.B)
    ok(yy < ay and math.abs(yx - ax) < 1, "bar " .. layer .. ": Y above A")
    ok(xx < bx and math.abs(xy - byy) < 1, "bar " .. layer .. ": X left of B")
  end
end)

test("controller HUD: back buttons are drawn but never focusable; the fixed face buttons are readable", function()
  local env, page = Open()
  for key, sk in pairs(page.paddles) do
    ok(not sk.acNode, key .. " socket is not a focus node")
  end
  for _, n in ipairs(env.ns.Focus:Nodes()) do
    for _, sk in pairs(page.paddles) do ok(n ~= sk, "socket in the focus list") end
  end
  local a = page.bars[0].slots.A
  eq(a.info.state, "fixed", "no-trigger A is the Gamepad UI's")
  eq(a.info.name, "Jump")
  ok(env.ns.Focus.Usable(a), "a fixed button can still be focused to read it")
  noErrors(env)
end)

test("controller focus: Blizzard diamond moves inside a bar, spatial between bars, no dead ends", function()
  local env, page = Open()
  local Focus = env.ns.Focus
  local top = page.bars[0].slots
  Focus:Set(top.Up, "key")
  Focus:Move("DOWN", "key")
  eq(Focus.current, top.Down, "Up -> Down in the D-pad diamond")
  Focus:Set(top.Right, "key")
  Focus:Move("RIGHT", "key")
  eq(Focus.current, top.X, "D-pad Right -> face X")
  -- Leaving the top bar downward lands in a bar below, never nowhere.
  Focus:Set(top.Down, "key")
  Focus:Move("DOWN", "key")
  ok(Focus.current and (Focus.current.layer == 1 or Focus.current.layer == 2), "Down from the top bar reaches the LT/RT row")
  -- From the left bar's B, Right goes into the right bar.
  Focus:Set(page.bars[1].slots.B, "key")
  Focus:Move("RIGHT", "key")
  eq(Focus.current and Focus.current.layer, 2, "Right from the LT bar's B reaches the RT bar")
  -- Down from the RT row reaches the bottom bar.
  Focus:Set(page.bars[2].slots.Down, "key")
  Focus:Move("DOWN", "key")
  eq(Focus.current and Focus.current.layer, 3, "Down from the RT bar reaches the LT + RT bar")
  -- Focus expands its bar and names the button in the bar header.
  Focus:Set(page.bars[2].slots.A, "key")
  ok(page.bars[2].expanded, "focused bar grows")
  ok(not page.bars[0].expanded, "others don't")
  ok(page.bars[2].focusName:GetText():find(page.bars[2].slots.A.info.name, 1, true), "header names the focused button")
  noErrors(env)
end)

test("controller sets: X cycles 1 -> 2 -> 3 -> 1 and focus stays on the same button", function()
  local env, page = Open()
  local Focus = env.ns.Focus
  Focus:Set(page.bars[2].slots.A, "key")
  eq(page.current, 1)
  env.ns.UI.CycleView(1)
  eq(page.current, 2, "X: set 2")
  eq(page.view, "2")
  env.ns.UI.CycleView(1); env.ns.UI.CycleView(1)
  eq(page.current, 1, "wraps back to set 1")
  eq(Focus.current and Focus.current.acId, "pad:2:A", "focus kept on RT + A")
  noErrors(env)
end)

test("controller preview: Shift (LT), Ctrl (RT) and both expand that bar and show it in the Inspector", function()
  local env, page = Open()
  local W = env.W
  W.mods.shift = true
  page.frame.acPollModifiers()
  ok(page.bars[1].expanded, "Shift / LT: the LT bar grows")
  eq(page.held, 1)
  W.mods.ctrl = true
  page.frame.acPollModifiers()
  ok(page.bars[3].expanded and not page.bars[1].expanded, "both: the LT + RT bar")
  W.mods.shift = false
  page.frame.acPollModifiers()
  ok(page.bars[2].expanded, "Ctrl / RT: the RT bar")
  W.mods.ctrl = false
  page.frame.acPollModifiers()
  eq(page.held, nil, "released")
  noErrors(env)
end)

test("controller List view: 32 named cells in a grid, focus follows, back to HUD restores", function()
  local env, page = Open()
  local Focus = env.ns.Focus
  page.toggles[1].set(page, 2)
  env.ns.UI.Refresh()
  ok(page.listHost:IsShown() and not page.hud:IsShown(), "List shown, HUD hidden")
  local named = 0
  for layer = 0, 3 do
    for _, n in ipairs(NAMES) do
      local cell = page.cells[layer][n]
      ok(Focus.Usable(cell), "cell " .. layer .. ":" .. n .. " focusable")
      if (cell.nameText:GetText() or "") ~= "" then named = named + 1 end
    end
  end
  eq(named, 32, "every cell has a name")
  Focus:Set(page.cells[0].Up, "key")
  Focus:Move("RIGHT", "key")
  eq(Focus.current, page.cells[1].Up, "Right moves to the next layer's column")
  Focus:Move("DOWN", "key")
  eq(Focus.current, page.cells[1].Right, "Down moves to the next button row")
  page.toggles[1].set(page, 1)
  env.ns.UI.Refresh()
  ok(page.hud:IsShown(), "HUD back")
  noErrors(env)
end)

test("controller Review: the count matches the plan's changes; Commit applies without creating macros", function()
  local env, page = Open()
  local groups = page:Review()
  local n = 0
  for _, g in ipairs(groups) do n = n + #g.items end
  eq(n, page.plan.changes, "Review items = plan.changes")
  ok(n > 0, "the fixture has changes")
  env:resetCalls()
  env.ns.UI.OpenReview()
  env.ns.UI.Commit()
  eq(#env:calls("CreateMacro"), 0, "Commit never creates macros")
  ok(#env:calls("PlaceAction") > 0, "bars filled")
  for _, k in ipairs({ "F13", "F14", "F15", "F16" }) do
    local bound = false
    for _, c in ipairs(env:calls("SetBinding")) do if c[1] == k and c[2] then bound = true end end
    ok(not bound, k .. " (back button) stays free")
  end
  page = PageById(env, "controller")
  eq(page.plan.changes, 0, "up to date after Commit")
  noErrors(env)
end)

test("controller without the Gamepad UI's bars: plate shown, status warns, no readiness", function()
  local env, page = Open({ pet = true, setup = function(W) W.gamepad = false end })
  ok(page.offPlate:IsShown(), "off plate")
  ok(not page.legend:IsShown(), "legend makes room")
  local text = page:Status()
  ok(text:find("Gamepad UI off", 1, true), text)
  eq(page:readiness(), nil, "no meter")
  noErrors(env)
end)
