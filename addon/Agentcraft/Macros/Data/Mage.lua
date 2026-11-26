-- Mage macros. See Library.lua for the fields. Sources:
--   Skill Capped, WoW Forever frost mage PvP macros (2026):
--     https://www.skill-capped.com/wowarticles/forever/guides/frost-mage-pvp-guide/macros/
--     -> PolyFocus, CounterFocus, ArmorSwap, BlockBreak, BlockLance
--   Blizzard forums, "Mage macros for Classic" (2019):
--     https://us.forums.blizzard.com/en/wow/t/mage-macros-for-classic/302604
--     -> ConjureBoth
--   Wowhead, DPS Mage Classic macro guide (guide 8750, read 2026-11-26):
--     https://www.wowhead.com/classic/guide=8750
--     -> Counter ("Immediate Spell"), PoMPyro ("Instant Pyroblast"),
--     Decurse ("Self & mouse-over de-curse", without the mouseover),
--     ConjureBoth ("Water and Food Creation")
-- Recommended per spec (specs = ..., tag "recommended"; owner, 2026-11-26):
--   arcane: Counter, PoMPyro, Decurse, ConjureBoth
--   fire:   Counter, Decurse, ConjureBoth
--   frost:  Counter, Decurse, ConjureBoth, BlockBreak, BlockLance
-- Left out on purpose: the popular Blizzard [@cursor] macro (no @cursor:
-- Blizzard is a plain button), mouseover Polymorph, Wowhead's totem-target
-- macro (PvP; it swaps your target), its named-mob Fire Blast macro (edited
-- per mob) and its modifier macros (no [mod]).
local _, ns = ...
local L = ns.MacroLibrary

-- Combat -----------------------------------------------------------------------

-- Wowhead guide 8750 ("Immediate Spell macro"): stops your own cast so the
-- interrupt goes out at once.
L.Add({ name = "Counter", category = "combat", class = "MAGE", order = 10, perCharacter = true,
  icon = "Counterspell", requires = { "Counterspell" }, tags = { "rotation", "recommended" }, untested = true,
  specs = { "arcane", "fire", "frost" },
  desc = "Stops your own cast and Counterspells your target at once.",
  body = "#showtooltip Counterspell\n/stopcasting\n/cast [@target,harm,nodead] Counterspell" })

-- Wowhead guide 8750 ("Instant Pyroblast"): Presence of Mind is off the
-- global cooldown, so both go out on one press. While it cools down this is
-- a normal Pyroblast. Arcane's Arcane Fire build (Pyroblast is a Fire talent).
L.Add({ name = "PoMPyro", category = "combat", class = "MAGE", order = 11, perCharacter = true,
  icon = "Pyroblast", requires = { "Presence of Mind", "Pyroblast" }, tags = { "burst", "recommended" }, untested = true,
  specs = { "arcane" },
  desc = "Presence of Mind, then an instant Pyroblast on your target; a normal Pyroblast while Presence of Mind cools down.",
  body = "#showtooltip Pyroblast\n/stopcasting\n/cast Presence of Mind\n/cast [@target,harm,nodead] Pyroblast" })

L.Add({ name = "PolyFocus", category = "combat", class = "MAGE", order = 20, perCharacter = true,
  icon = "Polymorph", requires = { "Polymorph" }, tags = { "crowd control" }, untested = true,
  desc = "Polymorphs your focus without changing target. Alternates ranks, because a sheep can't be refreshed with the same or a lower rank; resets after 15 seconds.",
  body = "#showtooltip Polymorph\n/castsequence [@focus] reset=15 Polymorph(Rank 1), Polymorph(Rank 2)" })

L.Add({ name = "CounterFocus", category = "combat", class = "MAGE", order = 21, perCharacter = true,
  icon = "Counterspell", requires = { "Counterspell" }, tags = { "crowd control" }, untested = true,
  desc = "Stops your own cast and Counterspells your focus without changing target.",
  body = "#showtooltip Counterspell\n/stopcasting\n/cast [@focus] Counterspell" })

L.Add({ name = "BlockBreak", category = "combat", class = "MAGE", order = 30, perCharacter = true,
  icon = "Ice Block", requires = { "Ice Block" }, tags = { "defensive", "recommended" }, untested = true,
  specs = { "frost" },
  desc = "Ice Block; press again while in the block to leave it early.",
  body = "#showtooltip Ice Block\n/cast Ice Block\n/cancelaura Ice Block" })

L.Add({ name = "BlockLance", category = "combat", class = "MAGE", order = 31, perCharacter = true,
  icon = "Ice Lance", requires = { "Ice Lance" }, tags = { "rotation", "defensive", "recommended" }, untested = true,
  specs = { "frost" },
  desc = "Ice Lance that first breaks your Ice Block, so you can strike the moment you leave it. Outside the block it is a plain Ice Lance.",
  body = "#showtooltip Ice Lance\n/cancelaura Ice Block\n/cast Ice Lance" })

-- Wowhead guide 8750 ("Self & mouse-over de-curse"), with the friendly
-- target or yourself in place of the mouseover.
L.Add({ name = "Decurse", category = "combat", class = "MAGE", order = 50, perCharacter = true,
  icon = "Remove Lesser Curse", requires = { "Remove Lesser Curse" }, tags = { "group", "recommended" }, untested = true,
  specs = { "arcane", "fire", "frost" },
  desc = "Remove Lesser Curse on your friendly target, or on yourself when you have none.",
  body = "#showtooltip Remove Lesser Curse\n/cast [@target,help,nodead][@player] Remove Lesser Curse" })

-- Utility ----------------------------------------------------------------------

L.Add({ name = "ArmorSwap", category = "utility", class = "MAGE", order = 40, perCharacter = true,
  icon = "Ice Armor", requires = { "Ice Armor", "Mage Armor" }, tags = { "defensive" }, untested = true,
  desc = "Each press switches between Ice Armor and Mage Armor.",
  body = "#showtooltip\n/castsequence Ice Armor, Mage Armor" })

-- Wowhead guide 8750 ("Water and Food Creation Macro").
L.Add({ name = "ConjureBoth", category = "utility", class = "MAGE", order = 41, perCharacter = true,
  icon = "Conjure Water", requires = { "Conjure Water", "Conjure Food" }, tags = { "recommended" }, untested = true,
  specs = { "arcane", "fire", "frost" },
  desc = "Conjures water, then food on the next press; starts over with water after 4 seconds idle.",
  body = "#showtooltip\n/castsequence reset=4 Conjure Water, Conjure Food" })
