import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.modules.launcher

// The floating layout: the time in a rounded pill at the top center of the screen. Opening the
// launcher grows this same pill into it, and closing shrinks it back.
PanelWindow {
    id: window

    required property ShellScreen targetScreen

    // Gap between the pill and the top of the screen
    readonly property int gapTop: 8
    readonly property int pillHeight: 30

    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === targetScreen.name
    readonly property bool open: ShellState.launcherOpen && focusedScreen

    screen: targetScreen
    anchors.top: true
    // Room for the pill at its largest. Only the pill itself takes input, and only its resting
    // height is reserved, so windows never move when it grows.
    implicitWidth: launcher.implicitWidth + 40
    implicitHeight: gapTop + launcher.maxRows * launcher.rowHeight + 120
    exclusiveZone: gapTop + pillHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "pill"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: pill
    }

    // Clicking anywhere else closes it. Armed a moment late, so the key press that opened the
    // launcher is not what clears the grab.
    HyprlandFocusGrab {
        id: grab
        windows: [window]
        onCleared: ShellState.launcherOpen = false
    }

    Timer {
        id: grabArm
        interval: 120
        onTriggered: grab.active = window.open
    }

    onOpenChanged: {
        if (open)
            grabArm.restart();
        else
            grab.active = false;
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        y: window.gapTop
        width: window.open ? launcher.implicitWidth + 20 : time.implicitWidth + 80
        height: window.open ? launcher.implicitHeight + 12 : window.pillHeight
        radius: window.open ? 22 : window.pillHeight / 2
        color: Theme.background
        border.color: Theme.border
        border.width: 1
        clip: true

        // A little overshoot, so the pill swells into the launcher rather than sliding open
        Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        Clock {
            id: time
            anchors.centerIn: parent
            date: clock.date
            opacity: window.open ? 0 : 1
            scale: window.open ? 0.8 : 1
            Behavior on opacity { NumberAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        LauncherContent {
            id: launcher
            x: 10
            y: 4
            width: implicitWidth
            height: implicitHeight
            active: window.open
            // Comes in once the pill has mostly grown, and leaves before it shrinks
            opacity: window.open ? 1 : 0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: window.open ? 260 : 120; easing.type: Easing.InOutQuad }
            }
            onCloseRequested: ShellState.launcherOpen = false
        }
    }
}
