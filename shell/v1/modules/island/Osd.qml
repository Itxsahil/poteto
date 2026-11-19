import QtQuick
import qs.config

Item {
    id: root

    property real level: 0
    // Past 100%: the bar stays full and this second lap (0–1) is drawn over it in Theme.boost
    property real boost: 0
    property bool dimmed: false
    property string label: Math.round(level * 100) + "%"
    default property alias icon: iconSlot.data

    implicitWidth: 240
    implicitHeight: 22

    Item {
        id: iconSlot
        width: 18
        height: 18
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        id: label
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        horizontalAlignment: Text.AlignRight
        text: root.label
        color: root.boost > 0 && !root.dimmed ? Theme.boost : Theme.textPrimary
        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.family: Theme.fontFamily
    }

    Rectangle {
        id: bar
        anchors.left: iconSlot.right
        anchors.leftMargin: 10
        anchors.right: label.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        radius: 3
        color: Theme.controlBg

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.min(1, root.level)
            radius: parent.radius
            color: Theme.controlFill
            opacity: root.dimmed ? 0.4 : 1
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, Math.min(1, root.boost))
            visible: root.boost > 0
            radius: parent.radius
            color: Theme.boost
            opacity: root.dimmed ? 0.4 : 1
            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }
    }
}
