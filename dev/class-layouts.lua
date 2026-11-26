-- Writes dev/class-layouts.md from the layout and macro data, so the owner
-- can review every class in one place. Run from the repo root:
--   luajit dev/class-layouts.lua > dev/class-layouts.md
-- It loads only Layouts/*.lua and Macros/Data/<Class>.lua with a stub
-- `ns`, so it needs no WoW mock. Keep the role guide below in step with
-- dev/key-roles.md.
local ADDON = "addon/Agentcraft/"
local CLASSES = {
  { "HUNTER", "Hunter" }, { "WARRIOR", "Warrior" }, { "PALADIN", "Paladin" },
  { "ROGUE", "Rogue" }, { "PRIEST", "Priest" }, { "SHAMAN", "Shaman" },
  { "MAGE", "Mage" }, { "WARLOCK", "Warlock" }, { "DRUID", "Druid" },
}
local KEYS = { "Q", "E", "R", "T", "F", "G", "C", "V", "1", "2", "3", "4" }
local ROLE = {
  "rotation 1", "rotation 2", "rotation 3", "rotation 5",
  "rotation 4", "proc", "mobility", "snare",
  "opener", "main AoE", "interrupt", "second AoE",
}
local SHIFT_ROLE = {
  "self-heal", "spec defensive", "burst", "spec control",
  "hard CC", "AoE control", "racial", "emergency",
  "buff row", "buff row", "buff row", "buff row",
}
-- Controller page 1 in key-roles order: button, role.
local PAD = {
  { "RT A", "Q" }, { "RT X", "E" }, { "RT Y", "R" }, { "RT B", "F" },
  { "LT A", "T" }, { "LT X", "G" }, { "LT B", "3" }, { "LT Y", "2" },
  { "RT Up", "1" }, { "RT Down", "4" }, { "RT Left", "C" }, { "RT Right", "V" },
  { "LT Up", "Shift+Q" }, { "LT Right", "Shift+E" }, { "LT Left", "Shift+T" }, { "LT Down", "Shift+F" },
  { "LT+RT A", "Shift+V" }, { "LT+RT X", "Shift+G" }, { "LT+RT B", "racial" }, { "LT+RT Y", "Shift+R" },
  { "LT+RT Up", "Ctrl+Q" }, { "LT+RT Down", "Ctrl+E" }, { "LT+RT Left", "Ctrl+R" }, { "LT+RT Right", "Ctrl+T" },
  { "none Up", "radial / buff" }, { "none Left", "utility" }, { "none Right", "class basic" }, { "none Down", "basic" },
}

local layouts, macros, sharedDef = {}, {}, nil
local ns = {
  Layout = { Register = function(class, data) layouts[class] = data end,
    RegisterShared = function(data) sharedDef = data end },
  MacroLibrary = { Add = function(m) macros[#macros + 1] = m end, previous = {}, retired = {} },
}
local function Load(path)
  local f = assert(loadfile(ADDON .. path))
  f("Agentcraft", ns)
end

local out = {}
local function P(s) out[#out + 1] = s or "" end

local function Entry(e)
  if e == nil then return "" end
  if e == false then return "-" end
  local parts = {}
  for _, s in ipairs(e) do parts[#parts + 1] = s end
  local text = table.concat(parts, " / ")
  if e.racial then text = "racial" end
  if e.item then text = e.item end
  if e.utility then text = "trinket " .. e.utility end
  if e.overflow then text = "overflow" end
  if e.petauto then text = "pet autocast" end
  if e.profession then text = "profession " .. e.profession end
  if e.flyout then text = text .. " (radial)" end
  if e.macro then text = (text ~= "" and (text .. " ") or "") .. "[" .. e.macro .. "]" end
  return (text:gsub("|", "/"))
end

-- A spec's keyboard: shared pieces, replaced by the spec's own.
local function Keyboard(data, spec)
  local kb = { stances = {} }
  local shared = data.keyboard or {}
  for _, bar in ipairs({ 1, 2, 4 }) do kb[bar] = shared[bar] end
  for k, v in pairs(shared.stances or {}) do kb.stances[k] = v end
  local own = spec and spec.keyboard or {}
  for _, bar in ipairs({ 1, 2, 4 }) do if own[bar] then kb[bar] = own[bar] end end
  for k, v in pairs(own.stances or {}) do kb.stances[k] = v or nil end
  return kb
end

local function Stances(kb)
  local list = {}
  for key, page in pairs(kb.stances) do list[#list + 1] = { key = key, page = page } end
  table.sort(list, function(a, b) return a.page.offset < b.page.offset end)
  return list
end

local function KeyboardTable(kb)
  local stances = Stances(kb)
  local head, rule = { "Key", "Role", "Plain" }, { "---", "---", "---" }
  for _, s in ipairs(stances) do
    head[#head + 1] = s.page.label or s.key
    rule[#rule + 1] = "---"
  end
  for _, h in ipairs({ "Shift", "Shift role", "Ctrl" }) do head[#head + 1] = h; rule[#rule + 1] = "---" end
  P("| " .. table.concat(head, " | ") .. " |")
  P("| " .. table.concat(rule, " | ") .. " |")
  for i = 1, 12 do
    local row = { KEYS[i], ROLE[i], Entry(kb[1] and kb[1][i]) }
    for _, s in ipairs(stances) do row[#row + 1] = Entry(s.page[i]) end
    row[#row + 1] = Entry(kb[2] and kb[2][i])
    row[#row + 1] = SHIFT_ROLE[i]
    row[#row + 1] = Entry(kb[4] and kb[4][i])
    P("| " .. table.concat(row, " | ") .. " |")
  end
end

local function PadTable(page)
  P("| Button | Mirrors | Spell | Button | Mirrors | Spell |")
  P("| --- | --- | --- | --- | --- | --- |")
  local half = #PAD / 2
  for i = 1, half do
    local a, b = PAD[i], PAD[i + half]
    P(("| %s | %s | %s | %s | %s | %s |"):format(a[1], a[2], Entry(page[a[1]]), b[1], b[2], Entry(page[b[1]])))
  end
end

-- Controller page 2's own (class) buttons, in a fixed button order.
local PAGE2_ORDER = {}
for _, layer in ipairs({ "RT", "LT", "none", "LT+RT" }) do
  for _, b in ipairs({ "A", "X", "B", "Y", "Up", "Down", "Left", "Right" }) do PAGE2_ORDER[#PAGE2_ORDER + 1] = layer .. " " .. b end
end
local function Page2Table(page)
  local rows = {}
  for _, key in ipairs(PAGE2_ORDER) do
    if page[key] ~= nil then rows[#rows + 1] = ("| %s | %s |"):format(key, Entry(page[key])) end
  end
  if #rows == 0 then P("Only the shared buttons.") return end
  P("| Button | Class button |")
  P("| --- | --- |")
  for _, r in ipairs(rows) do P(r) end
end

local function HasKeyboard(spec)
  local k = spec.keyboard
  return k and (k[1] or k[2] or k[4] or k.stances) and true or false
end

P("# Class layouts")
P()
P("Generated from `addon/Agentcraft/Layouts/*.lua` and `Macros/Data/*.lua` by `luajit dev/class-layouts.lua > dev/class-layouts.md`; regenerate after a layout change. The reasoning for each key is in the layout files' comments.")
P()
P("## Role guide")
P()
P("The keybinds are the same for every class (hard rule): plain keys = Action Bar 1, Shift = Bar 2, Ctrl = Bar 4, Alt = Bar 3 (shared item macros: HealPot Alt+Q, ManaPot Alt+E, Bandage Alt+R, Food Alt+T, Fish Alt+F, Bait Alt+G; trinkets Alt+C/V, Hearthstone Alt+4), pet bar on the mouse and Z/X. Each spec's rotation fills the slots in press-frequency order ([dev/key-roles.md](key-roles.md)):")
P()
P("| Key | Plain | Shift | Ctrl |")
P("| --- | --- | --- | --- |")
local CTRL_ROLE = { "secondary attack / debuff", "secondary debuff", "secondary utility attack", "spec utility", "utility", "utility", "utility", "utility", "buff / summon / create", "buff / summon / create", "buff / summon / create", "buff / summon / create" }
for i = 1, 12 do P(("| %s | %s | %s | %s |"):format(KEYS[i], ROLE[i], SHIFT_ROLE[i], CTRL_ROLE[i])) end
P()
P("- Stance pages (warrior stances, druid forms, rogue Stealth, Shadowform) keep the roles; the stance only changes which spell fills one.")
P("- Tanks: threat priority, taunt, interrupt and AoE threat fill the rotation slots. Healers (Holy paladin, Discipline and Holy priest, Restoration shaman and druid): heals and dispel fill the rotation slots; damage moves a tier down.")
P("- Controller page 1: the rotation on face buttons (the left thumb steers, so D-pad presses stop you): RT A X Y B = plain Q E R F, LT A X B Y = plain T G 3 2; RT D-pad = plain 1 4 C V; LT D-pad = Shift Q E T F; LT+RT = Shift V G R, the racial and Ctrl Q E R T; no trigger = radials and basics. Page 2 is utility: the class's own buttons (resurrects, buffs, portals...) plus the shared buttons below, page 3 pet and Steam Deck extras plus overflow.")
P()
Load("Layouts/Shared.lua")
local sharedPage2 = sharedDef and sharedDef.controller and sharedDef.controller.pages and sharedDef.controller.pages[2] or {}
P("## Shared controller page 2")
P()
P("`Layouts/Shared.lua` merges these buttons into every class's page 2, for every spec and character; a class page holds only its own buttons (listed per class below). `profession N` = the Nth of the character's profession spells in one stable order: first primary profession's own spell, second primary's, Cooking, First Aid, fishing helpers (Bait and Tackle), then gathering and utility spells (Find Minerals, Find Herbs, Smelting, Disenchant, Prospecting, Milling, Survey), then any other profession spell. Fewer professions leave the last slots empty. Keyboard: the same professions, in the same order, sit on Action Bar 6 after tracking.")
P()
P("| Button | Shared button |")
P("| --- | --- |")
for _, key in ipairs(PAGE2_ORDER) do
  if sharedPage2[key] ~= nil then P(("| %s | %s |"):format(key, Entry(sharedPage2[key]))) end
end
P()
P("Notation: `A / B` = the first spell you know (talent or rank chains), `[Name]` = a library macro that takes the key once installed (until then the spell before it, or nothing), `-` = empty on purpose. Spells without a key go to the side bars (Action Bars 5-8).")

for _, c in ipairs(CLASSES) do
  local class, title = c[1], c[2]
  Load("Layouts/" .. title .. ".lua")
  local mark = #macros
  local ok = pcall(Load, "Macros/Data/" .. title .. ".lua")
  local data = layouts[class]
  P()
  P("## " .. title)
  if not data then
    P()
    P("No layout.")
  else
    local shared, own = {}, {}
    for _, s in ipairs(data.specs) do
      local name = s.name .. (s.default and " (leveling)" or "")
      if HasKeyboard(s) then own[#own + 1] = s else shared[#shared + 1] = name end
    end
    if #shared > 0 then
      P()
      P("### Keyboard: " .. table.concat(shared, ", "))
      P()
      KeyboardTable(Keyboard(data, nil))
    end
    for _, s in ipairs(own) do
      P()
      P("### Keyboard: " .. s.name .. (s.default and " (leveling)" or "") .. " (own bars)")
      P()
      KeyboardTable(Keyboard(data, s))
    end
    local pages = data.controller and data.controller.pages
    if pages then
      local sharedPad = {}
      for _, s in ipairs(data.specs) do
        if not (s.controller and s.controller.pages and s.controller.pages[1]) then sharedPad[#sharedPad + 1] = s.name end
      end
      if #sharedPad > 0 then
        P()
        P("### Controller page 1: " .. table.concat(sharedPad, ", "))
        P()
        PadTable(pages[1])
      end
      for _, s in ipairs(data.specs) do
        local p1 = s.controller and s.controller.pages and s.controller.pages[1]
        if p1 then
          P()
          P("### Controller page 1: " .. s.name)
          P()
          PadTable(p1)
        end
      end
      local p2spec = {}
      for _, s in ipairs(data.specs) do
        if not (s.controller and s.controller.pages and s.controller.pages[2]) then p2spec[#p2spec + 1] = s.name end
      end
      if #p2spec > 0 and pages[2] then
        P()
        P("### Controller page 2 (class buttons): " .. table.concat(p2spec, ", "))
        P()
        Page2Table(pages[2])
      end
      for _, s in ipairs(data.specs) do
        local p2 = s.controller and s.controller.pages and s.controller.pages[2]
        if p2 then
          P()
          P("### Controller page 2 (class buttons): " .. s.name)
          P()
          Page2Table(p2)
        end
      end
    end
  end
  P()
  P("### Macros")
  P()
  if not ok or #macros == mark then
    P("None.")
  else
    local auto = {}
    for i = mark + 1, #macros do
      local m = macros[i]
      if m.petAbility then auto[#auto + 1] = m.petAbility
      else P(("- **%s** (%s): %s"):format(m.name, m.category, (m.desc or ""):gsub("|", "/"))) end
    end
    if #auto > 0 then
      P("- **Auto <ability>** (pet): controller autocast toggles for " .. table.concat(auto, ", ") .. ".")
    end
  end
end

io.write(table.concat(out, "\n"), "\n")
