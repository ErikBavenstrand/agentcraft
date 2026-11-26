-- Warrior layouts. Data contract: dev/layout-format.md; placement rule:
-- dev/key-roles.md (rotation slots in press-frequency order). Keep every
-- value a literal: dev.ps1 rules reads this file without running Lua.
--
-- Rotations (Wowhead WoW Forever guides, 2026-11-26; they win any
-- disagreement). Talent rows: dev/forever-talents.md (row r = level
-- 10 + 5r, earlier with the Legacy perk Talented):
--   [WH-P] wowhead.com/forever/guide/classes/warrior/protection/rotation-cooldowns-pve-tank
--          and .../warrior/protection/tank-leveling-tips
--   [WH-A] .../warrior/arms/rotation-cooldowns-pve-dps and .../arms/dps-leveling-tips
--   [WH-F] .../warrior/fury/rotation-cooldowns-pve-dps and .../fury/dps-leveling-tips
--   Protection (the leveling spec, 1H + shield, Defensive Stance). Single
--     target and leveling alike [WH-P]: Shield Block (off the GCD) ->
--     Revenge -> Shield Slam (row 6 = 40) or Bloodthirst (Fury-Prot) -> Sunder Armor
--     to 5 and as the filler -> Thunder Clap, Battle Shout and Demoralizing
--     Shout kept up -> Rend when high on threat -> Heroic Strike over 30
--     rage (off the GCD). AoE: Thunder Clap first, then the same, Cleave as
--     the dump; Retaliation in big pulls. Opener: Bloodrage, Battle Shout,
--     Retaliation (Battle) pre-pull, Defensive Stance, Charge + Shield Block,
--     Shield Slam, Heroic Strike, Revenge, Sunder x3 ... Thunder Clap,
--     Demoralizing Shout. Execute under 20% needs another stance.
--     Cooldowns: Shield Wall, Last Stand, Retaliation, Death Wish
--     (Fury-Prot), Recklessness; taunts: Taunt, Mocking Blow (backup),
--     Challenging Shout. Leveling uses the same buttons.
--   Arms (2H, Battle Stance) [WH-A]: Rend kept up -> Mortal Strike (talent,
--     row 6 = 40) -> Overpower when lit -> Spearing Strike (talent, row 3 =
--     25) -> Slam (10 sec
--     cooldown in Forever; only once you have Improved Slam) -> Sunder Armor
--     -> Heroic Strike over 40 rage -> Thunder Clap and Demoralizing Shout
--     as the lone warrior; Execute woven in under 20%. Leveling adds Victory
--     Rush under 90% health and Thunder Clap. AoE: Sweeping Strikes (row 4 =
--     30) ->
--     Mortal Strike -> Overpower -> Cleave over 45 rage -> Whirlwind.
--     Cooldown: Recklessness.
--   Fury (dual wield) [WH-F]: Execute -> Bloodthirst -> Whirlwind (both on
--     cooldown) -> Overpower under 30 rage -> Heroic Strike over 65 rage ->
--     Hamstring over 85 rage. AoE: Whirlwind first, Cleave over 60 rage.
--     Leveling: Charge, Reckless Swings (talent, row 3 = 25) above 30%
--     health, Bloodthirst (talent, row 6 = 40), Victory Rush, Overpower,
--     Bloodrage or Berserker Rage (feeding Gore Drinker, a passive row-4
--     talent: no button), Demoralizing Shout, Whirlwind, Rend.
--     Cooldowns: Death Wish (row 4 = 30), Recklessness; Piercing Howl (row 2
--     = 20) and Intimidating
--     Shout to escape.
--
-- Keyboard (index 1-12 = Q E R T F G C V 1 2 3 4): Bar 1 pages by stance
-- (Battle offset 1, Defensive 2, Berserker 3, confirmed in game; base [1]
-- is the no-stance page). Every spell has one key on all the pages it sits
-- on; a stance only changes which spell a slot holds. Shift and Ctrl don't
-- page. Each spec has its own Bar 1 pages, Shift and Ctrl: the rotations
-- differ too much for one shared bar. The top-level layout is Protection.
--
-- Controller page 1 follows key-roles.md (RT A X Y B = Q E R F, LT A X B Y
-- = T G 3 2, RT D-pad = 1 4 C V, LT D-pad = Shift Q E T F, LT+RT = Shift
-- V G, racial, Shift R and Ctrl Q E R T). The pad doesn't page by stance:
-- stance-dance macros (TankCharge, Revenge, Overpower, Whirlwind...) make
-- one layout work in every stance.
local _, ns = ...

