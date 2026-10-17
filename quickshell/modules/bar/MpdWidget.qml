import QtQuick
import qs.config
import qs.services

Item {
    id: root

    readonly property bool shown: Mpd.active

    implicitWidth: shown ? row.implicitWidth : 0
    implicitHeight: 28
    visible: shown

    Binding {
        target: Cava
        property: "enabled"
        value: root.shown && Mpd.playing
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Item {
            id: visualizer
            // Room for the bars while playing; paused, only as wide as the play glyph, so it does
            // not sit in an empty stretch of pill
            width: Mpd.playing ? Cava.barCount * 3 + (Cava.barCount - 1) * 2 : 12
            height: 18
            clip: true
            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            anchors.verticalCenter: parent.verticalCenter

            // Bars while playing; paused, only the play glyph (what a click does), not a row of
            // dim dots under it
            Row {
                anchors.bottom: parent.bottom
                spacing: 2
                opacity: Mpd.playing ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Repeater {
                    model: Cava.barCount

                    Rectangle {
                        required property int index
                        anchors.bottom: parent.bottom
                        width: 3
                        height: Math.max(3, visualizer.height * (Cava.bars[index] ?? 0))
                        radius: 1.5
                        color: Theme.accent
                        Behavior on height { NumberAnimation { duration: 70 } }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                opacity: Mpd.playing ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
                text: "󰐊"
                color: Theme.textPrimary
                font.pixelSize: 15
                font.family: "JetBrainsMono Nerd Font"
            }
        }

        Text {
            id: song
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(240, implicitWidth)
            elide: Text.ElideRight
            textFormat: Text.StyledText
            text: {
                const esc = s => String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                const dim = Qt.alpha(Theme.textPrimary, 0.55);
                const artist = Mpd.artist ? `<font color="${dim}"> · ${esc(Mpd.artist)}</font>` : "";
                return esc(Mpd.title) + artist;
            }
            // Paused: dimmed, but not to the theme's dim text, which some themes (Solitude) make
            // too faint to read on the pill
            color: Mpd.playing ? Theme.textPrimary : Qt.alpha(Theme.textPrimary, 0.6)
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }
    }

    MouseArea {
        anchors.fill: parent
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
