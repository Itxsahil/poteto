import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: root

    required property ShellScreen targetScreen
    readonly property bool shown: Screenshot.active && Screenshot.screenName === targetScreen.name

    property real startX: 0
    property real startY: 0
    property real selX: 0
    property real selY: 0
    property real selW: 0
    property real selH: 0
    property bool dragging: false
    property var hoveredWindow: null

    readonly property bool hasRect: Screenshot.mode === "screen"
        || (Screenshot.mode === "window" && hoveredWindow !== null)
        || (Screenshot.mode === "region" && selW > 0 && selH > 0)
    readonly property real rx: Screenshot.mode === "screen" ? 0 : Screenshot.mode === "window" ? (hoveredWindow?.x ?? 0) : selX
    readonly property real ry: Screenshot.mode === "screen" ? 0 : Screenshot.mode === "window" ? (hoveredWindow?.y ?? 0) : selY
    readonly property real rw: Screenshot.mode === "screen" ? width : Screenshot.mode === "window" ? (hoveredWindow?.w ?? 0) : selW
    readonly property real rh: Screenshot.mode === "screen" ? height : Screenshot.mode === "window" ? (hoveredWindow?.h ?? 0) : selH

    function resetSelection() {
        selX = selY = selW = selH = 0;
        dragging = false;
        hoveredWindow = null;
    }

    function windowAt(x, y) {
        return Screenshot.windows.find(w => x >= w.x && x < w.x + w.w && y >= w.y && y < w.y + w.h) ?? null;
    }

    function setMode(m) {
        Screenshot.mode = m;
        resetSelection();
        if (m === "window")
            hoveredWindow = windowAt(mouse.mouseX, mouse.mouseY);
    }

    function captureCurrent() {
        if (!hasRect || rw < 2 || rh < 2)
            return;
        const x = Math.max(0, rx), y = Math.max(0, ry);
        const w = Math.min(width, rx + rw) - x, h = Math.min(height, ry + rh) - y;
        Screenshot.capture(x, y, w, h);
    }

    screen: targetScreen
    visible: shown
    color: "black"

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "screenshot"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onShownChanged: {
        resetSelection();
        if (shown)
            keyCatcher.forceActiveFocus();
    }

    Image {
        id: frozen
        anchors.fill: parent
        source: root.shown ? "file://" + Screenshot.frozenPath : ""
        cache: false
        smooth: true
        mipmap: false
    }

    Item {
        id: dim
        anchors.fill: parent
        readonly property color shade: Theme.screenshotShade

        Rectangle { x: 0; y: 0; width: parent.width; height: root.hasRect ? root.ry : parent.height; color: dim.shade }
        Rectangle { x: 0; y: root.ry + root.rh; width: parent.width; height: root.hasRect ? parent.height - y : 0; color: dim.shade }
        Rectangle { x: 0; y: root.ry; width: root.hasRect ? root.rx : 0; height: root.hasRect ? root.rh : 0; color: dim.shade }
        Rectangle { x: root.rx + root.rw; y: root.ry; width: root.hasRect ? parent.width - x : 0; height: root.hasRect ? root.rh : 0; color: dim.shade }
    }

    Rectangle {
        id: selection
        visible: root.hasRect && Screenshot.mode !== "screen"
        x: root.rx
        y: root.ry
        width: root.rw
        height: root.rh
        color: "transparent"
        border.color: Theme.screenshotBorder
        border.width: 2
        radius: Screenshot.mode === "window" ? 10 : 2

        Behavior on x { enabled: Screenshot.mode === "window"; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: Screenshot.mode === "window"; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on width { enabled: Screenshot.mode === "window"; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on height { enabled: Screenshot.mode === "window"; NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Repeater {
            model: Screenshot.mode === "region" ? [[0, 0], [1, 0], [0, 1], [1, 1]] : []

            Rectangle {
                required property var modelData
                width: 10
                height: 10
                radius: 5
                color: Theme.screenshotBorder
                x: modelData[0] * selection.width - width / 2
                y: modelData[1] * selection.height - height / 2
            }
        }
    }

    Rectangle {
        id: sizeLabel
        visible: root.hasRect && Screenshot.mode !== "screen"
        readonly property bool below: root.ry + root.rh + height + 12 < root.height
        x: Math.min(Math.max(8, root.rx + root.rw / 2 - width / 2), root.width - width - 8)
        y: below ? root.ry + root.rh + 10 : Math.max(8, root.ry - height - 10)
        width: labelText.implicitWidth + 20
        height: 26
        radius: 13
        color: Theme.islandBg
        border.color: Theme.islandBorder

        Text {
            id: labelText
            anchors.centerIn: parent
            text: {
                const size = `${Math.round(root.rw * Screenshot.screenScale)} × ${Math.round(root.rh * Screenshot.screenScale)}`;
                return Screenshot.mode === "window" && root.hoveredWindow ? `${root.hoveredWindow.appClass}  ·  ${size}` : size;
            }
            color: Theme.textPrimary
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Screenshot.mode === "region" ? Qt.CrossCursor : Qt.PointingHandCursor

        onPressed: event => {
            if (event.button === Qt.RightButton) {
                Screenshot.cancel();
                return;
            }
            if (Screenshot.mode === "region") {
                root.dragging = true;
                root.startX = event.x;
                root.startY = event.y;
                root.selX = event.x;
                root.selY = event.y;
                root.selW = 0;
                root.selH = 0;
            }
        }

        onPositionChanged: event => {
            if (Screenshot.mode === "window") {
                root.hoveredWindow = root.windowAt(event.x, event.y);
            } else if (root.dragging) {
                root.selX = Math.min(root.startX, event.x);
                root.selY = Math.min(root.startY, event.y);
                root.selW = Math.abs(event.x - root.startX);
                root.selH = Math.abs(event.y - root.startY);
            }
        }

        onReleased: event => {
            if (event.button !== Qt.LeftButton)
                return;
            if (Screenshot.mode === "region") {
                root.dragging = false;
                if (root.selW >= 4 && root.selH >= 4)
                    root.captureCurrent();
                else
                    root.resetSelection();
            } else {
                root.captureCurrent();
            }
        }
    }

    Item {
        id: keyCatcher
        focus: true
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape: Screenshot.cancel(); break;
            case Qt.Key_R: case Qt.Key_1: root.setMode("region"); break;
            case Qt.Key_W: case Qt.Key_2: root.setMode("window"); break;
            case Qt.Key_S: case Qt.Key_3: root.setMode("screen"); break;
            case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: root.captureCurrent(); break;
            default: return;
            }
            event.accepted = true;
        }
    }

    Rectangle {
        id: toolbar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 14
        width: toolRow.implicitWidth + 12
        height: 44
        radius: 22
        color: Theme.islandBg
        border.color: Theme.islandBorder
        opacity: root.dragging ? 0.25 : 1
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Row {
            id: toolRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: [
                    { mode: "region", label: "Region", key: "R" },
                    { mode: "window", label: "Window", key: "W" },
                    { mode: "screen", label: "Screen", key: "S" }
                ]

                Rectangle {
                    id: modeBtn
                    required property var modelData
                    readonly property bool selected: Screenshot.mode === modelData.mode

                    width: btnRow.implicitWidth + 26
                    height: 32
                    radius: 16
                    color: selected ? Theme.wsActiveBg : btnMouse.containsMouse ? Theme.controlBg : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: btnRow
                        anchors.centerIn: parent
                        spacing: 8

                        Canvas {
                            id: modeIcon
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            property color tint: modeBtn.selected ? Theme.wsActiveText : Theme.textPrimary
                            onTintChanged: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = tint;
                                ctx.fillStyle = tint;
                                ctx.lineWidth = 1.8;
                                ctx.lineCap = "round";
                                const m = modeBtn.modelData.mode;
                                if (m === "region") {
                                    ctx.beginPath();
                                    ctx.moveTo(1, 5); ctx.lineTo(1, 1); ctx.lineTo(5, 1);
                                    ctx.moveTo(11, 1); ctx.lineTo(15, 1); ctx.lineTo(15, 5);
                                    ctx.moveTo(15, 11); ctx.lineTo(15, 15); ctx.lineTo(11, 15);
                                    ctx.moveTo(5, 15); ctx.lineTo(1, 15); ctx.lineTo(1, 11);
                                    ctx.stroke();
                                } else if (m === "window") {
                                    ctx.beginPath();
                                    ctx.roundedRect(1, 2, 14, 12, 2.5, 2.5);
                                    ctx.stroke();
                                    ctx.beginPath();
                                    ctx.moveTo(1, 6); ctx.lineTo(15, 6);
                                    ctx.stroke();
                                } else {
                                    ctx.beginPath();
                                    ctx.roundedRect(1, 1.5, 14, 10, 2, 2);
                                    ctx.stroke();
                                    ctx.beginPath();
                                    ctx.moveTo(5, 15); ctx.lineTo(11, 15);
                                    ctx.moveTo(8, 11.5); ctx.lineTo(8, 15);
                                    ctx.stroke();
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modeBtn.modelData.label
                            color: modeBtn.selected ? Theme.wsActiveText : Theme.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            font.family: Theme.fontFamily
                        }
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.setMode(modeBtn.modelData.mode)
                    }
                }
            }

            Rectangle {
                width: 1
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.controlBg
            }

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: closeMouse.containsMouse ? Theme.controlBg : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Screenshot.cancel()
                }
            }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        width: hint.implicitWidth + 28
        height: 30
        radius: 15
        color: Theme.islandBg
        border.color: Theme.islandBorder
        opacity: root.dragging ? 0 : 0.9
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Text {
            id: hint
            anchors.centerIn: parent
            text: Screenshot.mode === "region" ? "Drag to select  ·  Esc to cancel"
                : Screenshot.mode === "window" ? "Click a window  ·  Esc to cancel"
                : "Click or press Enter to capture  ·  Esc to cancel"
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }
}
