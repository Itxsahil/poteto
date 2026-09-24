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
    implicitHeight: 552

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
        cellHeight: 116
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

                // The palette: surfaces on the left, then text, accent and the status colors.
                Row {
                    id: palette
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 10
                    height: 44
                    spacing: 4

                    Repeater {
                        id: swatches
                        model: ["tile", "control", "fill", "text", "textDim", "accent", "success", "warning", "caution", "danger"]

                        Rectangle {
                            required property string modelData
                            width: (palette.width - palette.spacing * (swatches.count - 1)) / swatches.count
                            height: palette.height
                            radius: 7
                            color: cell.colors[modelData] ?? "transparent"
                        }
                    }
                }

                Text {
                    id: themeName
                    anchors.left: parent.left
                    anchors.right: check.visible ? check.left : parent.right
                    anchors.top: palette.bottom
                    anchors.leftMargin: 12
                    anchors.rightMargin: check.visible ? 8 : 12
                    anchors.topMargin: 8
                    elide: Text.ElideRight
                    text: cell.modelData.name
                    color: cell.colors.text ?? Theme.textPrimary
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Text {
                    anchors.left: themeName.left
                    anchors.right: themeName.right
                    anchors.top: themeName.bottom
                    anchors.topMargin: 1
                    elide: Text.ElideRight
                    text: cell.isCurrent ? "Active" : cell.isApplying ? "Applying…" : (cell.modelData.variant === "light" ? "Light" : "Dark")
                    color: cell.isCurrent || cell.isApplying ? (cell.colors.accent ?? Theme.accent) : (cell.colors.textDim ?? Theme.textSecondary)
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }

                Rectangle {
                    id: check
                    visible: cell.isCurrent
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.top: palette.bottom
                    anchors.topMargin: 12
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
