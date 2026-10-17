pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Keeps the desktop's light/dark preference in Config.mode: runs scripts/apply-mode at start and
// whenever the mode changes. The shell's own colors follow Config.mode in Theme.qml.
Singleton {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/apply-mode"
    property bool queued: false

    function apply() {
        if (proc.running) {
            queued = true;
            return;
        }
        proc.command = [script, Config.mode];
        proc.running = true;
    }

    readonly property string mode: Config.mode
    onModeChanged: apply()

    Process {
        id: proc
        stderr: StdioCollector { id: err }
        onExited: code => {
            if (code !== 0)
                console.warn("Appearance: apply-mode", Config.mode, "failed:", err.text);
            if (root.queued) {
                root.queued = false;
                root.apply();
            }
        }
    }
}
