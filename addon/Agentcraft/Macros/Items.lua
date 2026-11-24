-- Item macros: Fish, Bait, HealPot, ManaPot, Bandage and Food name the best
-- item you carry, and Agentcraft rewrites them when that changes (owner
-- decision, 2026-11-24: "Having macros be auto generated with items is ok
-- actually as long as Agentcraft can easily update them"). Hand-written
-- library macros still name no items.
--
-- The macros themselves are in Macros/Data/General.lua (generated = "<key>").
-- L.generators[key]() returns the body for the best item you carry (and that
-- item's name), or nil when you carry none: then the macro's own body runs,
-- which prints "no <thing> in your bags". That is clearer than keeping the
-- last item: a button naming an item you no longer have does nothing, with
-- no hint why.
--
-- The same macros and homes for every class and spec (Alt+Q E R T F G on
-- the keyboard, controller page 2 LT X Y B Left, LT A and none Up). Class
-- consumables are handled the same way everywhere:
--   * HealPot: a warlock's Healthstone first (free, its own cooldown, gone
--     once used, so the macro moves on to your best potion), then potions.
--   * ManaPot: a mage's mana gem first, by the same reasoning, then potions.
--     Warriors and rogues have no mana: ManaPot is not offered to them
--     (power = "mana") and its homes stay empty.
--   * Food: a mage's conjured food wins over bought or cooked food of the
--     same tier (it is free). Raw meat and fish (hunter pet food and cooking
--     material) and quest items are never in the lists. Cooked foods with a
--     buff are used only when you carry no plain food. Drinks are not food.
--   * Bandage: only bandages your First Aid skill allows.
--
-- Item lists are Classic names (WoW Forever runs Classic content), best
-- first. Each entry is { "Item Name", level = n, skill = n }: level is the
-- fallback when the client hasn't the item's required level cached
-- (C_Item.GetItemInfo's minLevel wins when it has); skill is the First Aid
-- (bandages) or Fishing (bait, poles) skill it needs. Keep every value a
-- literal: dev.ps1 reads these names without running Lua.
-- Sources: warcraft.wiki.gg and wowhead classic item pages (required level
-- and skill), checked 2026-11.
local _, ns = ...
local L = ns.MacroLibrary

L.ITEMS = {
  -- Fishing poles, by Fishing bonus. A pole you carry that is not listed
  -- (any weapon of the fishing pole subclass) beats only the plain one.
  poles = {
    { "Arcanite Fishing Pole" },
    { "Nat Pagle's Extreme Angler FC-5000" },
    { "Big Iron Fishing Pole", skill = 100 },
    { "Seth's Graphite Fishing Pole" },
    { "Darkwood Fishing Pole", level = 15 },
    { "Strong Fishing Pole", level = 10 },
    { "Blump Family Fishing Pole" },
    { "Fishing Pole" },
  },
  -- Fishing lures (the Bait macro), by bonus.
  baits = {
    { "Aquadynamic Fish Attractor", skill = 100 },
    { "Bright Baubles", skill = 100 },
    { "Flesh Eating Worm", skill = 100 },
    { "Aquadynamic Fish Lens", skill = 50 },
    { "Nightcrawlers", skill = 50 },
    { "Shiny Bauble", skill = 50 },
  },
  -- Warlock Healthstones: HealPot's first choice.
  healthstones = {
    { "Major Healthstone" },
    { "Greater Healthstone" },
    { "Healthstone" },
    { "Lesser Healthstone" },
    { "Minor Healthstone" },
  },
  healpots = {
    { "Major Healing Potion", level = 45 },
    { "Superior Healing Potion", level = 35 },
    { "Greater Healing Potion", level = 21 },
    { "Healing Potion", level = 12 },
    { "Lesser Healing Potion", level = 3 },
    { "Minor Healing Potion", level = 1 },
  },
  -- Mage mana gems: ManaPot's first choice.
  managems = {
    { "Mana Ruby" },
    { "Mana Citrine" },
    { "Mana Jade" },
    { "Mana Agate" },
  },
  manapots = {
    { "Major Mana Potion", level = 49 },
    { "Superior Mana Potion", level = 41 },
    { "Greater Mana Potion", level = 31 },
    { "Mana Potion", level = 22 },
    { "Lesser Mana Potion", level = 14 },
    { "Minor Mana Potion", level = 5 },
  },
  -- First Aid bandages, by the First Aid skill they need.
  bandages = {
    { "Heavy Runecloth Bandage", skill = 225 },
    { "Runecloth Bandage", skill = 200 },
    { "Heavy Mageweave Bandage", skill = 175 },
    { "Mageweave Bandage", skill = 150 },
    { "Heavy Silk Bandage", skill = 125 },
    { "Silk Bandage", skill = 100 },
    { "Heavy Wool Bandage", skill = 75 },
    { "Wool Bandage", skill = 50 },
    { "Heavy Linen Bandage", skill = 20 },
    { "Linen Bandage", skill = 1 },
  },
  -- Plain restoring food by tier (required level); in each tier the mage's
  -- conjured food comes first. Raw Black Truffle is a vendor mushroom, not
  -- raw meat.
  food = {
    { "Conjured Cinnamon Roll", level = 55 },
    { "Conjured Sweet Roll", level = 45 },
    { "Homemade Cherry Pie", level = 45 },
    { "Roasted Quail", level = 45 },
    { "Deep Fried Plantains", level = 45 },
    { "Alterac Swiss", level = 45 },
    { "Dried King Bolete", level = 45 },
    { "Spinefin Halibut", level = 45 },
    { "Conjured Sourdough", level = 35 },
    { "Soft Banana Bread", level = 35 },
    { "Cured Ham Steak", level = 35 },
    { "Moon Harvest Pumpkin", level = 35 },
    { "Fine Aged Cheddar", level = 35 },
    { "Raw Black Truffle", level = 35 },
    { "Spotted Yellowtail", level = 35 },
    { "Conjured Pumpernickel", level = 25 },
    { "Mulgore Spice Bread", level = 25 },
    { "Wild Hog Shank", level = 25 },
    { "Goldenbark Apple", level = 25 },
    { "Stormwind Brie", level = 25 },
    { "Delicious Cave Mold", level = 25 },
    { "Rockscale Cod", level = 25 },
    { "Conjured Rye", level = 15 },
    { "Moist Cornbread", level = 15 },
    { "Mutton Chop", level = 15 },
    { "Snapvine Watermelon", level = 15 },
    { "Dwarven Mild", level = 15 },
    { "Spongy Morel", level = 15 },
    { "Bristle Whisker Catfish", level = 15 },
    { "Conjured Bread", level = 5 },
    { "Freshly Baked Bread", level = 5 },
    { "Haunch of Meat", level = 5 },
    { "Tel'Abim Banana", level = 5 },
    { "Dalaran Sharp", level = 5 },
    { "Red-speckled Mushroom", level = 5 },
    { "Longjaw Mud Snapper", level = 5 },
    { "Conjured Muffin", level = 1 },
    { "Tough Hunk of Bread", level = 1 },
    { "Tough Jerky", level = 1 },
    { "Shiny Red Apple", level = 1 },
    { "Darnassian Bleu", level = 1 },
    { "Forest Mushroom Cap", level = 1 },
    { "Slitherskin Mackerel", level = 1 },
  },
  -- Cooked foods that also give a buff: used only when you carry no plain
  -- food above, so a buff food you saved for a fight isn't eaten first.
  buffFood = {
    { "Runn Tum Tuber Surprise", level = 45 },
    { "Smoked Desert Dumplings", level = 45 },
    { "Nightfin Soup", level = 35 },
    { "Grilled Squid", level = 35 },
    { "Cooked Glossy Mightfish", level = 35 },
    { "Monster Omelet", level = 35 },
    { "Tender Wolf Steak", level = 35 },
    { "Roast Raptor", level = 25 },
    { "Big Bear Steak", level = 15 },
    { "Crocolisk Steak", level = 15 },
    { "Goretusk Liver Pie", level = 5 },
    { "Boiled Clams", level = 5 },
    { "Coyote Steak", level = 5 },
    { "Herb Baked Egg", level = 1 },
    { "Spiced Wolf Meat", level = 1 },
    { "Roasted Boar Meat", level = 1 },
    { "Charred Wolf Meat", level = 1 },
    { "Smoked Bear Meat", level = 1 },
  },
}

-- Reading your bags and skills ---------------------------------------------------

local function ItemName(id)
  local name = C_Item and C_Item.GetItemInfo and C_Item.GetItemInfo(id)
  if not name and C_Item and C_Item.GetItemNameByID then name = C_Item.GetItemNameByID(id) end
  return name
end

-- Every item you carry, by name -> item ID; withMainHand adds the weapon in
-- your hands (a pole you already hold counts as carried).
local function Carried(withMainHand)
  local out = {}
  local numSlots = C_Container and C_Container.GetContainerNumSlots
  local itemID = C_Container and C_Container.GetContainerItemID
  if numSlots and itemID then
    for bag = 0, NUM_BAG_SLOTS or 4 do
      for slot = 1, numSlots(bag) or 0 do
        local id = itemID(bag, slot)
        local name = id and ItemName(id)
        if name and not out[name] then out[name] = id end
      end
    end
  end
  if withMainHand then
    local id = GetInventoryItemID("player", 16)
    local name = id and ItemName(id)
    if name and not out[name] then out[name] = id end
  end
  return out
end
L.CarriedItems = Carried

-- Your rank in a profession or secondary skill ("First Aid", "Fishing"):
-- 0 when you don't have it, nil when this client can't tell (then no item
-- is held back for skill).
function L.SkillRank(name)
  if GetProfessions and GetProfessionInfo then
    local list = { GetProfessions() }
    for p = 1, select("#", GetProfessions()) do
      if list[p] then
        local n, _, rank = GetProfessionInfo(list[p])
        if n == name then return rank or 0 end
      end
    end
    return 0
  end
  if GetNumSkillLines and GetSkillLineInfo then
    for i = 1, GetNumSkillLines() or 0 do
      local n, header, _, rank = GetSkillLineInfo(i)
      if n == name and not header then return rank or 0 end
    end
    return 0
  end
  return nil
end

-- The level an item needs: the client's minLevel when it has the item
-- cached, else the list's level.
local function MinLevel(id, fallback)
  local info = C_Item and C_Item.GetItemInfo
  local level = info and select(5, info(id))
  if type(level) == "number" then return level end
  return fallback or 0
end

-- The first entry of list you carry and can use: { name, id } or nil.
-- skillName names the skill an entry's skill = n counts against.
local function Pick(list, carried, skillName)
  local level = UnitLevel("player") or 1
  local rank = skillName and L.SkillRank(skillName)
  for _, e in ipairs(list) do
    local id = carried[e[1]]
    if id and MinLevel(id, e.level) <= level and not (e.skill and rank and rank < e.skill) then
      return e[1], id
    end
  end
end

-- Builders -------------------------------------------------------------------------
-- Each returns the macro body and the item it names, or nil when you carry
-- none. Bodies fit 255 characters with the longest listed name (tested).

local function UseBody(name) return "#showtooltip " .. name .. "\n/use " .. name end

local function BestPole()
  local carried = Carried(true)
  local name = Pick(L.ITEMS.poles, carried, "Fishing")
  if name and name ~= "Fishing Pole" then return name end
  -- A pole the list doesn't know beats only the plain Fishing Pole.
  local listed = {}
  for _, e in ipairs(L.ITEMS.poles) do listed[e[1]] = true end
  local other
  for n, id in pairs(carried) do
    if not listed[n] and L.IsPole(id) and (not other or n < other) then other = n end
  end
  return other or name
end

L.generators = {
  -- Fish: with a pole in your hands it fishes; otherwise it equips the best
  -- pole you carry. [equipped:] takes the client's own pole subtype name.
  fish = function()
    local pole = BestPole()
    if not pole then return nil end
    return "#showtooltip Fishing\n/cast [equipped:{POLETYPE}] Fishing\n/stopmacro [equipped:{POLETYPE}]\n/equip " .. pole, pole
  end,
  -- Bait: the best lure you carry and may use, onto the pole in your main
  -- hand. Only one /use, so no other lure can take the cursor.
  bait = function()
    local name = Pick(L.ITEMS.baits, Carried(), "Fishing")
    if not name then return nil end
    return "#showtooltip " .. name .. "\n/use " .. name .. "\n/use 16", name
  end,
  healpot = function()
    local carried = Carried()
    local name = Pick(L.ITEMS.healthstones, carried) or Pick(L.ITEMS.healpots, carried)
    if not name then return nil end
    return UseBody(name), name
  end,
  manapot = function()
    local carried = Carried()
    local name = Pick(L.ITEMS.managems, carried) or Pick(L.ITEMS.manapots, carried)
    if not name then return nil end
    return UseBody(name), name
  end,
  -- Bandage: always on yourself, whatever you target.
  bandage = function()
    local name = Pick(L.ITEMS.bandages, Carried(), "First Aid")
    if not name then return nil end
    return "#showtooltip " .. name .. "\n/use [@player] " .. name, name
  end,
  food = function()
    local carried = Carried()
    local name = Pick(L.ITEMS.food, carried) or Pick(L.ITEMS.buffFood, carried)
    if not name then return nil end
    return UseBody(name), name
  end,
}

-- The item a generated macro names right now, or nil when you carry none.
function L.GeneratedItem(m)
  local gen = m and m.generated and L.generators[m.generated]
  if not gen then return nil end
  local _, name = gen()
  return name
end

-- What a generated macro picks from, for the Macros page ("best healing
-- potion you carry").
L.GENERATED_WHAT = {
  fish = "fishing pole", bait = "fishing bait", healpot = "Healthstone or healing potion",
  manapot = "mana gem or mana potion", bandage = "bandage", food = "food",
}

-- The updater -----------------------------------------------------------------------
-- Rewrites installed item macros when the best item may have changed: bags,
-- level (potions and food need one) and skills (bandages, bait). Debounced
-- to one run a second after the last change, never in combat (queued until
-- it ends), and only macros whose text actually changes are written
-- (L.UpdateGenerated). Turn it off with /ac off ItemMacros.
local M = ns.RegisterModule("ItemMacros", {
  title = "Item Macros",
  order = 55,
  description = "Keeps the Fish, Bait, HealPot, ManaPot, Bandage and Food macros on the best item in your bags.",
})

local DELAY = 1
local timer, queued = nil, false

local function Run()
  timer = nil
  if InCombatLockdown() then queued = true return end
  queued = false
  local done = L.UpdateGenerated()
  if done and #done > 0 then
    if ns.LogLine then ns.LogLine("item macros updated: " .. table.concat(done, ", ")) end
    if ns.UI and ns.UI.Refresh then pcall(ns.UI.Refresh) end
  end
end
M.Run = Run

-- Each change restarts the one-second wait, so a burst of bag events (loot,
-- a vendor) costs one run.
local function Schedule()
  if InCombatLockdown() then queued = true return end
  if timer then timer:Cancel() end
  timer = C_Timer.NewTimer(DELAY, Run)
end
M.Schedule = Schedule

-- Whether an update waits for combat to end (tests and the Macros page).
function M.Queued() return queued end

M.events = {
  PLAYER_ENTERING_WORLD = Schedule,
  BAG_UPDATE_DELAYED = Schedule,
  PLAYER_LEVEL_UP = Schedule,
  SKILL_LINES_CHANGED = Schedule,
  PLAYER_REGEN_ENABLED = function() if queued then queued = false; Schedule() end end,
}
