import QtQuick
import qs.config
import qs.components
import qs.components.icons
import qs.services
import qs.modules.notifications

Item {
    id: root

    signal backRequested()

    function reset() {
        list.positionViewAtBeginning();
    }

    Item {
        id: header
        width: parent.width
        height: 40

        CircleButton {
            id: backBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            glyph: "‹"
            glyphSize: 26
            onClicked: root.backRequested()
        }

        Column {
            anchors.left: backBtn.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "Notifications"
                color: Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }

            Text {
                text: Notifications.dnd ? "Do Not Disturb is on"
                    : Notifications.count === 1 ? "1 notification"
                    : `${Notifications.count} notifications`
                color: Notifications.dnd ? Theme.accent : Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            PillButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: Notifications.count > 0
                text: "Clear all"
                danger: true
                onClicked: Notifications.clearAll()
            }

            Toggle {
                anchors.verticalCenter: parent.verticalCenter
                checked: Notifications.dnd
                onToggled: on => Notifications.dnd = on
            }
        }
    }

    Column {
        anchors.centerIn: list
        spacing: 10
        visible: Notifications.count === 0

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56
            height: 56
            radius: 28
            color: Theme.tileBg

            BellIcon {
                anchors.centerIn: parent
                width: 26
                height: 26
                color: Theme.textSecondary
                muted: Notifications.dnd
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "You're all caught up"
            color: Theme.textPrimary
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Notifications.dnd ? "Popups are silenced until you turn Do Not Disturb off" : "New notifications will show up here"
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }

    ListView {
        id: list
        anchors.top: header.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 8
        boundsBehavior: Flickable.StopAtBounds
        model: Notifications.history

        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 160 }
        }
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic }
        }

        delegate: NotificationCard {
            required property var modelData
            width: ListView.view.width
            notification: modelData
        }
    }
}
