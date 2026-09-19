import QtQuick
import Qt5Compat.GraphicalEffects
import QtMultimedia
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    // Transparent: the video sits at a negative z, which draws behind the root's own fill
    color: "transparent"
    readonly property real s: height / 1080

    // Wayland cursor fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }

    // Palette pulled from the wallpaper: wet night, cold light, a little steel blue
    readonly property color fg: "#dbe4ec"
    readonly property color steel: "#8fb0c7"
    readonly property color rain: "#a8c4d8"
    readonly property color bad: "#d98a8a"
    readonly property string mono: "JetBrainsMono Nerd Font"

    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property bool userMenuOpen: false
    property bool sessionMenuOpen: false
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined

    TextConstants { id: textConstants }

    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.userIndex
        opacity: 0; width: 1; height: 1; z: -100
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }

    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        opacity: 0; width: 1; height: 1; z: -100
        delegate: Item { property string sName: model.name || "" }
    }

    // Background video, over a black backdrop for the moment before the first frame
    Rectangle {
        anchors.fill: parent
        color: "#05080b"
        z: -1000
    }

    MediaPlayer {
        id: player
        source: "bg.mp4"
        videoOutput: bgVideo
        loops: MediaPlayer.Infinite
        Component.onCompleted: play()
    }

    VideoOutput {
        id: bgVideo
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        z: -500
    }

    // Darken the right half so the text stays readable over the rain
    Rectangle {
        anchors.fill: parent
        z: -300
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 0.45; color: "#33060a0e" }
            GradientStop { position: 1.0; color: "#b3060a0e" }
        }
    }

    // A few drifting streaks, echoing the rain in the video
    Item {
        anchors.fill: parent
        z: -200
        opacity: 0.5

        Repeater {
            model: 14

            Rectangle {
                id: drop
                required property int index
                readonly property real lane: (index + 0.5) / 14
                width: 1
                height: (40 + (index % 5) * 26) * root.s
                radius: width / 2
                color: root.rain
                opacity: 0.10 + (index % 3) * 0.05
                rotation: 8
                x: root.width * (0.42 + lane * 0.58) + (index % 7) * 9 * root.s

                NumberAnimation on y {
                    running: true
                    loops: Animation.Infinite
                    from: -drop.height - root.height * 0.1
                    to: root.height + drop.height
                    duration: 1500 + (drop.index % 6) * 550
                }
            }
        }
    }

    // Clock + login, kept on the right so the figure on the left stays visible
    Column {
        id: panel
        anchors.right: parent.right
        anchors.rightMargin: 120 * s
        anchors.verticalCenter: parent.verticalCenter
        width: 460 * s
        spacing: 0

        Text {
            id: timeLabel
            anchors.right: parent.right
            text: root.clockTime(new Date())
            font.family: root.mono
            font.weight: Font.Thin
            font.pixelSize: 132 * s
            font.letterSpacing: -2 * s
            color: root.fg
            layer.enabled: true
            layer.effect: DropShadow { color: "#99000000"; radius: 18; samples: 25 }
        }

        Row {
            anchors.right: parent.right
            spacing: 10 * s
            topPadding: 6 * s

            Text {
                id: meridiem
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(new Date(), "AP")
                font.family: root.mono
                font.pixelSize: 13 * s
                font.letterSpacing: 4 * s
                color: root.steel
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 30 * s
                height: 1
                color: root.steel
                opacity: 0.35
            }

            Text {
                id: dateLabel
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDate(new Date(), "dddd · dd MMM").toUpperCase()
                font.family: root.mono
                font.pixelSize: 13 * s
                font.letterSpacing: 4 * s
                color: root.fg
                opacity: 0.65
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                const now = new Date();
                timeLabel.text = root.clockTime(now);
                meridiem.text = Qt.formatTime(now, "AP");
                dateLabel.text = Qt.formatDate(now, "dddd · dd MMM").toUpperCase();
            }
        }

        Item { width: 1; height: 54 * s }

        // User
        Item {
            id: userRow
            anchors.right: parent.right
            width: parent.width
            height: userLabel.height

            Text {
                id: userLabel
                anchors.right: parent.right
                text: (userHelper.currentItem && userHelper.currentItem.uName ? userHelper.currentItem.uName : "USER").toUpperCase()
                font.family: root.mono
                font.weight: Font.Light
                font.pixelSize: 20 * s
                font.letterSpacing: 6 * s
                color: (root.userMenuOpen || userMouse.containsMouse) ? root.steel : root.fg
                Behavior on color { ColorAnimation { duration: 220 } }
                layer.enabled: true
                layer.effect: DropShadow { color: "#99000000"; radius: 10; samples: 17 }

                MouseArea {
                    id: userMouse
                    anchors.fill: parent
                    anchors.margins: -6 * root.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.userMenuOpen = !root.userMenuOpen
                }
            }

            Item {
                anchors.right: parent.right
                anchors.bottom: userLabel.top
                anchors.bottomMargin: 14 * s
                width: parent.width
                height: root.userMenuOpen ? (34 * s * (typeof userModel !== "undefined" ? userModel.rowCount() : 0)) + 14 * s : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutExpo } }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.steel
                    opacity: 0.3
                }

                Column {
                    anchors.fill: parent
                    anchors.rightMargin: 16 * s
                    anchors.topMargin: 7 * s
                    spacing: 6 * s

                    Repeater {
                        model: typeof userModel !== "undefined" ? userModel : null

                        Item {
                            width: panel.width - 20 * root.s
                            height: 28 * root.s

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: (model.realName || model.name).toUpperCase()
                                font.family: root.mono
                                font.pixelSize: 13 * root.s
                                font.letterSpacing: 3 * root.s
                                color: root.userIndex === index ? root.steel : root.fg
                                opacity: (root.userIndex === index || itemMouse.containsMouse) ? 1 : 0.45
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.userIndex = index;
                                    root.userMenuOpen = false;
                                    passInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { width: 1; height: 18 * s }

        // Password
        Item {
            id: field
            anchors.right: parent.right
            width: parent.width
            height: 46 * s

            TextInput {
                id: passInput
                anchors.left: parent.left
                anchors.right: submit.left
                anchors.rightMargin: 14 * s
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: TextInput.AlignRight
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                passwordCharacter: "•"
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase
                font.family: root.mono
                font.pixelSize: 19 * root.s
                font.letterSpacing: 8 * root.s
                color: root.fg
                focus: true
                cursorVisible: false
                cursorDelegate: Item {}
                selectionColor: root.steel
                onTextEdited: errorLabel.text = ""
                onAccepted: root.doLogin()

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: passInput.text.length === 0
                    text: "ENTER PASSWORD"
                    font.family: root.mono
                    font.pixelSize: 12 * root.s
                    font.letterSpacing: 4 * root.s
                    color: root.fg
                    opacity: 0.35
                    SequentialAnimation on opacity {
                        running: passInput.text.length === 0
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.16; duration: 1800; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.35; duration: 1800; easing.type: Easing.InOutSine }
                    }
                }

                Rectangle {
                    id: caret
                    width: 1.5 * root.s
                    height: 22 * root.s
                    color: root.steel
                    anchors.verticalCenter: parent.verticalCenter
                    x: passInput.cursorRectangle.x
                    visible: passInput.activeFocus && passInput.text.length > 0
                }
            }

            // Submit: a ring that fills like a drop hitting water
            Item {
                id: submit
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 34 * root.s
                height: 34 * root.s
                opacity: passInput.text.length > 0 ? 1 : 0.25
                Behavior on opacity { NumberAnimation { duration: 250 } }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: submitMouse.containsMouse ? Qt.rgba(root.steel.r, root.steel.g, root.steel.b, 0.15) : "transparent"
                    border.width: 1
                    border.color: root.steel
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                Text {
                    anchors.centerIn: parent
                    text: "→"
                    font.family: root.mono
                    font.pixelSize: 15 * root.s
                    color: root.fg
                }

                MouseArea {
                    id: submitMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.doLogin()
                }
            }

        }

        Item {
            anchors.right: parent.right
            width: parent.width
            height: 26 * s

            Text {
                id: errorLabel
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 7 * root.s
                text: ""
                font.family: root.mono
                font.pixelSize: 11 * root.s
                font.letterSpacing: 3 * root.s
                color: root.bad
            }

            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.topMargin: 7 * root.s
                visible: typeof keyboard !== "undefined" && keyboard.capsLock
                text: "CAPS LOCK"
                font.family: root.mono
                font.pixelSize: 11 * root.s
                font.letterSpacing: 3 * root.s
                color: root.steel
                opacity: 0.8
            }
        }
    }

    // Session and power, bottom right: the left side belongs to the figure
    Column {
        id: footer
        anchors.right: parent.right
        anchors.rightMargin: 120 * s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80 * s
        width: 460 * s
        spacing: 16 * s

        Item {
            width: parent.width
            height: sessionLabel.height
            visible: !root.isQuickshell

            Text {
                id: sessionLabel
                anchors.right: parent.right
                text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "SESSION").toUpperCase()
                font.family: root.mono
                font.pixelSize: 13 * root.s
                font.letterSpacing: 4 * root.s
                color: (root.sessionMenuOpen || sessionMouse.containsMouse) ? root.steel : root.fg
                opacity: 0.75
                Behavior on color { ColorAnimation { duration: 220 } }

                MouseArea {
                    id: sessionMouse
                    anchors.fill: parent
                    anchors.margins: -6 * root.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.sessionMenuOpen = !root.sessionMenuOpen
                }
            }

            Item {
                anchors.right: parent.right
                anchors.bottom: parent.top
                anchors.bottomMargin: 14 * root.s
                width: 300 * root.s
                height: root.sessionMenuOpen ? (32 * root.s * (typeof sessionModel !== "undefined" ? sessionModel.rowCount() : 0)) + 14 * root.s : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutExpo } }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.steel
                    opacity: 0.3
                }

                Column {
                    anchors.fill: parent
                    anchors.rightMargin: 16 * root.s
                    anchors.topMargin: 7 * root.s
                    spacing: 6 * root.s

                    Repeater {
                        model: typeof sessionModel !== "undefined" ? sessionModel : null

                        Item {
                            width: 260 * root.s
                            height: 26 * root.s

                            Text {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: model.name.toUpperCase()
                                font.family: root.mono
                                font.pixelSize: 12 * root.s
                                font.letterSpacing: 3 * root.s
                                color: root.sessionIndex === index ? root.steel : root.fg
                                opacity: (root.sessionIndex === index || sessionItemMouse.containsMouse) ? 1 : 0.45
                                Behavior on opacity { NumberAnimation { duration: 180 } }
                            }

                            MouseArea {
                                id: sessionItemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.sessionIndex = index;
                                    root.sessionMenuOpen = false;
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: powerRow.height

            Row {
                id: powerRow
                anchors.right: parent.right
                spacing: 18 * root.s

                Text {
                    text: "RESTART"
                    font.family: root.mono
                    font.pixelSize: 11 * root.s
                    font.letterSpacing: 3 * root.s
                    color: rebootMouse.containsMouse ? root.steel : root.fg
                    opacity: rebootMouse.containsMouse ? 1 : 0.45
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        anchors.margins: -6 * root.s
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (typeof sddm !== "undefined") sddm.reboot()
                    }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 9 * root.s
                color: root.steel
                opacity: 0.3
            }

            Text {
                text: "SHUT DOWN"
                font.family: root.mono
                font.pixelSize: 11 * root.s
                font.letterSpacing: 3 * root.s
                color: powerMouse.containsMouse ? root.steel : root.fg
                opacity: powerMouse.containsMouse ? 1 : 0.45
                Behavior on opacity { NumberAnimation { duration: 200 } }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    anchors.margins: -6 * root.s
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (typeof sddm !== "undefined") sddm.powerOff()
                    }
                }
            }
        }
    }

    // 12-hour clock without the meridiem, which sits on its own line below
    function clockTime(date) {
        return Qt.formatTime(date, "hh:mm AP").split(" ")[0];
    }

    function doLogin() {
        if (passInput.text.length === 0)
            return;
        let name = "";
        if (userHelper.currentItem && userHelper.currentItem.uLogin)
            name = userHelper.currentItem.uLogin;
        else if (typeof userModel !== "undefined")
            name = userModel.lastUser;
        if (typeof sddm !== "undefined")
            sddm.login(name, passInput.text, root.sessionIndex);
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null

        function onLoginFailed() {
            errorLabel.text = "WRONG PASSWORD";
            passInput.text = "";
            passInput.forceActiveFocus();
            shake.restart();
        }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: panel; property: "anchors.rightMargin"; to: 132 * root.s; duration: 60 }
        NumberAnimation { target: panel; property: "anchors.rightMargin"; to: 110 * root.s; duration: 60 }
        NumberAnimation { target: panel; property: "anchors.rightMargin"; to: 120 * root.s; duration: 90; easing.type: Easing.OutCubic }
    }

    Timer {
        interval: 250
        running: true
        onTriggered: passInput.forceActiveFocus()
    }

    Component.onCompleted: if (typeof keyboard !== "undefined") keyboard.numLock = true
}
