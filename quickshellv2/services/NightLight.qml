pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Night light: while Config.nightLight is on, hyprsunset warms the screens to
// Config.nightTemperature; off stops it, which hands the colors back. hyprsunset runs on its own
// (it outlives a shell restart), so this only ever brings it in line: start it, retune the one
// already running through hyprctl, or stop it.
Singleton {
    id: root

    readonly property bool enabled: Config.nightLight
    readonly property var wanted: [enabled, Config.nightTemperature]
    property bool queued: false

    function toggle() {
        Config.setNightLight(!enabled);
    }

    function apply() {
        if (proc.running) {
            queued = true;
            return;
        }
        proc.command = enabled
            ? ["sh", "-c", 'if pgrep -x hyprsunset >/dev/null; then hyprctl hyprsunset temperature "$1" >/dev/null; else setsid -f hyprsunset -t "$1" >/dev/null 2>&1; fi', "sh", String(Config.nightTemperature)]
            : ["sh", "-c", "pkill -x hyprsunset; true"];
        proc.running = true;
    }

    onWantedChanged: apply()

    Process {
        id: proc
        stderr: StdioCollector { id: err }
        onExited: code => {
            if (code !== 0)
                console.warn("NightLight: could not", root.enabled ? "start" : "stop", "hyprsunset:", err.text.trim());
            if (root.queued) {
                root.queued = false;
                root.apply();
            }
        }
    }
}
