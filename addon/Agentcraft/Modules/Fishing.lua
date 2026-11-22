-- Fishing: helpers around the "Fish" macro (which only equips a pole and
-- fishes; it never names your weapons).
--   * Remembers the weapons you wear (item link, so the right copy of a
--     random-suffix or enchanted weapon comes back). With the pole equipped,
--     15 seconds after your last cast ends (2 minutes if you haven't cast
--     yet; mounting counts only after a cast) (out of combat, alive, not
--     channelling, no loot window) or as soon as you mount, puts them back.
--     Keeps trying until both hands are filled, and gives up after a few
--     tries or when the weapon is no longer in your bags. Turn it off with
--     /ac off Fishing if you'd rather swap back yourself.
--   * Warns with a raid-warning style message and sound when the lure runs out.
local _, ns = ...
local M = ns.RegisterModule("Fishing", {
  title = "Fishing Helper",
  order = 50,
  description = "Puts your weapons back after fishing and warns when the lure runs out.",
  charDefaults = { idleSeconds = 15 },
})

local MAX_TRIES = 5
-- Client functions not yet in .luacheckrc read_globals, looked up when called.
local G = _G

local lastCast = 0
local ticker
local lureOn -- nil until we've seen the pole, then true/false
local tries = 0
local restoring -- { [16] = { id, link }, [17] = ... } once putting back has begun
-- Whether a cast started since the pole went on. Until then the helper
-- waits much longer and ignores mounting: equipping the pole and riding to
-- the water must not take it off again (the "pole won't equip" report).
local fished = false
local BEFORE_FIRST_CAST = 120

local function IsPole(id) return ns.MacroLibrary and ns.MacroLibrary.IsPole(id) end
local function PoleEquipped() return IsPole(GetInventoryItemID("player", 16)) end
local function Link(slot) return GetInventoryItemLink and GetInventoryItemLink("player", slot) or nil end

local function RememberWeapons()
  local main = GetInventoryItemID("player", 16)
  if main and not IsPole(main) then
    local off = GetInventoryItemID("player", 17)
    ns.charDB.weapons = { main = main, off = off, mainLink = Link(16), offLink = off and Link(17) or nil }
  end
end

