import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: root

    required property ShellScreen targetScreen

    property string path: ""
    property bool open: false
    readonly property int cardWidth: 260
    readonly property int margin: 20

    function show(p) {
        path = p;
        open = true;
        dismissTimer.restart();
    }

    function dismiss() {
        open = false;
    }

    screen: targetScreen
    visible: open || slideOut.running
    color: "transparent"
    anchors.bottom: true
    anchors.left: true
    implicitWidth: cardWidth + margin * 2
    implicitHeight: card.height + margin * 2
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "screenshot-preview"

    Connections {
        target: Screenshot
        function onCaptured(p) {
            if (Screenshot.screenName === root.targetScreen.name)
                root.show(p);
        }
    }

    Timer {
        id: dismissTimer
        interval: 6000
        onTriggered: {
            if (hover.hovered || dragArea.drag.active)
                restart();
            else
                root.dismiss();
        }
    }

    Process {
        id: openProc
    }

    Process {
        id: deleteProc
    }

    Rectangle {
        id: card

        readonly property real aspect: thumb.implicitHeight > 0 ? thumb.implicitWidth / thumb.implicitHeight : 16 / 9

        width: root.cardWidth
        height: Math.round(Math.min(root.cardWidth * 0.75, Math.max(90, root.cardWidth / aspect)))
        y: root.margin
        x: root.open ? root.margin : -width - root.margin
        radius: 14
        color: Theme.islandBg
        border.color: hover.hovered ? Qt.alpha(Theme.textPrimary, 0.35) : Theme.islandBorder
        border.width: 1
        opacity: root.open ? 1 : 0
        scale: dragArea.pressed ? 0.97 : 1

        Behavior on x {
            NumberAnimation {
                id: slideOut
                duration: 380
                easing.type: root.open ? Easing.OutBack : Easing.InCubic
                easing.overshoot: 1.1
            }
        }
        Behavior on opacity { NumberAnimation { duration: 300 } }
        Behavior on scale { NumberAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        HoverHandler { id: hover }

        Rectangle {
            id: frame
            anchors.fill: parent
            anchors.margins: 4
            radius: 10
            color: Theme.tileBg
            clip: true

            Image {
                id: thumb
                anchors.fill: parent
                source: root.path ? "file://" + root.path : ""
                fillMode: Image.PreserveAspectFit
                sourceSize.width: root.cardWidth * 2
                asynchronous: true
                cache: false
                smooth: true
                mipmap: true
            }
        }

        Item {
            id: dragProxy
            width: card.width
            height: card.height

            Drag.active: dragArea.drag.active
            Drag.dragType: Drag.Automatic
            Drag.supportedActions: Qt.CopyAction
            Drag.mimeData: ({
                "text/uri-list": encodeURI("file://" + root.path) + "\r\n"
            })
            Drag.imageSource: root.path ? "file://" + root.path : ""
            Drag.imageSourceSize: Qt.size(card.width * 0.8, card.height * 0.8)
            Drag.hotSpot.x: card.width * 0.4
            Drag.hotSpot.y: card.height * 0.4

            Drag.onDragFinished: action => {
                dragProxy.x = 0;
                dragProxy.y = 0;
                if (action !== Qt.IgnoreAction)
                    root.dismiss();
                else
                    dismissTimer.restart();
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            drag.target: dragProxy
            drag.threshold: 6

            onClicked: {
                openProc.command = ["xdg-open", root.path];
                openProc.running = true;
                root.dismiss();
            }
            onReleased: {
                dragProxy.x = 0;
                dragProxy.y = 0;
            }
        }

        component CornerButton: Rectangle {
            id: cb
            signal clicked()
            property alias iconItem: iconSlot.data
            width: 26
            height: 26
            radius: 13
            color: cbMouse.containsMouse ? Theme.controlHover : Qt.alpha(Theme.tileBg, 0.9)
            border.color: Qt.alpha(Theme.textPrimary, 0.2)
            border.width: 1
            opacity: hover.hovered ? 1 : 0
            scale: hover.hovered ? 1 : 0.6
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
            Behavior on color { ColorAnimation { duration: 100 } }

            Item {
                id: iconSlot
                anchors.centerIn: parent
                width: 12
                height: 12
            }

            MouseArea {
                id: cbMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: cb.clicked()
            }
        }

        CornerButton {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            onClicked: root.dismiss()

            iconItem: Canvas {
                anchors.fill: parent
                property color tint: Theme.textPrimary
                onTintChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = tint;
                    ctx.lineWidth = 1.8;
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.moveTo(2.5, 2.5); ctx.lineTo(9.5, 9.5);
                    ctx.moveTo(9.5, 2.5); ctx.lineTo(2.5, 9.5);
                    ctx.stroke();
                }
            }
        }

        CornerButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            onClicked: {
                deleteProc.command = ["gio", "trash", root.path];
                deleteProc.running = true;
                root.dismiss();
            }

            iconItem: Canvas {
                anchors.fill: parent
                property color tint: Theme.danger
                onTintChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = tint;
                    ctx.lineWidth = 1.5;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.beginPath();
                    ctx.moveTo(1, 3); ctx.lineTo(11, 3);
                    ctx.moveTo(4.5, 3); ctx.lineTo(4.5, 1.2); ctx.lineTo(7.5, 1.2); ctx.lineTo(7.5, 3);
                    ctx.moveTo(2.5, 3); ctx.lineTo(3.2, 11); ctx.lineTo(8.8, 11); ctx.lineTo(9.5, 3);
                    ctx.stroke();
                }
            }
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            width: tipText.implicitWidth + 18
            height: 22
            radius: 11
            color: Qt.alpha(Theme.tileBg, 0.9)
            border.color: Qt.alpha(Theme.textPrimary, 0.2)
            opacity: hover.hovered && !dragArea.drag.active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Text {
                id: tipText
                anchors.centerIn: parent
                text: "Click to open  ·  Drag to share"
                color: Theme.textSecondary
                font.pixelSize: 10
                font.family: Theme.fontFamily
            }
        }
    }
}
