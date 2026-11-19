import QtQuick
import qs.services
import qs.modules.controlcenter.tiles
import qs.modules.controlcenter.controls
import qs.modules.controlcenter.wifi
import qs.modules.controlcenter.bluetooth
import qs.modules.controlcenter.notifications
import qs.modules.controlcenter.audio
import qs.config
import qs.components

Item {
    id: root

    readonly property int gap: 10
    readonly property int colWidth: 235

    property date date: new Date()
    property string page: ""
    readonly property bool typing: wifiPage.typing
    readonly property bool busy: brightness.pressed || volume.pressed || mic.pressed || warmth.pressed || wifiPage.typing

    function reset() {
        page = "";
        calendar.reset();
        wifiPage.reset();
        bluetoothPage.reset();
        notificationsPage.reset();
        audioPage.reset();
    }

    implicitWidth: colWidth * 2 + gap
    implicitHeight: grid.implicitHeight
    clip: true

    onPageChanged: {
        if (page === "wifi")
            Wifi.rescan();
        if (page === "bluetooth")
            BluetoothManager.startScan();
        else
            BluetoothManager.stopScan();
        if (page === "notifications")
            Notifications.markRead();
    }

    component Page: Item {
        required property string name
        width: root.width
        height: root.height
        x: root.page === name ? 0 : root.width + 40
        opacity: root.page === name ? 1 : 0
        visible: opacity > 0
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 220 } }
    }

    Column {
        id: grid
        width: parent.width
        spacing: root.gap
        x: root.page !== "" ? -width - 40 : 0
        opacity: root.page !== "" ? 0 : 1
        Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 220 } }

        // Bento: the clock (which opens the calendar) wide beside the battery, then Wi-Fi and
        // Bluetooth, notifications and night light, and the sliders together in one tile
        Row {
            spacing: root.gap

            ClockTile {
                width: root.width - batteryTile.width - root.gap
                height: 88
                date: root.date
                onOpenRequested: root.page = "calendar"
            }

            BatteryTile {
                id: batteryTile
                width: 150
                height: 88
            }
        }

        Row {
            spacing: root.gap

            WifiTile {
                width: root.colWidth
                height: 60
                padding: 10
                onOpenRequested: root.page = "wifi"
            }

            BluetoothTile {
                width: root.colWidth
                height: 60
                padding: 10
                onOpenRequested: root.page = "bluetooth"
            }
        }

        Row {
            spacing: root.gap

            NotificationsTile {
                width: root.colWidth
                height: 60
                padding: 10
                onOpenRequested: root.page = "notifications"
            }

            NightLightTile {
                width: root.colWidth
                height: 60
                padding: 10
                onOpenRequested: root.page = "nightlight"
            }
        }

        Tile {
            width: parent.width
            height: sliders.implicitHeight + padding * 2
            padding: 10

            Column {
                id: sliders
                width: parent.width
                spacing: 8

                BrightnessSlider {
                    id: brightness
                    width: parent.width
                }

                // Volume and mic, each with a button to the Sound page when there is more than
                // one device to choose from
                Row {
                    width: parent.width
                    spacing: 8

                    VolumeSlider {
                        id: volume
                        width: parent.width - (outputButton.visible ? outputButton.width + parent.spacing : 0)
                    }

                    DeviceButton {
                        id: outputButton
                        visible: Audio.outputs.length > 1
                        glyph: /head(phone|set)|earphone/i.test(Audio.outputs.find(e => e.active)?.label ?? "") ? "󰋋" : "󰓃"
                    }
                }

                Row {
                    width: parent.width
                    spacing: 8

                    MicSlider {
                        id: mic
                        width: parent.width - (inputButton.visible ? inputButton.width + parent.spacing : 0)
                    }

                    DeviceButton {
                        id: inputButton
                        visible: Audio.inputs.length > 1
                        glyph: /head(phone|set)/i.test(Audio.inputs.find(e => e.active)?.label ?? "") ? "󰋎" : "󰍬"
                    }
                }
            }
        }
    }

    // Opens the Sound page: the device in use, as an icon, with a chevron
    component DeviceButton: Rectangle {
        id: button

        property string glyph

        width: 56
        height: 40
        radius: 20
        color: buttonMouse.containsMouse ? Theme.controlHover : Theme.controlBg
        Behavior on color { ColorAnimation { duration: 120 } }

        Row {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: button.glyph
                color: Theme.textPrimary
                font.pixelSize: 17
                font.family: "JetBrainsMono Nerd Font"
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -1
                text: "›"
                color: Theme.textSecondary
                font.pixelSize: 18
                font.family: Theme.fontFamily
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.page = "audio"
        }
    }

    Page {
        name: "calendar"

        Item {
            id: calendarHeader
            width: parent.width
            height: 40

            CircleButton {
                id: calendarBack
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                glyph: "‹"
                glyphSize: 26
                onClicked: root.page = ""
            }

            Text {
                anchors.left: calendarBack.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "Calendar"
                color: Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }
        }

        CalendarTile {
            id: calendar
            anchors.top: calendarHeader.bottom
            anchors.topMargin: 12
            width: parent.width
            height: 240
            today: root.date
        }
    }

    // Night light's warmth, on the scale Poteto uses: further right is warmer
    Page {
        name: "nightlight"

        Item {
            id: nightHeader
            width: parent.width
            height: 40

            CircleButton {
                id: nightBack
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                glyph: "‹"
                glyphSize: 26
                onClicked: root.page = ""
            }

            Column {
                anchors.left: nightBack.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: "Night Light"
                    color: Theme.textPrimary
                    font.pixelSize: 18
                    font.weight: Font.Bold
                    font.family: Theme.fontFamily
                }

                Text {
                    text: NightLight.enabled ? "Warmer colors, easier on the eyes at night" : "Turned off"
                    color: Theme.textSecondary
                    font.pixelSize: 11
                    font.family: Theme.fontFamily
                }
            }

            Toggle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: NightLight.enabled
                onToggled: on => NightLight.setEnabled(on)
            }
        }

        Tile {
            anchors.top: nightHeader.bottom
            anchors.topMargin: 14
            width: parent.width
            height: warmthColumn.implicitHeight + padding * 2
            padding: 12

            Column {
                id: warmthColumn
                width: parent.width
                spacing: 10

                Item {
                    width: parent.width
                    height: 16

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        text: "Warmth"
                        color: Theme.textPrimary
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        font.family: Theme.fontFamily
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        text: "Cooler  ·  Warmer"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        font.family: Theme.fontFamily
                    }
                }

                // 6500 K (left) to 2000 K (right); the drag is written a moment after it settles
                ControlSlider {
                    id: warmth
                    width: parent.width
                    dimmed: !NightLight.enabled
                    value: pending > 0 ? fraction(pending) : fraction(NightLight.temperature)
                    label: (pending > 0 ? pending : NightLight.temperature) + " K"

                    property int pending: 0

                    function fraction(k) {
                        return (NightLight.maxTemperature - k) / (NightLight.maxTemperature - NightLight.minTemperature);
                    }

                    onMoved: v => {
                        pending = Math.round((NightLight.maxTemperature - v * (NightLight.maxTemperature - NightLight.minTemperature)) / 100) * 100;
                        warmthWrite.restart();
                    }

                    Timer {
                        id: warmthWrite
                        interval: 150
                        onTriggered: {
                            NightLight.setTemperature(warmth.pending);
                            if (NightLight.enabled === false)
                                NightLight.setEnabled(true);
                            warmth.pending = 0;
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰖔"
                        color: Theme.controlIconOnFill
                        font.pixelSize: 16
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }
            }
        }
    }

    Page {
        name: "audio"

        AudioPage {
            id: audioPage
            anchors.fill: parent
            onBackRequested: root.page = ""
        }
    }

    Page {
        name: "wifi"

        WifiPage {
            id: wifiPage
            anchors.fill: parent
            onBackRequested: root.page = ""
        }
    }

    Page {
        name: "notifications"

        NotificationsPage {
            id: notificationsPage
            anchors.fill: parent
            onBackRequested: root.page = ""
        }
    }

    Page {
        name: "bluetooth"

        BluetoothPage {
            id: bluetoothPage
            anchors.fill: parent
            onBackRequested: root.page = ""
        }
    }
}
