-- Mage layouts. Data contract: dev/layout-format.md. Keep every value a
-- literal (no variables, no function calls): dev.ps1 rules reads this file
-- without running Lua. Placement rule: dev/key-roles.md (rotation first).
-- No stances, so no stance pages.
--
-- Rotations: Wowhead's WoW Forever guides (read 2026-11-26); they win any
-- disagreement with the earlier research.
--   https://www.wowhead.com/forever/guide/classes/mage/<spec>/rotation-cooldowns-pve-dps
--   https://www.wowhead.com/forever/guide/classes/mage/<spec>/dps-leveling-tips
--   (<spec> = arcane, fire, frost)
-- Where Wowhead is silent: [M] Method Forever mage leveling
-- (method.gg/wow-forever/wow-forever-mage-leveling-guide-and-talents) and
-- [T] Warcraft Tavern Forever mage leveling
-- (warcrafttavern.com/forever/guides/mage-leveling).
-- Forever changes (Wowhead): Ice Lance is a Frost talent sharing an 8 s
-- cooldown with Fire Blast; Arcane Blast's stacks are a spell power buff
-- that runs out; Fire Blast always gives a Heating Up stack and Pyroblast
-- fires at 3; Ice Barrier keeps Frigid Power up; Winter's Chill stacks buff
-- the next Cone of Cold; Frost Blast is a new trainer spell (24).
-- Trainer levels (Wowhead): Fireball 1, Frostbolt 4, Fire Blast 6, Arcane
-- Missiles 8, Frost Nova 10, Arcane Explosion 14, Blink / Blizzard /
-- Evocation / Mana Shield / Remove Lesser Curse 20, Scorch 22, Counterspell
-- / Frost Blast 24, Cone of Cold 26. Flamestrike 16 and Frostfire Bolt 40
-- [T].
-- Talents (dev/forever-talents.md; row r = level 10 + 5r, earlier with the
-- Talented legacy perk): Arcane Blast row 2 = 20, Arcane Wrath row 3 = 25,
-- Presence of Mind row 4 = 30, Arcane Power row 6 = 40; Pyroblast row 2 =
-- 20, Blast Wave row 4 = 30, Combustion row 6 = 40; Ice Lance row 2 = 20,
-- Ice Block row 3 = 25, Cold Snap row 4 = 30, Ice Barrier row 6 = 40.
-- Missile Barrage, Heating Up and Fingers of Frost are passive talents (no
-- button). Pyroblast and Ice Lance are talents, so only the specs that take
-- them get them: no chain assumes either.
--
-- Arcane (Wowhead). Arcane Fire build, single target: Pyroblast at 3
--   Heating Up > Fire Blast > Arcane Missiles on Missile Barrage > Arcane
--   Blast up to 4 stacks > Arcane Wrath on cooldown > Scorch otherwise.
--   Full Arcane: Missiles on Missile Barrage > Arcane Wrath > Arcane Blast
--   > Missiles. AoE: pre-cast Flamestrike, spam Arcane Explosion.
--   Cooldowns: Arcane Power (after 4 Blast stacks), Presence of Mind,
--   Evocation. Leveling: Frostbolt to pull and slow, Arcane Missiles, Frost
--   Nova for distance; from 21 Arcane Blast 1-2 stacks then Missiles, from
--   26 Arcane Wrath on cooldown; AoE: Flamestrike, Cone of Cold to slow,
--   Arcane Explosion spam.
-- Fire (Wowhead): pre-cast Pyroblast > keep Scorch at 5 stacks > Pyroblast
--   at 3 Heating Up > Fire Blast > Arcane Missiles on Missile Barrage >
--   Fireball (Scorch when Fire Blast is under 3 s). Frostfire build: the
--   same with Frostfire Bolt as the filler and on Fingers of Frost. AoE:
--   pre-cast Flamestrike, Blast Wave, Arcane Explosion. Cooldowns:
--   Combustion, Evocation. Leveling: the same priority (Fireball filler,
--   Scorch only on long fights); tips: Frostbolt to slow, Frost Nova then
--   Polymorph on adds; AoE: Flamestrike, Cone of Cold, Arcane Explosion.
-- Frost (leveling spec, default; Wowhead): pre-pull Ice Barrier, Frostbolt >
--   Cold Snap when Cone of Cold has 5-7 s left > Cone of Cold at 5 Winter's
--   Chill (AoE: on a Fingers of Frost charge) > Frostbolt + queued Ice Lance
--   on the last Fingers of Frost stack > Ice Barrier to keep Frigid Power >
--   Frostbolt (Blizzard at 3+ targets). Its deep build takes Missile Barrage
--   (Arcane Missiles on the proc). Leveling: Frostbolt, Fire Blast until Ice
--   Lance replaces it (shared cooldown), Ice Lance on frozen / Fingers of
--   Frost, Cone of Cold, Frost Nova for space; AoE: Cold Snap, Cone of Cold,
--   Ice Lance, Arcane Explosion, Blizzard. Frost-immune mobs: Fireball /
--   Frostfire Bolt [T] (Wowhead names no frost-immune button).
--
-- Every spec: Counterspell on 3, Blink on C, Arcane Explosion on 2, a
-- ground AoE on 4. Arcane and Fire put Frost Nova on V (their slow / control
-- key: in their rotations it only makes distance); for Frost it is rotation
-- slot 3. The shared layout is Frost's; Fire and Arcane replace Bar 1, Shift
-- (Cone of Cold on Shift+G, Arcane Power / Combustion on Shift+R), Ctrl
-- (Blizzard on Ctrl+Q) and controller page 1. Blizzard and Flamestrike are
-- plain ground-targeted buttons (no @cursor); on the pad they sit on the
-- D-pad, cast standing.
local _, ns = ...

