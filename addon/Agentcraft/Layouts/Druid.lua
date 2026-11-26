-- Druid layouts. Data contract: dev/layout-format.md; placement rule
-- (rotation slots in press-frequency order, binding): dev/key-roles.md.
-- Keep every value a literal (no variables, no function calls): dev.ps1
-- rules reads this file without running Lua.
--
-- Rotations (Wowhead WoW Forever guides, 2026-11-26; they win any
-- disagreement):
--   https://www.wowhead.com/forever/guide/classes/druid/balance/rotation-cooldowns-pve-dps
--   https://www.wowhead.com/forever/guide/classes/druid/balance/dps-leveling-tips
--   https://www.wowhead.com/forever/guide/classes/druid/feral/rotation-cooldowns-pve-dps
--   https://www.wowhead.com/forever/guide/classes/druid/feral/dps-leveling-tips
--   https://www.wowhead.com/forever/guide/classes/druid/feral/rotation-cooldowns-pve-tank
--   https://www.wowhead.com/forever/guide/classes/druid/feral/tank-leveling-tips
--   https://www.wowhead.com/forever/guide/classes/druid/restoration/rotation-cooldowns-pve-healer
--   https://www.wowhead.com/forever/guide/classes/druid/restoration/healer-leveling-tips
--   Feral, Cat: keep Rake up; keep a 5-CP Rip up (leveling: Rip at 3+ CP);
--     Shred on Clearcasting and as the filler, Claw when you can't Shred
--     (in front: solo leveling, where Claw is the trained builder);
--     Ferocious Bite only when the target dies within 3 s; Shifting Power
--     (talent) when no energy is wasted. AoE: Rake on every target, Rip on
--     the priority target. Pre-pull: Faerie Fire. No cat AoE or interrupt.
--   Feral, Bear tank: Primal Bite on cooldown; keep 5 Lacerate stacks, fill
--     with Lacerate (Swipe if bleed-immune); Maul to dump rage over 35
--     (leveling, before those talents, Maul is the main attack). AoE:
--     Lacerate on key targets, Primal Bite, Swipe, Maul over 50 rage. Keep
--     Demoralizing Roar and Faerie Fire up; pre-buff Mark of the Wild and
--     Thorns; Enrage before the pull. Taunts Growl and Challenging Roar;
--     defensives Barkskin (usable in forms on Forever) and Frenzied
--     Regeneration. "Bash and Dash" when a fight gets out of hand.
--   Balance: pull with Wrath, Insect Swarm and Moonfire, then 1 Wrath : 2
--     Starfire (Wrath banks Eclipse); refresh the DoTs as they fall off.
--     Short on mana: chain Wrath. 5+ targets: DoTs, then Hurricane. One
--     druid keeps Faerie Fire on the boss. Cooldowns: Innervate (and the
--     racial). Leveling: Entangling Roots for control.
--   Restoration: Rejuvenation is the most-cast heal (light damage, set-up,
--     blanketing), Regrowth for spikes, Swiftmend on a target with a HoT,
--     Wild Growth for 3+ hurt in a party, Nature's Swiftness + Healing
--     Touch for lethal damage (Healing Touch otherwise only "if getting
--     really low" while leveling). Tranquility: weak in raids; leveling
--     still lists it for group emergencies. Dispels Remove Curse, Abolish
--     Poison. Leveling solo: Thorns, Moonfire / Insect Swarm, Entangling
--     Roots, Wrath, Starfire; dungeons: Hurricane on Clearcasting.
--
-- Bar 1 pages by form (Cat offset 1, Bear 3, Moonkin 4; base = caster).
-- Each page puts its own rotation on the slots of dev/key-roles.md:
--
--   key  slot              caster/moonkin   cat                    bear
--   Q    rotation 1        Wrath            Claw                   Maul
--   E    rotation 2        Moonfire         Rake                   Lacerate
--   R    rotation 3        Starfire         Rip                    Primal Bite
--   F    rotation 4/taunt  Insect Swarm     Shred                  Growl
--   T    rotation 5        Entangling Roots Ferocious Bite         Demoralizing Roar
--   G    reactive          Nature's Grasp   Shifting Power         Frenzied Regeneration
--   C    mobility          -                Dash                   Feral Charge
--   V    debuff / pull     Faerie Fire      Faerie Fire            Faerie Fire
--   1    opener            -                CatOpener / Prowl      Enrage
--   2    main AoE          Hurricane        Ravage (no cat AoE)    Swipe
--   3    interrupt         -                Pounce (stun)          Bash
--   4    secondary AoE     -                -                      Challenging Roar
--
-- Faerie Fire sits on V in every form: one key, one home (Wowhead: Balance
-- keeps it on the boss, Bear and Cat pull with it). Wrath stays rotation 1
-- although Starfire is cast twice per Wrath at 60: Wrath is the pull, the
-- start of every cycle, the out-of-mana answer and all of leveling before
-- Starfire. Bear Maul stays Q: the leveling main attack and the rage dump
-- pressed on most swings; Lacerate (talent, 25) is next on E.
-- Cat 2 holds Ravage: the cat has no AoE, and 1 then 2 is Prowl then Ravage.
-- Restoration replaces the caster page with its heals (healer rule) and
-- drops the Moonkin page; its damage goes one tier down to Shift.
--
-- Shift and Ctrl don't page: they hold what works from any form (heals that
-- drop your form first, Barkskin, Innervate, Hibernate, forms, buffs,
-- dispels, resurrects).
--
-- WoW Forever changes (Wowhead; Icy Veins shapeshift page where Wowhead is
-- silent): no powershifting; entering Bear wipes energy, so no bear/cat
-- weave keys; Moonkin blocks heals; heals, dispels, Innervate and Rebirth
-- take you out of form; Barkskin works in forms; Revive is the
-- out-of-combat resurrect.
-- Names: Primal Bite, Lacerate, Shifting Power and Wild Growth are
-- Wowhead's Forever names. Faerie Fire (Feral) is not a Forever talent
-- (dev/forever-talents.md) and no trainer spell by that name is known: the
-- Bear and Cat guides link the trained Faerie Fire (ranks 18/30/42/54) for
-- pulling in form, so every page uses Faerie Fire. Unverified: that Faerie
-- Fire casts in Bear and Cat Form.
-- Talents (dev/forever-talents.md; row r = level 10 + 5r, earlier with the
-- Talented legacy perk): Insect Swarm row 3 = 25, Moonkin Form row 6 = 40
-- (Balance); Feral Charge row 2 = 20, Lacerate row 3 = 25, Primal Bite and
-- Shifting Power row 6 = 40 (Feral); Swiftmend row 3 = 25, Nature's
-- Swiftness row 4 = 30, Wild Growth row 6 = 40 (Restoration). Bloom
-- (Restoration row 2) is passive: no button. Nature's Grasp is not a
-- Forever talent: a trainer spell. Insect Swarm is Balance-only, so its
-- keys on the shared caster page (Feral before Cat Form) and Restoration's
-- Shift+T stay empty unless you put 15 points in Balance.
local _, ns = ...

