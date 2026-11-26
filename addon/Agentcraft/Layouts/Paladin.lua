-- Paladin layouts. Data contract: dev/layout-format.md; key roles shared by
-- every class: dev/key-roles.md (rotation slots). Keep every value a literal
-- (no variables, no function calls): dev.ps1 rules reads this file without
-- running Lua. Paladins have no stance paging.
--
-- Sources (Wowhead WoW Forever guides, 2026-11; they win any disagreement;
-- talent rows: dev/forever-talents.md, row r = level 10 + 5r, earlier with
-- the Legacy perk Talented):
--   https://www.wowhead.com/forever/guide/classes/paladin/retribution/rotation-cooldowns-pve-dps
--   https://www.wowhead.com/forever/guide/classes/paladin/retribution/dps-leveling-tips
--   https://www.wowhead.com/forever/guide/classes/paladin/protection/rotation-cooldowns-pve-tank
--   https://www.wowhead.com/forever/guide/classes/paladin/protection/tank-leveling-tips
--   https://www.wowhead.com/forever/guide/classes/paladin/holy/rotation-cooldowns-pve-healer
--   https://www.wowhead.com/forever/guide/classes/paladin/holy/healer-leveling-tips
--
-- WoW Forever changes: Judgement no longer uses up the Seal and is off the
-- global cooldown, so a seal is a buff you keep and Judgement a button you
-- press on cooldown. Holy Strike (6, 10 s cooldown) and Consecration (20,
-- full effect on 4 targets) are baseline; Seal of Fury (10) is the tank
-- seal and its Judgement (of Fury) taunts for 3 s; Seal of Command is a
-- Retribution talent (row 2 = 20). Blessings last an hour (side bars). The
-- Retribution capstone (row 6) is Unsealed Wrath, a passive (no button; it
-- replaced Twist of Light): your
-- swings store Seal of Command stacks, and at 3 you switch to Seal of
-- Righteousness for one swing to spend them, then back.
--
-- Rotations (Wowhead priority lists):
--   Retribution (leveling spec). Judge Seal of the Crusader on enemies that
--     live (elites, bosses), then: keep Seal of Command up (talent, row 2 = 20;
--     Righteousness before 20 and with a fast one-hander) > Judgement on
--     cooldown > Hammer of Wrath under 20% (44) > Holy Strike on cooldown >
--     at 3 Unsealed Wrath stacks swap to Righteousness for a swing (40) >
--     Exorcism on Undead/Demons (20) > Consecration only when AoE is needed
--     (mana). "Shockadin" build: Righteousness only, Judgement >
--     Consecration > Holy Strike > Holy Shock > Hammer of Wrath > Exorcism,
--     Divine Favor on cooldown. No damage cooldown. Stun: Hammer of Justice.
--   Protection (tank). Righteous Fury and Retribution Aura before the pull;
--     first Judgement under Seal of the Crusader or Wisdom, then: keep Seal
--     of Fury up > Judgement (off the GCD; Judgement of Fury is the taunt)
--     > Consecration if mana allows > Holy Shock (Holy talent, row 4 = 30)
--     > Holy Shield (talent, row 4 = 30) > Holy Strike > Exorcism on
--     Undead/Demons > Hammer of
--     Wrath on 0-1 targets > Holy Wrath on Undead/Demons when not tanking.
--     AoE: the same, Consecration and Holy Wrath higher. Cooldowns:
--     Templar's Bulwark (the only defensive cooldown, talent, row 2 = 20),
--     Swift Judgement (talent, row 3 = 25: resets Judgement; opener threat,
--     backup taunt),
--     Divine Shield (taunt from the bubble), Blessing of Protection, Lay on
--     Hands. Leveling: the same buttons. Shieldsworn (the row-6 capstone)
--     is a passive: no button.
--   Holy (healer). Seal of Light and Judgement on the main enemy > Light's
--     Vigil on a group member ahead of group damage (talent, row 6 = 40) >
--     Holy Shock to set it off (talent, row 4 = 30; 10 s) > Holy Light on
--     Infusion of Light
--     procs > Holy Shock when there's no time to cast > Flash of Light for
--     most heals, Holy Light for big ones. Divine Favor (Holy talent, row 2
--     = 20: the next Holy Shock crits). Cooldowns: Lay on Hands, Divine
--     Shield / Protection, Blessing of Protection, Voice of Truth (trainer
--     spell, 20: immune to silence and interrupts). Oath of Light (talent,
--     row 3 = 25): "Swear an Oath to protect target ally for 1 hour", one
--     Oath at a time, so a buff-row key (Shift+3; no-trigger D-pad Right),
--     not a rotation slot. Solo damage, one tier down: Righteousness >
--     Judgement > Holy Strike > Exorcism > Holy Shock > Consecration.
--
-- Rotation slots (dev/key-roles.md) per spec:
--          Q             E          R             F            T             G
--   Ret    Holy Strike   Judgement  Righteous.    Exorcism     Command/Shock Hammer of Wrath
--   Prot   Holy Strike   Judgement  Holy Shield   Exorcism     Seal of Fury  Hammer of Wrath
--   Holy   Flash         Judgement  Holy Light    Holy Shock   Cleanse       Divine Favor
--   1 opener Crusader (Holy: Seal of Light), 2 AoE Consecration (Holy:
--   Light's Vigil), 3 Hammer of Justice (a stun; paladins have no true
--   interrupt), 4 Holy Wrath (Holy: Voice of Truth), C Blessing of Freedom,
--   V Seal of Justice (stops runners).
-- Holy Strike and Judgement share a cooldown before Improved Judgement and
-- Wowhead says to press them together (5-second rule), so they sit on Q and
-- E in every spec. Judgement is Prot's taunt too (Judgement of Fury), so
-- the taunt slot F keeps Exorcism; Swift Judgement, the backup taunt and
-- opener threat cooldown, takes Prot's empty burst slot (Shift+R).
local _, ns = ...

