-- Dev-only page for the offline renderer: the v2 foundation widgets on one
-- page (native controller HUD of four UI.PadBar, back sockets, the view
-- strip with toggles, a List view on UI.ScrollList, the Inspector API with
-- a BarCard, the readiness meter and the Review sheet). render.lua registers
-- it in its own harness game; the addon never ships it.
-- The arrangement follows Blizzard's GamepadMainActionBarFrame:
-- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.xml
local SPELLS = { "Arcane Shot", "Serpent Sting", "Hunter's Mark", "Concussive Shot", "Aspect of the Hawk", "Mend Pet",
  "Raptor Strike", "Wing Clip", "Feign Death", "Multi-Shot", "Aimed Shot", "Rapid Fire", "Freezing Trap", "Volley",
  "Track Beasts", "Aspect of the Cheetah", "Disengage", "Mongoose Bite", "Scare Beast", "Eagle Eye", "Flare",
  "Immolation Trap", "Explosive Trap", "Frost Trap" }
local LAYER_TITLE = { [0] = "No trigger", "Hold LT", "Hold RT", "Hold LT + RT" }

local page = { id = "gallery", title = "Widget Gallery", api = 2, order = 2000,
  icon = "Interface\\Icons\\INV_Gizmo_02",
  description = "Dev-only: every v2 widget, drawn by the offline renderer." }
page.views = { { key = "1", label = "1 · Combat" }, { key = "2", label = "2 · Utility" }, { key = "3", label = "3 · Pet & Extras" } }
page.view = "1"
page.mode, page.after = 1, 1
page.toggles = {
  { key = "mode", labels = { "HUD", "List" }, get = function(p) return p.mode end, set = function(p, i) p.mode = i end },
  { key = "after", labels = { "Now", "After" }, get = function(p) return p.after end, set = function(p, i) p.after = i end },
}
page.prompts = function() return { { key = "PAD1", label = "Pin" }, { key = "PAD3", label = "Next set" } } end
page.readiness = function() return 41, 44 end
page.disableFrameFocusPaging = true

local function Entry(p, layer, name, i)
  local idx = (layer * 8 + i + (tonumber(p.view) - 1) * 5) % #SPELLS + 1
  if layer == 0 and (name == "A" or name == "B" or name == "X" or name == "Y") then return nil end
  if (layer * 8 + i) % 7 == 3 then return nil end
  return SPELLS[idx]
end

local function BarRows(p, layer)
  local UI = p.ns.UI
  local rows = {}
  for _, name in ipairs(UI.PAD_BUTTONS) do
    local s = p.bars[layer].slots[name]
    local spell = s.spell
    rows[#rows + 1] = { key = UI.PAD_OFFSETS[name][4], icon = spell and UI.SpellIcon(spell) or s.fixedIcon,
      name = spell or s.fixedName or "Empty", node = s, color = s.state and UI.C[s.state] or nil, focused = p.ns.Focus.current == s }
  end
  return { title = LAYER_TITLE[layer] .. " · set " .. p.view, rows = rows }
end

