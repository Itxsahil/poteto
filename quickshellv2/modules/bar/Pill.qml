import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.modules.launcher
import qs.modules.controlcenter

// The floating layout: the time in a rounded pill at the top center of the screen. The same pill
// grows into whatever is opened — the launcher (Alt + Space) or the control center (hover it, or
// Super + C) — and shrinks back when it closes.
PanelWindow {
    id: window

    required property ShellScreen targetScreen

    // Gap between the pill and the top of the screen
    readonly property int gapTop: 8
    readonly property int pillHeight: 30

    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === targetScreen.name
    readonly property bool showLauncher: ShellState.launcherOpen && focusedScreen
    readonly property bool showControlCenter: ShellState.controlCenterOpen && focusedScreen && !showLauncher
    readonly property bool expanded: showLauncher || showControlCenter
    // Opened from the keyboard, as opposed to a hover peek: takes the keyboard, closes on click-away
    readonly property bool pinned: ShellState.view !== "" && focusedScreen

    screen: targetScreen
    anchors.top: true
    // Room for the pill at its largest. Only the pill itself takes input, and only its resting
    // height is reserved, so windows never move when it grows.
    implicitWidth: Math.max(launcher.implicitWidth, controlCenter.implicitWidth) + 60
    implicitHeight: gapTop + Math.max(launcher.maxRows * launcher.rowHeight + 120, controlCenter.implicitHeight + 60)
    exclusiveZone: gapTop + pillHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "pill"
    WlrLayershell.keyboardFocus: pinned ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: pill
    }

    // Clicking anywhere else closes it. Armed a moment late, so the key press that opened it is
    // not what clears the grab.
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

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        y: window.gapTop
        width: window.showLauncher ? launcher.implicitWidth + 20
            : window.showControlCenter ? controlCenter.implicitWidth + 28
            : time.implicitWidth + 80
        height: window.showLauncher ? launcher.implicitHeight + 12
            : window.showControlCenter ? controlCenter.implicitHeight + 28
            : window.pillHeight
        radius: window.expanded ? 24 : window.pillHeight / 2
        color: Theme.background
        border.color: Theme.border
        border.width: 1
        clip: true

        // A little overshoot, so the pill swells into what it opens rather than sliding open
        Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        HoverHandler {
            onHoveredChanged: hovered ? ShellState.hoverEnter() : ShellState.hoverExit()
        }

        Clock {
            id: time
            anchors.centerIn: parent
            date: clock.date
            opacity: window.expanded ? 0 : 1
            scale: window.expanded ? 0.8 : 1
            Behavior on opacity { NumberAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        // Each one comes in once the pill has mostly grown, and leaves before it shrinks
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
