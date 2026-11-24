-- Warlock layouts. Data contract: dev/layout-format.md; key roles shared by
-- every class: dev/key-roles.md (the BM hunter is the reference). Keep every
-- value a literal (no variables, no function calls): dev.ps1 rules reads
-- this file without running Lua.
--
-- One layout serves all three specs: fallback chains pick the build's spell
-- ({ "Wrack", "Incinerate", "Soul Fire" } takes the first one you know), so
-- no spec needs an override. Affliction is the leveling spec (no respec
-- needed), Demonology is as strong, Destruction is weakest solo (research
-- 2026-11: Icy Veins, Mobalytics, Warcraft Tavern WoW Forever warlock
-- leveling). Forever names: Curse of Agony and Curse of Doom are Banes
-- (one Bane and one Curse per target), the Succubus/Incubus is the Sayaad.
-- Warlocks have no stance paging. Pet abilities sit on the pet bar keys
-- (Z/X, Shift+Z/X) and pet Attack/Follow on the mouse (Keybinds), so the
-- layout names no pet ability or pet command; the PetSpecial macro casts
-- the current demon's control spell (Spell Lock is the interrupt) from a
-- normal key.
--
-- Key roles (dev/key-roles.md) and how the warlock fills them:
--   Q main attack  Shadow Bolt            E DoT          Corruption
--   R big hitter   Immolate (cast + burn; Conflagrate and Incinerate feed on it)
--   T signature    the build's nuke: Wrack / Incinerate / Soul Fire
--   F secondary    Drain Life (the channel you drain-tank with)
--   G reactive     Drain Soul (finish a dying target for a shard)
--   C escape       Death Coil (horror + heal)
--   V snare        none: Life Tap, the spell you press most after the nukes
--   1 opener       Bane of Agony          2 main AoE     Hellfire
--   3 interrupt    PetSpecial (Spell Lock) 4 ground AoE  Rain of Fire
-- Shift: Q pet heal (Health Funnel, like the hunter's Mend Pet; Drain Life
-- on F heals you), E build cooldown, R build burst, T control, F Fear, G
-- Howl, C racial, V Shadow Ward, 1-4 armor, stones and breath. Ctrl: Q the
-- build's second spell, E R T curse, Searing Pain and Bane of Doom, F G the
-- utility curses, C V tools, 1-4 the four summons.
local _, ns = ...

