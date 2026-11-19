import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// The bar's workspaces: one slot per workspace, as tall as the bar, marked by brightness alone —
// bold and bright for the active one, dimmer for ones with windows, faint for empty ones, red
// for urgent. Click a slot to go there, scroll anywhere on it to step through them.
Item {
    id: root

    required property ShellScreen screen
    // Shown even while empty, so the first few always sit in the same place
    property int persistentCount: 5
    // Each slot's width: the bar's are roomy, the pill's neighbour packs them closer
    property int slotWidth: 34

    readonly property var monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1
    readonly property var slots: {
        const ids = new Set();
        for (let i = 1; i <= persistentCount; i++)
            ids.add(i);
        // Special and named workspaces have ids below 1; they are not slots
        for (const w of Hyprland.workspaces.values)
            if (w.id > 0)
                ids.add(w.id);
        return [...ids].sort((a, b) => a - b);
    }

    implicitWidth: row.implicitWidth

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
        height: parent.height

        Repeater {
            model: root.slots

            Item {
                id: slot

                required property int modelData
                readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === modelData) ?? null
                readonly property bool isActive: modelData === root.activeId
                readonly property bool occupied: (workspace?.toplevels?.values?.length ?? 0) > 0
                readonly property bool urgent: workspace?.urgent ?? false

                width: root.slotWidth
                height: row.height

                Text {
                    anchors.centerIn: parent
                    text: slot.modelData
                    color: slot.urgent ? Theme.danger
                        : slot.isActive ? Theme.text
                        : mouse.containsMouse ? Qt.alpha(Theme.text, 0.8)
                        : slot.occupied ? Qt.alpha(Theme.text, 0.55)
                        : Qt.alpha(Theme.text, 0.33)
                    font.pixelSize: 13
                    font.weight: slot.isActive ? Font.Bold : Font.Medium
                    font.family: Theme.fontFamily
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${slot.modelData} })`)
                }
            }
        }
    }
}
