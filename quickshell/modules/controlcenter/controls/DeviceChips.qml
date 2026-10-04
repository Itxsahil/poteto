import QtQuick
import qs.config
import qs.services

// One chip per place sound can go (or come from) — a device, or a port on one. Hidden while there
// is nothing to choose between, so a machine with one output never sees it. A Column skips
// invisible children, so the row leaves no gap behind.
Flow {
    id: root

    required property var entries

    signal picked(var entry)

    visible: entries.length > 1
    spacing: 6

    Repeater {
        model: root.entries

        delegate: Rectangle {
            id: chip

            required property var modelData

            height: 26
            width: Math.min(label.implicitWidth + 20, root.width)
            radius: 13
            // Dimmed and outlined when the port is unavailable: shown so you can see it exists,
            // but it reads as a label rather than a button, because picking it would be silent
            opacity: chip.modelData.available ? 1 : 0.6
            color: chip.modelData.active ? Theme.accent
                : !chip.modelData.available ? "transparent"
                : mouse.containsMouse ? Theme.controlHover
                : Theme.controlBg
            border.width: chip.modelData.available ? 0 : 1
            border.color: Theme.islandBorder
            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                id: label
                anchors.centerIn: parent
                width: Math.min(implicitWidth, chip.width - 20)
                elide: Text.ElideRight
                text: chip.modelData.label
                color: chip.modelData.active ? Theme.onAccent : Theme.textPrimary
                font.pixelSize: 11
                font.weight: chip.modelData.active ? Font.DemiBold : Font.Normal
                font.family: Theme.fontFamily
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                enabled: chip.modelData.available
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(chip.modelData)
            }
        }
    }
}
