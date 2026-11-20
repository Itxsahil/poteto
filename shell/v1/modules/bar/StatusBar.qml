import QtQuick
import Quickshell
import qs.components
import qs.config
import qs.services

// The status pill (the playing track and the date, opening into the media panel on hover) and
// the recording pill beside it, top right, hanging from the top edge like the island. They live
// in the island's window (modules/island/Island.qml), which draws their backgrounds as part of the
// shell's one surface (components/Surface.qml); the pills themselves are transparent.
Item {
    id: root

    required property ShellScreen targetScreen
    // Hidden while the workspace is fullscreen, like the rest of the idle surface
    property bool suppressed: false

    // Clear of the frame's rounded corner and its bevel, so the pill hangs on its own
    readonly property int gapRight: Tokens.frameWidth + Tokens.radius.screen + Tokens.radius.flare + 8
    readonly property alias pill: pill
    readonly property alias recPill: recPill
    // The pills that take input (the island's window masks everything else)
    readonly property bool pillShown: visible && Settings.showMusic

    // the simple bar carries all of this when it is on. The music and date pill can be turned
    // off (Poteto → Music & date); the recording pill stays while recording, for the stop button
    visible: !Layout.bar && (Settings.showMusic || recordingWidget.shown) && !suppressed

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
        // Beside the pill, or where it would be when it is turned off
        anchors.right: Settings.showMusic ? pill.left : parent.right
        // Far enough from the pill that the two stay apart rather than blending
        anchors.rightMargin: !Settings.showMusic ? root.gapRight : recordingWidget.shown ? Tokens.radius.flare * 2 + 8 : 0
        anchors.top: parent.top
        // zero width when idle, so the input mask has no invisible strip beside the pill
        width: recordingWidget.shown ? recordingWidget.implicitWidth + 24 : 0
        height: Layout.pillHeight
        radius: height / 2
        // Drawn by the surface behind it
        color: "transparent"
        opacity: recordingWidget.shown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { Anim {} }

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
        visible: Settings.showMusic

        anchors.right: parent.right
        anchors.rightMargin: root.gapRight
        anchors.top: parent.top
        width: showMedia ? media.implicitWidth + 32 : content.implicitWidth + 24
        height: showMedia ? media.implicitHeight + 28 : Layout.pillHeight
        radius: showMedia ? Tokens.radius.panel : height / 2
        // Drawn by the surface behind it
        color: "transparent"
        clip: true

        Behavior on width { Anim { duration: Tokens.duration.page } }
        Behavior on height { Anim { duration: Tokens.duration.page } }
        Behavior on radius { Anim {} }

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

        // Held at the top rather than centered, so it stays put while the pill grows into the
        // media panel; the margin is what centers it in the idle pill
        Row {
            id: content
            anchors.top: parent.top
            anchors.topMargin: (Layout.pillHeight - height) / 2
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            opacity: pill.showMedia ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { Anim { duration: Tokens.duration.fade } }

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
            Behavior on opacity { Anim {} }
        }
    }
}
