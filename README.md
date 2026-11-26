# Agentcraft

A World of Warcraft addon plus the Claude Code plugin (`wow`) that ships it. Claude reads your character from disk and helps you play it.

- **Addon** (`addon/Agentcraft`): writes your full character state to SavedVariables on every `/reload` and logout, and adds an in-game window (`/ac`) for laying out action bars, keybinds, controller pages and macros.
- **Plugin skills** (`skills/`):
  - `reading-game-state`: reads gear, stats, talents, spells, pet, bags, quests, reputation, keybinds, any addon's saved data, Lua errors and combat logs.
  - `installing-addon`: installs or updates Agentcraft in your WoW folder.
  - `extending-addon`: Agentcraft's structure and client API gotchas, for adding features.
- **Reader** (`scripts/wowdata.ps1`): the script the skills run. Windows PowerShell only.
- **Dev kit** (`dev/`): checks a change before you `/reload` (see [dev/README.md](dev/README.md)).

## Install

The plugin is listed in the `bavenstrand` marketplace:

```sh
claude plugin marketplace add ErikBavenstrand/claude-plugins
claude plugin install wow@bavenstrand
```

Then ask Claude to install the addon, and type `/reload` twice in game.

## Open the window with a controller

Every page of the `/ac` window works with a controller alone, for example on a Steam Deck with the Gamepad UI on. The D-pad moves, A selects, B backs out one step and then closes, X changes the view, Y is the page's main action, and LB / RB switch pages. The right stick scrolls lists. Agentcraft never binds a button for you, so pick one or more of these:

- **Key Bindings.** Open the game menu, then Options › Key Bindings › Agentcraft. Bind Toggle Agentcraft, or one of the page bindings (Keyboard, Controller, Macros), to a pad button or a chord. A page binding pressed again on its own page closes the window.
- **The Agentcraft macro.** On the Macros page, install Agentcraft (it runs `/ac`). Review & Apply on the Controller page then puts it on page 3, LT + RT + Y, the same button for every class.
- **The addon list by the minimap.** Click Agentcraft in the minimap's addon list. On the Deck, use the touchscreen or a trackpad as the mouse.
- **Chat.** Type `/ac`. On the Deck, press Steam + X to open Steam's keyboard.

A new install needs a full game restart, not `/reload`, before the key bindings and the minimap entry appear.

The Macros page's search box needs a keyboard, because the game never opens Steam's keyboard by itself. On a controller, filter instead with For You / Everything (X), the tag chips and More..., which lists every tag in the right-hand pane. To type anyway, press A on the box, then Steam + X. Pick Up (dragging a macro onto a button) needs the mouse. On a controller, Review & Apply places every macro that has a home in your layout.

## Develop

Clone this repo and link it into the game, so edits load on `/reload`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/wowdata.ps1 install -Link
```

Check a change before reloading:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File dev/dev.ps1 check
```

It runs the TOC check, the macro and layout rules, luacheck and the LuaJIT test harness. Install LuaJIT (`winget install DEVCOM.LuaJIT`) and luacheck (`luacheck.exe` from its GitHub releases) for the last two.
