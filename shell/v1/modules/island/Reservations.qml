import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Space kept clear of tiled windows, one invisible window per screen edge. The island's window
// (Island.qml) covers the whole screen to draw the shell's surface, so it cannot reserve an edge
// itself: Wayland only lets a window anchored to one edge do that.
//
// Top: the island's height, or in bar mode the bar's (SimpleBar.qml does not reserve its own).
// The other edges: the frame's width, so windows keep Hyprland's gaps_out from the frame rather
// than from the screen's edge.
Scope {
    id: root

    required property ShellScreen targetScreen

    component Edge: PanelWindow {
        screen: root.targetScreen
        color: "transparent"
        implicitWidth: 1
        implicitHeight: 1
        // Takes no input and draws nothing
        mask: Region {}
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "reservation"
    }

    Edge {
        anchors.top: true
        anchors.left: true
        anchors.right: true
        exclusiveZone: Layout.bar ? Layout.barHeight : Layout.pillHeight
    }

    Edge {
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        exclusiveZone: Tokens.frameWidth
    }

    Edge {
        anchors.left: true
        anchors.top: true
        anchors.bottom: true
        exclusiveZone: Tokens.frameWidth
    }

    Edge {
        anchors.right: true
        anchors.top: true
        anchors.bottom: true
        exclusiveZone: Tokens.frameWidth
    }
}
