import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.services

Item {
    id: root

    property bool active: false
    property string filter: "all"
    property int selected: 0
    property bool confirmWipe: false
    property string fullText: ""

    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        return Clipboard.entries.filter(e => {
            if (filter === "text" && e.isImage) return false;
            if (filter === "images" && !e.isImage) return false;
            if (!q) return true;
            return e.isImage ? "image".includes(q) || e.format.includes(q) : e.raw.toLowerCase().includes(q);
        });
    }
    readonly property var current: results[selected] ?? null

    signal closeRequested()

    implicitWidth: 740
    implicitHeight: 480

    function move(delta) {
        if (results.length === 0)
            return;
        selected = Math.max(0, Math.min(results.length - 1, selected + delta));
        list.positionViewAtIndex(selected, ListView.Contain);
    }

    function copyCurrent() {
        if (!current)
            return;
        Clipboard.copy(current);
        closeRequested();
    }

    function removeCurrent() {
        if (!current)
            return;
        const idx = selected;
        Clipboard.remove(current);
        selected = Math.min(idx, results.length - 1);
    }

    function cycleFilter() {
        const order = ["all", "text", "images"];
        filter = order[(order.indexOf(filter) + 1) % order.length];
    }

    onActiveChanged: {
        if (active) {
            input.text = "";
            filter = "all";
            selected = 0;
            confirmWipe = false;
            Clipboard.refresh();
            list.positionViewAtBeginning();
            input.forceActiveFocus();
        }
    }
    onResultsChanged: if (selected >= results.length) selected = Math.max(0, results.length - 1)
    onCurrentChanged: {
        fullText = "";
        if (current && !current.isImage)
            decodeDebounce.restart();
    }

    Timer {
        id: decodeDebounce
        interval: 60
        onTriggered: {
            if (!root.current || root.current.isImage)
                return;
            decodeProc.entryId = root.current.id;
            decodeProc.command = ["sh", "-c", 'printf "%s\\t%s\\n" "$1" "$2" | cliphist decode | head -c 20000', "sh", root.current.id, root.current.raw];
            decodeProc.running = true;
        }
    }

    Process {
        id: decodeProc
        property string entryId: ""
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.current && root.current.id === decodeProc.entryId)
                    root.fullText = text;
            }
        }
    }

    component Chip: Rectangle {
        id: chip
        property string label
        property string value
        readonly property bool selected: root.filter === value
        width: chipText.implicitWidth + 22
        height: 28
        radius: 14
        color: selected ? Theme.wsActiveBg : chipMouse.containsMouse ? Theme.controlBg : Theme.tileBg
        Behavior on color { ColorAnimation { duration: 140 } }

        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            color: chip.selected ? Theme.wsActiveText : Theme.textPrimary
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.filter = chip.value;
                root.selected = 0;
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
            anchors.right: chips.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textPrimary
            selectionColor: Theme.accent
            font.pixelSize: 16
            font.family: Theme.fontFamily
            clip: true

            onTextChanged: {
                root.selected = 0;
                list.positionViewAtBeginning();
            }

            Keys.onPressed: event => {
                const ctrl = event.modifiers & Qt.ControlModifier;
                if (event.key === Qt.Key_Escape) {
                    root.closeRequested();
                } else if (event.key === Qt.Key_Down || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))) {
                    root.move(1);
                } else if (event.key === Qt.Key_Up || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))) {
                    root.move(-1);
                } else if (event.key === Qt.Key_PageDown) {
                    root.move(8);
                } else if (event.key === Qt.Key_PageUp) {
                    root.move(-8);
                } else if (event.key === Qt.Key_Tab) {
                    root.cycleFilter();
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.copyCurrent();
                } else if (event.key === Qt.Key_Delete || (event.key === Qt.Key_Backspace && input.text === "" && ctrl)) {
                    root.removeCurrent();
                } else {
                    return;
                }
                event.accepted = true;
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !input.text
                text: "Search clipboard"
                color: Theme.textSecondary
                font: input.font
            }
        }

        Row {
            id: chips
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Chip { label: "All"; value: "all" }
            Chip { label: "Text"; value: "text" }
            Chip { label: "Images"; value: "images" }
        }
    }

    Item {
        id: body
        anchors.top: search.bottom
        anchors.topMargin: 10
        anchors.bottom: footer.top
        anchors.bottomMargin: 10
        width: parent.width

        Column {
            anchors.centerIn: parent
            spacing: 6
            visible: root.results.length === 0

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Clipboard.loading ? "Loading…" : input.text ? "Nothing matches" : "Clipboard is empty"
                color: Theme.textPrimary
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !Clipboard.loading
                text: input.text ? "Try a different search" : "Copied text and images show up here"
                color: Theme.textSecondary
                font.pixelSize: 12
                font.family: Theme.fontFamily
            }
        }

        ListView {
            id: list
            width: 320
            height: parent.height
            clip: true
            spacing: 4
            visible: root.results.length > 0
            model: root.results
            boundsBehavior: Flickable.StopAtBounds
            cacheBuffer: 400
            reuseItems: true

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index
                readonly property bool isSelected: index === root.selected
                readonly property string thumb: Clipboard.thumbs[modelData.id] ?? ""

                Component.onCompleted: Clipboard.requestThumb(modelData)
                onModelDataChanged: Clipboard.requestThumb(modelData)

                width: ListView.view.width
                height: modelData.isImage ? 64 : 44
                radius: 12
                color: isSelected ? Theme.tileHover : rowMouse.containsMouse ? "#121214" : "transparent"
                Behavior on color { ColorAnimation { duration: 90 } }

                Rectangle {
                    width: 3
                    height: parent.height - 20
                    radius: 1.5
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.accent
                    opacity: row.isSelected ? 1 : 0
                }

                Rectangle {
                    id: thumbBox
                    visible: row.modelData.isImage
                    width: 72
                    height: 48
                    radius: 8
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.controlBg
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: row.thumb ? "file://" + row.thumb : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 144
                        asynchronous: true
                    }
                }

                Column {
                    anchors.left: row.modelData.isImage ? thumbBox.right : parent.left
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        text: row.modelData.isImage ? `${row.modelData.imgW} × ${row.modelData.imgH}` : row.modelData.preview.replace(/\s+/g, " ").trim()
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.weight: row.isSelected ? Font.DemiBold : Font.Normal
                        font.family: Theme.fontFamily
                    }

                    Text {
                        visible: row.modelData.isImage
                        text: `${row.modelData.format?.toUpperCase()} · ${row.modelData.size}`
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selected = row.index
                    onClicked: root.copyCurrent()
                }
            }
        }

        Rectangle {
            id: preview
            anchors.left: list.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            height: parent.height
            radius: 18
            color: Theme.tileBg
            clip: true
            visible: root.current !== null

            Item {
                anchors.fill: parent
                anchors.margins: 12
                visible: root.current?.isImage ?? false

                Image {
                    id: bigImage
                    anchors.fill: parent
                    anchors.bottomMargin: 26
                    source: root.current?.isImage && Clipboard.thumbs[root.current.id] ? "file://" + Clipboard.thumbs[root.current.id] : ""
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 800
                    asynchronous: true
                    smooth: true
                    mipmap: true
                }

                Text {
                    anchors.centerIn: bigImage
                    visible: bigImage.status !== Image.Ready
                    text: "Loading image…"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                    font.family: Theme.fontFamily
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.current?.isImage ? `${root.current.imgW} × ${root.current.imgH}  ·  ${root.current.format.toUpperCase()}  ·  ${root.current.size}` : ""
                    color: Theme.textSecondary
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }
            }

            Flickable {
                id: textFlick
                anchors.fill: parent
                anchors.margins: 16
                visible: !(root.current?.isImage ?? true)
                contentWidth: width
                contentHeight: previewText.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Text {
                    id: previewText
                    width: textFlick.width
                    text: root.fullText || root.current?.raw || ""
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    textFormat: Text.PlainText
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    font.family: "JetBrains Mono, monospace"
                    lineHeight: 1.15
                }
            }
        }
    }

    Item {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        height: 28

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: "↵ copy   ↑↓ navigate   Tab filter   Del remove   Esc close"
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: wipeText.implicitWidth + 22
            height: 26
            radius: 13
            color: root.confirmWipe ? Theme.danger : wipeMouse.containsMouse ? Theme.controlBg : "transparent"
            visible: Clipboard.entries.length > 0
            Behavior on color { ColorAnimation { duration: 140 } }

            Text {
                id: wipeText
                anchors.centerIn: parent
                text: root.confirmWipe ? "Click again to clear all" : "Clear all"
                color: root.confirmWipe ? Theme.textPrimary : Theme.danger
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }

            MouseArea {
                id: wipeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.confirmWipe) {
                        Clipboard.wipe();
                        root.confirmWipe = false;
                    } else {
                        root.confirmWipe = true;
                        wipeReset.restart();
                    }
                    input.forceActiveFocus();
                }
            }

            Timer {
                id: wipeReset
                interval: 3000
                onTriggered: root.confirmWipe = false
            }
        }
    }
}
