---
name: extending-addon
description: Use when adding or changing a feature in the Agentcraft World of Warcraft addon, such as a new module, window page, action-bar profile, keybind layout or snapshot field. Holds the addon's structure and the client API gotchas.
---

# Extending Agentcraft

The addon source is in `${CLAUDE_PLUGIN_ROOT}/addon/Agentcraft`. Edit the copy the game loads: the plugin repo clone when it is linked with `install -Link`, otherwise the game's `Interface/AddOns/Agentcraft` folder.

## Structure

| File | Role |
| --- | --- |
| `Agentcraft.toc` | Load order. Add new files above `UI\Window.lua`. A new file needs a full game restart, not `/reload`. |
| `Core.lua` | `ns.RegisterModule`, `ns.RegisterPage`, `ns.RegisterCommand`, `ns.RegisterAction`, `ns.Run`, saved settings. Runs each module's `OnEnable` and event handlers in `xpcall`, so one failing module never stops the others. Print with `ns.Print` or `ns.Out` |
| `UI/Widgets.lua` | Shared look: `UI.Node` (makes a frame a focus target), `UI.Slot`, `UI.Header`, `UI.Button`, `UI.Text`, `UI.SetAtlas` and `UI.ART` (each art role lists the Forever atlas, then a retail one) |
| `UI/Fx.lua` | `UI.Sound`, `UI.Anim` (respects Reduced motion), `UI.FocusRing` |
| `UI/Input.lua` | `ns.Focus` (focus nodes, moves, zones, restore), `ns.Esc` (the Back stack), `ns.Input` (keyboard engaged mode, Ctrl chords, pad override bindings, combat handling), button glyphs (`UI.GlyphAtlas`, `UI.GlyphMarkup`) |
| `UI/Controls.lua` | `UI.Prompt`, `UI.Glyph`, `UI.Chips`, `UI.Card`, `UI.ScrollList` (scroll follows focus), `UI.Plate`, `UI.Meter` and other v2 controls |
| `UI/Slots.lua` | `UI.KeySlot`, `UI.PadSlot`, `UI.PadBar` (the Gamepad UI action bar look) |
| `UI/Inspector.lua` | The Inspector pane: `pane:Header`, `Row`, `CrossRef`, `BarCard`, `Buttons` and more |
| `UI/Window.lua` | The `/ac` window: side tabs, header and meter, the 712x512 stage, the 264 px Inspector, the prompt bar, the Review sheet. A page whose `Build` raises shows the error and is retried on the next visit |
| `UI/Settings.lua` | The Options page (id `options`): module switches, window settings, tools, log |
| `Modules/Layout.lua` | Per-class layouts, one per device: `L.keyboard.<CLASS>` (bars 1, 2 and 4: plain, Shift and Ctrl keys; plain keybinds, no flyouts; bar 3 is the Alt utility bar and is not set there) and `L.controller.<CLASS>` (3 pages of `"RT A"`-style keys with radials, plus back buttons). Controller page 3 holds Steam Deck helpers, `{ overflow = true }` buttons that take every known spell without another controller home, and `{ petauto = true }` pet autocast toggles. Its header lists the entry forms and the rules: one permanent home per spell, alternatives only for either-or talents or same-role upgrades, no spell in two homes |
| `Modules/ActionBars.lua` | Holds the Keyboard page (bars and keys together; layers Plain, Shift, Ctrl, Alt, plus Side bars). Fills keyboard bars 1, 2 and 4 (Ctrl) from `Layout.lua` (or `M.profiles.<CLASS>` for classes without one), the shared `M.utility` Alt bar 3, and the click-only side bars: Action Bar 5 (pet and other class spells), 6 (tracking, professions) and 7-8 (overflow); without bars 6-8 everything shares bar 5 and the least needed stay in the spellbook. A spell on a keyed bar never goes on a side bar. Backs up the bars on the first Apply only; Undo restores macros by name |
| `Modules/Keybinds.lua` | One key layout for bars 1-4 (plain, Shift, Alt, Ctrl + the same 12 keys) and the pet bar (mouse and Z/X; CTRL-1..4 no longer reach the pet bar). Backs up the active binding set (account or character) |
| `Modules/Snapshot.lua` | Writes the character state to SavedVariables (see the gotchas). Exposes `M.AddSection`, `M.SetCached`, `M.On` and `M.util` |
| `Modules/SnapshotMore.lua` | Sections readable at any time. Add one with `M.AddSection(name, fn)` |
| `Modules/SnapshotCached.lua` | Data only readable with a window open or after a server reply. Store it with `M.SetCached(name, table)`, triggered from `M.On(event, fn)` |
| `Modules/Controller.lua` | Holds the Controller page (the Gamepad UI HUD and a List view). Fills the native Gamepad UI bars (3 pages; Top/Left LT/Right RT/Bottom LT+RT; D-pad and face diamonds) and binds Steam Deck back buttons (F13-F16, plus LT layer) from `Layout.lua`. Holds the entry resolver (spells, flyouts, macros, items, racials) that ActionBars reuses. Apply deletes retired Agentcraft macros and unbinds their keys first. Without the Gamepad UI it binds only the back buttons. Its header explains the Gamepad UI rules |
| `Modules/Fishing.lua` | Puts your weapons back 15 s after your last fishing cast ends, or when you mount. Warns when the lure runs out. Remembers weapons in `AgentcraftCharDB.weapons` |
| `Macros/Library.lua` | Macro library core: categories, `L.Add`, install state, install, remove and pick up. Install and Remove never touch a player's own macro of the same name (state `taken`), and Remove unbinds the macro's keys. Its header lists every macro field and the macro conventions |
| `Macros/Data/*.lua` | Macro definitions: one file per class, plus `General.lua` and `Racial.lua`. Add a macro with `L.Add({...})`; add a new file to the TOC above `Macros\Page.lua` |
| `Macros/Page.lua` | The Macros page: a spellbook of macro cards with For You / Everything, search and tag chips; Y installs |
| `Modules/_Template.lua` | Copy this to start a module. It shows every registration call |

