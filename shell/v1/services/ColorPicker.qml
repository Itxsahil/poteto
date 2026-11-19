pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/quickshell"
    readonly property string stateFile: cacheDir + "/color-picker.json"
    readonly property int maxHistory: 16
    readonly property var formats: ["hex", "rgb", "hsl"]

    property bool active: false
    property bool busy: false
    property string screenName: ""
    property real screenScale: 1
    property int pixelWidth: 0
    property int pixelHeight: 0
    property string frozenPath: ""
    property real startX: 0
    property real startY: 0

    property string format: "hex"
    property var history: []

    signal picked(string hex)

    function start() {
        if (active || busy)
            return;
        busy = true;
        monitorsProc.running = true;
    }

    function cancel() {
        if (!active)
            return;
        active = false;
        cleanup(frozenPath);
    }

    function cycleFormat(delta) {
        format = formats[(formats.indexOf(format) + delta + formats.length) % formats.length];
        save();
    }

    function toHex(r, g, b) {
        return "#" + [r, g, b].map(v => v.toString(16).padStart(2, "0")).join("");
    }

    function fromHex(hex) {
        const n = parseInt(hex.slice(1), 16);
        return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
    }

    function formatColor(hex, fmt) {
        const [r, g, b] = fromHex(hex);
        if (fmt === "rgb")
            return `rgb(${r}, ${g}, ${b})`;
        if (fmt === "hsl") {
            const rn = r / 255, gn = g / 255, bn = b / 255;
            const max = Math.max(rn, gn, bn), min = Math.min(rn, gn, bn);
            const l = (max + min) / 2;
            let h = 0, s = 0;
            if (max !== min) {
                const d = max - min;
                s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
                h = max === rn ? (gn - bn) / d + (gn < bn ? 6 : 0)
                    : max === gn ? (bn - rn) / d + 2
                    : (rn - gn) / d + 4;
                h *= 60;
            }
            return `hsl(${Math.round(h)}, ${Math.round(s * 100)}%, ${Math.round(l * 100)}%)`;
        }
        return hex;
    }

    function copy(hex, fmt) {
        const text = formatColor(hex, fmt ?? format);
        Quickshell.execDetached(["wl-copy", text]);
        history = [hex, ...history.filter(h => h !== hex)].slice(0, maxHistory);
        save();
        notifyProc.command = ["sh", "-c", `
            swatch="$1/color-swatch.png"
            magick -size 96x96 xc:"$2" "$swatch" 2>/dev/null
            notify-send -a "Color Picker" -i "$swatch" "$2" "Copied $3"
        `, "sh", cacheDir, hex, text];
        notifyProc.running = true;
        picked(hex);
    }

    function pick(r, g, b) {
        if (!active)
            return;
        active = false;
        cleanup(frozenPath);
        copy(toHex(r, g, b));
    }

    function save() {
        store.setText(JSON.stringify({ format: format, history: history }));
    }

    function cleanup(path) {
        if (path)
            Quickshell.execDetached(["rm", "-f", path]);
    }

    Component.onCompleted: store.reload()

    FileView {
        id: store
        path: root.stateFile
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (root.formats.includes(data.format))
                    root.format = data.format;
                if (Array.isArray(data.history))
                    root.history = data.history.filter(h => /^#[0-9a-f]{6}$/i.test(h)).slice(0, root.maxHistory);
            } catch (e) {}
        }
    }

    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "-j"]
        property int monitorX: 0
        property int monitorY: 0
        stdout: StdioCollector {
            onStreamFinished: {
                let monitors = [];
                try {
                    monitors = JSON.parse(text);
                } catch (e) {}
                const m = monitors.find(x => x.focused) ?? monitors[0];
                if (!m) {
                    root.busy = false;
                    return;
                }
                root.screenName = m.name;
                root.screenScale = m.scale;
                root.pixelWidth = m.width;
                root.pixelHeight = m.height;
                root.frozenPath = `/tmp/qs-colorpicker-${Date.now()}.png`;
                monitorsProc.monitorX = m.x;
                monitorsProc.monitorY = m.y;
                cursorProc.running = true;
                freezeProc.command = ["sh", "-c", 'mkdir -p "$1" && grim -o "$2" "$3"', "sh", root.cacheDir, m.name, root.frozenPath];
                freezeProc.running = true;
            }
        }
    }

    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const c = JSON.parse(text);
                    root.startX = (c.x - monitorsProc.monitorX) * root.screenScale;
                    root.startY = (c.y - monitorsProc.monitorY) * root.screenScale;
                } catch (e) {}
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
        id: notifyProc
    }
}
