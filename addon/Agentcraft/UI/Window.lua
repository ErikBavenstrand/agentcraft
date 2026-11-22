-- The Agentcraft window (/ac), v2 "The War Table" shell (dev/ui-spec-v2.md §3):
--   header     portrait, page title, summary, readiness meter, character line
--   side tabs  one LargeSideTabButtonTemplate per page outside the right edge,
--              with LB / RB glyphs above and below in controller prompt mode
--   stage      712x512 inset where the page draws (view strip at its top)
--   inspector  264 px pane that explains the focused element (UI/Inspector.lua)
--   prompt bar the last result on the left; (A) (B) (X) [(Y) primary] on the right
--   layers     toast, combat banner and the Review sheet over the stage
-- Pages come from ns.RegisterPage (Core.lua). Input is UI/Input.lua's
-- ns.Focus / ns.Esc / ns.Input; motion and sound are UI/Fx.lua.
local _, ns = ...
local UI = ns.UI
local Focus, Esc, Input = ns.Focus, ns.Esc, ns.Input

local W, H = 1000, 640
local TAB_W, TAB_STEP, TAB_TOP = 44, 58, -96
local STAGE_TOP, STAGE_BOTTOM, PANE_W = -84, 44, 264
local SCALE_MIN, SCALE_MAX = 0.8, 1.25

local frame, stage, paneHost, pane, promptBar, status, toast, banner, review
local title, summary, summaryBtn, meter, who, failMsg, gateMsg, divider
local tabs, tabGlyphs = {}, {}
local prompts = {}
local current, lastError, inCombat
local Refresh, CloseReview

local function Resolve(v, page)
  if type(v) == "function" then
    local ok, r = pcall(v, page)
    if ok then return r end
    return nil
  end
  return v
end

-- What the right stick scrolls: the page's ScrollRegion when it names a
-- shown one, else the focused node's own scroll list, else the shared
-- Inspector scroll. Never nil while the Inspector exists, so a stale
-- registration from another page (or a closed log view) is always replaced.
local function ScrollRegionFor(page, node)
  local region = page and page.ScrollRegion and Resolve(page.ScrollRegion, page)
  if region and region.IsShown and not region:IsShown() then region = nil end
  region = region or (node and node.acScroll and node.acScroll.scroll)
  return region or (pane and pane.scroll) or nil
end

local function FirstLine(text) return (tostring(text or ""):match("^[^\n]*") or "") end
local function PageGated(page) return ns.IsGated(page.module) end
local function IsV2(page) return page.api == 2 end

