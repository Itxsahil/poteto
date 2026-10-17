import QtQuick
import qs.config

// The time as both layouts show it: 12-hour, without AM/PM. A small moon leads it while quiet
// mode (Config.quiet) holds notifications back.
Row {
    id: root

    property date date: new Date()

    spacing: 6

    Text {
        anchors.verticalCenter: parent.verticalCenter
        visible: Config.quiet
        text: "󰽥"
        color: Theme.textDim
        font.pixelSize: 13
        font.family: Theme.monoFamily
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.date, "h:mm AP").replace(/\s*[AP]M$/i, "")
        color: Theme.text
        font.pixelSize: 15
        font.weight: Font.DemiBold
        font.family: Theme.fontFamily
    }
}
