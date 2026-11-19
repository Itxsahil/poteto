pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpapers: every image in ~/Pictures/wallpapers (that folder only, not below it), with cached
// thumbnails, and setting one with awww. The lock screen follows: hyprlock's background path is
// rewritten to match. modules/wallpaper/WallpaperContent.qml is the picker.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string folder: home + "/Pictures/wallpapers"
    readonly property string thumbDir: home + "/.cache/quickshell/wallpaper-thumbs"
    readonly property string hyprlockConfig: home + "/.config/hypr/hyprlock.conf"

    // { path, thumb, hasThumb, label }
    property var wallpapers: []
    property string current: ""
    property bool loading: false
    property bool generating: false
    // Bumped when new thumbnails are written, so images showing an old one reload
    property int thumbsVersion: 0
    // Paths a thumbnail was already tried for, so one that cannot be made is not retried forever
    property var thumbAttempted: ({})

    function refresh() {
        if (listProc.running)
            return;
        loading = true;
        listProc.running = true;
        queryProc.running = true;
    }

    function apply(path) {
        applyProc.target = path;
        applyProc.command = ["awww", "img", path,
            "--transition-type", "grow",
            "--transition-pos", "top",
            "--transition-duration", "1.1",
            "--transition-fps", "60"];
        applyProc.running = true;
        current = path;
    }

    function applyRandom() {
        const pool = wallpapers.filter(w => w.path !== current);
        if (pool.length)
            apply(pool[Math.floor(Math.random() * pool.length)].path);
    }

    Process {
        id: listProc
        command: ["sh", "-c", `
            cache="$1"; dir="$2"
            mkdir -p "$cache"
            [ -d "$dir" ] || exit 0
            find "$dir" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) 2>/dev/null | sort |
            while IFS= read -r f; do
                h=$(printf '%s' "$f" | md5sum | cut -d' ' -f1)
                t="$cache/$h.jpg"
                if [ -s "$t" ]; then e=1; else e=0; fi
                printf '%s\\t%s\\t%s\\n' "$f" "$t" "$e"
            done
        `, "sh", root.thumbDir, root.folder]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                const missing = [];
                for (const line of text.split("\n")) {
                    const [path, thumb, exists] = line.split("\t");
                    if (!path || !thumb)
                        continue;
                    list.push({
                        path: path,
                        thumb: thumb,
                        hasThumb: exists === "1",
                        label: path.split("/").pop().replace(/\.[^.]+$/, "")
                    });
                    if (exists !== "1" && !root.thumbAttempted[path]) {
                        missing.push(path, thumb);
                        root.thumbAttempted[path] = true;
                    }
                }
                root.wallpapers = list;
                root.loading = false;
                if (missing.length && !genProc.running) {
                    genProc.command = ["sh", "-c", `
                        while [ $# -gt 1 ]; do printf '%s\\0%s\\0' "$1" "$2"; shift 2; done |
                        xargs -0 -n2 -P4 sh -c 'magick "$0[0]" -auto-orient -thumbnail 480x300^ -gravity center -extent 480x300 -quality 82 "$1" 2>/dev/null'
                    `, "sh", ...missing];
                    root.generating = true;
                    genProc.running = true;
                }
            }
        }
    }

    Process {
        id: genProc
        onExited: {
            root.generating = false;
            root.thumbsVersion++;
            root.refresh();
        }
    }

    Process {
        id: queryProc
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/image: (.+)$/m);
                if (m)
                    root.current = m[1].trim();
            }
        }
    }

    Process {
        id: applyProc
        property string target: ""
        onExited: code => {
            if (code !== 0) {
                // Show what is really on screen rather than what was asked for
                queryProc.running = true;
                return;
            }
            hyprlockProc.command = ["sh", "-c", `
                conf="$1"; wall="$2"
                [ -f "$conf" ] || exit 0
                tmp=$(mktemp) || exit 1
                WALL="$wall" awk '
                    /^[[:space:]]*background[[:space:]]*\\{/ { inbg = 1 }
                    inbg && /^[[:space:]]*path[[:space:]]*=/ { print substr($0, 1, index($0, "=")) " " ENVIRON["WALL"]; next }
                    inbg && /\\}/ { inbg = 0 }
                    { print }
                ' "$conf" > "$tmp" && cat "$tmp" > "$conf"
                rm -f "$tmp"
            `, "sh", root.hyprlockConfig, target];
            hyprlockProc.running = true;
        }
    }

    Process {
        id: hyprlockProc
    }
}
