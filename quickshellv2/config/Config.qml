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

    // "dark" or "light": the desktop's preference (services/Appearance.qml) and the shell's colors
    readonly property string mode: data.mode === "light" ? "light" : "dark"
    // The themes/<id>/ whose colors the shell uses in light mode; dark mode keeps the active theme
    readonly property string lightTheme: typeof data.lightTheme === "string" ? data.lightTheme : "catppuccin-latte"

    // Night light (services/NightLight.qml): on or off, and how warm, in kelvin
    readonly property bool nightLight: data.nightLight === true
    readonly property int nightTemperature: typeof data.nightTemperature === "number"
        ? Math.max(1000, Math.min(6500, Math.round(data.nightTemperature))) : 4000

    function set(key, value) {
        const updated = Object.assign({}, data);
        updated[key] = value;
        data = updated;
        store.setText(JSON.stringify(updated, null, 2) + "\n");
    }

    function setStyle(next) {
        if (next === "pill" || next === "bar")
            set("style", next);
    }

    function toggleStyle() {
        setStyle(style === "pill" ? "bar" : "pill");
    }

    function setMode(next) {
        if (next === "dark" || next === "light")
            set("mode", next);
    }

    function toggleMode() {
        setMode(mode === "dark" ? "light" : "dark");
    }

    function setNightLight(on) {
        set("nightLight", !!on);
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
