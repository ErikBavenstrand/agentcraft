-- A level 60 Human paladin with every WoW Forever trainer spell the
-- layouts name. Format: dev/layout-format.md ("Fixture format"). Spell IDs
-- are Classic ranks where one exists; Forever-only spells (Seal of Fury,
-- Holy Strike's baseline rank) use made-up IDs. Exact IDs don't matter to
-- the addon, only that names and IDs are consistent.
-- Fields left out (items, bags, equipped, flyouts, professions) get
-- defaults in harness.lua: a Hearthstone in the backpack, nothing else.
return {
  class = { "Paladin", "PALADIN", 2 },
  race = { "Human", "Human" },
  level = 60,

  -- Points per talent tab, in tab order (the leveling spec's tab is the
  -- default when every tab is 0). Tests override with boot{ talents = }.
  talents = {
    { name = "Holy", points = 0 },
    { name = "Protection", points = 0 },
    { name = "Retribution", points = 0 },
  },

  -- Known spells (player spellbook), in trainer level order.
  spells = {
    { name = "Seal of Righteousness", id = 20293 },   -- 1
    { name = "Holy Light", id = 25292 },              -- 1
    { name = "Devotion Aura", id = 10293 },           -- 1
    { name = "Judgement", id = 20271 },               -- 4
    { name = "Blessing of Might", id = 25291 },       -- 4
    { name = "Divine Protection", id = 5573 },        -- 6
    { name = "Seal of the Crusader", id = 20308 },    -- 6
    { name = "Holy Strike", id = 679 },               -- 6 (baseline on Forever)
    { name = "Hammer of Justice", id = 10308 },       -- 8
    { name = "Purify", id = 1152 },                   -- 8
    { name = "Lay on Hands", id = 10310 },            -- 10 (20 min cooldown on Forever)
    { name = "Seal of Fury", id = 990010 },           -- 10 (Forever only)
    { name = "Righteous Fury", id = 25780 },          -- 10
    { name = "Blessing of Protection", id = 10278 },  -- 10
    { name = "Redemption", id = 20773 },              -- 12
    { name = "Blessing of Wisdom", id = 25290 },      -- 14
    { name = "Retribution Aura", id = 10301 },        -- 16
    { name = "Blessing of Freedom", id = 1044 },      -- 18
    { name = "Consecration", id = 20924 },            -- 20 (baseline on Forever)
    { name = "Exorcism", id = 10314 },                -- 20
    { name = "Flash of Light", id = 19943 },          -- 20
    { name = "Blessing of Kings", id = 20217 },       -- 20
    { name = "Seal of Command", id = 20920 },         -- 20 (baseline on Forever)
    { name = "Concentration Aura", id = 19746 },      -- 22
    { name = "Seal of Justice", id = 20164 },         -- 22
    { name = "Turn Undead", id = 10326 },             -- 24
    { name = "Shadow Resistance Aura", id = 19896 },  -- 28
    { name = "Seal of Light", id = 20349 },           -- 30
    { name = "Divine Intervention", id = 19752 },     -- 30
    { name = "Frost Resistance Aura", id = 19898 },   -- 32
    { name = "Divine Shield", id = 1020 },            -- 34
    { name = "Fire Resistance Aura", id = 19900 },    -- 36
    { name = "Seal of Wisdom", id = 20357 },          -- 38
    { name = "Summon Warhorse", id = 13819 },         -- 40
    { name = "Cleanse", id = 4987 },                  -- 42
    { name = "Hammer of Wrath", id = 24239 },         -- 44
    { name = "Blessing of Sacrifice", id = 20729 },   -- 46
    { name = "Holy Wrath", id = 10318 },              -- 50
    { name = "Summon Charger", id = 23214 },          -- 60
    { name = "Perception", id = 20600 },              -- Human racial
  },

  -- Talent spells: C_Spell.GetSpellInfo finds them, IsPlayerSpell doesn't.
  catalog = {
    { name = "Holy Shock", id = 20930 },   -- Holy, 21 points (10 s cooldown on Forever)
    { name = "Holy Shield", id = 20928 },  -- Protection
    { name = "Repentance", id = 20066 },   -- Retribution
  },

  -- Profession spells the shared controller Utility page names (rules only).
  otherSpells = {
    "Fishing", "Cooking", "First Aid", "Basic Campfire", "Find Minerals", "Find Herbs",
    "Smelting", "Engineering", "Alchemy", "Blacksmithing", "Leatherworking", "Tailoring",
    "Enchanting", "Disenchant", "Skinning",
  },
}
