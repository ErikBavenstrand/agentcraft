# Class layouts

Generated from `addon/Agentcraft/Layouts/*.lua` and `Macros/Data/*.lua` by `luajit dev/class-layouts.lua > dev/class-layouts.md`; regenerate after a layout change. The reasoning for each key is in the layout files' comments.

## Role guide

The keybinds are the same for every class (hard rule): plain keys = Action Bar 1, Shift = Bar 2, Ctrl = Bar 4, Alt = Bar 3 (shared item macros: HealPot Alt+Q, ManaPot Alt+E, Bandage Alt+R, Food Alt+T, Fish Alt+F, Bait Alt+G; trinkets Alt+C/V, Hearthstone Alt+4), pet bar on the mouse and Z/X. What sits on a key follows these roles where the class has a fitting spell ([dev/key-roles.md](key-roles.md); the Beast Mastery hunter is the reference):

| Key | Plain | Shift | Ctrl |
| --- | --- | --- | --- |
| Q | main attack | self-heal | secondary attack / debuff |
| E | DoT / debuff | spec defensive | secondary debuff |
| R | big hitter | burst | secondary utility attack |
| T | signature | spec control | spec utility |
| F | melee / builder | hard CC | utility |
| G | proc | AoE control | utility |
| C | escape | racial | utility |
| V | snare | emergency | utility |
| 1 | opener | buff row | buff / summon / create |
| 2 | main AoE | buff row | buff / summon / create |
| 3 | interrupt | buff row | buff / summon / create |
| 4 | ground AoE | buff row | buff / summon / create |

- Stance pages (warrior stances, druid forms, rogue Stealth, Shadowform) keep the roles; the stance only changes which spell fills one.
- Healers (Holy paladin, Discipline and Holy priest, Restoration shaman and druid): heals on plain Q E R T and 1 (main heal, HoT, big heal, spec heal, group heal), damage on Shift Q E R T; F G C V and Shift F G C V keep their roles.
- Controller page 1 mirrors the keyboard: RT = plain Q E R T 1 2 3 4, LT face = plain F G C V, LT D-pad = Shift Q E T F, LT+RT = Shift V G R, the racial and Ctrl Q E R T, no trigger = radials and basics. Page 2 is utility: the class's own buttons (resurrects, buffs, portals...) plus the shared buttons below, page 3 pet and Steam Deck extras plus overflow.

## Shared controller page 2

`Layouts/Shared.lua` merges these buttons into every class's page 2, for every spec and character; a class page holds only its own buttons (listed per class below). `profession N` = the Nth of the character's profession spells in one stable order: first primary profession's own spell, second primary's, Cooking, First Aid, fishing helpers (Bait and Tackle), then gathering and utility spells (Find Minerals, Find Herbs, Smelting, Disenchant, Prospecting, Milling, Survey), then any other profession spell. Fewer professions leave the last slots empty. Keyboard: the same professions, in the same order, sit on Action Bar 6 after tracking.

| Button | Shared button |
| --- | --- |
| RT Up | Hearthstone |
| LT A | [Bait] |
| LT X | [HealPot] |
| LT B | [Bandage] |
| LT Y | [ManaPot] |
| LT Up | trinket 8 |
| LT Down | trinket 7 |
| LT Left | [Food] |
| none Up | Fishing [Fish] |
| none Down | Basic Campfire |
| none Left | Cozy Sleeping Bag |
| none Right | [Mount] |
| LT+RT A | profession 1 |
| LT+RT X | profession 3 |
| LT+RT B | profession 4 |
| LT+RT Y | profession 2 |
| LT+RT Up | profession 6 |
| LT+RT Down | profession 5 |
| LT+RT Left | profession 7 |
| LT+RT Right | profession 8 |

Notation: `A / B` = the first spell you know (talent or rank chains), `[Name]` = a library macro that takes the key once installed (until then the spell before it, or nothing), `-` = empty on purpose. Spells without a key go to the side bars (Action Bars 5-8).

## Hunter

### Keyboard: Beast Mastery (leveling), Marksmanship

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Arcane Shot [Arcane] | Mend Pet [PetCare] | self-heal | Viper Sting |
| E | DoT / debuff | Serpent Sting | Bestial Wrath / Deterrence / Trueshot Aura | spec defensive | Scorpid Sting |
| R | big hitter | Aimed Shot | Rapid Fire [Burst] | burst | Tranquilizing Shot |
| T | signature | Summon Hawk / Sniper Shot / Strider Kick | Intimidation / Counterattack / Scatter Shot | spec control | Distracting Shot |
| F | melee / builder | Raptor Strike [Melee] | Freezing Trap | hard CC | Volley |
| G | proc | Mongoose Bite | Frost Trap | AoE control | Flare |
| C | escape | Disengage | racial | racial | Scare Beast |
| V | snare | Wing Clip | Feign Death [FD] | emergency | Eyes of the Beast |
| 1 | opener | Hunter's Mark [Opener] | Aspect of the Hawk | buff row | Aspect of the Beast |
| 2 | main AoE | Multi-Shot | Aspect of the Monkey | buff row | Aspect of the Wild |
| 3 | interrupt | Concussive Shot | Aspect of the Cheetah | buff row | Feed Pet |
| 4 | ground AoE | Explosive Trap / Immolation Trap | Aspect of the Pack | buff row | Beast Lore |

### Keyboard: Survival (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Arcane Shot [Arcane] | Mend Pet [PetCare] | self-heal | Viper Sting |
| E | DoT / debuff | Serpent Sting | Bestial Wrath / Deterrence / Trueshot Aura | spec defensive | Scorpid Sting |
| R | big hitter | Aimed Shot | Rapid Fire [Burst] | burst | Tranquilizing Shot |
| T | signature | Summon Hawk / Sniper Shot / Strider Kick | Intimidation / Counterattack / Scatter Shot | spec control | Wyvern Sting / Distracting Shot |
| F | melee / builder | Raptor Strike [Melee] | Freezing Trap | hard CC | Volley |
| G | proc | Mongoose Bite | Frost Trap | AoE control | Flare |
| C | escape | Disengage | racial | racial | Scare Beast |
| V | snare | Wing Clip | Feign Death [FD] | emergency | Eyes of the Beast |
| 1 | opener | Hunter's Mark [Opener] | Aspect of the Hawk | buff row | Aspect of the Monkey |
| 2 | main AoE | Multi-Shot | Aspect of the Beast | buff row | Aspect of the Wild |
| 3 | interrupt | Concussive Shot | Aspect of the Cheetah | buff row | Feed Pet |
| 4 | ground AoE | Explosive Trap / Immolation Trap | Aspect of the Pack | buff row | Beast Lore |

### Controller page 1: Beast Mastery, Marksmanship, Survival

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Arcane Shot [Arcane] | LT Left | Shift+T | Intimidation / Counterattack / Scatter Shot |
| RT X | E | Serpent Sting | LT Down | Shift+F | Freezing Trap |
| RT Right | R | Aimed Shot | LT+RT A | Shift+V | Feign Death [FD] |
| RT Left | T | Summon Hawk / Sniper Shot / Strider Kick | LT+RT X | Shift+G | Frost Trap |
| LT A | F | Raptor Strike [Melee] | LT+RT B | racial | racial |
| LT X | G | Mongoose Bite | LT+RT Y | Shift+R | Rapid Fire [Burst] |
| LT Y | C | Disengage | LT+RT Up | Ctrl+Q | Viper Sting |
| LT B | V | Wing Clip | LT+RT Down | Ctrl+E | Volley |
| RT Up | 1 | Hunter's Mark [Opener] | LT+RT Left | Ctrl+R | Flare |
| RT Y | 2 | Multi-Shot | LT+RT Right | Ctrl+T | Wyvern Sting / Tranquilizing Shot |
| RT B | 3 | Concussive Shot | none Up | radial / buff | Aspect of the Hawk (radial) |
| RT Down | 4 | Explosive Trap / Immolation Trap | none Left | utility | Track Beasts (radial) |
| LT Up | Shift+Q | Mend Pet [PetCare] | none Right | class basic | Feed Pet |
| LT Right | Shift+E | Bestial Wrath / Deterrence / Trueshot Aura | none Down | basic |  |

### Controller page 2 (class buttons): Beast Mastery, Marksmanship, Survival

