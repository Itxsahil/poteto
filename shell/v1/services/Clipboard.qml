pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var entries: []
    property bool loading: false
    property var thumbs: ({})
    property var pendingThumbs: []

    // Decoded image previews: in the private per-login runtime folder (0700, in memory, gone at
    // logout), not shared /tmp, where other users could read them or claim the folder first
    readonly property string cacheDir: (Quickshell.env("XDG_RUNTIME_DIR")
        || Quickshell.env("HOME") + "/.cache/quickshell") + "/qs-cliphist"
    // Where previews went before, readable by other users: removed at start and by Clear all,
    // but only when it really is ours (a folder, not a link, owned by us)
    readonly property string legacyDir: Quickshell.env("USER") ? "/tmp/qs-cliphist-" + Quickshell.env("USER") : ""
    readonly property string removeLegacy: '[ -n "$1" ] && [ -d "$1" ] && [ ! -L "$1" ] && [ -O "$1" ] && rm -rf -- "$1"; true'

    Component.onCompleted: legacyProc.running = true

    signal copied()

    function refresh() {
        if (listProc.running)
            return;
        loading = true;
        listProc.running = true;
    }

    function copy(entry) {
        copyProc.command = ["sh", "-c", 'printf "%s\\t%s\\n" "$1" "$2" | cliphist decode | wl-copy', "sh", entry.id, entry.raw];
        copyProc.running = true;
    }

    function remove(entry) {
        entries = entries.filter(e => e.id !== entry.id);
        deleteProc.command = ["sh", "-c", 'printf "%s\\t%s\\n" "$1" "$2" | cliphist delete', "sh", entry.id, entry.raw];
        deleteProc.running = true;
    }

    function wipe() {
        entries = [];
        thumbs = {};
        wipeProc.running = true;
    }

    function requestThumb(entry) {
        if (!entry?.isImage || thumbs[entry.id] || pendingThumbs.includes(entry.id))
            return;
        pendingThumbs = [...pendingThumbs, entry.id];
        pumpThumbs();
    }

    function pumpThumbs() {
        if (thumbProc.running || pendingThumbs.length === 0)
            return;
        const id = pendingThumbs[0];
        const entry = entries.find(e => e.id === id);
        if (!entry) {
            pendingThumbs = pendingThumbs.slice(1);
            pumpThumbs();
            return;
        }
        thumbProc.entryId = id;
        thumbProc.out = `${cacheDir}/${id}.${entry.format || "png"}`;
        thumbProc.command = ["sh", "-c",
            // Files 0600 and the folder 0700; nothing is written into a folder that is a link or
            // someone else's
            'umask 077; mkdir -p "$1" && [ -d "$1" ] && [ ! -L "$1" ] && [ -O "$1" ] && chmod 700 "$1" && { [ -s "$4" ] || printf "%s\\t%s\\n" "$2" "$3" | cliphist decode > "$4"; }',
            "sh", cacheDir, id, entry.raw, thumbProc.out];
        thumbProc.running = true;
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const imageRe = /^\[\[ binary data (.+?) (\w+) (\d+)x(\d+) \]\]$/;
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const id = line.slice(0, tab);
                    const raw = line.slice(tab + 1);
                    const m = raw.match(imageRe);
                    out.push(m ? {
                        id: id, raw: raw, isImage: true,
                        size: m[1], format: m[2], imgW: parseInt(m[3]), imgH: parseInt(m[4]),
                        preview: `Image · ${m[3]}×${m[4]}`
                    } : {
                        id: id, raw: raw, isImage: false,
                        preview: raw
                    });
                }
                root.entries = out;
                root.loading = false;
            }
        }
    }

    Process {
        id: thumbProc
        property string entryId: ""
        property string out: ""
        onExited: code => {
            if (code === 0) {
                const t = Object.assign({}, root.thumbs);
                t[entryId] = out;
                root.thumbs = t;
            }
            root.pendingThumbs = root.pendingThumbs.filter(id => id !== entryId);
            root.pumpThumbs();
        }
    }

    Process {
        id: copyProc
        onExited: root.copied()
    }

    Process {
        id: deleteProc
    }

    Process {
        id: wipeProc
        command: ["sh", "-c", 'cliphist wipe && rm -rf "$1"; shift; ' + root.removeLegacy, "sh", root.cacheDir, root.legacyDir]
    }

    Process {
        id: legacyProc
        command: ["sh", "-c", root.removeLegacy, "sh", root.legacyDir]
    }
}
