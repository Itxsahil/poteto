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

    // Bar mode draws blocks that fill the bar's height instead of capsules floating inside a pill:
    // the active workspace is a solid panel of color, not an outline around a number.
    property bool flat: false

    implicitWidth: row.implicitWidth + (flat ? 0 : 8)
    implicitHeight: 36
    radius: flat ? 0 : height / 2
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
        spacing: root.flat ? 0 : 2

        Repeater {
            model: root.slots

            Rectangle {
                id: slot

                required property int modelData
                readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
                readonly property bool isActive: modelData === root.activeId
                readonly property bool occupied: (workspace?.toplevels?.values?.length ?? 0) > 0
                readonly property bool urgent: workspace?.urgent ?? false

                width: root.flat ? 34 : isActive ? 44 : 28
                height: root.flat ? root.height : 28
                radius: root.flat ? 0 : 14
                // Bar mode marks the active workspace by brightness alone — no block behind the
                // number, which is the one thing the pill is for
                color: root.flat ? "transparent"
                    : isActive ? Theme.wsActiveBg
                    : urgent ? Theme.wsUrgentBg
                    : slotMouse.containsMouse ? Theme.wsHoverBg
                    : "transparent"

                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: slot.modelData
                    color: slot.urgent ? Theme.danger
                        : root.flat ? (slot.isActive ? Theme.textPrimary
                            : slotMouse.containsMouse ? Qt.alpha(Theme.textPrimary, 0.8)
                            : slot.occupied ? Qt.alpha(Theme.textPrimary, 0.55)
                            : Theme.wsEmptyText)
                        : slot.isActive ? Theme.wsActiveText
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
