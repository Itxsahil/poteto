import QtQuick
import qs.config
import qs.services

// Video browser in the island, in the shape of the wallpaper switcher: every video under
// ~/Videos in one grid, filtered by folder chips. Picking one opens the player window.
Item {
    id: root

    property bool active: false
    property int selected: 0
    property string folder: ""

    readonly property int columns: 3
    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        const want = folder === "." ? "" : folder;   // "." is the loose-files chip
        return Videos.entries.filter(e => (!folder || e.folder === want)
            && (!q || e.name.toLowerCase().includes(q) || e.folder.toLowerCase().includes(q)));
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

    function openEntry(entry, external) {
        if (!entry)
            return;
        if (external)
            Player.openExternally(entry.path);
        else
            Player.play(entry.path, results.map(e => e.path));
        root.closeRequested();
    }

    // Inline components can't see outer ids, hence these on root
    function selectFolder(value) {
        folder = value;
        selected = 0;
        grid.positionViewAtBeginning();
        input.forceActiveFocus();
    }

    function cycleFolder(delta) {
        const order = ["", ...Videos.folders.map(f => f.value)];
        const i = order.indexOf(folder);
        selectFolder(order[(i + delta + order.length) % order.length]);
    }

    onActiveChanged: {
        if (active) {
            input.text = "";
            folder = "";
            selected = 0;
            Videos.refresh();
            input.forceActiveFocus();
        }
    }
    onResultsChanged: {
        if (selected >= results.length)
            selected = Math.max(0, results.length - 1);
    }

    component Chip: Rectangle {
        id: chip
        property string label
        property string value
        property int count: -1
        readonly property bool current: root.folder === value
        width: chipRow.implicitWidth + 22
        height: 28
        radius: 14
        color: current ? Theme.wsActiveBg : chipMouse.containsMouse ? Theme.controlBg : Theme.tileBg
        Behavior on color { ColorAnimation { duration: 140 } }

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: chip.label
                color: chip.current ? Theme.wsActiveText : Theme.textPrimary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            Text {
                visible: chip.count >= 0
                text: chip.count
                color: chip.current ? Qt.alpha(Theme.wsActiveText, 0.55) : Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.selectFolder(chip.value)
        }
    }

    Rectangle {
        id: search
        width: parent.width
        height: 48
        radius: 18
        color: Theme.tileBg

        Canvas {
            id: glass
            width: 18
            height: 18
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            property color tint: Theme.textSecondary
            onTintChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = tint;
                ctx.lineWidth = 2;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(7.5, 7.5, 5.5, 0, Math.PI * 2);
                ctx.moveTo(11.5, 11.5);
                ctx.lineTo(16, 16);
                ctx.stroke();
            }
        }

        TextInput {
            id: input
            anchors.left: glass.right
            anchors.leftMargin: 12
            anchors.right: status.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textPrimary
            selectionColor: Theme.accent
            selectedTextColor: Theme.onAccent
            font.pixelSize: 16
            font.family: Theme.fontFamily
            clip: true

            onTextChanged: {
                root.selected = 0;
                grid.positionViewAtBeginning();
            }

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier;
                const shift = event.modifiers & Qt.ShiftModifier;
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
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.openEntry(root.results[root.selected], shift);
                } else {
                    return;
                }
                event.accepted = true;
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !input.text
                text: "Search videos"
                color: Theme.textSecondary
                font: input.font
            }
        }

        Text {
            id: status
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: Videos.loading ? "Loading…" : `${root.results.length} items`
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }

    ListView {
        id: chipBar
        anchors.top: search.bottom
        anchors.topMargin: 10
        width: parent.width
        height: 28
        orientation: ListView.Horizontal
        spacing: 6
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: [{ name: "All", value: "", count: Videos.entries.length }, ...Videos.folders]

        delegate: Chip {
            required property var modelData
            label: modelData.name
            value: modelData.value
            count: modelData.count
        }

        WheelHandler {
            onWheel: event => chipBar.flick((event.angleDelta.y || event.angleDelta.x) * 8, 0)
        }
    }

    Text {
        anchors.centerIn: grid
        visible: root.results.length === 0
        text: Videos.loading ? "Loading…"
            : input.text ? `No videos match "${input.text}"`
            : root.folder ? "Nothing in this folder"
            : "No videos in ~/Videos"
        color: Theme.textSecondary
        font.pixelSize: 13
        font.family: Theme.fontFamily
    }

    GridView {
        id: grid
        anchors.top: chipBar.bottom
        anchors.topMargin: 10
        anchors.bottom: footer.top
        anchors.bottomMargin: 8
        width: parent.width
        clip: true
        cellWidth: width / root.columns
        cellHeight: Math.round(cellWidth * 0.5625) + 46
        model: root.results
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: cellHeight * 3
        currentIndex: root.selected

        delegate: Item {
            id: cell

            required property var modelData
            required property int index
            readonly property bool isSelected: index === root.selected
            readonly property bool isPlaying: Player.source === modelData.path

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: 14
                color: cell.isSelected ? Theme.tileHover : Theme.tileBg
                scale: cellMouse.pressed ? 0.97 : 1
                border.width: 2
                border.color: cell.isSelected ? Theme.textPrimary : cell.isPlaying ? Theme.accent : "transparent"
                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Rectangle {
                    id: preview
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 4
                    height: width * 0.5625
                    radius: 10
                    color: Theme.controlBg
                    clip: true

                    Image {
                        id: poster
                        anchors.fill: parent
                        visible: cell.modelData.hasThumb
                        source: cell.modelData.hasThumb
                            ? "file://" + cell.modelData.thumb + "?v=" + Videos.thumbsVersion
                            : ""
                        sourceSize.width: 420
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    // Play mark while the poster frame is still being made
                    Canvas {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        visible: !poster.visible
                        property color tint: Theme.textSecondary
                        onTintChanged: requestPaint()
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            ctx.fillStyle = tint;
                            ctx.beginPath();
                            ctx.moveTo(4, 0);
                            ctx.lineTo(22, 11);
                            ctx.lineTo(4, 22);
                            ctx.closePath();
                            ctx.fill();
                        }
                    }

                    // Duration, bottom right of the poster
                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 6
                        width: durationText.implicitWidth + 12
                        height: 18
                        radius: 9
                        visible: cell.modelData.duration > 0
                        color: Qt.alpha("#000000", 0.65)

                        Text {
                            id: durationText
                            anchors.centerIn: parent
                            text: Videos.formatDuration(cell.modelData.duration)
                            color: "#ffffff"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.family: Theme.fontFamily
                        }
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: preview.bottom
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    anchors.topMargin: 6
                    spacing: 1

                    Text {
                        width: parent.width
                        elide: Text.ElideMiddle
                        text: cell.modelData.name
                        color: Theme.textPrimary
                        font.pixelSize: 12
                        font.weight: cell.isSelected ? Font.DemiBold : Font.Normal
                        font.family: Theme.fontFamily
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: cell.isPlaying ? "Playing"
                            : [cell.modelData.folderName, Videos.formatSize(cell.modelData.size)]
                                .filter(Boolean).join("  ·  ")
                        color: cell.isPlaying ? Theme.accent : Theme.textSecondary
                        font.pixelSize: 10
                        font.family: Theme.fontFamily
                    }
                }
            }

            MouseArea {
                id: cellMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onEntered: root.selected = cell.index
                onClicked: mouse => root.openEntry(cell.modelData, mouse.button === Qt.RightButton)
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
            text: "↵ play   ⇧↵ / right click mpv   ←↑↓→ navigate   Tab folder   Esc close"
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: Videos.generating
            text: "Making thumbnails…"
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }
}
