pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Colors from quickshell/colors.json: in dark mode the active theme's (the symlink the theme
// switcher keeps in ~/.cache/quickshell/theme/), in light mode Config.lightTheme's. Fallbacks
// keep the shell drawing without one.
Singleton {
    id: root

    readonly property string colorsFile: Config.mode === "light"
        ? Quickshell.shellDir + "/../themes/" + Config.lightTheme + "/quickshell/colors.json"
        : Quickshell.env("HOME") + "/.cache/quickshell/theme/colors.json"
    property var colors: ({})

    function c(key, fallback) {
        return colors[key] ?? fallback;
    }

    readonly property color background: c("island", "#000000")
    readonly property color border: c("border", "#22ffffff")
    readonly property color text: c("text", "#ffffff")
    readonly property color textDim: c("textDim", "#aaaaaa")
    readonly property color tile: c("tile", "#1c1c1e")
    readonly property color tileHover: c("tileHover", "#242426")
    readonly property color control: c("control", "#2c2c2e")
    // The accent picked in Poteto (Config.accent) wins over the theme's
    readonly property color accent: Config.accent || c("accent", "#0a84ff")
    // Text on the accent: the theme's for its own accent, otherwise dark on light colors and
    // white on the rest (the same rule scripts/apply-accent uses for apps)
    // (Not "onAccent": QML takes a name starting with "on" + a capital as a signal handler, and
    // the binding never runs)
    readonly property color accentText: Config.accent ? (luminance(accent) > 0.45 ? "#1a1a1a" : "#ffffff")
        : c("onAccent", "#ffffff")

    function luminance(color) {
        const lin = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * lin(color.r) + 0.7152 * lin(color.g) + 0.0722 * lin(color.b);
    }
    readonly property color danger: c("danger", "#ff453a")
    // Volume past 100%: the second lap drawn over a full bar. The theme's caution color, unless
    // it is too close to the text color the bar is drawn in (monochrome themes like Solitude):
    // then danger.
    readonly property color boost: {
        const caution = c("caution", "#ff9f0a");
        const t = text;
        const distance = Math.abs(caution.r - t.r) + Math.abs(caution.g - t.g) + Math.abs(caution.b - t.b);
        return distance >= 0.5 ? caution : danger;
    }
    readonly property color controlHover: c("controlHover", "#3a3a3c")
    // A solid button, e.g. the selected mode in the screenshot toolbar, and what is drawn on it
    readonly property color fill: c("fill", "#ffffff")
    // (Not "onFill": a read-only property starting with "on" + a capital never gets its value)
    readonly property color fillText: c("onFill", "#000000")
    // Drop shadow under floating surfaces (components/Shadow.qml). Always dark, on every theme:
    // it is cast on the wallpaper, not a surface that follows the palette.
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.45)

    readonly property string fontFamily: "Inter"
    // Numbers that should not jump around as they change
    readonly property string monoFamily: "JetBrainsMono Nerd Font"

    FileView {
        path: root.colorsFile
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.colors = JSON.parse(text());
            } catch (e) {
                console.warn("Theme: could not parse", root.colorsFile, e);
            }
        }
        onLoadFailed: root.colors = ({})
    }
}
