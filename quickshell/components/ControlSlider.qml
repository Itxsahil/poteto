import QtQuick
import qs.config

Item {
    id: root

    property real value: 0
    property real minValue: 0
    // Above 1, the bar stays full and the part past 1 laps over it in Theme.boost
    property real maxValue: 1
    readonly property real fill: Math.min(1, value)
    // From the rounded percent: PipeWire floats drift (1.0000001 after a few 5% steps), which
    // would otherwise draw a sliver of boost at exactly 100%
    readonly property real boost: Math.max(0, Math.min(1, Math.round(value * 100) / 100 - 1))
    property bool dimmed: false
    property string label: Math.round(value * 100) + "%"
    readonly property bool pressed: drag.pressed
    default property alias icon: iconSlot.data

    signal moved(real value)
    signal rightClicked()

    implicitWidth: 300
    implicitHeight: 48

    // Dragging covers 0–100%; only the wheel goes past it, so a click never boosts by accident
    function setValue(v) {
        moved(Math.min(maxValue, Math.max(minValue, v)));
    }

    function dragTo(fraction) {
        moved(Math.min(1, Math.max(minValue, fraction)));
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
            width: Math.max(track.height, track.width * root.fill)
            radius: track.radius
            color: Theme.controlFill
            opacity: root.dimmed ? 0.45 : 1
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 120 } }
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        // The second lap, past 100%
        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(track.height, track.width * root.boost)
            visible: root.boost > 0
            radius: track.radius
            color: Theme.boost
            opacity: root.dimmed ? 0.45 : 1
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 120 } }
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
            color: root.fill > 0.85 && !root.dimmed ? Theme.controlIconOnFill : Theme.textSecondary
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
                    root.dragTo(mouse.x / width);
            }
            onPositionChanged: mouse => {
                if (pressedButtons & Qt.LeftButton)
                    root.dragTo(mouse.x / width);
            }
        }

        WheelHandler {
            onWheel: event => root.setValue(root.value + event.angleDelta.y / 120 * 0.05)
        }
    }
}