local function Inspect(s, pane)
  local p = s.page
  local UI = p.ns.UI
  local keys = {}
  for _, k in ipairs(UI.PAD_LAYER_TRIGGERS[s.layer]) do keys[#keys + 1] = k end
  keys[#keys + 1] = s.padKey
  pane:Header(s.spell and UI.SpellIcon(s.spell) or s.fixedIcon, s.spell or s.fixedName or "Empty", s.spell and "Spell" or "Gamepad UI", keys)
  if s.state == "ADDED" then pane:Row("State", "Added when you apply", UI.C.ADDED)
  elseif s.fixedName then pane:Row("State", "Fixed by the Gamepad UI", UI.C.FIXED)
  else pane:Row("State", s.spell and "In place" or "No home", s.spell and UI.C.HIGHLIGHT or UI.C.DISABLED) end
  pane:Diff({ icon = nil, name = "Empty" }, { icon = s.spell and UI.SpellIcon(s.spell), name = s.spell, color = UI.C.ADDED })
  pane:CrossRef({ { text = "Keyboard: Shift + R", fn = function() end } })
  pane:BarCard(BarRows(p, s.layer))
end

page.Build = function(p, stage)
  local UI, G = p.ns.UI, p.G
  p.stage = stage
  -- Stage art: the class talent background, darkened by a vertical gradient.
  local bg = stage:CreateTexture(nil, "BACKGROUND", nil, 2)
  bg:SetPoint("TOPLEFT", 3, -3); bg:SetPoint("BOTTOMRIGHT", -3, 3)
  if not UI.SetAtlas(bg, { "Talents-Background-c60", "talents-background-hunter-beastmastery" }) then bg:Hide() end
  local shade = UI.Gradient(stage, "BACKGROUND", "VERTICAL", { 0, 0, 0, 0.15 }, { 0, 0, 0, 0.55 }, 3)
  shade:SetPoint("TOPLEFT", 3, -3); shade:SetPoint("BOTTOMRIGHT", -3, 3)

  p.hud = G.CreateFrame("Frame", nil, stage)
  p.hud:SetAllPoints()
  p.bars = {}
  for layer = 0, 3 do
    local bar = UI.PadBar(p.hud, layer)
    local o = UI.PAD_BAR_OFFSETS[layer]
    bar:SetPoint("CENTER", p.hud, "TOPLEFT", 362 + o[1], -236 + o[2])
    bar:SetTitle(LAYER_TITLE[layer])
    for _, name in ipairs(UI.PAD_BUTTONS) do
      local s = bar.slots[name]
      s.page, s.layer = p, layer
      s.acInspect = Inspect
      s:SetScript("OnClick", function(self) p.ns.Focus:Pin(self) end)
    end
    p.bars[layer] = bar
  end
  -- Back paddles: empty sockets, not focusable (owner rule).
  p.sockets = {}
  for i, k in ipairs({ "L4", "L5", "R4", "R5" }) do
    local sk = UI.Socket(p.hud, k)
    sk:SetPoint("TOPLEFT", p.hud, "TOPLEFT", 236 + (i - 1) * 64 + (i > 2 and 40 or 0), -440)
    p.sockets[i] = sk
  end
  p.socketNote = UI.Text(p.hud, "Back buttons · kept free for now", "GameFontDisable")
  p.socketNote:SetPoint("TOPLEFT", p.hud, "TOPLEFT", 236, -500)

  -- List view: one row per button, the four layers side by side.
  p.listHost = G.CreateFrame("Frame", nil, stage)
  p.listHost:SetPoint("TOPLEFT", 8, -44)
  p.listHost:SetPoint("BOTTOMRIGHT", -8, 8)
  p.headers = {}
  for c = 0, 3 do
    local h = UI.Text(p.listHost, LAYER_TITLE[c]:upper(), "GameFontNormal")
    h:SetPoint("TOPLEFT", 44 + c * 164, 0)
    p.headers[c] = h
  end
  local rowsHost = G.CreateFrame("Frame", nil, p.listHost)
  rowsHost:SetPoint("TOPLEFT", 0, -20)
  rowsHost:SetPoint("BOTTOMRIGHT")
  p.list = UI.ScrollList(rowsHost, 52, function(parent)
    local r = G.CreateFrame("Button", nil, parent)
    r.bg = r:CreateTexture(nil, "BACKGROUND")
    r.bg:SetAllPoints()
    r.glyph = UI.Glyph(r, "PAD1", 24, "pad")
    r.glyph:SetPoint("LEFT", 8, 0)
    r.cells = {}
    for c = 0, 3 do
      local icon = r:CreateTexture(nil, "ARTWORK")
      icon:SetSize(32, 32)
      icon:SetPoint("LEFT", 44 + c * 164, 0)
      icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      local name = UI.Text(r, "", "GameFontHighlight")
      name:SetPoint("LEFT", icon, "RIGHT", 6, 0)
      name:SetWidth(118)
      name:SetJustifyH("LEFT")
      name:SetWordWrap(false)
      r.cells[c] = { icon = icon, name = name }
    end
    return r
  end, function(r, d, i)
    if not UI.SetAtlas(r.bg, UI.ART.zebra) then r.bg:SetTexture(UI.WHITE); r.bg:SetVertexColor(1, 1, 1, 0.05) end
    r.bg:SetAlpha(i % 2 == 0 and 0.45 or 1)
    r.glyph:SetKey(UI.PAD_OFFSETS[d][4])
    for c = 0, 3 do
      local s = p.bars[c].slots[d]
      local cell = r.cells[c]
      cell.icon:SetTexture(s.spell and UI.SpellIcon(s.spell) or s.fixedIcon or UI.QUESTION)
      cell.icon:SetDesaturated(s.spell == nil)
      cell.name:SetText(s.spell or s.fixedName or "Empty")
      if s.spell then cell.name:SetTextColor(1, 1, 1) else cell.name:SetTextColor(0.5, 0.5, 0.5) end
    end
    r.acId = "list:" .. d
  end)
end

page.Refresh = function(p)
  local UI = p.ns.UI
  for layer = 0, 3 do
    for i, name in ipairs(UI.PAD_BUTTONS) do
      local s = p.bars[layer].slots[name]
      s.spell = Entry(p, layer, name, i)
      s.fixedName, s.fixedIcon = nil, nil
      if layer == 0 and not s.spell and (name == "A" or name == "B" or name == "X" or name == "Y") then
        s.fixedName = ({ A = "Jump", B = "Back", X = "Interact", Y = "Inspect" })[name]
        s.fixedIcon = name == "A" and "atlas:gamepad-ability-icon-jump" or nil
        s:SetPermabound(true)
      end
      if s.fixedIcon and s.fixedIcon:find("^atlas:") then
        s:SetIcon(nil)
        if UI.SetAtlas(s.icon, s.fixedIcon:sub(7)) then s.icon:Show(); s.icon:SetDesaturated(true) end
        s.fixedIcon = nil
      else
        s:SetIcon(s.spell and UI.SpellIcon(s.spell) or nil)
      end
      s.state = (p.after == 2 and s.spell and (i + layer) % 4 == 0) and "ADDED" or nil
      s:SetState(s.state == "ADDED" and "added" or "empty")
    end
  end
  local list = p.mode == 2
  p.hud:SetShown(not list)
  p.listHost:SetShown(list)
  if list then p.list:SetData(UI.PAD_BUTTONS) end
end

page.Status = function(p)
  local UI = p.ns.UI
  return UI.C.ADDED:WrapTextInColorCode("3 changes ready") .. " · " .. UI.C.DISABLED:WrapTextInColorCode("2 waiting to learn")
end

page.DefaultFocus = function(p) return p.bars[0].slots.Up end
page.DefaultInspect = function(p, pane) pane:BarCard(BarRows(p, 0)) end
page.OnView = function() end
page.Review = function()
  return {
    { title = "WILL PLACE", items = {
      { key = "RT + A", afterName = "Kill Command", note = "new" },
      { key = "LT + Up", nowName = "Attack", afterName = "Concussive Shot", note = "replaces your bind" },
      { key = "RT + B", afterName = "Mend Pet" } } },
    { title = "WAITING", items = { { key = "LT + X", afterName = "Volley", note = "learn at 50" } } },
  }
end
page.Commit = function() return "Gallery: nothing applied (dev page).", nil, { "pad:2:A" } end

return page
