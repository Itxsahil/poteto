import QtQuick
import qs.config
import qs.components

Tile {
    id: root

    property date date: new Date()

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: 6

        Text {
            id: time
            text: Qt.formatDateTime(root.date, "h:mm AP").replace(/\s*[AP]M$/i, "")
            color: Theme.textPrimary
            font.pixelSize: 38
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
                font.pixelSize: 13
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }

            Text {
                text: Qt.formatDateTime(root.date, "ss")
                color: Theme.textSecondary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }
        }
    }

    Column {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        spacing: 1

        Text {
            text: Qt.formatDateTime(root.date, "dddd")
            color: Theme.accent
            font.pixelSize: 13
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
}
