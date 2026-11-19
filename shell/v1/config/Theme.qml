pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Symlink to the active theme's quickshell/colors.json, managed by ThemeManager.
    readonly property string colorsFile: Quickshell.env("HOME") + "/.cache/quickshell/theme/colors.json"
    property var colors: ({})
    // Another theme's colors.json while the theme picker browses (modules/themes/ThemeView.qml):
    // the shell shows it as a preview without touching the links. null shows the active theme.
    property var preview: null
    readonly property var palette: preview ?? colors

    readonly property string name: colors.name ?? "Default"
    readonly property string variant: colors.variant ?? "dark"

    // How long a theme change takes to fade across the shell
    readonly property int fade: 320

    function reload() {
        file.reload();
    }

    function c(key, fallback) {
        return palette[key] ?? fallback;
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

    property color islandBg: c("island", "#000000")
    Behavior on islandBg { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color islandBorder: c("border", "#22ffffff")
    Behavior on islandBorder { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color textPrimary: c("text", "#ffffff")
    Behavior on textPrimary { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color textSecondary: c("textDim", "#aaaaaa")
    Behavior on textSecondary { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color accent: c("accent", "#0a84ff")
    Behavior on accent { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    readonly property color onAccent: c("onAccent", "#ffffff")
    readonly property color wifiInactive: Qt.alpha(textPrimary, 0.27)
    property color signalStrong: c("success", "#30d158")
    Behavior on signalStrong { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color signalMedium: c("warning", "#ffd60a")
    Behavior on signalMedium { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color signalWeak: c("caution", "#ff9f0a")
    Behavior on signalWeak { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    // Volume past 100%: the second lap drawn over a full bar. The theme's caution color, unless
    // it is too close to the bar fill to see (monochrome themes like Solitude): then danger.
    readonly property color boost: {
        const caution = Qt.color(c("caution", "#ff9f0a"));
        const f = controlFill;
        const distance = Math.abs(caution.r - f.r) + Math.abs(caution.g - f.g) + Math.abs(caution.b - f.b);
        return distance >= 0.5 ? caution : danger;
    }
    property color signalOff: c("muted", "#8e8e93")
    Behavior on signalOff { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }

    property color tileBg: c("tile", "#1c1c1e")
    Behavior on tileBg { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color tileHover: c("tileHover", "#242426")
    Behavior on tileHover { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color controlBg: c("control", "#2c2c2e")
    Behavior on controlBg { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color controlHover: c("controlHover", "#3a3a3c")
    Behavior on controlHover { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color danger: c("danger", "#ff453a")
    Behavior on danger { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color controlFill: c("fill", "#ffffff")
    Behavior on controlFill { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color controlIconOnFill: c("onFill", "#000000")
    Behavior on controlIconOnFill { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }

    readonly property color wsActiveBg: controlFill
    readonly property color wsActiveText: controlIconOnFill
    readonly property color wsOccupiedText: textPrimary
    readonly property color wsEmptyText: Qt.alpha(textPrimary, 0.33)
    readonly property color wsHoverBg: controlBg
    readonly property color wsUrgentBg: Qt.alpha(danger, 0.2)

    // Drop shadow under the shell's surfaces (components/Shadow.qml). Always dark, on every theme:
    // it is a shadow cast on the wallpaper, not a surface that follows the palette.
    readonly property color shadow: Qt.rgba(0, 0, 0, 0.45)

    readonly property color screenshotShade: Qt.alpha(islandBg, 0.55)
    readonly property color screenshotBorder: textPrimary

    property color batteryGood: c("success", "#30d158")
    Behavior on batteryGood { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color batteryLow: c("warning", "#ffd60a")
    Behavior on batteryLow { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }
    property color batteryCritical: c("danger", "#ff453a")
    Behavior on batteryCritical { ColorAnimation { duration: root.fade; easing.type: Easing.OutCubic } }

    // One family name, not a CSS list: QML reads "Inter, sans-serif" as a family called exactly
    // that, finds nothing, and falls back without a word. Qt falls back on its own if Inter is
    // missing, so the comma bought nothing and cost the font.
    readonly property string fontFamily: "Inter"
    // Nerd Font glyphs (icons drawn as text) and numbers that should not jump around
    readonly property string monoFamily: "JetBrainsMono Nerd Font"
}
