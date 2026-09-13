import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property ShellScreen targetScreen

    screen: targetScreen
    anchors.top: true
    anchors.left: true
    margins.top: 8
    margins.left: 12
    implicitWidth: workspaces.implicitWidth
    implicitHeight: workspaces.implicitHeight
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "workspaces"

    Workspaces {
        id: workspaces
        anchors.fill: parent
        screen: root.targetScreen
    }
}