ns.Layout.Register("WARLOCK", {
  specs = {
    { key = "affliction", name = "Affliction", tab = 1, default = true },
    { key = "demonology", name = "Demonology", tab = 2 },
    { key = "destruction", name = "Destruction", tab = 3 },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  keyboard = {
    -- Bar 1: Q E R T the casts every pull uses, F G C V drains, escape and
    -- mana, 1 2 3 4 pull, AoE and interrupt (spell levels in brackets).
    [1] = {
      { "Shadow Bolt" },                                      -- Q  main attack (1)
      { "Corruption" },                                       -- E  DoT you keep up (4)
      { "Immolate" },                                         -- R  big hitter: cast nuke that leaves a burn (1)
      { macro = "Wrack", "Wrack", "Incinerate", "Soul Fire" }, -- T  build nuke: Aff 31 / Destro 31 / Soul Fire (48)
      { macro = "DrainLife", "Drain Life" },                  -- F  secondary: drain-tank channel, no clipping (14)
      { macro = "DrainSoul", "Drain Soul" },                  -- G  reactive: finish a dying target for a shard (10)
      { "Death Coil" },                                       -- C  escape: horrors the attacker and heals you (42)
      { "Life Tap" },                                         -- V  no snare: Life Tap, pressed all the time (6)
      { "Bane of Agony" },                                    -- 1  opener: instant pull with the long DoT (8)
      { "Hellfire" },                                         -- 2  main AoE around you (30)
      { macro = "PetSpecial" },                               -- 3  interrupt: Spell Lock / Seduction / Sacrifice (macro only)
      { "Rain of Fire" },                                     -- 4  ground AoE (20)
    },
    -- Bar 2 (Shift): Q pet heal, E build cooldown, R build burst, T
    -- control, F hard CC, G AoE control, C racial, V defensive, 1-4 armor,
    -- stones and breath.
    [2] = {
      { "Health Funnel" },                                    -- Shift+Q  pet heal (12): the warlock's Mend Pet
      { "Amplify Curse", "Fel Domination", "Bane of Havoc" }, -- Shift+E  build cooldown: Aff / Demo / Destro talent
      { "Demonic Sacrifice", "Shadowburn", "Inferno" },       -- Shift+R  burst: Demo / Destro talent, else Inferno (50)
      { "Enslave Demon" },                                    -- Shift+T  control: take over a demon (30)
      { "Fear" },                                             -- Shift+F  hard CC (8)
      { "Howl of Terror" },                                   -- Shift+G  AoE control (40)
      { racial = true },                                      -- Shift+C  racial
      { "Shadow Ward" },                                      -- Shift+V  emergency: absorbs Shadow damage (32)
      { "Demon Armor", "Demon Skin", upgrade = true },        -- Shift+1  armor (1 / 20)
      { "Create Healthstone" },                               -- Shift+2  create (10)
      { "Create Soulstone" },                                 -- Shift+3  create (18)
      { "Unending Breath" },                                  -- Shift+4  buff (16)
    },
    -- [3] is the Alt bar (trinkets, Fish, Bait, Hearthstone), not set here.
    -- Bar 4 (Ctrl): Q E R T secondary spells and debuffs, F G the utility
    -- curses, C V demon tools, 1 2 3 4 the summons in level order.
    [4] = {
      { "Siphon Life", "Conflagrate", "Soul Link" },          -- Ctrl+Q  build's second spell: Aff DoT / Destro hit / Demo link
      { "Curse of the Elements" },                            -- Ctrl+E  secondary debuff: the group curse (40)
      { "Searing Pain" },                                     -- Ctrl+R  secondary attack (18; Demonology: Demonic Brand)
      { "Bane of Doom" },                                     -- Ctrl+T  the long Bane for elites (60)
      { "Curse of Weakness" },                                -- Ctrl+F  utility curse vs melee (4)
      { "Curse of Tongues" },                                 -- Ctrl+G  utility curse vs casters (26)
      { "Eye of Kilrogg" },                                   -- Ctrl+C  scout (22)
      { "Drain Mana" },                                       -- Ctrl+V  mana from casters (24)
      { "Summon Imp" },                                       -- Ctrl+1  summon (1)
      { "Summon Voidwalker" },                                -- Ctrl+2  summon (10)
      { "Summon Sayaad", "Summon Succubus" },                 -- Ctrl+3  summon (20)
      { "Summon Felhunter" },                                 -- Ctrl+4  summon (30)
    },
  },

  -- Controller: keys "<layer> <button>", layer none / LT / RT / LT+RT,
  -- button A X B Y or Up Down Left Right (D-pad). The Top bar's face buttons
  -- are fixed.
  controller = {
    pages = {
      -- Page 1 mirrors the keyboard roles (dev/key-roles.md): RT = plain
      -- Q E 3 2 1 R T 4, LT = plain F G V C and Shift Q F T E, LT+RT =
      -- Shift V G, racial, Shift R and Ctrl Q E R T; no trigger = armor and
      -- the curses you pick per target.
      {
        title = "Combat",
        ["RT A"] = { "Shadow Bolt" },                                      -- Q
        ["RT X"] = { "Corruption" },                                       -- E
        ["RT B"] = { macro = "PetSpecial" },                               -- 3
        ["RT Y"] = { "Hellfire" },                                         -- 2
        ["RT Up"] = { "Bane of Agony" },                                   -- 1
        ["RT Right"] = { "Immolate" },                                     -- R
        ["RT Left"] = { macro = "Wrack", "Wrack", "Incinerate", "Soul Fire" }, -- T
        ["RT Down"] = { "Rain of Fire" },                                  -- 4 (cursor confirm)
        ["LT A"] = { macro = "DrainLife", "Drain Life" },                  -- F
        ["LT X"] = { macro = "DrainSoul", "Drain Soul" },                  -- G
        ["LT B"] = { "Life Tap" },                                         -- V
        ["LT Y"] = { "Death Coil" },                                       -- C
        ["LT Up"] = { "Health Funnel" },                                   -- Shift+Q
        ["LT Down"] = { "Fear" },                                          -- Shift+F
        ["LT Left"] = { "Enslave Demon" },                                 -- Shift+T
        ["LT Right"] = { "Amplify Curse", "Fel Domination", "Bane of Havoc" }, -- Shift+E
        ["none Up"] = { "Demon Armor", "Demon Skin", upgrade = true },     -- armor
        ["none Left"] = { "Curse of Weakness" },                           -- utility curse
        ["none Right"] = { "Curse of Tongues" },                           -- utility curse
        ["none Down"] = { "Drain Mana" },
        ["LT+RT A"] = { "Shadow Ward" },                                   -- Shift+V
        ["LT+RT X"] = { "Howl of Terror" },                                -- Shift+G
        ["LT+RT B"] = { racial = true },
        ["LT+RT Y"] = { "Demonic Sacrifice", "Shadowburn", "Inferno" },    -- Shift+R
        ["LT+RT Up"] = { "Siphon Life", "Conflagrate", "Soul Link" },      -- Ctrl+Q
        ["LT+RT Down"] = { "Curse of the Elements" },                      -- Ctrl+E
        ["LT+RT Left"] = { "Searing Pain" },                               -- Ctrl+R
        ["LT+RT Right"] = { "Bane of Doom" },                              -- Ctrl+T
      },
      -- Page 2: stones and travel; the shared Utility buttons
      -- (Layouts/Shared.lua) add Hearthstone, trinkets, fishing, camp, Mount
      -- and professions.
      {
        title = "Utility",
        ["RT A"] = { "Create Healthstone" },
        ["RT X"] = { "Create Soulstone" },
        ["RT B"] = { "Unending Breath" },
        ["RT Y"] = { "Eye of Kilrogg" },
        ["RT Down"] = { overflow = true },
      },
      -- Page 3: summons, pet autocast, Steam Deck helpers and the catch-all.
      {
        title = "Demons & Extras",
        ["RT A"] = { "Summon Imp" },
        ["RT X"] = { "Summon Voidwalker" },
        ["RT B"] = { "Summon Sayaad", "Summon Succubus" },
        ["RT Y"] = { "Summon Felhunter" },
        ["RT Up"] = { overflow = true },
        ["RT Down"] = { overflow = true },
        ["RT Left"] = { overflow = true },
        ["RT Right"] = { overflow = true },
        -- LT: every ability your demon knows that can autocast, one on/off
        -- toggle each (install the Auto macros on the Macros page).
        ["LT A"] = { petauto = true }, ["LT X"] = { petauto = true },
        ["LT B"] = { petauto = true }, ["LT Y"] = { petauto = true },
        ["LT Up"] = { petauto = true }, ["LT Down"] = { petauto = true },
        ["LT Left"] = { petauto = true }, ["LT Right"] = { petauto = true },
        ["none Up"] = { macro = "Reload" },
        ["none Down"] = { macro = "Follow" },
        ["none Left"] = { macro = "Focus" },
        ["none Right"] = { macro = "Assist" },
        ["LT+RT A"] = { macro = "Skull" },
        ["LT+RT X"] = { overflow = true }, ["LT+RT B"] = { overflow = true },
        ["LT+RT Y"] = { overflow = true }, ["LT+RT Up"] = { overflow = true },
        ["LT+RT Down"] = { overflow = true }, ["LT+RT Left"] = { overflow = true },
        ["LT+RT Right"] = { overflow = true },
      },
    },
    paddles = {},
  },
})
