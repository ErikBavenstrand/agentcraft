-- Warrior macros. See Library.lua for the fields.
--
-- Sources (round 2 research, 2026-11):
--   [M] Mobalytics WoW Forever warrior guides (Cliptis, LudiDeo): TankCharge,
--       Revenge, SlamRevenge, MockingBlow, BerserkerRage, Intercept,
--       Whirlwind, ChargeIntercept, BashPummel, ShieldWall, Retaliation.
--   [D] Drafted from the stance rules (Icy Veins / Mobalytics stance table):
--       Overpower, BattleCharge (TankCharge without the return to Defensive).
-- Adapted where noted: a stance line gets [nostance:n] so pressing it in
-- the stance you're already in gives no error; BashPummel's shield test is
-- [equipped:Shields] (the item subtype; the guide's "shield" never matches).
--
-- Keyboard players use the Bar 1 stance pages; these macros are mainly for
-- the controller, whose buttons stay the same in every stance. A stance swap and the
-- spell after it usually take two presses (press once to switch, again to cast).
local _, ns = ...
local L = ns.MacroLibrary

-- Combat -----------------------------------------------------------------------

L.Add({ name = "TankCharge", category = "combat", class = "WARRIOR", order = 10, perCharacter = true,
  icon = "Charge", requires = { "Charge" }, specs = { "prot" }, tags = { "recommended", "opener", "controller" }, untested = true,
  desc = "Protection pull: out of combat, Battle Stance then Charge; once in combat, back to Defensive Stance. Starts your attack. [M]",
  body = "#showtooltip Charge\n/cast [nocombat,nostance:1] Battle Stance\n/cast [nocombat] Charge\n/cast [combat,nostance:2] Defensive Stance\n/startattack" })

L.Add({ name = "ChargeIntercept", category = "combat", class = "WARRIOR", order = 11, perCharacter = true,
  icon = "Charge", requires = { "Charge", "Intercept" }, specs = { "fury" }, tags = { "recommended", "opener", "controller" }, untested = true,
  desc = "Arms and Fury gap closer: Charge out of combat (Battle Stance first), Intercept in combat (Berserker Stance first). [M, adapted]",
  body = "#showtooltip [combat] Intercept; Charge\n/cast [combat,nostance:3] Berserker Stance; [nocombat,nostance:1] Battle Stance\n/cast [combat] Intercept; Charge" })

L.Add({ name = "BattleCharge", category = "combat", class = "WARRIOR", order = 12, perCharacter = true,
  icon = "Charge", requires = { "Charge" }, specs = { "arms" }, tags = { "recommended", "opener", "controller" }, untested = true,
  desc = "Arms pull: Battle Stance if you're not in it, Charge, and start your attack (Arms stays in Battle Stance, unlike TankCharge). [D]",
  body = "#showtooltip Charge\n/cast [nostance:1] Battle Stance\n/cast Charge\n/startattack" })

L.Add({ name = "Overpower", category = "combat", class = "WARRIOR", order = 20, perCharacter = true,
  icon = "Overpower", requires = { "Overpower" }, specs = { "arms" }, tags = { "recommended", "rotation", "controller" }, untested = true,
  desc = "Overpower in Battle Stance; from another stance, switches to Battle Stance first. [D]",
  body = "#showtooltip Overpower\n/cast [stance:1] Overpower; Battle Stance" })

L.Add({ name = "Revenge", category = "combat", class = "WARRIOR", order = 21, perCharacter = true,
  icon = "Revenge", requires = { "Revenge" }, specs = { "prot" }, tags = { "recommended", "rotation", "controller" }, untested = true,
  desc = "Defensive Stance if you're not in it, Shield Block, then Revenge (Shield Block makes the block that lights Revenge up). Starts your attack. [M]",
  body = "#showtooltip Revenge\n/cast [nostance:2] Defensive Stance\n/cast Shield Block\n/cast Revenge\n/startattack" })

L.Add({ name = "SlamRevenge", category = "combat", class = "WARRIOR", order = 22, perCharacter = true,
  icon = "Revenge", requires = { "Shield Slam", "Revenge" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Protection at 40+: Defensive Stance if needed, then Shield Slam and Revenge in turn (resets after 2 seconds), with Shield Block. [M]",
  body = "#showtooltip Revenge\n/cast [nostance:2] Defensive Stance\n/castsequence reset=2 Shield Slam, Revenge\n/cast Shield Block" })

L.Add({ name = "Whirlwind", category = "combat", class = "WARRIOR", order = 23, perCharacter = true,
  icon = "Whirlwind", requires = { "Whirlwind" }, specs = { "fury" }, tags = { "recommended", "rotation", "controller" }, untested = true,
  desc = "Starts your attack, then Whirlwind in Berserker Stance; from another stance, switches to Berserker Stance first. [M]",
  body = "#showtooltip Whirlwind\n/startattack\n/cast [stance:3] Whirlwind; Berserker Stance" })

L.Add({ name = "Intercept", category = "combat", class = "WARRIOR", order = 24, perCharacter = true,
  icon = "Intercept", requires = { "Intercept" }, specs = { "arms" }, tags = { "recommended", "opener", "controller" }, untested = true,
  desc = "Berserker Stance if you're not in it, then Intercept. [M, adapted]",
  body = "#showtooltip Intercept\n/cast [nostance:3] Berserker Stance\n/cast Intercept" })

L.Add({ name = "BashPummel", category = "combat", class = "WARRIOR", order = 30, perCharacter = true,
  icon = "Shield Bash", requires = { "Shield Bash" }, specs = { "prot", "arms", "fury" }, tags = { "recommended", "crowd control", "controller" }, untested = true,
  desc = "One interrupt for any stance: with a shield, Shield Bash (Battle Stance first unless in Battle or Defensive); without, Pummel (Berserker Stance first). [M, adapted]",
  body = "#showtooltip [equipped:Shields] Shield Bash; Pummel\n/cast [equipped:Shields,nostance:1/2] Battle Stance; [noequipped:Shields,nostance:3] Berserker Stance\n/cast [equipped:Shields] Shield Bash; Pummel" })

L.Add({ name = "MockingBlow", category = "combat", class = "WARRIOR", order = 40, perCharacter = true,
  icon = "Mocking Blow", requires = { "Mocking Blow" }, tags = { "group", "controller" }, untested = true,
  desc = "Battle Stance if you're not in it, then Mocking Blow (a taunt that hits). [M]",
  body = "#showtooltip Mocking Blow\n/cast [nostance:1] Battle Stance\n/cast Mocking Blow" })

L.Add({ name = "BerserkerRage", category = "combat", class = "WARRIOR", order = 41, perCharacter = true,
  icon = "Berserker Rage", requires = { "Berserker Rage" }, specs = { "fury" }, tags = { "recommended", "defensive", "controller" }, untested = true,
  desc = "Berserker Stance if you're not in it, then Berserker Rage (breaks and blocks fear). [M, adapted]",
  body = "#showtooltip Berserker Rage\n/cast [nostance:3] Berserker Stance\n/cast Berserker Rage" })

L.Add({ name = "Retaliation", category = "combat", class = "WARRIOR", order = 50, perCharacter = true,
  icon = "Retaliation", requires = { "Retaliation" }, tags = { "cooldown", "controller" }, untested = true,
  desc = "Retaliation in Battle Stance; from another stance, switches to Battle Stance first. [M, adapted]",
  body = "#showtooltip Retaliation\n/cast [stance:1] Retaliation; Battle Stance" })

L.Add({ name = "ShieldWall", category = "combat", class = "WARRIOR", order = 51, perCharacter = true,
  icon = "Shield Wall", requires = { "Shield Wall" }, specs = { "prot" }, tags = { "recommended", "defensive", "cooldown", "controller" }, untested = true,
  desc = "Emergency: Defensive Stance if needed, Last Stand (if talented), then Shield Wall. [M]",
  body = "#showtooltip Shield Wall\n/cast [nostance:2] Defensive Stance\n/cast Last Stand\n/cast Shield Wall" })

-- Recommended per spec (owner, 2026-11-26) ---------------------------------------
-- Wowhead Classic warrior macro guides, adapted to WoW Forever:
--   [WH-T] https://www.wowhead.com/classic/guide=8794 (Tank Warrior macros)
--   [WH-D] https://www.wowhead.com/classic/guide=8786 (DPS Warrior macros)
--   [WH-F] https://www.wowhead.com/forever/guide/beginners-guide-to-writing-macros-in-wow-forever-34950
-- Both guides put /startattack in front of every offensive ability, and the
-- DPS guide adds /cancelaura Blessing of Protection (a BoP stops your swings).
-- The tank wrappers leave BoP alone: Wowhead's Forever Protection guide pairs
-- it with Challenging Shout. Taunt is the tank guide's mouseover Taunt with
-- the mouseover dropped and Defensive Stance first ([WH-F] stance macro).
-- Left out: mouseover Charge/Intercept (no @mouseover; TankCharge, Intercept
-- and ChargeIntercept cover them), the weapon swap (names items) and [WH-F]'s
-- Shoot Bow/Gun macro (not a verified Forever spell name).

L.Add({ name = "Sunder", category = "combat", class = "WARRIOR", order = 14, perCharacter = true,
  icon = "Sunder Armor", requires = { "Sunder Armor" }, specs = { "prot" }, tags = { "recommended", "rotation", "controller" }, untested = true,
  desc = "Protection filler: starts your attack, then Sunder Armor on your enemy target, so a target swap never leaves you standing idle. [WH-T]",
  body = "#showtooltip Sunder Armor\n/startattack\n/cast [@target,harm,nodead] Sunder Armor" })

L.Add({ name = "ShieldSlam", category = "combat", class = "WARRIOR", order = 15, perCharacter = true,
  icon = "Shield Slam", requires = { "Shield Slam" }, specs = { "prot" }, tags = { "recommended", "rotation", "controller" }, untested = true,
  desc = "Starts your attack, then Shield Slam on your enemy target (Protection talent, level 40). [WH-T]",
  body = "#showtooltip Shield Slam\n/startattack\n/cast [@target,harm,nodead] Shield Slam" })

L.Add({ name = "Taunt", category = "combat", class = "WARRIOR", order = 42, perCharacter = true,
  icon = "Taunt", requires = { "Taunt" }, specs = { "prot" }, tags = { "recommended", "group", "controller" }, untested = true,
  desc = "Defensive Stance if you're not in it, then Taunt on your enemy target: one taunt button from any stance. [WH-T, WH-F]",
  body = "#showtooltip Taunt\n/cast [nostance:2] Defensive Stance\n/cast [@target,harm,nodead] Taunt" })

L.Add({ name = "MortalStrike", category = "combat", class = "WARRIOR", order = 16, perCharacter = true,
  icon = "Mortal Strike", requires = { "Mortal Strike" }, specs = { "arms" }, tags = { "recommended", "rotation", "controller" }, untested = true,
  desc = "Drops Blessing of Protection, starts your attack, then Mortal Strike on your enemy target (Arms talent, level 40). [WH-D]",
  body = "#showtooltip Mortal Strike\n/cancelaura Blessing of Protection\n/startattack\n/cast [@target,harm,nodead] Mortal Strike" })

L.Add({ name = "Bloodthirst", category = "combat", class = "WARRIOR", order = 17, perCharacter = true,
  icon = "Bloodthirst", requires = { "Bloodthirst" }, specs = { "fury" }, tags = { "recommended", "rotation", "controller" }, untested = true,
  desc = "Drops Blessing of Protection, starts your attack, then Bloodthirst on your enemy target (Fury talent, level 40): Wowhead's own example. [WH-D]",
  body = "#showtooltip Bloodthirst\n/cancelaura Blessing of Protection\n/startattack\n/cast [@target,harm,nodead] Bloodthirst" })
