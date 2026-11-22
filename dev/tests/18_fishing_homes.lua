-- The Fish and Bait library macros get one home per device (owner request,
-- 2026-11-22). Keyboard: Alt+F = Fish, Alt+G = Bait ({ macro = } entries in
-- ActionBars.utility). Controller set 2: none Up = Fish (the plain Fishing
-- spell until it is installed), LT A = Bait (macro only, waits until then).
-- A home takes its macro only once you install it; Apply never creates one.
-- The Fishing spell keeps its click-only side-bar home.
local H = require("harness")

local ALT_F, ALT_G = 53, 54 -- Action Bar 3 is slots 49-60: Q E R T F G ...

local function Bars56(e) e.G.CreateFrame("Frame", "MultiBar5"); e.G.CreateFrame("Frame", "MultiBar6") end

-- Controller plan entry for a key on set 2.
local function PadEntry(env, key)
  local cp = env.ns.modules.controller.Plan()
  for slotID, e in pairs(cp[2]) do
    if type(slotID) == "number" and e.key == key then return e end
  end
end

-- Keyboard slots (1-180) holding what slotText calls `want`.
local function SlotsWith(env, want)
  local out = {}
  for slot = 1, 180 do if env:slotText(slot) == want then out[#out + 1] = slot end end
  return out
end

local function KeyedBar(slot) return slot <= 36 or (slot > 48 and slot <= 72) end

test("fishing homes: installed Fish and Bait go on Alt+F/G and controller set 2, once each", function()
  local env = H.boot({ pet = true, macros = { "Fish", "Bait" }, loaded = Bars56 })
  local AB = env.ns.modules.actionbars
  local made = #env.W.macros
  local p = AB.Plan()
  eq(p[3][5].kind, "macro", "Alt+F is a macro home")
  eq(p[3][5].name, "Fish")
  eq(p[3][5].state, "new", "Alt+F placed on apply")
  eq(p[3][6].name, "Bait")
  eq(p[3][6].state, "new", "Alt+G placed on apply")
  -- Side bars never take the macros; the Fishing spell keeps its side home.
  local sideFishing = 0
  for r = 5, #p.rows do
    for i = 1, 12 do
      local e = p[r][i]
      ok(e.name ~= "Fish" and e.name ~= "Bait", "no Fish/Bait on side row " .. r)
      if e.name == "Fishing" then sideFishing = sideFishing + 1 end
    end
  end
  eq(sideFishing, 1, "Fishing (the spell) on the side bars once")

  env:slash("spells apply")
  noErrors(env)
  eq(env:slotText(ALT_F), "macro:Fish", "Alt+F holds Fish")
  eq(env:slotText(ALT_G), "macro:Bait", "Alt+G holds Bait")
  eq(#SlotsWith(env, "macro:Fish"), 1, "Fish has one keyboard home")
  eq(#SlotsWith(env, "macro:Bait"), 1, "Bait has one keyboard home")
  local fishing = SlotsWith(env, "spell:Fishing")
  eq(#fishing, 1, "Fishing spell once on the keyboard bars")
  ok(fishing[1] and not KeyedBar(fishing[1]), "Fishing spell is click-only (side bar)")
  ok(AB.charDB.placed[ALT_F] and AB.charDB.placed[ALT_G], "Apply records both Alt keys as placed")
  eq(AB.Plan().changes, 0, "plan agrees with apply")
  eq(AB.Plan()[3][5].state, "same")

  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(env:padSlot(2, "none Up")), "macro:Fish", "controller set 2 none Up holds Fish")
  local bait = PadEntry(env, "LT A")
  ok(bait and bait.slot, "set 2 LT A is in the plan")
  eq(bait.slot, env:padSlot(2, "none Up") + 10, "LT A storage slot (page 2 pattern: page 1 LT A 192 + 28)")
  eq(env:slotText(bait.slot), "macro:Bait", "controller set 2 LT A holds Bait")
  eq(bait.state, "same")
  eq(#env:calls("CreateMacro"), 0, "Apply never creates a macro")
  eq(#env.W.macros, made, "no macro added")

  env:slash("spells undo")
  noErrors(env)
  eq(env:slotText(ALT_F), nil, "Undo empties Alt+F again")
  eq(env:slotText(ALT_G), nil, "Undo empties Alt+G again")
end)

test("fishing homes: not installed, the homes wait, nothing is placed and no macro is created", function()
  local env = H.boot({ pet = true, loaded = Bars56 })
  local AB = env.ns.modules.actionbars
  local p = AB.Plan()
  for i, name in pairs({ [5] = "Fish", [6] = "Bait" }) do
    eq(p[3][i].kind, "macro", name .. ": still a macro home")
    eq(p[3][i].state, "missing", name .. ": waiting")
    eq(p[3][i].item and p[3][i].item.reason, "install")
  end
  ok(p.macrosMissing >= 2, "counted as macros to install")

  env:slash("spells apply")
  env:slash("controller apply")
  noErrors(env)
  eq(env:slotText(ALT_F), nil, "Alt+F stays empty")
  eq(env:slotText(ALT_G), nil, "Alt+G stays empty")
  eq(#env:calls("CreateMacro"), 0, "Apply never creates a macro")
  for _, m in ipairs(env.W.macros) do ok(m.name ~= "Fish" and m.name ~= "Bait", "no " .. m.name .. " macro made") end
  local printed = false
  for _, line in ipairs(env.W.chat) do
    if tostring(line):find("Fish macro", 1, true) and tostring(line):find("Bait macro", 1, true) then printed = true end
  end
  ok(printed, "Apply lists both macros as left empty")
  -- Controller: Fish falls back to the plain spell; Bait (macro only) waits.
  eq(env:slotText(env:padSlot(2, "none Up")), "spell:Fishing", "none Up: Fishing until Fish is installed")
  local bait = PadEntry(env, "LT A")
  eq(bait.item.missing, "Bait macro")
  eq(bait.item.reason, "install")
  eq(bait.state, "missing")
  eq(env:slotText(bait.slot), nil, "LT A stays empty")

  -- Installing later: the next plan wants them.
  env:installMacro("Fish")
  eq(AB.Plan()[3][5].state, "new", "Alt+F gets Fish on the next apply")
  eq(AB.Plan()[3][6].state, "missing", "Alt+G still waits for Bait")
end)

test("fishing homes: both pages say which macro to install", function()
  local env = H.boot({ pet = true, db = { lastPage = "keyboard" } })
  env:slash("")
  env:runTimers(1)
  local UI = env.ns.UI
  local page = env.ns.PageById("keyboard")
  while page.view ~= "alt" do UI.CycleView(1) end
  local f = page.caps.F
  eq(f.cell.entry.kind, "macro")
  eq(f.cell.after.state, "waiting")
  eq(f.tip and f.tip.text, "Waiting · install Fish on the Macros page", "keyboard Alt+F")
  eq(page.caps.G.tip and page.caps.G.tip.text, "Waiting · install Bait on the Macros page", "keyboard Alt+G")

  env.ns.OpenPage("controller")
  env:runTimers(1)
  local cpage = env.ns.PageById("controller")
  UI.CycleView(1)
  local a = cpage.bars[1].slots.A
  eq(a.info.name, "Bait macro", "set 2 LT A")
  eq(a.info.stateText, "Waiting · install Bait on the Macros page", "controller LT A")
  noErrors(env)
end)
