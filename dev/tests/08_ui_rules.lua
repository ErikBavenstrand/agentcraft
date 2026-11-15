-- The main UI rules from dev/ui-spec.md §11, checked on every page of the
-- /ac window: the controller diamonds point the right way, nothing in the
-- footer's status area overlaps, and the window draws no large flat colour
-- fills (templates and atlases only).
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

local function Shown(o)
  while o do
    if not o._shown then return false end
    o = o._parent
  end
  return true
end

-- Every object under root: frames and their regions.
local function Walk(root, fn)
  local function walk(f)
    fn(f)
    for _, r in ipairs(f._regions or {}) do fn(r) end
    for _, c in ipairs(f._children or {}) do walk(c) end
  end
  walk(root)
end

local function Where(o) return tostring(o._site or o._name or o._type) end

-- Controller diamonds -------------------------------------------------------------

test("controller: every diamond has Up above Down and Left left of Right, inside the page", function()
  local env = H.boot({})
  env.ns.OpenPage("controller")
  noErrors(env)
  local page = PageById(env, "controller")
  ok(page and page.slots, "controller page built its slots")
  local s = Solver(env)
  local pr = s:Rect(page.frame)
  local function C(r) return (r.l + r.r) / 2, (r.t + r.b) / 2 end
  local names = { [0] = "No trigger", "Hold LT", "Hold RT", "Hold LT + RT" }
  for bar = 0, 3 do
    -- Button order in a bar: 1-4 D-pad Left Up Right Down, 5-8 face X Y B A.
    for _, base in ipairs({ 0, 4 }) do
      local which = names[bar] .. (base == 0 and " D-pad" or " face")
      local left, up, right, down = s:Rect(page.slots[bar * 8 + base + 1]), s:Rect(page.slots[bar * 8 + base + 2]),
        s:Rect(page.slots[bar * 8 + base + 3]), s:Rect(page.slots[bar * 8 + base + 4])
      local lx, ly = C(left); local ux, uy = C(up); local rx, ry = C(right); local dx, dy = C(down)
      ok(uy < dy, which .. ": Up (" .. uy .. ") is above Down (" .. dy .. ")")
      ok(lx < rx, which .. ": Left (" .. lx .. ") is left of Right (" .. rx .. ")")
      ok(math.abs(ux - dx) < 1, which .. ": Up and Down share a column")
      ok(math.abs(ly - ry) < 1, which .. ": Left and Right share a row")
      ok(uy < ly and ly < dy, which .. ": Left/Right sit between Up and Down")
      for _, r in ipairs({ left, up, right, down }) do ok(Inside(r, pr), which .. ": slot inside the 600x450 page") end
    end
  end
  for key, slot in pairs(page.paddles or {}) do ok(Inside(s:Rect(slot), pr), "back button " .. key .. " inside the page") end
  -- The diamonds don't change when LB/RB switches the set.
  ok(page.OnShoulder, "controller page handles LB/RB")
  page:OnShoulder(1)
  eq(page.current, 2, "RB: set 2")
  page:OnShoulder(-1); page:OnShoulder(-1)
  eq(page.current, 3, "LB twice from 2 wraps to set 3")
  noErrors(env)
end)

-- Status area ------------------------------------------------------------------------

test("footer: the status line never overlaps the actions or other text, on every page", function()
  local env = H.boot({ pet = true })
  env:slash("")
  local long = "MARK " .. string.rep("a long result line ", 12)
  for _, p in ipairs(env.ns.pages) do
    env.ns.OpenPage(p.id)
    env.ns.UI.ShowResult(long .. "\nsecond line\nthird line")
    -- The status text is the font string showing the marker; its button sits
    -- in the footer bar with the page's action buttons.
    local statusText
    Walk(env.G.AgentcraftFrame, function(o)
      if o._type == "FontString" and Shown(o) and tostring(o._text or ""):find("MARK ", 1, true) then statusText = o end
    end)
    ok(statusText, p.id .. ": status text found")
    if statusText then
      local status, bar = statusText._parent, statusText._parent._parent
      local s = Solver(env)
      local texts, buttons = {}, {}
      Walk(bar, function(o)
        if not Shown(o) then return end
        if o._type == "FontString" and (o._text or "") ~= "" then texts[#texts + 1] = o
        elseif (o._type == "Button" or o._type == "CheckButton") and o ~= status and o._parent == bar then buttons[#buttons + 1] = o end
      end)
      local sr = s:Rect(status)
      for _, b in ipairs(buttons) do
        ok(not Overlap(sr, s:Rect(b)), p.id .. ": status overlaps footer button " .. Where(b))
      end
      for i = 1, #texts do
        for j = i + 1, #texts do
          local a, b = texts[i], texts[j]
          -- A button's own label sits inside it; compare texts of different owners.
          if a._parent ~= b._parent then
            ok(not Overlap(s:Rect(a), s:Rect(b)), p.id .. ": footer texts overlap: '" .. tostring(a._text):sub(1, 30)
              .. "' and '" .. tostring(b._text):sub(1, 30) .. "'")
          end
        end
      end
    end
  end
  noErrors(env)
end)

-- No hand-drawn chrome -------------------------------------------------------------

test("no page draws a SetColorTexture fill larger than 4x4", function()
  local env = H.boot({ pet = true })
  env:slash("")
  local fills = {}
  for _, p in ipairs(env.ns.pages) do
    env.ns.OpenPage(p.id)
    local s = Solver(env)
    Walk(env.G.AgentcraftFrame, function(o)
      if o._region and o._color and not o._fromTemplate and not o._mask and o._layer ~= "HIGHLIGHT" and Shown(o) then
        local r = s:Rect(o)
        if r then
          local w, h = (r.r - r.l) / (r.scale or 1), (r.b - r.t) / (r.scale or 1)
          if w > 4 and h > 4 then fills[#fills + 1] = string.format("%s: %dx%d at %s", p.id, w, h, Where(o)) end
        end
      end
    end)
  end
  if #fills > 0 then fail("flat colour fills (use UI.Inset, UI.Panel, UI.Divider or an atlas):\n" .. table.concat(fills, "\n")) end
  noErrors(env)
end)