ns.Layout.Register("MAGE", {
  specs = {
    { key = "arcane", name = "Arcane", tab = 1,
      keyboard = {
        [1] = {
          { "Arcane Blast", "Fireball" },               -- Q  slot 1: Blast up to 4 stacks, the filler (Fireball until the talent)
          { "Arcane Missiles" },                        -- E  slot 2: on Missile Barrage, and the leveling nuke after 2 Blasts
          { "Arcane Wrath" },                           -- R  slot 3: big hitter on cooldown (talent, row 3 = 25)
          { "Scorch" },                                 -- T  slot 5: Arcane Fire filler once Blast has 4 stacks and Wrath cools (22)
          { "Fire Blast" },                             -- F  slot 4: on cooldown, builds Heating Up for Pyroblast
          { "Pyroblast" },                              -- G  reactive: at 3 Heating Up (Arcane Fire build)
          { "Blink" },                                  -- C  mobility
          { "Frost Nova" },                             -- V  control: freeze and step back while leveling
          { "Frostbolt" },                              -- 1  pull: "Frostbolt to pull" and slow (Wowhead leveling)
          { "Arcane Explosion" },                       -- 2  main AoE (spam)
          { macro = "Counter", "Counterspell" }, -- 3  interrupt (Counter: stops your cast first)
          { "Flamestrike" },                            -- 4  ground AoE, pre-cast standing
        },
        [2] = {
          { "Evocation" },                              -- Shift+Q  sustain
          { "Mana Shield" },                            -- Shift+E  defensive
          { "Arcane Power", "Combustion" },             -- Shift+R  burst (after 4 Blast stacks)
          { macro = "PolyFocus" },                      -- Shift+T  control (waits until installed)
          { "Polymorph" },                              -- Shift+F  hard CC
          { "Cone of Cold" },                           -- Shift+G  AoE control: slow a pack
          { racial = true },                            -- Shift+C  racial
          { macro = "BlockBreak", "Ice Block" },        -- Shift+V  emergency
          { macro = "ArmorSwap", "Ice Armor", "Frost Armor", upgrade = true }, -- Shift+1  armor
          { "Mage Armor" },                             -- Shift+2  armor (mana regen)
          { "Arcane Intellect" },                       -- Shift+3  buff
          { "Frost Ward" },                             -- Shift+4  ward
        },
        [4] = {
          { "Blizzard" },                               -- Ctrl+Q  rare: Flamestrike is the ground AoE
          { "Presence of Mind" },                       -- Ctrl+E  second cooldown, paired with Arcane Power (Wowhead: a cooldown, not rotation)
          { macro = "CounterFocus" },                   -- Ctrl+R  rare: focus interrupt
          { "Fire Ward" },                              -- Ctrl+T  rare ward
          { "Dampen Magic" },                           -- Ctrl+F  utility magic
          { "Amplify Magic" },                          -- Ctrl+G  utility magic
          { "Slow Fall" },                              -- Ctrl+C  utility (falls)
          { macro = "Decurse", "Remove Lesser Curse" }, -- Ctrl+V  decurse (friendly target, else you)
          { "Arcane Brilliance" },                      -- Ctrl+1  group buff
          { macro = "ConjureBoth", "Conjure Water" },   -- Ctrl+2  conjure (water, and food once installed)
          { "Conjure Food" },                           -- Ctrl+3  conjure
          { "Conjure Mana Ruby", "Conjure Mana Citrine", "Conjure Mana Jade", "Conjure Mana Agate", upgrade = true }, -- Ctrl+4  mana gem
        },
      },
      controller = {
        pages = {
          [1] = {
            title = "Combat",
            ["RT A"] = { "Arcane Blast", "Fireball" },   -- Q slot 1
            ["RT X"] = { "Arcane Missiles" },            -- E slot 2
            ["RT Y"] = { "Arcane Wrath" },               -- R slot 3
            ["RT B"] = { "Fire Blast" },                 -- F slot 4
            ["LT A"] = { "Scorch" },                     -- T slot 5
            ["LT X"] = { "Pyroblast" },                  -- G reactive proc
            ["LT B"] = { macro = "Counter", "Counterspell" },               -- 3 interrupt
            ["LT Y"] = { "Arcane Explosion" },           -- 2 main AoE
            ["RT Up"] = { "Frostbolt" },                 -- 1 pull, standing
            ["RT Down"] = { "Flamestrike" },             -- 4 ground AoE, standing
            ["RT Left"] = { "Blink" },                   -- C mobility
            ["RT Right"] = { "Frost Nova" },             -- V control (pressed standing as the mob arrives, then step away)
            ["LT Up"] = { "Evocation" },                 -- Shift+Q
            ["LT Right"] = { "Mana Shield" },            -- Shift+E
            ["LT Left"] = { macro = "PolyFocus" },       -- Shift+T
            ["LT Down"] = { "Polymorph" },               -- Shift+F
            ["LT+RT A"] = { macro = "BlockBreak", "Ice Block" }, -- Shift+V
            ["LT+RT X"] = { "Cone of Cold" },            -- Shift+G
            ["LT+RT B"] = { racial = true },
            ["LT+RT Y"] = { "Arcane Power", "Combustion" }, -- Shift+R
            ["LT+RT Up"] = { "Blizzard" },               -- Ctrl+Q
            ["LT+RT Down"] = { "Presence of Mind" },     -- Ctrl+E
            ["LT+RT Left"] = { macro = "CounterFocus" }, -- Ctrl+R
            ["LT+RT Right"] = { "Fire Ward" },           -- Ctrl+T
            ["none Up"] = { "Arcane Intellect" },        -- buff, out of combat
            ["none Left"] = { macro = "Decurse", "Remove Lesser Curse" },   -- decurse, standing
          },
        },
      },
    },
    { key = "fire", name = "Fire", tab = 2,
      keyboard = {
        [1] = {
          { "Fireball" },                               -- Q  slot 1: filler nuke
          { "Scorch", "Frostbolt" },                    -- E  slot 2: keep 5 Scorch stacks, filler when Fire Blast is under 3 s (Frostbolt slow until 22)
          { "Fire Blast" },                             -- R  slot 3: on cooldown, a Heating Up stack each
          { "Blast Wave" },                             -- T  slot 5: spec signature, AoE after Flamestrike (talent, row 4 = 30)
          { "Arcane Missiles" },                        -- F  slot 4: on Missile Barrage (in Wowhead's priority)
          { "Pyroblast" },                              -- G  reactive: at 3 Heating Up; also the pre-cast opener
          { "Blink" },                                  -- C  mobility
          { "Frost Nova" },                             -- V  control: Nova then step back / Polymorph an add
          { "Frostfire Bolt" },                         -- 1  Frostfire build's filler (40); Pyroblast on G is the opener
          { "Arcane Explosion" },                       -- 2  main AoE
          { macro = "Counter", "Counterspell" }, -- 3  interrupt (Counter: stops your cast first)
          { "Flamestrike" },                            -- 4  ground AoE, pre-cast standing
        },
        [2] = {
          { "Evocation" },                              -- Shift+Q  sustain
          { "Mana Shield" },                            -- Shift+E  defensive
          { "Combustion", "Arcane Power" },             -- Shift+R  burst (Scorch and Heating Up stacked)
          { macro = "PolyFocus" },                      -- Shift+T  control (waits until installed)
          { "Polymorph" },                              -- Shift+F  hard CC
          { "Cone of Cold" },                           -- Shift+G  AoE control: slow a pack
          { racial = true },                            -- Shift+C  racial
          { macro = "BlockBreak", "Ice Block" },        -- Shift+V  emergency
          { macro = "ArmorSwap", "Ice Armor", "Frost Armor", upgrade = true }, -- Shift+1  armor
          { "Mage Armor" },                             -- Shift+2  armor (mana regen)
          { "Arcane Intellect" },                       -- Shift+3  buff
          { "Frost Ward" },                             -- Shift+4  ward
        },
        [4] = {
          { "Blizzard" },                               -- Ctrl+Q  rare: Flamestrike is the ground AoE
          false,                                        -- Ctrl+E
          { macro = "CounterFocus" },                   -- Ctrl+R  rare: focus interrupt
          { "Fire Ward" },                              -- Ctrl+T  rare ward
          { "Dampen Magic" },                           -- Ctrl+F  utility magic
          { "Amplify Magic" },                          -- Ctrl+G  utility magic
          { "Slow Fall" },                              -- Ctrl+C  utility (falls)
          { macro = "Decurse", "Remove Lesser Curse" }, -- Ctrl+V  decurse (friendly target, else you)
          { "Arcane Brilliance" },                      -- Ctrl+1  group buff
          { macro = "ConjureBoth", "Conjure Water" },   -- Ctrl+2  conjure (water, and food once installed)
          { "Conjure Food" },                           -- Ctrl+3  conjure
          { "Conjure Mana Ruby", "Conjure Mana Citrine", "Conjure Mana Jade", "Conjure Mana Agate", upgrade = true }, -- Ctrl+4  mana gem
        },
      },
      controller = {
        pages = {
          [1] = {
            title = "Combat",
            ["RT A"] = { "Fireball" },                   -- Q slot 1
            ["RT X"] = { "Scorch", "Frostbolt" },        -- E slot 2
            ["RT Y"] = { "Fire Blast" },                 -- R slot 3
            ["RT B"] = { "Arcane Missiles" },            -- F slot 4
            ["LT A"] = { "Blast Wave" },                 -- T slot 5
            ["LT X"] = { "Pyroblast" },                  -- G reactive proc
            ["LT B"] = { macro = "Counter", "Counterspell" },               -- 3 interrupt
            ["LT Y"] = { "Arcane Explosion" },           -- 2 main AoE
            ["RT Up"] = { "Frostfire Bolt" },            -- 1 Frostfire filler
            ["RT Down"] = { "Flamestrike" },             -- 4 ground AoE, standing
            ["RT Left"] = { "Blink" },                   -- C mobility
            ["RT Right"] = { "Frost Nova" },             -- V control
            ["LT Up"] = { "Evocation" },                 -- Shift+Q
            ["LT Right"] = { "Mana Shield" },            -- Shift+E
            ["LT Left"] = { macro = "PolyFocus" },       -- Shift+T
            ["LT Down"] = { "Polymorph" },               -- Shift+F
            ["LT+RT A"] = { macro = "BlockBreak", "Ice Block" }, -- Shift+V
            ["LT+RT X"] = { "Cone of Cold" },            -- Shift+G
            ["LT+RT B"] = { racial = true },
            ["LT+RT Y"] = { "Combustion", "Arcane Power" }, -- Shift+R
            ["LT+RT Up"] = { "Blizzard" },               -- Ctrl+Q
            ["LT+RT Down"] = { "Frost Ward" },           -- ward (Shift+4)
            ["LT+RT Left"] = { macro = "CounterFocus" }, -- Ctrl+R
            ["LT+RT Right"] = { "Fire Ward" },           -- Ctrl+T
            ["none Up"] = { "Arcane Intellect" },        -- buff, out of combat
            ["none Left"] = { macro = "Decurse", "Remove Lesser Curse" },   -- decurse, standing
          },
        },
      },
    },
    { key = "frost", name = "Frost", tab = 3, default = true },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  -- Shared = Frost.
  keyboard = {
    [1] = {
      { "Frostbolt" },                                  -- Q  slot 1: Frostbolt spam (4)
      { "Cone of Cold", "Fire Blast" },                 -- E  slot 2: Cone at 5 Winter's Chill / on Fingers of Frost (26); Fire Blast before it (shares Ice Lance's cooldown)
      { "Frost Nova" },                                 -- R  slot 3: freeze for Ice Lance and space, starts AoE pulls (10)
      { "Frostfire Bolt", "Fireball", upgrade = true }, -- T  slot 5: nuke for Frost-immune mobs (Fireball before 40)
      { "Arcane Missiles" },                            -- F  slot 4: on Missile Barrage (the deep build takes it) (8)
      { macro = "BlockLance", "Ice Lance" },            -- G  reactive: frozen / Fingers of Frost (Frost talent, row 2 = 20, 8 s cd)
      { "Blink" },                                      -- C  mobility: Blink out of the novaed pack (20)
      { "Flamestrike" },                                -- V  second ground AoE (Frostbolt itself is the snare) (16)
      { "Ice Barrier" },                                -- 1  pre-pull 4 s before, then kept up for Frigid Power (talent, row 6 = 40)
      { "Arcane Explosion" },                           -- 2  main AoE on frozen mobs (14)
      { macro = "Counter", "Counterspell" }, -- 3  interrupt (Counter: stops your cast first) (24)
      { "Blizzard" },                                   -- 4  ground AoE, the 3+ target filler (20)
    },
    -- Bar 2 (Shift): Q sustain, E defensive, R burst, T spec control,
    -- F hard CC, G AoE control, C racial, V emergency, 1-4 armors and buffs.
    [2] = {
      { "Evocation" },                                  -- Shift+Q  sustain
      { "Mana Shield" },                                -- Shift+E  defensive (Ice Barrier is the Frost pre-pull on 1)
      { "Cold Snap" },                                  -- Shift+R  the throughput cooldown: resets Cone of Cold (talent, row 4 = 30)
      { macro = "PolyFocus" },                          -- Shift+T  control (waits until installed)
      { "Polymorph" },                                  -- Shift+F  hard CC
      false,                                            -- Shift+G  (Frost Nova and Cone of Cold are rotation keys)
      { racial = true },                                -- Shift+C  racial
      { macro = "BlockBreak", "Ice Block" },            -- Shift+V  emergency
      { macro = "ArmorSwap", "Ice Armor", "Frost Armor", upgrade = true }, -- Shift+1  armor (ArmorSwap toggles Ice / Mage Armor)
      { "Mage Armor" },                                 -- Shift+2  armor (mana regen)
      { "Arcane Intellect" },                           -- Shift+3  buff
      { "Frost Ward" },                                 -- Shift+4  ward
    },
    -- [3] is the Alt bar (item macros, trinkets, Hearthstone), not set here.
    -- Bar 4 (Ctrl): rare spells, utility magic, group buff and conjures.
    -- Teleports and portals fill the side bars.
    [4] = {
      false,                                            -- Ctrl+Q  (Flamestrike is on V)
      false,                                            -- Ctrl+E
      { macro = "CounterFocus" },                       -- Ctrl+R  rare: focus interrupt
      { "Fire Ward" },                                  -- Ctrl+T  rare ward
      { "Dampen Magic" },                               -- Ctrl+F  utility magic
      { "Amplify Magic" },                              -- Ctrl+G  utility magic
      { "Slow Fall" },                                  -- Ctrl+C  utility (falls)
      { macro = "Decurse", "Remove Lesser Curse" }, -- Ctrl+V  decurse (friendly target, else you)
      { "Arcane Brilliance" },                          -- Ctrl+1  group buff
      { macro = "ConjureBoth", "Conjure Water" },       -- Ctrl+2  conjure (water, and food once installed)
      { "Conjure Food" },                               -- Ctrl+3  conjure
      { "Conjure Mana Ruby", "Conjure Mana Citrine", "Conjure Mana Jade", "Conjure Mana Agate", upgrade = true }, -- Ctrl+4  mana gem
    },
  },

  -- Controller: keys "<layer> <button>", layer none / LT / RT / LT+RT,
  -- button A X B Y or Up Down Left Right (D-pad). Page 1 follows the
  -- controller table of dev/key-roles.md: the rotation on RT and LT face
  -- buttons (thumb free while steering), stand-still casts on the RT D-pad.
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { "Frostbolt" },                     -- Q slot 1
        ["RT X"] = { "Cone of Cold", "Fire Blast" },    -- E slot 2 (face: as the pack arrives)
        ["RT Y"] = { "Frost Nova" },                    -- R slot 3 (face: novas while mobs close in)
        ["RT B"] = { "Arcane Missiles" },               -- F slot 4 (Missile Barrage proc)
        ["LT A"] = { "Frostfire Bolt", "Fireball", upgrade = true }, -- T slot 5
        ["LT X"] = { macro = "BlockLance", "Ice Lance" }, -- G reactive proc
        ["LT B"] = { macro = "Counter", "Counterspell" },                  -- 3 interrupt
        ["LT Y"] = { "Arcane Explosion" },              -- 2 main AoE
        ["RT Up"] = { "Ice Barrier" },                  -- 1 pre-pull shield, standing
        ["RT Down"] = { "Blizzard" },                   -- 4 ground AoE, channelled standing (cursor confirm)
        ["RT Left"] = { "Blink" },                      -- C mobility
        ["RT Right"] = { "Flamestrike" },               -- V second ground AoE, cast standing (cursor confirm)
        ["LT Up"] = { "Evocation" },                    -- Shift+Q
        ["LT Right"] = { "Mana Shield" },               -- Shift+E
        ["LT Left"] = { macro = "PolyFocus" },          -- Shift+T
        ["LT Down"] = { "Polymorph" },                  -- Shift+F
        ["LT+RT A"] = { macro = "BlockBreak", "Ice Block" }, -- Shift+V
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Cold Snap" },                  -- Shift+R
        ["LT+RT Down"] = { "Frost Ward" },              -- ward (Shift+4)
        ["LT+RT Left"] = { macro = "CounterFocus" },    -- Ctrl+R
        ["LT+RT Right"] = { "Fire Ward" },              -- Ctrl+T
        ["none Up"] = { "Arcane Intellect" },           -- buff, out of combat
        ["none Left"] = { macro = "Decurse", "Remove Lesser Curse" },      -- decurse, standing
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
        ["LT+RT Up"] = { overflow = true },
        ["LT+RT Down"] = { overflow = true }, ["LT+RT Left"] = { overflow = true },
        ["LT+RT Right"] = { overflow = true },
      },
    },
    paddles = {},
  },
})
