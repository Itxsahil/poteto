# CLAUDE.md

poteto is a Hyprland desktop (Arch Linux) built around a Quickshell "dynamic island". It is a
dotfiles repo, not a buildable app: `shell/v1/` and `dotfiles/hypr/` are symlinked into
`~/.config` (as `quickshell` and `hypr`), and `themes/` and `login/` are found two folders up from
the shell (`Quickshell.shellDir + "/../../themes"`). `README.md` is the user-facing reference
(features, keybinds, IPC, requirements) — keep it in sync with changes.

## Layout

The repo is grouped by role. Moving a top-level folder breaks symlinks in `$HOME` and the
`../../` lookups in the shell, and moving `login/` also needs `login/setup` re-run as root.

- `shell/v1/` — the shell (QML, Quickshell 0.3+, `import qs.*` modules). The second shell, quickshell
  v2, was removed; it is kept in the `v2-final` git tag
  - `shell.qml` — entry point; creates the per-screen windows (bars, island, overlays, popups) and `Ipc`
  - `config/Theme.qml` — every color and font, read from the active theme's `colors.json`
  - `services/` — singletons that talk to the system (nmcli, BlueZ, UPower, MPD, cliphist, polkit, …); no UI
  - `modules/<feature>/` — UI, one folder per feature; `modules/ipc/Ipc.qml` holds every `qs ipc` target and global shortcut
  - `components/` — reusable widgets and `icons/`
  - `utils/Calc.js` — the launcher's safe expression parser
