-- Rogue layouts. Data contract: dev/layout-format.md; key roles shared by
-- every class: dev/key-roles.md. Keep every value a literal (no variables,
-- no function calls): dev.ps1 rules reads this file without running Lua.
--
-- One layout serves all three specs: fallback chains pick the build's spell
-- ({ "Mutilate", "Hemorrhage", "Sinister Strike" } takes the first one you
-- know); only Combat overrides Bar 1, for the Strike macro on Q (a macro
-- home needs its first spell known, so it can't sit in the shared chain).
-- Combat is the leveling spec; Subtlety from 30 (Hemorrhage), Assassination
-- once Mutilate (40, two daggers). Research 2026-11: Mobalytics and Icy
-- Veins rogue leveling, warcraft.wiki.gg Rogue abilities (Forever).
-- Poisons are items: not here. Rogues have no self-heal, snare or ground
-- AoE: Shift+Q stays empty, V holds Gouge and 4 Slice and Dice (closest fit).
--
-- Stealth pages Bar 1 (bonus bar offset 1, slots 73-84; unverified on the
-- Forever client). The stealth page keeps the key roles: 1 opener (Cheap
-- Shot), E bleed (Garrote), R big hit (Ambush), T Premeditation. Stealth
-- itself sits on Shift+1 (the buff/stance row), which doesn't page.
local _, ns = ...

ns.Layout.Register("ROGUE", {
  specs = {
    { key = "assassination", name = "Assassination", tab = 1 },
    { key = "combat", name = "Combat", tab = 2, default = true, keyboard = { [1] = {
      { macro = "Strike", "Sinister Strike" },          -- Q  main builder (the Strike macro once installed)
      { "Rupture" },                                    -- E  bleed (20)
      { "Eviscerate" },                                 -- R  big hitter (finisher)
      { "Shank" },                                      -- T  signature (24; under 60 energy)
      { "Ghostly Strike", "Backstab" },                 -- F  secondary builder
      { "Riposte" },                                    -- G  proc (after a parry; Combat talent)
      { "Sprint" },                                     -- C  mobility
      { "Gouge" },                                      -- V  no snare: Gouge stops the target
      { "Throw", "Shoot Bow", "Shoot Crossbow", "Shoot Gun" }, -- 1  ranged pull
      { "Blade Flurry" },                               -- 2  AoE (cleave; Combat talent)
      { "Kick" },                                       -- 3  interrupt
      { "Slice and Dice" },                             -- 4  no ground AoE: Slice and Dice
    } } },
    { key = "subtlety", name = "Subtlety", tab = 3 },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  keyboard = {
    [1] = {
      { "Mutilate", "Hemorrhage", "Sinister Strike" },  -- Q  main builder (Combat: the Strike macro)
      { "Rupture" },                                    -- E  bleed (20)
      { "Eviscerate" },                                 -- R  big hitter (finisher)
      { "Shank" },                                      -- T  signature (24; under 60 energy)
      { "Ghostly Strike", "Backstab" },                 -- F  secondary builder (Sub / daggers)
      { "Riposte" },                                    -- G  proc (after a parry)
      { "Sprint" },                                     -- C  mobility
      { "Gouge" },                                      -- V  no snare: Gouge stops the target
      { "Throw", "Shoot Bow", "Shoot Crossbow", "Shoot Gun" }, -- 1  ranged pull
      { "Blade Flurry" },                               -- 2  AoE (cleave)
      { "Kick" },                                       -- 3  interrupt
      { "Slice and Dice" },                             -- 4  no ground AoE: Slice and Dice
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
      { "Stealth" },                                    -- Shift+1  stance row
      false, false, false,                              -- Shift+2-4 (poisons are items)
    },
    -- [3] is the Alt bar (Fish, Bait, trinkets, Hearthstone), not set here.
    [4] = {
      false,                                            -- Ctrl+Q  (no secondary attack)
      { "Expose Armor" },                               -- Ctrl+E  secondary debuff
      { "Feint" },                                      -- Ctrl+R  threat drop
      false,                                            -- Ctrl+T  free
      { "Pick Pocket" },                                -- Ctrl+F  (from Stealth)
      { "Distract" },                                   -- Ctrl+G  utility
      { "Pick Lock" },                                  -- Ctrl+C  utility
      { "Disarm Trap" },                                -- Ctrl+V  utility
      false, false, false, false,                       -- Ctrl+1-4
    },
    stances = {
      -- Same roles in Stealth; keys whose spell works in and out of
      -- Stealth repeat the base entry.
      stealth = {
        offset = 1, label = "Stealth",
        { "Mutilate", "Hemorrhage", "Sinister Strike" }, -- Q  (Sinister Strike opens before 26)
        { "Garrote" },                                  -- E  bleed opener
        { macro = "Premed", "Ambush" },                 -- R  big opener (dagger, from behind)
        { "Premeditation" },                            -- T  Sub talent
        { "Ghostly Strike", "Backstab" },               -- F
        false,                                          -- G
        { "Sprint" },                                   -- C
        false,                                          -- V
        { "Cheap Shot" },                               -- 1  opener (stun)
        false,                                          -- 2
        { "Kick" },                                     -- 3
        false,                                          -- 4
      },
    },
  },

  -- Controller page 1 mirrors the keyboard roles (dev/key-roles.md). The
  -- controller doesn't page by Stealth, so the openers have their own
  -- buttons: Cheap Shot on the opener button, Garrote on the Ctrl Q
  -- button, Premeditation on Ctrl T, and Ambush on LT Up (the self-heal
  -- button, which rogues have no spell for).
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { "Mutilate", "Hemorrhage", "Sinister Strike" }, -- Q
        ["RT X"] = { "Rupture" },                          -- E
        ["RT B"] = { "Kick" },                             -- 3
        ["RT Y"] = { "Blade Flurry" },                     -- 2
        ["RT Up"] = { "Cheap Shot" },                      -- 1
        ["RT Right"] = { "Eviscerate" },                   -- R
        ["RT Left"] = { "Shank" },                         -- T
        ["RT Down"] = { "Slice and Dice" },                -- 4
        ["LT A"] = { "Ghostly Strike", "Backstab" },       -- F
        ["LT X"] = { "Riposte" },                          -- G
        ["LT B"] = { "Gouge" },                            -- V
        ["LT Y"] = { "Sprint" },                           -- C
        ["LT Up"] = { macro = "Premed", "Ambush" },        -- Shift Q (no self-heal): Ambush
        ["LT Down"] = { "Sap" },                           -- Shift F
        ["LT Left"] = { "Kidney Shot" },                   -- Shift T
        ["LT Right"] = { "Evasion" },                      -- Shift E
        ["none Up"] = { "Stealth" },                       -- stance
        ["none Left"] = { "Pick Pocket" },                 -- utility
        ["none Right"] = { "Throw", "Shoot Bow", "Shoot Crossbow", "Shoot Gun" }, -- ranged pull
        ["none Down"] = { "Distract" },
        ["LT+RT A"] = { macro = "Poof", "Vanish" },        -- Shift V
        ["LT+RT X"] = { "Blind" },                         -- Shift G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { macro = "Blades", "Adrenaline Rush", "Cold Blood", "Preparation" }, -- Shift R
        ["LT+RT Up"] = { "Garrote" },                      -- Ctrl Q
        ["LT+RT Down"] = { "Expose Armor" },               -- Ctrl E
        ["LT+RT Left"] = { "Feint" },                      -- Ctrl R
        ["LT+RT Right"] = { "Premeditation" },             -- Ctrl T
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
