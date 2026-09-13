import QtQuick
import qs.config
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
        const q = input.text.trim().toLowerCase();
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

    function cycleFolder(delta) {
        const order = ["", ...folderList.map(f => f.path)];
        const i = order.indexOf(folder);
        folder = order[(i + delta + order.length) % order.length];
    }

    onActiveChanged: {
        if (active) {
            input.text = "";
            folder = "";
            Wallpaper.refresh();
            selectCurrent();
            input.forceActiveFocus();
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
            if (!Wallpaper.loading && root.active && !input.text)
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
        radius: 14
        color: selected ? Theme.wsActiveBg : chipMouse.containsMouse ? Theme.controlBg : Theme.tileBg
        Behavior on color { ColorAnimation { duration: 140 } }

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
            onClicked: {
                root.folder = chip.value;
                input.forceActiveFocus();
            }
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
            anchors.right: randomBtn.left
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

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !input.text
                text: "Search wallpapers"
                color: Theme.textSecondary
                font: input.font
            }
        }

        Rectangle {
            id: randomBtn
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: randomRow.implicitWidth + 24
            height: 32
            radius: 16
            color: randomMouse.containsMouse ? Theme.controlHover : Theme.controlBg
            Behavior on color { ColorAnimation { duration: 120 } }

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
                    input.forceActiveFocus();
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
        radius: 18
        color: "transparent"

        Column {
            anchors.centerIn: parent
            spacing: 6
            visible: root.results.length === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Wallpaper.loading ? "Loading wallpapers…" : input.text ? "No wallpapers match" : "No wallpapers found"
                color: Theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !Wallpaper.loading && !input.text
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
            cacheBuffer: cellHeight * 3
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
                    radius: 14
                    color: Theme.tileBg
                    scale: cellMouse.pressed ? 0.96 : cell.isSelected ? 1.0 : 0.985
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    Rectangle {
                        id: imageClip
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: 11
                        color: Theme.controlBg
                        clip: true

                        Image {
                            id: img
                            anchors.fill: parent
                            source: cell.modelData.hasThumb ? "file://" + cell.modelData.thumb + "?v=" + Wallpaper.thumbsVersion : ""
                            sourceSize.width: 480
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 30
                            color: Qt.alpha(Theme.islandBg, 0.8)
                            opacity: cell.isSelected ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 140 } }

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                                text: cell.modelData.label
                                color: Theme.textPrimary
                                font.pixelSize: 11
                                font.family: Theme.fontFamily
                            }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: 2
                        border.color: cell.isSelected ? Theme.textPrimary : cell.isCurrent ? Theme.accent : "transparent"
                        Behavior on border.color { ColorAnimation { duration: 140 } }
                    }

                    Rectangle {
                        visible: cell.isCurrent
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 9
                        width: 22
                        height: 22
                        radius: 11
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
                        input.forceActiveFocus();
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
