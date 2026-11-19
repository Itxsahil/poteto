# TODO

Small open items for the shell (`shell/v1/`). The bigger, phased work is in `docs/plan.txt`.
Last updated 2026-11-20. quickshell v2 was removed; it is kept in the `v2-final` git tag.

## Shell

- [ ] **Keybind cheatsheet** — some labels end in a stray ")" (found early on, never fixed).
- [ ] **`SimpleBar.qml`** — a MouseArea warning in `qs log` (found early on, never fixed).
- [ ] **Overview wallpapers** — some `wall.jpg` files under `~/copyrice/larp/themes/` are not real
      JPEGs ("Unsupported image format" in `qs log`): convert or rename them.
- [ ] **Fn + F4 (mic mute)** — check it works; if not, find its key with `wev` and bind it the way
      Fn + F6 is (`code:160`).
- [ ] **Open Poteto from the shell** — a keybind and a settings button in the control center
      (v2 had one; v1 only has the launcher entry).

## Firefox

- [ ] **Grey search chip** in the address bar — needs the Browser Toolbox to find what paints it
      (`dotfiles/firefox/userChrome.css`).
- [ ] **Accent color** — nothing writes `poteto-accent.css` since v2 is gone; either have the
      theme switch write one from the theme's accent, or drop the import.

## Repo

- [ ] Choose a license (MIT or GPL-3; GPL-3 allows copying from `refrences/`).
- [ ] Decide on `temp`, and whether the four ignored light themes get committed.
- [ ] Push `reformating` (nothing from this round of work is pushed yet).

## Done

- [x] Low-battery warnings at 15% and 5%, shown even in Do Not Disturb (2026-11-20).
- [x] `dotfiles/hypr/hyprlock.conf` no longer changes with every wallpaper pick — the path lives in
      `~/.cache/quickshell/hyprlock-wallpaper.conf` (2026-11-20).
- [x] One settings file: `config/Settings.qml` reads and writes `~/.config/poteto/shell.json`
      (2026-11-20).
- [x] v1 is the only shell; v2 and `switch-shell` removed, tagged `v2-final` (2026-11-20).

## Not tried by hand

Checked with screenshots and `qs ipc` only, since clicks and typing could not be sent from here:
dragging sliders and regions, typing into fields (launcher, Wi-Fi password, recording name),
and most button clicks.
