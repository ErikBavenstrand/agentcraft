-- Rogue macros. See Library.lua for the fields. Sources:
--   Strike: Mobalytics WoW Forever rogue leveling guide (2026-11-12),
--     mobalytics.gg/wow-forever/classes/rogue-leveling-guide.
--   Premed: Icy Veins WoW Forever Subtlety rogue leveling (2026-11-18),
--     icy-veins.com/wow-forever/combat-rogue-leveling.
--   Blades: Icy Veins Combat rogue leveling, cooldown macro without its
--     trinket /use lines (trinkets have their own Alt keys).
--   Poof: written for Agentcraft (warcraft.wiki.gg /stopattack); untested.
-- Poisons are items, so no poison macros. No [stealth] macros: the
-- conditional is unverified on Forever and the keyboard's stealth page and
-- the controller's opener buttons cover it.
local _, ns = ...
local L = ns.MacroLibrary

L.Add({ name = "Strike", category = "combat", class = "ROGUE", order = 10, perCharacter = true, untested = true,
  icon = "Sinister Strike", requires = { "Sinister Strike" }, tags = { "rotation" },
  desc = "Starts melee and uses Riposte when it lights up after a parry, else Sinister Strike. Riposte is skipped until you have it.",
  body = "#showtooltip Sinister Strike\n/startattack\n/cast Riposte\n/cast Sinister Strike" })

L.Add({ name = "Premed", category = "combat", class = "ROGUE", order = 20, perCharacter = true, untested = true,
  icon = "Ambush", requires = { "Ambush" }, tags = { "opener" },
  desc = "From Stealth: Premeditation (2 combo points, no global cooldown) then Ambush. Premeditation is skipped until you have it.",
  body = "#showtooltip\n/cast Premeditation\n/cast Ambush" })

L.Add({ name = "Blades", category = "combat", class = "ROGUE", order = 30, perCharacter = true, untested = true,
  icon = "Blade Flurry", requires = { "Blade Flurry" }, tags = { "cooldown", "controller" },
  desc = "Both Combat cooldowns at once: Adrenaline Rush and Blade Flurry. Adrenaline Rush is skipped until you have it.",
  body = "#showtooltip\n/cast Adrenaline Rush\n/cast Blade Flurry" })

L.Add({ name = "Poof", category = "combat", class = "ROGUE", order = 40, perCharacter = true, untested = true,
  icon = "Vanish", requires = { "Vanish" }, tags = { "defensive" },
  desc = "A clean Vanish: stops your auto attack first, so the next swing doesn't pull you out of Stealth.",
  body = "#showtooltip Vanish\n/stopattack\n/cast Vanish" })
