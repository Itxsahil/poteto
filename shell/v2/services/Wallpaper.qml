pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wallpapers: every image in ~/Pictures/wallpapers (that folder only, not below it), with cached
// thumbnails, and setting one with awww. The lock screen follows: hyprlock reads the path from
// lockWallpaperFile. modules/wallpaper/WallpaperContent.qml is the picker.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string folder: home + "/Pictures/wallpapers"
    readonly property string thumbDir: home + "/.cache/quickshell/wallpaper-thumbs"
    // The lock screen's background: dotfiles/hypr/hyprlock.conf sources this file and uses
    // $wallpaper, so picking a wallpaper never edits the tracked config
    readonly property string lockWallpaperFile: home + "/.cache/quickshell/hyprlock-wallpaper.conf"

    // { path, thumb, hasThumb, label }
    property var wallpapers: []
    property string current: ""
    property bool loading: false
    property bool generating: false
    // Bumped when new thumbnails are written, so images showing an old one reload
    property int thumbsVersion: 0
    // Paths a thumbnail was already tried for, so one that cannot be made is not retried forever
    property var thumbAttempted: ({})

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
            if (code !== 0) {
                // Show what is really on screen rather than what was asked for
                queryProc.running = true;
                return;
            }
            root.syncLockScreen(target);
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