- `dotfiles/hypr/` — `hyprland.lua` (Hyprland's Lua config), `bindings.lua` (all keybinds), `hyprlock.conf`, `scripts/`
- `dotfiles/firefox/` — `userChrome.css`, `userContent.css`, `user.js`, linked into the Firefox profile
- `themes/<id>/` — one folder per color theme: `kitty/<id>.conf`, `hyprland/colors.lua`,
  `hyprlock/colors.conf`, `quickshell/colors.json`, `nvim/theme.lua`, `rmpc/theme.ron`,
  `vscode/theme`, `wallpaper/wall.*`
- `login/` — SDDM login themes (`metadata.desktop` + `Main.qml` + video), `setup` script, and
  `system/` (root-owned helper `poteto-login-theme` + polkit policy)
- `apps/settings/` — Poteto, the GTK settings app (`poteto-settings`, `.desktop`, icon)
- `tools/` — `check` (every check, run before committing), `qmllint-baseline.txt` (its known
  qmllint false alarms), `notif-test` (sends test notifications of every shape)
- `docs/` — `TODO.md`, `plan.txt` (the improvement plan)
- `refrences/` — another person's Quickshell config kept for ideas (gitignored)

## Conventions

- Services never draw anything; modules don't run commands directly unless it is view-local.
- Colors always come from `Theme`, never hard-coded. Content drawn on `Theme.accent` uses
  `Theme.onAccent`; on `Theme.fill` uses `Theme.controlIconOnFill`. Check that a change reads well on light
  themes (catppuccin-latte) and monochrome ones (solitude).
- Floating shell surfaces get a shadow with `components/Shadow.qml`, declared as a sibling before
  the surface. Its window needs room around the surface, or the shadow is clipped at the window edge.
- The shell has two shapes (`services/Layout.qml`): the floating island and a flat bar
  (`modules/bar/SimpleBar.qml`). Only the idle face changes — the island window still hosts every view,
  the OSD and the control center — so anything added to the idle pills needs a place on the bar too.
- New island view: add a component to `modules/island/Island.qml` (`viewItem` + an instance),
  open it with `ShellState.open("name")`, add an `IpcHandler` in `modules/ipc/Ipc.qml`, and bind a
  key in `dotfiles/hypr/bindings.lua` that calls `qs ipc call <target> <action>`.
- Theme switching only moves symlinks in `~/.cache/quickshell/theme/`. A new theme must provide
  every file above, with the kitty file named after the folder. The one generated theme is
  `themes/dynamic/` (gitignored), written by `shell/v1/scripts/theme-from-wallpaper` (matugen, or a
  built-in OKLCH fallback; the rmpc template is in `scripts/theme-templates/`). It is rebuilt on
  apply and on every wallpaper change while active; a new per-app file needs a line there too.
- Sizes and timings come from `config/Tokens.qml` by role (`Tokens.radius.row`, `Tokens.duration.view`),
  never new literals; animate with `components/Anim.qml` / `CAnim.qml` (`Behavior on x { Anim {} }`).
  Circles and pills are `height / 2` (or `width / 2`). Only functional timings and drawn shapes stay
  literal: spinner and pulse loops, the polkit shake, the camera flash, the visualizer bars, icon
  corners of a few pixels.
- Shared widgets live in `components/` and are used instead of redrawing them: the search box at
  the top of a view is `SearchField` (keys reach the view through `onKeyPressed`, extras declared
  inside it sit at its right end); a round icon button is `CircleButton` (flat with
  `baseColor: "transparent"`, `active` for the accent fill, `glyphFont: Theme.monoFamily` for a Nerd
  Font icon).
- Theme colors in `config/Theme.qml` fade (`Behavior` + `Theme.fade`); `Theme.preview` holds the
  theme picker's preview. Read colors through `Theme`, never from `colors.json` directly.
- User settings live in `~/.config/poteto/shell.json`, read and written only by `config/Settings.qml`
  (shared with Poteto, so keep its key names). Services bind to `Settings.<key>` and change
  it with `Settings.set(key, value)`; never give a setting its own file or `FileView`.
- Cache/state goes under `~/.cache/quickshell/`; list new paths in the README "Caches and state" table.
- New user-facing features and keys go in the README tables (Features, Keybinds, IPC, Customizing).

## Gotchas

- `mod` is **Alt** (`var_mainMod`). Never write `mod + ALT + …`: it folds back to plain `mod` and
  silently collides with other binds. The keybind cheatsheet (`services/Keybinds.qml`) parses
  `dotfiles/hypr/bindings.lua` live, so keep its `hl.bind(...)` style parseable.
- Workspace and window actions are Lua dispatches (`hl.dsp.*`), not classic `hyprctl dispatch` strings.
- The shell must be started as plain `quickshell`; `qs ipc` only reaches that instance.
- Quickshell owns `org.freedesktop.Notifications` and the polkit agent — don't add code that
  assumes dunst/mako or another agent.
- The login-theme helper runs as root via `pkexec`: keep its input validation strict (theme name
  `[a-z0-9-]`, no symlinks or special files, atomic swap). Re-run `login/setup` after editing `system/`.

## Validating changes

There is no build, test suite or CI. Before committing, run **`tools/check`** (about 7 s); it must
end with "all good". It runs:

- Qt 6's qmllint (`/usr/lib/qt6/bin/qmllint`, settings in `shell/v1/.qmllint.ini`; `/usr/bin/qmllint`
  is Qt 5's and checks nothing). It needs Quickshell's import paths: with the shell running, a
  one-time `touch shell/v1/.qmlls.ini shell/v1/shell.qml` makes Quickshell write them (the file is
  gitignored). Syntax errors always fail; other warnings fail only when they are not in
  `tools/qmllint-baseline.txt`, which holds the known false alarms (qmllint cannot tell that the
  shell's own services are singletons). After fixing warnings, or after checking that new ones are
  false alarms, run `tools/check --update-baseline` and commit the baseline with the change.
- `bash -n` (and shellcheck if installed), `luac -p`, JSON and Python parsing, and that every
  `themes/<id>/` has every file and `colors.json` key.

qmllint does not run the code: still re-read QML diffs, and watch `qs log -f` (Quickshell
hot-reloads on save). Many reloads in one session can slow the shell down; restart it rather than
rebooting.

## QML rules

Apply these to code you write or touch; there is no sweep to apply them everywhere at once.

- Typed functions: `function apply(path: string): void`, so qmllint can check the callers.
- Delegates take their model data as `required property var modelData` / `required property int
  index`, and files with delegates start with `pragma ComponentBehavior: Bound`, which makes
  delegates name what they use from outside (`root.selected`, not a bare `selected`).
- Don't let a new qmllint warning into the baseline without reading it: most real typos show up
  as `[missing-property]` or `[unresolved-type]`.
- A setting goes through `Settings`, a color through `Theme` (see Conventions).

## Commits

Short imperative subject ("Add …", "Fix …"), then a body of `- ` bullets explaining what changed
and why.
