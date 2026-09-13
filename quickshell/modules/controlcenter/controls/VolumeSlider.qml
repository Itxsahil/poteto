import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.config
import qs.components
import qs.components.icons

ControlSlider {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false

    value: Math.min(1, sink?.audio?.volume ?? 0)
    dimmed: muted
    label: muted ? "Muted" : Math.round(value * 100) + "%"

    onMoved: v => {
        if (!sink?.audio)
            return;
        sink.audio.volume = v;
        if (sink.audio.muted && v > 0)
            sink.audio.muted = false;
    }
    onRightClicked: if (sink?.audio) sink.audio.muted = !sink.audio.muted

    PwObjectTracker {
        objects: [root.sink]
    }

    SpeakerIcon {
        anchors.fill: parent
        level: root.value
        muted: root.muted
        color: Theme.controlIconOnFill
    }
}
