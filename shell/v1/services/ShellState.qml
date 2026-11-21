pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property string view: ""
    // The control center, opened by clicking the simple bar rather than hovering the island
    property bool panel: false
    // The settings drawer, sliding in from the right (modules/settings/SettingsDrawer.qml). Opening
    // it closes any view, and opening a view closes it
    property bool settings: false

    function toggle(name) {
        panel = false;
        settings = false;
        view = view === name ? "" : name;
    }

    function open(name) {
        panel = false;
        settings = false;
        view = name;
    }

    // close() with no name closes whatever is open, which is what the focus grab asks for
    function close(name) {
        if (!name || view === name)
            view = "";
        if (!name) {
            panel = false;
            settings = false;
        }
    }

    function openSettings(): void {
        view = "";
        panel = false;
        settings = true;
    }

    function toggleSettings(): void {
        if (settings)
            settings = false;
        else
            openSettings();
    }
}