Tags are worked out from a macro's `class`, `race`, `profession`, `category`, `tags` and `untested` fields. Set `class`, `race` and `profession` whenever a macro needs them: the page hides macros that don't fit the character unless the user picks "Everything". Keep `tags` to short lowercase topics that already exist (such as `opener`, `defensive`, `group`, `travel`) before inventing new ones, and keep macro names unique across all data files.

When adding a macro, follow the conventions in the `Macros/Library.lua` header. Cite where the macro comes from in the data file's header, and set `untested = true` until the user confirms it works in game.

Applying bars or a layout never creates macros; a macro home uses the plain spell until the user installs the macro on the Macros page. Controller `petauto` buttons use the library's "Auto <ability>" macros (Macros/Data/Hunter.lua, matched by `petAbility`) only once installed. Back buttons may mirror a page-1 spell; the hunter layout leaves them empty for now, and Apply unbinds any back button without a home.

## Window pages

Every page uses the v2 contract (`api = 2`). The full field list is in `dev/ui-widgets.md`; the `RegisterPage` comment in `Core.lua` has the short version.

- `Build(page, stage, pane)` runs once. `Refresh` runs on open, after each action and when bars, binds, bags or spells change.
- Lay content out on the 712x512 stage from y 40; the view strip (`views`, `toggles`) sits above it.
- Put changes through `Review` (groups of rows) and `Commit` (the real Apply). The shell checks combat, shows the Review sheet and returns `changedIds` to the proc cascade. Commit never creates macros.
- Make every interactive frame a focus node with `UI.Node(frame, { id =, style =, inspect = })`. Give it a stable `acId`, such as `"key:Q"`, so focus survives a refresh. `ns.OpenPage(id, acId)` opens a page on that node.
- Rely on spatial moves first. Set `navUp`/`navDown`/`navLeft`/`navRight` (a node, a function, or `false`) only where the spatial pick is wrong, such as a grid next to a chip row.
- Fill the Inspector from `acInspect(node, pane)`. Nodes inside the Inspector never re-inspect, so its buttons stay reachable.
- Use `UI.ScrollList` for long lists, so focus, wheel and PgUp/PgDn stay in step. A page without a list handles PgUp/PgDn with `page:ListJump(kind)`.
- Push a sub-view on the Back stack with `ns.Esc.Push(closeFn, tag)`, so B and Esc close it before the window.
- Make pad targets at least 28 px on each side; the render's `small-target` check enforces it.
- Name only real atlases (check wago.tools or Gethe/wow-ui-source), and put a retail fallback after a Forever-only one.

