-- Fishing Helper and Character Snapshot fixes from review 10: weapon
-- restore by link, dead/gone handling, re-enable, mixed secret fields,
-- collapsed headers and the bank rescan.
local H = require("harness")

local POLE, REAPER = 6256, 12784

local function PoleSetup(W)
  W.fixture.equipped[16] = POLE
  W.fixture.bags[0][6] = REAPER
end
-- Swap model: pickup a bag slot, equip into an inventory slot.
local function Swapper(env)
  local W, cursor, log = env.W, nil, {}
  env.G.C_Container.PickupContainerItem = function(bag, slot) cursor = { bag, slot } end
  env.G.EquipCursorItem = function(inv)
    local b = W.fixture.bags[cursor[1]]
    local id = b[cursor[2]]
    log[#log + 1] = { inv = inv, id = id }
    b[cursor[2]] = W.fixture.equipped[inv]
    W.fixture.equipped[inv] = id
    cursor = nil
  end
  env.G.CursorHasItem = function() return cursor ~= nil end
  return log
end

test("fishing: pole equipped at login puts the weapon back after the before-first-cast grace", function()
  local env = H.boot({ setup = PoleSetup, charDB = { weapons = { main = REAPER, mainLink = "|Hitem:12784|h[Arcanite Reaper]|h" } } })
  local log = Swapper(env)
  env:runTimers(30)
  eq(#log, 0, "not yet: no cast, so it waits 2 minutes")
  env:runTimers(100)
  noErrors(env)
  eq(env.W.fixture.equipped[16], REAPER, "reaper back in the main hand")
  eq(#log, 1, "one equip")
end)

test("fishing: no restore while dead; gives up when the weapon is gone", function()
  local env = H.boot({ setup = PoleSetup, charDB = { weapons = { main = REAPER } },
    loaded = function(e) e.G.UnitIsDeadOrGhost = function() return true end end })
  local log = Swapper(env)

  env:runTimers(30)
  eq(#log, 0, "no equip while dead")
  env.G.UnitIsDeadOrGhost = function() return false end
  env.W.fixture.bags[0][6] = nil
  env:runTimers(130)
  noErrors(env)
  eq(#log, 0, "nothing to equip")
  ok(env:chatText():find("Couldn't find", 1, true), "says so: " .. env:chatText())
end)

test("fishing: turning it back on re-reads the weapons", function()
  local env = H.boot({ charDB = { weapons = { main = 1 } } })
  env:slash("off fishing")
  env.W.fixture.equipped[16] = 18738
  env:slash("on fishing")
  noErrors(env)
  eq(env.G.AgentcraftCharDB.weapons and env.ns.charDB.weapons.main, 18738, "remembered the new weapon")
end)

test("snapshot: mixed secret health keeps the old current value; nil sections aren't errors", function()
  local env = H.boot()
  local mod = env.ns.modules.snapshot
  mod:Save()
  env.W.secret = true
  env.G.UnitHealthMax = function() return 3500 end
  env.G.C_QuestLog.GetAllCompletedQuestIDs = function() return nil end
  mod:Save()
  local snap = mod.db["Tester-Mockrealm"]
  eq(snap.basics.health, "3000 / 3500", "health merged")
  eq(snap.completedQuests, nil, "nil section stored as nothing")
  noErrors(env)
end)

test("snapshot: collapsed reputation headers are opened and closed again", function()
  local env = H.boot()
  local rows = {
    { name = "Horde", isHeader = true, isCollapsed = true, kids = { { name = "Orgrimmar", reaction = 5 } } },
    { name = "Other", isHeader = true },
    { name = "Booty Bay", reaction = 4 },
  }
  local function Visible()
    local v = {}
    for _, r in ipairs(rows) do
      v[#v + 1] = r
      if r.isHeader and not r.isCollapsed then for _, k in ipairs(r.kids or {}) do v[#v + 1] = k end end
    end
    return v
  end
  env.G.C_Reputation = {
    GetNumFactions = function() return #Visible() end,
    GetFactionDataByIndex = function(i) return Visible()[i] end,
    ExpandFactionHeader = function(i) Visible()[i].isCollapsed = false end,
    CollapseFactionHeader = function(i) Visible()[i].isCollapsed = true end,
  }
  local mod = env.ns.modules.snapshot
  mod:Save()
  local rep = mod.db["Tester-Mockrealm"].reputation
  eq(#rep, 2, "both factions: " .. table.concat(rep, "; "))
  eq(rows[1].isCollapsed, true, "Horde closed again")
  noErrors(env)
end)

test("snapshot: bank rescans on bag changes while open, once per burst; recipes debounced", function()
  local env = H.boot()
  local mod = env.ns.modules.snapshot
  local n = {}
  local set = mod.SetCached
  mod.SetCached = function(name, data) n[name] = (n[name] or 0) + 1; return set(name, data) end
  env.W.fixture.bags[6] = { 2589, size = 4 }
  env.W.fixture.items[2589] = { name = "Linen Cloth" }
  env:fire("BANKFRAME_OPENED")
  env:fire("BAG_UPDATE_DELAYED"); env:fire("PLAYERBANKSLOTS_CHANGED")
  env:runTimers(1)
  eq(n.bank, 1, "one scan for the burst")
  env.W.fixture.bags[6][2] = 2589
  env:fire("BAG_UPDATE_DELAYED")
  env:fire("BANKFRAME_CLOSED")
  env:runTimers(1)
  eq(n.bank, 2, "scan at close for the pending change")
  env:fire("BAG_UPDATE_DELAYED"); env:runTimers(1)
  eq(n.bank, 2, "no scan once closed")
  noErrors(env)
end)

test("fishing: mounting before the first cast keeps the pole; after a cast it puts the weapon back", function()
  local env = H.boot({ setup = PoleSetup, charDB = { weapons = { main = REAPER, mainLink = "|Hitem:12784|h[Arcanite Reaper]|h" } } })
  local log = Swapper(env)
  env.G.IsMounted = function() return true end
  env:fire("PLAYER_MOUNT_DISPLAY_CHANGED")
  env:runTimers(6)
  eq(#log, 0, "riding to the water keeps the pole")
  env.G.IsMounted = function() return false end
  env:fire("UNIT_SPELLCAST_CHANNEL_START", "player")
  env:fire("UNIT_SPELLCAST_CHANNEL_STOP", "player")
  env.G.IsMounted = function() return true end
  env:fire("PLAYER_MOUNT_DISPLAY_CHANGED")
  noErrors(env)
  eq(env.W.fixture.equipped[16], REAPER, "mounting after fishing puts the weapon back")
end)
