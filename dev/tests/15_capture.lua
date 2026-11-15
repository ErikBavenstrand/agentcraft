-- Dev capture (UI/Capture.lua, /ac capture): the step list, the geometry
-- dump, the flicker probe, a full run with a stubbed Screenshot, and the
-- combat refusal. The mock has no Screenshot or screenshot events, so each
-- test stubs them on env.G.
local H = require("harness")

local function Boot()
  local env = H.boot({ pet = true })
  local shots, cvars = {}, { screenshotFormat = "jpeg", screenshotQuality = "3" }
  env.G.Screenshot = function()
    shots[#shots + 1] = env.W.now
    env.G.C_Timer.After(0.2, function() env:fire("SCREENSHOT_SUCCEEDED") end)
  end
  env.G.C_CVar = env.G.C_CVar or {}
  env.G.C_CVar.GetCVar = function(k) return cvars[k] end
  env.G.C_CVar.SetCVar = function(k, v) cvars[k] = v; return true end
  local reloads = 0
  env.G.ReloadUI = function() reloads = reloads + 1 end
  return env, shots, cvars, function() return reloads end
end

local function Names(steps)
  local set = {}
  for _, s in ipairs(steps) do set[s.name] = true end
  return set
end

test("capture: the step list covers every page, view, sheet, focus move and the pad pass", function()
  local env = Boot()
  local DC = env.ns.DevCapture
  ok(DC, "ns.DevCapture exists")
  local steps = DC.BuildSteps("all")
  local n = Names(steps)
  for _, name in ipairs({ "keyboard:open", "keyboard:view-shift", "keyboard:view-alt", "keyboard:view-side",
    "keyboard:list", "keyboard:list-fold", "keyboard:now", "keyboard:review", "keyboard:review-fold",
    "keyboard:focus-first", "keyboard:focus-right", "keyboard:focus-down",
    "controller:open", "controller:view-2", "controller:view-3", "controller:list", "controller:review",
    "macros:open", "macros:view-all", "macros:page-2", "macros:tag", "macros:review",
    "options:open", "options:log", "options:toast", "options:confirm",
    "pad:on", "pad:keyboard", "pad:controller", "pad:macros", "pad:options", "pad:off" }) do
    ok(n[name], "step " .. name)
  end
  local quick = DC.BuildSteps("quick")
  ok(#quick < #steps, "quick is shorter")
  ok(not Names(quick)["pad:on"], "quick skips the pad pass")
  local one = DC.BuildSteps("macros")
  for _, s in ipairs(one) do ok(s.page == nil or s.page == "macros", "page suite only: " .. s.name) end
  noErrors(env)
end)

test("capture: a step dump lists the window tree as tab-separated rows", function()
  local env = Boot()
  env:slash("")
  local DC = env.ns.DevCapture
  local rows, truncated = DC.Dump(env.G.AgentcraftFrame)
  ok(#rows > 50, "rows: " .. #rows)
  eq(truncated, false)
  ok(rows[1]:find("^AgentcraftFrame\t"), "root row first: " .. rows[1])
  local text, full = false, false
  for _, r in ipairs(rows) do
    local f = {}
    for v in (r .. "\t"):gmatch("(.-)\t") do f[#f + 1] = v end
    if #f == #DC.FIELDS then full = true end
    if f[2] == "FontString" and f[4] == "1" and (f[20] or "") ~= "" then text = true end
  end
  ok(full, "visible rows carry every field")
  ok(text, "a visible font string with text")
  noErrors(env)
end)

test("capture: the flicker probe flags a region that shows and hides twice, not a one-way change", function()
  local env = Boot()
  env:slash("")
  local DC = env.ns.DevCapture
  local f = env.G.AgentcraftFrame
  local blink = f:CreateTexture(nil, "ARTWORK")
  blink:SetSize(10, 10); blink:SetPoint("CENTER")
  local once = f:CreateTexture(nil, "ARTWORK")
  once:SetSize(10, 10); once:SetPoint("TOPLEFT")
  DC.ProbeStart(f)
  DC.ProbeSample()
  blink:Hide(); once:Hide(); DC.ProbeSample()
  blink:Show(); DC.ProbeSample()
  blink:Hide(); DC.ProbeSample()
  local out = DC.ProbeStop()
  ok(out and out.frames == 4, "4 samples")
  eq(#out.hits, 1)
  ok(out.hits[1] and out.hits[1].flips >= 2, "the blinking texture is the hit")
  ok(out.changed >= 2, "both changes counted")
  noErrors(env)
end)

test("capture: a full run shoots every step, stores geometry, restores CVars and the page, then reloads", function()
  local env, shots, cvars, reloads = Boot()
  env:slash("")
  local ns = env.ns
  ns.OpenPage("options")
  env:slash("capture")
  eq(cvars.screenshotFormat, "png")
  env:runTimers(600)
  local cap = ns.db.capture
  ok(cap and cap.steps and #cap.steps > 20, "steps recorded")
  eq(#shots, #cap.steps)
  for _, s in ipairs(cap.steps) do
    ok(s.shot and s.shot.ok, "shot ok: " .. s.name)
    ok(#s.rows > 20, "rows for " .. s.name)
    ok(s.shot.time:match("^%d%d%d%d%d%d_%d%d%d%d%d%d$"), "time stamp " .. tostring(s.shot.time))
  end
  for _, s in ipairs(cap.steps) do
    ok(not s.error, "no error in " .. s.name .. ": " .. tostring(s.error))
    if s.note then note(s.name .. ": " .. s.note) end
  end
  eq(#cap.errors, 0)
  for i = 2, #shots do ok(shots[i] - shots[i - 1] >= 1.1 - 1e-6, "shots 1.1 s apart") end
  local probes = 0
  for _, s in ipairs(cap.steps) do if s.probe then probes = probes + 1 end end
  ok(probes >= 4, "probe steps: " .. probes)
  eq(cvars.screenshotFormat, "jpeg"); eq(cvars.screenshotQuality, "3")
  eq(ns.UI.CurrentPage().id, "options")
  eq(ns.db.prompts, nil)
  eq(cap.summary.screenshots, #cap.steps)
  eq(reloads(), 1)
  eq(ns.DevCapture.Running(), false)
  noErrors(env)
end)

test("capture: refuses in combat, and stops when combat starts", function()
  local env, shots = Boot()
  env.W.inCombat = true
  env:slash("capture")
  eq(#shots, 0)
  ok(env:chatText():find("combat"), "says why")
  eq(env.ns.DevCapture.Running(), false)
  env.W.inCombat = false
  env:slash("capture quick noreload")
  ok(env.ns.DevCapture.Running(), "started")
  env:runTimers(5)
  env:fire("PLAYER_REGEN_DISABLED")
  eq(env.ns.DevCapture.Running(), false)
  ok(env.ns.db.capture.stopped, "stop reason recorded")
  local n = #shots
  env:runTimers(60)
  eq(#shots, n)
  noErrors(env)
end)