| Button | Class button |
| --- | --- |
| RT A | Revive Pet |
| RT X | Call Pet |
| RT B | Dismiss Pet |
| RT Y | Beast Lore |
| RT Down | Beast Training |
| RT Left | Eyes of the Beast |
| RT Right | Tame Beast |

### Macros

- **Arcane** (combat): Arcane Shot that also starts Auto Shot (never toggles it off).
- **FDTrap** (combat): Traps can't be laid in combat. Press in combat to Feign Death (drops combat), press again to lay Freezing Trap. Your pet comes back to you.
- **Opener** (combat): Drops a dead or friendly target, picks the nearest enemy if you have none, then Hunter's Mark and Auto Shot. Your pet stays where it is.
- **Melee** (combat): Starts melee and uses whichever is ready: Counterattack (after a parry), Mongoose Bite (after a dodge), else Raptor Strike. Spells you don't know are skipped.
- **Burst** (combat): Every damage cooldown at once: Bestial Wrath, both trinkets, Berserking or Blood Fury, then Rapid Fire. Anything you don't have is skipped.
- **FD** (combat): A clean Feign Death: stops your cast and attacks, calls your pet back, then feigns.
- **PetCare** (pet): Calls your pet if it's missing, revives it if it's dead (even after its body is gone), otherwise heals it with Mend Pet.
- **Recall** (pet): Calls your pet back to you.
- **Travel** (utility): Speed aspect: Aspect of the Pack in a group once you know it, else Aspect of the Cheetah. Pressing again never turns it off.
- **Fight** (utility): Back to fighting: dismounts and swaps the speed aspect for Aspect of the Hawk (Monkey before you learn Hawk).
- **NoSpeed** (utility): Drops Cheetah or Pack at once, with no global cooldown, so a hit doesn't daze you.
- **TrackCycle** (utility): Each press switches to the next tracking: Beasts, Humanoids, Undead, Hidden. Needs all four (level 24).
- **Lore** (pet): Beast Lore on your target, or on your own pet when you have no target.
- **Eyes** (pet): One button into and out of Eyes of the Beast.
- **Auto <ability>** (pet): controller autocast toggles for Growl, Claw, Bite, Dash, Dive, Charge, Prowl, Cower, Screech, Furious Howl, Lightning Breath, Scorpid Poison, Thunderstomp, Shell Shield.

## Warrior

### Keyboard: Arms, Fury, Protection (leveling)

| Key | Role | Plain | Battle | Defensive | Berserker | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Q | main attack | Heroic Strike | Heroic Strike | Heroic Strike | Heroic Strike | Victory Rush | self-heal | Spearing Strike / Gore Drinker |
| E | DoT / debuff | Rend | Rend | Rend | - | Death Wish / Sweeping Strikes / Shield Block | spec defensive | Demoralizing Shout |
| R | big hitter | Execute | Execute | - | Execute | Recklessness | burst | Slam |
| T | signature | Mortal Strike / Bloodthirst / Shield Slam | Mortal Strike / Bloodthirst / Shield Slam | Mortal Strike / Bloodthirst / Shield Slam | Mortal Strike / Bloodthirst / Shield Slam | Concussion Blow / Piercing Howl | spec control | Last Stand / Reckless Swings |
| F | melee / builder | Sunder Armor | Sunder Armor | Sunder Armor | Sunder Armor | Disarm | hard CC | Taunt |
| G | proc | Overpower [Overpower] | Overpower | Revenge [Revenge] | Berserker Rage | Intimidating Shout | AoE control | Mocking Blow |
| C | escape | Intercept [Intercept] | - | - | Intercept | racial | racial | Challenging Shout |
| V | snare | Hamstring | Hamstring | - | Hamstring | Shield Wall | emergency | Retaliation |
| 1 | opener | Charge [TankCharge] | Charge [TankCharge] | Charge [TankCharge] | [ChargeIntercept] | Battle Stance | buff row | Bloodrage |
| 2 | main AoE | Cleave | Cleave | Cleave | Whirlwind | Defensive Stance | buff row | - |
| 3 | interrupt | Shield Bash / Pummel [BashPummel] | Shield Bash | Shield Bash | Pummel | Berserker Stance | buff row | - |
| 4 | ground AoE | Thunder Clap | Thunder Clap | Thunder Clap | - | Battle Shout | buff row | - |

### Controller page 1: Protection

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Heroic Strike | LT Left | Shift+T | Concussion Blow / Piercing Howl |
| RT X | E | Rend | LT Down | Shift+F | Disarm |
| RT Right | R | Execute | LT+RT A | Shift+V | Shield Wall [ShieldWall] |
| RT Left | T | Mortal Strike / Bloodthirst / Shield Slam | LT+RT X | Shift+G | Intimidating Shout |
| LT A | F | Sunder Armor | LT+RT B | racial | racial |
| LT X | G | Revenge [Revenge] | LT+RT Y | Shift+R | Recklessness |
| LT Y | C | Intercept [Intercept] | LT+RT Up | Ctrl+Q | Spearing Strike / Gore Drinker |
| LT B | V | Hamstring | LT+RT Down | Ctrl+E | Demoralizing Shout |
| RT Up | 1 | Charge [TankCharge] | LT+RT Left | Ctrl+R | Slam |
| RT Y | 2 | Cleave | LT+RT Right | Ctrl+T | Last Stand / Reckless Swings |
| RT B | 3 | Shield Bash / Pummel [BashPummel] | none Up | radial / buff | Battle Stance |
| RT Down | 4 | Thunder Clap | none Left | utility | Defensive Stance |
| LT Up | Shift+Q | Victory Rush | none Right | class basic | Berserker Stance |
| LT Right | Shift+E | Death Wish / Sweeping Strikes / Shield Block | none Down | basic | Battle Shout |

### Controller page 1: Arms

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Heroic Strike | LT Left | Shift+T | Concussion Blow / Piercing Howl |
| RT X | E | Rend | LT Down | Shift+F | Disarm |
| RT Right | R | Execute | LT+RT A | Shift+V | Shield Wall [ShieldWall] |
| RT Left | T | Mortal Strike / Bloodthirst / Shield Slam | LT+RT X | Shift+G | Intimidating Shout |
| LT A | F | Sunder Armor | LT+RT B | racial | racial |
| LT X | G | Overpower [Overpower] | LT+RT Y | Shift+R | Recklessness |
| LT Y | C | Intercept [Intercept] | LT+RT Up | Ctrl+Q | Spearing Strike / Gore Drinker |
| LT B | V | Hamstring | LT+RT Down | Ctrl+E | Demoralizing Shout |
| RT Up | 1 | Charge [TankCharge] | LT+RT Left | Ctrl+R | Slam |
| RT Y | 2 | Cleave | LT+RT Right | Ctrl+T | Last Stand / Reckless Swings |
| RT B | 3 | Shield Bash / Pummel [BashPummel] | none Up | radial / buff | Battle Stance |
| RT Down | 4 | Thunder Clap | none Left | utility | Defensive Stance |
| LT Up | Shift+Q | Victory Rush | none Right | class basic | Berserker Stance |
| LT Right | Shift+E | Death Wish / Sweeping Strikes / Shield Block | none Down | basic | Battle Shout |

### Controller page 1: Fury

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Heroic Strike | LT Left | Shift+T | Concussion Blow / Piercing Howl |
| RT X | E | Rend | LT Down | Shift+F | Disarm |
| RT Right | R | Execute | LT+RT A | Shift+V | Shield Wall [ShieldWall] |
| RT Left | T | Mortal Strike / Bloodthirst / Shield Slam | LT+RT X | Shift+G | Intimidating Shout |
| LT A | F | Sunder Armor | LT+RT B | racial | racial |
| LT X | G | Overpower [Overpower] | LT+RT Y | Shift+R | Recklessness |
| LT Y | C | Intercept [Intercept] | LT+RT Up | Ctrl+Q | Spearing Strike / Gore Drinker |
| LT B | V | Hamstring | LT+RT Down | Ctrl+E | Demoralizing Shout |
| RT Up | 1 | Charge [TankCharge] | LT+RT Left | Ctrl+R | Slam |
| RT Y | 2 | Whirlwind / Cleave [Whirlwind] | LT+RT Right | Ctrl+T | Last Stand / Reckless Swings |
| RT B | 3 | Shield Bash / Pummel [BashPummel] | none Up | radial / buff | Battle Stance |
| RT Down | 4 | Thunder Clap | none Left | utility | Defensive Stance |
| LT Up | Shift+Q | Victory Rush | none Right | class basic | Berserker Stance |
| LT Right | Shift+E | Death Wish / Sweeping Strikes / Shield Block | none Down | basic | Battle Shout |

