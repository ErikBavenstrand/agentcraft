-- Macros for every class: fishing, consumables and utility. Sources:
-- warcraft.wiki.gg Useful macros. See Library.lua for the fields and rules.
--
-- A macro earns its place only if it does something a plain button or the
-- game's own menus can't. Hand-written macros keep working forever once
-- installed: they name spells and slash commands only, never an item.
-- The item macros (Fish, Bait, HealPot, ManaPot, Bandage, Food) are
-- generated instead: their text names the best item you carry and
-- Agentcraft rewrites it when that changes (owner decision, 2026-11-24;
-- builders, item lists and the updater in Macros/Items.lua). Their body
-- below is the text used while you carry none of that thing.
local _, ns = ...
local L = ns.MacroLibrary

-- Fishing ----------------------------------------------------------------------
-- Fish: with a pole in your hands it fishes; otherwise it equips the best
-- pole you carry (only poles in your bags or hands, best first).
-- [equipped:] takes the client's own pole subtype name ({POLETYPE}). The
-- Fishing module puts your weapons back 15 seconds after your last cast
-- ends, or when you mount, unless you turn it off with /ac off Fishing.
-- Example: #showtooltip Fishing / /cast [equipped:Fishing Poles] Fishing /
-- /stopmacro [equipped:Fishing Poles] / /equip Big Iron Fishing Pole

L.Add({ name = "Fish", category = "fishing", profession = "Fishing", order = 10, icon = "Fishing",
  tags = { "controller", "gear" }, perCharacter = true, generated = "fish", untested = true,
  desc = "One button fishing: the first press equips the best pole you carry, the next presses fish. The Fishing module puts your weapons back 15 s after you stop fishing, or when you mount after fishing (/ac off Fishing to do it yourself).",
  body = "#showtooltip Fishing\n/run print(\"Agentcraft: no fishing pole in your bags\")" })

-- Bait: the best lure you carry and your Fishing skill allows, then /use 16
-- puts it on the pole in your main hand. One lure per text, so no other
-- lure can take the cursor.
L.Add({ name = "Bait", category = "fishing", profession = "Fishing", order = 11,
  iconFile = "INV_Misc_Orb_03", tags = { "controller", "gear" }, perCharacter = true, generated = "bait", untested = true,
  desc = "Puts the best fishing bait you carry on your pole, such as Aquadynamic Fish Attractor, Bright Baubles, Nightcrawlers or Shiny Bauble. Equip the pole first (press Fish).",
  body = "#showtooltip\n/run print(\"Agentcraft: no fishing bait in your bags\")" })

-- Consumables ----------------------------------------------------------------
-- The same four for every class, on Alt+Q E R T and controller page 2
-- LT X Y B Left. Item lists, level and skill gates: Macros/Items.lua.

L.Add({ name = "HealPot", category = "consumables", order = 20, iconFile = "INV_Potion_54",
  tags = { "controller", "solo" }, perCharacter = true, generated = "healpot", untested = true,
  desc = "Uses your Healthstone, or else the best healing potion you carry and your level allows.",
  body = "#showtooltip\n/run print(\"Agentcraft: no healing potion in your bags\")" })

L.Add({ name = "ManaPot", category = "consumables", order = 21, iconFile = "INV_Potion_76",
  tags = { "controller", "solo" }, perCharacter = true, power = "mana", generated = "manapot", untested = true,
  desc = "Uses your mana gem, or else the best mana potion you carry and your level allows. Not for warriors and rogues (no mana).",
  body = "#showtooltip\n/run print(\"Agentcraft: no mana potion in your bags\")" })

L.Add({ name = "Bandage", category = "consumables", order = 22, iconFile = "INV_Misc_Bandage_15",
  tags = { "controller", "solo" }, perCharacter = true, generated = "bandage", untested = true,
  desc = "Bandages yourself, whatever you target, with the best bandage you carry and your First Aid skill allows.",
  body = "#showtooltip\n/run print(\"Agentcraft: no bandage you can use in your bags\")" })

