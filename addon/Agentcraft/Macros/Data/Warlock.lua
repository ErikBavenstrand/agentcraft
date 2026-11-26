-- Warlock macros. See Library.lua for the fields. Sources:
--   * DrainLife, DrainSoul, Wrack: Mobalytics WoW Forever warlock leveling
--     guide (mobalytics.gg/wow-forever/classes/warlock-leveling-guide,
--     2026-11-23): "/cast [nochanneling:Drain Life] Drain Life"; the Drain
--     Soul and Wrack versions use the same pattern.
--   * PetSpecial: same Mobalytics guide ("[pet:Felhunter] Spell Lock;
--     [pet:Voidwalker] Sacrifice; [pet:Succubus] Seduction"). Whether
--     [pet:Succubus] or [pet:Sayaad] matches Forever's Sayaad is
--     unverified, so both are tried, plus [pet:Incubus] for the male form.
--   * Auto <ability>: the hunter autocast toggles (Hunter.lua) for Classic
--     warlock demon abilities, written fresh; which of them autocast on
--     Forever is unverified.
--   * Wowhead, Warlock Classic macro guide (guide 8791, read 2026-11-26):
--     https://www.wowhead.com/classic/guide=8791
--     It has no DPS macros ("no real major DPS macros"); of its utility
--     macros: "All in one Pet casts" is PetSpecial; "Self Dispell" is
--     SelfDevour (cast on yourself instead of /target + CastPetAction);
--     "Focus Target" (a spell on your focus, then back) is FearFocus and
--     HavocFocus, with [@focus] in place of the target swap.
--     Dropped: the soul-shard delete script (deletes bag items) and Totem
--     Stomp (/petattack, which the owner wants none of).
-- Recommended per spec (specs = ..., tag "recommended"; owner, 2026-11-26):
--   affliction:  DrainLife, DrainSoul, Wrack, PetSpecial, SelfDevour, FearFocus
--   demonology:  DrainLife, DrainSoul, PetSpecial, SelfDevour, FearFocus
--   destruction: DrainLife, DrainSoul, PetSpecial, SelfDevour, HavocFocus
-- Every macro is untested on WoW Forever.
local _, ns = ...
local L = ns.MacroLibrary

-- Combat -----------------------------------------------------------------------

L.Add({ name = "DrainLife", category = "combat", class = "WARLOCK", order = 20, perCharacter = true,
  icon = "Drain Life", requires = { "Drain Life" }, tags = { "rotation", "defensive", "recommended" }, untested = true,
  specs = { "affliction", "demonology", "destruction" },
  desc = "Drain Life that never restarts the channel when you press it again mid-drain.",
  body = "#showtooltip Drain Life\n/cast [nochanneling:Drain Life] Drain Life" })

L.Add({ name = "DrainSoul", category = "combat", class = "WARLOCK", order = 21, perCharacter = true,
  icon = "Drain Soul", requires = { "Drain Soul" }, tags = { "rotation", "recommended" }, untested = true,
  specs = { "affliction", "demonology", "destruction" },
  desc = "Drain Soul that never restarts the channel when you press it again, so a shard tick isn't lost.",
  body = "#showtooltip Drain Soul\n/cast [nochanneling:Drain Soul] Drain Soul" })

L.Add({ name = "Wrack", category = "combat", class = "WARLOCK", order = 22, perCharacter = true,
  icon = "Wrack", requires = { "Wrack" }, tags = { "rotation", "recommended" }, untested = true,
  specs = { "affliction" },
  desc = "Wrack (Affliction filler) that never restarts the channel when you press it again.",
  body = "#showtooltip Wrack\n/cast [nochanneling:Wrack] Wrack" })

-- Wowhead guide 8791 ("Focus Target"): Fear the second mob while you DoT
-- the first (Forever Affliction and Demonology leveling: "two mobs: DoT and
-- Fear one"). Without a focus it Fears your target.
L.Add({ name = "FearFocus", category = "combat", class = "WARLOCK", order = 30, perCharacter = true,
  icon = "Fear", requires = { "Fear" }, tags = { "crowd control", "recommended" }, untested = true,
  specs = { "affliction", "demonology" },
  desc = "Fears your focus without changing target, or your target when you have no hostile focus.",
  body = "#showtooltip Fear\n/cast [@focus,harm,nodead][@target,harm,nodead] Fear" })

-- Wowhead guide 8791 ("Focus Target"): Forever Destruction puts Bane of
-- Havoc on the second target; set it as focus and keep your target.
L.Add({ name = "HavocFocus", category = "combat", class = "WARLOCK", order = 31, perCharacter = true,
  icon = "Bane of Havoc", requires = { "Bane of Havoc" }, tags = { "rotation", "recommended" }, untested = true,
  specs = { "destruction" },
  desc = "Bane of Havoc on your focus (the second target) without changing target, or on your target when you have no hostile focus.",
  body = "#showtooltip Bane of Havoc\n/cast [@focus,harm,nodead][@target,harm,nodead] Bane of Havoc" })

-- Pet --------------------------------------------------------------------------

-- Wowhead guide 8791 ("All in one Pet casts").
L.Add({ name = "PetSpecial", category = "pet", class = "WARLOCK", order = 10, perCharacter = true,
  specs = { "affliction", "demonology", "destruction" },
  iconFile = "Spell_Shadow_SummonFelHunter", requires = { "Summon Voidwalker" }, tags = { "crowd control", "controller", "recommended" }, untested = true,
  desc = "Your demon's control spell on one button: Spell Lock (Felhunter), Sacrifice (Voidwalker) or Seduction (Sayaad).",
  body = "#showtooltip\n/cast [pet:Felhunter] Spell Lock; [pet:Voidwalker] Sacrifice; [pet:Sayaad] Seduction; [pet:Succubus] Seduction; [pet:Incubus] Seduction" })

-- Wowhead guide 8791 ("Self Dispell"): the Felhunter's Devour Magic on you,
-- without the /target and CastPetAction(4) dance.
L.Add({ name = "SelfDevour", category = "pet", class = "WARLOCK", order = 11, perCharacter = true,
  icon = "Devour Magic", iconFile = "Spell_Nature_Purge", requires = { "Summon Felhunter" }, tags = { "defensive", "recommended" }, untested = true,
  specs = { "affliction", "demonology", "destruction" },
  desc = "Your Felhunter casts Devour Magic on you, whatever you have targeted.",
  body = "#showtooltip Devour Magic\n/cast [@player] Devour Magic" })

-- Autocast toggles for demon abilities. The controller's { petauto = true }
-- buttons use the one for each ability your demon has, once installed here.
L.Add({ name = "Auto Firebolt", category = "pet", class = "WARLOCK", order = 101, perCharacter = true, icon = "Firebolt", iconFile = "Spell_Fire_FireBolt",
  petAbility = "Firebolt", tags = { "controller", "autocast" }, untested = true, desc = "Turns autocast of your Imp's Firebolt on or off.",
  body = "#showtooltip Firebolt\n/petautocasttoggle Firebolt" })
L.Add({ name = "Auto Torment", category = "pet", class = "WARLOCK", order = 102, perCharacter = true, icon = "Torment", iconFile = "Spell_Shadow_GatherShadows",
  petAbility = "Torment", tags = { "controller", "autocast" }, untested = true, desc = "Turns autocast of your Voidwalker's Torment on or off.",
  body = "#showtooltip Torment\n/petautocasttoggle Torment" })
L.Add({ name = "Auto Suffering", category = "pet", class = "WARLOCK", order = 103, perCharacter = true, icon = "Suffering", iconFile = "Spell_Shadow_BlackPlague",
  petAbility = "Suffering", tags = { "controller", "autocast" }, untested = true, desc = "Turns autocast of your Voidwalker's Suffering on or off.",
  body = "#showtooltip Suffering\n/petautocasttoggle Suffering" })
L.Add({ name = "Auto Consume", category = "pet", class = "WARLOCK", order = 104, perCharacter = true, icon = "Consume Shadows", iconFile = "Spell_Shadow_AntiShadow",
  petAbility = "Consume Shadows", tags = { "controller", "autocast" }, untested = true, desc = "Turns autocast of your Voidwalker's Consume Shadows on or off.",
  body = "#showtooltip Consume Shadows\n/petautocasttoggle Consume Shadows" })
L.Add({ name = "Auto Lash", category = "pet", class = "WARLOCK", order = 105, perCharacter = true, icon = "Lash of Pain", iconFile = "Spell_Shadow_Curse",
  petAbility = "Lash of Pain", tags = { "controller", "autocast" }, untested = true, desc = "Turns autocast of your Sayaad's Lash of Pain on or off.",
  body = "#showtooltip Lash of Pain\n/petautocasttoggle Lash of Pain" })
L.Add({ name = "Auto Kiss", category = "pet", class = "WARLOCK", order = 106, perCharacter = true, icon = "Soothing Kiss", iconFile = "Spell_Shadow_SoothingKiss",
  petAbility = "Soothing Kiss", tags = { "controller", "autocast" }, untested = true, desc = "Turns autocast of your Sayaad's Soothing Kiss on or off.",
  body = "#showtooltip Soothing Kiss\n/petautocasttoggle Soothing Kiss" })
L.Add({ name = "Auto Devour", category = "pet", class = "WARLOCK", order = 107, perCharacter = true, icon = "Devour Magic", iconFile = "Spell_Nature_Purge",
  petAbility = "Devour Magic", tags = { "controller", "autocast" }, untested = true, desc = "Turns autocast of your Felhunter's Devour Magic on or off.",
  body = "#showtooltip Devour Magic\n/petautocasttoggle Devour Magic" })
L.Add({ name = "Auto Tainted", category = "pet", class = "WARLOCK", order = 108, perCharacter = true, icon = "Tainted Blood", iconFile = "Spell_Shadow_LifeDrain",
  petAbility = "Tainted Blood", tags = { "controller", "autocast" }, untested = true, desc = "Turns autocast of your Felhunter's Tainted Blood on or off.",
  body = "#showtooltip Tainted Blood\n/petautocasttoggle Tainted Blood" })
