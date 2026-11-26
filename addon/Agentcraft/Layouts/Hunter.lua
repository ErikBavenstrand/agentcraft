-- Hunter layouts. Data contract: dev/layout-format.md; slot rules:
-- dev/key-roles.md. Keep every value a literal (no variables, no function
-- calls): dev.ps1 rules reads this file without running Lua.
--
-- Rotations (WoW Forever, checked 2026-11-26 against Wowhead's Forever
-- guides, which win any disagreement):
--   wowhead.com/forever/guide/classes/hunter/<spec>/rotation-cooldowns-pve-dps
--   wowhead.com/forever/guide/classes/hunter/<spec>/dps-leveling-tips
--   (<spec> = beast-mastery, marksmanship, survival). Tooltips (Wowhead
--   Forever): Summon Hawk shares Arcane Shot's 6 s cooldown; Strider Kick is
--   an 8 s melee kick; Expose Prey is passive (attacks on a Marked target can
--   enable Mongoose Bite). Trainer levels from the leveling guides: Raptor 1,
--   Serpent 4, Arcane and Mark 6, Concussive 8, Wing Clip and Mend Pet 12,
--   Immolation Trap and Mongoose Bite 16, Multi-Shot 18, Aimed Shot and
--   Freezing Trap 20, Rapid Fire 26, Frost Trap 28, Feign Death 30,
--   Explosive Trap 34, Volley 40. Talent rows (dev/forever-talents.md, row
--   r = level 10 + 5r, earlier with the Legacy perk Talented): BM Summon
--   Hawk row 3 = 25, Intimidation row 4 = 30, Bestial Wrath row 6 = 40; MM
--   Trueshot Aura row 3 = 25, Scatter Shot row 4 = 30, Sniper Shot row 6 =
--   40; Survival Deterrence row 2 = 20, Counterattack row 3 = 25, Strider
--   Kick row 4 = 30, Lacerating Strikes row 6 (passive: no button). Wyvern
--   Sting is not a Forever talent, so no layout names it.
--   Every spec: Hunter's Mark always up (the Opener on 1), Aspect of the Hawk.
--   Wowhead names no interrupt: Intimidation is a "non-DPS cooldown" (stun),
--   Scatter Shot isn't named, so the build's cast-stopper
--   sits on Shift+T (spec control) and key 3 holds the damage trap.
-- Beast Mastery (Wowhead: the leveling spec): Mark > Serpent Sting > Summon
--   Hawk > Arcane Shot every third press instead of Hawk (shared cooldown) >
--   Aimed Shot. AoE: Multi-Shot (4 or fewer) > run in for Explosive Trap >
--   Volley (40) for its full duration. Cooldowns: Rapid Fire and Bestial
--   Wrath on cooldown; Intimidation to stun. Situational: Freezing / Frost
--   Trap, Viper Sting, Tranquilizing Shot.
--   Arcane stays on Q (not Hawk): Q is the only Arcane/Hawk key a hunter has
--   before the Summon Hawk talent (row 3 = 25), and the Arcane macro
--   restarts Auto Shot.
-- Marksmanship: Mark > Serpent Sting > Arcane Shot > Aimed Shot > Sniper Shot
--   (talent, row 6 = 40; Wowhead: skip it until max level). Trueshot Aura
--   (row 3 = 25) kept up. AoE and
--   situational as BM; cooldown Rapid Fire.
-- Survival (Wowhead: play BM until 32): full melee Mark > Raptor Strike
--   queued > Serpent Sting (run out with the Strider Kick speed) > Mongoose
--   Bite > Immolation Trap > Strider Kick > Summon Hawk; weaving melee Raptor
--   > Mongoose > Strider Kick > Immolation Trap, ranged Serpent > Arcane >
--   Multi-Shot. No Aimed Shot. AoE and cooldown as MM. Counterattack after a
--   parry is not in Wowhead's rotation (kept from warcraft.wiki.gg "Hunter
--   abilities (Forever)").
--
-- BM and MM share one layout through fallback chains. Survival has its own
-- Bar 1 (Strider Kick on R instead of Aimed Shot, Immolation Trap on 3),
-- Shift, Ctrl and controller page 1.
local _, ns = ...

