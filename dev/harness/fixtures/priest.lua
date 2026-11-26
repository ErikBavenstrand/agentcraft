-- A level 60 Undead priest. Format: dev/layout-format.md ("Fixture format").
-- Spell IDs are Classic ranks; exact IDs don't matter to the addon, only that
-- names and IDs are consistent. Spell list and levels: warcraft.wiki.gg
-- Priest abilities (Forever), 2026-11. Trainer spells are learned; talents
-- sit in the catalog (tests learn them with a setup hook); other races'
-- priest spells and unmodelled professions are in otherSpells.
-- Fields left out (items, bags, equipped, flyouts) get defaults in
-- harness.lua: a Hearthstone in the backpack, nothing else.
return {
  class = { "Priest", "PRIEST", 5 },
  race = { "Undead", "Scourge" },
  level = 60,

  -- Points per talent tab, in tab order (the leveling spec's tab is the
  -- default when every tab is 0). Tests override with boot{ talents = }.
  talents = {
    { name = "Discipline", points = 0 },
    { name = "Holy", points = 0 },
    { name = "Shadow", points = 0 },
  },

  -- Known spells (player spellbook). passive = true are skipped by the addon.
  spells = {
    { name = "Shoot", id = 5019 },
    { name = "Smite", id = 10934 },
    { name = "Lesser Heal", id = 2053 },
    { name = "Heal", id = 6064 },
    { name = "Greater Heal", id = 25314 },
    { name = "Flash Heal", id = 10917 },
    { name = "Renew", id = 25315 },
    { name = "Prayer of Healing", id = 25316 },
    { name = "Power Word: Fortitude", id = 10938 },
    { name = "Prayer of Fortitude", id = 21564 },
    { name = "Power Word: Shield", id = 10901 },
    { name = "Inner Fire", id = 10952 },
    { name = "Divine Spirit", id = 27841 },
    { name = "Prayer of Spirit", id = 27681 },
    { name = "Shadow Protection", id = 10958 },
    { name = "Prayer of Shadow Protection", id = 27683 },
    { name = "Shadow Word: Pain", id = 10894 },
    { name = "Mind Blast", id = 10947 },
    { name = "Devouring Plague", id = 19280 },
    { name = "Shadow Word: Death", id = 1250001 },
    { name = "Holy Fire", id = 15261 },
    { name = "Psychic Scream", id = 10890 },
    { name = "Fade", id = 10942 },
    { name = "Fear Ward", id = 6346 },
    { name = "Dispel Magic", id = 988 },
    { name = "Cure Disease", id = 528 },
    { name = "Abolish Disease", id = 552 },
    { name = "Resurrection", id = 20770 },
    { name = "Mana Burn", id = 10876 },
    { name = "Mind Control", id = 10912 },
    { name = "Mind Soothe", id = 10953 },
    { name = "Mind Vision", id = 10909 },
    { name = "Shackle Undead", id = 10955 },
    { name = "Levitate", id = 1706 },
    { name = "Binding Heal", id = 1240774 }, -- Wowhead Forever spell=1240774: trainer spell, requires level 56
    -- Undead priest spells (racial quests, levels 10 and 20).
    { name = "Touch of Weakness", id = 19266 },
    { name = "Dark Sacrifice", id = 1250002 },
    { name = "Will of the Forsaken", id = 7744 },
    { name = "Fishing", id = 18248 },
    { name = "Cooking", id = 18260 },
    { name = "First Aid", id = 18629 },
    { name = "Basic Campfire", id = 818 },
  },

  -- Talent spells (active ones; dev/forever-talents.md): C_Spell.GetSpellInfo
  -- finds them, IsPlayerSpell doesn't. Holy Binding is a passive talent: no
  -- button, so not modelled.
  catalog = {
    { name = "Mind Flay", id = 18807 },
    { name = "Vampiric Embrace", id = 15286 },
    { name = "Shadowform", id = 15473 },
    { name = "Silence", id = 15487 },
    { name = "Inner Focus", id = 14751 },
    { name = "Power Infusion", id = 10060 },
    { name = "Penance", id = 1250003 },
    { name = "Holy Nova", id = 27801 },
    { name = "Prayer of Mending", id = 1250005 },
  },

  -- Other real spell names the layouts name that the fixture doesn't model
  -- (rules only: no ID needed): the other races' priest spells and
  -- professions this character lacks.
  otherSpells = {
    "Desperate Prayer", "Hex of Weakness", "Shadowguard", "Starshards", "Elune's Grace",
    "Divine Grace", "Feedback", "Confounding Flash", "Contingency Plan",
    "Smelting", "Find Minerals", "Find Herbs", "Skinning", "Engineering", "Alchemy",
    "Blacksmithing", "Leatherworking", "Tailoring", "Enchanting", "Disenchant",
  },
}
