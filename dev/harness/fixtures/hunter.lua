-- A level 60 Orc hunter, roughly what the owner plays. Edit freely; tests
-- depend only on what they assert. Spell IDs are Classic ranks; exact IDs
-- don't matter to the addon, only that names and IDs are consistent.
--
-- To build one from a real snapshot: `wowdata.ps1 character -Path spellbook`
-- lists the spellbook, `-Path bags` the bags, `-Path pet` the pet.
return {
  class = { "Hunter", "HUNTER", 3 },
  race = { "Orc", "Orc" },
  level = 60,

  -- Known spells (player spellbook). passive = true are skipped by the addon.
  -- icon = the spell icon file ID (SpellMisc.SpellIconFileDataID, Classic Era, from
  -- wago.tools); dev/render/fileids.lua names them so the render draws real icons.
  spells = {
    { name = "Auto Shot", id = 75, icon = 132369 },
    { name = "Arcane Shot", id = 14287, icon = 132218 },
    { name = "Serpent Sting", id = 13555, icon = 132204 },
    { name = "Aimed Shot", id = 20904, icon = 135130 },
    { name = "Multi-Shot", id = 14290, icon = 132330 },
    { name = "Concussive Shot", id = 5116, icon = 135860 },
    { name = "Hunter's Mark", id = 14325, icon = 132212 },
    { name = "Raptor Strike", id = 14266, icon = 132223 },
    { name = "Mongoose Bite", id = 14271, icon = 132215 },
    { name = "Wing Clip", id = 14268, icon = 132309 },
    { name = "Disengage", id = 14273, icon = 132294 },

    { name = "Feign Death", id = 5384, icon = 132293 },
    { name = "Freezing Trap", id = 14311, icon = 135834 },
    { name = "Frost Trap", id = 13809, icon = 135840 },
    { name = "Explosive Trap", id = 14317, icon = 135826 },
    { name = "Immolation Trap", id = 14305, icon = 135813 },
    { name = "Rapid Fire", id = 3045, icon = 132208 },

    { name = "Aspect of the Hawk", id = 25296, icon = 136076, flyoutOnly = true },
    { name = "Aspect of the Monkey", id = 13163, icon = 132159, flyoutOnly = true },
    { name = "Aspect of the Cheetah", id = 5118, icon = 132242, flyoutOnly = true },
    { name = "Aspect of the Pack", id = 13159, icon = 132267, flyoutOnly = true },
    { name = "Track Beasts", id = 1494, icon = 132328 },
    { name = "Track Humanoids", id = 19883, icon = 135942 },
    { name = "Mend Pet", id = 13544, icon = 132179 },
    { name = "Revive Pet", id = 982, icon = 132163 },
    { name = "Call Pet", id = 883, icon = 132161 },
    { name = "Dismiss Pet", id = 2641, icon = 136095 },
    { name = "Feed Pet", id = 6991, icon = 132165 },
    { name = "Tame Beast", id = 1515, icon = 132164 },
    { name = "Beast Training", id = 5149, icon = 132162 },
    { name = "Beast Lore", id = 1462, icon = 132270 },
    { name = "Eyes of the Beast", id = 1002, icon = 132150 },
    { name = "Scare Beast", id = 14327, icon = 132118 },
    { name = "Volley", id = 14295, icon = 132222 },
    { name = "Flare", id = 1543, icon = 135815 },
    { name = "Viper Sting", id = 14280, icon = 132157 },
    { name = "Tranquilizing Shot", id = 19801, icon = 136020 },
    { name = "Eagle Eye", id = 6197, icon = 132172 },
    { name = "Blood Fury", id = 20572, icon = 135726 },
    { name = "Fishing", id = 18248, icon = 136245 },
    { name = "Cooking", id = 18260, icon = 133971 },
    { name = "First Aid", id = 18629, icon = 136192 },
    { name = "Basic Campfire", id = 818, icon = 135805 },
  },

  -- Professions (GetProfessions / GetProfessionInfo), as the owner's hunter
  -- (Mining, Engineering, First Aid, Fishing, Cooking): their spells sit in the
  -- spellbook outside the class skill line. WoW Forever lists some under an
  -- old and a new spell ID with the same name: Engineering twice here, and
  -- Cooking again (1240956) though the class line already has it (18260).
  professions = {
    { name = "Mining", icon = 136248, spells = {
      { name = "Mining", id = 2575, icon = 136248 },
      { name = "Smelting", id = 2656, icon = 135811 },
      { name = "Find Minerals", id = 2580, icon = 136025 },
    } },
    { name = "Engineering", icon = 136243, spells = {
      { name = "Engineering", id = 4036, icon = 136243 },
      { name = "Engineering", id = 1240958, icon = 136243 },
    } },
    { name = "Cooking", icon = 133971, spells = {
      { name = "Cooking", id = 1240956, icon = 133971 },
    } },
    { name = "Fishing", icon = 136245, spells = {
      { name = "Bait and Tackle", id = 1278067, icon = 136245 },
    } },
  },

  -- Spellbook flyouts. Aspects are a flyout on the modern client.
  flyouts = {
    { id = 253, name = "Aspects", spells = {
      { name = "Aspect of the Hawk", id = 25296, icon = 136076 },
      { name = "Aspect of the Monkey", id = 13163, icon = 132159 },
      { name = "Aspect of the Cheetah", id = 5118, icon = 132242 },
      { name = "Aspect of the Pack", id = 13159, icon = 132267 },
    } },
  },

  -- Other real spell names the layouts name that the fixture doesn't model
  -- (rules only, no ID: R.FixtureSpells; adding them as spells would change
  -- what the tests see).
  otherSpells = {
    "Scorpid Sting", "Distracting Shot",
    "Aspect of the Beast", "Aspect of the Wild",
    "Find Herbs", "Skinning", "Alchemy", "Blacksmithing",
    "Leatherworking", "Tailoring", "Enchanting", "Disenchant",
  },

  -- Spells the game knows but the player hasn't learned (C_Spell.GetSpellInfo
  -- works): every active Forever talent the layouts name, with its row from
  -- dev/forever-talents.md (row r = level 10 + 5r, earlier with Talented).
  -- Lacerating Strikes (Survival row 6) is passive: no button. Wyvern Sting
  -- is not a Forever talent.
  catalog = {
    { name = "Summon Hawk", id = 1300301 },                -- BM row 3 = 25 (made-up ID)
    { name = "Intimidation", id = 19577, icon = 132111 },  -- BM row 4 = 30
    { name = "Bestial Wrath", id = 19574, icon = 132127 }, -- BM row 6 = 40
    { name = "Trueshot Aura", id = 20906, icon = 132329 }, -- MM row 3 = 25
    { name = "Scatter Shot", id = 19503, icon = 132153 },  -- MM row 4 = 30
    { name = "Sniper Shot", id = 1300302 },                -- MM row 6 = 40 (made-up ID)
    { name = "Deterrence", id = 19263 },                   -- Survival row 2 = 20
    { name = "Counterattack", id = 20910, icon = 132336 }, -- Survival row 3 = 25
    { name = "Strider Kick", id = 1300303 },               -- Survival row 4 = 30 (made-up ID)
  },

  -- icon = the item icon file ID (icon names from the wowhead classic tooltips,
  -- file IDs from the wago.tools file search); dev/render/fileids.lua names them.
  items = {
    [6948] = { name = "Hearthstone", spell = "Hearthstone", icon = 134414 },
    [8952] = { name = "Roasted Quail", minLevel = 45, spell = "Food", icon = 133971, tooltip = "Restores 2148 health over 30 sec. Must remain seated while eating." },
    [8766] = { name = "Morning Glory Dew", minLevel = 45, spell = "Drink", icon = 134712, tooltip = "Restores 2934 mana over 30 sec. Must remain seated while drinking." },
    [13446] = { name = "Major Healing Potion", minLevel = 45, spell = "Healing Potion", icon = 134834 },
    [14530] = { name = "Heavy Runecloth Bandage", minLevel = 0, spell = "First Aid", icon = 133682 },
    [6256] = { name = "Fishing Pole", classID = 2, subClassID = 20, equipLoc = "INVTYPE_2HWEAPON", icon = 132932 },
    [18738] = { name = "Carapace Spine Crossbow", classID = 2, subClassID = 18, equipLoc = "INVTYPE_RANGED", icon = 135533 },
    [12784] = { name = "Arcanite Reaper", classID = 2, subClassID = 1, equipLoc = "INVTYPE_2HWEAPON", icon = 132400 },
    -- Trinkets: one with a Use effect (placed on Alt+C), one without (never placed).
    [11122] = { name = "Carrot on a Stick", spell = "Increased Mount Speed", equipLoc = "INVTYPE_TRINKET", icon = 134010 },
    [13209] = { name = "Seal of the Dawn", equipLoc = "INVTYPE_TRINKET", icon = 133440 },
    -- WoW Forever camp item. 248000 is a fixture ID, not the real one; tests
    -- put it in the bags (setup) when they need it there.
    [248000] = { name = "Cozy Sleeping Bag", spell = "Cozy Sleeping Bag" },
  },

  -- bags[bag][slot] = itemID; size defaults to 16 for a listed bag.
  bags = {
    [0] = { 6948, 8952, 8766, 13446, 14530, 6256 },
  },

  -- equipped[inventorySlot] = itemID (13/14 trinkets, 16 main hand, 17 off hand, 18 ranged)
  equipped = { [13] = 11122, [14] = 13209, [16] = 12784, [18] = 18738 },

  -- Used when boot({ pet = true }).
  petData = {
    name = "Wolf",
    actions = {
      { name = "PET_ACTION_ATTACK", token = true },
      { name = "PET_ACTION_FOLLOW", token = true },
      { name = "PET_ACTION_WAIT", token = true },
      { name = "Bite", texture = 132278, autocast = true },
      { name = "Growl", texture = 132270, autocast = true },
    },
    spells = {
      { name = "Bite", id = 17261, icon = 132278, autocast = true },
      { name = "Growl", id = 14921, icon = 132270, autocast = true },
      { name = "Furious Howl", id = 24597, icon = 132203, autocast = true },
    },
  },
}
