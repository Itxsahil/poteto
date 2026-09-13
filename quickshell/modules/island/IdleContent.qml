import QtQuick
import qs.config
import qs.components.icons
import qs.services

Row {
    id: root

    property date date: new Date()

    readonly property int wifiSignal: Wifi.active?.signal ?? 0
    readonly property color wifiColor: !Wifi.enabled || !Wifi.active ? Theme.signalOff
        : wifiSignal >= 60 ? Theme.signalStrong
        : wifiSignal >= 35 ? Theme.signalMedium
        : Theme.signalWeak

    spacing: 12

    WifiIcon {
        anchors.verticalCenter: parent.verticalCenter
        width: 17
        height: 13
        strength: root.wifiSignal
        connected: Wifi.enabled && Wifi.active !== null
        color: root.wifiColor
        dimColor: Qt.rgba(root.wifiColor.r, root.wifiColor.g, root.wifiColor.b, 0.3)
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(root.date, "h:mm AP").replace(/\s*[AP]M$/i, "")
        color: Theme.textPrimary
        font.pixelSize: 15
        font.weight: Font.DemiBold
        font.family: Theme.fontFamily
    }

    BatteryIcon {
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 12.7
        visible: Battery.present
        level: Battery.level
        fillColor: Battery.color
        outlineColor: Qt.alpha(Theme.textPrimary, 0.6)
        boltStroke: Theme.islandBg
        charging: Battery.charging
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 7
        height: 7
        radius: 3.5
        color: Theme.accent
        visible: Notifications.unread > 0 && !Notifications.dnd
    }
}
