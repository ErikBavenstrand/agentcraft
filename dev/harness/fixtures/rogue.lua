-- A level 60 Human Combat rogue (swords, Riposte / Blade Flurry /
-- Adrenaline Rush). Format: dev/layout-format.md ("Fixture format"). Spell
-- IDs are Classic ranks; exact IDs don't matter to the addon, only that
-- names and IDs are consistent. Shank, Mutilate and Death Mark are Forever spells with
-- made-up IDs here. Fields left out (items, bags, equipped, flyouts,
-- professions) get defaults in harness.lua: a Hearthstone in the backpack.
return {
  class = { "Rogue", "ROGUE", 4 },
  race = { "Human", "Human" },
  level = 60,

  -- Points per talent tab, in tab order. Tests override with boot{ talents = }.
  talents = {
    { name = "Assassination", points = 15 },
    { name = "Combat", points = 31 },
    { name = "Subtlety", points = 5 },
  },

  -- Known spells (player spellbook). passive = true are skipped by the addon.
  spells = {
    { name = "Sinister Strike", id = 11294 },
    { name = "Eviscerate", id = 11300 },
    { name = "Stealth", id = 1787 },
    { name = "Backstab", id = 25300 },
    { name = "Pick Pocket", id = 921 },
    { name = "Gouge", id = 11286 },
    { name = "Evasion", id = 5277 },
    { name = "Sap", id = 11297 },
    { name = "Slice and Dice", id = 6774 },
    { name = "Sprint", id = 11305 },
    { name = "Kick", id = 1769 },
    { name = "Expose Armor", id = 11198 },
    { name = "Garrote", id = 11290 },
    { name = "Feint", id = 25302 },
    { name = "Pick Lock", id = 1804 },
    { name = "Ambush", id = 11269 },
    { name = "Rupture", id = 11275 },
    { name = "Distract", id = 1725 },
    { name = "Vanish", id = 1857 },
    { name = "Shank", id = 1300001 },
    { name = "Cheap Shot", id = 1833 },
    { name = "Disarm Trap", id = 1842 },
    { name = "Kidney Shot", id = 8643 },
    { name = "Blind", id = 2094 },
    { name = "Riposte", id = 14251 },
    { name = "Blade Flurry", id = 13877 },
    { name = "Adrenaline Rush", id = 13750 },
    { name = "Throw", id = 2764 },
    { name = "Shoot Bow", id = 2480 },
    { name = "Perception", id = 20600 },
    { name = "Fishing", id = 18248 },
    { name = "Cooking", id = 18260 },
    { name = "First Aid", id = 18629 },
    { name = "Basic Campfire", id = 818 },
  },

  -- Talents of the other builds: C_Spell.GetSpellInfo finds them, IsPlayerSpell doesn't.
  catalog = {
    { name = "Cold Blood", id = 14177 },
    { name = "Ghostly Strike", id = 14278 },
    { name = "Hemorrhage", id = 16511 },
    { name = "Preparation", id = 14185 },
    { name = "Premeditation", id = 14183 },
    { name = "Mutilate", id = 1300002 },
    { name = "Death Mark", id = 1300003 },
  },

  -- Profession spells the shared Utility page names (rules only).
  otherSpells = {
    "Shoot Crossbow", "Shoot Gun", "Find Minerals", "Find Herbs", "Smelting", "Engineering", "Alchemy", "Blacksmithing",
    "Leatherworking", "Tailoring", "Enchanting", "Disenchant", "Skinning",
  },
}
