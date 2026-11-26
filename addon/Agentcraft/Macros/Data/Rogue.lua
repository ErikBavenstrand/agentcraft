-- Rogue macros. See Library.lua for the fields. Sources:
--   Strike: Mobalytics WoW Forever rogue leveling guide (2026-11-12),
--     mobalytics.gg/wow-forever/classes/rogue-leveling-guide.
--   Premed: Icy Veins WoW Forever Subtlety rogue leveling (2026-11-18),
--     icy-veins.com/wow-forever/combat-rogue-leveling.
--   Blades: Icy Veins Combat rogue leveling, cooldown macro without its
--     trinket /use lines (trinkets have their own Alt keys).
--   Poof: written for Agentcraft (warcraft.wiki.gg /stopattack); untested.
--   PickGarrote: Wowhead WoW Forever rogue leveling tips ("macro Pick
--     Pocket into your opener", wowhead.com/forever/guide/classes/rogue/
--     combat/dps-leveling-tips) and ConquestCapped Forever Combat / Assassination /
--     Subtlety rotation pages (2026-11), "Pick Pocket before Garrote".
--   MutiAttack, HemoAttack, StealthOn: Wowhead's Classic rogue macro guide
--     (wowhead.com/classic/guide=8827): the "Auto-Attack Macro" (builder +
--     /startattack, here with Forever's Mutilate and Hemorrhage) and
--     "Spammable Stealth" (/stopattack + /cast !Stealth).
-- Left out of that guide: the Sap-a-stealthed-player and Expose Armor +
--   /targetlasttarget macros (PvP only), the Skull weapon swap (items) and
--   the mouseover Blind / Kick (no @mouseover; on your target they are one
--   plain /cast).
-- Recommended per spec (`specs`, the Layouts/Rogue.lua spec keys):
--   assassination MutiAttack, PickGarrote, Premed, StealthOn, Poof;
--   combat Strike, Blades, PickGarrote, StealthOn, Poof;
--   subtlety HemoAttack, Premed, PickGarrote, StealthOn, Poof.
-- Poisons are items, so no poison macros. No [stealth] macros: the
-- conditional is unverified on Forever and the keyboard's stealth page and
-- the controller's opener buttons cover it.
local _, ns = ...
local L = ns.MacroLibrary

L.Add({ name = "Strike", category = "combat", class = "ROGUE", order = 10, perCharacter = true, untested = true,
  icon = "Sinister Strike", requires = { "Sinister Strike" }, tags = { "rotation", "recommended" },
  specs = { "combat" },
  desc = "Starts melee and uses Riposte when it lights up after a parry, else Sinister Strike. Riposte is skipped until you have it.",
  body = "#showtooltip Sinister Strike\n/startattack\n/cast Riposte\n/cast Sinister Strike" })

-- wowhead.com/classic/guide=8827 (Auto-Attack Macro), with Mutilate.
L.Add({ name = "MutiAttack", category = "combat", class = "ROGUE", order = 11, perCharacter = true, untested = true,
  icon = "Mutilate", requires = { "Mutilate" }, tags = { "rotation", "recommended" },
  specs = { "assassination" },
  desc = "Starts melee, then Mutilate: a new target gets auto attacks without a separate click.",
  body = "#showtooltip Mutilate\n/startattack\n/cast [@target,harm,nodead] Mutilate" })

-- wowhead.com/classic/guide=8827 (Auto-Attack Macro, the Hemorrhage version).
L.Add({ name = "HemoAttack", category = "combat", class = "ROGUE", order = 12, perCharacter = true, untested = true,
  icon = "Hemorrhage", requires = { "Hemorrhage" }, tags = { "rotation", "recommended" },
  specs = { "subtlety" },
  desc = "Starts melee, then Hemorrhage: a new target gets auto attacks without a separate click.",
  body = "#showtooltip Hemorrhage\n/startattack\n/cast [@target,harm,nodead] Hemorrhage" })

L.Add({ name = "Premed", category = "combat", class = "ROGUE", order = 20, perCharacter = true, untested = true,
  icon = "Ambush", requires = { "Ambush" }, tags = { "opener", "recommended" },
  specs = { "assassination", "subtlety" },
  desc = "From Stealth: Premeditation (2 combo points, no global cooldown) then Ambush. Premeditation is skipped until you have it.",
  body = "#showtooltip\n/cast Premeditation\n/cast Ambush" })

L.Add({ name = "Blades", category = "combat", class = "ROGUE", order = 30, perCharacter = true, untested = true,
  icon = "Blade Flurry", requires = { "Blade Flurry" }, tags = { "cooldown", "controller", "recommended" },
  specs = { "combat" },
  desc = "Both Combat cooldowns at once: Adrenaline Rush and Blade Flurry. Adrenaline Rush is skipped until you have it.",
  body = "#showtooltip\n/cast Adrenaline Rush\n/cast Blade Flurry" })

L.Add({ name = "Poof", category = "combat", class = "ROGUE", order = 40, perCharacter = true, untested = true,
  icon = "Vanish", requires = { "Vanish" }, tags = { "defensive", "recommended" },
  specs = { "assassination", "combat", "subtlety" },
  desc = "A clean Vanish: stops your auto attack first, so the next swing doesn't pull you out of Stealth.",
  body = "#showtooltip Vanish\n/stopattack\n/cast Vanish" })

-- wowhead.com/classic/guide=8827 (Spammable Stealth).
L.Add({ name = "StealthOn", category = "combat", class = "ROGUE", order = 41, perCharacter = true, untested = true,
  icon = "Stealth", requires = { "Stealth" }, tags = { "opener", "recommended" },
  specs = { "assassination", "combat", "subtlety" },
  desc = "Stealth you can press twice: it never cancels Stealth once you're in it, and stops your auto attack first.",
  body = "#showtooltip Stealth\n/stopattack\n/cast !Stealth" })

L.Add({ name = "PickGarrote", category = "combat", class = "ROGUE", order = 25, perCharacter = true, untested = true,
  icon = "Garrote", requires = { "Garrote" }, tags = { "opener", "recommended" },
  specs = { "assassination", "combat", "subtlety" },
  desc = "From Stealth: Pick Pocket (free loot, no global cooldown) then Garrote. In combat (Subtlety, after Ghostly Strike) Pick Pocket just fails and Garrote goes out.",
  body = "#showtooltip Garrote\n/cast Pick Pocket\n/cast Garrote" })
