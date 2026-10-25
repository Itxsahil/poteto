import QtQuick
import qs.modules.bar

// The music player as an island view of its own (Super + P, qs ipc call media toggle): the
// panel the music pill grows into on hover, open without it. Esc closes it.
Item {
    id: root

    property bool active: false

    signal closeRequested()

    implicitWidth: panel.implicitWidth + 16
    implicitHeight: panel.implicitHeight + 16

    onActiveChanged: {
        if (active)
            keys.forceActiveFocus();
    }

    Item {
        id: keys
        focus: root.active
        Keys.onEscapePressed: root.closeRequested()
    }

    MediaPanel {
        id: panel
        anchors.centerIn: parent
        width: implicitWidth
        height: implicitHeight
    }
}
