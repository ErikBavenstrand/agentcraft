# Layout data format

The contract for class layout, macro and fixture data. A class agent edits only its own files:

| File | What goes in it |
| --- | --- |
| `addon/Agentcraft/Layouts/<Class>.lua` | The class's specs, keyboard layout (with stance pages) and controller layout |
| `addon/Agentcraft/Macros/Data/<Class>.lua` | The class's library macros |
| `dev/harness/fixtures/<class>.lua` | A level 60 character of the class for the tests |
| `dev/tests/2N_<class>.lua` | The class's tests (copy the template at the end) |

Don't edit shared code (`Modules/*.lua`, `UI/*.lua`, `Layouts/Shared.lua`, `dev/harness/*.lua`, `dev.ps1`) or another class's files.
Every file is already in the TOC; a new file needs a TOC line and a full game restart (`/reload` doesn't load new files).

Check your work with `powershell -NoProfile -ExecutionPolicy Bypass -File dev/dev.ps1 check`. Check: `toc`, `rules`, `lint` and `test` all pass, and the rules and test 19 print no warning for your class.

## Owner rules

These hold for every class. `rules` enforces the ones marked [rules].

- Apply never creates macros. A macro home uses its plain spell until the player installs the macro on the Macros page.
- Keyboard: no flyouts, `petauto` or `overflow` entries [rules]. Layers: plain keys = Bar 1, Shift = Bar 2, Ctrl = Bar 4. Bar 3 is the Alt bar, shared by all classes and filled by ActionBars (the item macros HealPot Alt+Q, ManaPot Alt+E, Bandage Alt+R, Food Alt+T, Fish Alt+F, Bait Alt+G; trinkets Alt+C/V, Hearthstone Alt+4); a layout's `[3]` is ignored [rules: warning].
- Side bars (Action Bars 5-8) fill themselves with every known spell that has no key. Leave situational spells to them.
- Shared controller buttons (`Layouts/Shared.lua`): Hearthstone, trinkets, the item macros (HealPot, ManaPot, Bandage, Food, Fish, Bait), camp, Mount and the profession slots are the same on every class's page 2. A class page never names one of their buttons [rules]; its own page 2 buttons are the RT layer (but RT Up) and LT Right.
- Professions: a class layout never names a profession spell (`Layout.PROFESSIONS`: the primaries, Cooking, First Aid, Bait and Tackle, Find Minerals, Find Herbs, Smelting, Disenchant, Prospecting, Milling, Survey) [rules]. Their homes are the shared `{ profession = n }` slots on the controller and Action Bar 6 (click only) on the keyboard, filled from each character's own professions.
- One home per spell per spec per device [rules]. An item, a utility slot, your racial, a macro and a flyout count as homes too. The stance-page exception is below.
- Back buttons (`paddles`, F13-F16) stay empty (`paddles = {}`) unless the owner asks.
- Hand-written macros name only spells, slash commands and pet abilities; items only as `/use 13`/`/use 14` slot numbers. The generated item macros (`generated = "<key>"`: Fish, Bait, HealPot, ManaPot, Bandage, Food; owner decision 2026-11-24) may name items: `Macros/Items.lua` builds their text from the best item you carry and rewrites it when that changes [rules: info]. No `[mod]` conditions, no `@mouseover` or `@cursor`, no `/petattack`, no `/petpassive`, at most 255 characters and a name of at most 16 characters [rules].
- Bars place only the Hearthstone, the Cozy Sleeping Bag and equipped on-use trinkets as item buttons. Never food, drink, potions, bandages, bombs, gadgets or elixirs as item buttons: potions, bandages, food, bait and poles reach a key only through the generated item macros.

## Layouts/<Class>.lua

Keep every value a literal: strings, numbers, `true`/`false` and tables. No variables, function calls, `..` or loops: `dev.ps1 rules` reads the file without running Lua and reports anything else as `layout-parse`.

```lua
local _, ns = ...

ns.Layout.Register("WARRIOR", {
  specs = {
    { key = "arms", name = "Arms", tab = 1 },
    { key = "fury", name = "Fury", tab = 2 },
    { key = "prot", name = "Protection", tab = 3, default = true },
  },
  keyboard = {
    [1] = { <12 entries> },  -- plain keys
    [2] = { <12 entries> },  -- Shift
    [4] = { <12 entries> },  -- Ctrl
    stances = {
      battle    = { offset = 1, label = "Battle", <12 entries> },
      defensive = { offset = 2, label = "Defensive", <12 entries> },
      berserker = { offset = 3, label = "Berserker", <12 entries> },
    },
  },
  controller = {
    pages = { { title = "Combat", ["RT A"] = <entry>, ... }, { title = "Utility", ... }, { title = "Extras", ... } },
    paddles = {},
  },
})
```

The top-level fields are `specs`, `keyboard` and `controller`; nothing else [rules]. A stub has only `specs`: the class then has no layout, the Keyboard page shows only the keys and Apply says "no profile".

### Specs

Each spec has:

| Field | Meaning |
| --- | --- |
| `key` | Short lowercase id, unique in the class. Stored as the character's choice (`AgentcraftCharDB.spec`). |
| `name` | The talent tab's name as the game shows it ("Feral Combat"). Spec detection matches the tab by this name first. |
| `tab` | The talent tab, 1-3 left to right. Used when the client gives no tab names. |
| `default` | `true` on exactly one spec: the leveling spec [rules]. |
| `keyboard`, `controller` | Optional overrides, below. |

The active spec is, in order: the character's choice on the Keyboard or Controller page's Spec picker; else the talent tab with the most points; else the default spec (below level 10, with no points spent, or when the client reports no talents). A tie keeps the default spec when it is one of the tied, else the lowest tab. `/ac capture` and the snapshot's `talentDebug` (`Layout.spec`, `Layout.TalentTabs`) show what the game reported.

### Sharing one layout across specs

Put the layout in the top-level `keyboard` and `controller`: every spec uses it. Fallback chains cover the specs, so most classes need no override. `{ "Bestial Wrath", "Deterrence", "Trueshot Aura" }` takes the first spell you know: each build's signature cooldown lands on the same key.

Give a spec its own piece only where it really differs. An override replaces whole pieces, never parts of one:

| Override | Replaces |
| --- | --- |
| `keyboard = { [2] = { ... } }` | Bar 2 (likewise `[1]`, `[4]`) |
| `keyboard = { stances = { bear = { ... } } }` | That stance page; the other pages stay shared |
| `keyboard = { stances = { shadowform = false } }` | Drops that stance page for this spec |
| `controller = { pages = { [1] = { ... } } }` | Controller page 1 (likewise 2, 3) |
| `controller = { paddles = { ... } }` | The back buttons |

Example: the shadowform page only for Shadow priests:

```lua
specs = {
  { key = "discipline", name = "Discipline", tab = 1, keyboard = { stances = { shadowform = false } } },
  { key = "holy", name = "Holy", tab = 2, keyboard = { stances = { shadowform = false } } },
  { key = "shadow", name = "Shadow", tab = 3, default = true },
},
keyboard = { [1] = {...}, [2] = {...}, [4] = {...}, stances = { shadowform = { offset = 1, label = "Shadowform", ... } } },
```

The rules check the shared layout, then each spec that has an override, merged.

### Keyboard bars

Each of `[1]`, `[2]` and `[4]` is a list of exactly 12 entries [rules], in key order:

```
index  1 2 3 4 5 6 7 8 9 10 11 12
key    Q E R T F G C V 1 2  3  4
```

Write `false` for a key left empty on purpose. Group the keys in rows of four by family (the hunter layout: Q E R T rotation, F G C V melee, 1 2 3 4 pull and shots), so players learn rows.

### Stance pages (Bar 1 paging)

In a stance, form or stealth the game shows another page of Action Bar 1 under the same plain keys. The base `[1]` is the no-stance page (slots 1-12). Each stance page goes into the bonus bar of its `offset`:

| offset | Slots | Class stance keys |
| --- | --- | --- |
| 1 | 73-84 | warrior `battle`, druid `cat`, rogue `stealth`, priest `shadowform` |
| 2 | 85-96 | warrior `defensive` |
| 3 | 97-108 | warrior `berserker`, druid `bear` |
| 4 | 109-120 | druid `moonkin` |

A stance page has `offset` (1-4, unique), an optional `label` (shown on the Keyboard page and in the Inspector; defaults to the key capitalised) and 12 entries [rules]. Use the stance keys above: another key or offset is a warning [rules]. Paladin, hunter, shaman, mage and warlock have no paging; a stance page there is a warning. Druid Prowl is handled by the game (no page of its own).

Apply puts each page into its bonus bar slots, backs them up the first time and Undo restores them. A stance page a spec drops is cleared on the next Apply. `ACTIONBUTTON1-12` follow the page by themselves: keybinds need nothing extra.

One home with stance pages: a spell may repeat on Bar 1's pages (base and stances) only on the same key, such as Execute on R in Battle and Berserker Stance or Heroic Strike on Q everywhere. The key is its one home. The same spell on another key, or on a Bar 1 page and on Shift or Ctrl, is two homes [rules]. A spell usable in every stance (Bloodrage, Battle Shout) belongs on Shift or Ctrl, which don't page.

Leave the stance spells themselves (Battle Stance, Cat Form) to a non-paging bar or the side bars, and a stance-dance macro (`/cast [stance:1] Overpower; Battle Stance`) on the base page where the spell needs another stance.

The controller does not page: the Gamepad UI's storage slots depend on the gamepad page only (Blizzard_GamepadActionBars `GetGamepadStorageSlotIndexFromPageAndPageUnitSlotID`). Controller layouts are stance-independent; use stance-dance macros there.

### Controller

`pages` is a list of 3 pages. Each page has a `title` and entries keyed `"<layer> <button>"`: layer `none`, `LT`, `RT` or `LT+RT`; button `A X B Y` (face) or `Up Down Left Right` (D-pad). `none A/X/B/Y` are fixed by the Gamepad UI [rules]. Follow the hunter's page roles:

- Page 1, Combat: RT face = ranged rotation, LT face = melee, the D-pad (thumb off the stick) = stand-still casts, LT+RT = rare spells, `none` D-pad = radials and out-of-combat basics.
- Page 2, Utility: only the class's own buttons, on the RT layer (resurrects, summons, pet care, buffs, conjures, portals) and `LT X B Y Left Right`. The shared buttons fill the rest (below); leave `RT Up`, `LT A`, `LT Up`, `LT Down`, the `none` D-pad and all of LT+RT out of the class page.
- Page 3, Extras: `petauto` toggles (pet classes), Steam Deck helper macros (`none` D-pad: Reload, Follow, Focus, Assist; `LT+RT A` Skull) and `overflow` everywhere else.

`paddles = {}` (back buttons left free by the owner).

### Shared buttons

`Layouts/Shared.lua` registers the buttons every class and character gets: `ns.Layout.RegisterShared({ controller = { pages = { [2] = { title = "Utility", ["RT Up"] = <entry>, ... } } } })`, literal data like a class file. `Layout.ControllerPages` (and so Apply, the Controller page and the rules) merges each shared page into the class page of the same number, for every spec, spec overrides included. A class page naming a shared button is an error [rules].

Page 2:

| Button | Entry |
| --- | --- |
| `RT Up` | `{ item = "Hearthstone" }` |
| `LT Up` / `LT Down` | `{ utility = 8 }` / `{ utility = 7 }` (on-use trinkets) |
| `LT A` | `{ macro = "Bait" }` |
| `LT X` | `{ macro = "HealPot" }` (keyboard Alt+Q) |
| `LT Y` | `{ macro = "ManaPot" }` (Alt+E; empty on warriors and rogues: no mana) |
| `LT B` | `{ macro = "Bandage" }` (Alt+R) |
| `LT Left` | `{ macro = "Food" }` (Alt+T) |
| `none Up` | `{ macro = "Fish", "Fishing" }` |
| `none Left` | `{ item = "Cozy Sleeping Bag" }` |
| `none Down` | `{ "Basic Campfire" }` |
| `none Right` | `{ macro = "Mount" }` (waits until installed) |
| `LT+RT A Y X B Down Up Left Right` | `{ profession = 1 }` ... `{ profession = 8 }`, in that button order |

The LT layer is the item layer: Bait, the four consumable macros and the trinkets. The item macro homes take their macro only once you install it on the Macros page (Apply never creates one) and wait with "Waiting · install <name> on the Macros page" until then; your own button on a waiting Alt key stays until you install the macro.

The profession order (`Layout.PROFESSIONS`, built per character by `ActionBars.ProfessionSpells` from `GetProfessions`/`GetProfessionInfo` and the spellbook, names as fallback):

1. the first primary profession's own spell (the spell named like the profession, else its first spell that is not a gathering/utility one),
2. the second primary's,
3. Cooking, 4. First Aid, 5. fishing helpers (Bait and Tackle),
6. then every other spell of your professions: Find Minerals, Find Herbs, Smelting, Disenchant, Prospecting, Milling, Survey, then the rest alphabetically.

A profession you lack is skipped, so the next one moves up; slots past the last spell wait ("learn another profession"). Fishing and Basic Campfire never take a slot (they have shared buttons). A profession spell past the eighth slot goes to the page 3 catch-all. On the keyboard, Action Bar 6 holds tracking, then the same profession spells in the same order, then Fishing, Basic Campfire and the Cozy Sleeping Bag. Button A Y X B keeps the owner's tested hunter page: Mining, Engineering (Y), Cooking (X), First Aid (B), Bait and Tackle (Down), Find Minerals (Up), Smelting (Left).

### Entry forms

An entry is a table; its list part names spells, tried in order.

| Form | Meaning |
| --- | --- |
| `{ "Spell", "Alternative" }` | The first one you know. Alternatives only for either-or talents of different builds, or a same-role upgrade. |
| `{ "Better", "Lower", upgrade = true }` | A same-role upgrade: once you know the better one, the lower one needs no home (side bars and the controller catch-all skip it). |
| `{ macro = "Name", "Spell" }` | The library macro once installed, else the spell. |
| `{ macro = "Name", "Spell", "Fallback" }` | Before you know Spell, the next spell you know holds the home. |
| `{ macro = "Name" }` | Macro only: waits ("install Name on the Macros page") until installed. |
| `{ macro = "Name", "Spell", covers = { "Other" } }` | Other spells the macro casts, so side bars and the catch-all skip them. |
| `{ flyout = 253, "Spell" }` | Controller only: a spellbook flyout (a radial), by flyout ID or name. |
| `{ racial = true }` | Your race's active racial. |
| `{ utility = 7 }` | The equipped on-use trinket (7 top, 8 bottom). |
| `{ item = "Hearthstone" }` | That bag item; only `Hearthstone` and `Cozy Sleeping Bag` are placed. |
| `{ petauto = true }` | Controller only: an autocast toggle for the pet's next autocastable ability. |
| `{ overflow = true }` | Controller only: a known spell with no other controller home. |
| `{ profession = 3 }` | Controller only: your 3rd profession spell in the stable order (Shared buttons); waits when you have fewer. Used by `Layouts/Shared.lua`. |
| `false` | Keyboard only: a key left empty on purpose. |

Other fields are errors [rules]. A `macro` must be in the library, not retired, and of this class or classless [rules].

## Macros/Data/<Class>.lua

The `Macros/Library.lua` header lists every field and convention. The shape:

```lua
local _, ns = ...
local L = ns.MacroLibrary

L.Add({ name = "Overpower", category = "combat", class = "WARRIOR", order = 20, perCharacter = true,
  icon = "Overpower", requires = { "Overpower" }, tags = { "rotation" }, untested = true,
  desc = "Overpower in Battle Stance; from another stance, switch to Battle Stance first.",
  body = "#showtooltip Overpower\n/cast [stance:1] Overpower; Battle Stance" })
```

- Set `class`, `perCharacter = true` and `untested = true` (until the owner confirms it in game).
- Cite the source of each macro in the file header.
- Names are unique across all data files and at most 16 characters; reuse existing short lowercase `tags` (`rotation`, `opener`, `defensive`, `cooldown`, `crowd control`, `controller`, `group`, `travel`) before inventing one.
- A layout home names the macro with `macro = "Overpower"`; the macro must exist, or `rules` fails.
- Class consumables never get a class macro: the shared item macros already cover them for every class (Healthstones in HealPot, mana gems in ManaPot, conjured food in Food; `Macros/Items.lua`). Add a new item to the lists there, not a class file.

### Generated item macros

`generated = "<key>"` makes a macro an item macro (`Macros/Data/General.lua`: Fish, Bait, HealPot, ManaPot, Bandage, Food). `L.generators[key]` in `Macros/Items.lua` returns the text for the best item you carry (only items in your bags, plus the pole in your hands for Fish; gated by level from `C_Item.GetItemInfo` minLevel, else the list's `level`, and by First Aid or Fishing skill), or nil; then the macro's own `body` runs, which prints "no <thing> in your bags". They are character macros (`perCharacter = true`), keep the question-mark icon so the button shows the item, and `power = "mana"` keeps ManaPot from warriors and rogues. Once installed, the ItemMacros module rewrites them (`L.UpdateGenerated`) on `BAG_UPDATE_DELAYED`, `PLAYER_LEVEL_UP`, `SKILL_LINES_CHANGED` and login, one second after the last change, never in combat (queued until `PLAYER_REGEN_ENABLED`), only when the text changes, and only a copy Agentcraft wrote in the character tab. Install still happens only on the Macros page.

## dev/harness/fixtures/<class>.lua

A level 60 character the tests boot with `H.boot({ fixture = "<class>" })`. Fields:

| Field | Required | Meaning |
| --- | --- | --- |
| `class` | yes | `{ "Warrior", "WARRIOR", 1 }` (UnitClass returns) |
| `race` | yes | `{ "Undead", "Scourge" }` (UnitRace returns) |
| `level` | no | Default 60. Tests override with `boot{ level = }`. |
| `talents` | no | Points per talent tab in tab order: `{ { name = "Arms", points = 31 }, ... }`. Without it the client reports no talents. Tests override with `boot{ talents = }`. |
| `spells` | yes | The learned spellbook: `{ name =, id = }` (`passive = true` skipped, `icon =` optional). |
| `catalog` | no | Spells the game knows but the character hasn't learned (talents, later ranks): `C_Spell.GetSpellInfo` finds them, `IsPlayerSpell` doesn't. |
| `otherSpells` | no | Other real spell names the layouts name, for the rules only (no ID). |
| `professions`, `flyouts`, `items`, `bags`, `equipped`, `petData`, `bonusOffset` | no | As in `fixtures/hunter.lua`. Without `items`/`bags`, a Hearthstone sits in the backpack. `bonusOffset` is the stance page shown (`GetBonusBarOffset`). `GetProfessions` returns the professions in the client's six positions (the first two primaries in fixture order, then archaeology, fishing, cooking, first aid); tests override them with `boot{ professions = }`. |

Spell IDs are Classic ranks; exact IDs don't matter, only that names and IDs stay consistent. Every spell name a layout names must be in `spells`, `catalog`, `otherSpells`, a profession or a flyout: test 19 warns about any other name.

## Test template

Copy this to `dev/tests/2N_<class>.lua` (pick an unused number) and adapt it:

```lua
-- <Class> layouts: every spec resolves, Apply fills the bars and stance
-- pages, the plan agrees afterwards, and nothing creates a macro.
local H = require("harness")

local function Boot(opts)
  opts = opts or {}
  opts.fixture = "warrior"
  return H.boot(opts)
end

test("warrior: each spec's keyboard and controller resolve", function()
  local env = Boot()
  local L = env.ns.Layout
  for _, spec in ipairs(L.Specs("WARRIOR")) do
    local kb = L.KeyboardBars("WARRIOR", spec.key)
    ok(kb and kb[1] and kb[2] and kb[4], spec.key .. " keyboard")
    ok(L.ControllerPages("WARRIOR", spec.key), spec.key .. " controller")
  end
end)

test("warrior: the leveling spec until talents say otherwise", function()
  eq(Boot({ level = 8 }).ns.Layout.ActiveSpec("WARRIOR").key, "prot")
  local env = Boot({ talents = { { name = "Arms", points = 31 }, { name = "Fury", points = 5 }, { name = "Protection", points = 0 } } })
  eq(env.ns.Layout.ActiveSpec("WARRIOR").key, "arms")
end)

test("warrior: Apply fills Bar 1, its stance pages and the controller; no macro is created", function()
  local env = Boot({ talents = { { name = "Arms", points = 31 }, { name = "Fury", points = 0 }, { name = "Protection", points = 0 } } })
  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(1), "spell:Heroic Strike", "Q")
  eq(env:slotText(74), "spell:Overpower", "Battle Stance E (slot 72 + 2)")
  eq(#env:calls("CreateMacro"), 0)
  eq(env.ns.modules.actionbars.Plan().changes, 0, "up to date after Apply")
end)

test("warrior: an installed macro takes its home", function()
  local env = Boot({ macros = { "Overpower" } })
  env:slash("spells apply")
  ok(env:slotText(1) ~= nil)
end)
```

Useful harness calls: `env:slotText(slot)` ("spell:Name", "macro:Name", "item:6948"), `env:padSlot(set, "RT A")` (hunter page slots pinned from the game; for other classes compute `180 + (set - 1) * 28 + (n < 5 and n or n - 4)` with `n = layer * 8 + button`, layer none 0 / LT 1 / RT 2 / LT+RT 3, button Left 1 Up 2 Right 3 Down 4 X 5 Y 6 B 7 A 8), `env:installMacro(name)`, `env.W.bonusOffset = 2` (change the stance page shown), `noErrors(env)`. `dev/README.md` lists the rest.

## Unverified on WoW Forever

- Bonus bar slots: the offsets and slots above are the classic `GetBonusBarOffset` table (warcraft.wiki.gg). The Forever client computes Bar 1's paging in C, so they need an in-game check: stand in each stance and run `/ac capture quick`, then `wowdata.ps1 capture` prints `GetBonusBarOffset`, `C_ActionBar.GetBonusBarIndex`, `bonusIndexForSlot` and the contents of slots 1-12 and 73-120 for each step.
- Talent tabs: Forever's trait tree is read as three node groups sorted by `orderIndex` and matched to specs by name; check `talentDebug` in the snapshot (`wowdata.ps1 character -Path talentDebug`) on a character with talents.
- Profession order: which profession `GetProfessions` returns as primary 1 and 2 on WoW Forever, and that Mining and Herbalism are castable spells there (the owner's hunter had a castable Mining on the controller catch-all), need an in-game check: `/ac capture` after Apply shows page 2's LT+RT slots.
