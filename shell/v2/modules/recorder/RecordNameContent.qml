import QtQuick
import qs.config
import qs.components
import qs.services

// Asked when a recording stops: what to call it. Enter saves under that name, an empty name or
// Esc keeps the default (the date and time). The pill grows into it.
Item {
    id: root

    property bool active: false
    readonly property bool processing: Recorder.pending === null && Recorder.finishing

    signal closeRequested()

    implicitWidth: 460
    implicitHeight: content.implicitHeight

    function save() {
        Recorder.submitName(input.text);
        closeRequested();
    }

    function keepDefault() {
        Recorder.submitName("");
        closeRequested();
    }

    onActiveChanged: {
        if (active) {
            input.text = Recorder.defaultName;
            input.selectAll();
            input.forceActiveFocus();
        } else if (Recorder.chosenName === null && Recorder.finishing) {
            Recorder.submitName("");
        }
    }

    Column {
        id: content
        width: parent.width
        spacing: 12

        Item {
            width: parent.width
            height: 40

            Rectangle {
                id: badge
                width: 40
                height: 40
                radius: 20
                anchors.left: parent.left
                color: Theme.danger

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.background
                }
            }

            Column {
                anchors.left: badge.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: "Name this recording"
                    color: Theme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Row {
                    spacing: 6

                    Spinner {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 11
                        height: 11
                        visible: root.processing
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !root.processing
                        text: "󰄬"
                        color: Theme.accentText
                        font.pixelSize: 12
                        font.family: Theme.monoFamily
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.processing ? "Saving video…" : `Ready  ·  ${Recorder.formatElapsed(Recorder.pending?.length ?? Recorder.elapsed)}`
                        color: Theme.textDim
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 44
            radius: 14
            color: Theme.tile
            border.width: 1
            border.color: input.activeFocus ? Theme.accent : "transparent"

            TextInput {
                id: input
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.right: suffix.left
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                selectionColor: Theme.accent
                selectedTextColor: Theme.accentText
                font.pixelSize: 15
                font.family: Theme.fontFamily
                clip: true
                maximumLength: 120

                Keys.onReturnPressed: root.save()
                Keys.onEnterPressed: root.save()
                Keys.onEscapePressed: root.keepDefault()
            }

            Text {
                id: suffix
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: ".mp4"
                color: Theme.textDim
                font.pixelSize: 14
                font.family: Theme.fontFamily
            }
        }

        Item {
            width: parent.width
            height: 32

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                text: "↵ save   Esc keep date name"
                color: Theme.textDim
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                PillButton {
                    text: "Keep date name"
                    onClicked: root.keepDefault()
                }

                PillButton {
                    text: "Save"
                    primary: true
                    onClicked: root.save()
                }
            }
        }
    }
}