ns.Layout.Register("WARRIOR", {
  specs = {
    -- Arms ------------------------------------------------------------------
    -- Slots in Wowhead's order: Q Mortal Strike, E Rend, R Slam, F Heroic
    -- Strike (off the GCD, pressed on most swings with rage), T Execute,
    -- G Overpower. V holds Spearing Strike (a rotation talent: a key that
    -- stays empty until you take it, so it gets the reach key, not F);
    -- Hamstring, which Wowhead's Arms rotation never uses, moves to Ctrl.
    { key = "arms", name = "Arms", tab = 1,
      keyboard = {
        [1] = {
          { macro = "MortalStrike", "Mortal Strike", "Thunder Clap" },               -- Q  slot 1: MS on cooldown (talent row 6 = 40); TC fills in before (leveling)
          { "Rend" },                                         -- E  slot 2: bleed kept up
          { "Slam", "Sunder Armor" },                         -- R  slot 3: Slam on its cooldown (20); Sunder before
          { "Execute" },                                      -- T  slot 5: finisher under 20%
          { "Heroic Strike" },                                -- F  slot 4: rage dump over 40 rage
          { macro = "Overpower", "Overpower" },               -- G  reactive (Battle Stance first)
          { macro = "Intercept", "Intercept" },               -- C  gap closer (Berserker first)
          { "Spearing Strike" },                              -- V  talent strike, row 3 = 25 (giants, dragonkin first)
          { macro = "BattleCharge", "Charge" },               -- 1  opener (Battle Stance first)
          { "Cleave" },                                       -- 2  main AoE
          { macro = "BashPummel", "Pummel", "Shield Bash" },  -- 3  interrupt (Pummel with a 2H)
          { "Sweeping Strikes" },                             -- 4  AoE opener (talent, row 4 = 30)
        },
        [2] = {
          { "Victory Rush" },                                 -- Shift+Q  self-heal after a kill (20)
          { macro = "Retaliation", "Retaliation" },           -- Shift+E  defensive (Battle Stance first)
          { "Recklessness" },                                 -- Shift+R  burst (50), Arms' one cooldown
          { "Disarm" },                                       -- Shift+T  control (Defensive Stance)
          { "Intimidating Shout" },                           -- Shift+F  hard CC
          { "Demoralizing Shout" },                           -- Shift+G  AoE control (lone warrior debuff)
          { racial = true },                                  -- Shift+C  racial
          { macro = "ShieldWall", "Shield Wall" },            -- Shift+V  emergency
          { "Battle Stance" },                                -- Shift+1  stance row
          { "Defensive Stance" },                             -- Shift+2
          { "Berserker Stance" },                             -- Shift+3
          { "Battle Shout" },                                 -- Shift+4  shout (any stance)
        },
        [4] = {
          { "Bloodrage" },                                    -- Ctrl+Q  rage at the pull
          { "Taunt" },                                        -- Ctrl+E  off-tank taunt (rare)
          { "Hamstring" },                                    -- Ctrl+R  snare for runners (not in the rotation)
          { "Challenging Shout" },                            -- Ctrl+T  AoE taunt (rare)
          { macro = "MockingBlow", "Mocking Blow" },          -- Ctrl+F  taunt that hits (rare)
          false,                                              -- Ctrl+G  free
          { "Reckless Swings" },                              -- Ctrl+C  Fury talent, row 3 = 25
          false, false, false, false, false,                  -- Ctrl+V 1 2 3 4  free
        },
        stances = {
          battle = {
            offset = 1, label = "Battle",
            { macro = "MortalStrike", "Mortal Strike", "Thunder Clap" },             -- Q  slot 1
            { "Rend" },                                       -- E  slot 2
            { "Slam", "Sunder Armor" },                       -- R  slot 3
            { "Execute" },                                    -- T  slot 5
            { "Heroic Strike" },                              -- F  slot 4
            { "Overpower" },                                  -- G  reactive
            { macro = "Intercept", "Intercept" },             -- C  gap closer
            { "Spearing Strike" },                            -- V  talent strike
            { macro = "BattleCharge", "Charge" },             -- 1  opener
            { "Cleave" },                                     -- 2  main AoE
            { macro = "BashPummel", "Pummel", "Shield Bash" },-- 3  interrupt
            { "Sweeping Strikes" },                           -- 4  AoE opener (Battle Stance)
          },
          defensive = {
            offset = 2, label = "Defensive",
            { macro = "MortalStrike", "Mortal Strike", "Thunder Clap" },             -- Q
            { "Rend" },                                       -- E
            { "Slam", "Sunder Armor" },                       -- R
            false,                                            -- T  (Execute: Battle or Berserker)
            { "Heroic Strike" },                              -- F
            { "Revenge" },                                    -- G  reactive in this stance
            { macro = "Intercept", "Intercept" },             -- C
            { "Spearing Strike" },                            -- V
            { macro = "BattleCharge", "Charge" },             -- 1
            { "Cleave" },                                     -- 2
            { macro = "BashPummel", "Pummel", "Shield Bash" },-- 3
            false,                                            -- 4  (Sweeping Strikes: Battle)
          },
          berserker = {
            offset = 3, label = "Berserker",
            { macro = "MortalStrike", "Mortal Strike", "Thunder Clap" },             -- Q
            false,                                            -- E  (Rend: Battle or Defensive)
            { "Slam", "Sunder Armor" },                       -- R
            { "Execute" },                                    -- T
            { "Heroic Strike" },                              -- F
            { "Berserker Rage" },                             -- G  reactive in this stance (fear)
            { "Intercept" },                                  -- C
            { "Spearing Strike" },                            -- V
            { macro = "ChargeIntercept" },                    -- 1  Intercept in combat, Charge out of it
            { "Whirlwind" },                                  -- 2  the AoE Wowhead adds in this stance
            { "Pummel" },                                     -- 3
            false,                                            -- 4
          },
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { macro = "MortalStrike", "Mortal Strike", "Thunder Clap" },      -- Q  slot 1
        ["RT X"] = { "Rend" },                                -- E  slot 2
        ["RT Y"] = { "Slam", "Sunder Armor" },                -- R  slot 3
        ["RT B"] = { "Heroic Strike" },                       -- F  slot 4
        ["LT A"] = { "Execute" },                             -- T  slot 5
        ["LT X"] = { macro = "Overpower", "Overpower" },      -- G  reactive
        ["LT B"] = { macro = "BashPummel", "Pummel", "Shield Bash" }, -- 3 interrupt
        ["LT Y"] = { "Cleave" },                              -- 2  main AoE
        ["RT Up"] = { macro = "BattleCharge", "Charge" },     -- 1  opener
        ["RT Down"] = { "Sweeping Strikes" },                 -- 4  AoE opener
        ["RT Left"] = { macro = "Intercept", "Intercept" },   -- C  gap closer
        ["RT Right"] = { "Spearing Strike" },                 -- V  talent strike
        ["LT Up"] = { "Victory Rush" },                       -- Shift+Q
        ["LT Right"] = { macro = "Retaliation", "Retaliation" }, -- Shift+E
        ["LT Left"] = { "Disarm" },                           -- Shift+T
        ["LT Down"] = { "Intimidating Shout" },               -- Shift+F
        ["LT+RT A"] = { macro = "ShieldWall", "Shield Wall" },-- Shift+V
        ["LT+RT X"] = { "Demoralizing Shout" },               -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Recklessness" },                     -- Shift+R
        ["LT+RT Up"] = { "Bloodrage" },                       -- Ctrl+Q
        ["LT+RT Down"] = { "Taunt" },                         -- Ctrl+E
        -- Ctrl+R on the pad is Whirlwind (Wowhead's Arms AoE): the pad has
        -- no Berserker page, so it needs the stance dance; Hamstring goes
        -- to the page 3 catch-all.
        ["LT+RT Left"] = { macro = "Whirlwind", "Whirlwind" },
        ["LT+RT Right"] = { "Challenging Shout" },            -- Ctrl+T
        ["none Up"] = { "Battle Stance" },
        ["none Left"] = { "Defensive Stance" },
        ["none Right"] = { "Berserker Stance" },
        ["none Down"] = { "Battle Shout" },
      } } } },

    -- Fury ------------------------------------------------------------------
    -- Slots in Wowhead's order: Q Bloodthirst, E Whirlwind (both on
    -- cooldown), R Heroic Strike (the rage dump), F Sunder Armor, T Execute,
    -- G Overpower, V Hamstring (Wowhead's dump over 85 rage). 4 holds
    -- Reckless Swings, third in Wowhead's leveling list; Piercing Howl (an
    -- escape there) takes Shift+V, as dual wield has no use for Shield Wall.
    -- Bloodrage feeds Gore Drinker's healing while leveling: Shift+E.
    { key = "fury", name = "Fury", tab = 2,
      keyboard = {
        [1] = {
          { macro = "Bloodthirst", "Bloodthirst", "Rend" },                         -- Q  slot 1: BT on cooldown (talent row 6 = 40); Rend before
          { macro = "Whirlwind", "Whirlwind", "Thunder Clap" }, -- E  slot 2: WW on cooldown (36, Berserker first); TC before
          { "Heroic Strike" },                                -- R  slot 3: rage dump over 65 rage
          { "Execute" },                                      -- T  slot 5: finisher, first under 20%
          { "Sunder Armor" },                                 -- F  slot 4: armor debuff for the group
          { macro = "Overpower", "Overpower" },               -- G  reactive (Battle Stance first)
          { macro = "Intercept", "Intercept" },               -- C  gap closer
          { "Hamstring" },                                    -- V  snare; rage dump over 85
          { macro = "ChargeIntercept", "Charge" },            -- 1  opener: Charge, Intercept in combat
          { "Cleave" },                                       -- 2  main AoE (WW is on E: it's single target too)
          { macro = "BashPummel", "Pummel", "Shield Bash" },  -- 3  interrupt
          { "Reckless Swings" },                              -- 4  leveling rage talent (row 3 = 25)
        },
        [2] = {
          { "Victory Rush" },                                 -- Shift+Q  self-heal
          { "Bloodrage" },                                    -- Shift+E  sustain: rage + Gore Drinker heals
          { "Death Wish" },                                   -- Shift+R  burst (talent, row 4 = 30), Fury's main cooldown
          { "Disarm" },                                       -- Shift+T  control
          { "Intimidating Shout" },                           -- Shift+F  hard CC / escape
          { "Demoralizing Shout" },                           -- Shift+G  AoE control (in the leveling list)
          { racial = true },                                  -- Shift+C
          { "Piercing Howl" },                                -- Shift+V  emergency: AoE slow to escape (talent, row 2 = 20)
          { "Battle Stance" },                                -- Shift+1
          { "Defensive Stance" },                             -- Shift+2
          { "Berserker Stance" },                             -- Shift+3
          { "Battle Shout" },                                 -- Shift+4
        },
        [4] = {
          { macro = "Retaliation", "Retaliation" },           -- Ctrl+Q  rare cooldown (Battle first)
          { "Taunt" },                                        -- Ctrl+E  rare
          { "Recklessness" },                                 -- Ctrl+R  second burst (50, 30 min)
          { "Challenging Shout" },                            -- Ctrl+T  rare
          { macro = "MockingBlow", "Mocking Blow" },          -- Ctrl+F  rare
          { macro = "ShieldWall", "Shield Wall" },            -- Ctrl+G  needs a shield: rare for Fury
          { "Spearing Strike" },                              -- Ctrl+C  Arms talent, row 3 = 25
          false, false, false, false, false,
        },
        stances = {
          battle = {
            offset = 1, label = "Battle",
            { macro = "Bloodthirst", "Bloodthirst", "Rend" },                       -- Q
            { macro = "Whirlwind", "Whirlwind", "Thunder Clap" }, -- E  (WW dances to Berserker)
            { "Heroic Strike" },                              -- R
            { "Execute" },                                    -- T
            { "Sunder Armor" },                               -- F
            { "Overpower" },                                  -- G  reactive
            { macro = "Intercept", "Intercept" },             -- C
            { "Hamstring" },                                  -- V
            { macro = "ChargeIntercept", "Charge" },          -- 1
            { "Cleave" },                                     -- 2
            { macro = "BashPummel", "Pummel", "Shield Bash" },-- 3
            { "Reckless Swings" },                            -- 4
          },
          defensive = {
            offset = 2, label = "Defensive",
            { macro = "Bloodthirst", "Bloodthirst", "Rend" },                       -- Q
            { macro = "Whirlwind", "Whirlwind", "Thunder Clap" }, -- E
            { "Heroic Strike" },                              -- R
            false,                                            -- T  (Execute: Battle or Berserker)
            { "Sunder Armor" },                               -- F
            { "Revenge" },                                    -- G
            { macro = "Intercept", "Intercept" },             -- C
            false,                                            -- V  (Hamstring: Battle or Berserker)
            { macro = "ChargeIntercept", "Charge" },          -- 1
            { "Cleave" },                                     -- 2
            { macro = "BashPummel", "Pummel", "Shield Bash" },-- 3
            { "Reckless Swings" },                            -- 4
          },
          berserker = {
            offset = 3, label = "Berserker",
            { macro = "Bloodthirst", "Bloodthirst", "Rend" },                       -- Q  slot 1 (Rend can't be cast here)
            { "Whirlwind", "Thunder Clap" },                  -- E  slot 2
            { "Heroic Strike" },                              -- R  slot 3
            { "Execute" },                                    -- T  slot 5
            { "Sunder Armor" },                               -- F  slot 4
            { "Berserker Rage" },                             -- G  reactive in this stance
            { "Intercept" },                                  -- C  gap closer
            { "Hamstring" },                                  -- V  snare / rage dump
            { macro = "ChargeIntercept", "Charge" },          -- 1  opener
            { "Cleave" },                                     -- 2  main AoE
            { "Pummel" },                                     -- 3  interrupt
            { "Reckless Swings" },                            -- 4
          },
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { macro = "Bloodthirst", "Bloodthirst", "Rend" },                -- Q  slot 1
        ["RT X"] = { macro = "Whirlwind", "Whirlwind", "Thunder Clap" }, -- E slot 2
        ["RT Y"] = { "Heroic Strike" },                       -- R  slot 3
        ["RT B"] = { "Sunder Armor" },                        -- F  slot 4
        ["LT A"] = { "Execute" },                             -- T  slot 5
        ["LT X"] = { macro = "Overpower", "Overpower" },      -- G  reactive
        ["LT B"] = { macro = "BashPummel", "Pummel", "Shield Bash" }, -- 3 interrupt
        ["LT Y"] = { "Cleave" },                              -- 2  main AoE
        ["RT Up"] = { macro = "ChargeIntercept", "Charge" },  -- 1  opener
        ["RT Down"] = { "Reckless Swings" },                  -- 4
        ["RT Left"] = { macro = "Intercept", "Intercept" },   -- C  gap closer
        ["RT Right"] = { "Hamstring" },                       -- V  snare / dump
        ["LT Up"] = { "Victory Rush" },                       -- Shift+Q
        ["LT Right"] = { "Bloodrage" },                       -- Shift+E
        ["LT Left"] = { "Disarm" },                           -- Shift+T
        ["LT Down"] = { "Intimidating Shout" },               -- Shift+F
        ["LT+RT A"] = { "Piercing Howl" },                    -- Shift+V
        ["LT+RT X"] = { "Demoralizing Shout" },               -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Death Wish" },                       -- Shift+R
        ["LT+RT Up"] = { macro = "Retaliation", "Retaliation" }, -- Ctrl+Q
        ["LT+RT Down"] = { "Taunt" },                         -- Ctrl+E
        ["LT+RT Left"] = { macro = "BerserkerRage", "Berserker Rage" }, -- Fury: rage and fear break every fight (Berserker page G); Recklessness (30 min) goes to the catch-all
        ["LT+RT Right"] = { "Challenging Shout" },            -- Ctrl+T
        ["none Up"] = { "Battle Stance" },
        ["none Left"] = { "Defensive Stance" },
        ["none Right"] = { "Berserker Stance" },
        ["none Down"] = { "Battle Shout" },
      } } } },

    -- Protection: the top-level layout below. ------------------------------
    { key = "prot", name = "Protection", tab = 3, default = true },
  },

  -- Protection keyboard. Rotation slots: Q Sunder Armor (GCD filler, most
  -- presses), E Shield Block (Wowhead's first priority, off the GCD, lights
  -- Revenge; Execute in Battle/Berserker), R Shield Slam (row 6 = 40) or Bloodthirst
  -- (Fury-Prot), Rend before, F the taunt of the stance (Taunt / Mocking
  -- Blow), T Heroic Strike (rage dump, Wowhead's last priority), G Revenge
  -- (reactive), 1 Charge, 2 Thunder Clap (AoE threat), 3 Shield Bash,
  -- 4 Cleave (pack rage dump). One move against key-roles.md: V holds
  -- Demoralizing Shout (kept up on every pull) because Defensive Stance has
  -- no snare.
  keyboard = {
    -- No-stance page (rarely seen: Battle Stance is learned at 1); mirrors
    -- Defensive with the stance-dance macros.
    [1] = {
      { macro = "Sunder", "Sunder Armor" },                                    -- Q  slot 1
      { "Shield Block" },                                     -- E  slot 2: mitigation
      { macro = "ShieldSlam", "Shield Slam", "Bloodthirst", "Rend" },              -- R  slot 3
      { "Heroic Strike" },                                    -- T  slot 5: rage dump
      { macro = "Taunt", "Taunt" },                                          -- F  slot 4: taunt
      { macro = "Revenge", "Revenge" },                       -- G  reactive (Defensive first)
      { macro = "Intercept", "Intercept" },                   -- C  gap closer
      { "Demoralizing Shout" },                               -- V  pack debuff (moved, see above)
      { macro = "TankCharge", "Charge" },                     -- 1  opener
      { "Thunder Clap" },                                     -- 2  AoE threat
      { macro = "BashPummel", "Shield Bash", "Pummel" },      -- 3  interrupt
      { "Cleave" },                                           -- 4  pack rage dump
    },
    -- Bar 2 (Shift): Q self-heal, E spec defensive, R rage burst, T control,
    -- F hard CC, G AoE control, C racial, V emergency, 1-4 stances and shout.
    [2] = {
      { "Victory Rush" },                                     -- Shift+Q  self-heal after a kill (20)
      { "Last Stand" },                                       -- Shift+E  spec defensive (talent, row 2 = 20)
      { "Bloodrage" },                                        -- Shift+R  rage at the pull (opener, any stance)
      { "Concussion Blow" },                                  -- Shift+T  stun (talent, row 4 = 30)
      { "Disarm" },                                           -- Shift+F  closest to hard CC (Defensive)
      { "Intimidating Shout" },                               -- Shift+G  AoE control
      { racial = true },                                      -- Shift+C  racial
      { macro = "ShieldWall", "Shield Wall" },                -- Shift+V  emergency
      { "Battle Stance" },                                    -- Shift+1  stance row
      { "Defensive Stance" },                                 -- Shift+2
      { "Berserker Stance" },                                 -- Shift+3
      { "Battle Shout" },                                     -- Shift+4  shout (any stance)
    },
    -- [3] is the shared Alt bar (consumables, Fish, Bait, Hearthstone).
    -- Bar 4 (Ctrl): rare presses.
    [4] = {
      { "Challenging Shout" },                                -- Ctrl+Q  AoE taunt (emergency)
      { macro = "Retaliation", "Retaliation" },               -- Ctrl+E  cooldown (Battle first; pre-pull)
      { "Recklessness" },                                     -- Ctrl+R  rare for a tank
      { "Hamstring" },                                        -- Ctrl+T  runners (Battle/Berserker)
      { "Slam" },                                             -- Ctrl+F  rare
      { "Death Wish" },                                       -- Ctrl+G  Fury-Prot cooldown (row 4 = 30)
      false, false, false, false, false, false,               -- Ctrl+C V 1 2 3 4  free
    },
    stances = {
      -- Battle Stance (offset 1): before Defensive Stance (level 10) and to
      -- Charge. Same keys; F is the Battle taunt, E Execute, G Overpower.
      battle = {
        offset = 1, label = "Battle",
        { macro = "Sunder", "Sunder Armor" },                                  -- Q  slot 1
        { "Execute" },                                        -- E  finisher in this stance (no Shield Block)
        { macro = "ShieldSlam", "Shield Slam", "Bloodthirst", "Rend" },            -- R  slot 3
        { "Heroic Strike" },                                  -- T  rage dump
        { "Mocking Blow" },                                   -- F  the Battle Stance taunt
        { "Overpower" },                                      -- G  reactive in this stance
        { macro = "Intercept", "Intercept" },                 -- C
        { "Demoralizing Shout" },                             -- V
        { macro = "TankCharge", "Charge" },                   -- 1
        { "Thunder Clap" },                                   -- 2
        { "Shield Bash" },                                    -- 3
        { "Cleave" },                                         -- 4
      },
      -- Defensive Stance (offset 2): where Protection tanks and levels.
      defensive = {
        offset = 2, label = "Defensive",
        { macro = "Sunder", "Sunder Armor" },                                  -- Q  slot 1: filler, 5 stacks
        { "Shield Block" },                                   -- E  slot 2: mitigation, lights Revenge
        { macro = "ShieldSlam", "Shield Slam", "Bloodthirst", "Rend" },            -- R  slot 3: Shield Slam / Bloodthirst / Rend
        { "Heroic Strike" },                                  -- T  slot 5: rage dump over 30 rage
        { "Taunt" },                                          -- F  slot 4: taunt
        { "Revenge" },                                        -- G  reactive
        { macro = "Intercept", "Intercept" },                 -- C  (dances to Berserker)
        { "Demoralizing Shout" },                             -- V  pack debuff
        { macro = "TankCharge", "Charge" },                   -- 1  opener (Battle first, back after)
        { "Thunder Clap" },                                   -- 2  AoE threat
        { "Shield Bash" },                                    -- 3  interrupt
        { "Cleave" },                                         -- 4  pack rage dump
      },
      -- Berserker Stance (offset 3): only after a fear break or Intercept.
      berserker = {
        offset = 3, label = "Berserker",
        { macro = "Sunder", "Sunder Armor" },                                  -- Q
        { "Execute" },                                        -- E
        { macro = "ShieldSlam", "Shield Slam", "Bloodthirst", "Rend" },            -- R
        { "Heroic Strike" },                                  -- T
        false,                                                -- F  (no taunt in this stance)
        { "Berserker Rage" },                                 -- G  reactive (fear)
        { "Intercept" },                                      -- C
        { "Demoralizing Shout" },                             -- V
        { macro = "TankCharge", "Charge" },                   -- 1  (back to Defensive in combat)
        { "Whirlwind" },                                      -- 2  AoE in this stance
        { "Pummel" },                                         -- 3  interrupt in this stance
        { "Cleave" },                                         -- 4
      },
    },
  },

  -- Controller: keys "<layer> <button>". One layout for every stance (Apply
  -- mirrors RT into the Gamepad UI's stance bar).
  controller = {
    pages = {
      -- Page 1 (Protection; Arms and Fury have their own above). The whole
      -- tank rotation is on RT/LT face buttons and the RT D-pad.
      {
        title = "Combat",
        ["RT A"] = { macro = "Sunder", "Sunder Armor" },                       -- Q  slot 1
        ["RT X"] = { "Shield Block" },                        -- E  slot 2: mitigation
        ["RT Y"] = { macro = "ShieldSlam", "Shield Slam", "Bloodthirst", "Rend" }, -- R  slot 3
        ["RT B"] = { macro = "Taunt", "Taunt" },                              -- F  slot 4: taunt
        ["LT A"] = { "Heroic Strike" },                       -- T  slot 5: rage dump
        ["LT X"] = { macro = "Revenge", "Revenge" },          -- G  reactive (Defensive + Shield Block first)
        ["LT B"] = { macro = "BashPummel", "Shield Bash", "Pummel" }, -- 3 interrupt
        ["LT Y"] = { "Thunder Clap" },                        -- 2  AoE threat
        ["RT Up"] = { macro = "TankCharge", "Charge" },       -- 1  opener
        ["RT Down"] = { "Cleave" },                           -- 4  pack rage dump
        ["RT Left"] = { macro = "Intercept", "Intercept" },   -- C  gap closer
        ["RT Right"] = { "Demoralizing Shout" },              -- V  pack debuff
        ["LT Up"] = { "Victory Rush" },                       -- Shift+Q
        ["LT Right"] = { "Last Stand" },                      -- Shift+E
        ["LT Left"] = { "Concussion Blow" },                  -- Shift+T
        ["LT Down"] = { "Disarm" },                           -- Shift+F
        ["LT+RT A"] = { macro = "ShieldWall", "Shield Wall" },-- Shift+V
        ["LT+RT X"] = { "Intimidating Shout" },               -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Bloodrage" },                        -- Shift+R
        ["LT+RT Up"] = { "Challenging Shout" },               -- Ctrl+Q
        ["LT+RT Down"] = { macro = "Retaliation", "Retaliation" }, -- Ctrl+E
        ["LT+RT Left"] = { "Recklessness" },                  -- Ctrl+R
        ["LT+RT Right"] = { "Hamstring" },                    -- Ctrl+T
        -- No trigger: the stance row and the shout.
        ["none Up"] = { "Battle Stance" },
        ["none Left"] = { "Defensive Stance" },
        ["none Right"] = { "Berserker Stance" },
        ["none Down"] = { "Battle Shout" },
      },
      -- Page 2: only the shared Utility buttons (Layouts/Shared.lua).
      {
        title = "Utility",
      },
      -- Page 3 (every spec): Mocking Blow's stance dance (no page 1 holds it),
      -- Steam Deck helpers and the catch-all (Overpower, Execute, Slam,
      -- Whirlwind, Death Wish... whatever the spec's page 1 lacks).
      {
        title = "Extras",
        ["RT A"] = { macro = "MockingBlow", "Mocking Blow" },
        ["RT Y"] = { overflow = true },   -- Berserker Rage: Fury page 1 LT+RT Left; Arms and Prot get it here from the catch-all
        ["RT X"] = { overflow = true }, ["RT B"] = { overflow = true },
        ["RT Up"] = { overflow = true }, ["RT Down"] = { overflow = true },
        ["RT Left"] = { overflow = true }, ["RT Right"] = { overflow = true },
        -- Only what the game menu, vendor window and Steam don't already do.
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
    -- Back buttons left unbound (owner's choice).
    paddles = {},
  },
})
