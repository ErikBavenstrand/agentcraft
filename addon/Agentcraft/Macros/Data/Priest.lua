-- Priest macros. See Library.lua for the fields. All new for WoW Forever and
-- untested in game. Sources:
--   * Flay: the warlock "/cast [nochanneling:Drain Life] Drain Life" pattern
--     (Mobalytics warlock leveling guide, 2026-11), applied to Mind Flay.
--   * MindPull: Agentcraft's hunter Opener (target pick-up), with the
--     Shadow pull from Icy Veins' Shadow priest leveling guide (2026-11-17):
--     open with Mind Blast.
--   * Empower: Agentcraft's hunter Burst pattern; Inner Focus and Power
--     Infusion are Discipline talents (warcraft.wiki.gg Priest abilities
--     (Forever)).
--
-- Left out on purpose: a wand macro ("/cast !Shoot" is a one-line wrapper;
-- Shoot sits on a key itself) and "[@target,help,nodead][@player]" heal
-- macros (auto self-cast already heals you when your target isn't friendly).
local _, ns = ...
local L = ns.MacroLibrary

L.Add({ name = "Flay", category = "combat", class = "PRIEST", order = 20, perCharacter = true,
  icon = "Mind Flay", requires = { "Mind Flay" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Mind Flay that never clips itself: pressing it again while Mind Flay channels does nothing, so you can hold or mash the button.",
  body = "#showtooltip Mind Flay\n/cast [@target,harm,nodead,nochanneling:Mind Flay] Mind Flay" })

L.Add({ name = "MindPull", category = "combat", class = "PRIEST", order = 10, perCharacter = true,
  icon = "Mind Blast", requires = { "Mind Blast" }, tags = { "opener", "rotation", "controller" }, untested = true,
  desc = "Drops a dead or friendly target, picks the nearest enemy if you have none, then Mind Blast.",
  body = "#showtooltip Mind Blast\n/cleartarget [dead][help]\n/targetenemy [noexists]\n/cast [@target,harm,nodead] Mind Blast" })

L.Add({ name = "Empower", category = "combat", class = "PRIEST", order = 30, perCharacter = true,
  icon = "Power Infusion", tags = { "cooldown", "controller" }, untested = true,
  desc = "Every cooldown at once: Inner Focus, both trinkets, Berserking, then Power Infusion on your friendly target (else on you). Anything you don't have is skipped.",
  body = "#showtooltip\n/cast Inner Focus\n/use 13\n/use 14\n/cast Berserking\n/cast [@target,help,nodead][@player] Power Infusion" })
