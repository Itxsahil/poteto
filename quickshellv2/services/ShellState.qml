pragma Singleton

import QtQuick
import Quickshell

// What the shell has open right now. Shared by every screen; each window decides for itself
// whether it is the one that shows it (the focused monitor).
Singleton {
    id: root

    // "" (nothing), "launcher" or "controlcenter", opened from the keyboard: stays until closed
    property string view: ""

    // The control center opened by hovering the pill or the bar's clock: closes again shortly
    // after the pointer leaves, and never takes the keyboard
    property bool peek: false

    readonly property bool launcherOpen: view === "launcher"
    readonly property bool controlCenterOpen: view === "controlcenter" || (peek && view === "")

    function toggle(name) {
        view = view === name ? "" : name;
        peek = false;
    }

    function open(name) {
        view = name;
        peek = false;
    }

    function close(name) {
        if (!name || view === name)
            view = "";
        peek = false;
    }

    // Hover in/out of anything that opens or shows the control center. The delay lets the
    // pointer cross from the bar's clock to the panel under it without it closing in between.
    function hoverEnter() {
        peekClose.stop();
        peek = true;
    }

    function hoverExit() {
        peekClose.restart();
    }

    Timer {
        id: peekClose
        interval: 250
        onTriggered: root.peek = false
    }
}
