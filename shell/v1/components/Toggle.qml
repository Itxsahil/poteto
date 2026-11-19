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
    Behavior on color { ColorAnimation { duration: 180 } }

    Rectangle {
        width: parent.height - 4
        height: width
        radius: width / 2
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        color: Theme.controlFill
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
