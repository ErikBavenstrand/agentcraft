# WoW Forever talent rows (conclusive)

Source: Wowhead's WoW Forever talent calculator, read in the browser on 2026-11-26 (https://www.wowhead.com/forever/talent-calc/<class>), plus Wowhead tooltips (nether.wowhead.com/forever/tooltip/spell/<id>).

Rules (Wowhead's Talented perk text, the calculator's "Requires N points in <tree>" messages):
- Talent points start at level 10, one per level, at most 51 (level 60). 7 rows per tree.
- Row r (0-6) needs 5*r points in that tree, so the earliest level is **10 + 5*r**: row 0 = 10, 1 = 15, 2 = 20, 3 = 25, 4 = 30, 5 = 35, 6 = 40 (the 31-point capstone).
- Legacy perk **Talented** rank n (1-5) starts talent points at level 10 - n, so every row comes n levels earlier (capstone at 35 with rank 5). Layouts don't depend on levels: a button fills when the spell is known, so Talented needs no layout change.

Rows per tree (row: talents). Active talents (buttons) in **bold** where known from the guides/tooltips; the rest are passive or ranks.

## Druid (Balance / Feral Combat / Restoration)
- Balance: 0 Starlight Wrath, Genesis; 1 Moonglow, Nature's Majesty, Nature's Reach, Moon and Stars; 2 Improved Entangling Roots, Nature's Splendor; 3 **Insect Swarm**, Vengeance, Improved Starfire; 4 Nature's Grace, Eclipse, Overgrowth; 5 Dreamstate; 6 **Moonkin Form**
- Feral: 0 Ferocity, Furor; 1 Feral Instinct, Brutal Impact, Thick Hide, Feral Swiftness; 2 **Feral Charge**, Shredding Attacks, Sharpened Claws, Savage Fury; 3 Blood Frenzy, **Lacerate**, Predatory Discipline, Predatory Strikes; 4 Natural Instinct, Leader of the Pack; 5 Rend and Tear, Natural Reaction; 6 **Primal Bite**, **Shifting Power**
- Restoration: 0 Nature's Focus, Heart of the Wild; 1 Natural Shapeshifter, Reflection, Naturalist; 2 Gift of Nature, Subtlety, Bloom; 3 **Swiftmend**, Improved Rejuvenation, Tranquil Spirit; 4 Improved Tranquility, Living Spirit, **Nature's Swiftness**; 5 Improved Regrowth; 6 **Wild Growth**

## Hunter (Beast Mastery / Marksmanship / Survival)
- BM: 0 Deadly Aspects, Endurance Training; 1 Improved Revive Pet, Improved Aspect of the Monkey, Focused Fire; 2 Unleashed Fury, Bestial Swiftness, Pathfinding; 3 **Summon Hawk**, Ferocity, Improved Mend Pet; 4 Bestial Discipline, **Intimidation**, Spirit Bond; 5 Frenzy; 6 **Bestial Wrath**
- MM: 0 Lethal Attacks, Improved Concussive Shot, Hawk Eye; 1 Careful Aim, Efficiency, Improved Stings; 2 Rapid Killing, Improved Arcane Shot, Lone Wolf; 3 Mortal Shots, **Trueshot Aura**; 4 Rapid Recuperation, **Scatter Shot**, Barrage; 5 Ranged Weapon Specialization; 6 **Sniper Shot**
- Survival: 0 Deflection, Improved Tracking; 1 Improved Wing Clip, Survivalist, Savage Strikes, Entrapment; 2 **Deterrence**, Surefooted, Clever Traps; 3 Survival Tactics, **Counterattack**, Predator's Edge; 4 **Strider Kick**, Resourcefulness, Expose Prey, Survivalist's Discipline; 5 Lightning Reflexes; 6 Lacerating Strikes
- Not a Forever talent: Wyvern Sting.

## Mage (Arcane / Fire / Frost)
- Arcane: 0 Arcane Resilience, Improved Channeling, Wand Specialization; 1 Missile Barrage, Arcane Concentration, Magic Absorption, Arcane Subtlety; 2 **Arcane Blast**, Arcane Impact, Arcane Geometry; 3 Arcane Meditation, Improved Counterspell, Arcane Shielding, **Arcane Wrath**; 4 Arcane Mind, **Presence of Mind**; 5 Arcane Instability; 6 **Arcane Power**
- Fire: 0 Accelerant, Incineration; 1 Impact, Flame Throwing, Ignite; 2 Burning Soul, **Pyroblast**, Improved Flamestrike, Improved Fire Blast; 3 Master of Elements, Heating Up, Improved Fire Ward, Improved Scorch; 4 **Blast Wave**, Critical Mass; 5 Fire Power; 6 **Combustion**
- Frost: 0 Precision, Improved Frostbolt, Frost Warding; 1 Frostbite, Improved Frost Nova, Permafrost, Ice Shards; 2 **Ice Lance**, Improved Blizzard, Frost Channeling; 3 Shatter, **Ice Block**, Arctic Reach; 4 Fingers of Frost, Improved Cone of Cold, **Cold Snap**; 5 Winter's Chill; 6 **Ice Barrier**

