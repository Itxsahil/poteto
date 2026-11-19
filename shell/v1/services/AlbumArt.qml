pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Album art for whatever MPD is playing: the picture embedded in the file, or a cover
// image sitting next to it. Extracted once per track and cached in ~/.cache.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string cacheDir: home + "/.cache/quickshell/album-art"
    readonly property string configFile: home + "/.config/mpd/mpd.conf"

    property string musicDir: home + "/Music"
    property string path: ""          // the extracted file, empty while unknown or missing
    property int version: 0           // bumped so Image reloads when a path is reused

    readonly property string source: path ? `file://${path}?v=${version}` : ""

    function refresh() {
        if (!Mpd.file || extractProc.running)
            return;
        extractProc.track = Mpd.file;
        extractProc.running = true;
    }

    onMusicDirChanged: refresh()

    Connections {
        target: Mpd
        function onFileChanged() {
            root.path = "";
            root.refresh();
        }
    }

    Component.onCompleted: musicDirProc.running = true

    // music_directory from mpd.conf, so this works if the library ever moves
    Process {
        id: musicDirProc
        command: ["sh", "-c", `
            conf="$1"
            dir=$(sed -n 's/^[[:space:]]*music_directory[[:space:]]*"\\(.*\\)"[[:space:]]*$/\\1/p' "$conf" 2>/dev/null | tail -n1)
            case "$dir" in "~"*) dir="$HOME\${dir#\\~}" ;; esac
            printf '%s' "\${dir:-$HOME/Music}"
        `, "sh", root.configFile]
        stdout: StdioCollector {
            onStreamFinished: {
                const dir = text.trim();
                if (dir)
                    root.musicDir = dir;
            }
        }
    }

    Process {
        id: extractProc
        property string track: ""
        command: ["sh", "-c", `
            dir="$1"; cache="$2"; track="$3"
            mkdir -p "$cache"
            file="$dir/$track"
            [ -f "$file" ] || exit 0
            h=$(printf '%s' "$track" | md5sum | cut -d' ' -f1)
            art="$cache/$h.jpg"
            if [ -s "$art" ] && [ "$art" -nt "$file" ]; then
                printf '%s' "$art"
                exit 0
            fi
            # the picture stored inside the track, scaled down for a 120px tile
            if ffmpeg -loglevel error -i "$file" -an -frames:v 1 -vf 'scale=320:-2' -y "$art" 2>/dev/null && [ -s "$art" ]; then
                printf '%s' "$art"
                exit 0
            fi
            # otherwise a cover sitting in the same folder
            folder=\${file%/*}
            for name in cover folder front album; do
                for ext in jpg jpeg png webp; do
                    candidate="$folder/$name.$ext"
                    [ -f "$candidate" ] || continue
                    if magick "$candidate" -resize 320x320 -quality 88 "$art" 2>/dev/null && [ -s "$art" ]; then
                        printf '%s' "$art"
                        exit 0
                    fi
                done
            done
            rm -f "$art"
        `, "sh", root.musicDir, root.cacheDir, track]

        stdout: StdioCollector {
            onStreamFinished: {
                const found = text.trim();
                root.path = found;
                if (found)
                    root.version++;
            }
        }

        onExited: {
            // the track changed while we were extracting
            if (Mpd.file && Mpd.file !== track)
                root.refresh();
        }
    }
}
