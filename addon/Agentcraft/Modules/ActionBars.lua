-- ActionBars: fills your action bars from a per-class profile.
--   /ac spells        show the plan for your class
--   /ac spells apply  place everything (saves current bar contents first)
--   /ac spells undo   put the bars back the way they were
--
-- Keyed bars (keys come from the Keybinds module):
--   slot:  1 2 3 4 5 6 7 8 9 10 11 12
--   key:   Q E R T F G C V 1 2  3  4
--   Bar 1 = key, Bar 2 = Shift+key, Bar 3 = Alt+key (all classes: the item
--   macros HealPot, ManaPot, Bandage and Food on Alt+Q/E/R/T and Fish and
--   Bait on Alt+F/G once installed, on-use trinkets on Alt+C/V and the
--   Hearthstone on Alt+4), Bar 4 = Ctrl+key
-- Click-only side bars, grouped automatically from your spellbook (a spell
-- on a keyed bar never shows here too: one home per spell):
--   Action Bar 5 = pet spells, then other class spells not on a keyed bar
--   Action Bar 6 = tracking, then professions (your own, in the stable
--   order of M.ProfessionSpells, the same as the controller's shared
--   profession slots; then Fishing and Basic Campfire), then the camp items
--   in M.SIDE_ITEMS (the Cozy Sleeping Bag), placed only while in your bags
--   Action Bars 7-8 take what doesn't fit, class spells first.
--   Action Bars 6-8 count only when the client has them. Without them,
--   everything shares Action Bar 5: camp items, professions, then tracking,
--   then pet utilities give up their slot before a class spell does.
-- The only bag items on any bar: the Hearthstone (Alt+4) and the Cozy
-- Sleeping Bag (side bar), plus your equipped on-use trinkets (Alt+C/V).
-- Potions, bandages, food, bait and poles reach a key only through the
-- generated item macros (Macros/Items.lua), never as item buttons.
--   Each spell goes on the side bars once, by name: WoW Forever knows some
--   professions under an old and a new spell ID (Cooking 3102 and 1240956),
--   and the side bars take the ID the spellbook lists.
--   Apply empties every slot of a side bar it manages before filling it, and
--   also clears a second copy of a side-bar spell (or anything it placed
--   itself) left on an Action Bar 6-8 it no longer manages.
-- Spells/items you don't have yet are skipped; apply again after training
-- or when you get new items.
local _, ns = ...
local M = ns.RegisterModule("ActionBars", {
  title = "Action Bars",
  order = 10,
  description = "Fills your keyboard action bars from your class layout.",
})

-- First action slot of each keyed bar: bar 1 = 1-12, bar 2 (bottom
-- left) = 61-72, bar 3 (bottom right) = 49-60, bar 4 (right) = 25-36.
local BAR_OFFSET = { 0, 60, 48, 24 }
-- Keyed bars filled from the layout (bar 3 is the utility bar).
local LAYOUT_BARS = { 1, 2, 4 }
local SIDE_BAR = 36 -- Action Bar 5 (right 2), slots 37-48: the first side bar

