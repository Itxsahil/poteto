-- =============================================================================
-- Hyprland Configuration
-- Clean setup with essential Omarchy keybindings
-- Adapted to match your existing ALT mod + HJKL style
-- =============================================================================

-- Import keybinds
require("bindings")

-- Main modifier (matches your config)
var_mainMod = "ALT"

-- Default applications (matches your config)
var_terminal = "kitty"
var_fileManager = "dolphin"
var_menu = "wofi --show drun"

-- Monitor configuration
hl.monitor({
    output = "",
    disabled = false,
    mode = "preferred",
    position = "auto",
    scale = 1,
})

-- Input settings
hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = true,
            tap_to_click = true,
            drag_lock = true,
            disable_while_typing = true,
        },
    },
})

-- General settings (matches your config)
hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 12,
        border_size = 1,
        col = {
            active_border = "rgba(cba6f7ff)",
            inactive_border = "rgba(585b70aa)",
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
    },
})

-- Decoration (matches your config)
hl.config({
    decoration = {
        active_opacity = 1.0,
        inactive_opacity = 1.0,
        fullscreen_opacity = 1.0,
        blur = {
            enabled = false,
            size = 10,
            passes = 3,
        },
    },
})

-- Animations (matches your config)
hl.curve("smooth", { type = "bezier", points = { {0.25, 0.1}, {0.25, 1.0} } })
hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 4,
    bezier = "smooth",
    style = "slide",
})
hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 4,
    bezier = "smooth",
    style = "slide",
})
hl.animation({
    leaf = "border",
    enabled = true,
    speed = 6,
    bezier = "smooth",
})
hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 4,
    bezier = "smooth",
})
hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 5,
    bezier = "smooth",
    style = "slide",
})

-- Miscellaneous
hl.config({
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
    },
})

-- Environment variables
hl.env("__GL_GSYNC_ALLOWED", "0")
hl.env("__GL_VRR_ALLOWED", "0")

-- Screenshot Preview (matches your config)
hl.window_rule({
    name = "screenshot-preview",
    match = {
        class = "dev.sahil.ScreenshotPreview",
    },
    float = true,
    size = "200 100",
    move = "monitor_w-window_w-6 monitor_h-window_h-6",
})

-- Gesture settings
hl.config({
    gestures = {
        workspace_swipe_distance = 500,
        workspace_swipe_invert = true,
    },
})

-- Autostart (matches your config)
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    -- hl.exec_cmd("waybar")
    hl.exec_cmd("quickshell")
end)

-- Clipboard (matches your config)
hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
