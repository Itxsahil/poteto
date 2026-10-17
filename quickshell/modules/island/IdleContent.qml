import QtQuick
import qs.config
import qs.components.icons
import qs.services
import Quickshell.Services.Pipewire

Row {
    id: root

    property date date: new Date()
    // The bar puts the time in the center of the screen, so its status cluster leaves it out
    property bool showClock: true

    readonly property int wifiSignal: Wifi.active?.signal ?? 0
    // Color only when it needs attention: a weak signal, or none. A good connection is plain text,
    // like the clock beside it
    readonly property color wifiColor: !Wifi.enabled || !Wifi.active ? Theme.signalOff
        : wifiSignal < 35 ? Theme.signalWeak
        : Theme.textPrimary
    // The same for the battery: low, critical or charging get their color, the rest is plain
    readonly property color batteryColor: Battery.charging ? Theme.batteryGood
        : Battery.level <= 0.15 ? Theme.batteryCritical
        : Battery.level <= 0.30 ? Theme.batteryLow
        : Qt.alpha(Theme.textPrimary, 0.85)

    spacing: 12

    // Recording: a red dot that pulses, so it reads as live rather than as a status color
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 8
        radius: 4
        color: Theme.danger
        visible: Recorder.recording || Recorder.finishing

        SequentialAnimation on opacity {
            running: Recorder.recording
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
        }
    }

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
        visible: root.showClock
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
        fillColor: root.batteryColor
        outlineColor: Qt.alpha(Theme.textPrimary, 0.6)
        boltStroke: Theme.islandBg
        charging: Battery.charging
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
    }

    MicIcon {
        anchors.verticalCenter: parent.verticalCenter
        width: 15
        height: 15
        muted: true
        color: Theme.danger
        visible: Pipewire.defaultAudioSource?.audio?.muted ?? false
    }

    // Unread notifications: how many, not just that there are some
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(height, unreadText.implicitWidth + 10)
        height: 16
        radius: height / 2
        color: Theme.accent
        visible: Notifications.unread > 0 && !Notifications.dnd

        Text {
            id: unreadText
            anchors.centerIn: parent
            text: Notifications.unread > 9 ? "9+" : Notifications.unread
            color: Theme.onAccent
            font.pixelSize: 10
            font.weight: Font.Bold
            font.family: Theme.fontFamily
        }
    }
}
