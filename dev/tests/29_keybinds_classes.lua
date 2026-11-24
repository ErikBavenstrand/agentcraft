-- The owner's hard rule (dev/key-roles.md): the keybinds are identical for
-- every class. Boot each of the nine class fixtures, apply the keybinds and
-- the controller (which binds the back buttons), and compare the resulting
-- key -> command map with the hunter's.
local H = require("harness")

local FIXTURES = { "hunter", "warrior", "paladin", "rogue", "priest", "shaman", "mage", "warlock", "druid" }

local function Binds(fixture)
  local env = H.boot({ fixture = fixture })
  env:slash("keys apply")
  env:slash("controller apply")
  noErrors(env)
  local map = {}
  for key, action in pairs(env.W.bindings) do
    if action and action ~= "" then map[key] = action end
  end
  return map
end

test("keybinds: every class gets the same key -> command layout", function()
  local ref = Binds("hunter")
  local n = 0
  for _ in pairs(ref) do n = n + 1 end
  ok(n >= 48 + 10, "the reference binds bars 1-4 and the pet bar (" .. n .. " keys)")
  eq(ref["Q"], "ACTIONBUTTON1", "Q")
  eq(ref["SHIFT-4"], "MULTIACTIONBAR1BUTTON12", "Shift+4")
  eq(ref["CTRL-Q"], "MULTIACTIONBAR3BUTTON1", "Ctrl+Q")
  eq(ref["ALT-4"], "MULTIACTIONBAR2BUTTON12", "Alt+4")
  for i = 2, #FIXTURES do
    local fixture = FIXTURES[i]
    local got = Binds(fixture)
    for key, action in pairs(ref) do eq(got[key], action, fixture .. " " .. key) end
    for key, action in pairs(got) do eq(ref[key], action, fixture .. " extra bind " .. key) end
  end
end)
