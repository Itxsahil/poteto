import QtQuick
import QtMultimedia
import Quickshell
import qs.config
import qs.services

// The video window the launcher opens: a plain floating window with an overlay that
// fades out while playing.
FloatingWindow {
    id: win

    visible: Player.playing
    title: Player.title || "Player"
    implicitWidth: 1100
    implicitHeight: 640
    minimumSize.width: 480
    minimumSize.height: 300
    color: "#000000"

    readonly property bool paused: media.playbackState !== MediaPlayer.PlayingState
    property bool controlsShown: true

    function seekBy(ms) {
        if (media.seekable)
            media.setPosition(Math.max(0, Math.min(media.duration, media.position + ms)));
    }

    function togglePlay() {
        if (paused)
            media.play();
        else
            media.pause();
        win.wake();
    }

    function wake() {
        controlsShown = true;
        hideTimer.restart();
    }

    function cycleSubtitles() {
        const count = media.subtitleTracks.length;
        if (count === 0)
            return;
        media.activeSubtitleTrack = media.activeSubtitleTrack + 1 >= count ? -1 : media.activeSubtitleTrack + 1;
    }

    function timeText(ms) {
        if (!(ms > 0))
            return "0:00";
        const s = Math.floor(ms / 1000);
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = String(s % 60).padStart(2, "0");
        return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${sec}` : `${m}:${sec}`;
    }

    onVisibleChanged: {
        if (visible) {
            keys.forceActiveFocus();
            wake();
        } else {
            media.stop();
            clickTimer.stop();
            fullscreen = false;
        }
    }

    // Closing the window from the compositor must stop playback, not leave it running unseen
    onClosed: Player.close()

    MediaPlayer {
        id: media
        source: Player.url
        videoOutput: output
        playbackRate: Player.speed
        audioOutput: AudioOutput {
            id: audio
            volume: 1.0
        }
        onSourceChanged: {
            if (source != "")
                play();
        }
        // EndOfMedia fires even with MediaPlayer.loops set, so the repeat is done here instead
        onMediaStatusChanged: {
            if (mediaStatus !== MediaPlayer.EndOfMedia)
                return;
            if (Player.loop === "one" || (Player.loop === "all" && Player.playlist.length < 2)) {
                setPosition(0);
                play();
            } else if (Player.hasNext) {
                Player.next();
            } else {
                Player.close();
            }
        }
    }

    VideoOutput {
        id: output
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
    }

    Timer {
        id: hideTimer
        interval: 2500
        onTriggered: {
            if (!win.paused && !bottomHover.hovered)
                win.controlsShown = false;
        }
    }

    // Any movement brings the overlay back
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: win.controlsShown ? Qt.ArrowCursor : Qt.BlankCursor
        onPositionChanged: win.wake()
        // Held briefly: a double click would otherwise pause on its way to fullscreen
        onClicked: clickTimer.restart()
        onDoubleClicked: {
            clickTimer.stop();
            win.fullscreen = !win.fullscreen;
        }
    }

    Timer {
        id: clickTimer
        interval: 220
        onTriggered: win.togglePlay()
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            const shift = event.modifiers & Qt.ShiftModifier;
            if (event.key === Qt.Key_Space || event.key === Qt.Key_K) {
                win.togglePlay();
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                win.seekBy(shift ? 60000 : 5000);
                win.wake();
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                win.seekBy(shift ? -60000 : -5000);
                win.wake();
            } else if (event.key === Qt.Key_Up) {
                audio.volume = Math.min(1, audio.volume + 0.05);
                win.wake();
            } else if (event.key === Qt.Key_Down) {
                audio.volume = Math.max(0, audio.volume - 0.05);
                win.wake();
            } else if (event.key === Qt.Key_M) {
                audio.muted = !audio.muted;
                win.wake();
            } else if (event.key === Qt.Key_F) {
                win.fullscreen = !win.fullscreen;
            } else if (event.key === Qt.Key_R) {
                Player.cycleLoop();
                win.wake();
            } else if (event.key === Qt.Key_BracketRight) {
                Player.cycleSpeed(1);
                win.wake();
            } else if (event.key === Qt.Key_BracketLeft) {
                Player.cycleSpeed(-1);
                win.wake();
            } else if (event.key === Qt.Key_C) {
                win.cycleSubtitles();
                win.wake();
            } else if (event.key === Qt.Key_N) {
                Player.next();
            } else if (event.key === Qt.Key_P) {
                Player.previous();
            } else if (event.key === Qt.Key_O) {
                Player.openExternally();
                Player.close();
            } else if (event.key === Qt.Key_Escape) {
                if (win.fullscreen)
                    win.fullscreen = false;
                else
                    Player.close();
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    component BarButton: Text {
        property bool on: false
        property bool dim: false
        signal activated()
        color: on ? Theme.accent : mouse.containsMouse ? "#ffffff" : "#99ffffff"
        opacity: dim ? 0.35 : 1
        font.pixelSize: 13
        font.weight: Font.DemiBold
        font.family: Theme.fontFamily
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: mouse
            anchors.fill: parent
            anchors.margins: -7
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
    }

    // Title, top
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 64
        opacity: win.controlsShown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#cc000000" }
            GradientStop { position: 1.0; color: "#00000000" }
        }

        Text {
            anchors.left: parent.left
            anchors.right: counter.left
            anchors.rightMargin: 16
            anchors.top: parent.top
            anchors.leftMargin: 20
            anchors.topMargin: 16
            elide: Text.ElideMiddle
            text: Player.title
            color: "#ffffff"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Text {
            id: counter
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.top: parent.top
            anchors.topMargin: 17
            visible: Player.playlist.length > 1
            text: `${Player.index + 1} / ${Player.playlist.length}`
            color: "#99ffffff"
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }

    // Controls, bottom
    Rectangle {
        id: bar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 96
        opacity: win.controlsShown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 1.0; color: "#e6000000" }
        }

        HoverHandler {
            id: bottomHover
            onHoveredChanged: if (hovered) win.wake()
        }

        // Seek bar
        Item {
            id: seek
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            anchors.top: parent.top
            anchors.topMargin: 26
            height: 18

            readonly property real ratio: media.duration > 0 ? media.position / media.duration : 0

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: seekMouse.containsMouse || seekMouse.pressed ? 6 : 4
                radius: height / 2
                color: "#40ffffff"
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
                    width: seekMouse.containsMouse || seekMouse.pressed ? 14 : 0
                    height: width
                    radius: width / 2
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 120 } }
                }
            }

            MouseArea {
                id: seekMouse
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => scrub(mouse.x)
                onPositionChanged: mouse => {
                    win.wake();
                    if (pressed)
                        scrub(mouse.x);
                }

                function scrub(x) {
                    if (media.duration > 0 && media.seekable)
                        media.setPosition(Math.max(0, Math.min(1, (x - 6) / seek.width)) * media.duration);
                }
            }
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            spacing: 14

            BarButton {
                anchors.verticalCenter: parent.verticalCenter
                text: "⏮"
                font.pixelSize: 15
                dim: Player.playlist.length < 2
                onActivated: Player.previous()
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36
                radius: 18
                color: playMouse.containsMouse ? Qt.alpha(Theme.accent, 0.9) : Theme.accent

                Canvas {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    property bool showPlay: win.paused
                    property color tint: Theme.onAccent
                    onShowPlayChanged: requestPaint()
                    onTintChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.fillStyle = tint;
                        if (showPlay) {
                            ctx.beginPath();
                            ctx.moveTo(2, 0);
                            ctx.lineTo(14, 7);
                            ctx.lineTo(2, 14);
                            ctx.closePath();
                            ctx.fill();
                        } else {
                            ctx.fillRect(1, 0, 4.5, 14);
                            ctx.fillRect(8.5, 0, 4.5, 14);
                        }
                    }
                }

                MouseArea {
                    id: playMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.togglePlay()
                }
            }

            BarButton {
                anchors.verticalCenter: parent.verticalCenter
                text: "⏭"
                font.pixelSize: 15
                dim: Player.playlist.length < 2
                onActivated: Player.next()
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: `${win.timeText(media.position)}  /  ${win.timeText(media.duration)}`
                color: "#ffffff"
                font.pixelSize: 12
                font.family: Theme.fontFamily
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            spacing: 16

            BarButton {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Player.speed}×`
                on: Player.speed !== 1.0
                onActivated: Player.cycleSpeed(1)
            }

            BarButton {
                anchors.verticalCenter: parent.verticalCenter
                text: "CC"
                visible: media.subtitleTracks.length > 0
                on: media.activeSubtitleTrack >= 0
                onActivated: win.cycleSubtitles()
            }

            BarButton {
                anchors.verticalCenter: parent.verticalCenter
                text: Player.loop === "one" ? "↻¹" : "↻"
                font.pixelSize: 15
                on: Player.loop !== "off"
                onActivated: Player.cycleLoop()
            }

            // Volume
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: audio.muted || audio.volume === 0 ? "🔇" : "🔊"
                    font.pixelSize: 14

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: audio.muted = !audio.muted
                    }
                }

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 70
                    height: 16

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 4
                        radius: 2
                        color: "#40ffffff"

                        Rectangle {
                            width: parent.width * (audio.muted ? 0 : audio.volume)
                            height: parent.height
                            radius: 2
                            color: "#ffffff"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: mouse => set(mouse.x)
                        onPositionChanged: mouse => { if (pressed) set(mouse.x); }
                        function set(x) {
                            audio.muted = false;
                            audio.volume = Math.max(0, Math.min(1, x / width));
                        }
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "mpv"
                color: mpvMouse.containsMouse ? "#ffffff" : "#99ffffff"
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.family: Theme.fontFamily

                MouseArea {
                    id: mpvMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Player.openExternally();
                        Player.close();
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: win.fullscreen ? "⤡" : "⤢"
                color: fsMouse.containsMouse ? "#ffffff" : "#99ffffff"
                font.pixelSize: 16
                font.family: Theme.fontFamily

                MouseArea {
                    id: fsMouse
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.fullscreen = !win.fullscreen
                }
            }
        }
    }

    // Loading / error
    Text {
        anchors.centerIn: parent
        visible: media.error !== MediaPlayer.NoError
        text: media.errorString || "Could not play this file"
        color: "#ffffff"
        font.pixelSize: 14
        font.family: Theme.fontFamily
    }

    Text {
        anchors.centerIn: parent
        visible: media.error === MediaPlayer.NoError
            && (media.mediaStatus === MediaPlayer.LoadingMedia || media.mediaStatus === MediaPlayer.BufferingMedia)
        text: "Loading…"
        color: "#99ffffff"
        font.pixelSize: 13
        font.family: Theme.fontFamily
    }
}
