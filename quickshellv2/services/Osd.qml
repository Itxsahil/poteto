pragma Singleton

import QtQuick
import Quickshell

// The on-screen display: what just changed from outside the shell (for now, the brightness keys),
// shown for a moment in the pill, or in the middle of the bar, by modules/osd/OsdContent.qml.
Singleton {
    id: root

    // "brightness"
    property string kind: "brightness"
    property bool shown: false

    function trigger(name) {
        // Not for the readings that come in while the shell starts
        if (startup.running)
            return;
        kind = name;
        shown = true;
        hide.restart();
    }

    Connections {
        target: Brightness
        function onChangedExternally() {
            root.trigger("brightness");
        }
    }

    Timer {
        id: startup
        interval: 1500
        running: true
    }

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.shown = false
    }
}
