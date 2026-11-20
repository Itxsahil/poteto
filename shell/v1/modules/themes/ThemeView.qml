import QtQuick
import qs.config
import qs.components
import qs.services

Item {
    id: root

    property bool active: false
    property int selected: 0

    readonly property var results: {
        const q = search.text.trim().toLowerCase();
        return ThemeManager.themes.filter(t => !q || t.name.toLowerCase().includes(q) || t.variant.includes(q));
    }

    signal closeRequested()

    implicitWidth: 600
    implicitHeight: 176

    function move(delta) {
        if (results.length === 0)
            return;
        selected = Math.max(0, Math.min(results.length - 1, selected + delta));
    }

    function applySelected() {
        const t = results[selected];
        if (t && t.id !== ThemeManager.current)
            ThemeManager.apply(t.id);
    }

    function selectCurrent() {
        selected = Math.max(0, results.findIndex(t => t.id === ThemeManager.current));
        list.positionViewAtIndex(selected, ListView.Center);
    }

    // The selected card's colors are shown on the whole shell while browsing (Theme.preview);
    // closing without applying fades back to the active theme
    function updatePreview() {
        Theme.preview = active ? (results[selected]?.colors ?? null) : null;
    }

    readonly property var selectedTheme: results[selected] ?? null
    readonly property bool dynamicSelected: selectedTheme?.id === ThemeManager.dynamicId

    onActiveChanged: {
        if (active) {
            search.text = "";
            ThemeManager.refresh();
            selectCurrent();
            search.focusInput();
        }
        updatePreview();
    }
    onSelectedChanged: updatePreview()
    Component.onDestruction: Theme.preview = null
    onResultsChanged: {
        if (selected >= results.length)
            selected = Math.max(0, results.length - 1);
        updatePreview();
    }

    Connections {
        target: ThemeManager
        function onThemesChanged() {
            if (root.active && !search.text)
                root.selectCurrent();
        }
    }

    SearchField {
        id: search
        width: parent.width
        placeholder: "Search themes"
        onTextChanged: root.selected = 0
        onKeyPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
                root.closeRequested();
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab
                    || (ctrl && (event.key === Qt.Key_L || event.key === Qt.Key_J))) {
                root.move(1);
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab
                    || (ctrl && (event.key === Qt.Key_H || event.key === Qt.Key_K))) {
                root.move(-1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.applySelected();
                if (event.modifiers & Qt.ShiftModifier)
                    root.closeRequested();
            } else if (ctrl && event.key === Qt.Key_D && root.dynamicSelected) {
                // The dynamic theme's mode: dark → light → auto (rebuilt and applied)
                ThemeManager.cycleDynamicMode();
            } else if (ctrl && event.key === Qt.Key_S && root.dynamicSelected) {
                // Its Material You style: tonal-spot → vibrant → expressive → …
                ThemeManager.cycleDynamicScheme();
            } else {
                return;
            }
            event.accepted = true;
        }

        Text {
            id: status
            anchors.verticalCenter: parent.verticalCenter
            text: ThemeManager.applying ? "Applying…" : root.results.length ? `${root.selected + 1}/${root.results.length}` : ""
            color: ThemeManager.applying ? Theme.accent : Theme.textSecondary
            font.pixelSize: 11
            font.weight: ThemeManager.applying ? Font.DemiBold : Font.Normal
            font.family: Theme.fontFamily
        }
    }

    Text {
        anchors.centerIn: list
        visible: root.results.length === 0
        text: ThemeManager.themes.length === 0 ? "No themes found" : "No themes match"
        color: Theme.textSecondary
        font.pixelSize: 13
        font.family: Theme.fontFamily
    }

    // One row of cards; the selected card always sits in the middle.
    ListView {
        id: list

        readonly property int cardWidth: 136
        readonly property int cardHeight: 84

        anchors.top: search.bottom
        anchors.topMargin: 16
        width: parent.width
        height: cardHeight
        clip: true
        orientation: ListView.Horizontal
        spacing: 10
        model: root.results
        currentIndex: root.selected
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - cardWidth) / 2
        preferredHighlightEnd: (width + cardWidth) / 2
        highlightMoveDuration: 220
        boundsBehavior: Flickable.StopAtBounds
        onCurrentIndexChanged: {
            if (currentIndex >= 0)
                root.selected = currentIndex;
        }

        WheelHandler {
            property real accumulated: 0
            onWheel: event => {
                accumulated += event.angleDelta.y || -event.angleDelta.x;
                if (Math.abs(accumulated) < 120)
                    return;
                root.move(accumulated > 0 ? -1 : 1);
                accumulated = 0;
            }
        }

        delegate: Rectangle {
            id: card

            required property var modelData
            required property int index
            readonly property var colors: modelData.colors
            readonly property bool isSelected: index === root.selected
            readonly property bool isCurrent: modelData.id === ThemeManager.current
            // Up to seven distinct colors: the status colors, the accent, then the foreground.
            readonly property var dots: {
                const seen = [];
                for (const key of ["danger", "caution", "warning", "success", "accent", "fill", "textDim", "muted"]) {
                    const c = colors[key];
                    if (c && !seen.includes(c.toLowerCase()))
                        seen.push(c.toLowerCase());
                }
                return seen.slice(0, 7);
            }
            // Cards fade out towards the edges of the row.
            readonly property real distance: Math.min(1, Math.abs(x + width / 2 - list.contentX - list.width / 2) / (list.width / 2))

            width: list.cardWidth
            height: list.cardHeight
            radius: Tokens.radius.chip
            color: colors.island ?? Theme.tileBg
            border.width: isSelected ? 2 : 1
            border.color: isSelected ? (colors.accent ?? Theme.accent) : (colors.border ?? "transparent")
            opacity: isSelected ? 1 : 0.9 - 0.45 * distance
            scale: cardMouse.pressed ? 0.96 : 1
            Behavior on scale { Anim { duration: Tokens.duration.press } }
            Behavior on border.color { CAnim { duration: Tokens.duration.fade } }

            // The active theme
            Rectangle {
                visible: card.isCurrent
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 9
                width: 6
                height: 6
                radius: height / 2
                color: card.colors.accent ?? Theme.accent
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 26
                spacing: 5

                Repeater {
                    model: card.dots

                    Rectangle {
                        required property string modelData
                        width: 11
                        height: 11
                        radius: height / 2
                        color: modelData
                    }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                anchors.bottomMargin: 12
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                // The dynamic theme shows its mode: "Dynamic · auto"
                text: card.modelData.id === ThemeManager.dynamicId
                    ? `${card.modelData.name} · ${card.colors.mode ?? card.modelData.variant}`
                    : card.modelData.name
                color: card.isSelected ? (card.colors.text ?? Theme.textPrimary) : (card.colors.textDim ?? Theme.textSecondary)
                font.pixelSize: 11
                font.weight: card.isSelected ? Font.DemiBold : Font.Normal
                font.family: Theme.fontFamily
            }

            MouseArea {
                id: cardMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (card.isSelected)
                        root.applySelected();
                    else
                        root.selected = card.index;
                    search.focusInput();
                }
                onDoubleClicked: {
                    if (!ThemeManager.applying)
                        root.applySelected();
                    root.closeRequested();
                }
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.bottom: parent.bottom
        text: root.dynamicSelected
            ? `From the wallpaper · ${root.selectedTheme.colors.scheme ?? "tonal-spot"} · Ctrl+D mode · Ctrl+S style · Enter to apply`
            : "Enter to apply"
        color: Theme.textSecondary
        font.pixelSize: 11
        font.family: Theme.fontFamily
    }
}
