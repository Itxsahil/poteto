pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Keeps the desktop in line with the settings: the light/dark preference (Config.mode, through
// scripts/apply-mode) and the accent color (Config.accent, through scripts/apply-accent), at
// start and whenever either changes. The shell's own colors follow both in Theme.qml.
Singleton {
    id: root

    readonly property string script: Quickshell.shellDir + "/scripts/apply-mode"
    property bool queued: false

    readonly property string accentScript: Quickshell.shellDir + "/scripts/apply-accent"
    property bool accentQueued: false

    function applyAccent() {
        if (accentProc.running) {
            accentQueued = true;
            return;
        }
        accentProc.command = [accentScript, Config.accent];
        accentProc.running = true;
    }

    readonly property string accent: Config.accent
    onAccentChanged: applyAccent()

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
        id: accentProc
        stderr: StdioCollector { id: accentErr }
        onExited: code => {
            if (code !== 0 || accentErr.text.trim())
                console.warn("Appearance: apply-accent", Config.accent, accentErr.text.trim());
            if (root.accentQueued) {
                root.accentQueued = false;
                root.applyAccent();
            }
        }
    }

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
