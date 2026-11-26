-- Shaman layouts (WoW Forever). Data contract: dev/layout-format.md; key
-- roles (rotation slots, controller table): dev/key-roles.md. Keep every value
-- a literal (no variables, no function calls): dev.ps1 rules reads this file
-- without running Lua.
--
-- Forever shaman: no stance paging (Ghost Wolf is a plain spell), no
-- Bloodlust (Rage of the Farseer), no Wind Shear, Hex, Lava Burst or Elemental
-- Mastery (Wowhead's Forever guides name none of them): Earth Shock (3) is the
-- interrupt ("can be used to interrupt"; keep a low rank for a cheap kick),
-- and all shocks share a cooldown.
-- A totem bar: Call of the Elements / Ancestors / Spirits (20/30/40) drop a
-- preset of up to four totems (3 s cast), Totemic Recall (20) picks them up,
-- Totemic Call (22) moves them to you. Trainer levels (Wowhead's ability
-- tables; warcraft.wiki.gg where Wowhead is silent): Lightning Bolt 1, Earth
-- Shock 4, Strength of Earth 4, Earthbind 6, Lightning Shield 8, Flame Shock
-- 10, Searing 10, Fire Nova 12, Purge 12, Cure Poison 16, Tremor 18, Frost
-- Shock 20, Ghost Wolf 20, Lesser Healing Wave 20, Healing Stream 20, Cure
-- Disease 22, Magma 26, Windfury Weapon 30, Astral Recall 30, Chain Lightning
-- 32, Windfury Totem 32, Chain Heal 40, Grace of Air 42. Talent rows
-- (dev/forever-talents.md; row r = level 10 + 5r, earlier with the Talented
-- perk): Stormstrike (Enh row 3 = 25; Improved Stormstrike returns mana),
-- Maelstrom Weapon (Enh, passive: at 5 stacks Lightning Bolt is the dump),
-- Rage of the Farseer (Enh row 6 = 40, the only Enh cooldown), Lightning
-- Mastery (Ele row 6 = 40: 15 s burst of faster casts), Water Shield (Resto
-- row 2 = 20; everyone else keeps Lightning Shield), Mana Tide Totem (Resto
-- row 3 = 25), Nature's Swiftness (Resto row 4 = 30), Riptide (Resto row 6 =
-- 40: the next Chain Heal on the target is 25% stronger).
--
-- Rotations (Wowhead WoW Forever guides, which win any disagreement:
--   https://www.wowhead.com/forever/guide/classes/shaman/elemental/rotation-cooldowns-pve-dps
--   https://www.wowhead.com/forever/guide/classes/shaman/elemental/dps-leveling-tips
--   https://www.wowhead.com/forever/guide/classes/shaman/enhancement/rotation-cooldowns-pve-dps
--   https://www.wowhead.com/forever/guide/classes/shaman/enhancement/dps-leveling-tips
--   https://www.wowhead.com/forever/guide/classes/shaman/restoration/rotation-cooldowns-pve-healer
--   https://www.wowhead.com/forever/guide/classes/shaman/restoration/healer-leveling-tips
-- warcraft.wiki.gg Shaman abilities (Forever) only for spells Wowhead skips):
-- Enhancement (leveling spec). Single target: maintain Magma Totem, maintain
--   Flame Shock, Stormstrike, Lightning Bolt at 5 Maelstrom Weapon, Earth
--   Shock, Fire Nova filler. AoE: Magma Totem, Fire Nova, Flame Shock on
--   every target, then the single-target list. Cooldown: Rage of the Farseer.
--   Leveling: pull with Lightning Bolt or Flame Shock, Stormstrike, Earth
--   Shock, keep Lightning Shield up; AoE: any fire totem, Fire Nova, Flame
--   Shock; Earthbind to kite or when Fire Nova pulls threat.
-- Elemental. Single target: Searing Totem, Flame Shock kept up, Lightning
--   Mastery, Chain Lightning only on a Clearcasting proc outside Lightning
--   Mastery (too costly otherwise), Lightning Bolt. AoE: Magma Totem,
--   Lightning Mastery, Chain Lightning and Fire Nova on cooldown, Flame Shock
--   on up to 3, Lightning Bolt; low-rank Earth Shock fishes for Clearcasting.
--   Leveling adds a shield, Stormstrike (Spellhance) and Earth/Frost Shock;
--   Stoneclaw Totem and Earthbind for packs.
-- Restoration (healer). Single target: Searing Totem, Riptide on the most
--   damaged ally, Healing Wave (downranked). AoE: Riptide, Chain Heal on
--   Riptide targets, Magma Totem and Fire Nova if mana allows. Cooldowns:
--   Mana Tide Totem (~80% mana), Nature's Swiftness + Healing Wave on a dying
--   tank. Lesser Healing Wave: the emergency fast heal. Cures and Earth Shock
--   interrupt from warcraft.wiki.gg (Wowhead is silent).
--
-- Elemental and Enhancement share Shift, Ctrl and the rest of the controller
-- (chains: R = Stormstrike / Chain Lightning, Shift+R = Rage of the Farseer /
-- Lightning Mastery). Enhancement overrides Plain and controller page 1 only
-- for Magma Totem on F / RT B (Wowhead's first Enhancement priority; Searing
-- holds it until 26). Restoration overrides Plain, Shift, Ctrl and controller
-- page 1. Earth Shock sits on 3 (interrupt) for every spec, so the interrupt
-- key never moves; it is also the damage specs' filler (3 is reachable from
-- WASD). Shaman has no hard CC: Shift+F and LT Down stay empty. Unkeyed
-- spells (Tremor and the resistance totems, Far Sight...) go to the side
-- bars and the catch-all.
-- Recommended macros (Macros/Data/Shaman.lua) take their spell's keys once
-- installed: StormAttack on Enhancement's Stormstrike, ShamanBurst on the
-- Shift+R burst, and Restoration's RiptideHeal, ChainHeal and LesserWave
-- (friendly target, else you).
local _, ns = ...

