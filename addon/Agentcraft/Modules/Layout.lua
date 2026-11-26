-- Layout: per-class layouts, designed separately for each device.
--
--   Keyboard: plain keybinds, no flyouts. Bar 1 = Q E R T F G C V 1 2 3 4,
--   bar 2 = Shift + the same keys, bar 4 = Ctrl + the same keys. Bar 3, the
--   Alt bar (Fish and Bait macros, on-use trinkets, the Hearthstone), and the click-only side
--   bars (Action Bars 5-8: everything else you know, each spell once, and
--   the Cozy Sleeping Bag) are filled by ActionBars.
--
--   Bag items: only the Hearthstone, the Cozy Sleeping Bag and your equipped
--   on-use trinkets go on any bar, on either device (owner rules, 2026-11-22;
--   the bag is a click-only side-bar slot on the keyboard). No food, drink,
--   potions, bandages, bombs, gadgets or elixirs.
--
--   Controller: built for the Gamepad UI and the Steam Deck: trigger layers,
--   radials (spell flyouts) and back buttons. Page 3 holds Deck helpers and a
--   catch-all, so every spell you know is reachable without a keyboard.
--
-- Rules for both, so a layout never feels weird:
--   * Every spell has one permanent home. It never moves when you learn more.
--   * A home lists alternatives only when they're either-or: talents from
--     different builds (Bestial Wrath / Deterrence / Trueshot Aura), or an
--     upgrade in the same role (Explosive Trap replaces Immolation Trap).
--   * No spell appears in two homes on the same device. Exception: Bar 1's
--     stance pages may repeat a spell on the same key (Execute on R in
--     Battle and Berserker Stance): the key is its one home.
--   * Homes for spells you haven't learned stay empty until you do.
-- Entry forms (resolved in Controller.lua):
--   { "Spell", "Alternative" }        first one you know
--   { "Better", "Lower", upgrade = true }  a same-role upgrade: once you know the
--                                     better one, the lower one needs no home
--                                     (side bars and the controller catch-all skip it)
--   { macro = "Arcane", "Arcane Shot" } the macro if you installed it, else the spell
--   { macro = "FD", "Feign Death", "Disengage" } before you know Feign Death, Disengage
--   { macro = "Bait" }                macro only: the macro once you installed it;
--                                     until then the home waits (no spell to fall back on)
--   { flyout = 253, "Aspect of the Hawk" } a spellbook flyout (radial on a controller)
--   { utility = 7 }                   the item for ActionBars.utility[7] (7 and 8:
--                                     the equipped on-use trinkets)
--   { item = "Hearthstone" }          that item, wherever it is in your bags (only
--                                     names in ActionBars.BAG_ITEMS are placed)
--   { racial = true }                 your race's active racial
--   { macro = "PetCare", "Mend Pet", covers = { ... } } other spells the macro casts, so
--                                     the controller catch-all skips them
--   { petauto = true }                controller only: an autocast toggle for
--                                     your pet's next autocastable ability
--                                     (its library "Auto <ability>" macro, once
--                                     you've installed it; Apply never creates it)
--   { overflow = true }               controller only: a spell you know that
--                                     has no other controller home
--   { profession = 3 }                controller only: your 3rd profession spell
--                                     in the stable L.PROFESSIONS order
--                                     (ActionBars.ProfessionSpells); waits
--                                     when you have fewer
--   false                          (in a 12-entry bar) a key left empty on purpose
--
-- Specs and stance pages (the full contract is dev/layout-format.md):
--   Each class's data lives in Layouts/<Class>.lua and registers itself:
--     ns.Layout.Register("WARRIOR", {
--       specs = { { key = "arms", name = "Arms", tab = 1 }, ..., { key = "prot", ..., default = true } },
--       keyboard = { [1] = {...}, [2] = {...}, [4] = {...}, stances = { battle = { offset = 1, label = "Battle", ... } } },
--       controller = { pages = { {...}, {...}, {...} }, paddles = {} },
--     })
--   keyboard/controller at the top are shared by every spec. A spec may add
--   its own keyboard/controller; they replace whole pieces, never parts of
--   one: a keyboard bar ([1], [2], [4]), one stance page (stances.<key>, or
--   false to drop it), a controller page (pages[n]) or the paddles.
--   Shared buttons (Layouts/Shared.lua, L.RegisterShared): the controller
--   buttons every class and character gets, merged into the class page of
--   the same number when a layout resolves (page 2: Hearthstone, trinkets,
--   Fish, Bait, camp, Mount and 8 profession slots). A class page never
--   names a shared button [rules].
--   The active spec: the character's choice (AgentcraftCharDB.spec), else
--   the talent tab with the most points; below level 10 or with no points,
--   the spec marked default (the leveling spec).
--   Stance pages: Bar 1 (slots 1-12) is the no-stance page; in a stance, form
--   or stealth the game shows bonus bar <offset> instead, slots
--   72 + (offset - 1) * 12 + 1..12 (offset 1 = 73-84, 2 = 85-96, 3 = 97-108,
--   4 = 109-120). ACTIONBUTTON1-12 follow the page by themselves, so binds
--   need nothing extra. The Gamepad UI bars don't page (their storage slots
--   depend on the gamepad page only), so controller layouts are
--   stance-independent: stance-dance macros cover it there.
local _, ns = ...
local L = {}
ns.Layout = L

