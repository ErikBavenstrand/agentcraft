-- Mage layouts. Data contract: dev/layout-format.md. Keep every value a
-- literal (no variables, no function calls): dev.ps1 rules reads this file
-- without running Lua.
--
-- Frost is the leveling spec (research 2026-11: Icy Veins, Mobalytics,
-- Method, Warcraft Tavern): Fire hits hardest on one target, Arcane lacks
-- survivability. Mages have no stances, so there are no stance pages.
--
-- Keys follow dev/key-roles.md (the same kind of ability on the same key
-- for every class). Plain: Q instant attack (Fire Blast), E maintained
-- debuff (Scorch / Arcane Wrath), R cast nuke, T spec signature, F second
-- nuke, G proc (Ice Lance / Pyroblast / Arcane Missiles), C escape (Blink),
-- V snare (Cone of Cold), 1 opener, 2 main AoE (Arcane Explosion),
-- 3 interrupt (Counterspell), 4 ground AoE (Blizzard / Flamestrike).
-- Shift: Q sustain, E spec defensive, R burst, T spec control, F hard CC,
-- G AoE control, C racial, V emergency, 1-4 armors and buffs. Ctrl: Q E R T
-- secondary attacks, F G C V utility magic, 1-4 buffs and conjures.
--
-- The shared layout is Frost's. Fire and Arcane replace Bar 1 and
-- controller page 1; Fire also replaces Ctrl (Blizzard there instead of
-- Flamestrike, which Fire has on 4). Blizzard and Flamestrike are
-- ground-targeted plain buttons (no @cursor macros); on a controller they
-- ask for the cursor confirm.
local _, ns = ...

