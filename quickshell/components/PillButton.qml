import QtQuick
import qs.config

Rectangle {
    id: root

    property string text
    property bool primary: false
    property bool danger: false
    signal clicked()

    height: 32
    width: label.implicitWidth + 28
    radius: 16
    color: primary ? (mouse.containsMouse ? Qt.lighter(Theme.accent, 1.15) : Theme.accent)
        : (mouse.containsMouse ? Theme.controlHover : Theme.controlBg)
    opacity: enabled ? 1 : 0.5
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.danger ? Theme.danger : root.primary ? Theme.onAccent : Theme.textPrimary
        font.pixelSize: 12
        font.weight: Font.DemiBold
        font.family: Theme.fontFamily
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
