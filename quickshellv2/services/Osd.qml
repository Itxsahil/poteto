pragma Singleton

import QtQuick
import Quickshell

// The on-screen display: what just changed (the volume, mic-mute or brightness keys, say), shown
// for a moment in the pill, or in the middle of the bar, by modules/osd/OsdContent.qml.
Singleton {
    id: root

    // "volume", "mic" or "brightness"
    property string kind: "brightness"
    property bool shown: false

    function trigger(name) {
        // Not for the readings that come in while the shell starts
        if (startup.running)
            return;
        kind = name;
        shown = true;
        hide.restart();
    }

    Connections {
        target: Audio.sink?.audio ?? null
        function onVolumeChanged() {
            root.trigger("volume");
        }
        function onMutedChanged() {
            root.trigger("volume");
        }
    }

    // The mic: muting or unmuting it (the mic-mute key, or any app)
    Connections {
        target: Audio.source?.audio ?? null
        function onMutedChanged() {
            root.trigger("mic");
        }
    }

    // A different output (headphones plugged in, say) is not a volume change
    Connections {
        target: Audio
        function onSinkChanged() {
            startup.restart();
        }
        function onSourceChanged() {
            startup.restart();
        }
    }

    Connections {
        target: Brightness
        function onChangedExternally() {
            root.trigger("brightness");
        }
    }

    Timer {
        id: startup
        interval: 1500
        running: true
    }

    Timer {
        id: hide
        interval: 1500
        onTriggered: root.shown = false
    }
}
