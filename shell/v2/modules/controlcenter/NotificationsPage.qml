import QtQuick
import qs.config
import qs.services
import qs.modules.notifications

// Every notification still in history, newest first, as a page of the control center (the bell
// in its bottom row, or qs ipc call controlcenter notifications). Click one to run its default
// action, hover it for the cross that dismisses it; Clear all empties the history. Opening the
// page marks everything read, which clears the bell's count.
Item {
    id: root

    property bool active: false
    // Taller than this, the list scrolls
    readonly property int maxListHeight: 420

    signal backRequested()

    onActiveChanged: {
        if (active) {
            keys.forceActiveFocus();
            Notifications.markRead();
        }
    }

    // Arriving while the page is open counts as seen
    Connections {
        target: Notifications
        function onUnreadChanged() {
            // Next tick: marking read changes unread, which is what is being handled here
            if (root.active && Notifications.unread > 0)
                Qt.callLater(Notifications.markRead);
        }
    }

    implicitHeight: column.implicitHeight

    Item {
        id: keys
        Keys.onEscapePressed: root.backRequested()
    }

    Column {
        id: column
        width: parent.width
        spacing: 10

        PageHeader {
            title: "Notifications"
            actionText: Notifications.count > 0 ? "Clear all" : ""
            showSwitch: false
            onBackClicked: root.backRequested()
            onActionClicked: Notifications.clearAll()
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }

        Column {
            width: parent.width
            visible: Notifications.count === 0
            topPadding: 18
            bottomPadding: 18
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰂜"
                color: Theme.textDim
                font.pixelSize: 26
                font.family: Theme.monoFamily
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No notifications"
                color: Theme.textDim
                font.pixelSize: 13
                font.family: Theme.fontFamily
            }
        }

        Flickable {
            id: list
            width: parent.width
            visible: Notifications.count > 0
            height: Math.min(cards.implicitHeight, root.maxListHeight)
            contentHeight: cards.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: cards
                width: list.width
                spacing: 6

                Repeater {
                    model: Notifications.history

                    Rectangle {
                        id: card

                        required property var modelData

                        width: cards.width
                        height: view.implicitHeight + 24
                        radius: 16
                        color: hover.hovered ? Theme.tileHover : Theme.tile
                        Behavior on color { ColorAnimation { duration: 120 } }

                        HoverHandler {
                            id: hover
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifications.invokeDefault(card.modelData)
                        }

                        NotificationView {
                            id: view
                            x: 12
                            y: 12
                            width: parent.width - 24
                            notification: card.modelData
                            showClose: hover.hovered
                            bodyLines: 2
                        }
                    }
                }
            }
        }
    }
}
