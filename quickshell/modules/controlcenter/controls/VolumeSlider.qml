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

    value: sink?.audio?.volume ?? 0
    maxValue: 2          // up to 200%, matching the volume key's wpctl limit
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
        level: root.fill
        muted: root.muted
        color: Theme.controlIconOnFill
    }
}
