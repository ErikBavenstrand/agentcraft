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
