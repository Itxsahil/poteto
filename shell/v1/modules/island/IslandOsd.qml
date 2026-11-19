import QtQuick
import Quickshell.Services.Pipewire
import qs.config
import qs.components.icons
import qs.services

Item {
    id: root

    property bool suppressed: false
    property bool shown: false
    property bool osdVisible: false
    property string kind: "volume"
    readonly property var sinkAudio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var sourceAudio: Pipewire.defaultAudioSource?.audio ?? null

    function trigger(newKind) {
        if (armTimer.running || suppressed)
            return;
        kind = newKind;
        osdVisible = true;
        hideTimer.restart();
    }

    implicitWidth: 240
    implicitHeight: 22

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Connections {
        target: root.sourceAudio
        function onMutedChanged() { root.trigger("mic"); }
    }

    Connections {
        target: root.sinkAudio
        function onVolumeChanged() { root.trigger("volume"); }
        function onMutedChanged() { root.trigger("volume"); }
    }

    Connections {
        target: Brightness
        function onChangedExternally() { root.trigger("brightness"); }
    }

    Timer {
        id: armTimer
        interval: 1500
        running: true
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.osdVisible = false
    }

    Osd {
        id: volumeOsd
        readonly property bool muted: root.sinkAudio?.muted ?? false
        readonly property real volume: root.sinkAudio?.volume ?? 0
        anchors.fill: parent
        level: Math.min(1, volume)
        boost: Math.round(volume * 100) / 100 - 1   // rounded: PipeWire floats drift past 1.0
        dimmed: muted
        label: muted ? "Mute" : Math.round(volume * 100) + "%"
        opacity: root.shown && root.kind === "volume" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        SpeakerIcon {
            anchors.fill: parent
            level: volumeOsd.level
            muted: volumeOsd.muted
        }
    }

    Osd {
        id: micOsd
        readonly property bool muted: root.sourceAudio?.muted ?? false
        anchors.fill: parent
        level: Math.min(1, root.sourceAudio?.volume ?? 0)
        dimmed: muted
        label: muted ? "Off" : Math.round(level * 100) + "%"
        opacity: root.shown && root.kind === "mic" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        MicIcon {
            anchors.fill: parent
            muted: micOsd.muted
            color: micOsd.muted ? Theme.danger : Theme.textPrimary
        }
    }

    Osd {
        anchors.fill: parent
        level: Brightness.value
        opacity: root.shown && root.kind === "brightness" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        SunIcon {
            anchors.fill: parent
        }
    }
}
