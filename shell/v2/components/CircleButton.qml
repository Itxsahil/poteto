import QtQuick
import qs.config

// A round icon button that fills with the accent while what it controls is on, and can spin
// (the camera view's controls)
Rectangle {
    id: root

    property string glyph
    property int glyphSize: 20
    property bool spinning: false
    // Filled with the accent color while the thing it controls is on
    property bool active: false
    signal clicked()

    width: 34
    height: 34
    radius: 17
    color: active ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent)
        : (mouse.containsMouse ? Theme.control : Theme.tile)
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: glyphText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        text: root.glyph
        color: root.active ? Theme.accentText : Theme.text
        font.pixelSize: root.glyphSize
        font.family: Theme.fontFamily

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: root.spinning
            onRunningChanged: if (!running) glyphText.rotation = 0
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
