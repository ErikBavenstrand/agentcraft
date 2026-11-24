-- Paladin layouts. Data contract: dev/layout-format.md; key roles shared by
-- every class: dev/key-roles.md (the BM hunter is the reference). Keep every
-- value a literal (no variables, no function calls): dev.ps1 rules reads
-- this file without running Lua.
--
-- Retribution is the leveling spec (research 2026-11: Icy Veins, Mobalytics).
-- Paladins have no stance paging. One layout serves Retribution and
-- Protection; the build's talent (Holy Shock / Holy Shield / Repentance)
-- sits on T by chain. Holy follows the healer rule: heals on plain Q E R T
-- and 1, its damage on Shift Q E R T, the rest as shared.
--
-- WoW Forever changes (Warcraft Tavern, Wowhead deep dive): Judgement no
-- longer uses up the Seal (its debuffs last 40 s), so seals are buffs you
-- set and Judgement is a maintained debuff; Seal of Fury (10) is the tank
-- seal and judges as a ranged taunt; Holy Strike (6), Consecration (20) and
-- Seal of Command (20) are baseline; Blessings last an hour (side bars,
-- except the short Protection, Freedom and Sacrifice); Salvation and
-- Blessing of Light are gone.
--
-- Key roles (dev/key-roles.md) and how the paladin fills them:
--   Q main attack  Holy Strike            E maintained debuff  Judgement
--   R big hitter   Exorcism (ExoJudge)    T signature   Holy Shock / Holy Shield / Repentance
--   F melee        your fighting seal: Righteousness, then Command (20)
--   G proc         Hammer of Wrath (HammerJudge, under 20%)
--   C mobility     Blessing of Freedom    V snare: none; Seal of Justice (stops runners)
--   1 opener       Seal of the Crusader (Ret judges it first, then fights in Command)
--   2 main AoE     Holy Wrath (Undead and Demons)
--   3 control      Turn Undead (no interrupt: Hammer of Justice is the hard CC on Shift+F)
--   4 ground AoE   Consecration
-- Shift: Q Flash of Light (self), E Lay on Hands, R Holy Light (no burst
-- cooldown before 60), T Cleanse, F Hammer of Justice, G Blessing of
-- Protection, C racial, V Divine Shield, 1-4 Righteous Fury and the seals
-- you set for a fight (Fury, Wisdom, Light). Ctrl: Q E R T free (no
-- secondary attacks), F G C rescue spells, 1 2 3 the auras.
local _, ns = ...

