import QtQuick
import qs.config
import qs.components.icons
import qs.services

Item {
    id: root

    property bool active: false
    property int selected: 0

    readonly property int columns: 3
    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        return ThemeManager.themes.filter(t => !q || t.name.toLowerCase().includes(q) || t.variant.includes(q));
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
        const t = results[selected];
        if (t && t.id !== ThemeManager.current)
            ThemeManager.apply(t.id);
    }

    function selectCurrent() {
        selected = Math.max(0, results.findIndex(t => t.id === ThemeManager.current));
        grid.positionViewAtIndex(selected, GridView.Contain);
    }

    onActiveChanged: {
        if (active) {
            input.text = "";
            ThemeManager.refresh();
            selectCurrent();
            input.forceActiveFocus();
        }
    }
    onResultsChanged: {
        if (selected >= results.length)
            selected = Math.max(0, results.length - 1);
    }

    Connections {
        target: ThemeManager
        function onThemesChanged() {
            if (root.active && !input.text)
                root.selectCurrent();
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
                text: "Search themes"
                color: Theme.textSecondary
                font: input.font
            }
        }

        Text {
            id: status
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: ThemeManager.applying ? "Applying…" : `${ThemeManager.themes.length} themes`
            color: ThemeManager.applying ? Theme.accent : Theme.textSecondary
            font.pixelSize: 11
            font.weight: ThemeManager.applying ? Font.DemiBold : Font.Normal
            font.family: Theme.fontFamily
        }
    }

    Text {
        anchors.centerIn: grid
        visible: root.results.length === 0
        text: ThemeManager.themes.length === 0 ? "No themes found" : "No themes match"
        color: Theme.textSecondary
        font.pixelSize: 13
        font.family: Theme.fontFamily
    }

    GridView {
        id: grid
        anchors.top: search.bottom
        anchors.topMargin: 10
        anchors.bottom: footer.top
        anchors.bottomMargin: 8
        width: parent.width
        clip: true
        cellWidth: width / root.columns
        cellHeight: Math.round(cellWidth * 0.625) + 58
        model: root.results
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: root.selected

        delegate: Item {
            id: cell

            required property var modelData
            required property int index
            readonly property var colors: modelData.colors
            readonly property bool isSelected: index === root.selected
            readonly property bool isCurrent: modelData.id === ThemeManager.current
            readonly property bool isApplying: ThemeManager.applying && ThemeManager.pending === "" && isSelected && !isCurrent

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                id: card
                anchors.fill: parent
                anchors.margins: 5
                radius: 16
                color: cell.colors.island ?? Theme.tileBg
                border.width: 2
                border.color: cell.isSelected ? Theme.textPrimary : cell.isCurrent ? Theme.accent : (cell.colors.border ?? "transparent")
                scale: cellMouse.pressed ? 0.97 : 1
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Rectangle {
                    id: preview
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    height: width * 0.625
                    radius: 11
                    color: cell.colors.tile ?? Theme.controlBg
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: cell.modelData.hasThumb ? "file://" + cell.modelData.thumb + "?v=" + ThemeManager.thumbsVersion : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        spacing: -4

                        Repeater {
                            model: ["island", "tile", "accent", "success", "warning", "danger", "text"]

                            Rectangle {
                                required property string modelData
                                width: 18
                                height: 18
                                radius: 9
                                color: cell.colors[modelData] ?? "transparent"
                                border.width: 2
                                border.color: cell.colors.island ?? "#000000"
                            }
                        }
                    }

                    Rectangle {
                        visible: cell.isCurrent
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        width: 22
                        height: 22
                        radius: 11
                        color: cell.colors.accent ?? Theme.accent

                        CheckIcon {
                            anchors.centerIn: parent
                            width: 12
                            height: 9
                            color: cell.colors.onAccent ?? Theme.onAccent
                        }
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: preview.bottom
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.topMargin: 8
                    spacing: 1

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: cell.modelData.name
                        color: cell.colors.text ?? Theme.textPrimary
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.family: Theme.fontFamily
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: cell.isCurrent ? "Active" : cell.isApplying ? "Applying…" : (cell.modelData.variant === "light" ? "Light" : "Dark")
                        color: cell.isCurrent || cell.isApplying ? (cell.colors.accent ?? Theme.accent) : (cell.colors.textDim ?? Theme.textSecondary)
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
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
                    root.selected = cell.index;
                    root.applySelected();
                    input.forceActiveFocus();
                }
                onDoubleClicked: root.closeRequested()
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
            text: "↵ apply   ⇧↵ apply & close   ←↑↓→ navigate   Esc close"
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.name
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }
}
