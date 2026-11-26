-- A level 60 Orc Enhancement shaman (WoW Forever spell list, research
-- 2026-11: Wowhead WoW Forever shaman guides, Warcraft Tavern, Method).
-- Format: dev/layout-format.md ("Fixture format"). Spell IDs are Classic
-- ranks where Classic has the spell;
-- Forever-only spells (Fire Nova as a spell, the Call spells, Totemic Call,
-- Rage of the Farseer, Lightning Mastery) use made-up 12400xx IDs. Exact IDs
-- don't matter to the addon, only that names and IDs are consistent.
-- Fields left out (items, bags, equipped, flyouts, professions) get
-- defaults in harness.lua: a Hearthstone in the backpack, nothing else.
return {
  class = { "Shaman", "SHAMAN", 7 },
  race = { "Orc", "Orc" },
  level = 60,

  -- Points per talent tab, in tab order. Tests override with boot{ talents = }.
  talents = {
    { name = "Elemental", points = 0 },
    { name = "Enhancement", points = 31 },
    { name = "Restoration", points = 20 },
  },

  -- Known spells (player spellbook). passive = true are skipped by the addon.
  spells = {
    -- Damage and shocks
    { name = "Lightning Bolt", id = 15208 },
    { name = "Chain Lightning", id = 10605 },
    { name = "Earth Shock", id = 10414 },
    { name = "Flame Shock", id = 29228 },
    { name = "Frost Shock", id = 10473 },
    { name = "Fire Nova", id = 1240001 },
    { name = "Purge", id = 8012 },
    -- Shields and weapon imbues
    { name = "Lightning Shield", id = 10432 },
    { name = "Rockbiter Weapon", id = 16316 },
    { name = "Flametongue Weapon", id = 16342 },
    { name = "Frostbrand Weapon", id = 16356 },
    { name = "Windfury Weapon", id = 16362 },
    -- Heals and cleansing
    { name = "Healing Wave", id = 25357 },
    { name = "Lesser Healing Wave", id = 10468 },
    { name = "Chain Heal", id = 10623 },
    { name = "Cure Poison", id = 526 },
    { name = "Cure Disease", id = 2870 },
    { name = "Ancestral Spirit", id = 20777 },
    -- Totems: earth
    { name = "Stoneskin Totem", id = 10408 },
    { name = "Earthbind Totem", id = 2484 },
    { name = "Stoneclaw Totem", id = 10428 },
    { name = "Strength of Earth Totem", id = 25361 },
    { name = "Tremor Totem", id = 8143 },
    -- Totems: fire
    { name = "Searing Totem", id = 10438 },
    { name = "Magma Totem", id = 10587 },
    { name = "Flametongue Totem", id = 16387 },
    { name = "Frost Resistance Totem", id = 10479 },
    -- Totems: water
    { name = "Healing Stream Totem", id = 10463 },
    { name = "Mana Spring Totem", id = 10497 },
    { name = "Poison Cleansing Totem", id = 8166 },
    { name = "Disease Cleansing Totem", id = 8170 },
    { name = "Fire Resistance Totem", id = 10538 },
    -- Totems: air
    { name = "Windfury Totem", id = 10614 },
    { name = "Grace of Air Totem", id = 25359 },
    { name = "Grounding Totem", id = 8177 },
    { name = "Nature Resistance Totem", id = 10601 },
    { name = "Windwall Totem", id = 15112 },
    { name = "Sentry Totem", id = 6495 },
    { name = "Tranquil Air Totem", id = 25908 },
    -- Totem bar (Forever)
    { name = "Call of the Elements", id = 1240002 },
    { name = "Call of the Ancestors", id = 1240003 },
    { name = "Call of the Spirits", id = 1240004 },
    { name = "Totemic Recall", id = 1240005 },
    { name = "Totemic Call", id = 1240006 },
    -- Utility
    { name = "Ghost Wolf", id = 2645 },
    { name = "Astral Recall", id = 556 },
    { name = "Far Sight", id = 6196 },
    { name = "Water Walking", id = 546 },
    { name = "Water Breathing", id = 131 },
    -- Enhancement talents this character has
    { name = "Stormstrike", id = 17364 },
    { name = "Rage of the Farseer", id = 1240007 },
    { name = "Maelstrom Weapon", id = 1240008, passive = true },
    { name = "Spirit Weapons", id = 16268, passive = true },
    { name = "Reincarnation", id = 20608, passive = true },
    -- Racial and professions-adjacent
    { name = "Blood Fury", id = 20572 },
    { name = "Fishing", id = 18248 },
    { name = "Cooking", id = 18260 },
    { name = "First Aid", id = 18629 },
    { name = "Basic Campfire", id = 818 },
  },

  -- Spells the game knows but this character hasn't learned (talents of the
  -- other trees): C_Spell.GetSpellInfo finds them, IsPlayerSpell doesn't.
  -- Rows (dev/forever-talents.md): Lightning Mastery Ele row 6 = 40; Water
  -- Shield Resto row 2 = 20, Mana Tide Totem row 3 = 25, Nature's Swiftness
  -- row 4 = 30, Riptide row 6 = 40.
  catalog = {
    { name = "Lightning Mastery", id = 1240009 },
    { name = "Riptide", id = 1240010 },
    { name = "Water Shield", id = 1240011 },
    { name = "Mana Tide Totem", id = 17359 },
    { name = "Nature's Swiftness", id = 16188 },
  },

  -- Other real spell names the layouts may name that the fixture doesn't
  -- model (rules only: no ID needed).
  otherSpells = {
    "Smelting", "Find Minerals", "Find Herbs", "Skinning", "Alchemy", "Blacksmithing",
    "Leatherworking", "Tailoring", "Enchanting", "Disenchant", "Engineering",
  },
}
