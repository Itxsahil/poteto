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
        home + "/Pictures/wuwa",
        home + "/copyrice/larp/themes"
    ]
    readonly property string thumbDir: home + "/.cache/quickshell/wallpaper-thumbs"
    // The lock screen's background: dotfiles/hypr/hyprlock.conf sources this file and uses
    // $wallpaper, so picking a wallpaper never edits the tracked config
    readonly property string lockWallpaperFile: home + "/.cache/quickshell/hyprlock-wallpaper.conf"

    property var wallpapers: []
    property string current: ""
    property bool loading: false
    property bool generating: false
    property int thumbsVersion: 0
    // The last list's paths and thumbnail states, to tell a real change from the same list again
    property string signature: ""
    property var thumbAttempted: ({})

    signal applied(string path)

    // Learn what awww is showing right away (and point the lock screen at it), not only once the
    // picker opens
    Component.onCompleted: queryProc.running = true

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

    // Points the lock screen at path: writes `$wallpaper = path` for hyprlock, in one step
    // ('#' starts a comment in hyprlock's config, so it is doubled)
    function syncLockScreen(path) {
        if (!path)
            return;
        // One write at a time; the latest path waits for the running one
        if (lockProc.running) {
            lockPending = path;
            return;
        }
        lockProc.command = ["sh", "-c", `
            file="$1"; wall="$2"
            case "$wall" in *"
"*) exit 1 ;; esac
            mkdir -p "$(dirname "$file")"
            tmp="$file.tmp.$$"
            {
                echo "# Written by the shell (services/Wallpaper.qml): the lock screen background"
                printf '$wallpaper = %s\\n' "$(printf '%s' "$wall" | sed 's/#/##/g')"
            } > "$tmp" && mv -f "$tmp" "$file"
        `, "sh", root.lockWallpaperFile, path];
        lockProc.running = true;
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
                    if (exists !== "1" && !root.thumbAttempted[path]) {
                        missing.push(path, thumb);
                        root.thumbAttempted[path] = true;
                    }
                }
                // Only a real change replaces the list: a new array resets the picker's grid, which
                // rebuilds every card and reloads every image, on each open
                const signature = list.map(w => (w.hasThumb ? "1" : "0") + w.path).join("\n");
                if (signature !== root.signature) {
                    root.signature = signature;
                    root.wallpapers = list;
                }
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
                if (m) {
                    root.current = m[1].trim();
                    // Also covers a wallpaper set outside the shell, and the first start
                    root.syncLockScreen(root.current);
                }
            }
        }
    }

    Process {
        id: applyProc
        property string target: ""
        onExited: code => {
            if (code === 0) {
                root.applied(target);
                root.syncLockScreen(target);
            } else {
                queryProc.running = true;
            }
        }
    }

    property string lockPending: ""

    Process {
        id: lockProc
        onExited: {
            if (root.lockPending) {
                const path = root.lockPending;
                root.lockPending = "";
                root.syncLockScreen(path);
            }
        }
    }
}
