import QtQuick
import qs.config

Rectangle {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 44
    implicitHeight: 26
    radius: height / 2
    color: checked ? Theme.accent : Theme.controlBg
    Behavior on color { CAnim { duration: Tokens.duration.view } }

    Rectangle {
        width: parent.height - 4
        height: width
        radius: width / 2
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        color: Theme.controlFill
        Behavior on x { Anim {} }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
