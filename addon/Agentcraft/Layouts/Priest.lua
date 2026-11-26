-- Priest layouts. Data contract: dev/layout-format.md; placement rule
-- (rotation slots, keyboard and controller tables): dev/key-roles.md. Keep
-- every value a literal (no variables, no function calls): dev.ps1 rules
-- reads this file without running Lua.
--
-- Rotations (WoW Forever; Wowhead's guides, sources below, read 2026-11-26):
--   Shadow (leveling spec, solo). Leveling: buffs, PW:Shield (optional),
--     open with Mind Blast, SW:Pain, Devouring Plague, Mind Flay if mana
--     permits, finish with the wand; early pulls use Smite [2]. AoE: SW:Pain
--     on secondary targets, Devouring Plague on the mob that dies first
--     (Devouring Contagion) [1][2]. 60 opener: (Fade), pre-cast Mind Blast,
--     SW:Pain, Devouring Plague, SW:Death, Vampiric Embrace, Mind Blast, Mind
--     Flay. Priority: keep SW:Pain up > keep Devouring Plague up > Mind Blast
--     on cooldown > SW:Death on cooldown > keep Vampiric Embrace up > fully
--     channel Mind Flay [1]. No AoE spell and no damage cooldown [1].
--     Interrupt: Silence (talent, Wowhead's one-point option) [2]. Shadowform
--     (row 6 = 40) pages Bar 1; a heal cancels it.
--   Discipline (healer) [3]: PW:Shield the tank > Penance if injured > keep
--     Renew up > Heal (Greater Heal the costly version) once Penance is on
--     cooldown; Flash Heal if someone is in danger [4]. AoE: Prayer of
--     Healing, PW:Shield on anyone in urgent danger. Cooldowns: Inner Focus
--     (with Prayer of Healing / Greater Heal), Fear Ward, Devouring Plague
--     for extra damage. Leveling [4]: buffs, PW:Shield, open with Penance (30)
--     or SW:Pain, wand; from ~41 Holy Fire -> Penance, Smite while Penance
--     cools down; Renew on yourself.
--   Holy (healer) [5]: keep Renew on the tank > Heal > Flash Heal if the
--     tank is about to die > Binding Heal when you and the tank are hurt >
--     Prayer of Mending on cooldown > Greater Heal (40) > PW:Shield with
--     spare mana; alternate heals for Litany of Light. Group: Prayer of
--     Mending, Prayer of Healing (most of the party low), Holy Nova when
--     stacked. Fade drops threat. Leveling [6]: buffs, PW:Shield, open with
--     Mind Blast (Holy Fire from 20), SW:Pain, Smite, wand; Dispel Magic (18),
--     Cure Disease (14) then Abolish Disease (32).
--   Healers share their bars (R is a chain: Penance, the Disc talent, then
--   Binding Heal, a trainer spell at 56 for every priest; Prayer of Mending
--   on G). Both guides rank Greater Heal last
--   among the single-target heals, so it takes V (priests have no snare).
--   Spell levels: Wowhead's trainer tables [4][6]; warcraft.wiki.gg Priest
--   abilities (Forever) [7] for the rest. Talent rows (dev/forever-talents.md;
--   row r = level 10 + 5r, earlier with the Talented perk): Inner Focus row
--   2 = 20, Penance row 4 = 30, Power Infusion row 6 = 40 (Discipline); Holy
--   Nova row 2 = 20, Prayer of Mending row 6 = 40 (Holy); Mind Flay row 2 =
--   20, Vampiric Embrace row 3 = 25, Silence row 4 = 30, Shadowform row 6 =
--   40 (Shadow). Holy Binding (Flash Heal on others heals you) is passive. Race spells come from quests at 10
--   and 20 and share two keys by chain (Shift+E / LT Right at 10, Shift+V /
--   LT+RT A at 20; Ctrl+E for healers).
-- Sources: [1] wowhead.com/forever/guide/classes/priest/shadow/rotation-cooldowns-pve-dps
--   [2] wowhead.com/forever/guide/classes/priest/shadow/dps-leveling-tips
--   [3] wowhead.com/forever/guide/classes/priest/discipline/rotation-cooldowns-pve-healer
--   [4] wowhead.com/forever/guide/classes/priest/discipline/healer-leveling-tips
--   [5] wowhead.com/forever/guide/classes/priest/holy/rotation-cooldowns-pve-healer
--   [6] wowhead.com/forever/guide/classes/priest/holy/healer-leveling-tips
--   [7] warcraft.wiki.gg/wiki/Priest_abilities_(Forever)
--
-- The shared layout is Shadow's. Discipline and Holy replace Bar 1, Shift,
-- Ctrl and controller page 1 (identical for both: the talent-heal keys are
-- chains) and drop the Shadowform page. PW:Shield is the pull button on 1
-- for every spec (cast before each pull in every guide).
-- Once installed, the self-cast fallback macros (Macros/Data/Priest.lua:
-- PriestHeal, PriestRenew, PriestFlash, PriestShield, DispelMagic: friendly
-- target, else you) take their spell's keys, and ShadowOn takes Shadowform's.
local _, ns = ...

ns.Layout.Register("PRIEST", {
  specs = {
    { key = "discipline", name = "Discipline", tab = 1,
      keyboard = {
        stances = { shadowform = false },
        [1] = {
          { macro = "PriestHeal", "Heal", "Lesser Heal", upgrade = true },      -- Q  slot 1: efficient main heal, the most casts (Lesser Heal 1, Heal 16)
          { macro = "PriestRenew", "Renew" },                                    -- E  slot 2: HoT kept on the tank (8)
          { "Penance", "Binding Heal" },                  -- R  slot 3: Disc's second priority (Penance, talent row 4 = 30); Holy's alternate heal (Binding Heal, trainer 56)
          { macro = "DispelMagic", "Dispel Magic" },                             -- T  slot 5: healer dispel (18)
          { macro = "PriestFlash", "Flash Heal" },                               -- F  slot 4: fast emergency heal (20)
          { "Prayer of Mending" },                        -- G  reactive: Holy's bouncing heal, recast on cooldown (talent, row 6 = 40)
          { "Fade" },                                     -- C  escape: drops threat when you pull aggro
          { "Greater Heal" },                             -- V  no snare: the big slow heal, last single-target heal in both guides (40)
          { macro = "PriestShield", "Power Word: Shield" },                       -- 1  pull: shield the tank before the pull, then on spikes (Disc's first priority)
          { "Prayer of Healing" },                        -- 2  main AoE: group heal (30)
          { "Abolish Disease", "Cure Disease", upgrade = true }, -- 3  no interrupt: the second dispel (14 / 32)
          { "Holy Nova" },                                -- 4  secondary AoE: Searing Light proc (Holy talent, row 2 = 20)
        },
        -- Healer rule: solo damage one tier down, in the damage rotation's order.
        [2] = {
          { "Smite" },                                    -- Shift+Q  damage slot 1: Smite filler
          { "Shadow Word: Pain" },                        -- Shift+E  damage slot 2: DoT
          { "Mind Blast" },                               -- Shift+R  damage slot 3: big hitter
          { "Holy Fire" },                                -- Shift+T  damage slot 5: Disc opener on the far target
          { "Shoot" },                                    -- Shift+F  damage slot 4: wand finisher
          { "Psychic Scream" },                           -- Shift+G  AoE control
          { racial = true },                              -- Shift+C  racial
          { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" }, -- Shift+V  emergency: race spell (20)
          { "Power Word: Fortitude" },                    -- Shift+1  buff
          { "Inner Fire" },                               -- Shift+2  buff
          { macro = "Empower", "Power Infusion", "Inner Focus" }, -- Shift+3  cooldowns (Disc talents: Inner Focus 20 until Power Infusion 40)
          { "Fear Ward" },                                -- Shift+4  buff
        },
        [4] = {
          { "Devouring Plague" },                         -- Ctrl+Q  secondary debuff: Disc's damage cooldown, for when you need extra damage
          { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" }, -- Ctrl+E  race spell (10)
          { "Mind Soothe" },                              -- Ctrl+R  rare utility
          { "Mind Vision" },                              -- Ctrl+T  rare utility
          { "Shackle Undead" },                           -- Ctrl+F  CC (Shift+F holds the wand)
          { "Mind Control" },                             -- Ctrl+G  control
          { "Shadow Word: Death" },                       -- Ctrl+C  rare execute when soloing
          { "Resurrection" },                             -- Ctrl+V  resurrect
          { "Divine Spirit" },                            -- Ctrl+1  buff
          { "Shadow Protection" },                        -- Ctrl+2  buff
          { "Prayer of Fortitude" },                      -- Ctrl+3  group buff
          { "Levitate" },                                 -- Ctrl+4  utility
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { macro = "PriestHeal", "Heal", "Lesser Heal", upgrade = true },  -- Q  slot 1
        ["RT X"] = { macro = "PriestRenew", "Renew" },                                -- E  slot 2
        -- Moved against the table (key-roles allows one): the instant shield
        -- is Disc's first priority and is pressed while moving; slot 3 (the
        -- Penance channel / Binding Heal cast) is pressed standing anyway.
        ["RT Y"] = { macro = "PriestShield", "Power Word: Shield" },                   -- 1  shield on a face button
        ["RT Up"] = { "Penance", "Binding Heal" },             -- R  slot 3 on the D-pad
        ["RT B"] = { macro = "PriestFlash", "Flash Heal" },                           -- F  slot 4
        ["LT A"] = { macro = "DispelMagic", "Dispel Magic" },                         -- T  slot 5: dispel
        ["LT X"] = { "Prayer of Mending" },                    -- G  reactive: instant bouncing heal
        ["LT B"] = { "Abolish Disease", "Cure Disease", upgrade = true }, -- 3  second dispel
        ["LT Y"] = { "Prayer of Healing" },                    -- 2  group heal
        ["RT Down"] = { "Holy Nova" },                         -- 4  secondary AoE
        ["RT Left"] = { "Fade" },                              -- C  escape
        ["RT Right"] = { "Greater Heal" },                     -- V  big slow heal, cast standing
        ["LT Up"] = { "Smite" },                               -- Shift+Q  damage slot 1
        ["LT Right"] = { "Shadow Word: Pain" },                -- Shift+E  damage slot 2
        ["LT Left"] = { "Holy Fire" },                         -- Shift+T  damage opener
        ["LT Down"] = { "Shoot" },                             -- Shift+F  wand
        ["LT+RT Y"] = { "Mind Blast" },                        -- Shift+R  damage slot 3
        ["LT+RT X"] = { "Psychic Scream" },                    -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT A"] = { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" }, -- Shift+V
        ["LT+RT Up"] = { "Devouring Plague" },                 -- Ctrl+Q
        ["LT+RT Down"] = { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" }, -- Ctrl+E
        ["LT+RT Left"] = { "Mind Soothe" },                    -- Ctrl+R
        ["LT+RT Right"] = { "Mind Vision" },                   -- Ctrl+T
        ["none Up"] = { "Power Word: Fortitude" },             -- out of combat buffs
        ["none Left"] = { "Inner Fire" },
        ["none Right"] = { macro = "Empower", "Power Infusion", "Inner Focus" },
        ["none Down"] = { "Shackle Undead" },                  -- cast standing, before the pull
      } } },
    },
    { key = "holy", name = "Holy", tab = 2,
      -- Same bars as Discipline (the talent-heal keys are chains).
      keyboard = {
        stances = { shadowform = false },
        [1] = {
          { macro = "PriestHeal", "Heal", "Lesser Heal", upgrade = true },      -- Q  slot 1: efficient main heal
          { macro = "PriestRenew", "Renew" },                                    -- E  slot 2: HoT kept on the tank
          { "Penance", "Binding Heal" },                  -- R  slot 3: Binding Heal (you + the tank, trainer 56), alternated with Heal / Flash Heal
          { macro = "DispelMagic", "Dispel Magic" },                             -- T  slot 5: healer dispel
          { macro = "PriestFlash", "Flash Heal" },                               -- F  slot 4: fast emergency heal
          { "Prayer of Mending" },                        -- G  reactive: Prayer of Mending on cooldown
          { "Fade" },                                     -- C  escape: drops threat
          { "Greater Heal" },                             -- V  no snare: big slow heal (40)
          { macro = "PriestShield", "Power Word: Shield" },                       -- 1  pull: shield the tank
          { "Prayer of Healing" },                        -- 2  main AoE: group heal
          { "Abolish Disease", "Cure Disease", upgrade = true }, -- 3  no interrupt: second dispel
          { "Holy Nova" },                                -- 4  secondary AoE: Searing Light proc
        },
        [2] = {
          { "Smite" },                                    -- Shift+Q  damage slot 1
          { "Shadow Word: Pain" },                        -- Shift+E  damage slot 2
          { "Mind Blast" },                               -- Shift+R  damage slot 3
          { "Holy Fire" },                                -- Shift+T  damage opener
          { "Shoot" },                                    -- Shift+F  wand
          { "Psychic Scream" },                           -- Shift+G  AoE control
          { racial = true },                              -- Shift+C  racial
          { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" }, -- Shift+V  race spell (20)
          { "Power Word: Fortitude" },                    -- Shift+1  buff
          { "Inner Fire" },                               -- Shift+2  buff
          { macro = "Empower", "Power Infusion", "Inner Focus" }, -- Shift+3  cooldowns
          { "Fear Ward" },                                -- Shift+4  buff
        },
        [4] = {
          { "Devouring Plague" },                         -- Ctrl+Q  damage cooldown
          { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" }, -- Ctrl+E  race spell (10)
          { "Mind Soothe" },                              -- Ctrl+R
          { "Mind Vision" },                              -- Ctrl+T
          { "Shackle Undead" },                           -- Ctrl+F
          { "Mind Control" },                             -- Ctrl+G
          { "Shadow Word: Death" },                       -- Ctrl+C
          { "Resurrection" },                             -- Ctrl+V
          { "Divine Spirit" },                            -- Ctrl+1
          { "Shadow Protection" },                        -- Ctrl+2
          { "Prayer of Fortitude" },                      -- Ctrl+3
          { "Levitate" },                                 -- Ctrl+4
        },
      },
      controller = { pages = { [1] = {
        title = "Combat",
        ["RT A"] = { macro = "PriestHeal", "Heal", "Lesser Heal", upgrade = true },  -- Q
        ["RT X"] = { macro = "PriestRenew", "Renew" },                                -- E
        ["RT Y"] = { macro = "PriestShield", "Power Word: Shield" },                   -- 1, moved: instant, pressed on the move
        ["RT Up"] = { "Penance", "Binding Heal" },             -- R, moved: a cast, standing
        ["RT B"] = { macro = "PriestFlash", "Flash Heal" },                           -- F
        ["LT A"] = { macro = "DispelMagic", "Dispel Magic" },                         -- T
        ["LT X"] = { "Prayer of Mending" },                    -- G
        ["LT B"] = { "Abolish Disease", "Cure Disease", upgrade = true }, -- 3
        ["LT Y"] = { "Prayer of Healing" },                    -- 2
        ["RT Down"] = { "Holy Nova" },                         -- 4
        ["RT Left"] = { "Fade" },                              -- C
        ["RT Right"] = { "Greater Heal" },                     -- V
        ["LT Up"] = { "Smite" },                               -- Shift+Q
        ["LT Right"] = { "Shadow Word: Pain" },                -- Shift+E
        ["LT Left"] = { "Holy Fire" },                         -- Shift+T
        ["LT Down"] = { "Shoot" },                             -- Shift+F
        ["LT+RT Y"] = { "Mind Blast" },                        -- Shift+R
        ["LT+RT X"] = { "Psychic Scream" },                    -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT A"] = { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" }, -- Shift+V
        ["LT+RT Up"] = { "Devouring Plague" },                 -- Ctrl+Q
        ["LT+RT Down"] = { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" }, -- Ctrl+E
        ["LT+RT Left"] = { "Mind Soothe" },                    -- Ctrl+R
        ["LT+RT Right"] = { "Mind Vision" },                   -- Ctrl+T
        ["none Up"] = { "Power Word: Fortitude" },
        ["none Left"] = { "Inner Fire" },
        ["none Right"] = { macro = "Empower", "Power Infusion", "Inner Focus" },
        ["none Down"] = { "Shackle Undead" },
      } } },
    },
    { key = "shadow", name = "Shadow", tab = 3, default = true },
  },

  -- Keyboard (Shadow): index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain,
  -- 2 Shift, 4 Ctrl. A level 10 priest has Smite, SW:Pain, Mind Blast and
  -- the wand on Q E R F.
  keyboard = {
    [1] = {
      { macro = "Flay", "Mind Flay", "Smite" },         -- Q  slot 1: filler, Smite (1) until Mind Flay (talent, row 2 = 20)
      { "Shadow Word: Pain" },                          -- E  slot 2: maintained DoT (4)
      { macro = "MindPull", "Mind Blast" },             -- R  slot 3: Mind Blast on cooldown (10); the macro also picks a target for the pull
      { "Vampiric Embrace" },                           -- T  slot 5: maintained debuff (talent, row 3 = 25)
      { "Shoot" },                                      -- F  slot 4: wand finisher while leveling
      { "Shadow Word: Death" },                         -- G  instant on cooldown between Mind Flay channels (32)
      { "Fade" },                                       -- C  escape: drops threat (8)
      false,                                            -- V  snare: priests have none
      { macro = "PriestShield", "Power Word: Shield" },                         -- 1  pull: shield before every pull (6)
      { "Devouring Plague" },                           -- 2  main AoE: spreads with Devouring Contagion (20)
      { "Silence", "Dispel Magic" },                    -- 3  interrupt (talent, row 4 = 30); Dispel Magic (18) until then
      { "Holy Nova" },                                  -- 4  secondary AoE (Holy talent, row 2 = 20; rare for Shadow)
    },
    [2] = {
      { macro = "PriestFlash", "Flash Heal", "Lesser Heal" },                  -- Shift+Q  self-heal (1 / 20)
      { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" }, -- Shift+E  defensive: race spell (10)
      { macro = "Empower", "Power Infusion", "Inner Focus" }, -- Shift+R  burst
      { "Mind Control" },                               -- Shift+T  spec control (30)
      { "Shackle Undead" },                             -- Shift+F  hard CC (20)
      { "Psychic Scream" },                             -- Shift+G  AoE control (14)
      { racial = true },                                -- Shift+C  racial
      { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" }, -- Shift+V  emergency: race spell (20)
      { "Power Word: Fortitude" },                      -- Shift+1  buff (1)
      { "Inner Fire" },                                 -- Shift+2  buff (12)
      { macro = "ShadowOn", "Shadowform" },                                 -- Shift+3  form (talent, row 6 = 40)
      { "Fear Ward" },                                  -- Shift+4  buff (20)
    },
    -- [3] is the shared Alt bar (item macros, trinkets, Hearthstone), not set here.
    [4] = {
      { "Holy Fire" },                                  -- Ctrl+Q  rare: not in the Shadow rotation (20)
      { "Mana Burn" },                                  -- Ctrl+E  rare (24)
      { "Mind Soothe" },                                -- Ctrl+R (20)
      { "Mind Vision" },                                -- Ctrl+T (22)
      { macro = "PriestRenew", "Renew" },                                      -- Ctrl+F  top-off between pulls (8)
      { "Greater Heal", "Heal", upgrade = true },       -- Ctrl+G  big self-heal out of form (16 / 40)
      { "Abolish Disease", "Cure Disease", upgrade = true }, -- Ctrl+C (14 / 32)
      { "Resurrection" },                               -- Ctrl+V (10)
      { "Divine Spirit" },                              -- Ctrl+1 (30)
      { "Shadow Protection" },                          -- Ctrl+2 (30)
      { "Prayer of Fortitude" },                        -- Ctrl+3 (48)
      { "Levitate" },                                   -- Ctrl+4 (34)
    },
    stances = {
      -- Shadowform: the same rotation on the same keys; Holy Nova (a heal
      -- that would cancel the form) gives way.
      shadowform = {
        offset = 1, label = "Shadowform",
        { macro = "Flay", "Mind Flay", "Smite" },       -- Q  slot 1: Mind Flay
        { "Shadow Word: Pain" },                        -- E  slot 2
        { macro = "MindPull", "Mind Blast" },           -- R  slot 3
        { "Vampiric Embrace" },                         -- T  slot 5
        { "Shoot" },                                    -- F  slot 4
        { "Shadow Word: Death" },                       -- G  reactive
        { "Fade" },                                     -- C  escape
        false,                                          -- V
        { macro = "PriestShield", "Power Word: Shield" },                       -- 1  pull (a shield keeps the form)
        { "Devouring Plague" },                         -- 2  AoE
        { "Silence", "Dispel Magic" },                  -- 3  interrupt
        false,                                          -- 4  (Holy Nova would cancel the form)
      },
    },
  },

  -- Controller (Shadow): keys "<layer> <button>", layer none / LT / RT /
  -- LT+RT, button A X B Y or Up Down Left Right. Page 1 follows the
  -- key-roles table. In Shadowform the Gamepad UI swaps the RT bar for the
  -- stance bar; Apply mirrors RT into it, so buttons stay put.
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { macro = "Flay", "Mind Flay", "Smite" },   -- Q  slot 1
        ["RT X"] = { "Shadow Word: Pain" },                    -- E  slot 2
        ["RT Y"] = { macro = "MindPull", "Mind Blast" },       -- R  slot 3 (and the pull)
        ["RT B"] = { "Shoot" },                                -- F  slot 4: wand
        ["LT A"] = { "Vampiric Embrace" },                     -- T  slot 5
        ["LT X"] = { "Shadow Word: Death" },                   -- G  on cooldown
        ["LT B"] = { "Silence", "Dispel Magic" },              -- 3  interrupt
        ["LT Y"] = { "Devouring Plague" },                     -- 2  AoE
        ["RT Up"] = { macro = "PriestShield", "Power Word: Shield" },                  -- 1  pull: shield first, standing
        ["RT Down"] = { "Holy Nova" },                         -- 4  secondary AoE
        ["RT Left"] = { "Fade" },                              -- C  escape (RT Right, the snare, stays empty)
        ["LT Up"] = { macro = "PriestFlash", "Flash Heal", "Lesser Heal" },           -- Shift+Q  self-heal
        ["LT Right"] = { "Desperate Prayer", "Touch of Weakness", "Hex of Weakness", "Starshards", "Divine Grace", "Confounding Flash" }, -- Shift+E
        ["LT Left"] = { "Mind Control" },                      -- Shift+T
        ["LT Down"] = { "Shackle Undead" },                    -- Shift+F
        ["LT+RT A"] = { "Dark Sacrifice", "Shadowguard", "Elune's Grace", "Feedback", "Contingency Plan" }, -- Shift+V
        ["LT+RT X"] = { "Psychic Scream" },                    -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { macro = "Empower", "Power Infusion", "Inner Focus" }, -- Shift+R
        ["LT+RT Up"] = { "Holy Fire" },                        -- Ctrl+Q
        ["LT+RT Down"] = { "Mana Burn" },                      -- Ctrl+E
        ["LT+RT Left"] = { "Mind Soothe" },                    -- Ctrl+R
        ["LT+RT Right"] = { "Mind Vision" },                   -- Ctrl+T
        ["none Up"] = { "Power Word: Fortitude" },             -- out of combat
        ["none Left"] = { "Inner Fire" },
        ["none Right"] = { macro = "ShadowOn", "Shadowform" },
        ["none Down"] = { macro = "PriestRenew", "Renew" },                           -- top-off between pulls
      },
      -- Page 2: resurrect and buffs; the shared Utility buttons
      -- (Layouts/Shared.lua) add Hearthstone, trinkets, item macros,
      -- fishing, camp, Mount and professions. Spells on no page (Greater
      -- Heal and Prayer of Healing for Shadow, Mind Control and Mana Burn for
      -- healers...)
      -- go to page 3.
      {
        title = "Utility",
        ["RT A"] = { "Resurrection" },
        ["RT X"] = { "Levitate" },
        -- RT B stays free: the healers' disease cure is on page 1 LT B, so a
        -- page 2 home would be a second one; Shadow's cure goes to page 3.
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
        ["LT+RT Up"] = { overflow = true },
        ["LT+RT Down"] = { overflow = true }, ["LT+RT Left"] = { overflow = true },
        ["LT+RT Right"] = { overflow = true },
      },
    },
    paddles = {},
  },
})
