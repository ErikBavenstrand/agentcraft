-- Priest macros. See Library.lua for the fields. All new for WoW Forever and
-- untested in game. Sources:
--   * Flay: the warlock "/cast [nochanneling:Drain Life] Drain Life" pattern
--     (Mobalytics warlock leveling guide, 2026-11), applied to Mind Flay.
--   * MindPull: Agentcraft's hunter Opener (target pick-up), with the
--     Shadow pull from Wowhead's Forever Shadow guides (2026-11-26): "Begin
--     combat by casting Mind Blast" while leveling, pre-cast Mind Blast at
--     60. It is Shadow's Mind Blast home (R / RT Y), so one button pulls and
--     casts Mind Blast on cooldown.
--   * Empower: Agentcraft's hunter Burst pattern; Inner Focus (row 2 = 20)
--     and Power Infusion (row 6 = 40) are Discipline talents
--     (dev/forever-talents.md, earlier with Talented); Wowhead's Discipline guide: use Inner Focus often, with
--     Prayer of Healing or Greater Heal, not only in emergencies.
--   * PriestHeal, PriestRenew, PriestFlash, PriestShield: Wowhead's Classic
--     healing priest macro guide (wowhead.com/classic/guide=8730, "Mouseover
--     healing macro", "Power Word: Shield") and Shadow guide
--     (wowhead.com/classic/guide=8829, "Self Target Power Word: Shield"),
--     rewritten without @mouseover: your friendly living target, else you.
--     That keeps an enemy target while you heal or shield yourself, skips a
--     dead friend, and works with the game's auto self-cast turned off.
--     Their /stopcasting is left out: a heal button you mash would cancel
--     its own cast.
--   * DispelMagic: guide 8730 "Dispel Magic" (one button: friend, enemy, or
--     you), without the mouseover part.
--   * ShadowOn: guide 8829 "Spammable Shadowform" (/cast !Shadowform never
--     cancels the form); its /stopattack is left out (priests wand).
-- Left out of those guides: Greater Heal(Rank 1) downranking (ranks differ
--   on Forever), the /targetenemyplayer mind-control dispel and the
--   mouseover Silence (no @mouseover; on your target it is one plain /cast),
--   Heal/Smite swap (healers keep damage on Shift), food and off-hand swaps
--   (items).
-- Recommended per spec (`specs`, the Layouts/Priest.lua spec keys):
--   discipline PriestShield, PriestHeal, PriestRenew, PriestFlash,
--     DispelMagic, Empower;
--   holy PriestHeal, PriestRenew, PriestFlash, PriestShield, DispelMagic;
--   shadow Flay, MindPull, ShadowOn, PriestShield, PriestFlash, PriestRenew.
-- A wand macro is left out ("/cast !Shoot" is a one-line wrapper; Shoot sits
-- on a key itself).
local _, ns = ...
local L = ns.MacroLibrary

L.Add({ name = "Flay", category = "combat", class = "PRIEST", order = 20, perCharacter = true,
  icon = "Mind Flay", requires = { "Mind Flay" }, tags = { "rotation", "controller", "recommended" }, untested = true,
  specs = { "shadow" },
  desc = "Mind Flay that never clips itself: pressing it again while Mind Flay channels does nothing, so you can hold or mash the button.",
  body = "#showtooltip Mind Flay\n/cast [@target,harm,nodead,nochanneling:Mind Flay] Mind Flay" })

L.Add({ name = "MindPull", category = "combat", class = "PRIEST", order = 10, perCharacter = true,
  icon = "Mind Blast", requires = { "Mind Blast" }, tags = { "opener", "rotation", "controller", "recommended" }, untested = true,
  specs = { "shadow" },
  desc = "Mind Blast that also pulls: drops a dead or friendly target, picks the nearest enemy if you have none, then Mind Blast.",
  body = "#showtooltip Mind Blast\n/cleartarget [dead][help]\n/targetenemy [noexists]\n/cast [@target,harm,nodead] Mind Blast" })

L.Add({ name = "Empower", category = "combat", class = "PRIEST", order = 30, perCharacter = true,
  icon = "Power Infusion", tags = { "cooldown", "controller", "recommended" }, untested = true,
  specs = { "discipline" },
  desc = "Every cooldown at once: Inner Focus, both trinkets, Berserking, then Power Infusion on your friendly target (else on you). Anything you don't have is skipped.",
  body = "#showtooltip\n/cast Inner Focus\n/use 13\n/use 14\n/cast Berserking\n/cast [@target,help,nodead][@player] Power Infusion" })

-- Healing: friendly living target, else you (wowhead.com/classic/guide=8730).
L.Add({ name = "PriestHeal", category = "combat", class = "PRIEST", order = 40, perCharacter = true,
  icon = "Heal", requires = { "Heal" }, tags = { "rotation", "group", "recommended" }, untested = true,
  specs = { "discipline", "holy" },
  desc = "Heal on your target if it's a living friend, else on yourself, so you never have to drop an enemy target to heal.",
  body = "#showtooltip Heal\n/cast [@target,help,nodead][@player] Heal" })

L.Add({ name = "PriestRenew", category = "combat", class = "PRIEST", order = 41, perCharacter = true,
  icon = "Renew", requires = { "Renew" }, tags = { "rotation", "group", "recommended" }, untested = true,
  specs = { "discipline", "holy", "shadow" },
  desc = "Renew on your target if it's a living friend, else on yourself.",
  body = "#showtooltip Renew\n/cast [@target,help,nodead][@player] Renew" })

L.Add({ name = "PriestFlash", category = "combat", class = "PRIEST", order = 42, perCharacter = true,
  icon = "Flash Heal", requires = { "Flash Heal" }, tags = { "defensive", "group", "recommended" }, untested = true,
  specs = { "discipline", "holy", "shadow" },
  desc = "Flash Heal on your target if it's a living friend, else on yourself: Shadow heals itself without losing its enemy target.",
  body = "#showtooltip Flash Heal\n/cast [@target,help,nodead][@player] Flash Heal" })

-- wowhead.com/classic/guide=8730 (Power Word: Shield) and guide=8829
-- (Self Target Power Word: Shield).
L.Add({ name = "PriestShield", category = "combat", class = "PRIEST", order = 43, perCharacter = true,
  icon = "Power Word: Shield", requires = { "Power Word: Shield" }, tags = { "defensive", "group", "recommended" }, untested = true,
  specs = { "discipline", "holy", "shadow" },
  desc = "Power Word: Shield on your target if it's a living friend, else on yourself: shield the tank, or yourself while you keep the enemy targeted.",
  body = "#showtooltip Power Word: Shield\n/cast [@target,help,nodead][@player] Power Word: Shield" })

-- wowhead.com/classic/guide=8730 (Dispel Magic).
L.Add({ name = "DispelMagic", category = "combat", class = "PRIEST", order = 44, perCharacter = true,
  icon = "Dispel Magic", requires = { "Dispel Magic" }, tags = { "group", "recommended" }, untested = true,
  specs = { "discipline", "holy" },
  desc = "Dispel Magic on your target, friend (removes a debuff) or enemy (removes a buff); with no living target, on yourself.",
  body = "#showtooltip Dispel Magic\n/cast [@target,help,nodead][@target,harm,nodead][@player] Dispel Magic" })

-- wowhead.com/classic/guide=8829 (Spammable Shadowform).
L.Add({ name = "ShadowOn", category = "combat", class = "PRIEST", order = 50, perCharacter = true,
  icon = "Shadowform", requires = { "Shadowform" }, tags = { "recommended" }, untested = true,
  specs = { "shadow" },
  desc = "Shadowform you can press twice: it never cancels the form once you're in it, and stops a cast in progress first.",
  body = "#showtooltip Shadowform\n/stopcasting\n/cast !Shadowform" })
