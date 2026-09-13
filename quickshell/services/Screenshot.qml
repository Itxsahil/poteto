pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property bool busy: false
    property string mode: "region"
    property string screenName: ""
    property real screenScale: 1
    property var windows: []
    property string frozenPath: ""
    property string lastPath: ""

    readonly property string saveDir: Quickshell.env("HOME") + "/Pictures/Screenshots"

    signal captured(string path)

    function start(newMode) {
        if (active || busy)
            return;
        busy = true;
        mode = newMode || "region";
        monitorsProc.running = true;
    }

    function cancel() {
        if (!active)
            return;
        active = false;
        cleanupProc.command = ["rm", "-f", frozenPath];
        cleanupProc.running = true;
    }

    function capture(x, y, w, h) {
        if (!active)
            return;
        active = false;
        const s = screenScale;
        const geom = `${Math.round(w * s)}x${Math.round(h * s)}+${Math.round(x * s)}+${Math.round(y * s)}`;
        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
        const out = `${saveDir}/${stamp}.png`;
        cropProc.out = out;
        cropProc.frozen = frozenPath;
        cropProc.command = ["sh", "-c",
            'mkdir -p "$1" && magick "$2" -crop "$3" +repage "$4" && wl-copy --type image/png < "$4"',
            "sh", saveDir, frozenPath, geom, out];
        cropProc.running = true;
    }

    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "-j"]
        property var monitor: null
        stdout: StdioCollector {
            onStreamFinished: {
                let mons = [];
                try {
                    mons = JSON.parse(text);
                } catch (e) {
                    console.warn("Screenshot: could not read monitors from hyprctl");
                }
                const m = mons.find(x => x.focused) ?? mons[0];
                if (!m) {
                    root.busy = false;
                    return;
                }
                monitorsProc.monitor = m;
                root.screenName = m.name;
                root.screenScale = m.scale;
                root.frozenPath = `/tmp/qs-screenshot-freeze-${Date.now()}.png`;
                freezeProc.command = ["grim", "-o", m.name, root.frozenPath];
                freezeProc.running = true;
                clientsProc.running = true;
            }
        }
    }

    Process {
        id: clientsProc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = monitorsProc.monitor;
                if (!m)
                    return;
                const wsIds = [m.activeWorkspace?.id, m.specialWorkspace?.id].filter(id => id);
                root.windows = JSON.parse(text)
                    .filter(c => c.mapped && !c.hidden && wsIds.includes(c.workspace.id))
                    .sort((a, b) => (b.floating - a.floating) || (a.focusHistoryID - b.focusHistoryID))
                    .map(c => ({
                        title: c.title,
                        appClass: c.class,
                        x: c.at[0] - m.x,
                        y: c.at[1] - m.y,
                        w: c.size[0],
                        h: c.size[1]
                    }));
            }
        }
    }

    Process {
        id: freezeProc
        onExited: code => {
            root.busy = false;
            if (code === 0)
                root.active = true;
        }
    }

    Process {
        id: cropProc
        property string out: ""
        property string frozen: ""
        onExited: code => {
            cropCleanupProc.command = ["rm", "-f", frozen];
            cropCleanupProc.running = true;
            if (code === 0) {
                root.lastPath = out;
                root.captured(out);
            }
        }
    }

    Process {
        id: cleanupProc
    }

    Process {
        id: cropCleanupProc
    }
}
