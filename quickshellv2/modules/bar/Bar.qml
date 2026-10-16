import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// The flat layout: one strip across the full width of the top of the screen, workspaces on the
// left and the time in the middle. Hovering the time drops the control center down under it
// (BarPanel.qml).
PanelWindow {
    id: window

    required property ShellScreen targetScreen

    screen: targetScreen
    anchors.top: true
    anchors.left: true
    anchors.right: true
    implicitHeight: 30
    exclusiveZone: implicitHeight
    color: Theme.background

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "bar"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // A hairline under the bar instead of a border all the way round
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }

    Workspaces {
        anchors.left: parent.left
        anchors.top: parent.top
        // Clear of the hairline, so it stays centred on what is visible
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        screen: window.targetScreen
    }

    Rectangle {
        anchors.centerIn: parent
        width: time.implicitWidth + 24
        height: window.implicitHeight - 6
        radius: 6
        color: ShellState.controlCenterOpen ? Theme.tile
            : hover.hovered ? Qt.alpha(Theme.tile, 0.6)
            : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        HoverHandler {
            id: hover
            onHoveredChanged: hovered ? ShellState.hoverEnter() : ShellState.hoverExit()
        }

        Clock {
            id: time
            anchors.centerIn: parent
            date: clock.date
        }
    }
}
