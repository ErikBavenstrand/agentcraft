-- A level 60 Tauren druid with every trainer spell. Format:
-- dev/layout-format.md ("Fixture format"). Spell IDs are Classic ranks
-- where one exists; the Forever-only spells (Revive, Primal Bite, Shifting
-- Power) have fixture IDs. Exact IDs don't matter to the addon, only
-- that names and IDs are consistent. Talent spells are in the catalog.
-- Fields left out (items, bags, equipped, flyouts, professions) get
-- defaults in harness.lua: a Hearthstone in the backpack, nothing else.
return {
  class = { "Druid", "DRUID", 11 },
  race = { "Tauren", "Tauren" },
  level = 60,

  -- Points per talent tab, in tab order (the leveling spec's tab is the
  -- default when every tab is 0). Tests override with boot{ talents = }.
  talents = {
    { name = "Balance", points = 0 },
    { name = "Feral Combat", points = 0 },
    { name = "Restoration", points = 0 },
  },

  -- Known spells (player spellbook). passive = true are skipped by the addon.
  spells = {
    { name = "Wrath", id = 5176 },
    { name = "Healing Touch", id = 5185 },
    { name = "Mark of the Wild", id = 1126 },
    { name = "Moonfire", id = 8921 },
    { name = "Rejuvenation", id = 774 },
    { name = "Thorns", id = 467 },
    { name = "Entangling Roots", id = 339 },
    { name = "Bear Form", id = 5487 },
    { name = "Demoralizing Roar", id = 99 },
    { name = "Maul", id = 6807 },
    { name = "Growl", id = 6795 },
    { name = "Enrage", id = 5229 },
    { name = "Regrowth", id = 8936 },
    { name = "Revive", id = 900120 },
    { name = "Bash", id = 5211 },
    { name = "Swipe", id = 779 },
    { name = "Aquatic Form", id = 1066 },
    { name = "Faerie Fire", id = 770 },
    { name = "Hibernate", id = 2637 },
    { name = "Cat Form", id = 768 },
    { name = "Claw", id = 1082 },
    { name = "Rake", id = 1822 },
    { name = "Prowl", id = 5215 },
    { name = "Shred", id = 5221 },
    { name = "Rip", id = 1079 },
    { name = "Rebirth", id = 20484 },
    { name = "Starfire", id = 2912 },
    { name = "Soothe Animal", id = 2908 },
    { name = "Remove Curse", id = 2782 },
    { name = "Dash", id = 1850 },
    { name = "Abolish Poison", id = 2893 },
    { name = "Cower", id = 8998 },
    { name = "Challenging Roar", id = 5209 },
    { name = "Travel Form", id = 783 },
    { name = "Tranquility", id = 740 },
    { name = "Ravage", id = 6785 },
    { name = "Ferocious Bite", id = 22568 },
    { name = "Track Humanoids", id = 5225 },
    { name = "Pounce", id = 9005 },
    { name = "Frenzied Regeneration", id = 22842 },
    { name = "Dire Bear Form", id = 9634 },
    { name = "Innervate", id = 29166 },
    { name = "Hurricane", id = 16914 },
    { name = "Barkskin", id = 22812 },
    { name = "Nature's Grasp", id = 16689 },
    { name = "Teleport: Moonglade", id = 18960 },
    { name = "War Stomp", id = 20549 },
  },

  -- Spells the game knows but this character hasn't learned (talents):
  -- C_Spell.GetSpellInfo finds them, IsPlayerSpell doesn't.
  -- Rows from dev/forever-talents.md (row r = level 10 + 5r). Nature's
  -- Grasp is not a Forever talent (a trainer spell, in spells above);
  -- Faerie Fire (Feral) is neither a talent nor a known trainer spell.
  catalog = {
    { name = "Insect Swarm", id = 5570 },        -- Balance row 3 (25)
    { name = "Moonkin Form", id = 24858 },       -- Balance row 6 (40)
    { name = "Feral Charge", id = 16979 },       -- Feral row 2 (20)
    { name = "Primal Bite", id = 900121 },       -- Feral row 6 (40)
    { name = "Lacerate", id = 33745 },           -- Feral row 3 (25)
    { name = "Shifting Power", id = 900122 },    -- Feral row 6 (40)
    { name = "Swiftmend", id = 18562 },          -- Restoration row 3 (25)
    { name = "Nature's Swiftness", id = 17116 }, -- Restoration row 4 (30)
    { name = "Wild Growth", id = 48438 },        -- Restoration row 6 (40)
  },

  -- Other real spell names the layouts name that the fixture doesn't
  -- model (rules only: no ID needed).
  otherSpells = {
    "Fishing", "Cooking", "First Aid", "Basic Campfire", "Find Minerals", "Find Herbs",
    "Smelting", "Engineering", "Alchemy", "Blacksmithing", "Leatherworking", "Tailoring",
    "Enchanting", "Disenchant", "Skinning",
  },
}
