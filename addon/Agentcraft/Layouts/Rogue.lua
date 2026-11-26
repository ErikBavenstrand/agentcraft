-- Rogue layouts. Data contract: dev/layout-format.md; key roles shared by
-- every class: dev/key-roles.md. Keep every value a literal (no variables,
-- no function calls): dev.ps1 rules reads this file without running Lua.
--
-- Rotations (WoW Forever, checked against Wowhead 2026-11-26; Wowhead wins
-- any disagreement). Sources:
--   https://www.wowhead.com/forever/guide/classes/rogue/assassination/rotation-cooldowns-pve-dps
--   https://www.wowhead.com/forever/guide/classes/rogue/combat/rotation-cooldowns-pve-dps
--   https://www.wowhead.com/forever/guide/classes/rogue/subtlety/rotation-cooldowns-pve-dps
--   and https://www.wowhead.com/forever/guide/classes/rogue/<spec>/dps-leveling-tips
-- Where Wowhead is silent: ConquestCapped Forever rotation pages (Rupture,
-- Cheap Shot openers), warcraft.wiki.gg Rogue abilities (Forever) and Shank.
-- Forever facts: Shank (trainer, 24) costs 5 energy, gives 15 back, 10 s
-- cooldown; Venom (passive talent) turns it into a poison window, Boot
-- Knife (passive, Deep Subtlety) makes it give 2 CP; poisons are items; no Envenom; Ghostly
-- Strike lets Garrote be used in combat; Death Mark is Deep Subtlety's
-- excess-CP finisher (in place of Eviscerate); Premeditation has a 2 min
-- cooldown. Trainer levels (Wowhead): Sinister Strike/Eviscerate/Stealth 1,
-- Backstab/Pick Pocket 4, Gouge 6, Evasion 8, Sprint/Slice and Dice/Sap 10,
-- Kick 12, Garrote/Expose Armor 14, Feint 16, Ambush 18, Rupture 20, Vanish
-- 22, Shank 24, Cheap Shot 26, Kidney Shot 30, Blind 34. Leveling 1-29 is
-- Combat for everyone (the default spec); Subtlety from Ambush/Hemorrhage,
-- Assassination from Mutilate.
-- Talent rows (dev/forever-talents.md; row r = level 10 + 5r, earlier with
-- the Talented perk): Riposte row 2 = 20, Blade Flurry row 4 = 30,
-- Adrenaline Rush row 6 = 40 (Combat); Cold Blood row 3 = 25, Mutilate
-- row 6 = 40 (Assassination); Premeditation row 2 = 20, Ghostly Strike
-- row 3 = 25, Preparation and Hemorrhage row 4 = 30, Death Mark row 6 = 40
-- (Subtlety). Venom and Boot Knife are passive: no button.
-- Every spec (Wowhead): Slice and Dice up (at as few CP as possible) >
-- builder > excess CP into the finisher at 4+ CP > Shank on cooldown. No
-- real AoE: Blade Flurry (Combat) is the cleave. Interrupts: Kick, Kidney
-- Shot, Gouge, Vanish + Cheap Shot.
--
--   Combat (Sinister Strike, or Backstab in the dagger build; Riposte,
--     Blade Flurry, Adrenaline Rush, Cold Blood): Slice and Dice > Sinister
--     Strike / Backstab > Eviscerate > Shank on cooldown. Opener: Blade
--     Flurry, Sinister Strike, Vanish + Garrote, Shank, Slice and Dice,
--     Adrenaline Rush, Sinister Strike to 5 CP, Cold Blood + Eviscerate.
--     Cooldowns: Blade Flurry + Adrenaline Rush together; Cold Blood on the
--     first 5-point Eviscerate. Leveling: spam Sinister Strike, Riposte (off
--     the global cooldown, after a parry) is the "bread and butter",
--     Eviscerate on a dying mob, Slice and Dice with another mob nearby.
--   Assassination (Mutilate, Cold Blood): Slice and Dice > Mutilate >
--     Eviscerate (4+ CP) > Shank on cooldown (Venom). No AoE. Opener:
--     Mutilate, Vanish + Garrote, Shank, Slice and Dice, Mutilate to 4-5 CP,
--     Cold Blood + Eviscerate; Cold Blood is its only cooldown. Leveling:
--     Ambush, then Sinister Strike (Mutilate once known), Eviscerate / Slice
--     and Dice. Rupture is not in Wowhead's priority (spare finisher on T).
--   Subtlety (Hemorrhage, Ghostly Strike, Premeditation, Preparation; Deep
--     Sub adds Death Mark + Boot Knife, Hemo Seal Fate uses Eviscerate +
--     Cold Blood): Ghostly Strike to reapply Garrote (Vanish the failsafe) >
--     Slice and Dice > Rupture (3-4+ CP) > Hemorrhage > Death Mark or
--     Eviscerate with excess CP (4+) > Shank on cooldown > Premeditation on
--     cooldown. Opener: Premeditation before the pull, Vanish + Garrote,
--     (Preparation, Premeditation, Death Mark), Hemorrhage, Shank, Rupture.
--     Leveling: Ambush opener, then Sinister Strike (Hemorrhage once known),
--     Eviscerate / Slice and Dice.
--
-- Keyboard (Bar 1, all specs): Q builder (slot 1), E Shank (slot 2: every
-- 10 s; Backstab until 24), R Eviscerate (slot 3: the excess-CP finisher),
-- F Slice and Dice (slot 4), T Rupture (slot 5, finisher), G proc, 1 pull,
-- 2 AoE, 3 Kick, 4 Feint (no ground AoE: Feint is the big-pull button),
-- C Sprint, V Gouge (no snare). Combat overrides Q for the Strike macro and
-- gives Cold Blood its own key; Subtlety overrides Bar 1, Stealth and Ctrl.
-- Each spec's builder takes its startattack macro once installed (Strike,
-- MutiAttack, HemoAttack) and Stealth takes StealthOn (Wowhead's Classic
-- rogue macro guide, wowhead.com/classic/guide=8827).
--
-- Stealth pages Bar 1 (bonus bar offset 1, slots 73-84; unverified on the
-- Forever client): E Garrote, R Ambush (Premed macro), 1 Cheap Shot; keys
-- whose spell works in and out of Stealth repeat the base entry. Stealth
-- itself sits on Shift+1 (the buff/stance row), which doesn't page.
local _, ns = ...

