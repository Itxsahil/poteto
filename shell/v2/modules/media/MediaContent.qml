import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services
import qs.modules.controlcenter

// What MPD is playing, in full (the now-playing row of the control center, or
// qs ipc call media toggle): album art, the track, a live visualizer, a seek bar, transport
// with shuffle and repeat, and MPD's own volume. Space plays or pauses, ←/→ seek, N/P skip,
// Esc closes.
Item {
    id: root

    property bool active: false

    signal closeRequested()

    function timeText(seconds) {
        if (!(seconds > 0))
            return "0:00";
        const s = Math.round(seconds);
        return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    }

    onActiveChanged: {
        if (active)
            keys.forceActiveFocus();
    }

    implicitWidth: 400
    implicitHeight: column.implicitHeight

    Item {
        id: keys
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape)
                root.closeRequested();
            else if (event.key === Qt.Key_Space)
                Mpd.toggle();
            else if (event.key === Qt.Key_Left)
                Mpd.seek(Mpd.elapsed - 5);
            else if (event.key === Qt.Key_Right)
                Mpd.seek(Mpd.elapsed + 5);
            else if (event.key === Qt.Key_N)
                Mpd.next();
            else if (event.key === Qt.Key_P)
                Mpd.previous();
            else
                return;
            event.accepted = true;
        }
    }

    Column {
        id: column
        width: parent.width
        spacing: 14

        // Art, and the track beside it
        Item {
            width: parent.width
            height: art.height

            ClippingRectangle {
                id: art
                width: 112
                height: 112
                radius: 18
                color: Theme.tile

                Image {
                    id: cover
                    anchors.fill: parent
                    source: AlbumArt.source
                    sourceSize.width: 224
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                }

                Text {
                    anchors.centerIn: parent
                    visible: cover.status !== Image.Ready
                    text: "󰝚"
                    color: Theme.textDim
                    font.pixelSize: 40
                    font.family: Theme.monoFamily
                }
            }

            Column {
                anchors.left: art.right
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.verticalCenter: art.verticalCenter
                spacing: 3

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.Wrap
                    text: Mpd.active ? Mpd.title : !Mpd.connected ? "MPD is not running" : "Nothing playing"
                    color: Theme.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    visible: text !== ""
                    text: Mpd.active ? Mpd.artist : ""
                    color: Theme.textDim
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    visible: text !== ""
                    text: Mpd.active ? Mpd.album : ""
                    color: Qt.alpha(Theme.textDim, 0.7)
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }

                // The visualizer, resting low while paused
                Row {
                    id: visualizer
                    topPadding: 8
                    height: 30
                    spacing: 3
                    opacity: Mpd.playing ? 1 : 0.35
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Repeater {
                        model: Cava.barCount

                        Item {
                            required property int index
                            width: 4
                            height: 22

                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: Math.max(3, parent.height * (Cava.bars[parent.index] ?? 0))
                                radius: 2
                                color: Theme.accent
                                Behavior on height { NumberAnimation { duration: 70 } }
                            }
                        }
                    }
                }
            }
        }

        // Seek
        Column {
            width: parent.width
            spacing: 4

            Item {
                id: seek
                width: parent.width
                height: 14

                readonly property real ratio: Mpd.duration > 0 ? Math.min(1, Mpd.elapsed / Mpd.duration) : 0
                readonly property bool engaged: seekMouse.containsMouse || seekMouse.pressed

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: seek.engaged ? 6 : 4
                    radius: height / 2
                    color: Qt.alpha(Theme.text, 0.12)
                    Behavior on height { NumberAnimation { duration: 120 } }

                    Rectangle {
                        width: parent.width * seek.ratio
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }
                }

                Rectangle {
                    x: seek.width * seek.ratio - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: seek.engaged ? 12 : 0
                    height: width
                    radius: width / 2
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 120 } }
                }

                MouseArea {
                    id: seekMouse
                    anchors.fill: parent
                    anchors.margins: -5
                    hoverEnabled: true
                    enabled: Mpd.duration > 0
                    cursorShape: Qt.PointingHandCursor
                    onPressed: mouse => scrub(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed)
                            scrub(mouse.x);
                    }

                    function scrub(x) {
                        Mpd.seek(Math.max(0, Math.min(1, (x - 5) / seek.width)) * Mpd.duration);
                    }
                }
            }

            Item {
                width: parent.width
                height: 14

                Text {
                    anchors.left: parent.left
                    text: root.timeText(Mpd.elapsed)
                    color: Theme.textDim
                    font.pixelSize: 11
                    font.family: Theme.monoFamily
                }

                Text {
                    anchors.right: parent.right
                    text: root.timeText(Mpd.duration)
                    color: Theme.textDim
                    font.pixelSize: 11
                    font.family: Theme.monoFamily
                }
            }
        }

        // Transport: shuffle, previous, play / pause, next, repeat (off → all → one)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14
            enabled: Mpd.connected
            opacity: enabled ? 1 : 0.4

            RoundButton {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 34
                implicitHeight: 34
                flat: !Mpd.random
                on: Mpd.random
                onColor: Qt.alpha(Theme.accent, 0.22)
                onGlyph: Theme.accent
                glyph: "󰒝"
                glyphSize: 15
                onClicked: Mpd.toggleRandom()
            }

            RoundButton {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 40
                implicitHeight: 40
                flat: true
                glyph: "󰒮"
                glyphSize: 18
                onClicked: Mpd.previous()
            }

            RoundButton {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 54
                implicitHeight: 54
                on: true
                glyph: Mpd.playing ? "󰏤" : "󰐊"
                glyphSize: 22
                onClicked: Mpd.toggle()
            }

            RoundButton {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 40
                implicitHeight: 40
                flat: true
                glyph: "󰒭"
                glyphSize: 18
                onClicked: Mpd.next()
            }

            RoundButton {
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 34
                implicitHeight: 34
                flat: !Mpd.repeat
                on: Mpd.repeat
                onColor: Qt.alpha(Theme.accent, 0.22)
                onGlyph: Theme.accent
                glyph: Mpd.repeat && Mpd.single ? "󰑘" : "󰑖"
                glyphSize: 15
                onClicked: Mpd.cycleRepeat()
            }
        }

        // MPD's own volume, separate from the system's
        DotSlider {
            width: parent.width
            visible: Mpd.volume >= 0
            label: "Music"
            value: Mpd.volume
            onMoved: v => Mpd.setVolume(v)
        }
    }
}
