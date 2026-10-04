pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property string view: ""
    // The control center, opened by clicking the simple bar rather than hovering the island
    property bool panel: false

    function toggle(name) {
        panel = false;
        view = view === name ? "" : name;
    }

    function open(name) {
        panel = false;
        view = name;
    }

    // close() with no name closes whatever is open, which is what the focus grab asks for
    function close(name) {
        if (!name || view === name)
            view = "";
        if (!name)
            panel = false;
    }
}
