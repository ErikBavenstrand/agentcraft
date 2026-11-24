-- A level 60 Undead warrior (the owner's warrior is an Undead). Format:
-- dev/layout-format.md ("Fixture format"). Spell IDs are Classic ranks;
-- exact IDs don't matter to the addon, only that names and IDs are
-- consistent (dev/tests/19 relies on 78, 772, 6572 and 7384). Talent spells
-- are in catalog. Fields left out (items, bags, equipped, flyouts,
-- professions) get defaults in harness.lua: a Hearthstone in the backpack.
return {
  class = { "Warrior", "WARRIOR", 1 },
  race = { "Undead", "Scourge" },
  level = 60,

  -- Points per talent tab, in tab order (the leveling spec's tab is the
  -- default when every tab is 0). Tests override with boot{ talents = }.
  talents = {
    { name = "Arms", points = 0 },
    { name = "Fury", points = 0 },
    { name = "Protection", points = 0 },
  },

  -- Known spells (player spellbook). passive = true are skipped by the addon.
  spells = {
    { name = "Battle Stance", id = 2457 },
    { name = "Heroic Strike", id = 78 },
    { name = "Charge", id = 100 },
    { name = "Rend", id = 772 },
    { name = "Thunder Clap", id = 6343 },
    { name = "Hamstring", id = 1715 },
    { name = "Bloodrage", id = 2687 },
    { name = "Battle Shout", id = 6673 },
    { name = "Defensive Stance", id = 71 },
    { name = "Sunder Armor", id = 7386 },
    { name = "Taunt", id = 355 },
    { name = "Revenge", id = 6572 },
    { name = "Shield Bash", id = 72 },
    { name = "Overpower", id = 7384 },
    { name = "Execute", id = 5308 },
    { name = "Berserker Stance", id = 2458 },
    { name = "Whirlwind", id = 1680 },
    { name = "Pummel", id = 6552 },
    { name = "Demoralizing Shout", id = 1160 },
    { name = "Mocking Blow", id = 694 },
    { name = "Shield Block", id = 2565 },
    { name = "Disarm", id = 676 },
    { name = "Cleave", id = 845 },
    { name = "Retaliation", id = 20230 },
    { name = "Victory Rush", id = 34428 },
    { name = "Intimidating Shout", id = 5246 },
    { name = "Challenging Shout", id = 1161 },
    { name = "Shield Wall", id = 871 },
    { name = "Intercept", id = 20252 },
    { name = "Slam", id = 1464 },
    { name = "Berserker Rage", id = 18499 },
    { name = "Recklessness", id = 1719 },
    { name = "Will of the Forsaken", id = 7744 },
  },

  -- Spells the game knows but this character hasn't learned (talents):
  -- C_Spell.GetSpellInfo finds them, IsPlayerSpell doesn't.
  catalog = {
    { name = "Mortal Strike", id = 12294 },
    { name = "Sweeping Strikes", id = 12292 },
    { name = "Bloodthirst", id = 23881 },
    { name = "Death Wish", id = 12328 },
    { name = "Piercing Howl", id = 12323 },
    { name = "Shield Slam", id = 23922 },
    { name = "Last Stand", id = 12975 },
    { name = "Concussion Blow", id = 12809 },
    -- Forever talents named by the guides (Icy Veins, Mobalytics): made-up
    -- IDs; unverified whether each is a button or a passive.
    { name = "Spearing Strike", id = 1300001 },
    { name = "Reckless Swings", id = 1300002 },
    { name = "Gore Drinker", id = 1300003 },
  },

  -- Other real spell names the layouts name that the fixture doesn't model
  -- (rules only: no ID needed).
  otherSpells = {
    "Fishing", "Basic Campfire", "Cooking", "First Aid", "Engineering",
    "Smelting", "Find Minerals", "Find Herbs", "Skinning", "Alchemy", "Blacksmithing",
    "Leatherworking", "Tailoring", "Enchanting", "Disenchant",
  },
}