ns.Layout.Register("DRUID", {
  specs = {
    -- Balance: the shared keyboard (caster and Moonkin pages carry its
    -- rotation); controller page 1 with the caster spells as plain buttons.
    { key = "balance", name = "Balance", tab = 1,
      controller = {
        pages = {
          [1] = {
            title = "Combat",
            ["RT A"] = { "Wrath" },                       -- Q  rotation 1 (pull; 1 per 2 Starfire; mana fallback)
            ["RT X"] = { "Moonfire" },                    -- E  rotation 2 (DoT kept up)
            ["RT Y"] = { "Starfire" },                    -- R  rotation 3 (two per Wrath: Eclipse)
            ["RT B"] = { "Insect Swarm" },                -- F  rotation 4 (second DoT, talent row 3 = 25)
            ["LT A"] = { "Entangling Roots" },            -- T  rotation 5 (leveling control)
            ["LT X"] = { "Nature's Grasp" },              -- G  reactive (melee on you)
            ["LT Y"] = { "Hurricane" },                   -- 2  main AoE (5+ targets)
            ["RT Right"] = { "Faerie Fire" },             -- V  debuff on the boss, before the pull
            ["LT Up"] = { macro = "Regrow", "Regrowth" }, -- Shift+Q  self-heal (drops form)
            ["LT Right"] = { "Barkskin" },                -- Shift+E  defensive
            ["LT Left"] = { macro = "Rejuv", "Rejuvenation" }, -- Shift+T  HoT top-off
            ["LT Down"] = { "Hibernate" },                -- Shift+F  hard CC
            ["none Up"] = { "Cat Form" },
            ["none Right"] = { "Dire Bear Form", "Bear Form", upgrade = true },
            ["none Left"] = { "Travel Form" },
            ["none Down"] = { "Moonkin Form" },
            ["LT+RT A"] = { macro = "HTouch", "Healing Touch" }, -- Shift+V  emergency heal
            ["LT+RT B"] = { racial = true },
            ["LT+RT Y"] = { macro = "Innerv", "Innervate" },                -- Shift+R  the one cooldown (Wowhead)
            ["LT+RT Down"] = { "Cower" },                 -- Ctrl+E  (Cat only, rare)
          },
        },
      },
    },
    { key = "feral", name = "Feral Combat", tab = 2, default = true },
    -- Restoration (healer rule): the heals take the rotation slots in
    -- Wowhead's order of use, the damage moves to Shift Q E R T. Cat and
    -- Bear pages stay shared; no Moonkin page.
    { key = "restoration", name = "Restoration", tab = 3,
      keyboard = {
        [1] = {
          { macro = "Rejuv", "Rejuvenation" },          -- Q  rotation 1: most-cast heal (set-up, blanketing)
          { macro = "Regrow", "Regrowth" },             -- E  rotation 2: spike heal + HoT
          { macro = "HTouch", "Healing Touch" },        -- R  rotation 3: big heal (with Nature's Swiftness)
          { macro = "RemoveCurse", "Remove Curse" }, -- T  rotation 5: healer dispel
          { "Swiftmend" },                              -- F  rotation 4: instant heal on a HoT (talent, row 3 = 25)
          { macro = "NSTouch", "Nature's Swiftness" }, -- G  reactive: instant Healing Touch (talent, row 4 = 30)
          false,                                        -- C  (no caster mobility; Travel Form is Shift+3)
          { "Entangling Roots" },                       -- V  root (leveling solo)
          false,                                        -- 1  (no healer opener)
          { "Wild Growth" },                            -- 2  group heal (talent, row 6 = 40)
          { "Abolish Poison" },                         -- 3  second dispel (no interrupt in caster form)
          { "Tranquility" },                            -- 4  group emergency (leveling; weak in raids)
        },
        [2] = {
          { "Wrath" },                                  -- Shift+Q  damage (one tier down)
          { "Moonfire" },                               -- Shift+E  damage: DoT
          { "Starfire" },                               -- Shift+R  damage: nuke
          { "Insect Swarm" },                           -- Shift+T  damage: DoT (Balance talent: only the HoTs-and-DoTs build with 15 Balance points)
          { "Hibernate" },                              -- Shift+F  hard CC
          { macro = "Innerv", "Innervate" }, -- Shift+G  mana cooldown (takes you out of form)
          { racial = true },                            -- Shift+C  racial
          { "Barkskin" },                               -- Shift+V  emergency: no pushback while hit
          { "Dire Bear Form", "Bear Form", upgrade = true }, -- Shift+1  form
          { "Cat Form" },                               -- Shift+2  form
          { "Travel Form" },                            -- Shift+3  form
          { "Aquatic Form" },                           -- Shift+4  form
        },
        [4] = {
          { "Nature's Grasp" },                         -- Ctrl+Q  cooldown (Wowhead resto list)
          { "Cower" },                                  -- Ctrl+E  (Cat only, rare)
          false, false,                                 -- Ctrl+R T
          { "Soothe Animal" },                          -- Ctrl+F  rare utility
          false, false, false,                          -- Ctrl+G C V  (dispels are plain T and 3; Faerie Fire is V in forms)
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
            ["RT A"] = { macro = "Rejuv", "Rejuvenation" },   -- Q  most-cast heal
            ["RT X"] = { macro = "Regrow", "Regrowth" },      -- E  spike heal
            ["RT Y"] = { macro = "HTouch", "Healing Touch" }, -- R  big heal
            ["RT B"] = { "Swiftmend" },                   -- F  instant heal
            ["LT A"] = { macro = "RemoveCurse", "Remove Curse" },                -- T  dispel
            ["LT X"] = { macro = "NSTouch", "Nature's Swiftness" },          -- G  reactive
            ["LT B"] = { "Abolish Poison" },              -- 3  second dispel
            ["LT Y"] = { "Wild Growth" },                 -- 2  group heal
            ["RT Down"] = { "Tranquility" },              -- 4  group emergency (channel, standing)
            ["RT Right"] = { "Entangling Roots" },        -- V  root
            ["LT Up"] = { "Wrath" },                      -- Shift+Q  damage
            ["LT Right"] = { "Moonfire" },                -- Shift+E  damage: DoT
            ["LT Left"] = { "Insect Swarm" },             -- Shift+T  damage: DoT
            ["LT Down"] = { "Hibernate" },                -- Shift+F  hard CC
            ["none Up"] = { "Cat Form" },
            ["none Right"] = { "Dire Bear Form", "Bear Form", upgrade = true },
            ["none Left"] = { "Travel Form" },
            ["LT+RT A"] = { "Barkskin" },                 -- Shift+V  emergency
            ["LT+RT X"] = { macro = "Innerv", "Innervate" },                -- Shift+G  mana cooldown
            ["LT+RT B"] = { racial = true },
            ["LT+RT Y"] = { "Starfire" },                 -- Shift+R  damage: nuke
            ["LT+RT Up"] = { "Faerie Fire" },             -- rare for a healer
          },
          -- Page 2 as shared, without the dispels (they are on page 1).
          [2] = {
            title = "Utility",
            ["RT A"] = { "Revive" },
            ["RT X"] = { "Rebirth" },
            ["RT Down"] = { "Mark of the Wild" },
            ["RT Left"] = { "Aquatic Form" },
            ["RT Right"] = { "Thorns" },
            ["LT Right"] = { "Track Humanoids" },
          },
          [3] = {
            title = "Extras",
            ["RT A"] = { "Teleport: Moonglade" },
            ["RT X"] = { "Soothe Animal" },
            ["RT B"] = { overflow = true },
            ["RT Y"] = { overflow = true },
            ["none Up"] = { macro = "Reload" },
            ["none Down"] = { macro = "Follow" },
            ["none Left"] = { macro = "Focus" },
            ["none Right"] = { macro = "Assist" },
            ["LT+RT A"] = { macro = "Skull" },
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
      },
    },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain (paged by
  -- form), 2 Shift, 4 Ctrl. Shared by Feral and Balance.
  keyboard = {
    -- Bar 1, caster page (Balance; Feral 1-10 before Bear Form).
    [1] = {
      { "Wrath" },                                    -- Q  rotation 1: pull, filler, mana fallback (level 1)
      { "Moonfire" },                                 -- E  rotation 2: DoT kept up (4)
      { "Starfire" },                                 -- R  rotation 3: two per Wrath (Eclipse)
      { "Entangling Roots" },                         -- T  rotation 5: leveling control (Balance talents buff it)
      { "Insect Swarm" },                             -- F  rotation 4: second DoT (Balance talent, row 3 = 25)
      { "Nature's Grasp" },                           -- G  reactive: roots melee attackers (trainer spell)
      false,                                          -- C  (no caster mobility; Travel Form is Shift+3)
      { "Faerie Fire" },                              -- V  debuff on the boss (one druid), same key in every form
      false,                                          -- 1  (Wrath is the pull)
      { "Hurricane" },                                -- 2  main AoE (5+ targets)
      false, false,                                   -- 3 4  (no caster interrupt or second AoE)
    },
    -- Bar 2 (Shift), any form.
    [2] = {
      { macro = "Regrow", "Regrowth" },               -- Shift+Q  self-heal (drops your form first)
      { "Barkskin" },                                 -- Shift+E  defensive (any form)
      { macro = "Innerv", "Innervate" }, -- Shift+R  cooldown (Balance's one cooldown; mana)
      { macro = "Rejuv", "Rejuvenation" },            -- Shift+T  HoT top-off between pulls (no spec control spell)
      { "Hibernate" },                                -- Shift+F  hard CC
      false,                                          -- Shift+G  (Challenging Roar is Bear 4)
      { racial = true },                              -- Shift+C  racial
      { macro = "HTouch", "Healing Touch" },          -- Shift+V  emergency big heal (drops your form)
      { "Dire Bear Form", "Bear Form", upgrade = true }, -- Shift+1  form
      { "Cat Form" },                                 -- Shift+2  form
      { "Travel Form" },                              -- Shift+3  form
      { "Moonkin Form", "Aquatic Form" },             -- Shift+4  Balance: Moonkin
    },
    -- [3] is the Alt bar (item macros, trinkets, Hearthstone), not set here.
    -- Bar 4 (Ctrl): rare presses, dispels, buffs and resurrects.
    [4] = {
      false,                                          -- Ctrl+Q
      { "Cower" },                                    -- Ctrl+E  threat drop (Cat only, groups)
      false, false,                                   -- Ctrl+R T
      { "Soothe Animal" },                            -- Ctrl+F  rare utility
      false,                                          -- Ctrl+G
      { macro = "RemoveCurse", "Remove Curse" }, -- Ctrl+C  dispel (not a damage spec's rotation)
      { "Abolish Poison" },                           -- Ctrl+V  dispel
      { "Mark of the Wild" },                         -- Ctrl+1  buff
      { "Thorns" },                                   -- Ctrl+2  buff
      { "Revive" },                                   -- Ctrl+3  out of combat
      { "Rebirth" },                                  -- Ctrl+4  combat resurrect
    },
    stances = {
      cat = { offset = 1, label = "Cat",
        { "Claw" },                                   -- Q  rotation 1: builder (in front; the trained leveling builder)
        { "Rake" },                                   -- E  rotation 2: bleed kept up
        { "Rip" },                                    -- R  rotation 3: finisher kept up (5 CP; 3+ leveling)
        { "Ferocious Bite" },                         -- T  rotation 5: finisher only when the target is about to die
        { "Shred" },                                  -- F  rotation 4: builder from behind, on Clearcasting
        { "Shifting Power" },                         -- G  reactive: when no energy is wasted (talent, row 6 = 40)
        { macro = "CatDash", "Dash" }, -- C  mobility
        { "Faerie Fire" },                            -- V  pull / debuff (same key as caster and bear)
        { macro = "CatOpener", "Prowl" },             -- 1  opener: Prowl, then Ravage
        { "Ravage" },                                 -- 2  opener from Prowl (cat has no AoE; 1 then 2)
        { "Pounce" },                                 -- 3  stun from Prowl (cat has no interrupt)
        false,                                        -- 4
      },
      bear = { offset = 3, label = "Bear",
        { "Maul" },                                   -- Q  rotation 1: leveling main attack, rage dump (35+)
        { "Lacerate" },                               -- E  rotation 2: keep 5 stacks, filler (talent, row 3 = 25)
        { "Primal Bite" },                            -- R  rotation 3: on cooldown (talent, row 6 = 40)
        { "Demoralizing Roar" },                      -- T  rotation 5: debuff kept up
        { "Growl" },                                  -- F  tank: taunt
        { "Frenzied Regeneration" },                  -- G  reactive: sustained-damage mitigation
        { macro = "BearCharge", "Feral Charge" }, -- C  gap closer (talent, row 2 = 20)
        { "Faerie Fire" },                            -- V  pull / debuff kept up
        { "Enrage" },                                 -- 1  opener: rage before the pull
        { "Swipe" },                                  -- 2  AoE threat
        { "Bash" },                                   -- 3  interrupt / stun
        { "Challenging Roar" },                       -- 4  AoE taunt
      },
      moonkin = { offset = 4, label = "Moonkin",
        { "Wrath" },                                  -- Q  rotation 1
        { "Moonfire" },                               -- E  rotation 2
        { "Starfire" },                               -- R  rotation 3: two per Wrath (Eclipse)
        { "Entangling Roots" },                       -- T  rotation 5
        { "Insect Swarm" },                           -- F  rotation 4
        { "Nature's Grasp" },                         -- G  reactive
        false,                                        -- C
        { "Faerie Fire" },                            -- V  debuff on the boss
        false,                                        -- 1
        { "Hurricane" },                              -- 2  main AoE
        false, false,                                 -- 3 4
      },
    },
  },

  -- Controller (Feral): the gamepad bars don't page by form, so the page
  -- holds both kits as plain spells, no macros needed: the Cat rotation on
  -- the RT face (key-roles slots 1-4, Wrath and Moonfire before Cat Form at
  -- 20), the Bear tank kit on the LT face in Wowhead's tank priority, and
  -- the taunt and Shifting Power on LT+RT face. Moved against
  -- dev/key-roles.md for that: Bash to LT Down (a stun, the hard-CC slot;
  -- LT B holds Lacerate), Growl to LT+RT A (Healing Touch to LT+RT Up),
  -- Demoralizing Roar to RT Down (Challenging Roar to LT+RT Down), Faerie
  -- Fire to RT Right (pull in both forms). Ravage, Pounce, Cower, Feral
  -- Charge and the caster damage spells fall to the page 3 catch-all.
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { "Claw", "Wrath" },                               -- Cat Q  rotation 1 (Wrath before Cat Form)
        ["RT X"] = { "Rake", "Moonfire" },                            -- Cat E  rotation 2 (Moonfire before Cat Form)
        ["RT Y"] = { "Rip" },                                         -- Cat R  rotation 3: finisher kept up
        ["RT B"] = { "Shred" },                                       -- Cat F  rotation 4: builder from behind
        ["LT A"] = { "Maul" },                                        -- Bear Q  leveling attack, rage dump
        ["LT X"] = { "Primal Bite" },                                 -- Bear R  on cooldown (talent, row 6 = 40)
        ["LT Y"] = { "Swipe" },                                       -- Bear 2  main AoE threat
        ["LT B"] = { "Lacerate" },                                    -- Bear E  keep 5 stacks, filler (talent, row 3 = 25)
        ["LT+RT A"] = { "Growl" },                                    -- Bear F  taunt (a face button: reactive)
        ["LT+RT X"] = { "Shifting Power" },                           -- Cat G  when no energy is wasted (talent, row 6 = 40)
        ["LT+RT Y"] = { "Ferocious Bite" },                           -- Cat T  execute only (rare)
        ["LT+RT B"] = { racial = true },
        ["RT Up"] = { macro = "CatOpener", "Prowl" },                 -- Cat 1  opener, standing
        ["RT Down"] = { "Demoralizing Roar" },                        -- Bear T  debuff kept up (30 s)
        ["RT Left"] = { macro = "CatDash", "Dash" },                                     -- Cat C  mobility / escape
        ["RT Right"] = { "Faerie Fire" },                             -- V  pull / debuff, both forms
        ["LT Up"] = { macro = "Regrow", "Regrowth" },                 -- Shift+Q  self-heal
        ["LT Right"] = { "Barkskin" },                                -- Shift+E  defensive
        ["LT Left"] = { "Frenzied Regeneration" },                    -- Bear G  sustain
        ["LT Down"] = { "Bash" },                                     -- Bear 3  stun / interrupt
        ["LT+RT Up"] = { macro = "HTouch", "Healing Touch" },         -- Shift+V  emergency heal
        ["LT+RT Down"] = { "Challenging Roar" },                      -- Bear 4  AoE taunt
        ["LT+RT Left"] = { "Enrage" },                                -- Bear 1  rage before the pull
        ["LT+RT Right"] = { macro = "Innerv", "Innervate" },                            -- Shift+R  utility cooldown
        -- No trigger: the forms, and the HoT top-off between pulls.
        ["none Up"] = { "Cat Form" },
        ["none Right"] = { "Dire Bear Form", "Bear Form", upgrade = true },
        ["none Left"] = { "Travel Form" },
        ["none Down"] = { macro = "Rejuv", "Rejuvenation" },
      },
      -- Page 2: resurrects, dispels and buffs; the shared Utility buttons
      -- (Layouts/Shared.lua) add Hearthstone, trinkets, item macros, fishing,
      -- camp, Mount and professions.
      {
        title = "Utility",
        ["RT A"] = { "Revive" },
        ["RT X"] = { "Rebirth" },
        ["RT B"] = { macro = "RemoveCurse", "Remove Curse" },
        ["RT Y"] = { "Abolish Poison" },
        ["RT Down"] = { "Mark of the Wild" },
        ["RT Left"] = { "Aquatic Form" },
        ["RT Right"] = { "Thorns" },
        ["LT Right"] = { "Track Humanoids" },
      },
      -- Page 3: Moonglade, Soothe Animal, Tranquility, Steam Deck helpers and
      -- the catch-all (Moonkin Form, the caster damage and the rest).
      {
        title = "Extras",
        ["RT A"] = { "Teleport: Moonglade" },
        ["RT X"] = { "Soothe Animal" },
        ["RT B"] = { overflow = true },
        ["RT Y"] = { "Tranquility" },
        ["none Up"] = { macro = "Reload" },
        ["none Down"] = { macro = "Follow" },
        ["none Left"] = { macro = "Focus" },
        ["none Right"] = { macro = "Assist" },
        ["LT+RT A"] = { macro = "Skull" },
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
