-- The shared controller buttons (Layouts/Shared.lua) and the profession
-- slots (owner request, 2026-11-24): every class's page 2 gets the same
-- Hearthstone, trinket, fishing, camp, Mount and profession buttons; the
-- profession slots and Action Bar 6 fill from the character's own
-- professions in one stable order; a character with fewer leaves the last
-- slots waiting; profession spells never get a class home or a catch-all
-- button of their own.
local H = require("harness")
local R = require("rules")

local FIXTURES = { "hunter", "warrior", "paladin", "rogue", "priest", "shaman", "mage", "warlock", "druid" }
local SLOT_KEYS = { "LT+RT A", "LT+RT Y", "LT+RT X", "LT+RT B", "LT+RT Down", "LT+RT Up", "LT+RT Left", "LT+RT Right" }

local function Bars56(e) e.G.CreateFrame("Frame", "MultiBar5"); e.G.CreateFrame("Frame", "MultiBar6") end

-- Controller slot for page `set` and a key like "LT+RT A".
local LAYER = { none = 0, LT = 1, RT = 2, ["LT+RT"] = 3 }
local BUTTON = { Left = 1, Up = 2, Right = 3, Down = 4, X = 5, Y = 6, B = 7, A = 8 }
local function Pad(set, key)
  local layer, button = key:match("^(%S+) (%S+)$")
  local n = LAYER[layer] * 8 + BUTTON[button]
  return 180 + (set - 1) * 28 + (n < 5 and n or n - 4)
end

local function Names(list)
  local out = {}
  for i, s in ipairs(list) do out[i] = s.name end
  return table.concat(out, ", ")
end

-- Names on the extra side bar rows of the plan (Action Bars 5-8), in order.
local function SideNames(env)
  local p = env.ns.modules.actionbars.Plan()
  local out, set = {}, {}
  for r = 5, #p.rows do
    for i = 1, 12 do
      local e = p[r][i]
      if e and e.name then out[#out + 1] = e.name; set[e.name] = r end
    end
  end
  return out, set, p
end

local HERB_ALCH = {
  { name = "Herbalism", icon = 136246, spells = {
    { name = "Herbalism", id = 2366, icon = 136246 },
    { name = "Find Herbs", id = 2383, icon = 133939 },
  } },
  { name = "Alchemy", icon = 136240, spells = {
    { name = "Alchemy", id = 2259, icon = 136240 },
  } },
}

test("professions: the hunter's (Mining, Engineering) in the stable order", function()
  local env = H.boot({ pet = true })
  local list = env.ns.modules.actionbars.ProfessionSpells()
  eq(Names(list), "Mining, Engineering, Cooking, First Aid, Bait and Tackle, Find Minerals, Smelting")
  env:slash("controller apply")
  noErrors(env)
  local want = { "spell:Mining", "spell:Engineering", "spell:Cooking", "spell:First Aid",
    "spell:Bait and Tackle", "spell:Find Minerals", "spell:Smelting", nil }
  for i, key in ipairs(SLOT_KEYS) do eq(env:slotText(Pad(2, key)), want[i], "page 2 " .. key) end
  -- The tested page's spots stay: Engineering on Y, Cooking X, First Aid B,
  -- Bait and Tackle Down (env:padSlot pins them from the game).
  eq(env:slotText(env:padSlot(2, "LT+RT Y")), "spell:Engineering")
  eq(env:slotText(env:padSlot(2, "LT+RT X")), "spell:Cooking")
  eq(env:slotText(env:padSlot(2, "LT+RT B")), "spell:First Aid")
  eq(env:slotText(env:padSlot(2, "LT+RT Down")), "spell:Bait and Tackle")
  local plan = env.ns.modules.controller.Plan()
  local last
  for slotID, e in pairs(plan[2]) do
    if type(slotID) == "number" and e.key == "LT+RT Right" then last = e end
  end
  ok(last and last.item.missing, "8th profession slot waits")
  eq(last.item.reason, "profession")
  eq(plan.changes, 0, "plan agrees with apply")
end)

test("professions: the catch-all skips a spell with a profession slot", function()
  local env = H.boot({ pet = true })
  local plan = env.ns.modules.controller.Plan()
  local count = {}
  for page = 1, 3 do
    for slotID, e in pairs(plan[page]) do
      if type(slotID) == "number" and e.item and e.item.kind == "spell" then count[e.item.name] = (count[e.item.name] or 0) + 1 end
    end
  end
  for _, n in ipairs({ "Mining", "Engineering", "Cooking", "First Aid", "Bait and Tackle", "Find Minerals", "Smelting" }) do
    eq(count[n], 1, n .. " has exactly one controller home")
  end
end)

test("professions: a warrior with Herbalism and Alchemy gets its own, not the hunter's", function()
  local env = H.boot({ fixture = "warrior", professions = HERB_ALCH, loaded = Bars56 })
  eq(Names(env.ns.modules.actionbars.ProfessionSpells()), "Herbalism, Alchemy, Find Herbs")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(Pad(2, "LT+RT A")), "spell:Herbalism")
  eq(env:slotText(Pad(2, "LT+RT Y")), "spell:Alchemy")
  eq(env:slotText(Pad(2, "LT+RT X")), "spell:Find Herbs")
  -- Fewer professions: the other five slots wait, empty.
  for i = 4, 8 do eq(env:slotText(Pad(2, SLOT_KEYS[i])), nil, SLOT_KEYS[i] .. " waits") end
  local names, set = SideNames(env)
  ok(set["Herbalism"] and set["Alchemy"] and set["Find Herbs"], "side bars: " .. table.concat(names, ", "))
  ok(not set["Mining"] and not set["Smelting"] and not set["Find Minerals"], "no hunter professions on the side bars")
  for slot = 1, 276 do
    local t = env:slotText(slot)
    ok(t ~= "spell:Mining" and t ~= "spell:Smelting", "slot " .. slot .. " holds no Mining spell")
  end
end)

