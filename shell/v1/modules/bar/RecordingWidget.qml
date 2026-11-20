import QtQuick
import qs.config
import qs.components
import qs.services

Item {
    id: root

    readonly property bool shown: Recorder.recording || Recorder.finishing

    implicitWidth: shown ? row.implicitWidth : 0
    implicitHeight: 28
    visible: shown

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Rectangle {
            id: dot
            anchors.verticalCenter: parent.verticalCenter
            width: 9
            height: 9
            radius: height / 2
            color: Theme.danger

            SequentialAnimation on opacity {
                running: Recorder.recording
                loops: Animation.Infinite
                onRunningChanged: if (!running) dot.opacity = 1
                NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Recorder.finishing ? "Saving…" : Recorder.formatElapsed(Recorder.elapsed)
            color: Theme.textPrimary
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.family: "JetBrainsMono Nerd Font"
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: 22
            radius: height / 2
            visible: Recorder.recording
            color: stopMouse.containsMouse ? Theme.danger : Theme.controlBg
            Behavior on color { CAnim {} }

            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 1.5
                color: stopMouse.containsMouse ? Theme.islandBg : Theme.danger
            }

            MouseArea {
                id: stopMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Recorder.stop()
            }
        }
    }
}
