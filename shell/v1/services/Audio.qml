pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Where sound goes and where it comes from, as a flat list of places you can pick.
//
// Two different things decide that, and a picker that knows only one of them is wrong half the
// time. Separate devices — Bluetooth headphones, HDMI, a USB interface — are PipeWire nodes.
// But the speakers and the headphone jack on one sound card are *ports* on a single node, which
// PipeWire does not expose, so plugging in wired earphones changes nothing about the node list.
// This merges both: a node with several usable ports contributes one entry per port, any other
// node contributes itself.
Singleton {
    id: root

    // { key, label, node, port, active }; port is "" when the entry is a whole device
    readonly property var outputs: build(devices.filter(node => node.isSink), portsBySink, output)
    readonly property var inputs: build(devices.filter(node => !node.isSink), portsBySource, input)

    readonly property PwNode output: Pipewire.defaultAudioSink
    readonly property PwNode input: Pipewire.defaultAudioSource

    readonly property var devices: Pipewire.nodes.values.filter(node => !node.isStream && node.audio)

    // name -> { activePort, ports: [{ name, label }] }, filled in from pactl
    property var portsBySink: ({})
    property var portsBySource: ({})

    // A node only fills in its description and volume while something is tracking it, and the
    // picker shows every device, not just the two in use.
    PwObjectTracker {
        objects: root.devices
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
                        node: node,
                        port: port.name,
                        available: port.available,
                        active: current && node.id === current.id && ports.activePort === port.name
                    });
                }
            } else {
                entries.push({
                    key: node.name,
                    label: label(node),
                    node: node,
                    port: "",
                    available: true,
                    active: current !== null && node.id === current.id
                });
            }
        }
        return entries;
    }

    // "ALC256 Analog" reads better on a chip than "Built-in Audio Analog Stereo"
    function label(node) {
        if (!node)
            return "";
        return node.nickname || node.description || node.name;
    }

    function select(entry) {
        if (!entry || !entry.available)
            return;
        const sink = entry.node.isSink;
        if (sink)
            Pipewire.preferredDefaultAudioSink = entry.node;
        else
            Pipewire.preferredDefaultAudioSource = entry.node;
        if (entry.port) {
            setPort.command = ["pactl", sink ? "set-sink-port" : "set-source-port",
                entry.node.name, entry.port];
            setPort.running = true;
        }
    }

    Process {
        id: setPort
        onExited: readPorts.running = true
    }

    // Ports are a PulseAudio-level concept; pactl is the only thing that reports and sets them.
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

            // A port marked "not available" is the far side of a switch — the speakers while the
            // headphone jack is occupied. It is kept in the list so you can still see where sound
            // goes and why, but it is not offered as a choice: the codec mutes that amplifier in
            // hardware, so routing to it produces silence rather than an output.
            function collect(list) {
                const map = {};
                for (const device of list ?? []) {
                    map[device.name] = {
                        activePort: device.active_port ?? "",
                        ports: (device.ports ?? []).map(port => ({
                            name: port.name,
                            label: port.description,
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
    }

    Timer {
        id: debounce
        interval: 150
        onTriggered: readPorts.running = true
    }
}
