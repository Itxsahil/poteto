import QtQuick
import qs.config
import qs.components
import qs.components.icons
import qs.services

Tile {
    id: root

    BatteryIcon {
        id: icon
        width: 34
        height: 18
        anchors.left: parent.left
        anchors.top: parent.top
        level: Battery.level
        fillColor: Battery.color
        charging: Battery.charging
    }

    Text {
        anchors.right: parent.right
        anchors.verticalCenter: icon.verticalCenter
        visible: Battery.health > 0
        text: Math.round(Battery.health) + "% health"
        color: Theme.textSecondary
        font.pixelSize: 11
        font.family: Theme.fontFamily
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 1

        Text {
            text: Math.round(Battery.level * 100) + "%"
            color: Theme.textPrimary
            font.pixelSize: 30
            font.weight: Font.Bold
            font.family: Theme.fontFamily
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: Battery.statusText
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }
}