A v1 page (no `api`) still works in a 600x450 frame; its `actions` show in the Inspector's dock.

## Process

1. Copy `_Template.lua` for a new module, or edit the module that owns the feature. Build UI only from `ns.UI` widgets, so pages share one look.
2. Wrap client API calls that may be missing in an existence check, such as `C_Item and C_Item.GetItemInfo`. Friends run different game versions.
3. Run the dev kit:

   ```
   powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/dev/dev.ps1" check
   ```

   Check: no new failures in `toc`, `rules`, `lint` or `test`. `dev/README.md` lists what each step checks and how to add a test in `dev/tests`.

   For a window change, also run `render` (same script, `render -Fetch` when art is missing). Check: every page and variant reports 0 warnings. The focus checks (`focus-unreachable`, `focus-deadend`) come from `dev/harness/focuscheck.lua`, which `dev/tests/14_focus.lua` also runs.
4. Ask the user to `/reload`, try the feature, wait 10 seconds, then `/reload` again. The second reload writes the snapshot to disk.
5. Run `wowdata.ps1 errors` from the `reading-game-state` skill. Check: no new console Lua errors and `0 errors` in the snapshot line.
6. Bump `## Version` in `Agentcraft.toc` when the change is done.

## Client API gotchas

- The global `GetItemInfo` is missing in modern-based clients. Use `C_Item.GetItemInfo`.
- Spellbook: `C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)`, with the classic `GetSpellBookItemName` as fallback.
- WoW Forever talents use `C_ClassTalents` and `C_Traits`. `GetTalentInfo` and `UnitCharacterPoints` don't exist there.
- Health, power and many combat values (attack power, auras) are secret while tainted. Arithmetic, comparison or concatenation on them throws. Check `issecretvalue(v)` first, as `Safe` and `Keep` in `Modules/Snapshot.lua` do.
- `GetProfessions()` returns nils for empty slots, so `ipairs({ GetProfessions() })` stops early. Take the returns by name.
- Changing bars or binds fails in combat. Check `InCombatLockdown()` first.
- SavedVariables reach disk only on `/reload` and logout. Snapshot saves 10 s after a change (after combat ends), because on logout the character data is often already gone and that save is skipped. A section that fails or turns secret keeps its last good values, marked with `staleSince`/`lastError` or `secretKept`.
- Never reassign `print` or other Blizzard globals; it taints. Route output through `ns.Out`.
- `SetPropagateKeyboardInput`, override bindings and `EnableKeyboard` fail in combat. Change them in `PLAYER_REGEN_DISABLED` (still allowed there) or after `PLAYER_REGEN_ENABLED`.
- Draw flat art on `Interface\Buttons\WHITE8x8` with `SetVertexColor` (`UI.Flat`, `UI.Gradient`), not `SetColorTexture`.
- In the harness, an unknown capitalised field on a mock frame returns a no-op function, which is truthy. Test template parts with `type(x) == "table"`.
- Bar slots: bar 1 = 1-12 (plain keys), bar 2 bottom left = 61-72 (Shift), bar 3 bottom right = 49-60 (Alt), bar 4 right = 25-36 (Ctrl, `MULTIACTIONBAR3BUTTON`), bar 5 right 2 = 37-48 (first side bar), bars 6-8 = 145-180 (`MULTIACTIONBAR5-7BUTTON`, side bars when the frames exist). Pet bar binds are `BONUSACTIONBUTTON1-10`.
