pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int maxRecent: 32
    readonly property string recentFile: Quickshell.env("HOME") + "/.cache/quickshell/emoji-recent.json"

    readonly property var groups: [
        { id: "recent", label: "Recent", icon: "🕘" },
        { id: "smileys", label: "Smileys", icon: "😀" },
        { id: "people", label: "People", icon: "👋" },
        { id: "nature", label: "Nature", icon: "🌿" },
        { id: "food", label: "Food", icon: "🍔" },
        { id: "travel", label: "Travel", icon: "✈️" },
        { id: "activities", label: "Activities", icon: "⚽" },
        { id: "objects", label: "Objects", icon: "💡" },
        { id: "symbols", label: "Symbols", icon: "❤️" },
        { id: "flags", label: "Flags", icon: "🏳️" }
    ]

    property var all: []
    property var recent: []

    function search(query, group) {
        const q = query.trim().toLowerCase();
        if (!q) {
            if (group === "recent")
                return recent.map(e => all.find(x => x.e === e) ?? { e: e, n: "", g: "" });
            return all.filter(x => x.g === group);
        }
        const words = q.split(/\s+/);
        const scored = [];
        for (const item of all) {
            const name = item.n.toLowerCase();
            if (!words.every(w => name.includes(w)))
                continue;
            const nameWords = name.split(/[\s:,-]+/);
            const score = name === q ? 0
                : name.startsWith(q) ? 1
                : words.every(w => nameWords.includes(w)) ? 2
                : nameWords.some(w => w.startsWith(words[0])) ? 3
                : 4;
            scored.push({ item: item, score: score });
        }
        scored.sort((a, b) => a.score - b.score || a.item.n.length - b.item.n.length);
        return scored.map(s => s.item);
    }

    function copy(emoji) {
        Quickshell.execDetached(["wl-copy", emoji]);
        recent = [emoji, ...recent.filter(e => e !== emoji)].slice(0, maxRecent);
        recentStore.setText(JSON.stringify(recent));
    }

    Component.onCompleted: {
        data.reload();
        recentStore.reload();
    }

    FileView {
        id: data
        path: Quickshell.shellDir + "/assets/emoji.json"
        blockLoading: true
        onLoaded: {
            try {
                root.all = JSON.parse(text());
            } catch (e) {
                console.warn("Emoji: could not parse emoji.json", e);
            }
        }
    }

    FileView {
        id: recentStore
        path: root.recentFile
        printErrors: false
        onLoaded: {
            try {
                const list = JSON.parse(text());
                if (Array.isArray(list))
                    root.recent = list.slice(0, root.maxRecent);
            } catch (e) {}
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.cache/quickshell"]
    }
}