ns.Layout.Register("PALADIN", {
  specs = {
    -- Holy (healer rule): heals on the plain keys and the RT/LT face
    -- buttons; damage one tier down (Shift / LT+RT).
    { key = "holy", name = "Holy", tab = 1,
      keyboard = {
        [1] = {
          { macro = "SmartFlash", "Flash of Light" },     -- Q  slot 1: most heals, quick and cheap (20)
          { "Judgement" },                                -- E  slot 2: judge Seal of Light on the main enemy (4)
          { macro = "SmartLight", "Holy Light" },         -- R  slot 3: big heal, Infusion of Light procs (1)
          { "Cleanse", "Purify", upgrade = true },        -- T  slot 5: healer dispel (8 / 42)
          { macro = "SmartShock", "Holy Shock" },         -- F  slot 4: instant heal, sets off Light's Vigil (talent, row 4 = 30)
          { "Divine Favor" },                             -- G  reactive: next Holy Shock crits (talent, row 2 = 20; 2 min)
          { "Blessing of Freedom" },                      -- C  mobility (18)
          { "Seal of Justice" },                          -- V  stops runners (22)
          { "Seal of Light" },                            -- 1  opener: the seal Wowhead judges, set before the pull (30)
          { "Light's Vigil" },                            -- 2  group heal: on a group member, then Holy Shock (talent, row 6 = 40)
          { macro = "HoJ", "Hammer of Justice" },                      -- 3  stun (8)
          { "Voice of Truth" },                           -- 4  situational: cast through silences (trainer, 20)
        },
        [2] = {
          { "Holy Strike" },                              -- Shift+Q  solo damage: main attack (6)
          { "Divine Shield", "Divine Protection", upgrade = true }, -- Shift+E  defensive (6 / 34)
          { macro = "ExoJudge", "Exorcism" },             -- Shift+R  solo damage: Undead/Demons (20)
          { "Seal of Righteousness" },                    -- Shift+T  solo damage: the seal Wowhead keeps up (1)
          { "Blessing of Protection" },                   -- Shift+F  no hard CC (Justice is on 3): save an ally (10)
          { "Consecration" },                             -- Shift+G  solo damage: AoE (20)
          { racial = true },                              -- Shift+C  racial
          { macro = "LayOnHands", "Lay on Hands" },                           -- Shift+V  emergency: full heal (10; 20 min)
          { "Seal of Wisdom" },                           -- Shift+1  seal row: mana (38)
          { "Seal of the Crusader" },                     -- Shift+2  seal row (6)
          { "Oath of Light" },                            -- Shift+3  buff row: 1-hour Oath on the tank (talent, row 3 = 25)
          { macro = "HammerJudge", "Hammer of Wrath" },   -- Shift+4  solo damage: execute (44)
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { macro = "SmartFlash", "Flash of Light" },     -- Q  most heals
        ["RT X"] = { "Judgement" },                                -- E  judge Seal of Light
        ["RT Y"] = { macro = "SmartLight", "Holy Light" },         -- R  big heal
        ["RT B"] = { macro = "SmartShock", "Holy Shock" },         -- F  instant heal
        ["LT A"] = { "Cleanse", "Purify", upgrade = true },        -- T  dispel
        ["LT X"] = { "Divine Favor" },                             -- G  reactive
        ["LT B"] = { macro = "HoJ", "Hammer of Justice" },                      -- 3  stun
        ["LT Y"] = { "Light's Vigil" },                            -- 2  group heal
        ["RT Up"] = { "Seal of Light" },                           -- 1  seal before the pull
        ["RT Down"] = { "Voice of Truth" },                        -- 4  through silences
        ["RT Left"] = { "Blessing of Freedom" },                   -- C
        ["RT Right"] = { "Seal of Justice" },                      -- V
        ["LT Up"] = { "Holy Strike" },                             -- Shift+Q  solo damage
        ["LT Right"] = { "Divine Shield", "Divine Protection", upgrade = true }, -- Shift+E
        ["LT Left"] = { "Seal of Righteousness" },                 -- Shift+T  solo seal
        ["LT Down"] = { "Blessing of Protection" },                -- Shift+F
        ["LT+RT A"] = { macro = "LayOnHands", "Lay on Hands" },                        -- Shift+V  emergency
        ["LT+RT X"] = { "Consecration" },                          -- Shift+G  solo AoE
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { macro = "ExoJudge", "Exorcism" },          -- Shift+R  solo nuke
        ["LT+RT Up"] = { "Turn Undead" },                          -- Ctrl+Q
        ["LT+RT Down"] = { "Blessing of Sacrifice" },              -- Ctrl+E
        ["LT+RT Left"] = { "Divine Intervention" },                -- Ctrl+R
        ["LT+RT Right"] = { macro = "HammerJudge", "Hammer of Wrath" }, -- Shift+4  solo execute
        -- No trigger: auras, the Oath and the mana seal, set out of combat
        -- (Retribution Aura and Seal of Fury go to the Extras overflow).
        ["none Up"] = { "Devotion Aura" },
        ["none Left"] = { "Concentration Aura" },
        ["none Right"] = { "Oath of Light" },                      -- Shift+3  1-hour Oath on an ally
        ["none Down"] = { "Seal of Wisdom" },
      } } },
    },
    { key = "prot", name = "Protection", tab = 2,
      keyboard = {
        [1] = {
          { macro = "HolyStrike", "Holy Strike" },                            -- Q  slot 1: on cooldown, pressed with Judgement (6)
          { "Judgement" },                                -- E  slot 2: on cooldown, off the GCD; the taunt under Seal of Fury (4)
          { "Holy Shield", "Holy Shock" },                -- R  slot 3: on cooldown (Holy Shield talent, row 4 = 30; Holy Shock build)
          { "Seal of Fury", "Seal of Righteousness" },    -- T  slot 5: keep the tank seal up (10; Righteousness before)
          { macro = "ExoJudge", "Exorcism" },             -- F  slot 4: Undead/Demons (20)
          { macro = "HammerJudge", "Hammer of Wrath" },   -- G  reactive: under 20%, on 0-1 targets (44)
          { "Blessing of Freedom" },                      -- C  mobility (18)
          { "Seal of Justice" },                          -- V  stops runners (22)
          { "Seal of the Crusader" },                     -- 1  opener: judge Crusader, then Seal of Fury (6)
          { "Consecration" },                             -- 2  AoE threat, high in both priorities (20)
          { macro = "HoJ", "Hammer of Justice" },                      -- 3  stun (8)
          { "Holy Wrath" },                               -- 4  secondary AoE: Undead/Demons when not tanking (50)
        },
        [2] = {
          { macro = "SmartFlash", "Flash of Light" },     -- Shift+Q  self-heal (20)
          { "Templar's Bulwark" },                        -- Shift+E  spec defensive: the only one, for big damage (talent, row 2 = 20)
          { "Swift Judgement" },                          -- Shift+R  no burst: resets Judgement, opener threat and backup taunt (talent, row 3 = 25)
          { "Cleanse", "Purify", upgrade = true },        -- Shift+T  dispel (8 / 42)
          { "Divine Shield", "Divine Protection", upgrade = true }, -- Shift+F  no hard CC: bubble, then taunt (6 / 34)
          { "Blessing of Protection" },                   -- Shift+G  save an ally (10)
          { racial = true },                              -- Shift+C  racial
          { macro = "LayOnHands", "Lay on Hands" },                           -- Shift+V  emergency: full heal (10; 20 min)
          { "Righteous Fury" },                           -- Shift+1  threat buff, always on (16)
          { "Seal of Wisdom" },                           -- Shift+2  seal row: the other first Judgement (38)
          { "Seal of Light" },                            -- Shift+3  seal row (30)
          { macro = "SmartLight", "Holy Light" },         -- Shift+4  big heal between pulls (1)
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { macro = "HolyStrike", "Holy Strike" },                            -- Q
        ["RT X"] = { "Judgement" },                                -- E  threat and taunt
        ["RT Y"] = { "Holy Shield", "Holy Shock" },                -- R
        ["RT B"] = { macro = "ExoJudge", "Exorcism" },             -- F
        ["LT A"] = { "Seal of Fury", "Seal of Righteousness" },    -- T
        ["LT X"] = { macro = "HammerJudge", "Hammer of Wrath" },   -- G
        ["LT B"] = { macro = "HoJ", "Hammer of Justice" },                      -- 3  stun
        ["LT Y"] = { "Consecration" },                             -- 2  AoE threat
        ["RT Up"] = { "Seal of the Crusader" },                    -- 1  opener
        ["RT Down"] = { "Holy Wrath" },                            -- 4
        ["RT Left"] = { "Blessing of Freedom" },                   -- C
        ["RT Right"] = { "Seal of Justice" },                      -- V
        ["LT Up"] = { macro = "SmartFlash", "Flash of Light" },    -- Shift+Q
        ["LT Right"] = { "Templar's Bulwark" },                    -- Shift+E
        ["LT Left"] = { "Cleanse", "Purify", upgrade = true },     -- Shift+T
        ["LT Down"] = { "Divine Shield", "Divine Protection", upgrade = true }, -- Shift+F
        ["LT+RT A"] = { macro = "LayOnHands", "Lay on Hands" },                        -- Shift+V
        ["LT+RT X"] = { "Blessing of Protection" },                -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Swift Judgement" },                       -- Shift+R
        ["LT+RT Up"] = { "Turn Undead" },                          -- Ctrl+Q
        ["LT+RT Down"] = { "Blessing of Sacrifice" },              -- Ctrl+E
        ["LT+RT Left"] = { "Divine Intervention" },                -- Ctrl+R
        ["LT+RT Right"] = { macro = "SmartLight", "Holy Light" },  -- Shift+4
        ["none Up"] = { "Devotion Aura" },
        ["none Left"] = { "Concentration Aura" },
        ["none Right"] = { "Retribution Aura" },
        ["none Down"] = { "Righteous Fury" },                      -- Shift+1, set out of combat
      } } },
    },
    { key = "ret", name = "Retribution", tab = 3, default = true },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  -- The shared bars are Retribution's; Holy and Protection override Bars 1
  -- and 2 and share Bar 4.
  keyboard = {
    [1] = {
      { macro = "HolyStrike", "Holy Strike" },                              -- Q  slot 1: on cooldown (6)
      { "Judgement" },                                  -- E  slot 2: on cooldown, seal stays (4)
      { "Seal of Righteousness" },                      -- R  slot 3: the seal before 20 and for Shockadin; the Unsealed Wrath swap every 3 swings (1)
      { macro = "ShockAny", "Holy Shock", "Seal of Command" },            -- T  slot 5: Seal of Command, kept up (talent, row 2 = 20); Shockadin: Holy Shock (row 4 = 30)
      { macro = "ExoJudge", "Exorcism" },               -- F  slot 4: Undead/Demons (20)
      { macro = "HammerJudge", "Hammer of Wrath" },     -- G  reactive: under 20%, above Holy Strike (44)
      { "Blessing of Freedom" },                        -- C  mobility: breaks roots and snares (18)
      { "Seal of Justice" },                            -- V  snare: judged, it stops runners (22)
      { "Seal of the Crusader" },                       -- 1  opener: judge Crusader on enemies that live (6)
      { "Consecration" },                               -- 2  main AoE, only when needed: mana (20)
      { macro = "HoJ", "Hammer of Justice" },                        -- 3  stun; paladins have no true interrupt (8)
      { "Holy Wrath" },                                 -- 4  secondary AoE: Undead/Demons (50)
    },
    -- Bar 2 (Shift): Q self-heal, E defensive, R Divine Favor (Shockadin's
    -- one cooldown; Ret has no burst), T dispel, F hard CC, G ally save, C
    -- racial, V emergency, 1-3 the seals you set for a fight, 4 Holy Light.
    -- Righteous Fury (tanking only) is left to the side bars.
    [2] = {
      { macro = "SmartFlash", "Flash of Light" },       -- Shift+Q  self-heal: target if friendly, else yourself (20)
      { "Divine Shield", "Divine Protection", upgrade = true }, -- Shift+E  defensive (6 / 34)
      { "Divine Favor" },                               -- Shift+R  burst: Shockadin, on cooldown (Holy talent, row 2 = 20)
      { "Cleanse", "Purify", upgrade = true },          -- Shift+T  dispel (8 / 42)
      { macro = "Repent", "Repentance" },               -- Shift+F  hard CC (Ret talent, row 4 = 30)
      { "Blessing of Protection" },                     -- Shift+G  save an ally (10)
      { racial = true },                                -- Shift+C  racial
      { macro = "LayOnHands", "Lay on Hands" },                             -- Shift+V  emergency: full heal (10; 20 min)
      { "Seal of Wisdom" },                             -- Shift+1  seal row: mana (38)
      { "Seal of Light" },                              -- Shift+2  seal row: sustain (30)
      { "Seal of Fury" },                               -- Shift+3  seal row: tanking (10)
      { macro = "SmartLight", "Holy Light" },           -- Shift+4  big heal between pulls (1)
    },
    -- [3] is the Alt bar (shared item macros), not set here.
    -- Bar 4 (Ctrl): rare presses; auras on 1 2 3. Blessings (an hour long)
    -- and resistance auras go to the side bars.
    [4] = {
      { "Turn Undead" },                                -- Ctrl+Q  rare: fear an Undead (24)
      { "Blessing of Sacrifice" },                      -- Ctrl+E  rare: take an ally's damage (46)
      { "Divine Intervention" },                        -- Ctrl+R  rare: wipe protection (30)
      false,                                            -- Ctrl+T
      { "Redemption" },                                 -- Ctrl+F  resurrect (12)
      false,                                            -- Ctrl+G
      false,                                            -- Ctrl+C
      false,                                            -- Ctrl+V
      { "Devotion Aura" },                              -- Ctrl+1  aura: solo and tanking (1)
      { "Retribution Aura" },                           -- Ctrl+2  aura: groups (16)
      { "Concentration Aura" },                         -- Ctrl+3  aura: casting (22)
      false,                                            -- Ctrl+4
    },
  },

  -- Controller: keys "<layer> <button>", layer none / LT / RT / LT+RT,
  -- button A X B Y or Up Down Left Right (D-pad). The Top bar's face buttons
  -- are fixed. Page 1 follows dev/key-roles.md: RT face = Q E R F, LT face =
  -- T G 3 2, RT D-pad = 1 4 C V, LT D-pad = Shift Q E T F, LT+RT face =
  -- Shift V G, racial, Shift R, LT+RT D-pad = Ctrl Q E R and Holy Light.
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { macro = "HolyStrike", "Holy Strike" },                            -- Q  slot 1
        ["RT X"] = { "Judgement" },                                -- E  slot 2
        ["RT Y"] = { "Seal of Righteousness" },                    -- R  slot 3
        ["RT B"] = { macro = "ExoJudge", "Exorcism" },             -- F  slot 4
        ["LT A"] = { macro = "ShockAny", "Holy Shock", "Seal of Command" },           -- T  slot 5
        ["LT X"] = { macro = "HammerJudge", "Hammer of Wrath" },   -- G  reactive
        ["LT B"] = { macro = "HoJ", "Hammer of Justice" },                      -- 3  stun
        ["LT Y"] = { "Consecration" },                             -- 2  AoE
        ["RT Up"] = { "Seal of the Crusader" },                    -- 1  opener
        ["RT Down"] = { "Holy Wrath" },                            -- 4
        ["RT Left"] = { "Blessing of Freedom" },                   -- C
        ["RT Right"] = { "Seal of Justice" },                      -- V
        ["LT Up"] = { macro = "SmartFlash", "Flash of Light" },    -- Shift+Q
        ["LT Right"] = { "Divine Shield", "Divine Protection", upgrade = true }, -- Shift+E
        ["LT Left"] = { "Cleanse", "Purify", upgrade = true },     -- Shift+T
        ["LT Down"] = { macro = "Repent", "Repentance" },          -- Shift+F
        ["LT+RT A"] = { macro = "LayOnHands", "Lay on Hands" },                        -- Shift+V
        ["LT+RT X"] = { "Blessing of Protection" },                -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Divine Favor" },                          -- Shift+R
        ["LT+RT Up"] = { "Turn Undead" },                          -- Ctrl+Q
        ["LT+RT Down"] = { "Blessing of Sacrifice" },              -- Ctrl+E
        ["LT+RT Left"] = { "Divine Intervention" },                -- Ctrl+R
        ["LT+RT Right"] = { macro = "SmartLight", "Holy Light" },  -- Shift+4  (Ctrl+T is empty)
        -- No trigger: the auras and the group seal (Judgement of Wisdom),
        -- set out of combat.
        ["none Up"] = { "Devotion Aura" },
        ["none Left"] = { "Concentration Aura" },
        ["none Right"] = { "Retribution Aura" },
        ["none Down"] = { "Seal of Wisdom" },
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
        ["RT Left"] = { overflow = true },
        ["RT Right"] = { overflow = true },
      },
      -- Page 3: Steam Deck helpers and the catch-all (other seals, auras,
      -- mounts, talents with no key).
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
        ["LT+RT Up"] = { overflow = true },
        ["LT+RT Down"] = { overflow = true }, ["LT+RT Left"] = { overflow = true },
        ["LT+RT Right"] = { overflow = true },
      },
    },
    paddles = {},
  },
})
