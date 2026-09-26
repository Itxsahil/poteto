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
| **Island (idle)** | Wi-Fi strength · 12-hour clock · battery, colored by level · red mic icon while the mic is muted |
| **Control center** (hover the island) | Clock, battery with health, calendar, Wi-Fi, Bluetooth and Notifications tiles, brightness, volume and microphone sliders (click the mic icon or right click to mute) |
| **Wi-Fi page** | Scan, connect (with password), disconnect, forget |
| **Bluetooth page** | Scan, pair + connect, disconnect, forget, device battery |
| **OSD** | Volume, brightness and mic changes (including the Fn mic-mute key) briefly turn the island into a level bar |
| **Notifications** | Popups under the island with icons, images, actions and markup; history page and Do Not Disturb in the control center; unread dot in the island |
| **Workspaces** | Separate pill top-left: click to switch, scroll to cycle |
| **Status pill** | Top-right: MPD track with a live cava visualizer (click play/pause, right click next, middle click previous) and the date |
| **Media panel** (hover the status pill) | Album art, track, seek bar, play/pause, next/previous, shuffle, repeat (all / one) and MPD volume |
| **Launcher** | Fuzzy app search, terminal apps open in kitty, built-in calculator, and a **Keybindings** card when you type `key` |
| **Keybindings** | Searchable cheatsheet parsed live from `hypr/bindings.lua` plus the shell's own keys; flags combos bound twice |
| **Videos** | Every video under `~/Videos` in one grid with poster frames and durations, filtered by folder chips, like the wallpaper switcher |
| **Video player** | Qt Multimedia (FFmpeg) in its own window: seek bar, volume, speed, loop (off / one / all), subtitle tracks, the folder as playlist, `O` or the mpv button hands the file to mpv |
| **Emoji picker** | 1,900 emoji (Unicode 17) in 9 categories plus recently used, search by name, Enter to copy |
| **Clipboard** | cliphist history with text and image previews, search, filters, delete |
| **Wallpapers** | Thumbnail grid of your wallpaper folders, applied with awww |
| **Themes** | Eleven color schemes, picked from a scrolling row of palette cards, that restyle Quickshell, Hyprland borders, kitty, NvChad, VS Code, rmpc, hyprlock and the wallpaper |
| **Power menu** | Lock, logout, suspend, hibernate, reboot, shutdown with letter keys; logout/reboot/shutdown ask for a second press |
| **Color picker** | Frozen-screen picker with a pixel magnifier, arrow-key nudging, HEX / RGB / HSL copy, a notification swatch and a recent-colors bar |
| **Screen recorder** | Whole screen or a region at native resolution and 60 fps (NVENC, falls back to x264), system audio and/or mic mixed in, recording timer with a stop button, a name prompt while it saves (Enter to save, Esc keeps the date name), notification with Open / Show in folder |
| **Screenshots** | Frozen-screen region / window / full-screen capture, saved and copied, with a draggable preview |
| **Login screen** | Switch the SDDM theme from a scrolling row of previews; asks for your password each time (see [Login screen](#login-screen-sddm)) |
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
| `mod + Shift + V` | Videos |
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
| Hover the island | Control center |

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
  wf-recorder ffmpeg \
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

`firefox/` is a flat dark chrome for Firefox: compact, rounded tabs and address bar, no lines
between the toolbar and the page, and only the buttons that earn their place. It is fixed dark, not
part of the theme system. Link both files into your profile — `about:profiles` shows its path,
`~/.config/mozilla/firefox/…` on current Firefox and `~/.mozilla/firefox/…` before that:

```sh
profile=~/.config/mozilla/firefox/xxxxxxxx.default-release
mkdir -p "$profile/chrome"
ln -s "$PWD/firefox/userChrome.css" "$profile/chrome/userChrome.css"
ln -s "$PWD/firefox/user.js"        "$profile/user.js"
```

`user.js` turns on `toolkit.legacyUserProfileCustomizations.stylesheets` for you. Firefox re-applies
it on every start, so those prefs win over `about:preferences`; delete a line to hand it back.
Changes land after a full restart (`about:profiles` → **Restart normally…**), not a new window.

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
└── wallpaper/wall.jpg           default wallpaper (.jpg / .png / .webp)
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
| horizon | horizon | Horizon (`jolaleye.horizon-theme-vscode`) |
| osaka-jade | scaryforest | Ocean Green: Dark (`jovejonovski.ocean-green`) |
| rose-pine | rosepine | Rosé Pine Moon (`mvllow.rose-pine`) |
| solitude | monochrome | Noctokai (`farigab.noctokai-theme`) |
| tokyo-night-storm | tokyonight | Tokyo Night Storm (`enkia.tokyo-night`) |

### `quickshell/colors.json`

```jsonc
{
  "name": "Everforest Dark",     // shown in the theme switcher
  "variant": "dark",             // "dark" | "light"
  "island": "#2d353b",           // island, workspace pill, panel background
  "border": "#3a444a",           // island outline
  "tile": "#3a444a",             // control-center tiles, search fields
  "tileHover": "#475258",
  "control": "#475258",          // slider tracks, buttons, chips
  "controlHover": "#859289",
  "fill": "#d3c6aa",             // slider fill, active workspace
  "onFill": "#2d353b",           // icons/text drawn on "fill"
  "text": "#d3c6aa",
  "textDim": "#9da9a0",
  "muted": "#859289",            // disconnected / inactive states
  "accent": "#a7c080",           // toggles, badges, selection, today in the calendar
  "onAccent": "#2d353b",         // text/icons drawn on "accent"
  "success": "#a7c080",          // battery ok, strong Wi-Fi
  "warning": "#dbbc7f",          // battery low, medium Wi-Fi
  "caution": "#e69875",          // weak Wi-Fi
  "danger": "#e67e80"            // battery critical, errors, delete buttons
}
```

Editing a theme's `colors.json` while that theme is active updates the shell immediately.

### Adding a theme

```sh
cd themes
cp -r everforest-dark my-theme
mv my-theme/kitty/everforest-dark.conf my-theme/kitty/my-theme.conf
# edit the colors, nvim/theme.lua, vscode/theme, and replace wallpaper/wall.*
```

It appears in the theme switcher the next time it opens.

---

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
│   ├── Battery.qml            UPower
│   ├── BluetoothManager.qml   Quickshell.Bluetooth (BlueZ)
│   ├── Brightness.qml         brightnessctl + udev backlight events
│   ├── Cava.qml               cava on the MPD fifo, only while MPD is playing
│   ├── Emoji.qml              emoji search and recently used (~/.cache/quickshell/emoji-recent.json)
│   ├── Keybinds.qml           cheatsheet parsed from hypr/bindings.lua
│   ├── LoginTheme.qml         SDDM themes from ../sddm-themes, switched through pkexec
│   ├── Clipboard.qml          cliphist
│   ├── ColorPicker.qml        screen freeze, color formats, recent colors (~/.cache/quickshell/color-picker.json)
│   ├── Mpd.qml                MPD protocol client (idle events, play/pause/next/previous)
│   ├── Notifications.qml      notification server, popups, history, Do Not Disturb
│   ├── Player.qml             what the video window plays, and the folder playlist
│   ├── Polkit.qml             polkit authentication agent (password prompts)
│   ├── Recorder.qml           wf-recorder video + ffmpeg audio, merged into ~/Videos/Recordings
│   ├── Screenshot.qml         grim freeze → ImageMagick crop → wl-copy
│   ├── Videos.qml             ~/Videos scan, ffmpeg poster frames and durations
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
    ├── bar/                   workspace pill (left), status pill with MPD and date (right),
    │                          media panel it expands into on hover
    ├── island/                island window, idle row, volume/brightness OSD
    ├── controlcenter/         grid, tiles/, controls/, wifi/, bluetooth/, notifications/
    ├── notifications/         notification card + popup stack
    ├── launcher/  clipboard/  emoji/  wallpaper/  themes/  power/
    ├── logintheme/            login screen (SDDM) theme switcher
    ├── keybinds/              keybinding cheatsheet
    ├── videos/                video grid with folder chips
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
qs ipc call screenshot region|window|screen|cancel
qs ipc call notifications toggleDnd|dnd|clear|count
qs ipc call session    toggle|open|close|lock
qs ipc call mpd        toggle|next|previous|status
qs ipc call keybinds   toggle|open|close
qs ipc call videos     toggle|open|close
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
| Icon theme | first line of `quickshell/shell.qml` (`//@ pragma IconTheme breeze-dark`) |
| Fonts | `fontFamily` in `quickshell/config/Theme.qml` |
| Window corners, shadows, blur, gaps, borders | `general` and `decoration` in `hypr/hyprland.lua` |
| Shadow under the shell's own surfaces | `shadow` in `quickshell/config/Theme.qml`, shape in `quickshell/components/Shadow.qml` |

---

## Caches and state

| Path | Contents |
|---|---|
| `~/.cache/quickshell/theme/` | symlinks to the active theme's files |
| `~/.cache/quickshell/wallpaper-thumbs/` | wallpaper grid thumbnails |
| `~/.cache/quickshell/login-thumbs/` | login theme stills |
| `~/.cache/quickshell/video-thumbs/` | video poster frames and durations |
| `~/.cache/quickshell/album-art/` | album art extracted from the playing track |
| `~/.cache/quickshell/border` | `on` / `off` for the focused window's border (`mod + B`) |
| `/tmp/qs-cliphist-$USER/` | decoded clipboard images |

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
