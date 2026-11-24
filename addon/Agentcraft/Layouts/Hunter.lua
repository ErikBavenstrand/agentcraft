-- Hunter layouts. Data contract: dev/layout-format.md. Keep every value a
-- literal (no variables, no function calls): dev.ps1 rules reads this file
-- without running Lua.
--
-- One layout serves all three specs: its fallback chains pick the build's
-- spell ({ "Bestial Wrath", "Deterrence", "Trueshot Aura" } takes the first
-- one you know). Beast Mastery is the leveling spec and the owner's tuned,
-- in-game-tested layout (research 2026-11: Icy Veins, Mobalytics).
--
-- Talents per build (WoW Forever; warcraft.wiki.gg Hunter abilities (Forever),
-- Icy Veins, Warcraft Tavern): BM Summon Hawk (shares Arcane Shot's 6 s
-- cooldown), Bestial Wrath, Intimidation; MM Trueshot Aura, Scatter Shot,
-- Sniper Shot (31 points, level 40; 4 s cast, 4 s cooldown), Lone Wolf (left
-- to the side bars: it gives up the pet); Survival Deterrence, Counterattack,
-- Strider Kick (level 30: a melee hit, then run out), Wyvern Sting. Aimed
-- Shot is a level 20 trainer spell for every build. All traps share one 30 s
-- cooldown, so one damage-trap key serves single target and AoE.
--
-- Marksmanship needs no override: the chains give it Sniper Shot on T,
-- Trueshot Aura on Shift+E and Scatter Shot on Shift+T, and the rest of its
-- priority (Mark, Aimed, Serpent, Arcane, trap in melee; Multi-Shot, trap,
-- Volley for AoE) is already keyed. Survival fights in melee with Aspect of
-- the Beast and at range with Hawk, so its override moves Beast to Shift+2
-- (Monkey to Ctrl+1) and gives Wyvern Sting Ctrl+T.
local _, ns = ...