local function SortedPages()
  local list = {}
  for _, p in ipairs(ns.pages) do list[#list + 1] = p end
  table.sort(list, function(a, b)
    if (a.order or 500) ~= (b.order or 500) then return (a.order or 500) < (b.order or 500) end
    return tostring(a.id) < tostring(b.id)
  end)
  return list
end

local function SetIcon(tex, icon, page)
  icon = Resolve(icon, page)
  if type(icon) == "string" and icon:find("^atlas:") then
    if not UI.SetAtlas(tex, icon:sub(7)) then tex:SetTexture(UI.QUESTION) end
  else
    tex:SetTexture(icon or UI.QUESTION)
  end
end

-- Status button and toast -------------------------------------------------------------
-- status keeps the last result (first line + "(+N more)"); focus it to read
-- every line in the Inspector. The toast is an opaque plate lit behind the
-- status line for a few seconds: it never covers the view strip at the stage
-- top (the capture showed the layer chips through the old translucent toast
-- there) and never repeats the status text in a second place.

local function LayoutStatus()
  local more = status.more:GetText() or ""
  local mw = more ~= "" and (status.more:GetStringWidth() or 0) + 4 or 0
  local fs = status.text
  local full = (fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth()) or fs:GetStringWidth() or 0
  local room = math.max((status:GetWidth() or 0) - mw, 1)
  fs:SetWidth(math.max(math.min(math.ceil(full) + 1, room), 1))
end

-- Hides the toast plate and the result or error text it lit, so an old
-- message ("Nothing to apply") never lingers next to a page it doesn't
-- describe.
local function HideToast()
  Esc.Remove("toast")
  if toast:IsShown() then UI.Anim.FadeOut(toast, 0.15) end
  if status and (status.kind == "result" or status.kind == "error") then
    status.kind, status.lines = nil, nil
    status.text:SetText("")
    status.more:SetText("")
    LayoutStatus()
  end
end

local function SetStatus(kind, text, lines, more)
  status.kind, status.lines, status.fromRefresh = kind, lines, nil
  status.text:SetText(text or "")
  status.more:SetText(more or "")
  LayoutStatus()
end

-- Lights the toast plate behind the status line. text (when given and not
-- already the status) becomes the status first. It appears at once; only
-- its timed dismissal fades. An error toast stays until Back.
local function ShowToast(text, kind)
  if not toast or not text or text == "" then return end
  if status.text:GetText() ~= text then SetStatus(kind == "error" and "error" or "result", text, { text }) end
  toast.style = kind
  toast.gen = (toast.gen or 0) + 1
  local gen = toast.gen
  UI.Anim.Stop(toast)
  toast:Show()
  if kind == "error" then
    Esc.Push(HideToast, "toast")
  elseif C_Timer and C_Timer.After then
    C_Timer.After(4, function() if toast.gen == gen and toast.style ~= "error" then HideToast() end end)
  end
end

local function ClearStatus() SetStatus(nil, "", nil) end

local function ShowResult(out)
  local lines = {}
  for line in tostring(out or ""):gmatch("[^\n]+") do
    if line:find("%S") then lines[#lines + 1] = line end
  end
  if #lines == 0 then return end
  local more = #lines > 1 and UI.C.GRAY:WrapTextInColorCode("(+" .. (#lines - 1) .. " more)") or nil
  SetStatus("result", lines[1], lines, more)
  ShowToast(lines[1], "result")
end

local function ShowError(err, logged)
  err = tostring(err)
  if not logged and err ~= lastError then ns.LogLine(UI.C.RED:WrapTextInColorCode("Error: ") .. err) end
  lastError = err
  local lines = {}
  for line in err:gmatch("[^\n]+") do lines[#lines + 1] = line end
  SetStatus("error", UI.C.RED:WrapTextInColorCode("Error: ") .. FirstLine(err), lines)
end

local function RunAction(fn)
  local out, err = ns.Run(fn)
  if err then ShowError(err, true); ShowToast(status.text:GetText(), "error")
  else ShowResult(out) end
  Refresh()
  return out, err
end

-- Actions (v1 footer buttons, now in the Inspector's action dock) ---------------------

local function Ordered(actions)
  local list = {}
  for _, a in ipairs(actions or {}) do if not a.primary then list[#list + 1] = a end end
  for _, a in ipairs(actions or {}) do if a.primary then list[#list + 1] = a end end
  return list
end

local function ClickAction(page, a)
  local run = function() RunAction(function() return a.fn(page) end) end
  local text = Resolve(a.confirm, page)
  if text and text ~= "" then UI.Confirm(text, run) else run() end
end

-- page.footerFrame: the page's action buttons (kept under that name so v1
-- code and tests still find page.footerFrame.buttons).
local function ActionsFor(page)
  if page.footerFrame then return page.footerFrame end
  local dock = pane:ActionsDock()
  local f = CreateFrame("Frame", nil, dock)
  f:SetAllPoints()
  f.buttons = {}
  for _, a in ipairs(Ordered(page.actions)) do
    local b = UI.Button(f, "", nil, function() ClickAction(page, a) end, nil, 26)
    UI.Tooltip(b, function() if a.tooltip then return Resolve(a.label, page) end end, function() return Resolve(a.tooltip, page) end)
    b.action = a
    b.acId = "action:" .. tostring(Resolve(a.label, page))
    f.buttons[#f.buttons + 1] = b
  end
  f:Hide()
  UI.PixelSnap(f)
  page.footerFrame = f
  return f
end

local function UpdateActions(page)
  local f = page.footerFrame
  if not f or #f.buttons == 0 then pane:SetActionsHeight(0) return end
  local x, y, maxW = 0, 0, PANE_W - 16
  for _, b in ipairs(f.buttons) do
    local a = b.action
    b:SetText(Resolve(a.label, page) or "")
    UI.FitButton(b, a.width or 80)
    if b:GetWidth() > maxW then b:SetWidth(maxW) end
    local enabled = true
    if a.enabled then enabled = Resolve(a.enabled, page) ~= false end
    if inCombat then enabled = false end
    b:SetEnabled(enabled)
    if x > 0 and x + b:GetWidth() > maxW then x = 0; y = y + 30 end
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", f, "TOPLEFT", x, -y)
    x = x + b:GetWidth() + 6
  end
  pane:SetActionsHeight(y + 30)
end

-- Inspector default content ------------------------------------------------------------

-- Clears the pane for subject. A refill of the subject already shown (a
-- Refresh, the settle after a page switch) keeps the scroll position, so
-- the Inspector never jumps back to its top while you read it. Returns the
-- scroll to restore after the fill.
local function BeginInspect(subject)
  local keep = subject ~= nil and subject == pane.subject and pane.scroll:GetVerticalScroll() or nil
  pane:Clear()
  pane.subject = subject
  return keep
end

local function DefaultInspect(page)
  local keep = BeginInspect(page)
  if not page then return end
  if page.DefaultInspect then
    local ok, err = pcall(page.DefaultInspect, page, pane)
    if ok then return pane:RestoreScroll(keep) end
    ns.LogLine("Inspector: " .. tostring(err))
  end
  local icon = page.icon and Resolve(page.icon, page)
  if type(icon) == "string" and icon:find("^atlas:") then icon = nil end
  pane:Header(icon, page.title or "", nil)
  if page.description then pane:Text(Resolve(page.description, page)) end
  local text = summary and summary:GetText()
  if text and text ~= "" then pane:Text(text) end
  local tip = summaryBtn and summaryBtn.tip
  if type(tip) == "string" then pane:Text(tip)
  elseif type(tip) == "table" then for _, l in ipairs(tip) do pane:Text(l) end end
  pane:RestoreScroll(keep)
end

local function InspectNode(node)
  if not pane then return end
  if Focus.pinned and node ~= Focus.pinned then node = Focus.pinned end
  if node and Focus.ZoneOf(node) ~= "inspector" then Focus.inspected = node end
  if node and node.acInspect then
    local keep = BeginInspect(node)
    local ok, err = pcall(node.acInspect, node, pane)
    if ok then return pane:RestoreScroll(keep) end
    ns.LogLine("Inspector: " .. tostring(err))
  end
  DefaultInspect(current)
end

-- Prompt bar --------------------------------------------------------------------------

local function Count(groups)
  local n = 0
  for _, g in ipairs(groups or {}) do n = n + #(g.items or {}) end
  return n
end

-- The page's primary: { label, fn, enabled, count } or nil.
local function Primary(page)
  if not page or PageGated(page) then return nil end
  if page.Review then
    local ok, groups = pcall(page.Review, page)
    local n = ok and Count(groups) or 0
    local label = (page.reviewLabel and Resolve(page.reviewLabel, page)) or "Review & Apply"
    return { label = n > 0 and (label .. " " .. n) or label, enabled = n > 0, count = n, review = true }
  end
  if page.primary then
    local p = page.primary
    local en = p.enabled == nil or Resolve(p.enabled, page) ~= false
    return { label = Resolve(p.label, page) or "Apply", enabled = en, fn = p.fn, count = 0 }
  end
end

local function PromptLabels(page)
  local labels = { PAD1 = "Select", PAD2 = (Esc.CanBack and Esc.CanBack() or Esc.HasLayers()) and "Back" or "Close" }
  if page and page.views and #page.views > 1 then labels.PAD3 = page.viewLabel or "View" end
  local list = page and Resolve(page.prompts, page)
  if type(list) == "table" then
    for _, p in ipairs(list) do labels[p.key] = p.label end
  end
  return labels
end

-- What each page's readiness meter counts (summary text counts changes).
local METER_UNITS = { keyboard = "keys", bars = "keys", controller = "buttons", macros = "macros" }

-- Calls b:SetGlow only when the glow turns on or off: every Refresh lays the
-- prompts out, and re-calling SetGlow(true) restarted the glow pulse from its
-- dim end each time (a visible flicker of the primary button).
local function SetGlow(b, on)
  on = on and true or false
  if b._acGlow == on then return end
  b._acGlow = on
  b:SetGlow(on)
end

local function LayoutPrompts()
  if not promptBar then return end
  local mode = UI.PromptMode()
  local x = -2
  local order = { "PAD4", "PAD3", "PAD2", "PAD1" }
  local labels = PromptLabels(current)
  local primary = Primary(current)
  for _, key in ipairs(order) do
    local b = prompts[key]
    local show
    if key == "PAD4" then
      show = primary ~= nil
      if show then
        b:SetLabel(primary.label .. (inCombat and " (in combat)" or ""))
        b:SetEnabled(primary.enabled and not inCombat)
        SetGlow(b, primary.enabled and primary.count > 0 and not inCombat)
      else SetGlow(b, false) end
    elseif key == "PAD1" then
      show = mode ~= "mouse" and labels.PAD1 ~= nil
      if show then b:SetLabel(labels.PAD1) end
    else
      show = labels[key] ~= nil
      if show then b:SetLabel(labels[key]) end
    end
    b:SetShown(show)
    if show then
      b:Relayout()
      b:ClearAllPoints()
      b:SetPoint("RIGHT", promptBar, "RIGHT", x, 0)
      x = x - b:GetWidth() - 6
    end
  end
  status:SetWidth(math.max(W - 16 - (-x) - 16, 60))
  LayoutStatus()
  -- LB / RB indicators by the side tabs, in controller prompt mode only.
  for _, g in pairs(tabGlyphs) do g:SetShown(mode == "pad" and #tabs > 1) end
end

-- Pages ------------------------------------------------------------------------------

local function CharLine()
  if not who then return end
  local _, class = UnitClass("player")
  local name = UnitClass("player") or ""
  local text = name
  if class and C_ClassColor and C_ClassColor.GetClassColor then
    local c = C_ClassColor.GetClassColor(class)
    if c and c.WrapTextInColorCode then text = c:WrapTextInColorCode(name) end
  end
  who:SetText(string.format("Level %d %s", UnitLevel("player") or 0, text))
end

-- The player's portrait in PortraitFrameTemplate's disc. SetPortraitToClassIcon
-- leaves the class cell's texcoords on the texture, so calling it before
-- SetPortraitToUnit showed a dark corner of the portrait (an empty disc in
-- the capture). Full texcoords first; the class icon only as a fallback.
local function Portrait()
  local _, class = UnitClass("player")
  local tex = frame.GetPortrait and frame:GetPortrait()
  if type(tex) == "table" and tex.SetTexCoord then tex:SetTexCoord(0, 1, 0, 1) end
  local ok = false
  if frame.SetPortraitToUnit and UnitExists and UnitExists("player") then ok = pcall(frame.SetPortraitToUnit, frame, "player") end
  if not ok and frame.SetPortraitToClassIcon and class then pcall(frame.SetPortraitToClassIcon, frame, class) end
end

local function StyleTabs()
  for _, t in ipairs(tabs) do
    local sel = t.page == current
    if t.SetChecked then t:SetChecked(sel) end
    if t.icon then t.icon:SetDesaturated(PageGated(t.page) and true or false) end
  end
end

-- The view strip at the stage top, built from page.views / page.toggles.
local function SelectView(page, i)
  local v = page.views and page.views[i]
  if not v then return end
  page.view = v.key
  if page.OnView then
    local ok, err = pcall(page.OnView, page, v.key)
    if not ok then ShowError(err) end
  end
  Refresh()
end

local function BuildStrip(page)
  if page.strip or not IsV2(page) then return end
  if not (page.views and #page.views > 0) and not (page.toggles and #page.toggles > 0) then return end
  local strip = CreateFrame("Frame", nil, page.frame)
  strip:SetPoint("TOPLEFT", 8, -4)
  strip:SetPoint("TOPRIGHT", -8, -4)
  strip:SetHeight(28)
  strip.acZone = "view"
  strip:SetFrameLevel(page.frame:GetFrameLevel() + 10)
  if page.views and #page.views > 0 then
    local labels, sel = {}, 1
    for i, v in ipairs(page.views) do
      labels[i] = { text = v.label, key = v.key }
      if v.key == page.view then sel = i end
    end
    strip.chips = UI.Chips(strip, labels, function(i) SelectView(page, i) end,
      { selected = sel, idPrefix = "view:" .. page.id .. ":" })
    strip.chips:SetPoint("LEFT")
    page.view = page.view or page.views[sel].key
  end
  local x = 0
  strip.toggles = {}
  for i = #(page.toggles or {}), 1, -1 do
    local t = page.toggles[i]
    local a, b = (t.labels and t.labels[1]) or t.a or "", (t.labels and t.labels[2]) or t.b or ""
    local tg = UI.Toggle2(strip, a, b, function(idx)
      if t.set then
        local ok, err = pcall(t.set, page, idx)
        if not ok then ShowError(err) end
      end
      Refresh()
    end)
    tg:SetPoint("RIGHT", strip, "RIGHT", x, 0)
    x = x - tg:GetWidth() - 12
    local cur = t.get and Resolve(t.get, page)
    if cur then tg:Set(cur, true) end
    tg.def = t
    strip.toggles[#strip.toggles + 1] = tg
  end
  page.strip = strip
end

local function SyncStrip(page)
  local strip = page.strip
  if not strip then return end
  if strip.chips and page.views then
    for i, v in ipairs(page.views) do
      if v.key == page.view and strip.chips.selected ~= i then strip.chips:Select(i, true) end
    end
  end
  for _, tg in ipairs(strip.toggles or {}) do
    local cur = tg.def.get and Resolve(tg.def.get, page)
    if cur and tg:Get() ~= cur then tg:Set(cur, true) end
  end
end

local function CycleView(delta)
  local page = current
  if not page or PageGated(page) then return end
  if page.CycleView then
    pcall(page.CycleView, page, delta or 1)
    UI.Sound("view")
    return Refresh()
  end
  if not (page.views and #page.views > 1) then return end
  local idx = 1
  for i, v in ipairs(page.views) do if v.key == page.view then idx = i end end
  idx = (idx - 1 + (delta or 1)) % #page.views + 1
  UI.Sound("view")
  if page.strip and page.strip.chips then page.strip.chips:Select(idx) else SelectView(page, idx) end
end

local function ShowGate(page, mod)
  if page.frame then page.frame:Hide() end
  if page.footerFrame then page.footerFrame:Hide() end
  pane:SetActionsHeight(0)
  failMsg:Hide()
  gateMsg:SetText((mod.title or mod.name) .. " is turned off.")
  gateMsg:SetButton("Turn On", function()
    local list = type(page.module) == "table" and page.module or { page.module }
    for _, key in ipairs(list) do
      local m = ns.ModuleOf(key)
      if m and not m.active then ns.SetModuleEnabled(m, true) end
    end
    Refresh()
  end)
  gateMsg:Show()
  summary:SetText(UI.C.GRAY:WrapTextInColorCode("Turned off"))
  summaryBtn.tip = nil
  meter:Hide()
end

-- Builds the page frame the first time; returns true when it exists.
local function EnsureBuilt(page)
  if page.frame then return true end
  local f = CreateFrame("Frame", nil, stage)
  if IsV2(page) then
    f:SetAllPoints(stage)
  else
    f:SetSize(600, 450)
    f:SetPoint("CENTER", stage, "CENTER", 0, 0)
  end
  f.acZone = "stage"
  page.frame = f
  local ok, err = true, nil
  if page.Build then
    if IsV2(page) then ok, err = pcall(page.Build, page, f, pane)
    else ok, err = pcall(page.Build, page, f) end
  end
  if not ok then
    f:Hide()
    page.frame = nil
    page.strip = nil
    page.buildErr = err
    return false
  end
  page.buildErr = nil
  BuildStrip(page)
  return true
end

local function ShowFail(page)
  failMsg:Show()
  gateMsg:Hide()
  if page.footerFrame then page.footerFrame:Hide() end
  pane:SetActionsHeight(0)
  ShowError(page.buildErr)
  summary:SetText("")
  meter:Hide()
end

Refresh = function()
  if not current then return end
  StyleTabs()
  local gated, mod = PageGated(current)
  if gated then
    ShowGate(current, mod)
    LayoutPrompts()
    Focus:Validate()
    return
  end
  gateMsg:Hide()
  if not current.frame and (current.buildErr or not EnsureBuilt(current)) then
    ShowFail(current)
    LayoutPrompts()
    return
  end
  current.frame:Show()
  failMsg:Hide()
  local f = ActionsFor(current)
  f:Show()
  local okAll = true
  if current.Refresh then
    local ok, err = pcall(current.Refresh, current)
    if not ok then okAll = false; ShowError(err); status.fromRefresh = true end
  end
  -- Pixel rounding for whatever the page built or added (cheap: objects
  -- already done are skipped).
  UI.PixelSnap(current.frame)
  local text, tip = "", nil
  if current.Status then
    local ok, s, t = pcall(current.Status, current)
    if ok then text, tip = s or "", t else okAll = false; ShowError(s); status.fromRefresh = true end
  end
  summary:SetText(text)
  summaryBtn.tip = tip
  -- Readiness meter, labelled with what it counts ("12 / 58 keys in place"):
  -- page.readiness may return the unit third, else page.readinessUnit.
  local done, total, unit
  if current.readiness then
    local ok, d, t, u = pcall(current.readiness, current)
    if ok then done, total, unit = d, t, u end
  end
  if done and total and total > 0 then
    local p = Primary(current)
    unit = unit or current.readinessUnit or METER_UNITS[current.id]
    meter:SetValue(done, total, p and p.count > 0)
    meter:SetLabel(string.format("%d / %d %sin place", done, total, unit and (unit .. " ") or ""))
    meter:Show()
  else
    meter:Hide()
  end
  SyncStrip(current)
  if divider then divider:SetShown(not current.hideDivider) end
  UpdateActions(current)
  LayoutPrompts()
  frame.disableFrameFocusPagingWhenFocused = current.disableFrameFocusPaging and true or nil
  if okAll and status.kind == "error" and status.fromRefresh then ClearStatus() end
  if okAll then lastError = nil end
  if frame:IsShown() then
    local node = Focus:Validate()
    -- Focus inside the Inspector keeps showing what was inspected before it.
    local subject = node
    if node and (Focus.ZoneOf(node) == "inspector" or node.acNoInspect) then
      subject = Focus.inspected
      if subject and not Focus.Usable(subject) then subject = nil end
    end
    if not subject or not subject.acInspect then
      -- The pane shows the page's default content: say so in
      -- Focus.inspected too (it kept naming the node explained before, so
      -- Back and the next Refresh worked from the wrong subject).
      if not Focus.pinned then
        if node and Focus.ZoneOf(node) ~= "inspector" then Focus.inspected = node end
        DefaultInspect(current)
      end
    elseif not Focus.pinned then InspectNode(subject) end
    if node and node ~= subject and not Focus.Usable(node) then node = Focus:Restore() end
    local region = ScrollRegionFor(current, node)
    Input.SyncSmartNav(node, region)
  end
end

local function Select(page)
  -- Close every layer properly before the Back stack is cleared, so no sheet,
  -- pin or sticky toast outlives the Back layer that guards it.
  if review and review:IsShown() then CloseReview() end
  if Focus.pinned then Focus:Unpin() end
  if toast and (toast:IsShown() or (current ~= page and status and status.kind)) then HideToast() end
  if current and current ~= page then
    if current.frame then current.frame:Hide() end
    if current.footerFrame then current.footerFrame:Hide() end
    if current.OnHide then pcall(current.OnHide, current) end
  end
  local changed = current ~= page
  current = page
  Esc.Clear({ engaged = true })
  if ns.db then ns.db.lastPage = page.id end
  title:SetText(page.title or "")
  page.buildErr = nil
  -- Instant switch with the tab sound, as CharacterFrame's side tabs: no
  -- bump on the tab, no slide on the page.
  if changed and frame:IsShown() then UI.Sound("tab") end
  if not PageGated(page) and not EnsureBuilt(page) then
    StyleTabs()
    ShowFail(page)
    LayoutPrompts()
    DefaultInspect(page)
    return
  end
  if page.OnShow then pcall(page.OnShow, page) end
  Refresh()
  if frame:IsShown() then Focus:Restore(true) end
end

local function Step(delta)
  local list = SortedPages()
  for i, p in ipairs(list) do
    if p == current then return Select(list[(i - 1 + delta) % #list + 1]) end
  end
end

-- The page to open first: the last one, else Overview, else Controller with
-- the Gamepad UI, else Keyboard (or the v1 Action Bars page), else the first.
local function FirstPage()
  local last = ns.db and ns.db.lastPage
  local p = last and ns.PageById(last)
  if p then return p end
  if ns.PageById("overview") then return ns.PageById("overview") end
  if UI.GamepadUI() and ns.PageById("controller") then return ns.PageById("controller") end
  return ns.PageById("keyboard") or ns.PageById("bars") or SortedPages()[1]
end

-- Review sheet --------------------------------------------------------------------------

local function ReviewRows(groups)
  local rows = {}
  for _, g in ipairs(groups or {}) do
    rows[#rows + 1] = { header = true, text = (g.title or "") .. " (" .. #(g.items or {}) .. ")" }
    for _, it in ipairs(g.items or {}) do rows[#rows + 1] = it end
  end
  return rows
end

-- A review row's key as button glyphs: d.set + d.keys (PAD keys) when the
-- page sends them, else parsed from "Set 1 · LT + RT + Right". nil when any
-- part is not a controller button (keyboard keys stay text).
local function ChordKeys(d)
  if type(d.keys) == "table" and #d.keys > 0 then return d.set and ("Set " .. d.set) or "", d.keys end
  local key = d.key
  if type(key) ~= "string" or key == "" then return nil end
  local set, rest = key:match("^(.-)%s*·%s*(.+)$")
  if not rest then set, rest = "", key end
  local keys = {}
  for tok in (rest .. " + "):gmatch("(.-)%s*%+%s*") do
    local k = UI.PAD_KEYS[tok]
    if not k then return nil end
    keys[#keys + 1] = k
  end
  if #keys == 0 then return nil end
  return set, keys
end

-- Fills a review row's key column: glyphs in pad prompt mode, text otherwise.
-- d nil hides it (group headers).
local function ReviewKey(r, d)
  local set, keys
  if d and UI.PadMode() then set, keys = ChordKeys(d) end
  for _, g in ipairs(r.keyGlyphs) do g:Hide() end
  r.keyDir:Hide()
  if not keys then
    r.keySet:Hide()
    r.key:SetShown(d ~= nil)
    r.key:SetText(d and d.key or "")
    return
  end
  r.key:Hide()
  r.keySet:SetText(set)
  r.keySet:SetShown(set ~= "")
  local x = 8 + (set ~= "" and math.ceil(r.keySet:GetStringWidth() or 0) + 6 or 0)
  for i, k in ipairs(keys) do
    local g = r.keyGlyphs[i]
    if not g then g = UI.Glyph(r, k, 28, "pad"); r.keyGlyphs[i] = g end
    g:SetKey(k)
    g:ClearAllPoints()
    g:SetPoint("LEFT", r, "LEFT", x, 0)
    g:Show()
    x = x + 29
  end
  -- D-pad crosses differ only by the lit arm: name the direction too.
  local last = keys[#keys]
  if last:find("^PADD") then
    r.keyDir:SetText(UI.PAD_NAMES[last] or "")
    r.keyDir:ClearAllPoints()
    r.keyDir:SetPoint("LEFT", r, "LEFT", x + 1, 0)
    r.keyDir:Show()
  end
end

local function OpenReview(page)
  if review:IsShown() then return end
  if inCombat then return ShowToast("In combat · changes wait until combat ends", "result") end
  local ok, groups = pcall(page.Review, page)
  if not ok then return ShowError(groups) end
  local n = Count(groups)
  if n == 0 then return ShowToast("Nothing to apply: everything is in place.", "result") end
  review.page = page
  review.title:SetText("Review changes · " .. (page.title or ""))
  review.list:SetData(ReviewRows(groups))
  review.note:SetText(page.reviewNote and Resolve(page.reviewNote, page) or "Your bars and keys are backed up the first time you apply.")
  review.apply:SetLabel("Apply " .. n .. (n == 1 and " change" or " changes"))
  review.apply:SetEnabled(page.Commit ~= nil)
  -- Shown in place at once, like a Blizzard dialog (no fade, no slide).
  review:Show()
  UI.PixelSnap(review)
  UI.Sound("review")
  Esc.Push(function() CloseReview() end, "review")
  review.acDefault = review.apply
  Focus:PushModal(review)
  Focus:Set(review.apply, Focus.source or "key", true)
end

CloseReview = function()
  if not review:IsShown() then return end
  Esc.Remove("review")
  review:Hide()
  Focus:PopModal(review)
  LayoutPrompts()
end

local function Commit()
  local page = review.page
  if not page or not page.Commit then return end
  if inCombat or (InCombatLockdown and InCombatLockdown()) then return ShowToast("In combat · changes wait until combat ends", "result") end
  local changed
  local out, err = ns.Run(function()
    local o, e, ids = page.Commit(page)
    changed = ids
    if o and o ~= "" then ns.Out(o) end
    if e then error(e, 0) end
  end)
  CloseReview()
  if err then
    ShowError(err, true)
    ShowToast(status.text:GetText(), "error")
    return Refresh()
  end
  -- Refresh redraws what changed (and the meter) in place. No proc cascade
  -- over the changed nodes and no meter animation (dev/ui-rules.md rule 4);
  -- the sound, the toast and the new state say it worked. changedIds stays
  -- part of the Commit contract.
  Refresh()
  page.lastChangedIds = type(changed) == "table" and changed or nil
  UI.Sound("applied")
  if UI.PadMode() and C_GamePad and C_GamePad.SetVibration then pcall(C_GamePad.SetVibration, "Low", 0.2) end
  ShowResult(out ~= "" and out or "Applied.")
end

local function DoPrimary()
  -- Y / Ctrl+Enter on the open Review sheet is its Apply prompt.
  if review and review:IsShown() then
    if review.apply and (not review.apply.IsEnabled or review.apply:IsEnabled()) then Commit() end
    return
  end
  local page = current
  local p = Primary(page)
  if not p or not p.enabled or inCombat then return end
  if p.review then return OpenReview(page) end
  if p.fn then RunAction(function() return p.fn(page) end) end
end

-- Position and scale ---------------------------------------------------------------------

local function AutoScale() return UI.GamepadUI() and 1.1 or 1.0 end

-- Scales come in whole 0.05 steps: a fitted scale such as 0.9183 put every
-- 1 px border on a fraction of a pixel. A fit is rounded down to a step, so
-- the window still fits; SetRoundLayoutToNearestPixel snaps the rest.
local SCALE_STEP = 0.05
local function Step05(s) return math.floor(s / SCALE_STEP + 1e-6) * SCALE_STEP end

local function ClampScale(s)
  s = math.max(SCALE_MIN, math.min(SCALE_MAX, Step05(s + SCALE_STEP / 2)))
  local pw, ph = UIParent:GetWidth(), UIParent:GetHeight()
  if pw and pw > 0 then s = math.min(s, Step05((pw - 20) / (W + TAB_W))) end
  if ph and ph > 0 then s = math.min(s, Step05((ph - 20) / H)) end
  return s
end

local function ApplyScale()
  if frame then frame:SetScale(ClampScale((ns.db and ns.db.scale) or AutoScale())) end
end

local function RestorePosition()
  frame:ClearAllPoints()
  local p = ns.db and ns.db.window
  if type(p) == "table" and p[1] then
    frame:SetPoint(p[1], UIParent, p[2] or p[1], p[3] or 0, p[4] or 0)
  else
    frame:SetPoint("CENTER", UIParent, "CENTER", -TAB_W / 2, 0)
  end
end

local function SavePosition()
  local point, _, relPoint, x, y = frame:GetPoint(1)
  if point and ns.db then ns.db.window = { point, relPoint, x, y } end
end

function UI.SetScale(v)
  if not ns.db then return end
  ns.db.scale = v and math.max(SCALE_MIN, math.min(SCALE_MAX, Step05(v + SCALE_STEP / 2))) or nil
  ApplyScale()
end
function UI.GetScale()
  return frame and frame:GetScale() or ClampScale((ns.db and ns.db.scale) or AutoScale())
end
function UI.ResetPosition()
  if not ns.db then return end
  ns.db.window, ns.db.scale = nil, nil
  if frame then RestorePosition(); ApplyScale() end
end

-- Plain Show/Hide, never ShowUIPanel/HideUIPanel: from addon code those
-- taint Blizzard's panel manager, and the next Escape then failed with
-- "AddOn blocked from an action only available to the Blizzard UI"
-- (owner report, 0.32.1). Escape closes the window through UISpecialFrames.
local function ShowWindow() frame:Show() end
local function HideWindow() frame:Hide() end

-- Combat ------------------------------------------------------------------------------------

local function SetCombat(on)
  inCombat = on and true or false
  if not banner then return end
  if inCombat then
    if review and review:IsShown() then CloseReview() end
    banner:Show()
  else
    banner:Hide()
  end
  if summaryBtn then summaryBtn:SetAlpha(inCombat and 0 or 1) end
  if frame and frame:IsShown() then Refresh() end
end

-- Build ------------------------------------------------------------------------------------

local function BuildHeader()
  title = UI.Text(frame, "", "GameFontHighlightLarge")
  title:SetPoint("TOPLEFT", 66, -30)
  title:SetWidth(W - 66 - 250)
  title:SetJustifyH("LEFT")
  title:SetWordWrap(false)
  -- The meter's caption sits above the bar: the bar at -48 keeps the caption
  -- (about 14 px tall) clear of the title bar, which ends near -24 and cut
  -- the caption's top off in the capture.
  meter = UI.Meter(frame, 200, 12)
  meter:SetPoint("TOPRIGHT", -16, -48)
  if meter.label.SetFontObject then meter.label:SetFontObject("GameFontHighlight") end
  meter.label:SetWidth(232)
  meter.label:SetWordWrap(false)
  meter:Hide()
  who = UI.Text(frame, "", "GameFontNormal")
  who:SetPoint("TOPRIGHT", -16, -66)
  who:SetWidth(232)
  who:SetJustifyH("RIGHT")
  who:SetWordWrap(false)
  summaryBtn = CreateFrame("Button", nil, frame)
  summaryBtn:SetPoint("TOPLEFT", 66, -52)
  summaryBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -(16 + 232 + 12), -52)
  summaryBtn:SetHeight(18)
  summary = UI.Text(summaryBtn, "", "GameFontNormal")
  summary:SetPoint("LEFT")
  summary:SetPoint("RIGHT")
  summary:SetJustifyH("LEFT")
  summary:SetWordWrap(false)
  summaryBtn:SetScript("OnEnter", function(self)
    local text = summary:GetText() or ""
    if text == "" or not current then return end
    local lines = { text }
    local tip = self.tip
    if type(tip) == "string" then lines[#lines + 1] = tip
    elseif type(tip) == "table" then for _, l in ipairs(tip) do lines[#lines + 1] = l end end
    UI.ShowTooltip(self, current.title, lines, "ANCHOR_BOTTOM")
  end)
  summaryBtn:SetScript("OnLeave", GameTooltip_Hide)
  summaryBtn.acSkip = true
  UI.Name(meter, "acMeter"); UI.Name(summaryBtn, "acSummary"); UI.Name(title, "acTitle"); UI.Name(who, "acWho")
end

local function BuildTabs()
  local list = SortedPages()
  local side = UI.Has("LargeSideTabButtonTemplate")
  local topBar
  if not side then
    local labels = {}
    for i, p in ipairs(list) do labels[i] = p.title or p.id end
    topBar = UI.Tabs(frame, labels, function(i) Select(list[i]) end, W - 300)
    topBar:SetPoint("TOPLEFT", stage, "TOPLEFT", 0, 32)
    topBar.acZone = "tabs"
    for i, t in ipairs(topBar.Tabs) do
      t.page = list[i]
      UI.Node(t, { style = "button", id = "tab:" .. list[i].id })
      t.acInspect, t.acNoInspect = nil, true  -- tabs never touch the Inspector (owner, 2026-11-15)
      tabs[i] = t
    end
    return
  end
  local holder = CreateFrame("Frame", nil, frame)
  holder:SetPoint("TOPLEFT", frame, "TOPRIGHT", -2, TAB_TOP + 34)
  holder:SetSize(TAB_W, #list * TAB_STEP + 68)
  holder._acOutsideOK = true
  holder.acZone = "tabs"
  UI.Name(holder, "acTabs")
  for i, p in ipairs(list) do
    local ok, t = pcall(CreateFrame, "CheckButton", nil, holder, "LargeSideTabButtonTemplate")
    if not ok then t = CreateFrame("CheckButton", nil, holder) t:SetSize(43, 55) end
    t:SetPoint("TOPLEFT", frame, "TOPRIGHT", -2, TAB_TOP - (i - 1) * TAB_STEP)
    t._acOutsideOK = true
    t.page = p
    UI.Name(t, "acTab_" .. tostring(p.id))
    if type(t.Icon) ~= "table" then t.Icon = nil end
    if not t.Icon and not (ok and type(t.SetIcon) == "function") then
      t.Icon = t:CreateTexture(nil, "ARTWORK")
      t.Icon:SetSize(30, 30)
      t.Icon:SetPoint("CENTER", -4, 0)
    end
    if t.Icon then SetIcon(t.Icon, p.icon, p)
    else
      local icon = Resolve(p.icon, p)
      if type(icon) == "string" and icon:find("^atlas:") then icon = UI.QUESTION end
      pcall(t.SetIcon, t, icon or UI.QUESTION)
    end
    t.icon = t.Icon
    -- A file icon on the template's Icon has no size, so it drew at its
    -- 64 px file size, bigger than the tab (the capture's oversized dock
    -- icons). Blizzard's own call for non-atlas icons: fill the tab's
    -- interior, sized from the tab mask's atlas.
    local pic = Resolve(p.icon, p)
    local isAtlas = type(pic) == "string" and pic:find("^atlas:") ~= nil
    if ok and t.Icon and not isAtlas and type(t.SetFillToInterior) == "function" then
      local mw, mh = UI.AtlasSize("common-sidetab-mask")
      local extent = mw and math.floor(math.min(mw, mh) - 6) or 40
      extent = math.max(32, math.min(extent, 44))
      pcall(t.SetFillToInterior, t, true, extent)
    end
    t:SetScript("OnClick", function() Select(p) end)
    UI.Tooltip(t, function() return p.title end, function() return Resolve(p.description, p) end)
    UI.Node(t, { style = "button", id = "tab:" .. p.id })
    t.acInspect, t.acNoInspect = nil, true  -- tabs never touch the Inspector (owner, 2026-11-15)
    tabs[i] = t
  end
  local function TabGlyph(key, anchorTab, above)
    local g = UI.Glyph(holder, key, 24, "pad")
    if above then g:SetPoint("BOTTOM", anchorTab, "TOP", -4, 4) else g:SetPoint("TOP", anchorTab, "BOTTOM", -4, -4) end
    g._acOutsideOK = true
    g:Hide()
    return g
  end
  if #tabs > 0 then
    tabGlyphs.lb = TabGlyph("PADLSHOULDER", tabs[1], true)
    tabGlyphs.rb = TabGlyph("PADRSHOULDER", tabs[#tabs], false)
  end
end

local function BuildStage()
  stage = UI.Inset(frame)
  stage:SetPoint("TOPLEFT", 8, STAGE_TOP)
  stage:SetPoint("BOTTOMRIGHT", -(PANE_W + 16), STAGE_BOTTOM)
  stage.acZone = "stage"
  UI.Name(stage, "acStage")
  -- Backdrop: the inset's own Blizzard background. The character sheet's
  -- General-BG (made for a 398 px pane) and the 197x355 class art were
  -- stretched over 706x506 here, which read as smeared, "weird" textures;
  -- the black vignette over them was our own WHITE8x8 box.
  if UI.Has("ShadowOverlayTemplate") then
    local ok, sh = pcall(CreateFrame, "Frame", nil, stage, "ShadowOverlayTemplate")
    if ok and sh then sh:SetAllPoints(); sh:SetFrameLevel(stage:GetFrameLevel() + 30); sh.acSkip = true; UI.MarkIgnored(sh) end
  end
  stage:EnableMouse(true)
  stage:SetScript("OnMouseUp", function(_, button) if button == "RightButton" then Esc.Pop(); LayoutPrompts() end end)
  -- A click inside the window engages the keyboard (arrows, Enter, Space).
  stage:SetScript("OnMouseDown", function(_, button) if button == "LeftButton" and not (InCombatLockdown and InCombatLockdown()) then Focus:Engage() end end)
  frame:HookScript("OnMouseDown", function() if not (InCombatLockdown and InCombatLockdown()) then Focus:Engage() end end)
  failMsg = UI.Empty(stage, "This page failed to load. Details are in Options › Log.")
  failMsg:SetFrameLevel(stage:GetFrameLevel() + 40)
  gateMsg = UI.Empty(stage, "")
  gateMsg:SetFrameLevel(stage:GetFrameLevel() + 40)
  ns.UI.pageInset, ns.UI.body, ns.UI.stage = stage, stage, stage

  -- CharacterFrame's pane divider: common-framedivider at its own width,
  -- running the full height (Camelot/CharacterFrame.xml).
  divider = frame:CreateTexture(nil, "ARTWORK")
  if UI.SetAtlas(divider, UI.ART.divider, true) then
    local dw = divider:GetWidth() or 8
    divider:SetPoint("TOP", stage, "TOPRIGHT", 4, 0)
    divider:SetPoint("BOTTOM", stage, "BOTTOMRIGHT", 4, 0)
    divider:SetWidth(dw)
  else
    divider:SetTexture(UI.WHITE); divider:SetVertexColor(0.9, 0.62, 0.32, 0.35); divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", stage, "TOPRIGHT", 4, 0)
    divider:SetPoint("BOTTOMLEFT", stage, "BOTTOMRIGHT", 4, 0)
  end

  -- The Inspector: an inset well, with the character sheet's stat pane art
  -- (UI-Character-Info-Stat-BG and the StoneBG3 header stone, both at
  -- their own aspect, as CharacterFrame's RightPaneHost draws them) clipped
  -- to the well. Before, both were stretched to 264x512 / 264x120 and a
  -- WHITE8x8 shade covered them.
  paneHost = CreateFrame("Frame", nil, frame)
  paneHost:SetPoint("TOPRIGHT", -8, STAGE_TOP)
  paneHost:SetPoint("BOTTOMRIGHT", -8, STAGE_BOTTOM)
  paneHost:SetWidth(PANE_W)
  paneHost.acZone = "inspector"
  UI.Name(paneHost, "acInspector")
  paneHost.inset = UI.Inset(paneHost)
  paneHost.inset:SetAllPoints()
  paneHost.inset.acSkip = true
  -- Levels set once: the well and its art under the pane's content, the
  -- well's border (its NineSlice child) over the art.
  local base = math.max(paneHost:GetFrameLevel() - 1, 0)
  paneHost.inset:SetFrameLevel(base)
  local art = CreateFrame("Frame", nil, paneHost.inset)
  art:SetPoint("TOPLEFT", 3, -3)
  art:SetPoint("BOTTOMRIGHT", -3, 3)
  art:SetFrameLevel(base)
  if art.SetClipsChildren then art:SetClipsChildren(true) end
  local artInner = CreateFrame("Frame", nil, art)
  artInner:SetAllPoints()
  artInner:SetFrameLevel(base)
  paneHost.bg = artInner:CreateTexture(nil, "BACKGROUND")
  paneHost.bg:SetPoint("TOP")
  if not UI.SetAtlasWidth(paneHost.bg, UI.ART.statBg, PANE_W - 6) then paneHost.bg:Hide() end
  paneHost.stone = artInner:CreateTexture(nil, "BACKGROUND", nil, 1)
  paneHost.stone:SetPoint("TOP")
  if not UI.SetAtlasWidth(paneHost.stone, UI.ART.stoneBg, PANE_W - 6) then paneHost.stone:Hide() end
  pane = UI.NewInspector(paneHost)
  -- Dark ink while the page lays parchment under the Inspector: page.inkInspector
  -- (true or a function), or a shown page.right (the Macros book's right page).
  pane.inkFn = function()
    local p = current
    if not p then return false end
    if p.inkInspector ~= nil then return Resolve(p.inkInspector, p) and true or false end
    local r = p.right
    return type(r) == "table" and r.IsShown and r:IsShown() and true or false
  end
  ns.UI.pane = pane
end

local function BuildPromptBar()
  promptBar = CreateFrame("Frame", nil, frame)
  promptBar:SetPoint("BOTTOMLEFT", 8, 6)
  promptBar:SetPoint("BOTTOMRIGHT", -8, 6)
  promptBar:SetHeight(32)
  promptBar.acZone = "prompts"
  UI.Name(promptBar, "acPromptBar")
  status = CreateFrame("Button", nil, promptBar)
  status:SetPoint("LEFT", 6, 0)
  status:SetHeight(28)
  status:SetWidth(W - 300)
  status.text = UI.Text(status, "", "GameFontHighlight")
  status.text:SetPoint("LEFT")
  status.text:SetJustifyH("LEFT")
  status.text:SetWordWrap(false)
  status.more = UI.Text(status, "", "GameFontHighlight")
  status.more:SetPoint("LEFT", status.text, "RIGHT", 4, 0)
  status.more:SetWordWrap(false)
  status:SetScript("OnEnter", function(self)
    if not self.lines or #self.lines == 0 then return end
    UI.ShowTooltip(self, current and current.title or "Agentcraft", self.lines, "ANCHOR_TOP")
  end)
  status:SetScript("OnLeave", GameTooltip_Hide)
  UI.Node(status, { style = "button", id = "status" })
  status.acReadable = true
  status.acInspect = function(self, p)
    if not self.lines or #self.lines == 0 then return p:Empty("No result yet. What an action prints shows here.") end
    p:Header(nil, "Last result", self.kind == "error" and "Error" or nil)
    for _, l in ipairs(self.lines) do p:Text(l) end
  end
  prompts.PAD1 = UI.Prompt(promptBar, "PAD1", "Select", function() Focus:Activate("mouse") end)
  prompts.PAD2 = UI.Prompt(promptBar, "PAD2", "Back", function() Esc.Back(); LayoutPrompts() end)
  prompts.PAD3 = UI.Prompt(promptBar, "PAD3", "View", function() CycleView(1) end)
  prompts.PAD4 = UI.PrimaryPrompt(promptBar, "PAD4", "Review & Apply", function() DoPrimary() end, 300)
  for k, b in pairs(prompts) do b.acId = "prompt:" .. k; UI.Name(b, "acPrompt" .. k) end
  UI.Name(status, "acStatus")
end

local function BuildLayers()
  -- Toast: an opaque plate behind the status line (see ShowToast), one
  -- frame level under it so the status text and its focus stay on top.
  toast = UI.Plate(promptBar, { opaque = true })
  -- As wide as the text (status.more follows it), not the whole status box.
  toast:SetPoint("TOPLEFT", status, "TOPLEFT", -6, 1)
  toast:SetPoint("BOTTOMLEFT", status, "BOTTOMLEFT", -6, -1)
  toast:SetPoint("RIGHT", status.more, "RIGHT", 10, 0)
  toast:SetFrameLevel(math.max(status:GetFrameLevel() - 1, 0))
  status:SetFrameLevel(toast:GetFrameLevel() + 1)
  UI.Name(toast, "acToast")
  toast:Hide()

  -- Combat banner: in the header band, over the summary line (which it
  -- replaces while you fight), so it never covers stage content.
  banner = UI.Plate(frame)
  banner:SetPoint("LEFT", summaryBtn, "LEFT", -6, 0)
  banner:SetPoint("RIGHT", summaryBtn, "RIGHT", 0, 0)
  banner:SetHeight(26)
  banner:SetFrameLevel(frame:GetFrameLevel() + 20)
  -- No red WHITE8x8 wash over the plate: the warning icon and red text say it.
  banner.icon = banner:CreateTexture(nil, "ARTWORK")
  banner.icon:SetSize(18, 18)
  banner.icon:SetPoint("LEFT", 10, 0)
  if not UI.SetAtlas(banner.icon, UI.ART.warning) then banner.icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew") end
  banner.text = UI.Text(banner, "In combat · changes wait until combat ends", "GameFontHighlight")
  banner.text:SetTextColor(UI.C.RED:GetRGB())
  banner.text:SetPoint("LEFT", 34, 0)
  banner.text:SetPoint("RIGHT", -10, 0)
  banner.text:SetJustifyH("LEFT")
  banner.text:SetWordWrap(false)
  UI.Name(banner, "acBanner")
  banner:Hide()

  -- Review sheet over stage + inspector.
  review = CreateFrame("Frame", nil, frame)
  review:SetPoint("TOPLEFT", 8, STAGE_TOP)
  review:SetPoint("BOTTOMRIGHT", -8, STAGE_BOTTOM)
  review:SetFrameLevel(frame:GetFrameLevel() + 60)
  review:EnableMouse(true)
  review.acZone = "review"
  UI.Name(review, "acReview")
  review.dim = CreateFrame("Frame", nil, review)
  review.dim:SetAllPoints()
  review.dim.tex = UI.Gradient(review.dim, "BACKGROUND", "VERTICAL", { 0, 0, 0, 0.85 }, { 0, 0, 0, 0.75 })
  review.dim.tex:SetAllPoints()
  review.panel = UI.Plate(review, { opaque = true })
  review.panel:SetPoint("TOPLEFT", 40, -16)
  review.panel:SetPoint("BOTTOMRIGHT", -40, 16)
  review.title = UI.Text(review.panel, "", "GameFontNormalMed3")
  review.title:SetPoint("TOPLEFT", 16, -14)
  local listHost = CreateFrame("Frame", nil, review.panel)
  listHost:SetPoint("TOPLEFT", 12, -40)
  listHost:SetPoint("BOTTOMRIGHT", -12, 76)
  review.list = UI.ScrollList(listHost, 36, function(parent)
    local r = CreateFrame("Button", nil, parent)
    r.bg = UI.Flat(r, "BACKGROUND", 0, 0, 0, 0.25)
    r.bg:SetAllPoints()
    r.key = UI.Text(r, "", "GameFontNormal")
    r.key:SetPoint("LEFT", 8, 0)
    r.key:SetWidth(150) -- fits "Set 1 · LT + RT + Right"
    r.key:SetJustifyH("LEFT")
    r.key:SetWordWrap(false)
    -- Pad prompt mode: "Set 1" + the chord's button glyphs.
    r.keySet = UI.Text(r, "", "GameFontNormal")
    r.keySet:SetPoint("LEFT", 8, 0)
    r.keySet:SetJustifyH("LEFT")
    r.keyDir = UI.Text(r, "", "GameFontNormalSmall")
    r.keyDir:SetJustifyH("LEFT")
    r.keyGlyphs = {}
    r.nowIcon = r:CreateTexture(nil, "ARTWORK")
    r.nowIcon:SetSize(28, 28)
    r.nowIcon:SetPoint("LEFT", 164, 0)
    r.now = UI.Text(r, "", "GameFontHighlight")
    r.now:SetPoint("LEFT", r.nowIcon, "RIGHT", 6, 0)
    r.now:SetWidth(170)
    r.now:SetJustifyH("LEFT")
    r.now:SetWordWrap(false)
    r.arrow = r:CreateTexture(nil, "ARTWORK")
    r.arrow:SetSize(16, 16)
    r.arrow:SetPoint("LEFT", 378, 0)
    r.arrow:SetTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    r.afterIcon = r:CreateTexture(nil, "ARTWORK")
    r.afterIcon:SetSize(28, 28)
    r.afterIcon:SetPoint("LEFT", 402, 0)
    r.after = UI.Text(r, "", "GameFontHighlight")
    r.after:SetPoint("LEFT", r.afterIcon, "RIGHT", 6, 0)
    r.after:SetWidth(180)
    r.after:SetJustifyH("LEFT")
    r.after:SetWordWrap(false)
    r.note = UI.Text(r, "", "GameFontHighlight")
    r.note:SetPoint("LEFT", r.after, "RIGHT", 8, 0)
    r.note:SetPoint("RIGHT", -8, 0)
    r.note:SetJustifyH("LEFT")
    r.note:SetWordWrap(false)
    -- Section headers: the title plate at its own width, centred, with the
    -- text between its end ornaments (as UI.SectionTitle).
    -- At the plate's own size (196x40), widened only for a long title.
    r.headBg = r:CreateTexture(nil, "BACKGROUND", nil, 1)
    r.headBg:SetPoint("CENTER")
    r.headNative = UI.SetAtlas(r.headBg, UI.ART.title, true)
    if not r.headNative then r.headBg:SetSize(420, 30); r.headBg:SetTexture(UI.WHITE); r.headBg:SetVertexColor(0.9, 0.62, 0.32, 0.18) end
    r.headW = r.headBg:GetWidth() or 196
    r.head = UI.Text(r, "", "GameFontHighlight")
    r.head:SetPoint("LEFT", r.headBg, "LEFT", 48, 0)
    r.head:SetPoint("RIGHT", r.headBg, "RIGHT", -48, 0)
    r.head:SetJustifyH("CENTER")
    r.head:SetWordWrap(false)
    r.acReadable = true
    UI.Node(r, { style = "row" })
    return r
  end, function(r, d, i)
    local head = d.header
    r.head:SetShown(head); r.now:SetShown(not head); r.after:SetShown(not head)
    ReviewKey(r, not head and d or nil)
    r.note:SetShown(not head); r.arrow:SetShown(not head)
    r.nowIcon:SetShown(not head and d.nowIcon ~= nil); r.afterIcon:SetShown(not head and d.afterIcon ~= nil)
    r.headBg:SetShown(head)
    -- A faint dark band on every other row (our own flat art: the 157x19
    -- stat stripe stretched across an 870x36 row looked smeared).
    r.bg:SetShown(not head and i % 2 == 1)
    if head then
      r.head:SetText(d.text or "")
      if r.headNative then
        local sw = (r.head.GetUnboundedStringWidth and r.head:GetUnboundedStringWidth()) or r.head:GetStringWidth() or 0
        r.headBg:SetWidth(math.max(r.headW, math.ceil(sw) + 96))
      end
      r.acSkip = true
    else
      r.acSkip = nil
      r.nowIcon:SetTexture(d.nowIcon)
      r.now:SetText(d.nowName or "Empty")
      r.afterIcon:SetTexture(d.afterIcon)
      r.after:SetText(d.afterName or "Empty")
      if d.color then r.after:SetTextColor(UI.RowRGB(d.color)) else r.after:SetTextColor(1, 1, 1) end
      r.note:SetText(d.note or "")
      if d.color then r.note:SetTextColor(UI.RowRGB(d.color)) else r.note:SetTextColor(1, 0.82, 0) end
    end
    r.acId = "review:" .. i
  end)
  -- The footnote sits in the band between the list and Back / Apply.
  review.note = UI.Text(review.panel, "", "GameFontDisable")
  review.note:SetPoint("BOTTOMLEFT", 16, 50)
  review.note:SetPoint("BOTTOMRIGHT", -16, 50)
  review.note:SetJustifyH("LEFT")
  review.note:SetJustifyV("BOTTOM")
  if review.note.SetMaxLines then review.note:SetMaxLines(2) end
  -- Back / Apply in their own zone, so Tab cycles list <-> buttons.
  review.buttons = CreateFrame("Frame", nil, review.panel)
  review.buttons:SetPoint("BOTTOMLEFT", 0, 0)
  review.buttons:SetPoint("BOTTOMRIGHT", 0, 0)
  review.buttons:SetHeight(48)
  review.buttons.acTabGroup = "reviewButtons"
  review.apply = UI.PrimaryPrompt(review.buttons, "PAD4", "Apply", function() Commit() end, 300)
  UI.Name(review.apply, "acApply")
  review.apply.acId = "review:apply"
  review.apply:SetPoint("BOTTOMRIGHT", -16, 12)
  review.back = UI.Prompt(review.buttons, "PAD2", "Back", function() CloseReview() end)
  review.back:SetPoint("RIGHT", review.apply, "LEFT", -12, 0)
  UI.Name(review.back, "acBack")
  review.back.acId = "review:back"
  UI.Name(review.panel, "acPanel"); UI.Name(review.list, "acList"); UI.Name(review.buttons, "acButtons")
  UI.Name(review.note, "acNote"); UI.Name(review.title, "acTitle")
  review:Hide()
end

local function Build()
  local template = UI.Has("PortraitFrameTemplate") and "PortraitFrameTemplate"
    or (UI.Has("ButtonFrameTemplate") and "ButtonFrameTemplate" or "BasicFrameTemplateWithInset")
  frame = CreateFrame("Frame", "AgentcraftFrame", UIParent, template)
  frame:Hide()
  frame:SetSize(W, H)
  -- Round the root's layout to whole physical pixels (dev/ui-rules.md rule 5);
  -- UI.PixelSnap at the end of Build does every child the same way.
  if frame.SetRoundLayoutToNearestPixel then pcall(frame.SetRoundLayoutToNearestPixel, frame, true) end
  frame:SetFrameStrata("MEDIUM")
  frame:SetToplevel(true)
  frame:SetMovable(true)
  frame:SetClampedToScreen(true)
  frame:EnableMouse(true)
  tinsert(UISpecialFrames, "AgentcraftFrame") -- Escape (and loss of control) closes it
  RestorePosition()
  ApplyScale()
  if type(frame.Inset) == "table" then frame.Inset:Hide() end -- ButtonFrameTemplate fallback: our own stage replaces it

  if frame.SetTitle then frame:SetTitle("Agentcraft")
  elseif frame.TitleText then frame.TitleText:SetText("Agentcraft")
  else UI.Text(frame, "Agentcraft", "GameFontNormal"):SetPoint("TOP", 0, -6) end
  Portrait()

  -- Drag by the title bar only, so stick moves on a page never move the window.
  local handle = type(frame.TitleContainer) == "table" and frame.TitleContainer or nil
  if not handle then
    handle = CreateFrame("Button", nil, frame)
    handle:SetPoint("TOPLEFT", 0, 0)
    handle:SetPoint("TOPRIGHT", -28, 0)
    handle:SetHeight(22)
  end
  handle:EnableMouse(true)
  handle:RegisterForDrag("LeftButton")
  handle:SetScript("OnDragStart", function() frame:StartMoving() end)
  handle:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    if frame.SetUserPlaced then pcall(frame.SetUserPlaced, frame, false) end
    SavePosition()
  end)
  if type(frame.CloseButton) == "table" then UI.Node(frame.CloseButton, { style = "button", id = "close" }); frame.CloseButton.acSkip = true end

  BuildHeader()
  BuildStage()
  BuildPromptBar()
  BuildTabs()
  BuildLayers()

  -- Input: the shared focus, Back stack, override bindings, Gamepad UI glue.
  Focus:SetHost(frame, function() return current end)
  Focus.onInspect = InspectNode
  -- Focus moved between zones (stage, Inspector, ...): re-aim the right stick
  -- at the page's ScrollRegion for that zone and refresh the B label, so
  -- "Back" shows while B would step out of the Inspector.
  Focus.onZoneChange = function(node)
    if not frame:IsShown() or not current then return end
    local region = ScrollRegionFor(current, node)
    Input.SyncSmartNav(node, region)
    LayoutPrompts()
  end
  Input.Setup(frame)
  Input.scrollRegionFn = function()
    if not frame:IsShown() or not current then return nil end
    return ScrollRegionFor(current, Focus.current)
  end
  Input.handlers.page = function(delta) Step(delta) end
  Input.handlers.pageIndex = function(i)
    local list = SortedPages()
    if list[i] and list[i] ~= current then Select(list[i]) end
  end
  Input.handlers.primary = DoPrimary
  Input.handlers.view = function() CycleView(1) end
  Input.handlers.search = function()
    if current and current.Search then pcall(current.Search, current) end
  end
  Input.handlers.close = function() HideWindow() end
  Input.onPrompts = LayoutPrompts
  Input.onCombat = SetCombat
  frame.FocusGamepad = function() Input.SetPadFocus(true) end
  frame.UnfocusGamepad = function() Input.SetPadFocus(false) end
  frame.SmartNavigationCloseHandler = function()
    local popped = Esc.Pop(true)
    LayoutPrompts()
    return popped
  end

  -- Keep the open page current while you play.
  local pending
  for _, ev in ipairs({ "ACTIONBAR_SLOT_CHANGED", "UPDATE_BINDINGS", "BAG_UPDATE_DELAYED", "SPELLS_CHANGED",
                        "PLAYER_EQUIPMENT_CHANGED", "PET_BAR_UPDATE", "PLAYER_LEVEL_UP", "UNIT_PORTRAIT_UPDATE" }) do
    pcall(frame.RegisterEvent, frame, ev)
  end
  frame:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LEVEL_UP" then C_Timer.After(0.5, CharLine) end
    if event == "UNIT_PORTRAIT_UPDATE" then
      if unit == "player" then Portrait() end
      return
    end
    if pending or not frame:IsShown() then return end
    pending = true
    C_Timer.After(0.2, function()
      pending = false
      if frame:IsShown() then Refresh() end
    end)
  end)
  frame:HookScript("OnShow", function(self)
    CharLine()
    ApplyScale()
    inCombat = InCombatLockdown() and true or false
    if banner then banner:SetShown(inCombat) end
    if summaryBtn then summaryBtn:SetAlpha(inCombat and 0 or 1) end
    if not inCombat then
      self:EnableKeyboard(true)
      Input.Apply()
      local fcm = type(GamepadMode) == "table" and GamepadMode.FrameControlsManager
      if fcm and fcm.FrameShown then pcall(fcm.FrameShown, fcm, self) end
    end
    UI.Sound("open")
    if current and current.OnShow then pcall(current.OnShow, current) end
    if current then Refresh() end
    Focus:Restore(true)
    -- No fade-in: the stage used to start at alpha 0 on every open (a flash).
  end)
  frame:HookScript("OnHide", function(self)
    Input.Release()
    -- Close each layer (sheet, pin, page state such as the Options log,
    -- toast) instead of only dropping its Back entry.
    if review and review:IsShown() then CloseReview() end
    if Focus.modal and #Focus.modal > 0 then Focus.modal = {} end
    if Focus.pinned then Focus:Unpin() end
    if current and current.OnHide then pcall(current.OnHide, current) end
    if toast then Esc.Remove("toast"); toast:Hide() end
    Esc.Clear()
    local fcm = type(GamepadMode) == "table" and GamepadMode.FrameControlsManager
    if fcm and fcm.FrameHidden and not InCombatLockdown() then pcall(fcm.FrameHidden, fcm, self) end
    UI.FocusRing:Hide()
    UI.Sound("close")
  end)

  CharLine()
  local first = FirstPage()
  if first then Select(first) end
  -- Crisp pixels (dev/ui-rules.md rule 5): the whole window rounds its
  -- layout to physical pixels. Pages, Inspector blocks and Review rows made
  -- later are snapped when they appear.
  UI.PixelSnap(frame)
end

-- Public -----------------------------------------------------------------------------------

ns.UI.Refresh = function() if frame and frame:IsShown() then Refresh() end end
ns.UI.RunAction = RunAction
ns.UI.ShowResult = function(out) if frame then ShowResult(out) end end
ns.UI.ShowToast = function(text, kind) if frame then ShowToast(text, kind) end end
ns.UI.OpenReview = function() if current and current.Review then OpenReview(current) end end
ns.UI.CloseReview = function() if review then CloseReview() end end
ns.UI.Commit = function() Commit() end
ns.UI.CycleView = CycleView
ns.UI.CurrentPage = function() return current end
ns.UI.Frame = function() return frame end

function ns.ToggleUI()
  if not frame then Build(); ShowWindow(); return end
  if frame:IsShown() then HideWindow() else ShowWindow() end
end

-- Opens the page with this id (or an old id from page.aliases). With focusId,
-- focuses the node whose acId matches (Inspector cross-references).
function ns.OpenPage(id, focusId)
  if not frame then Build() end
  if not frame:IsShown() then ShowWindow() end
  local page = ns.PageById(id)
  if not page then return end
  if page ~= current then Select(page) else Refresh() end
  if focusId then
    page.lastFocusId = focusId
    for _, n in ipairs(Focus:Nodes()) do
      if n.acId == focusId then Focus:Set(n, Focus.source or "key") break end
    end
  end
end

-- Dev helper: opens every page in turn and takes a game screenshot of each,
-- so the window can be reviewed outside the game. The page order is saved
-- in AgentcraftDB.shots (written on the next /reload). Listed in /ac help
-- only with AgentcraftDB.dev = true.
ns.RegisterCommand("shots", "screenshot every page of this window (for reviewing the UI)", function()
  if not Screenshot or not C_Timer then return ns.Print("Screenshots aren't available on this client.") end
  if not frame then Build() end
  ShowWindow()
  local list = SortedPages()
  ns.db.shots = { started = date("%Y-%m-%d %H:%M:%S"), pages = {} }
  local i = 0
  local function Next()
    i = i + 1
    local page = list[i]
    if not page then return ns.Print("Took " .. #list .. " screenshots (Screenshots folder). /reload to save the page list.") end
    Select(page)
    C_Timer.After(0.8, function()
      local ok = pcall(Screenshot)
      table.insert(ns.db.shots.pages, { id = page.id, title = page.title, time = date("%H:%M:%S"), ok = ok })
      C_Timer.After(1.2, Next)
    end)
  end
  Next()
end, { hidden = true })

ns.RegisterCommand("help", "list slash commands", function()
  ns.Print("Commands (/ac alone opens the window):")
  for _, line in ipairs(ns.CommandHelp()) do ns.Out("  " .. line) end
end)

