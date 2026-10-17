import QtQuick
import Quickshell
import qs.config
import qs.services

// The control center, with no surface of its own: the pill grows into it in pill mode, and a
// panel drops down from the bar in bar mode.
//
// What is in it:
// - Wi-Fi (services/Wifi.qml) and Bluetooth (services/BluetoothManager.qml), each with a menu
//   (WifiPage.qml, BluetoothPage.qml) behind its label or a right click
// - Quiet (notifications to history only, Config.quiet), Dark (light/dark mode, Config.mode) and
//   Night (night light, services/NightLight.qml)
// - the Sound and Mic sliders (services/Audio.qml; click the label to mute, the device button at
//   the end for the Audio page, AudioPage.qml) and the Screen slider (services/Brightness.qml)
// - now playing with its transport (MPD, services/Mpd.qml; the song opens the media view), and
//   the record button
//   (services/Recorder.qml)
// - the bell (notification history, NotificationsPage.qml), the settings button (Poteto), and
//   lock, restart and power (services/Session.qml; restart and power open the power menu on
//   that action)
Item {
    id: root

    property bool active: false
    readonly property string page: ShellState.page

    signal closeRequested()

    onActiveChanged: {
        if (active && page === "main")
            keys.forceActiveFocus();
    }
    // Always opens on the main page
    onVisibleChanged: {
        if (!visible)
            ShellState.page = "main";
    }
    onPageChanged: {
        if (page === "main" && active)
            keys.forceActiveFocus();
    }

    implicitWidth: 448
    implicitHeight: page === "wifi" ? wifi.implicitHeight
        : page === "bluetooth" ? bluetooth.implicitHeight
        : page === "notifications" ? notifications.implicitHeight
        : page === "audio" ? audio.implicitHeight
        : column.implicitHeight

    Item {
        id: keys
        focus: root.active
        Keys.onEscapePressed: root.closeRequested()
    }

    WifiPage {
        id: wifi
        width: parent.width
        active: root.active && root.page === "wifi"
        opacity: root.page === "wifi" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
        onBackRequested: ShellState.page = "main"
    }

    BluetoothPage {
        id: bluetooth
        width: parent.width
        active: root.active && root.page === "bluetooth"
        opacity: root.page === "bluetooth" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
        onBackRequested: ShellState.page = "main"
    }

    AudioPage {
        id: audio
        width: parent.width
        active: root.active && root.page === "audio"
        opacity: root.page === "audio" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
        onBackRequested: ShellState.page = "main"
    }

    NotificationsPage {
        id: notifications
        width: parent.width
        active: root.active && root.page === "notifications"
        opacity: root.page === "notifications" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
        onBackRequested: ShellState.page = "main"
    }

    Column {
        id: column
        width: parent.width
        spacing: 12
        opacity: root.page === "main" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

        // Quick toggles
        Row {
            id: toggleRow

            readonly property var items: [
                { id: "wifi", label: "Wi-Fi", glyph: "󰖩" },
                { id: "bluetooth", label: "Bluetooth", glyph: "󰂯" },
                { id: "quiet", label: "Quiet", glyph: "󰽥" },
                { id: "dark", label: "Dark", glyph: "󰔎" },
                { id: "night", label: "Night", glyph: "󰖨" }
            ]

            width: parent.width

            Repeater {
                model: toggleRow.items

                Column {
                    id: toggle

                    required property var modelData
                    readonly property bool isWifi: modelData.id === "wifi"
                    readonly property bool isBluetooth: modelData.id === "bluetooth"
                    // Has a menu of its own, opened from the label or a right click
                    readonly property bool hasPage: isWifi || isBluetooth
                    // What the label says: the network or device in use, or the toggle's name
                    readonly property string labelText: isWifi && Wifi.enabled && Wifi.active ? Wifi.active.ssid
                        : isBluetooth && BluetoothManager.connectedDevices.length > 0
                            ? BluetoothManager.displayName(BluetoothManager.connectedDevices[0])
                        : modelData.label
                    readonly property bool isOn: isWifi ? Wifi.enabled
                        : isBluetooth ? BluetoothManager.enabled
                        : modelData.id === "dark" ? Config.mode === "dark"
                        : modelData.id === "night" ? NightLight.enabled
                        : modelData.id === "quiet" ? Config.quiet
                        : false

                    width: toggleRow.width / toggleRow.items.length
                    spacing: 6

                    RoundButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        glyph: toggle.modelData.glyph
                        on: toggle.isOn
                        onClicked: toggle.isWifi ? Wifi.setEnabled(!Wifi.enabled)
                            : toggle.isBluetooth ? BluetoothManager.setEnabled(!BluetoothManager.enabled)
                            : toggle.modelData.id === "dark" ? Config.toggleMode()
                            : toggle.modelData.id === "night" ? NightLight.toggle()
                            : Config.setQuiet(!Config.quiet)
                        onSecondaryClicked: {
                            if (toggle.hasPage)
                                ShellState.openPage(toggle.modelData.id);
                        }
                    }

                    // Wi-Fi's and Bluetooth's labels name what is in use and open their menus
                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: name.width + (chevron.visible ? chevron.implicitWidth + 2 : 0)
                        height: name.implicitHeight

                        Text {
                            id: name
                            // A long network name is cut short, with room left for the chevron
                            width: toggle.hasPage ? Math.min(implicitWidth, toggle.width - 12) : implicitWidth
                            elide: Text.ElideRight
                            text: toggle.labelText
                            color: toggle.isOn || labelMouse.containsMouse ? Theme.text : Theme.textDim
                            font.pixelSize: 11
                            font.family: Theme.fontFamily
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }

                        Text {
                            id: chevron
                            visible: toggle.hasPage
                            anchors.left: name.right
                            anchors.leftMargin: 2
                            anchors.verticalCenter: name.verticalCenter
                            text: "󰅂"
                            color: labelMouse.containsMouse ? Theme.text : Theme.textDim
                            font.pixelSize: 10
                            font.family: Theme.monoFamily
                        }

                        MouseArea {
                            id: labelMouse
                            anchors.fill: parent
                            anchors.margins: -4
                            enabled: toggle.hasPage
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellState.openPage(toggle.modelData.id)
                        }
                    }
                }
            }
        }

        DotSlider {
            width: parent.width
            label: "Sound"
            visible: Audio.available
            value: Audio.percent
            maxValue: Audio.maxPercent
            dimmed: Audio.muted
            labelClickable: true
            onMoved: v => Audio.setPercent(v)
            onLabelClicked: Audio.toggleMute()
            // The device in use; opens the Audio page to switch
            actionGlyph: Audio.glyphFor(Audio.activeOutput?.kind ?? "speaker")
            onActionClicked: ShellState.openPage("audio")
        }

        DotSlider {
            width: parent.width
            label: "Mic"
            visible: Audio.micAvailable
            value: Audio.micPercent
            dimmed: Audio.micMuted
            dimmedText: "Off"
            labelClickable: true
            onMoved: v => Audio.setMicPercent(v)
            onLabelClicked: Audio.toggleMicMute()
            actionGlyph: Audio.glyphFor(Audio.activeInput?.kind ?? "mic")
            onActionClicked: ShellState.openPage("audio")
        }

        DotSlider {
            width: parent.width
            label: "Screen"
            visible: Brightness.available
            value: Brightness.percent
            onMoved: v => Brightness.set(v)
        }

        // Now playing, then the session
        Item {
            width: parent.width
            height: 34

            RoundButton {
                id: record
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 34
                implicitHeight: 34
                // Starts the screen recorder, or stops the recording in progress
                onClicked: {
                    root.closeRequested();
                    Recorder.toggle();
                }

                // A dot to record, a square to stop
                Rectangle {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    radius: Recorder.recording ? 2 : 5
                    color: Theme.danger
                    Behavior on radius { NumberAnimation { duration: 160 } }
                }
            }

            Column {
                id: nowPlaying
                anchors.left: record.right
                anchors.leftMargin: 10
                anchors.right: transport.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: Mpd.active ? Mpd.title : !Mpd.connected ? "MPD is not running" : "Nothing playing"
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.family: Theme.fontFamily
                }

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    visible: text !== ""
                    text: Mpd.active ? (Mpd.artist || Mpd.album) : ""
                    color: Theme.textDim
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }

                // How far into the song
                Rectangle {
                    width: parent.width
                    height: 2
                    radius: 1
                    visible: Mpd.active && Mpd.duration > 0
                    color: Qt.alpha(Theme.text, 0.16)

                    Rectangle {
                        width: parent.width * Math.min(1, Mpd.elapsed / Math.max(1, Mpd.duration))
                        height: parent.height
                        radius: parent.radius
                        color: Theme.textDim
                        Behavior on width { NumberAnimation { duration: 900 } }
                    }
                }
            }

            // The song opens the media view: art, seek, shuffle, repeat. Over the column, not in
            // it, so the column does not size itself from its own click area
            MouseArea {
                anchors.fill: nowPlaying
                enabled: Mpd.connected
                cursorShape: Qt.PointingHandCursor
                onClicked: ShellState.open("media")
            }

            Row {
                id: transport
                anchors.right: divider.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                // MPD (services/Mpd.qml); faded and inert while it is not running
                enabled: Mpd.connected
                opacity: enabled ? 1 : 0.4

                RoundButton {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 30
                    implicitHeight: 30
                    flat: true
                    glyph: "󰒮"
                    glyphSize: 14
                    onClicked: Mpd.previous()
                }

                // Play / pause: the one solid button in the row
                RoundButton {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 32
                    implicitHeight: 32
                    on: true
                    onColor: Theme.text
                    onGlyph: Theme.background
                    glyph: Mpd.playing ? "󰏤" : "󰐊"
                    glyphSize: 14
                    onClicked: Mpd.toggle()
                }

                RoundButton {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 30
                    implicitHeight: 30
                    flat: true
                    glyph: "󰒭"
                    glyphSize: 14
                    onClicked: Mpd.next()
                }
            }

            Rectangle {
                id: divider
                anchors.right: session.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 18
                color: Theme.border
            }

            Row {
                id: session
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                // Notifications: the history page, with the number of unread ones
                RoundButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    glyph: Notifications.unread > 0 ? "󰂚" : "󰂜"
                    glyphSize: 14
                    onClicked: ShellState.openPage("notifications")

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: -3
                        visible: Notifications.unread > 0
                        width: Math.max(16, unreadText.implicitWidth + 8)
                        height: 16
                        radius: 8
                        color: Theme.accent

                        Text {
                            id: unreadText
                            anchors.centerIn: parent
                            text: Notifications.unread > 99 ? "99+" : Notifications.unread
                            color: Theme.accentText
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            font.family: Theme.fontFamily
                        }
                    }
                }

                // Settings: opens Poteto (settings/poteto-settings), and gets out of its way
                RoundButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    glyph: "󰒓"
                    glyphSize: 14
                    onClicked: {
                        // From the repo itself, next to the shell, so it does not depend on
                        // ~/.local/bin being on PATH
                        Quickshell.execDetached([Quickshell.shellDir + "/../settings/poteto-settings"]);
                        root.closeRequested();
                    }
                }

                RoundButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    glyph: "󰌾"
                    glyphSize: 14
                    onClicked: {
                        root.closeRequested();
                        Session.run("lock");
                    }
                }

                RoundButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    glyph: "󰜉"
                    glyphSize: 14
                    // The power menu, on Reboot and waiting for one more press
                    onClicked: Session.openMenu("reboot")
                }

                RoundButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    on: true
                    onColor: Theme.danger
                    onGlyph: Theme.background
                    glyph: "⏻"
                    glyphSize: 14
                    onClicked: Session.openMenu("poweroff")
                }
            }
        }
    }
}
