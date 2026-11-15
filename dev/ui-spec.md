# Agentcraft window redesign spec: matching the official WoW Forever look

Status: this is a design spec only. I edited no repo files. There are no in-game screenshots: `C:/Program Files (x86)/World of Warcraft/_forever_/Screenshots` does not exist. Every measurement below comes from the code, the offline render harness (`dev/render/out/*.html`, 1280x800 canvas) and Blizzard's UI source (Gethe/wow-ui-source, `forever` branch). Lines marked **[VERIFY]** need an in-game check before shipping.

Facts I checked myself in the repo:
- `Window.lua` constants are `W, H, NAV_W, TOP = 800, 520, 160, -62`.
- Footer buttons are `UI.Button` (UIPanelButtonTemplate) with 6px gaps.
- `ns.RegisterAction` **is** called by `Modules/Snapshot.lua:715` ("Snapshot", "Save now"). The Settings "Tools" section therefore does show today, and the earlier audit's C11 ("dead code") is wrong.
- The controller diamond really is drawn upside down. `DIAMOND` up is `{0,1}` and y is `-62 - d[2]*32`, so Y lands at the bottom and A at the top.
- The harness (`dev/harness/frames.lua`) emulates PortraitFrameTemplate, ButtonFrameTemplate, InsetFrameTemplate, BasicFrameTemplate(WithInset), UIPanelScrollFrameTemplate, ScrollFrameTemplate and InputBoxTemplate. It does **not** emulate MinimalCheckboxTemplate, the WowStyle1 dropdowns, PanelTopTabButtonTemplate, ScrollingEditBoxTemplate or MagicButtonTemplate, so it must be extended (see §10).

---

## 0. Design principles

1. **Inherit, don't draw.** Forever runs the Mainline templates with "Camelot" art overrides on the same atlas names (Blizzard_SharedXML.toc loads `Camelot\SharedUIPanelTemplates.lua` and `NineSliceLayoutOverrides.lua` for game type `camelot`). Any region built from a Blizzard template or atlas therefore gets Forever's bronze metal for free. Every `SetColorTexture` fill or 1px border in the window chrome goes away. `UI.Fill` and `UI.Border` survive only as fallbacks when a template or atlas is missing.
2. **Settings-panel grammar.** The 12.x Options window is the native model for "list on the left, page on the right":
   - gold idle rows, white selected rows;
   - `Options_List_Active` and `Options_List_Hover` row art;
   - white section titles;
   - buttons bottom-right, the primary action rightmost.
3. **Gamepad-first sizing.** The owner plays at 800p with the controller cursor:
   - every interactive target is at least 28px tall;
   - no information is only available on hover;
   - body text uses `GameFont*` (12pt), never `*Small` (10pt);
   - the window registers with the Gamepad UI's FrameControlsManager.
4. **One vocabulary** (glossary, §8), using the game's own words: Action Bar 1–5, Key Bindings, General/Character macro, Not Bound.
5. **Module logic untouched.** Only page code (Build/Refresh/Status/actions/titles), `UI/*` and `Core.lua` registration fields change. Three audit findings need module logic changes; they are listed separately in §11.

---

## 1. Window chrome and size

### 1.1 Frame
```lua
frame = CreateFrame("Frame", "AgentcraftFrame", UIParent,
  HasTemplate("ButtonFrameTemplate") and "ButtonFrameTemplate" or "BasicFrameTemplateWithInset")
frame:SetSize(820, 560)
frame:SetFrameStrata("MEDIUM"); frame:SetToplevel(true)   -- was HIGH
frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
frame:SetTitle("Agentcraft")                               -- gold GameFontNormal, centred in the title bar
frame:SetPortraitToClassIcon(select(2, UnitClass("player")))  -- fallback: current UI-Classes-Circles code
tinsert(UISpecialFrames, "AgentcraftFrame")
```
- **Size: 820x560.** UIParent at 1280x800 with UI scale 1.0 is about 1229x768. At the maximum window scale of 1.25 the frame is 1025x700, which still fits. Width goes from 800 to 820 so the page well stays 600px wide inside the marble inset with 10px padding. Height goes from 520 to 560 to give the pages about 50px more room (§1.3).
- **Strata MEDIUM + toplevel.** The Macro Library asks you to drag macros onto bars and use the spellbook and bags. At HIGH the window covers them. MEDIUM + toplevel is what CharacterFrame uses.
- **Drag by the title bar only.** Register drag on `frame.TitleContainer` (fallback: an invisible 20px-tall button across the top) and forward to `frame:StartMoving()` / `StopMovingOrSizing()`. Remove `frame:RegisterForDrag` from the whole frame. A press and stick-move on a page must not move the window.
- **Saved position.** On drag stop, store `{point, relPoint, x, y}` in `ns.db.window`. Restore it on Build. First open uses `CENTER`. Add `/ac reset` to recentre and reset the scale.
- **Window scale.**
  - `ns.db.scale` (default `nil`) is set with `/ac scale 0.8–1.25` and with a slider on Options (§6.6).
  - When `nil`, use 1.1 if the Gamepad UI is on (§7.1), else 1.0.
  - Always clamp so that `820*s <= UIParent:GetWidth()-20` and `560*s <= UIParent:GetHeight()-20`.
- **Close button.** Use the template's `CloseButton` (Forever: 28x28 at TOPRIGHT 0,3). It calls HideUIPanel, so the gamepad B button finds it by name.
- **Classic fallback.** `BasicFrameTemplateWithInset` keeps working: there is no portrait, the title is `frame.TitleText`, and the layout constants are the same with the attic at -24 (see 1.2, where `ATTIC = portrait and 64 or 28`).

### 1.2 Regions (frame coordinates; y is negative downward)
```
┌─[portrait 62]─────────────── Agentcraft ───────────────────────────────[X]┐ 0
│  (class)   Key Bindings                              Level 60 Hunter     │ -30  title row
│            Up to date · 2 keys replace your binds                         │ -47  summary row
├──────────────┬────────────────────────────────────────────────────────────┤ -64
│ NAV inset    │ PAGE inset (f.Inset, marble)                               │
│ 180 wide     │ 626 x 470, page frame = inner 600 x 450 (10px padding)     │
│              │                                                            │
│ KEYBOARD     │                                                            │
│  Action Bars │                                                            │
│ >Key Bindings│                                                            │
│ GAMEPAD      │                                                            │
│  Controller  │                                                            │
│ LIBRARY      │                                                            │
│  Macro Libr. │                                                            │
│ AGENTCRAFT   │                                                            │
│  Options     │                                                            │
│      v0.26.1 │                                                            │
├──────────────┴────────────────────────────────────────────────────────────┤ -534
│ status text (left, truncates, tooltip)            [Undo…] [Apply] (Magic) │ 26px button bar
└───────────────────────────────────────────────────────────────────────────┘ -560
```
| Region | Anchor | Notes |
|---|---|---|
| Page title | `TOPLEFT 70,-30` | `GameFontHighlightLarge` (white). Use the page's display title |
| Summary | `TOPLEFT 70,-47`, `RIGHT -12` | `GameFontHighlight`, `SetWordWrap(false)`, truncates. Fixes the overlap with the character line, which now sits on the title row |
| Character line | `TOPRIGHT -12,-32` | `GameFontNormalSmall`, format `"Level %d %s"` (`PLAYER_LEVEL`-style, the class in `C_ClassColor.GetClassColor(class):WrapTextInColorCode`). One function, `CharLine()`, updated on OnShow and PLAYER_LEVEL_UP |
| Nav inset | `CreateFrame("Frame", nil, frame, "InsetFrameTemplate")`, `TOPLEFT 4,-64`, `BOTTOMLEFT 4,26`, width 180 | Replaces `UI.Fill` + `UI.Border` |
| Page inset | `frame.Inset` re-anchored: `ClearAllPoints()`, `TOPLEFT 188,-64`, `BOTTOMRIGHT -6,26` | 626x470 |
| Page frame | Child of `frame.Inset`, `TOPLEFT 13,-10`, `BOTTOMRIGHT -13,10` | **600x450.** Pages keep their 600px assumptions |
| Version | Nav inset `BOTTOM 0,8` | `"v0.26.1"`, `GameFontDisableSmall`. Tooltip: "Agentcraft 0.26.1" |
| Status | `BOTTOMLEFT 10,7`, `RIGHT` → footer buttons' LEFT, -10 | `GameFontHighlight` (see 1.4) |
| Footer buttons | `MagicButtonTemplate`, rightmost at `BOTTOMRIGHT -6,4`, the rest chained `RIGHT`→`LEFT` with 0 gap | **[VERIFY]** that MagicButton draws its left/right divider art when chained. Fallback: `UIPanelButtonTemplate` 22 tall with 4px gaps |

