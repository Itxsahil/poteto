pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The settings this shell shares with quickshell v2 and the Poteto settings app, read from
// ~/.config/poteto/shell.json and followed live. Only read here; Poteto writes them. Anything
// missing or unreadable counts as on.
Singleton {
    id: root

    property var data: ({})

    // The workspaces pill, top left (Poteto → Workspaces; v2 uses the same key)
    readonly property bool showWorkspaces: data.showWorkspaces !== false
    // The music and date pill, top right (Poteto → Music & date)
    readonly property bool showMusic: data.showMusic !== false

    FileView {
        path: Quickshell.env("HOME") + "/.config/poteto/shell.json"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object")
                    root.data = parsed;
            } catch (e) {
                console.warn("Settings: shell.json is not valid JSON; showing everything");
            }
        }
    }
}
