import QtQuick
import qs.services
import qs.modules.controlcenter.tiles
import qs.modules.controlcenter.controls
import qs.modules.controlcenter.wifi
import qs.modules.controlcenter.bluetooth
import qs.modules.controlcenter.notifications

Item {
    id: root

    readonly property int gap: 12
    readonly property int colWidth: 234

    property date date: new Date()
    property string page: ""
    readonly property bool typing: wifiPage.typing
    readonly property bool busy: brightness.pressed || volume.pressed || wifiPage.typing

    function reset() {
        page = "";
        calendar.reset();
        wifiPage.reset();
        bluetoothPage.reset();
        notificationsPage.reset();
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

        Row {
            spacing: root.gap

            Column {
                spacing: root.gap

                ClockTile {
                    width: root.colWidth
                    height: 111
                    date: root.date
                }

                BatteryTile {
                    width: root.colWidth
                    height: 111
                }
            }

            CalendarTile {
                id: calendar
                width: root.colWidth
                height: 234
                today: root.date
            }
        }

        Row {
            spacing: root.gap

            WifiTile {
                width: root.colWidth
                height: 64
                onOpenRequested: root.page = "wifi"
            }

            BluetoothTile {
                width: root.colWidth
                height: 64
                onOpenRequested: root.page = "bluetooth"
            }
        }

        NotificationsTile {
            width: parent.width
            height: 64
            onOpenRequested: root.page = "notifications"
        }

        BrightnessSlider {
            id: brightness
            width: parent.width
        }

        VolumeSlider {
            id: volume
            width: parent.width
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
