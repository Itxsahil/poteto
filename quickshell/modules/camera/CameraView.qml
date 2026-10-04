import QtQuick
import QtMultimedia
import qs.config
import qs.components
import qs.services

// Webcam in the island: a live preview, a shutter, a self-timer and a mirror toggle.
//
// The QtMultimedia Camera lives here rather than in the Webcam service so that it is bound to this
// view's lifetime: it powers on when the view opens and off when it closes, which is also what
// turns the webcam's light off. Nothing keeps the camera open in the background.
Item {
    id: root

    property bool active: false
    // Counts down while the self-timer runs; 0 means idle
    property int counting: 0
    property bool capturing: false

    signal closeRequested()

    implicitWidth: 640
    implicitHeight: header.height + 12 + preview.height + 12 + controls.height + 10 + footer.height

    onActiveChanged: {
        if (active) {
            Webcam.ensureDir();
            keys.forceActiveFocus();
        } else {
            cancelTimer();
        }
    }

    function cancelTimer() {
        countdown.stop();
        counting = 0;
    }

    // Space with a timer set starts the countdown; pressing it again cancels
    function shutter() {
        if (!Webcam.available || capturing)
            return;
        if (counting > 0) {
            cancelTimer();
            return;
        }
        if (Webcam.timer > 0) {
            counting = Webcam.timer;
            countdown.restart();
            return;
        }
        capture();
    }

    function capture() {
        if (!pipeline.item)
            return;
        capturing = true;
        flash.fire();
        pipeline.item.imageCapture.captureToFile(Webcam.nextPath());
    }

    Timer {
        id: countdown
        interval: 1000
        repeat: true
        onTriggered: {
            root.counting--;
            if (root.counting <= 0) {
                stop();
                root.capture();
            }
        }
    }

    // Built only while the view is open and torn down with it. Setting Camera.active to false is
    // not enough: the backend keeps /dev/video* open, and with it the webcam's light. Destroying
    // the session closes the device.
    Loader {
        id: pipeline

        active: root.active && Webcam.available

        // A capture in flight when this goes away — the view closed, or the camera was unplugged —
        // never reaches onImageSaved, so nothing would clear `capturing` and the shutter would
        // stay refusing presses for good. No pipeline means nothing can be in flight.
        onItemChanged: {
            if (!item) {
                root.capturing = false;
                root.cancelTimer();
            }
        }

        sourceComponent: CaptureSession {
            videoOutput: output

            camera: Camera {
                active: true
                cameraDevice: Webcam.device
                onErrorOccurred: (error, errorString) => console.warn("Camera:", error, errorString)
            }

            imageCapture: ImageCapture {
                onImageSaved: (id, path) => {
                    root.capturing = false;
                    Webcam.saved(path);
                }
                onErrorOccurred: (id, error, message) => {
                    root.capturing = false;
                    console.warn("Camera capture:", error, message);
                }
            }
        }
    }

    Item {
        id: keys
        focus: root.active
        Keys.onEscapePressed: root.closeRequested()
        Keys.onSpacePressed: root.shutter()
        Keys.onReturnPressed: root.shutter()
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_M:
                Webcam.mirror = !Webcam.mirror;
                break;
            case Qt.Key_T:
                Webcam.cycleTimer();
                break;
            case Qt.Key_C:
                Webcam.nextDevice();
                break;
            case Qt.Key_O:
                Webcam.openFolder();
                break;
            default:
                return;
            }
            event.accepted = true;
        }
    }

    Item {
        id: header
        width: parent.width
        height: 32

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: "Camera"
            color: Theme.textPrimary
            font.pixelSize: 15
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: Webcam.deviceName
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.width - 120)
            horizontalAlignment: Text.AlignRight
        }
    }

    Rectangle {
        id: preview
        anchors.top: header.bottom
        anchors.topMargin: 12
        width: parent.width
        height: Math.round(width * 9 / 16)
        radius: 16
        color: "black"
        clip: true

        VideoOutput {
            id: output
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            // Mirror horizontally about the centre, so the preview reads like a mirror
            transform: Scale {
                origin.x: preview.width / 2
                xScale: Webcam.mirror ? -1 : 1
            }
        }

        Text {
            anchors.centerIn: parent
            visible: !Webcam.available
            text: "No camera found"
            color: Theme.textSecondary
            font.pixelSize: 13
            font.family: Theme.fontFamily
        }

        // Self-timer count, drawn over the preview
        Rectangle {
            anchors.centerIn: parent
            visible: root.counting > 0
            width: 96
            height: 96
            radius: 48
            color: Qt.alpha(Theme.islandBg, 0.55)

            Text {
                anchors.centerIn: parent
                text: root.counting
                color: Theme.textPrimary
                font.pixelSize: 44
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily
            }
        }

        // Shutter flash
        Rectangle {
            id: flash

            function fire() {
                opacity = 0.85;
                fade.restart();
            }

            anchors.fill: parent
            color: "white"
            opacity: 0
            NumberAnimation on opacity {
                id: fade
                to: 0
                duration: 420
                running: false
            }
        }
    }

    Item {
        id: controls
        anchors.top: preview.bottom
        anchors.topMargin: 12
        width: parent.width
        height: 64

        // Last photo, click to open it
        Rectangle {
            id: thumb
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 56
            height: 44
            radius: 10
            color: Theme.tileBg
            clip: true
            visible: Webcam.lastShot !== ""

            Image {
                anchors.fill: parent
                // shotCount busts the cache when a new photo lands on the same-second path
                source: Webcam.lastShot ? `file://${Webcam.lastShot}?v=${Webcam.shotCount}` : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Webcam.openLastShot()
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 14

            CircleButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "⇄"
                glyphSize: 17
                active: Webcam.mirror
                onClicked: Webcam.mirror = !Webcam.mirror
            }

            // Shutter
            Rectangle {
                id: shutterButton
                anchors.verticalCenter: parent.verticalCenter
                width: 58
                height: 58
                radius: 29
                color: shutterMouse.containsMouse ? Qt.lighter(Theme.accent, 1.12) : Theme.accent
                opacity: Webcam.available ? 1 : 0.4
                scale: shutterMouse.pressed ? 0.93 : 1
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 90 } }

                Rectangle {
                    anchors.centerIn: parent
                    width: 44
                    height: 44
                    radius: 22
                    color: "transparent"
                    border.color: Theme.onAccent
                    border.width: 2
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.counting > 0
                    text: root.counting
                    color: Theme.onAccent
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: shutterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shutter()
                }
            }

            CircleButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: Webcam.timer === 0 ? "󰔛" : Webcam.timer + "s"
                glyphSize: Webcam.timer === 0 ? 16 : 13
                active: Webcam.timer > 0
                onClicked: Webcam.cycleTimer()
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            CircleButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: Webcam.devices.length > 1
                glyph: "󰑙"
                glyphSize: 16
                onClicked: Webcam.nextDevice()
            }

            CircleButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "󰉋"
                glyphSize: 16
                onClicked: Webcam.openFolder()
            }
        }
    }

    Item {
        id: footer
        anchors.top: controls.bottom
        anchors.topMargin: 10
        width: parent.width
        height: 20

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: "Space shoot   T timer   M mirror   " + (Webcam.devices.length > 1 ? "C camera   " : "") + "O folder   Esc close"
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            text: Webcam.lastShot ? "Saved " + Webcam.lastShot.split("/").pop() : ""
            color: Theme.textSecondary
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }
}
