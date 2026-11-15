-- Options page (dev/ui-spec-v2.md §9.5): a two-column ledger.
--   Left:  MODULES (one switch per module, with its icon and On/Off state)
--          WINDOW  (scale slider, button prompts, motion, sounds, tooltips on
--                   focus, window shortcuts, reset position)
--   Right: one section per tool group (ns.RegisterAction, e.g. Character
--          Snapshot › Save Now), FISHING HELPER (remembered weapons), LOG
--          (Open log ▸ plus the three newest lines).
-- Every row is one 32 px focus node on a zebra stripe; A / Enter / a click
-- toggles, cycles or presses it. A slider or choice row takes Left/Right and
-- hands focus to the next column once it reaches its end, so Left/Right
-- never dead-ends. "Open log" swaps the stage for a Log sub-view (a Back
-- layer: B / Esc returns to the ledger). The Inspector shows the focused
-- row's full description, its slash commands and its last log line.
-- Module logic is untouched: switches call ns.SetModuleEnabled, tools call
-- their registered fn through UI.RunAction, settings write ns.db.
local _, ns = ...
local UI = ns.UI

local COL_W = 332   -- column width
local LEFT_X = 12   -- left column x (stage-local)
local RIGHT_X = 368 -- right column x
local TOP = -12     -- first section title y
local ROW = 32      -- ledger row height
local TITLE_H = 36  -- section title slot (24) + the plate overhang below it (8) + gap
local GAP = 10      -- space before a section title

-- Sidebar order for modules that don't set `order` yet (explicit order wins).
local DEFAULT_ORDER = { ActionBars = 10, Keybinds = 20, Controller = 30, Snapshot = 40, Fishing = 50 }

-- Icons for modules without a page of their own (pages lend theirs), and
-- for modules that share a page (ActionBars and Keybinds both drive the
-- Keyboard page: a spellbook for the bars, a key for the bindings).
local MODULE_ICON = {
  ActionBars = "Interface\\Icons\\INV_Misc_Book_11",
  Keybinds = "Interface\\Icons\\INV_Misc_Key_03",
  Snapshot = "Interface\\Icons\\INV_Misc_Note_01",
  Fishing = "Interface\\Icons\\Trade_Fishing",
}
local GEAR_ICON = "Interface\\Icons\\INV_Misc_Gear_01"
local LOG_ICON = "Interface\\Icons\\INV_Misc_Book_09"

-- Slash commands that belong to a module but don't name it (v1 commands).
local MODULE_COMMANDS = { ActionBars = { "spells" }, Keybinds = { "keys" }, Controller = { "controller" } }

local function Title(mod) return mod.title or mod.name end

local function SortedModules()
  local list, index = {}, {}
  for i, mod in ipairs(ns.order) do list[i] = mod; index[mod] = i end
  local function key(mod) return mod.order or DEFAULT_ORDER[mod.name] or 500 end
  table.sort(list, function(a, b)
    if key(a) ~= key(b) then return key(a) < key(b) end
    return index[a] < index[b]
  end)
  return list
end

