import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services

// Bar mode's stand-in for the pill growing: a panel that drops down from under the bar, holding
// whatever is open (Views.qml: the launcher, the control center, the pickers, the password
// prompt).
PanelWindow {
    id: window

    required property ShellScreen targetScreen

    readonly property int barHeight: 30
    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === targetScreen.name
    // The view this panel shows: whatever is open, on the focused screen only
    readonly property string current: !focusedScreen ? ""
        : ShellState.view !== "" ? ShellState.view
        : ShellState.controlCenterOpen ? "controlcenter"
        // A notification takes the pill only when nothing else has it, and never the keyboard
        : Notifications.current ? "notification"
        : ""
    readonly property bool expanded: views.item !== null
    // Opened from the keyboard, as opposed to a hover peek: takes the keyboard, closes on click-away
    readonly property bool pinned: ShellState.view !== "" && focusedScreen

    screen: targetScreen
    anchors.top: true
    margins.top: barHeight
    // Room for the panel at its largest; only the panel takes input
    implicitWidth: views.maxWidth + 40
    implicitHeight: views.maxHeight + 40
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
        property real targetWidth: 0
        property real targetHeight: 0

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
            value: views.wantedWidth
        }
        Binding on targetHeight {
            when: window.expanded
            restoreMode: Binding.RestoreNone
            value: views.wantedHeight
        }

        Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
        Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }

        // Keeps a hover peek open while the pointer is on the panel rather than the clock
        HoverHandler {
            // Not while it shows a notification: there, hovering is for reading it and reaching
            // its buttons (and holds its timer), not for opening the control center over it
            onHoveredChanged: {
                if (!hovered)
                    ShellState.hoverExit();
                else if (window.current !== "notification")
                    ShellState.hoverEnter();
            }
        }

        Views {
            id: views
            anchors.fill: parent
            current: window.current
            pinned: window.pinned
        }
    }
}
