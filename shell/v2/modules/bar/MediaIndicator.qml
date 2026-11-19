import QtQuick
import qs.config
import qs.services

// What MPD is playing, on the bar: a live visualizer and "Title · Artist". Click to play or
// pause, right click for the next track, middle click for the previous one. Takes no room while
// nothing is playing or paused.
Item {
    id: root

    readonly property bool shown: Mpd.active

    implicitWidth: shown ? row.implicitWidth : 0
    implicitHeight: 24
    visible: shown

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // The visualizer, or a pause sign while paused
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: Cava.barCount * 3 + (Cava.barCount - 1) * 2
            height: 16

            Row {
                anchors.bottom: parent.bottom
                spacing: 2
                opacity: Mpd.playing ? 1 : 0.3
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Repeater {
                    model: Cava.barCount

                    Item {
                        required property int index
                        width: 3
                        height: 16

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: Math.max(2, parent.height * (Cava.bars[parent.index] ?? 0))
                            radius: 1.5
                            color: Theme.accent
                            Behavior on height { NumberAnimation { duration: 70 } }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !Mpd.playing
                text: "󰏤"
                color: Theme.text
                font.pixelSize: 12
                font.family: Theme.monoFamily
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(260, implicitWidth)
            elide: Text.ElideRight
            textFormat: Text.StyledText
            text: {
                const esc = s => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                const artist = Mpd.artist ? `<font color="${Theme.textDim}"> · ${esc(Mpd.artist)}</font>` : "";
                return esc(Mpd.title) + artist;
            }
            color: Mpd.playing ? Theme.text : Theme.textDim
            font.pixelSize: 12
            font.weight: Font.Medium
            font.family: Theme.fontFamily
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.RightButton)
                Mpd.next();
            else if (event.button === Qt.MiddleButton)
                Mpd.previous();
            else
                Mpd.toggle();
        }
    }
}