### Controller page 2 (class buttons): Arms, Fury, Protection

Only the shared buttons.

### Macros

- **TankCharge** (combat): Protection pull: out of combat, Battle Stance then Charge; once in combat, back to Defensive Stance. Starts your attack. [M]
- **ChargeIntercept** (combat): Arms and Fury gap closer: Charge out of combat (Battle Stance first), Intercept in combat (Berserker Stance first). [M, adapted]
- **Overpower** (combat): Overpower in Battle Stance; from another stance, switches to Battle Stance first. [D]
- **Revenge** (combat): Defensive Stance if you're not in it, Shield Block, then Revenge (Shield Block makes the block that lights Revenge up). Starts your attack. [M]
- **SlamRevenge** (combat): Protection at 40+: Defensive Stance if needed, then Shield Slam and Revenge in turn (resets after 2 seconds), with Shield Block. [M]
- **Whirlwind** (combat): Starts your attack, then Whirlwind in Berserker Stance; from another stance, switches to Berserker Stance first. [M]
- **Intercept** (combat): Berserker Stance if you're not in it, then Intercept. [M, adapted]
- **BashPummel** (combat): One interrupt for any stance: with a shield, Shield Bash (Battle Stance first unless in Battle or Defensive); without, Pummel (Berserker Stance first). [M, adapted]
- **MockingBlow** (combat): Battle Stance if you're not in it, then Mocking Blow (a taunt that hits). [M]
- **BerserkerRage** (combat): Berserker Stance if you're not in it, then Berserker Rage (breaks and blocks fear). [M, adapted]
- **Retaliation** (combat): Retaliation in Battle Stance; from another stance, switches to Battle Stance first. [M, adapted]
- **ShieldWall** (combat): Emergency: Defensive Stance if needed, Last Stand (if talented), then Shield Wall. [M]

## Paladin

### Keyboard: Protection, Retribution (leveling)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Holy Strike | Flash of Light [SmartFlash] | self-heal | - |
| E | DoT / debuff | Judgement | Lay on Hands | spec defensive | - |
| R | big hitter | Exorcism [ExoJudge] | Holy Light [SmartLight] | burst | - |
| T | signature | Holy Shock / Holy Shield / Repentance | Cleanse / Purify | spec control | - |
| F | melee / builder | Seal of Command / Seal of Righteousness | Hammer of Justice | hard CC | Redemption |
| G | proc | Hammer of Wrath [HammerJudge] | Blessing of Protection | AoE control | Divine Intervention |
| C | escape | Blessing of Freedom | racial | racial | Blessing of Sacrifice |
| V | snare | Seal of Justice | Divine Shield / Divine Protection | emergency | - |
| 1 | opener | Seal of the Crusader | Righteous Fury | buff row | Devotion Aura |
| 2 | main AoE | Holy Wrath | Seal of Fury | buff row | Retribution Aura |
| 3 | interrupt | Turn Undead | Seal of Wisdom | buff row | Concentration Aura |
| 4 | ground AoE | Consecration | Seal of Light | buff row | - |

### Keyboard: Holy (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Flash of Light [SmartFlash] | Holy Strike | self-heal | - |
| E | DoT / debuff | Cleanse / Purify | Judgement | spec defensive | - |
| R | big hitter | Holy Light [SmartLight] | Exorcism [ExoJudge] | burst | - |
| T | signature | Holy Shock / Holy Shield / Repentance | Lay on Hands | spec control | - |
| F | melee / builder | Seal of Command / Seal of Righteousness | Hammer of Justice | hard CC | Redemption |
| G | proc | Hammer of Wrath [HammerJudge] | Blessing of Protection | AoE control | Divine Intervention |
| C | escape | Blessing of Freedom | racial | racial | Blessing of Sacrifice |
| V | snare | Seal of Justice | Divine Shield / Divine Protection | emergency | - |
| 1 | opener | Seal of Wisdom | Righteous Fury | buff row | Devotion Aura |
| 2 | main AoE | Holy Wrath | Seal of Fury | buff row | Retribution Aura |
| 3 | interrupt | Turn Undead | Seal of the Crusader | buff row | Concentration Aura |
| 4 | ground AoE | Consecration | Seal of Light | buff row | - |

### Controller page 1: Protection, Retribution

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Holy Strike | LT Left | Shift+T | Cleanse / Purify |
| RT X | E | Judgement | LT Down | Shift+F | Hammer of Justice |
| RT Right | R | Exorcism [ExoJudge] | LT+RT A | Shift+V | Divine Shield / Divine Protection |
| RT Left | T | Holy Shock / Holy Shield / Repentance | LT+RT X | Shift+G | Blessing of Protection |
| LT A | F | Seal of Command / Seal of Righteousness | LT+RT B | racial | racial |
| LT X | G | Hammer of Wrath [HammerJudge] | LT+RT Y | Shift+R | Holy Light [SmartLight] |
| LT Y | C | Blessing of Freedom | LT+RT Up | Ctrl+Q | Seal of Fury |
| LT B | V | Seal of Justice | LT+RT Down | Ctrl+E | Seal of Wisdom |
| RT Up | 1 | Seal of the Crusader | LT+RT Left | Ctrl+R | Seal of Light |
| RT Y | 2 | Holy Wrath | LT+RT Right | Ctrl+T |  |
| RT B | 3 | Turn Undead | none Up | radial / buff | Devotion Aura |
| RT Down | 4 | Consecration | none Left | utility | Retribution Aura |
| LT Up | Shift+Q | Flash of Light [SmartFlash] | none Right | class basic | Concentration Aura |
| LT Right | Shift+E | Lay on Hands | none Down | basic | Righteous Fury |

### Controller page 1: Holy

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Flash of Light [SmartFlash] | LT Left | Shift+T | Lay on Hands |
| RT X | E | Cleanse / Purify | LT Down | Shift+F | Hammer of Justice |
| RT Right | R | Holy Light [SmartLight] | LT+RT A | Shift+V | Divine Shield / Divine Protection |
| RT Left | T | Holy Shock / Holy Shield / Repentance | LT+RT X | Shift+G | Blessing of Protection |
| LT A | F | Seal of Command / Seal of Righteousness | LT+RT B | racial | racial |
| LT X | G | Hammer of Wrath [HammerJudge] | LT+RT Y | Shift+R | Exorcism [ExoJudge] |
| LT Y | C | Blessing of Freedom | LT+RT Up | Ctrl+Q | Seal of Fury |
| LT B | V | Seal of Justice | LT+RT Down | Ctrl+E | Seal of the Crusader |
| RT Up | 1 | Seal of Wisdom | LT+RT Left | Ctrl+R | Seal of Light |
| RT Y | 2 | Holy Wrath | LT+RT Right | Ctrl+T |  |
| RT B | 3 | Turn Undead | none Up | radial / buff | Devotion Aura |
| RT Down | 4 | Consecration | none Left | utility | Retribution Aura |
| LT Up | Shift+Q | Holy Strike | none Right | class basic | Concentration Aura |
| LT Right | Shift+E | Judgement | none Down | basic | Righteous Fury |

### Controller page 2 (class buttons): Holy, Protection, Retribution

| Button | Class button |
| --- | --- |
| RT A | Redemption |
| RT X | Blessing of Might |
| RT B | Blessing of Wisdom |
| RT Y | Blessing of Kings |
| RT Down | overflow |
| RT Left | Divine Intervention |
| RT Right | Blessing of Sacrifice |

### Macros

- **ExoJudge** (combat): Starts melee on your enemy target, Judges if Judgement is ready, then casts Exorcism (Undead and Demons only).
- **HammerJudge** (combat): Judges if Judgement is ready, then Hammer of Wrath (targets below 20% health) in one press.
- **Repent** (combat): Repentance and Judgement in one press (Retribution talent).
- **SmartFlash** (combat): Flash of Light on your target if it's a living friend, otherwise on yourself, without dropping your enemy target.
- **SmartLight** (combat): Holy Light on your target if it's a living friend, otherwise on yourself, without dropping your enemy target.

## Rogue

### Keyboard: Assassination, Subtlety

