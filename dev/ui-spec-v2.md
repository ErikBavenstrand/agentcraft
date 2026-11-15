# Agentcraft `/ac` window — design spec v2 ("The War Table")

Status: final design, ready to implement. It replaces `dev/ui-spec.md` (v1) as the design of record; v1 stays in the repo as history. Widget API changes go into `dev/ui-widgets.md` as each phase lands.

Target: WoW Forever (Classic content on the modern 12.x client, project "Camelot"). Owner plays with keyboard and mouse, and with the native Gamepad UI on a Steam Deck (1280x800; sticks, D-pad, A/B/X/Y, LB/RB, LT/RT; back buttons L4/L5/R4/R5 = F13-F16).

Items marked **[VERIFY in game]** depend on client behaviour that the source alone can't settle. §14 collects them all.

---

## 0. Decision: concept scores

Each concept scored 1-10 (10 = best; for risk, 10 = safest). Weights follow the brief: usability first, then visual delight and immersion, then authenticity, then risk. Intuitiveness ×3, controller ×3, keyboard ×2, visual delight ×2.5, authenticity ×2, risk ×1.5 (sum 14).

| Criterion (weight) | A "The Loadout" (controller-first) | B "Forever-native" | C "The War Table" (stunning) |
|---|---|---|---|
| Intuitiveness (×3) | 8: Stage+Inspector, consistent A/B/X/Y | 8: five distinct "rooms", the page title is always visible | **9**: Now/After, Review sheet, "Coming next", the prompts double as buttons |
| Controller usability (×3) | **9**: one large layer at a time, trigger-peek | 8: SmartNav path, no stick capture | 8: trigger-peek, the Review sheet scrolls on the right stick |
| Keyboard usability (×2) | 7: many Ctrl chords; R3/Ctrl+D compare | **8**: Tab-engage model, few chords | 7: Ctrl-peek clashes with Ctrl chords |
| Forever/Blizzard authenticity (×2) | 7: a single giant diamond is not how the native HUD looks | **9**: CharacterFrame grammar, side tabs, ledger | 8: Character-sheet grammar, c60 art |
| Visual delight / immersion (×2.5) | 8: proc cascade, hero model | 7: polished but calmer | **9**: apply ceremony, readiness meter, model, ambient art |
| Implementation risk (×1.5) | 6: R3 override, trigger-paging override, a large surface | **8**: smallest client-behaviour surface | 6: many render variants, GlowEmitter, trigger-paging override |
| **Weighted score (out of 10)** | 108/14 = **7.71** | 111.5/14 = **7.96** | 112.5/14 = **8.04** |

**Base: C, "The War Table".** It has the highest weighted score and best meets the owner's call for a complete, visually stunning, immersive redesign. Grafts:
- **From B:** the low-risk input plumbing. Prompts hide for mouse-only use. Ctrl+Space toggles; no R3 and no Ctrl-hold peek. The Options "ledger". `MODIFIER_STATE_CHANGED`-driven previews. Old page-id aliases. The 0-warnings render gate. Module-off handling with a [Turn On] button.
- **From A:** permanent Inspector cross-references ("Also on: …"). The view strip at the top of each stage. X means "change what you're looking at" on every page. The pet-autocast ants. "Plain spell until you install X → (A) Go there".
- **New in v2, from the owner's latest requirements:** the Controller page is drawn as a faithful copy of Blizzard's own **Gamepad action bar HUD** (`GamepadMainActionBarFrame`): square D-pad slots, round face-button slots, a glyph on every button, and four bars arranged as a cross (Top / Left LT / Right RT / Bottom LT+RT). It uses Blizzard's own `gamepad-actionbar-*` atlases. Every page also gets a **List view** that shows icon and name side by side, readable at a glance on the Deck.

---

## 1. Principles

1. **See it the way you play it.** The Keyboard page is a keyboard and the Controller page is the native controller HUD. Holding a modifier (Shift/Alt, or LT/RT on the Deck) shows that layer live.
2. **Nothing is hover-only.** The Inspector pane always explains the focused element in full. A D-pad user sees everything a mouse user sees.
3. **Icon + name, always.** Every slot that holds something shows its name somewhere visible without hovering: under the keycap, in the List view, or in the Inspector bar card. The Deck must read it at arm's length.
4. **One focus, three inputs.** Mouse hover, arrow keys and the Gamepad UI cursor move one shared focus. Scrolling follows focus. Every edge has an exit. Focus survives refreshes.
5. **Stock art only for chrome.** Forever paints the stock templates and atlases bronze itself, so we never tint them ([forever NineSliceLayoutOverrides](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Camelot/NineSliceLayoutOverrides.lua)). Our own flat plates use near-black plus a bronze #E69E52 rule ([ClassicUI Forever Bronze.lua](https://github.com/wowaddonmaker/classicuiforever/blob/main/Art/Bronze.lua)).
6. **Ceremony for commits.** Apply goes through a Review sheet, then plays a proc-glow cascade with Blizzard's talent-commit sound.
7. **Combat-safe.** The window stays open but goes read-only in combat. Never leave an override binding or a non-propagating keyboard state behind.

---

## 2. Naming

| Thing | Name shown | id | Old ids aliased by `ns.OpenPage` |
|---|---|---|---|
| Window title | Agentcraft | — | — |
| Landing page | **Overview** | `overview` | — |
| Bars + key binds | **Keyboard** | `keyboard` | `bars`, `keys` |
| Gamepad UI bars + back buttons | **Controller** | `controller` | — |
| Macro library | **Macros** (the page art is a spellbook) | `macros` | `library` |
| Settings | **Options** | `options` | `settings` |
| Right-hand pane | Inspector (never labelled in the UI) | — | — |
| Commit sheet | "Review changes" | — | — |
| Layer names, Keyboard | Plain, Shift, Alt, Side bars | — | — |
| Layer names, Controller | No trigger, Hold LT, Hold RT, Hold LT + RT (existing `BAR_TITLE`) | — | — |
| Controller sets | 1 · Combat, 2 · Utility, 3 · Pet & Extras (from the layout titles) | — | — |
| Back buttons | L4, L5, R4, R5, plus a "Kept free for now" caption | — | — |

The user-facing word is "Controller", not "Gamepad". "Grimoire" is dropped as a label: "Macros" is clearer, and the book art carries the flavour.

---

## 3. Shell

### 3.1 Frame

- `CreateFrame("Frame", "AgentcraftFrame", UIParent, "PortraitFrameTemplate")`. Fallbacks: `ButtonFrameTemplate`, then `BasicFrameTemplateWithInset`.
- **Size 1000x640.** On a 1280x800 Deck at UI scale 1, UIParent is about 1229x768.
  - At the Gamepad-UI auto scale of 1.1, the window is 1100x704. The side tabs add 44 px x 1.1, for 1148 wide in total. Both fit with a 20 px margin.
  - The clamp in `UI.SetScale` includes the tab width: `(1000+44)*s ≤ W-20` and `640*s ≤ H-20`.
- Strata MEDIUM, `SetToplevel(true)`, `SetClampedToScreen(true)`. Drag by the title bar only. The saved position and `/ac reset` work as today.
- Portrait: `frame:SetPortraitToUnit("player")` (PortraitFrameMixin, 12.x), refreshed on `UNIT_PORTRAIT_UPDATE` for the player. Fallback: `SetPortraitToClassIcon`. [VERIFY in game] that SetPortraitToUnit exists on Forever's PortraitFrameTemplate.
- Shown through `ShowUIPanel`/`HideUIPanel`. In OnShow, also call `GamepadMode.FrameControlsManager:FrameShown(self)` out of combat; it is a no-op if already shown ([FrameControlsManager.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSharedUtility/FrameControlsManager.lua)). Keep the frame in `UISpecialFrames`, so loss of control still closes it.
- No `SetVertexColor` on any stock art.

### 3.2 Regions (frame coordinates, origin TOPLEFT, y down is negative)

```
 x:0                                                                                     1000
 ┌[portrait]────────────────────────── Agentcraft ─────────────────────────────────────[X]┐ ┌───┐
 │  (60)   PAGE TITLE (GameFontHighlightLarge)          ▕██████████████░░░▏ 41 / 44 in place │ │LB │ glyph (pad mode)
 │         summary line (GameFontNormal, coloured counts)        Level 60 Hunter (class col.)│ ├───┤
 ├──────────────────────────────────────────────────────────┬─────────────────────────────┤ │ ◆ │ Overview
 │ y -84                                                     │ x 728                       │ │ ⌨ │ Keyboard
 │ STAGE  712 x 512  (TOPLEFT 8,-84 / BOTTOMRIGHT -280,44)   │ INSPECTOR 264 x 512         │ │ ✚ │ Controller
 │  - view strip (32 px) at the top                          │ (TOPRIGHT -8,-84 /          │ │ 📖│ Macros
 │  - page art + content                                     │  BOTTOMRIGHT -8,44)         │ │ ⚙ │ Options
 │  - toast / combat banner slides in at its top edge        │                             │ ├───┤
 │                                                           │                             │ │RB │ glyph (pad mode)
 ├──────────────────────────────────────────────────────────┴─────────────────────────────┤ └───┘
 │ ✓ Keyboard applied · 12 slots          (A) Select (B) Back (X) Layer   [(Y) Review & Apply 9]│ y -604..-636
 └─────────────────────────────────────────────────────────────────────────────────────────┘
```

| Region | Anchor / size | Build |
|---|---|---|
| Page title | TOPLEFT 66,-30 | FontString `GameFontHighlightLarge` |
| Summary | TOPLEFT 66,-50, RIGHT to meter.LEFT -16 | `GameFontNormal`, one line, counts wrapped in `UI.C` colours. Tooltip lists the breakdown (from `page:Status()` tip). |
| Readiness meter | TOPRIGHT -16,-34, 200x12 | `UI.Meter`: `ColoredProgressBarTemplate` with fill `common-stat-bar-green`, or `common-stat-bar-white` while changes are pending. Label "41 / 44 in place" in `GameFontHighlightSmall` above it, right-aligned. Hidden on pages with no `readiness`. |
| Character line | TOPRIGHT -16,-54 | "Level 60 Hunter", class word in `C_ClassColor.GetClassColor(class)`. This is the only class-coloured chrome. |
| Stage | TOPLEFT 8,-84 / BOTTOMRIGHT -280,44 | `InsetFrameTemplate` (`UI.Inset`). The page draws its background art inside. `ShadowOverlayTemplate` child, setAllPoints, for the inner vignette. |
| Divider | between Stage and Inspector, x 720..728 | atlas `common-framedivider`, stretched vertically to the stage height; fallback a vertical `UI-Character-Info-ScrollLine` |
| Inspector | TOPRIGHT -8,-84 / BOTTOMRIGHT -8,44, width 264 | Background atlases `UI-Character-Info-Stat-BG` (fill) and `UI-Character-Info-Stat-StoneBG3` (bottom 120 px). Content API in §7. |
| Prompt bar | BOTTOMLEFT 8,6 / BOTTOMRIGHT -8,6, height 32 | Left: the toast/status button. Right: prompt buttons, primary rightmost (§5.4). |
| Side tabs | TOPLEFT to frame TOPRIGHT, x -2, y -96, step 52 | 5 × `LargeSideTabButtonTemplate` (Camelot shifts their icon -4,0 itself: [Camelot SharedUIPanelTemplates.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Camelot/SharedUIPanelTemplates.lua)). Flag `_acOutsideOK = true` for the renderer. |
| LB / RB indicators | centred above tab 1 and below tab 5 | 24 px glyph texture `UI.GlyphAtlas("PADLSHOULDER")` / `("PADRSHOULDER")`. Shown in pad prompt mode only. This copies `GamepadTabIndicatorsTemplate isVertical`, used on Camelot CharacterFrame ([CharacterFrame.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml)), without calling it. |

Tab fallback when `LargeSideTabButtonTemplate` is missing: a `PanelTopTabButtonTemplate` strip with labels across the top of the stage (`UI.Tabs`). The stage then starts 32 px lower.

How icon-only tabs stay readable: the page title names the current page, and the LB/RB prompt names the neighbours ("◀ Overview · Controller ▶"). A focused tab fills the Inspector with that page's description.

### 3.3 Window states

