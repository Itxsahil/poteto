import QtQuick
import qs.config
import qs.components
import qs.services

// Where sound goes and where it comes from: one row per output and per input (a device, or a
// port on one), the one in use checked. A port that is not available (the speakers while
// headphones are plugged in) is listed but greyed out, with why, since picking it would be silent.
Item {
    id: root

    signal backRequested()

    function reset() {
        flick.contentY = 0;
    }

    // A glyph for a device, guessed from its name
    function glyph(entry, input) {
        const name = entry.label.toLowerCase();
        // PipeWire names Bluetooth devices bluez_output.… / bluez_input.…
        if ((entry.node?.name ?? "").startsWith("bluez"))
            return "󰂰";
        if (/head(phone|set)|earphone/.test(name))
            return input ? "󰋎" : "󰋋";
        if (/hdmi|displayport|monitor/.test(name))
            return "󰍹";
        return input ? "󰍬" : "󰓃";
    }

    component SectionLabel: Text {
        leftPadding: 4
        color: Theme.textSecondary
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
        font.family: Theme.fontFamily
    }

    component DeviceRow: Rectangle {
        id: row

        required property var modelData
        property bool input: false
        readonly property bool active: modelData.active
        readonly property bool available: modelData.available

        width: parent.width
        height: 48
        radius: 14
        color: active ? Qt.alpha(Theme.accent, 0.16)
            : mouse.containsMouse && available ? Theme.tileHover
            : Theme.tileBg
        opacity: available ? 1 : 0.55
        Behavior on color { ColorAnimation { duration: 120 } }

        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            height: 32
            radius: 16
            color: row.active ? Theme.accent : Theme.controlBg

            Text {
                anchors.centerIn: parent
                text: root.glyph(row.modelData, row.input)
                color: row.active ? Theme.onAccent : Theme.textPrimary
                font.pixelSize: 16
                font.family: "JetBrainsMono Nerd Font"
            }
        }

        Column {
            anchors.left: badge.right
            anchors.leftMargin: 10
            anchors.right: check.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: row.modelData.label
                color: Theme.textPrimary
                font.pixelSize: 13
                font.weight: row.active ? Font.DemiBold : Font.Normal
                font.family: Theme.fontFamily
            }

            Text {
                width: parent.width
                visible: text !== ""
                elide: Text.ElideRight
                text: row.active ? "In use" : !row.available ? "Unplugged" : ""
                color: row.active ? Theme.accent : Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        Text {
            id: check
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: row.active ? "󰄬" : ""
            color: Theme.accent
            font.pixelSize: 16
            font.family: "JetBrainsMono Nerd Font"
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            enabled: row.available && !row.active
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Audio.select(row.modelData)
        }
    }

    Item {
        id: header
        width: parent.width
        height: 40

        CircleButton {
            id: backBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            glyph: "‹"
            glyphSize: 26
            onClicked: root.backRequested()
        }

        Column {
            anchors.left: backBtn.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "Sound"
                color: Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: "Output and input devices"
                color: Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }
    }

    Flickable {
        id: flick
        anchors.top: header.bottom
        anchors.topMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: flick.width
            spacing: 6

            SectionLabel {
                text: "OUTPUT"
            }

            Repeater {
                model: Audio.outputs
                delegate: DeviceRow {}
            }

            Item {
                width: 1
                height: 8
            }

            SectionLabel {
                text: "INPUT"
            }

            Repeater {
                model: Audio.inputs
                delegate: DeviceRow {
                    input: true
                }
            }
        }
    }
}
