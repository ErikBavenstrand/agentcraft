-- The Gamepad UI's stance bar (Blizzard_GamepadActionBars/StanceBar.lua):
-- in a stance it swaps the bar named by CVar GamepadStanceBarOverride for 8
-- slots of that stance. Apply mirrors the replaced bar into every stance's
-- slots, so a button does the same thing in every stance (owner, 2026-11-24).
local H = require("harness")

-- override: CVar value (3 = Page 1 Right bar). first: the active stance's first slot.
local function Boot(override, offset, first)
  local env = H.boot()
  local G = env.G
  G.C_CVar = { GetCVar = function(name) if name == "GamepadStanceBarOverride" then return tostring(override) end end }
  G.C_GamepadUI.GetFirstGamepadActionBarStorageSlotIndexForActiveStance = function()
    return env.W.bonusOffset > 0 and first + (env.W.bonusOffset - offset) * 8 or nil
  end
  G.C_GamepadUI.IsValidGamepadActionStorageSlotIndex = function(s) return s >= 181 and s < 400 end
  env.W.bonusOffset = offset
  return env
end

local function Name(env, slot)
  local t, id = env.G.GetActionInfo(slot)
  if not t then return nil end
  if t == "spell" then return env.G.C_Spell.GetSpellName(id) end
  return env.G.GetActionText(slot) or t
end

test("the stance target follows GamepadStanceBarOverride", function()
  local env = Boot(3, 1, 300)
  local C = env.ns.modules.controller
  local page, bar = C.StanceTarget()
  eq(page, 1, "page"); eq(bar, 2, "Right bar (RT)")
  env.G.C_CVar.GetCVar = function() return "1" end
  eq(C.StanceTarget(), nil, "None replaces nothing")
  env.G.C_CVar.GetCVar = function() return "12" end
  page, bar = C.StanceTarget()
  eq(page, 3, "page 3"); eq(bar, 3, "Bottom bar")
end)

test("Apply mirrors the RT bar into the active stance's 8 slots", function()
  local env = Boot(3, 1, 300)
  local C = env.ns.modules.controller
  env:slash("controller apply")
  noErrors(env)
  local plan = C.Plan()
  ok(#plan.stances >= 1, "one stance row at least")
  local row = plan.stances[1]
  eq(row.first, 300, "first slot"); ok(row.seen, "seen, not inferred")
  for k = 1, 8 do
    local std = plan[1][16 + k]
    local want = std and not std.item.missing and std.item.name or nil
    eq(Name(env, 299 + k), want, "stance slot " .. k .. " mirrors RT button " .. k)
    if want then eq(row[k].state, "same", "and reads as done") end
  end
  eq(plan.changes, 0, "nothing left to apply")
end)

test("no stance bar: nothing outside the three pages changes", function()
  local env = Boot(1, 1, 300)
  env:slash("controller apply")
  for s = 300, 307 do eq(env.G.GetActionInfo(s), nil, "slot " .. s .. " untouched") end
  eq(#env.ns.modules.controller.Plan().stances, 0, "no stance rows")
end)

test("Undo also restores the stance slots", function()
  local env = Boot(3, 1, 300)
  env:slash("controller apply")
  env:slash("controller undo")
  noErrors(env)
  for s = 300, 307 do eq(env.G.GetActionInfo(s), nil, "slot " .. s .. " empty again") end
end)
