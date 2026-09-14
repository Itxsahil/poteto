import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

PanelWindow {
    id: root

    required property ShellScreen targetScreen

    screen: targetScreen
    anchors.top: true
    anchors.right: true
    margins.top: 8
    margins.right: 12
    implicitWidth: pill.width
    implicitHeight: pill.height
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "statusbar"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    component Divider: Rectangle {
        width: 1
        height: 16
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.controlBg
    }

    Rectangle {
        id: pill
        width: content.implicitWidth + 24
        height: 36
        radius: height / 2
        color: Theme.islandBg
        border.color: Theme.islandBorder
        border.width: 1

        Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

        Row {
            id: content
            anchors.centerIn: parent
            spacing: 10

            MpdWidget {
                id: mpd
                anchors.verticalCenter: parent.verticalCenter
            }

            Divider {
                visible: mpd.shown
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "ddd d MMM")
                color: Theme.textPrimary
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }
        }
    }
}
