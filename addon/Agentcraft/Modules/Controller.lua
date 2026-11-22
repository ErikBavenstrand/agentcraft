-- Controller: fills WoW Forever's native Gamepad UI action bars and binds the
-- Steam Deck back buttons, from a per-class layout that leaves room to grow.
--
-- How the Gamepad UI works (Blizzard_GamepadActionBars, forever branch):
--   * 3 pages (LB+RB with D-pad left/right). Each page has 4 bars:
--       Top = nothing held, Left = LT held, Right = RT held, Bottom = LT+RT.
--   * Each bar is a D-pad diamond plus a face-button diamond (8 buttons).
--     The Top bar's face buttons are fixed (interact, inspect, back, jump).
--   * Actions live in action slots from C_GamepadUI.GetFirstGamepadActionStorageSlotIndex()
--     (181 on the live client); GamepadActionBarBindingUtil maps page + button to a slot.
--   * Only spell flyouts (like Aspects) open a radial: 8 entries, picked with the right stick.
--   * Pet commands (LB+LT) and pet abilities (RB+RT) are radials Blizzard fills itself.
--   * Newly learned spells are dropped into empty slots (RT+face first). Planned
--     slots for spells you haven't learned stay empty; Apply again after
--     training to move new spells to their planned button.
-- Back buttons: Steam Input maps L4, L5, R4, R5 to F13-F16; this module binds
-- those keys (and LT+key, since LT emulates Shift) to spells, macros and
-- items. They are plain key bindings, so they bind without the Gamepad UI.
-- Apply never creates macros. It first deletes retired Agentcraft macros you
-- never edited and unbinds their keys. Petauto buttons use the library's
-- "Auto <ability>" macros only once you've installed them.
-- A back button with no home in the layout is unbound by Apply.
-- Plan items that can't be placed carry `missing` (a label) and `reason`:
-- "learn", "carry", "equip", "install", "nomacro", "nohome" or "notpaddle".
-- Items: only the Hearthstone, the Cozy Sleeping Bag (set 2, no trigger +
-- D-pad left) and your equipped on-use trinkets are ever placed (owner
-- rules, 2026-11-22); no food, drink, potions or gadgets.
local _, ns = ...
local UI = ns.UI
local M = ns.RegisterModule("Controller", {
  title = "Controller",
  order = 30,
  description = "Fills the Gamepad UI bars and Steam Deck back buttons.",
})

local BAR = { none = 0, LT = 1, RT = 2, ["LT+RT"] = 3 }
local BAR_TITLE = { [0] = "No trigger", "Hold LT", "Hold RT", "Hold LT + RT" }
local BUTTON = { Left = 1, Up = 2, Right = 3, Down = 4, X = 5, Y = 6, B = 7, A = 8 }
local BUTTON_NAME = { "D-pad left", "D-pad up", "D-pad right", "D-pad down",
  "X / Square", "Y / Triangle", "B / Circle", "A / Cross" }

-- "RT A" -> page-unit slot ID (1-32).
local function SlotID(key)
  local layer, button = key:match("^(%S+) (%S+)$")
  return BAR[layer] * 8 + BUTTON[button]
end

-- Entry forms:
--   { "Feign Death", "Disengage" }   first spell you know
--   { flyout = 253 }                 spellbook flyout (a radial), by flyout ID or name
--   { macro = "Fish", "Fishing" }    an installed library macro (never installed for you), else the spell
--   { macro = "Bait" }               macro only: the installed macro, else the home waits
--   { utility = <ActionBars.utility index> }  that entry's item: an equipped on-use
--                                    trinket (7, 8) or the Hearthstone (12)
--   { item = "Hearthstone" }         that bag item, if ActionBars.BAG_ITEMS allows it
--   { racial = true }                your race's active racial
local RACIALS = { "War Stomp", "Berserking", "Blood Fury", "Will of the Forsaken", "Stoneform",
  "Shadowmeld", "Escape Artist", "Perception" }

local PADDLE_KEY = { L4 = "F13", L5 = "F14", R4 = "F15", R5 = "F16" }
local PADDLE_ORDER = { "L4", "L5", "R4", "R5", "LT+L4", "LT+L5", "LT+R4", "LT+R5" }
local function PaddleBinding(p)
  local lt, base = p:match("^(LT%+)(.+)$")
  return (lt and "SHIFT-" or "") .. PADDLE_KEY[base or p]
end

-- Resolving entries -------------------------------------------------------------

local function Util() return GamepadActionBarBindingUtil end
local KnownID -- defined below
local LibraryIcon -- defined below

-- The class layout lives in Layout.lua, shared with the keyboard bars.
local function Layout()
  local _, class = UnitClass("player")
  -- Not `ns.Layout and ControllerPages(class)`: `and` keeps only the first return.
  local pages, paddles
  if ns.Layout then pages, paddles = ns.Layout.ControllerPages(class) end
  if not pages then return nil, class end
  return { pages = pages, paddles = paddles }, class
end

-- Known spells by name, profession spells included, one ID per name: the
-- one the spellbook lists (WoW Forever knows Cooking as 3102 and 1240956).
local function Known()
  local AB = ns.modules.actionbars
  if AB and AB.SideSpellIDs then return AB.SideSpellIDs() end
  return AB and AB.KnownSpellIDs and AB.KnownSpellIDs() or {}
end

-- Spellbook index of a flyout, by flyout ID or name.
local function FindFlyout(want)
  if not (C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines) then return end
  local bank = Enum.SpellBookSpellBank.Player
  for tab = 1, C_SpellBook.GetNumSpellBookSkillLines() do
    local line = C_SpellBook.GetSpellBookSkillLineInfo(tab)
    if line then
      for i = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
        local item = C_SpellBook.GetSpellBookItemInfo(i, bank)
        if item and item.itemType == Enum.SpellBookItemType.Flyout
          and (item.actionID == want or item.name == want) then
          return i, item.actionID, item.name, item.iconID
        end
      end
    end
  end
end

-- Every pet ability that can autocast: the pet bar first (in its order), then
-- the rest of the pet's spellbook. Remembered per character, so the toggle
-- buttons stay while your pet is dismissed or dead.
local function PetAutocast()
  local list, seen = {}, {}
  local function Add(name, icon)
    if name and not seen[name] then seen[name] = true; list[#list + 1] = { name = name, icon = icon } end
  end
  if UnitExists("pet") then
    if GetPetActionInfo then
      for i = 1, NUM_PET_ACTION_SLOTS or 10 do
        local ok, name, texture, isToken, _, allowed = pcall(GetPetActionInfo, i)
        if ok and not isToken and allowed then Add(name, texture) end
      end
    end
    local bank = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet
    local ok, count = pcall(function() return C_SpellBook.HasPetSpells() end)
    if bank and ok and count then
      for i = 1, count do
        local okInfo, item = pcall(C_SpellBook.GetSpellBookItemInfo, i, bank)
        if okInfo and item and item.spellID and not item.isPassive then
          local okAuto, allowed = pcall(C_SpellBook.GetSpellBookItemAutoCast, i, bank)
          if okAuto and allowed then Add(item.name, item.iconID) end
        end
      end
    end
    if #list > 0 then M.charDB.petAuto = list end
  end
  return #list > 0 and list or (M.charDB.petAuto or {})
end

-- The library's autocast toggle for a pet ability (Macros/Data/Hunter.lua,
-- petAbility). Used only once you've installed it on the Macros page.
local function PetToggleItem(a)
  local lib = ns.MacroLibrary
  for _, m in ipairs(lib and lib.macros or {}) do
    if m.petAbility == a.name then
      local i = GetMacroIndexByName(m.name)
      if i and i > 0 then return { kind = "macro", name = m.name, icon = a.icon } end
      return { missing = m.name, macro = m.name, reason = "install", icon = a.icon }
    end
  end
  return { missing = a.name, reason = "nomacro", icon = a.icon }
end

-- Index of an installed macro. Applying a layout never installs library
-- macros: which macros you use is your choice on the Macros page.
local function MacroIndex(name)
  local i = GetMacroIndexByName(name)
  if i and i > 0 then return i end
end

-- Spell ID for a name you know. The class spellbook map misses profession
-- spells (Smelting, Cooking) and renamed ones ("Call Pet" shows as
-- "Call <pet name>"), so fall back to the game's own lookup.
function KnownID(name, known)
  if known[name] then return known[name] end
  local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(name)
  local id = info and info.spellID
  if id and ((IsPlayerSpell and IsPlayerSpell(id)) or (IsSpellKnown and IsSpellKnown(id))) then return id end
end

