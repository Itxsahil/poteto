import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config

// The floating layout: the time in a rounded pill at the top center of the screen.
PanelWindow {
    id: window

    required property ShellScreen targetScreen

    // Gap between the pill and the top of the screen
    readonly property int gapTop: 8

    screen: targetScreen
    anchors.top: true
    implicitWidth: pill.width
    implicitHeight: pill.height + gapTop
    exclusiveZone: implicitHeight
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "pill"

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Rectangle {
        id: pill
        y: window.gapTop
        width: time.implicitWidth + 80
        height: 30
        radius: height / 2
        color: Theme.background
        border.color: Theme.border
        border.width: 1

        Clock {
            id: time
            anchors.centerIn: parent
            date: clock.date
        }
    }
}