ns.Layout.Register("PALADIN", {
  specs = {
    -- Holy (healer rule): heals on Q E R T and 1, damage on Shift Q E R T;
    -- F G C V, 2 3 4 and Shift F G C V stay as shared.
    { key = "holy", name = "Holy", tab = 1,
      keyboard = {
        [1] = {
          { macro = "SmartFlash", "Flash of Light" },     -- Q  main heal: target if friendly, else yourself
          { "Cleanse", "Purify", upgrade = true },        -- E  no HoT: the dispel you keep pressing
          { macro = "SmartLight", "Holy Light" },         -- R  big heal
          { "Holy Shock", "Holy Shield", "Repentance" },  -- T  spec heal: Holy Shock
          { "Seal of Command", "Seal of Righteousness" }, -- F  fighting seal (as shared)
          { macro = "HammerJudge", "Hammer of Wrath" },   -- G  proc: Judgement, then Hammer of Wrath (<20%)
          { "Blessing of Freedom" },                      -- C  mobility
          { "Seal of Justice" },                          -- V  no snare: stops runners
          { "Seal of Wisdom" },                           -- 1  no group heal: the healer's seal (judge it for mana)
          { "Holy Wrath" },                               -- 2  AoE (Undead and Demons)
          { "Turn Undead" },                              -- 3  control (Undead)
          { "Consecration" },                             -- 4  ground AoE
        },
        [2] = {
          { "Holy Strike" },                              -- Shift+Q  damage: main attack
          { "Judgement" },                                -- Shift+E  damage: maintained debuff
          { macro = "ExoJudge", "Exorcism" },             -- Shift+R  damage: big hitter
          { "Lay on Hands" },                             -- Shift+T  no damage signature: Lay on Hands
          { "Hammer of Justice" },                        -- Shift+F  hard CC
          { "Blessing of Protection" },                   -- Shift+G  save an ally (no AoE control)
          { racial = true },                              -- Shift+C  racial
          { "Divine Shield", "Divine Protection", upgrade = true }, -- Shift+V  emergency
          { "Righteous Fury" },                           -- Shift+1  buff
          { "Seal of Fury" },                             -- Shift+2  seal
          { "Seal of the Crusader" },                     -- Shift+3  seal (Wisdom is on plain 1)
          { "Seal of Light" },                            -- Shift+4  seal
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { macro = "SmartFlash", "Flash of Light" },     -- Q
        ["RT X"] = { "Cleanse", "Purify", upgrade = true },        -- E
        ["RT B"] = { "Turn Undead" },                              -- 3
        ["RT Y"] = { "Holy Wrath" },                               -- 2
        ["RT Up"] = { "Seal of Wisdom" },                          -- 1
        ["RT Right"] = { macro = "SmartLight", "Holy Light" },     -- R
        ["RT Left"] = { "Holy Shock", "Holy Shield", "Repentance" }, -- T
        ["RT Down"] = { "Consecration" },                          -- 4
        ["LT A"] = { "Seal of Command", "Seal of Righteousness" }, -- F
        ["LT X"] = { macro = "HammerJudge", "Hammer of Wrath" },   -- G
        ["LT B"] = { "Seal of Justice" },                          -- V
        ["LT Y"] = { "Blessing of Freedom" },                      -- C
        ["LT Up"] = { "Holy Strike" },                             -- Shift+Q
        ["LT Down"] = { "Hammer of Justice" },                     -- Shift+F
        ["LT Left"] = { "Lay on Hands" },                          -- Shift+T
        ["LT Right"] = { "Judgement" },                            -- Shift+E
        ["none Up"] = { "Devotion Aura" },                         -- auras
        ["none Left"] = { "Retribution Aura" },
        ["none Right"] = { "Concentration Aura" },
        ["none Down"] = { "Righteous Fury" },
        ["LT+RT A"] = { "Divine Shield", "Divine Protection", upgrade = true }, -- Shift+V
        ["LT+RT X"] = { "Blessing of Protection" },                -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { macro = "ExoJudge", "Exorcism" },          -- Shift+R
        ["LT+RT Up"] = { "Seal of Fury" },                         -- seals
        ["LT+RT Down"] = { "Seal of the Crusader" },
        ["LT+RT Left"] = { "Seal of Light" },
      } } },
    },
    { key = "prot", name = "Protection", tab = 2 },
    { key = "ret", name = "Retribution", tab = 3, default = true },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  keyboard = {
    -- Bar 1: Q E R T rotation, F G C V seal, execute and utility, 1 2 3 4
    -- pull, AoE and control (spell levels in brackets).
    [1] = {
      { "Holy Strike" },                                -- Q  main attack (6)
      { "Judgement" },                                  -- E  maintained debuff: judge your seal (4)
      { macro = "ExoJudge", "Exorcism" },               -- R  big hitter: Judgement, then Exorcism (Undead/Demon) (20)
      { "Holy Shock", "Holy Shield", "Repentance" },    -- T  build signature: Holy / Prot / Ret talent
      { "Seal of Command", "Seal of Righteousness" },   -- F  fighting seal: Righteousness (1) until Command (20)
      { macro = "HammerJudge", "Hammer of Wrath" },     -- G  proc: Judgement, then Hammer of Wrath (<20%) (44)
      { "Blessing of Freedom" },                        -- C  mobility: breaks roots and snares (18)
      { "Seal of Justice" },                            -- V  no snare: judged, it stops runners (22)
      { "Seal of the Crusader" },                       -- 1  opener: Ret judges Crusader first (6)
      { "Holy Wrath" },                                 -- 2  AoE vs Undead and Demons (50)
      { "Turn Undead" },                                -- 3  control: fears an Undead (24)
      { "Consecration" },                               -- 4  ground AoE; Prot's threat (20)
    },
    -- Bar 2 (Shift): Q self-heal, E defensive cooldown, R big heal, T
    -- dispel, F hard CC, G ally save, C racial, V emergency, 1-4 Righteous
    -- Fury and the seals you set for a fight.
    [2] = {
      { macro = "SmartFlash", "Flash of Light" },       -- Shift+Q  self-heal: target if friendly, else yourself (20)
      { "Lay on Hands" },                               -- Shift+E  defensive cooldown: full heal (10; 20 min)
      { macro = "SmartLight", "Holy Light" },           -- Shift+R  no burst cooldown: Holy Light, the big heal (1)
      { "Cleanse", "Purify", upgrade = true },          -- Shift+T  no second control spell: the dispel (8 / 42)
      { "Hammer of Justice" },                          -- Shift+F  hard CC: stun, also interrupts (8)
      { "Blessing of Protection" },                     -- Shift+G  no AoE control: save an ally (10)
      { racial = true },                                -- Shift+C  racial
      { "Divine Shield", "Divine Protection", upgrade = true }, -- Shift+V  emergency (6 / 34)
      { "Righteous Fury" },                             -- Shift+1  Prot: threat buff (10)
      { "Seal of Fury" },                               -- Shift+2  Prot: the tank seal (10)
      { "Seal of Wisdom" },                             -- Shift+3  judge it for mana (38)
      { "Seal of Light" },                              -- Shift+4  judge it for heals (30)
    },
    -- [3] is the Alt bar (trinkets, Fish, Bait, Hearthstone), not set here.
    -- Bar 4 (Ctrl): paladins have no secondary attacks (Q E R T free), F G
    -- C the rescue spells, 1 2 3 the auras you switch between. Blessings
    -- (an hour long) and resistance auras go to the side bars.
    [4] = {
      false,                                            -- Ctrl+Q  (no secondary attack)
      false,                                            -- Ctrl+E  (no secondary debuff)
      false,                                            -- Ctrl+R
      false,                                            -- Ctrl+T
      { "Redemption" },                                 -- Ctrl+F  resurrect (12)
      { "Divine Intervention" },                        -- Ctrl+G  save a party member (30)
      { "Blessing of Sacrifice" },                      -- Ctrl+C  short blessing: take an ally's damage (46)
      false,                                            -- Ctrl+V
      { "Devotion Aura" },                              -- Ctrl+1  aura: solo and tanking (1)
      { "Retribution Aura" },                           -- Ctrl+2  aura: groups (16)
      { "Concentration Aura" },                         -- Ctrl+3  aura: casting (22)
      false,                                            -- Ctrl+4
    },
  },

  -- Controller: keys "<layer> <button>", layer none / LT / RT / LT+RT,
  -- button A X B Y or Up Down Left Right (D-pad). The Top bar's face buttons
  -- are fixed. Same page roles as the hunter.
  controller = {
    pages = {
      -- Page 1 mirrors the keyboard roles (dev/key-roles.md): RT = plain
      -- Q E 3 2 1 R T 4, LT = plain F G V C and Shift Q F T E, LT+RT =
      -- Shift V G, racial, Shift R and (Ctrl Q E R T being empty) the
      -- Shift row's seals; no trigger = the auras and Righteous Fury.
      {
        title = "Combat",
        ["RT A"] = { "Holy Strike" },                              -- Q
        ["RT X"] = { "Judgement" },                                -- E
        ["RT B"] = { "Turn Undead" },                              -- 3
        ["RT Y"] = { "Holy Wrath" },                               -- 2
        ["RT Up"] = { "Seal of the Crusader" },                    -- 1
        ["RT Right"] = { macro = "ExoJudge", "Exorcism" },         -- R
        ["RT Left"] = { "Holy Shock", "Holy Shield", "Repentance" }, -- T
        ["RT Down"] = { "Consecration" },                          -- 4
        ["LT A"] = { "Seal of Command", "Seal of Righteousness" }, -- F
        ["LT X"] = { macro = "HammerJudge", "Hammer of Wrath" },   -- G
        ["LT B"] = { "Seal of Justice" },                          -- V
        ["LT Y"] = { "Blessing of Freedom" },                      -- C
        ["LT Up"] = { macro = "SmartFlash", "Flash of Light" },    -- Shift+Q
        ["LT Down"] = { "Hammer of Justice" },                     -- Shift+F
        ["LT Left"] = { "Cleanse", "Purify", upgrade = true },     -- Shift+T
        ["LT Right"] = { "Lay on Hands" },                         -- Shift+E
        -- No trigger: the auras you switch between, and Righteous Fury.
        ["none Up"] = { "Devotion Aura" },
        ["none Left"] = { "Retribution Aura" },
        ["none Right"] = { "Concentration Aura" },
        ["none Down"] = { "Righteous Fury" },
        ["LT+RT A"] = { "Divine Shield", "Divine Protection", upgrade = true }, -- Shift+V
        ["LT+RT X"] = { "Blessing of Protection" },                -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { macro = "SmartLight", "Holy Light" },      -- Shift+R
        ["LT+RT Up"] = { "Seal of Fury" },                         -- Shift+2
        ["LT+RT Down"] = { "Seal of Wisdom" },                     -- Shift+3
        ["LT+RT Left"] = { "Seal of Light" },                      -- Shift+4
      },
      -- Page 2: blessings and rez; the shared Utility buttons
      -- (Layouts/Shared.lua) add Hearthstone, trinkets, fishing, camp, Mount
      -- and professions.
      {
        title = "Utility",
        ["RT A"] = { "Redemption" },
        ["RT X"] = { "Blessing of Might" },
        ["RT B"] = { "Blessing of Wisdom" },
        ["RT Y"] = { "Blessing of Kings" },
        ["RT Down"] = { overflow = true },
        ["RT Left"] = { "Divine Intervention" },
        ["RT Right"] = { "Blessing of Sacrifice" },
      },
      -- Page 3: Steam Deck helpers and the catch-all (other auras, mounts,
      -- talents with no key).
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
        ["LT+RT X"] = { overflow = true }, ["LT+RT B"] = { overflow = true },
        ["LT+RT Y"] = { overflow = true }, ["LT+RT Up"] = { overflow = true },
        ["LT+RT Down"] = { overflow = true }, ["LT+RT Left"] = { overflow = true },
        ["LT+RT Right"] = { overflow = true },
      },
    },
    paddles = {},
  },
})
