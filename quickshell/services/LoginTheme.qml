pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// SDDM login themes. Themes live in ../sddm-themes; SDDM always loads the "poteto"
// theme, and switching copies one of them into it through a root-owned helper
// (installed by sddm-themes/setup) that pkexec runs after asking for your password.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string thumbDir: home + "/.cache/quickshell/login-thumbs"
    readonly property string helper: "/usr/local/bin/poteto-login-theme"
    readonly property string activeDir: "/usr/share/sddm/themes/poteto"

    property string themesDir: ""
    property var themes: []
    property string active: ""
    property bool helperInstalled: false
    property string applying: ""
    property string message: ""
    property bool messageIsError: false
    property int thumbsVersion: 0
    property var thumbAttempted: ({})

    function refresh() {
        if (themesDir && !listProc.running)
            listProc.running = true;
    }

    function apply(id) {
        if (applying || id === active)
            return;
        if (!helperInstalled) {
            say(`Run ${themesDir || "sddm-themes"}/setup once first`, true);
            return;
        }
        applying = id;
        say("", false);
        applyProc.themeId = id;
        applyProc.command = ["pkexec", helper, id];
        applyProc.running = true;
    }

    function preview(id) {
        if (themesDir)
            Quickshell.execDetached(["sddm-greeter-qt6", "--test-mode", "--theme", `${themesDir}/${id}`]);
    }

    function say(text, isError) {
        message = text;
        messageIsError = isError;
    }

    Component.onCompleted: resolveProc.running = true

    Process {
        id: resolveProc
        command: ["realpath", "--", Quickshell.shellDir + "/../sddm-themes"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.themesDir = text.trim();
                root.refresh();
            }
        }
    }

    Process {
        id: listProc
        command: ["sh", "-c", `
            themes="$1"; thumbs="$2"; helper="$3"; active="$4"
            mkdir -p "$thumbs"
            if [ -x "$helper" ]; then installed=1; else installed=0; fi
            printf '__HELPER__\t%s\n' "$installed"
            printf '__ACTIVE__\t%s\n' "$(cat "$active/.poteto-source" 2>/dev/null)"
            for dir in "$themes"/*/; do
                dir=\${dir%/}; id=$(basename "$dir")
                [ -f "$dir/metadata.desktop" ] && [ -f "$dir/Main.qml" ] || continue
                case "$id" in *[!a-z0-9-]*|-*) continue ;; esac
                name=$(sed -n 's/^Name=//p' "$dir/metadata.desktop" | head -n1)
                bg=""
                for f in "$dir"/bg.mp4 "$dir"/*.mp4 "$dir"/*.webm "$dir"/*.mkv "$dir"/*.jpg "$dir"/*.png "$dir"/*.webp; do
                    [ -f "$f" ] && { bg="$f"; break; }
                done
                thumb="$thumbs/$id.jpg"
                fresh=0
                [ -n "$bg" ] && [ -s "$thumb" ] && [ "$thumb" -nt "$bg" ] && fresh=1
                printf '%s\t%s\t%s\t%s\t%s\n' "$id" "\${name:-$id}" "$bg" "$thumb" "$fresh"
            done
        `, "sh", root.themesDir, root.thumbDir, root.helper, root.activeDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                const missing = [];
                for (const line of text.split("\n")) {
                    const parts = line.split("\t");
                    if (parts[0] === "__HELPER__") {
                        root.helperInstalled = parts[1] === "1";
                    } else if (parts[0] === "__ACTIVE__") {
                        root.active = (parts[1] ?? "").trim();
                    } else if (parts.length === 5) {
                        const [id, name, bg, thumb, fresh] = parts;
                        list.push({ id: id, name: name, background: bg, thumb: bg ? thumb : "", hasThumb: fresh === "1" });
                        if (bg && fresh !== "1" && !root.thumbAttempted[bg]) {
                            missing.push(bg, thumb);
                            root.thumbAttempted[bg] = true;
                        }
                    }
                }
                root.themes = list;
                if (missing.length && !thumbProc.running) {
                    // A few seconds in, so a video's fade-in doesn't give a black still.
                    thumbProc.command = ["sh", "-c", `
                        while [ $# -gt 1 ]; do
                            case "$1" in
                                *.mp4|*.webm|*.mkv) ffmpeg -loglevel error -ss 3 -i "$1" -frames:v 1 -vf 'scale=640:-2' -q:v 3 -y "$2" ;;
                                *) magick "$1[0]" -auto-orient -thumbnail 640x360^ -gravity center -extent 640x360 -quality 85 "$2" ;;
                            esac 2>/dev/null
                            shift 2
                        done
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
        id: applyProc
        property string themeId: ""
        stderr: StdioCollector { id: applyErr }
        onExited: code => {
            const id = themeId;
            root.applying = "";
            if (code === 0) {
                root.active = id;
                const name = root.themes.find(t => t.id === id)?.name ?? id;
                root.say(`${name} will show at the next login`, false);
            } else if (code === 126) {
                // pkexec: the password prompt was dismissed
                root.say("Cancelled", false);
            } else if (code === 127) {
                root.say("Not authorized", true);
            } else {
                const err = applyErr.text.trim().split("\n").pop().replace(/^poteto-login-theme: /, "");
                root.say(err || `Switching failed (exit ${code})`, true);
            }
            root.refresh();
            // The password prompt took the island's place; bring the switcher back to show the result.
            if (ShellState.view === "")
                ShellState.open("logintheme");
        }
    }
}