| Key | Role | Plain | Stealth | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- |
| Q | main attack | Mutilate / Hemorrhage / Sinister Strike | Mutilate / Hemorrhage / Sinister Strike | - | self-heal | - |
| E | DoT / debuff | Rupture | Garrote | Evasion | spec defensive | Expose Armor |
| R | big hitter | Eviscerate | Ambush [Premed] | Adrenaline Rush / Cold Blood / Preparation [Blades] | burst | Feint |
| T | signature | Shank | Premeditation | Kidney Shot | spec control | - |
| F | melee / builder | Ghostly Strike / Backstab | Ghostly Strike / Backstab | Sap | hard CC | Pick Pocket |
| G | proc | Riposte | - | Blind | AoE control | Distract |
| C | escape | Sprint | Sprint | racial | racial | Pick Lock |
| V | snare | Gouge | - | Vanish [Poof] | emergency | Disarm Trap |
| 1 | opener | Throw / Shoot Bow / Shoot Crossbow / Shoot Gun | Cheap Shot | Stealth | buff row | - |
| 2 | main AoE | Blade Flurry | - | - | buff row | - |
| 3 | interrupt | Kick | Kick | - | buff row | - |
| 4 | ground AoE | Slice and Dice | - | - | buff row | - |

### Keyboard: Combat (leveling) (own bars)

| Key | Role | Plain | Stealth | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- |
| Q | main attack | Sinister Strike [Strike] | Mutilate / Hemorrhage / Sinister Strike | - | self-heal | - |
| E | DoT / debuff | Rupture | Garrote | Evasion | spec defensive | Expose Armor |
| R | big hitter | Eviscerate | Ambush [Premed] | Adrenaline Rush / Cold Blood / Preparation [Blades] | burst | Feint |
| T | signature | Shank | Premeditation | Kidney Shot | spec control | - |
| F | melee / builder | Ghostly Strike / Backstab | Ghostly Strike / Backstab | Sap | hard CC | Pick Pocket |
| G | proc | Riposte | - | Blind | AoE control | Distract |
| C | escape | Sprint | Sprint | racial | racial | Pick Lock |
| V | snare | Gouge | - | Vanish [Poof] | emergency | Disarm Trap |
| 1 | opener | Throw / Shoot Bow / Shoot Crossbow / Shoot Gun | Cheap Shot | Stealth | buff row | - |
| 2 | main AoE | Blade Flurry | - | - | buff row | - |
| 3 | interrupt | Kick | Kick | - | buff row | - |
| 4 | ground AoE | Slice and Dice | - | - | buff row | - |

### Controller page 1: Assassination, Combat, Subtlety

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Mutilate / Hemorrhage / Sinister Strike | LT Left | Shift+T | Kidney Shot |
| RT X | E | Rupture | LT Down | Shift+F | Sap |
| RT Right | R | Eviscerate | LT+RT A | Shift+V | Vanish [Poof] |
| RT Left | T | Shank | LT+RT X | Shift+G | Blind |
| LT A | F | Ghostly Strike / Backstab | LT+RT B | racial | racial |
| LT X | G | Riposte | LT+RT Y | Shift+R | Adrenaline Rush / Cold Blood / Preparation [Blades] |
| LT Y | C | Sprint | LT+RT Up | Ctrl+Q | Garrote |
| LT B | V | Gouge | LT+RT Down | Ctrl+E | Expose Armor |
| RT Up | 1 | Cheap Shot | LT+RT Left | Ctrl+R | Feint |
| RT Y | 2 | Blade Flurry | LT+RT Right | Ctrl+T | Premeditation |
| RT B | 3 | Kick | none Up | radial / buff | Stealth |
| RT Down | 4 | Slice and Dice | none Left | utility | Pick Pocket |
| LT Up | Shift+Q | Ambush [Premed] | none Right | class basic | Throw / Shoot Bow / Shoot Crossbow / Shoot Gun |
| LT Right | Shift+E | Evasion | none Down | basic | Distract |

### Controller page 2 (class buttons): Assassination, Combat, Subtlety

| Button | Class button |
| --- | --- |
| RT A | Pick Lock |
| RT X | Disarm Trap |

### Macros

- **Strike** (combat): Starts melee and uses Riposte when it lights up after a parry, else Sinister Strike. Riposte is skipped until you have it.
- **Premed** (combat): From Stealth: Premeditation (2 combo points, no global cooldown) then Ambush. Premeditation is skipped until you have it.
- **Blades** (combat): Both Combat cooldowns at once: Adrenaline Rush and Blade Flurry. Adrenaline Rush is skipped until you have it.
- **Poof** (combat): A clean Vanish: stops your auto attack first, so the next swing doesn't pull you out of Stealth.

## Priest

### Keyboard: Shadow (leveling)

| Key | Role | Plain | Shadowform | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- |
| Q | main attack | Mind Flay / Smite [Flay] | Mind Flay / Smite [Flay] | Flash Heal / Lesser Heal | self-heal | Mana Burn |
| E | DoT / debuff | Shadow Word: Pain | Shadow Word: Pain | Power Word: Shield | spec defensive | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash |
| R | big hitter | Mind Blast | Mind Blast | Power Infusion / Inner Focus [Empower] | burst | Mind Soothe |
| T | signature | Vampiric Embrace / Penance / Prayer of Mending | Vampiric Embrace / Penance / Prayer of Mending | Mind Control | spec control | Mind Vision |
| F | melee / builder | Shoot | Shoot | Shackle Undead | hard CC | Renew |
| G | proc | Shadow Word: Death | Shadow Word: Death | Psychic Scream | AoE control | Greater Heal / Heal |
| C | escape | Fade | Fade | racial | racial | Abolish Disease / Cure Disease |
| V | snare | - | - | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan | emergency | Resurrection |
| 1 | opener | Holy Fire | [MindPull] | Power Word: Fortitude | buff row | Divine Spirit |
| 2 | main AoE | Holy Nova | - | Inner Fire | buff row | Shadow Protection |
| 3 | interrupt | Silence / Dispel Magic | Silence / Dispel Magic | Shadowform | buff row | Prayer of Fortitude |
| 4 | ground AoE | Devouring Plague | Devouring Plague | Fear Ward | buff row | Levitate |

### Keyboard: Discipline (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Flash Heal / Lesser Heal | Mind Flay / Smite [Flay] | self-heal | Mana Burn |
| E | DoT / debuff | Renew | Shadow Word: Pain | spec defensive | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash |
| R | big hitter | Greater Heal / Heal | Mind Blast | burst | Mind Soothe |
| T | signature | Penance / Prayer of Mending / Holy Binding | Holy Fire | spec control | Mind Vision |
| F | melee / builder | Shoot | Shackle Undead | hard CC | Mind Control |
| G | proc | Shadow Word: Death | Psychic Scream | AoE control | Devouring Plague |
| C | escape | Fade | racial | racial | Abolish Disease / Cure Disease |
| V | snare | - | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan | emergency | Resurrection |
| 1 | opener | Prayer of Healing | Power Word: Fortitude | buff row | Divine Spirit |
| 2 | main AoE | Holy Nova | Inner Fire | buff row | Shadow Protection |
| 3 | interrupt | Silence / Dispel Magic | Power Infusion / Inner Focus [Empower] | buff row | Prayer of Fortitude |
| 4 | ground AoE | Power Word: Shield | Fear Ward | buff row | Levitate |

### Keyboard: Holy (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Flash Heal / Lesser Heal | Mind Flay / Smite [Flay] | self-heal | Mana Burn |
| E | DoT / debuff | Renew | Shadow Word: Pain | spec defensive | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash |
| R | big hitter | Greater Heal / Heal | Mind Blast | burst | Mind Soothe |
| T | signature | Penance / Prayer of Mending / Holy Binding | Holy Fire | spec control | Mind Vision |
| F | melee / builder | Shoot | Shackle Undead | hard CC | Mind Control |
| G | proc | Shadow Word: Death | Psychic Scream | AoE control | Devouring Plague |
| C | escape | Fade | racial | racial | Abolish Disease / Cure Disease |
| V | snare | - | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan | emergency | Resurrection |
| 1 | opener | Prayer of Healing | Power Word: Fortitude | buff row | Divine Spirit |
| 2 | main AoE | Holy Nova | Inner Fire | buff row | Shadow Protection |
| 3 | interrupt | Silence / Dispel Magic | Power Infusion / Inner Focus [Empower] | buff row | Prayer of Fortitude |
| 4 | ground AoE | Power Word: Shield | Fear Ward | buff row | Levitate |

