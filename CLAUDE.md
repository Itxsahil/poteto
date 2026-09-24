# CLAUDE.md

poteto is a Hyprland desktop (Arch Linux) built around a Quickshell "dynamic island". It is a
dotfiles repo, not a buildable app: `quickshell/` and `hypr/` are symlinked into `~/.config`, and
`themes/` is found next to the shell at `quickshell/../themes`. `README.md` is the user-facing
reference (features, keybinds, IPC, requirements) — keep it in sync with changes.

## Layout

- `quickshell/` — the shell (QML, Quickshell 0.3+, `import qs.*` modules)
  - `shell.qml` — entry point; creates the per-screen windows (bars, island, overlays, popups) and `Ipc`
  - `config/Theme.qml` — every color and font, read from the active theme's `colors.json`
  - `services/` — singletons that talk to the system (nmcli, BlueZ, UPower, MPD, cliphist, polkit, …); no UI
  - `modules/<feature>/` — UI, one folder per feature; `modules/ipc/Ipc.qml` holds every `qs ipc` target and global shortcut
  - `components/` — reusable widgets and `icons/`
  - `utils/Calc.js` — the launcher's safe expression parser
- `hypr/` — `hyprland.lua` (Hyprland's Lua config), `bindings.lua` (all keybinds), `hyprlock.conf`, `scripts/`
- `themes/<id>/` — one folder per color theme: `kitty/<id>.conf`, `hyprland/colors.lua`,
  `hyprlock/colors.conf`, `quickshell/colors.json`, `nvim/theme.lua`, `rmpc/theme.ron`,
  `vscode/theme`, `wallpaper/wall.*`
- `sddm-themes/` — login themes (`metadata.desktop` + `Main.qml` + video), `setup` script, and
  `system/` (root-owned helper `poteto-login-theme` + polkit policy)
- `tools/notif-test` — sends test notifications of every shape

## Conventions

- Services never draw anything; modules don't run commands directly unless it is view-local.
- Colors always come from `Theme`, never hard-coded. Content drawn on `Theme.accent` uses
  `Theme.onAccent`; on `Theme.fill` uses `Theme.controlIconOnFill`. Check that a change reads well on light
  themes (catppuccin-latte) and monochrome ones (solitude).
- New island view: add a component to `modules/island/Island.qml` (`viewItem` + an instance),
  open it with `ShellState.open("name")`, add an `IpcHandler` in `modules/ipc/Ipc.qml`, and bind a
  key in `hypr/bindings.lua` that calls `qs ipc call <target> <action>`.
- Theme switching only moves symlinks in `~/.cache/quickshell/theme/`; nothing is generated. A new
  theme must provide every file above, with the kitty file named after the folder.
- Cache/state goes under `~/.cache/quickshell/`; list new paths in the README "Caches and state" table.
- New user-facing features and keys go in the README tables (Features, Keybinds, IPC, Customizing).

## Gotchas

- `mod` is **Alt** (`var_mainMod`). Never write `mod + ALT + …`: it folds back to plain `mod` and
  silently collides with other binds. The keybind cheatsheet (`services/Keybinds.qml`) parses
  `hypr/bindings.lua` live, so keep its `hl.bind(...)` style parseable.
- Workspace and window actions are Lua dispatches (`hl.dsp.*`), not classic `hyprctl dispatch` strings.
- The shell must be started as plain `quickshell`; `qs ipc` only reaches that instance.
- Quickshell owns `org.freedesktop.Notifications` and the polkit agent — don't add code that
  assumes dunst/mako or another agent.
- The login-theme helper runs as root via `pkexec`: keep its input validation strict (theme name
  `[a-z0-9-]`, no symlinks or special files, atomic swap). Re-run `sddm-themes/setup` after editing `system/`.

## Validating changes

There is no build, test suite, linter config or CI. Before committing:

- Re-read QML diffs carefully for property/id typos and missing imports — mistakes only show up at runtime.
- Shell scripts: `bash -n <file>` (and `shellcheck` if available).
- Lua: `luac -p hypr/*.lua themes/*/hyprland/colors.lua` if `luac` is available.
- JSON: `python3 -m json.tool themes/<id>/quickshell/colors.json`.
- On a real machine: Quickshell hot-reloads on save; logs are in `qs log -f`.

## Commits

Short imperative subject ("Add …", "Fix …"), then a body of `- ` bullets explaining what changed
and why.
