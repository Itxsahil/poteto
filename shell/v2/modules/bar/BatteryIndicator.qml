import QtQuick
import qs.config
import qs.services

// The battery as the pill's neighbour and the bar show it: an icon for the level (with a bolt
// while plugged in, full or not), in the accent while plugged in, amber when low, red when
// critical.
Row {
    id: root

    readonly property color tint: Battery.pluggedIn ? Theme.accent
        : Battery.critical ? Theme.danger
        : Battery.low ? Theme.boost
        : Theme.text
    // The level in tenths; plugged in (charging, full, or held back) it carries a bolt
    readonly property int step: Math.max(0, Math.min(10, Math.round(Battery.percent / 10)))
    readonly property string glyph: Battery.pluggedIn
        ? ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"][step]
        : ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][step]

    spacing: 5

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        color: root.tint
        font.pixelSize: 15
        font.family: Theme.monoFamily
        Behavior on color { ColorAnimation { duration: 200 } }
    }
}
