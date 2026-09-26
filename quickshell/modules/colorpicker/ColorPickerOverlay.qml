import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

PanelWindow {
    id: root

    required property ShellScreen targetScreen
    readonly property bool shown: ColorPicker.active && ColorPicker.screenName === targetScreen.name

    readonly property int zoom: 12
    readonly property int radius: 5
    readonly property int loupeSize: (radius * 2 + 1) * zoom

    property real pointX: 0
    property real pointY: 0
    property bool ready: false
    property string hex: "#000000"

    function clampPoint() {
        pointX = Math.max(0, Math.min(ColorPicker.pixelWidth - 1, Math.round(pointX)));
        pointY = Math.max(0, Math.min(ColorPicker.pixelHeight - 1, Math.round(pointY)));
        sample();
    }

    function sample() {
        if (!ready)
            return;
        const d = frozen.context.getImageData(pointX, pointY, 1, 1).data;
        hex = ColorPicker.toHex(d[0], d[1], d[2]);
    }

    function pickCurrent() {
        if (!ready)
            return;
        const [r, g, b] = ColorPicker.fromHex(hex);
        ColorPicker.pick(r, g, b);
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
    WlrLayershell.namespace: "colorpicker"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onShownChanged: {
        ready = false;
        if (shown) {
            pointX = ColorPicker.startX;
            pointY = ColorPicker.startY;
            frozen.source = "file://" + ColorPicker.frozenPath;
            frozen.loadImage(frozen.source);
            keys.forceActiveFocus();
        } else if (frozen.source) {
            frozen.unloadImage(frozen.source);
            frozen.source = "";
        }
    }

    Canvas {
        id: frozen

        property string source: ""

        width: ColorPicker.pixelWidth
        height: ColorPicker.pixelHeight
        scale: 1 / ColorPicker.screenScale
        transformOrigin: Item.TopLeft
        renderStrategy: Canvas.Immediate

        onImageLoaded: requestPaint()
        onPaint: {
            if (!source || !isImageLoaded(source))
                return;
            const ctx = getContext("2d");
            ctx.drawImage(source, 0, 0, width, height);
            root.ready = true;
            root.sample();
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.CrossCursor

        onPositionChanged: event => {
            root.pointX = event.x * ColorPicker.screenScale;
            root.pointY = event.y * ColorPicker.screenScale;
            root.clampPoint();
        }
        onPressed: event => {
            if (event.button === Qt.RightButton)
                ColorPicker.cancel();
            else
                root.pickCurrent();
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const step = (event.modifiers & Qt.ShiftModifier) ? 10 : 1;
            switch (event.key) {
            case Qt.Key_Escape: ColorPicker.cancel(); break;
            case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: root.pickCurrent(); break;
            case Qt.Key_Tab: ColorPicker.cycleFormat(1); break;
            case Qt.Key_Backtab: ColorPicker.cycleFormat(-1); break;
            case Qt.Key_Left: case Qt.Key_H: root.pointX -= step; root.clampPoint(); break;
            case Qt.Key_Right: case Qt.Key_L: root.pointX += step; root.clampPoint(); break;
            case Qt.Key_Up: case Qt.Key_K: root.pointY -= step; root.clampPoint(); break;
            case Qt.Key_Down: case Qt.Key_J: root.pointY += step; root.clampPoint(); break;
            default: return;
            }
            event.accepted = true;
        }
    }

    Item {
        id: loupe

        readonly property real logicalX: root.pointX / ColorPicker.screenScale
        readonly property real logicalY: root.pointY / ColorPicker.screenScale
        readonly property bool flipX: logicalX + 24 + width > root.width
        readonly property bool flipY: logicalY + 24 + height > root.height

        visible: root.ready
        width: root.loupeSize + 8
        height: width + info.height + 8
        x: flipX ? logicalX - 24 - width : logicalX + 24
        y: flipY ? logicalY - 24 - height : logicalY + 24

        Rectangle {
            id: frame
            width: parent.width
            height: width
            radius: 18
            color: Theme.islandBg
            border.color: Theme.islandBorder
            border.width: 1

            Item {
                anchors.centerIn: parent
                width: root.loupeSize
                height: root.loupeSize
                clip: true

                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: frozen
                    sourceRect: Qt.rect(root.pointX - root.radius, root.pointY - root.radius, root.radius * 2 + 1, root.radius * 2 + 1)
                    smooth: false
                    live: true
                    hideSource: false
                }

                Canvas {
                    anchors.fill: parent
                    property color tint: Qt.alpha(Theme.textPrimary, 0.12)
                    onTintChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.strokeStyle = tint;
                        ctx.lineWidth = 1;
                        for (let i = 1; i < root.radius * 2 + 1; i++) {
                            const p = i * root.zoom + 0.5;
                            ctx.beginPath();
                            ctx.moveTo(p, 0); ctx.lineTo(p, height);
                            ctx.moveTo(0, p); ctx.lineTo(width, p);
                            ctx.stroke();
                        }
                    }
                }

                Rectangle {
                    x: root.radius * root.zoom - 1
                    y: root.radius * root.zoom - 1
                    width: root.zoom + 2
                    height: root.zoom + 2
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.textPrimary
                }
            }
        }

        Rectangle {
            id: info
            anchors.top: frame.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: frame.horizontalCenter
            width: infoRow.implicitWidth + 20
            height: 34
            radius: 17
            color: Theme.islandBg
            border.color: Theme.islandBorder

            Row {
                id: infoRow
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: 9
                    color: root.hex
                    border.width: 1
                    border.color: Qt.alpha(Theme.textPrimary, 0.3)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ColorPicker.formatColor(root.hex, ColorPicker.format)
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.family: "JetBrainsMono Nerd Font"
                }
            }
        }
    }

    Shadow {
        target: toolbar
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

        Row {
            id: toolRow
            anchors.centerIn: parent
            spacing: 4

            Repeater {
                model: ColorPicker.formats

                Rectangle {
                    id: fmt
                    required property string modelData
                    readonly property bool selected: ColorPicker.format === modelData

                    width: 52
                    height: 32
                    radius: 16
                    color: selected ? Theme.wsActiveBg : fmtMouse.containsMouse ? Theme.controlBg : "transparent"
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: fmt.modelData.toUpperCase()
                        color: fmt.selected ? Theme.wsActiveText : Theme.textPrimary
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        font.family: Theme.fontFamily
                    }

                    MouseArea {
                        id: fmtMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ColorPicker.format = fmt.modelData;
                            ColorPicker.save();
                        }
                    }
                }
            }

            Rectangle {
                width: 1
                height: 20
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.controlBg
                visible: ColorPicker.history.length > 0
            }

            Repeater {
                model: ColorPicker.history.slice(0, 10)

                Rectangle {
                    id: swatch
                    required property string modelData
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 26
                    radius: 13
                    color: modelData
                    border.width: swatchMouse.containsMouse ? 2 : 1
                    border.color: swatchMouse.containsMouse ? Theme.textPrimary : Qt.alpha(Theme.textPrimary, 0.25)
                    scale: swatchMouse.pressed ? 0.9 : 1

                    MouseArea {
                        id: swatchMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ColorPicker.cancel();
                            ColorPicker.copy(swatch.modelData);
                        }
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
                    onClicked: ColorPicker.cancel()
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
        opacity: 0.9

        Text {
            id: hint
            anchors.centerIn: parent
            text: "Click or ↵ to copy  ·  arrows nudge (⇧ ×10)  ·  Tab format  ·  Esc cancel"
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }
}
