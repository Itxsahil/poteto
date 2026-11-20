import QtQuick
import qs.config
import qs.components
import qs.services

Item {
    id: root

    property bool active: false
    property string group: "smileys"
    property int selected: 0
    property string flash: ""

    readonly property int columns: 14
    readonly property var results: Emoji.search(search.text, group)
    readonly property var current: results[selected] ?? null
    readonly property string emojiFont: "Noto Color Emoji"

    signal closeRequested()

    implicitWidth: 740
    implicitHeight: 500

    function move(delta) {
        if (results.length === 0)
            return;
        selected = Math.max(0, Math.min(results.length - 1, selected + delta));
        grid.positionViewAtIndex(selected, GridView.Contain);
    }

    function pick(item, keepOpen) {
        if (!item)
            return;
        Emoji.copy(item.e);
        if (keepOpen) {
            flash = item.e;
            flashTimer.restart();
        } else {
            closeRequested();
        }
    }

    function cycleGroup(delta) {
        const ids = Emoji.groups.map(g => g.id);
        group = ids[(ids.indexOf(group) + delta + ids.length) % ids.length];
    }

    onActiveChanged: {
        if (active) {
            search.text = "";
            group = Emoji.recent.length > 0 ? "recent" : "smileys";
            selected = 0;
            grid.positionViewAtBeginning();
            search.focusInput();
        }
    }
    onResultsChanged: {
        selected = 0;
        grid.positionViewAtBeginning();
    }

    Timer {
        id: flashTimer
        interval: 1200
        onTriggered: root.flash = ""
    }

    SearchField {
        id: search
        width: parent.width
        placeholder: "Search emoji"
        onKeyPressed: event => {
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
                root.cycleGroup(1);
            } else if (event.key === Qt.Key_Backtab) {
                root.cycleGroup(-1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.pick(root.current, shift);
            } else {
                return;
            }
            event.accepted = true;
        }

        Text {
            id: countLabel
            anchors.verticalCenter: parent.verticalCenter
            text: root.flash ? `Copied ${root.flash}` : `${root.results.length}`
            color: root.flash ? Theme.accent : Theme.textSecondary
            font.pixelSize: root.flash ? 12 : 11
            font.weight: root.flash ? Font.DemiBold : Font.Normal
            font.family: Theme.fontFamily
        }
    }

    Row {
        id: groupRow
        anchors.top: search.bottom
        anchors.topMargin: 10
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
        opacity: search.text ? 0.4 : 1
        Behavior on opacity { Anim { duration: Tokens.duration.fade } }

        Repeater {
            model: Emoji.groups

            Rectangle {
                id: chip
                required property var modelData
                readonly property bool isSelected: root.group === modelData.id && !search.text

                width: 66
                height: 50
                radius: Tokens.radius.button
                color: isSelected ? Theme.tileHover : chipMouse.containsMouse ? Theme.tileBg : "transparent"
                border.width: isSelected ? 1 : 0
                border.color: Theme.accent
                Behavior on color { CAnim {} }

                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: chip.modelData.icon
                        font.pixelSize: 18
                        font.family: root.emojiFont
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: chip.modelData.label
                        color: chip.isSelected ? Theme.textPrimary : Theme.textSecondary
                        font.pixelSize: 10
                        font.weight: chip.isSelected ? Font.DemiBold : Font.Normal
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        search.text = "";
                        root.group = chip.modelData.id;
                        search.focusInput();
                    }
                }
            }
        }
    }

    Column {
        anchors.centerIn: grid
        spacing: 6
        visible: root.results.length === 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: search.text ? "No emoji found" : root.group === "recent" ? "No recent emoji yet" : "Nothing here"
            color: Theme.textPrimary
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: search.text ? "Try another word" : "Emoji you pick will show up here"
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }

    GridView {
        id: grid
        anchors.top: groupRow.bottom
        anchors.topMargin: 10
        anchors.bottom: footer.top
        anchors.bottomMargin: 8
        width: parent.width
        clip: true
        cellWidth: width / root.columns
        cellHeight: cellWidth
        model: root.results
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: cellHeight * 4

        delegate: Item {
            id: cell

            required property var modelData
            required property int index
            readonly property bool isSelected: index === root.selected

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: Tokens.radius.row
                color: cell.isSelected ? Theme.tileHover : cellMouse.containsMouse ? Theme.tileBg : "transparent"
                border.width: cell.isSelected ? 1 : 0
                border.color: Theme.accent
            }

            Text {
                anchors.centerIn: parent
                text: cell.modelData.e
                font.pixelSize: 26
                font.family: root.emojiFont
                scale: cellMouse.pressed ? 0.85 : cell.isSelected ? 1.12 : 1
                Behavior on scale { Anim { duration: Tokens.duration.press } }
            }

            MouseArea {
                id: cellMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onEntered: root.selected = cell.index
                onClicked: event => {
                    root.pick(cell.modelData, event.button === Qt.RightButton || (event.modifiers & Qt.ShiftModifier));
                    search.focusInput();
                }
            }
        }
    }

    Item {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        height: 24

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: root.current !== null

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.current?.e ?? ""
                font.pixelSize: 16
                font.family: root.emojiFont
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.current?.n ?? ""
                color: Theme.textPrimary
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "↵ copy   ⇧↵ / right click copy & stay   Tab category   Esc close"
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }
}
