pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User settings, kept in ~/.config/poteto/shell.json so a settings app can edit them later.
// The file is watched, so a change shows up live. Missing or malformed values fall back to the
// defaults below.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/poteto"
    readonly property string file: dir + "/shell.json"
    property var data: ({})

    // "pill": the floating clock pill; "bar": a flat strip across the top of the screen
    readonly property string style: data.style === "bar" ? "bar" : "pill"

    function setStyle(next) {
        if (next !== "pill" && next !== "bar")
            return;
        const updated = Object.assign({}, data, { style: next });
        data = updated;
        store.setText(JSON.stringify(updated, null, 2) + "\n");
    }

    function toggleStyle() {
        setStyle(style === "pill" ? "bar" : "pill");
    }

    // setText does not create the folder
    Process {
        running: true
        command: ["mkdir", "-p", root.dir]
    }

    FileView {
        id: store
        path: root.file
        // Read before the first window exists, so the shell never starts in the wrong layout
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            // A half-written file keeps the last good settings rather than resetting them
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object")
                    root.data = parsed;
            } catch (e) {}
        }
        onLoadFailed: root.data = ({})
    }
}
