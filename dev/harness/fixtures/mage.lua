-- A level 60 Human mage (Alliance, so the Alliance teleports and portals).
-- Format: dev/layout-format.md ("Fixture format"). Spell IDs are Classic
-- ranks where one exists; spells new in WoW Forever (Frostfire Bolt,
-- Teleport: Dalaran and the new talents) use made-up 125xxxx IDs. Only names
-- and IDs staying consistent matters. Fields left out (items, bags,
-- equipped) get defaults in harness.lua: a Hearthstone in the backpack.
return {
  class = { "Mage", "MAGE", 8 },
  race = { "Human", "Human" },
  level = 60,

  -- Points per talent tab, in tab order (the leveling spec's tab is the
  -- default when every tab is 0). Tests override with boot{ talents = }.
  talents = {
    { name = "Arcane", points = 0 },
    { name = "Fire", points = 0 },
    { name = "Frost", points = 0 },
  },

  -- Known spells (player spellbook). passive = true are skipped by the addon.
  spells = {
    { name = "Fireball", id = 25306 },
    { name = "Frost Armor", id = 7301 },
    { name = "Arcane Intellect", id = 10157 },
    { name = "Frostbolt", id = 25304 },
    { name = "Conjure Water", id = 10140 },
    { name = "Conjure Food", id = 28612 },
    { name = "Fire Blast", id = 10199 },
    { name = "Arcane Missiles", id = 25345 },
    { name = "Polymorph", id = 12826 },
    { name = "Frost Nova", id = 10230 },
    { name = "Dampen Magic", id = 10174 },
    { name = "Slow Fall", id = 130 },
    { name = "Amplify Magic", id = 10170 },
    { name = "Remove Lesser Curse", id = 475 },
    { name = "Arcane Explosion", id = 10202 },
    { name = "Flamestrike", id = 10216 },
    { name = "Blink", id = 1953 },
    { name = "Evocation", id = 12051 },
    { name = "Mana Shield", id = 10193 },
    { name = "Blizzard", id = 10187 },
    { name = "Fire Ward", id = 10225 },
    { name = "Scorch", id = 10207 },
    { name = "Frost Ward", id = 28609 },
    { name = "Counterspell", id = 2139 },
    { name = "Cone of Cold", id = 10161 },
    { name = "Conjure Mana Agate", id = 759 },
    { name = "Conjure Mana Jade", id = 3552 },
    { name = "Conjure Mana Citrine", id = 10053 },
    { name = "Conjure Mana Ruby", id = 10054 },
    { name = "Ice Armor", id = 10220 },
    { name = "Mage Armor", id = 22783 },
    { name = "Frostfire Bolt", id = 1250001 },
    { name = "Arcane Brilliance", id = 23028 },
    { name = "Teleport: Stormwind", id = 3561 },
    { name = "Teleport: Ironforge", id = 3562 },
    { name = "Teleport: Darnassus", id = 3565 },
    { name = "Teleport: Dalaran", id = 1250002 },
    { name = "Portal: Stormwind", id = 10059 },
    { name = "Portal: Ironforge", id = 11416 },
    { name = "Portal: Darnassus", id = 11419 },
    { name = "Perception", id = 20600 },
    { name = "Fishing", id = 18248 },
    { name = "Cooking", id = 18260 },
    { name = "First Aid", id = 18629 },
    { name = "Basic Campfire", id = 818 },
  },

  -- Talent spells: the game knows them, this character hasn't learned them.
  -- Tests learn them with a setup hook.
  catalog = {
    { name = "Ice Lance", id = 1250003 },
    { name = "Ice Block", id = 11958 },
    { name = "Cold Snap", id = 12472 },
    { name = "Ice Barrier", id = 13033 },
    { name = "Pyroblast", id = 11366 },
    { name = "Combustion", id = 11129 },
    { name = "Blast Wave", id = 11113 },
    { name = "Arcane Blast", id = 1250004 },
    { name = "Presence of Mind", id = 12043 },
    { name = "Arcane Power", id = 12042 },
    { name = "Arcane Wrath", id = 1250005 },
  },

  -- Other real spell names the layouts name that the fixture doesn't model
  -- (rules only: no ID needed). The Horde teleports and portals, and
  -- profession spells.
  otherSpells = {
    "Teleport: Orgrimmar", "Teleport: Undercity", "Teleport: Thunder Bluff",
    "Portal: Orgrimmar", "Portal: Undercity", "Portal: Thunder Bluff",
    "Smelting", "Find Minerals", "Find Herbs", "Skinning", "Alchemy", "Blacksmithing",
    "Leatherworking", "Tailoring", "Enchanting", "Disenchant", "Engineering",
  },
}
