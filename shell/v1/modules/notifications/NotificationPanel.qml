pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.components
import qs.components.icons
import qs.services

// Notification popups, growing out of the bottom-right corner of the frame. The panel is a piece
// of the shell's one surface (components/Surface.qml, `edge: 2`), so it joins the bottom and right
// edges with the same curves and shares the one shadow; it lives in the island's window
// (modules/island/Island.qml), which draws its background, and holds the cards.
//
// The newest card sits nearest the corner, older ones stack above; the panel grows to fit them
// and scrolls past 70% of the screen. A card starts compact, opens with its chevron or a drag
// down, goes away on its own after a while (not while the pointer is on it), and can be swiped
// sideways or middle-clicked away. NotificationCard.qml is the card; the history page uses it too.
//
// A header with Do Not Disturb and Clear all shows while the pointer is on the panel, or when two
// or more are stacked, so a single quick popup stays small.
Item {
    id: root

    // Only on the focused screen
    property bool active: false
    // Hangs from the bottom-right corner (read by Surface)
    readonly property int edge: 2
    // Its top-left corner (read by Surface)
    readonly property real radius: Tokens.radius.panel
    readonly property int padding: 10
    readonly property real maxHeight: (parent?.height ?? 0) * 0.7
    readonly property bool showHeader: list.count >= 2 || panelHover.hovered
    readonly property int headerHeight: 34

    width: 380 + padding * 2
    height: active && list.count > 0
        ? Math.min(maxHeight, list.contentHeight + padding * 2 + (showHeader ? headerHeight : 0)) : 0
    x: (parent?.width ?? 0) - Tokens.frameWidth - width
    y: (parent?.height ?? 0) - Tokens.frameWidth - height
    visible: height > 1
    clip: true

    Behavior on height { Anim { duration: Tokens.duration.page } }

    HoverHandler {
        id: panelHover
    }

    // The header: how many, Do Not Disturb, and Clear all
    Item {
        id: header
        x: root.padding + 4
        y: root.padding
        width: root.width - root.padding * 2 - 8
        height: root.headerHeight - 8
        opacity: root.showHeader ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { Anim { duration: Tokens.duration.fade } }

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Notifications"
                color: Theme.textPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            // How many are up
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(height, countText.implicitWidth + 10)
                height: 18
                radius: height / 2
                color: Theme.controlBg

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: list.count
                    color: Theme.textSecondary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Do Not Disturb: filled with the accent while on. Turning it on clears the popups it
            // would have kept away (critical ones stay)
            Rectangle {
                id: dndButton
                anchors.verticalCenter: parent.verticalCenter
                width: dndRow.implicitWidth + 20
                height: 26
                radius: height / 2
                color: Notifications.dnd ? (dndMouse.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent)
                    : dndMouse.containsMouse ? Theme.controlHover : Theme.controlBg
                Behavior on color { CAnim {} }

                Row {
                    id: dndRow
                    anchors.centerIn: parent
                    spacing: 6

                    BellIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 13
                        height: 13
                        muted: Notifications.dnd
                        color: Notifications.dnd ? Theme.onAccent : Theme.textPrimary
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Do not disturb"
                        color: Notifications.dnd ? Theme.onAccent : Theme.textPrimary
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const on = !Notifications.dnd;
                        Notifications.setDnd(on);
                        if (on)
                            Notifications.clearPopups(true);
                    }
                }
            }

            // Every popup off the screen; the history in the control center keeps them
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: clearText.implicitWidth + 20
                height: 26
                radius: height / 2
                color: clearMouse.containsMouse ? Theme.controlHover : Theme.controlBg
                Behavior on color { CAnim {} }

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "Clear all"
                    color: Theme.textPrimary
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.clearPopups(false)
                }
            }
        }
    }

    ListView {
        id: list
        x: root.padding
        y: root.padding + (root.showHeader ? root.headerHeight : 0)
        width: root.width - root.padding * 2
        height: Math.max(0, root.height - root.padding * 2 - (root.showHeader ? root.headerHeight : 0))
        Behavior on y { Anim { duration: Tokens.duration.page } }
        // Newest at the bottom, nearest the corner
        verticalLayoutDirection: ListView.BottomToTop
        spacing: 8
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        model: Notifications.popups

        // In from the right edge
        add: Transition {
            ParallelAnimation {
                Anim { property: "opacity"; from: 0; to: 1 }
                Anim { property: "x"; from: list.width; to: 0; duration: Tokens.duration.page }
            }
        }
        displaced: Transition {
            Anim { property: "y"; duration: Tokens.duration.page }
        }

        delegate: Item {
            id: row

            required property var modelData

            width: ListView.view.width
            height: card.implicitHeight

            // Out by fading and folding its height away, so the others slide over rather than jump
            ListView.onRemove: removeAnim.start()

            SequentialAnimation {
                id: removeAnim
                PropertyAction { target: row; property: "ListView.delayRemove"; value: true }
                ParallelAnimation {
                    Anim { target: row; property: "opacity"; to: 0; duration: Tokens.duration.fade }
                    Anim { target: row; property: "height"; to: 0 }
                }
                PropertyAction { target: row; property: "ListView.delayRemove"; value: false }
            }

            NotificationCard {
                id: card
                width: row.width
                notification: row.modelData
                popup: true
                onTimedOut: Notifications.hidePopup(row.modelData)
                onSwiped: Notifications.hidePopup(row.modelData)
            }
        }
    }
}
