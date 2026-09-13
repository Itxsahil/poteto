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

    readonly property string cacheDir: "/tmp/qs-cliphist-" + Quickshell.env("USER")

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
            'mkdir -p "$1" && { [ -s "$4" ] || printf "%s\\t%s\\n" "$2" "$3" | cliphist decode > "$4"; }',
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
        command: ["sh", "-c", 'cliphist wipe && rm -rf "$1"', "sh", root.cacheDir]
    }
}