-- Registered classes: [CLASS] = the table given to Register.
L.classes = {}
-- The shared (all-spec) layouts by class, the tables Register was given.
-- Code that edits a layout at run time (tests) edits these.
L.keyboard = {}
L.controller = {}

-- The shared controller buttons (Layouts/Shared.lua):
-- { controller = { pages = { [2] = { title =, ["RT Up"] = entry, ... } } } }.
L.shared = { controller = { pages = {} } }

function L.RegisterShared(def)
  assert(type(def) == "table", "Layout.RegisterShared({ controller = { pages = { [n] = { ... } } } })")
  def.controller = def.controller or {}
  def.controller.pages = def.controller.pages or {}
  L.shared = def
end

-- Profession spells for the shared { profession = n } slots and Action Bar
-- 6, in one stable order (ActionBars.ProfessionSpells builds it from your
-- professions):
--   1. your first primary profession's own spell (Mining, Alchemy...),
--   2. your second primary's,
--   3. Cooking, 4. First Aid, 5. fishing helpers (Bait and Tackle),
--   6. then your professions' gathering and utility spells in `utility`
--      order (Find Minerals, Find Herbs, Smelting, Disenchant...), then any
--      other profession spell alphabetically.
-- A slot is skipped (the rest move up) when you lack that profession.
-- Fishing (the Fish home) and Basic Campfire (the camp home) have shared
-- buttons of their own and never take a profession slot. A class layout
-- never names a spell listed here [rules]: the shared slots are its home.
L.PROFESSIONS = {
  primary = { "Alchemy", "Blacksmithing", "Enchanting", "Engineering", "Herbalism", "Inscription",
    "Jewelcrafting", "Leatherworking", "Mining", "Skinning", "Tailoring" },
  secondary = { "Cooking", "First Aid" },
  fishing = { "Bait and Tackle" },
  -- Dedicated Study: the Legacy perk (Professions tree) that raises your
  -- lowest profession by 1 (25 s cast, 23 h cooldown; Wowhead, Legacy System Overview).
  utility = { "Find Minerals", "Find Herbs", "Smelting", "Disenchant", "Prospecting", "Milling", "Survey", "Dedicated Study" },
  -- Lines GetProfessions returns that are not primaries.
  lines = { ["Cooking"] = true, ["First Aid"] = true, ["Fishing"] = true, ["Archaeology"] = true },
  skip = { ["Fishing"] = true, ["Basic Campfire"] = true },
}

-- name -> true for every spell L.PROFESSIONS lists (the rules: no class home).
function L.ProfessionSpellNames()
  local out = {}
  local P = L.PROFESSIONS
  for _, list in ipairs({ P.primary, P.secondary, P.fishing, P.utility }) do
    for _, n in ipairs(list) do out[n] = true end
  end
  return out
