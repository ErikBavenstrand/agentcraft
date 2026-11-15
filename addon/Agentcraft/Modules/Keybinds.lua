-- Keybinds: applies one shared key layout to the action bars and pet bar.
--   /ac keys        show the layout
--   /ac keys apply  apply it (the first apply saves your original binds)
--   /ac keys undo   restore the binds from before the first apply
local _, ns = ...
local M = ns.RegisterModule("Keybinds", {
  title = "Key Bindings",
  order = 20,
  description = "One key layout for Action Bars 1–4 and the pet bar.",
})

-- Same keys on bars 1-4: plain picks bar 1, Shift bar 2, Alt bar 3
-- (utilities), Ctrl bar 4. CTRL-1..4 take over Blizzard's default pet bar
-- keys; the pet bar lives on the mouse and Z/X instead (PET below).
-- Slots: Q E R T | F G | C V | 1 2 3 4  (keyboard rows, number row last)
local KEYS = { "Q", "E", "R", "T", "F", "G", "C", "V", "1", "2", "3", "4" }

-- keys = nil means the bar is managed but left unbound (old binds cleared).
local BARS = {
  { label = "Bar 1",           prefix = "",       command = "ACTIONBUTTON",          keys = KEYS },
  { label = "Bar 2",           prefix = "SHIFT-", command = "MULTIACTIONBAR1BUTTON", keys = KEYS },
  { label = "Bar 3 (utilities)", prefix = "ALT-", command = "MULTIACTIONBAR2BUTTON", keys = KEYS },
  { label = "Bar 4",           prefix = "CTRL-",  command = "MULTIACTIONBAR3BUTTON", keys = KEYS },
}

-- Pet bar slots (Classic): 1 Attack, 2 Follow, 3 Stay, 4-7 abilities,
-- 8 Aggressive, 9 Defensive, 10 Passive.
-- Commands live on the mouse; the 4 abilities on Z/X (+Shift), the free
-- bottom-row keys next to the pinky.
local PET = {
  [1] = "BUTTON5",        -- Attack
  [2] = "BUTTON4",        -- Follow
  [3] = "SHIFT-BUTTON4",  -- Stay
  [4] = "Z",              -- ability 1
  [5] = "X",              -- ability 2
  [6] = "SHIFT-Z",        -- ability 3
  [7] = "SHIFT-X",        -- ability 4
  [8] = "SHIFT-BUTTON3",  -- Aggressive (Shift + wheel click)
  [9] = "BUTTON3",        -- Defensive (wheel click)
  [10] = "SHIFT-BUTTON5", -- Passive
}
local PET_SLOTS = 10

local function Layout()
  local list = {}
  for _, bar in ipairs(BARS) do
    for i = 1, 12 do
      local key = bar.keys and bar.keys[i]
      table.insert(list, { key = key and (bar.prefix .. key), command = bar.command .. i, label = bar.label })
    end
  end
  for i = 1, PET_SLOTS do
    table.insert(list, { key = PET[i], command = "BONUSACTIONBUTTON" .. i, label = "Pet bar" })
  end
  return list
end

local function CopyBackup(t)
  local out = {}
  for k, v in pairs(t) do out[k] = type(v) == "table" and CopyBackup(v) or v end
  return out
end

-- Where the backup lives: per character when this character uses
-- character-specific binds, otherwise account-wide like the binds.
-- Backups from before 0.26 were always account-wide and carry no `set`
-- field. A character on its own binds gets a copy of such a backup once,
-- so Undo still finds its original binds (and Apply doesn't take a new
-- "first" backup of binds that are already the layout).
local function Store()
  local set = GetCurrentBindingSet and GetCurrentBindingSet()
  if set == (_G.CHARACTER_BINDINGS or 2) then
    local c = M.charDB
    if not c.backup and not c.legacyChecked then
      local old = M.db.backup
      if old and not old.set then c.backup = CopyBackup(old) end
    end
    c.legacyChecked = true
    return c, "character"
  end
  return M.db, "account"
end