### Controller page 1: Shadow

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Mind Flay / Smite [Flay] | LT Left | Shift+T | Mind Control |
| RT X | E | Shadow Word: Pain | LT Down | Shift+F | Shackle Undead |
| RT Right | R | Mind Blast [MindPull] | LT+RT A | Shift+V | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan |
| RT Left | T | Vampiric Embrace / Penance / Prayer of Mending | LT+RT X | Shift+G | Psychic Scream |
| LT A | F | Shoot | LT+RT B | racial | racial |
| LT X | G | Shadow Word: Death | LT+RT Y | Shift+R | Power Infusion / Inner Focus [Empower] |
| LT Y | C | Fade | LT+RT Up | Ctrl+Q | Mana Burn |
| LT B | V |  | LT+RT Down | Ctrl+E | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash |
| RT Up | 1 | Holy Fire | LT+RT Left | Ctrl+R | Mind Soothe |
| RT Y | 2 | Holy Nova | LT+RT Right | Ctrl+T | Mind Vision |
| RT B | 3 | Silence / Dispel Magic | none Up | radial / buff | Power Word: Fortitude |
| RT Down | 4 | Devouring Plague | none Left | utility | Inner Fire |
| LT Up | Shift+Q | Flash Heal / Lesser Heal | none Right | class basic | Shadowform |
| LT Right | Shift+E | Power Word: Shield | none Down | basic | Renew |

### Controller page 1: Discipline

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Flash Heal / Lesser Heal | LT Left | Shift+T | Holy Fire |
| RT X | E | Renew | LT Down | Shift+F | Shackle Undead |
| RT Right | R | Greater Heal / Heal | LT+RT A | Shift+V | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan |
| RT Left | T | Penance / Prayer of Mending / Holy Binding | LT+RT X | Shift+G | Psychic Scream |
| LT A | F | Shoot | LT+RT B | racial | racial |
| LT X | G | Shadow Word: Death | LT+RT Y | Shift+R | Mind Blast |
| LT Y | C | Fade | LT+RT Up | Ctrl+Q | Mana Burn |
| LT B | V |  | LT+RT Down | Ctrl+E | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash |
| RT Up | 1 | Prayer of Healing | LT+RT Left | Ctrl+R | Mind Soothe |
| RT Y | 2 | Holy Nova | LT+RT Right | Ctrl+T | Mind Vision |
| RT B | 3 | Silence / Dispel Magic | none Up | radial / buff | Power Word: Fortitude |
| RT Down | 4 | Power Word: Shield | none Left | utility | Inner Fire |
| LT Up | Shift+Q | Mind Flay / Smite [Flay] | none Right | class basic | Power Infusion / Inner Focus [Empower] |
| LT Right | Shift+E | Shadow Word: Pain | none Down | basic |  |

### Controller page 1: Holy

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Flash Heal / Lesser Heal | LT Left | Shift+T | Holy Fire |
| RT X | E | Renew | LT Down | Shift+F | Shackle Undead |
| RT Right | R | Greater Heal / Heal | LT+RT A | Shift+V | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan |
| RT Left | T | Penance / Prayer of Mending / Holy Binding | LT+RT X | Shift+G | Psychic Scream |
| LT A | F | Shoot | LT+RT B | racial | racial |
| LT X | G | Shadow Word: Death | LT+RT Y | Shift+R | Mind Blast |
| LT Y | C | Fade | LT+RT Up | Ctrl+Q | Mana Burn |
| LT B | V |  | LT+RT Down | Ctrl+E | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash |
| RT Up | 1 | Prayer of Healing | LT+RT Left | Ctrl+R | Mind Soothe |
| RT Y | 2 | Holy Nova | LT+RT Right | Ctrl+T | Mind Vision |
| RT B | 3 | Silence / Dispel Magic | none Up | radial / buff | Power Word: Fortitude |
| RT Down | 4 | Power Word: Shield | none Left | utility | Inner Fire |
| LT Up | Shift+Q | Mind Flay / Smite [Flay] | none Right | class basic | Power Infusion / Inner Focus [Empower] |
| LT Right | Shift+E | Shadow Word: Pain | none Down | basic |  |

### Controller page 2 (class buttons): Discipline, Holy, Shadow

| Button | Class button |
| --- | --- |
| RT A | Resurrection |
| RT X | Levitate |
| RT B | Abolish Disease / Cure Disease |
| RT Y | Divine Spirit |
| RT Down | Fear Ward |
| RT Left | Shadow Protection |
| RT Right | Prayer of Fortitude |

### Macros

- **Flay** (combat): Mind Flay that never clips itself: pressing it again while Mind Flay channels does nothing, so you can hold or mash the button.
- **MindPull** (combat): Drops a dead or friendly target, picks the nearest enemy if you have none, then Mind Blast.
- **Empower** (combat): Every cooldown at once: Inner Focus, both trinkets, Berserking, then Power Infusion on your friendly target (else on you). Anything you don't have is skipped.

## Shaman

### Keyboard: Elemental, Enhancement (leveling)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Lightning Bolt | Healing Wave [WaveHeal] | self-heal | Lesser Healing Wave |
| E | DoT / debuff | Flame Shock | Stoneskin Totem | spec defensive | Cure Poison |
| R | big hitter | Chain Lightning | Rage of the Farseer | burst | Cure Disease |
| T | signature | Stormstrike / Lightning Mastery / Riptide | Grounding Totem | spec control | Totemic Call |
| F | melee / builder | [ShockCycle] | - | hard CC | Strength of Earth Totem |
| G | proc | Purge | Earthbind Totem | AoE control | Healing Stream Totem |
| C | escape | Ghost Wolf | racial | racial | Mana Spring Totem |
| V | snare | Frost Shock | Nature's Swiftness [NSWave] | emergency | Windfury Totem |
| 1 | opener | Searing Totem | Water Shield / Lightning Shield | buff row | Call of the Elements |
| 2 | main AoE | Fire Nova | Rockbiter Weapon | buff row | Call of the Ancestors |
| 3 | interrupt | Earth Shock [ShockKick] | Flametongue Weapon | buff row | Call of the Spirits |
| 4 | ground AoE | Magma Totem [MagmaNova] | Windfury Weapon | buff row | Totemic Recall |

### Keyboard: Restoration (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Healing Wave [WaveHeal] | Lightning Bolt | self-heal | Grounding Totem |
| E | DoT / debuff | Riptide | Flame Shock | spec defensive | Cure Poison |
| R | big hitter | Lesser Healing Wave | Chain Lightning | burst | Cure Disease |
| T | signature | Mana Tide Totem | Searing Totem | spec control | Totemic Call |
| F | melee / builder | [ShockCycle] | - | hard CC | Strength of Earth Totem |
| G | proc | Purge | Earthbind Totem | AoE control | Healing Stream Totem |
| C | escape | Ghost Wolf | racial | racial | Mana Spring Totem |
| V | snare | Frost Shock | Nature's Swiftness [NSWave] | emergency | Windfury Totem |
| 1 | opener | Chain Heal | Water Shield / Lightning Shield | buff row | Call of the Elements |
| 2 | main AoE | Fire Nova | Rockbiter Weapon | buff row | Call of the Ancestors |
| 3 | interrupt | Earth Shock [ShockKick] | Flametongue Weapon | buff row | Call of the Spirits |
| 4 | ground AoE | Magma Totem [MagmaNova] | Windfury Weapon | buff row | Totemic Recall |

### Controller page 1: Elemental, Enhancement

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Lightning Bolt | LT Left | Shift+T | Grounding Totem |
| RT X | E | Flame Shock | LT Down | Shift+F |  |
| RT Right | R | Chain Lightning | LT+RT A | Shift+V | Nature's Swiftness [NSWave] |
| RT Left | T | Stormstrike / Lightning Mastery / Riptide | LT+RT X | Shift+G | Earthbind Totem |
| LT A | F | [ShockCycle] | LT+RT B | racial | racial |
| LT X | G | Purge | LT+RT Y | Shift+R | Rage of the Farseer |
| LT Y | C | Ghost Wolf | LT+RT Up | Ctrl+Q | Lesser Healing Wave |
| LT B | V | Frost Shock | LT+RT Down | Ctrl+E | Cure Poison |
| RT Up | 1 | Searing Totem | LT+RT Left | Ctrl+R | Cure Disease |
| RT Y | 2 | Fire Nova | LT+RT Right | Ctrl+T | Totemic Call |
| RT B | 3 | Earth Shock [ShockKick] | none Up | radial / buff | Water Shield / Lightning Shield |
| RT Down | 4 | Magma Totem [MagmaNova] | none Left | utility | Call of the Elements |
| LT Up | Shift+Q | Healing Wave [WaveHeal] | none Right | class basic | Totemic Recall |
| LT Right | Shift+E | Stoneskin Totem | none Down | basic | Windfury Weapon / Rockbiter Weapon |

