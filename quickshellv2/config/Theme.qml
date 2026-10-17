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
    readonly property color accent: c("accent", "#0a84ff")
    readonly property color onAccent: c("onAccent", "#ffffff")
    readonly property color danger: c("danger", "#ff453a")
    readonly property color controlHover: c("controlHover", "#3a3a3c")
    // A solid button, e.g. the selected mode in the screenshot toolbar, and what is drawn on it
    readonly property color fill: c("fill", "#ffffff")
    readonly property color onFill: c("onFill", "#000000")
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
