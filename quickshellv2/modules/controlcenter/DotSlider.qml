import QtQuick
import qs.config

// A slider drawn as a row of dots, lit up to the value: "Sound ••••••••······ 62".
// Drag along it, click anywhere on it, or scroll over it.
Rectangle {
    id: root

    property string label
    // 0–100
    property real value: 0

    signal moved(real value)

    readonly property real dotSize: 4.5
    readonly property real dotGap: 8
    readonly property int dotCount: Math.max(1, Math.floor((dots.width + dotGap) / (dotSize + dotGap)))
    readonly property int lit: Math.round(value / 100 * dotCount)

    implicitHeight: 34
    radius: height / 2
    color: hover.hovered ? Theme.tileHover : Theme.tile
    Behavior on color { ColorAnimation { duration: 120 } }

    function setFromX(x) {
        const v = Math.max(0, Math.min(100, (x - dots.x) / dots.width * 100));
        moved(Math.round(v));
    }

    HoverHandler {
        id: hover
    }

    Text {
        id: name
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 48
        text: root.label
        color: Theme.text
        font.pixelSize: 12
        font.family: Theme.fontFamily
    }

    Row {
        id: dots
        anchors.left: name.right
        anchors.leftMargin: 6
        anchors.right: number.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.dotGap

        Repeater {
            model: root.dotCount

            Rectangle {
                required property int index
                anchors.verticalCenter: parent.verticalCenter
                width: root.dotSize
                height: root.dotSize
                radius: width / 2
                color: index < root.lit ? Theme.text : Qt.alpha(Theme.text, 0.16)
                Behavior on color { ColorAnimation { duration: 90 } }
            }
        }
    }

    Text {
        id: number
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value)
        color: Theme.text
        font.pixelSize: 13
        font.family: Theme.monoFamily
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFromX(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.setFromX(mouse.x); }
    }

    WheelHandler {
        onWheel: event => root.moved(Math.max(0, Math.min(100, root.value + (event.angleDelta.y > 0 ? 5 : -5))))
    }
}