| State | What changes |
|---|---|
| Normal | as above |
| **In combat** (`PLAYER_REGEN_DISABLED`) | A banner slides into the stage top: 28 px plate, text "In combat · changes wait until combat ends" in `GameFontHighlight`, left icon atlas `services-icon-warning`, plate background `common-stat-bar-red` at alpha .35. The primary prompt and all Apply/Install buttons disable, and their prompts grey out with " (in combat)". Browsing, focus and tooltips keep working. Overrides are cleared and keyboard input is released (§4.6). |
| Module off | The stage shows `UI.Empty` "Key Bindings is turned off." with a [Turn On] button that toggles it directly. Keyboard greys only the half whose module is off. |
| Page build error | `UI.Empty` "This page failed to load. Details are in Options › Log." |
| Toast | Slides down from y +32 to 0 at the stage top over 0.2 s and holds 4 s; errors stay until B, Esc or a click. Fades out over 0.3 s. It also writes the full text to the log (`ns.LogLine`). The prompt bar's left button keeps the last result; focus it to read it in the Inspector. |

---

## 4. Input model: one focus, three inputs

### 4.1 The focus core (`UI/Input.lua`, `ns.Focus`)

- **Node:** any interactive Button. Optional fields:

| Field | Meaning |
|---|---|
| `node.acId` | Stable string id ("key:Q", "pad:1:LT:A", "macro:Opener"), used for focus restore |
| `node.acInspect(node, pane)` | Fills the Inspector |
| `node.acTip(node)` | Tooltip builder; `UI.Tooltip` sets it |
| `node.acActivate(node)` | What A / Enter does (default `node:Click()`) |
| `node.acFocusStyle` | "slot", "circle", "row", "card", "button", "chip" |
| `node.navUp/navDown/navLeft/navRight` | Explicit neighbour (node or fn) |
| `node.acScroll` | The `UI.ScrollList` that owns the node, for scroll-into-view |

- **Zones:** `page:Zones()` returns ordered lists of nodes. Standard zone order: `view` (strip) → `stage` → `inspector` → `prompts`. The side tabs are a zone too, but only mouse, LB/RB and Ctrl+1..5 reach them; D-pad Right from the inspector's right edge also reaches them.
- **`Focus:Set(node, source)`**, where source is "mouse", "key" or "pad":
  1. Calls the old node's `FocusExit` visuals (`OnLeave`) and the new node's `OnEnter` visuals.
  2. Moves the single **FocusRing** (§6.6).
  3. Scrolls the node into view (§4.5).
  4. After 0.12 s with no further move, calls `node.acInspect` so the Inspector doesn't flicker while you sweep a grid.
  5. Shows `node.acTip` after 0.25 s, only when source is "mouse" or Options › "Tooltips on focus" is on. The Inspector already shows everything.
  6. Plays the focus tick when source is not "mouse" (§6.8).
  7. Remembers `page.lastFocusId = node.acId`.
- **Mouse:** `OnEnter` calls `Focus:Set(node, "mouse")`. Hover and keyboard focus never disagree.
- **Restore (no lost focus):** after any Refresh, page switch, list re-pool or view change, `Focus:Restore()` runs this ladder:
  1. the node with `page.lastFocusId`;
  2. the node at the same zone and index;
  3. the nearest node by `Neighbor` from the old rect;
  4. `page:DefaultFocus()`.

  A focused node that becomes hidden or disabled triggers the same ladder at once. In pad mode the result is also pushed to SmartNav with `SmartNavigation:SetTargetButtonForFrame(frame, node)`.
- **Spatial neighbour:** `Neighbor(cur, dir, list)` scores `along + 2·|cross|` on `GetCenter()·GetEffectiveScale()`, explicit `nav*` first (keyboard-nav research, §2.G). It is used by the keyboard and by the pad path with the Gamepad UI off.

### 4.2 Path A: Gamepad UI on (the Steam Deck)

Blizzard's SmartNavigation drives the D-pad (move), A (click) and B (close handler), and the right stick scrolls the registered scroll frame ([SmartNavigation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSmartNavigation/SmartNavigation.lua)). Its `FocusEnter` runs our `OnEnter`, so `ns.Focus` stays in sync. We add:

- `btn.OnSmartNavSelect = function(b) ns.Focus:Set(b, "pad") end` on every node.
- `frame.FocusGamepad` → `Input.BindPad(true)`; `frame.UnfocusGamepad` → `Input.BindPad(false)`.
- `frame.SmartNavigationCloseHandler = function() return ns.Esc.Pop() end`. It returns true while a layer was popped; when the stack is empty it returns false, so FCM clicks the CloseButton.
- Our own override bindings, owned by the frame with priority true, set only while FCM has given us focus and out of combat:

| Key | Hidden button | Does |
|---|---|---|
| `PAD4` (Y) | `AgentcraftPadY` | page primary (Review & Apply / Install) |
| `PAD3` (X) | `AgentcraftPadX` | page view cycle |
| `PADLSHOULDER` (LB) | `AgentcraftPrevTab` | previous page |
| `PADRSHOULDER` (RB) | `AgentcraftNextTab` | next page |

- After each build, refresh or page switch, out of combat:
  - `UI.MarkIgnored` on all art.
  - `SmartNavigation:RefreshButtonGroups(frame)` (it picks up pooled rows).
  - `SetTargetButtonForFrame(frame, restoredNode)`.
  - `SetScrollFrameForFrame(frame, page:ScrollRegion())`.
  - `SmartNavigation_AddBidirectionalJumpNavigationOverride` from stage right-edge nodes to the Inspector's first button, and from the Inspector's bottom to the primary prompt.
- **LT/RT:** by default they stay FCM's (they cycle open Blizzard windows). On the **Controller page only**, set `frame.disableFrameFocusPagingWhenFocused = true`, so holding LT/RT previews the layer (§9.3); clear it on leaving the page. [VERIFY in game]
- Never call `SmartNavigation:SelectButton`, the `GamepadMode` binding groups, `TabIndicators` or `PromptedBindingFooter` (gamepad-nav research §1).
- Confirms use `StaticPopup` (`UI.Confirm`). `GamepadPopupHandler` gives them A/B glyphs and bindings for free ([StaticPopupGamepad.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_StaticPopup/StaticPopupGamepad.lua)).

### 4.3 Path B: keyboard (and a controller with the Gamepad UI off)

- `frame:EnableKeyboard(true)`. The resting state is `SetPropagateKeyboardInput(true)`.
- **Engaged mode.** The window takes arrows, Enter and Space only after one of these: Tab, a click inside the window, or any window chord. While not engaged, only Tab and the chords are taken.
  - Disengaged by: Esc (as a layer), a world click, a movement binding (`GetBindingFromClick(key)` in the PASS table: MOVEFORWARD, MOVEBACKWARD, TURNLEFT, TURNRIGHT, STRAFELEFT, STRAFERIGHT, JUMP, TOGGLEAUTORUN), or hiding the window.
  - WASD is never consumed.
- `OnKeyDown(self, key)`:
  1. In combat or with `GetCurrentKeyBoardFocus()` set: return without touching propagation.
  2. `handled = ns.Focus:HandleKey(key)`, true only when consumed.
  3. `self:SetPropagateKeyboardInput(not handled)`.

  `OnKeyUp` resets propagation to true (out of combat).
- Held arrows repeat: after 0.35 s, a `C_Timer.NewTicker(0.08)`, cancelled in OnKeyUp, on hide and in combat.
- **Chords** are override bindings owned by the frame while it is shown, out of combat. Zero propagation risk:

| Chord | Does |
|---|---|
| `CTRL-TAB` / `CTRL-SHIFT-TAB` | next / previous page |
| `CTRL-1` .. `CTRL-5` | jump to page 1-5 |
| `CTRL-ENTER` | primary (same as Y) |
| `CTRL-SPACE` | view cycle (same as X) |
| `CTRL-F` | focus search (Macros) |

  [VERIFY in game] that these chords are free in the owner's bindings. If one clashes, Options › "Window shortcuts" turns the chords off.
- **Controller with the Gamepad UI off** (`C_GamePad.IsEnabled()` true but the interface style is not Gamepad): override-bind `PADDUP/PADDDOWN/PADDLEFT/PADDRIGHT/PAD1/PAD2/PAD3/PAD4/PADLSHOULDER/PADRSHOULDER` to hidden buttons that call `Focus:Move`, `Activate`, `Esc.Pop`, X, Y and the page switch. Same lifetime rules. Never `EnableGamePadButton`.

### 4.4 Back / Escape: one layer stack (`ns.Esc`)

`ns.Esc.Push(closeFn, tag)` / `ns.Esc.Pop()` → bool. Pop order (top first):
1. An open dropdown or menu (Blizzard closes these itself, before us).
2. A focused search box: the first press clears the text, the second clears focus. These are handled in the box's `OnEscapePressed`, so no stack pop happens.
3. The Review sheet.
4. A sub-view (Options › Log).
5. A pinned Inspector (A on a slot pins it).
6. Keyboard engaged mode.
7. Empty stack: close the window (`HideUIPanel`, sound 840).

Wiring:
- Pad B goes through `SmartNavigationCloseHandler`.
- Escape goes through `RegisterGameMenuEscHandler(GameMenuEscPriority.AddOn, Esc.Pop)` when both globals exist ([Blizzard_GameMenuEsc.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_GameMenuEsc/Blizzard_GameMenuEsc.lua)) [VERIFY in game: present on Forever?]. Otherwise OnKeyDown handles `GetBindingFromClick(key) == "TOGGLEGAMEMENU"`: it consumes the key only when a layer popped, and lets the last Escape propagate so `UISpecialFrames` closes the window.
- Right-clicking empty stage area also pops a layer.

### 4.5 Scrolling and paging rules (excellent, no dead ends)

All scrollable content uses **one widget**, `UI.ScrollList` (§10.2): `WowScrollBoxList` + `MinimalScrollBar` through `ScrollUtil.InitScrollBoxListWithScrollBar`, with a fallback to `UI.Scroll`.

