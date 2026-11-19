import QtQuick
import qs.config
import qs.services

// Wi-Fi as the pill's neighbour and the bar show it: an icon for the signal of the network in
// use, or for Wi-Fi being off or not connected.
Row {
    id: root

    readonly property var network: Wifi.enabled ? Wifi.active : null
    readonly property int signal: network?.signal ?? 0
    readonly property string glyph: !Wifi.enabled ? "󰤭"
        : !network ? "󰤯"
        : signal >= 75 ? "󰤨"
        : signal >= 50 ? "󰤥"
        : signal >= 25 ? "󰤢"
        : "󰤟"

    spacing: 5

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.glyph
        color: root.network ? Theme.text : Theme.textDim
        font.pixelSize: 15
        font.family: Theme.monoFamily
    }
}