ns.Layout.Register("HUNTER", {
  specs = {
    { key = "bm", name = "Beast Mastery", tab = 1, default = true },
    { key = "mm", name = "Marksmanship", tab = 2 },
    { key = "sv", name = "Survival", tab = 3, keyboard = {
      -- Bar 1: Wowhead's Survival kit. Aimed Shot isn't in it, so R takes
      -- Strider Kick; Immolation Trap (single-target melee rotation) takes 3.
      [1] = {
        { macro = "Arcane", "Arcane Shot" },          -- Q  rotation slot 1: ranged weave shot (also starts Auto Shot)
        { "Serpent Sting" },                          -- E  rotation slot 2: the maintained DoT
        { "Strider Kick" },                           -- R  rotation slot 3: melee hit on its 8 s cooldown (talent, row 4 = 30)
        { "Summon Hawk" },                            -- T  rotation slot 5: full melee, BM talent row 3 = 25 (shares Arcane's cooldown)
        { macro = "Melee", "Raptor Strike" },         -- F  rotation slot 4: Raptor Strike always queued
        { "Mongoose Bite" },                          -- G  proc: after a dodge or Expose Prey
        { "Wing Clip" },                              -- C  escape: clip, then walk out of melee
        { "Explosive Trap" },                         -- V  AoE: run in and lay it (34; Wowhead's Survival AoE, a Bar 1 key so packs need no Shift)
        { macro = "Opener", "Hunter's Mark" },        -- 1  opener: Mark always up
        { "Multi-Shot" },                             -- 2  main AoE (4 or fewer targets)
        { "Immolation Trap" },                        -- 3  melee rotation trap (no interrupt in the kit)
        { "Volley" },                                 -- 4  ground AoE (40), full duration
      },
      -- Bar 2: Counterattack on Shift+T, Explosive Trap (run-in AoE; Bar 1's
      -- 3 holds Immolation) on Shift+G, Aspect of the Beast on Shift+2.
      [2] = {
        { macro = "PetCare", "Mend Pet" },            -- Shift+Q  sustain: pet heal / call / revive
        { "Bestial Wrath", "Deterrence", "Trueshot Aura" },   -- Shift+E  build cooldown: Deterrence
        { macro = "Burst", "Rapid Fire" },            -- Shift+R  burst (Rapid Fire also speeds melee)
        { "Counterattack" },                          -- Shift+T  spec control: after a parry, roots (talent, row 3 = 25)
        { "Freezing Trap" },                          -- Shift+F  hard CC
        { "Concussive Shot" },                        -- Shift+G  snare: rare for a melee spec
        { racial = true },                            -- Shift+C  racial
        { macro = "FD", "Feign Death" },              -- Shift+V  emergency
        { "Aspect of the Hawk" },                     -- Shift+1  aspect row: at range
        { "Aspect of the Beast" },                    -- Shift+2  aspect row: in melee
        { "Aspect of the Cheetah" },                  -- Shift+3  aspect row: travel
        { "Aspect of the Pack" },                     -- Shift+4  aspect row: group travel
      },
      -- Bar 4: rare stings and utility; Frost Trap, Aimed Shot (not in
      -- Wowhead's Survival rotation) and the cast-stopper move here.
      [4] = {
        { "Viper Sting" },                            -- Ctrl+Q  rare: mana drain
        { "Scorpid Sting" },                          -- Ctrl+E  rare sting
        { "Tranquilizing Shot" },                     -- Ctrl+R  rare: enrage dispel
        { "Disengage" },                              -- Ctrl+T  rare: threat drop
        { "Frost Trap" },                             -- Ctrl+F  situational: slow adds
        { "Aimed Shot" },                             -- Ctrl+G  not in the Survival rotation
        { "Scare Beast" },                            -- Ctrl+C  utility
        { "Intimidation", "Scatter Shot" },           -- Ctrl+V  the build's stun / cast-stopper (rows 4 = 30)
        { "Aspect of the Monkey" },                   -- Ctrl+1  create/buff row
        { "Aspect of the Wild" },                     -- Ctrl+2  create/buff row
        { "Feed Pet" },                               -- Ctrl+3  pet care
        { "Beast Lore" },                             -- Ctrl+4  pet care
      },
    }, controller = { pages = { [1] = {
      title = "Combat",
      ["RT A"] = { macro = "Arcane", "Arcane Shot" },   -- rotation slot 1 (Q)
      ["RT X"] = { "Serpent Sting" },                   -- rotation slot 2 (E)
      ["RT Y"] = { "Strider Kick" },                    -- rotation slot 3 (R)
      ["RT B"] = { macro = "Melee", "Raptor Strike" },  -- rotation slot 4 (F): Raptor queued
      ["LT A"] = { "Summon Hawk" },                     -- rotation slot 5 (T)
      ["LT X"] = { "Mongoose Bite" },                   -- proc (G)
      ["LT B"] = { "Immolation Trap" },                 -- melee rotation trap (3)
      ["LT Y"] = { "Multi-Shot" },                      -- main AoE (2)
      ["RT Up"] = { macro = "Opener", "Hunter's Mark" }, -- opener (1), before the pull
      ["RT Down"] = { "Volley" },                       -- ground AoE (4), standing
      ["RT Left"] = { "Wing Clip" },                    -- escape (C)
      ["RT Right"] = { "Explosive Trap" },              -- AoE trap (V): page 1, no page switch
      ["LT Up"] = { macro = "PetCare", "Mend Pet" },    -- sustain (Shift+Q)
      ["LT Right"] = { "Bestial Wrath", "Deterrence", "Trueshot Aura" }, -- build cooldown (Shift+E)
      ["LT Left"] = { "Counterattack" },                -- spec control (Shift+T)
      ["LT Down"] = { "Freezing Trap" },                -- hard CC (Shift+F), laid before the pull
      ["LT+RT A"] = { macro = "FD", "Feign Death" },    -- emergency (Shift+V)
      ["LT+RT X"] = { "Concussive Shot" },              -- snare (Shift+G)
      ["LT+RT B"] = { racial = true },                  -- racial (Shift+C)
      ["LT+RT Y"] = { macro = "Burst", "Rapid Fire" },  -- burst (Shift+R)
      ["LT+RT Up"] = { "Viper Sting" },                 -- rare (Ctrl+Q)
      ["LT+RT Down"] = { "Scorpid Sting" },             -- rare (Ctrl+E)
      ["LT+RT Left"] = { "Tranquilizing Shot" },        -- rare (Ctrl+R)
      ["LT+RT Right"] = { "Disengage" },                -- rare (Ctrl+T)
      ["none Up"] = { flyout = 253, "Aspect of the Hawk" },        -- aspects
      ["none Left"] = { flyout = "Tracking", "Track Beasts" },      -- tracking
      ["none Right"] = { "Feed Pet" },
      -- Frost Trap, Aimed Shot, Scare Beast and the cast-stopper go to the
      -- page 3 catch-all.
    } } } },
  },

  -- Keyboard: index 1-12 = Q E R T F G C V 1 2 3 4. Bar 1 plain, 2 Shift, 4 Ctrl.
  keyboard = {
    -- Bar 1: the rotation in press-frequency order (key-roles.md slots).
    [1] = {
      { macro = "Arcane", "Arcane Shot" },          -- Q  rotation slot 1: on cooldown (MM), shares Hawk's cooldown (BM); starts Auto Shot
      { "Serpent Sting" },                          -- E  rotation slot 2: the maintained DoT
      { "Aimed Shot" },                             -- R  rotation slot 3: cast nuke on cooldown (20)
      { "Summon Hawk", "Sniper Shot" },             -- T  rotation slot 5: BM Summon Hawk (2 of 3 presses of the shared cooldown) / MM Sniper Shot
      { macro = "Melee", "Raptor Strike" },         -- F  rotation slot 4: mob in melee (Counterattack / Mongoose / Raptor)
      { "Mongoose Bite" },                          -- G  reactive: after a dodge
      { "Wing Clip" },                              -- C  escape: clip, then walk out of melee (Wowhead: kiting)
      { "Concussive Shot" },                        -- V  snare: kite (Wowhead: kiting)
      { macro = "Opener", "Hunter's Mark" },        -- 1  opener: Mark always up (target, Mark, Auto Shot; pet stays)
      { "Multi-Shot" },                             -- 2  main AoE (4 or fewer targets)
      { "Explosive Trap", "Immolation Trap", upgrade = true }, -- 3  AoE: run in for the damage trap (no interrupt in the kit)
      { "Volley" },                                 -- 4  ground AoE (40), full duration
    },
    -- Bar 2 (Shift): sustain, cooldowns, CC and emergency; 1-4 the aspects.
    [2] = {
      { macro = "PetCare", "Mend Pet" },            -- Shift+Q  sustain: pet heal / call / revive
      { "Bestial Wrath", "Deterrence", "Trueshot Aura" },   -- Shift+E  build cooldown (BM Bestial Wrath row 6 = 40; SV Deterrence row 2 = 20; MM aura row 3 = 25)
      { macro = "Burst", "Rapid Fire" },            -- Shift+R  burst (every cooldown at once)
      { "Intimidation", "Scatter Shot" },           -- Shift+T  spec control: the build's stun / cast-stopper (rows 4 = 30)
      { "Freezing Trap" },                          -- Shift+F  hard CC
      { "Frost Trap" },                             -- Shift+G  AoE control
      { racial = true },                            -- Shift+C  racial
      { macro = "FD", "Feign Death" },              -- Shift+V  emergency
      { "Aspect of the Hawk" },                     -- Shift+1  aspect row: fighting
      { "Aspect of the Monkey" },                   -- Shift+2  aspect row: before Hawk / dodge
      { "Aspect of the Cheetah" },                  -- Shift+3  aspect row: travel
      { "Aspect of the Pack" },                     -- Shift+4  aspect row: group travel
    },
    -- [3] is the Alt bar (ActionBars.utility), not set here.
    -- Bar 4 (Ctrl): rare stings and utility, then aspects and pet care.
    [4] = {
      { "Viper Sting" },                            -- Ctrl+Q  rare: mana drain
      { "Scorpid Sting" },                          -- Ctrl+E  rare sting
      { "Tranquilizing Shot" },                     -- Ctrl+R  rare: enrage dispel
      { "Disengage" },                              -- Ctrl+T  rare: threat drop
      { "Scare Beast" },                            -- Ctrl+F  rare: fear a beast
      { "Flare" },                                  -- Ctrl+G  rare utility
      { "Distracting Shot" },                       -- Ctrl+C  utility: pull a mob off someone
      { "Eyes of the Beast" },                      -- Ctrl+V  utility
      { "Aspect of the Beast" },                    -- Ctrl+1  create/buff row
      { "Aspect of the Wild" },                     -- Ctrl+2  create/buff row
      { "Feed Pet" },                               -- Ctrl+3  pet care
      { "Beast Lore" },                             -- Ctrl+4  pet care
    },
  },

  -- Controller: keys "<layer> <button>", layer none / LT / RT / LT+RT,
  -- button A X B Y or Up Down Left Right (D-pad). The Top bar's face buttons
  -- are fixed. Page 1 follows the key-roles.md controller table: the
  -- rotation on RT and LT face buttons (left thumb stays on the stick), the
  -- D-pad for stand-still casts, LT+RT for rare presses.
  controller = {
    pages = {
      {
        title = "Combat",
        ["RT A"] = { macro = "Arcane", "Arcane Shot" },   -- rotation slot 1 (Q)
        ["RT X"] = { "Serpent Sting" },                   -- rotation slot 2 (E)
        ["RT Y"] = { "Aimed Shot" },                      -- rotation slot 3 (R)
        ["RT B"] = { macro = "Melee", "Raptor Strike" },  -- rotation slot 4 (F): melee
        ["LT A"] = { "Summon Hawk", "Sniper Shot" },      -- rotation slot 5 (T)
        ["LT X"] = { "Mongoose Bite" },                   -- reactive (G)
        ["LT B"] = { "Explosive Trap", "Immolation Trap", upgrade = true }, -- damage trap (3)
        ["LT Y"] = { "Multi-Shot" },                      -- main AoE (2)
        ["RT Up"] = { macro = "Opener", "Hunter's Mark" }, -- opener (1), before the pull
        ["RT Down"] = { "Volley" },                       -- ground AoE (4), standing
        ["RT Left"] = { "Wing Clip" },                    -- escape (C)
        ["RT Right"] = { "Concussive Shot" },             -- snare (V)
        ["LT Up"] = { macro = "PetCare", "Mend Pet" },    -- sustain (Shift+Q)
        ["LT Right"] = { "Bestial Wrath", "Deterrence", "Trueshot Aura" }, -- build cooldown (Shift+E)
        ["LT Left"] = { "Intimidation", "Scatter Shot" }, -- spec control (Shift+T)
        ["LT Down"] = { "Freezing Trap" },                -- hard CC (Shift+F), laid before the pull
        ["LT+RT A"] = { macro = "FD", "Feign Death" },    -- emergency (Shift+V)
        ["LT+RT X"] = { "Frost Trap" },                   -- AoE control (Shift+G)
        ["LT+RT B"] = { racial = true },                  -- racial (Shift+C)
        ["LT+RT Y"] = { macro = "Burst", "Rapid Fire" },  -- burst (Shift+R)
        ["LT+RT Up"] = { "Viper Sting" },                 -- rare (Ctrl+Q)
        ["LT+RT Down"] = { "Scorpid Sting" },             -- rare (Ctrl+E)
        ["LT+RT Left"] = { "Tranquilizing Shot" },        -- rare (Ctrl+R)
        ["LT+RT Right"] = { "Disengage" },                -- rare (Ctrl+T)
        -- No trigger: radials (right stick picks) and out-of-combat basics.
        ["none Up"] = { flyout = 253, "Aspect of the Hawk" },        -- aspects
        ["none Left"] = { flyout = "Tracking", "Track Beasts" },      -- tracking
        ["none Right"] = { "Feed Pet" },
        -- none Down stays free.
      },
      -- Page 2: pet care on RT; the shared Utility buttons (Layouts/Shared.lua)
      -- add Hearthstone, trinkets, item macros, fishing, camp, Mount and
      -- professions.
      {
        title = "Utility",
        ["RT A"] = { "Revive Pet" },
        ["RT X"] = { "Call Pet" },
        ["RT B"] = { "Dismiss Pet" },
        ["RT Y"] = { "Beast Lore" },
        ["RT Down"] = { "Beast Training" },
        ["RT Left"] = { "Eyes of the Beast" },
        ["RT Right"] = { "Tame Beast" },
      },
      -- Page 3: pet autocast, Steam Deck helpers and the catch-all
      -- (Scare Beast, Flare, Distracting Shot, Aspect of the Beast... land here).
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
        -- Everything else you know, alphabetically.
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
    -- Steam Deck back buttons: left unbound by the owner's choice (2026-11).
    paddles = {},
  },
})
