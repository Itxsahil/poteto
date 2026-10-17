pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// The default audio output's and input's (the mic's) volume and mute, through PipeWire. Follows
// whatever changes them elsewhere (the volume and mic-mute keys, pavucontrol), so a slider showing
// them never goes stale, and the OSD (services/Osd.qml) shows output changes.
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

    // A node only reports its volume while something is tracking it
    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
