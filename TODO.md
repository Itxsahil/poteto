# TODO — quickshell v2

What is still left to bring over from the old shell (`quickshell/`) or to finish in v2
(`quickshellv2/`). Branch: `quickshell-v2`. Last updated 2026-10-17.

## From the old shell

- [ ] **Theme switcher (Alt + T)** — the bind exists but nothing answers it. Pick one of the 12
      themes in `themes/` and apply it to the shell, kitty, Hyprland, hyprlock, Neovim, rmpc,
      VS Code and the wallpaper. Has to fit with light/dark mode (`Config.mode`) and the accent
      color (`Config.accent`).
- [ ] **Media panel in the bar** — the MPD song with album art and the audio visualizer (old:
      `bar/MediaPanel.qml`, `bar/MpdWidget.qml`, `services/AlbumArt.qml`, `services/Cava.qml`).
- [ ] **`qs ipc call mpd toggle|next|previous|status`** — for MPD keybinds.
- [ ] **Calendar** — the old control center had calendar and clock tiles; maybe a page opened from
      the clock.

## Small additions

- [ ] **Low-battery warning** — a notification around 15% and 5% while unplugged (today only the
      battery icon changes color).
- [ ] **Fn + F4 (mic mute)** — check it works; if not, find its key with `wev` and bind it the way
      Fn + F6 is (`code:160`).

## Loose ends

- [ ] **Firefox: grey search chip** in the address bar — needs the Browser Toolbox to find what
      paints it (`firefox/userChrome.css`).
- [ ] **Firefox: accent color** — focus ring, selection and menu hover still use Firefox's own
      blue, even with `widget.non-native-theme.use-theme-accent`.
- [ ] **Accent color live in Qt and libadwaita apps** — needs `xdg-desktop-portal-gnome` as the
      settings portal; until then they take the accent on their next start.
- [ ] **Docs** — `README.md` and `CLAUDE.md` still describe the old shell, not v2 (features,
      keybinds, IPC, Poteto, caches and state).

## Repo

- [ ] Push `quickshell-v2` (nothing is pushed yet).
- [ ] Decide on the changes outside the v2 commits: `.gitignore`, `README.md`, `temp`.
- [ ] `hypr/hyprlock.conf` changes with every wallpaper pick (the lock screen follows it) — keep
      it out of git, or move the path somewhere untracked.
- [ ] Old-shell issues found at the start (keybind cheatsheet ")" labels, the `SimpleBar.qml`
      MouseArea warning, README mismatches) were never fixed — only worth it if the old shell
      stays.
- [ ] Decide what happens to the old shell (`quickshell/`) once v2 covers everything: keep it as
      a fallback, or remove it (and the symlink note in the README).

## Not tried by hand

Checked with screenshots and `qs ipc` only, since clicks and typing could not be sent from here:
dragging sliders and regions, typing into fields (launcher, Wi-Fi password, recording name),
and most button clicks.

## Done in v2

Pill and bar layouts, launcher (with calculator and `?` for the cheatsheet), control center
(Wi-Fi, Bluetooth, Quiet, Dark, Night, Sound, Mic, Screen, MPD, notifications, lock / restart /
power, record, and an Audio page for outputs and inputs; Awake and Airplane dropped as not
needed), light/dark mode, accent color, night light, brightness and volume OSD with mic mute,
notifications in the pill with history, screenshots, color picker, screen recorder, clipboard,
emoji, wallpaper picker, video browser and player, camera, login theme and video pickers,
polkit agent, power menu, keybind cheatsheet, workspaces / battery / Wi-Fi capsules, and the
Poteto settings app.
