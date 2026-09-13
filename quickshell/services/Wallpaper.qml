pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    property list<string> folders: [
        home + "/Pictures/wallpapers",
        home + "/Pictures/Wallpaper",
        home + "/Pictures/15-12-24-wallpaper",
        home + "/Pictures/ashtetic-wp",
        home + "/Pictures/anime-pic",
        home + "/Pictures/fate-stay-night wallpapers",
        home + "/copyrice/larp/themes"
    ]
    readonly property string thumbDir: home + "/.cache/quickshell/wallpaper-thumbs"
    readonly property string hyprlockConfig: home + "/.config/hypr/hyprlock.conf"

    property var wallpapers: []
    property string current: ""
    property bool loading: false
    property bool generating: false
    property int thumbsVersion: 0

    signal applied(string path)

    function refresh() {
        if (listProc.running)
            return;
        loading = true;
        listProc.running = true;
        queryProc.running = true;
    }

    function folderOf(path) {
        return folders.find(f => path.startsWith(f + "/")) ?? "";
    }

    function labelFor(path) {
        const root_ = folderOf(path);
        const rel = root_ ? path.slice(root_.length + 1) : path.split("/").pop();
        const parts = rel.split("/");
        const file = parts.pop().replace(/\.[^.]+$/, "");
        return parts.length ? `${parts.join("/")} · ${file}` : file;
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
            cache="$1"; shift
            mkdir -p "$cache"
            existing=""
            for d in "$@"; do [ -d "$d" ] && existing="yes"; done
            [ -z "$existing" ] && exit 0
            find "$@" -maxdepth 2 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \\) 2>/dev/null | sort -u |
            while IFS= read -r f; do
                h=$(printf '%s' "$f" | md5sum | cut -d' ' -f1)
                t="$cache/$h.jpg"
                if [ -s "$t" ]; then e=1; else e=0; fi
                printf '%s\\t%s\\t%s\\n' "$f" "$t" "$e"
            done
        `, "sh", root.thumbDir, ...root.folders]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                const missing = [];
                for (const line of text.split("\n")) {
                    const [path, thumb, exists] = line.split("\t");
                    if (!path || !thumb)
                        continue;
                    const folder = root.folderOf(path);
                    list.push({
                        path: path,
                        thumb: thumb,
                        hasThumb: exists === "1",
                        folder: folder,
                        folderName: folder.split("/").pop(),
                        label: root.labelFor(path)
                    });
                    if (exists !== "1")
                        missing.push(path, thumb);
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
            root.wallpapers = root.wallpapers.map(w => Object.assign({}, w, { hasThumb: true }));
            root.thumbsVersion++;
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
            if (code === 0) {
                root.applied(target);
                hyprlockProc.command = ["sh", "-c", `
                    conf="$1"; wall="$2"
                    [ -f "$conf" ] || exit 0
                    tmp=$(mktemp) || exit 1
                    WALL="$wall" awk '
                        /^[[:space:]]*background[[:space:]]*\{/ { inbg = 1 }
                        inbg && /^[[:space:]]*path[[:space:]]*=/ { print substr($0, 1, index($0, "=")) " " ENVIRON["WALL"]; next }
                        inbg && /\}/ { inbg = 0 }
                        { print }
                    ' "$conf" > "$tmp" && cat "$tmp" > "$conf"
                    rm -f "$tmp"
                `, "sh", root.hyprlockConfig, target];
                hyprlockProc.running = true;
            } else {
                queryProc.running = true;
            }
        }
    }

    Process {
        id: hyprlockProc
    }
}
