# Class layouts

Generated from `addon/Agentcraft/Layouts/*.lua` and `Macros/Data/*.lua` by `luajit dev/class-layouts.lua > dev/class-layouts.md`; regenerate after a layout change. The reasoning for each key is in the layout files' comments.

## Role guide

The keybinds are the same for every class (hard rule): plain keys = Action Bar 1, Shift = Bar 2, Ctrl = Bar 4, Alt = Bar 3 (shared item macros: HealPot Alt+Q, ManaPot Alt+E, Bandage Alt+R, Food Alt+T, Fish Alt+F, Bait Alt+G; trinkets Alt+C/V, Hearthstone Alt+4), pet bar on the mouse and Z/X. Each spec's rotation fills the slots in press-frequency order ([dev/key-roles.md](key-roles.md)):

| Key | Plain | Shift | Ctrl |
| --- | --- | --- | --- |
| Q | rotation 1 | self-heal | secondary attack / debuff |
| E | rotation 2 | spec defensive | secondary debuff |
| R | rotation 3 | burst | secondary utility attack |
| T | rotation 5 | spec control | spec utility |
| F | rotation 4 | hard CC | utility |
| G | proc | AoE control | utility |
| C | mobility | racial | utility |
| V | snare | emergency | utility |
| 1 | opener | buff row | buff / summon / create |
| 2 | main AoE | buff row | buff / summon / create |
| 3 | interrupt | buff row | buff / summon / create |
| 4 | second AoE | buff row | buff / summon / create |

- Stance pages (warrior stances, druid forms, rogue Stealth, Shadowform) keep the roles; the stance only changes which spell fills one.
- Tanks: threat priority, taunt, interrupt and AoE threat fill the rotation slots. Healers (Holy paladin, Discipline and Holy priest, Restoration shaman and druid): heals and dispel fill the rotation slots; damage moves a tier down.
- Controller page 1: the rotation on face buttons (the left thumb steers, so D-pad presses stop you): RT A X Y B = plain Q E R F, LT A X B Y = plain T G 3 2; RT D-pad = plain 1 4 C V; LT D-pad = Shift Q E T F; LT+RT = Shift V G R, the racial and Ctrl Q E R T; no trigger = radials and basics. Page 2 is utility: the class's own buttons (resurrects, buffs, portals...) plus the shared buttons below, page 3 pet and Steam Deck extras plus overflow.

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
| Q | rotation 1 | Arcane Shot [Arcane] | Mend Pet [PetCare] | self-heal | Viper Sting |
| E | rotation 2 | Serpent Sting | Bestial Wrath / Deterrence / Trueshot Aura | spec defensive | Scorpid Sting |
| R | rotation 3 | Aimed Shot | Rapid Fire [Burst] | burst | Tranquilizing Shot |
| T | rotation 5 | Summon Hawk / Sniper Shot | Intimidation / Scatter Shot | spec control | Disengage |
| F | rotation 4 | Raptor Strike [Melee] | Freezing Trap | hard CC | Scare Beast |
| G | proc | Mongoose Bite | Frost Trap | AoE control | Flare |
| C | mobility | Wing Clip | racial | racial | Distracting Shot |
| V | snare | Concussive Shot | Feign Death [FD] | emergency | Eyes of the Beast |
| 1 | opener | Hunter's Mark [Opener] | Aspect of the Hawk | buff row | Aspect of the Beast |
| 2 | main AoE | Multi-Shot | Aspect of the Monkey | buff row | Aspect of the Wild |
| 3 | interrupt | Explosive Trap / Immolation Trap | Aspect of the Cheetah | buff row | Feed Pet |
| 4 | second AoE | Volley | Aspect of the Pack | buff row | Beast Lore |

### Keyboard: Survival (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Arcane Shot [Arcane] | Mend Pet [PetCare] | self-heal | Viper Sting |
| E | rotation 2 | Serpent Sting | Bestial Wrath / Deterrence / Trueshot Aura | spec defensive | Scorpid Sting |
| R | rotation 3 | Strider Kick | Rapid Fire [Burst] | burst | Tranquilizing Shot |
| T | rotation 5 | Summon Hawk | Counterattack | spec control | Disengage |
| F | rotation 4 | Raptor Strike [Melee] | Freezing Trap | hard CC | Frost Trap |
| G | proc | Mongoose Bite | Concussive Shot | AoE control | Aimed Shot |
| C | mobility | Wing Clip | racial | racial | Scare Beast |
| V | snare | Explosive Trap | Feign Death [FD] | emergency | Intimidation / Scatter Shot |
| 1 | opener | Hunter's Mark [Opener] | Aspect of the Hawk | buff row | Aspect of the Monkey |
| 2 | main AoE | Multi-Shot | Aspect of the Beast | buff row | Aspect of the Wild |
| 3 | interrupt | Immolation Trap | Aspect of the Cheetah | buff row | Feed Pet |
| 4 | second AoE | Volley | Aspect of the Pack | buff row | Beast Lore |

### Controller page 1: Beast Mastery, Marksmanship

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Arcane Shot [Arcane] | LT Left | Shift+T | Intimidation / Scatter Shot |
| RT X | E | Serpent Sting | LT Down | Shift+F | Freezing Trap |
| RT Y | R | Aimed Shot | LT+RT A | Shift+V | Feign Death [FD] |
| RT B | F | Raptor Strike [Melee] | LT+RT X | Shift+G | Frost Trap |
| LT A | T | Summon Hawk / Sniper Shot | LT+RT B | racial | racial |
| LT X | G | Mongoose Bite | LT+RT Y | Shift+R | Rapid Fire [Burst] |
| LT B | 3 | Explosive Trap / Immolation Trap | LT+RT Up | Ctrl+Q | Viper Sting |
| LT Y | 2 | Multi-Shot | LT+RT Down | Ctrl+E | Scorpid Sting |
| RT Up | 1 | Hunter's Mark [Opener] | LT+RT Left | Ctrl+R | Tranquilizing Shot |
| RT Down | 4 | Volley | LT+RT Right | Ctrl+T | Disengage |
| RT Left | C | Wing Clip | none Up | radial / buff | Aspect of the Hawk (radial) |
| RT Right | V | Concussive Shot | none Left | utility | Track Beasts (radial) |
| LT Up | Shift+Q | Mend Pet [PetCare] | none Right | class basic | Feed Pet |
| LT Right | Shift+E | Bestial Wrath / Deterrence / Trueshot Aura | none Down | basic |  |

