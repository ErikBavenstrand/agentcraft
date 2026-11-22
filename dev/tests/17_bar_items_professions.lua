-- What Agentcraft places from your bags, and the profession spells (owner
-- decisions 2026-11-22): only equipped on-use trinkets, the Hearthstone and
-- the Cozy Sleeping Bag go on any bar; every profession spell gets one
-- home, by name, though WoW Forever knows some under two spell IDs; Apply
-- clears old copies on side bars.
local H = require("harness")

local function Bars56(e) e.G.CreateFrame("Frame", "MultiBar5"); e.G.CreateFrame("Frame", "MultiBar6") end
local function Bars678(e) Bars56(e); e.G.CreateFrame("Frame", "MultiBar7") end

-- Consumables in the hunter fixture's bags: food, drink, potion, bandage.
local CONSUMABLES = { [8952] = "Roasted Quail", [8766] = "Morning Glory Dew",
  [13446] = "Major Healing Potion", [14530] = "Heavy Runecloth Bandage" }

local function NoConsumables(env, where)
  for slot, a in pairs(env.W.actions) do
    if a.type == "item" then ok(not CONSUMABLES[a.id], where .. ": slot " .. slot .. " holds " .. tostring(CONSUMABLES[a.id])) end
  end
end

-- Spell names in action slots from..to, counted.
local function SpellCount(env, from, to)
  local n = {}
  for slot = from, to do
    local t = env:slotText(slot)
    local name = t and t:match("^spell:(.+)$")
    if name then n[name] = (n[name] or 0) + 1 end
  end
  return n
end

test("bars: Alt holds only the on-use trinket and the Hearthstone; nothing else from the bags", function()
  local env = H.boot({ pet = true })
  local AB = env.ns.modules.actionbars
  local p = AB.Plan()
  for i = 1, 12 do
    local e = p[3][i]
    -- Alt+F/G are the Fish and Bait macro homes (18_fishing_homes.lua).
    if i == 5 or i == 6 then eq(e.kind, "macro", "Alt key " .. i .. " is a macro home, not an item")
    elseif i == 7 then eq(e.id, 11122, "Alt+C: the trinket with a Use effect")
    elseif i == 8 then eq(e.id, nil, "Alt+V: the equipped trinket has no Use effect")
    elseif i == 12 then eq(e.id, 6948, "Alt+4: Hearthstone")
    else eq(e.kind, nil, "Alt key " .. i .. " is not in the layout") end
  end
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(55), "item:11122", "Alt+C placed")
  eq(env:slotText(56), nil, "Alt+V empty")
  eq(env:slotText(60), "item:6948", "Alt+4 placed")
  NoConsumables(env, "keyboard")
  eq(AB.Plan().changes, 0, "plan agrees with apply")
  -- A utility list naming a consumable never resolves.
  eq(AB.ResolveUtilityItem({ "Major Healing Potion" }), nil, "potions are never placed")
  eq(AB.ResolveUtilityItem({ "Hearthstone" }), 6948)
end)

