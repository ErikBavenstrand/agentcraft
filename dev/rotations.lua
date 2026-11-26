-- The abilities each spec presses in its Wowhead WoW Forever rotation
-- (single target, AoE, tank threat, healing), read from
-- https://www.wowhead.com/forever/guide/classes/<class>/<spec>/rotation-cooldowns-pve-<role>
-- on 2026-11-26, plus the role kit the owner asked for (2026-11-26: tanks
-- must tank, healers must heal, from keyboard AND controller): interrupt,
-- taunt, dispel. Passives, procs, buffs, totem-bar totems, pet spells,
-- consumables and long cooldowns are left out.
-- dev/tests/33_rotations.lua checks every name here is on a keyboard
-- rotation key (Bar 1 or the spec's stance page) and on controller page 1.
return {
  WARRIOR = {
    arms = { "Mortal Strike", "Rend", "Slam", "Overpower", "Heroic Strike", "Spearing Strike",
      "Execute", "Cleave", "Whirlwind", "Sweeping Strikes", "Pummel", "Charge" },
    -- Arms: Sunder Armor, Thunder Clap and Demoralizing Shout are Wowhead's
    -- "only if you're the only warrior" debuffs (Sunder and Thunder Clap fill
    -- R and Q until Slam 20 and Mortal Strike 40; the shout sits on Shift+G).
    fury = { "Bloodthirst", "Whirlwind", "Heroic Strike", "Overpower", "Execute", "Sunder Armor", "Cleave",
      "Pummel", "Charge" },
    prot = { "Shield Block", "Revenge", "Shield Slam", "Sunder Armor", "Thunder Clap", "Demoralizing Shout",
      "Heroic Strike", "Cleave", "Taunt", "Shield Bash", "Charge" },
    -- Prot: Rend is Wowhead's "if you're already high on threat" filler; it
    -- holds R until Shield Slam (40), then goes to the side bars.
  },
  PALADIN = {
    holy = { "Judgement", "Light's Vigil", "Holy Shock", "Holy Light", "Flash of Light", "Seal of Light",
      "Cleanse" },
    prot = { "Seal of Fury", "Judgement", "Consecration", "Holy Shield", "Holy Strike", "Exorcism",
      "Hammer of Wrath", "Holy Wrath" },
    ret = { "Seal of the Crusader", "Seal of Command", "Seal of Righteousness", "Judgement", "Holy Strike",
      "Hammer of Wrath", "Exorcism", "Consecration" },
  },
  HUNTER = {
    bm = { "Serpent Sting", "Summon Hawk", "Arcane Shot", "Aimed Shot", "Multi-Shot", "Volley", "Explosive Trap" },
    mm = { "Serpent Sting", "Arcane Shot", "Aimed Shot", "Sniper Shot", "Multi-Shot", "Volley", "Explosive Trap" },
    sv = { "Serpent Sting", "Arcane Shot", "Raptor Strike", "Mongoose Bite", "Strider Kick", "Immolation Trap",
      "Multi-Shot", "Volley", "Explosive Trap" },   -- Wowhead's Summon Hawk here is a BM-tree hybrid pick
  },
  ROGUE = {
    assassination = { "Mutilate", "Slice and Dice", "Shank", "Eviscerate", "Garrote", "Kick" },
    combat = { "Sinister Strike", "Slice and Dice", "Shank", "Eviscerate", "Blade Flurry", "Kick" },
    subtlety = { "Hemorrhage", "Slice and Dice", "Shank", "Rupture", "Ghostly Strike", "Garrote",
      "Premeditation", "Death Mark", "Kick" },
  },
  PRIEST = {
    discipline = { "Power Word: Shield", "Penance", "Renew", "Heal", "Greater Heal", "Prayer of Healing",
      "Flash Heal", "Dispel Magic" },
    holy = { "Renew", "Prayer of Mending", "Flash Heal", "Heal", "Greater Heal", "Prayer of Healing",
      "Holy Nova", "Power Word: Shield", "Dispel Magic" },
    shadow = { "Shadow Word: Pain", "Devouring Plague", "Mind Blast", "Shadow Word: Death", "Vampiric Embrace",
      "Mind Flay", "Silence" },
  },
  SHAMAN = {
    elemental = { "Lightning Bolt", "Flame Shock", "Chain Lightning", "Searing Totem", "Fire Nova", "Earth Shock" },
    enhancement = { "Stormstrike", "Lightning Bolt", "Flame Shock", "Earth Shock", "Fire Nova" },
    restoration = { "Riptide", "Healing Wave", "Lesser Healing Wave", "Chain Heal", "Cure Poison", "Earth Shock" },
  },
  MAGE = {
    -- Arcane: Wowhead's Pyroblast is a Fire-tree hybrid pick (G when learned).
    arcane = { "Arcane Blast", "Arcane Missiles", "Arcane Wrath", "Scorch", "Fire Blast",
      "Arcane Explosion", "Flamestrike", "Counterspell" },
    fire = { "Fireball", "Scorch", "Fire Blast", "Pyroblast", "Arcane Missiles", "Blast Wave",
      "Arcane Explosion", "Flamestrike", "Counterspell" },
    frost = { "Frostbolt", "Ice Lance", "Cone of Cold", "Ice Barrier", "Blizzard", "Counterspell" },
  },
  WARLOCK = {
    affliction = { "Corruption", "Bane of Agony", "Siphon Life", "Wrack", "Life Tap", "Shadow Bolt",
      "Death Coil", "Hellfire", "Rain of Fire" },
    demonology = { "Bane of Agony", "Corruption", "Immolate", "Searing Pain", "Shadow Bolt", "Life Tap",
      "Death Coil", "Hellfire" },
    destruction = { "Immolate", "Conflagrate", "Incinerate", "Shadowburn", "Corruption", "Bane of Havoc",
      "Life Tap", "Death Coil", "Hellfire" },
  },
  DRUID = {
    balance = { "Wrath", "Moonfire", "Starfire", "Insect Swarm", "Hurricane", "Faerie Fire" },
    feral = { "Shred", "Claw", "Rake", "Rip", "Ferocious Bite", "Shifting Power",
      "Maul", "Lacerate", "Primal Bite", "Swipe", "Growl", "Demoralizing Roar", "Bash" },
    restoration = { "Rejuvenation", "Regrowth", "Healing Touch", "Swiftmend", "Wild Growth",
      "Nature's Swiftness", "Remove Curse", "Abolish Poison" },
  },
}
