import QtQuick
import qs.config

Item {
    id: root

    property real value: 0
    property real minValue: 0
    property bool dimmed: false
    property string label: Math.round(value * 100) + "%"
    readonly property bool pressed: drag.pressed
    default property alias icon: iconSlot.data

    signal moved(real value)
    signal rightClicked()

    implicitWidth: 300
    implicitHeight: 48

    function setValue(v) {
        moved(Math.min(1, Math.max(minValue, v)));
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: Theme.controlBg
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(track.height, track.width * root.value)
            radius: track.radius
            color: Theme.controlFill
            opacity: root.dimmed ? 0.45 : 1
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 120 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Item {
            id: iconSlot
            z: 1
            width: 22
            height: 22
            anchors.left: parent.left
            anchors.leftMargin: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.value > 0.85 && !root.dimmed ? Theme.controlIconOnFill : Theme.textSecondary
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor

            onPressed: mouse => {
                if (mouse.button === Qt.RightButton)
                    root.rightClicked();
                else
                    root.setValue(mouse.x / width);
            }
            onPositionChanged: mouse => {
                if (pressedButtons & Qt.LeftButton)
                    root.setValue(mouse.x / width);
            }
        }

        WheelHandler {
            onWheel: event => root.setValue(root.value + event.angleDelta.y / 120 * 0.05)
        }
    }
}
