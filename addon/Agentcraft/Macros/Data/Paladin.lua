-- Paladin macros. Sources:
--   ExoJudge, HammerJudge: RankedBoost WoW Forever paladin macros (2026-11),
--     https://rankedboost.com/world-of-warcraft/forever/macros/paladin/retribution/
--   Repent: Icy Veins WoW Forever Retribution paladin leveling (2026-11-15),
--     https://www.icy-veins.com/wow-forever/retribution-paladin-leveling
--   SmartFlash, SmartLight, SmartShock: adapted from the RankedBoost heal macros (the
--     @mouseover part dropped; the [@player] fallback added).
-- Judgement is off the global cooldown, so a macro that judges first still
-- casts its second spell. Judgement no longer uses up your Seal on WoW Forever.
-- Left out: RankedBoost's seal macros ([mod:ctrl]) and mouseover heals.
local _, ns = ...
local L = ns.MacroLibrary

L.Add({ name = "ExoJudge", category = "combat", class = "PALADIN", order = 20, perCharacter = true, specs = { "ret", "prot" }, tags = { "recommended", "rotation" },
  icon = "Exorcism", requires = { "Exorcism" }, untested = true,
  desc = "Starts melee on your enemy target, Judges if Judgement is ready, then casts Exorcism (Undead and Demons only).",
  body = "#showtooltip Exorcism\n/startattack [@target,harm,nodead]\n/cast [@target,harm,nodead] Judgement\n/cast [@target,harm,nodead] Exorcism" })

L.Add({ name = "HammerJudge", category = "combat", class = "PALADIN", order = 25, perCharacter = true, specs = { "ret", "prot" }, tags = { "recommended", "rotation" },
  icon = "Hammer of Wrath", requires = { "Hammer of Wrath" }, untested = true,
  desc = "Judges if Judgement is ready, then Hammer of Wrath (targets below 20% health) in one press.",
  body = "#showtooltip Hammer of Wrath\n/cast [@target,harm,nodead] Judgement\n/cast [@target,harm,nodead] Hammer of Wrath" })

L.Add({ name = "Repent", category = "combat", class = "PALADIN", order = 30, perCharacter = true, tags = { "crowd control" },
  icon = "Repentance", requires = { "Repentance" }, untested = true,
  desc = "Repentance and Judgement in one press (Retribution talent).",
  body = "#showtooltip\n/cast Repentance\n/cast Judgement" })

L.Add({ name = "SmartFlash", category = "combat", class = "PALADIN", order = 40, perCharacter = true, specs = { "holy" }, tags = { "recommended", "controller" },
  icon = "Flash of Light", requires = { "Flash of Light" }, untested = true,
  desc = "Flash of Light on your target if it's a living friend, otherwise on yourself, without dropping your enemy target.",
  body = "#showtooltip Flash of Light\n/cast [@target,help,nodead][@player] Flash of Light" })

L.Add({ name = "SmartLight", category = "combat", class = "PALADIN", order = 41, perCharacter = true, specs = { "holy" }, tags = { "recommended", "controller" },
  icon = "Holy Light", requires = { "Holy Light" }, untested = true,
  desc = "Holy Light on your target if it's a living friend, otherwise on yourself, without dropping your enemy target.",
  body = "#showtooltip Holy Light\n/cast [@target,help,nodead][@player] Holy Light" })

L.Add({ name = "SmartShock", category = "combat", class = "PALADIN", order = 42, perCharacter = true, specs = { "holy" }, tags = { "recommended", "controller" },
  icon = "Holy Shock", requires = { "Holy Shock" }, untested = true,
  desc = "Holy Shock heals your target if it's a living friend, otherwise yourself: a healer's instant heal that never hits the enemy you have targeted.",
  body = "#showtooltip Holy Shock\n/cast [@target,help,nodead][@player] Holy Shock" })

-- Recommended per spec (owner, 2026-11-26) ---------------------------------------
-- Wowhead Classic paladin macro guides, adapted to WoW Forever:
--   [WH-H] https://www.wowhead.com/classic/guide=8807 (Holy Paladin macros)
--   [WH-R] https://www.wowhead.com/classic/guide=8808 (Retribution Paladin macros)
--   [WH-D] https://www.wowhead.com/classic/guide=8786 (the /startattack wrapper, DPS Warrior macros)
-- Wowhead has no Protection paladin macro guide: Protection gets the melee
-- wrapper and the Holy/Ret utility macros its Forever rotation presses
-- (Holy Strike, Judgement, Exorcism, Hammer of Wrath, Hammer of Justice).
-- Both guides' Hammer of Justice macro stops your cast first ("adapt it for
-- Lay on Hands"); /stopcasting is the slash form of their SpellStopCasting().
-- Their mouseover heals are SmartFlash/SmartLight (target, else yourself);
-- their mouseover Holy Shock (help or harm) is ShockAny without the mouseover.
-- Left out: the downranked Consecration (a [mod] variant) and mouseover
-- Blessing of Freedom (no @mouseover; a plain button already targets).

L.Add({ name = "HolyStrike", category = "combat", class = "PALADIN", order = 15, perCharacter = true,
  specs = { "ret", "prot" }, tags = { "recommended", "rotation", "controller" },
  icon = "Holy Strike", requires = { "Holy Strike" }, untested = true,
  desc = "Starts your attack, then Holy Strike on your enemy target, so a target swap never leaves you standing idle. [WH-D]",
  body = "#showtooltip Holy Strike\n/startattack\n/cast [@target,harm,nodead] Holy Strike" })

L.Add({ name = "ShockAny", category = "combat", class = "PALADIN", order = 43, perCharacter = true,
  specs = { "ret" }, tags = { "recommended", "rotation", "controller" },
  icon = "Holy Shock", requires = { "Holy Shock" }, untested = true,
  desc = "Holy Shock damages your enemy target, heals a friendly target, and heals yourself when you have neither. [WH-H]",
  body = "#showtooltip Holy Shock\n/cast [@target,harm,nodead] Holy Shock; [@target,help,nodead][@player] Holy Shock" })

L.Add({ name = "HoJ", category = "combat", class = "PALADIN", order = 31, perCharacter = true,
  specs = { "holy", "prot", "ret" }, tags = { "recommended", "crowd control", "controller" },
  icon = "Hammer of Justice", requires = { "Hammer of Justice" }, untested = true,
  desc = "Stops the spell you're casting and stuns your enemy target with Hammer of Justice at once. [WH-H, WH-R]",
  body = "#showtooltip Hammer of Justice\n/stopcasting\n/cast [@target,harm,nodead] Hammer of Justice" })

L.Add({ name = "LayOnHands", category = "combat", class = "PALADIN", order = 44, perCharacter = true,
  specs = { "holy", "prot", "ret" }, tags = { "recommended", "defensive", "controller" },
  icon = "Lay on Hands", requires = { "Lay on Hands" }, untested = true,
  desc = "Stops your cast, then Lay on Hands on your target if it's a living friend, otherwise on yourself. [WH-H, WH-R]",
  body = "#showtooltip Lay on Hands\n/stopcasting\n/cast [@target,help,nodead][@player] Lay on Hands" })
