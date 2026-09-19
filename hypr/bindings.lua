-- =============================================================================
-- Essential Hyprland Keybindings
-- Extracted from Omarchy - adapted to your ALT mod + HJKL style
-- =============================================================================

-- Variables (match your existing config)
var_mainMod = "ALT"
var_terminal = "kitty"
var_fileManager = "nautilus"
-- var_menu = "rofi -show drun"
var_menu = "qs ipc call launcher toggle"
-- -----------------------------------------------------------------------------
-- APPLICATION LAUNCHERS
-- -----------------------------------------------------------------------------
hl.bind(var_mainMod .. " + RETURN", hl.dsp.exec_cmd(var_terminal))
hl.bind(var_mainMod .. " + E", hl.dsp.exec_cmd(var_fileManager))
hl.bind(var_mainMod .. " + SPACE", hl.dsp.exec_cmd(var_menu))

-- -----------------------------------------------------------------------------
-- WINDOW MANAGEMENT
-- -----------------------------------------------------------------------------
-- Close window
hl.bind(var_mainMod .. " + Q", hl.dsp.window.close())

-- Toggle floating/tiling
hl.bind(var_mainMod .. " + V", hl.dsp.window.float())

-- Fullscreen
hl.bind(var_mainMod .. " + F", hl.dsp.window.fullscreen())

-- Window splitting
hl.bind(var_mainMod .. " + apostrophe", hl.dsp.layout("togglesplit"))

-- Pseudo tiling
hl.bind(var_mainMod .. " + P", hl.dsp.window.pseudo())

-- -----------------------------------------------------------------------------
-- WINDOW FOCUS (HJKL - vim style)
-- -----------------------------------------------------------------------------
hl.bind(var_mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(var_mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(var_mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(var_mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- -----------------------------------------------------------------------------
-- WINDOW MOVEMENT (Shift + HJKL)
-- -----------------------------------------------------------------------------
hl.bind(var_mainMod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(var_mainMod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "right" }))
hl.bind(var_mainMod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "up" }))
hl.bind(var_mainMod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "down" }))

-- -----------------------------------------------------------------------------
-- WINDOW RESIZE (Ctrl + HJKL)
-- -----------------------------------------------------------------------------
hl.bind(var_mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
hl.bind(var_mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))
hl.bind(var_mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
hl.bind(var_mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))

-- Fine resize (Alt + Ctrl + HJKL)
hl.bind(var_mainMod .. " + ALT + CTRL + H", hl.dsp.window.resize({ x = -25, y = 0, relative = true }))
hl.bind(var_mainMod .. " + ALT + CTRL + L", hl.dsp.window.resize({ x = 25, y = 0, relative = true }))
hl.bind(var_mainMod .. " + ALT + CTRL + K", hl.dsp.window.resize({ x = 0, y = -25, relative = true }))
hl.bind(var_mainMod .. " + ALT + CTRL + J", hl.dsp.window.resize({ x = 0, y = 25, relative = true }))

-- -----------------------------------------------------------------------------
-- WORKSPACES (1-9)
-- -----------------------------------------------------------------------------
for workspace = 1, 9 do
  hl.bind(var_mainMod .. " + " .. workspace, hl.dsp.focus({ workspace = workspace }))
  hl.bind(var_mainMod .. " + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace }))
end

-- Scroll through workspaces
hl.bind(var_mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(var_mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Quick workspace navigation
hl.bind(var_mainMod .. " + TAB", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(var_mainMod .. " + SHIFT + TAB", hl.dsp.focus({ workspace = "e-1" }))

-- -----------------------------------------------------------------------------
-- WINDOW GROUPING
-- -----------------------------------------------------------------------------
hl.bind(var_mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(var_mainMod .. " + ALT + G", hl.dsp.window.move({ out_of_group = true }))

-- Move into group
hl.bind(var_mainMod .. " + ALT + H", hl.dsp.window.move({ into_group = "left" }))
hl.bind(var_mainMod .. " + ALT + L", hl.dsp.window.move({ into_group = "right" }))
hl.bind(var_mainMod .. " + ALT + K", hl.dsp.window.move({ into_group = "up" }))
hl.bind(var_mainMod .. " + ALT + J", hl.dsp.window.move({ into_group = "down" }))

-- Navigate within group
hl.bind(var_mainMod .. " + ALT + TAB", hl.dsp.group.next())
hl.bind(var_mainMod .. " + ALT + SHIFT + TAB", hl.dsp.group.prev())

-- -----------------------------------------------------------------------------
-- MOUSE BINDINGS
-- -----------------------------------------------------------------------------
-- Move window with mouse
hl.bind(var_mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
-- Resize window with mouse
hl.bind(var_mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- -----------------------------------------------------------------------------
-- MEDIA CONTROLS (Hardware keys)
-- -----------------------------------------------------------------------------
-- Volume (using wpctl - matches your existing config)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), {
    repeating = true,
    locked = true,
})
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), {
    repeating = true,
    locked = true,
})
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), {
    locked = true,
})

-- Microphone mute
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), {
    locked = true,
})

