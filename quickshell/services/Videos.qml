pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Browses a folder tree of videos for the launcher: entries, cached poster frames
// and durations (one ffmpeg + ffprobe pass per file, kept in ~/.cache).
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string rootDir: home + "/Videos"
    readonly property string thumbDir: home + "/.cache/quickshell/video-thumbs"

    property var entries: []
    property bool loading: false
    property bool generating: false
    property int thumbsVersion: 0
    property var thumbAttempted: ({})

    // Folder names (relative to ~/Videos) that actually hold videos, with counts
    readonly property var folders: {
        const counts = {};
        for (const e of entries)
            counts[e.folder] = (counts[e.folder] ?? 0) + 1;
        // "." stands for videos sitting directly in ~/Videos: an empty value would collide
        // with the "All" chip, which filters nothing.
        return Object.keys(counts).sort((a, b) => a.localeCompare(b))
            .map(name => ({ name: name || "Loose files", value: name || ".", count: counts[name] }));
    }

    function refresh() {
        if (listProc.running)
            return;
        loading = true;
        listProc.running = true;
    }

    function formatSize(bytes) {
        if (bytes >= 1073741824)
            return (bytes / 1073741824).toFixed(1) + " GB";
        if (bytes >= 1048576)
            return Math.round(bytes / 1048576) + " MB";
        return Math.max(1, Math.round(bytes / 1024)) + " KB";
    }

    function formatDuration(seconds) {
        if (!(seconds > 0))
            return "";
        const s = Math.round(seconds);
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = String(s % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${sec}` : `${m}:${sec}`;
    }

    Component.onCompleted: refresh()

    Process {
        id: listProc
        command: ["sh", "-c", `
            dir="$1"; cache="$2"
            mkdir -p "$cache"
            [ -d "$dir" ] || exit 0
            # Every video under ~/Videos, not one folder at a time: the grid shows them all and
            # the chips filter by folder, the way the wallpaper switcher does.
            find "$dir" -mindepth 1 -maxdepth 4 -type f -not -path '*/.*' -printf '%s\\t%T@\\t%p\\n' 2>/dev/null |
            while IFS="$(printf '\\t')" read -r size mtime path; do
                name=\${path##*/}
                ext=$(printf '%s' "\${name##*.}" | tr 'A-Z' 'a-z')
                case "$ext" in
                    mp4|mkv|webm|avi|mov|m4v|flv|wmv|ts|mpg|mpeg|ogv|3gp) ;;
                    *) continue ;;
                esac
                rel=\${path#"$dir"/}
                folder=\${rel%/*}
                [ "$folder" = "$rel" ] && folder=""
                h=$(printf '%s' "$path" | md5sum | cut -d' ' -f1)
                thumb="$cache/$h.jpg"
                ok=0
                [ -s "$thumb" ] && [ "$thumb" -nt "$path" ] && ok=1
                dur=""
                [ -f "$cache/$h.dur" ] && dur=$(cat "$cache/$h.dur")
                printf '%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\t%s\\n' \\
                    "$size" "\${mtime%%.*}" "$name" "$path" "$folder" "$thumb" "$ok" "$dur"
            done
        `, "sh", root.rootDir, root.thumbDir]

        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                const missing = [];
                for (const line of text.split("\n")) {
                    const f = line.split("\t");
                    if (f.length < 8)
                        continue;
                    const [size, mtime, name, path, folder, thumb, ok, dur] = f;
                    list.push({
                        name: name,
                        path: path,
                        folder: folder,
                        folderName: folder ? folder.split("/").pop() : "",
                        size: parseInt(size) || 0,
                        mtime: parseInt(mtime) || 0,
                        thumb: thumb,
                        hasThumb: ok === "1",
                        duration: parseFloat(dur) || 0
                    });
                    if (ok !== "1" && !root.thumbAttempted[path])
                        missing.push(path, thumb.replace(/\.jpg$/, ""));
                }
                root.entries = list.sort((a, b) => b.mtime - a.mtime);
                root.loading = false;

                if (missing.length && !thumbProc.running) {
                    thumbProc.command = ["sh", "-c", `
                        while [ $# -gt 1 ]; do printf '%s\\0%s\\0' "$1" "$2"; shift 2; done |
                        xargs -0 -n2 -P3 sh -c '
                            dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$0" 2>/dev/null)
                            printf "%s" "\${dur:-0}" > "$1.dur"
                            ss=$(awk -v d="\${dur:-0}" "BEGIN { printf \\"%.2f\\", (d > 60 ? d * 0.15 : (d > 4 ? 2 : 0)) }")
                            ffmpeg -loglevel error -ss "$ss" -i "$0" -frames:v 1 -vf scale=320:-2 -q:v 4 -y "$1.jpg" 2>/dev/null
                        '
                    `, "sh", ...missing];
                    // Only now: a batch dropped because one was already running must be retried
                    // on the next scan, not written off as attempted.
                    for (let i = 0; i < missing.length; i += 2)
                        root.thumbAttempted[missing[i]] = true;
                    root.generating = true;
                    thumbProc.running = true;
                }
            }
        }
    }

    Process {
        id: thumbProc
        onExited: {
            root.generating = false;
            root.thumbsVersion++;
            root.refresh();
        }
    }
}
