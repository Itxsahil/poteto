import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.config
import qs.components
import qs.components.icons

ControlSlider {
    id: root

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool muted: source?.audio?.muted ?? false

    value: Math.min(1, source?.audio?.volume ?? 0)
    dimmed: muted
    label: !source ? "No mic" : muted ? "Muted" : Math.round(value * 100) + "%"

    onMoved: v => {
        if (!source?.audio)
            return;
        source.audio.volume = v;
        if (source.audio.muted && v > 0)
            source.audio.muted = false;
    }
    onRightClicked: if (source?.audio) source.audio.muted = !source.audio.muted

    PwObjectTracker {
        objects: [root.source]
    }

    MicIcon {
        anchors.fill: parent
        muted: root.muted
        color: Theme.controlIconOnFill

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
        }
    }
}
