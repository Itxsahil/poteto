pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Keeps the desktop in line with the settings, at start and whenever one changes:
// - the mode (Config.mode): the system's light/dark preference (scripts/apply-mode), then kitty,
//   Neovim, rmpc, VS Code, Hyprland's borders and hyprlock switch to Poteto's palette for it
//   (scripts/apply-palette mode)
// - the accent (Config.accent): GTK, Qt, VS Code and Firefox (scripts/apply-accent), and the
//   palette files drawn in it (borders, kitty's cursor and selection, rmpc), rebuilt by
//   scripts/apply-palette build
// The shell's own colors follow both in Theme.qml.
//
// One script at a time, in the order asked, so two never edit the same file at once; asking
// again for something already waiting does not run it twice.
Singleton {
    id: root

    readonly property string scripts: Quickshell.shellDir + "/scripts/"
    // What is waiting to run: "palette", "mode" and "accent"
    property var queue: []

    // At start: the palette files first, which the mode switches between
    function apply() {
        enqueue("palette");
        enqueue("mode");
    }

    function applyAccent() {
        enqueue("accent");
        enqueue("palette");
    }

    function enqueue(job) {
        if (!queue.includes(job))
            queue = queue.concat([job]);
        next();
    }

    // The commands for a job, run one after the other
    function commands(job) {
        if (job === "mode")
            return [[scripts + "apply-mode", Config.mode], [scripts + "apply-palette", "mode", Config.mode]];
        if (job === "palette")
            return [[scripts + "apply-palette", "build", Config.mode, Config.accent]];
        return [[scripts + "apply-accent", Config.accent]];
    }

    function next() {
        if (proc.running || (proc.steps.length === 0 && queue.length === 0))
            return;
        if (proc.steps.length === 0) {
            proc.steps = commands(queue[0]);
            queue = queue.slice(1);
        }
        proc.command = proc.steps[0];
        proc.steps = proc.steps.slice(1);
        proc.running = true;
    }

    readonly property string mode: Config.mode
    onModeChanged: enqueue("mode")
    readonly property string accent: Config.accent
    onAccentChanged: applyAccent()

    Process {
        id: proc
        property var steps: []
        stderr: StdioCollector { id: err }
        onExited: code => {
            if (code !== 0 || err.text.trim())
                console.warn("Appearance:", command.slice(1).join(" "), "exited", code, err.text.trim());
            Qt.callLater(root.next);
        }
    }
}
