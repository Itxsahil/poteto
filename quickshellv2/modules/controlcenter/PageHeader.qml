import QtQuick
import qs.config

// The top of a control center page (Wi-Fi, Bluetooth): back, the title, a rescan button that
// spins while scanning, and an on/off switch for the radio.
Item {
    id: root

    property string title
    // The radio is on: shows the rescan button and lights the switch
    property bool checked: false
    property bool scanning: false
    property bool showSwitch: true

    signal backClicked()
    signal rescanClicked()
    signal toggled(bool on)

    width: parent?.width ?? 0
    height: 34

    RoundButton {
        id: back
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 32
        implicitHeight: 32
        flat: true
        glyph: "󰁍"
        glyphSize: 15
        onClicked: root.backClicked()
    }

    Text {
        anchors.left: back.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: Theme.text
        font.pixelSize: 15
        font.weight: Font.DemiBold
        font.family: Theme.fontFamily
    }

    RoundButton {
        id: rescan
        anchors.right: radio.visible ? radio.left : parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 32
        implicitHeight: 32
        flat: true
        visible: root.checked
        glyph: "󰑐"
        glyphSize: 15
        onClicked: root.rescanClicked()

        RotationAnimation on rotation {
            running: root.scanning
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            onStopped: rescan.rotation = 0
        }
    }

    // The radio switch
    Rectangle {
        id: radio
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: root.showSwitch
        width: 42
        height: 24
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.tileHover
        Behavior on color { ColorAnimation { duration: 160 } }

        Rectangle {
            width: 18
            height: 18
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? Theme.accentText : Theme.text
            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled(!root.checked)
        }
    }
}
