import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services

// The wallpaper picker (Alt + W), with no surface of its own: the pill grows into it in pill
// mode, and the bar's panel holds it in bar mode. Type to filter, arrows to move, Enter to set
// (Shift + Enter also closes), Ctrl + R for a random one. Click to set, double click to set and
// close.
Item {
    id: root

    property bool active: false
    property int selected: 0

    readonly property int columns: 4
    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        return q ? Wallpaper.wallpapers.filter(w => w.label.toLowerCase().includes(q)) : Wallpaper.wallpapers;
    }

    signal closeRequested()

    implicitWidth: 740
    implicitHeight: 520

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
        selected = Math.max(0, results.findIndex(w => w.path === Wallpaper.current));
        grid.positionViewAtIndex(selected, GridView.Center);
    }

    onActiveChanged: {
        if (active) {
            input.text = "";
            Wallpaper.refresh();
            selectCurrent();
            input.forceActiveFocus();
        }
    }
    onResultsChanged: {
        if (selected >= results.length)
            selected = Math.max(0, results.length - 1);
    }

    Connections {
        target: Wallpaper
        function onLoadingChanged() {
            if (!Wallpaper.loading && root.active && !input.text)
                root.selectCurrent();
        }
    }

    // Search, and a random pick
    Item {
        id: search
        width: parent.width
        height: 44

        Text {
            id: glass
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "󰍉"
            color: Theme.textDim
            font.pixelSize: 17
            font.family: Theme.monoFamily
        }

        TextInput {
            id: input
            anchors.left: glass.right
            anchors.leftMargin: 12
            anchors.right: random.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            selectionColor: Theme.accent
            selectedTextColor: Theme.accentText
            font.pixelSize: 16
            font.family: Theme.fontFamily
            clip: true

            onTextChanged: {
                root.selected = 0;
                grid.positionViewAtBeginning();
            }

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier;
                if (event.key === Qt.Key_Escape)
                    root.closeRequested();
                else if (event.key === Qt.Key_Right || (ctrl && event.key === Qt.Key_L))
                    root.move(1);
                else if (event.key === Qt.Key_Left || (ctrl && event.key === Qt.Key_H))
                    root.move(-1);
                else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J))
                    root.move(root.columns);
                else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K))
                    root.move(-root.columns);
                else if (ctrl && event.key === Qt.Key_R)
                    Wallpaper.applyRandom();
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.applySelected();
                    if (event.modifiers & Qt.ShiftModifier)
                        root.closeRequested();
                } else
                    return;
                event.accepted = true;
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !input.text
                text: "Search wallpapers"
                color: Theme.textDim
                font: input.font
            }
        }

        Text {
            id: count
            anchors.right: random.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text !== ""
            text: root.results.length
            color: Theme.textDim
            font.pixelSize: 12
            font.family: Theme.monoFamily
        }

        Rectangle {
            id: random
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: randomRow.implicitWidth + 24
            height: 30
            radius: 15
            color: randomMouse.containsMouse ? Theme.tileHover : Theme.tile
            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                id: randomRow
                anchors.centerIn: parent
                spacing: 7

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰒝"
                    color: Theme.text
                    font.pixelSize: 14
                    font.family: Theme.monoFamily
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Random"
                    color: Theme.text
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

    Rectangle {
        id: divider
        anchors.top: search.bottom
        width: parent.width
        height: 1
        color: Theme.border
    }

    Item {
        id: gridArea
        anchors.top: divider.bottom
        anchors.topMargin: 8
        anchors.bottom: footer.top
        anchors.bottomMargin: 6
        width: parent.width

        Text {
            anchors.centerIn: parent
            visible: root.results.length === 0
            text: Wallpaper.loading ? "Loading wallpapers…"
                : input.text ? "No wallpapers match"
                : "No images in ~/Pictures/wallpapers"
            color: Theme.textDim
            font.pixelSize: 14
            font.family: Theme.fontFamily
        }

        GridView {
            id: grid
            anchors.fill: parent
            clip: true
            cellWidth: width / root.columns
            cellHeight: cellWidth * 0.66
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
                    anchors.fill: parent
                    anchors.margins: 5
                    radius: 16
                    color: Theme.tile
                    scale: cellMouse.pressed ? 0.96 : cell.isSelected ? 1.0 : 0.985
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

                    ClippingRectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: 13
                        color: Theme.control

                        Image {
                            anchors.fill: parent
                            source: cell.modelData.hasThumb ? "file://" + cell.modelData.thumb + "?v=" + Wallpaper.thumbsVersion : ""
                            sourceSize.width: 480
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        // The name, on the selected one
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 28
                            color: Qt.alpha(Theme.background, 0.8)
                            opacity: cell.isSelected ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 140 } }

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideMiddle
                                text: cell.modelData.label
                                color: Theme.text
                                font.pixelSize: 11
                                font.family: Theme.fontFamily
                            }
                        }
                    }

                    // Selected: a ring in the text color; on screen now: in the accent
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "transparent"
                        border.width: 2
                        border.color: cell.isSelected ? Theme.text : cell.isCurrent ? Theme.accent : "transparent"
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

                        Text {
                            anchors.centerIn: parent
                            text: "󰄬"
                            color: Theme.accentText
                            font.pixelSize: 13
                            font.family: Theme.monoFamily
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
        height: 20

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "↵ set   ⇧↵ set & close   ←↑↓→ move   Ctrl+R random   Esc close"
            color: Theme.textDim
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            visible: Wallpaper.generating
            text: "Making previews…"
            color: Theme.textDim
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }
}
