import QtQuick
import qs.config

// A round icon button: a quick toggle at the top of the control center, a session or transport
// button at the bottom, the header buttons of a page
Rectangle {
    id: button

    property string glyph
    property int glyphSize: 15
    property bool on: false
    // No background until hovered, for the skip buttons beside play/pause
    property bool flat: false
    property color onColor: Theme.accent
    property color onGlyph: Theme.onAccent
    readonly property alias hovered: mouse.containsMouse
    signal clicked()
    // Right click
    signal secondaryClicked()

    implicitWidth: 42
    implicitHeight: 42
    radius: width / 2
    color: on ? (mouse.containsMouse ? Qt.lighter(onColor, 1.12) : onColor)
        : flat ? (mouse.containsMouse ? Theme.tile : "transparent")
        : mouse.containsMouse ? Theme.tileHover : Theme.tile
    scale: mouse.pressed ? 0.92 : 1
    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on scale { NumberAnimation { duration: 90 } }

    Text {
        anchors.centerIn: parent
        text: button.glyph
        color: button.on ? button.onGlyph : Theme.text
        font.pixelSize: button.glyphSize
        font.family: Theme.monoFamily
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => event.button === Qt.RightButton ? button.secondaryClicked() : button.clicked()
    }
}
