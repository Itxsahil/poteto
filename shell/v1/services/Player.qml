pragma Singleton

import QtQuick
import Quickshell

// What the video window is playing. The playlist is whatever sat next to the file.
Singleton {
    id: root

    property string source: ""
    property var playlist: []
    property int index: -1

    // "off" stops at the end of the folder, "one" repeats this video, "all" loops the folder
    property string loop: "off"
    property real speed: 1.0

    readonly property bool hasNext: playlist.length > 1 && (loop === "all" || index < playlist.length - 1)

    function cycleLoop() {
        loop = loop === "off" ? "one" : loop === "one" ? "all" : "off";
    }

    function cycleSpeed(delta) {
        const steps = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
        const i = steps.indexOf(speed);
        const next = i < 0 ? 2 : Math.max(0, Math.min(steps.length - 1, i + delta));
        speed = steps[next];
    }

    readonly property bool playing: source !== ""
    readonly property string title: source ? source.split("/").pop() : ""
    readonly property string url: source ? "file://" + source.split("/").map(encodeURIComponent).join("/") : ""

    function play(path, list) {
        playlist = (list && list.length) ? list : [path];
        index = playlist.indexOf(path);
        source = path;
    }

    function step(delta) {
        if (playlist.length < 2)
            return;
        index = (index + delta + playlist.length) % playlist.length;
        source = playlist[index];
    }

    function next() {
        step(1);
    }

    function previous() {
        step(-1);
    }

    function close() {
        source = "";
        playlist = [];
        index = -1;
        speed = 1.0;
    }

    // For anything the built-in player struggles with (4K AV1 and friends)
    function openExternally(path) {
        Quickshell.execDetached(["mpv", "--", path ?? source]);
    }
}
