# quick-shell

An opinionated Hyprland desktop built around a **dynamic island**: one pill at the top of the
screen that shows the time, grows into a control center on hover, and morphs into the app
launcher, clipboard history, wallpaper switcher and theme switcher.

Everything lives in this repository and is symlinked into `~/.config`.

```
quick-shell/
├── quickshell/   the shell (Quickshell / QML)          → ~/.config/quickshell
├── hypr/         Hyprland, keybinds, hyprlock          → ~/.config/hypr
└── themes/       color schemes + default wallpapers
```

---

## Features

| | |
|---|---|
| **Island (idle)** | Wi-Fi strength · 12-hour clock · battery, colored by level |
| **Control center** (hover the island) | Clock, battery with health, calendar, Wi-Fi and Bluetooth tiles, brightness and volume sliders |
| **Wi-Fi page** | Scan, connect (with password), disconnect, forget |
| **Bluetooth page** | Scan, pair + connect, disconnect, forget, device battery |
| **OSD** | Volume / brightness keys briefly turn the island into a level bar |
| **Workspaces** | Separate pill top-left: click to switch, scroll to cycle |
| **Launcher** | Fuzzy app search, terminal apps open in kitty, built-in calculator |
| **Clipboard** | cliphist history with text and image previews, search, filters, delete |
| **Wallpapers** | Thumbnail grid of your wallpaper folders, applied with awww |
| **Themes** | Nine color schemes that restyle Quickshell, Hyprland borders, kitty, NvChad, VS Code, hyprlock and the wallpaper |
| **Screenshots** | Frozen-screen region / window / full-screen capture, saved and copied, with a draggable preview |

---

## Keybinds

`mod` is **Alt** (`var_mainMod` in `hypr/bindings.lua`).

| Keys | Action |
|---|---|
| `mod + Space` | App launcher / calculator |
| `mod + W` | Wallpaper switcher |
| `mod + T` | Theme switcher |
| `Super + V` | Clipboard history |
| `Super + Shift + 3` | Screenshot (full screen) |
| `Super + Shift + 4` | Screenshot (region) |
| `mod + Shift + ;` | Lock screen |
| Hover the island | Control center |

Inside the island views: arrows (or `Ctrl+H/J/K/L`) move, `Enter` applies, `Esc` or clicking
outside closes. The footer of each view lists its extra keys.

---

## Requirements

Arch packages:

```sh
sudo pacman -S quickshell hyprland hyprlock awww kitty neovim \
  networkmanager bluez bluez-utils wireplumber upower brightnessctl \
  cliphist wl-clipboard grim imagemagick glib2 xdg-utils libnotify playerctl \
  breeze-icons ttf-jetbrains-mono-nerd inter-font
```

- **Quickshell 0.3+** is required: the code uses `import qs.*` modules and the built-in Bluetooth,
  PipeWire and UPower services.
- **Hyprland with the Lua config** (`hyprland.lua` / `bindings.lua`). Workspace clicks send Lua
  dispatches (`hl.dsp.focus({ workspace = N })`).
- **NvChad** (base46 themes) and **VS Code** (`code` on `PATH`) are optional; themes skip them if
  they are missing.
- `inter-font` is optional; without it the shell falls back to the default sans-serif font.

---

## Installation

```sh
git clone <this repo> ~/Templates/quick-shell
cd ~/Templates/quick-shell

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

### One-time app configuration

The theme system switches apps by pointing symlinks in `~/.cache/quickshell/theme/` at the chosen
theme. Each app has to read from those links once:

**kitty**: at the end of `~/.config/kitty/kitty.conf`, and remove any other color `include`:

```conf
include ~/.cache/quickshell/theme/kitty.conf
```

**NvChad**: in `~/.config/nvim/lua/chadrc.lua`:

```lua
local ok, theme = pcall(dofile, vim.fn.expand("~/.cache/quickshell/theme/nvim.lua"))