L.Add({ name = "Food", category = "consumables", order = 23, iconFile = "INV_Misc_Food_15",
  tags = { "controller", "solo" }, perCharacter = true, generated = "food", untested = true,
  desc = "Eats the best food you carry for your level: conjured food first, never raw meat or fish; buff food only when you have nothing else.",
  body = "#showtooltip\n/run print(\"Agentcraft: no food in your bags\")" })

-- Utility ----------------------------------------------------------------------

L.Add({ name = "Skull", category = "utility", tags = { "group" }, order = 40, iconFile = "INV_Misc_Bone_HumanSkull_01",
  desc = "Puts a skull on your target so the group knows what to kill first.",
  body = "/run SetRaidTarget(\"target\", 8)" })

L.Add({ name = "Focus", category = "utility", tags = { "group", "controller" }, order = 41, iconFile = "Ability_Hunter_SniperShot",
  desc = "Makes your target your focus. Focus a friend, then Assist attacks whatever they attack.",
  body = "/focus" })

L.Add({ name = "Assist", category = "utility", tags = { "group", "controller" }, order = 42, iconFile = "Ability_Hunter_MarkedForDeath",
  desc = "Targets what your focus (or your current friendly target) is attacking, then starts Auto Shot if you're a hunter.",
  body = "/assist [@focus,exists][]\n/cast [harm] !Auto Shot" })

L.Add({ name = "Follow", category = "utility", tags = { "group", "travel", "controller" }, order = 43, iconFile = "Ability_Tracking",
  desc = "Follows your target, for long runs with a friend.",
  body = "/follow" })

L.Add({ name = "Reload", category = "utility", tags = { "interface", "controller" }, order = 70, iconFile = "Spell_Holy_BorrowedTime",
  desc = "Reloads the interface. Saves Agentcraft's snapshot and loads addon changes; the game menu has no reload.",
  body = "/reload" })

L.Add({ name = "Agentcraft", category = "utility", tags = { "interface", "controller" }, order = 71, iconFile = "INV_Gizmo_02",
  desc = "Opens or closes this window, so a controller reaches it with one button (controller page 3, LT+RT Y).",
  body = "/ac" })

-- Older texts of the item macros, before they were generated (0.25-0.35):
-- Fish tried every pole by name, Bait every lure. Installed copies of these
-- show "Update", which moves them to your character macros with the
-- generated text. Neither "Fishing Pole" (0.25) nor "Fishing Poles"
-- (0.26-0.32) matched on WoW Forever; Fish reads the subtype from the client.
L.previous.Fish = {
  "#showtooltip Fishing\n/cast [equipped:Fishing Poles] Fishing\n/stopmacro [equipped:Fishing Poles]\n/equip Fishing Pole\n/equip Strong Fishing Pole\n/equip Darkwood Fishing Pole\n/equip Big Iron Fishing Pole\n/equip Seth's Graphite Fishing Pole",
  "#showtooltip Fishing\n/cast [equipped:Fishing Pole] Fishing\n/stopmacro [equipped:Fishing Pole]\n/equip Fishing Pole\n/equip Strong Fishing Pole\n/equip Darkwood Fishing Pole\n/equip Big Iron Fishing Pole\n/equip Seth's Graphite Fishing Pole",
}
L.previous.Bait = {
  "#showtooltip\n/use Shiny Bauble\n/use Nightcrawlers\n/use Bright Baubles\n/use Aquadynamic Fish Attractor\n/use 16",
}

