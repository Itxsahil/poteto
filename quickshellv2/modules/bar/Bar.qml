import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// The flat layout: one strip across the full width of the top of the screen, time in the middle.
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

    Clock {
        anchors.centerIn: parent
        date: clock.date
    }
}