ns.Layout.Register("SHAMAN", {
  specs = {
    { key = "elemental", name = "Elemental", tab = 1 },
    { key = "enhancement", name = "Enhancement", tab = 2, default = true,
      -- Wowhead: Enhancement maintains Magma Totem even on one target (and
      -- never names Searing), so the fire totem on F / RT B is Magma from 26;
      -- Searing holds the key before that ("put down any fire totem") and
      -- then goes to the side bars. Everything else matches the shared bars.
      keyboard = {
        [1] = {
          { "Lightning Bolt" },                                 -- Q  slot 1: pull + 5-Maelstrom dump (1)
          { "Flame Shock" },                                    -- E  slot 2: DoT kept up, pull (10)
          { macro = "StormAttack", "Stormstrike", "Chain Lightning" }, -- R  slot 3: on cooldown (talent, row 3 = 25)
          { "Water Shield", "Lightning Shield" },               -- T  slot 5: shield kept up (Lightning Shield 8; Water Shield is Resto's)
          { macro = "MagmaNova", "Magma Totem", "Searing Totem" }, -- F  slot 4: Magma kept up (26; Searing before)
          { "Purge" },                                          -- G  reactive: enemy buffs (12)
          { "Ghost Wolf" },                                     -- C  mobility (20)
          { "Frost Shock" },                                    -- V  snare (20)
          { "Call of the Elements" },                           -- 1  opener: buff totems before the pull (20)
          { "Fire Nova" },                                      -- 2  main AoE, detonates your fire totem (12)
          { macro = "ShockKick", "Earth Shock" },               -- 3  interrupt + filler shock (4)
          { "Stoneclaw Totem" },                                -- 4  packs: draws the adds off you
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { "Lightning Bolt" },                              -- slot 1 (Q)
        ["RT X"] = { "Flame Shock" },                                 -- slot 2 (E)
        ["RT Y"] = { macro = "StormAttack", "Stormstrike", "Chain Lightning" }, -- slot 3 (R)
        ["RT B"] = { macro = "MagmaNova", "Magma Totem", "Searing Totem" }, -- slot 4 (F)
        ["LT A"] = { "Water Shield", "Lightning Shield" },            -- slot 5 (T)
        ["LT X"] = { "Purge" },                                       -- reactive (G)
        ["LT B"] = { macro = "ShockKick", "Earth Shock" },            -- interrupt + filler (3)
        ["LT Y"] = { "Fire Nova" },                                   -- main AoE (2)
        ["RT Up"] = { "Call of the Elements" },                       -- opener, standing (1)
        ["RT Down"] = { "Stoneclaw Totem" },                          -- packs (4)
        ["RT Left"] = { "Ghost Wolf" },                               -- mobility (C)
        ["RT Right"] = { "Frost Shock" },                             -- snare (V)
        ["LT Up"] = { macro = "WaveHeal", "Healing Wave" },           -- self-heal (Shift+Q)
        ["LT Right"] = { "Stoneskin Totem" },                         -- defensive (Shift+E)
        ["LT Left"] = { "Grounding Totem" },                          -- control (Shift+T)
        ["LT+RT A"] = { macro = "NSWave", "Nature's Swiftness", "Lesser Healing Wave" }, -- emergency (Shift+V)
        ["LT+RT X"] = { "Earthbind Totem" },                          -- AoE control (Shift+G)
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { macro = "ShamanBurst", "Rage of the Farseer", "Lightning Mastery" }, -- burst (Shift+R)
        ["LT+RT Up"] = { "Chain Heal" },                              -- rare (Ctrl+Q)
        ["LT+RT Down"] = { "Cure Poison" },                           -- rare (Ctrl+E)
        ["LT+RT Left"] = { "Cure Disease" },                          -- rare (Ctrl+R)
        ["LT+RT Right"] = { "Totemic Call" },                         -- rare (Ctrl+T)
        ["none Up"] = { "Windfury Weapon" },                          -- Enhancement from 30
        ["none Left"] = { "Rockbiter Weapon" },                       -- Enhancement until 30
        ["none Right"] = { "Totemic Recall" },
        ["none Down"] = { "Flametongue Weapon" },
      } } } },
    { key = "restoration", name = "Restoration", tab = 3,
      keyboard = {
        [1] = {
          { macro = "WaveHeal", "Healing Wave" },     -- Q  slot 1: main heal (friendly target, else you)
          { macro = "RiptideHeal", "Riptide" },                              -- E  slot 2: HoT kept on the most damaged ally, before Chain Heal (talent, row 6 = 40)
          { macro = "ChainHeal", "Chain Heal" },     -- R  slot 3: group heal, best on Riptide targets (40)
          { "Cure Poison" },                          -- T  slot 5: healer dispel (16)
          { macro = "LesserWave", "Lesser Healing Wave" },                  -- F  slot 4: fast emergency heal (20)
          { "Cure Disease" },                         -- G  reactive: second dispel (22)
          { "Ghost Wolf" },                           -- C  mobility (20)
          { "Frost Shock" },                          -- V  snare (20)
          { "Call of the Elements" },                 -- 1  opener: totem preset before the pull (20)
          { "Healing Stream Totem" },                 -- 2  group heal totem (20)
          { macro = "ShockKick", "Earth Shock" },     -- 3  interrupt (4)
          { "Purge" },                                -- 4  enemy buffs (12)
        },
        -- Healer rule: solo damage one tier down on Shift Q E T.
        [2] = {
          { "Lightning Bolt" },                       -- Shift+Q  damage: main nuke
          { "Flame Shock" },                          -- Shift+E  damage: DoT
          { "Mana Tide Totem" },                      -- Shift+R  healer cooldown (talent, row 3 = 25)
          { "Searing Totem" },                        -- Shift+T  damage: fire totem
          false,                                      -- Shift+F  hard CC: none (no Hex)
          { "Earthbind Totem" },                      -- Shift+G  AoE control
          { racial = true },                          -- Shift+C  racial
          { macro = "NSWave", "Nature's Swiftness" }, -- Shift+V  emergency instant Healing Wave (talent, row 4 = 30)
          { "Water Shield", "Lightning Shield" },     -- Shift+1  shield (Water Shield: talent, row 2 = 20; Lightning Shield before)
          { "Rockbiter Weapon" },                     -- Shift+2  imbue
          { "Flametongue Weapon" },                   -- Shift+3  imbue
          { "Windfury Weapon" },                      -- Shift+4  imbue
        },
        [4] = {
          { "Grounding Totem" },                      -- Ctrl+Q  eats a spell
          { macro = "MagmaNova", "Magma Totem" },     -- Ctrl+E  damage: AoE if mana allows (26)
          { "Fire Nova" },                            -- Ctrl+R  damage: AoE if mana allows (12)
          { "Totemic Call" },                         -- Ctrl+T  moves your totems to you
          { "Strength of Earth Totem" },              -- Ctrl+F  utility totem
          { "Mana Spring Totem" },                    -- Ctrl+G  utility totem
          { "Stoneskin Totem" },                      -- Ctrl+C  utility totem
          { "Windfury Totem" },                       -- Ctrl+V  utility totem
          { "Call of the Ancestors" },                -- Ctrl+1  totem preset (30)
          { "Call of the Spirits" },                  -- Ctrl+2  totem preset (40)
          { "Totemic Recall" },                       -- Ctrl+3  totem pickup
          { "Tremor Totem" },                         -- Ctrl+4  anti-fear totem
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { macro = "WaveHeal", "Healing Wave" },   -- slot 1 main heal (Q)
        ["RT X"] = { macro = "RiptideHeal", "Riptide" },                            -- slot 2 HoT (E)
        ["RT Y"] = { macro = "ChainHeal", "Chain Heal" }, -- slot 3 group heal (R)
        ["RT B"] = { macro = "LesserWave", "Lesser Healing Wave" },                -- slot 4 fast heal (F)
        ["LT A"] = { "Cure Poison" },                        -- slot 5 dispel (T)
        ["LT X"] = { "Cure Disease" },                       -- reactive dispel (G)
        ["LT B"] = { macro = "ShockKick", "Earth Shock" },   -- interrupt (3)
        ["LT Y"] = { "Healing Stream Totem" },               -- group heal totem (2)
        ["RT Up"] = { "Call of the Elements" },              -- opener: preset, standing (1)
        ["RT Down"] = { "Purge" },                           -- (4)
        ["RT Left"] = { "Ghost Wolf" },                      -- mobility (C)
        ["RT Right"] = { "Frost Shock" },                    -- snare (V)
        ["LT Up"] = { "Lightning Bolt" },                    -- solo damage (Shift+Q)
        ["LT Right"] = { "Flame Shock" },                    -- solo damage (Shift+E)
        ["LT Left"] = { "Searing Totem" },                   -- solo damage (Shift+T)
        ["LT Down"] = { "Grounding Totem" },                 -- no hard CC: closest standing cast
        ["LT+RT A"] = { macro = "NSWave", "Nature's Swiftness" }, -- emergency (Shift+V)
        ["LT+RT X"] = { "Earthbind Totem" },                 -- AoE control (Shift+G)
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Mana Tide Totem" },                 -- cooldown (Shift+R)
        ["LT+RT Up"] = { macro = "MagmaNova", "Magma Totem" }, -- rare AoE damage (Ctrl+E)
        ["LT+RT Down"] = { "Fire Nova" },                    -- rare
        ["LT+RT Left"] = { "Mana Spring Totem" },            -- rare
        ["LT+RT Right"] = { "Totemic Call" },                -- rare
        ["none Up"] = { "Water Shield", "Lightning Shield" }, -- out of combat: shield
        ["none Left"] = { "Rockbiter Weapon" },
        ["none Right"] = { "Totemic Recall" },
        ["none Down"] = { "Flametongue Weapon" },
      } } } },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  -- Elemental (and Enhancement's Shift and Ctrl; fallback chains pick the
  -- build's spell). Plain bar in Wowhead's Elemental order.
  keyboard = {
    [1] = {
      { "Lightning Bolt" },                                 -- Q  slot 1: the filler you cast most (1)
      { "Flame Shock" },                                    -- E  slot 2: DoT kept up, refreshed as it drops (10)
      { "Stormstrike", "Chain Lightning" },                 -- R  slot 3: Chain Lightning on Clearcasting (32) / Spellhance Stormstrike
      { "Water Shield", "Lightning Shield" },               -- T  slot 5: shield kept up (Lightning Shield 8; Water Shield is Resto's)
      { "Searing Totem" },                                  -- F  slot 4: Searing kept up on one target (10)
      { "Purge" },                                          -- G  reactive: enemy buffs (12)
      { "Ghost Wolf" },                                     -- C  mobility (20)
      { "Frost Shock" },                                    -- V  snare (20)
      { "Call of the Elements" },                           -- 1  opener: totem preset in groups (20)
      { "Fire Nova" },                                      -- 2  main AoE, detonates your fire totem (12)
      { macro = "ShockKick", "Earth Shock" },               -- 3  interrupt + filler shock (4)
      { macro = "MagmaNova", "Magma Totem" },               -- 4  ground AoE: Magma kept up on packs (26)
    },
    [2] = {
      { macro = "WaveHeal", "Healing Wave" },               -- Shift+Q  self-heal (friendly target, else you)
      { "Stoneskin Totem" },                                -- Shift+E  defensive totem (4)
      { macro = "ShamanBurst", "Rage of the Farseer", "Lightning Mastery" },       -- Shift+R  burst (Enh / Ele capstone, row 6 = 40)
      { "Grounding Totem" },                                -- Shift+T  control: eats a spell (30)
      false,                                                -- Shift+F  hard CC: none (no Hex)
      { "Earthbind Totem" },                                -- Shift+G  AoE control (6)
      { racial = true },                                    -- Shift+C  racial
      { macro = "NSWave", "Nature's Swiftness", "Lesser Healing Wave" }, -- Shift+V  emergency heal (LHW 20 until Nature's Swiftness, Resto row 4 = 30)
      { "Rockbiter Weapon" },                               -- Shift+1  imbue: solo until 30 (1)
      { "Flametongue Weapon" },                             -- Shift+2  imbue: Elemental (10)
      { "Frostbrand Weapon" },                              -- Shift+3  imbue (20)
      { "Windfury Weapon" },                                -- Shift+4  imbue: Enhancement from 30
    },
    -- [3] is the Alt bar (ActionBars.utility), not set here.
    [4] = {
      { "Chain Heal" },                                     -- Ctrl+Q  off-heal (40)
      { "Cure Poison" },                                    -- Ctrl+E  cure
      { "Cure Disease" },                                   -- Ctrl+R  cure
      { "Totemic Call" },                                   -- Ctrl+T  moves your totems to you
      { "Strength of Earth Totem" },                        -- Ctrl+F  utility totem
      { "Healing Stream Totem" },                           -- Ctrl+G  utility totem
      { "Mana Spring Totem" },                              -- Ctrl+C  utility totem
      { "Windfury Totem" },                                 -- Ctrl+V  utility totem
      { "Grace of Air Totem" },                             -- Ctrl+1  utility totem
      { "Call of the Ancestors" },                          -- Ctrl+2  totem preset (30)
      { "Call of the Spirits" },                            -- Ctrl+3  totem preset (40)
      { "Totemic Recall" },                                 -- Ctrl+4  totem pickup
    },
  },

  -- Controller: page 1 follows the key-roles table: the rotation on RT face,
  -- slot 5 / reactive / interrupt / AoE on LT face, stand-still casts on the
  -- RT D-pad. Earth Shock (filler + interrupt) on LT B: pressed while moving.
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { "Lightning Bolt" },                              -- slot 1 (Q)
        ["RT X"] = { "Flame Shock" },                                 -- slot 2 (E)
        ["RT Y"] = { "Stormstrike", "Chain Lightning" },              -- slot 3 (R)
        ["RT B"] = { "Searing Totem" },                               -- slot 4 (F)
        ["LT A"] = { "Water Shield", "Lightning Shield" },            -- slot 5 (T)
        ["LT X"] = { "Purge" },                                       -- reactive (G)
        ["LT B"] = { macro = "ShockKick", "Earth Shock" },            -- interrupt + filler (3)
        ["LT Y"] = { "Fire Nova" },                                   -- main AoE (2)
        ["RT Up"] = { "Call of the Elements" },                       -- opener, standing (1)
        ["RT Down"] = { macro = "MagmaNova", "Magma Totem" },         -- ground AoE (4)
        ["RT Left"] = { "Ghost Wolf" },                               -- mobility (C)
        ["RT Right"] = { "Frost Shock" },                             -- snare (V)
        ["LT Up"] = { macro = "WaveHeal", "Healing Wave" },           -- self-heal (Shift+Q)
        ["LT Right"] = { "Stoneskin Totem" },                         -- defensive (Shift+E)
        ["LT Left"] = { "Grounding Totem" },                          -- control (Shift+T)
        -- LT Down (Shift+F, hard CC) stays free: no Hex on Forever.
        ["LT+RT A"] = { macro = "NSWave", "Nature's Swiftness", "Lesser Healing Wave" }, -- emergency (Shift+V)
        ["LT+RT X"] = { "Earthbind Totem" },                          -- AoE control (Shift+G)
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { macro = "ShamanBurst", "Rage of the Farseer", "Lightning Mastery" }, -- burst (Shift+R)
        ["LT+RT Up"] = { "Chain Heal" },                              -- rare (Ctrl+Q)
        ["LT+RT Down"] = { "Cure Poison" },                           -- rare (Ctrl+E)
        ["LT+RT Left"] = { "Cure Disease" },                          -- rare (Ctrl+R)
        ["LT+RT Right"] = { "Totemic Call" },                         -- rare (Ctrl+T)
        -- No trigger: imbues and Totemic Recall, out of combat.
        ["none Up"] = { "Windfury Weapon" },                          -- Enhancement from 30
        ["none Left"] = { "Rockbiter Weapon" },                       -- Enhancement until 30
        ["none Right"] = { "Totemic Recall" },
        ["none Down"] = { "Flametongue Weapon" },                     -- Elemental
      },
      -- Page 2: resurrection and travel; the shared Utility buttons
      -- (Layouts/Shared.lua) add Hearthstone, trinkets, fishing, camp, Mount
      -- and professions.
      {
        title = "Utility",
        ["RT A"] = { "Ancestral Spirit" },
        ["RT X"] = { "Astral Recall" },
        ["RT B"] = { "Far Sight" },
        ["RT Y"] = { "Water Walking" },
        ["RT Down"] = { "Water Breathing" },
        ["RT Left"] = { "Frostbrand Weapon" },
      },
      -- Page 3: totems no page 1 holds (same for every spec), the other two
      -- presets, Steam Deck helpers and the catch-all (it also takes the
      -- totems each spec's page 1 leaves out).
      {
        title = "Totems & Extras",
        ["RT A"] = { "Strength of Earth Totem" },
        ["RT X"] = { "Windfury Totem" },
        ["RT B"] = { "Grace of Air Totem" },
        ["RT Y"] = { "Tremor Totem" },
        ["RT Up"] = { "Call of the Ancestors" },
        ["RT Down"] = { "Call of the Spirits" },
        ["RT Left"] = { overflow = true },
        ["RT Right"] = { overflow = true },
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
