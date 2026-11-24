-- Mage macros. See Library.lua for the fields. Sources:
--   Skill Capped, WoW Forever frost mage PvP macros (2026):
--     https://www.skill-capped.com/wowarticles/forever/guides/frost-mage-pvp-guide/macros/
--     -> PolyFocus, CounterFocus, ArmorSwap, BlockBreak, BlockLance
--   Blizzard forums, "Mage macros for Classic" (2019):
--     https://us.forums.blizzard.com/en/wow/t/mage-macros-for-classic/302604
--     -> ConjureBoth
-- Left out on purpose: the popular Blizzard [@cursor] macro (no @cursor:
-- Blizzard is a plain button) and mouseover Polymorph / decurse macros.
local _, ns = ...
local L = ns.MacroLibrary

-- Combat -----------------------------------------------------------------------

L.Add({ name = "PolyFocus", category = "combat", class = "MAGE", order = 20, perCharacter = true,
  icon = "Polymorph", requires = { "Polymorph" }, tags = { "crowd control" }, untested = true,
  desc = "Polymorphs your focus without changing target. Alternates ranks, because a sheep can't be refreshed with the same or a lower rank; resets after 15 seconds.",
  body = "#showtooltip Polymorph\n/castsequence [@focus] reset=15 Polymorph(Rank 1), Polymorph(Rank 2)" })

L.Add({ name = "CounterFocus", category = "combat", class = "MAGE", order = 21, perCharacter = true,
  icon = "Counterspell", requires = { "Counterspell" }, tags = { "crowd control" }, untested = true,
  desc = "Stops your own cast and Counterspells your focus without changing target.",
  body = "#showtooltip Counterspell\n/stopcasting\n/cast [@focus] Counterspell" })

L.Add({ name = "BlockBreak", category = "combat", class = "MAGE", order = 30, perCharacter = true,
  icon = "Ice Block", requires = { "Ice Block" }, tags = { "defensive" }, untested = true,
  desc = "Ice Block; press again while in the block to leave it early.",
  body = "#showtooltip Ice Block\n/cast Ice Block\n/cancelaura Ice Block" })

L.Add({ name = "BlockLance", category = "combat", class = "MAGE", order = 31, perCharacter = true,
  icon = "Ice Lance", requires = { "Ice Lance" }, tags = { "rotation", "defensive" }, untested = true,
  desc = "Ice Lance that first breaks your Ice Block, so you can strike the moment you leave it. Outside the block it is a plain Ice Lance.",
  body = "#showtooltip Ice Lance\n/cancelaura Ice Block\n/cast Ice Lance" })

-- Utility ----------------------------------------------------------------------

L.Add({ name = "ArmorSwap", category = "utility", class = "MAGE", order = 40, perCharacter = true,
  icon = "Ice Armor", requires = { "Ice Armor", "Mage Armor" }, tags = { "defensive" }, untested = true,
  desc = "Each press switches between Ice Armor and Mage Armor.",
  body = "#showtooltip\n/castsequence Ice Armor, Mage Armor" })

L.Add({ name = "ConjureBoth", category = "utility", class = "MAGE", order = 41, perCharacter = true,
  icon = "Conjure Water", requires = { "Conjure Water", "Conjure Food" }, untested = true,
  desc = "Conjures water, then food on the next press; starts over with water after 4 seconds idle.",
  body = "#showtooltip\n/castsequence reset=4 Conjure Water, Conjure Food" })