-- Action Bars 6-8 of the modern client (slots 145-180). Classic clients
-- have no such bars, so they count only when their frame exists. A bar is
-- managed once Apply puts something on it (M.charDB.extraBars), so a bar
-- the layout never needs is never touched.
local EXTRA_BARS = {
  { first = 144, command = "MULTIACTIONBAR5BUTTON", frame = "MultiBar5", label = "Action Bar 6" },
  { first = 156, command = "MULTIACTIONBAR6BUTTON", frame = "MultiBar6", label = "Action Bar 7" },
  { first = 168, command = "MULTIACTIONBAR7BUTTON", frame = "MultiBar7", label = "Action Bar 8" },
}
local function ExtraBars()
  local list = {}
  for _, b in ipairs(EXTRA_BARS) do
    local frame = _G[b.frame]
    if type(frame) == "table" and frame.GetName and frame:GetName() == b.frame then list[#list + 1] = b end
  end
  return list
end
local function ExtraBarHidden(b)
  local f = _G[b.frame]
  return f and f.IsShown and not f:IsShown() or false
end

-- Per-class keyboard layouts for classes without a role layout in Layout.lua:
--   M.profiles.<CLASS> = { { 12 spell names for bar 1 }, { 12 for bar 2 }, [3] = utility override,
--                          [4] = { 12 for bar 4, the Ctrl layer } }
-- Classes with a role layout (Layout.lua) use it instead, shared with the controller.
M.profiles = {}

-- Bar 3 (Alt) for every class, identical for every class and spec (no
-- class layout sets it). The only item buttons Agentcraft ever places are
-- your equipped on-use trinkets, the Hearthstone and the Cozy Sleeping Bag
-- (owner rules, 2026-11-22; the bag sits on a side bar, not here): food,
-- potions, bandages and bait come only through the generated item macros
-- (owner decision, 2026-11-24; Macros/Items.lua keeps them on the best item
-- you carry). An entry is a list of item names
-- (the first one you carry is used), trinket1/trinket2 (the equipped
-- trinket, only when it has an on-use effect) or { macro = "Fish" } (that
-- library macro once you installed it on the Macros page; Apply never
-- creates it, and the key waits until then). An Alt key without an entry
-- (false) is not in the layout: Apply clears it only when Agentcraft put
-- what it holds there, and leaves anything of yours alone.
-- The Fishing spell itself keeps its click-only side-bar home: the Fish
-- macro is the convenient key, and side bars never take macros.
M.utility = {
  { macro = "HealPot" }, -- Alt+Q  Healthstone, else best healing potion (Shift+Q is the self-heal spell)
  { macro = "ManaPot" }, -- Alt+E  mana gem, else best mana potion (empty on warriors and rogues)
  { macro = "Bandage" }, -- Alt+R  best bandage on yourself
  { macro = "Food" },    -- Alt+T  best food for your level
  { macro = "Fish" },  -- Alt+F  (owner request, 2026-11-22)
  { macro = "Bait" },  -- Alt+G  best fishing bait you carry onto the pole
  "trinket1",          -- Alt+C
  "trinket2",          -- Alt+V
  false, false, false, -- Alt+1 2 3: not in the layout
  { "Hearthstone" },   -- Alt+4
}

-- Groups for the click-only side bars.
local PET_SPELLS = {
  ["Call Pet"] = 1, ["Dismiss Pet"] = 2, ["Revive Pet"] = 3, ["Feed Pet"] = 4,
  ["Tame Beast"] = 5, ["Beast Training"] = 6, ["Beast Lore"] = 7,
  ["Eyes of the Beast"] = 8, ["Scare Beast"] = 9,
}
local PROFESSIONS = {
  "Alchemy", "Blacksmithing", "Enchanting", "Disenchant", "Engineering",
  "Leatherworking", "Tailoring", "Mining", "Smelting", "Herbalism", "Skinning",
  "Cooking", "Basic Campfire", "Fishing", "First Aid", "Pick Lock", "Survey",
}
local PROFESSION_RANK = {}
for i, name in ipairs(PROFESSIONS) do PROFESSION_RANK[name] = i end
local IGNORE = { ["Attack"] = true, ["Auto Attack"] = true, ["Auto Shot"] = true, ["Shoot"] = true, ["Throw"] = true, ["Cultivation"] = true }
-- "Call Pet" shows in the spellbook as "Call <pet name>", so match it by ID.
local CALL_PET_ID = 883

local function PetRank(name, id) return PET_SPELLS[name] or (id == CALL_PET_ID and PET_SPELLS["Call Pet"]) or nil end
local function IsPet(name, id) return PetRank(name, id) or name:find("^Summon ") end
local function IsTracking(name) return name:find("^Track ") or name:find("^Find ") or name:find("^Sense ") end

-- Map of known (castable) spell name -> spell ID. Later ranks come later in
-- the spellbook, so the highest rank wins.
local function KnownSpells()
  local map = {}
  if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
    local bank = Enum.SpellBookSpellBank.Player
    local spellType = Enum.SpellBookItemType and Enum.SpellBookItemType.Spell
    for tab = 1, C_SpellBook.GetNumSpellBookSkillLines() do
      local line = C_SpellBook.GetSpellBookSkillLineInfo(tab)
      if line then
        for i = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
          local item = C_SpellBook.GetSpellBookItemInfo(i, bank)
          -- Spells only: no future (unlearned) spells, flyouts or pet actions.
          if item and item.spellID and item.name and not item.isPassive
            and (not spellType or item.itemType == nil or item.itemType == spellType) then
            map[item.name] = item.spellID
          end
        end
      end
    end
  else
    for tab = 1, GetNumSpellTabs() do
      local _, _, offset, num = GetSpellTabInfo(tab)
      for i = offset + 1, offset + num do
        local name = GetSpellBookItemName(i, BOOKTYPE_SPELL)
        local _, id = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
        local passive = IsPassiveSpell and IsPassiveSpell(i, BOOKTYPE_SPELL)
        if name and id and not passive then map[name] = id end
      end
    end
  end
  return map
end

-- Spell ID for a spell you know by name, from the game's own lookup.
local function LookupKnown(name)
  local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(name)
  local id = info and info.spellID
  if id and ((IsPlayerSpell and IsPlayerSpell(id)) or (IsSpellKnown and IsSpellKnown(id))) then return id end
end

-- Names the class skill lines miss: profession spells and the pet spells.
local SIDE_EXTRAS = { "Find Minerals", "Find Herbs" }
for _, name in ipairs(PROFESSIONS) do table.insert(SIDE_EXTRAS, name) end
for name in pairs(PET_SPELLS) do table.insert(SIDE_EXTRAS, name) end

-- The profession lists of Layout.lua (the stable profession order).
local function ProfData() return ns.Layout and ns.Layout.PROFESSIONS end
do
  local P = ProfData()
  local seen = {}
  for _, n in ipairs(SIDE_EXTRAS) do seen[n] = true end
  for _, list in ipairs(P and { P.primary, P.secondary, P.fishing, P.utility } or {}) do
    for _, n in ipairs(list) do
      if not seen[n] then seen[n] = true; table.insert(SIDE_EXTRAS, n) end
      if not PROFESSION_RANK[n] then PROFESSION_RANK[n] = #PROFESSIONS + 1 end
    end
  end
end

-- Your professions as GetProfessions lists them (client: primary 1,
-- primary 2, archaeology, fishing, cooking, first aid; empty ones are nil):
-- { { name =, spells = { { name =, id = }, ... } }, ... }, the castable
-- spellbook entries of each.
local function ProfessionLines()
  local out = {}
  if not (GetProfessions and GetProfessionInfo and C_SpellBook and C_SpellBook.GetSpellBookItemInfo) then return out end
  local bank = Enum.SpellBookSpellBank.Player
  local list = { GetProfessions() }
  for p = 1, select("#", GetProfessions()) do
    if list[p] then
      local name, _, _, _, numSpells, offset = GetProfessionInfo(list[p])
      local line = { name = name, spells = {} }
      for i = (offset or 0) + 1, (offset or 0) + (numSpells or 0) do
        local ok, item = pcall(C_SpellBook.GetSpellBookItemInfo, i, bank)
        if ok and item and item.spellID and item.name and not item.isPassive then
          line.spells[#line.spells + 1] = { name = item.name, id = item.spellID }
        end
      end
      out[#out + 1] = line
    end
  end
  return out
end

-- The known map plus profession spells, which live outside the class skill
-- lines. Returns name -> ID and the set of names from your professions.
-- One ID per name: WoW Forever lists some professions under an old and a
-- new spell ID with the same name (Cooking 3102 / 1240956, Engineering 4038
-- / 1240958). The first source that names a spell wins, spellbook first:
-- the class skill lines, then the profession spellbook entries in the
-- order C_SpellBook lists them, and only then the game's lookup by name.
-- An ID already taken under another name is skipped too.
local function SideKnown(known)
  local ids, have, prof = {}, {}, {}
  for name, id in pairs(known) do ids[name] = id; have[id] = true end
  local function Add(name, id, fromProfession)
    if name and id and not ids[name] and not have[id] then
      ids[name], have[id] = id, true
      if fromProfession then prof[name] = true end
    end
  end
  for _, line in ipairs(ProfessionLines()) do
    for _, s in ipairs(line.spells) do Add(s.name, s.id, true) end
  end
  for _, name in ipairs(SIDE_EXTRAS) do
    if not ids[name] then Add(name, LookupKnown(name)) end
  end
  return ids, prof
end

-- Your profession spells in the stable order of Layout.PROFESSIONS, for the
-- shared { profession = n } controller slots and Action Bar 6:
-- { { name =, id = }, ... }. ids: the name -> ID map to take IDs from
-- (SideKnown's; built when nil), so a profession known under two IDs gets
-- the same one everywhere.
--   1-2. Each primary's own spell (the one named like the profession; else
--        its first spell that is not a gathering/utility spell), in the
--        order GetProfessions lists them, then primaries known only by name.
--   3-5. Cooking, First Aid, fishing helpers (Bait and Tackle).
--   6+.  Every other spell of your professions: Layout.PROFESSIONS.utility
--        order (Find Minerals, Find Herbs, Smelting, Disenchant...), then
--        alphabetically.
-- Fishing and Basic Campfire never count (shared homes of their own).
local function ProfessionSpells(ids)
  local P = ProfData()
  if not P then return {} end
  ids = ids or (SideKnown(KnownSpells()))
  local out, seen = {}, {}
  local function Add(name, id)
    if not name or seen[name] or P.skip[name] then return end
    id = ids[name] or id or LookupKnown(name)
    if not id then return end
    seen[name] = true
    out[#out + 1] = { name = name, id = id }
  end
  local utilRank = {}
  for i, n in ipairs(P.utility) do utilRank[n] = i end
  local lines, byName = ProfessionLines(), {}
  for _, l in ipairs(lines) do if l.name then byName[l.name] = l end end
  local primaries = {}
  for _, l in ipairs(lines) do if l.name and not P.lines[l.name] then primaries[#primaries + 1] = l end end
  -- Clients without GetProfessions: a primary you know by its own spell.
  for _, n in ipairs(P.primary) do
    if not byName[n] and ids[n] then primaries[#primaries + 1] = { name = n, spells = { { name = n, id = ids[n] } } } end
  end
  local rest = {}
  for _, l in ipairs(primaries) do
    local main
    for _, s in ipairs(l.spells) do if s.name == l.name then main = s; break end end
    -- WoW Forever lists Mining's own spell (1240973) outside the Mining
    -- skill line, which holds only Find Minerals and Smelting; take it by
    -- name so Mining keeps its primary slot (owner's capture, 0.35.0).
    if not main and ids[l.name] then main = { name = l.name, id = ids[l.name] } end
    if not main then
      for _, s in ipairs(l.spells) do if not utilRank[s.name] and not P.skip[s.name] then main = s; break end end
    end
    if main then Add(main.name, main.id) end
    for _, s in ipairs(l.spells) do if s.name ~= (main and main.name) then rest[#rest + 1] = s end end
  end
  local function Line(name)
    local l = byName[name]
    Add(name, nil)
    for _, s in ipairs(l and l.spells or {}) do if s.name == name then Add(s.name, s.id) else rest[#rest + 1] = s end end
  end
  Line("Cooking")
  Line("First Aid")
  for _, s in ipairs(byName["Fishing"] and byName["Fishing"].spells or {}) do Add(s.name, s.id) end
  for _, n in ipairs(P.fishing) do Add(n, nil) end
  for _, s in ipairs(byName["Archaeology"] and byName["Archaeology"].spells or {}) do rest[#rest + 1] = s end
  for _, n in ipairs(P.utility) do rest[#rest + 1] = { name = n } end
  local function Rank(s) return utilRank[s.name] or 99 end
  table.sort(rest, function(a, b)
    if Rank(a) ~= Rank(b) then return Rank(a) < Rank(b) end
    return a.name < b.name
  end)
  for _, s in ipairs(rest) do Add(s.name, s.id) end
  return out
end
M.ProfessionSpells = ProfessionSpells

-- Items ------------------------------------------------------------------

local GetItemInfoCompat = (C_Item and C_Item.GetItemInfo) or GetItemInfo

local function ItemInfo(id)
  local name = GetItemInfoCompat(id)
  -- GetItemInfo returns nothing for items not cached yet; the name lookup still works.
  if not name and C_Item and C_Item.GetItemNameByID then name = C_Item.GetItemNameByID(id) end
  return name
end

local function ItemSpell(id)
  if C_Item and C_Item.GetItemSpell then return C_Item.GetItemSpell(id) end
  return GetItemSpell(id)
end

-- Bag items Agentcraft may place, by name (the trinkets come from your
-- equipment, not your bags). Anything else in a utility list, a layout
-- { item = } entry or M.SIDE_ITEMS is never placed.
M.BAG_ITEMS = { ["Hearthstone"] = true, ["Cozy Sleeping Bag"] = true }

-- Bag items with a click-only home on the side bars (owner request,
-- 2026-11-22: the WoW Forever camp item), after the professions on Action
-- Bar 6. Each is placed only while it is in your bags (waiting otherwise),
-- and skipped when a keyed bar or the Alt bar names it: one home per device.
M.SIDE_ITEMS = { "Cozy Sleeping Bag" }

-- Every distinct item in your bags: { [name] = id }.
local function BagItems()
  local byName = {}
  local numSlots = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
  local itemID = C_Container and C_Container.GetContainerItemID or GetContainerItemID
  for bag = 0, 4 do
    for slot = 1, numSlots(bag) or 0 do
      local id = itemID(bag, slot)
      if id then
        local name = ItemInfo(id)
        if name and not byName[name] then byName[name] = id end
      end
    end
  end
  return byName
end

local function ResolveUtility(entry, bags)
  if entry == "trinket1" or entry == "trinket2" then
    local id = GetInventoryItemID("player", entry == "trinket1" and 13 or 14)
    if id and ItemSpell(id) then return id end -- only on-use trinkets
    return nil
  end
  if type(entry) ~= "table" or entry.macro then return nil end -- a macro entry is no item
  for _, name in ipairs(entry) do
    if M.BAG_ITEMS[name] and bags[name] then return bags[name] end
  end
end

-- For other modules (Controller): item ID for a utility entry, or nil.
function M.ResolveUtilityItem(entry)
  return ResolveUtility(entry, BagItems())
end

-- For other modules: known spell name -> highest-rank spell ID.
function M.KnownSpellIDs() return KnownSpells() end

-- For other modules (the controller): known spells plus your profession
-- spells, one ID per name, the spellbook's ID first (see SideKnown).
function M.SideSpellIDs() return (SideKnown(KnownSpells())) end

-- Display name of a utility entry nobody carries yet (display only).
local SPECIAL_LABEL = { trinket1 = "On-use trinket (top)", trinket2 = "On-use trinket (bottom)" }
local function UtilityLabel(entry)
  if type(entry) == "string" then return SPECIAL_LABEL[entry] or entry end
  if entry.macro then return entry.macro end
  return entry[#entry]  -- the weakest item; its state line says a better one counts too
end
M.UtilityLabel = UtilityLabel

-- Placement ----------------------------------------------------------------

local function PickupSpellID(id)
  if C_Spell and C_Spell.PickupSpell then C_Spell.PickupSpell(id) else PickupSpell(id) end
end

local function PickupItemID(id)
  if C_Item and C_Item.PickupItem then C_Item.PickupItem(id) else PickupItem(id) end
end

local function ClearSlot(slot)
  if HasAction(slot) then PickupAction(slot); ClearCursor() end
end

local function PlaceSpell(slot, id) PickupSpellID(id); PlaceAction(slot); ClearCursor() end
local function PlaceItem(slot, id) PickupItemID(id); if GetCursorInfo() then PlaceAction(slot) end; ClearCursor() end

-- Bars 1, 2 and 4 come from the shared role layout (Layout.lua) when the
-- class has one, so keyboard and controller agree; otherwise from M.profiles.
-- Returns { [1] = entries, [2] = entries, [3] = utility override, [4] = entries }.
local function Profile()
  local _, class = UnitClass("player")
  local bars = ns.Layout and ns.Layout.KeyboardBars(class)
  local legacy = M.profiles[class]
  if bars then
    bars[3] = legacy and legacy[3]
    return bars, class
  end
  if not legacy then return nil, class end
  local out = { {}, {}, legacy[3], {} }
  for _, bar in ipairs(LAYOUT_BARS) do
    for i, name in pairs(legacy[bar] or {}) do out[bar][i] = { name } end
  end
  return out, class
end

-- Resolve a layout entry (spell names, flyout, macro, racial) with the
-- controller module's resolver, which knows every entry form.
local function ResolveEntry(entry, known)
  local C = ns.modules.controller
  if C and C.Resolve then return C.Resolve(entry, known) end
  for _, n in ipairs(entry) do
    if known[n] then return { kind = "spell", id = known[n], name = n } end
  end
  return { missing = entry[#entry] or "?" }
end

-- An Alt-bar macro entry ({ macro = "Fish" }): the macro's name, else nil.
local function AltMacro(entry) return type(entry) == "table" and entry.macro or nil end

-- Resolves an Alt-bar macro entry: { kind = "macro", name } once the macro
-- is installed, else { missing, macro, reason = "install" }. Never creates it.
local function ResolveAltMacro(entry)
  local C = ns.modules.controller
  if C and C.Resolve then return C.Resolve({ macro = entry.macro }, {}) end
  local i = GetMacroIndexByName(entry.macro)
  if i and i > 0 then return { kind = "macro", name = entry.macro, installed = true } end
  return { missing = entry.macro .. " macro", macro = entry.macro, reason = "install" }
end

-- Puts an installed macro on a slot, by name (macro indexes shift).
local function PlaceMacro(slot, item)
  local C = ns.modules.controller
  if C and C.Place then return C.Place(slot, item) end
  local i = GetMacroIndexByName(item.name)
  if i and i > 0 then PickupMacro(i); if GetCursorInfo() then PlaceAction(slot) end end
  ClearCursor()
end

-- "Waiting · install Fish on the Macros page", as the Controller page says it.
local function InstallText(name)
  local C = ns.modules.controller
  if C and C.InstallText then return C.InstallText(name) end
  return "Waiting · install " .. tostring(name) .. " on the Macros page"
end

-- Every keyed entry of a profile: bars 1, 2 and 4, then Bar 1's stance
-- pages. fn(entry) runs once per entry.
local function EachKeyed(profile, fn)
  for _, bar in ipairs(LAYOUT_BARS) do
    for _, entry in pairs(profile[bar] or {}) do fn(entry) end
  end
  for _, st in ipairs(profile.stances or {}) do
    for _, entry in pairs(st.entries or {}) do fn(entry) end
  end
end

-- Bar 1's stance pages (bonus bars, slots 73-120) that Apply manages: the
-- profile's, plus the ones an earlier Apply filled (charDB.stanceBars), so
-- it clears a page the spec no longer has. { first =, key =, label =,
-- offset =, entries = } by offset; an old page has no entries.
local function StanceOffset(first) return (first - 72) / 12 + 1 end
local function UsedStanceBars(profile)
  local list, seen = {}, {}
  for _, st in ipairs(profile and profile.stances or {}) do list[#list + 1] = st; seen[st.first] = true end
  for first in pairs(M.charDB.stanceBars or {}) do
    first = tonumber(first)
    if first and not seen[first] then
      list[#list + 1] = { first = first, offset = StanceOffset(first), key = "old" .. first,
        label = "Stance page " .. StanceOffset(first), entries = {}, old = true }
    end
  end
  table.sort(list, function(a, b) return a.first < b.first end)
  return list
end

-- Stance pages the backup covers, for Undo.
local function SavedStanceBars()
  local list = {}
  for first in pairs(M.charDB.backup and M.charDB.backup.stance or {}) do
    if tonumber(first) then list[#list + 1] = { first = tonumber(first) } end
  end
  table.sort(list, function(a, b) return a.first < b.first end)
  return list
end

-- First slot offset of the stance page (bonus bar) a slot is on, or nil.
local function StanceBarOf(slot)
  if slot > 72 and slot <= 120 then return 72 + math.floor((slot - 73) / 12) * 12 end
end

-- Slots Apply and Undo manage: bars 1-5, plus the given Action Bars 6-8
-- and Bar 1 stance pages.
local function ManagedSlots(extra, stances)
  local slots = {}
  for bar = 1, 4 do
    for i = 1, 12 do table.insert(slots, BAR_OFFSET[bar] + i) end
  end
  for i = 1, 12 do table.insert(slots, SIDE_BAR + i) end
  for _, b in ipairs(extra or {}) do
    for i = 1, 12 do table.insert(slots, b.first + i) end
  end
  for _, st in ipairs(stances or {}) do
    for i = 1, 12 do table.insert(slots, st.first + i) end
  end
  return slots
end

-- First slot offset of the Action Bar 6-8 a slot is on, or nil.
local function ExtraBarOf(slot)
  if slot > 144 and slot <= 180 then return 144 + math.floor((slot - 145) / 12) * 12 end
end

-- Action Bars 6-8 that Apply manages: the ones that get spells now, plus
-- the ones an earlier Apply filled (so it clears what no longer belongs).
local function UsedExtraBars(extra, extraBars)
  local before = M.charDB.extraBars or {}
  local used = {}
  for b, bar in ipairs(extraBars) do
    if (extra[b] and next(extra[b])) or before[bar.first] then used[#used + 1] = bar end
  end
  return used
end

-- Action Bars 6-8 an earlier Apply filled, for Undo (even if the client
-- lost the frame since).
local function SavedExtraBars()
  local list = {}
  for _, b in ipairs(EXTRA_BARS) do
    if (M.charDB.extraBars or {})[b.first] then list[#list + 1] = b end
  end
  return list
end

-- What a slot holds, as Apply records it in M.charDB.placed: "spell:883".
local function SlotKey(slot)
  local t, id = GetActionInfo(slot)
  if t then return t .. ":" .. tostring(id) end
end

local function InAltBar(slot) return slot > BAR_OFFSET[3] and slot <= BAR_OFFSET[3] + 12 end

-- Whether Agentcraft put what a slot holds there. Apply records every slot
-- it fills (M.charDB.placed). Bars applied before that record existed
-- count an item on the Alt bar as ours, since the old Alt bar held only
-- items Apply picked from your bags, unless it is the item your own bars
-- had there before the first Apply.
local function PlacedByUs(slot)
  local key = SlotKey(slot)
  if not key then return false end
  local rec = M.charDB.placed
  if rec then return rec[slot] == key end
  local backup = M.charDB.backup
  if not backup or not InAltBar(slot) then return false end
  local t, id = GetActionInfo(slot)
  if t ~= "item" then return false end
  local saved = backup[slot]
  return not (saved and saved[1] == "item" and saved[2] == id)
end

-- An Alt key the layout leaves out (no utility entry), or a macro home
-- whose macro you haven't installed (HealPot on Alt+Q), that holds
-- something of yours: Apply leaves it alone, so a potion button you placed
-- yourself stays until you install the macro. One holding what Agentcraft
-- placed is cleared instead (the old consumables).
local function AltFree(slot, entry)
  if entry and not (AltMacro(entry) and ResolveAltMacro(entry).missing) then return false end
  return InAltBar(slot) and GetActionInfo(slot) ~= nil and not PlacedByUs(slot)
end

local function SpellNameOf(id)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
  return info and info.name
end

-- Stale copies on an Action Bar 6-8 that Apply doesn't manage this time
-- (an older layout put tracking and professions there): a spell whose name
-- the plan puts on a side bar, by name so an old profession ID counts, or
-- anything Apply placed there itself. Returns { { slot =, name = } }.
local function StaleSlots(side, extra, used)
  local names = {}
  for _, n in ipairs(side) do names[n] = true end
  for _, list in pairs(extra) do
    for _, n in pairs(list) do names[n] = true end
  end
  local managed = {}
  for _, b in ipairs(used) do managed[b.first] = true end
  local out = {}
  for _, b in ipairs(EXTRA_BARS) do
    if not managed[b.first] then
      for i = 1, 12 do
        local slot = b.first + i
        local t, id = GetActionInfo(slot)
        local name = t == "spell" and SpellNameOf(id) or nil
        if (name and names[name]) or PlacedByUs(slot) then
          local d = not name and ns.UI and ns.UI.DescribeSlot and ns.UI.DescribeSlot(slot)
          out[#out + 1] = { slot = slot, name = name or (d and d.name) or tostring(t) }
        end
      end
    end
  end
  return out
end

-- Learned spells not on a keyed bar, split over the side bars. Returns side
-- (Action Bar 5's list), the name -> spell ID map the lists draw from, extra
-- (one 12-slot list per available Action Bar 6-8: tracking, professions and
-- camp items on Action Bar 6, overflow on 7-8), dropped (names that fit
-- nowhere), the available extra bars, and items: the side-bar names that
-- are bag items (M.SIDE_ITEMS), name -> item ID, or false while the item is
-- not in your bags (a waiting slot; nothing is placed there).
local function SideBars(profile, known)
  local used = {}
  EachKeyed(profile, function(entry)
    -- Only the spell a home picked is placed; the alternatives it skipped
    -- still need a home. A macro home places its spell and covers = { ... }.
    local item = ResolveEntry(entry, known)
    if item.kind == "spell" and item.name then used[item.name] = true end
    if item.kind == "macro" then
      if entry[1] then used[entry[1]] = true end
      for _, n in ipairs(entry.covers or {}) do used[n] = true end
    end
    -- { "Better", "Lower rank", upgrade = true }: the lower one needs no home.
    if entry.upgrade then
      for _, n in ipairs(entry) do used[n] = true end
    end
  end)
  local ids, fromProfession = SideKnown(known)
  local function Rank(name) return PetRank(name, ids[name]) or 99 end
  -- Professions in the stable order the controller's profession slots use
  -- (ProfessionSpells), then the rest (Fishing, Basic Campfire...) by PROFESSIONS.
  local order = {}
  for i, s in ipairs(ProfessionSpells(ids)) do order[s.name] = i end
  local function ProfRank(name) return order[name] or (100 + (PROFESSION_RANK[name] or 99)) end
  local pet, other, tracking, prof = {}, {}, {}, {}
  for name in pairs(ids) do
    if not used[name] and not IGNORE[name] then
      if IsPet(name, ids[name]) then table.insert(pet, name)
      elseif IsTracking(name) then table.insert(tracking, name)
      elseif PROFESSION_RANK[name] or fromProfession[name] then table.insert(prof, name)
      else table.insert(other, name) end
    end
  end
  table.sort(pet, function(a, b) return Rank(a) < Rank(b) or (Rank(a) == Rank(b) and a < b) end)
  table.sort(other)
  table.sort(tracking)
  table.sort(prof, function(a, b) return ProfRank(a) < ProfRank(b) or (ProfRank(a) == ProfRank(b) and a < b) end)
  -- Camp items follow the professions, so they give up their slot first.
  -- One home per device: an item a keyed bar or the Alt bar names is skipped.
  local onKeys = {}
  EachKeyed(profile, function(entry)
    if type(entry) == "table" and entry.item then onKeys[entry.item] = true end
  end)
  for _, entry in pairs(profile[3] or M.utility) do
    if type(entry) == "table" then
      for _, n in ipairs(entry) do onKeys[n] = true end
    end
  end
  local items, bags = {}, nil
  for _, name in ipairs(M.SIDE_ITEMS) do
    if M.BAG_ITEMS[name] and not onKeys[name] and not ids[name] then
      bags = bags or BagItems()
      items[name] = bags[name] or false
      table.insert(prof, name)
    end
  end
  -- More entries than slots: the least needed give up their slot first
  -- (camp items, professions, then tracking, then pet utilities), never a
  -- class spell.
  local extraBars = ExtraBars()
  local room = 12 + 12 * #extraBars
  local dropped = {}
  local total = #pet + #other + #tracking + #prof
  while total > room do
    local from = (#prof > 0 and prof) or (#tracking > 0 and tracking) or (#pet > 0 and pet) or other
    table.insert(dropped, 1, table.remove(from))
    total = total - 1
  end
  local right, right2 = {}, {}
  for _, n in ipairs(pet) do table.insert(right, n) end
  for _, n in ipairs(other) do table.insert(right, n) end
  for _, n in ipairs(tracking) do table.insert(right2, n) end
  for _, n in ipairs(prof) do table.insert(right2, n) end
  local extra = {}
  if #extraBars == 0 then
    -- Only Action Bar 5: tracking and professions follow the class spells
    -- (the drops above made it all fit).
    for _, n in ipairs(right2) do table.insert(right, n) end
    return right, ids, extra, dropped, extraBars, items
  end
  -- Spill extras from one side bar into free room on the other.
  while #right > 12 and #right2 < 12 do table.insert(right2, table.remove(right)) end
  while #right2 > 12 and #right < 12 do table.insert(right, table.remove(right2)) end
  -- The rest goes to Action Bars 7-8, Action Bar 5's class spells first.
  local rest, rest2 = {}, {}
  while #right > 12 do table.insert(rest, 1, table.remove(right)) end
  while #right2 > 12 do table.insert(rest2, 1, table.remove(right2)) end
  for _, n in ipairs(rest2) do table.insert(rest, n) end
  extra[1] = {}
  for i = 1, 12 do extra[1][i] = right2[i] end
  for b = 2, #extraBars do
    extra[b] = {}
    for i = 1, 12 do extra[b][i] = rest[(b - 2) * 12 + i] end
  end
  return right, ids, extra, dropped, extraBars, items
end

-- Places a side-bar name: a spell, or a camp item while it is in your bags.
local function PlaceSide(slot, name, ids, items)
  local item = items[name]
  if item ~= nil then
    if item then PlaceItem(slot, item) end
  elseif ids[name] then
    PlaceSpell(slot, ids[name])
  end
end

-- Spellbook index of a flyout, by flyout ID (for undo).
local function FlyoutIndex(want)
  if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return end
  local bank = Enum.SpellBookSpellBank.Player
  for tab = 1, C_SpellBook.GetNumSpellBookSkillLines() do
    local line = C_SpellBook.GetSpellBookSkillLineInfo(tab)
    if line then
      for i = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
        local item = C_SpellBook.GetSpellBookItemInfo(i, bank)
        if item and item.itemType == Enum.SpellBookItemType.Flyout and item.actionID == want then return i end
      end
    end
  end
end

-- Action types undo can put back. Apply leaves slots of any other type alone.
local function Restorable(t)
  if t == "spell" or t == "item" or t == "macro" then return true end
  if t == "flyout" then return C_SpellBook and C_SpellBook.PickupSpellBookItem and true end
  if t == "summonmount" then
    return C_MountJournal and ((C_MountJournal.Pickup and C_MountJournal.GetDisplayedMountID)
      or C_MountJournal.GetMountInfoByID) and true
  end
  if t == "summonpet" then return _G.C_PetJournal and _G.C_PetJournal.PickupPet and true end
  if t == "equipmentset" then return C_EquipmentSet and C_EquipmentSet.PickupEquipmentSet and true end
  return false
end

-- Puts a backed-up action on the cursor. Macros go back by name, since
-- macro indexes shift when macros are created or deleted.
local function PickupSaved(t, id, text)
  if t == "spell" then PickupSpellID(id)
  elseif t == "item" then PickupItemID(id)
  elseif t == "macro" then
    local i = text and GetMacroIndexByName(text)
    if i and i > 0 then PickupMacro(i)
    elseif not text then PickupMacro(id) end -- backup from an older version
  elseif t == "flyout" then
    local index = FlyoutIndex(id)
    if index then C_SpellBook.PickupSpellBookItem(index, Enum.SpellBookSpellBank.Player) end
  elseif t == "summonmount" then
    -- Journal mounts aren't spellbook spells on modern clients: pick them up
    -- from the journal (as Controller does), with the mount spell as fallback.
    if C_MountJournal.Pickup and C_MountJournal.GetDisplayedMountID then
      for i = 1, C_MountJournal.GetNumDisplayedMounts and C_MountJournal.GetNumDisplayedMounts() or 0 do
        if C_MountJournal.GetDisplayedMountID(i) == id then C_MountJournal.Pickup(i); break end
      end
    end
    if not GetCursorInfo() and C_MountJournal.GetMountInfoByID then
      local _, spellID = C_MountJournal.GetMountInfoByID(id)
      if spellID then PickupSpellID(spellID) end
    end
  elseif t == "summonpet" then pcall(_G.C_PetJournal.PickupPet, id)
  elseif t == "equipmentset" then
    local setID = id
    if type(id) == "string" and C_EquipmentSet.GetEquipmentSetID then setID = C_EquipmentSet.GetEquipmentSetID(id) end
    if setID then pcall(C_EquipmentSet.PickupEquipmentSet, setID) end
  end
end

local function Apply()
  if InCombatLockdown() then return ns.Print("can't change bars in combat.") end
  local profile, class = Profile()
  if not profile then return ns.Print("no profile for " .. class .. " yet.") end
  local known = KnownSpells()
  local bags = BagItems()
  local side, ids, extra, dropped, extraBars, items = SideBars(profile, known)
  local used = UsedExtraBars(extra, extraBars)
  local stances = UsedStanceBars(profile)
  local slots = ManagedSlots(used, stances)
  local utility = profile[3] or M.utility
  -- Before the backup and the record change: what is ours is decided on
  -- the bars as they are now.
  local stale = StaleSlots(side, extra, used)
  local free = {}
  for i = 1, 12 do
    local slot = BAR_OFFSET[3] + i
    if AltFree(slot, utility[i]) then free[slot] = true end
  end

  -- Keep the very first backup, so undo always returns to the bars from
  -- before the first apply. An Action Bar 6-8 joins the backup the first
  -- time Apply manages it (backup.extra lists the ones it covers); a stale
  -- copy cleared from a bar Apply doesn't manage joins it on its own
  -- (backup.loose). Slots holding something undo can't put back, and Alt
  -- keys outside the layout that hold your own things, are left alone.
  -- A stance page joins the backup the same way, the first time Apply
  -- manages it (backup.stance lists the pages it covers).
  local first = not M.charDB.backup
  local backup = M.charDB.backup or {}
  local covered = backup.extra or {}
  local stanceCovered = backup.stance or {}
  local keep, kept = {}, 0
  for _, slot in ipairs(slots) do
    local t, id = GetActionInfo(slot)
    if t and not Restorable(t) then keep[slot] = true; kept = kept + 1 end
    if free[slot] then keep[slot] = true end
    local bar = ExtraBarOf(slot)
    local sbar = StanceBarOf(slot)
    if t and (first or (bar and not covered[bar]) or (sbar and not stanceCovered[sbar])) then
      backup[slot] = { t, id, t == "macro" and GetActionText(slot) or nil }
    end
  end
  for _, s in ipairs(stale) do
    if not covered[ExtraBarOf(s.slot)] then
      backup.loose = backup.loose or {}
      if not backup.loose[s.slot] then
        local t, id = GetActionInfo(s.slot)
        backup[s.slot] = { t, id, t == "macro" and GetActionText(s.slot) or nil }
        backup.loose[s.slot] = true
      end
    end
  end
  local extraUsed = {}
  for offset in pairs(M.charDB.extraBars or {}) do extraUsed[offset] = true end
  for _, b in ipairs(used) do covered[b.first] = true; extraUsed[b.first] = true end
  backup.extra = covered
  local stanceUsed = {}
  for _, st in ipairs(stances) do
    stanceCovered[st.first] = true
    if not st.old then stanceUsed[st.first] = true end
  end
  backup.stance = stanceCovered
  M.charDB.backup = backup
  M.charDB.extraBars = next(extraUsed) and extraUsed or nil
  -- An old page is cleared now and needs no managing after this Apply.
  M.charDB.stanceBars = next(stanceUsed) and stanceUsed or nil

  ClearCursor()
  for _, slot in ipairs(slots) do
    if not keep[slot] then ClearSlot(slot) end
  end
  for _, s in ipairs(stale) do ClearSlot(s.slot) end

  local missing = {}
  local C = ns.modules.controller
  for _, bar in ipairs(LAYOUT_BARS) do
    for i = 1, 12 do
      local entry = profile[bar] and profile[bar][i]
      local slot = BAR_OFFSET[bar] + i
      if entry and not keep[slot] then
        local item = ResolveEntry(entry, known)
        if item.missing then table.insert(missing, item.missing)
        elseif C and C.Place then C.Place(slot, item)
        elseif item.kind == "spell" then PlaceSpell(slot, item.id) end
      end
    end
  end
  -- Bar 1's stance pages go into their bonus bar slots.
  for _, st in ipairs(stances) do
    for i = 1, 12 do
      local entry = st.entries[i]
      local slot = st.first + i
      if entry and not keep[slot] then
        local item = ResolveEntry(entry, known)
        if item.missing then table.insert(missing, item.missing)
        elseif C and C.Place then C.Place(slot, item)
        elseif item.kind == "spell" then PlaceSpell(slot, item.id) end
      end
    end
  end

  for i = 1, 12 do
    local entry = utility[i]
    if entry and not keep[BAR_OFFSET[3] + i] then
      if AltMacro(entry) then
        -- Only an installed macro goes on; a missing one leaves the key empty.
        local item = ResolveAltMacro(entry)
        if item.missing then table.insert(missing, item.missing) else PlaceMacro(BAR_OFFSET[3] + i, item) end
      else
        local id = ResolveUtility(entry, bags)
        if id then PlaceItem(BAR_OFFSET[3] + i, id) end
      end
    end
  end

  for i, name in ipairs(side) do
    if not keep[SIDE_BAR + i] then PlaceSide(SIDE_BAR + i, name, ids, items) end
  end
  local hidden = {}
  for b, bar in ipairs(extraBars) do
    for i, name in pairs(extra[b] or {}) do
      if not keep[bar.first + i] then PlaceSide(bar.first + i, name, ids, items) end
    end
    if next(extra[b] or {}) and ExtraBarHidden(bar) then hidden[#hidden + 1] = bar.label end
  end

  -- Record what Apply placed, so the next Apply knows which slots are ours.
  local placed = {}
  for _, slot in ipairs(slots) do
    if not keep[slot] then placed[slot] = SlotKey(slot) end
  end
  M.charDB.placed = placed

  if #stale > 0 then
    local names = {}
    for i, s in ipairs(stale) do names[i] = s.name end
    ns.Print("cleared old copies from bars Agentcraft no longer fills: " .. table.concat(names, ", ") .. ".")
  end
  if #dropped > 0 then ns.Print("side bars full; these stay in the spellbook: " .. table.concat(dropped, ", ") .. ".") end
  if #hidden > 0 then ns.Print(table.concat(hidden, ", ") .. " hidden: turn on in Edit Mode to click those spells.") end

  ns.Print("bars set for " .. class .. ". /ac spells undo to go back.")
  if kept > 0 then ns.Print(kept .. " slots kept as they were (undo can't restore what they hold).") end
  if #missing > 0 then ns.Print("left empty (not learned yet, or macro not installed): " .. table.concat(missing, ", ")) end
end

-- A readable name for a backed-up action, for the "couldn't put back" list.
local function SavedName(saved)
  local t, id, text = saved[1], saved[2], saved[3]
  if text then return text end
  if t == "spell" then return ns.UI.SpellName(id) or ("spell " .. tostring(id)) end
  if t == "item" then return (ItemInfo(id)) or ("item " .. tostring(id)) end
  return tostring(t)
end

local function Undo()
  if InCombatLockdown() then return ns.Print("can't change bars in combat.") end
  local backup = M.charDB.backup
  if not backup then return ns.Print("nothing to undo.") end
  ClearCursor()
  local lost = {}
  local slots = ManagedSlots(SavedExtraBars(), SavedStanceBars())
  local listed = {}
  for _, slot in ipairs(slots) do listed[slot] = true end
  -- Stale copies Apply cleared from bars it doesn't manage go back too.
  for slot in pairs(backup.loose or {}) do
    if not listed[slot] then slots[#slots + 1] = slot end
  end
  for _, slot in ipairs(slots) do
    local saved = backup[slot]
    local cur = GetActionInfo(slot)
    -- Apply left slots it can't restore alone; so does undo.
    if not (cur and not Restorable(cur)) and not (saved and not Restorable(saved[1])) then
      ClearSlot(slot)
      if saved then
        PickupSaved(saved[1], saved[2], saved[3])
        -- A macro deleted or renamed since, a spell unlearned, a set gone.
        if GetCursorInfo() then PlaceAction(slot) else lost[#lost + 1] = SavedName(saved) end
        ClearCursor()
      end
    end
  end
  M.charDB.backup = nil
  M.charDB.extraBars = nil
  M.charDB.stanceBars = nil
  M.charDB.placed = nil
  ns.Print("bars restored.")
  if #lost > 0 then ns.Print("couldn't put back: " .. table.concat(lost, ", ") .. ".") end
end

local KEY_LABELS = { "Q", "E", "R", "T", "F", "G", "C", "V", "1", "2", "3", "4" }
local BAR_MOD = { [2] = "Shift", [3] = "Alt", [4] = "Ctrl" }

local function Show()
  local profile, class = Profile()
  if not profile then return ns.Print("no profile for " .. class .. " yet.") end
  local known = KnownSpells()
  local bags = BagItems()
  local spec = ns.Layout and ns.Layout.SpecLabel(class)
  if spec then print("|cffffd100Spec:|r " .. spec .. "  (/ac spec to change)") end
  for _, bar in ipairs(LAYOUT_BARS) do
    local mod = BAR_MOD[bar]
    print("|cffffd100Bar " .. bar .. (mod and (" (" .. mod .. ")") or "") .. "|r")
    for i = 1, 12 do
      local entry = profile[bar] and profile[bar][i]
      if entry then
        local item = ResolveEntry(entry, known)
        local what = item.missing and ("|cff888888" .. item.missing .. " (not learned)|r") or item.name
        print("  " .. (mod and (mod .. "+") or "") .. KEY_LABELS[i] .. " -> " .. what)
      end
    end
  end
  for _, st in ipairs(profile.stances or {}) do
    print("|cffffd100Bar 1 in " .. st.label .. " (bonus bar " .. st.offset .. ", slots " .. (st.first + 1) .. "-" .. (st.first + 12) .. ")|r")
    for i = 1, 12 do
      local entry = st.entries[i]
      if entry then
        local item = ResolveEntry(entry, known)
        local what = item.missing and ("|cff888888" .. item.missing .. " (not learned)|r") or item.name
        print("  " .. KEY_LABELS[i] .. " -> " .. what)
      end
    end
  end
  print("|cffffd100Bar 3 (Alt: item macros, trinkets and Hearthstone)|r")
  local utility = profile[3] or M.utility
  for i = 1, 12 do
    local entry = utility[i]
    if AltMacro(entry) then
      local item = ResolveAltMacro(entry)
      local what = item.missing and ("|cff888888" .. entry.macro .. " macro (install it on the Macros page)|r")
        or (entry.macro .. " macro")
      print("  Alt+" .. KEY_LABELS[i] .. " -> " .. what)
    elseif entry then
      local id = ResolveUtility(entry, bags)
      local none = type(entry) == "string" and " (none equipped)" or " (none in bags)"
      local what = id and (ItemInfo(id)) or ("|cff888888" .. UtilityLabel(entry) .. none .. "|r")
      print("  Alt+" .. KEY_LABELS[i] .. " -> " .. what)
    end
  end
  local side, _, extra, dropped, extraBars, items = SideBars(profile, known)
  -- A camp item you don't carry shows greyed, like a utility item.
  local function Names(list)
    local out = {}
    for i = 1, 12 do
      local n = list[i]
      if n then out[#out + 1] = items[n] == false and ("|cff888888" .. n .. " (none in bags)|r") or n end
    end
    return out
  end
  print("|cffffd100Action Bar 5 (click: pet, other" .. (#extraBars == 0 and ", tracking, professions, camp" or "") .. ")|r  " .. table.concat(Names(side), ", "))
  for b, bar in ipairs(extraBars) do
    local names = Names(extra[b])
    local what = b == 1 and "click: tracking, professions, camp" or "click"
    if #names > 0 then print("|cffffd100" .. bar.label .. " (" .. what .. ")|r  " .. table.concat(names, ", ")) end
  end
  if #dropped > 0 then print("|cff888888No room (stay in the spellbook):|r  " .. table.concat(dropped, ", ")) end
end

-- Plan for the window: what each managed slot will hold after Apply. It
-- makes the same choices as Apply, so the page and the change count match
-- what Apply does.
-- Entry states: same (already there), new (placed on apply), missing (spell
-- not learned / item not in bags; e.clears when Apply empties a slot that
-- holds something now), clear (removed on apply), kept (holds something
-- Undo can't restore, so Apply leaves it alone), free (an Alt key outside
-- the layout holding something of yours: Apply leaves it alone), empty.
-- plan.stale lists the old copies Apply clears from Action Bars 6-8 it
-- doesn't manage ({ slot =, name = }); each counts as a change.
-- label/sub are display only (Edit Mode names; sub = the key modifier).
local ROWS = {
  { label = "Action Bar 1", sub = nil,     command = "ACTIONBUTTON",          first = BAR_OFFSET[1] },
  { label = "Action Bar 2", sub = "Shift", command = "MULTIACTIONBAR1BUTTON", first = BAR_OFFSET[2] },
  { label = "Action Bar 3", sub = "Alt",   command = "MULTIACTIONBAR2BUTTON", first = BAR_OFFSET[3] },
  { label = "Action Bar 4", sub = "Ctrl",  command = "MULTIACTIONBAR3BUTTON", first = BAR_OFFSET[4] },
  { label = "Action Bar 5", sub = nil,     command = "MULTIACTIONBAR4BUTTON", first = SIDE_BAR },
}
-- Plan rows 1-4 are the keyed bars (row = bar number); the side bars start here.
local SIDE_FIRST_ROW = 5
local KEYED_ROW = { [1] = true, [2] = true, [4] = true } -- filled from the layout (3 = utilities)

-- A keyed home's plan entry fields (bars 1, 2, 4 and the stance pages).
local function KeyedEntry(e, entry, known)
  local item = ResolveEntry(entry, known)
  e.item = item
  -- A missing home keeps its entry's form: item, macro or spell.
  e.kind = item.kind or ((entry.item or entry.utility) and "item")
    or (item.macro and "macro") or "spell"
  e.id = item.id or (not item.missing and item.name) or nil
  e.name = item.name or item.missing
  e.macro = entry.macro -- display only: a macro home shows its plain spell until installed
  -- Display only: what a waiting home can show as its icon.
  if entry.macro then e.needs = entry[1]
  elseif entry.item then e.cands = { entry.item }
  elseif entry.utility then
    local spec = M.utility and M.utility[entry.utility]
    e.cands = type(spec) == "table" and spec or nil
  end
end

-- Sets e.state from what the slot holds now and counts it in the plan.
local function PlanState(plan, e)
  local cur, curID = GetActionInfo(e.slot)
  local C = ns.modules.controller
  if cur and not Restorable(cur) then e.state = "kept"; plan.kept = plan.kept + 1
  elseif e.free then e.state = "free"
  elseif not e.kind then e.state = cur and "clear" or "empty"
  elseif not e.id then e.state = "missing"; e.clears = cur ~= nil
  elseif e.item and C and C.Same then e.state = C.Same(e.slot, e.item) and "same" or "new"
  elseif cur == e.kind and curID == e.id then e.state = "same"
  else e.state = "new" end
  if e.state == "new" or e.state == "clear" or e.clears then plan.changes = plan.changes + 1 end
  if e.state == "missing" then
    if e.kind == "spell" then plan.spellsMissing = plan.spellsMissing + 1
    elseif e.kind == "macro" then
      -- ManaPot on a class without mana: empty for good, nothing to install.
      if not (e.item and e.item.reason == "nomana") then plan.macrosMissing = plan.macrosMissing + 1 end
    else plan.itemsMissing = plan.itemsMissing + 1 end
  end
end

-- plan.stances: Bar 1's stance pages, { key =, label =, offset =, first =,
-- [1..12] = entries } by offset (an old page the spec dropped is cleared).
function M.Plan()
  local profile, class = Profile()
  if not profile then return nil, class end
  local known = KnownSpells()
  local bags = BagItems()
  local side, ids, extra, dropped, extraBars, items = SideBars(profile, known)
  local used = UsedExtraBars(extra, extraBars)
  local utility = profile[3] or M.utility
  local stale = StaleSlots(side, extra, used)
  local plan = { changes = #stale, spellsMissing = 0, itemsMissing = 0, macrosMissing = 0, kept = 0,
    dropped = dropped, rows = {}, hidden = {}, stale = stale, stances = {} }
  local extraOf = {}
  for b, bar in ipairs(extraBars) do extraOf[bar.first] = extra[b] end
  for r, row in ipairs(ROWS) do plan.rows[r] = row end
  for _, bar in ipairs(used) do
    plan.rows[#plan.rows + 1] = { label = bar.label, command = bar.command, first = bar.first,
      extra = extraOf[bar.first] or {}, hidden = ExtraBarHidden(bar) }
    if ExtraBarHidden(bar) and next(extraOf[bar.first] or {}) then plan.hidden[#plan.hidden + 1] = bar.label end
  end
  for r, row in ipairs(plan.rows) do
    local entries = {}
    for i = 1, 12 do
      local e = { slot = row.first + i }
      if KEYED_ROW[r] then
        local entry = profile[r] and profile[r][i]
        if entry then KeyedEntry(e, entry, known) end
      elseif r == 3 then
        local entry = utility[i]
        if AltMacro(entry) then
          -- { macro = "Fish" }: the macro once installed; waiting until then
          -- (kind stays "macro", so it counts as a macro to install).
          local item = ResolveAltMacro(entry)
          e.item, e.kind, e.macro = item, "macro", entry.macro
          e.id = not item.missing and item.name or nil
          e.name = item.name or item.missing
          -- Your own button on a waiting macro home stays until you install it.
          if item.missing and AltFree(e.slot, entry) then e.free = true end
        elseif entry then
          e.cands = type(entry) == "table" and entry or nil
          local id = ResolveUtility(entry, bags)
          e.kind, e.id, e.name = "item", id, id and ItemInfo(id) or UtilityLabel(entry)
          e.trinket = type(entry) == "string" or nil -- display only: "none equipped"
        elseif AltFree(e.slot, entry) then
          e.free = true
        end
      else
        local name = (row.extra or side)[i]
        if name and items[name] ~= nil then
          -- A camp item: waiting ("missing") while it is not in your bags.
          e.kind, e.id, e.name, e.cands = "item", items[name] or nil, name, { name }
        elseif name then
          e.kind, e.id, e.name = "spell", ids[name], name
        end
      end
      PlanState(plan, e)
      entries[i] = e
    end
    plan[r] = entries
  end
  for _, st in ipairs(UsedStanceBars(profile)) do
    local page = { key = st.key, label = st.label, offset = st.offset, first = st.first, old = st.old }
    for i = 1, 12 do
      local e = { slot = st.first + i, i = i, stance = st.key, stanceLabel = st.label }
      local entry = st.entries[i]
      if entry then KeyedEntry(e, entry, known) end
      PlanState(plan, e)
      page[i] = e
    end
    plan.stances[#plan.stances + 1] = page
  end
  return plan, class
end

-- Keyboard page (dev/ui-spec-v2.md §9.2) ---------------------------------------
-- One page for Action Bars and Key Bindings: a keyboard you can read at a
-- glance. Each key shows the icon and the name of what it casts on the shown
-- layer (Plain, Shift, Ctrl, Alt), the mouse buttons hold the pet commands,
-- and the Side bars view shows the click-only bars (Action Bars 5-8). The
-- List view puts every key's four layers side by side as icon + name.
-- Holding Shift, Ctrl or Alt previews that layer; nothing is bound or
-- consumed by the preview. A window chord (Ctrl+Space, Ctrl+Tab...) pauses
-- the Ctrl preview until Ctrl is released, so the chord's result shows.
-- Apply goes through the Review sheet and runs Action Bars Apply, then Key
-- Bindings Apply; neither ever creates a macro.

M.Apply, M.Undo = Apply, Undo

local UI = ns.UI
local function Keybinds() return ns.modules.keybinds end
local function Active(key) local m = ns.ModuleOf(key); return m ~= nil and m.active == true end
local NOT_BOUND_TEXT = NOT_BOUND or "Not bound"

-- The four key layers in display order (tabs, pips, List columns, the
-- Inspector). bar = the action bar the layer fires, which is also its plan row.
local LAYERS = {
  { key = "plain", label = "Plain", prefix = "",       mod = nil,     bar = 1, title = "Action Bar 1" },
  { key = "shift", label = "Shift", prefix = "SHIFT-", mod = "Shift", bar = 2, title = "Action Bar 2" },
  { key = "ctrl",  label = "Ctrl",  prefix = "CTRL-",  mod = "Ctrl",  bar = 4, title = "Action Bar 4" },
  { key = "alt",   label = "Alt",   prefix = "ALT-",   mod = "Alt",   bar = 3, title = "Action Bar 3" },
}
local LAYER_OF_VIEW, LAYER_OF_BAR = {}, {}
for li, l in ipairs(LAYERS) do LAYER_OF_VIEW[l.key], LAYER_OF_BAR[l.bar] = li, li end
local LAYER_SHIFT, LAYER_CTRL, LAYER_ALT = LAYER_OF_VIEW.shift, LAYER_OF_VIEW.ctrl, LAYER_OF_VIEW.alt

-- The keyboard as it looks: four staggered rows (stagger in px, spec §9.2).
local KEY_ROWS = {
  { x = 0,  keys = { "1", "2", "3", "4", "5" } },
  { x = 16, keys = { "Q", "W", "E", "R", "T" } },
  { x = 24, keys = { "A", "S", "D", "F", "G" } },
  { x = 40, keys = { "Z", "X", "C", "V" } },
}
local MOUSE = { "BUTTON3", "BUTTON4", "BUTTON5" }
local MOUSE_LABEL = { BUTTON3 = "M3", BUTTON4 = "M4", BUTTON5 = "M5" }
local MOUSE_NAME = { BUTTON3 = "Middle mouse button", BUTTON4 = "Mouse button 4", BUTTON5 = "Mouse button 5" }
-- Every key the List view lists, in layout order, in three groups.
local LIST_GROUPS = {
  { title = "Action Bars 1-4 · same 12 keys", keys = { "Q", "E", "R", "T", "F", "G", "C", "V", "1", "2", "3", "4" } },
  { title = "Pet abilities", keys = { "Z", "X" } },
  { title = "Mouse · pet commands", keys = MOUSE },
}

local function KeyLabel(base) return MOUSE_LABEL[base] or base end
local function Chord(base, li)
  local m = LAYERS[li].mod
  return (m and (m .. "+") or "") .. KeyLabel(base)
end

-- Binding command -> action slot (bars 1-8) or pet bar slot.
local CMD_SLOT = {
  { "^ACTIONBUTTON(%d+)$", 0 }, { "^MULTIACTIONBAR1BUTTON(%d+)$", 60 }, { "^MULTIACTIONBAR2BUTTON(%d+)$", 48 },
  { "^MULTIACTIONBAR3BUTTON(%d+)$", 24 }, { "^MULTIACTIONBAR4BUTTON(%d+)$", 36 },
  { "^MULTIACTIONBAR5BUTTON(%d+)$", 144 }, { "^MULTIACTIONBAR6BUTTON(%d+)$", 156 }, { "^MULTIACTIONBAR7BUTTON(%d+)$", 168 },
}
local function SlotOf(cmd)
  if type(cmd) ~= "string" then return nil end
  for _, c in ipairs(CMD_SLOT) do
    local n = cmd:match(c[1])
    if n then return c[2] + tonumber(n) end
  end
end
local function PetOf(cmd) return type(cmd) == "string" and tonumber(cmd:match("^BONUSACTIONBUTTON(%d+)$")) or nil end

-- "Action Bar 2 · button 4" for an action slot.
local function SlotText(slot)
  for _, r in ipairs(ROWS) do
    if slot > r.first and slot <= r.first + 12 then return r.label .. " · button " .. (slot - r.first) end
  end
  for _, b in ipairs(EXTRA_BARS) do
    if slot > b.first and slot <= b.first + 12 then return b.label .. " · button " .. (slot - b.first) end
  end
  local first = StanceBarOf(slot)
  if first then
    local label = "stance page " .. StanceOffset(first)
    local _, class = UnitClass("player")
    for _, st in ipairs(ns.Layout and ns.Layout.StancePages(class) or {}) do
      if st.first == first then label = st.label .. " page" end
    end
    return "Action Bar 1 · " .. label .. " · button " .. (slot - first)
  end
  return "Action slot " .. slot
end

local function Plural(n, one, many) return n .. " " .. (n == 1 and one or many) end
local function NameOf(d, fallback) return d and type(d.name) == "string" and d.name or fallback end

local function EntryIcon(e)
  if e.kind == "spell" then return UI.SpellIcon(e.id or e.name) end
  if e.kind == "item" then return e.id and UI.ItemIcon(e.id) or nil end
  local C = ns.modules.controller
  if C and C.Icon and e.item then return C.Icon(e.item) end
end

-- Icon of an item by name (items you do not carry may be uncached: nil then).
local function ItemIconByName(name)
  if type(name) ~= "string" then return nil end
  if C_Item and C_Item.GetItemInfoInstant then
    local ok, _, _, _, _, icon = pcall(C_Item.GetItemInfoInstant, name)
    if ok and icon then return icon end
  end
  local ok, icon = pcall(UI.ItemIcon, name)
  return ok and icon or nil
end

-- The real icon of a home that waits (shown desaturated), so you still see
-- what will sit there; nil only when nothing resolves.
local function WaitingIcon(e)
  if e.item and e.item.icon then return e.item.icon end
  if e.kind == "item" then
    local c = e.cands
    if c then
      -- "or better" lists run worst to best; the label names the last one.
      for k = #c, 1, -1 do
        local icon = ItemIconByName(c[k])
        if icon then return icon end
      end
    end
    return ItemIconByName(e.name)
  end
  if e.kind == "macro" then return UI.SpellIcon(e.needs) end
  return UI.SpellIcon(e.id or e.name)
end

-- A slot's icon; a waiting home with no icon shows a "?" bright enough to read.
local function SetSlotIcon(s, icon, faded)
  s:SetIcon(icon or (faded and UI.QUESTION) or nil, faded)
  if faded and not icon and s.icon and s.icon.SetAlpha then s.icon:SetAlpha(0.7) end
end

-- What a managed slot holds after Apply, from the plan entry e.
-- state: same, new, waiting (not learned / not carried / macro not
-- installed), kept, clear, empty.
local function AfterOfEntry(e)
  local st = e.state
  if st == "same" or st == "new" then
    return { icon = EntryIcon(e) or UI.QUESTION, name = e.name or "?", state = st, kind = e.kind, id = e.id }
  elseif st == "missing" then
    return { icon = WaitingIcon(e), name = e.name or "?", state = "waiting",
      kind = e.kind, clears = e.clears }
  elseif st == "kept" or st == "free" then
    local d = UI.DescribeSlot(e.slot)
    return { icon = d.icon, name = d.name, state = st, tip = d.tip }
  elseif st == "clear" then
    return { name = "Empty", state = "clear" }
  end
  return { name = "Empty", state = "empty" }
end

local function AfterOfCommand(cmd)
  local d = UI.DescribeCommand(cmd)
  if not d then return { name = NOT_BOUND_TEXT, state = "unbound" } end
  local empty = d.name == "Empty slot"
  return { icon = d.icon, name = empty and "Empty" or NameOf(d, "?"), state = empty and "empty" or "same",
    kind = d.kind, tip = d.tip }
end

-- Everything the page shows, gathered once per Refresh.
local function Gather(page)
  local d = { ab = Active("ActionBars"), kb = Active("Keybinds"), cells = { {}, {}, {}, {} } }
  d.plan = M.Plan()
  local K = Keybinds()
  d.layout = K and K.Layout and K.Layout() or {}
  d.map = {}
  for _, b in ipairs(d.layout) do if b.key then d.map[b.key] = b.command end end
  d.diff = (K and K.Diff and K.Diff()) or { keys = 0, replace = 0, extra = 0, replaced = {}, unbinds = {} }
  d.slots = {}
  if d.plan then
    for r = 1, #d.plan.rows do
      for i = 1, 12 do
        local e = d.plan[r][i]
        if e then e.r, e.i = r, i; d.slots[e.slot] = e end
      end
    end
  end
  -- Bar 1's stance pages (not the old ones Apply only clears), and the one
  -- the Plain layer previews: page.stance, else the stance you are in now.
  d.stances = {}
  for _, st in ipairs(d.plan and d.plan.stances or {}) do
    for i = 1, 12 do d.slots[st[i].slot] = st[i] end
    if not st.old then d.stances[#d.stances + 1] = st end
  end
  if page.stance == nil and #d.stances > 0 then
    local off = ns.Layout and ns.Layout.BonusOffset and ns.Layout.BonusOffset()
    page.stance = "none"
    for _, st in ipairs(d.stances) do if st.offset == off then page.stance = st.key end end
  end
  for _, st in ipairs(d.stances) do if st.key == page.stance then d.stancePage = st end end
  page.data = d
  return d
end

-- The Plain layer's slot for key index i (1-12): the previewed stance page's
-- bonus bar slot, else Bar 1's own.
local function PlainSlot(page, i)
  local st = page.data and page.data.stancePage
  return st and (st.first + i) or i
end

-- One key on one layer: now, after, and how Apply changes it.
local function Cell(page, base, li)
  local d = page.data
  local cached = d.cells[li][base]
  if cached then return cached end
  local bind = LAYERS[li].prefix .. base
  local c = { base = base, layer = li, bind = bind }
  local cur = GetBindingAction(bind) or ""
  local want = d.map[bind]
  c.cur, c.want, c.managed = cur, want, want ~= nil
  local nowD = UI.DescribeCommand(cur)
  c.now = nowD and { icon = nowD.icon, name = NameOf(nowD, "?"), kind = nowD.kind, tip = nowD.tip, state = "same" }
    or { name = NOT_BOUND_TEXT, state = "unbound" }
  if c.now.name == "Empty slot" then c.now.name, c.now.state = "Empty", "empty" end
  local cmd = (want and d.kb) and want or cur
  c.command = cmd
  if want and d.kb and want ~= cur then
    c.bindState = cur == "" and "added" or "replaces"
    c.oldName = NameOf(nowD, cur)
  end
  c.slot, c.pet = SlotOf(cmd), PetOf(cmd)
  -- Plain keys fire Action Bar 1, which the game pages by stance, form or
  -- stealth: with a stance page previewed, the key shows that page's slot.
  if d.stancePage and c.slot and c.slot >= 1 and c.slot <= 12 then
    c.slot, c.stance = d.stancePage.first + c.slot, d.stancePage
    local nowSlot = SlotOf(cur)
    if nowSlot and nowSlot >= 1 and nowSlot <= 12 then
      local sd = UI.DescribeSlot(d.stancePage.first + nowSlot)
      local empty = sd.name == "Empty slot"
      c.now = { icon = sd.icon, name = empty and "Empty" or NameOf(sd, "?"), kind = sd.kind, tip = sd.tip,
        state = empty and "empty" or "same" }
    end
  end
  local e = c.slot and d.ab and d.slots[c.slot] or nil
  c.entry = e
  c.after = e and AfterOfEntry(e) or AfterOfCommand(cmd)
  local a = c.after
  -- Marks on the After view (spec §9.2): Added green, Removed orange-red,
  -- Replaces-your-bind orange edge, waiting homes red and desaturated (as on
  -- the Controller page).
  if e and e.kind == "flyout" then c.mark, c.flyout = UI.C.MISSING, true
  elseif a.state == "clear" or a.clears then c.mark = UI.C.REMOVED
  elseif a.state == "waiting" then c.mark = UI.C.MISSING
  elseif a.state == "new" or c.bindState == "added" then c.mark = UI.C.ADDED end
  if c.bindState == "replaces" then c.edge = UI.C.REPLACES elseif c.pet then c.edge = UI.C.PET end
  c.changed = c.bindState ~= nil or a.state == "new" or a.state == "clear" or a.clears == true
  c.waiting = a.state == "waiting"
  d.cells[li][base] = c
  return c
end

-- Colour of a name: white, so names read best; red while it waits (as on the
-- Controller page) or for a radial (the keyboard has none); grey when the
-- key is unbound/unused. The slot's glow and edge carry Added / Replaces.
local function NameColor(c, after)
  if not after then return (c.now.state == "unbound" or c.now.state == "empty") and UI.C.DISABLED or nil end
  if c.flyout or c.after.state == "waiting" then return UI.C.MISSING end
  if c.after.state == "unbound" or c.after.state == "empty" or c.after.state == "clear" then return UI.C.DISABLED end
  if not c.managed then return UI.C.DISABLED end
  return nil
end

local function StateText(c)
  local a = c.after
  if not c.managed then return "Not used by the layout", UI.C.GRAY end
  if c.flyout then return "Radials belong on the Controller page", UI.C.MISSING end
  if a.state == "waiting" then
    local e = c.entry
    if e and e.kind == "macro" then return InstallText(e.item and e.item.macro or e.macro or a.name), UI.C.MISSING end
    if e and e.trinket then return "Waiting: equip a trinket with a Use effect", UI.C.MISSING end
    if e and e.kind == "item" then return "Waiting: none in your bags", UI.C.MISSING end
    return "Waiting: learn " .. a.name, UI.C.MISSING
  end
  if a.state == "clear" then return "Cleared when you apply", UI.C.REMOVED end
  if a.state == "kept" then return "Kept: Apply leaves this slot alone", UI.C.GRAY end
  if a.state == "free" then
    local e = c.entry
    if e and e.kind == "macro" and e.macro then
      return "Your own button stays until you install " .. e.macro .. " on the Macros page", UI.C.GRAY
    end
    return "Not in the layout: Apply leaves your own button here", UI.C.GRAY
  end
  if c.bindState == "replaces" then return "Replaces your bind when you apply", UI.C.REPLACES end
  if c.changed then return "Added when you apply", UI.C.ADDED end
  return "In place", UI.C.GREEN
end

-- Where a key's layer lives: "Action Bar 2 · button 4", "Pet bar · slot 4".
local function HomeText(c)
  if c.slot then return SlotText(c.slot) end
  if c.pet then return "Pet bar · slot " .. c.pet end
  if c.command and c.command ~= "" then return UI.KeyName(c.command) end
  return "—"
end

local function PetAutoCast(n)
  if not (n and GetPetActionInfo) then return false end
  local ok, _, _, _, _, allowed, enabled = pcall(GetPetActionInfo, n)
  return ok and allowed and enabled and true or false
end

-- A pad key's name in the chosen controller style ("X" or "Square", "LT" or "L2").
local function PadName(key)
  local C = ns.modules.controller
  if C and C.PadName then
    local ok, n = pcall(C.PadName, key)
    if ok and n then return n end
  end
  return UI.PAD_NAMES and UI.PAD_NAMES[key] or tostring(key)
end

-- "RT + D-pad Down", "L2 + R2 + Cross": a controller chord as text.
local function PadChord(layer, button)
  local parts = {}
  for _, k in ipairs(UI.PAD_LAYER_TRIGGERS and UI.PAD_LAYER_TRIGGERS[layer] or {}) do parts[#parts + 1] = PadName(k) end
  local off = UI.PAD_OFFSETS and UI.PAD_OFFSETS[button]
  local key = off and off[4]
  if key and key:find("^PADD") then parts[#parts + 1] = "D-pad " .. button
  else parts[#parts + 1] = key and PadName(key) or button end
  return table.concat(parts, " + ")
end

-- The same chord as inline button glyphs ([RT] + [D-pad Down]), as the
-- Macros page shows it; the text form when the glyph helper is missing.
-- The flat glyph atlases carry wide transparent padding: at 18 px the art
-- drew at about 9 px and RT/LT were indistinguishable specks. 26 px fits the
-- Inspector's 28 px link row and reads at Steam Deck distance. The plain
-- text chord follows the glyphs, so the line reads even when they don't.
local CHORD_GLYPH = 26
local function PadChordGlyphs(layer, button)
  if not UI.GlyphMarkup then return PadChord(layer, button) end
  local parts, any = {}, false
  for _, k in ipairs(UI.PAD_LAYER_TRIGGERS and UI.PAD_LAYER_TRIGGERS[layer] or {}) do
    local ok, m = pcall(UI.GlyphMarkup, k, CHORD_GLYPH)
    if ok and type(m) == "string" and m:find("|A", 1, true) then any = true end
    parts[#parts + 1] = (ok and m) or PadName(k)
  end
  local off = UI.PAD_OFFSETS and UI.PAD_OFFSETS[button]
  local key = off and off[4]
  local ok, m = false, nil
  if key then ok, m = pcall(UI.GlyphMarkup, key, CHORD_GLYPH) end
  if ok and type(m) == "string" and m:find("|A", 1, true) then any = true end
  parts[#parts + 1] = (ok and m) or (key and key:find("^PADD") and ("D-pad " .. button)) or (key and PadName(key)) or button
  local glyphs = table.concat(parts, " + ")
  -- Without any atlas the markup already reads "[RT] + [D-pad Up]".
  if not any then return glyphs end
  return glyphs .. "  |cffb0b0b0" .. PadChord(layer, button) .. "|r"
end

-- Opens the Controller page on one set at one button (the Macros page's
-- OpenController pattern: choose the set's view first, then list: or pad:
-- by the page's mode, so the link lands on the spell it names).
local function OpenControllerAt(set, layer, button)
  local p = ns.PageById and ns.PageById("controller")
  if p then
    local view = tostring(set)
    if p.view ~= view then
      p.view = view
      if p.OnView then pcall(p.OnView, p, view) end
    end
  end
  ns.OpenPage("controller", ((p and p.mode == 2) and "list:" or "pad:") .. layer .. ":" .. button)
end

-- Controller homes of a spell or item, for the Inspector's "Also on" lines.
local PAD_LAYER = { none = 0, LT = 1, RT = 2, ["LT+RT"] = 3 }
local function ControllerRefs(page, v)
  if not v or not v.name or v.state == "unbound" or v.state == "empty" then return {} end
  local d = page.data
  if d.ctrl == nil then
    d.ctrl = false
    local C = ns.modules.controller
    if C and C.Plan and C.active then
      local ok, plan = pcall(C.Plan)
      if ok and type(plan) == "table" then d.ctrl = plan end
    end
  end
  local out = {}
  if not d.ctrl then return out end
  for set = 1, 3 do
    for slotID, p in pairs(d.ctrl[set] or {}) do
      local it = type(slotID) == "number" and type(p) == "table" and p.item
      if it and not it.missing and ((v.id and it.id == v.id and it.kind == v.kind) or it.name == v.name) and p.key then
        local layer, button = p.key:match("^(%S+) (%S+)$")
        if layer and PAD_LAYER[layer] then
          local li = PAD_LAYER[layer]
          out[#out + 1] = { text = "Pad set " .. set .. ": " .. PadChordGlyphs(li, button),
            sort = set .. " " .. PadChord(li, button),
            fn = function() OpenControllerAt(set, li, button) end }
        end
      end
    end
  end
  table.sort(out, function(a, b) return a.sort < b.sort end)
  return out
end

local function SpellText(v)
  if v and v.kind == "spell" and v.id and C_Spell and C_Spell.GetSpellDescription then
    local ok, t = pcall(C_Spell.GetSpellDescription, v.id)
    if ok and type(t) == "string" and t ~= "" then return t end
  end
end

local function RestoreButtons()
  local K = Keybinds()
  return {
    { label = "Restore original bars", fn = function() UI.RunAction(Undo) end,
      enabled = Active("ActionBars") and M.charDB ~= nil and M.charDB.backup ~= nil,
      confirm = "Restore your action bars to how they were before your first Apply?" },
    { label = "Restore original keys", fn = function() if K and K.Undo then UI.RunAction(K.Undo) end end,
      enabled = Active("Keybinds") and K ~= nil and K.HasBackup ~= nil and K.HasBackup(),
      confirm = "Restore the key bindings you had before Agentcraft?" },
  }
end

local SavedState -- defined with the page (below)
local StanceInspect -- defined with the page (below)

-- Picture <-> List: shows the same key (or side slot) in the other mode,
-- focused, so every Inspector has a link the D-pad can step onto.
local function ModeLink(page, base, layer, slot)
  local list = page.mode == 2
  local text
  if slot then text = list and "Show on the side bars" or "Show in the List view"
  else text = list and "Show on the keyboard" or "Show in the List view (every layer by name)" end
  return { text = text, fn = function()
    local id
    if list then
      page.mode = 1
      if slot then id = "side:" .. slot
      else
        local view = LAYERS[layer or 1] and LAYERS[layer or 1].key or "plain"
        if page.view ~= view then page.view = view end
        id = "key:" .. base
      end
    else
      page.mode = 2
      id = slot and ("sidelist:" .. slot) or ("list:" .. base .. ":" .. (layer or 1))
    end
    if SavedState then SavedState(page) end
    ns.OpenPage("keyboard", id)
  end }
end

-- Inspector for one key on one layer.
local function InspectCell(pane, page, c)
  page.pane = pane
  local after = page.after == 2
  local v = after and c.after or c.now
  local keys = {}
  if LAYERS[c.layer].mod then keys[1] = LAYERS[c.layer].mod end
  keys[#keys + 1] = KeyLabel(c.base)
  local kind = (v.kind == "spell" and "Spell") or (v.kind == "item" and "Item") or (v.kind == "macro" and "Macro")
    or (v.kind == "pet" and "Pet bar") or (c.pet and "Pet bar") or (c.managed and "Action bar") or "Key"
  pane:Header(v.icon or (v.state == "waiting" and UI.QUESTION) or nil, v.name or "Empty", kind .. " · " .. (after and "after Apply" or "now"), keys)
  local stext, scolor = StateText(c)
  pane:Row("State", stext, scolor)
  pane:Row("Home", HomeText(c))
  if MOUSE_NAME[c.base] then pane:Row("Button", MOUSE_NAME[c.base]) end
  if c.bindState == "replaces" then pane:Row("Replaces", (c.oldName or "?") .. " (your bind)", UI.C.REPLACES) end
  if c.changed then
    pane:Diff({ icon = c.now.icon, name = c.now.name }, { icon = c.after.icon, name = c.after.name, color = c.mark or UI.C.ADDED })
  end
  pane:Section(KeyLabel(c.base) .. " on every layer")
  local layers = {}
  for l = 1, #LAYERS do
    local cc = Cell(page, c.base, l)
    local vv = after and cc.after or cc.now
    layers[l] = { label = LAYERS[l].label, icon = vv.icon, name = (vv.state == "unbound" and NOT_BOUND_TEXT or (vv.name or ""):gsub(" %(or better%)$", "")), color = NameColor(cc, after) }
  end
  pane:Layers(layers)
  -- A plain key on a class whose Bar 1 pages by stance, form or stealth:
  -- what the key casts on each page ("Battle: Overpower, Defensive: Revenge").
  local d = page.data
  if c.layer == 1 and c.slot and #(d.stances or {}) > 0 then
    local i = c.stance and (c.slot - c.stance.first) or c.slot
    if i >= 1 and i <= 12 then
      pane:Section(KeyLabel(c.base) .. " in each stance")
      local rows = {}
      local function Row(label, e, slot)
        local vv
        if after and e then vv = AfterOfEntry(e)
        else
          local sd = UI.DescribeSlot(slot)
          local empty = sd.name == "Empty slot"
          vv = { icon = sd.icon, name = empty and "Empty" or sd.name, state = empty and "empty" or "same" }
        end
        local color = (vv.state == "waiting" and UI.C.MISSING)
          or ((vv.state == "empty" or vv.state == "clear") and UI.C.DISABLED) or nil
        rows[#rows + 1] = { label = label, icon = vv.icon, name = vv.name, color = color }
      end
      Row("No stance", d.slots[i], i)
      for _, st in ipairs(d.stances) do Row(st.label, st[i], st.first + i) end
      pane:Layers(rows)
    end
  end
  pane:Text(SpellText(v))
  local e = c.entry
  if e and e.macro and after and c.after.kind == "spell" then
    pane:Text("Uses the plain spell until you install the " .. e.macro .. " macro. Apply never creates macros.", UI.C.NORMAL)
    pane:CrossRef({ { text = "Open Macros", fn = function() ns.OpenPage("macros") end } })
  elseif e and e.kind == "macro" and c.after.state == "waiting" then
    pane:CrossRef({ { text = "Install it in Macros", fn = function() ns.OpenPage("macros") end } })
  end
  if c.flyout then pane:Text("The keyboard uses plain keybinds without radials; put this spell on the Controller page instead.", UI.C.MISSING) end
  if c.pet and PetAutoCast(c.pet) then pane:Text("Autocast is on for this pet ability.", UI.C.PET) end
  local refs = ControllerRefs(page, v)
  -- One home per spell: a second keyboard key with the same spell shows in red.
  if v.name and (v.state == "same" or v.state == "new") and v.kind ~= "pet" then
    for _, grp in ipairs(LIST_GROUPS) do
      for _, base in ipairs(grp.keys) do
        for l = 1, #LAYERS do
          local o = Cell(page, base, l)
          local ov = after and o.after or o.now
          if o ~= c and o.managed and ov.name == v.name and ov.kind == v.kind then
            refs[#refs + 1] = { text = "Also on " .. Chord(base, l) .. ": a second home on the keyboard", color = UI.C.MISSING,
              fn = function() ns.OpenPage("keyboard", "key:" .. base) end }
          end
        end
      end
    end
  end
  if #refs > 0 then
    pane:Section("Also on")
    pane:CrossRef(refs)
  end
  pane:CrossRef({ ModeLink(page, c.base, c.layer) })
  pane:Buttons(RestoreButtons())
end

-- Inspector for a side-bar slot (plan entry e, or an empty slot).
local function InspectSide(pane, page, e, slot)
  page.pane = pane
  local after = page.after == 2
  local now = UI.DescribeSlot(slot)
  local v = after and e and AfterOfEntry(e) or { icon = now.icon, name = now.name, state = "same" }
  pane:Header(v.icon or (v.state == "waiting" and UI.QUESTION) or nil, v.name or "Empty", "Click only · " .. (after and "after Apply" or "now"))
  local st = e and e.state or "empty"
  local text, color = "In place", UI.C.GREEN
  if st == "new" then text, color = "Placed when you apply", UI.C.ADDED
  elseif st == "clear" then text, color = "Cleared when you apply", UI.C.REMOVED
  elseif st == "missing" and e.kind == "item" then text, color = "Waiting: none in your bags", UI.C.MISSING
  elseif st == "missing" then text, color = "Waiting: learn " .. (e.name or "?"), UI.C.MISSING
  elseif st == "kept" then text, color = "Kept: Apply leaves this slot alone", UI.C.GRAY
  elseif st == "empty" then text, color = "Empty", UI.C.DISABLED end
  pane:Row("State", text, color)
  pane:Row("Home", SlotText(slot))
  if st == "new" or st == "clear" then
    pane:Diff({ icon = now.icon, name = now.name }, { icon = v.icon, name = v.name, color = st == "new" and UI.C.ADDED or UI.C.REMOVED })
  end
  pane:Text(SpellText(v))
  pane:Text("Side bars hold the spells without a key: pet spells, other class spells, tracking, professions and the Cozy Sleeping Bag (while it is in your bags). Click them on screen.", UI.C.GRAY)
  local refs = ControllerRefs(page, v)
  if #refs > 0 then pane:Section("Also on"); pane:CrossRef(refs) end
  if slot then pane:CrossRef({ ModeLink(page, nil, nil, slot) }) end
  pane:Buttons(RestoreButtons())
end

-- Right from the stage's right edge: the Inspector node nearest in height
-- (spec §9.2 "Right edge <-> Inspector"), else spatial.
-- The Inspector first explains node itself (the focus settles 0.12 s after a
-- move, so a quick Right would otherwise step into the previous subject's
-- links); a node inside the Inspector never re-inspects, so it keeps this one.
-- No Inspector node: stop here rather than jump to a far-away chip.
local function ToInspector(node)
  local F = ns.Focus
  if not (F and F.ScreenRect) then return nil end
  local _, b, _, h = F.ScreenRect(node)
  if not b then return nil end
  if not F.pinned and F.inspected ~= node and node.acInspect then F:Inspect(node) end
  local cy, best, bestD = b + h / 2, nil, nil
  for _, n in ipairs(F:Nodes()) do
    if F.ZoneOf(n) == "inspector" then
      local _, nb, _, nh = F.ScreenRect(n)
      if nb then
        local dist = math.abs(nb + nh / 2 - cy)
        if not bestD or dist < bestD then best, bestD = n, dist end
      end
    end
  end
  return best or false
end

local function TogglePin(node)
  local F = ns.Focus
  if not F then return end
  UI.Sound("activate")
  if F.pinned == node then F:Unpin() return end
  if F.pinned then F:Unpin() end
  F:Pin(node)
end

-- The Inspector's top focusable node, or nil.
local function TopInspectorNode()
  local F = ns.Focus
  local best, bestTop
  for _, n in ipairs(F:Nodes()) do
    if F.ZoneOf(n) == "inspector" then
      local top = n.GetTop and n:GetTop() or 0
      if not bestTop or top > bestTop then best, bestTop = n, top end
    end
  end
  return best
end

-- A / Enter on a key, slot or list cell: pin it and step into the Inspector,
-- so its links and buttons are one press away on the D-pad (spec §9.2).
-- A on the pinned node again unpins. B inside the Inspector unpins and
-- brings the focus back to the node (a mouse click only toggles the pin).
local function PinAndEnter(node, source)
  local F, Esc = ns.Focus, ns.Esc
  if not F then return end
  if F.pinned == node then TogglePin(node) return end
  TogglePin(node)
  if F.pinned ~= node then return end
  local target = TopInspectorNode()
  if not target then return end
  F:Set(target, source or "key")
  if Esc and Esc.Push then
    Esc.Push(function()
      if F.pinned == node then F:Unpin() end
      local cur = F.current
      if cur and F.ZoneOf(cur) == "inspector" and node.IsVisible and node:IsVisible()
        and (not F.Usable or F.Usable(node)) then
        F:Set(node, F.source or "key")
      end
    end, "pin")
  end
end

local function SetPinnedHighlight(self, on)
  if on then if self.LockHighlight then self:LockHighlight() end
  elseif self.UnlockHighlight then self:UnlockHighlight() end
  if self.pinArt then self.pinArt:SetShown(on and true or false) end
end

-- Geometry (stage-local, 712x512; content from y 40, spec §8).
-- A two-line caption (GameFontHighlightSmall, 12 px lines) ends 6 + 24 px
-- under its key, so KY leaves a few px before the next row. The first key
-- sits 22 px inside the deck: its caption is KX - 6 wide, centred on the
-- key, so it reaches 11 px left of the key and must stay off the deck rim.
local KEY, KX, KY = 56, 84, 88          -- keycap, step across, row step
local KB_X, KB_Y = 30, 46               -- first keycap
local MOUSE_X = 484                     -- the mouse column
local DECK_X, DECK_W = 8, 462           -- the keyboard deck (ends 14 px before the mouse column)
local BAR_Y = 412                       -- the action bar mirror's title
-- Side bars: the bar's name on a line above its 12 slots, so the slots get
-- the full width and their captions 54 px ("Smelting", "Humanoids" fit).
local SIDE_SLOT, SIDE_STEP, SIDE_ROW = 40, 56, 88
-- List view columns: the 30 px keycap at x 8, then four layer columns
-- (4 x 156 = 624, ending at 672 in the 696 px list, clear of its scroll bar).
local CELL_X, CELL_W = 48, 156

-- The layer the held modifiers preview (page.mods = { shift, ctrl, alt },
-- from UI.WatchModifiers), or nil. Alt wins over Ctrl, Ctrl over Shift.
-- While a window chord's Ctrl is still held (ns.Input.ctrlChord, set by
-- Ctrl+Space, Ctrl+Tab...), nothing is previewed, so the chord's result
-- (a new layer tab, a new page) shows instead of the Ctrl layer.
local function PreviewLayer(page)
  local m = page.mods
  if not m then return nil end
  local shift, ctrl, alt = m[1], m[2], m[3]
  if ctrl and ns.Input and ns.Input.ctrlChord then return nil end
  return (alt and LAYER_ALT) or (ctrl and LAYER_CTRL) or (shift and LAYER_SHIFT) or nil
end

local function ShownLayer(page)
  return PreviewLayer(page) or LAYER_OF_VIEW[page.view or "plain"] or 1
end

-- Picture view --------------------------------------------------------------------------------

local function FillCap(page, s)
  local base, li = s.base, ShownLayer(page)
  local c = Cell(page, base, li)
  s.cell = c
  local after = page.after == 2
  local v = after and c.after or c.now
  local faded = after and v.state == "waiting"
  s:SetState("empty")
  SetSlotIcon(s, v.icon, faded)
  s:SetMark(after and c.mark or nil)
  s:SetEdge(after and c.edge or (c.pet and UI.C.PET) or nil)
  s:SetBadge(c.flyout and "flyout" or nil)
  local used = {}
  for l = 1, #LAYERS do
    local cc = Cell(page, base, l)
    local vv = after and cc.after or cc.now
    used[l] = vv.icon ~= nil
  end
  s:SetPips(#LAYERS, li, used)
  -- Only on change: ShowAutoCastEnabled restarts the ants, so a call on
  -- every fill (each modifier press) made them jump.
  local auto = c.pet ~= nil and PetAutoCast(c.pet) and true or false
  if (s.acAuto or false) ~= auto then
    s.acAuto = auto
    s:SetAutoCast(auto)
  end
  s:SetTip(v.tip or (v.kind == "spell" and v.id and { spellID = v.id }) or (v.kind == "item" and v.id and { itemID = v.id })
    or { title = Chord(base, li), text = (StateText(c)) })
  s:SetAlpha(c.managed and 1 or 0.6)
  local name = (v.state == "unbound") and NOT_BOUND_TEXT or v.name
  if s.nameText then
    s.nameText:SetText(name or "")
    s.nameText:SetTextColor(UI.RGB(NameColor(c, after) or UI.C.HIGHLIGHT))
    local stext, scolor = StateText(c)
    s.stateText:SetText(stext)
    s.stateText:SetTextColor(UI.RGB(scolor or UI.C.NORMAL))
  else
    s:SetCaption(((name or ""):gsub(" %(or better%)$", "")), NameColor(c, after))
  end
  s.acId = "key:" .. base
end

local function CapInspect(s, pane) InspectCell(pane, s.page, s.cell or Cell(s.page, s.base, ShownLayer(s.page))) end

local function MakeCap(page, parent, base, size)
  local s = UI.KeySlot(parent, size)
  s.page, s.base = page, base
  s:SetKey(KeyLabel(base))
  s.acId = "key:" .. base
  s.acInspect = CapInspect
  UI.Node(s, { style = "slot" })
  s:SetScript("OnClick", TogglePin)
  s.acActivate = PinAndEnter
  s.SetPinned = SetPinnedHighlight
  return s
end

local function BuildPicture(page, stage)
  local g = CreateFrame("Frame", nil, stage)
  g:SetAllPoints()
  page.picture = g
  -- Keyboard body: a dark plate behind the keys, as a keyboard deck.
  local deck = UI.Plate(g)
  deck:SetPoint("TOPLEFT", DECK_X, -40)
  deck:SetSize(DECK_W, 4 * KY + 10)
  deck:SetFrameLevel(g:GetFrameLevel())
  UI.MarkIgnored(deck)
  page.caps = {}
  page.capList = {}
  for r, row in ipairs(KEY_ROWS) do
    for i, base in ipairs(row.keys) do
      local x, y = KB_X + row.x + (i - 1) * KX, KB_Y + (r - 1) * KY
      local managed = false
      for _, grp in ipairs(LIST_GROUPS) do for _, k in ipairs(grp.keys) do if k == base then managed = true end end end
      if managed then
        local s = MakeCap(page, g, base, KEY)
        s:SetPoint("TOPLEFT", x, -y)
        s:SetCaption("")
        s.caption:SetWidth(KX - 6)
        s.caption:SetWordWrap(true)
        if s.caption.SetMaxLines then s.caption:SetMaxLines(2) end
        page.caps[base] = s
        page.capList[#page.capList + 1] = s
      else
        -- Movement keys and 5: drawn faint, not a focus target (no dead weight on the D-pad).
        local s = UI.KeySlot(g, KEY)
        s:SetPoint("TOPLEFT", x, -y)
        s:SetKey(base)
        s:SetAlpha(0.35)
        s:EnableMouse(false)
        s.acSkip = true
        UI.MarkIgnored(s)
      end
    end
  end

  -- Mouse column: the pet commands (Attack, Follow, Stay...).
  page.mouseTitle = UI.SectionTitle(g, "Mouse · pet commands", MOUSE_X, -42, 220)
  for i, base in ipairs(MOUSE) do
    local s = MakeCap(page, g, base, 52)
    s:SetPoint("TOPLEFT", MOUSE_X + 4, -(74 + (i - 1) * 66))
    s.nameText = UI.Text(g, "", "GameFontHighlight")
    s.nameText:SetPoint("TOPLEFT", s, "TOPRIGHT", 10, -4)
    s.nameText:SetWidth(150)
    s.nameText:SetJustifyH("LEFT")
    s.nameText:SetWordWrap(false)
    s.stateText = UI.Text(g, "", "GameFontNormal")
    s.stateText:SetPoint("TOPLEFT", s.nameText, "BOTTOMLEFT", 0, -4)
    s.stateText:SetWidth(150)
    s.stateText:SetJustifyH("LEFT")
    s.stateText:SetWordWrap(false)
    s.navRight = ToInspector
    page.caps[base] = s
    page.capList[#page.capList + 1] = s
  end

  -- Left/Right stay on the key's own row (the stagger and the faint keys
  -- would pull a spatial move up or down a row); a row's last key leads to
  -- the mouse button beside it, and back.
  for r, row in ipairs(KEY_ROWS) do
    local list = {}
    for _, base in ipairs(row.keys) do if page.caps[base] then list[#list + 1] = page.caps[base] end end
    for i, s in ipairs(list) do
      s.navLeft = list[i - 1] or false
      s.navRight = list[i + 1] or page.caps[MOUSE[math.min(r, #MOUSE)]]
    end
  end
  page.caps.BUTTON3.navLeft = page.caps["4"]
  page.caps.BUTTON4.navLeft = page.caps.T
  page.caps.BUTTON5.navLeft = page.caps.G

  -- Legend under the mouse column: the same marks the keys wear.
  local legend = {
    { "added", "Added when you apply" }, { "replaces", "Replaces your bind" },
    { "removed", "Cleared when you apply" }, { "missing", "Waiting to learn" }, { "pet", "Pet ability" },
  }
  for i, l in ipairs(legend) do
    local item = UI.LegendItem(g, l[1], l[2])
    item:SetPoint("TOPLEFT", MOUSE_X + 6, -(286 + (i - 1) * 21))
  end

  -- The shown layer's action bar, as it sits on screen (a mirror; not a focus target).
  page.barTitle = UI.Text(g, "", "GameFontNormal")
  page.barTitle:SetPoint("TOPLEFT", KB_X, -BAR_Y)
  page.barSlots = {}
  for i = 1, 12 do
    local s = UI.Slot(g, 30)
    s:SetPoint("TOPLEFT", KB_X + (i - 1) * 36 + math.floor((i - 1) / 4) * 8, -(BAR_Y + 20))
    s:EnableMouse(false)
    s.acSkip = true
    UI.MarkIgnored(s)
    page.barSlots[i] = s
  end
  page.hint = UI.Text(g, "", "GameFontDisable")
  page.hint:SetPoint("TOPLEFT", MOUSE_X + 4, -BAR_Y)
  page.hint:SetWidth(212)
  page.hint:SetJustifyH("LEFT")
end

local function FillPicture(page)
  for _, s in ipairs(page.capList) do FillCap(page, s) end
  local li = ShownLayer(page)
  local after = page.after == 2
  local d = page.data
  local stance = li == 1 and d.stancePage or nil
  page.barTitle:SetText(LAYERS[li].title .. (stance and (" · " .. stance.label .. " page")
      or (LAYERS[li].mod and (" · hold " .. LAYERS[li].mod) or " · no modifier"))
    .. (PreviewLayer(page) and "  (preview)" or ""))
  local K = Keybinds()
  local keys = K and K.KEYS or {}
  for i, s in ipairs(page.barSlots) do
    local slot = li == 1 and PlainSlot(page, i) or (BAR_OFFSET[LAYERS[li].bar] + i)
    local e = d.ab and d.slots[slot]
    local v
    if after and e then v = AfterOfEntry(e) else local dd = UI.DescribeSlot(slot); v = { icon = dd.icon, state = "same" } end
    s:SetState("empty")
    SetSlotIcon(s, v.icon, v.state == "waiting")
    s:SetMark(after and e and (e.state == "new" and UI.C.ADDED or (e.state == "clear" or e.clears) and UI.C.REMOVED or e.state == "missing" and UI.C.MISSING) or nil)
    s:SetKey(keys[i] or "")
  end
  local pad = UI.PadMode and UI.PadMode()
  page.hint:SetText(pad and ("Hold " .. PadName("PADLTRIGGER") .. " or " .. PadName("PADRTRIGGER")
      .. " to preview the Shift or Ctrl layer. "
      .. PadName("PAD3") .. " changes the layer.")
    or "Hold Shift, Ctrl or Alt to preview that layer. Ctrl+Space changes the layer.")
end

-- Side bars view ------------------------------------------------------------------------------

local function SideInspect(s, pane) InspectSide(pane, s.page, s.entry, s.slot) end

local function BuildSide(page, stage)
  local g = CreateFrame("Frame", nil, stage)
  g:SetAllPoints()
  page.side = g
  page.sideRows = {}
  for r = 1, #ROWS - SIDE_FIRST_ROW + 1 + #EXTRA_BARS do
    local row = CreateFrame("Frame", nil, g)
    row:SetPoint("TOPLEFT", 8, -(42 + (r - 1) * SIDE_ROW))
    row:SetPoint("TOPRIGHT", -8, -(42 + (r - 1) * SIDE_ROW))
    row:SetHeight(SIDE_ROW - 2)
    row.bg = row:CreateTexture(nil, "BACKGROUND")
    row.bg:SetAllPoints()
    if UI.SetAtlas(row.bg, r % 2 == 0 and UI.ART.zebra2 or UI.ART.zebra) then
      if r % 2 == 0 and not UI.HasAtlas("UI-Character-Info-Line-Bounce2") then row.bg:SetAlpha(0.45) end
    else row.bg:Hide() end
    row.label = UI.Text(row, "", "GameFontNormal")
    row.label:SetPoint("TOPLEFT", 8, -4)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row.sub = UI.Text(row, "", "GameFontHighlight")
    row.sub:SetPoint("LEFT", row.label, "RIGHT", 10, 0)
    row.sub:SetJustifyH("LEFT")
    row.sub:SetWordWrap(false)
    row.slots = {}
    -- 12 steps of 56 = 672 px, centred in the 696 px row.
    local x0 = 12 + (SIDE_STEP - SIDE_SLOT) / 2
    for i = 1, 12 do
      local s = UI.Slot(row, SIDE_SLOT)
      s:SetPoint("TOPLEFT", x0 + (i - 1) * SIDE_STEP, -20)
      s:SetCaption("")
      s.caption:SetWidth(SIDE_STEP - 2)
      s.caption:SetWordWrap(true)
      if s.caption.SetMaxLines then s.caption:SetMaxLines(2) end
      s.page = page
      s.acInspect = SideInspect
      UI.Node(s, { style = "slot" })
      s:SetScript("OnClick", TogglePin)
      s.acActivate = PinAndEnter
      s.SetPinned = SetPinnedHighlight
      if i == 12 then s.navRight = ToInspector end
      row.slots[i] = s
    end
    page.sideRows[r] = row
  end
  page.sideHint = UI.Text(g, "", "GameFontDisable")
  page.sideHint:SetPoint("BOTTOMLEFT", 12, 12)
  page.sideHint:SetPoint("BOTTOMRIGHT", -12, 12)
  page.sideHint:SetJustifyH("LEFT")
end

local function FillSide(page)
  local plan = page.data.plan
  local after = page.after == 2
  local k = 0
  for r, row in ipairs(page.sideRows) do
    local def = plan and plan.rows[r + SIDE_FIRST_ROW - 1]
    row:SetShown(def ~= nil)
    if def then
      k = k + 1
      row.label:SetText(def.label)
      if def.hidden then row.sub:SetText("Hidden in Edit Mode"); row.sub:SetTextColor(UI.RGB(UI.C.REPLACES))
      else row.sub:SetText("Click only"); row.sub:SetTextColor(UI.RGB(UI.C.GRAY)) end
      for i, s in ipairs(row.slots) do
        local e = plan[r + SIDE_FIRST_ROW - 1][i]
        s.entry, s.slot = e, e.slot
        s.acId = "side:" .. e.slot
        local v
        if after then v = AfterOfEntry(e) else local dd = UI.DescribeSlot(e.slot); v = { icon = dd.icon, name = dd.icon and dd.name or "", state = "same" } end
        local faded = v.state == "waiting"
        s:SetState("empty")
        SetSlotIcon(s, v.icon, faded)
        local mark = after and ((e.state == "new" and UI.C.ADDED) or ((e.state == "clear" or e.clears) and UI.C.REMOVED) or (e.state == "missing" and UI.C.MISSING)) or nil
        s:SetMark(mark)
        local name = (v.state == "empty" or v.state == "clear") and "" or v.name
        s:SetCaption(((name or ""):gsub(" %(or better%)$", "")), faded and UI.C.MISSING or nil)
      end
    end
  end
  local notes = {}
  if not plan then notes[#notes + 1] = "No keyboard layout for " .. (UnitClass("player") or "your class") .. " yet."
  else
    notes[#notes + 1] = "Side bars hold the spells without a key: pet spells, other class spells, tracking, professions and the Cozy Sleeping Bag (while it is in your bags)."
    if #plan.dropped > 0 then notes[#notes + 1] = "No room (they stay in the spellbook): " .. table.concat(plan.dropped, ", ") .. "." end
  end
  page.sideHint:SetText(table.concat(notes, "\n"))
end

-- List view: every key's four layers as icon + name (or the side bars, four slots a row) ----

local function CellInspect(cell, pane)
  local page, d = cell.page, cell.data
  if not d then return end
  if d.side then InspectSide(pane, page, d.entry, d.slot) else InspectCell(pane, page, Cell(page, d.base, d.layer)) end
end

-- The view strip's chip for the view on show (spec §4.5: Up from the first
-- row goes to the view strip, onto the selected view, not the nearest chip).
local function SelectedChip(page)
  local chips = page.strip and page.strip.chips
  if not (chips and chips.buttons and page.views) then return nil end
  for i, v in ipairs(page.views) do
    if v.key == page.view then
      local b = chips.buttons[i]
      if b and b:IsVisible() and (not ns.Focus.Usable or ns.Focus.Usable(b)) then return b end
    end
  end
end

-- Up from a cell of the list's first data row: the selected view chip; else
-- spatial. The rightmost column keeps the spatial move, which reaches the
-- Picture/List and Now/After toggles at the strip's right end.
local function ListCellUp(cell)
  local page, list = cell.page, cell.page.list
  if not (list and list.data and cell.acIndex) or cell.acCol == #LAYERS then return nil end
  for i, d in ipairs(list.data) do
    if not d.header then
      if i == cell.acIndex then return SelectedChip(page) end
      return nil
    end
  end
end

local function MakeListRow(page)
  return function(parent)
    local r = CreateFrame("Frame", nil, parent)
    r.acNode, r.acSkip = true, true -- the cells are the focus targets
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    -- Header rows: the character sheet's category title plate at its own
    -- height (40) and a modest width, text centred between its end
    -- ornaments (as UI.SectionTitle), not the plate stretched across the row.
    r.plate = r:CreateTexture(nil, "BACKGROUND", nil, 1)
    r.plate:SetPoint("LEFT", 0, 0)
    r.plate:SetSize(320, 40)
    if not UI.SetAtlas(r.plate, UI.ART.title) then r.plate:SetTexture(UI.WHITE); r.plate:SetVertexColor(0.9, 0.62, 0.32, 0.18) end
    r.plate:Hide()
    r.head = UI.Text(r, "", "GameFontHighlight")
    r.head:SetPoint("LEFT", r.plate, "LEFT", 22, 0)
    r.head:SetPoint("RIGHT", r.plate, "RIGHT", -22, 0)
    r.head:SetJustifyH("CENTER")
    r.head:SetWordWrap(false)
    r.cap = UI.Keycap(r, "", 30)
    r.cap:SetPoint("LEFT", 8, 0)
    r.cells = {}
    for c = 1, #LAYERS do
      local b = CreateFrame("Button", nil, r)
      b:SetPoint("TOPLEFT", r, "TOPLEFT", CELL_X + (c - 1) * CELL_W, -2)
      b:SetSize(CELL_W - 6, 40)
      b.pinArt = b:CreateTexture(nil, "BACKGROUND", nil, 1)
      b.pinArt:SetAllPoints()
      if not UI.SetAtlas(b.pinArt, UI.ART.rowActive) then b.pinArt:SetTexture(UI.WHITE); b.pinArt:SetVertexColor(1, 0.82, 0, 0.14) end
      b.pinArt:Hide()
      b.slot = UI.Slot(b, 32)
      b.slot:SetPoint("LEFT", 2, 0)
      b.slot:EnableMouse(false)
      b.slot.acSkip = true
      UI.MarkIgnored(b.slot)
      b.name = UI.Text(b, "", "GameFontHighlightSmall") -- four columns: 106 px names, two lines
      b.name:SetPoint("LEFT", b.slot, "RIGHT", 8, 0)
      b.name:SetPoint("RIGHT", b, "RIGHT", -2, 0)
      b.name:SetJustifyH("LEFT")
      b.name:SetWordWrap(true)
      if b.name.SetMaxLines then b.name:SetMaxLines(2) end
      b.page = page
      b.acInspect = CellInspect
      UI.Node(b, { style = "row" })
      b:SetScript("OnClick", TogglePin)
      b.acActivate = PinAndEnter
      b.navUp = ListCellUp
      b.acCol = c
      b.SetPinned = SetPinnedHighlight
      if c == #LAYERS then b.navRight = ToInspector end
      r.cells[c] = b
    end
    return r
  end
end

local function FillListRow(page)
  return function(r, d, i)
    local after = page.after == 2
    r.bg:SetAlpha(1)
    r.head:SetShown(d.header == true)
    r.plate:SetShown(d.header == true)
    r.bg:SetShown(not d.header)
    r.cap:SetShown(not d.header)
    if d.header then
      r.head:SetText(d.text)
      for _, b in ipairs(r.cells) do b:Hide() end
      return
    end
    if UI.SetAtlas(r.bg, UI.ART.zebra) then r.bg:SetAlpha(i % 2 == 0 and 0.45 or 1)
    else r.bg:SetTexture(UI.WHITE); r.bg:SetVertexColor(1, 1, 1, i % 2 == 0 and 0.03 or 0.06) end
    r.cap:SetText(d.capText)
    local shown = ShownLayer(page)
    for c, b in ipairs(r.cells) do
      local cd = d.cells[c]
      b:SetShown(cd ~= nil)
      if cd then
        b.data = cd
        b.acScroll, b.acIndex = page.list, i
        local icon, name, color, faded, mark
        if cd.side then
          local e = cd.entry
          local v
          if after then v = AfterOfEntry(e) else local dd = UI.DescribeSlot(cd.slot); v = { icon = dd.icon, name = dd.icon and dd.name or "Empty", state = dd.icon and "same" or "empty" } end
          faded = v.state == "waiting"
          icon, name = v.icon, v.name
          mark = after and ((e.state == "new" and UI.C.ADDED) or ((e.state == "clear" or e.clears) and UI.C.REMOVED) or (e.state == "missing" and UI.C.MISSING)) or nil
          color = faded and UI.C.MISSING or ((v.state == "empty" or v.state == "clear") and UI.C.DISABLED) or nil
          b.acId = "sidelist:" .. cd.slot
          b.slot:SetKey(tostring(e.i))
          b.slot:SetEdge(nil)
          b:SetAlpha(1)
        else
          local cell = Cell(page, cd.base, cd.layer)
          local v = after and cell.after or cell.now
          faded = after and v.state == "waiting"
          icon, name = v.icon, (v.state == "unbound") and NOT_BOUND_TEXT or v.name
          mark = after and cell.mark or nil
          color = NameColor(cell, after)
          b.acId = "list:" .. cd.base .. ":" .. cd.layer
          b.slot:SetKey("")
          b.slot:SetEdge(after and cell.edge or nil)
          b:SetAlpha((cell.managed or cd.layer == shown) and 1 or 0.7)
        end
        b.slot:SetState("empty")
        SetSlotIcon(b.slot, icon, faded)
        b.slot:SetMark(mark)
        b.name:SetText(name or "")
        b.name:SetTextColor(UI.RGB(color or UI.C.HIGHLIGHT))
      end
    end
  end
end

local function ListData(page)
  local rows = {}
  local n = #LAYERS -- side slots per row match the key view's columns
  if page.view == "side" then
    local plan = page.data.plan
    if not plan then return rows end
    for r = SIDE_FIRST_ROW, #plan.rows do
      local def = plan.rows[r]
      rows[#rows + 1] = { header = true, text = def.label .. (def.hidden and " · hidden in Edit Mode" or " · click only") }
      for g = 0, 12 / n - 1 do
        local cells = {}
        for c = 1, n do
          local e = plan[r][g * n + c]
          cells[c] = { side = true, entry = e, slot = e.slot }
        end
        rows[#rows + 1] = { capText = (g * n + 1) .. "-" .. (g * n + n), cells = cells }
      end
    end
    return rows
  end
  for _, grp in ipairs(LIST_GROUPS) do
    rows[#rows + 1] = { header = true, text = grp.title }
    for _, base in ipairs(grp.keys) do
      local cells = {}
      for li = 1, n do cells[li] = { base = base, layer = li } end
      rows[#rows + 1] = { capText = KeyLabel(base), base = base, cells = cells }
    end
  end
  return rows
end

-- Column heads: Key, then each layer in display order.
local function ListHeads(side)
  local heads = { side and "Slots" or "Key" }
  for li, l in ipairs(LAYERS) do heads[li + 1] = side and "" or l.label end
  return heads
end

local function BuildList(page, stage)
  local g = CreateFrame("Frame", nil, stage)
  g:SetPoint("TOPLEFT", 8, -40)
  g:SetPoint("BOTTOMRIGHT", -8, 8)
  page.listFrame = g
  page.colHeads = {}
  for c, text in ipairs(ListHeads(false)) do
    local fs = UI.Text(g, text, "GameFontNormal")
    fs:SetPoint("TOPLEFT", c == 1 and 10 or (CELL_X + (c - 2) * CELL_W + 4), -4)
    fs:SetJustifyH("LEFT")
    page.colHeads[c] = fs
  end
  local host = CreateFrame("Frame", nil, g)
  host:SetPoint("TOPLEFT", 0, -22)
  host:SetPoint("BOTTOMRIGHT")
  page.list = UI.ScrollList(host, 44, MakeListRow(page), FillListRow(page))
  local list = page.list
  -- The cells are the nodes: PgUp/PgDn/Home/End and the wheel's focus-follow
  -- stay in the focused cell's column.
  function list.Nodes(self)
    local col = 1
    local cur = ns.Focus and ns.Focus.current
    if cur and cur.acScroll == self then
      for _, r in ipairs(self.rows) do for c, b in ipairs(r.cells or {}) do if b == cur then col = c end end end
    end
    local out = {}
    for i = 1, #self.data do
      local r = self.rows[i]
      local b = r and r:IsShown() and r.cells and r.cells[col]
      if b and b:IsShown() and (not ns.Focus or ns.Focus.Usable(b)) then out[#out + 1] = b end
    end
    return out
  end
end

local function FillList(page)
  local side = page.view == "side"
  local li = ShownLayer(page)
  local heads = ListHeads(side)
  for c, fs in ipairs(page.colHeads) do
    fs:SetText(heads[c])
    fs:SetFontObject((not side and c - 1 == li) and "GameFontHighlight" or "GameFontNormal")
  end
  page.list:SetData(ListData(page))
end

-- Review / Commit ----------------------------------------------------------------------------

-- "Shift+E" for a keyed slot, "Action Bar 5 · 3" for a side slot.
local function SlotKeyLabel(e)
  local li = e.r and LAYER_OF_BAR[e.r]
  if li or e.stance then
    local K = Keybinds()
    local key = K and K.KEYS and K.KEYS[e.i]
    if key and e.stance then return e.stanceLabel .. ": " .. key end
    if key then return Chord(key, li) end
  end
  return (SlotText(e.slot):gsub(" · button ", " · "))
end

local function KeyChord(bind)
  local mod, base = bind:match("^(%u+)%-(.+)$")
  base = base or bind
  local label = MOUSE_LABEL[base] or base
  if mod then return mod:sub(1, 1) .. mod:sub(2):lower() .. "+" .. label end
  return label
end

local function Groups(page)
  local d = page.data
  local place, clear, keys, unbind, waiting = {}, {}, {}, {}, {}
  local ids = {}
  if d.ab and d.plan then
    local function Visit(e)
      local now = UI.DescribeSlot(e.slot)
      local nowName = now.name == "Empty slot" and "Empty" or now.name
      if e.state == "new" then
        local a = AfterOfEntry(e)
        place[#place + 1] = { key = SlotKeyLabel(e), nowIcon = now.icon, nowName = nowName,
          afterIcon = a.icon, afterName = a.name, color = UI.C.ADDED,
          note = e.macro and e.kind == "spell" and "plain spell until the macro is installed" or nil }
      elseif e.state == "clear" or e.clears then
        clear[#clear + 1] = { key = SlotKeyLabel(e), nowIcon = now.icon, nowName = nowName,
          afterName = "Empty", color = UI.C.REMOVED, note = e.clears and ("waits for " .. (e.name or "?")) or nil }
      elseif e.state == "missing" then
        waiting[#waiting + 1] = e.name
      end
      if e.state == "new" or e.state == "clear" or e.clears then
        ids[#ids + 1] = "side:" .. e.slot
        ids[#ids + 1] = "sidelist:" .. e.slot
      end
    end
    for r = 1, #d.plan.rows do
      for i = 1, 12 do Visit(d.plan[r][i]) end
    end
    -- Bar 1's stance pages (bonus bar slots).
    for _, st in ipairs(d.plan.stances or {}) do
      for i = 1, 12 do Visit(st[i]) end
    end
    -- Old copies on Action Bars 6-8 that Apply no longer fills.
    for _, s in ipairs(d.plan.stale or {}) do
      local now = UI.DescribeSlot(s.slot)
      clear[#clear + 1] = { key = (SlotText(s.slot):gsub(" · button ", " · ")), nowIcon = now.icon,
        nowName = now.name, afterName = "Empty", color = UI.C.REMOVED, note = "old copy; it has a home on the side bars" }
    end
  end
  if d.kb then
    for _, b in ipairs(d.layout) do
      if b.key then
        local cur = GetBindingAction(b.key) or ""
        if cur ~= b.command then
          local base, li = b.key, 1
          for l, layer in ipairs(LAYERS) do
            local p = layer.prefix
            if p ~= "" and b.key:sub(1, #p) == p then base, li = b.key:sub(#p + 1), l end
          end
          local c = Cell(page, base, li)
          keys[#keys + 1] = { key = KeyChord(b.key), nowIcon = c.now.icon, nowName = c.now.name,
            afterIcon = c.after.icon, afterName = c.after.name,
            color = cur ~= "" and UI.C.REPLACES or UI.C.ADDED, note = cur ~= "" and "replaces your bind" or nil }
        end
      end
    end
    for _, key in ipairs(d.diff.unbinds or {}) do
      local now = UI.DescribeCommand(GetBindingAction(key) or "")
      unbind[#unbind + 1] = { key = KeyChord(key), nowIcon = now and now.icon, nowName = NameOf(now, "?"),
        afterName = NOT_BOUND_TEXT, color = UI.C.REMOVED, note = "another key of this button" }
    end
  end
  -- Keys whose shown content changes (any layer) flash after Apply.
  for _, grp in ipairs(LIST_GROUPS) do
    for _, base in ipairs(grp.keys) do
      for l = 1, #LAYERS do
        if Cell(page, base, l).changed then
          ids[#ids + 1] = "key:" .. base
          ids[#ids + 1] = "list:" .. base .. ":" .. l
        end
      end
    end
  end
  local groups = {}
  if #place > 0 then groups[#groups + 1] = { title = "WILL PLACE", items = place } end
  if #clear > 0 then groups[#groups + 1] = { title = "WILL CLEAR", items = clear } end
  if #keys > 0 then groups[#groups + 1] = { title = "KEYS", items = keys } end
  if #unbind > 0 then groups[#groups + 1] = { title = "WILL UNBIND", items = unbind } end
  return groups, ids, waiting
end

local function Counts(page)
  local d = page.data
  local bars = (d.ab and d.plan) and d.plan.changes or 0
  local keys = d.kb and (d.diff.keys + d.diff.extra) or 0
  local waiting = 0
  if d.plan then waiting = d.plan.spellsMissing + d.plan.itemsMissing + d.plan.macrosMissing end
  return bars, keys, waiting
end

-- Page ------------------------------------------------------------------------------------------

function SavedState(page)
  local db = ns.db
  if type(db) ~= "table" then return end
  db.keyboardPage = type(db.keyboardPage) == "table" and db.keyboardPage or {}
  local s = db.keyboardPage
  s.view, s.mode, s.after = page.view, page.mode, page.after
end

-- Inspector for the "Bar 1 page" picker.
function StanceInspect(row, pane)
  local p = ns.PageById("keyboard")
  local d = p and p.data
  pane:Header("Interface\\Icons\\Ability_Warrior_OffensiveStance", "Bar 1 page", "Stance, form or stealth")
  pane:Row("Showing", row:ValueText(), UI.C.HIGHLIGHT)
  pane:Text("In a stance, form or stealth the game shows another page of Action Bar 1 under the same plain keys. Apply fills every page; the keys need no extra binds.")
  pane:Row("No stance", "slots 1-12")
  for _, st in ipairs(d and d.stances or {}) do
    pane:Row(st.label, "bonus bar " .. st.offset .. " · slots " .. (st.first + 1) .. "-" .. (st.first + 12))
  end
  pane:Text("Pick a page to preview it on the Plain layer. The controller's bars don't page: stance macros cover that there.", UI.C.GRAY)
end

-- The node that stands for the same key in another view (focus survives a view change).
local function TranslateFocus(page)
  local id = page.lastFocusId
  if type(id) ~= "string" then return end
  local list = page.mode == 2
  local base = id:match("^key:(.+)$") or id:match("^list:([^:]+):%d$")
  if base and page.view ~= "side" then
    page.lastFocusId = list and ("list:" .. base .. ":" .. ShownLayer(page)) or ("key:" .. base)
    return
  end
  local slot = id:match("^side:(%d+)$") or id:match("^sidelist:(%d+)$")
  if slot and page.view == "side" then page.lastFocusId = (list and "sidelist:" or "side:") .. slot end
end

ns.RegisterPage({
  id = "keyboard",
  title = "Keyboard",
  api = 2,
  icon = "Interface\\Icons\\INV_Misc_Key_03",
  order = 10,
  view = "plain",
  module = { "ActionBars", "Keybinds" },
  aliases = { "bars", "keys" },
  description = "Your action bars and key bindings as one keyboard. Every key shows what it casts on each layer: plain, with Shift, with Ctrl and with Alt.",
  views = {
    { key = "plain", label = "Plain" }, { key = "shift", label = "Shift" },
    { key = "ctrl", label = "Ctrl" }, { key = "alt", label = "Alt" },
    { key = "side", label = "Side bars" },
  },
  viewLabel = "Layer",
  toggles = {
    { key = "mode", labels = { "Picture", "List" }, get = function(p) return p.mode end,
      set = function(p, i) p.mode = i; TranslateFocus(p); SavedState(p) end },
    { key = "after", labels = { "Now", "After" }, get = function(p) return p.after end,
      set = function(p, i) p.after = i; SavedState(p) end },
  },
  prompts = function() return { { key = "PAD1", label = "Pin" }, { key = "PAD3", label = "Layer" } } end,
  reviewNote = function(p)
    local _, _, waiting = Groups(p)
    local text = "Your bars and keys are backed up the first time you apply. Apply never creates macros."
    if #waiting > 0 then
      local list = {}
      for i = 1, math.min(#waiting, 6) do list[i] = waiting[i] end
      text = "Waiting, no change: " .. table.concat(list, ", ") .. (#waiting > 6 and (" and " .. (#waiting - 6) .. " more") or "")
        .. " (homes stay empty until then). " .. text
    end
    return text
  end,

  Build = function(p, stage)
    -- Stage art: the character sheet's backdrop, else the class art faint on the right.
    local bg = stage:CreateTexture(nil, "BACKGROUND", nil, 1)
    bg:SetPoint("TOPLEFT", 3, -3); bg:SetPoint("BOTTOMRIGHT", -3, 3)
    if not UI.SetAtlas(bg, UI.ART.generalBg) then
      local _, class = UnitClass("player")
      bg:ClearAllPoints()
      bg:SetPoint("TOPRIGHT", -3, -3); bg:SetPoint("BOTTOMRIGHT", -3, 3)
      bg:SetWidth(352)
      if class and UI.SetAtlas(bg, { "ui-character-info-" .. class:lower() .. "-bg" }) then bg:SetAlpha(0.6) else bg:Hide() end
      local fade = UI.Gradient(stage, "BACKGROUND", "HORIZONTAL", { 0, 0, 0, 0.9 }, { 0, 0, 0, 0 }, 2)
      fade:SetPoint("TOPLEFT", bg, "TOPLEFT"); fade:SetPoint("BOTTOMLEFT", bg, "BOTTOMLEFT")
      fade:SetWidth(180)
    end
    local vignette = UI.Gradient(stage, "BACKGROUND", "VERTICAL", { 0, 0, 0, 0.55 }, { 0, 0, 0, 0 }, 3)
    vignette:SetPoint("BOTTOMLEFT", 3, 3); vignette:SetPoint("BOTTOMRIGHT", -3, 3)
    vignette:SetHeight(120)

    local saved = type(ns.db) == "table" and type(ns.db.keyboardPage) == "table" and ns.db.keyboardPage or {}
    p.view = LAYER_OF_VIEW[saved.view or ""] and saved.view or (saved.view == "side" and "side") or p.view or "plain"
    p.mode = saved.mode == 2 and 2 or 1
    p.after = saved.after == 1 and 1 or 2

    BuildPicture(p, stage)
    BuildSide(p, stage)
    BuildList(p, stage)

    -- Below the bar mirror: the spec whose layout the plan shows, and (for
    -- classes whose Bar 1 pages by stance, form or stealth) the page the
    -- Plain layer previews. Picture and Side views; the List fills the stage.
    p.specRow = UI.SpecRow(stage, 340, "keyboard:spec")
    p.specRow:SetPoint("TOPLEFT", 8, -472)
    p.stanceRow = UI.ChoiceRow(stage, {
      label = "Bar 1 page", width = 340, id = "keyboard:stance", inspect = StanceInspect,
      choices = function()
        local out = { { "none", "No stance" } }
        for _, st in ipairs(p.data and p.data.stances or {}) do out[#out + 1] = { st.key, st.label } end
        return out
      end,
      get = function() return p.stance end,
      set = function(key)
        p.stance = key
        if p.view ~= "plain" then p.view = "plain"; SavedState(p) end
        UI.Refresh()
      end,
    })
    p.stanceRow:SetPoint("TOPLEFT", 364, -472)

    -- Live layer preview: Shift / Ctrl / Alt (LT on the Gamepad UI is
    -- Shift, RT is Ctrl). Display only.
    UI.WatchModifiers(stage, function(shift, ctrl, alt)
      p.mods = { shift, ctrl, alt }
      -- Ctrl let go: the next Ctrl press previews again after a chord.
      if not ctrl and ns.Input then ns.Input.ctrlChord = nil end
      local want = PreviewLayer(p)
      if want == p.preview then return end
      p.preview = want
      if not p.data or p.view == "side" then return end
      -- Instant swap in place, no bump, fade or sound (Blizzard's bars
      -- switch pages silently on a modifier).
      if p.mode == 2 then FillList(p) else FillPicture(p) end
      local cur = ns.Focus and ns.Focus.current
      if cur and not ns.Focus.pinned and cur.acInspect and (cur.page == p) then ns.Focus:Inspect(cur) end
    end)
  end,

  OnView = function(p) TranslateFocus(p); SavedState(p) end,

  Refresh = function(p)
    Gather(p)
    local side, list = p.view == "side", p.mode == 2
    p.picture:SetShown(not side and not list)
    p.side:SetShown(side and not list)
    p.listFrame:SetShown(list)
    if list then FillList(p)
    elseif side then FillSide(p)
    else FillPicture(p) end
    local specs = not list and p.specRow:HasSpecs()
    p.specRow:SetShown(specs)
    if specs then p.specRow:Sync() end
    local stances = not list and #(p.data.stances or {}) > 0
    p.stanceRow:SetShown(stances)
    if stances then p.stanceRow:Sync() end
  end,

  Status = function(p)
    local d = p.data
    if not d then return "" end
    local bars, keys, waiting = Counts(p)
    local n = bars + keys
    local parts = {}
    parts[1] = n > 0 and UI.C.ADDED:WrapTextInColorCode(Plural(n, "change", "changes") .. " ready")
      or UI.C.GREEN:WrapTextInColorCode("Up to date")
    if d.kb and d.diff.replace > 0 then
      parts[#parts + 1] = UI.C.REPLACES:WrapTextInColorCode(d.diff.replace .. (d.diff.replace == 1 and " replaces your bind" or " replace your binds"))
    end
    if waiting > 0 then parts[#parts + 1] = UI.C.MISSING:WrapTextInColorCode(waiting .. " waiting to learn") end
    local tip = {}
    local _, class = UnitClass("player")
    local spec = ns.Layout and ns.Layout.SpecLabel(class)
    if spec then tip[#tip + 1] = "Spec: " .. spec end
    if d.ab and d.plan then tip[#tip + 1] = "Bars: " .. Plural(bars, "slot changes", "slots change") end
    if d.kb then tip[#tip + 1] = "Keys: " .. Plural(d.diff.keys, "key to set", "keys to set")
      .. (d.diff.extra > 0 and (", " .. Plural(d.diff.extra, "other key", "other keys") .. " to unbind") or "") end
    if not d.ab then tip[#tip + 1] = "Action Bars is turned off: only the keys change." end
    if not d.kb then tip[#tip + 1] = "Key Bindings is turned off: only the bars change." end
    local plan = d.plan
    if plan then
      local miss = {}
      if plan.spellsMissing > 0 then miss[#miss + 1] = plan.spellsMissing .. " not learned" end
      if plan.itemsMissing > 0 then miss[#miss + 1] = plan.itemsMissing .. " not in bags" end
      if plan.macrosMissing > 0 then miss[#miss + 1] = Plural(plan.macrosMissing, "macro", "macros") .. " to install" end
      if #miss > 0 then tip[#tip + 1] = "Waiting: " .. table.concat(miss, " · ") end
      if plan.kept > 0 then tip[#tip + 1] = Plural(plan.kept, "slot", "slots") .. " kept: Apply leaves them alone, since Restore can't put back what they hold." end
      if #(plan.stale or {}) > 0 then tip[#tip + 1] = Plural(#plan.stale, "old copy", "old copies") .. " on Action Bars 6-8 cleared: each spell has one home." end
      if #plan.dropped > 0 then tip[#tip + 1] = "No room on the side bars: " .. table.concat(plan.dropped, ", ") .. "." end
      for _, label in ipairs(plan.hidden) do tip[#tip + 1] = label .. " is hidden. Turn it on in Edit Mode." end
    else
      tip[#tip + 1] = "No keyboard layout for " .. (UnitClass("player") or "your class") .. " yet: only the keys are shown."
    end
    return table.concat(parts, " · "), tip
  end,

  readiness = function(p)
    local d = p.data
    if not d then return nil end
    local done, total = 0, 0
    for _, grp in ipairs(LIST_GROUPS) do
      for _, base in ipairs(grp.keys) do
        for l = 1, #LAYERS do
          local c = Cell(p, base, l)
          if c.managed and not c.waiting and c.after.state ~= "empty" and c.after.state ~= "unbound"
            and c.after.state ~= "free" then
            total = total + 1
            if not c.changed then done = done + 1 end
          end
        end
      end
    end
    if d.ab and d.plan then
      for r = SIDE_FIRST_ROW, #d.plan.rows do
        for i = 1, 12 do
          local e = d.plan[r][i]
          if e.state == "same" or e.state == "new" then
            total = total + 1
            if e.state == "same" then done = done + 1 end
          end
        end
      end
      -- Bar 1's stance pages count like the side bars (they have no binding of their own).
      for _, st in ipairs(d.plan.stances or {}) do
        for i = 1, 12 do
          local e = st[i]
          if e.state == "same" or e.state == "new" then
            total = total + 1
            if e.state == "same" then done = done + 1 end
          end
        end
      end
    end
    return done, total
  end,

  Review = function(p)
    if not p.data then Gather(p) end
    return (Groups(p))
  end,

  Commit = function(p)
    Gather(p)
    local _, ids = Groups(p)
    local d = p.data
    local bars, keys = Counts(p)
    if d.ab and bars > 0 then Apply() end
    local K = Keybinds()
    if d.kb and keys > 0 and K and K.Apply then K.Apply() end
    return nil, nil, ids
  end,

  DefaultFocus = function(p)
    if p.mode == 2 then
      local nodes = p.list:Nodes()
      return nodes[1]
    end
    if p.view == "side" then
      for _, row in ipairs(p.sideRows) do if row:IsShown() then return row.slots[1] end end
      return nil
    end
    for _, s in ipairs(p.capList) do if s.cell and s.cell.changed then return s end end
    return p.caps.Q
  end,

  DefaultInspect = function(p, pane)
    p.pane = pane
    local d = p.data
    pane:Header("Interface\\Icons\\INV_Misc_Key_03", "Keyboard", "Action bars and key bindings")
    if d then
      local bars, keys, waiting = Counts(p)
      pane:Row("Bar slots to change", tostring(bars), bars > 0 and UI.C.ADDED or nil)
      pane:Row("Keys to set", tostring(keys), keys > 0 and UI.C.ADDED or nil)
      if d.kb and d.diff.replace > 0 then pane:Row("Replace your binds", tostring(d.diff.replace), UI.C.REPLACES) end
      pane:Row("Waiting to learn", tostring(waiting), waiting > 0 and UI.C.MISSING or nil)
    end
    pane:Section("How it works")
    pane:Text("The same 12 keys work on every bar: plain is Action Bar 1, Shift is Action Bar 2, Ctrl is Action Bar 4 and Alt is Action Bar 3 (the item macros once you install them on the Macros page: HealPot, ManaPot, Bandage and Food on Alt+Q, E, R and T, Fish and Bait on Alt+F and Alt+G; on-use trinkets on Alt+C and Alt+V, the Hearthstone on Alt+4). Spells without a key sit on the side bars, Action Bars 5-8, each once, with the Cozy Sleeping Bag after the professions; nothing else from your bags goes on a bar. Pet abilities sit on Z and X, pet commands on the mouse buttons.")
    pane:Text("Move to a key to see all four layers. " .. PadName("PAD1") .. " or Enter pins it here.", UI.C.GRAY)
    pane:Buttons(RestoreButtons())
  end,

  -- Right stick: the list in List view while focus is in it; otherwise the
  -- Inspector, so its overflowing text can be read with the controller.
  ScrollRegion = function(p)
    local F = ns.Focus
    local inInspector = F and F.current and F.ZoneOf and F.ZoneOf(F.current) == "inspector"
    if p.mode == 2 and p.list and p.list.scroll and not inInspector then return p.list.scroll end
    return p.pane and p.pane.scroll or nil
  end,

  OnHide = function(p)
    if ns.Focus and ns.Focus.pinned and ns.Focus.pinned.page == p then ns.Focus:Unpin() end
  end,
})

ns.RegisterCommand("spells", "list the Action Bars layout, or apply/undo it (also /ac bars)", function(arg)
  arg = (arg or ""):lower()
  if arg == "apply" then Apply()
  elseif arg == "undo" then Undo()
  else Show() end
end, { usage = "spells [apply|undo]", module = "ActionBars" })

-- /ac spec [auto|<key>]: which spec's layout the bars and the controller use
-- (the Spec picker on the Keyboard and Controller pages does the same).
ns.RegisterCommand("spec", "show or set the spec your layouts use: auto, or a spec key", function(arg)
  arg = (arg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  local L = ns.Layout
  local _, class = UnitClass("player")
  local specs = L and L.Specs(class) or {}
  if #specs == 0 then return ns.Print("no specs for " .. tostring(class) .. " yet.") end
  local keys = {}
  for i, s in ipairs(specs) do keys[i] = s.key .. " (" .. s.name .. ")" end
  if arg ~= "" then
    if arg ~= "auto" and not L.SpecByKey(class, arg) then
      return ns.Print("unknown spec '" .. arg .. "'. Use auto or one of: " .. table.concat(keys, ", ") .. ".")
    end
    L.SetSpecChoice(arg)
    if UI and UI.Refresh then UI.Refresh() end
  end
  ns.Print("spec: " .. tostring(L.SpecLabel(class)) .. ". Choices: auto, " .. table.concat(keys, ", ")
    .. ". Apply on the Keyboard and Controller pages puts it on your bars.")
end, { usage = "spec [auto|<key>]", module = "ActionBars" })
