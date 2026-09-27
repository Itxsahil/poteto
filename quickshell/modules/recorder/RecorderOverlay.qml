import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config
import qs.services

PanelWindow {
    id: root

    required property ShellScreen targetScreen
    readonly property bool shown: Recorder.selecting && Recorder.screenName === targetScreen.name
    readonly property bool region: Recorder.mode === "region"

    property real startX: 0
    property real startY: 0
    property real selX: 0
    property real selY: 0
    property real selW: 0
    property real selH: 0
    property bool dragging: false
    readonly property bool hasRect: !region || (selW > 0 && selH > 0)
    readonly property real rx: region ? selX : 0
    readonly property real ry: region ? selY : 0
    readonly property real rw: region ? selW : width
    readonly property real rh: region ? selH : height

    function resetSelection() {
        selX = selY = selW = selH = 0;
        dragging = false;
    }

    function record() {
        if (!region)
            Recorder.startScreen();
        else if (selW >= 16 && selH >= 16)
            Recorder.startRegion(selX, selY, Math.floor(selW / 2) * 2, Math.floor(selH / 2) * 2);
    }

    screen: targetScreen
    visible: shown
    color: "transparent"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "recorder"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onShownChanged: {
        resetSelection();
        if (shown)
            keys.forceActiveFocus();
    }

    Item {
        id: dim
        anchors.fill: parent
        readonly property color shade: Qt.alpha(Theme.islandBg, root.region ? 0.55 : 0.25)

        Rectangle { x: 0; y: 0; width: parent.width; height: root.hasRect ? root.ry : parent.height; color: dim.shade }
        Rectangle { x: 0; y: root.ry + root.rh; width: parent.width; height: root.hasRect ? parent.height - y : 0; color: dim.shade }
        Rectangle { x: 0; y: root.ry; width: root.hasRect ? root.rx : 0; height: root.hasRect ? root.rh : 0; color: dim.shade }
        Rectangle { x: root.rx + root.rw; y: root.ry; width: root.hasRect ? parent.width - x : 0; height: root.hasRect ? root.rh : 0; color: dim.shade }
    }

    Rectangle {
        visible: root.hasRect
        x: root.rx
        y: root.ry
        width: root.rw
        height: root.rh
        color: "transparent"
        border.color: Theme.danger
        border.width: 2
        radius: root.region ? 2 : 0
    }

    Rectangle {
        visible: root.region && root.hasRect
        readonly property bool below: root.ry + root.rh + height + 12 < root.height
        x: Math.min(Math.max(8, root.rx + root.rw / 2 - width / 2), root.width - width - 8)
        y: below ? root.ry + root.rh + 10 : Math.max(8, root.ry - height - 10)
        width: sizeText.implicitWidth + 20
        height: 26
        radius: 13
        color: Theme.islandBg
        border.color: Theme.islandBorder

        Text {
            id: sizeText
            anchors.centerIn: parent
            text: `${Math.round(root.rw)} × ${Math.round(root.rh)}`
            color: Theme.textPrimary
            font.pixelSize: 12
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: root.region ? Qt.CrossCursor : Qt.PointingHandCursor

        onPressed: event => {
            if (event.button === Qt.RightButton) {
                Recorder.cancel();
                return;
            }
            if (!root.region)
                return;
            root.dragging = true;
            root.startX = event.x;
            root.startY = event.y;
            root.selX = event.x;
            root.selY = event.y;
            root.selW = 0;
            root.selH = 0;
        }
        onPositionChanged: event => {
            if (!root.dragging)
                return;
            root.selX = Math.min(root.startX, event.x);
            root.selY = Math.min(root.startY, event.y);
            root.selW = Math.abs(event.x - root.startX);
            root.selH = Math.abs(event.y - root.startY);
        }
        onReleased: event => {
            if (event.button !== Qt.LeftButton)
                return;
            if (!root.region) {
                root.record();
                return;
            }
            root.dragging = false;
            if (root.selW < 16 || root.selH < 16)
                root.resetSelection();
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Escape: Recorder.cancel(); break;
            case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space: root.record(); break;
            case Qt.Key_S: case Qt.Key_1: Recorder.setMode("screen"); root.resetSelection(); break;
            case Qt.Key_R: case Qt.Key_2: Recorder.setMode("region"); root.resetSelection(); break;
            case Qt.Key_A: Recorder.setSystemAudio(!Recorder.systemAudio); break;
            case Qt.Key_M: Recorder.setMic(!Recorder.mic); break;
            default: return;
            }
            event.accepted = true;
        }
    }

    component BarButton: Rectangle {
        id: btn
        property string glyph
        property string label
        property bool selected: false
        property bool accentWhenSelected: false
        signal clicked()

        width: btnRow.implicitWidth + 24
        height: 32
        radius: 16
        color: selected ? (accentWhenSelected ? Theme.accent : Theme.wsActiveBg)
            : btnMouse.containsMouse ? Theme.controlBg : "transparent"
        Behavior on color { ColorAnimation { duration: 150 } }

        readonly property color contentColor: selected ? (accentWhenSelected ? Theme.onAccent : Theme.wsActiveText) : Theme.textPrimary

        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 7

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.glyph
                color: btn.contentColor
                font.pixelSize: 15
                font.family: "JetBrainsMono Nerd Font"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: btn.label
                color: btn.contentColor
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
            onClicked: btn.clicked()
        }
    }

    component Divider: Rectangle {
        width: 1
        height: 20
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.controlBg
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
        opacity: root.dragging ? 0.25 : 1
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Row {
            id: toolRow
            anchors.centerIn: parent
            spacing: 4

            BarButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "󰍹"
                label: "Screen"
                selected: !root.region
                onClicked: { Recorder.setMode("screen"); root.resetSelection(); }
            }

            BarButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "󰩭"
                label: "Region"
                selected: root.region
                onClicked: { Recorder.setMode("region"); root.resetSelection(); }
            }

            Divider {}

            BarButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: Recorder.systemAudio ? "󰕾" : "󰖁"
                label: "System"
                selected: Recorder.systemAudio
                accentWhenSelected: true
                onClicked: Recorder.setSystemAudio(!Recorder.systemAudio)
            }

            BarButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: Recorder.mic ? "󰍬" : "󰍭"
                label: "Mic"
                selected: Recorder.mic
                accentWhenSelected: true
                onClicked: Recorder.setMic(!Recorder.mic)
            }

            Divider {}

            Rectangle {
                id: recordBtn
                readonly property bool enabledNow: !root.region || (root.selW >= 16 && root.selH >= 16)
                anchors.verticalCenter: parent.verticalCenter
                width: recRow.implicitWidth + 26
                height: 32
                radius: 16
                color: recMouse.containsMouse && enabledNow ? Qt.lighter(Theme.danger, 1.1) : Theme.danger
                opacity: enabledNow ? 1 : 0.4

                Row {
                    id: recRow
                    anchors.centerIn: parent
                    spacing: 7

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: 10
                        radius: 5
                        color: Theme.islandBg
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Record"
                        color: Theme.islandBg
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        font.family: Theme.fontFamily
                    }
                }

                MouseArea {
                    id: recMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: recordBtn.enabledNow ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.record()
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: 16
                anchors.verticalCenter: parent.verticalCenter
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
                    onClicked: Recorder.cancel()
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
            text: (root.region ? "Drag a region, then Record or ↵" : "Click or ↵ to record the whole screen")
                + "  ·  A system audio  ·  M mic  ·  Esc cancel  ·  Super+Shift+R stops"
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }
}