### Controller page 1: Survival

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Arcane Shot [Arcane] | LT Left | Shift+T | Counterattack |
| RT X | E | Serpent Sting | LT Down | Shift+F | Freezing Trap |
| RT Y | R | Strider Kick | LT+RT A | Shift+V | Feign Death [FD] |
| RT B | F | Raptor Strike [Melee] | LT+RT X | Shift+G | Concussive Shot |
| LT A | T | Summon Hawk | LT+RT B | racial | racial |
| LT X | G | Mongoose Bite | LT+RT Y | Shift+R | Rapid Fire [Burst] |
| LT B | 3 | Immolation Trap | LT+RT Up | Ctrl+Q | Viper Sting |
| LT Y | 2 | Multi-Shot | LT+RT Down | Ctrl+E | Scorpid Sting |
| RT Up | 1 | Hunter's Mark [Opener] | LT+RT Left | Ctrl+R | Tranquilizing Shot |
| RT Down | 4 | Volley | LT+RT Right | Ctrl+T | Disengage |
| RT Left | C | Wing Clip | none Up | radial / buff | Aspect of the Hawk (radial) |
| RT Right | V | Explosive Trap | none Left | utility | Track Beasts (radial) |
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
- **Scatter** (combat): Calls your pet back, then Scatter Shot on your enemy target, so the pet's hits don't break the disorient before your trap (Marksmanship talent, level 30). [WH]
- **Deterrence** (combat): Panic button: Aspect of the Monkey (never toggled off if it's already on) and Deterrence in one press, both raising your dodge (Survival talent, level 20). [WH]
- **Auto <ability>** (pet): controller autocast toggles for Growl, Claw, Bite, Dash, Dive, Charge, Prowl, Cower, Screech, Furious Howl, Lightning Breath, Scorpid Poison, Thunderstomp, Shell Shield.

## Warrior

### Keyboard: Protection (leveling)

| Key | Role | Plain | Battle | Defensive | Berserker | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Sunder Armor [Sunder] | Sunder Armor [Sunder] | Sunder Armor [Sunder] | Sunder Armor [Sunder] | Victory Rush | self-heal | Challenging Shout |
| E | rotation 2 | Shield Block | Execute | Shield Block | Execute | Last Stand | spec defensive | Retaliation [Retaliation] |
| R | rotation 3 | Shield Slam / Bloodthirst / Rend [ShieldSlam] | Shield Slam / Bloodthirst / Rend [ShieldSlam] | Shield Slam / Bloodthirst / Rend [ShieldSlam] | Shield Slam / Bloodthirst / Rend [ShieldSlam] | Bloodrage | burst | Recklessness |
| T | rotation 5 | Heroic Strike | Heroic Strike | Heroic Strike | Heroic Strike | Concussion Blow | spec control | Hamstring |
| F | rotation 4 | Taunt [Taunt] | Mocking Blow | Taunt | - | Disarm | hard CC | Slam |
| G | proc | Revenge [Revenge] | Overpower | Revenge | Berserker Rage | Intimidating Shout | AoE control | Death Wish |
| C | mobility | Intercept [Intercept] | Intercept [Intercept] | Intercept [Intercept] | Intercept | racial | racial | - |
| V | snare | Demoralizing Shout | Demoralizing Shout | Demoralizing Shout | Demoralizing Shout | Shield Wall [ShieldWall] | emergency | - |
| 1 | opener | Charge [TankCharge] | Charge [TankCharge] | Charge [TankCharge] | Charge [TankCharge] | Battle Stance | buff row | - |
| 2 | main AoE | Thunder Clap | Thunder Clap | Thunder Clap | Whirlwind | Defensive Stance | buff row | - |
| 3 | interrupt | Shield Bash / Pummel [BashPummel] | Shield Bash | Shield Bash | Pummel | Berserker Stance | buff row | - |
| 4 | second AoE | Cleave | Cleave | Cleave | Cleave | Battle Shout | buff row | - |

### Keyboard: Arms (own bars)

| Key | Role | Plain | Battle | Defensive | Berserker | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Mortal Strike / Thunder Clap [MortalStrike] | Mortal Strike / Thunder Clap [MortalStrike] | Mortal Strike / Thunder Clap [MortalStrike] | Mortal Strike / Thunder Clap [MortalStrike] | Victory Rush | self-heal | Bloodrage |
| E | rotation 2 | Rend | Rend | Rend | - | Retaliation [Retaliation] | spec defensive | Taunt |
| R | rotation 3 | Slam / Sunder Armor | Slam / Sunder Armor | Slam / Sunder Armor | Slam / Sunder Armor | Recklessness | burst | Hamstring |
| T | rotation 5 | Execute | Execute | - | Execute | Disarm | spec control | Challenging Shout |
| F | rotation 4 | Heroic Strike | Heroic Strike | Heroic Strike | Heroic Strike | Intimidating Shout | hard CC | Mocking Blow [MockingBlow] |
| G | proc | Overpower [Overpower] | Overpower | Revenge | Berserker Rage | Demoralizing Shout | AoE control | - |
| C | mobility | Intercept [Intercept] | Intercept [Intercept] | Intercept [Intercept] | Intercept | racial | racial | Reckless Swings |
| V | snare | Spearing Strike | Spearing Strike | Spearing Strike | Spearing Strike | Shield Wall [ShieldWall] | emergency | - |
| 1 | opener | Charge [BattleCharge] | Charge [BattleCharge] | Charge [BattleCharge] | [ChargeIntercept] | Battle Stance | buff row | - |
| 2 | main AoE | Cleave | Cleave | Cleave | Whirlwind | Defensive Stance | buff row | - |
| 3 | interrupt | Pummel / Shield Bash [BashPummel] | Pummel / Shield Bash [BashPummel] | Pummel / Shield Bash [BashPummel] | Pummel | Berserker Stance | buff row | - |
| 4 | second AoE | Sweeping Strikes | Sweeping Strikes | - | - | Battle Shout | buff row | - |

### Keyboard: Fury (own bars)

| Key | Role | Plain | Battle | Defensive | Berserker | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Bloodthirst / Rend [Bloodthirst] | Bloodthirst / Rend [Bloodthirst] | Bloodthirst / Rend [Bloodthirst] | Bloodthirst / Rend [Bloodthirst] | Victory Rush | self-heal | Retaliation [Retaliation] |
| E | rotation 2 | Whirlwind / Thunder Clap [Whirlwind] | Whirlwind / Thunder Clap [Whirlwind] | Whirlwind / Thunder Clap [Whirlwind] | Whirlwind / Thunder Clap | Bloodrage | spec defensive | Taunt |
| R | rotation 3 | Heroic Strike | Heroic Strike | Heroic Strike | Heroic Strike | Death Wish | burst | Recklessness |
| T | rotation 5 | Execute | Execute | - | Execute | Disarm | spec control | Challenging Shout |
| F | rotation 4 | Sunder Armor | Sunder Armor | Sunder Armor | Sunder Armor | Intimidating Shout | hard CC | Mocking Blow [MockingBlow] |
| G | proc | Overpower [Overpower] | Overpower | Revenge | Berserker Rage | Demoralizing Shout | AoE control | Shield Wall [ShieldWall] |
| C | mobility | Intercept [Intercept] | Intercept [Intercept] | Intercept [Intercept] | Intercept | racial | racial | Spearing Strike |
| V | snare | Hamstring | Hamstring | - | Hamstring | Piercing Howl | emergency | - |
| 1 | opener | Charge [ChargeIntercept] | Charge [ChargeIntercept] | Charge [ChargeIntercept] | Charge [ChargeIntercept] | Battle Stance | buff row | - |
| 2 | main AoE | Cleave | Cleave | Cleave | Cleave | Defensive Stance | buff row | - |
| 3 | interrupt | Pummel / Shield Bash [BashPummel] | Pummel / Shield Bash [BashPummel] | Pummel / Shield Bash [BashPummel] | Pummel | Berserker Stance | buff row | - |
| 4 | second AoE | Reckless Swings | Reckless Swings | Reckless Swings | Reckless Swings | Battle Shout | buff row | - |

### Controller page 1: Protection

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Sunder Armor [Sunder] | LT Left | Shift+T | Concussion Blow |
| RT X | E | Shield Block | LT Down | Shift+F | Disarm |
| RT Y | R | Shield Slam / Bloodthirst / Rend [ShieldSlam] | LT+RT A | Shift+V | Shield Wall [ShieldWall] |
| RT B | F | Taunt [Taunt] | LT+RT X | Shift+G | Intimidating Shout |
| LT A | T | Heroic Strike | LT+RT B | racial | racial |
| LT X | G | Revenge [Revenge] | LT+RT Y | Shift+R | Bloodrage |
| LT B | 3 | Shield Bash / Pummel [BashPummel] | LT+RT Up | Ctrl+Q | Challenging Shout |
| LT Y | 2 | Thunder Clap | LT+RT Down | Ctrl+E | Retaliation [Retaliation] |
| RT Up | 1 | Charge [TankCharge] | LT+RT Left | Ctrl+R | Recklessness |
| RT Down | 4 | Cleave | LT+RT Right | Ctrl+T | Hamstring |
| RT Left | C | Intercept [Intercept] | none Up | radial / buff | Battle Stance |
| RT Right | V | Demoralizing Shout | none Left | utility | Defensive Stance |
| LT Up | Shift+Q | Victory Rush | none Right | class basic | Berserker Stance |
| LT Right | Shift+E | Last Stand | none Down | basic | Battle Shout |

### Controller page 1: Arms

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Mortal Strike / Thunder Clap [MortalStrike] | LT Left | Shift+T | Disarm |
| RT X | E | Rend | LT Down | Shift+F | Intimidating Shout |
| RT Y | R | Slam / Sunder Armor | LT+RT A | Shift+V | Shield Wall [ShieldWall] |
| RT B | F | Heroic Strike | LT+RT X | Shift+G | Demoralizing Shout |
| LT A | T | Execute | LT+RT B | racial | racial |
| LT X | G | Overpower [Overpower] | LT+RT Y | Shift+R | Recklessness |
| LT B | 3 | Pummel / Shield Bash [BashPummel] | LT+RT Up | Ctrl+Q | Bloodrage |
| LT Y | 2 | Cleave | LT+RT Down | Ctrl+E | Taunt |
| RT Up | 1 | Charge [BattleCharge] | LT+RT Left | Ctrl+R | Whirlwind [Whirlwind] |
| RT Down | 4 | Sweeping Strikes | LT+RT Right | Ctrl+T | Challenging Shout |
| RT Left | C | Intercept [Intercept] | none Up | radial / buff | Battle Stance |
| RT Right | V | Spearing Strike | none Left | utility | Defensive Stance |
| LT Up | Shift+Q | Victory Rush | none Right | class basic | Berserker Stance |
| LT Right | Shift+E | Retaliation [Retaliation] | none Down | basic | Battle Shout |

### Controller page 1: Fury

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Bloodthirst / Rend [Bloodthirst] | LT Left | Shift+T | Disarm |
| RT X | E | Whirlwind / Thunder Clap [Whirlwind] | LT Down | Shift+F | Intimidating Shout |
| RT Y | R | Heroic Strike | LT+RT A | Shift+V | Piercing Howl |
| RT B | F | Sunder Armor | LT+RT X | Shift+G | Demoralizing Shout |
| LT A | T | Execute | LT+RT B | racial | racial |
| LT X | G | Overpower [Overpower] | LT+RT Y | Shift+R | Death Wish |
| LT B | 3 | Pummel / Shield Bash [BashPummel] | LT+RT Up | Ctrl+Q | Retaliation [Retaliation] |
| LT Y | 2 | Cleave | LT+RT Down | Ctrl+E | Taunt |
| RT Up | 1 | Charge [ChargeIntercept] | LT+RT Left | Ctrl+R | Berserker Rage [BerserkerRage] |
| RT Down | 4 | Reckless Swings | LT+RT Right | Ctrl+T | Challenging Shout |
| RT Left | C | Intercept [Intercept] | none Up | radial / buff | Battle Stance |
| RT Right | V | Hamstring | none Left | utility | Defensive Stance |
| LT Up | Shift+Q | Victory Rush | none Right | class basic | Berserker Stance |
| LT Right | Shift+E | Bloodrage | none Down | basic | Battle Shout |

### Controller page 2 (class buttons): Arms, Fury, Protection

Only the shared buttons.

### Macros

- **TankCharge** (combat): Protection pull: out of combat, Battle Stance then Charge; once in combat, back to Defensive Stance. Starts your attack. [M]
- **ChargeIntercept** (combat): Arms and Fury gap closer: Charge out of combat (Battle Stance first), Intercept in combat (Berserker Stance first). [M, adapted]
- **BattleCharge** (combat): Arms pull: Battle Stance if you're not in it, Charge, and start your attack (Arms stays in Battle Stance, unlike TankCharge). [D]
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
- **Sunder** (combat): Protection filler: starts your attack, then Sunder Armor on your enemy target, so a target swap never leaves you standing idle. [WH-T]
- **ShieldSlam** (combat): Starts your attack, then Shield Slam on your enemy target (Protection talent, level 40). [WH-T]
- **Taunt** (combat): Defensive Stance if you're not in it, then Taunt on your enemy target: one taunt button from any stance. [WH-T, WH-F]
- **MortalStrike** (combat): Drops Blessing of Protection, starts your attack, then Mortal Strike on your enemy target (Arms talent, level 40). [WH-D]
- **Bloodthirst** (combat): Drops Blessing of Protection, starts your attack, then Bloodthirst on your enemy target (Fury talent, level 40): Wowhead's own example. [WH-D]

## Paladin

### Keyboard: Retribution (leveling)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Holy Strike [HolyStrike] | Flash of Light [SmartFlash] | self-heal | Turn Undead |
| E | rotation 2 | Judgement | Divine Shield / Divine Protection | spec defensive | Blessing of Sacrifice |
| R | rotation 3 | Seal of Righteousness | Divine Favor | burst | Divine Intervention |
| T | rotation 5 | Holy Shock / Seal of Command [ShockAny] | Cleanse / Purify | spec control | - |
| F | rotation 4 | Exorcism [ExoJudge] | Repentance [Repent] | hard CC | Redemption |
| G | proc | Hammer of Wrath [HammerJudge] | Blessing of Protection | AoE control | - |
| C | mobility | Blessing of Freedom | racial | racial | - |
| V | snare | Seal of Justice | Lay on Hands [LayOnHands] | emergency | - |
| 1 | opener | Seal of the Crusader | Seal of Wisdom | buff row | Devotion Aura |
| 2 | main AoE | Consecration | Seal of Light | buff row | Retribution Aura |
| 3 | interrupt | Hammer of Justice [HoJ] | Seal of Fury | buff row | Concentration Aura |
| 4 | second AoE | Holy Wrath | Holy Light [SmartLight] | buff row | - |

### Keyboard: Holy (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Flash of Light [SmartFlash] | Holy Strike | self-heal | Turn Undead |
| E | rotation 2 | Judgement | Divine Shield / Divine Protection | spec defensive | Blessing of Sacrifice |
| R | rotation 3 | Holy Light [SmartLight] | Exorcism [ExoJudge] | burst | Divine Intervention |
| T | rotation 5 | Cleanse / Purify | Seal of Righteousness | spec control | - |
| F | rotation 4 | Holy Shock [SmartShock] | Blessing of Protection | hard CC | Redemption |
| G | proc | Divine Favor | Consecration | AoE control | - |
| C | mobility | Blessing of Freedom | racial | racial | - |
| V | snare | Seal of Justice | Lay on Hands [LayOnHands] | emergency | - |
| 1 | opener | Seal of Light | Seal of Wisdom | buff row | Devotion Aura |
| 2 | main AoE | Light's Vigil | Seal of the Crusader | buff row | Retribution Aura |
| 3 | interrupt | Hammer of Justice [HoJ] | Oath of Light | buff row | Concentration Aura |
| 4 | second AoE | Voice of Truth | Hammer of Wrath [HammerJudge] | buff row | - |

### Keyboard: Protection (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Holy Strike [HolyStrike] | Flash of Light [SmartFlash] | self-heal | Turn Undead |
| E | rotation 2 | Judgement | Templar's Bulwark | spec defensive | Blessing of Sacrifice |
| R | rotation 3 | Holy Shield / Holy Shock | Swift Judgement | burst | Divine Intervention |
| T | rotation 5 | Seal of Fury / Seal of Righteousness | Cleanse / Purify | spec control | - |
| F | rotation 4 | Exorcism [ExoJudge] | Divine Shield / Divine Protection | hard CC | Redemption |
| G | proc | Hammer of Wrath [HammerJudge] | Blessing of Protection | AoE control | - |
| C | mobility | Blessing of Freedom | racial | racial | - |
| V | snare | Seal of Justice | Lay on Hands [LayOnHands] | emergency | - |
| 1 | opener | Seal of the Crusader | Righteous Fury | buff row | Devotion Aura |
| 2 | main AoE | Consecration | Seal of Wisdom | buff row | Retribution Aura |
| 3 | interrupt | Hammer of Justice [HoJ] | Seal of Light | buff row | Concentration Aura |
| 4 | second AoE | Holy Wrath | Holy Light [SmartLight] | buff row | - |

### Controller page 1: Retribution

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Holy Strike [HolyStrike] | LT Left | Shift+T | Cleanse / Purify |
| RT X | E | Judgement | LT Down | Shift+F | Repentance [Repent] |
| RT Y | R | Seal of Righteousness | LT+RT A | Shift+V | Lay on Hands [LayOnHands] |
| RT B | F | Exorcism [ExoJudge] | LT+RT X | Shift+G | Blessing of Protection |
| LT A | T | Holy Shock / Seal of Command [ShockAny] | LT+RT B | racial | racial |
| LT X | G | Hammer of Wrath [HammerJudge] | LT+RT Y | Shift+R | Divine Favor |
| LT B | 3 | Hammer of Justice [HoJ] | LT+RT Up | Ctrl+Q | Turn Undead |
| LT Y | 2 | Consecration | LT+RT Down | Ctrl+E | Blessing of Sacrifice |
| RT Up | 1 | Seal of the Crusader | LT+RT Left | Ctrl+R | Divine Intervention |
| RT Down | 4 | Holy Wrath | LT+RT Right | Ctrl+T | Holy Light [SmartLight] |
| RT Left | C | Blessing of Freedom | none Up | radial / buff | Devotion Aura |
| RT Right | V | Seal of Justice | none Left | utility | Concentration Aura |
| LT Up | Shift+Q | Flash of Light [SmartFlash] | none Right | class basic | Retribution Aura |
| LT Right | Shift+E | Divine Shield / Divine Protection | none Down | basic | Seal of Wisdom |

### Controller page 1: Holy

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Flash of Light [SmartFlash] | LT Left | Shift+T | Seal of Righteousness |
| RT X | E | Judgement | LT Down | Shift+F | Blessing of Protection |
| RT Y | R | Holy Light [SmartLight] | LT+RT A | Shift+V | Lay on Hands [LayOnHands] |
| RT B | F | Holy Shock [SmartShock] | LT+RT X | Shift+G | Consecration |
| LT A | T | Cleanse / Purify | LT+RT B | racial | racial |
| LT X | G | Divine Favor | LT+RT Y | Shift+R | Exorcism [ExoJudge] |
| LT B | 3 | Hammer of Justice [HoJ] | LT+RT Up | Ctrl+Q | Turn Undead |
| LT Y | 2 | Light's Vigil | LT+RT Down | Ctrl+E | Blessing of Sacrifice |
| RT Up | 1 | Seal of Light | LT+RT Left | Ctrl+R | Divine Intervention |
| RT Down | 4 | Voice of Truth | LT+RT Right | Ctrl+T | Hammer of Wrath [HammerJudge] |
| RT Left | C | Blessing of Freedom | none Up | radial / buff | Devotion Aura |
| RT Right | V | Seal of Justice | none Left | utility | Concentration Aura |
| LT Up | Shift+Q | Holy Strike | none Right | class basic | Oath of Light |
| LT Right | Shift+E | Divine Shield / Divine Protection | none Down | basic | Seal of Wisdom |

### Controller page 1: Protection

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Holy Strike [HolyStrike] | LT Left | Shift+T | Cleanse / Purify |
| RT X | E | Judgement | LT Down | Shift+F | Divine Shield / Divine Protection |
| RT Y | R | Holy Shield / Holy Shock | LT+RT A | Shift+V | Lay on Hands [LayOnHands] |
| RT B | F | Exorcism [ExoJudge] | LT+RT X | Shift+G | Blessing of Protection |
| LT A | T | Seal of Fury / Seal of Righteousness | LT+RT B | racial | racial |
| LT X | G | Hammer of Wrath [HammerJudge] | LT+RT Y | Shift+R | Swift Judgement |
| LT B | 3 | Hammer of Justice [HoJ] | LT+RT Up | Ctrl+Q | Turn Undead |
| LT Y | 2 | Consecration | LT+RT Down | Ctrl+E | Blessing of Sacrifice |
| RT Up | 1 | Seal of the Crusader | LT+RT Left | Ctrl+R | Divine Intervention |
| RT Down | 4 | Holy Wrath | LT+RT Right | Ctrl+T | Holy Light [SmartLight] |
| RT Left | C | Blessing of Freedom | none Up | radial / buff | Devotion Aura |
| RT Right | V | Seal of Justice | none Left | utility | Concentration Aura |
| LT Up | Shift+Q | Flash of Light [SmartFlash] | none Right | class basic | Retribution Aura |
| LT Right | Shift+E | Templar's Bulwark | none Down | basic | Righteous Fury |

### Controller page 2 (class buttons): Holy, Protection, Retribution

| Button | Class button |
| --- | --- |
| RT A | Redemption |
| RT X | Blessing of Might |
| RT B | Blessing of Wisdom |
| RT Y | Blessing of Kings |
| RT Down | overflow |
| RT Left | overflow |
| RT Right | overflow |

### Macros

- **ExoJudge** (combat): Starts melee on your enemy target, Judges if Judgement is ready, then casts Exorcism (Undead and Demons only).
- **HammerJudge** (combat): Judges if Judgement is ready, then Hammer of Wrath (targets below 20% health) in one press.
- **Repent** (combat): Repentance and Judgement in one press (Retribution talent).
- **SmartFlash** (combat): Flash of Light on your target if it's a living friend, otherwise on yourself, without dropping your enemy target.
- **SmartLight** (combat): Holy Light on your target if it's a living friend, otherwise on yourself, without dropping your enemy target.
- **SmartShock** (combat): Holy Shock heals your target if it's a living friend, otherwise yourself: a healer's instant heal that never hits the enemy you have targeted.
- **HolyStrike** (combat): Starts your attack, then Holy Strike on your enemy target, so a target swap never leaves you standing idle. [WH-D]
- **ShockAny** (combat): Holy Shock damages your enemy target, heals a friendly target, and heals yourself when you have neither. [WH-H]
- **HoJ** (combat): Stops the spell you're casting and stuns your enemy target with Hammer of Justice at once. [WH-H, WH-R]
- **LayOnHands** (combat): Stops your cast, then Lay on Hands on your target if it's a living friend, otherwise on yourself. [WH-H, WH-R]

## Rogue

### Keyboard: Assassination

| Key | Role | Plain | Stealth | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Mutilate / Hemorrhage / Sinister Strike [MutiAttack] | Mutilate / Hemorrhage / Sinister Strike [MutiAttack] | - | self-heal | - |
| E | rotation 2 | Shank / Backstab | Garrote [PickGarrote] | Evasion | spec defensive | Expose Armor |
| R | rotation 3 | Eviscerate | Ambush [Premed] | Adrenaline Rush / Cold Blood / Preparation [Blades] | burst | - |
| T | rotation 5 | Rupture | - | Kidney Shot | spec control | - |
| F | rotation 4 | Slice and Dice | - | Sap | hard CC | Pick Pocket |
| G | proc | Riposte / Ghostly Strike | - | Blind | AoE control | Distract |
| C | mobility | Sprint | Sprint | racial | racial | Pick Lock |
| V | snare | Gouge | - | Vanish [Poof] | emergency | Disarm Trap |
| 1 | opener | Throw / Shoot Bow / Shoot Crossbow / Shoot Gun | Cheap Shot | Stealth [StealthOn] | buff row | - |
| 2 | main AoE | Blade Flurry | Blade Flurry | - | buff row | - |
| 3 | interrupt | Kick | Kick | - | buff row | - |
| 4 | second AoE | Feint | - | - | buff row | - |

### Keyboard: Combat (leveling) (own bars)

| Key | Role | Plain | Stealth | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Sinister Strike [Strike] | Mutilate / Hemorrhage / Sinister Strike [MutiAttack] | - | self-heal | - |
| E | rotation 2 | Shank / Backstab | Garrote [PickGarrote] | Evasion | spec defensive | Expose Armor |
| R | rotation 3 | Eviscerate | Ambush [Premed] | Adrenaline Rush / Preparation [Blades] | burst | Cold Blood |
| T | rotation 5 | Rupture | - | Kidney Shot | spec control | - |
| F | rotation 4 | Slice and Dice | - | Sap | hard CC | Pick Pocket |
| G | proc | Riposte | - | Blind | AoE control | Distract |
| C | mobility | Sprint | Sprint | racial | racial | Pick Lock |
| V | snare | Gouge | - | Vanish [Poof] | emergency | Disarm Trap |
| 1 | opener | Throw / Shoot Bow / Shoot Crossbow / Shoot Gun | Cheap Shot | Stealth [StealthOn] | buff row | - |
| 2 | main AoE | Blade Flurry | Blade Flurry | - | buff row | - |
| 3 | interrupt | Kick | Kick | - | buff row | - |
| 4 | second AoE | Feint | - | - | buff row | - |

### Keyboard: Subtlety (own bars)

| Key | Role | Plain | Stealth | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Hemorrhage / Sinister Strike [HemoAttack] | Hemorrhage / Sinister Strike [HemoAttack] | - | self-heal | - |
| E | rotation 2 | Shank / Backstab | Cheap Shot | Evasion | spec defensive | Expose Armor |
| R | rotation 3 | Death Mark / Eviscerate | Ambush [Premed] | Adrenaline Rush / Cold Blood / Preparation [Blades] | burst | - |
| T | rotation 5 | Rupture | - | Kidney Shot | spec control | - |
| F | rotation 4 | Slice and Dice | - | Sap | hard CC | Pick Pocket |
| G | proc | Ghostly Strike | Ghostly Strike | Blind | AoE control | Distract |
| C | mobility | Sprint | Sprint | racial | racial | Pick Lock |
| V | snare | Gouge | - | Vanish [Poof] | emergency | Disarm Trap |
| 1 | opener | Garrote [PickGarrote] | Garrote [PickGarrote] | Stealth [StealthOn] | buff row | Throw / Shoot Bow / Shoot Crossbow / Shoot Gun |
| 2 | main AoE | Premeditation | Premeditation | - | buff row | - |
| 3 | interrupt | Kick | Kick | - | buff row | - |
| 4 | second AoE | Feint | - | - | buff row | - |

### Controller page 1: Combat

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Sinister Strike [Strike] | LT Left | Shift+T | Kidney Shot |
| RT X | E | Shank / Backstab | LT Down | Shift+F | Sap |
| RT Y | R | Eviscerate | LT+RT A | Shift+V | Vanish [Poof] |
| RT B | F | Slice and Dice | LT+RT X | Shift+G | Blind |
| LT A | T | Rupture | LT+RT B | racial | racial |
| LT X | G | Riposte | LT+RT Y | Shift+R | Adrenaline Rush / Preparation [Blades] |
| LT B | 3 | Kick | LT+RT Up | Ctrl+Q |  |
| LT Y | 2 | Blade Flurry | LT+RT Down | Ctrl+E | Expose Armor |
| RT Up | 1 | Cheap Shot | LT+RT Left | Ctrl+R | Feint |
| RT Down | 4 | Garrote [PickGarrote] | LT+RT Right | Ctrl+T | Cold Blood |
| RT Left | C | Sprint | none Up | radial / buff | Stealth [StealthOn] |
| RT Right | V | Gouge | none Left | utility | Pick Pocket |
| LT Up | Shift+Q | Ambush [Premed] | none Right | class basic | Throw / Shoot Bow / Shoot Crossbow / Shoot Gun |
| LT Right | Shift+E | Evasion | none Down | basic | Distract |

### Controller page 1: Assassination

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Mutilate / Sinister Strike [MutiAttack] | LT Left | Shift+T | Kidney Shot |
| RT X | E | Shank / Backstab | LT Down | Shift+F | Sap |
| RT Y | R | Eviscerate | LT+RT A | Shift+V | Vanish [Poof] |
| RT B | F | Slice and Dice | LT+RT X | Shift+G | Blind |
| LT A | T | Rupture | LT+RT B | racial | racial |
| LT X | G | Riposte / Ghostly Strike | LT+RT Y | Shift+R | Adrenaline Rush / Cold Blood / Preparation [Blades] |
| LT B | 3 | Kick | LT+RT Up | Ctrl+Q |  |
| LT Y | 2 | Cheap Shot | LT+RT Down | Ctrl+E | Expose Armor |
| RT Up | 1 | Ambush [Premed] | LT+RT Left | Ctrl+R | Feint |
| RT Down | 4 | Garrote [PickGarrote] | LT+RT Right | Ctrl+T |  |
| RT Left | C | Sprint | none Up | radial / buff | Stealth [StealthOn] |
| RT Right | V | Gouge | none Left | utility | Pick Pocket |
| LT Up | Shift+Q |  | none Right | class basic | Throw / Shoot Bow / Shoot Crossbow / Shoot Gun |
| LT Right | Shift+E | Evasion | none Down | basic | Distract |

### Controller page 1: Subtlety

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Hemorrhage / Sinister Strike [HemoAttack] | LT Left | Shift+T | Kidney Shot |
| RT X | E | Shank / Backstab | LT Down | Shift+F | Sap |
| RT Y | R | Death Mark / Eviscerate | LT+RT A | Shift+V | Vanish [Poof] |
| RT B | F | Slice and Dice | LT+RT X | Shift+G | Blind |
| LT A | T | Rupture | LT+RT B | racial | racial |
| LT X | G | Ghostly Strike | LT+RT Y | Shift+R | Adrenaline Rush / Cold Blood / Preparation [Blades] |
| LT B | 3 | Kick | LT+RT Up | Ctrl+Q |  |
| LT Y | 2 | Premeditation | LT+RT Down | Ctrl+E | Expose Armor |
| RT Up | 1 | Garrote [PickGarrote] | LT+RT Left | Ctrl+R | Feint |
| RT Down | 4 | Ambush [Premed] | LT+RT Right | Ctrl+T |  |
| RT Left | C | Sprint | none Up | radial / buff | Stealth [StealthOn] |
| RT Right | V | Gouge | none Left | utility | Pick Pocket |
| LT Up | Shift+Q | Cheap Shot | none Right | class basic | Throw / Shoot Bow / Shoot Crossbow / Shoot Gun |
| LT Right | Shift+E | Evasion | none Down | basic | Distract |

### Controller page 2 (class buttons): Assassination, Combat, Subtlety

| Button | Class button |
| --- | --- |
| RT A | Pick Lock |
| RT X | Disarm Trap |

### Macros

- **Strike** (combat): Starts melee and uses Riposte when it lights up after a parry, else Sinister Strike. Riposte is skipped until you have it.
- **MutiAttack** (combat): Starts melee, then Mutilate: a new target gets auto attacks without a separate click.
- **HemoAttack** (combat): Starts melee, then Hemorrhage: a new target gets auto attacks without a separate click.
- **Premed** (combat): From Stealth: Premeditation (2 combo points, no global cooldown) then Ambush. Premeditation is skipped until you have it.
- **Blades** (combat): Both Combat cooldowns at once: Adrenaline Rush and Blade Flurry. Adrenaline Rush is skipped until you have it.
- **Poof** (combat): A clean Vanish: stops your auto attack first, so the next swing doesn't pull you out of Stealth.
- **StealthOn** (combat): Stealth you can press twice: it never cancels Stealth once you're in it, and stops your auto attack first.
- **PickGarrote** (combat): From Stealth: Pick Pocket (free loot, no global cooldown) then Garrote. In combat (Subtlety, after Ghostly Strike) Pick Pocket just fails and Garrote goes out.

## Priest

### Keyboard: Shadow (leveling)

| Key | Role | Plain | Shadowform | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Mind Flay / Smite [Flay] | Mind Flay / Smite [Flay] | Flash Heal / Lesser Heal [PriestFlash] | self-heal | Holy Fire |
| E | rotation 2 | Shadow Word: Pain | Shadow Word: Pain | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash | spec defensive | Mana Burn |
| R | rotation 3 | Mind Blast [MindPull] | Mind Blast [MindPull] | Power Infusion / Inner Focus [Empower] | burst | Mind Soothe |
| T | rotation 5 | Vampiric Embrace | Vampiric Embrace | Mind Control | spec control | Mind Vision |
| F | rotation 4 | Shoot | Shoot | Shackle Undead | hard CC | Renew [PriestRenew] |
| G | proc | Shadow Word: Death | Shadow Word: Death | Psychic Scream | AoE control | Greater Heal / Heal |
| C | mobility | Fade | Fade | racial | racial | Abolish Disease / Cure Disease |
| V | snare | - | - | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan | emergency | Resurrection |
| 1 | opener | Power Word: Shield [PriestShield] | Power Word: Shield [PriestShield] | Power Word: Fortitude | buff row | Divine Spirit |
| 2 | main AoE | Devouring Plague | Devouring Plague | Inner Fire | buff row | Shadow Protection |
| 3 | interrupt | Silence / Dispel Magic | Silence / Dispel Magic | Shadowform [ShadowOn] | buff row | Prayer of Fortitude |
| 4 | second AoE | Holy Nova | - | Fear Ward | buff row | Levitate |

### Keyboard: Discipline (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Heal / Lesser Heal [PriestHeal] | Smite | self-heal | Devouring Plague |
| E | rotation 2 | Renew [PriestRenew] | Shadow Word: Pain | spec defensive | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash |
| R | rotation 3 | Penance / Binding Heal | Mind Blast | burst | Mind Soothe |
| T | rotation 5 | Dispel Magic [DispelMagic] | Holy Fire | spec control | Mind Vision |
| F | rotation 4 | Flash Heal [PriestFlash] | Shoot | hard CC | Shackle Undead |
| G | proc | Prayer of Mending | Psychic Scream | AoE control | Mind Control |
| C | mobility | Fade | racial | racial | Shadow Word: Death |
| V | snare | Greater Heal | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan | emergency | Resurrection |
| 1 | opener | Power Word: Shield [PriestShield] | Power Word: Fortitude | buff row | Divine Spirit |
| 2 | main AoE | Prayer of Healing | Inner Fire | buff row | Shadow Protection |
| 3 | interrupt | Abolish Disease / Cure Disease | Power Infusion / Inner Focus [Empower] | buff row | Prayer of Fortitude |
| 4 | second AoE | Holy Nova | Fear Ward | buff row | Levitate |

### Keyboard: Holy (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Heal / Lesser Heal [PriestHeal] | Smite | self-heal | Devouring Plague |
| E | rotation 2 | Renew [PriestRenew] | Shadow Word: Pain | spec defensive | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash |
| R | rotation 3 | Penance / Binding Heal | Mind Blast | burst | Mind Soothe |
| T | rotation 5 | Dispel Magic [DispelMagic] | Holy Fire | spec control | Mind Vision |
| F | rotation 4 | Flash Heal [PriestFlash] | Shoot | hard CC | Shackle Undead |
| G | proc | Prayer of Mending | Psychic Scream | AoE control | Mind Control |
| C | mobility | Fade | racial | racial | Shadow Word: Death |
| V | snare | Greater Heal | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan | emergency | Resurrection |
| 1 | opener | Power Word: Shield [PriestShield] | Power Word: Fortitude | buff row | Divine Spirit |
| 2 | main AoE | Prayer of Healing | Inner Fire | buff row | Shadow Protection |
| 3 | interrupt | Abolish Disease / Cure Disease | Power Infusion / Inner Focus [Empower] | buff row | Prayer of Fortitude |
| 4 | second AoE | Holy Nova | Fear Ward | buff row | Levitate |

### Controller page 1: Shadow

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Mind Flay / Smite [Flay] | LT Left | Shift+T | Mind Control |
| RT X | E | Shadow Word: Pain | LT Down | Shift+F | Shackle Undead |
| RT Y | R | Mind Blast [MindPull] | LT+RT A | Shift+V | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan |
| RT B | F | Shoot | LT+RT X | Shift+G | Psychic Scream |
| LT A | T | Vampiric Embrace | LT+RT B | racial | racial |
| LT X | G | Shadow Word: Death | LT+RT Y | Shift+R | Power Infusion / Inner Focus [Empower] |
| LT B | 3 | Silence / Dispel Magic | LT+RT Up | Ctrl+Q | Holy Fire |
| LT Y | 2 | Devouring Plague | LT+RT Down | Ctrl+E | Mana Burn |
| RT Up | 1 | Power Word: Shield [PriestShield] | LT+RT Left | Ctrl+R | Mind Soothe |
| RT Down | 4 | Holy Nova | LT+RT Right | Ctrl+T | Mind Vision |
| RT Left | C | Fade | none Up | radial / buff | Power Word: Fortitude |
| RT Right | V |  | none Left | utility | Inner Fire |
| LT Up | Shift+Q | Flash Heal / Lesser Heal [PriestFlash] | none Right | class basic | Shadowform [ShadowOn] |
| LT Right | Shift+E | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash | none Down | basic | Renew [PriestRenew] |

### Controller page 1: Discipline

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Heal / Lesser Heal [PriestHeal] | LT Left | Shift+T | Holy Fire |
| RT X | E | Renew [PriestRenew] | LT Down | Shift+F | Shoot |
| RT Y | R | Power Word: Shield [PriestShield] | LT+RT A | Shift+V | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan |
| RT B | F | Flash Heal [PriestFlash] | LT+RT X | Shift+G | Psychic Scream |
| LT A | T | Dispel Magic [DispelMagic] | LT+RT B | racial | racial |
| LT X | G | Prayer of Mending | LT+RT Y | Shift+R | Mind Blast |
| LT B | 3 | Abolish Disease / Cure Disease | LT+RT Up | Ctrl+Q | Devouring Plague |
| LT Y | 2 | Prayer of Healing | LT+RT Down | Ctrl+E | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash |
| RT Up | 1 | Penance / Binding Heal | LT+RT Left | Ctrl+R | Mind Soothe |
| RT Down | 4 | Holy Nova | LT+RT Right | Ctrl+T | Mind Vision |
| RT Left | C | Fade | none Up | radial / buff | Power Word: Fortitude |
| RT Right | V | Greater Heal | none Left | utility | Inner Fire |
| LT Up | Shift+Q | Smite | none Right | class basic | Power Infusion / Inner Focus [Empower] |
| LT Right | Shift+E | Shadow Word: Pain | none Down | basic | Shackle Undead |

### Controller page 1: Holy

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Heal / Lesser Heal [PriestHeal] | LT Left | Shift+T | Holy Fire |
| RT X | E | Renew [PriestRenew] | LT Down | Shift+F | Shoot |
| RT Y | R | Power Word: Shield [PriestShield] | LT+RT A | Shift+V | Dark Sacrifice / Shadowguard / Elune's Grace / Feedback / Contingency Plan |
| RT B | F | Flash Heal [PriestFlash] | LT+RT X | Shift+G | Psychic Scream |
| LT A | T | Dispel Magic [DispelMagic] | LT+RT B | racial | racial |
| LT X | G | Prayer of Mending | LT+RT Y | Shift+R | Mind Blast |
| LT B | 3 | Abolish Disease / Cure Disease | LT+RT Up | Ctrl+Q | Devouring Plague |
| LT Y | 2 | Prayer of Healing | LT+RT Down | Ctrl+E | Desperate Prayer / Touch of Weakness / Hex of Weakness / Starshards / Divine Grace / Confounding Flash |
| RT Up | 1 | Penance / Binding Heal | LT+RT Left | Ctrl+R | Mind Soothe |
| RT Down | 4 | Holy Nova | LT+RT Right | Ctrl+T | Mind Vision |
| RT Left | C | Fade | none Up | radial / buff | Power Word: Fortitude |
| RT Right | V | Greater Heal | none Left | utility | Inner Fire |
| LT Up | Shift+Q | Smite | none Right | class basic | Power Infusion / Inner Focus [Empower] |
| LT Right | Shift+E | Shadow Word: Pain | none Down | basic | Shackle Undead |

### Controller page 2 (class buttons): Discipline, Holy, Shadow

| Button | Class button |
| --- | --- |
| RT A | Resurrection |
| RT X | Levitate |
| RT Y | Divine Spirit |
| RT Down | Fear Ward |
| RT Left | Shadow Protection |
| RT Right | Prayer of Fortitude |

### Macros

- **Flay** (combat): Mind Flay that never clips itself: pressing it again while Mind Flay channels does nothing, so you can hold or mash the button.
- **MindPull** (combat): Mind Blast that also pulls: drops a dead or friendly target, picks the nearest enemy if you have none, then Mind Blast.
- **Empower** (combat): Every cooldown at once: Inner Focus, both trinkets, Berserking, then Power Infusion on your friendly target (else on you). Anything you don't have is skipped.
- **PriestHeal** (combat): Heal on your target if it's a living friend, else on yourself, so you never have to drop an enemy target to heal.
- **PriestRenew** (combat): Renew on your target if it's a living friend, else on yourself.
- **PriestFlash** (combat): Flash Heal on your target if it's a living friend, else on yourself: Shadow heals itself without losing its enemy target.
- **PriestShield** (combat): Power Word: Shield on your target if it's a living friend, else on yourself: shield the tank, or yourself while you keep the enemy targeted.
- **DispelMagic** (combat): Dispel Magic on your target, friend (removes a debuff) or enemy (removes a buff); with no living target, on yourself.
- **ShadowOn** (combat): Shadowform you can press twice: it never cancels the form once you're in it, and stops a cast in progress first.

## Shaman

### Keyboard: Elemental

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Lightning Bolt | Healing Wave [WaveHeal] | self-heal | Chain Heal |
| E | rotation 2 | Flame Shock | Stoneskin Totem | spec defensive | Cure Poison |
| R | rotation 3 | Stormstrike / Chain Lightning | Rage of the Farseer / Lightning Mastery [ShamanBurst] | burst | Cure Disease |
| T | rotation 5 | Water Shield / Lightning Shield | Grounding Totem | spec control | Totemic Call |
| F | rotation 4 | Searing Totem | - | hard CC | Strength of Earth Totem |
| G | proc | Purge | Earthbind Totem | AoE control | Healing Stream Totem |
| C | mobility | Ghost Wolf | racial | racial | Mana Spring Totem |
| V | snare | Frost Shock | Nature's Swiftness / Lesser Healing Wave [NSWave] | emergency | Windfury Totem |
| 1 | opener | Call of the Elements | Rockbiter Weapon | buff row | Grace of Air Totem |
| 2 | main AoE | Fire Nova | Flametongue Weapon | buff row | Call of the Ancestors |
| 3 | interrupt | Earth Shock [ShockKick] | Frostbrand Weapon | buff row | Call of the Spirits |
| 4 | second AoE | Magma Totem [MagmaNova] | Windfury Weapon | buff row | Totemic Recall |

### Keyboard: Enhancement (leveling) (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Lightning Bolt | Healing Wave [WaveHeal] | self-heal | Chain Heal |
| E | rotation 2 | Flame Shock | Stoneskin Totem | spec defensive | Cure Poison |
| R | rotation 3 | Stormstrike / Chain Lightning [StormAttack] | Rage of the Farseer / Lightning Mastery [ShamanBurst] | burst | Cure Disease |
| T | rotation 5 | Water Shield / Lightning Shield | Grounding Totem | spec control | Totemic Call |
| F | rotation 4 | Magma Totem / Searing Totem [MagmaNova] | - | hard CC | Strength of Earth Totem |
| G | proc | Purge | Earthbind Totem | AoE control | Healing Stream Totem |
| C | mobility | Ghost Wolf | racial | racial | Mana Spring Totem |
| V | snare | Frost Shock | Nature's Swiftness / Lesser Healing Wave [NSWave] | emergency | Windfury Totem |
| 1 | opener | Call of the Elements | Rockbiter Weapon | buff row | Grace of Air Totem |
| 2 | main AoE | Fire Nova | Flametongue Weapon | buff row | Call of the Ancestors |
| 3 | interrupt | Earth Shock [ShockKick] | Frostbrand Weapon | buff row | Call of the Spirits |
| 4 | second AoE | Stoneclaw Totem | Windfury Weapon | buff row | Totemic Recall |

### Keyboard: Restoration (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Healing Wave [WaveHeal] | Lightning Bolt | self-heal | Grounding Totem |
| E | rotation 2 | Riptide [RiptideHeal] | Flame Shock | spec defensive | Magma Totem [MagmaNova] |
| R | rotation 3 | Chain Heal [ChainHeal] | Mana Tide Totem | burst | Fire Nova |
| T | rotation 5 | Cure Poison | Searing Totem | spec control | Totemic Call |
| F | rotation 4 | Lesser Healing Wave [LesserWave] | - | hard CC | Strength of Earth Totem |
| G | proc | Cure Disease | Earthbind Totem | AoE control | Mana Spring Totem |
| C | mobility | Ghost Wolf | racial | racial | Stoneskin Totem |
| V | snare | Frost Shock | Nature's Swiftness [NSWave] | emergency | Windfury Totem |
| 1 | opener | Call of the Elements | Water Shield / Lightning Shield | buff row | Call of the Ancestors |
| 2 | main AoE | Healing Stream Totem | Rockbiter Weapon | buff row | Call of the Spirits |
| 3 | interrupt | Earth Shock [ShockKick] | Flametongue Weapon | buff row | Totemic Recall |
| 4 | second AoE | Purge | Windfury Weapon | buff row | Tremor Totem |

### Controller page 1: Elemental

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Lightning Bolt | LT Left | Shift+T | Grounding Totem |
| RT X | E | Flame Shock | LT Down | Shift+F |  |
| RT Y | R | Stormstrike / Chain Lightning | LT+RT A | Shift+V | Nature's Swiftness / Lesser Healing Wave [NSWave] |
| RT B | F | Searing Totem | LT+RT X | Shift+G | Earthbind Totem |
| LT A | T | Water Shield / Lightning Shield | LT+RT B | racial | racial |
| LT X | G | Purge | LT+RT Y | Shift+R | Rage of the Farseer / Lightning Mastery [ShamanBurst] |
| LT B | 3 | Earth Shock [ShockKick] | LT+RT Up | Ctrl+Q | Chain Heal |
| LT Y | 2 | Fire Nova | LT+RT Down | Ctrl+E | Cure Poison |
| RT Up | 1 | Call of the Elements | LT+RT Left | Ctrl+R | Cure Disease |
| RT Down | 4 | Magma Totem [MagmaNova] | LT+RT Right | Ctrl+T | Totemic Call |
| RT Left | C | Ghost Wolf | none Up | radial / buff | Windfury Weapon |
| RT Right | V | Frost Shock | none Left | utility | Rockbiter Weapon |
| LT Up | Shift+Q | Healing Wave [WaveHeal] | none Right | class basic | Totemic Recall |
| LT Right | Shift+E | Stoneskin Totem | none Down | basic | Flametongue Weapon |

### Controller page 1: Enhancement

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Lightning Bolt | LT Left | Shift+T | Grounding Totem |
| RT X | E | Flame Shock | LT Down | Shift+F |  |
| RT Y | R | Stormstrike / Chain Lightning [StormAttack] | LT+RT A | Shift+V | Nature's Swiftness / Lesser Healing Wave [NSWave] |
| RT B | F | Magma Totem / Searing Totem [MagmaNova] | LT+RT X | Shift+G | Earthbind Totem |
| LT A | T | Water Shield / Lightning Shield | LT+RT B | racial | racial |
| LT X | G | Purge | LT+RT Y | Shift+R | Rage of the Farseer / Lightning Mastery [ShamanBurst] |
| LT B | 3 | Earth Shock [ShockKick] | LT+RT Up | Ctrl+Q | Chain Heal |
| LT Y | 2 | Fire Nova | LT+RT Down | Ctrl+E | Cure Poison |
| RT Up | 1 | Call of the Elements | LT+RT Left | Ctrl+R | Cure Disease |
| RT Down | 4 | Stoneclaw Totem | LT+RT Right | Ctrl+T | Totemic Call |
| RT Left | C | Ghost Wolf | none Up | radial / buff | Windfury Weapon |
| RT Right | V | Frost Shock | none Left | utility | Rockbiter Weapon |
| LT Up | Shift+Q | Healing Wave [WaveHeal] | none Right | class basic | Totemic Recall |
| LT Right | Shift+E | Stoneskin Totem | none Down | basic | Flametongue Weapon |

### Controller page 1: Restoration

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Healing Wave [WaveHeal] | LT Left | Shift+T | Searing Totem |
| RT X | E | Riptide [RiptideHeal] | LT Down | Shift+F | Grounding Totem |
| RT Y | R | Chain Heal [ChainHeal] | LT+RT A | Shift+V | Nature's Swiftness [NSWave] |
| RT B | F | Lesser Healing Wave [LesserWave] | LT+RT X | Shift+G | Earthbind Totem |
| LT A | T | Cure Poison | LT+RT B | racial | racial |
| LT X | G | Cure Disease | LT+RT Y | Shift+R | Mana Tide Totem |
| LT B | 3 | Earth Shock [ShockKick] | LT+RT Up | Ctrl+Q | Magma Totem [MagmaNova] |
| LT Y | 2 | Healing Stream Totem | LT+RT Down | Ctrl+E | Fire Nova |
| RT Up | 1 | Call of the Elements | LT+RT Left | Ctrl+R | Mana Spring Totem |
| RT Down | 4 | Purge | LT+RT Right | Ctrl+T | Totemic Call |
| RT Left | C | Ghost Wolf | none Up | radial / buff | Water Shield / Lightning Shield |
| RT Right | V | Frost Shock | none Left | utility | Rockbiter Weapon |
| LT Up | Shift+Q | Lightning Bolt | none Right | class basic | Totemic Recall |
| LT Right | Shift+E | Flame Shock | none Down | basic | Flametongue Weapon |

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
- **StormAttack** (combat): Starts melee, then Stormstrike: a new target gets auto attacks without a separate click.
- **MagmaNova** (combat): AoE on one key: drops Magma Totem, then each press after detonates it with Fire Nova; starts over out of combat or after 20 sec (the totem's life).
- **ShamanBurst** (combat): Every damage cooldown at once: both trinkets, Berserking, then Rage of the Farseer (Enhancement) or Lightning Mastery (Elemental). Anything you don't have is skipped.
- **BoltOrWave** (combat): One button for both: Lightning Bolt on an enemy, Healing Wave on a friend, and Healing Wave on yourself with no target.
- **WaveHeal** (combat): Healing Wave on your target if it's a living friend, else on yourself, so you never have to drop an enemy target to heal.
- **ChainHeal** (combat): Chain Heal starting on your target if it's a living friend, else on yourself.
- **LesserWave** (combat): Lesser Healing Wave (the fast emergency heal) on your target if it's a living friend, else on yourself.
- **RiptideHeal** (combat): Riptide on your target if it's a living friend, else on yourself.
- **NSWave** (combat): Emergency heal: Nature's Swiftness, then an instant Healing Wave on your friendly target, else on yourself.
- **WFShield** (combat): Both Enhancement buffs on one key: Lightning Shield on the first press, Windfury Weapon on the next; starts over after 2 sec.

## Mage

### Keyboard: Frost (leveling)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Frostbolt | Evocation | self-heal | - |
| E | rotation 2 | Cone of Cold / Fire Blast | Mana Shield | spec defensive | - |
| R | rotation 3 | Frost Nova | Cold Snap | burst | [CounterFocus] |
| T | rotation 5 | Frostfire Bolt / Fireball | [PolyFocus] | spec control | Fire Ward |
| F | rotation 4 | Arcane Missiles | Polymorph | hard CC | Dampen Magic |
| G | proc | Ice Lance [BlockLance] | - | AoE control | Amplify Magic |
| C | mobility | Blink | racial | racial | Slow Fall |
| V | snare | Flamestrike | Ice Block [BlockBreak] | emergency | Remove Lesser Curse [Decurse] |
| 1 | opener | Ice Barrier | Ice Armor / Frost Armor [ArmorSwap] | buff row | Arcane Brilliance |
| 2 | main AoE | Arcane Explosion | Mage Armor | buff row | Conjure Water [ConjureBoth] |
| 3 | interrupt | Counterspell [Counter] | Arcane Intellect | buff row | Conjure Food |
| 4 | second AoE | Blizzard | Frost Ward | buff row | Conjure Mana Ruby / Conjure Mana Citrine / Conjure Mana Jade / Conjure Mana Agate |

### Keyboard: Arcane (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Arcane Blast / Fireball | Evocation | self-heal | Blizzard |
| E | rotation 2 | Arcane Missiles | Mana Shield | spec defensive | Presence of Mind |
| R | rotation 3 | Arcane Wrath | Arcane Power / Combustion | burst | [CounterFocus] |
| T | rotation 5 | Scorch | [PolyFocus] | spec control | Fire Ward |
| F | rotation 4 | Fire Blast | Polymorph | hard CC | Dampen Magic |
| G | proc | Pyroblast | Cone of Cold | AoE control | Amplify Magic |
| C | mobility | Blink | racial | racial | Slow Fall |
| V | snare | Frost Nova | Ice Block [BlockBreak] | emergency | Remove Lesser Curse [Decurse] |
| 1 | opener | Frostbolt | Ice Armor / Frost Armor [ArmorSwap] | buff row | Arcane Brilliance |
| 2 | main AoE | Arcane Explosion | Mage Armor | buff row | Conjure Water [ConjureBoth] |
| 3 | interrupt | Counterspell [Counter] | Arcane Intellect | buff row | Conjure Food |
| 4 | second AoE | Flamestrike | Frost Ward | buff row | Conjure Mana Ruby / Conjure Mana Citrine / Conjure Mana Jade / Conjure Mana Agate |

### Keyboard: Fire (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Fireball | Evocation | self-heal | Blizzard |
| E | rotation 2 | Scorch / Frostbolt | Mana Shield | spec defensive | - |
| R | rotation 3 | Fire Blast | Combustion / Arcane Power | burst | [CounterFocus] |
| T | rotation 5 | Blast Wave | [PolyFocus] | spec control | Fire Ward |
| F | rotation 4 | Arcane Missiles | Polymorph | hard CC | Dampen Magic |
| G | proc | Pyroblast | Cone of Cold | AoE control | Amplify Magic |
| C | mobility | Blink | racial | racial | Slow Fall |
| V | snare | Frost Nova | Ice Block [BlockBreak] | emergency | Remove Lesser Curse [Decurse] |
| 1 | opener | Frostfire Bolt | Ice Armor / Frost Armor [ArmorSwap] | buff row | Arcane Brilliance |
| 2 | main AoE | Arcane Explosion | Mage Armor | buff row | Conjure Water [ConjureBoth] |
| 3 | interrupt | Counterspell [Counter] | Arcane Intellect | buff row | Conjure Food |
| 4 | second AoE | Flamestrike | Frost Ward | buff row | Conjure Mana Ruby / Conjure Mana Citrine / Conjure Mana Jade / Conjure Mana Agate |

### Controller page 1: Frost

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Frostbolt | LT Left | Shift+T | [PolyFocus] |
| RT X | E | Cone of Cold / Fire Blast | LT Down | Shift+F | Polymorph |
| RT Y | R | Frost Nova | LT+RT A | Shift+V | Ice Block [BlockBreak] |
| RT B | F | Arcane Missiles | LT+RT X | Shift+G |  |
| LT A | T | Frostfire Bolt / Fireball | LT+RT B | racial | racial |
| LT X | G | Ice Lance [BlockLance] | LT+RT Y | Shift+R | Cold Snap |
| LT B | 3 | Counterspell [Counter] | LT+RT Up | Ctrl+Q |  |
| LT Y | 2 | Arcane Explosion | LT+RT Down | Ctrl+E | Frost Ward |
| RT Up | 1 | Ice Barrier | LT+RT Left | Ctrl+R | [CounterFocus] |
| RT Down | 4 | Blizzard | LT+RT Right | Ctrl+T | Fire Ward |
| RT Left | C | Blink | none Up | radial / buff | Arcane Intellect |
| RT Right | V | Flamestrike | none Left | utility | Remove Lesser Curse [Decurse] |
| LT Up | Shift+Q | Evocation | none Right | class basic |  |
| LT Right | Shift+E | Mana Shield | none Down | basic |  |

### Controller page 1: Arcane

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Arcane Blast / Fireball | LT Left | Shift+T | [PolyFocus] |
| RT X | E | Arcane Missiles | LT Down | Shift+F | Polymorph |
| RT Y | R | Arcane Wrath | LT+RT A | Shift+V | Ice Block [BlockBreak] |
| RT B | F | Fire Blast | LT+RT X | Shift+G | Cone of Cold |
| LT A | T | Scorch | LT+RT B | racial | racial |
| LT X | G | Pyroblast | LT+RT Y | Shift+R | Arcane Power / Combustion |
| LT B | 3 | Counterspell [Counter] | LT+RT Up | Ctrl+Q | Blizzard |
| LT Y | 2 | Arcane Explosion | LT+RT Down | Ctrl+E | Presence of Mind |
| RT Up | 1 | Frostbolt | LT+RT Left | Ctrl+R | [CounterFocus] |
| RT Down | 4 | Flamestrike | LT+RT Right | Ctrl+T | Fire Ward |
| RT Left | C | Blink | none Up | radial / buff | Arcane Intellect |
| RT Right | V | Frost Nova | none Left | utility | Remove Lesser Curse [Decurse] |
| LT Up | Shift+Q | Evocation | none Right | class basic |  |
| LT Right | Shift+E | Mana Shield | none Down | basic |  |

### Controller page 1: Fire

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Fireball | LT Left | Shift+T | [PolyFocus] |
| RT X | E | Scorch / Frostbolt | LT Down | Shift+F | Polymorph |
| RT Y | R | Fire Blast | LT+RT A | Shift+V | Ice Block [BlockBreak] |
| RT B | F | Arcane Missiles | LT+RT X | Shift+G | Cone of Cold |
| LT A | T | Blast Wave | LT+RT B | racial | racial |
| LT X | G | Pyroblast | LT+RT Y | Shift+R | Combustion / Arcane Power |
| LT B | 3 | Counterspell [Counter] | LT+RT Up | Ctrl+Q | Blizzard |
| LT Y | 2 | Arcane Explosion | LT+RT Down | Ctrl+E | Frost Ward |
| RT Up | 1 | Frostfire Bolt | LT+RT Left | Ctrl+R | [CounterFocus] |
| RT Down | 4 | Flamestrike | LT+RT Right | Ctrl+T | Fire Ward |
| RT Left | C | Blink | none Up | radial / buff | Arcane Intellect |
| RT Right | V | Frost Nova | none Left | utility | Remove Lesser Curse [Decurse] |
| LT Up | Shift+Q | Evocation | none Right | class basic |  |
| LT Right | Shift+E | Mana Shield | none Down | basic |  |

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

- **Counter** (combat): Stops your own cast and Counterspells your target at once.
- **PoMPyro** (combat): Presence of Mind, then an instant Pyroblast on your target; a normal Pyroblast while Presence of Mind cools down.
- **PolyFocus** (combat): Polymorphs your focus without changing target. Alternates ranks, because a sheep can't be refreshed with the same or a lower rank; resets after 15 seconds.
- **CounterFocus** (combat): Stops your own cast and Counterspells your focus without changing target.
- **BlockBreak** (combat): Ice Block; press again while in the block to leave it early.
- **BlockLance** (combat): Ice Lance that first breaks your Ice Block, so you can strike the moment you leave it. Outside the block it is a plain Ice Lance.
- **Decurse** (combat): Remove Lesser Curse on your friendly target, or on yourself when you have none.
- **ArmorSwap** (utility): Each press switches between Ice Armor and Mage Armor.
- **ConjureBoth** (utility): Conjures water, then food on the next press; starts over with water after 4 seconds idle.

## Warlock

### Keyboard: Affliction (leveling), Demonology

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Drain Life [DrainLife] | Health Funnel | self-heal | Curse of the Elements |
| E | rotation 2 | Corruption | Amplify Curse / Fel Domination / Bane of Havoc | spec defensive | Curse of Recklessness |
| R | rotation 3 | Bane of Agony | Soul Fire / Inferno | burst | Curse of Tongues |
| T | rotation 5 | Siphon Life / Searing Pain | Drain Soul [DrainSoul] | spec control | Bane of Doom |
| F | rotation 4 | Wrack / Immolate [Wrack] | Fear | hard CC | Create Spellstone / Create Firestone |
| G | proc | Life Tap | Howl of Terror | AoE control | Eye of Kilrogg |
| C | mobility | Death Coil | racial | racial | Soul Link |
| V | snare | Shoot | Shadow Ward | emergency | Demonic Sacrifice |
| 1 | opener | Shadow Bolt | Demon Armor / Demon Skin | buff row | Summon Imp |
| 2 | main AoE | Hellfire | Create Healthstone | buff row | Summon Voidwalker |
| 3 | interrupt | [PetSpecial] | Create Soulstone | buff row | Summon Succubus / Summon Incubus |
| 4 | second AoE | Rain of Fire | Unending Breath | buff row | Summon Felhunter |

### Keyboard: Destruction (own bars)

| Key | Role | Plain | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Incinerate / Shadow Bolt | Drain Life [DrainLife] | self-heal | Curse of the Elements |
| E | rotation 2 | Immolate | Amplify Curse | spec defensive | Curse of Recklessness |
| R | rotation 3 | Conflagrate | Soul Fire / Inferno | burst | Curse of Tongues |
| T | rotation 5 | Shadowburn | Drain Soul [DrainSoul] | spec control | Bane of Doom |
| F | rotation 4 | Corruption | Fear | hard CC | Create Spellstone / Create Firestone |
| G | proc | Life Tap | Howl of Terror | AoE control | Eye of Kilrogg |
| C | mobility | Death Coil | racial | racial | Health Funnel |
| V | snare | Shoot | Shadow Ward | emergency | Rain of Fire |
| 1 | opener | Bane of Agony | Demon Armor / Demon Skin | buff row | Summon Imp |
| 2 | main AoE | Hellfire | Create Healthstone | buff row | Summon Voidwalker |
| 3 | interrupt | [PetSpecial] | Create Soulstone | buff row | Summon Succubus / Summon Incubus |
| 4 | second AoE | Bane of Havoc | Unending Breath | buff row | Summon Felhunter |

### Controller page 1: Affliction, Demonology

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Drain Life [DrainLife] | LT Left | Shift+T | Drain Soul [DrainSoul] |
| RT X | E | Corruption | LT Down | Shift+F | Fear |
| RT Y | R | Bane of Agony | LT+RT A | Shift+V | Shadow Ward |
| RT B | F | Wrack / Immolate [Wrack] | LT+RT X | Shift+G | Howl of Terror |
| LT A | T | Siphon Life / Searing Pain | LT+RT B | racial | racial |
| LT X | G | Life Tap | LT+RT Y | Shift+R | Soul Fire / Inferno |
| LT B | 3 | [PetSpecial] | LT+RT Up | Ctrl+Q | Curse of the Elements |
| LT Y | 2 | Hellfire | LT+RT Down | Ctrl+E | Curse of Recklessness |
| RT Up | 1 | Shadow Bolt | LT+RT Left | Ctrl+R | Curse of Tongues |
| RT Down | 4 | Rain of Fire | LT+RT Right | Ctrl+T | Bane of Doom |
| RT Left | C | Death Coil | none Up | radial / buff | Demon Armor / Demon Skin |
| RT Right | V | Shoot | none Left | utility | Soul Link |
| LT Up | Shift+Q | Health Funnel | none Right | class basic |  |
| LT Right | Shift+E | Amplify Curse / Fel Domination / Bane of Havoc | none Down | basic | Demonic Sacrifice |

### Controller page 1: Destruction

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Incinerate / Shadow Bolt | LT Left | Shift+T | Drain Soul [DrainSoul] |
| RT X | E | Immolate | LT Down | Shift+F | Fear |
| RT Y | R | Conflagrate | LT+RT A | Shift+V | Shadow Ward |
| RT B | F | Corruption | LT+RT X | Shift+G | Howl of Terror |
| LT A | T | Shadowburn | LT+RT B | racial | racial |
| LT X | G | Life Tap | LT+RT Y | Shift+R | Soul Fire / Inferno |
| LT B | 3 | [PetSpecial] | LT+RT Up | Ctrl+Q | Curse of the Elements |
| LT Y | 2 | Hellfire | LT+RT Down | Ctrl+E | Curse of Recklessness |
| RT Up | 1 | Bane of Agony | LT+RT Left | Ctrl+R | Curse of Tongues |
| RT Down | 4 | Bane of Havoc | LT+RT Right | Ctrl+T | Bane of Doom |
| RT Left | C | Death Coil | none Up | radial / buff | Demon Armor / Demon Skin |
| RT Right | V | Shoot | none Left | utility | Health Funnel |
| LT Up | Shift+Q | Drain Life [DrainLife] | none Right | class basic | Rain of Fire |
| LT Right | Shift+E | Amplify Curse | none Down | basic |  |

### Controller page 2 (class buttons): Affliction, Demonology, Destruction

| Button | Class button |
| --- | --- |
| RT A | Create Healthstone |
| RT X | Create Soulstone |
| RT B | Unending Breath |
| RT Y | Eye of Kilrogg |
| RT Down | overflow |
| RT Left | Create Spellstone / Create Firestone |
| RT Right | Ritual of Summoning |

### Macros

- **DrainLife** (combat): Drain Life that never restarts the channel when you press it again mid-drain.
- **DrainSoul** (combat): Drain Soul that never restarts the channel when you press it again, so a shard tick isn't lost.
- **Wrack** (combat): Wrack (Affliction filler) that never restarts the channel when you press it again.
- **FearFocus** (combat): Fears your focus without changing target, or your target when you have no hostile focus.
- **HavocFocus** (combat): Bane of Havoc on your focus (the second target) without changing target, or on your target when you have no hostile focus.
- **PetSpecial** (pet): Your demon's control spell on one button: Spell Lock (Felhunter), Sacrifice (Voidwalker) or Seduction (Sayaad).
- **SelfDevour** (pet): Your Felhunter casts Devour Magic on you, whatever you have targeted.
- **Auto <ability>** (pet): controller autocast toggles for Firebolt, Torment, Suffering, Consume Shadows, Lash of Pain, Soothing Kiss, Devour Magic, Tainted Blood.

## Druid

### Keyboard: Balance, Feral Combat (leveling)

| Key | Role | Plain | Cat | Bear | Moonkin | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Wrath | Claw | Maul | Wrath | Regrowth [Regrow] | self-heal | - |
| E | rotation 2 | Moonfire | Rake | Lacerate | Moonfire | Barkskin | spec defensive | Cower |
| R | rotation 3 | Starfire | Rip | Primal Bite | Starfire | Innervate [Innerv] | burst | - |
| T | rotation 5 | Entangling Roots | Ferocious Bite | Demoralizing Roar | Entangling Roots | Rejuvenation [Rejuv] | spec control | - |
| F | rotation 4 | Insect Swarm | Shred | Growl | Insect Swarm | Hibernate | hard CC | Soothe Animal |
| G | proc | Nature's Grasp | Shifting Power | Frenzied Regeneration | Nature's Grasp | - | AoE control | - |
| C | mobility | - | Dash [CatDash] | Feral Charge [BearCharge] | - | racial | racial | Remove Curse [RemoveCurse] |
| V | snare | Faerie Fire | Faerie Fire | Faerie Fire | Faerie Fire | Healing Touch [HTouch] | emergency | Abolish Poison |
| 1 | opener | - | Prowl [CatOpener] | Enrage | - | Dire Bear Form / Bear Form | buff row | Mark of the Wild |
| 2 | main AoE | Hurricane | Ravage | Swipe | Hurricane | Cat Form | buff row | Thorns |
| 3 | interrupt | - | Pounce | Bash | - | Travel Form | buff row | Revive |
| 4 | second AoE | - | - | Challenging Roar | - | Moonkin Form / Aquatic Form | buff row | Rebirth |

### Keyboard: Restoration (own bars)

| Key | Role | Plain | Cat | Bear | Shift | Shift role | Ctrl |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Q | rotation 1 | Rejuvenation [Rejuv] | Claw | Maul | Wrath | self-heal | Nature's Grasp |
| E | rotation 2 | Regrowth [Regrow] | Rake | Lacerate | Moonfire | spec defensive | Cower |
| R | rotation 3 | Healing Touch [HTouch] | Rip | Primal Bite | Starfire | burst | - |
| T | rotation 5 | Remove Curse [RemoveCurse] | Ferocious Bite | Demoralizing Roar | Insect Swarm | spec control | - |
| F | rotation 4 | Swiftmend | Shred | Growl | Hibernate | hard CC | Soothe Animal |
| G | proc | Nature's Swiftness [NSTouch] | Shifting Power | Frenzied Regeneration | Innervate [Innerv] | AoE control | - |
| C | mobility | - | Dash [CatDash] | Feral Charge [BearCharge] | racial | racial | - |
| V | snare | Entangling Roots | Faerie Fire | Faerie Fire | Barkskin | emergency | - |
| 1 | opener | - | Prowl [CatOpener] | Enrage | Dire Bear Form / Bear Form | buff row | Mark of the Wild |
| 2 | main AoE | Wild Growth | Ravage | Swipe | Cat Form | buff row | Thorns |
| 3 | interrupt | Abolish Poison | Pounce | Bash | Travel Form | buff row | Revive |
| 4 | second AoE | Tranquility | - | Challenging Roar | Aquatic Form | buff row | Rebirth |

### Controller page 1: Feral Combat

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Claw / Wrath | LT Left | Shift+T | Frenzied Regeneration |
| RT X | E | Rake / Moonfire | LT Down | Shift+F | Bash |
| RT Y | R | Rip | LT+RT A | Shift+V | Growl |
| RT B | F | Shred | LT+RT X | Shift+G | Shifting Power |
| LT A | T | Maul | LT+RT B | racial | racial |
| LT X | G | Primal Bite | LT+RT Y | Shift+R | Ferocious Bite |
| LT B | 3 | Lacerate | LT+RT Up | Ctrl+Q | Healing Touch [HTouch] |
| LT Y | 2 | Swipe | LT+RT Down | Ctrl+E | Challenging Roar |
| RT Up | 1 | Prowl [CatOpener] | LT+RT Left | Ctrl+R | Enrage |
| RT Down | 4 | Demoralizing Roar | LT+RT Right | Ctrl+T | Innervate [Innerv] |
| RT Left | C | Dash [CatDash] | none Up | radial / buff | Cat Form |
| RT Right | V | Faerie Fire | none Left | utility | Travel Form |
| LT Up | Shift+Q | Regrowth [Regrow] | none Right | class basic | Dire Bear Form / Bear Form |
| LT Right | Shift+E | Barkskin | none Down | basic | Rejuvenation [Rejuv] |

### Controller page 1: Balance

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Wrath | LT Left | Shift+T | Rejuvenation [Rejuv] |
| RT X | E | Moonfire | LT Down | Shift+F | Hibernate |
| RT Y | R | Starfire | LT+RT A | Shift+V | Healing Touch [HTouch] |
| RT B | F | Insect Swarm | LT+RT X | Shift+G |  |
| LT A | T | Entangling Roots | LT+RT B | racial | racial |
| LT X | G | Nature's Grasp | LT+RT Y | Shift+R | Innervate [Innerv] |
| LT B | 3 |  | LT+RT Up | Ctrl+Q |  |
| LT Y | 2 | Hurricane | LT+RT Down | Ctrl+E | Cower |
| RT Up | 1 |  | LT+RT Left | Ctrl+R |  |
| RT Down | 4 |  | LT+RT Right | Ctrl+T |  |
| RT Left | C |  | none Up | radial / buff | Cat Form |
| RT Right | V | Faerie Fire | none Left | utility | Travel Form |
| LT Up | Shift+Q | Regrowth [Regrow] | none Right | class basic | Dire Bear Form / Bear Form |
| LT Right | Shift+E | Barkskin | none Down | basic | Moonkin Form |

### Controller page 1: Restoration

| Button | Mirrors | Spell | Button | Mirrors | Spell |
| --- | --- | --- | --- | --- | --- |
| RT A | Q | Rejuvenation [Rejuv] | LT Left | Shift+T | Insect Swarm |
| RT X | E | Regrowth [Regrow] | LT Down | Shift+F | Hibernate |
| RT Y | R | Healing Touch [HTouch] | LT+RT A | Shift+V | Barkskin |
| RT B | F | Swiftmend | LT+RT X | Shift+G | Innervate [Innerv] |
| LT A | T | Remove Curse [RemoveCurse] | LT+RT B | racial | racial |
| LT X | G | Nature's Swiftness [NSTouch] | LT+RT Y | Shift+R | Starfire |
| LT B | 3 | Abolish Poison | LT+RT Up | Ctrl+Q | Faerie Fire |
| LT Y | 2 | Wild Growth | LT+RT Down | Ctrl+E |  |
| RT Up | 1 |  | LT+RT Left | Ctrl+R |  |
| RT Down | 4 | Tranquility | LT+RT Right | Ctrl+T |  |
| RT Left | C |  | none Up | radial / buff | Cat Form |
| RT Right | V | Entangling Roots | none Left | utility | Travel Form |
| LT Up | Shift+Q | Wrath | none Right | class basic | Dire Bear Form / Bear Form |
| LT Right | Shift+E | Moonfire | none Down | basic |  |

### Controller page 2 (class buttons): Balance, Feral Combat

| Button | Class button |
| --- | --- |
| RT A | Revive |
| RT X | Rebirth |
| RT B | Remove Curse [RemoveCurse] |
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
| RT Down | Mark of the Wild |
| RT Left | Aquatic Form |
| RT Right | Thorns |
| LT Right | Track Humanoids |

### Macros

- **Rejuv** (combat): Drops any form, then Rejuvenation on your friendly target, or on yourself when you have none.
- **Regrow** (combat): Drops any form, then Regrowth on your friendly target, or on yourself when you have none.
- **HTouch** (combat): Drops any form, then Healing Touch on your friendly target, or on yourself when you have none.
- **NSTouch** (combat): Drops any form, then Nature's Swiftness and an instant Healing Touch on your friendly target, or on yourself.
- **Innerv** (combat): Drops any form, then Innervate on your friendly target, or on yourself when you have none.
- **RemoveCurse** (combat): Drops any form, then Remove Curse on your friendly target, or on yourself when you have none.
- **CatOpener** (combat): In Cat Form: out of combat, Prowl; while prowling, Ravage your target (Shred until you know Ravage). Get behind it first.
- **CatProwl** (combat): Shifts to Cat Form from any form (stays in it if you are), then Prowls.
- **CatDash** (combat): Shifts to Cat Form from any form (stays in it if you are), then Dashes.
- **BearCharge** (combat): Shifts to Bear Form from any other form, then Feral Charges your target (with Furor's rage).
