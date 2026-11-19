import QtQuick
import qs.config
import qs.components

Tile {
    id: root

    property string title
    property string subtitle
    property bool active: false
    default property alias icon: iconSlot.data

    signal toggleRequested()
    signal openRequested()

    padding: 12
    color: tileMouse.containsMouse ? Theme.tileHover : Theme.tileBg
    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        anchors.margins: -root.padding
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openRequested()
    }

    Rectangle {
        id: badge
        width: 40
        height: 40
        radius: 20
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        color: root.active ? (badgeMouse.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent)
            : (badgeMouse.containsMouse ? Theme.controlHover : Theme.controlBg)
        scale: badgeMouse.pressed ? 0.92 : 1
        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on scale { NumberAnimation { duration: 100 } }

        Item {
            id: iconSlot
            anchors.centerIn: parent
            width: 20
            height: 20
        }

        MouseArea {
            id: badgeMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleRequested()
        }
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: 10
        anchors.right: chevron.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.title
            color: Theme.textPrimary
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.subtitle
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }

    Text {
        id: chevron
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "›"
        color: Theme.textSecondary
        font.pixelSize: 22
        font.family: Theme.fontFamily
    }
}