ns.Layout.Register("ROGUE", {
  specs = {
    { key = "assassination", name = "Assassination", tab = 1,
      -- Controller: no AoE, so LT Y holds Cheap Shot (leveling stun opener)
      -- and the two openers sit on RT Up (Ambush) and RT Down (Garrote).
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { macro = "MutiAttack", "Mutilate", "Sinister Strike" }, -- Q  slot 1: builder (SS until Mutilate, row 6 = 40)
        ["RT X"] = { "Shank", "Backstab" },                -- E  slot 2: Shank on cooldown (Venom window)
        ["RT Y"] = { "Eviscerate" },                       -- R  slot 3: finisher at 4-5 CP
        ["RT B"] = { "Slice and Dice" },                   -- F  slot 4: keep it up
        ["LT A"] = { "Rupture" },                          -- T  slot 5: spare finisher (not in Wowhead)
        ["LT X"] = { "Riposte", "Ghostly Strike" },        -- G  proc (hybrid builds)
        ["LT B"] = { "Kick" },                             -- 3  interrupt
        ["LT Y"] = { "Cheap Shot" },                       -- 2  no AoE: leveling stun opener
        ["RT Up"] = { macro = "Premed", "Ambush" },        -- 1  opener (leveling)
        ["RT Down"] = { macro = "PickGarrote", "Garrote" }, -- 4  Vanish + Garrote opener (no ground AoE)
        ["RT Left"] = { "Sprint" },                        -- C  mobility
        ["RT Right"] = { "Gouge" },                        -- V  no snare: Gouge stops the target
        ["LT Down"] = { "Sap" },                           -- Shift F  hard CC
        ["LT Left"] = { "Kidney Shot" },                   -- Shift T  control
        ["LT Right"] = { "Evasion" },                      -- Shift E  defensive
        ["none Up"] = { macro = "StealthOn", "Stealth" },  -- stance
        ["none Left"] = { "Pick Pocket" },
        ["none Right"] = { "Throw", "Shoot Bow", "Shoot Crossbow", "Shoot Gun" }, -- ranged pull, standing
        ["none Down"] = { "Distract" },
        ["LT+RT A"] = { macro = "Poof", "Vanish" },        -- Shift V  emergency
        ["LT+RT X"] = { "Blind" },                         -- Shift G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { macro = "Blades", "Adrenaline Rush", "Cold Blood", "Preparation" }, -- Shift R  burst
        ["LT+RT Down"] = { "Expose Armor" },               -- Ctrl E  (Expose build at 5 CP)
        ["LT+RT Left"] = { "Feint" },                      -- Ctrl R  threat drop
      } } } },
    { key = "combat", name = "Combat", tab = 2, default = true, keyboard = {
      [1] = {
        { macro = "Strike", "Sinister Strike" },        -- Q  slot 1: builder (Strike adds Riposte)
        { "Shank", "Backstab" },                        -- E  slot 2: Shank on cooldown (Backstab until 24)
        { "Eviscerate" },                               -- R  slot 3: excess CP (4+ in the dagger build)
        { "Rupture" },                                  -- T  slot 5: rarely (not in Wowhead's priority)
        { "Slice and Dice" },                           -- F  slot 4: keep it up
        { "Riposte" },                                  -- G  proc: after a parry (leveling bread and butter)
        { "Sprint" },                                   -- C  mobility
        { "Gouge" },                                    -- V  no snare: Gouge stops the target
        { "Throw", "Shoot Bow", "Shoot Crossbow", "Shoot Gun" }, -- 1  ranged pull
        { "Blade Flurry" },                             -- 2  AoE: cleave
        { "Kick" },                                     -- 3  interrupt
        { "Feint" },                                    -- 4  big pulls: drop threat early
      },
      -- Combat has two burst presses (Wowhead): Blade Flurry + Adrenaline
      -- Rush together on Shift+R, and Cold Blood on the first 5-point
      -- Eviscerate, once or twice a fight, on Ctrl+R.
      [2] = {
        false,                                          -- Shift+Q  self-heal (rogues have none)
        { "Evasion" },                                  -- Shift+E  defensive
        { macro = "Blades", "Adrenaline Rush", "Preparation" }, -- Shift+R  burst
        { "Kidney Shot" },                              -- Shift+T  control
        { "Sap" },                                      -- Shift+F  hard CC (from Stealth)
        { "Blind" },                                    -- Shift+G  control
        { racial = true },                              -- Shift+C  racial
        { macro = "Poof", "Vanish" },                   -- Shift+V  emergency
        { macro = "StealthOn", "Stealth" },             -- Shift+1  stance row
        false, false, false,                            -- Shift+2-4 (poisons are items)
      },
      [4] = {
        false,                                          -- Ctrl+Q  (no secondary attack)
        { "Expose Armor" },                             -- Ctrl+E  secondary debuff
        { "Cold Blood" },                               -- Ctrl+R  first 5-point Eviscerate (row 3 = 25)
        false,                                          -- Ctrl+T  free
        { "Pick Pocket" },                              -- Ctrl+F  (from Stealth)
        { "Distract" },                                 -- Ctrl+G  utility
        { "Pick Lock" },                                -- Ctrl+C  utility
        { "Disarm Trap" },                              -- Ctrl+V  utility
        false, false, false, false,                     -- Ctrl+1-4
      },
    } },
    { key = "subtlety", name = "Subtlety", tab = 3,
      keyboard = {
        -- Subtlety presses more buttons: Garrote in combat (after Ghostly
        -- Strike) and Premeditation on cooldown. Death Mark is Deep Sub's
        -- excess-CP finisher (Wowhead), so it takes Eviscerate's key.
        [1] = {
          { macro = "HemoAttack", "Hemorrhage", "Sinister Strike" }, -- Q  slot 1: builder (SS until Hemorrhage, row 4 = 30)
          { "Shank", "Backstab" },                      -- E  slot 2: Shank on cooldown (Boot Knife: 2 CP)
          { "Death Mark", "Eviscerate" },               -- R  slot 3: excess CP at 4+ (Eviscerate in Hemo Seal Fate)
          { "Rupture" },                                -- T  slot 5: keep the bleed up
          { "Slice and Dice" },                         -- F  slot 4: keep it up
          { "Ghostly Strike" },                         -- G  reapplies Garrote in combat
          { "Sprint" },                                 -- C  mobility
          { "Gouge" },                                  -- V  no snare: Gouge stops the target
          { macro = "PickGarrote", "Garrote" },         -- 1  opener; again after Ghostly Strike
          { "Premeditation" },                          -- 2  no AoE: Premeditation before the pull and on cooldown
          { "Kick" },                                   -- 3  interrupt
          { "Feint" },                                  -- 4  big pulls: drop threat early
        },
        -- Ctrl as shared, plus the pull (1 holds Garrote).
        [4] = {
          false,                                        -- Ctrl+Q
          { "Expose Armor" },                           -- Ctrl+E  secondary debuff
          false,                                        -- Ctrl+R
          false,                                        -- Ctrl+T  free
          { "Pick Pocket" },                            -- Ctrl+F  (from Stealth)
          { "Distract" },                               -- Ctrl+G
          { "Pick Lock" },                              -- Ctrl+C
          { "Disarm Trap" },                            -- Ctrl+V
          { "Throw", "Shoot Bow", "Shoot Crossbow", "Shoot Gun" }, -- Ctrl+1  ranged pull (1 holds Garrote)
          false, false, false,                          -- Ctrl+2-4
        },
        stances = {
          stealth = {
            offset = 1, label = "Stealth",
            { macro = "HemoAttack", "Hemorrhage", "Sinister Strike" }, -- Q  same as base
            { "Cheap Shot" },                           -- E  stun opener (1 holds Garrote)
            { macro = "Premed", "Ambush" },             -- R  dagger opener
            false,                                      -- T
            false,                                      -- F
            { "Ghostly Strike" },                       -- G  same as base
            { "Sprint" },                               -- C  same as base
            false,                                      -- V
            { macro = "PickGarrote", "Garrote" },       -- 1  opener (same key as base)
            { "Premeditation" },                        -- 2  opener: 2 CP (same as base)
            { "Kick" },                                 -- 3  same as base
            false,                                      -- 4
          },
        },
      },
      -- Controller: Death Mark / Eviscerate on RT Y, Premeditation on LT Y
      -- (no AoE), Garrote on the opener button, Ambush on RT Down.
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { macro = "HemoAttack", "Hemorrhage", "Sinister Strike" }, -- Q  slot 1: builder
        ["RT X"] = { "Shank", "Backstab" },                -- E  slot 2: Shank on cooldown
        ["RT Y"] = { "Death Mark", "Eviscerate" },         -- R  slot 3: excess-CP finisher
        ["RT B"] = { "Slice and Dice" },                   -- F  slot 4: keep it up
        ["LT A"] = { "Rupture" },                          -- T  slot 5: keep the bleed up
        ["LT X"] = { "Ghostly Strike" },                   -- G  reapplies Garrote
        ["LT B"] = { "Kick" },                             -- 3  interrupt
        ["LT Y"] = { "Premeditation" },                    -- 2  no AoE: Premeditation on cooldown
        ["RT Up"] = { macro = "PickGarrote", "Garrote" },  -- 1  opener; again after Ghostly Strike
        ["RT Down"] = { macro = "Premed", "Ambush" },      -- 4  leveling opener (no ground AoE)
        ["RT Left"] = { "Sprint" },                        -- C  mobility
        ["RT Right"] = { "Gouge" },                        -- V  no snare: Gouge stops the target
        ["LT Up"] = { "Cheap Shot" },                      -- Shift Q (no self-heal): dungeon stun opener
        ["LT Down"] = { "Sap" },                           -- Shift F  hard CC
        ["LT Left"] = { "Kidney Shot" },                   -- Shift T  control
        ["LT Right"] = { "Evasion" },                      -- Shift E  defensive
        ["none Up"] = { macro = "StealthOn", "Stealth" },  -- stance
        ["none Left"] = { "Pick Pocket" },
        ["none Right"] = { "Throw", "Shoot Bow", "Shoot Crossbow", "Shoot Gun" }, -- ranged pull, standing
        ["none Down"] = { "Distract" },
        ["LT+RT A"] = { macro = "Poof", "Vanish" },        -- Shift V  emergency
        ["LT+RT X"] = { "Blind" },                         -- Shift G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { macro = "Blades", "Adrenaline Rush", "Cold Blood", "Preparation" }, -- Shift R  burst
        ["LT+RT Down"] = { "Expose Armor" },               -- Ctrl E
        ["LT+RT Left"] = { "Feint" },                      -- Ctrl R  threat drop
      } } } },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  -- The shared Bar 1, 2 and 4 are Assassination's (Combat changes Q, Shift+R, Ctrl+R).
  keyboard = {
    [1] = {
      { macro = "MutiAttack", "Mutilate", "Hemorrhage", "Sinister Strike" }, -- Q  slot 1: builder (SS until Hemorrhage 30 / Mutilate 40)
      { "Shank", "Backstab" },                          -- E  slot 2: Shank on cooldown (Backstab until 24)
      { "Eviscerate" },                                 -- R  slot 3: finisher at 4-5 CP
      { "Rupture" },                                    -- T  slot 5: finisher (long fights)
      { "Slice and Dice" },                             -- F  slot 4: keep it up
      { "Riposte", "Ghostly Strike" },                  -- G  proc (hybrid builds)
      { "Sprint" },                                     -- C  mobility
      { "Gouge" },                                      -- V  no snare: Gouge stops the target
      { "Throw", "Shoot Bow", "Shoot Crossbow", "Shoot Gun" }, -- 1  ranged pull
      { "Blade Flurry" },                               -- 2  AoE (Combat talent, row 4 = 30; empty otherwise)
      { "Kick" },                                       -- 3  interrupt
      { "Feint" },                                      -- 4  big pulls: drop threat early
    },
    [2] = {
      false,                                            -- Shift+Q  self-heal (rogues have none)
      { "Evasion" },                                    -- Shift+E  defensive
      { macro = "Blades", "Adrenaline Rush", "Cold Blood", "Preparation" }, -- Shift+R  burst
      { "Kidney Shot" },                                -- Shift+T  control
      { "Sap" },                                        -- Shift+F  hard CC (from Stealth)
      { "Blind" },                                      -- Shift+G  control
      { racial = true },                                -- Shift+C  racial
      { macro = "Poof", "Vanish" },                     -- Shift+V  emergency
      { macro = "StealthOn", "Stealth" },               -- Shift+1  stance row
      false, false, false,                              -- Shift+2-4 (poisons are items)
    },
    -- [3] is the Alt bar (Fish, Bait, trinkets, Hearthstone), not set here.
    [4] = {
      false,                                            -- Ctrl+Q  (no secondary attack)
      { "Expose Armor" },                               -- Ctrl+E  secondary debuff
      false,                                            -- Ctrl+R  (Feint moved to 4)
      false,                                            -- Ctrl+T  free
      { "Pick Pocket" },                                -- Ctrl+F  (from Stealth)
      { "Distract" },                                   -- Ctrl+G  utility
      { "Pick Lock" },                                  -- Ctrl+C  utility
      { "Disarm Trap" },                                -- Ctrl+V  utility
      false, false, false, false,                       -- Ctrl+1-4
    },
    stances = {
      -- Stealth's own rotation: the openers. Keys whose spell works in and
      -- out of Stealth repeat the base entry.
      stealth = {
        offset = 1, label = "Stealth",
        { macro = "MutiAttack", "Mutilate", "Hemorrhage", "Sinister Strike" }, -- Q  same as base
        { macro = "PickGarrote", "Garrote" },           -- E  bleed opener (bosses, long fights)
        { macro = "Premed", "Ambush" },                 -- R  big opener (dagger, from behind)
        false,                                          -- T
        false,                                          -- F  (no combo points yet)
        false,                                          -- G
        { "Sprint" },                                   -- C  same as base
        false,                                          -- V
        { "Cheap Shot" },                               -- 1  opener (stun)
        { "Blade Flurry" },                             -- 2  same as base: pop it on the way in
        { "Kick" },                                     -- 3  same as base
        false,                                          -- 4
      },
    },
  },

  -- Controller page 1 (Combat; Assassination and Subtlety have their own
  -- above) follows dev/key-roles.md: RT A X Y B = slots 1-4, LT A slot 5,
  -- LT X proc, LT B interrupt, LT Y AoE, RT D-pad opener / second opener /
  -- mobility / Gouge. The controller doesn't page by Stealth (Apply mirrors
  -- the RT bar into the stealth bar), so the openers have their own buttons:
  -- Cheap Shot on the opener button, Garrote on RT Down (Feint, the 4 key,
  -- moves to LT+RT Left: it's a cooldown, not a rotation press).
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { macro = "Strike", "Sinister Strike" }, -- Q  slot 1: builder
        ["RT X"] = { "Shank", "Backstab" },                -- E  slot 2: Shank
        ["RT Y"] = { "Eviscerate" },                       -- R  slot 3: finisher
        ["RT B"] = { "Slice and Dice" },                   -- F  slot 4: keep it up
        ["LT A"] = { "Rupture" },                          -- T  slot 5: rarely (not in Wowhead)
        ["LT X"] = { "Riposte" },                          -- G  proc: after a parry
        ["LT B"] = { "Kick" },                             -- 3  interrupt
        ["LT Y"] = { "Blade Flurry" },                     -- 2  AoE
        ["RT Up"] = { "Cheap Shot" },                      -- 1  opener (from Stealth)
        ["RT Down"] = { macro = "PickGarrote", "Garrote" }, -- 4  long-fight opener (no ground AoE)
        ["RT Left"] = { "Sprint" },                        -- C  mobility
        ["RT Right"] = { "Gouge" },                        -- V  no snare: Gouge stops the target
        ["LT Up"] = { macro = "Premed", "Ambush" },        -- Shift Q (no self-heal): dagger opener
        ["LT Down"] = { "Sap" },                           -- Shift F  hard CC
        ["LT Left"] = { "Kidney Shot" },                   -- Shift T  control
        ["LT Right"] = { "Evasion" },                      -- Shift E  defensive
        ["none Up"] = { macro = "StealthOn", "Stealth" },  -- stance
        ["none Left"] = { "Pick Pocket" },                 -- utility
        ["none Right"] = { "Throw", "Shoot Bow", "Shoot Crossbow", "Shoot Gun" }, -- ranged pull, standing
        ["none Down"] = { "Distract" },
        ["LT+RT A"] = { macro = "Poof", "Vanish" },        -- Shift V  emergency
        ["LT+RT X"] = { "Blind" },                         -- Shift G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { macro = "Blades", "Adrenaline Rush", "Preparation" }, -- Shift R  burst: Blade Flurry + Adrenaline Rush
        ["LT+RT Down"] = { "Expose Armor" },               -- Ctrl E
        ["LT+RT Left"] = { "Feint" },                      -- Ctrl R  threat drop
        ["LT+RT Right"] = { "Cold Blood" },                -- Ctrl R on the keyboard: first 5-point Eviscerate
      },
      -- Page 2: rogue tools; the shared Utility buttons (Layouts/Shared.lua)
      -- add Hearthstone, trinkets, fishing, camp, Mount and professions.
      {
        title = "Utility",
        ["RT A"] = { "Pick Lock" },
        ["RT X"] = { "Disarm Trap" },
      },
      -- Page 3: Steam Deck helpers and the catch-all.
      {
        title = "Extras",
        ["none Up"] = { macro = "Reload" },
        ["none Down"] = { macro = "Follow" },
        ["none Left"] = { macro = "Focus" },
        ["none Right"] = { macro = "Assist" },
        ["LT+RT A"] = { macro = "Skull" },
        ["RT A"] = { overflow = true }, ["RT X"] = { overflow = true },
        ["RT B"] = { overflow = true }, ["RT Y"] = { overflow = true },
        ["RT Up"] = { overflow = true }, ["RT Down"] = { overflow = true },
        ["RT Left"] = { overflow = true }, ["RT Right"] = { overflow = true },
        ["LT A"] = { overflow = true }, ["LT X"] = { overflow = true },
        ["LT B"] = { overflow = true }, ["LT Y"] = { overflow = true },
        ["LT Up"] = { overflow = true }, ["LT Down"] = { overflow = true },
        ["LT Left"] = { overflow = true }, ["LT Right"] = { overflow = true },
      },
    },
    paddles = {},
  },
})
