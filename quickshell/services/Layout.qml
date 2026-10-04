pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Which shape the shell takes: "island" — the floating pills it ships with — or "bar", one flat
// strip across the top of the screen with no hover tricks.
//
// Only the idle face of the shell changes. The island window stays either way, because it is what
// the launcher, the control center, the OSD and every other view are drawn in; in bar mode it just
// has nothing to show until you open something.
Singleton {
    id: root

    readonly property string stateFile: Quickshell.env("HOME") + "/.cache/quickshell/layout"

    property string mode: "island"
    readonly property bool bar: mode === "bar"

    // Height of the bar, and what it reserves from the screen for tiled windows
    readonly property int barHeight: 30

    function toggle() {
        setMode(bar ? "island" : "bar");
    }

    function setMode(next) {
        if (next !== "island" && next !== "bar")
            return;
        mode = next;
        store.setText(next);
    }

    Component.onCompleted: store.reload()

    FileView {
        id: store
        path: root.stateFile
        // Read before the first window is created: starting in the wrong shape and correcting a
        // frame later is what used to leave the bar stranded below the island's reserved strip.
        blockLoading: true
        printErrors: false
        onLoaded: {
            const saved = text().trim();
            if (saved === "bar" || saved === "island")
                root.mode = saved;
        }
    }
}
