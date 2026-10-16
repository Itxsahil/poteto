import QtQuick
import qs.config

// The time as both layouts show it: 12-hour, without AM/PM.
Text {
    property date date: new Date()

    text: Qt.formatDateTime(date, "h:mm AP").replace(/\s*[AP]M$/i, "")
    color: Theme.text
    font.pixelSize: 15
    font.weight: Font.DemiBold
    font.family: Theme.fontFamily
}
