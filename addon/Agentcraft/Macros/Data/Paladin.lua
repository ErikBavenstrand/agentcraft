-- Paladin macros. Sources:
--   ExoJudge, HammerJudge: RankedBoost WoW Forever paladin macros (2026-11),
--     https://rankedboost.com/world-of-warcraft/forever/macros/paladin/retribution/
--   Repent: Icy Veins WoW Forever Retribution paladin leveling (2026-11-15),
--     https://www.icy-veins.com/wow-forever/retribution-paladin-leveling
--   SmartFlash, SmartLight: adapted from the RankedBoost heal macros (the
--     @mouseover part dropped; the [@player] fallback added).
-- Judgement is off the global cooldown, so a macro that judges first still
-- casts its second spell. Judgement no longer uses up your Seal on WoW Forever.
-- Left out: RankedBoost's seal macros ([mod:ctrl]) and mouseover heals.
local _, ns = ...
local L = ns.MacroLibrary

L.Add({ name = "ExoJudge", category = "combat", class = "PALADIN", order = 20, perCharacter = true, tags = { "rotation" },
  icon = "Exorcism", requires = { "Exorcism" }, untested = true,
  desc = "Starts melee on your enemy target, Judges if Judgement is ready, then casts Exorcism (Undead and Demons only).",
  body = "#showtooltip Exorcism\n/startattack [@target,harm,nodead]\n/cast [@target,harm,nodead] Judgement\n/cast [@target,harm,nodead] Exorcism" })

L.Add({ name = "HammerJudge", category = "combat", class = "PALADIN", order = 25, perCharacter = true, tags = { "rotation" },
  icon = "Hammer of Wrath", requires = { "Hammer of Wrath" }, untested = true,
  desc = "Judges if Judgement is ready, then Hammer of Wrath (targets below 20% health) in one press.",
  body = "#showtooltip Hammer of Wrath\n/cast [@target,harm,nodead] Judgement\n/cast [@target,harm,nodead] Hammer of Wrath" })

L.Add({ name = "Repent", category = "combat", class = "PALADIN", order = 30, perCharacter = true, tags = { "crowd control" },
  icon = "Repentance", requires = { "Repentance" }, untested = true,
  desc = "Repentance and Judgement in one press (Retribution talent).",
  body = "#showtooltip\n/cast Repentance\n/cast Judgement" })

L.Add({ name = "SmartFlash", category = "combat", class = "PALADIN", order = 40, perCharacter = true, tags = { "controller" },
  icon = "Flash of Light", requires = { "Flash of Light" }, untested = true,
  desc = "Flash of Light on your target if it's a living friend, otherwise on yourself, without dropping your enemy target.",
  body = "#showtooltip Flash of Light\n/cast [@target,help,nodead][@player] Flash of Light" })

L.Add({ name = "SmartLight", category = "combat", class = "PALADIN", order = 41, perCharacter = true, tags = { "controller" },
  icon = "Holy Light", requires = { "Holy Light" }, untested = true,
  desc = "Holy Light on your target if it's a living friend, otherwise on yourself, without dropping your enemy target.",
  body = "#showtooltip Holy Light\n/cast [@target,help,nodead][@player] Holy Light" })
