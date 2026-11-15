# Agentcraft dev kit

Check addon changes on Windows before you `/reload` the game. Everything runs from `dev.ps1`:

```
powershell -NoProfile -ExecutionPolicy Bypass -File dev/dev.ps1 <command>
```

| Command | What it does | Needs |
| --- | --- | --- |
| `check` | Runs `toc`, `rules`, `lint`, `lint-ui`, `types` and `test`. A step whose tool is missing is skipped and does not fail the run. | PowerShell 5.1 |
| `toc` | Checks `Agentcraft.toc`: every listed file exists (and matches its case on disk), every `.lua` file is listed, `Version` is `X.Y.Z`, the `Interface` and SavedVariables lines are present, and the load order is right (Core first, Library before the macro data files, Snapshot before its extensions, new files above `UI\Window.lua`). | PowerShell 5.1 |
| `rules` | Checks the owner's rules without running Lua. It reads `Macros/Data/*.lua` and `Modules/Layout.lua` (details below). When the game is installed, it also reads the newest account's `bindings-cache.wtf` and `macros-cache.txt` (read-only). | PowerShell 5.1 |
| `lint` | Runs luacheck with `.luacheckrc`, which flags accidental globals, unused variables and typos. | luacheck |
| `lint-ui` | Checks the `[lint]` rules of `dev/ui-rules.md` statically over `addon/Agentcraft/**/*.lua` (`dev/harness/uilint.lua`). Errors fail; warnings print and pass. Details below. | Lua 5.1 or LuaJIT |
| `types` | Runs `lua-language-server --check` with `.luarc.json`, which flags wrong API arguments and misspelled `C_` functions. | LuaLS and the Ketho annotations |
| `test` | Runs the Lua 5.1 harness. It loads the addon against a WoW API mock and runs `dev/tests/*.lua`. | Lua 5.1 or LuaJIT |
| `globals` | Lists the globals the addon reads and writes. Use it when updating `.luacheckrc`. | PowerShell 5.1 |
| `render` | Draws every page of the `/ac` window to `dev/render/out/<page-id>.html` (plus `index.html`) with a list of layout warnings. Not part of `check`. `-Fetch` first downloads missing textures and atlas data. See [Rendering the window](#rendering-the-window). | Lua 5.1 or LuaJIT |

Exit codes are 0 for pass, 1 for findings or failures, and 2 when a needed tool is missing.

Options:
- `-Strict` makes warnings fail `rules` too.
- `-NoGame` skips the live game section.
- `-WowPath <dir>` points at the game install, or straight at a flavor folder such as `_forever_`. By default the script finds the install through the registry and prefers `_forever_` over the other flavors.
- `-Addon <dir>` checks a copy of the addon, for example a scratch copy with a change you're trying out.
- `-Fetch` (with `render`) downloads the textures and atlas data the render reports missing, then renders again.

### What `rules` enforces

**Macros**
- Errors:
  - A macro names an item through `/use`, `/equip`, `/equipslot`, `#showtooltip`, or `/cast` of a known item. `/use 13` (a slot number) is allowed.
  - A `[mod]`, `[mod:shift]` or `[mod:ctrl]` condition.
  - `@mouseover` or `@cursor`.
  - `/petpassive` or `/petattack` (the owner sends the pet by hand).
  - A body over 255 characters, or a name over 16 characters.
  - The same macro name in two files.
  - A command the game menus already cover, such as `/camp`, `/readycheck`, `/screenshot`, or a `/run` or `/console` that toggles the map, repairs, sells junk or sets camera zoom.
- Info: a macro without `#showtooltip`, one marked `untested`, `/equip` of poles in `Fish` (an exception the owner approved), and a live macro that is also in `L.retired` (Apply keeps it; the Macros page shows Update while its text equals the retired text).

**Layouts**
- Errors:
  - A spell with more than one home on the same device. Your racial, an `item`, a `utility` slot, a `macro` and a `flyout` count as homes too.
  - A back button that repeats a spell whose home is on controller page 2 or 3 (back buttons may mirror page-1 spells only).
  - A flyout, `petauto` or `overflow` entry in a keyboard layout.
  - A bad controller key, or a use of the fixed Top face buttons.
  - A `macro = "X"` that is missing from the library, is retired, or belongs to another class.
- Info:
  - A back button that repeats a page-1 home (a mirror, allowed).
  - A macro-only home, which stays empty until the macro is installed.
  - A macro that also casts spells that have their own home.

**Code**
- Warning: `CreateMacro` or `EditMacro` outside `Macros/Library.lua`, which breaks the rule that applying bars never installs macros.

**Live game**
- Error: a key bound to `MACRO X` where no macro `X` exists, as with F13 bound to `MACRO PetAttack`.
- Info:
  - An installed library macro whose text differs from the library.
  - An installed retired macro.

### What `lint-ui` enforces

`dev/harness/uilint.lua` tokenizes each addon file (comments and strings are skipped properly), tracks function boundaries and names, and checks the `[lint]` rules of `dev/ui-rules.md`. Each finding prints `SEVERITY [rule id] file:line` and a message. Run it alone with `dev.ps1 lint-ui`, or directly: `luajit dev/harness/uilint.lua addon/Agentcraft`.

| Rule | Severity | Flags |
| --- | --- | --- |
| R1 `no-slide` | error | A `"Translation"` animation (`CreateAnimation`, or any helper with `Anim` in its name given the kind), and any call to `UI.Anim.SlideIn`, `Bump`, `Squish`, `Drift` or `Cascade` outside `UI/Fx.lua`. |
| R2 `scale-anim` | warning | A `"Scale"` animation, except in `UI/Fx.lua` functions whose name has `Ring`, `Focus` or `Glow`. |
| R3 `long-alpha` | warning | `SetDuration(x)` with a literal over 1 s (`dur or 1.5` counts; `math.min(...)` and divisions don't) on an Alpha or Scale animation, unless the function names a glow or highlight. |
| R4 `pixelutil-deprecated` | error | `PixelUtil.SetSize` or `PixelUtil.SetPoint`. |
| R5 `pixel-snap-off` | error | `SetSnapToPixelGrid(false)` or `SetTexelSnappingBias(0)`. |
| R6 `atlas-texcoord` | error | `SetTexCoord` on a texture whose last texture call in the same function was `SetAtlas` (method or `UI.SetAtlas(tex, ...)`). A fallback `SetTexture` in between clears it. |
| R7 `create-in-refresh` | error | `CreateFrame`, `CreateTexture` or `CreateFontString` in a function whose name contains `Refresh`, `Update`, `OnUpdate`, `OnEvent`, `Layout` or `Render`, or in a `SetScript`/`HookScript` `OnUpdate` or `OnEvent` handler (a closure, or a named function passed to it). It's fine when guarded: `if not x then` within 3 lines above, `x = x or Create...`, an early `if x then return` in the function, or a pool in the function (`CreateFramePool`, `CreateObjectPool`, `Acquire`, any name with `Pool`). Anonymous closures inherit the enclosing function's name. |
| R8 `onupdate-churn` | error | `SetAtlas`, `SetTexture`, `SetPoint`, `ClearAllPoints`, `Show` or `Hide` inside an `OnUpdate` handler. |
| R9 `dataprovider-reset` | error | `SetDataProvider(p)` with no second argument (pass `ScrollBoxConstants.RetainScrollPosition`). |
| R10 `tint-stock-art` | warning | `SetVertexColor` or `SetDesaturated` on a texture whose last atlas or file (literal, or a `UI.ART.<role>` resolved from the `UI.ART` table) contains `UI-Frame-`, `Metal`, `bronze`, `parchment` or `UI-Character-Info`. A tint on the `UI.WHITE` fallback is fine. |
| R11 `round-layout` | error | `UI/Window.lua` never calls `SetRoundLayoutToNearestPixel` or `PixelUtil.SetRoundLayoutToNearestPixelRecursively`. |

R3, R6, R7 and R10 are heuristics. When one is wrong, put `-- ui-ok: <reason>` on the same line or the line above. `dev/tests/16_uilint.lua` tests each rule on small snippets; add a case there when you change a rule.

## Install the tools

You only need these for `lint`, `lint-ui`, `types` and `test`; `toc` and `rules` run with nothing installed.

```
scoop install luacheck                      # or put luacheck.exe (v1.2.0 release) in dev/tools/
scoop bucket add versions; scoop install lua51   # real Lua 5.1, matches the game
winget install --id DEVCOM.LuaJIT -e        # alternative to lua51 if you only use winget
winget install --id LuaLS.lua-language-server -e
git clone https://github.com/Ketho/vscode-wow-api dev/tools/vscode-wow-api   # WoW API annotations for LuaLS
```

- Don't use `DEVCOM.Lua`: it is Lua 5.4, not the game's 5.1.
- `dev.ps1` looks for each tool in `dev/tools/`, then on PATH, then in `%LOCALAPPDATA%\Programs\*\` (and `*\bin\`) and `%LOCALAPPDATA%\Microsoft\WinGet\Links` or `Packages`, so a fresh winget or unzip install works without reopening the shell.
- Lua and luacheck can't open paths with characters outside the ANSI code page. `dev.ps1` runs them in the repo root with relative paths, and switches to the 8.3 short name when that folder's path isn't plain ASCII.
- In VS Code, install `sumneko.lua` and `ketho.wow-api`.
- In the game, BugGrabber and BugSack give full stack traces. `/console scriptErrors 1` shows errors as popups.

## The loop

1. Edit the addon in `addon/Agentcraft`. The game loads it through the junction.
2. Run `dev.ps1 check`. Fix every error, and read the warnings.
3. In the game, `/reload`. The `Reload` macro on controller page 3 does the same.
4. Do the thing you changed, such as Apply, open the page, or fish.
5. `/reload` again so SavedVariables, `macros-cache.txt` and `bindings-cache.wtf` are written to disk.
6. Run `scripts/wowdata.ps1 errors` to see new Lua errors, and `wowdata.ps1 character` or `binds` to see the result. Then run `dev.ps1 rules` again; its live section reads the files from step 5.

## Dev capture (the real window, in game)

`render` approximates the window; `/ac capture` records the real one. The user types it in game (it never presses keys and never applies anything). It walks every page and its states, takes a PNG screenshot of each, and stores the window's frame tree with each step. Then `wowdata.ps1 capture` pairs each step with its screenshot and lists layout findings, so an agent can look at the UI without the user describing it.

In game:

```
/ac capture              every step, then /reload to save (about 45 screenshots, 1-2 minutes)
/ac capture quick        pages and views only: no focus moves, flicker probes or controller prompts
/ac capture keyboard     one page (keyboard, controller, macros or options)
/ac capture noreload     add to any of the above: don't reload at the end
/ac capture stop         stop now and put everything back
/ac capture clear        drop the stored run (it can be several MB in AgentcraftDB)
```

Leave the mouse and keyboard alone while it runs: the cursor's hover highlights show up in the screenshots. It refuses to start in combat and stops when combat starts. It sets `screenshotFormat` png and `screenshotQuality` 10, and puts them back, with the prompt mode, each page's view and toggles and the open page, at the end. Then it reloads the UI to write SavedVariables; if that is blocked it prints "type /reload". After adding `UI/Capture.lua` to the TOC the first time, restart the game: a new file isn't loaded by `/reload`.

Steps, per page (`UI/Capture.lua`, `PageSteps`):

| Step | State |
| --- | --- |
| `<page>:open` | Opens the page (flicker probe from the switch on). |
| `<page>:view-<key>` | Each further view chip: Keyboard Shift, Alt, Side bars; Controller sets 2 and 3; Macros Everything. |
| `<page>:list`, `list-focus`, `list-fold` | The Picture/HUD-List toggle; focus moved down twice (probe); a scroll list paged twice past its fold. |
| `<page>:now` | The Now/After toggle flipped. |
| `macros:page-2`, `macros:tag` | The book's second page; the first tag chip on. |
| `options:log`, `options:toast`, `options:confirm` | The log view; a sample toast; the `UI.Confirm` dialog with a do-nothing accept (closed after the shot). |
| `<page>:review`, `review-fold` | The Review sheet (probe), and its list paged past the fold. Macros shows it only while no single card is installable; the step then notes "no Review sheet in this state". |
| `<page>:focus-first`, `focus-right`, `focus-down` | The first stage node, then two moves right, then two moves down (each with a probe). |
| `pad:<page>` | Every page again in controller prompt mode (`ns.db.prompts = "pad"`). |

Each step applies its state, waits two frames and 0.3 s, checks `IsRectValid`, dumps the tree, calls `Screenshot()` and waits for `SCREENSHOT_SUCCEEDED` (3 s timeout); screenshots are at least 1.1 s apart, since their file names have 1 s resolution.

What `AgentcraftDB.capture` holds: `runId`, `build` (`GetBuildInfo`), `screen` (`GetPhysicalScreenSize`), `ui` (UIParent size and effective scale), `cvars` (the saved values), `fields`, `paths`, `summary`, `errors` and `steps`. A step has its name, page, view, mode, prompt mode, focused node (`acId`) and zone, the window rect and scale, `shot` (`time` as `MMDDYY_HHMMSS`, `ok`), and `rows`: one tab-separated string per object of the window tree (frames, textures, font strings; at most 4000), with the columns named in `fields`: path, type, shown, visible, effective alpha, rect (`l b w h` in the object's own scale), effective scale, strata, level, draw layer, anchors (`POINT@#n:RELPOINT(x,y)`), texture, atlas, texcoords, `atlasTc` (1 when the texcoords differ from the atlas's own), vertex or text colour, text, font size, truncated, `acId`, global name, and `clip` (`1` scrolled wholly out of its scroll frame, `p` partly). Paths and anchor targets are `#n` indexes into `paths`. Hidden objects get a short row; hidden frames aren't entered. Secret values read as `<secret>`.

A probe step also has `probe`: for 1.5 s it samples every shown object's shown flag, alpha and position each frame, and lists as `hits` the objects that showed and hid twice or more, or whose alpha or position reversed direction (with timestamps), plus `C_AddOnProfiler` recent average and peak time when the client has it.

On the PC:

```
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/wowdata.ps1 capture [-Grep <step name regex>] [-Json] [-Out <file>]
```

It reads the newest account's `Agentcraft.lua` the same way the other commands do (only the capture table, in a few seconds), and pairs steps with `<WoW>/_forever_/Screenshots/WoWScrnShot_MMDDYY_HHMMSS.png` (exact second first, then within 2 s). Per step it prints the screenshot path, the counts, and the findings new since the previous step: `offscreen`, `outside` (the window; the portrait, close button and side tabs sit outside by design), `zero` (a visible region with content and no size), `truncated`, `overlap` (sibling font strings or buttons that overlap), `noTexture` (a visible texture with no file or atlas), `atlasTc`, and every `flicker` hit. Objects scrolled out of their scroll frame are skipped. It ends with each finding's step count. `-Json` writes all of it (every row, path resolved) to `-Out`, default `%TEMP%\agentcraft-capture-<runId>.json`.

`dev/tests/15_capture.lua` runs the whole capture in the harness with a stubbed `Screenshot`.

## The test harness

The harness lives in `dev/harness/`:

| File | Role |
| --- | --- |
| `run.lua` | Runner. It loads `dev/tests/*.lua` in sorted order and gives them `test`, `eq`, `ok`, `fail`, `note`, `noErrors` and `describeCalls`. |
| `harness.lua` | `H.boot{...}` makes a fresh world. It loads every TOC file with `("Agentcraft", ns)`, fires `ADDON_LOADED`, `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD` and `SPELLS_CHANGED`, then runs the timers. It returns an `env` with `:slash("controller apply")`, `:calls("CreateMacro")`, `:installMacro("Arcane")`, `:padSlot(1, "RT A")` (storage slot numbers pinned from an in-game snapshot, not computed), `:slotText(slot)`, `:fire(event, ...)`, `:runTimers(sec)` and `.W` (the world state: `macros`, `actions`, `bindings`, `inCombat`, `secret`, `chat`, `errors`). Options: `pet`, `db`, `charDB`, `macros`, `bindings`, `setup(W)` (before the addon loads), `loaded(env)` (after its files ran, before `ADDON_LOADED`: patch a module here) and `secret`. |
| `frames.lua` | The frame model behind `CreateFrame`: parent, strata and level, shown state, size, anchors (every `SetPoint` form, `SetAllPoints`), scale, alpha, backdrops, textures, font strings, buttons, check buttons, edit boxes and scroll frames. `M.FONTS` lists the font objects and `M.TEMPLATES` the Blizzard templates it emulates (each with a `doc` line); add entries there. `C_XMLUtil.GetTemplateInfo` reports exactly those templates. |
| `layout.lua` | Resolves anchors into screen rectangles (y-up offsets, parent default, scale, scroll children) and reports circular or missing anchors. `GetWidth`, `GetHeight` and `GetRect` use it. |
| `wow.lua` | The API mock: frames (from `frames.lua`) with scripts and events, C_Timer, the spellbook and flyouts, pets, bags and items, macros, action slots and the cursor, bindings, the Gamepad storage slots, and unit stats. Macros live in two tabs as in the client: account macros at 1-120 and character macros at 121-138, each sorted by name; `CreateMacro` refuses a full tab, and action slots follow their macro when indices shift (cleared when it is deleted). Gamepad storage slots match the game: 28 per page, and the Top bar's fixed face buttons (page-unit slots 5-8) have none. With `W.secret` set, health, power, attack power, crit and dodge return secret values (userdata; `issecretvalue` is true; arithmetic, comparison and concatenation raise, but `==` against a number is silently false, so guard with `issecretvalue`, never `type()`) and aura reads raise; `W.secret = "fields"` returns auras whose fields are secret instead. `xpcall` passes extra arguments, as the game's does. Names the modern client lacks (`GetItemInfo`, `GetTalentInfo`, and the globals that moved into `C_Spell`, `C_Item`, `C_AddOns` and `C_UnitAuras` in 11.0) are nil (`M.MISSING`). |
| `rules.lua` | The macro and layout rules in Lua (`CheckMacro`, `CheckLayout`, `ItemNames`), used by test 02. Keep them in step with `dev.ps1` `Test-Macro` and `Test-Layout`. |
| `fixtures/hunter.lua` | A level 60 Orc hunter: spells, flyouts, items, bags, and a pet for `boot{ pet = true }`. |

Every API the addon calls that the mock doesn't define becomes an auto stub: it returns nil and is listed at the end of the run. To add a stub:

1. Open `wow.lua` and find `M.api(W, toc)`.
2. Add `A.Name = function(...) ... end`, or a field inside the matching `C_` table.
3. Read state from `W.fixture` or `W`. Call `Record(W, "Name", ...)` when a test needs to see the call.

A partly mocked `C_` namespace still auto-stubs the functions it doesn't define.

To add a test, create `dev/tests/NN_topic.lua`:

```lua
local H = require("harness")
test("what it checks", function()
  local env = H.boot({ pet = true, macros = { "Arcane" }, bindings = { F13 = "MACRO PetAttack" } })
  env:slash("controller apply")
  eq(env:slotText(env:padSlot(1, "RT A")), "macro:Arcane")
end)
```

`noErrors(env)` fails on Lua errors from event handlers and timers, and on the `error:` lines Core.lua prints when a `/ac` command raises (`env:slash` collects those). The mock refuses `CreateMacro`, `EditMacro`, `DeleteMacro`, `PlaceAction` and the `SetBinding*` calls while `env.W.inCombat` is true, but still records them, so a test can assert that nothing was attempted.

To run a single file or test, run Lua directly from the repo root: `luajit dev/harness/run.lua addon/Agentcraft dev/tests controller` (the last argument filters by test or file name). Set `AC_VERBOSE=1` to echo the addon's chat output.

## Rendering the window

`dev.ps1 render` shows the `/ac` window without launching the game. It boots the addon in the harness with the hunter fixture (pet on, two library macros installed), runs `/ac`, selects each page with `ns.OpenPage(id)`, and writes:

| File | Content |
| --- | --- |
| `dev/render/out/index.html` | Every page with its warning counts, and every texture drawn. |
| `dev/render/out/<page-id><variant>.html` | The window at 1:1 UI pixels on a 1280x800 (Steam Deck) canvas, a 1920x1080 variant (radio button), zoom, and an "outline frames" switch: hover any box for its name, type, size, position and the addon line that created it. Below it, the layout warnings; click one to flash the object. |
| `dev/render/out/warnings.txt` | The same warnings as text. |
| `dev/render/out/textures-used.txt` | Every texture path, atlas and file ID drawn, with whether a PNG exists and whether the addon or a template uses it. |
| `dev/render/out/textures-missing.txt` | The ones without a PNG (what `-Fetch` downloads). |

Run it directly with `luajit dev/render/render.lua addon/Agentcraft dev/render/out dev/render/textures`.

Each variant boots its own game (`VARIANTS` in `render.lua`) and adds a suffix to the file name:

| Variant | Suffix | Pages | Setup |
| --- | --- | --- | --- |
| `kb` | none | all | default (keyboard prompts) |
| `pad` | `-pad` | all | Gamepad UI on: glyph prompts, LB/RB, 1.1 scale |
| `list` | `-list` | Keyboard, Controller | List view |
| `review` | `-review` | Keyboard, Controller, Macros | Review sheet open |
| `combat` | `-combat` | Keyboard, Controller, Macros, Options | after `PLAYER_REGEN_DISABLED` |
| `shift` | `-shift` | Keyboard | Shift held (live layer preview) |
| `lt` | `-lt` | Controller | Gamepad UI, LT (Shift) held |
| `ps` | `-ps` | Controller, gallery | Gamepad UI with PlayStation glyphs |

The dev-only Widget Gallery page (`dev/render/gallery.lua`) shows every v2 widget. `dev/render/forever-only.txt` lists WoW Forever atlases that the retail atlas table lacks: a missing one is an info line, not a warning, because the addon always names a retail atlas of the same role after it.

The warnings are real UI findings:

| Kind | Meaning |
| --- | --- |
| `unresolved` | An anchor chain is circular, points at a frame with no rectangle, or the frame has no anchors. |
| `unknown-template` | A template the renderer doesn't emulate; drawn as a dashed pink box. Add it to `M.TEMPLATES` in `frames.lua`. |
| `zero-size` | A frame or region with content has no width or height. |
| `overflow` | Text truncated by its width, cut off by its height, wider than its button, or spilling past the frame it starts in. |
| `outside` / `outside-page` | Content past the window's edge, or past the page area (the frame the window gives the page). |
| `overlap` | Two controls or texts under the same parent overlap. |
| `api` | A call the modern client rejects, such as `SetBackdrop` without `BackdropTemplate`. |
| `color-fill` | A flat `SetColorTexture` fill larger than 4x4 that the addon (not a template) made inside the window. Use `UI.Inset`, `UI.Panel`, `UI.Divider` or an atlas. |
| `missing-texture` | No PNG for a texture; it's drawn as a striped placeholder (icons), a dashed outline (other art) or a flat colour (template art). |
| `lua-error` | The page raised while opening. `render` exits 1. |
| `offscreen` | The window plus its side tabs, at the scale the client picks, doesn't fit 1229x768 (the Steam Deck at its UI scale). |
| `small-target` | Pad variants: a focus node under 28 px on either side. |
| `focus-unreachable` | A visible focus node that arrows, D-pad or Tab from the page's landing focus never reach. |
| `focus-deadend` | A focus node with no exit in any direction, one the landing focus can't be reached from again, or one that loses focus once the Inspector settles. |

The focus checks walk the page with real moves (`dev/harness/focuscheck.lua`, also used by `dev/tests/14_focus.lua`). The walk stands on each node the way a player does (set it, let the Inspector settle), presses each direction, presses a stepping row again until it leaves, keys Inspector rows by `acId` because they are pooled, and puts the page's view state, the settings and the scale back afterwards.

What is emulated and what is approximated:
- Emulated: anchors, sizes, scale, alpha, strata, frame level and draw-layer order (highlight layers are not drawn), shown state (hidden frames are skipped), scroll-frame and `SetClipsChildren` clipping, button states (normal, disabled, checked), colour textures, vertex colour, desaturation, additive blending, texture coordinates, `|c`, `|T` and `|n` markup.
- Approximated: fonts (Friz Quadrata and Arial Narrow aren't bundled; the page falls back to Palatino/Georgia and Arial), text width (a per-glyph table within about 5% of the fallback fonts), templates (`frames.lua` builds them from classic-style art with flat-colour fallbacks), backdrops (a CSS fill and border), texture file IDs (mapped through `dev/render/fileids.lua`), and tiling atlases (repeated at their own size only when the atlas spans its sheet along the tiled axis; otherwise stretched).

### Textures

PNGs go in `dev/render/textures/<path>.png`: the texture path in lower case with forward slashes, for example `interface/buttons/ui-quickslot2.png`. An atlas draws from its sheet when `dev/render/atlases.lua` maps it, and from `atlas/<name>.png` otherwise. A file ID draws from the path `dev/render/fileids.lua` gives it, and from `fileid/<id>.png` otherwise.

`dev.ps1 render -Fetch` renders once, reads `textures-missing.txt`, fetches only what that render needs, then renders again. The code is `dev/render/fetch.ps1`. It handles three kinds of line:

| Missing | What `-Fetch` does |
| --- | --- |
| `atlas/<name>` | Looks the name up in the `UiTextureAtlasMember` and `UiTextureAtlas` tables. It regenerates `dev/render/atlases.lua` with every atlas it already had plus the new ones: the sheet's path and file ID, the atlas size, its texture coordinates, and whether it tiles across or down. Then it fetches the sheet. |
| `fileid/<n>` | Names the file through the wago.tools file search, adds `[n] = "path"` to `dev/render/fileids.lua`, then fetches the file. |
| `interface/...` | Fetches the file. |

It fetches a file from these sources, in this order:
1. An atlas sheet comes from wago.tools by file ID first. The atlas coordinates come from the current build, and a 2022 PNG may have a different layout.
2. [Gethe/wow-ui-textures](https://github.com/Gethe/wow-ui-textures), branch `live`: PNGs that mirror `Interface\`, last updated in 2022. It downloads one file at a time from `raw.githubusercontent.com` and finds each file's exact case through the GitHub trees API. Never clone that repo: it is about 6 GB.
3. The client's own BLP file from wago.tools (`https://wago.tools/api/casc/<fileID>`), converted to PNG by a small BLP2 decoder in `fetch.ps1`. The decoder reads palettized, DXT1/3/5 and BGRA files. A path without a known file ID is looked up first with `https://wago.tools/files?search=<path>.blp`.

Sources:
- Atlas tables: `https://wago.tools/db2/UiTextureAtlasMember/csv` and `https://wago.tools/db2/UiTextureAtlas/csv`, the DB2 CSV exports of the latest retail build. Set `$WagoBuild` in `fetch.ps1` to read another build. `CommittedLeft`, `CommittedRight`, `CommittedTop` and `CommittedBottom` divided by the sheet's `AtlasWidth` and `AtlasHeight` give the texture coordinates. `CommittedFlags` 4 tiles across (the `_` names) and 2 tiles down (the `!` names).
- File ID to path: the wago.tools file search (`https://wago.tools/files?search=<fileID>`), which reads the [wowdev/wow-listfile](https://github.com/wowdev/wow-listfile) community listfile. `fetch.ps1` looks up one ID at a time, so the full listfile (over 100 MB) is never downloaded.
- Spell icons in the hunter fixture: `SpellMisc.SpellIconFileDataID` from `https://wago.tools/db2/SpellMisc/csv?branch=wow_classic_era`, typed into `dev/harness/fixtures/hunter.lua` as `icon = <fileID>`.

Everything downloaded is cached in `dev/render/textures/.cache/`: the GitHub trees (unauthenticated GitHub API calls are limited to 60 an hour), the two atlas CSVs, and `files.tsv` (file ID and path, including paths wago.tools doesn't list). A second `-Fetch` with the same missing list downloads nothing. Delete `.cache/` to refresh it, for example after a patch changes the atlases.

What no source has goes to `dev/render/textures/unavailable.txt`. Its `missing-texture` warnings say `(not mirrored)`, and `-Fetch` prints those files as `not mirrored`. A network failure prints as `not fetched` instead, and the next `-Fetch` tries again. An atlas name that isn't in `UiTextureAtlasMember` is "not mirrored" too. That usually means a typo, or a stand-in name in `frames.lua`, such as the old `minimal-slider-bar` (now the real `Minimal_SliderBar_Left`, `_Minimal_SliderBar_Middle` and `Minimal_SliderBar_Right`).

Fonts aren't in any of these sources and stay approximated.

`dev/render/fetch-test.ps1` unit-tests the fetch offline against hand-made samples: CSV parsing, atlas rows, the generated Lua, the BLP decoder and the caches. Run it with `powershell -NoProfile -ExecutionPolicy Bypass -File dev/render/fetch-test.ps1`.

`dev/render/out/`, `dev/render/textures/` and the generated `dev/render/atlases.lua` are gitignored. `dev/render/fileids.lua` is tracked, and `-Fetch` adds lines to it.
