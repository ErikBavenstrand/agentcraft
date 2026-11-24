-- Priest layouts. Data contract: dev/layout-format.md; key roles (the same
-- kind of ability on the same key for every class): dev/key-roles.md. Keep
-- every value a literal (no variables, no function calls): dev.ps1 rules
-- reads this file without running Lua.
--
-- Shadow is the leveling spec (solo; Icy Veins and Mobalytics 2026-11) and
-- uses the shared layout. Discipline and Holy heal in groups: by the healer
-- rule their heals take the plain Q E R T and 1 keys and the damage moves to
-- Shift Q E R T (Bar 1, Bar 2, Bar 4 and controller page 1 overrides; F G C
-- V and Shift F G C V stay as shared). Spells and levels: warcraft.wiki.gg
-- Priest abilities (Forever).
--
-- Shadowform (Shadow talent, 40) pages Bar 1 (offset 1). Heals and Holy
-- spells can't be cast in it (a heal cancels it), so its page keeps every
-- role on its key and fills 1 with the MindPull macro instead of Holy Fire.
-- Discipline and Holy drop the page.
--
-- The race-specific priest spells (quests at 10 and 20) share two keys by
-- chain, so each race gets its own: Ctrl+E (level 10) and Shift+V (level 20).
local _, ns = ...

