import QtQuick
import Quickshell
import qs.config
import qs.services
import "../../utils/Calc.js" as Calc

// The launcher itself, with no surface of its own: the pill grows into it in pill mode, and a
// panel drops down from the bar in bar mode. Type to filter, arrows or Ctrl+J/K to move, Enter
// to launch, Esc to close. Typing a sum shows its answer on a card above the apps (Enter copies
// it, utils/Calc.js), and "?" or "keys" offers the keybind cheatsheet the same way.
Item {
    id: root

    property bool active: false

    readonly property int rowHeight: 42
    readonly property int maxRows: 8
    // Apps that run in a terminal open in this one
    readonly property string terminal: "kitty"

    // -1 is the card above the list (the answer, or the cheatsheet), when there is one
    property int selected: 0

    readonly property var calc: Calc.evaluate(input.text)
    readonly property bool wantsKeys: ["?", "keys", "keybinds", "shortcuts", "cheatsheet", "bindings"]
        .includes(input.text.trim().toLowerCase())
    readonly property bool hasCard: calc !== null || wantsKeys

    signal closeRequested()

    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        if (!q)
            return apps;
        const scored = [];
        for (const app of apps) {
            const s = score(app, q);
            if (s > 0)
                scored.push({ app: app, s: s });
        }
        scored.sort((a, b) => b.s - a.s || a.app.name.localeCompare(b.app.name));
        return scored.map(x => x.app);
    }

    function score(app, q) {
        const name = app.name.toLowerCase();
        if (name === q)
            return 1000;
        if (name.startsWith(q))
            return 800 - name.length;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 600 - name.length;
        if (name.includes(q))
            return 400 - name.length;
        const extra = [app.genericName, app.comment, app.id, ...(app.keywords ?? [])]
            .filter(Boolean).join(" ").toLowerCase();
        if (extra.includes(q))
            return 200;
        // the letters in order, with gaps allowed ("ffx" finds Firefox)
        let i = 0;
        for (const c of name)
            if (c === q[i])
                i++;
        return i === q.length ? 100 - name.length : 0;
    }

    function launch(app) {
        if (!app)
            return;
        if (app.runInTerminal)
            Quickshell.execDetached({
                command: [terminal, "-e", ...app.command],
                workingDirectory: app.workingDirectory || Quickshell.env("HOME")
            });
        else
            app.execute();
        closeRequested();
    }

    function move(delta) {
        // The card is one more stop, before the first app
        const first = hasCard ? -1 : 0;
        const count = results.length - first;
        if (count <= 0)
            return;
        selected = ((selected - first + delta) % count + count) % count + first;
    }

    function activate() {
        if (selected === -1 && calc) {
            Quickshell.execDetached(["wl-copy", calc.value]);
            root.closeRequested();
        } else if (selected === -1 && wantsKeys) {
            ShellState.open("keybinds");
        } else {
            launch(results[selected]);
        }
    }

    function resetSelection() {
        selected = hasCard ? -1 : 0;
        list.positionViewAtBeginning();
    }

    onResultsChanged: resetSelection()
    onHasCardChanged: resetSelection()

    onActiveChanged: {
        if (active) {
            input.text = "";
            resetSelection();
            input.forceActiveFocus();
        }
    }

    implicitWidth: 500
    implicitHeight: search.height + divider.height + (hasCard ? card.height + 8 : 0) + listArea.height + 8

    Item {
        id: search
        width: parent.width
        height: 44

        // magnifier
        Canvas {
            id: glass
            width: 16
            height: 16
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            property color tint: Theme.textDim
            onTintChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = tint;
                ctx.lineWidth = 1.8;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(6.5, 6.5, 5, 0, Math.PI * 2);
                ctx.moveTo(10.2, 10.2);
                ctx.lineTo(14.5, 14.5);
                ctx.stroke();
            }
        }

        TextInput {
            id: input
            anchors.left: glass.right
            anchors.leftMargin: 12
            anchors.right: count.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            font.pixelSize: 15
            font.family: Theme.fontFamily
            clip: true

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier;
                if (event.key === Qt.Key_Escape) {
                    root.closeRequested();
                } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab
                        || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                    root.move(1);
                } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab
                        || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                    root.move(-1);
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activate();
                } else {
                    return;
                }
                event.accepted = true;
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !input.text
                text: "Search apps, or calculate"
                color: Theme.textDim
                font: input.font
            }
        }

        Text {
            id: count
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.results.length
            color: Theme.textDim
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }

    Rectangle {
        id: divider
        anchors.top: search.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }

    // The answer to a sum, or the way to the cheatsheet
    Rectangle {
        id: card

        readonly property bool isSelected: root.selected === -1
        // Kept while the card fades, so it does not empty out as it goes
        property var shown: null

        anchors.top: divider.bottom
        anchors.topMargin: 8
        width: parent.width
        height: 58
        radius: 14
        visible: root.hasCard
        color: isSelected ? Qt.alpha(Theme.accent, 0.16) : Theme.tile
        Behavior on color { ColorAnimation { duration: 120 } }

        Connections {
            target: root
            function onCalcChanged() {
                if (root.calc)
                    card.shown = root.calc;
            }
        }

        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: 17
            color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: root.calc ? "=" : "󰌌"
                color: Theme.accentText
                font.pixelSize: root.calc ? 19 : 16
                font.weight: Font.Bold
                font.family: root.calc ? Theme.fontFamily : Theme.monoFamily
            }
        }

        Column {
            anchors.left: badge.right
            anchors.leftMargin: 12
            anchors.right: hint.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                elide: Text.ElideLeft
                text: root.calc ? input.text.trim().replace(/^=/, "") : "Keyboard shortcuts"
                color: root.calc ? Theme.textDim : Theme.text
                font.pixelSize: root.calc ? 11 : 14
                font.weight: root.calc ? Font.Normal : Font.DemiBold
                font.family: root.calc ? Theme.monoFamily : Theme.fontFamily
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.calc ? (card.shown?.display ?? "") : "Every keybind, from hypr/bindings.lua"
                color: root.calc ? Theme.text : Theme.textDim
                font.pixelSize: root.calc ? 20 : 11
                font.weight: root.calc ? Font.DemiBold : Font.Normal
                font.family: root.calc ? Theme.monoFamily : Theme.fontFamily
            }
        }

        Text {
            id: hint
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            opacity: card.isSelected ? 1 : 0.5
            text: root.calc ? "↵ copy" : "↵ open"
            color: Theme.textDim
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selected = -1
            onClicked: {
                root.selected = -1;
                root.activate();
            }
        }
    }

    Item {
        id: listArea
        anchors.top: root.hasCard ? card.bottom : divider.bottom
        anchors.topMargin: 8
        width: parent.width
        // With a card and no apps, the card is the answer: no "nothing matches" under it
        height: root.results.length === 0 ? (root.hasCard ? 0 : 52)
            : Math.min(root.results.length, root.maxRows) * root.rowHeight

        Text {
            anchors.centerIn: parent
            visible: root.results.length === 0 && !root.hasCard
            text: `Nothing matches "${input.text}"`
            color: Theme.textDim
            font.pixelSize: 13
            font.family: Theme.fontFamily
        }

        ListView {
            id: list
            anchors.fill: parent
            clip: true
            model: root.results
            currentIndex: root.selected
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 140
            highlightResizeDuration: 0

            // Slides from row to row instead of jumping
            highlight: Rectangle {
                radius: 12
                color: Qt.alpha(Theme.accent, 0.16)

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: 16
                    radius: 1.5
                    color: Theme.accent
                }
            }

            delegate: Item {
                id: row

                required property var modelData
                required property int index
                readonly property bool isSelected: index === root.selected

                width: ListView.view.width
                height: root.rowHeight

                Item {
                    id: appIcon
                    width: 24
                    height: 24
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: iconImage
                        anchors.fill: parent
                        source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, true) : ""
                        sourceSize.width: 48
                        sourceSize.height: 48
                        asynchronous: true
                    }

                    // First letter when the icon theme has nothing for this app
                    Rectangle {
                        anchors.fill: parent
                        radius: 7
                        color: Theme.control
                        visible: iconImage.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            text: row.modelData.name.charAt(0).toUpperCase()
                            color: Theme.text
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            font.family: Theme.fontFamily
                        }
                    }
                }

                Text {
                    id: name
                    anchors.left: appIcon.right
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, row.width - 64)
                    elide: Text.ElideRight
                    text: row.modelData.name
                    color: Theme.text
                    font.pixelSize: 14
                    font.weight: row.isSelected ? Font.DemiBold : Font.Normal
                    font.family: Theme.fontFamily
                }

                // What the app is, dimmed beside its name, while there is room
                Text {
                    anchors.left: name.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: row.modelData.genericName || row.modelData.comment || ""
                    color: Theme.textDim
                    font.pixelSize: 12
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selected = row.index
                    onClicked: root.launch(row.modelData)
                }
            }
        }
    }
}
