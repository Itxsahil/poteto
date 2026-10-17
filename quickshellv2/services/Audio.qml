pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// The default audio output's and input's (the mic's) volume and mute, through PipeWire. Follows
// whatever changes them elsewhere (the volume and mic-mute keys, pavucontrol), so a slider showing
// them never goes stale, and the OSD (services/Osd.qml) shows output changes.
//
// Also every place sound can go and come from, as one flat list each (outputs, inputs) for the
// control center's Audio page. Two things decide that: separate devices (Bluetooth headphones,
// HDMI, a USB headset) are PipeWire nodes, but the speakers and the headphone jack on one sound
// card are ports of a single node, which only pactl reports. A node with several ports gives one
// entry per port; any other node gives itself.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool available: sink?.audio !== undefined && sink?.audio !== null
    // 0–200: past 100 is a boost, as far as the volume key goes (wpctl -l 2 in hypr/bindings.lua)
    readonly property real maxPercent: 200
    // Rounded: PipeWire floats drift (100.0000001 after a few 5% steps), which would otherwise
    // read as a sliver of boost at exactly 100
    readonly property real percent: Math.round((sink?.audio?.volume ?? 0) * 1000) / 10
    readonly property bool muted: sink?.audio?.muted ?? false

    function setPercent(v) {
        if (!sink?.audio)
            return;
        sink.audio.volume = Math.max(0, Math.min(maxPercent, v)) / 100;
        // Turning it up from muted means wanting to hear it
        if (v > 0 && sink.audio.muted)
            sink.audio.muted = false;
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    // The mic: the default input, 0–100 (no boost: past 100 a mic only distorts)
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool micAvailable: !!source?.audio
    readonly property real micPercent: Math.round((source?.audio?.volume ?? 0) * 1000) / 10
    readonly property bool micMuted: source?.audio?.muted ?? false

    function setMicPercent(v) {
        if (!source?.audio)
            return;
        source.audio.volume = Math.max(0, Math.min(100, v)) / 100;
        // Turning it up from muted means wanting to be heard
        if (v > 0 && source.audio.muted)
            source.audio.muted = false;
    }

    function toggleMicMute() {
        if (source?.audio)
            source.audio.muted = !source.audio.muted;
    }

    // { key, label, detail, kind, node, port, available, active }; port is "" for a whole device,
    // kind is what it is ("speaker", "headphones", "headset", "hdmi", "bluetooth", "usb", "mic")
    readonly property var outputs: build(devices.filter(node => node.isSink), portsBySink, sink)
    readonly property var inputs: build(devices.filter(node => !node.isSink), portsBySource, source)
    readonly property var devices: Pipewire.nodes.values.filter(node => !node.isStream && node.audio)

    // node name -> { activePort, ports: [{ name, label, type, available }] }, from pactl
    property var portsBySink: ({})
    property var portsBySource: ({})

    // What a device or port is, from the port's type or the node's name
    function kindOf(node, port) {
        const t = (port?.type ?? "").toLowerCase();
        const name = (node?.name ?? "").toLowerCase();
        if (name.startsWith("bluez"))
            return "bluetooth";
        if (t === "headphones" || /headphone/.test(port?.name ?? ""))
            return "headphones";
        if (t === "headset" || /headset/.test(port?.name ?? ""))
            return "headset";
        if (t === "hdmi" || t === "displayport" || /hdmi|displayport/.test(name))
            return "hdmi";
        if (/usb/.test(name))
            return "usb";
        return node?.isSink ? "speaker" : "mic";
    }

    // The icon for a kind of device
    function glyphFor(kind) {
        return kind === "headphones" ? "󰋋"
            : kind === "headset" ? "󰋎"
            : kind === "bluetooth" ? "󰂰"
            : kind === "hdmi" ? "󰍹"
            : kind === "usb" ? "󰕓"
            : kind === "mic" ? "󰍬"
            : "󰓃";
    }

    // The entries in use, for the control center's slider buttons
    readonly property var activeOutput: outputs.find(e => e.active) ?? null
    readonly property var activeInput: inputs.find(e => e.active) ?? null

    // "ALC256 Analog" reads better than "Built-in Audio Analog Stereo"
    function label(node) {
        return node ? node.nickname || node.description || node.name : "";
    }

    function build(nodes, portMap, current) {
        const entries = [];
        for (const node of nodes) {
            const ports = portMap[node.name] ?? null;
            const list = ports ? ports.ports : [];
            if (list.length > 1) {
                for (const port of list) {
                    entries.push({
                        key: node.name + "/" + port.name,
                        label: port.label,
                        // "Built-in Audio", not "Built-in Audio Analog Stereo"
                        detail: (node.description || "").replace(/\s+(Analog|Digital|Pro)\b.*$/, ""),
                        kind: kindOf(node, port),
                        node: node,
                        port: port.name,
                        available: port.available,
                        active: !!current && node.id === current.id && ports.activePort === port.name
                    });
                }
            } else {
                entries.push({
                    key: node.name,
                    label: label(node),
                    detail: node.name.startsWith("bluez") ? "Bluetooth" : (node.description !== label(node) ? node.description : ""),
                    kind: kindOf(node, list[0] ?? null),
                    node: node,
                    port: "",
                    available: true,
                    active: !!current && node.id === current.id
                });
            }
        }
        return entries;
    }

    // Make an entry the one in use: the default device, and its port if it is one
    function select(entry) {
        if (!entry || !entry.available)
            return;
        const isSink = entry.node.isSink;
        if (isSink)
            Pipewire.preferredDefaultAudioSink = entry.node;
        else
            Pipewire.preferredDefaultAudioSource = entry.node;
        if (entry.port) {
            setPort.command = ["pactl", isSink ? "set-sink-port" : "set-source-port", entry.node.name, entry.port];
            setPort.running = true;
        }
    }

    // A node only reports its volume (and description) while something is tracking it; the list
    // shows every device, not just the two in use
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.devices]
    }

    Process {
        id: setPort
        onExited: readPorts.running = true
    }

    // Ports are a PulseAudio-level idea; pactl is what reports and sets them
    Process {
        id: readPorts
        running: true
        command: ["sh", "-c",
            `printf '{"sinks":%s,"sources":%s}' "$(pactl -f json list sinks)" "$(pactl -f json list sources)"`]

        stdout: StdioCollector {
            onStreamFinished: {
                let parsed;
                try {
                    parsed = JSON.parse(text);
                } catch (e) {
                    console.warn("Audio: could not read ports", e);
                    return;
                }
                root.portsBySink = collect(parsed.sinks);
                root.portsBySource = collect(parsed.sources);
            }

            // A port marked "not available" is the far side of a jack switch: the headphones while
            // nothing is plugged in, or the speakers while something is. It is listed but cannot
            // be chosen: the codec cuts that path in hardware, and PipeWire then drops the device
            // as the default output altogether, so choosing it only gives silence.
            function collect(list) {
                const map = {};
                for (const device of list ?? []) {
                    map[device.name] = {
                        activePort: device.active_port ?? "",
                        ports: (device.ports ?? []).map(port => ({
                            name: port.name,
                            label: port.description,
                            type: port.type ?? "",
                            available: port.availability !== "not available"
                        }))
                    };
                }
                return map;
            }
        }
    }

    // Plugging a jack in or out, or connecting headphones, is a card event rather than a node one
    Process {
        id: watcher
        running: true
        command: ["pactl", "subscribe"]

        stdout: SplitParser {
            onRead: line => {
                if (/ on (card|sink|source)/.test(line))
                    debounce.restart();
            }
        }

        onExited: watcherRestart.restart()
    }

    Timer {
        id: watcherRestart
        interval: 3000
        onTriggered: watcher.running = true
    }

    Timer {
        id: debounce
        interval: 150
        onTriggered: readPorts.running = true
    }
}