ns.Layout.Register("PRIEST", {
  specs = {
    { key = "discipline", name = "Discipline", tab = 1,
      keyboard = {
        stances = { shadowform = false },
        -- Healer rule: Q main heal, E HoT, R big heal, T spec heal, 1 group heal.
        [1] = {
          { "Flash Heal", "Lesser Heal" },                -- Q  main heal
          { "Renew" },                                    -- E  HoT
          { "Greater Heal", "Heal", upgrade = true },     -- R  big heal
          { "Penance", "Prayer of Mending", "Holy Binding" }, -- T  spec heal
          { "Shoot" },                                    -- F  wand
          { "Shadow Word: Death" },                       -- G  execute
          { "Fade" },                                     -- C  escape: drops threat
          false,                                          -- V  (no snare)
          { "Prayer of Healing" },                        -- 1  group heal
          { "Holy Nova" },                                -- 2  AoE
          { "Silence", "Dispel Magic" },                  -- 3  interrupt / dispel
          { "Power Word: Shield" },                       -- 4  no ground AoE: the shield you cast most
        },
        -- Damage on Shift Q E R T, in the plain roles' order.
        [2] = {
          { macro = "Flay", "Mind Flay", "Smite" },       -- Shift+Q  main attack
          { "Shadow Word: Pain" },                        -- Shift+E  DoT
          { "Mind Blast" },                               -- Shift+R  big hitter
          { "Holy Fire" },                                -- Shift+T  nuke
          { "Shackle Undead" },                           -- Shift+F  hard CC
          { "Psychic Scream" },                           -- Shift+G  AoE control
          { racial = true },                              -- Shift+C  racial
          { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" }, -- Shift+V  race spell (20)
          { "Power Word: Fortitude" },                    -- Shift+1  buff
          { "Inner Fire" },                               -- Shift+2  buff
          { macro = "Empower", "Power Infusion", "Inner Focus" }, -- Shift+3  buff / cooldowns
          { "Fear Ward" },                                -- Shift+4  buff
        },
        [4] = {
          { "Mana Burn" },                                -- Ctrl+Q  secondary attack
          { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" }, -- Ctrl+E  race spell (10)
          { "Mind Soothe" },                              -- Ctrl+R  utility
          { "Mind Vision" },                              -- Ctrl+T  utility
          { "Mind Control" },                             -- Ctrl+F  control (Shift+T for Shadow)
          { "Devouring Plague" },                         -- Ctrl+G  second DoT (plain 4 for Shadow)
          { "Abolish Disease", "Cure Disease", upgrade = true }, -- Ctrl+C  cure
          { "Resurrection" },                             -- Ctrl+V  resurrect
          { "Divine Spirit" },                            -- Ctrl+1  buff
          { "Shadow Protection" },                        -- Ctrl+2  buff
          { "Prayer of Fortitude" },                      -- Ctrl+3  group buff
          { "Levitate" },                                 -- Ctrl+4  utility
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { "Flash Heal", "Lesser Heal" },
        ["RT X"] = { "Renew" },
        ["RT B"] = { "Silence", "Dispel Magic" },
        ["RT Y"] = { "Holy Nova" },
        ["RT Up"] = { "Prayer of Healing" },
        ["RT Right"] = { "Greater Heal", "Heal", upgrade = true },
        ["RT Left"] = { "Penance", "Prayer of Mending", "Holy Binding" },
        ["RT Down"] = { "Power Word: Shield" },
        ["LT A"] = { "Shoot" },
        ["LT X"] = { "Shadow Word: Death" },
        ["LT Y"] = { "Fade" },
        ["LT Up"] = { macro = "Flay", "Mind Flay", "Smite" },
        ["LT Down"] = { "Shackle Undead" },
        ["LT Left"] = { "Holy Fire" },
        ["LT Right"] = { "Shadow Word: Pain" },
        ["none Up"] = { "Power Word: Fortitude" },
        ["none Left"] = { "Inner Fire" },
        ["none Right"] = { macro = "Empower", "Power Infusion", "Inner Focus" },
        ["LT+RT A"] = { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" },
        ["LT+RT X"] = { "Psychic Scream" },
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Mind Blast" },
        ["LT+RT Up"] = { "Mana Burn" },
        ["LT+RT Down"] = { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" },
        ["LT+RT Left"] = { "Mind Soothe" },
        ["LT+RT Right"] = { "Mind Vision" },
      } } },
    },
    { key = "holy", name = "Holy", tab = 2,
      keyboard = {
        stances = { shadowform = false },
        [1] = {
          { "Flash Heal", "Lesser Heal" },                -- Q  main heal
          { "Renew" },                                    -- E  HoT
          { "Greater Heal", "Heal", upgrade = true },     -- R  big heal
          { "Penance", "Prayer of Mending", "Holy Binding" }, -- T  spec heal
          { "Shoot" },                                    -- F  wand
          { "Shadow Word: Death" },                       -- G  execute
          { "Fade" },                                     -- C  escape: drops threat
          false,                                          -- V  (no snare)
          { "Prayer of Healing" },                        -- 1  group heal
          { "Holy Nova" },                                -- 2  AoE
          { "Silence", "Dispel Magic" },                  -- 3  interrupt / dispel
          { "Power Word: Shield" },                       -- 4  no ground AoE: the shield you cast most
        },
        [2] = {
          { macro = "Flay", "Mind Flay", "Smite" },       -- Shift+Q  main attack
          { "Shadow Word: Pain" },                        -- Shift+E  DoT
          { "Mind Blast" },                               -- Shift+R  big hitter
          { "Holy Fire" },                                -- Shift+T  nuke
          { "Shackle Undead" },                           -- Shift+F  hard CC
          { "Psychic Scream" },                           -- Shift+G  AoE control
          { racial = true },                              -- Shift+C  racial
          { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" }, -- Shift+V  race spell (20)
          { "Power Word: Fortitude" },                    -- Shift+1  buff
          { "Inner Fire" },                               -- Shift+2  buff
          { macro = "Empower", "Power Infusion", "Inner Focus" }, -- Shift+3  cooldowns
          { "Fear Ward" },                                -- Shift+4  buff
        },
        [4] = {
          { "Mana Burn" },                                -- Ctrl+Q  secondary attack
          { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" }, -- Ctrl+E  race spell (10)
          { "Mind Soothe" },                              -- Ctrl+R  utility
          { "Mind Vision" },                              -- Ctrl+T  utility
          { "Mind Control" },                             -- Ctrl+F  control (Shift+T for Shadow)
          { "Devouring Plague" },                         -- Ctrl+G  second DoT (plain 4 for Shadow)
          { "Abolish Disease", "Cure Disease", upgrade = true }, -- Ctrl+C  cure
          { "Resurrection" },                             -- Ctrl+V  resurrect
          { "Divine Spirit" },                            -- Ctrl+1  buff
          { "Shadow Protection" },                        -- Ctrl+2  buff
          { "Prayer of Fortitude" },                      -- Ctrl+3  group buff
          { "Levitate" },                                 -- Ctrl+4  utility
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { "Flash Heal", "Lesser Heal" },
        ["RT X"] = { "Renew" },
        ["RT B"] = { "Silence", "Dispel Magic" },
        ["RT Y"] = { "Holy Nova" },
        ["RT Up"] = { "Prayer of Healing" },
        ["RT Right"] = { "Greater Heal", "Heal", upgrade = true },
        ["RT Left"] = { "Penance", "Prayer of Mending", "Holy Binding" },
        ["RT Down"] = { "Power Word: Shield" },
        ["LT A"] = { "Shoot" },
        ["LT X"] = { "Shadow Word: Death" },
        ["LT Y"] = { "Fade" },
        ["LT Up"] = { macro = "Flay", "Mind Flay", "Smite" },
        ["LT Down"] = { "Shackle Undead" },
        ["LT Left"] = { "Holy Fire" },
        ["LT Right"] = { "Shadow Word: Pain" },
        ["none Up"] = { "Power Word: Fortitude" },
        ["none Left"] = { "Inner Fire" },
        ["none Right"] = { macro = "Empower", "Power Infusion", "Inner Focus" },
        ["LT+RT A"] = { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" },
        ["LT+RT X"] = { "Psychic Scream" },
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Mind Blast" },
        ["LT+RT Up"] = { "Mana Burn" },
        ["LT+RT Down"] = { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" },
        ["LT+RT Left"] = { "Mind Soothe" },
        ["LT+RT Right"] = { "Mind Vision" },
      } } },
    },
    { key = "shadow", name = "Shadow", tab = 3, default = true },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  -- Rows follow dev/key-roles.md (the BM hunter is the reference).
  keyboard = {
    [1] = {
      { macro = "Flay", "Mind Flay", "Smite" },         -- Q  main attack: Smite (1) until Mind Flay
      { "Shadow Word: Pain" },                          -- E  DoT (4)
      { "Mind Blast" },                                 -- R  big hitter (10)
      { "Vampiric Embrace", "Penance", "Prayer of Mending" }, -- T  spec signature (talents)
      { "Shoot" },                                      -- F  wand: the secondary attack
      { "Shadow Word: Death" },                         -- G  execute (32)
      { "Fade" },                                       -- C  escape (8)
      false,                                            -- V  snare: priests have none
      { "Holy Fire" },                                  -- 1  pull (20)
      { "Holy Nova" },                                  -- 2  AoE (Holy talent)
      { "Silence", "Dispel Magic" },                    -- 3  interrupt; Dispel Magic (18) until Silence
      { "Devouring Plague" },                           -- 4  second DoT (20): closest fit
    },
    [2] = {
      { "Flash Heal", "Lesser Heal" },                  -- Shift+Q  self-heal (1 / 20)
      { "Power Word: Shield" },                         -- Shift+E  defensive (6)
      { macro = "Empower", "Power Infusion", "Inner Focus" }, -- Shift+R  burst
      { "Mind Control" },                               -- Shift+T  control (30)
      { "Shackle Undead" },                             -- Shift+F  hard CC (20)
      { "Psychic Scream" },                             -- Shift+G  AoE control (14)
      { racial = true },                                -- Shift+C  racial
      { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" }, -- Shift+V  race spell (20)
      { "Power Word: Fortitude" },                      -- Shift+1  buff (1)
      { "Inner Fire" },                                 -- Shift+2  buff (12)
      { "Shadowform" },                                 -- Shift+3  form (40)
      { "Fear Ward" },                                  -- Shift+4  buff (20)
    },
    -- [3] is the shared Alt bar (Fish, Bait, trinkets, Hearthstone), not set here.
    [4] = {
      { "Mana Burn" },                                  -- Ctrl+Q  secondary attack (24)
      { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" }, -- Ctrl+E  race spell (10)
      { "Mind Soothe" },                                -- Ctrl+R (20)
      { "Mind Vision" },                                -- Ctrl+T (22)
      { "Renew" },                                      -- Ctrl+F  top-off (8)
      { "Greater Heal", "Heal", upgrade = true },       -- Ctrl+G (16 / 40)
      { "Abolish Disease", "Cure Disease", upgrade = true }, -- Ctrl+C (14 / 32)
      { "Resurrection" },                               -- Ctrl+V (10)
      { "Divine Spirit" },                              -- Ctrl+1 (30)
      { "Shadow Protection" },                          -- Ctrl+2 (30)
      { "Prayer of Fortitude" },                        -- Ctrl+3 (48)
      { "Levitate" },                                   -- Ctrl+4 (34)
    },
    stances = {
      -- Same roles on the same keys; Holy spells give way (no Holy Fire or
      -- Holy Nova in form).
      shadowform = {
        offset = 1, label = "Shadowform",
        { macro = "Flay", "Mind Flay", "Smite" },       -- Q
        { "Shadow Word: Pain" },                        -- E
        { "Mind Blast" },                               -- R
        { "Vampiric Embrace", "Penance", "Prayer of Mending" }, -- T
        { "Shoot" },                                    -- F
        { "Shadow Word: Death" },                       -- G
        { "Fade" },                                     -- C
        false,                                          -- V
        { macro = "MindPull" },                         -- 1  pull: target + Mind Blast (once installed)
        false,                                          -- 2  (Holy Nova: not in form)
        { "Silence", "Dispel Magic" },                  -- 3
        { "Devouring Plague" },                         -- 4
      },
    },
  },

  -- Controller: keys "<layer> <button>", layer none / LT / RT / LT+RT,
  -- button A X B Y or Up Down Left Right. Page 1 mirrors the keyboard roles
  -- (dev/key-roles.md). The Gamepad UI bars don't page by stance.
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { macro = "Flay", "Mind Flay", "Smite" },   -- Q
        ["RT X"] = { "Shadow Word: Pain" },                    -- E
        ["RT B"] = { "Silence", "Dispel Magic" },              -- 3
        ["RT Y"] = { "Holy Nova" },                            -- 2
        ["RT Up"] = { "Holy Fire" },                           -- 1
        ["RT Right"] = { macro = "MindPull", "Mind Blast" },   -- R (MindPull also picks a target)
        ["RT Left"] = { "Vampiric Embrace", "Penance", "Prayer of Mending" }, -- T
        ["RT Down"] = { "Devouring Plague" },                  -- 4
        ["LT A"] = { "Shoot" },                                -- F
        ["LT X"] = { "Shadow Word: Death" },                   -- G
        ["LT Y"] = { "Fade" },                                 -- C (LT B, the snare, stays empty)
        ["LT Up"] = { "Flash Heal", "Lesser Heal" },           -- Shift+Q
        ["LT Down"] = { "Shackle Undead" },                    -- Shift+F
        ["LT Left"] = { "Mind Control" },                      -- Shift+T
        ["LT Right"] = { "Power Word: Shield" },               -- Shift+E
        ["none Up"] = { "Power Word: Fortitude" },
        ["none Left"] = { "Inner Fire" },
        ["none Right"] = { "Shadowform" },
        ["none Down"] = { "Renew" },
        ["LT+RT A"] = { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" }, -- Shift+V
        ["LT+RT X"] = { "Psychic Scream" },                    -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { macro = "Empower", "Power Infusion", "Inner Focus" }, -- Shift+R
        ["LT+RT Up"] = { "Mana Burn" },                        -- Ctrl+Q
        ["LT+RT Down"] = { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" }, -- Ctrl+E
        ["LT+RT Left"] = { "Mind Soothe" },                    -- Ctrl+R
        ["LT+RT Right"] = { "Mind Vision" },                   -- Ctrl+T
      },
      -- Page 2: resurrect and buffs; the shared Utility buttons
      -- (Layouts/Shared.lua) add Hearthstone, trinkets, fishing, camp, Mount
      -- and professions. Spells on no page (Greater Heal and Prayer of
      -- Healing for Shadow, Mind Control for healers...) go to page 3.
      {
        title = "Utility",
        ["RT A"] = { "Resurrection" },
        ["RT X"] = { "Levitate" },
        ["RT B"] = { "Abolish Disease", "Cure Disease", upgrade = true },
        ["RT Y"] = { "Divine Spirit" },
        ["RT Down"] = { "Fear Ward" },
        ["RT Left"] = { "Shadow Protection" },
        ["RT Right"] = { "Prayer of Fortitude" },
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
        ["LT+RT X"] = { overflow = true }, ["LT+RT B"] = { overflow = true },
        ["LT+RT Y"] = { overflow = true }, ["LT+RT Up"] = { overflow = true },
        ["LT+RT Down"] = { overflow = true }, ["LT+RT Left"] = { overflow = true },
        ["LT+RT Right"] = { overflow = true },
      },
    },
    paddles = {},
  },
})
