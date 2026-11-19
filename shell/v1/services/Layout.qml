pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Which shape the shell takes: "island" — the floating pills it ships with — or "bar", one flat
// strip across the top of the screen with no hover tricks.
//
// Only the idle face of the shell changes. The island window stays either way, because it is what
// the launcher, the control center, the OSD and every other view are drawn in; in bar mode it just
// has nothing to show until you open something.
//
// The choice is `style` in config/Settings.qml ("pill" or "bar" in shell.json, the names Poteto
// uses; "pill" is this shell's "island"), so Poteto's layout switch works here too.
Singleton {
    id: root

    // The old file's value while it waits to be carried over (see below), then shell.json's
    readonly property string mode: legacyMode || (Settings.style === "bar" ? "bar" : "island")
    readonly property bool bar: mode === "bar"

    // Height of the bar, and what it reserves from the screen for tiled windows
    readonly property int barHeight: 30
    // The floating pills' height: the island's, the workspaces' and the music and date pill's
    readonly property int pillHeight: 30

    function toggle() {
        setMode(bar ? "island" : "bar");
    }

    function setMode(next) {
        if (next === "island" || next === "bar")
            Settings.set("style", next === "bar" ? "bar" : "pill");
    }

    // Before the choice moved into shell.json it was kept in ~/.cache/quickshell/layout. Carry it
    // over once (it is newer than anything this shell wrote to shell.json, which was nothing),
    // then remove the old file so it is never read again.
    readonly property string legacyFile: Quickshell.env("HOME") + "/.cache/quickshell/layout"
    property string legacyMode: ""

    // Settings may not have read shell.json yet when the old file is read: wait for it. The old
    // file is removed only after its value is written to shell.json.
    function migrate() {
        if (!legacyMode || !Settings.writable)
            return;
        Settings.set("style", legacyMode === "bar" ? "bar" : "pill");
        legacyMode = "";
        removeLegacy.running = true;
    }

    Connections {
        target: Settings
        function onWritableChanged() {
            root.migrate();
        }
    }

    FileView {
        path: root.legacyFile
        // Read before the first window, like Settings, so the shell starts in the carried-over shape
        blockLoading: true
        printErrors: false
        onLoaded: {
            const saved = text().trim();
            if (saved !== "bar" && saved !== "island")
                return;
            root.legacyMode = saved;
            root.migrate();
        }
    }

    Process {
        id: removeLegacy
        command: ["rm", "-f", "--", root.legacyFile]
    }
}