-- Retired --------------------------------------------------------------------------
-- Macros the library no longer offers. Removed from /macro on the next
-- controller Apply, but only while their text is still exactly what
-- Agentcraft installed (yours are never touched); keys bound to them are
-- unbound. Old texts of macros the library still offers go in L.previous
-- instead (next to the macro), so the Macros page shows "Update".
L.retired = {
  -- Done by the game's menus, the vendor window or Steam.
  Map = "/run ToggleWorldMap()",
  Chat = "/run ChatFrame_OpenChat(\"\")",
  MaxZoom = "/console cameraDistanceMaxZoomFactor 2.6",
  SellGrays = "/run for b=0,4 do for s=1,C_Container.GetContainerNumSlots(b) do local i=C_Container.GetContainerItemInfo(b,s) if i and i.quality==0 and not i.hasNoValue then C_Container.UseContainerItem(b,s) end end end",
  Repair = "/run if CanMerchantRepair() then RepairAllItems() end",
  Screenshot = "/run Screenshot()",
  ReadyCheck = "/readycheck",
  Logout = "/camp",
  QuietErrors = "/run UIErrorsFrame:Clear()",
  -- The Hearthstone item itself goes on the bar.
  Hearth = "#showtooltip Hearthstone\n/use Hearthstone",
  -- Put the lure on a bar as an item button; the Fishing module warns when it runs out.
  Lure = "#showtooltip Shiny Bauble\n/use Shiny Bauble\n/use 16",
  -- One-line wrappers: the plain spell button is the same.
  Campfire = "#showtooltip\n/cast Basic Campfire",
  Smelt = "#showtooltip\n/cast Smelting",
  Forsaken = "#showtooltip Will of the Forsaken\n/cast Will of the Forsaken",
  Stoneform = "#showtooltip Stoneform\n/cast Stoneform",
  EscArtist = "#showtooltip Escape Artist\n/cast Escape Artist",
  Perception = "#showtooltip Perception\n/cast Perception",
  -- Shift/Ctrl variants: those are bar layers on keyboard and controller.
  Track = "#showtooltip\n/cast [mod:shift] Track Humanoids; [mod:ctrl] Track Beasts; Find Minerals",
  Trap = "#showtooltip\n/stopattack\n/petfollow\n/cast [mod:shift] Immolation Trap; Freezing Trap",
  Aspect = "#showtooltip\n/cast [mod:ctrl] Aspect of the Monkey; [combat] Aspect of the Hawk; Aspect of the Cheetah",
  -- Mouse-only (@mouseover / @cursor); Eagle Eye isn't even ground-targeted.
  MarkMO = "#showtooltip Hunter's Mark\n/cast [@mouseover,harm,nodead][] Hunter's Mark",
  ScareMO = "#showtooltip Scare Beast\n/cast [@mouseover,harm,nodead][] Scare Beast",
  EagleEye = "#showtooltip Eagle Eye\n/cast [@cursor] !Eagle Eye",
  Flare = "#showtooltip Flare\n/cast [@cursor] Flare",
  Volley = "#showtooltip Volley\n/cast [@cursor] Volley",
  Dynamite = "#showtooltip Rough Dynamite\n/use [@cursor] Rough Dynamite",
  -- Left the pet passive after the fight.
  Scatter = "#showtooltip Scatter Shot\n/targetenemy [noexists][dead][help]\n/petstay [@pettarget,harm]\n/petpassive [@pettarget,harm]\n/cast Scatter Shot",
  -- Covered by other buttons: separate Raptor/Mongoose/Disengage homes,
  -- Arcane starts Auto Shot, the library's autocast toggles. No /petattack.
  Escape = "#showtooltip Disengage\n/petattack [@target,harm,nodead]\n/cast Disengage",
  AutoShot = "#showtooltip Auto Shot\n/targetenemy [noexists][dead][help]\n/cast !Auto Shot",
  PetAttack = "/petattack [@target,harm,nodead]",
  Growl = "/petautocasttoggle Growl",
  -- Dropped in 0.26: they sent the pet in (/petattack); you send it yourself.
  Pull = "#showtooltip Serpent Sting\n/petattack [@target,harm,nodead]\n/cast [@target,harm,nodead] Serpent Sting",
  Mark = "#showtooltip Hunter's Mark\n/petattack [@target,harm,nodead]\n/cast [@target,harm,nodead] Hunter's Mark",
  PetToggle = "/petfollow [@pettarget,exists]\n/petattack [@pettarget,noexists]",
  Berserk = "#showtooltip Berserking\n/petattack [@target,harm,nodead]\n/cast Berserking",
  BloodFury = "#showtooltip Blood Fury\n/petattack [@target,harm,nodead]\n/cast Blood Fury",
  -- Autocast toggles that controller Apply generated before 0.26, cut to 16
  -- characters. The library's Auto Howl, Auto Lightning... replace them.
  ["Auto Furious How"] = "#showtooltip Furious Howl\n/petautocasttoggle Furious Howl",
  ["Auto Lightning B"] = "#showtooltip Lightning Breath\n/petautocasttoggle Lightning Breath",
  ["Auto Scorpid Poi"] = "#showtooltip Scorpid Poison\n/petautocasttoggle Scorpid Poison",
  ["Auto Shell Shiel"] = "#showtooltip Shell Shield\n/petautocasttoggle Shell Shield",
  ["Auto Thunderstom"] = "#showtooltip Thunderstomp\n/petautocasttoggle Thunderstomp",
}

