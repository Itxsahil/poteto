pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string linkDir: home + "/.cache/quickshell/theme"
    readonly property string vscodeSettings: home + "/.config/Code/User/settings.json"
    readonly property string thumbDir: home + "/.cache/quickshell/theme-thumbs"

    property string themesDir: ""
    property var themes: []
    property string current: ""
    property bool applying: false
    property string pending: ""
    property int thumbsVersion: 0
    property var thumbAttempted: ({})
    readonly property string defaultTheme: "gruvbox-material"

    signal applied(string id, bool ok)

    function refresh() {
        if (themesDir && !listProc.running)
            listProc.running = true;
    }

    function apply(id) {
        if (!themesDir || applying) {
            pending = id;
            return;
        }
        applying = true;
        applyProc.themeId = id;
        applyProc.running = true;
    }

    Component.onCompleted: resolveProc.running = true

    Process {
        id: resolveProc
        command: ["sh", "-c", 'realpath -- "$1/../themes"; basename "$(readlink "$2/current")" 2>/dev/null', "sh", Quickshell.shellDir, root.linkDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const [dir, current] = text.split("\n");
                root.themesDir = dir.trim();
                root.current = (current ?? "").trim();
                root.refresh();
                if (root.pending) {
                    const id = root.pending;
                    root.pending = "";
                    root.apply(id);
                } else if (!root.current) {
                    root.apply(root.defaultTheme);
                }
            }
        }
    }

    Process {
        id: listProc
        command: ["sh", "-c", `
            themes="$1"; thumbs="$2"
            mkdir -p "$thumbs"
            for f in "$themes"/*/quickshell/colors.json; do
                [ -f "$f" ] || continue
                dir=$(dirname "$(dirname "$f")"); id=$(basename "$dir")
                wall=""
                for w in "$dir"/wallpaper/wall.*; do [ -f "$w" ] && { wall="$w"; break; }; done
                thumb="$thumbs/$id.jpg"
                fresh=0
                [ -n "$wall" ] && [ -s "$thumb" ] && [ "$thumb" -nt "$wall" ] && fresh=1
                printf '%s\t%s\t%s\t%s\t' "$id" "$wall" "$thumb" "$fresh"
                tr -d '\n' < "$f"
                echo
            done
        `, "sh", root.themesDir, root.thumbDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                const missing = [];
                for (const line of text.split("\n")) {
                    const parts = line.split("\t");
                    if (parts.length < 5)
                        continue;
                    const [id, wallpaper, thumb, fresh] = parts;
                    try {
                        const colors = JSON.parse(parts.slice(4).join("\t"));
                        list.push({
                            id: id,
                            name: colors.name ?? id,
                            variant: colors.variant ?? "dark",
                            colors: colors,
                            wallpaper: wallpaper,
                            thumb: wallpaper ? thumb : "",
                            hasThumb: fresh === "1"
                        });
                        if (wallpaper && fresh !== "1" && !root.thumbAttempted[wallpaper]) {
                            missing.push(wallpaper, thumb);
                            root.thumbAttempted[wallpaper] = true;
                        }
                    } catch (e) {
                        console.warn("ThemeManager: invalid colors.json in", id);
                    }
                }
                root.themes = list.sort((a, b) => a.name.localeCompare(b.name));
                if (missing.length && !thumbProc.running) {
                    thumbProc.command = ["sh", "-c", `
                        while [ $# -gt 1 ]; do printf '%s\\0%s\\0' "$1" "$2"; shift 2; done |
                        xargs -0 -n2 -P4 sh -c 'magick "$0[0]" -auto-orient -thumbnail 520x325^ -gravity center -extent 520x325 -quality 85 "$1" 2>/dev/null'
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
        command: ["sh", "-c", `
            set -e
            theme="$1/$2"; links="$3"; vscode="$4"
            [ -f "$theme/quickshell/colors.json" ] || { echo "no theme named $2" >&2; exit 1; }
            mkdir -p "$links"

            link() { if [ -e "$1" ]; then ln -sfn "$1" "$2"; else rm -f "$2"; fi; }
            ln -sfn "$theme" "$links/current"
            link "$theme/quickshell/colors.json" "$links/colors.json"
            link "$theme/kitty/$2.conf"          "$links/kitty.conf"
            link "$theme/hyprlock/colors.conf"   "$links/hyprlock.conf"
            link "$theme/nvim/theme.lua"         "$links/nvim.lua"
            link "$theme/nvim/transparent"       "$links/nvim-transparent"
            link "$theme/hyprland/colors.lua"    "$links/hyprland.lua"
            link "$theme/rmpc/theme.ron"         "$links/rmpc.ron"

            pkill -USR1 -x kitty || true
            hyprctl reload >/dev/null 2>&1 || true
            if [ -e "$links/rmpc.ron" ] && command -v rmpc >/dev/null; then
                for pid in $(pgrep -x rmpc); do
                    rmpc remote --pid "$pid" set theme "$links/rmpc.ron" >/dev/null 2>&1 || true
                done
            fi

            if [ -f "$theme/nvim/theme.lua" ]; then
                nvtheme=$(sed -n 's/^return "\\(.*\\)"$/\\1/p' "$theme/nvim/theme.lua")
                # a theme opts into a see-through Neovim with an nvim/transparent marker file
                nvtransparent=false
                [ -e "$theme/nvim/transparent" ] && nvtransparent=true
                for sock in "\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/nvim.*; do
                    [ -S "$sock" ] || continue
                    nvim --server "$sock" --remote-expr "execute('lua local c = require(\\"nvconfig\\").base46; c.theme = \\"$nvtheme\\"; c.transparency = $nvtransparent; require(\\"base46\\").load_all_highlights()')" >/dev/null 2>&1 || true
                done
                # NvChad starts from a compiled highlight cache, which the loop above only rebuilds
                # inside Neovims that are open. Rebuild it once more here so the next Neovim you
                # start gets this theme too, rather than whatever was compiled last.
                if command -v nvim >/dev/null; then
                    nvim --headless +'lua require("base46").load_all_highlights()' +qa >/dev/null 2>&1 || true
                fi
            fi

            if [ -f "$vscode" ] && [ -f "$theme/vscode/theme" ]; then
                vstheme=$(head -n1 "$theme/vscode/theme" | sed 's/[&|\\\\]/\\\\&/g')
                sed -i "s|\\"workbench.colorTheme\\": *\\"[^\\"]*\\"|\\"workbench.colorTheme\\": \\"$vstheme\\"|" "$vscode"
            fi

            for wall in "$theme"/wallpaper/wall.*; do
                [ -f "$wall" ] && { echo "$wall"; break; }
            done
        `, "sh", root.themesDir, themeId, root.linkDir, root.vscodeSettings]
        stdout: StdioCollector { id: applyOut }
        stderr: StdioCollector { id: applyErr }
        onExited: code => {
            root.applying = false;
            if (code === 0) {
                root.current = themeId;
                Theme.reload();
                const wallpaper = applyOut.text.trim().split("\n").pop();
                if (wallpaper)
                    Wallpaper.apply(wallpaper);
            } else {
                console.warn("ThemeManager: switching to", themeId, "failed:", applyErr.text);
            }
            root.applied(themeId, code === 0);
            if (root.pending) {
                const id = root.pending;
                root.pending = "";
                root.apply(id);
            }
        }
    }
}
