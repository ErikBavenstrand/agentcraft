# Agentcraft widget API (`ns.UI`)

Reference for page code. Design of record: `dev/ui-spec-v2.md`. Source files:

| File | Holds |
|---|---|
| `UI/Widgets.lua` | feature checks, art roles (`UI.ART`), colours, lookups, v1 widgets, `UI.Slot`, `UI.Node` |
| `UI/Fx.lua` | `UI.Sound`, `UI.Anim.*`, `UI.FocusRing` |
| `UI/Input.lua` | `ns.Focus`, `ns.Esc`, `ns.Input`, glyph helpers, prompt mode |
| `UI/Controls.lua` | `UI.Plate`, `UI.Keycap`, `UI.Glyph`, `UI.Prompt`, `UI.Chips`, `UI.Toggle2`, `UI.Meter`, `UI.Card`, `UI.ScrollList`, `UI.Model`, `UI.Socket`, `UI.SectionTitle`, `UI.StatRow`, `UI.WatchModifiers` |
| `UI/Slots.lua` | `UI.KeySlot`, `UI.PadSlot`, `UI.PadBar` (the native controller HUD) |
| `UI/Inspector.lua` | the Inspector pane API |
| `UI/Window.lua` | the shell: header, side tabs, stage, Inspector, prompt bar, toast, combat banner, Review sheet |

The new files load right after `UI\Widgets.lua` in the TOC. **New TOC files need a full game restart, not a /reload.**

