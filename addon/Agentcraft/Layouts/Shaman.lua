-- Shaman layouts (WoW Forever). Data contract: dev/layout-format.md; key
-- roles shared by every class: dev/key-roles.md. Keep every value a literal
-- (no variables, no function calls): dev.ps1 rules reads this file without
-- running Lua.
--
-- Enhancement is the leveling spec; Elemental is weak; Restoration is a
-- group healer (research 2026-11: Icy Veins, Warcraft Tavern, Method).
-- Forever shaman: no stance paging (Ghost Wolf is a plain spell here), no
-- Bloodlust (Rage of the Farseer, a 40 talent), no Wind Shear or Hex (Earth
-- Shock interrupts), no Lava Burst. Totems need their totem item in your bags
-- (a spell button is fine), one totem per element; Call of the Elements,
-- Ancestors and Spirits (20/30/40) drop a preset from the totem bar (3 s
-- cast); Totemic Recall (20) picks them up, Totemic Call (22) moves them.
--
-- Enhancement and Elemental share every bar through fallback chains (T =
-- Stormstrike / Lightning Mastery / Riptide). Restoration follows the healer
-- rule of key-roles.md: heals on plain Q E R T and 1, its damage on Shift
-- Q E R T. Shaman has no hard CC (Shift+F stays empty) and few secondary
-- attacks, so Ctrl Q E R T hold the closest fits: a second heal, the cures
-- and Totemic Call. Everything not keyed (Frostbrand, resistance and
-- cleansing totems, Far Sight, Water Walking...) goes to the side bars.
local _, ns = ...

