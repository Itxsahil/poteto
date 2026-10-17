import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.modules.osd
import qs.modules.recorder

// The floating layout: the time in a rounded pill at the top center of the screen. The same pill
// grows into whatever is opened (Views.qml: the launcher, the control center, the pickers, the
// password prompt) and shrinks back when it closes.
PanelWindow {
    id: window

    required property ShellScreen targetScreen

    // Gap between the pill and the top of the screen
    readonly property int gapTop: 8
    readonly property int pillHeight: 30

    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === targetScreen.name
    // The view this pill shows: whatever is open, on the focused screen only
    readonly property string current: !focusedScreen ? ""
        : ShellState.view !== "" ? ShellState.view
        : ShellState.controlCenterOpen ? "controlcenter"
        // A notification takes the pill only when nothing else has it, and never the keyboard
        : Notifications.current ? "notification"
        : ""
    readonly property bool expanded: views.item !== null
    // A change from outside, e.g. the brightness keys: the pill widens into a level bar for a
    // moment. Only on the focused screen, and never over something that is open.
    readonly property bool showOsd: Osd.shown && focusedScreen && !expanded
    // Opened from the keyboard, as opposed to a hover peek: takes the keyboard, closes on click-away
    readonly property bool pinned: ShellState.view !== "" && focusedScreen

    screen: targetScreen
    anchors.top: true
    // Room for the pill at its largest. Only the pill itself takes input, and only its resting
    // height is reserved, so windows never move when it grows.
    implicitWidth: views.maxWidth + 40
    implicitHeight: gapTop + views.maxHeight + 40
    exclusiveZone: gapTop + pillHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "pill"
    WlrLayershell.keyboardFocus: pinned ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // The pill, and the battery beside it when it shows
    mask: Region {
        item: pill

        Region {
            item: batteryCapsule.visible ? batteryCapsule : null
        }

        Region {
            item: workspacesCapsule.visible ? workspacesCapsule : null
        }

        Region {
            item: wifiCapsule.visible ? wifiCapsule : null
        }
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

    // A notification arriving: the pill gives a quick squash-and-pop, and a ring in the accent
    // ripples out of it, before it grows into the notification
    Connections {
        target: Notifications
        function onArrived() {
            // Only from the resting pill: over the control center or a view it would just be noise
            if (window.focusedScreen && ShellState.view === "" && !ShellState.controlCenterOpen) {
                // From the pill as it is now, not as it grows
                ring.width = pill.width;
                ring.height = pill.height;
                ring.radius = pill.radius;
                ripple.restart();
                pop.restart();
            }
        }
    }

    Rectangle {
        id: ring
        anchors.centerIn: pill
        color: "transparent"
        border.width: 2
        border.color: Theme.accent
        opacity: 0
        visible: opacity > 0

        ParallelAnimation {
            id: ripple
            NumberAnimation { target: ring; property: "scale"; from: 1; to: 1.35; duration: 700; easing.type: Easing.OutCubic }
            NumberAnimation { target: ring; property: "opacity"; from: 0.9; to: 0; duration: 700; easing.type: Easing.OutCubic }
        }
    }

    SequentialAnimation {
        id: pop
        NumberAnimation { target: pill; property: "scale"; to: 0.9; duration: 90; easing.type: Easing.OutQuad }
        NumberAnimation { target: pill; property: "scale"; to: 1.06; duration: 160; easing.type: Easing.OutQuad }
        NumberAnimation { target: pill; property: "scale"; to: 1; duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2 }
    }

    // The workspaces, in their own capsule to the left of the pill, the way the battery sits on
    // its right. Out of the way while the pill has grown into something.
    Rectangle {
        id: workspacesCapsule

        readonly property bool shown: Config.showWorkspaces && !window.expanded

        anchors.right: pill.left
        anchors.rightMargin: 8
        y: window.gapTop
        width: workspaces.implicitWidth + 12
        height: window.pillHeight
        radius: height / 2
        color: Theme.background
        border.color: Theme.border
        border.width: 1
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.85
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Workspaces {
            id: workspaces
            anchors.centerIn: parent
            height: parent.height
            screen: window.targetScreen
            slotWidth: 24
        }
    }

    // The battery, in its own small capsule to the right of the pill. It steps aside while the
    // pill has grown into something.
    Rectangle {
        id: batteryCapsule

        readonly property bool shown: Config.showBattery && Battery.present && !window.expanded

        anchors.left: pill.right
        anchors.leftMargin: 8
        y: window.gapTop
        width: battery.implicitWidth + 24
        height: window.pillHeight
        radius: height / 2
        color: Theme.background
        border.color: Theme.border
        border.width: 1
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.85
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        BatteryIndicator {
            id: battery
            anchors.centerIn: parent
        }
    }

    // Wi-Fi, in its own capsule right of the battery (or of the pill, when the battery is hidden).
    // Click for the Wi-Fi menu.
    Rectangle {
        id: wifiCapsule

        readonly property bool shown: Config.showWifi && !window.expanded

        anchors.left: batteryCapsule.shown ? batteryCapsule.right : pill.right
        anchors.leftMargin: 8
        y: window.gapTop
        width: wifiIndicator.implicitWidth + 24
        height: window.pillHeight
        radius: height / 2
        color: Theme.background
        border.color: Theme.border
        border.width: 1
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.85
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: ShellState.openPage("wifi")
        }

        WifiIndicator {
            id: wifiIndicator
            anchors.centerIn: parent
        }
    }

    Rectangle {
        id: pill

        anchors.horizontalCenter: parent.horizontalCenter
        y: window.gapTop
        width: window.expanded ? views.wantedWidth
            : window.showOsd ? osd.implicitWidth + 28
            : idle.implicitWidth + 80
        height: window.expanded ? views.wantedHeight : window.pillHeight
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
            // Not while it shows a notification: there, hovering is for reading it and reaching
            // its buttons (and holds its timer), not for opening the control center over it
            onHoveredChanged: {
                if (!hovered)
                    ShellState.hoverExit();
                else if (window.current !== "notification")
                    ShellState.hoverEnter();
            }
        }

        // At rest: the time, led by a recording in progress (red dot, time so far, stop)
        Row {
            id: idle
            anchors.centerIn: parent
            spacing: recording.shown ? 12 : 0
            opacity: window.expanded || window.showOsd ? 0 : 1
            scale: window.expanded || window.showOsd ? 0.8 : 1
            Behavior on opacity { NumberAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            RecordingIndicator {
                id: recording
                anchors.verticalCenter: parent.verticalCenter
            }

            Clock {
                id: time
                anchors.verticalCenter: parent.verticalCenter
                date: clock.date
            }
        }

        OsdContent {
            id: osd
            anchors.centerIn: parent
            opacity: window.showOsd ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: window.showOsd ? 220 : 120 } }
        }

        Views {
            id: views
            anchors.fill: parent
            current: window.current
            pinned: window.pinned
        }
    }
}
