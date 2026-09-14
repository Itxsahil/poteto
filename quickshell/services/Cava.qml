pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int barCount: 10
    readonly property string fifo: "/tmp/mpd.fifo"
    readonly property string configFile: Quickshell.env("HOME") + "/.cache/quickshell/cava.conf"

    property bool enabled: false
    property var bars: new Array(barCount).fill(0)

    readonly property string config: `[general]
framerate = 30
bars = ${barCount}
autosens = 1

[input]
method = fifo
source = ${fifo}
sample_rate = 44100
sample_bits = 16

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10

[smoothing]
noise_reduction = 55
`

    onEnabledChanged: {
        if (!enabled)
            bars = new Array(barCount).fill(0);
    }

    Process {
        id: writeConfig
        running: true
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", root.configFile, root.config]
        onExited: code => {
            if (code === 0)
                cava.ready = true;
        }
    }

    Process {
        id: cava
        property bool ready: false
        property bool coolingDown: false
        running: ready && root.enabled && !coolingDown
        command: ["stdbuf", "-o0", "cava", "-p", root.configFile]

        stdout: SplitParser {
            onRead: line => {
                const values = line.split(";").filter(v => v !== "").map(v => Math.min(1, (parseInt(v) || 0) / 100));
                if (values.length === root.barCount)
                    root.bars = values;
            }
        }

        onExited: {
            if (root.enabled) {
                coolingDown = true;
                restart.restart();
            }
        }
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: cava.coolingDown = false
    }
}
