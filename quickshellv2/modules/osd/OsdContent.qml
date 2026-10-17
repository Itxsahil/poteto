import QtQuick
import qs.config
import qs.services

// What the OSD shows: an icon, a level bar and the value, "󰃠 ━━━━━━━━──── 72%". No surface of its
// own; the pill grows around it, and the bar puts it where the time is.
Item {
    id: root

    readonly property real level: Osd.kind === "brightness" ? Brightness.percent / 100 : 0
    readonly property string glyph: Osd.kind === "brightness" ? "󰃠" : ""

    implicitWidth: 220
    implicitHeight: 22

    Text {
        id: icon
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        horizontalAlignment: Text.AlignHCenter
        text: root.glyph
        color: Theme.text
        font.pixelSize: 15
        font.family: Theme.monoFamily
    }

    Text {
        id: value
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.level * 100) + "%"
        color: Theme.text
        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.family: Theme.monoFamily
    }

    Rectangle {
        anchors.left: icon.right
        anchors.leftMargin: 10
        anchors.right: value.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: Theme.control

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, Math.min(1, root.level))
            radius: parent.radius
            color: Theme.text
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }
}
