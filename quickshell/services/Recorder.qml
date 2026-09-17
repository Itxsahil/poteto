pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string outDir: home + "/Videos/Recordings"
    readonly property string stateFile: home + "/.cache/quickshell/recorder.json"

    property bool selecting: false
    property string mode: "screen"
    property bool systemAudio: true
    property bool mic: false

    property string screenName: ""
    property int monitorX: 0
    property int monitorY: 0

    property bool recording: false
    property bool finishing: false
    property double startedAt: 0
    property int elapsed: 0
    property string encoder: "libx264"

    property string defaultName: ""
    property var chosenName: null
    property var pending: null

    signal nameRequested()

    function toggle() {
        if (recording)
            stop();
        else if (selecting)
            cancel();
        else
            open();
    }

    function open() {
        if (recording || finishing || selecting)
            return;
        monitorsProc.running = true;
    }

    function cancel() {
        selecting = false;
    }

    function setMode(m) {
        mode = m;
        save();
    }

    function setSystemAudio(on) {
        systemAudio = on;
        save();
    }

    function setMic(on) {
        mic = on;
        save();
    }

    // x, y, w, h are logical coordinates local to the selected monitor
    function startRegion(x, y, w, h) {
        begin(["-g", `${Math.round(monitorX + x)},${Math.round(monitorY + y)} ${Math.round(w)}x${Math.round(h)}`]);
    }

    function startScreen() {
        begin(["-o", screenName]);
    }

    function begin(target) {
        if (!selecting)
            return;
        selecting = false;
        launch.target = target;
        launch.restart();
    }

    function stop() {
        if (!recording)
            return;
        recording = false;
        finishing = true;
        chosenName = null;
        pending = null;
        recordProc.signal(15);
        nameRequested();
    }

    function submitName(name) {
        if (chosenName !== null)
            return;
        chosenName = (name ?? "").trim();
        finalize();
    }

    function sanitize(name) {
        let clean = name.replace(/[\/\x00-\x1f]/g, "-").replace(/^\.+/, "").trim();
        if (!clean)
            clean = defaultName;
        return clean.toLowerCase().endsWith(".mp4") ? clean : clean + ".mp4";
    }

    function finalize() {
        if (chosenName === null || pending === null)
            return;
        const job = pending;
        pending = null;
        finalizeProc.command = ["bash", "-c", finalizeProc.script, "bash",
            job.path, job.thumb, String(job.length), job.tmp, sanitize(chosenName)];
        finalizeProc.running = true;
    }

    function formatElapsed(seconds) {
        const h = Math.floor(seconds / 3600), m = Math.floor(seconds / 60) % 60, s = seconds % 60;
        const mm = String(m).padStart(h ? 2 : 1, "0"), ss = String(s).padStart(2, "0");
        return h ? `${h}:${mm}:${ss}` : `${mm}:${ss}`;
    }

    function save() {
        store.setText(JSON.stringify({ mode: mode, systemAudio: systemAudio, mic: mic }));
    }

    Component.onCompleted: {
        store.reload();
        encoderProbe.running = true;
    }

    FileView {
        id: store
        path: root.stateFile
        printErrors: false
        onLoaded: {
            try {
                const data = JSON.parse(text());
                if (data.mode === "screen" || data.mode === "region")
                    root.mode = data.mode;
                root.systemAudio = data.systemAudio ?? root.systemAudio;
                root.mic = data.mic ?? root.mic;
            } catch (e) {}
        }
    }

    Process {
        id: encoderProbe
        command: ["ffmpeg", "-hide_banner", "-loglevel", "error", "-f", "lavfi", "-i", "color=black:size=320x240:rate=30",
            "-t", "0.2", "-c:v", "h264_nvenc", "-f", "null", "-"]
        onExited: code => root.encoder = code === 0 ? "h264_nvenc" : "libx264"
    }

    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let monitors = [];
                try {
                    monitors = JSON.parse(text);
                } catch (e) {}
                const m = monitors.find(x => x.focused) ?? monitors[0];
                if (!m)
                    return;
                root.screenName = m.name;
                root.monitorX = m.x;
                root.monitorY = m.y;
                root.selecting = true;
            }
        }
    }

    // Wait for the selection overlay to disappear so it never ends up in the recording.
    Timer {
        id: launch
        property var target: []
        interval: 250
        onTriggered: {
            const video = root.encoder === "h264_nvenc"
                ? ["-c", "h264_nvenc", "-p", "preset=p5", "-p", "tune=hq", "-p", "rc=vbr", "-p", "cq=19", "-p", "b=0"]
                : ["-c", "libx264", "-p", "preset=veryfast", "-p", "crf=18"];
            root.defaultName = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
            root.chosenName = null;
            root.pending = null;
            recordProc.command = ["bash", "-c", recordProc.script, "bash",
                root.outDir, root.defaultName, root.systemAudio ? "1" : "0", root.mic ? "1" : "0",
                ...target, "--", ...video];
            root.elapsed = 0;
            root.startedAt = Date.now();
            root.recording = true;
            recordProc.running = true;
        }
    }

    Process {
        id: recordProc

        readonly property string script: `
            set -m
            outdir="$1"; stamp="$2"; sys="$3"; mic="$4"; shift 4
            target=()
            while [ "$1" != "--" ]; do target+=("$1"); shift; done
            shift
            codec=("$@")

            mkdir -p "$outdir"
            out="$outdir/$stamp.mp4"
            tmp=$(mktemp -d)
            video="$tmp/video.mkv"
            audio="$tmp/audio.mka"

            inputs=()
            if [ "$sys" = 1 ]; then inputs+=(-f pulse -i "$(pactl get-default-sink).monitor"); fi
            if [ "$mic" = 1 ]; then inputs+=(-f pulse -i "$(pactl get-default-source)"); fi
            count=$(( ${"$"}{#inputs[@]} / 4 ))

            wf-recorder "${"$"}{target[@]}" "${"$"}{codec[@]}" -r 60 -y -f "$video" >"$tmp/video.log" 2>&1 &
            vpid=$!
            apid=""
            if [ "$count" -gt 0 ]; then
                mix=()
                [ "$count" -gt 1 ] && mix=(-filter_complex "amix=inputs=$count:duration=longest:normalize=0")
                ffmpeg -hide_banner -loglevel error -nostdin "${"$"}{inputs[@]}" "${"$"}{mix[@]}" -c:a flac -y "$audio" >"$tmp/audio.log" 2>&1 &
                apid=$!
            fi

            trap 'kill -TERM $vpid $apid 2>/dev/null' TERM INT
            while kill -0 $vpid 2>/dev/null || { [ -n "$apid" ] && kill -0 $apid 2>/dev/null; }; do
                wait 2>/dev/null
            done

            if [ ! -s "$video" ]; then
                echo "__FAILED__$(tail -n 3 "$tmp/video.log" | tr '\\n' ' ')"
                rm -rf "$tmp"
                exit 1
            fi

            if [ -n "$apid" ] && [ -s "$audio" ]; then
                ffmpeg -hide_banner -loglevel error -nostdin -i "$video" -i "$audio" -map 0:v:0 -map 1:a:0 \\
                    -c:v copy -c:a aac -b:a 192k -shortest -movflags +faststart -y "$out"
            else
                ffmpeg -hide_banner -loglevel error -nostdin -i "$video" -c copy -movflags +faststart -y "$out"
            fi
            [ -s "$out" ] || { echo "__FAILED__could not write $out"; rm -rf "$tmp"; exit 1; }

            thumb="$tmp/thumb.png"
            ffmpeg -hide_banner -loglevel error -nostdin -ss 0.5 -i "$out" -frames:v 1 -vf scale=256:-1 -y "$thumb" 2>/dev/null
            length=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out" | cut -d. -f1)
            printf '__SAVED__%s\\t%s\\t%s\\t%s\\n' "$out" "$thumb" "\${length:-0}" "$tmp"
        `

        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("__FAILED__")) {
                    root.chosenName = "";
                    ShellState.close("recordname");
                    Quickshell.execDetached(["notify-send", "-u", "critical", "-a", "Screen Recorder", "Recording failed", line.slice(10) || "wf-recorder exited"]);
                } else if (line.startsWith("__SAVED__")) {
                    const [path, thumb, length, tmp] = line.slice(9).split("\t");
                    if (!root.finishing) {
                        root.finishing = true;
                        root.chosenName = "";
                    }
                    root.pending = { path: path, thumb: thumb, length: parseInt(length) || 0, tmp: tmp };
                    root.finalize();
                }
            }
        }

        onRunningChanged: {
            if (!running) {
                root.recording = false;
                if (root.pending === null && !finalizeProc.running)
                    root.finishing = false;
            }
        }
    }

    Process {
        id: finalizeProc

        readonly property string script: `
            set -m
            src="$1"; thumb="$2"; length="$3"; tmp="$4"; name="$5"
            dir=$(dirname "$src")
            dest="$dir/$name"
            if [ "$dest" != "$src" ]; then
                base="\${name%.mp4}"; n=2
                while [ -e "$dest" ]; do dest="$dir/$base-$n.mp4"; n=$((n + 1)); done
                mv -- "$src" "$dest" || dest="$src"
            fi
            echo "__FINAL__$dest"
            (
                icon="$thumb"; [ -s "$icon" ] || icon=video-x-generic
                action=$(notify-send -a "Screen Recorder" -i "$icon" -A default=Open -A open=Open -A folder="Show in folder" \\
                    "Recording saved" "$(basename "$dest") · $(( length / 60 )):$(printf %02d $(( length % 60 )))" --wait)
                case "$action" in
                    default|open) xdg-open "$dest" ;;
                    folder)
                        uri=$(python3 -c 'import pathlib, sys; print(pathlib.Path(sys.argv[1]).as_uri())' "$dest")
                        busctl --user call org.freedesktop.FileManager1 /org/freedesktop/FileManager1 \\
                            org.freedesktop.FileManager1 ShowItems ass 1 "$uri" "" \\
                            || nautilus --select "$dest" ;;
                esac
                rm -rf "$tmp"
            ) >/dev/null 2>&1 &
        `

        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("__FINAL__"))
                    console.log("Recorder: saved", line.slice(9));
            }
        }

        onRunningChanged: {
            if (!running)
                root.finishing = false;
        }
    }

    Timer {
        running: root.recording
        interval: 1000
        repeat: true
        onTriggered: root.elapsed = Math.floor((Date.now() - root.startedAt) / 1000)
    }
}
