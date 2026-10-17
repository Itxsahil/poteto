import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.modules.launcher
import qs.modules.controlcenter
import qs.modules.wallpaper

// Bar mode's stand-in for the pill growing: a panel that drops down from under the bar, holding
// the launcher (Alt + Space), the control center (hover the bar's clock, or Super + C) or the
// wallpaper picker (Alt + W).
PanelWindow {
    id: window

    required property ShellScreen targetScreen

    readonly property int barHeight: 30
    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === targetScreen.name
    readonly property bool showLauncher: ShellState.launcherOpen && focusedScreen
    readonly property bool showControlCenter: ShellState.controlCenterOpen && focusedScreen && !showLauncher
    readonly property bool showWallpaper: ShellState.wallpaperOpen && focusedScreen
    readonly property bool expanded: showLauncher || showControlCenter || showWallpaper
    // Opened from the keyboard, as opposed to a hover peek: takes the keyboard, closes on click-away
    readonly property bool pinned: ShellState.view !== "" && focusedScreen

    screen: targetScreen
    anchors.top: true
    margins.top: barHeight
    // Room for the panel at its largest; only the panel takes input
    implicitWidth: Math.max(launcher.implicitWidth, controlCenter.implicitWidth, wallpaper.implicitWidth) + 60
    implicitHeight: Math.max(launcher.maxRows * launcher.rowHeight + 120, controlCenter.implicitHeight + 60,
        wallpaper.implicitHeight + 60)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "barpanel"
    WlrLayershell.keyboardFocus: pinned ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: panel
    }

    // Clicking anywhere else closes it, armed late so the opening key press does not clear it
    HyprlandFocusGrab {
        id: grab
        windows: [window]
        onCleared: ShellState.close()
    }

    Timer {
        id: grabArm
        interval: 120
        onTriggered: grab.active = window.pinned
    }

    onPinnedChanged: {
        if (pinned)
            grabArm.restart();
        else
            grab.active = false;
    }

    Rectangle {
        id: panel

        // The size it is growing towards, kept while it shrinks away so the content does not jump
        property real targetWidth: launcher.implicitWidth + 20
        property real targetHeight: launcher.implicitHeight + 12

        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        width: window.expanded ? targetWidth : targetWidth * 0.6
        height: window.expanded ? targetHeight : 0
        radius: 24
        color: Theme.background
        border.color: Theme.border
        border.width: height > 2 ? 1 : 0
        clip: true
        visible: height > 0

        Binding on targetWidth {
            when: window.expanded
            restoreMode: Binding.RestoreNone
            value: window.showLauncher ? launcher.implicitWidth + 20
                : window.showWallpaper ? wallpaper.implicitWidth + 20
                : controlCenter.implicitWidth + 28
        }
        Binding on targetHeight {
            when: window.expanded
            restoreMode: Binding.RestoreNone
            value: window.showLauncher ? launcher.implicitHeight + 12
                : window.showWallpaper ? wallpaper.implicitHeight + 20
                : controlCenter.implicitHeight + 28
        }

        Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

        // Keeps a hover peek open while the pointer is on the panel rather than the clock
        HoverHandler {
            onHoveredChanged: hovered ? ShellState.hoverEnter() : ShellState.hoverExit()
        }

        LauncherContent {
            id: launcher
            x: 10
            y: 4
            width: implicitWidth
            height: implicitHeight
            active: window.showLauncher
            opacity: window.showLauncher ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: window.showLauncher ? 260 : 120; easing.type: Easing.InOutQuad }
            }
            onCloseRequested: ShellState.close("launcher")
        }

        WallpaperContent {
            id: wallpaper
            x: 10
            y: 10
            width: implicitWidth
            height: implicitHeight
            active: window.showWallpaper
            opacity: window.showWallpaper ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: window.showWallpaper ? 260 : 120; easing.type: Easing.InOutQuad }
            }
            onCloseRequested: ShellState.close("wallpaper")
        }

        ControlCenterContent {
            id: controlCenter
            x: 14
            y: 14
            width: implicitWidth
            height: implicitHeight
            active: window.showControlCenter && window.pinned
            opacity: window.showControlCenter ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: window.showControlCenter ? 260 : 120; easing.type: Easing.InOutQuad }
            }
            onCloseRequested: ShellState.close("controlcenter")
        }
    }
}
