-- Warrior layouts. Data contract: dev/layout-format.md; key roles shared by
-- every class: dev/key-roles.md (the BM hunter is the reference). Keep every
-- value a literal (no variables, no function calls): dev.ps1 rules reads
-- this file without running Lua.
--
-- Protection (one-hand and shield) is the leveling spec; Arms (two-hander)
-- is the alternative and Fury is weak before 36 (research 2026-11, round 2:
-- Icy Veins, Mobalytics). One keyboard layout serves all three specs through
-- fallback chains ({ "Mortal Strike", "Bloodthirst", "Shield Slam" } on T).
--
-- Keyboard: Bar 1 pages by stance (Battle offset 1, Defensive 2, Berserker
-- 3; base [1] is the no-stance page). Every page keeps the key roles; the
-- stance only changes which spell fills a role, and a role with no spell
-- usable in that stance stays empty:
--   Q main attack  Heroic Strike              E DoT        Rend (Battle, Defensive)
--   R big hitter   Execute (Battle, Berserker) T signature MS / BT / Shield Slam
--   F builder      Sunder Armor               G proc       Overpower / Revenge / Berserker Rage
--   C escape       Intercept (Berserker)      V snare      Hamstring (Battle, Berserker)
--   1 opener       Charge (Battle, Defensive; ChargeIntercept in Berserker)
--   2 main AoE     Cleave / Whirlwind         3 interrupt  Shield Bash / Pummel
--   4 ground AoE   Thunder Clap (Battle, Defensive)
-- Shift and Ctrl don't page: they hold the any-stance spells and the
-- stance-locked rarer ones (Shield Wall, Taunt...), stances on Shift+1/2/3.
--
-- Controller: it doesn't page by stance, so it uses the stance-dance macros.
-- Page 1 mirrors the keyboard roles (dev/key-roles.md). Its proc button (LT X)
-- is Revenge for Protection and Overpower for Arms and Fury, and Fury's AoE
-- (RT Y) is Whirlwind: Arms and Fury have their own page 1.
local _, ns = ...

