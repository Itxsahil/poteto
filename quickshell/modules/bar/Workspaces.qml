import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

Rectangle {
    id: root

    property ShellScreen screen
    property int persistentCount: 5

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1
    readonly property var slots: {
        const ids = new Set();
        for (let i = 1; i <= persistentCount; i++)
            ids.add(i);
        for (const w of Hyprland.workspaces.values)
            if (w.id > 0)
                ids.add(w.id);
        return [...ids].sort((a, b) => a - b);
    }

    implicitWidth: row.implicitWidth + 8
    implicitHeight: 36
    radius: height / 2
    color: Theme.islandBg
    border.color: Theme.islandBorder
    border.width: 1

    Behavior on implicitWidth { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    WheelHandler {
        property real accumulated: 0
        onWheel: event => {
            accumulated += event.angleDelta.y;
            if (Math.abs(accumulated) < 120)
                return;
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${accumulated > 0 ? "e-1" : "e+1"}" })`);
            accumulated = 0;
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.slots

            Rectangle {
                id: slot

                required property int modelData
                readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
                readonly property bool isActive: modelData === root.activeId
                readonly property bool occupied: (workspace?.toplevels?.values?.length ?? 0) > 0
                readonly property bool urgent: workspace?.urgent ?? false

                width: isActive ? 44 : 28
                height: 28
                radius: 14
                color: isActive ? Theme.wsActiveBg
                    : urgent ? Theme.wsUrgentBg
                    : slotMouse.containsMouse ? Theme.wsHoverBg
                    : "transparent"

                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: slot.modelData
                    color: slot.isActive ? Theme.wsActiveText
                        : slot.urgent ? Theme.danger
                        : slot.occupied ? Theme.wsOccupiedText
                        : Theme.wsEmptyText
                    font.pixelSize: 13
                    font.weight: slot.isActive ? Font.Bold : Font.Medium
                    font.family: Theme.fontFamily
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    id: slotMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${slot.modelData} })`)
                }
            }
        }
    }
}
