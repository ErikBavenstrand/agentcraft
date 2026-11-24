-- Druid layouts. Data contract: dev/layout-format.md; key roles (binding,
-- the same kind of ability on the same key for every class):
-- dev/key-roles.md. Keep every value a literal (no variables, no function
-- calls): dev.ps1 rules reads this file without running Lua.
--
-- Feral is the leveling spec (research 2026-11: Icy Veins, Method,
-- Mobalytics): Bear for packs (from 10), Cat for single targets (from 20).
-- Balance levels faster than Restoration; Restoration is the group healer
-- and follows the healer rule (heals on the plain keys, damage on Shift).
--
-- Bar 1 pages by form: the base page is caster form, cat is bonus bar
-- offset 1 (Prowl is handled by the game), bear 3, moonkin 4. Every page
-- keeps the key roles; the form only changes which spell fills a role:
--
--   key  role            caster/moonkin   cat              bear
--   Q    main attack     Wrath            Claw             Maul
--   E    DoT             Moonfire         Rake             Lacerate
--   R    big hitter      Starfire         Ferocious Bite   Primal Bite
--   T    signature       Insect Swarm     Rip              Growl
--   F    melee builder   -                Shred            -
--   G    proc/reactive   Nature's Grasp   Cower            Frenzied Regeneration
--   C    escape          -                Dash             Feral Charge
--   V    snare           Entangling Roots -                -
--   1    opener          -                CatOpener/Prowl  Enrage
--   2    main AoE        -                -                Swipe
--   3    control         -                Pounce           Bash
--   4    ground AoE      Hurricane        -                Demoralizing Roar
--
-- Shift and Ctrl don't page, so they hold what works from any form: the
-- self-heal macro (it drops your form first), the spec cooldown, Hibernate,
-- Barkskin, the forms (Shift 1-4), Faerie Fire, heals, dispels and buffs.
--
-- WoW Forever changes (Warcraft Tavern, Icy Veins shapeshift page): no
-- powershifting; Shifting Power (Feral 40 talent, 8 s cooldown, Cat only)
-- trades mana for 40 energy and replaces Tiger's Fury; entering Bear wipes
-- your energy, so there are no bear/cat weave keys; Moonkin blocks heals;
-- heals, dispels, Innervate and Rebirth take you out of form; Primal Bite
-- (Bear) replaces Mangle; Lacerate is a Feral talent; Revive (12) is the
-- out-of-combat resurrect.
local _, ns = ...