### Controller page 1: Restoration

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Healing Wave [WaveHeal] | LT Left | Shift+T | Searing Totem |
| RT X | E | Riptide | LT Down | Shift+F |  |
| RT Right | R | Lesser Healing Wave | LT+RT A | Shift+V | Nature's Swiftness [NSWave] |
| RT Left | T | Mana Tide Totem | LT+RT X | Shift+G | Earthbind Totem |
| LT A | F | [ShockCycle] | LT+RT B | racial | racial |
| LT X | G | Purge | LT+RT Y | Shift+R | Chain Lightning |
| LT Y | C | Ghost Wolf | LT+RT Up | Ctrl+Q | Grounding Totem |
| LT B | V | Frost Shock | LT+RT Down | Ctrl+E | Cure Poison |
| RT Up | 1 | Chain Heal | LT+RT Left | Ctrl+R | Cure Disease |
| RT Y | 2 | Fire Nova | LT+RT Right | Ctrl+T | Totemic Call |
| RT B | 3 | Earth Shock [ShockKick] | none Up | radial / buff | Water Shield / Lightning Shield |
| RT Down | 4 | Magma Totem [MagmaNova] | none Left | utility | Call of the Elements |
| LT Up | Shift+Q | Lightning Bolt | none Right | class basic | Totemic Recall |
| LT Right | Shift+E | Flame Shock | none Down | basic | Windfury Weapon / Rockbiter Weapon |

### Controller page 2 (class buttons): Elemental, Enhancement, Restoration

| Button | Class button |
| --- | --- |
| RT A | Ancestral Spirit |
| RT X | Astral Recall |
| RT B | Far Sight |
| RT Y | Water Walking |
| RT Down | Water Breathing |
| RT Left | Frostbrand Weapon |

### Macros

