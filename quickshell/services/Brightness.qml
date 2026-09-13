pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real value: 1.0
    property bool ready: false
    property double lastWrite: 0

    signal changedExternally()

    function set(v) {
        value = Math.min(1, Math.max(0.01, v));
        lastWrite = Date.now();
        writeDebounce.restart();
    }

    function read() {
        if (readProc.running)
            readAgain.restart();
        else
            readProc.running = true;
    }

    Process {
        id: monitor
        running: true
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=backlight"]
        stdout: SplitParser {
            onRead: line => { if (line.includes(" change ")) root.read(); }
        }
        onExited: monitorRestart.restart()
    }

    Timer {
        id: monitorRestart
        interval: 2000
        onTriggered: monitor.running = true
    }

    Process {
        id: readProc
        running: true
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                if (f.length < 5)
                    return;
                if (Date.now() - root.lastWrite < 300)
                    return;
                const v = parseInt(f[2]) / parseInt(f[4]);
                const changed = Math.abs(v - root.value) > 0.001;
                root.value = v;
                if (root.ready && changed)
                    root.changedExternally();
                root.ready = true;
            }
        }
    }

    Timer {
        id: readAgain
        interval: 50
        onTriggered: root.read()
    }

    Process {
        id: writeProc
        property int target: 100
        command: ["brightnessctl", "-q", "set", target + "%"]
    }

    Timer {
        id: writeDebounce
        interval: 30
        onTriggered: {
            if (writeProc.running) {
                restart();
                return;
            }
            writeProc.target = Math.max(1, Math.round(root.value * 100));
            writeProc.running = true;
            root.lastWrite = Date.now();
        }
    }
}