-- "id:enchant:gem1:gem2:gem3:gem4:suffix" of an item link: what tells two
-- copies of the same item apart (the rest of a link changes with level).
local function LinkKey(link)
  local fields = type(link) == "string" and link:match("item:([%-%d:]*)")
  if not fields then return nil end
  local parts = {}
  for v in (fields .. ":"):gmatch("(%-?%d*):") do
    parts[#parts + 1] = v
    if #parts == 7 then break end
  end
  return table.concat(parts, ":")
end

-- The bag slot holding the item: the exact copy (same link) first, else any
-- copy with the same ID. Skips locked slots (an item already on its way).
local function FindInBags(id, link)
  if not (id and C_Container and C_Container.GetContainerItemInfo) then return end
  local want, any = LinkKey(link), nil
  for bag = 0, NUM_BAG_SLOTS or 4 do
    for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.itemID == id and not info.isLocked then
        if want and LinkKey(info.hyperlink) == want then return bag, slot end
        any = any or { bag, slot }
      end
    end
  end
  if any then return any[1], any[2] end
end

local function InBags(id, link)
  if FindInBags(id, link) then return true end
  if not (C_Container and C_Container.GetContainerItemInfo) and C_Item and C_Item.GetItemCount then
    return (C_Item.GetItemCount(id) or 0) > 0
  end
  return false
end

-- Puts the item into an equipment slot: picked up from its exact bag slot
-- when possible, else by item ID.
local function Equip(id, link, slot)
  if not id then return end
  local bag, bagSlot = FindInBags(id, link)
  if bag and C_Container.PickupContainerItem and G.EquipCursorItem then
    if G.CursorHasItem and G.CursorHasItem() then return end -- don't drop what the player holds
    C_Container.PickupContainerItem(bag, bagSlot)
    G.EquipCursorItem(slot)
    if G.CursorHasItem and G.CursorHasItem() then ClearCursor() end
    return
  end
  if C_Item and C_Item.EquipItemByName then C_Item.EquipItemByName(link or id, slot)
  elseif EquipItemByName then EquipItemByName(link or id, slot) end
end

local function IsTwoHanded(id)
  if not (id and C_Item and C_Item.GetItemInfoInstant) then return false end
  local _, _, _, equipLoc = C_Item.GetItemInfoInstant(id)
  return equipLoc == "INVTYPE_2HWEAPON"
end

-- The weapons to put back: { main, mainLink, off, offLink }, or nil and why.
local function Remembered()
  local w = ns.charDB.weapons
  local main, mainLink, off, offLink
  if w then
    main, mainLink, off, offLink = w.main, w.mainLink, w.off, w.offLink
    if main and not InBags(main, mainLink) then
      local name = mainLink and mainLink:match("%[(.-)%]") or "your weapon"
      return nil, "Couldn't find " .. name .. " in your bags. Put your weapons back yourself."
    end
  elseif ns.MacroLibrary and ns.MacroLibrary.Weapons then
    main, off = ns.MacroLibrary.Weapons()
  end
  if not main then return nil, "Agentcraft hasn't seen your weapons yet. Put them back yourself." end
  -- A two-hander leaves no room for an off-hand (equipping one would take it off again).
  if IsTwoHanded(main) then off, offLink = nil, nil end
  return { main = main, mainLink = mainLink, off = off, offLink = offLink }
end

local function Warn(text)
  pcall(RaidNotice_AddMessage, RaidWarningFrame, text, ChatTypeInfo and ChatTypeInfo["RAID_WARNING"])
  if SOUNDKIT and SOUNDKIT.RAID_WARNING then pcall(PlaySound, SOUNDKIT.RAID_WARNING) end
  ns.Print(text)
end

-- Notices the lure going on or running out while the pole is in your hands.
local function CheckLure()
  if not PoleEquipped() then lureOn = nil; return end
  local has, expires = GetWeaponEnchantInfo()
  has = has and true or false
  if lureOn == true and not has then
    Warn("Lure ran out")
  elseif lureOn == false and has then
    ns.Print(string.format("lure on for %d min.", math.floor((expires or 0) / 60000 + 0.5)))
  end
  lureOn = has
end

local function StopTicker()
  if ticker then ticker:Cancel(); ticker = nil end
  fished = false
  restoring = nil
end

local function GiveUp(text)
  StopTicker()
  if text then ns.Print(text) end
end

-- A hand that still has to be filled: its weapon isn't on yet and is in the bags.
local function Needs(slot)
  local want = restoring and restoring[slot]
  if not want or GetInventoryItemID("player", slot) == want.id then return false end
  return InBags(want.id, want.link)
end

local function RestoreIfIdle()
  if not M.active then StopTicker(); return end
  local pole = PoleEquipped()
  if pole then CheckLure() end
  if not restoring and not pole then StopTicker(); return end
  if restoring and not Needs(16) and not Needs(17) then StopTicker(); return end
  -- The game refuses equipment changes in combat and while dead.
  if InCombatLockdown() or (G.UnitIsDeadOrGhost and G.UnitIsDeadOrGhost("player")) then return end
  if UnitChannelInfo("player") or (LootFrame and LootFrame:IsShown()) then return end
  if not restoring then
    local leaving = fished and IsMounted and IsMounted()
    local grace = fished and (M.charDB.idleSeconds or 15) or BEFORE_FIRST_CAST
    if not leaving and GetTime() - lastCast < grace then return end
    local w, why = Remembered()
    if not w then return GiveUp(why) end
    restoring = { [16] = { id = w.main, link = w.mainLink } }
    if w.off then restoring[17] = { id = w.off, link = w.offLink } end
  end
  -- Retried on the next ticks until both hands are filled (an item can be
  -- locked mid-swap), then given up.
  tries = tries + 1
  if tries > MAX_TRIES then return GiveUp("Couldn't put your weapons back. Equip them yourself.") end
  if Needs(16) then Equip(restoring[16].id, restoring[16].link, 16) end
  if Needs(17) then Equip(restoring[17].id, restoring[17].link, 17) end
end

-- Restarts the idle clock. Runs when a cast starts and again when it ends
-- (channel stop, loot closed), so the grace period counts from the end.
local function Touch() lastCast = GetTime(); tries = 0 end

local function Watch()
  Touch()
  if not ticker then ticker = C_Timer.NewTicker(3, RestoreIfIdle) end
end

-- Turned back on: the weapons may have changed while no events arrived.
function M:OnEnable()
  RememberWeapons()
  CheckLure()
  if PoleEquipped() then Watch() end
end

function M:OnDisable()
  StopTicker()
  lureOn = nil
end

M.events = {
  -- After /reload or login with the pole in hand, the idle clock starts too.
  PLAYER_ENTERING_WORLD = function()
    RememberWeapons()
    CheckLure()
    if PoleEquipped() then Watch() end
  end,
  PLAYER_EQUIPMENT_CHANGED = function(_, slot)
    if slot == 16 or slot == 17 then
      RememberWeapons()
      if PoleEquipped() then Watch() end
      CheckLure()
    end
  end,
  UNIT_INVENTORY_CHANGED = function(_, unit) if unit == "player" then CheckLure() end end,
  PLAYER_MOUNT_DISPLAY_CHANGED = function() if PoleEquipped() then RestoreIfIdle() end end,
  UNIT_SPELLCAST_CHANNEL_START = function(_, unit)
    -- Fishing again: wait for the next idle period before putting weapons back.
    if unit == "player" and PoleEquipped() then fished = true; restoring = nil; Watch() end
  end,
  UNIT_SPELLCAST_CHANNEL_STOP = function(_, unit)
    if unit == "player" and PoleEquipped() then Touch() end
  end,
  LOOT_CLOSED = function() if PoleEquipped() then Touch() end end,
}
