pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Colors from the active theme's quickshell/colors.json (the symlink the theme switcher keeps in
// ~/.cache/quickshell/theme/), with fallbacks so the shell still draws without one.
Singleton {
    id: root

    readonly property string colorsFile: Quickshell.env("HOME") + "/.cache/quickshell/theme/colors.json"
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

    readonly property string fontFamily: "Inter"

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
