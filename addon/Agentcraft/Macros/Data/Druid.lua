-- Druid macros. See Library.lua for the fields; data contract:
-- dev/layout-format.md. All untested on WoW Forever.
--
-- Sources:
--   * Heal macros: the "smart heal" pattern ([@target,help,nodead][@player])
--     from RankedBoost's WoW Forever paladin macros (2026-11), with
--     /cancelform added because Moonkin blocks heals and heals from Bear/Cat
--     may not shift you out by themselves (Icy Veins, WoW Forever druid
--     shapeshift forms, 2026-11-04; unverified in game).
--   * CatOpener: drafted from the Forever Feral opener (Prowl, then Ravage;
--     Shred before Ravage is trained; Method and Icy Veins Feral guides).
--     [stealth] is assumed to cover Prowl, as on Classic.
--   * Form macros (FormAttack ... FormMove): drafted for the controller,
--     whose bars don't page by form. One button per key role
--     (dev/key-roles.md) casts the Bear spell in form 1 (Bear and Dire Bear
--     are always form 1: Bear is learned first), the Cat spell in form 2 or
--     3 (Cat is 2 without Aquatic Form, else 3; the other one is a water or
--     travel form where the cat spell just fails), else the caster spell
--     (caster form, Moonkin). They never change form.
-- No bear/cat weave macros: entering Bear wipes your energy on Forever.
local _, ns = ...
local L = ns.MacroLibrary

L.Add({ name = "Rejuv", category = "combat", class = "DRUID", order = 70, perCharacter = true,
  icon = "Rejuvenation", requires = { "Rejuvenation" }, tags = { "group", "controller" }, untested = true,
  desc = "Drops any form, then Rejuvenation on your friendly target, or on yourself when you have none.",
  body = "#showtooltip Rejuvenation\n/cancelform\n/cast [@target,help,nodead][@player] Rejuvenation" })

L.Add({ name = "Regrow", category = "combat", class = "DRUID", order = 71, perCharacter = true,
  icon = "Regrowth", requires = { "Regrowth" }, tags = { "group", "controller" }, untested = true,
  desc = "Drops any form, then Regrowth on your friendly target, or on yourself when you have none.",
  body = "#showtooltip Regrowth\n/cancelform\n/cast [@target,help,nodead][@player] Regrowth" })

L.Add({ name = "HTouch", category = "combat", class = "DRUID", order = 72, perCharacter = true,
  icon = "Healing Touch", requires = { "Healing Touch" }, tags = { "group", "controller" }, untested = true,
  desc = "Drops any form, then Healing Touch on your friendly target, or on yourself when you have none.",
  body = "#showtooltip Healing Touch\n/cancelform\n/cast [@target,help,nodead][@player] Healing Touch" })

L.Add({ name = "CatOpener", category = "combat", class = "DRUID", order = 20, perCharacter = true,
  icon = "Prowl", requires = { "Prowl" }, tags = { "opener", "controller" }, untested = true,
  desc = "In Cat Form: out of combat, Prowl; while prowling, Ravage your target (Shred until you know Ravage). Get behind it first.",
  body = "#showtooltip\n/cast [nostealth,nocombat] Prowl; [@target,harm,nodead] Ravage\n/cast [stealth,@target,harm,nodead] Shred" })

-- Controller form macros: one button per key role.

L.Add({ name = "FormAttack", category = "combat", class = "DRUID", order = 30, perCharacter = true,
  icon = "Claw", requires = { "Bear Form" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Main attack for your form: Maul in Bear, Claw in Cat, else Wrath.",
  body = "#showtooltip\n/cast [form:1] Maul; [form:2/3] Claw; [@target,harm,nodead] Wrath" })

L.Add({ name = "FormDoT", category = "combat", class = "DRUID", order = 31, perCharacter = true,
  icon = "Rake", requires = { "Bear Form" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Bleed or DoT for your form: Lacerate in Bear, Rake in Cat, else Moonfire.",
  body = "#showtooltip\n/cast [form:1] Lacerate; [form:2/3] Rake; [@target,harm,nodead] Moonfire" })

L.Add({ name = "FormBig", category = "combat", class = "DRUID", order = 32, perCharacter = true,
  icon = "Ferocious Bite", requires = { "Bear Form" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Big hitter for your form: Primal Bite in Bear, Ferocious Bite in Cat, else Starfire.",
  body = "#showtooltip\n/cast [form:1] Primal Bite; [form:2/3] Ferocious Bite; [@target,harm,nodead] Starfire" })

L.Add({ name = "FormSig", category = "combat", class = "DRUID", order = 33, perCharacter = true,
  icon = "Rip", requires = { "Bear Form" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Signature for your form: Growl in Bear, Rip in Cat, else Insect Swarm.",
  body = "#showtooltip\n/cast [form:1] Growl; [form:2/3] Rip; [@target,harm,nodead] Insect Swarm" })

L.Add({ name = "FormOpen", category = "combat", class = "DRUID", order = 34, perCharacter = true,
  icon = "Prowl", requires = { "Bear Form" }, tags = { "opener", "controller" }, untested = true,
  desc = "Opener for your form: Enrage in Bear; in Cat, Prowl out of combat, then Ravage (Shred before you know it).",
  body = "#showtooltip\n/cast [form:1] Enrage; [form:2/3,nostealth,nocombat] Prowl; [form:2/3,@target,harm,nodead] Ravage\n/cast [form:2/3,stealth,@target,harm,nodead] Shred" })

L.Add({ name = "FormStun", category = "combat", class = "DRUID", order = 35, perCharacter = true,
  icon = "Bash", requires = { "Bear Form" }, tags = { "crowd control", "controller" }, untested = true,
  desc = "Control for your form: Bash in Bear, Pounce in Cat (from Prowl).",
  body = "#showtooltip\n/cast [form:1] Bash; [form:2/3] Pounce" })

L.Add({ name = "FormArea", category = "combat", class = "DRUID", order = 36, perCharacter = true,
  icon = "Demoralizing Roar", requires = { "Bear Form" }, tags = { "rotation", "controller" }, untested = true,
  desc = "Area spell for your form: Demoralizing Roar in Bear, Hurricane when not in Cat.",
  body = "#showtooltip\n/cast [form:1] Demoralizing Roar; [noform:2/3] Hurricane" })

L.Add({ name = "FormProc", category = "combat", class = "DRUID", order = 37, perCharacter = true,
  icon = "Cower", requires = { "Bear Form" }, tags = { "defensive", "controller" }, untested = true,
  desc = "Reactive spell for your form: Frenzied Regeneration in Bear, Cower in Cat, else Nature's Grasp.",
  body = "#showtooltip\n/cast [form:1] Frenzied Regeneration; [form:2/3] Cower; Nature's Grasp" })

L.Add({ name = "FormMove", category = "combat", class = "DRUID", order = 38, perCharacter = true,
  icon = "Dash", requires = { "Bear Form" }, tags = { "travel", "controller" }, untested = true,
  desc = "Gap closer or escape for your form: Feral Charge in Bear, Dash in Cat.",
  body = "#showtooltip\n/cast [form:1,@target,harm,nodead] Feral Charge; [form:2/3] Dash" })
