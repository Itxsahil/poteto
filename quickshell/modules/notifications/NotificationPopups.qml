import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

PanelWindow {
    id: root

    required property ShellScreen targetScreen
    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === targetScreen.name
    readonly property bool hasPopups: Notifications.popups.length > 0

    screen: targetScreen
    visible: focusedScreen && (hasPopups || stack.count > 0)
    color: "transparent"
    anchors.top: true
    margins.top: 56
    implicitWidth: 400
    implicitHeight: Math.max(1, stack.contentHeight + 20)
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notifications"

    mask: Region {
        item: stack.contentItem
    }

    ListView {
        id: stack
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8
        interactive: false
        model: Notifications.popups

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220 }
                NumberAnimation { property: "y"; from: -40; duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 180 }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 260; easing.type: Easing.OutCubic }
        }

        delegate: NotificationCard {
            required property var modelData
            width: ListView.view.width
            notification: modelData
            popup: true
            onTimedOut: Notifications.hidePopup(modelData)
        }
    }
}
