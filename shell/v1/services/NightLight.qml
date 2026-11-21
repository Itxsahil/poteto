pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Night light: while it is on, hyprsunset warms the screens to `temperature` (kelvin); off stops
// it, which hands the colors back. The setting lives in config/Settings.qml (nightLight and
// nightTemperature in ~/.config/poteto/shell.json), which the settings drawer edits.
//
// hyprsunset runs on its own (it outlives a shell restart), so this only ever brings it in line:
// start it, retune the one already running through hyprctl, or stop it.
Singleton {
    id: root

    readonly property bool enabled: Settings.nightLight
    readonly property int minTemperature: 2000
    readonly property int maxTemperature: 6500
    readonly property int temperature: Settings.nightTemperature
    readonly property var wanted: [enabled, temperature]
    property bool queued: false

    function toggle() {
        Settings.set("nightLight", !enabled);
    }

    function setEnabled(on) {
        Settings.set("nightLight", !!on);
    }

    function setTemperature(kelvin) {
        Settings.set("nightTemperature", Math.round(Math.max(minTemperature, Math.min(maxTemperature, kelvin)) / 100) * 100);
    }

    function apply() {
        if (proc.running) {
            queued = true;
            return;
        }
        proc.command = enabled
            ? ["sh", "-c", 'if pgrep -x hyprsunset >/dev/null; then hyprctl hyprsunset temperature "$1" >/dev/null; else setsid -f hyprsunset -t "$1" >/dev/null 2>&1; fi', "sh", String(temperature)]
            : ["sh", "-c", "pkill -x hyprsunset; true"];
        proc.running = true;
    }

    onWantedChanged: apply()
    // The change handler does not run for the first value: bring hyprsunset in line at start
    Component.onCompleted: apply()

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
