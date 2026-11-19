import QtQuick
import Quickshell.Bluetooth
import qs.config
import qs.services

// The Bluetooth menu, a page of the control center, laid out like the Wi-Fi one: the radio
// switch and rescan on top, then devices in three groups. Connected ones are cards with their
// battery; your other paired devices connect with a click; nearby ones pair with a click (and
// connect once paired). Hover a device to disconnect or forget it. The page searches for nearby
// devices while it is open.
Item {
    id: root

    property bool active: false
    readonly property int rowHeight: 50
    // Taller than this, the device list scrolls
    readonly property int maxListHeight: 340

    readonly property var connected: BluetoothManager.connectedDevices
    readonly property var mine: BluetoothManager.pairedDevices.filter(d => !d.connected)
    readonly property var nearby: BluetoothManager.otherDevices.filter(d => !d.connected)

    signal backRequested()

    // A Nerd Font glyph for what the device is, from its freedesktop icon name
    function glyphFor(device) {
        const icon = device?.icon ?? "";
        return /headset|headphone/.test(icon) ? "󰋋"
            : /audio|speaker/.test(icon) ? "󰓃"
            : /keyboard/.test(icon) ? "󰌌"
            : /mouse|tablet/.test(icon) ? "󰍽"
            : /gaming|joystick/.test(icon) ? "󰊴"
            : /phone/.test(icon) ? "󰏲"
            : /computer|laptop/.test(icon) ? "󰇄"
            : /display|video|tv/.test(icon) ? "󰍹"
            : /watch/.test(icon) ? "󰖉"
            : "󰂯";
    }

    onActiveChanged: {
        if (active) {
            keys.forceActiveFocus();
            BluetoothManager.startScan();
        } else {
            BluetoothManager.stopScan();
        }
    }

    implicitHeight: column.implicitHeight

    Item {
        id: keys
        Keys.onEscapePressed: root.backRequested()
    }

    // A small heading over each group
    component SectionLabel: Item {
        id: label
        property string text
        property bool busy: false
        width: parent?.width ?? 0
        height: 26

        Text {
            id: labelText
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: label.text
            color: Theme.textDim
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.4
            font.family: Theme.fontFamily
        }

        Text {
            anchors.left: labelText.right
            anchors.leftMargin: 8
            anchors.verticalCenter: labelText.verticalCenter
            visible: label.busy
            text: "Searching…"
            color: Theme.textDim
            opacity: 0.7
            font.pixelSize: 11
            font.family: Theme.fontFamily

            SequentialAnimation on opacity {
                running: label.busy
                loops: Animation.Infinite
                NumberAnimation { to: 0.3; duration: 700 }
                NumberAnimation { to: 0.8; duration: 700 }
            }
        }
    }

    // One device. Connected ones are drawn as a tile with the accent badge; the rest are rows
    component DeviceRow: Rectangle {
        id: row

        required property var modelData
        readonly property var device: modelData
        readonly property string address: device?.address ?? ""
        readonly property bool isConnected: device?.connected ?? false
        readonly property bool isConnecting: device?.state === BluetoothDeviceState.Connecting
        readonly property bool isDisconnecting: device?.state === BluetoothDeviceState.Disconnecting
        readonly property bool isPairing: (device?.pairing ?? false) || BluetoothManager.pairingAddress === address
        readonly property bool failed: BluetoothManager.errorAddress === address
        readonly property bool busy: isConnecting || isDisconnecting || isPairing
        readonly property int battery: BluetoothManager.batteryPercent(device)
        readonly property bool hovered: mouse.containsMouse || leave.hovered || forget.hovered

        width: parent?.width ?? 0
        height: root.rowHeight
        radius: 14
        color: isConnected ? Theme.tile
            : mouse.containsMouse ? Qt.alpha(Theme.tile, 0.7)
            : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: row.isConnected || row.busy ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: {
                if (!row.isConnected && !row.busy)
                    BluetoothManager.connect(row.device);
            }
        }

        Rectangle {
            id: badge
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 34
            radius: 17
            color: row.isConnected ? Theme.accent : Theme.tileHover
            Behavior on color { ColorAnimation { duration: 160 } }

            Text {
                anchors.centerIn: parent
                text: root.glyphFor(row.device)
                color: row.isConnected ? Theme.accentText : Theme.text
                font.pixelSize: 16
                font.family: Theme.monoFamily
            }

            // Busy: a ring turning around the badge
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 6
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
                visible: row.busy
                opacity: 0.6

                SequentialAnimation on opacity {
                    running: row.busy
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.15; duration: 600 }
                    NumberAnimation { to: 0.7; duration: 600 }
                }
            }
        }

        Column {
            anchors.left: badge.right
            anchors.leftMargin: 12
            anchors.right: actions.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: BluetoothManager.displayName(row.device)
                color: Theme.text
                font.pixelSize: 13
                font.weight: row.isConnected ? Font.DemiBold : Font.Medium
                font.family: Theme.fontFamily
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: row.isPairing ? "Pairing…"
                    : row.isConnecting ? "Connecting…"
                    : row.isDisconnecting ? "Disconnecting…"
                    : row.failed ? "Couldn't connect"
                    : row.isConnected ? "Connected"
                    : row.device?.paired ? "Not connected"
                    : "Click to pair"
                color: row.failed ? Theme.danger : Theme.textDim
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        Row {
            id: actions
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Hover-only: leave a connected device
            Rectangle {
                id: leave
                readonly property bool hovered: leaveMouse.containsMouse
                anchors.verticalCenter: parent.verticalCenter
                visible: row.isConnected && !row.busy && row.hovered
                width: leaveText.implicitWidth + 20
                height: 26
                radius: 13
                color: leaveMouse.containsMouse ? Theme.tileHover : Theme.background

                Text {
                    id: leaveText
                    anchors.centerIn: parent
                    text: "Disconnect"
                    color: Theme.text
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.family: Theme.fontFamily
                }

                MouseArea {
                    id: leaveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothManager.disconnect(row.device)
                }
            }

            // Hover-only: forget a paired device
            RoundButton {
                id: forget
                anchors.verticalCenter: parent.verticalCenter
                visible: (row.device?.paired ?? false) && !row.busy && row.hovered
                implicitWidth: 26
                implicitHeight: 26
                flat: true
                glyph: "󰆴"
                glyphSize: 13
                onClicked: BluetoothManager.forget(row.device)
            }

            // Battery, while not hovered: a small gauge and the percentage
            Row {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.battery >= 0 && !row.hovered
                spacing: 6

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 10
                    radius: 3
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.textDim

                    Rectangle {
                        x: 2
                        y: 2
                        width: Math.max(1, (parent.width - 4) * row.battery / 100)
                        height: parent.height - 4
                        radius: 1.5
                        color: row.battery <= 20 ? Theme.danger : Theme.text
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.battery + "%"
                    color: Theme.textDim
                    font.pixelSize: 11
                    font.family: Theme.monoFamily
                }
            }
        }
    }

    Column {
        id: column
        width: parent.width
        spacing: 10

        PageHeader {
            title: "Bluetooth"
            checked: BluetoothManager.enabled
            showSwitch: BluetoothManager.available
            scanning: BluetoothManager.scanning
            onBackClicked: root.backRequested()
            onRescanClicked: BluetoothManager.toggleScan()
            onToggled: on => BluetoothManager.setEnabled(on)
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }

        // Shown instead of the list when there is nothing to list
        Column {
            width: parent.width
            visible: !BluetoothManager.enabled || BluetoothManager.devices.length === 0
            topPadding: 14
            bottomPadding: 14
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰂲"
                visible: !BluetoothManager.enabled
                color: Theme.textDim
                font.pixelSize: 26
                font.family: Theme.monoFamily
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: !BluetoothManager.available ? "No Bluetooth adapter"
                    : !BluetoothManager.enabled ? "Bluetooth is off"
                    : "Looking for devices…"
                color: Theme.textDim
                font.pixelSize: 13
                font.family: Theme.fontFamily
            }
        }

        Flickable {
            id: list
            width: parent.width
            visible: BluetoothManager.enabled && BluetoothManager.devices.length > 0
            height: Math.min(groups.implicitHeight, root.maxListHeight)
            contentHeight: groups.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: groups
                width: list.width
                spacing: 2

                SectionLabel {
                    visible: root.connected.length > 0
                    text: "CONNECTED"
                }

                Repeater {
                    model: root.connected
                    DeviceRow {}
                }

                SectionLabel {
                    visible: root.mine.length > 0
                    text: "MY DEVICES"
                }

                Repeater {
                    model: root.mine
                    DeviceRow {}
                }

                SectionLabel {
                    visible: root.nearby.length > 0 || BluetoothManager.scanning
                    text: "NEARBY"
                    busy: BluetoothManager.scanning
                }

                Repeater {
                    model: root.nearby
                    DeviceRow {}
                }
            }
        }
    }
}