local function Apply()
  if InCombatLockdown() then return ns.Print("can't change keybinds in combat.") end
  local layout = Layout()

  -- Keep the very first backup, so undo always returns to your original binds.
  -- A button or key the layout gained since (such as bar 4, the Ctrl layer)
  -- joins the backup the first time Apply manages it: an earlier Apply
  -- never touched it, so what it holds now is still your own bind.
  local store, set = Store()
  local backup = store.backup or { commands = {}, keys = {}, set = set }
  backup.commands, backup.keys = backup.commands or {}, backup.keys or {}
  for _, b in ipairs(layout) do
    if backup.commands[b.command] == nil then backup.commands[b.command] = { GetBindingKey(b.command) } end
    if b.key and backup.keys[b.key] == nil then backup.keys[b.key] = GetBindingAction(b.key) end
  end
  store.backup = backup

  -- Clear every key on the managed commands so nothing is left double-bound.
  for _, b in ipairs(layout) do
    for _, key in ipairs({ GetBindingKey(b.command) }) do SetBinding(key) end
  end
  for _, b in ipairs(layout) do
    if b.key then SetBinding(b.key, b.command) end
  end

  SaveBindings(GetCurrentBindingSet())
  ns.Print("keybinds applied. /ac keys undo to go back to your original binds.")
end

-- True when a "MACRO X" bind points at a macro that no longer exists.
local function MacroGone(action)
  local macro = type(action) == "string" and action:match("^MACRO (.+)$")
  return macro and (GetMacroIndexByName(macro) or 0) == 0, macro
end

local function Undo()
  if InCombatLockdown() then return ns.Print("can't change keybinds in combat.") end
  local store = Store()
  local backup = store.backup
  if not backup then return ns.Print("nothing to undo.") end
  for _, b in ipairs(Layout()) do
    for _, key in ipairs({ GetBindingKey(b.command) }) do SetBinding(key) end
  end
  local lost = {}
  for key, action in pairs(backup.keys) do
    -- Never re-bind a key to a macro that's gone (deleted, renamed, or
    -- retired by the controller layout since): the key would do nothing.
    local gone, macro = MacroGone(action)
    if gone then lost[#lost + 1] = key .. " (macro " .. macro .. ")"
    elseif action and action ~= "" then SetBinding(key, action) end
  end
  for command, keys in pairs(backup.commands) do
    for _, key in ipairs(keys) do SetBinding(key, command) end
  end
  SaveBindings(GetCurrentBindingSet())
  store.backup = nil
  ns.Print("original keybinds restored.")
  if #lost > 0 then
    table.sort(lost)
    ns.Print("left unbound, their macro is gone: " .. table.concat(lost, ", ") .. ".")
  end
end

local function Show()
  local last
  for _, b in ipairs(Layout()) do
    if b.key then
      if b.label ~= last then print("|cffffd100" .. b.label .. "|r"); last = b.label end
      print("  " .. b.key .. " -> " .. b.command)
    end
  end
end

-- What Apply changes. keys: layout keys bound to something else now
-- (replace = the ones bound to another action, not unbound). extra: other
-- keys on the layout's buttons, which Apply unbinds.
local function Diff()
  local d = { keys = 0, replace = 0, extra = 0, replaced = {}, unbinds = {} }
  local want = {}
  for _, b in ipairs(Layout()) do
    if b.key then
      want[b.key] = b.command
      local cur = GetBindingAction(b.key) or ""
      if cur ~= b.command then
        d.keys = d.keys + 1
        if cur ~= "" then d.replace = d.replace + 1; d.replaced[#d.replaced + 1] = { key = b.key, old = cur } end
      end
    end
  end
  for _, b in ipairs(Layout()) do
    for _, key in ipairs({ GetBindingKey(b.command) }) do
      if want[key] ~= b.command then d.extra = d.extra + 1; d.unbinds[#d.unbinds + 1] = key end
    end
  end
  return d
end

-- For the Keyboard page (Modules/ActionBars.lua) and other modules: the
-- layout ({ key, command, label } per managed button), what Apply changes,
-- Apply and Undo, and whether Undo has a backup to restore.
M.Layout, M.Diff, M.Apply, M.Undo = Layout, Diff, Apply, Undo
M.KEYS, M.PET = KEYS, PET
function M.HasBackup()
  local store = Store()
  return store ~= nil and store.backup ~= nil
end

ns.RegisterCommand("keys", "list the Key Bindings layout, or apply/undo it", function(arg)
  arg = (arg or ""):lower()
  if arg == "apply" then Apply()
  elseif arg == "undo" then Undo()
  else Show() end
end, { usage = "keys [apply|undo]", module = "Keybinds" })
