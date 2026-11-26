-- Macro library core: categories, the macro registry, placeholder filling,
-- install state and install/remove. Macro data lives in Macros/Data/*.lua;
-- the window page is Macros/Page.lua.
--
-- Adding a macro (in a Data file):
--   L.Add({
--     name = "Opener",            -- shown on the action button; 16 characters max
--     category = "combat",        -- a key from L.categories
--     class = "HUNTER",           -- omit for every class
--     race = "Tauren",            -- race file name (Scourge = Undead, NightElf); omit for every race
--     profession = "Fishing",     -- profession it needs; omit if none
--     tags = { "solo", "group" }, -- free topic tags shown as chips
--     specs = { "prot" },         -- spec keys (Layouts/<Class>.lua) it is recommended for: a gold chip each,
--                                 -- and the Macros page lists your spec's first
--     order = 10,                 -- position inside its category (lower first)
--     icon = "Serpent Sting",     -- spell or item name for the picture; or iconFile = "INV_..."
--     requires = { "Serpent Sting" }, -- spells that must be in your spellbook
--     perCharacter = true,        -- character tab (class macros) or account tab
--     power = "mana",             -- only classes with mana (L.Fits hides it from warriors and rogues)
--     generated = "healpot",      -- an item macro: Macros/Items.lua builds its body from your bags
--     untested = true,            -- shows a warning: not yet confirmed on this game version
--     desc = "One sentence: what pressing it does.",
--     body = "#showtooltip ...\n/cast ...",   -- 255 characters max after filling;
--                                 -- for a generated macro, the text used while you carry none
--   })
--
-- Conventions every macro follows:
--   * Start with #showtooltip so the button shows the right icon and cooldown.
--   * Install once, works forever: a hand-written macro names only spells and
--     slash commands, never an item (food, pole, weapon, potion).
--   * Item macros are generated instead (owner decision, 2026-11-24): Fish,
--     Bait, HealPot, ManaPot, Bandage and Food name the best item you carry,
--     and Agentcraft rewrites them when that changes (L.UpdateGenerated, run
--     by the ItemMacros module in Macros/Items.lua). They are character
--     macros, since bags differ, and only a copy Agentcraft wrote is rewritten.
--   * No Shift/Ctrl variants (they are bar layers) and no @mouseover/@cursor.
--   * Harmful casts use [@target,harm,nodead] so they never hit friends or corpses.
--   * Name it after what it does, one word where possible ("Opener", "Fish").
--   * Install and Remove touch only macros Agentcraft wrote (every body it
--     ever wrote is recorded in AgentcraftDB.macroWritten, so a copy on
--     another character still counts). A player's own macro of the same name
--     is "taken" (Name in use) until they pick Replace. Remove also unbinds
--     the macro's keys.
--   * When a live macro's text changes, add its old text to L.previous[name]
--     (a list) so installed copies show "Update", not "Name in use".
--     A macro dropped from the library goes in L.retired (General.lua).
local _, ns = ...
local L = {}
ns.MacroLibrary = L

L.categories = {
  { key = "combat", title = "Combat", icon = "Interface\\Icons\\Ability_Marksmanship" },
  { key = "pet", title = "Pet", icon = "Interface\\Icons\\Ability_Hunter_BeastCall" },
  { key = "racial", title = "Racial", icon = "Interface\\Icons\\Ability_WarStomp" },
  { key = "fishing", title = "Fishing", icon = "Interface\\Icons\\Trade_Fishing" },
  { key = "consumables", title = "Consumables", icon = "Interface\\Icons\\INV_Potion_54" },
  { key = "professions", title = "Professions", icon = "Interface\\Icons\\Trade_Engineering" },
  { key = "utility", title = "Utility", icon = "Interface\\Icons\\INV_Misc_Bag_08" },
}
local CATEGORY_RANK = {}
for i, c in ipairs(L.categories) do CATEGORY_RANK[c.key] = i end

L.macros = {}
-- Older texts of live macros, by name: { "old body", ... }. Data files add to it.
L.previous = {}

function L.Add(m)
  assert(m.name and #m.name <= 16, "macro name missing or longer than 16 characters: " .. tostring(m.name))
  assert(CATEGORY_RANK[m.category], "unknown macro category: " .. tostring(m.category))
  table.insert(L.macros, m)
end

-- Tags ------------------------------------------------------------------------------
-- Every macro gets tags worked out from its fields: class, race, profession,
-- category, its own topic tags, and "Untested". The page filters on them.

L.tagTypes = {
  class = { order = 1 },
  race = { order = 2, color = { 0.85, 0.65, 0.45 } },
  profession = { order = 3, color = { 0.45, 0.85, 0.45 } },
  spec = { order = 3.5, color = { 1, 0.82, 0 } },
  topic = { order = 4, color = { 0.8, 0.8, 0.8 } },
  status = { order = 5, color = { 1, 0.55, 0.2 } },
}

local RACE_LABELS = { Scourge = "Undead", NightElf = "Night Elf" }

local function Title(s) return (s:gsub("^%l", string.upper)) end

local function ClassLabel(class)
  local names = LOCALIZED_CLASS_NAMES_MALE
  return names and names[class] or Title(class:lower())
end

-- { { key, label, type, color }, ... } sorted by type then label.
function L.Tags(m)
  if m._tags then return m._tags end
  local tags, seenKey, seenLabel = {}, {}, {}
  -- One tag per label: Fish's profession "Fishing" already says what the
  -- "Fishing" category would, so the filter menu lists it once.
  local function Add(kind, value, label, color)
    local key = kind .. ":" .. value
    if seenKey[key] or seenLabel[label:lower()] then return end
    seenKey[key], seenLabel[label:lower()] = true, true
    tags[#tags + 1] = { key = key, label = label, type = kind,
      color = color or L.tagTypes[kind].color }
  end
  if m.class then
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[m.class]
    Add("class", m.class, ClassLabel(m.class), c and { c.r, c.g, c.b })
  end
  if m.race then Add("race", m.race, RACE_LABELS[m.race] or m.race) end
  if m.profession then Add("profession", m.profession, m.profession) end
  -- Recommended for a spec (owner, 2026-11-26): one chip per spec it suits.
  for _, key in ipairs(m.specs or {}) do
    local Lay = ns.Layout
    local spec = Lay and m.class and Lay.SpecByKey and Lay.SpecByKey(m.class, key)
    Add("spec", key, spec and spec.name or Title(key))
  end
  for _, c in ipairs(L.categories) do
    if c.key == m.category then Add("topic", c.key, c.title) end
  end
  for _, t in ipairs(m.tags or {}) do Add("topic", t, Title(t)) end
  if m.untested then Add("status", "untested", "Untested") end
  table.sort(tags, function(a, b)
    local oa, ob = L.tagTypes[a.type].order, L.tagTypes[b.type].order
    if oa ~= ob then return oa < ob end
    return a.label < b.label
  end)
  m._tags = tags
  return tags
end

function L.HasTag(m, key)
  for _, t in ipairs(L.Tags(m)) do if t.key == key then return true end end
  return false
end

-- Professions this character has, by name.
local function MyProfessions()
  local have = {}
  if GetProfessions then
    -- Any of the six (primary 1, primary 2, archaeology, fishing, cooking,
    -- first aid) can be nil, and ipairs stops at the first nil, so walk
    -- every return.
    local list = { GetProfessions() }
    for p = 1, select("#", GetProfessions()) do
      local name = list[p] and GetProfessionInfo(list[p])
      if name then have[name] = true end
    end
  end
  return have, GetProfessions ~= nil
end

-- Classes without a mana bar: a macro with power = "mana" (ManaPot) doesn't
-- fit them, and its shared homes stay empty there.
L.NO_MANA = { WARRIOR = true, ROGUE = true }

-- Whether the macro suits this character's class, race and professions.
function L.Fits(m)
  local _, class = UnitClass("player")
  local _, race = UnitRace("player")
  if m.class and m.class ~= class then return false end
  if m.race and m.race ~= race then return false end
  if m.power == "mana" and L.NO_MANA[class] then return false end
  if m.profession then
    local have, canCheck = MyProfessions()
    if canCheck and not have[m.profession] then return false end
  end
  return true
end

-- Whether m is recommended for the character's active spec (m.specs).
local function MySpec()
  if not ns.Layout or not ns.Layout.ActiveSpec then return nil end
  local _, class = UnitClass("player")
  return ns.Layout.ActiveSpec(class), class
end
function L.ForMySpec(m, spec, class)
  if not m.specs then return false end
  if not spec then spec, class = MySpec() end
  if m.class and m.class ~= class then return false end
  for _, k in ipairs(m.specs) do if spec and spec.key == k then return true end end
  return false
end

-- Macros sorted by category, then your spec's recommended ones, then order,
-- then name. Only the ones that fit this character unless showAll.
function L.Entries(showAll)
  local list, mine = {}, {}
  local spec, class = MySpec()
  for _, m in ipairs(L.macros) do mine[m] = L.ForMySpec(m, spec, class) end
  for _, m in ipairs(L.macros) do
    if showAll or L.Fits(m) then list[#list + 1] = m end
  end
  table.sort(list, function(a, b)
    local ca, cb = CATEGORY_RANK[a.category], CATEGORY_RANK[b.category]
    if ca ~= cb then return ca < cb end
    if mine[a] ~= mine[b] then return mine[a] end
    if (a.order or 50) ~= (b.order or 50) then return (a.order or 50) < (b.order or 50) end
    return a.name < b.name
  end)
  return list
end

-- Known spells ----------------------------------------------------------------------

local known

-- Only learned spells count: the 12.x spellbook also lists spells you learn
-- later (FutureSpell) and flyouts. want = the item type to accept.
local function ScanBank(map, bank, from, to, want)
  for i = from, to do
    local item = C_SpellBook.GetSpellBookItemInfo(i, bank)
    if item and item.name and (want == nil or item.itemType == nil or item.itemType == want) then
      map[item.name] = true
    end
  end
end

-- Spells in the player and pet spellbooks, cached until L.Invalidate().
function L.Known()
  if known then return known end
  known = {}
  if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines then
    local player = Enum.SpellBookSpellBank.Player
    local types = Enum.SpellBookItemType or {}
    for tab = 1, C_SpellBook.GetNumSpellBookSkillLines() do
      local line = C_SpellBook.GetSpellBookSkillLineInfo(tab)
      if line then ScanBank(known, player, line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems, types.Spell) end
    end
    if C_SpellBook.HasPetSpells then
      ScanBank(known, Enum.SpellBookSpellBank.Pet, 1, C_SpellBook.HasPetSpells() or 0, types.PetAction)
    end
  end
  return known
end

function L.Invalidate() known = nil end

-- { { spell, true/false }, ... } for the detail panel.
function L.Requirements(m)
  local out, k = {}, L.Known()
  for _, spell in ipairs(m.requires or {}) do out[#out + 1] = { spell, k[spell] and true or false } end
  return out
end

function L.MissingSpell(m)
  for _, r in ipairs(L.Requirements(m)) do
    if not r[2] then return r[1] end
  end
end

-- Placeholders ----------------------------------------------------------------------


-- Fishing poles are weapon class 2, subclass 20 on every client and
-- language; the subtype text differs ("Fishing Poles" vs "Fishing Pole").
function L.IsPole(id)
  if not (id and C_Item and C_Item.GetItemInfoInstant) then return false end
  local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(id)
  return classID == 2 and subClassID == 20
end
local IsPole = L.IsPole

local function BagItemIDs()
  local ids, seen = {}, {}
  for bag = 0, NUM_BAG_SLOTS or 4 do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local id = C_Container.GetContainerItemID(bag, slot)
      if id and not seen[id] then seen[id] = true; ids[#ids + 1] = id end
    end
  end
  return ids
end

-- The pole in your hands or bags: item ID.
local function FindPole()
  local main = GetInventoryItemID("player", 16)
  if IsPole(main) then return main end
  for _, id in ipairs(BagItemIDs()) do if IsPole(id) then return id end end
end

-- Weapons to return to after fishing: what you wear now, or what Agentcraft
-- saw you wearing before you picked up the pole.
local function Weapons()
  local main, off = GetInventoryItemID("player", 16), GetInventoryItemID("player", 17)
  if main and not IsPole(main) then return main, off end
  local saved = ns.charDB and ns.charDB.weapons
  if saved then return saved.main, saved.off end
  -- Never seen: take the first bound main-hand weapon and off-hand item in
  -- your bags. Unbound items (a BoE you mean to sell) are skipped, and a
  -- two-hander takes no off-hand (equipping one would unequip it again).
  main, off = nil, nil
  local mainLoc
  local getInfo = C_Container and C_Container.GetContainerItemInfo
  for bag = 0, NUM_BAG_SLOTS or 4 do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local id = C_Container.GetContainerItemID(bag, slot)
      local info = id and getInfo and getInfo(bag, slot)
      if id and not (info and info.isBound == false) then
        local _, _, _, equipLoc, _, classID = C_Item.GetItemInfoInstant(id)
        if not main and classID == 2 and not IsPole(id) and (equipLoc == "INVTYPE_WEAPON"
          or equipLoc == "INVTYPE_WEAPONMAINHAND" or equipLoc == "INVTYPE_2HWEAPON") then
          main, mainLoc = id, equipLoc
        elseif not off and (equipLoc == "INVTYPE_HOLDABLE" or equipLoc == "INVTYPE_SHIELD"
          or equipLoc == "INVTYPE_WEAPONOFFHAND") then
          off = id
        end
      end
    end
  end
  if mainLoc == "INVTYPE_2HWEAPON" then off = nil end
  return main, off
end
L.Weapons = Weapons
L.FindPole = FindPole

-- Placeholders ({KEY} in a body) fill in fixed facts of the client. What is
-- in your bags is not a placeholder: item macros are generated
-- (m.generated, Macros/Items.lua) and rewritten when your bags change.
L.placeholders = {}

-- {POLETYPE}: the client's own name for the fishing pole subtype, the text
-- [equipped:...] matches. A fixed fact of the client, not of your bags.
-- "Fishing Poles" never matched on WoW Forever (owner, 0.32.2: Fish equipped
-- the pole but the next press didn't cast), so it is read, not assumed:
-- the item subtype of a pole you carry or wear, else the subclass name.
L.placeholders.POLETYPE = function()
  local pole = FindPole()
  if pole and C_Item and C_Item.GetItemInfo then
    local subType = select(7, C_Item.GetItemInfo(pole))
    if type(subType) == "string" and subType ~= "" then return subType end
  end
  local info = (C_Item and C_Item.GetItemSubClassInfo) or _G.GetItemSubClassInfo
  if info then
    local name = info(2, 20)
    if type(name) == "string" and name ~= "" then return name end
  end
  return "Fishing Poles"
end

-- The body with placeholders filled, or nil and a short reason.
-- {KEY?} is optional: when it can't be filled, its line is dropped.
function L.Resolve(m)
  local reason
  local lines = {}
  local text = m.body
  if m.generated then
    -- An item macro: the text for the best item you carry, else m.body
    -- (which says you carry none).
    local gen = L.generators and L.generators[m.generated]
    text = gen and gen() or m.body
  end
  for line in (text .. "\n"):gmatch("(.-)\n") do
    local drop = false
    line = line:gsub("{(%u+)(%??)}", function(key, optional)
      local fn = L.placeholders[key]
      local value, why
      if fn then value, why = fn() end
      if value then return value end
      if optional == "?" then drop = true else reason = reason or why or ("can't fill " .. key) end
      return ""
    end)
    if not drop then lines[#lines + 1] = line end
  end
  if reason then return nil, reason end
  local body = table.concat(lines, "\n")
  if #body > 255 then return nil, "longer than 255 characters" end
  return body
end

-- State -----------------------------------------------------------------------------

local function IndexOf(name)
  local i = GetMacroIndexByName(name)
  if i and i > 0 then return i end
  -- Macros installed by the first catalog used an "AC " prefix.
  i = GetMacroIndexByName("AC " .. name)
  if i and i > 0 then return i, true end
  return 0
end

local function Trim(s) return ((s or ""):gsub("%s+$", "")) end

-- Every body Agentcraft ever wrote, by macro name (account SavedVariables):
-- { [name] = { [body] = true } }. A set, not the last body, because class
-- macros live in each character's own tab: one hunter updating Melee must
-- not turn another hunter's older copy into "Name in use". Removing a macro
-- keeps its record for the same reason.
local function Written(name, peek)
  if not ns.db then return {} end
  local all = ns.db.macroWritten
  if not all then
    all = {}
    ns.db.macroWritten = all
    -- 0.26.0 kept one body per name (macroBodies); carry it over once.
    for n, body in pairs(ns.db.macroBodies or {}) do
      if type(body) == "string" then all[n] = { [Trim(body)] = true } end
    end
  end
  if peek then return all[name] or {} end
  all[name] = all[name] or {}
  return all[name]
end

-- macroBodies (the last body per name) is still kept for code that reads it.
local function Record(name, body)
  Written(name)[Trim(body)] = true
  if ns.db then
    ns.db.macroBodies = ns.db.macroBodies or {}
    ns.db.macroBodies[name] = Trim(body)
  end
end

-- Whether Agentcraft ever wrote this exact text under this name. Retired
-- shapes (General.lua) use it so a macro you wrote yourself is never deleted.
function L.Wrote(name, body)
  return Written(name, true)[Trim(body)] == true
end

-- Whether a macro named name with this body is a retired Agentcraft macro
-- that may be deleted (Controller Apply uses it). A name still in the library
-- never is. Fixed texts in L.retired match exactly; texts players often
-- write themselves (L.retiredCommon) and the shapes (L.retiredShapes) also
-- need Agentcraft's record of writing them.
function L.RetiredDeletable(name, body)
  for _, m in ipairs(L.macros) do if m.name == name then return false end end
  body = Trim(body)
  local fixed = L.retired and L.retired[name]
  if fixed and Trim(fixed) == body then
    return not (L.retiredCommon and L.retiredCommon[name]) or L.Wrote(name, body)
  end
  local shape = L.retiredShapes and L.retiredShapes[name]
  return shape and shape(body) and true or false
end

-- Whether body is an older library text of this macro.
local function Previous(name, body)
  for _, old in ipairs(L.previous[name] or {}) do
    if Trim(old) == body then return true end
  end
  return false
end

-- Whether the macro at index is one Agentcraft wrote.
local function IsOurs(m, index, legacy, body)
  if legacy then return true end
  local current = Trim(GetMacroBody(index))
  if body and current == Trim(body) then
    Record(m.name, current)
    return true
  end
  return L.Wrote(m.name, current) or Previous(m.name, current)
end

-- A class or racial macro sitting in the shared account tab (installed
-- before it was marked perCharacter). EditMacro can't move it between tabs.
local function InWrongTab(m, index)
  return m.perCharacter and index <= (MAX_ACCOUNT_MACROS or 120)
end

-- Returns state, index, detail. States:
--   installed  in /macro and up to date
--   update     in /macro but its text differs (spell or item changed)
--   taken      a macro of yours already has this name (Name in use); left
--              alone unless you pick Replace on that macro
--   blocked    can't be installed yet; detail is the missing spell, or why
--   ready      can be installed
function L.State(m)
  local index, legacy = IndexOf(m.name)
  local body, why = L.Resolve(m)
  local missing = L.MissingSpell(m)
  if index > 0 then
    if not IsOurs(m, index, legacy, body) then return "taken", index, "your own macro has this name" end
    if legacy or InWrongTab(m, index) or (body and Trim(GetMacroBody(index)) ~= Trim(body)) then return "update", index end
    return "installed", index
  end
  if missing then return "blocked", 0, missing end
  if not body then return "blocked", 0, why end
  return "ready", 0
end

-- A generated macro keeps the question-mark icon, so its button shows the
-- item its #showtooltip names.
local function IconFor(m) return (not m.generated and m.iconFile) or "INV_Misc_QuestionMark" end

-- Free slots in the General (account) and Character macro tabs.
local function FreeSlots()
  local acct, char = 0, 0
  if GetNumMacros then acct, char = GetNumMacros() end
  return (MAX_ACCOUNT_MACROS or 120) - (acct or 0), (MAX_CHARACTER_MACROS or 18) - (char or 0)
end

-- Moves key bindings from one macro name to another (legacy "AC X" -> "X").
local function Rebind(from, to)
  if not (GetBindingKey and SetBinding) then return false end
  local keys = { GetBindingKey("MACRO " .. from) }
  for _, key in ipairs(keys) do SetBinding(key, "MACRO " .. to) end
  return #keys > 0
end

local function SaveBinds()
  if SaveBindings and GetCurrentBindingSet then SaveBindings(GetCurrentBindingSet()) end
end

-- replace = true also overwrites a macro of yours with the same name (the
-- detail panel's Replace button); checked installs never do.
function L.Install(list, replace)
  if InCombatLockdown() then return ns.Print("can't change macros in combat.") end
  local done, skipped, moved, rebound = {}, {}, {}, false
  local freeAcct, freeChar = FreeSlots()
  for _, m in ipairs(list) do
    local body, why = L.Resolve(m)
    local missing = L.MissingSpell(m)
    local index, legacy = IndexOf(m.name)
    local create = index == 0 or InWrongTab(m, index)
    if missing then
      skipped[#skipped + 1] = m.name .. " (learn " .. missing .. ")"
    elseif not body then
      skipped[#skipped + 1] = m.name .. " (" .. why .. ")"
    elseif index > 0 and not replace and not IsOurs(m, index, legacy, body) then
      skipped[#skipped + 1] = m.name .. " (name in use by your own macro)"
    elseif create and m.perCharacter and freeChar <= 0 then
      skipped[#skipped + 1] = m.name .. " (Character macros full: " .. (MAX_CHARACTER_MACROS or 18) .. " of " .. (MAX_CHARACTER_MACROS or 18) .. ")"
    elseif create and not m.perCharacter and freeAcct <= 0 then
      skipped[#skipped + 1] = m.name .. " (General macros full: " .. (MAX_ACCOUNT_MACROS or 120) .. " of " .. (MAX_ACCOUNT_MACROS or 120) .. ")"
    else
      local ok, err
      if create then
        -- A new macro, or a character macro sitting in the General tab: the
        -- new copy is created first, and the old one deleted only once that
        -- worked, so a failure never loses the macro.
        ok, err = pcall(CreateMacro, m.name, IconFor(m), body, m.perCharacter and true or nil)
        if ok and not (err and err ~= 0) then ok, err = false, "the game refused to create it" end
        if ok then
          if m.perCharacter then freeChar = freeChar - 1 else freeAcct = freeAcct - 1 end
          if index > 0 then
            DeleteMacro(index)
            moved[#moved + 1] = m.name
          end
        end
      else
        ok, err = pcall(EditMacro, index, m.name, IconFor(m), body)
      end
      if ok then
        -- Keys bound to the old "AC X" name now point at "X".
        if legacy then rebound = Rebind("AC " .. m.name, m.name) or rebound end
        done[#done + 1] = m.name
        Record(m.name, body)
      else
        skipped[#skipped + 1] = m.name .. " (" .. tostring(err) .. ")"
      end
    end
  end
  if rebound then SaveBinds() end
  if #done > 0 then ns.Print("installed " .. table.concat(done, ", ") .. ". Use Pick Up to put one on a bar.") end
  if #moved > 0 then
    ns.Print("moved " .. table.concat(moved, ", ") .. " from General to Character macros; other characters no longer have the General copy.")
  end
  if #skipped > 0 then ns.Print("skipped " .. table.concat(skipped, "; ")) end
  if #done == 0 and #skipped == 0 then ns.Print("check some macros first.") end
end

-- Clears every key bound to the macro, so no key is left pointing at nothing.
local function Unbind(index)
  local name = GetMacroInfo and GetMacroInfo(index)
  if not (name and GetBindingKey and SetBinding) then return false end
  local keys = { GetBindingKey("MACRO " .. name) }
  for _, key in ipairs(keys) do SetBinding(key) end
  return #keys > 0
end

-- Deletes only macros Agentcraft wrote; one of yours with the same name stays.
function L.Remove(list)
  if InCombatLockdown() then return ns.Print("can't change macros in combat.") end
  local removed, kept, unbound = {}, {}, false
  for _, m in ipairs(list) do
    local index, legacy = IndexOf(m.name)
    if index > 0 then
      if IsOurs(m, index, legacy, L.Resolve(m)) then
        unbound = Unbind(index) or unbound
        DeleteMacro(index)
        removed[#removed + 1] = m.name
      else
        kept[#kept + 1] = m.name
      end
    end
  end
  if unbound then SaveBinds() end
  if #kept > 0 then ns.Print("kept " .. table.concat(kept, ", ") .. ": the name is in use by your own macro; delete it in /macro.") end
  if #removed > 0 then ns.Print("removed " .. table.concat(removed, ", "))
  elseif #kept == 0 then ns.Print("none of those are installed.") end
end

-- Puts the installed macro on the cursor so it can be dropped on a bar.
function L.PickUp(m)
  if InCombatLockdown() then return ns.Print("can't pick up macros in combat.") end
  local index = IndexOf(m.name)
  if index == 0 then return ns.Print(m.name .. " isn't installed yet.") end
  PickupMacro(index)
end

-- Generated item macros -------------------------------------------------------
-- Rewrites the text of each installed item macro (m.generated) whose best
-- item changed. Only a macro Agentcraft wrote (a text it recorded writing,
-- or an older library text) in this character's macro tab is edited: a copy
-- still in the General tab waits for Update on the Macros page, and your own
-- macro of the same name is never touched. Never creates or deletes a macro,
-- so the 18 character slots are spent only by Install.
-- Returns the names it rewrote, or nil and "combat".
function L.UpdateGenerated()
  if InCombatLockdown() then return nil, "combat" end
  local done = {}
  for _, m in ipairs(L.macros) do
    if m.generated then
      local index, legacy = IndexOf(m.name)
      if index > 0 and not legacy and not InWrongTab(m, index) and IsOurs(m, index, false, nil) then
        local body = L.Resolve(m)
        if body and Trim(GetMacroBody(index)) ~= Trim(body) then
          if pcall(EditMacro, index, m.name, IconFor(m), body) then
            Record(m.name, body)
            done[#done + 1] = m.name
          end
        end
      end
    end
  end
  return done
end
