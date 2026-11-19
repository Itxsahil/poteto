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
    // Builds themes/dynamic/ from the wallpaper (matugen, or a built-in fallback). The folder is
    // generated, not tracked, and rebuilt whenever it is applied or the wallpaper changes while
    // it is the active theme.
    readonly property string dynamicId: "dynamic"
    readonly property string generator: Quickshell.shellDir + "/scripts/theme-from-wallpaper"
    readonly property var dynamicModes: ["dark", "light", "auto"]
    readonly property var dynamicSchemes: ["tonal-spot", "vibrant", "expressive", "fidelity", "content",
        "fruit-salad", "rainbow", "neutral", "monochrome"]

    property string themesDir: ""
    property var themes: []
    property string current: ""
    property bool applying: false
    property string pending: ""
    // Arguments for the next dynamic build: [wallpaper], --mode, --scheme. Anything left out keeps
    // what the last build used.
    property var dynamicArgs: []
    readonly property string defaultTheme: "gruvbox-material"

    readonly property var dynamicTheme: themes.find(t => t.id === dynamicId) ?? null

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
        // A plain apply("dynamic") (the picker, qs ipc call theme apply dynamic) gets the
        // wallpaper too
        applyProc.extraArgs = id !== dynamicId ? [] : dynamicArgs.length ? dynamicArgs
            : (Wallpaper.current ? [Wallpaper.current] : []);
        dynamicArgs = [];
        applyProc.running = true;
    }

    // Rebuild and apply the dynamic theme. Empty strings keep the last mode / scheme / wallpaper.
    function applyDynamic(mode, scheme, wallpaper) {
        const args = [];
        // The wallpaper the shell knows of; the script asks awww itself only without one
        const source = wallpaper || Wallpaper.current;
        if (source)
            args.push(source);
        if (dynamicModes.includes(mode))
            args.push("--mode", mode);
        if (dynamicSchemes.includes(scheme))
            args.push("--scheme", scheme);
        dynamicArgs = args;
        apply(dynamicId);
    }

    // dark → light → auto → dark
    function cycleDynamicMode() {
        const now = dynamicTheme?.colors.mode ?? dynamicTheme?.variant ?? "dark";
        applyDynamic(dynamicModes[(dynamicModes.indexOf(now) + 1) % dynamicModes.length], "", "");
    }

    function cycleDynamicScheme() {
        const now = dynamicTheme?.colors.scheme ?? "tonal-spot";
        applyDynamic("", dynamicSchemes[(dynamicSchemes.indexOf(now) + 1) % dynamicSchemes.length], "");
    }

    Component.onCompleted: resolveProc.running = true

    // The dynamic theme follows the wallpaper while it is the active one
    Connections {
        target: Wallpaper
        function onApplied(path) {
            if (root.current === root.dynamicId)
                root.applyDynamic("", "", path);
        }
    }

    Process {
        id: resolveProc
        command: ["sh", "-c", 'realpath -- "$1/../../themes"; basename "$(readlink "$2/current")" 2>/dev/null', "sh", Quickshell.shellDir, root.linkDir]
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
            # The dynamic theme is generated: build it from the current wallpaper the first time
            [ -f "$1/dynamic/quickshell/colors.json" ] || "$2" "$1" >/dev/null 2>&1 || true
            for f in "$1"/*/quickshell/colors.json; do
                [ -f "$f" ] || continue
                printf '%s\t' "$(basename "$(dirname "$(dirname "$f")")")"
                tr -d '\n' < "$f"
                echo
            done
        `, "sh", root.themesDir, root.generator]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const id = line.slice(0, tab);
                    try {
                        const colors = JSON.parse(line.slice(tab + 1));
                        list.push({
                            id: id,
                            name: colors.name ?? id,
                            variant: colors.variant ?? "dark",
                            colors: colors
                        });
                    } catch (e) {
                        console.warn("ThemeManager: invalid colors.json in", id);
                    }
                }
                root.themes = list.sort((a, b) => a.name.localeCompare(b.name));
            }
        }
    }

    Process {
        id: applyProc
        property string themeId: ""
        property var extraArgs: []
        command: ["sh", "-c", `
            set -e
            themes="$1"; id="$2"; links="$3"; vscode="$4"; generator="$5"
            shift 5
            theme="$themes/$id"
            # The dynamic theme is rebuilt from the wallpaper first ("$@": wallpaper, --mode, --scheme)
            if [ "$id" = dynamic ]; then
                "$generator" "$themes" "$@" >/dev/null || { echo "could not build the dynamic theme" >&2; exit 1; }
            fi
            [ -f "$theme/quickshell/colors.json" ] || { echo "no theme named $id" >&2; exit 1; }
            mkdir -p "$links"

            link() { if [ -e "$1" ]; then ln -sfn "$1" "$2"; else rm -f "$2"; fi; }
            ln -sfn "$theme" "$links/current"
            link "$theme/quickshell/colors.json" "$links/colors.json"
            link "$theme/kitty/$id.conf"         "$links/kitty.conf"
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
                    nvim --server "$sock" --remote-expr "execute('lua package.loaded[\\"themes.$nvtheme\\"] = nil; local c = require(\\"nvconfig\\").base46; c.theme = \\"$nvtheme\\"; c.transparency = $nvtransparent; require(\\"base46\\").load_all_highlights()')" >/dev/null 2>&1 || true
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
            # The wallpaper is optional: without one, the test above is the last command run, and
            # its failure must not count as the theme failing to apply
            exit 0
        `, "sh", root.themesDir, themeId, root.linkDir, root.vscodeSettings, root.generator, ...extraArgs]
        stdout: StdioCollector { id: applyOut }
        stderr: StdioCollector { id: applyErr }
        onExited: code => {
            root.applying = false;
            if (code === 0) {
                root.current = themeId;
                Theme.reload();
                // A rebuilt dynamic theme has new colors: its card has to show them
                if (themeId === root.dynamicId)
                    root.refresh();
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
