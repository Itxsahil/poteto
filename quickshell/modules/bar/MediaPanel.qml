import QtQuick
import qs.config
import qs.services

// The media controls that the status pill grows into on hover: album art, the track,
// a seek bar, transport buttons and volume.
Item {
    id: root

    implicitWidth: 380
    implicitHeight: 196

    function timeText(seconds) {
        if (!(seconds > 0))
            return "0:00";
        const s = Math.round(seconds);
        const m = Math.floor(s / 60);
        return `${m}:${String(s % 60).padStart(2, "0")}`;
    }

    // Transport / toggle button: a glyph drawn on demand
    component IconButton: Item {
        id: button

        property string kind: "play"
        property bool active: false
        property real scale_: 1
        signal activated()

        width: 30 * scale_
        height: 30 * scale_

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: button.kind === "play" ? Theme.accent
                : mouse.containsMouse ? Theme.controlBg
                : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Canvas {
            anchors.centerIn: parent
            width: parent.width * 0.5
            height: parent.height * 0.5
            property color tint: button.kind === "play" ? Theme.onAccent
                : button.active ? Theme.accent
                : Theme.textPrimary
            property string kind: button.kind
            property bool playing: Mpd.playing
            onTintChanged: requestPaint()
            onKindChanged: requestPaint()
            onPlayingChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const w = width;
                const h = height;
                ctx.fillStyle = tint;
                ctx.strokeStyle = tint;
                ctx.lineWidth = Math.max(1.3, w * 0.11);
                ctx.lineCap = "round";
                ctx.lineJoin = "round";

                if (kind === "play") {
                    if (playing) {
                        ctx.fillRect(w * 0.18, 0, w * 0.22, h);
                        ctx.fillRect(w * 0.6, 0, w * 0.22, h);
                    } else {
                        ctx.beginPath();
                        ctx.moveTo(w * 0.2, 0);
                        ctx.lineTo(w, h / 2);
                        ctx.lineTo(w * 0.2, h);
                        ctx.closePath();
                        ctx.fill();
                    }
                } else if (kind === "next" || kind === "previous") {
                    const flip = kind === "previous";
                    ctx.save();
                    if (flip) {
                        ctx.translate(w, 0);
                        ctx.scale(-1, 1);
                    }
                    ctx.beginPath();
                    ctx.moveTo(0, 0);
                    ctx.lineTo(w * 0.72, h / 2);
                    ctx.lineTo(0, h);
                    ctx.closePath();
                    ctx.fill();
                    ctx.fillRect(w * 0.78, 0, w * 0.22, h);
                    ctx.restore();
                } else if (kind === "shuffle") {
                    ctx.beginPath();
                    ctx.moveTo(0, h * 0.2);
                    ctx.lineTo(w * 0.28, h * 0.2);
                    ctx.bezierCurveTo(w * 0.62, h * 0.2, w * 0.45, h * 0.8, w * 0.78, h * 0.8);
                    ctx.lineTo(w, h * 0.8);
                    ctx.moveTo(0, h * 0.8);
                    ctx.lineTo(w * 0.28, h * 0.8);
                    ctx.bezierCurveTo(w * 0.62, h * 0.8, w * 0.45, h * 0.2, w * 0.78, h * 0.2);
                    ctx.lineTo(w, h * 0.2);
                    ctx.stroke();
                    ctx.beginPath();
                    ctx.moveTo(w * 0.82, h * 0.02);
                    ctx.lineTo(w, h * 0.2);
                    ctx.lineTo(w * 0.82, h * 0.38);
                    ctx.moveTo(w * 0.82, h * 0.62);
                    ctx.lineTo(w, h * 0.8);
                    ctx.lineTo(w * 0.82, h * 0.98);
                    ctx.stroke();
                } else if (kind === "repeat") {
                    ctx.lineWidth = Math.max(1.2, w * 0.1);
                    const r = h * 0.28;
                    ctx.beginPath();                       // top edge, right corner, down
                    ctx.moveTo(w * 0.3, h * 0.16);
                    ctx.lineTo(w - r, h * 0.16);
                    ctx.quadraticCurveTo(w, h * 0.16, w, h * 0.16 + r);
                    ctx.lineTo(w, h * 0.5);
                    ctx.stroke();
                    ctx.beginPath();                       // bottom edge, left corner, up
                    ctx.moveTo(w * 0.7, h * 0.84);
                    ctx.lineTo(r, h * 0.84);
                    ctx.quadraticCurveTo(0, h * 0.84, 0, h * 0.84 - r);
                    ctx.lineTo(0, h * 0.5);
                    ctx.stroke();
                    ctx.beginPath();                       // arrow heads
                    ctx.moveTo(w * 0.46, h * 0.02);
                    ctx.lineTo(w * 0.3, h * 0.16);
                    ctx.lineTo(w * 0.46, h * 0.3);
                    ctx.moveTo(w * 0.54, h * 0.7);
                    ctx.lineTo(w * 0.7, h * 0.84);
                    ctx.lineTo(w * 0.54, h * 0.98);
                    ctx.stroke();
                }
            }
        }

        // the "1" on repeat-one
        Text {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 1
            visible: button.kind === "repeat" && Mpd.single && Mpd.repeat
            text: "1"
            color: Theme.accent
            font.pixelSize: 8
            font.weight: Font.Bold
            font.family: Theme.fontFamily
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.activated()
        }
    }

    Rectangle {
        id: art
        width: 96
        height: 96
        anchors.left: parent.left
        anchors.top: parent.top
        radius: 16
        color: Theme.controlBg
        clip: true

        Image {
            id: cover
            anchors.fill: parent
            source: AlbumArt.source
            sourceSize.width: 192
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
        }

        // a music glyph while there is no art
        Canvas {
            anchors.centerIn: parent
            width: 28
            height: 28
            visible: !cover.visible
            property color tint: Theme.textSecondary
            onTintChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.strokeStyle = tint;
                ctx.fillStyle = tint;
                ctx.lineWidth = 2;
                ctx.beginPath();
                ctx.moveTo(10, 22);
                ctx.lineTo(10, 5);
                ctx.lineTo(24, 2);
                ctx.lineTo(24, 19);
                ctx.stroke();
                ctx.beginPath();
                ctx.ellipse(3, 18, 8, 7);
                ctx.ellipse(17, 15, 8, 7);
                ctx.fill();
            }
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 6
        spacing: 2

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: Mpd.title || "Nothing playing"
            color: Theme.textPrimary
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            visible: text !== ""
            text: Mpd.artist
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            visible: text !== ""
            text: Mpd.album
            color: Qt.alpha(Theme.textSecondary, 0.7)
            font.pixelSize: 11
            font.family: Theme.fontFamily
        }
    }

    // Seek
    Item {
        id: seek
        anchors.left: art.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: art.top
        anchors.topMargin: 74
        height: 16

        readonly property real ratio: Mpd.duration > 0 ? Mpd.elapsed / Mpd.duration : 0

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: seekMouse.containsMouse || seekMouse.pressed ? 6 : 4
            radius: height / 2
            color: Theme.controlBg
            Behavior on height { NumberAnimation { duration: 120 } }

            Rectangle {
                width: parent.width * seek.ratio
                height: parent.height
                radius: parent.radius
                color: Theme.accent
            }

            Rectangle {
                x: parent.width * seek.ratio - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: seekMouse.containsMouse || seekMouse.pressed ? 12 : 0
                height: width
                radius: width / 2
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 120 } }
            }
        }

        MouseArea {
            id: seekMouse
            anchors.fill: parent
            anchors.margins: -5
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => scrub(mouse.x)
            onPositionChanged: mouse => { if (pressed) scrub(mouse.x); }

            function scrub(x) {
                Mpd.seek(Math.max(0, Math.min(1, (x - 5) / seek.width)) * Mpd.duration);
            }
        }
    }

    Text {
        anchors.left: seek.left
        anchors.top: seek.bottom
        anchors.topMargin: 2
        text: root.timeText(Mpd.elapsed)
        color: Theme.textSecondary
        font.pixelSize: 10
        font.family: Theme.fontFamily
    }

    Text {
        anchors.right: seek.right
        anchors.top: seek.bottom
        anchors.topMargin: 2
        text: root.timeText(Mpd.duration)
        color: Theme.textSecondary
        font.pixelSize: 10
        font.family: Theme.fontFamily
    }

    // Transport
    Row {
        id: transport
        anchors.left: art.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: art.bottom
        anchors.topMargin: 12
        spacing: 14

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            kind: "shuffle"
            active: Mpd.random
            scale_: 0.8
            onActivated: Mpd.toggleRandom()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            kind: "previous"
            onActivated: Mpd.previous()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            kind: "play"
            scale_: 1.35
            onActivated: Mpd.toggle()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            kind: "next"
            onActivated: Mpd.next()
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            kind: "repeat"
            active: Mpd.repeat
            scale_: 0.8
            onActivated: Mpd.cycleRepeat()
        }
    }

    // Volume
    Item {
        id: volume
        anchors.left: parent.left
        anchors.leftMargin: 26
        anchors.right: parent.right
        anchors.rightMargin: 26
        anchors.bottom: parent.bottom
        height: 16
        visible: Mpd.volume >= 0

        readonly property real ratio: Mpd.volume / 100

        Canvas {
            id: speaker
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 13
            height: 13
            property color tint: Theme.textSecondary
            onTintChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = tint;
                ctx.strokeStyle = tint;
                ctx.lineWidth = 1.3;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(1, 5);
                ctx.lineTo(4, 5);
                ctx.lineTo(7.5, 1.5);
                ctx.lineTo(7.5, 11.5);
                ctx.lineTo(4, 8);
                ctx.lineTo(1, 8);
                ctx.closePath();
                ctx.fill();
                ctx.beginPath();
                ctx.arc(8, 6.5, 3.4, -Math.PI / 3, Math.PI / 3);
                ctx.stroke();
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: speaker.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            height: 4
            radius: 2
            color: Theme.controlBg

            Rectangle {
                width: parent.width * volume.ratio
                height: parent.height
                radius: 2
                color: Qt.alpha(Theme.textPrimary, 0.75)
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -5
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => set(mouse.x)
            onPositionChanged: mouse => { if (pressed) set(mouse.x); }
            function set(x) {
                const track = volume.width - 21;      // the slider starts after the speaker glyph
                Mpd.setVolume(Math.max(0, Math.min(1, (x - 26) / track)) * 100);
            }
        }
    }
}
