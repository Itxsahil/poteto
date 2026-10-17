pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness through brightnessctl, as a percentage. Follows changes made elsewhere (the
// brightness keys in hypr/bindings.lua) through udev, so a slider showing it never goes stale,
// and says so with changedExternally, which brings up the OSD (services/Osd.qml).
Singleton {
    id: root

    // 1–100; never 0, which on most laptops turns the backlight off altogether
    property real percent: 100
    // A backlight was found
    property bool available: false
    // When the shell last wrote, so the read that the write itself causes does not undo a drag
    property double lastWrite: 0
    // The first reading is in, so later changes are real changes rather than the startup value
    property bool ready: false

    signal changedExternally()

    function set(v) {
        percent = Math.min(100, Math.max(1, Math.round(v)));
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
            onRead: line => {
                if (line.includes(" change "))
                    root.read();
            }
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
        command: ["brightnessctl", "-m", "--class=backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                // name,class,current,percent,max
                const f = text.trim().split("\n")[0].split(",");
                if (f.length < 5) {
                    root.available = false;
                    return;
                }
                root.available = true;
                if (Date.now() - root.lastWrite < 300)
                    return;
                const v = parseInt(f[2]) / parseInt(f[4]) * 100;
                const changed = Math.abs(v - root.percent) > 0.1;
                root.percent = v;
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
        command: ["brightnessctl", "-q", "--class=backlight", "set", target + "%"]
    }

    // At most one write in flight; a drag only ever sends its latest position
    Timer {
        id: writeDebounce
        interval: 30
        onTriggered: {
            if (writeProc.running) {
                restart();
                return;
            }
            writeProc.target = Math.round(root.percent);
            writeProc.running = true;
            root.lastWrite = Date.now();
        }
    }
}
