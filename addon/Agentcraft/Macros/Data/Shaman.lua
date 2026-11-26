-- Shaman macros (WoW Forever). See Library.lua for the fields.
-- Sources:
--   ShockCycle, MagmaNova, BoltOrWave: warcraft.wiki.gg "Useful macros for
--     shamans" (Classic era), adapted to Forever (Fire Nova is a spell that
--     detonates your fire totem; no Wind Shear, so Earth Shock interrupts).
--   WaveHeal: the common "[@target,help,nodead][@player]" self-heal pattern
--     (RankedBoost WoW Forever paladin smart heal, adapted to Healing Wave).
--   ShockKick: drafted from Forever's spell list (Earth Shock is the only
--     interrupt; /stopcasting lets it cut your own cast short); also
--     Wowhead's "Stopcasting Macro" in all three Classic shaman macro guides
--     (wowhead.com/classic/guide=8837, 8873, 8814).
--   NSWave: the Classic Nature's Swiftness + Healing Wave macro (wiki above).
--   StormAttack: Wowhead's Classic Enhancement macro guide (guide=8873,
--     "StartAttack macros": Stormstrike + /startattack).
--   ShamanBurst: the "Burst-macros" of guides 8837 / 8873 (trinkets,
--     Berserking, the spec cooldown), with Forever's cooldowns: Lightning
--     Mastery (Elemental) and Rage of the Farseer (Enhancement) in place of
--     Elemental Mastery; the Chain Lightning / Stormstrike + Earth Shock
--     castsequence is left out (Forever: Chain Lightning only on
--     Clearcasting, and the shock is the interrupt).
--   WFShield: "One-button Buffing" in all three guides (castsequence
--     Lightning Shield, Windfury Weapon); Enhancement only, since Elemental
--     uses Flametongue and Restoration Water Shield on Forever.
--   ChainHeal, LesserWave, RiptideHeal: the "Mouseover healing macro" of
--     guide 8814 (Chain Heal, Healing Wave, Lesser Healing Wave), rewritten
--     without @mouseover: your friendly living target, else you; Riptide
--     (Forever's Resto HoT) the same way.
-- Left out of the guides: weapon/shield swap macros (items) and the
-- mouseover parts (no @mouseover).
-- Recommended per spec (`specs`, the Layouts/Shaman.lua spec keys):
--   elemental ShockKick, ShockCycle, MagmaNova, BoltOrWave, ShamanBurst;
--   enhancement StormAttack, ShockKick, MagmaNova, ShamanBurst, WaveHeal,
--     WFShield;
--   restoration WaveHeal, ChainHeal, LesserWave, RiptideHeal, NSWave,
--     ShockKick.
-- All are untested on Forever until the owner confirms them in game.
--
-- Rules every macro here keeps: no [mod] variants, no @mouseover/@cursor, no
-- items (totems need their totem item in your bags, but a totem spell is
-- cast by name; weapon imbues and totem presets stay plain buttons).
local _, ns = ...
local L = ns.MacroLibrary

L.Add({ name = "ShockKick", category = "combat", class = "SHAMAN", order = 10, perCharacter = true,
  icon = "Earth Shock", requires = { "Earth Shock" }, tags = { "rotation", "controller", "recommended" }, untested = true,
  specs = { "elemental", "enhancement", "restoration" },
  desc = "Earth Shock that stops your own cast first, so it interrupts the moment you press it (Forever has no Wind Shear).",
  body = "#showtooltip Earth Shock\n/stopcasting\n/cast [@target,harm,nodead] Earth Shock" })

L.Add({ name = "ShockCycle", category = "combat", class = "SHAMAN", order = 20, perCharacter = true,
  icon = "Flame Shock", requires = { "Flame Shock", "Earth Shock" }, tags = { "rotation", "controller", "recommended" }, untested = true,
  specs = { "elemental" },
  desc = "Flame Shock, then Earth Shock on the next press (the shared shock cooldown holds it until ready); starts over on a new target, out of combat or after 12 sec. Also starts melee.",
  body = "#showtooltip\n/castsequence [@target,harm,nodead] reset=combat/target/12 Flame Shock, Earth Shock\n/startattack [harm]" })

-- wowhead.com/classic/guide=8873 (StartAttack macros).
L.Add({ name = "StormAttack", category = "combat", class = "SHAMAN", order = 25, perCharacter = true,
  icon = "Stormstrike", requires = { "Stormstrike" }, tags = { "rotation", "controller", "recommended" }, untested = true,
  specs = { "enhancement" },
  desc = "Starts melee, then Stormstrike: a new target gets auto attacks without a separate click.",
  body = "#showtooltip Stormstrike\n/startattack\n/cast [@target,harm,nodead] Stormstrike" })

L.Add({ name = "MagmaNova", category = "combat", class = "SHAMAN", order = 30, perCharacter = true,
  icon = "Magma Totem", requires = { "Magma Totem", "Fire Nova" }, tags = { "rotation", "recommended" }, untested = true,
  specs = { "elemental", "enhancement" },
  desc = "AoE on one key: drops Magma Totem, then each press after detonates it with Fire Nova; starts over out of combat or after 20 sec (the totem's life).",
  body = "#showtooltip\n/castsequence reset=combat/20 Magma Totem, Fire Nova" })

-- wowhead.com/classic/guide=8837 and guide=8873 (Burst-macros).
L.Add({ name = "ShamanBurst", category = "combat", class = "SHAMAN", order = 35, perCharacter = true,
  icon = "Lightning Mastery", tags = { "cooldown", "controller", "recommended" }, untested = true,
  specs = { "elemental", "enhancement" },
  desc = "Every damage cooldown at once: both trinkets, Berserking, then Rage of the Farseer (Enhancement) or Lightning Mastery (Elemental). Anything you don't have is skipped.",
  body = "#showtooltip\n/use 13\n/use 14\n/cast Berserking\n/cast Rage of the Farseer\n/cast Lightning Mastery" })

L.Add({ name = "BoltOrWave", category = "combat", class = "SHAMAN", order = 40, perCharacter = true,
  icon = "Lightning Bolt", requires = { "Lightning Bolt", "Healing Wave" }, tags = { "controller", "recommended" }, untested = true,
  specs = { "elemental" },
  desc = "One button for both: Lightning Bolt on an enemy, Healing Wave on a friend, and Healing Wave on yourself with no target.",
  body = "#showtooltip\n/cast [harm,nodead] Lightning Bolt; [help,nodead] Healing Wave; [@player] Healing Wave" })

L.Add({ name = "WaveHeal", category = "combat", class = "SHAMAN", order = 50, perCharacter = true,
  icon = "Healing Wave", requires = { "Healing Wave" }, tags = { "defensive", "group", "recommended" }, untested = true,
  specs = { "enhancement", "restoration" },
  desc = "Healing Wave on your target if it's a living friend, else on yourself, so you never have to drop an enemy target to heal.",
  body = "#showtooltip Healing Wave\n/cast [@target,help,nodead][@player] Healing Wave" })

-- wowhead.com/classic/guide=8814 (Mouseover healing macro), target version.
L.Add({ name = "ChainHeal", category = "combat", class = "SHAMAN", order = 51, perCharacter = true,
  icon = "Chain Heal", requires = { "Chain Heal" }, tags = { "rotation", "group", "recommended" }, untested = true,
  specs = { "restoration" },
  desc = "Chain Heal starting on your target if it's a living friend, else on yourself.",
  body = "#showtooltip Chain Heal\n/cast [@target,help,nodead][@player] Chain Heal" })

-- wowhead.com/classic/guide=8814 (Mouseover healing macro), target version.
L.Add({ name = "LesserWave", category = "combat", class = "SHAMAN", order = 52, perCharacter = true,
  icon = "Lesser Healing Wave", requires = { "Lesser Healing Wave" }, tags = { "defensive", "group", "recommended" }, untested = true,
  specs = { "restoration" },
  desc = "Lesser Healing Wave (the fast emergency heal) on your target if it's a living friend, else on yourself.",
  body = "#showtooltip Lesser Healing Wave\n/cast [@target,help,nodead][@player] Lesser Healing Wave" })

-- wowhead.com/classic/guide=8814 pattern, applied to Forever's Riptide.
L.Add({ name = "RiptideHeal", category = "combat", class = "SHAMAN", order = 53, perCharacter = true,
  icon = "Riptide", requires = { "Riptide" }, tags = { "rotation", "group", "recommended" }, untested = true,
  specs = { "restoration" },
  desc = "Riptide on your target if it's a living friend, else on yourself.",
  body = "#showtooltip Riptide\n/cast [@target,help,nodead][@player] Riptide" })

L.Add({ name = "NSWave", category = "combat", class = "SHAMAN", order = 60, perCharacter = true,
  icon = "Nature's Swiftness", requires = { "Nature's Swiftness", "Healing Wave" }, tags = { "cooldown", "defensive", "recommended" }, untested = true,
  specs = { "restoration" },
  desc = "Emergency heal: Nature's Swiftness, then an instant Healing Wave on your friendly target, else on yourself.",
  body = "#showtooltip Nature's Swiftness\n/cast Nature's Swiftness\n/stopcasting\n/cast [@target,help,nodead][@player] Healing Wave" })

-- wowhead.com/classic/guide=8873 (One-button Buffing).
L.Add({ name = "WFShield", category = "combat", class = "SHAMAN", order = 70, perCharacter = true,
  icon = "Windfury Weapon", requires = { "Lightning Shield", "Windfury Weapon" }, tags = { "recommended" }, untested = true,
  specs = { "enhancement" },
  desc = "Both Enhancement buffs on one key: Lightning Shield on the first press, Windfury Weapon on the next; starts over after 2 sec.",
  body = "#showtooltip\n/castsequence reset=2 Lightning Shield, Windfury Weapon" })
