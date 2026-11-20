import QtQuick
import Quickshell
import "../../utils/Calc.js" as Calc
import qs.config
import qs.components
import qs.services

Item {
    id: root

    property bool active: false
    readonly property int rowHeight: 50
    readonly property int maxRows: 7
    property int selected: 0
    property string terminal: "kitty"

    readonly property var calc: Calc.evaluate(search.text)
    readonly property int firstIndex: wantsKeys ? -2 : calc ? -1 : 0

    signal closeRequested()

    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property bool wantsKeys: {
        const q = search.text.trim().toLowerCase();
        return q !== "" && ["keys", "keybinds", "keybindings", "shortcuts", "bindings", "?"]
            .some(w => w.startsWith(q));
    }

    readonly property var results: {
        const q = search.text.trim().toLowerCase();
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
        if (name === q) return 1000;
        if (name.startsWith(q)) return 800 - name.length;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 600 - name.length;
        if (name.includes(q)) return 400 - name.length;
        const extra = [app.genericName, app.comment, app.id, ...(app.keywords ?? [])]
            .filter(Boolean).join(" ").toLowerCase();
        if (extra.includes(q)) return 200;
        let i = 0;
        for (const c of name)
            if (c === q[i]) i++;
        return i === q.length ? 100 - name.length : 0;
    }

    function launch(app) {
        if (!app)
            return;
        if (app.runInTerminal)
            Quickshell.execDetached({
                command: [root.terminal, "-e", ...app.command],
                workingDirectory: app.workingDirectory || Quickshell.env("HOME")
            });
        else
            app.execute();
        closeRequested();
    }

    function openKeybinds() {
        ShellState.open("keybinds");
    }

    function copyCalc() {
        if (!calc)
            return;
        Quickshell.execDetached(["wl-copy", calc.value]);
        closeRequested();
    }

    function move(delta) {
        const count = results.length - firstIndex;
        if (count <= 0)
            return;
        let next = selected;
        for (let i = 0; i < count; i++) {
            next = ((next - firstIndex + delta) % count + count) % count + firstIndex;
            if (next !== -1 || calc)        // -1 is the calculator slot; skip it when there is none
                break;
        }
        selected = next;
        if (selected >= 0)
            list.positionViewAtIndex(selected, ListView.Contain);
    }

    function resetSelection() {
        selected = firstIndex;
        list.positionViewAtBeginning();
    }

    onActiveChanged: {
        if (active) {
            search.text = "";
            resetSelection();
            search.focusInput();
        }
    }
    onResultsChanged: resetSelection()
    onCalcChanged: resetSelection()
    onWantsKeysChanged: resetSelection()

    implicitWidth: 560
    implicitHeight: search.height + (calc ? calcCard.height + 10 : 0)
        + (wantsKeys ? keysCard.height + 10 : 0) + (listArea.height > 0 ? listArea.height + 10 : 0)

    SearchField {
        id: search
        width: parent.width
        placeholder: "Search apps or calculate"
        onKeyPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
                root.closeRequested();
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && event.key === Qt.Key_J) || (ctrl && event.key === Qt.Key_N)) {
                root.move(1);
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && event.key === Qt.Key_K) || (ctrl && event.key === Qt.Key_P)) {
                root.move(-1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (root.selected === -2)
                    root.openKeybinds();
                else if (root.selected === -1)
                    root.copyCalc();
                else
                    root.launch(root.results[root.selected]);
            } else {
                return;
            }
            event.accepted = true;
        }

        Text {
            id: countLabel
            anchors.verticalCenter: parent.verticalCenter
            visible: !(root.calc && root.results.length === 0)
            text: root.results.length + (root.results.length === 1 ? " app" : " apps")
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }

    Rectangle {
        id: calcCard
        readonly property bool isSelected: root.selected === -1
        anchors.top: search.bottom
        anchors.topMargin: 10
        width: parent.width
        height: 68
        radius: Tokens.radius.field
        visible: root.calc !== null
        color: isSelected ? Theme.tileHover : Theme.tileBg
        border.width: 1
        border.color: isSelected ? Theme.accent : "transparent"
        Behavior on color { CAnim {} }

        property var shown: null
        Connections {
            target: root
            function onCalcChanged() { if (root.calc) calcCard.shown = root.calc; }
        }

        Rectangle {
            id: calcBadge
            width: 36
            height: 36
            radius: height / 2
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accent

            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: "="
                color: Theme.onAccent
                font.pixelSize: 20
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }
        }

        Column {
            anchors.left: calcBadge.right
            anchors.leftMargin: 14
            anchors.right: copyHint.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                elide: Text.ElideLeft
                text: search.text.trim()
                color: Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: calcCard.shown?.display ?? ""
                color: Theme.textPrimary
                font.pixelSize: 24
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }
        }

        Text {
            id: copyHint
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "↵ Copy"
            color: calcCard.isSelected ? Theme.textPrimary : Theme.textSecondary
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selected = -1
            onClicked: root.copyCalc()
        }
    }

    Rectangle {
        id: keysCard
        readonly property bool isSelected: root.selected === -2
        anchors.top: root.calc ? calcCard.bottom : search.bottom
        anchors.topMargin: 10
        width: parent.width
        height: 52
        radius: Tokens.radius.field
        visible: root.wantsKeys
        color: isSelected ? Theme.tileHover : Theme.tileBg
        border.width: 1
        border.color: isSelected ? Theme.accent : "transparent"
        Behavior on color { CAnim {} }

        Rectangle {
            id: keysBadge
            width: 36
            height: 36
            radius: Tokens.radius.row
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.accent

            Text {
                anchors.centerIn: parent
                text: "⌘"
                color: Theme.onAccent
                font.pixelSize: 17
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }
        }

        Column {
            anchors.left: keysBadge.right
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: "Keybindings"
                color: Theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            Text {
                text: `${Keybinds.count} shortcuts, read from your config`
                color: Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "↵ Open"
            color: keysCard.isSelected ? Theme.textPrimary : Theme.textSecondary
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: root.selected = -2
            onClicked: root.openKeybinds()
        }
    }

    Item {
        id: listArea
        anchors.top: root.wantsKeys ? keysCard.bottom : root.calc ? calcCard.bottom : search.bottom
        anchors.topMargin: 10
        width: parent.width
        height: root.results.length === 0 ? (root.calc ? 0 : 70) : Math.min(root.results.length, root.maxRows) * (root.rowHeight + list.spacing) - list.spacing
        Behavior on height { Anim {} }

        Text {
            anchors.centerIn: parent
            visible: root.results.length === 0 && !root.calc
            text: `No apps match "${search.text}"`
            color: Theme.textSecondary
            font.pixelSize: 13
            font.family: Theme.fontFamily
        }

        ListView {
            id: list
            anchors.fill: parent
            clip: true
            spacing: 4
            model: root.results
            boundsBehavior: Flickable.StopAtBounds
            highlightFollowsCurrentItem: false
            currentIndex: root.selected

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index
                readonly property bool isSelected: index === root.selected

                width: ListView.view.width
                height: root.rowHeight
                radius: Tokens.radius.chip
                color: isSelected ? Theme.tileHover : "transparent"
                Behavior on color { CAnim {} }

                Rectangle {
                    width: 3
                    height: 20
                    radius: width / 2
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.accent
                    opacity: row.isSelected ? 1 : 0
                    Behavior on opacity { Anim { duration: Tokens.duration.press } }
                }

                Item {
                    id: appIcon
                    width: 32
                    height: 32
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: iconImage
                        anchors.fill: parent
                        source: row.modelData.icon ? Quickshell.iconPath(row.modelData.icon, true) : ""
                        sourceSize.width: 64
                        sourceSize.height: 64
                        asynchronous: true
                        smooth: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Tokens.radius.small
                        color: Theme.controlBg
                        visible: iconImage.status !== Image.Ready

                        Text {
                            anchors.centerIn: parent
                            text: row.modelData.name.charAt(0).toUpperCase()
                            color: Theme.textPrimary
                            font.pixelSize: 15
                            font.weight: Font.Bold
                            font.family: Theme.fontFamily
                        }
                    }
                }

                Column {
                    anchors.left: appIcon.right
                    anchors.leftMargin: 14
                    anchors.right: hint.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: row.modelData.name
                        color: Theme.textPrimary
                        font.pixelSize: 14
                        font.weight: row.isSelected ? Font.DemiBold : Font.Normal
                        font.family: Theme.fontFamily
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        visible: text !== ""
                        text: row.modelData.genericName || row.modelData.comment || ""
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }

                Text {
                    id: hint
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↵"
                    color: Theme.textSecondary
                    font.pixelSize: 14
                    font.family: Theme.fontFamily
                    opacity: row.isSelected ? 1 : 0
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
