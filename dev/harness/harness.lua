-- Test-facing API: boot a fresh mocked game with the addon loaded.
--
--   local H = require("harness")
--   local env = H.boot({ fixture = "hunter", pet = true })
--   env:slash("controller apply")
--   assert(#env:calls("CreateMacro") == 0)
--
-- boot options:
--   fixture   name of a file in harness/fixtures (default "hunter")
--   pet       true to give the fixture its pet (fixture.petData)
--   db, charDB  SavedVariables tables to start from (default nil, a fresh install)
--   macros    { "Arcane", ... } library macros already installed (by name)
--   bindings  { F13 = "MACRO PetAttack", ... } keybinds before login
--   setup(W)  called after the world is made, before the addon loads
--   loaded(env) called after the addon files ran, before ADDON_LOADED (to
--             patch a module, e.g. make its OnEnable raise)
--   secret    true to start with combat values secret (W.secret; see wow.lua)
--   level     the player level (default: the fixture's, else 60)
--   talents   { { name =, points = }, ... } points per talent tab, in tab order
--             (default: the fixture's; none = no talent config)
--   bonusOffset  GetBonusBarOffset (the stance page shown; default 0). Change
--             it later with env.W.bonusOffset
local wow = require("wow")
local rules = require("rules")

local H = { rules = rules, wow = wow }
H.addonDir = nil   -- set by run.lua
H.addonName = "Agentcraft"

-- Loads harness/fixtures/<name>.lua. A class fixture may be small: fields it
-- leaves out get defaults, so any class boots. Format: dev/layout-format.md
-- ("Fixture format").
local function LoadFixture(name)
  local f = assert(loadfile(H.harnessDir .. "/fixtures/" .. name .. ".lua"))
  local fx = f()
  fx.spells = fx.spells or {}
  fx.professions = fx.professions or {}
  fx.flyouts = fx.flyouts or {}
  fx.catalog = fx.catalog or {}
  fx.items = fx.items or { [6948] = { name = "Hearthstone", spell = "Hearthstone", icon = 134414 } }
  fx.bags = fx.bags or { [0] = { 6948 } }
  fx.equipped = fx.equipped or {}
  return fx
end
H.LoadFixture = LoadFixture

local Env = {}
Env.__index = Env

function Env:fire(event, ...) wow.FireEvent(self.W, event, ...) end
function Env:runTimers(seconds) wow.RunTimers(self.W, seconds) end
function Env:calls(name) return self.W.calls[name] or {} end
function Env:resetCalls() self.W.calls = {}; self.W.chat = {} end
function Env:chatText() return table.concat(self.W.chat, "\n") end

-- Runs "/ac <msg>" the way the chat box would. Core.lua runs commands in a
-- pcall and prints "error: ..." instead of raising, so those lines are moved
-- into W.errors, where noErrors(env) sees them.
function Env:slash(msg)
  local fn = self.G.SlashCmdList.AGENTCRAFT
  assert(fn, "SlashCmdList.AGENTCRAFT is not registered")
  local before = #self.W.chat
  fn(msg)
  for i = before + 1, #self.W.chat do
    local line = self.W.chat[i]
    if line:find("error:", 1, true) then self.W.errors[#self.W.errors + 1] = "/ac " .. tostring(msg) .. ": " .. line end
  end
end

-- Puts a library macro into /macro without going through the addon (as if
-- the owner installed it earlier). Does not record a CreateMacro call.
function Env:installMacro(name)
  for _, m in ipairs(self.ns.MacroLibrary.macros) do
    if m.name == name then
      local body = assert(self.ns.MacroLibrary.Resolve(m))
      local entry = { name = name, icon = "INV_Misc_QuestionMark", body = body, perChar = m.perCharacter and true or false }
      self.W.macros[#self.W.macros + 1] = entry
      return wow.MacroIndexOf(self.W, entry)
    end
  end
  error("no library macro named " .. name)
end

-- Gamepad storage slot for page (1-3) and a layout key like "RT A".
-- Literal numbers from an in-game snapshot (controller/gamepadBars on WoW
-- Forever), not computed with Controller's own tables, so a wrong mapping in
-- the addon or the mock shows up. Pages are 28 slots apart: the Top bar's
-- fixed face buttons have no storage slot. Entries marked * follow the same
-- pattern but had nothing placed in that snapshot.
local PAD_SLOTS = {
  [1] = { ["none Left"] = 181, ["none Up"] = 182, ["none Right"] = 183, ["none Down"] = 184,
    ["LT Left"] = 185 --[[*]], ["LT Up"] = 186, ["LT Right"] = 187 --[[*]], ["LT Down"] = 188,
    ["LT X"] = 189, ["LT Y"] = 190, ["LT B"] = 191, ["LT A"] = 192,
    ["RT Left"] = 193 --[[*]], ["RT Up"] = 194, ["RT Right"] = 195, ["RT Down"] = 196,
    ["RT X"] = 197, ["RT Y"] = 198, ["RT B"] = 199, ["RT A"] = 200, ["LT+RT B"] = 207 },
  [2] = { ["none Up"] = 210, ["none Right"] = 211, ["RT Up"] = 222, ["RT Right"] = 223, ["RT Down"] = 224,
    ["RT X"] = 225, ["RT B"] = 227, ["RT A"] = 228, ["LT+RT Down"] = 232, ["LT+RT X"] = 233,
    ["LT+RT Y"] = 234, ["LT+RT B"] = 235, ["LT+RT A"] = 236 },
  [3] = { ["none Left"] = 237, ["none Up"] = 238, ["none Right"] = 239, ["none Down"] = 240,
    ["LT A"] = 248, ["RT X"] = 253, ["RT A"] = 256, ["LT+RT A"] = 264 },
}
H.PAD_SLOTS = PAD_SLOTS
function Env:padSlot(page, key)
  local slot = PAD_SLOTS[page] and PAD_SLOTS[page][key]
  return assert(slot, "no in-game reference for page " .. tostring(page) .. " " .. tostring(key) .. "; add it to PAD_SLOTS from a snapshot")
end

-- What a slot holds: "spell:Arcane Shot", "macro:Arcane", "item:6948", "flyout:253" or nil.
function Env:slotText(slot)
  local a = self.W.actions[slot]
  if not a then return nil end
  if a.type == "macro" then local m = wow.MacroAt(self.W, a.id) return "macro:" .. tostring(m and m.name) end
  if a.type == "spell" then
    for _, s in ipairs(self.W.fixture.spells or {}) do if s.id == a.id then return "spell:" .. s.name end end
    for _, p in ipairs(self.W.fixture.professions or {}) do
      for _, s in ipairs(p.spells or {}) do if s.id == a.id then return "spell:" .. s.name end end
    end
  end
  return a.type .. ":" .. tostring(a.id)
end

-- Globals the addon wrote (minus frames it named; auto stubs live outside G).
function Env:globalsWritten()
  local out = {}
  for k, v in pairs(self.G) do
    if k ~= "_G" and not (type(v) == "table" and rawget(v, "_world")) then
      out[#out + 1] = k
    end
  end
  table.sort(out)
  return out
end

function H.boot(opts)
  opts = opts or {}
  local fixture = LoadFixture(opts.fixture or "hunter")
  if opts.pet then fixture.pet = fixture.petData end
  if opts.level then fixture.level = opts.level end
  if opts.talents then fixture.talents = opts.talents end
  if opts.bonusOffset then fixture.bonusOffset = opts.bonusOffset end
  if opts.professions then fixture.professions = opts.professions end
  local W = wow.NewWorld(fixture)
  local toc = wow.ReadToc(H.addonDir, H.addonName)
  local G = wow.NewEnv(W, toc)
  G.AgentcraftDB = opts.db
  G.AgentcraftCharDB = opts.charDB
  for k, v in pairs(opts.bindings or {}) do W.bindings[k] = v end
  W.secret = opts.secret and true or false
  if opts.setup then opts.setup(W) end

  local ns = wow.LoadAddon(W, G, toc)
  local env = setmetatable({ W = W, G = G, ns = ns, toc = toc }, Env)
  for _, name in ipairs(opts.macros or {}) do env:installMacro(name) end
  if opts.loaded then opts.loaded(env) end

  wow.FireEvent(W, "ADDON_LOADED", H.addonName)
  wow.FireEvent(W, "PLAYER_LOGIN")
  wow.FireEvent(W, "PLAYER_ENTERING_WORLD", true, false)
  wow.FireEvent(W, "SPELLS_CHANGED")
  wow.RunTimers(W, 15)

  H.worlds[#H.worlds + 1] = W
  return env
end

-- Every auto-stubbed API touched by any boot, during load or later in a
-- test: { [name] = total calls }. run.lua prints it at the end.
H.worlds = {}
function H.Unknown()
  local out = {}
  for _, W in ipairs(H.worlds) do
    for k, n in pairs(W.unknown) do out[k] = (out[k] or 0) + n end
  end
  return out
end
function H.collect() end  -- kept for old tests; H.Unknown() sees every boot

return H
