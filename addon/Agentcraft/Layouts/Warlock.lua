-- Warlock layouts. Data contract: dev/layout-format.md; key roles
-- (rotation slots in press-frequency order, the same on every class):
-- dev/key-roles.md. Keep every value a literal (no variables, no function
-- calls): dev.ps1 rules reads this file without running Lua.
--
-- Rotations: Wowhead's WoW Forever guides (2026-11), which win any
-- disagreement:
--   https://www.wowhead.com/forever/guide/classes/warlock/affliction/rotation-cooldowns-pve-dps
--   https://www.wowhead.com/forever/guide/classes/warlock/affliction/dps-leveling-tips
--   https://www.wowhead.com/forever/guide/classes/warlock/demonology/rotation-cooldowns-pve-dps
--   https://www.wowhead.com/forever/guide/classes/warlock/demonology/dps-leveling-tips
--   https://www.wowhead.com/forever/guide/classes/warlock/destruction/rotation-cooldowns-pve-dps
--   https://www.wowhead.com/forever/guide/classes/warlock/destruction/dps-leveling-tips
-- Forever: Curse of Agony/Doom are Banes (one Bane per warlock per target,
-- plus one Curse), Wrack is the 31-point Affliction channel, Enslave Demon
-- is Subjugate Demon, the Succubus/Incubus is the Sayaad.
--   Affliction leveling (no respec): send the demon; Curse of the Elements
--     first from 40; Corruption on every mob, Bane of Agony if it lives,
--     Immolate on high-health mobs (rank 1 is most of your damage early),
--     Siphon Life once talented; filler wand or Drain Life before 30, Drain
--     Life from 30, Wrack (40) on the pulls you start fresh; finish with the
--     wand; Life Tap when health is spare; Drain Soul (rank 1) to finish for
--     a shard. Two mobs: DoT and Fear one. AoE: Corruption each, Hellfire.
--   Affliction raid (Wrack build): Shadow Bolt pre-pull; Amplify Curse +
--     Bane of Agony, your Curse, Corruption, Siphon Life, Shadow Bolt only
--     on a Shadow Trance proc, Life Tap after a full Wrack, Wrack. Demonic
--     Sacrifice (Imp). SM Ruin build: Bane, Curse, Corruption, Siphon Life,
--     Immolate, Shadow Bolt filler.
--   Demonology leveling: demon in; Searing Pain brands its target (Demonic
--     Brand, passive talent row 3 = 25), rebrand after 6 demon attacks; Curse of the Elements (40),
--     Corruption, Bane of Agony, Immolate on high-health mobs; wand before
--     30, Drain Life from 30; finish with the wand; Life Tap. 40: Demonic
--     Sacrifice the Imp, Sayaad out, Soul Link. Shadow Bolt only to open.
--   Demonology raid: Soul Fire (or Shadow Bolt) pre-pull; Searing Pain if
--     the brand is down, Bane (Doom with 1 min+ left, else Agony), Curse,
--     Immolate, Soul Fire under Decimation (Fire, below 35%), Corruption,
--     Life Tap; filler Searing Pain (Fire) or Shadow Bolt (Shadow).
--   Destruction raid: Soul Fire pre-pull; Bane (Doom, else Amplify Curse +
--     Agony), Curse, Immolate, Corruption, Conflagrate and Shadowburn on
--     cooldown, Life Tap, Incinerate (Shadow Bolt before 40). Two targets:
--     Bane of Havoc on the second. Leveling solo: Immolate (not as the
--     opener), Bane of Agony, Corruption on long mobs, Drain Life filler,
--     Conflagrate near Immolate's end, Shadowburn or the wand to finish.
--   Every spec: Hellfire is the AoE, Rain of Fire when you can't stand in
--     the pack; Death Coil escape/heal; Shadow Ward before Shadow hits;
--     Howl of Terror for pulls gone wrong. Skip: Curse of Weakness, Drain
--     Mana, Subjugate Demon, Detect Invisibility (no key; Apply's side
--     bars and the controller catch-all still find them).
--
-- Placement (dev/key-roles.md): Affliction and Demonology share one layout
-- (fallback chains: T is Siphon Life or Searing Pain, F is Wrack or
-- Immolate, Shift+E the spec's talent); Destruction overrides Bar 1, Bar 2,
-- Bar 4 and controller page 1. Same on all three: G Life Tap, C Death Coil,
-- V the wand, 2 Hellfire, 3 PetSpecial, Shift+T Drain Soul, Shift+R Soul
-- Fire, Ctrl+Q-T the curses and Doom.
--   Aff/Demo plain: Q Drain Life, E Corruption, R Bane of Agony, F Wrack /
--     Immolate, T Siphon Life / Searing Pain, G Life Tap, C Death Coil,
--     V wand (filler to 30, finisher at every level), 1 Shadow Bolt (the
--     pre-pull cast, Shadow Trance procs, Demo Shadow filler), 2 Hellfire,
--     3 PetSpecial (Spell Lock), 4 Rain of Fire. Before Drain Life (14) Q is
--     empty: Shadow Bolt (1) and the wand (V) are the early filler. Aff
--     loses Immolate's key at Wrack (40): the Wrack build drops it.
-- Talents (dev/forever-talents.md; row r = level 10 + 5r, earlier with the
-- Talented legacy perk): Amplify Curse row 2 = 20, Curse of Exhaustion row
-- 3 = 25 (no key), Siphon Life row 4 = 30, Wrack row 6 = 40; Demonic
-- Sacrifice row 2 = 20, Fel Domination row 3 = 25, Soul Link row 4 = 30;
-- Shadowburn row 2 = 20, Conflagrate row 3 = 25, Bane of Havoc row 4 = 30,
-- Incinerate row 6 = 40. Demonic Pact (Demonology row 6) is passive: no
-- button.
--   Destro plain: Q Incinerate / Shadow Bolt, E Immolate, R Conflagrate,
--     F Corruption, T Shadowburn, 1 Bane of Agony, 4 Bane of Havoc (the
--     second target), the rest as above; Drain Life on Shift+Q (solo
--     filler and self-heal), Amplify Curse on Shift+E, Health Funnel on
--     Ctrl+C and Rain of Fire on Ctrl+V.
-- Warlocks have no stance paging. Pet abilities and pet commands stay on the
-- shared pet bar keys (Keybinds), so the layout names none; PetSpecial
-- casts the current demon's control spell from a normal key.
local _, ns = ...

ns.Layout.Register("WARLOCK", {
  specs = {
    { key = "affliction", name = "Affliction", tab = 1, default = true },
    { key = "demonology", name = "Demonology", tab = 2 },
    { key = "destruction", name = "Destruction", tab = 3,
      keyboard = {
        -- Destruction Bar 1: Wowhead's priority, filler on Q.
        [1] = {
          { "Incinerate", "Shadow Bolt" },                -- Q  rotation slot 1: filler; Incinerate (talent, row 6 = 40) replaces Shadow Bolt (1)
          { "Immolate" },                                 -- E  rotation slot 2: the burn Conflagrate and Incinerate need (1)
          { "Conflagrate" },                              -- R  rotation slot 3: on cooldown (talent, row 3 = 25)
          { "Shadowburn" },                               -- T  rotation slot 5: on cooldown; the killing blow while leveling (talent, row 2 = 20)
          { "Corruption" },                               -- F  rotation slot 4: kept on the boss; long-lived mobs (4)
          { "Life Tap" },                                 -- G  reactive: health > mana, and while moving (6)
          { "Death Coil" },                               -- C  escape: horror + heal (42)
          { "Shoot" },                                    -- V  wand: finish a low mob (Wowhead), every spec on V
          { "Bane of Agony" },                            -- 1  opener: the Bane is the first cast of the pull (8)
          { "Hellfire" },                                 -- 2  main AoE (30)
          { macro = "PetSpecial" },                       -- 3  interrupt: Spell Lock (Felhunter)
          { "Bane of Havoc" },                            -- 4  secondary AoE: on the second target or one mob of a pack (talent, row 4 = 30)
        },
        [2] = {
          { macro = "DrainLife", "Drain Life" },          -- Shift+Q  self-heal: the solo filler from 30, and when a mob turns on you (14)
          { "Amplify Curse" },                            -- Shift+E  spec cooldown: on the Agony after the last Doom (Affliction talent, row 2 = 20)
          { "Soul Fire", "Inferno" },                     -- Shift+R  burst: the pre-pull Soul Fire (48)
          { macro = "DrainSoul", "Drain Soul" },          -- Shift+T  shards for Shadowburn and Soul Fire: finish a mob with it (10)
          { "Fear" },                                     -- Shift+F  hard CC (8)
          { "Howl of Terror" },                           -- Shift+G  AoE control (40)
          { racial = true },                              -- Shift+C  racial
          { "Shadow Ward" },                              -- Shift+V  emergency: before a known Shadow hit (32)
          { "Demon Armor", "Demon Skin", upgrade = true }, -- Shift+1  armor (1 / 20)
          { "Create Healthstone" },                       -- Shift+2  create (10)
          { "Create Soulstone" },                         -- Shift+3  create (18)
          { "Unending Breath" },                          -- Shift+4  buff (16)
        },
        [4] = {
          { "Curse of the Elements" },                    -- Ctrl+Q  your Curse: first from 40, casters in the raid (20)
          { "Curse of Recklessness" },                    -- Ctrl+E  your Curse with melee; calls back a feared mob (14)
          { "Curse of Tongues" },                         -- Ctrl+R  vs casters (26)
          { "Bane of Doom" },                             -- Ctrl+T  the Bane with a minute or more left, once a minute (60)
          { "Create Spellstone", "Create Firestone" },    -- Ctrl+F  weapon stone: Firestone (28) until Spellstone (36)
          { "Eye of Kilrogg" },                           -- Ctrl+G  scout (22)
          { "Health Funnel" },                            -- Ctrl+C  pet heal (12): Shift+Q holds Drain Life here
          { "Rain of Fire" },                             -- Ctrl+V  ranged AoE, only when you can't stand in the pack (20)
          { "Summon Imp" },                               -- Ctrl+1  summon (1)
          { "Summon Voidwalker" },                        -- Ctrl+2  summon (10)
          { "Summon Succubus", "Summon Incubus" }, -- Ctrl+3  the Sayaad (20)
          { "Summon Felhunter" },                         -- Ctrl+4  summon (30)
        },
      },
      controller = {
        pages = {
          [1] = {
            title = "Combat",
            ["RT A"] = { "Incinerate", "Shadow Bolt" },             -- Q  slot 1 filler
            ["RT X"] = { "Immolate" },                              -- E  slot 2
            ["RT Y"] = { "Conflagrate" },                           -- R  slot 3
            ["RT B"] = { "Corruption" },                            -- F  slot 4
            ["LT A"] = { "Shadowburn" },                            -- T  slot 5
            ["LT X"] = { "Life Tap" },                              -- G  reactive, while moving
            ["LT B"] = { macro = "PetSpecial" },                    -- 3  interrupt
            ["LT Y"] = { "Hellfire" },                              -- 2  main AoE
            ["RT Up"] = { "Bane of Agony" },                        -- 1  opener
            ["RT Down"] = { "Bane of Havoc" },                      -- 4  second target
            ["RT Left"] = { "Death Coil" },                         -- C  escape
            ["RT Right"] = { "Shoot" },                             -- V  wand finisher
            ["LT Up"] = { macro = "DrainLife", "Drain Life" },      -- Shift+Q self-heal
            ["LT Right"] = { "Amplify Curse" },                     -- Shift+E
            ["LT Left"] = { macro = "DrainSoul", "Drain Soul" },    -- Shift+T shards (a channel: standing anyway)
            ["LT Down"] = { "Fear" },                               -- Shift+F
            ["LT+RT A"] = { "Shadow Ward" },                        -- Shift+V
            ["LT+RT X"] = { "Howl of Terror" },                     -- Shift+G
            ["LT+RT B"] = { racial = true },
            ["LT+RT Y"] = { "Soul Fire", "Inferno" },               -- Shift+R
            ["LT+RT Up"] = { "Curse of the Elements" },             -- Ctrl+Q
            ["LT+RT Down"] = { "Curse of Recklessness" },           -- Ctrl+E
            ["LT+RT Left"] = { "Curse of Tongues" },                -- Ctrl+R
            ["LT+RT Right"] = { "Bane of Doom" },                   -- Ctrl+T
            ["none Up"] = { "Demon Armor", "Demon Skin", upgrade = true }, -- armor, out of combat
            ["none Left"] = { "Health Funnel" },                    -- pet heal, standing
            ["none Right"] = { "Rain of Fire" },                    -- ranged AoE (cursor confirm)
          },
        },
      },
    },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  -- Shared by Affliction and Demonology.
  keyboard = {
    [1] = {
      { macro = "DrainLife", "Drain Life" },                -- Q  rotation slot 1: the leveling filler from 30, wand or it before (14)
      { "Corruption" },                                     -- E  rotation slot 2: on every mob, kept on the boss (4)
      { "Bane of Agony" },                                  -- R  rotation slot 3: first in the raid priority, on mobs that live (8)
      { "Siphon Life", "Searing Pain" },                    -- T  rotation slot 5: Aff third DoT (talent, row 4 = 30) / Demo Demonic Brand, rebrand often (18)
      { macro = "Wrack", "Wrack", "Immolate" },             -- F  rotation slot 4: Aff filler Wrack (talent, row 6 = 40); Immolate before it and for Demo (1)
      { "Life Tap" },                                       -- G  reactive: health to spare, after a full Wrack, while moving (6)
      { "Death Coil" },                                     -- C  escape: horror + heal (42)
      { "Shoot" },                                          -- V  wand: filler before 30 and the finisher at every level (Wowhead)
      { "Shadow Bolt" },                                    -- 1  opener: the pre-pull cast; Shadow Trance procs; Demo Shadow filler (1)
      { "Hellfire" },                                       -- 2  main AoE (30)
      { macro = "PetSpecial" },                             -- 3  interrupt: Spell Lock / Seduction / Sacrifice (macro only)
      { "Rain of Fire" },                                   -- 4  ground AoE when you can't stand in the pack (20)
    },
    -- Bar 2 (Shift): Q pet sustain, E spec cooldown, R burst, T shards,
    -- F hard CC, G AoE control, C racial, V emergency, 1-4 armor, stones, breath.
    [2] = {
      { "Health Funnel" },                                    -- Shift+Q  sustain: heal the demon that tanks for you (12)
      { "Amplify Curse", "Fel Domination", "Bane of Havoc" }, -- Shift+E  spec cooldown, all talents: Aff Amplify Curse on Agony (20) / Demo Fel Domination (25) / Destro Bane of Havoc (30)
      { "Soul Fire", "Inferno" },                             -- Shift+R  burst: Demo Soul Fire pre-pull and under Decimation (48)
      { macro = "DrainSoul", "Drain Soul" },                  -- Shift+T  shards: finish a mob with rank 1 when you need one (10); Subjugate Demon is skipped
      { "Fear" },                                             -- Shift+F  hard CC: Fear one of two mobs (8)
      { "Howl of Terror" },                                   -- Shift+G  AoE control: pulls gone wrong (40)
      { racial = true },                                      -- Shift+C  racial
      { "Shadow Ward" },                                      -- Shift+V  emergency: before a known Shadow hit (32)
      { "Demon Armor", "Demon Skin", upgrade = true },        -- Shift+1  armor (1 / 20)
      { "Create Healthstone" },                               -- Shift+2  create (10)
      { "Create Soulstone" },                                 -- Shift+3  create (18)
      { "Unending Breath" },                                  -- Shift+4  buff (16)
    },
    -- [3] is the Alt bar (consumables, Fish, Bait, Hearthstone), not set here.
    -- Bar 4 (Ctrl): your Curse, the long Bane, tools and the summons.
    [4] = {
      { "Curse of the Elements" },                            -- Ctrl+Q  your Curse: first from 40, casters in the raid (20)
      { "Curse of Recklessness" },                            -- Ctrl+E  your Curse with melee; calls back a feared mob (14)
      { "Curse of Tongues" },                                 -- Ctrl+R  vs casters (26)
      { "Bane of Doom" },                                     -- Ctrl+T  Demo/SM Ruin Bane with a minute or more left (60)
      { "Create Spellstone", "Create Firestone" },            -- Ctrl+F  weapon stone: Firestone (28) until Spellstone (36)
      { "Eye of Kilrogg" },                                   -- Ctrl+G  scout (22)
      { "Soul Link" },                                        -- Ctrl+C  Demo talent buff (row 4 = 30): keep it up (Wowhead)
      { "Demonic Sacrifice" },                                -- Ctrl+V  sacrifice the Imp (Demo talent, row 2 = 20; Aff Wrack, Demo Fire/Shadow builds)
      { "Summon Imp" },                                       -- Ctrl+1  summon (1)
      { "Summon Voidwalker" },                                -- Ctrl+2  summon (10)
      { "Summon Succubus", "Summon Incubus" }, -- Ctrl+3  the Sayaad (20)
      { "Summon Felhunter" },                                 -- Ctrl+4  summon (30)
    },
  },

  -- Controller: keys "<layer> <button>", layer none / LT / RT / LT+RT,
  -- button A X B Y or Up Down Left Right (D-pad). The Top bar's face buttons
  -- are fixed.
  controller = {
    pages = {
      -- Page 1 (Aff/Demo): rotation slots 1-4 on RT face, slot 5, reactive,
      -- interrupt and AoE on LT face; standing casts on the D-pad.
      {
        title = "Combat",
        ["RT A"] = { macro = "DrainLife", "Drain Life" },                -- Q  slot 1 filler
        ["RT X"] = { "Corruption" },                                     -- E  slot 2
        ["RT Y"] = { "Bane of Agony" },                                  -- R  slot 3
        ["RT B"] = { macro = "Wrack", "Wrack", "Immolate" },             -- F  slot 4
        ["LT A"] = { "Siphon Life", "Searing Pain" },                    -- T  slot 5
        ["LT X"] = { "Life Tap" },                                       -- G  reactive, while moving
        ["LT B"] = { macro = "PetSpecial" },                             -- 3  interrupt
        ["LT Y"] = { "Hellfire" },                                       -- 2  main AoE
        ["RT Up"] = { "Shadow Bolt" },                                   -- 1  opener (a cast: standing anyway)
        ["RT Down"] = { "Rain of Fire" },                                -- 4  ground AoE (cursor confirm)
        ["RT Left"] = { "Death Coil" },                                  -- C  escape
        ["RT Right"] = { "Shoot" },                                      -- V  wand finisher
        ["LT Up"] = { "Health Funnel" },                                 -- Shift+Q
        ["LT Right"] = { "Amplify Curse", "Fel Domination", "Bane of Havoc" }, -- Shift+E
        ["LT Left"] = { macro = "DrainSoul", "Drain Soul" },             -- Shift+T shards (a channel: standing anyway)
        ["LT Down"] = { "Fear" },                                        -- Shift+F
        ["LT+RT A"] = { "Shadow Ward" },                                 -- Shift+V
        ["LT+RT X"] = { "Howl of Terror" },                              -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Soul Fire", "Inferno" },                        -- Shift+R
        ["LT+RT Up"] = { "Curse of the Elements" },                      -- Ctrl+Q
        ["LT+RT Down"] = { "Curse of Recklessness" },                    -- Ctrl+E
        ["LT+RT Left"] = { "Curse of Tongues" },                         -- Ctrl+R
        ["LT+RT Right"] = { "Bane of Doom" },                            -- Ctrl+T
        ["none Up"] = { "Demon Armor", "Demon Skin", upgrade = true },   -- armor, out of combat
        ["none Left"] = { "Soul Link" },                                 -- Demo buff, out of combat
        ["none Down"] = { "Demonic Sacrifice" },                         -- sacrifice, out of combat
      },
      -- Page 2: stones and travel; the shared Utility buttons
      -- (Layouts/Shared.lua) add Hearthstone, trinkets, consumables,
      -- fishing, camp, Mount and professions.
      {
        title = "Utility",
        ["RT A"] = { "Create Healthstone" },
        ["RT X"] = { "Create Soulstone" },
        ["RT B"] = { "Unending Breath" },
        ["RT Y"] = { "Eye of Kilrogg" },
        ["RT Left"] = { "Create Spellstone", "Create Firestone" },
        ["RT Right"] = { "Ritual of Summoning" },
        ["RT Down"] = { overflow = true },
      },
      -- Page 3: summons, pet autocast, Steam Deck helpers and the catch-all.
      {
        title = "Demons & Extras",
        ["RT A"] = { "Summon Imp" },
        ["RT X"] = { "Summon Voidwalker" },
        ["RT B"] = { "Summon Succubus", "Summon Incubus" },
        ["RT Y"] = { "Summon Felhunter" },
        ["RT Up"] = { overflow = true },
        ["RT Down"] = { overflow = true },
        ["RT Left"] = { overflow = true },
        ["RT Right"] = { overflow = true },
        -- LT: every ability your demon knows that can autocast, one on/off
        -- toggle each (install the Auto macros on the Macros page).
        ["LT A"] = { petauto = true }, ["LT X"] = { petauto = true },
        ["LT B"] = { petauto = true }, ["LT Y"] = { petauto = true },
        ["LT Up"] = { petauto = true }, ["LT Down"] = { petauto = true },
        ["LT Left"] = { petauto = true }, ["LT Right"] = { petauto = true },
        ["none Up"] = { macro = "Reload" },
        ["none Down"] = { macro = "Follow" },
        ["none Left"] = { macro = "Focus" },
        ["none Right"] = { macro = "Assist" },
        ["LT+RT A"] = { macro = "Skull" },
        ["LT+RT X"] = { overflow = true }, ["LT+RT B"] = { overflow = true },
        ["LT+RT Up"] = { overflow = true },
        ["LT+RT Down"] = { overflow = true }, ["LT+RT Left"] = { overflow = true },
        ["LT+RT Right"] = { overflow = true },
      },
    },
    paddles = {},
  },
})
