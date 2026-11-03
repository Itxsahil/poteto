pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// The workspace overview (Alt + Tab, modules/overview/WorkspaceOverview.qml): every workspace
// with windows, and the one you are on, as cards; one is selected, and committing focuses it.
//
// Alt + Tab opens it with the next workspace selected (as Alt + Tab does on other desktops) and
// moves on while it is open; Alt + Shift + Tab goes back. Letting go of Alt, Enter or a click
// commits; Esc or a click outside cancels.
Singleton {
    id: root

    property bool open: false
    property int index: 0

    readonly property int currentId: Hyprland.focusedMonitor?.activeWorkspace?.id ?? -1

    // The workspaces to show, by id: those with windows, and the current one even when empty
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(w => w.id > 0 && ((w.toplevels?.values?.length ?? 0) > 0 || w.id === currentId))
        .sort((a, b) => a.id - b.id)

    readonly property var selected: workspaces[index] ?? null

    function show(step) {
        // Window positions come from Hyprland's last report: ask for a fresh one
        Hyprland.refreshToplevels();
        const current = Math.max(0, workspaces.findIndex(w => w.id === currentId));
        index = workspaces.length > 1 ? (current + step + workspaces.length) % workspaces.length : current;
        open = true;
    }

    function next() {
        if (!open)
            show(1);
        else if (workspaces.length > 0)
            index = (index + 1) % workspaces.length;
    }

    function prev() {
        if (!open)
            show(-1);
        else if (workspaces.length > 0)
            index = (index - 1 + workspaces.length) % workspaces.length;
    }

    function select(i) {
        index = Math.max(0, Math.min(workspaces.length - 1, i));
    }

    function commit() {
        if (!open)
            return;
        const target = selected;
        open = false;
        if (!target || target.id === currentId)
            return;
        // Not yet: while the overview still holds the keyboard, Hyprland hands focus back to the
        // window that had it when the overview lets go, which pulls the screen back to its
        // workspace. Switch once the overview has let go
        switchTimer.target = target.id;
        switchTimer.restart();
    }

    Timer {
        id: switchTimer
        property int target: -1
        interval: 120
        onTriggered: Hyprland.dispatch(`hl.dsp.focus({ workspace = ${target} })`)
    }

    function cancel() {
        open = false;
    }

    // A workspace that empties or closes while open must not leave the selection past the end
    onWorkspacesChanged: {
        if (index >= workspaces.length)
            index = Math.max(0, workspaces.length - 1);
    }
}
