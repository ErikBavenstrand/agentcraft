-- dev/harness/uilint.lua (dev.ps1 lint-ui): each rule on small snippets, the
-- cases it must leave alone, and the "-- ui-ok:" suppression.
local L = require("uilint")

local function Lint(src, rel, ctx)
  return (L.LintSource(src, rel or "UI/Thing.lua", ctx))
end

-- Rule ids found, as "R1@3 R7@5" (sorted by line).
local function Ids(src, rel, ctx)
  local out = {}
  for _, f in ipairs(Lint(src, rel, ctx)) do out[#out + 1] = f.rule .. "@" .. f.line end
  return table.concat(out, " ")
end

test("uilint: tokenizer skips comments and strings", function()
  local toks, comments = L.Tokenize('local s = "a -- not a comment" -- real\nlocal t = [[\nCreateFrame("x")\n]] --[==[ long\ncomment ]==] x = 1')
  local names = {}
  for _, t in ipairs(toks) do if t.t == "name" then names[#names + 1] = t.v end end
  eq(table.concat(names, ","), "s,t,x")
  eq(comments[1][1], " real")
  ok(comments[4] and comments[5], "long comment filed under both lines")
  eq(toks[#toks].line, 5, "line count through long strings and comments")
end)

test("uilint: R1 Translation animations and retired motion helpers", function()
  eq(Ids('local g = f:CreateAnimationGroup()\nlocal t = g:CreateAnimation("Translation")'), "R1@2")
  eq(Ids('local t = AddAnim(g, "Translation", "t")'), "R1@1")
  eq(Ids('UI.Anim.SlideIn(f, 0, 32, 0.2)\nUI.Anim.Bump(t)\nUI.Anim.Squish(n)\nUI.Anim.Drift(tex)\nUI.Anim.Cascade(nodes)'), "R1@1 R1@2 R1@3 R1@4 R1@5")
  eq(Ids('if chip and UI.Anim and UI.Anim.Bump then UI.Anim.Bump(chip) end'), "R1@1", "a guard is not a call")
  eq(Ids('function Anim.SlideIn(region) end\nAnim.SlideIn(x)', "UI/Fx.lua"), "", "the shims in UI/Fx.lua are fine")
  eq(Ids('UI.Anim.FadeIn(f)\nUI.Anim.Pulse(f)\nlocal s = "Translation"'), "")
end)

test("uilint: R2 Scale animations outside the focus/glow helpers", function()
  eq(Ids('local function Grow(f)\n  local a = f:CreateAnimationGroup():CreateAnimation("Scale")\nend'), "R2@2")
  eq(Ids('function Ring:Attach(n)\n  local a = AddAnim(g, "Scale", "s")\nend', "UI/Fx.lua"), "")
  eq(Ids('function Anim.Bump(f)\n  local a = AddAnim(g, "Scale", "s")\nend', "UI/Fx.lua"), "R2@2")
  eq(Lint('g:CreateAnimation("Scale")')[1].sev, "WARN")
end)

test("uilint: R3 long Alpha/Scale animations not on a glow", function()
  eq(Ids('local function Pulse(row)\n  local a = g:CreateAnimation("Alpha")\n  a:SetDuration(2)\nend'), "R3@3")
  eq(Ids('local function F(row, dur)\n  local a = AddAnim(g, "Alpha", "a")\n  a:SetDuration(dur or 1.5)\nend'), "R3@3")
  eq(Ids('local function F(glow)\n  local a = g:CreateAnimation("Alpha")\n  a:SetDuration(2)\nend'), "", "on a glow")
  eq(Ids('local function F()\n  local a = g:CreateAnimation("Alpha")\n  a:SetDuration(0.9)\nend'), "")
  eq(Ids('local function F(d)\n  local a = g:CreateAnimation("Alpha")\n  a:SetDuration(math.min(d or 0.3, 1))\nend'), "")
  eq(Ids('local function F()\n  local a = g:CreateAnimation("TextureCoordTranslation")\n  a:SetDuration(40)\nend'), "", "not alpha/scale")
end)

test("uilint: R4 deprecated PixelUtil, R5 snapping off", function()
  eq(Ids('PixelUtil.SetSize(f, 10, 10)\nPixelUtil.SetPoint(f, "TOP", p, "TOP", 0, 0)\nf:SetSize(1, 1)'), "R4@1 R4@2")
  eq(Ids('t:SetSnapToPixelGrid(false)\nt:SetTexelSnappingBias(0)\nt:SetSnapToPixelGrid(true)\nt:SetTexelSnappingBias(0.5)'), "R5@1 R5@2")
end)

test("uilint: R6 SetTexCoord on an atlas texture", function()
  eq(Ids('local function B(f)\n  f.icon:SetAtlas("x")\n  f.icon:SetTexCoord(0, 1, 0, 1)\nend'), "R6@3")
  eq(Ids('local function B(f)\n  UI.SetAtlas(f.icon, UI.ART.title)\n  f.icon:SetTexCoord(0, 1, 0, 1)\nend'), "R6@3")
  eq(Ids('local function B(f)\n  f.icon:SetTexture(134400)\n  f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)\nend'), "")
  eq(Ids('local function B(f)\n  if not UI.SetAtlas(f.bg, "a") then f.bg:SetTexture(1); f.bg:SetTexCoord(0, 1, 0, 1) end\nend'), "", "fallback file texture")
  eq(Ids('local function A(f) f.icon:SetAtlas("x") end\nlocal function B(f) f.icon:SetTexCoord(0, 1, 0, 1) end'), "", "another function")
end)

test("uilint: R7 creating objects in refresh/update/event code", function()
  eq(Ids('function page:Refresh()\n  local t = self.frame:CreateTexture()\nend'), "R7@2")
  eq(Ids('local function UpdateRows(p)\n  for i = 1, 5 do\n    local r = CreateFrame("Button", nil, p)\n  end\nend'), "R7@3")
  eq(Ids('f:SetScript("OnEvent", function(self)\n  local fs = self:CreateFontString()\nend)'), "R7@2")
  eq(Ids('local function Tick(self)\n  self:CreateTexture()\nend\nf:SetScript("OnUpdate", Tick)'), "R7@2", "named OnUpdate handler")
  eq(Ids('function page:Refresh()\n  for i = 1, 5 do\n    local r = rows[i]\n    if not r then\n      r = CreateFrame("Button", nil, p)\n      rows[i] = r\n    end\n  end\nend'), "", "if not x then guard")
  eq(Ids('function page:Refresh()\n  self.bg = self.bg or self.frame:CreateTexture()\nend'), "", "x = x or guard")
  eq(Ids('function page:Refresh()\n  if self.built then return end\n  self.frame:CreateTexture()\nend'), "", "early-out guard")
  eq(Ids('function page:Refresh()\n  self.pool = self.pool or CreateFramePool("Button", p)\n  local r = self.pool:Acquire()\n  local x = CreateFrame("Frame")\nend'), "", "pooled")
  eq(Ids('function page:Build()\n  local t = self.frame:CreateTexture()\nend'), "", "build code is fine")
  eq(Ids('function page:Refresh()\n  local t = self.frame:CreateTexture() -- ui-ok: one-time, guarded by caller\nend'), "", "suppressed same line")
  eq(Ids('function page:Refresh()\n  -- ui-ok: guarded by caller\n  local t = self.frame:CreateTexture()\nend'), "", "suppressed line above")
end)

test("uilint: R8 churn inside OnUpdate", function()
  eq(Ids('f:SetScript("OnUpdate", function(self, e)\n  self.t:SetAtlas("x")\n  self:ClearAllPoints()\n  self:SetPoint("TOP")\n  self.b:Show()\n  self.c:Hide()\n  self.d:SetTexture(1)\nend)'),
    "R8@2 R8@3 R8@4 R8@5 R8@6 R8@7")
  eq(Ids('f:HookScript("OnUpdate", function(_, e)\n  acc = acc + e\n  if acc > 1 then self:SetScript("OnUpdate", nil) end\nend)'), "")
  eq(Ids('f:SetScript("OnShow", function(self)\n  self.t:Show()\nend)'), "")
end)

test("uilint: R9 SetDataProvider without Retain", function()
  eq(Ids('box:SetDataProvider(p)\nbox:SetDataProvider(p, ScrollBoxConstants.RetainScrollPosition)'), "R9@1")
end)

test("uilint: R10 tinting stock art", function()
  local ctx = { art = L.CollectArt('UI.ART = { title = { "UI-Character-Info-Title" }, hover = { "Options_List_Hover" } }') }
  eq(Ids('local function B(r)\n  UI.SetAtlas(r.bg, UI.ART.title)\n  r.bg:SetVertexColor(1, 0, 0)\nend', nil, ctx), "R10@3")
  eq(Ids('local function B(r)\n  r.bg:SetTexture("Interface\\\\FrameGeneral\\\\UI-Frame-Metal")\n  r.bg:SetDesaturated(true)\nend', nil, ctx), "R10@3")
  eq(Ids('local function B(r)\n  if not UI.SetAtlas(r.bg, UI.ART.title) then r.bg:SetTexture(UI.WHITE); r.bg:SetVertexColor(1, 1, 1, 0.1) end\nend', nil, ctx), "", "tint on the white fallback")
  eq(Ids('local function B(r)\n  UI.SetAtlas(r.bg, UI.ART.hover)\n  r.bg:SetVertexColor(1, 0, 0)\nend', nil, ctx), "")
  eq(Lint('local function B(r)\n  r.bg:SetAtlas("bronze-edge")\n  r.bg:SetVertexColor(1, 0, 0)\nend')[1].sev, "WARN")
end)

test("uilint: R11 window root rounds layout", function()
  eq(Ids('local frame = CreateFrame("Frame")', "UI/Window.lua"), "R11@1")
  eq(Ids('frame:SetRoundLayoutToNearestPixel(true)', "UI/Window.lua"), "")
  eq(Ids('PixelUtil.SetRoundLayoutToNearestPixelRecursively(frame, true)', "UI/Window.lua"), "")
  eq(Ids('local frame = CreateFrame("Frame")', "UI/Other.lua"), "", "only UI/Window.lua")
end)

test("uilint: function boundaries survive if/while/for/repeat blocks", function()
  local src = table.concat({
    'local function Build(f)',
    '  if a then for i = 1, 2 do while b do repeat x() until c end end end',
    '  do local y = 1 end',
    'end',
    'function page:Refresh()',
    '  local t = f:CreateTexture()',
    'end',
    'local function After() return f:CreateTexture() end',
  }, "\n")
  eq(Ids(src), "R7@6")
end)

test("uilint: R12 HIGHLIGHT textures are additive", function()
  eq(Ids('local hl = c:CreateTexture(nil, "HIGHLIGHT")\nhl:SetAllPoints()'), "R12@1")
  eq(Ids('local hl = c:CreateTexture(nil, "HIGHLIGHT")\nhl:SetAllPoints()\nhl:SetBlendMode("ADD")'), "")
  eq(Ids('local t = c:CreateTexture(nil, "ARTWORK")'), "")
end)

test("uilint: R13 hover never moves the focus or fills the Inspector", function()
  eq(Ids('w:HookScript("OnEnter", function(self)\n  ns.Focus:Set(self, "mouse")\nend)'), "R13@1")
  eq(Ids('w:HookScript("OnEnter", function(self)\n  pane:Inspect(self)\nend)'), "R13@1")
  eq(Ids('w:HookScript("OnEnter", function(self) self:acTip() end)\nw:HookScript("OnMouseDown", function(self) ns.Focus:Set(self, "click") end)'), "")
end)

test("uilint: R14 no calls that taint Blizzard's secure UI", function()
  eq(Ids('ShowUIPanel(frame)\nHideUIPanel(frame)'), "R14@1 R14@2")
  eq(Ids('pcall(RegisterGameMenuEscHandler, 1, fn)'), "R14@1", "a pcall still runs it")
  eq(Ids('RegisterGameMenuEscHandler(1, fn)'), "R14@1")
  eq(Ids('-- never ShowUIPanel(frame)\nframe:Show()'), "")
end)