test("controller: only the trinket and the Hearthstone; no food, drink or potion homes", function()
  local env = H.boot({ pet = true })
  env:slash("controller apply")
  noErrors(env)
  NoConsumables(env, "controller")
  local items = {}
  for slot = 181, 276 do
    local a = env.W.actions[slot]
    if a and a.type == "item" then items[a.id] = true end
  end
  ok(items[11122], "the on-use trinket has a controller home")
  ok(items[6948], "the Hearthstone has a controller home")
  local n = 0
  for _ in pairs(items) do n = n + 1 end
  eq(n, 2, "no other item on the controller")
  for _, def in ipairs(env.ns.Layout.controller.HUNTER.pages) do
    for key, entry in pairs(def) do
      if type(entry) == "table" and entry.utility then
        ok(entry.utility == 7 or entry.utility == 8, key .. " is a trinket home, not a consumable")
      end
    end
  end
  eq(#env:calls("CreateMacro"), 0, "Apply never creates a macro")
end)

test("bars: Alt keys outside the layout: Agentcraft's old consumables are cleared, your own buttons stay", function()
  local env = H.boot({ pet = true })
  local AB = env.ns.modules.actionbars
  env:slash("spells apply")
  -- As the bars looked after an Apply from before the record of placed
  -- slots: the old Alt bar had food on Alt+1; you put a spell on Alt+Q.
  AB.charDB.placed = nil
  env.W.actions[57] = { type = "item", id = 8952 }
  env.W.actions[49] = { type = "spell", id = 6197 }
  local p = AB.Plan()
  eq(p[3][9].state, "clear", "Alt+1: the old food is cleared")
  eq(p[3][1].state, "free", "Alt+Q: your own spell is left alone")
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(57), nil, "old food gone")
  eq(env:slotText(49), "spell:Eagle Eye", "your Alt+Q stays")
  -- After the record exists: an item you put on Alt+2 yourself stays too.
  env.W.actions[58] = { type = "item", id = 8766 }
  eq(AB.Plan()[3][10].state, "free", "Alt+2 holds your own item")
  env:slash("spells apply")
  eq(env.W.actions[58] and env.W.actions[58].id, 8766, "your Alt+2 stays")
  eq(AB.Plan().changes, 0, "plan agrees with apply")
end)

test("side bars: a profession known under two spell IDs gets one home, the spellbook's ID", function()
  local env = H.boot({ pet = true, loaded = Bars56 })
  local p = env.ns.modules.actionbars.Plan()
  local count, id = {}, {}
  for r = 5, #p.rows do
    for i = 1, 12 do
      local e = p[r][i]
      if e.name then count[e.name] = (count[e.name] or 0) + 1; id[e.name] = e.id end
    end
  end
  eq(count["Engineering"], 1, "Engineering once (listed under 4036 and 1240958)")
  eq(id["Engineering"], 4036, "the first ID the spellbook lists")
  eq(count["Cooking"], 1, "Cooking once (18260 in the class line, 1240956 in the profession)")
  eq(id["Cooking"], 18260, "the class spellbook line's ID")
  eq(count["Bait and Tackle"], 1, "a profession's own spell")
  env:slash("spells apply")
  noErrors(env)
  local n = SpellCount(env, 1, 180)
  eq(n["Engineering"], 1, "one Engineering on the keyboard bars")
  eq(n["Cooking"], 1, "one Cooking on the keyboard bars")
  -- Controller: a set entry once each, the catch-all included.
  local cp = env.ns.modules.controller.Plan()
  local cc = {}
  for page = 1, 3 do
    for slotID, e in pairs(cp[page]) do
      if type(slotID) == "number" and e.item and e.item.kind == "spell" then
        cc[e.item.name] = (cc[e.item.name] or 0) + 1
        if e.item.name == "Engineering" then eq(e.item.id, 4036, "controller uses the spellbook's Engineering") end
      end
    end
  end
  eq(cc["Engineering"], 1, "one Engineering on the controller")
  eq(cc["Cooking"], 1, "one Cooking on the controller")
  eq(cc["Bait and Tackle"], 1, "Bait and Tackle on the controller catch-all")
end)