-- Returns a plan item: { kind, id, name, icon } or { missing = "label" }.
function M.Resolve(entry, known, used)
  if entry.flyout then
    local index, id, name, icon = FindFlyout(entry.flyout)
    if index then return { kind = "flyout", index = index, id = id, name = name .. " (radial)", icon = icon } end
  end
  if entry.racial then
    for _, n in ipairs(RACIALS) do
      local id = KnownID(n, known)
      if id then return { kind = "spell", id = id, name = n } end
    end
    return { missing = "racial", reason = "learn" }
  end
  if entry.macro then
    -- { macro = "Arcane", "Arcane Shot" }: the macro version of a spell's home.
    -- It needs the spell; until you know it, the home stays empty like a plain
    -- spell. The macro is used only if you installed it; otherwise the home
    -- gets the plain spell (the first spell listed, or the first one covered).
    local needs = entry[1]
    if needs and not KnownID(needs, known) then
      -- { macro = "FD", "Feign Death", "Disengage" }: until you know the
      -- macro's spell, the next spell you know holds the home.
      for i = 2, #entry do
        local id = KnownID(entry[i], known)
        if id then return { kind = "spell", id = id, name = entry[i] } end
      end
      return { missing = needs, reason = "learn" }
    end
    if MacroIndex(entry.macro) then return { kind = "macro", name = entry.macro, installed = true, spell = needs } end
    local plain = needs or (entry.covers and entry.covers[1])
    local id = plain and KnownID(plain, known)
    if id then return { kind = "spell", id = id, name = plain } end
    -- A macro-only home ({ macro = "Bait" }) waits, showing the macro's icon.
    return { missing = entry.macro .. " macro", macro = entry.macro, reason = "install", icon = LibraryIcon(entry.macro) }
  end
  if entry.item then
    -- { item = "Hearthstone" }, { item = "Cozy Sleeping Bag" }: that item,
    -- wherever it sits in your bags (only names in ActionBars.BAG_ITEMS).
    local AB = ns.modules.actionbars
    local id = AB and AB.ResolveUtilityItem({ entry.item })
    if id then return { kind = "item", id = id, name = entry.item } end
    return { missing = entry.item, reason = "carry" }
  end
  if entry.utility then
    local AB = ns.modules.actionbars
    local spec = AB and AB.utility and AB.utility[entry.utility]
    local id = spec and AB.ResolveUtilityItem(spec)
    if id then return { kind = "item", id = id, name = C_Item.GetItemNameByID(id) or ("item " .. id) } end
    local label = spec and AB.UtilityLabel and AB.UtilityLabel(spec) or tostring(spec)
    return { missing = label, reason = type(spec) == "string" and "equip" or "carry" }
  end
  for _, n in ipairs(entry) do
    local id = KnownID(n, known)
    if id and not (used and used[id]) then return { kind = "spell", id = id, name = n } end
  end
  return { missing = entry[#entry] or "?", reason = "learn" }
end

-- Fill order: rotation layer first, most comfortable buttons first.
local LAYER_RANK = { RT = 1, LT = 2, none = 3, ["LT+RT"] = 4 }
local BUTTON_RANK = { A = 1, X = 2, B = 3, Y = 4, Up = 5, Down = 6, Left = 7, Right = 8 }
local function PriorityKeys(def)
  local keys = {}
  for key in pairs(def) do if key ~= "title" then keys[#keys + 1] = key end end
  table.sort(keys, function(a, b)
    local la, ba = a:match("^(%S+) (%S+)$")
    local lb, bb = b:match("^(%S+) (%S+)$")
    if LAYER_RANK[la] ~= LAYER_RANK[lb] then return LAYER_RANK[la] < LAYER_RANK[lb] end
    return BUTTON_RANK[ba] < BUTTON_RANK[bb]
  end)
  return keys
end

-- The question-mark macro icon (file ID 134400), by ID or path.
local function IsQuestion(tex)
  return tex == nil or tex == 134400 or (type(tex) == "string" and tex:lower():find("inv_misc_questionmark", 1, true) ~= nil)
end

-- A library macro's own display icon (its spell or item), by macro name.
-- The spell a library macro is built around (its icon spell, else its
-- first required spell), for "Arcane · Arcane Shot" labels; nil if none.
local function LibrarySpell(name)
  local L = ns.MacroLibrary
  for _, m in ipairs(L and L.macros or {}) do
    if m.name == name then
      local icon = type(m.icon) == "string" and m.icon ~= "" and m.icon or nil
      if icon and UI.SpellIcon(icon) then return icon end
      return m.requires and m.requires[1] or icon
    end
  end
end

function LibraryIcon(name)
  local L = ns.MacroLibrary
  for _, m in ipairs(L and L.macros or {}) do
    if m.name == name then
      if m.icon then
        local tex = UI.SpellIcon(m.icon)
        if tex then return tex end
        if C_Item and C_Item.GetItemInfoInstant then
          local itemTex = select(5, C_Item.GetItemInfoInstant(m.icon))
          if itemTex then return itemTex end
        end
      end
      if m.iconFile and not IsQuestion(m.iconFile) then return "Interface\\Icons\\" .. m.iconFile end
      return nil
    end
  end
end

local function Icon(p)
  if not p or p.missing then return nil end
  if p.icon then return p.icon end
  -- One value each (parentheses): extra returns would reach Slot:SetIcon's
  -- `faded` argument and fade a placed spell like a missing one.
  if p.kind == "spell" then return (UI.SpellIcon(p.id)) end
  if p.kind == "item" then return (UI.ItemIcon(p.id)) end
  if p.kind == "macro" then
    local i = GetMacroIndexByName(p.name)
    local tex = (i and i > 0) and (select(2, GetMacroInfo(i))) or nil
    -- Library macros are installed with the question mark plus #showtooltip;
    -- show the spell they cast instead, as the Macros page does.
    if IsQuestion(tex) and i and i > 0 and _G.GetMacroSpell then
      local ok, sid = pcall(_G.GetMacroSpell, i)
      if ok and sid then tex = UI.SpellIcon(sid) or tex end
    end
    if IsQuestion(tex) then tex = LibraryIcon(p.name) or (p.spell and UI.SpellIcon(p.spell)) or tex end
    return tex or "Interface\\Icons\\INV_Misc_Note_01"
  end
end

-- Storage slot for a page and page-unit slot ID, or nil.
local function Storage(page, slotID)
  local U = Util()
  if not U then return end
  local ok, index = pcall(U.GetGamepadStorageSlotIndexFromPageAndPageUnitSlotID, page, slotID)
  return ok and index or nil
end

-- Spells never offered by the catch-all: always-on or handled by the UI.
local OVERFLOW_SKIP = { ["Attack"] = true, ["Auto Attack"] = true, ["Auto Shot"] = true, ["Shoot"] = true, ["Throw"] = true, ["Cultivation"] = true }

-- Known spells with no controller home (and not inside a placed flyout),
-- alphabetically, for the { overflow = true } buttons. A spell counts as
-- placed by ID and by name, so a profession the client knows under two IDs
-- (Cooking 3102 and 1240956) never gets a second button.
local function OverflowSpells(pages, known)
  local placed, placedName = {}, {}
  for _, def in ipairs(pages) do
    -- Same order and per-page `used` as M.Plan, so both pick the same
    -- alternative from a list home.
    local used = {}
    for _, key in ipairs(PriorityKeys(def)) do
      local entry = def[key]
      if not entry.overflow and not entry.petauto then
        local item = M.Resolve(entry, known, used)
        if item.kind == "spell" then placed[item.id] = true; used[item.id] = true; placedName[item.name] = true end
        if item.kind == "flyout" and GetFlyoutInfo then
          local _, _, numSlots = GetFlyoutInfo(item.id)
          for s = 1, numSlots or 0 do
            -- By ID and by name: `known` holds the highest rank's ID, which
            -- may differ from the ID the flyout reports.
            local spellID, overrideID, _, spellName = GetFlyoutSlotInfo(item.id, s)
            if spellID then placed[spellID] = true end
            if overrideID then placed[overrideID] = true end
            if spellName then placedName[spellName] = true end
            if spellName and known[spellName] then placed[known[spellName]] = true end
          end
        end
        -- { "Better", "Lower rank", upgrade = true }: the lower one needs no home.
        if entry.upgrade then
          for _, n in ipairs(entry) do
            local id = KnownID(n, known)
            if id then placed[id] = true; placedName[n] = true end
          end
        end
        -- A macro version counts as placing its spell, and covers = { ... }
        -- lists other spells a macro already casts.
        if item.kind == "macro" then
          local names = { entry[1] }
          for _, n in ipairs(entry.covers or {}) do names[#names + 1] = n end
          for _, n in ipairs(names) do
            local id = KnownID(n, known)
            if id then placed[id] = true; placedName[n] = true end
          end
        end
      end
    end
  end
  local list = {}
  for name, id in pairs(known) do
    if not placed[id] and not placedName[name] and not OVERFLOW_SKIP[name] then list[#list + 1] = { name = name, id = id } end
  end
  table.sort(list, function(a, b) return a.name < b.name end)
  return list
end

-- Full plan: plan[page][slotID] = { key, entry, item, slot, state }.
function M.Plan()
  local layout, class = Layout()
  if not layout then return nil, class end
  local known = Known()
  local plan = { changes = 0, missing = 0, missingNames = {} }
  local overflow, nextOverflow = OverflowSpells(layout.pages, known), 1
  local petAuto, nextPet = PetAutocast(), 1
  for page, def in ipairs(layout.pages) do
    plan[page] = { title = def.title }
    local used = {}
    for _, key in ipairs(PriorityKeys(def)) do
      local entry = def[key]
      local item
      if entry.overflow then
        local spell = overflow[nextOverflow]
        if spell then
          nextOverflow = nextOverflow + 1
          item = { kind = "spell", id = spell.id, name = spell.name }
        end
      elseif entry.petauto then
        local a = petAuto[nextPet]
        if a then nextPet = nextPet + 1; item = PetToggleItem(a) end
      else
        item = M.Resolve(entry, known, used)
      end
      if item then
        local slotID = SlotID(key)
        if item.kind == "spell" then used[item.id] = true end
        local slot = Storage(page, slotID)
        local state = "missing"
        if not item.missing and not slot then
          -- Resolved, but there are no bars to put it on (Gamepad UI off).
          state = "nobars"
        elseif not item.missing then
          local t, id = GetActionInfo(slot)
          local same = (item.kind == "spell" and t == "spell" and id == item.id)
            or (item.kind == "item" and t == "item" and id == item.id)
            or (item.kind == "flyout" and t == "flyout" and id == item.id)
            or (item.kind == "macro" and t == "macro" and GetActionText(slot) == item.name)
          state = same and "same" or "new"
          if state == "new" then plan.changes = plan.changes + 1 end
        else
          plan.missing = plan.missing + 1
          plan.missingNames[#plan.missingNames + 1] = item.missing
          -- Apply clears whatever sits in a home that waits for its spell.
          if item.missing and slot and HasAction(slot) then
            state = "clear"
            plan.changes = plan.changes + 1
          end
        end
        plan[page][slotID] = { key = key, entry = entry, item = item, slot = slot, state = state }
      end
    end
    -- Apply also clears slots outside the layout that hold something.
    for slotID = 1, 32 do
      local slot = not plan[page][slotID] and Storage(page, slotID)
      if slot and HasAction(slot) then plan.changes = plan.changes + 1 end
    end
  end
  plan.unplaced = #overflow - (nextOverflow - 1)
  plan.paddles = {}
  local paddleUsed = {}
  for _, p in ipairs(PADDLE_ORDER) do
    local entry = layout.paddles and layout.paddles[p]
    do
      local item
      if not entry then
        item = { missing = "no home", reason = "nohome" }
      elseif entry.petauto or entry.overflow then
        item = { missing = "not on back buttons", reason = "notpaddle" }
      else
        item = M.Resolve(entry, known, paddleUsed)
        -- A key binding can't open a radial: back buttons take spells, items and macros.
        if item.kind == "flyout" then item = { missing = item.name, reason = "notpaddle" } end
      end
      if item.kind == "spell" then paddleUsed[item.id] = true end
      local binding = PaddleBinding(p)
      local current = GetBindingAction(binding) or ""
      local want = ""
      if not item.missing then
        want = (item.kind == "macro" and "MACRO " or item.kind == "item" and "ITEM " or "SPELL ") .. item.name
      end
      local state
      if item.missing then
        -- Apply unbinds the key (a stale MACRO binding included).
        state = current ~= "" and "clear" or "missing"
      else
        state = current == want and "same" or "new"
      end
      plan.paddles[p] = { item = item, binding = binding, current = current, state = state }
      if state == "new" or state == "clear" then plan.changes = plan.changes + 1 end
    end
  end
  return plan, class
end

-- Placement ------------------------------------------------------------------------

local function Pickup(item)
  ClearCursor()
  if item.kind == "spell" then
    if C_Spell and C_Spell.PickupSpell then C_Spell.PickupSpell(item.id) else PickupSpell(item.id) end
  elseif item.kind == "item" then
    if C_Item and C_Item.PickupItem then C_Item.PickupItem(item.id) else PickupItem(item.id) end
  elseif item.kind == "flyout" then
    C_SpellBook.PickupSpellBookItem(item.index, Enum.SpellBookSpellBank.Player)
  elseif item.kind == "macro" then
    local i = MacroIndex(item.name)
    if i then PickupMacro(i) end
  end
end

local function Place(slot, item)
  Pickup(item)
  if GetCursorInfo() then PlaceAction(slot) end
  ClearCursor()
end

-- Whether an action slot already holds the resolved item.
local function Same(slot, item)
  if not item or item.missing then return false end
  local t, id = GetActionInfo(slot)
  return (item.kind == "spell" and t == "spell" and id == item.id)
    or (item.kind == "item" and t == "item" and id == item.id)
    or (item.kind == "flyout" and t == "flyout" and id == item.id)
    or (item.kind == "macro" and t == "macro" and GetActionText(slot) == item.name)
end

-- Shared with the keyboard bars (ActionBars), which use the same layout entries.
M.Place, M.Same, M.Icon, M.Known = Place, Same, Icon, Known

local function ManagedSlots(plan)
  local slots = {}
  for page = 1, #plan do
    for slotID = 1, 32 do
      local s = Storage(page, slotID)
      if s then slots[#slots + 1] = s end
    end
  end
  return slots
end

-- Deletes retired Agentcraft macros you never edited, and unbinds keys bound
-- to them. A name the library still offers is left alone: the Macros page
-- shows it as "Update" instead.
local function DeleteRetired()
  local lib = ns.MacroLibrary
  if not (lib and lib.RetiredDeletable) then return end
  local function Delete(name, i)
    if GetBindingKey then
      for _, k in ipairs({ GetBindingKey("MACRO " .. name) }) do SetBinding(k) end
    end
    DeleteMacro(i)
  end
  -- RetiredDeletable skips names the library still offers, and texts players
  -- often write themselves unless Agentcraft recorded writing them.
  local names = {}
  for name in pairs(lib.retired or {}) do names[name] = true end
  for name in pairs(lib.retiredShapes or {}) do names[name] = true end
  for name in pairs(names) do
    local i = GetMacroIndexByName(name)
    if i and i > 0 and lib.RetiredDeletable(name, GetMacroBody(i) or "") then Delete(name, i) end
  end
end

function M.Apply()
  if InCombatLockdown() then return ns.Print("can't change controller bars in combat.") end
  local layout, layoutClass = Layout()
  if not layout then return ns.Print("no controller layout for " .. tostring(layoutClass) .. " yet.") end
  -- Before planning, so a home whose macro goes gets its plain spell now.
  DeleteRetired()
  local plan = M.Plan()
  -- Back buttons are plain key bindings and work without the Gamepad UI.
  local bars = Util() ~= nil

  -- Save the current layout once per apply, for undo.
  -- `managed` lists the bar slots, so Undo can restore them even if the
  -- Gamepad UI's slot map is gone by then.
  local backup = { slots = {}, binds = {}, noBars = not bars or nil }
  if bars then
    backup.managed = ManagedSlots(plan)
    for _, slot in ipairs(backup.managed) do
      local t, id = GetActionInfo(slot)
      if t then backup.slots[slot] = { t, id, t == "macro" and GetActionText(slot) or nil } end
    end
  end
  for _, p in pairs(plan.paddles) do backup.binds[p.binding] = GetBindingAction(p.binding) end
  M.charDB.backup = backup

  ClearCursor()
  local placed = 0
  for page = 1, bars and #plan or 0 do
    for slotID = 1, 32 do
      local s = Storage(page, slotID)
      local want = plan[page][slotID]
      if s then
        if want and not want.item.missing then
          if want.state ~= "same" then Place(s, want.item); placed = placed + 1 end
        elseif HasAction(s) then
          -- Planned for a spell you don't have yet, or not in the layout:
          -- clear it so the layout stays predictable.
          PickupAction(s); ClearCursor()
        end
      end
    end
  end

  for _, p in pairs(plan.paddles) do
    SetBinding(p.binding)
    if not p.item.missing then
      if p.item.kind == "macro" then MacroIndex(p.item.name); SetBindingMacro(p.binding, p.item.name)
      elseif p.item.kind == "item" then SetBinding(p.binding, "ITEM " .. p.item.name)
      else SetBindingSpell(p.binding, p.item.name) end
    end
  end
  SaveBindings(GetCurrentBindingSet())
  if not bars then
    return ns.Print("back buttons bound; bars skipped: turn on the Gamepad UI first (Options > Gameplay > Gamepad).")
  end
  ns.Print(string.format("controller layout applied (%d changes). /ac controller undo to go back.", placed))
  if plan.missing > 0 then ns.Print(plan.missing .. " planned buttons wait for spells or items you don't have yet, or macros you haven't installed.") end
end

-- Puts a saved action back on the cursor; false if it can't be restored.
local function PickupSaved(t, id, text)
  if t == "spell" then Pickup({ kind = "spell", id = id })
  elseif t == "item" then Pickup({ kind = "item", id = id })
  elseif t == "macro" then local i = MacroIndex(text or "") if i then PickupMacro(i) end
  elseif t == "flyout" then local index = FindFlyout(id) if index then Pickup({ kind = "flyout", index = index }) end
  elseif t == "equipmentset" and C_EquipmentSet and C_EquipmentSet.PickupEquipmentSet and C_EquipmentSet.GetEquipmentSetID then
    local setID = C_EquipmentSet.GetEquipmentSetID(id)
    if setID then C_EquipmentSet.PickupEquipmentSet(setID) end
  elseif t == "summonmount" and C_MountJournal and C_MountJournal.Pickup and C_MountJournal.GetDisplayedMountID then
    for i = 1, C_MountJournal.GetNumDisplayedMounts and C_MountJournal.GetNumDisplayedMounts() or 0 do
      if C_MountJournal.GetDisplayedMountID(i) == id then C_MountJournal.Pickup(i); break end
    end
  elseif t == "summonpet" and C_PetJournal and C_PetJournal.PickupPet then
    pcall(C_PetJournal.PickupPet, id)
  end
  return GetCursorInfo() ~= nil
end

function M.Undo()
  if InCombatLockdown() then return ns.Print("can't change controller bars in combat.") end
  local backup = M.charDB.backup
  if not backup then return ns.Print("nothing to undo.") end
  -- An apply without the Gamepad UI saved no slots: leave the bars alone.
  local slots = backup.managed
  if not backup.noBars and not slots then
    -- A backup from before `managed` existed: the slot list needs the
    -- Gamepad UI. Without it, keep the backup rather than lose the bars.
    if not Util() then
      return ns.Print("turn on the Gamepad UI to undo the controller bars; nothing was changed.")
    end
    slots = ManagedSlots(M.Plan() or { 1, 2, 3 })
  end
  ClearCursor()
  local lost = {}
  if not backup.noBars then
    for _, slot in ipairs(slots) do
      if HasAction(slot) then PickupAction(slot); ClearCursor() end
      local saved = backup.slots[slot]
      if saved then
        local t, id, text = saved[1], saved[2], saved[3]
        if PickupSaved(t, id, text) then PlaceAction(slot) else lost[#lost + 1] = text or tostring(t) end
        ClearCursor()
      end
    end
  end
  for key, action in pairs(backup.binds) do
    SetBinding(key)
    -- Never re-bind a key to a macro that's gone (Apply may have retired it).
    local macro = action and action:match("^MACRO (.+)$")
    if macro and not MacroIndex(macro) then lost[#lost + 1] = key .. " (macro " .. macro .. ")"
    elseif action and action ~= "" then SetBinding(key, action) end
  end
  SaveBindings(GetCurrentBindingSet())
  M.charDB.backup = nil
  ns.Print("controller layout restored.")
  if #lost > 0 then ns.Print("couldn't put back: " .. table.concat(lost, ", ") .. ".") end
end


-- Window page ----------------------------------------------------------------------
-- The native Gamepad action bar HUD (dev/ui-spec-v2.md §9.3), drawn with
-- Blizzard's own art: four bars in a cross (Top: no trigger, Left: hold LT,
-- Right: hold RT, Bottom: hold LT + RT), each a D-pad diamond of square
-- slots and a face diamond of round slots, a glyph on every button
-- (Blizzard_GamepadActionBars, MainActionBarFrame.xml / ActionBarButton.xml:
-- https://github.com/Gethe/wow-ui-source/tree/forever/Interface/AddOns/Blizzard_GamepadActionBars).
-- The bars sit on three rows so no two bars interleave. The focused or held
-- bar shows its section glow (never a scale, slide or fade: the packed rows
-- leave no room to grow) and its header names the focused button;
-- every slot also carries its name in a caption under it (readable at a
-- glance on the Deck);
-- the Inspector's BarCard names all 8 buttons of that bar and the List view
-- names all 32. Sets 1-3 are the view strip (Next set cycles them). The back
-- buttons flank the bottom bar like the Deck's paddles and stay free (owner
-- rule): they are drawn, never focusable.

M.BAR_TITLE, M.BUTTON_NAME = BAR_TITLE, BUTTON_NAME

-- No-trigger face buttons the Gamepad UI keeps (slot IDs 5-8 = X Y B A).
-- [VERIFY in game: the Gamepad UI's own bindings for these four]
local FIXED = { [5] = "Interact", [6] = "Inspect", [7] = "Back", [8] = "Jump" }
local FIXED_TITLE = { [5] = "Interact", [6] = "Inspect", [7] = "Cancel / Back", [8] = "Jump" }
-- The native icons on those buttons (MainActionBarFrame.lua).
-- Inspect has its own cursor art (Interface\Cursor\Inspect, in the client and
-- in github.com/Gethe/wow-ui-textures/tree/live/Cursor), so X and Y differ.
local FIXED_ICON = { [5] = "Interface\\Cursor\\Interact", [6] = "Interface\\Cursor\\Inspect",
  [7] = "atlas:128-redbutton-exit", [8] = "atlas:gamepad-ability-icon-jump" }

local REASON = {
  learn = "Not learned yet. Added when you train it and apply again.",
  carry = "None in your bags. Added when you carry one and apply again.",
  equip = "No trinket with a Use effect equipped. Added when you equip one and apply again.",
  install = "Macro not installed. Install it on the Macros page, then apply again.",
  nomacro = "No autocast macro for this ability in the Macro Library yet.",
  notpaddle = "Back buttons are plain key bindings: they can't open a radial or toggle autocast.",
}
local function ReasonText(item) return REASON[item.reason] or REASON.learn end
M.ReasonText = ReasonText

local WAITING = { learn = "Waiting · learn it first", carry = "Waiting · carry one",
  equip = "Waiting · equip an on-use trinket", install = "Waiting · install its macro",
  nomacro = "Waiting · no autocast macro yet", notpaddle = "Can't go on a back button" }
local KIND = { spell = "Spell", item = "Item", macro = "Macro", flyout = "Radial" }

-- "Waiting · install Bait on the Macros page": a macro home whose macro you
-- haven't installed. The Keyboard page uses the same words.
function M.InstallText(name) return "Waiting · install " .. tostring(name) .. " on the Macros page" end

local function TabLabel(i, title) return i .. " · " .. (title or "Empty") end

local function LayoutTitles()
  local _, class = UnitClass("player")
  local pages = ns.Layout and ns.Layout.ControllerPages(class)
  local titles = {}
  for i = 1, 3 do titles[i] = pages and pages[i] and pages[i].title or nil end
  return titles
end

local function Count(n, one, many)
  return string.format(n == 1 and one or many, n)
end

-- Button names in the active controller's style: "LT", "A" on Letters,
-- "L2", "Cross" on Shapes (PlayStation), so text matches the glyphs.
local SHAPE_NAMES = { PADLTRIGGER = "L2", PADRTRIGGER = "R2", PADLSHOULDER = "L1", PADRSHOULDER = "R1",
  PAD1 = "Cross", PAD2 = "Circle", PAD3 = "Square", PAD4 = "Triangle" }
local function Shapes()
  if UI.LabelStyle and UI.LabelStyle() == "Shapes" then return true end
  local a = UI.GlyphAtlas and UI.GlyphAtlas("PAD1")
  return type(a) == "string" and a:find("%-ps%-") ~= nil
end
local function PadName(key)
  return (Shapes() and SHAPE_NAMES[key]) or UI.PAD_NAMES[key] or tostring(key)
end
M.PadName = PadName
-- Full bar title for text without glyphs: "Hold LT", "Hold L2 + R2".
local function BarTitle(layer)
  if layer == 0 then return BAR_TITLE[0] end
  local names = {}
  for i, k in ipairs(UI.PAD_LAYER_TRIGGERS[layer] or {}) do names[i] = PadName(k) end
  return "Hold " .. table.concat(names, " + ")
end
-- Short title next to the trigger glyphs (the glyph already names the trigger).
local GLYPH_TITLE = { [0] = "No trigger", "Hold", "Hold", "Hold both" }

-- "RT + A", "LT + RT + Up" (style-aware).
local function Chord(layer, name)
  local parts = {}
  for _, k in ipairs(UI.PAD_LAYER_TRIGGERS[layer] or {}) do parts[#parts + 1] = PadName(k) end
  local key = UI.PAD_OFFSETS[name] and UI.PAD_OFFSETS[name][4]
  parts[#parts + 1] = (key and BUTTON[name] >= 5) and PadName(key) or name
  return table.concat(parts, " + ")
end
-- The same chord as inline button glyphs ([LT] + [D-pad Left]), as the
-- HUD, Inspector and prompt bar show it; each part falls back to its text.
local REVIEW_GLYPH = 28  -- the glyph atlases carry wide transparent margins: 20 drew a 10 px button in game
local function ChordGlyphs(layer, name)
  if not UI.GlyphMarkup then return Chord(layer, name) end
  local function G(k, text)
    local ok, m = pcall(UI.GlyphMarkup, k, REVIEW_GLYPH)
    -- GlyphMarkup returns "[A]" without the atlas: use the readable name then.
    if ok and type(m) == "string" and m:find("|A", 1, true) then return m end
    return text
  end
  local parts = {}
  for _, k in ipairs(UI.PAD_LAYER_TRIGGERS[layer] or {}) do parts[#parts + 1] = G(k, PadName(k)) end
  local key = UI.PAD_OFFSETS[name] and UI.PAD_OFFSETS[name][4]
  local text = (key and BUTTON[name] >= 5) and PadName(key) or name
  parts[#parts + 1] = key and G(key, text) or text
  return table.concat(parts, " + ")
end
-- "LT+L4" -> "LT + L4" (or "L2 + L4" on Shapes).
local function PaddleLabel(key)
  local lt, base = key:match("^(LT%+)(.+)$")
  return lt and (PadName("PADLTRIGGER") .. " + " .. base) or key
end
-- Page-unit slot ID from bar layer (0-3) and button name ("Up", "A", ...).
local function SlotOf(layer, name) return layer * 8 + BUTTON[name] end
local NAME_OF = {}
for name, b in pairs(BUTTON) do NAME_OF[b] = name end

-- The controller bars exist (Apply can fill them) whenever the Gamepad UI's
-- binding util is loaded, even while you play on keyboard and mouse; M.Apply
-- uses the same test.
local function Gamepad() return Util() ~= nil end

-- Splits "atlas:<name>" icons from textures.
local function SetIconArt(tex, icon)
  if type(icon) == "string" and icon:find("^atlas:") then
    if UI.SetAtlas(tex, icon:sub(7)) then tex:Show() return true end
    tex:SetTexture(UI.QUESTION)
    return false
  end
  tex:SetTexture(icon)
end
-- Plain texture files standing in for the atlas icons where only SetTexture
-- is used (the Inspector's header and Diff). BarCard rows also get `atlas`.
local ATLAS_TEX = { ["128-redbutton-exit"] = "Interface\\Buttons\\UI-GroupLoot-Pass-Up",
  ["gamepad-ability-icon-jump"] = "Interface\\Icons\\Ability_HeroicLeap" }
local function AtlasOf(icon)
  if type(icon) == "string" and icon:find("^atlas:") then return icon:sub(7) end
end
local function PlainIcon(icon)
  local a = AtlasOf(icon)
  if a then return ATLAS_TEX[a] end
  return icon
end

-- What one button shows: d.name/icon (after Apply), d.nowName/nowIcon (now),
-- d.state ("same", "new", "clear", "waiting", "nobars", "empty", "fixed"),
-- d.stateText, d.color, d.slotState (a UI.SLOT_STATES key), d.change.
local function Describe(plan, set, slotID)
  local p = plan and plan[set] and plan[set][slotID]
  local storage = Storage(set, slotID)
  local d = { slotID = slotID }
  if storage and HasAction(storage) then
    local n = UI.DescribeSlot(storage)
    d.nowIcon, d.nowName = n.icon, n.name
  end
  if FIXED[slotID] then
    d.fixed, d.name, d.icon, d.kind = true, FIXED_TITLE[slotID], FIXED_ICON[slotID], "Gamepad UI"
    d.nowIcon, d.nowName = d.icon, d.name
    d.state, d.stateText, d.color, d.slotState = "fixed", "Fixed by the Gamepad UI", UI.C.FIXED, "fixed"
    return d
  end
  if not p then
    d.name = "Empty"
    if d.nowName then
      d.icon, d.faded, d.change = d.nowIcon, true, true
      d.state, d.stateText, d.color, d.slotState = "clear", "Not in the layout · cleared when you apply", UI.C.REMOVED, "removed"
    else
      d.state, d.stateText, d.color, d.slotState = "empty", "Not in the layout", UI.C.DISABLED, "empty"
    end
    return d
  end
  local item = p.item
  if item.missing then
    d.name, d.reason = item.missing, ReasonText(item)
    d.icon, d.faded = item.icon or UI.SpellIcon(item.missing) or UI.QUESTION, true
    d.color = UI.C.MISSING
    if p.state == "clear" then
      d.state, d.change, d.slotState = "clear", true, "removed"
      d.stateText = "Waiting · cleared when you apply"  -- the slot name is already in the header
    else
      d.state, d.slotState = "waiting", "missing"
      d.stateText = WAITING[item.reason] or WAITING.learn
      if item.reason == "install" and item.macro then d.stateText = M.InstallText(item.macro) end
    end
    return d
  end
  d.name, d.icon, d.kind, d.item = item.name, Icon(item), KIND[item.kind], item
  if item.kind == "macro" then d.macroSpell = LibrarySpell(item.name) end
  d.flyout = item.kind == "flyout"
  d.autocast = item.kind == "macro" and type(item.name) == "string" and item.name:find("^Auto ") ~= nil
  if p.state == "new" then
    d.state, d.change, d.color, d.slotState = "new", true, UI.C.ADDED, "added"
    d.stateText = d.nowName and ("Replaces " .. d.nowName .. " when you apply") or "Added when you apply"
  elseif p.state == "nobars" then
    d.state, d.color, d.slotState = "nobars", UI.C.GRAY, "empty"
    d.stateText = "Placed when the Gamepad UI is on and you apply"
  else
    d.state, d.stateText, d.slotState = "same", "In place", "empty"
  end
  return d
end

-- Every home of the same spell/item/macro elsewhere on the controller.
local function SameItem(a, b)
  return a and b and a.kind == b.kind and ((a.id and a.id == b.id) or (not a.id and a.name == b.name))
end

-- Geometry (stage px, origin TOPLEFT, y down): bar centres on three rows.
-- Every slot carries a name caption under it, so the diamonds are spread a
-- little (Up/Down and Y/A at +-33) and the slots are 40 px. A bar spans
-- about +57 (glyphs) to -80 (two-line Down/A captions) and -164..+158
-- across. The rows interlock: the LT/RT headers sit outside the top bar's
-- columns, and the LT + RT bar's header goes under it (where the native HUD
-- draws its trigger glyphs).
--
-- The middle row is the tight one: four diamonds and their side captions
-- span the whole 712 px stage (LT bar 2..354, RT bar 358..710), so a side
-- caption gets 64 px: about 11 letters of GameFontHighlightSmall. Longer
-- names go through SHORT, and only then end in "...".
local BAR_POS = { [0] = { 356, 123 }, { 178, 264 }, { 534, 264 }, { 356, 405 } }
local SLOT_SIZE = 40
-- Own slot offsets (bar centre, y up): diamonds at -+88, side slots -+55
-- from a diamond's centre, Up/Down and Y/A at -+35.
local DIAMOND_X, SIDE_X, PAD_Y = 88, 55, 35
local SLOT_AT = {
  Up = { -DIAMOND_X, PAD_Y }, Down = { -DIAMOND_X, -PAD_Y },
  Left = { -DIAMOND_X - SIDE_X, 0 }, Right = { -DIAMOND_X + SIDE_X, 0 },
  Y = { DIAMOND_X, PAD_Y }, A = { DIAMOND_X, -PAD_Y },
  X = { DIAMOND_X - SIDE_X, 0 }, B = { DIAMOND_X + SIDE_X, 0 },
}
-- Captions: { width, lines }, one line each in GameFontHighlightSmall (spec
-- §name captions). Up/Y sit between the side slots (that frees the
-- diamond's centre for the Down/A glyphs); side captions sit under their
-- slot, clear of the Down/A slot (35 px either side) and of the next bar's
-- side caption (70 px apart in the middle row); Down/A have the row under
-- the diamond to themselves.
local CAPTION_FONT = "GameFontHighlightSmall"
-- Side and Down/A captions take two lines, so common names show whole
-- ("Trueshot / Aura", "Hunter's / Mark"): a two-line side caption ends at
-- -47, clear of the Down/A slot's x and of the Down/A caption (-58); a
-- two-line Down/A caption ends at -82, above the next row's glyphs and the
-- "Hold both" header. Up/Y keep one line: under them sits the Down glyph.
local CAPTION_AT = { Up = { 64, 1 }, Y = { 64, 1 }, Down = { 96, 2 }, A = { 96, 2 },
  Left = { 64, 2 }, Right = { 64, 2 }, X = { 64, 2 }, B = { 64, 2 } }
-- Long names the HUD shortens to one recognisable word or two (the bar
-- header, the List view and the Inspector show them whole).
local SHORT = {
  ["Tranquilizing Shot"] = "Tranq Shot", ["Counterattack"] = "Counter", ["Mongoose Bite"] = "Mongoose",
  ["Trueshot Aura"] = "Trueshot", ["Aspect of the Hawk"] = "Hawk", ["Aspect of the Monkey"] = "Monkey",
  ["Aspect of the Cheetah"] = "Cheetah", ["Aspect of the Pack"] = "Pack", ["Aspect of the Wild"] = "Wild",
  ["Aspect of the Beast"] = "Beast", ["Concussive Shot"] = "Concussive", ["Scatter Shot"] = "Scatter",
  ["Freezing Trap"] = "Freeze Trap", ["Immolation Trap"] = "Immo Trap", ["Explosive Trap"] = "Explo Trap",
  ["Distracting Shot"] = "Distract", ["Eyes of the Beast"] = "Eyes", ["Hunter's Mark"] = "Mark", ["Raptor Strike"] = "Raptor",
  ["Serpent Sting"] = "Serpent", ["Viper Sting"] = "Viper", ["Scorpid Sting"] = "Scorpid",
  ["Cancel / Back"] = "Back", ["Hearthstone"] = "Hearth", ["Find Minerals"] = "Minerals", ["Find Herbs"] = "Herbs",
  ["Find Treasure"] = "Treasure", ["Engineering"] = "Engineer", ["Cozy Sleeping Bag"] = "Sleeping Bag",
}
-- Focused or held bars keep their size (the section glow and dimming of the
-- other bars mark them): the rows are packed too close to grow, and slots
-- stay on one grid. UpdateBars toggles bar.section itself rather than
-- calling PadBar:SetExpanded, which scales the bar.
-- Glyphs ride each slot's outer corner, as the native HUD's corner prompts
-- do, mostly outside the icon, never on a neighbour or a caption:
-- { corner, dx, dy, size }. Down/A sit in the diamond's free centre.
local GLYPH_AT = {
  Up = { "TOPLEFT", -2, -10, 22 }, Left = { "TOPLEFT", -2, -10, 22 },
  Right = { "TOPRIGHT", 0, -10, 22 }, Down = { "TOPLEFT", 5, 0, 22 },
  Y = { "TOPRIGHT", -3, -9, 24 }, B = { "TOPRIGHT", -3, -9, 24 },
  X = { "TOPLEFT", 3, -9, 24 }, A = { "TOPRIGHT", -5, 0, 24 },
}
-- Held trigger: the other bars fade this far.
local HELD_DIM = 0.4
-- List view: glyph column, then the four layers.
local LIST_X, LIST_COL_W, LIST_TOP, LIST_ROW_H = 50, 164, 70, 54

local function Rows(page, layer, focused)
  local list = page.mode == 2
  local now = page.after == 1
  local rows = {}
  for _, name in ipairs(UI.PAD_BUTTONS) do
    local s = page.bars[layer].slots[name]
    local d = s.info or {}
    local node = list and page.cells[layer][name] or s
    -- (Not "now and d.nowIcon or d.icon": an empty Now slot would show the After icon.)
    local raw
    if now then raw = d.nowIcon else raw = d.icon end
    rows[#rows + 1] = { key = s.padKey, icon = PlainIcon(raw), atlas = AtlasOf(raw),
      name = (now and (d.nowName or "Empty")) or d.name or "Empty",
      color = not now and d.color ~= UI.C.DISABLED and d.color or nil, node = node,
      focused = focused ~= nil and (focused == s or focused == page.cells[layer][name]), faded = not now and d.faded }
  end
  return { title = BarTitle(layer) .. " · set " .. page.current, rows = rows }
end

local function Goto(page, set, layer, name)
  page.current, page.view = set, tostring(set)
  ns.OpenPage("controller", (page.mode == 2 and "list:" or "pad:") .. layer .. ":" .. name)
end

local function CrossRefs(page, node)
  local d, refs = node.info or {}, {}
  if not d.item then return refs end
  local plan = page.plan
  for set = 1, 3 do
    for slotID, p in pairs(plan[set] or {}) do
      if type(slotID) == "number" and not (set == page.current and slotID == d.slotID) and SameItem(p.item, d.item) then
        local layer, name = math.floor((slotID - 1) / 8), NAME_OF[(slotID - 1) % 8 + 1]
        refs[#refs + 1] = { text = "Also on set " .. set .. " · " .. Chord(layer, name) .. " (one home per spell)",
          color = UI.C.MISSING, fn = function() Goto(page, set, layer, name) end }
      end
    end
  end
  for key, pp in pairs(plan.paddles or {}) do
    if SameItem(pp.item, d.item) then
      refs[#refs + 1] = { text = "Also on back button " .. PaddleLabel(key), color = UI.C.MISSING, fn = function() end }
    end
  end
  return refs
end

local function InspectButton(node, pane)
  local page, d = node.page, node.info or {}
  local keys = {}
  for _, k in ipairs(UI.PAD_LAYER_TRIGGERS[node.layer] or {}) do keys[#keys + 1] = k end
  keys[#keys + 1] = node.padKey
  local now = page.after == 1
  local raw
  if now then raw = d.nowIcon else raw = d.icon end
  local icon = PlainIcon(raw)
  local name = now and (d.nowName or "Empty") or d.name or "Empty"
  pane:Header(icon, name, (d.kind or "Button") .. " · " .. TabLabel(page.current, page.titles[page.current]), keys)
  pane:Row("State", d.stateText or "", d.color)
  -- Now -> After only when something is really replaced (an empty "Now" says nothing).
  if d.change and d.nowName then
    pane:Diff({ icon = PlainIcon(d.nowIcon), name = d.nowName },
      { icon = d.state ~= "clear" and PlainIcon(d.icon) or nil, name = d.state == "clear" and "Empty" or d.name, color = d.color })
  end
  -- What this button does comes first, above the fold on the Deck: why it
  -- waits, what a macro casts, the radial / fixed / empty notes. Then the
  -- links, then the whole bar card (it may run below the fold).
  if d.reason then pane:Text(d.reason, UI.C.MISSING) end
  if not now and d.macroSpell then pane:Text("Library macro: casts " .. d.macroSpell .. ".", UI.C.GRAY) end
  if d.flyout then pane:Text("Radial: hold the button to open a ring of these spells, then pick one with the stick.", UI.C.NORMAL) end
  if d.fixed then pane:Text("The Gamepad UI keeps this button for " .. d.name:lower() .. ". Apply never changes it.") end
  if d.state == "empty" then pane:Text("Not in the layout. The Gamepad UI may put newly learned spells here; Apply clears them.", UI.C.GRAY) end
  local refs = CrossRefs(page, node)
  if #refs > 0 then pane:CrossRef(refs) end
  -- The whole bar, glyph + icon + name.
  pane:BarCard(Rows(page, node.layer, node))
end

-- Focused and held bars --------------------------------------------------------------

-- Focus marks its bar with the section glow only: every name stays at full
-- strength. Holding a trigger brings that bar forward (lit header, the
-- others faded), as the native HUD does.
local function UpdateBars(page)
  local held = page.held
  local layer = held or page.focusLayer
  local off = not Gamepad()
  for l = 0, 3 do
    local bar = page.bars[l]
    local on = l == layer
    if bar.expanded ~= on then
      bar.expanded = on
      if bar.section then bar.section:SetShown(on) end
    end
    local alpha = ((held ~= nil and l ~= held) and HELD_DIM or 1) * (off and 0.6 or 1)
    if bar.acAlpha ~= alpha then
      bar.acAlpha = alpha
      bar:SetAlpha(alpha)
      bar.hdr:SetAlpha(alpha); bar.rule:SetAlpha(alpha)
    end
    local lit = held == l
    if bar.hdrGlow then bar.hdrGlow:SetShown(lit) end
    if bar.layerText then
      if lit then bar.layerText:SetTextColor(1, 1, 1) else bar.layerText:SetTextColor(1, 0.82, 0) end
    end
    if bar.rule.SetVertexColor then
      if lit then bar.rule:SetVertexColor(1, 0.82, 0, 1) else bar.rule:SetVertexColor(0.9, 0.62, 0.32, 0.55) end
    end
    local d = page.focusNode and page.focusNode.layer == l and page.focusNode.info
    if d then
      local now = page.after == 1
      bar.focusName:SetText(UI.C.HIGHLIGHT:WrapTextInColorCode("·  " .. ((now and d.nowName) or (not now and d.name) or "Empty")))
    else
      bar.focusName:SetText("")
    end
  end
  for l = 0, 3 do
    local glow = page.colGlow and page.colGlow[l]
    if glow then glow:SetShown(l == layer); glow.line:SetShown(l == layer) end
  end
end

local function OnFocusButton(node)
  local page = node.page
  page.focusLayer, page.focusNode = node.layer, node
  UpdateBars(page)
end
local function OnBlurButton(node)
  local page = node.page
  if page.focusNode == node then page.focusLayer, page.focusNode = nil, nil end
  UpdateBars(page)
end

-- LT = Shift and RT = Ctrl on the Gamepad UI (GAMEPAD_MOD_*): holding a
-- trigger (or the key) expands that bar and shows it in the Inspector.
local function OnModifiers(page, shift, ctrl)
  local held = (shift and ctrl and 3) or (shift and 1) or (ctrl and 2) or nil
  if held == page.held then return end
  page.held = held
  if not page.bars then return end
  UpdateBars(page)
  local pane = page.pane
  if not pane or ns.Focus.pinned then return end
  if held then
    pane:Clear()
    pane:BarCard(Rows(page, held, ns.Focus.current))
  else
    ns.Focus:Inspect(ns.Focus.current)
  end
end

-- Build -----------------------------------------------------------------------------------

-- The Inspector's BarCard row for a pad key ("barcard:PAD1"), else its top
-- focusable node; nil when the Inspector has none.
local function InspectorTarget(padKey)
  local F = ns.Focus
  if not (F and F.Nodes and F.ZoneOf) then return nil end
  local want = padKey and ("barcard:" .. padKey)
  local best, bestTop
  for _, n in ipairs(F:Nodes()) do
    if F.ZoneOf(n) == "inspector" and (not F.Usable or F.Usable(n)) then
      if want and n.acId == want then return n end
      local top = n.GetTop and n:GetTop() or 0
      if not bestTop or top > bestTop then best, bestTop = n, top end
    end
  end
  return best
end

-- Mouse click: toggle the pin (focus stays where the mouse is).
local function TogglePin(node)
  local F = ns.Focus
  if not F then return end
  if F.pinned == node then F:Unpin() return end
  if F.pinned then F:Unpin() end
  F:Pin(node)
end

-- A / Enter on a HUD slot or List cell (the Keyboard and Macros pages'
-- pattern): pin it and step into the Inspector onto the BarCard row of
-- that same button, so the bar card and the links are on the D-pad. A on
-- the pinned node again unpins. One B in the Inspector unpins and brings
-- focus back to the slot.
local function PinAndEnter(node, source)
  local F, Esc = ns.Focus, ns.Esc
  if not F then return end
  if F.pinned == node then F:Unpin() return end
  TogglePin(node)
  if F.pinned ~= node then return end
  if UI.Sound then pcall(UI.Sound, "activate") end
  local target = InspectorTarget(node.padKey)
  if not target then return end
  F:Set(target, source or "key")
  if Esc and Esc.Push then
    Esc.Push(function()
      if F.pinned == node then F:Unpin() end
      local cur = F.current
      if cur and F.ZoneOf and F.ZoneOf(cur) == "inspector" and node.IsVisible and node:IsVisible()
        and (not F.Usable or F.Usable(node)) then
        F:Set(node, F.source or "key")
      end
    end, "pin")
  end
end

local function ButtonNode(page, node, layer, name)
  node.page, node.layer, node.padName, node.padKey = page, layer, name, UI.PAD_OFFSETS[name][4]
  node.acInspect = InspectButton
  node.acOnFocus, node.acOnBlur = OnFocusButton, OnBlurButton
  node:SetScript("OnClick", TogglePin)
  node.acActivate = PinAndEnter
end

-- Byte index where a UTF-8 cut at or before i keeps whole characters.
local function Utf8Cut(s, i)
  while i > 1 do
    local b = s:byte(i + 1)
    if not b or b < 0x80 or b >= 0xC0 then break end
    i = i - 1
  end
  return i
end

-- Puts name on at most `lines` lines of `width` px: the whole name, else
-- its SHORT form; on more than one line whole words first; a
-- word too long for a line is hyphenated (never broken bare); what still
-- does not fit ends in "...". Explicit line breaks, so the client never
-- breaks a word mid-letter.
local function FitCaption(fs, name, width, lines)
  -- The unbounded width: GetStringWidth stops at the string's own width
  -- (64 px here), so every long name "fit" and the client cut it ("Mongoos...").
  local function W(t)
    fs:SetText(t)
    return (fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth()) or fs:GetStringWidth() or 0
  end
  local full = width
  -- A little slack: shadowed glyphs and font fallbacks run wider than measured.
  width = width - 3
  if W(name) <= width then return end
  -- Whole words on up to `lines` lines, the full name first, then its short
  -- form; only when neither fits whole is a word hyphenated or cut below.
  local function Wrap(n)
    local out, line = {}, ""
    for w in n:gmatch("%S+") do
      local try = line == "" and w or (line .. " " .. w)
      if W(try) <= width then line = try
      elseif line ~= "" and W(w) <= width then out[#out + 1], line = line, w
      else return nil end
    end
    if line ~= "" then out[#out + 1] = line end
    if #out > lines then return nil end
    return table.concat(out, "\n")
  end
  if lines > 1 then
    local t = Wrap(name) or (SHORT[name] and Wrap(SHORT[name]))
    if t then fs:SetText(t) return end
  end
  -- Too wide whole: the short form, if one is known.
  if SHORT[name] then
    name = SHORT[name]
    if W(name) <= width then return end
  end
  local words = {}
  for w in name:gmatch("%S+") do words[#words + 1] = w end
  local out, line, i = {}, "", 1
  while i <= #words and #out < lines do
    local w = words[i]
    local try = line == "" and w or (line .. " " .. w)
    if W(try) <= width then
      line, i = try, i + 1
    elseif line ~= "" then
      out[#out + 1], line = line, ""
    elseif #out < lines - 1 and #w > 5 then
      -- One word wider than the line: hyphenate, keeping 3+ letters each side.
      local cut = Utf8Cut(w, #w - 3)
      while cut > 3 and W(w:sub(1, cut) .. "-") > full * 0.85 do cut = Utf8Cut(w, cut - 1) end
      -- Prefer a syllable-ish break, consonant | vowel ("Counter-attack").
      for j = cut, 4, -1 do
        local a, b = w:sub(j, j):lower(), w:sub(j + 1, j + 1):lower()
        if a:find("^[b-df-hj-np-tv-z]$") and b:find("^[aeiouy]$") then cut = j break end
      end
      out[#out + 1] = w:sub(1, cut) .. "-"
      words[i] = w:sub(cut + 1)
    else
      line, i = w, i + 1 -- the last line: truncated below
    end
  end
  if line ~= "" and #out < lines then out[#out + 1] = line; line = "" end
  local rest = i <= #words or line ~= ""
  local last = out[#out] or ""
  if rest or W(last) > width then
    while #last > 1 and W(last .. "...") > width do last = last:sub(1, Utf8Cut(last, #last - 1)) end
    out[#out] = last:gsub("[%s%-]+$", "") .. "..."
  end
  fs:SetText(table.concat(out, "\n"))
end

-- A dark disc behind a D-pad glyph, only for the full-cross fallback art
-- (thin and light: on its own it reads as a notch in a bright icon). The
-- single-direction "donly" shields bring their own dark plate, as the face
-- glyphs do, so they get no disc (PadGlyph hides it).
local function GlyphDisc(g)
  if g.acDisc or not g.CreateTexture then return end
  local d = g:CreateTexture(nil, "BACKGROUND")
  d:SetPoint("CENTER")
  d:SetSize(g.size or 22, g.size or 22)
  d:SetTexture(UI.WHITE)
  d:SetVertexColor(0.02, 0.02, 0.03, 0.92)
  if g.CreateMaskTexture and d.AddMaskTexture then
    local m = g:CreateMaskTexture(nil, "BACKGROUND")
    m:SetAllPoints(d)
    local a = UI.FirstAtlas(UI.ART.padCircleMask)
    if a then m:SetAtlas(a)
    else m:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE") end
    d:AddMaskTexture(m)
  end
  g.acDisc = d
end

-- D-pad shield art fills only about 55% of its atlas cell, so a shield is
-- drawn this much larger than the face glyphs for the same visible size.
local DONLY_SIZE = 30
-- Sizes a HUD slot's glyph for the art the current prompt style uses:
-- donly shields large and bare, the cross fallback with its disc.
local function PadGlyph(s)
  local g, at = s.glyph, GLYPH_AT[s.padName]
  if not (g and at) then return end
  local a = UI.GlyphAtlas and UI.GlyphAtlas(s.padKey)
  local donly = type(a) == "string" and a:find("donly", 1, true) ~= nil
  local size = donly and DONLY_SIZE or at[4]
  if g.size ~= size then g:SetSize(size, size) end
  -- Re-anchor only when the art kind changes (every refresh calls this).
  local placed = (donly and "d" or "c") .. size
  if g.acPlaced == placed then return end
  g.acPlaced = placed
  -- A larger shield grows inward, so its outer edge stays where the
  -- smaller glyph's was (inside the stage, off the neighbours). Down's
  -- glyph sits in the diamond's free centre and stays put.
  local grow = s.padName == "Down" and 0 or (size - at[4]) / 2
  local dx = at[1]:find("LEFT") and grow or -grow
  g:ClearAllPoints()
  g:SetPoint("CENTER", s, at[1], at[2] + dx, at[3] - grow)
  if g.acDisc then
    g.acDisc:SetSize(size, size)
    g.acDisc:SetShown(not donly)
  end
end

-- Explicit vertical moves between bars: the slot of `layers` (among `names`)
-- nearest in x, so D-pad Up/Down never drift to a chip at the stage's side.
local function NearestSlot(page, layers, names)
  return function(cur)
    local Focus = ns.Focus
    local cl, _, cw = Focus.ScreenRect(cur)
    if not cl then return nil end
    local cx, best, bestD = cl + cw / 2, nil, nil
    for _, l in ipairs(layers) do
      for _, n in ipairs(names) do
        local s = page.bars[l].slots[n]
        local sl, _, sw = Focus.ScreenRect(s)
        if sl and Focus.Usable(s) then
          local dist = math.abs(sl + sw / 2 - cx)
          if not bestD or dist < bestD then best, bestD = s, dist end
        end
      end
    end
    return best
  end
end

-- Up from the top bar: the selected set tab (the view chip that is lit),
-- else the view chip nearest in x; never the HUD/List or Now/After toggles.
local function NearestChip(page)
  return function(cur)
    local Focus = ns.Focus
    local strip = page.strip and page.strip.chips
    local chips = strip and strip.buttons
    local cl, _, cw = Focus.ScreenRect(cur)
    if not (chips and cl) then return nil end
    local sel = strip.selected and chips[strip.selected]
    if sel and Focus.Usable(sel) then return sel end
    local cx, best, bestD = cl + cw / 2, nil, nil
    for _, b in ipairs(chips) do
      local bl, _, bw = Focus.ScreenRect(b)
      if bl and Focus.Usable(b) then
        local dist = math.abs(bl + bw / 2 - cx)
        if not bestD or dist < bestD then best, bestD = b, dist end
      end
    end
    return best
  end
end

local function WireHUDNav(page)
  local B = page.bars
  local S0, S1, S2, S3 = B[0].slots, B[1].slots, B[2].slots, B[3].slots
  -- Rows wrap sideways (spec §4.5): the top and bottom bars inside
  -- themselves, the LT + RT row across both bars.
  S0.Left.navLeft, S0.B.navRight = S0.B, S0.Left
  S3.Left.navLeft, S3.B.navRight = S3.B, S3.Left
  S1.B.navRight, S2.Left.navLeft = S2.Left, S1.B
  S1.Left.navLeft, S2.B.navRight = S2.B, S1.Left
  local LOW = { "Down", "A", "Left", "Right", "X", "B" }
  local HIGH = { "Up", "Y", "Left", "Right", "X", "B" }
  local chip = NearestChip(page)
  local toTop, toMidLow = NearestSlot(page, { 0 }, LOW), NearestSlot(page, { 1, 2 }, LOW)
  local toMidHigh, toBottom = NearestSlot(page, { 1, 2 }, HIGH), NearestSlot(page, { 3 }, HIGH)
  for _, n in ipairs({ "Up", "Y" }) do
    S0[n].navUp = chip
    S1[n].navUp, S2[n].navUp = toTop, toTop
    S3[n].navUp = toMidLow
  end
  for _, n in ipairs({ "Down", "A" }) do
    S0[n].navDown = toMidHigh
    S1[n].navDown, S2[n].navDown = toBottom, toBottom
    -- The bottom bar's lowest buttons go down to the prompt bar (spatial).
  end
end

local function BuildHUD(page, stage)
  local hud = CreateFrame("Frame", nil, stage)
  hud:SetAllPoints()
  page.hud = hud
  page.bars = {}
  for layer = 0, 3 do
    -- A holder at the bar's centre: the bar and its header hang off it.
    local pos = BAR_POS[layer]
    local holder = CreateFrame("Frame", nil, hud)
    holder:SetSize(1, 1)
    holder:SetPoint("CENTER", hud, "TOPLEFT", pos[1], -pos[2])
    local bar = UI.PadBar(hud, layer, SLOT_SIZE)
    bar:SetPoint("CENTER", holder, "CENTER", 0, 0)
    bar:SetTitle("")
    for _, g in ipairs(bar.triggers or {}) do g:Hide() end
    -- Big enough to hold the captions (symmetric: the bar is centre-anchored);
    -- the focus glow hugs the slots and captions, not the header.
    bar:SetSize(352, 170)
    -- The focus band (gamepad-actionbar-focus-bg-section, native 512x160
    -- behind a 266x86 bar) at the native aspect, over this bar's own
    -- column only (356 px: the LT and RT bars sit side by side), centred
    -- on the slots and captions (glyph tops +57, Down/A captions -70).
    if bar.section then
      bar.section:ClearAllPoints()
      bar.section:SetSize(356, 112)
      bar.section:SetPoint("CENTER", bar, "CENTER", 0, -6)
    end
    if bar.behind then
      bar.behind:ClearAllPoints()
      bar.behind:SetPoint("TOPLEFT", bar, "CENTER", -178, 70)
      bar.behind:SetPoint("BOTTOMRIGHT", bar, "CENTER", 178, -94)
    end
    -- (No plate or backing behind the bar: the native HUD hides its
    -- gamepad-actionbar-bg frames too; the slots carry their drop shadows.)
    -- Header: the trigger glyphs, the layer, and the focused button's name.
    -- It hangs off the holder, so the titles keep one baseline. Top bar: full width above. LT bar: left half above, RT bar:
    -- right half above (clear of the top bar's columns). LT + RT: below.
    local hdr = CreateFrame("Frame", nil, hud)
    local rule = UI.Flat(hud, "BORDER", 0.9, 0.62, 0.32, 0.55)
    rule:SetHeight(1)
    if layer == 3 then
      hdr:SetSize(352, 20)
      hdr:SetPoint("TOPLEFT", holder, "CENTER", -176, -84)
      rule:SetPoint("BOTTOMLEFT", hdr, "TOPLEFT", 0, 1)
      rule:SetPoint("BOTTOMRIGHT", hdr, "TOPRIGHT", 0, 1)
    else
      hdr:SetSize(layer == 0 and 352 or 168, 20)
      if layer == 2 then hdr:SetPoint("BOTTOMRIGHT", holder, "CENTER", 176, 63)
      else hdr:SetPoint("BOTTOMLEFT", holder, "CENTER", -176, 63) end
      rule:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 0, -1)
      rule:SetPoint("TOPRIGHT", hdr, "BOTTOMRIGHT", 0, -1)
    end
    -- Lit while this bar's trigger is held (UpdateBars).
    bar.hdrGlow = UI.Gradient(hdr, "BACKGROUND", "HORIZONTAL",
      layer == 2 and { 1, 0.82, 0, 0 } or { 1, 0.82, 0, 0.32 },
      layer == 2 and { 1, 0.82, 0, 0.32 } or { 1, 0.82, 0, 0 })
    bar.hdrGlow:SetAllPoints()
    bar.hdrGlow:Hide()
    local x = 0
    for _, k in ipairs(UI.PAD_LAYER_TRIGGERS[layer] or {}) do
      local g = UI.Glyph(hdr, k, 20, "pad")
      g:SetPoint("LEFT", x, 0)
      x = x + 22
    end
    bar.layerText = UI.Text(hdr, GLYPH_TITLE[layer], "GameFontNormal")
    bar.layerText:SetPoint("LEFT", x + (x > 0 and 2 or 0), 0)
    bar.focusName = UI.Text(hdr, "", "GameFontHighlight")
    bar.focusName:SetPoint("LEFT", bar.layerText, "RIGHT", 6, 0)
    bar.focusName:SetPoint("RIGHT", hdr, "RIGHT", 0, 0)
    bar.focusName:SetJustifyH("LEFT")
    bar.focusName:SetWordWrap(false)
    bar.hdr, bar.rule = hdr, rule
    -- Captions draw above the slots, so slot frame art never covers a name.
    local capLayer = CreateFrame("Frame", nil, bar)
    capLayer:SetAllPoints()
    capLayer:SetFrameLevel(bar:GetFrameLevel() + 10)
    bar.captions = capLayer
    for _, name in ipairs(UI.PAD_BUTTONS) do
      local s = bar.slots[name]
      ButtonNode(page, s, layer, name)
      local o = SLOT_AT[name]
      s:ClearAllPoints()
      s:SetPoint("CENTER", bar, "CENTER", o[1], o[2])
      local g = GLYPH_AT[name]
      -- (.size too: UI.Glyph's Refresh resizes to it on every prompt refresh.)
      s.glyph.size = g[4]
      s.glyph:SetSize(g[4], g[4])
      if s.shape == "square" then GlyphDisc(s.glyph) end
      -- PadGlyph places it. (A SetPoint here used to undo the shield
      -- offset until the first Refresh, so glyphs jumped on open.)
      PadGlyph(s)
      -- A prompt style change (Xbox <-> PlayStation art) re-sizes the glyph
      -- at once, not on the page's next refresh.
      local glyphRefresh = s.glyph.Refresh
      if glyphRefresh then
        function s.glyph.Refresh(self) glyphRefresh(self); PadGlyph(s) end
      end
      -- The name, under the slot, coloured by state (FitCaption breaks it).
      local c = CAPTION_AT[name]
      local cap = UI.Text(capLayer, "", CAPTION_FONT)
      cap:SetWidth(c[1])
      cap:SetPoint("TOP", s, "BOTTOM", 0, -3)
      cap:SetJustifyH("CENTER")
      if cap.SetJustifyV then cap:SetJustifyV("TOP") end
      cap:SetWordWrap(c[2] > 1)
      if cap.SetMaxLines then cap:SetMaxLines(c[2]) end
      cap.fitWidth, cap.fitLines = c[1], c[2]
      s.caption = cap
    end
    page.bars[layer] = bar
  end
  -- Edges: rows wrap sideways, D-pad Up/Down between bars go to the slot
  -- nearest in x, the top bar's highest buttons up to the set chips, the
  -- bottom bar's lowest down to the prompt bar (spatial).
  WireHUDNav(page)

  -- Row 1, left: the set badge.
  page.setTitle = UI.SectionTitle(hud, "CONTROLLER SET", 10, -48, 160)
  page.setNum = UI.Text(hud, "1", "GameFontNormalHuge")
  page.setNum:SetPoint("TOPLEFT", hud, "TOPLEFT", 16, -82)
  page.setName = UI.Text(hud, "", "GameFontHighlightLarge")
  page.setName:SetPoint("LEFT", page.setNum, "RIGHT", 10, 0)
  page.setName:SetWidth(140)
  page.setName:SetJustifyH("LEFT")
  page.setName:SetWordWrap(false)
  page.setCount = UI.Text(hud, "", "GameFontHighlight")
  page.setCount:SetPoint("TOPLEFT", hud, "TOPLEFT", 16, -112)
  page.setCount:SetWidth(170)
  page.setCount:SetJustifyH("LEFT")
  -- Next set: the pad glyph or keyboard keycap with its label, and in every
  -- mode a click target (mouse mode shows the label alone, flush left, with
  -- a hover highlight). Not a focus node: the footer prompt is the pad and
  -- keyboard route, so the HUD's D-pad graph is unchanged.
  local hint = CreateFrame("Button", nil, hud)
  hint:SetPoint("TOPLEFT", hud, "TOPLEFT", 12, -134)
  hint:SetSize(120, 26)
  local hl = hint:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  if not UI.SetAtlas(hl, UI.ART.rowHover) then hl:SetTexture(UI.WHITE); hl:SetVertexColor(1, 1, 1, 0.08) end
  hl:SetBlendMode("ADD")
  hint:SetScript("OnClick", function()
    if ns.UI and ns.UI.CycleView then ns.UI.CycleView(1) end
  end)
  page.setHintButton = hint
  page.setHint = UI.Glyph(hint, "PAD3", 22, "prompt")
  page.setHint:SetPoint("LEFT", hint, "LEFT", 2, 0)
  page.setHintText = UI.Text(hint, "Next set", "GameFontNormal")
  local function HintLayout()
    local gw = page.setHint.width or 0
    -- Mouse mode: no key to show, so the label reads as a link to click.
    page.setHintText:SetText(gw > 1 and "Next set" or "Next set \226\128\186")
    page.setHintText:ClearAllPoints()
    if gw > 1 then page.setHintText:SetPoint("LEFT", page.setHint, "RIGHT", 6, 0)
    else page.setHintText:SetPoint("LEFT", hint, "LEFT", 4, 0) end
    hint:SetWidth(math.max(40, (gw > 1 and gw + 8 or 4) + math.ceil(page.setHintText:GetStringWidth() or 0) + 6))
  end
  local refreshGlyph = page.setHint.Refresh
  function page.setHint.Refresh(self)
    refreshGlyph(self)
    HintLayout()
  end
  HintLayout()

  -- Row 1, right: the legend, or the Gamepad-UI-off plate.
  page.legend = CreateFrame("Frame", nil, hud)
  page.legend:SetPoint("TOPLEFT", hud, "TOPLEFT", 534, -48)
  page.legend:SetSize(170, 120)
  local items = { { "added", "Added when you apply" }, { "removed", "Cleared when you apply" },
    { "missing", "Waiting to learn" }, { "flyout", "Radial (opens a ring)" } }
  for i, l in ipairs(items) do
    local it = UI.LegendItem(page.legend, l[1], l[2])
    it:SetPoint("TOPLEFT", 0, -(i - 1) * 26)
  end
  page.offPlate = UI.Plate(hud)
  page.offPlate:SetPoint("TOPLEFT", hud, "TOPLEFT", 526, -46)
  page.offPlate:SetSize(178, 126)
  local offText = UI.Text(page.offPlate, "The Gamepad UI is off. These bars fill when you turn it on (Options › Controls › Gamepad). The back buttons still apply.", "GameFontHighlight")
  offText:SetPoint("TOPLEFT", 10, -10)
  offText:SetPoint("TOPRIGHT", -10, -10)
  offText:SetJustifyH("LEFT")
  offText:SetTextColor(UI.RGB(UI.C.ORANGE))
  page.offPlate:Hide()

  -- Row 3, both sides: the back buttons, left pair and right pair as on the Deck.
  page.paddles = {}
  local spots = { L4 = 30, L5 = 100, R4 = 572, R5 = 642 }
  for key, x in pairs(spots) do
    local sk = UI.Socket(hud, key)
    sk:SetPoint("TOPLEFT", hud, "TOPLEFT", x, -400)
    sk.icon = sk:CreateTexture(nil, "OVERLAY")
    sk.icon:SetSize(24, 24)
    sk.icon:SetPoint("CENTER", sk.socket, "CENTER")
    sk.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    sk.icon:Hide()
    page.paddles[key] = sk
  end
  for i, x in ipairs({ 18, 560 }) do
    local t = UI.Text(hud, "Back buttons · kept free", "GameFontDisable")
    t:SetPoint("TOPLEFT", hud, "TOPLEFT", x, -464)
    t:SetWidth(150)
    t:SetJustifyH("CENTER")
    page["paddleNote" .. i] = t
  end
end

local function BuildList(page, stage)
  local host = CreateFrame("Frame", nil, stage)
  host:SetPoint("TOPLEFT", 0, 0)
  host:SetPoint("BOTTOMRIGHT", 0, 0)
  page.listHost = host
  page.cells, page.colGlow = {}, {}
  for layer = 0, 3 do
    local x = LIST_X + layer * LIST_COL_W
    -- Column glow while its trigger is held.
    -- (a flat tint: the list-highlight atlas smears when stretched this tall).
    local glow = UI.Flat(host, "BACKGROUND", 1, 0.82, 0, 0.08, 2)
    glow:SetPoint("TOPLEFT", host, "TOPLEFT", x - 2, -40)
    glow:SetSize(LIST_COL_W - 2, LIST_TOP - 40 + 8 * LIST_ROW_H)
    local line = UI.Flat(host, "BORDER", 1, 0.82, 0, 0.8)
    line:SetPoint("TOPLEFT", glow, "TOPLEFT", 0, -(LIST_TOP - 40 - 3))
    line:SetSize(LIST_COL_W - 2, 2)
    glow.line = line
    glow:Hide()
    line:Hide()
    page.colGlow[layer] = glow
    local hx = 4
    for _, k in ipairs(UI.PAD_LAYER_TRIGGERS[layer] or {}) do
      local g = UI.Glyph(host, k, 22, "pad")
      g:SetPoint("TOPLEFT", host, "TOPLEFT", x + hx, -44)
      hx = hx + 24
    end
    local h = UI.Text(host, GLYPH_TITLE[layer]:upper(), "GameFontNormal")
    h:SetPoint("TOPLEFT", host, "TOPLEFT", x + hx + 2, -49)
    page.cells[layer] = {}
  end
  for r, name in ipairs(UI.PAD_BUTTONS) do
    local y = LIST_TOP + (r - 1) * LIST_ROW_H
    local zebra = host:CreateTexture(nil, "BACKGROUND", nil, 1)
    zebra:SetPoint("TOPLEFT", host, "TOPLEFT", 8, -y)
    zebra:SetSize(712 - 16, LIST_ROW_H - 2)
    if not UI.SetAtlas(zebra, r % 2 == 1 and UI.ART.zebra or UI.ART.zebra2) then
      zebra:SetTexture(UI.WHITE); zebra:SetVertexColor(1, 1, 1, r % 2 == 1 and 0.05 or 0.02)
    end
    zebra:SetAlpha(r % 2 == 1 and 0.9 or 0.5)
    local g = UI.Glyph(host, UI.PAD_OFFSETS[name][4], 28, "pad")
    g:SetPoint("CENTER", host, "TOPLEFT", 28, -(y + LIST_ROW_H / 2 - 1))
    for layer = 0, 3 do
      local cell = CreateFrame("Button", nil, host)
      cell:SetSize(LIST_COL_W - 6, LIST_ROW_H - 4)
      cell:SetPoint("TOPLEFT", host, "TOPLEFT", LIST_X + layer * LIST_COL_W, -(y + 1))
      local shape = UI.PAD_OFFSETS[name][3]
      local s = UI.PadSlot(cell, shape, 40)
      s:SetPoint("LEFT", 2, 0)
      s:EnableMouse(false)
      s.acSkip = true
      s:SetGlyph(nil)
      s:SetEmptyKey(UI.PAD_OFFSETS[name][4])
      cell.slot = s
      cell.nameText = UI.Text(cell, "", "GameFontHighlight")
      cell.nameText:SetPoint("LEFT", s, "RIGHT", 6, 0)
      cell.nameText:SetWidth(LIST_COL_W - 6 - 50)
      cell.nameText:SetJustifyH("LEFT")
      if cell.nameText.SetMaxLines then cell.nameText:SetMaxLines(2) end
      UI.Node(cell, { style = "row", id = "list:" .. layer .. ":" .. name })
      ButtonNode(page, cell, layer, name)
      -- Right from the last column goes sideways into the Inspector, onto
      -- the BarCard row for this same button (never up to the header).
      if layer == 3 then cell.navRight = function(cur) return InspectorTarget(cur.padKey) end end
      page.cells[layer][name] = cell
    end
  end
end

-- Fill ------------------------------------------------------------------------------------

-- The name a slot shows (Now or After) and its colour by state.
local function NameOf(page, d)
  local now = page.after == 1
  local name = (now and (d.nowName or "Empty")) or d.name or "Empty"
  local c = (not now and d.color) or ((now and not d.nowName or d.state == "empty") and UI.C.DISABLED) or UI.C.HIGHLIGHT
  if d.fixed then c = UI.C.FIXED end
  return name, c
end

-- A macro looks like the spell it casts (same icon, the macro's name), so
-- placed macros get a small gold "M" tag in the icon's lower-left corner,
-- on the HUD and in the List view alike.
local function MacroTag(s, on)
  if not on then
    if s.acMacroTag then s.acMacroTag:Hide() end
    return
  end
  local t = s.acMacroTag
  if not t then
    t = CreateFrame("Frame", nil, s)
    t:SetSize(13, 13)
    t:SetPoint("BOTTOMLEFT", s, "BOTTOMLEFT", 3, 3)
    t:SetFrameLevel(s:GetFrameLevel() + 6)
    -- Outlined text, as the action button's hotkey and count text are (no
    -- flat box drawn over the icon).
    t.text = UI.Text(t, "M", "NumberFontNormalSmall")
    t.text:SetTextColor(1, 0.82, 0)
    t.text:SetPoint("CENTER", 0, 0)
    s.acMacroTag = t
  end
  t:Show()
end

local function FillSlot(page, s, d)
  local now = page.after == 1
  s.info = d
  -- No permabound overlay: over a desaturated icon its red ring reads as "disabled".
  s:SetPermabound(false)
  -- Now shows what sits there now: an empty slot is empty, never the After icon.
  local icon
  if now then icon = d.nowIcon else icon = d.icon end
  if type(icon) == "string" and icon:find("^atlas:") then
    s:SetIcon(nil)
    if SetIconArt(s.icon, icon) then
      s.icon:Show()
      if s.RefreshEmpty then s:RefreshEmpty() elseif s.empty then s.empty:Hide() end
    end
  else
    s:SetIcon(icon)
  end
  if now then
    s:SetState(d.fixed and "fixed" or (d.change and "replaces") or "empty")
  else
    s:SetState(d.slotState or "empty")
    if d.flyout then s:SetBadge("flyout") end
  end
  if d.fixed and s.icon:IsShown() then s.icon:SetDesaturated(true); s.icon:SetAlpha(0.7) end
  -- Only on change: ShowAutoCastEnabled restarts the ants, so calling it on
  -- every refresh made them jump; and slots that never autocast never make
  -- the overlay.
  local auto = not now and d.autocast == true
  if (s.acAuto or false) ~= auto then
    s.acAuto = auto
    s:SetAutoCast(auto)
  end
  MacroTag(s, not now and d.item ~= nil and d.item.kind == "macro")
  PadGlyph(s)
  local tip = { title = (now and d.nowName) or d.name or "Empty", text = d.stateText, color = d.color }
  if not now and d.item and d.item.kind == "spell" then tip.spellID = d.item.id
  elseif not now and d.item and d.item.kind == "item" then tip.itemID = d.item.id end
  s:SetTip(tip)
  if s.caption then
    local name, c = NameOf(page, d)
    -- "(radial)" and "(or better)" are for the List and the Inspector.
    local cap, text = s.caption, (name:gsub(" %(radial%)$", ""):gsub(" %(or better%)$", ""))
    if cap.fitWidth then FitCaption(cap, text, cap.fitWidth, cap.fitLines) else cap:SetText(text) end
    s.caption:SetTextColor(UI.RGB(c))
  end
end

local function FillCell(page, cell, d)
  FillSlot(page, cell.slot, d)
  cell.info = d
  local name, c = NameOf(page, d)
  -- A macro names the spell it casts on a second, gray line ("Arcane" /
  -- "Macro · Arcane Shot"), so it never reads as a truncated spell.
  if page.after ~= 1 and d.item and d.item.kind == "macro" then
    name = name .. "\n" .. UI.C.GRAY:WrapTextInColorCode("Macro" .. (d.macroSpell and (" · " .. d.macroSpell) or ""))
  end
  cell.nameText:SetText(name)
  cell.nameText:SetTextColor(UI.RGB(c))
  cell.tip = cell.slot.tip
end

local function FillPaddle(sk, pp)
  local item = pp and pp.item
  local icon
  if item and not item.missing then icon = Icon(item)
  elseif pp and pp.current ~= "" then icon = (UI.DescribeCommand(pp.current) or {}).icon end
  sk.icon:SetTexture(icon)
  sk.icon:SetShown(icon ~= nil)
  sk.icon:SetDesaturated(pp ~= nil and pp.state == "clear")
end

local function SetMode(page, i)
  page.mode = i
  if ns.db then ns.db.controllerView = i end
end

ns.RegisterPage({
  id = "controller",
  api = 2,
  title = "Controller",
  icon = "Interface\\Icons\\INV_Gauntlets_04",
  order = 20,
  section = "gamepad",
  module = "Controller",
  aliases = { "gamepad", "pad" },
  description = "Your Gamepad UI bars, drawn like the controller HUD: hold a trigger, or both, to see that bar. Next set cycles sets 1-3.",
  views = { { key = "1", label = "1 · Combat" }, { key = "2", label = "2 · Utility" }, { key = "3", label = "3 · Pet & Extras" } },
  view = "1",
  viewLabel = "Next set",
  toggles = {
    { key = "mode", labels = { "HUD", "List" }, get = function(p) return p.mode end, set = SetMode },
    { key = "after", labels = { "Now", "After" }, get = function(p) return p.after end, set = function(p, i) p.after = i end },
  },
  prompts = function() return { { key = "PAD1", label = "Pin" }, { key = "PAD3", label = "Next set" } } end,
  disableFrameFocusPaging = true,

  Build = function(page, stage, pane)
    page.pane = pane
    page.current = tonumber(page.view) or 1
    page.mode = (ns.db and ns.db.controllerView == 2) and 2 or 1
    page.after = 2
    page.titles = LayoutTitles()
    for i = 1, 3 do page.views[i].label = TabLabel(i, page.titles[i]) end

    -- Stage art: the character sheet's backdrop (the Keyboard page's too,
    -- so the two pages match), else the class talent background, darkened
    -- toward the bottom.
    local bg = stage:CreateTexture(nil, "BACKGROUND", nil, 1)
    bg:SetPoint("TOPLEFT", 3, -3)
    bg:SetPoint("BOTTOMRIGHT", -3, 3)
    local _, class = UnitClass("player")
    local talents = class and ("talents-background-" .. class:lower()) or nil
    if not UI.SetAtlas(bg, UI.ART.generalBg)
      and not UI.SetAtlas(bg, { talents and (talents .. "-beastmastery") or "", talents or "" }) then bg:Hide() end
    local shade = UI.Gradient(stage, "BACKGROUND", "VERTICAL", { 0, 0, 0, 0.6 }, { 0, 0, 0, 0.2 }, 2)
    shade:SetPoint("TOPLEFT", 3, -3)
    shade:SetPoint("BOTTOMRIGHT", -3, 3)

    page.content = CreateFrame("Frame", nil, stage)
    page.content:SetAllPoints()
    BuildHUD(page, page.content)
    BuildList(page, page.content)

    -- v1 field names, kept for tests: slots by page-unit slot ID (1-32).
    page.slots = {}
    for layer = 0, 3 do
      for name, s in pairs(page.bars[layer].slots) do page.slots[SlotOf(layer, name)] = s end
    end

    page.empty = UI.Empty(stage, "")
    page.empty:Hide()
    UI.WatchModifiers(stage, function(shift, ctrl) OnModifiers(page, shift, ctrl) end)
  end,

  OnView = function(page, key) page.current = tonumber(key) or 1 end,
  -- v1 hook (ignored by the v2 shell, where LB/RB always change page).
  OnShoulder = function(page, delta)
    if not page.plan then return false end
    page.current = (page.current - 1 + delta) % 3 + 1
    page.view = tostring(page.current)
    ns.UI.Refresh()
    return true
  end,

  Refresh = function(page)
    local plan = M.Plan()
    page.plan = plan
    if not plan then
      page.content:Hide()
      page.empty:SetText("No controller layout for " .. tostring(UnitClass("player")) .. " yet.")
      page.empty:Show()
      return
    end
    page.empty:Hide()
    page.content:Show()
    local list = page.mode == 2
    page.hud:SetShown(not list)
    page.listHost:SetShown(list)
    local set = page.current
    local inPlace, homes = 0, 0
    for layer = 0, 3 do
      for _, name in ipairs(UI.PAD_BUTTONS) do
        local d = Describe(plan, set, SlotOf(layer, name))
        FillSlot(page, page.bars[layer].slots[name], d)
        FillCell(page, page.cells[layer][name], d)
        if not d.fixed and d.state ~= "empty" then
          homes = homes + 1
          if d.state == "same" then inPlace = inPlace + 1 end
        end
      end
    end
    page.setNum:SetText(tostring(set))
    page.setName:SetText(page.titles[set] or (plan[set] and plan[set].title) or "")
    page.setCount:SetText(string.format("%d of %d buttons in place", inPlace, homes))
    local off = not Gamepad()
    page.offPlate:SetShown(off)
    page.legend:SetShown(not off)
    for key, sk in pairs(page.paddles) do FillPaddle(sk, plan.paddles[key]) end
    UpdateBars(page)
  end,

  Status = function(page)
    local p = page.plan
    if not p then return "" end
    local C = UI.C
    local parts, tip = {}, {}
    -- First, so a truncated summary never hides it.
    if not Gamepad() then
      parts[#parts + 1] = C.ORANGE:WrapTextInColorCode("Gamepad UI off")
      tip[#tip + 1] = "Gamepad UI off: Apply binds only the back buttons. Turn it on in Options > Controls > Gamepad."
    end
    parts[#parts + 1] = p.changes > 0 and C.ADDED:WrapTextInColorCode(Count(p.changes, "%d change ready", "%d changes ready")) or "Up to date"
    if p.missing > 0 then
      parts[#parts + 1] = C.MISSING:WrapTextInColorCode(Count(p.missing, "%d waiting to learn", "%d waiting to learn"))
      local names, more = {}, #p.missingNames - 10
      for i = 1, math.min(10, #p.missingNames) do names[i] = p.missingNames[i] end
      tip[#tip + 1] = "Waiting: " .. table.concat(names, ", ") .. (more > 0 and (", and " .. more .. " more.") or ".")
    end
    if (p.unplaced or 0) > 0 then
      parts[#parts + 1] = Count(p.unplaced, "%d spell without a button", "%d spells without a button")
      tip[#tip + 1] = "Every overflow button on set 3 is taken; the rest of your spells have no controller button."
    end
    return table.concat(parts, "  ·  "), #tip > 0 and tip or nil
  end,

  readiness = function(page)
    local p = page.plan
    if not p or not Gamepad() then return nil end
    local done, total = 0, 0
    for set = 1, #p do
      for _, e in pairs(p[set]) do
        if type(e) == "table" and e.item then
          total = total + 1
          if e.state == "same" then done = done + 1 end
        end
      end
    end
    return done, total
  end,

  -- The Review sheet: every change Apply makes, on all three sets and the
  -- back buttons (the count matches plan.changes).
  Review = function(page)
    local p = page.plan
    if not p then return nil end
    local place, clear, backs = {}, {}, {}
    for set = 1, #p do
      for slotID = 1, 32 do
        local layer, name = math.floor((slotID - 1) / 8), NAME_OF[(slotID - 1) % 8 + 1]
        local sortKey = "Set " .. set .. " · " .. Chord(layer, name)
        local key = "Set " .. set .. " · " .. ChordGlyphs(layer, name)
        local e = p[set][slotID]
        local storage = Storage(set, slotID)
        local now = storage and HasAction(storage) and UI.DescribeSlot(storage) or nil
        if e and e.state == "new" then
          place[#place + 1] = { key = key, sortKey = sortKey, nowIcon = now and now.icon, nowName = now and now.name or "Empty",
            afterIcon = Icon(e.item), afterName = e.item.name, note = now and (now.name == e.item.name and (now.actionKind == "macro" and "macro to spell" or "updates") or "replaces") or nil, color = UI.C.ADDED }
        elseif (e and e.state == "clear") or (not e and now) then
          clear[#clear + 1] = { key = key, sortKey = sortKey, nowIcon = now and now.icon, nowName = now and now.name or "Empty",
            afterName = "Empty", note = e and ("waits for " .. tostring(e.item.missing)) or "not in the layout", color = UI.C.REMOVED }
        end
      end
    end
    for _, key in ipairs(PADDLE_ORDER) do
      local pp = p.paddles[key]
      if pp and (pp.state == "new" or pp.state == "clear") then
        local now = pp.current ~= "" and UI.DescribeCommand(pp.current) or nil
        backs[#backs + 1] = { key = PaddleLabel(key), nowIcon = now and now.icon, nowName = now and now.name or "Not bound",
          afterIcon = pp.state == "new" and Icon(pp.item) or nil, afterName = pp.state == "new" and pp.item.name or "Not bound",
          note = pp.state == "clear" and "kept free" or nil, color = pp.state == "new" and UI.C.ADDED or UI.C.REMOVED }
      end
    end
    local groups = {}
    if #place > 0 then groups[#groups + 1] = { title = "WILL PLACE", items = place } end
    if #clear > 0 then groups[#groups + 1] = { title = "WILL CLEAR", items = clear } end
    if #backs > 0 then groups[#groups + 1] = { title = "BACK BUTTONS", items = backs } end
    return groups
  end,
  reviewNote = function(page)
    local p = page.plan
    local parts = {}
    if not Gamepad() then parts[#parts + 1] = "The Gamepad UI is off, so Apply binds only the back buttons." end
    if p and p.missing > 0 then parts[#parts + 1] = Count(p.missing, "%d home waits for a spell you don't have yet and stays empty.", "%d homes wait for spells you don't have yet and stay empty.") end
    parts[#parts + 1] = "Your current layout is saved for Undo Last Apply."
    return table.concat(parts, " ")
  end,
  Commit = function(page)
    local ids = {}
    local p = page.plan
    if p and p[page.current] then
      for layer = 0, 3 do
        for _, name in ipairs(UI.PAD_BUTTONS) do
          local e = p[page.current][SlotOf(layer, name)]
          if e and (e.state == "new" or e.state == "clear") then
            ids[#ids + 1] = (page.mode == 2 and "list:" or "pad:") .. layer .. ":" .. name
          end
        end
      end
    end
    M.Apply()
    return nil, nil, ids
  end,

  DefaultFocus = function(page)
    -- cells is indexed by layer 0-3; layer 0 (no trigger) is the leftmost column.
    if page.mode == 2 then return page.cells and page.cells[0] and page.cells[0].Up end
    return page.bars and page.bars[0].slots.Up
  end,
  -- Right stick: the Inspector (the HUD and List fit the stage), so its
  -- bar card and notes can be read when they run below the fold.
  ScrollRegion = function(p) return p.pane and p.pane.scroll or nil end,
  DefaultInspect = function(page, pane)
    if not page.plan or not page.bars then error("no plan") end
    pane:Header("Interface\\Icons\\INV_Gizmo_02", TabLabel(page.current, page.titles[page.current]),
      "Controller set " .. page.current .. " of 3")
    pane:BarCard(Rows(page, page.held or 0, ns.Focus.current))
    local lt, rt = PadName("PADLTRIGGER"), PadName("PADRTRIGGER")
    pane:Text(string.format("Hold %s, %s or both (Shift, Ctrl on the keyboard) to see that bar. Pet radials (%s + %s, %s + %s) are filled by the Gamepad UI itself.",
      lt, rt, PadName("PADLSHOULDER"), lt, PadName("PADRSHOULDER"), rt), UI.C.GRAY)
    pane:Text("Items on the controller: the Hearthstone, the Cozy Sleeping Bag and your on-use trinkets, each placed once you carry or equip it. Nothing else from your bags.", UI.C.GRAY)
  end,

  actions = {
    { label = "Undo Last Apply", fn = M.Undo,
      enabled = function() return M.charDB ~= nil and M.charDB.backup ~= nil end,
      confirm = "Put back the controller bars and back-button keys from before the last Apply?",
      tooltip = "Put back the controller bars and back-button keys from before the last Apply." },
  },
})

ns.RegisterCommand("controller", "open Controller, or apply/undo the layout", function(arg)
  arg = (arg or ""):lower()
  if arg == "apply" then M.Apply() elseif arg == "undo" then M.Undo() else ns.OpenPage("controller") end
end, { usage = "controller [apply|undo]", module = "Controller" })