- **ShockKick** (combat): Earth Shock that stops your own cast first, so it interrupts the moment you press it (Forever has no Wind Shear).
- **ShockCycle** (combat): Flame Shock, then Earth Shock on the next press (the shared shock cooldown holds it until ready); starts over on a new target, out of combat or after 12 sec. Also starts melee.
- **MagmaNova** (combat): AoE on one key: drops Magma Totem, then each press after detonates it with Fire Nova; starts over out of combat or after 20 sec (the totem's life).
- **BoltOrWave** (combat): One button for both: Lightning Bolt on an enemy, Healing Wave on a friend, and Healing Wave on yourself with no target.
- **WaveHeal** (combat): Healing Wave on your target if it's a living friend, else on yourself, so you never have to drop an enemy target to heal.
- **NSWave** (combat): Emergency heal: Nature's Swiftness, then an instant Healing Wave on your friendly target, else on yourself.

## Mage

### Keyboard: Frost (leveling)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Fire Blast | Evocation | self-heal | Flamestrike |
| E | DoT / debuff | Scorch | Ice Barrier / Mana Shield | spec defensive | - |
| R | big hitter | Frostbolt | Arcane Power / Combustion / Cold Snap | burst | [CounterFocus] |
| T | signature | Arcane Missiles | [PolyFocus] | spec control | Fire Ward |
| F | melee / builder | Fireball | Polymorph | hard CC | Dampen Magic |
| G | proc | Ice Lance [BlockLance] | Frost Nova | AoE control | Amplify Magic |
| C | escape | Blink | racial | racial | Slow Fall |
| V | snare | Cone of Cold | Ice Block [BlockBreak] | emergency | Remove Lesser Curse |
| 1 | opener | Pyroblast | Ice Armor / Frost Armor [ArmorSwap] | buff row | Arcane Brilliance |
| 2 | main AoE | Arcane Explosion | Mage Armor | buff row | Conjure Water [ConjureBoth] |
| 3 | interrupt | Counterspell | Arcane Intellect | buff row | Conjure Food |
| 4 | ground AoE | Blizzard | Frost Ward | buff row | Conjure Mana Ruby / Conjure Mana Citrine / Conjure Mana Jade / Conjure Mana Agate |

### Keyboard: Arcane (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Fire Blast | Evocation | self-heal | Flamestrike |
| E | DoT / debuff | Arcane Wrath / Scorch | Ice Barrier / Mana Shield | spec defensive | - |
| R | big hitter | Arcane Blast / Frostbolt | Arcane Power / Combustion / Cold Snap | burst | [CounterFocus] |
| T | signature | Presence of Mind | [PolyFocus] | spec control | Fire Ward |
| F | melee / builder | Fireball | Polymorph | hard CC | Dampen Magic |
| G | proc | Arcane Missiles | Frost Nova | AoE control | Amplify Magic |
| C | escape | Blink | racial | racial | Slow Fall |
| V | snare | Cone of Cold | Ice Block [BlockBreak] | emergency | Remove Lesser Curse |
| 1 | opener | Pyroblast | Ice Armor / Frost Armor [ArmorSwap] | buff row | Arcane Brilliance |
| 2 | main AoE | Arcane Explosion | Mage Armor | buff row | Conjure Water [ConjureBoth] |
| 3 | interrupt | Counterspell | Arcane Intellect | buff row | Conjure Food |
| 4 | ground AoE | Blizzard | Frost Ward | buff row | Conjure Mana Ruby / Conjure Mana Citrine / Conjure Mana Jade / Conjure Mana Agate |

### Keyboard: Fire (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Fire Blast | Evocation | self-heal | Blizzard |
| E | DoT / debuff | Scorch | Ice Barrier / Mana Shield | spec defensive | - |
| R | big hitter | Fireball | Arcane Power / Combustion / Cold Snap | burst | [CounterFocus] |
| T | signature | Blast Wave | [PolyFocus] | spec control | Fire Ward |
| F | melee / builder | Frostbolt | Polymorph | hard CC | Dampen Magic |
| G | proc | Pyroblast | Frost Nova | AoE control | Amplify Magic |
| C | escape | Blink | racial | racial | Slow Fall |
| V | snare | Cone of Cold | Ice Block [BlockBreak] | emergency | Remove Lesser Curse |
| 1 | opener | Frostfire Bolt | Ice Armor / Frost Armor [ArmorSwap] | buff row | Arcane Brilliance |
| 2 | main AoE | Arcane Explosion | Mage Armor | buff row | Conjure Water [ConjureBoth] |
| 3 | interrupt | Counterspell | Arcane Intellect | buff row | Conjure Food |
| 4 | ground AoE | Flamestrike | Frost Ward | buff row | Conjure Mana Ruby / Conjure Mana Citrine / Conjure Mana Jade / Conjure Mana Agate |

### Controller page 1: Frost

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Fire Blast | LT Left | Shift+T | [PolyFocus] |
| RT X | E | Scorch | LT Down | Shift+F | Polymorph |
| RT Right | R | Frostbolt | LT+RT A | Shift+V | Ice Block [BlockBreak] |
| RT Left | T | Arcane Missiles | LT+RT X | Shift+G | Frost Nova |
| LT A | F | Fireball | LT+RT B | racial | racial |
| LT X | G | Ice Lance [BlockLance] | LT+RT Y | Shift+R | Arcane Power / Combustion / Cold Snap |
| LT Y | C | Blink | LT+RT Up | Ctrl+Q | Flamestrike |
| LT B | V | Cone of Cold | LT+RT Down | Ctrl+E | Frost Ward |
| RT Up | 1 | Pyroblast | LT+RT Left | Ctrl+R | [CounterFocus] |
| RT Y | 2 | Arcane Explosion | LT+RT Right | Ctrl+T | Fire Ward |
| RT B | 3 | Counterspell | none Up | radial / buff | Arcane Intellect |
| RT Down | 4 | Blizzard | none Left | utility | Remove Lesser Curse |
| LT Up | Shift+Q | Evocation | none Right | class basic |  |
| LT Right | Shift+E | Ice Barrier / Mana Shield | none Down | basic |  |

### Controller page 1: Arcane

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Fire Blast | LT Left | Shift+T | [PolyFocus] |
| RT X | E | Arcane Wrath / Scorch | LT Down | Shift+F | Polymorph |
| RT Right | R | Arcane Blast / Frostbolt | LT+RT A | Shift+V | Ice Block [BlockBreak] |
| RT Left | T | Presence of Mind | LT+RT X | Shift+G | Frost Nova |
| LT A | F | Fireball | LT+RT B | racial | racial |
| LT X | G | Arcane Missiles | LT+RT Y | Shift+R | Arcane Power / Combustion / Cold Snap |
| LT Y | C | Blink | LT+RT Up | Ctrl+Q | Flamestrike |
| LT B | V | Cone of Cold | LT+RT Down | Ctrl+E | Frost Ward |
| RT Up | 1 | Pyroblast | LT+RT Left | Ctrl+R | [CounterFocus] |
| RT Y | 2 | Arcane Explosion | LT+RT Right | Ctrl+T | Fire Ward |
| RT B | 3 | Counterspell | none Up | radial / buff | Arcane Intellect |
| RT Down | 4 | Blizzard | none Left | utility | Remove Lesser Curse |
| LT Up | Shift+Q | Evocation | none Right | class basic |  |
| LT Right | Shift+E | Ice Barrier / Mana Shield | none Down | basic |  |

### Controller page 1: Fire

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Fire Blast | LT Left | Shift+T | [PolyFocus] |
| RT X | E | Scorch | LT Down | Shift+F | Polymorph |
| RT Right | R | Fireball | LT+RT A | Shift+V | Ice Block [BlockBreak] |
| RT Left | T | Blast Wave | LT+RT X | Shift+G | Frost Nova |
| LT A | F | Frostbolt | LT+RT B | racial | racial |
| LT X | G | Pyroblast | LT+RT Y | Shift+R | Arcane Power / Combustion / Cold Snap |
| LT Y | C | Blink | LT+RT Up | Ctrl+Q | Blizzard |
| LT B | V | Cone of Cold | LT+RT Down | Ctrl+E | Frost Ward |
| RT Up | 1 | Frostfire Bolt | LT+RT Left | Ctrl+R | [CounterFocus] |
| RT Y | 2 | Arcane Explosion | LT+RT Right | Ctrl+T | Fire Ward |
| RT B | 3 | Counterspell | none Up | radial / buff | Arcane Intellect |
| RT Down | 4 | Flamestrike | none Left | utility | Remove Lesser Curse |
| LT Up | Shift+Q | Evocation | none Right | class basic |  |
| LT Right | Shift+E | Ice Barrier / Mana Shield | none Down | basic |  |

### Controller page 2 (class buttons): Arcane, Fire, Frost

| Button | Class button |
| --- | --- |
| RT A | Ice Armor / Frost Armor [ArmorSwap] |
| RT X | Mage Armor |
| RT B | Conjure Water [ConjureBoth] |
| RT Y | Conjure Mana Ruby / Conjure Mana Citrine / Conjure Mana Jade / Conjure Mana Agate |
| RT Down | Arcane Brilliance |
| RT Left | Teleport: Orgrimmar / Teleport: Stormwind |
| RT Right | Portal: Orgrimmar / Portal: Stormwind |
| LT Right | Portal: Thunder Bluff / Portal: Darnassus |

### Macros

- **PolyFocus** (combat): Polymorphs your focus without changing target. Alternates ranks, because a sheep can't be refreshed with the same or a lower rank; resets after 15 seconds.
- **CounterFocus** (combat): Stops your own cast and Counterspells your focus without changing target.
- **BlockBreak** (combat): Ice Block; press again while in the block to leave it early.
- **BlockLance** (combat): Ice Lance that first breaks your Ice Block, so you can strike the moment you leave it. Outside the block it is a plain Ice Lance.
- **ArmorSwap** (utility): Each press switches between Ice Armor and Mage Armor.
- **ConjureBoth** (utility): Conjures water, then food on the next press; starts over with water after 4 seconds idle.

## Warlock

### Keyboard: Affliction (leveling), Demonology, Destruction

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | main attack | Shadow Bolt | Health Funnel | self-heal | Siphon Life / Conflagrate / Soul Link |
| E | DoT / debuff | Corruption | Amplify Curse / Fel Domination / Bane of Havoc | spec defensive | Curse of the Elements |
| R | big hitter | Immolate | Demonic Sacrifice / Shadowburn / Inferno | burst | Searing Pain |
| T | signature | Wrack / Incinerate / Soul Fire [Wrack] | Enslave Demon | spec control | Bane of Doom |
| F | melee / builder | Drain Life [DrainLife] | Fear | hard CC | Curse of Weakness |
| G | proc | Drain Soul [DrainSoul] | Howl of Terror | AoE control | Curse of Tongues |
| C | escape | Death Coil | racial | racial | Eye of Kilrogg |
| V | snare | Life Tap | Shadow Ward | emergency | Drain Mana |
| 1 | opener | Bane of Agony | Demon Armor / Demon Skin | buff row | Summon Imp |
| 2 | main AoE | Hellfire | Create Healthstone | buff row | Summon Voidwalker |
| 3 | interrupt | [PetSpecial] | Create Soulstone | buff row | Summon Sayaad / Summon Succubus |
| 4 | ground AoE | Rain of Fire | Unending Breath | buff row | Summon Felhunter |

### Controller page 1: Affliction, Demonology, Destruction

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Shadow Bolt | LT Left | Shift+T | Enslave Demon |
| RT X | E | Corruption | LT Down | Shift+F | Fear |
| RT Right | R | Immolate | LT+RT A | Shift+V | Shadow Ward |
| RT Left | T | Wrack / Incinerate / Soul Fire [Wrack] | LT+RT X | Shift+G | Howl of Terror |
| LT A | F | Drain Life [DrainLife] | LT+RT B | racial | racial |
| LT X | G | Drain Soul [DrainSoul] | LT+RT Y | Shift+R | Demonic Sacrifice / Shadowburn / Inferno |
| LT Y | C | Death Coil | LT+RT Up | Ctrl+Q | Siphon Life / Conflagrate / Soul Link |
| LT B | V | Life Tap | LT+RT Down | Ctrl+E | Curse of the Elements |
| RT Up | 1 | Bane of Agony | LT+RT Left | Ctrl+R | Searing Pain |
| RT Y | 2 | Hellfire | LT+RT Right | Ctrl+T | Bane of Doom |
| RT B | 3 | [PetSpecial] | none Up | radial / buff | Demon Armor / Demon Skin |
| RT Down | 4 | Rain of Fire | none Left | utility | Curse of Weakness |
| LT Up | Shift+Q | Health Funnel | none Right | class basic | Curse of Tongues |
| LT Right | Shift+E | Amplify Curse / Fel Domination / Bane of Havoc | none Down | basic | Drain Mana |

### Controller page 2 (class buttons): Affliction, Demonology, Destruction

| Button | Class button |
| --- | --- |
| RT A | Create Healthstone |
| RT X | Create Soulstone |
| RT B | Unending Breath |
| RT Y | Eye of Kilrogg |
| RT Down | overflow |

### Macros

- **DrainLife** (combat): Drain Life that never restarts the channel when you press it again mid-drain.
- **DrainSoul** (combat): Drain Soul that never restarts the channel when you press it again, so a shard tick isn't lost.
- **Wrack** (combat): Wrack (Affliction filler) that never restarts the channel when you press it again.
- **PetSpecial** (pet): Your demon's control spell on one button: Spell Lock (Felhunter), Sacrifice (Voidwalker) or Seduction (Sayaad).
- **Auto <ability>** (pet): controller autocast toggles for Firebolt, Torment, Suffering, Consume Shadows, Lash of Pain, Soothing Kiss, Devour Magic, Tainted Blood.

## Druid

### Keyboard: Balance, Feral Combat (leveling)

| Key | Role | Plain | Cat | Bear | Moonkin | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Q | main attack | Wrath | Claw | Maul | Wrath | Regrowth [Regrow] | self-heal | Faerie Fire |
| E | DoT / debuff | Moonfire | Rake | Lacerate | Moonfire | Shifting Power / Nature's Swiftness | spec defensive | - |
| R | big hitter | Starfire | Ferocious Bite | Primal Bite | Starfire | Innervate | burst | - |
| T | signature | Insect Swarm | Rip | Growl | Insect Swarm | - | spec control | - |
| F | melee / builder | - | Shred | - | - | Hibernate | hard CC | Rejuvenation [Rejuv] |
| G | proc | Nature's Grasp | Cower | Frenzied Regeneration | Nature's Grasp | Challenging Roar | AoE control | Healing Touch [HTouch] |
| C | escape | - | Dash | Feral Charge | - | racial | racial | Remove Curse |
| V | snare | Entangling Roots | - | - | Entangling Roots | Barkskin | emergency | Abolish Poison |
| 1 | opener | - | Prowl [CatOpener] | Enrage | - | Dire Bear Form / Bear Form | buff row | Mark of the Wild |
| 2 | main AoE | - | - | Swipe | - | Cat Form | buff row | Thorns |
| 3 | interrupt | - | Pounce | Bash | - | Travel Form | buff row | Revive |
| 4 | ground AoE | Hurricane | - | Demoralizing Roar | Hurricane | Moonkin Form / Aquatic Form | buff row | Rebirth |

### Keyboard: Restoration (own bars)

| Key | Role | Plain | Cat | Bear | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Q | main attack | Regrowth [Regrow] | Claw | Maul | Wrath | self-heal | Faerie Fire |
| E | DoT / debuff | Rejuvenation [Rejuv] | Rake | Lacerate | Moonfire | spec defensive | - |
| R | big hitter | Healing Touch [HTouch] | Ferocious Bite | Primal Bite | Starfire | burst | - |
| T | signature | Swiftmend | Rip | Growl | - | spec control | - |
| F | melee / builder | - | Shred | - | Hibernate | hard CC | Innervate |
| G | proc | Nature's Swiftness | Cower | Frenzied Regeneration | Challenging Roar | AoE control | - |
| C | escape | - | Dash | Feral Charge | racial | racial | Remove Curse |
| V | snare | Entangling Roots | - | - | Barkskin | emergency | Abolish Poison |
| 1 | opener | Wild Growth | Prowl [CatOpener] | Enrage | Dire Bear Form / Bear Form | buff row | Mark of the Wild |
| 2 | main AoE | Tranquility | - | Swipe | Cat Form | buff row | Thorns |
| 3 | interrupt | - | Pounce | Bash | Travel Form | buff row | Revive |
| 4 | ground AoE | Bloom | - | Demoralizing Roar | Aquatic Form | buff row | Rebirth |

### Controller page 1: Feral Combat

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Claw / Maul / Wrath [FormAttack] | LT Left | Shift+T |  |
| RT X | E | Rake / Lacerate / Moonfire [FormDoT] | LT Down | Shift+F | Hibernate |
| RT Right | R | Ferocious Bite / Primal Bite / Starfire [FormBig] | LT+RT A | Shift+V | Barkskin |
| RT Left | T | Rip / Growl / Insect Swarm [FormSig] | LT+RT X | Shift+G | Challenging Roar |
| LT A | F | Shred | LT+RT B | racial | racial |
| LT X | G | Cower / Frenzied Regeneration / Nature's Grasp [FormProc] | LT+RT Y | Shift+R | Innervate |
| LT Y | C | Dash / Feral Charge [FormMove] | LT+RT Up | Ctrl+Q | Faerie Fire |
| LT B | V | Entangling Roots | LT+RT Down | Ctrl+E |  |
| RT Up | 1 | Prowl / Enrage [FormOpen] | LT+RT Left | Ctrl+R |  |
| RT Y | 2 | Swipe | LT+RT Right | Ctrl+T |  |
| RT B | 3 | Pounce / Bash [FormStun] | none Up | radial / buff | Cat Form |
| RT Down | 4 | Demoralizing Roar / Hurricane [FormArea] | none Left | utility | Travel Form |
| LT Up | Shift+Q | Regrowth [Regrow] | none Right | class basic | Dire Bear Form / Bear Form |
| LT Right | Shift+E | Shifting Power / Nature's Swiftness | none Down | basic | Healing Touch [HTouch] |

### Controller page 1: Balance

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Wrath | LT Left | Shift+T |  |
| RT X | E | Moonfire | LT Down | Shift+F | Hibernate |
| RT Right | R | Starfire | LT+RT A | Shift+V | Barkskin |
| RT Left | T | Insect Swarm | LT+RT X | Shift+G | Challenging Roar |
| LT A | F |  | LT+RT B | racial | racial |
| LT X | G | Nature's Grasp | LT+RT Y | Shift+R | Innervate |
| LT Y | C |  | LT+RT Up | Ctrl+Q | Faerie Fire |
| LT B | V | Entangling Roots | LT+RT Down | Ctrl+E |  |
| RT Up | 1 |  | LT+RT Left | Ctrl+R |  |
| RT Y | 2 |  | LT+RT Right | Ctrl+T |  |
| RT B | 3 |  | none Up | radial / buff | Moonkin Form / Cat Form |
| RT Down | 4 | Hurricane | none Left | utility | Travel Form |
| LT Up | Shift+Q | Regrowth [Regrow] | none Right | class basic | Dire Bear Form / Bear Form |
| LT Right | Shift+E | Shifting Power / Nature's Swiftness | none Down | basic | Healing Touch [HTouch] |

### Controller page 1: Restoration

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Regrowth [Regrow] | LT Left | Shift+T |  |
| RT X | E | Rejuvenation [Rejuv] | LT Down | Shift+F | Hibernate |
| RT Right | R | Healing Touch [HTouch] | LT+RT A | Shift+V | Barkskin |
| RT Left | T | Swiftmend | LT+RT X | Shift+G | Challenging Roar |
| LT A | F |  | LT+RT B | racial | racial |
| LT X | G | Nature's Swiftness | LT+RT Y | Shift+R | Starfire |
| LT Y | C |  | LT+RT Up | Ctrl+Q | Faerie Fire |
| LT B | V | Entangling Roots | LT+RT Down | Ctrl+E |  |
| RT Up | 1 | Wild Growth | LT+RT Left | Ctrl+R |  |
| RT Y | 2 | Tranquility | LT+RT Right | Ctrl+T |  |
| RT B | 3 |  | none Up | radial / buff | Cat Form |
| RT Down | 4 | Bloom | none Left | utility | Travel Form |
| LT Up | Shift+Q | Wrath | none Right | class basic | Dire Bear Form / Bear Form |
| LT Right | Shift+E | Moonfire | none Down | basic |  |

### Controller page 2 (class buttons): Balance, Feral Combat

| Button | Class button |
| --- | --- |
| RT A | Revive |
| RT X | Rebirth |
| RT B | Remove Curse |
| RT Y | Abolish Poison |
| RT Down | Mark of the Wild |
| RT Left | Aquatic Form |
| RT Right | Thorns |
| LT Right | Track Humanoids |

### Controller page 2 (class buttons): Restoration

| Button | Class button |
| --- | --- |
| RT A | Revive |
| RT X | Rebirth |
| RT B | Remove Curse |
| RT Y | Abolish Poison |
| RT Down | Mark of the Wild |
| RT Left | Aquatic Form |
| RT Right | Thorns |
| LT Right | Track Humanoids |

### Macros

- **Rejuv** (combat): Drops any form, then Rejuvenation on your friendly target, or on yourself when you have none.
- **Regrow** (combat): Drops any form, then Regrowth on your friendly target, or on yourself when you have none.
- **HTouch** (combat): Drops any form, then Healing Touch on your friendly target, or on yourself when you have none.
- **CatOpener** (combat): In Cat Form: out of combat, Prowl; while prowling, Ravage your target (Shred until you know Ravage). Get behind it first.
- **FormAttack** (combat): Main attack for your form: Maul in Bear, Claw in Cat, else Wrath.
- **FormDoT** (combat): Bleed or DoT for your form: Lacerate in Bear, Rake in Cat, else Moonfire.
- **FormBig** (combat): Big hitter for your form: Primal Bite in Bear, Ferocious Bite in Cat, else Starfire.
- **FormSig** (combat): Signature for your form: Growl in Bear, Rip in Cat, else Insect Swarm.
- **FormOpen** (combat): Opener for your form: Enrage in Bear; in Cat, Prowl out of combat, then Ravage (Shred before you know it).
- **FormStun** (combat): Control for your form: Bash in Bear, Pounce in Cat (from Prowl).
- **FormArea** (combat): Area spell for your form: Demoralizing Roar in Bear, Hurricane when not in Cat.
- **FormProc** (combat): Reactive spell for your form: Frenzied Regeneration in Bear, Cower in Cat, else Nature's Grasp.
- **FormMove** (combat): Gap closer or escape for your form: Feral Charge in Bear, Dash in Cat.
