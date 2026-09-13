import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.config
import qs.components
import qs.components.icons
import qs.services

Item {
    id: root

    property string expandedAddress: ""

    signal backRequested()

    function reset() {
        expandedAddress = "";
        flick.contentY = 0;
    }

    component SectionLabel: Row {
        property string text
        property bool busy: false
        spacing: 8
        height: 26

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.text
            color: Theme.textSecondary
            font.pixelSize: 11
            font.weight: Font.DemiBold
            font.letterSpacing: 0.6
            font.family: Theme.fontFamily
        }

        Spinner {
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 12
            color: Theme.textSecondary
            visible: parent.busy
        }
    }

    component DeviceRow: Rectangle {
        id: row

        required property var modelData
        readonly property var device: modelData
        readonly property string address: device.address
        readonly property bool isConnected: device.connected
        readonly property bool isConnecting: device.state === BluetoothDeviceState.Connecting
        readonly property bool isDisconnecting: device.state === BluetoothDeviceState.Disconnecting
        readonly property bool isPairing: device.pairing || BluetoothManager.pairingAddress === address
        readonly property bool busy: isConnecting || isDisconnecting || isPairing
        readonly property bool expanded: root.expandedAddress === address
        readonly property int battery: BluetoothManager.batteryPercent(device)
        property bool failed: BluetoothManager.errorAddress === address
        property bool wasConnecting: false

        width: parent.width
        height: 52 + (expanded ? actions.implicitHeight + 10 : 0)
        radius: 16
        color: expanded || rowMouse.containsMouse ? Theme.tileHover : Theme.tileBg
        clip: true

        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 120 } }

        onIsConnectingChanged: {
            if (isConnecting) {
                wasConnecting = true;
                failed = false;
            } else if (wasConnecting) {
                wasConnecting = false;
                if (!device.connected)
                    failed = true;
            }
        }

        MouseArea {
            id: rowMouse
            width: parent.width
            height: 52
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (row.busy)
                    return;
                if (!row.device.paired) {
                    BluetoothManager.connect(row.device);
                    return;
                }
                root.expandedAddress = row.expanded ? "" : row.address;
            }
        }

        Rectangle {
            id: iconBadge
            x: 12
            y: 26 - height / 2
            width: 32
            height: 32
            radius: 16
            color: row.isConnected ? Theme.accent : Theme.controlBg
            Behavior on color { ColorAnimation { duration: 180 } }

            Image {
                id: deviceIcon
                anchors.centerIn: parent
                width: 18
                height: 18
                source: row.device.icon ? Quickshell.iconPath(row.device.icon, true) : ""
                sourceSize.width: 36
                sourceSize.height: 36
                visible: status === Image.Ready
            }

            BluetoothIcon {
                anchors.centerIn: parent
                width: 10
                height: 15
                color: row.isConnected ? Theme.onAccent : Theme.textPrimary
                visible: !deviceIcon.visible
            }
        }

        Column {
            anchors.left: iconBadge.right
            anchors.leftMargin: 12
            anchors.right: trailing.left
            anchors.rightMargin: 10
            y: 26 - height / 2
            spacing: 1

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: BluetoothManager.displayName(row.device)
                color: Theme.textPrimary
                font.pixelSize: 13
                font.weight: row.isConnected ? Font.DemiBold : Font.Normal
                font.family: Theme.fontFamily
            }

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: row.isPairing ? "Pairing…"
                    : row.isConnecting ? "Connecting…"
                    : row.isDisconnecting ? "Disconnecting…"
                    : row.isConnected ? "Connected" + (row.battery >= 0 ? `  ·  ${row.battery}% battery` : "")
                    : row.failed ? "Couldn't connect"
                    : row.device.paired ? "Not connected"
                    : "Tap to pair"
                color: row.isConnected || row.busy ? Theme.accent
                    : row.failed ? Theme.danger
                    : Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        Item {
            id: trailing
            anchors.right: parent.right
            anchors.rightMargin: 16
            y: 26 - height / 2
            width: 18
            height: 18

            Spinner {
                anchors.fill: parent
                visible: row.busy
            }

            CheckIcon {
                anchors.centerIn: parent
                width: 16
                height: 12
                visible: row.isConnected && !row.busy
            }
        }

        Row {
            id: actions
            x: 16
            y: 52
            spacing: 8
            opacity: row.expanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            PillButton {
                visible: !row.isConnected
                text: "Connect"
                primary: true
                enabled: !row.busy
                onClicked: BluetoothManager.connect(row.device)
            }

            PillButton {
                visible: row.isConnected
                text: "Disconnect"
                enabled: !row.busy
                onClicked: BluetoothManager.disconnect(row.device)
            }

            PillButton {
                text: "Forget"
                danger: true
                onClicked: {
                    root.expandedAddress = "";
                    BluetoothManager.forget(row.device);
                }
            }
        }
    }

    Item {
        id: header
        width: parent.width
        height: 40

        CircleButton {
            id: backBtn
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            glyph: "‹"
            glyphSize: 26
            onClicked: root.backRequested()
        }

        Column {
            anchors.left: backBtn.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "Bluetooth"
                color: Theme.textPrimary
                font.pixelSize: 18
                font.weight: Font.Bold
                font.family: Theme.fontFamily
            }

            Text {
                text: !BluetoothManager.available ? "No adapter found"
                    : !BluetoothManager.enabled ? "Turned off"
                    : BluetoothManager.scanning ? "Searching for devices…"
                    : `${BluetoothManager.connectedDevices.length} connected  ·  ${BluetoothManager.pairedDevices.length} paired`
                color: Theme.textSecondary
                font.pixelSize: 11
                font.family: Theme.fontFamily
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            CircleButton {
                anchors.verticalCenter: parent.verticalCenter
                glyph: "↻"
                glyphSize: 18
                visible: BluetoothManager.enabled
                spinning: BluetoothManager.scanning
                onClicked: BluetoothManager.toggleScan()
            }

            Toggle {
                anchors.verticalCenter: parent.verticalCenter
                visible: BluetoothManager.available
                checked: BluetoothManager.enabled
                onToggled: on => BluetoothManager.setEnabled(on)
            }
        }
    }

    Column {
        anchors.centerIn: flick
        spacing: 10
        visible: !BluetoothManager.enabled || BluetoothManager.devices.length === 0

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 56
            height: 56
            radius: 28
            color: Theme.tileBg

            BluetoothIcon {
                anchors.centerIn: parent
                width: 18
                height: 27
                color: Theme.textSecondary
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: !BluetoothManager.available ? "No Bluetooth adapter"
                : !BluetoothManager.enabled ? "Bluetooth is off"
                : BluetoothManager.scanning ? "Looking for devices…"
                : "No devices found"
            color: Theme.textPrimary
            font.pixelSize: 14
            font.weight: Font.DemiBold
            font.family: Theme.fontFamily
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: BluetoothManager.available
            text: !BluetoothManager.enabled ? "Turn it on to connect your devices"
                : "Put your device in pairing mode"
            color: Theme.textSecondary
            font.pixelSize: 12
            font.family: Theme.fontFamily
        }
    }

    Flickable {
        id: flick
        anchors.top: header.bottom
        anchors.topMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        contentWidth: width
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        visible: BluetoothManager.enabled && BluetoothManager.devices.length > 0

        Column {
            id: content
            width: flick.width
            spacing: 6

            SectionLabel {
                x: 4
                text: "MY DEVICES"
                visible: BluetoothManager.pairedDevices.length > 0
            }

            Repeater {
                model: BluetoothManager.pairedDevices
                delegate: DeviceRow {}
            }

            SectionLabel {
                x: 4
                text: "OTHER DEVICES"
                busy: BluetoothManager.scanning
                visible: BluetoothManager.otherDevices.length > 0 || BluetoothManager.scanning
            }

            Repeater {
                model: BluetoothManager.otherDevices
                delegate: DeviceRow {}
            }
        }
    }
}
