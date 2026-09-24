import QtQuick
import Quickshell.Widgets
import qs.config
import qs.components
import qs.components.icons
import qs.services

Item {
    id: root

    property bool active: false
    property int selected: 0

    readonly property var themes: LoginTheme.themes

    signal closeRequested()

    implicitWidth: 680
    implicitHeight: listBottom + 30

    // Everything above the footer; the view grows by the setup note's height when it shows.
    readonly property real listBottom: list.y + list.height

    function move(delta) {
        if (themes.length === 0)
            return;
        selected = Math.max(0, Math.min(themes.length - 1, selected + delta));
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
        list.positionViewAtIndex(selected, ListView.Center);
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
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab
                    || event.key === Qt.Key_L || event.key === Qt.Key_J) {
                root.move(1);
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab
                    || event.key === Qt.Key_H || event.key === Qt.Key_K) {
                root.move(-1);
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
                    : root.themes.length ? `${root.selected + 1}/${root.themes.length}` : ""
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
        anchors.centerIn: list
        visible: root.themes.length === 0
        text: LoginTheme.themesDir ? "No login themes found" : "Loading…"
        color: Theme.textSecondary
        font.pixelSize: 13
        font.family: Theme.fontFamily
    }

    // One row of cards; the selected card always sits in the middle.
    ListView {
        id: list

        readonly property int cardWidth: 272
        readonly property int imageHeight: Math.round((cardWidth - 12) * 0.5625)

        anchors.top: setupNote.bottom
        anchors.topMargin: 14
        width: parent.width
        height: imageHeight + 54
        clip: true
        orientation: ListView.Horizontal
        spacing: 12
        model: root.themes
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
            readonly property bool isSelected: index === root.selected
            readonly property bool isActive: modelData.id === LoginTheme.active
            readonly property bool isApplying: modelData.id === LoginTheme.applying
            // Cards fade out towards the edges of the row.
            readonly property real distance: Math.min(1, Math.abs(x + width / 2 - list.contentX - list.width / 2) / (list.width / 2))

            width: list.cardWidth
            height: list.height
            radius: 16
            color: Theme.tileBg
            border.width: 2
            border.color: isSelected ? Theme.accent : "transparent"
            opacity: isSelected ? 1 : 0.9 - 0.5 * distance
            scale: cardMouse.pressed ? 0.97 : 1
            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            // ClippingRectangle, unlike clip on a Rectangle, cuts the image to the rounded corners.
            ClippingRectangle {
                id: preview
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                height: list.imageHeight
                radius: 10
                color: Theme.controlBg

                Image {
                    anchors.fill: parent
                    source: card.modelData.hasThumb ? "file://" + card.modelData.thumb + "?v=" + LoginTheme.thumbsVersion : ""
                    sourceSize.width: 640
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    opacity: status === Image.Ready ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                Rectangle {
                    visible: card.isActive
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
                    text: card.modelData.name
                    color: card.isSelected ? Theme.textPrimary : Theme.textSecondary
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: card.isActive ? "Active" : card.isApplying ? "Switching…" : card.modelData.id
                    color: card.isActive || card.isApplying ? Theme.accent : Theme.textSecondary
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }
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
                }
            }
        }
    }

    Item {
        id: footer
        anchors.top: list.bottom
        anchors.topMargin: 8
        width: parent.width
        height: 22

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "↵ set as login screen   P preview   ←→ navigate   Esc close"
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }
}
