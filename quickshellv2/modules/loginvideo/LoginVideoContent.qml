import QtQuick
import qs.config
import qs.components
import qs.services

// Picks the video that plays behind the login screen (Alt + Shift + W), in the shape of the
// wallpaper picker: everything in ~/Videos/Hidamari as one grid of poster frames. Choosing one
// asks for your password, because publishing it to the greeter needs root.
Item {
    id: root

    property bool active: false
    property int selected: 0

    readonly property int columns: 3
    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        return LoginVideo.videos.filter(entry => !q || entry.name.toLowerCase().includes(q));
    }

    signal closeRequested()

    implicitWidth: 740
    implicitHeight: 540

    onActiveChanged: {
        if (active) {
            input.text = "";
            selected = 0;
            LoginVideo.refresh();
            input.forceActiveFocus();
        }
    }

    onResultsChanged: {
        if (selected >= results.length)
            selected = Math.max(0, results.length - 1);
    }

    function move(delta) {
        if (results.length === 0)
            return;
        selected = Math.max(0, Math.min(results.length - 1, selected + delta));
        grid.positionViewAtIndex(selected, GridView.Contain);
    }

    function choose(entry) {
        if (entry)
            LoginVideo.apply(entry.path);
    }

    Rectangle {
        id: search
        width: parent.width
        height: 48
        radius: 18
        color: Theme.tile

        TextInput {
            id: input
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.right: counter.left
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
                    root.choose(root.results[root.selected]);
                } else {
                    return;
                }
                event.accepted = true;
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !input.text
                text: "Search login videos"
                color: Theme.textDim
                font: input.font
            }
        }

        Text {
            id: counter
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: root.results.length + (root.results.length === 1 ? " video" : " videos")
            color: Theme.textDim
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }

    Text {
        anchors.centerIn: grid
        width: grid.width - 40
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: root.results.length === 0
        text: input.text ? "Nothing matches"
            : `No videos in ~/Videos/${LoginVideo.folder}`
        color: Theme.textDim
        font.pixelSize: 13
        font.family: Theme.fontFamily
    }

    GridView {
        id: grid
        anchors.top: search.bottom
        anchors.topMargin: 12
        anchors.bottom: footer.top
        anchors.bottomMargin: 8
        width: parent.width
        clip: true
        cellWidth: width / root.columns
        cellHeight: Math.round(cellWidth * 0.5625) + 34
        model: root.results
        boundsBehavior: Flickable.StopAtBounds
        cacheBuffer: cellHeight * 3
        currentIndex: root.selected

        delegate: Item {
            id: cell

            required property var modelData
            required property int index
            readonly property bool isSelected: index === root.selected
            readonly property bool isCurrent: LoginVideo.current === modelData.path
            readonly property bool isApplying: LoginVideo.applying === modelData.path

            width: grid.cellWidth
            height: grid.cellHeight

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: 14
                color: cell.isSelected ? Theme.tileHover : Theme.tile
                scale: cellMouse.pressed ? 0.97 : 1
                border.width: 2
                border.color: cell.isSelected ? Theme.text
                    : cell.isCurrent ? Theme.accent
                    : "transparent"
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
                    color: Theme.control
                    clip: true

                    Image {
                        id: poster
                        anchors.fill: parent
                        visible: cell.modelData.hasThumb
                        source: cell.modelData.hasThumb
                            ? "file://" + cell.modelData.thumb + "?v=" + LoginVideo.thumbsVersion
                            : ""
                        sourceSize.width: 420
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }

                    // While the poster frame is still being made, or the swap is running
                    Spinner {
                        anchors.centerIn: parent
                        width: 18
                        height: 18
                        visible: !poster.visible || cell.isApplying
                    }

                    // The one the login screen is playing now
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 6
                        width: currentLabel.implicitWidth + 14
                        height: 20
                        radius: 10
                        color: Theme.accent
                        visible: cell.isCurrent

                        Text {
                            id: currentLabel
                            anchors.centerIn: parent
                            text: "on the login screen"
                            color: Theme.accentText
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.family: Theme.fontFamily
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    anchors.top: preview.bottom
                    anchors.topMargin: 6
                    elide: Text.ElideRight
                    text: cell.modelData.name
                    color: Theme.text
                    font.pixelSize: 12
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selected = cell.index;
                        root.choose(cell.modelData);
                    }
                }
            }
        }
    }

    Item {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        height: LoginVideo.message ? 42 : 22

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            text: "↵ use for the login screen   ←↑↓→ navigate   Esc close"
            color: Theme.textDim
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }

        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            anchors.top: parent.top
            visible: LoginVideo.message !== ""
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideMiddle
            text: LoginVideo.message
            color: LoginVideo.messageIsError ? Theme.danger : Theme.textDim
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }
}