ns.Layout.Register("WARRIOR", {
  specs = {
    { key = "arms", name = "Arms", tab = 1, controller = { pages = { [1] = {
      title = "Combat",
      ["RT A"] = { "Heroic Strike" },
      ["RT X"] = { "Rend" },
      ["RT B"] = { macro = "BashPummel", "Shield Bash", "Pummel" },
      ["RT Y"] = { "Cleave" },
      ["RT Up"] = { macro = "TankCharge", "Charge" },
      ["RT Right"] = { "Execute" },
      ["RT Left"] = { "Mortal Strike", "Bloodthirst", "Shield Slam" },
      ["RT Down"] = { "Thunder Clap" },
      ["LT A"] = { "Sunder Armor" },
      ["LT X"] = { macro = "Overpower", "Overpower" },
      ["LT B"] = { "Hamstring" },
      ["LT Y"] = { macro = "Intercept", "Intercept" },
      ["LT Up"] = { "Victory Rush" },
      ["LT Down"] = { "Disarm" },
      ["LT Left"] = { "Concussion Blow", "Piercing Howl" },
      ["LT Right"] = { "Death Wish", "Sweeping Strikes", "Shield Block" },
      ["none Up"] = { "Battle Stance" },
      ["none Left"] = { "Defensive Stance" },
      ["none Right"] = { "Berserker Stance" },
      ["none Down"] = { "Battle Shout" },
      ["LT+RT A"] = { macro = "ShieldWall", "Shield Wall" },
      ["LT+RT X"] = { "Intimidating Shout" },
      ["LT+RT B"] = { racial = true },
      ["LT+RT Y"] = { "Recklessness" },
      ["LT+RT Up"] = { "Spearing Strike", "Gore Drinker" },
      ["LT+RT Down"] = { "Demoralizing Shout" },
      ["LT+RT Left"] = { "Slam" },
      ["LT+RT Right"] = { "Last Stand", "Reckless Swings" },
    } } } },
    { key = "fury", name = "Fury", tab = 2, controller = { pages = { [1] = {
      title = "Combat",
      ["RT A"] = { "Heroic Strike" },
      ["RT X"] = { "Rend" },
      ["RT B"] = { macro = "BashPummel", "Shield Bash", "Pummel" },
      ["RT Y"] = { macro = "Whirlwind", "Whirlwind", "Cleave" },
      ["RT Up"] = { macro = "TankCharge", "Charge" },
      ["RT Right"] = { "Execute" },
      ["RT Left"] = { "Mortal Strike", "Bloodthirst", "Shield Slam" },
      ["RT Down"] = { "Thunder Clap" },
      ["LT A"] = { "Sunder Armor" },
      ["LT X"] = { macro = "Overpower", "Overpower" },
      ["LT B"] = { "Hamstring" },
      ["LT Y"] = { macro = "Intercept", "Intercept" },
      ["LT Up"] = { "Victory Rush" },
      ["LT Down"] = { "Disarm" },
      ["LT Left"] = { "Concussion Blow", "Piercing Howl" },
      ["LT Right"] = { "Death Wish", "Sweeping Strikes", "Shield Block" },
      ["none Up"] = { "Battle Stance" },
      ["none Left"] = { "Defensive Stance" },
      ["none Right"] = { "Berserker Stance" },
      ["none Down"] = { "Battle Shout" },
      ["LT+RT A"] = { macro = "ShieldWall", "Shield Wall" },
      ["LT+RT X"] = { "Intimidating Shout" },
      ["LT+RT B"] = { racial = true },
      ["LT+RT Y"] = { "Recklessness" },
      ["LT+RT Up"] = { "Spearing Strike", "Gore Drinker" },
      ["LT+RT Down"] = { "Demoralizing Shout" },
      ["LT+RT Left"] = { "Slam" },
      ["LT+RT Right"] = { "Last Stand", "Reckless Swings" },
    } } } },
    { key = "prot", name = "Protection", tab = 3, default = true },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  keyboard = {
    -- The no-stance page (a warrior is nearly always in a stance; this page
    -- mirrors Battle Stance, with stance-dance macros where they help).
    [1] = {
      { "Heroic Strike" },                                    -- Q  main attack
      { "Rend" },                                             -- E  DoT
      { "Execute" },                                          -- R  big hitter
      { "Mortal Strike", "Bloodthirst", "Shield Slam" },      -- T  spec signature (40)
      { "Sunder Armor" },                                     -- F  builder
      { macro = "Overpower", "Overpower" },                   -- G  proc (Battle Stance first)
      { macro = "Intercept", "Intercept" },                   -- C  escape / mobility
      { "Hamstring" },                                        -- V  snare
      { macro = "TankCharge", "Charge" },                     -- 1  opener
      { "Cleave" },                                           -- 2  main AoE
      { macro = "BashPummel", "Shield Bash", "Pummel" },      -- 3  interrupt
      { "Thunder Clap" },                                     -- 4  ground AoE
    },
    -- Bar 2 (Shift): Q self-heal, E spec cooldown, R burst, T spec control,
    -- F hard CC, G AoE control, C racial, V emergency, 1-4 stances and shout.
    [2] = {
      { "Victory Rush" },                                     -- Shift+Q  heals you after a kill (20)
      { "Death Wish", "Sweeping Strikes", "Shield Block" },   -- Shift+E  spec cooldown
      { "Recklessness" },                                     -- Shift+R  burst
      { "Concussion Blow", "Piercing Howl" },                 -- Shift+T  spec control
      { "Disarm" },                                           -- Shift+F  closest to hard CC
      { "Intimidating Shout" },                               -- Shift+G  AoE control
      { racial = true },                                      -- Shift+C  racial
      { "Shield Wall" },                                      -- Shift+V  emergency
      { "Battle Stance" },                                    -- Shift+1  stance
      { "Defensive Stance" },                                 -- Shift+2  stance
      { "Berserker Stance" },                                 -- Shift+3  stance
      { "Battle Shout" },                                     -- Shift+4  shout (any stance)
    },
    -- [3] is the Alt bar (trinkets, Fish, Bait, Hearthstone), not set here.
    -- Bar 4 (Ctrl): Q E R T secondary attacks and debuffs, F G C V taunts
    -- and Retaliation, 1 Bloodrage.
    [4] = {
      { "Spearing Strike", "Gore Drinker" },                  -- Ctrl+Q  Arms / Fury strike (Forever talents)
      { "Demoralizing Shout" },                               -- Ctrl+E  secondary debuff
      { "Slam" },                                             -- Ctrl+R  secondary attack
      { "Last Stand", "Reckless Swings" },                    -- Ctrl+T  spec utility
      { "Taunt" },                                            -- Ctrl+F  taunt
      { "Mocking Blow" },                                     -- Ctrl+G  taunt
      { "Challenging Shout" },                                -- Ctrl+C  AoE taunt
      { "Retaliation" },                                      -- Ctrl+V  cooldown
      { "Bloodrage" },                                        -- Ctrl+1  rage (any stance)
      false, false, false,                                    -- Ctrl+2 3 4  free
    },
    stances = {
      -- Battle Stance (offset 1): where every warrior starts; Arms lives here.
      battle = {
        offset = 1, label = "Battle",
        { "Heroic Strike" },                                  -- Q
        { "Rend" },                                           -- E
        { "Execute" },                                        -- R
        { "Mortal Strike", "Bloodthirst", "Shield Slam" },    -- T
        { "Sunder Armor" },                                   -- F
        { "Overpower" },                                      -- G
        false,                                                -- C  (no escape in Battle Stance)
        { "Hamstring" },                                      -- V
        { macro = "TankCharge", "Charge" },                   -- 1
        { "Cleave" },                                         -- 2
        { "Shield Bash" },                                    -- 3
        { "Thunder Clap" },                                   -- 4
      },
      -- Defensive Stance (offset 2, quest at 10): Protection's stance.
      defensive = {
        offset = 2, label = "Defensive",
        { "Heroic Strike" },                                  -- Q
        { "Rend" },                                           -- E
        false,                                                -- R  (Execute needs Battle or Berserker)
        { "Mortal Strike", "Bloodthirst", "Shield Slam" },    -- T
        { "Sunder Armor" },                                   -- F
        { macro = "Revenge", "Revenge" },                     -- G  (with Shield Block)
        false,                                                -- C
        false,                                                -- V  (Hamstring needs Battle or Berserker)
        { macro = "TankCharge", "Charge" },                   -- 1  (Battle Stance first, or Vanguard)
        { "Cleave" },                                         -- 2
        { "Shield Bash" },                                    -- 3
        { "Thunder Clap" },                                   -- 4
      },
      -- Berserker Stance (offset 3, quest at 30): Fury's stance.
      berserker = {
        offset = 3, label = "Berserker",
        { "Heroic Strike" },                                  -- Q
        false,                                                -- E  (Rend needs Battle or Defensive)
        { "Execute" },                                        -- R
        { "Mortal Strike", "Bloodthirst", "Shield Slam" },    -- T
        { "Sunder Armor" },                                   -- F
        { "Berserker Rage" },                                 -- G  reactive (breaks fear)
        { "Intercept" },                                      -- C
        { "Hamstring" },                                      -- V
        { macro = "ChargeIntercept" },                        -- 1  (Battle Stance and Charge out of combat)
        { "Whirlwind" },                                      -- 2
        { "Pummel" },                                         -- 3
        false,                                                -- 4
      },
    },
  },

  -- Controller: keys "<layer> <button>", layer none / LT / RT / LT+RT,
  -- button A X B Y or Up Down Left Right (D-pad). The Top bar's face buttons
  -- are fixed. Gamepad bars don't page by stance: stance-dance macros.
  controller = {
    pages = {
      -- Page 1 (Protection; Arms and Fury have their own above): the
      -- keyboard roles. RT = Plain Q E 3 2 1 R T 4, LT = Plain F G V C and
      -- Shift Q F T E, LT+RT = Shift V G, racial, Shift R, Ctrl Q E R T.
      {
        title = "Combat",
        ["RT A"] = { "Heroic Strike" },
        ["RT X"] = { "Rend" },
        ["RT B"] = { macro = "BashPummel", "Shield Bash", "Pummel" },
        ["RT Y"] = { "Cleave" },
        ["RT Up"] = { macro = "TankCharge", "Charge" },
        ["RT Right"] = { "Execute" },
        ["RT Left"] = { "Mortal Strike", "Bloodthirst", "Shield Slam" },
        ["RT Down"] = { "Thunder Clap" },
        ["LT A"] = { "Sunder Armor" },
        ["LT X"] = { macro = "Revenge", "Revenge" },
        ["LT B"] = { "Hamstring" },
        ["LT Y"] = { macro = "Intercept", "Intercept" },
        ["LT Up"] = { "Victory Rush" },
        ["LT Down"] = { "Disarm" },
        ["LT Left"] = { "Concussion Blow", "Piercing Howl" },
        ["LT Right"] = { "Death Wish", "Sweeping Strikes", "Shield Block" },
        -- No trigger: the stance row and the shout (no radial for stances).
        ["none Up"] = { "Battle Stance" },
        ["none Left"] = { "Defensive Stance" },
        ["none Right"] = { "Berserker Stance" },
        ["none Down"] = { "Battle Shout" },
        ["LT+RT A"] = { macro = "ShieldWall", "Shield Wall" },
        ["LT+RT X"] = { "Intimidating Shout" },
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Recklessness" },
        ["LT+RT Up"] = { "Spearing Strike", "Gore Drinker" },
        ["LT+RT Down"] = { "Demoralizing Shout" },
        ["LT+RT Left"] = { "Slam" },
        ["LT+RT Right"] = { "Last Stand", "Reckless Swings" },
      },
      -- Page 2: only the shared Utility buttons (Layouts/Shared.lua):
      -- Hearthstone, trinkets, fishing, camp, Mount and professions.
      {
        title = "Utility",
      },
      -- Page 3: taunts and the rarer stance spells, Steam Deck helpers and
      -- the catch-all (Overpower or Revenge, whichever page 1 lacks).
      {
        title = "Extras",
        ["RT A"] = { "Taunt" },
        ["RT X"] = { macro = "MockingBlow", "Mocking Blow" },
        ["RT B"] = { "Challenging Shout" },
        ["RT Y"] = { macro = "Retaliation", "Retaliation" },
        ["RT Up"] = { "Bloodrage" },
        ["RT Down"] = { macro = "BerserkerRage", "Berserker Rage" },
        ["RT Left"] = { overflow = true },
        ["RT Right"] = { overflow = true },
        -- Only what the game menu, vendor window and Steam don't already do.
        ["none Up"] = { macro = "Reload" },
        ["none Down"] = { macro = "Follow" },
        ["none Left"] = { macro = "Focus" },
        ["none Right"] = { macro = "Assist" },
        ["LT+RT A"] = { macro = "Skull" },
        -- Everything else you know, alphabetically.
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
    -- Back buttons left unbound (owner's choice).
    paddles = {},
  },
})
