import QtQuick
import qs.config
import qs.components

// The time and date, one wide tile; a click opens the calendar page
Tile {
    id: root

    property date date: new Date()

    signal openRequested()

    color: mouse.containsMouse ? Theme.tileHover : Theme.tileBg
    Behavior on color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -root.padding
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.openRequested()
    }

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: -4
        spacing: 6

        Text {
            id: time
            text: Qt.formatDateTime(root.date, "h:mm AP").replace(/\s*[AP]M$/i, "")
            color: Theme.textPrimary
            font.pixelSize: 34
            font.weight: Font.Bold
            font.family: Theme.fontFamily
        }

        Column {
            anchors.verticalCenter: time.verticalCenter
            anchors.verticalCenterOffset: 2
            spacing: -2

            Text {
                text: Qt.formatDateTime(root.date, "AP")
                color: Theme.textPrimary
                font.pixelSize: 12
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }

            Text {
                text: Qt.formatDateTime(root.date, "ss")
                color: Theme.textSecondary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        spacing: 6

        Text {
            text: Qt.formatDateTime(root.date, "dddd")
            color: Theme.accent
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Text {
            text: Qt.formatDateTime(root.date, "d MMMM yyyy")
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: "›"
        color: Theme.textSecondary
        font.pixelSize: 22
        font.family: Theme.fontFamily
    }
}
