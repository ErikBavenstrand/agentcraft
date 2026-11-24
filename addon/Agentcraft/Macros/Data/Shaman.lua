-- Shaman macros (WoW Forever). See Library.lua for the fields.
-- Sources:
--   ShockCycle, MagmaNova, BoltOrWave: warcraft.wiki.gg "Useful macros for
--     shamans" (Classic era), adapted to Forever (Fire Nova is a spell that
--     detonates your fire totem; no Wind Shear, so Earth Shock interrupts).
--   WaveHeal: the common "[@target,help,nodead][@player]" self-heal pattern
--     (RankedBoost WoW Forever paladin smart heal, adapted to Healing Wave).
--   ShockKick: drafted from Forever's spell list (Earth Shock is the only
--     interrupt; /stopcasting lets it cut your own cast short).
--   NSWave: the Classic Nature's Swiftness + Healing Wave macro (wiki above).
-- All are untested on Forever until the owner confirms them in game.
--
-- Rules every macro here keeps: no [mod] variants, no @mouseover/@cursor, no
-- items (totems need their totem item in your bags, but a totem spell is
-- cast by name; weapon imbues and totem presets stay plain buttons).
local _, ns = ...
local L = ns.MacroLibrary

L.Add({ name = "ShockKick", category = "combat", class = "SHAMAN", order = 10, perCharacter = true,
  icon = "Earth Shock", requires = { "Earth Shock" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Earth Shock that stops your own cast first, so it interrupts the moment you press it (Forever has no Wind Shear).",
  body = "#showtooltip Earth Shock\n/stopcasting\n/cast [@target,harm,nodead] Earth Shock" })

L.Add({ name = "ShockCycle", category = "combat", class = "SHAMAN", order = 20, perCharacter = true,
  icon = "Flame Shock", requires = { "Flame Shock", "Earth Shock" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Flame Shock, then Earth Shock on the next press (the shared shock cooldown holds it until ready); starts over on a new target, out of combat or after 12 sec. Also starts melee.",
  body = "#showtooltip\n/castsequence [@target,harm,nodead] reset=combat/target/12 Flame Shock, Earth Shock\n/startattack [harm]" })

L.Add({ name = "MagmaNova", category = "combat", class = "SHAMAN", order = 30, perCharacter = true,
  icon = "Magma Totem", requires = { "Magma Totem", "Fire Nova" }, tags = { "rotation" }, untested = true,
  desc = "AoE on one key: drops Magma Totem, then each press after detonates it with Fire Nova; starts over out of combat or after 20 sec (the totem's life).",
  body = "#showtooltip\n/castsequence reset=combat/20 Magma Totem, Fire Nova" })

L.Add({ name = "BoltOrWave", category = "combat", class = "SHAMAN", order = 40, perCharacter = true,
  icon = "Lightning Bolt", requires = { "Lightning Bolt", "Healing Wave" }, tags = { "controller" }, untested = true,
  desc = "One button for both: Lightning Bolt on an enemy, Healing Wave on a friend, and Healing Wave on yourself with no target.",
  body = "#showtooltip\n/cast [harm,nodead] Lightning Bolt; [help,nodead] Healing Wave; [@player] Healing Wave" })

L.Add({ name = "WaveHeal", category = "combat", class = "SHAMAN", order = 50, perCharacter = true,
  icon = "Healing Wave", requires = { "Healing Wave" }, tags = { "defensive", "group" }, untested = true,
  desc = "Healing Wave on your target if it's a living friend, else on yourself, so you never have to drop an enemy target to heal.",
  body = "#showtooltip Healing Wave\n/cast [@target,help,nodead][@player] Healing Wave" })

L.Add({ name = "NSWave", category = "combat", class = "SHAMAN", order = 60, perCharacter = true,
  icon = "Nature's Swiftness", requires = { "Nature's Swiftness", "Healing Wave" }, tags = { "cooldown", "defensive" }, untested = true,
  desc = "Emergency heal: Nature's Swiftness, then an instant Healing Wave on your friendly target, else on yourself.",
  body = "#showtooltip Nature's Swiftness\n/cast Nature's Swiftness\n/stopcasting\n/cast [@target,help,nodead][@player] Healing Wave" })
