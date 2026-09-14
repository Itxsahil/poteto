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
            width: Cava.barCount * 3 + (Cava.barCount - 1) * 2
            height: 18
            anchors.verticalCenter: parent.verticalCenter

            Row {
                anchors.bottom: parent.bottom
                spacing: 2
                opacity: Mpd.playing ? 1 : 0.35
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
                visible: !Mpd.playing
                text: "󰏤"
                color: Theme.textPrimary
                font.pixelSize: 13
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
                const artist = Mpd.artist ? `<font color="${Theme.textSecondary}"> · ${esc(Mpd.artist)}</font>` : "";
                return esc(Mpd.title) + artist;
            }
            color: Mpd.playing ? Theme.textPrimary : Theme.textSecondary
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
