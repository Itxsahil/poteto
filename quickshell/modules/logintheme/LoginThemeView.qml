import QtQuick
import qs.config
import qs.components
import qs.components.icons
import qs.services

Item {
    id: root

    property bool active: false
    property int selected: 0

    readonly property int columns: 2
    readonly property var themes: LoginTheme.themes

    signal closeRequested()

    implicitWidth: 740
    implicitHeight: 540

    function move(delta) {
        if (themes.length === 0)
            return;
        selected = Math.max(0, Math.min(themes.length - 1, selected + delta));
        grid.positionViewAtIndex(selected, GridView.Contain);
    }

    function applySelected() {
        const t = themes[selected];
        if (t)
            LoginTheme.apply(t.id);
    }

    function previewSelected() {
        const t = themes[selected];
        if (t)
            LoginTheme.preview(t.id);
    }

    function selectActive() {
        selected = Math.max(0, themes.findIndex(t => t.id === LoginTheme.active));
        grid.positionViewAtIndex(selected, GridView.Contain);
    }

    onActiveChanged: {
        if (active) {
            LoginTheme.refresh();
            if (!LoginTheme.applying)
                selectActive();
            keys.forceActiveFocus();
        }
    }
    onThemesChanged: {
        if (selected >= themes.length)
            selected = Math.max(0, themes.length - 1);
    }

    Item {
        id: keys
        focus: root.active

        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
                root.closeRequested();
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L || (ctrl && event.key === Qt.Key_L)) {
                root.move(1);
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H || (ctrl && event.key === Qt.Key_H)) {
                root.move(-1);
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J || (ctrl && event.key === Qt.Key_J)) {
                root.move(root.columns);
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K || (ctrl && event.key === Qt.Key_K)) {
                root.move(-root.columns);
            } else if (event.key === Qt.Key_P) {
                root.previewSelected();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.applySelected();
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    Rectangle {
        id: header
        width: parent.width
        height: 48
        radius: 18
        color: Theme.tileBg

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: "Login screen"
            color: Theme.textPrimary
            font.pixelSize: 16
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Spinner {
                anchors.verticalCenter: parent.verticalCenter
                width: 13
                height: 13
                visible: LoginTheme.applying !== ""
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: LoginTheme.applying ? "Switching…"
                    : LoginTheme.message ? LoginTheme.message
                    : `${root.themes.length} themes`
                color: LoginTheme.messageIsError ? Theme.danger
                    : LoginTheme.applying || LoginTheme.message ? Theme.accent
                    : Theme.textSecondary
                font.pixelSize: 11
                font.weight: LoginTheme.applying || LoginTheme.message ? Font.DemiBold : Font.Normal
                font.family: Theme.fontFamily
            }
        }
    }

    // Shown until sddm-themes/setup has installed the root helper.
    Rectangle {
        id: setupNote
        anchors.top: header.bottom
        anchors.topMargin: visible ? 10 : 0
        width: parent.width
        height: visible ? setupText.implicitHeight + 20 : 0
        visible: LoginTheme.themesDir !== "" && !LoginTheme.helperInstalled
        radius: 14
        color: Qt.alpha(Theme.danger, 0.12)

        Text {
            id: setupText
            anchors.fill: parent
            anchors.margins: 10
            anchors.leftMargin: 14
            wrapMode: Text.Wrap
            text: `One-time setup needed. In a terminal run:  ${LoginTheme.themesDir}/setup`
            color: Theme.textPrimary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }

    Text {
        anchors.centerIn: grid
        visible: root.themes.length === 0
        text: LoginTheme.themesDir ? "No login themes found" : "Loading…"
        color: Theme.textSecondary
        font.pixelSize: 13
        font.family: Theme.fontFamily
    }

    GridView {
        id: grid
        anchors.top: setupNote.bottom
        anchors.topMargin: 10
        anchors.bottom: footer.top
        anchors.bottomMargin: 8
        width: parent.width
        clip: true
        cellWidth: width / root.columns
        cellHeight: Math.round(cellWidth * 0.5625) + 58
        model: root.themes
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: root.selected

        delegate: Item {
            id: cell

            required property var modelData
            required property int index
            readonly property bool isSelected: index === root.selected
            readonly property bool isActive: modelData.id === LoginTheme.active
            readonly property bool isApplying: modelData.id === LoginTheme.applying

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: 16
                color: Theme.tileBg
                border.width: 2
                border.color: cell.isSelected ? Theme.textPrimary : cell.isActive ? Theme.accent : "transparent"
                scale: cellMouse.pressed ? 0.97 : 1
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Rectangle {
                    id: preview
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    height: width * 0.5625
                    radius: 11
                    color: Theme.controlBg
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: cell.modelData.hasThumb ? "file://" + cell.modelData.thumb + "?v=" + LoginTheme.thumbsVersion : ""
                        sourceSize.width: 640
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    Rectangle {
                        visible: cell.isActive
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 8
                        width: 22
                        height: 22
                        radius: 11
                        color: Theme.accent

                        CheckIcon {
                            anchors.centerIn: parent
                            width: 12
                            height: 9
                            color: Theme.onAccent
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
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.family: Theme.fontFamily
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: cell.isActive ? "Active" : cell.isApplying ? "Switching…" : cell.modelData.id
                        color: cell.isActive || cell.isApplying ? Theme.accent : Theme.textSecondary
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
            text: "↵ set as login screen   P preview   ←↑↓→ navigate   Esc close"
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }
}