-- Brightness (using brightnessctl)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), {
    repeating = true,
    locked = true,
})
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), {
    repeating = true,
    locked = true,
})

-- Media player controls
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- -----------------------------------------------------------------------------
-- SCREENSHOT (matches your existing config)
-- -----------------------------------------------------------------------------
-- Full screen screenshot
-- hl.bind(
 --   "SUPER + SHIFT + 3",
 --   hl.dsp.exec_cmd(
 --       "sh -c 'file=\"$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png\" && grim \"$file\" && \"$HOME/.config/hypr/scripts/screenshot-preview.py\" \"$file\" &'"
--    )
--)
hl.bind( "SUPER + SHIFT + 3" ,hl.dsp.exec_cmd("qs ipc call screenshot screen"))
-- Region screenshot
-- hl.bind(
--     "SUPER + SHIFT + 4",
--     hl.dsp.exec_cmd(
--         "sh -c 'file=\"$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png\" && geometry=\"$(slurp)\" && [ -n \"$geometry\" ] && grim -g \"$geometry\" \"$file\" && \"$HOME/.config/hypr/scripts/screenshot-preview.py\" \"$file\" &'"
--     )
-- )
hl.bind("SUPER + SHIFT + 4", hl.dsp.exec_cmd("qs ipc call screenshot region"))

-- -----------------------------------------------------------------------------
-- CLIPBOARD (matches your existing config)
-- -----------------------------------------------------------------------------
-- hl.bind("SUPER + V", hl.dsp.exec_cmd("cliphist list | rofi -dmenu -p \"Clipboard\" | cliphist decode | wl-copy"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
hl.bind("SUPER + period", hl.dsp.exec_cmd("qs ipc call emoji toggle"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("qs ipc call colorpicker pick"))
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("qs ipc call recorder toggle"))
-- -----------------------------------------------------------------------------
-- SYSTEM CONTROLS
-- -----------------------------------------------------------------------------
-- Lock screen (matches your existing config)
hl.bind(var_mainMod .. " + SHIFT + semicolon", hl.dsp.exec_cmd("hyprlock"))

-- Power menu/logout
-- hl.bind(var_mainMod .. " + X", hl.dsp.exec_cmd("wlogout"))
hl.bind(var_mainMod .. " + X", hl.dsp.exec_cmd("qs ipc call session toggle"))

-- Reload config
-- hl.bind(var_mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("sh -c 'killall waybar; hyprctl reload; waybar & notify-send \"Hyprland\" \"Reloaded ✨\"'"))
hl.bind(var_mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload; notify-send 'Hyprland' 'Reloaded ✨'"))
-- -----------------------------------------------------------------------------
-- UTILITY BINDINGS
-- -----------------------------------------------------------------------------
-- Wallpaper selector (matches your existing config)
-- hl.bind(var_mainMod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpicker.sh"))
hl.bind(var_mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"))

-- Theme selector (matches your existing config)
-- hl.bind(var_mainMod .. " + T", hl.dsp.exec_cmd("~/rice/main/theme-selector.sh"))
-- hl.bind(var_mainMod .. " + T", hl.dsp.exec_cmd("~/copyrice/larp/main/theme-selector.sh"))
hl.bind(var_mainMod .. " + T", hl.dsp.exec_cmd("qs ipc call theme toggle"))

-- Login screen (SDDM) theme selector
hl.bind(var_mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("qs ipc call logintheme toggle"))

-- -----------------------------------------------------------------------------
-- MISCELLANEOUS
-- -----------------------------------------------------------------------------
-- Center window
hl.bind(var_mainMod .. " + C", hl.dsp.window.center())

-- Toggle window transparency
hl.bind(var_mainMod .. " + backspace", function()
    local opacity = hl.get_config("decoration:active_opacity") or 1
    hl.config({ decoration = { active_opacity = opacity == 1 and 0.9 or 1 } })
end)

-- Toggle gaps
hl.bind(var_mainMod .. " + SHIFT + backspace", function()
    local gaps = hl.get_config("general:gaps_in") or 6
    hl.config({ general = { gaps_in = gaps == 6 and 0 or 6, gaps_out = gaps == 6 and 0 or 12 } })
end)

-- -----------------------------------------------------------------------------
-- TOUCHPAD GESTURES (matches your existing config)
-- -----------------------------------------------------------------------------
hl.config({
    gestures = {
        workspace_swipe_distance = 500,
        workspace_swipe_invert = true,
    },
    input = {
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            drag_lock = true,
            disable_while_typing = true,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})
hl.gesture({
    fingers = 3,
    direction = "up",
    action = "fullscreen",
})
hl.gesture({
    fingers = 3,
    direction = "down",
    action = "close",
})
hl.gesture({
    fingers = 4,
    direction = "down",
    action = "special",
})
hl.gesture({
    fingers = 2,
    direction = "pinchout",
    action = "cursorZoom",
})
hl.gesture({
    fingers = 4,
    direction = "pinch",
    action = "fullscreen",
})
