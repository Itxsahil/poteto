import QtQuick
import qs.config

Rectangle {
    id: root

    property string glyph
    property int glyphSize: 20
    property bool spinning: false
    signal clicked()

    width: 34
    height: 34
    radius: 17
    color: mouse.containsMouse ? Theme.controlBg : Theme.tileBg
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: glyphText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        text: root.glyph
        color: Theme.textPrimary
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
