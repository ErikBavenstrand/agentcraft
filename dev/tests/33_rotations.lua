-- Owner (2026-11-26): every spec must play its full rotation, tank kit or
-- heal kit from keyboard AND controller, and the controller's core kit must
-- not need a page switch. dev/rotations.lua lists each spec's Wowhead
-- rotation; with every talent learned, each name must be on a keyboard
-- rotation key (Bar 1 or one of the spec's stance pages, Shift for a healer's
-- or tank's cooldown-free kit is not enough) and on controller page 1.
local H = require("harness")
local ROT = dofile(H.devDir and (H.devDir .. "/rotations.lua") or "dev/rotations.lua")
-- Talents of one tree (dev/forever-talents.md, from Wowhead's Forever
-- talent calculator): a spec learns only its own tree, as in game.
local MD = io.open("dev/forever-talents.md"):read("*a")
local function TreeNames(class, index)
  local block = MD:match("\n## " .. class:sub(1, 1) .. class:sub(2):lower() .. " %(.-\n## ") or ""
  local i, out = 0, {}
  for line in block:gmatch("\n%- [^\n]+") do
    if line:match("^\n%- [%w ]+:") and not line:match("Not a Forever") and not line:match("Tooltips") then
      i = i + 1
      if i == index then
        for name in line:gsub("%*%*", ""):gsub("%b()", ""):gmatch("[^,;:]+") do
          local n = name:gsub("^%s*%d*%s*", ""):gsub("%s+$", "")
          if n ~= "" then out[n] = true end
        end
      end
    end
  end
  return out
end
local FIXTURES = { "hunter", "warrior", "paladin", "rogue", "priest", "shaman", "mage", "warlock", "druid" }

-- A spell counts as placed when the resolved item is the spell itself, or a
-- macro whose plain-spell fallback is that spell (macros aren't installed
-- in the harness, so the fallback resolves).
local function Collect(env, class, specKey)
  local C, AB, L = env.ns.modules.controller, env.ns.modules.actionbars, env.ns.Layout
  local known = C.Known()
  local kb, pad = {}, {}
  local p = AB.Plan()
  for i = 1, 12 do if p[1][i] and p[1][i].name then kb[p[1][i].name] = true end end
  local bars = L.KeyboardBars(class, specKey)
  for _, st in ipairs(bars and bars.stances or {}) do
    for i = 1, 12 do
      local entry = st.entries[i]
      if entry then
        local item = C.Resolve(entry, known, {})
        if item and not item.missing then kb[item.name] = true end
      end
    end
  end
  for slotID, e in pairs(C.Plan()[1] or {}) do
    if type(slotID) == "number" and e.item and not e.item.missing then pad[e.item.name] = true end
  end
  return kb, pad, known
end

test("rotations: every spec's Wowhead rotation is on keyboard rotation keys and controller page 1", function()
  local missing = {}
  for _, fx in ipairs(FIXTURES) do
    local probe = H.boot({ fixture = fx })
    local _, class = probe.G.UnitClass("player")
    local specIndex = {}
    for i, sp in ipairs(probe.ns.Layout.Specs(class)) do specIndex[sp.key] = i end
    for _, spec in ipairs(probe.ns.Layout.Specs(class)) do
      local list = ROT[class] and ROT[class][spec.key]
      ok(list, class .. "/" .. spec.key .. " has a rotation list")
      local tree = TreeNames(class, specIndex[spec.key])
      local env = H.boot({ fixture = fx, charDB = { spec = spec.key }, setup = function(W)
        for _, s in ipairs(W.fixture.catalog or {}) do if tree[s.name] then table.insert(W.fixture.spells, s) end end
        -- Other trees' talents a fixture lists as known (Stormstrike) are forgotten.
        local other = {}
        for t = 1, 3 do if t ~= specIndex[spec.key] then for n in pairs(TreeNames(class, t)) do if not tree[n] then other[n] = true end end end end
        for i = #W.fixture.spells, 1, -1 do if other[W.fixture.spells[i].name] then table.remove(W.fixture.spells, i) end end
      end })
      local kb, pad, known = Collect(env, class, spec.key)
      for _, name in ipairs(list or {}) do
        if known[name] then
          if not kb[name] then missing[#missing + 1] = class .. "/" .. spec.key .. ": " .. name .. " not on a keyboard rotation key" end
          if not pad[name] then missing[#missing + 1] = class .. "/" .. spec.key .. ": " .. name .. " not on controller page 1" end
        else
          missing[#missing + 1] = class .. "/" .. spec.key .. ": " .. name .. " unknown to the fixture"
        end
      end
    end
  end
  eq(#missing, 0, "\n" .. table.concat(missing, "\n"))
end)

test("macros: every recommended macro names its class and real spec keys", function()
  local env = H.boot()
  local L, Lay = env.ns.MacroLibrary, env.ns.Layout
  local bad, n = {}, 0
  for _, m in ipairs(L.macros) do
    if m.specs then
      n = n + 1
      if not m.class then bad[#bad + 1] = m.name .. ": specs without a class" end
      for _, k in ipairs(m.specs) do
        if m.class and not Lay.SpecByKey(m.class, k) then bad[#bad + 1] = m.name .. ": unknown spec " .. tostring(k) end
      end
      local tagged = false
      for _, t in ipairs(m.tags or {}) do if t == "recommended" then tagged = true end end
      if not tagged then bad[#bad + 1] = m.name .. ": no recommended tag" end
    end
  end
  eq(#bad, 0, "\n" .. table.concat(bad, "\n"))
  ok(n >= 0, n .. " recommended macros")
end)

test("macros page: your spec's recommended macros wear the star", function()
  local env = H.boot({ charDB = { spec = "bm" } })
  local L = env.ns.MacroLibrary
  local mine, other = 0, 0
  for _, m in ipairs(L.Entries(true)) do
    if L.ForMySpec(m) then mine = mine + 1 elseif m.class == "HUNTER" then other = other + 1 end
  end
  ok(mine >= 2, "BM has recommended macros: " .. mine)
  env:slash("macros")
  noErrors(env)
end)
