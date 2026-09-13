pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Symlink to the active theme's quickshell/colors.json, managed by ThemeManager.
    readonly property string colorsFile: Quickshell.env("HOME") + "/.cache/quickshell/theme/colors.json"
    property var colors: ({})

    readonly property string name: colors.name ?? "Default"
    readonly property string variant: colors.variant ?? "dark"

    function reload() {
        file.reload();
    }

    function c(key, fallback) {
        return colors[key] ?? fallback;
    }

    Component.onCompleted: file.reload()

    FileView {
        id: file
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

    readonly property color islandBg: c("island", "#000000")
    readonly property color islandBorder: c("border", "#22ffffff")
    readonly property color textPrimary: c("text", "#ffffff")
    readonly property color textSecondary: c("textDim", "#aaaaaa")
    readonly property color accent: c("accent", "#0a84ff")
    readonly property color onAccent: c("onAccent", "#ffffff")
    readonly property color wifiInactive: Qt.alpha(textPrimary, 0.27)
    readonly property color signalStrong: c("success", "#30d158")
    readonly property color signalMedium: c("warning", "#ffd60a")
    readonly property color signalWeak: c("caution", "#ff9f0a")
    readonly property color signalOff: c("muted", "#8e8e93")

    readonly property color tileBg: c("tile", "#1c1c1e")
    readonly property color tileHover: c("tileHover", "#242426")
    readonly property color controlBg: c("control", "#2c2c2e")
    readonly property color controlHover: c("controlHover", "#3a3a3c")
    readonly property color danger: c("danger", "#ff453a")
    readonly property color controlFill: c("fill", "#ffffff")
    readonly property color controlIconOnFill: c("onFill", "#000000")

    readonly property color wsActiveBg: controlFill
    readonly property color wsActiveText: controlIconOnFill
    readonly property color wsOccupiedText: textPrimary
    readonly property color wsEmptyText: Qt.alpha(textPrimary, 0.33)
    readonly property color wsHoverBg: controlBg
    readonly property color wsUrgentBg: Qt.alpha(danger, 0.2)

    readonly property color screenshotShade: Qt.alpha(islandBg, 0.55)
    readonly property color screenshotBorder: textPrimary

    readonly property color batteryGood: c("success", "#30d158")
    readonly property color batteryLow: c("warning", "#ffd60a")
    readonly property color batteryCritical: c("danger", "#ff453a")

    readonly property string fontFamily: "Inter, sans-serif"
}