### 1.3 Size budget (1280x800, scale 1.0)
- Page area: 600x450 (was 600x404).
- Window: 820x560 out of 1229x768. That leaves about 200px each side for the spellbook or bags when the window is moved left (ShowUIPanel without an area does not dock it; the user places it).

### 1.4 Status bar behaviour (fixes shell audit 1.2, 1.3, 1.5 and A9)
- `status.kind` is `"result"` or `"error"`. `Refresh()` clears the status if `kind == "error"` and the refresh itself succeeded.
- **Results:**
  - The status shows the first non-empty line, plus ` (+N more)` when there are more lines.
  - OnEnter shows a GameTooltip with every line (`GameTooltip_SetTitle(page.title)` + `AddHighlightLine` each, wrapped).
  - The status is a `Button`, so the controller cursor can focus it.
- **Errors:**
  - Shown as `RED_FONT_COLOR:WrapTextInColorCode("Error: ") .. firstLineOf(err)`.
  - Also appended to `ns.log` via a new `ns.LogLine(text)` (Core).
  - The tooltip shows the full error.
- **Build errors:**
  - The footer buttons are hidden while `buildErr` is set.
  - The page well shows a centred `GameFontHighlight` line: "This page failed to load. Details are in Options › Log."
- "Done." is replaced by an empty status when an action printed nothing.

---

## 2. Navigation model and final page list

### 2.1 Decision: a left category list (Settings model), not side tabs
Forever's CharacterFrame uses `LargeSideTabButtonTemplate` icon tabs outside the right edge. I am **not** using them as the primary navigation:
- They are icon-only, so page names live in tooltips (hover-only information on a handheld).
- They add about 64px outside the frame.
- They are missing on the classic-flavor clients the TOC also targets.

A labelled list inside an inset, with Blizzard's own list atlases, is just as native: it is the Options panel's own pattern.

### 2.2 Nav row spec
- **Header row** (non-interactive): 172x22.
  - Label in `GameFontHighlightSmall`, uppercase-free Title Case ("Keyboard & Mouse"), at `LEFT 10,0`.
  - Background atlas `Options_CategoryHeader_1` when `C_Texture.GetAtlasInfo` finds it **[VERIFY: looks right at 172 wide]**, else none.
  - Mark ignored for gamepad: `SmartNavigation_MarkFrameIgnored(hdr)` when that function exists.
- **Page row:** `Button` 172x30, 2px spacing, inside the nav inset at x=4.
  - `row.Texture` (BACKGROUND, all points): atlas `Options_List_Active` when selected, `Options_List_Hover` on enter (cleared on leave unless selected).
  - Fallback when the atlas is missing: the current gold 0.12 fill.
  - Icon: 20x20 at `LEFT 10,0`, with `SetTexCoord(.08,.92,.08,.92)` plus a circular mask (`CreateMaskTexture` with `Interface\CharacterFrame\TempPortraitAlphaMask`) so it reads as a list icon, not a slot.
  - Label: `LEFT icon RIGHT 8`. `GameFontNormal` when idle (gold), `GameFontHighlight` when selected (white). That matches Blizzard_CategoryList.lua.
  - Remove `b.bar` (the 2px gold bar) and the 0.06 white highlight.
- 10px spacer before each header except the first.
- Total height for 4 headers + 5 rows is about 4*22 + 5*32 + 3*10 = 278px, which fits in 470. Past about 12 rows, wrap the list in `ScrollFrameTemplate` (not needed now).

### 2.3 Final pages (names, order, sections)
| Section (header) | Page title | id | order | Icon (neutral, not reused by macro categories) |
|---|---|---|---|---|
| Keyboard & Mouse | **Action Bars** | `bars` | 10 | `Interface\Icons\INV_Misc_Book_09` [VERIFY exists on Classic] |
| Keyboard & Mouse | **Key Bindings** | `keys` | 20 | `Interface\Icons\INV_Misc_Key_03` (keep) |
| Gamepad | **Controller** | `controller` | 30 | `Interface\Icons\INV_Gizmo_02` (keep) |
| Library | **Macro Library** | `macros` | 40 | `Interface\Icons\INV_Misc_Note_01` (keep). Change `Controller.lua:235`'s macro fallback icon to `INV_Misc_QuestionMark` so they no longer collide |
| Agentcraft | **Options** | `settings` | 1000 | `Interface\Icons\INV_Misc_Gear_01` (was Trade_Engineering, which is also the Professions category icon) |

- No new Snapshot page. Snapshot gets a section on Options (§6.6). A page with one button is thin, and the snapshot is passive.
- **Opening page:**
  1. `ns.db.lastPage` if it is still registered;
  2. else `controller` if the Gamepad UI is on (§7.1);
  3. else `bars`.

  Saved on every `Select`.

---

## 3. Shared widget set → Blizzard templates and atlases