test("side bars: Action Bar 6 = tracking, professions in the stable order, then camp items", function()
  local env = H.boot({ pet = true, loaded = Bars56, setup = function(W)
    W.fixture.items[248000] = { name = "Cozy Sleeping Bag", icon = 133665 }
    table.insert(W.fixture.bags[0], 248000)
  end })
  local p = env.ns.modules.actionbars.Plan()
  local row
  for r = 5, #p.rows do if p.rows[r].first == 144 then row = r end end
  ok(row, "an Action Bar 6 row")
  local names = {}
  for i = 1, 12 do local e = p[row][i]; if e and e.name then names[#names + 1] = e.name end end
  eq(table.concat(names, ", "), "Find Minerals, Track Beasts, Track Humanoids, Mining, Engineering, Cooking, "
    .. "First Aid, Bait and Tackle, Smelting, Basic Campfire, Fishing, Cozy Sleeping Bag")
  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(148), "spell:Mining", "Action Bar 6 slot 4")
end)

test("shared: every class's page 2 has the identical shared buttons, for every spec", function()
  local ref -- this boot's shared page 2 (the same file for every class)
  for _, fixture in ipairs(FIXTURES) do
    local env = H.boot({ fixture = fixture })
    local L = env.ns.Layout
    local shared = L.shared.controller.pages[2]
    ok(shared and shared["RT Up"] and shared["LT+RT A"], "shared page 2")
    ref = shared
    local class = env.W.fixture.class[2]
    for _, spec in ipairs(L.Specs(class)) do
      local pages = L.ControllerPages(class, spec.key)
      for key, entry in pairs(ref) do
        if key ~= "title" then eq(pages[2][key], entry, class .. " (" .. spec.key .. ") page 2 " .. key) end
      end
      eq(pages[2].title, "Utility", class .. " page 2 title")
    end
    -- The class files hold no shared button themselves.
    for _, page in pairs(L.controller[class].pages) do
      if page == L.controller[class].pages[2] then
        for key in pairs(ref) do if key ~= "title" then eq(page[key], nil, class .. " own page 2 " .. key) end end
      end
    end
  end
end)

test("shared: every class applies its page 2 with the shared Hearthstone and Fish homes", function()
  for _, fixture in ipairs(FIXTURES) do
    local env = H.boot({ fixture = fixture })
    env:slash("controller apply")
    noErrors(env)
    eq(env:slotText(Pad(2, "RT Up")), "item:6948", fixture .. " Hearthstone on page 2 RT Up")
    eq(#env:calls("CreateMacro"), 0, fixture .. ": Apply never creates a macro")
  end
end)

test("rules: a class page naming a shared button or a profession spell is an error", function()
  local env = H.boot({ fixture = "warrior" })
  local L = env.ns.Layout
  local page2 = L.controller.WARRIOR.pages[2]
  page2["RT Up"] = { "Bloodrage" }
  L.controller.WARRIOR.pages[1]["RT A"] = { "Smelting" }
  L.keyboard.WARRIOR[4][12] = { profession = 1 }
  local found = {}
  for _, p in ipairs(R.CheckLayout(L, "WARRIOR", {})) do
    if p.severity == "error" then found[p.rule] = (found[p.rule] or 0) + 1 end
  end
  ok(found["layout-shared"], "a shared key in the class page")
  ok(found["layout-profession"], "a profession spell in a class layout")
  ok(found["layout-keyboard"], "a profession slot on the keyboard")
end)

-- WoW Forever lists Mining's own spell outside the Mining skill line (which
-- holds only Smelting and Find Minerals); Mining still takes its primary
-- slot (owner's capture, 0.35.0: Mining fell to a page 3 catch-all button).
test("professions: a primary whose own spell sits outside its skill line keeps its slot", function()
  local env = H.boot({ pet = true, setup = function(W)
    local mining = W.fixture.professions[1]
    for i = #mining.spells, 1, -1 do
      if mining.spells[i].name == "Mining" then table.remove(mining.spells, i) end
    end
    table.insert(W.fixture.spells, { name = "Mining", id = 1240973, icon = 136248 })
  end })
  local list = env.ns.modules.actionbars.ProfessionSpells()
  eq(Names(list), "Mining, Engineering, Cooking, First Aid, Bait and Tackle, Find Minerals, Smelting")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(Pad(2, "LT+RT A")), "spell:Mining", "Mining on its primary slot")
end)

test("professions: the Legacy perk Dedicated Study takes the next profession slot", function()
  local env = H.boot({ fixture = "warrior", professions = HERB_ALCH, loaded = Bars56, setup = function(W)
    table.insert(W.fixture.spells, { name = "Dedicated Study", id = 1300901, icon = 136240 })
  end })
  eq(Names(env.ns.modules.actionbars.ProfessionSpells()), "Herbalism, Alchemy, Find Herbs, Dedicated Study")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(Pad(2, "LT+RT B")), "spell:Dedicated Study", "4th profession slot")
end)
