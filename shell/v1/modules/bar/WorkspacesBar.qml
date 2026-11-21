import QtQuick
import Quickshell
import qs.config
import qs.services

// The workspaces pill, top left, hanging from the top edge like the island. It lives in the
// island's window (modules/island/Island.qml), which draws its background as part of the shell's
// one surface (components/Surface.qml); the pill itself is transparent.
Item {
    id: root

    required property ShellScreen targetScreen
    // Hidden while the workspace is fullscreen, like the rest of the idle surface
    property bool suppressed: false

    // Clear of the frame's rounded corner and its bevel, so the pill hangs on its own
    readonly property int gapLeft: Tokens.frameWidth + Tokens.radius.screen + Tokens.radius.flare + 8
    readonly property alias pill: workspaces

    // the simple bar carries all of this when it is on; and it can be turned off (Settings →
    // Workspaces)
    visible: !Layout.bar && Settings.showWorkspaces && !suppressed

    Workspaces {
        id: workspaces
        x: root.gapLeft
        y: 0
        width: implicitWidth
        height: implicitHeight
        screen: root.targetScreen
        // Drawn by the surface behind it
        color: "transparent"
        border.width: 0
    }
}
