# poteto

An opinionated Hyprland desktop built around a **dynamic island**: one pill at the top of the
screen that shows the time, grows into a control center on hover, and morphs into the app
launcher, clipboard history, emoji picker, wallpaper switcher, theme switcher and power menu.

Everything lives in this repository and is symlinked into `~/.config`.

```
poteto/
├── quickshell/   the shell (Quickshell / QML)          → ~/.config/quickshell
├── hypr/         Hyprland, keybinds, hyprlock          → ~/.config/hypr
└── themes/       color schemes + default wallpapers
```

---

## Features

| | |
|---|---|
| **Simple bar mode** | `mod + Shift + B` swaps the floating pills for one flat bar across the top — workspaces, the playing track and status in a single strip that reserves its own space. Everything the island opens still opens; click the right of the bar for the control center. The choice is remembered |
| **Island (idle)** | Wi-Fi strength · 12-hour clock · battery, colored by level · red mic icon while the mic is muted |
| **Control center** (rest the pointer on the island, or click it to keep it open) | A compact bento grid: clock (click it for the calendar), battery with health, Wi-Fi, Bluetooth, Notifications and Night Light tiles (Night Light opens a warmth slider), and brightness, volume and microphone sliders (click the mic icon or right click to mute). The button beside volume and mic opens the Sound page, which lists every output and input, with unplugged ones greyed out |
| **Audio devices** | A row of chips under the volume and mic sliders picks where sound goes and comes from — separate devices (Bluetooth, HDMI, USB) and the ports on one sound card (Speakers / Headphones, Internal / Headset Microphone) in the same list, shown only when there is more than one to choose from |
| **Wi-Fi page** | Scan, connect (with password), disconnect, forget |
| **Bluetooth page** | Scan, pair + connect, disconnect, forget, device battery |
| **OSD** | Volume, brightness and mic changes (including the Fn mic-mute key) briefly turn the island into a level bar |
| **Notifications** | Popups under the island with icons, images, actions and markup; history page and Do Not Disturb in the control center; unread dot in the island |
| **Workspaces** | Separate pill top-left: click to switch, scroll to cycle |
| **Music pill** | Small pill left of the center island: circular MPD album art (music icon when unavailable), four live visualizer bars while playing; click for media controls, right click for play/pause, Esc or click outside to close. Shown in island mode |
| **Status pill** | Top-right: MPD track with a live cava visualizer (click play/pause, right click next, middle click previous) and the date |
| **Media panel** (hover the status pill) | Album art, track, seek bar, play/pause, next/previous, shuffle, repeat (all / one) and MPD volume |
| **Launcher** | Fuzzy app search, terminal apps open in kitty, built-in calculator, and a **Keybindings** card when you type `key` |
| **Keybindings** | Searchable cheatsheet parsed live from `hypr/bindings.lua` plus the shell's own keys; flags combos bound twice |
| **Videos** | Every video under `~/Videos` in one grid with poster frames and durations, filtered by folder chips, like the wallpaper switcher |
| **Video player** | Qt Multimedia (FFmpeg) in its own window: seek bar, volume, speed, loop (off / one / all), subtitle tracks, the folder as playlist, `O` or the mpv button hands the file to mpv |
| **Camera** | Webcam in the island: live mirrored preview, shutter, 3s / 10s self-timer, photos to `~/Pictures/Camera`, thumbnail of the last shot; the camera is only powered while the view is open |
| **Emoji picker** | 1,900 emoji (Unicode 17) in 9 categories plus recently used, search by name, Enter to copy |
| **Clipboard** | cliphist history with text and image previews, search, filters, delete |
| **Wallpapers** | Thumbnail grid of your wallpaper folders, applied with awww |
| **Themes** | Twelve color schemes, picked from a scrolling row of palette cards, that restyle Quickshell, Hyprland borders, kitty, NvChad, VS Code, rmpc, hyprlock and (when supplied) the wallpaper |
| **Power menu** | Lock, logout, suspend, hibernate, reboot, shutdown with letter keys; logout/reboot/shutdown ask for a second press |
| **Color picker** | Frozen-screen picker with a pixel magnifier, arrow-key nudging, HEX / RGB / HSL copy, a notification swatch and a recent-colors bar |
| **Screen recorder** | Whole screen or a region at native resolution and 60 fps (NVENC, falls back to x264), system audio and/or mic mixed in, recording timer with a stop button, a name prompt while it saves (Enter to save, Esc keeps the date name), notification with Open / Show in folder |
| **Screenshots** | Frozen-screen region / window / full-screen capture, saved and copied, with a draggable preview |
| **Login screen** | Switch the SDDM theme from a scrolling row of previews; asks for your password each time (see [Login screen](#login-screen-sddm)) |
| **Login video** | Pick the video that plays behind the login screen from `~/Videos/Hidamari`, as a grid of poster frames like the wallpaper switcher. The greeter cannot read a 700 home directory, so the file is published into the live theme by the same root helper, and asks for your password |
| **Password prompts** | Built-in polkit agent: any app asking for admin rights gets its password prompt in the island |

---

## Keybinds

`mod` is **Alt** (`var_mainMod` in `hypr/bindings.lua`).

| Keys | Action |
|---|---|
| `mod + Space` | App launcher / calculator |
| `mod + W` | Wallpaper switcher |
| `mod + T` | Theme switcher |
| `mod + Shift + T` | Login screen (SDDM) theme switcher |
| `mod + Shift + W` | Login screen background video |
| `mod + Shift + V` | Videos |
| `mod + Shift + C` | Camera |
| `mod + /` | Keybinding cheatsheet |
| `Super + V` | Clipboard history |
| `Super + .` | Emoji picker |
| `Super + Shift + C` | Color picker |
| `Super + Shift + R` | Screen recorder (again to stop) |
| `Super + Shift + 3` | Screenshot (full screen) |
| `Super + Shift + 4` | Screenshot (region) |
| `mod + X` | Power menu (L lock · E logout · S suspend · H hibernate · R reboot · P shutdown) |
| `mod + Shift + ;` | Lock screen |
| `mod + B` | Border around the focused window on / off (remembered across reloads) |
| `mod + Shift + B` | Simple bar instead of the floating island, and back |
| `mod + S` | Scrolling layout (columns on an endless strip) instead of dwindle, and back |
| Hover the island | Control center (opens after a moment, closes when the pointer leaves) |
| Click the island | Control center, kept open until you click elsewhere or press Esc |

The table above is the shell's own keys. `mod + /` lists **every** bind, window management
included, parsed live from `hypr/bindings.lua`, and flags any combo bound twice.

Window management worth knowing, since these moved: groups are `mod + G` (toggle),
`mod + Shift + G` (move out), `Super + H/J/K/L` (move into) and `Super + Tab` (cycle inside).
Fine resize is `mod + Ctrl + Shift + H/J/K/L`. These were written as `mod + ALT + …`, which folds
back to plain `mod` when `mainMod` is Alt, so they silently collided with the focus, workspace and
resize binds and never fired.

Inside the island views: arrows (or `Ctrl+H/J/K/L`) move, `Enter` applies, `Esc` or clicking
outside closes. The footer of each view lists its extra keys.

In the videos grid: `Enter` plays, `Shift+Enter` (or right click) hands it to mpv, `Tab` cycles the
folder chips, and typing filters by name or folder.

In the video window: `Space` play/pause, `←`/`→` 5s (`Shift` 60s), `↑`/`↓` volume, `M` mute,
`F` fullscreen, `N`/`P` next and previous, `R` loop (off → this video → the whole list),
`[`/`]` speed, `C` subtitle track, `O` reopen in mpv, `Esc` close.

---

## Requirements

Arch packages:

```sh
sudo pacman -S quickshell hyprland hyprlock awww kitty neovim \
  networkmanager bluez bluez-utils wireplumber upower brightnessctl \
  cliphist wl-clipboard grim imagemagick glib2 xdg-utils libnotify playerctl mpd cava \
  wf-recorder ffmpeg qt6-multimedia-ffmpeg \
  breeze-icons ttf-jetbrains-mono-nerd noto-fonts-emoji inter-font
```

- **Quickshell 0.3+** is required: the code uses `import qs.*` modules and the built-in Bluetooth,
  PipeWire and UPower services.
- **Hyprland with the Lua config** (`hyprland.lua` / `bindings.lua`). Workspace clicks send Lua
  dispatches (`hl.dsp.focus({ workspace = N })`).
- **NvChad** (base46 themes) and **VS Code** (`code` on `PATH`) are optional; themes skip them if
  they are missing.
- `inter-font` is optional; without it the shell falls back to the default sans-serif font.
- **MPD + cava** are optional. The shell talks to MPD on `127.0.0.1:6600` (or `MPD_HOST` / `MPD_PORT`).
  The visualizer needs a fifo output in `mpd.conf`:

  ```conf
  audio_output {
      type   "fifo"
      name   "Visualizer feed"
      path   "/tmp/mpd.fifo"
      format "44100:16:2"
  }
  ```
- **No other notification daemon** may run (dunst, mako, swaync). Quickshell registers
  `org.freedesktop.Notifications` itself. If dunst is installed, mask it so D-Bus cannot start it:
  `systemctl --user mask --now dunst.service`.
- **No other polkit agent** may run (hyprpolkitagent, polkit-gnome, polkit-kde-agent). Quickshell
  registers itself as the session's agent; a second one would take the prompts instead.
- **The camera** needs `qt6-multimedia-ffmpeg` (the same backend the video player uses) and a
  V4L2 webcam. Without one the view opens and says so.
- **SDDM** is optional; the login screen switcher needs `sddm` with its Qt 6 greeter and `polkit`.

---

## Installation

```sh
git clone <this repo> ~/Templates/poteto
cd ~/Templates/poteto

# Link the configs (back up anything that is already there first)
ln -s "$PWD/quickshell" ~/.config/quickshell
ln -s "$PWD/hypr"       ~/.config/hypr
```

`themes/` does **not** need a link. The shell finds it next to its own folder (`quickshell/../themes`).

To switch between this shell and quickshell v2 from the launcher ("Switch Shell"), link the
script and its launcher entry:

```sh
ln -s "$PWD/switch-shell" ~/.local/bin/poteto-switch-shell
ln -s "$PWD/dev.poteto.SwitchShell.desktop" ~/.local/share/applications/
```

It moves `~/.config/quickshell` to the other folder and restarts Quickshell. When switching to
this shell it also points the theme links back at this shell's last theme. Run
`poteto-switch-shell v1`, `v2` or `status` from a terminal to pick a shell or see which is
active.

### Autostart

`hypr/hyprland.lua` already starts everything once Hyprland is up:

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("quickshell")
end)

hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
```

Always start the shell as plain `quickshell` (or `qs`), never with `-p <path>`. The keybinds call
`qs ipc call …`, which only reaches the instance started from `~/.config/quickshell`.

The autostart sets `QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi` for the shell. Without it, the video
player asks the NVIDIA GPU to decode AV1; GPUs before RTX 30 cannot, and it plays nothing at all
rather than falling back. VAAPI keeps hardware h264 and lets AV1 decode in software. Start it the
same way by hand: `env QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi quickshell`.

### One-time app configuration

The theme system switches apps by pointing symlinks in `~/.cache/quickshell/theme/` at the chosen
theme. Each app has to read from those links once:

**kitty**: at the end of `~/.config/kitty/kitty.conf`, and remove any other color `include`:

```conf
include ~/.cache/quickshell/theme/kitty.conf
```

The terminal is frosted glass: see-through, with Hyprland blurring whatever is behind it
(`decoration:blur` in `hypr/hyprland.lua`). That covers everything running in it too — Neovim,
rmpc, btop. Set the opacity here rather than per theme, so every theme gets it; a theme can still
override it in its own `kitty/<id>.conf`. kitty only reads `dynamic_background_opacity` when a
window starts, so reopen any open terminals once after adding it:

```conf
background_opacity          0.80
dynamic_background_opacity  yes
```

**NvChad**: in `~/.config/nvim/lua/chadrc.lua`:

```lua
local ok, theme = pcall(dofile, vim.fn.expand("~/.cache/quickshell/theme/nvim.lua"))
local transparent = vim.uv.fs_stat(vim.fn.expand("~/.cache/quickshell/theme/nvim-transparent")) ~= nil

M.base46 = {
    theme = ok and theme or "gruvbox-material",
    transparency = transparent,   -- only themes with an nvim/transparent marker (anime)
}
```

**rmpc**: link the active theme into rmpc's theme folder and select it in `~/.config/rmpc/config.ron`:

```sh
ln -s ~/.cache/quickshell/theme/rmpc.ron ~/.config/rmpc/themes/quickshell.ron
```

```ron
theme: Some("quickshell"),
```

**Hyprland borders**: already done. `hypr/hyprland.lua` reads `active_border` and
`inactive_border` from `~/.cache/quickshell/theme/hyprland.lua`, falling back to fixed colors.

**hyprlock**: already done. `hypr/hyprlock.conf` starts with
`source = ~/.cache/quickshell/theme/hyprlock.conf` and uses `$accent`, `$surface`, `$text`,
`$time`, `$date`, `$warning` and `$danger`.

**VS Code**: nothing to set up. `workbench.colorTheme` in `~/.config/Code/User/settings.json` is
rewritten on every switch. Install the VS Code theme extensions you want (see the table below).

On first start, if no theme has been applied yet, the shell applies **gruvbox-material**
automatically.

### Firefox (optional)

`firefox/` is a clean chrome for Firefox: compact tabs, square fields in the address bar, the page
as a rounded card inset under the toolbars, no lines between them, and only the buttons that earn
their place. It follows the system's light/dark mode live (the shell's mode toggle), and uses the
shell's accent color for focus rings, selections, menu hover and Firefox's own buttons.
`userContent.css` does the same for Firefox's own pages (new tab, settings).

Link the three files into your profile — `about:profiles` shows its path,
`~/.config/mozilla/firefox/…` on current Firefox and `~/.mozilla/firefox/…` before that:

```sh
profile=~/.config/mozilla/firefox/xxxxxxxx.default-release
mkdir -p "$profile/chrome"
ln -s "$PWD/firefox/userChrome.css"  "$profile/chrome/userChrome.css"
ln -s "$PWD/firefox/userContent.css" "$profile/chrome/userContent.css"
ln -s "$PWD/firefox/user.js"         "$profile/user.js"
```

`user.js` turns on `toolkit.legacyUserProfileCustomizations.stylesheets`, lets websites follow
Firefox's light/dark mode, and asks for the theme's accent. Firefox re-applies it on every start,
so those prefs win over `about:preferences`; delete a line to hand it back. Changes land after a
full restart (`about:profiles` → **Restart normally…**), not a new window.

The accent comes from `chrome/poteto-accent.css`, which quickshell v2 writes into every profile
whose `userChrome.css` links here, whenever the accent changes (Poteto → Accent Color). Without it,
Firefox keeps its own accent.

If Firefox stays dark in light mode, an older `user.js` forced it: reset `ui.systemUsesDarkTheme`
in `about:config`. Setting a pref in `user.js` stores it in the profile, so taking the line out of
`user.js` alone does not undo it.

### Accent color in apps (optional, quickshell v2)

The accent color picked in the **Poteto** settings app reaches most apps on its own: GTK 3 and
GTK 4 through `gtk.css`, VS Code through its settings, and Firefox through
`chrome/poteto-accent.css` in the profile. Those apply when each app starts.

To have **libadwaita and Qt apps change it live**, the desktop portal has to pass the accent on.
`xdg-desktop-portal-gtk` only passes light/dark, so add the GNOME backend for settings only. This
is a one-time setup outside the repo:

1. Install it:

   ```sh
   sudo pacman -S xdg-desktop-portal-gnome
   ```

2. Let it answer settings (color scheme and accent), and leave everything else — screenshots,
   screen sharing, file pickers — to Hyprland and GTK as before. In
   `~/.config/xdg-desktop-portal/hyprland-portals.conf`:

   ```ini
   [preferred]
   default=hyprland;gtk
   org.freedesktop.impl.portal.Settings=gnome;gtk
   ```

3. The packaged service only starts inside a systemd graphical session, which Hyprland started
   on its own does not have. Override it with the same service minus that requirement, in
   `~/.config/systemd/user/xdg-desktop-portal-gnome.service`:

   ```ini
   [Unit]
   Description=Portal service (GNOME implementation, without a GNOME session)

   [Service]
   Type=dbus
   BusName=org.freedesktop.impl.portal.desktop.gnome
   ExecStart=/usr/lib/xdg-desktop-portal-gnome
   ```

4. Reload and restart the portal:

   ```sh
   systemctl --user daemon-reload
   systemctl --user restart xdg-desktop-portal
   ```

Check it: this should print three numbers (the accent as red, green, blue) rather than
`Requested setting not found`.

```sh
busctl --user call org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop \
    org.freedesktop.portal.Settings ReadOne ss org.freedesktop.appearance accent-color
```

Qt apps follow the portal because `hypr/hyprland.lua` sets `QT_QPA_PLATFORMTHEME=xdgdesktopportal`.
The portal only knows GNOME's nine named accent colors: the swatches in Poteto change live
everywhere, while a custom color shows as the nearest named one in live apps and exactly in
`gtk.css` apps once they restart.

---

## Themes

Each theme is a folder of ready-made files. Nothing is generated; switching only moves symlinks.

```
themes/everforest-dark/
├── kitty/everforest-dark.conf   kitty colors (file name must match the folder name)
├── hyprland/colors.lua          return { active_border = "rgba(…ff)", inactive_border = "rgba(…aa)" }
├── hyprlock/colors.conf         $accent, $surface, $text, $time, $date, $warning, $danger
├── quickshell/colors.json       shell colors (see below)
├── nvim/theme.lua               return "everforest"     (NvChad base46 theme name)
├── nvim/transparent             optional marker: see-through Neovim while this theme is active
├── rmpc/theme.ron               rmpc theme
├── vscode/theme                 Everforest Night Medium  (exact VS Code theme label)
└── wallpaper/wall.jpg           optional default wallpaper (.jpg / .png / .webp)
```

Switching a theme (`mod + T`, or `qs ipc call theme apply <id>`):

1. links `colors.json`, `kitty.conf`, `hyprland.lua`, `hyprlock.conf`, `nvim.lua`, `nvim-transparent`, `rmpc.ron` and `current` into `~/.cache/quickshell/theme/`
2. reloads every open kitty window (`SIGUSR1`), runs `hyprctl reload` for the new border colors, and sends the new theme to every running rmpc (`rmpc remote --pid … set theme`)
3. recolors every running Neovim through its socket (theme and transparency), then rebuilds NvChad's
   highlight cache once more headlessly, so Neovims started later get the new theme too
4. replaces `workbench.colorTheme` in VS Code's `settings.json`
5. sets the theme wallpaper with awww and updates hyprlock's background path

| Theme | NvChad | VS Code theme (extension) |
|---|---|---|
| anime | vscode_dark | Dark Modern (built in) |
| catppuccin-latte | catppuccin-latte | Catppuccin Latte (`catppuccin.catppuccin-vsc`) |
| catppuccin-macchiato | catppuccin | Catppuccin Macchiato (`catppuccin.catppuccin-vsc`) |
| dracula | chadracula | Dracula Theme (`dracula-theme.theme-dracula`) |
| everforest-dark | everforest | Everforest Night Hard (`jarith.everforest-night-vscode`) |
| gruvbox-material | gruvbox-material | Gruvbox Dark Hard (`jdinhlife.gruvbox`) |
| horizon | horizon | Dark Modern (built in) |
| osaka-jade | scaryforest | Ocean Green: Dark (`jovejonovski.ocean-green`) |
| rose-pine | rosepine | Rosé Pine Moon (`mvllow.rose-pine`) |
| rxyhn | rxyhn | Dark Modern (built in; no matching VS Code theme bundled) |
| solitude | monochrome | Noctokai (`farigab.noctokai-theme`) |
| tokyo-night-storm | tokyonight | Tokyo Night Storm (`enkia.tokyo-night`) |

### Dark and light mode in quickshell v2

Quickshell v2 has no themes: it has one dark palette and one light one, in
`quickshellv2/config/palettes.json`, and the accent color on top. Both palettes are neutral
grays, so any accent sits well on them.

- **Mode** is set in Poteto, the control center's Dark button, or `qs ipc call appearance toggle`.
  It switches the shell, the system's light/dark preference (GTK, Qt, Firefox) and the apps below.
- **Accent** is set in Poteto. A picked color is made a little lighter in dark mode, or darker
  in light mode, until it stands out from the background.

`quickshellv2/scripts/apply-palette` puts the palettes on the apps:

| App | Dark | Light | How it switches |
|---|---|---|---|
| kitty | palette colors | palette colors | `SIGUSR1`, open windows too |
| Neovim (NvChad) | `vscode_dark`, see-through | `vscode_light`, see-through | every running instance, plus the cache for new ones |
| VS Code | Dark Modern | Light Modern | `workbench.colorTheme` |
| rmpc | palette colors | palette colors | `rmpc remote set theme` |
| Hyprland borders | accent | accent | `hyprctl reload` |
| hyprlock | palette colors | palette colors | read at lock time |

The script writes both modes' files into `~/.cache/quickshell/theme/dark/` and `light/` at
start and when the accent changes. Switching the mode only points
`~/.cache/quickshell/theme/active` at one of them and reloads the apps. kitty must not have a
`dark-theme.auto.conf` or `light-theme.auto.conf`: open windows ignore reloads while those
exist, so the script moves them aside as `.bak`. Edit `palettes.json` to change the colors;
the shell picks it up live, and the apps on the next accent change or shell start. The
wallpaper is never changed.

## Login screen (SDDM)

Login themes are standalone: they don't follow the color themes above.

```
sddm-themes/
├── setup                       one-time system setup (run as your user; it asks for sudo)
├── system/
│   ├── poteto-login-theme      helper, installed root-owned to /usr/local/bin
│   └── dev.poteto.login-theme.policy   polkit action: admin password, every time
├── rover-in-rain/              a theme: metadata.desktop, Main.qml, bg.mp4, ...
└── cloth-tiearing-anime/
```

**How it works.** SDDM is configured once to always load `/usr/share/sddm/themes/poteto`
(`Current=poteto` in `/etc/sddm.conf.d/theme.conf`). Switching themes never touches that config:
it replaces the contents of the `poteto` folder with the chosen theme. So there's no theme name
to type, and nothing to misspell.

**One-time setup:**

```sh
sddm-themes/setup rover-in-rain
```

This installs the helper and the polkit action, writes the config, removes copies left by the old
`install` script, and activates the theme you name. Re-run it after moving the repo or editing
anything in `sddm-themes/system/`. `sddm-themes/setup --uninstall` removes all of it.

**Changing just the video:** `mod + Shift + W` opens a grid of the videos in `~/Videos/Hidamari`
(including subfolders; MP4, WebM and MKV, up to 1 GiB). Poster frames come from the same scan the
video browser uses. Picking one copies it over the live theme's `bg.mp4` and asks for your password,
leaving the rest of the theme alone. Switching themes
afterwards brings that theme's own video back. The folder is `folder` in `services/LoginVideo.qml`.
Re-run `sddm-themes/setup <theme>` after updating the helper to enable video switching.

**Switching:** `mod + Shift + T`, pick a theme, enter your password in the island. It shows at the
next login screen. Press `P` in the switcher to preview a theme in a window first.

**Why it asks every time, and what the password allows.** Copying into `/usr/share` needs root.
Quickshell never gets root itself: it runs `pkexec /usr/local/bin/poteto-login-theme <name>`,
polkit asks for the admin password (never cached), and only that helper runs as root. The helper:

- accepts only a theme name (`a-z`, `0-9`, `-`); the repo path is fixed when `setup` installs it
- reads the theme with your own permissions, so it can never publish a file you couldn't read
- refuses themes containing symlinks, devices or other special files
- makes the installed copy root-owned and read-only for everyone else
- builds the new theme next to the live one and swaps them atomically, so the login screen is
  never left half-copied

**Adding a theme:** create a folder in `sddm-themes/` with `metadata.desktop` and `Main.qml`
(folder name in lowercase letters, digits and dashes). The switcher previews `bg.mp4`, or the
first video or image it finds. Test it without installing anything:

```sh
sddm-greeter-qt6 --test-mode --theme sddm-themes/<name>
```

---

## Project structure

```
quickshell/
├── shell.qml                  entry point: creates the windows for every screen
├── config/
│   └── Theme.qml              all colors (read from the active theme) and fonts
├── services/                  system backends, no UI (singletons)
│   ├── AlbumArt.qml           album art for the playing track (embedded, or a cover file)
│   ├── Audio.qml              audio devices and sound-card ports, and which is in use
│   ├── Battery.qml            UPower
│   ├── BluetoothManager.qml   Quickshell.Bluetooth (BlueZ)
│   ├── Brightness.qml         brightnessctl + udev backlight events
│   ├── Cava.qml               cava on the MPD fifo, only while MPD is playing
│   ├── Emoji.qml              emoji search and recently used (~/.cache/quickshell/emoji-recent.json)
│   ├── Keybinds.qml           cheatsheet parsed from hypr/bindings.lua
│   ├── Layout.qml             island or simple bar, remembered between restarts
│   ├── LoginTheme.qml         SDDM themes from ../sddm-themes, switched through pkexec
│   ├── LoginVideo.qml         the login screen's background video, swapped through the same helper
│   ├── Clipboard.qml          cliphist
│   ├── ColorPicker.qml        screen freeze, color formats, recent colors (~/.cache/quickshell/color-picker.json)
│   ├── Mpd.qml                MPD protocol client (idle events, play/pause/next/previous)
│   ├── Notifications.qml      notification server, popups, history, Do Not Disturb
│   ├── Player.qml             what the video window plays, and the folder playlist
│   ├── Polkit.qml             polkit authentication agent (password prompts)
│   ├── Recorder.qml           wf-recorder video + ffmpeg audio, merged into ~/Videos/Recordings
│   ├── Screenshot.qml         grim freeze → ImageMagick crop → wl-copy
│   ├── Videos.qml             ~/Videos scan, ffmpeg poster frames and durations
│   ├── Webcam.qml             webcam list, mirror, self-timer, photo folder
│   ├── Session.qml            power actions and logind capabilities, uptime
│   ├── ShellState.qml         which island view is open
│   ├── ThemeManager.qml       lists themes and applies them
│   ├── Wallpaper.qml          awww, wallpaper folders, thumbnails, hyprlock path
│   └── Wifi.qml               nmcli
├── assets/
│   └── emoji.json             emoji, names and categories (generated from Unicode emoji-test.txt)
├── utils/
│   └── Calc.js                safe expression parser for the launcher
├── components/                reusable UI
│   ├── CircleButton  ControlSlider  PillButton  Shadow  Spinner  Tile  Toggle
│   └── icons/                 Battery, Bell, Bluetooth, Check, Speaker, Sun, Wifi
└── modules/                   one folder per feature
    ├── ipc/Ipc.qml            every `qs ipc` target and global shortcut
    ├── bar/                   workspace pill (left), MusicPill beside the center island,
    │                          status pill with MPD and date (right),
    │                          media panel it expands into on hover, and the flat SimpleBar
    │                          that replaces all three in bar mode
    ├── island/                island window, idle row, volume/brightness OSD
    ├── controlcenter/         grid, tiles/, controls/, wifi/, bluetooth/, notifications/, audio/
    ├── notifications/         notification card + popup stack
    ├── launcher/  clipboard/  emoji/  wallpaper/  themes/  power/
    ├── logintheme/            login screen (SDDM) theme switcher
    ├── loginvideo/            login screen background video picker
    ├── keybinds/              keybinding cheatsheet
    ├── videos/                video grid with folder chips
    ├── camera/                webcam preview, shutter and self-timer
    ├── player/                video window (QtMultimedia)
    ├── polkit/                password prompt
    ├── screenshot/            overlay + floating preview
    ├── colorpicker/           color picker overlay
    └── recorder/              recording mode bar and region selection
```

Conventions:

- Services never draw anything; modules never run commands directly unless it is view-local.
- Colors always come from `Theme`. Content drawn on `Theme.accent` uses `Theme.onAccent`.
- A new island view: add a component to `modules/island/Island.qml` (`viewItem` + an instance),
  open it with `ShellState.open("name")`, and add an `IpcHandler` in `modules/ipc/Ipc.qml`.

---

## IPC

```sh
qs ipc show                               # list everything

qs ipc call launcher   toggle|open|close
qs ipc call clipboard  toggle|open|close
qs ipc call emoji      toggle|open|close
qs ipc call colorpicker pick|cancel|last
qs ipc call recorder   toggle|stop|status
qs ipc call wallpaper  toggle|open|close|random
qs ipc call theme      toggle|open|close|list|current
qs ipc call theme      apply gruvbox-material
qs ipc call logintheme toggle|open|close|list|current
qs ipc call logintheme apply rover-in-rain
qs ipc call loginvideo toggle|open|close|current
qs ipc call screenshot region|window|screen|cancel
qs ipc call notifications toggleDnd|dnd|clear|count|unread
qs ipc call session    toggle|open|close|lock
qs ipc call mpd        toggle|next|previous|status
qs ipc call keybinds   toggle|open|close
qs ipc call videos     toggle|open|close
qs ipc call camera     toggle|open|close
qs ipc call bar        toggle|simple|island|status|panel
qs ipc call layout     toggle|pill|bar|status       # same names as quickshell v2 (Alt + Shift + B)
qs ipc call controlcenter toggle|open|close        # same names as quickshell v2 (Super + C)
qs ipc call nightlight toggle|on|off|status        # shared with quickshell v2 and Poteto (shell.json)
qs ipc call player     play <path>|stop|next|previous|loop|status
qs ipc call player     speed 1        # or -1, steps 0.5×…2×
```

The same actions are registered as Hyprland global shortcuts named `quickshell:launcher`,
`quickshell:clipboard`, `quickshell:wallpaper`, `quickshell:themes`, `quickshell:power` and
`quickshell:screenshot`.

---

## Customizing

| What | Where |
|---|---|
| Wallpaper folders | `folders` in `quickshell/services/Wallpaper.qml` |
| Videos folder | `rootDir` in `quickshell/services/Videos.qml` (default `~/Videos`) |
| Terminal for terminal apps | `terminal` in `quickshell/modules/launcher/Launcher.qml` |
| Always-visible workspaces | `persistentCount` in `quickshell/modules/bar/Workspaces.qml` |
| Default theme on first run | `defaultTheme` in `quickshell/services/ThemeManager.qml` |
| VS Code settings path | `vscodeSettings` in `quickshell/services/ThemeManager.qml` |
| Power menu actions and commands | `actions` / `commands` in `quickshell/services/Session.qml` |
| Popup timeout, history size, max popups | `defaultTimeout`, `criticalTimeout`, `maxHistory`, `maxPopups` in `quickshell/services/Notifications.qml` |
| Screenshot folder | `saveDir` in `quickshell/services/Screenshot.qml` (default `~/Pictures/Screenshots`) |
| Camera photo folder | `saveDir` in `quickshell/services/Webcam.qml` (default `~/Pictures/Camera`) |
| Login video folder | `folder` in `quickshell/services/LoginVideo.qml` (default `Hidamari`, under `~/Videos`) |
| Icon theme | first line of `quickshell/shell.qml` (`//@ pragma IconTheme breeze-dark`) |
| Fonts | `fontFamily` in `quickshell/config/Theme.qml` |
| Window corners, shadows, blur, gaps, borders | `general` and `decoration` in `hypr/hyprland.lua` |
| Shadow under the shell's own surfaces | `shadow` in `quickshell/config/Theme.qml`, shape in `quickshell/components/Shadow.qml` |

---

## Caches and state

| Path | Contents |
|---|---|
| `~/.cache/quickshell/theme/` | symlinks to the active theme's files |
| `~/.cache/quickshell/theme/dark/`, `light/`, `active` | v2: the apps' files for each mode, and the active one (`scripts/apply-palette`) |
| `~/.cache/quickshell/vscode-settings.lock` | v2: keeps the palette and accent scripts from editing VS Code's settings at once |
| `~/.cache/quickshell/wallpaper-thumbs/` | wallpaper grid thumbnails |
| `~/.cache/quickshell/login-thumbs/` | login theme stills |
| `~/.cache/quickshell/video-thumbs/` | video poster frames and durations |
| `~/.cache/quickshell/album-art/` | album art extracted from the playing track |
| `~/.cache/quickshell/border` | `on` / `off` for the focused window's border (`mod + B`) |
| `~/.cache/quickshell/layout` | `island` / `bar`, the shell's shape (`mod + Shift + B`) |
| `~/.cache/quickshell/hypr-layout` | `dwindle` / `scrolling`, Hyprland's window layout (`mod + S`) |
| `$XDG_RUNTIME_DIR/qs-cliphist/` | decoded clipboard images (private: folder 0700, files 0600, cleared at logout) |

All of them can be deleted safely; they are rebuilt on demand, and `border` falls back to `on`.

---

## Troubleshooting

- **Logs**: `qs log` (add `-f` to follow).
- **Keybinds do nothing**: check `qs list`. There must be one instance whose config path is
  `~/.config/quickshell/shell.qml`. Restart it with `pkill quickshell; quickshell -d`.
- **After editing shell files**: Quickshell hot-reloads on save. If a singleton starts throwing
  `TypeError` after a reload, restart the shell once.
- **Theme didn't reach an app**: `ls -l ~/.cache/quickshell/theme/` should show links into the
  active theme folder. kitty only picks up opacity changes in new windows.
- **Wallpaper cards are blank**: delete the matching thumbnail folder and reopen the view.
- **Testing notifications**: `tools/notif-test` sends one of each shape (browser push with a site
  image, unescaped `&`/`<`, multi-line bodies, markup, critical, actions). Run it with no arguments
  for all of them, or name cases (`tools/notif-test chrome entities`). `qs ipc call notifications
  clear` clears the popups.
- **A video plays no picture** (black window, audio may work): the file's codec is being sent to a
  GPU that cannot decode it. Check `qs log` for `Failed setup for format cuda`, and make sure the
  shell was started with `QT_FFMPEG_DECODING_HW_DEVICE_TYPES=vaapi` (see Autostart). Press `O` in
  the player to hand the file to mpv meanwhile.
- **Chrome stops sending notifications**: Chrome picks the notification service once at startup, so
  it falls back to drawing its own if the shell reloaded at the wrong moment (only happens while
  editing the shell). Restart Chrome. Firefox re-checks per notification and is unaffected.
- **Login screen shows the plain default theme**: SDDM logs why on each boot:
  `journalctl -b -u sddm | grep -i theme`. `grep -r Current= /etc/sddm.conf.d/ /etc/sddm.conf`
  should print only `Current=poteto`; if not, re-run `sddm-themes/setup`.
- **No password prompt appears** (a switch fails with "Not authorized"): another polkit agent may
  own the session. Stop it, then restart Quickshell.

## Known limitations

- Bluetooth pairing has no PIN or passkey prompt. Headphones, speakers and mice pair fine; devices
  that ask you to confirm a code need `bluetoothctl` once.
- The Wi-Fi password is passed to `nmcli` as an argument, so it is briefly visible in the process list.
- Screenshots capture only the focused monitor.
- Notification history lives in memory: it survives shell reloads but not a restart or logout.
  Inline replies are not supported.