ns.Layout.Register("MAGE", {
  specs = {
    { key = "arcane", name = "Arcane", tab = 1,
      keyboard = {
        [1] = {
          { "Fire Blast" },                             -- Q  instant attack
          { "Arcane Wrath", "Scorch" },                 -- E  debuff (15-point talent)
          { "Arcane Blast", "Frostbolt" },              -- R  cast nuke: Frostbolt until Arcane Blast
          { "Presence of Mind" },                       -- T  spec signature
          { "Fireball" },                               -- F  second nuke
          { "Arcane Missiles" },                        -- G  proc: Missile Barrage
          { "Blink" },                                  -- C  escape
          { "Cone of Cold" },                           -- V  snare
          { "Pyroblast" },                              -- 1  opener (hybrid builds only)
          { "Arcane Explosion" },                       -- 2  main AoE
          { "Counterspell" },                           -- 3  interrupt
          { "Blizzard" },                               -- 4  ground AoE
        },
      },
      controller = {
        pages = {
          [1] = {
            title = "Combat",
            ["RT A"] = { "Fire Blast" },
            ["RT X"] = { "Arcane Wrath", "Scorch" },
            ["RT B"] = { "Counterspell" },
            ["RT Y"] = { "Arcane Explosion" },
            ["RT Up"] = { "Pyroblast" },
            ["RT Right"] = { "Arcane Blast", "Frostbolt" },
            ["RT Left"] = { "Presence of Mind" },
            ["RT Down"] = { "Blizzard" },
            ["LT A"] = { "Fireball" },
            ["LT X"] = { "Arcane Missiles" },
            ["LT B"] = { "Cone of Cold" },
            ["LT Y"] = { "Blink" },
            ["LT Up"] = { "Evocation" },
            ["LT Down"] = { "Polymorph" },
            ["LT Left"] = { macro = "PolyFocus" },
            ["LT Right"] = { "Ice Barrier", "Mana Shield" },
            ["none Up"] = { "Arcane Intellect" },
            ["none Left"] = { "Remove Lesser Curse" },
            ["LT+RT A"] = { macro = "BlockBreak", "Ice Block" },
            ["LT+RT X"] = { "Frost Nova" },
            ["LT+RT B"] = { racial = true },
            ["LT+RT Y"] = { "Arcane Power", "Combustion", "Cold Snap" },
            ["LT+RT Up"] = { "Flamestrike" },
            ["LT+RT Down"] = { "Frost Ward" },
            ["LT+RT Left"] = { macro = "CounterFocus" },
            ["LT+RT Right"] = { "Fire Ward" },
          },
        },
      },
    },
    { key = "fire", name = "Fire", tab = 2,
      keyboard = {
        [1] = {
          { "Fire Blast" },                             -- Q  instant attack
          { "Scorch" },                                 -- E  debuff: Scorch stacks
          { "Fireball" },                               -- R  cast nuke
          { "Blast Wave" },                             -- T  spec signature
          { "Frostbolt" },                              -- F  second nuke (slows)
          { "Pyroblast" },                              -- G  proc: at 3 Heating Up
          { "Blink" },                                  -- C  escape
          { "Cone of Cold" },                           -- V  snare
          { "Frostfire Bolt" },                         -- 1  opener (level 40)
          { "Arcane Explosion" },                       -- 2  main AoE
          { "Counterspell" },                           -- 3  interrupt
          { "Flamestrike" },                            -- 4  ground AoE
        },
        [4] = {
          { "Blizzard" },                               -- Ctrl+Q  secondary attack
          false,                                        -- Ctrl+E  (no second debuff)
          { macro = "CounterFocus" },                   -- Ctrl+R  secondary utility attack
          { "Fire Ward" },                              -- Ctrl+T  spec utility
          { "Dampen Magic" },                           -- Ctrl+F  utility magic
          { "Amplify Magic" },                          -- Ctrl+G  utility magic
          { "Slow Fall" },                              -- Ctrl+C  utility (falls)
          { "Remove Lesser Curse" },                    -- Ctrl+V  decurse
          { "Arcane Brilliance" },                      -- Ctrl+1  group buff
          { macro = "ConjureBoth", "Conjure Water" },   -- Ctrl+2  conjure (water, and food once installed)
          { "Conjure Food" },                           -- Ctrl+3  conjure
          { "Conjure Mana Ruby", "Conjure Mana Citrine", "Conjure Mana Jade", "Conjure Mana Agate", upgrade = true }, -- Ctrl+4  conjure mana gem
        },
      },
      controller = {
        pages = {
          [1] = {
            title = "Combat",
            ["RT A"] = { "Fire Blast" },
            ["RT X"] = { "Scorch" },
            ["RT B"] = { "Counterspell" },
            ["RT Y"] = { "Arcane Explosion" },
            ["RT Up"] = { "Frostfire Bolt" },
            ["RT Right"] = { "Fireball" },
            ["RT Left"] = { "Blast Wave" },
            ["RT Down"] = { "Flamestrike" },
            ["LT A"] = { "Frostbolt" },
            ["LT X"] = { "Pyroblast" },
            ["LT B"] = { "Cone of Cold" },
            ["LT Y"] = { "Blink" },
            ["LT Up"] = { "Evocation" },
            ["LT Down"] = { "Polymorph" },
            ["LT Left"] = { macro = "PolyFocus" },
            ["LT Right"] = { "Ice Barrier", "Mana Shield" },
            ["none Up"] = { "Arcane Intellect" },
            ["none Left"] = { "Remove Lesser Curse" },
            ["LT+RT A"] = { macro = "BlockBreak", "Ice Block" },
            ["LT+RT X"] = { "Frost Nova" },
            ["LT+RT B"] = { racial = true },
            ["LT+RT Y"] = { "Arcane Power", "Combustion", "Cold Snap" },
            ["LT+RT Up"] = { "Blizzard" },
            ["LT+RT Down"] = { "Frost Ward" },
            ["LT+RT Left"] = { macro = "CounterFocus" },
            ["LT+RT Right"] = { "Fire Ward" },
          },
        },
      },
    },
    { key = "frost", name = "Frost", tab = 3, default = true },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  keyboard = {
    -- Bar 1 (Frost, shared), roles from dev/key-roles.md.
    [1] = {
      { "Fire Blast" },                                 -- Q  instant attack (6)
      { "Scorch" },                                     -- E  debuff, closest fit (22)
      { "Frostbolt" },                                  -- R  cast nuke (4)
      { "Arcane Missiles" },                            -- T  spec slot, closest fit (8)
      { "Fireball" },                                   -- F  second nuke, Frost-immune mobs (1)
      { macro = "BlockLance", "Ice Lance" },            -- G  proc: frozen / Fingers of Frost
      { "Blink" },                                      -- C  escape (20)
      { "Cone of Cold" },                               -- V  snare (26)
      { "Pyroblast" },                                  -- 1  opener (hybrid builds only)
      { "Arcane Explosion" },                           -- 2  main AoE (14)
      { "Counterspell" },                               -- 3  interrupt (24)
      { "Blizzard" },                                   -- 4  ground AoE (20)
    },
    -- Bar 2 (Shift): Q sustain, E spec defensive, R burst, T spec control,
    -- F hard CC, G AoE control, C racial, V emergency, 1-4 armors and buffs.
    [2] = {
      { "Evocation" },                                  -- Shift+Q  sustain
      { "Ice Barrier", "Mana Shield" },                 -- Shift+E  spec defensive
      { "Arcane Power", "Combustion", "Cold Snap" },    -- Shift+R  burst
      { macro = "PolyFocus" },                          -- Shift+T  control (waits until installed)
      { "Polymorph" },                                  -- Shift+F  hard CC
      { "Frost Nova" },                                 -- Shift+G  AoE control
      { racial = true },                                -- Shift+C  racial
      { macro = "BlockBreak", "Ice Block" },            -- Shift+V  emergency
      { macro = "ArmorSwap", "Ice Armor", "Frost Armor", upgrade = true }, -- Shift+1  armor (ArmorSwap toggles Ice / Mage Armor)
      { "Mage Armor" },                                 -- Shift+2  armor (mana regen)
      { "Arcane Intellect" },                           -- Shift+3  buff
      { "Frost Ward" },                                 -- Shift+4  ward
    },
    -- [3] is the Alt bar (trinkets, Fish, Bait, Hearthstone), not set here.
    -- Bar 4 (Ctrl): Q E R T secondary attacks, F G C V utility magic,
    -- 1 2 3 4 group buff and conjures. Teleports and portals fill the side bars.
    [4] = {
      { "Flamestrike" },                                -- Ctrl+Q  secondary attack
      false,                                            -- Ctrl+E  (no second debuff)
      { macro = "CounterFocus" },                       -- Ctrl+R  secondary utility attack
      { "Fire Ward" },                                  -- Ctrl+T  spec utility
      { "Dampen Magic" },                               -- Ctrl+F  utility magic
      { "Amplify Magic" },                              -- Ctrl+G  utility magic
      { "Slow Fall" },                                  -- Ctrl+C  utility (falls)
      { "Remove Lesser Curse" },                        -- Ctrl+V  decurse
      { "Arcane Brilliance" },                          -- Ctrl+1  group buff
      { macro = "ConjureBoth", "Conjure Water" },       -- Ctrl+2  conjure (water, and food once installed)
      { "Conjure Food" },                               -- Ctrl+3  conjure
      { "Conjure Mana Ruby", "Conjure Mana Citrine", "Conjure Mana Jade", "Conjure Mana Agate", upgrade = true }, -- Ctrl+4  conjure mana gem
    },
  },

  -- Controller: keys "<layer> <button>", layer none / LT / RT / LT+RT,
  -- button A X B Y or Up Down Left Right (D-pad). The Top bar's face buttons
  -- are fixed. Page 1 mirrors the keyboard roles (dev/key-roles.md).
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { "Fire Blast" },                    -- Q
        ["RT X"] = { "Scorch" },                        -- E
        ["RT B"] = { "Counterspell" },                  -- 3
        ["RT Y"] = { "Arcane Explosion" },              -- 2
        ["RT Up"] = { "Pyroblast" },                    -- 1
        ["RT Right"] = { "Frostbolt" },                 -- R
        ["RT Left"] = { "Arcane Missiles" },            -- T
        ["RT Down"] = { "Blizzard" },                   -- 4 (cursor confirm)
        ["LT A"] = { "Fireball" },                      -- F
        ["LT X"] = { macro = "BlockLance", "Ice Lance" }, -- G
        ["LT B"] = { "Cone of Cold" },                  -- V
        ["LT Y"] = { "Blink" },                         -- C
        ["LT Up"] = { "Evocation" },                    -- Shift+Q
        ["LT Down"] = { "Polymorph" },                  -- Shift+F
        ["LT Left"] = { macro = "PolyFocus" },          -- Shift+T
        ["LT Right"] = { "Ice Barrier", "Mana Shield" }, -- Shift+E
        ["none Up"] = { "Arcane Intellect" },           -- buff
        ["none Left"] = { "Remove Lesser Curse" },      -- utility
        ["LT+RT A"] = { macro = "BlockBreak", "Ice Block" }, -- Shift+V
        ["LT+RT X"] = { "Frost Nova" },                 -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Arcane Power", "Combustion", "Cold Snap" }, -- Shift+R
        ["LT+RT Up"] = { "Flamestrike" },               -- Ctrl+Q
        ["LT+RT Down"] = { "Frost Ward" },              -- Ctrl+E (closest fit: a ward)
        ["LT+RT Left"] = { macro = "CounterFocus" },    -- Ctrl+R
        ["LT+RT Right"] = { "Fire Ward" },              -- Ctrl+T
      },
      -- Page 2: armors, conjures, your home city's teleport and portal; the
      -- shared Utility buttons (Layouts/Shared.lua) add Hearthstone,
      -- trinkets, fishing, the item macros on LT X Y B Left, camp, Mount and
      -- professions. The other cities' teleports and portals are on page 3.
      -- Faction pairs: you know only your side's one.
      {
        title = "Utility",
        ["RT A"] = { macro = "ArmorSwap", "Ice Armor", "Frost Armor", upgrade = true },
        ["RT X"] = { "Mage Armor" },
        ["RT B"] = { macro = "ConjureBoth", "Conjure Water" },
        ["RT Y"] = { "Conjure Mana Ruby", "Conjure Mana Citrine", "Conjure Mana Jade", "Conjure Mana Agate", upgrade = true },
        ["RT Down"] = { "Arcane Brilliance" },
        ["RT Left"] = { "Teleport: Orgrimmar", "Teleport: Stormwind" },
        ["RT Right"] = { "Portal: Orgrimmar", "Portal: Stormwind" },
        ["LT Right"] = { "Portal: Thunder Bluff", "Portal: Darnassus" },
      },
      -- Page 3: rarer magic, the other cities' teleports and portals (moved
      -- off page 2 for the shared item macros), Steam Deck helpers and the
      -- catch-all.
      {
        title = "Extras",
        ["RT A"] = { "Slow Fall" },
        ["RT X"] = { "Dampen Magic" },
        ["RT B"] = { "Amplify Magic" },
        ["RT Y"] = { "Conjure Food" },
        ["RT Up"] = { "Teleport: Undercity", "Teleport: Ironforge" },
        ["RT Down"] = { "Teleport: Thunder Bluff", "Teleport: Darnassus" },
        ["RT Left"] = { "Portal: Undercity", "Portal: Ironforge" },
        ["RT Right"] = { "Teleport: Dalaran" },
        ["none Up"] = { macro = "Reload" },
        ["none Down"] = { macro = "Follow" },
        ["none Left"] = { macro = "Focus" },
        ["none Right"] = { macro = "Assist" },
        ["LT+RT A"] = { macro = "Skull" },
        ["LT A"] = { overflow = true }, ["LT X"] = { overflow = true },
        ["LT B"] = { overflow = true }, ["LT Y"] = { overflow = true },
        ["LT Up"] = { overflow = true }, ["LT Down"] = { overflow = true },
        ["LT Left"] = { overflow = true }, ["LT Right"] = { overflow = true },
        ["LT+RT X"] = { overflow = true }, ["LT+RT B"] = { overflow = true },
        ["LT+RT Y"] = { overflow = true }, ["LT+RT Up"] = { overflow = true },
        ["LT+RT Down"] = { overflow = true }, ["LT+RT Left"] = { overflow = true },
        ["LT+RT Right"] = { overflow = true },
      },
    },
    paddles = {},
  },
})