end

-- Classic offsets of the bonus bars (API GetBonusBarOffset): which stance
-- page a class's stance keys mean. Display and docs; data names the offset.
L.STANCE_OFFSETS = {
  WARRIOR = { battle = 1, defensive = 2, berserker = 3 },
  DRUID = { cat = 1, bear = 3, moonkin = 4 },
  ROGUE = { stealth = 1 },
  PRIEST = { shadowform = 1 },
}

function L.Register(class, def)
  assert(type(class) == "string" and type(def) == "table", "Layout.Register(CLASS, { ... })")
  def.specs = def.specs or {}
  L.classes[class] = def
  L.keyboard[class] = def.keyboard
  L.controller[class] = def.controller
end

-- Specs ---------------------------------------------------------------------------

function L.Specs(class)
  local def = L.classes[class]
  return def and def.specs or {}
end

function L.SpecByKey(class, key)
  for _, s in ipairs(L.Specs(class)) do if s.key == key then return s end end
end

local function DefaultSpec(specs)
  for _, s in ipairs(specs) do if s.default then return s end end
  return specs[1]
end

local function Num(v)
  if issecretvalue and issecretvalue(v) then return 0 end
  return tonumber(v) or 0
end

-- Points per talent tab, in tab order: { { name =, points = }, ... }, plus
-- where they came from ("traits" or "tabs"); nil when the client tells
-- nothing. WoW Forever (game type "camelot") has one trait tree per class
-- whose node groups are the three talent tabs: Blizzard_ClassTalentsFrame
-- (Camelot) draws a header per group from C_Traits.GetGroupDisplayInfoByTreeID
-- and its points from C_Traits.GetGroupCurrencyInfo (currencyInfos[1].spent).
-- Classic clients have GetTalentTabInfo instead.
function L.TalentTabs()
  if C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_Traits and C_Traits.GetConfigInfo
    and C_Traits.GetGroupDisplayInfoByTreeID and C_Traits.GetGroupCurrencyInfo then
    local ok, tabs = pcall(function()
      local configID = C_ClassTalents.GetActiveConfigID()
      local cfg = configID and C_Traits.GetConfigInfo(configID)
      local treeID = type(cfg) == "table" and type(cfg.treeIDs) == "table" and cfg.treeIDs[1]
      if not treeID then return nil end
      local infos = C_Traits.GetGroupDisplayInfoByTreeID(treeID)
      if type(infos) ~= "table" or #infos == 0 then return nil end
      local list = {}
      for _, d in ipairs(infos) do list[#list + 1] = d end
      table.sort(list, function(a, b) return Num(a.orderIndex) < Num(b.orderIndex) end)
      local ids = {}
      for i, d in ipairs(list) do ids[i] = d.groupID end
      local spent = {}
      for _, g in ipairs(C_Traits.GetGroupCurrencyInfo(configID, ids) or {}) do
        local c = type(g.currencyInfos) == "table" and g.currencyInfos[1]
        spent[g.traitNodeGroupID] = c and Num(c.spent) or 0
      end
      local out = {}
      for i, d in ipairs(list) do out[i] = { name = d.displayName, points = spent[d.groupID] or 0 } end
      return out
    end)
    if ok and tabs then return tabs, "traits" end
  end
  if GetNumTalentTabs and GetTalentTabInfo then
    local ok, tabs = pcall(function()
      local out = {}
      for tab = 1, Num(GetNumTalentTabs()) do
        -- Classic Era: name, icon, pointsSpent; Cataclysm and later: id, name, desc, icon, pointsSpent.
        local a, b, c, _, e = GetTalentTabInfo(tab)
        if type(a) == "string" then out[tab] = { name = a, points = Num(c) }
        elseif a ~= nil then out[tab] = { name = b, points = Num(e) } end
      end
      return #out > 0 and out or nil
    end)
    if ok and tabs then return tabs, "tabs" end
  end
end

-- The spec a talent tab stands for: by name when the tab has one (tab order
-- on WoW Forever is not verified), else by spec.tab.
local function SpecForTab(specs, tab, name)
  if type(name) == "string" and name ~= "" then
    local n = name:lower()
    for _, s in ipairs(specs) do
      local sn = (s.name or ""):lower()
      if sn ~= "" and (n == sn or n:find(sn, 1, true) or sn:find(n, 1, true)) then return s end
    end
  end
  for _, s in ipairs(specs) do if s.tab == tab then return s end end
end

-- The spec the talents point at: (key, why) with why "talents", or the
-- leveling default with why "level" (below 10), "points" (none spent) or
-- "unknown" (the client tells nothing). nil for a class without specs.
function L.DetectSpec(class)
  local specs = L.Specs(class)
  if #specs == 0 then return nil end
  local default = DefaultSpec(specs)
  if Num(UnitLevel and UnitLevel("player")) < 10 then return default.key, "level" end
  local tabs = L.TalentTabs()
  if not tabs then return default.key, "unknown" end
  local best, bestPts, total, pts = nil, 0, 0, {}
  for tab, t in ipairs(tabs) do
    total = total + t.points
    local s = SpecForTab(specs, tab, t.name)
    if s then
      pts[s.key] = (pts[s.key] or 0) + t.points
      if pts[s.key] > bestPts then best, bestPts = s, pts[s.key] end
    end
  end
  if total == 0 or not best then return default.key, "points" end
  -- A tie keeps the leveling spec when it is one of the tied.
  if (pts[default.key] or 0) == bestPts then best = default end
  return best.key, "talents"
end

-- The character's choice: a spec key, or nil for Automatic.
function L.SpecChoice(class)
  local c = ns.charDB and ns.charDB.spec
  if type(c) == "string" and L.SpecByKey(class, c) then return c end
  return nil
end

-- key = a spec key, or nil / "auto" for Automatic.
function L.SetSpecChoice(key)
  if not ns.charDB then return end
  ns.charDB.spec = (key and key ~= "auto") and key or nil
end

-- The spec in use: (spec table, automatic?, detected key). nil for a class
-- without specs.
function L.ActiveSpec(class)
  local detected = L.DetectSpec(class)
  if not detected then return nil, true end
  local choice = L.SpecChoice(class)
  if choice then return L.SpecByKey(class, choice), false, detected end
  return L.SpecByKey(class, detected), true, detected
end

-- "Automatic (Beast Mastery)", or the chosen spec's name.
function L.SpecLabel(class)
  local spec, auto = L.ActiveSpec(class)
  if not spec then return nil end
  return auto and ("Automatic (" .. spec.name .. ")") or spec.name
end

-- For a spec picker: { { "auto", "Automatic (Arms)" }, { "arms", "Arms" }, ... }
-- and the current choice key ("auto" or a spec key).
function L.SpecChoices(class)
  local out = {}
  local detected = L.DetectSpec(class)
  local d = detected and L.SpecByKey(class, detected)
  if not d then return out end
  out[1] = { "auto", "Automatic (" .. d.name .. ")" }
  for _, s in ipairs(L.Specs(class)) do out[#out + 1] = { s.key, s.name } end
  return out
end
function L.SpecChoiceKey(class) return L.SpecChoice(class) or "auto" end

-- Resolving a spec's layout --------------------------------------------------------

-- A bar or stance page as 12 entries: false (an intentionally empty key)
-- becomes nil, other fields (offset, label) are dropped.
local function Bar(t)
  if type(t) ~= "table" then return nil end
  local out = {}
  for i = 1, 12 do
    local e = t[i]
    if type(e) == "table" then out[i] = e end
  end
  return out
end

local function KeyboardOf(class, spec)
  local base = L.keyboard[class]
  local over = spec and spec.keyboard
  if not over then return base end
  if not base then return over end
  local out = {}
  for k, v in pairs(base) do out[k] = v end
  for k, v in pairs(over) do
    if k == "stances" then
      local st = {}
      for sk, sv in pairs(base.stances or {}) do st[sk] = sv end
      for sk, sv in pairs(v) do st[sk] = sv or nil end
      out.stances = st
    else
      out[k] = v
    end
  end
  return out
end

-- A controller layout with the shared buttons (L.shared) merged into its
-- pages, as a new table (the given one is untouched). A shared button wins
-- over a class entry on the same key; the rules report that as an error.
function L.WithShared(ct)
  if type(ct) ~= "table" then return ct end
  local shared = L.shared and L.shared.controller and L.shared.controller.pages or {}
  local own = ct.pages or {}
  local n = #own
  for i in pairs(shared) do if type(i) == "number" and i > n then n = i end end
  local pages = {}
  for i = 1, n do
    local add = shared[i]
    if add then
      local page = {}
      for k, v in pairs(own[i] or {}) do page[k] = v end
      for k, v in pairs(add) do if k ~= "title" then page[k] = v end end
      page.title = own[i] and own[i].title or add.title
      pages[i] = page
    else
      pages[i] = own[i]
    end
  end
  return { pages = pages, paddles = ct.paddles }
end

local function ControllerOf(class, spec)
  local base = L.controller[class]
  local over = spec and spec.controller
  if not over then return L.WithShared(base) end
  if not base then return L.WithShared(over) end
  local out = { pages = base.pages, paddles = base.paddles }
  if over.pages then
    local pages = {}
    local n = math.max(#(base.pages or {}), 3)
    for i = 1, n do pages[i] = over.pages[i] or (base.pages or {})[i] end
    out.pages = pages
  end
  if over.paddles then out.paddles = over.paddles end
  return L.WithShared(out)
end

-- The spec to resolve: the given key, else the active spec.
local function SpecFor(class, key)
  if key then return L.SpecByKey(class, key) end
  return (L.ActiveSpec(class))
end

-- The merged layout of one spec: { keyboard =, controller = } (either may be nil).
function L.Resolve(class, key)
  local spec = SpecFor(class, key)
  return { keyboard = KeyboardOf(class, spec), controller = ControllerOf(class, spec), spec = spec }
end

-- First action slot (before button 1) of the bonus bar a stance page uses.
function L.BonusFirst(offset) return 72 + (offset - 1) * 12 end

-- The current bonus bar offset (0 = no stance page), or nil when unknown.
function L.BonusOffset()
  local fn = (C_ActionBar and C_ActionBar.GetBonusBarOffset) or GetBonusBarOffset
  if not fn then return nil end
  local ok, v = pcall(fn)
  if not ok or (issecretvalue and issecretvalue(v)) then return nil end
  return tonumber(v)
end

-- Stance pages of a spec's keyboard, by offset: { { key =, label =, offset =,
-- first =, entries = { 12 } }, ... } (empty when it has none).
function L.StancePages(class, key)
  local kb = KeyboardOf(class, SpecFor(class, key))
  local out = {}
  for sk, st in pairs(kb and kb.stances or {}) do
    if type(st) == "table" and tonumber(st.offset) then
      out[#out + 1] = { key = sk, label = st.label or (sk:sub(1, 1):upper() .. sk:sub(2)),
        offset = st.offset, first = L.BonusFirst(st.offset), entries = Bar(st) }
    end
  end
  table.sort(out, function(a, b) return a.offset < b.offset end)
  return out
end

function L.ControllerPages(class, key)
  local c = ControllerOf(class, SpecFor(class, key))
  if not c then return nil end
  return c.pages, c.paddles
end

-- { [1] = 12 entries, [2] = 12 entries, [4] = 12 entries, stances = StancePages }
-- for keyboard bars 1, 2 (Shift) and 4 (Ctrl). [3] stays free for the Alt
-- utility override. nil when the class has no keyboard layout.
function L.KeyboardBars(class, key)
  local k = KeyboardOf(class, SpecFor(class, key))
  if not (k and (k[1] or k[2] or k[4])) then return nil end
  local bars = { Bar(k[1]) or {}, Bar(k[2]) or {}, nil, Bar(k[4]) or {} }
  bars.stances = L.StancePages(class, key)
  return bars
end
