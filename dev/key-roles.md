# Key roles: one muscle memory for every class

The owner is an altoholic (2026-11-23). Two levels of consistency:
- Hard rule: the keybinds are identical for every class: the same 12 keys on Bar 1, Shift on Bar 2, Ctrl on Bar 4, Alt on Bar 3, the same pet keys and the same controller buttons. Keybinds.lua is class-independent; never add class-specific binds.
- Guideline: put the same KIND of ability on the same key where it fits, using the roles below (the Beast Mastery hunter in Layouts/Hunter.lua is the reference; the owner plays it daily).
  Classes and specs may differ when there's a reason, but every layout must be laid out with purpose: say the reasoning in the layout file's comments (why this spell sits on this key).
  Every class and spec in one table each: `dev/class-layouts.md`, generated from the data by `luajit dev/class-layouts.lua > dev/class-layouts.md`.

## Keyboard

| Key | Plain (Bar 1) | Shift (Bar 2) | Ctrl (Bar 4) |
|---|---|---|---|
| Q | Main instant attack / builder (Arcane Shot, Sinister Strike, Heroic Strike, Shadow Bolt) | Self-heal / sustain (Mend Pet, Flash of Light self, Healthstone-free heals, Frenzied Regen) | Secondary attack / debuff (stings, curses, shocks) |
| E | DoT or maintained debuff (Serpent Sting, Rend, Corruption, Flame Shock, SW:Pain) | Spec defensive / spec cooldown (Bestial Wrath, Deterrence, Shield Block, Ice Barrier) | Secondary debuff |
| R | Big hitter / cast nuke (Aimed Shot, Mortal Strike, Mind Blast, Frostbolt) | Burst cooldown (Rapid Fire, Recklessness, Arcane Power, Adrenaline Rush) | Secondary utility attack |
| T | Spec signature (Summon Hawk / Sniper Shot / Strider Kick; Shield Slam / MS / BT) | Spec control (Intimidation, Scatter, Concussion Blow, Kidney Shot) | Spec utility |
| F | Melee / secondary builder (Raptor Strike) | Hard CC (Freezing Trap, Polymorph, Sap, Seduction, Hammer of Justice) | Utility |
| G | Proc / reactive ability (Mongoose Bite, Overpower, Revenge, Riposte, Ice Lance) | AoE control (Frost Trap, Frost Nova, Psychic Scream, Howl, Intimidating Shout) | Utility |
| C | Escape / mobility (Disengage, Blink, Sprint, Intercept/Charge in combat, Fade) | Racial (always) | Utility |
| V | Snare / slow (Wing Clip, Hamstring, Frost Shock, Crippling-free snares) | Emergency (Feign Death, Ice Block, Vanish, Divine Shield, Shield Wall, Barkskin) | Utility |
| 1 | Opener / pull (Hunter's Mark, Charge, Cheap Shot, Pyroblast, SW:Pain pull) | Buff / stance row (aspects, stances, forms, armors, seals, auras, shields) | Buff / summon / create row |
| 2 | Main AoE (Multi-Shot, Cleave/Whirlwind, Arcane Explosion, Swipe, Hellfire) | Buff / stance row | Buff / summon / create row |
| 3 | Ranged control / interrupt (Concussive Shot, Pummel/Shield Bash, Kick, Counterspell, Earth Shock) | Buff / stance row | Buff / summon / create row |
| 4 | Ground / secondary AoE (damage trap, Blizzard, Consecration, Rain of Fire, Thunder Clap) | Buff / stance row | Buff / summon / create row |

Alt (Bar 3) is the same on every class and spec (`ActionBars.utility`; no class layout sets it):

| Key | Alt (Bar 3) |
|---|---|
| Q | HealPot: Healthstone, else the best healing potion |
| E | ManaPot: mana gem, else the best mana potion (empty on warriors and rogues) |
| R | Bandage: the best bandage on yourself |
| T | Food: the best food for your level |
| F | Fish: equip the best pole you carry, then fish |
| G | Bait: the best lure onto your pole |
| C / V | On-use trinkets (top / bottom) |
| 4 | Hearthstone |

Stance pages (warrior, druid, rogue stealth, priest shadowform) keep these roles in every stance: the stance only changes WHICH spell fills a role.
Healers: the heal roles move to Plain (Q main heal, E HoT, R big heal, T spec heal, 1 group heal) and damage moves to Shift, exactly as the Holy paladin override does; keep F G C V and the Shift row 2 roles unchanged.

## Controller page 1 (mirrors the keyboard roles)

| Button | Role (keyboard key) |
|---|---|
| RT A | Plain Q (main attack) |
| RT X | Plain E (DoT) |
| RT B | Plain 3 (ranged control / interrupt) |
| RT Y | Plain 2 (main AoE) |
| RT Up | Plain 1 (opener) |
| RT Right | Plain R (big hitter) |
| RT Left | Plain T (spec signature) |
| RT Down | Plain 4 (ground AoE) |
| LT A | Plain F (melee / builder) |
| LT X | Plain G (proc) |
| LT B | Plain V (snare) |
| LT Y | Plain C (escape) |
| LT Up | Shift Q (self-heal) |
| LT Down | Shift F (hard CC) |
| LT Left | Shift T (spec control) |
| LT Right | Shift E (spec defensive/cooldown) |
| none Up / Left / Right / Down | Radials or out-of-combat basics (buff row radial on Up, tracking/utility on Left, pet/class basic on Right) |
| LT+RT A | Shift V (emergency) |
| LT+RT X | Shift G (AoE control) |
| LT+RT B | Racial |
| LT+RT Y | Shift R (burst) |
| LT+RT Up/Down/Left/Right | Ctrl Q E R T (secondary attacks/debuffs) |

Page 2 = utility: the class's own buttons (resurrect/summon/creation/buffs on RT, one more on LT Right) plus the shared buttons from `Layouts/Shared.lua`, identical on every class and character: Hearthstone RT Up, the LT item layer (Bait LT A, HealPot LT X, ManaPot LT Y, Bandage LT B, Food LT Left, trinkets LT Up/Down), Fish none Up, camp none Left/Down, Mount none Right, and 8 profession slots on LT+RT filled from the character's own professions in one stable order (dev/layout-format.md, "Shared buttons"). Page 3 = pet/class extras, then overflow.

## Consumables: why these keys

The item macros (owner decision, 2026-11-24) are generated from your bags (`Macros/Items.lua`), so one macro per kind of consumable works for every class:
- Same keys everywhere: an altoholic presses Alt+Q for a heal potion on every character, and LT X on the pad. No class file may move them [rules: layout-shared, and the Alt bar is never read from a class].
- Alt+Q E R T sit under the main hand, like Q E R T, and read top-down in urgency: heal (Q, as Shift+Q is the self-heal spell), mana (E), bandage (R, out of danger), food (T, out of combat). Fish and Bait stay on F and G, trinkets on C and V, the Hearthstone on 4.
- Controller: LT is the item layer of page 2 (Bait A, trinkets Up/Down), so the consumables take its free face buttons in the same order (HealPot X, ManaPot Y, Bandage B) and Food LT Left. Mage and druid page 2 spells that sat there moved to page 3.
- Class consumables fold into the shared macros instead of getting their own: a warlock's Healthstone is HealPot's first choice (free, its own cooldown; once used the macro moves on to potions), a mage's mana gem is ManaPot's first choice for the same reason, and conjured food wins its tier in Food. Warriors and rogues have no mana: ManaPot isn't offered and Alt+E / LT Y stay empty ("your class has no mana") rather than holding something else, so the key means the same thing on every character. Hunter pet food is not player food: raw meat and fish are never in the Food list (Feed Pet keeps its own home). Drinks are not handled.