## Paladin (Holy / Protection / Retribution)
- Holy: 0 Spiritual Focus, Divine Strength; 1 Purifying Power, Healing Light, Improved Seals, Reverence; 2 **Divine Favor**, Illumination, Holy Conduit; 3 Divine Precision, **Oath of Light**, Infusion of Light; 4 **Holy Shock**, Consecrated Ground, Boundless Light; 5 Holy Power; 6 **Light's Vigil**
- Protection: 0 Divine Intellect, Redoubt; 1 Sacred Duty, Guardian's Favor, Precision; 2 **Templar's Bulwark**, Toughness, Improved Hammer of Justice, Shield Specialization; 3 Improved Righteous Fury, Anticipation, **Swift Judgement**; 4 Reckoning, **Holy Shield**, Stoicism; 5 Iron Creed; 6 Shieldsworn (passive: Holy Strike cooldown -4 s, strikes with the shield)
- Retribution: 0 Benediction, Deflection; 1 Sanctified Judgement, Conviction, Improved Judgement; 2 Unyielding Faith, **Seal of Command**, Pursuit of Justice, Vindication; 3 Two-Handed Weapon Specialization, Eye for an Eye, Sacred Arbiter; 4 Vengeance, **Repentance**, Turn Evil; 5 Champion of the Light; 6 Unsealed Wrath
- Tooltips: Oath of Light = active, "Swear an Oath to protect target ally for 1 hour" (one Oath at a time; Boundless Light refers to it). Voice of Truth = trainer spell, level 20, not a talent. Light's Vigil = active, level 40.

## Priest (Discipline / Holy / Shadow)
- Discipline: 0 Twin Disciplines, Wand Specialization, Power in Light; 1 Mental Strength, Martyrdom, Silent Resolve, Holy Precision; 2 Mental Agility, Meditation, **Inner Focus**, Improved Power Word: Shield; 3 Improved Mana Burn, Soul Warding, Improved Inner Fire; 4 **Penance**, Renewed Hope; 5 Divine Aegis; 6 **Power Infusion**
- Holy: 0 Improved Renew, Twilight Focus, Holy Specialization; 1 Divine Fury, Spell Warding; 2 Inspiration, Blessed Recovery, **Holy Nova**; 3 Holy Binding (passive: Flash Heal on others heals you 50%), Searing Light, Improved Healing, Holy Reach; 4 Spiritual Guidance, Spirit of Redemption, Litany of Light; 5 Spiritual Healing; 6 **Prayer of Mending**
- Shadow: 0 Blackout, Spirit Tap, Shadow Focus; 1 Shadow Reach, Improved Shadow Word: Pain, Improved Mind Blast; 2 Improved Mind Flay, **Mind Flay**, Improved Psychic Scream; 3 **Vampiric Embrace**, Shadow Weaving, Dark Inspiration; 4 Devouring Contagion, **Silence**; 5 Darkness, Early Demise; 6 **Shadowform**
- Tooltips: Binding Heal = trainer spell (requires level 56), "Heal yourself and a friendly target". Holy Binding is the passive talent, not a button.

## Rogue (Assassination / Combat / Subtlety)
- Assassination: 0 Malice, Remorseless Attacks, Improved Gouge; 1 Improved Expose Armor, Ruthlessness, Improved Slice and Dice; 2 Lethality, Blood Splatter, Vigor; 3 Improved Poisons, Vile Poisons, **Cold Blood**; 4 Improved Kidney Shot, Venom, Relentless Strikes; 5 Seal Fate; 6 **Mutilate**
- Combat: 0 Coup de Grace, Efficient Strikes, Lightning Reflexes; 1 Puncturing Wounds, Improved Sprint, Precision, Deflection; 2 **Riposte**, Endurance, Composure; 3 Weapon Expertise, Aggression, Improved Kick, Flawless Execution; 4 Hack and Slash, **Blade Flurry**, Dual Wield Specialization; 5 Flash of Steel; 6 **Adrenaline Rush**
- Subtlety: 0 Setup, Opportunity, Master of Deception; 1 Dirty Deeds, Improved Ambush, Camouflage, Dirty Tricks; 2 **Premeditation**, Serrated Blades, Initiative; 3 Elusiveness, **Ghostly Strike**, Quick Getaway; 4 **Preparation**, Heightened Senses, **Hemorrhage**; 5 Boot Knife; 6 **Death Mark**

