-- A level 60 Undead warlock with the WoW Forever spellbook (Banes, Sayaad).
-- Format: dev/layout-format.md ("Fixture format"). Spell IDs are Classic
-- ranks where one exists; Forever-only spells (Bane of Havoc, Wrack, Summon
-- Sayaad, Bane names) use stand-in IDs. Exact IDs don't matter to the addon,
-- only that names and IDs are consistent.
return {
  class = { "Warlock", "WARLOCK", 9 },
  race = { "Undead", "Scourge" },
  level = 60,

  -- Points per talent tab, in tab order. Tests override with boot{ talents = }.
  talents = {
    { name = "Affliction", points = 0 },
    { name = "Demonology", points = 0 },
    { name = "Destruction", points = 0 },
  },

  -- Known spells (player spellbook), with the level each is learned (Forever).
  spells = {
    { name = "Shadow Bolt", id = 25307 },        -- 1
    { name = "Immolate", id = 25309 },           -- 1
    { name = "Summon Imp", id = 688 },           -- 1
    { name = "Corruption", id = 25311 },         -- 4
    { name = "Curse of Weakness", id = 11708 },
    { name = "Life Tap", id = 11689 },           -- 6
    { name = "Bane of Agony", id = 11713 },      -- 8
    { name = "Fear", id = 6215 },                -- 8
    { name = "Drain Soul", id = 11675 },         -- 10
    { name = "Create Healthstone", id = 11730 }, -- 10
    { name = "Summon Voidwalker", id = 697 },    -- 10 (quest)
    { name = "Health Funnel", id = 11695 },      -- 12
    { name = "Drain Life", id = 11700 },         -- 14
    { name = "Curse of Tongues", id = 11719 },
    { name = "Create Soulstone", id = 20757 },   -- 18
    { name = "Searing Pain", id = 17923 },       -- 18
    { name = "Rain of Fire", id = 11678 },       -- 20
    { name = "Summon Sayaad", id = 712 },        -- 20 (quest)
    { name = "Demon Armor", id = 11735 },
    { name = "Unending Breath", id = 5697 },
    { name = "Eye of Kilrogg", id = 126 },
    { name = "Enslave Demon", id = 11726 },
    { name = "Drain Mana", id = 11704 },         -- 24
    { name = "Shadow Ward", id = 28610 },
    { name = "Hellfire", id = 11684 },           -- 30
    { name = "Summon Felhunter", id = 691 },     -- 30 (quest)
    { name = "Howl of Terror", id = 17928 },     -- 40
    { name = "Curse of the Elements", id = 11722 }, -- 40
    { name = "Death Coil", id = 17926 },         -- 42
    { name = "Soul Fire", id = 17924 },          -- 48
    { name = "Inferno", id = 1122 },             -- 50
    { name = "Bane of Doom", id = 603 },         -- 60
    { name = "Will of the Forsaken", id = 7744 },
    { name = "Cannibalize", id = 20577 },
  },

  -- Talent spells: the game knows them, the character hasn't learned them.
  catalog = {
    { name = "Siphon Life", id = 18881 },        -- Affliction
    { name = "Amplify Curse", id = 18288 },      -- Affliction
    { name = "Wrack", id = 1230001 },            -- Affliction 31 (Forever)
    { name = "Fel Domination", id = 18708 },     -- Demonology
    { name = "Demonic Sacrifice", id = 18788 },  -- Demonology
    { name = "Soul Link", id = 19028 },          -- Demonology
    { name = "Shadowburn", id = 18871 },         -- Destruction
    { name = "Conflagrate", id = 18932 },        -- Destruction
    { name = "Bane of Havoc", id = 1230002 },    -- Destruction 34 (Forever)
    { name = "Incinerate", id = 1230003 },       -- Destruction 31 (Forever)
  },

  -- Other real spell names the layouts name (rules only, no ID).
  otherSpells = {
    "Demon Skin", "Summon Succubus",
    "Fishing", "Basic Campfire", "Cooking", "First Aid", "Engineering",
    "Smelting", "Find Minerals", "Find Herbs", "Skinning", "Alchemy", "Blacksmithing",
    "Leatherworking", "Tailoring", "Enchanting", "Disenchant",
  },

  -- Used when boot({ pet = true }): a Voidwalker.
  petData = {
    name = "Voidwalker",
    actions = {
      { name = "PET_ACTION_ATTACK", token = true },
      { name = "PET_ACTION_FOLLOW", token = true },
      { name = "PET_ACTION_WAIT", token = true },
      { name = "Torment", texture = 136160, autocast = true },
      { name = "Sacrifice", texture = 136190 },
      { name = "Suffering", texture = 136140, autocast = true },
      { name = "Consume Shadows", texture = 136121, autocast = true },
    },
    spells = {
      { name = "Torment", id = 11775, icon = 136160, autocast = true },
      { name = "Sacrifice", id = 11779, icon = 136190 },
      { name = "Suffering", id = 17752, icon = 136140, autocast = true },
      { name = "Consume Shadows", id = 17854, icon = 136121, autocast = true },
    },
  },
}
