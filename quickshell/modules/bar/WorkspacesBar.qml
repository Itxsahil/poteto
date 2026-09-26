import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components

PanelWindow {
    id: root

    required property ShellScreen targetScreen

    // The window sits in the screen corner and the pill is inset by the gap it used to get from
    // the window margins, so there is room around it for the shadow. Only the pill takes input.
    readonly property int gapTop: 8
    readonly property int gapLeft: 12
    readonly property int shadowRoom: 24

    screen: targetScreen
    anchors.top: true
    anchors.left: true
    implicitWidth: workspaces.implicitWidth + gapLeft + shadowRoom
    implicitHeight: workspaces.implicitHeight + gapTop + shadowRoom
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "workspaces"

    mask: Region {
        item: workspaces
    }

    Shadow {
        target: workspaces
    }

    Workspaces {
        id: workspaces
        x: root.gapLeft
        y: root.gapTop
        width: implicitWidth
        height: implicitHeight
        screen: root.targetScreen
    }
}