-- Tool actions grouped by section, sections in order of first appearance.
local function ToolGroups()
  local groups, byName = {}, {}
  for _, a in ipairs(ns.actions) do
    local g = byName[a.section]
    if not g then
      local mod = ns.ModuleOf(a.section)
      g = { name = a.section, mod = mod, title = mod and Title(mod) or a.section, items = {} }
      byName[a.section] = g
      groups[#groups + 1] = g
    end
    table.insert(g.items, a)
  end
  return groups
end

-- The page a module drives (its side tab), or nil.
local function PageOf(mod)
  for _, p in ipairs(ns.pages) do
    local m = p.module
    if m == mod.name then return p end
    if type(m) == "table" then
      for _, k in ipairs(m) do if k == mod.name then return p end end
    end
  end
end

local function ModuleIcon(mod)
  if not mod then return GEAR_ICON end
  if mod.icon then return mod.icon end
  if MODULE_ICON[mod.name] then return MODULE_ICON[mod.name] end
  local p = PageOf(mod)
  if p and type(p.icon) == "string" and not p.icon:find("^atlas:") then return p.icon end
  return GEAR_ICON
end

-- "/ac ..." lines for a module: on/off plus its own commands.
local function ModuleCommands(mod)
  local out, seen = {}, {}
  local function add(c)
    if not c or seen[c.name] or c.hidden then return end
    seen[c.name] = true
    out[#out + 1] = { "/ac " .. (c.usage or c.name), c.help }
  end
  for _, name in ipairs(MODULE_COMMANDS[mod.name] or {}) do add(ns.commands[name]) end
  local names = {}
  for name, c in pairs(ns.commands) do if c.module == mod.name then names[#names + 1] = name end end
  table.sort(names)
  for _, name in ipairs(names) do add(ns.commands[name]) end
  local low = mod.name:lower()
  out[#out + 1] = { "/ac on " .. low, "turn it on" }
  out[#out + 1] = { "/ac off " .. low, "turn it off" }
  return out
end

-- The newest log line that mentions any of the words, or nil.
local function LastLogLine(words)
  for i = #ns.log, 1, -1 do
    local line = ns.log[i]
    for _, w in ipairs(words) do
      if w and w ~= "" and line:find(w, 1, true) then return line end
    end
  end
end

-- Inspector blocks shared by every row.
local function InspectCommands(pane, list)
  if not list or #list == 0 then return end
  pane:Section("Slash commands")
  for _, c in ipairs(list) do
    local help = c[2] and ("  " .. UI.C.GRAY:WrapTextInColorCode(c[2])) or ""
    pane:Text(UI.C.NORMAL:WrapTextInColorCode(c[1]) .. help)
  end
end

local function InspectLastLine(pane, words)
  local line = LastLogLine(words)
  if not line then return end
  pane:Section("Last message")
  pane:Text(line)
end

local function SetSetting(k, v)
  if ns.db then ns.db[k] = v end
end

-- Rows ----------------------------------------------------------------------------------

-- Zebra stripe: Line-Bounce, Line-Bounce2 on even rows (Bounce at .45 when the
-- client lacks Bounce2), else a faint flat stripe.
local function Zebra(tex, index)
  local even = index % 2 == 0
  if UI.SetAtlas(tex, even and UI.ART.zebra2 or UI.ART.zebra) then
    tex:SetAlpha((even and not UI.HasAtlas("UI-Character-Info-Line-Bounce2")) and 0.45 or 1)
  else
    tex:SetTexture(UI.WHITE); tex:SetVertexColor(1, 1, 1, even and 0.03 or 0.06)
  end
end

-- Moves the focus to row when the mouse enters one of its child controls
-- (check box, slider, steppers, button), so the Inspector follows.
local function FocusOnEnter(row, child)
  if type(child) ~= "table" or not child.HookScript then return end
  child:HookScript("OnEnter", function()
    if ns.Focus and ns.Focus.Set then ns.Focus:Set(row, "mouse") end
  end)
end

-- A 32 px ledger row: a Button that is one focus node ("row" ring).
-- opts: id, label, icon, aLabel (prompt label for A while focused).
local function NewRow(page, parent, x, y, zebra, opts)
  local r = CreateFrame("Button", nil, parent)
  r:SetSize(COL_W, ROW)
  r:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
  r.bg = r:CreateTexture(nil, "BACKGROUND", nil, 2)
  r.bg:SetAllPoints()
  Zebra(r.bg, zebra)
  local lx = 10
  if opts.box then lx = lx + 30 end
  if opts.icon then
    r.slotBg = r:CreateTexture(nil, "ARTWORK", nil, 1)
    r.slotBg:SetSize(26, 26)
    r.slotBg:SetPoint("LEFT", lx - 2, 0)
    if not UI.SetAtlas(r.slotBg, UI.ART.gearSlot) then r.slotBg:Hide() end
    r.icon = r:CreateTexture(nil, "ARTWORK", nil, 2)
    r.icon:SetSize(22, 22)
    r.icon:SetPoint("CENTER", r.slotBg, "CENTER", 0, 0)
    r.icon:SetTexture(opts.icon)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    lx = lx + 30
  end
  r.label = UI.Text(r, opts.label or "", "GameFontNormal")
  r.label:SetPoint("LEFT", lx, 0)
  r.label:SetJustifyH("LEFT")
  r.label:SetWordWrap(false)
  r.labelX = lx
  UI.Node(r, { style = "row", id = opts.id })
  r.acPromptA = opts.aLabel or "Select"
  r.acOnFocus = function(self)
    if page.promptA ~= self.acPromptA then
      page.promptA = self.acPromptA
      if ns.Input and ns.Input.onPrompts then pcall(ns.Input.onPrompts) end
    end
  end
  return r
end

-- A value on the right edge of a row (state word, count, hint).
local function RowValue(r, font)
  local v = UI.Text(r, "", font or "GameFontHighlight")
  v:SetPoint("RIGHT", r, "RIGHT", -10, 0)
  v:SetJustifyH("RIGHT")
  v:SetWordWrap(false)
  r.label:SetPoint("RIGHT", v, "LEFT", -8, 0)
  r.value = v
  return v
end

-- A check box inside a row (left or right). Mouse clicks on it act like a
-- click on the row; the row is the only focus node. MinimalCheckboxTemplate
-- is the Settings panel's check box art (checkbox-minimal / checkmark-minimal,
-- SettingsCheckboxTemplate) at its own 30x29: its textures use the atlas
-- size, so a smaller frame would only misplace them.
local function RowBox(r, side)
  local box
  if UI.Has("MinimalCheckboxTemplate") then
    box = CreateFrame("CheckButton", nil, r, "MinimalCheckboxTemplate")
  else
    box = CreateFrame("CheckButton", nil, r, "UICheckButtonTemplate")
    box:SetSize(28, 28)
  end
  if side == "right" then box:SetPoint("RIGHT", r, "RIGHT", -6, 0) else box:SetPoint("LEFT", r, "LEFT", 6, 0) end
  box:SetScript("OnClick", function() r:Click() end)
  FocusOnEnter(r, box)
  UI.MarkIgnored(box)
  r.box = box
  return box
end

-- Module switch ---------------------------------------------------------------------------

local function ModuleState(mod)
  if mod.active then return "On", UI.C.GREEN end
  if ns.IsModuleEnabled(mod) then return "Failed to start", UI.C.RED end
  return "Off", UI.C.GRAY
end

local function ToggleModule(mod)
  local on = not mod.active -- a module that failed to start: try again
  UI.Sound(on and "on" or "off")
  -- RunAction logs the result, catches errors and refreshes the window
  -- (the switch goes back to off if the module failed to start).
  UI.RunAction(function()
    if ns.SetModuleEnabled(mod, on) and (mod.active and true or false) == on then
      ns.Print(Title(mod) .. (on and " turned on." or " turned off."))
    end
  end)
end

local function InspectModule(row, pane)
  local mod = row.mod
  local state, color = ModuleState(mod)
  pane:Header(ModuleIcon(mod), Title(mod), "Module")
  pane:Row("State", state, color)
  if mod.description then pane:Text(mod.description) end
  if state == "Failed to start" then
    pane:Text("It failed to start. Press it to try again; the log has the error.", UI.C.RED)
  end
  local p = PageOf(mod)
  if p and p.title then
    pane:CrossRef({ { text = "Open " .. p.title .. "  >", fn = function() ns.OpenPage(p.id) end } })
  end
  InspectCommands(pane, ModuleCommands(mod))
  InspectLastLine(pane, { Title(mod) })
  pane:Buttons({ { label = mod.active and "Turn Off" or "Turn On", fn = function() ToggleModule(mod) end } })
end

local function ModuleRow(page, parent, mod, y, zebra)
  local r = NewRow(page, parent, LEFT_X, y, zebra, { id = "opt:mod:" .. mod.name, label = Title(mod),
    icon = ModuleIcon(mod), box = true, aLabel = "Toggle" })
  RowBox(r, "left")
  RowValue(r)
  r.mod = mod
  r:SetScript("OnClick", function() ToggleModule(mod) end)
  r.acInspect = InspectModule
  -- Right steps into this module's Inspector (Open <page>, Turn On/Off), so the
  -- pad reaches them without Tab; B there comes back to the row. Without
  -- Inspector nodes the move stays spatial (on to the tools column).
  r.navRight = function(self)
    local F = ns.Focus
    if not (F and F.Nodes and F.ZoneOf) then return nil end
    if not F.pinned and F.inspected ~= self and F.Inspect then F:Inspect(self) end
    local best, bestTop
    for _, n in ipairs(F:Nodes()) do
      if F.ZoneOf(n) == "inspector" then
        local top = n.GetTop and n:GetTop() or 0
        if not bestTop or top > bestTop then best, bestTop = n, top end
      end
    end
    return best
  end
  r.acTip = function(self)
    UI.ShowTooltip(self, Title(mod), mod.description or "")
  end
  r:HookScript("OnLeave", function() if GameTooltip_Hide then GameTooltip_Hide() end end)
  function r.Sync(self)
    local state, color = ModuleState(mod)
    self.box:SetChecked(mod.active and true or false)
    self.value:SetText(state)
    self.value:SetTextColor(UI.RGB(color))
  end
  table.insert(page.rows, r)
  return r
end

-- Window settings ------------------------------------------------------------------------------

-- Setting rows: description and commands for the Inspector.
local INFO = {
  scale = { "Window scale", "How big this window is, from 0.80 to 1.25. With the Gamepad UI the automatic scale is 1.10. "
    .. "The window and its side tabs always fit on screen.", { { "/ac scale [0.8-1.25]", "no number: automatic" }, { "/ac reset", "centre and automatic scale" } } },
  prompts = { "Button prompts", "Which button pictures the prompt bar and the side tabs show. Automatic follows the device "
    .. "you used last (controller glyphs while the Gamepad UI is on). Keyboard always shows keys; Controller always shows A, B, X and Y." },
  motion = { "Motion", "Full: glow pulses and short focus fades on highlights. Reduced: no pulses, for a low frame rate or if motion bothers you." },
  sound = { "Sounds", "Interface sounds: page turns, focus ticks, switches and the chime when changes are applied." },
  focusTips = { "Tooltips on focus", "Also show the game tooltip when the keyboard or controller focus lands on something. "
    .. "This panel always explains the focused item, so it's off by default." },
  shortcuts = { "Window shortcuts", "While this window is open: Ctrl+Tab and Ctrl+Shift+Tab switch pages, Ctrl+1 to Ctrl+5 open a page, "
    .. "Ctrl+Enter reviews and applies, Ctrl+Space changes the view and Ctrl+F searches. Turn them off if one clashes with your own key bindings." },
  reset = { "Reset position", "Centres the window and goes back to the automatic scale.", { { "/ac reset" } } },
}

local function InspectSetting(row, pane)
  local info = INFO[row.key]
  pane:Header(GEAR_ICON, info[1], "Window setting")
  if row.ValueText then pane:Row("Now", row:ValueText(), UI.C.HIGHLIGHT) end
  pane:Text(info[2])
  if row.hint then pane:Text(row.hint, UI.C.GRAY) end
  InspectCommands(pane, info[3])
  InspectLastLine(pane, { info[1] })
end

local function SettingRow(page, parent, key, y, zebra, aLabel)
  local r = NewRow(page, parent, LEFT_X, y, zebra, { id = "opt:set:" .. key, label = INFO[key][1], aLabel = aLabel })
  r.key = key
  r.acInspect = InspectSetting
  table.insert(page.rows, r)
  return r
end

-- On/off setting with a check box on the right.
local function ToggleSetting(page, parent, key, y, zebra, onChange)
  local r = SettingRow(page, parent, key, y, zebra, "Toggle")
  RowBox(r, "right")
  r.label:SetPoint("RIGHT", r.box, "LEFT", -8, 0)
  r:SetScript("OnClick", function(self)
    local on = not ns.Setting(key)
    SetSetting(key, on)
    if onChange then pcall(onChange, on) end
    UI.Sound(on and "on" or "off")
    self:Sync()
    if ns.Focus and ns.Focus.current == self then ns.Focus:Inspect(self) end
  end)
  function r.ValueText() return ns.Setting(key) and "On" or "Off" end
  function r.Sync(self) self.box:SetChecked(ns.Setting(key) and true or false) end
  return r
end

-- Choice setting: the Settings panel's dropdown (WowStyle1DropdownTemplate);
-- without it ◀ Value ▶ with the slider's stepper buttons. A cycles (wraps),
-- Left/Right step and hand focus on at either end.

-- A stepper button as MinimalSliderWithSteppersTemplate draws it: the atlas
-- at its own size, no highlight; disabled at 0.5 alpha and desaturated
-- (SetStepperButtonEnabled in MinimalSlider.lua).
local function SetStepperEnabled(b, on)
  if b.acOn == on then return end
  b.acOn = on
  b:SetEnabled(on)
  b:SetAlpha(on and 1 or 0.5)
  if b.art then b.art:SetDesaturated(not on) end
end

local function Arrow(r, atlas, text)
  local b = CreateFrame("Button", nil, r)
  if UI.HasAtlas(atlas) then
    b.art = b:CreateTexture(nil, "BACKGROUND")
    b.art:SetAtlas(atlas, true)
    b.art:SetPoint("CENTER")
    local w, h = UI.AtlasSize(atlas)
    b:SetSize(w or 11, h or 19)
  else
    b:SetSize(16, 20)
    b.fs = UI.Text(b, text, "GameFontNormal")
    b.fs:SetPoint("CENTER")
  end
  FocusOnEnter(r, b)
  UI.MarkIgnored(b)
  return b
end

local function ChoiceSetting(page, parent, key, y, zebra, choices, onChange)
  local r = SettingRow(page, parent, key, y, zebra, "Change")
  r.choices = choices
  local function Index()
    local v = ns.Setting(key)
    for i, c in ipairs(choices) do if c[1] == v then return i end end
    return 1
  end
  local function Choose(i)
    i = math.max(1, math.min(#choices, i))
    if choices[i][1] == ns.Setting(key) then return end
    SetSetting(key, choices[i][1])
    if onChange then pcall(onChange, choices[i][1]) end
    UI.Sound("view")
    r:Sync()
    if ns.Focus and ns.Focus.current == r then ns.Focus:Inspect(r) end
  end
  if UI.Has("WowStyle1DropdownTemplate") then
    r.dropdown = UI.Dropdown(r, function(_, root)
      for i, c in ipairs(choices) do
        root:CreateRadio(c[2], function(j) return Index() == j end, function(j) Choose(j) end, i)
      end
    end, 140)
    r.dropdown:SetPoint("RIGHT", r, "RIGHT", -10, 0)
    r.label:SetPoint("RIGHT", r.dropdown, "LEFT", -8, 0)
    FocusOnEnter(r, r.dropdown)
    UI.MarkIgnored(r.dropdown)
  else
    r.next = Arrow(r, "Minimal_SliderBar_Button_Right", ">")
    r.next:SetPoint("RIGHT", r, "RIGHT", -12, 0)
    r.valueFs = UI.Text(r, "", "GameFontHighlight")
    r.valueFs:SetWidth(96)
    r.valueFs:SetJustifyH("CENTER")
    r.valueFs:SetWordWrap(false)
    r.valueFs:SetPoint("RIGHT", r.next, "LEFT", -6, 0)
    r.prev = Arrow(r, "Minimal_SliderBar_Button_Left", "<")
    r.prev:SetPoint("RIGHT", r.valueFs, "LEFT", -6, 0)
    r.label:SetPoint("RIGHT", r.prev, "LEFT", -8, 0)
    r.prev:SetScript("OnClick", function() Choose(Index() - 1) end)
    r.next:SetScript("OnClick", function() Choose(Index() + 1) end)
  end
  r:SetScript("OnClick", function() Choose(Index() % #choices + 1) end)
  -- Left/Right step the choice; at an end they fall through to spatial
  -- navigation (the other column), so focus never gets stuck.
  r.navLeft = function() if Index() > 1 then Choose(Index() - 1) return false end end
  r.navRight = function() if Index() < #choices then Choose(Index() + 1) return false end end
  function r.ValueText() return choices[Index()][2] end
  -- Changes only what changed: the dropdown regenerates its text only when
  -- the value moved.
  function r.Sync(self)
    local i = Index()
    if self.synced == i then return end
    self.synced = i
    if self.dropdown then
      if self.dropdown.GenerateMenu then self.dropdown:GenerateMenu() end
      return
    end
    self.valueFs:SetText(choices[i][2])
    SetStepperEnabled(self.prev, i > 1)
    SetStepperEnabled(self.next, i < #choices)
  end
  return r
end

local SCALE_MIN, SCALE_MAX, SCALE_STEP = 0.8, 1.25, 0.05

local function ScaleRow(page, parent, y, zebra)
  local r = SettingRow(page, parent, "scale", y, zebra, "Automatic")
  r.hint = "Left and Right change it in steps of 0.05; A goes back to the automatic scale."
  local function Set(v)
    v = math.max(SCALE_MIN, math.min(SCALE_MAX, math.floor(v / SCALE_STEP + 0.5) * SCALE_STEP))
    local before, saved = UI.GetScale(), ns.db and ns.db.scale
    if math.abs(v - before) < 0.001 then return false end
    UI.SetScale(v)
    -- Clamped by the screen size: nothing changed, so let focus move on.
    if math.abs(UI.GetScale() - before) < 0.001 then
      if ns.db then ns.db.scale = saved end
      return false
    end
    page.syncing = true
    r.slider:SetSliderValue(UI.GetScale())
    page.syncing = false
    if ns.Focus and ns.Focus.current == r then ns.Focus:Inspect(r) end
    return true
  end
  r.slider = UI.Slider(r, SCALE_MIN, SCALE_MAX, SCALE_STEP, UI.GetScale(), function(v)
    if page.syncing or math.abs(v - UI.GetScale()) < 0.001 then return end
    UI.SetScale(v)
  end, 150)
  r.slider:SetPoint("RIGHT", r, "RIGHT", -46, 0)
  r.label:SetPoint("RIGHT", r.slider, "LEFT", -8, 0)
  -- SmartNavigation lands on the row, not on the slider or its steppers.
  if type(r.slider.Slider) == "table" then UI.MarkIgnored(r.slider.Slider); FocusOnEnter(r, r.slider.Slider) end
  FocusOnEnter(r, r.slider)
  FocusOnEnter(r, r.slider.Back)
  FocusOnEnter(r, r.slider.Forward)
  r:SetScript("OnClick", function()
    UI.SetScale(nil)
    UI.Sound("view")
    page.syncing = true
    r.slider:SetSliderValue(UI.GetScale())
    page.syncing = false
    if ns.Focus and ns.Focus.current == r then ns.Focus:Inspect(r) end
  end)
  r.navLeft = function() if Set(UI.GetScale() - SCALE_STEP) then return false end end
  r.navRight = function() if Set(UI.GetScale() + SCALE_STEP) then return false end end
  function r.ValueText()
    return string.format("%.2f", UI.GetScale()) .. ((ns.db and ns.db.scale) and "" or " (automatic)")
  end
  function r.Sync()
    page.syncing = true
    r.slider:SetSliderValue(UI.GetScale())
    page.syncing = false
  end
  return r
end

local function ResetRow(page, parent, y, zebra)
  local r = SettingRow(page, parent, "reset", y, zebra, "Reset")
  r.hint = nil
  -- An action, so a panel button as on the tool rows (grey text read as a
  -- disabled value). The row stays the one focus node; A presses it.
  local b = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
  b:SetText("Reset")
  b:SetHeight(24)
  UI.FitButton(b, 84)
  b:SetPoint("RIGHT", r, "RIGHT", -8, 0)
  FocusOnEnter(r, b)
  UI.MarkIgnored(b)
  r.button = b
  r.label:SetPoint("RIGHT", b, "LEFT", -8, 0)
  local function Reset()
    UI.RunAction(function()
      UI.ResetPosition()
      ns.Print("Window position and scale reset.")
    end)
  end
  b:SetScript("OnClick", Reset)
  r:SetScript("OnClick", Reset)
  return r
end

-- Right column: tools, fishing, log ---------------------------------------------------------------

-- A tool row: its status on the left (two lines allowed), the action as a
-- button on the right. A on the row presses the button.
local function ToolStatus(a)
  local gated, mod = ns.IsGated(a.module)
  if gated then return UI.C.GRAY:WrapTextInColorCode(Title(mod) .. " is turned off."), true end
  if a.status then
    local ok, v = pcall(a.status)
    if not ok then return UI.C.RED:WrapTextInColorCode("Status failed: " .. tostring(v)) end
    return v or ""
  end
  return type(a.tooltip) == "string" and a.tooltip or ""
end

local function InspectTool(row, pane)
  local a, g = row.action, row.group
  pane:Header(ModuleIcon(g.mod), a.label, g.title)
  local status = ToolStatus(a)
  if status ~= "" then pane:Text(status) end
  if type(a.tooltip) == "string" and a.tooltip ~= status then pane:Text(a.tooltip, UI.C.GRAY) end
  if g.mod then InspectCommands(pane, ModuleCommands(g.mod)) end
  InspectLastLine(pane, { a.label, g.title })
  local gated = ns.IsGated(a.module)
  pane:Buttons({ { label = a.label, fn = function() UI.RunAction(a.fn) end, enabled = not gated } })
end

local function ToolRow(page, parent, g, a, y, zebra)
  local r = NewRow(page, parent, RIGHT_X, y, zebra, { id = "opt:tool:" .. g.name .. ":" .. a.label, label = "",
    aLabel = a.label })
  local b = CreateFrame("Button", nil, r, "UIPanelButtonTemplate")
  b:SetText(a.label)
  b:SetHeight(24)
  UI.FitButton(b, 84)
  b:SetPoint("RIGHT", r, "RIGHT", -8, 0)
  b:SetScript("OnClick", function() UI.RunAction(a.fn) end)
  FocusOnEnter(r, b)
  UI.MarkIgnored(b)
  r.button = b
  r.label:SetFontObject("GameFontHighlightSmall")
  r.label:SetWordWrap(true)
  r.label:SetMaxLines(2)
  r.label:SetPoint("RIGHT", b, "LEFT", -8, 0)
  r.action, r.group = a, g
  r:SetScript("OnClick", function() if b:IsEnabled() then b:Click() end end)
  r.acInspect = InspectTool
  function r.Sync(self)
    local text, gated = ToolStatus(a)
    self.label:SetText(text)
    self.button:SetEnabled(not gated)
    self.acPromptA = gated and "Select" or a.label
  end
  table.insert(page.rows, r)
  return r
end

-- The weapons the Fishing Helper puts back (ns.charDB.weapons).
local function Weapons()
  local w = ns.charDB and ns.charDB.weapons
  if type(w) ~= "table" or not w.main then return nil end
  local list = {}
  for _, id in ipairs({ w.main, w.off }) do
    if id then list[#list + 1] = { id = id, icon = UI.ItemIcon(id), name = UI.ItemName(id) } end
  end
  return list
end

local function InspectFishing(row, pane)
  local mod = row.mod
  local state, color = ModuleState(mod)
  pane:Header(ModuleIcon(mod), "Remembered weapons", Title(mod))
  pane:Row("Fishing Helper", state, color)
  local list = Weapons()
  if list then
    for i, w in ipairs(list) do pane:Row(i == 1 and "Main hand" or "Off hand", w.name or ("item " .. w.id), UI.C.HIGHLIGHT, w.icon) end
    pane:Text("These go back on 15 seconds after your last cast ends, or when you mount.")
  else
    pane:Empty("Not seen yet. Equip your weapons once and they're remembered.")
  end
  InspectLastLine(pane, { "weapon", "lure", "Lure" })
end

local function FishingRow(page, parent, mod, y, zebra)
  local r = NewRow(page, parent, RIGHT_X, y, zebra, { id = "opt:fishing", label = "Remembered weapons" })
  r.mod = mod
  r.acReadable = true
  r.weapons = {}
  for i = 1, 2 do
    local t = r:CreateTexture(nil, "ARTWORK", nil, 2)
    t:SetSize(22, 22)
    t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    t:SetPoint("RIGHT", r, "RIGHT", -10 - (2 - i) * 26, 0)
    t:Hide()
    r.weapons[i] = t
  end
  r.none = UI.Text(r, "Not seen yet", "GameFontDisable")
  r.none:SetPoint("RIGHT", r, "RIGHT", -10, 0)
  r.label:SetPoint("RIGHT", r, "RIGHT", -70, 0)
  r:SetScript("OnClick", function() end)
  r.acInspect = InspectFishing
  function r.Sync(self)
    local list = Weapons() or {}
    -- Right-aligned: a lone main hand sits in the rightmost spot.
    local shown = { list[#list - 1], list[#list] }
    for i, t in ipairs(self.weapons) do
      local w = shown[i]
      if w then t:SetTexture(w.icon or UI.QUESTION); t:Show() else t:Hide() end
    end
    self.none:SetShown(#list == 0)
  end
  table.insert(page.rows, r)
  return r
end

-- Log -------------------------------------------------------------------------------------------

local function ClearLog(page)
  wipe(ns.log)
  page.logKey = nil
  UI.Refresh()
end

local function InspectLog(row, pane)
  local page = row.page
  pane:Header(LOG_ICON, "Log", string.format("%d message%s", #ns.log, #ns.log == 1 and "" or "s"))
  pane:Text("Everything Agentcraft printed, newest first: results, errors and what changed. "
    .. "In the log, select text with the mouse and press Ctrl+C to copy it.")
  if ns.log[#ns.log] then
    pane:Section("Newest")
    pane:Text(ns.log[#ns.log])
  end
  pane:Buttons({
    { label = "Open Log", fn = function() page:OpenLog() end },
    { label = "Clear Log", fn = function() ClearLog(page) end, enabled = #ns.log > 0 },
  })
end

local function LogRow(page, parent, y, zebra)
  local r = NewRow(page, parent, RIGHT_X, y, zebra, { id = "opt:log", label = "Open log", icon = LOG_ICON, aLabel = "Open" })
  r.page = page
  local v = RowValue(r, "GameFontHighlightSmall")
  r:SetScript("OnClick", function() page:OpenLog() end)
  r.acInspect = InspectLog
  function r.Sync(self)
    local n = #ns.log
    v:SetText(string.format("%d line%s  >", n, n == 1 and "" or "s"))
  end
  table.insert(page.rows, r)
  return r
end

-- The three newest log lines under the Log row (display only).
local PREVIEW = 3
local function LogPreview(page, parent, y)
  page.preview = {}
  for i = 1, PREVIEW do
    local fs = UI.Text(parent, "", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", RIGHT_X + 10, y - 6 - (i - 1) * 18)
    fs:SetWidth(COL_W - 20)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    fs:SetAlpha(1 - (i - 1) * 0.22)
    page.preview[i] = fs
  end
  return y - PREVIEW * 18 - 6
end

-- Controls legend (display only): controller glyphs on the left, keyboard
-- keys on the right, what they do on this page in between.
local LEGEND = {
  { { "PADDPAD" }, "Move between rows", { "Arrows" } },
  { { "PAD1" }, "Toggle, change or press", { "Enter" } },
  { { "PADDLEFT", "PADDRIGHT" }, "Step a slider or choice", { "Left", "Right" } },
  { { "PAD2" }, "Back · close", { "Esc" } },
  { { "PADLSHOULDER", "PADRSHOULDER" }, "Other pages", { "Ctrl+Tab" } },
}
local LEGEND_ROW = 24

local function Legend(page, parent, y)
  page.legend = {}
  for i, e in ipairs(LEGEND) do
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(COL_W, LEGEND_ROW)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", RIGHT_X, y - (i - 1) * LEGEND_ROW)
    local x = 10
    for _, k in ipairs(e[1]) do
      local g = UI.Glyph(row, k, 20, "pad")
      g:SetPoint("LEFT", x, 0)
      x = x + 22
    end
    local label = UI.Text(row, e[2], "GameFontHighlightSmall")
    label:SetPoint("LEFT", 62, 0)
    label:SetJustifyH("LEFT")
    local rx = -10
    for j = #e[3], 1, -1 do
      local cap = UI.Keycap(row, e[3][j], 18)
      cap:SetPoint("RIGHT", row, "RIGHT", rx, 0)
      rx = rx - cap:GetWidth() - 4
    end
    page.legend[i] = row
  end
  return y - #LEGEND * LEGEND_ROW
end

-- Log sub-view: covers the stage; B / Esc / Back returns to the ledger.
-- Scrolls the log one step; false when it is already at that end (or has
-- nothing to scroll), so a D-pad move can leave the well instead.
local function ScrollLog(page, delta)
  local box = page.logBox
  if not box then return false end
  local sb = box.GetScrollBox and box:GetScrollBox()
  if sb and sb.ScrollInDirection and sb.GetWheelPanPercentage then
    if sb.HasScrollableExtent and not sb:HasScrollableExtent() then return false end
    local pct = sb.GetScrollPercentage and sb:GetScrollPercentage()
    if pct and ((delta < 0 and pct <= 0.001) or (delta > 0 and pct >= 0.999)) then return false end
    pcall(sb.ScrollInDirection, sb, sb:GetWheelPanPercentage(), delta > 0 and 1 or -1)
    return true
  elseif box.GetVerticalScroll and box.SetVerticalScroll then
    local range = box.GetVerticalScrollRange and box:GetVerticalScrollRange() or 0
    local cur = box:GetVerticalScroll()
    local to = math.max(0, math.min(range, cur + delta * 42))
    if math.abs(to - cur) < 0.5 then return false end
    box:SetVerticalScroll(to)
    return true
  end
  return false
end

-- The Inspector node nearest the well's vertical centre (Right from the log).
local function NearestInspectorNode(node)
  local F = ns.Focus
  if not (F and F.ScreenRect and F.Nodes and F.ZoneOf) then return nil end
  local _, b, _, h = F.ScreenRect(node)
  if not b then return nil end
  local cy, best, bestD = b + h / 2, nil, nil
  for _, n in ipairs(F:Nodes()) do
    if F.ZoneOf(n) == "inspector" then
      local _, nb, _, nh = F.ScreenRect(n)
      if nb then
        local d = math.abs(nb + nh / 2 - cy)
        if not bestD or d < bestD then best, bestD = n, d end
      end
    end
  end
  return best
end

local function BuildLogView(page, stage)
  local v = CreateFrame("Frame", nil, stage)
  v:SetAllPoints(stage)
  v:Hide()
  page.logView = v
  UI.SectionTitle(v, "LOG", LEFT_X, TOP, 688)
  -- The hint sits between Back and Clear Log, off the title plate (on the
  -- plate it ran over the right ornament and past the plate's end).
  local hint = UI.Text(v, "Newest first · select text and press Ctrl+C to copy", "GameFontHighlightSmall")
  hint:SetPoint("BOTTOM", v, "BOTTOM", 0, 21)
  hint:SetWidth(440)
  hint:SetJustifyH("CENTER")
  hint:SetWordWrap(false)
  hint:SetTextColor(0.7, 0.7, 0.7)
  -- The log well is the focus node: Up/Down scroll it, Left/Right leave.
  local well = CreateFrame("Button", nil, v)
  well:SetPoint("TOPLEFT", v, "TOPLEFT", LEFT_X, TOP - TITLE_H - 2)
  well:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -LEFT_X, 50)
  -- A dark fill under the inset border: InsetFrameTemplate's own Bg is
  -- translucent, and the stat parchment's light bands read through it.
  well.fill = UI.Flat(well, "BACKGROUND", 0.03, 0.026, 0.022, 0.94)
  well.fill:SetPoint("TOPLEFT", 2, -2)
  well.fill:SetPoint("BOTTOMRIGHT", -2, 2)
  well.inset = UI.Inset(well)
  well.inset:SetAllPoints()
  well:EnableMouse(false) -- the edit box inside takes the mouse (selection)
  page.logBox = UI.LogBox(well)
  UI.Node(well, { style = "row", id = "opt:logview" })
  well.acReadable = true
  well.acPromptA = "Back"
  well.acOnFocus = function(self)
    if page.promptA ~= self.acPromptA then
      page.promptA = self.acPromptA
      if ns.Input and ns.Input.onPrompts then pcall(ns.Input.onPrompts) end
    end
  end
  well:SetScript("OnClick", function() page:CloseLog() end)
  -- Up/Down scroll; at either end the move leaves the well (strip above,
  -- Back / Clear Log below). Right goes to the Inspector's buttons.
  well.navUp = function() if ScrollLog(page, -1) then return false end end
  well.navDown = function() if ScrollLog(page, 1) then return false end end
  well.navRight = NearestInspectorNode
  well.acInspect = function(_, pane)
    pane:Header(LOG_ICON, "Log", string.format("%d message%s", #ns.log, #ns.log == 1 and "" or "s"))
    pane:Text("Up and Down scroll the log. B or Escape goes back to Options.")
    pane:Text("With a mouse, select text in the log and press Ctrl+C to copy it.", UI.C.GRAY)
    pane:Buttons({
      { label = "Back", fn = function() page:CloseLog() end },
      { label = "Clear Log", fn = function() ClearLog(page) end, enabled = #ns.log > 0 },
    })
  end
  page.logWell = well
  -- Buttons under the well (mouse and spatial focus).
  local back = UI.Button(v, "Back", 96, function() page:CloseLog() end, nil, 26)
  back:SetPoint("BOTTOMLEFT", v, "BOTTOMLEFT", LEFT_X, 14)
  back.acId = "opt:logback"
  local clear = UI.Button(v, "Clear Log", 110, function() ClearLog(page) end, nil, 26)
  clear:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -LEFT_X, 14)
  clear.acId = "opt:logclear"
  page.logClear = clear
  -- In the log view the Inspector always explains the log, whichever of its
  -- controls has focus (its Back / Clear Log stay put while you move).
  back.acInspect, clear.acInspect = well.acInspect, well.acInspect
  -- One row: Back <-> Clear Log, then on to the Inspector.
  back.navRight = function() if clear:IsShown() and clear:IsEnabled() then return clear end end
  clear.navLeft = back
  clear.navRight = NearestInspectorNode
end

-- Refresh ------------------------------------------------------------------------------------------

-- The log text only changes when an entry was added or removed, so a
-- selection survives the refreshes that bag and spell events trigger.
local function RefreshLog(page)
  local n = #ns.log
  for i, fs in ipairs(page.preview) do
    local line = ns.log[n - i + 1]
    if i == 1 and not line then line = UI.C.GRAY:WrapTextInColorCode("Messages from Agentcraft appear here.") end
    fs:SetText(line or "")
  end
  if page.logClear then page.logClear:SetEnabled(n > 0) end
  if not (page.logView and page.logView:IsShown()) then return end
  local key = n .. "\0" .. (ns.log[n] or "")
  if page.logKey == key then return end
  page.logKey = key
  local lines = {}
  for i = n, 1, -1 do lines[#lines + 1] = ns.log[i] end
  page.logBox:SetTextIfChanged(n > 0 and table.concat(lines, "\n") or "Messages from Agentcraft appear here.")
end

local function Background(stage)
  -- Forever: the character sheet's stat parchment; elsewhere a dark plate.
  -- Both get a soft vertical shade at the foot (our own art). The stat
  -- pane's StoneBG3 is not used: Blizzard pins it at its atlas size to the
  -- pane's top, and stretched across the stage foot it drew a smeared band
  -- through the Controls legend and the log well.
  local bg = stage:CreateTexture(nil, "BACKGROUND", nil, 1)
  bg:SetPoint("TOPLEFT", 3, -3)
  bg:SetPoint("BOTTOMRIGHT", -3, 3)
  if not UI.SetAtlas(bg, UI.ART.statBg) then
    bg:SetTexture(UI.WHITE); bg:SetVertexColor(0.07, 0.065, 0.06, 0.9)
  end
  local shade = UI.Gradient(stage, "BACKGROUND", "VERTICAL", { 0, 0, 0, 0.5 }, { 0, 0, 0, 0.05 }, 3)
  shade:SetPoint("BOTTOMLEFT", 3, 3)
  shade:SetPoint("BOTTOMRIGHT", -3, 3)
  shade:SetHeight(140)
end

ns.RegisterPage({
  id = "options",
  aliases = { "settings" }, -- the v1 id: saved lastPage and /ac settings keep working
  title = "Options",
  icon = GEAR_ICON,
  order = 1000,
  api = 2,
  description = "Turn modules on or off, size the window, choose button prompts, motion and sounds, run tools and read the log.",

  Build = function(page, stage)
    page.rows = {}
    Background(stage)
    local ledger = CreateFrame("Frame", nil, stage)
    ledger:SetAllPoints(stage)
    page.ledger = ledger

    -- Column divider.
    local div = ledger:CreateTexture(nil, "ARTWORK")
    div:SetPoint("TOP", ledger, "TOPLEFT", (LEFT_X + COL_W + RIGHT_X) / 2, -10)
    div:SetPoint("BOTTOM", ledger, "BOTTOMLEFT", (LEFT_X + COL_W + RIGHT_X) / 2, 10)
    div:SetWidth(8)
    if not UI.SetAtlas(div, UI.ART.divider) then
      div:SetTexture(UI.WHITE); div:SetVertexColor(0.9, 0.62, 0.32, 0.3); div:SetWidth(1)
    end

    -- Left column: modules, then window settings.
    local y = TOP
    UI.SectionTitle(ledger, "MODULES", LEFT_X, y, COL_W)
    y = y - TITLE_H
    local z = 0
    page.moduleRows = {}
    for _, mod in ipairs(SortedModules()) do
      z = z + 1
      page.moduleRows[#page.moduleRows + 1] = ModuleRow(page, ledger, mod, y, z)
      y = y - ROW
    end

    y = y - GAP
    UI.SectionTitle(ledger, "WINDOW", LEFT_X, y, COL_W)
    y = y - TITLE_H
    z = 0
    local function nextZ() z = z + 1; return z end
    ScaleRow(page, ledger, y, nextZ()); y = y - ROW
    ChoiceSetting(page, ledger, "prompts", y, nextZ(),
      { { "auto", "Automatic" }, { "keyboard", "Keyboard" }, { "pad", "Controller" } },
      function() UI.RefreshPrompts() end)
    y = y - ROW
    -- No Motion row: the window has no motion to reduce (dev/ui-rules.md §1-4).
    ToggleSetting(page, ledger, "sound", y, nextZ()); y = y - ROW
    ToggleSetting(page, ledger, "focusTips", y, nextZ()); y = y - ROW
    ToggleSetting(page, ledger, "shortcuts", y, nextZ(), function()
      if ns.Input and ns.Input.Apply then ns.Input.Apply() end
    end)
    y = y - ROW
    ResetRow(page, ledger, y, nextZ())

    -- Right column: tools by section, the fishing helper, the log.
    y = TOP
    for gi, g in ipairs(ToolGroups()) do
      if gi > 1 then y = y - GAP end
      UI.SectionTitle(ledger, g.title:upper(), RIGHT_X, y, COL_W)
      y = y - TITLE_H
      for i, a in ipairs(g.items) do
        ToolRow(page, ledger, g, a, y, i)
        y = y - ROW
      end
    end
    local fishing = ns.ModuleOf and ns.ModuleOf("Fishing")
    if fishing then
      if y ~= TOP then y = y - GAP end
      UI.SectionTitle(ledger, Title(fishing):upper(), RIGHT_X, y, COL_W)
      y = y - TITLE_H
      FishingRow(page, ledger, fishing, y, 1)
      y = y - ROW
    end
    if y ~= TOP then y = y - GAP end
    UI.SectionTitle(ledger, "LOG", RIGHT_X, y, COL_W)
    y = y - TITLE_H
    page.logRow = LogRow(page, ledger, y, 1)
    y = y - ROW
    y = LogPreview(page, ledger, y)
    y = y - GAP
    UI.SectionTitle(ledger, "CONTROLS", RIGHT_X, y, COL_W)
    y = y - TITLE_H
    Legend(page, ledger, y)

    -- Footer: version and where every command is listed.
    local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("Agentcraft", "Version")
    local foot = UI.Text(ledger, (version and ("Agentcraft " .. version .. " · ") or "") .. "/ac help lists every command", "GameFontDisable")
    foot:SetPoint("BOTTOMRIGHT", ledger, "BOTTOMRIGHT", -(712 - RIGHT_X - COL_W) - 2, 14)
    foot:SetJustifyH("RIGHT")

    BuildLogView(page, stage)
  end,

  Refresh = function(page)
    for _, r in ipairs(page.rows) do if r.Sync then r:Sync() end end
    RefreshLog(page)
  end,

  Status = function()
    local on = 0
    for _, mod in ipairs(ns.order) do if mod.active then on = on + 1 end end
    return string.format("%s of %d modules on · %d log line%s", UI.C.GREEN:WrapTextInColorCode(on), #ns.order,
      #ns.log, #ns.log == 1 and "" or "s")
  end,

  prompts = function(page)
    return { { key = "PAD1", label = page.promptA or "Select" } }
  end,

  DefaultFocus = function(page) return page.moduleRows and page.moduleRows[1] end,

  DefaultInspect = function(page, pane)
    pane:Header(GEAR_ICON, "Options", "Agentcraft")
    pane:Text(page.description)
    local on = 0
    for _, mod in ipairs(ns.order) do if mod.active then on = on + 1 end end
    pane:Row("Modules on", string.format("%d of %d", on, #ns.order))
    pane:Row("Window scale", string.format("%.2f", UI.GetScale()))
    pane:Row("Log", tostring(#ns.log) .. " lines")
  end,

  ScrollRegion = function(page)
    if page.logView and page.logView:IsShown() and page.logBox then
      return page.logBox.GetScrollBox and page.logBox:GetScrollBox() or page.logBox
    end
  end,

  OnShow = function(page)
    -- A page switch clears the Back stack; never leave the log open without its layer.
    if page.logView and page.logView:IsShown() and not ns.Esc.Has("log") then page:CloseLog(true) end
  end,

  OnHide = function(page)
    if page.logView and page.logView:IsShown() then page:CloseLog(true) end
  end,

  OpenLog = function(page)
    if not page.logView or page.logView:IsShown() then return end
    page.ledger:Hide()
    page.logView:Show()
    page.logKey = nil
    UI.Sound("page")
    ns.Esc.Push(function() page:CloseLog() end, "log")
    UI.Refresh()
    if ns.Focus and ns.Focus.Set then ns.Focus:Set(page.logWell, ns.Focus.source == "mouse" and "key" or ns.Focus.source) end
  end,

  CloseLog = function(page, quiet)
    if not page.logView or not page.logView:IsShown() then return end
    page.logView:Hide()
    page.ledger:Show()
    if ns.Esc.Has("log") then ns.Esc.Remove("log") end
    if quiet then return end
    UI.Sound("page")
    UI.Refresh()
    if ns.Focus and ns.Focus.Set and page.logRow then ns.Focus:Set(page.logRow, ns.Focus.source == "mouse" and "key" or ns.Focus.source) end
  end,
})