## Shaman (Elemental / Enhancement / Restoration)
- Elemental: 0 Concussion, Convection; 1 Reverberation, Elemental Devastation, Call of Flame, Elemental Alacrity; 2 Elemental Warding, Elemental Focus; 3 Earthbound, Eye of the Storm, Trial by Fire; 4 Lightning Overload, Call of Thunder, Elemental Reach; 5 Elemental Fury; 6 **Lightning Mastery**
- Enhancement: 0 Thundering Strikes, Ancestral Knowledge, Earth's Grasp; 1 Improved Lightning Shield, Guardian Totems, Mental Dexterity; 2 Anticipation, Shamanistic Focus, Elemental Weapons; 3 **Stormstrike**, Toughness, Flurry, Improved Ghost Wolf; 4 Improved Stormstrike, Mental Quickness, Spirit Weapons; 5 Maelstrom Weapon; 6 **Rage of the Farseer**
- Restoration: 0 Tidal Focus, Improved Healing Wave; 1 Mindfulness, Totemic Focus, Natural Grace, Improved Reincarnation; 2 Ancestral Healing, **Water Shield**, Healing Focus; 3 **Mana Tide Totem**, Restorative Totems, Tidal Mastery; 4 **Nature's Swiftness**, Healing Way; 5 Purification; 6 **Riptide**

## Warlock (Affliction / Demonology / Destruction)
- Affliction: 0 Improved Life Tap, Improved Corruption, Suppression; 1 Improved Drains, Soul Harvest, Grim Reach; 2 **Amplify Curse**, Pandemic, Fel Concentration, Improved Bane of Agony; 3 **Curse of Exhaustion**, Nightfall, Malevolence; 4 Soul Siphon, **Siphon Life**; 5 Shadow Mastery; 6 **Wrack**
- Demonology: 0 Improved Health Funnel, Unholy Power, Demonic Embrace, Improved Imp; 1 Demonic Energies, Demonic Aegis, Fel Vitality, Improved Voidwalker; 2 Master Summoner, **Demonic Sacrifice**, Improved Sayaad; 3 **Fel Domination**, Demonic Brand, Decimation; 4 **Soul Link**, Demonic Knowledge, Improved Felhunter; 5 Master Demonologist; 6 Demonic Pact
- Destruction: 0 Destructive Reach, Bane, Improved Shadow Bolt; 1 Molten Skin, Aftermath, Cataclysm; 2 Ruin, **Shadowburn**; 3 Agonizing Flames, **Conflagrate**, Intensity; 4 **Bane of Havoc**, Fire and Brimstone, Pyroclasm; 5 Shadow and Flame; 6 **Incinerate**

## Warrior (Arms / Fury / Protection)
- Arms: 0 Improved Rend, Deflection, Improved Heroic Strike; 1 Improved Overpower, Improved Tactical Mastery, Improved Charge; 2 Deep Wounds, Anger Management; 3 Impale, Two-Handed Weapon Specialization, **Spearing Strike**; 4 Weaponmaster, **Sweeping Strikes**, Bloodthrill; 5 Improved Hamstring, Improved Slam; 6 **Mortal Strike**
- Fury: 0 Booming Voice, Cruelty; 1 Unbridled Wrath, Lingering Rage; 2 Enrage, Blood Craze, **Piercing Howl**, Furious Precision; 3 Improved Execute, Dual Wield Specialization, **Reckless Swings**; 4 Improved Intercept, **Death Wish**, Improved Berserker Rage, Gore Drinker; 5 Flurry, Improved Whirlwind; 6 **Bloodthirst**
- Protection: 0 Improved Bloodrage, Shield Specialization, Iron Will; 1 Improved Revenge, Improved Thunder Clap, Anticipation; 2 Improved Disarm, **Last Stand**, Master of Defense, Defiance; 3 Improved Shield Bash, Vanguard, Improved Sunder Armor; 4 Focused Rage, Improved Shield Wall, **Concussion Blow**; 5 Bastion; 6 **Shield Slam**

## Legacy perks (Wowhead, Legacy System Overview: https://www.wowhead.com/forever/guide/legacy-system-overview-rewards)
Per character, up to 16 points. What matters to Agentcraft:
- Talented (Adventure, 5 ranks): talent rows n levels earlier (above). No layout change: buttons fill when the spell is known.
- Dedicated Study (Professions, 1 rank): a castable spell (25 s cast, 23 h cooldown) that raises your lowest profession by 1. Agentcraft places it with the profession utility spells.
- Field Medicine (shorter Recently Bandaged), Reagent Economy (no vendor reagents), Luremaster, Field Guide, Permanence, Gourmand and the rest are passive: no button, no change to the item macros.
