pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The keybind cheatsheet, read from hypr/bindings.lua itself so it cannot drift from the
// real config, plus the in-shell keys that live in QML rather than in Hyprland.
Singleton {
    id: root

    readonly property string bindingsFile: Quickshell.env("HOME") + "/.config/hypr/bindings.lua"

    property var hyprGroups: []
    readonly property var groups: hyprGroups.concat(shellGroups)
    readonly property int count: groups.reduce((n, g) => n + g.items.length, 0)

    // Combos bound more than once: Hyprland collapses repeated modifiers, so a config that
    // writes "mod + ALT + H" while mod is already ALT silently shadows plain "mod + H".
    readonly property var conflicts: {
        const seen = {};
        const dupes = {};
        for (const g of hyprGroups)
            for (const it of g.items) {
                if (seen[it.keys])
                    dupes[it.keys] = true;
                seen[it.keys] = true;
            }
        return dupes;
    }

    // Keys handled inside the shell's own views, which Hyprland never sees
    readonly property var shellGroups: [
        {
            name: "Island views",
            items: [
                { keys: "↑ ↓ ← →", action: "Move the selection", detail: "Ctrl+H/J/K/L works too" },
                { keys: "Enter", action: "Apply, open or play", detail: "" },
                { keys: "Shift + Enter", action: "Apply and close, or open in mpv", detail: "" },
                { keys: "Tab", action: "Cycle folder chips", detail: "wallpapers and videos" },
                { keys: "Esc", action: "Close the view", detail: "clicking outside closes too" }
            ]
        },
        {
            name: "Video player",
            items: [
                { keys: "Space", action: "Play or pause", detail: "click the video too" },
                { keys: "← →", action: "Seek 5 seconds", detail: "hold Shift for 60" },
                { keys: "↑ ↓", action: "Volume", detail: "M mutes" },
                { keys: "F", action: "Fullscreen", detail: "or double click" },
                { keys: "N / P", action: "Next / previous video", detail: "" },
                { keys: "R", action: "Loop: off → one → all", detail: "" },
                { keys: "[ ]", action: "Playback speed", detail: "0.5× to 2×" },
                { keys: "C", action: "Subtitle track", detail: "when the file has any" },
                { keys: "O", action: "Reopen in mpv", detail: "for what Qt cannot decode" },
                { keys: "Esc", action: "Close the player", detail: "" }
            ]
        },
        {
            name: "Control center",
            items: [
                { keys: "Hover the island", action: "Open the control center", detail: "" },
                { keys: "Esc", action: "Back, then close", detail: "" }
            ]
        }
    ]

    // Names Hyprland uses that read badly in a cheatsheet
    readonly property var keyNames: ({
        "RETURN": "Enter",
        "SPACE": "Space",
        "TAB": "Tab",
        "ESCAPE": "Esc",
        "apostrophe": "'",
        "semicolon": ";",
        "period": ".",
        "comma": ",",
        "backspace": "Backspace",
        "mouse_down": "Scroll down",
        "mouse_up": "Scroll up",
        "mouse:272": "Left click",
        "mouse:273": "Right click",
        "XF86AudioRaiseVolume": "Volume up key",
        "XF86AudioLowerVolume": "Volume down key",
        "XF86AudioMute": "Mute key",
        "XF86AudioMicMute": "Mic mute key",
        "XF86MonBrightnessUp": "Brightness up key",
        "XF86MonBrightnessDown": "Brightness down key",
        "XF86AudioPlay": "Play key",
        "XF86AudioPause": "Pause key",
        "XF86AudioNext": "Next track key",
        "XF86AudioPrev": "Previous track key"
    })

    function prettyKeys(expr, vars) {
        let s = expr;
        for (const name in vars)
            s = s.split(name).join(vars[name]);
        s = s.replace(/"/g, "").replace(/\.\./g, " ").replace(/\s+/g, " ").trim();
        const parts = s.split("+").map(part => {
            const key = part.trim();
            return root.keyNames[key] ?? (key.length === 1 ? key.toUpperCase()
                : key.charAt(0).toUpperCase() + key.slice(1).toLowerCase());
        });
        return parts.filter((p, i) => parts.indexOf(p) === i || i === parts.length - 1).join(" + ");
    }

    // "hl.dsp.window.close()" → "window close", "hl.dsp.focus({ direction = "left" })" → "focus left"
    function prettyAction(expr, vars) {
        let s = expr.trim();
        const exec = s.match(/^hl\.dsp\.exec_cmd\(([\s\S]*)\)$/);
        if (exec) {
            let cmd = exec[1].trim();
            if (vars[cmd] !== undefined)
                return vars[cmd];
            return cmd.replace(/^"|"$/g, "");
        }
        if (/^function/.test(s))
            return "custom action";
        s = s.replace(/^hl\.dsp\./, "").replace(/\(\s*\)$/, "");
        const call = s.match(/^([\w.]+)\(([\s\S]*)\)$/);
        if (!call)
            return s.replace(/\./g, " ");
        const args = call[2].replace(/[{}"]/g, "").split(",")
            .map(a => a.split("=").pop().trim()).filter(Boolean).join(" ");
        return `${call[1].replace(/\./g, " ")} ${args}`.trim();
    }

    // Split "keys, action" at the comma that is not inside quotes, parens or a table
    function splitArgs(inner) {
        let depth = 0;
        let quoted = false;
        for (let i = 0; i < inner.length; i++) {
            const c = inner[i];
            if (c === '"' && inner[i - 1] !== "\\")
                quoted = !quoted;
            else if (!quoted && (c === "(" || c === "{"))
                depth++;
            else if (!quoted && (c === ")" || c === "}"))
                depth--;
            else if (!quoted && depth === 0 && c === ",")
                return [inner.slice(0, i), inner.slice(i + 1)];
        }
        return [inner, ""];
    }

    function parse(text) {
        const vars = {};
        const groups = [];
        let group = null;
        let comment = "";
        let expectHeading = false;
        let closingRule = false;
        let inWorkspaceLoop = false;

        for (const raw of text.split("\n")) {
            const line = raw.trim();

            const varMatch = line.match(/^(var_\w+)\s*=\s*"(.*)"\s*$/);
            if (varMatch) {
                vars[varMatch[1]] = varMatch[2];
                continue;
            }

            if (line.startsWith("--")) {
                const body = line.replace(/^--+\s?/, "").trim();
                if (/^[-=]+$/.test(body)) {
                    // rules come in pairs around a title; only the opening one announces a section
                    expectHeading = !closingRule;
                    closingRule = false;
                } else if (expectHeading && body) {
                    group = { name: body.charAt(0) + body.slice(1).toLowerCase(), items: [] };
                    groups.push(group);
                    expectHeading = false;
                    closingRule = true;
                    comment = "";
                } else if (!body.startsWith("hl.bind")) {
                    comment = body;                // a description for the next bind
                }
                continue;
            }

            if (line.startsWith("for workspace")) {
                inWorkspaceLoop = true;
                continue;
            }
            if (inWorkspaceLoop && line === "end") {
                inWorkspaceLoop = false;
                continue;
            }

            if (!line.startsWith("hl.bind("))
                continue;

            const inner = line.slice("hl.bind(".length, line.lastIndexOf(")"));
            const [keyExpr, rest] = splitArgs(inner);
            let keys = prettyKeys(keyExpr, vars);
            const action = prettyAction(splitArgs(rest)[0], vars);

            if (inWorkspaceLoop)
                keys = keys.replace(/\+ Workspace$/, "+ 1…9");

            if (!group) {
                group = { name: "Other", items: [] };
                groups.push(group);
            }
            group.items.push({
                keys: keys,
                action: comment || action,
                detail: comment ? action : ""
            });
            comment = "";
        }

        root.hyprGroups = groups.filter(g => g.items.length > 0);
    }

    Component.onCompleted: file.reload()

    FileView {
        id: file
        path: root.bindingsFile
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }
}
