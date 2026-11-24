-- Warrior macros. See Library.lua for the fields.
--
-- Sources (round 2 research, 2026-11):
--   [M] Mobalytics WoW Forever warrior guides (Cliptis, LudiDeo): TankCharge,
--       Revenge, SlamRevenge, MockingBlow, BerserkerRage, Intercept,
--       Whirlwind, ChargeIntercept, BashPummel, ShieldWall, Retaliation.
--   [D] Drafted from the stance rules (Icy Veins / Mobalytics stance table):
--       Overpower.
-- Adapted where noted: a stance line gets [nostance:n] so pressing it in
-- the stance you're already in gives no error; BashPummel's shield test is
-- [equipped:Shields] (the item subtype; the guide's "shield" never matches).
--
-- Keyboard players use the Bar 1 stance pages; these macros are mainly for
-- the controller, whose bars don't page by stance. A stance swap and the
-- spell after it usually take two presses (press once to switch, again to cast).
local _, ns = ...
local L = ns.MacroLibrary

-- Combat -----------------------------------------------------------------------

L.Add({ name = "TankCharge", category = "combat", class = "WARRIOR", order = 10, perCharacter = true,
  icon = "Charge", requires = { "Charge" }, tags = { "opener", "controller" }, untested = true,
  desc = "Protection pull: out of combat, Battle Stance then Charge; once in combat, back to Defensive Stance. Starts your attack. [M]",
  body = "#showtooltip Charge\n/cast [nocombat,nostance:1] Battle Stance\n/cast [nocombat] Charge\n/cast [combat,nostance:2] Defensive Stance\n/startattack" })

L.Add({ name = "ChargeIntercept", category = "combat", class = "WARRIOR", order = 11, perCharacter = true,
  icon = "Charge", requires = { "Charge", "Intercept" }, tags = { "opener", "controller" }, untested = true,
  desc = "Arms and Fury gap closer: Charge out of combat (Battle Stance first), Intercept in combat (Berserker Stance first). [M, adapted]",
  body = "#showtooltip [combat] Intercept; Charge\n/cast [combat,nostance:3] Berserker Stance; [nocombat,nostance:1] Battle Stance\n/cast [combat] Intercept; Charge" })

L.Add({ name = "Overpower", category = "combat", class = "WARRIOR", order = 20, perCharacter = true,
  icon = "Overpower", requires = { "Overpower" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Overpower in Battle Stance; from another stance, switches to Battle Stance first. [D]",
  body = "#showtooltip Overpower\n/cast [stance:1] Overpower; Battle Stance" })

L.Add({ name = "Revenge", category = "combat", class = "WARRIOR", order = 21, perCharacter = true,
  icon = "Revenge", requires = { "Revenge" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Defensive Stance if you're not in it, Shield Block, then Revenge (Shield Block makes the block that lights Revenge up). Starts your attack. [M]",
  body = "#showtooltip Revenge\n/cast [nostance:2] Defensive Stance\n/cast Shield Block\n/cast Revenge\n/startattack" })

L.Add({ name = "SlamRevenge", category = "combat", class = "WARRIOR", order = 22, perCharacter = true,
  icon = "Revenge", requires = { "Shield Slam", "Revenge" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Protection at 40+: Defensive Stance if needed, then Shield Slam and Revenge in turn (resets after 2 seconds), with Shield Block. [M]",
  body = "#showtooltip Revenge\n/cast [nostance:2] Defensive Stance\n/castsequence reset=2 Shield Slam, Revenge\n/cast Shield Block" })

L.Add({ name = "Whirlwind", category = "combat", class = "WARRIOR", order = 23, perCharacter = true,
  icon = "Whirlwind", requires = { "Whirlwind" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Starts your attack, then Whirlwind in Berserker Stance; from another stance, switches to Berserker Stance first. [M]",
  body = "#showtooltip Whirlwind\n/startattack\n/cast [stance:3] Whirlwind; Berserker Stance" })

L.Add({ name = "Intercept", category = "combat", class = "WARRIOR", order = 24, perCharacter = true,
  icon = "Intercept", requires = { "Intercept" }, tags = { "opener", "controller" }, untested = true,
  desc = "Berserker Stance if you're not in it, then Intercept. [M, adapted]",
  body = "#showtooltip Intercept\n/cast [nostance:3] Berserker Stance\n/cast Intercept" })

L.Add({ name = "BashPummel", category = "combat", class = "WARRIOR", order = 30, perCharacter = true,
  icon = "Shield Bash", requires = { "Shield Bash" }, tags = { "crowd control", "controller" }, untested = true,
  desc = "One interrupt for any stance: with a shield, Shield Bash (Battle Stance first unless in Battle or Defensive); without, Pummel (Berserker Stance first). [M, adapted]",
  body = "#showtooltip [equipped:Shields] Shield Bash; Pummel\n/cast [equipped:Shields,nostance:1/2] Battle Stance; [noequipped:Shields,nostance:3] Berserker Stance\n/cast [equipped:Shields] Shield Bash; Pummel" })

L.Add({ name = "MockingBlow", category = "combat", class = "WARRIOR", order = 40, perCharacter = true,
  icon = "Mocking Blow", requires = { "Mocking Blow" }, tags = { "group", "controller" }, untested = true,
  desc = "Battle Stance if you're not in it, then Mocking Blow (a taunt that hits). [M]",
  body = "#showtooltip Mocking Blow\n/cast [nostance:1] Battle Stance\n/cast Mocking Blow" })

L.Add({ name = "BerserkerRage", category = "combat", class = "WARRIOR", order = 41, perCharacter = true,
  icon = "Berserker Rage", requires = { "Berserker Rage" }, tags = { "defensive", "controller" }, untested = true,
  desc = "Berserker Stance if you're not in it, then Berserker Rage (breaks and blocks fear). [M, adapted]",
  body = "#showtooltip Berserker Rage\n/cast [nostance:3] Berserker Stance\n/cast Berserker Rage" })

L.Add({ name = "Retaliation", category = "combat", class = "WARRIOR", order = 50, perCharacter = true,
  icon = "Retaliation", requires = { "Retaliation" }, tags = { "cooldown", "controller" }, untested = true,
  desc = "Retaliation in Battle Stance; from another stance, switches to Battle Stance first. [M, adapted]",
  body = "#showtooltip Retaliation\n/cast [stance:1] Retaliation; Battle Stance" })

L.Add({ name = "ShieldWall", category = "combat", class = "WARRIOR", order = 51, perCharacter = true,
  icon = "Shield Wall", requires = { "Shield Wall" }, tags = { "defensive", "cooldown", "controller" }, untested = true,
  desc = "Emergency: Defensive Stance if needed, Last Stand (if talented), then Shield Wall. [M]",
  body = "#showtooltip Shield Wall\n/cast [nostance:2] Defensive Stance\n/cast Last Stand\n/cast Shield Wall" })
