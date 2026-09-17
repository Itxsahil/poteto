pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string host: {
        const env = Quickshell.env("MPD_HOST") ?? "";
        return env && !env.startsWith("/") && !env.includes("@") ? env : "127.0.0.1";
    }
    readonly property string port: Quickshell.env("MPD_PORT") || "6600"

    property bool connected: false
    property string state: "stop"
    property string title: ""
    property string artist: ""
    property string album: ""
    property real elapsed: 0
    property real duration: 0

    readonly property bool playing: connected && state === "play"
    readonly property bool active: connected && state !== "stop" && title !== ""

    function toggle() {
        send(state === "stop" ? "play" : "pause");
    }

    function next() {
        send("next");
    }

    function previous() {
        send("previous");
    }

    function send(command) {
        Quickshell.execDetached(["bash", "-c", `
            exec 3<>/dev/tcp/"$1"/"$2" || exit 1
            read -r -u 3 _
            printf '%s\\nclose\\n' "$3" >&3
            cat <&3 >/dev/null
        `, "bash", host, port, command]);
    }

    function applyBlock(fields) {
        root.state = fields.state ?? "stop";
        root.elapsed = parseFloat(fields.elapsed ?? "0") || 0;
        root.duration = parseFloat(fields.duration ?? fields.Time ?? "0") || 0;
        const file = fields.file ?? "";
        root.title = fields.Title || file.split("/").pop().replace(/\.[^.]+$/, "").replace(/\s*\[[\w-]{11}\]$/, "");
        root.artist = (fields.Artist ?? "").replace(/\s+-\s+Topic$/, "");
        root.album = fields.Album ?? "";
    }

    Process {
        id: watcher
        running: true
        command: ["bash", "-c", `
            host="$1"; port="$2"
            exec 3<>/dev/tcp/"$host"/"$port" 2>/dev/null || { echo "__DOWN__"; exit 1; }
            IFS= read -r -u 3 hello || { echo "__DOWN__"; exit 1; }
            while :; do
                printf 'status\\ncurrentsong\\n' >&3 || break
                echo "__BEGIN__"
                oks=0
                while [ "$oks" -lt 2 ] && IFS= read -r -u 3 line; do
                    case "$line" in
                        OK) oks=$((oks + 1)) ;;
                        ACK*) oks=2 ;;
                        *) echo "$line" ;;
                    esac
                done
                [ "$oks" -lt 2 ] && break
                echo "__END__"
                printf 'idle player\\n' >&3 || break
                got=0
                while IFS= read -r -u 3 line; do
                    [ "$line" = "OK" ] && { got=1; break; }
                done
                [ "$got" = 1 ] || break
            done
            echo "__DOWN__"
        `, "bash", root.host, root.port]

        property var block: ({})

        stdout: SplitParser {
            onRead: line => {
                if (line === "__BEGIN__") {
                    watcher.block = {};
                } else if (line === "__END__") {
                    root.connected = true;
                    root.applyBlock(watcher.block);
                } else if (line === "__DOWN__") {
                    root.connected = false;
                } else {
                    const i = line.indexOf(": ");
                    if (i > 0 && !(line.slice(0, i) in watcher.block))
                        watcher.block[line.slice(0, i)] = line.slice(i + 2);
                }
            }
        }

        onExited: {
            root.connected = false;
            reconnect.restart();
        }
    }

    Timer {
        id: reconnect
        interval: 3000
        onTriggered: watcher.running = true
    }

    Timer {
        running: root.playing && root.duration > 0
        interval: 1000
        repeat: true
        onTriggered: root.elapsed = Math.min(root.duration, root.elapsed + 1)
    }
}
