pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The background video of the login screen.
//
// The greeter runs as the sddm user and cannot read a 700 home directory, so the file cannot just
// be pointed at: it is copied into the live theme by the same root helper that switches themes
// (sddm-themes/system/poteto-login-theme, installed by sddm-themes/setup). Switching the whole
// theme afterwards brings that theme's own video back, which is what you would expect.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    // Which folder under ~/Videos the picker offers
    readonly property string folder: "Hidamari"
    readonly property string videoDir: home + "/Videos/" + folder
    // Poster frames, named by the md5 of the video's path (the same cache the old shell used)
    readonly property string thumbDir: home + "/.cache/quickshell/video-thumbs"
    readonly property string helper: "/usr/local/bin/poteto-login-theme"
    readonly property string activeDir: "/usr/share/sddm/themes/poteto"

    // { name, path, thumb, hasThumb }, newest first
    property var videos: []
    property int thumbsVersion: 0
    property var thumbAttempted: ({})

    // The path that was last published, read back from the live theme
    property string current: ""
    property string applying: ""
    property string message: ""
    property bool messageIsError: false

    Component.onCompleted: refresh()

    Connections {
        target: LoginTheme
        function onActiveChanged() {
            if (!readProc.running)
                readProc.running = true;
        }
    }

    function refresh() {
        if (!listProc.running)
            listProc.running = true;
        if (!readProc.running)
            readProc.running = true;
    }

    function apply(path) {
        if (applying || !path)
            return;
        if (!LoginTheme.helperInstalled) {
            say(`Run ${LoginTheme.themesDir || "sddm-themes"}/setup once first`, true);
            return;
        }
        applying = path;
        say("", false);
        applyProc.path = path;
        applyProc.command = ["pkexec", helper, "video", path];
        applyProc.running = true;
    }

    function say(text, isError) {
        message = text;
        messageIsError = isError;
    }

    function name(path) {
        return path ? path.split("/").pop() : "";
    }

    Process {
        id: listProc
        command: ["sh", "-c", `
            dir="$1"; cache="$2"
            mkdir -p "$cache"
            [ -d "$dir" ] || exit 0
            find "$dir" -maxdepth 2 -type f \\( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \\) -printf '%T@\\t%p\\n' 2>/dev/null |
            sort -rn |
            while IFS="$(printf '\\t')" read -r mtime path; do
                h=$(printf '%s' "$path" | md5sum | cut -d' ' -f1)
                thumb="$cache/$h.jpg"
                ok=0
                [ -s "$thumb" ] && [ "$thumb" -nt "$path" ] && ok=1
                printf '%s\\t%s\\t%s\\n' "$path" "$thumb" "$ok"
            done
        `, "sh", root.videoDir, root.thumbDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                const missing = [];
                for (const line of text.split("\n")) {
                    const [path, thumb, ok] = line.split("\t");
                    if (!path || !thumb)
                        continue;
                    list.push({ name: path.split("/").pop(), path: path, thumb: thumb, hasThumb: ok === "1" });
                    if (ok !== "1" && !root.thumbAttempted[path]) {
                        missing.push(path, thumb);
                        root.thumbAttempted[path] = true;
                    }
                }
                root.videos = list;
                if (missing.length && !thumbProc.running) {
                    // A little way in, so a fade-in does not give a black frame
                    thumbProc.command = ["sh", "-c", `
                        while [ $# -gt 1 ]; do printf '%s\\0%s\\0' "$1" "$2"; shift 2; done |
                        xargs -0 -n2 -P3 sh -c 'ffmpeg -loglevel error -ss 2 -i "$0" -frames:v 1 -vf scale=320:-2 -q:v 4 -y "$1" 2>/dev/null'
                    `, "sh", ...missing];
                    thumbProc.running = true;
                }
            }
        }
    }

    Process {
        id: thumbProc
        onExited: {
            root.thumbsVersion++;
            root.refresh();
        }
    }

    Process {
        id: readProc
        command: ["sh", "-c", `cat "$1/.poteto-video" 2>/dev/null || true`, "sh", root.activeDir]
        stdout: StdioCollector {
            onStreamFinished: root.current = text.trim()
        }
    }

    Process {
        id: applyProc
        property string path: ""
        stderr: StdioCollector { id: applyErr }
        onExited: code => {
            const chosen = path;
            root.applying = "";
            if (code === 0) {
                root.current = chosen;
                root.say(`${root.name(chosen)} will play at the next login`, false);
            } else if (code === 126) {
                // pkexec: the password prompt was dismissed
                root.say("Cancelled", false);
            } else if (code === 127) {
                root.say("Not authorized", true);
            } else {
                const err = applyErr.text.trim().split("\n").pop().replace(/^poteto-login-theme: /, "");
                root.say(err || `Could not change the video (exit ${code})`, true);
            }
            root.refresh();
            // The password prompt took the picker's place; bring it back to show the result.
            if (ShellState.view === "")
                ShellState.open("loginvideo");
        }
    }
}
