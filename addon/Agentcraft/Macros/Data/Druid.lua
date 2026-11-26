-- Druid macros. See Library.lua for the fields; data contract:
-- dev/layout-format.md. All untested on WoW Forever.
--
-- Sources:
--   * Heal macros: the "smart heal" pattern ([@target,help,nodead][@player])
--     from RankedBoost's WoW Forever paladin macros (2026-11), with
--     /cancelform added because Moonkin blocks heals and heals from Bear/Cat
--     may not shift you out by themselves (Icy Veins, WoW Forever druid
--     shapeshift forms, 2026-11-04; unverified in game). Wowhead's healing
--     guide (8753) recommends the same heals as mouseover macros; these are
--     the no-mouseover form.
--   * CatOpener: drafted from the Forever Feral opener (Prowl, then Ravage;
--     Shred before Ravage is trained; Method and Icy Veins Feral guides).
--     It is also Wowhead's "Conditional Ravage" (guide 8789).
--     [stealth] is assumed to cover Prowl, as on Classic.
--   * Wowhead Classic druid macro guides (read 2026-11-26):
--       Feral DPS  https://www.wowhead.com/classic/guide=8789
--       Feral tank https://www.wowhead.com/classic/guide=8853
--       Healing    https://www.wowhead.com/classic/guide=8753
--     -> CatDash ("Instant Dash"), CatProwl ("Instant Stealth"), BearCharge
--     ("Any Form into Feral Charge"), NSTouch (Nature's Swiftness + Healing
--     Touch), Innerv (Innervate on yourself), RemoveCurse (the healing
--     guide's mouseover pattern applied to the dispel).
--     Dropped: the powershift macros (Forever has no powershifting, and
--     entering Bear wipes energy), the consumable powershifts (items, and
--     /run SetCVar), weapon swaps (/equip: items), mouseover taunt and
--     Hurricane at cursor (no @mouseover / @cursor; without them they are
--     plain buttons), the modifier heal (no [mod]) and the form-cancel
--     macros (/cancelform is in the heals already).
-- Recommended per spec (specs = ..., tag "recommended"; owner, 2026-11-26):
--   balance:     Innerv, Rejuv, Regrow, HTouch
--   feral:       CatOpener, CatProwl, CatDash, BearCharge (cat DPS and bear tank)
--   restoration: Rejuv, Regrow, HTouch, NSTouch, Innerv, RemoveCurse
-- The old Form* macros (FormAttack ... FormSnare) were retired on purpose
-- (L.retiredShapes in Macros/Data/General.lua): the Feral controller page
-- holds the Cat and Bear kits as plain spells, so no macro is needed there.
-- No bear/cat weave macros: entering Bear wipes your energy on Forever.
-- Bear Form: the macros cast Dire Bear Form, then Bear Form, both only
-- outside form 1 (Bear and Dire Bear are always form 1: Bear is learned
-- first), so whichever you know is used and neither shifts you out.
local _, ns = ...
local L = ns.MacroLibrary

-- Heals and dispels (any form) ---------------------------------------------------

L.Add({ name = "Rejuv", category = "combat", class = "DRUID", order = 70, perCharacter = true,
  icon = "Rejuvenation", requires = { "Rejuvenation" }, tags = { "group", "controller", "recommended" }, untested = true,
  specs = { "balance", "restoration" },
  desc = "Drops any form, then Rejuvenation on your friendly target, or on yourself when you have none.",
  body = "#showtooltip Rejuvenation\n/cancelform\n/cast [@target,help,nodead][@player] Rejuvenation" })

L.Add({ name = "Regrow", category = "combat", class = "DRUID", order = 71, perCharacter = true,
  icon = "Regrowth", requires = { "Regrowth" }, tags = { "group", "controller", "recommended" }, untested = true,
  specs = { "balance", "restoration" },
  desc = "Drops any form, then Regrowth on your friendly target, or on yourself when you have none.",
  body = "#showtooltip Regrowth\n/cancelform\n/cast [@target,help,nodead][@player] Regrowth" })

L.Add({ name = "HTouch", category = "combat", class = "DRUID", order = 72, perCharacter = true,
  icon = "Healing Touch", requires = { "Healing Touch" }, tags = { "group", "controller", "recommended" }, untested = true,
  specs = { "balance", "restoration" },
  desc = "Drops any form, then Healing Touch on your friendly target, or on yourself when you have none.",
  body = "#showtooltip Healing Touch\n/cancelform\n/cast [@target,help,nodead][@player] Healing Touch" })

-- Wowhead guide 8753 (Nature's Swiftness + Healing Touch); Forever
-- Restoration: "Nature's Swiftness + Healing Touch for lethal damage".
-- Nature's Swiftness is off the global cooldown, so one press does both;
-- while it cools down this is a normal Healing Touch.
L.Add({ name = "NSTouch", category = "combat", class = "DRUID", order = 73, perCharacter = true,
  icon = "Nature's Swiftness", requires = { "Nature's Swiftness", "Healing Touch" }, tags = { "group", "burst", "recommended" }, untested = true,
  specs = { "restoration" },
  desc = "Drops any form, then Nature's Swiftness and an instant Healing Touch on your friendly target, or on yourself.",
  body = "#showtooltip Nature's Swiftness\n/cancelform\n/cast Nature's Swiftness\n/cast [@target,help,nodead][@player] Healing Touch" })

-- Wowhead guide 8753 (Innervate used on yourself).
L.Add({ name = "Innerv", category = "combat", class = "DRUID", order = 74, perCharacter = true,
  icon = "Innervate", requires = { "Innervate" }, tags = { "group", "recommended" }, untested = true,
  specs = { "balance", "restoration" },
  desc = "Drops any form, then Innervate on your friendly target, or on yourself when you have none.",
  body = "#showtooltip Innervate\n/cancelform\n/cast [@target,help,nodead][@player] Innervate" })

-- Wowhead guide 8753's mouseover pattern, applied to the curse dispel.
L.Add({ name = "RemoveCurse", category = "combat", class = "DRUID", order = 75, perCharacter = true,
  icon = "Remove Curse", requires = { "Remove Curse" }, tags = { "group", "recommended" }, untested = true,
  specs = { "restoration" },
  desc = "Drops any form, then Remove Curse on your friendly target, or on yourself when you have none.",
  body = "#showtooltip Remove Curse\n/cancelform\n/cast [@target,help,nodead][@player] Remove Curse" })

-- Cat -----------------------------------------------------------------------------

L.Add({ name = "CatOpener", category = "combat", class = "DRUID", order = 20, perCharacter = true,
  icon = "Prowl", requires = { "Prowl" }, tags = { "opener", "controller", "recommended" }, untested = true,
  specs = { "feral" },
  desc = "In Cat Form: out of combat, Prowl; while prowling, Ravage your target (Shred until you know Ravage). Get behind it first.",
  body = "#showtooltip\n/cast [nostealth,nocombat] Prowl; [@target,harm,nodead] Ravage\n/cast [stealth,@target,harm,nodead] Shred" })

-- Wowhead guides 8789 and 8753 ("Instant Stealth"). "!" keeps Cat Form from
-- toggling off when you are already in it.
L.Add({ name = "CatProwl", category = "combat", class = "DRUID", order = 21, perCharacter = true,
  icon = "Prowl", requires = { "Cat Form", "Prowl" }, tags = { "opener", "recommended" }, untested = true,
  specs = { "feral" },
  desc = "Shifts to Cat Form from any form (stays in it if you are), then Prowls.",
  body = "#showtooltip Prowl\n/cast !Cat Form\n/cast [nostealth] Prowl" })

-- Wowhead guides 8789 and 8753 ("Instant Dash"): Dash is off the global
-- cooldown, so it follows the shift at once.
L.Add({ name = "CatDash", category = "combat", class = "DRUID", order = 22, perCharacter = true,
  icon = "Dash", requires = { "Cat Form", "Dash" }, tags = { "movement", "recommended" }, untested = true,
  specs = { "feral" },
  desc = "Shifts to Cat Form from any form (stays in it if you are), then Dashes.",
  body = "#showtooltip Dash\n/cast !Cat Form\n/cast Dash" })

-- Bear ----------------------------------------------------------------------------

-- Wowhead guides 8853 and 8753 ("Any Form into Feral Charge"). Needs the
-- Furor talent for the rage to charge straight after shifting; spam it, as
-- Wowhead says, since that rage arrives a moment later.
L.Add({ name = "BearCharge", category = "combat", class = "DRUID", order = 30, perCharacter = true,
  icon = "Feral Charge", requires = { "Feral Charge" }, tags = { "movement", "tank", "recommended" }, untested = true,
  specs = { "feral" },
  desc = "Shifts to Bear Form from any other form, then Feral Charges your target (with Furor's rage).",
  body = "#showtooltip Feral Charge\n/cast [noform:1] Dire Bear Form\n/cast [noform:1] Bear Form\n/cast [form:1,@target,harm,nodead] Feral Charge" })
