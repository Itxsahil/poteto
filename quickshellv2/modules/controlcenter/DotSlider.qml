import QtQuick
import qs.config

// A slider drawn as a row of dots, lit up to the value: "Sound ••••••••······ 62".
// Drag along it, click anywhere on it, or scroll over it. Dragging and clicking cover 0–100; with
// a maxValue past 100 only the wheel goes further (so a click never boosts by accident), and the
// part past 100 laps over the full row in Theme.boost.
Rectangle {
    id: root

    property string label
    // 0–100
    property real value: 0
    property real maxValue: 100
    // Off for now (muted): the dots fade and the number gives way to this
    property bool dimmed: false
    property string dimmedText: "Off"
    // The label can be clicked (e.g. to mute); it shows a hover state then
    property bool labelClickable: false

    // A small round button at the right end (e.g. the device in use, opening the Audio page);
    // "" for none
    property string actionGlyph: ""

    signal moved(real value)
    signal labelClicked()
    signal actionClicked()

    readonly property real dotSize: 4.5
    readonly property real dotGap: 8
    readonly property int dotCount: Math.max(1, Math.floor((dots.width + dotGap) / (dotSize + dotGap)))
    readonly property int lit: Math.round(Math.min(100, value) / 100 * dotCount)
    readonly property int boosted: Math.round(Math.max(0, Math.min(100, value - 100)) / 100 * dotCount)

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
                color: index < root.boosted ? Qt.alpha(Theme.boost, root.dimmed ? 0.35 : 1)
                    : index < root.lit ? Qt.alpha(Theme.text, root.dimmed ? 0.35 : 1)
                    : Qt.alpha(Theme.text, 0.16)
                Behavior on color { ColorAnimation { duration: 90 } }
            }
        }
    }

    Text {
        id: number
        anchors.right: action.visible ? action.left : parent.right
        anchors.rightMargin: action.visible ? 8 : 14
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        horizontalAlignment: Text.AlignRight
        text: root.dimmed ? root.dimmedText : Math.round(root.value)
        color: root.dimmed ? Theme.textDim : root.boosted > 0 ? Theme.boost : Theme.text
        font.pixelSize: 13
        font.family: Theme.monoFamily
    }

    // Above the slider's own mouse area (declared after it), so a click here is not a jump
    MouseArea {
        anchors.fill: parent
        anchors.rightMargin: action.visible ? action.width + 6 : 0
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFromX(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.setFromX(mouse.x); }
    }

    // Above the slider's own mouse area, so a click on the label is not a jump to 0
    MouseArea {
        anchors.fill: name
        anchors.margins: -6
        enabled: root.labelClickable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.labelClicked()
    }

    WheelHandler {
        onWheel: event => root.moved(Math.max(0, Math.min(root.maxValue, root.value + (event.angleDelta.y > 0 ? 5 : -5))))
    }

    Rectangle {
        id: action
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        visible: root.actionGlyph !== ""
        width: 26
        height: 26
        radius: 13
        color: actionMouse.containsMouse ? Theme.tileHover : Qt.alpha(Theme.text, 0.07)
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            anchors.centerIn: parent
            text: root.actionGlyph
            color: Theme.text
            font.pixelSize: 13
            font.family: Theme.monoFamily
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.actionClicked()
        }
    }
}
