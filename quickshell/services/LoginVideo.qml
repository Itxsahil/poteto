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
    // Which folder under ~/Videos the picker offers. Everything comes from the Videos service,
    // which already scans the tree and keeps the poster frames.
    readonly property string folder: "Hidamari"
    readonly property string helper: "/usr/local/bin/poteto-login-theme"
    readonly property string activeDir: "/usr/share/sddm/themes/poteto"

    readonly property var videos: Videos.entries.filter(entry =>
        (entry.folder === root.folder || entry.folder.startsWith(root.folder + "/"))
        && /\.(mp4|webm|mkv)$/i.test(entry.path))

    // The path that was last published, read back from the live theme
    property string current: ""
    property string applying: ""
    property string message: ""
    property bool messageIsError: false

    Component.onCompleted: readProc.running = true

    Connections {
        target: LoginTheme
        function onActiveChanged() {
            if (!readProc.running)
                readProc.running = true;
        }
    }

    function refresh() {
        Videos.refresh();
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
            // The password prompt took the island's place; bring the picker back to show the result.
            if (ShellState.view === "")
                ShellState.open("loginvideo");
        }
    }
}