| Rule | Implementation |
|---|---|
| Scroll follows focus | `Focus:Set` calls `node.acScroll:ScrollToElementData(node.acData, ScrollBoxConstants.AlignNearest)`; the fallback is the ScrollFrame's `SetVerticalScroll` clamp. The focused row keeps one row of context above and below ("nearest + 1"). |
| Right stick (pad) | `SmartNavigation:SetScrollFrameForFrame(frame, list.ScrollBox)` whenever a list is the focused zone. Stick scrolling moves focus to the first fully visible row when the old focus scrolls out, so focus is never off-screen. |
| Mouse wheel | Native on the ScrollBox: 1 wheel tick = 1 row (`list:SetWheelStep(rowHeight)`). On paged views (Macros book) a wheel tick turns the page. |
| Keyboard | Arrows move focus row by row. `PAGEUP`/`PAGEDOWN` (engaged, list zone focused only) jump one visible page. `HOME`/`END` go to the first/last row. All of these are consumed only while engaged. |
| Edges | Up from the first row goes to the view strip. Down from the last row goes to the prompt bar. Left/Right from a list go to the neighbouring zone. Lists do not wrap vertically (wrap disorients on long lists). Grids wrap horizontally within a row only on the Controller HUD (where Blizzard's own D-pad diamond implies it). |
| Paged views | At a page edge, D-pad or arrow Left/Right turns the page and lands on the mirrored slot (same row, opposite column). The page buttons are focusable too. `IG_ABILITY_PAGE_TURN` plays. |
| Scroll indicator | `MinimalScrollBar` is shown only when content overflows. Fade masks top and bottom (WHITE8x8 vertical gradient, 16 px, alpha .6 → 0) show that more content exists. |
| Large jumps | LB/RB always change page, never scroll. X never scrolls. |

### 4.6 Combat and taint rules

- On `PLAYER_REGEN_DISABLED` (still unlocked inside the handler, per [InCombatLockdown](https://warcraft.wiki.gg/wiki/InCombatLockdown)): `ClearOverrideBindings(frame)`, `SetPropagateKeyboardInput(true)`, `EnableKeyboard(false)`, cancel repeat tickers, disengage, show the banner.
- On `PLAYER_REGEN_ENABLED`: if shown, re-enable the keyboard and re-bind (pad overrides only while FCM focus is held). Run any queued `ClearOverrideBindings` from a hide during combat. This fixes today's leak at `UI/Window.lua:653`.
- All SmartNav marking and jump overrides happen at build/refresh time out of combat; anything requested in combat is queued for REGEN_ENABLED.
- Never write Blizzard tables or methods. Our fields on our own frame (`FocusGamepad`, `SmartNavigationCloseHandler`, `OnSmartNavSelect`, `disableFrameFocusPagingWhenFocused`) are fine.

### 4.7 Global button map (every page)

| Intent | Gamepad UI on (Deck) | Keyboard | Mouse |
|---|---|---|---|
| Move focus | D-pad (SmartNav) | Tab / Shift-Tab zones; arrows once engaged | hover |
| Activate / select / pin | **A** | Enter / Space | left-click |
| Back (pop layer, then close) | **B** | Esc | [X] button; right-click empty stage |
| Primary (Review & Apply / Install) | **Y** | Ctrl+Enter | gold prompt button |
| Change view (layer / set / scope) | **X** | Ctrl+Space | click a view-strip chip |
| Previous / next page | **LB / RB** | Ctrl+Shift+Tab / Ctrl+Tab; Ctrl+1..5 | side tabs |
| Scroll a list | right stick | arrows (focus scrolls); PgUp/PgDn; Home/End | wheel |
| Preview a layer | hold LT / RT / both (Controller page) | hold Shift / Alt (Keyboard page); Shift / Ctrl (Controller page) | same keys |
| Cycle Blizzard windows | LT / RT tap (FCM), except on the Controller page | — | — |
| Back paddles L4/L5/R4/R5 | **unused** (owner rule) | — | — |

---

## 5. Glyph prompts

### 5.1 Glyph source

- `UI.PadMode()`: true when the prompt style is "pad". The style is "auto" (default), "keyboard" or "pad" from Options › "Button prompts". In auto mode:
  - `C_InputInterfaceStyle.GetCurrentStyle() == Enum.InputDeviceInterfaceType.Gamepad` → pad;
  - else the last device used: a handled key → keyboard; a pad override press or `GAME_PAD_ACTIVE_CHANGED(true)` → pad;
  - mouse-only use (no key or pad input since open) → "mouse": the prompt bar shows only the clickable buttons, no glyphs (from B).
- `UI.GlyphAtlas(key)` → `InputIconTextureSetUtility.GetNormalActiveInputIconButtonTexture(key)` inside a `pcall`, accepted only if `C_Texture.GetAtlasInfo` knows it ([InputIconTexture.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/InputIcons/InputIconTexture.lua)). This resolves the label style from `C_GamePad.GetDeviceMappedState(id).labelStyle`:
  - Letters / Generic: `gamepad-xbox1-buttona-normal`, `-buttonb-`, `-buttonx-`, `-buttony-`, `gamepad-xbox1-trigger-lb-normal`, `-rb-`, `-lt-`, `-rt-`, `gamepad-xbox1-dpadup-normal` (and down/left/right)
  - Shapes: `gamepad-ps-buttoncrox-normal`, `-buttoncircle-`, `-buttonsquare-`, `-buttontriangle-`
  - Reverse (Nintendo): `gamepad-switch-128x-face-b-normal` for PAD1, and so on

  The Steam Deck under Steam Input is expected to report "Letters". [VERIFY in game]
- **Static fallback table** (used when the utility is missing, e.g. in the harness or on other clients):

```lua
UI.GLYPH_FALLBACK = {
  PAD1 = "gamepad-xbox1-buttona-normal", PAD2 = "gamepad-xbox1-buttonb-normal",
  PAD3 = "gamepad-xbox1-buttonx-normal", PAD4 = "gamepad-xbox1-buttony-normal",
  PADLSHOULDER = "gamepad-xbox1-trigger-lb-normal", PADRSHOULDER = "gamepad-xbox1-trigger-rb-normal",
  PADLTRIGGER  = "gamepad-xbox1-trigger-lt-normal", PADRTRIGGER  = "gamepad-xbox1-trigger-rt-normal",
  PADDUP = "gamepad-xbox1-dpadup-normal", PADDDOWN = "gamepad-xbox1-dpaddown-normal",
  PADDLEFT = "gamepad-xbox1-dpadleft-normal", PADDRIGHT = "gamepad-xbox1-dpadright-normal",
}
```
  The fallback names `-dpaddown/-dpadleft/-dpadright` follow the pattern of the verified `-dpadup-normal`. [VERIFY with -Fetch / atlas dump]
- The old `Gamepad_Ltr_A_32` atlases are removed.
- **Back paddles** (F13-F16) always draw as keycaps "L4", "L5", "R4", "R5".
- **Keycaps** (keyboard mode): `UI.Keycap(parent, text, h)`, a plate atlas `UI-HUD-ActionBar-IconFrame-Background` stretched to `textWidth+12` × h, with the text in `NumberFontNormal`. Fallback: the bracketed text "[Ctrl+Enter]".
- **Refresh triggers:** `InputDeviceIconSetManager:RegisterActiveInputDeviceIconSetUpdatedCallback(UI.RefreshPrompts, UI)` ([InputDeviceIconSetManager.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/InputIcons/InputDeviceIconSetManager.lua)), plus the events `INPUT_DEVICE_INTERFACE_TRANSITION`, `GAME_PAD_ACTIVE_CHANGED` and `GAME_PAD_CONNECTED`.

### 5.2 Keycap text per pad key (keyboard mode)

| Pad | Keyboard prompt |
|---|---|
| A | Enter |
| B | Esc |
| X | Ctrl+Space |
| Y | Ctrl+Enter |
| LB / RB | Ctrl+⇧Tab / Ctrl+Tab |
| D-pad | Arrows |

### 5.3 Prompt look

Copied from Blizzard's `GamepadPersistentInputLegend`, which uses `GameFontNormal` prompts with 18 px icons ([GamepadPersistentInputLegend.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Gamepad/UI/PersistentInputLegend/GamepadPersistentInputLegend.lua)). Ours use 22 px glyphs, because the Deck screen is small and viewed at arm's length.

### 5.4 Prompt bar

- Each prompt is a **focusable Button** made by `UI.Prompt(parent, key, label, fn)`: a 22 px glyph (or keycap), 4 px gap, label in `GameFontNormal`, height 28, highlight atlas `Options_List_Hover`. Mouse users click it, so v1's separate footer button row is gone.
- The **primary prompt** is `UIPanelGoldButtonTemplate` (fallback `UIPanelButtonTemplate`), height 28, with the glyph inline at its left: "(Y) Review & Apply 9".
  - While changes are pending it wears `GlowEmitterFactory:Show(btn, GlowEmitterMixin.Anims.FaintFadeAnim)` inside a `pcall` ([GlowEmitter.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameEffects/GlowEmitter.lua)).
  - Fallback glow: `newplayertutorial-yellowGlow-redbutton-left` / `-middle` / `-right` in ADD at a .35/.35 s alpha pulse.
- A prompt whose action doesn't apply is **hidden** and the bar re-flows. In combat, actions are greyed rather than hidden, so the layout doesn't jump.
- Order, right to left: primary (Y), X, B, A. LB/RB is not in the bar; it sits by the side tabs.
- The left side holds the toast/status button: the last result, truncated, with the full text in the Inspector when focused.

---

## 6. Visual language

### 6.1 Rules

- Chrome comes from stock templates and atlases only. Forever paints them bronze. Never tint them, and never recolour button labels.
- Flat plates we draw ourselves (`UI.Plate`) use NineSlice layout `TooltipDefaultDarkLayout` when `NineSliceUtil` exists. The fallback is a near-black (0.05, 0.05, 0.07, .85) fill with a 1 px top and bottom rule of #E69E52 (0.90, 0.62, 0.32) at alpha .9. Both are template art for the `color-fill` rule (§11).
- Class colour appears only on the character line and the Overview name.

### 6.2 Colours (`UI.C`, Blizzard colour objects)

| Use | Colour |
|---|---|
| Labels, idle tab text | NORMAL (gold 1, .82, 0) |
| Values, titles | HIGHLIGHT (white) |
| Empty, hints | DISABLED |
| Added / will place | ADDED (green) |
| Missing / can't place | MISSING (red) |
| Replaces your bind / will clear | REPLACES / REMOVED (orange) |
| Pet | PET (light blue) |
| Waiting to learn | DISABLED + desaturated icon |
| Custom bronze rule | #E69E52, at 90 % on large areas |

### 6.3 Fonts

| Use | Font object |
|---|---|
| Page title | GameFontHighlightLarge |
| Pane, card and sheet titles | GameFontNormalMed3 |
| Section headers | GameFontHighlight on `UI-Character-Info-Title` |
| Labels | GameFontNormal |
| Values, body, names in List views | GameFontHighlight |
| Name captions under icons (≤ 64 px wide) | GameFontHighlightSmall, one line. The only allowed `*Small`, because the full name is always in the Inspector and List view. |
| Key letters on keycaps | NumberFontNormal; NumberFontNormalLarge at ≥ 56 px |
| Big numbers | Game15Font_o1 |
| Macro text | ChatFontNormal |
| Empty states | GameFontDisable |

### 6.4 Atlas and template inventory

Every name below comes from Blizzard's Forever source, at the file cited. Each is guarded with `UI.HasAtlas` / `UI.Has` and has a fallback. Each must be added to `frames.ATLASES` / the harness template table (§11).

| Role | Names | Source | Fallback |
|---|---|---|---|
| Shell | `PortraitFrameTemplate`, `LargeSideTabButtonTemplate`, `InsetFrameTemplate`, `ShadowOverlayTemplate`, `UIPanelGoldButtonTemplate`, `UIPanelButtonTemplate`, atlas `common-framedivider` | [SharedUIPanelTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml), [CharacterFrame.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml) | ButtonFrameTemplate; `UI.Tabs`; UIPanelButtonTemplate; `UI-Character-Info-ScrollLine` |
| Inspector, rows | `UI-Character-Info-Stat-BG`, `UI-Character-Info-Stat-StoneBG3`, `UI-Character-Info-General-BG`, `UI-Character-Info-Title`, `UI-Character-Info-Line-Bounce`, `UI-Character-Info-Line-Bounce2`, `UI-Character-Info-ScrollLine`, `UI-Character-Info-ScrollLine-Long`, `UI-Character-Info-GearSlot` | [PaperDollFrame.xml (Camelot)](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PaperDollFrame.xml), CharacterFrame.xml | `UI.Inset` well; `Options_List_Active` zebra at alpha .4 |
| Cards | `UI-Character-Info-OutfitCard`, `-OutfitCard-Hover`, `-OutfitCard-Selected`, `UI-Character-Info-OutfitIcon-Frame`, `UI-Character-Info-Icon-Tick` | PaperDollFrame.xml (Camelot) | `UI.Panel` + `Options_List_Hover/Active` |
| Hero art | `Talents-Background-c60`, `talents-background-<class>-<spec>`, `Talents-inner-frame-c60`, `Talents-Main-Ring-c60`, `talents-main-ring-box-c60`, `Talents-small-divider-c60`, `Talents-Square-Box-c60`, `talents-animations-clouds`, `talents-animations-particles` | [Blizzard_ClassTalentsFrame.xml (Camelot)](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_PlayerSpells/Camelot/ClassTalents/Blizzard_ClassTalentsFrame.xml) | `UI-Character-Info-General-BG`; `common-insideframe` |
| Book | `spellbook-Page-Left-C60`, `spellbook-Page-Right-C60`; textures `Interface\Buttons\UI-SpellbookIcon-PrevPage-Up/-Down/-Disabled`, `-NextPage-*` | [Blizzard_SpellBookTemplates.xml (Camelot)](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_PlayerSpells/Camelot/SpellBook/Blizzard_SpellBookTemplates.xml) | `UI-Character-Info-General-BG` |
| Keyboard slots | `UI-HUD-ActionBar-IconFrame`, `-Mask`, `-Border`, `-Mouseover`, `-Down`, `-Flash`, `-Background`, `ui-hud-actionbar-iconframe-slot`, `UI-HUD-ActionBar-Flyout`, `QuestSharing-Padlock` | [ActionButtonTemplate.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml) | existing `UI.Slot` fallbacks |
| **Controller HUD** (native look) | `gamepad-actionbar-bg`, `gamepad-actionbar-slot-bg-empty`, `gamepad-actionbar-slot-frame-select`, `gamepad-actionbar-squareslot-dropshadow`, `gamepad-actionbar-circleslot-dropshadow`, `gamepad-actionbar-focus-bg-square`, `gamepad-actionbar-focus-bg-circ`, `gamepad-actionbar-focus-bg-section`, `gamepad-actionbar-fx-squareglw`, `gamepad-actionbar-fx-circglw`, `gamepad-actionbar-fx-trigger-behind`, `gamepad-actionbar-fx-triggerL-top` / `-triggerR-top` (+ `-ps`, `-switch` variants), `gamepad-actionbar-circleslot-permabound`, `gamepad-ability-icon-jump`, `128-redbutton-exit`, `gamepad-targeting-left-shoulder-bg` / `-right-shoulder-bg`, `gamepad-actionbar-numericalpage-1-normal` / `-selected` / `-disabled`, masks `SquareMask`, `CircleMask` | [ActionBarButton.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarButton.xml), [ActionBarTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarTemplates.xml), [MainActionBarFrame.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.xml), [MainActionBarFrame.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.lua) | `UI.Slot` (square) with a `CircleMask`-less round fallback: `Interface\CharacterFrame\TempPortraitAlphaMask` mask |
| Glyphs | `gamepad-xbox1-*`, `gamepad-ps-*`, `gamepad-switch-128x-*` via InputIconTextureSetUtility | InputIconTexture.lua | text keycap |
| Effects | `ActionButtonSpellAlertTemplate` (`UI-HUD-ActionBar-Proc-Start-Flipbook`, `-Proc-Loop-Flipbook`), `AutoCastOverlayTemplate` (`UI-HUD-ActionBar-PetAutoCast-Ants`, `-Mask`, `-Corners`), `GlowEmitterFactory`, `newplayertutorial-yellowGlow-redbutton-left/-middle/-right` | [ActionButtonSpellAlerts.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButtonSpellAlerts.xml), [AutoCastTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanelTemplates/Mainline/AutoCastTemplates.xml) | `UI-HUD-ActionBar-IconFrame-Flash` alpha pulse |
| Meter | `ColoredProgressBarTemplate`, `common-stat-bar-green`, `-white`, `-red` | [ColoredProgressBar.lua (Camelot)](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Camelot/ProgressBars/ColoredProgressBar.lua) | `StatusBar` with `Interface\TargetingFrame\UI-StatusBar` |
| Controls | `checkbox-minimal`, `checkmark-minimal`, `checkmark-minimal-disabled`, `WowStyle1DropdownTemplate`, `WowStyle1FilterDropdownTemplate`, `MinimalSliderWithSteppersTemplate`, `MinimalScrollBar`, `WowScrollBoxList`, `SearchBoxTemplate`, `ScrollingEditBoxTemplate`, `Options_List_Hover`, `Options_List_Active` | SharedUIPanelTemplates.xml | existing `UI.*` fallbacks |
| **Slider art** | `Minimal_SliderBar_Left`, `_Minimal_SliderBar_Middle`, `Minimal_SliderBar_Right`, thumb `Minimal_SliderBar_Button`, steppers `Minimal_SliderBar_Button_Left`, `Minimal_SliderBar_Button_Right` | [MinimalSlider.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/Slider/MinimalSlider.xml) (read for this spec) | `OptionsSliderTemplate` |
| Misc | `services-icon-warning`, `character-emptysocket`, `UI-Character-Info-Icon-Tick` | Camelot PaperDollFrame.xml | text |

**Dropped from v1:** `Options_CategoryHeader_1`, `Options_HorizontalDivider`, `UI-Background-Marble`, `Interface\common\help-i`, `Gamepad_Ltr_*_32`, and the invented stand-in `minimal-slider-bar`.

### 6.5 Stage backgrounds per page

| Page | Background (first that exists) | Overlay |
|---|---|---|
| Overview | `talents-background-<class>-<spec>` → `Talents-Background-c60` → `UI-Character-Info-General-BG` | `Talents-inner-frame-c60` border; clouds ADD alpha .05 drifting; particles ADD .08; bottom vignette |
| Keyboard | `UI-Character-Info-General-BG` | vignette |
| Controller | `Talents-Background-c60` darkened by vertical gradient (0,0,0,.55 → 0,0,0,.15) | `gamepad-actionbar-focus-bg-section` at alpha .375 behind the focused bar (as Blizzard does) |
| Macros | `spellbook-Page-Left-C60` on the stage + `spellbook-Page-Right-C60` on the Inspector; the divider is hidden so the spread reads as one book | none |
| Options | `UI-Character-Info-Stat-BG` + `UI-Character-Info-Stat-StoneBG3` | `common-framedivider` between the columns |

Vignette: a texture on `Interface\Buttons\WHITE8x8` with `SetGradient("VERTICAL", CreateColor(0,0,0,.55), CreateColor(0,0,0,0))` over the bottom 120 px ([SetGradient](https://warcraft.wiki.gg/wiki/API_TextureBase_SetGradient)).

### 6.6 Focus ring

One frame, `UI.FocusRing`: strata HIGH, `UI.MarkIgnored`, re-anchored to the focused node with 3 px of outset. Its art depends on `acFocusStyle`:

| Style | Art | Animation |
|---|---|---|
| slot | `UI-HUD-ActionBar-IconFrame-Mouseover` ADD | Alpha .55 ↔ 1, 0.8 s BOUNCE |
| square (Controller D-pad) | `gamepad-actionbar-fx-squareglw` + `gamepad-actionbar-focus-bg-square` behind | same pulse |
| circle (Controller face) | `gamepad-actionbar-fx-circglw` + `gamepad-actionbar-focus-bg-circ` behind | same pulse |
| row | `Options_List_Hover` + 2 px bronze left bar (`UI.Plate` edge) | none |
| card | `UI-Character-Info-OutfitCard-Hover` | pulse .75 ↔ 1 |
| button / chip | the template highlight locked (`LockHighlight`) | none |

Movement: an instant re-anchor, no tween (keeps the D-pad snappy). In pad mode Blizzard's own `gamepad-largecursor` pointer also shows; leave it.

### 6.7 Motion (`UI/Fx.lua`)

All motion runs on non-secure frames. Options › Motion: Full (default) or Reduced. Reduced keeps only fades of 0.12 s or less. Everything is guarded by `UI.HasAnim()` (whether `CreateAnimationGroup` exists).

| Moment | Animation |
|---|---|
| Window open | inner container Alpha 0→1 + Translation y -12→0, 0.18 s OUT; close reverses in 0.12 s, then Hide in OnFinished |
| Page switch | old stage Alpha 1→0 0.08 s; new stage Alpha 0→1 + Translation x ±10→0 0.15 s OUT (direction follows LB/RB); the side tab does a Scale 1→1.06→1 bump |
| View change (X / chip / modifier) | slot icons cross-fade 0.10 s; the layer title slides 6 px |
| Controller bar expand (held trigger or focused bar) | the focused bar Scales 1→1.12 over 0.12 s OUT, copying the native collapsed (208x68) → expanded (266x86) change ([ActionBarStyles.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarStyles.lua)); `gamepad-actionbar-fx-trigger-behind` fades in at .6 |
| Press (A, Enter, click) | icon Scale 1→0.92→1, 0.06 s + 0.06 s, origin CENTER |
| Pending change (After view) | the slot mark pulses Alpha .6↔1, 1.2 s BOUNCE |
| Review sheet | Translation x +40→0 + Alpha, 0.18 s OUT; dim layer fades in over 0.12 s |
| Apply commit | each changed slot plays `ActionButtonSpellAlertTemplate.ProcStartAnim`, staggered 25 ms in reading order, capped at 24 (≈ 0.6 s); then the meter fills over 0.4 s; card ticks pop (Scale 0.6→1.1→1) |
| Macro install | ProcStartAnim one-shot on the book entry |
| Book page turn | Alpha + Translation x ±12→0, 0.12 s |
| Ambient (Overview) | clouds TextureCoordTranslation over 40 s REPEAT; particles Alpha bounce 4 s; model sway ±8° over 6 s in OnUpdate, paused when hidden |

Performance guard: if `GetFramerate() < 40` for 3 s while the window is shown and Motion is Full, switch to Reduced for the session and log it. [VERIFY in game on the Deck]

### 6.8 Sound (`UI.Sound(key)`)

The guard is `if ns.db.sound ~= false and SOUNDKIT and SOUNDKIT[key] then PlaySound(SOUNDKIT[key]) end`. IDs come from [SoundKitConstants.lua (forever)](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Mainline/SoundKitConstants.lua).

| Event | Key (id) | Fallback |
|---|---|---|
| Window open / close | IG_CHARACTER_INFO_OPEN (839) / IG_CHARACTER_INFO_CLOSE (840) | — |
| Page switch | IG_CHARACTER_INFO_TAB (841) | — |
| Focus move (key/pad only, throttled to 1 per 60 ms) | GAMEPAD_RADIAL_MENU_HIGHLIGHT (370996, Forever-only) | U_CHAT_SCROLL_BUTTON (1115) |
| View change / trigger preview | GAMEPAD_RADIAL_MENU_TAB_OVER (370999) | UI_CLASS_TALENT_TAB (207760) |
| Activate / pin | IG_MAINMENU_OPTION (852) | — |
| Toggle on / off | IG_MAINMENU_OPTION_CHECKBOX_ON (856) / _OFF (857) | — |
| Review sheet open | UI_CLASS_TALENT_APPLY_CHANGES (207767) | — |
| Apply complete | UI_CLASS_TALENT_APPLY_COMPLETE (212391), plus `C_GamePad.SetVibration("Low", 0.2)` in pad mode | GS_TITLE_OPTION_OK (798) |
| Macro installed | UI_PROFESSIONS_NEW_RECIPE_LEARNED_TOAST (73919) | UI_CLASS_TALENT_LEARN_TALENT (217825) |
| Book page turn | IG_ABILITY_PAGE_TURN (836) | — |
| Blocked in combat / error | none (the banner is enough) | — |

---

## 7. Inspector pane (`UI/Inspector.lua`)

`pane` is built once by the shell and cleared with `pane:Clear()` before each `acInspect`. It stacks blocks top-down with 8 px gaps. Overflow scrolls through an internal `UI.ScrollList`, and the right stick scrolls it when an Inspector button is focused.

| Method | Draws |
|---|---|
| `pane:Header(icon, title, kind [, glyphKeys])` | 56 px icon in `UI-Character-Info-GearSlot`; title `GameFontNormalMed3` (wraps to 2 lines); kind line `GameFontHighlight` ("Spell · Rank 7"). `glyphKeys` such as `{"PADRTRIGGER","PAD1"}` draws "RT + A" as glyphs above the title. |
| `pane:Section(text)` | `UI-Character-Info-Title` header |
| `pane:Row(label, value [, color, icon])` | zebra row `UI-Character-Info-Line-Bounce` / `-Bounce2`, 24 tall; label gold, value white or coloured; optional 18 px icon |
| `pane:Layers(list)` | one row per layer: `{label, icon, name, stateColor}`. Used for "Plain / Shift / Alt" on a key and "No trigger / LT / RT / LT+RT" on a controller button. |
| `pane:Diff(now, after)` | two 32 px mini-slots joined by an arrow, "Now → After", in state colours |
| `pane:Text(text)` | wrapped `GameFontHighlight`, from `C_Spell.GetSpellDescription(id)` or tooltip lines (`C_TooltipInfo.GetSpellByID` when it exists) |
| `pane:CrossRef(list)` | "Also on: Controller RT + A (set 1)" lines. A button on each line jumps there (opens the page and focuses the node). A second home of the same spell on the same device shows in MISSING red. This makes the one-home rule visible. |
| `pane:Code(text)` | read-only `ScrollingEditBoxTemplate`, 7 lines, `ChatFontNormal` (macro text) |
| `pane:Buttons(list)` | 26-tall `UI.Button`s, `{label, fn, enabled, confirm}`, bottom-docked, focusable |
| `pane:Empty(text)` | `GameFontDisable` text, e.g. "Move to a key to see what it does." |
| `pane:BarCard(bar)` | **Controller only**: the 8 buttons of one bar as 8 rows of glyph (20) + icon (28) + name (`GameFontHighlight`) + state dot. The focused row is highlighted. |

---

## 8. Page contract v2 (`Core.lua`)

New fields are optional; every v1 field keeps working.

| Field | Meaning |
|---|---|
| `id`, `title`, `order`, `module` | as v1; `module` may be a list (`{"ActionBars","Keybinds"}`): the page shows if any is on |
| `icon` | side-tab icon: fileID, texture path, atlas, or `fn(page)` |
| `description` | Inspector text when its side tab is focused |
| `aliases` | old ids such as `{"bars","keys"}` |
| `Build(page, stage, pane)` | runs once; `stage` is 712x512; `pane` is the Inspector. v1 pages (`Build(page, f)`) get a 600x450 frame centred in the stage and the Inspector shows `page:Status()`. |
| `Refresh(page)` | as v1 |
| `Status(page)` → text, tip | the summary line |
| `readiness(page)` → done, total | drives the meter; nil hides it |
| `views` | `{ {key, label}, ... }`: the view-strip chips that X cycles |
| `toggles` | `{ {key, label, get, set}, ... }`: extra strip chips such as Now/After or Picture/List |
| `Zones(page)` → `{ {name, nodes}, ... }` | focus zones (§4.1) |
| `DefaultFocus(page)` → node | |
| `ScrollRegion(page)` → ScrollBox or nil | for the right stick |
| `Review(page)` → groups or nil | the Review sheet content (§9.6); nil hides the Y prompt unless `primary` exists |
| `Commit(page)` | runs the real Apply; returns `out, err, changedNodeIds` |
| `primary` | `{label, fn, enabled}`: a primary without a review (e.g. Install on Macros) |
| `prompts(page)` | per-page prompt list `{ {key="PAD3", label="Layer"}, ... }`; the shell adds A/B |
| `Back(page)` → bool | pops a page-owned layer |
| `OnShoulder` | v1 field; **ignored** in v2 (LB/RB always change page) |
| `actions` | v1 footer actions become Inspector buttons when the page has no focused node, or Options › Tools entries |

---

## 9. Pages

Coordinates are stage-local (712x512, origin TOPLEFT). Each page has a view strip at y 0..32: chips are `UI.Chips` (Buttons, `Options_List_Active` when selected, `GameFontNormal` / `GameFontHighlight` when selected, height 28), plus right-aligned toggles.

### 9.1 Overview (`overview`, order 0, icon class icon from `Interface\TargetingFrame\UI-Classes-Circles` coords)

The landing page on first open; after that, the last page used opens.

```
STAGE
┌──────────────────────────────────────────────────────────────────────────────────────┐
│ [spec art + clouds + particles + inner frame]                                          │
│  ┌──────────────────┐   Erik · Level 60 Hunter · Beast Mastery   (GameFontNormalMed3)  │ y 16
│  │                  │   ─────────────── Talents-small-divider-c60 ──────────────────   │ y 44
│  │   PlayerModel    │   LOADOUTS                                                       │
│  │   (player)       │  ┌OutfitCard 420x76──────────────────────────────────────────┐   │ y 64
│  │   230 x 300      │  │[44 ⌨] Keyboard        ▕████████████░░▏ 41/44              │   │
│  │   sway ±8°       │  │       3 changes ready · 2 waiting to learn     ✓ when done │   │
│  │                  │  └────────────────────────────────────────────────────────────┘   │
│  │   pet model      │  ┌[44 ✚] Controller      ▕████████░░░░░▏ 30/41               ┐   │ y 148
│  │   (70 %, right)  │  │       Gamepad UI on · 11 changes ready · mini HUD ▣▣▣▣     │   │
│  └──────────────────┘  └────────────────────────────────────────────────────────────┘   │
│                        ┌[44 📖] Macros         12 installed · 4 recommended         ┐   │ y 232
│                        └────────────────────────────────────────────────────────────┘   │
│                         HELPERS (UI-Character-Info-Title)                               │ y 320
│                         ▒ Fishing Helper   On · weapons return 15 s after fishing [✓] │ Line-Bounce 32
│                         ░ Snapshot         Saved 14:02 · on disk at /reload  [Save]   │ Line-Bounce2
└──────────────────────────────────────────────────────────────────────────────────────┘
INSPECTOR: COMING NEXT. Homes waiting for spells you will learn (Controller plan
missing "learn" + ActionBars missing, de-duplicated): 18 px desaturated icon + name +
"Home ready: Q · RT+A". Then a focused card's breakdown (Now→After of its top 3 changes).
```

- Models: `CreateFrame("PlayerModel")`: `SetUnit("player")`, `SetPortraitZoom(0)`, `SetCamDistanceScale(1.15)`, `SetAnimation(0)`. The pet model uses `SetUnit("pet")` when `UnitExists("pet")`. The mouse drags to rotate; the pad has no rotation (no stick capture). Harness: a placeholder of the class icon in `talents-main-ring-box-c60`. [VERIFY in game: PlayerModel for "pet"; Deck performance]
- Cards: `UI.Card` with a 44 px icon in `UI-Character-Info-OutfitIcon-Frame`, title `GameFontNormalMed3`, state line `GameFontHighlight` in state colours, a `UI.Meter` 160x10, and `UI-Character-Info-Icon-Tick` when up to date. The Controller card draws a 120x36 mini HUD (four 4-dot crosses).
- Readiness counts "same" homes ÷ homes with a resolvable item. Waiting homes count as waiting, not as failures.
- Empty layout: a large class crest with "No Mage layouts yet. Ask Claude Code to write one; this page fills in on your next /reload." The Macros card stays.

| Input | Overview |
|---|---|
| D-pad / arrows | cards (vertical) → helper rows → Inspector "Coming next" rows |
| A / Enter / click card | open that page |
| A on a helper row | toggle the helper; A on [Save] = save snapshot now |
| A on a "Coming next" row | open that page and focus the home |
| X | — (prompt hidden) |
| Y / Ctrl+Enter | **Review all**: the Review sheet lists Keyboard and Controller changes; Commit runs ActionBars → Keybinds → Controller Apply, skipping gated modules and modules with 0 changes |
| LB / RB | pages |

Prompts: (A) Open  (B) Close  [(Y) Review all N]. Default focus: the first card with changes, else Keyboard.

### 9.2 Keyboard (`keyboard`, order 10, icon `Interface\Icons\INV_Misc_Key_03`, modules ActionBars + Keybinds)

This merges v1's Action Bars and Key Bindings pages. The page reads `ActionBars.M.Plan/Apply/Undo` and `Keybinds.M.Diff/Apply/Undo/Layout` (export-only change, §12).

View strip: `[ Plain ][ ⇧ Shift ][ Alt ][ Side bars ]` (X cycles), right toggles `[ Picture | List ]` and `[ Now | After ]`.

**Picture view:**
```
y 40     ┌──┐┌──┐┌──┐┌──┐┌──┐                                      MOUSE
         │1 ││2 ││3 ││4 ││5░│      keycaps: UI.Keycap slot 56,          ┌──────┐
         └──┘└──┘└──┘└──┘└──┘      step 64, row stagger 0/16/24/40     │ M3   │ name
 caption Arcane Serp  Hunt  Rapid  (GameFontHighlightSmall, 1 line,    ├──────┤
           ┌──┐┌──┐┌──┐┌──┐┌──┐     truncated to 62 px)                 │ M4   │ name
           │Q ││W░││E ││R ││T │                                         │ M5   │ name
             ┌──┐┌──┐┌──┐┌──┐┌──┐   key letter top-left NumberFontNormal └──────┘
             │A░││S░││D░││F ││G │   3 layer pips bottom edge (plain/shift/alt in use)
                ┌──┐┌──┐┌──┐┌──┐    lit pip = shown layer
                │Z ││X ││C ││V │    Z/X pet keys: PET edge + AutoCast ants when autocast
y 392 ─────────────── Talents-small-divider-c60 ──────────────────────────
y 404   Bar strip: "Action Bar 2 (Shift)" 12 × 30 px slots, slot index under each  (ignored by nav)
y 456   hint: "Hold Shift or Alt to see that bar." (keyboard prompt mode) GameFontDisable
```
- Each keycap row is 4 rows × 82 px (cap 56 + caption 16 + gap 10) = 328 px, from y 40 to 368.
- Keys outside the layout (W A S D, 5) draw at alpha .35 with only their key letter, and are not focusable. Rationale: no dead weight on the D-pad; the Inspector of a neighbour says "W A S D: movement keys, left alone".
- No flyout badges (owner rule: plain keybinds, no flyouts). If a layout entry would resolve to a flyout, the cap shows MISSING red and the Inspector explains why.
- After view: changed caps carry `SetMark(ADDED)` / `SetMark(REPLACES)` with the 1.2 s pulse. Waiting homes show the desaturated icon with a "…" corner.

**Side bars view:** 5 strips (Action Bar 4-8) of 12 `UI.Slot` 40 px at step 46, labels on the left in `GameFontNormal`. Hidden bars show "Hidden in Edit Mode · Apply shows it" in orange. Each slot has a name caption.

**List view** (the glance view; a `UI.ScrollList`):
```
 KEY   PLAIN                      SHIFT                      ALT
 [1]   [ic] Arcane Shot   ✓      [ic] Serpent Sting   +     [ic] Healing Potion  ✓
 [2]   [ic] Hunter's Mark ✓      [ic] Concussive …    ↻     [ic] —
 …     rows 36 tall: keycap 28 + 3 × (icon 28 + name GameFontHighlight + state glyph)
```
Columns: key 48, then 3 × 220. One row per layout key. A row is one node; Left/Right selects the layer cell within the row (cells are sub-nodes with `navLeft/Right`). The list scrolls with focus (§4.5).

**Inspector for a key** (e.g. Q):
- Header: keycap "Q" glyph, then the spell icon and name.
- `pane:Layers` with Plain / Shift / Alt.
- Diff Now → After for the shown layer.
- Rows: "Bar slot: Action Bar 2 · 4"; "Binding: MULTIACTIONBAR1BUTTON4".
- Text: the description.
- "Replaces: Attack (bound by you)" in orange, only when it does.
- "Macro home: uses the plain spell until you install 'Arcane' in Macros. [Open Macros]". Apply never creates macros.
- CrossRef "Controller: RT + B (set 1)".
- Buttons: [Restore original bars], [Restore original keys]; each confirms, and each is enabled only when a backup exists.

**Live layer preview:** an OnUpdate throttled to 20 Hz, running only while this page is shown, reads `IsShiftKeyDown()` / `IsAltKeyDown()`. Shift shows the Shift layer and Alt the Alt layer; releasing returns to the chip's layer, and the chip flashes. Nothing is consumed.

| Input | Keyboard page |
|---|---|
| D-pad / arrows | spatial over keycaps → mouse block → (Side bars view: strips). Right edge ↔ Inspector (jump override). Up from the top row → view strip. |
| A / Enter | pin the key in the Inspector (B unpins) |
| X / Ctrl+Space | cycle layer Plain → Shift → Alt → Side bars |
| hold Shift / Alt | live preview |
| Y / Ctrl+Enter | Review & Apply (bars, then keys) |
| LB / RB | pages |

Prompts: (A) Pin  (B) Back  (X) Layer  [(Y) Review & Apply N]. Status line: "3 changes ready · 2 waiting to learn", or "Up to date ✓"; the tip breaks down slots / keys / replaces.

### 9.3 Controller (`controller`, order 20, icon `Interface\Icons\INV_Gizmo_02`, module Controller)

**This page copies Blizzard's own Gamepad action bar HUD.** The native `GamepadMainActionBarFrame` (656x202) arranges four bars as a cross:
- Top bar: nothing held, at y +58.
- Bottom bar: LT + RT, at y -58.
- Left bar: LT, at x -195.
- Right bar: RT, at x +195.

Each bar is a D-pad diamond of **square** slots (left group) plus a face diamond of **circle** slots (right group). Each slot has a 20 px `InputIconTextureFrameTemplate` glyph. Trigger glyphs sit 35 px under the Left, Right and Bottom bars ([ActionBarTemplates.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarTemplates.xml)). We draw the same arrangement with our own widgets and Blizzard's atlases, larger and spaced so names fit.

View strip: `[ 1 · Combat ][ 2 · Utility ][ 3 · Pet & Extras ]` (X cycles sets), right toggles `[ HUD | List ]` and `[ Now | After ]`. A page indicator to the left of the chips uses `gamepad-actionbar-numericalpage-1-*` styling. [VERIFY: only "-1" is referenced in source; for 2 and 3 use the chip text.]

**HUD view** (cross centre at stage (362, 236)):
```
y 40                         ┌───────── TOP · No trigger ─────────┐
                             │  [▲]                     (Y)       │    squares 46 (D-pad), circles 46 (face)
                             │[◀]  [▶]   gamepad-     (X)   (B)   │    bar backing: gamepad-actionbar-bg
                             │  [▼]      actionbar-bg   (A)       │    glyph 20 px at each slot's outer corner
                             └────────────────────────────────────┘
 ┌────── LEFT · Hold LT ──────┐                          ┌────── RIGHT · Hold RT ─────┐
 │  [▲]            (Y)        │      [LB]  set 1/3  [RB] │  [▲]            (Y)        │
 │[◀]  [▶]      (X)   (B)     │      (shoulder plates:   │[◀]  [▶]      (X)   (B)     │
 │  [▼]            (A)        │       gamepad-targeting- │  [▼]            (A)        │
 └────────────────────────────┘       left/right-        └────────────────────────────┘
        [LT glyph 28]                 shoulder-bg)              [RT glyph 28]
                             ┌──────── BOTTOM · Hold LT + RT ─────┐
                             │  …                                 │
                             └────────────────────────────────────┘
                                       [LT][RT] glyphs
y 448  BACK BUTTONS  (L4) (L5)      (R4) (R5)   character-emptysocket 32, keycap labels,
                     "Kept free for now"  (not focusable; owner rule)
```

Exact geometry. Offsets are relative to the **cross centre at stage (362, 236)**, in stage px with y up positive (SetPoint "CENTER" offsets use the same sign; stage-top coordinates are `236 - y`):

| Bar | Centre | Bar backing size |
|---|---|---|
| Top (none) | (0, +104) | 300 x 100 |
| Left (LT) | (-194, 0) | 300 x 100 |
| Right (RT) | (+194, 0) | 300 x 100 |
| Bottom (LT+RT) | (0, -104) | 300 x 100 |

Buttons within a bar, relative to the bar centre. These are native expanded offsets ×1.15, rounded:

| Button | Offset | Shape | Glyph key |
|---|---|---|---|
| D-pad Up | (-86, +26) | square 46 | PADDUP |
| D-pad Down | (-86, -26) | square 46 | PADDDOWN |
| D-pad Left | (-137, 0) | square 46 | PADDLEFT |
| D-pad Right | (-36, 0) | square 46 | PADDRIGHT |
| Face Y | (+80, +26) | circle 46 | PAD4 |
| Face A | (+80, -26) | circle 46 | PAD1 |
| Face X | (+37, 0) | circle 46 | PAD3 |
| Face B | (+124, 0) | circle 46 | PAD2 |

Y on top and A on the bottom (this fixes v1's upside-down diamond).

Clearances:
- The vertical bar spacing of 104 keeps the Top bar's lowest slot (y 104-26-23 = 55) clear of the Left/Right bars' highest (26+23 = 49).
- The slots span x -354 (Left bar, D-pad Left) .. +341 (Right bar, Face B). That is why the cross centre sits at stage x 362: slots then cover stage x 8..703 inside the 712 px stage.
- Vertically, slots cover stage y 83..389. The trigger glyphs (28 px, 50 px under the Left, Right and Bottom bar centres) end above y 430. The back sockets sit at y 448..480.

Tests must assert that no two slot rects overlap and that all lie inside the stage.

- **Name captions:** the HUD itself shows icons only, like the native HUD. **Names are always visible in the Inspector's BarCard** for the focused or held bar (§7), so the Deck reads "RT layer: A = Kill Command, B = Mend Pet…" at a glance. The List view shows all 32 names at once.
- **Slot art** (`UI.PadSlot(parent, shape, size)`):
  - background `gamepad-actionbar-slot-bg-empty`;
  - icon masked with `SquareMask` / `CircleMask` (wrap `CLAMPTOBLACKADDITIVE`);
  - drop shadow `gamepad-actionbar-squareslot-dropshadow` / `-circleslot-dropshadow` at 4 px outset (13 px when focused: native shadow distance, collapsed vs expanded);
  - selection frame `gamepad-actionbar-slot-frame-select` when pinned;
  - state mark: a 2 px ring in state colour drawn with the matching glow atlas (`-fx-squareglw` / `-fx-circglw`) tinted. These are our own overlays, not the stock frame.
- **Base-layer face buttons** (Top bar A/B/X/Y) are fixed by the Gamepad UI. They show Blizzard's own icons: `gamepad-ability-icon-jump` on A, `128-redbutton-exit` on B, `Interface\Cursor\Interact` on X/Y as native, and `gamepad-actionbar-circleslot-permabound` over them ([MainActionBarFrame.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.lua)). They are desaturated and focusable for explanation only; the Inspector says "Fixed by the Gamepad UI". [VERIFY in game: which face is interact / inspect / back / jump]
- Radial (flyout) slots: `UI-HUD-ActionBar-Flyout` corner arrow. The Inspector lists the radial's spells as a ring of 24 px icons around a 44 px centre in `Talents-Main-Ring-c60`.
- Pet autocast (`petauto`) slots: `AutoCastOverlayTemplate` → `ShowAutoCastEnabled(true)`, but only once the library's "Auto <ability>" macro is installed. Otherwise the plain ability is desaturated with an Inspector line "Install 'Auto Growl' in Macros to use this toggle · [Open Macros]". Apply never creates it.
- **Focused / held bar:** the bar scales to 1.12 and its `gamepad-actionbar-focus-bg-section` (alpha .375) and `gamepad-actionbar-fx-trigger-behind` fade in, as the native HUD does when you hold a trigger. The other three bars dim to alpha .7.
- **Trigger preview:** an OnUpdate at 20 Hz reads `IsShiftKeyDown()` (LT = GAMEPAD_MOD_LEFT = SHIFT) and `IsControlKeyDown()` (RT = CTRL). Holding LT expands Left, RT expands Right, both expand Bottom. The keyboard user gets the same with Shift/Ctrl. Holding also switches the Inspector BarCard to that bar. [VERIFY in game: modifier state reflects the triggers; `disableFrameFocusPagingWhenFocused` stops window cycling]
- **Gamepad UI off:** the four bars dim to .4 behind a centred `UI.Plate`: "The Gamepad UI is off. Controller bars appear when you turn it on (Options › Controls › Gamepad)." Only the back sockets stay at full alpha.

**List view** (`UI.ScrollList`, 4 columns × 8 rows; no scroll needed at 712 wide but the widget is reused):
```
          NO TRIGGER              HOLD LT                 HOLD RT                 HOLD LT + RT
 [▲]   [ic] Hunter's Mark    [ic] Aspect (radial)   [ic] Mend Pet          [ic] Feign Death
 [▶]   …                     rows 44: glyph 20 + icon 32 + name GameFontHighlight (≤ 120 px, 2-line wrap)
 (A)   Jump (fixed)          …
```
Column width 166, row height 52 (glyph column 36). The rows are the same 8 buttons in native order (Up, Right, Down, Left, Y, B, A, X).

**Inspector for a button** (e.g. RT + A):
- Header with glyph chord "RT + (A)", icon and name.
- State: In place / Added / Will clear / Waiting: learn X / No home → set 3.
- Text, radial ring if any.
- CrossRef "Keyboard: Shift + R".
- **BarCard** of the bar it belongs to.
- Buttons: [Undo last apply] (confirm, enabled when a backup exists).

| Input | Controller page |
|---|---|
| D-pad | Within a bar: Blizzard-diamond moves (Up/Down/Left/Right in the diamond; Right from D-pad Right → Face X). Across bars: spatial (Up from the Top bar → view strip; Left from the Left bar's D-pad Left → wraps to nothing, stops; Down from the Bottom bar → prompts). Right edge (Right bar Face B) ↔ Inspector BarCard. |
| A / Enter | pin the button; on the BarCard, a row focuses that slot |
| X / Ctrl+Space | next set 1 → 2 → 3 |
| hold LT / RT (pad) or Shift / Ctrl (keys) | expand that bar (preview) |
| Y / Ctrl+Enter | Review & Apply |
| LB / RB | pages |

Prompts: (A) Pin  (B) Back  (X) Next set  [(Y) Review & Apply N]. Status: the Gamepad UI warning first (orange), then "11 changes ready · 3 waiting · 2 spells without a button".

### 9.4 Macros (`macros`, order 30, icon `Interface\Icons\INV_Misc_Book_09`)

An open spellbook: the left page is the stage (`spellbook-Page-Left-C60`), the right page is the Inspector (`spellbook-Page-Right-C60`).

View strip: `[ For You | Everything ]` (X), tag chips `opener · defensive · pet · travel · group · More…` (`UI.Filter`), and `[⌕ Search]` (`SearchBoxTemplate`, width 160; Ctrl+F; reachable by D-pad Up from the chips).

```
LEFT PAGE (stage)
y 44   ┌card 340x64───────────────────┐ ┌card─────────────────────────────┐
       │[44 icon] Opener   ✓ Installed │ │[ic] Feign        ↻ Update       │   2 columns × 6 rows = 12 per page
       │ Drops a dead or friendly…     │ │ Feign Death, then trap…         │   cards: UI-Character-Info-OutfitCard
       └───────────────────────────────┘ └─────────────────────────────────┘   icon in Talents-Main-Ring-c60
       …                                                                       name GameFontNormal, desc 1 line
y 470             [◀]  Page 2 of 5  [▶]    (UI-SpellbookIcon-Prev/NextPage; IG_ABILITY_PAGE_TURN)
RIGHT PAGE (inspector)
 [56] Opener        Character macro · Combat
 ✓ Installed · will not be overwritten            ⚠ Untested (services-icon-warning)
 description (wrapped)
 Requires: ✓ Hunter's Mark   ✗ Volley (red)
 ── Macro ──  pane:Code(L.Resolve(m))
 Used by: Keyboard Q · Controller RT+X        ← CrossRef, A jumps there
 [(Y) Install] [Pick Up] [Remove]
```
- Card state ribbon at the right: Installed (green, `checkmark-minimal`), Update (gold), Name in use (orange: your own macro keeps its name), Requires X (red), Untested (`services-icon-warning`).
- Install: A selects a card, and the Inspector [Install] installs that macro. The primary prompt reads "(Y) Install" while a card that isn't installed is selected; otherwise it reads "(Y) Install recommended N", and the Review sheet lists the names first. There is no tick column (from B: a book has no checkbox column), and X stays the scope toggle.
- Search: debounced 0.15 s, the matched substring highlighted gold, Enter or ↓ moves into the results, Esc clears, then unfocuses. The Deck route is scope plus tags.
- Empty state: a blank page, "No macros match these tags." [Clear tags] (focusable).
- Library rules are untouched (install-once; spell, slash and pet names only; Fish poles exception).

| Input | Macros page |
|---|---|
| D-pad / arrows | book grid 2×6; off the left/right edge turns the page and lands on the mirrored slot; Down from the last row → page buttons; Right from the right column → Inspector buttons; Up from the top row → tag chips → search |
| A / Enter | select (fills the Inspector) |
| Y / Ctrl+Enter | Install selected, or install recommended (Review sheet lists names) |
| X / Ctrl+Space | For You ↔ Everything |
| wheel / PgUp / PgDn | turn page |
| Ctrl+F | search |
| B / Esc | clear search → unfocus search → close |
| LB / RB | pages |

Prompts: (A) Select  (B) Back  (X) Scope  [(Y) Install]. Status: "General 12/120 · Character 5/18".

### 9.5 Options (`options`, order 1000, icon `Interface\Icons\INV_Misc_Gear_01`)

A two-column ledger (from B).

```
LEFT 340                                        │ RIGHT 340
MODULES (UI-Character-Info-Title)               │ SNAPSHOT
▒ [✓] Action Bars       Fills bars 1-3          │ ▒ Last saved   14:02 · on disk at /reload
░ [✓] Key Bindings      One layout for bars     │ ░ [Save now]
▒ [✓] Controller        Gamepad UI bars         │ FISHING HELPER
░ [✓] Character Snapshot                        │ ▒ State  On · remembered: [ic][ic]
▒ [✓] Fishing Helper                            │ TOOLS
WINDOW                                          │ ▒ [Open log ▸]   42 lines
▒ Scale           ◀ ━━━●━━ ▶  1.10              │ ░ registered ns.actions, grouped by section
░ Button prompts  [Automatic ▾]                 │
▒ Motion          [Full ▾]                      │
░ Sounds          [✓]                           │
▒ Tooltips on focus [ ]                         │
░ Window shortcuts (Ctrl+…) [✓]                 │
▒ [Reset position]                              │
```
- Rows are 32 px Line-Bounce zebra rows; **the whole row is the focus target** and A toggles it.
- The slider uses `MinimalSliderWithSteppersTemplate`, with the real `Minimal_SliderBar_*` art.
- "Open log" opens a Log sub-view (`UI.LogBox` fills the stage). B returns. [Clear log] is an Inspector button.
- Inspector: the focused row's full description, its slash commands (`/ac keys apply`, …), and its last log line.
- A slider row takes D-pad Left/Right (step 0.05) and still lets Up/Down leave. In SmartNav, the steppers are the focus targets: mark the Slider itself ignored, and the Back/Forward buttons are the nodes.

| Input | Options |
|---|---|
| D-pad / arrows | rows; Left/Right between columns, and steps a focused slider |
| A / Enter | toggle / press / open dropdown |
| X / Ctrl+Space | — (hidden) |
| Y | — (hidden) |
| LB / RB | pages |

### 9.6 Review sheet (shared layer)

`page:Review()` returns `{ {title="WILL PLACE", items={ {key, nowIcon, nowName, afterIcon, afterName, note, color} }}, ... }`.

```
Slides over stage + inspector (x 8..992, y -84..-604); behind it a dim layer
(WHITE8x8 gradient (0,0,0,.6)→(0,0,0,.35)).
┌ Review changes · Keyboard ────────────────────────────── (GameFontNormalMed3) ┐
│ WILL PLACE (8)                                    (UI-Character-Info-Title)    │
│  Q        [ic] empty           →  [ic] Arcane Shot                             │  rows 36: keycap/glyph,
│  Shift+E  [ic] Attack          →  [ic] Concussive Shot   replaces your bind    │  icon+name, arrow, icon+name,
│ WILL CLEAR (1) …                                                               │  note in state colour
│ KEYS (5)  F → Mend Pet (was Not Bound) …                                        │
│ WAITING (2) · no change   Feign Death · Volley (homes stay empty)              │
│                                                (UI.ScrollList, right stick)    │
│ Your bars are backed up the first time you apply.                              │
│                                      [ (B) Back ]   [ (Y) Apply 13 changes ]   │
└───────────────────────────────────────────────────────────────────────────────┘
```
- Focus enters on [Apply]. D-pad Up scrolls the list (rows are focusable for reading). B pops.
- The commit sequence:
  1. combat check;
  2. `UI.RunAction(page.Commit)`;
  3. close the sheet;
  4. the proc cascade on the changed nodes (§6.7);
  5. the meter animates;
  6. sound + rumble;
  7. toast.
- Restore and Undo keep `UI.Confirm` (StaticPopup).

---

## 10. Widget API (new and changed; every v1 signature still works)

### 10.1 Changed

| Widget | Change |
|---|---|
| `UI.Tooltip(w, title, text)` | Also stores `w.acTip`; its OnEnter calls `ns.Focus:Set(w, "mouse")` before the tooltip. |
| `UI.Slot(parent, size)` | Adds `slot:SetCaption(text)` (name under the slot), `slot:SetPips(n, lit)`, `slot:Flash()` (proc start), `slot:SetAutoCast(on)`, `slot:SetFocusStyle(style)`. `acFocusStyle="slot"` by default. `SetTip{}` also fills `acInspect` with a default Inspector header plus lines. |
| `UI.Button` | Adds `acFocusStyle="button"`. |
| `UI.Check` | The row is the node (`acFocusStyle="row"`); A toggles. |
| `UI.Slider` | Harness art fix only (§11); the API is unchanged. The SmartNav nodes are the steppers. |
| `UI.Header` | Uses `UI-Character-Info-Title` (fallback: the v1 rule); the `opts.hint` ⓘ button is dropped (the Inspector replaces it). The signature is unchanged. |
| `UI.Tabs` | Unchanged; now only the fallback for side tabs. |
| `UI.RunAction(fn)` / `UI.ShowResult(text)` | Results go to the toast + prompt-bar status; the signatures are unchanged. |
| `UI.pageInset`, `UI.body` | Kept as aliases: `UI.body` = the stage host, `UI.pageInset` = the stage inset. |

### 10.2 New

| Function | Creates |
|---|---|
| `UI.Plate(parent)` | flat bronze-ruled plate (§6.1) |
| `UI.Card(parent, w, h)` | OutfitCard button: `card.icon`, `card.title`, `card.line`, `card.meter`, `card.tick`; `card:SetSelected(b)` |
| `UI.Chips(parent, labels, onSelect [, opts])` | view strip: `strip:Select(i [, silent])`, `strip:Cycle(delta)`, `strip.buttons` |
| `UI.Toggle2(parent, a, b, onChange)` | two-segment chip toggle ("Now | After") |
| `UI.Meter(parent, w)` | readiness bar: `meter:SetValue(done, total [, pending])`, `meter:AnimateTo(done, total)` |
| `UI.Keycap(parent, text, h)` | keycap plate (prompts) |
| `UI.KeySlot(parent, size)` | a keyboard key: Slot + key letter + caption + pips |
| `UI.PadSlot(parent, shape, size)` | `shape` "square" or "circle"; native gamepad slot art (§9.3); `SetGlyph(key)`, plus all Slot methods |
| `UI.PadBar(parent, layerIndex)` | one native-style bar: backing + 8 PadSlots at the §9.3 offsets; `bar:SetExpanded(b)`, `bar.slots[BUTTON]` |
| `UI.Glyph(parent, key, size)` | glyph texture or keycap; re-skins on `UI.RefreshPrompts` |
| `UI.GlyphAtlas(key)`, `UI.GlyphMarkup(key, size)`, `UI.PadMode()`, `UI.RefreshPrompts()` | §5 |
| `UI.Prompt(parent, key, label, fn)` | prompt-bar button |
| `UI.ScrollList(parent, rowHeight, makeRow, fillRow)` | WowScrollBoxList + MinimalScrollBar; `list:SetData(t)`, `list:ScrollToNode(node)`, `list:Nodes()`; registers itself for the right stick and wheel |
| `UI.Model(parent, unit, w, h)` | PlayerModel with a placeholder fallback |
| `UI.Socket(parent, label)` | empty `character-emptysocket` + keycap label (back buttons) |
| `UI.SectionTitle(parent, text, x, y, w)` | `UI-Character-Info-Title` header |
| `UI.StatRow(parent, label, value, w, zebraIndex)` | Line-Bounce zebra row |
| `UI.FocusRing` | the singleton ring (§6.6) |
| `UI.Anim.FadeIn/SlideIn/Squish/Pulse/Cascade(nodes)`, `UI.HasAnim()` | §6.7 |
| `UI.Sound(key)` | §6.8 |
| `ns.Focus`, `ns.Esc` | §4 |

---

## 11. Local dev: renderer, harness, warnings

**Current state (checked for this spec):** `dev/render/out/warnings.txt` shows 0 warnings on every page except settings, which has one `missing-texture  atlas minimal-slider-bar (not mirrored) (template art)`. `textures/unavailable.txt` says `atlas/minimal-slider-bar  not in UiTextureAtlasMember`: the harness invented that name.

### 11.1 Fix the slider stand-in (do first)

In `dev/harness/frames.lua`, `MinimalSliderWithSteppersTemplate.build`:
- Replace the single `track:SetAtlas("minimal-slider-bar")` with three textures copied from [MinimalSlider.xml](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/Slider/MinimalSlider.xml):
  - `Left` (`Minimal_SliderBar_Left`, anchored LEFT, atlas size);
  - `Right` (`Minimal_SliderBar_Right`, anchored RIGHT);
  - `Middle` (`_Minimal_SliderBar_Middle`, TOPLEFT to Left.TOPRIGHT, TOPRIGHT to Right.TOPLEFT).
- Thumb: `Minimal_SliderBar_Button`.
- Back stepper (11x19): `Minimal_SliderBar_Button_Left`. Forward stepper (9x18): `Minimal_SliderBar_Button_Right`. These replace the `UI-SpellbookIcon-*` textures.
- Size the frame 250x40 as in the real template; the slider is TOPLEFT x 19 / BOTTOMRIGHT x -19.
- In `M.ATLASES`, remove `minimal-slider-bar`. Add `minimal_sliderbar_left`, `_minimal_sliderbar_middle`, `minimal_sliderbar_right`, `minimal_sliderbar_button`, `minimal_sliderbar_button_left`, `minimal_sliderbar_button_right` with stand-in colours.
- Then run `dev.ps1 render -Fetch` and check that warnings.txt shows 0 on every page.

### 11.2 Every new atlas and template

- Add each §6.4 atlas to `M.ATLASES` (lower-case key, size, stand-in colour, optional "ring") and each template to the template table.
- Then run `powershell -NoProfile -ExecutionPolicy Bypass -File C:/Users/erik/code/agentcraft/dev/dev.ps1 render -Fetch`.
- **Forever-only atlases** (`gamepad-actionbar-*`, `*-c60`, `talents-animations-*`, possibly `UI-Character-Info-*`) may be missing from the retail tables fetch.ps1 reads.
  1. First try pointing `$WagoBuild` / product at a Forever build if wago.tools lists one. [VERIFY]
  2. Otherwise fetch.ps1 writes them to `textures/unavailable.txt` with the reason `forever-only`.
  3. render.lua reports `forever-only` names as an **info** line ("stand-in drawn"), not a `missing-texture` warning.
  4. The list of allowed forever-only names lives in `dev/render/forever-only.txt`, checked in, each line citing its source file. A name not on that list stays a warning, so invented names can't hide there.

### 11.3 Harness additions (`dev/harness/frames.lua`, `wow.lua`)

- **AnimationGroup / Animation stub:**
  - `CreateAnimationGroup`: Play, Stop, Finish, Pause, Restart, IsPlaying=false, IsReverse, SetLooping, SetToFinalAlpha, SetScript, GetProgress.
  - `CreateAnimation(type)`: a chainable setter sink for Alpha, Translation, Scale, Rotation, FlipBook, TextureCoordTranslation and VertexColor, plus SetDuration, SetOrder, SetSmoothing, SetStartDelay, SetTarget, SetChildKey.
  - `Play()` applies the end state and fires OnFinished synchronously, so the render shows the final frame.
- **Templates:** `LargeSideTabButtonTemplate` (`SetIcon`, `SetChecked`), `UIPanelGoldButtonTemplate`, `ColoredProgressBarTemplate`, `ShadowOverlayTemplate`, `ActionButtonSpellAlertTemplate` (`ProcStartAnim`, `ProcLoop`), `AutoCastOverlayTemplate` (`ShowAutoCastEnabled`), `InputIconTextureFrameTemplate` (`SetInputKey`), `WowScrollBoxList` + `ScrollUtil.InitScrollBoxListWithScrollBar` + a `CreateScrollBoxListLinearView` emulation, `SearchBoxTemplate` (if not present).
- **Frame types:** a `PlayerModel` placeholder (SetUnit etc. as no-ops; it draws a labelled box).
- **Globals:** `InputIconTextureSetUtility.GetNormalActiveInputIconButtonTexture` (returns `UI.GLYPH_FALLBACK` names; `W.labelStyle` switches the sets), `InputDeviceIconSetManager:RegisterActiveInputDeviceIconSetUpdatedCallback`, `C_GamePad.GetDeviceMappedState/GetActiveDeviceID/SetVibration`, `GlowEmitterFactory` / `GlowEmitterMixin.Anims` (pcall-safe), `NineSliceUtil.ApplyLayoutByName`, `SOUNDKIT` with the §6.8 keys, and `IsShiftKeyDown/IsAltKeyDown/IsControlKeyDown` driven by `W.mods`. Also `GetFramerate`, `RegisterGameMenuEscHandler` (absent unless `W.escRegistry`), `GetCurrentKeyBoardFocus`, `SetPropagateKeyboardInput` and `EnableKeyboard` recorded in `W`.

### 11.4 Renderer (`dev/render/render.lua`) variants and new checks

- **Render variants**, each written to `out/<page>-<variant>.html`:

| Variant | Setup |
|---|---|
| `kb` | default |
| `pad` | `W.gamepadUI=true`: glyph prompts and LB/RB indicators |
| `list` | List view on Keyboard and Controller |
| `review` | Review sheet open |
| `combat` | `W.inCombat` |
| `empty` | no layout |
| `shift` | Keyboard with Shift held |
| `lt` | Controller with LT held |
| `ps` | `W.labelStyle="Shapes"`: PlayStation glyphs |

- **New warning kinds:**

| Kind | Fires when |
|---|---|
| `offscreen` | the window plus side tabs at scale 1.1 doesn't fit 1229x768 |
| `small-target` | an interactive rect is under 28 px in the pad variant |
| `small-font` | a `*Small` font is used outside captions, keycaps or the meter label |
| `focus-unreachable` | a visible enabled node can't be reached from DefaultFocus by Neighbor walks |
| `focus-deadend` | a node has no exit in some direction and no zone edge is defined |

- **Changed checks:** `outside` ignores frames flagged `_acOutsideOK`. WHITE8x8 + `SetGradient` textures and `UI.Plate` fills count as art, not `color-fill`.
- **Acceptance gate:** every variant of every page renders with **0 warnings** (info lines allowed).

---

## 12. File-by-file implementation plan

Each phase is shippable on its own; run `dev.ps1 check` and `dev.ps1 render -Fetch` at the end of each.

**Phase 0: dev fixes**
- `dev/harness/frames.lua`: the slider art fix (§11.1), the AnimationGroup stub, new templates, frame types and atlases (§11.3).
- `dev/harness/wow.lua`: new globals and `W` fields.
- `dev/render/render.lua`: variants, new checks, `_acOutsideOK`, the gradient/plate exemption, the forever-only info list.
- `dev/render/fetch.ps1`: the forever-only classification and an optional Forever build. `dev/render/forever-only.txt` (new).
- `dev/dev.ps1`: `render -Variant <name|all>`.

**Phase 1: shell and input**
- `Agentcraft.toc`: add `UI\Input.lua`, `UI\Fx.lua` and `UI\Inspector.lua` right after `UI\Widgets.lua`. Add `UI\Pages\Overview.lua`, `UI\Pages\Keyboard.lua` and `UI\Pages\Controller.lua` above `UI\Window.lua`. Bump to `0.28.0`.
- `Core.lua`: the page contract v2 fields (§8), `aliases`, module lists, `ns.db.sound/motion/prompts/focusTips/shortcuts` defaults.
- `UI/Input.lua` (new): `ns.Focus` (Set, Move, HandleKey, Restore, zones, Neighbor), engaged mode, OnKeyDown/OnKeyUp, repeat ticker, `ns.Esc`, pad and chord override sets with combat-safe clear/requeue, SmartNav glue, glyph helpers, prompt-mode tracking.
- `UI/Fx.lua` (new): `UI.FocusRing`, `UI.Anim.*`, `UI.Sound`, ambient helpers, the frame-rate guard.
- `UI/Inspector.lua` (new): the pane API (§7).
- `UI/Window.lua` (rewritten shell):
  - PortraitFrame 1000x640, header, meter, side tabs with LB/RB glyphs, stage/inspector hosts, prompt bar, toast, combat banner, Review sheet host, open/close animation;
  - FCM `FocusGamepad` / `UnfocusGamepad` / `SmartNavigationCloseHandler`;
  - the v1 page wrapper (600x450 centred);
  - `ns.OpenPage` with aliases, `ns.ToggleUI`, `UI.SetScale` with the tab-width clamp.

  The status line and the v1 sidebar are deleted.
- `UI/Widgets.lua`: the §10 additions and changes. Drop the `Options_CategoryHeader_1`, `Options_HorizontalDivider`, `UI-Background-Marble` and `help-i` uses.

**Phase 2: Keyboard page**
- `Modules/ActionBars.lua`: export `M.Apply = Apply`, `M.Undo = Undo` (locals at :512 and :604). Delete the page block at :834, which moves to Keyboard.lua. No logic change.
- `Modules/Keybinds.lua`: export `M.Apply`, `M.Undo`, `M.Diff` (:81, :114, :155) and `M.Layout`. Delete the page block at :275. No logic change.
- `UI/Pages/Keyboard.lua` (new): Picture / Side bars / List views, the live preview poller, the Inspector, Review/Commit.

**Phase 3: Controller page**
- `Modules/Controller.lua`: move the page block at :701 into `UI/Pages/Controller.lua`. Export `M.BAR_TITLE`, `M.BUTTON_NAME` and the `ReasonText` helper. No logic change.
- `UI/Pages/Controller.lua` (new): HUD view with `UI.PadBar` × 4, the List view, the trigger preview, BarCard, back sockets, Gamepad-UI-off plate, Review/Commit, and `disableFrameFocusPagingWhenFocused` while shown.

**Phase 4: Macros**
- `Macros/Page.lua`: rewritten as the spellbook spread (§9.4). `Macros/Library.lua` is untouched.

**Phase 5: Overview and Options**
- `UI/Pages/Overview.lua` (new).
- `UI/Settings.lua`: rewritten as the Options ledger, with the new settings.

**Phase 6: tests and polish**
- `dev/tests/12_input.lua`:
  - overrides set only while focused;
  - overrides cleared on REGEN_DISABLED and on hide;
  - a hide in combat clears them on REGEN_ENABLED;
  - no key consumed while not engaged;
  - WASD always propagates;
  - Esc order;
  - focus Restore after Refresh, page switch and re-pool.
- `dev/tests/13_pages_v2.lua`:
  - every page builds in every variant;
  - Review groups match Plan counts;
  - Commit never calls `CreateMacro`;
  - back buttons have no binding after Controller Apply with the hunter layout;
  - the Controller HUD has no overlapping slot rects, and all lie inside the stage;
  - Y on top / A on the bottom;
  - every PadSlot has a glyph.
- `dev/tests/14_scroll.lua`: focusing row N scrolls it into view; the wheel step equals the row height; there are no dead ends (`focus-deadend` = 0).
- Update the existing tests `06_frames`, `07_window`, `08_ui_rules`, `09_macros_controller` and `10_bars_keys` for the new page ids (the aliases keep old calls working).
- Docs: `dev/ui-widgets.md` (the §10 API), `skills/extending-addon/SKILL.md` (structure table: the new UI files and Pages/), `dev/README.md` (render variants).

---

## 13. Owner rules: how the design keeps them

| Rule | How |
|---|---|
| Macros install once; names only spells, slash commands, pet abilities (Fish poles excepted) | `Library.lua` untouched. Install creates only a missing macro; "Name in use" never overwrites. The UI authors no macro text. |
| Applying bars never creates macros | Commit calls only the module Apply. Macro homes show "plain spell until you install X · [Open Macros]". The Review sheet has no "create macro" row. Test in 13_pages_v2. |
| No Shift/Ctrl macro variants, no @mouseover/@cursor, no /petpassive, no /petattack | The UI has no macro editor. The modifier previews are display-only polling and bind nothing. |
| One permanent home per spell | The Inspector CrossRef shows each spell's single home per device and flags a duplicate in red. "Coming next" shows empty homes waiting. |
| Back buttons stay empty for now | Drawn as non-focusable `character-emptysocket` sockets, "Kept free for now". F13-F16 are never override-bound by the window. Test in 13_pages_v2. |
| Keyboard layout is plain keybinds, no flyouts | No flyout badges on the Keyboard page; a flyout resolution shows as an error. Radials appear only on the Controller page. |

---

## 14. [VERIFY in game] (Forever, Steam Deck 1280x800, Gamepad UI on and off)

1. `PortraitFrameTemplate:SetPortraitToUnit`, `LargeSideTabButtonTemplate`, `UIPanelGoldButtonTemplate`, `ColoredProgressBarTemplate`, `ActionButtonSpellAlertTemplate`, `AutoCastOverlayTemplate` and `ShadowOverlayTemplate` exist. Every §6.4 atlas resolves with `C_Texture.GetAtlasInfo`, and the c60, UI-Character-Info and gamepad-actionbar art scales well at 1000x640 × 1.1.
2. `FocusGamepad` fires after ShowUIPanel. The SmartNav pointer appears on our nodes. `FocusEnter` runs our OnEnter, so the Inspector syncs on D-pad moves.
3. Our priority overrides on PAD3, PAD4, PADLSHOULDER and PADRSHOULDER beat FCM's fallthrough catcher.
4. `RefreshButtonGroups` picks up pooled ScrollBox rows and book cards after a scroll or page turn. `SetScrollFrameForFrame` with a `WowScrollBoxList` scrolls on the right stick.
5. Holding LT/RT reads as `IsShiftKeyDown` / `IsControlKeyDown`. `disableFrameFocusPagingWhenFocused` stops LT/RT window cycling on the Controller page.
6. `C_GamePad.GetDeviceMappedState(...).labelStyle` on the Deck ("Letters" expected). The `gamepad-xbox1-dpaddown/left/right-normal` names. Glyphs re-skin on device change.
7. `RegisterGameMenuEscHandler` / `GameMenuEscPriority` exist on Forever; otherwise the OnKeyDown Escape path works.
8. Ctrl+Tab, Ctrl+Shift+Tab, Ctrl+1..5, Ctrl+Enter, Ctrl+Space and Ctrl+F are free in the owner's bindings.
9. Entering combat with the window open leaves movement and action bars working (overrides cleared, keyboard propagating), and the window recovers after combat.
10. Which Top-bar face buttons are interact / inspect / back / jump, and the matching native icons.
11. `PlayerModel` (player and pet) performance on the Deck. The frame-rate guard switches to Reduced motion when needed.
12. The Forever-only `SOUNDKIT.GAMEPAD_RADIAL_MENU_*` keys exist and aren't too loud when throttled.
13. `gamepad-actionbar-numericalpage-2/3-*` atlases exist (only `-1` is referenced in source).

---

## 15. Sources

Forever UI source (Gethe/wow-ui-source, `forever` branch):
- https://github.com/Gethe/wow-ui-source/tree/forever
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarTemplates.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarButton.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/ActionBarStyles.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadActionBars/MainActionBarFrame.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Gamepad/UI/PersistentInputLegend/GamepadPersistentInputLegend.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Gamepad/UI/Radials/GamepadRadial.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/Slider/MinimalSlider.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSmartNavigation/SmartNavigation.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSmartNavigation/Utility.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSmartNavigation/SecureHelper.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSharedUtility/FrameControlsManager.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSharedUtility/Tab/TabIndicators.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSharedUtility/PromptedBindings/PromptedBindingFooter.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_StaticPopup/StaticPopupGamepad.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/GamepadConstants.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/InputIcons/InputIconTexture.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Shared/InputIcons/InputDeviceIconSetManager.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Camelot/NineSliceLayoutOverrides.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Camelot/SharedUIPanelTemplates.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Camelot/ProgressBars/ColoredProgressBar.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PaperDollFrame.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_PlayerSpells/Camelot/ClassTalents/Blizzard_ClassTalentsFrame.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_PlayerSpells/Camelot/SpellBook/Blizzard_SpellBookTemplates.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButtonSpellAlerts.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanelTemplates/Mainline/AutoCastTemplates.xml
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameEffects/GlowEmitter.lua
- https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/Mainline/SoundKitConstants.lua

Retail source:
- https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_GameMenuEsc/Blizzard_GameMenuEsc.lua
- https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua
- https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_StaticPopup/StaticPopup.lua

warcraft.wiki.gg:
- https://warcraft.wiki.gg/wiki/UIOBJECT_AnimationGroup
- https://warcraft.wiki.gg/wiki/UIOBJECT_Animation
- https://warcraft.wiki.gg/wiki/UIOBJECT_FlipBook
- https://warcraft.wiki.gg/wiki/API_PlaySound
- https://warcraft.wiki.gg/wiki/API_TextureBase_SetGradient
- https://warcraft.wiki.gg/wiki/API_Frame_SetPropagateKeyboardInput
- https://warcraft.wiki.gg/wiki/API_SetOverrideBindingClick
- https://warcraft.wiki.gg/wiki/API_Frame_EnableGamePadButton
- https://warcraft.wiki.gg/wiki/UIHANDLER_OnKeyDown
- https://warcraft.wiki.gg/wiki/InCombatLockdown
- https://warcraft.wiki.gg/wiki/API_GetCurrentKeyBoardFocus
- https://warcraft.wiki.gg/wiki/Make_frames_closable_with_the_Escape_key

Forever style references:
- https://github.com/wowaddonmaker/classicuiforever/blob/main/Art/Bronze.lua
- https://www.curseforge.com/wow/addons/umbra-unit-frames
- https://www.method.gg/wow-forever/understanding-wow-forevers-ui
- https://github.com/seblindfors/ConsolePort/blob/master/ConsolePort_Cursor/View/Cursor.lua