| Agentcraft widget | Today | New | Fallback |
|---|---|---|---|
| Window | PortraitFrameTemplate + hand-drawn attic | `ButtonFrameTemplate` (portrait, rock bg, `.Inset`, close, gamepad FrameGlow/JumpHints) | `BasicFrameTemplateWithInset` |
| Inset / panel well | `UI.Fill(0,0,0,.35)` + `UI.Border(1,1,1,.08)` | **`UI.Inset(parent)`** = `CreateFrame("Frame",nil,parent,"InsetFrameTemplate")` | Old fill + border |
| Sub-panel inside a page (controller bars, macro detail) | Fill + gold border | **`UI.Panel(parent)`** = `InsetFrameTemplate3` **[VERIFY look nested inside marble; if too heavy use `InsetFrameTemplate4` or no box + a divider]** | Fill 0.25 |
| Section header | Gold `GameFontNormal` + 1px gold rule of fixed width 590 | **`UI.Header(parent, text, x, y, width)`** (same signature). Text in `GameFontHighlightMedium`... see §5. Divider texture atlas `Options_HorizontalDivider`, height 1 (use the atlas height), anchored `TOPLEFT text BOTTOMLEFT 0,-3` → `RIGHT parent TOPLEFT x+width`. `width` defaults to `parent:GetWidth()` at build time, not 590. Optional `hint` argument → tooltip on an invisible button over the header (removes the grey inline hints) | Old rule |
| Header hint | Grey `|cff999999…|r` inside the header | `UI.Header(..., {hint="..."})`, which adds a 16x16 `Interface\common\help-i` ⓘ **[VERIFY texture]** after the text with a tooltip. Focusable | Text after the header |
| Divider | 1px gold rule | `UI.Divider(parent)` with atlas `UI-Character-Info-ScrollLine-Long` | Fill 1,1,1,.1 |
| Button | `UIPanelButtonTemplate` 22 tall | Same template, **height 26** inside pages (gamepad target), 22 in the 26px button bar. `UI.Button(parent, text, width, onClick, tooltip)` now auto-sizes when `width == nil`: `max(80, fs:GetStringWidth()+28)` | — |
| Footer button | `UI.Button` | `MagicButtonTemplate` (§1.2) | `UIPanelButtonTemplate` |
| Checkbox | `UICheckButtonTemplate` 24x24 (old art) | **`UI.Check(parent, label, desc)`** = `MinimalCheckboxTemplate` 28x28. The label is `GameFontNormal` at `LEFT cb RIGHT 4`, the description `GameFontHighlightSmall` under the label. **The whole row is a Button** that toggles the box, so the hit area covers the label too | `UICheckButtonTemplate` |
| Tabs (controller sets, macro scope) | `UIPanelButtonTemplate` with the selected tab *disabled* (looks greyed) | **`UI.Tabs(parent, labels, onSelect)`** = `PanelTopTabButtonTemplate` children in `parent.Tabs`. Use `PanelTemplates_SetNumTabs`, `PanelTemplates_SetTab` and `PanelTemplates_ResizeTabsToFit(parent, 580)` | Buttons, with the selected one using `LockHighlight()` instead of `SetEnabled(false)` |
| Dropdown / filter | Tag chip wall | **`UI.Filter(parent, setupFn)`** = `CreateFrame("DropdownButton",nil,parent,"WowStyle1FilterDropdownTemplate")` + `SetupMenu`. **`UI.Dropdown`** = `WowStyle1DropdownTemplate` (radio) | Old chips |
| Search | `SearchBoxTemplate` (good) | Keep. 180x22, `self.Instructions:SetText(SEARCH)` | `InputBoxTemplate` |
| Scroll list | `UIPanelScrollFrameTemplate` (old red arrows) | **`ScrollFrameTemplate`** (modern ScrollFrame + MinimalScrollBar; already in the harness). This is the smallest change. Optional later: `WowScrollBoxList` + `MinimalScrollBar` for row recycling | `UIPanelScrollFrameTemplate` |
| Read-only multi-line text (log, macro code) | EditBox inside UIPanelScrollFrame | **`ScrollingEditBoxTemplate`** (Shared/Scroll/ScrollTemplates.xml) with `SetInterpolateScroll`, `GetEditBox():SetEnabled(true)` for selection, read-only via OnTextChanged revert **[VERIFY API on 12.x]** | Current |
| Slot (spell/item icon) | `UI-Quickslot2` + `UI-ActionButton-Border` glow + `ButtonHilight-Square` | **`UI.Slot`** with modern action-button art: icon masked by `UI-HUD-ActionBar-IconFrame-Mask`; `UI-HUD-ActionBar-IconFrame` overlay; `SetHighlightAtlas("UI-HUD-ActionBar-IconFrame-Mouseover")`; `SetPushedAtlas("UI-HUD-ActionBar-IconFrame-Down")`; empty slot bg `ui-hud-actionbar-iconframe-slot`. The state mark is `UI-HUD-ActionBar-IconFrame-Border` tinted (see §4) **[VERIFY atlas names in game with C_Texture.GetAtlasInfo; Forever Camelot art may rename them]** | Old textures, chosen once in `UI.Slot` by `C_Texture.GetAtlasInfo("UI-HUD-ActionBar-IconFrame")` |
| Slot key text | `NumberFontNormalSmallGray` | `NumberFontNormalSmall` (white-grey is unreadable at 800p), via `UI.KeyText` → `GetBindingText(key, nil, true)` (abbreviated), clipped with `SetWidth(size-4)`, `SetWordWrap(false)` | — |
| Slot centre label ("fixed") | `GameFontDisableSmall` lowercase | `GameFontHighlightSmall` Title Case function name ("Jump") | — |
| Flyout marker | Gold 1px edge | Corner badge: 12x12 texture `UI-HUD-ActionBar-Flyout` at `TOPRIGHT -1,-1` **[VERIFY atlas; fallback: small gold "▲" FontString]** | — |
| Legend item | Filled 10px square | **`UI.LegendItem(parent, state, text)`**: an 18px mini `UI.Slot` drawn in that state (glow, edge or badge) + `GameFontHighlight` label. It shows exactly what it describes | Square |
| Tooltip | `GameTooltip:SetText(title,1,.82,0)` | `GameTooltip_SetTitle(GameTooltip, title)`; body via `GameTooltip_AddNormalLine` / `GameTooltip_AddColoredLine(tt, text, color)` | — |
| Confirm dialog | none | **`UI.Confirm(text, onAccept)`**: one `StaticPopupDialogs["AGENTCRAFT_CONFIRM"]` (`button1=YES`, `button2=NO`, `hideOnEscape=1`, `whileDead=1`, `showAlert=1`), text set per call via `StaticPopup_Show(..., text)`. StaticPopups get gamepad navigation from the Gamepad UI **[VERIFY]** | — |
| Empty / error state | `page.empty` centred over the still-visible widgets | `UI.Empty(parent)`: centred `GameFontHighlight` text + optional button. Pages hide their content frame while it shows | — |

---

## 4. State colours and legends

Use Blizzard colour objects only. `Widgets.lua` exposes them as `UI.C` and keeps the old `UI.GREEN`/`UI.RED`/... names as `{r,g,b}` aliases built from them, so module code keeps working:

| Meaning | Name | Object | Where |
|---|---|---|---|
| Added on Apply | Added | `GREEN_FONT_COLOR` (#19FF19) | Slot glow, status text |
| Missing (not learned / not in bags / macro not installed) | Missing | `RED_FONT_COLOR` (#FF2020) | Slot glow + desaturated icon at 0.45 alpha |
| Removed on Apply | Removed | `ORANGE_FONT_COLOR` (#FF7F3F) **[VERIFY global exists on classic; fallback {1,.5,.25}]** | Slot glow + faded current icon |
| Will replace your bind | Replaces | `ORANGE_FONT_COLOR` | Key Bindings key edge |
| Unassigned / empty | Empty | no mark; empty-slot atlas | Controller back buttons without a home |
| Fixed by the Gamepad UI | Fixed | `GRAY_FONT_COLOR` text, desaturated, lock look | Controller face buttons |
| Bound to an action bar | — | `NORMAL_FONT_COLOR` edge | Key Bindings |
| Bound to the pet bar | — | `LIGHTBLUE_FONT_COLOR` (#87ABFF) edge | Key Bindings |
| Labels / interactive text | — | `NORMAL_FONT_COLOR` | — |
| Values / selected | — | `HIGHLIGHT_FONT_COLOR` | — |
| Secondary / disabled | — | `GRAY_FONT_COLOR` / `DISABLED_FONT_COLOR` | — |

- **"Added" marker [VERIFY in game]:** if the green `IconFrame-Border` tint still reads as "equipped item" next to items, switch "Added" to the green border plus a small `+` badge (top-left, `GameFontGreenSmall`).
- **Status strings:** build them only with `color:WrapTextInColorCode(text)`. Delete the `|cffff5a4a`, `|cff4cff4c` and `|cffffd100` literals in page Status code. Show a count only when it is above 0.
- **Legend rule:** every page that uses a colour has a legend line (`UI.LegendItem`) at the bottom of its page frame, and the legend words equal the tooltip words.

---

## 5. Typography

| Use | Font object |
|---|---|
| Window title (title bar) | `GameFontNormal` (template) |
| Page title (attic) | `GameFontHighlightLarge` |
| Summary (attic), status bar, hints, descriptions in the body | `GameFontHighlight` (hints may use `GameFontHighlightSmall` only when a second line under a label) |
| Section headers | `GameFontNormalLarge`... **decision: `GameFontHighlightMedium`** (white; Settings list headers) for page sections, `GameFontNormal` (gold) for row labels |
| Nav rows | `GameFontNormal` idle, `GameFontHighlight` selected |
| Nav section headers | `GameFontHighlightSmall` |
| Row labels ("Action Bar 1", "No trigger") | `GameFontNormal` |
| Values (spell names next to slots) | `GameFontHighlight` |
| Key text in slots | `NumberFontNormalSmall` (`NumberFontNormal` on 42px keyboard keys) |
| Disabled / empty values | `GameFontDisable` |
| Version | `GameFontDisableSmall` |

Ban `GameFontDisableSmall` for explanatory text (grey and 10pt is unreadable at 800p).

---

## 6. Page layouts (page frame 600x450; coordinates are page-local, y down negative)

All pages:
- No header inside the page. The page title and summary are in the attic.
- Content frame `page.content` (all points); `UI.Empty` sibling; legend and hint pinned to `BOTTOMLEFT` of the page frame, so they never collide with content.

### 6.1 Action Bars (`ActionBars.lua` page block only)
```
y=0    Bound to keys ─────────────────────────────────────────────── ⓘ
y=-26  Action Bar 1      [Q][E][R][T]  [F][G][C][V]  [1][2][3][4]
y=-68  Action Bar 2      ... (Shift)
         · Shift
y=-110 Action Bar 3      ... (Alt, consumables)
         · Alt
y=-160 Side bars (no key) ────────────────────────────────────────── ⓘ
y=-186 Action Bar 4      [  ]×12
y=-228 Action Bar 5      [  ]×12
...
bottom-24  Legend: [▣] Added  [▣] Missing  [▣] Removed  [ ] Unmarked = already in place
bottom-0   Bars 1–2 come from your class layout. Bar 3 picks the best consumable you carry.
```
- `SLOT=36`, `STEP=40`, group gap 10, `LABEL_W=112`. Width = 112 + 11*40 + 2*10 + 36 = 608, too wide, so use `STEP=39`: 112 + 429 + 20 + 36 = 597 ✓.
- Row label: two lines. "Action Bar 1" in `GameFontNormal`, then the modifier ("Shift", "Alt", none) in `GameFontHighlightSmall`, vertically centred on the slot.
- Header hints (tooltips):
  - "Bound to keys": "Plain, Shift and Alt use the same 12 keys."
  - "Side bars": "Pet, other spells, tracking and professions. Click only."
- Empty state (`plan == nil`): "No keyboard layout for Hunter yet." (localized class name, `UnitClass` first return). Hide `page.content`.
- Status: `"%d changes to apply"` (or `"Up to date"`), then `" · %d missing"` with the breakdown only in the summary tooltip: "N not learned · N not in bags · N macros to install".
- Actions:
  - `Undo` → **"Restore Original"** (`tooltip` "Put the bars back the way they were before your first Apply."), with `confirm`.
  - `Apply`: `confirm` "Apply the layout to your action bars? %d slots change.", `enabled = plan.changes > 0`, `primary = true`.

### 6.2 Key Bindings (`Keybinds.lua` page block)
```
x=0                                   x=318
Keyboard ──────────────── ⓘ          Mouse ─────────────────── ⓘ
[1][2][3][4][5]                        Plain        Shift
 [Q][W][E][R][T]                       Mouse Button 5 [ ]name  [ ]name
  [A][S][D][F][G]                      Mouse Button 4 [ ]name  [ ]name
    [Z][X][C][V]                       Middle Mouse   [ ]name  [ ]name
Q key ───────────────── (pinned 📌)    Legend: [▣] Action bar  [▣] Pet bar
 Q        [ ] Arcane Shot                      [▣] Set by Apply  [▣] Replaces your bind
 Shift+Q  [ ] Serpent Sting           Same 12 keys on every bar: plain = Action Bar 1,
 Alt+Q    [ ] Healing Potion          Shift = Action Bar 2, Alt = Action Bar 3.
                                       Pet abilities sit on Z and X.
```
- Keys: 42px at `KSTEP=47` (keep).
- Keys outside the layout (5, W, A, S, D) are drawn at alpha 0.5. Their tooltip says "Not used by the layout".
- The key label is the key only.
- The name under the key: remove `Short()` truncation, and show nothing.
- Mouse labels come from `GetBindingText("BUTTON5")` and so on. Name column width 100 (was 72); total 318 + 62 + 2*(30+6+100) = 652, too wide, so use the label column 96 and the name width 80: 318 + 96 + 2*116 = 646. Still too wide, so **stack Plain/Shift vertically per mouse button** (rows of 32: label row, then Plain slot+name and Shift slot+name at x 318+96 and 318+96+... ). Simplest fit: the label column 96, one entry 30 + 6 + 76 = 112, two entries 224 → 318 + 96 + 224 = 638. Move the right column to x=300 and use the label column 80: 300 + 80 + 224 = 604. **Final: MOUSE_X=296, label col 80, entry name width 76 → 600.** Width 296 is enough for the keyboard (row 4 x=1.25*47 + 4*47 = 247 + 42 = 289) ✓.
- Detail panel:
  - Follows hover **and** pins on click (A on gamepad).
  - The title shows "Q key" plus a "Pinned" note in `GameFontNormalSmall` when pinned.
  - Clicking the pinned key again unpins it.
  - Default shown key: the first layout key, so the panel is never blank.
- **Visual diff (page code only; reads `M.Layout()` / `GetBindingAction`):** for each layout key whose current action ≠ the layout command:
  - green Added edge when the key is currently unbound;
  - orange Replaces edge when it is bound to something else, with the tooltip line "Replaces: <UI.DescribeCommand(old).name>".
- Unbound text: `NOT_BOUND` global in `GameFontDisable`.
- Status: "Up to date", or `"%d keys to set · %d replace your binds"`.
- Actions:
  - "Restore Original": confirm "Restore the key bindings you had before Agentcraft?". **[VERIFY Keybinds module only has a first-apply backup]** Enabled only when a backup exists (page reads `M.db.backup` or similar; if no accessor exists, leave it always enabled and note it in §11).
  - "Apply": confirm, enabled when the count is above 0.

### 6.3 Controller (`Controller.lua` page block)
```
[ 1 · Combat ][ 2 · Utility ][ 3 · Pet & Extras ]       (PanelTopTabButtonTemplate, y=0)
y=-36 ┌ No trigger ─────────────┐  ┌ Hold LT ────────────────┐
      │     [↑]          [Y]    │  │                          │
      │ [←]    [→]   [X]    [B] │  │                          │
      │     [↓]          [A]    │  │                          │
      └─────────────────────────┘  └──────────────────────────┘
y=-166┌ Hold RT ────────────────┐  ┌ Hold LT + RT ────────────┐
      └─────────────────────────┘  └──────────────────────────┘
y=-298 Back buttons ─────────────────────────────────────────── ⓘ (Steam Input: L4=F13 …)
y=-322 [L4] [L5] [R4] [R5] [LT+L4] [LT+L5] [LT+R4] [LT+R5]   (labels inside slot corner)
bottom-44 Legend: [▣] Added  [▣] Missing  [▣] Removed  [▲] Flyout (opens a radial)  [ ] Empty
bottom-22 Pet radials (LB + LT, RB + RT) are filled by the Gamepad UI itself.
bottom-0  (gamepad only) LB / RB  Switch set
```
- **Panel geometry:** `PANEL_W=294`, `PANEL_H=124`, column gap 12 (2*294 + 12 = 600 ✓), row gap 6.
- **Panel order** (reading order follows the triggers you hold): `PANEL_POS = { [0]={0,0}, {1,0}, {0,1}, {1,1} }`. Positions: x = col*(294+12), y = -36 - row*(124+6).
- **Panel content:**
  - Title at `TOPLEFT 8,-6` in `GameFontNormal`.
  - Diamonds centred at x=78 and x=216, y=-72 (title clearance about 24px above the top slot).
  - `SLOT=30`, step 32.
  - **Fix the sign:** `y = -72 + d[2]*(SLOT+GAP)`.
- **D-pad labels:** arrows "↑ → ↓ ←" as key text **[VERIFY Friz Quadrata renders arrows; else use "Up/Right/Down/Left" in the tooltip only and the glyph atlas when known]**.
- **Face labels:** use the PlayStation letters when `C_GamePad.GetActiveDeviceID` / `GetDeviceMappedState` reports a PS pad **[VERIFY API]**, otherwise X/Y/B/A.
- **Fixed face buttons (no trigger set):** desaturated, centre label per button, and a matching tooltip title each, for example A = "Jump", B = "Cancel / Back", X = "Interact", Y = "Inspect". **[VERIFY mapping in the Gamepad UI bindings before shipping]** Tooltip text: "Fixed by the Gamepad UI."
- **Tabs:** `UI.Tabs(f, {"1 · Combat","2 · Utility","3 · Pet & Extras"})`, labels from Layout page titles. Remove `page.pageTitle`.
  - For a page with no title, use "N · Empty".
  - "Pet & Deck" is renamed in `Layout.lua` data titles (string data only).
- **Back buttons:** 8 slots of 36 at step 72. The label goes *inside* the slot at the bottom (`key` font). The tooltip title is the paddle name ("LT + L4"); the text comes from `UI.DescribeCommand(pp.current).name`, never a raw binding string.
- **Unassigned back button (`missing=="no home"`):** neutral Empty, with no icon, no glow and no question mark. Tooltip: "Unassigned. Apply leaves this button unbound."
- **Empty state (no layout):** hide `page.content` (wrap tabs, panels and back buttons in it), and show "No controller layout for Hunter yet."
- **Status:**
  - "Up to date" or "%d changes to apply";
  - "· %d missing" only if above 0;
  - "· %d spells without a button" only if above 0;
  - the Gamepad UI warning goes **first** when the Gamepad UI is off: `ORANGE:Wrap("Gamepad UI off")`, so truncation never hides it.
- **Actions:**
  - "Undo Last Apply" (that is what it does), confirm, enabled when a backup exists;
  - "Apply", confirm, primary.

### 6.4 Macro Library (`Macros/Page.lua`)
```
y=0   [ For You ][ All Macros ]              [🔍 Search........][Filter ▾]
y=-30 Filters: Hunter, Pet  (×)                       — hidden when none
y=-30/-50 ┌ list (ScrollFrameTemplate) 336 wide ─┐ ┌ detail UI.Panel 254 wide ──┐
          │ General ─────────────                │ │ [icon 40] Feign            │
          │ [☐][ic] Feign             Installed  │ │          Character macro   │
          │         Feign Death, then trap       │ │ Feigns death and drops...  │
          │ [☐][ic] Pet Care          Update     │ │ Requires Freezing Trap     │
          │ ...  (rows 40 tall)                  │ │ Macro ─────────────        │
          │                                      │ │ ┌ code (ScrollingEditBox, │
          │                                      │ │ │  96 tall, read-only) ┐  │
          │                                      │ │ [Install] [Pick Up] [Remove]│
          └──────────────────────────────────────┘ └────────────────────────────┘
Footer bar: status "General 12/120 · Character 5/18"     [Check All][Remove Checked (2)][Install Checked (2)]
```
- **Scope:** `UI.Tabs(f, {"For You", "All Macros"})` (replaces the self-labelled toggle).
- **Search:** 180x22 `TOPRIGHT -96,0`.
- **Filter:** `UI.Filter` 90x22 `TOPRIGHT 0,0`. The menu groups entries with `CreateTitle` (Class / Race / Profession / Topic / Status) and uses `CreateCheckbox` per tag. **Delete the chip bar.**
- **Active-filter line:** `GameFontHighlightSmall`, plus a 16px clear button (`UIPanelCloseButtonNoScripts`-style small X or `SearchBoxTemplate`'s clear look). It clears filters **and** the search. When filters are active, the list starts at y=-50; otherwise at y=-30.
- **List rows:** 40 tall.
  - `UI.Check` 28px box at x=2.
  - 32px slot at x=34. It is draggable: `RegisterForDrag("LeftButton")` → `L.PickUp(m)` when installed.
  - Name `GameFontNormal` at x=72.
  - Description `GameFontHighlightSmall`, one line, truncated.
  - State on the right in its colour: "Installed" (green), "Update" (gold), "Name in use" (orange), "Requires X" (red). Nothing for ready.
  - An "Untested" alert icon (`services-icon-warning` **[VERIFY atlas]**, fallback `Interface\DialogFrame\UI-Dialog-Icon-AlertNew` 14px) instead of a pill.
  - Selection: atlas `Options_List_Active` row background. Hover: `Options_List_Hover`.
- **Category headers in the list:** `UI.Header`.
- **Detail panel:**
  - `UI.Panel`, every text anchored `TOPLEFT`+`TOPRIGHT` (no fixed 226 widths).
  - Hidden sections are re-chained to the last visible element (fixes the 25px gap).
  - The code box has a fixed 96px height inside `ScrollingEditBoxTemplate` (fixes the overflow over the buttons). It shows `L.Resolve(m)`, and so does the card tooltip.
  - Buttons are 26 tall, bottom-anchored:
    - primary: "Install" / "Update" / "Replace…" (Replace confirms "Replace your macro 'X'? Your version will be lost."), disabled with the label "Installed" when current;
    - "Pick Up", enabled only when installed;
    - "Remove", enabled only when installed, with confirm "Remove 'X' and unbind its keys?".
- **Empty state:** the detail panel stays and shows "No macros match." plus a [Reset Filters] button.
- **Selection:** do not reset it on search or filter changes (remove the `page.selected = nil` lines at :148 and :317). Scroll the selected row into view (`ScrollFrame:SetVerticalScroll` computed from the row index).
- **Search:** do not match `m.icon`; trim the query.
- **Footer actions (`page.actions`):**
  - "Check All": "Check every macro shown that isn't installed or is out of date."
  - "Remove Checked (N)": confirm "Remove N macros and unbind their keys?", enabled when N > 0.
  - "Install Checked (N)": primary, enabled when N > 0.
  - Labels are dynamic, so `label` may be a function (Window re-reads it in Refresh and re-sizes the button).
  - Checked macros are counted **only among visible rows** (`Ticked()` filters by `Matches`).
  - Remove "Clear tags" (it moves to the filter line).
- **Status:** `"General %d/%d · Character %d/%d"` (`MAX_ACCOUNT_MACROS`, `MAX_CHARACTER_MACROS`), plus "· N checked" when above 0.

### 6.5 Hit targets
Every row and checkbox on a page is at least 28px tall, and buttons inside pages are 26 tall.

### 6.6 Options (`UI/Settings.lua`)
```
Modules ───────────────────────────────────────────────────────────
[☑] Action Bars        Fills your keyboard action bars from your class layout.
[☑] Key Bindings       One key layout for Action Bars 1–3 and the pet bar.
[☑] Controller         Fills the Gamepad UI bars and Steam Deck back buttons.
[☑] Character Snapshot Saves your character for Claude Code to read (on reload, logout and after changes).
[☑] Fishing Helper     Puts your weapons back after fishing and warns when the lure runs out.
Window ────────────────────────────────────────────────────────────
Scale  [====|=====] 1.10      [Reset Position]
Character Snapshot ────────────────────────────────────────────────   (from ns.actions, grouped by section)
Last saved 14:02 · written to disk at your next /reload     [Save Now]
Log ─────────────────────────────────────────── ⓘ (keyboard: select and Ctrl+C to copy)
┌ ScrollingEditBox, fills to bottom ─────────────────────────────────┐
```
- **Module rows:** `UI.Check` rows, 32 tall.
  - The title comes from the new `mod.title` (fallback: `mod.name`), in `GameFontNormal`.
  - The description sits at `LEFT 150`, `GameFontHighlightSmall`, one line, truncated, with the full text in the tooltip.
  - Order follows the sidebar: Action Bars, Key Bindings, Controller, Snapshot, Fishing (sort by `mod.order or 500`).
- **Window section:** `Slider` with `MinimalSliderWithSteppersTemplate` **[VERIFY name; fallback `OptionsSliderTemplate`]**, 0.8–1.25, step 0.05, writing `ns.db.scale`. Plus "Reset Position".
- **Tools:** one header per `a.section`. Each action is a row: optional left text from a new optional `a.status` function, and an auto-width button labelled `a.label` ("Save Now"). The rows wrap vertically, never horizontally.
- **Log:**
  - `ScrollingEditBoxTemplate`.
  - `SetText` only when `#ns.log` or its last entry changed; never reset the cursor otherwise.
  - Store entries without the "Agentcraft:" prefix.
  - Empty text: "Messages from Agentcraft appear here."
- **Actions:** "Clear Log".
- **Status:** "%d of %d modules on".
- **Module-off behaviour (UI only):** when `mod.active == false`, its page row label is drawn in `GameFontDisable`, and the page shows a `UI.Empty` reading "Action Bars is turned off. Turn it on in Options." plus an [Open Options] button. The footer actions are hidden. (A page declares `module = "ActionBars"`.)

---

## 7. Controller-cursor and Gamepad UI

### 7.1 Detection
```lua
local function GamepadUI()
  return C_InputInterfaceStyle and Enum.InputDeviceInterfaceType
     and C_InputInterfaceStyle.GetCurrentStyle() == Enum.InputDeviceInterfaceType.Gamepad
end
```
Use this instead of `C_GamePad.IsEnabled()` for the "Gamepad UI off" warning **[VERIFY on Forever]**. Keep `IsEnabled` as a fallback on clients without `C_InputInterfaceStyle`.

### 7.2 Registering with FrameControlsManager (biggest Steam Deck fix)
- Open with `ShowUIPanel(frame)` when out of combat, and with `frame:Show()` in combat. Close with `HideUIPanel(frame)`.
- In `OnHide`, call `GamepadMode.FrameControlsManager:FrameHidden(frame)` when it exists and you are out of combat. Escape through UISpecialFrames only calls `Hide()`.
- `ns.ToggleUI` and `ns.OpenPage` go through these functions.
- Do **not** add a `UIPanelWindows` entry: the window stays free-floating and keeps its saved position.
- **[VERIFY in game]:** with the Gamepad UI on, `/ac` gets the gold focus glow, the D-pad walks nav rows → page → footer, A clicks, and B closes.

### 7.3 Focus hygiene
- Mark decorative frames ignored when `SmartNavigation_MarkFrameIgnored` exists: headers, legends, the version text, panels' backgrounds.
- Mark sub-sections when `SmartNavigation_MarkFrameSubSection` exists: nav inset = "nav", page = "page", button bar = "footer".
- Slots that carry information are Buttons (they already are), so OnEnter tooltips fire under smart navigation.
- Info-only FontStrings never hold information that is not also in a focusable element's tooltip or visible text.

### 7.4 LB/RB paging
While the window is shown, out of combat:
```lua
SetOverrideBindingClick(frame, true, "PADLSHOULDER", "AgentcraftPrevTab")
SetOverrideBindingClick(frame, true, "PADRSHOULDER", "AgentcraftNextTab")
```
- Clear them in OnHide with `ClearOverrideBindings(frame)`.
- These are hidden named Buttons.
- On Controller they cycle sets; on Macro Library, the scope tabs; elsewhere, sidebar pages.
- **[VERIFY]:** the Gamepad UI may own LB/RB for its own panel tabs or the radial. If the override does not fire or breaks the Gamepad UI, drop it; the tabs stay reachable with the D-pad.

### 7.5 Input legend
When `GamepadUI()` is true, show a line at the left of the button bar instead of the status text when the status is empty: `"[A] Select   [B] Close   [LB/RB] Switch"`, using `CreateAtlasMarkup` glyphs **[VERIFY glyph atlas names with an atlas dump; fallback bracketed text]**.

### 7.6 Other
- No hover-only state: the Keybinds detail pins (6.2), and truncated status/summary text has focusable tooltips.
- Destructive actions are never adjacent without a confirm. All Apply / Restore / Remove / Replace go through `UI.Confirm`.

---

## 8. Glossary and renamed strings

### 8.1 Glossary (use everywhere)
| Term | Meaning / replaces |
|---|---|
| Action Bar 1–5 | Edit Mode names. Replaces "Bar 1 / Shift / Alt / Right / Right 2", "bar 2", "Keyed bars" |
| Side bars | Action Bars 4–5 (replaces "Click-only bars") |
| Consumables | Action Bar 3 / the Alt row (replaces utility, utilities) |
| Layout | What Agentcraft puts on bars or keys (replaces plan, profile, home) |
| Added / Missing / Removed / Empty | Slot states (replaces placed, waiting, reserved, clear, Free) |
| Apply / Restore Original / Undo Last Apply | Button names; Title Case when naming the button |
| Key Bindings | Replaces Keybinds, binds |
| Not Bound | `NOT_BOUND` global (replaces "Unbound") |
| Gamepad UI | Blizzard's controller mode. "Controller" is only the page name |
| No trigger / Hold LT / Hold RT / Hold LT + RT | Controller bars (replaces Top/Left/Right/Bottom) |
| Set 1–3 | Controller pages (tabs "1 · Combat", "2 · Utility", "3 · Pet & Extras") |
| Flyout | Opens a radial on the gamepad |
| Back buttons | L4 L5 R4 R5 |
| General macro / Character macro | Replaces Account macro |
| Check / Checked | Replaces tick / ticked |
| Name in use / Requires X | Replaces Name taken / Locked (learn X) |
| Character Snapshot | The saved data Claude Code reads |
| Options | The page (replaces Settings) |

### 8.2 Renamed set (old → new; file)
- **Page titles:** "Action bars" → "Action Bars" (ActionBars.lua:642); "Keybinds" → "Key Bindings" (Keybinds.lua:176); "Macros" → "Macro Library" (Page.lua:333); "Settings" → "Options" (Settings.lua:9).
- **Module display titles** (new `title` field, keys unchanged): ActionBars → "Action Bars", Keybinds → "Key Bindings", Controller → "Controller", Snapshot → "Character Snapshot", Fishing → "Fishing Helper".
- **Module descriptions** (sentence case, third person):
  - "Fills your keyboard action bars from your class layout."
  - "One key layout for Action Bars 1–3 and the pet bar."
  - "Fills the Gamepad UI bars and Steam Deck back buttons."
  - "Saves your character for Claude Code to read (on reload, logout and after changes)."
  - "Puts your weapons back after fishing and warns when the lure runs out."
- **ActionBars `ROWS` labels** (display only): "Action Bar 1", "Action Bar 2", "Action Bar 3", "Action Bar 4", "Action Bar 5", plus the modifier sub-label. Group headers: "Bound to keys", "Side bars".
- **Controller `BAR_TITLE`:** "No trigger", "Hold LT", "Hold RT", "Hold LT + RT". `FillSlot` empty title "Free" → "Empty". "Free page" → "Empty".
- **Layout.lua page 3 title:** "Pet & Deck" → "Pet & Extras".
- **Status lines:** "Up to date" / "N changes to apply" / "N missing" / "N spells without a button" / "Gamepad UI off".
- **Legend words:** "Added", "Missing (not learned, not in bags, or macro not installed)", "Removed", "Unmarked: already in place", "Flyout (opens a radial)", "Empty".
- **Tooltips:**
  - "Added when you click Apply."
  - "Not learned yet. Added when you train it and Apply again."
  - "Macro not installed. Install it in the Macro Library, then Apply again."
  - "None in your bags. Added when you carry one and Apply again."
  - "Removed when you click Apply."
- **Macro footer:** "Clear tags / Tick shown / Remove / Install" → (filter-line clear) / "Check All" / "Remove Checked (N)" / "Install Checked (N)".
- **Macro scope:** tabs "For You" | "All Macros".
- **Macro state words** (Page.lua:14-20): "Installed", "Update", "Name in use", "Requires %s", none for ready. "Account macro" → "General macro".
- **Mouse labels:** `GetBindingText("BUTTON3"/"BUTTON4"/"BUTTON5")`.
- **Detail title:** "Key Q" → "Q key".
- **Slash commands** (Core/Window only):
  - `/ac bars` is added as an alias of `spells`.
  - `shots` is hidden unless `ns.db.dev`.
  - An unknown command prints "Unknown command 'foo'." first.
  - One help format: `"/ac bars [apply|undo] – open Action Bars, or apply/undo the layout"`.
  - Remove the duplicate help between Core.lua:215 and Window.lua:263 (keep Window's).
- **Chat sentence case and periods:** this is in module code. It is listed in §11, not done in this pass.
- **Macro names (FDTrap → FD Trap etc.):** these need install migration, so they are out of scope here (§11).

---

## 9. Core.lua registration additions (backward compatible)

```lua
-- RegisterModule: new optional fields
--   title   display name ("Action Bars"); default = name
--   order   sort position on Options; default 500
-- RegisterPage: new optional fields
--   section   "keyboard" | "gamepad" | "library" | "addon"   (nav header; default "addon")
--   module    module key whose .active gates the page
-- page.actions[i]: new optional fields
--   label     string or function(page) -> string   (re-read on Refresh)
--   enabled   function(page) -> bool               (b:SetEnabled each Refresh)
--   confirm   string or function(page) -> string|nil  (nil = no dialog)
--   primary   bool (rightmost; other order kept)
-- RegisterAction: optional 5th arg  status = function() -> string  (text left of the button)
function ns.LogLine(text)   -- append a pre-formatted line to ns.log (used by Window for errors)
```
- Section header labels, in a Window.lua table: keyboard = "Keyboard & Mouse", gamepad = "Gamepad", library = "Library", addon = "Agentcraft".
- `ns.Run` stores lines with the `|cff33ff99Agentcraft|r:` prefix stripped.

---

## 10. File-by-file implementation plan

1. **`Core.lua`**
   - Add the fields in §9 (docs in the existing comment blocks), `ns.LogLine`, prefix stripping in `ns.Run`, the unknown-command message and the `dev` gate for help listing.
   - Add `/ac scale` and `/ac reset` (they call `ns.UI.SetScale` / `ns.UI.ResetPosition`).
2. **`UI/Widgets.lua`**
   - Add `UI.C` (colour objects) and keep `UI.GREEN/RED/ORANGE/GOLD/BLUE` as rgb aliases derived from them.
   - Add `UI.Has(template)` and `UI.HasAtlas(name)` helpers. Move `HasTemplate` here from Window.lua and Macros/Page.lua.
   - New: `UI.Inset`, `UI.Panel`, `UI.Divider`, `UI.Check`, `UI.Tabs`, `UI.Filter`, `UI.Dropdown`, `UI.Scroll` (ScrollFrameTemplate + child, returns `scroll, child`), `UI.LogBox` (ScrollingEditBox wrapper with `SetTextIfChanged`), `UI.Confirm`, `UI.Empty`, `UI.LegendItem`.
   - Rework `UI.Header`: white `GameFontHighlightMedium`, an `Options_HorizontalDivider` rule under the text, width from the parent, optional `{hint=}`.
   - Rework `UI.Button`: auto width, an optional `height` argument.
   - Rework `UI.Tooltip`: use `GameTooltip_SetTitle` and `AddNormalLine`.
   - Rework `UI.Slot`: modern atlases with fallback; `SetMark` uses the tinted IconFrame-Border; add `SetBadge(kind)` (flyout/added); key font `NumberFontNormalSmall`.
   - `UI.KeyText` → `GetBindingText(key, nil, true)` with a width cap; keep the current replacements as fallback when `GetBindingText` is nil.
   - Keep `UI.Fill`, `UI.Border` and `UI.Swatch` (deprecated) for fallbacks and third-party pages.
3. **`UI/Window.lua`**
   - Rebuild per §1–2 and §7: ButtonFrameTemplate, the attic, the nav inset with sections and atlas rows, the page inset re-anchor, the MagicButton footer reading `label`/`enabled`/`confirm`/`primary`.
   - Status button with tooltip, `(+N more)`, error kinds, ns.LogLine on errors, footer hidden on build error.
   - Title-bar-only drag, saved position, scale, strata MEDIUM.
   - ShowUIPanel / HideUIPanel / FrameHidden, override LB/RB (guarded), the gamepad input legend.
   - `lastPage`, page `module` gating, `CharLine()`.
   - `/ac shots` behind `ns.db.dev`.
4. **`UI/Settings.lua`**
   - Title "Options", the gear icon, section "addon".
   - `UI.Check` module rows sorted by `mod.order` using `mod.title`.
   - The Window section (scale slider, Reset Position).
   - Tools grouped by section, wrapping vertically, with the `a.status` text.
   - `UI.LogBox` with `SetTextIfChanged`, the new empty text, and the header hint "(keyboard) select and Ctrl+C to copy".
   - Print "<title> turned on/off" only after `SetModuleEnabled` returns true **and** `mod.active` matches. **[VERIFY return semantics]**
5. **`Macros/Page.lua`**
   - Per §6.4: scope tabs, search + `UI.Filter` (delete the chip bar and LayoutChips), the active-filter line.
   - `UI.Scroll` list with 40px rows, `UI.Check`, draggable slots and atlas selection.
   - The detail panel as `UI.Panel` with re-chaining, a fixed-height `UI.LogBox`-style code box and stateful buttons with confirms.
   - Empty state with Reset Filters; selection preserved and scrolled into view.
   - `Ticked()` limited to visible rows; dynamic footer labels/enabled/confirm; status wording; title "Macro Library", section "library".
   - L.Tags de-dup (Library.lua:88-91) is a library-logic change → §11 (or de-dup on the page side when building the filter menu: group by label).
6. **`Modules/ActionBars.lua`**
   - Page block only (lines 598–735): geometry per §6.1, display row labels (a page-side table mapping row index → label; leave `ROWS` used by the planner alone or only change `.label`, which is display-only — **[VERIFY `.label` isn't used in chat output]**).
   - Legend via `UI.LegendItem`, hint text, empty state with the localized class, status wording with colour objects.
   - Actions: label/confirm/enabled/primary, `section="keyboard"`, `module="ActionBars"`, title and icon.
   - Module `title`/`description`/`order` fields.
7. **`Modules/Keybinds.lua`**
   - Page block only (lines 120–274): MOUSE_X 296 geometry, `GetBindingText` labels, dimmed non-layout keys, click-to-pin detail, the green/orange diff edges with "Replaces:" tooltips, `NOT_BOUND`, legend, note text with the glossary.
   - Status wording; actions with confirm; `section="keyboard"`; title "Key Bindings".
   - Do **not** change `/ac keys` raw print here (module command; §11).
8. **`Modules/Controller.lua`**
   - Page block only (lines 555–697): the content wrapper and empty state, `UI.Tabs`, panel geometry and order, **the diamond sign fix**, title clearance, `UI.Panel`, per-button fixed labels and tooltips.
   - D-pad arrows; neutral "no home" Empty state (page-side check of `p.item.missing == "no home"`); flyout badge instead of the gold edge.
   - Back-button slots 36 with inner labels and friendly tooltips; legend + pet-radial note; status reorder and wording via colour objects and `GamepadUI()`.
   - Actions renamed "Undo Last Apply" / "Apply" with confirm; `section="gamepad"`.
   - Edit the `BAR_TITLE` strings.
9. **`Modules/Layout.lua`:** the string "Pet & Deck" → "Pet & Extras" (data title only).
10. **`Modules/Snapshot.lua` / `Fishing.lua`:** add `title`/`order` to RegisterModule, sentence-case `description`, and an optional `status` function on the existing `RegisterAction` ("Last saved HH:MM"; read from existing snapshot fields **[VERIFY a timestamp field exists in the snapshot table]**). No logic change.
11. **`dev/harness/frames.lua` + `dev/render`:**
    - Emulate `MinimalCheckboxTemplate`, `PanelTopTabButtonTemplate` (+ the `PanelTemplates_*` globals), `MagicButtonTemplate`, `WowStyle1FilterDropdownTemplate` / `WowStyle1DropdownTemplate` (DropdownButton with `SetupMenu`/`SetText`/`SetDefaultText`), `ScrollingEditBoxTemplate`, `InsetFrameTemplate3`, `MinimalSliderWithSteppersTemplate`.
    - Emulate the globals `ShowUIPanel`/`HideUIPanel`, `StaticPopup_Show`, `GetBindingText`, `C_Texture.GetAtlasInfo` (true for the atlases listed here), `SetOverrideBindingClick`/`ClearOverrideBindings`, `C_ClassColor`, the `*_FONT_COLOR` objects with `WrapTextInColorCode`/`GetRGB`, and `NOT_BOUND`.
    - Add a render-warning rule that flags any `SetColorTexture` region larger than 4x4 under `AgentcraftFrame` (catches regressions to hand-drawn chrome).
    - Add `dev/tests` cases:
      - controller diamond: Up slot y > Down slot y;
      - no FontString overlaps in the attic at 1280x800 with a 110-char summary;
      - every footer action with `confirm` calls StaticPopup_Show;
      - page frame width = 600.
12. **`Agentcraft.toc`:** bump Version.

Order of work:
1. Widgets + Core fields, with the harness additions.
2. Window.
3. Settings.
4. Controller (the most visible bugs).
5. Action Bars.
6. Key Bindings.
7. Macro Library.
8. `dev.ps1 check` + render after each step.
9. In game: `/ac shots`, then `/reload`, and compare against the [VERIFY] list.

---

## 11. Out of scope for this pass (module logic; track separately)

- **Controller Apply clears slots the page shows as empty** (Controller.lua:342-345, 483-486). It needs the planner to emit `{state="clear"}` entries. Until then, the page can mark planned-empty slots that currently hold an action (`HasAction(slot)`) orange on the page side **[acceptable page-side approximation]**.
- **Undo semantics:** first-apply (Action Bars, Key Bindings) vs last-apply (Controller). This pass only relabels. Unifying them needs module changes.
- **Undo "enabled only with a backup":** needs a backup accessor (`M.HasBackup()`) in each module.
- **Library tag de-dup** (Library.lua:88-91), the `"can't fill KEY"` wording (Library.lua:268), PetToggleItem `macro=` (Controller.lua:134), and the racial title (Controller.lua:168).
- **Chat strings:** sentence case, `ERR_NOT_IN_COMBAT`, and `/ac keys` printing raw tokens with global `print` (Keybinds.lua:111-112).
- **Macro renames** (FD → Feign etc.), which need migration like the legacy "AC " prefix handling.
- **The tag "controller" on 23 of 30 macros:** drop it or turn it into a badge (data change).

---

## 12. [VERIFY] checklist (in game, Forever client, 1280x800, Gamepad UI on and off)

1. `ButtonFrameTemplate` look in Forever (bronze Camelot metal, rock bg, marble inset). `SetPortraitToClassIcon` exists.
2. MagicButtonTemplate chaining art in the 26px bar.
3. Atlases exist and look right: `Options_List_Active`, `Options_List_Hover`, `Options_CategoryHeader_1`, `Options_HorizontalDivider`, `UI-Character-Info-ScrollLine-Long`, `UI-HUD-ActionBar-IconFrame*` (all variants), `UI-HUD-ActionBar-Flyout`, `services-icon-warning`, gamepad glyph atlases.
4. `InsetFrameTemplate3` nested inside the marble inset; whether it looks too heavy.
5. `ScrollingEditBoxTemplate` API (read-only plus selectable) and `MinimalSliderWithSteppersTemplate` name.
6. Gamepad: ShowUIPanel registration gives focus glow, D-pad navigation and B to close. LB/RB overrides fire without breaking the Gamepad UI. StaticPopup is navigable.
7. `C_InputInterfaceStyle.GetCurrentStyle()` reports Gamepad on Forever. PS pad detection API.
8. Fixed face-button functions (A/B/X/Y) in the Gamepad UI bindings.
9. Arrow glyphs render in Friz Quadrata.
10. `ORANGE_FONT_COLOR` and `C_ClassColor` on the classic-flavor clients in the TOC (fall back to literals).
11. Window fits at scale 1.25 on the Deck; the summary truncates without hitting the character line.
12. The "Added" green border does not read as "equipped item".
13. `ActionBars ROWS[].label` and the Settings `SetModuleEnabled` return semantics (code check).

---

## Sources
- Forever FrameXML (Mainline + Camelot overrides):
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Blizzard_SharedXML.toc
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Camelot/NineSliceLayoutOverrides.lua
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Camelot/SharedUIPanelTemplates.lua
- Templates:
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/PortraitFrame.lua
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/Button/CheckButtonTemplates.xml
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/InputBox/InputBoxTemplates.xml
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Menu/11_0_0_MenuImplementationGuide.lua
- Settings list model:
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_CategoryList.lua
  - https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_SettingsPanel.xml
- Forever reference windows:
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/SkillsFrame.xml
- Gamepad:
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSharedUtility/FrameControlsManager.lua
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSmartNavigation/SmartNavigation.lua
  - https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua
  - https://news.blizzard.com/article/24316974/wow
  - https://www.warcrafttavern.com/forever/guides/controller/
- Forever look:
  - https://www.warcrafttavern.com/forever/news/classicui-forever-addon-makes-wow-forever-truly-feel-like-classic/
  - https://www.curseforge.com/wow/addons/pewter
  - https://www.method.gg/wow-forever/understanding-wow-forevers-ui
  - https://news.blizzard.com/article/24315821/wow
- Naming and API:
  - https://warcraft.wiki.gg/wiki/ColorMixin
  - https://warcraft.wiki.gg/wiki/API:GetBindingText
  - https://warcraft.wiki.gg/wiki/Action_bar
  - https://warcraft.wiki.gg/wiki/ActionSlot
  - https://warcraft.wiki.gg/wiki/HOWTO:_Make_a_Macro
  - https://warcraft.wiki.gg/wiki/Making_scrollable_frames

## Repo files referenced
- C:/Users/erik/code/agentcraft/skills/extending-addon/SKILL.md
- C:/Users/erik/code/agentcraft/addon/Agentcraft/Core.lua
- C:/Users/erik/code/agentcraft/addon/Agentcraft/UI/Window.lua
- C:/Users/erik/code/agentcraft/addon/Agentcraft/UI/Widgets.lua
- C:/Users/erik/code/agentcraft/addon/Agentcraft/UI/Settings.lua
- C:/Users/erik/code/agentcraft/addon/Agentcraft/Macros/Page.lua
- C:/Users/erik/code/agentcraft/addon/Agentcraft/Modules/ActionBars.lua
- C:/Users/erik/code/agentcraft/addon/Agentcraft/Modules/Keybinds.lua
- C:/Users/erik/code/agentcraft/addon/Agentcraft/Modules/Controller.lua
- C:/Users/erik/code/agentcraft/addon/Agentcraft/Modules/Layout.lua
- C:/Users/erik/code/agentcraft/addon/Agentcraft/Modules/Snapshot.lua
- C:/Users/erik/code/agentcraft/dev/harness/frames.lua
- C:/Users/erik/code/agentcraft/dev/render/render.lua
- C:/Users/erik/code/agentcraft/dev/render/out/index.html