Every widget checks its Blizzard template with `UI.Has` and its atlas with `UI.HasAtlas` / `UI.SetAtlas`, and falls back when either is missing. Art lists in `UI.ART` name the WoW Forever (Camelot) atlas first and a retail atlas of the same role second, so both clients and the offline renderer draw real art. The harness knows only retail atlas names (checked against wago.tools' UiTextureAtlasMember), so renders show the retail fallback.

## Page contract v2 (Core.lua)

A page with `api = 2` gets the v2 shell; any other page is a v1 page (`Build(page, f)` with a 600x450 frame centred in the stage; its `actions` show in the Inspector's action dock).

| Field | Meaning |
|---|---|
| `id`, `title`, `order` | Tab order is `order`, then `id`. `section` is ignored by v2. |
| `module` | A module key or a list of keys. Gated (stage shows "<Module> is turned off." with a [Turn On] button) only while **every** listed module is off. |
| `icon` | Side-tab icon: file ID, texture path, `"atlas:<name>"`, or `fn(page)`. |
| `description` | Inspector text while the page's side tab is focused, and in the default Inspector. |
| `aliases` | Old ids `ns.OpenPage` still accepts (`{ "bars", "keys" }`). |
| `api = 2` | `Build(page, stage, pane)`: `stage` is the page's 712x512 frame (`page.frame`, zone "stage"), `pane` the Inspector. |
| `Refresh(page)`, `Status(page) -> text, tip` | As v1. Status is the header summary; `tip` (string or lines) also shows in the default Inspector. |
| `readiness(page) -> done, total` | Drives the header meter ("41 / 44 in place"); nil hides it. |
| `views` | `{ {key=, label=}, ... }`: the view strip chips at the stage top (y 4..32). X / Ctrl+Space / a chip click selects; the shell sets `page.view` and calls `page:OnView(key)`, then Refresh. Pages lay content out from y 40. |
| `toggles` | `{ {key=, labels={"Picture","List"}, get=fn(page)->1|2, set=fn(page, i)}, ... }`: two-segment toggles at the strip's right. |
| `CycleView(page, delta)` | Optional: replaces the default X behaviour (cycle `views`). |
| `viewLabel` | X prompt label (default "View"). |
| `prompts(page)` | `{ {key="PAD1", label="Pin"}, {key="PAD3", label="Next set"} }`: overrides prompt labels. The shell shows A (hidden in mouse mode), B ("Back"/"Close"), X (when `views` has 2+ or a PAD3 prompt is given), Y (primary). |
| `Review(page) -> groups` | `{ {title="WILL PLACE", items={ {key, nowIcon, nowName, afterIcon, afterName, note, color} }}, ... }`. Y / Ctrl+Enter opens the Review sheet; the primary reads "Review & Apply N" (`reviewLabel` changes the words, `reviewNote` the footnote). |
| `Commit(page) -> out, err, changedIds` | The real Apply. The shell checks combat, runs it through `ns.Run`, closes the sheet, plays the proc cascade on nodes whose `acId` is in `changedIds`, animates the meter, sounds, toasts `out`. **Never create macros here.** |
| `primary` | `{ label=, fn=, enabled= }` (label/enabled may be functions): a primary without a review (Install on Macros). |
| `DefaultFocus(page) -> node` | Where focus lands when nothing better is known. |
| `DefaultInspect(page, pane)` | Inspector content while the focused node has no `acInspect` (default: icon, title, description, status). |
| `ScrollRegion(page) -> frame` | The scroll frame the right stick scrolls (SmartNavigation). Rows of a `UI.ScrollList` register their own. |
| `Back(page) -> bool` | Called when the Back stack is empty; return true when you closed something of your own. |
| `Search(page)` | Ctrl+F. |
| `ListJump(page, kind) -> bool` | PgUp/PgDn/Home/End while the focused node isn't in a `UI.ScrollList` (the Macros book turns pages). Return true when handled. |
| `hideDivider` | true hides the line between stage and Inspector (the Macros spread reads as one book). |
| `OnShow(page)`, `OnHide(page)` | Page switch hooks. |
| `disableFrameFocusPaging` | true on the Controller page: LT/RT preview layers instead of cycling Blizzard windows (`frame.disableFrameFocusPagingWhenFocused`). |
| `actions` | v1 footer actions; drawn in the Inspector's bottom dock (`page.footerFrame.buttons`). |

Other Core calls: `ns.PageById(id)` (id or alias), `ns.IsGated(keyOrList) -> gated, mod`, `ns.Setting(k)` with defaults `ns.UI_DEFAULTS = { sound = true, motion = "full", prompts = "auto", focusTips = false, shortcuts = true }`, plus everything from v1 (`ns.RegisterModule`, `ns.RegisterCommand`, `ns.RegisterAction`, `ns.LogLine`, `ns.Run`, `ns.ModuleOf`, `ns.CommandHelp`).

## Window (UI/Window.lua)

| Function | Does |
|---|---|
| `ns.OpenPage(id [, focusId])` | Opens the page (aliases work) and refreshes it; with `focusId` focuses the node with that `acId` (Inspector cross-references). |
| `ns.ToggleUI()` | Opens or closes (ShowUIPanel / HideUIPanel). |
| `UI.Refresh()` | Re-runs the open page's Refresh, Status, meter, prompts; keeps or restores focus. |
| `UI.RunAction(fn)` | Runs `fn` through `ns.Run`, toasts the result (errors stay until dismissed), logs, refreshes. |
| `UI.ShowResult(text)`, `UI.ShowToast(text, "result"|"error")` | Toast at the stage top + the prompt bar's status button (focus it to read every line). |
| `UI.OpenReview()`, `UI.CloseReview()`, `UI.Commit()` | The Review sheet of the open page. |
| `UI.CycleView(delta)`, `UI.CurrentPage()`, `UI.Frame()` | |
| `UI.SetScale(v)` / `UI.GetScale()` / `UI.ResetPosition()` | 0.8-1.25, clamped so window + side tabs fit: `(1000+44)*s <= W-20`, `640*s <= H-20`. Auto: 1.1 with the Gamepad UI. |
| `UI.stage` (alias `UI.body`, `UI.pageInset`), `UI.pane` | The stage inset and the Inspector pane. |

Geometry: frame 1000x640 (`PortraitFrameTemplate`; fallback `ButtonFrameTemplate`, `BasicFrameTemplateWithInset`); stage TOPLEFT 8,-84 / BOTTOMRIGHT -280,44 (712x512); Inspector TOPRIGHT -8,-84 / BOTTOMRIGHT -8,44 (264 wide); prompt bar BOTTOMLEFT 8,6 / BOTTOMRIGHT -8,6 (32 tall); side tabs outside the right edge from y -96, step 58 (flagged `_acOutsideOK`). Zones (the `acZone` of a container): `view`, `stage`, `inspector`, `prompts`, `tabs`, `review`.

## Input (UI/Input.lua)

### Focus nodes

`UI.Node(frame, { style=, id=, inspect=, activate= })` makes any frame a focus target. `UI.Button`, `UI.Slot`, `UI.KeySlot`, `UI.PadSlot`, `UI.Card`, `UI.Prompt`, chips, toggles, `UI.Check` rows, Inspector cross-references and BarCard rows, `UI.ScrollList` rows and anything with `UI.Tooltip` already are. Fields a node may carry:

| Field | Meaning |
|---|---|
| `acId` | Stable id for focus restore and Commit ceremonies ("key:Q", "pad:2:A"). |
| `acInspect(node, pane)` | Fills the Inspector (after 0.12 s settle). A node inside the Inspector never re-inspects: the pane keeps explaining `Focus.inspected` (the last node outside it), so its buttons and links stay put, also across a Refresh. |
| `acTip(node)` | Tooltip (mouse hover, or keyboard/controller focus with "Tooltips on focus"). |
| `acActivate(node, source)` | A / Enter / Space (default `node:Click()`). |
| `acFocusStyle` | Ring art: `"slot"`, `"square"`, `"circle"`, `"row"`, `"card"`, `"button"`, `"chip"`. |
| `navUp/navDown/navLeft/navRight` | Explicit neighbour: a node, `fn(node, dir) -> node`, or `false` (stop). Otherwise spatial. |
| `acEdge(node, dir)` | Called when a move finds nothing (turn a book page). |
| `acScroll` | The `UI.ScrollList` that owns the node (set by the list). |
| `acSkip` | Never a target (decorative). |
| `acReadable` | Focusable even while disabled (status, cross-refs, Review rows). |
| `acOnFocus(node, source)`, `acOnBlur(node)` | Visual hooks. |

### `ns.Focus`

| Call | Does |
|---|---|
| `Focus:Set(node, source [, quiet, noScroll])` | source "mouse", "key" or "pad". Moves the ring, scrolls into view (not for mouse), remembers `page.lastFocusId`, inspects after 0.12 s, focus tick sound (not for mouse). |
| `Focus:Move("UP"|"DOWN"|"LEFT"|"RIGHT", source)` | Explicit nav, else spatial over every usable node (score: distance along + 2 x gap across). Up from a page's top row reaches the view strip, Down the prompt bar, Right the Inspector. |
| `Focus:Activate(source)` | A / Enter. |
| `Focus:Restore()` / `Focus:Validate()` | The ladder: `page.lastFocusId` -> nearest node in the same zone -> `page:DefaultFocus()` -> first stage node. Validate keeps a still-usable focus (the shell calls it after every Refresh). |
| `Focus:Pin(node)` / `Focus:Unpin()` | Pins the Inspector (a Back layer); `node:SetPinned(true)` when the node has it (PadSlot draws its select frame). |
| `Focus:NextZone(delta)`, `Focus:ListJump("PAGEUP"|"PAGEDOWN"|"HOME"|"END")` | Tab cycling; list jumps. |
| `Focus:Nodes()`, `Focus.Neighbor(cur, dir, list)`, `Focus.ZoneOf(node)`, `Focus.ScrollIntoView(node)` | Helpers (used by tests). |
| `Focus:PushModal(root)` / `PopModal(root)` | Focus stays inside root (the Review sheet). |
| `Focus.current`, `Focus.source`, `Focus.engaged`, `Focus.pinned` | State. |

### `ns.Esc` (Back / Escape)

`Esc.Push(closeFn, tag)`, `Esc.Remove(tag)`, `Esc.Has(tag)`, `Esc.Pop() -> bool` (by layer: `"review"`, then any other tag (sub-views), then `"pin"`, then `"engaged"`; newest first among equals; else `page:Back()`), `Esc.Back()` (pop, else close the window), `Esc.Clear(keep)`. Shell tags: `"review"`, `"pin"`, `"toast"` (error toasts), `"engaged"`. Push your own sub-views (Options › Log). Pad B goes through `frame.SmartNavigationCloseHandler`; Escape through `RegisterGameMenuEscHandler` when the client has it, else OnKeyDown consumes it only when a layer popped (the last Escape closes through `UISpecialFrames`). Right-click on empty stage pops too.

### Keyboard and controller

- Resting: the window takes only Tab and the chords; arrows, Enter and Space only once engaged (Tab or a click inside). A movement binding (WASD, arrows bound to movement while not engaged), Esc or a hide releases it. OnKeyDown sets `SetPropagateKeyboardInput(not handled)`; OnKeyUp resets it. Held arrows repeat after 0.35 s every 0.08 s.
- Chords (override bindings while shown, out of combat, Options › "Window shortcuts"): Ctrl+Tab / Ctrl+Shift+Tab pages, Ctrl+1..5 page n, Ctrl+Enter primary, Ctrl+Space view, Ctrl+F `page:Search()`.
- Pad overrides (`Input.PadSet()`): Gamepad UI with FCM focus (`frame.FocusGamepad`): PAD4 primary, PAD3 view, LB/RB pages; SmartNavigation keeps the D-pad, A and B. A controller without Gamepad UI navigation (or no FCM): the full set (D-pad moves, A activates, B backs). F13-F16 (back paddles) are never bound.
- Combat: `PLAYER_REGEN_DISABLED` clears overrides, releases the keyboard and disengages; the window stays browsable but Apply/Install grey out ("(in combat)") and a banner shows. `PLAYER_REGEN_ENABLED` rebinds and runs anything queued (a hide in combat, SmartNavigation sync).
- `Input.SyncSmartNav(node, scrollRegion)`: `RefreshButtonGroups`, `SetTargetButtonForFrame`, `SetScrollFrameForFrame` (never `SelectButton`); queued in combat.

### Glyphs and prompt mode

| Call | Does |
|---|---|
| `UI.GlyphAtlas(key)` | `InputIconTextureSetUtility.GetNormalActiveInputIconButtonTexture(key)` when its atlas exists (or its `-flat-` twin), else `UI.GLYPH_SHAPES` (PlayStation, by label style) or `UI.GLYPH_FALLBACK`. Keys: PAD1-4, PADLSHOULDER, PADRSHOULDER, PADLTRIGGER, PADRTRIGGER, PADDUP/DOWN/LEFT/RIGHT, PADDPAD. |
| `UI.GlyphMarkup(key, size)` | Inline `|A..|a` markup, or "[A]". |
| `UI.PromptMode()` / `UI.PadMode()` | "pad", "keyboard" or "mouse" (Options › Button prompts, else Gamepad UI, else last device). |
| `UI.NoteDevice("keyboard"|"pad")`, `UI.RefreshPrompts()` | Re-skin every `UI.Glyph`. Called on device events and the icon-set callback. |
| `UI.PAD_NAMES`, `UI.PAD_KEYS`, `UI.KEY_TEXT`, `UI.KeyLabel(key)` | "A"/"LT"/"Up" names, "RT A"-style layout key to PAD key, keyboard prompt text ("Ctrl+Enter"). |

## Motion and sound (UI/Fx.lua)

- `UI.Sound(role|SOUNDKIT key)`: roles `open`, `close`, `tab`, `focus` (throttled 60 ms), `view`, `activate`, `on`, `off`, `review`, `applied`, `installed`, `page`, each with fallbacks. Off with `ns.db.sound = false`.
- `UI.Anim.FadeIn(region, dur, from)`, `FadeOut(region, dur, onDone)`, `SlideIn(region, dx, dy, dur)`, `Squish(frame)`, `Bump(frame)`, `Pulse(region, from, to, dur) -> group`, `Blink(region, dur)`, `Cascade(nodes)` (node:Flash() 25 ms apart, max 24), `Drift(tex, seconds)`. `UI.HasAnim()`, `UI.Reduced()` (Options › Motion "reduced": short fades only). Never rely on a finished translation or scale; alpha ends are set in OnFinished.
- `UI.FocusRing:Attach(node)` / `:Hide()`: one ring, art by `acFocusStyle` (slot: IconFrame-Mouseover; square/circle: the gamepad slot focus frame and glow; row: list hover + 2 px bronze bar; card: card hover; button/chip: LockHighlight + hover). Pulses .55-1 on slots and controller slots.

## Inspector pane (UI/Inspector.lua)

The shell clears the pane before each `acInspect`. Blocks stack top-down with 8 px gaps and scroll; `pane:Buttons` docks at the bottom.

| Method | Draws |
|---|---|
| `pane:Header(icon, title [, kind [, glyphKeys]])` | 52 px icon in its slot, title (`GameFontNormalMed3`, 2 lines), kind line; `glyphKeys = {"PADRTRIGGER","PAD1"}` draws "RT + A" above the title. |
| `pane:Section(text)` | Title plate; restarts the zebra. |
| `pane:Row(label, value [, color, icon])` | Zebra row, 24 tall. |
| `pane:Layers({ {label, icon, name, color}, ... })` | One row per layer (Plain/Shift/Alt, No trigger/LT/RT/LT+RT). |
| `pane:Diff(now, after)` | `{icon, name, color}` each: two 32 px slots, "Now" over "After". |
| `pane:Text(text [, color])`, `pane:Empty(text)` | Wrapped body text; dim hint. |
| `pane:CrossRef({ {text, fn, color}, ... })` | Focusable "Also on" lines; A runs `fn` (e.g. `ns.OpenPage("keyboard", "key:R")`). |
| `pane:Code(text)` | Read-only macro text, 7 lines (`ChatFontNormal`). |
| `pane:Buttons({ {label, fn, enabled, confirm}, ... })` | 26-tall buttons docked at the bottom; `confirm` asks first. |
| `pane:BarCard({ title=, rows={ {key, icon, name, color, node, focused, faded}, ... } })` | Controller: the 8 buttons of a bar as glyph + icon + name rows; A on a row focuses `node`. |
| `pane:Glyphs(keys)` | A row of glyphs joined by "+". |

## Controls (UI/Controls.lua)

| Function | Creates |
|---|---|
| `UI.Plate(parent)` | Flat panel: NineSlice "TooltipDefaultDarkLayout", else near-black with bronze #E69E52 rules. |
| `UI.Keycap(parent, text, h)` | Key label on a keycap plate; `cap:SetText(t)` resizes. |
| `UI.Glyph(parent, key, size, mode)` | mode "pad" (always the controller glyph) or "prompt" (glyph in pad mode, keycap in keyboard mode, hidden in mouse mode). `g:SetKey(key)`, `g.width`. |
| `UI.Prompt(parent, key, label, fn [, {primary=true}])` | Prompt-bar button (glyph + label, 28 tall); primary = gold button with a glow (`GlowEmitterFactory`, else the tutorial glow atlases) via `SetGlow(on)`. `SetLabel`, `SetKey`, `Relayout`. |
| `UI.Chips(parent, labels, onSelect [, {selected, gap, minWidth, idPrefix, inspect}])` | View strip: `strip:Select(i [, silent])`, `strip:Cycle(delta)`, `strip.buttons`, `strip.selected`. |
| `UI.Toggle2(parent, a, b, onChange)` | Two-segment toggle; `Set(i [, silent])`, `Get()`; A on either half flips it. |
| `UI.Meter(parent, w [, h])` | Readiness bar: `SetValue(done, total [, pending])`, `AnimateTo(done, total)`, `SetLabel(text)` (above, right). |
| `UI.Card(parent, w, h)` | OutfitCard button: `icon`, `title`, `line`, `meter`, `tick`, `SetSelected(b)`. |
| `UI.ScrollList(parent, rowHeight, makeRow(child, i), fillRow(row, data, i))` | Fills parent. `SetData(t)`, `Nodes()`, `ScrollToNode(row)` (one row of context), `VisibleRows()`, `IsRowVisible(row)`, `SetWheelStep(px)`, `.scroll`. One wheel tick = one row; the wheel moves focus to the first visible row when it scrolls out; fade masks show more content; the scroll bar shows only on overflow. Rows are reused, not virtualised. Anchor rows by TOPLEFT and TOPRIGHT only (a RIGHT anchor would stretch them). |
| `UI.Model(parent, unit, w, h)` | PlayerModel (mouse drag rotates) over a faint class crest. `holder:SetUnit(u)`. |
| `UI.Socket(parent, label)` | Empty gem socket + keycap (back paddles; not focusable). |
| `UI.SectionTitle(parent, text, x, y, w)` | Title plate header (24 tall); `fs.plate`. |
| `UI.StatRow(parent, label, value, w, zebraIndex)` | Zebra label/value row; `row:SetValue(text [, color])`. |
| `UI.WatchModifiers(frame, fn(shift, ctrl, alt))` | 20 Hz poll while shown (LT = Shift, RT = Ctrl on the Gamepad UI). Display only. `frame.acPollModifiers()` polls now (tests). |

Also in Widgets.lua: `UI.FirstAtlas(list)`, `UI.SetAtlas(tex, list [, useAtlasSize]) -> name|nil`, `UI.ART` (art roles), `UI.Flat(parent, layer, r, g, b, a)` and `UI.Gradient(parent, layer, orientation, c1, c2)` (our own WHITE8x8 art; renders as art, never a "color-fill"), `UI.DescribeTip(tip, icon)`.

## Slots (UI/Slots.lua and UI.Slot)

`UI.Slot(parent, size)` (v1) gains: `SetCaption(text [, color])` (name under the slot, `GameFontHighlightSmall`, one line), `SetPips(n, lit [, used])`, `Flash()` (proc start), `SetAutoCast(on)`, `SetFocusStyle(style)`. It is a focus node ("slot") whose default `acInspect` shows its tip.

| Function | Creates |
|---|---|
| `UI.KeySlot(parent, size)` | A keyboard key: Slot with the key letter top-left (`SetKey`), caption, pips. |
| `UI.PadSlot(parent, "square"|"circle", size)` | Native Gamepad action bar slot: GamepadActionBarButtonTemplate art: drop shadow, empty slot art (SlotArt), icon under a Square/CircleMask inset 3, border-normal/pressed/hover as button states, tinted Border for the state ring, border-selected when pinned, permabound overlay, a 15 px glyph at TOPRIGHT (-1,-1 square, 0,-3 circle). Every Slot method plus `SetGlyph(key [, corner])`, `SetEmptyKey(key)`, `SetPinned(b)`, `SetPermabound(b)`. Focus style = its shape. |
| `UI.PadBar(parent, layer [, size])` | One bar (layer 0 none, 1 LT, 2 RT, 3 LT+RT): D-pad diamond of squares (left) and face diamond of circles (right), Y on top and A at the bottom, glyph on every slot, trigger glyphs under the bar. `bar.slots[name]` with names `UI.PAD_BUTTONS` (`Up Right Down Left Y B A X`, native order), `slot.padKey`, `slot.acId = "pad:<layer>:<name>"`, `bar:SetTitle(t)`, `bar:SetExpanded(b)` (section glow only; bars never scale). Blizzard diamond moves are explicit `nav*`; leaving the bar is spatial. |
| `UI.PAD_OFFSETS`, `UI.PAD_BAR_OFFSETS`, `UI.PAD_LAYER_TRIGGERS` | Slot offsets in a bar (48 px between centres: no overlap at 46 px), bar centres from the cross centre (stage 362,236; ±194 x, ±108 y), trigger keys per layer. |

## Colours: `UI.C`

Unchanged: `NORMAL`, `HIGHLIGHT`, `GRAY`, `DISABLED`, `GREEN`, `RED`, `ORANGE`, `LIGHTBLUE`; meanings `ADDED`, `MISSING`, `REMOVED`, `REPLACES`, `BAR`, `PET`, `FIXED`. Build strings with `UI.C.X:WrapTextInColorCode(text)`.

## v1 widgets (unchanged signatures)

`UI.Text`, `UI.Header` (now on the `UI-Character-Info-Title` plate, kept inside its parent; `opts.hint` no longer draws a button), `UI.Divider`, `UI.Inset`, `UI.Panel`, `UI.Button` (a focus node), `UI.FitButton`, `UI.Check` (the row is the node), `UI.Tabs` (only the fallback for side tabs now), `UI.Filter`, `UI.Dropdown`, `UI.Slider` (harness art now the real `Minimal_SliderBar_*`), `UI.Scroll`, `UI.LogBox`, `UI.Confirm`, `UI.Empty`, `UI.LegendItem`, `UI.ShowTooltip`, `UI.Tooltip` (also sets `acTip` and a default `acInspect`), `UI.DescribeSlot`, `UI.DescribeCommand`, `UI.KeyText`, `UI.KeyName`, `UI.SpellIcon/SpellName/ItemIcon/ItemName`, `UI.Has`, `UI.HasAtlas`, `UI.HasMenu`, `UI.GamepadUI`, `UI.MarkIgnored`, `UI.MarkSubSection`, `UI.RGB`. Deprecated: `UI.Fill`, `UI.Border`, `UI.SetBorder`, `UI.Swatch`.

## Harness and renderer

- `dev/harness/frames.lua`: AnimationGroup/Animation sink (`Play` fires OnFinished at once; alpha sticks only with `SetToFinalAlpha(true)`), `EnableKeyboard`/`SetPropagateKeyboardInput` (recorded on the frame; an error in combat), `LockHighlight`; templates `LargeSideTabButtonTemplate`, `UIPanelGoldButtonTemplate`, `ShadowOverlayTemplate`, and `MinimalSliderWithSteppersTemplate` with the real `Minimal_SliderBar_Left/_Middle/Right/_Button/_Button_Left/_Button_Right` atlases (250x40, steppers that step); retail atlases for glyphs, the gamepad HUD, the character sheet and class talent backgrounds. Globals: `IsShiftKeyDown/IsControlKeyDown/IsAltKeyDown` (`W.mods`), `GetBindingFromClick` (W.bindings, then WASD/arrows/Space/Escape defaults), `GetCurrentKeyBoardFocus` (`W.keyFocus`), `GetFramerate` (`W.framerate`), `InputIconTextureSetUtility` (`W.labelStyle`), `InputDeviceIconSetManager`, SOUNDKIT keys. Absent on purpose (false): `GamepadMode`, `SmartNavigation`, `NineSliceUtil`, `GlowEmitterFactory`, `RegisterGameMenuEscHandler`; a test sets `W.api.<name>` in `setup(W)` to provide one.
- `dev/render/render.lua`: variants `kb` (`<page>.html`), `pad`, `list`, `review`, `combat`, `shift`, `lt` and `ps` (`<page>-<variant>.html`; dev/README.md lists their setup); checks `offscreen`, `small-target` (pad, 28 px), `focus-unreachable` and `focus-deadend` from the walk in `dev/harness/focuscheck.lua`; the dev-only `gallery` page (`dev/render/gallery.lua`) shows the controller HUD, List view, Inspector BarCard and prompts; WHITE8x8 tints and gradients draw as art; `_acOutsideOK` frames (side tabs) skip the outside check; `dev/render/forever-only.txt` turns a missing PNG of a listed Forever atlas into an info line.
- Tests: `dev/tests/14_focus.lua` (the focus walk of every v2 page in kb and pad, Inspector focus, Tab zones, the modal Review sheet and its scrolling, B closing and reopening, LB/RB), `dev/tests/13_*.lua` (one file per page), `dev/tests/12_input.lua` (overrides, combat, engaged keyboard, Back order, restore, page switch, spatial moves, scroll-follows-focus, the HUD bar layout, glyphs, slider art).
