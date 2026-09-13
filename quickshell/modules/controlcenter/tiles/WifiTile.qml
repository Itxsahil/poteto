import QtQuick
import qs.config
import qs.components.icons
import qs.services

QuickToggleTile {
    title: "Wi-Fi"
    subtitle: !Wifi.enabled ? "Off"
        : Wifi.connectingSsid ? "Connecting…"
        : Wifi.active ? Wifi.active.ssid
        : "Not connected"
    active: Wifi.enabled

    onToggleRequested: Wifi.setEnabled(!Wifi.enabled)

    WifiIcon {
        anchors.centerIn: parent
        width: 20
        height: 16
        strength: Wifi.active?.signal ?? 0
        connected: Wifi.enabled && Wifi.active !== null
        color: Wifi.enabled ? Theme.onAccent : Theme.textPrimary
        dimColor: Wifi.enabled ? Qt.alpha(Theme.onAccent, 0.4) : Theme.wifiInactive
    }
}
