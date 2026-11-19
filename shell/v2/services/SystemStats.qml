pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory, GPU, disk, network, sensors and the busiest processes, from scripts/sysstats, a
// sample a second. It runs only while the performance view is open (on any screen), so a closed
// view costs nothing. Keeps the last minute of a few numbers for the graphs.
Singleton {
    id: root

    readonly property bool watching: ShellState.view === "performance"
    readonly property int historyLength: 60

    // The latest sample, as scripts/sysstats prints it; {} until the first one
    property var sample: ({})
    readonly property bool ready: sample.cpu !== undefined

    // The last minute, oldest first
    property var cpuHistory: []
    property var memHistory: []
    property var gpuHistory: []
    property var downHistory: []
    property var upHistory: []
    property var readHistory: []
    property var writeHistory: []

    function push(list, value) {
        const next = list.concat([value]);
        return next.length > historyLength ? next.slice(next.length - historyLength) : next;
    }

    function formatBytes(bytes) {
        if (!(bytes > 0))
            return "0 B";
        const units = ["B", "KB", "MB", "GB", "TB"];
        const i = Math.min(units.length - 1, Math.floor(Math.log(bytes) / Math.log(1024)));
        const v = bytes / Math.pow(1024, i);
        return (v >= 100 || i === 0 ? Math.round(v) : v.toFixed(1)) + " " + units[i];
    }

    function formatRate(bytesPerSecond) {
        return formatBytes(bytesPerSecond) + "/s";
    }

    function formatUptime(seconds) {
        const d = Math.floor(seconds / 86400);
        const h = Math.floor(seconds % 86400 / 3600);
        const m = Math.floor(seconds % 3600 / 60);
        return d > 0 ? `${d}d ${h}h` : h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    // End a process (SIGTERM, so it can clean up)
    function end(pid) {
        Quickshell.execDetached(["kill", "-TERM", String(pid)]);
    }

    Process {
        id: proc
        command: [Quickshell.shellDir + "/scripts/sysstats"]
        running: root.watching

        stdout: SplitParser {
            onRead: line => {
                let s;
                try {
                    s = JSON.parse(line);
                } catch (e) {
                    return;
                }
                root.sample = s;
                root.cpuHistory = root.push(root.cpuHistory, s.cpu);
                root.memHistory = root.push(root.memHistory, s.mem.total > 0 ? 100 * s.mem.used / s.mem.total : 0);
                root.gpuHistory = root.push(root.gpuHistory, s.gpu && !s.gpu.asleep ? (s.gpu.util ?? 0) : 0);
                root.downHistory = root.push(root.downHistory, s.net.down);
                root.upHistory = root.push(root.upHistory, s.net.up);
                root.readHistory = root.push(root.readHistory, s.disk.read ?? 0);
                root.writeHistory = root.push(root.writeHistory, s.disk.write ?? 0);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim())
                    console.warn("SystemStats:", text.trim());
            }
        }
    }
}
