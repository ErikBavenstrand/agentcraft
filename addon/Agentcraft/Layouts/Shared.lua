-- Shared controller buttons: the same on every class and every character
-- (owner request, 2026-11-24: "a nice all in one solution" for professions
-- and the other shared things). Data contract: dev/layout-format.md
-- ("Shared buttons"). Keep every value a literal: dev.ps1 rules reads this
-- file without running Lua.
--
-- Layout.lua merges each page here into the class page of the same number
-- when a layout resolves, for every spec. A class page never names one of
-- these buttons [rules]; it keeps only its own class buttons (page 2: the RT
-- layer but RT Up, and LT Right).
--
-- Page 2 (Utility):
--   none  Up Fish, Left Cozy Sleeping Bag, Down Basic Campfire, Right Mount
--         (the library macro; waits until you install it on the Macros page)
--   LT    the item layer: A Bait, X HealPot, Y ManaPot, B Bandage,
--         Left Food (generated item macros, each waiting until you install
--         it on the Macros page; ManaPot stays empty on warriors and
--         rogues), Up / Down your equipped on-use trinkets. LT Right is the
--         class's own.
--   RT    Up Hearthstone
--   LT+RT 8 profession slots, filled from your own professions in the stable
--         order of Layout.PROFESSIONS: 1 first primary (Mining, Alchemy...),
--         2 second primary, then Cooking, First Aid, fishing helpers (Bait
--         and Tackle), then gathering and utility spells (Find Minerals,
--         Find Herbs, Smelting, Disenchant...). A character with fewer
--         profession spells leaves the last slots empty.
--         Slot order A, Y, X, B, Down, Up, Left, Right keeps the owner's
--         tested hunter page: Engineering (2) on Y, Cooking (3) on X, First
--         Aid (4) on B and Bait and Tackle (5) on Down, as before.
--
-- Page 3 (Extras):
--   LT+RT Y  the "Agentcraft" macro (/ac): opens this window from the pad.
local _, ns = ...

ns.Layout.RegisterShared({
  controller = {
    pages = {
      [2] = {
        title = "Utility",
        ["RT Up"] = { item = "Hearthstone" },
        ["LT A"] = { macro = "Bait" },     -- best fishing bait onto your pole (waits until installed)
        ["LT X"] = { macro = "HealPot" },  -- Healthstone, else best healing potion (keyboard Alt+Q)
        ["LT Y"] = { macro = "ManaPot" },  -- mana gem, else best mana potion (keyboard Alt+E)
        ["LT B"] = { macro = "Bandage" },  -- best bandage on yourself (keyboard Alt+R)
        ["LT Left"] = { macro = "Food" },  -- best food for your level (keyboard Alt+T)
        ["LT Up"] = { utility = 8 },       -- on-use trinket (bottom)
        ["LT Down"] = { utility = 7 },     -- on-use trinket (top)
        ["none Up"] = { macro = "Fish", "Fishing" },
        ["none Left"] = { item = "Cozy Sleeping Bag" }, -- camp, with Basic Campfire on Down
        ["none Down"] = { "Basic Campfire" },
        ["none Right"] = { macro = "Mount" }, -- waits until installed
        ["LT+RT A"] = { profession = 1 },
        ["LT+RT Y"] = { profession = 2 },
        ["LT+RT X"] = { profession = 3 },
        ["LT+RT B"] = { profession = 4 },
        ["LT+RT Down"] = { profession = 5 },
        ["LT+RT Up"] = { profession = 6 },
        ["LT+RT Left"] = { profession = 7 },
        ["LT+RT Right"] = { profession = 8 },
      },
      [3] = {
        -- Next to the Steam Deck helpers (Reload, Follow, Focus, Assist on
        -- the D-pad, Skull on LT+RT A): opens this window with one button
        -- (owner request, 2026-11-24). Waits until installed.
        ["LT+RT Y"] = { macro = "Agentcraft" },
      },
    },
  },
})
