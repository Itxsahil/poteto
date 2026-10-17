pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The shell's colors: Poteto's dark or light palette (config/palettes.json, the same one
// scripts/apply-palette puts on kitty, Neovim, rmpc, Hyprland and hyprlock), by Config.mode, with
// the accent picked in Poteto on top. Both palettes are held, so the mode switches them live.
//
// A palette has eleven colors: bg, surface, overlay, border, text, subtext, accent, error,
// warning, success, info. The names below are the shell's for them, plus a few mixed from them.
Singleton {
    id: root

    property var palettes: ({})
    readonly property bool light: Config.mode === "light"
    readonly property var palette: (light ? palettes.light : palettes.dark)?.palette ?? ({})

    function p(key, fallback) {
        return palette[key] ?? fallback;
    }

    // Built in as well, so the shell draws even without palettes.json
    readonly property color background: p("bg", light ? "#f6f6f8" : "#121316")
    readonly property color tile: p("surface", light ? "#ebecef" : "#1b1c20")
    readonly property color control: p("overlay", light ? "#dfe1e6" : "#26282d")
    readonly property color border: p("border", light ? "#d9dbe0" : "#2c2e34")
    readonly property color text: p("text", light ? "#1c1d21" : "#e8e9ec")
    readonly property color textDim: p("subtext", light ? "#5e626b" : "#9b9ea6")
    readonly property color danger: p("error", light ? "#c8323a" : "#f07178")
    readonly property color warning: p("warning", light ? "#9a6400" : "#e5b567")
    readonly property color success: p("success", light ? "#2b8a4a" : "#7fc98f")
    readonly property color info: p("info", light ? "#1d77ad" : "#6cbfe0")

    // Hover shades and the solid fill, mixed from the palette rather than stored
    readonly property color tileHover: Qt.tint(tile, Qt.alpha(text, 0.06))
    readonly property color controlHover: Qt.tint(control, Qt.alpha(text, 0.08))
    // A solid button, e.g. the selected mode in the screenshot toolbar, and what is drawn on it
    readonly property color fill: text
    // (Not "onFill": a read-only property starting with "on" + a capital never gets its value)
    readonly property color fillText: background

    // The accent picked in Poteto (Config.accent), or the palette's own. A picked one is made
    // lighter in dark mode or darker in light mode until it stands out from the background (3:1),
    // so any color works in both.
    readonly property color accent: Config.accent ? readable(Config.accent, background, 3)
        : p("accent", light ? "#2f6fdb" : "#7ba4f7")
    // Text on the accent, black or white, whichever reads better
    // (Not "onAccent": QML takes a name starting with "on" + a capital as a signal handler, and
    // the binding never runs)
    readonly property color accentText: contrast(accent, "#ffffff") >= contrast(accent, "#1a1a1a") ? "#ffffff" : "#1a1a1a"

    function luminance(color) {
        const lin = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * lin(color.r) + 0.7152 * lin(color.g) + 0.0722 * lin(color.b);
    }

    function contrast(a, b) {
        const la = luminance(Qt.color(a));
        const lb = luminance(Qt.color(b));
        return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
    }

    // color, its lightness moved away from bg's until the two have `target` contrast
    function readable(color, bg, target) {
        let c = Qt.color(color);
        const darker = luminance(Qt.color(bg)) > 0.5;
        let l = c.hslLightness;
        // Bounded only at the end it moves toward: black on a dark background has to be able to
        // lighten from 0, and white on a light one to darken from 1
        while (contrast(c, bg) < target && (darker ? l > 0 : l < 1)) {
            l = Math.max(0, Math.min(1, l + (darker ? -0.01 : 0.01)));
            // (a gray has no hue: -1)
            c = Qt.hsla(Math.max(0, c.hslHue), c.hslSaturation, l, 1);
        }
        return c;
    }

    // Volume past 100%: the second lap drawn over a full bar, in the warning color
    readonly property color boost: warning

    // Drop shadow under floating surfaces (components/Shadow.qml). Always dark, in both modes:
    // it is cast on the wallpaper, not a surface that follows the palette.
    readonly property color shadow: Qt.rgba(0, 0, 0, light ? 0.22 : 0.45)

    readonly property string fontFamily: "Inter"
    // Numbers that should not jump around as they change
    readonly property string monoFamily: "JetBrainsMono Nerd Font"

    // Read before the first window exists (blockLoading), so the shell never draws in the wrong
    // colors
    FileView {
        path: Quickshell.shellDir + "/config/palettes.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.palettes = JSON.parse(text());
            } catch (e) {
                console.warn("Theme: config/palettes.json is not valid JSON; using the built-in colors");
            }
        }
    }
}
