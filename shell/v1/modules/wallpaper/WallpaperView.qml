import QtQuick
import qs.config
import qs.components
import qs.services

Item {
    id: root

    property bool active: false
    property string folder: ""
    property int selected: 0

    readonly property int columns: 4
    readonly property var folderList: {
        const counts = {};
        for (const w of Wallpaper.wallpapers)
            counts[w.folder] = (counts[w.folder] ?? 0) + 1;
        return Wallpaper.folders.filter(f => counts[f]).map(f => ({ path: f, name: f.split("/").pop(), count: counts[f] }));
    }
    readonly property var results: {
        const q = search.text.trim().toLowerCase();
        return Wallpaper.wallpapers.filter(w => (!folder || w.folder === folder) && (!q || w.label.toLowerCase().includes(q)));
    }

    signal closeRequested()

    implicitWidth: 740
    implicitHeight: 540

    function move(delta) {
        if (results.length === 0)
            return;
        selected = Math.max(0, Math.min(results.length - 1, selected + delta));
        grid.positionViewAtIndex(selected, GridView.Contain);
    }

    function applySelected() {
        const w = results[selected];
        if (w)
            Wallpaper.apply(w.path);
    }

    function selectCurrent() {
        const idx = results.findIndex(w => w.path === Wallpaper.current);
        selected = Math.max(0, idx);
        grid.positionViewAtIndex(selected, GridView.Center);
    }

    function selectFolder(value) {
        folder = value;
        search.focusInput();
    }

    function cycleFolder(delta) {
        const order = ["", ...folderList.map(f => f.path)];
        const i = order.indexOf(folder);
        folder = order[(i + delta + order.length) % order.length];
    }

    onActiveChanged: {
        if (active) {
            search.text = "";
            folder = "";
            Wallpaper.refresh();
            selectCurrent();
            search.focusInput();
        }
    }
    onResultsChanged: {
        if (active && selected >= results.length)
            selected = Math.max(0, results.length - 1);
    }
    onFolderChanged: {
        selected = 0;
        grid.positionViewAtBeginning();
    }

    Connections {
        target: Wallpaper
        function onLoadingChanged() {
            if (!Wallpaper.loading && root.active && !search.text)
                root.selectCurrent();
        }
    }

    component Chip: Rectangle {
        id: chip
        property string label
        property string value
        property int count: -1
        readonly property bool selected: root.folder === value
        width: chipRow.implicitWidth + 22
        height: 28
        radius: Tokens.radius.chip
        color: selected ? Theme.wsActiveBg : chipMouse.containsMouse ? Theme.controlBg : Theme.tileBg
        Behavior on color { CAnim { duration: Tokens.duration.fade } }

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: chip.label
                color: chip.selected ? Theme.wsActiveText : Theme.textPrimary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            Text {
                visible: chip.count >= 0
                text: chip.count
                color: chip.selected ? Qt.alpha(Theme.wsActiveText, 0.55) : Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // Inline components can't see outer ids, hence the function on root
            onClicked: root.selectFolder(chip.value)
        }
    }

    SearchField {
        id: search
        width: parent.width
        trailingMargin: 10
        placeholder: "Search wallpapers"
        onTextChanged: {
            root.selected = 0;
            grid.positionViewAtBeginning();
        }
        onKeyPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
                root.closeRequested();
            } else if (event.key === Qt.Key_Right || (ctrl && event.key === Qt.Key_L)) {
                root.move(1);
            } else if (event.key === Qt.Key_Left || (ctrl && event.key === Qt.Key_H)) {
                root.move(-1);
            } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) {
                root.move(root.columns);
            } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) {
                root.move(-root.columns);
            } else if (event.key === Qt.Key_Tab) {
                root.cycleFolder(1);
            } else if (event.key === Qt.Key_Backtab) {
                root.cycleFolder(-1);
            } else if (ctrl && event.key === Qt.Key_R) {
                Wallpaper.applyRandom();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.applySelected();
                if (event.modifiers & Qt.ShiftModifier)
                    root.closeRequested();
            } else {
                return;
            }
            event.accepted = true;
        }

        Rectangle {
            id: randomBtn
            anchors.verticalCenter: parent.verticalCenter
            width: randomRow.implicitWidth + 24
            height: 32
            radius: Tokens.radius.button
            color: randomMouse.containsMouse ? Theme.controlHover : Theme.controlBg
            Behavior on color { CAnim {} }

            Row {
                id: randomRow
                anchors.centerIn: parent
                spacing: 7

                Canvas {
                    width: 14
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    property color tint: Theme.textPrimary
                    onTintChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = tint;
                        ctx.lineWidth = 1.6;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        ctx.beginPath();
                        ctx.moveTo(1, 3.5); ctx.lineTo(4, 3.5);
                        ctx.bezierCurveTo(8, 3.5, 6, 10.5, 10, 10.5); ctx.lineTo(13, 10.5);
                        ctx.moveTo(1, 10.5); ctx.lineTo(4, 10.5);
                        ctx.bezierCurveTo(8, 10.5, 6, 3.5, 10, 3.5); ctx.lineTo(13, 3.5);
                        ctx.moveTo(11, 1.5); ctx.lineTo(13, 3.5); ctx.lineTo(11, 5.5);
                        ctx.moveTo(11, 8.5); ctx.lineTo(13, 10.5); ctx.lineTo(11, 12.5);
                        ctx.stroke();
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Random"
                    color: Theme.textPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }
            }

            MouseArea {
                id: randomMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Wallpaper.applyRandom();
                    search.focusInput();
                }
            }
        }
    }

    ListView {
        id: chips
        anchors.top: search.bottom
        anchors.topMargin: 10
        width: parent.width
        height: 28
        orientation: ListView.Horizontal
        spacing: 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: [{ path: "", name: "All", count: Wallpaper.wallpapers.length }, ...root.folderList]

        delegate: Chip {
            required property var modelData
            label: modelData.name
            value: modelData.path
            count: modelData.count
        }

        WheelHandler {
            onWheel: event => chips.flick((event.angleDelta.y || event.angleDelta.x) * 8, 0)
        }
    }

    Rectangle {
        id: gridArea
        anchors.top: chips.bottom
        anchors.topMargin: 10
        anchors.bottom: footer.top
        anchors.bottomMargin: 8
        width: parent.width
        radius: Tokens.radius.field
        color: "transparent"

        Column {
            anchors.centerIn: parent
            spacing: 6
            visible: root.results.length === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Wallpaper.loading ? "Loading wallpapers…" : search.text ? "No wallpapers match" : "No wallpapers found"
                color: Theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !Wallpaper.loading && !search.text
                text: "Add folders in Wallpaper.qml"
                color: Theme.textSecondary
                font.pixelSize: 12
                font.family: Theme.fontFamily
            }
        }

        GridView {
            id: grid
            anchors.fill: parent
            clip: true
            cellWidth: width / root.columns
            cellHeight: cellWidth * 0.68
            model: root.results
            boundsBehavior: Flickable.StopAtBounds
            // One row kept ready past each edge, and cards reused as they scroll out
            cacheBuffer: cellHeight
            reuseItems: true
            currentIndex: root.selected

            delegate: Item {
                id: cell

                required property var modelData
                required property int index
                readonly property bool isSelected: index === root.selected
                readonly property bool isCurrent: modelData.path === Wallpaper.current

                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    id: card
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: Tokens.radius.field
                    // Shown until the thumbnail has loaded
                    color: Theme.controlBg
                    scale: cellMouse.pressed ? 0.96 : cell.isSelected ? 1.0 : 0.985
                    Behavior on scale { Anim { duration: Tokens.duration.fade } }

                    Image {
                        id: img
                        anchors.fill: parent
                        // No version in the URL: a thumbnail only appears (hasThumb), it is never
                        // rewritten in place, so the image cache can keep every one
                        source: cell.modelData.hasThumb ? "file://" + cell.modelData.thumb : ""
                        sourceSize.width: 480
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { Anim {} }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 30
                        color: Qt.alpha(Theme.islandBg, 0.8)
                        opacity: cell.isSelected ? 1 : 0
                        Behavior on opacity { Anim { duration: Tokens.duration.fade } }

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideMiddle
                            text: cell.modelData.label
                            color: Theme.textPrimary
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                        }
                    }

                    // Rounds the corners: a ring in the island's color over the square corners of
                    // the image and the label. Far cheaper than a ClippingRectangle per card,
                    // which renders two offscreen layers and a shader for every card on screen.
                    // The ring must be at least 0.42 x radius wide to cover a corner; it reaches
                    // 8px past the card, inside the 10px gap between cards.
                    Rectangle {
                        readonly property int reach: 8
                        anchors.fill: parent
                        anchors.margins: -reach
                        radius: card.radius + reach
                        color: "transparent"
                        border.width: reach
                        border.color: Theme.islandBg
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: 2
                        border.color: cell.isSelected ? Theme.textPrimary : cell.isCurrent ? Theme.accent : "transparent"
                        Behavior on border.color { CAnim { duration: Tokens.duration.fade } }
                    }

                    Rectangle {
                        visible: cell.isCurrent
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 9
                        width: 22
                        height: 22
                        radius: height / 2
                        color: Theme.accent

                        Canvas {
                            anchors.centerIn: parent
                            width: 12
                            height: 10
                            property color tint: Theme.onAccent
                            onTintChanged: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = tint;
                                ctx.lineWidth = 2;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";
                                ctx.beginPath();
                                ctx.moveTo(1.5, 5);
                                ctx.lineTo(4.5, 8);
                                ctx.lineTo(10.5, 2);
                                ctx.stroke();
                            }
                        }
                    }
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selected = cell.index
                    onClicked: {
                        Wallpaper.apply(cell.modelData.path);
                        search.focusInput();
                    }
                    onDoubleClicked: {
                        Wallpaper.apply(cell.modelData.path);
                        root.closeRequested();
                    }
                }
            }
        }
    }

    Item {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        height: 22

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "↵ apply   ⇧↵ apply & close   ←↑↓→ navigate   Tab folder   Ctrl+R random   Esc close"
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: Wallpaper.generating
            text: "Generating previews…"
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }
}
