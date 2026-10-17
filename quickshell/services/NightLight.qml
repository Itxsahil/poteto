pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Night light: while it is on, hyprsunset warms the screens to `temperature` (kelvin); off stops
// it, which hands the colors back. The setting is the one quickshell v2 and the Poteto settings
// app use (nightLight and nightTemperature in ~/.config/poteto/shell.json), so it carries over
// when switching shells and the app's controls keep working. Only those two keys are written;
// everything else in the file is left as it is.
//
// hyprsunset runs on its own (it outlives a shell restart), so this only ever brings it in line:
// start it, retune the one already running through hyprctl, or stop it.
Singleton {
    id: root

    readonly property string file: Quickshell.env("HOME") + "/.config/poteto/shell.json"
    property var data: ({})
    // Only written once it has been read cleanly (or found missing): writing over a file that
    // did not parse would drop every other setting in it
    property bool readable: false

    readonly property bool enabled: data.nightLight === true
    readonly property int minTemperature: 2000
    readonly property int maxTemperature: 6500
    readonly property int temperature: typeof data.nightTemperature === "number"
        ? Math.max(1000, Math.min(6500, Math.round(data.nightTemperature))) : 4000
    readonly property var wanted: [enabled, temperature]
    property bool queued: false

    function toggle() {
        set("nightLight", !enabled);
    }

    function setEnabled(on) {
        set("nightLight", !!on);
    }

    function setTemperature(kelvin) {
        set("nightTemperature", Math.round(Math.max(minTemperature, Math.min(maxTemperature, kelvin)) / 100) * 100);
    }

    function set(key, value) {
        if (!readable) {
            console.warn("NightLight: shell.json could not be read; not writing to it");
            return;
        }
        if (data[key] === value)
            return;
        const updated = Object.assign({}, data);
        updated[key] = value;
        data = updated;
        store.setText(JSON.stringify(updated, null, 2) + "\n");
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

    FileView {
        id: store
        path: root.file
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && typeof parsed === "object") {
                    root.data = parsed;
                    root.readable = true;
                }
            } catch (e) {
                root.readable = false;
                console.warn("NightLight: shell.json is not valid JSON; leaving it alone");
            }
        }
        // No file yet: one is written on the first change
        onLoadFailed: root.readable = true
    }

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
