import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.config
import qs.components
import qs.services

PanelWindow {
    id: root

    required property ShellScreen targetScreen
    readonly property bool focusedScreen: Hyprland.focusedMonitor?.name === targetScreen.name
    readonly property bool hasPopups: Notifications.popups.length > 0

    // Padding around the card column so each card's shadow is not cut off at the window edge.
    // The window moves up and grows by the same amount, so the cards stay where they were.
    readonly property int shadowRoom: 24

    screen: targetScreen
    visible: focusedScreen && (hasPopups || stack.count > 0)
    color: "transparent"
    anchors.top: true
    margins.top: 56 - shadowRoom
    implicitWidth: 380 + shadowRoom * 2
    implicitHeight: Math.max(1, stack.contentHeight + shadowRoom * 2)
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notifications"

    mask: Region {
        item: stack.contentItem
    }

    ListView {
        id: stack
        anchors.fill: parent
        anchors.topMargin: root.shadowRoom
        anchors.leftMargin: root.shadowRoom
        anchors.rightMargin: root.shadowRoom
        spacing: 8
        interactive: false
        model: Notifications.popups

        add: Transition {
            ParallelAnimation {
                Anim { property: "opacity"; from: 0; to: 1 }
                Anim { property: "y"; from: -40; duration: Tokens.duration.page; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
            }
        }
        remove: Transition {
            Anim { property: "opacity"; to: 0 }
        }
        displaced: Transition {
            Anim { property: "y"; duration: Tokens.duration.page }
        }

        // The card is wrapped so the shadow can sit behind it: inside the card it would be drawn
        // over its own background instead.
        delegate: Item {
            id: row

            required property var modelData

            width: ListView.view.width
            height: card.implicitHeight

            Shadow {
                target: card
            }

            NotificationCard {
                id: card
                width: row.width
                notification: row.modelData
                popup: true
                onTimedOut: Notifications.hidePopup(row.modelData)
            }
        }
    }
}
