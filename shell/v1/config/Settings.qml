pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The user's settings: ~/.config/poteto/shell.json, the file the Poteto settings app
// (apps/settings/poteto-settings) and quickshell v2 use too. This is the only place in the shell
// that reads or writes it: services bind to the properties below and change them with set().
//
// The file is followed live, so a change made in Poteto or by hand shows up straight away.
// Anything missing or malformed counts as its default. A file that does not parse is never
// written over (that would drop every other setting in it); a missing one is created on the first
// change. Writes are atomic, so the shell and Poteto never read half a file.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/poteto"
    readonly property string file: dir + "/shell.json"
    property var data: ({})
    // Read cleanly, or found missing: only then may set() write the file
    property bool writable: false

    // The shell's shape (services/Layout.qml): "pill", the floating island, or "bar", one flat strip
    readonly property string style: data.style === "bar" ? "bar" : "pill"

    // The workspaces pill, top left (Poteto → Workspaces)
    readonly property bool showWorkspaces: data.showWorkspaces !== false
    // The music and date pill, top right (Poteto → Music & date)
    readonly property bool showMusic: data.showMusic !== false

    // Do Not Disturb (Poteto → Quiet): notifications go straight to history; critical ones still
    // pop up (services/Notifications.qml)
    readonly property bool quiet: data.quiet === true

    // Night light (services/NightLight.qml): on or off, and how warm, in kelvin
    readonly property bool nightLight: data.nightLight === true
    readonly property int nightTemperature: typeof data.nightTemperature === "number"
        ? Math.max(1000, Math.min(6500, Math.round(data.nightTemperature))) : 4000

    // Sets one key and writes the file; everything else in it is kept as it is
    function set(key, value) {
        update({ [key]: value });
    }

    // Sets several keys in one write
    function update(changes) {
        if (!writable) {
            console.warn("Settings: shell.json could not be read; not writing to it");
            return;
        }
        const updated = Object.assign({}, data);
        let changed = false;
        for (const key in changes) {
            if (updated[key] !== changes[key]) {
                updated[key] = changes[key];
                changed = true;
            }
        }
        if (!changed)
            return;
        data = updated;
        store.setText(JSON.stringify(updated, null, 2) + "\n");
    }

    // setText does not create the folder
    Process {
        running: true
        command: ["mkdir", "-p", root.dir]
    }

    FileView {
        id: store
        path: root.file
        // Read before the first window exists, so the shell never starts in the wrong shape
        blockLoading: true
        atomicWrites: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object") {
                    root.data = parsed;
                    root.writable = true;
                    return;
                }
            } catch (e) {}
            // A half-written or broken file keeps the last good settings, and is left alone
            root.writable = false;
            console.warn("Settings: shell.json is not valid JSON; keeping the last good settings");
        }
        // No file yet: defaults, and one is written on the first change
        onLoadFailed: {
            root.data = ({});
            root.writable = true;
        }
    }
}
