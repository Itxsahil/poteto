import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.modules.island
import qs.services

// The plain face of the shell: one flat strip across the top, with the same pieces the pills carry
// — workspaces on the left, the time in the middle, the player and status on the right — and none
// of the floating, rounded, hover-to-grow behaviour.
//
// The window is taller than the strip so the media controls have somewhere to drop into; only the
// strip and that panel take input, and only the strip reserves space, so windows tile right under
// it. Clicking the status cluster opens the control center, which the island draws just below.
PanelWindow {
    id: root

    required property ShellScreen targetScreen

    // Hovering the track opens the media controls, as long as something is playing
    property bool mediaHover: false
    readonly property bool showMedia: mediaHover && Mpd.active

    screen: targetScreen
    visible: Layout.bar
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Layout.barHeight + media.height + 16
    // Pinned to the very top, ignoring what anything else reserves. A layer surface that reserves
    // space is itself placed below every *other* surface's reserved strip, and the compositor does
    // not move it afterwards — so a bar that reserved its own height would land under the island's
    // strip whenever the island happened to map first, and stay there. The island reserves the
    // bar's height instead; its own position does not matter, since its pill is placed by margin.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "simplebar"

    mask: Region {
        item: strip

        Region {
            item: root.showMedia ? media : nothing
            intersection: Intersection.Combine
        }
    }

    Item {
        id: nothing
        width: 0
        height: 0
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Timer {
        id: mediaClose
        interval: 250
        onTriggered: root.mediaHover = false
    }

    Rectangle {
        id: strip

        anchors.top: parent.top
        width: parent.width
        height: Layout.barHeight
        color: Theme.islandBg

        // A hairline under the bar instead of a border all the way round
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.islandBorder
        }

        Workspaces {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            screen: root.targetScreen
            // the bar is already the surface, and the active workspace fills its full height
            flat: true
            color: "transparent"
            border.width: 0
        }

        // The time holds the middle of the screen; everything else is pushed to the two ends.
        // It is also the handle for the control center, which drops open right underneath it.
        Rectangle {
            anchors.centerIn: parent
            width: time.implicitWidth + 20
            height: Layout.barHeight - 6
            radius: 6
            color: ShellState.panel ? Theme.controlBg
                : timeMouse.containsMouse ? Theme.wsHoverBg
                : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: time
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "h:mm AP").replace(/\s*[AP]M$/i, "")
                color: Theme.textPrimary
                font.pixelSize: 15
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            MouseArea {
                id: timeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.panel = !ShellState.panel
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            // The stop button has to live somewhere while the status pill is hidden
            RecordingWidget {
                anchors.verticalCenter: parent.verticalCenter
            }

            MpdWidget {
                id: mpd
                anchors.verticalCenter: parent.verticalCenter

                // Same gesture as the status pill: hover the track, get the full controls.
                // Its own clicks (play/pause, next, previous) still work underneath.
                HoverHandler {
                    onHoveredChanged: {
                        if (hovered) {
                            mediaClose.stop();
                            root.mediaHover = true;
                        } else {
                            mediaClose.restart();
                        }
                    }
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: mpd.shown
                width: 1
                height: 14
                color: Theme.controlBg
            }

            // Everything from here right opens the control center on click
            Row {
                id: statusCluster
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                IdleContent {
                    anchors.verticalCenter: parent.verticalCenter
                    date: clock.date
                    showClock: false
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 14
                    color: Theme.controlBg
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

        // Only over the status cluster: the track keeps its own buttons
        MouseArea {
            anchors.fill: statusCluster
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellState.panel = !ShellState.panel
        }
    }

    Shadow {
        target: media
    }

    // The media controls, dropped under the track rather than grown out of a pill
    Rectangle {
        id: media

        anchors.top: strip.bottom
        anchors.topMargin: 8
        anchors.right: strip.right
        anchors.rightMargin: 12
        width: panel.implicitWidth + 32
        height: panel.implicitHeight + 28
        radius: 26
        color: Theme.islandBg
        border.color: Theme.islandBorder
        border.width: 1
        opacity: root.showMedia ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    mediaClose.stop();
                else
                    mediaClose.restart();
            }
        }

        MediaPanel {
            id: panel
            anchors.centerIn: parent
            width: implicitWidth
            height: implicitHeight
        }
    }
}