test("side bars: Apply clears old copies left on side bars; Undo puts them back", function()
  local env = H.boot({ pet = true, loaded = Bars678 })
  local AB = env.ns.modules.actionbars
  -- The old mapping: First Aid on Action Bar 5 and 6, an old Cooking ID on
  -- Action Bar 8 (no longer filled), and a spell of yours next to it.
  env.W.actions[43] = { type = "spell", id = 18629 }
  env.W.actions[150] = { type = "spell", id = 18629 }
  env.W.actions[170] = { type = "spell", id = 1240956 }
  env.W.actions[171] = { type = "spell", id = 14287 }
  local p = AB.Plan()
  for r = 5, #p.rows do ok(p.rows[r].label ~= "Action Bar 8", "Action Bar 8 is not managed this time") end
  eq(#p.stale, 1, "one old copy on an unmanaged bar")
  eq(p.stale[1] and p.stale[1].slot, 170)
  env:slash("spells apply")
  noErrors(env)
  local n = SpellCount(env, 1, 180)
  eq(n["First Aid"], 1, "First Aid once")
  eq(n["Cooking"], 1, "Cooking once")
  eq(env.W.actions[170], nil, "old Cooking cleared")
  eq(env:slotText(171), "spell:Arcane Shot", "your own spell on Action Bar 8 stays")
  ok(env:chatText():find("cleared old copies", 1, true), env:chatText())
  local after = AB.Plan()
  eq(after.changes, 0, "plan agrees with apply")
  eq(#after.stale, 0)
  env:slash("spells undo")
  noErrors(env)
  eq(env.W.actions[170] and env.W.actions[170].id, 1240956, "Undo puts the old copy back")
  eq(env.W.actions[43] and env.W.actions[43].id, 18629, "Undo restores Action Bar 5")
end)

-- The Cozy Sleeping Bag (owner request 2026-11-22: "on click keyboard and
-- bound on controller"): a click-only side-bar slot after the professions,
-- and controller set 2, no trigger + D-pad left. 248000 is the fixture's ID.
local BAG = 248000
local function WithBag(W) table.insert(W.fixture.bags[0], BAG) end

-- Item IDs in keyboard slots 1-180 and controller slots 181-276.
local function ItemsIn(env, from, to)
  local out = {}
  for slot = from, to do
    local a = env.W.actions[slot]
    if a and a.type == "item" then out[a.id] = slot end
  end
  return out
end

local function SideEntry(plan, name)
  for r = 5, #plan.rows do
    for i = 1, 12 do
      local e = plan[r][i]
      if e.name == name then return e, plan.rows[r] end
    end
  end
end

local function PadEntry(env, key)
  local cp = env.ns.modules.controller.Plan()
  for slotID, e in pairs(cp[2]) do
    if type(slotID) == "number" and e.key == key then return e end
  end
end

test("sleeping bag: in your bags, it lands on Action Bar 6 after the professions, once, and on controller set 2", function()
  local env = H.boot({ pet = true, setup = WithBag, loaded = Bars56 })
  local AB = env.ns.modules.actionbars
  local e, row = SideEntry(AB.Plan(), "Cozy Sleeping Bag")
  ok(e, "the plan has a side slot for the bag")
  eq(row and row.label, "Action Bar 6", "on the tracking and professions bar")
  eq(e.kind, "item")
  eq(e.id, BAG)
  eq(e.state, "new", "placed when you apply")
  env:slash("spells apply")
  noErrors(env)
  local kb = ItemsIn(env, 1, 180)
  local slot = kb[BAG]
  ok(slot and slot > 144 and slot <= 156, "on Action Bar 6 (slot " .. tostring(slot) .. ")")
  eq(slot, e.slot, "where the plan said")
  for s = 49, 60 do ok(env.W.actions[s] == nil or env.W.actions[s].id ~= BAG, "not on the Alt bar") end
  eq(AB.charDB.placed[slot], "item:" .. BAG, "recorded as placed by Agentcraft")
  local n = 0
  for s = 1, 180 do if env.W.actions[s] and env.W.actions[s].id == BAG then n = n + 1 end end
  eq(n, 1, "one home on the keyboard")
  -- Nothing else from the bags: trinket, Hearthstone, sleeping bag.
  for id in pairs(kb) do ok(id == 11122 or id == 6948 or id == BAG, "item " .. id .. " is allowed") end
  NoConsumables(env, "keyboard")
  local after = AB.Plan()
  eq(after.changes, 0, "plan agrees with apply")
  eq(SideEntry(after, "Cozy Sleeping Bag").state, "same", "in place")
  -- Controller: set 2, no trigger + D-pad left.
  local pe = PadEntry(env, "none Left")
  ok(pe and pe.item and pe.item.kind == "item" and pe.item.id == BAG, "controller none Left resolves the bag")
  env:slash("controller apply")
  noErrors(env)
  eq(env.W.actions[pe.slot] and env.W.actions[pe.slot].id, BAG, "controller none Left holds the bag")
  local pad = ItemsIn(env, 181, 276)
  for id in pairs(pad) do ok(id == 11122 or id == 6948 or id == BAG, "controller item " .. id .. " is allowed") end
  -- Undo puts the side bar back the way it was (empty).
  env:slash("spells undo")
  noErrors(env)
  eq(env.W.actions[slot], nil, "Undo clears the bag's side slot")
end)

test("sleeping bag: not in your bags, its side slot and controller home wait; nothing is placed", function()
  local env = H.boot({ pet = true, loaded = Bars56 })
  local AB = env.ns.modules.actionbars
  local e = SideEntry(AB.Plan(), "Cozy Sleeping Bag")
  ok(e, "the plan still shows the slot")
  eq(e.kind, "item")
  eq(e.state, "missing", "waiting: none in your bags")
  ok(AB.Plan().itemsMissing >= 1, "counted as an item not in bags")
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env.W.actions[e.slot], nil, "the side slot stays empty")
  for s = 1, 276 do ok(not (env.W.actions[s] and env.W.actions[s].id == BAG), "no bag in slot " .. s) end
  local pe = PadEntry(env, "none Left")
  eq(pe and pe.item.missing, "Cozy Sleeping Bag", "controller none Left waits")
  eq(pe and pe.item.reason, "carry")
  eq(AB.Plan().changes, 0, "plan agrees with apply")
end)

test("sleeping bag: only listed bag items get a side slot; one home per device", function()
  local env = H.boot({ pet = true, setup = WithBag, loaded = Bars56 })
  local AB = env.ns.modules.actionbars
  -- A side-item list naming food never places it: only M.BAG_ITEMS count.
  AB.SIDE_ITEMS = { "Cozy Sleeping Bag", "Roasted Quail" }
  ok(not SideEntry(AB.Plan(), "Roasted Quail"), "food never gets a side slot")
  eq(AB.ResolveUtilityItem({ "Roasted Quail" }), nil)
  eq(AB.ResolveUtilityItem({ "Cozy Sleeping Bag" }), BAG)
  -- An Alt key naming the bag takes it off the side bars.
  local saved = AB.utility[9]
  AB.utility[9] = { "Cozy Sleeping Bag" }
  ok(not SideEntry(AB.Plan(), "Cozy Sleeping Bag"), "no side slot while the Alt bar holds it")
  AB.utility[9] = saved
  AB.SIDE_ITEMS = { "Cozy Sleeping Bag" }
  env:slash("spells apply")
  noErrors(env)
  NoConsumables(env, "keyboard")
end)

test("sleeping bag: without Action Bars 6-8 it shares Action Bar 5 and gives up its slot before any spell", function()
  local env = H.boot({ pet = true, setup = function(W)
    WithBag(W)
    for i = 1, 20 do table.insert(W.fixture.spells, { name = "Fake Spell " .. i, id = 900000 + i }) end
  end })
  local p = env.ns.modules.actionbars.Plan()
  ok(#p.dropped > 0, "more than fits")
  eq(p.dropped[#p.dropped], "Cozy Sleeping Bag", "the bag is the first to give up its slot")
  ok(not SideEntry(p, "Cozy Sleeping Bag"), "no side slot")
  env:slash("spells apply")
  noErrors(env)
  for s = 1, 180 do ok(not (env.W.actions[s] and env.W.actions[s].id == BAG), "no bag in slot " .. s) end
end)