ns.Layout.Register("DRUID", {
  specs = {
    -- Balance: the shared keyboard; controller page 1 with the caster
    -- spells as plain buttons (no form macros needed).
    { key = "balance", name = "Balance", tab = 1,
      controller = {
        pages = {
          [1] = {
            title = "Combat",
            ["RT A"] = { "Wrath" },                       -- Q
            ["RT X"] = { "Moonfire" },                    -- E
            ["RT Right"] = { "Starfire" },                -- R
            ["RT Left"] = { "Insect Swarm" },             -- T
            ["RT Down"] = { "Hurricane" },                -- 4
            ["LT X"] = { "Nature's Grasp" },              -- G
            ["LT B"] = { "Entangling Roots" },            -- V
            ["LT Up"] = { macro = "Regrow", "Regrowth" }, -- Shift+Q
            ["LT Down"] = { "Hibernate" },                -- Shift+F
            ["LT Right"] = { "Shifting Power", "Nature's Swiftness" }, -- Shift+E
            ["none Up"] = { "Moonkin Form", "Cat Form" },
            ["none Right"] = { "Dire Bear Form", "Bear Form", upgrade = true },
            ["none Left"] = { "Travel Form" },
            ["none Down"] = { macro = "HTouch", "Healing Touch" },
            ["LT+RT A"] = { "Barkskin" },                 -- Shift+V
            ["LT+RT X"] = { "Challenging Roar" },         -- Shift+G
            ["LT+RT B"] = { racial = true },
            ["LT+RT Y"] = { "Innervate" },                -- Shift+R
            ["LT+RT Up"] = { "Faerie Fire" },             -- Ctrl+Q
          },
        },
      },
    },
    { key = "feral", name = "Feral Combat", tab = 2, default = true },
    -- Restoration (healer rule): Q main heal, E HoT, R big heal, T spec
    -- heal, 1 group heal on the plain keys; the damage moves to Shift Q E R T;
    -- F G C V and Shift F G C V keep their roles. No Moonkin page.
    { key = "restoration", name = "Restoration", tab = 3,
      keyboard = {
        [1] = {
          { macro = "Regrow", "Regrowth" },             -- Q  main heal (target if friendly, else you)
          { macro = "Rejuv", "Rejuvenation" },          -- E  HoT
          { macro = "HTouch", "Healing Touch" },        -- R  big heal
          { "Swiftmend" },                              -- T  spec heal
          false,                                        -- F  (no melee in caster form)
          { "Nature's Swiftness" },                     -- G  reactive
          false,                                        -- C  (no caster escape; Travel Form is Shift+3)
          { "Entangling Roots" },                       -- V  snare
          { "Wild Growth" },                            -- 1  group heal
          { "Tranquility" },                            -- 2  AoE heal
          false,                                        -- 3  (no caster interrupt)
          { "Bloom" },                                  -- 4  ground heal (Resto talent)
        },
        [2] = {
          { "Wrath" },                                  -- Shift+Q  damage
          { "Moonfire" },                               -- Shift+E  damage: DoT
          { "Starfire" },                               -- Shift+R  damage: big hitter
          false,                                        -- Shift+T  (no damage signature for Resto)
          { "Hibernate" },                              -- Shift+F  hard CC
          { "Challenging Roar" },                       -- Shift+G  AoE control
          { racial = true },                            -- Shift+C  racial
          { "Barkskin" },                               -- Shift+V  emergency
          { "Dire Bear Form", "Bear Form", upgrade = true }, -- Shift+1  form
          { "Cat Form" },                               -- Shift+2  form
          { "Travel Form" },                            -- Shift+3  form
          { "Aquatic Form" },                           -- Shift+4  form
        },
        [4] = {
          { "Faerie Fire" },                            -- Ctrl+Q  debuff (any form)
          false, false, false,                          -- Ctrl+E R T  (no secondary attacks)
          { "Innervate" },                              -- Ctrl+F  mana (takes you out of form)
          false,                                        -- Ctrl+G  (Healing Touch is plain R)
          { "Remove Curse" },                           -- Ctrl+C  dispel
          { "Abolish Poison" },                         -- Ctrl+V  dispel
          { "Mark of the Wild" },                       -- Ctrl+1  buff
          { "Thorns" },                                 -- Ctrl+2  buff
          { "Revive" },                                 -- Ctrl+3  resurrect (out of combat)
          { "Rebirth" },                                -- Ctrl+4  combat resurrect
        },
        stances = { moonkin = false },
      },
      controller = {
        pages = {
          [1] = {
            title = "Combat",
            ["RT A"] = { macro = "Regrow", "Regrowth" },  -- Q  main heal
            ["RT X"] = { macro = "Rejuv", "Rejuvenation" }, -- E  HoT
            ["RT Y"] = { "Tranquility" },                 -- 2
            ["RT Up"] = { "Wild Growth" },                -- 1  group heal
            ["RT Right"] = { macro = "HTouch", "Healing Touch" }, -- R  big heal
            ["RT Left"] = { "Swiftmend" },                -- T
            ["RT Down"] = { "Bloom" },                    -- 4
            ["LT X"] = { "Nature's Swiftness" },          -- G
            ["LT B"] = { "Entangling Roots" },            -- V
            ["LT Up"] = { "Wrath" },                      -- Shift+Q
            ["LT Down"] = { "Hibernate" },                -- Shift+F
            ["LT Right"] = { "Moonfire" },                -- Shift+E
            ["none Up"] = { "Cat Form" },
            ["none Right"] = { "Dire Bear Form", "Bear Form", upgrade = true },
            ["none Left"] = { "Travel Form" },
            ["LT+RT A"] = { "Barkskin" },                 -- Shift+V
            ["LT+RT X"] = { "Challenging Roar" },         -- Shift+G
            ["LT+RT B"] = { racial = true },
            ["LT+RT Y"] = { "Starfire" },                 -- Shift+R
            ["LT+RT Up"] = { "Faerie Fire" },             -- Ctrl+Q
          },
          -- Page 2 as shared, with Innervate where Rejuv sits (Rejuv is on page 1).
          [2] = {
            title = "Utility",
            ["RT A"] = { "Revive" },
            ["RT X"] = { "Rebirth" },
            ["RT B"] = { "Remove Curse" },
            ["RT Y"] = { "Abolish Poison" },
            ["RT Down"] = { "Mark of the Wild" },
            ["RT Left"] = { "Aquatic Form" },
            ["RT Right"] = { "Thorns" },
            ["LT X"] = { "Teleport: Moonglade" },
            ["LT B"] = { "Soothe Animal" },
            ["LT Y"] = { "Innervate" },
            ["LT Right"] = { "Track Humanoids" },
          },
        },
      },
    },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain (paged by
  -- form), 2 Shift, 4 Ctrl. Shared by Feral and Balance.
  keyboard = {
    -- Bar 1, caster page.
    [1] = {
      { "Wrath" },                                    -- Q  main attack
      { "Moonfire" },                                 -- E  DoT
      { "Starfire" },                                 -- R  cast nuke
      { "Insect Swarm" },                             -- T  Balance signature
      false,                                          -- F  (no melee in caster form)
      { "Nature's Grasp" },                           -- G  reactive (Balance talent)
      false,                                          -- C  (no caster escape; Travel Form is Shift+3)
      { "Entangling Roots" },                         -- V  snare
      false, false, false,                            -- 1 2 3  (Faerie Fire opens on Ctrl+Q; no caster AoE or interrupt here)
      { "Hurricane" },                                -- 4  ground AoE
    },
    -- Bar 2 (Shift), any form.
    [2] = {
      { macro = "Regrow", "Regrowth" },               -- Shift+Q  self-heal (drops your form first)
      { "Shifting Power", "Nature's Swiftness" },     -- Shift+E  spec cooldown (Feral / Resto talent)
      { "Innervate" },                                -- Shift+R  cooldown
      false,                                          -- Shift+T  (no spec control spell)
      { "Hibernate" },                                -- Shift+F  hard CC
      { "Challenging Roar" },                         -- Shift+G  AoE control
      { racial = true },                              -- Shift+C  racial
      { "Barkskin" },                                 -- Shift+V  emergency
      { "Dire Bear Form", "Bear Form", upgrade = true }, -- Shift+1  form
      { "Cat Form" },                                 -- Shift+2  form
      { "Travel Form" },                              -- Shift+3  form
      { "Moonkin Form", "Aquatic Form" },             -- Shift+4  Balance: Moonkin
    },
    -- [3] is the Alt bar (trinkets, Fish, Bait, Hearthstone), not set here.
    -- Bar 4 (Ctrl): Faerie Fire, utility heals and dispels, buffs and resurrects.
    [4] = {
      { "Faerie Fire" },                              -- Ctrl+Q  debuff (any form)
      false, false, false,                            -- Ctrl+E R T  (no secondary attacks)
      { macro = "Rejuv", "Rejuvenation" },            -- Ctrl+F  HoT top-off (drops your form)
      { macro = "HTouch", "Healing Touch" },          -- Ctrl+G  big heal (drops your form)
      { "Remove Curse" },                             -- Ctrl+C  dispel
      { "Abolish Poison" },                           -- Ctrl+V  dispel
      { "Mark of the Wild" },                         -- Ctrl+1  buff
      { "Thorns" },                                   -- Ctrl+2  buff
      { "Revive" },                                   -- Ctrl+3  out of combat
      { "Rebirth" },                                  -- Ctrl+4  combat resurrect
    },
    stances = {
      cat = { offset = 1, label = "Cat",
        { "Claw" },                                   -- Q  builder
        { "Rake" },                                   -- E  bleed
        { "Ferocious Bite" },                         -- R  big finisher
        { "Rip" },                                    -- T  signature finisher
        { "Shred" },                                  -- F  builder from behind
        { "Cower" },                                  -- G  reactive
        { "Dash" },                                   -- C  escape
        false,                                        -- V
        { macro = "CatOpener", "Prowl" },             -- 1  Prowl, then Ravage (Shred before)
        false,                                        -- 2
        { "Pounce" },                                 -- 3  control
        false,                                        -- 4
      },
      bear = { offset = 3, label = "Bear",
        { "Maul" },                                   -- Q  rage dump (35+ rage)
        { "Lacerate" },                               -- E  bleed (Feral talent)
        { "Primal Bite" },                            -- R  on cooldown (Feral talent)
        { "Growl" },                                  -- T  tank signature
        false,                                        -- F
        { "Frenzied Regeneration" },                  -- G  reactive
        { "Feral Charge" },                           -- C  charge (Feral talent)
        false,                                        -- V
        { "Enrage" },                                 -- 1  opener (rage)
        { "Swipe" },                                  -- 2  AoE
        { "Bash" },                                   -- 3  stun / interrupt
        { "Demoralizing Roar" },                      -- 4  AoE debuff
      },
      moonkin = { offset = 4, label = "Moonkin",
        { "Wrath" },                                  -- Q
        { "Moonfire" },                               -- E
        { "Starfire" },                               -- R  two after each Wrath (Eclipse)
        { "Insect Swarm" },                           -- T
        false,                                        -- F
        { "Nature's Grasp" },                         -- G
        false,                                        -- C
        { "Entangling Roots" },                       -- V
        false, false, false,                          -- 1 2 3
        { "Hurricane" },                              -- 4
      },
    },
  },

  -- Controller: the gamepad bars don't page by form, so page 1's plain-key
  -- roles are form macros (bear = form 1, cat = form 2 or 3, else caster);
  -- until installed each holds its Cat spell, else the Bear one, else the
  -- caster one. Page 1 mirrors the keyboard roles (dev/key-roles.md).
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { macro = "FormAttack", "Claw", "Maul", "Wrath", covers = { "Maul", "Wrath" } },        -- Q
        ["RT X"] = { macro = "FormDoT", "Rake", "Lacerate", "Moonfire", covers = { "Lacerate", "Moonfire" } }, -- E
        ["RT B"] = { macro = "FormStun", "Pounce", "Bash", covers = { "Bash" } },                          -- 3
        ["RT Y"] = { "Swipe" },                                                                             -- 2
        ["RT Up"] = { macro = "FormOpen", "Prowl", "Enrage", covers = { "Enrage", "Ravage" } },            -- 1
        ["RT Right"] = { macro = "FormBig", "Ferocious Bite", "Primal Bite", "Starfire", covers = { "Primal Bite", "Starfire" } }, -- R
        ["RT Left"] = { macro = "FormSig", "Rip", "Growl", "Insect Swarm", covers = { "Growl", "Insect Swarm" } }, -- T
        ["RT Down"] = { macro = "FormArea", "Demoralizing Roar", "Hurricane", covers = { "Hurricane" } },  -- 4
        ["LT A"] = { "Shred" },                                                                             -- F
        ["LT X"] = { macro = "FormProc", "Cower", "Frenzied Regeneration", "Nature's Grasp", covers = { "Frenzied Regeneration", "Nature's Grasp" } }, -- G
        ["LT B"] = { "Entangling Roots" },                                                                  -- V
        ["LT Y"] = { macro = "FormMove", "Dash", "Feral Charge", covers = { "Feral Charge" } },            -- C
        ["LT Up"] = { macro = "Regrow", "Regrowth" },                 -- Shift+Q
        ["LT Down"] = { "Hibernate" },                                -- Shift+F
        ["LT Right"] = { "Shifting Power", "Nature's Swiftness" },    -- Shift+E
        -- No trigger: the forms and an out-of-combat heal.
        ["none Up"] = { "Cat Form" },
        ["none Right"] = { "Dire Bear Form", "Bear Form", upgrade = true },
        ["none Left"] = { "Travel Form" },
        ["none Down"] = { macro = "HTouch", "Healing Touch" },
        ["LT+RT A"] = { "Barkskin" },                                 -- Shift+V
        ["LT+RT X"] = { "Challenging Roar" },                         -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Innervate" },                                -- Shift+R
        ["LT+RT Up"] = { "Faerie Fire" },                             -- Ctrl+Q
      },
      -- Page 2: resurrects, dispels and buffs; the shared Utility buttons
      -- (Layouts/Shared.lua) add Hearthstone, trinkets, fishing, camp, Mount
      -- and professions.
      {
        title = "Utility",
        ["RT A"] = { "Revive" },
        ["RT X"] = { "Rebirth" },
        ["RT B"] = { "Remove Curse" },
        ["RT Y"] = { "Abolish Poison" },
        ["RT Down"] = { "Mark of the Wild" },
        ["RT Left"] = { "Aquatic Form" },
        ["RT Right"] = { "Thorns" },
        ["LT X"] = { "Teleport: Moonglade" },
        ["LT B"] = { "Soothe Animal" },
        ["LT Y"] = { macro = "Rejuv", "Rejuvenation" },
        ["LT Left"] = { "Tranquility" },
        ["LT Right"] = { "Track Humanoids" },
      },
      -- Page 3: Steam Deck helpers and the catch-all (spells a form macro
      -- will cover once installed, Moonkin Form and the rest).
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