ns.Layout.Register("SHAMAN", {
  specs = {
    { key = "elemental", name = "Elemental", tab = 1 },
    { key = "enhancement", name = "Enhancement", tab = 2, default = true },
    { key = "restoration", name = "Restoration", tab = 3,
      keyboard = {
        -- Healer rule: Q main heal, E HoT, R second heal, T spec heal, 1
        -- group heal; F G C V and 2 3 4 keep their roles.
        [1] = {
          { macro = "WaveHeal", "Healing Wave" },     -- Q  main heal (friendly target, else you)
          { "Riptide" },                              -- E  HoT (40 talent)
          { "Lesser Healing Wave" },                  -- R  fast heal
          { "Mana Tide Totem" },                      -- T  spec heal / signature
          { macro = "ShockCycle" },                   -- F  melee starter (macro only)
          { "Purge" },                                -- G  reactive
          { "Ghost Wolf" },                           -- C  mobility
          { "Frost Shock" },                          -- V  snare
          { "Chain Heal" },                           -- 1  group heal
          { "Fire Nova" },                            -- 2  main AoE
          { macro = "ShockKick", "Earth Shock" },     -- 3  interrupt
          { macro = "MagmaNova", "Magma Totem" },     -- 4  ground AoE
        },
        -- Damage moves to Shift Q E R T; the rest of Shift stays shared.
        [2] = {
          { "Lightning Bolt" },                       -- Shift+Q  damage: main attack
          { "Flame Shock" },                          -- Shift+E  damage: DoT
          { "Chain Lightning" },                      -- Shift+R  damage: big hitter
          { "Searing Totem" },                        -- Shift+T  damage: fire totem
          false,                                      -- Shift+F  hard CC: none (no Hex)
          { "Earthbind Totem" },                      -- Shift+G  AoE control
          { racial = true },                          -- Shift+C  racial
          { macro = "NSWave", "Nature's Swiftness" }, -- Shift+V  emergency
          { "Water Shield", "Lightning Shield" },     -- Shift+1  shield (Water Shield: Resto talent)
          { "Rockbiter Weapon" },                     -- Shift+2  imbue
          { "Flametongue Weapon" },                   -- Shift+3  imbue
          { "Windfury Weapon" },                      -- Shift+4  imbue
        },
        -- As shared, but Lesser Healing Wave is on plain R: Grounding on Ctrl+Q.
        [4] = {
          { "Grounding Totem" },                      -- Ctrl+Q  control (eats a spell)
          { "Cure Poison" },                          -- Ctrl+E  cure
          { "Cure Disease" },                         -- Ctrl+R  cure
          { "Totemic Call" },                         -- Ctrl+T  moves your totems to you
          { "Strength of Earth Totem" },              -- Ctrl+F  utility totem
          { "Healing Stream Totem" },                 -- Ctrl+G  utility totem
          { "Mana Spring Totem" },                    -- Ctrl+C  utility totem
          { "Windfury Totem" },                       -- Ctrl+V  utility totem
          { "Call of the Elements" },                 -- Ctrl+1  totem preset
          { "Call of the Ancestors" },                -- Ctrl+2  totem preset
          { "Call of the Spirits" },                  -- Ctrl+3  totem preset
          { "Totemic Recall" },                       -- Ctrl+4  totem pickup
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { macro = "WaveHeal", "Healing Wave" },
        ["RT X"] = { "Riptide" },
        ["RT B"] = { macro = "ShockKick", "Earth Shock" },
        ["RT Y"] = { "Fire Nova" },
        ["RT Up"] = { "Chain Heal" },
        ["RT Right"] = { "Lesser Healing Wave" },
        ["RT Left"] = { "Mana Tide Totem" },
        ["RT Down"] = { macro = "MagmaNova", "Magma Totem" },
        ["LT A"] = { macro = "ShockCycle" },
        ["LT X"] = { "Purge" },
        ["LT B"] = { "Frost Shock" },
        ["LT Y"] = { "Ghost Wolf" },
        ["LT Up"] = { "Lightning Bolt" },
        ["LT Left"] = { "Searing Totem" },
        ["LT Right"] = { "Flame Shock" },
        ["none Up"] = { "Water Shield", "Lightning Shield" },
        ["none Left"] = { "Call of the Elements" },
        ["none Right"] = { "Totemic Recall" },
        ["none Down"] = { "Windfury Weapon", "Rockbiter Weapon" },
        ["LT+RT A"] = { macro = "NSWave", "Nature's Swiftness" },
        ["LT+RT X"] = { "Earthbind Totem" },
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Chain Lightning" },
        ["LT+RT Up"] = { "Grounding Totem" },
        ["LT+RT Down"] = { "Cure Poison" },
        ["LT+RT Left"] = { "Cure Disease" },
        ["LT+RT Right"] = { "Totemic Call" },
      } } } },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  -- Roles (dev/key-roles.md): Q main attack, E DoT, R big hitter, T spec
  -- signature, F melee, G proc, C mobility, V snare, 1 opener, 2 main AoE,
  -- 3 interrupt, 4 ground AoE.
  keyboard = {
    [1] = {
      { "Lightning Bolt" },                                 -- Q  main attack (Enh: at 5 Maelstrom)
      { "Flame Shock" },                                    -- E  DoT (10)
      { "Chain Lightning" },                                -- R  big hitter (32)
      { "Stormstrike", "Lightning Mastery", "Riptide" },    -- T  spec signature
      { macro = "ShockCycle" },                             -- F  melee: starts melee + shock cycle (macro only)
      { "Purge" },                                          -- G  reactive (enemy buffs)
      { "Ghost Wolf" },                                     -- C  mobility (20)
      { "Frost Shock" },                                    -- V  snare (20)
      { "Searing Totem" },                                  -- 1  opener: drop it, then pull (10)
      { "Fire Nova" },                                      -- 2  main AoE, detonates your fire totem (12)
      { macro = "ShockKick", "Earth Shock" },               -- 3  interrupt (4)
      { macro = "MagmaNova", "Magma Totem" },               -- 4  ground AoE (26)
    },
    -- Bar 2 (Shift): Q self-heal, E spec defensive, R burst, T spec control,
    -- F hard CC, G AoE control, C racial, V emergency, 1-4 buffs.
    [2] = {
      { macro = "WaveHeal", "Healing Wave" },               -- Shift+Q  self-heal (friendly target, else you)
      { "Stoneskin Totem" },                                -- Shift+E  defensive totem (4)
      { "Rage of the Farseer" },                            -- Shift+R  burst (40 talent)
      { "Grounding Totem" },                                -- Shift+T  control (eats a spell)
      false,                                                -- Shift+F  hard CC: none (no Hex)
      { "Earthbind Totem" },                                -- Shift+G  AoE control (6)
      { racial = true },                                    -- Shift+C  racial
      { macro = "NSWave", "Nature's Swiftness" },           -- Shift+V  emergency heal
      { "Water Shield", "Lightning Shield" },               -- Shift+1  shield (Water Shield: Resto talent)
      { "Rockbiter Weapon" },                               -- Shift+2  imbue: solo until 30
      { "Flametongue Weapon" },                             -- Shift+3  imbue: groups until 30, Elemental
      { "Windfury Weapon" },                                -- Shift+4  imbue: Enhancement from 30
    },
    -- [3] is the Alt bar (ActionBars.utility), not set here.
    -- Bar 4 (Ctrl): Q E R T secondary (closest fits), F G C V utility
    -- totems, 1 2 3 4 the totem presets and Totemic Recall.
    [4] = {
      { "Lesser Healing Wave" },                            -- Ctrl+Q  second heal (closest fit)
      { "Cure Poison" },                                    -- Ctrl+E  cure
      { "Cure Disease" },                                   -- Ctrl+R  cure
      { "Totemic Call" },                                   -- Ctrl+T  moves your totems to you
      { "Strength of Earth Totem" },                        -- Ctrl+F  utility totem
      { "Healing Stream Totem" },                           -- Ctrl+G  utility totem
      { "Mana Spring Totem" },                              -- Ctrl+C  utility totem
      { "Windfury Totem" },                                 -- Ctrl+V  utility totem
      { "Call of the Elements" },                           -- Ctrl+1  drops your preset (3 s cast)
      { "Call of the Ancestors" },                          -- Ctrl+2  totem preset
      { "Call of the Spirits" },                            -- Ctrl+3  totem preset
      { "Totemic Recall" },                                 -- Ctrl+4  off the global cooldown
    },
  },

  -- Controller: keys "<layer> <button>", layer none / LT / RT / LT+RT,
  -- button A X B Y or Up Down Left Right (D-pad). The Top bar's face buttons
  -- are fixed. Page 1 mirrors the keyboard roles (dev/key-roles.md).
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { "Lightning Bolt" },                              -- Q
        ["RT X"] = { "Flame Shock" },                                 -- E
        ["RT B"] = { macro = "ShockKick", "Earth Shock" },            -- 3
        ["RT Y"] = { "Fire Nova" },                                   -- 2
        ["RT Up"] = { "Searing Totem" },                              -- 1
        ["RT Right"] = { "Chain Lightning" },                         -- R
        ["RT Left"] = { "Stormstrike", "Lightning Mastery", "Riptide" }, -- T
        ["RT Down"] = { macro = "MagmaNova", "Magma Totem" },         -- 4
        ["LT A"] = { macro = "ShockCycle" },                          -- F
        ["LT X"] = { "Purge" },                                       -- G
        ["LT B"] = { "Frost Shock" },                                 -- V
        ["LT Y"] = { "Ghost Wolf" },                                  -- C
        ["LT Up"] = { macro = "WaveHeal", "Healing Wave" },           -- Shift+Q
        -- LT Down (Shift+F, hard CC) stays free: no Hex on Forever.
        ["LT Left"] = { "Grounding Totem" },                          -- Shift+T
        ["LT Right"] = { "Stoneskin Totem" },                         -- Shift+E
        -- No trigger: shield (buff row), preset, recall and main imbue.
        ["none Up"] = { "Water Shield", "Lightning Shield" },
        ["none Left"] = { "Call of the Elements" },
        ["none Right"] = { "Totemic Recall" },
        ["none Down"] = { "Windfury Weapon", "Rockbiter Weapon" },    -- Enh: Rockbiter until 30
        ["LT+RT A"] = { macro = "NSWave", "Nature's Swiftness" },     -- Shift+V
        ["LT+RT X"] = { "Earthbind Totem" },                          -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Rage of the Farseer" },                      -- Shift+R
        ["LT+RT Up"] = { "Lesser Healing Wave" },                     -- Ctrl+Q
        ["LT+RT Down"] = { "Cure Poison" },                           -- Ctrl+E
        ["LT+RT Left"] = { "Cure Disease" },                          -- Ctrl+R
        ["LT+RT Right"] = { "Totemic Call" },                         -- Ctrl+T
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
      -- Page 3: totems and imbues page 1 has no room for, the other two
      -- presets, Steam Deck helpers and the catch-all.
      {
        title = "Totems & Extras",
        ["RT A"] = { "Strength of Earth Totem" },
        ["RT X"] = { "Healing Stream Totem" },
        ["RT B"] = { "Windfury Totem" },
        ["RT Y"] = { "Mana Spring Totem" },
        ["RT Up"] = { "Call of the Ancestors" },
        ["RT Down"] = { "Call of the Spirits" },
        ["RT Left"] = { "Flametongue Weapon" },
        ["RT Right"] = { "Tremor Totem" },
        ["none Up"] = { macro = "Reload" },
        ["none Down"] = { macro = "Follow" },
        ["none Left"] = { macro = "Focus" },
        ["none Right"] = { macro = "Assist" },
        ["LT+RT A"] = { macro = "Skull" },
        -- Everything else you know, alphabetically: resistance and cleansing totems...
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
