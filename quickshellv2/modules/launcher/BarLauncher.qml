import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

// The launcher in bar mode: a panel that drops down from under the bar, growing from nothing
// the way the pill grows in pill mode.
PanelWindow {
    id: window

    required property ShellScreen targetScreen

    readonly property int barHeight: 30
    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === targetScreen.name
    readonly property bool open: ShellState.launcherOpen && focusedScreen

    screen: targetScreen
    anchors.top: true
    margins.top: barHeight
    // Room for the panel at its largest; only the panel takes input
    implicitWidth: launcher.implicitWidth + 40
    implicitHeight: launcher.maxRows * launcher.rowHeight + 120
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "launcher"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: panel
    }

    // Clicking anywhere else closes it, armed late so the opening key press does not clear it
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

    Rectangle {
        id: panel

        anchors.horizontalCenter: parent.horizontalCenter
        y: 8
        width: window.open ? launcher.implicitWidth + 20 : launcher.implicitWidth * 0.6
        height: window.open ? launcher.implicitHeight + 12 : 0
        radius: 22
        color: Theme.background
        border.color: Theme.border
        border.width: window.open || height > 2 ? 1 : 0
        clip: true
        visible: height > 0

        Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

        LauncherContent {
            id: launcher
            x: 10
            y: 4
            width: implicitWidth
            height: implicitHeight
            active: window.open
            opacity: window.open ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: window.open ? 260 : 120; easing.type: Easing.InOutQuad }
            }
            onCloseRequested: ShellState.launcherOpen = false
        }
    }
}