M.base46 = {
    theme = ok and theme or "gruvbox-material",
}
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
├── vscode/theme                 Everforest Night Medium  (exact VS Code theme label)
└── wallpaper/wall.jpg           default wallpaper (.jpg / .png / .webp)
```

Switching a theme (`mod + T`, or `qs ipc call theme apply <id>`):

1. links `colors.json`, `kitty.conf`, `hyprland.lua`, `hyprlock.conf`, `nvim.lua` and `current` into `~/.cache/quickshell/theme/`
2. reloads every open kitty window (`SIGUSR1`) and runs `hyprctl reload` for the new border colors
3. recolors every running Neovim through its socket
4. replaces `workbench.colorTheme` in VS Code's `settings.json`
5. sets the theme wallpaper with awww and updates hyprlock's background path

| Theme | NvChad | VS Code theme (extension) |
|---|---|---|
| catppuccin-latte | catppuccin-latte | Catppuccin Latte (`catppuccin.catppuccin-vsc`) |
| catppuccin-macchiato | catppuccin | Catppuccin Macchiato (`catppuccin.catppuccin-vsc`) |
| dracula | chadracula | Dracula Theme (`dracula-theme.theme-dracula`) |
| everforest-dark | everforest | Everforest Night Medium (`jarith.everforest-night-vscode`) |
| gruvbox-material | gruvbox-material | Gruvbox Material Dark (`sainnhe.gruvbox-material`) |
| osaka-jade | gruvchad *(closest)* | Everforest Night Hard *(closest)* |
| rose-pine | rosepine | Rosé Pine (`mvllow.rose-pine`) |
| solitude | tomorrow_night *(closest)* | Default Dark Modern (built in) |
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

## Project structure

```
quickshell/
├── shell.qml                  entry point: creates the windows for every screen
├── config/
│   └── Theme.qml              all colors (read from the active theme) and fonts
├── services/                  system backends, no UI (singletons)
│   ├── Battery.qml            UPower
│   ├── BluetoothManager.qml   Quickshell.Bluetooth (BlueZ)
│   ├── Brightness.qml         brightnessctl + udev backlight events
│   ├── Clipboard.qml          cliphist
│   ├── Screenshot.qml         grim freeze → ImageMagick crop → wl-copy
│   ├── ShellState.qml         which island view is open
│   ├── ThemeManager.qml       lists themes, applies them, theme thumbnails
│   ├── Wallpaper.qml          awww, wallpaper folders, thumbnails, hyprlock path
│   └── Wifi.qml               nmcli
├── utils/
│   └── Calc.js                safe expression parser for the launcher
├── components/                reusable UI
│   ├── CircleButton  ControlSlider  PillButton  Spinner  Tile  Toggle
│   └── icons/                 Battery, Bluetooth, Check, Speaker, Sun, Wifi
└── modules/                   one folder per feature
    ├── ipc/Ipc.qml            every `qs ipc` target and global shortcut
    ├── bar/                   workspace pill
    ├── island/                island window, idle row, volume/brightness OSD
    ├── controlcenter/         grid, tiles/, controls/, wifi/, bluetooth/
    ├── launcher/  clipboard/  wallpaper/  themes/
    └── screenshot/            overlay + floating preview
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
qs ipc call wallpaper  toggle|open|close|random
qs ipc call theme      toggle|open|close|list|current
qs ipc call theme      apply gruvbox-material
qs ipc call screenshot region|window|screen|cancel
```

The same actions are registered as Hyprland global shortcuts named `quickshell:launcher`,
`quickshell:clipboard`, `quickshell:wallpaper`, `quickshell:themes` and `quickshell:screenshot`.

---

## Customizing

| What | Where |
|---|---|
| Wallpaper folders | `folders` in `quickshell/services/Wallpaper.qml` |
| Terminal for terminal apps | `terminal` in `quickshell/modules/launcher/Launcher.qml` |
| Always-visible workspaces | `persistentCount` in `quickshell/modules/bar/Workspaces.qml` |
| Default theme on first run | `defaultTheme` in `quickshell/services/ThemeManager.qml` |
| VS Code settings path | `vscodeSettings` in `quickshell/services/ThemeManager.qml` |
| Screenshot folder | `saveDir` in `quickshell/services/Screenshot.qml` (default `~/Pictures/Screenshots`) |
| Icon theme | first line of `quickshell/shell.qml` (`//@ pragma IconTheme breeze-dark`) |
| Fonts | `fontFamily` in `quickshell/config/Theme.qml` |

---

## Caches and state

| Path | Contents |
|---|---|
| `~/.cache/quickshell/theme/` | symlinks to the active theme's files |
| `~/.cache/quickshell/theme-thumbs/` | theme card thumbnails |
| `~/.cache/quickshell/wallpaper-thumbs/` | wallpaper grid thumbnails |
| `/tmp/qs-cliphist-$USER/` | decoded clipboard images |

All of them can be deleted safely; they are rebuilt on demand.

---

## Troubleshooting

- **Logs**: `qs log` (add `-f` to follow).
- **Keybinds do nothing**: check `qs list`. There must be one instance whose config path is
  `~/.config/quickshell/shell.qml`. Restart it with `pkill quickshell; quickshell -d`.
- **After editing shell files**: Quickshell hot-reloads on save. If a singleton starts throwing
  `TypeError` after a reload, restart the shell once.
- **Theme didn't reach an app**: `ls -l ~/.cache/quickshell/theme/` should show links into the
  active theme folder. kitty only picks up opacity changes in new windows.
- **Wallpapers or theme cards are blank**: delete the matching thumbnail folder and reopen the view.

## Known limitations

- Bluetooth pairing has no PIN or passkey prompt. Headphones, speakers and mice pair fine; devices
  that ask you to confirm a code need `bluetoothctl` once.
- The Wi-Fi password is passed to `nmcli` as an argument, so it is briefly visible in the process list.
- Screenshots capture only the focused monitor.
- osaka-jade and solitude have no real NvChad or VS Code counterpart; the closest themes are used.