-- Retired texts so short that players write the same macro themselves:
-- deleted only when Agentcraft recorded writing them (L.RetiredDeletable).
-- PetAttack isn't here: no /petattack macro may stay (owner rule), and
-- versions before 0.26 kept no record, so its exact text is enough.
L.retiredCommon = { ReadyCheck = true, Logout = true, Hearth = true, Growl = true, Screenshot = true }

-- Retired macros whose text Agentcraft filled in from your bags (so it
-- differs per person): deleted when every line still has the shape
-- Agentcraft wrote, and only when Agentcraft recorded writing that exact
-- text. Most players write this same Feed Pet or /use macro themselves, so
-- the shape alone is never enough. A line you added yourself keeps it too.
-- Eat's successor is the generated Food macro (a new name, so an old Eat
-- copy is still cleaned up and never mistaken for Food).
local function OnlyLines(body, allowed)
  for line in (body .. "\n"):gmatch("(.-)\n") do
    local ok = line == ""
    for _, prefix in ipairs(allowed) do
      if line:sub(1, #prefix) == prefix then ok = true end
    end
    if not ok then return false end
  end
  return true
end
L.retiredShapes = {
  Eat = function(b) return L.Wrote("Eat", b) and OnlyLines(b, { "#showtooltip", "/use " }) end,
  Feed = function(b)
    return L.Wrote("Feed", b) and b:find("/cast Feed Pet", 1, true) and OnlyLines(b, { "#showtooltip", "/cast Feed Pet", "/use " }) or false
  end,
}
-- Druid controller form macros (owner, 2026-11-26): page 1 now holds the cat
-- and bear kits as plain spells. Any text Agentcraft wrote goes.
for _, n in ipairs({ "FormAttack", "FormDoT", "FormBig", "FormFill", "FormSig", "FormOpen",
  "FormStun", "FormArea", "FormProc", "FormMove", "FormSnare" }) do
  L.retiredShapes[n] = function(b) return L.Wrote(n, b) end
end

-- More utility (2026-11-22). Sources: warcraft.wiki.gg API_C_MountJournal.SummonByID
-- (lists Forever 1.60.1) and API_GetInventoryItemCount (ammo slot).
L.Add({ name = "Mount", category = "utility", order = 45, tags = { "travel", "controller" }, iconFile = "Ability_Mount_Kodo_01", untested = true,
  desc = "Summons a random favourite mount for the area, or dismounts. Mark favourites in the mount journal.",
  body = "#showtooltip\n/run if IsMounted() then Dismount() else C_MountJournal.SummonByID(0) end" })

L.Add({ name = "Ammo", category = "utility", class = "HUNTER", order = 46, tags = { "interface" }, iconFile = "INV_Ammo_Arrow_02", untested = true,
  desc = "Prints how much of your equipped ammo you have left.",
  body = "/run local s=GetInventorySlotInfo(\"AmmoSlot\") print(\"Ammo:\",GetInventoryItemCount(\"player\",s))" })