ns.Layout.Register("HUNTER", {
  specs = {
    { key = "bm", name = "Beast Mastery", tab = 1, default = true },
    { key = "mm", name = "Marksmanship", tab = 2 },
    { key = "sv", name = "Survival", tab = 3, keyboard = {
      -- Bar 2 as shared, with Aspect of the Beast (melee) on Shift+2.
      [2] = {
        { macro = "PetCare", "Mend Pet" },            -- Shift+Q
        { "Bestial Wrath", "Deterrence", "Trueshot Aura" },   -- Shift+E  Deterrence
        { macro = "Burst", "Rapid Fire" },            -- Shift+R  (Rapid Fire also speeds melee)
        { "Intimidation", "Counterattack", "Scatter Shot" },  -- Shift+T  Counterattack
        { "Freezing Trap" },                          -- Shift+F
        { "Frost Trap" },                             -- Shift+G
        { racial = true },                            -- Shift+C
        { macro = "FD", "Feign Death" },              -- Shift+V
        { "Aspect of the Hawk" },                     -- Shift+1  at range
        { "Aspect of the Beast" },                    -- Shift+2  in melee
        { "Aspect of the Cheetah" },                  -- Shift+3
        { "Aspect of the Pack" },                     -- Shift+4
      },
      -- Bar 4 as shared, with Monkey on Ctrl+1 and Wyvern Sting on Ctrl+T.
      [4] = {
        { "Viper Sting" },                            -- Ctrl+Q
        { "Scorpid Sting" },                          -- Ctrl+E
        { "Tranquilizing Shot" },                     -- Ctrl+R
        { "Wyvern Sting", "Distracting Shot" },       -- Ctrl+T  (Distracting Shot until the talent)
        { "Volley" },                                 -- Ctrl+F
        { "Flare" },                                  -- Ctrl+G
        { "Scare Beast" },                            -- Ctrl+C
        { "Eyes of the Beast" },                      -- Ctrl+V
        { "Aspect of the Monkey" },                   -- Ctrl+1
        { "Aspect of the Wild" },                     -- Ctrl+2
        { "Feed Pet" },                               -- Ctrl+3
        { "Beast Lore" },                             -- Ctrl+4
      },
    } },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  keyboard = {
    -- Each row of four keys is one family, so you learn rows, not single keys.
    -- Bar 1: Q E R T rotation, F G C V melee, 1 2 3 4 pull and shots.
    [1] = {
      { macro = "Arcane", "Arcane Shot" },          -- Q  (also starts Auto Shot)
      { "Serpent Sting" },                            -- E
      { "Aimed Shot" },                             -- R
      { "Summon Hawk", "Sniper Shot", "Strider Kick" }, -- T  build signature: BM / MM / SV
      { macro = "Melee", "Raptor Strike" },         -- F  (Counterattack / Mongoose Bite / Raptor)
      { "Mongoose Bite" },                          -- G
      { "Disengage" },                              -- C
      { "Wing Clip" },                              -- V
      { macro = "Opener", "Hunter's Mark" },        -- 1  opener (target, Mark, Auto Shot; pet stays)
      { "Multi-Shot" },                             -- 2
      { "Concussive Shot" },                        -- 3
      { "Explosive Trap", "Immolation Trap", upgrade = true }, -- 4  damage trap
    },
    -- Bar 2 (Shift): Q E R T cooldowns and pet, F G C V crowd control and
    -- escape, 1 2 3 4 aspects. Situational spells go to the side bars.
    [2] = {
      { macro = "PetCare", "Mend Pet" },            -- Shift+Q  (call / revive / mend)
      { "Bestial Wrath", "Deterrence", "Trueshot Aura" },   -- Shift+E  build cooldown
      { macro = "Burst", "Rapid Fire" },            -- Shift+R  (every cooldown at once)
      { "Intimidation", "Counterattack", "Scatter Shot" },  -- Shift+T  build control
      { "Freezing Trap" },                          -- Shift+F
      { "Frost Trap" },                             -- Shift+G
      { racial = true },                            -- Shift+C
      { macro = "FD", "Feign Death" },              -- Shift+V
      { "Aspect of the Hawk" },                     -- Shift+1
      { "Aspect of the Monkey" },                   -- Shift+2
      { "Aspect of the Cheetah" },                  -- Shift+3
      { "Aspect of the Pack" },                     -- Shift+4
    },
    -- [3] is the Alt bar (Fish and Bait macros, trinkets and Hearthstone,
    -- ActionBars.utility), not set here.
    -- Bar 4 (Ctrl): Q E R T stings and utility shots, F G C V area and beast
    -- control, 1 2 3 4 more aspects and pet care.
    [4] = {
      { "Viper Sting" },                            -- Ctrl+Q
      { "Scorpid Sting" },                          -- Ctrl+E
      { "Tranquilizing Shot" },                     -- Ctrl+R
      { "Distracting Shot" },                       -- Ctrl+T
      { "Volley" },                                 -- Ctrl+F
      { "Flare" },                                  -- Ctrl+G
      { "Scare Beast" },                            -- Ctrl+C
      { "Eyes of the Beast" },                      -- Ctrl+V
      { "Aspect of the Beast" },                    -- Ctrl+1
      { "Aspect of the Wild" },                     -- Ctrl+2
      { "Feed Pet" },                               -- Ctrl+3
      { "Beast Lore" },                             -- Ctrl+4
    },
  },

  -- Controller: keys "<layer> <button>", layer none / LT / RT / LT+RT,
  -- button A X B Y or Up Down Left Right (D-pad). The Top bar's face buttons
  -- are fixed.
  controller = {
    pages = {
      -- Page 1: everything you press in a normal session.
      --   Face buttons (with a trigger) leave your left thumb on the stick, so
      --   they hold what you press while moving: RT = ranged, LT = melee.
      --   The D-pad takes your left thumb off the stick, so you stop moving:
      --   it holds stand-still casts (Mark, Aimed Shot, traps) and
      --   out-of-combat basics. LT+RT is the hardest chord: rare spells.
      {
        title = "Combat",
        ["RT A"] = { macro = "Arcane", "Arcane Shot" },
        ["RT X"] = { "Serpent Sting" },
        ["RT B"] = { "Concussive Shot" },
        ["RT Y"] = { "Multi-Shot" },
        ["RT Up"] = { macro = "Opener", "Hunter's Mark" },
        ["RT Right"] = { "Aimed Shot" },
        ["RT Left"] = { "Summon Hawk", "Sniper Shot", "Strider Kick" },
        ["RT Down"] = { "Explosive Trap", "Immolation Trap", upgrade = true },
        ["LT A"] = { macro = "Melee", "Raptor Strike" },
        ["LT X"] = { "Mongoose Bite" },
        ["LT B"] = { "Wing Clip" },
        ["LT Y"] = { "Disengage" },
        ["LT Up"] = { macro = "PetCare", "Mend Pet" },
        ["LT Down"] = { "Freezing Trap" },
        ["LT Left"] = { "Intimidation", "Counterattack", "Scatter Shot" },
        ["LT Right"] = { "Bestial Wrath", "Deterrence", "Trueshot Aura" },
        -- No trigger: radials (right stick picks) and out-of-combat basics.
        ["none Up"] = { flyout = 253, "Aspect of the Hawk" },        -- aspects
        ["none Left"] = { flyout = "Tracking", "Track Beasts" },      -- tracking
        ["none Right"] = { "Feed Pet" },
        -- none Down stays free (it held food; no consumables on bars).
        ["LT+RT A"] = { macro = "FD", "Feign Death" },
        ["LT+RT X"] = { "Frost Trap" },
        ["LT+RT B"] = { racial = true },   -- War Stomp etc.; also on back button LT+R5
        ["LT+RT Y"] = { macro = "Burst", "Rapid Fire" },
        ["LT+RT Up"] = { "Viper Sting" },
        ["LT+RT Down"] = { "Volley" },
        ["LT+RT Left"] = { "Flare" },
        ["LT+RT Right"] = { "Wyvern Sting", "Tranquilizing Shot" },
      },
      -- Page 2: pet care on RT; the shared Utility buttons (Layouts/Shared.lua)
      -- add Hearthstone, trinkets, fishing, camp, Mount and professions.
      {
        title = "Utility",
        ["RT A"] = { "Revive Pet" },
        ["RT X"] = { "Call Pet" },
        ["RT B"] = { "Dismiss Pet" },
        ["RT Y"] = { "Beast Lore" },
        ["RT Down"] = { "Beast Training" },
        ["RT Left"] = { "Eyes of the Beast" },
        ["RT Right"] = { "Tame Beast" },
        -- The shared buttons (Layouts/Shared.lua) fill the rest of this page:
        -- Hearthstone, trinkets, Fish, Bait, camp, Mount and professions.
        -- LT X B Y Left Right stay free.
      },
      -- Page 3: pet autocast, Steam Deck helpers and the catch-all.
      {
        title = "Pet & Extras",
        -- RT: every ability your pet knows that can autocast, one on/off
        -- toggle each, in pet bar order (spinning border = autocast on).
        ["RT A"] = { petauto = true }, ["RT X"] = { petauto = true },
        ["RT B"] = { petauto = true }, ["RT Y"] = { petauto = true },
        ["RT Up"] = { petauto = true }, ["RT Down"] = { petauto = true },
        ["RT Left"] = { petauto = true }, ["RT Right"] = { petauto = true },
        -- Only what the game menu, vendor window and Steam don't already do.
        ["none Up"] = { macro = "Reload" },
        ["none Down"] = { macro = "Follow" },
        ["none Left"] = { macro = "Focus" },
        ["none Right"] = { macro = "Assist" },
        ["LT+RT A"] = { macro = "Skull" },
        -- Everything else you know, alphabetically: extra shots, tracking...
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
    -- Steam Deck back buttons (F13-F16), plain and with LT held: keys
    -- L4 L5 R4 R5 and LT+L4 ... LT+R5. A back button may repeat a page-1
    -- spell (a shortcut, not a second home). Left unbound for now by the
    -- owner's choice (2026-11); Apply unbinds any key without a home here.
    paddles = {},
  },
})
