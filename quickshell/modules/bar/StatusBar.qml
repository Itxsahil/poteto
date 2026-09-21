import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: root

    required property ShellScreen targetScreen

    screen: targetScreen
    anchors.top: true
    anchors.right: true
    margins.top: 8
    margins.right: 12
    // Room for the media panel to grow into, plus the recorder pill beside it.
    // Only the pills themselves take input.
    implicitWidth: 620
    implicitHeight: 240
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "statusbar"

    mask: Region {
        item: pill

        Region {
            item: recPill
            intersection: Intersection.Combine
        }
    }

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

    // Recording indicator and stop button, kept out of the status pill: that one turns into
    // the media panel on hover, which would hide the stop button mid-recording.
    Rectangle {
        id: recPill
        anchors.right: pill.left
        anchors.rightMargin: recordingWidget.shown ? 8 : 0
        anchors.top: parent.top
        // zero width when idle, so the input mask has no invisible strip beside the pill
        width: recordingWidget.shown ? recordingWidget.implicitWidth + 24 : 0
        height: 36
        radius: height / 2
        color: Theme.islandBg
        border.color: Theme.islandBorder
        border.width: 1
        opacity: recordingWidget.shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        RecordingWidget {
            id: recordingWidget
            anchors.centerIn: parent
        }
    }

    Rectangle {
        id: pill

        // Hovering the pill opens the media controls, as long as something is playing
        property bool expanded: false
        readonly property bool showMedia: expanded && Mpd.active

        anchors.right: parent.right
        anchors.top: parent.top
        width: showMedia ? media.implicitWidth + 32 : content.implicitWidth + 24
        height: showMedia ? media.implicitHeight + 28 : 36
        radius: showMedia ? 26 : height / 2
        color: Theme.islandBg
        border.color: Theme.islandBorder
        border.width: 1
        clip: true

        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on radius { NumberAnimation { duration: 250 } }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    closeTimer.stop();
                    pill.expanded = true;
                } else {
                    closeTimer.restart();
                }
            }
        }

        Timer {
            id: closeTimer
            interval: 250
            onTriggered: pill.expanded = false
        }

        Row {
            id: content
            anchors.top: parent.top
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            opacity: pill.showMedia ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

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

        MediaPanel {
            id: media
            anchors.centerIn: parent
            width: implicitWidth
            height: implicitHeight
            opacity: pill.showMedia ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
    }
}
